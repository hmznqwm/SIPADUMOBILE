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
    if (!ApiConfig.useMockBackend) {
      try {
        await _httpHelper.makeOnlineRequest(
          '/notifications/index.php',
          method: 'PUT',
          body: {'id': notificationId, 'isRead': 1, 'action': 'mark_read'},
        );
      } catch (_) {}
    }
    await Future.delayed(const Duration(milliseconds: 150));
  }

  /// Mark multiple notifications as read
  Future<void> markMultipleNotificationsRead(List<String> notificationIds) async {
    for (int i = 0; i < MockDatabase.notifications.length; i++) {
      if (notificationIds.contains(MockDatabase.notifications[i].id)) {
        MockDatabase.notifications[i] = MockDatabase.notifications[i].copyWith(isRead: true);
      }
    }
    if (!ApiConfig.useMockBackend) {
      try {
        await _httpHelper.makeOnlineRequest(
          '/notifications/index.php',
          method: 'PUT',
          body: {'ids': notificationIds, 'isRead': 1, 'action': 'mark_multiple_read'},
        );
      } catch (_) {}
    }
    await Future.delayed(const Duration(milliseconds: 150));
  }

  /// Delete notifications
  Future<void> deleteNotifications(List<String> notificationIds) async {
    MockDatabase.notifications.removeWhere((n) => notificationIds.contains(n.id));
    if (!ApiConfig.useMockBackend) {
      try {
        await _httpHelper.makeOnlineRequest(
          '/notifications/index.php',
          method: 'DELETE',
          body: {'ids': notificationIds},
        );
      } catch (_) {}
    }
    await Future.delayed(const Duration(milliseconds: 150));
  }

  /// Mark all notifications as read for a user
  Future<void> markAllNotificationsRead(String userId) async {
    for (int i = 0; i < MockDatabase.notifications.length; i++) {
      MockDatabase.notifications[i] = MockDatabase.notifications[i].copyWith(isRead: true);
    }
    if (!ApiConfig.useMockBackend) {
      try {
        await _httpHelper.makeOnlineRequest(
          '/notifications/index.php',
          method: 'PUT',
          body: {'markAll': true, 'userId': userId, 'isRead': 1, 'action': 'mark_all_read'},
        );
      } catch (_) {}
    }
    await Future.delayed(const Duration(milliseconds: 150));
  }
}
