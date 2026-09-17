// File: matakuliah_form_dialog.dart
// Deskripsi: Modal bottom sheet form Tambah dan Edit Mata Kuliah master data.

import 'package:flutter/material.dart';
import '../../../../../config/constants.dart';
import '../../../../../data/models/user_model.dart';
import '../master_data_pickers.dart';

// ── Dialog Tambah Matkul Baru ──
void showAddMatkulDialog({
  required BuildContext context,
  required List<Map<String, dynamic>> matkulData,
  required List<Map<String, dynamic>> fakultasData,
  required List<UserModel> dosenList,
  required Function(Map<String, dynamic> newMatkul) onAdded,
}) {
  final kodeCtrl = TextEditingController();
  final namaCtrl = TextEditingController();
  final sksCtrl = TextEditingController(text: '3');
  final kelasCtrl = TextEditingController(text: 'A, B');
  String selectedFakultas = 'Fakultas Sains & Teknologi';
  UserModel? selectedDosenObj;

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
                      child: const Icon(Icons.bookmark_add_rounded, color: AppColors.primary, size: 20),
                    ),
                    const SizedBox(width: 10),
                    const Expanded(
                      child: Text(
                        'Tambah Mata Kuliah Baru',
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
                Row(
                  children: [
                    Expanded(
                      flex: 2,
                      child: TextField(
                        controller: kodeCtrl,
                        decoration: cleanMasterInputDecoration(
                          label: 'Kode Matkul',
                          hint: 'IF101',
                          prefixIcon: const Icon(Icons.pin_rounded, size: 18, color: Color(0xFF64748B)),
                        ),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: TextField(
                        controller: sksCtrl,
                        keyboardType: TextInputType.number,
                        decoration: cleanMasterInputDecoration(
                          label: 'SKS',
                          hint: '3',
                          prefixIcon: const Icon(Icons.alarm_on_rounded, size: 18, color: Color(0xFF64748B)),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: namaCtrl,
                  decoration: cleanMasterInputDecoration(
                    label: 'Nama Mata Kuliah',
                    hint: 'Contoh: Algoritma & Pemrograman',
                    prefixIcon: const Icon(Icons.book_rounded, size: 18, color: Color(0xFF64748B)),
                  ),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: kelasCtrl,
                  decoration: cleanMasterInputDecoration(
                    label: 'Kelas Paralel',
                    hint: 'Contoh: A, B, C',
                    prefixIcon: const Icon(Icons.groups_rounded, size: 18, color: Color(0xFF64748B)),
                  ),
                ),
                const SizedBox(height: 12),
                buildSearchablePickerField(
                  label: 'Fakultas Pengampu',
                  value: selectedFakultas,
                  placeholder: 'Pilih fakultas...',
                  icon: Icons.school_rounded,
                  onTap: () async {
                    final picked = await showSearchableFakultasPicker(
                      context: context,
                      currentSelected: selectedFakultas,
                    );
                    if (picked != null) {
                      setModalState(() => selectedFakultas = picked);
                    }
                  },
                ),
                const SizedBox(height: 12),
                buildSearchablePickerField(
                  label: 'Dosen Pengampu',
                  value: selectedDosenObj != null ? selectedDosenObj!.nama : '',
                  hasValue: selectedDosenObj != null,
                  placeholder: 'Ketuk untuk mencari dosen...',
                  icon: Icons.person_search_rounded,
                  onTap: () async {
                    final picked = await showSearchableDosenPicker(
                      context: context,
                      dosenList: dosenList,
                      currentSelected: selectedDosenObj,
                    );
                    if (picked != null) {
                      setModalState(() => selectedDosenObj = picked);
                    }
                  },
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
                          if (namaCtrl.text.trim().isNotEmpty && kodeCtrl.text.trim().isNotEmpty) {
                            final kList = kelasCtrl.text
                                .split(',')
                                .map((k) => k.trim())
                                .where((k) => k.isNotEmpty)
                                .toList();

                            final newMatkul = {
                              'kode': kodeCtrl.text.trim().toUpperCase(),
                              'nama': namaCtrl.text.trim(),
                              'sks': int.tryParse(sksCtrl.text) ?? 3,
                              'jurusan': selectedDosenObj?.jurusanNama ?? 'Program Studi Terkait',
                              'fakultas': selectedFakultas,
                              'kelas': kList.isNotEmpty ? kList : ['A'],
                              'dosen': selectedDosenObj?.nama ?? 'Dosen Belum Ditentukan',
                              'dosenId': selectedDosenObj?.id ?? 'DSN000',
                            };
                            onAdded(newMatkul);
                            Navigator.pop(ctx);
                          }
                        },
                        child: const Text('Simpan Matkul', style: TextStyle(fontWeight: FontWeight.bold)),
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

// ── Dialog Edit Matkul ──
void showEditMatkulDialog({
  required BuildContext context,
  required Map<String, dynamic> matkul,
  int? index,
  required List<Map<String, dynamic>> fakultasData,
  required List<UserModel> dosenList,
  required Function(Map<String, dynamic> updatedMatkul) onSaved,
}) {
  final kodeCtrl = TextEditingController(text: (matkul['kode'] ?? '').toString());
  final namaCtrl = TextEditingController(text: (matkul['nama'] ?? '').toString());
  final sksCtrl = TextEditingController(text: '${matkul['sks'] ?? 3}');
  final kelasRaw = matkul['kelas'];
  final List<String> existingKelasList = kelasRaw is List
      ? kelasRaw.map((e) => e.toString()).toList()
      : <String>[];
  final kelasCtrl = TextEditingController(text: existingKelasList.join(', '));
  String selectedFakultas = (matkul['fakultas'] ?? 'Fakultas Sains & Teknologi').toString();
  UserModel? selectedDosenObj;

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
                        'Edit Mata Kuliah',
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
                Row(
                  children: [
                    Expanded(
                      flex: 2,
                      child: TextField(
                        controller: kodeCtrl,
                        decoration: cleanMasterInputDecoration(
                          label: 'Kode Matkul',
                          hint: 'IF101',
                          prefixIcon: const Icon(Icons.pin_rounded, size: 18, color: Color(0xFF64748B)),
                        ),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: TextField(
                        controller: sksCtrl,
                        keyboardType: TextInputType.number,
                        decoration: cleanMasterInputDecoration(
                          label: 'SKS',
                          hint: '3',
                          prefixIcon: const Icon(Icons.alarm_on_rounded, size: 18, color: Color(0xFF64748B)),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: namaCtrl,
                  decoration: cleanMasterInputDecoration(
                    label: 'Nama Mata Kuliah',
                    hint: 'Contoh: Algoritma & Pemrograman',
                    prefixIcon: const Icon(Icons.book_rounded, size: 18, color: Color(0xFF64748B)),
                  ),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: kelasCtrl,
                  decoration: cleanMasterInputDecoration(
                    label: 'Kelas Paralel',
                    hint: 'A, B',
                    prefixIcon: const Icon(Icons.groups_rounded, size: 18, color: Color(0xFF64748B)),
                  ),
                ),
                const SizedBox(height: 12),
                buildSearchablePickerField(
                  label: 'Fakultas Pengampu',
                  value: selectedFakultas,
                  placeholder: 'Pilih fakultas...',
                  icon: Icons.school_rounded,
                  onTap: () async {
                    final picked = await showSearchableFakultasPicker(
                      context: context,
                      currentSelected: selectedFakultas,
                    );
                    if (picked != null) {
                      setModalState(() => selectedFakultas = picked);
                    }
                  },
                ),
                const SizedBox(height: 12),
                buildSearchablePickerField(
                  label: 'Dosen Pengampu',
                  value: selectedDosenObj != null ? selectedDosenObj!.nama : (matkul['dosen'] ?? ''),
                  hasValue: selectedDosenObj != null || (matkul['dosen'] != null && (matkul['dosen'] as String).isNotEmpty),
                  placeholder: 'Ketuk untuk mencari dosen...',
                  icon: Icons.person_search_rounded,
                  onTap: () async {
                    final picked = await showSearchableDosenPicker(
                      context: context,
                      dosenList: dosenList,
                      currentSelected: selectedDosenObj,
                    );
                    if (picked != null) {
                      setModalState(() => selectedDosenObj = picked);
                    }
                  },
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
                          if (namaCtrl.text.trim().isNotEmpty && kodeCtrl.text.trim().isNotEmpty) {
                            final kList = kelasCtrl.text
                                .split(',')
                                .map((k) => k.trim())
                                .where((k) => k.isNotEmpty)
                                .toList();

                            final updated = {
                              'kode': kodeCtrl.text.trim().toUpperCase(),
                              'nama': namaCtrl.text.trim(),
                              'sks': int.tryParse(sksCtrl.text) ?? 3,
                              'jurusan': selectedDosenObj?.jurusanNama ?? matkul['jurusan'] ?? 'Program Studi Terkait',
                              'fakultas': selectedFakultas,
                              'kelas': kList.isNotEmpty ? kList : ['A'],
                              'dosen': selectedDosenObj?.nama ?? matkul['dosen'] ?? 'Dosen Belum Ditentukan',
                              'dosenId': selectedDosenObj?.id ?? matkul['dosenId'] ?? 'DSN000',
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
