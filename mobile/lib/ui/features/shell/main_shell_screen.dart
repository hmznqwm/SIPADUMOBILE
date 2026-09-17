// File: main_shell_screen.dart
// Deskripsi: Tampilan utama kontainer (Shell Screen) dengan bilah navigasi bawah (Bottom Navigation Bar).
// Fungsi: Mengelola perpindahan tab utama (Dashboard, Ketersediaan, Jadwal, Profil), AppBar universal, fitur simulasi switch role, dan notifikasi.

import 'package:flutter/material.dart';
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

  Widget _buildNavItem(int index, IconData icon, IconData activeIcon, String label) {
    final isSelected = _currentIndex == index;
    return InkWell(
      onTap: () => _onTabTapped(index),
      borderRadius: BorderRadius.circular(24),
      splashColor: AppColors.primary.withValues(alpha: 0.08),
      highlightColor: Colors.transparent,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 220),
        curve: Curves.easeInOutCubic,
        padding: EdgeInsets.symmetric(
          horizontal: isSelected ? 14 : 10,
          vertical: 8,
        ),
        decoration: BoxDecoration(
          color: isSelected ? AppColors.primary.withValues(alpha: 0.12) : Colors.transparent,
          borderRadius: BorderRadius.circular(24),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              isSelected ? activeIcon : icon,
              color: isSelected ? AppColors.primary : const Color(0xFF64748B),
              size: 22,
            ),
            if (isSelected) ...[
              const SizedBox(width: 6),
              Text(
                label,
                style: const TextStyle(
                  color: AppColors.primary,
                  fontWeight: FontWeight.bold,
                  fontSize: 12.5,
                  letterSpacing: 0.2,
                ),
              ),
            ],
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

    return Scaffold(
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
        children: pages.map((page) {
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
      bottomNavigationBar: Container(
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
          child: Container(
            height: 60,
            padding: const EdgeInsets.symmetric(horizontal: 8),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              crossAxisAlignment: CrossAxisAlignment.center,
              children: isAdmin
                  ? [
                      _buildNavItem(0, Icons.home_outlined, Icons.home_rounded, 'Home'),
                      _buildNavItem(1, Icons.grid_view_outlined, Icons.grid_view_rounded, 'Ajuan'),
                      _buildNavItem(2, Icons.storage_outlined, Icons.storage_rounded, 'Master'),
                      _buildNavItem(3, Icons.calendar_today_outlined, Icons.calendar_month_rounded, 'Jadwal'),
                      _buildNavItem(4, Icons.person_outline_rounded, Icons.person_rounded, 'Profil'),
                    ]
                  : [
                      _buildNavItem(0, Icons.home_outlined, Icons.home_rounded, 'Home'),
                      _buildNavItem(1, Icons.grid_view_outlined, Icons.grid_view_rounded, 'Ajuan'),
                      _buildNavItem(3, Icons.calendar_today_outlined, Icons.calendar_month_rounded, 'Jadwal'),
                      _buildNavItem(4, Icons.person_outline_rounded, Icons.person_rounded, 'Profil'),
                    ],
            ),
          ),
        ),
      ),
    );
  }
}
