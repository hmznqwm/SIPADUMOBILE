import 'package:flutter/material.dart';
import '../../../../data/models/jadwal_model.dart';

class ScheduleCard extends StatelessWidget {
  final JadwalModel item;

  const ScheduleCard({
    super.key,
    required this.item,
  });

  int get _durasiMenit {
    if (item.jamMulai.contains(':') && item.jamSelesai.contains(':')) {
      try {
        final p1 = item.jamMulai.split(':');
        final p2 = item.jamSelesai.split(':');
        final m1 = int.parse(p1[0]) * 60 + int.parse(p1[1]);
        final m2 = int.parse(p2[0]) * 60 + int.parse(p2[1]);
        if (m2 > m1) return m2 - m1;
      } catch (_) {}
    }
    return item.sks > 0 ? item.sks * 50 : 100;
  }

  @override
  Widget build(BuildContext context) {
    // Format start time & end time
    final startStr = item.jamMulai.isNotEmpty ? item.jamMulai : '07:30';
    final endStr = item.jamSelesai.isNotEmpty ? item.jamSelesai : '10:00';

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: const Color(0xFFE2E8F0)),
        boxShadow: const [
          BoxShadow(
            color: Color(0x08000000),
            blurRadius: 12,
            offset: Offset(0, 3),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(18),
        child: IntrinsicHeight(
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // ── 1. Left Split Chrono Block (Mint Box - Dynamic Height) ──
              Container(
                width: 86,
                padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 6),
                decoration: const BoxDecoration(
                  color: Color(0xFFECFDF5), // Soft Mint
                ),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    const Text(
                      'MULAI',
                      style: TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.w800,
                        letterSpacing: 0.6,
                        color: Color(0xFF047857),
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      startStr,
                      style: const TextStyle(
                        fontSize: 16.5,
                        fontWeight: FontWeight.w800,
                        color: Color(0xFF064E3B),
                      ),
                    ),
                    const SizedBox(height: 4),
                    Container(
                      width: 14,
                      height: 2.5,
                      decoration: BoxDecoration(
                        color: const Color(0xFFA7F3D0),
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      endStr,
                      style: const TextStyle(
                        fontSize: 12.5,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF047857),
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      '$_durasiMenit mnt',
                      style: const TextStyle(
                        fontSize: 10.5,
                        fontWeight: FontWeight.w500,
                        color: Color(0xFF059669),
                      ),
                    ),
                  ],
                ),
              ),

              // ── 2. Right Main Details Column ──
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.all(12),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Top Row: Status Badge (Left) & SKS Badge (Right)
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: [
                          // Status Badge Pill
                          Flexible(
                            child: Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                              decoration: BoxDecoration(
                                color: item.statusBadgeBgColor,
                                borderRadius: BorderRadius.circular(6),
                                border: Border.all(
                                  color: item.statusBadgeTextColor.withValues(alpha: 0.25),
                                  width: 1,
                                ),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(
                                    item.statusBadgeIcon,
                                    size: 11,
                                    color: item.statusBadgeTextColor,
                                  ),
                                  const SizedBox(width: 4),
                                  Flexible(
                                    child: Text(
                                      item.statusBadgeText,
                                      style: TextStyle(
                                        fontSize: 10.5,
                                        fontWeight: FontWeight.bold,
                                        color: item.statusBadgeTextColor,
                                      ),
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                          const SizedBox(width: 6),
                          // SKS Badge
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                            decoration: BoxDecoration(
                              color: const Color(0xFFF1F5F9),
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: Text(
                              '${item.sks} SKS',
                              style: const TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.bold,
                                color: Color(0xFF475569),
                              ),
                            ),
                          ),
                        ],
                      ),

                      const SizedBox(height: 8),

                      // Course Title
                      Text(
                        item.mataKuliahNama.isNotEmpty ? item.mataKuliahNama : 'Mata Kuliah',
                        style: const TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF0F172A),
                          height: 1.25,
                        ),
                      ),

                      if (item.dosenNama != null && item.dosenNama!.isNotEmpty) ...[
                        const SizedBox(height: 4),
                        Text(
                          item.dosenNama!,
                          style: const TextStyle(
                            fontSize: 12.5,
                            fontWeight: FontWeight.w600,
                            color: Color(0xFF334155),
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                      if (item.jurusanNama != null && item.jurusanNama!.isNotEmpty) ...[
                        const SizedBox(height: 2),
                        Text(
                          'Prodi ${item.jurusanNama}',
                          style: const TextStyle(
                            fontSize: 11.5,
                            fontWeight: FontWeight.w500,
                            color: Color(0xFF64748B),
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],

                      const SizedBox(height: 6),

                      // Class Badge & Student Count Row
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
                            decoration: BoxDecoration(
                              color: const Color(0xFFEFF6FF),
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: Text(
                              'Kelas ${item.kelasNama.isNotEmpty ? item.kelasNama : "-"}',
                              style: const TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.bold,
                                color: Color(0xFF1D4ED8),
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Text(
                            '${item.jumlahMahasiswa} Mahasiswa',
                            style: const TextStyle(
                              fontSize: 11.5,
                              fontWeight: FontWeight.w500,
                              color: Color(0xFF64748B),
                            ),
                          ),
                        ],
                      ),

                      const SizedBox(height: 8),

                      // Divider Line
                      const Divider(height: 1, thickness: 1, color: Color(0xFFF1F5F9)),

                      const SizedBox(height: 8),

                      // Location Section (Full Gedung & Ruangan Details)
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Gedung Row
                          Row(
                            children: [
                              const Icon(
                                Icons.domain_rounded,
                                size: 14,
                                color: Color(0xFF475569),
                              ),
                              const SizedBox(width: 5),
                              Expanded(
                                child: Text(
                                  item.gedungNama.isNotEmpty ? item.gedungNama : '-',
                                  style: const TextStyle(
                                    fontSize: 11.5,
                                    fontWeight: FontWeight.bold,
                                    color: Color(0xFF1E293B),
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 4),
                          // Ruangan Row
                          Row(
                            children: [
                              const Icon(
                                Icons.meeting_room_rounded,
                                size: 14,
                                color: Color(0xFF0F766E),
                              ),
                              const SizedBox(width: 5),
                              Expanded(
                                child: Text(
                                  item.ruanganNama.isNotEmpty ? item.ruanganNama : '-',
                                  style: const TextStyle(
                                    fontSize: 11.5,
                                    fontWeight: FontWeight.w600,
                                    color: Color(0xFF0F766E),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
