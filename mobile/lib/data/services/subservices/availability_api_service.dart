import '../../../config/api_config.dart';
import '../../models/availability_model.dart';
import '../../models/ajuan_pengajaran_model.dart';
import '../../models/jadwal_model.dart';
import '../../mock/mock_database.dart';
import 'api_http_helper.dart';
import 'master_data_api_service.dart';

class AvailabilityApiService {
  final ApiHttpHelper _httpHelper;
  final MasterDataApiService _masterDataService;

  AvailabilityApiService({
    ApiHttpHelper? httpHelper,
    MasterDataApiService? masterDataService,
  })  : _httpHelper = httpHelper ?? ApiHttpHelper(),
        _masterDataService = masterDataService ?? MasterDataApiService(httpHelper: httpHelper);

  /// GET /api/availability/index.php
  Future<AvailabilityModel> getAvailability(String dosenId, String semesterId) async {
    if (!ApiConfig.useMockBackend) {
      try {
        final res = await _httpHelper.makeOnlineRequest('/availability/index.php?dosen_id=$dosenId&semester_id=$semesterId');
        if (res is Map && res['status'] == 'success' && res['data'] != null) {
          final model = AvailabilityModel.fromJson(Map<String, dynamic>.from(res['data']));
          MockDatabase.currentAvailability = model;
          return model;
        }
      } catch (_) {}
    }

    await Future.delayed(const Duration(milliseconds: 100));
    if (MockDatabase.currentAvailability != null) {
      return MockDatabase.currentAvailability!;
    }
    final isDeleted = MockDatabase.deletedUserIds.contains(dosenId);
    final hasMatkul = MockDatabase.matkulData.isNotEmpty;
    if (isDeleted || !hasMatkul) {
      return AvailabilityModel(
        id: 'AVL_$dosenId',
        dosenId: dosenId,
        semesterId: semesterId,
        selectedSlotIds: const [],
        slotTags: const {},
        status: 'draft',
      );
    }
    return AvailabilityModel(
      id: 'AVL001',
      dosenId: dosenId,
      semesterId: semesterId,
      selectedSlotIds: const [
        'SLOT005', 'SLOT006', 'SLOT007', 'SLOT008',
        'SLOT016', 'SLOT017', 'SLOT018',
        'SLOT020', 'SLOT021',
        'SLOT027', 'SLOT028', 'SLOT029',
        'SLOT038', 'SLOT039', 'SLOT040', 'SLOT041',
        'SLOT051', 'SLOT052',
      ],
      slotTags: const {
        'SLOT005': SlotTagInfo(
          mataKuliahId: 'MK001',
          mataKuliahNama: 'Algoritma & Pemrograman',
          kelasNama: 'TI-1A',
          jurusanNama: 'Teknik Informatika',
          fakultasNama: 'Fakultas Sains & Teknologi',
          sks: 3,
        ),
        'SLOT006': SlotTagInfo(
          mataKuliahId: 'MK001',
          mataKuliahNama: 'Algoritma & Pemrograman',
          kelasNama: 'TI-1A',
          jurusanNama: 'Teknik Informatika',
          fakultasNama: 'Fakultas Sains & Teknologi',
          sks: 3,
        ),
        'SLOT016': SlotTagInfo(
          mataKuliahId: 'MK-SI01',
          mataKuliahNama: 'Sistem Informasi Enterprise',
          kelasNama: 'SI-3A',
          jurusanNama: 'Sistem Informasi',
          fakultasNama: 'Fakultas Sains & Teknologi',
          sks: 3,
        ),
      },
      status: 'submitted',
      submittedAt: DateTime(2026, 9, 5),
    );
  }

