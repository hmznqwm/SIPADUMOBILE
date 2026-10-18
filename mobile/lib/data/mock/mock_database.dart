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

/// Central in-memory & locally-persisted data store for Smart Schedule app.
class MockDatabase {
  static const Duration defaultDelay = Duration(milliseconds: 100);
  static bool _initialized = false;

  // ── Global System State ──
  static bool isSubmissionActive = true;
  static final Set<String> priorityDosenIds = {};

  // ── Deleted IDs Sets (To prevent stale online responses from reviving deleted items) ──
  static final Set<String> deletedGedungIds = {};
  static final Set<String> deletedRuanganIds = {};
  static final Set<String> deletedFakultasIds = {};
  static final Set<String> deletedMatkulIds = {};
  static final Set<String> deletedUserIds = {};
  static final Set<String> deletedAjuanIds = {};
  static final Set<String> deletedJadwalIds = {};

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
      final delAjuan = prefs.getStringList('cached_deleted_ajuan_ids');
      if (delAjuan != null) {
        deletedAjuanIds.clear();
        deletedAjuanIds.addAll(delAjuan);
      }
      final delJadwal = prefs.getStringList('cached_deleted_jadwal_ids');
      if (delJadwal != null) {
        deletedJadwalIds.clear();
        deletedJadwalIds.addAll(delJadwal);
      }

      // 1. Users
      final usersJson = prefs.getString('cached_mock_users');
      if (usersJson != null && usersJson.isNotEmpty) {
        final List list = jsonDecode(usersJson);
        final loaded = list
            .map((u) => UserModel.fromJson(u))
            .where((u) => !deletedUserIds.contains(u.id))
            .toList();
        demoUsers
          ..clear()
          ..addAll(loaded);
      } else {
        demoUsers.removeWhere((u) => deletedUserIds.contains(u.id));
      }

      // 2. Priority Dosen
      final priorityList = prefs.getStringList('cached_priority_dosen_ids');
      if (priorityList != null) {
        priorityDosenIds.clear();
        priorityDosenIds.addAll(
          priorityList.where((id) => !deletedUserIds.contains(id)),
        );
      }

      // 3. Gedung
      // 3. Gedung
      final hasSavedGedung = prefs.containsKey('cached_master_gedung');
      final gedungJson = prefs.getString('cached_master_gedung');
      if (hasSavedGedung) {
        if (gedungJson != null && gedungJson.isNotEmpty) {
          final List list = jsonDecode(gedungJson);
          final loaded = list.map((g) => GedungModel.fromJson(g)).where((g) {
            if (deletedGedungIds.contains(g.id) ||
                deletedGedungIds.contains(g.nama)) {
              return false;
            }
            return true;
          }).toList();
          gedungList
            ..clear()
            ..addAll(loaded);
        } else {
          gedungList.clear();
        }
      }

      // 3b. Ruangan
      final hasSavedRuangan = prefs.containsKey('cached_master_ruangan');
      final ruanganJson = prefs.getString('cached_master_ruangan');
      if (hasSavedRuangan) {
        if (ruanganJson != null && ruanganJson.isNotEmpty) {
          final List list = jsonDecode(ruanganJson);
          final loaded = list.map((r) => RuanganModel.fromJson(r)).where((r) {
            if (deletedRuanganIds.contains(r.id) ||
                deletedRuanganIds.contains(r.nama)) {
              return false;
            }
            if (deletedGedungIds.contains(r.gedungId) ||
                deletedGedungIds.contains(r.gedungNama)) {
              return false;
            }
            return true;
          }).toList();
          ruanganList
            ..clear()
            ..addAll(loaded);
        } else {
          ruanganList.clear();
        }
      }

      // Pastikan data ruangan yang dihapus secara eksplisit dibersihkan
      ruanganList.removeWhere((r) {
        if (deletedRuanganIds.contains(r.id) ||
            deletedRuanganIds.contains(r.nama)) {
          return true;
        }
        if (deletedGedungIds.contains(r.gedungId) ||
            deletedGedungIds.contains(r.gedungNama)) {
          return true;
        }
        return false;
      });

