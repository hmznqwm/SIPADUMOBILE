// File: conflict_resolution_center_screen.dart
// Deskripsi: Halaman khusus (Dedicated Studio) untuk Pusat Resolusi Konflik Jadwal Super Admin.
// Fitur: Pencarian Dosen/Matkul, Filter Kategori Bentrok, Multi-Selection, Before/After Diff Preview, dan Batch Auto-Resolve.

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../../config/constants.dart';
import '../../../../data/models/ajuan_pengajaran_model.dart';
import '../../../../data/services/api_service.dart';
import '../widgets/conflict_item_card.dart';
import '../widgets/conflict_resolution_diff_dialog.dart';
import '../widgets/conflict_resolution_empty_states.dart';

class ConflictResolutionCenterScreen extends StatefulWidget {
  const ConflictResolutionCenterScreen({super.key});

  @override
  State<ConflictResolutionCenterScreen> createState() => _ConflictResolutionCenterScreenState();
}

class _ConflictResolutionCenterScreenState extends State<ConflictResolutionCenterScreen> {
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';
  String _selectedCategory = 'all'; // 'all', 'ruang', 'dosen', 'buffer', 'kelas'
  String _selectedFakultas = 'Semua';
  final Set<String> _selectedIds = {};
  bool _isProcessing = false;

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  String _getCategory(AjuanPengajaranModel ajuan, [ApiService? api]) {
    if (api != null) {
      final conflictInfo = api.checkBuildingConflict(ajuan);
      if (conflictInfo['hasConflict'] == true && conflictInfo['conflictType'] != null) {
        return conflictInfo['conflictType'] as String;
      }
    }
    final detail = (ajuan.bentrokDetail ?? '').toLowerCase();
    if (detail.contains('ruang')) return 'ruang';
    if (detail.contains('gedung') || detail.contains('transit') || detail.contains('jeda') || detail.contains('buffer')) return 'buffer';
    if (detail.contains('kelas') || detail.contains('rombel') || detail.contains('mahasiswa')) return 'kelas';
    if (detail.contains('dosen') || detail.contains('pengampu')) return 'dosen';
    return 'ruang';
  }

