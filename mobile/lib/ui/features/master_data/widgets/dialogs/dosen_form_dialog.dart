// File: dosen_form_dialog.dart
// Deskripsi: Modal bottom sheet form Tambah dan Edit Dosen Pengampu master data.

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../../../config/constants.dart';
import '../../../../../data/models/user_model.dart';
import '../../../../../data/services/api_service.dart';
import '../master_data_pickers.dart';

// ── Dialog Tambah Dosen Baru ──
void showAddDosenDialog({
  required BuildContext context,
  required List<UserModel> dosenList,
  required List<Map<String, dynamic>> fakultasData,
  required List<Map<String, dynamic>> matkulData,
  required Set<String> priorityDosenIds,
  required Function(UserModel newDosen, bool isPriority) onAdded,
}) {
  final nidnCtrl = TextEditingController();
  final namaCtrl = TextEditingController();
  final emailCtrl = TextEditingController();
  String selectedProdi = 'Teknik Informatika';
  String selectedFakultas = 'Fakultas Sains & Teknologi';
  String selectedMatkul = 'IF101 - Algoritma & Pemrograman';
  bool isPriority = false;

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
                        color: const Color(0xFFECFDF5),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: const Icon(Icons.person_add_alt_1_rounded, color: Color(0xFF059669), size: 20),
                    ),
                    const SizedBox(width: 10),
                    const Expanded(
                      child: Text(
                        'Tambah Dosen Baru',
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
                  controller: nidnCtrl,
                  decoration: cleanMasterInputDecoration(
                    label: 'NIDN / NIP',
                    hint: 'Contoh: 0412098801 atau DSN011',
                    prefixIcon: const Icon(Icons.badge_rounded, size: 18, color: Color(0xFF64748B)),
                  ),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: namaCtrl,
                  decoration: cleanMasterInputDecoration(
                    label: 'Nama Lengkap',
                    hint: 'Contoh: Dr. Ir. Ahmad Maulana, M.Kom.',
                    prefixIcon: const Icon(Icons.person_rounded, size: 18, color: Color(0xFF64748B)),
                  ),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: emailCtrl,
                  keyboardType: TextInputType.emailAddress,
                  decoration: cleanMasterInputDecoration(
                    label: 'Alamat Email',
                    hint: 'Contoh: ahmad.maulana@kampus.ac.id',
                    prefixIcon: const Icon(Icons.email_rounded, size: 18, color: Color(0xFF64748B)),
                  ),
                ),
                const SizedBox(height: 12),
                buildSearchablePickerField(
                  label: 'Fakultas Mengajar',
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
                  label: 'Program Studi',
                  value: selectedProdi,
                  placeholder: 'Pilih prodi...',
                  icon: Icons.domain_verification_rounded,
                  onTap: () async {
                    final picked = await showSearchableProdiPicker(
                      context: context,
                      fakultasData: fakultasData,
                      currentSelected: selectedProdi,
                      selectedFakultas: selectedFakultas,
                    );
                    if (picked != null) {
                      setModalState(() => selectedProdi = picked);
                    }
                  },
                ),
                const SizedBox(height: 12),
                buildSearchablePickerField(
                  label: 'Mata Kuliah',
                  value: selectedMatkul,
                  placeholder: 'Pilih mata kuliah...',
                  icon: Icons.book_rounded,
                  onTap: () async {
                    final picked = await showSearchableMatkulPicker(
                      context: context,
                      matkulData: matkulData,
                      currentSelected: selectedMatkul,
                    );
                    if (picked != null) {
                      setModalState(() => selectedMatkul = picked);
                    }
                  },
                ),
                const SizedBox(height: 12),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF8FAFC),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: const Color(0xFFE2E8F0)),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Row(
                        children: [
                          Icon(Icons.star_rounded, color: AppColors.primaryAccent, size: 20),
                          SizedBox(width: 8),
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text('Prioritas Utama', style: TextStyle(fontSize: 12.5, fontWeight: FontWeight.bold, color: Color(0xFF0F172A))),
                              Text('Jadwalkan di slot waktu utama kampus', style: TextStyle(fontSize: 10.5, color: Color(0xFF64748B))),
                            ],
                          ),
                        ],
                      ),
                      Switch(
                        value: isPriority,
                        activeThumbColor: const Color(0xFF059669),
                        activeTrackColor: const Color(0xFFA7F3D0),
                        onChanged: (v) => setModalState(() => isPriority = v),
                      ),
                    ],
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
                          backgroundColor: const Color(0xFF059669),
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          elevation: 0,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                        ),
                        onPressed: () async {
                          final cleanName = namaCtrl.text.trim();
                          var cleanEmail = emailCtrl.text.trim();
                          if (cleanName.isEmpty) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(content: Text('Nama lengkap dosen wajib diisi!')),
                            );
                            return;
                          }
                          if (cleanEmail.isEmpty) {
                            cleanEmail = '${cleanName.toLowerCase().replaceAll(RegExp(r'[^a-z]'), '')}@kampus.ac.id';
                          }

                          final rawNidn = nidnCtrl.text.trim();
                          final newId = rawNidn.isNotEmpty ? rawNidn : 'DSN00${dosenList.length + 1}';
                          final newDosen = UserModel(
                            id: newId,
                            nama: cleanName,
                            email: cleanEmail,
                            role: 'dosen',
                            jurusanId: 'JUR001',
                            jurusanNama: selectedProdi,
                            fakultasNama: selectedFakultas,
                            matkulNama: selectedMatkul,
                            isPriority: isPriority,
                          );

                          final api = context.read<ApiService>();
                          await api.createDosen(newDosen);

                          if (!ctx.mounted) return;
                          onAdded(newDosen, isPriority);
                          Navigator.pop(ctx);
                        },
                        child: const Text('Simpan Dosen', style: TextStyle(fontWeight: FontWeight.bold)),
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

