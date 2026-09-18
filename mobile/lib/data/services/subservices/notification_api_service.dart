import 'dart:convert';
import 'package:http/http.dart' as http;
import '../../../config/api_config.dart';
import '../../models/notification_model.dart';
import '../../mock/mock_database.dart';
import 'api_http_helper.dart';

class NotificationApiService {
  final ApiHttpHelper _httpHelper;

  NotificationApiService({ApiHttpHelper? httpHelper})
      : _httpHelper = httpHelper ?? ApiHttpHelper();

  /// GET notifications for a specific user (filtered by role)
  Future<List<NotificationModel>> getNotifications(String dosenId) async {
    // 1. Coba via Backend Python
    if (!ApiConfig.useMockBackend) {
      try {
        final data = await _httpHelper.makeOnlineRequest('/notifications/index.php?userId=$dosenId');
        if (data is Map && data['status'] == 'success' && data['data'] != null) {
          final list = (data['data'] as List)
              .map((n) => NotificationModel.fromJson(n))
              .toList();
          return list;
        }
      } catch (_) {}
    }

    // 2. Direct Supabase Cloud Fallback
    try {
      final uri = Uri.parse('${ApiConfig.supabaseUrl}/rest/v1/notifications?or=(user_id.eq.$dosenId,user_id.is.null,user_id.eq.GLOBAL,user_id.eq.)&order=created_at.desc');
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
          return decoded.map((n) => NotificationModel.fromJson(Map<String, dynamic>.from(n))).toList();
        }
      }
    } catch (_) {}

    // 3. Local Mock fallback
    await Future.delayed(const Duration(milliseconds: 150));

    final allowedIds = MockDatabase.userNotifIds[dosenId];
    if (allowedIds != null) {
      return MockDatabase.notifications
          .where((n) => allowedIds.contains(n.id))
          .toList()
        ..sort((a, b) => b.timestamp.compareTo(a.timestamp));
    }
    return MockDatabase.notifications
        .where((n) => n.id == 'NOTIF_GLOBAL')
        .toList();
  }

  /// Mark notification as read
  Future<void> markNotificationRead(String notificationId) async {
    final idx = MockDatabase.notifications.indexWhere((n) => n.id == notificationId);
    if (idx >= 0) {
      MockDatabase.notifications[idx] = MockDatabase.notifications[idx].copyWith(isRead: true);
    }
    // 1. Backend Python
    if (!ApiConfig.useMockBackend) {
      try {
        await _httpHelper.makeOnlineRequest(
          '/notifications/index.php',
          method: 'PUT',
          body: {'id': notificationId, 'isRead': 1, 'action': 'mark_read'},
        );
      } catch (_) {}
    }

    // 2. Direct Supabase Cloud
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
      ).timeout(const Duration(seconds: 6));
    } catch (_) {}

    await Future.delayed(const Duration(milliseconds: 150));
  }

  /// Mark multiple notifications as read
  Future<void> markMultipleNotificationsRead(List<String> notificationIds) async {
    for (int i = 0; i < MockDatabase.notifications.length; i++) {
      if (notificationIds.contains(MockDatabase.notifications[i].id)) {
        MockDatabase.notifications[i] = MockDatabase.notifications[i].copyWith(isRead: true);
      }
    }
    // 1. Backend Python
    if (!ApiConfig.useMockBackend) {
      try {
        await _httpHelper.makeOnlineRequest(
          '/notifications/index.php',
          method: 'PUT',
          body: {'ids': notificationIds, 'isRead': 1, 'action': 'mark_multiple_read'},
        );
      } catch (_) {}
    }

    // 2. Direct Supabase Cloud
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
        ).timeout(const Duration(seconds: 4));
      }
    } catch (_) {}

    await Future.delayed(const Duration(milliseconds: 150));
  }

  /// Delete notifications
  Future<void> deleteNotifications(List<String> notificationIds) async {
    MockDatabase.notifications.removeWhere((n) => notificationIds.contains(n.id));
    // 1. Backend Python
    if (!ApiConfig.useMockBackend) {
      try {
        await _httpHelper.makeOnlineRequest(
          '/notifications/index.php',
          method: 'DELETE',
          body: {'ids': notificationIds},
        );
      } catch (_) {}
    }

    // 2. Direct Supabase Cloud
    try {
      for (final nid in notificationIds) {
        final uri = Uri.parse('${ApiConfig.supabaseUrl}/rest/v1/notifications?id=eq.$nid');
        await http.delete(
          uri,
          headers: {
            'apikey': ApiConfig.supabasePublishableKey,
            'Authorization': 'Bearer ${ApiConfig.supabasePublishableKey}',
          },
        ).timeout(const Duration(seconds: 4));
      }
    } catch (_) {}

    await Future.delayed(const Duration(milliseconds: 150));
  }

  /// Mark all notifications as read for a user
  Future<void> markAllNotificationsRead(String userId) async {
    for (int i = 0; i < MockDatabase.notifications.length; i++) {
      MockDatabase.notifications[i] = MockDatabase.notifications[i].copyWith(isRead: true);
    }
    // 1. Backend Python
    if (!ApiConfig.useMockBackend) {
      try {
        await _httpHelper.makeOnlineRequest(
          '/notifications/index.php',
          method: 'PUT',
          body: {'markAll': true, 'userId': userId, 'isRead': 1, 'action': 'mark_all_read'},
        );
      } catch (_) {}
    }

    // 2. Direct Supabase Cloud
    try {
      final uri = Uri.parse('${ApiConfig.supabaseUrl}/rest/v1/notifications?user_id=eq.$userId');
      await http.patch(
        uri,
        headers: {
          'apikey': ApiConfig.supabasePublishableKey,
          'Authorization': 'Bearer ${ApiConfig.supabasePublishableKey}',
          'Content-Type': 'application/json',
        },
        body: jsonEncode({'is_read': true}),
      ).timeout(const Duration(seconds: 6));
    } catch (_) {}

    await Future.delayed(const Duration(milliseconds: 150));
  }
}
