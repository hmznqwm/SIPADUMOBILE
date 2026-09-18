// File: schedule_view_model.dart
// Deskripsi: ViewModel (ChangeNotifier) untuk memuat & memfilter jadwal perkuliahan final.
// Fungsi: Mengambil daftar hasil penjadwalan final dari JadwalRepository dan memfilter data berdasarkan hari operasional (Senin-Jumat).

import 'package:flutter/material.dart';

import '../../../../data/models/jadwal_model.dart';
import '../../../../data/mock/mock_database.dart';
import '../../../../data/repositories/auth_repository.dart';
import '../../../../data/repositories/jadwal_repository.dart';

class ScheduleViewModel extends ChangeNotifier {
  final AuthRepository _authRepository;
  final JadwalRepository _jadwalRepository;

  ScheduleViewModel({
    required AuthRepository authRepository,
    required JadwalRepository jadwalRepository,
  })  : _authRepository = authRepository,
        _jadwalRepository = jadwalRepository;

  bool _isLoading = false;
  bool get isLoading => _isLoading;

  String? _errorMessage;
  String? get errorMessage => _errorMessage;

  List<JadwalModel> _jadwalList = [];
  List<JadwalModel> get jadwalList => _jadwalList;

  String _selectedDay = 'Semua';
  String get selectedDay => _selectedDay;

  List<String> get availableDays => ['Semua', 'Senin', 'Selasa', 'Rabu', 'Kamis', 'Jumat'];

  String _selectedFakultas = 'Semua Fakultas';
  String get selectedFakultas => _selectedFakultas;

  String _selectedProdi = 'Semua Prodi';
  String get selectedProdi => _selectedProdi;

  List<String> get availableFakultas {
    final list = <String>{'Semua Fakultas'};
    for (final item in _jadwalList) {
      if (item.fakultasNama != null && item.fakultasNama!.isNotEmpty) {
        list.add(item.fakultasNama!);
      }
    }
    list.add('Fakultas Sains & Teknologi');
    list.add('Fakultas Ekonomi & Bisnis');
    return list.toList();
  }

  List<String> get availableProdi {
    final list = <String>{'Semua Prodi'};
    for (final item in _jadwalList) {
      final isFakMatch = _selectedFakultas == 'Semua Fakultas' ||
          item.fakultasNama == _selectedFakultas ||
          (_selectedFakultas.contains('Ekonomi') && (item.fakultasNama?.contains('Ekonomi') ?? false));
      if (isFakMatch && item.jurusanNama != null && item.jurusanNama!.isNotEmpty) {
        list.add(item.jurusanNama!);
      }
    }
    if (_selectedFakultas == 'Fakultas Sains & Teknologi') {
      list.add('Teknik Informatika');
      list.add('Sistem Informasi');
    } else if (_selectedFakultas == 'Fakultas Ekonomi & Bisnis' || _selectedFakultas == 'Fakultas Ekonomi') {
      list.add('Manajemen');
      list.add('Akuntansi');
    }
    return list.toList();
  }

  List<JadwalModel> get filteredJadwalList {
    final user = _authRepository.currentUser;

    bool isRelationalValid(JadwalModel j) {
      return j.mataKuliahNama.trim().isNotEmpty && j.hari.trim().isNotEmpty;
    }

    return _jadwalList.where((j) {
      if (!isRelationalValid(j)) return false;

      final matchDay = _selectedDay == 'Semua' || j.hari == _selectedDay;

      // Role KaProdi / KaJur: terikat ke program studi sendiri
      if (user?.role == 'kajur') {
        final userProdi = (user != null && user.jurusanNama.isNotEmpty) ? user.jurusanNama.toLowerCase() : 'teknik informatika';
        final jur = (j.jurusanNama ?? '').toLowerCase();
        final matchProdi = jur.contains(userProdi) || userProdi.contains(jur);
        return matchDay && matchProdi;
      }

      final matchFakultas = _selectedFakultas == 'Semua Fakultas' ||
          j.fakultasNama == null ||
          j.fakultasNama == _selectedFakultas ||
          (_selectedFakultas.contains('Ekonomi') && (j.fakultasNama?.contains('Ekonomi') ?? false));
      final matchProdi = _selectedProdi == 'Semua Prodi' ||
          j.jurusanNama == null ||
          j.jurusanNama == _selectedProdi;

      return matchDay && matchFakultas && matchProdi;
    }).toList();
  }

  Future<void> loadScheduleData() async {
    final user = _authRepository.currentUser;
    if (user == null) return;

    await MockDatabase.initLocalCache(forceReload: true);
    MockDatabase.purgeInvalidSchedules();
    await MockDatabase.saveLocalAjuan();
    await MockDatabase.saveLocalJadwal();

    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      if (user.role == 'admin') {
        _jadwalList = await _jadwalRepository.getGlobalJadwal();
      } else if (user.role == 'dekan') {
        final all = await _jadwalRepository.getGlobalJadwal();
        final fak = (user.fakultasNama.isNotEmpty ? user.fakultasNama : 'Fakultas Sains & Teknologi').toLowerCase();
        _jadwalList = all.where((j) => (j.fakultasNama ?? '').toLowerCase().contains(fak) || fak.contains((j.fakultasNama ?? '').toLowerCase())).toList();
      } else if (user.role == 'kajur') {
        final all = await _jadwalRepository.getGlobalJadwal();
        final jur = (user.jurusanNama.isNotEmpty ? user.jurusanNama : 'Teknik Informatika').toLowerCase();
        _jadwalList = all.where((j) => (j.jurusanNama ?? '').toLowerCase().contains(jur) || jur.contains((j.jurusanNama ?? '').toLowerCase())).toList();
        _selectedProdi = user.jurusanNama.isNotEmpty ? user.jurusanNama : 'Teknik Informatika';
      } else {
        final byId = await _jadwalRepository.getJadwalFinal(user.id);
        if (byId.isNotEmpty) {
          _jadwalList = byId;
        } else {
          final all = await _jadwalRepository.getGlobalJadwal();
          _jadwalList = all.where((j) =>
            (j.dosenId != null && j.dosenId == user.id) ||
            (j.dosenNama != null && user.nama.isNotEmpty && j.dosenNama!.toLowerCase().contains(user.nama.toLowerCase())) ||
            (j.dosenNama != null && user.nama.isNotEmpty && user.nama.toLowerCase().contains(j.dosenNama!.toLowerCase()))
          ).toList();
        }
      }
    } catch (e) {
      _errorMessage = e.toString();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  void filterByDay(String day) {
    _selectedDay = day;
    notifyListeners();
  }

  void filterByFakultas(String fakultas) {
    _selectedFakultas = fakultas;
    _selectedProdi = 'Semua Prodi';
    notifyListeners();
  }

  void filterByProdi(String prodi) {
    _selectedProdi = prodi;
    notifyListeners();
  }

  void setFilters({
    required String day,
    required String fakultas,
    required String prodi,
  }) {
    _selectedDay = day;
    _selectedFakultas = fakultas;
    _selectedProdi = prodi;
    notifyListeners();
  }

  void resetFilters() {
    _selectedDay = 'Semua';
    _selectedFakultas = 'Semua Fakultas';
    _selectedProdi = 'Semua Prodi';
    notifyListeners();
  }
}
