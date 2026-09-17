// File: dosen_matrix_submit_dialog.dart
// Deskripsi: Dialog konfirmasi pengajuan / pembaruan ketersediaan jadwal mengajar dosen.

import 'package:flutter/material.dart';

import '../../../../../config/constants.dart';
import '../../view_models/availability_view_model.dart';
import '../availability_common_widgets.dart';

void showDosenMatrixSubmitConfirmationDialog(
  BuildContext context,
  AvailabilityViewModel viewModel,
) {
  final isUpdate = viewModel.availability != null;
  final totalSlots = viewModel.selectedCount;
  final taggedSlots = viewModel.slotTags.length;
  final flexibleSlots = totalSlots - taggedSlots;

  showDialog(
    context: context,
    barrierDismissible: true,
    builder: (ctx) => AlertDialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      titlePadding: const EdgeInsets.fromLTRB(20, 20, 20, 10),
      contentPadding: const EdgeInsets.symmetric(horizontal: 20),
      actionsPadding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
      title: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: isUpdate
                  ? AppColors.primary.withValues(alpha: 0.1)
                  : const Color(0xFF0F766E).withValues(alpha: 0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(
              isUpdate ? Icons.update_rounded : Icons.verified_rounded,
              color: isUpdate ? AppColors.primary : const Color(0xFF0F766E),
              size: 24,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              isUpdate ? 'Perbarui Ketersediaan?' : 'Ajukan Ketersediaan?',
              style: const TextStyle(
                fontSize: 17,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            isUpdate
                ? 'Anda akan memperbarui jadwal ketersediaan waktu mengajar dengan rincian berikut:'
                : 'Pastikan pilihan waktu Anda sudah sesuai dengan rincian berikut:',
            style: const TextStyle(
              fontSize: 13,
              color: Color(0xFF475569),
              height: 1.4,
            ),
          ),
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: const Color(0xFFF8FAFC),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: const Color(0xFFE2E8F0)),
            ),
            child: Column(
              children: [
                ConfirmRow(
                  icon: Icons.timer_outlined,
                  label: 'Total Slot Waktu',
                  value: '$totalSlots Slot (${totalSlots * 2} Jam)',
                  valueColor: const Color(0xFF0F172A),
                ),
                const Divider(height: 14, color: Color(0xFFE2E8F0)),
                ConfirmRow(
                  icon: Icons.school_outlined,
                  label: 'Mata Kuliah Tertaut',
                  value: '$taggedSlots Slot',
                  valueColor: const Color(0xFF0F766E),
                ),
                const Divider(height: 14, color: Color(0xFFE2E8F0)),
                ConfirmRow(
                  icon: Icons.all_inclusive_rounded,
                  label: 'Waktu Fleksibel',
                  value: '$flexibleSlots Slot',
                  valueColor: Colors.amber.shade900,
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: const Color(0xFFEFF6FF),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: const Color(0xFFBFDBFE)),
            ),
            child: const Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(
                  Icons.info_outline_rounded,
                  size: 16,
                  color: Color(0xFF2563EB),
                ),
                SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Pilihan ini dapat Anda ubah atau sesuaikan kembali kapan saja selama periode pengisian jadwal masih dibuka.',
                    style: TextStyle(
                      fontSize: 11,
                      color: Color(0xFF1D4ED8),
                      height: 1.3,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
      actions: [
        Row(
          children: [
            Expanded(
              child: OutlinedButton(
                onPressed: () => Navigator.pop(ctx),
                style: OutlinedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  side: const BorderSide(color: Color(0xFFCBD5E1)),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
                child: const Text(
                  'Periksa Lagi',
                  style: TextStyle(
                    color: Color(0xFF64748B),
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: ElevatedButton(
                onPressed: () async {
                  Navigator.pop(ctx);
                  await viewModel.submitAvailability();
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  elevation: 0,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
                child: Text(
                  isUpdate ? 'Ya, Perbarui' : 'Ya, Ajukan',
                  style: const TextStyle(
                    fontSize: 13.5,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
          ],
        ),
      ],
    ),
  );
}
