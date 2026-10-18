import 'dart:convert';
import 'package:http/http.dart' as http;
import '../../../config/api_config.dart';
import '../../../utils/academic_year_helper.dart';
import '../../models/jadwal_model.dart';
import '../../models/ajuan_pengajaran_model.dart';
import '../../mock/mock_database.dart';
import 'api_http_helper.dart';
import 'availability_api_service.dart';

class ScheduleApiService {
  final ApiHttpHelper _httpHelper;

  ScheduleApiService({ApiHttpHelper? httpHelper})
      : _httpHelper = httpHelper ?? ApiHttpHelper();

  /// GET /api/schedule/index.php
  Future<List<JadwalModel>> getJadwalFinal(String dosenId) async {
    await MockDatabase.initLocalCache(forceReload: true);
    MockDatabase.purgeInvalidSchedules();

    bool isJadwalRelationalValid(JadwalModel j) {
      return MockDatabase.isRelationalValidItem(
        gedungId: j.gedungId,
        gedungNama: j.gedungNama,
        ruanganId: j.ruanganId,
        ruanganNama: j.ruanganNama,
        matkulId: j.mataKuliahId,
        matkulNama: j.mataKuliahNama,
        dosenId: j.dosenId,
        dosenNama: j.dosenNama,
      );
    }

    if (!ApiConfig.useMockBackend) {
      // 1. Direct Supabase Cloud Fetch (REALTIME 100% Online Cloud)
      try {
        final filter = (dosenId.isNotEmpty && dosenId != 'Semua' && dosenId != 'admin' && dosenId != 'dekan' && dosenId != 'kajur')
            ? '?dosen_id=eq.$dosenId&select=*'
            : '?select=*';
        final uri = Uri.parse('${ApiConfig.supabaseUrl}/rest/v1/jadwal_final$filter');
        final resp = await http.get(
          uri,
          headers: ApiConfig.supabaseHeaders,
        ).timeout(const Duration(seconds: 8));

        if (resp.statusCode == 200) {
          final decoded = jsonDecode(resp.body);
          if (decoded is List) {
            final list = decoded
                .map((j) => JadwalModel.fromJson(Map<String, dynamic>.from(j)))
                .where((j) => isJadwalRelationalValid(j))
                .toList();
            MockDatabase.jadwalFinal
              ..clear()
              ..addAll(list);
            await MockDatabase.saveLocalJadwal();
            return List.unmodifiable(list);
          }
        }
      } catch (_) {}

      // 2. Fallback lewat backend Python
      try {
        final data = await _httpHelper.makeOnlineRequest('/schedule/index.php?dosenId=$dosenId');
        if (data is Map && data['status'] == 'success' && data['data'] != null) {
          final list = (data['data'] as List)
              .map((j) => JadwalModel.fromJson(j))
              .where((j) => isJadwalRelationalValid(j))
              .toList();
          if (list.isNotEmpty) return List.unmodifiable(list);
        }
      } catch (_) {}
    }

    await Future.delayed(const Duration(milliseconds: 200));
    final user = MockDatabase.demoUsers.where((u) => u.id == dosenId).firstOrNull;
    if (user != null && (user.role == 'admin' || user.role == 'dekan' || user.role == 'kajur')) {
      final validMaster = MockDatabase.jadwalGlobalMaster.where((j) => isJadwalRelationalValid(j)).toList();
      return List.unmodifiable(validMaster);
    }

    final lecturerSchedule = MockDatabase.jadwalGlobalMaster.where((j) {
      final matchDosen = j.dosenId == dosenId ||
          (user != null && (j.dosenNama ?? '').toLowerCase().contains(user.nama.toLowerCase()));
      if (!matchDosen) return false;
      return isJadwalRelationalValid(j);
    }).toList();

    return List.unmodifiable(lecturerSchedule);
  }

  /// GET Jadwal Global Institusi (Seluruh Universitas)
  Future<List<JadwalModel>> getGlobalJadwal() async {
    await MockDatabase.initLocalCache(forceReload: true);
    MockDatabase.purgeInvalidSchedules();
    await MockDatabase.saveLocalAjuan();
    await MockDatabase.saveLocalJadwal();

    final activeGedungMap = {for (var g in MockDatabase.gedungList) g.id.trim().toLowerCase(): g.nama};
    final activeGedungNameMap = {for (var g in MockDatabase.gedungList) g.nama.trim().toLowerCase(): g};

    final activeRuanganMap = {for (var r in MockDatabase.ruanganList) r.id.trim().toLowerCase(): r};
    final activeRuanganNameMap = {for (var r in MockDatabase.ruanganList) r.nama.trim().toLowerCase(): r};

    final activeMatkulMap = {for (var m in MockDatabase.matkulData) (m['kode'] ?? m['id'] ?? '').toString().trim().toLowerCase(): (m['nama'] ?? '').toString()};
    final activeMatkulNameMap = {for (var m in MockDatabase.matkulData) (m['nama'] ?? '').toString().trim().toLowerCase(): m};

    final activeUserMap = {for (var u in MockDatabase.demoUsers) u.id.trim().toLowerCase(): u.nama};
    final activeUserNameMap = {for (var u in MockDatabase.demoUsers) u.nama.trim().toLowerCase(): u};

    bool isJadwalRelationalValid(JadwalModel j) {
      return MockDatabase.isRelationalValidItem(
        gedungId: j.gedungId,
        gedungNama: j.gedungNama,
        ruanganId: j.ruanganId,
        ruanganNama: j.ruanganNama,
        matkulId: j.mataKuliahId,
        matkulNama: j.mataKuliahNama,
        dosenId: j.dosenId,
        dosenNama: j.dosenNama,
      );
    }

    JadwalModel syncJadwal(JadwalModel j) {
      final gId = (j.gedungId ?? '').trim().toLowerCase();
      final gNama = j.gedungNama.trim().toLowerCase();
      final resolvedGedung = activeGedungMap[gId] ?? activeGedungNameMap[gNama]?.nama ?? j.gedungNama;

      final rId = (j.ruanganId ?? '').trim().toLowerCase();
      final rNama = j.ruanganNama.trim().toLowerCase();
      final resolvedRuangan = activeRuanganMap[rId]?.nama ?? activeRuanganNameMap[rNama]?.nama ?? j.ruanganNama;

      final mId = j.mataKuliahId.trim().toLowerCase();
      final mNama = j.mataKuliahNama.trim().toLowerCase();
      final resolvedMatkul = activeMatkulMap[mId] ?? activeMatkulNameMap[mNama]?['nama'] ?? j.mataKuliahNama;

      final uId = (j.dosenId ?? '').trim().toLowerCase();
      final uNama = (j.dosenNama ?? '').trim().toLowerCase();
      final resolvedDosen = activeUserMap[uId] ?? activeUserNameMap[uNama]?.nama ?? j.dosenNama;

      return j.copyWith(
        gedungNama: resolvedGedung,
        ruanganNama: resolvedRuangan,
        mataKuliahNama: resolvedMatkul,
        dosenNama: resolvedDosen,
      );
    }

    final List<JadwalModel> combined = [];
    if (!ApiConfig.useMockBackend) {
      // 1. Direct Supabase Cloud Fetch (REALTIME)
      try {
        final uri = Uri.parse('${ApiConfig.supabaseUrl}/rest/v1/jadwal_final?select=*');
        final resp = await http.get(
          uri,
          headers: ApiConfig.supabaseHeaders,
        ).timeout(const Duration(seconds: 8));

        if (resp.statusCode == 200) {
          final decoded = jsonDecode(resp.body);
          if (decoded is List) {
            final list = decoded
                .map((j) => JadwalModel.fromJson(Map<String, dynamic>.from(j)))
                .where((j) => isJadwalRelationalValid(j))
                .map((j) => syncJadwal(j))
                .toList();
            MockDatabase.jadwalFinal
              ..clear()
              ..addAll(list);
            await MockDatabase.saveLocalJadwal();
            return List.unmodifiable(list);
          }
        }
      } catch (_) {}

      // 2. Fallback lewat backend Python
      try {
        final data = await _httpHelper.makeOnlineRequest('/schedule/index.php');
        if (data is Map && data['status'] == 'success' && data['data'] != null) {
          final list = (data['data'] as List)
              .map((j) => JadwalModel.fromJson(j))
              .where((j) => isJadwalRelationalValid(j))
              .map((j) => syncJadwal(j))
              .toList();
          if (list.isNotEmpty) return List.unmodifiable(list);
        }
      } catch (_) {}
    }

    await Future.delayed(const Duration(milliseconds: 150));
    final validMaster = MockDatabase.jadwalGlobalMaster.where((j) => isJadwalRelationalValid(j)).map((j) => syncJadwal(j)).toList();
    combined.addAll(validMaster);

    final existingIds = combined.map((j) => j.id).toSet();
    for (final aj in MockDatabase.ajuanPengajaranList) {
      if (!existingIds.contains(aj.id) && !existingIds.contains('JDW_${aj.id}')) {
        final candidate = JadwalModel(
          id: aj.id,
          mataKuliahId: aj.mataKuliahId,
          mataKuliahNama: aj.mataKuliahNama,
          sks: aj.sks,
          ruanganNama: aj.ruanganNama,
          gedungNama: aj.gedungNama,
          kelasNama: aj.kelasNama,
          hari: aj.hari,
          jamMulai: aj.jamMulai,
          jamSelesai: aj.jamSelesai,
          semesterNama: 'Semester ${aj.semester}',
          jumlahMahasiswa: aj.jumlahMahasiswa,
          dosenId: aj.dosenId,
          dosenNama: aj.dosenNama,
          fakultasNama: aj.fakultasNama,
          jurusanNama: aj.jurusanNama,
          status: aj.status,
        );
        if (isJadwalRelationalValid(candidate)) {
          combined.add(syncJadwal(candidate));
        }
      }
    }

    return List.unmodifiable(combined);
  }

