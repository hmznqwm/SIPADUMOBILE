// File: conflict_item_card.dart
// Deskripsi: Widget kartu item bentrok jadwal di Studio Resolusi Konflik.

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../../config/constants.dart';
import '../../../../data/models/ajuan_pengajaran_model.dart';
import '../../../../data/services/api_service.dart';
import '../../availability/widgets/ajuan_pengajaran_dialogs.dart';

class ConflictItemCard extends StatelessWidget {
  final AjuanPengajaranModel ajuan;
  final bool isSelected;
  final String category;
  final ValueChanged<bool?> onSelectedChanged;
  final VoidCallback onResolved;

  const ConflictItemCard({
    super.key,
    required this.ajuan,
    required this.isSelected,
    required this.category,
    required this.onSelectedChanged,
    required this.onResolved,
  });

  @override
  Widget build(BuildContext context) {
    final api = context.read<ApiService>();
    final suggestion = api.findSmartAlternativeSlot(ajuan);

    String categoryLabel = 'Bentrok Ruangan';
    Color categoryColor = const Color(0xFFDC2626);
    if (category == 'dosen') {
      categoryLabel = 'Bentrok Dosen';
      categoryColor = const Color(0xFF9333EA);
    } else if (category == 'buffer') {
      categoryLabel = 'Jeda Transit Sempit';
      categoryColor = const Color(0xFFEA580C);
    } else if (category == 'kelas') {
      categoryLabel = 'Bentrok Kelas Mahasiswa';
      categoryColor = const Color(0xFF2563EB);
    }

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isSelected ? AppColors.primary : const Color(0xFFFECACA),
          width: isSelected ? 1.5 : 1.0,
        ),
        boxShadow: const [
          BoxShadow(color: Color(0x06DC2626), blurRadius: 4, offset: Offset(0, 1)),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Title Row
          Row(
            children: [
              SizedBox(
                width: 22,
                height: 22,
                child: Checkbox(
                  value: isSelected,
                  activeColor: AppColors.primary,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(4)),
                  onChanged: onSelectedChanged,
                ),
              ),
              const SizedBox(width: 6),
              Expanded(
                child: Text(
                  ajuan.mataKuliahNama,
                  style: const TextStyle(fontSize: 13.5, fontWeight: FontWeight.bold, color: Color(0xFF0F172A)),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              const SizedBox(width: 4),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                decoration: BoxDecoration(
                  color: categoryColor.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(6),
                  border: Border.all(color: categoryColor.withValues(alpha: 0.3)),
                ),
                child: Text(
                  categoryLabel,
                  style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: categoryColor),
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Row(
            children: [
              const Icon(Icons.person_outline_rounded, size: 13, color: Color(0xFF64748B)),
              const SizedBox(width: 4),
              Expanded(
                child: Text(
                  '${ajuan.dosenNama} • ${ajuan.fakultasNama} (Kelas ${ajuan.kelasNama})',
                  style: const TextStyle(fontSize: 11.5, color: Color(0xFF475569)),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),

          // Detail Bentrok (Box Merah)
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: const Color(0xFFFEF2F2),
              borderRadius: BorderRadius.circular(6),
              border: Border.all(color: const Color(0xFFFECACA)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Jadwal Bentrok: ${ajuan.hari}, ${ajuan.waktuFormatted} di ${ajuan.ruanganNama} (${ajuan.gedungNama})',
                  style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Color(0xFF991B1B)),
                ),
                if (ajuan.bentrokDetail != null && ajuan.bentrokDetail!.isNotEmpty) ...[
                  const SizedBox(height: 2),
                  Text(
                    ajuan.bentrokDetail!,
                    style: const TextStyle(fontSize: 10.5, color: Color(0xFF7F1D1D)),
                  ),
                ],
              ],
            ),
          ),
          const SizedBox(height: 6),

          // Smart Heuristic Suggestion Card (Box Hijau/Teal)
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: const Color(0xFFF0FDFA),
              borderRadius: BorderRadius.circular(6),
              border: Border.all(color: const Color(0xFF99F6E4)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: const [
                    Icon(Icons.auto_awesome, color: Colors.teal, size: 14),
                    SizedBox(width: 4),
                    Text(
                      'Rekomendasi Solusi Cerdas',
                      style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Color(0xFF0F766E)),
                    ),
                  ],
                ),
                const SizedBox(height: 2),
                Text(
                  '${suggestion['hari']}, ${suggestion['jamMulai']}-${suggestion['jamSelesai']} di ${suggestion['ruanganNama']} (${suggestion['gedungNama']})',
                  style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Color(0xFF115E59)),
                ),
                Text(
                  suggestion['reason'] ?? 'Tersedia ruangan alternatif yang dapat disesuaikan.',
                  style: const TextStyle(fontSize: 10.5, color: Color(0xFF134E4A)),
                ),
              ],
            ),
          ),
          const SizedBox(height: 8),

          // Action Buttons
          Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 8),
                    side: const BorderSide(color: Color(0xFFCBD5E1)),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                  ),
                  onPressed: () {
                    AjuanPengajaranDialogs.showEditDialog(
                      context: context,
                      ajuan: ajuan,
                      currentRole: 'admin',
                      onSaved: (updated) async {
                        await api.adminApproveFinalAjuan(ajuan.id, updatedData: updated);
                        onResolved();
                      },
                    );
                  },
                  child: const Text('Edit Manual', style: TextStyle(fontSize: 11.5, color: Color(0xFF475569))),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: ElevatedButton.icon(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 8),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                    elevation: 0,
                  ),
                  onPressed: () async {
                    final updated = ajuan.copyWith(
                      gedungNama: suggestion['gedungNama'],
                      ruanganNama: suggestion['ruanganNama'],
                      hari: suggestion['hari'],
                      jamMulai: suggestion['jamMulai'],
                      jamSelesai: suggestion['jamSelesai'],
                      status: 'disetujui_admin',
                      catatanAdmin: 'Rekomendasi solusi cerdas diterapkan.',
                      bentrokDetail: null,
                      updatedAt: DateTime.now(),
                    );
                    final messenger = ScaffoldMessenger.of(context);
                    await api.adminApproveFinalAjuan(ajuan.id, updatedData: updated);
                    onResolved();
                    messenger.showSnackBar(
                      const SnackBar(
                        content: Text('Rekomendasi diterapkan! Jadwal resmi disetujui.'),
                        backgroundColor: AppColors.primary,
                      ),
                    );
                  },
                  icon: const Icon(Icons.check_rounded, size: 15),
                  label: const Text('Terapkan Solusi', style: TextStyle(fontSize: 11.5, fontWeight: FontWeight.bold)),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
