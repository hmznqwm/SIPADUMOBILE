// File: master_data_screen_components.dart
// Deskripsi: Kumpulan komponen reusable UI untuk AdminMasterDataScreen.
// Termasuk: Header banner, Filter bar, Section header, Expand toggle, Empty state, dan Floating Multi-Select bar.

import 'package:flutter/material.dart';

import '../../../../config/constants.dart';
import '../../../core/widgets/wave_header_card.dart';

class MasterDataHeaderCard extends StatelessWidget {
  final dynamic user;
  const MasterDataHeaderCard({super.key, this.user});

  @override
  Widget build(BuildContext context) {
    final role = user?.role ?? 'admin';
    final isDekan = role == 'dekan';
    final isKaProdi = role == 'kajur';

    String title = 'Pusat Master Data & Institusi';
    String subtitle = 'Kelola gedung, fakultas, prodi, matkul, dan dosen prioritas';

    if (isKaProdi) {
      final jur = user?.jurusanNama ?? 'Program Studi';
      title = 'Master Data Program Studi';
      subtitle = 'Kelola mata kuliah dan data dosen pengampu $jur';
    } else if (isDekan) {
      final fak = user?.fakultasNama ?? 'Fakultas';
      title = 'Master Data Fakultas';
      subtitle = 'Kelola mata kuliah dan data dosen di lingkungan $fak';
    }

    return WaveHeaderCard(
      title: title,
      subtitle: subtitle,
    );
  }
}

class MasterDataSectionHeader extends StatelessWidget {
  final String title;
  final IconData icon;
  final Color iconColor;
  final VoidCallback onAdd;
  final String addButtonText;
  final bool showAddButton;
  final Color? buttonColor;

  const MasterDataSectionHeader({
    super.key,
    required this.title,
    required this.icon,
    required this.iconColor,
    required this.onAdd,
    required this.addButtonText,
    this.showAddButton = true,
    this.buttonColor,
  });

  @override
  Widget build(BuildContext context) {
    final activeBtnColor = buttonColor ?? iconColor;
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.all(5),
              decoration: BoxDecoration(
                color: iconColor.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(6),
              ),
              child: Icon(icon, size: 14, color: iconColor),
            ),
            const SizedBox(width: 8),
            Text(
              title,
              style: const TextStyle(
                fontSize: 13.5,
                fontWeight: FontWeight.bold,
                color: Color(0xFF0F172A),
              ),
            ),
          ],
        ),
        if (showAddButton)
          InkWell(
            onTap: onAdd,
            borderRadius: BorderRadius.circular(6),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 5),
              decoration: BoxDecoration(
                color: activeBtnColor,
                borderRadius: BorderRadius.circular(6),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.add, size: 14, color: Colors.white),
                  const SizedBox(width: 3),
                  Text(
                    addButtonText,
                    style: const TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                ],
              ),
            ),
          ),
      ],
    );
  }
}

class MasterDataExpandToggle extends StatelessWidget {
  final bool isExpanded;
  final VoidCallback onToggle;
  final String? label;

  const MasterDataExpandToggle({
    super.key,
    this.isExpanded = false,
    required this.onToggle,
    this.label,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: 6),
      child: Center(
        child: InkWell(
          onTap: onToggle,
          borderRadius: BorderRadius.circular(6),
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 4, horizontal: 8),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  label ?? (isExpanded ? 'Tampilkan Lebih Sedikit' : 'Lihat Selengkapnya'),
                  style: const TextStyle(
                    fontSize: 11.5,
                    fontWeight: FontWeight.bold,
                    color: AppColors.primary,
                  ),
                ),
                const SizedBox(width: 4),
                const Icon(
                  Icons.arrow_forward_rounded,
                  size: 14,
                  color: AppColors.primary,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class MasterDataPaginationBar extends StatelessWidget {
  final int currentCount;
  final int totalCount;
  final int initialCount;
  final VoidCallback onLoadMore;
  final VoidCallback? onCollapse;

  const MasterDataPaginationBar({
    super.key,
    required this.currentCount,
    required this.totalCount,
    this.initialCount = 10,
    required this.onLoadMore,
    this.onCollapse,
  });

  @override
  Widget build(BuildContext context) {
    final hasMore = totalCount > currentCount;

    if (!hasMore) return const SizedBox.shrink();

    return Padding(
      padding: const EdgeInsets.only(top: 8),
      child: InkWell(
        onTap: onLoadMore,
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
    );
  }
}

class MasterDataEmptyState extends StatelessWidget {
  final String message;
  final VoidCallback? onAdd;
  final String? addLabel;

  const MasterDataEmptyState({
    super.key,
    required this.message,
    this.onAdd,
    this.addLabel,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: const Color(0xFFF1F5F9),
              shape: BoxShape.circle,
              border: Border.all(color: const Color(0xFFE2E8F0)),
            ),
            child: const Icon(
              Icons.folder_open_rounded,
              color: Color(0xFF94A3B8),
              size: 22,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            message,
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontSize: 12.5,
              fontWeight: FontWeight.w500,
              color: Color(0xFF64748B),
            ),
          ),
          if (onAdd != null && addLabel != null) ...[
            const SizedBox(height: 10),
            InkWell(
              onTap: onAdd,
              borderRadius: BorderRadius.circular(8),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: AppColors.primary.withValues(alpha: 0.08),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: AppColors.primary.withValues(alpha: 0.25)),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.add_rounded, size: 14, color: AppColors.primary),
                    const SizedBox(width: 4),
                    Text(
                      addLabel!,
                      style: const TextStyle(
                        fontSize: 11.5,
                        fontWeight: FontWeight.bold,
                        color: AppColors.primary,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class MasterDataMultiSelectBar extends StatelessWidget {
  final int totalSelectedCount;
  final VoidCallback onCancel;
  final VoidCallback onDelete;

  const MasterDataMultiSelectBar({
    super.key,
    required this.totalSelectedCount,
    required this.onCancel,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    return Positioned(
      left: 0,
      right: 0,
      bottom: 0,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 9),
        decoration: const BoxDecoration(
          color: Colors.white,
          border: Border(
            top: BorderSide(color: Color(0xFFE2E8F0), width: 1.2),
          ),
          boxShadow: [
            BoxShadow(
              color: Color(0x0C000000),
              blurRadius: 8,
              offset: Offset(0, -3),
            ),
          ],
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              decoration: BoxDecoration(
                color: AppColors.primary.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(
                    Icons.check_circle_rounded,
                    size: 15,
                    color: AppColors.primary,
                  ),
                  const SizedBox(width: 5),
                  Text(
                    '$totalSelectedCount Terpilih',
                    style: const TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                      color: AppColors.primary,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 6),
            TextButton(
              onPressed: onCancel,
              style: TextButton.styleFrom(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                minimumSize: Size.zero,
                tapTargetSize: MaterialTapTargetSize.shrinkWrap,
              ),
              child: const Text(
                'Batal',
                style: TextStyle(
                  color: Color(0xFF64748B),
                  fontWeight: FontWeight.w600,
                  fontSize: 12.5,
                ),
              ),
            ),
            const SizedBox(width: 6),
            Expanded(
              child: ElevatedButton.icon(
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFFDC2626),
                  foregroundColor: Colors.white,
                  elevation: 0,
                  tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 9),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                onPressed: totalSelectedCount == 0 ? null : onDelete,
                icon: const Icon(Icons.delete_outline_rounded, size: 16),
                label: Text(
                  'Hapus Masal ($totalSelectedCount)',
                  style: const TextStyle(
                    fontSize: 12.5,
                    fontWeight: FontWeight.bold,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
