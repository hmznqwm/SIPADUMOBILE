// File: fakultas_master_tab.dart
// Deskripsi: Widget ListView & Kartu Data Master Fakultas & Prodi dengan aksi seleksi & context menu.

import 'package:flutter/material.dart';

import '../../../../config/constants.dart';
import 'master_data_dialogs.dart';

class FakultasMasterList extends StatelessWidget {
  final List<Map<String, dynamic>> list;
  final Set<String> selectedFakultasIds;
  final bool isMultiSelectMode;
  final int totalSelectedCount;
  final int? limit;
  final bool isCompact;
  final void Function(String id) onToggleSelect;
  final void Function(Map<String, dynamic> fakultas) onEdit;
  final void Function(Map<String, dynamic> fakultas) onDelete;
  final void Function(String id) onBatchDelete;

  const FakultasMasterList({
    super.key,
    required this.list,
    required this.selectedFakultasIds,
    required this.isMultiSelectMode,
    required this.totalSelectedCount,
    this.limit,
    this.isCompact = false,
    required this.onToggleSelect,
    required this.onEdit,
    required this.onDelete,
    required this.onBatchDelete,
  });

  void _showDetail(BuildContext context, Map<String, dynamic> f) {
    final jurRaw = f['jurusan'];
    final List<String> jurList = jurRaw is List
        ? jurRaw.map((e) => e.toString()).toList()
        : <String>[];
    final prodiStr = jurList.isNotEmpty ? jurList.join(', ') : '-';

    showMasterDetailInfoDialog(
      context: context,
      title: (f['nama'] ?? 'Fakultas').toString(),
      category: 'Fakultas & Program Studi',
      icon: Icons.account_balance_outlined,
      details: [
        MapEntry('Nama Fakultas', (f['nama'] ?? '-').toString()),
        MapEntry('Dekan', (f['dekan'] ?? '-').toString()),
        MapEntry('Lokasi Gedung', (f['gedung'] ?? '-').toString()),
        MapEntry('Jumlah Prodi', '${jurList.length} Program Studi'),
        MapEntry('Daftar Prodi', prodiStr),
      ],
      onEdit: () => onEdit(f),
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
        final f = displayList[index];
        final id = (f['id'] ?? f['nama']) as String;
        final isSelected = selectedFakultasIds.contains(id);
        final jurRaw = f['jurusan'];
        final List<String> jurList = jurRaw is List
            ? jurRaw.map((e) => e.toString()).toList()
            : <String>[];
        final prodiStr = jurList.isNotEmpty ? jurList.join(', ') : '-';
        Offset tapPos = Offset.zero;

        return GestureDetector(
          behavior: HitTestBehavior.opaque,
          onTapDown: (details) => tapPos = details.globalPosition,
          onLongPressDown: (details) => tapPos = details.globalPosition,
          onTap: () {
            if (isMultiSelectMode || totalSelectedCount > 0) {
              onToggleSelect(id);
            } else {
              _showDetail(context, f);
            }
          },
          onLongPress: () {
            showCardContextMenu(
              context: context,
              tapPosition: tapPos,
              itemTitle: (f['nama'] ?? 'Fakultas').toString(),
              itemCategory: 'Fakultas & Prodi',
              onViewDetail: () => _showDetail(context, f),
              onEdit: () => onEdit(f),
              onDelete: () => onDelete(f),
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
                    Icons.account_balance_outlined,
                    color: isSelected ? Colors.white : AppColors.primary,
                    size: 18,
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        (f['nama'] ?? '').toString(),
                        style: TextStyle(
                          fontSize: 12.5,
                          fontWeight: FontWeight.bold,
                          color: isSelected ? AppColors.primary : const Color(0xFF0F172A),
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 2),
                      if (isCompact) ...[
                        Text(
                          '${jurList.length} Program Studi • Lokasi: ${f['gedung'] ?? '-'}',
                          style: const TextStyle(fontSize: 11, color: Color(0xFF64748B)),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ] else ...[
                        Text(
                          'Dekan: ${f['dekan'] ?? '-'} • Lokasi: ${f['gedung'] ?? '-'}',
                          style: const TextStyle(fontSize: 11, color: Color(0xFF64748B)),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 2),
                        Text(
                          'Prodi: $prodiStr',
                          style: const TextStyle(fontSize: 10.5, color: Color(0xFF0284C7), fontWeight: FontWeight.w500),
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
