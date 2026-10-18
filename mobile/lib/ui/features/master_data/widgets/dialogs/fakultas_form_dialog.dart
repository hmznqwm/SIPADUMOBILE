// File: fakultas_form_dialog.dart
// Deskripsi: Modal bottom sheet form Tambah dan Edit Fakultas & Program Studi master data dengan 3-char autocomplete dosen.

import 'package:flutter/material.dart';
import '../../../../../config/constants.dart';
import '../../../../../data/models/gedung_model.dart';
import '../../../../../data/models/user_model.dart';
import '../master_data_pickers.dart';
import 'quick_add_master_dialogs.dart';

// ── Dialog Tambah Fakultas & Prodi ──
void showAddFakultasDialog({
  required BuildContext context,
  required List<Map<String, dynamic>> fakultasData,
  required List<GedungModel> gedungList,
  List<UserModel> dosenList = const [],
  required Function(Map<String, dynamic> newFakultas) onAdded,
}) {
  final namaFakCtrl = TextEditingController();
  final dekanCtrl = TextEditingController();
  final prodiCtrl = TextEditingController();
  String selectedGedung = gedungList.isNotEmpty ? gedungList.first.nama : 'Gedung Soekarno (A)';
  String dekanQuery = '';
  bool isDekanDropdownOpen = false;

  showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (ctx) => StatefulBuilder(
      builder: (context, setModalState) {
        final matchingDosen = dekanQuery.length >= 3
            ? dosenList.where((d) {
                final q = dekanQuery.toLowerCase();
                return d.nama.toLowerCase().contains(q) ||
                    d.id.toLowerCase().contains(q) ||
                    d.jurusanNama.toLowerCase().contains(q);
              }).toList()
            : <UserModel>[];

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
                  // ── Input Nama Dekan dengan Autocomplete min 3 huruf & Tombol Quick Add + ──
                  Row(
                    children: [
                      Expanded(
                        child: TextField(
                          controller: dekanCtrl,
                          decoration: cleanMasterInputDecoration(
                            label: 'Nama Dekan',
                            hint: 'Ketik nama dosen (min. 3 huruf)...',
                            prefixIcon: const Icon(Icons.person_outline_rounded, size: 18, color: Color(0xFF64748B)),
                          ).copyWith(
                            suffixIcon: dekanCtrl.text.isNotEmpty
                                ? IconButton(
                                    icon: const Icon(Icons.clear_rounded, size: 18, color: Color(0xFF94A3B8)),
                                    onPressed: () {
                                      dekanCtrl.clear();
                                      setModalState(() {
                                        dekanQuery = '';
                                        isDekanDropdownOpen = false;
                                      });
                                    },
                                  )
                                : null,
                          ),
                          onChanged: (val) {
                            setModalState(() {
                              dekanQuery = val.trim();
                              isDekanDropdownOpen = dekanQuery.length >= 3;
                            });
                          },
                        ),
                      ),
                      const SizedBox(width: 8),
                      Material(
                        color: AppColors.primary.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(10),
                        child: InkWell(
                          onTap: () {
                            showQuickAddDosenDialog(
                              context: context,
                              defaultFakultas: namaFakCtrl.text.trim().isNotEmpty ? namaFakCtrl.text.trim() : null,
                              onAdded: (newDosen) {
                                setModalState(() {
                                  if (!dosenList.any((d) => d.id == newDosen.id)) {
                                    dosenList.add(newDosen);
                                  }
                                  dekanCtrl.text = newDosen.nama;
                                  dekanQuery = '';
                                  isDekanDropdownOpen = false;
                                });
                              },
                            );
                          },
                          borderRadius: BorderRadius.circular(10),
                          child: Container(
                            width: 48,
                            height: 48,
                            alignment: Alignment.center,
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(10),
                              border: Border.all(color: AppColors.primary.withValues(alpha: 0.25)),
                            ),
                            child: const Icon(Icons.add_rounded, color: AppColors.primary, size: 24),
                          ),
                        ),
                      ),
                    ],
                  ),
                  if (dekanQuery.isNotEmpty && dekanQuery.length < 3)
                    Padding(
                      padding: const EdgeInsets.only(top: 4, left: 4),
                      child: Row(
                        children: [
                          const Icon(Icons.info_outline_rounded, size: 13, color: Color(0xFF64748B)),
                          const SizedBox(width: 4),
                          Text(
                            'Ketik minimal 3 huruf untuk mencari dosen (${3 - dekanQuery.length} karakter lagi)...',
                            style: const TextStyle(fontSize: 11, color: Color(0xFF64748B)),
                          ),
                        ],
                      ),
                    ),
                  if (dekanQuery.length >= 3 && isDekanDropdownOpen)
                    Container(
                      margin: const EdgeInsets.only(top: 6),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: AppColors.primary.withValues(alpha: 0.3), width: 1.5),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.06),
                            blurRadius: 10,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                            decoration: BoxDecoration(
                              color: AppColors.primary.withValues(alpha: 0.06),
                              borderRadius: const BorderRadius.vertical(top: Radius.circular(10)),
                            ),
                            child: Row(
                              children: [
                                const Icon(Icons.auto_awesome_rounded, size: 14, color: AppColors.primary),
                                const SizedBox(width: 6),
                                Text(
                                  matchingDosen.isNotEmpty
                                      ? 'Pilih Dosen Terdaftar (${matchingDosen.length} ditemukan)'
                                      : 'Tidak ada dosen dengan kata kunci "$dekanQuery"',
                                  style: const TextStyle(
                                    fontSize: 11.5,
                                    fontWeight: FontWeight.bold,
                                    color: AppColors.primary,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          if (matchingDosen.isNotEmpty)
                            ConstrainedBox(
                              constraints: const BoxConstraints(maxHeight: 170),
                              child: ListView.separated(
                                shrinkWrap: true,
                                itemCount: matchingDosen.length,
                                separatorBuilder: (_, _) => const Divider(height: 1, color: Color(0xFFF1F5F9)),
                                itemBuilder: (context, idx) {
                                  final d = matchingDosen[idx];
                                  return InkWell(
                                    onTap: () {
                                      setModalState(() {
                                        dekanCtrl.text = d.nama;
                                        isDekanDropdownOpen = false;
                                      });
                                    },
                                    child: Padding(
                                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                                      child: Row(
                                        children: [
                                          CircleAvatar(
                                            radius: 14,
                                            backgroundColor: AppColors.primary.withValues(alpha: 0.1),
                                            child: Text(
                                              d.nama.isNotEmpty ? d.nama[0].toUpperCase() : 'D',
                                              style: const TextStyle(
                                                fontSize: 11,
                                                fontWeight: FontWeight.bold,
                                                color: AppColors.primary,
                                              ),
                                            ),
                                          ),
                                          const SizedBox(width: 10),
                                          Expanded(
                                            child: Column(
                                              crossAxisAlignment: CrossAxisAlignment.start,
                                              children: [
                                                Text(
                                                  d.nama,
                                                  style: const TextStyle(
                                                    fontSize: 12.5,
                                                    fontWeight: FontWeight.w600,
                                                    color: Color(0xFF0F172A),
                                                  ),
                                                ),
                                                Text(
                                                  '${d.id} • ${d.jurusanNama.isNotEmpty ? d.jurusanNama : d.fakultasNama}',
                                                  style: const TextStyle(
                                                    fontSize: 10.5,
                                                    color: Color(0xFF64748B),
                                                  ),
                                                ),
                                              ],
                                            ),
                                          ),
                                          const Icon(Icons.arrow_forward_ios_rounded, size: 12, color: Color(0xFF94A3B8)),
                                        ],
                                      ),
                                    ),
                                  );
                                },
                              ),
                            )
                          else
                            Padding(
                              padding: const EdgeInsets.all(12),
                              child: Text(
                                'Tekan tombol Simpan untuk tetap menggunakan "$dekanQuery" sebagai Dekan.',
                                style: const TextStyle(fontSize: 11, color: Color(0xFF64748B)),
                              ),
                            ),
                        ],
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
                    onAdd: () {
                      showQuickAddGedungDialog(
                        context: context,
                        onAdded: (newGedung) {
                          setModalState(() {
                            if (!gedungList.any((g) => g.id == newGedung.id)) {
                              gedungList.add(newGedung);
                            }
                            selectedGedung = newGedung.nama;
                          });
                        },
                      );
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
                                'jurusan': prodiList.isNotEmpty ? prodiList : <String>[],
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
        );
      },
    ),
  );
}