  /// POST /api/availability/index.php
  Future<AvailabilityModel> saveAvailability({
    required String dosenId,
    required String semesterId,
    required List<String> selectedSlotIds,
    Map<String, SlotTagInfo>? slotTags,
  }) async {
    final tagsMap = slotTags ?? MockDatabase.currentAvailability?.slotTags ?? {};

    if (!ApiConfig.useMockBackend) {
      try {
        final payload = {
          'dosen_id': dosenId,
          'semester_id': semesterId,
          'selectedSlotIds': selectedSlotIds,
          'slotTags': tagsMap.map((k, v) => MapEntry(k, v.toJson())),
        };
        final res = await _httpHelper.makeOnlineRequest(
          '/availability/index.php',
          method: 'POST',
          body: payload,
        );
        if (res is Map && res['status'] == 'success' && res['data'] != null) {
          final model = AvailabilityModel.fromJson(Map<String, dynamic>.from(res['data']));
          MockDatabase.currentAvailability = model;
          return model;
        }
      } catch (_) {}
    }

    await Future.delayed(const Duration(milliseconds: 150));

    final availability = AvailabilityModel(
      id: 'AVL_${DateTime.now().millisecondsSinceEpoch}',
      dosenId: dosenId,
      semesterId: semesterId,
      selectedSlotIds: selectedSlotIds,
      slotTags: tagsMap,
      status: 'submitted',
      submittedAt: DateTime.now(),
      updatedAt: DateTime.now(),
    );

    MockDatabase.currentAvailability = availability;

    MockDatabase.availabilityHistory.insert(
      0,
      AvailabilityHistoryItem(
        id: availability.id,
        submittedAt: DateTime.now(),
        slotCount: selectedSlotIds.length,
        status: 'submitted',
        semesterNama: 'Ganjil 2026/2027',
      ),
    );

    return availability;
  }

  /// Validate pre-submit
  Future<({bool valid, int required, int provided, String? message})> validatePreSubmit({
    required String dosenId,
    required List<String> selectedSlotIds,
  }) async {
    await Future.delayed(const Duration(milliseconds: 150));

    final mataKuliah = await _masterDataService.getMataKuliah(dosenId);
    final totalSks = mataKuliah.fold<int>(0, (sum, mk) => sum + mk.sks);

    if (selectedSlotIds.length < totalSks) {
      return (
        valid: false,
        required: totalSks,
        provided: selectedSlotIds.length,
        message: 'Jumlah slot yang dipilih (${selectedSlotIds.length}) kurang dari total SKS ($totalSks). Silakan tambah minimal ${totalSks - selectedSlotIds.length} slot lagi.',
      );
    }
    return (
      valid: true,
      required: totalSks,
      provided: selectedSlotIds.length,
      message: null,
    );
  }

  /// GET availability history
  Future<List<AvailabilityHistoryItem>> getAvailabilityHistory(String dosenId) async {
    await Future.delayed(MockDatabase.defaultDelay);
    return List.unmodifiable(MockDatabase.availabilityHistory);
  }

  /// GET Admin Submission Toggle status
  Future<bool> getSubmissionActive() async {
    return MockDatabase.isSubmissionActive;
  }

  Future<bool> getSubmissionWindowStatus() async {
    if (!ApiConfig.useMockBackend) {
      try {
        final data = await _httpHelper.makeOnlineRequest('/availability/status.php');
        if (data is Map && data['status'] == 'success' && data['isActive'] != null) {
          MockDatabase.isSubmissionActive = (data['isActive'] == true);
          return MockDatabase.isSubmissionActive;
        }
      } catch (_) {}
    }
    return MockDatabase.isSubmissionActive;
  }

  /// TOGGLE Admin Submission ON / OFF
  Future<bool> toggleSubmissionActive() async {
    MockDatabase.isSubmissionActive = !MockDatabase.isSubmissionActive;
    await setSubmissionWindowStatus(MockDatabase.isSubmissionActive);
    return MockDatabase.isSubmissionActive;
  }