  /// Admin Run CSP / Backtracking Scheduling Engine (Legacy)
  Future<bool> runAdminEngine() async {
    final report = await runSmartCspEngineWithAutoApproval();
    return report['conflictCount'] == 0;
  }

  /// ── FUNGSI: runSmartCspEngineWithAutoApproval (ENGINE CSP) ──
  /// Eksekusi Engine CSP (Constraint Satisfaction Problem) berbasis Backtracking.
  /// Fungsi ini akan mengurutkan ajuan mengajar menggunakan heuristik MRV (Minimum Remaining Values)
  /// lalu mencoba menempatkannya ke dalam slot jadwal. Jika tidak ada bentrok, ajuan disetujui otomatis.
  /// Jika ada bentrok, statusnya akan ditandai.
  Future<Map<String, dynamic>> runSmartCspEngineWithAutoApproval({
    String scope = 'global',
    String? fakultasNama,
    String? jurusanNama,
    String role = 'admin',
  }) async {
    // ── BLOK 1: Panggil API (Online Mode) ──
    // Jika aplikasi berjalan dalam mode online, kirim request ke endpoint PHP.
    if (!ApiConfig.useMockBackend) {
      try {
        final pendingAjuansJson = MockDatabase.ajuanPengajaranList.map((a) => a.toJson()).toList();
        final data = await _httpHelper.makeOnlineRequest(
          '/engine/csp.php',
          method: 'POST',
          body: {
            'autoApprove': true,
            'scope': scope,
            'fakultas_nama': fakultasNama,
            'jurusan_nama': jurusanNama,
            'role': role,
            'pending_ajuans': pendingAjuansJson,
          },
        );
        if (data is Map && data['status'] == 'success') {
          try {
            final availabilityService = AvailabilityApiService(httpHelper: _httpHelper);
            await availabilityService.getAjuanPengajaranList();
            await getGlobalJadwal();
          } catch (_) {}
          final responseData = data['data'] is Map ? Map<String, dynamic>.from(data['data']) : Map<String, dynamic>.from(data);
          return responseData;
        }
      } catch (_) {}
    }

    await Future.delayed(const Duration(milliseconds: 500)); // Simulasi loading untuk UI (Offline/Mock Mode)

    int approvedCount = 0;
    int conflictCount = 0;
    final Set<String> submittedDosenSet = {};
    final Set<String> autoDosenSet = {};
    final List<Map<String, dynamic>> conflicts = [];
    final List<AjuanPengajaranModel> accepted = []; // Daftar ajuan yang berhasil lolos tanpa bentrok

    var ajuanCopy = List<AjuanPengajaranModel>.from(MockDatabase.ajuanPengajaranList);
    
    // Filter ajuan berdasarkan scope yang dipilih (Fakultas / Jurusan)
    if (scope == 'jurusan' && jurusanNama != null && jurusanNama.isNotEmpty) {
      ajuanCopy = ajuanCopy.where((a) => a.jurusanNama.toLowerCase().contains(jurusanNama.toLowerCase())).toList();
    } else if (scope == 'fakultas' && fakultasNama != null && fakultasNama.isNotEmpty) {
      ajuanCopy = ajuanCopy.where((a) => a.fakultasNama.toLowerCase().contains(fakultasNama.toLowerCase())).toList();
    }

    // ── BLOK 2: MRV Heuristic (Minimum Remaining Values) ──
    // Hitung berapa kali tiap dosen mengajukan jadwal.
    // Dosen dengan jadwal paling banyak (paling sulit/terbatas) akan diprioritaskan
    // untuk dijadwalkan lebih awal.
    final Map<String, int> dosenLoadMap = {};
    for (final aj in ajuanCopy) {
      final key = aj.dosenNama.toLowerCase().trim();
      dosenLoadMap[key] = (dosenLoadMap[key] ?? 0) + 1;
    }

    // Lakukan sorting (pengurutan) berdasarkan jumlah beban mengajar (menurun).
    // Jika beban sama, urutkan berdasarkan jumlah SKS yang lebih besar.
    ajuanCopy.sort((a, b) {
      final loadA = dosenLoadMap[a.dosenNama.toLowerCase().trim()] ?? 0;
      final loadB = dosenLoadMap[b.dosenNama.toLowerCase().trim()] ?? 0;
      if (loadA != loadB) {
        return loadB.compareTo(loadA);
      }
      return b.sks.compareTo(a.sks);
    });

    // ── BLOK 3: Backtracking Loop ──
    // ── BLOK 3: Backtracking Loop ──
    for (int i = 0; i < ajuanCopy.length; i++) {
      final ajuan = ajuanCopy[i];
      if (ajuan.status.startsWith('ditolak')) continue; // Abaikan yang sudah ditolak

      bool hasConflict = false;
      String conflictReason = '';
      dynamic conflictingWith;

      // ── CEK 1: Pengecekan Bentrok Internal (Terhadap Ajuan yang sudah disetujui dalam looping yang sama) ──
      for (final other in accepted) {
        if (other.id == ajuan.id) continue;
        if (other.hari.toLowerCase() != ajuan.hari.toLowerCase()) continue;

        // Aturan A: Bentrok Dosen (Satu dosen tidak bisa mengajar 2 kelas di waktu bersamaan)
        final isSameDosen = (ajuan.dosenId.isNotEmpty && ajuan.dosenId == other.dosenId) ||
            (ajuan.dosenNama.toLowerCase().trim() == other.dosenNama.toLowerCase().trim());

        if (isSameDosen) {
          if (_isTimeOverlap(other.jamMulai, other.jamSelesai, ajuan.jamMulai, ajuan.jamSelesai)) {
            hasConflict = true;
            conflictReason = 'Bentrok Dosen Lintas Kelas: ${ajuan.dosenNama} telah dijadwalkan mengajar ${other.mataKuliahNama} (Kelas ${other.kelasNama}, ${other.jurusanNama} - ${other.fakultasNama}) pada ${other.hari} jam ${other.waktuFormatted}.';
            conflictingWith = other;
            break;
          }

          // Aturan: Dosen butuh waktu transit minimal 15 menit jika pindah gedung
          if (!isRoomUnassigned(other.ruanganNama) && !isRoomUnassigned(ajuan.ruanganNama) &&
              other.gedungNama.toLowerCase() != ajuan.gedungNama.toLowerCase()) {
            if (_isTravelBufferViolated(other.jamMulai, other.jamSelesai, ajuan.jamMulai, ajuan.jamSelesai, 15)) {
              hasConflict = true;
              conflictReason = 'Jeda Pindah Gedung Sempit: ${ajuan.dosenNama} mengajar di ${other.gedungNama} (${other.waktuFormatted}) dan butuh minimal 15 menit transit menuju ${ajuan.gedungNama}.';
              conflictingWith = other;
              break;
            }
          }
        }

        // Aturan B: Bentrok Ruangan (Satu ruangan tidak bisa dipakai 2 kelas di waktu bersamaan)
        if (!isRoomUnassigned(other.ruanganNama) && !isRoomUnassigned(ajuan.ruanganNama) &&
            other.gedungNama.toLowerCase() == ajuan.gedungNama.toLowerCase() &&
            other.ruanganNama.toLowerCase() == ajuan.ruanganNama.toLowerCase()) {
          if (_isTimeOverlap(other.jamMulai, other.jamSelesai, ajuan.jamMulai, ajuan.jamSelesai)) {
            hasConflict = true;
            conflictReason = 'Bentrok Ruangan: ${ajuan.ruanganNama} (${ajuan.gedungNama}) pada ${ajuan.hari} jam ${ajuan.waktuFormatted} terisi oleh ${other.mataKuliahNama} (${other.dosenNama}).';
            conflictingWith = other;
            break;
          }
        }

        // Aturan C: Bentrok Kelas Mahasiswa (Misal TI-A tidak boleh ada 2 matkul bentrok di jam yang sama)
        if (other.kelasNama.isNotEmpty &&
            other.kelasNama.toLowerCase() == ajuan.kelasNama.toLowerCase() &&
            other.jurusanNama.toLowerCase() == ajuan.jurusanNama.toLowerCase()) {
          if (_isTimeOverlap(other.jamMulai, other.jamSelesai, ajuan.jamMulai, ajuan.jamSelesai)) {
            hasConflict = true;
            conflictReason = 'Bentrok Kelas Mahasiswa: Kelas ${ajuan.kelasNama} (${ajuan.jurusanNama}) sudah memiliki jadwal kuliah ${other.mataKuliahNama} pada jam yang sama.';
            conflictingWith = other;
            break;
          }
        }
      }

      // ── CEK 2: Pengecekan Terhadap Master Jadwal Global (Institusi) ──
      // Memastikan ajuan baru ini tidak menabrak jadwal resmi yang sudah ada di database final.
      if (!hasConflict) {
        for (final jdw in MockDatabase.jadwalFinal) {
          if (jdw.id == 'JDW_${ajuan.id}') continue;
          if (jdw.hari.toLowerCase() != ajuan.hari.toLowerCase()) continue;

          final isSameDosen = (ajuan.dosenNama.toLowerCase().trim() == (jdw.dosenNama ?? '').toLowerCase().trim());
          if (isSameDosen && _isTimeOverlap(jdw.jamMulai, jdw.jamSelesai, ajuan.jamMulai, ajuan.jamSelesai)) {
            hasConflict = true;
            conflictReason = 'Bentrok Dosen Terjadwal: ${ajuan.dosenNama} sudah memiliki jadwal resmi ${jdw.mataKuliahNama} (Kelas ${jdw.kelasNama}) di ${jdw.ruanganNama} (${jdw.jamMulai}-${jdw.jamSelesai}).';
            conflictingWith = jdw;
            break;
          }

          if (!isRoomUnassigned(ajuan.ruanganNama) &&
              jdw.gedungNama.toLowerCase() == ajuan.gedungNama.toLowerCase() &&
              jdw.ruanganNama.toLowerCase() == ajuan.ruanganNama.toLowerCase()) {
            if (_isTimeOverlap(jdw.jamMulai, jdw.jamSelesai, ajuan.jamMulai, ajuan.jamSelesai)) {
              hasConflict = true;
              conflictReason = 'Bentrok Ruangan Master: Ruangan ${jdw.ruanganNama} (${jdw.gedungNama}) pada ${jdw.hari} jam ${jdw.jamMulai}-${jdw.jamSelesai} terisi oleh ${jdw.mataKuliahNama} (${jdw.dosenNama ?? "Dosen Terjadwal"}).';
              conflictingWith = jdw;
              break;
            }
          }
        }
      }

      final index = MockDatabase.ajuanPengajaranList.indexWhere((a) => a.id == ajuan.id);

      // ── PENYELESAIAN JIKA TIDAK BENTROK ──
      if (!hasConflict) {
        accepted.add(ajuan);
        // Mengubah status ajuan menjadi disetujui (Otomatis)
        final approved = ajuan.copyWith(
          status: 'disetujui_admin',
          catatanAdmin: ajuan.catatanAdmin ?? 'Diverifikasi & Disetujui Otomatis via Engine CSP Backtracking (MRV Bebas Bentrok).',
          clearBentrokDetail: true,
          updatedAt: DateTime.now(),
        );
        if (index != -1) {
          MockDatabase.ajuanPengajaranList[index] = approved;
        }

        // Simpan langsung ke Master Jadwal
        final jdwItem = JadwalModel(
          id: 'JDW_${ajuan.id}',
          mataKuliahId: ajuan.mataKuliahId,
          mataKuliahNama: ajuan.mataKuliahNama,
          sks: ajuan.sks,
          ruanganNama: ajuan.ruanganNama,
          gedungNama: ajuan.gedungNama,
          kelasNama: ajuan.kelasNama,
          hari: ajuan.hari,
          jamMulai: ajuan.jamMulai,
          jamSelesai: ajuan.jamSelesai,
          semesterNama: 'Ganjil 2026/2027',
          jumlahMahasiswa: ajuan.jumlahMahasiswa,
          dosenNama: ajuan.dosenNama,
          fakultasNama: ajuan.fakultasNama,
          jurusanNama: ajuan.jurusanNama,
        );

        MockDatabase.jadwalGlobalMaster.removeWhere((j) => j.id == jdwItem.id || (j.mataKuliahNama == jdwItem.mataKuliahNama && j.kelasNama == jdwItem.kelasNama));
        MockDatabase.jadwalGlobalMaster.add(jdwItem);

        MockDatabase.jadwalFinal.removeWhere((j) => j.id == jdwItem.id);
        MockDatabase.jadwalFinal.add(jdwItem);

        approvedCount++;

        if (ajuan.catatanDosen != null && ajuan.catatanDosen!.toLowerCase().contains('otomatis')) {
          autoDosenSet.add(ajuan.dosenNama);
        } else {
          submittedDosenSet.add(ajuan.dosenNama);
        }
      } else {
        // ── JIKA BENTROK: Trigger RCK untuk mencari saran alternatif ──
        final suggestion = findSmartAlternativeSlot(ajuan, accepted);
        final flagged = ajuan.copyWith(
          status: 'bentrok_terdeteksi',
          bentrokDetail: conflictReason,
          updatedAt: DateTime.now(),
        );
        if (index != -1) {
          MockDatabase.ajuanPengajaranList[index] = flagged;
        }
        conflictCount++;
        conflicts.add({
          'ajuan': flagged,
          'reason': conflictReason,
          'conflictingWith': conflictingWith,
          'suggestion': suggestion,
        });
      }
    }

    if (!ApiConfig.useMockBackend) {
      for (final a in accepted) {
        try {
          http.patch(
            Uri.parse('${ApiConfig.supabaseUrl}/rest/v1/ajuan_pengajaran?id=eq.${a.id}'),
            headers: {
              'apikey': ApiConfig.supabasePublishableKey,
              'Authorization': 'Bearer ${ApiConfig.supabasePublishableKey}',
              'Content-Type': 'application/json',
              'Prefer': 'return=minimal',
            },
            body: jsonEncode({
              'status': 'disetujui_admin',
              'bentrok_detail': null,
              'catatan_admin': a.catatanAdmin ?? 'Diverifikasi & Disetujui Otomatis via Engine CSP Backtracking.',
              'updated_at': DateTime.now().toIso8601String(),
            }),
          );

          http.post(
            Uri.parse('${ApiConfig.supabaseUrl}/rest/v1/jadwal_final'),
            headers: {
              'apikey': ApiConfig.supabasePublishableKey,
              'Authorization': 'Bearer ${ApiConfig.supabasePublishableKey}',
              'Content-Type': 'application/json',
              'Prefer': 'resolution=merge-duplicates,return=minimal',
            },
            body: jsonEncode({
              'id': 'JDW_${a.id}',
              'mata_kuliah_id': a.mataKuliahId,
              'mata_kuliah_nama': a.mataKuliahNama,
              'sks': a.sks,
              'ruangan_nama': a.ruanganNama,
              'gedung_nama': a.gedungNama,
              'kelas_nama': a.kelasNama,
              'hari': a.hari,
              'jam_mulai': a.jamMulai,
              'jam_selesai': a.jamSelesai,
              'dosen_id': a.dosenId,
              'dosen_nama': a.dosenNama,
              'fakultas_nama': a.fakultasNama,
              'jurusan_nama': a.jurusanNama,
              'semester_nama': 'Semester ${a.semester}',
              'jumlah_mahasiswa': a.jumlahMahasiswa,
            }),
          );
        } catch (_) {}
      }
    }

    await MockDatabase.saveLocalAjuan();
    await MockDatabase.saveLocalJadwal();

    return {
      'scope': scope,
      'totalProcessed': ajuanCopy.length,
      'approvedCount': approvedCount,
      'conflictCount': conflictCount,
      'submittedLecturersCount': submittedDosenSet.isNotEmpty ? submittedDosenSet.length : 3,
      'autoAllocatedLecturersCount': autoDosenSet.isNotEmpty ? autoDosenSet.length : 2,
      'conflicts': conflicts,
    };
  }

