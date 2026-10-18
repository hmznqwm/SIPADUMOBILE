import 'dart:async';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import '../../../config/api_config.dart';
import '../../models/availability_model.dart';
import '../../models/ajuan_pengajaran_model.dart';
import '../../models/jadwal_model.dart';
import '../../models/mata_kuliah_model.dart';
import '../../models/slot_waktu_model.dart';
import '../../mock/mock_database.dart';
import 'api_http_helper.dart';
import 'master_data_api_service.dart';
import 'notification_api_service.dart';

class AvailabilityApiService {
  final ApiHttpHelper _httpHelper;
  final MasterDataApiService _masterDataService;
  final NotificationApiService _notificationService;

  Future<Map<String, SlotTagInfo>> _loadCachedTags(String dosenId, String semesterId) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final cachedStr = prefs.getString('slot_tags_${dosenId}_$semesterId');
      if (cachedStr != null) {
        final decoded = jsonDecode(cachedStr) as Map;
        final tags = <String, SlotTagInfo>{};
        decoded.forEach((k, v) {
          if (v is Map) {
            tags[k.toString()] = SlotTagInfo.fromJson(Map<String, dynamic>.from(v));
          }
        });
        return tags;
      }
    } catch (_) {}
    return {};
  }

  AvailabilityApiService({
    ApiHttpHelper? httpHelper,
    MasterDataApiService? masterDataService,
    NotificationApiService? notificationService,
  })  : _httpHelper = httpHelper ?? ApiHttpHelper(),
        _masterDataService = masterDataService ?? MasterDataApiService(httpHelper: httpHelper),
        _notificationService = notificationService ?? NotificationApiService(httpHelper: httpHelper);

  /// GET /api/availability
  Future<AvailabilityModel> getAvailability(String dosenId, String semesterId) async {
    // 1. Coba lewat backend Python
    if (!ApiConfig.useMockBackend) {
      try {
        final res = await _httpHelper.makeOnlineRequest('/availability?dosenId=$dosenId&semesterId=$semesterId');
        if (res is Map && res['status'] == 'success' && res['data'] != null) {
          final data = res['data'];
          Map<String, dynamic>? itemMap;
          if (data is List && data.isNotEmpty) {
            itemMap = Map<String, dynamic>.from(data.first);
          } else if (data is Map) {
            itemMap = Map<String, dynamic>.from(data);
          }
          if (itemMap != null) {
            var model = AvailabilityModel.fromJson(itemMap);
            if (model.slotTags.isEmpty) {
              model = model.copyWith(slotTags: await _loadCachedTags(dosenId, semesterId));
            }
            MockDatabase.currentAvailability = model;
            return model;
          }
        }
      } catch (_) {}
    }

    // 2. Direct Supabase Cloud Fallback
    try {
      final uri = Uri.parse('${ApiConfig.supabaseUrl}/rest/v1/availability?dosen_id=eq.$dosenId&semester_id=eq.$semesterId&select=*,availability_slots(*)&order=submitted_at.desc');
      final resp = await http.get(
        uri,
        headers: ApiConfig.supabaseHeaders,
      ).timeout(const Duration(seconds: 6));

      if (resp.statusCode == 200) {
        final decoded = jsonDecode(resp.body);
        if (decoded is List && decoded.isNotEmpty) {
          final raw = decoded.first as Map<String, dynamic>;
          final slots = (raw['availability_slots'] as List? ?? [])
              .map((s) => (s['slot_id'] ?? '').toString())
              .where((s) => s.isNotEmpty)
              .toList();
          final cachedTags = slots.isNotEmpty ? await _loadCachedTags(dosenId, semesterId) : const <String, SlotTagInfo>{};
          final model = AvailabilityModel(
            id: raw['id'] ?? 'AVL_${dosenId}_$semesterId',
            dosenId: raw['dosen_id'] ?? dosenId,
            semesterId: raw['semester_id'] ?? semesterId,
            selectedSlotIds: slots,
            slotTags: cachedTags,
            status: slots.isNotEmpty ? (raw['status'] ?? 'submitted') : 'draft',
            submittedAt: raw['submitted_at'] != null ? DateTime.tryParse(raw['submitted_at']) : null,
          );
          MockDatabase.currentAvailability = model;
          return model;
        } else if (decoded is List && decoded.isEmpty) {
          final emptyModel = AvailabilityModel(
            id: 'AVL_${dosenId}_$semesterId',
            dosenId: dosenId,
            semesterId: semesterId,
            selectedSlotIds: const [],
            slotTags: const {},
            status: 'draft',
          );
          MockDatabase.currentAvailability = emptyModel;
          return emptyModel;
        }
      }
    } catch (_) {}

    await Future.delayed(const Duration(milliseconds: 100));
    if (MockDatabase.currentAvailability != null && MockDatabase.currentAvailability!.dosenId == dosenId) {
      var model = MockDatabase.currentAvailability!;
      if (model.slotTags.isEmpty && model.selectedSlotIds.isNotEmpty) {
        model = model.copyWith(slotTags: await _loadCachedTags(dosenId, semesterId));
        MockDatabase.currentAvailability = model;
      }
      return model;
    }
    
    final fallbackModel = AvailabilityModel(
      id: 'AVL_${dosenId}_$semesterId',
      dosenId: dosenId,
      semesterId: semesterId,
      selectedSlotIds: const [],
      slotTags: const {},
      status: 'draft',
    );
    MockDatabase.currentAvailability = fallbackModel;
    return fallbackModel;
  }

  /// Label semester dari ID (mis. SEM001 -> Semester 1); tanpa data karangan.
  static String _semesterLabel(String id) {
    final n = int.tryParse(id.replaceAll(RegExp(r'[^0-9]'), ''));
    return n == null ? (id.isEmpty ? '-' : id) : 'Semester $n';
  }

  /// POST /api/availability
  /// Menyimpan matriks ketersediaan dosen DAN otomatis membentuk Ajuan Pengajaran
  /// (status `menunggu_kaprodi`) agar langsung tampil di Tab "Ajuan Saya",
  /// dashboard KaProdi, Dekan, dan Admin.
  Future<AvailabilityModel> saveAvailability({
    required String dosenId,
    required String semesterId,
    required List<String> selectedSlotIds,
    Map<String, SlotTagInfo>? slotTags,
    List<MataKuliahModel>? mataKuliahList,
    String? dosenNama,
    String? dosenJurusan,
    String? dosenFakultas,
  }) async {
    // Hanya simpan tag milik slot yang benar-benar dipilih (cegah tag yatim/usang)
    final rawTags = slotTags ?? MockDatabase.currentAvailability?.slotTags ?? {};
    final tagsMap = <String, SlotTagInfo>{};
    for (final sid in selectedSlotIds) {
      final t = rawTags[sid];
      if (t != null) tagsMap[sid] = t;
    }

    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('slot_tags_${dosenId}_$semesterId', jsonEncode(tagsMap.map((k, v) => MapEntry(k, v.toJson()))));
    } catch (_) {}

    final availId = 'AVL_${dosenId}_$semesterId';
    final availability = AvailabilityModel(
      id: availId,
      dosenId: dosenId,
      semesterId: semesterId,
      selectedSlotIds: selectedSlotIds,
      slotTags: tagsMap,
      status: 'submitted',
      submittedAt: DateTime.now(),
      updatedAt: DateTime.now(),
    );

    // Simpan ke server DULU; bila gagal, lempar error sebelum state lokal berubah.
    await _persistAvailabilityToCloud(
      availId: availId,
      dosenId: dosenId,
      semesterId: semesterId,
      selectedSlotIds: selectedSlotIds,
      tagsMap: tagsMap,
    );

    MockDatabase.currentAvailability = availability;
    MockDatabase.dosenSubmissionStatus[dosenId] = 'Diajukan';

    MockDatabase.availabilityHistory.removeWhere((h) => h.id == availId);
    MockDatabase.availabilityHistory.insert(
      0,
      AvailabilityHistoryItem(
        id: availability.id,
        submittedAt: DateTime.now(),
        slotCount: selectedSlotIds.length,
        status: 'submitted',
        semesterNama: _semesterLabel(semesterId),
      ),
    );

    // Identitas dosen: prioritaskan data dari sesi login, lalu demoUsers
    final userObj = MockDatabase.demoUsers.where((u) => u.id == dosenId).firstOrNull;
    final dNama = (dosenNama != null && dosenNama.trim().isNotEmpty)
        ? dosenNama
        : (userObj?.nama ?? '');
    final dJurusan = (dosenJurusan != null && dosenJurusan.trim().isNotEmpty)
        ? dosenJurusan
        : (userObj?.jurusanNama ?? '');
    final dFakultas = (dosenFakultas != null && dosenFakultas.trim().isNotEmpty)
        ? dosenFakultas
        : (userObj?.fakultasNama ?? '');

    // Bridge Matriks -> Ajuan Pengajaran (SELALU dijalankan apapun jalur backend-nya)
    final ajuanCount = await _syncAjuanFromAvailability(
      dosenId: dosenId,
      dNama: dNama,
      dJurusan: dJurusan,
      dFakultas: dFakultas,
      selectedSlotIds: selectedSlotIds,
      tagsMap: tagsMap,
      mataKuliahList: mataKuliahList,
    );

    // Broadcast notifications to KaProdi, Dekan, and Admin
    try {
      await _notificationService.sendNotification(
        userId: 'kaprodi',
        title: 'Ketersediaan Dosen Masuk',
        message: '$dNama ($dJurusan) mengirim ${selectedSlotIds.length} slot ketersediaan dan $ajuanCount ajuan mengajar yang menunggu persetujuan Anda.',
        type: 'info',
      );
      await _notificationService.sendNotification(
        userId: 'dekan',
        title: 'Ketersediaan Dosen Dikirim',
        message: '$dNama ($dFakultas) telah menyelesaikan pengisian ketersediaan waktu ($ajuanCount ajuan).',
        type: 'info',
      );
      await _notificationService.sendNotification(
        userId: 'admin',
        title: 'Ketersediaan Dosen Masuk',
        message: '$dNama telah mengirim matriks ketersediaan waktu untuk semester ini ($ajuanCount ajuan).',
        type: 'info',
      );
    } catch (_) {}

    return availability;
  }

  /// Menyimpan ketersediaan ke server. WAJIB berhasil sebelum state lokal diubah,
  /// agar UI tidak pernah melaporkan "berhasil" untuk data yang tidak tersimpan.
  /// Melempar [Exception] bila backend maupun Supabase menolak / tidak terjangkau.
  Future<void> _persistAvailabilityToCloud({
    required String availId,
    required String dosenId,
    required String semesterId,
    required List<String> selectedSlotIds,
    required Map<String, SlotTagInfo> tagsMap,
  }) async {
    // 1. Backend Python
    if (!ApiConfig.useMockBackend) {
      try {
        final res = await _httpHelper.makeOnlineRequest(
          '/availability',
          method: 'POST',
          body: {
            'dosen_id': dosenId,
            'dosenId': dosenId,
            'semester_id': semesterId,
            'semesterId': semesterId,
            'slot_ids': selectedSlotIds,
            'slotIds': selectedSlotIds,
            'selectedSlotIds': selectedSlotIds,
            'selected_slot_ids': selectedSlotIds,
            'slotTags': tagsMap.map((k, v) => MapEntry(k, v.toJson())),
          },
        );
        if (res is Map && res['status'] == 'success') return;
      } catch (_) {}
    }

    // 2. Supabase langsung (upsert availability, ganti seluruh slot)
    final headers = {
      ...ApiConfig.supabaseHeaders,
      'Content-Type': 'application/json',
    };
    bool ok(http.Response r) => r.statusCode >= 200 && r.statusCode < 300;
    try {
      final now = DateTime.now().toIso8601String();
      final up = await http.post(
        Uri.parse('${ApiConfig.supabaseUrl}/rest/v1/availability'),
        headers: {...headers, 'Prefer': 'resolution=merge-duplicates'},
        body: jsonEncode({
          'id': availId,
          'dosen_id': dosenId,
          'semester_id': semesterId,
          'status': 'submitted',
          'submitted_at': now,
          'updated_at': now,
        }),
      ).timeout(const Duration(seconds: 8));
      if (!ok(up)) {
        throw Exception('server menolak penyimpanan ketersediaan (kode ${up.statusCode})');
      }

      final del = await http.delete(
        Uri.parse('${ApiConfig.supabaseUrl}/rest/v1/availability_slots?availability_id=eq.${Uri.encodeComponent(availId)}'),
        headers: headers,
      ).timeout(const Duration(seconds: 8));
      if (!ok(del)) {
        throw Exception('server menolak pembaruan slot (kode ${del.statusCode})');
      }

      if (selectedSlotIds.isNotEmpty) {
        final ins = await http.post(
          Uri.parse('${ApiConfig.supabaseUrl}/rest/v1/availability_slots'),
          headers: headers,
          body: jsonEncode(selectedSlotIds
              .map((sid) => {'availability_id': availId, 'slot_id': sid})
              .toList()),
        ).timeout(const Duration(seconds: 8));
        if (!ok(ins)) {
          throw Exception('server menolak penyimpanan slot (kode ${ins.statusCode})');
        }
      }
    } on TimeoutException {
      throw Exception('server tidak merespons, periksa koneksi internet');
    } on http.ClientException catch (e) {
      throw Exception('tidak dapat terhubung ke server (${e.message})');
    }
  }

  static const List<String> _hariOrder = ['Senin', 'Selasa', 'Rabu', 'Kamis', 'Jumat', 'Sabtu', 'Minggu'];

  /// Prefix ID ajuan yang dibentuk otomatis dari Matriks Ketersediaan.
  /// ID deterministik (per dosen + matkul + kelas) agar submit ulang MENGGANTI, bukan menduplikasi.
  static String availabilityAjuanPrefix(String dosenId) =>
      'AJU_AVL_${dosenId.replaceAll(RegExp(r'[^A-Za-z0-9]'), '')}_';

  /// Membentuk ulang seluruh Ajuan Pengajaran milik dosen dari matriks ketersediaan.
  /// Return: jumlah ajuan yang dibentuk.
  Future<int> _syncAjuanFromAvailability({
    required String dosenId,
    required String dNama,
    required String dJurusan,
    required String dFakultas,
    required List<String> selectedSlotIds,
    required Map<String, SlotTagInfo> tagsMap,
    List<MataKuliahModel>? mataKuliahList,
  }) async {
    List<SlotWaktuModel> allSlots;
    try {
      allSlots = await _masterDataService.getSlotWaktu();
    } catch (_) {
      allSlots = MockDatabase.slotWaktu;
    }
    var mkList = mataKuliahList ?? const <MataKuliahModel>[];
    if (mkList.isEmpty) {
      try {
        mkList = await _masterDataService.getMataKuliah(dosenId);
      } catch (_) {}
    }

    final slotById = {for (final s in allSlots) s.id: s};
    int hariIdx(String h) {
      final i = _hariOrder.indexOf(h);
      return i < 0 ? 99 : i;
    }

    int cmpSlot(SlotWaktuModel a, SlotWaktuModel b) {
      final d = hariIdx(a.hari).compareTo(hariIdx(b.hari));
      return d != 0 ? d : a.jamMulai.compareTo(b.jamMulai);
    }

    /// Rentang waktu (hari, jam mulai, jam selesai) dari kumpulan slot pada hari yang sama.
    ({String hari, String mulai, String selesai})? rangeOf(List<String> ids) {
      final objs = ids.map((id) => slotById[id]).whereType<SlotWaktuModel>().toList()..sort(cmpSlot);
      if (objs.isEmpty) return null;
      final hari = objs.first.hari;
      final sameDay = objs.where((s) => s.hari == hari).toList();
      return (hari: hari, mulai: sameDay.first.jamMulai, selesai: sameDay.last.jamSelesai);
    }

    String clean(String s) => s.replaceAll(RegExp(r'[^A-Za-z0-9]'), '');
    final prefix = availabilityAjuanPrefix(dosenId);
    final now = DateTime.now();
    final generated = <AjuanPengajaranModel>[];

    AjuanPengajaranModel build({
      required String mkId,
      required String mkNama,
      required int sks,
      required String kelas,
      required String jurusan,
      required String fakultas,
      required int semester,
      required ({String hari, String mulai, String selesai}) range,
      required String catatan,
    }) {
      return AjuanPengajaranModel(
        id: '$prefix${clean(mkId)}_${clean(kelas)}',
        dosenId: dosenId,
        dosenNama: dNama,
        fakultasNama: fakultas.isNotEmpty ? fakultas : dFakultas,
        jurusanNama: jurusan.isNotEmpty ? jurusan : dJurusan,
        mataKuliahId: mkId,
        mataKuliahNama: mkNama,
        sks: sks,
        hari: range.hari,
        jamMulai: range.mulai,
        jamSelesai: range.selesai,
        gedungNama: 'Menunggu Plotting',
        ruanganNama: 'Belum Diplot',
        semester: semester,
        kelasNama: kelas.isNotEmpty ? kelas : 'Kelas A',
        jumlahMahasiswa: 35,
        status: 'menunggu_kaprodi',
        catatanDosen: catatan,
        submittedAt: now,
      );
    }

    // A. Slot yang ditautkan ke Mata Kuliah & Kelas -> 1 ajuan per (matkul, kelas)
    final grouped = <String, List<String>>{};
    for (final sid in selectedSlotIds) {
      final tag = tagsMap[sid];
      if (tag == null) continue;
      grouped.putIfAbsent('${tag.mataKuliahId}||${tag.kelasNama}', () => []).add(sid);
    }
    final coveredKeys = <String>{};
    grouped.forEach((key, ids) {
      final tag = tagsMap[ids.first]!;
      final range = rangeOf(ids);
      if (range == null) return;
      coveredKeys.add(key);
      final mk = mkList.where((m) => m.id == tag.mataKuliahId).firstOrNull;
      generated.add(build(
        mkId: tag.mataKuliahId,
        mkNama: tag.mataKuliahNama,
        sks: tag.sks,
        kelas: tag.kelasNama,
        jurusan: tag.jurusanNama,
        fakultas: tag.fakultasNama,
        semester: mk?.semester ?? 1,
        range: range,
        catatan: 'Diajukan dari Matriks Ketersediaan (${ids.length} slot x 50 menit, ${range.hari} ${range.mulai}-${range.selesai}).',
      ));
    });

    // B. Slot Waktu Fleksibel -> dibagikan ke (matkul, kelas) yang belum ditautkan
    final flexible = selectedSlotIds.where((s) => tagsMap[s] == null && slotById[s] != null).toList()
      ..sort((a, b) => cmpSlot(slotById[a]!, slotById[b]!));
    int cursor = 0;
    for (final mk in mkList) {
      final kelasList = mk.kelasNama.isEmpty ? const ['Kelas A'] : mk.kelasNama;
      for (final kelas in kelasList) {
        if (coveredKeys.contains('${mk.id}||$kelas')) continue;
        if (cursor >= flexible.length) break;
        final end = (cursor + mk.slotPerPertemuan).clamp(0, flexible.length);
        final ids = flexible.sublist(cursor, end);
        cursor = end;
        final range = rangeOf(ids);
        if (range == null) continue;
        generated.add(build(
          mkId: mk.id,
          mkNama: mk.nama,
          sks: mk.sks,
          kelas: kelas,
          jurusan: mk.jurusanNama,
          fakultas: mk.fakultasNama,
          semester: mk.semester,
          range: range,
          catatan: 'Waktu Fleksibel dari Matriks Ketersediaan (${ids.length} slot). Jadwal final dapat disesuaikan oleh sistem penjadwalan otomatis.',
        ));
      }
    }

    // Ganti ajuan matriks lama milik dosen ini (termasuk format ID lama bertimestamp)
    bool isOldMatrixAjuan(AjuanPengajaranModel a) {
      if (a.id.startsWith(prefix)) return true;
      final note = a.catatanDosen ?? '';
      return a.dosenId == dosenId &&
          a.id.startsWith('AJU_${dosenId}_') &&
          (note.contains('Matriks Ketersediaan') ||
              note.contains('Ketersediaan Waktu Fleksibel') ||
              note.contains('Pengajuan ketersediaan jam'));
    }

    final oldIds = MockDatabase.ajuanPengajaranList.where(isOldMatrixAjuan).map((a) => a.id).toList();
    MockDatabase.ajuanPengajaranList.removeWhere(isOldMatrixAjuan);
    MockDatabase.ajuanPengajaranList.insertAll(0, generated);
    await MockDatabase.saveLocalAjuan();

    // Sinkronisasi Supabase Cloud: hapus ajuan matriks lama, lalu upsert batch yang baru
    try {
      final headers = {
        ...ApiConfig.supabaseHeaders,
        'Content-Type': 'application/json',
      };
      final newIds = generated.map((a) => a.id).toSet();
      final staleIds = {
        ...oldIds,
      }.where((id) => !newIds.contains(id)).toList();
      await http.delete(
        Uri.parse('${ApiConfig.supabaseUrl}/rest/v1/ajuan_pengajaran?id=like.$prefix*'),
        headers: headers,
      ).timeout(const Duration(seconds: 5));
      for (final id in staleIds) {
        await http.delete(
          Uri.parse('${ApiConfig.supabaseUrl}/rest/v1/ajuan_pengajaran?id=eq.${Uri.encodeComponent(id)}'),
          headers: headers,
        ).timeout(const Duration(seconds: 4));
      }
      if (generated.isNotEmpty) {
        await http.post(
          Uri.parse('${ApiConfig.supabaseUrl}/rest/v1/ajuan_pengajaran'),
          headers: {...headers, 'Prefer': 'resolution=merge-duplicates'},
          body: jsonEncode(generated.map((a) => {
            'id': a.id,
            'dosen_id': a.dosenId,
            'dosen_nama': a.dosenNama,
            'fakultas_nama': a.fakultasNama,
            'jurusan_nama': a.jurusanNama,
            'mata_kuliah_id': a.mataKuliahId,
            'mata_kuliah_nama': a.mataKuliahNama,
            'sks': a.sks,
            'semester': a.semester,
            'kelas_nama': a.kelasNama,
            'jumlah_mahasiswa': a.jumlahMahasiswa,
            'gedung_nama': a.gedungNama,
            'ruangan_nama': a.ruanganNama,
            'hari': a.hari,
            'jam_mulai': a.jamMulai,
            'jam_selesai': a.jamSelesai,
            'status': a.status,
            'catatan_dosen': a.catatanDosen,
          }).toList()),
        ).timeout(const Duration(seconds: 6));
      }
    } catch (_) {}

    return generated.length;
  }

  /// Validate pre-submit: jumlah slot harus TEPAT sesuai kebutuhan seluruh matkul & kelas.
  Future<({bool valid, int required, int provided, String? message})> validatePreSubmit({
    required String dosenId,
    required List<String> selectedSlotIds,
  }) async {
    final mataKuliah = await _masterDataService.getMataKuliah(dosenId);
    final required = mataKuliah.fold<int>(0, (sum, mk) => sum + mk.totalSlotDibutuhkan);
    final provided = selectedSlotIds.length;

    if (provided == 0) {
      return (valid: false, required: required, provided: 0, message: 'Belum ada slot waktu yang dipilih.');
    }
    if (required > 0 && provided > required) {
      return (
        valid: false,
        required: required,
        provided: provided,
        message: 'Slot dipilih ($provided) melebihi kebutuhan beban mengajar ($required slot). Kurangi ${provided - required} slot.',
      );
    }
    if (required > 0 && provided < required) {
      return (
        valid: false,
        required: required,
        provided: provided,
        message: 'Slot dipilih ($provided) kurang dari kebutuhan beban mengajar ($required slot). Tambah ${required - provided} slot lagi.',
      );
    }
    return (valid: true, required: required > 0 ? required : provided, provided: provided, message: null);
  }

  /// GET availability history
  Future<List<AvailabilityHistoryItem>> getAvailabilityHistory(String dosenId) async {
    if (!ApiConfig.useMockBackend) {
      try {
        final uri = Uri.parse('${ApiConfig.supabaseUrl}/rest/v1/availability?dosen_id=eq.$dosenId&select=*,availability_slots(*)&order=submitted_at.desc');
        final resp = await http.get(
          uri,
          headers: ApiConfig.supabaseHeaders,
        ).timeout(const Duration(seconds: 5));
        if (resp.statusCode == 200) {
          final decoded = jsonDecode(resp.body);
          if (decoded is List) {
            final list = decoded.map((raw) {
              final r = Map<String, dynamic>.from(raw);
              final slots = (r['availability_slots'] as List? ?? []);
              return AvailabilityHistoryItem(
                id: (r['id'] ?? '').toString(),
                submittedAt: r['submitted_at'] != null ? DateTime.tryParse(r['submitted_at']) ?? DateTime.now() : DateTime.now(),
                slotCount: slots.length,
                status: (r['status'] ?? 'submitted').toString(),
                semesterNama: _semesterLabel((r['semester_id'] ?? '').toString()),
              );
            }).toList();
            return List.unmodifiable(list);
          }
        }
      } catch (_) {}
    }
    await Future.delayed(MockDatabase.defaultDelay);
    return List.unmodifiable(MockDatabase.availabilityHistory);
  }

  /// GET Admin Submission Toggle status
  Future<bool> getSubmissionActive() async {
    return MockDatabase.isSubmissionActive;
  }

  Future<bool> getSubmissionWindowStatus() async {
    bool? localCached;
    try {
      final prefs = await SharedPreferences.getInstance();
      localCached = prefs.getBool('cached_is_submission_active');
      if (localCached != null) {
        MockDatabase.isSubmissionActive = localCached;
      }
    } catch (_) {}

    if (!ApiConfig.useMockBackend) {
      try {
        final data = await _httpHelper.makeOnlineRequest('/availability/status.php');
        if (data is Map && data['status'] == 'success' && data['isActive'] != null) {
          final serverActive = (data['isActive'] == true);
          if (localCached == null) {
            MockDatabase.isSubmissionActive = serverActive;
            try {
              final prefs = await SharedPreferences.getInstance();
              await prefs.setBool('cached_is_submission_active', serverActive);
            } catch (_) {}
          }
          return MockDatabase.isSubmissionActive;
        }
      } catch (_) {}
    }
    return MockDatabase.isSubmissionActive;
  }

  /// TOGGLE Admin Submission ON / OFF
  Future<bool> toggleSubmissionActive() async {
    MockDatabase.isSubmissionActive = !MockDatabase.isSubmissionActive;
    await setSubmissionWindowStatus(MockDatabase.isSubmissionActive);
    return MockDatabase.isSubmissionActive;
  }

  Future<void> setSubmissionWindowStatus(bool active) async {
    MockDatabase.isSubmissionActive = active;
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool('cached_is_submission_active', active);
    } catch (_) {}

    if (!ApiConfig.useMockBackend) {
      try {
        await _httpHelper.makeOnlineRequest(
          '/availability/status.php',
          method: 'POST',
          body: {'active': active},
        );
      } catch (_) {}
    }
    await Future.delayed(const Duration(milliseconds: 150));
  }

  /// KaProdi Verify Submission for a Lecturer
  Future<void> kajurVerifySubmission(String dosenId) async {
    MockDatabase.dosenSubmissionStatus[dosenId] = 'Diverifikasi KaProdi';
    if (!ApiConfig.useMockBackend) {
      try {
        await _httpHelper.makeOnlineRequest(
          '/availability/verify.php',
          method: 'POST',
          body: {'action': 'verify_kajur', 'dosenId': dosenId},
        );
      } catch (_) {}
    }
    await Future.delayed(const Duration(milliseconds: 200));
  }

  /// GET Multi-tier status of lecturer submission
  String getDosenSubmissionStatus(String dosenId) {
    return MockDatabase.dosenSubmissionStatus[dosenId] ?? 'Belum Mengisi';
  }

  /// GET Occupied Slot IDs taken by other lecturers
  /// Slot matriks bukan sumber daya eksklusif antar-dosen (banyak dosen bisa mengajar
  /// di jam yang sama pada ruangan berbeda), sehingga tidak ada slot yang dikunci di sini.
  /// Bentrok ruangan/dosen divalidasi saat review KaProdi/Admin dan oleh engine CSP.
  Set<String> getOccupiedSlotsForOtherDosen(String currentDosenId) {
    return <String>{};
  }

  /// GET All Teaching Proposals
  Future<List<AjuanPengajaranModel>> getAjuanPengajaranList({
    String? dosenId,
    String? fakultas,
    String? prodi,
    String? status,
  }) async {
    // 1. Prioritaskan pengambilan data real-time langsung dari Supabase Cloud
    if (!ApiConfig.useMockBackend) {
      try {
        final uri = Uri.parse('${ApiConfig.supabaseUrl}/rest/v1/ajuan_pengajaran?select=*&order=created_at.desc');
        final resp = await http.get(
          uri,
          headers: ApiConfig.supabaseHeaders,
        ).timeout(const Duration(seconds: 6));
        if (resp.statusCode == 200) {
          final decoded = jsonDecode(resp.body);
          if (decoded is List) {
            final list = decoded
                .map((a) => AjuanPengajaranModel.fromJson(Map<String, dynamic>.from(a)))
                .where((a) => !MockDatabase.deletedAjuanIds.contains(a.id))
                .toList();
            // Pertahankan ajuan hasil Matriks Ketersediaan yang tersimpan lokal
            // tetapi belum tersinkron ke cloud (mis. koneksi gagal saat submit).
            final cloudIds = list.map((a) => a.id).toSet();
            final pendingLocal = MockDatabase.ajuanPengajaranList
                .where((a) =>
                    a.id.startsWith('AJU_AVL_') &&
                    !cloudIds.contains(a.id) &&
                    !MockDatabase.deletedAjuanIds.contains(a.id))
                .toList();
            list.insertAll(0, pendingLocal);
            MockDatabase.ajuanPengajaranList
              ..clear()
              ..addAll(list);
            await MockDatabase.saveLocalAjuan();
            final onlineFiltered = list.where((a) {
              if (dosenId != null && dosenId.isNotEmpty && a.dosenId != dosenId) return false;
              if (fakultas != null && fakultas.isNotEmpty && a.fakultasNama != fakultas) return false;
              if (prodi != null && prodi.isNotEmpty && a.jurusanNama != prodi) return false;
              if (status != null && status.isNotEmpty && a.status != status) return false;
              return true;
            }).toList();
            return List.unmodifiable(onlineFiltered);
          }
        }
      } catch (_) {}
    }

    await MockDatabase.initLocalCache();
    await Future.delayed(const Duration(milliseconds: 100));
    final filtered = MockDatabase.ajuanPengajaranList.where((a) {
      if (dosenId != null && dosenId.isNotEmpty && a.dosenId != dosenId) return false;
      if (fakultas != null && fakultas.isNotEmpty && a.fakultasNama != fakultas) return false;
      if (prodi != null && prodi.isNotEmpty && a.jurusanNama != prodi) return false;
      if (status != null && status.isNotEmpty && a.status != status) return false;
      return true;
    }).toList();
    return List.unmodifiable(filtered);
  }

  /// SUBMIT New Teaching Proposal
  Future<AjuanPengajaranModel> submitAjuanPengajaran(AjuanPengajaranModel ajuan) async {
    // 1. Coba lewat backend Python
    if (!ApiConfig.useMockBackend) {
      try {
        final data = await _httpHelper.makeOnlineRequest(
          '/ajuan/index.php',
          method: 'POST',
          body: ajuan.toJson(),
        );
        if (data is Map && data['status'] == 'success' && data['data'] != null) {
          final saved = AjuanPengajaranModel.fromJson(data['data']);
          MockDatabase.ajuanPengajaranList.insert(0, saved);
          MockDatabase.dosenSubmissionStatus[saved.dosenId] = 'Diajukan';
          await MockDatabase.saveLocalAjuan();

          // Broadcast notifications to KaProdi, Dekan, and Admin
          try {
            await _notificationService.sendNotification(
              userId: 'kaprodi',
              title: 'Ajuan Pengajaran Masuk',
              message: '${saved.dosenNama} (${saved.jurusanNama}) telah mengajukan jadwal ${saved.mataKuliahNama} (${saved.sks} SKS).',
              type: 'info',
            );
            await _notificationService.sendNotification(
              userId: 'dekan',
              title: 'Ajuan Pengajaran Dikirim',
              message: '${saved.dosenNama} (${saved.fakultasNama}) mengajukan jadwal perkuliahan baru.',
              type: 'info',
            );
            await _notificationService.sendNotification(
              userId: 'admin',
              title: 'Ajuan Pengajaran Masuk',
              message: '${saved.dosenNama} telah mengirim ajuan ${saved.mataKuliahNama} untuk semester ini.',
              type: 'info',
            );
          } catch (_) {}

          return saved;
        }
      } catch (_) {}
    }

    // 2. Direct Supabase Cloud Sync
    try {
      final uri = Uri.parse('${ApiConfig.supabaseUrl}/rest/v1/ajuan_pengajaran');
      await http.post(
        uri,
        headers: {
          'apikey': ApiConfig.supabasePublishableKey,
          'Authorization': 'Bearer ${ApiConfig.supabasePublishableKey}',
          'Content-Type': 'application/json',
          'Prefer': 'resolution=merge-duplicates',
        },
        body: jsonEncode({
          'id': ajuan.id,
          'dosen_id': ajuan.dosenId,
          'dosen_nama': ajuan.dosenNama,
          'fakultas_nama': ajuan.fakultasNama,
          'jurusan_nama': ajuan.jurusanNama,
          'mata_kuliah_id': ajuan.mataKuliahId,
          'mata_kuliah_nama': ajuan.mataKuliahNama,
          'sks': ajuan.sks,
          'semester': ajuan.semester,
          'kelas_nama': ajuan.kelasNama,
          'jumlah_mahasiswa': ajuan.jumlahMahasiswa,
          'gedung_nama': ajuan.gedungNama,
          'ruangan_nama': ajuan.ruanganNama,
          'hari': ajuan.hari,
          'jam_mulai': ajuan.jamMulai,
          'jam_selesai': ajuan.jamSelesai,
          'status': ajuan.status,
          'catatan_dosen': ajuan.catatanDosen,
          'catatan_kaprodi': ajuan.catatanKaProdi,
          'catatan_dekan': ajuan.catatanDekan,
          'catatan_admin': ajuan.catatanAdmin,
          'alasan_penolakan': ajuan.alasanPenolakan,
          'bentrok_detail': ajuan.bentrokDetail,
        }),
      ).timeout(const Duration(seconds: 5));
    } catch (_) {}

    await Future.delayed(const Duration(milliseconds: 250));
    MockDatabase.ajuanPengajaranList.insert(0, ajuan);
    MockDatabase.dosenSubmissionStatus[ajuan.dosenId] = 'Diajukan';
    await MockDatabase.saveLocalAjuan();

    // Broadcast notifications to KaProdi, Dekan, and Admin
    try {
      await _notificationService.sendNotification(
        userId: 'kaprodi',
        title: 'Ajuan Pengajaran Masuk',
        message: '${ajuan.dosenNama} (${ajuan.jurusanNama}) telah mengajukan jadwal ${ajuan.mataKuliahNama} (${ajuan.sks} SKS).',
        type: 'info',
      );
      await _notificationService.sendNotification(
        userId: 'dekan',
        title: 'Ajuan Pengajaran Dikirim',
        message: '${ajuan.dosenNama} (${ajuan.fakultasNama}) mengajukan jadwal perkuliahan baru.',
        type: 'info',
      );
      await _notificationService.sendNotification(
        userId: 'admin',
        title: 'Ajuan Pengajaran Masuk',
        message: '${ajuan.dosenNama} telah mengirim ajuan ${ajuan.mataKuliahNama} untuk semester ini.',
        type: 'info',
      );
    } catch (_) {}

    return ajuan;
  }

  /// UPDATE Teaching Proposal
  Future<AjuanPengajaranModel> updateAjuanPengajaran(AjuanPengajaranModel updated) async {
    // 1. Backend Python
    if (!ApiConfig.useMockBackend) {
      try {
        final data = await _httpHelper.makeOnlineRequest(
          '/ajuan/index.php',
          method: 'PUT',
          body: updated.toJson(),
        );
        if (data is Map && data['status'] == 'success' && data['data'] != null) {
          final saved = AjuanPengajaranModel.fromJson(data['data']);
          final idx = MockDatabase.ajuanPengajaranList.indexWhere((a) => a.id == saved.id);
          if (idx != -1) MockDatabase.ajuanPengajaranList[idx] = saved;
          await MockDatabase.saveLocalAjuan();
          return saved;
        }
      } catch (_) {}
    }

    // 2. Direct Supabase Cloud Sync
    try {
      final uri = Uri.parse('${ApiConfig.supabaseUrl}/rest/v1/ajuan_pengajaran?id=eq.${updated.id}');
      await http.patch(
        uri,
        headers: {
          'apikey': ApiConfig.supabasePublishableKey,
          'Authorization': 'Bearer ${ApiConfig.supabasePublishableKey}',
          'Content-Type': 'application/json',
        },
        body: jsonEncode({
          'status': updated.status,
          'gedung_nama': updated.gedungNama,
          'ruangan_nama': updated.ruanganNama,
          'hari': updated.hari,
          'jam_mulai': updated.jamMulai,
          'jam_selesai': updated.jamSelesai,
          'catatan_dosen': updated.catatanDosen,
          'catatan_kaprodi': updated.catatanKaProdi,
          'catatan_dekan': updated.catatanDekan,
          'catatan_admin': updated.catatanAdmin,
          'alasan_penolakan': updated.alasanPenolakan,
          'bentrok_detail': updated.bentrokDetail,
        }),
      ).timeout(const Duration(seconds: 5));
    } catch (_) {}

    await Future.delayed(const Duration(milliseconds: 200));
    final index = MockDatabase.ajuanPengajaranList.indexWhere((a) => a.id == updated.id);
    if (index != -1) {
      MockDatabase.ajuanPengajaranList[index] = updated.copyWith(updatedAt: DateTime.now());
      await MockDatabase.saveLocalAjuan();
      return MockDatabase.ajuanPengajaranList[index];
    }
    MockDatabase.ajuanPengajaranList.add(updated);
    await MockDatabase.saveLocalAjuan();
    return updated;
  }

  /// DELETE Teaching Proposal
  Future<void> deleteAjuanPengajaran(String ajuanId) async {
    // 0. Register in deleted IDs to avoid resurrection
    MockDatabase.deletedAjuanIds.add(ajuanId);
    MockDatabase.deletedJadwalIds.add(ajuanId);
    MockDatabase.deletedJadwalIds.add('JDW_$ajuanId');

    // 1. Immediately delete locally to eliminate all lag
    final target = MockDatabase.ajuanPengajaranList.where((a) => a.id == ajuanId).firstOrNull;
    MockDatabase.ajuanPengajaranList.removeWhere((a) => a.id == ajuanId);
    MockDatabase.jadwalFinal.removeWhere((j) =>
      j.id == ajuanId || j.id == 'JDW_$ajuanId' ||
      (target != null && j.mataKuliahNama == target.mataKuliahNama && j.kelasNama == target.kelasNama)
    );
    MockDatabase.jadwalGlobalMaster.removeWhere((j) =>
      j.id == ajuanId || j.id == 'JDW_$ajuanId' ||
      (target != null && j.mataKuliahNama == target.mataKuliahNama && j.kelasNama == target.kelasNama)
    );
    await MockDatabase.saveLocalAjuan();
    await MockDatabase.saveLocalJadwal();
    await MockDatabase.saveLocalDeletedIds();

    // 2. Perform online deletion in background (non-blocking)
    unawaited(Future(() async {
      if (!ApiConfig.useMockBackend) {
        try {
          await _httpHelper.makeOnlineRequest('/ajuan/index.php?id=$ajuanId', method: 'DELETE');
        } catch (_) {}
      }
      try {
        final uri = Uri.parse('${ApiConfig.supabaseUrl}/rest/v1/ajuan_pengajaran?id=eq.$ajuanId');
        await http.delete(
          uri,
          headers: {
            'apikey': ApiConfig.supabasePublishableKey,
            'Authorization': 'Bearer ${ApiConfig.supabasePublishableKey}',
          },
        ).timeout(const Duration(seconds: 5));

        final uriJadwal = Uri.parse('${ApiConfig.supabaseUrl}/rest/v1/jadwal_final?or=(id.eq.$ajuanId,id.eq.JDW_$ajuanId)');
        await http.delete(
          uriJadwal,
          headers: {
            'apikey': ApiConfig.supabasePublishableKey,
            'Authorization': 'Bearer ${ApiConfig.supabasePublishableKey}',
          },
        ).timeout(const Duration(seconds: 5));
      } catch (_) {}
    }));
  }

  /// DELETE Multiple Teaching Proposals
  Future<void> deleteMultipleAjuanPengajaran(List<String> ajuanIds) async {
    if (ajuanIds.isEmpty) return;
    final ajuanSet = ajuanIds.toSet();
    for (final id in ajuanIds) {
      MockDatabase.deletedAjuanIds.add(id);
      MockDatabase.deletedJadwalIds.add(id);
      MockDatabase.deletedJadwalIds.add('JDW_$id');
    }
    final itemsToDelete = MockDatabase.ajuanPengajaranList.where((a) => ajuanSet.contains(a.id)).toList();

    // 1. Immediately delete locally to eliminate all lag
    MockDatabase.ajuanPengajaranList.removeWhere((a) => ajuanSet.contains(a.id));
    MockDatabase.jadwalFinal.removeWhere((j) {
      if (ajuanSet.contains(j.id) || ajuanSet.any((id) => j.id == 'JDW_$id')) return true;
      return itemsToDelete.any((a) =>
        (j.mataKuliahNama == a.mataKuliahNama && j.kelasNama == a.kelasNama) ||
        (j.dosenId != null && j.dosenId == a.dosenId && j.mataKuliahNama == a.mataKuliahNama)
      );
    });
    MockDatabase.jadwalGlobalMaster.removeWhere((j) {
      if (ajuanSet.contains(j.id) || ajuanSet.any((id) => j.id == 'JDW_$id')) return true;
      return itemsToDelete.any((a) =>
        (j.mataKuliahNama == a.mataKuliahNama && j.kelasNama == a.kelasNama) ||
        (j.dosenId != null && j.dosenId == a.dosenId && j.mataKuliahNama == a.mataKuliahNama)
      );
    });

    await MockDatabase.saveLocalAjuan();
    await MockDatabase.saveLocalJadwal();
    await MockDatabase.saveLocalDeletedIds();

    // 2. Perform online background sync asynchronously in parallel (non-blocking)
    unawaited(Future(() async {
      if (!ApiConfig.useMockBackend) {
        try {
          await _httpHelper.makeOnlineRequest(
            '/ajuan/index.php',
            method: 'DELETE',
            body: {'ids': ajuanIds},
          );
        } catch (_) {}
      }
      try {
        await Future.wait(ajuanIds.map((id) async {
          final uri = Uri.parse('${ApiConfig.supabaseUrl}/rest/v1/ajuan_pengajaran?id=eq.$id');
          await http.delete(
            uri,
            headers: {
              'apikey': ApiConfig.supabasePublishableKey,
              'Authorization': 'Bearer ${ApiConfig.supabasePublishableKey}',
            },
          ).timeout(const Duration(seconds: 5));

          final uriJadwal = Uri.parse('${ApiConfig.supabaseUrl}/rest/v1/jadwal_final?or=(id.eq.$id,id.eq.JDW_$id)');
          await http.delete(
            uriJadwal,
            headers: {
              'apikey': ApiConfig.supabasePublishableKey,
              'Authorization': 'Bearer ${ApiConfig.supabasePublishableKey}',
            },
          ).timeout(const Duration(seconds: 5));
        }));
      } catch (_) {}
    }));
  }

  Future<void> _syncAjuanToSupabase(AjuanPengajaranModel ajuan) async {
    try {
      final uri = Uri.parse('${ApiConfig.supabaseUrl}/rest/v1/ajuan_pengajaran?id=eq.${ajuan.id}');
      await http.patch(
        uri,
        headers: {
          'apikey': ApiConfig.supabasePublishableKey,
          'Authorization': 'Bearer ${ApiConfig.supabasePublishableKey}',
          'Content-Type': 'application/json',
          'Prefer': 'return=minimal',
        },
        body: jsonEncode({
          'status': ajuan.status,
          'gedung_nama': ajuan.gedungNama,
          'ruangan_nama': ajuan.ruanganNama,
          'hari': ajuan.hari,
          'jam_mulai': ajuan.jamMulai,
          'jam_selesai': ajuan.jamSelesai,
          'catatan_dosen': ajuan.catatanDosen,
          'catatan_kaprodi': ajuan.catatanKaProdi,
          'catatan_dekan': ajuan.catatanDekan,
          'catatan_admin': ajuan.catatanAdmin,
          'alasan_penolakan': ajuan.alasanPenolakan,
          'alasan_banding': ajuan.alasanBanding,
          'preferensi_banding_hari': ajuan.preferensiBandingHari,
          'preferensi_banding_jam': ajuan.preferensiBandingJam,
          'bentrok_detail': ajuan.bentrokDetail,
          'updated_at': DateTime.now().toIso8601String(),
        }),
      ).timeout(const Duration(seconds: 4));
    } catch (_) {}
  }

  Future<void> _syncJadwalToSupabase(JadwalModel jadwal, {String? dosenId}) async {
    try {
      final uri = Uri.parse('${ApiConfig.supabaseUrl}/rest/v1/jadwal_final');
      await http.post(
        uri,
        headers: {
          'apikey': ApiConfig.supabasePublishableKey,
          'Authorization': 'Bearer ${ApiConfig.supabasePublishableKey}',
          'Content-Type': 'application/json',
          'Prefer': 'resolution=merge-duplicates,return=minimal',
        },
        body: jsonEncode({
          'id': jadwal.id,
          'mata_kuliah_id': jadwal.mataKuliahId,
          'mata_kuliah_nama': jadwal.mataKuliahNama,
          'sks': jadwal.sks,
          'ruangan_nama': jadwal.ruanganNama,
          'gedung_nama': jadwal.gedungNama,
          'kelas_nama': jadwal.kelasNama,
          'hari': jadwal.hari,
          'jam_mulai': jadwal.jamMulai,
          'jam_selesai': jadwal.jamSelesai,
          'dosen_id': dosenId ?? jadwal.dosenId,
          'dosen_nama': jadwal.dosenNama,
          'fakultas_nama': jadwal.fakultasNama,
          'jurusan_nama': jadwal.jurusanNama,
          'semester_nama': jadwal.semesterNama,
          'jumlah_mahasiswa': jadwal.jumlahMahasiswa,
        }),
      ).timeout(const Duration(seconds: 4));
    } catch (_) {}
  }

  /// KaProdi Verify & Forward to Dekan
  Future<AjuanPengajaranModel> kaprodiVerifyAjuan(
    String ajuanId, {
    AjuanPengajaranModel? updatedData,
    String? catatan,
  }) async {
    if (!ApiConfig.useMockBackend) {
      try {
        final data = await _httpHelper.makeOnlineRequest(
          '/ajuan/verify.php',
          method: 'POST',
          body: {
            'action': 'kaprodi_verify',
            'ajuanId': ajuanId,
            'catatan': catatan,
            'updatedData': updatedData?.toJson(),
          },
        );
        if (data is Map && data['status'] == 'success' && data['data'] != null) {
          final verified = AjuanPengajaranModel.fromJson(data['data']);
          final idx = MockDatabase.ajuanPengajaranList.indexWhere((a) => a.id == ajuanId);
          if (idx != -1) MockDatabase.ajuanPengajaranList[idx] = verified;
          MockDatabase.dosenSubmissionStatus[verified.dosenId] = 'Diverifikasi KaProdi';
          await MockDatabase.saveLocalAjuan();
          await _syncAjuanToSupabase(verified);
          await _notificationService.sendNotification(
            userId: verified.dosenId,
            title: 'Ajuan Diverifikasi Kaprodi',
            message: catatan != null && catatan.isNotEmpty ? 'Catatan: $catatan' : 'Ajuan jadwal Anda telah diverifikasi oleh Kaprodi.',
            type: 'success',
          );
          return verified;
        }
      } catch (_) {}
    }

    await Future.delayed(const Duration(milliseconds: 250));
    final index = MockDatabase.ajuanPengajaranList.indexWhere((a) => a.id == ajuanId);
    if (index != -1) {
      final base = updatedData ?? MockDatabase.ajuanPengajaranList[index];
      final verified = base.copyWith(
        status: 'menunggu_dekan',
        catatanKaProdi: catatan ?? base.catatanKaProdi ?? 'Diverifikasi oleh KaProdi.',
        clearBentrokDetail: true,
        updatedAt: DateTime.now(),
      );
      MockDatabase.ajuanPengajaranList[index] = verified;
      MockDatabase.dosenSubmissionStatus[verified.dosenId] = 'Diverifikasi KaProdi';
      await MockDatabase.saveLocalAjuan();
      await _syncAjuanToSupabase(verified);
      await _notificationService.sendNotification(
        userId: verified.dosenId,
        title: 'Ajuan Diverifikasi Kaprodi',
        message: catatan != null && catatan.isNotEmpty ? 'Catatan: $catatan' : 'Ajuan jadwal Anda telah diverifikasi oleh Kaprodi.',
        type: 'success',
      );
      return verified;
    }
    throw const ApiException('NOT_FOUND', 'Ajuan tidak ditemukan');
  }

  /// KaProdi Reject
  Future<AjuanPengajaranModel> kaprodiRejectAjuan(String ajuanId, String alasan) async {
    if (!ApiConfig.useMockBackend) {
      try {
        final data = await _httpHelper.makeOnlineRequest(
          '/ajuan/verify.php',
          method: 'POST',
          body: {
            'action': 'kaprodi_reject',
            'ajuanId': ajuanId,
            'alasan': alasan,
          },
        );
        if (data is Map && data['status'] == 'success' && data['data'] != null) {
          final rejected = AjuanPengajaranModel.fromJson(data['data']);
          final idx = MockDatabase.ajuanPengajaranList.indexWhere((a) => a.id == ajuanId);
          if (idx != -1) MockDatabase.ajuanPengajaranList[idx] = rejected;
          await MockDatabase.saveLocalAjuan();
          await _syncAjuanToSupabase(rejected);
          await _notificationService.sendNotification(
            userId: rejected.dosenId,
            title: 'Ajuan Ditolak Kaprodi',
            message: 'Alasan: $alasan',
            type: 'info',
          );
          return rejected;
        }
      } catch (_) {}
    }

    await Future.delayed(const Duration(milliseconds: 250));
    final index = MockDatabase.ajuanPengajaranList.indexWhere((a) => a.id == ajuanId);
    if (index != -1) {
      final rejected = MockDatabase.ajuanPengajaranList[index].copyWith(
        status: 'ditolak_kaprodi',
        alasanPenolakan: alasan,
        updatedAt: DateTime.now(),
      );
      MockDatabase.ajuanPengajaranList[index] = rejected;
      await MockDatabase.saveLocalAjuan();
      await _syncAjuanToSupabase(rejected);
      await _notificationService.sendNotification(
        userId: rejected.dosenId,
        title: 'Ajuan Ditolak Kaprodi',
        message: 'Alasan: $alasan',
        type: 'info',
      );
      return rejected;
    }
    throw const ApiException('NOT_FOUND', 'Ajuan tidak ditemukan');
  }

  /// Dekan Approve & Forward to Admin
  Future<AjuanPengajaranModel> dekanApproveAjuan(
    String ajuanId, {
    AjuanPengajaranModel? updatedData,
    String? catatan,
  }) async {
    if (!ApiConfig.useMockBackend) {
      try {
        final data = await _httpHelper.makeOnlineRequest(
          '/ajuan/verify.php',
          method: 'POST',
          body: {
            'action': 'dekan_approve',
            'ajuanId': ajuanId,
            'catatan': catatan,
            'updatedData': updatedData?.toJson(),
          },
        );
        if (data is Map && data['status'] == 'success' && data['data'] != null) {
          final approved = AjuanPengajaranModel.fromJson(data['data']);
          final idx = MockDatabase.ajuanPengajaranList.indexWhere((a) => a.id == ajuanId);
          if (idx != -1) MockDatabase.ajuanPengajaranList[idx] = approved;
          MockDatabase.dosenSubmissionStatus[approved.dosenId] = 'Disetujui Dekan';
          await MockDatabase.saveLocalAjuan();
          await _syncAjuanToSupabase(approved);
          await _notificationService.sendNotification(
            userId: approved.dosenId,
            title: 'Ajuan Disetujui Dekan',
            message: catatan != null && catatan.isNotEmpty ? 'Catatan: $catatan' : 'Ajuan jadwal Anda telah disetujui oleh Dekan.',
            type: 'success',
          );
          return approved;
        }
      } catch (_) {}
    }

    await Future.delayed(const Duration(milliseconds: 250));
    final index = MockDatabase.ajuanPengajaranList.indexWhere((a) => a.id == ajuanId);
    if (index != -1) {
      final base = updatedData ?? MockDatabase.ajuanPengajaranList[index];
      final approved = base.copyWith(
        status: 'menunggu_admin',
        catatanDekan: catatan ?? base.catatanDekan ?? 'Disetujui Dekan Fakultas.',
        clearBentrokDetail: true,
        updatedAt: DateTime.now(),
      );
      MockDatabase.ajuanPengajaranList[index] = approved;
      MockDatabase.dosenSubmissionStatus[approved.dosenId] = 'Disetujui Dekan';
      await MockDatabase.saveLocalAjuan();
      await _syncAjuanToSupabase(approved);
      await _notificationService.sendNotification(
        userId: approved.dosenId,
        title: 'Ajuan Disetujui Dekan',
        message: catatan != null && catatan.isNotEmpty ? 'Catatan: $catatan' : 'Ajuan jadwal Anda telah disetujui oleh Dekan.',
        type: 'success',
      );
      return approved;
    }
    throw const ApiException('NOT_FOUND', 'Ajuan tidak ditemukan');
  }

  /// Dekan Reject
  Future<AjuanPengajaranModel> dekanRejectAjuan(String ajuanId, String alasan) async {
    if (!ApiConfig.useMockBackend) {
      try {
        final data = await _httpHelper.makeOnlineRequest(
          '/ajuan/verify.php',
          method: 'POST',
          body: {
            'action': 'dekan_reject',
            'ajuanId': ajuanId,
            'alasan': alasan,
          },
        );
        if (data is Map && data['status'] == 'success' && data['data'] != null) {
          final rejected = AjuanPengajaranModel.fromJson(data['data']);
          final idx = MockDatabase.ajuanPengajaranList.indexWhere((a) => a.id == ajuanId);
          if (idx != -1) MockDatabase.ajuanPengajaranList[idx] = rejected;
          await MockDatabase.saveLocalAjuan();
          await _syncAjuanToSupabase(rejected);
          await _notificationService.sendNotification(
            userId: rejected.dosenId,
            title: 'Ajuan Ditolak Dekan',
            message: 'Alasan: $alasan',
            type: 'info',
          );
          return rejected;
        }
      } catch (_) {}
    }

    await Future.delayed(const Duration(milliseconds: 250));
    final index = MockDatabase.ajuanPengajaranList.indexWhere((a) => a.id == ajuanId);
    if (index != -1) {
      final rejected = MockDatabase.ajuanPengajaranList[index].copyWith(
        status: 'ditolak_dekan',
        alasanPenolakan: alasan,
        updatedAt: DateTime.now(),
      );
      MockDatabase.ajuanPengajaranList[index] = rejected;
      await MockDatabase.saveLocalAjuan();
      await _syncAjuanToSupabase(rejected);
      return rejected;
    }
    throw const ApiException('NOT_FOUND', 'Ajuan tidak ditemukan');
  }

  /// Admin Final Approve & Official Schedule Generation
  Future<AjuanPengajaranModel> adminApproveFinalAjuan(
    String ajuanId, {
    AjuanPengajaranModel? updatedData,
    String? catatan,
  }) async {
    if (!ApiConfig.useMockBackend) {
      try {
        final data = await _httpHelper.makeOnlineRequest(
          '/ajuan/verify.php',
          method: 'POST',
          body: {
            'action': 'admin_approve',
            'ajuanId': ajuanId,
            'catatan': catatan,
            'updatedData': updatedData?.toJson(),
          },
        );
        if (data is Map && data['status'] == 'success' && data['data'] != null) {
          final approved = AjuanPengajaranModel.fromJson(data['data']);
          final idx = MockDatabase.ajuanPengajaranList.indexWhere((a) => a.id == ajuanId);
          if (idx != -1) MockDatabase.ajuanPengajaranList[idx] = approved;
          await MockDatabase.saveLocalAjuan();
          await MockDatabase.saveLocalJadwal();
          await _syncAjuanToSupabase(approved);
          await _notificationService.sendNotification(
            userId: approved.dosenId,
            title: 'Jadwal Final Ditetapkan',
            message: catatan != null && catatan.isNotEmpty ? 'Catatan: $catatan' : 'Jadwal mengajar Anda telah resmi ditetapkan oleh Admin.',
            type: 'success',
          );

          final jdw = JadwalModel(
            id: 'JDW_${approved.id}',
            mataKuliahId: approved.mataKuliahId,
            mataKuliahNama: approved.mataKuliahNama,
            sks: approved.sks,
            ruanganNama: approved.ruanganNama,
            gedungNama: approved.gedungNama,
            kelasNama: approved.kelasNama,
            hari: approved.hari,
            jamMulai: approved.jamMulai,
            jamSelesai: approved.jamSelesai,
            semesterNama: 'Ganjil 2026/2027',
            jumlahMahasiswa: approved.jumlahMahasiswa,
            dosenNama: approved.dosenNama,
            fakultasNama: approved.fakultasNama,
            jurusanNama: approved.jurusanNama,
          );
          await _syncJadwalToSupabase(jdw, dosenId: approved.dosenId);
          return approved;
        }
      } catch (_) {}
    }

    await Future.delayed(const Duration(milliseconds: 300));
    final index = MockDatabase.ajuanPengajaranList.indexWhere((a) => a.id == ajuanId);
    if (index != -1) {
      final base = updatedData ?? MockDatabase.ajuanPengajaranList[index];
      final approved = base.copyWith(
        status: 'disetujui_admin',
        catatanAdmin: catatan ?? base.catatanAdmin ?? 'Ditetapkan resmi oleh Admin Institusi.',
        clearBentrokDetail: true,
        updatedAt: DateTime.now(),
      );
      MockDatabase.ajuanPengajaranList[index] = approved;

      final newJadwal = JadwalModel(
        id: 'JDW_${base.id}',
        mataKuliahId: base.mataKuliahId,
        mataKuliahNama: base.mataKuliahNama,
        sks: base.sks,
        ruanganNama: base.ruanganNama,
        gedungNama: base.gedungNama,
        kelasNama: base.kelasNama,
        hari: base.hari,
        jamMulai: base.jamMulai,
        jamSelesai: base.jamSelesai,
        semesterNama: 'Ganjil 2026/2027',
        jumlahMahasiswa: base.jumlahMahasiswa,
        dosenNama: base.dosenNama,
        fakultasNama: base.fakultasNama,
        jurusanNama: base.jurusanNama,
      );
      MockDatabase.jadwalFinal.removeWhere((j) => j.id == newJadwal.id || (j.mataKuliahNama == newJadwal.mataKuliahNama && j.kelasNama == newJadwal.kelasNama));
      MockDatabase.jadwalFinal.add(newJadwal);
      MockDatabase.jadwalGlobalMaster.removeWhere((j) => j.id == newJadwal.id || (j.mataKuliahNama == newJadwal.mataKuliahNama && j.kelasNama == newJadwal.kelasNama));
      MockDatabase.jadwalGlobalMaster.add(newJadwal);

      await MockDatabase.saveLocalAjuan();
      await MockDatabase.saveLocalJadwal();
      await _syncAjuanToSupabase(approved);
      await _syncJadwalToSupabase(newJadwal, dosenId: approved.dosenId);
      await _notificationService.sendNotification(
        userId: approved.dosenId,
        title: 'Jadwal Final Ditetapkan',
        message: catatan != null && catatan.isNotEmpty ? 'Catatan: $catatan' : 'Jadwal mengajar Anda telah resmi ditetapkan oleh Admin.',
        type: 'success',
      );
      return approved;
    }
    throw const ApiException('NOT_FOUND', 'Ajuan tidak ditemukan');
  }

  /// Admin Reject
  Future<AjuanPengajaranModel> adminRejectAjuan(String ajuanId, String alasan) async {
    if (!ApiConfig.useMockBackend) {
      try {
        final data = await _httpHelper.makeOnlineRequest(
          '/ajuan/verify.php',
          method: 'POST',
          body: {
            'action': 'admin_reject',
            'ajuanId': ajuanId,
            'alasan': alasan,
          },
        );
        if (data is Map && data['status'] == 'success' && data['data'] != null) {
          final rejected = AjuanPengajaranModel.fromJson(data['data']);
          final idx = MockDatabase.ajuanPengajaranList.indexWhere((a) => a.id == ajuanId);
          if (idx != -1) MockDatabase.ajuanPengajaranList[idx] = rejected;
          await MockDatabase.saveLocalAjuan();
          await _syncAjuanToSupabase(rejected);
          await _notificationService.sendNotification(
            userId: rejected.dosenId,
            title: 'Ajuan Ditolak Admin',
            message: 'Alasan: $alasan',
            type: 'info',
          );
          return rejected;
        }
      } catch (_) {}
    }

    await Future.delayed(const Duration(milliseconds: 250));
    final index = MockDatabase.ajuanPengajaranList.indexWhere((a) => a.id == ajuanId);
    if (index != -1) {
      final rejected = MockDatabase.ajuanPengajaranList[index].copyWith(
        status: 'ditolak_admin',
        alasanPenolakan: alasan,
        updatedAt: DateTime.now(),
      );
      MockDatabase.ajuanPengajaranList[index] = rejected;
      await MockDatabase.saveLocalAjuan();
      await _syncAjuanToSupabase(rejected);
      await _notificationService.sendNotification(
        userId: rejected.dosenId,
        title: 'Ajuan Ditolak Admin',
        message: 'Alasan: $alasan',
        type: 'info',
      );
      return rejected;
    }
    throw const ApiException('NOT_FOUND', 'Ajuan tidak ditemukan');
  }

  /// Dosen mengajukan banding
  Future<AjuanPengajaranModel> submitBandingAjuan({
    required String ajuanId,
    required String alasan,
    String? preferensiHari,
    String? preferensiJam,
  }) async {
    if (!ApiConfig.useMockBackend) {
      try {
        final data = await _httpHelper.makeOnlineRequest(
          '/ajuan/banding.php',
          method: 'POST',
          body: {
            'action': 'submit_banding',
            'ajuanId': ajuanId,
            'alasanBanding': alasan,
            'preferensiHari': preferensiHari,
            'preferensiJam': preferensiJam,
          },
        );
        if (data is Map && data['status'] == 'success' && data['data'] != null) {
          final updated = AjuanPengajaranModel.fromJson(data['data']);
          final idx = MockDatabase.ajuanPengajaranList.indexWhere((a) => a.id == ajuanId);
          if (idx != -1) MockDatabase.ajuanPengajaranList[idx] = updated;
          await MockDatabase.saveLocalAjuan();
          await _syncAjuanToSupabase(updated);
          await _notificationService.sendNotification(
            userId: 'admin', // Typically sent to admin or kaprodi, but for simplicity let's notify the lecturer that their appeal is received
            title: 'Banding Diajukan',
            message: 'Banding Anda telah berhasil diajukan dan sedang menunggu proses.',
            type: 'info',
          );
          return updated;
        }
      } catch (_) {}
    }

    await Future.delayed(const Duration(milliseconds: 250));
    final index = MockDatabase.ajuanPengajaranList.indexWhere((a) => a.id == ajuanId);
    if (index != -1) {
      final updated = MockDatabase.ajuanPengajaranList[index].copyWith(
        status: 'menunggu_banding',
        alasanBanding: alasan,
        preferensiBandingHari: preferensiHari,
        preferensiBandingJam: preferensiJam,
        updatedAt: DateTime.now(),
      );
      MockDatabase.ajuanPengajaranList[index] = updated;
      await MockDatabase.saveLocalAjuan();
      await _syncAjuanToSupabase(updated);
      await _notificationService.sendNotification(
        userId: updated.dosenId,
        title: 'Banding Diajukan',
        message: 'Banding Anda telah berhasil diajukan dan sedang menunggu proses.',
        type: 'info',
      );
      return updated;
    }
    throw const ApiException('NOT_FOUND', 'Ajuan tidak ditemukan');
  }

  /// Admin memproses pengajuan banding
  Future<AjuanPengajaranModel> adminProcessBanding({
    required String ajuanId,
    required bool approve,
    String? catatanAdmin,
    AjuanPengajaranModel? updatedData,
  }) async {
    if (!ApiConfig.useMockBackend) {
      try {
        final data = await _httpHelper.makeOnlineRequest(
          '/ajuan/banding.php',
          method: 'POST',
          body: {
            'action': 'admin_process_banding',
            'ajuanId': ajuanId,
            'approve': approve,
            'catatanAdmin': catatanAdmin,
            'updatedData': updatedData?.toJson(),
          },
        );
        if (data is Map && data['status'] == 'success' && data['data'] != null) {
          final updated = AjuanPengajaranModel.fromJson(data['data']);
          final idx = MockDatabase.ajuanPengajaranList.indexWhere((a) => a.id == ajuanId);
          if (idx != -1) MockDatabase.ajuanPengajaranList[idx] = updated;
          await MockDatabase.saveLocalAjuan();
          await _syncAjuanToSupabase(updated);

          if (approve) {
            final jdw = JadwalModel(
              id: 'JDW_${updated.id}',
              mataKuliahId: updated.mataKuliahId,
              mataKuliahNama: updated.mataKuliahNama,
              sks: updated.sks,
              ruanganNama: updated.ruanganNama,
              gedungNama: updated.gedungNama,
              kelasNama: updated.kelasNama,
              hari: updated.hari,
              jamMulai: updated.jamMulai,
              jamSelesai: updated.jamSelesai,
              semesterNama: 'Ganjil 2026/2027',
              jumlahMahasiswa: updated.jumlahMahasiswa,
              dosenNama: updated.dosenNama,
              fakultasNama: updated.fakultasNama,
              jurusanNama: updated.jurusanNama,
            );
            final jdwIndex = MockDatabase.jadwalFinal.indexWhere((j) => j.id == 'JDW_${updated.id}');
            if (jdwIndex != -1) {
              MockDatabase.jadwalFinal[jdwIndex] = jdw;
            } else {
              MockDatabase.jadwalFinal.add(jdw);
            }
            await MockDatabase.saveLocalJadwal();
            await _syncJadwalToSupabase(jdw, dosenId: updated.dosenId);
          }
          await _notificationService.sendNotification(
            userId: updated.dosenId,
            title: approve ? 'Banding Disetujui' : 'Banding Ditolak',
            message: approve ? 'Banding jadwal Anda telah disetujui Admin.' : 'Banding jadwal Anda ditolak Admin.',
            type: approve ? 'success' : 'info',
          );
          return updated;
        }
      } catch (_) {}
    }

    await Future.delayed(const Duration(milliseconds: 300));
    final index = MockDatabase.ajuanPengajaranList.indexWhere((a) => a.id == ajuanId);
    if (index != -1) {
      final base = updatedData ?? MockDatabase.ajuanPengajaranList[index];
      final newStatus = approve ? 'banding_disetujui' : 'banding_ditolak';
      final updated = base.copyWith(
        status: newStatus,
        catatanAdmin: catatanAdmin ?? (approve ? 'Banding disetujui. Jadwal telah disesuaikan resmi.' : 'Banding ditolak oleh Admin.'),
        clearBentrokDetail: true,
        updatedAt: DateTime.now(),
      );
      MockDatabase.ajuanPengajaranList[index] = updated;

      if (approve) {
        final jdw = JadwalModel(
          id: 'JDW_${base.id}',
          mataKuliahId: base.mataKuliahId,
          mataKuliahNama: base.mataKuliahNama,
          sks: base.sks,
          ruanganNama: base.ruanganNama,
          gedungNama: base.gedungNama,
          kelasNama: base.kelasNama,
          hari: base.hari,
          jamMulai: base.jamMulai,
          jamSelesai: base.jamSelesai,
          semesterNama: 'Ganjil 2026/2027',
          jumlahMahasiswa: base.jumlahMahasiswa,
          dosenNama: base.dosenNama,
          fakultasNama: base.fakultasNama,
          jurusanNama: base.jurusanNama,
        );
        final jdwIndex = MockDatabase.jadwalFinal.indexWhere((j) => j.id == 'JDW_${base.id}');
        if (jdwIndex != -1) {
          MockDatabase.jadwalFinal[jdwIndex] = jdw;
        } else {
          MockDatabase.jadwalFinal.add(jdw);
        }
        await MockDatabase.saveLocalJadwal();
        await _syncJadwalToSupabase(jdw, dosenId: updated.dosenId);
      }
      await MockDatabase.saveLocalAjuan();
      await _syncAjuanToSupabase(updated);
      await _notificationService.sendNotification(
        userId: updated.dosenId,
        title: approve ? 'Banding Disetujui' : 'Banding Ditolak',
        message: approve ? 'Banding jadwal Anda telah disetujui Admin.' : 'Banding jadwal Anda ditolak Admin.',
        type: approve ? 'success' : 'info',
      );
      return updated;
    }
    throw const ApiException('NOT_FOUND', 'Ajuan tidak ditemukan');
  }
}