  Future<void> setSubmissionWindowStatus(bool active) async {
    MockDatabase.isSubmissionActive = active;
    if (!ApiConfig.useMockBackend) {
      await _httpHelper.makeOnlineRequest(
        '/availability/status.php',
        method: 'POST',
        body: {'active': active},
      );
    }
    await Future.delayed(const Duration(milliseconds: 150));
  }

  /// KaProdi Verify Submission for a Lecturer
  Future<void> kajurVerifySubmission(String dosenId) async {
    MockDatabase.dosenSubmissionStatus[dosenId] = 'Diverifikasi KaProdi';
    if (!ApiConfig.useMockBackend) {
      try {
        await _httpHelper.makeOnlineRequest(
          '/availability/verify.php',
          method: 'POST',
          body: {'action': 'verify_kajur', 'dosenId': dosenId},
        );
      } catch (_) {}
    }
    await Future.delayed(const Duration(milliseconds: 200));
  }

  /// GET Multi-tier status of lecturer submission
  String getDosenSubmissionStatus(String dosenId) {
    return MockDatabase.dosenSubmissionStatus[dosenId] ?? 'Belum Mengisi';
  }

  /// GET Occupied Slot IDs taken by other lecturers
  Set<String> getOccupiedSlotsForOtherDosen(String currentDosenId) {
    return {'SLOT010', 'SLOT025'};
  }

  /// GET All Teaching Proposals
  Future<List<AjuanPengajaranModel>> getAjuanPengajaranList({
    String? dosenId,
    String? fakultas,
    String? prodi,
    String? status,
  }) async {
    if (!ApiConfig.useMockBackend) {
      try {
        final queryParams = <String>[];
        if (dosenId != null && dosenId.isNotEmpty) queryParams.add('dosenId=$dosenId');
        if (fakultas != null && fakultas.isNotEmpty) queryParams.add('fakultas=${Uri.encodeComponent(fakultas)}');
        if (prodi != null && prodi.isNotEmpty) queryParams.add('prodi=${Uri.encodeComponent(prodi)}');
        if (status != null && status.isNotEmpty) queryParams.add('status=$status');

        final qs = queryParams.isNotEmpty ? '?${queryParams.join('&')}' : '';
        final data = await _httpHelper.makeOnlineRequest('/ajuan/index.php$qs');
        if (data is Map && data['status'] == 'success' && data['data'] != null) {
          final list = (data['data'] as List)
              .map((a) => AjuanPengajaranModel.fromJson(a))
              .toList();
          if (list.isNotEmpty) {
            MockDatabase.ajuanPengajaranList
              ..clear()
              ..addAll(list);
            return list;
          }
        }
      } catch (_) {}
    }
    await MockDatabase.initLocalCache();
    await Future.delayed(const Duration(milliseconds: 150));
    final filtered = MockDatabase.ajuanPengajaranList.where((a) {
      final isGedungDeleted = MockDatabase.deletedGedungIds.contains(a.gedungNama);
      final isRuanganDeleted = MockDatabase.deletedRuanganIds.contains(a.ruanganNama);
      final isMatkulDeleted = MockDatabase.deletedMatkulIds.contains(a.mataKuliahId) || MockDatabase.deletedMatkulIds.contains(a.mataKuliahNama);
      final isDosenDeleted = MockDatabase.deletedUserIds.contains(a.dosenId) || MockDatabase.deletedUserIds.contains(a.dosenNama);
      final isFakultasDeleted = MockDatabase.deletedFakultasIds.contains(a.fakultasNama);
      if (isGedungDeleted || isRuanganDeleted || isMatkulDeleted || isDosenDeleted || isFakultasDeleted) {
        return false;
      }
      if (dosenId != null && dosenId.isNotEmpty && a.dosenId != dosenId) return false;
      if (fakultas != null && fakultas.isNotEmpty && a.fakultasNama != fakultas) return false;
      if (prodi != null && prodi.isNotEmpty && a.jurusanNama != prodi) return false;
      if (status != null && status.isNotEmpty && a.status != status) return false;
      return true;
    }).toList();
    return List.unmodifiable(filtered);
  }

