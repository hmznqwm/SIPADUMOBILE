// File: admin_availability_tab.dart
// Deskripsi: Widget panel manajemen ketersediaan ruangan kampus dan verifikasi ajuan dosen untuk Administrator.
// Fungsi: Menampilkan sub-tab ruangan kosong dan pengajuan dosen, filter fakultas/prodi/status, search, dan persetujuan final.

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../../config/constants.dart';
import '../../../../data/models/ajuan_pengajaran_model.dart';
import '../../../../data/services/api_service.dart';
import '../../../core/widgets/wave_header_card.dart';
import 'cards/admin_ajuan_card.dart';
import 'dialogs/admin_filter_bottom_sheet.dart';
import 'ruangan_kosong_section.dart';

class AdminAvailabilityTab extends StatefulWidget {
  final List<AjuanPengajaranModel> liveAjuanList;
  final bool isLoadingAjuan;
  final Future<void> Function() onRefresh;
  final List<Map<String, dynamic>> ruanganList;
  final Set<String> selectedAjuanIds;
  final Function(String id, VoidCallback defaultAction) onAjuanTap;
  final Function(String id) onAjuanLongPress;

  const AdminAvailabilityTab({
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
  State<AdminAvailabilityTab> createState() => _AdminAvailabilityTabState();
}

class _AdminAvailabilityTabState extends State<AdminAvailabilityTab> {
  int _adminSelectedSubTab = 0; // 0: Ruangan Kampus, 1: Pengajuan Dosen
  int _displayedCount = 10;
  String _adminAjuanFilter = 'Semua';
  String _adminFakultasFilter = 'Semua';
  String _adminProdiFilter = 'Semua';
  String _adminSearchQuery = '';
  final TextEditingController _adminSearchController = TextEditingController();

  @override
  void dispose() {
    _adminSearchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final api = context.read<ApiService>();

    // List fakultas yang tersedia
    final availableFakultas = [
      'Semua',
      ...widget.liveAjuanList.map((d) => d.fakultasNama).toSet(),
    ];

    // Filter pengajuan dosen berdasarkan Status, Fakultas, Prodi, dan Search Query
    final filteredAjuan = widget.liveAjuanList.where((a) {
      bool matchStatus = true;
      if (_adminAjuanFilter != 'Semua') {
        if (_adminAjuanFilter == 'Diajukan') {
          matchStatus = a.status == 'menunggu_kaprodi';
        } else if (_adminAjuanFilter == 'Verifikasi KaProdi') {
          matchStatus = a.status == 'menunggu_dekan';
        } else if (_adminAjuanFilter == 'Disetujui Dekan') {
          matchStatus = a.status == 'menunggu_admin';
        } else if (_adminAjuanFilter == 'Disetujui Admin') {
          matchStatus =
              a.status == 'disetujui_admin' || a.status == 'banding_disetujui';
        } else if (_adminAjuanFilter == 'Banding') {
          matchStatus = a.status == 'menunggu_banding';
        } else if (_adminAjuanFilter == 'Bentrok') {
          matchStatus = a.status == 'bentrok_terdeteksi';
        } else if (_adminAjuanFilter == 'Ditolak') {
          matchStatus =
              a.status.startsWith('ditolak') || a.status == 'banding_ditolak';
        }
      }

      final matchFakultas =
          _adminFakultasFilter == 'Semua' ||
          a.fakultasNama == _adminFakultasFilter;
      final matchProdi =
          _adminProdiFilter == 'Semua' || a.jurusanNama == _adminProdiFilter;
      final q = _adminSearchQuery.trim().toLowerCase();
      final matchQuery =
          q.isEmpty ||
          a.dosenNama.toLowerCase().contains(q) ||
          a.mataKuliahNama.toLowerCase().contains(q) ||
          a.jurusanNama.toLowerCase().contains(q) ||
          a.fakultasNama.toLowerCase().contains(q) ||
          a.gedungNama.toLowerCase().contains(q) ||
          a.ruanganNama.toLowerCase().contains(q);
      return matchStatus && matchFakultas && matchProdi && matchQuery;
    }).toList();

    // Grouping ajuan per dosen & per jurusan untuk nested slide card
    final Map<String, List<AjuanPengajaranModel>> adminGroupedMap = {};
    for (final aj in filteredAjuan) {
      final key =
          '${aj.dosenId.isNotEmpty ? aj.dosenId : aj.dosenNama}_${aj.jurusanNama}';
      adminGroupedMap.putIfAbsent(key, () => []).add(aj);
    }
    final groupedAjuan = adminGroupedMap.values.toList();

    return RefreshIndicator(
      onRefresh: widget.onRefresh,
      color: AppColors.primary,
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.fromLTRB(
          AppSpacing.md,
          AppSpacing.md,
          AppSpacing.md,
          20,
        ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ── Header Panel Ruang & Ajuan Admin (Split Wave 2-Warna) ──
          const WaveHeaderCard(
            title: 'Manajemen Ruangan & Pengajuan Dosen',
            subtitle: 'Kelola ruangan dan verifikasi ajuan dosen.',
          ),
          const SizedBox(height: AppSpacing.md),

          // ── Segmented Navigation Sub-Tab (Ruangan Kampus vs Pengajuan Dosen) ──
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
                    onTap: () => setState(() => _adminSelectedSubTab = 0),
                    borderRadius: BorderRadius.circular(10),
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        vertical: 12,
                        horizontal: 8,
                      ),
                      alignment: Alignment.center,
                      decoration: BoxDecoration(
                        color: _adminSelectedSubTab == 0
                            ? AppColors.primary
                            : Colors.transparent,
                        borderRadius: BorderRadius.circular(10),
                        boxShadow: _adminSelectedSubTab == 0
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
                          color: _adminSelectedSubTab == 0
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
                    onTap: () => setState(() => _adminSelectedSubTab = 1),
                    borderRadius: BorderRadius.circular(10),
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        vertical: 12,
                        horizontal: 8,
                      ),
                      alignment: Alignment.center,
                      decoration: BoxDecoration(
                        color: _adminSelectedSubTab == 1
                            ? AppColors.primary
                            : Colors.transparent,
                        borderRadius: BorderRadius.circular(10),
                        boxShadow: _adminSelectedSubTab == 1
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
                          color: _adminSelectedSubTab == 1
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
          if (_adminSelectedSubTab == 0)
            RuanganKosongSection(
              ruanganList: widget.ruanganList,
            ),

          // ── SUB-TAB 1: PENGAJUAN KETERSEDIAAN DOSEN ──
          if (_adminSelectedSubTab == 1) ...[
            // ── Modern Compact Filter Container ──
            Container(
              margin: const EdgeInsets.only(bottom: 10),
              padding: const EdgeInsets.symmetric(
                horizontal: 12,
                vertical: 10,
              ),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: const Color(0xFFE2E8F0)),
                boxShadow: const [
                  BoxShadow(
                    color: Color(0x04000000),
                    blurRadius: 4,
                    offset: Offset(0, 2),
                  ),
                ],
              ),
              child: Row(
                children: [
                  // 1. Search Bar
                  Expanded(
                    child: Container(
                      height: 40,
                      decoration: BoxDecoration(
                        color: const Color(0xFFF8FAFC),
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(color: const Color(0xFFCBD5E1)),
                      ),
                      child: TextField(
                        controller: _adminSearchController,
                        onChanged: (val) =>
                            setState(() => _adminSearchQuery = val),
                        style: const TextStyle(
                          fontSize: 12,
                          color: Color(0xFF0F172A),
                          fontWeight: FontWeight.w500,
                        ),
                        decoration: InputDecoration(
                          isDense: true,
                          hintText:
                              'Cari dosen, matkul, prodi...',
                          hintStyle: const TextStyle(
                            fontSize: 11.5,
                            color: Color(0xFF94A3B8),
                          ),
                          prefixIcon: const Icon(
                            Icons.search_rounded,
                            color: AppColors.primary,
                            size: 17,
                          ),
                          prefixIconConstraints: const BoxConstraints(
                            minWidth: 32,
                            minHeight: 32,
                          ),
                          suffixIcon: _adminSearchQuery.isNotEmpty
                              ? IconButton(
                                  icon: const Icon(
                                    Icons.clear_rounded,
                                    size: 15,
                                    color: Color(0xFF94A3B8),
                                  ),
                                  onPressed: () {
                                    _adminSearchController.clear();
                                    setState(() => _adminSearchQuery = '');
                                  },
                                )
                              : null,
                          suffixIconConstraints: const BoxConstraints(
                            minWidth: 32,
                            minHeight: 32,
                          ),
                          border: InputBorder.none,
                          contentPadding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 9,
                          ),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),

                  // 2. Button Filter (Buka Modal Bottom Sheet)
                  Builder(
                    builder: (context) {
                      int activeFilterCount = 0;
                      if (_adminFakultasFilter != 'Semua') activeFilterCount++;
                      if (_adminProdiFilter != 'Semua') activeFilterCount++;
                      if (_adminAjuanFilter != 'Semua') activeFilterCount++;

                      return InkWell(
                        onTap: () => showAdminFilterBottomSheet(
                          context: context,
                          availableFakultas: availableFakultas,
                          liveAjuanList: widget.liveAjuanList,
                          currentFakultas: _adminFakultasFilter,
                          currentProdi: _adminProdiFilter,
                          currentStatus: _adminAjuanFilter,
                          onApply: (fakultas, prodi, status) {
                            setState(() {
                              _adminFakultasFilter = fakultas;
                              _adminProdiFilter = prodi;
                              _adminAjuanFilter = status;
                            });
                          },
                        ),
                        borderRadius: BorderRadius.circular(10),
                        child: Container(
                          height: 40,
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
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                Icons.tune_rounded,
                                size: 18,
                                color: activeFilterCount > 0
                                    ? AppColors.primary
                                    : const Color(0xFF64748B),
                              ),
                              const SizedBox(width: 6),
                              Text(
                                'Filter',
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
                              if (activeFilterCount > 0) ...[
                                const SizedBox(width: 6),
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
                              ],
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

            // ── Data Counter ──
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 2, vertical: 2),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Menampilkan ${filteredAjuan.length} dari ${widget.liveAjuanList.length} ajuan',
                    style: const TextStyle(
                      fontSize: 11,
                      color: Color(0xFF64748B),
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  if (_adminSearchQuery.isNotEmpty ||
                      _adminFakultasFilter != 'Semua' ||
                      _adminProdiFilter != 'Semua' ||
                      _adminAjuanFilter != 'Semua')
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
                      'Coba ubah kata kunci pencarian atau reset filter fakultas/prodi.',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 11,
                        color: Color(0xFF64748B),
                      ),
                    ),
                  ],
                ),
              )
            else ...[
              ListView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: groupedAjuan.length > _displayedCount
                    ? _displayedCount
                    : groupedAjuan.length,
                itemBuilder: (context, index) {
                  final group = groupedAjuan[index];
                  return AdminAjuanCard(
                    ajuanList: group,
                    api: api,
                    selectedAjuanIds: widget.selectedAjuanIds,
                    onAjuanTap: widget.onAjuanTap,
                    onAjuanLongPress: widget.onAjuanLongPress,
                    onRefresh: widget.onRefresh,
                  );
                },
              ),
              if (groupedAjuan.length > _displayedCount)
                Padding(
                  padding: const EdgeInsets.only(top: 10, bottom: 8),
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
        ],
      ),
    ),
  );
}
}