      // 4. Fakultas
      final hasSavedFakultas = prefs.containsKey('cached_master_fakultas');
      final fakultasJson = prefs.getString('cached_master_fakultas');
      if (hasSavedFakultas) {
        if (fakultasJson != null && fakultasJson.isNotEmpty) {
          final List list = jsonDecode(fakultasJson);
          final loaded = list
              .map((f) {
                final map = Map<String, dynamic>.from(f);
                final jurRaw = map['jurusan'];
                if (jurRaw is List) {
                  map['jurusan'] = jurRaw.map((e) => e.toString()).toList();
                } else {
                  map['jurusan'] = <String>[];
                }
                return map;
              })
              .where((f) {
                final fid = f['id']?.toString() ?? '';
                final fnama = f['nama']?.toString() ?? '';
                return !deletedFakultasIds.contains(fid) &&
                    !deletedFakultasIds.contains(fnama);
              })
              .toList();
          fakultasData
            ..clear()
            ..addAll(loaded);
        } else {
          fakultasData.clear();
        }
      }

      // 5. Matkul
      final hasSavedMatkul = prefs.containsKey('cached_master_matkul');
      final matkulJson = prefs.getString('cached_master_matkul');
      if (hasSavedMatkul) {
        if (matkulJson != null && matkulJson.isNotEmpty) {
          final List list = jsonDecode(matkulJson);
          final loaded = list
              .map((m) {
                final map = Map<String, dynamic>.from(m);
                final kelasRaw = map['kelas'];
                if (kelasRaw is List) {
                  map['kelas'] = kelasRaw.map((e) => e.toString()).toList();
                } else {
                  map['kelas'] = <String>['A'];
                }
                return map;
              })
              .where((m) {
                final mkId = (m['id']?.toString() ?? m['kode']?.toString() ?? '')
                    .toLowerCase();
                final mkNama = (m['nama']?.toString() ?? '').toLowerCase();
                return !deletedMatkulIds.contains(mkId) &&
                    !deletedMatkulIds.contains(mkNama);
              })
              .toList();
          matkulData
            ..clear()
            ..addAll(loaded);
        } else {
          matkulData.clear();
        }
      }

      // 6. Ajuan Pengajaran
      final hasSavedAjuan = prefs.containsKey('cached_ajuan_pengajaran');
      final ajuanJson = prefs.getString('cached_ajuan_pengajaran');
      if (hasSavedAjuan) {
        if (ajuanJson != null && ajuanJson.isNotEmpty) {
          final List list = jsonDecode(ajuanJson);
          final loaded = list.map((a) => AjuanPengajaranModel.fromJson(a)).where((
            a,
          ) {
            if (deletedAjuanIds.contains(a.id)) return false;
            if (deletedGedungIds.contains(a.gedungNama) ||
                deletedRuanganIds.contains(a.ruanganNama) ||
                deletedMatkulIds.contains(a.mataKuliahId) ||
                deletedMatkulIds.contains(a.mataKuliahNama) ||
                deletedUserIds.contains(a.dosenId) ||
                deletedUserIds.contains(a.dosenNama) ||
                deletedFakultasIds.contains(a.fakultasNama)) {
              return false;
            }
            return true;
          }).toList();
          ajuanPengajaranList
            ..clear()
            ..addAll(loaded);
        } else {
          ajuanPengajaranList.clear();
        }
      }

