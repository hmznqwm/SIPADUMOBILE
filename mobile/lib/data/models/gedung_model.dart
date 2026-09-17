// File: gedung_model.dart
// Deskripsi: Model data untuk informasi gedung perkuliahan.
// Fungsi: Menyimpan data gedung seperti nama gedung, jam operasional (jam buka/tutup), dan hak akses jurusan.

class GedungModel {
  final String id;
  final String nama;
  final String jamBuka; // e.g. '09:50' or '06:30'
  final String jamTutup; // e.g. '16:30'
  final String aksesJurusan; // e.g. 'Eksklusif Jurusan TI' or 'Shared All'

  const GedungModel({
    required this.id,
    required this.nama,
    required this.jamBuka,
    required this.jamTutup,
    required this.aksesJurusan,
  });

  GedungModel copyWith({
    String? id,
    String? nama,
    String? jamBuka,
    String? jamTutup,
    String? aksesJurusan,
  }) {
    return GedungModel(
      id: id ?? this.id,
      nama: nama ?? this.nama,
      jamBuka: jamBuka ?? this.jamBuka,
      jamTutup: jamTutup ?? this.jamTutup,
      aksesJurusan: aksesJurusan ?? this.aksesJurusan,
    );
  }

  factory GedungModel.fromJson(Map<String, dynamic> json) {
    return GedungModel(
      id: (json['id'] ?? json['gedung_id'] ?? '').toString(),
      nama: (json['nama'] ?? json['gedung_nama'] ?? json['name'] ?? '').toString(),
      jamBuka: (json['jamBuka'] ?? json['jam_buka'] ?? '07:30').toString(),
      jamTutup: (json['jamTutup'] ?? json['jam_tutup'] ?? '17:00').toString(),
      aksesJurusan: (json['aksesJurusan'] ?? json['akses_jurusan'] ?? 'Semua Fakultas').toString(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'nama': nama,
      'jamBuka': jamBuka,
      'jamTutup': jamTutup,
      'aksesJurusan': aksesJurusan,
    };
  }
}
