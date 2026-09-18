// File: api_service.dart
// Deskripsi: Layanan API Facade (Mock Backend REST API & Live Server) untuk pengujian seluruh fitur aplikasi Smart Schedule.
// Arsitektur: Facade Pattern yang mendelegasikan logika ke sub-service modular.

import 'package:flutter/foundation.dart';

import '../models/user_model.dart';
import '../models/mata_kuliah_model.dart';
import '../models/slot_waktu_model.dart';
import '../models/availability_model.dart';
import '../models/jadwal_model.dart';
import '../models/notification_model.dart';
import '../models/gedung_model.dart';
import '../models/ruangan_model.dart';
import '../models/ajuan_pengajaran_model.dart';

import 'subservices/api_http_helper.dart';
import 'subservices/auth_api_service.dart';
import 'subservices/master_data_api_service.dart';
import 'subservices/availability_api_service.dart';
import 'subservices/schedule_api_service.dart';
import 'subservices/notification_api_service.dart';

export 'subservices/api_http_helper.dart' show ApiException;

/// Facade ApiService yang menyatukan seluruh sub-service sistem.
/// Mempertahankan 100% kompatibilitas kontrak API dengan ChangeNotifier.
class ApiService extends ChangeNotifier {
  final ApiHttpHelper _httpHelper;
  final AuthApiService _authService;
  final MasterDataApiService _masterDataService;
  final AvailabilityApiService _availabilityService;
  final ScheduleApiService _scheduleService;
  final NotificationApiService _notificationService;

  ApiService({
    ApiHttpHelper? httpHelper,
    AuthApiService? authService,
    MasterDataApiService? masterDataService,
    AvailabilityApiService? availabilityService,
    ScheduleApiService? scheduleService,
    NotificationApiService? notificationService,
  })  : _httpHelper = httpHelper ?? ApiHttpHelper(),
        _authService = authService ?? AuthApiService(httpHelper: httpHelper),
        _masterDataService = masterDataService ?? MasterDataApiService(httpHelper: httpHelper),
        _availabilityService = availabilityService ??
            AvailabilityApiService(
              httpHelper: httpHelper,
              masterDataService: masterDataService,
            ),
        _scheduleService = scheduleService ?? ScheduleApiService(httpHelper: httpHelper),
        _notificationService = notificationService ?? NotificationApiService(httpHelper: httpHelper);

  // ══════════════════════════════════════════════
  //  CONNECTIVITY & NETWORK STATUS
  // ══════════════════════════════════════════════

  Future<bool> checkConnectivity() => _httpHelper.checkConnectivity();

  // ══════════════════════════════════════════════
  //  AUTH & USER CREDENTIALS
  // ══════════════════════════════════════════════

  Future<UserModel> login(String email, String password) =>
      _authService.login(email, password);

  Future<UserModel> googleLogin({
    required String email,
    required String displayName,
    String? photoUrl,
    String? idToken,
  }) =>
      _authService.googleLogin(
        email: email,
        displayName: displayName,
        photoUrl: photoUrl,
        idToken: idToken,
      );

  Future<Map<String, dynamic>> forgotPassword({
    required String email,
    String? nidn,
  }) =>
      _authService.forgotPassword(email: email, nidn: nidn);

  Future<Map<String, dynamic>> resetPassword({
    required String email,
    required String otp,
    required String newPassword,
  }) =>
      _authService.resetPassword(
        email: email,
        otp: otp,
        newPassword: newPassword,
      );

  Future<Map<String, dynamic>> changePassword({
    required String email,
    required String oldPassword,
    required String newPassword,
  }) =>
      _authService.changePassword(
        email: email,
        oldPassword: oldPassword,
        newPassword: newPassword,
      );

  // ══════════════════════════════════════════════
  //  MASTER DATA (Courses, Slots, Users, Buildings, Rooms)
  // ══════════════════════════════════════════════

  Future<List<MataKuliahModel>> getMataKuliah(String dosenId) =>
      _masterDataService.getMataKuliah(dosenId);

  Future<List<SlotWaktuModel>> getSlotWaktu() =>
      _masterDataService.getSlotWaktu();

  Future<List<UserModel>> getAllUsers() =>
      _masterDataService.getAllUsers();

  Future<bool> toggleDosenPriority(String dosenId) async {
    final res = await _masterDataService.toggleDosenPriority(dosenId);
    notifyListeners();
    return res;
  }

  Future<void> setDosenPriority(String dosenId, bool priority) async {
    await _masterDataService.setDosenPriority(dosenId, priority);
    notifyListeners();
  }

  Future<UserModel> createDosen(UserModel dosen, {String password = 'password123'}) async {
    final res = await _masterDataService.createDosen(dosen, password: password);
    notifyListeners();
    return res;
  }

  Future<void> deleteUser(String userId) async {
    await _masterDataService.deleteUser(userId);
    notifyListeners();
  }

  Future<List<GedungModel>> getGedungList() =>
      _masterDataService.getGedungList();

