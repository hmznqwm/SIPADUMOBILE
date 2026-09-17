// ════════════════════════════════════════════════════════════════════════════════
// SmartSchedule App - Entry Point Utama Aplikasi
// Deskripsi: Berkas ini berfungsi sebagai titik awal (main entry point) aplikasi.
// Mengatur Inisialisasi Provider (State Management), Routing, dan Cek Sesi Autentikasi.
// ════════════════════════════════════════════════════════════════════════════════

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'config/constants.dart';
import 'config/routes.dart';
import 'config/theme.dart';
import 'data/repositories/auth_repository.dart';
import 'data/repositories/availability_repository.dart';
import 'data/repositories/jadwal_repository.dart';
import 'data/repositories/notification_repository.dart';
import 'data/services/api_service.dart';
import 'ui/features/auth/view_models/auth_view_model.dart';
import 'ui/features/auth/views/login_screen.dart';
import 'ui/features/availability/view_models/availability_view_model.dart';
import 'ui/features/dashboard/view_models/dashboard_view_model.dart';
import 'ui/features/history/view_models/history_view_model.dart';
import 'ui/features/notifications/view_models/notifications_view_model.dart';
import 'ui/features/onboarding/views/onboarding_screen.dart';
import 'ui/features/schedule/view_models/schedule_view_model.dart';
import 'ui/features/shell/main_shell_screen.dart';

import 'package:flutter/services.dart';

/// Fungsi utama untuk menjalankan aplikasi Flutter
void main() {
  // Memastikan binding Flutter sudah siap sebelum menjalankan aplikasi
  WidgetsFlutterBinding.ensureInitialized();

  // Mengatur transparansi dan warna sistem navigation bar Android agar tidak menutupi tombol navbar
  SystemChrome.setSystemUIOverlayStyle(
    const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.dark,
      systemNavigationBarColor: Colors.white,
      systemNavigationBarIconBrightness: Brightness.dark,
      systemNavigationBarDividerColor: Colors.transparent,
    ),
  );

  runApp(const SmartScheduleApp());
}

/// Root Widget Aplikasi SmartSchedule
class SmartScheduleApp extends StatelessWidget {
  const SmartScheduleApp({super.key});

  @override
  Widget build(BuildContext context) {
    // 1. Inisialisasi Service API & Repository (Data Layer)
    final apiService = ApiService();
    final authRepo = AuthRepository(apiService: apiService);
    final availabilityRepo = AvailabilityRepository(apiService: apiService);
    final jadwalRepo = JadwalRepository(apiService: apiService);
    final notifRepo = NotificationRepository(apiService: apiService);

    // 2. Mengatur MultiProvider untuk State Management (MVVM Pattern)
    return MultiProvider(
      providers: [
        // Provider Service API Utama
        ChangeNotifierProvider<ApiService>.value(value: apiService),
        // ViewModel Autentikasi (Login/Logout & Cek Sesi User)
        ChangeNotifierProvider(create: (_) => AuthViewModel(authRepository: authRepo)),
        // ViewModel Dashboard & Konflik Jadwal (RCK)
        ChangeNotifierProvider(
          create: (_) => DashboardViewModel(
            authRepository: authRepo,
            availabilityRepository: availabilityRepo,
            jadwalRepository: jadwalRepo,
          ),
        ),
        // ViewModel Ketersediaan Waktu Dosen
        ChangeNotifierProvider(
          create: (_) => AvailabilityViewModel(
            authRepository: authRepo,
            availabilityRepository: availabilityRepo,
          ),
        ),
        // ViewModel Jadwal Kuliah & Penyusunan Otomatis
        ChangeNotifierProvider(
          create: (_) => ScheduleViewModel(
            authRepository: authRepo,
            jadwalRepository: jadwalRepo,
          ),
        ),
        // ViewModel Riwayat & Logs Sistem
        ChangeNotifierProvider(
          create: (_) => HistoryViewModel(
            authRepository: authRepo,
            availabilityRepository: availabilityRepo,
          ),
        ),
        // ViewModel Notifikasi & Pengumuman Dosen
        ChangeNotifierProvider(
          create: (_) => NotificationsViewModel(
            authRepository: authRepo,
            notificationRepository: notifRepo,
          ),
        ),
      ],
      // 3. Konfigurasi Utama MaterialApp (Tema, Judul, Route & Initial Screen)
      child: MaterialApp(
        title: 'SIPADU - Sistem Informasi Penjadwalan Dosen',
        debugShowCheckedModeBanner: false,
        theme: AppTheme.lightTheme,
        home: const AuthWrapper(),
        routes: AppRoutes.routes,
      ),
    );
  }
}

/// Widget Wrapper untuk Memeriksa Status Login User (Session Check)
class AuthWrapper extends StatefulWidget {
  const AuthWrapper({super.key});

  @override
  State<AuthWrapper> createState() => _AuthWrapperState();
}

class _AuthWrapperState extends State<AuthWrapper> {
  bool _isChecking = true;
  bool _hasSeenOnboarding = false;

  @override
  void initState() {
    super.initState();
    // Memeriksa sesi login tersimpan & onboarding status secara asynchronous
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _checkSession();
    });
  }

  /// Fungsi untuk memeriksa apakah pengguna sudah login sebelumnya dan sudah melihat onboarding
  Future<void> _checkSession() async {
    final prefs = await SharedPreferences.getInstance();
    final seen = prefs.getBool('has_seen_onboarding') ?? false;

    if (!mounted) return;
    final authVm = context.read<AuthViewModel>();
    await authVm.checkAndLoadSession();

    if (mounted) {
      setState(() {
        _hasSeenOnboarding = seen;
        _isChecking = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    // 1. Tampilkan loading spinner saat masih memeriksa sesi
    if (_isChecking) {
      return const Scaffold(
        backgroundColor: Colors.white,
        body: Center(
          child: CircularProgressIndicator(color: AppColors.primary),
        ),
      );
    }

    // 2. Arahkan ke MainShell jika sudah login
    final authVm = context.watch<AuthViewModel>();
    if (authVm.isAuthenticated) {
      return const MainShellScreen();
    }

    // 3. Jika belum login dan belum pernah lihat onboarding, tampilkan OnboardingScreen
    if (!_hasSeenOnboarding) {
      return const OnboardingScreen();
    }

    // 4. Jika sudah pernah melihat onboarding tapi belum login, tampilkan LoginScreen
    return const LoginScreen();
  }
}
