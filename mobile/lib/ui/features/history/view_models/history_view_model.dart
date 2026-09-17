// File: history_view_model.dart
// Deskripsi: ViewModel (ChangeNotifier) untuk memuat riwayat pengajuan ketersediaan dosen.
// Fungsi: Mengambil daftar histori pengisian ketersediaan waktu dosen beserta status persetujuan dan catatan revisi dari KaProdi.

import 'package:flutter/material.dart';

import '../../../../data/models/availability_model.dart';
import '../../../../data/repositories/auth_repository.dart';
import '../../../../data/repositories/availability_repository.dart';

class HistoryViewModel extends ChangeNotifier {
  final AuthRepository _authRepository;
  final AvailabilityRepository _availabilityRepository;

  HistoryViewModel({
    required AuthRepository authRepository,
    required AvailabilityRepository availabilityRepository,
  })  : _authRepository = authRepository,
        _availabilityRepository = availabilityRepository;

  bool _isLoading = false;
  bool get isLoading => _isLoading;

  String? _errorMessage;
  String? get errorMessage => _errorMessage;

  List<AvailabilityHistoryItem> _historyList = [];
  List<AvailabilityHistoryItem> get historyList => _historyList;

  Future<void> loadHistoryData() async {
    final user = _authRepository.currentUser;
    if (user == null) return;

    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      _historyList = await _availabilityRepository.getAvailabilityHistory(user.id);
    } catch (e) {
      _errorMessage = e.toString();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }
}
