// File: status_badge.dart
// Deskripsi: Widget label status berlatar belakang warna transparan.
// Fungsi: Menampilkan indikator visual status (seperti Disetujui, Ditolak, Draft, Perlu Revisi) dengan penyesuaian warna otomatis.

import 'package:flutter/material.dart';

import '../../../config/constants.dart';

class StatusBadge extends StatelessWidget {
  final String status;
  final String? customLabel;

  const StatusBadge({
    super.key,
    required this.status,
    this.customLabel,
  });

  @override
  Widget build(BuildContext context) {
    final (bgColor, textColor, defaultLabel) = _getBadgeStyle(status);

    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: 10,
        vertical: 4,
      ),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(AppRadius.full),
        border: Border.all(
          color: textColor.withValues(alpha: 0.2),
          width: 1,
        ),
      ),
      child: Text(
        customLabel ?? defaultLabel,
        style: TextStyle(
          color: textColor,
          fontSize: 11,
          fontWeight: FontWeight.w700,
          letterSpacing: 0.2,
        ),
      ),
    );
  }

  (Color, Color, String) _getBadgeStyle(String status) {
    switch (status.toLowerCase()) {
      case 'approved':
      case 'disetujui':
      case 'submitted':
      case 'tersedia':
        return (
          AppColors.available.withValues(alpha: 0.12),
          AppColors.available,
          'Disetujui',
        );
      case 'rejected':
      case 'ditolak':
        return (
          AppColors.conflict.withValues(alpha: 0.12),
          AppColors.conflict,
          'Ditolak',
        );
      case 'revision':
      case 'revisi':
      case 'perlu revisi':
        return (
          AppColors.pending.withValues(alpha: 0.12),
          AppColors.pending,
          'Perlu Revisi',
        );
      case 'draft':
      case 'tidak tersedia':
      case 'kosong':
        return (
          AppColors.surfaceVariant,
          AppColors.textSecondary,
          'Draft',
        );
      default:
        return (
          AppColors.surfaceVariant,
          AppColors.textPrimary,
          status,
        );
    }
  }
}