  /// SUBMIT New Teaching Proposal
  Future<AjuanPengajaranModel> submitAjuanPengajaran(AjuanPengajaranModel ajuan) async {
    if (!ApiConfig.useMockBackend) {
      try {
        final data = await _httpHelper.makeOnlineRequest(
          '/ajuan/index.php',
          method: 'POST',
          body: ajuan.toJson(),
        );
        if (data is Map && data['status'] == 'success' && data['data'] != null) {
          final saved = AjuanPengajaranModel.fromJson(data['data']);
          MockDatabase.ajuanPengajaranList.insert(0, saved);
          MockDatabase.dosenSubmissionStatus[saved.dosenId] = 'Diajukan';
          return saved;
        }
      } catch (_) {}
    }
    await Future.delayed(const Duration(milliseconds: 250));
    MockDatabase.ajuanPengajaranList.insert(0, ajuan);
    MockDatabase.dosenSubmissionStatus[ajuan.dosenId] = 'Diajukan';
    return ajuan;
  }

  /// UPDATE Teaching Proposal
  Future<AjuanPengajaranModel> updateAjuanPengajaran(AjuanPengajaranModel updated) async {
    if (!ApiConfig.useMockBackend) {
      try {
        final data = await _httpHelper.makeOnlineRequest(
          '/ajuan/index.php',
          method: 'PUT',
          body: updated.toJson(),
        );
        if (data is Map && data['status'] == 'success' && data['data'] != null) {
          final saved = AjuanPengajaranModel.fromJson(data['data']);
          final idx = MockDatabase.ajuanPengajaranList.indexWhere((a) => a.id == saved.id);
          if (idx != -1) MockDatabase.ajuanPengajaranList[idx] = saved;
          await MockDatabase.saveLocalAjuan();
          return saved;
        }
      } catch (_) {}
    }
    await Future.delayed(const Duration(milliseconds: 200));
    final index = MockDatabase.ajuanPengajaranList.indexWhere((a) => a.id == updated.id);
    if (index != -1) {
      MockDatabase.ajuanPengajaranList[index] = updated.copyWith(updatedAt: DateTime.now());
      await MockDatabase.saveLocalAjuan();
      return MockDatabase.ajuanPengajaranList[index];
    }
    MockDatabase.ajuanPengajaranList.add(updated);
    await MockDatabase.saveLocalAjuan();
    return updated;
  }

  /// DELETE Teaching Proposal
  Future<void> deleteAjuanPengajaran(String ajuanId) async {
    if (!ApiConfig.useMockBackend) {
      try {
        await _httpHelper.makeOnlineRequest('/ajuan/index.php?id=$ajuanId', method: 'DELETE');
      } catch (_) {}
    }
    await Future.delayed(const Duration(milliseconds: 150));
    MockDatabase.ajuanPengajaranList.removeWhere((a) => a.id == ajuanId);
    await MockDatabase.saveLocalAjuan();
  }

  /// DELETE Multiple Teaching Proposals
  Future<void> deleteMultipleAjuanPengajaran(List<String> ajuanIds) async {
    if (ajuanIds.isEmpty) return;
    if (!ApiConfig.useMockBackend) {
      try {
        await _httpHelper.makeOnlineRequest(
          '/ajuan/index.php',
          method: 'DELETE',
          body: {'ids': ajuanIds},
        );
      } catch (_) {
        for (final id in ajuanIds) {
          try {
            await _httpHelper.makeOnlineRequest('/ajuan/index.php?id=$id', method: 'DELETE');
          } catch (_) {}
        }
      }
    }
    await Future.delayed(const Duration(milliseconds: 150));
    MockDatabase.ajuanPengajaranList.removeWhere((a) => ajuanIds.contains(a.id));
  }