      // 7. Jadwal Final
      final hasSavedJadwal = prefs.containsKey('cached_jadwal_final');
      final jadwalJson = prefs.getString('cached_jadwal_final');
      if (hasSavedJadwal) {
        if (jadwalJson != null && jadwalJson.isNotEmpty) {
          final List list = jsonDecode(jadwalJson);
          final loaded = list.map((j) => JadwalModel.fromJson(j)).where((j) {
            if (deletedJadwalIds.contains(j.id)) return false;
            if (deletedGedungIds.contains(j.gedungNama) ||
                deletedRuanganIds.contains(j.ruanganNama) ||
                deletedMatkulIds.contains(j.mataKuliahId) ||
                deletedMatkulIds.contains(j.mataKuliahNama) ||
                deletedUserIds.contains(j.dosenId) ||
                deletedUserIds.contains(j.dosenNama) ||
                deletedFakultasIds.contains(j.fakultasNama)) {
              return false;
            }
            return true;
          }).toList();
          jadwalFinal
            ..clear()
            ..addAll(loaded);
          jadwalGlobalMaster
            ..clear()
            ..addAll(loaded);
        } else {
          jadwalFinal.clear();
          jadwalGlobalMaster.clear();
        }
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

  /// Helper: Check relational validity against active Master Data
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
    if (gedungList.isEmpty ||
        ruanganList.isEmpty ||
        matkulData.isEmpty ||
        demoUsers.isEmpty) {
      return true; // Don't purge when master lists are being populated dynamically
    }

    final gId = (gedungId ?? '').trim().toLowerCase();
    final gNama = (gedungNama ?? '').trim().toLowerCase();
    final rId = (ruanganId ?? '').trim().toLowerCase();
    final rNama = (ruanganNama ?? '').trim().toLowerCase();

    // Virtual / Daring / RTI Room Bypass
    final isVirtual =
        gNama.contains('virtual') ||
        gNama.contains('daring') ||
        rNama.contains('rti') ||
        rNama.contains('daring');

    if (!isVirtual) {
      final gMatch = gedungList.any((g) {
        final gGedungId = g.id.trim().toLowerCase();
        final gGedungNama = g.nama.trim().toLowerCase();
        if (gId.isNotEmpty && gGedungId == gId) return true;
        if (gNama.isNotEmpty &&
            (gGedungNama == gNama ||
                gNama.contains(gGedungNama) ||
                gGedungNama.contains(gNama))) {
          return true;
        }
        return false;
      });
      if (!gMatch) return false;

      final rMatch = ruanganList.any((r) {
        final rRuanganId = r.id.trim().toLowerCase();
        final rRuanganNama = r.nama.trim().toLowerCase();
        if (rId.isNotEmpty && rRuanganId == rId) return true;
        if (rNama.isNotEmpty &&
            (rRuanganNama == rNama ||
                rNama.contains(rRuanganNama) ||
                rRuanganNama.contains(rNama))) {
          return true;
        }
        return false;
      });
      if (!rMatch) return false;
    }

    final mId = (matkulId ?? '').trim().toLowerCase();
    final mNama = (matkulNama ?? '').trim().toLowerCase();

    final mMatch = matkulData.any((m) {
      final mKode = (m['kode'] ?? m['id'] ?? '')
          .toString()
          .trim()
          .toLowerCase();
      final mMataKuliahNama = (m['nama'] ?? '').toString().trim().toLowerCase();
      if (mId.isNotEmpty && mKode == mId) return true;
      if (mNama.isNotEmpty &&
          (mMataKuliahNama == mNama ||
              mNama.contains(mMataKuliahNama) ||
              mMataKuliahNama.contains(mNama))) {
        return true;
      }
      return false;
    });
    if (!mMatch) return false;

    final uId = (dosenId ?? '').trim().toLowerCase();
    final uNama = (dosenNama ?? '').trim().toLowerCase();

    final uMatch = demoUsers.any((u) {
      final uUserId = u.id.trim().toLowerCase();
      final uUserNama = u.nama.trim().toLowerCase();
      if (uId.isNotEmpty && uUserId == uId) return true;
      if (uNama.isNotEmpty &&
          (uUserNama == uNama ||
              uNama.contains(uUserNama) ||
              uUserNama.contains(uNama))) {
        return true;
      }
      return false;
    });
    if (!uMatch) return false;

    return true;
  }

