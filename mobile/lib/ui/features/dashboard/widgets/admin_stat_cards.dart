// File: admin_stat_cards.dart
// Deskripsi: Widget kartu statistik institusi kampus pada Dashboard Admin.

import 'package:flutter/material.dart';

import '../../../../config/constants.dart';
import '../../../../data/mock/mock_database.dart';
import '../../../../data/models/gedung_model.dart';
import '../../../../data/models/ruangan_model.dart';
import '../../../../data/models/user_model.dart';

class AdminStatCards extends StatelessWidget {
  final List<GedungModel> gedungList;
  final List<RuanganModel> ruanganList;
  final List<UserModel> allUsersList;

  const AdminStatCards({
    super.key,
    required this.gedungList,
    required this.ruanganList,
    required this.allUsersList,
  });

  @override
  Widget build(BuildContext context) {
    final dosenPengajarCount = allUsersList
        .where((u) => u.role == 'dosen' || u.role == 'kajur' || u.role == 'dekan')
        .length;
    final totalDosenCount = dosenPengajarCount;

    final effectiveGedungList = gedungList.isNotEmpty ? gedungList : MockDatabase.gedungList;
    final activeGedungIds = effectiveGedungList.map((g) => g.id.trim()).where((id) => id.isNotEmpty).toSet();
    final activeGedungNames = effectiveGedungList.map((g) => g.nama.trim().toLowerCase()).where((n) => n.isNotEmpty).toSet();

    final sourceRuanganList = ruanganList.isNotEmpty ? ruanganList : MockDatabase.ruanganList;
    final effectiveRuanganList = sourceRuanganList.where((r) {
      final rid = r.id.trim().toUpperCase();
      if (!rid.startsWith('RNG_')) return false;
      if (MockDatabase.deletedRuanganIds.contains(r.id) || MockDatabase.deletedRuanganIds.contains(r.nama)) return false;
      if (MockDatabase.deletedGedungIds.contains(r.gedungId) || MockDatabase.deletedGedungIds.contains(r.gedungNama)) return false;

      final matchId = r.gedungId.isNotEmpty && activeGedungIds.contains(r.gedungId.trim());
      final matchNama = r.gedungNama.isNotEmpty && activeGedungNames.contains(r.gedungNama.trim().toLowerCase());
      return matchId || matchNama;
    }).toList();

    final totalGedungCount = effectiveGedungList.length;
    final totalRuanganCount = effectiveRuanganList.length;
    final totalFakultasCount = MockDatabase.fakultasData.length;
    final totalProdiCount = MockDatabase.fakultasData.fold<int>(
        0, (sum, f) => sum + ((f['jurusan'] as List?)?.length ?? 0));
    final totalMatkulCount = MockDatabase.matkulData.length;

    final usedRooms = MockDatabase.jadwalGlobalMaster
        .map((j) => j.ruanganNama)
        .where((r) => r.isNotEmpty)
        .toSet()
        .length;
    final ruanganTerpakaiCount = totalRuanganCount == 0
        ? 0
        : (usedRooms <= totalRuanganCount ? usedRooms : totalRuanganCount);
    final ruanganKosongCount = totalRuanganCount == 0
        ? 0
        : (totalRuanganCount > ruanganTerpakaiCount
            ? totalRuanganCount - ruanganTerpakaiCount
            : 0);

    final stats = [
      {
        'title': 'Fakultas',
        'value': '$totalFakultasCount Fakultas',
        'subtitle': 'Fakultas Aktif',
        'icon': Icons.account_balance_outlined,
        'color': AppColors.primary,
        'bg': const Color(0xFFF0FDFA),
      },
      {
        'title': 'Program Studi',
        'value': '$totalProdiCount Prodi',
        'subtitle': 'Jurusan Terdaftar',
        'icon': Icons.account_tree_outlined,
        'color': AppColors.primary,
        'bg': const Color(0xFFF0FDFA),
      },
      {
        'title': 'Gedung Kampus',
        'value': '$totalGedungCount Gedung',
        'subtitle': 'Gedung & Lab',
        'icon': Icons.apartment_rounded,
        'color': AppColors.primary,
        'bg': const Color(0xFFF0FDFA),
      },
      {
        'title': 'Total Ruangan & Kelas',
        'value': '$totalRuanganCount Ruang',
        'subtitle': 'Kelas Teori & Lab',
        'icon': Icons.door_sliding_outlined,
        'color': AppColors.primary,
        'bg': const Color(0xFFF0FDFA),
      },
      {
        'title': 'Ruangan Kosong',
        'value': '$ruanganKosongCount Ruang',
        'subtitle': 'Siap Digunakan',
        'icon': Icons.meeting_room_outlined,
        'color': AppColors.primary,
        'bg': const Color(0xFFF0FDFA),
      },
      {
        'title': 'Ruangan Terpakai',
        'value': '$ruanganTerpakaiCount Ruang',
        'subtitle': 'Sesi Perkuliahan',
        'icon': Icons.event_seat_outlined,
        'color': AppColors.primary,
        'bg': const Color(0xFFF0FDFA),
      },
      {
        'title': 'Mata Kuliah',
        'value': '$totalMatkulCount Matkul',
        'subtitle': 'Total Matkul Kampus',
        'icon': Icons.menu_book_rounded,
        'color': AppColors.primary,
        'bg': const Color(0xFFF0FDFA),
      },
      {
        'title': 'Dosen Pengajar',
        'value': '$totalDosenCount Dosen',
        'subtitle': 'Dosen, Kaprodi, Dekan',
        'icon': Icons.people_alt_outlined,
        'color': AppColors.primary,
        'bg': const Color(0xFFF0FDFA),
      },
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Statistik Institusi',
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.bold,
            color: AppColors.textPrimary,
          ),
        ),
        const SizedBox(height: 10),
        Column(
          children: stats.map((item) {
            final color = item['color'] as Color;
            final bg = item['bg'] as Color;

            return Container(
              width: double.infinity,
              margin: const EdgeInsets.only(bottom: 8),
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: const Color(0xFFE2E8F0), width: 1.1),
                boxShadow: const [
                  BoxShadow(
                    color: Color(0x04000000),
                    blurRadius: 3,
                    offset: Offset(0, 1),
                  ),
                ],
              ),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: bg,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Icon(
                      item['icon'] as IconData,
                      color: color,
                      size: 20,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          item['title'] as String,
                          style: const TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF0F172A),
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 1),
                        Text(
                          item['subtitle'] as String,
                          style: const TextStyle(
                            fontSize: 11,
                            color: Color(0xFF64748B),
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 8),
                  Container(
                    width: 105,
                    alignment: Alignment.center,
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
                    decoration: BoxDecoration(
                      color: bg,
                      borderRadius: BorderRadius.circular(6),
                      border: Border.all(color: color.withValues(alpha: 0.25)),
                    ),
                    child: Text(
                      item['value'] as String,
                      textAlign: TextAlign.center,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w800,
                        color: color,
                      ),
                    ),
                  ),
                ],
              ),
            );
          }).toList(),
        ),
      ],
    );
  }
}