  /// KaProdi Verify & Forward to Dekan
  Future<AjuanPengajaranModel> kaprodiVerifyAjuan(
    String ajuanId, {
    AjuanPengajaranModel? updatedData,
    String? catatan,
  }) async {
    if (!ApiConfig.useMockBackend) {
      try {
        final data = await _httpHelper.makeOnlineRequest(
          '/ajuan/verify.php',
          method: 'POST',
          body: {
            'action': 'kaprodi_verify',
            'ajuanId': ajuanId,
            'catatan': catatan,
            'updatedData': updatedData?.toJson(),
          },
        );
        if (data is Map && data['status'] == 'success' && data['data'] != null) {
          final verified = AjuanPengajaranModel.fromJson(data['data']);
          final idx = MockDatabase.ajuanPengajaranList.indexWhere((a) => a.id == ajuanId);
          if (idx != -1) MockDatabase.ajuanPengajaranList[idx] = verified;
          MockDatabase.dosenSubmissionStatus[verified.dosenId] = 'Diverifikasi KaProdi';
          return verified;
        }
      } catch (_) {}
    }

    await Future.delayed(const Duration(milliseconds: 250));
    final index = MockDatabase.ajuanPengajaranList.indexWhere((a) => a.id == ajuanId);
    if (index != -1) {
      final base = updatedData ?? MockDatabase.ajuanPengajaranList[index];
      final verified = base.copyWith(
        status: 'menunggu_dekan',
        catatanKaProdi: catatan ?? base.catatanKaProdi ?? 'Diverifikasi oleh KaProdi.',
        updatedAt: DateTime.now(),
      );
      MockDatabase.ajuanPengajaranList[index] = verified;
      MockDatabase.dosenSubmissionStatus[verified.dosenId] = 'Diverifikasi KaProdi';
      return verified;
    }
    throw const ApiException('NOT_FOUND', 'Ajuan tidak ditemukan');
  }

  /// KaProdi Reject
  Future<AjuanPengajaranModel> kaprodiRejectAjuan(String ajuanId, String alasan) async {
    if (!ApiConfig.useMockBackend) {
      try {
        final data = await _httpHelper.makeOnlineRequest(
          '/ajuan/verify.php',
          method: 'POST',
          body: {
            'action': 'kaprodi_reject',
            'ajuanId': ajuanId,
            'alasan': alasan,
          },
        );
        if (data is Map && data['status'] == 'success' && data['data'] != null) {
          final rejected = AjuanPengajaranModel.fromJson(data['data']);
          final idx = MockDatabase.ajuanPengajaranList.indexWhere((a) => a.id == ajuanId);
          if (idx != -1) MockDatabase.ajuanPengajaranList[idx] = rejected;
          return rejected;
        }
      } catch (_) {}
    }

    await Future.delayed(const Duration(milliseconds: 250));
    final index = MockDatabase.ajuanPengajaranList.indexWhere((a) => a.id == ajuanId);
    if (index != -1) {
      final rejected = MockDatabase.ajuanPengajaranList[index].copyWith(
        status: 'ditolak_kaprodi',
        alasanPenolakan: alasan,
        updatedAt: DateTime.now(),
      );
      MockDatabase.ajuanPengajaranList[index] = rejected;
      return rejected;
    }
    throw const ApiException('NOT_FOUND', 'Ajuan tidak ditemukan');
  }

