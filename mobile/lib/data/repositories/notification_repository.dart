// File: notification_repository.dart
// Deskripsi: Repositori pengelolaan data notifikasi pengguna.
// Fungsi: Menghubungkan ViewModel dengan ApiService untuk me-load daftar notifikasi, menandai notifikasi dibaca, atau menandai semua notifikasi dibaca.

import '../models/notification_model.dart';
import '../services/api_service.dart';

class NotificationRepository {
  final ApiService _apiService;

  NotificationRepository({required ApiService apiService}) : _apiService = apiService;

  Future<List<NotificationModel>> getNotifications(String dosenId) {
    return _apiService.getNotifications(dosenId);
  }

  Future<void> markAsRead(String notificationId) {
    return _apiService.markNotificationRead(notificationId);
  }

  Future<void> markMultipleAsRead(List<String> notificationIds) {
    return _apiService.markMultipleNotificationsRead(notificationIds);
  }

  Future<void> deleteNotifications(List<String> notificationIds) {
    return _apiService.deleteNotifications(notificationIds);
  }

  Future<void> markAllAsRead([String? userId]) {
    return _apiService.markAllNotificationsRead(userId);
  }
}
