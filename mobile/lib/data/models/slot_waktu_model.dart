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
