// File: gedung_master_tab.dart
// Deskripsi: Widget ListView & Kartu Data Master Gedung Kampus dengan aksi seleksi & context menu.

import 'package:flutter/material.dart';

import '../../../../config/constants.dart';
import '../../../../data/models/gedung_model.dart';
import '../../../../data/mock/mock_database.dart';
import 'master_data_dialogs.dart';

class GedungMasterList extends StatelessWidget {
  final List<GedungModel> list;
  final Set<String> selectedGedungIds;
  final bool isMultiSelectMode;
  final int totalSelectedCount;
  final int? limit;
  final bool isCompact;
  final void Function(String id) onToggleSelect;
  final void Function(GedungModel gedung) onEdit;
  final void Function(GedungModel gedung) onDelete;
  final void Function(String id) onBatchDelete;
  final VoidCallback? onRuanganUpdated;

  const GedungMasterList({
    super.key,
    required this.list,
    required this.selectedGedungIds,
    required this.isMultiSelectMode,
    required this.totalSelectedCount,
    this.limit,
    this.isCompact = false,
    required this.onToggleSelect,
    required this.onEdit,
    required this.onDelete,
    required this.onBatchDelete,
    this.onRuanganUpdated,
  });

  void _showDetail(BuildContext context, GedungModel g) {
    showGedungRuanganBottomSheet(
      context: context,
      gedung: g,
      onEditGedung: () => onEdit(g),
      onRuanganUpdated: onRuanganUpdated,
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
        final g = displayList[index];
        final isSelected = selectedGedungIds.contains(g.id);
        final roomCount = MockDatabase.ruanganList.where((r) =>
            (r.gedungId.isNotEmpty && (r.gedungId == g.id || r.gedungId == g.nama)) ||
            (r.gedungNama.isNotEmpty && (r.gedungNama.trim().toLowerCase() == g.nama.trim().toLowerCase() || r.gedungNama.trim().toLowerCase() == g.id.trim().toLowerCase()))
        ).length;
        Offset tapPos = Offset.zero;

        return GestureDetector(
          behavior: HitTestBehavior.opaque,
          onTapDown: (details) => tapPos = details.globalPosition,
          onLongPressDown: (details) => tapPos = details.globalPosition,
          onTap: () {
            if (isMultiSelectMode || totalSelectedCount > 0) {
              onToggleSelect(g.id);
            } else {
              _showDetail(context, g);
            }
          },
          onLongPress: () {
            showCardContextMenu(
              context: context,
              tapPosition: tapPos,
              itemTitle: g.nama,
              itemCategory: 'Master Gedung',
              onViewDetail: () => _showDetail(context, g),
              onEdit: () => onEdit(g),
              onDelete: () => onDelete(g),
              onBatchDelete: () => onBatchDelete(g.id),
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
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: isSelected ? AppColors.primary : AppColors.primary.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(
                    Icons.apartment_rounded,
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
                          Expanded(
                            child: Text(
                              g.nama,
                              style: TextStyle(
                                fontSize: 12.5,
                                fontWeight: FontWeight.bold,
                                color: isSelected ? AppColors.primary : const Color(0xFF0F172A),
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                            decoration: BoxDecoration(
                              color: roomCount > 0 ? const Color(0xFFE0F2FE) : const Color(0xFFF1F5F9),
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: Text(
                              '$roomCount Ruang',
                              style: TextStyle(
                                fontSize: 10.5,
                                fontWeight: FontWeight.bold,
                                color: roomCount > 0 ? const Color(0xFF0284C7) : const Color(0xFF64748B),
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 2),
                      Text(
                        isCompact
                            ? '${g.aksesJurusan} • ${g.jamBuka} - ${g.jamTutup}'
                            : 'Operasional: ${g.jamBuka} - ${g.jamTutup} • ${g.aksesJurusan}',
                        style: const TextStyle(fontSize: 11, color: Color(0xFF64748B)),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
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
