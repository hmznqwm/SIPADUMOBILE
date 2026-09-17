import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';

import '../models/user_model.dart';
import '../models/mata_kuliah_model.dart';
import '../models/slot_waktu_model.dart';
import '../models/availability_model.dart';
import '../models/jadwal_model.dart';
import '../models/notification_model.dart';
import '../models/gedung_model.dart';
import '../models/ruangan_model.dart';
import '../models/ajuan_pengajaran_model.dart';

/// Central in-memory & locally-persisted mock data store for Smart Schedule app simulation.
class MockDatabase {
  static const Duration defaultDelay = Duration(milliseconds: 400);
  static bool _initialized = false;

  // ── Global System State ──
  static bool isSubmissionActive = true;
  static final Set<String> priorityDosenIds = {'DSN001'};

  // ── Deleted IDs Sets (To prevent stale online responses from reviving deleted items) ──
  static final Set<String> deletedGedungIds = {};
  static final Set<String> deletedRuanganIds = {};
  static final Set<String> deletedFakultasIds = {};
  static final Set<String> deletedMatkulIds = {};
  static final Set<String> deletedUserIds = {};

  /// Initialize local cache from SharedPreferences (Fail-safe persistence)
  static Future<void> initLocalCache({bool forceReload = false}) async {
    if (_initialized && !forceReload) return;
    try {
      final prefs = await SharedPreferences.getInstance();

      // 0. Load Deleted IDs
      final delGedung = prefs.getStringList('cached_deleted_gedung_ids');
      if (delGedung != null) {
        deletedGedungIds.clear();
        deletedGedungIds.addAll(delGedung);
      }
      final delRuangan = prefs.getStringList('cached_deleted_ruangan_ids');
      if (delRuangan != null) {
        deletedRuanganIds.clear();
        deletedRuanganIds.addAll(delRuangan);
      }
      final delFak = prefs.getStringList('cached_deleted_fakultas_ids');
      if (delFak != null) {
        deletedFakultasIds.clear();
        deletedFakultasIds.addAll(delFak);
      }
      final delMatkul = prefs.getStringList('cached_deleted_matkul_ids');
      if (delMatkul != null) {
        deletedMatkulIds.clear();
        deletedMatkulIds.addAll(delMatkul);
      }
      final delUsers = prefs.getStringList('cached_deleted_user_ids');
      if (delUsers != null) {
        deletedUserIds.clear();
        deletedUserIds.addAll(delUsers);
      }
      
      // 1. Users
      final usersJson = prefs.getString('cached_mock_users');
      if (usersJson != null && usersJson.isNotEmpty) {
        final List list = jsonDecode(usersJson);
        final loaded = list.map((u) => UserModel.fromJson(u)).where((u) => !deletedUserIds.contains(u.id)).toList();
        demoUsers.clear();
        demoUsers.addAll(loaded);
      } else {
        demoUsers.removeWhere((u) => deletedUserIds.contains(u.id));
      }
      // Pastikan SEMUA user hardcoded (sistem + demo dosen) SELALU ada dan tidak bisa dihapus permanen
      final _hardcoded = [
        const UserModel(id: 'DSN001', nama: 'Dr. Ahmad Fauzi, M.Kom.', email: 'ahmad.fauzi@university.ac.id', role: 'dosen', jurusanId: 'JUR001', jurusanNama: 'Teknik Informatika', fakultasNama: 'Fakultas Sains & Teknologi', isPriority: true),
        const UserModel(id: 'DSN002', nama: 'Siti Nurhaliza, S.T., M.T.', email: 'siti.nurhaliza@university.ac.id', role: 'dosen', jurusanId: 'JUR001', jurusanNama: 'Teknik Informatika', fakultasNama: 'Fakultas Sains & Teknologi'),
        const UserModel(id: 'DSN003', nama: 'Prof. Budi Santoso, Ph.D.', email: 'budi.santoso@university.ac.id', role: 'dosen', jurusanId: 'JUR002', jurusanNama: 'Sistem Informasi', fakultasNama: 'Fakultas Sains & Teknologi'),
        const UserModel(id: 'KJR001', nama: 'Ir. Hendra Wijaya, M.T. (KaProdi TI)', email: 'kaprodi.ti@university.ac.id', role: 'kajur', jurusanId: 'JUR001', jurusanNama: 'Teknik Informatika', fakultasNama: 'Fakultas Sains & Teknologi'),
        const UserModel(id: 'DKN001', nama: 'Prof. Dr. Ir. H. Bambang, M.Sc. (Dekan FST)', email: 'dekan.fst@university.ac.id', role: 'dekan', jurusanId: 'JUR001', jurusanNama: 'Fakultas Sains & Teknologi', fakultasNama: 'Fakultas Sains & Teknologi'),
        const UserModel(id: 'ADM001', nama: 'Super Admin', email: 'hamizanqowiem90@gmail.com', role: 'admin', jurusanId: 'GLOBAL', jurusanNama: 'Administrator Sistem', fakultasNama: 'Universitas'),
        const UserModel(id: 'ADM002', nama: 'Hamizan Qowiem (Admin)', email: 'hamizanqowiem4@gmail.com', role: 'admin', jurusanId: 'GLOBAL', jurusanNama: 'Administrator Sistem', fakultasNama: 'Universitas'),
      ];
      // ID yang tidak boleh dihapus permanen
      const _protectedIds = {'DSN001', 'DSN002', 'DSN003', 'KJR001', 'DKN001', 'ADM001', 'ADM002'};
      // Hapus dari deletedUserIds agar tidak terblokir
      deletedUserIds.removeAll(_protectedIds);
      // Restore/update setiap user hardcoded (replace jika sudah ada, tambah jika belum ada)
      for (final sys in _hardcoded) {
        demoUsers.removeWhere((u) => u.id == sys.id); // hapus versi lama
        demoUsers.add(sys); // tambahkan versi terbaru
      }
      
      // 2. Priority Dosen
      final priorityList = prefs.getStringList('cached_priority_dosen_ids');
      if (priorityList != null) {
        priorityDosenIds.clear();
        priorityDosenIds.addAll(priorityList.where((id) => !deletedUserIds.contains(id)));
      }

      // 3. Gedung
      final gedungJson = prefs.getString('cached_master_gedung');
      if (gedungJson != null && gedungJson.isNotEmpty) {
        final List list = jsonDecode(gedungJson);
        final loaded = list.map((g) => GedungModel.fromJson(g)).where((g) {
          if (deletedGedungIds.contains(g.id) || deletedGedungIds.contains(g.nama)) return false;
          final gName = g.nama.trim().toLowerCase();
          final isLegacyDemo = gName.contains('habibie') ||
              gName.contains('hatta') ||
              gName.contains('soekarno') ||
              gName.contains('gedung a') ||
              gName.contains('gedung b') ||
              gName.contains('gedung c') ||
              gName.contains('gedung e') ||
              gName.contains('gedung f');
          return !isLegacyDemo;
        }).toList();
        gedungList
          ..clear()
          ..addAll(loaded);
      }
      if (gedungList.isEmpty) {
        gedungList
          ..clear()
          ..add(const GedungModel(
            id: 'GDG_SAINTEK',
            nama: 'Gedung Saintek',
            jamBuka: '07:00',
            jamTutup: '17:00',
            aksesJurusan: 'Fakultas Sains & Teknologi',
          ));
        await saveLocalGedung();
      }

      // 3b. Ruangan
      final ruanganJson = prefs.getString('cached_master_ruangan');
      if (ruanganJson != null && ruanganJson.isNotEmpty) {
        final List list = jsonDecode(ruanganJson);
        final loaded = list.map((r) => RuanganModel.fromJson(r)).where((r) {
          final rid = r.id.trim().toUpperCase();
          final isLegacyDemo = !rid.startsWith('RNG_') ||
              rid.startsWith('RNG_0') ||
              rid.startsWith('RNG_30') ||
              rid.startsWith('RNG_LAB') ||
              rid.startsWith('RNG_50') ||
              rid.startsWith('RNG_F10');
          return !isLegacyDemo;
        }).toList();
        ruanganList
          ..clear()
          ..addAll(loaded);
      }
      if (ruanganList.isEmpty) {
        ruanganList
          ..clear()
          ..addAll([
            const RuanganModel(
              id: 'RNG_101',
              nama: 'Ruang 101',
              gedungId: 'GDG_SAINTEK',
              gedungNama: 'Gedung Saintek',
              kapasitas: 40,
              tipeRuangan: 'Kelas Teori',
            ),
            const RuanganModel(
              id: 'RNG_RPL',
              nama: 'Lab RPL',
              gedungId: 'GDG_SAINTEK',
              gedungNama: 'Gedung Saintek',
              kapasitas: 40,
              tipeRuangan: 'Kelas Teori',
            ),
          ]);
        await saveLocalRuangan();
      }

      final activeGedungIds = gedungList.map((g) => g.id.trim()).where((id) => id.isNotEmpty).toSet();
      final activeGedungNames = gedungList.map((g) => g.nama.trim().toLowerCase()).where((n) => n.isNotEmpty).toSet();

      ruanganList.removeWhere((r) {
        if (deletedRuanganIds.contains(r.id) || deletedRuanganIds.contains(r.nama)) return true;
        if (deletedGedungIds.contains(r.gedungId) || deletedGedungIds.contains(r.gedungNama)) return true;

        final rGedungId = r.gedungId.trim();
        final rGedungNama = r.gedungNama.trim().toLowerCase();

        final matchId = rGedungId.isNotEmpty && activeGedungIds.contains(rGedungId);
        final matchNama = rGedungNama.isNotEmpty && activeGedungNames.contains(rGedungNama);

        return !(matchId || matchNama);
      });

      await saveLocalRuangan();
      await saveLocalGedung();

      // 4. Fakultas
      final fakultasJson = prefs.getString('cached_master_fakultas');
      if (fakultasJson != null && fakultasJson.isNotEmpty) {
        final List list = jsonDecode(fakultasJson);
        final loaded = list.map((f) {
          final map = Map<String, dynamic>.from(f);
          final jurRaw = map['jurusan'];
          if (jurRaw is List) {
            map['jurusan'] = jurRaw.map((e) => e.toString()).toList();
          } else {
            map['jurusan'] = <String>['Teknik Informatika'];
          }
          return map;
        }).where((f) {
          final fid = f['id']?.toString() ?? '';
          final fnama = f['nama']?.toString() ?? '';
          return !deletedFakultasIds.contains(fid) && !deletedFakultasIds.contains(fnama);
        }).toList();
        fakultasData
          ..clear()
          ..addAll(loaded);
      } else {
        fakultasData.removeWhere((f) {
          final fid = f['id']?.toString() ?? '';
          final fnama = f['nama']?.toString() ?? '';
          return deletedFakultasIds.contains(fid) || deletedFakultasIds.contains(fnama);
        });
      }

      // 5. Matkul
      final matkulJson = prefs.getString('cached_master_matkul');
      if (matkulJson != null && matkulJson.isNotEmpty) {
        final List list = jsonDecode(matkulJson);
        final loaded = list.map((m) {
          final map = Map<String, dynamic>.from(m);
          final kelasRaw = map['kelas'];
          if (kelasRaw is List) {
            map['kelas'] = kelasRaw.map((e) => e.toString()).toList();
          } else {
            map['kelas'] = <String>['A'];
          }
          return map;
        }).where((m) {
          final mkId = (m['id']?.toString() ?? m['kode']?.toString() ?? '').toLowerCase();
          final mkNama = (m['nama']?.toString() ?? '').toLowerCase();
          final isLegacy = mkNama.contains('pemrograman web & mobile lanjut') ||
                           mkNama.contains('akuntansi keuangan menengah');
          return !isLegacy && !deletedMatkulIds.contains(mkId) && !deletedMatkulIds.contains(mkNama);
        }).toList();
        matkulData
          ..clear()
          ..addAll(loaded);
      }
      if (matkulData.isEmpty) {
        matkulData
          ..clear()
          ..addAll([
            {
              'kode': 'IF101',
              'nama': 'Algoritma & Pemrograman',
              'sks': 3,
              'jurusan': 'Teknik Informatika',
              'fakultas': 'Fakultas Sains & Teknologi',
              'kelas': ['TI-1A', 'TI-1B'],
              'dosen': 'Dr. Ahmad Fauzi, M.T.',
              'dosenId': 'DSN001',
            },
            {
              'kode': 'IF302',
              'nama': 'Kecerdasan Buatan (AI)',
              'sks': 3,
              'jurusan': 'Teknik Informatika',
              'fakultas': 'Fakultas Sains & Teknologi',
              'kelas': ['TI-3A', 'TI-3B'],
              'dosen': 'Siti Nurhaliza, M.Kom.',
              'dosenId': 'DSN002',
            },
            {
              'kode': 'SI201',
              'nama': 'Basis Data Lanjut',
              'sks': 3,
              'jurusan': 'Sistem Informasi',
              'fakultas': 'Fakultas Sains & Teknologi',
              'kelas': ['SI-2A'],
              'dosen': 'Prof. Budi Santoso, Ph.D.',
              'dosenId': 'DSN003',
            },
            {
              'kode': 'MN101',
              'nama': 'Pengantar Manajemen',
              'sks': 3,
              'jurusan': 'Manajemen',
              'fakultas': 'Fakultas Ekonomi & Bisnis',
              'kelas': ['MN-1A', 'MN-1B'],
              'dosen': 'Dr. Hendra Wijaya, S.E., M.M.',
              'dosenId': 'DSN004',
            },
            {
              'kode': 'AK201',
              'nama': 'Akuntansi Biaya',
              'sks': 3,
              'jurusan': 'Akuntansi',
              'fakultas': 'Fakultas Ekonomi & Bisnis',
              'kelas': ['AK-2A'],
              'dosen': 'Dian Lestari, S.E., M.Ak.',
              'dosenId': 'DSN005',
            },
          ]);
        await saveLocalMatkul();
      }

      // 6. Ajuan Pengajaran (Fail-safe RCK persistence)
      final ajuanJson = prefs.getString('cached_ajuan_pengajaran');
      if (ajuanJson != null && ajuanJson.isNotEmpty) {
        final List list = jsonDecode(ajuanJson);
        final loaded = list.map((a) => AjuanPengajaranModel.fromJson(a)).where((a) {
          if (deletedGedungIds.contains(a.gedungNama) ||
              deletedRuanganIds.contains(a.ruanganNama) ||
              deletedMatkulIds.contains(a.mataKuliahId) || deletedMatkulIds.contains(a.mataKuliahNama) ||
              deletedUserIds.contains(a.dosenId) || deletedUserIds.contains(a.dosenNama) ||
              deletedFakultasIds.contains(a.fakultasNama)) return false;

          final gNama = a.gedungNama.trim().toLowerCase();
          final rNama = a.ruanganNama.trim().toLowerCase();
          final mNama = a.mataKuliahNama.trim().toLowerCase();

          final isLegacy = gNama.contains('habibie') || gNama.contains('hatta') || gNama.contains('soekarno') ||
                           rNama.contains('r.b-201') || mNama.contains('pemrograman web & mobile lanjut') ||
                           mNama.contains('akuntansi keuangan menengah');
          return !isLegacy;
        }).toList();
        ajuanPengajaranList
          ..clear()
          ..addAll(loaded);
      } else {
        ajuanPengajaranList.removeWhere((a) {
          final gNama = a.gedungNama.trim().toLowerCase();
          final rNama = a.ruanganNama.trim().toLowerCase();
          final mNama = a.mataKuliahNama.trim().toLowerCase();
          return gNama.contains('habibie') || gNama.contains('hatta') || gNama.contains('soekarno') ||
                 rNama.contains('r.b-201') || mNama.contains('pemrograman web & mobile lanjut') ||
                 mNama.contains('akuntansi keuangan menengah');
        });
      }

      // 7. Jadwal Final (Fail-safe RCK persistence)
      final jadwalJson = prefs.getString('cached_jadwal_final');
      if (jadwalJson != null && jadwalJson.isNotEmpty) {
        final List list = jsonDecode(jadwalJson);
        final loaded = list.map((j) => JadwalModel.fromJson(j)).where((j) {
          if (deletedGedungIds.contains(j.gedungNama) ||
              deletedRuanganIds.contains(j.ruanganNama) ||
              deletedMatkulIds.contains(j.mataKuliahId) || deletedMatkulIds.contains(j.mataKuliahNama) ||
              deletedUserIds.contains(j.dosenId) || deletedUserIds.contains(j.dosenNama) ||
              deletedFakultasIds.contains(j.fakultasNama)) return false;

          final gNama = (j.gedungNama ?? '').trim().toLowerCase();
          final rNama = (j.ruanganNama ?? '').trim().toLowerCase();
          final mNama = (j.mataKuliahNama ?? '').trim().toLowerCase();

          final isLegacy = gNama.contains('habibie') || gNama.contains('hatta') || gNama.contains('soekarno') ||
                           rNama.contains('r.b-201') || mNama.contains('pemrograman web & mobile lanjut') ||
                           mNama.contains('akuntansi keuangan menengah');
          return !isLegacy;
        }).toList();
        jadwalFinal
          ..clear()
          ..addAll(loaded);
        jadwalGlobalMaster
          ..clear()
          ..addAll(loaded);
      } else {
        jadwalFinal.removeWhere((j) {
          final gNama = (j.gedungNama ?? '').trim().toLowerCase();
          final rNama = (j.ruanganNama ?? '').trim().toLowerCase();
          final mNama = (j.mataKuliahNama ?? '').trim().toLowerCase();
          return gNama.contains('habibie') || gNama.contains('hatta') || gNama.contains('soekarno') ||
                 rNama.contains('r.b-201') || mNama.contains('pemrograman web & mobile lanjut') ||
                 mNama.contains('akuntansi keuangan menengah');
        });
        jadwalGlobalMaster.removeWhere((j) {
          final gNama = (j.gedungNama ?? '').trim().toLowerCase();
          final rNama = (j.ruanganNama ?? '').trim().toLowerCase();
          final mNama = (j.mataKuliahNama ?? '').trim().toLowerCase();
          return gNama.contains('habibie') || gNama.contains('hatta') || gNama.contains('soekarno') ||
                 rNama.contains('r.b-201') || mNama.contains('pemrograman web & mobile lanjut') ||
                 mNama.contains('akuntansi keuangan menengah');
        });
      }

      if (jadwalGlobalMaster.isEmpty) {
        jadwalGlobalMaster
          ..clear()
          ..addAll([
            const JadwalModel(
              id: 'JDW-G01',
              mataKuliahId: 'IF101',
              mataKuliahNama: 'Algoritma & Pemrograman',
              sks: 3,
              ruanganNama: 'Ruang 101',
              gedungNama: 'Gedung Saintek',
              kelasNama: 'TI-1A',
              hari: 'Senin',
              jamMulai: '08:00',
              jamSelesai: '10:30',
              semesterNama: 'Ganjil 2026/2027',
              jumlahMahasiswa: 35,
              dosenId: 'DSN001',
              dosenNama: 'Dr. Ahmad Fauzi, M.Kom.',
              fakultasNama: 'Fakultas Sains & Teknologi',
              jurusanNama: 'Teknik Informatika',
            ),
            const JadwalModel(
              id: 'JDW-G02',
              mataKuliahId: 'IF302',
              mataKuliahNama: 'Kecerdasan Buatan (AI)',
              sks: 3,
              ruanganNama: 'Lab RPL',
              gedungNama: 'Gedung Saintek',
              kelasNama: 'TI-3A',
              hari: 'Selasa',
              jamMulai: '09:50',
              jamSelesai: '12:20',
              semesterNama: 'Ganjil 2026/2027',
              jumlahMahasiswa: 40,
              dosenId: 'DSN002',
              dosenNama: 'Siti Nurhaliza, S.T., M.T.',
              fakultasNama: 'Fakultas Sains & Teknologi',
              jurusanNama: 'Teknik Informatika',
            ),
            const JadwalModel(
              id: 'JDW-G03',
              mataKuliahId: 'SI201',
              mataKuliahNama: 'Basis Data Lanjut',
              sks: 3,
              ruanganNama: 'Ruang 101',
              gedungNama: 'Gedung Saintek',
              kelasNama: 'SI-3A',
              hari: 'Rabu',
              jamMulai: '13:00',
              jamSelesai: '15:30',
              semesterNama: 'Ganjil 2026/2027',
              jumlahMahasiswa: 38,
              dosenId: 'DSN003',
              dosenNama: 'Prof. Budi Santoso, Ph.D.',
              fakultasNama: 'Fakultas Sains & Teknologi',
              jurusanNama: 'Sistem Informasi',
            ),
          ]);
        jadwalFinal
          ..clear()
          ..addAll(jadwalGlobalMaster);
      }

      // 8. Strict Relational Integrity Enforcement
      purgeInvalidSchedules();
      await saveLocalGedung();
      await saveLocalRuangan();
      await saveLocalMatkul();
      await saveLocalUsers();
      await saveLocalAjuan();
      await saveLocalJadwal();

      _initialized = true;
    } catch (_) {}
  }

