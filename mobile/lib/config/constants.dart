// File: constants.dart
// Deskripsi: Berisi konstanta global aplikasi seperti warna (palette), spacing, radius, dan konstanta operasional jadwal.
// Fungsi: Menyediakan nilai terpusat untuk konsistensi tampilan UI dan aturan operasional perkuliahan.

import 'package:flutter/material.dart';

class AppColors {
  AppColors._();

  // Flat Color Palette extracted from the SIAKAD UIN Malang Screenshot
  static const Color primary = Color(0xFF00897B); // Hijau Tosca Solid (dari foto)
  static const Color primaryLight = Color(0xFF00A896);
  static const Color primaryDark = Color(0xFF00695C);

  // Yellow Warm Accent (dari aksen kanan foto)
  static const Color primaryAccent = Color(0xFFD97706); // Kuning Oker Solid (dari foto)
  static const Color yellowSoft = Color(0xFFFEF3C7);
  static const Color yellowBackground = Color(0xFFFFFBEB);

  static const Color secondary = Color(0xFF00897B);
  static const Color secondaryLight = Color(0xFFE6F4F1);

  // Background & Surfaces (Putih Murni Flat)
  static const Color background = Colors.white;
  static const Color surface = Colors.white;
  static const Color surfaceVariant = Color(0xFFE6F4F1); // Soft Light Teal Circle Background
  static const Color cardBackground = Colors.white;

  // Status Colors
  static const Color available = Color(0xFF00897B);
  static const Color booked = Color(0xFF1D4ED8);
  static const Color conflict = Color(0xFFDC2626);
  static const Color pending = Color(0xFFD97706);
  static const Color unavailable = Color(0xFF64748B);

  // Typography Colors
  static const Color textPrimary = Color(0xFF0F172A);
  static const Color textSecondary = Color(0xFF475569);
  static const Color textTertiary = Color(0xFF94A3B8);
  static const Color textOnPrimary = Colors.white;

  // Borders & Dividers
  static const Color border = Color(0xFFE2E8F0);
  static const Color borderLight = Color(0xFFF1F5F9);

  // Status Feedback
  static const Color error = Color(0xFFDC2626);
  static const Color success = Color(0xFF00897B);
  static const Color warning = Color(0xFFD97706);
  static const Color info = Color(0xFF1D4ED8);

  // Flat Elevation (No Heavy Shadows)
  static const List<BoxShadow> cardShadow = [];
}

class AppSpacing {
  AppSpacing._();

  static const double xs = 4.0;
  static const double sm = 8.0;
  static const double md = 12.0;
  static const double lg = 16.0;
  static const double xl = 24.0;
  static const double xxl = 32.0;
}

class AppRadius {
  AppRadius._();

  static const double sm = 8.0;
  static const double md = 12.0;
  static const double lg = 16.0;
  static const double xl = 24.0;
  static const double full = 100.0;
}

// Operational Constants per PRD
const List<String> kOperationalDays = [
  'Senin',
  'Selasa',
  'Rabu',
  'Kamis',
  'Jumat',
];

const int kDefaultSksDurationMinutes = 50;
const String kBuildingAEOpenTime = '09:50';
const String kBuildingAECloseTime = '16:30';
const String kBuildingFOpenTime = '06:30';
const String kBuildingFCloseTime = '16:30';
const String kMaxEndTime = '16:30';
