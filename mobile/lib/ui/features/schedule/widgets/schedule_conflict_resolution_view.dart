import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../../config/constants.dart';
import '../../../../data/models/ajuan_pengajaran_model.dart';
import '../../../../data/services/api_service.dart';
import '../../auth/view_models/auth_view_model.dart';
import '../../availability/widgets/ajuan_pengajaran_dialogs.dart';
import '../view_models/schedule_view_model.dart';

class ScheduleConflictResolutionView extends StatelessWidget {
  final List<AjuanPengajaranModel> allAjuanList;
  final Set<String> selectedConflictIds;
  final bool isConflictSelectionMode;
  final Future<void> Function() onRefresh;
  final void Function(String id) onConflictTap;
  final void Function(String id) onConflictLongPress;
  final void Function(List<AjuanPengajaranModel> conflicts) onShowBatchResolveDialog;

  const ScheduleConflictResolutionView({
    super.key,
    required this.allAjuanList,
    required this.selectedConflictIds,
    required this.isConflictSelectionMode,
    required this.onRefresh,
    required this.onConflictTap,
    required this.onConflictLongPress,
    required this.onShowBatchResolveDialog,
  });

  @override
  Widget build(BuildContext context) {
    final user = context.watch<AuthViewModel>().currentUser;
    final isDekan = user?.role == 'dekan';
    final isKaProdi = user?.role == 'kajur';
    final api = context.read<ApiService>();

    final allConflicts = allAjuanList.where((a) {
      if (a.status.startsWith('ditolak')) return false;
      final conflictInfo = api.checkBuildingConflict(a);
      final isConflict = a.status == 'bentrok_terdeteksi' ||
          a.status == 'menunggu_banding' ||
          conflictInfo['hasConflict'] == true ||
          (a.status != 'disetujui_admin' && a.status != 'banding_disetujui' && a.bentrokDetail != null && a.bentrokDetail!.isNotEmpty);
      if (!isConflict) return false;
      if (isKaProdi) {
        return a.jurusanNama == (user?.jurusanNama ?? 'Teknik Informatika');
      }
      if (isDekan) {
        return a.fakultasNama == 'Fakultas Sains & Teknologi';
      }
      return true;
    }).toList();

    final hasConflicts = allConflicts.isNotEmpty;

    return RefreshIndicator(
      onRefresh: onRefresh,
      color: AppColors.primary,
      child: ListView(
        padding: const EdgeInsets.fromLTRB(16, 14, 16, 90),
        children: [
          // ── Smart Resolution Button (RCK) ──
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(AppRadius.md),
              border: Border.all(color: const Color(0xFFE2E8F0)),
              boxShadow: const [
                BoxShadow(
                  color: Color(0x04000000),
                  blurRadius: 4,
                  offset: Offset(0, 1),
                ),
              ],
            ),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: hasConflicts
                        ? const Color(0xFFFEF2F2)
                        : const Color(0xFFF0FDF4),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(
                    hasConflicts
                        ? Icons.published_with_changes_rounded
                        : Icons.check_circle_outline_rounded,
                    color: hasConflicts
                        ? const Color(0xFFDC2626)
                        : const Color(0xFF059669),
                    size: 20,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        'RCK - Resolusi & Banding',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.bold,
                          color: Colors.teal[900],
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        hasConflicts
                            ? 'Penyesuaian jadwal & banding'
                            : 'Semua jadwal aman & selaras',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontSize: 11,
                          color: hasConflicts ? const Color(0xFFDC2626) : AppColors.textSecondary,
                          fontWeight: hasConflicts ? FontWeight.w600 : FontWeight.normal,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                if (hasConflicts)
                  ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primary,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                      elevation: 0,
                    ),
                    onPressed: () => onShowBatchResolveDialog(allConflicts),
                    child: const Text(
                      'Sesuaikan',
                      style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
                    ),
                  )
                else
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                    decoration: BoxDecoration(
                      color: const Color(0xFFF0FDF4),
                      borderRadius: BorderRadius.circular(6),
                      border: Border.all(color: const Color(0xFFA7F3D0)),
                    ),
                    child: const Text(
                      'Selaras',
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF059669),
                      ),
                    ),
                  ),
              ],
            ),
          ),
          const SizedBox(height: 10),

          // ── Section Title: Pusat Resolusi Konflik ──
          Row(
            children: [
              const Text(
                'Pusat Resolusi Konflik Jadwal',
                style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: AppColors.textPrimary),
              ),
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                decoration: BoxDecoration(
                  color: allConflicts.isEmpty ? const Color(0xFFECFDF5) : const Color(0xFFFEF2F2),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: allConflicts.isEmpty ? const Color(0xFFA7F3D0) : const Color(0xFFFECACA)),
                ),
                child: Text(
                  '${allConflicts.length} Konflik',
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.bold,
                    color: allConflicts.isEmpty ? const Color(0xFF047857) : const Color(0xFFB91C1C),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),

          if (allConflicts.isEmpty)
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: const Color(0xFFF8FAFC),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: const Color(0xFFE2E8F0)),
              ),
              child: const Row(
                children: [
                  Icon(Icons.check_circle_outline_rounded, color: Color(0xFF10B981), size: 18),
                  SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Tidak ada konflik. Seluruh jadwal aman.',
                      style: TextStyle(fontSize: 12, color: Color(0xFF475569)),
                    ),
                  ),
                ],
              ),
            )
          else
            ...allConflicts.map((aj) {
              final isSelected = selectedConflictIds.contains(aj.id);
              final suggestion = api.findSmartAlternativeSlot(aj);
              return Container(
                margin: const EdgeInsets.only(bottom: 10),
                decoration: BoxDecoration(
                  color: isSelected ? const Color(0xFFF0FDF4) : Colors.white,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: isSelected ? AppColors.primary : const Color(0xFFE2E8F0),
                    width: isSelected ? 1.8 : 1.0,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: isSelected
                          ? AppColors.primary.withValues(alpha: 0.12)
                          : const Color(0x06DC2626),
                      blurRadius: isSelected ? 6 : 4,
                      offset: const Offset(0, 1),
                    ),
                  ],
                ),
                child: Material(
                  color: Colors.transparent,
                  child: InkWell(
                    onTap: () => onConflictTap(aj.id),
                    onLongPress: () => onConflictLongPress(aj.id),
                    borderRadius: BorderRadius.circular(12),
                    child: Padding(
                      padding: const EdgeInsets.all(12),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              if (isConflictSelectionMode) ...[
                                Container(
                                  margin: const EdgeInsets.only(right: 8),
                                  child: Icon(
                                    isSelected
                                        ? Icons.check_circle_rounded
                                        : Icons.radio_button_unchecked_rounded,
                                    size: 18,
                                    color: isSelected ? AppColors.primary : const Color(0xFF94A3B8),
                                  ),
                                ),
                              ],
                              Expanded(
                                child: Text(
                                  aj.mataKuliahNama,
                                  style: const TextStyle(fontSize: 13.5, fontWeight: FontWeight.bold, color: Color(0xFF0F172A)),
                                ),
                              ),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                                decoration: BoxDecoration(
                                  color: aj.status == 'menunggu_banding' ? const Color(0xFFFFFBEB) : const Color(0xFFFEF2F2),
                                  borderRadius: BorderRadius.circular(6),
                                  border: Border.all(color: aj.status == 'menunggu_banding' ? const Color(0xFFFDE68A) : const Color(0xFFFECACA)),
                                ),
                                child: Text(
                                  aj.status == 'menunggu_banding' ? 'Banding Dosen' : 'Bentrok Terdeteksi',
                                  style: TextStyle(
                                    fontSize: 10,
                                    fontWeight: FontWeight.bold,
                                    color: aj.status == 'menunggu_banding' ? const Color(0xFFB45309) : const Color(0xFFDC2626),
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 5),
                          Row(
                            children: [
                              const Icon(Icons.person_outline_rounded, size: 14, color: Color(0xFF475569)),
                              const SizedBox(width: 5),
                              Expanded(
                                child: Text(
                                  '${aj.dosenNama} • ${aj.fakultasNama} (Kelas ${aj.kelasNama})',
                                  style: const TextStyle(fontSize: 11.5, color: Color(0xFF475569)),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 6),
                          Container(
                            width: double.infinity,
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: aj.status == 'menunggu_banding' ? const Color(0xFFFFFBEB) : const Color(0xFFFEF2F2),
                              borderRadius: BorderRadius.circular(6),
                              border: Border.all(color: aj.status == 'menunggu_banding' ? const Color(0xFFFDE68A) : const Color(0xFFFECACA)),
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                if (aj.status == 'menunggu_banding') ...[
                                  Text(
                                    'Permohonan Dosen: ${aj.preferensiBandingHari ?? aj.hari}, ${aj.preferensiBandingJam ?? aj.waktuFormatted}',
                                    style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Color(0xFF92400E)),
                                  ),
                                  if (aj.alasanBanding != null && aj.alasanBanding!.isNotEmpty) ...[
                                    const SizedBox(height: 2),
                                    Text(
                                      'Alasan Banding: ${aj.alasanBanding}',
                                      style: const TextStyle(fontSize: 10.5, color: Color(0xFF78350F)),
                                    ),
                                  ],
                                ] else ...[
                                  Text(
                                    'Jadwal Bentrok: ${aj.hari}, ${aj.waktuFormatted} di ${aj.ruanganNama} (${aj.gedungNama})',
                                    style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Color(0xFF991B1B)),
                                  ),
                                  if (aj.bentrokDetail != null && aj.bentrokDetail!.isNotEmpty) ...[
                                    const SizedBox(height: 2),
                                    Text(
                                      aj.bentrokDetail!,
                                      style: const TextStyle(fontSize: 10.5, color: Color(0xFF7F1D1D)),
                                    ),
                                  ],
                                ],
                              ],
                            ),
                          ),
                          const SizedBox(height: 6),
                          Container(
                            width: double.infinity,
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: const Color(0xFFF0FDFA),
                              borderRadius: BorderRadius.circular(6),
                              border: Border.all(color: const Color(0xFF99F6E4)),
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: const [
                                    Icon(Icons.lightbulb_outline_rounded, color: Color(0xFF0F766E), size: 14),
                                    SizedBox(width: 4),
                                    Text(
                                      'Rekomendasi Penyesuaian',
                                      style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Color(0xFF0F766E)),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  '${suggestion['hari']}, ${suggestion['jamMulai']}-${suggestion['jamSelesai']} di ${suggestion['ruanganNama']} (${suggestion['gedungNama']})',
                                  style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Color(0xFF115E59)),
                                ),
                                Text(
                                  suggestion['reason'] ?? 'Ruangan alternatif tersedia.',
                                  style: const TextStyle(fontSize: 10.5, color: Color(0xFF134E4A)),
                                ),
                              ],
                            ),
                          ),
                          if (!isConflictSelectionMode) ...[
                            const SizedBox(height: 8),
                            Row(
                              children: [
                                Expanded(
                                  child: OutlinedButton(
                                    style: OutlinedButton.styleFrom(
                                      padding: const EdgeInsets.symmetric(vertical: 8),
                                      side: const BorderSide(color: Color(0xFFCBD5E1)),
                                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                                    ),
                                    onPressed: () {
                                      AjuanPengajaranDialogs.showEditDialog(
                                        context: context,
                                        ajuan: aj,
                                        currentRole: isKaProdi ? 'kaprodi' : (isDekan ? 'dekan' : 'admin'),
                                        onSaved: (updated) async {
                                          if (isKaProdi) {
                                            await api.kaprodiVerifyAjuan(aj.id, updatedData: updated);
                                          } else if (isDekan) {
                                            await api.dekanApproveAjuan(aj.id, updatedData: updated);
                                          } else {
                                            await api.adminApproveFinalAjuan(aj.id, updatedData: updated);
                                          }
                                          await onRefresh();
                                          if (context.mounted) {
                                            await context.read<ScheduleViewModel>().loadScheduleData();
                                          }
                                        },
                                      );
                                    },
                                    child: const Text('Edit Manual', style: TextStyle(fontSize: 11.5, color: Color(0xFF475569))),
                                  ),
                                ),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: ElevatedButton.icon(
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: AppColors.primary,
                                      foregroundColor: Colors.white,
                                      padding: const EdgeInsets.symmetric(vertical: 8),
                                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                                      elevation: 0,
                                    ),
                                    onPressed: () async {
                                      final nextStatus = isKaProdi
                                          ? 'menunggu_dekan'
                                          : (isDekan ? 'menunggu_admin' : 'disetujui_admin');
                                      final updated = aj.copyWith(
                                        gedungNama: suggestion['gedungNama'],
                                        ruanganNama: suggestion['ruanganNama'],
                                        hari: suggestion['hari'],
                                        jamMulai: suggestion['jamMulai'],
                                        jamSelesai: suggestion['jamSelesai'],
                                        status: nextStatus,
                                        catatanKaProdi: isKaProdi ? 'Rekomendasi solusi cerdas disetujui KaProdi.' : aj.catatanKaProdi,
                                        catatanDekan: isDekan ? 'Rekomendasi solusi cerdas disetujui Dekan.' : aj.catatanDekan,
                                        catatanAdmin: (!isDekan && !isKaProdi) ? 'Rekomendasi solusi cerdas diterapkan.' : aj.catatanAdmin,
                                        clearBentrokDetail: true,
                                        updatedAt: DateTime.now(),
                                      );
                                      final messenger = ScaffoldMessenger.of(context);
                                      if (isKaProdi) {
                                        await api.kaprodiVerifyAjuan(aj.id, updatedData: updated);
                                      } else if (isDekan) {
                                        await api.dekanApproveAjuan(aj.id, updatedData: updated);
                                      } else {
                                        await api.adminApproveFinalAjuan(aj.id, updatedData: updated);
                                      }
                                      await onRefresh();
                                      if (context.mounted) {
                                        await context.read<ScheduleViewModel>().loadScheduleData();
                                        messenger.showSnackBar(
                                          const SnackBar(
                                            content: Text('Rekomendasi diterapkan.'),
                                            backgroundColor: AppColors.primary,
                                          ),
                                        );
                                      }
                                    },
                                    icon: const Icon(Icons.check_rounded, size: 15),
                                    label: const Text('Terapkan Solusi', style: TextStyle(fontSize: 11.5, fontWeight: FontWeight.bold)),
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ],
                      ),
                    ),
                  ),
                ),
              );
            }),
        ],
      ),
    );
  }
}
