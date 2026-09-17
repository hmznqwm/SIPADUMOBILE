import '../../../config/api_config.dart';
import '../../models/user_model.dart';
import '../../models/mata_kuliah_model.dart';
import '../../models/slot_waktu_model.dart';
import '../../models/gedung_model.dart';
import '../../models/ruangan_model.dart';
import '../../mock/mock_database.dart';
import 'api_http_helper.dart';

class MasterDataApiService {
  final ApiHttpHelper _httpHelper;

  MasterDataApiService({ApiHttpHelper? httpHelper})
      : _httpHelper = httpHelper ?? ApiHttpHelper();

  /// GET /api/master/mata_kuliah.php
  Future<List<MataKuliahModel>> getMataKuliah(String dosenId) async {
    if (!ApiConfig.useMockBackend) {
      try {
        final data = await _httpHelper.makeOnlineRequest('/master/mata_kuliah.php?dosen_id=$dosenId&dosenId=$dosenId');
        if (data is Map && data['status'] == 'success' && data['data'] != null) {
          final list = (data['data'] as List).map((mk) => MataKuliahModel.fromJson(mk)).toList();
          if (list.isNotEmpty) return list;
        }
      } catch (_) {}
    }

    await Future.delayed(MockDatabase.defaultDelay);
    if (dosenId == 'DSN001') return MockDatabase.mataKuliahDSN001;

    return [
      MataKuliahModel(
        id: 'MK_${dosenId}_01',
        nama: 'Algoritma & Pemrograman Lanjut',
        sks: 3,
        jurusanId: 'JUR001',
        jurusanNama: 'Teknik Informatika',
        fakultasNama: 'Fakultas Sains & Teknologi',
        semesterId: 'SEM001',
        kelasNama: const ['TI-1A', 'TI-1B'],
      ),
      MataKuliahModel(
        id: 'MK_${dosenId}_02',
        nama: 'Basis Data & Rekayasa Informasi',
        sks: 3,
        jurusanId: 'JUR002',
        jurusanNama: 'Sistem Informasi',
        fakultasNama: 'Fakultas Sains & Teknologi',
        semesterId: 'SEM001',
        kelasNama: const ['SI-3A', 'SI-3B'],
      ),
      MataKuliahModel(
        id: 'MK_${dosenId}_03',
        nama: 'Sistem Terdistribusi & Cloud',
        sks: 3,
        jurusanId: 'JUR001',
        jurusanNama: 'Teknik Informatika',
        fakultasNama: 'Fakultas Sains & Teknologi',
        semesterId: 'SEM001',
        kelasNama: const ['TI-5A', 'TI-5B'],
      ),
    ];
  }

  /// GET slot waktu master data
  Future<List<SlotWaktuModel>> getSlotWaktu() async {
    await Future.delayed(const Duration(milliseconds: 150));
    return MockDatabase.slotWaktu;
  }

  /// GET all demo users / lecturers
  Future<List<UserModel>> getAllUsers() async {
    await MockDatabase.initLocalCache();
    if (!ApiConfig.useMockBackend) {
      try {
        final data = await _httpHelper.makeOnlineRequest('/master/users.php');
        if (data is Map && data['status'] == 'success' && data['data'] != null) {
          final list = (data['data'] as List).map((u) => UserModel.fromJson(u)).toList();
          if (list.isNotEmpty) {
            MockDatabase.demoUsers.clear();
            MockDatabase.demoUsers.addAll(list);
            await MockDatabase.saveLocalUsers();
            return list;
          }
        }
      } catch (_) {}
    }
    await Future.delayed(const Duration(milliseconds: 150));
    return MockDatabase.demoUsers.map((u) {
      final isPriority = MockDatabase.priorityDosenIds.contains(u.id);
      return u.copyWith(isPriority: isPriority);
    }).toList();
  }

  /// TOGGLE Dosen Priority Flag (MRV Heuristic Priority)
  Future<bool> toggleDosenPriority(String dosenId) async {
    final newPriority = !MockDatabase.priorityDosenIds.contains(dosenId);
    await setDosenPriority(dosenId, newPriority);
    return newPriority;
  }

  Future<void> setDosenPriority(String dosenId, bool priority) async {
    if (priority) {
      MockDatabase.priorityDosenIds.add(dosenId);
    } else {
      MockDatabase.priorityDosenIds.remove(dosenId);
    }
    await MockDatabase.saveLocalUsers();
    if (!ApiConfig.useMockBackend) {
      try {
        await _httpHelper.makeOnlineRequest(
          '/master/users.php',
          method: 'POST',
          body: {'dosenId': dosenId, 'isPriority': priority},
        );
      } catch (_) {}
    }
    await Future.delayed(const Duration(milliseconds: 150));
  }

  /// Create / Register new Dosen with email & login credentials
  Future<UserModel> createDosen(UserModel dosen, {String password = 'password123'}) async {
    MockDatabase.demoUsers.removeWhere((u) => u.id == dosen.id || u.email.toLowerCase() == dosen.email.toLowerCase());
    MockDatabase.demoUsers.add(dosen);
    await MockDatabase.saveLocalUsers();
    if (!ApiConfig.useMockBackend) {
      try {
        final data = await _httpHelper.makeOnlineRequest(
          '/master/users.php',
          method: 'POST',
          body: {
            'action': 'create',
            'id': dosen.id,
            'nidn': dosen.id,
            'nama': dosen.nama,
            'email': dosen.email,
            'password': password,
            'role': dosen.role,
            'jurusan_id': dosen.jurusanId,
            'jurusan_nama': dosen.jurusanNama,
            'fakultas_nama': dosen.fakultasNama,
            'is_priority': dosen.isPriority ? 1 : 0,
          },
        );
        if (data is Map && data['status'] == 'success' && data['data'] != null) {
          final saved = UserModel.fromJson(data['data']);
          MockDatabase.demoUsers.removeWhere((u) => u.id == saved.id);
          MockDatabase.demoUsers.add(saved);
          await MockDatabase.saveLocalUsers();
          return saved;
        }
      } catch (_) {}
    }
    await Future.delayed(const Duration(milliseconds: 150));
    return dosen;
  }

