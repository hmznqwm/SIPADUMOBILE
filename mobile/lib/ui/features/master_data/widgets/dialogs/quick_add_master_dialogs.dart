// File: quick_add_master_dialogs.dart
// Deskripsi: Modal dialog popup cepat (Quick Add) untuk Gedung, Fakultas, Prodi, Dosen, dan Mata Kuliah langsung dari dalam form picker.

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../../../config/constants.dart';
import '../../../../../data/mock/mock_database.dart';
import '../../../../../data/models/gedung_model.dart';
import '../../../../../data/models/user_model.dart';
import '../../../../../data/services/api_service.dart';
import '../pickers/picker_field_decoration.dart';

// ── Quick Add Gedung Dialog ──
void showQuickAddGedungDialog({
  required BuildContext context,
  required Function(GedungModel newGedung) onAdded,
}) {
  final namaCtrl = TextEditingController();
  final formKey = GlobalKey<FormState>();

  showDialog(
    context: context,
    builder: (dCtx) => AlertDialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      titlePadding: const EdgeInsets.fromLTRB(20, 18, 20, 10),
      contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
      actionsPadding: const EdgeInsets.fromLTRB(20, 10, 20, 16),
      title: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(6),
            decoration: BoxDecoration(
              color: AppColors.primary.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: const Icon(Icons.apartment_rounded, color: AppColors.primary, size: 18),
          ),
          const SizedBox(width: 8),
          const Expanded(
            child: Text(
              'Tambah Gedung Baru',
              style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: Color(0xFF0F172A)),
            ),
          ),
        ],
      ),
      content: Form(
        key: formKey,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextFormField(
              controller: namaCtrl,
              autofocus: true,
              style: const TextStyle(fontSize: 13),
              decoration: cleanMasterInputDecoration(
                label: 'Nama Gedung',
                hint: 'Contoh: Gedung Soekarno (A)',
                prefixIcon: const Icon(Icons.business_rounded, size: 18, color: Color(0xFF64748B)),
              ),
              validator: (v) => (v == null || v.trim().isEmpty) ? 'Nama gedung wajib diisi' : null,
            ),
          ],
        ),
      ),
      actions: [
        OutlinedButton(
          style: OutlinedButton.styleFrom(
            side: const BorderSide(color: Color(0xFFCBD5E1)),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
          ),
          onPressed: () => Navigator.pop(dCtx),
          child: const Text('Batal', style: TextStyle(color: Color(0xFF64748B), fontSize: 12)),
        ),
        ElevatedButton(
          style: ElevatedButton.styleFrom(
            backgroundColor: AppColors.primary,
            foregroundColor: Colors.white,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
          ),
          onPressed: () async {
            if (formKey.currentState?.validate() ?? false) {
              final cleanNama = namaCtrl.text.trim();
              final nextNum = MockDatabase.gedungList.length + 1;
              final newGedung = GedungModel(
                id: 'GDG00$nextNum',
                nama: cleanNama,
                jamBuka: '07:30',
                jamTutup: '17:00',
                aksesJurusan: 'Semua Fakultas',
              );

              final api = context.read<ApiService>();
              try {
                await api.addGedung(newGedung);
              } catch (_) {}

              if (!MockDatabase.gedungList.any((g) => g.id == newGedung.id)) {
                MockDatabase.gedungList.add(newGedung);
              }

              onAdded(newGedung);
              if (dCtx.mounted) {
                Navigator.pop(dCtx);
              }
            }
          },
          child: const Text('Simpan', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12)),
        ),
      ],
    ),
  );
}

