// File: ruangan_model.dart
// Deskripsi: Model data untuk ruangan kelas/laboratorium.
// Fungsi: Menyimpan entitas ruangan seperti nama ruangan, ID/nama gedung induk, kapasitas kursi, dan tipe ruangan.

class RuanganModel {
  final String id;
  final String nama;
  final String gedungId;
  final String gedungNama;
  final int kapasitas;
  final String tipeRuangan; // e.g. 'Kelas Teori', 'Laboratorium Komputer', 'Studio'
  final String keterangan;

  const RuanganModel({
    required this.id,
    required this.nama,
    required this.gedungId,
    required this.gedungNama,
    required this.kapasitas,
    this.tipeRuangan = 'Kelas Teori',
    this.keterangan = 'Ruang kelas ber-AC dan LCD proyektor',
  });

  RuanganModel copyWith({
    String? id,
    String? nama,
    String? gedungId,
    String? gedungNama,
    int? kapasitas,
    String? tipeRuangan,
    String? keterangan,
  }) {
    return RuanganModel(
      id: id ?? this.id,
      nama: nama ?? this.nama,
      gedungId: gedungId ?? this.gedungId,
      gedungNama: gedungNama ?? this.gedungNama,
      kapasitas: kapasitas ?? this.kapasitas,
      tipeRuangan: tipeRuangan ?? this.tipeRuangan,
      keterangan: keterangan ?? this.keterangan,
    );
  }

  factory RuanganModel.fromJson(Map<String, dynamic> json) {
    String gNama = (json['gedungNama'] ?? json['gedung_nama'] ?? '').toString();
    if (gNama.isEmpty && json['gedung'] is Map) {
      gNama = (json['gedung']['nama'] ?? '').toString();
    }
    final gId = (json['gedungId'] ?? json['gedung_id'] ?? '').toString();
    return RuanganModel(
      id: (json['id'] ?? json['ruangan_id'] ?? '').toString(),
      nama: (json['nama'] ?? json['ruangan_nama'] ?? json['name'] ?? '').toString(),
      gedungId: gId,
      gedungNama: gNama,
      kapasitas: int.tryParse((json['kapasitas'] ?? json['capacity'])?.toString() ?? '40') ?? 40,
      tipeRuangan: (json['tipeRuangan'] ?? json['tipe_ruangan'] ?? json['type'] ?? 'Kelas Teori').toString(),
      keterangan: (json['keterangan'] ?? json['description'] ?? 'Ruang kelas ber-AC dan LCD proyektor').toString(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'nama': nama,
      'gedungId': gedungId,
      'gedungNama': gedungNama,
      'kapasitas': kapasitas,
      'tipeRuangan': tipeRuangan,
      'keterangan': keterangan,
    };
  }
}
