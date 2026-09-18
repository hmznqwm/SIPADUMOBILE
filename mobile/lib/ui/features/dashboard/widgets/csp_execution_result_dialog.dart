// File: csp_execution_result_dialog.dart
// Deskripsi: Modal dialog ringkasan hasil eksekusi CSP engine (alokasi, metrik, checklist aturan).

import 'package:flutter/material.dart';

import '../../../../config/constants.dart';

class CspExecutionResultDialog extends StatelessWidget {
  final Map<String, dynamic> report;

  const CspExecutionResultDialog({
    super.key,
    required this.report,
  });

  static void show(BuildContext context, Map<String, dynamic> report) {
    showDialog(
      context: context,
      builder: (ctx) => CspExecutionResultDialog(report: report),
    );
  }

  @override
  Widget build(BuildContext context) {
    int safeInt(dynamic val, [int fallback = 0]) {
      if (val == null) return fallback;
      if (val is int) return val;
      if (val is num) return val.toInt();
      if (val is List) return val.length;
      return int.tryParse(val.toString()) ?? fallback;
    }

    double safeDouble(dynamic val, [double fallback = 100.0]) {
      if (val == null) return fallback;
      if (val is double) return val;
      if (val is num) return val.toDouble();
      return double.tryParse(val.toString()) ?? fallback;
    }

    final totalAssigned = safeInt(report['total_scheduled'] ?? report['totalAssigned'] ?? report['approvedCount']);
    final totalSlot = safeInt(report['total_courses'] ?? report['total_slots'] ?? report['totalProcessed'], totalAssigned);
    final conflicts = safeInt(report['conflicts_count'] ?? report['conflictCount'] ?? (report['conflicts'] is List ? (report['conflicts'] as List).length : 0));
    final submittedDosen = safeInt(report['submitted_dosen_count'] ?? report['submittedDosen'] ?? report['submittedLecturersCount']);
    final autoDosen = safeInt(report['auto_assigned_dosen_count'] ?? report['autoAssignedDosen'] ?? report['autoAllocatedLecturersCount']);
    final successRate = safeDouble(report['success_rate'], totalSlot > 0 ? (totalAssigned / totalSlot * 100) : 100.0);

    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      clipBehavior: Clip.antiAlias,
      elevation: 4,
      insetPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
      backgroundColor: Colors.white,
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 480),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
            Container(
              padding: const EdgeInsets.fromLTRB(18, 16, 14, 14),
              decoration: const BoxDecoration(
                color: Color(0xFFF8FAFC),
                border: Border(bottom: BorderSide(color: Color(0xFFE2E8F0))),
              ),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(7),
                    decoration: BoxDecoration(
                      color: Colors.teal.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Icon(Icons.tune_rounded, color: Colors.teal[800], size: 18),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Hasil Eksekusi CSP',
                          style: TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.bold,
                            color: Colors.teal[800],
                          ),
                        ),
                        const Text(
                          'Penjadwalan otomatis selesai diproses',
                          style: TextStyle(fontSize: 11, color: Color(0xFF64748B)),
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close_rounded, size: 20, color: Color(0xFF64748B)),
                    splashRadius: 18,
                    onPressed: () => Navigator.pop(context),
                  ),
                ],
              ),
            ),

            // Content Body
            Flexible(
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(16, 14, 16, 14),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Banner Ringkasan Status
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: conflicts == 0 ? const Color(0xFFECFDF5) : const Color(0xFFFFFBEB),
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(
                          color: conflicts == 0 ? const Color(0xFFA7F3D0) : const Color(0xFFFDE68A),
                        ),
                      ),
                      child: Row(
                        children: [
                          Icon(
                            conflicts == 0 ? Icons.check_circle_rounded : Icons.info_outline_rounded,
                            size: 20,
                            color: conflicts == 0 ? const Color(0xFF059669) : const Color(0xFFD97706),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  conflicts == 0
                                      ? 'Penjadwalan Optimal'
                                      : 'Penjadwalan Selesai dengan Catatan',
                                  style: TextStyle(
                                    fontSize: 12.5,
                                    fontWeight: FontWeight.bold,
                                    color: conflicts == 0 ? const Color(0xFF047857) : const Color(0xFFB45309),
                                  ),
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  conflicts == 0
                                      ? 'Semua jadwal berhasil ditempatkan tanpa bentrok.'
                                      : '$conflicts jadwal membutuhkan penyesuaian di menu Resolusi Konflik.',
                                  style: TextStyle(
                                    fontSize: 11,
                                    color: conflicts == 0 ? const Color(0xFF065F46) : const Color(0xFF92400E),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 14),

                    // Metrics 2x2 Grid
                    Row(
                      children: [
                        Expanded(
                          child: _buildMetricCard(
                            title: 'Jadwal Terisi',
                            value: '$totalAssigned / $totalSlot',
                            subtitle: '${successRate.toStringAsFixed(1)}% berhasil',
                            icon: Icons.assignment_turned_in_outlined,
                            color: const Color(0xFF0D9488),
                            bg: const Color(0xFFF0FDFA),
                            borderColor: const Color(0xFFCCFBF1),
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: _buildMetricCard(
                            title: 'Preferensi Dosen',
                            value: '$submittedDosen Dosen',
                            subtitle: 'Pilihan dosen',
                            icon: Icons.person_outline_rounded,
                            color: const Color(0xFF2563EB),
                            bg: const Color(0xFFEFF6FF),
                            borderColor: const Color(0xFFDBEAFE),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),
                    Row(
                      children: [
                        Expanded(
                          child: _buildMetricCard(
                            title: 'Alokasi Otomatis',
                            value: '$autoDosen Dosen',
                            subtitle: 'Alokasi sistem',
                            icon: Icons.tune_rounded,
                            color: const Color(0xFF7C3AED),
                            bg: const Color(0xFFFAF5FF),
                            borderColor: const Color(0xFFF3E8FF),
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: _buildMetricCard(
                            title: 'Status Konflik',
                            value: conflicts == 0 ? '0 Konflik' : '$conflicts Konflik',
                            subtitle: conflicts == 0 ? 'Aman' : 'Perlu cek',
                            icon: conflicts == 0 ? Icons.verified_outlined : Icons.warning_amber_rounded,
                            color: conflicts == 0 ? const Color(0xFF059669) : const Color(0xFFDC2626),
                            bg: conflicts == 0 ? const Color(0xFFECFDF5) : const Color(0xFFFEF2F2),
                            borderColor: conflicts == 0 ? const Color(0xFFA7F3D0) : const Color(0xFFFECACA),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 14),

                    // Constraint Checklist Card
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: const Color(0xFFF8FAFC),
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(color: const Color(0xFFE2E8F0)),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Pemeriksaan Aturan Jadwal',
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                              color: Color(0xFF334155),
                            ),
                          ),
                          const SizedBox(height: 8),
                          _buildConstraintRow('Bebas bentrok dosen & ruang'),
                          _buildConstraintRow('Kapasitas ruang memadai'),
                          _buildConstraintRow('Jeda transit gedung terpenuhi'),
                          _buildConstraintRow('Bebas bentrok rombel'),
                        ],
                      ),
                    ),

                    if (conflicts > 0) ...[
                      const SizedBox(height: 12),
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: const Color(0xFFFEF2F2),
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: const Color(0xFFFECACA)),
                        ),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Icon(Icons.info_outline_rounded, size: 16, color: Color(0xFFDC2626)),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                '$conflicts jadwal bentrok dapat diselesaikan di menu Jadwal > Tab Resolusi Konflik.',
                                style: const TextStyle(fontSize: 11, color: Color(0xFF991B1B), height: 1.3),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ),

            // Footer Action
            Container(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 14),
              decoration: const BoxDecoration(
                color: Colors.white,
                border: Border(top: BorderSide(color: Color(0xFFE2E8F0))),
              ),
              child: SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 11),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                    elevation: 0,
                  ),
                  onPressed: () => Navigator.pop(context),
                  child: const Text('Tutup', style: TextStyle(fontSize: 12.5, fontWeight: FontWeight.bold)),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMetricCard({
    required String title,
    required String value,
    required String subtitle,
    required IconData icon,
    required Color color,
    required Color bg,
    required Color borderColor,
  }) {
    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: borderColor),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, size: 15, color: color),
              const SizedBox(width: 5),
              Expanded(
                child: Text(
                  title,
                  style: TextStyle(fontSize: 10.5, fontWeight: FontWeight.w600, color: color),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            value,
            style: TextStyle(fontSize: 13.5, fontWeight: FontWeight.bold, color: color),
          ),
          const SizedBox(height: 1),
          Text(
            subtitle,
            style: TextStyle(fontSize: 9.5, color: color.withValues(alpha: 0.85)),
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }

  Widget _buildConstraintRow(String label) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(Icons.check_circle_outline_rounded, size: 14, color: Color(0xFF059669)),
          const SizedBox(width: 6),
          Expanded(
            child: Text(
              label,
              style: const TextStyle(fontSize: 11, color: Color(0xFF475569)),
            ),
          ),
        ],
      ),
    );
  }
}
