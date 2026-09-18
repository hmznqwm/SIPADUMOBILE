// File: slot_waktu_model.dart
// Deskripsi: Model data untuk representasi slot jam perkuliahan per hari operasional.
// Fungsi: Mengelola rentang jam mulai, jam selesai, hari operasional, dan durasi menit untuk setiap slot ketersediaan/jadwal.

class SlotWaktuModel {
  final String id;
  final String hari; // Senin-Jumat
  final String jamMulai; // HH:mm format
  final String jamSelesai; // HH:mm format
  final int durasiMenit;

  const SlotWaktuModel({
    required this.id,
    required this.hari,
    required this.jamMulai,
    required this.jamSelesai,
    required this.durasiMenit,
  });

  factory SlotWaktuModel.fromJson(Map<String, dynamic> json) {
    return SlotWaktuModel(
      id: json['id']?.toString() ?? '',
      hari: json['hari']?.toString() ?? 'Senin',
      jamMulai: json['jamMulai']?.toString() ?? json['jam_mulai']?.toString() ?? '07:30',
      jamSelesai: json['jamSelesai']?.toString() ?? json['jam_selesai']?.toString() ?? '10:00',
      durasiMenit: int.tryParse(json['durasiMenit']?.toString() ?? json['durasi_menit']?.toString() ?? '150') ?? 150,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'hari': hari,
      'jamMulai': jamMulai,
      'jam_mulai': jamMulai,
      'jamSelesai': jamSelesai,
      'jam_selesai': jamSelesai,
      'durasiMenit': durasiMenit,
      'durasi_menit': durasiMenit,
    };
  }

  String get label => '$jamMulai - $jamSelesai';

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is SlotWaktuModel &&
          runtimeType == other.runtimeType &&
          id == other.id;

  @override
  int get hashCode => id.hashCode;
}
