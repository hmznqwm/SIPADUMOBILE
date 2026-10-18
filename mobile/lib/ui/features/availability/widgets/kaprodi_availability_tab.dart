// File: kaprodi_availability_tab.dart
// Deskripsi: Widget panel manajemen ketersediaan ruangan dan persetujuan ajuan dosen untuk KaProdi (Level 1 Approval).
// Fungsi: Menampilkan sub-tab ruangan kosong dan pengajuan dosen prodi, filter status, pencarian, serta aksi persetujuan/pengembalian.

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../../config/constants.dart';
import '../../../../data/models/ajuan_pengajaran_model.dart';
import '../../../../data/services/api_service.dart';
import '../../../core/widgets/wave_header_card.dart';
import '../../auth/view_models/auth_view_model.dart';
import 'cards/kajur_ajuan_card.dart';
import 'dialogs/kajur_filter_bottom_sheet.dart';
import 'ruangan_kosong_section.dart';

class KaProdiAvailabilityTab extends StatefulWidget {
  final List<AjuanPengajaranModel> liveAjuanList;
  final bool isLoadingAjuan;
  final Future<void> Function() onRefresh;
  final List<Map<String, dynamic>> ruanganList;
  final Set<String> selectedAjuanIds;
  final Function(String id, VoidCallback defaultAction) onAjuanTap;
  final Function(String id) onAjuanLongPress;

