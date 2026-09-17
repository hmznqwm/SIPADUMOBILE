// File: history_screen.dart
// Deskripsi: Tampilan (View) halaman riwayat pengajuan matriks ketersediaan.
// Fungsi: Menampilkan kartu daftar riwayat pengajuan ketersediaan waktu dosen per semester, status badge, timestamp, dan catatan revisi.

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';

import '../../../../config/constants.dart';
import '../../../core/widgets/status_badge.dart';
import '../view_models/history_view_model.dart';

class HistoryScreen extends StatefulWidget {
  const HistoryScreen({super.key});

  @override
  State<HistoryScreen> createState() => _HistoryScreenState();
}

class _HistoryScreenState extends State<HistoryScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<HistoryViewModel>().loadHistoryData();
    });
  }

  @override
  Widget build(BuildContext context) {
    final viewModel = context.watch<HistoryViewModel>();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Riwayat Pengajuan'),
      ),
      body: RefreshIndicator(
        onRefresh: () => viewModel.loadHistoryData(),
        color: AppColors.primary,
        child: viewModel.isLoading
            ? const Center(child: CircularProgressIndicator())
            : viewModel.historyList.isEmpty
                ? const SingleChildScrollView(
                    physics: AlwaysScrollableScrollPhysics(),
                    child: SizedBox(
                      height: 400,
                      child: Center(child: Text('Belum ada riwayat pengajuan.')),
                    ),
                  )
                : ListView.builder(
                    physics: const AlwaysScrollableScrollPhysics(),
                    padding: const EdgeInsets.all(AppSpacing.md),
                    itemCount: viewModel.historyList.length,
                    itemBuilder: (context, index) {
                      final item = viewModel.historyList[index];
                      final dateStr = DateFormat('dd MMM yyyy, HH:mm').format(item.submittedAt);

                      return Card(
                        child: Padding(
                          padding: const EdgeInsets.all(AppSpacing.lg),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  Text(
                                    item.semesterNama,
                                    style: Theme.of(context).textTheme.titleMedium,
                                  ),
                                  StatusBadge(status: item.status),
                                ],
                              ),
                              const SizedBox(height: AppSpacing.sm),

                              Text(
                                'Diajukan pada: $dateStr',
                                style: Theme.of(context).textTheme.bodySmall,
                              ),
                              const SizedBox(height: AppSpacing.xs),

                              Text(
                                'Jumlah Slot Dipilih: ${item.slotCount} Slot',
                                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                      fontWeight: FontWeight.w600,
                                    ),
                              ),

                              if (item.catatan != null) ...[
                                const Divider(height: AppSpacing.lg),
                                Container(
                                  width: double.infinity,
                                  padding: const EdgeInsets.all(AppSpacing.md),
                                  decoration: BoxDecoration(
                                    color: AppColors.surfaceVariant,
                                    borderRadius: BorderRadius.circular(AppRadius.sm),
                                  ),
                                  child: Text(
                                    'Catatan: ${item.catatan!}',
                                    style: const TextStyle(fontSize: 12, fontStyle: FontStyle.italic),
                                  ),
                                ),
                              ],
                            ],
                          ),
                        ),
                      );
                    },
                  ),
      ),
    );
  }
}
