import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../../data/models/jadwal_model.dart';

class ScheduleCard extends StatefulWidget {
  final JadwalModel item;

  const ScheduleCard({
    super.key,
    required this.item,
  });

  @override
  State<ScheduleCard> createState() => _ScheduleCardState();
}

class _ScheduleCardState extends State<ScheduleCard> {
  bool _isExpanded = false;

  @override
  Widget build(BuildContext context) {
    final item = widget.item;
    final rawStart = item.jamMulai.isNotEmpty ? item.jamMulai : '07:00';
    final rawEnd = item.jamSelesai.isNotEmpty ? item.jamSelesai : '09:00';

    // Format jam dengan titik sesuai foto (misal: 07.00-09.00)
    final startFormatted = rawStart.replaceAll(':', '.');
    final endFormatted = rawEnd.replaceAll(':', '.');
    final timeStr = '$startFormatted-$endFormatted';

    final cleanKelas = item.kelasNama.trim().toLowerCase().startsWith('kelas')
        ? item.kelasNama.trim()
        : (item.kelasNama.trim().isNotEmpty
            ? 'Kelas ${item.kelasNama.trim()}'
            : '');

    // Format Gedung & Ruang
    String locationStr = '';
    if (item.gedungNama.isNotEmpty && item.ruanganNama.isNotEmpty) {
      locationStr = '${item.gedungNama} ${item.ruanganNama}';
    } else if (item.gedungNama.isNotEmpty) {
      locationStr = item.gedungNama;
    } else if (item.ruanganNama.isNotEmpty) {
      locationStr = item.ruanganNama;
    } else {
      locationStr = 'Gedung A R.106';
    }

    final dosenStr = (item.dosenNama != null && item.dosenNama!.isNotEmpty)
        ? item.dosenNama!
        : 'Dosen Pengampu';

    final matkulStr = item.mataKuliahNama.isNotEmpty
        ? item.mataKuliahNama
        : 'Mata Kuliah';

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: const Color(0xFFF1F5F9),
          width: 1,
        ),
        boxShadow: const [
          BoxShadow(
            color: Color(0x06000000),
            blurRadius: 10,
            offset: Offset(0, 3),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(20),
        child: InkWell(
          borderRadius: BorderRadius.circular(20),
          onTap: () {
            setState(() {
              _isExpanded = !_isExpanded;
            });
          },
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 18),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // ── Header Row ──
                Row(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    Expanded(
                      child: Row(
                        children: [
                          Flexible(
                            child: Text(
                              matkulStr,
                              style: GoogleFonts.plusJakartaSans(
                                fontSize: 15.5,
                                fontWeight: FontWeight.w700,
                                color: const Color(0xFF2D3748),
                              ),
                            ),
                          ),
                          if (item.ruanganNama.toLowerCase().contains('rti') ||
                              item.gedungNama.toLowerCase().contains('virtual') ||
                              item.ruanganNama.toLowerCase().contains('daring')) ...[
                            const SizedBox(width: 8),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                              decoration: BoxDecoration(
                                color: const Color(0xFFF5F3FF),
                                borderRadius: BorderRadius.circular(6),
                                border: Border.all(color: const Color(0xFFDDD6FE)),
                              ),
                              child: const Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(Icons.videocam_rounded, size: 11, color: Color(0xFF7C3AED)),
                                  SizedBox(width: 3),
                                  Text(
                                    'RTI',
                                    style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Color(0xFF7C3AED)),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),
                    const SizedBox(width: 12),
                    Text(
                      timeStr,
                      textAlign: TextAlign.right,
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 13,
                        fontWeight: FontWeight.w500,
                        color: const Color(0xFF94A3B8),
                      ),
                    ),
                  ],
                ),

                // ── Expanded Content (Sesuai Desain Foto) ──
                if (_isExpanded) ...[
                  const SizedBox(height: 10),
                  Text(
                    dosenStr,
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 13.5,
                      fontWeight: FontWeight.w500,
                      color: const Color(0xFF94A3B8),
                      height: 1.35,
                    ),
                  ),
                  const SizedBox(height: 3),
                  Text(
                    timeStr,
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 13.5,
                      fontWeight: FontWeight.w500,
                      color: const Color(0xFF94A3B8),
                      height: 1.35,
                    ),
                  ),
                  const SizedBox(height: 3),
                  Text(
                    locationStr,
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 13.5,
                      fontWeight: FontWeight.w500,
                      color: const Color(0xFF94A3B8),
                      height: 1.35,
                    ),
                  ),
                  if (cleanKelas.isNotEmpty || item.sks > 0) ...[
                    const SizedBox(height: 3),
                    Text(
                      [
                        if (cleanKelas.isNotEmpty) cleanKelas,
                        if (item.sks > 0) '${item.sks} SKS',
                        if (item.jurusanNama != null && item.jurusanNama!.isNotEmpty)
                          item.jurusanNama!,
                      ].join(' • '),
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 12.5,
                        fontWeight: FontWeight.w500,
                        color: const Color(0xFF94A3B8),
                        height: 1.35,
                      ),
                    ),
                  ],
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}