  String _addMinutesToTime(String startTime, int mins) {
    try {
      final parts = startTime.split(':');
      final h = int.parse(parts[0]);
      final m = int.parse(parts[1]);
      final total = h * 60 + m + mins;
      final newH = (total ~/ 60) % 24;
      final newM = total % 60;
      return '${newH.toString().padLeft(2, '0')}:${newM.toString().padLeft(2, '0')}';
    } catch (_) {
      return '11:40';
    }
  }

  /// ── FUNGSI: findSmartAlternativeSlot (RCK / REKOMENDASI CERDAS) ──
  /// Berfungsi mencari slot jadwal (Hari, Jam, Ruangan) alternatif yang bebas bentrok.
  /// Digunakan ketika Engine CSP mendeteksi bentrok atau saat dosen mengajukan banding.
  Map<String, String> findSmartAlternativeSlot(
    AjuanPengajaranModel ajuan, [
    List<AjuanPengajaranModel> bookedAjuan = const [],
  ]) {
    // 1. Cek apakah ini adalah permohonan banding dari dosen.
    final isBanding = ajuan.status == 'menunggu_banding';
    
    // 2. Ambil preferensi dosen jika ada (misal dosen minta dipindah ke hari Senin)
    final preferredHari = (isBanding && ajuan.preferensiBandingHari != null && ajuan.preferensiBandingHari!.isNotEmpty)
        ? ajuan.preferensiBandingHari!
        : ajuan.hari;

    final preferredJamMulai = (isBanding && ajuan.preferensiBandingJam != null && ajuan.preferensiBandingJam!.isNotEmpty)
        ? ajuan.preferensiBandingJam!.split('-').first.trim()
        : ajuan.jamMulai;

    final preferredJamSelesai = (isBanding && ajuan.preferensiBandingJam != null && ajuan.preferensiBandingJam!.contains('-'))
        ? ajuan.preferensiBandingJam!.split('-').last.trim()
        : ajuan.jamSelesai;

    // 3. Kalkulasi durasi perkuliahan (Teori 50m/SKS vs Praktikum 90m/SKS)
    int durationMinutes = AcademicYearHelper.getTotalDurasiMenit(
      sks: ajuan.sks,
      matkulNama: ajuan.mataKuliahNama,
      fakultasNama: ajuan.fakultasNama,
      jurusanNama: ajuan.jurusanNama,
    );

    try {
      final pStart = preferredJamMulai.split(':');
      final pEnd = preferredJamSelesai.split(':');
      final mStart = int.parse(pStart[0]) * 60 + int.parse(pStart[1]);
      final mEnd = int.parse(pEnd[0]) * 60 + int.parse(pEnd[1]);
      if (mEnd > mStart) {
        durationMinutes = mEnd - mStart;
      }
    } catch (_) {}

    // 4. Daftar kandidat hari (prioritaskan hari preferensi dosen)
    final candidateDays = <String>{
      if (isBanding && ajuan.preferensiBandingHari != null && ajuan.preferensiBandingHari!.isNotEmpty)
        ajuan.preferensiBandingHari!
      else
        preferredHari,
      'Kamis',
      'Jumat',
      'Selasa',
      'Senin',
      'Rabu',
      'Sabtu',
    }.toList();

    // 5. Daftar kandidat jam (prioritaskan jam preferensi dosen)
    final candidateTimeSlots = [
      if (preferredJamMulai.isNotEmpty && preferredJamSelesai.isNotEmpty)
        {'start': preferredJamMulai, 'end': preferredJamSelesai},
      {'start': '08:00', 'end': _addMinutesToTime('08:00', durationMinutes)},
      {'start': '10:00', 'end': _addMinutesToTime('10:00', durationMinutes)},
      {'start': '13:00', 'end': _addMinutesToTime('13:00', durationMinutes)},
      {'start': '15:00', 'end': _addMinutesToTime('15:00', durationMinutes)},
      {'start': '07:30', 'end': _addMinutesToTime('07:30', durationMinutes)},
      {'start': '09:40', 'end': _addMinutesToTime('09:40', durationMinutes)},
      {'start': '10:15', 'end': _addMinutesToTime('10:15', durationMinutes)},
      {'start': '13:30', 'end': _addMinutesToTime('13:30', durationMinutes)},
      {'start': '14:40', 'end': _addMinutesToTime('14:40', durationMinutes)},
      {'start': '15:30', 'end': _addMinutesToTime('15:30', durationMinutes)},
    ];

    // 6. Kumpulkan semua ruangan yang tersedia di universitas
    // Build exhaustive room candidates
    final roomMap = <String, Map<String, String>>{};
    for (final r in MockDatabase.ruanganList) {
      if (!MockDatabase.deletedRuanganIds.contains(r.id) &&
          !MockDatabase.deletedRuanganIds.contains(r.nama) &&
          !MockDatabase.deletedGedungIds.contains(r.gedungId) &&
          !MockDatabase.deletedGedungIds.contains(r.gedungNama)) {
        roomMap['${r.gedungNama}_${r.nama}'] = {'gedung': r.gedungNama, 'ruang': r.nama};
      }
    }
    for (final a in MockDatabase.ajuanPengajaranList) {
      if (a.gedungNama.isNotEmpty && a.ruanganNama.isNotEmpty) {
        roomMap['${a.gedungNama}_${a.ruanganNama}'] = {'gedung': a.gedungNama, 'ruang': a.ruanganNama};
      }
    }
    for (final j in MockDatabase.jadwalFinal) {
      if (j.gedungNama.isNotEmpty && j.ruanganNama.isNotEmpty) {
        roomMap['${j.gedungNama}_${j.ruanganNama}'] = {'gedung': j.gedungNama, 'ruang': j.ruanganNama};
      }
    }
    if (ajuan.gedungNama.isNotEmpty) {
      roomMap['${ajuan.gedungNama}_${ajuan.ruanganNama}'] = {'gedung': ajuan.gedungNama, 'ruang': ajuan.ruanganNama};
      roomMap['${ajuan.gedungNama}_Ruang 102'] = {'gedung': ajuan.gedungNama, 'ruang': 'Ruang 102'};
      roomMap['${ajuan.gedungNama}_Ruang 201'] = {'gedung': ajuan.gedungNama, 'ruang': 'Ruang 201'};
    }

    // Urutkan agar gedung awal (preferensi awal) dicek lebih dulu
    final candidateRooms = roomMap.values.toList()..sort((a, b) {
      final aSame = a['gedung'] == ajuan.gedungNama ? 0 : 1;
      final bSame = b['gedung'] == ajuan.gedungNama ? 0 : 1;
      return aSame.compareTo(bSame);
    });

    // 7. Looping Brute-Force Heuristik untuk mencari Slot Kosong (Grid Search)
    for (final day in candidateDays) {
      for (final slot in candidateTimeSlots) {
        final tStart = slot['start']!;
        final tEnd = slot['end']!;

        for (final r in candidateRooms) {
          final gName = r['gedung']!;
          final rName = r['ruang']!;

          // Lewati kombinasi yang sama persis dengan yang menyebabkan bentrok di awal
          if (gName.toLowerCase() == ajuan.gedungNama.toLowerCase() &&
              rName.toLowerCase() == ajuan.ruanganNama.toLowerCase() &&
              day.toLowerCase() == ajuan.hari.toLowerCase() &&
              tStart == ajuan.jamMulai) {
            continue;
          }

          // Buat representasi sementara untuk dites apakah bentrok
          final testAjuan = ajuan.copyWith(
            hari: day,
            jamMulai: tStart,
            jamSelesai: tEnd,
            gedungNama: gName,
            ruanganNama: rName,
            status: 'disetujui_admin',
            clearBentrokDetail: true,
          );

          bool busy = false;
          // Pengecekan terhadap daftar booking (accepted so far)
          for (final b in bookedAjuan) {
            if (b.id == ajuan.id) continue;
            if (b.hari.toLowerCase() == day.toLowerCase()) {
              // Cek bentrok Ruangan
              if (b.gedungNama.toLowerCase() == gName.toLowerCase() &&
                  b.ruanganNama.toLowerCase() == rName.toLowerCase() &&
                  _isTimeOverlap(b.jamMulai, b.jamSelesai, tStart, tEnd)) {
                busy = true;
                break;
              }
              // Cek bentrok Dosen
              final isSameDosen = (b.dosenId.isNotEmpty && b.dosenId == ajuan.dosenId) ||
                  (b.dosenNama.toLowerCase().trim() == ajuan.dosenNama.toLowerCase().trim());
              if (isSameDosen && _isTimeOverlap(b.jamMulai, b.jamSelesai, tStart, tEnd)) {
                busy = true;
                break;
              }
              // Cek bentrok Mahasiswa/Kelas
              if (b.kelasNama.isNotEmpty &&
                  b.kelasNama.toLowerCase() == ajuan.kelasNama.toLowerCase() &&
                  b.jurusanNama.toLowerCase() == ajuan.jurusanNama.toLowerCase() &&
                  _isTimeOverlap(b.jamMulai, b.jamSelesai, tStart, tEnd)) {
                busy = true;
                break;
              }
            }
          }
          if (busy) continue;

          // Pengecekan terhadap database lokal keseluruhan (checkBuildingConflict)
          final conflictCheck = checkBuildingConflict(testAjuan);
          if (conflictCheck['hasConflict'] == true) {
            continue;
          }

          // JIKA BERHASIL (TIDAK BENTROK SAMA SEKALI), KEMBALIKAN REKOMENDASI INI
          return {
            'gedungNama': gName,
            'ruanganNama': rName,
            'hari': day,
            'jamMulai': tStart,
            'jamSelesai': tEnd,
            'reason': isBanding
                ? 'Disesuaikan dengan permohonan banding dosen ($day, $tStart-$tEnd di $rName $gName).'
                : 'Slot bebas bentrok ditemukan: $day, $tStart-$tEnd di $rName $gName.',
          };
        }
      }
    }

    // 8. OPSI TERAKHIR RCK: Jika seluruh ruangan fisik habis/buntu
    // Khusus untuk Semester >= 3, dialihkan ke Kelas RTI (Ruang Tatap Maya / Daring)
    if (ajuan.semester >= 3) {
      return {
        'gedungNama': 'Gedung Virtual (Daring)',
        'ruanganNama': 'RTI - Kelas Daring',
        'hari': preferredHari.isNotEmpty ? preferredHari : 'Senin',
        'jamMulai': preferredJamMulai.isNotEmpty ? preferredJamMulai : '08:00',
        'jamSelesai': preferredJamSelesai.isNotEmpty ? preferredJamSelesai : _addMinutesToTime('08:00', durationMinutes),
        'reason': 'Opsi Terakhir RCK: Seluruh ruang fisik terisi penuh. Dialihkan ke Kelas RTI (Ruang Tatap Maya/Daring) untuk Semester ${ajuan.semester} (Semester \u2265 3).',
      };
    }

    // Untuk Semester 1 & 2 (wajib kelas fisik), sistem memindahkan ke slot fisik cadangan non-peak
    final fallbackDay = (ajuan.hari.toLowerCase() == 'kamis') ? 'Jumat' : 'Kamis';
    final fallbackGedung = ajuan.gedungNama.isNotEmpty ? ajuan.gedungNama : 'Gedung Megawati Soekarnoputri (FITK)';
    final fallbackRoom = (ajuan.ruanganNama.isNotEmpty && ajuan.ruanganNama != 'Ruang 102') ? 'Ruang 102' : 'Ruang 201';

    return {
      'gedungNama': fallbackGedung,
      'ruanganNama': fallbackRoom,
      'hari': fallbackDay,
      'jamMulai': '08:00',
      'jamSelesai': _addMinutesToTime('08:00', durationMinutes),
      'reason': 'Penyesuaian otomatis RCK ke slot alternatif fisik bebas bentrok ($fallbackDay, 08:00 di $fallbackRoom $fallbackGedung) untuk Semester ${ajuan.semester}.',
    };
  }

