// File: conflict_check_bottom_sheet.dart
// Deskripsi: Modal Bottom Sheet untuk mengecek status dan rincian bentrok jadwal ajuan perkuliahan.

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../../../config/constants.dart';
import '../../../../../data/models/ajuan_pengajaran_model.dart';
import '../../../../../data/models/jadwal_model.dart';
import '../../../../../data/services/api_service.dart';
import '../ajuan_pengajaran_dialogs.dart';

class ConflictCheckBottomSheet {
  /// Menampilkan Dialog Hasil Cek Bentrok Gedung & Ruang (Keluar dari Bawah / Bottom Sheet Modern)
  static void show({
    required BuildContext context,
    required AjuanPengajaranModel ajuan,
  }) {
    final api = context.read<ApiService>();
    final result = api.checkBuildingConflict(ajuan);
    final hasConflict = result['hasConflict'] == true;
    final conflictTypeLabel = result['conflictTypeLabel'] as String? ??
        (hasConflict ? 'Bentrok Jadwal Terdeteksi' : 'Bebas Bentrok');
    final message = result['message'] as String;
    final dynamic conflictingWith = result['conflictingWith'];

    // Ekstraksi data bentrok jika ada
    String conflictMk = '-';
    String conflictDosen = '-';
    String conflictUnit = '-';
    String conflictWaktu = '-';
    String conflictRuang = '${ajuan.gedungNama}, ${ajuan.ruanganNama}';

    if (conflictingWith is AjuanPengajaranModel) {
      conflictMk = '${conflictingWith.mataKuliahNama} (${conflictingWith.sks} SKS)';
      conflictDosen = conflictingWith.dosenNama;
      conflictUnit = '${conflictingWith.fakultasNama} - ${conflictingWith.jurusanNama} (Kelas ${conflictingWith.kelasNama})';
      conflictWaktu = '${conflictingWith.hari}, ${conflictingWith.waktuFormatted}';
      conflictRuang = '${conflictingWith.gedungNama}, ${conflictingWith.ruanganNama}';
    } else if (conflictingWith is JadwalModel) {
      conflictMk = '${conflictingWith.mataKuliahNama} (${conflictingWith.sks} SKS)';
      conflictDosen = conflictingWith.dosenNama ?? 'Dosen Terjadwal';
      conflictUnit = '${conflictingWith.fakultasNama ?? ""} ${conflictingWith.jurusanNama ?? ""} (Kelas ${conflictingWith.kelasNama})'.trim();
      conflictWaktu = '${conflictingWith.hari}, ${conflictingWith.jamMulai} - ${conflictingWith.jamSelesai}';
      conflictRuang = '${conflictingWith.gedungNama}, ${conflictingWith.ruanganNama}';
    }

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) {
        return DraggableScrollableSheet(
          initialChildSize: 0.75,
          minChildSize: 0.45,
          maxChildSize: 0.95,
          expand: false,
          builder: (_, scrollController) {
            return Container(
              padding: const EdgeInsets.fromLTRB(20, 12, 20, 20),
              child: ListView(
                controller: scrollController,
                children: [
                  // Drag handle
                  Center(
                    child: Container(
                      width: 40,
                      height: 4,
                      decoration: BoxDecoration(
                        color: Colors.grey.shade300,
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                  ),
                  const SizedBox(height: 14),

                  // Header
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: (hasConflict ? const Color(0xFFEF4444) : AppColors.primary).withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Icon(
                          hasConflict ? Icons.error_outline_rounded : Icons.verified_user_outlined,
                          color: hasConflict ? const Color(0xFFDC2626) : AppColors.primary,
                          size: 24,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'Cek Batasan & Bentrok Jadwal',
                              style: TextStyle(
                                color: Color(0xFF0F172A),
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              '${ajuan.mataKuliahNama} • ${ajuan.gedungNama}',
                              style: const TextStyle(fontSize: 11.5, color: Color(0xFF64748B)),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 14),

                  // Status Alert Banner
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                    decoration: BoxDecoration(
                      color: hasConflict ? const Color(0xFFFEF2F2) : const Color(0xFFF0FDF4),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: hasConflict ? const Color(0xFFFECACA) : const Color(0xFFBBF7D0),
                      ),
                    ),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Icon(
                          hasConflict ? Icons.error_outline_rounded : Icons.check_circle_outline_rounded,
                          size: 20,
                          color: hasConflict ? const Color(0xFFDC2626) : const Color(0xFF16A34A),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                hasConflict ? conflictTypeLabel : 'Jadwal Bebas Bentrok',
                                style: TextStyle(
                                  fontSize: 13,
                                  fontWeight: FontWeight.bold,
                                  color: hasConflict ? const Color(0xFF991B1B) : const Color(0xFF15803D),
                                ),
                              ),
                              const SizedBox(height: 3),
                              Text(
                                message,
                                style: TextStyle(
                                  fontSize: 12,
                                  height: 1.4,
                                  color: hasConflict ? const Color(0xFF7F1D1D) : const Color(0xFF166534),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),

                  if (hasConflict) ...[
                    // Box 1: Jadwal Ajuan Saat Ini
                    const Text(
                      'Ajuan Saat Ini',
                      style: TextStyle(fontSize: 12.5, fontWeight: FontWeight.bold, color: Color(0xFF475569)),
                    ),
                    const SizedBox(height: 6),
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: const Color(0xFFF8FAFC),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: const Color(0xFFE2E8F0)),
                      ),
                      child: Column(
                        children: [
                          _buildSimpleRow('Mata Kuliah', '${ajuan.mataKuliahNama} (${ajuan.sks} SKS)'),
                          const Divider(height: 10, color: Color(0xFFE2E8F0)),
                          _buildSimpleRow('Pengampu', ajuan.dosenNama),
                          const Divider(height: 10, color: Color(0xFFE2E8F0)),
                          _buildSimpleRow('Waktu & Lokasi', '${ajuan.hari}, ${ajuan.waktuFormatted} (${ajuan.gedungNama} - ${ajuan.ruanganNama})'),
                        ],
                      ),
                    ),
                    const SizedBox(height: 14),

                    // Box 2: Jadwal yang Bertabrakan
                    const Text(
                      'Jadwal yang Bertabrakan',
                      style: TextStyle(fontSize: 12.5, fontWeight: FontWeight.bold, color: Color(0xFFDC2626)),
                    ),
                    const SizedBox(height: 6),
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: const Color(0xFFFFF1F2),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: const Color(0xFFFFE4E6)),
                      ),
                      child: Column(
                        children: [
                          _buildSimpleRow('Mata Kuliah', conflictMk),
                          const Divider(height: 10, color: Color(0xFFFFE4E6)),
                          _buildSimpleRow('Pengampu', conflictDosen),
                          if (conflictUnit.trim().isNotEmpty) ...[
                            const Divider(height: 10, color: Color(0xFFFFE4E6)),
                            _buildSimpleRow('Fakultas', conflictUnit),
                          ],
                          const Divider(height: 10, color: Color(0xFFFFE4E6)),
                          _buildSimpleRow('Waktu & Lokasi', '$conflictWaktu ($conflictRuang)'),
                        ],
                      ),
                    ),
                  ] else ...[
                    // Ringkasan Alokasi Bersih
                    const Text(
                      'Rincian Jadwal',
                      style: TextStyle(fontSize: 12.5, fontWeight: FontWeight.bold, color: Color(0xFF475569)),
                    ),
                    const SizedBox(height: 6),
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: const Color(0xFFF8FAFC),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: const Color(0xFFE2E8F0)),
                      ),
                      child: Column(
                        children: [
                          _buildSimpleRow('Mata Kuliah', '${ajuan.mataKuliahNama} (${ajuan.sks} SKS)'),
                          const Divider(height: 10, color: Color(0xFFE2E8F0)),
                          _buildSimpleRow('Pengampu', ajuan.dosenNama),
                          const Divider(height: 10, color: Color(0xFFE2E8F0)),
                          _buildSimpleRow('Fakultas', ajuan.fakultasNama),
                          const Divider(height: 10, color: Color(0xFFE2E8F0)),
                          _buildSimpleRow('Waktu', '${ajuan.hari}, ${ajuan.waktuFormatted}'),
                          const Divider(height: 10, color: Color(0xFFE2E8F0)),
                          _buildSimpleRow('Ruangan', '${ajuan.gedungNama} — ${ajuan.ruanganNama}'),
                          const Divider(height: 10, color: Color(0xFFE2E8F0)),
                          _buildSimpleRow('Rombel', 'Kelas ${ajuan.kelasNama} (${ajuan.jumlahMahasiswa} Mhs, Smt ${ajuan.semester})'),
                        ],
                      ),
                    ),
                  ],
                  const SizedBox(height: 20),

