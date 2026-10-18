// File: dosen_master_tab.dart
// Deskripsi: Widget ListView & Kartu Data Master Dosen dengan switch Prioritas MRV, seleksi & context menu.

import 'package:flutter/material.dart';

import '../../../../config/constants.dart';
import '../../../../data/models/user_model.dart';
import 'master_data_dialogs.dart';

class DosenMasterList extends StatelessWidget {
  final List<UserModel> list;
  final Set<String> priorityDosenIds;
  final Set<String> selectedDosenIds;
  final bool isMultiSelectMode;
  final int totalSelectedCount;
  final int? limit;
  final int startIndex;
  final bool isCompact;
  final void Function(String id) onToggleSelect;
  final void Function(String dosenId, bool currentPriority) onTogglePriority;
  final void Function(UserModel dosen) onEdit;
  final void Function(UserModel dosen) onDelete;
  final void Function(String id) onBatchDelete;

  const DosenMasterList({
    super.key,
    required this.list,
    required this.priorityDosenIds,
    required this.selectedDosenIds,
    required this.isMultiSelectMode,
    required this.totalSelectedCount,
    this.limit,
    this.startIndex = 1,
    this.isCompact = false,
    required this.onToggleSelect,
    required this.onTogglePriority,
    required this.onEdit,
    required this.onDelete,
    required this.onBatchDelete,
  });

  void _showDetail(BuildContext context, UserModel d) {
    final isPriority = priorityDosenIds.contains(d.id);
    final matkulStr = d.matkulNama ?? '-';

    showMasterDetailInfoDialog(
      context: context,
      title: d.nama,
      category: 'Data Dosen Pengajar',
      icon: Icons.person_outline_rounded,
      details: [
        MapEntry('Nama Lengkap', d.nama),
        MapEntry('Email', d.email),
        MapEntry('Fakultas', d.fakultasNama),
        MapEntry('Program Studi', d.jurusanNama),
        MapEntry('Mata Kuliah Diampu', matkulStr),
        MapEntry('Status Prioritas', isPriority ? 'Prioritas Utama (MRV Aktif)' : 'Reguler'),
      ],
      onEdit: () => onEdit(d),
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
        final d = displayList[index];
        final isSelected = selectedDosenIds.contains(d.id);
        final isPriority = priorityDosenIds.contains(d.id);
        final matkulStr = (d.matkulNama != null && d.matkulNama!.isNotEmpty) ? d.matkulNama! : '-';
        Offset tapPos = Offset.zero;

        return GestureDetector(
          behavior: HitTestBehavior.opaque,
          onTapDown: (details) => tapPos = details.globalPosition,
          onLongPressDown: (details) => tapPos = details.globalPosition,
          onTap: () {
            if (isMultiSelectMode || totalSelectedCount > 0) {
              onToggleSelect(d.id);
            } else {
              _showDetail(context, d);
            }
          },
          onLongPress: () {
            showCardContextMenu(
              context: context,
              tapPosition: tapPos,
              itemTitle: d.nama,
              itemCategory: 'Data Dosen',
              onViewDetail: () => _showDetail(context, d),
              onEdit: () => onEdit(d),
              onDelete: () => onDelete(d),
              onBatchDelete: () => onBatchDelete(d.id),
              isPriority: isPriority,
              onTogglePriority: () => onTogglePriority(d.id, isPriority),
            );
          },
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 180),
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            decoration: BoxDecoration(
              color: isSelected ? AppColors.primary.withValues(alpha: 0.08) : Colors.white,
              borderRadius: BorderRadius.circular(10),
              border: Border.all(
                color: isSelected
                    ? AppColors.primary
                    : (isPriority ? const Color(0xFFF59E0B).withValues(alpha: 0.4) : const Color(0xFFE2E8F0)),
                width: isSelected ? 1.5 : 1.0,
              ),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                GestureDetector(
                  behavior: HitTestBehavior.opaque,
                  onTap: () => onToggleSelect(d.id),
                  child: Container(
                    width: 30,
                    height: 30,
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      color: isSelected
                          ? AppColors.primary
                          : (isPriority ? const Color(0xFFFEF3C7) : const Color(0xFFF1F5F9)),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: isSelected
                        ? const Icon(Icons.check, size: 14, color: Colors.white)
                        : Text(
                            '${startIndex + index}',
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                              color: isPriority ? const Color(0xFFD97706) : const Color(0xFF64748B),
                            ),
                          ),
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
                              d.nama,
                              style: TextStyle(
                                fontSize: 12.5,
                                fontWeight: FontWeight.bold,
                                color: isSelected ? AppColors.primary : const Color(0xFF0F172A),
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          if (isPriority) ...[
                            const SizedBox(width: 4),
                            const Icon(
                              Icons.star_rounded,
                              size: 15,
                              color: Color(0xFFF59E0B),
                            ),
                          ],
                        ],
                      ),
                      const SizedBox(height: 2),
                      Text(
                        '${d.fakultasNama} • ${d.jurusanNama}',
                        style: const TextStyle(fontSize: 11, color: Color(0xFF64748B)),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      if (!isCompact) ...[
                        const SizedBox(height: 2),
                        Text(
                          'Matkul: $matkulStr',
                          style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: AppColors.primary),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ],
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