  /// Strict Relational Integrity: Purge any schedule whose Gedung, Ruangan, Matkul, or Dosen is missing
  static void purgeInvalidSchedules() {
    if (gedungList.isEmpty ||
        ruanganList.isEmpty ||
        matkulData.isEmpty ||
        demoUsers.isEmpty) {
      return;
    }

    ajuanPengajaranList.removeWhere(
      (a) => !isRelationalValidItem(
        gedungNama: a.gedungNama,
        ruanganNama: a.ruanganNama,
        matkulId: a.mataKuliahId,
        matkulNama: a.mataKuliahNama,
        dosenId: a.dosenId,
        dosenNama: a.dosenNama,
      ),
    );

    jadwalFinal.removeWhere((j) {
      final isValidRelation = isRelationalValidItem(
        gedungId: j.gedungId,
        gedungNama: j.gedungNama,
        ruanganId: j.ruanganId,
        ruanganNama: j.ruanganNama,
        matkulId: j.mataKuliahId,
        matkulNama: j.mataKuliahNama,
        dosenId: j.dosenId,
        dosenNama: j.dosenNama,
      );
      return !isValidRelation;
    });

    jadwalGlobalMaster.removeWhere((j) {
      final isValidRelation = isRelationalValidItem(
        gedungId: j.gedungId,
        gedungNama: j.gedungNama,
        ruanganId: j.ruanganId,
        ruanganNama: j.ruanganNama,
        matkulId: j.mataKuliahId,
        matkulNama: j.mataKuliahNama,
        dosenId: j.dosenId,
        dosenNama: j.dosenNama,
      );
      return !isValidRelation;
    });
  }

