// File: gedung_form_dialog.dart
// Deskripsi: Modal bottom sheet form Tambah dan Edit Gedung Kampus master data.

import 'package:flutter/material.dart';
import '../../../../../config/constants.dart';
import '../../../../../data/models/gedung_model.dart';
import '../master_data_pickers.dart';

// ── Dialog Tambah Gedung ──
void showAddGedungDialog({
  required BuildContext context,
  required List<GedungModel> gedungList,
  required Function(GedungModel newGedung) onAdded,
}) {
  final namaCtrl = TextEditingController();
  final jamBukaCtrl = TextEditingController(text: '07:30');
  final jamTutupCtrl = TextEditingController(text: '17:00');
  String selectedAkses = 'Semua Fakultas';

  showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (ctx) => StatefulBuilder(
      builder: (context, setModalState) => Padding(
        padding: EdgeInsets.only(
          bottom: MediaQuery.of(context).viewInsets.bottom,
        ),
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
                      child: const Icon(
                        Icons.apartment_rounded,
                        color: AppColors.primary,
                        size: 20,
                      ),
                    ),
                    const SizedBox(width: 10),
                    const Expanded(
                      child: Text(
                        'Tambah Gedung Kampus',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF0F172A),
                        ),
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
                  controller: namaCtrl,
                  decoration: cleanMasterInputDecoration(
                    label: 'Nama Gedung',
                    hint: 'Contoh: Gedung Soekarno (A)',
                    prefixIcon: const Icon(Icons.business_rounded, size: 18, color: Color(0xFF64748B)),
                  ),
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: jamBukaCtrl,
                        decoration: cleanMasterInputDecoration(
                          label: 'Jam Buka',
                          hint: '07:30',
                          prefixIcon: const Icon(Icons.access_time_rounded, size: 18, color: Color(0xFF64748B)),
                        ),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: TextField(
                        controller: jamTutupCtrl,
                        decoration: cleanMasterInputDecoration(
                          label: 'Jam Tutup',
                          hint: '17:00',
                          prefixIcon: const Icon(Icons.lock_clock_rounded, size: 18, color: Color(0xFF64748B)),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                buildSearchablePickerField(
                  label: 'Akses Fakultas',
                  value: selectedAkses,
                  placeholder: 'Pilih akses fakultas...',
                  icon: Icons.account_balance_rounded,
                  onTap: () async {
                    final picked = await showSearchableFakultasPicker(
                      context: context,
                      currentSelected: selectedAkses,
                    );
                    if (picked != null) {
                      setModalState(() => selectedAkses = picked);
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
                          if (namaCtrl.text.trim().isNotEmpty) {
                            final newGedung = GedungModel(
                              id: 'GDG_${DateTime.now().millisecondsSinceEpoch}',
                              nama: namaCtrl.text.trim(),
                              jamBuka: jamBukaCtrl.text.trim(),
                              jamTutup: jamTutupCtrl.text.trim(),
                              aksesJurusan: selectedAkses,
                            );
                            onAdded(newGedung);
                            Navigator.pop(ctx);
                          }
                        },
                        child: const Text('Simpan Gedung', style: TextStyle(fontWeight: FontWeight.bold)),
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

// ── Dialog Edit Gedung ──
void showEditGedungDialog({
  required BuildContext context,
  required GedungModel gedung,
  required Function(GedungModel updatedGedung) onSaved,
}) {
  final namaCtrl = TextEditingController(text: gedung.nama);
  final jamBukaCtrl = TextEditingController(text: gedung.jamBuka);
  final jamTutupCtrl = TextEditingController(text: gedung.jamTutup);
  String selectedAkses = gedung.aksesJurusan;

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
                        'Edit Gedung Kampus',
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
                  controller: namaCtrl,
                  decoration: cleanMasterInputDecoration(
                    label: 'Nama Gedung',
                    hint: 'Contoh: Gedung Soekarno (A)',
                    prefixIcon: const Icon(Icons.business_rounded, size: 18, color: Color(0xFF64748B)),
                  ),
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: jamBukaCtrl,
                        decoration: cleanMasterInputDecoration(
                          label: 'Jam Buka',
                          hint: '07:30',
                          prefixIcon: const Icon(Icons.access_time_rounded, size: 18, color: Color(0xFF64748B)),
                        ),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: TextField(
                        controller: jamTutupCtrl,
                        decoration: cleanMasterInputDecoration(
                          label: 'Jam Tutup',
                          hint: '17:00',
                          prefixIcon: const Icon(Icons.lock_clock_rounded, size: 18, color: Color(0xFF64748B)),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                buildSearchablePickerField(
                  label: 'Akses Fakultas',
                  value: selectedAkses,
                  placeholder: 'Pilih akses fakultas...',
                  icon: Icons.account_balance_rounded,
                  onTap: () async {
                    final picked = await showSearchableFakultasPicker(
                      context: context,
                      currentSelected: selectedAkses,
                    );
                    if (picked != null) {
                      setModalState(() => selectedAkses = picked);
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
                          if (namaCtrl.text.trim().isNotEmpty) {
                            final updated = gedung.copyWith(
                              nama: namaCtrl.text.trim(),
                              jamBuka: jamBukaCtrl.text.trim(),
                              jamTutup: jamTutupCtrl.text.trim(),
                              aksesJurusan: selectedAkses,
                            );
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
