// File: admin_banding_section.dart
// Deskripsi: Widget kartu daftar permohonan banding jadwal dosen untuk Super Admin.

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../../config/constants.dart';
import '../../../../data/models/ajuan_pengajaran_model.dart';
import '../../../../data/services/api_service.dart';
import '../../availability/widgets/ajuan_pengajaran_dialogs.dart';

class AdminBandingSection extends StatelessWidget {
  final List<AjuanPengajaranModel> allAjuanList;
  final Future<void> Function() onRefreshData;

  const AdminBandingSection({
    super.key,
    required this.allAjuanList,
    required this.onRefreshData,
  });

  @override
  Widget build(BuildContext context) {
    final bandings = allAjuanList.where((a) => a.status == 'menunggu_banding').toList();
    final api = context.read<ApiService>();

    if (bandings.isEmpty) return const SizedBox.shrink();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            const Text(
              'Permintaan Banding Dosen',
              style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: AppColors.textPrimary),
            ),
            const SizedBox(width: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
              decoration: BoxDecoration(
                color: const Color(0xFFFFF7ED),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: const Color(0xFFFDBA74)),
              ),
              child: Text(
                '${bandings.length} Banding',
                style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Color(0xFFEA580C)),
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),

        ...bandings.map((aj) {
          return Container(
            margin: const EdgeInsets.only(bottom: 10),
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: const Color(0xFFFDBA74)),
              boxShadow: const [
                BoxShadow(color: Color(0x06EA580C), blurRadius: 4, offset: Offset(0, 1)),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        aj.mataKuliahNama,
                        style: const TextStyle(fontSize: 13.5, fontWeight: FontWeight.bold, color: Color(0xFF0F172A)),
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                      decoration: BoxDecoration(
                        color: const Color(0xFFFFF7ED),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: const Text('Banding', style: TextStyle(fontSize: 10.5, fontWeight: FontWeight.bold, color: Color(0xFFEA580C))),
                    ),
                  ],
                ),
                const SizedBox(height: 5),
                Row(
                  children: [
                    const Icon(Icons.person_outline_rounded, size: 14, color: Color(0xFF475569)),
                    const SizedBox(width: 5),
                    Expanded(
                      child: Text(
                        aj.dosenNama,
                        style: const TextStyle(fontSize: 12.5, fontWeight: FontWeight.bold, color: Color(0xFF1E293B)),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 2),
                Text(
                  aj.fakultasNama,
                  style: const TextStyle(fontSize: 11, color: Color(0xFF64748B)),
                ),
                const SizedBox(height: 4),
                Text(
                  'Jadwal Saat Ini: ${aj.hari}, ${aj.waktuFormatted} (${aj.ruanganNama})',
                  style: const TextStyle(fontSize: 11.5, fontWeight: FontWeight.w600, color: Color(0xFF0F172A)),
                ),
                const SizedBox(height: 8),

                // Alasan Banding Card
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: const Color(0xFFFFF7ED),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: const Color(0xFFFFEDD5)),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Alasan: ${aj.alasanBanding ?? "-"}', style: const TextStyle(fontSize: 11.5, color: Color(0xFF7C2D12))),
                      if (aj.preferensiBandingHari != null || aj.preferensiBandingJam != null) ...[
                        const SizedBox(height: 3),
                        Text('Preferensi Waktu: ${aj.preferensiBandingHari ?? "-"}, ${aj.preferensiBandingJam ?? "-"}', style: const TextStyle(fontSize: 11.5, fontWeight: FontWeight.bold, color: Color(0xFF7C2D12))),
                      ],
                    ],
                  ),
                ),
                const SizedBox(height: 10),

                // Action Buttons
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton(
                        style: OutlinedButton.styleFrom(
                          foregroundColor: AppColors.error,
                          padding: const EdgeInsets.symmetric(vertical: 8),
                          side: const BorderSide(color: Color(0xFFFECACA)),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                        ),
                        onPressed: () async {
                          await api.adminProcessBanding(
                            ajuanId: aj.id,
                            approve: false,
                            catatanAdmin: 'Permohonan banding ditolak oleh Admin.',
                          );
                          await onRefreshData();
                        },
                        child: const Text('Tolak Banding', style: TextStyle(fontSize: 11.5, fontWeight: FontWeight.bold)),
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
                        onPressed: () {
                          AjuanPengajaranDialogs.showEditDialog(
                            context: context,
                            ajuan: aj,
                            currentRole: 'admin',
                            onSaved: (updated) async {
                              await api.adminProcessBanding(
                                ajuanId: aj.id,
                                approve: true,
                                catatanAdmin: 'Banding disetujui dan jadwal telah disesuaikan.',
                                updatedData: updated,
                              );
                              await onRefreshData();
                            },
                          );
                        },
                        icon: const Icon(Icons.edit_outlined, size: 15),
                        label: const Text('Ubah & Setujui', style: TextStyle(fontSize: 11.5, fontWeight: FontWeight.bold)),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          );
        }),
      ],
    );
  }
}
