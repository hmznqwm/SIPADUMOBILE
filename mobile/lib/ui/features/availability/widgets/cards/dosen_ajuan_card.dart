// File: dosen_ajuan_card.dart
// Deskripsi: Widget kartu pengajuan mengajar khusus role Dosen.
// Fungsi: Menampilkan rincian ajuan, tombol aksi Detail, Cek Bentrok, Banding, Edit, dan Hapus.

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../../../config/constants.dart';
import '../../../../../data/models/ajuan_pengajaran_model.dart';
import '../../../../../data/models/user_model.dart';
import '../../../../../data/services/api_service.dart';
import '../ajuan_pengajaran_dialogs.dart';
import '../availability_common_widgets.dart';

class DosenAjuanCard extends StatelessWidget {
  final AjuanPengajaranModel ajuan;
  final UserModel? user;
  final bool isSelected;
  final bool isSelectionMode;
  final Future<void> Function() onRefresh;
  final Function(String id, VoidCallback defaultAction) onAjuanTap;
  final Function(String id) onAjuanLongPress;

  const DosenAjuanCard({
    super.key,
    required this.ajuan,
    required this.user,
    required this.isSelected,
    required this.isSelectionMode,
    required this.onRefresh,
    required this.onAjuanTap,
    required this.onAjuanLongPress,
  });

