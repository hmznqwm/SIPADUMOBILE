// File: jadwal_repository.dart
// Deskripsi: Repositori untuk mengambil data hasil penjadwalan final.
// Fungsi: Menghubungkan ViewModel dengan ApiService untuk memperoleh daftar jadwal perkuliahan yang telah disusun oleh sistem.

import '../models/jadwal_model.dart';
import '../services/api_service.dart';

class JadwalRepository {
  final ApiService _apiService;

  JadwalRepository({required ApiService apiService}) : _apiService = apiService;

  Future<List<JadwalModel>> getJadwalFinal(String dosenId) {
    return _apiService.getJadwalFinal(dosenId);
  }

  Future<List<JadwalModel>> getGlobalJadwal() {
    return _apiService.getGlobalJadwal();
  }
}
