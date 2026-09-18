// File: matkul_master_tab.dart
// Deskripsi: Widget ListView & Kartu Data Master Mata Kuliah dengan info SKS, kelas, seleksi & context menu.

import 'package:flutter/material.dart';

import '../../../../config/constants.dart';
import 'master_data_dialogs.dart';

class MatkulMasterList extends StatelessWidget {
  final List<Map<String, dynamic>> list;
  final Set<String> selectedMatkulIds;
  final bool isMultiSelectMode;
  final int totalSelectedCount;
  final int? limit;
  final bool isCompact;
  final void Function(String id) onToggleSelect;
  final void Function(Map<String, dynamic> matkul) onEdit;
  final void Function(Map<String, dynamic> matkul) onDelete;
  final void Function(String id) onBatchDelete;

  const MatkulMasterList({
    super.key,
    required this.list,
    required this.selectedMatkulIds,
    required this.isMultiSelectMode,
    required this.totalSelectedCount,
    this.limit,
    this.isCompact = false,
    required this.onToggleSelect,
    required this.onEdit,
    required this.onDelete,
    required this.onBatchDelete,
  });

  void _showDetail(BuildContext context, Map<String, dynamic> m) {
    final kelasRaw = m['kelas'];
    final List<String> kelasList = kelasRaw is List
        ? kelasRaw.map((e) => e.toString()).toList()
        : <String>[];
    final kelasStr = kelasList.isNotEmpty ? kelasList.join(', ') : '-';

    showMasterDetailInfoDialog(
      context: context,
      title: '${m['nama'] ?? 'Mata Kuliah'} (${m['kode'] ?? '-'})',
      category: 'Mata Kuliah Kurikulum',
      icon: Icons.menu_book_rounded,
      details: [
        MapEntry('Kode Matkul', (m['kode'] ?? '-').toString()),
        MapEntry('Nama Matkul', (m['nama'] ?? '-').toString()),
        MapEntry('Bobot SKS', '${m['sks'] ?? 3} SKS'),
        MapEntry('Dosen Pengampu', (m['dosen'] ?? m['dosenNama'] ?? m['dosen_nama'] ?? '-').toString()),
        MapEntry('Fakultas / Unit', (m['fakultas'] ?? '-').toString()),
        MapEntry('Daftar Kelas', kelasStr),
      ],
      onEdit: () => onEdit(m),
    );
  }

  @override
  Widget build(BuildContext context) {
    final displayList = limit != null ? list.take(limit!).toList() : list;

    return ListView.separated(
      padding: EdgeInsets.zero,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: displayList.length,
      separatorBuilder: (_, _) => const SizedBox(height: 6),
      itemBuilder: (context, index) {
        final m = displayList[index];
        final id = (m['kode'] ?? '').toString();
        final isSelected = selectedMatkulIds.contains(id);
        final kelasRaw = m['kelas'];
        final List<String> kelasList = kelasRaw is List
            ? kelasRaw.map((e) => e.toString()).toList()
            : <String>[];
        final kelasStr = kelasList.isNotEmpty ? kelasList.join(', ') : '-';
        Offset tapPos = Offset.zero;

        return GestureDetector(
          behavior: HitTestBehavior.opaque,
          onTapDown: (details) => tapPos = details.globalPosition,
          onLongPressDown: (details) => tapPos = details.globalPosition,
          onTap: () {
            if (isMultiSelectMode || totalSelectedCount > 0) {
              onToggleSelect(id);
            } else {
              _showDetail(context, m);
            }
          },
          onLongPress: () {
            showCardContextMenu(
              context: context,
              tapPosition: tapPos,
              itemTitle: (m['nama'] ?? 'Mata Kuliah').toString(),
              itemCategory: 'Mata Kuliah (${m['kode'] ?? '-'})',
              onViewDetail: () => _showDetail(context, m),
              onEdit: () => onEdit(m),
              onDelete: () => onDelete(m),
              onBatchDelete: () => onBatchDelete(id),
            );
          },
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 180),
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            decoration: BoxDecoration(
              color: isSelected ? AppColors.primary.withValues(alpha: 0.08) : Colors.white,
              borderRadius: BorderRadius.circular(10),
              border: Border.all(
                color: isSelected ? AppColors.primary : const Color(0xFFE2E8F0),
                width: isSelected ? 1.5 : 1.0,
              ),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: isSelected ? AppColors.primary : AppColors.primary.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(
                    Icons.menu_book_rounded,
                    color: isSelected ? Colors.white : AppColors.primary,
                    size: 18,
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Flexible(
                            child: Text(
                              '${m['nama'] ?? ''} (${m['kode'] ?? ''})',
                              style: TextStyle(
                                fontSize: 12.5,
                                fontWeight: FontWeight.bold,
                                color: isSelected ? AppColors.primary : const Color(0xFF0F172A),
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          const SizedBox(width: 6),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1),
                            decoration: BoxDecoration(
                              color: AppColors.primary.withValues(alpha: 0.1),
                              borderRadius: BorderRadius.circular(4),
                              border: Border.all(color: AppColors.primary.withValues(alpha: 0.3)),
                            ),
                            child: Text(
                              '${m['sks'] ?? 3} SKS',
                              style: const TextStyle(fontSize: 9.5, fontWeight: FontWeight.bold, color: AppColors.primary),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 2),
                      Text(
                        'Dosen: ${m['dosen'] ?? m['dosenNama'] ?? m['dosen_nama'] ?? '-'}',
                        style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: Color(0xFF334155)),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      if (!isCompact) ...[
                        const SizedBox(height: 2),
                        Text(
                          'Kelas: $kelasStr • ${m['fakultas'] ?? '-'}',
                          style: const TextStyle(fontSize: 10.5, color: Color(0xFF64748B)),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ],
                  ),
                ),
                if (isSelected) ...[
                  const SizedBox(width: 6),
                  Container(
                    padding: const EdgeInsets.all(2),
                    decoration: const BoxDecoration(
                      color: AppColors.primary,
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(Icons.check, size: 12, color: Colors.white),
                  ),
                ],
              ],
            ),
          ),
        );
      },
    );
  }
}
