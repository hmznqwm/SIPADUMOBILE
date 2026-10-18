// File: schedule_view_model.dart
// Deskripsi: ViewModel (ChangeNotifier) untuk memuat & memfilter jadwal perkuliahan final.
// Fungsi: Mengambil daftar hasil penjadwalan final dari JadwalRepository dan memfilter data berdasarkan hari operasional (Senin-Jumat).

import 'package:flutter/foundation.dart';
import '../../../../data/models/jadwal_model.dart';
import '../../../../data/mock/mock_database.dart';
import '../../../../data/repositories/auth_repository.dart';
import '../../../../data/repositories/jadwal_repository.dart';
import '../../../../utils/academic_year_helper.dart';

/// [PRESENTASI] ScheduleViewModel:
/// Mengelola data penjadwalan. Menangani logika filter jadwal berdasarkan 
/// Role (Admin, Dekan, Kajur, Dosen), Fakultas, Prodi, dan Hari, 
/// sehingga UI (Tampilan) tetap bersih dari aturan bisnis yang rumit.
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
    for (final f in MockDatabase.fakultasData) {
      final fNama = (f['nama'] ?? '').toString().trim();
      if (fNama.isNotEmpty) list.add(fNama);
    }
    for (final item in _jadwalList) {
      if (item.fakultasNama != null && item.fakultasNama!.trim().isNotEmpty) {
        list.add(item.fakultasNama!.trim());
      }
    }
    return list.toList();
  }

  List<String> get availableProdi {
    final list = <String>{'Semua Prodi'};
    for (final f in MockDatabase.fakultasData) {
      final fNama = (f['nama'] ?? '').toString().trim();
      final isFakMatch = _selectedFakultas == 'Semua Fakultas' || fNama == _selectedFakultas;
      if (isFakMatch) {
        final jurRaw = f['jurusan'];
        if (jurRaw is List) {
          for (final j in jurRaw) {
            final jStr = j.toString().trim();
            if (jStr.isNotEmpty) list.add(jStr);
          }
        }
      }
    }
    for (final item in _jadwalList) {
      final isFakMatch = _selectedFakultas == 'Semua Fakultas' ||
          item.fakultasNama == _selectedFakultas;
      if (isFakMatch && item.jurusanNama != null && item.jurusanNama!.trim().isNotEmpty) {
        list.add(item.jurusanNama!.trim());
      }
    }
    return list.toList();
  }

  /// [PRESENTASI] filteredJadwalList:
  /// Filter cerdas berdasarkan role dan semester aktif (misal Genap/Ganjil).
  /// Memastikan jadwal yang tampil selalu ter-update dan aman (hak akses).
  List<JadwalModel> get filteredJadwalList {
    final user = _authRepository.currentUser;
    final activeSemesterText = AcademicYearHelper.getCurrentSemester().toLowerCase(); // e.g. "ganjil 2026/2027"
    final activeSemesterType = AcademicYearHelper.getSemesterType().toLowerCase(); // "ganjil" or "genap"

    bool isRelationalValid(JadwalModel j) {
      return j.mataKuliahNama.trim().isNotEmpty && j.hari.trim().isNotEmpty;
    }

    bool isSemesterMatch(JadwalModel j) {
      final jSmt = j.semesterNama.toLowerCase().trim();
      if (jSmt.isEmpty) return true;

      // 1. Exact match with active semester text from profile (e.g. "ganjil 2026/2027")
      if (jSmt == activeSemesterText || jSmt.contains(activeSemesterText)) {
        return true;
      }

      // 2. Check Semester Ganjil (1, 3, 5, 7) vs Genap (2, 4, 6, 8)
      final numMatch = RegExp(r'\d+').firstMatch(jSmt);
      if (numMatch != null) {
        final smtNum = int.tryParse(numMatch.group(0)!) ?? 1;
        if (activeSemesterType == 'ganjil') {
          return smtNum % 2 != 0;
        } else {
          return smtNum % 2 == 0;
        }
      }

      // 3. Fallback type check
      if (jSmt.contains('ganjil') && activeSemesterType == 'ganjil') return true;
      if (jSmt.contains('genap') && activeSemesterType == 'genap') return true;

      return false;
    }

    return _jadwalList.where((j) {
      if (!isRelationalValid(j)) return false;
      if (!isSemesterMatch(j)) return false; // Otomatis filter / restart saat semester berganti

      final matchDay = _selectedDay == 'Semua' || j.hari == _selectedDay;

      // Role KaProdi / KaJur: terikat ke program studi sendiri
      if (user?.role == 'kajur') {
        final userProdi = (user != null && user.jurusanNama.isNotEmpty) ? user.jurusanNama.toLowerCase() : '';
        if (userProdi.isEmpty) return matchDay;
        final jur = (j.jurusanNama ?? '').toLowerCase();
        final matchProdi = jur.contains(userProdi) || userProdi.contains(jur);
        return matchDay && matchProdi;
      }

      final matchFakultas = _selectedFakultas == 'Semua Fakultas' ||
          j.fakultasNama == null ||
          j.fakultasNama == _selectedFakultas;
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
        final fak = user.fakultasNama.toLowerCase().trim();
        if (fak.isNotEmpty) {
          _jadwalList = all.where((j) => (j.fakultasNama ?? '').toLowerCase().contains(fak) || fak.contains((j.fakultasNama ?? '').toLowerCase())).toList();
        } else {
          _jadwalList = all;
        }
      } else if (user.role == 'kajur') {
        final all = await _jadwalRepository.getGlobalJadwal();
        final jur = user.jurusanNama.toLowerCase().trim();
        if (jur.isNotEmpty) {
          _jadwalList = all.where((j) => (j.jurusanNama ?? '').toLowerCase().contains(jur) || jur.contains((j.jurusanNama ?? '').toLowerCase())).toList();
          _selectedProdi = user.jurusanNama;
        } else {
          _jadwalList = all;
        }
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
