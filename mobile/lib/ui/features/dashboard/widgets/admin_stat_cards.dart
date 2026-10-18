// File: admin_stat_cards.dart
// Deskripsi: Widget kartu statistik institusi kampus pada Dashboard Admin dengan Bento Grid Dinamis.

import 'package:flutter/material.dart';

import '../../../../config/constants.dart';
import '../../../../data/mock/mock_database.dart';
import '../../../../data/models/ajuan_pengajaran_model.dart';
import '../../../../data/models/gedung_model.dart';
import '../../../../data/models/jadwal_model.dart';
import '../../../../data/models/mata_kuliah_model.dart';
import '../../../../data/models/ruangan_model.dart';
import '../../../../data/models/user_model.dart';

class AdminStatCards extends StatelessWidget {
  final List<GedungModel> gedungList;
  final List<RuanganModel> ruanganList;
  final List<UserModel> allUsersList;
  final List<dynamic> allMatkulList;
  final List<Map<String, dynamic>> fakultasList;
  final List<AjuanPengajaranModel> allAjuanList;
  final List<JadwalModel> jadwalList;

  const AdminStatCards({
    super.key,
    required this.gedungList,
    required this.ruanganList,
    required this.allUsersList,
    this.allMatkulList = const [],
    this.fakultasList = const [],
    this.allAjuanList = const [],
    this.jadwalList = const [],
  });

  @override
  Widget build(BuildContext context) {
    // 1. Hitung Dosen Aktif (Filter deleted user IDs, names, and emails)
    final effectiveUsersList = allUsersList.where((u) =>
        !MockDatabase.deletedUserIds.contains(u.id) &&
        !MockDatabase.deletedUserIds.contains(u.nama) &&
        !MockDatabase.deletedUserIds.contains(u.email)).toList();

    final dosenPengajarCount = effectiveUsersList
        .where((u) => u.role == 'dosen' || u.role == 'kajur' || u.role == 'dekan')
        .length;
    final totalDosenCount = dosenPengajarCount;

    // 2. Hitung Ruangan Aktif (Filter deleted room & building IDs)
    final effectiveRuanganList = ruanganList
        .where((r) =>
            !MockDatabase.deletedRuanganIds.contains(r.id) &&
            !MockDatabase.deletedRuanganIds.contains(r.nama) &&
            (r.gedungId.isEmpty || !MockDatabase.deletedGedungIds.contains(r.gedungId)) &&
            (r.gedungNama.isEmpty || !MockDatabase.deletedGedungIds.contains(r.gedungNama)))
        .toList();

    final totalRuanganCount = effectiveRuanganList.length;

    // 3. Hitung Fakultas & Program Studi Aktif
    final effectiveFakultasList = fakultasList
        .where((f) {
          final id = f['id']?.toString() ?? '';
          final nama = f['nama']?.toString() ?? '';
          return !MockDatabase.deletedFakultasIds.contains(id) &&
              !MockDatabase.deletedFakultasIds.contains(nama);
        })
        .toList();

    final totalFakultasCount = effectiveFakultasList.length;

    final prodiSet = <String>{};
    for (final f in effectiveFakultasList) {
      final jurRaw = f['jurusan'];
      if (jurRaw is List) {
        for (final item in jurRaw) {
          final str = item.toString().trim();
          if (str.isNotEmpty && str != 'Semua' && str != 'GLOBAL') {
            prodiSet.add(str.toLowerCase());
          }
        }
      } else if (jurRaw is String) {
        for (final item in jurRaw.split(',')) {
          final str = item.trim();
          if (str.isNotEmpty && str != 'Semua' && str != 'GLOBAL') {
            prodiSet.add(str.toLowerCase());
          }
        }
      }
    }
    final totalProdiCount = prodiSet.length;

    // 4. Hitung Mata Kuliah Aktif
    final effectiveMatkulList = allMatkulList.where((m) {
      final id = (m is Map ? (m['id'] ?? m['kode']) : (m is MataKuliahModel ? m.id : ''))?.toString() ?? '';
      final nama = (m is Map ? m['nama'] : (m is MataKuliahModel ? m.nama : ''))?.toString() ?? '';
      return !MockDatabase.deletedMatkulIds.contains(id) &&
          !MockDatabase.deletedMatkulIds.contains(nama);
    }).toList();

    final totalMatkulCount = effectiveMatkulList.length;

    // 5. Kumpulkan seluruh nama ruangan yang telah dialokasikan / terjadwal
    final usedRoomNames = <String>{};
    for (final j in jadwalList) {
      if (!MockDatabase.deletedJadwalIds.contains(j.id) &&
          !MockDatabase.deletedMatkulIds.contains(j.mataKuliahId) &&
          !MockDatabase.deletedMatkulIds.contains(j.mataKuliahNama) &&
          j.ruanganNama.trim().isNotEmpty) {
        usedRoomNames.add(j.ruanganNama.trim().toLowerCase());
      }
    }
    for (final a in allAjuanList) {
      if (!MockDatabase.deletedAjuanIds.contains(a.id) &&
          !MockDatabase.deletedMatkulIds.contains(a.mataKuliahId) &&
          !MockDatabase.deletedMatkulIds.contains(a.mataKuliahNama) &&
          (a.status == 'disetujui_admin' || a.status == 'banding_disetujui') &&
          a.ruanganNama.trim().isNotEmpty) {
        usedRoomNames.add(a.ruanganNama.trim().toLowerCase());
      }
    }

    int countTerpakai = 0;
    for (final r in effectiveRuanganList) {
      final rLower = r.nama.trim().toLowerCase();
      final rId = r.id.trim().toLowerCase();
      if (usedRoomNames.any((u) =>
          u == rLower ||
          u == rId ||
          (u.isNotEmpty && (u.contains(rLower) || rLower.contains(u))))) {
        countTerpakai++;
      }
    }
    if (countTerpakai > totalRuanganCount) {
      countTerpakai = totalRuanganCount;
    }

    final ruanganTerpakaiCount = countTerpakai;
    final ruanganKosongCount = totalRuanganCount >= ruanganTerpakaiCount
        ? totalRuanganCount - ruanganTerpakaiCount
        : 0;

    final double ratioKosong =
        totalRuanganCount > 0 ? (ruanganKosongCount / totalRuanganCount) : 1.0;
    final double ratioTerpakai =
        totalRuanganCount > 0 ? (ruanganTerpakaiCount / totalRuanganCount) : 0.0;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Statistik Institusi',
          style: TextStyle(
            fontSize: 15,
            fontWeight: FontWeight.bold,
            color: AppColors.textPrimary,
            letterSpacing: -0.2,
          ),
        ),
        const SizedBox(height: 10),

