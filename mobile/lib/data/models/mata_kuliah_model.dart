// File: mata_kuliah_model.dart
// Deskripsi: Model data untuk mata kuliah yang diajarkan dalam perkuliahan.
// Fungsi: Memuat detail mata kuliah seperti nama, bobot SKS, jurusan, semester, tipe sesi (reguler/split), dan kebutuhan ruangan.

class MataKuliahModel {
  final String id;
  final String nama;
  final int sks;
  final String jurusanId;
  final String jurusanNama;
  final String fakultasNama;
  final String dosenId;
  final String? dosenNama;
  final String semesterId;
  final String tipeSesi; // 'reguler' or 'split'
  final String? kebutuhanTipeRuangan;
  final List<String> kelasIds;
  final List<String> kelasNama;

  const MataKuliahModel({
    required this.id,
    required this.nama,
    required this.sks,
    required this.jurusanId,
    required this.jurusanNama,
    this.fakultasNama = 'Fakultas Sains dan Teknologi',
    this.dosenId = 'DOS001',
    this.dosenNama,
    required this.semesterId,
    this.tipeSesi = 'reguler',
    this.kebutuhanTipeRuangan,
    this.kelasIds = const [],
    this.kelasNama = const [],
  });

  factory MataKuliahModel.fromJson(Map<String, dynamic> json) {
    List<String> parseStringList(dynamic val) {
      if (val is List) return val.map((e) => e.toString()).toList();
      if (val is String && val.isNotEmpty) {
        return val.split(',').map((e) => e.trim()).toList();
      }
      return [];
    }

    final parsedKelas = parseStringList(json['kelasNama'] ?? json['kelas_nama'] ?? json['kelas']);

    return MataKuliahModel(
      id: json['id']?.toString() ?? '',
      nama: json['nama']?.toString() ?? '',
      sks: int.tryParse(json['sks']?.toString() ?? '3') ?? 3,
      jurusanId: json['jurusanId']?.toString() ?? json['jurusan_id']?.toString() ?? '',
      jurusanNama: json['jurusanNama']?.toString() ?? json['jurusan_nama']?.toString() ?? 'Teknik Informatika',
      fakultasNama: json['fakultasNama']?.toString() ?? json['fakultas_nama']?.toString() ?? 'Fakultas Sains & Teknologi',
      dosenId: json['dosenId']?.toString() ?? json['dosen_id']?.toString() ?? 'DOS001',
      dosenNama: json['dosenNama']?.toString() ?? json['dosen_nama']?.toString() ?? json['dosen']?.toString(),
      semesterId: json['semesterId']?.toString() ?? json['semester_id']?.toString() ?? 'SEM001',
      tipeSesi: json['tipeSesi']?.toString() ?? json['tipe_sesi']?.toString() ?? 'reguler',
      kebutuhanTipeRuangan: json['kebutuhanTipeRuangan']?.toString() ?? json['kebutuhan_tipe_ruangan']?.toString(),
      kelasIds: parseStringList(json['kelasIds'] ?? json['kelas_ids']),
      kelasNama: parsedKelas.isNotEmpty ? parsedKelas : const ['Kelas A', 'Kelas B'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'nama': nama,
      'sks': sks,
      'jurusanId': jurusanId,
      'jurusanNama': jurusanNama,
      'fakultasNama': fakultasNama,
      'dosenId': dosenId,
      'dosenNama': dosenNama,
      'dosen_nama': dosenNama,
      'dosen': dosenNama,
      'semesterId': semesterId,
      'tipeSesi': tipeSesi,
      'kebutuhanTipeRuangan': kebutuhanTipeRuangan,
      'kelasIds': kelasIds,
      'kelasNama': kelasNama,
    };
  }
}
