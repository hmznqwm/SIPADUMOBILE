// File: kajur_ajuan_card.dart
// Deskripsi: Widget kartu pengajuan mengajar dosen untuk role KaProdi (Level 1 Approval).

import 'package:flutter/material.dart';

import '../../../../../config/constants.dart';
import '../../../../../data/models/ajuan_pengajaran_model.dart';
import '../../../../../data/services/api_service.dart';
import '../ajuan_pengajaran_dialogs.dart';
import '../availability_common_widgets.dart';

class KajurAjuanCard extends StatelessWidget {
  final AjuanPengajaranModel aj;
  final ApiService api;
  final Set<String> selectedAjuanIds;
  final Function(String id, VoidCallback defaultAction) onAjuanTap;
  final Function(String id) onAjuanLongPress;
  final Future<void> Function() onRefresh;

  const KajurAjuanCard({
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
    final isConflict =
        aj.status == 'bentrok_terdeteksi' ||
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
    } else if (aj.status == 'disetujui_admin') {
      statusColor = const Color(0xFF059669);
      statusBg = const Color(0xFFECFDF5);
      statusLabel = 'Final Admin';
    } else if (aj.status == 'menunggu_admin') {
      statusColor = const Color(0xFF0F766E);
      statusBg = const Color(0xFFF0FDFA);
      statusLabel = 'Disetujui Dekan';
    } else if (aj.status == 'menunggu_dekan') {
      statusColor = const Color(0xFF2563EB);
      statusBg = const Color(0xFFEFF6FF);
      statusLabel = 'Disetujui KaProdi';
    } else if (aj.status == 'menunggu_kaprodi' ||
        aj.status == 'menunggu_verifikasi') {
      statusColor = const Color(0xFFD97706);
      statusBg = const Color(0xFFFFFBEB);
      statusLabel = 'Menunggu KaProdi';
    } else if (aj.status.startsWith('ditolak')) {
      statusColor = const Color(0xFFDC2626);
      statusBg = const Color(0xFFFEF2F2);
      if (aj.status == 'ditolak_kaprodi') {
        statusLabel = 'Ditolak KaProdi';
      } else if (aj.status == 'ditolak_dekan') {
        statusLabel = 'Ditolak Dekan';
      } else {
        statusLabel = 'Ditolak';
      }
    } else {
      statusColor = const Color(0xFF475569);
      statusBg = const Color(0xFFF1F5F9);
      statusLabel = 'Menunggu KaProdi';
    }

    final isPendingKaProdi =
        aj.status == 'menunggu_kaprodi' || aj.status == 'menunggu_verifikasi';
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
            currentRole: 'kajur',
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
              // Header: Jurusan/Prodi Badge & Status Pill
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
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
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 3,
                        ),
                        decoration: BoxDecoration(
                          color: const Color(0xFFF1F5F9),
                          borderRadius: BorderRadius.circular(6),
                          border: Border.all(color: const Color(0xFFE2E8F0)),
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
                        ),
                      ),
                    ],
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 3,
                    ),
                    decoration: BoxDecoration(
                      color: statusBg,
                      borderRadius: BorderRadius.circular(6),
                      border: Border.all(
                        color: statusColor.withValues(alpha: 0.3),
                      ),
                    ),
                    child: Text(
                      statusLabel,
                      style: TextStyle(
                        fontSize: 10.5,
                        fontWeight: FontWeight.bold,
                        color: statusColor,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 10),

              // Lecturer & Course Details
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
                ],
              ),
              const SizedBox(height: 6),
              Text(
                '${aj.hari}, ${aj.waktuFormatted} • Kelas ${aj.kelasNama} (${aj.jumlahMahasiswa} Mhs) • Sem ${aj.semester}',
                style: const TextStyle(
                  fontSize: 11.5,
                  color: Color(0xFF64748B),
                ),
              ),
              const SizedBox(height: 3),
              Text(
                'Ruang: ${aj.ruanganNama} • ${aj.gedungNama}',
                style: const TextStyle(
                  fontSize: 11.5,
                  fontWeight: FontWeight.w600,
                  color: Color(0xFF2563EB),
                ),
              ),
              const SizedBox(height: 10),
              const Divider(height: 1, color: Color(0xFFF1F5F9)),
              const SizedBox(height: 8),

              // Action Buttons for KaProdi
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      style: OutlinedButton.styleFrom(
                        foregroundColor: const Color(0xFF334155),
                        side: const BorderSide(color: Color(0xFFCBD5E1)),
                        padding: const EdgeInsets.symmetric(vertical: 9),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                      onPressed: () {
                        AjuanPengajaranDialogs.showDetailDialog(
                          context: context,
                          ajuan: aj,
                          currentRole: 'kajur',
                          onRefresh: onRefresh,
                        );
                      },
                      child: const Text(
                        'Detail',
                        style: TextStyle(
                          fontSize: 11.5,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 6),
                  Expanded(
                    child: OutlinedButton(
                      style: OutlinedButton.styleFrom(
                        foregroundColor: const Color(0xFF2563EB),
                        side: const BorderSide(color: Color(0xFF93C5FD)),
                        backgroundColor: const Color(0xFFEFF6FF),
                        padding: const EdgeInsets.symmetric(vertical: 9),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                      onPressed: () {
                        AjuanPengajaranDialogs.showEditDialog(
                          context: context,
                          ajuan: aj,
                          currentRole: 'kajur',
                          onSaved: (updated) async {
                            await api.kaprodiVerifyAjuan(
                              aj.id,
                              updatedData: updated,
                            );
                            await onRefresh();
                          },
                        );
                      },
                      child: const Text(
                        'Edit',
                        style: TextStyle(
                          fontSize: 11.5,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 6),
                  Expanded(
                    child: OutlinedButton(
                      style: OutlinedButton.styleFrom(
                        foregroundColor: const Color(0xFFD97706),
                        side: const BorderSide(color: Color(0xFFFDE68A)),
                        backgroundColor: const Color(0xFFFFFBEB),
                        padding: const EdgeInsets.symmetric(vertical: 9),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                      onPressed: () {
                        AjuanPengajaranDialogs.showConflictCheckDialog(
                          context: context,
                          ajuan: aj,
                        );
                      },
                      child: const Text(
                        'Bentrok',
                        style: TextStyle(
                          fontSize: 11.5,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
                ],
              ),

              if (isPendingKaProdi) ...[
                const SizedBox(height: 6),
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton(
                        style: OutlinedButton.styleFrom(
                          foregroundColor: const Color(0xFFDC2626),
                          side: const BorderSide(color: Color(0xFFFECACA)),
                          backgroundColor: const Color(0xFFFEF2F2),
                          padding: const EdgeInsets.symmetric(vertical: 9),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                        ),
                        onPressed: () {
                          AjuanPengajaranDialogs.showRejectDialog(
                            context: context,
                            ajuan: aj,
                            role: 'kajur',
                            onConfirmReject: (alasan) async {
                              await api.kaprodiRejectAjuan(aj.id, alasan);
                              if (context.mounted) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(
                                    content: Text(
                                      'Ajuan dikembalikan ke Dosen.',
                                    ),
                                    backgroundColor: Color(0xFFDC2626),
                                  ),
                                );
                              }
                              await onRefresh();
                            },
                          );
                        },
                        child: const Text(
                          'Kembalikan',
                          style: TextStyle(
                            fontSize: 11.5,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 6),
                    Expanded(
                      child: ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.primary,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 9),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                          elevation: 0,
                        ),
                        onPressed: () async {
                          if (aj.status == 'bentrok_terdeteksi') {
                            showConflictWarningDialog(
                              context,
                              aj,
                              aj.bentrokDetail ?? 'Terdeteksi konflik jadwal.',
                            );
                            return;
                          }
                          final conflict = api.checkBuildingConflict(aj);
                          if (conflict['hasConflict'] == true) {
                            showConflictWarningDialog(
                              context,
                              aj,
                              conflict['message'] ??
                                  'Terdeteksi bentrok ruangan/gedung.',
                            );
                            return;
                          }
                          await api.kaprodiVerifyAjuan(aj.id);
                          if (context.mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text(
                                  'Ajuan disetujui & diteruskan ke Dekan!',
                                ),
                                backgroundColor: AppColors.primary,
                              ),
                            );
                          }
                          await onRefresh();
                        },
                        child: const Text(
                          'Setujui',
                          style: TextStyle(
                            fontSize: 11.5,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