// ── Dialog Edit Dosen ──
void showEditDosenDialog({
  required BuildContext context,
  required UserModel dosen,
  required List<UserModel> dosenList,
  required List<Map<String, dynamic>> fakultasData,
  required List<Map<String, dynamic>> matkulData,
  required Set<String> priorityDosenIds,
  required Function(UserModel updatedDosen, bool isPriority) onSaved,
}) {
  final nidnCtrl = TextEditingController(text: dosen.id);
  final namaCtrl = TextEditingController(text: dosen.nama);
  final emailCtrl = TextEditingController(text: dosen.email);
  String selectedProdi = dosen.jurusanNama;
  String selectedFakultas = dosen.fakultasNama;
  String selectedMatkul = dosen.matkulNama ?? 'IF101 - Algoritma & Pemrograman';
  bool isPriority = priorityDosenIds.contains(dosen.id);

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
                        color: const Color(0xFFECFDF5),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: const Icon(Icons.edit_note_rounded, color: Color(0xFF059669), size: 20),
                    ),
                    const SizedBox(width: 10),
                    const Expanded(
                      child: Text(
                        'Edit Data Dosen',
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
                  controller: nidnCtrl,
                  decoration: cleanMasterInputDecoration(
                    label: 'NIDN / NIP',
                    hint: 'Contoh: 0412098801',
                    prefixIcon: const Icon(Icons.badge_rounded, size: 18, color: Color(0xFF64748B)),
                  ),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: namaCtrl,
                  decoration: cleanMasterInputDecoration(
                    label: 'Nama Lengkap',
                    hint: 'Contoh: Dr. Ir. Ahmad Maulana, M.Kom.',
                    prefixIcon: const Icon(Icons.person_rounded, size: 18, color: Color(0xFF64748B)),
                  ),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: emailCtrl,
                  keyboardType: TextInputType.emailAddress,
                  decoration: cleanMasterInputDecoration(
                    label: 'Alamat Email',
                    hint: 'Contoh: ahmad.maulana@kampus.ac.id',
                    prefixIcon: const Icon(Icons.email_rounded, size: 18, color: Color(0xFF64748B)),
                  ),
                ),
                const SizedBox(height: 12),
                buildSearchablePickerField(
                  label: 'Fakultas Mengajar',
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
                  label: 'Program Studi',
                  value: selectedProdi,
                  placeholder: 'Pilih prodi...',
                  icon: Icons.domain_verification_rounded,
                  onTap: () async {
                    final picked = await showSearchableProdiPicker(
                      context: context,
                      fakultasData: fakultasData,
                      currentSelected: selectedProdi,
                      selectedFakultas: selectedFakultas,
                    );
                    if (picked != null) {
                      setModalState(() => selectedProdi = picked);
                    }
                  },
                ),
                const SizedBox(height: 12),
                buildSearchablePickerField(
                  label: 'Mata Kuliah',
                  value: selectedMatkul,
                  placeholder: 'Pilih mata kuliah...',
                  icon: Icons.book_rounded,
                  onTap: () async {
                    final picked = await showSearchableMatkulPicker(
                      context: context,
                      matkulData: matkulData,
                      currentSelected: selectedMatkul,
                    );
                    if (picked != null) {
                      setModalState(() => selectedMatkul = picked);
                    }
                  },
                ),
                const SizedBox(height: 12),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF8FAFC),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: const Color(0xFFE2E8F0)),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Row(
                        children: [
                          Icon(Icons.star_rounded, color: AppColors.primaryAccent, size: 20),
                          SizedBox(width: 8),
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text('Prioritas Utama', style: TextStyle(fontSize: 12.5, fontWeight: FontWeight.bold, color: Color(0xFF0F172A))),
                              Text('Jadwalkan di slot waktu utama kampus', style: TextStyle(fontSize: 10.5, color: Color(0xFF64748B))),
                            ],
                          ),
                        ],
                      ),
                      Switch(
                        value: isPriority,
                        activeThumbColor: const Color(0xFF059669),
                        activeTrackColor: const Color(0xFFA7F3D0),
                        onChanged: (v) => setModalState(() => isPriority = v),
                      ),
                    ],
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
                          backgroundColor: const Color(0xFF059669),
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          elevation: 0,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                        ),
                        onPressed: () async {
                          final cleanName = namaCtrl.text.trim();
                          var cleanEmail = emailCtrl.text.trim();
                          if (cleanName.isEmpty) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(content: Text('Nama lengkap dosen wajib diisi!')),
                            );
                            return;
                          }
                          if (cleanEmail.isEmpty) {
                            cleanEmail = '${cleanName.toLowerCase().replaceAll(RegExp(r'[^a-z]'), '')}@kampus.ac.id';
                          }

                          final updatedDosen = dosen.copyWith(
                            id: nidnCtrl.text.trim().isNotEmpty ? nidnCtrl.text.trim() : dosen.id,
                            nama: cleanName,
                            email: cleanEmail,
                            jurusanNama: selectedProdi,
                            fakultasNama: selectedFakultas,
                            matkulNama: selectedMatkul,
                            isPriority: isPriority,
                          );

                          final api = context.read<ApiService>();
                          await api.createDosen(updatedDosen);

                          if (!ctx.mounted) return;
                          onSaved(updatedDosen, isPriority);
                          Navigator.pop(ctx);
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