  /// Dekan Approve & Forward to Admin
  Future<AjuanPengajaranModel> dekanApproveAjuan(
    String ajuanId, {
    AjuanPengajaranModel? updatedData,
    String? catatan,
  }) async {
    if (!ApiConfig.useMockBackend) {
      try {
        final data = await _httpHelper.makeOnlineRequest(
          '/ajuan/verify.php',
          method: 'POST',
          body: {
            'action': 'dekan_approve',
            'ajuanId': ajuanId,
            'catatan': catatan,
            'updatedData': updatedData?.toJson(),
          },
        );
        if (data is Map && data['status'] == 'success' && data['data'] != null) {
          final approved = AjuanPengajaranModel.fromJson(data['data']);
          final idx = MockDatabase.ajuanPengajaranList.indexWhere((a) => a.id == ajuanId);
          if (idx != -1) MockDatabase.ajuanPengajaranList[idx] = approved;
          MockDatabase.dosenSubmissionStatus[approved.dosenId] = 'Disetujui Dekan';
          await MockDatabase.saveLocalAjuan();
          return approved;
        }
      } catch (_) {}
    }

    await Future.delayed(const Duration(milliseconds: 250));
    final index = MockDatabase.ajuanPengajaranList.indexWhere((a) => a.id == ajuanId);
    if (index != -1) {
      final base = updatedData ?? MockDatabase.ajuanPengajaranList[index];
      final approved = base.copyWith(
        status: 'menunggu_admin',
        catatanDekan: catatan ?? base.catatanDekan ?? 'Disetujui Dekan Fakultas.',
        updatedAt: DateTime.now(),
      );
      MockDatabase.ajuanPengajaranList[index] = approved;
      MockDatabase.dosenSubmissionStatus[approved.dosenId] = 'Disetujui Dekan';
      await MockDatabase.saveLocalAjuan();
      return approved;
    }
    throw const ApiException('NOT_FOUND', 'Ajuan tidak ditemukan');
  }

  /// Dekan Reject
  Future<AjuanPengajaranModel> dekanRejectAjuan(String ajuanId, String alasan) async {
    if (!ApiConfig.useMockBackend) {
      try {
        final data = await _httpHelper.makeOnlineRequest(
          '/ajuan/verify.php',
          method: 'POST',
          body: {
            'action': 'dekan_reject',
            'ajuanId': ajuanId,
            'alasan': alasan,
          },
        );
        if (data is Map && data['status'] == 'success' && data['data'] != null) {
          final rejected = AjuanPengajaranModel.fromJson(data['data']);
          final idx = MockDatabase.ajuanPengajaranList.indexWhere((a) => a.id == ajuanId);
          if (idx != -1) MockDatabase.ajuanPengajaranList[idx] = rejected;
          return rejected;
        }
      } catch (_) {}
    }

    await Future.delayed(const Duration(milliseconds: 250));
    final index = MockDatabase.ajuanPengajaranList.indexWhere((a) => a.id == ajuanId);
    if (index != -1) {
      final rejected = MockDatabase.ajuanPengajaranList[index].copyWith(
        status: 'ditolak_dekan',
        alasanPenolakan: alasan,
        updatedAt: DateTime.now(),
      );
      MockDatabase.ajuanPengajaranList[index] = rejected;
      return rejected;
    }
    throw const ApiException('NOT_FOUND', 'Ajuan tidak ditemukan');
  }