        // ── 1. Hero Card: Ketersediaan Ruangan (Clean White Card with Line Comparison Bar) ──
        Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: const Color(0xFFE2E8F0)),
            boxShadow: const [
              BoxShadow(
                color: Color(0x05000000),
                blurRadius: 4,
                offset: Offset(0, 2),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Ketersediaan Ruangan',
                style: TextStyle(
                  color: Color(0xFF0F172A),
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                  letterSpacing: -0.1,
                ),
              ),
              const SizedBox(height: 10),

              // Baris Perbandingan Garis (Visual Comparison Bar)
              ClipRRect(
                borderRadius: BorderRadius.circular(6),
                child: SizedBox(
                  height: 6,
                  child: totalRuanganCount == 0
                      ? Container(color: const Color(0xFFE2E8F0))
                      : Row(
                          children: [
                            if (ruanganKosongCount > 0)
                              Expanded(
                                flex: (ratioKosong * 100).round().clamp(1, 100),
                                child: Container(color: AppColors.primary),
                              ),
                            if (ruanganKosongCount > 0 && ruanganTerpakaiCount > 0)
                              const SizedBox(width: 2),
                            if (ruanganTerpakaiCount > 0)
                              Expanded(
                                flex: (ratioTerpakai * 100).round().clamp(1, 100),
                                child: Container(color: const Color(0xFF94A3B8)),
                              ),
                          ],
                        ),
                ),
              ),
              const SizedBox(height: 12),

              // Keterangan Jumlah Kosong vs Terpakai
              Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Container(
                              width: 7,
                              height: 7,
                              decoration: const BoxDecoration(
                                color: AppColors.primary,
                                shape: BoxShape.circle,
                              ),
                            ),
                            const SizedBox(width: 6),
                            const Text(
                              'Ruangan Kosong',
                              style: TextStyle(
                                color: Color(0xFF64748B),
                                fontSize: 11.5,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 3),
                        Text(
                          '$ruanganKosongCount Ruang',
                          style: const TextStyle(
                            color: Color(0xFF0F172A),
                            fontSize: 17,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Container(
                    width: 1,
                    height: 28,
                    color: const Color(0xFFE2E8F0),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Container(
                              width: 7,
                              height: 7,
                              decoration: const BoxDecoration(
                                color: Color(0xFF94A3B8),
                                shape: BoxShape.circle,
                              ),
                            ),
                            const SizedBox(width: 6),
                            const Text(
                              'Ruangan Terpakai',
                              style: TextStyle(
                                color: Color(0xFF64748B),
                                fontSize: 11.5,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 3),
                        Text(
                          '$ruanganTerpakaiCount Ruang',
                          style: const TextStyle(
                            color: Color(0xFF0F172A),
                            fontSize: 17,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
        const SizedBox(height: 10),

        // ── 2. Row 1: 2 White Cards (Fakultas & Program Studi) ──
        Row(
          children: [
            Expanded(
              child: _buildWhiteBentoCard(
                title: 'Fakultas',
                count: '$totalFakultasCount',
                subtitle: 'Fakultas',
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: _buildWhiteBentoCard(
                title: 'Program Studi',
                count: '$totalProdiCount',
                subtitle: 'Program Studi',
              ),
            ),
          ],
        ),
        const SizedBox(height: 10),

        // ── 3. Row 2: 2 White Cards (Mata Kuliah & Dosen Pengajar) ──
        Row(
          children: [
            Expanded(
              child: _buildWhiteBentoCard(
                title: 'Mata Kuliah',
                count: '$totalMatkulCount',
                subtitle: 'Mata Kuliah',
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: _buildWhiteBentoCard(
                title: 'Dosen',
                count: '$totalDosenCount',
                subtitle: 'Dosen Pengajar',
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildWhiteBentoCard({
    required String title,
    required String count,
    required String subtitle,
  }) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE2E8F0)),
        boxShadow: const [
          BoxShadow(
            color: Color(0x05000000),
            blurRadius: 4,
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              color: Color(0xFF1E293B),
              fontSize: 12.5,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            count,
            style: const TextStyle(
              color: Color(0xFF0F172A),
              fontSize: 24,
              fontWeight: FontWeight.w800,
              letterSpacing: -0.5,
              height: 1.1,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            subtitle,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              color: Color(0xFF64748B),
              fontSize: 11,
            ),
          ),
        ],
      ),
    );
  }
}
