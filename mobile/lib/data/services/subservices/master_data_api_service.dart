import 'dart:convert';
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
    // 1. Coba lewat backend Python
    try {
      final data = await _httpHelper.makeOnlineRequest('/master/mata_kuliah.php');
      if (data is Map && data['status'] == 'success' && data['data'] != null) {
        return (data['data'] as List).map((mk) => MataKuliahModel.fromJson(mk)).toList();
      }
    } catch (_) {}

    // 2. Direct Supabase Cloud Fallback
    try {
      final uri = Uri.parse('${ApiConfig.supabaseUrl}/rest/v1/mata_kuliah?select=*');
      final resp = await http.get(
        uri,
        headers: {
          'apikey': ApiConfig.supabasePublishableKey,
          'Authorization': 'Bearer ${ApiConfig.supabasePublishableKey}',
          'Accept': 'application/json',
        },
      ).timeout(const Duration(seconds: 8));

      if (resp.statusCode == 200) {
        final decoded = jsonDecode(resp.body);
        if (decoded is List && decoded.isNotEmpty) {
          return decoded.map((mk) => MataKuliahModel.fromJson(Map<String, dynamic>.from(mk))).toList();
        }
      }
    } catch (e) {
      debugPrint('Direct Supabase getAllMataKuliah error: $e');
    }

    return [];
  }

  /// GET /api/master/mata_kuliah.php
  Future<List<MataKuliahModel>> getMataKuliah(String dosenId) async {
    try {
      final url = (dosenId.isNotEmpty && dosenId != 'Semua')
          ? '/master/mata_kuliah.php?dosen_id=$dosenId&dosenId=$dosenId'
          : '/master/mata_kuliah.php';
      final data = await _httpHelper.makeOnlineRequest(url);
      if (data is Map && data['status'] == 'success' && data['data'] != null) {
        final list = (data['data'] as List).map((mk) => MataKuliahModel.fromJson(mk)).toList();
        if (list.isNotEmpty) return list;
      }
    } catch (_) {}

    // Direct Supabase Cloud Fallback
    try {
      final filter = (dosenId.isNotEmpty && dosenId != 'Semua') ? '?dosen_id=eq.$dosenId&select=*' : '?select=*';
      final uri = Uri.parse('${ApiConfig.supabaseUrl}/rest/v1/mata_kuliah$filter');
      final resp = await http.get(
        uri,
        headers: {
          'apikey': ApiConfig.supabasePublishableKey,
          'Authorization': 'Bearer ${ApiConfig.supabasePublishableKey}',
          'Accept': 'application/json',
        },
      ).timeout(const Duration(seconds: 8));

      if (resp.statusCode == 200) {
        final decoded = jsonDecode(resp.body);
        if (decoded is List && decoded.isNotEmpty) {
          return decoded.map((mk) => MataKuliahModel.fromJson(Map<String, dynamic>.from(mk))).toList();
        }
      }

      // Check User's assigned matkul_nama in Supabase
      if (dosenId.isNotEmpty && dosenId != 'Semua') {
        final userUri = Uri.parse(
          '${ApiConfig.supabaseUrl}/rest/v1/users?or=(id.eq.${Uri.encodeComponent(dosenId)},email.ilike.${Uri.encodeComponent(dosenId)})&select=*'
        );
        final uResp = await http.get(
          userUri,
          headers: {
            'apikey': ApiConfig.supabasePublishableKey,
            'Authorization': 'Bearer ${ApiConfig.supabasePublishableKey}',
            'Accept': 'application/json',
          },
        ).timeout(const Duration(seconds: 6));

        if (uResp.statusCode == 200) {
          final uDecoded = jsonDecode(uResp.body);
          if (uDecoded is List && uDecoded.isNotEmpty) {
            final uMap = uDecoded.first;
            final matkulStr = (uMap['matkul_nama'] ?? uMap['matkulNama'] ?? '').toString().trim();
            if (matkulStr.isNotEmpty) {
              final result = <MataKuliahModel>[];
              final parts = matkulStr.split(',').map((s) => s.trim()).where((s) => s.isNotEmpty);
              int idx = 1;
              for (final part in parts) {
                final cleanName = part.contains('-') ? part.split('-').last.trim() : part;
                result.add(
                  MataKuliahModel(
                    id: 'MK_${dosenId}_$idx',
                    nama: cleanName,
                    sks: 3,
                    jurusanId: uMap['jurusan_id']?.toString() ?? 'JUR001',
                    jurusanNama: uMap['jurusan_nama']?.toString() ?? 'Teknik Informatika',
                    fakultasNama: uMap['fakultas_nama']?.toString() ?? 'Fakultas Sains & Teknologi',
                    dosenId: dosenId,
                    dosenNama: uMap['nama']?.toString() ?? 'Dosen Pengampu',
                    semesterId: 'SEM001',
                    kebutuhanTipeRuangan: 'Kelas Teori',
                    kelasIds: ['${dosenId}_KLS_1', '${dosenId}_KLS_2'],
                    kelasNama: const ['Kelas A', 'Kelas B'],
                  ),
                );
                idx++;
              }
              if (result.isNotEmpty) return result;
            }
          }
        }
      }
    } catch (_) {}

    return [];
  }

  /// GET slot waktu master data
  Future<List<SlotWaktuModel>> getSlotWaktu() async {
    // 1. Coba lewat backend Python
    try {
      final data = await _httpHelper.makeOnlineRequest('/master/slot_waktu.php');
      if (data is Map && data['status'] == 'success' && data['data'] != null) {
        return (data['data'] as List).map((s) => SlotWaktuModel.fromJson(Map<String, dynamic>.from(s))).toList();
      }
    } catch (_) {}

    // 2. Direct Supabase Cloud Fallback
    try {
      final uri = Uri.parse('${ApiConfig.supabaseUrl}/rest/v1/slot_waktu?select=*');
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
          return decoded.map((s) => SlotWaktuModel.fromJson(Map<String, dynamic>.from(s))).toList();
        }
      }
    } catch (_) {}

    await Future.delayed(const Duration(milliseconds: 150));
    return MockDatabase.slotWaktu;
  }

  /// GET all users / lecturers
  Future<List<UserModel>> getAllUsers() async {
    // 1. Coba lewat backend Python
    try {
      final data = await _httpHelper.makeOnlineRequest('/master/users.php');
      if (data is Map && data['status'] == 'success' && data['data'] != null) {
        return (data['data'] as List).map((u) => UserModel.fromJson(u)).toList();
      }
    } catch (_) {}

    // 2. Direct Supabase Cloud Fallback
    try {
      final uri = Uri.parse('${ApiConfig.supabaseUrl}/rest/v1/users?select=*');
      final resp = await http.get(
        uri,
        headers: {
          'apikey': ApiConfig.supabasePublishableKey,
          'Authorization': 'Bearer ${ApiConfig.supabasePublishableKey}',
          'Accept': 'application/json',
        },
      ).timeout(const Duration(seconds: 8));

      if (resp.statusCode == 200) {
        final decoded = jsonDecode(resp.body);
        if (decoded is List && decoded.isNotEmpty) {
          return decoded.map((u) => UserModel.fromJson(Map<String, dynamic>.from(u))).toList();
        }
      }
    } catch (e) {
      debugPrint('Direct Supabase getAllUsers error: $e');
    }

    return [];
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
      final uri = Uri.parse('${ApiConfig.supabaseUrl}/rest/v1/users?id=eq.$dosenId');
      await http.patch(
        uri,
        headers: {
          'apikey': ApiConfig.supabasePublishableKey,
          'Authorization': 'Bearer ${ApiConfig.supabasePublishableKey}',
          'Content-Type': 'application/json',
        },
        body: jsonEncode({'is_priority': priority}),
      ).timeout(const Duration(seconds: 8));
    } catch (_) {}
  }

  /// Create / Register new Dosen with email & login credentials
  Future<UserModel> createDosen(UserModel dosen, {String password = 'password123'}) async {
    // 1. Send to Backend Python
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
          'matkul_nama': dosen.matkulNama ?? '',
          'matkulNama': dosen.matkulNama ?? '',
          'is_priority': dosen.isPriority ? 1 : 0,
        },
      );
      if (data is Map && data['status'] == 'success' && data['data'] != null) {
        // Updated from backend
      }
    } catch (_) {}

    // 2. Direct Supabase Cloud Persistence
    try {
      // Check if user already exists by ID or email
      final checkUri = Uri.parse(
        '${ApiConfig.supabaseUrl}/rest/v1/users?or=(id.eq.${dosen.id},email.eq.${dosen.email})&select=id,role'
      );
      final checkResp = await http.get(
        checkUri,
        headers: {
          'apikey': ApiConfig.supabasePublishableKey,
          'Authorization': 'Bearer ${ApiConfig.supabasePublishableKey}',
          'Accept': 'application/json',
        },
      ).timeout(const Duration(seconds: 6));

      bool userExists = false;
      String targetId = dosen.id;
      if (checkResp.statusCode == 200) {
        final decoded = jsonDecode(checkResp.body);
        if (decoded is List && decoded.isNotEmpty) {
          userExists = true;
          targetId = decoded[0]['id']?.toString() ?? dosen.id;
        }
      }

      final payload = {
        'id': targetId,
        'nama': dosen.nama,
        'email': dosen.email,
        'password': password,
        'role': dosen.role,
        'jurusan_id': dosen.jurusanId.isNotEmpty ? dosen.jurusanId : 'JUR001',
        'jurusan_nama': dosen.jurusanNama,
        'fakultas_nama': dosen.fakultasNama,
        'is_priority': dosen.isPriority,
        'matkul_nama': dosen.matkulNama ?? '',
      };

      if (userExists) {
        final patchUri = Uri.parse('${ApiConfig.supabaseUrl}/rest/v1/users?id=eq.$targetId');
        await http.patch(
          patchUri,
          headers: {
            'apikey': ApiConfig.supabasePublishableKey,
            'Authorization': 'Bearer ${ApiConfig.supabasePublishableKey}',
            'Content-Type': 'application/json',
          },
          body: jsonEncode(payload),
        ).timeout(const Duration(seconds: 8));
      } else {
        final postUri = Uri.parse('${ApiConfig.supabaseUrl}/rest/v1/users');
        await http.post(
          postUri,
          headers: {
            'apikey': ApiConfig.supabasePublishableKey,
            'Authorization': 'Bearer ${ApiConfig.supabasePublishableKey}',
            'Content-Type': 'application/json',
            'Prefer': 'resolution=merge-duplicates',
          },
          body: jsonEncode(payload),
        ).timeout(const Duration(seconds: 8));
      }

      // Link courses to this dosen in Supabase if matkulNama is specified
      if (dosen.matkulNama != null && dosen.matkulNama!.isNotEmpty) {
        final matkulItems = dosen.matkulNama!.split(',').map((s) => s.trim()).where((s) => s.isNotEmpty);
        for (final item in matkulItems) {
          final cleanTitle = item.contains('-') ? item.split('-').last.trim() : item;
          if (cleanTitle.isNotEmpty) {
            final mkPatchUri = Uri.parse(
              '${ApiConfig.supabaseUrl}/rest/v1/mata_kuliah?nama=ilike.%25${Uri.encodeComponent(cleanTitle)}%25'
            );
            await http.patch(
              mkPatchUri,
              headers: {
                'apikey': ApiConfig.supabasePublishableKey,
                'Authorization': 'Bearer ${ApiConfig.supabasePublishableKey}',
                'Content-Type': 'application/json',
              },
              body: jsonEncode({
                'dosen_id': targetId,
                'dosen_nama': dosen.nama,
              }),
            ).timeout(const Duration(seconds: 5));
          }
        }
      }
    } catch (e) {
      debugPrint('Direct Supabase createDosen error: $e');
    }

    return dosen;
  }

  /// Delete Dosen / User (Cascade)
  Future<void> deleteUser(String userId) async {
    // 1. Backend Python
    try {
      await _httpHelper.makeOnlineRequest(
        '/master/users.php',
        method: 'POST',
        body: {'action': 'delete', 'id': userId},
      );
    } catch (_) {}

    // 2. Direct Supabase Cloud
    try {
      final uri = Uri.parse('${ApiConfig.supabaseUrl}/rest/v1/users?id=eq.$userId');
      await http.delete(
        uri,
        headers: {
          'apikey': ApiConfig.supabasePublishableKey,
          'Authorization': 'Bearer ${ApiConfig.supabasePublishableKey}',
        },
      ).timeout(const Duration(seconds: 8));
    } catch (_) {}
  }

  /// GET Master Data Gedung List
  Future<List<GedungModel>> getGedungList() async {
    try {
      final data = await _httpHelper.makeOnlineRequest('/master/gedung.php');
      if (data is Map && data['status'] == 'success' && data['data'] != null) {
        return (data['data'] as List).map((g) => GedungModel.fromJson(g)).toList();
      }
    } catch (_) {}

    // Direct Supabase Cloud Fallback
    try {
      final uri = Uri.parse('${ApiConfig.supabaseUrl}/rest/v1/gedung?select=*');
      final resp = await http.get(
        uri,
        headers: {
          'apikey': ApiConfig.supabasePublishableKey,
          'Authorization': 'Bearer ${ApiConfig.supabasePublishableKey}',
          'Accept': 'application/json',
        },
      ).timeout(const Duration(seconds: 8));

      if (resp.statusCode == 200) {
        final decoded = jsonDecode(resp.body);
        if (decoded is List && decoded.isNotEmpty) {
          return decoded.map((g) => GedungModel.fromJson(Map<String, dynamic>.from(g))).toList();
        }
      }
    } catch (_) {}

    return [];
  }

  /// ADD Master Data Gedung
  Future<GedungModel> addGedung(GedungModel gedung) async {
    // 1. Backend Python
    try {
      await _httpHelper.makeOnlineRequest(
        '/master/gedung.php',
        method: 'POST',
        body: gedung.toJson(),
      );
    } catch (_) {}

    // 2. Direct Supabase Cloud
    try {
      final uri = Uri.parse('${ApiConfig.supabaseUrl}/rest/v1/gedung');
      await http.post(
        uri,
        headers: {
          'apikey': ApiConfig.supabasePublishableKey,
          'Authorization': 'Bearer ${ApiConfig.supabasePublishableKey}',
          'Content-Type': 'application/json',
          'Prefer': 'resolution=merge-duplicates',
        },
        body: jsonEncode(gedung.toJson()),
      ).timeout(const Duration(seconds: 8));
    } catch (_) {}

    return gedung;
  }

  /// DELETE Master Data Gedung (Cascade)
  Future<void> deleteGedung(String gedungId) async {
    // 1. Backend Python
    try {
      await _httpHelper.makeOnlineRequest('/master/gedung.php?id=$gedungId', method: 'DELETE');
      await _httpHelper.makeOnlineRequest(
        '/master/gedung.php',
        method: 'POST',
        body: {'action': 'delete', 'id': gedungId},
      );
    } catch (_) {}

    // 2. Direct Supabase Cloud
    try {
      final uri = Uri.parse('${ApiConfig.supabaseUrl}/rest/v1/gedung?id=eq.$gedungId');
      await http.delete(
        uri,
        headers: {
          'apikey': ApiConfig.supabasePublishableKey,
          'Authorization': 'Bearer ${ApiConfig.supabasePublishableKey}',
        },
      ).timeout(const Duration(seconds: 8));
    } catch (_) {}
  }

  /// GET Master Data Ruangan List
  Future<List<RuanganModel>> getRuanganList() async {
    try {
      final data = await _httpHelper.makeOnlineRequest('/master/ruangan.php');
      if (data is Map && data['status'] == 'success' && data['data'] != null) {
        return (data['data'] as List).map((r) => RuanganModel.fromJson(r)).toList();
      }
    } catch (_) {}

    // Direct Supabase Cloud Fallback
    try {
      final uri = Uri.parse('${ApiConfig.supabaseUrl}/rest/v1/ruangan?select=*');
      final resp = await http.get(
        uri,
        headers: {
          'apikey': ApiConfig.supabasePublishableKey,
          'Authorization': 'Bearer ${ApiConfig.supabasePublishableKey}',
          'Accept': 'application/json',
        },
      ).timeout(const Duration(seconds: 8));

      if (resp.statusCode == 200) {
        final decoded = jsonDecode(resp.body);
        if (decoded is List && decoded.isNotEmpty) {
          return decoded.map((r) => RuanganModel.fromJson(Map<String, dynamic>.from(r))).toList();
        }
      }
    } catch (_) {}

    return [];
  }

  /// ADD Master Data Ruangan
  Future<RuanganModel> addRuangan(RuanganModel ruangan) async {
    MockDatabase.deletedRuanganIds.remove(ruangan.id);
    MockDatabase.deletedRuanganIds.remove(ruangan.nama);
    MockDatabase.ruanganList.removeWhere((r) => r.id == ruangan.id || (r.nama.toLowerCase() == ruangan.nama.toLowerCase() && (r.gedungId == ruangan.gedungId || r.gedungNama.toLowerCase() == ruangan.gedungNama.toLowerCase())));
    MockDatabase.ruanganList.add(ruangan);
    await MockDatabase.saveLocalRuangan();

    // 1. Backend Python
    if (!ApiConfig.useMockBackend) {
      try {
        await _httpHelper.makeOnlineRequest(
          '/master/ruangan.php',
          method: 'POST',
          body: ruangan.toJson(),
        );
      } catch (_) {}
    }

    // 2. Direct Supabase Cloud
    try {
      final uri = Uri.parse('${ApiConfig.supabaseUrl}/rest/v1/ruangan');
      await http.post(
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
          'gedung_id': ruangan.gedungId,
          'kapasitas': ruangan.kapasitas,
          'tipe_ruangan': ruangan.tipeRuangan,
        }),
      ).timeout(const Duration(seconds: 8));
    } catch (_) {}

    await Future.delayed(const Duration(milliseconds: 100));
    return ruangan;
  }

  /// DELETE Master Data Ruangan (Cascade)
  Future<void> deleteRuangan(String ruanganId) async {
    await MockDatabase.cascadeDeleteRuangan(ruanganId);
    // 1. Backend Python
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

    // 2. Direct Supabase Cloud
    try {
      final uri = Uri.parse('${ApiConfig.supabaseUrl}/rest/v1/ruangan?id=eq.$ruanganId');
      await http.delete(
        uri,
        headers: {
          'apikey': ApiConfig.supabasePublishableKey,
          'Authorization': 'Bearer ${ApiConfig.supabasePublishableKey}',
        },
      ).timeout(const Duration(seconds: 8));
    } catch (_) {}

    await Future.delayed(const Duration(milliseconds: 150));
  }

  /// SAVE / UPDATE Master Data Mata Kuliah
  Future<void> saveMataKuliah(Map<String, dynamic> matkul) async {
    final mkId = (matkul['id'] ?? matkul['kode'] ?? '').toString();
    final body = {
      'id': mkId,
      'nama': matkul['nama'],
      'sks': matkul['sks'] ?? 3,
      'jurusan_nama': matkul['jurusan'],
      'fakultas_nama': matkul['fakultas'],
      'dosen_id': matkul['dosenId'] ?? matkul['dosen_id'] ?? 'DOS001',
      'dosen_nama': matkul['dosen'],
      'kelas': matkul['kelas'],
    };

    // 1. Send to Backend Python
    try {
      await _httpHelper.makeOnlineRequest(
        '/master/mata_kuliah.php',
        method: 'POST',
        body: body,
      );
    } catch (_) {}

    // 2. Direct upsert to Supabase
    try {
      final uri = Uri.parse('${ApiConfig.supabaseUrl}/rest/v1/mata_kuliah');
      await http.post(
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
          'jurusan_id': matkul['jurusan_id'] ?? 'JUR001',
          'jurusan_nama': matkul['jurusan'] ?? 'Teknik Informatika',
          'fakultas_nama': matkul['fakultas'] ?? 'Fakultas Sains dan Teknologi',
          'dosen_id': matkul['dosenId'] ?? matkul['dosen_id'] ?? 'DOS001',
          'dosen_nama': matkul['dosen'] ?? '',
        }),
      ).timeout(const Duration(seconds: 8));
    } catch (_) {}
  }

  /// DELETE Master Data Mata Kuliah
  Future<void> deleteMataKuliah(String mkId) async {
    // 1. Backend Python
    try {
      await _httpHelper.makeOnlineRequest(
        '/master/mata_kuliah.php',
        method: 'POST',
        body: {'action': 'delete', 'id': mkId},
      );
    } catch (_) {}

    // 2. Supabase Cloud
    try {
      final uri = Uri.parse('${ApiConfig.supabaseUrl}/rest/v1/mata_kuliah?id=eq.$mkId');
      await http.delete(
        uri,
        headers: {
          'apikey': ApiConfig.supabasePublishableKey,
          'Authorization': 'Bearer ${ApiConfig.supabasePublishableKey}',
        },
      ).timeout(const Duration(seconds: 8));
    } catch (_) {}
  }

  /// GET Demo Users for Role Switching
  List<UserModel> getDemoUsers() {
    return List.unmodifiable(MockDatabase.demoUsers.where((u) => !MockDatabase.deletedUserIds.contains(u.id)));
  }
}