  /// Admin Final Approve & Official Schedule Generation
  Future<AjuanPengajaranModel> adminApproveFinalAjuan(
    String ajuanId, {
    AjuanPengajaranModel? updatedData,
    String? catatan,
  }) async {
    if (!ApiConfig.useMockBackend) {
      try {
        final data = await _httpHelper.makeOnlineRequest(
          '/ajuan/verify.php',
          method: 'POST',
          body: {
            'action': 'admin_approve',
            'ajuanId': ajuanId,
            'catatan': catatan,
            'updatedData': updatedData?.toJson(),
          },
        );
        if (data is Map && data['status'] == 'success' && data['data'] != null) {
          final approved = AjuanPengajaranModel.fromJson(data['data']);
          final idx = MockDatabase.ajuanPengajaranList.indexWhere((a) => a.id == ajuanId);
          if (idx != -1) MockDatabase.ajuanPengajaranList[idx] = approved;
          await MockDatabase.saveLocalAjuan();
          await MockDatabase.saveLocalJadwal();
          return approved;
        }
      } catch (_) {}
    }

    await Future.delayed(const Duration(milliseconds: 300));
    final index = MockDatabase.ajuanPengajaranList.indexWhere((a) => a.id == ajuanId);
    if (index != -1) {
      final base = updatedData ?? MockDatabase.ajuanPengajaranList[index];
      final approved = base.copyWith(
        status: 'disetujui_admin',
        catatanAdmin: catatan ?? base.catatanAdmin ?? 'Ditetapkan resmi oleh Admin Institusi.',
        updatedAt: DateTime.now(),
      );
      MockDatabase.ajuanPengajaranList[index] = approved;

      final newJadwal = JadwalModel(
        id: 'JDW_${base.id}',
        mataKuliahId: base.mataKuliahId,
        mataKuliahNama: base.mataKuliahNama,
        sks: base.sks,
        ruanganNama: base.ruanganNama,
        gedungNama: base.gedungNama,
        kelasNama: base.kelasNama,
        hari: base.hari,
        jamMulai: base.jamMulai,
        jamSelesai: base.jamSelesai,
        semesterNama: 'Ganjil 2026/2027',
        jumlahMahasiswa: base.jumlahMahasiswa,
        dosenNama: base.dosenNama,
        fakultasNama: base.fakultasNama,
        jurusanNama: base.jurusanNama,
      );
      MockDatabase.jadwalFinal.removeWhere((j) => j.id == newJadwal.id || (j.mataKuliahNama == newJadwal.mataKuliahNama && j.kelasNama == newJadwal.kelasNama));
      MockDatabase.jadwalFinal.add(newJadwal);
      MockDatabase.jadwalGlobalMaster.removeWhere((j) => j.id == newJadwal.id || (j.mataKuliahNama == newJadwal.mataKuliahNama && j.kelasNama == newJadwal.kelasNama));
      MockDatabase.jadwalGlobalMaster.add(newJadwal);

      await MockDatabase.saveLocalAjuan();
      await MockDatabase.saveLocalJadwal();
      return approved;
    }
    throw const ApiException('NOT_FOUND', 'Ajuan tidak ditemukan');
  }

  /// Admin Reject
  Future<AjuanPengajaranModel> adminRejectAjuan(String ajuanId, String alasan) async {
    if (!ApiConfig.useMockBackend) {
      try {
        final data = await _httpHelper.makeOnlineRequest(
          '/ajuan/verify.php',
          method: 'POST',
          body: {
            'action': 'admin_reject',
            'ajuanId': ajuanId,
            'alasan': alasan,
          },
        );
        if (data is Map && data['status'] == 'success' && data['data'] != null) {
          final rejected = AjuanPengajaranModel.fromJson(data['data']);
          final idx = MockDatabase.ajuanPengajaranList.indexWhere((a) => a.id == ajuanId);
          if (idx != -1) MockDatabase.ajuanPengajaranList[idx] = rejected;
          return rejected;
        }
      } catch (_) {}
    }

    await Future.delayed(const Duration(milliseconds: 250));
    final index = MockDatabase.ajuanPengajaranList.indexWhere((a) => a.id == ajuanId);
    if (index != -1) {
      final rejected = MockDatabase.ajuanPengajaranList[index].copyWith(
        status: 'ditolak_admin',
        alasanPenolakan: alasan,
        updatedAt: DateTime.now(),
      );
      MockDatabase.ajuanPengajaranList[index] = rejected;
      return rejected;
    }
    throw const ApiException('NOT_FOUND', 'Ajuan tidak ditemukan');
  }

