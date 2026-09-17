// File: routes.dart
// Deskripsi: Definisi rute navigasi dan pemetaan rute aplikasi Smart Schedule.
// Fungsi: Mengelola daftar URL/nama rute dan widget halaman yang dipanggil untuk navigasi aplikasi.

import 'package:flutter/material.dart';

import '../ui/features/auth/views/login_screen.dart';
import '../ui/features/history/views/history_screen.dart';
import '../ui/features/info/views/info_screen.dart';
import '../ui/features/notifications/views/notifications_screen.dart';
import '../ui/features/onboarding/views/onboarding_screen.dart';
import '../ui/features/shell/main_shell_screen.dart';

class AppRoutes {
  static const String onboarding = '/onboarding';
  static const String login = '/login';
  static const String main = '/main';
  static const String history = '/history';
  static const String notifications = '/notifications';
  static const String info = '/info';

  static Map<String, WidgetBuilder> get routes => {
        onboarding: (context) => const OnboardingScreen(),
        login: (context) => const LoginScreen(),
        main: (context) => const MainShellScreen(),
        history: (context) => const HistoryScreen(),
        notifications: (context) => const NotificationsScreen(),
        info: (context) => const InfoScreen(),
      };
}
