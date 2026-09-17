// File: fakultas_form_dialog.dart
// Deskripsi: Modal bottom sheet form Tambah dan Edit Fakultas & Program Studi master data.

import 'package:flutter/material.dart';
import '../../../../../config/constants.dart';
import '../../../../../data/models/gedung_model.dart';
import '../master_data_pickers.dart';

// ── Dialog Tambah Fakultas & Prodi ──
void showAddFakultasDialog({
  required BuildContext context,
  required List<Map<String, dynamic>> fakultasData,
  required List<GedungModel> gedungList,
  required Function(Map<String, dynamic> newFakultas) onAdded,
}) {
  final namaFakCtrl = TextEditingController();
  final dekanCtrl = TextEditingController();
  final prodiCtrl = TextEditingController();
  String selectedGedung = gedungList.isNotEmpty ? gedungList.first.nama : 'Gedung Soekarno (A)';

  showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (ctx) => StatefulBuilder(
      builder: (context, setModalState) => Padding(
        padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
        child: Container(
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
          ),
          padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Center(
                  child: Container(
                    width: 40,
                    height: 4,
                    margin: const EdgeInsets.only(bottom: 16),
                    decoration: BoxDecoration(
                      color: const Color(0xFFCBD5E1),
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ),
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: AppColors.primary.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: const Icon(Icons.school_rounded, color: AppColors.primary, size: 20),
                    ),
                    const SizedBox(width: 10),
                    const Expanded(
                      child: Text(
                        'Tambah Fakultas & Prodi',
                        style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Color(0xFF0F172A)),
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.close_rounded, color: Color(0xFF64748B)),
                      onPressed: () => Navigator.pop(ctx),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: namaFakCtrl,
                  decoration: cleanMasterInputDecoration(
                    label: 'Nama Fakultas',
                    hint: 'Contoh: Fakultas Ilmu Komputer',
                    prefixIcon: const Icon(Icons.account_balance_outlined, size: 18, color: Color(0xFF64748B)),
                  ),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: dekanCtrl,
                  decoration: cleanMasterInputDecoration(
                    label: 'Nama Dekan',
                    hint: 'Contoh: Dr. Ir. Muhammad Yusuf, M.T.',
                    prefixIcon: const Icon(Icons.person_outline_rounded, size: 18, color: Color(0xFF64748B)),
                  ),
                ),
                const SizedBox(height: 12),
                buildSearchablePickerField(
                  label: 'Lokasi Gedung',
                  value: selectedGedung,
                  placeholder: 'Pilih gedung...',
                  icon: Icons.apartment_rounded,
                  onTap: () async {
                    final picked = await showSearchableGedungPicker(
                      context: context,
                      gedungList: gedungList,
                      currentSelected: selectedGedung,
                    );
                    if (picked != null) {
                      setModalState(() => selectedGedung = picked);
                    }
                  },
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: prodiCtrl,
                  decoration: cleanMasterInputDecoration(
                    label: 'Program Studi',
                    hint: 'Teknik Informatika, Sistem Informasi',
                    prefixIcon: const Icon(Icons.domain_verification_rounded, size: 18, color: Color(0xFF64748B)),
                  ),
                ),
                const SizedBox(height: 20),
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton(
                        style: OutlinedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          side: const BorderSide(color: Color(0xFFCBD5E1)),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                        ),
                        onPressed: () => Navigator.pop(ctx),
                        child: const Text('Batal', style: TextStyle(color: Color(0xFF475569), fontWeight: FontWeight.w600)),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      flex: 2,
                      child: ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.primary,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          elevation: 0,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                        ),
                        onPressed: () {
                          if (namaFakCtrl.text.trim().isNotEmpty) {
                            final prodiList = prodiCtrl.text
                                .split(',')
                                .map((p) => p.trim())
                                .where((p) => p.isNotEmpty)
                                .toList();

                            final newFak = {
                              'id': 'FAK00${fakultasData.length + 1}',
                              'nama': namaFakCtrl.text.trim(),
                              'gedung': selectedGedung,
                              'jurusan': prodiList.isNotEmpty ? prodiList : ['Teknik Informatika'],
                              'dekan': dekanCtrl.text.trim().isNotEmpty ? dekanCtrl.text.trim() : 'Belum Ditentukan',
                            };
                            onAdded(newFak);
                            Navigator.pop(ctx);
                          }
                        },
                        child: const Text('Simpan Fakultas', style: TextStyle(fontWeight: FontWeight.bold)),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    ),
  );
}

