// File: admin_stat_cards.dart
// Deskripsi: Widget kartu statistik institusi kampus pada Dashboard Admin.

import 'package:flutter/material.dart';

import '../../../../config/constants.dart';
import '../../../../data/mock/mock_database.dart';
import '../../../../data/models/ajuan_pengajaran_model.dart';
import '../../../../data/models/gedung_model.dart';
import '../../../../data/models/jadwal_model.dart';
import '../../../../data/models/ruangan_model.dart';
import '../../../../data/models/user_model.dart';

class AdminStatCards extends StatelessWidget {
  final List<GedungModel> gedungList;
  final List<RuanganModel> ruanganList;
  final List<UserModel> allUsersList;
  final List<dynamic> allMatkulList;
  final List<AjuanPengajaranModel> allAjuanList;
  final List<JadwalModel> jadwalList;

  const AdminStatCards({
    super.key,
    required this.gedungList,
    required this.ruanganList,
    required this.allUsersList,
    this.allMatkulList = const [],
    this.allAjuanList = const [],
    this.jadwalList = const [],
  });

  @override
  Widget build(BuildContext context) {
    final dosenPengajarCount = allUsersList
        .where((u) => u.role == 'dosen' || u.role == 'kajur' || u.role == 'dekan')
        .length;
    final totalDosenCount = dosenPengajarCount;

    final totalGedungCount = gedungList.length;
    final totalRuanganCount = ruanganList.length;

    final fakultasSet = <String>{};
    final prodiSet = <String>{};
    for (final u in allUsersList) {
      if (u.fakultasNama.isNotEmpty) fakultasSet.add(u.fakultasNama);
      if (u.jurusanNama.isNotEmpty) prodiSet.add(u.jurusanNama);
    }

    final totalFakultasCount = fakultasSet.length;
    final totalProdiCount = prodiSet.length;
    final totalMatkulCount = allMatkulList.length;

    // Kumpulkan seluruh nama ruangan yang telah dialokasikan / terjadwal
    final usedRoomNames = <String>{};
    for (final j in jadwalList) {
      if (j.ruanganNama.trim().isNotEmpty) usedRoomNames.add(j.ruanganNama.trim().toLowerCase());
    }
    for (final j in MockDatabase.jadwalFinal) {
      if (j.ruanganNama.trim().isNotEmpty) usedRoomNames.add(j.ruanganNama.trim().toLowerCase());
    }
    for (final j in MockDatabase.jadwalGlobalMaster) {
      if (j.ruanganNama.trim().isNotEmpty) usedRoomNames.add(j.ruanganNama.trim().toLowerCase());
    }
    for (final a in allAjuanList) {
      if ((a.status == 'disetujui_admin' || a.status == 'banding_disetujui' || a.status == 'diverifikasi_kaprodi' || a.status == 'disetujui_dekan') &&
          a.ruanganNama.trim().isNotEmpty) {
        usedRoomNames.add(a.ruanganNama.trim().toLowerCase());
      }
    }

    int countTerpakai = 0;
    for (final r in ruanganList) {
      final rLower = r.nama.trim().toLowerCase();
      if (usedRoomNames.any((u) => u == rLower || u.contains(rLower) || rLower.contains(u))) {
        countTerpakai++;
      }
    }
    if (countTerpakai == 0 && usedRoomNames.isNotEmpty) {
      countTerpakai = usedRoomNames.length;
    }
    if (totalRuanganCount > 0 && countTerpakai > totalRuanganCount) {
      countTerpakai = totalRuanganCount;
    }

    final ruanganTerpakaiCount = totalRuanganCount == 0 ? 0 : countTerpakai;
    final ruanganKosongCount = totalRuanganCount == 0
        ? 0
        : (totalRuanganCount >= ruanganTerpakaiCount
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
