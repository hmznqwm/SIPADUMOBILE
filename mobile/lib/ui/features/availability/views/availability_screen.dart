// File: availability_screen.dart
// Deskripsi: Tampilan (View) utama fitur ketersediaan dan pengajuan jadwal mengajar multi-role.
// Fungsi: Orchestrator modular yang mendelegasikan tampilan ke tab Admin, KaProdi, Dekan, atau Dosen (Matriks & Ajuan).

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

import '../../../../config/constants.dart';
import '../../../../data/models/ajuan_pengajaran_model.dart';
import '../../../../data/services/api_service.dart';
import '../../auth/view_models/auth_view_model.dart';
import '../view_models/availability_view_model.dart';
import '../widgets/admin_availability_tab.dart';
import '../widgets/dekan_availability_tab.dart';
import '../widgets/dosen_ajuan_tab.dart';
import '../widgets/dosen_matrix_tab.dart';
import '../widgets/kaprodi_availability_tab.dart';
import '../widgets/ruangan_kosong_section.dart';

class AvailabilityScreen extends StatefulWidget {
  const AvailabilityScreen({super.key});

  @override
  State<AvailabilityScreen> createState() => _AvailabilityScreenState();
}

class _AvailabilityScreenState extends State<AvailabilityScreen> {
  int _dosenSelectedSubTab = 0; // 0: Matriks Ketersediaan Waktu, 1: Ajuan Jam & Ruang Mengajar
  List<AjuanPengajaranModel> _liveAjuanList = [];
  bool _isLoadingAjuan = false;

  // Multi-select state khusus Admin, Dekan, KaProdi, Dosen di Tab Pengajuan
  final Set<String> _selectedAjuanIds = {};
  bool get _isAjuanSelectionMode => _selectedAjuanIds.isNotEmpty;

