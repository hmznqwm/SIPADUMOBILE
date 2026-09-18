// File: main_shell_screen.dart
// Deskripsi: Tampilan utama kontainer (Shell Screen) dengan bilah navigasi bawah (Bottom Navigation Bar).
// Fungsi: Mengelola perpindahan tab utama (Dashboard, Ketersediaan, Master Data, Jadwal, Profil), AppBar universal, fitur simulasi switch role, dan notifikasi.

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

import '../../../config/constants.dart';
import '../../../utils/pdf_export.dart';
import '../auth/view_models/auth_view_model.dart';
import '../availability/views/availability_screen.dart';
import '../dashboard/views/dashboard_screen.dart';
import '../master_data/views/master_data_screen.dart';
import '../notifications/view_models/notifications_view_model.dart';
import '../profile/views/profile_screen.dart';
import '../schedule/view_models/schedule_view_model.dart';
import '../schedule/views/schedule_screen.dart';

// ── Custom Database Cylinder Icon (Tabung Bertumpuk 3 Layer) ──
class DatabaseCylinderIcon extends StatelessWidget {
  final Color color;
  final double size;

  const DatabaseCylinderIcon({
    super.key,
    required this.color,
    this.size = 22,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: size,
      height: size,
      child: CustomPaint(
        painter: _DatabaseCylinderPainter(color: color),
      ),
    );
  }
}

class _DatabaseCylinderPainter extends CustomPainter {
  final Color color;

  _DatabaseCylinderPainter({required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.0
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;

    final w = size.width;
    final h = size.height;

    // Top Ellipse Disk
    final topRect = Rect.fromLTWH(w * 0.12, h * 0.08, w * 0.76, h * 0.26);
    canvas.drawOval(topRect, paint);

    // Middle Cylinder Arc
    final middlePath = Path()
      ..addArc(
        Rect.fromLTWH(w * 0.12, h * 0.35, w * 0.76, h * 0.26),
        0,
        3.14159,
      );
    canvas.drawPath(middlePath, paint);

    // Bottom Cylinder Arc
    final bottomPath = Path()
      ..addArc(
        Rect.fromLTWH(w * 0.12, h * 0.62, w * 0.76, h * 0.26),
        0,
        3.14159,
      );
    canvas.drawPath(bottomPath, paint);

    // Left and Right Vertical Side Lines
    final topY = h * 0.21;
    final bottomY = h * 0.75;
    final leftX = w * 0.12;
    final rightX = w * 0.88;

    canvas.drawLine(Offset(leftX, topY), Offset(leftX, bottomY), paint);
    canvas.drawLine(Offset(rightX, topY), Offset(rightX, bottomY), paint);
  }

  @override
  bool shouldRepaint(covariant _DatabaseCylinderPainter oldDelegate) {
    return oldDelegate.color != color;
  }
}

class MainShellScreen extends StatefulWidget {
  const MainShellScreen({super.key});

  @override
  State<MainShellScreen> createState() => _MainShellScreenState();
}

class _MainShellScreenState extends State<MainShellScreen> {
  int _currentIndex = 0;

  void _onTabTapped(int index) {
    setState(() {
      _currentIndex = index;
    });
  }

  String _getTabTitle(int index, dynamic user) {
    switch (index) {
      case 0:
        if (user?.role == 'admin') return 'Dashboard Super Admin';
        if (user?.role == 'dekan') return 'Dashboard Dekan FST';
        if (user?.role == 'kajur') return 'Dashboard KaProdi TI';
        return 'Dashboard Dosen';
      case 1:
        if (user?.role == 'admin') return 'Ruang & Ajuan Dosen';
        if (user?.role == 'dekan') return 'Persetujuan Ketersediaan';
        if (user?.role == 'kajur') return 'Verifikasi Ketersediaan';
        return 'Ketersediaan Jadwal';
      case 2:
        return 'Master Data & Prioritas';
      case 3:
        if (user?.role == 'admin') return 'Jadwal Master Institusi';
        if (user?.role == 'dekan') return 'Jadwal Fakultas FST';
        if (user?.role == 'kajur') return 'Jadwal Program Studi';
        return 'Jadwal Mengajar';
      case 4:
        return 'Profil Pengguna';
      default:
        return 'SIPADU';
    }
  }

