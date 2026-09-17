// File: availability_repository.dart
// Deskripsi: Repositori pengelolaan ketersediaan waktu dosen (availability matrix).
// Fungsi: Menghubungkan ViewModel dengan ApiService untuk pengisian slot waktu, validasi SKS, melihat riwayat pengajuan, dan status kunci window pengisian.

import '../models/availability_model.dart';
import '../models/mata_kuliah_model.dart';
import '../models/slot_waktu_model.dart';
import '../services/api_service.dart';

class AvailabilityRepository {
  final ApiService _apiService;

  AvailabilityRepository({required ApiService apiService}) : _apiService = apiService;

  Future<List<MataKuliahModel>> getMataKuliah(String dosenId) {
    return _apiService.getMataKuliah(dosenId);
  }

  Future<List<SlotWaktuModel>> getSlotWaktu() {
    return _apiService.getSlotWaktu();
  }

  Future<AvailabilityModel> getAvailability(String dosenId, String semesterId) {
    return _apiService.getAvailability(dosenId, semesterId);
  }

  Future<AvailabilityModel> saveAvailability({
    required String dosenId,
    required String semesterId,
    required List<String> selectedSlotIds,
    Map<String, SlotTagInfo>? slotTags,
  }) {
    return _apiService.saveAvailability(
      dosenId: dosenId,
      semesterId: semesterId,
      selectedSlotIds: selectedSlotIds,
      slotTags: slotTags,
    );
  }

  Future<({bool valid, int required, int provided, String? message})> validatePreSubmit({
    required String dosenId,
    required List<String> selectedSlotIds,
  }) {
    return _apiService.validatePreSubmit(
      dosenId: dosenId,
      selectedSlotIds: selectedSlotIds,
    );
  }

  Future<List<AvailabilityHistoryItem>> getAvailabilityHistory(String dosenId) {
    return _apiService.getAvailabilityHistory(dosenId);
  }

  Future<bool> getSubmissionWindowStatus() {
    return _apiService.getSubmissionWindowStatus();
  }

  Set<String> getOccupiedSlotsForOtherDosen(String dosenId) {
    return _apiService.getOccupiedSlotsForOtherDosen(dosenId);
  }
}