  void _showDiffConfirmDialog({
    required BuildContext context,
    required List<AjuanPengajaranModel> items,
    required VoidCallback onResolved,
  }) {
    ConflictResolutionDiffDialog.show(
      context: context,
      items: items,
      onResolved: onResolved,
      onProcessingChanged: (val) {
        if (mounted) setState(() => _isProcessing = val);
      },
      onClearSelection: () {
        if (mounted) setState(() => _selectedIds.clear());
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final api = context.watch<ApiService>();

    return FutureBuilder<List<AjuanPengajaranModel>>(
      future: api.getAjuanPengajaranList(),
      builder: (context, snapshot) {
        final allAjuan = snapshot.data ?? [];
        final allConflicts = allAjuan.where((a) {
          if (a.status.startsWith('ditolak')) return false;
          final conflictInfo = api.checkBuildingConflict(a);
          if (conflictInfo['hasConflict'] == true) return true;
          if (a.status == 'disetujui_admin' || a.status == 'banding_disetujui') return false;
          return a.status == 'bentrok_terdeteksi' ||
              a.status == 'menunggu_banding' ||
              (a.bentrokDetail != null && a.bentrokDetail!.isNotEmpty);
        }).toList();

        // Counter per kategori
        final ruangCount = allConflicts.where((a) => _getCategory(a, api) == 'ruang').length;
        final dosenCount = allConflicts.where((a) => _getCategory(a, api) == 'dosen').length;
        final bufferCount = allConflicts.where((a) => _getCategory(a, api) == 'buffer').length;
        final kelasCount = allConflicts.where((a) => _getCategory(a, api) == 'kelas').length;

        // Ambil daftar fakultas unik untuk dropdown filter
        final fakultasList = ['Semua', ...allConflicts.map((a) => a.fakultasNama).toSet()];

        // Filter data sesuai Search, Kategori, dan Fakultas
        final filteredConflicts = allConflicts.where((a) {
          // Filter Kategori
          if (_selectedCategory != 'all' && _getCategory(a, api) != _selectedCategory) {
            return false;
          }
          // Filter Fakultas
          if (_selectedFakultas != 'Semua' && a.fakultasNama.toLowerCase() != _selectedFakultas.toLowerCase()) {
            return false;
          }
          // Filter Pencarian
          if (_searchQuery.isNotEmpty) {
            final query = _searchQuery.toLowerCase();
            final matchMk = a.mataKuliahNama.toLowerCase().contains(query);
            final matchDosen = a.dosenNama.toLowerCase().contains(query);
            final matchRuang = a.ruanganNama.toLowerCase().contains(query);
            final matchKelas = a.kelasNama.toLowerCase().contains(query);
            if (!matchMk && !matchDosen && !matchRuang && !matchKelas) return false;
          }
          return true;
        }).toList();

        final allFilteredSelected = filteredConflicts.isNotEmpty &&
            filteredConflicts.every((a) => _selectedIds.contains(a.id));

        return Scaffold(
          backgroundColor: const Color(0xFFF8FAFC),
          appBar: AppBar(
            backgroundColor: Colors.white,
            foregroundColor: const Color(0xFF0F172A),
            elevation: 0,
            bottom: const PreferredSize(
              preferredSize: Size.fromHeight(1),
              child: Divider(height: 1, color: Color(0xFFE2E8F0)),
            ),
            leading: IconButton(
              icon: const Icon(Icons.arrow_back_rounded, color: Color(0xFF0F172A)),
              onPressed: () => Navigator.pop(context, true),
            ),
            title: const Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Studio Resolusi Konflik',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Color(0xFF0F172A)),
                ),
                Text(
                  'Super Admin Control • Penyelarasan Jadwal',
                  style: TextStyle(fontSize: 11, color: Color(0xFF64748B)),
                ),
              ],
            ),
            actions: [
              if (allConflicts.isNotEmpty)
                Padding(
                  padding: const EdgeInsets.only(right: 12),
                  child: ElevatedButton.icon(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primary,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                      elevation: 0,
                    ),
                    onPressed: _isProcessing
                        ? null
                        : () => _showDiffConfirmDialog(
                              context: context,
                              items: allConflicts,
                              onResolved: () => setState(() {}),
                            ),
                    icon: const Icon(Icons.published_with_changes_rounded, size: 14),
                    label: const Text(
                      'Selesaikan Semua',
                      style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold),
                    ),
                  ),
                ),
            ],
          ),
          body: _isProcessing
              ? const Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      CircularProgressIndicator(color: AppColors.primary),
                      SizedBox(height: 12),
                      Text(
                        'Memproses Resolusi Cerdas...',
                        style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: Color(0xFF334155)),
                      ),
                    ],
                  ),
                )
              : Column(
                  children: [
                    // ── Search & Filter Controls Panel ──
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.fromLTRB(14, 12, 14, 12),
                      decoration: const BoxDecoration(
                        color: Colors.white,
                        border: Border(bottom: BorderSide(color: Color(0xFFE2E8F0))),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Search Box
                          TextField(
                            controller: _searchController,
                            onChanged: (val) => setState(() => _searchQuery = val.trim()),
                            style: const TextStyle(fontSize: 12.5),
                            decoration: InputDecoration(
                              hintText: 'Cari nama mata kuliah, dosen, ruangan, atau kelas...',
                              hintStyle: const TextStyle(fontSize: 11.5, color: Color(0xFF94A3B8)),
                              prefixIcon: const Icon(Icons.search_rounded, color: Color(0xFF64748B), size: 18),
                              suffixIcon: _searchQuery.isNotEmpty
                                  ? IconButton(
                                      icon: const Icon(Icons.clear_rounded, size: 16, color: Color(0xFF64748B)),
                                      onPressed: () {
                                        _searchController.clear();
                                        setState(() => _searchQuery = '');
                                      },
                                    )
                                  : null,
                              filled: true,
                              fillColor: const Color(0xFFF8FAFC),
                              contentPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                              enabledBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(8),
                                borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
                              ),
                              focusedBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(8),
                                borderSide: const BorderSide(color: AppColors.primary, width: 1.5),
                              ),
                            ),
                          ),
                          const SizedBox(height: 10),

                          // Filter Chips Kategori Bentrok
                          SingleChildScrollView(
                            scrollDirection: Axis.horizontal,
                            child: Row(
                              children: [
                                _buildCategoryFilterChip('all', 'Semua (${allConflicts.length})'),
                                const SizedBox(width: 6),
                                if (ruangCount > 0) ...[
                                  _buildCategoryFilterChip('ruang', 'Bentrok Ruang ($ruangCount)'),
                                  const SizedBox(width: 6),
                                ],
                                if (dosenCount > 0) ...[
                                  _buildCategoryFilterChip('dosen', 'Bentrok Dosen ($dosenCount)'),
                                  const SizedBox(width: 6),
                                ],
                                if (bufferCount > 0) ...[
                                  _buildCategoryFilterChip('buffer', 'Jeda Transit ($bufferCount)'),
                                  const SizedBox(width: 6),
                                ],
                                if (kelasCount > 0) ...[
                                  _buildCategoryFilterChip('kelas', 'Bentrok Kelas ($kelasCount)'),
                                  const SizedBox(width: 6),
                                ],
                              ],
                            ),
                          ),

                          // Fakultas Selector Dropdown if multi-faculty exists
                          if (fakultasList.length > 2) ...[
                            const SizedBox(height: 8),
                            Row(
                              children: [
                                const Text(
                                  'Fakultas: ',
                                  style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Color(0xFF64748B)),
                                ),
                                const SizedBox(width: 6),
                                Expanded(
                                  child: Container(
                                    height: 32,
                                    padding: const EdgeInsets.symmetric(horizontal: 8),
                                    decoration: BoxDecoration(
                                      color: const Color(0xFFF8FAFC),
                                      borderRadius: BorderRadius.circular(6),
                                      border: Border.all(color: const Color(0xFFE2E8F0)),
                                    ),
                                    child: DropdownButtonHideUnderline(
                                      child: DropdownButton<String>(
                                        value: _selectedFakultas,
                                        isDense: true,
                                        style: const TextStyle(fontSize: 11.5, color: Color(0xFF0F172A)),
                                        items: fakultasList
                                            .map((f) => DropdownMenuItem(value: f, child: Text(f, maxLines: 1, overflow: TextOverflow.ellipsis)))
                                            .toList(),
                                        onChanged: (val) {
                                          if (val != null) setState(() => _selectedFakultas = val);
                                        },
                                      ),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ],
                      ),
                    ),

                    // ── Multi-Select Tool Bar ──
                    if (allConflicts.isNotEmpty)
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                        color: const Color(0xFFF1F5F9),
                        child: Row(
                          children: [
                            SizedBox(
                              width: 22,
                              height: 22,
                              child: Checkbox(
                                value: allFilteredSelected,
                                activeColor: AppColors.primary,
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(4)),
                                onChanged: (val) {
                                  setState(() {
                                    if (val == true) {
                                      for (final a in filteredConflicts) {
                                        _selectedIds.add(a.id);
                                      }
                                    } else {
                                      for (final a in filteredConflicts) {
                                        _selectedIds.remove(a.id);
                                      }
                                    }
                                  });
                                },
                              ),
                            ),
                            const SizedBox(width: 6),
                            Text(
                              'Pilih Semua (${_selectedIds.length}/${filteredConflicts.length} item)',
                              style: const TextStyle(fontSize: 11.5, fontWeight: FontWeight.w600, color: Color(0xFF334155)),
                            ),
                            const Spacer(),
                            if (_selectedIds.isNotEmpty)
                              ElevatedButton.icon(
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: const Color(0xFF0F172A),
                                  foregroundColor: Colors.white,
                                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
                                  elevation: 0,
                                ),
                                onPressed: () {
                                  final selectedItems = allConflicts.where((a) => _selectedIds.contains(a.id)).toList();
                                  _showDiffConfirmDialog(
                                    context: context,
                                    items: selectedItems,
                                    onResolved: () => setState(() {}),
                                  );
                                },
                                icon: const Icon(Icons.done_all_rounded, size: 13),
                                label: Text(
                                  'Terapkan Terpilih (${_selectedIds.length})',
                                  style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold),
                                ),
                              ),
                          ],
                        ),
                      ),

                    // ── Conflict Cards List ──
                    Expanded(
                      child: RefreshIndicator(
                        onRefresh: () async {
                          setState(() {});
                        },
                        color: AppColors.primary,
                        child: allConflicts.isEmpty
                            ? SingleChildScrollView(
                                physics: const AlwaysScrollableScrollPhysics(),
                                child: SizedBox(
                                  height: MediaQuery.of(context).size.height * 0.5,
                                  child: const ConflictAllClearView(),
                                ),
                              )
                            : filteredConflicts.isEmpty
                                ? SingleChildScrollView(
                                    physics: const AlwaysScrollableScrollPhysics(),
                                    child: SizedBox(
                                      height: MediaQuery.of(context).size.height * 0.5,
                                      child: ConflictEmptyFilteredView(
                                        onResetFilter: () {
                                          _searchController.clear();
                                          setState(() {
                                            _searchQuery = '';
                                            _selectedCategory = 'all';
                                            _selectedFakultas = 'Semua';
                                          });
                                        },
                                      ),
                                    ),
                                  )
                                : ListView.separated(
                                    physics: const AlwaysScrollableScrollPhysics(),
                                    padding: const EdgeInsets.all(14),
                                    itemCount: filteredConflicts.length,
                                    separatorBuilder: (_, _) => const SizedBox(height: 10),
                                    itemBuilder: (context, index) {
                                      final aj = filteredConflicts[index];
                                      final isSelected = _selectedIds.contains(aj.id);
                                      final category = _getCategory(aj, api);

                                      return ConflictItemCard(
                                        ajuan: aj,
                                        isSelected: isSelected,
                                        category: category,
                                        onSelectedChanged: (val) {
                                          setState(() {
                                            if (val == true) {
                                              _selectedIds.add(aj.id);
                                            } else {
                                              _selectedIds.remove(aj.id);
                                            }
                                          });
                                        },
                                        onResolved: () {
                                          if (mounted) setState(() {});
                                        },
                                      );
                                    },
                                  ),
                      ),
                    ),
                  ],
                ),
        );
      },
    );
  }

  Widget _buildCategoryFilterChip(String key, String label) {
    final isSelected = _selectedCategory == key;
    return GestureDetector(
      onTap: () => setState(() => _selectedCategory = key),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
        decoration: BoxDecoration(
          color: isSelected ? const Color(0xFF0F172A) : const Color(0xFFF1F5F9),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: isSelected ? const Color(0xFF0F172A) : const Color(0xFFCBD5E1)),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 11,
            fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
            color: isSelected ? Colors.white : const Color(0xFF475569),
          ),
        ),
      ),
    );
  }
}