  List<Map<String, dynamic>> _dynamicRuanganList = [];

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<AvailabilityViewModel>().loadAvailabilityData();
      _loadAjuanData();
    });
  }

  Future<void> _loadAjuanData() async {
    if (!mounted) return;
    setState(() => _isLoadingAjuan = true);
    try {
      final api = context.read<ApiService>();
      final list = await api.getAjuanPengajaranList();
      final ruanganModels = await api.getRuanganList();
      final mapList = ruanganModels.map((r) => {
        'id': r.id,
        'nama': r.nama,
        'gedung': r.gedungNama,
        'lantai': 'Lantai 1',
        'kapasitas': r.kapasitas,
        'tipe': r.tipeRuangan,
        'status': 'Tersedia',
        'hariKosong': ['Senin', 'Selasa', 'Rabu', 'Kamis', 'Jumat', 'Sabtu'],
        'hariFormatted': 'Senin - Sabtu',
        'jamKosong': '07:30 - 16:20 WIB',
      }).toList();

      if (mounted) {
        setState(() {
          _liveAjuanList = list;
          _dynamicRuanganList = mapList;
          _isLoadingAjuan = false;
        });
      }
    } catch (_) {
      if (mounted) setState(() => _isLoadingAjuan = false);
    }
  }

  void _handleAjuanTap(String id, VoidCallback defaultAction) {
    if (_isAjuanSelectionMode) {
      final isSubmissionActive =
          context.read<AvailabilityViewModel>().isSubmissionActive;
      final role = context.read<AuthViewModel>().currentUser?.role ?? 'dosen';
      if (!isSubmissionActive && role == 'dosen') {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Window pengajuan sedang dikunci oleh Admin.'),
            duration: Duration(seconds: 2),
          ),
        );
        return;
      }
      HapticFeedback.selectionClick();
      setState(() {
        if (_selectedAjuanIds.contains(id)) {
          _selectedAjuanIds.remove(id);
        } else {
          _selectedAjuanIds.add(id);
        }
      });
    } else {
      defaultAction();
    }
  }

  void _handleAjuanLongPress(String id) {
    final isSubmissionActive =
        context.read<AvailabilityViewModel>().isSubmissionActive;
    final role = context.read<AuthViewModel>().currentUser?.role ?? 'dosen';
    if (!isSubmissionActive && role == 'dosen') {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Window pengajuan sedang dikunci oleh Admin.'),
          duration: Duration(seconds: 2),
        ),
      );
      return;
    }
    HapticFeedback.heavyImpact();
    setState(() {
      _selectedAjuanIds.add(id);
    });
  }

  void _confirmDeleteSelectedAjuan(BuildContext context) {
    final count = _selectedAjuanIds.length;
    showModalBottomSheet(
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
                  child: const Icon(Icons.delete_outline_rounded, color: AppColors.error, size: 24),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Hapus $count Ajuan Terpilih?',
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF0F172A),
                        ),
                      ),
                      const SizedBox(height: 2),
                      const Text(
                        'Tindakan ini akan menghapus data permanen',
                        style: TextStyle(fontSize: 11.5, color: Color(0xFF64748B)),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Text(
              'Apakah Anda yakin ingin menghapus $count data pengajuan dosen yang dipilih secara permanen?',
              style: const TextStyle(fontSize: 13, color: Color(0xFF334155), height: 1.4),
            ),
            const SizedBox(height: 20),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      side: const BorderSide(color: Color(0xFFCBD5E1)),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                    ),
                    onPressed: () => Navigator.pop(ctx),
                    child: const Text('Batal', style: TextStyle(color: Color(0xFF475569), fontWeight: FontWeight.w600, fontSize: 13)),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.error,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                      elevation: 0,
                    ),
                    onPressed: () async {
                      final idsToDelete = _selectedAjuanIds.toList();
                      final messenger = ScaffoldMessenger.of(context);
                      final api = context.read<ApiService>();
                      Navigator.pop(ctx);
                      await api.deleteMultipleAjuanPengajaran(idsToDelete);
                      setState(() {
                        _selectedAjuanIds.clear();
                      });
                      await _loadAjuanData();
                      if (context.mounted) {
                        messenger.showSnackBar(
                          SnackBar(
                            content: Text('$count data pengajuan berhasil dihapus!'),
                            backgroundColor: AppColors.primaryDark,
                          ),
                        );
                      }
                    },
                    child: const Text('Hapus Masal', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  PreferredSizeWidget? _buildAjuanSelectionAppBar(BuildContext context) {
    if (!_isAjuanSelectionMode) return null;

    return AppBar(
      backgroundColor: AppColors.primary,
      foregroundColor: Colors.white,
      elevation: 2,
      leading: IconButton(
        icon: const Icon(Icons.close_rounded, color: Colors.white),
        tooltip: 'Batal Seleksi',
        onPressed: () => setState(() => _selectedAjuanIds.clear()),
      ),
      title: Text(
        '${_selectedAjuanIds.length} Dipilih',
        style: const TextStyle(
          color: Colors.white,
          fontSize: 16,
          fontWeight: FontWeight.bold,
        ),
      ),
      actions: [
        IconButton(
          icon: Icon(
            _selectedAjuanIds.length == _liveAjuanList.length &&
                    _liveAjuanList.isNotEmpty
                ? Icons.deselect_rounded
                : Icons.select_all_rounded,
            color: Colors.white,
          ),
          tooltip: _selectedAjuanIds.length == _liveAjuanList.length
              ? 'Batal Pilih Semua'
              : 'Pilih Semua',
          onPressed: () {
            setState(() {
              if (_selectedAjuanIds.length == _liveAjuanList.length) {
                _selectedAjuanIds.clear();
              } else {
                _selectedAjuanIds.addAll(_liveAjuanList.map((a) => a.id));
              }
            });
          },
        ),
        IconButton(
          icon: const Icon(Icons.delete_outline_rounded, color: Colors.white),
          tooltip: 'Hapus Masal',
          onPressed: () => _confirmDeleteSelectedAjuan(context),
        ),
        const SizedBox(width: 4),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final viewModel = context.watch<AvailabilityViewModel>();
    final user = context.watch<AuthViewModel>().currentUser;

    if (viewModel.isLoading) {
      return const Scaffold(
        backgroundColor: Colors.white,
        body: Center(
          child: CircularProgressIndicator(
            color: AppColors.primary,
            strokeWidth: 3.2,
          ),
        ),
      );
    }

    if (user?.role == 'admin') {
      return Scaffold(
        backgroundColor: Colors.transparent,
        appBar: _buildAjuanSelectionAppBar(context),
        body: AdminAvailabilityTab(
          liveAjuanList: _liveAjuanList,
          isLoadingAjuan: _isLoadingAjuan,
          onRefresh: _loadAjuanData,
          ruanganList: _dynamicRuanganList,
          selectedAjuanIds: _selectedAjuanIds,
          onAjuanTap: _handleAjuanTap,
          onAjuanLongPress: _handleAjuanLongPress,
        ),
      );
    } else if (user?.role == 'kajur') {
      return Scaffold(
        backgroundColor: Colors.transparent,
        appBar: _buildAjuanSelectionAppBar(context),
        body: KaProdiAvailabilityTab(
          liveAjuanList: _liveAjuanList,
          isLoadingAjuan: _isLoadingAjuan,
          onRefresh: _loadAjuanData,
          ruanganList: _dynamicRuanganList,
          selectedAjuanIds: _selectedAjuanIds,
          onAjuanTap: _handleAjuanTap,
          onAjuanLongPress: _handleAjuanLongPress,
        ),
      );
    } else if (user?.role == 'dekan') {
      return Scaffold(
        backgroundColor: Colors.transparent,
        appBar: _buildAjuanSelectionAppBar(context),
        body: DekanAvailabilityTab(
          liveAjuanList: _liveAjuanList,
          isLoadingAjuan: _isLoadingAjuan,
          onRefresh: _loadAjuanData,
          ruanganList: _dynamicRuanganList,
          selectedAjuanIds: _selectedAjuanIds,
          onAjuanTap: _handleAjuanTap,
          onAjuanLongPress: _handleAjuanLongPress,
        ),
      );
    }

    // Default: Dosen Matrix & Ajuan
    return Scaffold(
      backgroundColor: Colors.transparent,
      appBar: _buildAjuanSelectionAppBar(context),
      body: Column(
        children: [
          // Segmented Sub-Tab Switcher Dosen
          Container(
            margin: const EdgeInsets.fromLTRB(16, 12, 16, 8),
            decoration: BoxDecoration(
              color: const Color(0xFFF1F5F9),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: const Color(0xFFE2E8F0)),
            ),
            padding: const EdgeInsets.all(4),
            child: Row(
              children: [
                Expanded(
                  child: GestureDetector(
                    onTap: () => setState(() => _dosenSelectedSubTab = 0),
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        vertical: 11,
                        horizontal: 6,
                      ),
                      decoration: BoxDecoration(
                        color: _dosenSelectedSubTab == 0
                            ? Colors.white
                            : Colors.transparent,
                        borderRadius: BorderRadius.circular(9),
                        boxShadow: _dosenSelectedSubTab == 0
                            ? [
                                BoxShadow(
                                  color: Colors.black.withValues(alpha: 0.06),
                                  blurRadius: 4,
                                  offset: const Offset(0, 1),
                                ),
                              ]
                            : null,
                      ),
                      alignment: Alignment.center,
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.grid_view_rounded,
                            size: 17,
                            color: _dosenSelectedSubTab == 0
                                ? AppColors.primary
                                : const Color(0xFF64748B),
                          ),
                          const SizedBox(width: 7),
                          Flexible(
                            child: Text(
                              'Matriks Waktu',
                              style: TextStyle(
                                fontSize: 13,
                                fontWeight: _dosenSelectedSubTab == 0
                                    ? FontWeight.bold
                                    : FontWeight.w600,
                                color: _dosenSelectedSubTab == 0
                                    ? AppColors.primary
                                    : const Color(0xFF64748B),
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
                Expanded(
                  child: GestureDetector(
                    onTap: () => setState(() => _dosenSelectedSubTab = 1),
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        vertical: 11,
                        horizontal: 6,
                      ),
                      decoration: BoxDecoration(
                        color: _dosenSelectedSubTab == 1
                            ? Colors.white
                            : Colors.transparent,
                        borderRadius: BorderRadius.circular(9),
                        boxShadow: _dosenSelectedSubTab == 1
                            ? [
                                BoxShadow(
                                  color: Colors.black.withValues(alpha: 0.06),
                                  blurRadius: 4,
                                  offset: const Offset(0, 1),
                                ),
                              ]
                            : null,
                      ),
                      alignment: Alignment.center,
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.post_add_rounded,
                            size: 18,
                            color: _dosenSelectedSubTab == 1
                                ? AppColors.primary
                                : const Color(0xFF64748B),
                          ),
                          const SizedBox(width: 7),
                          Flexible(
                            child: Text(
                              'Ajuan Saya',
                              style: TextStyle(
                                fontSize: 13,
                                fontWeight: _dosenSelectedSubTab == 1
                                    ? FontWeight.bold
                                    : FontWeight.w600,
                                color: _dosenSelectedSubTab == 1
                                    ? AppColors.primary
                                    : const Color(0xFF64748B),
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),

          // Sub-Tab Content
          Expanded(
            child: _dosenSelectedSubTab == 1
                ? DosenAjuanTab(
                    liveAjuanList: _liveAjuanList,
                    isLoadingAjuan: _isLoadingAjuan,
                    onRefresh: _loadAjuanData,
                    selectedAjuanIds: _selectedAjuanIds,
                    onAjuanTap: _handleAjuanTap,
                    onAjuanLongPress: _handleAjuanLongPress,
                  )
                : const DosenMatrixTab(),
          ),
        ],
      ),
    );
  }
}
