// File: admin_filter_bottom_sheet.dart
// Deskripsi: Bottom sheet modal untuk memfilter fakultas, prodi, dan status pengajuan dosen di tingkat Administrator.

import 'package:flutter/material.dart';

import '../../../../../config/constants.dart';
import '../../../../../data/models/ajuan_pengajaran_model.dart';

void showAdminFilterBottomSheet({
  required BuildContext context,
  required List<String> availableFakultas,
  required List<AjuanPengajaranModel> liveAjuanList,
  required String currentFakultas,
  required String currentProdi,
  required String currentStatus,
  required Function(String fakultas, String prodi, String status) onApply,
}) {
  String tempFakultas = currentFakultas;
  String tempProdi = currentProdi;
  String tempStatus = currentStatus;

  showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (ctx) {
      return StatefulBuilder(
        builder: (context, setBottomSheetState) {
          final prodisForFakultas = tempFakultas == 'Semua'
              ? ['Semua', ...liveAjuanList.map((d) => d.jurusanNama).toSet()]
              : [
                  'Semua',
                  ...liveAjuanList
                      .where((d) => d.fakultasNama == tempFakultas)
                      .map((d) => d.jurusanNama)
                      .toSet(),
                ];

          if (!prodisForFakultas.contains(tempProdi)) {
            tempProdi = 'Semua';
          }

          return Container(
            decoration: const BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
            ),
            padding: EdgeInsets.only(
              left: 20,
              right: 20,
              top: 16,
              bottom: MediaQuery.of(context).viewInsets.bottom + 24,
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Center(
                  child: Container(
                    width: 40,
                    height: 4,
                    decoration: BoxDecoration(
                      color: const Color(0xFFCBD5E1),
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Row(
                      children: [
                        Icon(
                          Icons.tune_rounded,
                          color: AppColors.primary,
                          size: 22,
                        ),
                        SizedBox(width: 8),
                        Text(
                          'Filter Data Pengajuan',
                          style: TextStyle(
                            fontSize: 17,
                            fontWeight: FontWeight.bold,
                            color: AppColors.textPrimary,
                          ),
                        ),
                      ],
                    ),
                    IconButton(
                      onPressed: () => Navigator.pop(context),
                      icon: const Icon(
                        Icons.close_rounded,
                        color: Color(0xFF64748B),
                      ),
                      padding: EdgeInsets.zero,
                      constraints: const BoxConstraints(),
                    ),
                  ],
                ),
                const Divider(height: 24),
                const Text(
                  'Fakultas',
                  style: TextStyle(
                    fontSize: 12.5,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF334155),
                  ),
                ),
                const SizedBox(height: 6),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF8FAFC),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: const Color(0xFFCBD5E1)),
                  ),
                  child: DropdownButtonHideUnderline(
                    child: DropdownButton<String>(
                      value: availableFakultas.contains(tempFakultas)
                          ? tempFakultas
                          : 'Semua',
                      isExpanded: true,
                      icon: const Icon(
                        Icons.keyboard_arrow_down_rounded,
                        color: AppColors.primary,
                      ),
                      style: const TextStyle(
                        fontSize: 13,
                        color: Color(0xFF0F172A),
                      ),
                      items: availableFakultas.map((f) {
                        return DropdownMenuItem<String>(
                          value: f,
                          child: Text(f == 'Semua' ? 'Semua Fakultas' : f),
                        );
                      }).toList(),
                      onChanged: (val) {
                        if (val != null) {
                          setBottomSheetState(() {
                            tempFakultas = val;
                            tempProdi = 'Semua';
                          });
                        }
                      },
                    ),
                  ),
                ),
                const SizedBox(height: 14),
                const Text(
                  'Program Studi (Prodi)',
                  style: TextStyle(
                    fontSize: 12.5,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF334155),
                  ),
                ),
                const SizedBox(height: 6),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF8FAFC),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: const Color(0xFFCBD5E1)),
                  ),
                  child: DropdownButtonHideUnderline(
                    child: DropdownButton<String>(
                      value: prodisForFakultas.contains(tempProdi)
                          ? tempProdi
                          : 'Semua',
                      isExpanded: true,
                      icon: const Icon(
                        Icons.keyboard_arrow_down_rounded,
                        color: AppColors.primary,
                      ),
                      style: const TextStyle(
                        fontSize: 13,
                        color: Color(0xFF0F172A),
                      ),
                      items: prodisForFakultas.map((p) {
                        return DropdownMenuItem<String>(
                          value: p,
                          child: Text(p == 'Semua' ? 'Semua Prodi' : p),
                        );
                      }).toList(),
                      onChanged: (val) {
                        if (val != null) {
                          setBottomSheetState(() {
                            tempProdi = val;
                          });
                        }
                      },
                    ),
                  ),
                ),
                const SizedBox(height: 14),
                const Text(
                  'Status Ajuan',
                  style: TextStyle(
                    fontSize: 12.5,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF334155),
                  ),
                ),
                const SizedBox(height: 6),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF8FAFC),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: const Color(0xFFCBD5E1)),
                  ),
                  child: DropdownButtonHideUnderline(
                    child: DropdownButton<String>(
                      value: tempStatus,
                      isExpanded: true,
                      icon: const Icon(
                        Icons.keyboard_arrow_down_rounded,
                        color: AppColors.primary,
                      ),
                      style: const TextStyle(
                        fontSize: 13,
                        color: Color(0xFF0F172A),
                      ),
                      items: const [
                        DropdownMenuItem(
                          value: 'Semua',
                          child: Text('Semua Status'),
                        ),
                        DropdownMenuItem(
                          value: 'Diajukan',
                          child: Text('Menunggu KaProdi'),
                        ),
                        DropdownMenuItem(
                          value: 'Verifikasi KaProdi',
                          child: Text('Menunggu Dekan'),
                        ),
                        DropdownMenuItem(
                          value: 'Disetujui Dekan',
                          child: Text('Menunggu Admin'),
                        ),
                        DropdownMenuItem(
                          value: 'Disetujui Admin',
                          child: Text('Terjadwal Resmi'),
                        ),
                        DropdownMenuItem(
                          value: 'Banding',
                          child: Text('Menunggu Banding'),
                        ),
                        DropdownMenuItem(
                          value: 'Bentrok',
                          child: Text('Terdeteksi Bentrok'),
                        ),
                        DropdownMenuItem(
                          value: 'Ditolak',
                          child: Text('Ditolak'),
                        ),
                      ],
                      onChanged: (val) {
                        if (val != null) {
                          setBottomSheetState(() {
                            tempStatus = val;
                          });
                        }
                      },
                    ),
                  ),
                ),
                const SizedBox(height: 24),
                Row(
                  children: [
                    Expanded(
                      flex: 1,
                      child: OutlinedButton(
                        onPressed: () {
                          setBottomSheetState(() {
                            tempFakultas = 'Semua';
                            tempProdi = 'Semua';
                            tempStatus = 'Semua';
                          });
                        },
                        style: OutlinedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 13),
                          side: const BorderSide(color: Color(0xFFCBD5E1)),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10),
                          ),
                        ),
                        child: const Text(
                          'Reset',
                          style: TextStyle(
                            color: Color(0xFF64748B),
                            fontWeight: FontWeight.bold,
                            fontSize: 13.5,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      flex: 2,
                      child: ElevatedButton(
                        onPressed: () {
                          onApply(tempFakultas, tempProdi, tempStatus);
                          Navigator.pop(context);
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.primary,
                          padding: const EdgeInsets.symmetric(vertical: 13),
                          elevation: 0,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10),
                          ),
                        ),
                        child: const Text(
                          'Tampilkan!',
                          style: TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                            fontSize: 13.5,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          );
        },
      );
    },
  );
}
