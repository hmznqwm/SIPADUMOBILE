// File: conflict_resolution_diff_dialog.dart
// Deskripsi: Modal dialog perbandingan sebelum dan sesudah (Diff Preview) untuk resolusi jadwal bentrok massal.

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../../config/constants.dart';
import '../../../../data/models/ajuan_pengajaran_model.dart';
import '../../../../data/services/api_service.dart';

class ConflictResolutionDiffDialog extends StatelessWidget {
  final List<AjuanPengajaranModel> items;
  final VoidCallback onResolved;
  final ValueChanged<bool> onProcessingChanged;
  final VoidCallback onClearSelection;

  const ConflictResolutionDiffDialog({
    super.key,
    required this.items,
    required this.onResolved,
    required this.onProcessingChanged,
    required this.onClearSelection,
  });

  static void show({
    required BuildContext context,
    required List<AjuanPengajaranModel> items,
    required VoidCallback onResolved,
    required ValueChanged<bool> onProcessingChanged,
    required VoidCallback onClearSelection,
  }) {
    if (items.isEmpty) return;
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => ConflictResolutionDiffDialog(
        items: items,
        onResolved: onResolved,
        onProcessingChanged: onProcessingChanged,
        onClearSelection: onClearSelection,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final api = context.read<ApiService>();

    final List<Map<String, dynamic>> diffs = [];
    final List<AjuanPengajaranModel> simulatedAccepted = api.getDemoUsers().isNotEmpty ? [] : [];

    for (final aj in items) {
      final suggestion = api.findSmartAlternativeSlot(aj, simulatedAccepted);
      diffs.add({
        'ajuan': aj,
        'oldRoom': '${aj.ruanganNama} (${aj.gedungNama})',
        'oldTime': '${aj.hari}, ${aj.waktuFormatted}',
        'newRoom': '${suggestion['ruanganNama']} (${suggestion['gedungNama']})',
        'newTime': '${suggestion['hari']}, ${suggestion['jamMulai']}-${suggestion['jamSelesai']}',
        'reason': suggestion['reason'],
      });
    }

    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      clipBehavior: Clip.antiAlias,
      insetPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
      backgroundColor: Colors.white,
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 520, maxHeight: 600),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
            Container(
              padding: const EdgeInsets.fromLTRB(16, 14, 16, 14),
              decoration: const BoxDecoration(
                color: Colors.white,
                border: Border(bottom: BorderSide(color: Color(0xFFE2E8F0))),
              ),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(7),
                    decoration: BoxDecoration(
                      color: Colors.teal.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Icon(Icons.published_with_changes_rounded, color: Colors.teal[800], size: 20),
                  ),
                  const SizedBox(width: 10),
                  const Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Konfirmasi Resolusi Bentrok Massal',
                          style: TextStyle(color: Color(0xFF0F172A), fontSize: 14.5, fontWeight: FontWeight.bold),
                        ),
                        Text(
                          'Penerapan otomatis penyesuaian jadwal bebas bentrok',
                          style: TextStyle(color: Color(0xFF64748B), fontSize: 11),
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close_rounded, color: Color(0xFF64748B), size: 20),
                    visualDensity: VisualDensity.compact,
                    onPressed: () => Navigator.pop(context),
                  ),
                ],
              ),
            ),

            // Diff List
            Flexible(
              child: ListView.separated(
                padding: const EdgeInsets.all(14),
                shrinkWrap: true,
                itemCount: diffs.length,
                separatorBuilder: (_, _) => const SizedBox(height: 10),
                itemBuilder: (ctx, idx) {
                  final d = diffs[idx];
                  final AjuanPengajaranModel aj = d['ajuan'];
                  return Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: const Color(0xFFF8FAFC),
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: const Color(0xFFE2E8F0)),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Expanded(
                              child: Text(
                                aj.mataKuliahNama,
                                style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: Color(0xFF0F172A)),
                              ),
                            ),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                              decoration: BoxDecoration(
                                color: const Color(0xFFF1F5F9),
                                borderRadius: BorderRadius.circular(4),
                              ),
                              child: Text(
                                'Kelas ${aj.kelasNama}',
                                style: const TextStyle(fontSize: 10.5, fontWeight: FontWeight.bold, color: Color(0xFF475569)),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 2),
                        Text(
                          '${aj.dosenNama} • ${aj.fakultasNama}',
                          style: const TextStyle(fontSize: 11, color: Color(0xFF64748B)),
                        ),
                        const SizedBox(height: 8),
                        Row(
                          children: [
                            // Sebelum (Bentrok)
                            Expanded(
                              child: Container(
                                padding: const EdgeInsets.all(7),
                                decoration: BoxDecoration(
                                  color: const Color(0xFFFEF2F2),
                                  borderRadius: BorderRadius.circular(6),
                                  border: Border.all(color: const Color(0xFFFECACA)),
                                ),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    const Row(
                                      children: [
                                        Icon(Icons.close_rounded, size: 12, color: Color(0xFFDC2626)),
                                        SizedBox(width: 4),
                                        Text('Sebelum (Bentrok)', style: TextStyle(fontSize: 9.5, fontWeight: FontWeight.bold, color: Color(0xFF991B1B))),
                                      ],
                                    ),
                                    const SizedBox(height: 2),
                                    Text(d['oldTime'], style: const TextStyle(fontSize: 10.5, color: Color(0xFF7F1D1D), fontWeight: FontWeight.w600)),
                                    Text(d['oldRoom'], style: const TextStyle(fontSize: 10, color: Color(0xFF991B1B))),
                                  ],
                                ),
                              ),
                            ),
                            const Padding(
                              padding: EdgeInsets.symmetric(horizontal: 6),
                              child: Icon(Icons.arrow_forward_rounded, size: 16, color: Color(0xFF94A3B8)),
                            ),
                            // Sesudah (Solusi Baru)
                            Expanded(
                              child: Container(
                                padding: const EdgeInsets.all(7),
                                decoration: BoxDecoration(
                                  color: const Color(0xFFF0FDF4),
                                  borderRadius: BorderRadius.circular(6),
                                  border: Border.all(color: const Color(0xFFBBF7D0)),
                                ),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    const Row(
                                      children: [
                                        Icon(Icons.check_rounded, size: 12, color: Color(0xFF16A34A)),
                                        SizedBox(width: 4),
                                        Text('Solusi Baru (Aman)', style: TextStyle(fontSize: 9.5, fontWeight: FontWeight.bold, color: Color(0xFF15803D))),
                                      ],
                                    ),
                                    const SizedBox(height: 2),
                                    Text(d['newTime'], style: const TextStyle(fontSize: 10.5, color: Color(0xFF14532D), fontWeight: FontWeight.w600)),
                                    Text(d['newRoom'], style: const TextStyle(fontSize: 10, color: Color(0xFF166534))),
                                  ],
                                ),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  );
                },
              ),
            ),

            // Footer
            Container(
              padding: const EdgeInsets.fromLTRB(14, 10, 14, 12),
              decoration: const BoxDecoration(
                color: Colors.white,
                border: Border(top: BorderSide(color: Color(0xFFE2E8F0))),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 10),
                        side: const BorderSide(color: Color(0xFFCBD5E1)),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                      ),
                      onPressed: () => Navigator.pop(context),
                      child: const Text('Batal', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: Color(0xFF64748B))),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    flex: 2,
                    child: ElevatedButton.icon(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primary,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 10),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                        elevation: 0,
                      ),
                      onPressed: () async {
                        final messenger = ScaffoldMessenger.of(context);
                        Navigator.pop(context);
                        onProcessingChanged(true);
                        final targetIds = items.map((e) => e.id).toList();
                        final count = await api.batchResolveConflicts(targetAjuanIds: targetIds);
                        await api.getAjuanPengajaranList();
                        onClearSelection();
                        onProcessingChanged(false);
                        onResolved();
                        messenger.showSnackBar(
                          SnackBar(
                            content: Text('Berhasil menyelesaikan $count jadwal bentrok secara massal!'),
                            backgroundColor: AppColors.primary,
                            behavior: SnackBarBehavior.floating,
                          ),
                        );
                      },
                      icon: const Icon(Icons.check_circle_rounded, size: 16),
                      label: Text('Terapkan ${items.length} Solusi', style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