  const KaProdiAvailabilityTab({
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
  State<KaProdiAvailabilityTab> createState() => _KaProdiAvailabilityTabState();
}

class _KaProdiAvailabilityTabState extends State<KaProdiAvailabilityTab> {
  int _kajurSelectedSubTab = 0; // 0: Ruangan Kosong, 1: Pengajuan Dosen
  int _displayedCount = 10;
  String _kajurStatusFilter = 'Semua';
  String _kajurSearchQuery = '';
  final TextEditingController _kajurSearchController = TextEditingController();

  @override
  void dispose() {
    _kajurSearchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final api = context.read<ApiService>();
    final user = context.read<AuthViewModel>().currentUser;
    final String jurusanNama = (user != null && user.jurusanNama.isNotEmpty)
        ? user.jurusanNama
        : '';

    // Ajuan di lingkungan Program Studi KaProdi
    final prodiAjuanList = widget.liveAjuanList
        .where((a) => jurusanNama.isEmpty || a.jurusanNama.toLowerCase() == jurusanNama.toLowerCase())
        .toList();

    // Filter pengajuan dosen berdasarkan Status dan Search Query
    final filteredAjuan = prodiAjuanList.where((a) {
      bool matchStatus = true;
      if (_kajurStatusFilter != 'Semua') {
        if (_kajurStatusFilter == 'Menunggu KaProdi') {
          matchStatus =
              a.status == 'menunggu_kaprodi' ||
              a.status == 'menunggu_verifikasi';
        } else if (_kajurStatusFilter == 'Disetujui KaProdi') {
          matchStatus = a.status == 'menunggu_dekan';
        } else if (_kajurStatusFilter == 'Disetujui Dekan') {
          matchStatus = a.status == 'menunggu_admin';
        } else if (_kajurStatusFilter == 'Final Admin') {
          matchStatus = a.status == 'disetujui_admin';
        } else if (_kajurStatusFilter == 'Ditolak') {
          matchStatus =
              a.status.startsWith('ditolak') || a.status == 'banding_ditolak';
        }
      }

      final q = _kajurSearchQuery.trim().toLowerCase();
      final matchQuery =
          q.isEmpty ||
          a.dosenNama.toLowerCase().contains(q) ||
          a.mataKuliahNama.toLowerCase().contains(q) ||
          a.ruanganNama.toLowerCase().contains(q) ||
          a.gedungNama.toLowerCase().contains(q);

      return matchStatus && matchQuery;
    }).toList();

    // Grouping ajuan per dosen & per jurusan untuk nested slide card
    final Map<String, List<AjuanPengajaranModel>> kajurGroupedMap = {};
    for (final aj in filteredAjuan) {
      final key =
          '${aj.dosenId.isNotEmpty ? aj.dosenId : aj.dosenNama}_${aj.jurusanNama}';
      kajurGroupedMap.putIfAbsent(key, () => []).add(aj);
    }
    final groupedAjuan = kajurGroupedMap.values.toList();

    return RefreshIndicator(
      onRefresh: widget.onRefresh,
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header Panel Persetujuan KaProdi (Split Wave 2-Warna)
            WaveHeaderCard(
              title: 'Manajemen Ruangan & Usulan $jurusanNama',
              subtitle: 'Kelola ketersediaan ruangan dan verifikasi usulan jadwal dosen $jurusanNama.',
            ),
            const SizedBox(height: 14),

            // Segmented Navigation Sub-Tab (Ruangan Kosong vs Pengajuan Dosen)
            Container(
              padding: const EdgeInsets.all(4),
              decoration: BoxDecoration(
                color: const Color(0xFFF1F5F9),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: const Color(0xFFE2E8F0)),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: InkWell(
                      onTap: () => setState(() => _kajurSelectedSubTab = 0),
                      borderRadius: BorderRadius.circular(10),
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          vertical: 12,
                          horizontal: 8,
                        ),
                        alignment: Alignment.center,
                        decoration: BoxDecoration(
                          color: _kajurSelectedSubTab == 0
                              ? AppColors.primary
                              : Colors.transparent,
                          borderRadius: BorderRadius.circular(10),
                          boxShadow: _kajurSelectedSubTab == 0
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
                            color: _kajurSelectedSubTab == 0
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
                      onTap: () => setState(() => _kajurSelectedSubTab = 1),
                      borderRadius: BorderRadius.circular(10),
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          vertical: 12,
                          horizontal: 8,
                        ),
                        alignment: Alignment.center,
                        decoration: BoxDecoration(
                          color: _kajurSelectedSubTab == 1
                              ? AppColors.primary
                              : Colors.transparent,
                          borderRadius: BorderRadius.circular(10),
                          boxShadow: _kajurSelectedSubTab == 1
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
                            color: _kajurSelectedSubTab == 1
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
            const SizedBox(height: 14),

            // SUB-TAB 0: DAFTAR RUANGAN KOSONG & GEDUNG
            if (_kajurSelectedSubTab == 0)
              RuanganKosongSection(
                ruanganList: widget.ruanganList,
              ),

            // SUB-TAB 1: PENGAJUAN KETERSEDIAAN DOSEN PRODI
            if (_kajurSelectedSubTab == 1) ...[
              // Search & Filter Bar
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: const Color(0xFFE2E8F0)),
                ),
                child: Row(
                children: [
                  Expanded(
                    child: Container(
                      height: 40,
                      decoration: BoxDecoration(
                        color: const Color(0xFFF8FAFC),
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(color: const Color(0xFFCBD5E1)),
                      ),
                      child: TextField(
                        controller: _kajurSearchController,
                        onChanged: (val) {
                          setState(() {
                            _kajurSearchQuery = val.trim();
                          });
                        },
                        style: const TextStyle(
                          fontSize: 12,
                          color: Color(0xFF0F172A),
                          fontWeight: FontWeight.w500,
                        ),
                        decoration: InputDecoration(
                          isDense: true,
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
                          prefixIconConstraints: const BoxConstraints(
                            minWidth: 32,
                            minHeight: 32,
                          ),
                          suffixIcon: _kajurSearchQuery.isNotEmpty
                              ? IconButton(
                                  icon: const Icon(
                                    Icons.clear_rounded,
                                    size: 15,
                                    color: Color(0xFF64748B),
                                  ),
                                  onPressed: () {
                                    _kajurSearchController.clear();
                                    setState(() => _kajurSearchQuery = '');
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
                      final bool hasActiveFilter = _kajurStatusFilter != 'Semua';

                      return InkWell(
                        onTap: () => showKajurFilterBottomSheet(
                          context: context,
                          currentStatus: _kajurStatusFilter,
                          onApply: (status) {
                            setState(() {
                              _kajurStatusFilter = status;
                            });
                          },
                        ),
                        borderRadius: BorderRadius.circular(10),
                        child: Container(
                          height: 40,
                          padding: const EdgeInsets.symmetric(horizontal: 12),
                          decoration: BoxDecoration(
                            color: hasActiveFilter
                                ? AppColors.primary.withValues(alpha: 0.08)
                                : const Color(0xFFF8FAFC),
                            borderRadius: BorderRadius.circular(10),
                            border: Border.all(
                              color: hasActiveFilter
                                  ? AppColors.primary
                                  : const Color(0xFFCBD5E1),
                              width: hasActiveFilter ? 1.4 : 1.0,
                            ),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                Icons.tune_rounded,
                                size: 18,
                                color: hasActiveFilter
                                    ? AppColors.primary
                                    : const Color(0xFF64748B),
                              ),
                              const SizedBox(width: 6),
                              Text(
                                'Filter',
                                style: TextStyle(
                                  fontSize: 12,
                                  fontWeight: hasActiveFilter
                                      ? FontWeight.bold
                                      : FontWeight.w500,
                                  color: hasActiveFilter
                                      ? AppColors.primary
                                      : const Color(0xFF475569),
                                ),
                              ),
                              if (hasActiveFilter) ...[
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
                                  child: const Text(
                                    '1',
                                    style: TextStyle(
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
                      'Menampilkan ${filteredAjuan.length} dari ${prodiAjuanList.length} ajuan $jurusanNama',
                      style: const TextStyle(
                        fontSize: 11,
                        color: Color(0xFF64748B),
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    if (_kajurSearchQuery.isNotEmpty ||
                        _kajurStatusFilter != 'Semua')
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
                        'Coba ubah kata kunci pencarian atau reset filter status.',
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
                    return KajurAjuanCard(
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
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }
}
