// File: schedule_screen.dart
// Deskripsi: Tampilan (View) halaman daftar jadwal perkuliahan final.
// Fungsi: Menampilkan kartu jadwal mengajar/kuliah, filter tab per hari operasional, detail ruang/gedung, SKS, rombel, dan pusat resolusi konflik.

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

import '../../../../config/constants.dart';
import '../../../../data/models/ajuan_pengajaran_model.dart';
import '../../../../data/services/api_service.dart';
import '../../../core/widgets/empty_state_widget.dart';
import '../../auth/view_models/auth_view_model.dart';
import '../view_models/schedule_view_model.dart';
import '../widgets/schedule_card.dart';
import '../widgets/schedule_filter_bar.dart';
import '../widgets/schedule_conflict_resolution_view.dart';
import '../widgets/schedule_batch_resolve_dialog.dart';

class ScheduleScreen extends StatefulWidget {
  const ScheduleScreen({super.key});

  @override
  State<ScheduleScreen> createState() => _ScheduleScreenState();
}

class _ScheduleScreenState extends State<ScheduleScreen> {
  int _selectedAdminTab = 0; // 0: Jadwal Final, 1: Resolusi Konflik
  int _displayedCount = 10;
  List<AjuanPengajaranModel> _allAjuanList = [];
  final Set<String> _selectedConflictIds = {};

  bool get _isConflictSelectionMode => _selectedConflictIds.isNotEmpty;

  void _handleConflictTap(String id) {
    if (_isConflictSelectionMode) {
      HapticFeedback.selectionClick();
      setState(() {
        if (_selectedConflictIds.contains(id)) {
          _selectedConflictIds.remove(id);
        } else {
          _selectedConflictIds.add(id);
        }
      });
    }
  }

  void _handleConflictLongPress(String id) {
    HapticFeedback.heavyImpact();
    setState(() {
      _selectedConflictIds.add(id);
    });
  }

