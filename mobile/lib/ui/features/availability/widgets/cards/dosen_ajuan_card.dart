// File: dosen_ajuan_card.dart
// Deskripsi: Widget kartu pengajuan mengajar dosen untuk role Dosen.

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
    final currentAj = ajuan;
    final stageColor = getAjuanStageColor(currentAj.status);

    final cleanKelas = currentAj.kelasNama.trim().toLowerCase().startsWith('kelas')
        ? currentAj.kelasNama.trim()
        : (currentAj.kelasNama.trim().isNotEmpty ? 'Kelas ${currentAj.kelasNama.trim()}' : '-');

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isSelected ? stageColor : const Color(0xFFE2E8F0),
          width: isSelected ? 2.0 : 1.0,
        ),
        boxShadow: const [
          BoxShadow(
            color: Color(0x0A0F172A),
            blurRadius: 10,
            offset: Offset(0, 4),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(15.0),
        child: InkWell(
          onTap: () {
            if (isSelectionMode) {
              onAjuanTap(currentAj.id, () {});
            } else {
              onAjuanTap(
                currentAj.id,
                () => AjuanPengajaranDialogs.showDetailDialog(
                  context: context,
                  ajuan: currentAj,
                  currentRole: 'dosen',
                  onRefresh: onRefresh,
                ),
              );
            }
          },
          onLongPress: () => onAjuanLongPress(currentAj.id),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            mainAxisSize: MainAxisSize.min,
            children: [
              // ── 1. HEADER (White Background) ──
              Container(
                padding: const EdgeInsets.fromLTRB(20, 20, 20, 16),
                decoration: const BoxDecoration(
                  border: Border(bottom: BorderSide(color: Color(0xFFF1F5F9))),
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    Stack(
                      alignment: Alignment.center,
                      children: [
                        buildDosenAvatar(
                          dosenId: currentAj.dosenId,
                          dosenNama: currentAj.dosenNama,
                          radius: 26,
                        ),
                        if (isSelected)
                          Container(
                            width: 52,
                            height: 52,
                            decoration: BoxDecoration(
                              color: stageColor.withValues(alpha: 0.8),
                              shape: BoxShape.circle,
                              border: Border.all(color: Colors.white, width: 2),
                            ),
                            child: const Icon(
                              Icons.check_rounded,
                              color: Colors.white,
                              size: 28,
                            ),
                          ),
                      ],
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            currentAj.dosenNama,
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                              color: Color(0xFF0F172A),
                              letterSpacing: -0.3,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          const SizedBox(height: 4),
                          Wrap(
                            crossAxisAlignment: WrapCrossAlignment.center,
                            spacing: 6,
                            runSpacing: 4,
                            children: [
                              Text(
                                currentAj.dosenId.isNotEmpty ? currentAj.dosenId : '0412087601',
                                style: const TextStyle(
                                  fontSize: 12,
                                  color: Color(0xFF64748B),
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                              const Text(
                                '•',
                                style: TextStyle(color: Color(0xFFCBD5E1), fontSize: 12),
                              ),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                                decoration: BoxDecoration(
                                  color: const Color(0xFFE0F2F1),
                                  borderRadius: BorderRadius.circular(100),
                                  border: Border.all(color: const Color(0xFFB2DFDB)),
                                ),
                                child: Text(
                                  currentAj.jurusanNama.isNotEmpty ? currentAj.jurusanNama : 'Jurusan',
                                  style: const TextStyle(
                                    fontSize: 10.5,
                                    fontWeight: FontWeight.w600,
                                    color: Color(0xFF00695C),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),

              // ── 2. BODY KARTU (Jadwal Diajukan - Light Gray) ──
              Container(
                color: const Color(0xFFF8FAFC),
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'JADWAL DIAJUKAN',
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                        color: Color(0xFF94A3B8),
                        letterSpacing: 0.5,
                      ),
                    ),
                    const SizedBox(height: 12),
                    
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: const Color(0xFFE2E8F0)),
                        boxShadow: const [
                          BoxShadow(
                            color: Color(0x050F172A),
                            blurRadius: 4,
                            offset: Offset(0, 1),
                          ),
                        ],
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          // Top Sub-header
                          Container(
                            padding: const EdgeInsets.only(bottom: 12),
                            decoration: const BoxDecoration(
                              border: Border(bottom: BorderSide(color: Color(0xFFF1F5F9))),
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text(
                                  'MATA KULIAH POKOK',
                                  style: TextStyle(
                                    fontSize: 10,
                                    fontWeight: FontWeight.w700,
                                    color: Color(0xFF94A3B8),
                                    letterSpacing: 0.5,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  currentAj.mataKuliahNama,
                                  style: const TextStyle(
                                    fontSize: 15,
                                    fontWeight: FontWeight.w600,
                                    color: Color(0xFF0F172A),
                                  ),
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  'TIF-${currentAj.mataKuliahId} | ${currentAj.sks} SKS | Teori & Praktik',
                                  style: const TextStyle(
                                    fontSize: 12,
                                    color: Color(0xFF64748B),
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 12),
                          
                          // Grid Semester & Kelas
                          Row(
                            children: [
                              Expanded(
                                child: Container(
                                  padding: const EdgeInsets.all(10),
                                  decoration: BoxDecoration(
                                    color: const Color(0xFFF8FAFC),
                                    borderRadius: BorderRadius.circular(8),
                                    border: Border.all(color: const Color(0xFFF1F5F9)),
                                  ),
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      const Text('TINGKAT SEMESTER', style: TextStyle(fontSize: 10, fontWeight: FontWeight.w700, color: Color(0xFF94A3B8))),
                                      const SizedBox(height: 2),
                                      Text('Semester ${currentAj.semester}', style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: Color(0xFF0F172A))),
                                    ],
                                  ),
                                ),
                              ),
                              const SizedBox(width: 10),
                              Expanded(
                                child: Container(
                                  padding: const EdgeInsets.all(10),
                                  decoration: BoxDecoration(
                                    color: const Color(0xFFF8FAFC),
                                    borderRadius: BorderRadius.circular(8),
                                    border: Border.all(color: const Color(0xFFF1F5F9)),
                                  ),
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      const Text('ALOKASI KELAS', style: TextStyle(fontSize: 10, fontWeight: FontWeight.w700, color: Color(0xFF94A3B8))),
                                      const SizedBox(height: 2),
                                      Text(cleanKelas, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: Color(0xFF0F172A))),
                                    ],
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 10),

                          // Hari & Tanggal
                          Container(
                            padding: const EdgeInsets.all(10),
                            width: double.infinity,
                            decoration: BoxDecoration(
                              color: const Color(0xFFF8FAFC),
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(color: const Color(0xFFF1F5F9)),
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text('HARI & TANGGAL', style: TextStyle(fontSize: 10, fontWeight: FontWeight.w700, color: Color(0xFF94A3B8))),
                                const SizedBox(height: 2),
                                Text('${currentAj.hari}, 12 Oktober 2026', style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: Color(0xFF0F172A))),
                              ],
                            ),
                          ),
                          const SizedBox(height: 10),

                          // Waktu
                          Container(
                            padding: const EdgeInsets.all(10),
                            width: double.infinity,
                            decoration: BoxDecoration(
                              color: const Color(0xFFF8FAFC),
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(color: const Color(0xFFF1F5F9)),
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text('WAKTU PERKULIAHAN', style: TextStyle(fontSize: 10, fontWeight: FontWeight.w700, color: Color(0xFF94A3B8))),
                                const SizedBox(height: 2),
                                Text(currentAj.waktuFormatted, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: AppColors.primary)),
                              ],
                            ),
                          ),
                          const SizedBox(height: 10),

                          // Ruangan
                          Container(
                            padding: const EdgeInsets.all(12),
                            width: double.infinity,
                            decoration: BoxDecoration(
                              color: const Color(0xFFF8FAFC),
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(color: const Color(0xFFF1F5F9)),
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                  children: [
                                    const Text('RUANGAN & TEMPAT', style: TextStyle(fontSize: 10, fontWeight: FontWeight.w700, color: Color(0xFF94A3B8))),
                                    const Text('Tersedia', style: TextStyle(fontSize: 10, fontWeight: FontWeight.w700, color: AppColors.primary)),
                                  ],
                                ),
                                const SizedBox(height: 4),
                                Text('${currentAj.gedungNama} — ${currentAj.ruanganNama}', style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: Color(0xFF0F172A))),
                                const SizedBox(height: 6),
                                const Divider(color: Color(0xFFE2E8F0), height: 1),
                                const SizedBox(height: 6),
                                const Text('Kapasitas 40 Kursi | Fasilitas Smart TV & AC', style: TextStyle(fontSize: 11, color: Color(0xFF64748B))),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),

              // ── 3. FOOTER ACTION BAR (4 Buttons Grid) ──
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                decoration: const BoxDecoration(
                  color: Colors.white,
                  border: Border(top: BorderSide(color: Color(0xFFF1F5F9))),
                ),
                child: Column(
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: OutlinedButton(
                            style: OutlinedButton.styleFrom(
                              foregroundColor: const Color(0xFF334155),
                              backgroundColor: const Color(0xFFF8FAFC),
                              side: const BorderSide(color: Color(0xFFE2E8F0)),
                              padding: const EdgeInsets.symmetric(vertical: 12),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                            ),
                            onPressed: () => AjuanPengajaranDialogs.showConflictCheckDialog(
                              context: context,
                              ajuan: currentAj,
                            ),
                            child: const Text('Cek Bentrok', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600)),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: OutlinedButton(
                            style: OutlinedButton.styleFrom(
                              foregroundColor: const Color(0xFF334155),
                              backgroundColor: const Color(0xFFF8FAFC),
                              side: const BorderSide(color: Color(0xFFE2E8F0)),
                              padding: const EdgeInsets.symmetric(vertical: 12),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                            ),
                            onPressed: () => AjuanPengajaranDialogs.showDetailDialog(
                              context: context,
                              ajuan: currentAj,
                              currentRole: 'dosen',
                              onRefresh: onRefresh,
                            ),
                            child: const Text('Detail', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600)),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        Expanded(
                          child: OutlinedButton(
                            style: OutlinedButton.styleFrom(
                              foregroundColor: const Color(0xFFBE123C),
                              backgroundColor: const Color(0xFFFFF1F2),
                              side: const BorderSide(color: Color(0xFFFDA4AF)),
                              padding: const EdgeInsets.symmetric(vertical: 12),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                            ),
                            onPressed: () {
                              _confirmDeleteAjuan(context, context.read<ApiService>(), currentAj);
                            },
                            child: const Text('Hapus', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600)),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: _buildPrimaryActionButton(context, currentAj),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildPrimaryActionButton(BuildContext context, AjuanPengajaranModel aj) {
    final api = context.read<ApiService>();
    final conflictInfo = api.checkBuildingConflict(aj);
    final isConflict = aj.status == 'bentrok_terdeteksi' ||
        conflictInfo['hasConflict'] == true ||
        (aj.status != 'disetujui_admin' &&
            aj.status != 'banding_disetujui' &&
            aj.bentrokDetail != null &&
            aj.bentrokDetail!.isNotEmpty);

    if (isConflict || aj.status == 'bentrok_terdeteksi' || aj.status.startsWith('ditolak')) {
      return ElevatedButton(
        style: ElevatedButton.styleFrom(
          backgroundColor: const Color(0xFF7C3AED),
          foregroundColor: Colors.white,
          padding: const EdgeInsets.symmetric(vertical: 12),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
          elevation: 2,
        ),
        onPressed: () {
          AjuanPengajaranDialogs.showBandingDialog(
            context: context,
            ajuan: aj,
            onConfirmBanding: (alasan, prefHari, prefJam) async {
              await api.submitBandingAjuan(
                ajuanId: aj.id,
                alasan: alasan,
                preferensiHari: prefHari,
                preferensiJam: prefJam,
              );
              onRefresh();
            },
          );
        },
        child: const Text('Banding Jadwal', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
      );
    }

    if (aj.status == 'menunggu_banding') {
      return ElevatedButton(
        style: ElevatedButton.styleFrom(
          backgroundColor: const Color(0xFFF3E8FF),
          foregroundColor: const Color(0xFF7C3AED),
          padding: const EdgeInsets.symmetric(vertical: 12),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
          elevation: 0,
        ),
        onPressed: null,
        child: const Text('Ditinjau Banding', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
      );
    }

    return ElevatedButton(
      style: ElevatedButton.styleFrom(
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
        padding: const EdgeInsets.symmetric(vertical: 12),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        elevation: 2,
      ),
      onPressed: () {
        AjuanPengajaranDialogs.showEditDialog(
          context: context,
          ajuan: aj,
          currentRole: user?.role ?? 'dosen',
          onSaved: (updated) {
            onRefresh();
            if (context.mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Data ajuan berhasil diperbarui!'),
                  backgroundColor: AppColors.primary,
                ),
              );
            }
          },
        );
      },
      child: const Text('Sesuaikan', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
    );
  }

  Future<void> _confirmDeleteAjuan(BuildContext context, ApiService api, AjuanPengajaranModel aj) async {
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
              'Apakah Anda yakin ingin menghapus pengajuan mata kuliah "${aj.mataKuliahNama}"?',
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
      await api.deleteAjuanPengajaran(aj.id);
      onRefresh();
    }
  }
}

