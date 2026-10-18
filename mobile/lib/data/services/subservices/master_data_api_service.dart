import 'dart:convert';
import 'package:bcrypt/bcrypt.dart';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
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

  /// GET /api/master/mata_kuliah.php (All)
  Future<List<MataKuliahModel>> getAllMataKuliah() async {
    await MockDatabase.initLocalCache();
    List<MataKuliahModel>? result;
    bool isOnlineSuccess = false;

    // 1. Direct Supabase Cloud (Primary Ground Truth)
    try {
      final uri = Uri.parse(
        '${ApiConfig.supabaseUrl}/rest/v1/mata_kuliah?select=*,mata_kuliah_kelas(*)',
      );
      final resp = await http
          .get(
            uri,
            headers: {
              'apikey': ApiConfig.supabasePublishableKey,
              'Authorization': 'Bearer ${ApiConfig.supabasePublishableKey}',
              'Accept': 'application/json',
            },
          )
          .timeout(const Duration(seconds: 8));

      if (resp.statusCode == 200) {
        final decoded = jsonDecode(resp.body);
        if (decoded is List) {
          isOnlineSuccess = true;
          result = decoded
              .map(
                (mk) => MataKuliahModel.fromJson(Map<String, dynamic>.from(mk)),
              )
              .where(
                (m) =>
                    !MockDatabase.deletedMatkulIds.contains(m.id) &&
                    !MockDatabase.deletedMatkulIds.contains(m.nama),
              )
              .toList();
        }
      }
    } catch (e) {
      debugPrint('Direct Supabase getAllMataKuliah error: $e');
    }

    // 2. Fallback to backend Python if Supabase returned null or failed
    if (!isOnlineSuccess) {
      try {
        final data = await _httpHelper.makeOnlineRequest(
          '/master/mata_kuliah.php',
        );
        if (data is Map && data['status'] == 'success' && data['data'] != null) {
          final raw = (data['data'] as List)
              .map((mk) => MataKuliahModel.fromJson(mk))
              .where(
                (m) =>
                    !MockDatabase.deletedMatkulIds.contains(m.id) &&
                    !MockDatabase.deletedMatkulIds.contains(m.nama),
              )
              .toList();
          isOnlineSuccess = true;
          result = raw;
        }
      } catch (_) {}
    }

    if (isOnlineSuccess && result != null) {
      // Sync local cache with remote state (even if empty list, database is ground truth)
      MockDatabase.matkulData.clear();
      for (final m in result) {
        MockDatabase.matkulData.add({
          'id': m.id,
          'kode': m.id,
          'nama': m.nama,
          'sks': m.sks,
          'semester': m.semester,
          'semester_angka': m.semester,
          'semesterId': m.semesterId,
          'fakultas': m.fakultasNama,
          'jurusan': m.jurusanNama,
          'dosenId': m.dosenId,
          'dosen': m.dosenNama,
          'kelas': m.kelasNama,
        });
      }
      await MockDatabase.saveLocalMatkul();
      return result;
    }

    // 3. Fallback to Local Cache (ONLY when offline/network error)
    return MockDatabase.matkulData
        .where((m) {
          final id = (m['id'] ?? m['kode'] ?? '').toString();
          final nama = (m['nama'] ?? '').toString();
          return !MockDatabase.deletedMatkulIds.contains(id) &&
              !MockDatabase.deletedMatkulIds.contains(nama);
        })
        .map((m) => MataKuliahModel.fromJson(m))
        .toList();
  }

  /// GET /api/master/mata_kuliah.php
  Future<List<MataKuliahModel>> getMataKuliah(String dosenId) async {
    await MockDatabase.initLocalCache();
    List<MataKuliahModel>? result;
    bool isOnlineSuccess = false;

    // 1. Direct Supabase Cloud
    try {
      final filter = (dosenId.isNotEmpty && dosenId != 'Semua')
          ? '?dosen_id=eq.$dosenId&select=*,mata_kuliah_kelas(*)'
          : '?select=*,mata_kuliah_kelas(*)';
      final uri = Uri.parse(
        '${ApiConfig.supabaseUrl}/rest/v1/mata_kuliah$filter',
      );
      final resp = await http
          .get(
            uri,
            headers: ApiConfig.supabaseHeaders,
          )
          .timeout(const Duration(seconds: 8));

      if (resp.statusCode == 200) {
        final decoded = jsonDecode(resp.body);
        if (decoded is List) {
          isOnlineSuccess = true;
          final list = decoded
              .map(
                (mk) => MataKuliahModel.fromJson(Map<String, dynamic>.from(mk)),
              )
              .where(
                (m) =>
                    !MockDatabase.deletedMatkulIds.contains(m.id) &&
                    !MockDatabase.deletedMatkulIds.contains(m.nama),
              )
              .toList();
          result = list;
        }
      }
    } catch (_) {}

    // 2. Fallback backend Python
    if (!isOnlineSuccess) {
      try {
        final url = (dosenId.isNotEmpty && dosenId != 'Semua')
            ? '/master/mata_kuliah.php?dosen_id=$dosenId&dosenId=$dosenId'
            : '/master/mata_kuliah.php';
        final data = await _httpHelper.makeOnlineRequest(url);
        if (data is Map && data['status'] == 'success' && data['data'] != null) {
          final raw = (data['data'] as List)
              .map((mk) => MataKuliahModel.fromJson(mk))
              .where(
                (m) =>
                    !MockDatabase.deletedMatkulIds.contains(m.id) &&
                    !MockDatabase.deletedMatkulIds.contains(m.nama),
              )
              .toList();
          isOnlineSuccess = true;
          result = raw;
        }
      } catch (_) {}
    }

    if (isOnlineSuccess && result != null) return result;

    // 3. Fallback Local Cache (ONLY when offline/network error)
    return MockDatabase.matkulData
        .where((m) {
          final did = (m['dosenId'] ?? m['dosen_id'] ?? '').toString();
          final id = (m['id'] ?? m['kode'] ?? '').toString();
          final nama = (m['nama'] ?? '').toString();
          if (MockDatabase.deletedMatkulIds.contains(id) ||
              MockDatabase.deletedMatkulIds.contains(nama)) {
            return false;
          }
          if (dosenId.isNotEmpty && dosenId != 'Semua') {
            return did == dosenId;
          }
          return true;
        })
        .map((m) => MataKuliahModel.fromJson(m))
        .toList();
  }

  /// GET slot waktu master data
  Future<List<SlotWaktuModel>> getSlotWaktu() async {
    bool isOnlineSuccess = false;
    List<SlotWaktuModel>? result;

    // 1. Direct Supabase Cloud
    try {
      final uri = Uri.parse(
        '${ApiConfig.supabaseUrl}/rest/v1/slot_waktu?select=*',
      );
      final resp = await http
          .get(
            uri,
            headers: ApiConfig.supabaseHeaders,
          )
          .timeout(const Duration(seconds: 6));

      if (resp.statusCode == 200) {
        final decoded = jsonDecode(resp.body);
        if (decoded is List) {
          isOnlineSuccess = true;
          result = decoded
              .map((s) => SlotWaktuModel.fromJson(Map<String, dynamic>.from(s)))
              .toList();
        }
      }
    } catch (_) {}

    // 2. Coba lewat backend Python
    if (!isOnlineSuccess) {
      try {
        final data = await _httpHelper.makeOnlineRequest(
          '/master/slot_waktu.php',
        );
        if (data is Map && data['status'] == 'success' && data['data'] != null) {
          final raw = (data['data'] as List)
              .map((s) => SlotWaktuModel.fromJson(Map<String, dynamic>.from(s)))
              .toList();
          isOnlineSuccess = true;
          result = raw;
        }
      } catch (_) {}
    }

    if (isOnlineSuccess && result != null && result.isNotEmpty) {
      return result;
    }
    return MockDatabase.slotWaktu;
  }

  /// GET all users / lecturers
  Future<List<UserModel>> getAllUsers() async {
    await MockDatabase.initLocalCache();
    List<UserModel>? result;
    bool isOnlineSuccess = false;

    // 1. Direct Supabase Cloud (Primary Ground Truth)
    try {
      final uri = Uri.parse('${ApiConfig.supabaseUrl}/rest/v1/users?select=*');
      final resp = await http
          .get(
            uri,
            headers: ApiConfig.supabaseHeaders,
          )
          .timeout(const Duration(seconds: 8));

      if (resp.statusCode == 200) {
        final decoded = jsonDecode(resp.body);
        if (decoded is List) {
          isOnlineSuccess = true;
          result = decoded
              .map((u) => UserModel.fromJson(Map<String, dynamic>.from(u)))
              .where(
                (u) =>
                    !MockDatabase.deletedUserIds.contains(u.id) &&
                    !MockDatabase.deletedUserIds.contains(u.nama) &&
                    !MockDatabase.deletedUserIds.contains(u.email),
              )
              .toList();
        }
      }
    } catch (e) {
      debugPrint('Direct Supabase getAllUsers error: $e');
    }

    // 2. Fallback to backend Python
    if (!isOnlineSuccess) {
      try {
        final data = await _httpHelper.makeOnlineRequest('/master/users.php');
        if (data is Map && data['status'] == 'success' && data['data'] != null) {
          final raw = (data['data'] as List)
              .map((u) => UserModel.fromJson(u))
              .where(
                (u) =>
                    !MockDatabase.deletedUserIds.contains(u.id) &&
                    !MockDatabase.deletedUserIds.contains(u.nama) &&
                    !MockDatabase.deletedUserIds.contains(u.email),
              )
              .toList();
          isOnlineSuccess = true;
          result = raw;
        }
      } catch (_) {}
    }

    if (isOnlineSuccess && result != null) {
      MockDatabase.demoUsers
        ..clear()
        ..addAll(result);
      await MockDatabase.saveLocalUsers();
      return result;
    }

    // 3. Fallback Local Cache (ONLY when offline/network error)
    return MockDatabase.demoUsers
        .where(
          (u) =>
              !MockDatabase.deletedUserIds.contains(u.id) &&
              !MockDatabase.deletedUserIds.contains(u.nama) &&
              !MockDatabase.deletedUserIds.contains(u.email),
        )
        .toList();
  }

  /// TOGGLE Dosen Priority Flag (MRV Heuristic Priority)
  Future<bool> toggleDosenPriority(String dosenId) async {
    final newPriority = !MockDatabase.priorityDosenIds.contains(dosenId);
    await setDosenPriority(dosenId, newPriority);
    return newPriority;
  }

  Future<void> setDosenPriority(String dosenId, bool priority) async {
    try {
      await _httpHelper.makeOnlineRequest(
        '/master/users.php',
        method: 'POST',
        body: {'dosenId': dosenId, 'isPriority': priority},
      );
    } catch (_) {}

    // Direct Supabase Cloud Fallback
    try {
      final uri = Uri.parse(
        '${ApiConfig.supabaseUrl}/rest/v1/users?id=eq.$dosenId',
      );
      await http
          .patch(
            uri,
            headers: {
              'apikey': ApiConfig.supabasePublishableKey,
              'Authorization': 'Bearer ${ApiConfig.supabasePublishableKey}',
              'Content-Type': 'application/json',
            },
            body: jsonEncode({'is_priority': priority}),
          )
          .timeout(const Duration(seconds: 8));
    } catch (_) {}
  }

  /// Create / Register new Dosen with email & login credentials
  Future<UserModel> createDosen(
    UserModel dosen, {
    String password = 'password123',
  }) async {
    // Un-mark from deleted sets
    MockDatabase.deletedUserIds.remove(dosen.id);
    MockDatabase.deletedUserIds.remove(dosen.nama);
    MockDatabase.deletedUserIds.remove(dosen.email);
    MockDatabase.demoUsers.removeWhere(
      (u) => u.id == dosen.id || u.email == dosen.email,
    );
    MockDatabase.demoUsers.add(dosen);
    await MockDatabase.saveLocalUsers();

    // 1. Direct Supabase Cloud Persistence (First priority)
    try {
      final checkUri = Uri.parse(
        '${ApiConfig.supabaseUrl}/rest/v1/users?or=(id.eq.${dosen.id},email.eq.${dosen.email})&select=id,role',
      );
      final checkResp = await http
          .get(
            checkUri,
            headers: {
              'apikey': ApiConfig.supabasePublishableKey,
              'Authorization': 'Bearer ${ApiConfig.supabasePublishableKey}',
              'Accept': 'application/json',
            },
          )
          .timeout(const Duration(seconds: 6));

      bool userExists = false;
      String targetId = dosen.id;
      if (checkResp.statusCode == 200) {
        final decoded = jsonDecode(checkResp.body);
        if (decoded is List && decoded.isNotEmpty) {
          userExists = true;
          targetId = decoded[0]['id']?.toString() ?? dosen.id;
        }
      }

      String securePassword = password;
      if (!password.startsWith(r'$2b$') &&
          !password.startsWith(r'$2a$') &&
          !password.startsWith(r'$2y$')) {
        securePassword = BCrypt.hashpw(password, BCrypt.gensalt());
      }

      final payload = {
        'id': targetId,
        'nama': dosen.nama,
        'email': dosen.email,
        'password': securePassword,
        'role': dosen.role,
        'jurusan_id': dosen.jurusanId,
        'jurusan_nama': dosen.jurusanNama,
        'fakultas_nama': dosen.fakultasNama,
        'is_priority': dosen.isPriority,
        'matkul_nama': dosen.matkulNama ?? '',
      };

      if (userExists) {
        final patchUri = Uri.parse(
          '${ApiConfig.supabaseUrl}/rest/v1/users?id=eq.$targetId',
        );
        await http
            .patch(
            patchUri,
            headers: {
              'apikey': ApiConfig.supabasePublishableKey,
              'Authorization': 'Bearer ${ApiConfig.supabasePublishableKey}',
              'Content-Type': 'application/json',
            },
            body: jsonEncode(payload),
          )
          .timeout(const Duration(seconds: 8));
      } else {
        final postUri = Uri.parse('${ApiConfig.supabaseUrl}/rest/v1/users');
        await http
            .post(
              postUri,
              headers: {
                'apikey': ApiConfig.supabasePublishableKey,
                'Authorization': 'Bearer ${ApiConfig.supabasePublishableKey}',
                'Content-Type': 'application/json',
                'Prefer': 'resolution=merge-duplicates',
              },
              body: jsonEncode(payload),
            )
            .timeout(const Duration(seconds: 8));
      }

      if (dosen.matkulNama != null && dosen.matkulNama!.isNotEmpty) {
        final matkulItems = dosen.matkulNama!
            .split(',')
            .map((s) => s.trim())
            .where((s) => s.isNotEmpty);
        for (final item in matkulItems) {
          final cleanTitle = item.contains('-')
              ? item.split('-').last.trim()
              : item;
          if (cleanTitle.isNotEmpty) {
            final mkPatchUri = Uri.parse(
              '${ApiConfig.supabaseUrl}/rest/v1/mata_kuliah?nama=ilike.%25${Uri.encodeComponent(cleanTitle)}%25',
            );
            await http
                .patch(
                  mkPatchUri,
                  headers: {
                    'apikey': ApiConfig.supabasePublishableKey,
                    'Authorization':
                        'Bearer ${ApiConfig.supabasePublishableKey}',
                    'Content-Type': 'application/json',
                  },
                  body: jsonEncode({
                    'dosen_id': targetId,
                    'dosen_nama': dosen.nama,
                  }),
                )
                .timeout(const Duration(seconds: 5));
          }
        }
      }
    } catch (e) {
      debugPrint('Direct Supabase createDosen error: $e');
    }

    // 2. Send to Backend Python
    try {
      await _httpHelper.makeOnlineRequest(
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
          'matkul_nama': dosen.matkulNama ?? '',
          'matkulNama': dosen.matkulNama ?? '',
          'is_priority': dosen.isPriority ? 1 : 0,
        },
      );
    } catch (_) {}

    return dosen;
  }

  /// Delete Dosen / User (Cascade Permanently)
  Future<void> deleteUser(String userId) async {
    // 0. Cascade delete and mark permanently deleted in local cache
    await MockDatabase.cascadeDeleteDosen(userId);

    // 1. Direct Supabase Cloud (Cascade Relational Deletes)
    try {
      // A. Hapus ajuan_pengajaran terkait dosen
      await http
          .delete(
            Uri.parse(
              '${ApiConfig.supabaseUrl}/rest/v1/ajuan_pengajaran?dosen_id=eq.$userId',
            ),
            headers: {
              'apikey': ApiConfig.supabasePublishableKey,
              'Authorization': 'Bearer ${ApiConfig.supabasePublishableKey}',
            },
          )
          .timeout(const Duration(seconds: 5));

      // B. Hapus jadwal_final terkait dosen
      await http
          .delete(
            Uri.parse(
              '${ApiConfig.supabaseUrl}/rest/v1/jadwal_final?dosen_id=eq.$userId',
            ),
            headers: {
              'apikey': ApiConfig.supabasePublishableKey,
              'Authorization': 'Bearer ${ApiConfig.supabasePublishableKey}',
            },
          )
          .timeout(const Duration(seconds: 5));

      // C. Hapus availability & slots
      final avResp = await http
          .get(
            Uri.parse(
              '${ApiConfig.supabaseUrl}/rest/v1/availability?dosen_id=eq.$userId&select=id',
            ),
            headers: {
              'apikey': ApiConfig.supabasePublishableKey,
              'Authorization': 'Bearer ${ApiConfig.supabasePublishableKey}',
            },
          )
          .timeout(const Duration(seconds: 5));
      if (avResp.statusCode == 200) {
        final avList = jsonDecode(avResp.body);
        if (avList is List) {
          for (var av in avList) {
            final avId = av['id'];
            if (avId != null) {
              await http
                  .delete(
                    Uri.parse(
                      '${ApiConfig.supabaseUrl}/rest/v1/availability_slots?availability_id=eq.$avId',
                    ),
                    headers: {
                      'apikey': ApiConfig.supabasePublishableKey,
                      'Authorization':
                          'Bearer ${ApiConfig.supabasePublishableKey}',
                    },
                  )
                  .timeout(const Duration(seconds: 4));
            }
          }
        }
      }
      await http
          .delete(
            Uri.parse(
              '${ApiConfig.supabaseUrl}/rest/v1/availability?dosen_id=eq.$userId',
            ),
            headers: {
              'apikey': ApiConfig.supabasePublishableKey,
              'Authorization': 'Bearer ${ApiConfig.supabasePublishableKey}',
            },
          )
          .timeout(const Duration(seconds: 5));

      // D. Hapus mata_kuliah_kelas & mata_kuliah terkait
      final mkResp = await http
          .get(
            Uri.parse(
              '${ApiConfig.supabaseUrl}/rest/v1/mata_kuliah?dosen_id=eq.$userId&select=id',
            ),
            headers: {
              'apikey': ApiConfig.supabasePublishableKey,
              'Authorization': 'Bearer ${ApiConfig.supabasePublishableKey}',
            },
          )
          .timeout(const Duration(seconds: 5));
      if (mkResp.statusCode == 200) {
        final mkList = jsonDecode(mkResp.body);
        if (mkList is List) {
          for (var mk in mkList) {
            final mkId = mk['id'];
            if (mkId != null) {
              await http
                  .delete(
                    Uri.parse(
                      '${ApiConfig.supabaseUrl}/rest/v1/mata_kuliah_kelas?mata_kuliah_id=eq.$mkId',
                    ),
                    headers: {
                      'apikey': ApiConfig.supabasePublishableKey,
                      'Authorization':
                          'Bearer ${ApiConfig.supabasePublishableKey}',
                    },
                  )
                  .timeout(const Duration(seconds: 4));
            }
          }
        }
      }
      await http
          .delete(
            Uri.parse(
              '${ApiConfig.supabaseUrl}/rest/v1/mata_kuliah?dosen_id=eq.$userId',
            ),
            headers: {
              'apikey': ApiConfig.supabasePublishableKey,
              'Authorization': 'Bearer ${ApiConfig.supabasePublishableKey}',
            },
          )
          .timeout(const Duration(seconds: 5));

      // E. Hapus user
      final uri = Uri.parse(
        '${ApiConfig.supabaseUrl}/rest/v1/users?id=eq.$userId',
      );
      await http
          .delete(
            uri,
            headers: {
              'apikey': ApiConfig.supabasePublishableKey,
              'Authorization': 'Bearer ${ApiConfig.supabasePublishableKey}',
            },
          )
          .timeout(const Duration(seconds: 8));
    } catch (_) {}

    // 2. Backend Python
    try {
      await _httpHelper.makeOnlineRequest(
        '/master/users.php?id=$userId',
        method: 'DELETE',
      );
      await _httpHelper.makeOnlineRequest(
        '/master/users.php',
        method: 'POST',
        body: {'action': 'delete', 'id': userId},
      );
    } catch (_) {}
  }

  /// GET Master Data Gedung List
  Future<List<GedungModel>> getGedungList() async {
    await MockDatabase.initLocalCache();
    List<GedungModel>? result;
    bool isOnlineSuccess = false;

    // 1. Direct Supabase Cloud (Primary Ground Truth)
    try {
      final uri = Uri.parse('${ApiConfig.supabaseUrl}/rest/v1/gedung?select=*');
      final resp = await http
          .get(
            uri,
            headers: {
              'apikey': ApiConfig.supabasePublishableKey,
              'Authorization': 'Bearer ${ApiConfig.supabasePublishableKey}',
              'Accept': 'application/json',
            },
          )
          .timeout(const Duration(seconds: 8));

      if (resp.statusCode == 200) {
        final decoded = jsonDecode(resp.body);
        if (decoded is List) {
          isOnlineSuccess = true;
          result = decoded
              .map((g) => GedungModel.fromJson(Map<String, dynamic>.from(g)))
              .where(
                (g) =>
                    !MockDatabase.deletedGedungIds.contains(g.id) &&
                    !MockDatabase.deletedGedungIds.contains(g.nama),
              )
              .toList();
        }
      }
    } catch (e) {
      debugPrint('Direct Supabase getGedungList error: $e');
    }

    // 2. Fallback to backend Python if Supabase returned null or failed
    if (!isOnlineSuccess) {
      try {
        final data = await _httpHelper.makeOnlineRequest('/master/gedung.php');
        if (data is Map && data['status'] == 'success' && data['data'] != null) {
          final raw = (data['data'] as List)
              .map((g) => GedungModel.fromJson(g))
              .where(
                (g) =>
                    !MockDatabase.deletedGedungIds.contains(g.id) &&
                    !MockDatabase.deletedGedungIds.contains(g.nama),
              )
              .toList();
          isOnlineSuccess = true;
          result = raw;
        }
      } catch (_) {}
    }

    if (isOnlineSuccess && result != null) {
      MockDatabase.gedungList
        ..clear()
        ..addAll(result);
      await MockDatabase.saveLocalGedung();
      return result;
    }

    // 3. Fallback to Local Cache in MockDatabase (ONLY when offline/network error)
    return MockDatabase.gedungList
        .where(
          (g) =>
              !MockDatabase.deletedGedungIds.contains(g.id) &&
              !MockDatabase.deletedGedungIds.contains(g.nama),
        )
        .toList();
  }

  /// ADD Master Data Gedung
  Future<GedungModel> addGedung(GedungModel gedung) async {
    // Un-mark from deleted sets
    MockDatabase.deletedGedungIds.remove(gedung.id);
    MockDatabase.deletedGedungIds.remove(gedung.nama);
    MockDatabase.gedungList.removeWhere(
      (g) => g.id == gedung.id || g.nama == gedung.nama,
    );
    MockDatabase.gedungList.add(gedung);
    await MockDatabase.saveLocalGedung();

    // 1. Direct Supabase Cloud (Always ground truth)
    try {
      final uri = Uri.parse('${ApiConfig.supabaseUrl}/rest/v1/gedung');
      await http
          .post(
            uri,
            headers: {
              'apikey': ApiConfig.supabasePublishableKey,
              'Authorization': 'Bearer ${ApiConfig.supabasePublishableKey}',
              'Content-Type': 'application/json',
              'Prefer': 'resolution=merge-duplicates',
            },
            body: jsonEncode({
              'id': gedung.id,
              'nama': gedung.nama,
              'jam_buka': gedung.jamBuka,
              'jam_tutup': gedung.jamTutup,
              'akses_jurusan': gedung.aksesJurusan,
            }),
          )
          .timeout(const Duration(seconds: 8));
    } catch (e) {
      debugPrint('Supabase addGedung error: $e');
    }

    // 2. Backend Python
    try {
      await _httpHelper.makeOnlineRequest(
        '/master/gedung.php',
        method: 'POST',
        body: gedung.toJson(),
      );
    } catch (_) {}

    return gedung;
  }

  /// DELETE Master Data Gedung (Cascade Permanently)
  Future<void> deleteGedung(String gedungId) async {
    // 0. Cascade delete and record in local storage
    await MockDatabase.cascadeDeleteGedung(gedungId);

    // 1. Direct Supabase Cloud (Cascade Relational Deletes)
    try {
      // Hapus ruangan terkait
      await http
          .delete(
            Uri.parse(
              '${ApiConfig.supabaseUrl}/rest/v1/ruangan?gedung_id=eq.$gedungId',
            ),
            headers: {
              'apikey': ApiConfig.supabasePublishableKey,
              'Authorization': 'Bearer ${ApiConfig.supabasePublishableKey}',
            },
          )
          .timeout(const Duration(seconds: 5));

      final uri = Uri.parse(
        '${ApiConfig.supabaseUrl}/rest/v1/gedung?id=eq.$gedungId',
      );
      await http
          .delete(
            uri,
            headers: {
              'apikey': ApiConfig.supabasePublishableKey,
              'Authorization': 'Bearer ${ApiConfig.supabasePublishableKey}',
            },
          )
          .timeout(const Duration(seconds: 8));
    } catch (_) {}

    // 2. Backend Python
    try {
      await _httpHelper.makeOnlineRequest(
        '/master/gedung.php?id=$gedungId',
        method: 'DELETE',
      );
      await _httpHelper.makeOnlineRequest(
        '/master/gedung.php',
        method: 'POST',
        body: {'action': 'delete', 'id': gedungId},
      );
    } catch (_) {}
  }

  /// GET Master Data Fakultas List from Supabase
  Future<List<Map<String, dynamic>>> getFakultasList() async {
    await MockDatabase.initLocalCache();
    List<Map<String, dynamic>>? result;
    bool isOnlineSuccess = false;

    // 1. Direct Supabase Cloud (Primary Ground Truth)
    try {
      final uri = Uri.parse(
        '${ApiConfig.supabaseUrl}/rest/v1/fakultas?select=*',
      );
      final resp = await http
          .get(
            uri,
            headers: {
              'apikey': ApiConfig.supabasePublishableKey,
              'Authorization': 'Bearer ${ApiConfig.supabasePublishableKey}',
              'Accept': 'application/json',
            },
          )
          .timeout(const Duration(seconds: 8));

      if (resp.statusCode == 200) {
        final decoded = jsonDecode(resp.body);
        if (decoded is List) {
          isOnlineSuccess = true;
          result = decoded
              .map((f) {
                final m = Map<String, dynamic>.from(f);
                List<String> jurList = [];
                if (m['jurusan'] is List) {
                  jurList = (m['jurusan'] as List)
                      .map((e) => e.toString())
                      .toList();
                } else if (m['jurusan'] is String) {
                  jurList = (m['jurusan'] as String)
                      .split(',')
                      .map((e) => e.trim())
                      .toList();
                }
                return {
                  'id': m['id']?.toString() ?? '',
                  'nama': m['nama']?.toString() ?? '',
                  'dekan_id': m['dekan_id']?.toString() ?? '',
                  'dekan':
                      m['dekan_nama']?.toString() ??
                      m['dekan']?.toString() ??
                      '',
                  'gedung_id': m['gedung_id']?.toString() ?? '',
                  'gedung':
                      m['gedung_nama']?.toString() ??
                      m['gedung']?.toString() ??
                      '',
                  'jurusan': jurList,
                };
              })
              .where(
                (f) =>
                    !MockDatabase.deletedFakultasIds.contains(
                      f['id']?.toString(),
                    ) &&
                    !MockDatabase.deletedFakultasIds.contains(
                      f['nama']?.toString(),
                    ),
              )
              .toList();
        }
      }
    } catch (e) {
      debugPrint('Direct Supabase getFakultasList error: $e');
    }

    // 2. Fallback backend Python
    if (!isOnlineSuccess) {
      try {
        final data = await _httpHelper.makeOnlineRequest('/master/fakultas.php');
        if (data is Map && data['status'] == 'success' && data['data'] != null) {
          final raw = (data['data'] as List)
              .map((f) => Map<String, dynamic>.from(f))
              .where(
                (f) =>
                    !MockDatabase.deletedFakultasIds.contains(
                      f['id']?.toString(),
                    ) &&
                    !MockDatabase.deletedFakultasIds.contains(
                      f['nama']?.toString(),
                    ),
              )
              .toList();
          isOnlineSuccess = true;
          result = raw;
        }
      } catch (_) {}
    }

    if (isOnlineSuccess && result != null) {
      MockDatabase.fakultasData
        ..clear()
        ..addAll(result);
      await MockDatabase.saveLocalFakultas();
      return result;
    }

    // 3. Fallback Local Cache (ONLY when offline/network error)
    return MockDatabase.fakultasData
        .where(
          (f) =>
              !MockDatabase.deletedFakultasIds.contains(f['id']?.toString()) &&
              !MockDatabase.deletedFakultasIds.contains(f['nama']?.toString()),
        )
        .toList();
  }

  /// ADD / UPSERT Master Data Fakultas to Supabase
  Future<void> saveFakultas(Map<String, dynamic> fakultas) async {
    final fId = (fakultas['id'] ?? '').toString();
    final fNama = (fakultas['nama'] ?? '').toString();
    final dekanNama = (fakultas['dekan'] ?? fakultas['dekan_nama'] ?? '')
        .toString();
    final gedungNama = (fakultas['gedung'] ?? fakultas['gedung_nama'] ?? '')
        .toString();
    final jurRaw = fakultas['jurusan'];
    final List<String> jurList = jurRaw is List
        ? jurRaw.map((e) => e.toString()).toList()
        : <String>[];

    final resolvedId = fId.isNotEmpty
        ? fId
        : 'FAK_${DateTime.now().millisecondsSinceEpoch}';

    // Un-mark from deleted sets
    MockDatabase.deletedFakultasIds.remove(resolvedId);
    MockDatabase.deletedFakultasIds.remove(fNama);
    MockDatabase.fakultasData.removeWhere(
      (item) =>
          ((item['id'] ?? item['nama'])?.toString() ?? '') == resolvedId ||
          (item['nama']?.toString() ?? '') == fNama,
    );
    MockDatabase.fakultasData.add({
      'id': resolvedId,
      'nama': fNama,
      'dekan': dekanNama,
      'dekan_nama': dekanNama,
      'gedung': gedungNama,
      'gedung_nama': gedungNama,
      'jurusan': jurList,
    });
    await MockDatabase.saveLocalFakultas();

    final payload = {
      'id': resolvedId,
      'nama': fNama,
      'dekan_nama': dekanNama,
      'gedung_nama': gedungNama,
      'jurusan': jurList,
    };

    // 1. Direct Supabase Cloud
    try {
      final uri = Uri.parse('${ApiConfig.supabaseUrl}/rest/v1/fakultas');
      await http
          .post(
            uri,
            headers: {
              'apikey': ApiConfig.supabasePublishableKey,
              'Authorization': 'Bearer ${ApiConfig.supabasePublishableKey}',
              'Content-Type': 'application/json',
              'Prefer': 'resolution=merge-duplicates',
            },
            body: jsonEncode(payload),
          )
          .timeout(const Duration(seconds: 8));
    } catch (e) {
      debugPrint('Direct Supabase saveFakultas error: $e');
    }

    // 2. Backend Python
    try {
      await _httpHelper.makeOnlineRequest(
        '/master/fakultas.php',
        method: 'POST',
        body: payload,
      );
    } catch (_) {}
  }

  /// DELETE Master Data Fakultas from Supabase
  Future<void> deleteFakultas(String fakultasId) async {
    await MockDatabase.cascadeDeleteFakultas(fakultasId);

    // 1. Direct Supabase Cloud
    try {
      final uri = Uri.parse(
        '${ApiConfig.supabaseUrl}/rest/v1/fakultas?id=eq.$fakultasId',
      );
      await http
          .delete(
            uri,
            headers: {
              'apikey': ApiConfig.supabasePublishableKey,
              'Authorization': 'Bearer ${ApiConfig.supabasePublishableKey}',
            },
          )
          .timeout(const Duration(seconds: 8));
    } catch (e) {
      debugPrint('Direct Supabase deleteFakultas error: $e');
    }

    // 2. Backend Python
    try {
      await _httpHelper.makeOnlineRequest(
        '/master/fakultas.php?id=$fakultasId',
        method: 'DELETE',
      );
      await _httpHelper.makeOnlineRequest(
        '/master/fakultas.php',
        method: 'POST',
        body: {'action': 'delete', 'id': fakultasId},
      );
    } catch (_) {}
  }

  RuanganModel _sanitizeRuangan(RuanganModel r) {
    if (r.gedungNama.trim().isNotEmpty) return r;
    if (r.gedungId.isNotEmpty) {
      final g = MockDatabase.gedungList
          .where((g) => g.id == r.gedungId)
          .firstOrNull;
      if (g != null && g.nama.isNotEmpty) {
        return r.copyWith(gedungNama: g.nama);
      }
    }
    return r;
  }

  /// GET Master Data Ruangan List
  Future<List<RuanganModel>> getRuanganList() async {
    await MockDatabase.initLocalCache();
    List<RuanganModel>? result;
    bool isOnlineSuccess = false;

    // 1. Direct Supabase Cloud (Primary Ground Truth)
    try {
      final uri = Uri.parse(
        '${ApiConfig.supabaseUrl}/rest/v1/ruangan?select=*,gedung(*)',
      );
      final resp = await http
          .get(
            uri,
            headers: {
              'apikey': ApiConfig.supabasePublishableKey,
              'Authorization': 'Bearer ${ApiConfig.supabasePublishableKey}',
              'Accept': 'application/json',
            },
          )
          .timeout(const Duration(seconds: 8));

      if (resp.statusCode == 200) {
        final decoded = jsonDecode(resp.body);
        if (decoded is List) {
          isOnlineSuccess = true;
          result = decoded
              .map(
                (r) => _sanitizeRuangan(
                  RuanganModel.fromJson(Map<String, dynamic>.from(r)),
                ),
              )
              .where(
                (r) =>
                    !MockDatabase.deletedRuanganIds.contains(r.id) &&
                    !MockDatabase.deletedRuanganIds.contains(r.nama) &&
                    (r.gedungId.isEmpty ||
                        !MockDatabase.deletedGedungIds.contains(r.gedungId)) &&
                    (r.gedungNama.isEmpty ||
                        !MockDatabase.deletedGedungIds.contains(r.gedungNama)),
              )
              .toList();
        }
      }
    } catch (e) {
      debugPrint('Direct Supabase getRuanganList error: $e');
    }

    // 2. Fallback backend Python if Supabase returned null or failed
    if (!isOnlineSuccess) {
      try {
        final data = await _httpHelper.makeOnlineRequest('/master/ruangan.php');
        if (data is Map && data['status'] == 'success' && data['data'] != null) {
          final raw = (data['data'] as List)
              .map((r) => _sanitizeRuangan(RuanganModel.fromJson(r)))
              .where(
                (r) =>
                    !MockDatabase.deletedRuanganIds.contains(r.id) &&
                    !MockDatabase.deletedRuanganIds.contains(r.nama) &&
                    (r.gedungId.isEmpty ||
                        !MockDatabase.deletedGedungIds.contains(r.gedungId)) &&
                    (r.gedungNama.isEmpty ||
                        !MockDatabase.deletedGedungIds.contains(r.gedungNama)),
              )
              .toList();
          isOnlineSuccess = true;
          result = raw;
        }
      } catch (_) {}
    }

    if (isOnlineSuccess && result != null) {
      MockDatabase.ruanganList
        ..clear()
        ..addAll(result);
      await MockDatabase.saveLocalRuangan();
      return result;
    }

    // 3. Fallback to Local Cache in MockDatabase (ONLY when offline/network error)
    return MockDatabase.ruanganList
        .where(
          (r) =>
              !MockDatabase.deletedRuanganIds.contains(r.id) &&
              !MockDatabase.deletedRuanganIds.contains(r.nama) &&
              (r.gedungId.isEmpty ||
                  !MockDatabase.deletedGedungIds.contains(r.gedungId)) &&
              (r.gedungNama.isEmpty ||
                  !MockDatabase.deletedGedungIds.contains(r.gedungNama)),
        )
        .toList();
  }

  /// ADD Master Data Ruangan
  Future<RuanganModel> addRuangan(RuanganModel ruangan) async {
    MockDatabase.deletedRuanganIds.remove(ruangan.id);
    MockDatabase.deletedRuanganIds.remove(ruangan.nama);
    MockDatabase.ruanganList.removeWhere(
      (r) =>
          r.id == ruangan.id ||
          (r.nama.toLowerCase() == ruangan.nama.toLowerCase() &&
              (r.gedungId == ruangan.gedungId ||
                  r.gedungNama.toLowerCase() ==
                      ruangan.gedungNama.toLowerCase())),
    );
    MockDatabase.ruanganList.add(ruangan);
    await MockDatabase.saveLocalRuangan();

    // 1. Direct Supabase Cloud (Primary Ground Truth)
    try {
      String resolvedGedungId = ruangan.gedungId;
      if (resolvedGedungId.isEmpty && ruangan.gedungNama.isNotEmpty) {
        final gMatch = MockDatabase.gedungList
            .where(
              (g) => g.nama.toLowerCase() == ruangan.gedungNama.toLowerCase(),
            )
            .firstOrNull;
        if (gMatch != null) resolvedGedungId = gMatch.id;
      }
      if (resolvedGedungId.isEmpty) {
        resolvedGedungId = 'GD01';
      }

      // Pastikan Gedung induk tersimpan di Supabase sebelum memasukkan Ruangan (mencegah Foreign Key Violation)
      if (ruangan.gedungNama.isNotEmpty) {
        try {
          final gMatch = MockDatabase.gedungList
              .where(
                (g) =>
                    g.id == resolvedGedungId ||
                    g.nama.toLowerCase() == ruangan.gedungNama.toLowerCase(),
              )
              .firstOrNull;
          await http
              .post(
                Uri.parse('${ApiConfig.supabaseUrl}/rest/v1/gedung'),
                headers: {
                  'apikey': ApiConfig.supabasePublishableKey,
                  'Authorization': 'Bearer ${ApiConfig.supabasePublishableKey}',
                  'Content-Type': 'application/json',
                  'Prefer': 'resolution=merge-duplicates',
                },
                body: jsonEncode({
                  'id': resolvedGedungId,
                  'nama': gMatch?.nama ?? ruangan.gedungNama,
                  'jam_buka': gMatch?.jamBuka ?? '07:00',
                  'jam_tutup': gMatch?.jamTutup ?? '18:30',
                  'akses_jurusan': gMatch?.aksesJurusan ?? '',
                }),
              )
              .timeout(const Duration(seconds: 4));
        } catch (_) {}
      }

      // Kirim kolom yang valid ke tabel ruangan di Supabase
      final uri = Uri.parse('${ApiConfig.supabaseUrl}/rest/v1/ruangan');
      await http
          .post(
            uri,
            headers: {
              'apikey': ApiConfig.supabasePublishableKey,
              'Authorization': 'Bearer ${ApiConfig.supabasePublishableKey}',
              'Content-Type': 'application/json',
              'Prefer': 'resolution=merge-duplicates',
            },
            body: jsonEncode({
              'id': ruangan.id,
              'nama': ruangan.nama,
              'gedung_id': resolvedGedungId,
              'lantai': 'Lantai 1',
              'kapasitas': ruangan.kapasitas,
              'tipe_ruangan': ruangan.tipeRuangan,
              'status': 'Kosong (Ready)',
              'keterangan': ruangan.keterangan.isNotEmpty
                  ? ruangan.keterangan
                  : 'Ruang kelas ber-AC dan LCD proyektor',
            }),
          )
          .timeout(const Duration(seconds: 8));
    } catch (e) {
      debugPrint('Supabase addRuangan error: $e');
    }

    // 2. Backend Python
    try {
      await _httpHelper.makeOnlineRequest(
        '/master/ruangan.php',
        method: 'POST',
        body: {
          'id': ruangan.id,
          'nama': ruangan.nama,
          'gedung_id': ruangan.gedungId,
          'gedungId': ruangan.gedungId,
          'gedung_nama': ruangan.gedungNama,
          'gedungNama': ruangan.gedungNama,
          'kapasitas': ruangan.kapasitas,
          'tipe_ruangan': ruangan.tipeRuangan,
          'tipeRuangan': ruangan.tipeRuangan,
          'lantai': 'Lantai 1',
          'status': 'Kosong (Ready)',
          'keterangan': ruangan.keterangan.isNotEmpty
              ? ruangan.keterangan
              : 'Ruang kelas ber-AC dan LCD proyektor',
        },
      );
    } catch (_) {}

    return ruangan;
  }

  /// DELETE Master Data Ruangan (Cascade Permanently)
  Future<void> deleteRuangan(String ruanganId) async {
    await MockDatabase.cascadeDeleteRuangan(ruanganId);

    // 1. Direct Supabase Cloud
    try {
      final uri = Uri.parse(
        '${ApiConfig.supabaseUrl}/rest/v1/ruangan?id=eq.$ruanganId',
      );
      await http
          .delete(
            uri,
            headers: {
              'apikey': ApiConfig.supabasePublishableKey,
              'Authorization': 'Bearer ${ApiConfig.supabasePublishableKey}',
            },
          )
          .timeout(const Duration(seconds: 8));
    } catch (_) {}

    // 2. Backend Python
    try {
      await _httpHelper.makeOnlineRequest(
        '/master/ruangan.php?id=$ruanganId',
        method: 'DELETE',
      );
      await _httpHelper.makeOnlineRequest(
        '/master/ruangan.php',
        method: 'POST',
        body: {'action': 'delete', 'id': ruanganId},
      );
    } catch (_) {}
  }

  /// SAVE / UPDATE Master Data Mata Kuliah
  Future<void> saveMataKuliah(Map<String, dynamic> matkul) async {
    final mkId = (matkul['id'] ?? matkul['kode'] ?? '').toString().trim();
    if (mkId.isEmpty) return;

    final smtVal =
        int.tryParse(
          matkul['semester']?.toString() ??
              matkul['semester_angka']?.toString() ??
              '',
        ) ??
        1;
    final smtId = smtVal % 2 != 0 ? 'SEM001' : 'SEM002';
    final rawKelas = matkul['kelas'];
    final List<String> kList = rawKelas is List
        ? rawKelas
              .map((e) => e.toString().trim())
              .where((e) => e.isNotEmpty)
              .toList()
        : (rawKelas is String && rawKelas.isNotEmpty
              ? rawKelas
                    .split(',')
                    .map((e) => e.trim())
                    .where((e) => e.isNotEmpty)
                    .toList()
              : ['A']);

    // Un-mark from deleted sets
    MockDatabase.deletedMatkulIds.remove(mkId);
    MockDatabase.deletedMatkulIds.remove(matkul['nama']?.toString() ?? '');
    MockDatabase.matkulData.removeWhere(
      (item) =>
          (item['kode']?.toString() ?? item['id']?.toString() ?? '') == mkId,
    );
    MockDatabase.matkulData.add(matkul);
    await MockDatabase.saveLocalMatkul();

    // 1. Direct upsert to Supabase
    try {
      final uri = Uri.parse('${ApiConfig.supabaseUrl}/rest/v1/mata_kuliah');
      final resp = await http
          .post(
            uri,
            headers: {
              'apikey': ApiConfig.supabasePublishableKey,
              'Authorization': 'Bearer ${ApiConfig.supabasePublishableKey}',
              'Content-Type': 'application/json',
              'Prefer': 'resolution=merge-duplicates',
            },
            body: jsonEncode({
              'id': mkId,
              'nama': matkul['nama'],
              'sks': matkul['sks'] ?? 3,
              'semester_angka': smtVal,
              'semester_id': smtId,
              'jurusan_id': matkul['jurusan_id'] ?? matkul['jurusanId'] ?? '',
              'jurusan_nama': matkul['jurusan'] ?? matkul['jurusan_nama'] ?? matkul['jurusanNama'] ?? '',
              'fakultas_nama':
                  matkul['fakultas'] ?? matkul['fakultas_nama'] ?? matkul['fakultasNama'] ?? '',
              'dosen_id': matkul['dosenId'] ?? matkul['dosen_id'] ?? '',
              'dosen_nama': matkul['dosen'] ?? '',
              'kebutuhan_tipe_ruangan':
                  matkul['kebutuhan_tipe_ruangan'] ??
                  matkul['kebutuhanTipeRuangan'] ??
                  'Kelas Teori',
            }),
          )
          .timeout(const Duration(seconds: 8));

      // 2. Direct sync mata_kuliah_kelas table in Supabase
      if (resp.statusCode == 200 || resp.statusCode == 201) {
        final delUri = Uri.parse(
          '${ApiConfig.supabaseUrl}/rest/v1/mata_kuliah_kelas?mata_kuliah_id=eq.$mkId',
        );
        await http
            .delete(
              delUri,
              headers: {
                'apikey': ApiConfig.supabasePublishableKey,
                'Authorization': 'Bearer ${ApiConfig.supabasePublishableKey}',
              },
            )
            .timeout(const Duration(seconds: 5));

        if (kList.isNotEmpty) {
          final insertUri = Uri.parse(
            '${ApiConfig.supabaseUrl}/rest/v1/mata_kuliah_kelas',
          );
          final rows = kList
              .map((k) => {'mata_kuliah_id': mkId, 'kelas_nama': k})
              .toList();

          await http
              .post(
                insertUri,
                headers: {
                  'apikey': ApiConfig.supabasePublishableKey,
                  'Authorization': 'Bearer ${ApiConfig.supabasePublishableKey}',
                  'Content-Type': 'application/json',
                },
                body: jsonEncode(rows),
              )
              .timeout(const Duration(seconds: 5));
        }
      }
    } catch (e) {
      debugPrint('Direct Supabase saveMataKuliah error: $e');
    }

    final body = {
      'id': mkId,
      'nama': matkul['nama'],
      'sks': matkul['sks'] ?? 3,
      'semester': smtVal,
      'semester_angka': smtVal,
      'semester_id': smtId,
      'jurusan_nama': matkul['jurusan'],
      'fakultas_nama': matkul['fakultas'],
      'dosen_id': matkul['dosenId'] ?? matkul['dosen_id'] ?? 'DOS001',
      'dosen_nama': matkul['dosen'],
      'kelas': kList,
      'kebutuhan_tipe_ruangan':
          matkul['kebutuhan_tipe_ruangan'] ??
          matkul['kebutuhanTipeRuangan'] ??
          'Kelas Teori',
    };

    // 3. Send to Backend Python
    try {
      await _httpHelper.makeOnlineRequest(
        '/master/mata_kuliah.php',
        method: 'POST',
        body: body,
      );
    } catch (_) {}
  }

  /// DELETE Master Data Mata Kuliah (Cascade Permanently)
  Future<void> deleteMataKuliah(String mkId) async {
    // 0. Cascade delete and record in local storage
    await MockDatabase.cascadeDeleteMatkul(mkId);

    // 1. Supabase Cloud (Cascade Deletes)
    try {
      // Hapus mata_kuliah_kelas
      await http
          .delete(
            Uri.parse(
              '${ApiConfig.supabaseUrl}/rest/v1/mata_kuliah_kelas?mata_kuliah_id=eq.$mkId',
            ),
            headers: {
              'apikey': ApiConfig.supabasePublishableKey,
              'Authorization': 'Bearer ${ApiConfig.supabasePublishableKey}',
            },
          )
          .timeout(const Duration(seconds: 5));

      // Hapus jadwal_final & ajuan_pengajaran
      await http
          .delete(
            Uri.parse(
              '${ApiConfig.supabaseUrl}/rest/v1/jadwal_final?mata_kuliah_id=eq.$mkId',
            ),
            headers: {
              'apikey': ApiConfig.supabasePublishableKey,
              'Authorization': 'Bearer ${ApiConfig.supabasePublishableKey}',
            },
          )
          .timeout(const Duration(seconds: 5));

      await http
          .delete(
            Uri.parse(
              '${ApiConfig.supabaseUrl}/rest/v1/ajuan_pengajaran?mata_kuliah_id=eq.$mkId',
            ),
            headers: {
              'apikey': ApiConfig.supabasePublishableKey,
              'Authorization': 'Bearer ${ApiConfig.supabasePublishableKey}',
            },
          )
          .timeout(const Duration(seconds: 5));

      final uri = Uri.parse(
        '${ApiConfig.supabaseUrl}/rest/v1/mata_kuliah?id=eq.$mkId',
      );
      await http
          .delete(
            uri,
            headers: {
              'apikey': ApiConfig.supabasePublishableKey,
              'Authorization': 'Bearer ${ApiConfig.supabasePublishableKey}',
            },
          )
          .timeout(const Duration(seconds: 8));
    } catch (_) {}

    // 2. Backend Python
    try {
      await _httpHelper.makeOnlineRequest(
        '/master/mata_kuliah.php?id=$mkId',
        method: 'DELETE',
      );
      await _httpHelper.makeOnlineRequest(
        '/master/mata_kuliah.php',
        method: 'POST',
        body: {'action': 'delete', 'id': mkId},
      );
    } catch (_) {}
  }

  /// GET Demo Users for Role Switching
  List<UserModel> getDemoUsers() {
    return List.unmodifiable(
      MockDatabase.demoUsers.where(
        (u) => !MockDatabase.deletedUserIds.contains(u.id),
      ),
    );
  }

  /// Force clear local cache and pull pure ground-truth master data from Supabase
  Future<void> forceSyncAllMasterDataFromSupabase() async {
    await Future.wait([
      getAllUsers(),
      getGedungList(),
      getRuanganList(),
      getAllMataKuliah(),
      getFakultasList(),
      getSlotWaktu(),
    ]);
  }
}