  Future<GedungModel> addGedung(GedungModel gedung) async {
    final res = await _masterDataService.addGedung(gedung);
    notifyListeners();
    return res;
  }

  Future<void> deleteGedung(String gedungId) async {
    await _masterDataService.deleteGedung(gedungId);
    notifyListeners();
  }

  Future<List<RuanganModel>> getRuanganList() =>
      _masterDataService.getRuanganList();

  Future<RuanganModel> addRuangan(RuanganModel ruangan) async {
    final res = await _masterDataService.addRuangan(ruangan);
    notifyListeners();
    return res;
  }

  Future<void> deleteRuangan(String ruanganId) async {
    await _masterDataService.deleteRuangan(ruanganId);
    notifyListeners();
  }

  Future<List<MataKuliahModel>> getAllMataKuliah() =>
      _masterDataService.getAllMataKuliah();

  Future<void> saveMataKuliah(Map<String, dynamic> matkul) =>
      _masterDataService.saveMataKuliah(matkul);

  Future<void> deleteMataKuliah(String mkId) =>
      _masterDataService.deleteMataKuliah(mkId);

  List<UserModel> getDemoUsers() =>
      _masterDataService.getDemoUsers();

  // ══════════════════════════════════════════════
  //  AVAILABILITY & SUBMISSION WINDOW
  // ══════════════════════════════════════════════

  Future<AvailabilityModel> getAvailability(String dosenId, String semesterId) =>
      _availabilityService.getAvailability(dosenId, semesterId);

  Future<AvailabilityModel> saveAvailability({
    required String dosenId,
    required String semesterId,
    required List<String> selectedSlotIds,
    Map<String, SlotTagInfo>? slotTags,
  }) async {
    final res = await _availabilityService.saveAvailability(
      dosenId: dosenId,
      semesterId: semesterId,
      selectedSlotIds: selectedSlotIds,
      slotTags: slotTags,
    );
    notifyListeners();
    return res;
  }

  Future<({bool valid, int required, int provided, String? message})> validatePreSubmit({
    required String dosenId,
    required List<String> selectedSlotIds,
  }) =>
      _availabilityService.validatePreSubmit(
        dosenId: dosenId,
        selectedSlotIds: selectedSlotIds,
      );

  Future<List<AvailabilityHistoryItem>> getAvailabilityHistory(String dosenId) =>
      _availabilityService.getAvailabilityHistory(dosenId);

  Future<bool> getSubmissionActive() =>
      _availabilityService.getSubmissionActive();

  Future<bool> getSubmissionWindowStatus() =>
      _availabilityService.getSubmissionWindowStatus();

  Future<bool> toggleSubmissionActive() async {
    final res = await _availabilityService.toggleSubmissionActive();
    notifyListeners();
    return res;
  }

  Future<void> setSubmissionWindowStatus(bool active) async {
    await _availabilityService.setSubmissionWindowStatus(active);
    notifyListeners();
  }

  Future<void> kajurVerifySubmission(String dosenId) async {
    await _availabilityService.kajurVerifySubmission(dosenId);
    notifyListeners();
  }

  String getDosenSubmissionStatus(String dosenId) =>
      _availabilityService.getDosenSubmissionStatus(dosenId);

  Set<String> getOccupiedSlotsForOtherDosen(String currentDosenId) =>
      _availabilityService.getOccupiedSlotsForOtherDosen(currentDosenId);

  // ══════════════════════════════════════════════
  //  TEACHING PROPOSALS (AJUAN PENGAJARAN MULTI-TIER)
  // ══════════════════════════════════════════════

  Future<List<AjuanPengajaranModel>> getAjuanPengajaranList({
    String? dosenId,
    String? fakultas,
    String? prodi,
    String? status,
  }) =>
      _availabilityService.getAjuanPengajaranList(
        dosenId: dosenId,
        fakultas: fakultas,
        prodi: prodi,
        status: status,
      );

  Future<AjuanPengajaranModel> submitAjuanPengajaran(AjuanPengajaranModel ajuan) async {
    final res = await _availabilityService.submitAjuanPengajaran(ajuan);
    notifyListeners();
    return res;
  }

  Future<AjuanPengajaranModel> updateAjuanPengajaran(AjuanPengajaranModel updated) async {
    final res = await _availabilityService.updateAjuanPengajaran(updated);
    notifyListeners();
    return res;
  }

  Future<void> deleteAjuanPengajaran(String ajuanId) async {
    await _availabilityService.deleteAjuanPengajaran(ajuanId);
    notifyListeners();
  }

  Future<void> deleteMultipleAjuanPengajaran(List<String> ajuanIds) async {
    await _availabilityService.deleteMultipleAjuanPengajaran(ajuanIds);
    notifyListeners();
  }

  Future<AjuanPengajaranModel> kaprodiVerifyAjuan(
    String ajuanId, {
    AjuanPengajaranModel? updatedData,
    String? catatan,
  }) async {
    final res = await _availabilityService.kaprodiVerifyAjuan(
      ajuanId,
      updatedData: updatedData,
      catatan: catatan,
    );
    notifyListeners();
    return res;
  }

