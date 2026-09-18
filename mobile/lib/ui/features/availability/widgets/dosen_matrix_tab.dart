// File: dosen_matrix_tab.dart
// Deskripsi: Widget matriks ketersediaan waktu mengajar dosen (Grid slot waktu operasional).
// Fungsi: Menampilkan pilihan hari, daftar slot waktu, penautan mata kuliah/kelas, dan tombol simpan preferensi.

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../../config/constants.dart';
import '../../../core/widgets/custom_button.dart';
import '../view_models/availability_view_model.dart';
import 'availability_common_widgets.dart';
import 'matrix/dosen_matrix_course_summary.dart';
import 'matrix/dosen_matrix_slot_tag_sheet.dart';
import 'matrix/dosen_matrix_submit_dialog.dart';

class DosenMatrixTab extends StatefulWidget {
  const DosenMatrixTab({super.key});

  @override
  State<DosenMatrixTab> createState() => _DosenMatrixTabState();
}

class _DosenMatrixTabState extends State<DosenMatrixTab> {
  String _selectedDay = 'Senin';

  @override
  Widget build(BuildContext context) {
    final viewModel = context.watch<AvailabilityViewModel>();

    // Filter slots by selected day
    final daySlots = viewModel.allSlots
        .where((s) => s.hari == _selectedDay)
        .toList();

    return Column(
      children: [
        // ── Admin Locked Warning Banner (if submission window OFF) ──
        if (!viewModel.isSubmissionActive)
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(
              horizontal: 16,
              vertical: 10,
            ),
            color: AppColors.primary,
            child: Row(
              children: const [
                Icon(Icons.lock, color: Colors.white, size: 20),
                SizedBox(width: 10),
                Expanded(
                  child: Text(
                    'Sistem Dikunci Admin: Pengisian & perubahan ketersediaan waktu dosen saat ini ditutup.',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
          ),

        // ── Context Card: Mata Kuliah Diampu (Multi-Jurusan & Multi-Fakultas) ──
        DosenMatrixCourseSummary(viewModel: viewModel),

        const SizedBox(height: 10),

        // ── Progress Counter Bar ──
        Container(
          margin: const EdgeInsets.symmetric(horizontal: 16),
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: const Color(0xFFE2E8F0)),
          ),
          child: Column(
            children: [
              Row(
                children: [
                  // Selected count
                  Expanded(
                    child: Row(
                      children: [
                        Container(
                          width: 8,
                          height: 8,
                          decoration: BoxDecoration(
                            color: viewModel.meetsMinimumSks
                                ? AppColors.available
                                : AppColors.pending,
                            shape: BoxShape.circle,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Text(
                          '${viewModel.selectedCount}',
                          style: TextStyle(
                            fontSize: 17,
                            fontWeight: FontWeight.bold,
                            color: viewModel.meetsMinimumSks
                                ? AppColors.available
                                : AppColors.pending,
                          ),
                        ),
                        Text(
                          ' / ${viewModel.totalRequiredSks} Slot SKS Minimal',
                          style: const TextStyle(
                            fontSize: 12.5,
                            color: Color(0xFF64748B),
                          ),
                        ),
                      ],
                    ),
                  ),
                  // Status label
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 3,
                    ),
                    decoration: BoxDecoration(
                      color: viewModel.meetsMinimumSks
                          ? AppColors.available.withValues(alpha: 0.1)
                          : AppColors.pending.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      viewModel.meetsMinimumSks
                          ? 'Terpenuhi'
                          : 'Belum Cukup',
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                        color: viewModel.meetsMinimumSks
                            ? AppColors.available
                            : AppColors.pending,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              ClipRRect(
                borderRadius: BorderRadius.circular(4),
                child: LinearProgressIndicator(
                  value: viewModel.totalRequiredSks > 0
                      ? (viewModel.selectedCount /
                                viewModel.totalRequiredSks)
                            .clamp(0.0, 1.0)
                      : 0.0,
                  minHeight: 5,
                  backgroundColor: const Color(0xFFE2E8F0),
                  valueColor: AlwaysStoppedAnimation<Color>(
                    viewModel.meetsMinimumSks
                        ? AppColors.available
                        : AppColors.pending,
                  ),
                ),
              ),
            ],
          ),
        ),

        // Error / Success Messages
        if (viewModel.errorMessage != null)
          MessageBanner(
            message: viewModel.errorMessage!,
            color: AppColors.error,
            icon: Icons.error_outline_rounded,
          ),
        if (viewModel.successMessage != null)
          MessageBanner(
            message: viewModel.successMessage!,
            color: AppColors.available,
            icon: Icons.check_circle_outline_rounded,
          ),

        const SizedBox(height: 8),

        // ── Day Tabs Header ──
        Container(
          color: Colors.white,
          padding: const EdgeInsets.symmetric(vertical: 4),
          child: SizedBox(
            height: 40,
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 14),
              itemCount: kOperationalDays.length,
              itemBuilder: (context, index) {
                final day = kOperationalDays[index];
                final isSelected = day == _selectedDay;
                final daySlotCount = viewModel.allSlots
                    .where(
                      (s) =>
                          s.hari == day &&
                          viewModel.selectedSlotIds.contains(s.id),
                    )
                    .length;

                return GestureDetector(
                  onTap: () => setState(() => _selectedDay = day),
                  child: Container(
                    margin: const EdgeInsets.only(right: 6),
                    padding: const EdgeInsets.symmetric(horizontal: 14),
                    decoration: BoxDecoration(
                      border: Border(
                        bottom: BorderSide(
                          color: isSelected
                              ? AppColors.primary
                              : Colors.transparent,
                          width: 2.5,
                        ),
                      ),
                    ),
                    alignment: Alignment.center,
                    child: Row(
                      children: [
                        Text(
                          day,
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: isSelected
                                ? FontWeight.bold
                                : FontWeight.w600,
                            color: isSelected
                                ? AppColors.primary
                                : const Color(0xFF64748B),
                          ),
                        ),
                        if (daySlotCount > 0) ...[
                          const SizedBox(width: 5),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 5,
                              vertical: 1,
                            ),
                            decoration: BoxDecoration(
                              color: AppColors.primary,
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Text(
                              '$daySlotCount',
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 10,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
        ),
        Container(height: 1, color: const Color(0xFFE2E8F0)),

        // ── Time Slots Grid ──
        Expanded(
          child: RefreshIndicator(
            onRefresh: () async => viewModel.loadAvailabilityData(),
            color: AppColors.primary,
            child: daySlots.isEmpty
                ? SingleChildScrollView(
                    physics: const AlwaysScrollableScrollPhysics(),
                    child: Container(
                      height: 300,
                      alignment: Alignment.center,
                      child: const Text(
                        'Tidak ada slot waktu.',
                        style: TextStyle(
                          color: Color(0xFF64748B),
                          fontSize: 13,
                        ),
                      ),
                    ),
                  )
                : ListView.separated(
                    physics: const AlwaysScrollableScrollPhysics(),
                    padding: const EdgeInsets.fromLTRB(16, 12, 16, 20),
                    itemCount: daySlots.length,
                    separatorBuilder: (context, index) =>
                        const SizedBox(height: 8),
                    itemBuilder: (context, index) {
                      final slot = daySlots[index];
                      final isSelected = viewModel.selectedSlotIds.contains(
                        slot.id,
                      );
                      final isOccupied = viewModel.occupiedSlotIds.contains(
                        slot.id,
                      );
                      final isEarlyMorning =
                          slot.jamMulai.compareTo('09:50') < 0;
                      final tag = viewModel.slotTags[slot.id];

                      return GestureDetector(
                        onTap: isOccupied || !viewModel.isSubmissionActive
                            ? () {
                                if (isOccupied) {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    const SnackBar(
                                      content: Text(
                                        'Slot ini telah dipakai oleh dosen lain (Mutex Lock).',
                                      ),
                                      duration: Duration(seconds: 2),
                                    ),
                                  );
                                } else if (!viewModel.isSubmissionActive) {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    const SnackBar(
                                      content: Text(
                                        'Pengisian ketersediaan dikunci oleh Admin.',
                                      ),
                                      duration: Duration(seconds: 2),
                                    ),
                                  );
                                }
                              }
                            : () => showDosenMatrixSlotTagDialog(
                                context,
                                slot,
                                viewModel,
                              ),
                        onLongPress: !viewModel.isSubmissionActive
                            ? () {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(
                                    content: Text(
                                      'Pengisian ketersediaan dikunci oleh Admin.',
                                    ),
                                    duration: Duration(seconds: 2),
                                  ),
                                );
                              }
                            : null,
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 150),
                          padding: const EdgeInsets.symmetric(
                            horizontal: 14,
                            vertical: 12,
                          ),
                          decoration: BoxDecoration(
                            color: isOccupied
                                ? Colors.grey.withValues(alpha: 0.15)
                                : isSelected
                                ? AppColors.primary.withValues(alpha: 0.05)
                                : Colors.white,
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                              color: isOccupied
                                  ? Colors.grey.shade400
                                  : isSelected
                                  ? AppColors.primary
                                  : const Color(0xFFE2E8F0),
                              width: isSelected ? 1.5 : 1,
                            ),
                            boxShadow: isSelected
                                ? [
                                    BoxShadow(
                                      color: AppColors.primary.withValues(
                                        alpha: 0.06,
                                      ),
                                      blurRadius: 6,
                                      offset: const Offset(0, 2),
                                    ),
                                  ]
                                : null,
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  // Time label
                                  SizedBox(
                                    width: 110,
                                    child: Text(
                                      slot.label,
                                      style: TextStyle(
                                        fontSize: 13.5,
                                        fontWeight: FontWeight.bold,
                                        color: isOccupied
                                            ? Colors.grey
                                            : isSelected
                                            ? AppColors.primary
                                            : const Color(0xFF0F172A),
                                      ),
                                    ),
                                  ),
                                  // Building info or Occupied status
                                  Expanded(
                                    child: Text(
                                      isOccupied
                                          ? 'Dipakai Dosen Lain (Mutex)'
                                          : isEarlyMorning
                                          ? 'Gedung F (Pagi)'
                                          : 'Gedung A–F',
                                      style: TextStyle(
                                        fontSize: 12,
                                        color: isOccupied
                                            ? Colors.red[400]
                                            : isEarlyMorning
                                            ? const Color(0xFF0284C7)
                                            : const Color(0xFF64748B),
                                        fontWeight:
                                            (isOccupied || isEarlyMorning)
                                            ? FontWeight.w600
                                            : FontWeight.normal,
                                      ),
                                    ),
                                  ),
                                  // Toggle / Tag button
                                  if (isOccupied)
                                    const Icon(
                                      Icons.block,
                                      size: 18,
                                      color: Colors.grey,
                                    )
                                  else if (isSelected)
                                    Container(
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 8,
                                        vertical: 3,
                                      ),
                                      decoration: BoxDecoration(
                                        color: AppColors.primary,
                                        borderRadius: BorderRadius.circular(
                                          12,
                                        ),
                                      ),
                                      child: Row(
                                        mainAxisSize: MainAxisSize.min,
                                        children: const [
                                          Icon(
                                            Icons.check,
                                            size: 12,
                                            color: Colors.white,
                                          ),
                                          SizedBox(width: 4),
                                          Text(
                                            'Dipilih',
                                            style: TextStyle(
                                              color: Colors.white,
                                              fontSize: 10.5,
                                              fontWeight: FontWeight.bold,
                                            ),
                                          ),
                                        ],
                                      ),
                                    )
                                  else
                                    Container(
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 8,
                                        vertical: 3,
                                      ),
                                      decoration: BoxDecoration(
                                        color: const Color(0xFFF1F5F9),
                                        borderRadius: BorderRadius.circular(
                                          12,
                                        ),
                                        border: Border.all(
                                          color: const Color(0xFFCBD5E1),
                                        ),
                                      ),
                                      child: const Text(
                                        '+ Pilih',
                                        style: TextStyle(
                                          color: Color(0xFF64748B),
                                          fontSize: 11,
                                          fontWeight: FontWeight.w600,
                                        ),
                                      ),
                                    ),
                                ],
                              ),

                              // Course Tag Badge (if selected)
                              if (isSelected) ...[
                                const SizedBox(height: 8),
                                Container(
                                  width: double.infinity,
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 10,
                                    vertical: 6,
                                  ),
                                  decoration: BoxDecoration(
                                    color: tag != null
                                        ? const Color(
                                            0xFF0F766E,
                                          ).withValues(alpha: 0.08)
                                        : Colors.amber.shade50,
                                    borderRadius: BorderRadius.circular(8),
                                    border: Border.all(
                                      color: tag != null
                                          ? const Color(
                                              0xFF0F766E,
                                            ).withValues(alpha: 0.25)
                                          : Colors.amber.shade200,
                                    ),
                                  ),
                                  child: Row(
                                    children: [
                                      Icon(
                                        tag != null
                                            ? Icons.school_rounded
                                            : Icons.all_inclusive_rounded,
                                        size: 14,
                                        color: tag != null
                                            ? const Color(0xFF0F766E)
                                            : Colors.amber.shade800,
                                      ),
                                      const SizedBox(width: 6),
                                      Expanded(
                                        child: Text(
                                          tag != null
                                              ? '[${tag.kelasNama}] ${tag.mataKuliahNama} • ${tag.jurusanNama}'
                                              : 'Waktu Fleksibel (Dapat dialokasikan untuk matkul apa saja)',
                                          style: TextStyle(
                                            fontSize: 11,
                                            fontWeight: FontWeight.w600,
                                            color: tag != null
                                                ? const Color(0xFF0F766E)
                                                : Colors.amber.shade900,
                                          ),
                                          maxLines: 1,
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                      ),
                                      const Icon(
                                        Icons.edit_note_rounded,
                                        size: 15,
                                        color: Color(0xFF64748B),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ],
                          ),
                        ),
                      );
                    },
                  ),
          ),
        ),

        // ── Bottom Action Bar (only visible when slots selected and submission window active) ──
        if (viewModel.selectedCount > 0 && viewModel.isSubmissionActive)
          Container(
            padding: const EdgeInsets.fromLTRB(16, 10, 16, 20),
            decoration: const BoxDecoration(
              color: Colors.white,
              border: Border(top: BorderSide(color: Color(0xFFE2E8F0))),
            ),
            child: Row(
              children: [
                Expanded(
                  flex: 1,
                  child: CustomButton(
                    text: 'Reset',
                    isOutlined: true,
                    onPressed: () => viewModel.resetSelection(),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  flex: 2,
                  child: CustomButton(
                    text: viewModel.availability != null
                        ? 'Simpan Perubahan'
                        : 'Ajukan Ketersediaan',
                    icon: viewModel.availability != null
                        ? Icons.save_rounded
                        : Icons.send_rounded,
                    isLoading: viewModel.isSubmitting,
                    onPressed: () =>
                        showDosenMatrixSubmitConfirmationDialog(context, viewModel),
                  ),
                ),
              ],
            ),
          ),
      ],
    );
  }
}