  /// Helper: Check 100% strict 4-way relational validity against active Master Data
  static bool isRelationalValidItem({
    String? gedungId,
    String? gedungNama,
    String? ruanganId,
    String? ruanganNama,
    String? matkulId,
    String? matkulNama,
    String? dosenId,
    String? dosenNama,
  }) {
    if (gedungList.isEmpty || ruanganList.isEmpty || matkulData.isEmpty || demoUsers.isEmpty) {
      return false;
    }

    final gId = (gedungId ?? '').trim().toLowerCase();
    final gNama = (gedungNama ?? '').trim().toLowerCase();
    if (gNama.contains('habibie') || gNama.contains('hatta') || gNama.contains('soekarno')) return false;

    final gMatch = gedungList.any((g) {
      final gGedungId = g.id.trim().toLowerCase();
      final gGedungNama = g.nama.trim().toLowerCase();
      if (gId.isNotEmpty && gGedungId == gId) return true;
      if (gNama.isNotEmpty && (gGedungNama == gNama || gNama.contains(gGedungNama) || gGedungNama.contains(gNama))) return true;
      return false;
    });
    if (!gMatch) return false;

    final rId = (ruanganId ?? '').trim().toLowerCase();
    final rNama = (ruanganNama ?? '').trim().toLowerCase();
    if (rNama.contains('r.b-201') || rNama.contains('habibie') || rNama.contains('hatta')) return false;

    final rMatch = ruanganList.any((r) {
      final rRuanganId = r.id.trim().toLowerCase();
      final rRuanganNama = r.nama.trim().toLowerCase();
      if (rId.isNotEmpty && rRuanganId == rId) return true;
      if (rNama.isNotEmpty && (rRuanganNama == rNama || rNama.contains(rRuanganNama) || rRuanganNama.contains(rNama))) return true;
      return false;
    });
    if (!rMatch) return false;

    final mId = (matkulId ?? '').trim().toLowerCase();
    final mNama = (matkulNama ?? '').trim().toLowerCase();
    if (mNama.contains('pemrograman web & mobile lanjut') || mNama.contains('akuntansi keuangan menengah')) return false;

    final mMatch = matkulData.any((m) {
      final mKode = (m['kode'] ?? m['id'] ?? '').toString().trim().toLowerCase();
      final mMataKuliahNama = (m['nama'] ?? '').toString().trim().toLowerCase();
      if (mId.isNotEmpty && mKode == mId) return true;
      if (mNama.isNotEmpty && (mMataKuliahNama == mNama || mNama.contains(mMataKuliahNama) || mMataKuliahNama.contains(mNama))) return true;
      return false;
    });
    if (!mMatch) return false;

    final uId = (dosenId ?? '').trim().toLowerCase();
    final uNama = (dosenNama ?? '').trim().toLowerCase();

    final uMatch = demoUsers.any((u) {
      final uUserId = u.id.trim().toLowerCase();
      final uUserNama = u.nama.trim().toLowerCase();
      if (uId.isNotEmpty && uUserId == uId) return true;
      if (uNama.isNotEmpty && (uUserNama == uNama || uNama.contains(uUserNama) || uUserNama.contains(uNama))) return true;
      return false;
    });
    if (!uMatch) return false;

    return true;
  }

