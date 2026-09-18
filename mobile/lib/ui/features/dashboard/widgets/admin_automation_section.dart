// File: admin_automation_section.dart
// Deskripsi: Widget panel otomasi jadwal (Tombol Engine CSP dan Switch Window Ketersediaan).

import 'package:flutter/material.dart';

import '../../../../config/constants.dart';

class AdminAutomationSection extends StatelessWidget {
  final bool isSubmissionActive;
  final bool isEngineRunning;
  final bool isAllApprovedAndConflictFree;
  final VoidCallback onRunCSPEngine;
  final ValueChanged<bool> onToggleSubmissionStatus;

  const AdminAutomationSection({
    super.key,
    required this.isSubmissionActive,
    required this.isEngineRunning,
    this.isAllApprovedAndConflictFree = false,
    required this.onRunCSPEngine,
    required this.onToggleSubmissionStatus,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Otomasi & Kontrol Jadwal',
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.bold,
            color: AppColors.textPrimary,
          ),
        ),
        const SizedBox(height: 8),

        // ── Engine CSP Action Bar ──
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(AppSpacing.md),
          decoration: BoxDecoration(
            color: isAllApprovedAndConflictFree
                ? AppColors.surfaceVariant
                : Colors.white,
            borderRadius: BorderRadius.circular(AppRadius.md),
            border: Border.all(
              color: isAllApprovedAndConflictFree
                  ? AppColors.primary.withValues(alpha: 0.3)
                  : const Color(0xFFE2E8F0),
            ),
            boxShadow: const [
              BoxShadow(
                color: Color(0x04000000),
                blurRadius: 4,
                offset: Offset(0, 1),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: AppColors.primary.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Icon(
                      isAllApprovedAndConflictFree
                          ? Icons.task_alt_rounded
                          : Icons.tune_rounded,
                      color: AppColors.primary,
                      size: 20,
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Engine CSP',
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.bold,
                            color: AppColors.textPrimary,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          isAllApprovedAndConflictFree
                              ? 'Jadwal Rapi & Optimal'
                              : 'Generate jadwal otomatis',
                          style: const TextStyle(
                            fontSize: 11,
                            color: AppColors.textSecondary,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 8),
                  ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primary,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                      elevation: 0,
                    ),
                    onPressed: isEngineRunning ? null : onRunCSPEngine,
                    child: isEngineRunning
                        ? const SizedBox(
                            width: 16,
                            height: 16,
                            child: CircularProgressIndicator(
                              strokeWidth: 2.2,
                              color: Colors.white,
                            ),
                          )
                        : Text(
                            isAllApprovedAndConflictFree ? 'Jadwal Rapi' : 'Jalankan',
                            style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
                          ),
                  ),
                ],
              ),
              if (isAllApprovedAndConflictFree) ...[
                const SizedBox(height: 8),
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.85),
                    borderRadius: BorderRadius.circular(6),
                    border: Border.all(color: AppColors.primary.withValues(alpha: 0.25)),
                  ),
                  child: const Row(
                    children: [
                      Icon(Icons.info_outline_rounded, color: AppColors.primary, size: 14),
                      SizedBox(width: 6),
                      Expanded(
                        child: Text(
                          'Tidak ada jadwal yang perlu dirapikan (Semua pengajuan disetujui & 0 bentrok).',
                          style: TextStyle(
                            fontSize: 10.5,
                            color: AppColors.primaryDark,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ],
          ),
        ),
        const SizedBox(height: 10),

        // ── Window Submission Lock Toggle ──
        Container(
          padding: const EdgeInsets.all(AppSpacing.md),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(AppRadius.md),
            border: Border.all(color: const Color(0xFFE2E8F0)),
            boxShadow: const [
              BoxShadow(
                color: Color(0x04000000),
                blurRadius: 4,
                offset: Offset(0, 1),
              ),
            ],
          ),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: AppColors.primary.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(
                  isSubmissionActive ? Icons.lock_open_rounded : Icons.lock_outline_rounded,
                  color: AppColors.primary,
                  size: 20,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      isSubmissionActive ? 'Window Ketersediaan: Buka' : 'Window Ketersediaan: Kunci',
                      style: const TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.bold,
                        color: AppColors.primary,
                      ),
                    ),
                    Text(
                      isSubmissionActive
                          ? 'Akses dosen terbuka'
                          : 'Akses dosen ditutup',
                      style: const TextStyle(fontSize: 11, color: AppColors.textSecondary),
                    ),
                  ],
                ),
              ),
              Switch(
                value: isSubmissionActive,
                activeTrackColor: AppColors.primary.withValues(alpha: 0.4),
                activeThumbColor: AppColors.primary,
                onChanged: onToggleSubmissionStatus,
              ),
            ],
          ),
        ),
      ],
    );
  }
}
