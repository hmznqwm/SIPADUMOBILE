// File: admin_automation_section.dart
// Deskripsi: Widget panel otomasi jadwal (Tombol Engine CSP dan Switch Window Ketersediaan).

import 'package:flutter/material.dart';

import '../../../../config/constants.dart';

class AdminAutomationSection extends StatelessWidget {
  final bool isSubmissionActive;
  final bool isEngineRunning;
  final bool hasAjuan;
  final bool isAllApprovedAndConflictFree;
  final VoidCallback onRunCSPEngine;
  final ValueChanged<bool> onToggleSubmissionStatus;

  const AdminAutomationSection({
    super.key,
    required this.isSubmissionActive,
    required this.isEngineRunning,
    this.hasAjuan = true,
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
        const SizedBox(height: 10),

        // ── Unified Merged Card (Duo Control Bento) ──
        Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: const Color(0xFFE2E8F0)),
            boxShadow: const [
              BoxShadow(
                color: Color(0x04000000),
                blurRadius: 4,
                offset: Offset(0, 2),
              ),
            ],
          ),
          child: Column(
            children: [
              // ── Row 1: Engine CSP ──
              Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Container(
                    width: 38,
                    height: 38,
                    decoration: BoxDecoration(
                      color: const Color(0xFFF1F5F9),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: const Icon(
                      Icons.settings_outlined,
                      color: Color(0xFF64748B),
                      size: 20,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Engine CSP',
                          style: TextStyle(
                            fontSize: 13.5,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF0F172A),
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          !hasAjuan
                              ? 'Belum ada ajuan jadwal'
                              : isAllApprovedAndConflictFree
                                  ? 'Jadwal Rapi & Optimal'
                                  : 'Generate jadwal otomatis',
                          style: const TextStyle(
                            fontSize: 11,
                            color: Color(0xFF64748B),
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 10),
                  SizedBox(
                    width: 90,
                    height: 34,
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: !hasAjuan
                            ? const Color(0xFFF1F5F9)
                            : isAllApprovedAndConflictFree
                                ? const Color(0xFF0F766E)
                                : AppColors.primary,
                        foregroundColor: !hasAjuan
                            ? const Color(0xFF94A3B8)
                            : Colors.white,
                        elevation: 0,
                        padding: EdgeInsets.zero,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                      onPressed: (!hasAjuan || isEngineRunning)
                          ? null
                          : onRunCSPEngine,
                      child: isEngineRunning
                          ? const SizedBox(
                              width: 14,
                              height: 14,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: Colors.white,
                              ),
                            )
                          : Text(
                              !hasAjuan
                                  ? 'Data Kosong'
                                  : isAllApprovedAndConflictFree
                                      ? 'Jadwal Rapi'
                                      : 'Jalankan',
                              style: TextStyle(
                                fontSize: !hasAjuan ? 11 : 12,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                    ),
                  ),
                ],
              ),

              // ── Hairline Divider ──
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 10),
                child: Container(
                  height: 1,
                  color: const Color(0xFFF1F5F9),
                ),
              ),

              // ── Row 2: Window Ketersediaan ──
              Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Container(
                    width: 38,
                    height: 38,
                    decoration: BoxDecoration(
                      color: const Color(0xFFF1F5F9),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: const Icon(
                      Icons.calendar_today_outlined,
                      color: Color(0xFF64748B),
                      size: 18,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Jendela Ketersediaan',
                          style: TextStyle(
                            fontSize: 13.5,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF0F172A),
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          isSubmissionActive
                              ? 'Akses dosen terbuka'
                              : 'Akses dosen ditutup',
                          style: const TextStyle(
                            fontSize: 11,
                            color: Color(0xFF64748B),
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 10),
                    SizedBox(
                    width: 90,
                    height: 34,
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: isSubmissionActive
                            ? const Color(0xFFF1F5F9)
                            : AppColors.primary,
                        foregroundColor: isSubmissionActive
                            ? const Color(0xFF0F172A)
                            : Colors.white,
                        side: BorderSide(
                          color: isSubmissionActive
                              ? const Color(0xFFE2E8F0)
                              : AppColors.primary,
                        ),
                        elevation: 0,
                        padding: EdgeInsets.zero,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                      onPressed: () =>
                          onToggleSubmissionStatus(!isSubmissionActive),
                      child: Text(
                        isSubmissionActive ? 'Matikan' : 'Aktifkan',
                        style: const TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ],
    );
  }
}
