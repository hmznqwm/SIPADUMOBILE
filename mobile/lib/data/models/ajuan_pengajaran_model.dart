// File: ajuan_pengajaran_model.dart
// Deskripsi: Model data untuk pengajuan jam & ruang pengajaran dosen serta alur approval multi-tier (Dosen -> KaProdi -> Dekan -> Admin).
// Fungsi: Menyimpan entitas ajuan pengajaran mencakup mata kuliah, hari, jam, gedung, ruangan, semester, jumlah siswa, dan status persetujuan institusi.

class AjuanPengajaranModel {
  final String id;
  final String dosenId;
  final String dosenNama;
  final String fakultasNama;
  final String jurusanNama;
  final String mataKuliahId;
  final String mataKuliahNama;
  final int sks;
  final String hari; // 'Senin', 'Selasa', 'Rabu', 'Kamis', 'Jumat', 'Sabtu'
  final String jamMulai; // '07:30'
  final String jamSelesai; // '10:00'
  final String gedungNama; // 'Gedung Soekarno (A)'
  final String ruanganNama; // 'R.301'
  final int semester; // 1 - 8
  final String kelasNama; // 'TI-3A'
  final int jumlahMahasiswa; // 35
  final String status; // 'menunggu_kaprodi', 'menunggu_dekan', 'menunggu_admin', 'disetujui_admin', 'ditolak_kaprodi', 'ditolak_dekan', 'ditolak_admin', 'bentrok_terdeteksi', 'menunggu_banding', 'banding_disetujui', 'banding_ditolak'
  final String? catatanDosen;
  final String? catatanKaProdi;
  final String? catatanDekan;
  final String? catatanAdmin;
  final String? alasanPenolakan;
  final String? alasanBanding;
  final String? preferensiBandingHari;
  final String? preferensiBandingJam;
  final String? bentrokDetail;
  final DateTime submittedAt;
  final DateTime? updatedAt;

  const AjuanPengajaranModel({
    required this.id,
    required this.dosenId,
    required this.dosenNama,
    required this.fakultasNama,
    required this.jurusanNama,
    required this.mataKuliahId,
    required this.mataKuliahNama,
    required this.sks,
    required this.hari,
    required this.jamMulai,
    required this.jamSelesai,
    required this.gedungNama,
    required this.ruanganNama,
    required this.semester,
    required this.kelasNama,
    required this.jumlahMahasiswa,
    this.status = 'menunggu_kaprodi',
    this.catatanDosen,
    this.catatanKaProdi,
    this.catatanDekan,
    this.catatanAdmin,
    this.alasanPenolakan,
    this.alasanBanding,
    this.preferensiBandingHari,
    this.preferensiBandingJam,
    this.bentrokDetail,
    required this.submittedAt,
    this.updatedAt,
  });

  String get waktuFormatted => '$jamMulai - $jamSelesai WIB';
  String get lokasiFormatted => '$ruanganNama ($gedungNama)';

  String get statusDisplay {
    switch (status) {
      case 'menunggu_kaprodi':
        return 'Menunggu KaProdi';
      case 'menunggu_dekan':
        return 'Menuju Dekan';
      case 'menunggu_admin':
        return 'Menuju Admin';
      case 'disetujui_admin':
        return 'Disetujui Admin';
      case 'bentrok_terdeteksi':
        return 'Bentrok';
      case 'menunggu_banding':
        return 'Banding Dosen';
      case 'banding_disetujui':
        return 'Banding Diterima';
      case 'banding_ditolak':
        return 'Banding Ditolak';
      case 'ditolak_kaprodi':
        return 'Ditolak KaProdi';
      case 'ditolak_dekan':
        return 'Ditolak Dekan';
      case 'ditolak_admin':
        return 'Ditolak Admin';
      default:
        return 'Draft';
    }
  }

