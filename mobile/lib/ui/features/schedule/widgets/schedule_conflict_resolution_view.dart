import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../../config/constants.dart';
import '../../../../data/models/ajuan_pengajaran_model.dart';
import '../../../../data/services/api_service.dart';
import '../../auth/view_models/auth_view_model.dart';
import '../../availability/widgets/ajuan_pengajaran_dialogs.dart';
import '../view_models/schedule_view_model.dart';

/// [PRESENTASI] ScheduleConflictResolutionView (Antarmuka Resolusi Konflik RCK):
/// Menampilkan daftar jadwal kuliah yang terdeteksi mengalami konflik/bentrok waktu atau ruangan,
/// serta permohonan banding dari dosen. Dilengkapi dengan trigger tombol resolusi massal RCK.
class ScheduleConflictResolutionView extends StatefulWidget {
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
  State<ScheduleConflictResolutionView> createState() => _ScheduleConflictResolutionViewState();
}

class _ScheduleConflictResolutionViewState extends State<ScheduleConflictResolutionView> {
  int _displayedCount = 10;

  @override
  Widget build(BuildContext context) {
    final user = context.watch<AuthViewModel>().currentUser;
    final isDekan = user?.role == 'dekan';
    final isKaProdi = user?.role == 'kajur';
    final api = context.read<ApiService>();

    final seenConflictIds = <String>{};
    final allConflicts = widget.allAjuanList.where((a) {
      if (seenConflictIds.contains(a.id)) return false;
      if (a.status.startsWith('ditolak')) return false;
      final conflictInfo = api.checkBuildingConflict(a);
      final isConflict = a.status == 'bentrok_terdeteksi' ||
          a.status == 'menunggu_banding' ||
          conflictInfo['hasConflict'] == true ||
          (a.status != 'disetujui_admin' && a.status != 'banding_disetujui' && a.bentrokDetail != null && a.bentrokDetail!.isNotEmpty);
      if (!isConflict) return false;
      if (isKaProdi) {
        if (user != null && user.jurusanNama.isNotEmpty && a.jurusanNama.isNotEmpty) {
          if (a.jurusanNama.toLowerCase() != user.jurusanNama.toLowerCase()) return false;
        }
      } else if (isDekan) {
        if (user != null && user.fakultasNama.isNotEmpty && a.fakultasNama.isNotEmpty) {
          if (a.fakultasNama.toLowerCase() != user.fakultasNama.toLowerCase()) return false;
        }
      }
      seenConflictIds.add(a.id);
      return true;
    }).toList();

    final visibleConflicts = allConflicts.take(_displayedCount).toList();
    final hasMore = allConflicts.length > visibleConflicts.length;
    final hasConflicts = allConflicts.isNotEmpty;

    return RefreshIndicator(
      onRefresh: () async {
        setState(() => _displayedCount = 10);
        await widget.onRefresh();
      },
      color: AppColors.primary,
      child: ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.fromLTRB(16, 14, 16, 90),
        children: [
          // ── Smart Resolution Button (RCK) ──
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: const Color(0xFFE2E8F0)),
              boxShadow: const [
                BoxShadow(
                  color: Color(0x06000000),
                  blurRadius: 4,
                  offset: Offset(0, 2),
                ),
              ],
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Container(
                  width: 38,
                  height: 38,
                  decoration: BoxDecoration(
                    color: const Color(0xFFF1F5F9),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Icon(
                    Icons.published_with_changes_rounded,
                    color: Color(0xFF64748B),
                    size: 20,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Engine RCK',
                        style: TextStyle(
                          fontSize: 13.5,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF0F172A),
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        hasConflicts
                            ? 'Penyesuaian jadwal & banding'
                            : 'Semua jadwal aman & selaras',
                        style: const TextStyle(
                          fontSize: 11,
                          color: Color(0xFF64748B),
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 10),
                SizedBox(
                  width: 90,
                  height: 34,
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primary,
                      foregroundColor: Colors.white,
                      elevation: 0,
                      padding: EdgeInsets.zero,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                    onPressed: hasConflicts
                        ? () => widget.onShowBatchResolveDialog(allConflicts)
                        : null,
                    child: Text(
                      hasConflicts ? 'Sesuaikan' : 'Selaras',
                      style: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),

          // ── Section Title: Pusat Resolusi Konflik ──
          const Text(
            'Pusat Resolusi Konflik Jadwal',
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.bold,
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: 12),
          if (!hasConflicts)
            Container(
              padding: const EdgeInsets.all(32),
              margin: const EdgeInsets.only(top: 20),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(AppRadius.md),
                border: Border.all(color: const Color(0xFFE2E8F0)),
              ),
              child: Column(
                children: [
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: const BoxDecoration(
                      color: Color(0xFFF1F5F9),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.check_circle_outline_rounded,
                      size: 44,
                      color: Color(0xFF94A3B8),
                    ),
                  ),
                  const SizedBox(height: 12),
                  const Text('Semua Pengajuan Bebas Bentrok', style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: Color(0xFF1E293B))),
                  const SizedBox(height: 4),
                  const Text('Seluruh jadwal perkuliahan dosen telah tervalidasi dan siap diterbitkan.', textAlign: TextAlign.center, style: TextStyle(fontSize: 12, color: Color(0xFF64748B))),
                ],
              ),
            )
          else ...[
            ...visibleConflicts.map((aj) {
              final isSelected = widget.selectedConflictIds.contains(aj.id);
              final conflictInfo = api.checkBuildingConflict(aj);
              final bentrokPesan = aj.bentrokDetail ?? conflictInfo['message'] ?? 'Konflik jadwal mengajar terdeteksi.';
              final suggestion = api.findSmartAlternativeSlot(aj);

              return Container(
                margin: const EdgeInsets.only(bottom: 12),
                decoration: BoxDecoration(
                  color: isSelected ? const Color(0xFFEFF6FF) : Colors.white,
                  borderRadius: BorderRadius.circular(AppRadius.md),
                  border: Border.all(color: isSelected ? AppColors.primary : const Color(0xFFE2E8F0), width: isSelected ? 1.5 : 1),
                  boxShadow: const [BoxShadow(color: Color(0x04000000), blurRadius: 4, offset: Offset(0, 1))],
                ),
                child: Material(
                  color: Colors.transparent,
                  child: InkWell(
                    borderRadius: BorderRadius.circular(AppRadius.md),
                    onTap: () => widget.onConflictTap(aj.id),
                    onLongPress: () => widget.onConflictLongPress(aj.id),
                    child: Padding(
                      padding: const EdgeInsets.all(12),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              if (widget.isConflictSelectionMode)
                                Padding(
                                  padding: const EdgeInsets.only(right: 8, top: 2),
                                  child: Icon(
                                    isSelected ? Icons.check_box_rounded : Icons.check_box_outline_blank_rounded,
                                    color: isSelected ? AppColors.primary : const Color(0xFF94A3B8),
                                    size: 20,
                                  ),
                                ),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(aj.mataKuliahNama, style: const TextStyle(fontSize: 13.5, fontWeight: FontWeight.bold, color: Color(0xFF0F172A))),
                                    const SizedBox(height: 2),
                                    Text('${aj.dosenNama} • ${aj.jurusanNama}', style: const TextStyle(fontSize: 11.5, color: Color(0xFF64748B))),
                                  ],
                                ),
                              ),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                decoration: BoxDecoration(
                                  color: const Color(0xFFFEF2F2),
                                  borderRadius: BorderRadius.circular(12),
                                  border: Border.all(color: const Color(0xFFFECACA)),
                                ),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: const [
                                    Icon(Icons.warning_amber_rounded, size: 12, color: AppColors.error),
                                    SizedBox(width: 4),
                                    Text('Bentrok', style: TextStyle(fontSize: 10.5, fontWeight: FontWeight.bold, color: AppColors.error)),
                                  ],
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 8),
                          Container(
                            width: double.infinity,
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: const Color(0xFFFFFBEB),
                              borderRadius: BorderRadius.circular(6),
                              border: Border.all(color: const Color(0xFFFDE68A)),
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: const [
                                    Icon(Icons.info_outline_rounded, color: Color(0xFFB45309), size: 14),
                                    SizedBox(width: 4),
                                    Text('Detail Bentrok Terdeteksi:', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Color(0xFFB45309))),
                                  ],
                                ),
                                const SizedBox(height: 2),
                                Text(bentrokPesan, style: const TextStyle(fontSize: 11, color: Color(0xFF78350F))),
                                if (aj.ruanganNama.isNotEmpty) ...[
                                  const SizedBox(height: 2),
                                  Text(
                                    'Posisi Pengajuan: ${aj.hari}, ${aj.jamMulai}-${aj.jamSelesai} di ${aj.ruanganNama} (${aj.gedungNama})',
                                    style: const TextStyle(fontSize: 10.5, fontStyle: FontStyle.italic, color: Color(0xFF92400E)),
                                  ),
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
                                    Text('Rekomendasi Penyesuaian', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Color(0xFF0F766E))),
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
                          if (!widget.isConflictSelectionMode) ...[
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
                                          await widget.onRefresh();
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
                                      await widget.onRefresh();
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
            if (hasMore)
              Padding(
                padding: const EdgeInsets.only(top: 10, bottom: 16),
                child: InkWell(
                  onTap: () {
                    setState(() {
                      _displayedCount += 10;
                    });
                  },
                  borderRadius: BorderRadius.circular(8),
                  child: Container(
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(vertical: 9, horizontal: 14),
                    decoration: BoxDecoration(
                      color: const Color(0xFFF8FAFC),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: const Color(0xFFE2E8F0)),
                    ),
                    alignment: Alignment.center,
                    child: const Text(
                      'Tampilkan Lainnya',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: Color(0xFF475569),
                      ),
                    ),
                  ),
                ),
              ),
          ],
        ],
      ),
    );
  }
}
