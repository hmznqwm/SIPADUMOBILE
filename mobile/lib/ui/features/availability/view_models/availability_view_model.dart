// File: availability_view_model.dart
// Deskripsi: ViewModel (ChangeNotifier) untuk manajemen status & logika matriks ketersediaan waktu dosen.
// Fungsi: Mengelola daftar slot waktu, pemilihan slot, hitung SKS minimal, validasi pra-pengajuan, preset waktu, dan penyimpanan ketersediaan.

import 'package:flutter/material.dart';

import '../../../../data/models/availability_model.dart';
import '../../../../data/models/mata_kuliah_model.dart';
import '../../../../data/models/slot_waktu_model.dart';
import '../../../../data/repositories/auth_repository.dart';
import '../../../../data/repositories/availability_repository.dart';

class AvailabilityViewModel extends ChangeNotifier {
  final AuthRepository _authRepository;
  final AvailabilityRepository _availabilityRepository;

  AvailabilityViewModel({
    required AuthRepository authRepository,
    required AvailabilityRepository availabilityRepository,
  })  : _authRepository = authRepository,
        _availabilityRepository = availabilityRepository;

  bool _isLoading = false;
  bool get isLoading => _isLoading;

  bool _isSubmitting = false;
  bool get isSubmitting => _isSubmitting;

  String? _errorMessage;
  String? get errorMessage => _errorMessage;

  String? _successMessage;
  String? get successMessage => _successMessage;

  List<SlotWaktuModel> _allSlots = [];
  List<SlotWaktuModel> get allSlots => _allSlots;

  List<MataKuliahModel> _mataKuliahList = [];
  List<MataKuliahModel> get mataKuliahList => _mataKuliahList;

  Set<String> _selectedSlotIds = {};
  Set<String> get selectedSlotIds => _selectedSlotIds;

  Map<String, SlotTagInfo> _slotTags = {};
  Map<String, SlotTagInfo> get slotTags => _slotTags;

  bool _isSubmissionActive = true;
  bool get isSubmissionActive => _isSubmissionActive;

  Set<String> _occupiedSlotIds = {};
  Set<String> get occupiedSlotIds => _occupiedSlotIds;

  AvailabilityModel? _availability;
  AvailabilityModel? get availability => _availability;

  int get totalRequiredSks => _mataKuliahList.fold(0, (sum, mk) => sum + mk.sks);
  int get selectedCount => _selectedSlotIds.length;
  bool get meetsMinimumSks => selectedCount >= totalRequiredSks;

  Future<void> loadAvailabilityData() async {
    final user = _authRepository.currentUser;
    if (user == null) return;

    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      _allSlots = await _availabilityRepository.getSlotWaktu();
      _mataKuliahList = await _availabilityRepository.getMataKuliah(user.id);
      _availability = await _availabilityRepository.getAvailability(user.id, 'SEM001');
      _isSubmissionActive = await _availabilityRepository.getSubmissionWindowStatus();
      _occupiedSlotIds = _availabilityRepository.getOccupiedSlotsForOtherDosen(user.id);

      if (_availability != null) {
        _selectedSlotIds = Set.from(_availability!.selectedSlotIds);
        _slotTags = Map.from(_availability!.slotTags);
      }
    } catch (e) {
      _errorMessage = e.toString();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  void toggleSlot(String slotId, [SlotTagInfo? tag]) {
    if (!_isSubmissionActive) return; // Prevent toggle if submission window is closed by Admin
    if (_occupiedSlotIds.contains(slotId)) return; // Prevent picking slot locked by another lecturer

    if (_selectedSlotIds.contains(slotId)) {
      _selectedSlotIds.remove(slotId);
      _slotTags.remove(slotId);
    } else {
      _selectedSlotIds.add(slotId);
      if (tag != null) {
        _slotTags[slotId] = tag;
      }
    }
    notifyListeners();
  }

  void setSlotTag(String slotId, SlotTagInfo? tag) {
    if (!_isSubmissionActive) return;
    if (_occupiedSlotIds.contains(slotId)) return;

    if (!_selectedSlotIds.contains(slotId)) {
      _selectedSlotIds.add(slotId);
    }
    if (tag != null) {
      _slotTags[slotId] = tag;
    } else {
      _slotTags.remove(slotId);
    }
    notifyListeners();
  }

  void selectPresetPagi() {
    if (!_isSubmissionActive) return;
    _selectedSlotIds = _allSlots
        .where((s) => s.jamMulai.compareTo('12:00') < 0)
        .map((s) => s.id)
        .toSet();
    notifyListeners();
  }

  void selectPresetSiang() {
    if (!_isSubmissionActive) return;
    _selectedSlotIds = _allSlots
        .where((s) => s.jamMulai.compareTo('12:00') >= 0)
        .map((s) => s.id)
        .toSet();
    notifyListeners();
  }

  void resetSelection() {
    if (!_isSubmissionActive) return;
    _selectedSlotIds.clear();
    _slotTags.clear();
    notifyListeners();
  }

  Future<bool> submitAvailability() async {
    final user = _authRepository.currentUser;
    if (user == null) return false;

    _isSubmitting = true;
    _errorMessage = null;
    _successMessage = null;
    notifyListeners();

    try {
      // Step 1: Pre-submit validation (PRD Section 3A)
      final validation = await _availabilityRepository.validatePreSubmit(
        dosenId: user.id,
        selectedSlotIds: _selectedSlotIds.toList(),
      );

      if (!validation.valid) {
        _errorMessage = validation.message;
        _isSubmitting = false;
        notifyListeners();
        return false;
      }

      // Step 2: Save to backend database
      _availability = await _availabilityRepository.saveAvailability(
        dosenId: user.id,
        semesterId: 'SEM001',
        selectedSlotIds: _selectedSlotIds.toList(),
        slotTags: _slotTags,
      );

      _successMessage = 'Matriks ketersediaan & tag mata kuliah berhasil disimpan ke database!';
      _isSubmitting = false;
      notifyListeners();
      return true;
    } catch (e) {
      _errorMessage = e.toString();
      _isSubmitting = false;
      notifyListeners();
      return false;
    }
  }
}