  /// Strict Relational Integrity: Purge any schedule whose Gedung, Ruangan, Matkul, or Dosen is missing in active Master Data
  static void purgeInvalidSchedules() {
    if (gedungList.isEmpty || ruanganList.isEmpty || matkulData.isEmpty || demoUsers.isEmpty) {
      ajuanPengajaranList.clear();
      jadwalFinal.clear();
      jadwalGlobalMaster.clear();
      return;
    }

    ajuanPengajaranList.removeWhere((a) => !isRelationalValidItem(
      gedungNama: a.gedungNama,
      ruanganNama: a.ruanganNama,
      matkulId: a.mataKuliahId,
      matkulNama: a.mataKuliahNama,
      dosenId: a.dosenId,
      dosenNama: a.dosenNama,
    ));

    jadwalFinal.removeWhere((j) => !isRelationalValidItem(
      gedungId: j.gedungId,
      gedungNama: j.gedungNama,
      ruanganId: j.ruanganId,
      ruanganNama: j.ruanganNama,
      matkulId: j.mataKuliahId,
      matkulNama: j.mataKuliahNama,
      dosenId: j.dosenId,
      dosenNama: j.dosenNama,
    ));

    jadwalGlobalMaster.removeWhere((j) => !isRelationalValidItem(
      gedungId: j.gedungId,
      gedungNama: j.gedungNama,
      ruanganId: j.ruanganId,
      ruanganNama: j.ruanganNama,
      matkulId: j.mataKuliahId,
      matkulNama: j.mataKuliahNama,
      dosenId: j.dosenId,
      dosenNama: j.dosenNama,
    ));
  }

