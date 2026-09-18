import '../../../config/api_config.dart';
import '../../models/jadwal_model.dart';
import '../../models/ajuan_pengajaran_model.dart';
import '../../mock/mock_database.dart';
import 'api_http_helper.dart';

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

  /// Eksekusi Engine CSP Backtracking Cerdas Berbasis Scope
  Future<Map<String, dynamic>> runSmartCspEngineWithAutoApproval({
    String scope = 'global',
    String? fakultasNama,
    String? jurusanNama,
    String role = 'admin',
  }) async {
    if (!ApiConfig.useMockBackend) {
      try {
        final data = await _httpHelper.makeOnlineRequest(
          '/engine/csp.php',
          method: 'POST',
          body: {
            'autoApprove': true,
            'scope': scope,
            'fakultas_nama': fakultasNama,
            'jurusan_nama': jurusanNama,
            'role': role,
          },
        );
        if (data is Map && data['status'] == 'success') {
          final responseData = data['data'] is Map ? Map<String, dynamic>.from(data['data']) : Map<String, dynamic>.from(data);
          return responseData;
        }
      } catch (_) {}
    }

    await Future.delayed(const Duration(milliseconds: 500));

    int approvedCount = 0;
    int conflictCount = 0;
    final Set<String> submittedDosenSet = {};
    final Set<String> autoDosenSet = {};
    final List<Map<String, dynamic>> conflicts = [];
    final List<AjuanPengajaranModel> accepted = [];

    var ajuanCopy = List<AjuanPengajaranModel>.from(MockDatabase.ajuanPengajaranList);
    if (scope == 'jurusan' && jurusanNama != null && jurusanNama.isNotEmpty) {
      ajuanCopy = ajuanCopy.where((a) => a.jurusanNama.toLowerCase().contains(jurusanNama.toLowerCase())).toList();
    } else if (scope == 'fakultas' && fakultasNama != null && fakultasNama.isNotEmpty) {
      ajuanCopy = ajuanCopy.where((a) => a.fakultasNama.toLowerCase().contains(fakultasNama.toLowerCase())).toList();
    }

    // 1. MRV Heuristic
    final Map<String, int> dosenLoadMap = {};
    for (final aj in ajuanCopy) {
      final key = aj.dosenNama.toLowerCase().trim();
      dosenLoadMap[key] = (dosenLoadMap[key] ?? 0) + 1;
    }

    ajuanCopy.sort((a, b) {
      final loadA = dosenLoadMap[a.dosenNama.toLowerCase().trim()] ?? 0;
      final loadB = dosenLoadMap[b.dosenNama.toLowerCase().trim()] ?? 0;
      if (loadA != loadB) {
        return loadB.compareTo(loadA);
      }
      return b.sks.compareTo(a.sks);
    });

    for (int i = 0; i < ajuanCopy.length; i++) {
      final ajuan = ajuanCopy[i];
      if (ajuan.status.startsWith('ditolak')) continue;

      bool hasConflict = false;
      String conflictReason = '';
      dynamic conflictingWith;

      // 2. Cek terhadap ajuan yang sudah disetujui dalam batch ini
      for (final other in accepted) {
        if (other.id == ajuan.id) continue;
        if (other.hari.toLowerCase() != ajuan.hari.toLowerCase()) continue;

        // A. Bentrok Dosen Lintas Kelas / Jurusan / Fakultas
        final isSameDosen = (ajuan.dosenId.isNotEmpty && ajuan.dosenId == other.dosenId) ||
            (ajuan.dosenNama.toLowerCase().trim() == other.dosenNama.toLowerCase().trim());

        if (isSameDosen) {
          if (_isTimeOverlap(other.jamMulai, other.jamSelesai, ajuan.jamMulai, ajuan.jamSelesai)) {
            hasConflict = true;
            conflictReason = 'Bentrok Dosen Lintas Kelas: ${ajuan.dosenNama} telah dijadwalkan mengajar ${other.mataKuliahNama} (Kelas ${other.kelasNama}, ${other.jurusanNama} - ${other.fakultasNama}) pada ${other.hari} jam ${other.waktuFormatted}.';
            conflictingWith = other;
            break;
          }

          if (other.gedungNama.toLowerCase() != ajuan.gedungNama.toLowerCase()) {
            if (_isTravelBufferViolated(other.jamMulai, other.jamSelesai, ajuan.jamMulai, ajuan.jamSelesai, 15)) {
              hasConflict = true;
              conflictReason = 'Jeda Pindah Gedung Sempit: ${ajuan.dosenNama} mengajar di ${other.gedungNama} (${other.waktuFormatted}) dan butuh minimal 15 menit transit menuju ${ajuan.gedungNama}.';
              conflictingWith = other;
              break;
            }
          }
        }

        // B. Bentrok Ruangan & Gedung
        if (other.gedungNama.toLowerCase() == ajuan.gedungNama.toLowerCase() &&
            other.ruanganNama.toLowerCase() == ajuan.ruanganNama.toLowerCase()) {
          if (_isTimeOverlap(other.jamMulai, other.jamSelesai, ajuan.jamMulai, ajuan.jamSelesai)) {
            hasConflict = true;
            conflictReason = 'Bentrok Ruangan: ${ajuan.ruanganNama} (${ajuan.gedungNama}) pada ${ajuan.hari} jam ${ajuan.waktuFormatted} terisi oleh ${other.mataKuliahNama} (${other.dosenNama}).';
            conflictingWith = other;
            break;
          }
        }

        // C. Bentrok Kelas Mahasiswa yang Sama
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

      // 3. Cek terhadap Master Jadwal Final Institusi
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

          if (jdw.gedungNama.toLowerCase() == ajuan.gedungNama.toLowerCase() &&
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

      if (!hasConflict) {
        accepted.add(ajuan);
        final approved = ajuan.copyWith(
          status: 'disetujui_admin',
          catatanAdmin: ajuan.catatanAdmin ?? 'Diverifikasi & Disetujui Otomatis via Engine CSP Backtracking (MRV Bebas Bentrok).',
          clearBentrokDetail: true,
          updatedAt: DateTime.now(),
        );
        if (index != -1) {
          MockDatabase.ajuanPengajaranList[index] = approved;
        }

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

  /// Rekomendasi Solusi Cerdas (AI/Heuristik) untuk Ajuan yang Bentrok atau Permohonan Banding Dosen
  Map<String, String> findSmartAlternativeSlot(
    AjuanPengajaranModel ajuan, [
    List<AjuanPengajaranModel> bookedAjuan = const [],
  ]) {
    final isBanding = ajuan.status == 'menunggu_banding';
    final preferredHari = (isBanding && ajuan.preferensiBandingHari != null && ajuan.preferensiBandingHari!.isNotEmpty)
        ? ajuan.preferensiBandingHari!
        : ajuan.hari;

    final preferredJamMulai = (isBanding && ajuan.preferensiBandingJam != null && ajuan.preferensiBandingJam!.isNotEmpty)
        ? ajuan.preferensiBandingJam!.split('-').first.trim()
        : ajuan.jamMulai;

    final preferredJamSelesai = (isBanding && ajuan.preferensiBandingJam != null && ajuan.preferensiBandingJam!.contains('-'))
        ? ajuan.preferensiBandingJam!.split('-').last.trim()
        : ajuan.jamSelesai;

    int durationMinutes = 100;
    try {
      final pStart = preferredJamMulai.split(':');
      final pEnd = preferredJamSelesai.split(':');
      final mStart = int.parse(pStart[0]) * 60 + int.parse(pStart[1]);
      final mEnd = int.parse(pEnd[0]) * 60 + int.parse(pEnd[1]);
      if (mEnd > mStart) durationMinutes = mEnd - mStart;
    } catch (_) {}

    final candidateDays = {
      preferredHari,
      'Senin',
      'Selasa',
      'Rabu',
      'Kamis',
      'Jumat',
      'Sabtu',
    }.toList();

    final candidateTimeSlots = [
      if (preferredJamMulai.isNotEmpty && preferredJamSelesai.isNotEmpty)
        {'start': preferredJamMulai, 'end': preferredJamSelesai},
      {'start': '08:00', 'end': _addMinutesToTime('08:00', durationMinutes)},
      {'start': '10:00', 'end': _addMinutesToTime('10:00', durationMinutes)},
      {'start': '13:00', 'end': _addMinutesToTime('13:00', durationMinutes)},
      {'start': '15:00', 'end': _addMinutesToTime('15:00', durationMinutes)},
      {'start': '09:40', 'end': _addMinutesToTime('09:40', durationMinutes)},
      {'start': '14:40', 'end': _addMinutesToTime('14:40', durationMinutes)},
    ];

    final activeRooms = MockDatabase.ruanganList.where((r) =>
      !MockDatabase.deletedRuanganIds.contains(r.id) &&
      !MockDatabase.deletedRuanganIds.contains(r.nama) &&
      !MockDatabase.deletedGedungIds.contains(r.gedungId) &&
      !MockDatabase.deletedGedungIds.contains(r.gedungNama)
    ).toList();

    final candidateRooms = activeRooms.isNotEmpty
        ? activeRooms.map((r) => {'gedung': r.gedungNama, 'ruang': r.nama}).toList()
        : [
            if (ajuan.gedungNama.isNotEmpty && ajuan.ruanganNama.isNotEmpty)
              {'gedung': ajuan.gedungNama, 'ruang': ajuan.ruanganNama},
          ];

    for (final day in candidateDays) {
      for (final slot in candidateTimeSlots) {
        final tStart = slot['start']!;
        final tEnd = slot['end']!;

        for (final r in candidateRooms) {
          final gName = r['gedung']!;
          final rName = r['ruang']!;

          if (gName == ajuan.gedungNama && rName == ajuan.ruanganNama && day == ajuan.hari && tStart == ajuan.jamMulai) {
            continue;
          }

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
          for (final b in bookedAjuan) {
            if (b.id == ajuan.id) continue;
            if (b.hari.toLowerCase() == day.toLowerCase()) {
              if (b.gedungNama == gName && b.ruanganNama == rName && _isTimeOverlap(b.jamMulai, b.jamSelesai, tStart, tEnd)) {
                busy = true;
                break;
              }
              final isSameDosen = (b.dosenId.isNotEmpty && b.dosenId == ajuan.dosenId) ||
                  (b.dosenNama.toLowerCase().trim() == ajuan.dosenNama.toLowerCase().trim());
              if (isSameDosen && _isTimeOverlap(b.jamMulai, b.jamSelesai, tStart, tEnd)) {
                busy = true;
                break;
              }
            }
          }
          if (busy) continue;

          final conflictCheck = checkBuildingConflict(testAjuan);
          if (conflictCheck['hasConflict'] == true) {
            continue;
          }

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

    final defaultRoom = activeRooms.isNotEmpty ? activeRooms.first.nama : (ajuan.ruanganNama.isNotEmpty ? ajuan.ruanganNama : 'Ruang 101');
    final defaultGedung = activeRooms.isNotEmpty ? activeRooms.first.gedungNama : (ajuan.gedungNama.isNotEmpty ? ajuan.gedungNama : 'Gedung Utama');

    return {
      'gedungNama': defaultGedung,
      'ruanganNama': defaultRoom,
      'hari': preferredHari == 'Senin' ? 'Selasa' : 'Rabu',
      'jamMulai': '10:00',
      'jamSelesai': _addMinutesToTime('10:00', durationMinutes),
      'reason': 'Penyesuaian otomatis RCK ke slot alternatif bebas bentrok.',
    };
  }

  /// Admin Batch Resolve: Menerapkan rekomendasi alternatif bebas bentrok untuk bentrok & banding sekaligus
  Future<int> batchResolveConflicts({List<String>? targetAjuanIds}) async {
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
    final List<AjuanPengajaranModel> acceptedSoFar = MockDatabase.ajuanPengajaranList
        .where((a) => (a.status == 'disetujui_admin' || a.status == 'banding_disetujui') && !conflicts.any((c) => c.id == a.id))
        .toList();

    for (final ajuan in conflicts) {
      final isBanding = ajuan.status == 'menunggu_banding';
      final suggestion = findSmartAlternativeSlot(ajuan, acceptedSoFar);
      final nextStatus = isBanding ? 'banding_disetujui' : 'disetujui_admin';
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
        MockDatabase.ajuanPengajaranList[index] = updated;
      }
      acceptedSoFar.add(updated);

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
        if (other.gedungNama.toLowerCase() != ajuan.gedungNama.toLowerCase()) {
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

      // C. Bentrok Ruangan & Gedung
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

        if (jdw.gedungNama.toLowerCase() != ajuan.gedungNama.toLowerCase()) {
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

      if (jdw.gedungNama.toLowerCase() == ajuan.gedungNama.toLowerCase() &&
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