// ── Quick Add Fakultas Dialog ──
void showQuickAddFakultasDialog({
  required BuildContext context,
  required Function(Map<String, dynamic> newFakultas) onAdded,
}) {
  final namaCtrl = TextEditingController();
  final prodiCtrl = TextEditingController();
  final formKey = GlobalKey<FormState>();

  showDialog(
    context: context,
    builder: (dCtx) => AlertDialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      titlePadding: const EdgeInsets.fromLTRB(20, 18, 20, 10),
      contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
      actionsPadding: const EdgeInsets.fromLTRB(20, 10, 20, 16),
      title: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(6),
            decoration: BoxDecoration(
              color: AppColors.primary.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: const Icon(Icons.school_rounded, color: AppColors.primary, size: 18),
          ),
          const SizedBox(width: 8),
          const Expanded(
            child: Text(
              'Tambah Fakultas Baru',
              style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: Color(0xFF0F172A)),
            ),
          ),
        ],
      ),
      content: Form(
        key: formKey,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextFormField(
              controller: namaCtrl,
              autofocus: true,
              style: const TextStyle(fontSize: 13),
              decoration: cleanMasterInputDecoration(
                label: 'Nama Fakultas',
                hint: 'Contoh: Fakultas Ilmu Komputer',
                prefixIcon: const Icon(Icons.account_balance_outlined, size: 18, color: Color(0xFF64748B)),
              ),
              validator: (v) => (v == null || v.trim().isEmpty) ? 'Nama fakultas wajib diisi' : null,
            ),
            const SizedBox(height: 10),
            TextFormField(
              controller: prodiCtrl,
              style: const TextStyle(fontSize: 13),
              decoration: cleanMasterInputDecoration(
                label: 'Program Studi Awal (Opsional)',
                hint: 'Teknik Informatika, Sistem Informasi',
                prefixIcon: const Icon(Icons.domain_verification_rounded, size: 18, color: Color(0xFF64748B)),
              ),
            ),
          ],
        ),
      ),
      actions: [
        OutlinedButton(
          style: OutlinedButton.styleFrom(
            side: const BorderSide(color: Color(0xFFCBD5E1)),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
          ),
          onPressed: () => Navigator.pop(dCtx),
          child: const Text('Batal', style: TextStyle(color: Color(0xFF64748B), fontSize: 12)),
        ),
        ElevatedButton(
          style: ElevatedButton.styleFrom(
            backgroundColor: AppColors.primary,
            foregroundColor: Colors.white,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
          ),
          onPressed: () async {
            if (formKey.currentState?.validate() ?? false) {
              final cleanNama = namaCtrl.text.trim();
              final prodiList = prodiCtrl.text
                  .split(',')
                  .map((p) => p.trim())
                  .where((p) => p.isNotEmpty)
                  .toList();

              final nextNum = MockDatabase.fakultasData.length + 1;
              final newFak = {
                'id': 'FAK00$nextNum',
                'nama': cleanNama,
                'gedung': 'Semua Gedung',
                'jurusan': prodiList.isNotEmpty ? prodiList : <String>['Umum'],
                'dekan': 'Belum Ditentukan',
              };

              final api = context.read<ApiService>();
              try {
                await api.saveFakultas(newFak);
              } catch (_) {}

              MockDatabase.deletedFakultasIds.remove(newFak['id']);
              MockDatabase.fakultasData.removeWhere(
                (item) => ((item['id'] ?? item['nama'])?.toString() ?? '') == newFak['id'],
              );
              MockDatabase.fakultasData.add(newFak);

              onAdded(newFak);
              if (dCtx.mounted) {
                Navigator.pop(dCtx);
              }
            }
          },
          child: const Text('Simpan', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12)),
        ),
      ],
    ),
  );
}

