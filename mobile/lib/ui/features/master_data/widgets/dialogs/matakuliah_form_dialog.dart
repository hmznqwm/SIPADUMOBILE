// File: matakuliah_form_dialog.dart
// Deskripsi: Modal bottom sheet form Tambah dan Edit Mata Kuliah master data.

import 'package:flutter/material.dart';
import '../../../../../config/constants.dart';
import '../../../../../data/models/user_model.dart';
import '../../../../../utils/academic_year_helper.dart';
import '../master_data_pickers.dart';
import 'quick_add_master_dialogs.dart';

// ── Dialog Tambah Matkul Baru ──
void showAddMatkulDialog({
  required BuildContext context,
  required List<Map<String, dynamic>> matkulData,
  required List<Map<String, dynamic>> fakultasData,
  required List<UserModel> dosenList,
  UserModel? currentUser,
  required Function(Map<String, dynamic> newMatkul) onAdded,
}) {
  final isKaProdi = currentUser?.role == 'kajur';
  final isDekan = currentUser?.role == 'dekan';

  final kodeCtrl = TextEditingController();
  final namaCtrl = TextEditingController();
  int selectedSks = 3;
  int selectedSemester = 3;
  String selectedJenis = 'Teori'; // 'Teori' (50 mnt/sks) or 'Praktikum' (90 mnt/sks)
  List<String> selectedKelasList = ['A', 'B'];
  String selectedFakultas = (currentUser?.fakultasNama != null && currentUser!.fakultasNama.isNotEmpty && currentUser.fakultasNama != 'Universitas')
      ? currentUser.fakultasNama
      : (fakultasData.isNotEmpty ? (fakultasData.first['nama']?.toString() ?? '') : '');
  UserModel? selectedDosenObj;

  // Filter dosen list based on scope
  final scopedDosenList = dosenList.where((d) {
    if (isKaProdi) {
      final userJur = currentUser?.jurusanNama.toLowerCase() ?? '';
      return d.jurusanNama.toLowerCase().contains(userJur) || userJur.contains(d.jurusanNama.toLowerCase());
    }
    if (isDekan) {
      final userFak = currentUser?.fakultasNama.toLowerCase() ?? '';
      return d.fakultasNama.toLowerCase().contains(userFak) || userFak.contains(d.fakultasNama.toLowerCase());
    }
    return true;
  }).toList();

  showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (ctx) => StatefulBuilder(
      builder: (context, setModalState) {
        final totalMenit = selectedSks * (selectedJenis == 'Praktikum' ? 90 : 50);

        return Padding(
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
                  // ── Header ──
                  Row(
                    children: [
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
                  TextField(
                    controller: kodeCtrl,
                    decoration: cleanMasterInputDecoration(
                      label: 'Kode Matkul',
                      hint: 'IF101',
                      prefixIcon: const Icon(Icons.pin_rounded, size: 18, color: Color(0xFF64748B)),
                    ),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: namaCtrl,
                    decoration: cleanMasterInputDecoration(
                      label: 'Nama Mata Kuliah',
                      hint: 'Contoh: Praktikum Algoritma & Pemrograman',
                      prefixIcon: const Icon(Icons.book_outlined, size: 18, color: Color(0xFF64748B)),
                    ),
                    onChanged: (val) {
                      // Auto-detect praktikum from title
                      if (AcademicYearHelper.isPraktikum(
                        matkulNama: val,
                        fakultasNama: selectedFakultas,
                      )) {
                        setModalState(() => selectedJenis = 'Praktikum');
                      }
                    },
                  ),
                  const SizedBox(height: 12),
                  // ── Jenis Perkuliahan (Teori 50 mnt vs Praktikum 90 mnt) ──
                  const Text(
                    'Jenis Perkuliahan & Durasi SKS',
                    style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: Color(0xFF475569)),
                  ),
                  const SizedBox(height: 6),
                  Row(
                    children: [
                      Expanded(
                        child: InkWell(
                          onTap: () => setModalState(() => selectedJenis = 'Teori'),
                          borderRadius: BorderRadius.circular(10),
                          child: Container(
                            padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 8),
                            decoration: BoxDecoration(
                              color: selectedJenis == 'Teori' ? AppColors.primary.withValues(alpha: 0.1) : const Color(0xFFF8FAFC),
                              borderRadius: BorderRadius.circular(10),
                              border: Border.all(
                                color: selectedJenis == 'Teori' ? AppColors.primary : const Color(0xFFE2E8F0),
                                width: selectedJenis == 'Teori' ? 1.5 : 1,
                              ),
                            ),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(
                                  Icons.menu_book_rounded,
                                  size: 16,
                                  color: selectedJenis == 'Teori' ? AppColors.primary : const Color(0xFF64748B),
                                ),
                                const SizedBox(width: 6),
                                Text(
                                  'Teori (50 mnt/SKS)',
                                  style: TextStyle(
                                    fontSize: 11.5,
                                    fontWeight: selectedJenis == 'Teori' ? FontWeight.bold : FontWeight.normal,
                                    color: selectedJenis == 'Teori' ? AppColors.primary : const Color(0xFF475569),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: InkWell(
                          onTap: () => setModalState(() => selectedJenis = 'Praktikum'),
                          borderRadius: BorderRadius.circular(10),
                          child: Container(
                            padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 8),
                            decoration: BoxDecoration(
                              color: selectedJenis == 'Praktikum' ? const Color(0xFF0F766E).withValues(alpha: 0.1) : const Color(0xFFF8FAFC),
                              borderRadius: BorderRadius.circular(10),
                              border: Border.all(
                                color: selectedJenis == 'Praktikum' ? const Color(0xFF0F766E) : const Color(0xFFE2E8F0),
                                width: selectedJenis == 'Praktikum' ? 1.5 : 1,
                              ),
                            ),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(
                                  Icons.biotech_rounded,
                                  size: 16,
                                  color: selectedJenis == 'Praktikum' ? const Color(0xFF0F766E) : const Color(0xFF64748B),
                                ),
                                const SizedBox(width: 6),
                                Text(
                                  'Praktikum (90 mnt/SKS)',
                                  style: TextStyle(
                                    fontSize: 11.5,
                                    fontWeight: selectedJenis == 'Praktikum' ? FontWeight.bold : FontWeight.normal,
                                    color: selectedJenis == 'Praktikum' ? const Color(0xFF0F766E) : const Color(0xFF475569),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(
                        child: DropdownButtonFormField<int>(
                          isExpanded: true,
                          isDense: true,
                          initialValue: selectedSks,
                          decoration: cleanMasterInputDecoration(
                            label: 'Bobot SKS',
                            hint: 'Pilih',
                          ).copyWith(
                            contentPadding: const EdgeInsets.symmetric(horizontal: 8, vertical: 10),
                          ),
                          icon: const SizedBox.shrink(),
                          dropdownColor: Colors.white,
                          borderRadius: BorderRadius.circular(12),
                          items: [1, 2, 3, 4, 5, 6].map((sks) {
                            return DropdownMenuItem<int>(
                              value: sks,
                              child: Text(
                                '$sks SKS',
                                style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: Color(0xFF0F172A)),
                                overflow: TextOverflow.ellipsis,
                              ),
                            );
                          }).toList(),
                          onChanged: (val) {
                            if (val != null) {
                              setModalState(() => selectedSks = val);
                            }
                          },
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: DropdownButtonFormField<int>(
                          isExpanded: true,
                          isDense: true,
                          initialValue: selectedSemester,
                          decoration: cleanMasterInputDecoration(
                            label: 'Semester',
                            hint: 'Pilih',
                          ).copyWith(
                            contentPadding: const EdgeInsets.symmetric(horizontal: 8, vertical: 10),
                          ),
                          icon: const SizedBox.shrink(),
                          dropdownColor: Colors.white,
                          borderRadius: BorderRadius.circular(12),
                          items: List.generate(8, (i) => i + 1).map((smt) {
                            return DropdownMenuItem<int>(
                              value: smt,
                              child: Text(
                                'Smt $smt',
                                style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: Color(0xFF0F172A)),
                                overflow: TextOverflow.ellipsis,
                              ),
                            );
                          }).toList(),
                          onChanged: (val) {
                            if (val != null) {
                              setModalState(() => selectedSemester = val);
                            }
                          },
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  // Live duration banner
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                    decoration: BoxDecoration(
                      color: selectedJenis == 'Praktikum' ? const Color(0xFFF0FDF4) : const Color(0xFFF1F5F9),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(
                        color: selectedJenis == 'Praktikum' ? const Color(0xFF86EFAC) : const Color(0xFFE2E8F0),
                      ),
                    ),
                    child: Row(
                      children: [
                        Icon(
                          selectedJenis == 'Praktikum' ? Icons.science_outlined : Icons.schedule_rounded,
                          size: 14,
                          color: selectedJenis == 'Praktikum' ? const Color(0xFF16A34A) : const Color(0xFF64748B),
                        ),
                        const SizedBox(width: 6),
                        Expanded(
                          child: Text(
                            'Durasi: $totalMenit Menit (${selectedJenis == 'Praktikum' ? "90 mnt/SKS khusus Lab / Saintek / Teknik" : "50 mnt/SKS Kuliah Teori"})',
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w600,
                              color: selectedJenis == 'Praktikum' ? const Color(0xFF15803D) : const Color(0xFF475569),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 12),
                  buildSearchablePickerField(
                    label: 'Kelas Paralel',
                    value: selectedKelasList.join(', '),
                    placeholder: 'Pilih kelas...',
                    icon: Icons.groups_rounded,
                    onTap: () async {
                      final picked = await showKelasParalelPicker(
                        context: context,
                        currentSelected: selectedKelasList,
                      );
                      if (picked != null && picked.isNotEmpty) {
                        setModalState(() => selectedKelasList = picked);
                      }
                    },
                  ),
                  if (!isKaProdi && !isDekan) ...[
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
                          setModalState(() {
                            selectedFakultas = picked;
                            if (AcademicYearHelper.isPraktikum(
                              matkulNama: namaCtrl.text,
                              fakultasNama: selectedFakultas,
                            )) {
                              selectedJenis = 'Praktikum';
                            }
                          });
                        }
                      },
                      onAdd: () {
                        showQuickAddFakultasDialog(
                          context: context,
                          onAdded: (newFak) {
                            setModalState(() {
                              if (!fakultasData.any((f) => f['nama'] == newFak['nama'])) {
                                fakultasData.add(newFak);
                              }
                              selectedFakultas = newFak['nama']?.toString() ?? '';
                            });
                          },
                        );
                      },
                    ),
                  ],
                  const SizedBox(height: 12),
                  buildSearchablePickerField(
                    label: 'Dosen Pengampu',
                    value: selectedDosenObj?.nama ?? '',
                    placeholder: 'Ketuk untuk mencari dosen...',
                    icon: Icons.person_search_rounded,
                    onTap: () async {
                      final picked = await showSearchableDosenPicker(
                        context: context,
                        dosenList: scopedDosenList,
                        currentSelected: selectedDosenObj,
                      );
                      if (picked != null) {
                        setModalState(() => selectedDosenObj = picked);
                      }
                    },
                    onAdd: () {
                      showQuickAddDosenDialog(
                        context: context,
                        defaultFakultas: selectedFakultas.isNotEmpty ? selectedFakultas : null,
                        onAdded: (newDosen) {
                          setModalState(() {
                            if (!dosenList.any((d) => d.id == newDosen.id)) {
                              dosenList.add(newDosen);
                            }
                            selectedDosenObj = newDosen;
                          });
                        },
                      );
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
                              final kList = selectedKelasList.isNotEmpty ? selectedKelasList : ['A'];
                              final smtVal = selectedSemester;

                              final resolvedJurusan = isKaProdi
                                  ? currentUser!.jurusanNama
                                  : (selectedDosenObj?.jurusanNama ?? (isDekan ? (currentUser?.jurusanNama ?? 'Program Studi Terkait') : 'Program Studi Terkait'));

                              final newMatkul = {
                                'id': kodeCtrl.text.trim().toUpperCase(),
                                'kode': kodeCtrl.text.trim().toUpperCase(),
                                'nama': namaCtrl.text.trim(),
                                'sks': selectedSks,
                                'jenis': selectedJenis,
                                'semester': smtVal > 0 ? smtVal : 1,
                                'semester_angka': smtVal > 0 ? smtVal : 1,
                                'semesterId': 'SEM00${smtVal % 2 != 0 ? 1 : 2}',
                                'jurusan': resolvedJurusan,
                                'fakultas': selectedFakultas,
                                'kelas': kList,
                                'dosen': selectedDosenObj?.nama ?? 'Dosen Belum Ditentukan',
                                'dosenId': selectedDosenObj?.id ?? 'DSN000',
                                'kebutuhanTipeRuangan': selectedJenis == 'Praktikum' ? 'Laboratorium' : 'Teori',
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
        );
      },
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
  UserModel? currentUser,
  required Function(Map<String, dynamic> updatedMatkul) onSaved,
}) {
  final isKaProdi = currentUser?.role == 'kajur';
  final isDekan = currentUser?.role == 'dekan';

  final kodeCtrl = TextEditingController(text: (matkul['kode'] ?? matkul['id'] ?? '').toString());
  final namaCtrl = TextEditingController(text: (matkul['nama'] ?? '').toString());
  int selectedSks = int.tryParse('${matkul['sks'] ?? 3}') ?? 3;
  if (selectedSks < 1 || selectedSks > 6) selectedSks = 3;
  int selectedSemester = int.tryParse('${matkul['semester'] ?? matkul['semester_angka'] ?? 1}') ?? 1;
  if (selectedSemester < 1 || selectedSemester > 8) selectedSemester = 1;

  final initialJenis = matkul['jenis']?.toString() ??
      (AcademicYearHelper.isPraktikum(
        matkulNama: matkul['nama']?.toString(),
        fakultasNama: matkul['fakultas']?.toString(),
        jurusanNama: matkul['jurusan']?.toString(),
      )
          ? 'Praktikum'
          : 'Teori');
  String selectedJenis = initialJenis;

  final kelasRaw = matkul['kelas'];
  final List<String> existingKelasList = kelasRaw is List
      ? kelasRaw.map((e) => e.toString()).toList()
      : <String>[];
  List<String> selectedKelasList = existingKelasList.isNotEmpty ? List<String>.from(existingKelasList) : ['A'];
  String selectedFakultas = (currentUser?.fakultasNama != null && currentUser!.fakultasNama.isNotEmpty && currentUser.fakultasNama != 'Universitas')
      ? currentUser.fakultasNama
      : (matkul['fakultas']?.toString() ?? (fakultasData.isNotEmpty ? fakultasData.first['nama']?.toString() ?? '' : ''));
  UserModel? selectedDosenObj;

  // Filter dosen list based on scope
  final scopedDosenList = dosenList.where((d) {
    if (isKaProdi) {
      final userJur = currentUser?.jurusanNama.toLowerCase() ?? '';
      return d.jurusanNama.toLowerCase().contains(userJur) || userJur.contains(d.jurusanNama.toLowerCase());
    }
    if (isDekan) {
      final userFak = currentUser?.fakultasNama.toLowerCase() ?? '';
      return d.fakultasNama.toLowerCase().contains(userFak) || userFak.contains(d.fakultasNama.toLowerCase());
    }
    return true;
  }).toList();

  showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (ctx) => StatefulBuilder(
      builder: (context, setModalState) {
        final totalMenit = selectedSks * (selectedJenis == 'Praktikum' ? 90 : 50);

        return Padding(
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
                  // ── Header ──
                  Row(
                    children: [
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
                  TextField(
                    controller: kodeCtrl,
                    decoration: cleanMasterInputDecoration(
                      label: 'Kode Matkul',
                      hint: 'IF101',
                      prefixIcon: const Icon(Icons.pin_rounded, size: 18, color: Color(0xFF64748B)),
                    ),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: namaCtrl,
                    decoration: cleanMasterInputDecoration(
                      label: 'Nama Mata Kuliah',
                      hint: 'Contoh: Praktikum Algoritma & Pemrograman',
                      prefixIcon: const Icon(Icons.book_outlined, size: 18, color: Color(0xFF64748B)),
                    ),
                  ),
                  const SizedBox(height: 12),
                  // ── Jenis Perkuliahan (Teori 50 mnt vs Praktikum 90 mnt) ──
                  const Text(
                    'Jenis Perkuliahan & Durasi SKS',
                    style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: Color(0xFF475569)),
                  ),
                  const SizedBox(height: 6),
                  Row(
                    children: [
                      Expanded(
                        child: InkWell(
                          onTap: () => setModalState(() => selectedJenis = 'Teori'),
                          borderRadius: BorderRadius.circular(10),
                          child: Container(
                            padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 8),
                            decoration: BoxDecoration(
                              color: selectedJenis == 'Teori' ? AppColors.primary.withValues(alpha: 0.1) : const Color(0xFFF8FAFC),
                              borderRadius: BorderRadius.circular(10),
                              border: Border.all(
                                color: selectedJenis == 'Teori' ? AppColors.primary : const Color(0xFFE2E8F0),
                                width: selectedJenis == 'Teori' ? 1.5 : 1,
                              ),
                            ),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(
                                  Icons.menu_book_rounded,
                                  size: 16,
                                  color: selectedJenis == 'Teori' ? AppColors.primary : const Color(0xFF64748B),
                                ),
                                const SizedBox(width: 6),
                                Text(
                                  'Teori (50 mnt/SKS)',
                                  style: TextStyle(
                                    fontSize: 11.5,
                                    fontWeight: selectedJenis == 'Teori' ? FontWeight.bold : FontWeight.normal,
                                    color: selectedJenis == 'Teori' ? AppColors.primary : const Color(0xFF475569),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: InkWell(
                          onTap: () => setModalState(() => selectedJenis = 'Praktikum'),
                          borderRadius: BorderRadius.circular(10),
                          child: Container(
                            padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 8),
                            decoration: BoxDecoration(
                              color: selectedJenis == 'Praktikum' ? const Color(0xFF0F766E).withValues(alpha: 0.1) : const Color(0xFFF8FAFC),
                              borderRadius: BorderRadius.circular(10),
                              border: Border.all(
                                color: selectedJenis == 'Praktikum' ? const Color(0xFF0F766E) : const Color(0xFFE2E8F0),
                                width: selectedJenis == 'Praktikum' ? 1.5 : 1,
                              ),
                            ),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(
                                  Icons.biotech_rounded,
                                  size: 16,
                                  color: selectedJenis == 'Praktikum' ? const Color(0xFF0F766E) : const Color(0xFF64748B),
                                ),
                                const SizedBox(width: 6),
                                Text(
                                  'Praktikum (90 mnt/SKS)',
                                  style: TextStyle(
                                    fontSize: 11.5,
                                    fontWeight: selectedJenis == 'Praktikum' ? FontWeight.bold : FontWeight.normal,
                                    color: selectedJenis == 'Praktikum' ? const Color(0xFF0F766E) : const Color(0xFF475569),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(
                        child: DropdownButtonFormField<int>(
                          isExpanded: true,
                          isDense: true,
                          initialValue: selectedSks,
                          decoration: cleanMasterInputDecoration(
                            label: 'Bobot SKS',
                            hint: 'Pilih',
                          ).copyWith(
                            contentPadding: const EdgeInsets.symmetric(horizontal: 8, vertical: 10),
                          ),
                          icon: const SizedBox.shrink(),
                          dropdownColor: Colors.white,
                          borderRadius: BorderRadius.circular(12),
                          items: [1, 2, 3, 4, 5, 6].map((sks) {
                            return DropdownMenuItem<int>(
                              value: sks,
                              child: Text(
                                '$sks SKS',
                                style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: Color(0xFF0F172A)),
                                overflow: TextOverflow.ellipsis,
                              ),
                            );
                          }).toList(),
                          onChanged: (val) {
                            if (val != null) {
                              setModalState(() => selectedSks = val);
                            }
                          },
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: DropdownButtonFormField<int>(
                          isExpanded: true,
                          isDense: true,
                          initialValue: selectedSemester,
                          decoration: cleanMasterInputDecoration(
                            label: 'Semester',
                            hint: 'Pilih',
                          ).copyWith(
                            contentPadding: const EdgeInsets.symmetric(horizontal: 8, vertical: 10),
                          ),
                          icon: const SizedBox.shrink(),
                          dropdownColor: Colors.white,
                          borderRadius: BorderRadius.circular(12),
                          items: List.generate(8, (i) => i + 1).map((smt) {
                            return DropdownMenuItem<int>(
                              value: smt,
                              child: Text(
                                'Smt $smt',
                                style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: Color(0xFF0F172A)),
                                overflow: TextOverflow.ellipsis,
                              ),
                            );
                          }).toList(),
                          onChanged: (val) {
                            if (val != null) {
                              setModalState(() => selectedSemester = val);
                            }
                          },
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  // Live duration banner
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                    decoration: BoxDecoration(
                      color: selectedJenis == 'Praktikum' ? const Color(0xFFF0FDF4) : const Color(0xFFF1F5F9),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(
                        color: selectedJenis == 'Praktikum' ? const Color(0xFF86EFAC) : const Color(0xFFE2E8F0),
                      ),
                    ),
                    child: Row(
                      children: [
                        Icon(
                          selectedJenis == 'Praktikum' ? Icons.science_outlined : Icons.schedule_rounded,
                          size: 14,
                          color: selectedJenis == 'Praktikum' ? const Color(0xFF16A34A) : const Color(0xFF64748B),
                        ),
                        const SizedBox(width: 6),
                        Expanded(
                          child: Text(
                            'Durasi: $totalMenit Menit (${selectedJenis == 'Praktikum' ? "90 mnt/SKS khusus Lab / Saintek / Teknik" : "50 mnt/SKS Kuliah Teori"})',
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w600,
                              color: selectedJenis == 'Praktikum' ? const Color(0xFF15803D) : const Color(0xFF475569),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 12),
                  buildSearchablePickerField(
                    label: 'Kelas Paralel',
                    value: selectedKelasList.join(', '),
                    placeholder: 'Pilih kelas...',
                    icon: Icons.groups_rounded,
                    onTap: () async {
                      final picked = await showKelasParalelPicker(
                        context: context,
                        currentSelected: selectedKelasList,
                      );
                      if (picked != null && picked.isNotEmpty) {
                        setModalState(() => selectedKelasList = picked);
                      }
                    },
                  ),
                  if (!isKaProdi && !isDekan) ...[
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
                      onAdd: () {
                        showQuickAddFakultasDialog(
                          context: context,
                          onAdded: (newFak) {
                            setModalState(() {
                              if (!fakultasData.any((f) => f['nama'] == newFak['nama'])) {
                                fakultasData.add(newFak);
                              }
                              selectedFakultas = newFak['nama']?.toString() ?? '';
                            });
                          },
                        );
                      },
                    ),
                  ],
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
                        dosenList: scopedDosenList,
                        currentSelected: selectedDosenObj,
                      );
                      if (picked != null) {
                        setModalState(() => selectedDosenObj = picked);
                      }
                    },
                    onAdd: () {
                      showQuickAddDosenDialog(
                        context: context,
                        defaultFakultas: selectedFakultas.isNotEmpty ? selectedFakultas : null,
                        onAdded: (newDosen) {
                          setModalState(() {
                            if (!dosenList.any((d) => d.id == newDosen.id)) {
                              dosenList.add(newDosen);
                            }
                            selectedDosenObj = newDosen;
                          });
                        },
                      );
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
                              final kList = selectedKelasList.isNotEmpty ? selectedKelasList : ['A'];
                              final smtVal = selectedSemester;

                              final resolvedJurusan = isKaProdi
                                  ? currentUser!.jurusanNama
                                  : (selectedDosenObj?.jurusanNama ?? matkul['jurusan'] ?? (isDekan ? (currentUser?.jurusanNama ?? 'Program Studi Terkait') : 'Program Studi Terkait'));

                              final updated = {
                                'id': kodeCtrl.text.trim().toUpperCase(),
                                'kode': kodeCtrl.text.trim().toUpperCase(),
                                'nama': namaCtrl.text.trim(),
                                'sks': selectedSks,
                                'jenis': selectedJenis,
                                'semester': smtVal > 0 ? smtVal : 1,
                                'semester_angka': smtVal > 0 ? smtVal : 1,
                                'semesterId': 'SEM00${smtVal % 2 != 0 ? 1 : 2}',
                                'jurusan': resolvedJurusan,
                                'fakultas': selectedFakultas,
                                'kelas': kList,
                                'dosen': selectedDosenObj?.nama ?? matkul['dosen'] ?? 'Dosen Belum Ditentukan',
                                'dosenId': selectedDosenObj?.id ?? matkul['dosenId'] ?? 'DSN000',
                                'kebutuhanTipeRuangan': selectedJenis == 'Praktikum' ? 'Laboratorium' : 'Teori',
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
        );
      },
    ),
  );
}
