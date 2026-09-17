// File: dekan_availability_tab.dart
// Deskripsi: Widget panel manajemen ketersediaan ruangan dan persetujuan ajuan dosen FST untuk Dekan (Level 2 Approval).
// Fungsi: Menampilkan sub-tab ruangan kosong dan pengajuan dosen FST, filter prodi & status, pencarian, serta aksi persetujuan/pengembalian.

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../../config/constants.dart';
import '../../../../data/models/ajuan_pengajaran_model.dart';
import '../../../../data/services/api_service.dart';
import '../view_models/availability_view_model.dart';
import 'cards/dekan_ajuan_card.dart';
import 'dialogs/dekan_filter_bottom_sheet.dart';
import 'ruangan_kosong_section.dart';

class DekanAvailabilityTab extends StatefulWidget {
  final List<AjuanPengajaranModel> liveAjuanList;
  final bool isLoadingAjuan;
  final Future<void> Function() onRefresh;
  final List<Map<String, dynamic>> ruanganList;
  final Set<String> selectedAjuanIds;
  final Function(String id, VoidCallback defaultAction) onAjuanTap;
  final Function(String id) onAjuanLongPress;

  const DekanAvailabilityTab({
    super.key,
    required this.liveAjuanList,
    required this.isLoadingAjuan,
    required this.onRefresh,
    required this.ruanganList,
    required this.selectedAjuanIds,
    required this.onAjuanTap,
    required this.onAjuanLongPress,
  });

  @override
  State<DekanAvailabilityTab> createState() => _DekanAvailabilityTabState();
}

class _DekanAvailabilityTabState extends State<DekanAvailabilityTab> {
  int _dekanSelectedSubTab = 0; // 0: Ruangan Kosong, 1: Pengajuan Dosen
  String _dekanStatusFilter = 'Semua';
  String _dekanProdiFilter = 'Semua';
  String _dekanSearchQuery = '';
  final TextEditingController _dekanSearchController = TextEditingController();

