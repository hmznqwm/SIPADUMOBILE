// File: notifications_screen.dart
// Deskripsi: Tampilan (View) halaman pusat notifikasi sistem dengan sistem multi-select Gmail.
// Fungsi: Menampilkan daftar notifikasi ringkas. Saat ditekan lama (long press), masuk ke mode seleksi untuk tandai dibaca atau hapus masal persis seperti Gmail.

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../../../../config/constants.dart';
import '../../../core/widgets/empty_state_widget.dart';
import '../view_models/notifications_view_model.dart';

class NotificationsScreen extends StatefulWidget {
  const NotificationsScreen({super.key});

  @override
  State<NotificationsScreen> createState() => _NotificationsScreenState();
}

class _NotificationsScreenState extends State<NotificationsScreen> {
  final Set<String> _expandedIds = {};
  final Set<String> _selectedIds = {};

  bool get _isSelectionMode => _selectedIds.isNotEmpty;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<NotificationsViewModel>().loadNotifications();
    });
  }

  IconData _getNotificationIcon(String type) {
    switch (type) {
      case 'jadwal_published':
        return Icons.calendar_today_outlined;
      case 'availability_request':
        return Icons.warning_amber_rounded;
      case 'approval':
        return Icons.check_circle_outline;
      case 'success':
        return Icons.verified_outlined;
      case 'info':
      default:
        return Icons.info_outline;
    }
  }

  Color _getNotificationColor(String type) {
    switch (type) {
      case 'jadwal_published':
        return AppColors.primary;
      case 'availability_request':
        return AppColors.pending;
      case 'approval':
        return AppColors.available;
      case 'success':
        return const Color(0xFF16A34A);
      case 'info':
      default:
        return AppColors.info;
    }
  }

  void _handleTap(String id, bool isRead, NotificationsViewModel viewModel) {
    if (_isSelectionMode) {
      setState(() {
        if (_selectedIds.contains(id)) {
          _selectedIds.remove(id);
        } else {
          _selectedIds.add(id);
        }
      });
    } else {
      if (!isRead) {
        viewModel.markAsRead(id);
      }
      setState(() {
        if (_expandedIds.contains(id)) {
          _expandedIds.remove(id);
        } else {
          _expandedIds.add(id);
        }
      });
    }
  }

  void _handleLongPress(String id) {
    setState(() {
      _selectedIds.add(id);
    });
  }

  void _confirmBulkDelete(BuildContext context, NotificationsViewModel viewModel) {
    final count = _selectedIds.length;
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
        title: Row(
          children: [
            const Icon(Icons.delete_outline_rounded, color: AppColors.error),
            const SizedBox(width: 8),
            Text('Hapus $count Notifikasi?', style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
          ],
        ),
        content: Text('Apakah Anda yakin ingin menghapus $count notifikasi terpilih secara permanen?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Batal'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.error,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
            ),
            onPressed: () async {
              final idsToDelete = _selectedIds.toList();
              final messenger = ScaffoldMessenger.of(context);
              Navigator.pop(ctx);
              await viewModel.deleteNotifications(idsToDelete);
              setState(() {
                _selectedIds.clear();
              });
              messenger.showSnackBar(
                SnackBar(
                  content: Text('$count notifikasi berhasil dihapus!'),
                  backgroundColor: AppColors.primaryDark,
                ),
              );
            },
            child: const Text('Hapus Masal'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final viewModel = context.watch<NotificationsViewModel>();

    return Scaffold(
      appBar: _isSelectionMode
          ? AppBar(
              backgroundColor: AppColors.primary,
              foregroundColor: Colors.white,
              elevation: 2,
              leading: IconButton(
                icon: const Icon(Icons.close_rounded, color: Colors.white),
                tooltip: 'Batal Seleksi',
                onPressed: () => setState(() => _selectedIds.clear()),
              ),
              title: Text(
                '${_selectedIds.length} Dipilih',
                style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold),
              ),
              actions: [
                // Tombol Pilih Semua (Select All / Deselect)
                IconButton(
                  icon: Icon(
                    _selectedIds.length == viewModel.notifications.length
                        ? Icons.deselect_rounded
                        : Icons.select_all_rounded,
                    color: Colors.white,
                  ),
                  tooltip: _selectedIds.length == viewModel.notifications.length ? 'Batal Pilih Semua' : 'Pilih Semua',
                  onPressed: () {
                    setState(() {
                      if (_selectedIds.length == viewModel.notifications.length) {
                        _selectedIds.clear();
                      } else {
                        _selectedIds.addAll(viewModel.notifications.map((n) => n.id));
                      }
                    });
                  },
                ),

                // Tombol Tandai Dibaca Semua Terpilih
                IconButton(
                  icon: const Icon(Icons.mark_email_read_outlined, color: Colors.white),
                  tooltip: 'Tandai Dibaca',
                  onPressed: () async {
                    final count = _selectedIds.length;
                    final idsToRead = _selectedIds.toList();
                    await viewModel.markMultipleAsRead(idsToRead);
                    setState(() => _selectedIds.clear());
                    if (context.mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text('$count notifikasi ditandai sudah dibaca!')),
                      );
                    }
                  },
                ),

                // Tombol Hapus Masal
                IconButton(
                  icon: const Icon(Icons.delete_outline_rounded, color: Colors.white),
                  tooltip: 'Hapus Masal',
                  onPressed: () => _confirmBulkDelete(context, viewModel),
                ),
                const SizedBox(width: 4),
              ],
            )
          : AppBar(
              title: const Text('Notifikasi Sistem'),
            ),
      body: RefreshIndicator(
        onRefresh: () => viewModel.loadNotifications(),
        color: AppColors.primary,
        child: viewModel.isLoading
            ? const Center(
                child: CircularProgressIndicator(
                  color: AppColors.primary,
                  strokeWidth: 3.2,
                ),
              )
            : viewModel.notifications.isEmpty
                ? const SingleChildScrollView(
                    physics: AlwaysScrollableScrollPhysics(),
                    child: SizedBox(
                      height: 400,
                      child: EmptyStateWidget(
                        icon: Icons.notifications_off_outlined,
                        title: 'Tidak Ada Notifikasi',
                        message: 'Anda belum memiliki notifikasi baru.',
                      ),
                    ),
                  )
                : ListView.separated(
                    physics: const AlwaysScrollableScrollPhysics(),
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  itemCount: viewModel.notifications.length,
                  separatorBuilder: (context, index) => const SizedBox(height: 10),
                  itemBuilder: (context, index) {
                    final item = viewModel.notifications[index];
                    final dateStr = DateFormat('dd MMM yyyy, HH:mm').format(item.timestamp);
                    final iconColor = _getNotificationColor(item.tipe);
                    final isExpanded = _expandedIds.contains(item.id);
                    final isSelected = _selectedIds.contains(item.id);

                    return Card(
                      elevation: 0,
                      margin: EdgeInsets.zero,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                        side: BorderSide(
                          color: isSelected
                              ? AppColors.primary
                              : item.isRead
                                  ? const Color(0xFFE2E8F0)
                                  : iconColor.withValues(alpha: 0.35),
                          width: isSelected ? 1.5 : (item.isRead ? 1 : 1.2),
                        ),
                      ),
                      color: isSelected
                          ? AppColors.primary.withValues(alpha: 0.08)
                          : item.isRead
                              ? Colors.white
                              : iconColor.withValues(alpha: 0.04),
                      child: InkWell(
                        onTap: () => _handleTap(item.id, item.isRead, viewModel),
                        onLongPress: () => _handleLongPress(item.id),
                        borderRadius: BorderRadius.circular(12),
                        child: Padding(
                          padding: const EdgeInsets.all(12),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                crossAxisAlignment: CrossAxisAlignment.center,
                                children: [
                                  // Leading: Checkbox Icon saat terpilih / Avatar Kategori
                                  if (isSelected)
                                    Container(
                                      width: 38,
                                      height: 38,
                                      decoration: const BoxDecoration(
                                        color: AppColors.primary,
                                        shape: BoxShape.circle,
                                      ),
                                      child: const Icon(
                                        Icons.check_rounded,
                                        color: Colors.white,
                                        size: 20,
                                      ),
                                    )
                                  else
                                    Container(
                                      width: 38,
                                      height: 38,
                                      decoration: BoxDecoration(
                                        color: iconColor.withValues(alpha: 0.12),
                                        borderRadius: BorderRadius.circular(10),
                                      ),
                                      child: Icon(_getNotificationIcon(item.tipe), color: iconColor, size: 19),
                                    ),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          item.judul,
                                          style: TextStyle(
                                            fontSize: 13.5,
                                            fontWeight: item.isRead ? FontWeight.w500 : FontWeight.bold,
                                            color: const Color(0xFF0F172A),
                                            height: 1.3,
                                          ),
                                        ),
                                        const SizedBox(height: 3),
                                        Text(
                                          dateStr,
                                          style: const TextStyle(fontSize: 11, color: Color(0xFF94A3B8)),
                                        ),
                                      ],
                                    ),
                                  ),
                                  if (!item.isRead && !isSelected) ...[
                                    const SizedBox(width: 8),
                                    Container(
                                      width: 8,
                                      height: 8,
                                      decoration: const BoxDecoration(
                                        color: AppColors.primary,
                                        shape: BoxShape.circle,
                                      ),
                                    ),
                                  ],
                                ],
                              ),

                              // ── Isi Pesan (Hanya terbuka ketika judul notifikasi ditekan) ──
                              AnimatedCrossFade(
                                duration: const Duration(milliseconds: 200),
                                crossFadeState: isExpanded && !_isSelectionMode ? CrossFadeState.showSecond : CrossFadeState.showFirst,
                                firstChild: const SizedBox.shrink(),
                                secondChild: Padding(
                                  padding: const EdgeInsets.only(top: 10, left: 50),
                                  child: Container(
                                    width: double.infinity,
                                    padding: const EdgeInsets.all(10),
                                    decoration: BoxDecoration(
                                      color: const Color(0xFFF8FAFC),
                                      borderRadius: BorderRadius.circular(8),
                                      border: Border.all(color: const Color(0xFFE2E8F0)),
                                    ),
                                    child: Text(
                                      item.pesan,
                                      style: const TextStyle(
                                        fontSize: 12,
                                        color: Color(0xFF334155),
                                        height: 1.45,
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    );
                  },
                ),
      ),
    );
  }
}