  static Future<void> saveLocalDeletedIds() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setStringList(
        'cached_deleted_gedung_ids',
        deletedGedungIds.toList(),
      );
      await prefs.setStringList(
        'cached_deleted_ruangan_ids',
        deletedRuanganIds.toList(),
      );
      await prefs.setStringList(
        'cached_deleted_fakultas_ids',
        deletedFakultasIds.toList(),
      );
      await prefs.setStringList(
        'cached_deleted_matkul_ids',
        deletedMatkulIds.toList(),
      );
      await prefs.setStringList(
        'cached_deleted_user_ids',
        deletedUserIds.toList(),
      );
      await prefs.setStringList(
        'cached_deleted_ajuan_ids',
        deletedAjuanIds.toList(),
      );
      await prefs.setStringList(
        'cached_deleted_jadwal_ids',
        deletedJadwalIds.toList(),
      );
    } catch (_) {}
  }

  static Future<void> saveLocalUsers() async {
    try {
      await saveLocalDeletedIds();
      final prefs = await SharedPreferences.getInstance();
      final usersData = demoUsers.map((u) => u.toJson()).toList();
      await prefs.setString('cached_mock_users', jsonEncode(usersData));
      await prefs.setStringList(
        'cached_priority_dosen_ids',
        priorityDosenIds.toList(),
      );
    } catch (_) {}
  }

  static Future<void> saveLocalGedung() async {
    try {
      await saveLocalDeletedIds();
      final prefs = await SharedPreferences.getInstance();
      final data = gedungList.map((g) => g.toJson()).toList();
      await prefs.setString('cached_master_gedung', jsonEncode(data));
    } catch (_) {}
  }

  static Future<void> saveLocalRuangan() async {
    try {
      await saveLocalDeletedIds();
      final prefs = await SharedPreferences.getInstance();
      final data = ruanganList.map((r) => r.toJson()).toList();
      await prefs.setString('cached_master_ruangan', jsonEncode(data));
    } catch (_) {}
  }

  static Future<void> saveLocalFakultas() async {
    try {
      await saveLocalDeletedIds();
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('cached_master_fakultas', jsonEncode(fakultasData));
    } catch (_) {}
  }

  static Future<void> saveLocalMatkul() async {
    try {
      await saveLocalDeletedIds();
      final prefs = await SharedPreferences.getInstance();
      final data = matkulData.map((m) => m).toList();
      await prefs.setString('cached_master_matkul', jsonEncode(data));
    } catch (_) {}
  }

  static Future<void> saveLocalAjuan() async {
    try {
      await saveLocalDeletedIds();
      final prefs = await SharedPreferences.getInstance();
      final data = ajuanPengajaranList.map((a) => a.toJson()).toList();
      await prefs.setString('cached_ajuan_pengajaran', jsonEncode(data));
    } catch (_) {}
  }

  static Future<void> saveLocalJadwal() async {
    try {
      await saveLocalDeletedIds();
      final prefs = await SharedPreferences.getInstance();
      final data = jadwalGlobalMaster.map((j) => j.toJson()).toList();
      await prefs.setString('cached_jadwal_final', jsonEncode(data));
    } catch (_) {}
  }

  // ── Multi-Tier Submission Approvals State ──
  static final Map<String, String> dosenSubmissionStatus = {};

  // ── Users ──
  static final List<UserModel> demoUsers = [];

  // ── Master Data Gedung ──
  static final List<GedungModel> gedungList = [];

  // ── Master Data Ruangan ──
  static final List<RuanganModel> ruanganList = [];

  // ── Master Data Fakultas & Prodi ──
  static final List<Map<String, dynamic>> fakultasData = [];

  // ── Master Data Mata Kuliah & Kelas ──
  static final List<Map<String, dynamic>> matkulData = [];

  // ── Slot Waktu (Standard Matrix Grid) ──
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
        allSlots.add(
          SlotWaktuModel(
            id: 'SLOT${counter.toString().padLeft(3, '0')}',
            hari: day,
            jamMulai: slot.$1,
            jamSelesai: slot.$2,
            durasiMenit: 50,
          ),
        );
      }
      for (final slot in standardSlots) {
        counter++;
        allSlots.add(
          SlotWaktuModel(
            id: 'SLOT${counter.toString().padLeft(3, '0')}',
            hari: day,
            jamMulai: slot.$1,
            jamSelesai: slot.$2,
            durasiMenit: 50,
          ),
        );
      }
    }
    return allSlots;
  }

  // ── Mata Kuliah List ──
  static final List<MataKuliahModel> mataKuliahDSN001 = [];

  // ── In-Memory Availability State ──
  static AvailabilityModel? currentAvailability;
  static final List<AvailabilityHistoryItem> availabilityHistory = [];

  // ── Notifications ──
  static final List<NotificationModel> notifications = [];
  static const Map<String, List<String>> userNotifIds = {};

  // ── Teaching Proposals (Ajuan Pengajaran Multi-Tier) ──
  static final List<AjuanPengajaranModel> ajuanPengajaranList = [];

  // ── Jadwal Final Personal ──
  static final List<JadwalModel> jadwalFinal = [];

  // ── Jadwal Master Global Institusi ──
  static final List<JadwalModel> jadwalGlobalMaster = [];

  // ── Active OTP and Passwords ──
  static final Map<String, String> activeOtps = {};
  static final Map<String, String> userPasswords = {};

  // ═══════════════════════════════════════════════════════════════════
  // ── CASCADE DELETION ENGINES (Menghapus Data Terkait di Semua Menu) ──
  // ═══════════════════════════════════════════════════════════════════

  /// Cascade delete Gedung beserta Ruangan, Jadwal (Global & Final), dan Ajuan Pengajaran
  static Future<void> cascadeDeleteGedung(
    String gedungId, [
    String? gedungNama,
  ]) async {
    final g = gedungList
        .where(
          (item) =>
              item.id == gedungId ||
              (gedungNama != null && item.nama == gedungNama),
        )
        .firstOrNull;
    final resolvedNama = g?.nama ?? gedungNama ?? '';
    final resolvedId = g?.id ?? gedungId;
    final gLower = resolvedNama.toLowerCase();

    // 0. Catat ke deleted sets agar tidak bangkit kembali saat sync online
    deletedGedungIds.add(resolvedId);
    if (gedungId.isNotEmpty) deletedGedungIds.add(gedungId);
    if (resolvedNama.isNotEmpty) deletedGedungIds.add(resolvedNama);

    // 1. Hapus Gedung
    gedungList.removeWhere(
      (item) =>
          item.id == resolvedId ||
          (resolvedNama.isNotEmpty && item.nama == resolvedNama),
    );

    // 2. Kumpulkan & hapus Ruangan terkait
    final affectedRuangan = ruanganList
        .where(
          (r) =>
              r.gedungId == resolvedId ||
              (resolvedNama.isNotEmpty && r.gedungNama == resolvedNama),
        )
        .toList();
    for (var r in affectedRuangan) {
      deletedRuanganIds.add(r.id);
      deletedRuanganIds.add(r.nama);
    }
    final affectedRuanganNames = affectedRuangan
        .map((r) => r.nama.toLowerCase())
        .toSet();
    ruanganList.removeWhere(
      (r) =>
          r.gedungId == resolvedId ||
          (resolvedNama.isNotEmpty && r.gedungNama == resolvedNama),
    );

    // 3. Hapus dari Jadwal (Jadwal Final & Jadwal Global Master)
    jadwalFinal.removeWhere((j) {
      final matchGedung =
          resolvedNama.isNotEmpty &&
          (j.gedungNama.toLowerCase() == gLower ||
              j.gedungNama.toLowerCase().contains(gLower));
      final matchRuangan = affectedRuanganNames.contains(
        j.ruanganNama.toLowerCase(),
      );
      return matchGedung || matchRuangan;
    });
    jadwalGlobalMaster.removeWhere((j) {
      final matchGedung =
          resolvedNama.isNotEmpty &&
          (j.gedungNama.toLowerCase() == gLower ||
              j.gedungNama.toLowerCase().contains(gLower));
      final matchRuangan = affectedRuanganNames.contains(
        j.ruanganNama.toLowerCase(),
      );
      return matchGedung || matchRuangan;
    });

    // 4. Hapus dari Ajuan Pengajaran (RCK, semua status approval)
    ajuanPengajaranList.removeWhere((a) {
      final matchGedung =
          resolvedNama.isNotEmpty &&
          (a.gedungNama.toLowerCase() == gLower ||
              a.gedungNama.toLowerCase().contains(gLower));
      final matchRuangan = affectedRuanganNames.contains(
        a.ruanganNama.toLowerCase(),
      );
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
  static Future<void> cascadeDeleteRuangan(
    String ruanganId, [
    String? ruanganNama,
  ]) async {
    final r = ruanganList
        .where(
          (item) =>
              item.id == ruanganId ||
              (ruanganNama != null && item.nama == ruanganNama),
        )
        .firstOrNull;
    final resolvedNama = r?.nama ?? ruanganNama ?? '';
    final resolvedId = r?.id ?? ruanganId;
    final rLower = resolvedNama.toLowerCase();

    // 0. Catat ke deleted sets
    deletedRuanganIds.add(resolvedId);
    if (ruanganId.isNotEmpty) deletedRuanganIds.add(ruanganId);
    if (resolvedNama.isNotEmpty) deletedRuanganIds.add(resolvedNama);

    // 1. Hapus Ruangan
    ruanganList.removeWhere(
      (item) =>
          item.id == resolvedId ||
          (resolvedNama.isNotEmpty && item.nama.toLowerCase() == rLower),
    );

    // 2. Hapus Jadwal
    jadwalFinal.removeWhere((j) => j.ruanganNama.toLowerCase() == rLower);
    jadwalGlobalMaster.removeWhere(
      (j) => j.ruanganNama.toLowerCase() == rLower,
    );

    // 3. Hapus Ajuan
    ajuanPengajaranList.removeWhere(
      (a) => a.ruanganNama.toLowerCase() == rLower,
    );

    await saveLocalRuangan();
    await saveLocalJadwal();
    await saveLocalAjuan();
  }

  /// Cascade delete Fakultas & Prodi beserta Mata Kuliah, Jadwal, dan Ajuan Pengajaran
  static Future<void> cascadeDeleteFakultas(
    String fakultasId, [
    String? fakultasNama,
    List<String>? jurusanList,
  ]) async {
    final f = fakultasData
        .where(
          (item) =>
              (item['id'] ?? item['nama']) == fakultasId ||
              (fakultasNama != null && item['nama'] == fakultasNama),
        )
        .firstOrNull;
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
    fakultasData.removeWhere(
      (item) =>
          (item['id'] ?? item['nama']) == fakultasId ||
          (resolvedNama.isNotEmpty && item['nama'] == resolvedNama),
    );

    // 2. Hapus Mata Kuliah terkait fakultas/jurusan ini
    matkulData.removeWhere((m) {
      final mFak = (m['fakultas'] ?? '').toString().toLowerCase();
      final mJur = (m['jurusan'] ?? '').toString().toLowerCase();
      final match =
          (resolvedNama.isNotEmpty && mFak == fLower) ||
          (resolvedJur.isNotEmpty && resolvedJur.contains(mJur));
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
      return (resolvedNama.isNotEmpty && jFak == fLower) ||
          (resolvedJur.isNotEmpty && resolvedJur.contains(jJur));
    });
    jadwalGlobalMaster.removeWhere((j) {
      final jFak = (j.fakultasNama ?? '').toLowerCase();
      final jJur = (j.jurusanNama ?? '').toLowerCase();
      return (resolvedNama.isNotEmpty && jFak == fLower) ||
          (resolvedJur.isNotEmpty && resolvedJur.contains(jJur));
    });

    // 4. Hapus Ajuan Pengajaran terkait
    ajuanPengajaranList.removeWhere((a) {
      final aFak = a.fakultasNama.toLowerCase();
      final aJur = a.jurusanNama.toLowerCase();
      return (resolvedNama.isNotEmpty && aFak == fLower) ||
          (resolvedJur.isNotEmpty && resolvedJur.contains(aJur));
    });

    // Simpan semua cache lokal
    await saveLocalFakultas();
    await saveLocalMatkul();
    await saveLocalJadwal();
    await saveLocalAjuan();
  }

  /// Cascade delete Mata Kuliah beserta Jadwal dan Ajuan Pengajaran
  static Future<void> cascadeDeleteMatkul(
    String matkulKode, [
    String? matkulNama,
  ]) async {
    final m = matkulData
        .where(
          (item) =>
              item['kode'] == matkulKode ||
              (matkulNama != null && item['nama'] == matkulNama),
        )
        .firstOrNull;
    final resolvedKode = m?['kode']?.toString() ?? matkulKode;
    final resolvedNama = m?['nama']?.toString() ?? matkulNama ?? '';
    final codeLower = resolvedKode.toLowerCase();
    final nameLower = resolvedNama.toLowerCase();

    // 0. Catat ke deleted sets
    deletedMatkulIds.add(resolvedKode);
    if (matkulKode.isNotEmpty) deletedMatkulIds.add(matkulKode);
    if (resolvedNama.isNotEmpty) deletedMatkulIds.add(resolvedNama);

    // 1. Hapus dari list Mata Kuliah
    matkulData.removeWhere(
      (item) =>
          item['kode']?.toString().toLowerCase() == codeLower ||
          (resolvedNama.isNotEmpty &&
              item['nama']?.toString().toLowerCase() == nameLower),
    );
    mataKuliahDSN001.removeWhere(
      (item) =>
          item.id.toLowerCase() == codeLower ||
          (resolvedNama.isNotEmpty && item.nama.toLowerCase() == nameLower),
    );

    // 2. Hapus dari Jadwal Final & Global
    jadwalFinal.removeWhere((j) {
      final matchKode = j.mataKuliahId.toLowerCase() == codeLower;
      final matchNama =
          resolvedNama.isNotEmpty &&
          (j.mataKuliahNama.toLowerCase() == nameLower ||
              j.mataKuliahNama.toLowerCase().contains(nameLower));
      return matchKode || matchNama;
    });
    jadwalGlobalMaster.removeWhere((j) {
      final matchKode = j.mataKuliahId.toLowerCase() == codeLower;
      final matchNama =
          resolvedNama.isNotEmpty &&
          (j.mataKuliahNama.toLowerCase() == nameLower ||
              j.mataKuliahNama.toLowerCase().contains(nameLower));
      return matchKode || matchNama;
    });

    // 3. Hapus dari Ajuan Pengajaran
    ajuanPengajaranList.removeWhere((a) {
      final matchKode = a.mataKuliahId.toLowerCase() == codeLower;
      final matchNama =
          resolvedNama.isNotEmpty &&
          (a.mataKuliahNama.toLowerCase() == nameLower ||
              a.mataKuliahNama.toLowerCase().contains(nameLower));
      return matchKode || matchNama;
    });

    // Simpan semua cache lokal
    await saveLocalMatkul();
    await saveLocalJadwal();
    await saveLocalAjuan();
  }

  /// Cascade delete Dosen beserta Mata Kuliah yang diampu, Jadwal, Ajuan Pengajaran, dan Status Prioritas
  static Future<void> cascadeDeleteDosen(
    String dosenId, [
    String? dosenNama,
    String? email,
  ]) async {
    final u = demoUsers
        .where(
          (user) =>
              user.id == dosenId ||
              (email != null && user.email == email) ||
              (dosenNama != null && user.nama == dosenNama),
        )
        .firstOrNull;
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
    demoUsers.removeWhere(
      (user) =>
          user.id == resolvedId ||
          (resolvedNama.isNotEmpty && user.nama.toLowerCase() == nameLower),
    );
    priorityDosenIds.remove(resolvedId);

    // 2. Hapus/unassign Mata Kuliah yang diampu dosen ini
    matkulData.removeWhere((m) {
      final mDid = (m['dosenId'] ?? '').toString().toLowerCase();
      final mDosen = (m['dosen'] ?? '').toString().toLowerCase();
      return mDid == idLower ||
          (resolvedNama.isNotEmpty && mDosen.contains(nameLower));
    });

    // 3. Hapus dari Jadwal Final & Global
    jadwalFinal.removeWhere((j) {
      final matchId = (j.dosenId ?? '').toLowerCase() == idLower;
      final matchNama =
          resolvedNama.isNotEmpty &&
          (j.dosenNama ?? '').toLowerCase().contains(nameLower);
      return matchId || matchNama;
    });
    jadwalGlobalMaster.removeWhere((j) {
      final matchId = (j.dosenId ?? '').toLowerCase() == idLower;
      final matchNama =
          resolvedNama.isNotEmpty &&
          (j.dosenNama ?? '').toLowerCase().contains(nameLower);
      return matchId || matchNama;
    });

    // 4. Hapus dari Ajuan Pengajaran
    ajuanPengajaranList.removeWhere((a) {
      final matchId = a.dosenId.toLowerCase() == idLower;
      final matchNama =
          resolvedNama.isNotEmpty &&
          a.dosenNama.toLowerCase().contains(nameLower);
      return matchId || matchNama;
    });

    await saveLocalUsers();
    await saveLocalMatkul();
    await saveLocalJadwal();
    await saveLocalAjuan();
  }
}