  void _confirmDeleteSelectedConflicts(BuildContext context) {
    final count = _selectedConflictIds.length;
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
        title: Row(
          children: [
            const Icon(Icons.delete_outline_rounded, color: AppColors.error),
            const SizedBox(width: 8),
            Text('Hapus $count Ajuan Bentrok?', style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
          ],
        ),
        content: Text('Apakah Anda yakin ingin menghapus $count data ajuan bentrok yang dipilih secara permanen?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Batal'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.error,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
            ),
            onPressed: () async {
              final idsToDelete = _selectedConflictIds.toList();
              final messenger = ScaffoldMessenger.of(context);
              final api = context.read<ApiService>();
              Navigator.pop(ctx);
              await api.deleteMultipleAjuanPengajaran(idsToDelete);
              setState(() {
                _selectedConflictIds.clear();
              });
              await _loadAjuanData();
              if (context.mounted) {
                await context.read<ScheduleViewModel>().loadScheduleData();
                messenger.showSnackBar(
                  SnackBar(
                    content: Text('$count ajuan bentrok berhasil dihapus!'),
                    backgroundColor: AppColors.primaryDark,
                  ),
                );
              }
            },
            child: const Text('Hapus Masal'),
          ),
        ],
      ),
    );
  }

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<ScheduleViewModel>().loadScheduleData();
      _loadAjuanData();
    });
  }

  Future<void> _loadAjuanData() async {
    try {
      final api = context.read<ApiService>();
      final ajuan = await api.getAjuanPengajaranList();
      if (mounted) {
        setState(() {
          _allAjuanList = ajuan;
        });
      }
    } catch (_) {}
  }

  void _showBatchResolveConfirmationDialog(List<AjuanPengajaranModel> conflicts) {
    ScheduleBatchResolveDialog.show(
      context: context,
      conflicts: conflicts,
      onResolved: _loadAjuanData,
    );
  }

  @override
  Widget build(BuildContext context) {
    final viewModel = context.watch<ScheduleViewModel>();
    final user = context.watch<AuthViewModel>().currentUser;
    final isDekan = user?.role == 'dekan';
    final isAdmin = user?.role == 'admin';
    final isKaProdi = user?.role == 'kajur';
    final isPrivileged = isAdmin || isDekan || isKaProdi;
    final api = context.watch<ApiService>();

    final seenIds = <String>{};
    final conflictsForRole = _allAjuanList.where((a) {
      if (seenIds.contains(a.id)) return false;
      if (a.status.startsWith('ditolak')) return false;
      final conflictInfo = api.checkBuildingConflict(a);
      final bool isConflict;
      if (conflictInfo['hasConflict'] == true) {
        isConflict = true;
      } else if (a.status == 'disetujui_admin' || a.status == 'banding_disetujui') {
        isConflict = false;
      } else {
        isConflict = a.status == 'bentrok_terdeteksi' ||
            a.status == 'menunggu_banding' ||
            (a.bentrokDetail != null && a.bentrokDetail!.isNotEmpty);
      }
      if (!isConflict) return false;
      if (isKaProdi) {
        if (a.jurusanNama != (user?.jurusanNama ?? 'Teknik Informatika')) return false;
      } else if (isDekan) {
        if (a.fakultasNama != 'Fakultas Sains & Teknologi') return false;
      }
      seenIds.add(a.id);
      return true;
    }).toList();
    final conflictCount = conflictsForRole.length;

    if (viewModel.isLoading) {
      return const Center(
        child: CircularProgressIndicator(
          color: AppColors.primary,
          strokeWidth: 3.2,
        ),
      );
    }

    final filteredList = viewModel.filteredJadwalList;

    return Column(
      children: [
        if (_isConflictSelectionMode)
          Container(
            color: AppColors.primary,
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            child: Row(
              children: [
                IconButton(
                  icon: const Icon(Icons.close_rounded, color: Colors.white),
                  onPressed: () => setState(() => _selectedConflictIds.clear()),
                ),
                Text(
                  '${_selectedConflictIds.length} Dipilih',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const Spacer(),
                IconButton(
                  icon: const Icon(Icons.delete_outline_rounded, color: Colors.white),
                  onPressed: () => _confirmDeleteSelectedConflicts(context),
                ),
              ],
            ),
          ),
        ScheduleFilterBar(
          viewModel: viewModel,
          user: user,
          selectedAdminTab: _selectedAdminTab,
          conflictCount: conflictCount,
          onTabChanged: (index) => setState(() => _selectedAdminTab = index),
        ),
        Container(height: 1, color: const Color(0xFFE2E8F0)),
        Expanded(
          child: (isPrivileged && _selectedAdminTab == 1)
              ? ScheduleConflictResolutionView(
                  allAjuanList: _allAjuanList,
                  selectedConflictIds: _selectedConflictIds,
                  isConflictSelectionMode: _isConflictSelectionMode,
                  onRefresh: _loadAjuanData,
                  onConflictTap: _handleConflictTap,
                  onConflictLongPress: _handleConflictLongPress,
                  onShowBatchResolveDialog: _showBatchResolveConfirmationDialog,
                )
              : filteredList.isEmpty
                  ? const EmptyStateWidget(
                      icon: Icons.calendar_today_outlined,
                      title: 'Tidak Ada Jadwal',
                      message: 'Belum ada jadwal mengajar pada hari yang dipilih.',
                    )
                  : ListView.builder(
                      padding: const EdgeInsets.fromLTRB(16, 16, 16, 20),
                      itemCount: filteredList.length > _displayedCount
                          ? _displayedCount + 1
                          : filteredList.length,
                      itemBuilder: (context, index) {
                        if (index == _displayedCount && filteredList.length > _displayedCount) {
                          return Padding(
                            padding: const EdgeInsets.only(top: 14, bottom: 16),
                            child: SizedBox(
                              width: double.infinity,
                              child: OutlinedButton.icon(
                                onPressed: () {
                                  setState(() {
                                    _displayedCount += 10;
                                  });
                                },
                                icon: const Icon(Icons.expand_more_rounded, size: 20),
                                label: Text(
                                  'Muat 10 Jadwal Lagi (${filteredList.length - _displayedCount} Tersisa)',
                                  style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13),
                                ),
                                style: OutlinedButton.styleFrom(
                                  foregroundColor: AppColors.primary,
                                  backgroundColor: AppColors.primary.withValues(alpha: 0.05),
                                  side: BorderSide(color: AppColors.primary.withValues(alpha: 0.3), width: 1.2),
                                  padding: const EdgeInsets.symmetric(vertical: 13),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  elevation: 0,
                                ),
                              ),
                            ),
                          );
                        }
                        return ScheduleCard(item: filteredList[index]);
                      },
                    ),
        ),
      ],
    );
  }
}
