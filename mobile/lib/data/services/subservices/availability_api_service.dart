import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import '../../../config/api_config.dart';
import '../../models/availability_model.dart';
import '../../models/ajuan_pengajaran_model.dart';
import '../../models/jadwal_model.dart';
import '../../mock/mock_database.dart';
import 'api_http_helper.dart';
import 'master_data_api_service.dart';

class AvailabilityApiService {
  final ApiHttpHelper _httpHelper;
  final MasterDataApiService _masterDataService;

  AvailabilityApiService({
    ApiHttpHelper? httpHelper,
    MasterDataApiService? masterDataService,
  })  : _httpHelper = httpHelper ?? ApiHttpHelper(),
        _masterDataService = masterDataService ?? MasterDataApiService(httpHelper: httpHelper);

  /// GET /api/availability/index.php
  Future<AvailabilityModel> getAvailability(String dosenId, String semesterId) async {
    // 1. Coba lewat backend Python
    if (!ApiConfig.useMockBackend) {
      try {
        final res = await _httpHelper.makeOnlineRequest('/availability/index.php?dosen_id=$dosenId&semester_id=$semesterId');
        if (res is Map && res['status'] == 'success' && res['data'] != null) {
          final model = AvailabilityModel.fromJson(Map<String, dynamic>.from(res['data']));
          MockDatabase.currentAvailability = model;
          return model;
        }
      } catch (_) {}
    }

    // 2. Direct Supabase Cloud Fallback
    try {
      final uri = Uri.parse('${ApiConfig.supabaseUrl}/rest/v1/availability?dosen_id=eq.$dosenId&semester_id=eq.$semesterId&select=*,availability_slots(*)');
      final resp = await http.get(
        uri,
        headers: {
          'apikey': ApiConfig.supabasePublishableKey,
          'Authorization': 'Bearer ${ApiConfig.supabasePublishableKey}',
          'Accept': 'application/json',
        },
      ).timeout(const Duration(seconds: 6));

      if (resp.statusCode == 200) {
        final decoded = jsonDecode(resp.body);
        if (decoded is List && decoded.isNotEmpty) {
          final raw = decoded.first as Map<String, dynamic>;
          final slots = (raw['availability_slots'] as List? ?? [])
              .map((s) => (s['slot_id'] ?? '').toString())
              .where((s) => s.isNotEmpty)
              .toList();
          final model = AvailabilityModel(
            id: raw['id'] ?? 'AVL_$dosenId',
            dosenId: raw['dosen_id'] ?? dosenId,
            semesterId: raw['semester_id'] ?? semesterId,
            selectedSlotIds: slots,
            status: raw['status'] ?? 'submitted',
            submittedAt: raw['submitted_at'] != null ? DateTime.tryParse(raw['submitted_at']) : DateTime.now(),
          );
          MockDatabase.currentAvailability = model;
          return model;
        }
      }
    } catch (_) {}

    await Future.delayed(const Duration(milliseconds: 100));
    if (MockDatabase.currentAvailability != null) {
      return MockDatabase.currentAvailability!;
    }
    final isDeleted = MockDatabase.deletedUserIds.contains(dosenId);
    final hasMatkul = MockDatabase.matkulData.isNotEmpty;
    if (isDeleted || !hasMatkul) {
      return AvailabilityModel(
        id: 'AVL_$dosenId',
        dosenId: dosenId,
        semesterId: semesterId,
        selectedSlotIds: const [],
        slotTags: const {},
        status: 'draft',
      );
    }
    return AvailabilityModel(
      id: 'AVL001',
      dosenId: dosenId,
      semesterId: semesterId,
      selectedSlotIds: const [
        'SLOT005', 'SLOT006', 'SLOT007', 'SLOT008',
        'SLOT016', 'SLOT017', 'SLOT018',
        'SLOT020', 'SLOT021',
        'SLOT027', 'SLOT028', 'SLOT029',
        'SLOT038', 'SLOT039', 'SLOT040', 'SLOT041',
        'SLOT051', 'SLOT052',
      ],
      slotTags: const {
        'SLOT005': SlotTagInfo(
          mataKuliahId: 'MK001',
          mataKuliahNama: 'Algoritma & Pemrograman',
          kelasNama: 'TI-1A',
          jurusanNama: 'Teknik Informatika',
          fakultasNama: 'Fakultas Sains & Teknologi',
          sks: 3,
        ),
        'SLOT006': SlotTagInfo(
          mataKuliahId: 'MK001',
          mataKuliahNama: 'Algoritma & Pemrograman',
          kelasNama: 'TI-1A',
          jurusanNama: 'Teknik Informatika',
          fakultasNama: 'Fakultas Sains & Teknologi',
          sks: 3,
        ),
        'SLOT016': SlotTagInfo(
          mataKuliahId: 'MK-SI01',
          mataKuliahNama: 'Sistem Informasi Enterprise',
          kelasNama: 'SI-3A',
          jurusanNama: 'Sistem Informasi',
          fakultasNama: 'Fakultas Sains & Teknologi',
          sks: 3,
        ),
      },
      status: 'submitted',
      submittedAt: DateTime(2026, 9, 5),
    );
  }

