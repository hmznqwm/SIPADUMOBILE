// File: dashboard_view_model.dart
// Deskripsi: ViewModel (ChangeNotifier) untuk memuat data ringkasan dashboard sesuai role pengguna.
// Fungsi: Mengambil informasi ringkasan beban mengajar SKS, jumlah mata kuliah, status ketersediaan, dan total jadwal perkuliahan dosen.

import 'package:flutter/material.dart';

import '../../../../data/models/mata_kuliah_model.dart';
import '../../../../data/models/user_model.dart';
import '../../../../data/repositories/auth_repository.dart';
import '../../../../data/repositories/availability_repository.dart';
import '../../../../data/repositories/jadwal_repository.dart';

/// [PRESENTASI] DashboardViewModel (Pattern MVVM):
/// Bertugas sebagai otak dari halaman Dashboard. 
/// Mengambil, mengolah, dan menyediakan data SKS, Mata Kuliah, 
/// Status Ketersediaan, dan Jadwal Dosen untuk ditampilkan di View.
class DashboardViewModel extends ChangeNotifier {
  final AuthRepository _authRepository;
  final AvailabilityRepository _availabilityRepository;
  final JadwalRepository _jadwalRepository;

  DashboardViewModel({
    required AuthRepository authRepository,
    required AvailabilityRepository availabilityRepository,
    required JadwalRepository jadwalRepository,
  })  : _authRepository = authRepository,
        _availabilityRepository = availabilityRepository,
        _jadwalRepository = jadwalRepository;

  UserModel? get currentUser => _authRepository.currentUser;

  bool _isLoading = false;
  bool get isLoading => _isLoading;

  List<MataKuliahModel> _mataKuliahList = [];
  List<MataKuliahModel> get mataKuliahList => _mataKuliahList;

  int get totalSks => _mataKuliahList.fold(0, (sum, item) => sum + item.sks);

  String _availabilityStatus = 'disetujui';
  String get availabilityStatus => _availabilityStatus;

  int _totalJadwal = 0;
  int get totalJadwal => _totalJadwal;

  /// [PRESENTASI] loadDashboardData():
  /// Dipanggil saat dashboard pertama kali dibuka. 
  /// Mengambil data secara asinkron dan sinkronisasi dengan UI menggunakan notifyListeners()
  Future<void> loadDashboardData() async {
    final user = currentUser;
    if (user == null) return;

    _isLoading = true;
    notifyListeners();

    try {
      if (user.role == 'dosen' || user.role == 'kajur') {
        _mataKuliahList = await _availabilityRepository.getMataKuliah(user.id);

        if (_mataKuliahList.isEmpty && user.email.isNotEmpty) {
          _mataKuliahList = await _availabilityRepository.getMataKuliah(user.email);
        }

        final availability = await _availabilityRepository.getAvailability(user.id, 'SEM001');
        _availabilityStatus = availability.status;

        var jadwalList = await _jadwalRepository.getJadwalFinal(user.id);
        if (jadwalList.isEmpty && user.nama.isNotEmpty) {
          jadwalList = await _jadwalRepository.getJadwalFinal(user.nama);
        }
        _totalJadwal = jadwalList.length;
      }
    } catch (e) {
      debugPrint('Error loading dashboard data: $e');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }
}