  AjuanPengajaranModel copyWith({
    String? id,
    String? dosenId,
    String? dosenNama,
    String? fakultasNama,
    String? jurusanNama,
    String? mataKuliahId,
    String? mataKuliahNama,
    int? sks,
    String? hari,
    String? jamMulai,
    String? jamSelesai,
    String? gedungNama,
    String? ruanganNama,
    int? semester,
    String? kelasNama,
    int? jumlahMahasiswa,
    String? status,
    String? catatanDosen,
    String? catatanKaProdi,
    String? catatanDekan,
    String? catatanAdmin,
    String? alasanPenolakan,
    String? alasanBanding,
    String? preferensiBandingHari,
    String? preferensiBandingJam,
    String? bentrokDetail,
    bool clearBentrokDetail = false,
    bool clearAlasanPenolakan = false,
    bool clearAlasanBanding = false,
    DateTime? submittedAt,
    DateTime? updatedAt,
  }) {
    return AjuanPengajaranModel(
      id: id ?? this.id,
      dosenId: dosenId ?? this.dosenId,
      dosenNama: dosenNama ?? this.dosenNama,
      fakultasNama: fakultasNama ?? this.fakultasNama,
      jurusanNama: jurusanNama ?? this.jurusanNama,
      mataKuliahId: mataKuliahId ?? this.mataKuliahId,
      mataKuliahNama: mataKuliahNama ?? this.mataKuliahNama,
      sks: sks ?? this.sks,
      hari: hari ?? this.hari,
      jamMulai: jamMulai ?? this.jamMulai,
      jamSelesai: jamSelesai ?? this.jamSelesai,
      gedungNama: gedungNama ?? this.gedungNama,
      ruanganNama: ruanganNama ?? this.ruanganNama,
      semester: semester ?? this.semester,
      kelasNama: kelasNama ?? this.kelasNama,
      jumlahMahasiswa: jumlahMahasiswa ?? this.jumlahMahasiswa,
      status: status ?? this.status,
      catatanDosen: catatanDosen ?? this.catatanDosen,
      catatanKaProdi: catatanKaProdi ?? this.catatanKaProdi,
      catatanDekan: catatanDekan ?? this.catatanDekan,
      catatanAdmin: catatanAdmin ?? this.catatanAdmin,
      alasanPenolakan: clearAlasanPenolakan ? null : (alasanPenolakan ?? this.alasanPenolakan),
      alasanBanding: clearAlasanBanding ? null : (alasanBanding ?? this.alasanBanding),
      preferensiBandingHari: preferensiBandingHari ?? this.preferensiBandingHari,
      preferensiBandingJam: preferensiBandingJam ?? this.preferensiBandingJam,
      bentrokDetail: clearBentrokDetail ? null : (bentrokDetail ?? this.bentrokDetail),
      submittedAt: submittedAt ?? this.submittedAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  factory AjuanPengajaranModel.fromJson(Map<String, dynamic> json) {
    return AjuanPengajaranModel(
      id: (json['id'] ?? '').toString(),
      dosenId: (json['dosenId'] ?? json['dosen_id'] ?? '').toString(),
      dosenNama: (json['dosenNama'] ?? json['dosen_nama'] ?? '').toString(),
      fakultasNama: (json['fakultasNama'] ?? json['fakultas_nama'] ?? '').toString(),
      jurusanNama: (json['jurusanNama'] ?? json['jurusan_nama'] ?? '').toString(),
      mataKuliahId: (json['mataKuliahId'] ?? json['mata_kuliah_id'] ?? '').toString(),
      mataKuliahNama: (json['mataKuliahNama'] ?? json['mata_kuliah_nama'] ?? '').toString(),
      sks: int.tryParse((json['sks'] ?? '3').toString()) ?? 3,
      hari: (json['hari'] ?? 'Senin').toString(),
      jamMulai: (json['jamMulai'] ?? json['jam_mulai'] ?? '07:30').toString(),
      jamSelesai: (json['jamSelesai'] ?? json['jam_selesai'] ?? '10:00').toString(),
      gedungNama: (json['gedungNama'] ?? json['gedung_nama'] ?? '').toString(),
      ruanganNama: (json['ruanganNama'] ?? json['ruangan_nama'] ?? '').toString(),
      semester: int.tryParse((json['semester'] ?? '1').toString()) ?? 1,
      kelasNama: (json['kelasNama'] ?? json['kelas_nama'] ?? 'A').toString(),
      jumlahMahasiswa: int.tryParse((json['jumlahMahasiswa'] ?? json['jumlah_mahasiswa'] ?? '30').toString()) ?? 30,
      status: (json['status'] ?? 'menunggu_kaprodi').toString(),
      catatanDosen: (json['catatanDosen'] ?? json['catatan_dosen'])?.toString(),
      catatanKaProdi: (json['catatanKaProdi'] ?? json['catatan_kaprodi'])?.toString(),
      catatanDekan: (json['catatanDekan'] ?? json['catatan_dekan'])?.toString(),
      catatanAdmin: (json['catatanAdmin'] ?? json['catatan_admin'])?.toString(),
      alasanPenolakan: (json['alasanPenolakan'] ?? json['alasan_penolakan'])?.toString(),
      alasanBanding: (json['alasanBanding'] ?? json['alasan_banding'])?.toString(),
      preferensiBandingHari: (json['preferensiBandingHari'] ?? json['preferensi_banding_hari'])?.toString(),
      preferensiBandingJam: (json['preferensiBandingJam'] ?? json['preferensi_banding_jam'])?.toString(),
      bentrokDetail: (json['bentrokDetail'] ?? json['bentrok_detail'])?.toString(),
      submittedAt: json['submittedAt'] != null
          ? DateTime.tryParse(json['submittedAt'].toString()) ?? DateTime.now()
          : (json['created_at'] != null ? DateTime.tryParse(json['created_at'].toString()) ?? DateTime.now() : DateTime.now()),
      updatedAt: json['updatedAt'] != null
          ? DateTime.tryParse(json['updatedAt'].toString())
          : (json['updated_at'] != null ? DateTime.tryParse(json['updated_at'].toString()) : null),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'dosenId': dosenId,
      'dosenNama': dosenNama,
      'fakultasNama': fakultasNama,
      'jurusanNama': jurusanNama,
      'mataKuliahId': mataKuliahId,
      'mataKuliahNama': mataKuliahNama,
      'sks': sks,
      'hari': hari,
      'jamMulai': jamMulai,
      'jamSelesai': jamSelesai,
      'gedungNama': gedungNama,
      'ruanganNama': ruanganNama,
      'semester': semester,
      'kelasNama': kelasNama,
      'jumlahMahasiswa': jumlahMahasiswa,
      'status': status,
      'catatanDosen': catatanDosen,
      'catatanKaProdi': catatanKaProdi,
      'catatanDekan': catatanDekan,
      'catatanAdmin': catatanAdmin,
      'alasanPenolakan': alasanPenolakan,
      'alasanBanding': alasanBanding,
      'preferensiBandingHari': preferensiBandingHari,
      'preferensiBandingJam': preferensiBandingJam,
      'bentrokDetail': bentrokDetail,
      'submittedAt': submittedAt.toIso8601String(),
      'updatedAt': updatedAt?.toIso8601String(),
    };
  }
}