  /// Dosen mengajukan banding
  Future<AjuanPengajaranModel> submitBandingAjuan({
    required String ajuanId,
    required String alasan,
    String? preferensiHari,
    String? preferensiJam,
  }) async {
    if (!ApiConfig.useMockBackend) {
      try {
        final data = await _httpHelper.makeOnlineRequest(
          '/ajuan/banding.php',
          method: 'POST',
          body: {
            'action': 'submit_banding',
            'ajuanId': ajuanId,
            'alasanBanding': alasan,
            'preferensiHari': preferensiHari,
            'preferensiJam': preferensiJam,
          },
        );
        if (data is Map && data['status'] == 'success' && data['data'] != null) {
          final updated = AjuanPengajaranModel.fromJson(data['data']);
          final idx = MockDatabase.ajuanPengajaranList.indexWhere((a) => a.id == ajuanId);
          if (idx != -1) MockDatabase.ajuanPengajaranList[idx] = updated;
          return updated;
        }
      } catch (_) {}
    }

    await Future.delayed(const Duration(milliseconds: 250));
    final index = MockDatabase.ajuanPengajaranList.indexWhere((a) => a.id == ajuanId);
    if (index != -1) {
      final updated = MockDatabase.ajuanPengajaranList[index].copyWith(
        status: 'menunggu_banding',
        alasanBanding: alasan,
        preferensiBandingHari: preferensiHari,
        preferensiBandingJam: preferensiJam,
        updatedAt: DateTime.now(),
      );
      MockDatabase.ajuanPengajaranList[index] = updated;
      return updated;
    }
    throw const ApiException('NOT_FOUND', 'Ajuan tidak ditemukan');
  }

  /// Admin memproses pengajuan banding
  Future<AjuanPengajaranModel> adminProcessBanding({
    required String ajuanId,
    required bool approve,
    String? catatanAdmin,
    AjuanPengajaranModel? updatedData,
  }) async {
    if (!ApiConfig.useMockBackend) {
      try {
        final data = await _httpHelper.makeOnlineRequest(
          '/ajuan/banding.php',
          method: 'POST',
          body: {
            'action': 'admin_process_banding',
            'ajuanId': ajuanId,
            'approve': approve,
            'catatanAdmin': catatanAdmin,
            'updatedData': updatedData?.toJson(),
          },
        );
        if (data is Map && data['status'] == 'success' && data['data'] != null) {
          final updated = AjuanPengajaranModel.fromJson(data['data']);
          final idx = MockDatabase.ajuanPengajaranList.indexWhere((a) => a.id == ajuanId);
          if (idx != -1) MockDatabase.ajuanPengajaranList[idx] = updated;
          return updated;
        }
      } catch (_) {}
    }

    await Future.delayed(const Duration(milliseconds: 300));
    final index = MockDatabase.ajuanPengajaranList.indexWhere((a) => a.id == ajuanId);
    if (index != -1) {
      final base = updatedData ?? MockDatabase.ajuanPengajaranList[index];
      final newStatus = approve ? 'banding_disetujui' : 'banding_ditolak';
      final updated = base.copyWith(
        status: newStatus,
        catatanAdmin: catatanAdmin ?? (approve ? 'Banding disetujui. Jadwal telah disesuaikan resmi.' : 'Banding ditolak oleh Admin.'),
        updatedAt: DateTime.now(),
      );
      MockDatabase.ajuanPengajaranList[index] = updated;

      final jdwIndex = MockDatabase.jadwalFinal.indexWhere((j) => j.id == 'JDW_${base.id}');
      if (approve) {
        if (jdwIndex != -1) {
          MockDatabase.jadwalFinal[jdwIndex] = JadwalModel(
            id: 'JDW_${base.id}',
            mataKuliahId: base.mataKuliahId,
            mataKuliahNama: base.mataKuliahNama,
            sks: base.sks,
            ruanganNama: base.ruanganNama,
            gedungNama: base.gedungNama,
            kelasNama: base.kelasNama,
            hari: base.hari,
            jamMulai: base.jamMulai,
            jamSelesai: base.jamSelesai,
            semesterNama: 'Ganjil 2026/2027',
            jumlahMahasiswa: base.jumlahMahasiswa,
            dosenNama: base.dosenNama,
            fakultasNama: base.fakultasNama,
            jurusanNama: base.jurusanNama,
          );
        }
      }
      return updated;
    }
    throw const ApiException('NOT_FOUND', 'Ajuan tidak ditemukan');
  }
}