  @override
  Widget build(BuildContext context) {
    final api = context.read<ApiService>();

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: isSelected ? const Color(0xFFEFF6FF) : Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: isSelected ? AppColors.primary : const Color(0xFFE2E8F0),
          width: isSelected ? 1.8 : 1.0,
        ),
        boxShadow: const [
          BoxShadow(
            color: Color(0x04000000),
            blurRadius: 6,
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () => onAjuanTap(
            ajuan.id,
            () => AjuanPengajaranDialogs.showDetailDialog(
              context: context,
              ajuan: ajuan,
              currentRole: user?.role ?? 'dosen',
              onRefresh: onRefresh,
            ),
          ),
          onLongPress: () => onAjuanLongPress(ajuan.id),
          borderRadius: BorderRadius.circular(14),
          child: Padding(
            padding: const EdgeInsets.all(14),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Header: Mata Kuliah & SKS Badge
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (isSelectionMode)
                      Padding(
                        padding: const EdgeInsets.only(right: 8, top: 2),
                        child: Icon(
                          isSelected
                              ? Icons.check_circle_rounded
                              : Icons.radio_button_unchecked_rounded,
                          color: isSelected
                              ? AppColors.primary
                              : const Color(0xFF94A3B8),
                          size: 20,
                        ),
                      ),
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: AppColors.primary.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: const Icon(
                        Icons.school_rounded,
                        color: AppColors.primary,
                        size: 20,
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            ajuan.mataKuliahNama,
                            style: const TextStyle(
                              fontSize: 14.5,
                              fontWeight: FontWeight.bold,
                              color: Color(0xFF0F172A),
                            ),
                          ),
                          const SizedBox(height: 3),
                          Text(
                            ajuan.fakultasNama,
                            style: const TextStyle(
                              fontSize: 11.5,
                              color: Color(0xFF64748B),
                            ),
                          ),
                        ],
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 3,
                      ),
                      decoration: BoxDecoration(
                        color: AppColors.primary.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        '${ajuan.sks} SKS',
                        style: const TextStyle(
                          fontSize: 11.5,
                          fontWeight: FontWeight.bold,
                          color: AppColors.primary,
                        ),
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 10),
                const Divider(height: 1, color: Color(0xFFF1F5F9)),
                const SizedBox(height: 10),

                // Info Grid: Semester, Kelas, Siswa, Hari & Jam, Gedung, Ruang
                Wrap(
                  spacing: 8,
                  runSpacing: 6,
                  children: [
                    InfoChip(
                      icon: Icons.stairs_rounded,
                      label: 'Semester ${ajuan.semester}',
                    ),
                    InfoChip(
                      icon: Icons.groups_rounded,
                      label:
                          'Kelas ${ajuan.kelasNama} (${ajuan.jumlahMahasiswa} Mhs)',
                    ),
                    InfoChip(
                      icon: Icons.calendar_today_rounded,
                      label:
                          '${ajuan.hari}, ${ajuan.jamMulai} - ${ajuan.jamSelesai}',
                    ),
                    InfoChip(
                      icon: Icons.domain_rounded,
                      label: ajuan.gedungNama,
                    ),
                    InfoChip(
                      icon: Icons.meeting_room_rounded,
                      label: 'Ruang: ${ajuan.ruanganNama}',
                    ),
                  ],
                ),

                // Rejection or Adjustment Notice
                if (ajuan.alasanPenolakan != null &&
                    ajuan.alasanPenolakan!.isNotEmpty) ...[
                  const SizedBox(height: 10),
                  Container(
                    padding: const EdgeInsets.all(9),
                    decoration: BoxDecoration(
                      color: Colors.red.withValues(alpha: 0.08),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(
                        color: Colors.red.withValues(alpha: 0.25),
                      ),
                    ),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Icon(
                          Icons.info_outline,
                          size: 15,
                          color: Colors.red,
                        ),
                        const SizedBox(width: 6),
                        Expanded(
                          child: Text(
                            'Catatan: ${ajuan.alasanPenolakan}',
                            style: const TextStyle(
                              fontSize: 11.5,
                              color: Colors.red,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],

                const SizedBox(height: 12),

                // Status Badge & Action Buttons
                Row(
                  children: [AjuanStatusBadge(status: ajuan.status)],
                ),
                const SizedBox(height: 10),

                // ── Dosen Action Buttons (Responsive Grid) ──
                Column(
                  children: [
                    Row(
                      children: [
                        // 1. Detail Alur
                        Expanded(
                          child: InkWell(
                            onTap: () {
                              AjuanPengajaranDialogs.showDetailDialog(
                                context: context,
                                ajuan: ajuan,
                                currentRole: user?.role ?? 'dosen',
                                onRefresh: onRefresh,
                              );
                            },
                            borderRadius: BorderRadius.circular(9),
                            child: Container(
                              height: 36,
                              decoration: BoxDecoration(
                                color: const Color(0xFFF1F5F9),
                                borderRadius: BorderRadius.circular(9),
                                border: Border.all(
                                  color: const Color(0xFFCBD5E1),
                                ),
                              ),
                              alignment: Alignment.center,
                              child: const Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(
                                    Icons.visibility_outlined,
                                    size: 14.5,
                                    color: Color(0xFF0284C7),
                                  ),
                                  SizedBox(width: 5),
                                  Text(
                                    'Lihat Detail',
                                    style: TextStyle(
                                      fontSize: 11.5,
                                      fontWeight: FontWeight.bold,
                                      color: Color(0xFF0284C7),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        // 2. Cek Bentrok
                        Expanded(
                          child: InkWell(
                            onTap: () {
                              AjuanPengajaranDialogs.showConflictCheckDialog(
                                context: context,
                                ajuan: ajuan,
                              );
                            },
                            borderRadius: BorderRadius.circular(9),
                            child: Container(
                              height: 36,
                              decoration: BoxDecoration(
                                color: const Color(0xFFF5F3FF),
                                borderRadius: BorderRadius.circular(9),
                                border: Border.all(
                                  color: const Color(0xFFDDD6FE),
                                ),
                              ),
                              alignment: Alignment.center,
                              child: const Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(
                                    Icons.event_busy_outlined,
                                    size: 14.5,
                                    color: Color(0xFF7C3AED),
                                  ),
                                  SizedBox(width: 5),
                                  Text(
                                    'Cek Bentrok',
                                    style: TextStyle(
                                      fontSize: 11.5,
                                      fontWeight: FontWeight.bold,
                                      color: Color(0xFF7C3AED),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                    if (ajuan.status == 'disetujui_admin' ||
                        ajuan.status == 'banding_disetujui') ...[
                      const SizedBox(height: 7),
                      InkWell(
                        onTap: () {
                          AjuanPengajaranDialogs.showBandingDialog(
                            context: context,
                            ajuan: ajuan,
                            onConfirmBanding: (alasan, hari, jam) async {
                              await api.submitBandingAjuan(
                                ajuanId: ajuan.id,
                                alasan: alasan,
                                preferensiHari: hari,
                                preferensiJam: jam,
                              );
                              onRefresh();
                              if (context.mounted) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(
                                    content: Text(
                                      'Permohonan banding jadwal berhasil dikirimkan ke Admin.',
                                    ),
                                    backgroundColor: AppColors.primary,
                                  ),
                                );
                              }
                            },
                          );
                        },
                        borderRadius: BorderRadius.circular(9),
                        child: Container(
                          height: 36,
                          decoration: BoxDecoration(
                            color: const Color(0xFFFFF7ED),
                            borderRadius: BorderRadius.circular(9),
                            border: Border.all(
                              color: const Color(0xFFFED7AA),
                            ),
                          ),
                          alignment: Alignment.center,
                          child: const Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(
                                Icons.history_toggle_off_rounded,
                                size: 14.5,
                                color: Color(0xFFEA580C),
                              ),
                              SizedBox(width: 5),
                              Text(
                                'Ajukan Banding Jadwal',
                                style: TextStyle(
                                  fontSize: 11.5,
                                  fontWeight: FontWeight.bold,
                                  color: Color(0xFFEA580C),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ] else if (ajuan.status == 'menunggu_banding') ...[
                      const SizedBox(height: 7),
                      Container(
                        height: 36,
                        decoration: BoxDecoration(
                          color: const Color(0xFFFFF7ED),
                          borderRadius: BorderRadius.circular(9),
                          border: Border.all(
                            color: const Color(0xFFFED7AA),
                          ),
                        ),
                        alignment: Alignment.center,
                        child: const Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.hourglass_top_rounded,
                              size: 14.5,
                              color: Color(0xFFEA580C),
                            ),
                            SizedBox(width: 5),
                            Text(
                              'Banding Sedang Ditinjau Admin',
                              style: TextStyle(
                                fontSize: 11.5,
                                fontWeight: FontWeight.bold,
                                color: Color(0xFFEA580C),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ] else ...[
                      const SizedBox(height: 7),
                      Row(
                        children: [
                          // 3. Edit Ajuan
                          Expanded(
                            child: InkWell(
                              onTap: () {
                                AjuanPengajaranDialogs.showEditDialog(
                                  context: context,
                                  ajuan: ajuan,
                                  currentRole: user?.role ?? 'dosen',
                                  onSaved: (updated) async {
                                    await api.updateAjuanPengajaran(updated);
                                    onRefresh();
                                  },
                                );
                              },
                              borderRadius: BorderRadius.circular(9),
                              child: Container(
                                height: 36,
                                decoration: BoxDecoration(
                                  color: const Color(0xFFEFF6FF),
                                  borderRadius: BorderRadius.circular(9),
                                  border: Border.all(
                                    color: const Color(0xFFBFDBFE),
                                  ),
                                ),
                                alignment: Alignment.center,
                                child: const Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Icon(
                                      Icons.edit_outlined,
                                      size: 14.5,
                                      color: AppColors.primary,
                                    ),
                                    SizedBox(width: 5),
                                    Text(
                                      'Edit',
                                      style: TextStyle(
                                        fontSize: 11.5,
                                        fontWeight: FontWeight.bold,
                                        color: AppColors.primary,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ),
                          if (ajuan.status == 'menunggu_kaprodi' ||
                              ajuan.status.startsWith('ditolak')) ...[
                            const SizedBox(width: 8),
                            // 4. Hapus Ajuan
                            Expanded(
                              child: InkWell(
                                onTap: () => _confirmDeleteAjuan(context, api),
                                borderRadius: BorderRadius.circular(9),
                                child: Container(
                                  height: 36,
                                  decoration: BoxDecoration(
                                    color: const Color(0xFFFEF2F2),
                                    borderRadius: BorderRadius.circular(9),
                                    border: Border.all(
                                      color: const Color(0xFFFECACA),
                                    ),
                                  ),
                                  alignment: Alignment.center,
                                  child: const Row(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      Icon(
                                        Icons.delete_outline_rounded,
                                        size: 14.5,
                                        color: Colors.red,
                                      ),
                                      SizedBox(width: 5),
                                      Text(
                                        'Hapus',
                                        style: TextStyle(
                                          fontSize: 11.5,
                                          fontWeight: FontWeight.bold,
                                          color: Colors.red,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ],
                      ),
                    ],
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _confirmDeleteAjuan(BuildContext context, ApiService api) async {
    final confirm = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => Padding(
        padding: EdgeInsets.only(
          left: 20,
          right: 20,
          top: 12,
          bottom: MediaQuery.of(context).viewInsets.bottom + 20,
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
                  color: Colors.grey.shade300,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: const Color(0xFFFEF2F2),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(
                    Icons.delete_outline_rounded,
                    color: Color(0xFFDC2626),
                    size: 24,
                  ),
                ),
                const SizedBox(width: 12),
                const Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Hapus Pengajuan?',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF0F172A),
                        ),
                      ),
                      SizedBox(height: 2),
                      Text(
                        'Tindakan ini tidak dapat dibatalkan',
                        style: TextStyle(
                          fontSize: 11.5,
                          color: Color(0xFF64748B),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Text(
              'Apakah Anda yakin ingin menghapus pengajuan mata kuliah "${ajuan.mataKuliahNama}"?',
              style: const TextStyle(
                fontSize: 13,
                color: Color(0xFF334155),
                height: 1.4,
              ),
            ),
            const SizedBox(height: 20),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      side: const BorderSide(color: Color(0xFFCBD5E1)),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                    onPressed: () => Navigator.pop(ctx, false),
                    child: const Text(
                      'Batal',
                      style: TextStyle(
                        color: Color(0xFF475569),
                        fontWeight: FontWeight.w600,
                        fontSize: 13,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFFDC2626),
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                      elevation: 0,
                    ),
                    onPressed: () => Navigator.pop(ctx, true),
                    child: const Text(
                      'Hapus',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 13,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
    if (confirm == true) {
      await api.deleteAjuanPengajaran(ajuan.id);
      onRefresh();
    }
  }
}