  Future<AjuanPengajaranModel> kaprodiRejectAjuan(String ajuanId, String alasan) async {
    final res = await _availabilityService.kaprodiRejectAjuan(ajuanId, alasan);
    notifyListeners();
    return res;
  }

  Future<AjuanPengajaranModel> dekanApproveAjuan(
    String ajuanId, {
    AjuanPengajaranModel? updatedData,
    String? catatan,
  }) async {
    final res = await _availabilityService.dekanApproveAjuan(
      ajuanId,
      updatedData: updatedData,
      catatan: catatan,
    );
    notifyListeners();
    return res;
  }

  Future<AjuanPengajaranModel> dekanRejectAjuan(String ajuanId, String alasan) async {
    final res = await _availabilityService.dekanRejectAjuan(ajuanId, alasan);
    notifyListeners();
    return res;
  }

  Future<AjuanPengajaranModel> adminApproveFinalAjuan(
    String ajuanId, {
    AjuanPengajaranModel? updatedData,
    String? catatan,
  }) async {
    final res = await _availabilityService.adminApproveFinalAjuan(
      ajuanId,
      updatedData: updatedData,
      catatan: catatan,
    );
    notifyListeners();
    return res;
  }

  Future<AjuanPengajaranModel> adminRejectAjuan(String ajuanId, String alasan) async {
    final res = await _availabilityService.adminRejectAjuan(ajuanId, alasan);
    notifyListeners();
    return res;
  }

  Future<AjuanPengajaranModel> submitBandingAjuan({
    required String ajuanId,
    required String alasan,
    String? preferensiHari,
    String? preferensiJam,
  }) async {
    final res = await _availabilityService.submitBandingAjuan(
      ajuanId: ajuanId,
      alasan: alasan,
      preferensiHari: preferensiHari,
      preferensiJam: preferensiJam,
    );
    notifyListeners();
    return res;
  }

  Future<AjuanPengajaranModel> adminProcessBanding({
    required String ajuanId,
    required bool approve,
    String? catatanAdmin,
    AjuanPengajaranModel? updatedData,
  }) async {
    final res = await _availabilityService.adminProcessBanding(
      ajuanId: ajuanId,
      approve: approve,
      catatanAdmin: catatanAdmin,
      updatedData: updatedData,
    );
    notifyListeners();
    return res;
  }

  // ══════════════════════════════════════════════
  //  SCHEDULE, MRV / CSP ENGINE & CONFLICT DETECTION
  // ══════════════════════════════════════════════

  Future<List<JadwalModel>> getJadwalFinal(String dosenId) =>
      _scheduleService.getJadwalFinal(dosenId);

  Future<List<JadwalModel>> getGlobalJadwal() =>
      _scheduleService.getGlobalJadwal();

  Future<bool> runAdminEngine() =>
      _scheduleService.runAdminEngine();

  Future<Map<String, dynamic>> runSmartCspEngineWithAutoApproval({
    String scope = 'global',
    String? fakultasNama,
    String? jurusanNama,
    String role = 'admin',
  }) async {
    final res = await _scheduleService.runSmartCspEngineWithAutoApproval(
      scope: scope,
      fakultasNama: fakultasNama,
      jurusanNama: jurusanNama,
      role: role,
    );
    notifyListeners();
    return res;
  }

  Map<String, String> findSmartAlternativeSlot(
    AjuanPengajaranModel ajuan, [
    List<AjuanPengajaranModel> bookedAjuan = const [],
  ]) =>
      _scheduleService.findSmartAlternativeSlot(ajuan, bookedAjuan);

  Future<int> batchResolveConflicts({List<String>? targetAjuanIds}) async {
    final res = await _scheduleService.batchResolveConflicts(targetAjuanIds: targetAjuanIds);
    notifyListeners();
    return res;
  }

  Map<String, dynamic> checkBuildingConflict(AjuanPengajaranModel ajuan) =>
      _scheduleService.checkBuildingConflict(ajuan);

  // ══════════════════════════════════════════════
  //  NOTIFICATIONS
  // ══════════════════════════════════════════════

  Future<List<NotificationModel>> getNotifications(String dosenId) =>
      _notificationService.getNotifications(dosenId);

  Future<void> markNotificationRead(String notificationId) async {
    await _notificationService.markNotificationRead(notificationId);
    notifyListeners();
  }

  Future<void> markMultipleNotificationsRead(List<String> notificationIds) async {
    await _notificationService.markMultipleNotificationsRead(notificationIds);
    notifyListeners();
  }

  Future<void> deleteNotifications(List<String> notificationIds) async {
    await _notificationService.deleteNotifications(notificationIds);
    notifyListeners();
  }

  Future<void> markAllNotificationsRead([String? userId]) async {
    await _notificationService.markAllNotificationsRead(userId ?? '');
    notifyListeners();
  }
}
