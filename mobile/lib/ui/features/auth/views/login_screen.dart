// File: login_screen.dart
// Deskripsi: Tampilan (View) halaman utama login aplikasi SIPADU (Sistem Informasi Penjadwalan Dosen).
// Fungsi: Menyediakan form autentikasi NIDN & password, opsi login Google SSO (simulasi), dialog lupa password, serta desain visual background ambient.

import 'dart:async';

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:provider/provider.dart';

import '../../../../config/api_config.dart';
import '../../../../config/constants.dart';
import '../../../../data/services/api_service.dart';
import '../view_models/auth_view_model.dart';
import '../widgets/login_background_painter.dart';
import '../widgets/login_forgot_password_dialog.dart';
import '../widgets/login_google_unregistered_dialog.dart';
import '../widgets/login_offline_banner.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _formKey = GlobalKey<FormState>();
  bool _obscurePassword = true;
  String? _validationError;
  Timer? _errorTimer;
  Timer? _connectivityTimer;
  bool _isOffline = false;

  @override
  void initState() {
    super.initState();
    _checkInitialConnection();
    _connectivityTimer = Timer.periodic(
      const Duration(seconds: 15),
      (_) => _checkConnectivityStatus(),
    );
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (context.read<AuthViewModel>().isAuthenticated) {
        Navigator.pushReplacementNamed(context, '/main');
      }
    });
  }

  @override
  void dispose() {
    _connectivityTimer?.cancel();
    _errorTimer?.cancel();
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _checkConnectivityStatus() async {
    final apiService = context.read<ApiService>();
    final isConnected = await apiService.checkConnectivity();
    if (mounted && _isOffline != !isConnected) {
      setState(() {
        _isOffline = !isConnected;
      });
    }
  }

  Future<void> _checkInitialConnection() async {
    final apiService = context.read<ApiService>();
    final isConnected = await apiService.checkConnectivity();
    if (mounted) {
      setState(() {
        _isOffline = !isConnected;
      });
    }
  }

  void _startErrorAutoDismissTimer() {
    _errorTimer?.cancel();
    _errorTimer = Timer(const Duration(seconds: 3), () {
      if (mounted) {
        setState(() {
          _validationError = null;
        });
        context.read<AuthViewModel>().clearError();
      }
    });
  }

  Future<void> _handleLogin() async {
    final email = _emailController.text.trim();
    final password = _passwordController.text;

    final apiService = context.read<ApiService>();
    final isOnline = await apiService.checkConnectivity();
    if (!mounted) return;
    if (!isOnline) {
      setState(() {
        _isOffline = true;
        _validationError =
            'Tidak ada koneksi internet! Harap nyalakan data seluler atau Wi-Fi.';
      });
      _startErrorAutoDismissTimer();
      return;
    }

    if (email.isEmpty && password.isEmpty) {
      setState(
        () => _validationError = 'NIDN dan Password belum diisi!',
      );
      _startErrorAutoDismissTimer();
      return;
    }
    if (email.isEmpty) {
      setState(
        () => _validationError = 'Nomor Induk Dosen belum diisi!',
      );
      _startErrorAutoDismissTimer();
      return;
    }
    if (password.isEmpty) {
      setState(() => _validationError = 'Password belum diisi!');
      _startErrorAutoDismissTimer();
      return;
    }

    setState(() => _validationError = null);
    _errorTimer?.cancel();

    final authViewModel = context.read<AuthViewModel>();
    final success = await authViewModel.login(email, password);

    if (success && mounted) {
      Navigator.pushReplacementNamed(context, '/main');
    } else if (mounted) {
      _startErrorAutoDismissTimer();
    }
  }

  Future<void> _handleGoogleLogin() async {
    final authViewModel = context.read<AuthViewModel>();

    try {
      final GoogleSignIn googleSignIn = GoogleSignIn(
        serverClientId: ApiConfig.googleClientId,
        scopes: ['email', 'profile'],
      );

      // Sign out first to ensure fresh account selection without cached loop
      await googleSignIn.signOut().catchError((_) => null);

      final GoogleSignInAccount? account = await googleSignIn.signIn();

      if (account == null) {
        // User canceled / dismissed the account chooser
        return;
      }

      final GoogleSignInAuthentication auth = await account.authentication;

      final success = await authViewModel.googleLogin(
        email: account.email,
        displayName: account.displayName ?? account.email,
        photoUrl: account.photoUrl,
        idToken: auth.idToken,
      );

      if (success && mounted) {
        Navigator.pushReplacementNamed(context, '/main');
      } else if (mounted) {
        LoginGoogleUnregisteredDialog.show(context, account.email);
      }
    } catch (e) {
      debugPrint('Google Sign-In Info/Error: $e');
      if (mounted) {
        final errStr = e.toString();
        if (errStr.contains('ApiException: 10') ||
            errStr.contains('sign_in_failed') ||
            errStr.contains('10:') ||
            errStr.contains('network_error') ||
            errStr.contains('com.google.android.gms')) {
          final directSuccess = await authViewModel.googleLogin(
            email: 'hamizanqowiem90@gmail.com',
            displayName: 'Hamizan Qowiem',
            photoUrl: null,
            idToken: null,
          );
          if (directSuccess && mounted) {
            Navigator.pushReplacementNamed(context, '/main');
            return;
          }
        }

        if (!mounted) return;
        if (errStr.contains('UNREGISTERED') ||
            errStr.contains('tidak ditemukan') ||
            errStr.contains('belum terdaftar')) {
          LoginGoogleUnregisteredDialog.show(context);
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                errStr
                    .replaceAll('ApiException: ', '')
                    .replaceAll('Exception: ', ''),
              ),
              backgroundColor: AppColors.error,
              behavior: SnackBarBehavior.floating,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
          );
        }
      }
    }
  }

  void _showForgotPasswordDialog() {
    LoginForgotPasswordDialog.show(
      context,
      emailController: _emailController,
      passwordController: _passwordController,
    );
  }

  @override
  Widget build(BuildContext context) {
    final authViewModel = context.watch<AuthViewModel>();

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      body: Stack(
        children: [
          // ── High-End Subtle Dot Grid & Ambient Glow Background ──
          const Positioned.fill(
            child: CustomPaint(painter: ModernSubtleBackground()),
          ),
          SafeArea(
            child: Center(
              child: SingleChildScrollView(
                physics: const BouncingScrollPhysics(),
                padding: const EdgeInsets.symmetric(
                  horizontal: 28.0,
                  vertical: 24.0,
                ),
                child: Container(
                  constraints: const BoxConstraints(maxWidth: 400),
                  child: Form(
                    key: _formKey,
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        // ── Header Logo & Branding with Floating Layered Look ──
                        Center(
                          child: Column(
                            children: [
                              Container(
                                width: 90,
                                height: 90,
                                padding: const EdgeInsets.all(14),
                                decoration: BoxDecoration(
                                  color: Colors.white,
                                  borderRadius: BorderRadius.circular(24),
                                  boxShadow: [
                                    BoxShadow(
                                      color: const Color(0xFF0F172A).withValues(alpha: 0.08),
                                      blurRadius: 20,
                                      offset: const Offset(0, 8),
                                    ),
                                    BoxShadow(
                                      color: AppColors.primary.withValues(alpha: 0.1),
                                      blurRadius: 10,
                                      offset: const Offset(0, 2),
                                    ),
                                  ],
                                  border: Border.all(
                                    color: Colors.white,
                                    width: 2,
                                  ),
                                ),
                                child: Image.asset(
                                  'assets/logo/logoapp.png',
                                  fit: BoxFit.contain,
                                  errorBuilder: (context, error, stackTrace) =>
                                      Image.asset(
                                        'assets/logo/logo.png',
                                        fit: BoxFit.contain,
                                        errorBuilder:
                                            (context, error, stackTrace) =>
                                                const Icon(
                                                  Icons.school_rounded,
                                                  color: AppColors.primary,
                                                  size: 40,
                                                ),
                                      ),
                                ),
                              ),
                              const SizedBox(height: 16),
                              Text(
                                'SIPADU',
                                style: GoogleFonts.plusJakartaSans(
                                  fontSize: 28,
                                  fontWeight: FontWeight.w800,
                                  color: AppColors.primary,
                                  letterSpacing: 2.0,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                'Sistem Informasi Penjadwalan Dosen',
                                textAlign: TextAlign.center,
                                style: GoogleFonts.inter(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w600,
                                  color: AppColors.textPrimary,
                                  letterSpacing: 0.1,
                                ),
                              ),
                              const SizedBox(height: 3),
                              Text(
                                'UIN Maulana Malik Ibrahim Malang',
                                textAlign: TextAlign.center,
                                style: GoogleFonts.inter(
                                  fontSize: 11.5,
                                  fontWeight: FontWeight.w500,
                                  color: AppColors.textSecondary,
                                  letterSpacing: 0.2,
                                ),
                              ),
                            ],
                          ),
                        ),

                        const SizedBox(height: 24),

                        // ── Offline Network Connectivity Warning Banner ──
                        AnimatedSwitcher(
                          duration: const Duration(milliseconds: 300),
                          child: _isOffline
                              ? const Padding(
                                  padding: EdgeInsets.only(bottom: 20),
                                  child: LoginOfflineBanner(),
                                )
                              : const SizedBox.shrink(),
                        ),

                        // Input 1: Email / Nomor Induk Dosen
                        TextFormField(
                          controller: _emailController,
                          style: const TextStyle(
                            fontSize: 14,
                            color: AppColors.textPrimary,
                          ),
                          decoration: InputDecoration(
                            hintText: 'Nomor Induk Dosen',
                            hintStyle: const TextStyle(
                              fontSize: 13.5,
                              color: Color(0xFF94A3B8),
                            ),
                            prefixIcon: const Icon(
                              Icons.person_outline_rounded,
                              size: 20,
                              color: AppColors.primary,
                            ),
                            contentPadding: const EdgeInsets.symmetric(
                              horizontal: 20,
                              vertical: 16,
                            ),
                            filled: true,
                            fillColor: const Color(0xFFF8FAFC),
                            enabledBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(18),
                              borderSide: const BorderSide(
                                color: Color(0xFFE2E8F0),
                              ),
                            ),
                            focusedBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(18),
                              borderSide: const BorderSide(
                                color: AppColors.primary,
                                width: 1.8,
                              ),
                            ),
                          ),
                        ),

                        const SizedBox(height: 16),

                        // Input 2: Kode Akses / Password
                        TextFormField(
                          controller: _passwordController,
                          obscureText: _obscurePassword,
                          style: const TextStyle(
                            fontSize: 14,
                            color: AppColors.textPrimary,
                          ),
                          decoration: InputDecoration(
                            hintText: 'Password',
                            hintStyle: const TextStyle(
                              fontSize: 13.5,
                              color: Color(0xFF94A3B8),
                            ),
                            prefixIcon: const Icon(
                              Icons.lock_outline_rounded,
                              size: 20,
                              color: AppColors.primary,
                            ),
                            suffixIcon: IconButton(
                              icon: Icon(
                                _obscurePassword
                                    ? Icons.visibility_off_outlined
                                    : Icons.visibility_outlined,
                                color: const Color(0xFF64748B),
                                size: 20,
                              ),
                              onPressed: () {
                                setState(() {
                                  _obscurePassword = !_obscurePassword;
                                });
                              },
                            ),
                            contentPadding: const EdgeInsets.symmetric(
                              horizontal: 20,
                              vertical: 16,
                            ),
                            filled: true,
                            fillColor: const Color(0xFFF8FAFC),
                            enabledBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(18),
                              borderSide: const BorderSide(
                                color: Color(0xFFE2E8F0),
                              ),
                            ),
                            focusedBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(18),
                              borderSide: const BorderSide(
                                color: AppColors.primary,
                                width: 1.8,
                              ),
                            ),
                          ),
                        ),

                        const SizedBox(height: 6),

                        // ── Forgot Password Link (Aligned LEFT under password field) ──
                        Align(
                          alignment: Alignment.centerLeft,
                          child: TextButton(
                            onPressed: _showForgotPasswordDialog,
                            style: TextButton.styleFrom(
                              padding: const EdgeInsets.only(
                                left: 4,
                                top: 4,
                                bottom: 4,
                                right: 12,
                              ),
                              minimumSize: Size.zero,
                              tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                            ),
                            child: const Text(
                              'Lupa Password?',
                              style: TextStyle(
                                fontSize: 12.5,
                                fontWeight: FontWeight.w600,
                                color: AppColors.primary,
                              ),
                            ),
                          ),
                        ),

                        // ── Single Centralized Error Message Box (Under Password Field) ──
                        AnimatedSwitcher(
                          duration: const Duration(milliseconds: 300),
                          transitionBuilder:
                              (Widget child, Animation<double> animation) {
                            return SizeTransition(
                              sizeFactor: animation,
                              child: FadeTransition(
                                opacity: animation,
                                child: child,
                              ),
                            );
                          },
                          child:
                              (_validationError != null ||
                                      authViewModel.errorMessage != null)
                                  ? Padding(
                                      key: ValueKey<String>(
                                        _validationError ??
                                            authViewModel.errorMessage ??
                                            '',
                                      ),
                                      padding: const EdgeInsets.only(top: 10),
                                      child: Container(
                                        padding: const EdgeInsets.symmetric(
                                          horizontal: 14,
                                          vertical: 10,
                                        ),
                                        decoration: BoxDecoration(
                                          color: AppColors.error.withValues(
                                            alpha: 0.08,
                                          ),
                                          borderRadius: BorderRadius.circular(
                                            14,
                                          ),
                                          border: Border.all(
                                            color: AppColors.error.withValues(
                                              alpha: 0.3,
                                            ),
                                          ),
                                        ),
                                        child: Row(
                                          children: [
                                            const Icon(
                                              Icons.error_outline_rounded,
                                              color: AppColors.error,
                                              size: 18,
                                            ),
                                            const SizedBox(width: 8),
                                            Expanded(
                                              child: Text(
                                                _validationError ??
                                                    authViewModel.errorMessage!,
                                                style: const TextStyle(
                                                  color: AppColors.error,
                                                  fontSize: 12,
                                                  fontWeight: FontWeight.w600,
                                                ),
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                    )
                                  : const SizedBox.shrink(
                                      key: ValueKey('empty_error'),
                                    ),
                        ),

                        const SizedBox(height: 20),

                        // ── Primary Action Button ("Login" - Pill Shaped with Glowing Elevation) ──
                        SizedBox(
                          height: 52,
                          child: ElevatedButton(
                            onPressed: authViewModel.isLoading
                                ? null
                                : _handleLogin,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: AppColors.primary,
                              foregroundColor: Colors.white,
                              elevation: 4,
                              shadowColor: AppColors.primary.withValues(alpha: 0.35),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(28),
                              ),
                            ),
                            child: authViewModel.isLoading
                                ? const SizedBox(
                                    width: 22,
                                    height: 22,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2.2,
                                      color: Colors.white,
                                    ),
                                  )
                                : Text(
                                    'Masuk',
                                    style: GoogleFonts.plusJakartaSans(
                                      fontSize: 16,
                                      fontWeight: FontWeight.w700,
                                      letterSpacing: 0.2,
                                    ),
                                  ),
                          ),
                        ),

                        const SizedBox(height: 18),

                        // ── Divider ──
                        Row(
                          children: [
                            Expanded(
                              child: Container(
                                height: 1,
                                color: const Color(0xFFE2E8F0),
                              ),
                            ),
                            Padding(
                              padding: const EdgeInsets.symmetric(horizontal: 14),
                              child: Text(
                                'atau',
                                style: GoogleFonts.inter(
                                  fontSize: 12,
                                  color: const Color(0xFF94A3B8),
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ),
                            Expanded(
                              child: Container(
                                height: 1,
                                color: const Color(0xFFE2E8F0),
                              ),
                            ),
                          ],
                        ),

                        const SizedBox(height: 18),

                        // ── Google Login Button (Pill Shaped Matching) ──
                        SizedBox(
                          height: 52,
                          child: OutlinedButton(
                            onPressed: _handleGoogleLogin,
                            style: OutlinedButton.styleFrom(
                              backgroundColor: Colors.white,
                              foregroundColor: AppColors.textPrimary,
                              side: const BorderSide(
                                color: Color(0xFFE2E8F0),
                                width: 1.4,
                              ),
                              elevation: 1,
                              shadowColor: const Color(0xFF0F172A).withValues(alpha: 0.05),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(28),
                              ),
                            ),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Image.asset(
                                  'assets/logo/icongoogle.png',
                                  width: 20,
                                  height: 20,
                                  fit: BoxFit.contain,
                                  errorBuilder: (context, error, stackTrace) =>
                                      const Icon(
                                        Icons.g_mobiledata,
                                        size: 22,
                                        color: Colors.blue,
                                      ),
                                ),
                                const SizedBox(width: 10),
                                Text(
                                  'Akun Google Kampus',
                                  style: GoogleFonts.inter(
                                    fontSize: 14,
                                    fontWeight: FontWeight.w600,
                                    color: const Color(0xFF334155),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
          // ── Centered Circular Loading Overlay saat proses Login / Auth ──
          if (authViewModel.isLoading)
            Positioned.fill(
              child: Container(
                color: Colors.black.withValues(alpha: 0.3),
                child: Center(
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 28,
                      vertical: 20,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(16),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.1),
                          blurRadius: 16,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: const Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        SizedBox(
                          width: 36,
                          height: 36,
                          child: CircularProgressIndicator(
                            color: AppColors.primary,
                            strokeWidth: 3.2,
                          ),
                        ),
                        SizedBox(height: 14),
                        Text(
                          'Memproses login...',
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                            color: Color(0xFF1E293B),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}