  @override
  void dispose() {
    _dekanSearchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final api = context.read<ApiService>();
    final viewModel = context.watch<AvailabilityViewModel>();
    final isSubmissionActive = viewModel.isSubmissionActive;
    const String fakultasNama = 'Fakultas Sains & Teknologi';

    // Ajuan di lingkungan Fakultas FST
    final fstAjuanList = widget.liveAjuanList
        .where((a) => a.fakultasNama == fakultasNama)
        .toList();

    // List prodi yang tersedia di FST
    final availableProdis = [
      'Semua',
      ...fstAjuanList
          .map((d) => d.jurusanNama)
          .where((j) => j.isNotEmpty)
          .toSet(),
    ];

    // Filter pengajuan dosen berdasarkan Status, Prodi, dan Search Query
    final filteredAjuan = fstAjuanList.where((a) {
      bool matchStatus = true;
      if (_dekanStatusFilter != 'Semua') {
        if (_dekanStatusFilter == 'Menunggu Dekan') {
          matchStatus = a.status == 'menunggu_dekan';
        } else if (_dekanStatusFilter == 'Disetujui Dekan') {
          matchStatus =
              a.status == 'menunggu_admin' || a.status == 'disetujui_admin';
        } else if (_dekanStatusFilter == 'Final Admin') {
          matchStatus = a.status == 'disetujui_admin';
        } else if (_dekanStatusFilter == 'Ditolak') {
          matchStatus =
              a.status.startsWith('ditolak') || a.status == 'banding_ditolak';
        }
      }

      final matchProdi =
          _dekanProdiFilter == 'Semua' || a.jurusanNama == _dekanProdiFilter;
      final q = _dekanSearchQuery.trim().toLowerCase();
      final matchQuery =
          q.isEmpty ||
          a.dosenNama.toLowerCase().contains(q) ||
          a.mataKuliahNama.toLowerCase().contains(q) ||
          a.jurusanNama.toLowerCase().contains(q) ||
          a.ruanganNama.toLowerCase().contains(q) ||
          a.gedungNama.toLowerCase().contains(q);

      return matchStatus && matchProdi && matchQuery;
    }).toList();

    return RefreshIndicator(
      onRefresh: widget.onRefresh,
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.fromLTRB(
          AppSpacing.md,
          AppSpacing.md,
          AppSpacing.md,
          90,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ── Header Panel Persetujuan Dekan FST ──
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(AppSpacing.lg),
              decoration: BoxDecoration(
                color: AppColors.surfaceVariant,
                borderRadius: BorderRadius.circular(AppRadius.lg),
                border: Border.all(
                  color: AppColors.primary.withValues(alpha: 0.25),
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Wrap(
                    alignment: WrapAlignment.spaceBetween,
                    crossAxisAlignment: WrapCrossAlignment.center,
                    spacing: 8,
                    runSpacing: 6,
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: AppColors.primary,
                          borderRadius: BorderRadius.circular(AppRadius.full),
                        ),
                        child: const Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              Icons.meeting_room_outlined,
                              color: Colors.white,
                              size: 12,
                            ),
                            SizedBox(width: 4),
                            Text(
                              'RUANG & AJUAN FST',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 10,
                                fontWeight: FontWeight.bold,
                                letterSpacing: 0.6,
                              ),
                            ),
                          ],
                        ),
                      ),
                      InkWell(
                        onTap: () async {
                          final newStatus = !isSubmissionActive;
                          await api.setSubmissionWindowStatus(newStatus);
                          await viewModel.loadAvailabilityData();
                          if (context.mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text(
                                  newStatus
                                      ? 'Window Ketersediaan berhasil DIBUKA.'
                                      : 'Window Ketersediaan berhasil DIKUNCI.',
                                ),
                                backgroundColor: newStatus
                                    ? AppColors.primaryDark
                                    : AppColors.error,
                                behavior: SnackBarBehavior.floating,
                              ),
                            );
                          }
                        },
                        borderRadius: BorderRadius.circular(AppRadius.sm),
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 3.5,
                          ),
                          decoration: BoxDecoration(
                            color: isSubmissionActive
                                ? const Color(0xFFECFDF5)
                                : const Color(0xFFFEF2F2),
                            borderRadius: BorderRadius.circular(AppRadius.sm),
                            border: Border.all(
                              color: isSubmissionActive
                                  ? const Color(0xFFA7F3D0)
                                  : const Color(0xFFFECACA),
                            ),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                isSubmissionActive
                                    ? Icons.lock_open_rounded
                                    : Icons.lock_rounded,
                                size: 12,
                                color: isSubmissionActive
                                    ? const Color(0xFF047857)
                                    : const Color(0xFFDC2626),
                              ),
                              const SizedBox(width: 4),
                              Text(
                                isSubmissionActive
                                    ? 'Window Open'
                                    : 'Window Lock',
                                style: TextStyle(
                                  color: isSubmissionActive
                                      ? const Color(0xFF047857)
                                      : const Color(0xFFDC2626),
                                  fontSize: 10.5,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  const Text(
                    'Manajemen Ruangan & Usulan FST',
                    style: TextStyle(
                      color: AppColors.textPrimary,
                      fontSize: 17,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 3),
                  const Text(
                    'Kelola ketersediaan ruangan dan verifikasi usulan jadwal dosen FST.',
                    style: TextStyle(
                      color: AppColors.textSecondary,
                      fontSize: 11.5,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: AppSpacing.md),

            // ── Segmented Navigation Sub-Tab (Ruangan Kosong vs Pengajuan Dosen) ──
            Container(
              padding: const EdgeInsets.all(4),
              decoration: BoxDecoration(
                color: const Color(0xFFF1F5F9),
                borderRadius: BorderRadius.circular(AppRadius.md),
                border: Border.all(color: const Color(0xFFE2E8F0)),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: InkWell(
                      onTap: () => setState(() => _dekanSelectedSubTab = 0),
                      borderRadius: BorderRadius.circular(10),
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          vertical: 12,
                          horizontal: 8,
                        ),
                        alignment: Alignment.center,
                        decoration: BoxDecoration(
                          color: _dekanSelectedSubTab == 0
                              ? AppColors.primary
                              : Colors.transparent,
                          borderRadius: BorderRadius.circular(10),
                          boxShadow: _dekanSelectedSubTab == 0
                              ? [
                                  BoxShadow(
                                    color: AppColors.primary.withValues(
                                      alpha: 0.25,
                                    ),
                                    blurRadius: 6,
                                    offset: const Offset(0, 2),
                                  ),
                                ]
                              : null,
                        ),
                        child: Text(
                          'Ruangan Kosong',
                          style: TextStyle(
                            fontSize: 13.5,
                            fontWeight: FontWeight.bold,
                            color: _dekanSelectedSubTab == 0
                                ? Colors.white
                                : const Color(0xFF64748B),
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ),
                  ),
                  Expanded(
                    child: InkWell(
                      onTap: () => setState(() => _dekanSelectedSubTab = 1),
                      borderRadius: BorderRadius.circular(10),
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          vertical: 12,
                          horizontal: 8,
                        ),
                        alignment: Alignment.center,
                        decoration: BoxDecoration(
                          color: _dekanSelectedSubTab == 1
                              ? AppColors.primary
                              : Colors.transparent,
                          borderRadius: BorderRadius.circular(10),
                          boxShadow: _dekanSelectedSubTab == 1
                              ? [
                                  BoxShadow(
                                    color: AppColors.primary.withValues(
                                      alpha: 0.25,
                                    ),
                                    blurRadius: 6,
                                    offset: const Offset(0, 2),
                                  ),
                                ]
                              : null,
                        ),
                        child: Text(
                          'Pengajuan Dosen',
                          style: TextStyle(
                            fontSize: 13.5,
                            fontWeight: FontWeight.bold,
                            color: _dekanSelectedSubTab == 1
                                ? Colors.white
                                : const Color(0xFF64748B),
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: AppSpacing.md),

            // ── SUB-TAB 0: DAFTAR RUANGAN KOSONG & GEDUNG ──
            if (_dekanSelectedSubTab == 0)
              RuanganKosongSection(
                title: 'Status Ketersediaan Ruangan Kampus',
                subtitle:
                    'Data ruangan yang siap digunakan di tingkat fakultas.',
                ruanganList: widget.ruanganList,
              ),

            // ── SUB-TAB 1: PENGAJUAN KETERSEDIAAN DOSEN FST ──
            if (_dekanSelectedSubTab == 1) ...[
              // ── Search & Filter Bar ──
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: const Color(0xFFE2E8F0)),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Search Input
                    TextField(
                      controller: _dekanSearchController,
                      onChanged: (val) {
                        setState(() {
                          _dekanSearchQuery = val.trim();
                        });
                      },
                      decoration: InputDecoration(
                        hintText: 'Cari dosen, matkul, ruang...',
                        hintStyle: const TextStyle(
                          fontSize: 11.5,
                          color: Color(0xFF94A3B8),
                        ),
                        prefixIcon: const Icon(
                          Icons.search_rounded,
                          size: 17,
                          color: AppColors.primary,
                        ),
                        suffixIcon: _dekanSearchQuery.isNotEmpty
                            ? IconButton(
                                icon: const Icon(
                                  Icons.clear_rounded,
                                  size: 15,
                                  color: Color(0xFF64748B),
                                ),
                                onPressed: () {
                                  _dekanSearchController.clear();
                                  setState(() => _dekanSearchQuery = '');
                                },
                              )
                            : null,
                        filled: true,
                        fillColor: const Color(0xFFF8FAFC),
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 7,
                        ),
                        isDense: true,
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                          borderSide: const BorderSide(
                            color: Color(0xFFE2E8F0),
                          ),
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                          borderSide: const BorderSide(
                            color: Color(0xFFE2E8F0),
                          ),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                          borderSide: const BorderSide(
                            color: AppColors.primary,
                            width: 1.2,
                          ),
                        ),
                      ),
                      style: const TextStyle(
                        fontSize: 12,
                        color: AppColors.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 8),

                    // 2. Button Filter Full-Width (Buka Modal Bottom Sheet dari bawah)
                    Builder(
                      builder: (context) {
                        int activeFilterCount = 0;
                        if (_dekanProdiFilter != 'Semua') activeFilterCount++;
                        if (_dekanStatusFilter != 'Semua') activeFilterCount++;

                        return InkWell(
                          onTap: () {
                            showDekanFilterBottomSheet(
                              context: context,
                              availableProdis: availableProdis,
                              currentProdi: _dekanProdiFilter,
                              currentStatus: _dekanStatusFilter,
                              onApply: (prodi, status) {
                                setState(() {
                                  _dekanProdiFilter = prodi;
                                  _dekanStatusFilter = status;
                                });
                              },
                            );
                          },
                          borderRadius: BorderRadius.circular(10),
                          child: Container(
                            height: 40,
                            width: double.infinity,
                            padding: const EdgeInsets.symmetric(horizontal: 12),
                            decoration: BoxDecoration(
                              color: activeFilterCount > 0
                                  ? AppColors.primary.withValues(alpha: 0.08)
                                  : const Color(0xFFF8FAFC),
                              borderRadius: BorderRadius.circular(10),
                              border: Border.all(
                                color: activeFilterCount > 0
                                    ? AppColors.primary
                                    : const Color(0xFFCBD5E1),
                                width: activeFilterCount > 0 ? 1.4 : 1.0,
                              ),
                            ),
                            child: Row(
                              children: [
                                Icon(
                                  Icons.tune_rounded,
                                  size: 18,
                                  color: activeFilterCount > 0
                                      ? AppColors.primary
                                      : const Color(0xFF64748B),
                                ),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: Text(
                                    activeFilterCount > 0
                                        ? 'Filter (${_dekanProdiFilter != 'Semua' ? _dekanProdiFilter : ''}${_dekanStatusFilter != 'Semua' ? ', $_dekanStatusFilter' : ''})'
                                        : 'Filter Prodi & Status Ajuan',
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: TextStyle(
                                      fontSize: 12,
                                      fontWeight: activeFilterCount > 0
                                          ? FontWeight.bold
                                          : FontWeight.w500,
                                      color: activeFilterCount > 0
                                          ? AppColors.primary
                                          : const Color(0xFF475569),
                                    ),
                                  ),
                                ),
                                if (activeFilterCount > 0) ...[
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 6,
                                      vertical: 2,
                                    ),
                                    decoration: BoxDecoration(
                                      color: AppColors.primary,
                                      borderRadius: BorderRadius.circular(10),
                                    ),
                                    child: Text(
                                      '$activeFilterCount',
                                      style: const TextStyle(
                                        color: Colors.white,
                                        fontSize: 10,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ),
                                  const SizedBox(width: 6),
                                ],
                                Icon(
                                  Icons.keyboard_arrow_down_rounded,
                                  size: 20,
                                  color: activeFilterCount > 0
                                      ? AppColors.primary
                                      : const Color(0xFF64748B),
                                ),
                              ],
                            ),
                          ),
                        );
                      },
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 10),

              // Info Count Row
              Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 2,
                  vertical: 2,
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Menampilkan ${filteredAjuan.length} dari ${fstAjuanList.length} ajuan FST',
                      style: const TextStyle(
                        fontSize: 11,
                        color: Color(0xFF64748B),
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    if (_dekanSearchQuery.isNotEmpty ||
                        _dekanProdiFilter != 'Semua' ||
                        _dekanStatusFilter != 'Semua')
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 6,
                          vertical: 2,
                        ),
                        decoration: BoxDecoration(
                          color: AppColors.primary.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: const Text(
                          'Filter Aktif',
                          style: TextStyle(
                            fontSize: 9.5,
                            fontWeight: FontWeight.bold,
                            color: AppColors.primary,
                          ),
                        ),
                      ),
                  ],
                ),
              ),
              const SizedBox(height: 6),

              if (widget.isLoadingAjuan)
                const Padding(
                  padding: EdgeInsets.symmetric(vertical: 30),
                  child: Center(
                    child: CircularProgressIndicator(
                      color: AppColors.primary,
                      strokeWidth: 3.2,
                    ),
                  ),
                )
              else if (filteredAjuan.isEmpty)
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(
                    vertical: 36,
                    horizontal: 16,
                  ),
                  margin: const EdgeInsets.only(top: 8),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: const Color(0xFFE2E8F0)),
                  ),
                  child: Column(
                    children: [
                      Icon(
                        Icons.search_off_rounded,
                        size: 42,
                        color: Colors.grey.shade400,
                      ),
                      const SizedBox(height: 8),
                      const Text(
                        'Tidak ada ajuan yang sesuai',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 13,
                          color: Color(0xFF0F172A),
                        ),
                      ),
                      const SizedBox(height: 4),
                      const Text(
                        'Coba ubah kata kunci pencarian atau reset filter prodi / status.',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: 11,
                          color: Color(0xFF64748B),
                        ),
                      ),
                    ],
                  ),
                )
              else
                ListView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: filteredAjuan.length,
                  itemBuilder: (context, index) {
                    final aj = filteredAjuan[index];
                    return DekanAjuanCard(
                      aj: aj,
                      api: api,
                      selectedAjuanIds: widget.selectedAjuanIds,
                      onAjuanTap: widget.onAjuanTap,
                      onAjuanLongPress: widget.onAjuanLongPress,
                      onRefresh: widget.onRefresh,
                    );
                  },
                ),
            ],
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }
}
