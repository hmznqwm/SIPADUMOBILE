// File: admin_ajuan_card.dart
// Deskripsi: Widget kartu pengajuan mengajar dosen untuk role Admin (Final Scheduling Approval).

import 'package:flutter/material.dart';

import '../../../../../config/constants.dart';
import '../../../../../data/models/ajuan_pengajaran_model.dart';
import '../../../../../data/services/api_service.dart';
import '../ajuan_pengajaran_dialogs.dart';
import '../availability_common_widgets.dart';

class AdminAjuanCard extends StatelessWidget {
  final AjuanPengajaranModel aj;
  final ApiService api;
  final Set<String> selectedAjuanIds;
  final Function(String id, VoidCallback defaultAction) onAjuanTap;
  final Function(String id) onAjuanLongPress;
  final Future<void> Function() onRefresh;

  const AdminAjuanCard({
    super.key,
    required this.aj,
    required this.api,
    required this.selectedAjuanIds,
    required this.onAjuanTap,
    required this.onAjuanLongPress,
    required this.onRefresh,
  });

  @override
  Widget build(BuildContext context) {
    final conflictInfo = api.checkBuildingConflict(aj);
    final isConflict = aj.status == 'bentrok_terdeteksi' ||
        conflictInfo['hasConflict'] == true ||
        (aj.status != 'disetujui_admin' &&
            aj.status != 'banding_disetujui' &&
            aj.bentrokDetail != null &&
            aj.bentrokDetail!.isNotEmpty);

    Color statusColor;
    Color statusBg;
    String statusLabel;

    if (isConflict) {
      statusColor = const Color(0xFFDC2626);
      statusBg = const Color(0xFFFEF2F2);
      statusLabel = 'Bentrok Terdeteksi';
    } else if (aj.status == 'disetujui_admin' ||
        aj.status == 'banding_disetujui') {
      statusColor = AppColors.primary;
      statusBg = const Color(0xFFECFDF5);
      statusLabel = aj.status == 'banding_disetujui'
          ? 'Banding Diterima'
          : 'Disetujui Admin';
    } else if (aj.status == 'menunggu_banding') {
      statusColor = const Color(0xFFEA580C);
      statusBg = const Color(0xFFFFF7ED);
      statusLabel = 'Banding Dosen';
    } else if (aj.status == 'menunggu_admin') {
      statusColor = const Color(0xFF7C3AED);
      statusBg = const Color(0xFFF5F3FF);
      statusLabel = 'Menuju Admin';
    } else if (aj.status == 'menunggu_dekan') {
      statusColor = const Color(0xFFD97706);
      statusBg = const Color(0xFFFFFBEB);
      statusLabel = 'Menuju Dekan';
    } else if (aj.status.startsWith('ditolak') ||
        aj.status == 'banding_ditolak') {
      statusColor = AppColors.error;
      statusBg = const Color(0xFFFEF2F2);
      if (aj.status == 'ditolak_kaprodi') {
        statusLabel = 'Ditolak KaProdi';
      } else if (aj.status == 'ditolak_dekan') {
        statusLabel = 'Ditolak Dekan';
      } else if (aj.status == 'ditolak_admin') {
        statusLabel = 'Ditolak Admin';
      } else if (aj.status == 'banding_ditolak') {
        statusLabel = 'Banding Ditolak';
      } else {
        statusLabel = 'Ditolak';
      }
    } else {
      statusColor = const Color(0xFF2563EB);
      statusBg = const Color(0xFFEFF6FF);
      statusLabel = 'Menunggu KaProdi';
    }

    final isSelected = selectedAjuanIds.contains(aj.id);

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      decoration: BoxDecoration(
        color: isSelected ? const Color(0xFFEFF6FF) : Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isSelected ? AppColors.primary : const Color(0xFFE2E8F0),
          width: isSelected ? 1.8 : 1.0,
        ),
        boxShadow: const [
          BoxShadow(
            color: Color(0x05000000),
            blurRadius: 6,
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: InkWell(
        onTap: () => onAjuanTap(
          aj.id,
          () => AjuanPengajaranDialogs.showDetailDialog(
            context: context,
            ajuan: aj,
            currentRole: 'admin',
            onRefresh: onRefresh,
          ),
        ),
        onLongPress: () => onAjuanLongPress(aj.id),
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // ── Header: Jurusan/Prodi Badge & Status Pill ──
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        if (selectedAjuanIds.isNotEmpty)
                          Padding(
                            padding: const EdgeInsets.only(right: 6),
                            child: Icon(
                              isSelected
                                  ? Icons.check_circle_rounded
                                  : Icons.radio_button_unchecked_rounded,
                              color: isSelected
                                  ? AppColors.primary
                                  : const Color(0xFF94A3B8),
                              size: 18,
                            ),
                          ),
                        Flexible(
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 3,
                            ),
                            decoration: BoxDecoration(
                              color: const Color(0xFFF1F5F9),
                              borderRadius: BorderRadius.circular(6),
                              border: Border.all(
                                color: const Color(0xFFE2E8F0),
                              ),
                            ),
                            child: Text(
                              aj.jurusanNama.isNotEmpty
                                  ? aj.jurusanNama
                                  : aj.fakultasNama,
                              style: const TextStyle(
                                fontSize: 10.5,
                                fontWeight: FontWeight.w600,
                                color: Color(0xFF475569),
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 6),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 3,
                    ),
                    decoration: BoxDecoration(
                      color: statusBg,
                      borderRadius: BorderRadius.circular(6),
                      border: Border.all(
                        color: statusColor.withValues(
                          alpha: 0.3,
                        ),
                      ),
                    ),
                    child: Text(
                      statusLabel,
                      style: TextStyle(
                        fontSize: 10.5,
                        fontWeight: FontWeight.bold,
                        color: statusColor,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 10),

              // ── Lecturer & Course Details ──
              Text(
                aj.dosenNama,
                style: const TextStyle(
                  fontSize: 14.5,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF0F172A),
                  height: 1.2,
                ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 4),
              Row(
                children: [
                  Expanded(
                    child: Text(
                      aj.mataKuliahNama,
                      style: const TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: Color(0xFF334155),
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  const SizedBox(width: 6),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 6,
                      vertical: 2,
                    ),
                    decoration: BoxDecoration(
                      color: const Color(0xFFEFF6FF),
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Text(
                      '${aj.sks} SKS',
                      style: const TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF2563EB),
                      ),
                    ),
                  ),
                  const SizedBox(width: 4),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 6,
                      vertical: 2,
                    ),
                    decoration: BoxDecoration(
                      color: const Color(0xFFF1F5F9),
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Text(
                      'Sem ${aj.semester}',
                      style: const TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF475569),
                      ),
                    ),
                  ),
                ],
              ),
              AjuanCardDetailGrid(
                hari: aj.hari,
                waktuFormatted: aj.waktuFormatted,
                kelasNama: aj.kelasNama,
                jumlahMahasiswa: aj.jumlahMahasiswa,
                semester: aj.semester,
                ruanganNama: aj.ruanganNama,
                gedungNama: aj.gedungNama,
              ),
              const SizedBox(height: 4),
              const Divider(height: 1, color: Color(0xFFF1F5F9)),
              const SizedBox(height: 8),

              // ── Action Buttons for Admin ──
              Column(
                children: [
                  // Row 1: Detail & Edit
                  Row(
                    children: [
                      Expanded(
                        child: InkWell(
                          onTap: () =>
                              AjuanPengajaranDialogs.showDetailDialog(
                            context: context,
                            ajuan: aj,
                            currentRole: 'admin',
                            onRefresh: onRefresh,
                          ),
                          borderRadius: BorderRadius.circular(8),
                          child: Container(
                            height: 34,
                            decoration: BoxDecoration(
                              color: const Color(0xFFF1F5F9),
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(
                                color: const Color(0xFFCBD5E1),
                              ),
                            ),
                            alignment: Alignment.center,
                            child: const Text(
                              'Detail',
                              style: TextStyle(
                                fontSize: 11.5,
                                fontWeight: FontWeight.bold,
                                color: Color(0xFF334155),
                              ),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: InkWell(
                          onTap: () {
                            AjuanPengajaranDialogs.showEditDialog(
                              context: context,
                              ajuan: aj,
                              currentRole: 'admin',
                              onSaved: (updated) async {
                                await api.updateAjuanPengajaran(
                                  updated,
                                );
                                onRefresh();
                                if (context.mounted) {
                                  ScaffoldMessenger.of(
                                    context,
                                  ).showSnackBar(
                                    const SnackBar(
                                      content: Text(
                                        'Data ajuan berhasil disesuaikan oleh Admin!',
                                      ),
                                      backgroundColor: AppColors.primary,
                                    ),
                                  );
                                }
                              },
                            );
                          },
                          borderRadius: BorderRadius.circular(8),
                          child: Container(
                            height: 34,
                            decoration: BoxDecoration(
                              color: const Color(0xFFEFF6FF),
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(
                                color: const Color(0xFFBFDBFE),
                              ),
                            ),
                            alignment: Alignment.center,
                            child: const Text(
                              'Edit',
                              style: TextStyle(
                                fontSize: 11.5,
                                fontWeight: FontWeight.bold,
                                color: Color(0xFF2563EB),
                              ),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  // Row 2: Cek Bentrok & Setujui Final
                  Row(
                    children: [
                      Expanded(
                        child: InkWell(
                          onTap: () =>
                              AjuanPengajaranDialogs.showConflictCheckDialog(
                            context: context,
                            ajuan: aj,
                          ),
                          borderRadius: BorderRadius.circular(8),
                          child: Container(
                            height: 34,
                            decoration: BoxDecoration(
                              color: const Color(0xFFF5F3FF),
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(
                                color: const Color(0xFFDDD6FE),
                              ),
                            ),
                            alignment: Alignment.center,
                            child: const Text(
                              'Cek Bentrok',
                              style: TextStyle(
                                fontSize: 11.5,
                                fontWeight: FontWeight.bold,
                                color: Color(0xFF7C3AED),
                              ),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: InkWell(
                          onTap: aj.status == 'disetujui_admin'
                              ? null
                              : () async {
                                  if (aj.status == 'bentrok_terdeteksi') {
                                    showConflictWarningDialog(
                                      context,
                                      aj,
                                      aj.bentrokDetail ??
                                          'Terdeteksi konflik jadwal.',
                                    );
                                    return;
                                  }
                                  final conflict =
                                      api.checkBuildingConflict(
                                    aj,
                                  );
                                  if (conflict['hasConflict'] == true) {
                                    showConflictWarningDialog(
                                      context,
                                      aj,
                                      conflict['message'] ??
                                          'Terdeteksi bentrok ruangan/gedung.',
                                    );
                                    return;
                                  }

                                  await api.adminApproveFinalAjuan(
                                    aj.id,
                                  );
                                  onRefresh();
                                  if (context.mounted) {
                                    ScaffoldMessenger.of(
                                      context,
                                    ).showSnackBar(
                                      const SnackBar(
                                        content: Text(
                                          'Jadwal RESMI DISETUJUI & diterbitkan!',
                                        ),
                                        backgroundColor: AppColors.primary,
                                      ),
                                    );
                                  }
                                },
                          borderRadius: BorderRadius.circular(8),
                          child: Container(
                            height: 34,
                            decoration: BoxDecoration(
                              color: aj.status == 'disetujui_admin'
                                  ? const Color(0xFFE2E8F0)
                                  : AppColors.primary,
                              borderRadius: BorderRadius.circular(8),
                            ),
                            alignment: Alignment.center,
                            child: Text(
                              aj.status == 'disetujui_admin'
                                  ? 'Terjadwal Resmi'
                                  : 'Setujui',
                              style: TextStyle(
                                fontSize: 11.5,
                                fontWeight: FontWeight.bold,
                                color: aj.status == 'disetujui_admin'
                                    ? const Color(0xFF64748B)
                                    : Colors.white,
                              ),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
