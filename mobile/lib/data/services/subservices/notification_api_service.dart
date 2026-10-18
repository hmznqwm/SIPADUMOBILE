import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import '../../../config/api_config.dart';
import '../../models/notification_model.dart';
import '../../mock/mock_database.dart';
import 'api_http_helper.dart';

class NotificationApiService {
  final ApiHttpHelper _httpHelper;

  static const String _spReadIdsKey = 'sp_read_notif_ids';
  static const String _spDeletedIdsKey = 'sp_deleted_notif_ids';
  static const String _spCustomNotifsKey = 'sp_custom_notifications';

  NotificationApiService({ApiHttpHelper? httpHelper})
      : _httpHelper = httpHelper ?? ApiHttpHelper();

  // ── Helper SharedPreferences Persistence ──

  Future<Set<String>> _getReadIds() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final list = prefs.getStringList(_spReadIdsKey) ?? [];
      return list.toSet();
    } catch (_) {
      return {};
    }
  }

  Future<void> _saveReadIds(Set<String> ids) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setStringList(_spReadIdsKey, ids.toList());
    } catch (_) {}
  }

  Future<Set<String>> _getDeletedIds() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final list = prefs.getStringList(_spDeletedIdsKey) ?? [];
      return list.toSet();
    } catch (_) {
      return {};
    }
  }

  Future<void> _saveDeletedIds(Set<String> ids) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setStringList(_spDeletedIdsKey, ids.toList());
    } catch (_) {}
  }

  Future<List<NotificationModel>> _getCustomStoredNotifications() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final list = prefs.getStringList(_spCustomNotifsKey) ?? [];
      return list.map((item) {
        final decoded = jsonDecode(item);
        return NotificationModel.fromJson(Map<String, dynamic>.from(decoded));
      }).toList();
    } catch (_) {
      return [];
    }
  }

  Future<void> _saveCustomNotifications(List<NotificationModel> notifs) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final list = notifs.map((n) => jsonEncode(n.toJson())).toList();
      await prefs.setStringList(_spCustomNotifsKey, list);
    } catch (_) {}
  }

  // ── DYNAMIC GENERATION: Real notifications from actual live state ──

  List<NotificationModel> _generateDynamicNotificationsForUser(String userId) {
    final user = MockDatabase.demoUsers.where((u) => u.id.toLowerCase() == userId.toLowerCase().trim()).firstOrNull;
    final role = user?.role ?? (userId.startsWith('ADM') ? 'admin' : (userId.startsWith('DKN') ? 'dekan' : (userId.startsWith('KJR') ? 'kajur' : 'dosen')));
    final userName = user?.nama ?? '';
    final userJurusan = user?.jurusanNama ?? '';
    final userFakultas = user?.fakultasNama ?? '';

    final dynamicNotifs = <NotificationModel>[];

    // 1. Dosen Role Notifications
    if (role == 'dosen') {
      final myAjuans = MockDatabase.ajuanPengajaranList.where((a) {
        return a.dosenId.toLowerCase() == userId.toLowerCase() ||
            (userName.isNotEmpty && a.dosenNama.toLowerCase().contains(userName.toLowerCase()));
      }).toList();

      for (final aj in myAjuans) {
        final baseId = 'NOTIF_AJ_${aj.id}_${aj.status}';
        final ajDate = aj.updatedAt ?? aj.submittedAt;

        switch (aj.status) {
          case 'disetujui_admin':
          case 'terjadwal_resmi':
            dynamicNotifs.add(NotificationModel(
              id: baseId,
              judul: 'Jadwal Resmi Disetujui Admin',
              pesan: 'Jadwal mata kuliah ${aj.mataKuliahNama} (${aj.kelasNama}) di ruang ${aj.ruanganNama} pada hari ${aj.hari}, ${aj.waktuFormatted} telah resmi disetujui.',
              tipe: 'success',
              timestamp: ajDate,
            ));
            break;
          case 'menunggu_admin':
          case 'disetujui_dekan':
            dynamicNotifs.add(NotificationModel(
              id: baseId,
              judul: 'Persetujuan Dekan Fakultas',
              pesan: 'Pengajuan ${aj.mataKuliahNama} (${aj.kelasNama}) telah disetujui Dekan Fakultas dan diteruskan ke Super Admin.',
              tipe: 'approval',
              timestamp: ajDate,
            ));
            break;
          case 'menunggu_dekan':
          case 'diverifikasi_kaprodi':
            dynamicNotifs.add(NotificationModel(
              id: baseId,
              judul: 'Ajuan Diverifikasi KaProdi',
              pesan: 'Pengajuan ${aj.mataKuliahNama} (${aj.kelasNama}) telah diverifikasi oleh KaProdi dan menunggu persetujuan Dekan.',
              tipe: 'approval',
              timestamp: ajDate,
            ));
            break;
          case 'menunggu_kaprodi':
          case 'diajukan':
          case 'draft':
            dynamicNotifs.add(NotificationModel(
              id: baseId,
              judul: 'Pengajuan Jadwal Terkirim',
              pesan: 'Pengajuan jadwal mata kuliah ${aj.mataKuliahNama} (${aj.sks} SKS, ${aj.kelasNama}) berhasil diajukan ke KaProdi.',
              tipe: 'info',
              timestamp: ajDate,
            ));
            break;
          case 'ditolak_kaprodi':
          case 'ditolak_dekan':
          case 'ditolak_admin':
            final alasan = aj.alasanPenolakan ?? aj.catatanKaProdi ?? aj.catatanDekan ?? aj.catatanAdmin ?? 'Perlu penyesuaian jadwal.';
            dynamicNotifs.add(NotificationModel(
              id: baseId,
              judul: 'Pengajuan Jadwal Ditolak',
              pesan: 'Pengajuan mata kuliah ${aj.mataKuliahNama} (${aj.kelasNama}) ditolak: $alasan',
              tipe: 'warning',
              timestamp: ajDate,
            ));
            break;
          case 'menunggu_banding':
          case 'banding_diajukan':
            dynamicNotifs.add(NotificationModel(
              id: baseId,
              judul: 'Permohonan Banding Sedang Ditinjau',
              pesan: 'Permohonan banding jadwal untuk mata kuliah ${aj.mataKuliahNama} (${aj.alasanBanding ?? 'Penyesuaian jam'}) sedang dalam proses peninjauan.',
              tipe: 'info',
              timestamp: ajDate,
            ));
            break;
          case 'banding_disetujui':
            dynamicNotifs.add(NotificationModel(
              id: baseId,
              judul: 'Permohonan Banding Disetujui',
              pesan: 'Permohonan banding untuk mata kuliah ${aj.mataKuliahNama} telah disetujui. Jadwal telah disesuaikan.',
              tipe: 'success',
              timestamp: ajDate,
            ));
            break;
          case 'banding_ditolak':
            dynamicNotifs.add(NotificationModel(
              id: baseId,
              judul: 'Permohonan Banding Ditolak',
              pesan: 'Permohonan banding mata kuliah ${aj.mataKuliahNama} ditolak: ${aj.catatanAdmin ?? '-'}',
              tipe: 'warning',
              timestamp: ajDate,
            ));
            break;
          case 'bentrok_terdeteksi':
            dynamicNotifs.add(NotificationModel(
              id: baseId,
              judul: 'Peringatan Bentrok Jadwal',
              pesan: 'Terdeteksi bentrok pada jadwal ${aj.mataKuliahNama}: ${aj.bentrokDetail ?? 'Konflik alokasi ruangan/jam'}.',
              tipe: 'conflict',
              timestamp: ajDate,
            ));
            break;
        }
      }
    }

    // 2. KaProdi (Kajur) Role Notifications
    else if (role == 'kajur') {
      final prodiAjuans = MockDatabase.ajuanPengajaranList.where((a) {
        if (userJurusan.isNotEmpty) {
          return a.jurusanNama.toLowerCase().contains(userJurusan.toLowerCase()) ||
              userJurusan.toLowerCase().contains(a.jurusanNama.toLowerCase());
        }
        return true;
      }).toList();

      for (final aj in prodiAjuans) {
        final ajDate = aj.updatedAt ?? aj.submittedAt;
        if (aj.status == 'menunggu_kaprodi' || aj.status == 'diajukan') {
          dynamicNotifs.add(NotificationModel(
            id: 'NOTIF_KJR_INCOMING_${aj.id}',
            judul: 'Ajuan Baru Masuk Prodi',
            pesan: '${aj.dosenNama} mengajukan jadwal mata kuliah ${aj.mataKuliahNama} (${aj.sks} SKS, ${aj.kelasNama}) di ruang ${aj.ruanganNama}.',
            tipe: 'info',
            timestamp: ajDate,
          ));
        } else if (aj.status == 'menunggu_banding') {
          dynamicNotifs.add(NotificationModel(
            id: 'NOTIF_KJR_BANDING_${aj.id}',
            judul: 'Permohonan Banding Dosen',
            pesan: '${aj.dosenNama} mengajukan banding untuk mata kuliah ${aj.mataKuliahNama}: ${aj.alasanBanding ?? 'Penyesuaian jam'}',
            tipe: 'warning',
            timestamp: ajDate,
          ));
        } else if (aj.status == 'bentrok_terdeteksi') {
          dynamicNotifs.add(NotificationModel(
            id: 'NOTIF_KJR_BENTROK_${aj.id}',
            judul: 'Bentrok Jadwal Dosen Prodi',
            pesan: 'Terdeteksi bentrok ruangan/waktu pada ajuan ${aj.dosenNama} (${aj.mataKuliahNama}, ${aj.hari}).',
            tipe: 'conflict',
            timestamp: ajDate,
          ));
        } else if (aj.status == 'disetujui_admin') {
          dynamicNotifs.add(NotificationModel(
            id: 'NOTIF_KJR_APPROVED_${aj.id}',
            judul: 'Jadwal Dosen Disahkan',
            pesan: 'Jadwal perkuliahan ${aj.mataKuliahNama} (${aj.dosenNama}) telah resmi disahkan Admin.',
            tipe: 'success',
            timestamp: ajDate,
          ));
        }
      }
    }

    // 3. Dekan Role Notifications
    else if (role == 'dekan') {
      final fstAjuans = MockDatabase.ajuanPengajaranList.where((a) {
        if (userFakultas.isNotEmpty) {
          return a.fakultasNama.toLowerCase().contains(userFakultas.toLowerCase()) ||
              userFakultas.toLowerCase().contains(a.fakultasNama.toLowerCase());
        }
        return true;
      }).toList();

      for (final aj in fstAjuans) {
        final ajDate = aj.updatedAt ?? aj.submittedAt;
        if (aj.status == 'menunggu_dekan' || aj.status == 'diverifikasi_kaprodi') {
          dynamicNotifs.add(NotificationModel(
            id: 'NOTIF_DKN_INCOMING_${aj.id}',
            judul: 'Verifikasi Masuk dari KaProdi',
            pesan: 'KaProdi telah memverifikasi ajuan jadwal ${aj.mataKuliahNama} (${aj.dosenNama}) untuk persetujuan tingkat Fakultas.',
            tipe: 'approval',
            timestamp: ajDate,
          ));
        } else if (aj.status == 'menunggu_banding') {
          dynamicNotifs.add(NotificationModel(
            id: 'NOTIF_DKN_BANDING_${aj.id}',
            judul: 'Eskalasi Banding Dosen Fakultas',
            pesan: 'Dosen ${aj.dosenNama} (${aj.jurusanNama}) mengajukan permohonan banding jadwal ${aj.mataKuliahNama}.',
            tipe: 'warning',
            timestamp: ajDate,
          ));
        } else if (aj.status == 'disetujui_admin') {
          dynamicNotifs.add(NotificationModel(
            id: 'NOTIF_DKN_APPROVED_${aj.id}',
            judul: 'Jadwal Fakultas Terbit Resmi',
            pesan: 'Jadwal perkuliahan ${aj.mataKuliahNama} (${aj.dosenNama}) telah difinalisasi secara resmi oleh Admin.',
            tipe: 'success',
            timestamp: ajDate,
          ));
        }
      }
    }

    // 4. Admin Role Notifications
    else if (role == 'admin') {
      for (final aj in MockDatabase.ajuanPengajaranList) {
        final ajDate = aj.updatedAt ?? aj.submittedAt;
        if (aj.status == 'menunggu_admin' || aj.status == 'disetujui_dekan') {
          dynamicNotifs.add(NotificationModel(
            id: 'NOTIF_ADM_INCOMING_${aj.id}',
            judul: 'Persetujuan Dekan Masuk',
            pesan: 'Dekan telah menyetujui ajuan ${aj.dosenNama} (${aj.mataKuliahNama}, ${aj.jurusanNama}), siap untuk finalisasi jadwal.',
            tipe: 'approval',
            timestamp: ajDate,
          ));
        } else if (aj.status == 'menunggu_banding') {
          dynamicNotifs.add(NotificationModel(
            id: 'NOTIF_ADM_BANDING_${aj.id}',
            judul: 'Permohonan Banding Jadwal',
            pesan: 'Dosen ${aj.dosenNama} mengajukan permohonan banding jadwal ${aj.mataKuliahNama}: ${aj.alasanBanding ?? 'Penyesuaian jam'}',
            tipe: 'warning',
            timestamp: ajDate,
          ));
        } else if (aj.status == 'bentrok_terdeteksi') {
          dynamicNotifs.add(NotificationModel(
            id: 'NOTIF_ADM_BENTROK_${aj.id}',
            judul: 'Konflik Jadwal Kampus',
            pesan: 'Terdeteksi bentrok jadwal pada ajuan ${aj.dosenNama} (${aj.ruanganNama}, ${aj.hari}).',
            tipe: 'conflict',
            timestamp: ajDate,
          ));
        }
      }
    }

    return dynamicNotifs;
  }

  // ── GET NOTIFICATIONS (Merged & State Filtered) ──

  Future<List<NotificationModel>> getNotifications(String dosenId) async {
    final readIds = await _getReadIds();
    final deletedIds = await _getDeletedIds();
    final customStored = await _getCustomStoredNotifications();

    final allItemsMap = <String, NotificationModel>{};

    // 1. Online backend / Supabase
    if (!ApiConfig.useMockBackend) {
      try {
        final data = await _httpHelper.makeOnlineRequest('/notifications/index.php?userId=$dosenId');
        if (data is Map && data['status'] == 'success' && data['data'] != null) {
          final list = (data['data'] as List)
              .map((n) => NotificationModel.fromJson(n))
              .toList();
          for (final n in list) {
            allItemsMap[n.id] = n;
          }
        }
      } catch (_) {}

      try {
        final uri = Uri.parse('${ApiConfig.supabaseUrl}/rest/v1/notifications?or=(user_id.eq.$dosenId,user_id.is.null,user_id.eq.GLOBAL,user_id.eq.)&order=created_at.desc');
        final resp = await http.get(
          uri,
          headers: ApiConfig.supabaseHeaders,
        ).timeout(const Duration(seconds: 6));

        if (resp.statusCode == 200) {
          final decoded = jsonDecode(resp.body);
          if (decoded is List && decoded.isNotEmpty) {
            for (final item in decoded) {
              final n = NotificationModel.fromJson(Map<String, dynamic>.from(item));
              allItemsMap[n.id] = n;
            }
          }
        }
      } catch (_) {}
    }

    // 2. Add custom persisted notifications sent through the app
    for (final n in customStored) {
      allItemsMap[n.id] = n;
    }

    // 3. Add dynamic notifications generated from actual real state
    final dynamicNotifs = _generateDynamicNotificationsForUser(dosenId);
    for (final n in dynamicNotifs) {
      allItemsMap[n.id] = n;
    }

    // 4. Apply read status and delete filters
    final result = <NotificationModel>[];
    for (final entry in allItemsMap.entries) {
      final n = entry.value;
      if (deletedIds.contains(n.id)) continue; // Filter out deleted

      final isAlreadyRead = readIds.contains(n.id) || n.isRead;
      result.add(n.copyWith(isRead: isAlreadyRead));
    }

    // 5. Sort by timestamp descending
    result.sort((a, b) => b.timestamp.compareTo(a.timestamp));
    return result;
  }

  // ── Mark Notification Read (Persistent in SharedPreferences & Cloud) ──

  Future<void> markNotificationRead(String notificationId) async {
    final readIds = await _getReadIds();
    readIds.add(notificationId);
    await _saveReadIds(readIds);

    // Update in custom stored list if present
    final customList = await _getCustomStoredNotifications();
    bool customUpdated = false;
    for (int i = 0; i < customList.length; i++) {
      if (customList[i].id == notificationId) {
        customList[i] = customList[i].copyWith(isRead: true);
        customUpdated = true;
      }
    }
    if (customUpdated) {
      await _saveCustomNotifications(customList);
    }

    // Backend Python
    if (!ApiConfig.useMockBackend) {
      try {
        await _httpHelper.makeOnlineRequest(
          '/notifications/index.php',
          method: 'PUT',
          body: {'id': notificationId, 'isRead': 1, 'action': 'mark_read'},
        );
      } catch (_) {}
    }

    // Direct Supabase Cloud
    try {
      final uri = Uri.parse('${ApiConfig.supabaseUrl}/rest/v1/notifications?id=eq.$notificationId');
      await http.patch(
        uri,
        headers: {
          'apikey': ApiConfig.supabasePublishableKey,
          'Authorization': 'Bearer ${ApiConfig.supabasePublishableKey}',
          'Content-Type': 'application/json',
        },
        body: jsonEncode({'is_read': true}),
      ).timeout(const Duration(seconds: 4));
    } catch (_) {}
  }

  // ── Mark Multiple Notifications Read ──

  Future<void> markMultipleNotificationsRead(List<String> notificationIds) async {
    final readIds = await _getReadIds();
    readIds.addAll(notificationIds);
    await _saveReadIds(readIds);

    // Update in custom stored list if present
    final customList = await _getCustomStoredNotifications();
    bool customUpdated = false;
    for (int i = 0; i < customList.length; i++) {
      if (notificationIds.contains(customList[i].id)) {
        customList[i] = customList[i].copyWith(isRead: true);
        customUpdated = true;
      }
    }
    if (customUpdated) {
      await _saveCustomNotifications(customList);
    }

    // Backend Python
    if (!ApiConfig.useMockBackend) {
      try {
        await _httpHelper.makeOnlineRequest(
          '/notifications/index.php',
          method: 'PUT',
          body: {'ids': notificationIds, 'isRead': 1, 'action': 'mark_multiple_read'},
        );
      } catch (_) {}
    }

    // Direct Supabase Cloud
    try {
      for (final nid in notificationIds) {
        final uri = Uri.parse('${ApiConfig.supabaseUrl}/rest/v1/notifications?id=eq.$nid');
        await http.patch(
          uri,
          headers: {
            'apikey': ApiConfig.supabasePublishableKey,
            'Authorization': 'Bearer ${ApiConfig.supabasePublishableKey}',
            'Content-Type': 'application/json',
          },
          body: jsonEncode({'is_read': true}),
        ).timeout(const Duration(seconds: 3));
      }
    } catch (_) {}
  }

  // ── Delete Notifications (Persistent Delete) ──

  Future<void> deleteNotifications(List<String> notificationIds) async {
    final deletedIds = await _getDeletedIds();
    deletedIds.addAll(notificationIds);
    await _saveDeletedIds(deletedIds);

    // Remove from custom stored list if present
    final customList = await _getCustomStoredNotifications();
    final lenBefore = customList.length;
    customList.removeWhere((n) => notificationIds.contains(n.id));
    if (customList.length != lenBefore) {
      await _saveCustomNotifications(customList);
    }

    // Backend Python
    if (!ApiConfig.useMockBackend) {
      try {
        await _httpHelper.makeOnlineRequest(
          '/notifications/index.php',
          method: 'DELETE',
          body: {'ids': notificationIds},
        );
      } catch (_) {}
    }

    // Direct Supabase Cloud
    try {
      for (final nid in notificationIds) {
        final uri = Uri.parse('${ApiConfig.supabaseUrl}/rest/v1/notifications?id=eq.$nid');
        await http.delete(
          uri,
          headers: {
            'apikey': ApiConfig.supabasePublishableKey,
            'Authorization': 'Bearer ${ApiConfig.supabasePublishableKey}',
          },
        ).timeout(const Duration(seconds: 3));
      }
    } catch (_) {}
  }

  // ── Mark All Notifications Read ──

  Future<void> markAllNotificationsRead(String? userId) async {
    if (userId != null && userId.isNotEmpty) {
      final notifs = await getNotifications(userId);
      final allIds = notifs.map((n) => n.id).toList();
      await markMultipleNotificationsRead(allIds);
    }
  }

  // ── Send Notification (Persistent Storage & Distribution) ──

  Future<void> sendNotification({
    required String userId,
    required String title,
    required String message,
    String type = 'approval',
  }) async {
    final newNotif = NotificationModel(
      id: 'NOTIF_${DateTime.now().millisecondsSinceEpoch}',
      judul: title,
      pesan: message,
      tipe: type,
      timestamp: DateTime.now(),
      isRead: false,
    );

    // 1. Save to Persistent SharedPreferences Custom Notifications
    final customList = await _getCustomStoredNotifications();
    customList.insert(0, newNotif);
    await _saveCustomNotifications(customList);

    // 2. Direct Supabase Cloud
    try {
      final uri = Uri.parse('${ApiConfig.supabaseUrl}/rest/v1/notifications');
      await http.post(
        uri,
        headers: {
          'apikey': ApiConfig.supabasePublishableKey,
          'Authorization': 'Bearer ${ApiConfig.supabasePublishableKey}',
          'Content-Type': 'application/json',
        },
        body: jsonEncode({
          'id': newNotif.id,
          'user_id': userId,
          'title': newNotif.judul,
          'message': newNotif.pesan,
          'type': newNotif.tipe,
          'created_at': newNotif.timestamp.toIso8601String(),
          'is_read': false,
        }),
      ).timeout(const Duration(seconds: 5));
    } catch (_) {}
  }
}