// ── Dialog Edit Fakultas ──
void showEditFakultasDialog({
  required BuildContext context,
  required Map<String, dynamic> fakultas,
  int? index,
  required List<GedungModel> gedungList,
  required Function(Map<String, dynamic> updatedFakultas) onSaved,
}) {
  final namaFakCtrl = TextEditingController(text: (fakultas['nama'] ?? '').toString());
  final dekanCtrl = TextEditingController(text: (fakultas['dekan'] ?? '').toString());
  final jurRaw = fakultas['jurusan'];
  final List<String> existingJurList = jurRaw is List
      ? jurRaw.map((e) => e.toString()).toList()
      : <String>[];
  final prodiCtrl = TextEditingController(
    text: existingJurList.join(', '),
  );
  String selectedGedung = (fakultas['gedung'] ?? (gedungList.isNotEmpty ? gedungList.first.nama : 'Gedung Soekarno (A)')).toString();

  showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (ctx) => StatefulBuilder(
      builder: (context, setModalState) => Padding(
        padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
        child: Container(
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
          ),
          padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Center(
                  child: Container(
                    width: 40,
                    height: 4,
                    margin: const EdgeInsets.only(bottom: 16),
                    decoration: BoxDecoration(
                      color: const Color(0xFFCBD5E1),
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ),
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: AppColors.primary.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: const Icon(Icons.edit_note_rounded, color: AppColors.primary, size: 20),
                    ),
                    const SizedBox(width: 10),
                    const Expanded(
                      child: Text(
                        'Edit Fakultas & Prodi',
                        style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Color(0xFF0F172A)),
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.close_rounded, color: Color(0xFF64748B)),
                      onPressed: () => Navigator.pop(ctx),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: namaFakCtrl,
                  decoration: cleanMasterInputDecoration(
                    label: 'Nama Fakultas',
                    hint: 'Contoh: Fakultas Sains & Teknologi',
                    prefixIcon: const Icon(Icons.account_balance_outlined, size: 18, color: Color(0xFF64748B)),
                  ),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: dekanCtrl,
                  decoration: cleanMasterInputDecoration(
                    label: 'Nama Dekan',
                    hint: 'Contoh: Dr. Ir. Budi Hartono, M.T.',
                    prefixIcon: const Icon(Icons.person_outline_rounded, size: 18, color: Color(0xFF64748B)),
                  ),
                ),
                const SizedBox(height: 12),
                buildSearchablePickerField(
                  label: 'Lokasi Gedung',
                  value: selectedGedung,
                  placeholder: 'Pilih gedung...',
                  icon: Icons.apartment_rounded,
                  onTap: () async {
                    final picked = await showSearchableGedungPicker(
                      context: context,
                      gedungList: gedungList,
                      currentSelected: selectedGedung,
                    );
                    if (picked != null) {
                      setModalState(() => selectedGedung = picked);
                    }
                  },
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: prodiCtrl,
                  decoration: cleanMasterInputDecoration(
                    label: 'Program Studi',
                    hint: 'Teknik Informatika, Sistem Informasi',
                    prefixIcon: const Icon(Icons.domain_verification_rounded, size: 18, color: Color(0xFF64748B)),
                  ),
                ),
                const SizedBox(height: 20),
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton(
                        style: OutlinedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          side: const BorderSide(color: Color(0xFFCBD5E1)),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                        ),
                        onPressed: () => Navigator.pop(ctx),
                        child: const Text('Batal', style: TextStyle(color: Color(0xFF475569), fontWeight: FontWeight.w600)),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      flex: 2,
                      child: ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.primary,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          elevation: 0,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                        ),
                        onPressed: () {
                          if (namaFakCtrl.text.trim().isNotEmpty) {
                            final prodiList = prodiCtrl.text
                                .split(',')
                                .map((p) => p.trim())
                                .where((p) => p.isNotEmpty)
                                .toList();

                            final updated = {
                              'id': (fakultas['id'] ?? 'FAK001').toString(),
                              'nama': namaFakCtrl.text.trim(),
                              'gedung': selectedGedung,
                              'jurusan': prodiList.isNotEmpty ? prodiList : existingJurList,
                              'dekan': dekanCtrl.text.trim().isNotEmpty ? dekanCtrl.text.trim() : (fakultas['dekan'] ?? 'Belum Ditentukan').toString(),
                            };
                            onSaved(updated);
                            Navigator.pop(ctx);
                          }
                        },
                        child: const Text('Simpan Perubahan', style: TextStyle(fontWeight: FontWeight.bold)),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    ),
  );
}