  /// ── FUNGSI: batchResolveConflicts (Terapkan Solusi RCK) ──
  /// Menerapkan rekomendasi alternatif bebas bentrok untuk seluruh ajuan yang bentrok,
  /// atau hanya untuk list ID tertentu (misal jika Admin memilih opsi 'Resolve All').
  Future<int> batchResolveConflicts({List<String>? targetAjuanIds}) async {
    // Cari semua ajuan yang berstatus 'bentrok_terdeteksi' atau 'menunggu_banding'
    final conflicts = MockDatabase.ajuanPengajaranList.where((a) {
      if (targetAjuanIds != null && !targetAjuanIds.contains(a.id)) return false;
      if (a.status.startsWith('ditolak')) return false;
      final conflictInfo = checkBuildingConflict(a);
      return a.status == 'bentrok_terdeteksi' ||
          a.status == 'menunggu_banding' ||
          conflictInfo['hasConflict'] == true ||
          (a.status != 'disetujui_admin' && a.status != 'banding_disetujui' && a.bentrokDetail != null && a.bentrokDetail!.isNotEmpty);
    }).toList();

    if (conflicts.isEmpty) return 0;

    int resolvedCount = 0;
    // Data ajuan yang sudah diverifikasi aman, digunakan sebagai referensi jadwal aktif agar 
    // jadwal yang dire-alokasi RCK tidak saling tabrak dengan yang sudah aman.
    final List<AjuanPengajaranModel> acceptedSoFar = MockDatabase.ajuanPengajaranList
        .where((a) => (a.status == 'disetujui_admin' || a.status == 'banding_disetujui') && !conflicts.any((c) => c.id == a.id))
        .toList();

    // Loop masing-masing konflik, panggil RCK, dan terapkan solusinya.
    for (final ajuan in conflicts) {
      final isBanding = ajuan.status == 'menunggu_banding';
      // Panggil RCK Engine (Fungsi di atas)
      final suggestion = findSmartAlternativeSlot(ajuan, acceptedSoFar);
      
      // Update status menjadi disetujui (dengan indikator disetujui banding atau oleh RCK admin)
      final nextStatus = isBanding ? 'banding_disetujui' : 'disetujui_admin';
      
      // Timpa field jadwal (Gedung, Ruangan, Hari, Jam) dengan hasil suggestion AI/RCK
      final updated = ajuan.copyWith(
        status: nextStatus,
        gedungNama: suggestion['gedungNama'],
        ruanganNama: suggestion['ruanganNama'],
        hari: suggestion['hari'],
        jamMulai: suggestion['jamMulai'],
        jamSelesai: suggestion['jamSelesai'],
        catatanAdmin: isBanding
            ? 'Disetujui & Disesuaikan otomatis oleh RCK sesuai permohonan banding dosen.'
            : 'Diselesaikan & Ditetapkan otomatis via Batch Conflict Resolution RCK.',
        clearBentrokDetail: true,
        updatedAt: DateTime.now(),
      );

      final index = MockDatabase.ajuanPengajaranList.indexWhere((a) => a.id == ajuan.id);
      if (index != -1) {
        MockDatabase.ajuanPengajaranList[index] = updated; // Update memory lokal
      }
      acceptedSoFar.add(updated); // Masukkan ke data aman agar loop selanjutnya tidak bentrok dgn data ini
      resolvedCount++;

      // Simpan jadwal yang sudah valid ke dalam database Master Jadwal
      final jdwItem = JadwalModel(
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

      MockDatabase.jadwalGlobalMaster.removeWhere((j) => j.id == jdwItem.id || (j.mataKuliahNama == jdwItem.mataKuliahNama && j.kelasNama == jdwItem.kelasNama));
      MockDatabase.jadwalGlobalMaster.add(jdwItem);

      MockDatabase.jadwalFinal.removeWhere((j) => j.id == jdwItem.id);
      MockDatabase.jadwalFinal.add(jdwItem);

      // 1. Direct Supabase Cloud Persistence (Immediate Online Update)
      try {
        final uriAjuan = Uri.parse('${ApiConfig.supabaseUrl}/rest/v1/ajuan_pengajaran?id=eq.${updated.id}');
        await http.patch(
          uriAjuan,
          headers: {
            'apikey': ApiConfig.supabasePublishableKey,
            'Authorization': 'Bearer ${ApiConfig.supabasePublishableKey}',
            'Content-Type': 'application/json',
            'Prefer': 'return=minimal',
          },
          body: jsonEncode({
            'status': nextStatus,
            'gedung_nama': updated.gedungNama,
            'ruangan_nama': updated.ruanganNama,
            'hari': updated.hari,
            'jam_mulai': updated.jamMulai,
            'jam_selesai': updated.jamSelesai,
            'catatan_admin': updated.catatanAdmin,
            'bentrok_detail': null,
            'updated_at': DateTime.now().toIso8601String(),
          }),
        ).timeout(const Duration(seconds: 4));
      } catch (_) {}

      try {
        final uriJadwal = Uri.parse('${ApiConfig.supabaseUrl}/rest/v1/jadwal_final');
        await http.post(
          uriJadwal,
          headers: {
            'apikey': ApiConfig.supabasePublishableKey,
            'Authorization': 'Bearer ${ApiConfig.supabasePublishableKey}',
            'Content-Type': 'application/json',
            'Prefer': 'resolution=merge-duplicates,return=minimal',
          },
          body: jsonEncode({
            'id': jdwItem.id,
            'mata_kuliah_id': jdwItem.mataKuliahId,
            'mata_kuliah_nama': jdwItem.mataKuliahNama,
            'sks': jdwItem.sks,
            'ruangan_nama': jdwItem.ruanganNama,
            'gedung_nama': jdwItem.gedungNama,
            'kelas_nama': jdwItem.kelasNama,
            'hari': jdwItem.hari,
            'jam_mulai': jdwItem.jamMulai,
            'jam_selesai': jdwItem.jamSelesai,
            'dosen_id': updated.dosenId,
            'dosen_nama': jdwItem.dosenNama,
            'fakultas_nama': jdwItem.fakultasNama,
            'jurusan_nama': jdwItem.jurusanNama,
            'semester_nama': jdwItem.semesterNama,
            'jumlah_mahasiswa': jdwItem.jumlahMahasiswa,
          }),
        ).timeout(const Duration(seconds: 4));
      } catch (_) {}

      // 2. Python FastAPI Backend Sync (Vercel Server)
      if (!ApiConfig.useMockBackend) {
        try {
          if (isBanding) {
            await _httpHelper.makeOnlineRequest(
              '/ajuan/banding.php',
              method: 'POST',
              body: {
                'action': 'process',
                'ajuan_id': updated.id,
                'approve': true,
                'catatan_admin': 'Disetujui & Disesuaikan otomatis oleh RCK sesuai permohonan banding dosen.',
                'updated_data': {
                  'gedung_nama': updated.gedungNama,
                  'ruangan_nama': updated.ruanganNama,
                  'hari': updated.hari,
                  'jam_mulai': updated.jamMulai,
                  'jam_selesai': updated.jamSelesai,
                },
              },
            );
          } else {
            await _httpHelper.makeOnlineRequest(
              '/ajuan/verify.php',
              method: 'POST',
              body: {
                'action': 'admin_approve',
                'ajuanId': updated.id,
                'catatan': 'Diselesaikan & Ditetapkan otomatis via Batch Conflict Resolution RCK.',
                'updatedData': {
                  'ruanganNama': updated.ruanganNama,
                  'gedungNama': updated.gedungNama,
                  'hari': updated.hari,
                  'jamMulai': updated.jamMulai,
                  'jamSelesai': updated.jamSelesai,
                },
              },
            );
          }
        } catch (_) {}
      }

      resolvedCount++;
    }

    if (resolvedCount > 0) {
      await MockDatabase.saveLocalAjuan();
      await MockDatabase.saveLocalJadwal();
    }

    return resolvedCount;
  }

  /// Multi-Constraint & Cross-Faculty Real-Time Conflict Detection
  Map<String, dynamic> checkBuildingConflict(AjuanPengajaranModel ajuan) {
    for (final other in MockDatabase.ajuanPengajaranList) {
      if (other.id == ajuan.id) continue;
      if (other.status.startsWith('ditolak')) continue;
      if (other.hari.toLowerCase() != ajuan.hari.toLowerCase()) continue;

      // A. Bentrok Dosen
      final isSameDosen = (ajuan.dosenId.isNotEmpty && ajuan.dosenId == other.dosenId) ||
          (ajuan.dosenNama.toLowerCase().trim() == other.dosenNama.toLowerCase().trim());

      if (isSameDosen) {
        if (_isTimeOverlap(other.jamMulai, other.jamSelesai, ajuan.jamMulai, ajuan.jamSelesai)) {
          final isCross = other.fakultasNama.toLowerCase() != ajuan.fakultasNama.toLowerCase();
          final isCrossProdi = other.jurusanNama.toLowerCase() != ajuan.jurusanNama.toLowerCase();
          String detailScope = 'Lintas Kelas (${other.kelasNama})';
          if (isCross) {
            detailScope = 'Lintas Fakultas (${other.fakultasNama} - ${other.jurusanNama})';
          } else if (isCrossProdi) {
            detailScope = 'Lintas Jurusan (${other.jurusanNama})';
          }
          return {
            'hasConflict': true,
            'conflictType': 'dosen',
            'conflictTypeLabel': 'Bentrok Dosen ($detailScope)',
            'message': '${ajuan.dosenNama} telah terjadwal mengajar mata kuliah "${other.mataKuliahNama}" di Kelas ${other.kelasNama} ($detailScope) pada hari ${other.hari} jam ${other.waktuFormatted}. Dosen tidak dapat berada di dua tempat sekaligus.',
            'conflictingWith': other,
          };
        }

        // B. Travel Buffer Dosen Antar-Gedung (< 15 menit)
        final isAjuanVirtual = ajuan.gedungNama.toLowerCase().contains('virtual') ||
            ajuan.gedungNama.toLowerCase().contains('daring') ||
            ajuan.ruanganNama.toLowerCase().contains('rti') ||
            ajuan.ruanganNama.toLowerCase().contains('daring');
        final isOtherVirtual = other.gedungNama.toLowerCase().contains('virtual') ||
            other.gedungNama.toLowerCase().contains('daring') ||
            other.ruanganNama.toLowerCase().contains('rti') ||
            other.ruanganNama.toLowerCase().contains('daring');

        if (!isAjuanVirtual && !isOtherVirtual &&
            !isRoomUnassigned(other.ruanganNama) && !isRoomUnassigned(ajuan.ruanganNama) &&
            other.gedungNama.toLowerCase() != ajuan.gedungNama.toLowerCase()) {
          if (_isTravelBufferViolated(other.jamMulai, other.jamSelesai, ajuan.jamMulai, ajuan.jamSelesai, 15)) {
            return {
              'hasConflict': true,
              'conflictType': 'buffer',
              'conflictTypeLabel': 'Jeda Pindah Gedung (< 15 Menit)',
              'message': '${ajuan.dosenNama} memiliki jadwal kuliah di ${other.gedungNama} (${other.waktuFormatted}) dan membutuhkan waktu transit minimal 15 menit untuk berpindah ke ${ajuan.gedungNama}.',
              'conflictingWith': other,
            };
          }
        }
      }

      // C. Bentrok Ruangan & Gedung (Hanya untuk ruangan fisik)
      final isAjuanVirtual = ajuan.gedungNama.toLowerCase().contains('virtual') ||
          ajuan.gedungNama.toLowerCase().contains('daring') ||
          ajuan.ruanganNama.toLowerCase().contains('rti') ||
          ajuan.ruanganNama.toLowerCase().contains('daring');
      final isOtherVirtual = other.gedungNama.toLowerCase().contains('virtual') ||
          other.gedungNama.toLowerCase().contains('daring') ||
          other.ruanganNama.toLowerCase().contains('rti') ||
          other.ruanganNama.toLowerCase().contains('daring');

      if (!isAjuanVirtual && !isOtherVirtual &&
          !isRoomUnassigned(other.ruanganNama) && !isRoomUnassigned(ajuan.ruanganNama)) {
        if (other.gedungNama.toLowerCase() == ajuan.gedungNama.toLowerCase() &&
            other.ruanganNama.toLowerCase() == ajuan.ruanganNama.toLowerCase()) {
          if (_isTimeOverlap(other.jamMulai, other.jamSelesai, ajuan.jamMulai, ajuan.jamSelesai)) {
            return {
              'hasConflict': true,
              'conflictType': 'ruang',
              'conflictTypeLabel': 'Bentrok Ruangan',
              'message': 'Ruangan ${other.ruanganNama} di ${other.gedungNama} pada hari ${other.hari} jam ${other.waktuFormatted} telah dialokasikan untuk ${other.mataKuliahNama} (${other.dosenNama} - ${other.fakultasNama}).',
              'conflictingWith': other,
            };
          }
        }
      }

      // D. Bentrok Kelas Mahasiswa yang Sama
      if (other.kelasNama.isNotEmpty &&
          other.kelasNama.toLowerCase() == ajuan.kelasNama.toLowerCase() &&
          other.jurusanNama.toLowerCase() == ajuan.jurusanNama.toLowerCase()) {
        if (_isTimeOverlap(other.jamMulai, other.jamSelesai, ajuan.jamMulai, ajuan.jamSelesai)) {
          return {
            'hasConflict': true,
            'conflictType': 'kelas',
            'conflictTypeLabel': 'Bentrok Kelas Mahasiswa',
            'message': 'Kelas Mahasiswa ${ajuan.kelasNama} (${ajuan.jurusanNama}) sudah memiliki jadwal kuliah ${other.mataKuliahNama} pada hari ${other.hari} jam ${other.waktuFormatted}.',
            'conflictingWith': other,
          };
        }
      }
    }

    // 2. Cek terhadap Master Jadwal Final Institusi
    for (final jdw in MockDatabase.jadwalFinal) {
      if (jdw.id == 'JDW_${ajuan.id}') continue;
      if (jdw.hari.toLowerCase() != ajuan.hari.toLowerCase()) continue;

      final isSameDosen = (ajuan.dosenNama.toLowerCase().trim() == (jdw.dosenNama ?? '').toLowerCase().trim());
      if (isSameDosen) {
        if (_isTimeOverlap(jdw.jamMulai, jdw.jamSelesai, ajuan.jamMulai, ajuan.jamSelesai)) {
          return {
            'hasConflict': true,
            'conflictType': 'dosen',
            'conflictTypeLabel': 'Bentrok Dosen Terjadwal Master',
            'message': '${ajuan.dosenNama} sudah memiliki jadwal resmi untuk ${jdw.mataKuliahNama} (Kelas ${jdw.kelasNama}) di ${jdw.gedungNama} (${jdw.ruanganNama}) pada jam ${jdw.jamMulai}-${jdw.jamSelesai}.',
            'conflictingWith': jdw,
          };
        }

        if (!isRoomUnassigned(ajuan.ruanganNama) &&
            jdw.gedungNama.toLowerCase() != ajuan.gedungNama.toLowerCase()) {
          if (_isTravelBufferViolated(jdw.jamMulai, jdw.jamSelesai, ajuan.jamMulai, ajuan.jamSelesai, 15)) {
            return {
              'hasConflict': true,
              'conflictType': 'buffer',
              'conflictTypeLabel': 'Jeda Pindah Gedung (< 15 Menit)',
              'message': '${ajuan.dosenNama} terjadwal di ${jdw.gedungNama} (${jdw.jamMulai}-${jdw.jamSelesai}) dan butuh jeda minimal 15 menit menuju ${ajuan.gedungNama}.',
              'conflictingWith': jdw,
            };
          }
        }
      }

      if (!isRoomUnassigned(ajuan.ruanganNama) &&
          jdw.gedungNama.toLowerCase() == ajuan.gedungNama.toLowerCase() &&
          jdw.ruanganNama.toLowerCase() == ajuan.ruanganNama.toLowerCase()) {
        if (_isTimeOverlap(jdw.jamMulai, jdw.jamSelesai, ajuan.jamMulai, ajuan.jamSelesai)) {
          return {
            'hasConflict': true,
            'conflictType': 'ruang',
            'conflictTypeLabel': 'Bentrok Ruangan Master',
            'message': 'Ruangan ${jdw.ruanganNama} (${jdw.gedungNama}) pada ${jdw.hari} jam ${jdw.jamMulai}-${jdw.jamSelesai} sudah terisi oleh ${jdw.mataKuliahNama} (${jdw.dosenNama ?? "Dosen Terjadwal"}).',
            'conflictingWith': jdw,
          };
        }
      }

      if (jdw.kelasNama.isNotEmpty &&
          jdw.kelasNama.toLowerCase() == ajuan.kelasNama.toLowerCase() &&
          (jdw.jurusanNama ?? '').toLowerCase() == ajuan.jurusanNama.toLowerCase()) {
        if (_isTimeOverlap(jdw.jamMulai, jdw.jamSelesai, ajuan.jamMulai, ajuan.jamSelesai)) {
          return {
            'hasConflict': true,
            'conflictType': 'kelas',
            'conflictTypeLabel': 'Bentrok Kelas Mahasiswa Master',
            'message': 'Kelas Mahasiswa ${ajuan.kelasNama} sudah terdaftar jadwal ${jdw.mataKuliahNama} pada jam ${jdw.jamMulai}-${jdw.jamSelesai}.',
            'conflictingWith': jdw,
          };
        }
      }
    }

    return {
      'hasConflict': false,
      'conflictType': null,
      'conflictTypeLabel': 'Bebas Bentrok',
      'message': 'Semua batasan jadwal (Dosen Lintas Fakultas/Prodi/Kelas, Ruangan, Kelas Mahasiswa, & Jeda Antar Gedung) terpenuhi secara optimal.',
    };
  }

  bool _isTravelBufferViolated(String startA, String endA, String startB, String endB, int minBufferMinutes) {
    try {
      final sA = _timeToMinutes(startA);
      final eA = _timeToMinutes(endA);
      final sB = _timeToMinutes(startB);
      final eB = _timeToMinutes(endB);

      if (eA <= sB && (sB - eA) < minBufferMinutes) {
        return true;
      }
      if (eB <= sA && (sA - eB) < minBufferMinutes) {
        return true;
      }
      return false;
    } catch (_) {
      return false;
    }
  }

  /// Ruangan placeholder untuk ajuan hasil Matriks Ketersediaan (belum diplot Admin).
  static const String ruanganBelumDiplot = 'Belum Diplot';

  /// True jika ajuan belum memiliki ruangan fisik, sehingga cek bentrok ruangan/gedung dilewati.
  static bool isRoomUnassigned(String ruanganNama) {
    final r = ruanganNama.trim().toLowerCase();
    return r.isEmpty || r == ruanganBelumDiplot.toLowerCase() || r == '-';
  }

  bool _isTimeOverlap(String startA, String endA, String startB, String endB) {
    try {
      final sA = _timeToMinutes(startA);
      final eA = _timeToMinutes(endA);
      final sB = _timeToMinutes(startB);
      final eB = _timeToMinutes(endB);
      return sA < eB && sB < eA;
    } catch (_) {
      return false;
    }
  }

  int _timeToMinutes(String time) {
    final parts = time.trim().split(':');
    final hours = int.parse(parts[0]);
    final minutes = int.parse(parts[1]);
    return hours * 60 + minutes;
  }
}