// ── Quick Add Program Studi Dialog ──
void showQuickAddProdiDialog({
  required BuildContext context,
  required String currentFakultas,
  required Function(String newProdi) onAdded,
}) {
  final prodiCtrl = TextEditingController();
  final formKey = GlobalKey<FormState>();

  showDialog(
    context: context,
    builder: (dCtx) => AlertDialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      titlePadding: const EdgeInsets.fromLTRB(20, 18, 20, 10),
      contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
      actionsPadding: const EdgeInsets.fromLTRB(20, 10, 20, 16),
      title: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(6),
            decoration: BoxDecoration(
              color: AppColors.primary.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: const Icon(Icons.domain_verification_rounded, color: AppColors.primary, size: 18),
          ),
          const SizedBox(width: 8),
          const Expanded(
            child: Text(
              'Tambah Program Studi',
              style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: Color(0xFF0F172A)),
            ),
          ),
        ],
      ),
      content: Form(
        key: formKey,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (currentFakultas.isNotEmpty)
              Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: Text(
                  'Fakultas: $currentFakultas',
                  style: const TextStyle(fontSize: 11.5, color: Color(0xFF64748B), fontWeight: FontWeight.w600),
                ),
              ),
            TextFormField(
              controller: prodiCtrl,
              autofocus: true,
              style: const TextStyle(fontSize: 13),
              decoration: cleanMasterInputDecoration(
                label: 'Nama Program Studi',
                hint: 'Contoh: Teknik Informatika',
                prefixIcon: const Icon(Icons.school_outlined, size: 18, color: Color(0xFF64748B)),
              ),
              validator: (v) => (v == null || v.trim().isEmpty) ? 'Nama prodi wajib diisi' : null,
            ),
          ],
        ),
      ),
      actions: [
        OutlinedButton(
          style: OutlinedButton.styleFrom(
            side: const BorderSide(color: Color(0xFFCBD5E1)),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
          ),
          onPressed: () => Navigator.pop(dCtx),
          child: const Text('Batal', style: TextStyle(color: Color(0xFF64748B), fontSize: 12)),
        ),
        ElevatedButton(
          style: ElevatedButton.styleFrom(
            backgroundColor: AppColors.primary,
            foregroundColor: Colors.white,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
          ),
          onPressed: () async {
            if (formKey.currentState?.validate() ?? false) {
              final newProdi = prodiCtrl.text.trim();

              // Update existing fakultas in MockDatabase if matched
              if (currentFakultas.isNotEmpty) {
                for (var f in MockDatabase.fakultasData) {
                  if (f['nama']?.toString().toLowerCase() == currentFakultas.toLowerCase()) {
                    final jurList = (f['jurusan'] as List?)?.map((e) => e.toString()).toList() ?? [];
                    if (!jurList.contains(newProdi)) {
                      jurList.add(newProdi);
                      f['jurusan'] = jurList;
                    }
                  }
                }
              }

              onAdded(newProdi);
              if (dCtx.mounted) {
                Navigator.pop(dCtx);
              }
            }
          },
          child: const Text('Simpan', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12)),
        ),
      ],
    ),
  );
}

