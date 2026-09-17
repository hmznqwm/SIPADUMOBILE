// File: conflict_resolution_empty_states.dart
// Deskripsi: Widget tampilan kosong/sukses pada Studio Resolusi Konflik (All Clear & Empty Filter).

import 'package:flutter/material.dart';

import '../../../../config/constants.dart';

class ConflictAllClearView extends StatelessWidget {
  const ConflictAllClearView({super.key});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.all(16),
              decoration: const BoxDecoration(
                color: Color(0xFFECFDF5),
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.verified_rounded, size: 48, color: Color(0xFF10B981)),
            ),
            const SizedBox(height: 16),
            const Text(
              'Seluruh Jadwal Bebas Bentrok 100%!',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Color(0xFF0F172A)),
            ),
            const SizedBox(height: 6),
            const Text(
              'Tidak ada konflik jadwal aktif. Seluruh alokasi waktu, ruangan, dan dosen telah tersinkronisasi sempurna.',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 12, color: Color(0xFF64748B), height: 1.4),
            ),
            const SizedBox(height: 20),
            ElevatedButton.icon(
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 10),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
              ),
              onPressed: () => Navigator.pop(context, true),
              icon: const Icon(Icons.arrow_back_rounded, size: 16),
              label: const Text('Kembali ke Dashboard Admin', style: TextStyle(fontWeight: FontWeight.bold)),
            ),
          ],
        ),
      ),
    );
  }
}

class ConflictEmptyFilteredView extends StatelessWidget {
  final VoidCallback onResetFilter;

  const ConflictEmptyFilteredView({
    super.key,
    required this.onResetFilter,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.filter_list_off_rounded, size: 40, color: Color(0xFF94A3B8)),
            const SizedBox(height: 10),
            const Text(
              'Tidak ada konflik yang cocok dengan filter.',
              style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: Color(0xFF475569)),
            ),
            const SizedBox(height: 4),
            const Text(
              'Coba ubah kata kunci pencarian atau kategori filter Anda.',
              style: TextStyle(fontSize: 11.5, color: Color(0xFF94A3B8)),
            ),
            const SizedBox(height: 12),
            TextButton(
              onPressed: onResetFilter,
              child: const Text('Reset Filter'),
            ),
          ],
        ),
      ),
    );
  }
}