  /// Delete Dosen / User (Cascade)
  Future<void> deleteUser(String userId) async {
    await MockDatabase.cascadeDeleteDosen(userId);
    if (!ApiConfig.useMockBackend) {
      try {
        await _httpHelper.makeOnlineRequest(
          '/master/users.php',
          method: 'POST',
          body: {'action': 'delete', 'id': userId},
        );
      } catch (_) {}
    }
    await Future.delayed(const Duration(milliseconds: 150));
  }

  /// GET Master Data Gedung List
  Future<List<GedungModel>> getGedungList() async {
    await MockDatabase.initLocalCache();
    final filtered = MockDatabase.gedungList.where((g) =>
        !MockDatabase.deletedGedungIds.contains(g.id) &&
        !MockDatabase.deletedGedungIds.contains(g.nama)
    ).toList();
    return List.unmodifiable(filtered);
  }

  /// ADD Master Data Gedung
  Future<GedungModel> addGedung(GedungModel gedung) async {
    MockDatabase.deletedGedungIds.remove(gedung.id);
    MockDatabase.deletedGedungIds.remove(gedung.nama);
    MockDatabase.gedungList.removeWhere((g) => g.id == gedung.id || g.nama == gedung.nama);
    MockDatabase.gedungList.add(gedung);
    await MockDatabase.saveLocalGedung();

    if (!ApiConfig.useMockBackend) {
      try {
        await _httpHelper.makeOnlineRequest(
          '/master/gedung.php',
          method: 'POST',
          body: gedung.toJson(),
        );
      } catch (_) {}
    }
    await Future.delayed(const Duration(milliseconds: 100));
    return gedung;
  }

  /// DELETE Master Data Gedung (Cascade)
  Future<void> deleteGedung(String gedungId) async {
    await MockDatabase.cascadeDeleteGedung(gedungId);
    if (!ApiConfig.useMockBackend) {
      try {
        await _httpHelper.makeOnlineRequest('/master/gedung.php?id=$gedungId', method: 'DELETE');
        await _httpHelper.makeOnlineRequest(
          '/master/gedung.php',
          method: 'POST',
          body: {'action': 'delete', 'id': gedungId},
        );
      } catch (_) {}
    }
    await Future.delayed(const Duration(milliseconds: 100));
  }

  /// GET Master Data Ruangan List
  Future<List<RuanganModel>> getRuanganList() async {
    await MockDatabase.initLocalCache();
    final activeGedungIds = MockDatabase.gedungList.map((g) => g.id.trim()).where((id) => id.isNotEmpty).toSet();
    final activeGedungNames = MockDatabase.gedungList.map((g) => g.nama.trim().toLowerCase()).where((n) => n.isNotEmpty).toSet();

    MockDatabase.ruanganList.removeWhere((r) {
      if (MockDatabase.deletedRuanganIds.contains(r.id) || MockDatabase.deletedRuanganIds.contains(r.nama)) return true;
      if (MockDatabase.deletedGedungIds.contains(r.gedungId) || MockDatabase.deletedGedungIds.contains(r.gedungNama)) return true;

      final matchId = r.gedungId.isNotEmpty && activeGedungIds.contains(r.gedungId.trim());
      final matchNama = r.gedungNama.isNotEmpty && activeGedungNames.contains(r.gedungNama.trim().toLowerCase());
      return !(matchId || matchNama);
    });
    await MockDatabase.saveLocalRuangan();

    return List.unmodifiable(MockDatabase.ruanganList);
  }

  /// ADD Master Data Ruangan
  Future<RuanganModel> addRuangan(RuanganModel ruangan) async {
    MockDatabase.deletedRuanganIds.remove(ruangan.id);
    MockDatabase.deletedRuanganIds.remove(ruangan.nama);
    MockDatabase.ruanganList.removeWhere((r) => r.id == ruangan.id || (r.nama.toLowerCase() == ruangan.nama.toLowerCase() && (r.gedungId == ruangan.gedungId || r.gedungNama.toLowerCase() == ruangan.gedungNama.toLowerCase())));
    MockDatabase.ruanganList.add(ruangan);
    await MockDatabase.saveLocalRuangan();

    if (!ApiConfig.useMockBackend) {
      try {
        await _httpHelper.makeOnlineRequest(
          '/master/ruangan.php',
          method: 'POST',
          body: ruangan.toJson(),
        );
      } catch (_) {}
    }
    await Future.delayed(const Duration(milliseconds: 100));
    return ruangan;
  }

  /// DELETE Master Data Ruangan (Cascade)
  Future<void> deleteRuangan(String ruanganId) async {
    await MockDatabase.cascadeDeleteRuangan(ruanganId);
    if (!ApiConfig.useMockBackend) {
      try {
        await _httpHelper.makeOnlineRequest('/master/ruangan.php?id=$ruanganId', method: 'DELETE');
        await _httpHelper.makeOnlineRequest(
          '/master/ruangan.php',
          method: 'POST',
          body: {'action': 'delete', 'id': ruanganId},
        );
      } catch (_) {}
    }
    await Future.delayed(const Duration(milliseconds: 150));
  }

  /// GET Demo Users for Role Switching
  List<UserModel> getDemoUsers() {
    return List.unmodifiable(MockDatabase.demoUsers.where((u) => !MockDatabase.deletedUserIds.contains(u.id)));
  }
}
