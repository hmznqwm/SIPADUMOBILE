// File: dosen_ajuan_tab.dart
// Deskripsi: Widget tab daftar pengajuan jam & ruang mengajar dosen.
// Fungsi: Menampilkan kartu ajuan pengajaran, tombol buat ajuan baru, modal detail, cek bentrok, edit, hapus, dan banding.

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../../config/constants.dart';
import '../../../../data/models/ajuan_pengajaran_model.dart';
import '../../../../data/services/api_service.dart';
import '../../auth/view_models/auth_view_model.dart';
import '../view_models/availability_view_model.dart';
import 'ajuan_pengajaran_dialogs.dart';
import 'cards/dosen_ajuan_card.dart';

class DosenAjuanTab extends StatefulWidget {
  final List<AjuanPengajaranModel> liveAjuanList;
  final bool isLoadingAjuan;
  final Future<void> Function() onRefresh;
  final Set<String> selectedAjuanIds;
  final Function(String id, VoidCallback defaultAction) onAjuanTap;
  final Function(String id) onAjuanLongPress;

  const DosenAjuanTab({
    super.key,
    required this.liveAjuanList,
    required this.isLoadingAjuan,
    required this.onRefresh,
    required this.selectedAjuanIds,
    required this.onAjuanTap,
    required this.onAjuanLongPress,
  });

  @override
  State<DosenAjuanTab> createState() => _DosenAjuanTabState();
}

class _DosenAjuanTabState extends State<DosenAjuanTab> {
  @override
  Widget build(BuildContext context) {
    final api = context.read<ApiService>();
    final user = context.watch<AuthViewModel>().currentUser;
    final isSubmissionActive =
        context.watch<AvailabilityViewModel>().isSubmissionActive;

    // Filter proposals by dosen if not admin, or show all for demo
    final dosenAjuanList = widget.liveAjuanList.where((a) {
      if (user?.role == 'dosen' && user?.id != null) {
        return a.dosenId == user!.id ||
            a.dosenNama.toLowerCase().contains(user.nama.toLowerCase());
      }
      return true;
    }).toList();

    final isSelectionMode = widget.selectedAjuanIds.isNotEmpty;

    return RefreshIndicator(
      onRefresh: widget.onRefresh,
      color: AppColors.primary,
      child: ListView(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 90),
        children: [
          // ── Action Button: Ajukan Jam & Ruang Baru / Warning Locked ──
          if (!isSubmissionActive)
            Container(
              margin: const EdgeInsets.only(bottom: 12),
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: const Color(0xFFFEF2F2),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: const Color(0xFFFECACA)),
              ),
              child: Row(
                children: const [
                  Icon(
                    Icons.lock_clock_rounded,
                    color: AppColors.error,
                    size: 20,
                  ),
                  SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      'Window Pengajuan Dikunci: Pengiriman dan pembuatan ajuan jadwal mengajar baru saat ini ditutup oleh Admin.',
                      style: TextStyle(
                        fontSize: 12,
                        color: Color(0xFF991B1B),
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: !isSubmissionActive
                  ? () {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text(
                            'Window pengajuan sedang dikunci oleh Admin. Anda tidak dapat membuat ajuan baru.',
                          ),
                          backgroundColor: AppColors.error,
                        ),
                      );
                    }
                  : () {
                      AjuanPengajaranDialogs.showCreateDialog(
                        context: context,
                        dosenId: user?.id ?? 'D001',
                        dosenNama:
                            user?.nama ?? 'Dr. Eng. Ir. Budi Santoso, M.T.',
                        fakultasNama: user?.fakultasNama ?? 'Fakultas Teknik',
                        jurusanNama: user?.jurusanNama ?? 'Teknik Informatika',
                        onCreated: (newAjuan) async {
                          await api.submitAjuanPengajaran(newAjuan);
                          widget.onRefresh();
                        },
                      );
                    },
              icon: Icon(
                !isSubmissionActive
                    ? Icons.lock_outline_rounded
                    : Icons.add_circle_outline_rounded,
                size: 20,
                color: Colors.white,
              ),
              label: Text(
                !isSubmissionActive
                    ? 'Pengajuan Ditutup (Terkunci)'
                    : '+ Ajukan Jam & Ruang Mengajar Baru',
                style: const TextStyle(
                  fontSize: 13.5,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: !isSubmissionActive
                    ? const Color(0xFF94A3B8)
                    : AppColors.primary,
                padding: const EdgeInsets.symmetric(vertical: 13),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                elevation: 1,
              ),
            ),
          ),

          const SizedBox(height: 14),

          // ── Section Header ──
          Text(
            'Daftar Ajuan Pengajaran Saya (${dosenAjuanList.length})',
            style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.bold,
              color: Color(0xFF1E293B),
            ),
          ),

          const SizedBox(height: 6),

          if (widget.isLoadingAjuan)
            const Center(
              child: Padding(
                padding: EdgeInsets.all(32),
                child: CircularProgressIndicator(color: AppColors.primary),
              ),
            )
          else if (dosenAjuanList.isEmpty)
            Container(
              padding: const EdgeInsets.all(28),
              margin: const EdgeInsets.only(top: 8),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: const Color(0xFFE2E8F0)),
              ),
              child: Column(
                children: [
                  Icon(Icons.inbox_outlined, size: 48, color: Colors.grey[400]),
                  const SizedBox(height: 10),
                  const Text(
                    'Belum Ada Ajuan Pengajaran',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF64748B),
                    ),
                  ),
                  const SizedBox(height: 6),
                  const Text(
                    'Klik tombol hijau di atas untuk mengajukan mata kuliah, jadwal hari, jam, gedung, dan ruangan.',
                    textAlign: TextAlign.center,
                    style: TextStyle(fontSize: 12, color: Color(0xFF94A3B8)),
                  ),
                ],
              ),
            )
          else
            ...dosenAjuanList.map((ajuan) {
              final isSelected = widget.selectedAjuanIds.contains(ajuan.id);
              return DosenAjuanCard(
                ajuan: ajuan,
                user: user,
                isSelected: isSelected,
                isSelectionMode: isSelectionMode,
                onRefresh: widget.onRefresh,
                onAjuanTap: widget.onAjuanTap,
                onAjuanLongPress: widget.onAjuanLongPress,
              );
            }),
        ],
      ),
    );
  }
}
