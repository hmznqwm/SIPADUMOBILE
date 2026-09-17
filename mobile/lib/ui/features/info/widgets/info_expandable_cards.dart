// File: info_expandable_cards.dart
// Deskripsi: Widget kartu interaktif accordion/expandable untuk informasi biodata, aplikasi, jam operasional, dan aturan mutex.

import 'package:flutter/material.dart';

import '../../../../config/constants.dart';
import '../../../../data/models/user_model.dart';

class InfoExpandableCards extends StatelessWidget {
  final UserModel? user;

  const InfoExpandableCards({
    super.key,
    required this.user,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        // ── Interactive Expandable Card 1: Biodata Profil Dosen / Pegawai ──
        _buildExpandableCard(
          context: context,
          icon: Icons.person_outline_rounded,
          title: 'Biodata & Identitas Pegawai',
          subtitle: 'NIDN, Email, Jurusan & Fakultas',
          children: [
            _buildDetailRow('Nomor Induk (NIDN / NIP)', user?.id ?? '198503152010121003'),
            _buildDetailRow('Email Resmi Instansi', user?.email ?? 'dosen@university.ac.id', valueColor: AppColors.primary),
            _buildDetailRow('Program Studi', user?.jurusanNama ?? 'Teknik Informatika'),
            _buildDetailRow('Fakultas', user?.fakultasNama ?? 'Fakultas Sains & Teknologi'),
            _buildDetailRow('Status Keaktifan', 'Aktif SIPADU', valueColor: AppColors.available),
            _buildDetailRow('Semester Aktif', 'Ganjil 2026/2027', isLast: true),
          ],
        ),
        const SizedBox(height: AppSpacing.md),

        // ── Interactive Expandable Card 2: Tentang Aplikasi ──
        _buildExpandableCard(
          context: context,
          icon: Icons.info_outline_rounded,
          title: 'Tentang Aplikasi',
          subtitle: 'SIPADU v1.6',
          children: [
            const Text(
              'SIPADU (Sistem Informasi Penjadwalan Dosen) v1.6 adalah sistem penjadwalan perkuliahan otomatis berbasis Constraint Satisfaction Problem (CSP) & Backtracking untuk alokasi waktu dan ruangan tanpa bentrok.',
              textAlign: TextAlign.justify,
              style: TextStyle(fontSize: 12, color: AppColors.textSecondary, height: 1.5),
            ),
            const SizedBox(height: 10),
            _buildBulletPoint('Algoritma CSP & Backtracking cerdas untuk kalkulasi alokasi jadwal.', boldPrefix: 'Mesin Otomatis:'),
            _buildBulletPoint('Deteksi instan bentrok jadwal dosen, ruangan, dan rombel.', boldPrefix: 'Bebas Bentrok:'),
            _buildBulletPoint('Sinkronisasi data kehadiran dan ketersediaan mengajar.', boldPrefix: 'Ketersediaan Dosen:', isLast: true),
          ],
        ),
        const SizedBox(height: AppSpacing.md),

        // ── Interactive Expandable Card 3: Jam Operasional ──
        _buildExpandableCard(
          context: context,
          icon: Icons.schedule_outlined,
          title: 'Jam Operasional',
          subtitle: 'Senin - Jumat (06.30 - 16.30 WIB)',
          children: [
            _buildBulletPoint('Senin s.d. Jumat (Hari Sabtu dan Minggu Libur Akademik).', boldPrefix: 'Hari Perkuliahan:'),
            _buildBulletPoint('Seluruh kegiatan perkuliahan berakhir maksimal pukul 16.30 WIB.', boldPrefix: 'Batas Selesai:'),
            _buildBulletPoint('Sesi perkuliahan berlangsung pukul 09.50 – 16.30 WIB.', boldPrefix: 'Gedung A, B, C, D, E:'),
            _buildBulletPoint('Khusus melayani slot perkuliahan pagi mulai pukul 06.30 – 16.30 WIB.', boldPrefix: 'Gedung F (Slot Pagi):', isLast: true),
          ],
        ),
        const SizedBox(height: AppSpacing.md),

        // ── Interactive Expandable Card 4: Aturan Mutex ──
        _buildExpandableCard(
          context: context,
          icon: Icons.shield_outlined,
          title: 'Aturan Bebas Bentrok',
          subtitle: 'Prinsip Mutex Dosen, Ruangan & Rombel',
          children: [
            _buildBulletPoint('Dosen pengampu tidak dapat mengajar pada 2 kelas berbeda di slot waktu yang sama.', boldPrefix: 'Mutex Dosen:'),
            _buildBulletPoint('Satu ruang kuliah hanya digunakan untuk 1 kegiatan pembelajaran dalam satu slot waktu.', boldPrefix: 'Mutex Ruangan:'),
            _buildBulletPoint('Rombongan belajar (rombel) mahasiswa tidak memiliki 2 jadwal perkuliahan yang bertabrakan.', boldPrefix: 'Mutex Rombel:', isLast: true),
          ],
        ),
      ],
    );
  }

  Widget _buildExpandableCard({
    required BuildContext context,
    required IconData icon,
    required String title,
    required String subtitle,
    required List<Widget> children,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.cardBackground,
        borderRadius: BorderRadius.circular(AppRadius.lg),
        border: Border.all(color: AppColors.border),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(AppRadius.lg),
        child: Theme(
          data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
          child: ExpansionTile(
            showTrailingIcon: false,
            shape: const RoundedRectangleBorder(side: BorderSide.none),
            collapsedShape: const RoundedRectangleBorder(side: BorderSide.none),
            tilePadding: const EdgeInsets.symmetric(
              horizontal: AppSpacing.lg,
              vertical: AppSpacing.xs,
            ),
            leading: Container(
              padding: const EdgeInsets.all(AppSpacing.xs + 2),
              decoration: const BoxDecoration(
                color: AppColors.surfaceVariant,
                shape: BoxShape.circle,
              ),
              child: Icon(icon, size: 20, color: AppColors.primary),
            ),
            title: Text(
              title,
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.bold,
                color: AppColors.textPrimary,
              ),
            ),
            subtitle: Text(
              subtitle,
              style: const TextStyle(
                fontSize: 11,
                color: AppColors.textTertiary,
              ),
            ),
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(
                  AppSpacing.lg,
                  0,
                  AppSpacing.lg,
                  AppSpacing.lg,
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: children,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildDetailRow(String label, String value, {Color? valueColor, bool isLast = false}) {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 8.0),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                label,
                style: const TextStyle(
                  fontSize: 13,
                  color: AppColors.textSecondary,
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(width: 12),
              Flexible(
                child: Text(
                  value,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  textAlign: TextAlign.end,
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.bold,
                    color: valueColor ?? AppColors.textPrimary,
                  ),
                ),
              ),
            ],
          ),
        ),
        if (!isLast)
          Container(
            height: 1,
            color: AppColors.surfaceVariant,
          ),
      ],
    );
  }

  Widget _buildBulletPoint(String text, {String? boldPrefix, bool isLast = false}) {
    return Padding(
      padding: EdgeInsets.only(bottom: isLast ? 0 : 8.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            margin: const EdgeInsets.only(top: 6, right: 10),
            width: 6,
            height: 6,
            decoration: const BoxDecoration(
              color: AppColors.primary,
              shape: BoxShape.circle,
            ),
          ),
          Expanded(
            child: RichText(
              textAlign: TextAlign.justify,
              text: TextSpan(
                style: const TextStyle(
                  fontSize: 12,
                  color: AppColors.textSecondary,
                  height: 1.5,
                ),
                children: [
                  if (boldPrefix != null)
                    TextSpan(
                      text: '$boldPrefix ',
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        color: AppColors.textPrimary,
                      ),
                    ),
                  TextSpan(text: text),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
