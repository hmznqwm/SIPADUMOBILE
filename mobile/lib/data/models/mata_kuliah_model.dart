// File: mata_kuliah_model.dart
// Deskripsi: Model data untuk mata kuliah yang diajarkan dalam perkuliahan.
// Fungsi: Memuat detail mata kuliah seperti nama, bobot SKS, jurusan, semester, tipe sesi (reguler/split), dan kebutuhan ruangan.

import '../../utils/academic_year_helper.dart';

class MataKuliahModel {
  final String id;
  final String nama;
  final int sks;
  final int semester;
  final String jurusanId;
  final String jurusanNama;
  final String fakultasNama;
  final String dosenId;
  final String? dosenNama;
  final String semesterId;
  final String tipeSesi; // 'reguler' or 'split'
  final String jenis; // 'Teori' or 'Praktikum'
  final String? kebutuhanTipeRuangan;
  final List<String> kelasIds;
  final List<String> kelasNama;

  bool get isSemesterGanjil => semester % 2 != 0;
  bool get isSemesterGenap => semester % 2 == 0;

  /// Mengecek apakah mata kuliah ini adalah Praktikum / Laboratorium / Bengkel
  bool get isPraktikum =>
      jenis.toLowerCase() == 'praktikum' ||
      AcademicYearHelper.isPraktikum(
        matkulNama: nama,
        tipeRuangan: kebutuhanTipeRuangan,
        jenis: jenis,
        fakultasNama: fakultasNama,
        jurusanNama: jurusanNama,
      );

  /// Durasi menit per 1 SKS (90 menit untuk Praktikum, 50 menit untuk Teori)
  int get durasiMenitPerSks => isPraktikum ? 90 : 50;

  /// Total durasi menit mata kuliah (SKS * menit per SKS)
  int get totalDurasiMenit => sks * durasiMenitPerSks;

  /// Label ringkas durasi mata kuliah untuk tampilan UI
  String get labelDurasi => isPraktikum
      ? '$sks SKS • ${sks * 90} Mnt (Praktikum)'
      : '$sks SKS • ${sks * 50} Mnt (Teori)';

  /// Badge tipe perkuliahan
  String get badgeJenis => isPraktikum ? 'Praktikum' : 'Teori';

  /// Jumlah slot matriks (1 slot = 50 menit) yang dibutuhkan untuk SATU pertemuan/kelas.
  /// Teori: 1 SKS = 1 slot. Praktikum: 1 SKS = 90 menit = 2 slot (dibulatkan ke atas).
  int get slotPerPertemuan {
    if (sks <= 0) return 1;
    return isPraktikum ? ((sks * 90) / 50).ceil() : sks;
  }

  /// Jumlah kelas paralel yang diampu (minimal 1).
  int get jumlahKelas => kelasNama.isEmpty ? 1 : kelasNama.length;

  /// Total slot yang wajib dipilih dosen untuk mata kuliah ini (seluruh kelas).
  int get totalSlotDibutuhkan => slotPerPertemuan * jumlahKelas;

  const MataKuliahModel({
    required this.id,
    required this.nama,
    required this.sks,
    this.semester = 1,
    required this.jurusanId,
    required this.jurusanNama,
    this.fakultasNama = '',
    this.dosenId = '',
    this.dosenNama,
    required this.semesterId,
    this.tipeSesi = 'reguler',
    this.jenis = 'Teori',
    this.kebutuhanTipeRuangan,
    this.kelasIds = const [],
    this.kelasNama = const [],
  });

  factory MataKuliahModel.fromJson(Map<String, dynamic> json) {
    List<String> parseStringList(dynamic val) {
      if (val is List) {
        if (val.isEmpty) return [];
        if (val.first is Map) {
          return val
              .map((e) => (e['kelas_nama'] ?? e['nama'] ?? e['name'] ?? '').toString())
              .where((s) => s.isNotEmpty)
              .toList();
        }
        return val.map((e) => e.toString()).toList();
      }
      if (val is String && val.isNotEmpty) {
        return val.split(',').map((e) => e.trim()).toList();
      }
      return [];
    }

    final parsedKelas = parseStringList(json['mata_kuliah_kelas'] ?? json['kelasNama'] ?? json['kelas_nama'] ?? json['kelas']);
    final parsedSemester = int.tryParse(json['semester']?.toString() ?? '') ??
        int.tryParse(json['semester_angka']?.toString() ?? '') ??
        int.tryParse(json['semester_id']?.toString().replaceAll(RegExp(r'[^0-9]'), '') ?? '') ??
        1;

    final namaVal = json['nama']?.toString() ?? '';
    final fakVal = json['fakultasNama']?.toString() ?? json['fakultas_nama'] ?? json['fakultas']?.toString() ?? '';
    final jurVal = json['jurusanNama']?.toString() ?? json['jurusan_nama'] ?? json['jurusan']?.toString() ?? '';
    final tipeRuangVal = json['kebutuhanTipeRuangan']?.toString() ?? json['kebutuhan_tipe_ruangan']?.toString();

    // Deteksi cerdas jenis perkuliahan bila belum dispesifikasikan di database
    final rawJenis = json['jenis']?.toString() ?? json['tipe']?.toString();
    final resolvedJenis = (rawJenis != null && rawJenis.isNotEmpty)
        ? (rawJenis.toLowerCase() == 'praktikum' ? 'Praktikum' : 'Teori')
        : (AcademicYearHelper.isPraktikum(
            matkulNama: namaVal,
            tipeRuangan: tipeRuangVal,
            fakultasNama: fakVal,
            jurusanNama: jurVal,
          )
            ? 'Praktikum'
            : 'Teori');

    return MataKuliahModel(
      id: json['id']?.toString() ?? '',
      nama: namaVal,
      sks: int.tryParse(json['sks']?.toString() ?? '3') ?? 3,
      semester: parsedSemester > 0 ? parsedSemester : 1,
      jurusanId: json['jurusanId']?.toString() ?? json['jurusan_id']?.toString() ?? '',
      jurusanNama: jurVal,
      fakultasNama: fakVal,
      dosenId: json['dosenId']?.toString() ?? json['dosen_id']?.toString() ?? '',
      dosenNama: json['dosenNama']?.toString() ?? json['dosen_nama']?.toString() ?? json['dosen']?.toString(),
      semesterId: json['semesterId']?.toString() ?? json['semester_id']?.toString() ?? '',
      tipeSesi: json['tipeSesi']?.toString() ?? json['tipe_sesi']?.toString() ?? 'reguler',
      jenis: resolvedJenis,
      kebutuhanTipeRuangan: tipeRuangVal,
      kelasIds: parseStringList(json['kelasIds'] ?? json['kelas_ids']),
      kelasNama: parsedKelas,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'nama': nama,
      'sks': sks,
      'semester': semester,
      'semester_angka': semester,
      'jurusanId': jurusanId,
      'jurusan_id': jurusanId,
      'jurusanNama': jurusanNama,
      'jurusan_nama': jurusanNama,
      'fakultasNama': fakultasNama,
      'fakultas_nama': fakultasNama,
      'dosenId': dosenId,
      'dosen_id': dosenId,
      'dosenNama': dosenNama,
      'dosen_nama': dosenNama,
      'dosen': dosenNama,
      'semesterId': semesterId,
      'semester_id': semesterId,
      'tipeSesi': tipeSesi,
      'jenis': jenis,
      'kebutuhanTipeRuangan': kebutuhanTipeRuangan,
      'kebutuhan_tipe_ruangan': kebutuhanTipeRuangan,
      'kelasIds': kelasIds,
      'kelasNama': kelasNama,
    };
  }
}
