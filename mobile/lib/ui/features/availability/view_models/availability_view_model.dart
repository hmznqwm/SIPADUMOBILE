// File: availability_view_model.dart
// Deskripsi: ViewModel (ChangeNotifier) untuk manajemen status & logika matriks ketersediaan waktu dosen.
// Fungsi: Mengelola daftar slot waktu, pemilihan slot, hitung SKS minimal, validasi pra-pengajuan, preset waktu, dan penyimpanan ketersediaan.

import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../../../data/models/availability_model.dart';
import '../../../../data/models/mata_kuliah_model.dart';
import '../../../../data/models/slot_waktu_model.dart';
import '../../../../data/repositories/auth_repository.dart';
import '../../../../data/repositories/availability_repository.dart';

/// [PRESENTASI] AvailabilityViewModel (Business Logic):
/// Merupakan inti dari fitur kesediaan mengajar. Mengelola state pengisian slot waktu secara real-time,
/// preset jadwal otomatis (Pagi/Siang), serta mem-blokir slot yang telah dikunci (occupied) oleh sistem.
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

  // Konteks user untuk persistensi tag
  String _currentDosenId = '';
  String _currentSemesterId = 'SEM001';

  /// Simpan _slotTags ke SharedPreferences secara langsung (fire & forget)
  void _persistTagsToCache() {
    if (_currentDosenId.isEmpty) return;
    SharedPreferences.getInstance().then((prefs) {
      prefs.setString(
        'slot_tags_${_currentDosenId}_$_currentSemesterId',
        jsonEncode(_slotTags.map((k, v) => MapEntry(k, v.toJson()))),
      );
    });
  }

  /// Total SKS seluruh mata kuliah diampu (informasi beban).
  int get totalRequiredSks => _mataKuliahList.fold(0, (sum, mk) => sum + mk.sks);

  /// Total slot 50-menit yang WAJIB dipilih (Teori/Praktikum x jumlah kelas).
  int get totalRequiredSlots =>
      _mataKuliahList.fold(0, (sum, mk) => sum + mk.totalSlotDibutuhkan);

  int get selectedCount => _selectedSlotIds.length;

  /// Sisa slot yang masih harus dipilih (negatif = kelebihan).
  int get remainingSlots => totalRequiredSlots - selectedCount;

  /// True jika jumlah slot sudah TEPAT sesuai beban mengajar.
  bool get meetsMinimumSks =>
      totalRequiredSlots > 0 ? selectedCount == totalRequiredSlots : selectedCount > 0;

  bool get isOverQuota => totalRequiredSlots > 0 && selectedCount > totalRequiredSlots;

  Future<void> loadAvailabilityData() async {
    final user = _authRepository.currentUser;
    if (user == null) return;

    // Simpan konteks user agar _persistTagsToCache bisa digunakan
    _currentDosenId = user.id;
    _currentSemesterId = 'SEM001';

    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      _allSlots = await _availabilityRepository.getSlotWaktu();
      _mataKuliahList = await _availabilityRepository.getMataKuliah(user.id);
      if (_mataKuliahList.isEmpty && user.email.isNotEmpty) {
        _mataKuliahList = await _availabilityRepository.getMataKuliah(user.email);
      }
      _availability = await _availabilityRepository.getAvailability(user.id, 'SEM001');
      _isSubmissionActive = await _availabilityRepository.getSubmissionWindowStatus();
      _occupiedSlotIds = _availabilityRepository.getOccupiedSlotsForOtherDosen(user.id);

      if (_availability != null) {
        _selectedSlotIds = Set.from(_availability!.selectedSlotIds);
        // [BUG FIX] Jangan timpa in-memory tags jika sudah ada (mencegah hilangnya
        // tag yang baru diset tapi belum di-submit ke backend).
        // Prioritas: in-memory > backend model > SharedPreferences (sudah di-merge di service layer).
        if (_slotTags.isEmpty) {
          _slotTags = Map.from(_availability!.slotTags);
        } else {
          // Merge: tambahkan slot baru dari backend, pertahankan tag in-memory yang sudah ada
          for (final entry in _availability!.slotTags.entries) {
            _slotTags.putIfAbsent(entry.key, () => entry.value);
          }
        }
      }

      // Sanitasi: buang slot yang tidak ada di master & tag yatim (slot tak dipilih)
      if (_allSlots.isNotEmpty) {
        final validIds = _allSlots.map((s) => s.id).toSet();
        _selectedSlotIds.removeWhere((id) => !validIds.contains(id));
      }
      _slotTags.removeWhere((k, _) => !_selectedSlotIds.contains(k));
    } catch (e) {
      _errorMessage = e.toString();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// [PRESENTASI] Aturan Kuota Slot:
  /// 1 slot matriks = 50 menit. Kebutuhan slot dihitung per mata kuliah & per kelas:
  /// Teori 3 SKS = 3 slot, Praktikum 1 SKS (90 menit) = 2 slot. Dosen wajib memilih TEPAT
  /// sejumlah slot tersebut (tidak boleh kurang, tidak boleh lebih).
  int slotsNeededForTag(SlotTagInfo tag) {
    final mk = _mataKuliahList.where((m) => m.id == tag.mataKuliahId).firstOrNull;
    if (mk != null) return mk.slotPerPertemuan;
    final fak = tag.fakultasNama.toLowerCase();
    final isLab = tag.sks == 1 && (fak.contains('sains') || fak.contains('teknik'));
    if (tag.sks <= 0) return 1;
    return isLab ? ((tag.sks * 90) / 50).ceil() : tag.sks;
  }

  /// Semua slot yang saat ini terikat ke pasangan (matkul, kelas) yang sama dengan [tag].
  List<String> _blockOf(SlotTagInfo tag) => _slotTags.entries
      .where((e) => e.value.mataKuliahId == tag.mataKuliahId && e.value.kelasNama == tag.kelasNama)
      .map((e) => e.key)
      .toList();

  bool _exceedsQuota(int resultingCount) =>
      totalRequiredSlots > 0 && resultingCount > totalRequiredSlots;

  String get _quotaMessage =>
      'Kuota penuh: beban mengajar Anda $totalRequiredSlots slot ($totalRequiredSks SKS). '
      'Lepas slot lain terlebih dahulu sebelum menambah.';

  bool _fail(String message) {
    _errorMessage = message;
    _successMessage = null;
    notifyListeners();
    return false;
  }

  void _commit() {
    _errorMessage = null;
    _successMessage = null;
    _persistTagsToCache();
    notifyListeners();
  }

  void clearMessages() {
    _errorMessage = null;
    _successMessage = null;
    notifyListeners();
  }

  /// [PRESENTASI] toggleSlot & Conflict Handling:
  /// Pilih / lepas satu slot. Jika slot adalah bagian dari blok mata kuliah,
  /// seluruh blok dilepas sekaligus agar tidak tersisa blok "bolong".
  /// Return `false` jika aksi ditolak (kuota penuh / dikunci admin).
  bool toggleSlot(String slotId, [SlotTagInfo? tag]) {
    if (!_isSubmissionActive) return _fail('Pengisian ketersediaan sedang dikunci oleh Admin.');
    if (_occupiedSlotIds.contains(slotId)) return _fail('Slot ini sedang dikunci dan tidak dapat dipilih.');

    if (_selectedSlotIds.contains(slotId)) {
      final existing = _slotTags[slotId];
      final ids = existing != null ? _blockOf(existing) : [slotId];
      for (final id in ids) {
        _selectedSlotIds.remove(id);
        _slotTags.remove(id);
      }
      _selectedSlotIds.remove(slotId);
      _commit();
      return true;
    }

    if (tag != null) return setSlotTag(slotId, tag);
    if (_exceedsQuota(_selectedSlotIds.length + 1)) return _fail(_quotaMessage);
    _selectedSlotIds.add(slotId);
    _commit();
    return true;
  }

  /// Tetapkan peruntukan slot:
  /// - `tag == null`  -> Waktu Fleksibel (1 slot ini saja).
  /// - `tag != null`  -> Tautkan ke matkul & kelas, otomatis mengalokasikan blok slot
  ///   berurutan sesuai SKS (tanpa menembus jam istirahat / slot milik matkul lain).
  /// Return `false` jika ditolak (pesan error tersedia di [errorMessage]).
  bool setSlotTag(String slotId, SlotTagInfo? tag) {
    if (!_isSubmissionActive) return _fail('Pengisian ketersediaan sedang dikunci oleh Admin.');
    if (_occupiedSlotIds.contains(slotId)) return _fail('Slot ini sedang dikunci dan tidak dapat dipilih.');

    if (tag == null) {
      // Jika slot ini sebelumnya bagian dari blok matkul, lepas seluruh blok itu.
      final existing = _slotTags[slotId];
      final freed = existing != null ? _blockOf(existing) : const <String>[];
      final resulting = {..._selectedSlotIds}
        ..removeAll(freed)
        ..add(slotId);
      if (_exceedsQuota(resulting.length)) return _fail(_quotaMessage);
      for (final id in freed) {
        _selectedSlotIds.remove(id);
        _slotTags.remove(id);
      }
      _selectedSlotIds.add(slotId);
      _slotTags.remove(slotId);
      _commit();
      return true;
    }

    final needed = slotsNeededForTag(tag);
    final current = _allSlots.where((s) => s.id == slotId).firstOrNull;
    if (current == null) return _fail('Slot waktu tidak ditemukan. Tarik ke bawah untuk memuat ulang.');

    final daySlots = _allSlots.where((s) => s.hari == current.hari).toList()
      ..sort((a, b) => a.jamMulai.compareTo(b.jamMulai));
    final startIndex = daySlots.indexWhere((s) => s.id == slotId);

    final block = <SlotWaktuModel>[];
    for (int i = 0; i < needed; i++) {
      final idx = startIndex + i;
      if (idx >= daySlots.length) {
        return _fail(
          '${tag.mataKuliahNama} butuh $needed slot berurutan (${needed * 50} menit), '
          'tetapi slot di hari ${current.hari} mulai ${current.jamMulai} tidak cukup. Pilih jam mulai lebih awal.',
        );
      }
      final s = daySlots[idx];
      if (block.isNotEmpty && block.last.jamSelesai != s.jamMulai) {
        return _fail(
          'Blok ${tag.mataKuliahNama} ($needed slot) akan terpotong jeda ${block.last.jamSelesai}-${s.jamMulai}. '
          'Pilih jam mulai lain agar perkuliahan berlangsung tanpa terputus.',
        );
      }
      if (_occupiedSlotIds.contains(s.id)) {
        return _fail('Jam ${s.label} sedang dikunci sehingga blok ${tag.mataKuliahNama} tidak muat.');
      }
      final other = _slotTags[s.id];
      if (other != null &&
          !(other.mataKuliahId == tag.mataKuliahId && other.kelasNama == tag.kelasNama)) {
        return _fail(
          'Jam ${s.label} sudah ditautkan ke ${other.mataKuliahNama} (${other.kelasNama}). '
          'Lepas tautan tersebut atau pilih jam lain.',
        );
      }
      block.add(s);
    }

    final oldIds = _blockOf(tag);
    final blockIds = block.map((s) => s.id).toList();
    final resulting = {..._selectedSlotIds}
      ..removeAll(oldIds)
      ..addAll(blockIds);
    if (_exceedsQuota(resulting.length)) {
      final sisa = totalRequiredSlots - (_selectedSlotIds.length - oldIds.length);
      return _fail(
        'Kuota tidak cukup: ${tag.mataKuliahNama} butuh $needed slot, sisa kuota Anda ${sisa < 0 ? 0 : sisa} slot. '
        'Lepas slot Waktu Fleksibel atau tautan lain terlebih dahulu.',
      );
    }

    for (final id in oldIds) {
      _selectedSlotIds.remove(id);
      _slotTags.remove(id);
    }
    for (final id in blockIds) {
      _selectedSlotIds.add(id);
      _slotTags[id] = tag;
    }
    _commit();
    return true;
  }

  /// Isi sisa kuota dengan slot Waktu Fleksibel sesuai filter, tanpa menyentuh blok matkul yang sudah ditautkan.
  void _applyPreset(bool Function(SlotWaktuModel s) filter) {
    if (!_isSubmissionActive) return;
    final keep = _selectedSlotIds.where((id) => _slotTags.containsKey(id)).toSet();
    final candidates = _allSlots
        .where((s) => filter(s) && !_occupiedSlotIds.contains(s.id) && !keep.contains(s.id))
        .map((s) => s.id)
        .toList();
    final room = totalRequiredSlots > 0 ? totalRequiredSlots - keep.length : candidates.length;
    _selectedSlotIds = {...keep, ...candidates.take(room < 0 ? 0 : room)};
    _slotTags.removeWhere((k, _) => !_selectedSlotIds.contains(k));
    _commit();
  }

  void selectPresetPagi() => _applyPreset((s) => s.jamMulai.compareTo('12:00') < 0);

  void selectPresetSiang() => _applyPreset((s) => s.jamMulai.compareTo('12:00') >= 0);

  void resetSelection() {
    if (!_isSubmissionActive) return;
    _selectedSlotIds.clear();
    _slotTags.clear();
    _commit();
  }

  /// Validasi lokal sebelum kirim. Return pesan error, atau null jika valid.
  String? _validateBeforeSubmit() {
    if (_mataKuliahList.isEmpty) {
      return 'Anda belum memiliki mata kuliah pengampu pada semester ini. Hubungi Admin/KaProdi untuk penugasan.';
    }
    if (_selectedSlotIds.isEmpty) return 'Belum ada slot waktu yang dipilih.';
    final need = totalRequiredSlots;
    final have = _selectedSlotIds.length;
    if (need > 0 && have > need) {
      return 'Slot dipilih ($have) melebihi beban mengajar Anda ($need slot / $totalRequiredSks SKS). Lepas ${have - need} slot.';
    }
    if (need > 0 && have < need) {
      return 'Slot dipilih ($have) belum memenuhi beban mengajar Anda ($need slot / $totalRequiredSks SKS). Tambah ${need - have} slot lagi.';
    }
    // Setiap blok matkul yang ditautkan harus utuh sesuai SKS
    final groups = <String, List<String>>{};
    _slotTags.forEach((sid, t) {
      if (_selectedSlotIds.contains(sid)) {
        groups.putIfAbsent('${t.mataKuliahId}||${t.kelasNama}', () => []).add(sid);
      }
    });
    for (final ids in groups.values) {
      final t = _slotTags[ids.first]!;
      final needed = slotsNeededForTag(t);
      if (ids.length != needed) {
        return 'Blok ${t.mataKuliahNama} (${t.kelasNama}) belum lengkap: ${ids.length} dari $needed slot. '
            'Tautkan ulang mata kuliah tersebut pada jam mulai yang diinginkan.';
      }
    }
    return null;
  }

  Future<bool> submitAvailability() async {
    final user = _authRepository.currentUser;
    if (user == null) return _fail('Sesi login berakhir. Silakan masuk kembali.');
    if (!_isSubmissionActive) return _fail('Pengisian ketersediaan sedang dikunci oleh Admin.');

    final localError = _validateBeforeSubmit();
    if (localError != null) return _fail(localError);

    _isSubmitting = true;
    _errorMessage = null;
    _successMessage = null;
    notifyListeners();

    try {
      // Bersihkan tag yatim sebelum dikirim
      _slotTags.removeWhere((k, _) => !_selectedSlotIds.contains(k));

      _availability = await _availabilityRepository.saveAvailability(
        dosenId: user.id,
        semesterId: _currentSemesterId,
        selectedSlotIds: _selectedSlotIds.toList(),
        slotTags: Map.of(_slotTags),
        mataKuliahList: _mataKuliahList,
        dosenNama: user.nama,
        dosenJurusan: user.jurusanNama,
        dosenFakultas: user.fakultasNama,
      );

      _successMessage =
          'Ketersediaan berhasil disimpan dan diteruskan sebagai ajuan ke KaProdi, Dekan & Admin. '
          'Lihat statusnya di tab "Ajuan Saya".';
      _isSubmitting = false;
      notifyListeners();
      return true;
    } catch (e) {
      _errorMessage = 'Gagal menyimpan ketersediaan: $e';
      _isSubmitting = false;
      notifyListeners();
      return false;
    }
  }
}