  // Standard Nav Item (Icon + Text Label)
  Widget _buildNavItem(int index, IconData icon, IconData activeIcon, String label) {
    final isSelected = _currentIndex == index;
    final activeColor = AppColors.primary;
    final inactiveColor = const Color(0xFF64748B);

    return Expanded(
      child: InkWell(
        onTap: () => _onTabTapped(index),
        borderRadius: BorderRadius.circular(12),
        splashColor: activeColor.withValues(alpha: 0.08),
        highlightColor: Colors.transparent,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 2, vertical: 2),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Icon(
                isSelected ? activeIcon : icon,
                color: isSelected ? activeColor : inactiveColor,
                size: 23,
              ),
              const SizedBox(height: 2),
              Text(
                label,
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 10.5,
                  fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                  color: isSelected ? activeColor : inactiveColor,
                  letterSpacing: 0.1,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // Floating Elevated Center Nav Item (M-Banking QRIS Style untuk Admin Data Button)
  Widget _buildElevatedCenterNavItem(int index, String label) {
    final isSelected = _currentIndex == index;
    final activeColor = AppColors.primary;

    return Expanded(
      child: InkWell(
        onTap: () => _onTabTapped(index),
        borderRadius: BorderRadius.circular(30),
        splashColor: activeColor.withValues(alpha: 0.12),
        highlightColor: Colors.transparent,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            // Floating Circle Elevated Button
            Transform.translate(
              offset: const Offset(0, -18),
              child: Container(
                width: 54,
                height: 54,
                decoration: BoxDecoration(
                  color: AppColors.primary,
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: AppColors.primary.withValues(alpha: isSelected ? 0.35 : 0.20),
                      blurRadius: isSelected ? 10 : 7,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: const Center(
                  child: DatabaseCylinderIcon(
                    color: Colors.white,
                    size: 24,
                  ),
                ),
              ),
            ),
            Transform.translate(
              offset: const Offset(0, -14),
              child: Text(
                label,
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 10.5,
                  fontWeight: isSelected ? FontWeight.bold : FontWeight.w600,
                  color: isSelected ? activeColor : const Color(0xFF64748B),
                  letterSpacing: 0.1,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final unreadNotifs = context.watch<NotificationsViewModel>().unreadCount;
    final user = context.watch<AuthViewModel>().currentUser;
    final scheduleViewModel = context.watch<ScheduleViewModel>();

    final pages = [
      DashboardScreen(onNavigateToTab: _onTabTapped),
      const AvailabilityScreen(),
      const AdminMasterDataScreen(),
      const ScheduleScreen(),
      const ProfileScreen(),
    ];

    final maxIndex = pages.length - 1;
    final safeIndex = _currentIndex > maxIndex ? maxIndex : _currentIndex;

    final isHistoryVisible = user?.role == 'dosen' && safeIndex == 1;
    final isExportPdfVisible = user?.role != 'admin' && safeIndex == 3;

    final bool isAdmin = user?.role == 'admin';

    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: const SystemUiOverlayStyle(
        statusBarColor: Colors.transparent,
        statusBarIconBrightness: Brightness.dark,
        statusBarBrightness: Brightness.light,
        systemNavigationBarColor: Colors.white,
        systemNavigationBarDividerColor: Colors.transparent,
        systemNavigationBarIconBrightness: Brightness.dark,
        systemNavigationBarContrastEnforced: false,
      ),
      child: Scaffold(
        extendBody: false,
        appBar: AppBar(
          title: Text(
            _getTabTitle(safeIndex, user),
            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
          ),
          actions: [
            // Export PDF Button on Schedule Tab (Hanya untuk non-admin seperti Dosen, Mahasiswa, Kaprodi, Dekan)
            if (isExportPdfVisible)
              IconButton(
                icon: const Icon(Icons.picture_as_pdf_rounded, color: AppColors.primary),
                tooltip: 'Export Jadwal ke PDF',
                onPressed: scheduleViewModel.jadwalList.isEmpty || user == null
                    ? null
                    : () {
                        PdfExportUtility.exportJadwalToPdf(
                          user: user,
                          jadwalList: scheduleViewModel.filteredJadwalList,
                        );
                      },
              ),

            // Histori Ajuan button (Khusus Dosen di tab Ajuan)
            if (isHistoryVisible)
              IconButton(
                icon: const Icon(Icons.history_rounded),
                tooltip: 'Riwayat Ajuan Dosen',
                onPressed: () {
                  Navigator.pushNamed(context, '/history');
                },
              ),

            // Notification Bell with Badge
            Stack(
              alignment: Alignment.center,
              children: [
                IconButton(
                  icon: const Icon(Icons.notifications_none_rounded),
                  onPressed: () {
                    Navigator.pushNamed(context, '/notifications');
                  },
                ),
                if (unreadNotifs > 0)
                  Positioned(
                    top: 10,
                    right: 10,
                    child: Container(
                      padding: const EdgeInsets.all(4),
                      decoration: const BoxDecoration(
                        color: AppColors.error,
                        shape: BoxShape.circle,
                      ),
                      constraints: const BoxConstraints(
                        minWidth: 8,
                        minHeight: 8,
                      ),
                    ),
                  ),
              ],
            ),
            const SizedBox(width: 8),
          ],
        ),
        backgroundColor: const Color(0xFFF8FAFC),
        body: IndexedStack(
          index: safeIndex,
          children: pages.map<Widget>((page) {
            if (page is AdminMasterDataScreen && !isAdmin) {
              return const Center(
                child: Padding(
                  padding: EdgeInsets.all(24),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.gpp_bad_rounded, size: 56, color: Color(0xFF94A3B8)),
                      SizedBox(height: 14),
                      Text(
                        'Akses Ditolak',
                        style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Color(0xFF0F172A)),
                      ),
                      SizedBox(height: 6),
                      Text(
                        'Menu Master Data & Prioritas Kampus hanya dapat diakses oleh Super Administrator.',
                        textAlign: TextAlign.center,
                        style: TextStyle(fontSize: 13, color: Color(0xFF64748B)),
                      ),
                    ],
                  ),
                ),
              );
            }
            return page;
          }).toList(),
        ),
        bottomNavigationBar: Stack(
          clipBehavior: Clip.none,
          alignment: Alignment.topCenter,
          children: [
            Container(
              decoration: const BoxDecoration(
                color: Colors.white,
                border: Border(
                  top: BorderSide(color: Color(0xFFF1F5F9), width: 1.2),
                ),
                boxShadow: [
                  BoxShadow(
                    color: Color(0x0A000000),
                    blurRadius: 10,
                    offset: Offset(0, -3),
                  ),
                ],
              ),
              child: SafeArea(
                top: false,
                bottom: true,
                child: Padding(
                  padding: const EdgeInsets.only(left: 4, right: 4, top: 2, bottom: 2),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: isAdmin
                        ? [
                            _buildNavItem(0, Icons.grid_view_outlined, Icons.grid_view_rounded, 'Dashboard'),
                            _buildNavItem(1, Icons.description_outlined, Icons.description_rounded, 'Ajuan'),
                            _buildElevatedCenterNavItem(2, 'Data'),
                            _buildNavItem(3, Icons.calendar_month_outlined, Icons.calendar_month_rounded, 'Jadwal'),
                            _buildNavItem(4, Icons.person_outline_rounded, Icons.person_rounded, 'Profil'),
                          ]
                        : [
                            _buildNavItem(0, Icons.grid_view_outlined, Icons.grid_view_rounded, 'Dashboard'),
                            _buildNavItem(1, Icons.description_outlined, Icons.description_rounded, 'Ajuan'),
                            _buildNavItem(3, Icons.calendar_month_outlined, Icons.calendar_month_rounded, 'Jadwal'),
                            _buildNavItem(4, Icons.person_outline_rounded, Icons.person_rounded, 'Profil'),
                          ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
