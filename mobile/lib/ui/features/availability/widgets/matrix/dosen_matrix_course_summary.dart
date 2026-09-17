// File: dosen_matrix_course_summary.dart
// Deskripsi: Widget kartu ringkasan mata kuliah diampu dosen (multi-jurusan & multi-fakultas) beserta toggle detail ekspansi.

import 'package:flutter/material.dart';

import '../../../../../config/constants.dart';
import '../../view_models/availability_view_model.dart';

class DosenMatrixCourseSummary extends StatefulWidget {
  final AvailabilityViewModel viewModel;

  const DosenMatrixCourseSummary({super.key, required this.viewModel});

  @override
  State<DosenMatrixCourseSummary> createState() => _DosenMatrixCourseSummaryState();
}

class _DosenMatrixCourseSummaryState extends State<DosenMatrixCourseSummary> {
  bool _showCourseDetails = false;

  @override
  Widget build(BuildContext context) {
    final viewModel = widget.viewModel;

    // Group mata kuliah by fakultas & jurusan
    final mkByFakultas = <String, Map<String, List<dynamic>>>{};
    for (final mk in viewModel.mataKuliahList) {
      mkByFakultas.putIfAbsent(mk.fakultasNama, () => {});
      mkByFakultas[mk.fakultasNama]!
          .putIfAbsent(mk.jurusanNama, () => [])
          .add(mk);
    }

    final totalJurusanCount = viewModel.mataKuliahList
        .map((m) => m.jurusanNama)
        .toSet()
        .length;
    final totalFakultasCount = mkByFakultas.keys.length;

    return Container(
      margin: const EdgeInsets.fromLTRB(16, 6, 16, 0),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFFE2E8F0)),
        boxShadow: const [
          BoxShadow(
            color: Color(0x05000000),
            blurRadius: 8,
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        children: [
          InkWell(
            onTap: () => setState(
              () => _showCourseDetails = !_showCourseDetails,
            ),
            borderRadius: BorderRadius.circular(14),
            child: Padding(
              padding: const EdgeInsets.all(14),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: AppColors.primary.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: const Icon(
                      Icons.menu_book_rounded,
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
                          '${viewModel.mataKuliahList.length} Mata Kuliah Diampu',
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 14.5,
                            color: Color(0xFF0F172A),
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          '$totalFakultasCount Fakultas  •  $totalJurusanCount Jurusan  •  ${viewModel.totalRequiredSks} SKS Total',
                          style: const TextStyle(
                            fontSize: 12,
                            color: Color(0xFF64748B),
                          ),
                        ),
                      ],
                    ),
                  ),
                  Icon(
                    _showCourseDetails
                        ? Icons.keyboard_arrow_up_rounded
                        : Icons.keyboard_arrow_down_rounded,
                    color: const Color(0xFF94A3B8),
                  ),
                ],
              ),
            ),
          ),

          // Detail Mata Kuliah grouped by Fakultas & Jurusan
          if (_showCourseDetails) ...[
            Container(height: 1, color: const Color(0xFFE2E8F0)),
            Padding(
              padding: const EdgeInsets.all(14),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: mkByFakultas.entries.map((fakEntry) {
                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Fakultas Header Tag
                      Container(
                        margin: const EdgeInsets.only(
                          bottom: 8,
                          top: 4,
                        ),
                        padding: const EdgeInsets.symmetric(
                          horizontal: 9,
                          vertical: 3,
                        ),
                        decoration: BoxDecoration(
                          color: const Color(0xFFF1F5F9),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Text(
                          fakEntry.key.toUpperCase(),
                          style: const TextStyle(
                            fontSize: 10.5,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF334155),
                            letterSpacing: 0.5,
                          ),
                        ),
                      ),
                      // Jurusan groups inside Fakultas
                      ...fakEntry.value.entries.map((jurEntry) {
                        return Padding(
                          padding: const EdgeInsets.only(
                            left: 4,
                            bottom: 8,
                          ),
                          child: Column(
                            crossAxisAlignment:
                                CrossAxisAlignment.start,
                            children: [
                              Text(
                                '• ${jurEntry.key}',
                                style: const TextStyle(
                                  fontSize: 12.5,
                                  fontWeight: FontWeight.bold,
                                  color: AppColors.primary,
                                ),
                              ),
                              const SizedBox(height: 4),
                              ...jurEntry.value.map(
                                (mk) => Padding(
                                  padding: const EdgeInsets.only(
                                    left: 12,
                                    bottom: 4,
                                  ),
                                  child: Row(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      const Text(
                                        '-',
                                        style: TextStyle(
                                          color: Color(0xFF94A3B8),
                                          fontSize: 12,
                                        ),
                                      ),
                                      const SizedBox(width: 6),
                                      Expanded(
                                        child: RichText(
                                          text: TextSpan(
                                            style: const TextStyle(
                                              fontSize: 12.5,
                                              color: Color(0xFF1E293B),
                                              height: 1.35,
                                            ),
                                            children: [
                                              TextSpan(
                                                text: mk.nama,
                                                style: const TextStyle(
                                                  fontWeight:
                                                      FontWeight.w600,
                                                ),
                                              ),
                                              TextSpan(
                                                text: '  ${mk.sks} SKS',
                                                style: const TextStyle(
                                                  color:
                                                      AppColors.primary,
                                                  fontWeight:
                                                      FontWeight.bold,
                                                  fontSize: 11,
                                                ),
                                              ),
                                              TextSpan(
                                                text:
                                                    '  •  Kelas: ${mk.kelasNama.join(", ")}',
                                                style: const TextStyle(
                                                  color: Color(
                                                    0xFF64748B,
                                                  ),
                                                  fontSize: 11.5,
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
                            ],
                          ),
                        );
                      }),
                    ],
                  );
                }).toList(),
              ),
            ),
          ],
        ],
      ),
    );
  }
}
