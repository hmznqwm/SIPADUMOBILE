// File: onboarding_screen.dart
// Deskripsi: Layar Onboarding / Welcome Walkthrough untuk pengguna baru (4 slide).
// Slide 1: Ucapan Selamat Datang di Aplikasi SIPADU Mobile.
// Slide 2: Penjadwalan Kuliah Cerdas & Otomatis.
// Slide 3: Monitoring Ruangan & Kelas Real-time.
// Slide 4: Akses Jadwal Kuliah Mudah Kapan Saja.

import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../../../config/constants.dart';
import '../../auth/views/login_screen.dart';

class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({super.key});

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen>
    with SingleTickerProviderStateMixin {
  final PageController _pageController = PageController();
  int _currentPage = 0;
  late AnimationController _floatController;

  final List<OnboardingSlideData> _slides = const [
    OnboardingSlideData(
      imagePath: 'assets/images/onboarding/welcome.png',
      accentColor: AppColors.primary,
      title: 'Selamat Datang di\nAplikasi SIPADU Mobile',
      description:
          'Sistem Informasi Penjadwalan Terpadu untuk kemudahan perencanaan, monitoring, dan akses jadwal perkuliahan secara cerdas dan efisien.',
    ),
    OnboardingSlideData(
      imagePath: 'assets/images/onboarding/1.png',
      accentColor: AppColors.primary,
      title: 'Penjadwalan Kuliah\nCerdas & Otomatis',
      description:
          'Susun jadwal perkuliahan seluruh fakultas tanpa bentrok ruang maupun waktu secara cepat dan presisi dengan algoritma otomatis.',
    ),
    OnboardingSlideData(
      imagePath: 'assets/images/onboarding/2.png',
      accentColor: AppColors.primaryAccent,
      title: 'Monitoring Ruangan\n& Kelas Real-time',
      description:
          'Pantau ketersediaan gedung, ruang kuliah, dan fasilitas laboratorium secara transparan, akurat, dan terintegrasi.',
    ),
    OnboardingSlideData(
      imagePath: 'assets/images/onboarding/3.png',
      accentColor: AppColors.primary,
      title: 'Akses Jadwal Kuliah\nMudah Kapan Saja',
      description:
          'Dosen dan mahasiswa dapat melihat jadwal mengajar, pengumuman perkuliahan, serta notifikasi update langsung dari perangkat.',
    ),
  ];

  @override
  void initState() {
    super.initState();
    _floatController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 4000),
    )..repeat();
  }

  @override
  void dispose() {
    _floatController.dispose();
    _pageController.dispose();
    super.dispose();
  }

  /// Menandai onboarding telah dilihat dan navigasi ke halaman Login
  Future<void> _completeOnboarding() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('has_seen_onboarding', true);

    if (!mounted) return;
    Navigator.pushReplacement(
      context,
      PageRouteBuilder(
        pageBuilder: (context, animation, secondaryAnimation) =>
            const LoginScreen(),
        transitionsBuilder: (context, animation, secondaryAnimation, child) {
          return FadeTransition(
            opacity: animation,
            child: child,
          );
        },
        transitionDuration: const Duration(milliseconds: 350),
      ),
    );
  }

  void _nextPage() {
    if (_currentPage < _slides.length - 1) {
      _pageController.nextPage(
        duration: const Duration(milliseconds: 400),
        curve: Curves.easeInOutCubic,
      );
    } else {
      _completeOnboarding();
    }
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    final isLastPage = _currentPage == _slides.length - 1;

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      body: SafeArea(
        child: Column(
          children: [
            const SizedBox(height: 12),

            // ── Main PageView Slider (4 Slides) ──
            Expanded(
              child: PageView.builder(
                controller: _pageController,
                physics: const BouncingScrollPhysics(),
                itemCount: _slides.length,
                onPageChanged: (index) {
                  setState(() {
                    _currentPage = index;
                  });
                },
                itemBuilder: (context, index) {
                  final slide = _slides[index];
                  return _buildSlideItem(slide, size);
                },
              ),
            ),

            // ── Bottom Section: Indicator, CTA Button & Sign In Link ──
            Padding(
              padding: EdgeInsets.fromLTRB(
                28,
                0,
                28,
                math.max(MediaQuery.of(context).padding.bottom, 12.0) + 8.0,
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Animated Dots Indicator
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: List.generate(_slides.length, (index) {
                      final isActive = index == _currentPage;
                      return AnimatedContainer(
                        duration: const Duration(milliseconds: 300),
                        margin: const EdgeInsets.symmetric(horizontal: 4),
                        height: 7,
                        width: isActive ? 28 : 7,
                        decoration: BoxDecoration(
                          color: isActive
                              ? AppColors.primary
                              : const Color(0xFFCBD5E1),
                          borderRadius: BorderRadius.circular(10),
                        ),
                      );
                    }),
                  ),

                  const SizedBox(height: 24),

                  // Main Action CTA Button
                  SizedBox(
                    width: double.infinity,
                    height: 54,
                    child: ElevatedButton(
                      onPressed: _nextPage,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primary,
                        foregroundColor: Colors.white,
                        elevation: 4,
                        shadowColor: AppColors.primary.withValues(alpha: 0.35),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(28),
                        ),
                      ),
                      child: Text(
                        isLastPage ? 'Mulai Sekarang' : 'Lanjutkan',
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
                          letterSpacing: 0.2,
                        ),
                      ),
                    ),
                  ),

                  const SizedBox(height: 14),

                  // "Sudah punya akun? Masuk" Link
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        'Sudah punya akun? ',
                        style: GoogleFonts.inter(
                          fontSize: 13,
                          color: AppColors.textSecondary,
                        ),
                      ),
                      GestureDetector(
                        onTap: _completeOnboarding,
                        child: Text(
                          'Masuk',
                          style: GoogleFonts.inter(
                            fontSize: 13,
                            fontWeight: FontWeight.w700,
                            color: AppColors.primary,
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSlideItem(OnboardingSlideData slide, Size size) {
    final imageHeight = (size.height * 0.38).clamp(240.0, 340.0);

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          // ── Seamless Floating Graphic / Illustration ──
          AnimatedBuilder(
            animation: _floatController,
            builder: (context, child) {
              final floatOffset =
                  math.sin(_floatController.value * 2 * math.pi) * 6;

              return Transform.translate(
                offset: Offset(0, floatOffset),
                child: SizedBox(
                  height: imageHeight,
                  width: double.infinity,
                  child: Stack(
                    alignment: Alignment.center,
                    children: [
                      // Soft Ambient Radial Glow
                      Container(
                        width: size.width * 0.75,
                        height: imageHeight * 0.85,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          boxShadow: [
                            BoxShadow(
                              color: slide.accentColor.withValues(alpha: 0.20),
                              blurRadius: 52,
                              spreadRadius: 10,
                            ),
                          ],
                        ),
                      ),

                      // 3D Illustration with Curved Bottom & Soft Fade Mask
                      ShaderMask(
                        shaderCallback: (Rect bounds) {
                          return const LinearGradient(
                            begin: Alignment.topCenter,
                            end: Alignment.bottomCenter,
                            colors: [
                              Colors.black,
                              Colors.black,
                              Colors.black,
                              Colors.transparent,
                            ],
                            stops: [0.0, 0.65, 0.85, 1.0],
                          ).createShader(bounds);
                        },
                        blendMode: BlendMode.dstIn,
                        child: ClipRRect(
                          borderRadius: const BorderRadius.vertical(
                            top: Radius.circular(24),
                            bottom: Radius.circular(36),
                          ),
                          child: Image.asset(
                            slide.imagePath,
                            fit: BoxFit.contain,
                            height: imageHeight,
                            errorBuilder: (context, error, stackTrace) =>
                                const Icon(
                              Icons.image_rounded,
                              size: 80,
                              color: AppColors.primary,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              );
            },
          ),

          const SizedBox(height: 28),

          // ── Title & Description ──
          Text(
            slide.title,
            textAlign: TextAlign.center,
            style: GoogleFonts.plusJakartaSans(
              fontSize: 23,
              fontWeight: FontWeight.w800,
              color: AppColors.textPrimary,
              height: 1.25,
              letterSpacing: -0.3,
            ),
          ),

          const SizedBox(height: 12),

          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12),
            child: Text(
              slide.description,
              textAlign: TextAlign.center,
              style: GoogleFonts.inter(
                fontSize: 13.5,
                fontWeight: FontWeight.w400,
                color: AppColors.textSecondary,
                height: 1.5,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class OnboardingSlideData {
  final String imagePath;
  final Color accentColor;
  final String title;
  final String description;

  const OnboardingSlideData({
    required this.imagePath,
    required this.accentColor,
    required this.title,
    required this.description,
  });
}
