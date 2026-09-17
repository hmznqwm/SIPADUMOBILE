// File: ruangan_kosong_section.dart
// Deskripsi: Widget monitoring ketersediaan ruangan kampus per hari dan jam kosong.
// Fungsi: Menampilkan daftar ruangan kelas & lab yang tersedia, filter per hari, kapasitas, dan status.

import 'package:flutter/material.dart';
import '../../../../config/constants.dart';

class RuanganKosongSection extends StatefulWidget {
  final String title;
  final String subtitle;
  final List<Map<String, dynamic>> ruanganList;

  const RuanganKosongSection({
    super.key,
    required this.title,
    required this.subtitle,
    this.ruanganList = const [],
  });

  @override
  State<RuanganKosongSection> createState() => _RuanganKosongSectionState();
}

class _RuanganKosongSectionState extends State<RuanganKosongSection> {
  String _ruanganDayFilter = 'Semua';
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final filteredRooms = widget.ruanganList.where((r) {
      final matchDay = _ruanganDayFilter == 'Semua' ||
          (r['hariKosong'] as List<String>? ?? []).contains(_ruanganDayFilter);
      if (!matchDay) return false;

      if (_searchQuery.isEmpty) return true;
      final query = _searchQuery.toLowerCase();
      final nama = (r['nama'] ?? '').toString().toLowerCase();
      final gedung = (r['gedung'] ?? '').toString().toLowerCase();
      final kode = (r['kode'] ?? '').toString().toLowerCase();
      final fasilitas = (r['fasilitas'] ?? '').toString().toLowerCase();
      return nama.contains(query) ||
          gedung.contains(query) ||
          kode.contains(query) ||
          fasilitas.contains(query);
    }).toList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          widget.title,
          style: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: Color(0xFF0F172A),
          ),
        ),
        const SizedBox(height: 3),
        Text(
          widget.subtitle,
          style: const TextStyle(
            fontSize: 12,
            color: Color(0xFF64748B),
          ),
        ),
        const SizedBox(height: 12),

        // ── Modern Compact Filter Container (Identik dengan Tab Pengajuan Dosen) ──
        Container(
          margin: const EdgeInsets.only(bottom: 12),
          padding: const EdgeInsets.symmetric(
            horizontal: 12,
            vertical: 10,
          ),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: const Color(0xFFE2E8F0)),
            boxShadow: const [
              BoxShadow(
                color: Color(0x04000000),
                blurRadius: 4,
                offset: Offset(0, 2),
              ),
            ],
          ),
          child: Column(
            children: [
              // 1. Search Bar Ruangan & Gedung
              Container(
                height: 38,
                decoration: BoxDecoration(
                  color: const Color(0xFFF8FAFC),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: const Color(0xFFCBD5E1)),
                ),
                child: TextField(
                  controller: _searchController,
                  onChanged: (val) => setState(() => _searchQuery = val),
                  style: const TextStyle(
                    fontSize: 12,
                    color: Color(0xFF0F172A),
                    fontWeight: FontWeight.w500,
                  ),
                  decoration: InputDecoration(
                    isDense: true,
                    hintText: 'Cari nama ruangan, gedung, fasilitas...',
                    hintStyle: const TextStyle(
                      fontSize: 11.5,
                      color: Color(0xFF94A3B8),
                    ),
                    prefixIcon: const Icon(
                      Icons.search_rounded,
                      color: AppColors.primary,
                      size: 17,
                    ),
                    prefixIconConstraints: const BoxConstraints(
                      minWidth: 32,
                      minHeight: 32,
                    ),
                    suffixIcon: _searchQuery.isNotEmpty
                        ? IconButton(
                            icon: const Icon(
                              Icons.clear_rounded,
                              size: 15,
                              color: Color(0xFF94A3B8),
                            ),
                            onPressed: () {
                              _searchController.clear();
                              setState(() => _searchQuery = '');
                            },
                          )
                        : null,
                    suffixIconConstraints: const BoxConstraints(
                      minWidth: 32,
                      minHeight: 32,
                    ),
                    border: InputBorder.none,
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 9,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 8),

              // 2. Dropdown Filter Hari
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10),
                decoration: BoxDecoration(
                  color: const Color(0xFFF8FAFC),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(
                    color: _ruanganDayFilter != 'Semua'
                        ? AppColors.primary
                        : const Color(0xFFCBD5E1),
                  ),
                ),
                child: DropdownButtonHideUnderline(
                  child: DropdownButton<String>(
                    value: _ruanganDayFilter,
                    isExpanded: true,
                    icon: const Icon(
                      Icons.keyboard_arrow_down_rounded,
                      size: 18,
                      color: Color(0xFF64748B),
                    ),
                    style: const TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: Color(0xFF1E293B),
                    ),
                    items: const [
                      DropdownMenuItem(
                        value: 'Semua',
                        child: Text('Semua Hari (Senin - Sabtu)'),
                      ),
                      DropdownMenuItem(
                        value: 'Senin',
                        child: Text('Hari Senin'),
                      ),
                      DropdownMenuItem(
                        value: 'Selasa',
                        child: Text('Hari Selasa'),
                      ),
                      DropdownMenuItem(
                        value: 'Rabu',
                        child: Text('Hari Rabu'),
                      ),
                      DropdownMenuItem(
                        value: 'Kamis',
                        child: Text('Hari Kamis'),
                      ),
                      DropdownMenuItem(
                        value: 'Jumat',
                        child: Text('Hari Jumat'),
                      ),
                      DropdownMenuItem(
                        value: 'Sabtu',
                        child: Text('Hari Sabtu'),
                      ),
                    ],
                    onChanged: (val) {
                      if (val != null) {
                        setState(() => _ruanganDayFilter = val);
                      }
                    },
                  ),
                ),
              ),
            ],
          ),
        ),

        // Daftar Ruangan
        if (filteredRooms.isEmpty)
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(vertical: 36, horizontal: 16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: const Color(0xFFE2E8F0)),
            ),
            child: Column(
              children: [
                Icon(
                  Icons.meeting_room_outlined,
                  size: 40,
                  color: Colors.grey.shade400,
                ),
                const SizedBox(height: 8),
                Text(
                  'Tidak ada ruangan kosong pada hari $_ruanganDayFilter',
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 13,
                    color: Color(0xFF0F172A),
                  ),
                ),
              ],
            ),
          )
        else
          Column(
            children: filteredRooms.map((r) {
              final days = (r['hariKosong'] as List<String>? ?? []);
              final bool isAvailToday = _ruanganDayFilter == 'Semua' ||
                  days.contains(_ruanganDayFilter);
              final displayHari = isAvailToday && _ruanganDayFilter != 'Semua'
                  ? 'Tersedia Hari $_ruanganDayFilter'
                  : (r['hariFormatted'] ?? 'Senin - Sabtu');
              final displayJam = r['jamKosong'] ?? '07:30 - 16:20 WIB';

              return Container(
                margin: const EdgeInsets.only(bottom: 10),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: const Color(0xFFE2E8F0)),
                  boxShadow: const [
                    BoxShadow(
                      color: Color(0x05000000),
                      blurRadius: 6,
                      offset: Offset(0, 2),
                    ),
                  ],
                ),
                child: Padding(
                  padding: const EdgeInsets.all(12),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.all(8),
                                decoration: BoxDecoration(
                                  color: AppColors.primary.withValues(alpha: 0.1),
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: const Icon(
                                  Icons.meeting_room_rounded,
                                  color: AppColors.primary,
                                  size: 20,
                                ),
                              ),
                              const SizedBox(width: 10),
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    r['nama'],
                                    style: const TextStyle(
                                      fontSize: 15,
                                      fontWeight: FontWeight.bold,
                                      color: Color(0xFF0F172A),
                                    ),
                                  ),
                                  Text(
                                    '${r['gedung']} • ${r['lantai']}',
                                    style: const TextStyle(
                                      fontSize: 11.5,
                                      color: Color(0xFF64748B),
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 3,
                            ),
                            decoration: BoxDecoration(
                              color: const Color(0xFFECFDF5),
                              borderRadius: BorderRadius.circular(6),
                              border: Border.all(
                                color: const Color(0xFFA7F3D0),
                              ),
                            ),
                            child: const Text(
                              'Kosong',
                              style: TextStyle(
                                fontSize: 10.5,
                                fontWeight: FontWeight.bold,
                                color: Color(0xFF059669),
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 10),
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 7,
                              vertical: 2,
                            ),
                            decoration: BoxDecoration(
                              color: const Color(0xFFF1F5F9),
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: Text(
                              r['tipe'],
                              style: const TextStyle(
                                fontSize: 10.5,
                                color: Color(0xFF475569),
                              ),
                            ),
                          ),
                          const SizedBox(width: 6),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 7,
                              vertical: 2,
                            ),
                            decoration: BoxDecoration(
                              color: const Color(0xFFEFF6FF),
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: Text(
                              'Kapasitas ${r['kapasitas']} Kursi',
                              style: const TextStyle(
                                fontSize: 10.5,
                                fontWeight: FontWeight.w600,
                                color: Color(0xFF2563EB),
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      // Badge Keterangan Hari & Jam Kosong
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 7,
                        ),
                        decoration: BoxDecoration(
                          color: const Color(0xFFF0FDFA),
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: const Color(0xFFCCFBF1)),
                        ),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.center,
                          children: [
                            const Icon(
                              Icons.calendar_month_rounded,
                              size: 15,
                              color: Color(0xFF0F766E),
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                '$displayHari • $displayJam',
                                style: const TextStyle(
                                  fontSize: 11.5,
                                  fontWeight: FontWeight.w600,
                                  color: Color(0xFF0F766E),
                                  height: 1.3,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              );
            }).toList(),
          ),
      ],
    );
  }
}