// ── Quick Add Dosen Dialog ──
void showQuickAddDosenDialog({
  required BuildContext context,
  String? defaultFakultas,
  String? defaultProdi,
  required Function(UserModel newDosen) onAdded,
}) {
  final nidnCtrl = TextEditingController();
  final namaCtrl = TextEditingController();
  final emailCtrl = TextEditingController();
  final formKey = GlobalKey<FormState>();

  showDialog(
    context: context,
    builder: (dCtx) => AlertDialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      titlePadding: const EdgeInsets.fromLTRB(20, 18, 20, 10),
      contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
      actionsPadding: const EdgeInsets.fromLTRB(20, 10, 20, 16),
      title: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(6),
            decoration: BoxDecoration(
              color: AppColors.primary.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: const Icon(Icons.person_add_rounded, color: AppColors.primary, size: 18),
          ),
          const SizedBox(width: 8),
          const Expanded(
            child: Text(
              'Tambah Dosen Baru',
              style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: Color(0xFF0F172A)),
            ),
          ),
        ],
      ),
      content: Form(
        key: formKey,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextFormField(
                controller: namaCtrl,
                autofocus: true,
                style: const TextStyle(fontSize: 13),
                decoration: cleanMasterInputDecoration(
                  label: 'Nama Lengkap Dosen',
                  hint: 'Dr. Ir. Ahmad Maulana, M.Kom.',
                  prefixIcon: const Icon(Icons.person_outline_rounded, size: 18, color: Color(0xFF64748B)),
                ),
                validator: (v) => (v == null || v.trim().isEmpty) ? 'Nama dosen wajib diisi' : null,
              ),
              const SizedBox(height: 10),
              TextFormField(
                controller: nidnCtrl,
                style: const TextStyle(fontSize: 13),
                decoration: cleanMasterInputDecoration(
                  label: 'NIDN / NIP (Opsional)',
                  hint: 'Contoh: 0412098801',
                  prefixIcon: const Icon(Icons.badge_outlined, size: 18, color: Color(0xFF64748B)),
                ),
              ),
              const SizedBox(height: 10),
              TextFormField(
                controller: emailCtrl,
                keyboardType: TextInputType.emailAddress,
                style: const TextStyle(fontSize: 13),
                decoration: cleanMasterInputDecoration(
                  label: 'Email (Opsional)',
                  hint: 'dosen@kampus.ac.id',
                  prefixIcon: const Icon(Icons.email_outlined, size: 18, color: Color(0xFF64748B)),
                ),
              ),
            ],
          ),
        ),
      ),
      actions: [
        OutlinedButton(
          style: OutlinedButton.styleFrom(
            side: const BorderSide(color: Color(0xFFCBD5E1)),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
          ),
          onPressed: () => Navigator.pop(dCtx),
          child: const Text('Batal', style: TextStyle(color: Color(0xFF64748B), fontSize: 12)),
        ),
        ElevatedButton(
          style: ElevatedButton.styleFrom(
            backgroundColor: AppColors.primary,
            foregroundColor: Colors.white,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
          ),
          onPressed: () async {
            if (formKey.currentState?.validate() ?? false) {
              final cleanNama = namaCtrl.text.trim();
              final rawNidn = nidnCtrl.text.trim();
              final newId = rawNidn.isNotEmpty
                  ? rawNidn
                  : 'DSN00${MockDatabase.demoUsers.length + 1}';
              var cleanEmail = emailCtrl.text.trim();
              if (cleanEmail.isEmpty) {
                cleanEmail = '${cleanNama.toLowerCase().replaceAll(RegExp(r'[^a-z]'), '')}@kampus.ac.id';
              }

              final newDosen = UserModel(
                id: newId,
                nama: cleanNama,
                email: cleanEmail,
                role: 'dosen',
                jurusanId: 'JUR001',
                fakultasNama: defaultFakultas ?? 'Fakultas Ilmu Komputer',
                jurusanNama: defaultProdi ?? 'Teknik Informatika',
              );

              final api = context.read<ApiService>();
              try {
                await api.createDosen(newDosen);
              } catch (_) {}

              MockDatabase.deletedUserIds.remove(newDosen.id);
              MockDatabase.demoUsers.removeWhere((u) => u.id == newDosen.id);
              MockDatabase.demoUsers.add(newDosen);

              onAdded(newDosen);
              if (dCtx.mounted) {
                Navigator.pop(dCtx);
              }
            }
          },
          child: const Text('Simpan', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12)),
        ),
      ],
    ),
  );
}

