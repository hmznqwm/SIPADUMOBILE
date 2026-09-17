// File: notifications_view_model.dart
// Deskripsi: ViewModel (ChangeNotifier) untuk pengelolaan data dan status notifikasi pengguna.
// Fungsi: Mengelola daftar notifikasi pengumuman/sistem, menghitung pesan belum dibaca, dan menandai notifikasi telah dibaca.

import 'package:flutter/material.dart';

import '../../../../data/models/notification_model.dart';
import '../../../../data/repositories/auth_repository.dart';
import '../../../../data/repositories/notification_repository.dart';

class NotificationsViewModel extends ChangeNotifier {
  final AuthRepository _authRepository;
  final NotificationRepository _notificationRepository;

  NotificationsViewModel({
    required AuthRepository authRepository,
    required NotificationRepository notificationRepository,
  })  : _authRepository = authRepository,
        _notificationRepository = notificationRepository;

  bool _isLoading = false;
  bool get isLoading => _isLoading;

  String? _errorMessage;
  String? get errorMessage => _errorMessage;

  List<NotificationModel> _notifications = [];
  List<NotificationModel> get notifications => _notifications;

  int get unreadCount => _notifications.where((n) => !n.isRead).length;

  Future<void> loadNotifications() async {
    final user = _authRepository.currentUser;
    if (user == null) return;

    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      _notifications = await _notificationRepository.getNotifications(user.id);
    } catch (e) {
      _errorMessage = e.toString();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> markAsRead(String id) async {
    await _notificationRepository.markAsRead(id);
    final idx = _notifications.indexWhere((n) => n.id == id);
    if (idx >= 0) {
      _notifications[idx] = _notifications[idx].copyWith(isRead: true);
      notifyListeners();
    }
  }

  Future<void> markMultipleAsRead(List<String> ids) async {
    await _notificationRepository.markMultipleAsRead(ids);
    for (int i = 0; i < _notifications.length; i++) {
      if (ids.contains(_notifications[i].id)) {
        _notifications[i] = _notifications[i].copyWith(isRead: true);
      }
    }
    notifyListeners();
  }

  Future<void> deleteNotifications(List<String> ids) async {
    await _notificationRepository.deleteNotifications(ids);
    _notifications.removeWhere((n) => ids.contains(n.id));
    notifyListeners();
  }

  Future<void> markAllAsRead() async {
    final user = _authRepository.currentUser;
    await _notificationRepository.markAllAsRead(user?.id);
    for (int i = 0; i < _notifications.length; i++) {
      _notifications[i] = _notifications[i].copyWith(isRead: true);
    }
    notifyListeners();
  }
}
