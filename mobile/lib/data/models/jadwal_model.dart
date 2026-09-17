// File: jadwal_model.dart
// Deskripsi: Model data untuk hasil penjadwalan kuliah yang ter-generate atau terdaftar.
// Fungsi: Menyimpan entitas jadwal seperti nama mata kuliah, SKS, ruangan, gedung, kelas, hari, jam, jumlah mahasiswa, dan status workflow persetujuan (KaProdi -> Dekan -> Admin).

import 'package:flutter/material.dart';

class JadwalModel {
  final String id;
  final String mataKuliahId;
  final String mataKuliahNama;
  final int sks;
  final String? ruanganId;
  final String ruanganNama;
  final String? gedungId;
  final String gedungNama;
  final String kelasNama;
  final String hari;
  final String jamMulai;
  final String jamSelesai;
  final String semesterNama;
  final int jumlahMahasiswa;
  final String? dosenId;
  final String? dosenNama;
  final String? fakultasNama;
  final String? jurusanNama;
  final String status;

  const JadwalModel({
    required this.id,
    required this.mataKuliahId,
    required this.mataKuliahNama,
    required this.sks,
    this.ruanganId,
    required this.ruanganNama,
    this.gedungId,
    required this.gedungNama,
    required this.kelasNama,
    required this.hari,
    required this.jamMulai,
    required this.jamSelesai,
    required this.semesterNama,
    this.jumlahMahasiswa = 0,
    this.dosenId,
    this.dosenNama,
    this.fakultasNama,
    this.jurusanNama,
    this.status = 'disetujui_admin',
  });

  JadwalModel copyWith({
    String? id,
    String? mataKuliahId,
    String? mataKuliahNama,
    int? sks,
    String? ruanganId,
    String? ruanganNama,
    String? gedungId,
    String? gedungNama,
    String? kelasNama,
    String? hari,
    String? jamMulai,
    String? jamSelesai,
    String? semesterNama,
    int? jumlahMahasiswa,
    String? dosenId,
    String? dosenNama,
    String? fakultasNama,
    String? jurusanNama,
    String? status,
  }) {
    return JadwalModel(
      id: id ?? this.id,
      mataKuliahId: mataKuliahId ?? this.mataKuliahId,
      mataKuliahNama: mataKuliahNama ?? this.mataKuliahNama,
      sks: sks ?? this.sks,
      ruanganId: ruanganId ?? this.ruanganId,
      ruanganNama: ruanganNama ?? this.ruanganNama,
      gedungId: gedungId ?? this.gedungId,
      gedungNama: gedungNama ?? this.gedungNama,
      kelasNama: kelasNama ?? this.kelasNama,
      hari: hari ?? this.hari,
      jamMulai: jamMulai ?? this.jamMulai,
      jamSelesai: jamSelesai ?? this.jamSelesai,
      semesterNama: semesterNama ?? this.semesterNama,
      jumlahMahasiswa: jumlahMahasiswa ?? this.jumlahMahasiswa,
      dosenId: dosenId ?? this.dosenId,
      dosenNama: dosenNama ?? this.dosenNama,
      fakultasNama: fakultasNama ?? this.fakultasNama,
      jurusanNama: jurusanNama ?? this.jurusanNama,
      status: status ?? this.status,
    );
  }

  String get waktu {
    if (jamMulai.isNotEmpty && jamSelesai.isNotEmpty) {
      return '$jamMulai - $jamSelesai';
    } else if (jamMulai.isNotEmpty) {
      return jamMulai;
    }
    return 'Waktu Belum Diatur';
  }

  String get lokasi {
    final parts = [ruanganNama, gedungNama].where((s) => s.trim().isNotEmpty).toList();
    if (parts.isNotEmpty) {
      return parts.join(', ');
    }
    return 'Ruangan Belum Ditentukan';
  }

  bool get isApproved {
    final s = status.toLowerCase();
    return s == 'disetujui_admin' || s == 'disetujui' || s == 'terjadwal_resmi' || s == 'final';
  }

  String get statusBadgeText {
    final s = status.toLowerCase();
    if (s == 'disetujui_admin' || s == 'disetujui' || s == 'terjadwal_resmi' || s == 'final') {
      return 'Disetujui Admin';
    } else if (s == 'menunggu_admin' || s == 'disetujui_dekan') {
      return 'Disetujui Dekan';
    } else if (s == 'menunggu_dekan' || s == 'diverifikasi_kaprodi') {
      return 'Disetujui KaProdi';
    } else if (s == 'menunggu_kaprodi' || s == 'diajukan' || s == 'draft') {
      return 'Menunggu KaProdi';
    } else if (s == 'bentrok_terdeteksi') {
      return 'Bentrok';
    } else if (s.startsWith('ditolak')) {
      return 'Ditolak';
    }
    return 'Proses Validasi';
  }

  Color get statusBadgeBgColor {
    final s = status.toLowerCase();
    if (isApproved) {
      return const Color(0xFFECFDF5); // Emerald 50
    } else if (s == 'menunggu_kaprodi' || s == 'diajukan' || s == 'draft') {
      return const Color(0xFFFFFBEB); // Amber 50
    } else if (s == 'menunggu_dekan' || s == 'diverifikasi_kaprodi') {
      return const Color(0xFFEFF6FF); // Blue 50
    } else if (s == 'menunggu_admin' || s == 'disetujui_dekan') {
      return const Color(0xFFEEF2FF); // Indigo 50
    } else if (s.startsWith('ditolak') || s == 'bentrok_terdeteksi') {
      return const Color(0xFFFEF2F2); // Red 50
    }
    return const Color(0xFFF1F5F9); // Slate 100
  }