  /// POST /api/availability/index.php
  Future<AvailabilityModel> saveAvailability({
    required String dosenId,
    required String semesterId,
    required List<String> selectedSlotIds,
    Map<String, SlotTagInfo>? slotTags,
  }) async {
    final tagsMap = slotTags ?? MockDatabase.currentAvailability?.slotTags ?? {};

    if (!ApiConfig.useMockBackend) {
      try {
        final payload = {
          'dosen_id': dosenId,
          'semester_id': semesterId,
          'selectedSlotIds': selectedSlotIds,
          'slotTags': tagsMap.map((k, v) => MapEntry(k, v.toJson())),
        };
        final res = await _httpHelper.makeOnlineRequest(
          '/availability/index.php',
          method: 'POST',
          body: payload,
        );
        if (res is Map && res['status'] == 'success' && res['data'] != null) {
          final model = AvailabilityModel.fromJson(Map<String, dynamic>.from(res['data']));
          MockDatabase.currentAvailability = model;
          return model;
        }
      } catch (_) {}
    }

    await Future.delayed(const Duration(milliseconds: 150));

    final availability = AvailabilityModel(
      id: 'AVL_${DateTime.now().millisecondsSinceEpoch}',
      dosenId: dosenId,
      semesterId: semesterId,
      selectedSlotIds: selectedSlotIds,
      slotTags: tagsMap,
      status: 'submitted',
      submittedAt: DateTime.now(),
      updatedAt: DateTime.now(),
    );

    MockDatabase.currentAvailability = availability;

    MockDatabase.availabilityHistory.insert(
      0,
      AvailabilityHistoryItem(
        id: availability.id,
        submittedAt: DateTime.now(),
        slotCount: selectedSlotIds.length,
        status: 'submitted',
        semesterNama: 'Ganjil 2026/2027',
      ),
    );

    // Direct Supabase Cloud Sync
    try {
      final uri = Uri.parse('${ApiConfig.supabaseUrl}/rest/v1/availability');
      await http.post(
        uri,
        headers: {
          'apikey': ApiConfig.supabasePublishableKey,
          'Authorization': 'Bearer ${ApiConfig.supabasePublishableKey}',
          'Content-Type': 'application/json',
          'Prefer': 'resolution=merge-duplicates',
        },
        body: jsonEncode({
          'id': availability.id,
          'dosen_id': dosenId,
          'semester_id': semesterId,
          'status': 'submitted',
          'submitted_at': DateTime.now().toIso8601String(),
        }),
      ).timeout(const Duration(seconds: 5));

      if (selectedSlotIds.isNotEmpty) {
        final slotUri = Uri.parse('${ApiConfig.supabaseUrl}/rest/v1/availability_slots');
        final slotsPayload = selectedSlotIds.map((sid) => {
          'availability_id': availability.id,
          'slot_id': sid,
        }).toList();
        await http.post(
          slotUri,
          headers: {
            'apikey': ApiConfig.supabasePublishableKey,
            'Authorization': 'Bearer ${ApiConfig.supabasePublishableKey}',
            'Content-Type': 'application/json',
            'Prefer': 'resolution=merge-duplicates',
          },
          body: jsonEncode(slotsPayload),
        ).timeout(const Duration(seconds: 5));
      }
    } catch (_) {}

    return availability;
  }

  /// Validate pre-submit
  Future<({bool valid, int required, int provided, String? message})> validatePreSubmit({
    required String dosenId,
    required List<String> selectedSlotIds,
  }) async {
    await Future.delayed(const Duration(milliseconds: 150));

    final mataKuliah = await _masterDataService.getMataKuliah(dosenId);
    final totalSks = mataKuliah.fold<int>(0, (sum, mk) => sum + mk.sks);

    if (selectedSlotIds.length < totalSks) {
      return (
        valid: false,
        required: totalSks,
        provided: selectedSlotIds.length,
        message: 'Jumlah slot yang dipilih (${selectedSlotIds.length}) kurang dari total SKS ($totalSks). Silakan tambah minimal ${totalSks - selectedSlotIds.length} slot lagi.',
      );
    }
    return (
      valid: true,
      required: totalSks,
      provided: selectedSlotIds.length,
      message: null,
    );
  }

