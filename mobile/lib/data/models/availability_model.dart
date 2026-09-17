// File: availability_model.dart
// Deskripsi: Model data untuk ketersediaan waktu dosen (availability), riwayat pengajuan, dan course-slot tagging.
// Fungsi: Merepresentasikan data slot ketersediaan dosen, tag mata kuliah/kelas per slot, status persetujuan, serta item riwayat pengajuan.

class SlotTagInfo {
  final String mataKuliahId;
  final String mataKuliahNama;
  final String kelasNama;
  final String jurusanNama;
  final String fakultasNama;
  final int sks;

  const SlotTagInfo({
    required this.mataKuliahId,
    required this.mataKuliahNama,
    required this.kelasNama,
    required this.jurusanNama,
    required this.fakultasNama,
    this.sks = 3,
  });

  Map<String, dynamic> toJson() => {
    'mataKuliahId': mataKuliahId,
    'mataKuliahNama': mataKuliahNama,
    'kelasNama': kelasNama,
    'jurusanNama': jurusanNama,
    'fakultasNama': fakultasNama,
    'sks': sks,
  };

  factory SlotTagInfo.fromJson(Map<String, dynamic> json) => SlotTagInfo(
    mataKuliahId: json['mataKuliahId'] ?? json['mata_kuliah_id'] ?? '',
    mataKuliahNama: json['mataKuliahNama'] ?? json['mata_kuliah_nama'] ?? '',
    kelasNama: json['kelasNama'] ?? json['kelas_nama'] ?? '',
    jurusanNama: json['jurusanNama'] ?? json['jurusan_nama'] ?? '',
    fakultasNama: json['fakultasNama'] ?? json['fakultas_nama'] ?? '',
    sks: (json['sks'] ?? 3) is int ? (json['sks'] ?? 3) : int.tryParse(json['sks'].toString()) ?? 3,
  );
}

class AvailabilityModel {
  final String id;
  final String dosenId;
  final String semesterId;
  final List<String> selectedSlotIds;
  final Map<String, SlotTagInfo> slotTags; // slotId -> SlotTagInfo
  final String status; // 'draft', 'submitted', 'approved', 'rejected', 'revision'
  final DateTime? submittedAt;
  final DateTime? updatedAt;
  final String? catatan;

  const AvailabilityModel({
    required this.id,
    required this.dosenId,
    required this.semesterId,
    required this.selectedSlotIds,
    this.slotTags = const {},
    this.status = 'draft',
    this.submittedAt,
    this.updatedAt,
    this.catatan,
  });

  AvailabilityModel copyWith({
    List<String>? selectedSlotIds,
    Map<String, SlotTagInfo>? slotTags,
    String? status,
    DateTime? submittedAt,
    DateTime? updatedAt,
    String? catatan,
  }) {
    return AvailabilityModel(
      id: id,
      dosenId: dosenId,
      semesterId: semesterId,
      selectedSlotIds: selectedSlotIds ?? this.selectedSlotIds,
      slotTags: slotTags ?? this.slotTags,
      status: status ?? this.status,
      submittedAt: submittedAt ?? this.submittedAt,
      updatedAt: updatedAt ?? this.updatedAt,
      catatan: catatan ?? this.catatan,
    );
  }

  factory AvailabilityModel.fromJson(Map<String, dynamic> json) {
    final rawSlots = json['selectedSlotIds'] ?? json['selected_slot_ids'];
    List<String> slotIds = [];
    if (rawSlots is List) {
      slotIds = rawSlots.map((e) => e.toString()).toList();
    }

    final rawTags = json['slotTags'] ?? json['slot_tags'];
    Map<String, SlotTagInfo> tags = {};
    if (rawTags is Map) {
      rawTags.forEach((k, v) {
        if (v is Map) {
          tags[k.toString()] = SlotTagInfo.fromJson(Map<String, dynamic>.from(v));
        }
      });
    }

    return AvailabilityModel(
      id: json['id'] ?? '',
      dosenId: json['dosenId'] ?? json['dosen_id'] ?? '',
      semesterId: json['semesterId'] ?? json['semester_id'] ?? 'SEM001',
      selectedSlotIds: slotIds,
      slotTags: tags,
      status: json['status'] ?? 'submitted',
      submittedAt: json['submittedAt'] != null || json['submitted_at'] != null
          ? DateTime.tryParse(json['submittedAt'] ?? json['submitted_at'] ?? '')
          : null,
      updatedAt: json['updatedAt'] != null || json['updated_at'] != null
          ? DateTime.tryParse(json['updatedAt'] ?? json['updated_at'] ?? '')
          : null,
      catatan: json['catatan'],
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'dosenId': dosenId,
    'semesterId': semesterId,
    'selectedSlotIds': selectedSlotIds,
    'slotTags': slotTags.map((k, v) => MapEntry(k, v.toJson())),
    'status': status,
    'submittedAt': submittedAt?.toIso8601String(),
    'updatedAt': updatedAt?.toIso8601String(),
    'catatan': catatan,
  };
}

class AvailabilityHistoryItem {
  final String id;
  final DateTime submittedAt;
  final int slotCount;
  final String status; // 'approved', 'rejected', 'revision', 'submitted'
  final String? catatan;
  final String semesterNama;

  const AvailabilityHistoryItem({
    required this.id,
    required this.submittedAt,
    required this.slotCount,
    required this.status,
    this.catatan,
    required this.semesterNama,
  });
}