// ── Dialog Edit Fakultas ──
void showEditFakultasDialog({
  required BuildContext context,
  required Map<String, dynamic> fakultas,
  int? index,
  required List<GedungModel> gedungList,
  List<UserModel> dosenList = const [],
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
  String dekanQuery = '';
  bool isDekanDropdownOpen = false;

  showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (ctx) => StatefulBuilder(
      builder: (context, setModalState) {
        final matchingDosen = dekanQuery.length >= 3
            ? dosenList.where((d) {
                final q = dekanQuery.toLowerCase();
                return d.nama.toLowerCase().contains(q) ||
                    d.id.toLowerCase().contains(q) ||
                    d.jurusanNama.toLowerCase().contains(q);
              }).toList()
            : <UserModel>[];

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
                  // ── Input Nama Dekan dengan Autocomplete min 3 huruf & Tombol Quick Add + ──
                  Row(
                    children: [
                      Expanded(
                        child: TextField(
                          controller: dekanCtrl,
                          decoration: cleanMasterInputDecoration(
                            label: 'Nama Dekan',
                            hint: 'Ketik nama dosen (min. 3 huruf)...',
                            prefixIcon: const Icon(Icons.person_outline_rounded, size: 18, color: Color(0xFF64748B)),
                          ).copyWith(
                            suffixIcon: dekanCtrl.text.isNotEmpty
                                ? IconButton(
                                    icon: const Icon(Icons.clear_rounded, size: 18, color: Color(0xFF94A3B8)),
                                    onPressed: () {
                                      dekanCtrl.clear();
                                      setModalState(() {
                                        dekanQuery = '';
                                        isDekanDropdownOpen = false;
                                      });
                                    },
                                  )
                                : null,
                          ),
                          onChanged: (val) {
                            setModalState(() {
                              dekanQuery = val.trim();
                              isDekanDropdownOpen = dekanQuery.length >= 3;
                            });
                          },
                        ),
                      ),
                      const SizedBox(width: 8),
                      Material(
                        color: AppColors.primary.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(10),
                        child: InkWell(
                          onTap: () {
                            showQuickAddDosenDialog(
                              context: context,
                              defaultFakultas: namaFakCtrl.text.trim().isNotEmpty ? namaFakCtrl.text.trim() : null,
                              onAdded: (newDosen) {
                                setModalState(() {
                                  if (!dosenList.any((d) => d.id == newDosen.id)) {
                                    dosenList.add(newDosen);
                                  }
                                  dekanCtrl.text = newDosen.nama;
                                  dekanQuery = '';
                                  isDekanDropdownOpen = false;
                                });
                              },
                            );
                          },
                          borderRadius: BorderRadius.circular(10),
                          child: Container(
                            width: 48,
                            height: 48,
                            alignment: Alignment.center,
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(10),
                              border: Border.all(color: AppColors.primary.withValues(alpha: 0.25)),
                            ),
                            child: const Icon(Icons.add_rounded, color: AppColors.primary, size: 24),
                          ),
                        ),
                      ),
                    ],
                  ),
                  if (dekanQuery.isNotEmpty && dekanQuery.length < 3)
                    Padding(
                      padding: const EdgeInsets.only(top: 4, left: 4),
                      child: Row(
                        children: [
                          const Icon(Icons.info_outline_rounded, size: 13, color: Color(0xFF64748B)),
                          const SizedBox(width: 4),
                          Text(
                            'Ketik minimal 3 huruf untuk mencari dosen (${3 - dekanQuery.length} karakter lagi)...',
                            style: const TextStyle(fontSize: 11, color: Color(0xFF64748B)),
                          ),
                        ],
                      ),
                    ),
                  if (dekanQuery.length >= 3 && isDekanDropdownOpen)
                    Container(
                      margin: const EdgeInsets.only(top: 6),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: AppColors.primary.withValues(alpha: 0.3), width: 1.5),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.06),
                            blurRadius: 10,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                            decoration: BoxDecoration(
                              color: AppColors.primary.withValues(alpha: 0.06),
                              borderRadius: const BorderRadius.vertical(top: Radius.circular(10)),
                            ),
                            child: Row(
                              children: [
                                const Icon(Icons.auto_awesome_rounded, size: 14, color: AppColors.primary),
                                const SizedBox(width: 6),
                                Text(
                                  matchingDosen.isNotEmpty
                                      ? 'Pilih Dosen Terdaftar (${matchingDosen.length} ditemukan)'
                                      : 'Tidak ada dosen dengan kata kunci "$dekanQuery"',
                                  style: const TextStyle(
                                    fontSize: 11.5,
                                    fontWeight: FontWeight.bold,
                                    color: AppColors.primary,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          if (matchingDosen.isNotEmpty)
                            ConstrainedBox(
                              constraints: const BoxConstraints(maxHeight: 170),
                              child: ListView.separated(
                                shrinkWrap: true,
                                itemCount: matchingDosen.length,
                                separatorBuilder: (_, _) => const Divider(height: 1, color: Color(0xFFF1F5F9)),
                                itemBuilder: (context, idx) {
                                  final d = matchingDosen[idx];
                                  return InkWell(
                                    onTap: () {
                                      setModalState(() {
                                        dekanCtrl.text = d.nama;
                                        isDekanDropdownOpen = false;
                                      });
                                    },
                                    child: Padding(
                                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                                      child: Row(
                                        children: [
                                          CircleAvatar(
                                            radius: 14,
                                            backgroundColor: AppColors.primary.withValues(alpha: 0.1),
                                            child: Text(
                                              d.nama.isNotEmpty ? d.nama[0].toUpperCase() : 'D',
                                              style: const TextStyle(
                                                fontSize: 11,
                                                fontWeight: FontWeight.bold,
                                                color: AppColors.primary,
                                              ),
                                            ),
                                          ),
                                          const SizedBox(width: 10),
                                          Expanded(
                                            child: Column(
                                              crossAxisAlignment: CrossAxisAlignment.start,
                                              children: [
                                                Text(
                                                  d.nama,
                                                  style: const TextStyle(
                                                    fontSize: 12.5,
                                                    fontWeight: FontWeight.w600,
                                                    color: Color(0xFF0F172A),
                                                  ),
                                                ),
                                                Text(
                                                  '${d.id} • ${d.jurusanNama.isNotEmpty ? d.jurusanNama : d.fakultasNama}',
                                                  style: const TextStyle(
                                                    fontSize: 10.5,
                                                    color: Color(0xFF64748B),
                                                  ),
                                                ),
                                              ],
                                            ),
                                          ),
                                          const Icon(Icons.arrow_forward_ios_rounded, size: 12, color: Color(0xFF94A3B8)),
                                        ],
                                      ),
                                    ),
                                  );
                                },
                              ),
                            )
                          else
                            Padding(
                              padding: const EdgeInsets.all(12),
                              child: Text(
                                'Tekan tombol Simpan untuk tetap menggunakan "$dekanQuery" sebagai Dekan.',
                                style: const TextStyle(fontSize: 11, color: Color(0xFF64748B)),
                              ),
                            ),
                        ],
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
                    onAdd: () {
                      showQuickAddGedungDialog(
                        context: context,
                        onAdded: (newGedung) {
                          setModalState(() {
                            if (!gedungList.any((g) => g.id == newGedung.id)) {
                              gedungList.add(newGedung);
                            }
                            selectedGedung = newGedung.nama;
                          });
                        },
                      );
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
                                'id': (fakultas['id'] ?? '').toString(),
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
        );
      },
    ),
  );
}