  /// GET availability history
  Future<List<AvailabilityHistoryItem>> getAvailabilityHistory(String dosenId) async {
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
  Set<String> getOccupiedSlotsForOtherDosen(String currentDosenId) {
    return {'SLOT010', 'SLOT025'};
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
          headers: {
            'apikey': ApiConfig.supabasePublishableKey,
            'Authorization': 'Bearer ${ApiConfig.supabasePublishableKey}',
            'Accept': 'application/json',
          },
        ).timeout(const Duration(seconds: 6));
        if (resp.statusCode == 200) {
          final decoded = jsonDecode(resp.body);
          if (decoded is List && decoded.isNotEmpty) {
            final list = decoded.map((a) => AjuanPengajaranModel.fromJson(Map<String, dynamic>.from(a))).toList();
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
    // 1. Backend Python
    if (!ApiConfig.useMockBackend) {
      try {
        await _httpHelper.makeOnlineRequest('/ajuan/index.php?id=$ajuanId', method: 'DELETE');
      } catch (_) {}
    }

    // 2. Direct Supabase Cloud
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

    await Future.delayed(const Duration(milliseconds: 150));
    MockDatabase.ajuanPengajaranList.removeWhere((a) => a.id == ajuanId);
    MockDatabase.jadwalFinal.removeWhere((j) => j.id == ajuanId || j.id == 'JDW_$ajuanId');
    MockDatabase.jadwalGlobalMaster.removeWhere((j) => j.id == ajuanId || j.id == 'JDW_$ajuanId');
    await MockDatabase.saveLocalAjuan();
    await MockDatabase.saveLocalJadwal();
  }

  /// DELETE Multiple Teaching Proposals
  Future<void> deleteMultipleAjuanPengajaran(List<String> ajuanIds) async {
    if (ajuanIds.isEmpty) return;
    if (!ApiConfig.useMockBackend) {
      try {
        await _httpHelper.makeOnlineRequest(
          '/ajuan/index.php',
          method: 'DELETE',
          body: {'ids': ajuanIds},
        );
      } catch (_) {
        for (final id in ajuanIds) {
          try {
            await _httpHelper.makeOnlineRequest('/ajuan/index.php?id=$id', method: 'DELETE');
          } catch (_) {}
        }
      }
    }
    try {
      for (final id in ajuanIds) {
        final uri = Uri.parse('${ApiConfig.supabaseUrl}/rest/v1/ajuan_pengajaran?id=eq.$id');
        await http.delete(
          uri,
          headers: {
            'apikey': ApiConfig.supabasePublishableKey,
            'Authorization': 'Bearer ${ApiConfig.supabasePublishableKey}',
          },
        ).timeout(const Duration(seconds: 3));

        final uriJadwal = Uri.parse('${ApiConfig.supabaseUrl}/rest/v1/jadwal_final?or=(id.eq.$id,id.eq.JDW_$id)');
        await http.delete(
          uriJadwal,
          headers: {
            'apikey': ApiConfig.supabasePublishableKey,
            'Authorization': 'Bearer ${ApiConfig.supabasePublishableKey}',
          },
        ).timeout(const Duration(seconds: 3));
      }
    } catch (_) {}

    await Future.delayed(const Duration(milliseconds: 150));
    MockDatabase.ajuanPengajaranList.removeWhere((a) => ajuanIds.contains(a.id));
    MockDatabase.jadwalFinal.removeWhere((j) => ajuanIds.contains(j.id) || ajuanIds.any((id) => j.id == 'JDW_$id'));
    MockDatabase.jadwalGlobalMaster.removeWhere((j) => ajuanIds.contains(j.id) || ajuanIds.any((id) => j.id == 'JDW_$id'));
    await MockDatabase.saveLocalAjuan();
    await MockDatabase.saveLocalJadwal();
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
        updatedAt: DateTime.now(),
      );
      MockDatabase.ajuanPengajaranList[index] = verified;
      MockDatabase.dosenSubmissionStatus[verified.dosenId] = 'Diverifikasi KaProdi';
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
        updatedAt: DateTime.now(),
      );
      MockDatabase.ajuanPengajaranList[index] = approved;
      MockDatabase.dosenSubmissionStatus[approved.dosenId] = 'Disetujui Dekan';
      await MockDatabase.saveLocalAjuan();
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
        updatedAt: DateTime.now(),
      );
      MockDatabase.ajuanPengajaranList[index] = updated;

      final jdwIndex = MockDatabase.jadwalFinal.indexWhere((j) => j.id == 'JDW_${base.id}');
      if (approve) {
        if (jdwIndex != -1) {
          MockDatabase.jadwalFinal[jdwIndex] = JadwalModel(
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
        }
      }
      return updated;
    }
    throw const ApiException('NOT_FOUND', 'Ajuan tidak ditemukan');
  }
}