  static Future<void> saveLocalDeletedIds() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setStringList('cached_deleted_gedung_ids', deletedGedungIds.toList());
      await prefs.setStringList('cached_deleted_ruangan_ids', deletedRuanganIds.toList());
      await prefs.setStringList('cached_deleted_fakultas_ids', deletedFakultasIds.toList());
      await prefs.setStringList('cached_deleted_matkul_ids', deletedMatkulIds.toList());
      await prefs.setStringList('cached_deleted_user_ids', deletedUserIds.toList());
    } catch (_) {}
  }

  static Future<void> saveLocalUsers() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final usersData = demoUsers.map((u) => u.toJson()).toList();
      await prefs.setString('cached_mock_users', jsonEncode(usersData));
      await prefs.setStringList('cached_priority_dosen_ids', priorityDosenIds.toList());
      await saveLocalDeletedIds();
    } catch (_) {}
  }

  static Future<void> saveLocalGedung() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final data = gedungList.map((g) => g.toJson()).toList();
      await prefs.setString('cached_master_gedung', jsonEncode(data));
      await saveLocalDeletedIds();
    } catch (_) {}
  }

  static Future<void> saveLocalRuangan() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final data = ruanganList.map((r) => r.toJson()).toList();
      await prefs.setString('cached_master_ruangan', jsonEncode(data));
      await saveLocalDeletedIds();
    } catch (_) {}
  }

  static Future<void> saveLocalFakultas() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('cached_master_fakultas', jsonEncode(fakultasData));
      await saveLocalDeletedIds();
    } catch (_) {}
  }

  static Future<void> saveLocalMatkul() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final data = matkulData.map((m) => m).toList();
      await prefs.setString('cached_master_matkul', jsonEncode(data));
      await saveLocalDeletedIds();
    } catch (_) {}
  }

  static Future<void> saveLocalAjuan() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final data = ajuanPengajaranList.map((a) => a.toJson()).toList();
      await prefs.setString('cached_ajuan_pengajaran', jsonEncode(data));
      await saveLocalDeletedIds();
    } catch (_) {}
  }

  static Future<void> saveLocalJadwal() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final data = jadwalGlobalMaster.map((j) => j.toJson()).toList();
      await prefs.setString('cached_jadwal_final', jsonEncode(data));
      await saveLocalDeletedIds();
    } catch (_) {}
  }

  // ── Multi-Tier Submission Approvals State ──
  static final Map<String, String> dosenSubmissionStatus = {
    'DSN001': 'Diajukan',
    'DSN002': 'Diverifikasi KaProdi',
    'DSN003': 'Disetujui Dekan',
  };

  // ── Demo Users (Multi-Role Support) ──
  static final List<UserModel> demoUsers = [
    const UserModel(
      id: 'DSN001',
      nama: 'Dr. Ahmad Fauzi, M.Kom.',
      email: 'ahmad.fauzi@university.ac.id',
      role: 'dosen',
      jurusanId: 'JUR001',
      jurusanNama: 'Teknik Informatika',
      fakultasNama: 'Fakultas Sains & Teknologi',
      isPriority: true,
    ),
    const UserModel(
      id: 'DSN002',
      nama: 'Siti Nurhaliza, S.T., M.T.',
      email: 'siti.nurhaliza@university.ac.id',
      role: 'dosen',
      jurusanId: 'JUR001',
      jurusanNama: 'Teknik Informatika',
      fakultasNama: 'Fakultas Sains & Teknologi',
    ),
    const UserModel(
      id: 'DSN003',
      nama: 'Prof. Budi Santoso, Ph.D.',
      email: 'budi.santoso@university.ac.id',
      role: 'dosen',
      jurusanId: 'JUR002',
      jurusanNama: 'Sistem Informasi',
      fakultasNama: 'Fakultas Sains & Teknologi',
    ),
    const UserModel(
      id: 'KJR001',
      nama: 'Ir. Hendra Wijaya, M.T. (KaProdi TI)',
      email: 'kaprodi.ti@university.ac.id',
      role: 'kajur',
      jurusanId: 'JUR001',
      jurusanNama: 'Teknik Informatika',
      fakultasNama: 'Fakultas Sains & Teknologi',
    ),
    const UserModel(
      id: 'DKN001',
      nama: 'Prof. Dr. Ir. H. Bambang, M.Sc. (Dekan FST)',
      email: 'dekan.fst@university.ac.id',
      role: 'dekan',
      jurusanId: 'JUR001',
      jurusanNama: 'Fakultas Sains & Teknologi',
      fakultasNama: 'Fakultas Sains & Teknologi',
    ),
    const UserModel(
      id: 'ADM001',
      nama: 'Super Admin',
      email: 'hamizanqowiem90@gmail.com',
      role: 'admin',
      jurusanId: 'GLOBAL',
      jurusanNama: 'Administrator Sistem',
      fakultasNama: 'Universitas',
    ),
    const UserModel(
      id: 'ADM002',
      nama: 'Hamizan Qowiem (Admin)',
      email: 'hamizanqowiem4@gmail.com',
      role: 'admin',
      jurusanId: 'GLOBAL',
      jurusanNama: 'Administrator Sistem',
      fakultasNama: 'Universitas',
    ),
  ];

  // ── Master Data Gedung ──
  static final List<GedungModel> gedungList = [
    const GedungModel(
      id: 'GDG_SAINTEK',
      nama: 'Gedung Saintek',
      jamBuka: '07:00',
      jamTutup: '17:00',
      aksesJurusan: 'Fakultas Sains & Teknologi',
    ),
  ];

  // ── Master Data Ruangan ──
  static final List<RuanganModel> ruanganList = [
    const RuanganModel(
      id: 'RNG_101',
      nama: 'Ruang 101',
      gedungId: 'GDG_SAINTEK',
      gedungNama: 'Gedung Saintek',
      kapasitas: 40,
      tipeRuangan: 'Kelas Teori',
    ),
    const RuanganModel(
      id: 'RNG_RPL',
      nama: 'Lab RPL',
      gedungId: 'GDG_SAINTEK',
      gedungNama: 'Gedung Saintek',
      kapasitas: 40,
      tipeRuangan: 'Kelas Teori',
    ),
  ];

  // ── Master Data Fakultas & Prodi ──
  static final List<Map<String, dynamic>> fakultasData = [
    {
      'id': 'FAK001',
      'nama': 'Fakultas Sains & Teknologi',
      'gedung': 'Gedung Soekarno (A)',
      'jurusan': ['Teknik Informatika', 'Sistem Informasi'],
      'dekan': 'Dr. Ir. Budi Hartono, M.T.',
    },
    {
      'id': 'FAK002',
      'nama': 'Fakultas Ekonomi & Bisnis',
      'gedung': 'Gedung Hatta (B)',
      'jurusan': ['Manajemen', 'Akuntansi'],
      'dekan': 'Prof. Dr. Sri Mulyani, S.E., M.Si.',
    },
  ];

  // ── Master Data Mata Kuliah & Kelas ──
  static final List<Map<String, dynamic>> matkulData = [
    {
      'kode': 'IF101',
      'nama': 'Algoritma & Pemrograman',
      'sks': 3,
      'jurusan': 'Teknik Informatika',
      'fakultas': 'Fakultas Sains & Teknologi',
      'kelas': ['TI-1A', 'TI-1B'],
      'dosen': 'Dr. Ahmad Fauzi, M.T.',
      'dosenId': 'DSN001',
    },
    {
      'kode': 'IF302',
      'nama': 'Kecerdasan Buatan (AI)',
      'sks': 3,
      'jurusan': 'Teknik Informatika',
      'fakultas': 'Fakultas Sains & Teknologi',
      'kelas': ['TI-3A', 'TI-3B'],
      'dosen': 'Siti Nurhaliza, M.Kom.',
      'dosenId': 'DSN002',
    },
    {
      'kode': 'SI201',
      'nama': 'Basis Data Lanjut',
      'sks': 3,
      'jurusan': 'Sistem Informasi',
      'fakultas': 'Fakultas Sains & Teknologi',
      'kelas': ['SI-2A'],
      'dosen': 'Prof. Budi Santoso, Ph.D.',
      'dosenId': 'DSN003',
    },
    {
      'kode': 'MN101',
      'nama': 'Pengantar Manajemen',
      'sks': 3,
      'jurusan': 'Manajemen',
      'fakultas': 'Fakultas Ekonomi & Bisnis',
      'kelas': ['MN-1A', 'MN-1B'],
      'dosen': 'Dr. Hendra Wijaya, S.E., M.M.',
      'dosenId': 'DSN004',
    },
    {
      'kode': 'AK201',
      'nama': 'Akuntansi Biaya',
      'sks': 3,
      'jurusan': 'Akuntansi',
      'fakultas': 'Fakultas Ekonomi & Bisnis',
      'kelas': ['AK-2A'],
      'dosen': 'Dian Lestari, S.E., M.Ak.',
      'dosenId': 'DSN005',
    },
  ];

  // ── Slot Waktu ──
  static final List<SlotWaktuModel> slotWaktu = _generateSlotWaktu();

  static List<SlotWaktuModel> _generateSlotWaktu() {
    const days = ['Senin', 'Selasa', 'Rabu', 'Kamis', 'Jumat'];
    final standardSlots = [
      ('09:50', '10:40'),
      ('10:40', '11:30'),
      ('11:30', '12:20'),
      ('13:00', '13:50'),
      ('13:50', '14:40'),
      ('14:40', '15:30'),
      ('15:30', '16:20'),
    ];
    final earlySlots = [
      ('06:30', '07:20'),
      ('07:20', '08:10'),
      ('08:10', '09:00'),
      ('09:00', '09:50'),
    ];

    final allSlots = <SlotWaktuModel>[];
    int counter = 0;

    for (final day in days) {
      for (final slot in earlySlots) {
        counter++;
        allSlots.add(SlotWaktuModel(
          id: 'SLOT${counter.toString().padLeft(3, '0')}',
          hari: day,
          jamMulai: slot.$1,
          jamSelesai: slot.$2,
          durasiMenit: 50,
        ));
      }
      for (final slot in standardSlots) {
        counter++;
        allSlots.add(SlotWaktuModel(
          id: 'SLOT${counter.toString().padLeft(3, '0')}',
          hari: day,
          jamMulai: slot.$1,
          jamSelesai: slot.$2,
          durasiMenit: 50,
        ));
      }
    }
    return allSlots;
  }

  // ── Mata Kuliah Demo (DSN001) ──
  static final List<MataKuliahModel> mataKuliahDSN001 = [
    const MataKuliahModel(
      id: 'MK001',
      nama: 'Sistem Operasi',
      sks: 3,
      jurusanId: 'JUR001',
      jurusanNama: 'Teknik Informatika',
      fakultasNama: 'Fakultas Sains & Teknologi',
      semesterId: 'SEM001',
      kelasIds: ['KLS001', 'KLS002'],
      kelasNama: ['TI-3A', 'TI-3B'],
    ),
    const MataKuliahModel(
      id: 'MK002',
      nama: 'Algoritma & Struktur Data',
      sks: 3,
      jurusanId: 'JUR001',
      jurusanNama: 'Teknik Informatika',
      fakultasNama: 'Fakultas Sains & Teknologi',
      semesterId: 'SEM001',
      kelasIds: ['KLS003'],
      kelasNama: ['TI-2A'],
    ),
    const MataKuliahModel(
      id: 'MK003',
      nama: 'Manajemen Data & Informasi',
      sks: 3,
      jurusanId: 'JUR002',
      jurusanNama: 'Sistem Informasi',
      fakultasNama: 'Fakultas Sains & Teknologi',
      semesterId: 'SEM001',
      kebutuhanTipeRuangan: 'Laboratorium Komputer',
      kelasIds: ['KLS004', 'KLS005'],
      kelasNama: ['SI-3A', 'SI-3B'],
    ),
    const MataKuliahModel(
      id: 'MK004',
      nama: 'Sistem Informasi Manajemen',
      sks: 2,
      jurusanId: 'JUR003',
      jurusanNama: 'Manajemen',
      fakultasNama: 'Fakultas Ekonomi',
      semesterId: 'SEM001',
      kelasIds: ['KLS006'],
      kelasNama: ['MNJ-4A'],
    ),
  ];

  // ── In-Memory Availability State ──
  static AvailabilityModel? currentAvailability;
  static final List<AvailabilityHistoryItem> availabilityHistory = [
    AvailabilityHistoryItem(
      id: 'AVH001',
      submittedAt: DateTime(2026, 8, 15, 10, 30),
      slotCount: 18,
      status: 'approved',
      catatan: 'Ketersediaan telah disetujui oleh Ketua Jurusan.',
      semesterNama: 'Ganjil 2025/2026',
    ),
    AvailabilityHistoryItem(
      id: 'AVH002',
      submittedAt: DateTime(2026, 2, 20, 14, 15),
      slotCount: 12,
      status: 'revision',
      catatan: 'Slot waktu tidak mencukupi total SKS. Silakan tambah minimal 3 slot lagi.',
      semesterNama: 'Genap 2025/2026',
    ),
    AvailabilityHistoryItem(
      id: 'AVH003',
      submittedAt: DateTime(2026, 2, 25, 9, 0),
      slotCount: 16,
      status: 'approved',
      semesterNama: 'Genap 2025/2026',
    ),
  ];

  // ── Notifications ──
  static final List<NotificationModel> notifications = [
    NotificationModel(
      id: 'NOTIF001',
      judul: 'Jadwal Semester Ganjil 2026/2027 Dipublikasikan',
      pesan: 'Jadwal mengajar Anda untuk semester Ganjil 2026/2027 telah dipublikasikan. Silakan periksa jadwal Anda di menu Jadwal Mengajar.',
      tipe: 'jadwal_published',
      timestamp: DateTime(2026, 9, 10, 8, 0),
    ),
    NotificationModel(
      id: 'NOTIF002',
      judul: 'Permintaan Penambahan Slot Ketersediaan',
      pesan: 'Ketua Jurusan meminta Anda menambah opsi ketersediaan waktu untuk mata kuliah Sistem Operasi karena terjadi konflik jadwal. Silakan perbarui matriks ketersediaan Anda.',
      tipe: 'availability_request',
      timestamp: DateTime(2026, 9, 8, 14, 30),
    ),
    NotificationModel(
      id: 'NOTIF003',
      judul: 'Ketersediaan Anda Telah Disetujui',
      pesan: 'Matriks ketersediaan semester Ganjil 2026/2027 telah disetujui oleh Ketua Jurusan Teknik Informatika.',
      tipe: 'approval',
      timestamp: DateTime(2026, 9, 5, 10, 0),
      isRead: true,
    ),
    NotificationModel(
      id: 'NOTIF004',
      judul: 'Pengisian Ketersediaan Dibuka',
      pesan: 'Periode pengisian matriks ketersediaan untuk semester Ganjil 2026/2027 telah dibuka. Batas akhir pengisian: 30 September 2026.',
      tipe: 'info',
      timestamp: DateTime(2026, 9, 1, 7, 0),
      isRead: true,
    ),
    NotificationModel(
      id: 'NOTIF005',
      judul: 'Pengajuan Anda Disetujui KaProdi',
      pesan: 'Ajuan mengajar mata kuliah Pemrograman Web & Mobile Lanjut Anda telah diverifikasi dan disetujui oleh KaProdi TI.',
      tipe: 'approval',
      timestamp: DateTime(2026, 9, 9, 11, 0),
    ),
    NotificationModel(
      id: 'NOTIF006',
      judul: 'Reminder: Batas Pengisian Ketersediaan',
      pesan: 'Batas pengisian ketersediaan waktu mengajar semester Ganjil 2026/2027 tinggal 3 hari lagi. Segera isi sebelum ditutup.',
      tipe: 'availability_request',
      timestamp: DateTime(2026, 9, 7, 9, 0),
    ),
    NotificationModel(
      id: 'NOTIF_KJR001',
      judul: 'Ajuan Dosen Baru Masuk',
      pesan: '3 ajuan ketersediaan mengajar baru dari dosen Teknik Informatika menunggu verifikasi Anda.',
      tipe: 'info',
      timestamp: DateTime(2026, 9, 9, 8, 30),
    ),
    NotificationModel(
      id: 'NOTIF_KJR002',
      judul: 'Semua Ajuan Terverifikasi',
      pesan: 'Seluruh 23 ajuan ketersediaan mengajar dosen Teknik Informatika telah lolos verifikasi KaProdi.',
      tipe: 'success',
      timestamp: DateTime(2026, 9, 10, 14, 0),
      isRead: true,
    ),
    NotificationModel(
      id: 'NOTIF_DKN001',
      judul: 'Ajuan Menunggu Persetujuan Dekan',
      pesan: 'Terdapat 15 ajuan pengajaran yang sudah diverifikasi KaProdi dan menunggu persetujuan Dekan FST.',
      tipe: 'info',
      timestamp: DateTime(2026, 9, 10, 9, 0),
    ),
    NotificationModel(
      id: 'NOTIF_DKN002',
      judul: 'Approval Dekan FST Selesai',
      pesan: 'Pengesahan alokasi gedung dan jadwal ruang perkuliahan Fakultas Sains & Teknologi telah ditandatangani digital.',
      tipe: 'success',
      timestamp: DateTime(2026, 9, 11, 10, 30),
      isRead: true,
    ),
    NotificationModel(
      id: 'NOTIF_ADM001',
      judul: 'Smart CSP Backtracking Selesai',
      pesan: 'Penyusunan jadwal otomatis 1 semester (24 mata kuliah, 19 ruangan) berhasil diselesaikan dengan 0 bentrok.',
      tipe: 'success',
      timestamp: DateTime(2026, 9, 11, 15, 0),
    ),
    NotificationModel(
      id: 'NOTIF_ADM002',
      judul: 'Jadwal Resmi Dipublikasikan',
      pesan: 'Seluruh jadwal perkuliahan 1 semester telah diverifikasi KaProdi, disetujui Dekan, dan berhasil dipublikasikan.',
      tipe: 'success',
      timestamp: DateTime(2026, 9, 12, 8, 0),
    ),
    NotificationModel(
      id: 'NOTIF_ADM003',
      judul: 'Perubahan Ruangan Disetujui',
      pesan: 'Permintaan perubahan ruangan untuk mata kuliah Struktur Data & Algoritma telah disetujui.',
      tipe: 'approval',
      timestamp: DateTime(2026, 9, 11, 11, 0),
    ),
    NotificationModel(
      id: 'NOTIF_GLOBAL',
      judul: 'Pengumuman Akademik',
      pesan: 'Semester Ganjil 2026/2027 resmi dimulai. Seluruh jadwal perkuliahan telah terpublikasi dan dapat diakses melalui aplikasi.',
      tipe: 'jadwal_published',
      timestamp: DateTime(2026, 9, 12, 7, 0),
    ),
  ];

  static const Map<String, List<String>> userNotifIds = {
    'DSN001': ['NOTIF001', 'NOTIF002', 'NOTIF003', 'NOTIF004', 'NOTIF005', 'NOTIF006', 'NOTIF_GLOBAL'],
    'DSN002': ['NOTIF001', 'NOTIF002', 'NOTIF004', 'NOTIF006', 'NOTIF_GLOBAL'],
    'DSN003': ['NOTIF001', 'NOTIF004', 'NOTIF006', 'NOTIF_GLOBAL'],
    'KJR001': ['NOTIF_KJR001', 'NOTIF_KJR002', 'NOTIF001', 'NOTIF004', 'NOTIF_GLOBAL'],
    'DKN001': ['NOTIF_DKN001', 'NOTIF_DKN002', 'NOTIF_GLOBAL'],
    'ADM001': ['NOTIF_ADM001', 'NOTIF_ADM002', 'NOTIF_ADM003', 'NOTIF001', 'NOTIF004', 'NOTIF_GLOBAL'],
    'ADM002': ['NOTIF_ADM001', 'NOTIF_ADM002', 'NOTIF_ADM003', 'NOTIF001', 'NOTIF004', 'NOTIF_GLOBAL'],
  };

  // ── Teaching Proposals (Ajuan Pengajaran Multi-Tier) ──
  static final List<AjuanPengajaranModel> ajuanPengajaranList = [
    AjuanPengajaranModel(
      id: 'AJU001',
      dosenId: 'DSN001',
      dosenNama: 'Dr. Ahmad Fauzi, M.Kom.',
      fakultasNama: 'Fakultas Sains & Teknologi',
      jurusanNama: 'Teknik Informatika',
      mataKuliahId: 'IF101',
      mataKuliahNama: 'Algoritma & Pemrograman',
      sks: 3,
      hari: 'Senin',
      jamMulai: '08:00',
      jamSelesai: '10:30',
      gedungNama: 'Gedung Saintek',
      ruanganNama: 'Ruang 101',
      semester: 1,
      kelasNama: 'TI-1A',
      jumlahMahasiswa: 35,
      status: 'disetujui_dekan',
      catatanDosen: 'Kebutuhan ruang kuliah teori.',
      submittedAt: DateTime(2026, 9, 8, 9, 30),
    ),
    AjuanPengajaranModel(
      id: 'AJU002',
      dosenId: 'DSN002',
      dosenNama: 'Siti Nurhaliza, S.T., M.T.',
      fakultasNama: 'Fakultas Sains & Teknologi',
      jurusanNama: 'Teknik Informatika',
      mataKuliahId: 'IF302',
      mataKuliahNama: 'Kecerdasan Buatan (AI)',
      sks: 3,
      hari: 'Selasa',
      jamMulai: '09:50',
      jamSelesai: '12:20',
      gedungNama: 'Gedung Saintek',
      ruanganNama: 'Lab RPL',
      semester: 3,
      kelasNama: 'TI-3A',
      jumlahMahasiswa: 40,
      status: 'disetujui_dekan',
      catatanDosen: 'Kebutuhan lab komputer praktikum AI.',
      submittedAt: DateTime(2026, 9, 8, 10, 15),
    ),
  ];

  // ── Jadwal Final Personal Demo (Untuk Dosen DSN001) ──
  static final List<JadwalModel> jadwalFinal = [
    const JadwalModel(
      id: 'JDW001',
      mataKuliahId: 'IF101',
      mataKuliahNama: 'Algoritma & Pemrograman',
      sks: 3,
      ruanganNama: 'Ruang 101',
      gedungNama: 'Gedung Saintek',
      kelasNama: 'TI-1A',
      hari: 'Senin',
      jamMulai: '08:00',
      jamSelesai: '10:30',
      semesterNama: 'Ganjil 2026/2027',
      jumlahMahasiswa: 35,
      dosenId: 'DSN001',
      dosenNama: 'Dr. Ahmad Fauzi, M.Kom.',
      fakultasNama: 'Fakultas Sains & Teknologi',
      jurusanNama: 'Teknik Informatika',
    ),
    const JadwalModel(
      id: 'JDW002',
      mataKuliahId: 'IF302',
      mataKuliahNama: 'Kecerdasan Buatan (AI)',
      sks: 3,
      ruanganNama: 'Lab RPL',
      gedungNama: 'Gedung Saintek',
      kelasNama: 'TI-3A',
      hari: 'Selasa',
      jamMulai: '09:50',
      jamSelesai: '12:20',
      semesterNama: 'Ganjil 2026/2027',
      jumlahMahasiswa: 40,
      dosenId: 'DSN002',
      dosenNama: 'Siti Nurhaliza, S.T., M.T.',
      fakultasNama: 'Fakultas Sains & Teknologi',
      jurusanNama: 'Teknik Informatika',
    ),
  ];

  // ── Jadwal Master Global Institusi ──
  static final List<JadwalModel> jadwalGlobalMaster = [
    const JadwalModel(
      id: 'JDW-G01',
      mataKuliahId: 'IF101',
      mataKuliahNama: 'Algoritma & Pemrograman',
      sks: 3,
      ruanganNama: 'Ruang 101',
      gedungNama: 'Gedung Saintek',
      kelasNama: 'TI-1A',
      hari: 'Senin',
      jamMulai: '08:00',
      jamSelesai: '10:30',
      semesterNama: 'Ganjil 2026/2027',
      jumlahMahasiswa: 35,
      dosenId: 'DSN001',
      dosenNama: 'Dr. Ahmad Fauzi, M.Kom.',
      fakultasNama: 'Fakultas Sains & Teknologi',
      jurusanNama: 'Teknik Informatika',
    ),
    const JadwalModel(
      id: 'JDW-G02',
      mataKuliahId: 'IF302',
      mataKuliahNama: 'Kecerdasan Buatan (AI)',
      sks: 3,
      ruanganNama: 'Lab RPL',
      gedungNama: 'Gedung Saintek',
      kelasNama: 'TI-3A',
      hari: 'Selasa',
      jamMulai: '09:50',
      jamSelesai: '12:20',
      semesterNama: 'Ganjil 2026/2027',
      jumlahMahasiswa: 40,
      dosenId: 'DSN002',
      dosenNama: 'Siti Nurhaliza, S.T., M.T.',
      fakultasNama: 'Fakultas Sains & Teknologi',
      jurusanNama: 'Teknik Informatika',
    ),
    const JadwalModel(
      id: 'JDW-G03',
      mataKuliahId: 'SI201',
      mataKuliahNama: 'Basis Data Lanjut',
      sks: 3,
      ruanganNama: 'Ruang 101',
      gedungNama: 'Gedung Saintek',
      kelasNama: 'SI-3A',
      hari: 'Rabu',
      jamMulai: '13:00',
      jamSelesai: '15:30',
      semesterNama: 'Ganjil 2026/2027',
      jumlahMahasiswa: 38,
      dosenId: 'DSN003',
      dosenNama: 'Prof. Budi Santoso, Ph.D.',
      fakultasNama: 'Fakultas Sains & Teknologi',
      jurusanNama: 'Sistem Informasi',
    ),
  ];

  // ── Active OTP and Passwords ──
  static final Map<String, String> activeOtps = {};
  static final Map<String, String> userPasswords = {
    'adm001': 'admin123',
    'admin@uin-malang.ac.id': 'admin123',
    'dek001': 'dekan123',
    'dekan.fst@uin-malang.ac.id': 'dekan123',
    'kap001': 'kaprodi123',
    'kaprodi.ti@uin-malang.ac.id': 'kaprodi123',
    'dsn001': 'dosen123',
    'dosen@uin-malang.ac.id': 'dosen123',
    'mhs001': 'mahasiswa123',
    'mahasiswa@uin-malang.ac.id': 'mahasiswa123',
  };

  // ═══════════════════════════════════════════════════════════════════
  // ── CASCADE DELETION ENGINES (Menghapus Data Terkait di Semua Menu) ──
  // ═══════════════════════════════════════════════════════════════════

  /// Cascade delete Gedung beserta Ruangan, Jadwal (Global & Final), dan Ajuan Pengajaran
  static Future<void> cascadeDeleteGedung(String gedungId, [String? gedungNama]) async {
    final g = gedungList.where((item) => item.id == gedungId || (gedungNama != null && item.nama == gedungNama)).firstOrNull;
    final resolvedNama = g?.nama ?? gedungNama ?? '';
    final resolvedId = g?.id ?? gedungId;
    final gLower = resolvedNama.toLowerCase();

    // 0. Catat ke deleted sets agar tidak bangkit kembali saat sync online
    deletedGedungIds.add(resolvedId);
    if (gedungId.isNotEmpty) deletedGedungIds.add(gedungId);
    if (resolvedNama.isNotEmpty) deletedGedungIds.add(resolvedNama);

    // 1. Hapus Gedung
    gedungList.removeWhere((item) => item.id == resolvedId || (resolvedNama.isNotEmpty && item.nama == resolvedNama));

    // 2. Kumpulkan & hapus Ruangan terkait
    final affectedRuangan = ruanganList
        .where((r) => r.gedungId == resolvedId || (resolvedNama.isNotEmpty && r.gedungNama == resolvedNama))
        .toList();
    for (var r in affectedRuangan) {
      deletedRuanganIds.add(r.id);
      deletedRuanganIds.add(r.nama);
    }
    final affectedRuanganNames = affectedRuangan
        .map((r) => r.nama.toLowerCase())
        .toSet();
    ruanganList.removeWhere((r) => r.gedungId == resolvedId || (resolvedNama.isNotEmpty && r.gedungNama == resolvedNama));

    // 3. Hapus dari Jadwal (Jadwal Final & Jadwal Global Master)
    jadwalFinal.removeWhere((j) {
      final matchGedung = resolvedNama.isNotEmpty && (j.gedungNama.toLowerCase() == gLower || j.gedungNama.toLowerCase().contains(gLower));
      final matchRuangan = affectedRuanganNames.contains(j.ruanganNama.toLowerCase());
      return matchGedung || matchRuangan;
    });
    jadwalGlobalMaster.removeWhere((j) {
      final matchGedung = resolvedNama.isNotEmpty && (j.gedungNama.toLowerCase() == gLower || j.gedungNama.toLowerCase().contains(gLower));
      final matchRuangan = affectedRuanganNames.contains(j.ruanganNama.toLowerCase());
      return matchGedung || matchRuangan;
    });

    // 4. Hapus dari Ajuan Pengajaran (RCK, semua status approval)
    ajuanPengajaranList.removeWhere((a) {
      final matchGedung = resolvedNama.isNotEmpty && (a.gedungNama.toLowerCase() == gLower || a.gedungNama.toLowerCase().contains(gLower));
      final matchRuangan = affectedRuanganNames.contains(a.ruanganNama.toLowerCase());
      return matchGedung || matchRuangan;
    });

    // 5. Update relasi Fakultas yang memakai gedung ini
    for (var f in fakultasData) {
      if ((f['gedung'] ?? '').toString().toLowerCase() == gLower) {
        f['gedung'] = 'Belum Ditentukan';
      }
    }

    // Simpan semua cache lokal
    await saveLocalGedung();
    await saveLocalRuangan();
    await saveLocalJadwal();
    await saveLocalAjuan();
    await saveLocalFakultas();
  }

  /// Cascade delete Ruangan beserta Jadwal dan Ajuan Pengajaran
  static Future<void> cascadeDeleteRuangan(String ruanganId, [String? ruanganNama]) async {
    final r = ruanganList.where((item) => item.id == ruanganId || (ruanganNama != null && item.nama == ruanganNama)).firstOrNull;
    final resolvedNama = r?.nama ?? ruanganNama ?? '';
    final resolvedId = r?.id ?? ruanganId;
    final rLower = resolvedNama.toLowerCase();

    // 0. Catat ke deleted sets
    deletedRuanganIds.add(resolvedId);
    if (ruanganId.isNotEmpty) deletedRuanganIds.add(ruanganId);
    if (resolvedNama.isNotEmpty) deletedRuanganIds.add(resolvedNama);

    // 1. Hapus Ruangan
    ruanganList.removeWhere((item) => item.id == resolvedId || (resolvedNama.isNotEmpty && item.nama.toLowerCase() == rLower));

    // 2. Hapus Jadwal
    jadwalFinal.removeWhere((j) => j.ruanganNama.toLowerCase() == rLower);
    jadwalGlobalMaster.removeWhere((j) => j.ruanganNama.toLowerCase() == rLower);

    // 3. Hapus Ajuan
    ajuanPengajaranList.removeWhere((a) => a.ruanganNama.toLowerCase() == rLower);

    await saveLocalRuangan();
    await saveLocalJadwal();
    await saveLocalAjuan();
  }

  /// Cascade delete Fakultas & Prodi beserta Mata Kuliah, Jadwal, dan Ajuan Pengajaran
  static Future<void> cascadeDeleteFakultas(String fakultasId, [String? fakultasNama, List<String>? jurusanList]) async {
    final f = fakultasData.where((item) => (item['id'] ?? item['nama']) == fakultasId || (fakultasNama != null && item['nama'] == fakultasNama)).firstOrNull;
    final resolvedNama = f?['nama']?.toString() ?? fakultasNama ?? '';
    final resolvedId = f?['id']?.toString() ?? fakultasId;
    final rawJur = f?['jurusan'] ?? jurusanList;
    final List<String> resolvedJur = rawJur is List
        ? rawJur.map((e) => e.toString().toLowerCase()).toList()
        : <String>[];
    final fLower = resolvedNama.toLowerCase();

    // 0. Catat ke deleted sets
    deletedFakultasIds.add(resolvedId);
    if (fakultasId.isNotEmpty) deletedFakultasIds.add(fakultasId);
    if (resolvedNama.isNotEmpty) deletedFakultasIds.add(resolvedNama);

    // 1. Hapus Fakultas
    fakultasData.removeWhere((item) => (item['id'] ?? item['nama']) == fakultasId || (resolvedNama.isNotEmpty && item['nama'] == resolvedNama));

    // 2. Hapus Mata Kuliah terkait fakultas/jurusan ini
    matkulData.removeWhere((m) {
      final mFak = (m['fakultas'] ?? '').toString().toLowerCase();
      final mJur = (m['jurusan'] ?? '').toString().toLowerCase();
      final match = (resolvedNama.isNotEmpty && mFak == fLower) || (resolvedJur.isNotEmpty && resolvedJur.contains(mJur));
      if (match) {
        final mkKode = m['kode']?.toString() ?? '';
        final mkNama = m['nama']?.toString() ?? '';
        if (mkKode.isNotEmpty) deletedMatkulIds.add(mkKode);
        if (mkNama.isNotEmpty) deletedMatkulIds.add(mkNama);
      }
      return match;
    });

    // 3. Hapus Jadwal terkait
    jadwalFinal.removeWhere((j) {
      final jFak = (j.fakultasNama ?? '').toLowerCase();
      final jJur = (j.jurusanNama ?? '').toLowerCase();
      return (resolvedNama.isNotEmpty && jFak == fLower) || (resolvedJur.isNotEmpty && resolvedJur.contains(jJur));
    });
    jadwalGlobalMaster.removeWhere((j) {
      final jFak = (j.fakultasNama ?? '').toLowerCase();
      final jJur = (j.jurusanNama ?? '').toLowerCase();
      return (resolvedNama.isNotEmpty && jFak == fLower) || (resolvedJur.isNotEmpty && resolvedJur.contains(jJur));
    });

    // 4. Hapus Ajuan Pengajaran terkait
    ajuanPengajaranList.removeWhere((a) {
      final aFak = a.fakultasNama.toLowerCase();
      final aJur = a.jurusanNama.toLowerCase();
      return (resolvedNama.isNotEmpty && aFak == fLower) || (resolvedJur.isNotEmpty && resolvedJur.contains(aJur));
    });

    // Simpan semua cache lokal
    await saveLocalFakultas();
    await saveLocalMatkul();
    await saveLocalJadwal();
    await saveLocalAjuan();
  }

  /// Cascade delete Mata Kuliah beserta Jadwal dan Ajuan Pengajaran
  static Future<void> cascadeDeleteMatkul(String matkulKode, [String? matkulNama]) async {
    final m = matkulData.where((item) => item['kode'] == matkulKode || (matkulNama != null && item['nama'] == matkulNama)).firstOrNull;
    final resolvedKode = m?['kode']?.toString() ?? matkulKode;
    final resolvedNama = m?['nama']?.toString() ?? matkulNama ?? '';
    final codeLower = resolvedKode.toLowerCase();
    final nameLower = resolvedNama.toLowerCase();

    // 0. Catat ke deleted sets
    deletedMatkulIds.add(resolvedKode);
    if (matkulKode.isNotEmpty) deletedMatkulIds.add(matkulKode);
    if (resolvedNama.isNotEmpty) deletedMatkulIds.add(resolvedNama);

    // 1. Hapus dari list Mata Kuliah
    matkulData.removeWhere((item) => item['kode']?.toString().toLowerCase() == codeLower || (resolvedNama.isNotEmpty && item['nama']?.toString().toLowerCase() == nameLower));
    mataKuliahDSN001.removeWhere((item) => item.id.toLowerCase() == codeLower || (resolvedNama.isNotEmpty && item.nama.toLowerCase() == nameLower));

    // 2. Hapus dari Jadwal Final & Global
    jadwalFinal.removeWhere((j) {
      final matchKode = j.mataKuliahId.toLowerCase() == codeLower;
      final matchNama = resolvedNama.isNotEmpty && (j.mataKuliahNama.toLowerCase() == nameLower || j.mataKuliahNama.toLowerCase().contains(nameLower));
      return matchKode || matchNama;
    });
    jadwalGlobalMaster.removeWhere((j) {
      final matchKode = j.mataKuliahId.toLowerCase() == codeLower;
      final matchNama = resolvedNama.isNotEmpty && (j.mataKuliahNama.toLowerCase() == nameLower || j.mataKuliahNama.toLowerCase().contains(nameLower));
      return matchKode || matchNama;
    });

    // 3. Hapus dari Ajuan Pengajaran
    ajuanPengajaranList.removeWhere((a) {
      final matchKode = a.mataKuliahId.toLowerCase() == codeLower;
      final matchNama = resolvedNama.isNotEmpty && (a.mataKuliahNama.toLowerCase() == nameLower || a.mataKuliahNama.toLowerCase().contains(nameLower));
      return matchKode || matchNama;
    });

    // Simpan semua cache lokal
    await saveLocalMatkul();
    await saveLocalJadwal();
    await saveLocalAjuan();
  }

  /// Cascade delete Dosen beserta Mata Kuliah yang diampu, Jadwal, Ajuan Pengajaran, dan Status Prioritas
  static Future<void> cascadeDeleteDosen(String dosenId, [String? dosenNama, String? email]) async {
    final u = demoUsers.where((user) => user.id == dosenId || (email != null && user.email == email) || (dosenNama != null && user.nama == dosenNama)).firstOrNull;
    final resolvedId = u?.id ?? dosenId;
    final resolvedNama = u?.nama ?? dosenNama ?? '';
    final resolvedEmail = u?.email ?? email ?? '';
    final idLower = resolvedId.toLowerCase();
    final nameLower = resolvedNama.toLowerCase();

    // 0. Catat ke deleted sets
    deletedUserIds.add(resolvedId);
    if (dosenId.isNotEmpty) deletedUserIds.add(dosenId);
    if (resolvedNama.isNotEmpty) deletedUserIds.add(resolvedNama);
    if (resolvedEmail.isNotEmpty) deletedUserIds.add(resolvedEmail);

    // 1. Hapus User & Prioritas
    demoUsers.removeWhere((user) => user.id == resolvedId || (resolvedNama.isNotEmpty && user.nama.toLowerCase() == nameLower));
    priorityDosenIds.remove(resolvedId);

    // 2. Hapus/unassign Mata Kuliah yang diampu dosen ini
    matkulData.removeWhere((m) {
      final mDid = (m['dosenId'] ?? '').toString().toLowerCase();
      final mDosen = (m['dosen'] ?? '').toString().toLowerCase();
      return mDid == idLower || (resolvedNama.isNotEmpty && mDosen.contains(nameLower));
    });

    // 3. Hapus dari Jadwal Final & Global
    jadwalFinal.removeWhere((j) {
      final matchId = (j.dosenId ?? '').toLowerCase() == idLower;
      final matchNama = resolvedNama.isNotEmpty && (j.dosenNama ?? '').toLowerCase().contains(nameLower);
      return matchId || matchNama;
    });
    jadwalGlobalMaster.removeWhere((j) {
      final matchId = (j.dosenId ?? '').toLowerCase() == idLower;
      final matchNama = resolvedNama.isNotEmpty && (j.dosenNama ?? '').toLowerCase().contains(nameLower);
      return matchId || matchNama;
    });

    // 4. Hapus dari Ajuan Pengajaran
    ajuanPengajaranList.removeWhere((a) {
      final matchId = a.dosenId.toLowerCase() == idLower;
      final matchNama = resolvedNama.isNotEmpty && a.dosenNama.toLowerCase().contains(nameLower);
      return matchId || matchNama;
    });

    await saveLocalUsers();
    await saveLocalMatkul();
    await saveLocalJadwal();
    await saveLocalAjuan();
  }
}