// ── Quick Add Mata Kuliah Dialog ──
void showQuickAddMatkulDialog({
  required BuildContext context,
  String? defaultFakultas,
  String? defaultProdi,
  required Function(Map<String, dynamic> newMatkul) onAdded,
}) {
  final kodeCtrl = TextEditingController();
  final namaCtrl = TextEditingController();
  int selectedSks = 3;
  int selectedSemester = 3;
  String selectedJenis = 'Teori';
  final formKey = GlobalKey<FormState>();

  showDialog(
    context: context,
    builder: (dCtx) => StatefulBuilder(
      builder: (context, setDState) {
        final totalMenit = selectedSks * (selectedJenis == 'Praktikum' ? 90 : 50);

        return AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          titlePadding: const EdgeInsets.fromLTRB(20, 18, 20, 10),
          contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
          actionsPadding: const EdgeInsets.fromLTRB(20, 10, 20, 16),
          title: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  color: AppColors.primary.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(Icons.book_outlined, color: AppColors.primary, size: 18),
              ),
              const SizedBox(width: 8),
              const Expanded(
                child: Text(
                  'Tambah Mata Kuliah Baru',
                  style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: Color(0xFF0F172A)),
                ),
              ),
            ],
          ),
          content: Form(
            key: formKey,
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextFormField(
                    controller: kodeCtrl,
                    autofocus: true,
                    style: const TextStyle(fontSize: 13),
                    decoration: cleanMasterInputDecoration(
                      label: 'Kode Matkul',
                      hint: 'Contoh: IF101',
                      prefixIcon: const Icon(Icons.pin_rounded, size: 18, color: Color(0xFF64748B)),
                    ),
                    validator: (v) => (v == null || v.trim().isEmpty) ? 'Kode matkul wajib diisi' : null,
                  ),
                  const SizedBox(height: 10),
                  TextFormField(
                    controller: namaCtrl,
                    style: const TextStyle(fontSize: 13),
                    decoration: cleanMasterInputDecoration(
                      label: 'Nama Mata Kuliah',
                      hint: 'Contoh: Praktikum Algoritma & Pemrograman',
                      prefixIcon: const Icon(Icons.menu_book_rounded, size: 18, color: Color(0xFF64748B)),
                    ),
                    validator: (v) => (v == null || v.trim().isEmpty) ? 'Nama matkul wajib diisi' : null,
                    onChanged: (val) {
                      if (val.toLowerCase().contains('prak') ||
                          val.toLowerCase().contains('lab') ||
                          (defaultFakultas != null &&
                              (defaultFakultas.toLowerCase().contains('sains') ||
                                  defaultFakultas.toLowerCase().contains('teknik')))) {
                        setDState(() => selectedJenis = 'Praktikum');
                      }
                    },
                  ),
                  const SizedBox(height: 10),
                  // Jenis Perkuliahan Toggle
                  Row(
                    children: [
                      Expanded(
                        child: InkWell(
                          onTap: () => setDState(() => selectedJenis = 'Teori'),
                          borderRadius: BorderRadius.circular(8),
                          child: Container(
                            padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 6),
                            decoration: BoxDecoration(
                              color: selectedJenis == 'Teori' ? AppColors.primary.withValues(alpha: 0.1) : const Color(0xFFF8FAFC),
                              borderRadius: BorderRadius.circular(8),
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
                                  size: 14,
                                  color: selectedJenis == 'Teori' ? AppColors.primary : const Color(0xFF64748B),
                                ),
                                const SizedBox(width: 4),
                                Text(
                                  'Teori (50m)',
                                  style: TextStyle(
                                    fontSize: 11,
                                    fontWeight: selectedJenis == 'Teori' ? FontWeight.bold : FontWeight.normal,
                                    color: selectedJenis == 'Teori' ? AppColors.primary : const Color(0xFF475569),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: InkWell(
                          onTap: () => setDState(() => selectedJenis = 'Praktikum'),
                          borderRadius: BorderRadius.circular(8),
                          child: Container(
                            padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 6),
                            decoration: BoxDecoration(
                              color: selectedJenis == 'Praktikum' ? const Color(0xFF0F766E).withValues(alpha: 0.1) : const Color(0xFFF8FAFC),
                              borderRadius: BorderRadius.circular(8),
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
                                  size: 14,
                                  color: selectedJenis == 'Praktikum' ? const Color(0xFF0F766E) : const Color(0xFF64748B),
                                ),
                                const SizedBox(width: 4),
                                Text(
                                  'Praktikum (90m)',
                                  style: TextStyle(
                                    fontSize: 11,
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
                  const SizedBox(height: 10),
                  Row(
                    children: [
                      Expanded(
                        child: DropdownButtonFormField<int>(
                          isExpanded: true,
                          isDense: true,
                          initialValue: selectedSks,
                          decoration: cleanMasterInputDecoration(label: 'SKS').copyWith(
                            contentPadding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
                          ),
                          items: [1, 2, 3, 4, 5, 6].map((sks) {
                            return DropdownMenuItem<int>(
                              value: sks,
                              child: Text('$sks SKS', style: const TextStyle(fontSize: 12)),
                            );
                          }).toList(),
                          onChanged: (val) {
                            if (val != null) setDState(() => selectedSks = val);
                          },
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: DropdownButtonFormField<int>(
                          isExpanded: true,
                          isDense: true,
                          initialValue: selectedSemester,
                          decoration: cleanMasterInputDecoration(label: 'Semester').copyWith(
                            contentPadding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
                          ),
                          items: List.generate(8, (i) => i + 1).map((smt) {
                            return DropdownMenuItem<int>(
                              value: smt,
                              child: Text('Smt $smt', style: const TextStyle(fontSize: 12)),
                            );
                          }).toList(),
                          onChanged: (val) {
                            if (val != null) setDState(() => selectedSemester = val);
                          },
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
                    decoration: BoxDecoration(
                      color: selectedJenis == 'Praktikum' ? const Color(0xFFF0FDF4) : const Color(0xFFF1F5F9),
                      borderRadius: BorderRadius.circular(6),
                      border: Border.all(
                        color: selectedJenis == 'Praktikum' ? const Color(0xFF86EFAC) : const Color(0xFFE2E8F0),
                      ),
                    ),
                    child: Row(
                      children: [
                        Icon(
                          selectedJenis == 'Praktikum' ? Icons.science_outlined : Icons.schedule_rounded,
                          size: 13,
                          color: selectedJenis == 'Praktikum' ? const Color(0xFF16A34A) : const Color(0xFF64748B),
                        ),
                        const SizedBox(width: 5),
                        Expanded(
                          child: Text(
                            'Total: $totalMenit Menit (${selectedJenis == 'Praktikum' ? "90m/SKS" : "50m/SKS"})',
                            style: TextStyle(
                              fontSize: 10.5,
                              fontWeight: FontWeight.w600,
                              color: selectedJenis == 'Praktikum' ? const Color(0xFF15803D) : const Color(0xFF475569),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
          actions: [
            OutlinedButton(
              style: OutlinedButton.styleFrom(
                side: const BorderSide(color: Color(0xFFCBD5E1)),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
              ),
              onPressed: () => Navigator.pop(dCtx),
              child: const Text('Batal', style: TextStyle(color: Color(0xFF64748B), fontSize: 12)),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
              ),
              onPressed: () async {
                if (formKey.currentState?.validate() ?? false) {
                  final cleanKode = kodeCtrl.text.trim().toUpperCase();
                  final cleanNama = namaCtrl.text.trim();

                  final newMatkul = {
                    'id': cleanKode,
                    'kode': cleanKode,
                    'nama': cleanNama,
                    'sks': selectedSks,
                    'jenis': selectedJenis,
                    'semester': selectedSemester,
                    'semester_angka': selectedSemester,
                    'fakultas': defaultFakultas ?? 'Fakultas Ilmu Komputer',
                    'jurusan': defaultProdi ?? 'Teknik Informatika',
                    'kelas': 'A',
                    'dosen': 'Belum Ditentukan',
                    'kebutuhanTipeRuangan': selectedJenis == 'Praktikum' ? 'Laboratorium' : 'Teori',
                  };

                  final api = context.read<ApiService>();
                  try {
                    await api.saveMataKuliah(newMatkul);
                  } catch (_) {}

                  MockDatabase.deletedMatkulIds.remove(cleanKode);
                  MockDatabase.matkulData.removeWhere((item) => (item['kode']?.toString() ?? '') == cleanKode);
                  MockDatabase.matkulData.add(newMatkul);

                  onAdded(newMatkul);
                  if (dCtx.mounted) {
                    Navigator.pop(dCtx);
                  }
                }
              },
              child: const Text('Simpan', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12)),
            ),
          ],
        );
      },
    ),
  );
}