  Color get statusBadgeTextColor {
    final s = status.toLowerCase();
    if (isApproved) {
      return const Color(0xFF059669); // Emerald 600
    } else if (s == 'menunggu_kaprodi' || s == 'diajukan' || s == 'draft') {
      return const Color(0xFFD97706); // Amber 600
    } else if (s == 'menunggu_dekan' || s == 'diverifikasi_kaprodi') {
      return const Color(0xFF2563EB); // Blue 600
    } else if (s == 'menunggu_admin' || s == 'disetujui_dekan') {
      return const Color(0xFF4F46E5); // Indigo 600
    } else if (s.startsWith('ditolak') || s == 'bentrok_terdeteksi') {
      return const Color(0xFFDC2626); // Red 600
    }
    return const Color(0xFF475569); // Slate 600
  }

  IconData get statusBadgeIcon {
    final s = status.toLowerCase();
    if (isApproved) {
      return Icons.verified_rounded;
    } else if (s == 'menunggu_kaprodi' || s == 'diajukan') {
      return Icons.hourglass_top_rounded;
    } else if (s == 'menunggu_dekan' || s == 'diverifikasi_kaprodi') {
      return Icons.assignment_turned_in_rounded;
    } else if (s == 'menunggu_admin' || s == 'disetujui_dekan') {
      return Icons.admin_panel_settings_rounded;
    } else if (s.startsWith('ditolak') || s == 'bentrok_terdeteksi') {
      return Icons.cancel_rounded;
    }
    return Icons.info_outline_rounded;
  }

  factory JadwalModel.fromJson(Map<String, dynamic> json) {
    return JadwalModel(
      id: json['id']?.toString() ?? '',
      mataKuliahId: json['mataKuliahId']?.toString() ?? json['mata_kuliah_id']?.toString() ?? '',
      mataKuliahNama: json['mataKuliahNama']?.toString() ?? json['mata_kuliah_nama']?.toString() ?? '',
      sks: int.tryParse(json['sks']?.toString() ?? '0') ?? 0,
      ruanganId: json['ruanganId']?.toString() ?? json['ruangan_id']?.toString(),
      ruanganNama: json['ruanganNama']?.toString() ?? json['ruangan_nama']?.toString() ?? '',
      gedungId: json['gedungId']?.toString() ?? json['gedung_id']?.toString(),
      gedungNama: json['gedungNama']?.toString() ?? json['gedung_nama']?.toString() ?? '',
      kelasNama: json['kelasNama']?.toString() ?? json['kelas_nama']?.toString() ?? '',
      hari: json['hari']?.toString() ?? '',
      jamMulai: json['jamMulai']?.toString() ?? json['jam_mulai']?.toString() ?? '',
      jamSelesai: json['jamSelesai']?.toString() ?? json['jam_selesai']?.toString() ?? '',
      semesterNama: json['semesterNama']?.toString() ?? json['semester_nama']?.toString() ?? '',
      jumlahMahasiswa: int.tryParse(json['jumlahMahasiswa']?.toString() ?? json['jumlah_mahasiswa']?.toString() ?? '0') ?? 0,
      dosenId: json['dosenId']?.toString() ?? json['dosen_id']?.toString(),
      dosenNama: json['dosenNama']?.toString() ?? json['dosen_nama']?.toString(),
      fakultasNama: json['fakultasNama']?.toString() ?? json['fakultas_nama']?.toString(),
      jurusanNama: json['jurusanNama']?.toString() ?? json['jurusan_nama']?.toString(),
      status: json['status']?.toString() ?? 'disetujui_admin',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'mataKuliahId': mataKuliahId,
      'mata_kuliah_id': mataKuliahId,
      'mataKuliahNama': mataKuliahNama,
      'mata_kuliah_nama': mataKuliahNama,
      'sks': sks,
      'ruanganId': ruanganId,
      'ruangan_id': ruanganId,
      'ruanganNama': ruanganNama,
      'ruangan_nama': ruanganNama,
      'gedungId': gedungId,
      'gedung_id': gedungId,
      'gedungNama': gedungNama,
      'gedung_nama': gedungNama,
      'kelasNama': kelasNama,
      'kelas_nama': kelasNama,
      'hari': hari,
      'jamMulai': jamMulai,
      'jam_mulai': jamMulai,
      'jamSelesai': jamSelesai,
      'jam_selesai': jamSelesai,
      'semesterNama': semesterNama,
      'semester_nama': semesterNama,
      'jumlahMahasiswa': jumlahMahasiswa,
      'jumlah_mahasiswa': jumlahMahasiswa,
      'dosenId': dosenId,
      'dosen_id': dosenId,
      'dosenNama': dosenNama,
      'dosen_nama': dosenNama,
      'fakultasNama': fakultasNama,
      'fakultas_nama': fakultasNama,
      'jurusanNama': jurusanNama,
      'jurusan_nama': jurusanNama,
      'status': status,
    };
  }
}