                  // Actions
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton(
                          style: OutlinedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(vertical: 12),
                            side: const BorderSide(color: Color(0xFFCBD5E1)),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                          ),
                          onPressed: () => Navigator.pop(ctx),
                          child: const Text('Tutup', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: Color(0xFF64748B))),
                        ),
                      ),
                      if (hasConflict) ...[
                        const SizedBox(width: 10),
                        Expanded(
                          child: ElevatedButton(
                            style: ElevatedButton.styleFrom(
                              backgroundColor: AppColors.primary,
                              foregroundColor: Colors.white,
                              padding: const EdgeInsets.symmetric(vertical: 12),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                              elevation: 0,
                            ),
                            onPressed: () {
                              Navigator.pop(ctx);
                              AjuanPengajaranDialogs.showEditDialog(
                                context: context,
                                ajuan: ajuan,
                                currentRole: 'admin',
                                onSaved: (updated) async {
                                  await api.updateAjuanPengajaran(updated);
                                },
                              );
                            },
                            child: const Text('Edit Jadwal', style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold)),
                          ),
                        ),
                      ],
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

  static Widget _buildSimpleRow(String label, String value) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          width: 90,
          child: Text(
            label,
            style: const TextStyle(fontSize: 11.5, color: Color(0xFF64748B), fontWeight: FontWeight.w500),
          ),
        ),
        Expanded(
          child: Text(
            value,
            style: const TextStyle(fontSize: 11.5, fontWeight: FontWeight.w600, color: Color(0xFF0F172A)),
          ),
        ),
      ],
    );
  }
}
