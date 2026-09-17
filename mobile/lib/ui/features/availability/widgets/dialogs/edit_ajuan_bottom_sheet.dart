// File: edit_ajuan_bottom_sheet.dart
// Deskripsi: Modal Bottom Sheet untuk menambah atau mengedit data pengajuan perkuliahan dosen.

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../../../config/constants.dart';
import '../../../../../data/models/ajuan_pengajaran_model.dart';
import '../../../../../data/models/gedung_model.dart';
import '../../../../../data/models/ruangan_model.dart';
import '../../../../../data/services/api_service.dart';

class EditAjuanBottomSheet {
  /// Menampilkan Form Edit / Sesuaikan Ajuan (Untuk Dosen, KaProdi, Dekan, dan Admin)
  static void showEditDialog({
    required BuildContext context,
    required AjuanPengajaranModel ajuan,
    required String currentRole,
    required Function(AjuanPengajaranModel) onSaved,
  }) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) {
        return DraggableScrollableSheet(
          initialChildSize: 0.90,
          minChildSize: 0.5,
          maxChildSize: 0.95,
          expand: false,
          builder: (_, scrollController) {
            return EditAjuanDialogWidget(
              initialAjuan: ajuan,
              currentRole: currentRole,
              onSaved: onSaved,
              scrollController: scrollController,
            );
          },
        );
      },
    );
  }

  /// Menampilkan Form Tambah Ajuan Baru (Untuk Dosen)
  static void showCreateDialog({
    required BuildContext context,
    required String dosenId,
    required String dosenNama,
    required String fakultasNama,
    required String jurusanNama,
    required Function(AjuanPengajaranModel) onCreated,
  }) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) {
        return DraggableScrollableSheet(
          initialChildSize: 0.90,
          minChildSize: 0.5,
          maxChildSize: 0.95,
          expand: false,
          builder: (_, scrollController) {
            return EditAjuanDialogWidget(
              initialAjuan: null,
              dosenId: dosenId,
              dosenNama: dosenNama,
              fakultasNama: fakultasNama,
              jurusanNama: jurusanNama,
              currentRole: 'dosen',
              onSaved: onCreated,
              scrollController: scrollController,
            );
          },
        );
      },
    );
  }
}

class EditAjuanDialogWidget extends StatefulWidget {
  final AjuanPengajaranModel? initialAjuan;
  final String? dosenId;
  final String? dosenNama;
  final String? fakultasNama;
  final String? jurusanNama;
  final String currentRole;
  final Function(AjuanPengajaranModel) onSaved;
  final ScrollController? scrollController;

  const EditAjuanDialogWidget({
    super.key,
    this.initialAjuan,
    this.dosenId,
    this.dosenNama,
    this.fakultasNama,
    this.jurusanNama,
    required this.currentRole,
    required this.onSaved,
    this.scrollController,
  });

  @override
  State<EditAjuanDialogWidget> createState() => _EditAjuanDialogWidgetState();
}

class _EditAjuanDialogWidgetState extends State<EditAjuanDialogWidget> {
  final _formKey = GlobalKey<FormState>();

  late TextEditingController _mkController;
  late TextEditingController _sksController;
  late TextEditingController _semesterController;
  late TextEditingController _kelasController;
  late TextEditingController _mhsController;
  late TextEditingController _catatanController;

  String _selectedHari = 'Senin';
  String _selectedJamMulai = '07:30';
  String _selectedJamSelesai = '10:00';
  String _selectedGedung = 'Gedung Soekarno (A)';
  String _selectedRuangan = 'R.301';

  final List<String> _days = ['Senin', 'Selasa', 'Rabu', 'Kamis', 'Jumat', 'Sabtu'];
  final List<String> _jamMulaiList = ['06:30', '07:30', '08:45', '09:50', '10:00', '13:00', '14:00', '15:30', '16:00', '18:30'];
  final List<String> _jamSelesaiList = ['08:30', '09:30', '10:00', '11:15', '12:20', '12:30', '15:30', '16:30', '17:30', '20:30'];

  List<GedungModel> _masterGedung = [];
  List<RuanganModel> _masterRuangan = [];

  @override
  void initState() {
    super.initState();
    final a = widget.initialAjuan;
    _mkController = TextEditingController(text: a?.mataKuliahNama ?? '');
    _sksController = TextEditingController(text: a?.sks.toString() ?? '3');
    _semesterController = TextEditingController(text: a?.semester.toString() ?? '3');
    _kelasController = TextEditingController(text: a?.kelasNama ?? 'A');
    _mhsController = TextEditingController(text: a?.jumlahMahasiswa.toString() ?? '35');
    _catatanController = TextEditingController(text: a?.catatanDosen ?? '');

    if (a != null) {
      _selectedHari = a.hari.isNotEmpty ? a.hari : 'Senin';
      _selectedJamMulai = a.jamMulai.isNotEmpty ? a.jamMulai : '07:30';
      _selectedJamSelesai = a.jamSelesai.isNotEmpty ? a.jamSelesai : '10:00';
      _selectedGedung = a.gedungNama.isNotEmpty ? a.gedungNama : 'Gedung Soekarno (A)';
      _selectedRuangan = a.ruanganNama.isNotEmpty ? a.ruanganNama : 'R.301';
    }

    if (!_days.contains(_selectedHari)) {
      _days.add(_selectedHari);
    }
    if (!_jamMulaiList.contains(_selectedJamMulai)) {
      _jamMulaiList.add(_selectedJamMulai);
      _jamMulaiList.sort();
    }
    if (!_jamSelesaiList.contains(_selectedJamSelesai)) {
      _jamSelesaiList.add(_selectedJamSelesai);
      _jamSelesaiList.sort();
    }

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        _loadMasterData();
      }
    });
  }

  Future<void> _loadMasterData() async {
    final api = context.read<ApiService>();
    final gedung = await api.getGedungList();
    final ruangan = await api.getRuanganList();
    if (mounted) {
      setState(() {
        _masterGedung = gedung;
        _masterRuangan = ruangan;
      });
    }
  }

  @override
  void dispose() {
    _mkController.dispose();
    _sksController.dispose();
    _semesterController.dispose();
    _kelasController.dispose();
    _mhsController.dispose();
    _catatanController.dispose();
    super.dispose();
  }

  // ── Searchable Gedung Picker Modal ──
  Future<String?> _showSearchableGedungPicker(BuildContext context, {String? currentSelected}) async {
    final searchPickerCtrl = TextEditingController();
    final allGedung = _masterGedung;

    List<GedungModel> filtered = List.from(allGedung);

    return showModalBottomSheet<String>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (bCtx) => StatefulBuilder(
        builder: (context, setPickerState) {
          return Container(
            height: MediaQuery.of(context).size.height * 0.65,
            decoration: const BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
            ),
            child: Column(
              children: [
                Container(
                  margin: const EdgeInsets.only(top: 10, bottom: 8),
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: const Color(0xFFCBD5E1),
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  child: Row(
                    children: [
                      const Expanded(
                        child: Text(
                          'Pilih Gedung Kuliah',
                          style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: Color(0xFF0F172A)),
                        ),
                      ),
                      IconButton(
                        icon: const Icon(Icons.close_rounded, color: Color(0xFF64748B)),
                        onPressed: () => Navigator.pop(bCtx),
                      ),
                    ],
                  ),
                ),
                const Divider(height: 1, color: Color(0xFFE2E8F0)),
                Padding(
                  padding: const EdgeInsets.all(12),
                  child: TextField(
                    controller: searchPickerCtrl,
                    style: const TextStyle(fontSize: 13),
                    decoration: InputDecoration(
                      hintText: 'Ketik nama gedung...',
                      hintStyle: const TextStyle(fontSize: 12, color: Color(0xFF94A3B8)),
                      prefixIcon: const Icon(Icons.search_rounded, color: AppColors.primary, size: 18),
                      suffixIcon: searchPickerCtrl.text.isNotEmpty
                          ? IconButton(
                              icon: const Icon(Icons.clear_rounded, size: 16),
                              onPressed: () {
                                searchPickerCtrl.clear();
                                setPickerState(() {
                                  filtered = List.from(allGedung);
                                });
                              },
                            )
                          : null,
                      filled: true,
                      fillColor: const Color(0xFFF8FAFC),
                      contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: const BorderSide(color: Color(0xFFCBD5E1))),
                      enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: const BorderSide(color: Color(0xFFCBD5E1))),
                      focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: const BorderSide(color: AppColors.primary, width: 1.5)),
                    ),
                    onChanged: (val) {
                      final q = val.trim().toLowerCase();
                      setPickerState(() {
                        if (q.isEmpty) {
                          filtered = List.from(allGedung);
                        } else {
                          filtered = allGedung.where((g) {
                            return g.nama.toLowerCase().contains(q) ||
                                g.aksesJurusan.toLowerCase().contains(q);
                          }).toList();
                        }
                      });
                    },
                  ),
                ),
                Expanded(
                  child: filtered.isEmpty
                      ? Center(
                          child: Text(
                            'Gedung "${searchPickerCtrl.text}" tidak ditemukan',
                            style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                          ),
                        )
                      : ListView.separated(
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                          itemCount: filtered.length,
                          separatorBuilder: (_, _) => const SizedBox(height: 6),
                          itemBuilder: (context, index) {
                            final g = filtered[index];
                            final isSelected = currentSelected == g.nama;

                            return InkWell(
                              onTap: () => Navigator.pop(bCtx, g.nama),
                              borderRadius: BorderRadius.circular(8),
                              child: Container(
                                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                                decoration: BoxDecoration(
                                  color: isSelected ? AppColors.primary.withValues(alpha: 0.08) : Colors.white,
                                  borderRadius: BorderRadius.circular(8),
                                  border: Border.all(
                                    color: isSelected ? AppColors.primary : const Color(0xFFE2E8F0),
                                    width: isSelected ? 1.5 : 1.0,
                                  ),
                                ),
                                child: Row(
                                  children: [
                                    CircleAvatar(
                                      radius: 16,
                                      backgroundColor: isSelected ? AppColors.primary : const Color(0xFFF1F5F9),
                                      child: Icon(Icons.apartment_rounded, size: 18, color: isSelected ? Colors.white : const Color(0xFF64748B)),
                                    ),
                                    const SizedBox(width: 10),
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            g.nama,
                                            style: TextStyle(
                                              fontSize: 12.5,
                                              fontWeight: isSelected ? FontWeight.bold : FontWeight.w600,
                                              color: const Color(0xFF0F172A),
                                            ),
                                          ),
                                          Text(
                                            'Buka: ${g.jamBuka} - ${g.jamTutup} • ${g.aksesJurusan}',
                                            style: const TextStyle(fontSize: 10.5, color: Color(0xFF64748B)),
                                          ),
                                        ],
                                      ),
                                    ),
                                    if (isSelected)
                                      const Icon(Icons.check_circle_rounded, color: AppColors.primary, size: 18),
                                  ],
                                ),
                              ),
                            );
                          },
                        ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  // ── Searchable Ruangan Picker Modal ──
  Future<String?> _showSearchableRuanganPicker(BuildContext context, {String? currentSelected, String? selectedGedung}) async {
    final searchPickerCtrl = TextEditingController();
    final allRuangan = _masterRuangan;

    List<RuanganModel> filtered = List.from(allRuangan);

    return showModalBottomSheet<String>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (bCtx) => StatefulBuilder(
        builder: (context, setPickerState) {
          return Container(
            height: MediaQuery.of(context).size.height * 0.70,
            decoration: const BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
            ),
            child: Column(
              children: [
                Container(
                  margin: const EdgeInsets.only(top: 10, bottom: 8),
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: const Color(0xFFCBD5E1),
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  child: Row(
                    children: [
                      const Expanded(
                        child: Text(
                          'Pilih Ruang Kelas / Lab',
                          style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: Color(0xFF0F172A)),
                        ),
                      ),
                      IconButton(
                        icon: const Icon(Icons.close_rounded, color: Color(0xFF64748B)),
                        onPressed: () => Navigator.pop(bCtx),
                      ),
                    ],
                  ),
                ),
                const Divider(height: 1, color: Color(0xFFE2E8F0)),
                Padding(
                  padding: const EdgeInsets.all(12),
                  child: TextField(
                    controller: searchPickerCtrl,
                    style: const TextStyle(fontSize: 13),
                    decoration: InputDecoration(
                      hintText: 'Ketik nama ruang (contoh: 301, Lab, Teori)...',
                      hintStyle: const TextStyle(fontSize: 12, color: Color(0xFF94A3B8)),
                      prefixIcon: const Icon(Icons.search_rounded, color: Color(0xFF0284C7), size: 18),
                      suffixIcon: searchPickerCtrl.text.isNotEmpty
                          ? IconButton(
                              icon: const Icon(Icons.clear_rounded, size: 16),
                              onPressed: () {
                                searchPickerCtrl.clear();
                                setPickerState(() {
                                  filtered = List.from(allRuangan);
                                });
                              },
                            )
                          : null,
                      filled: true,
                      fillColor: const Color(0xFFF8FAFC),
                      contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: const BorderSide(color: Color(0xFFCBD5E1))),
                      enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: const BorderSide(color: Color(0xFFCBD5E1))),
                      focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: const BorderSide(color: Color(0xFF0284C7), width: 1.5)),
                    ),
                    onChanged: (val) {
                      final q = val.trim().toLowerCase();
                      setPickerState(() {
                        if (q.isEmpty) {
                          filtered = List.from(allRuangan);
                        } else {
                          filtered = allRuangan.where((r) {
                            return r.nama.toLowerCase().contains(q) ||
                                r.gedungNama.toLowerCase().contains(q) ||
                                r.tipeRuangan.toLowerCase().contains(q) ||
                                r.kapasitas.toString().contains(q);
                          }).toList();
                        }
                      });
                    },
                  ),
                ),
                Expanded(
                  child: filtered.isEmpty
                      ? Center(
                          child: Text(
                            'Ruangan "${searchPickerCtrl.text}" tidak ditemukan',
                            style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                          ),
                        )
                      : ListView.separated(
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                          itemCount: filtered.length,
                          separatorBuilder: (_, _) => const SizedBox(height: 6),
                          itemBuilder: (context, index) {
                            final r = filtered[index];
                            final isSelected = currentSelected == r.nama;

                            return InkWell(
                              onTap: () => Navigator.pop(bCtx, r.nama),
                              borderRadius: BorderRadius.circular(8),
                              child: Container(
                                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                                decoration: BoxDecoration(
                                  color: isSelected ? const Color(0xFF0284C7).withValues(alpha: 0.08) : Colors.white,
                                  borderRadius: BorderRadius.circular(8),
                                  border: Border.all(
                                    color: isSelected ? const Color(0xFF0284C7) : const Color(0xFFE2E8F0),
                                    width: isSelected ? 1.5 : 1.0,
                                  ),
                                ),
                                child: Row(
                                  children: [
                                    CircleAvatar(
                                      radius: 16,
                                      backgroundColor: isSelected ? const Color(0xFF0284C7) : const Color(0xFFF1F5F9),
                                      child: Icon(Icons.meeting_room_outlined, size: 18, color: isSelected ? Colors.white : const Color(0xFF64748B)),
                                    ),
                                    const SizedBox(width: 10),
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          Row(
                                            children: [
                                              Text(
                                                r.nama,
                                                style: TextStyle(
                                                  fontSize: 12.5,
                                                  fontWeight: isSelected ? FontWeight.bold : FontWeight.w600,
                                                  color: const Color(0xFF0F172A),
                                                ),
                                              ),
                                              const SizedBox(width: 6),
                                              Container(
                                                padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1),
                                                decoration: BoxDecoration(
                                                  color: const Color(0xFFF1F5F9),
                                                  borderRadius: BorderRadius.circular(4),
                                                ),
                                                child: Text(
                                                  r.tipeRuangan,
                                                  style: const TextStyle(fontSize: 9.5, color: Color(0xFF475569), fontWeight: FontWeight.w500),
                                                ),
                                              ),
                                            ],
                                          ),
                                          const SizedBox(height: 2),
                                          Text(
                                            'Kapasitas: ${r.kapasitas} Kursi • ${r.gedungNama}',
                                            style: const TextStyle(fontSize: 10.5, color: Color(0xFF64748B)),
                                          ),
                                        ],
                                      ),
                                    ),
                                    if (isSelected)
                                      const Icon(Icons.check_circle_rounded, color: Color(0xFF0284C7), size: 18),
                                  ],
                                ),
                              ),
                            );
                          },
                        ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isNew = widget.initialAjuan == null;

    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: Column(
        children: [
          // ── Drag Handle & Header ──
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 12, 12, 8),
            child: Column(
              children: [
                Center(
                  child: Container(
                    width: 40,
                    height: 4,
                    decoration: BoxDecoration(
                      color: Colors.grey.shade300,
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: AppColors.primary.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Icon(
                        isNew ? Icons.add_chart_rounded : Icons.edit_note_rounded,
                        color: AppColors.primary,
                        size: 20,
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        isNew ? 'Tambah Pengajuan Baru' : 'Edit Pengajuan Perkuliahan',
                        style: const TextStyle(
                          color: Color(0xFF0F172A),
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.close_rounded, color: Color(0xFF64748B), size: 20),
                      visualDensity: VisualDensity.compact,
                      onPressed: () => Navigator.pop(context),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const Divider(height: 1, color: Color(0xFFE2E8F0)),

          // ── Scrollable Form Body ──
          Expanded(
            child: Form(
              key: _formKey,
              child: ListView(
                controller: widget.scrollController,
                padding: const EdgeInsets.fromLTRB(20, 16, 20, 20),
                children: [
                  _buildSectionHeader('MATA KULIAH'),
                  const SizedBox(height: 6),

                  _buildFieldLabel('Nama Mata Kuliah *'),
                  TextFormField(
                    controller: _mkController,
                    style: const TextStyle(fontSize: 13, color: Color(0xFF0F172A)),
                    decoration: _buildInputDecoration('Algoritma & Pemrograman'),
                    validator: (v) => v == null || v.trim().isEmpty ? 'Wajib diisi' : null,
                  ),
                  const SizedBox(height: 12),

                  Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            _buildFieldLabel('Kelas / Rombel *'),
                            TextFormField(
                              controller: _kelasController,
                              style: const TextStyle(fontSize: 13, color: Color(0xFF0F172A)),
                              textCapitalization: TextCapitalization.characters,
                              decoration: _buildInputDecoration('TI-1A'),
                              validator: (v) => v == null || v.trim().isEmpty ? 'Wajib' : null,
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            _buildFieldLabel('Bobot SKS *'),
                            TextFormField(
                              controller: _sksController,
                              keyboardType: TextInputType.number,
                              style: const TextStyle(fontSize: 13, color: Color(0xFF0F172A)),
                              decoration: _buildInputDecoration('3'),
                              validator: (v) => v == null || v.trim().isEmpty ? 'Wajib' : null,
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),

                  Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            _buildFieldLabel('Semester *'),
                            TextFormField(
                              controller: _semesterController,
                              keyboardType: TextInputType.number,
                              style: const TextStyle(fontSize: 13, color: Color(0xFF0F172A)),
                              decoration: _buildInputDecoration('1'),
                              validator: (v) => v == null || v.trim().isEmpty ? 'Wajib' : null,
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            _buildFieldLabel('Jumlah Mahasiswa *'),
                            TextFormField(
                              controller: _mhsController,
                              keyboardType: TextInputType.number,
                              style: const TextStyle(fontSize: 13, color: Color(0xFF0F172A)),
                              decoration: _buildInputDecoration('35'),
                              validator: (v) => v == null || v.trim().isEmpty ? 'Wajib' : null,
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),

                  _buildSectionHeader('WAKTU PERKULIAHAN'),
                  const SizedBox(height: 6),

                  _buildFieldLabel('Hari *'),
                  DropdownButtonFormField<String>(
                    initialValue: _days.contains(_selectedHari) ? _selectedHari : _days.first,
                    isExpanded: true,
                    icon: const Icon(Icons.keyboard_arrow_down_rounded, size: 20, color: Color(0xFF64748B)),
                    style: const TextStyle(fontSize: 13, color: Color(0xFF0F172A)),
                    decoration: _buildInputDecoration('Pilih Hari'),
                    items: _days
                        .map((d) => DropdownMenuItem(value: d, child: Text(d, style: const TextStyle(fontSize: 13, color: Color(0xFF0F172A)))))
                        .toList(),
                    onChanged: (val) {
                      if (val != null) setState(() => _selectedHari = val);
                    },
                  ),
                  const SizedBox(height: 12),

                  Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            _buildFieldLabel('Jam Mulai *'),
                            DropdownButtonFormField<String>(
                              initialValue: _jamMulaiList.contains(_selectedJamMulai) ? _selectedJamMulai : _jamMulaiList.first,
                              isExpanded: true,
                              icon: const Icon(Icons.keyboard_arrow_down_rounded, size: 18, color: Color(0xFF64748B)),
                              style: const TextStyle(fontSize: 12.5, color: Color(0xFF0F172A)),
                              decoration: _buildInputDecoration('Mulai'),
                              items: _jamMulaiList
                                  .map((j) => DropdownMenuItem(value: j, child: Text('$j WIB', style: const TextStyle(fontSize: 12.5, color: Color(0xFF0F172A)))))
                                  .toList(),
                              onChanged: (val) {
                                if (val != null) setState(() => _selectedJamMulai = val);
                              },
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            _buildFieldLabel('Jam Selesai *'),
                            DropdownButtonFormField<String>(
                              initialValue: _jamSelesaiList.contains(_selectedJamSelesai) ? _selectedJamSelesai : _jamSelesaiList.first,
                              isExpanded: true,
                              icon: const Icon(Icons.keyboard_arrow_down_rounded, size: 18, color: Color(0xFF64748B)),
                              style: const TextStyle(fontSize: 12.5, color: Color(0xFF0F172A)),
                              decoration: _buildInputDecoration('Selesai'),
                              items: _jamSelesaiList
                                  .map((j) => DropdownMenuItem(value: j, child: Text('$j WIB', style: const TextStyle(fontSize: 12.5, color: Color(0xFF0F172A)))))
                                  .toList(),
                              onChanged: (val) {
                                if (val != null) setState(() => _selectedJamSelesai = val);
                              },
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),

                  _buildSectionHeader('LOKASI RUANGAN'),
                  const SizedBox(height: 6),

                  Row(
                    children: [
                      Expanded(
                        child: InkWell(
                          onTap: () async {
                            final picked = await _showSearchableGedungPicker(context, currentSelected: _selectedGedung);
                            if (picked != null) {
                              setState(() => _selectedGedung = picked);
                            }
                          },
                          borderRadius: BorderRadius.circular(8),
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                            decoration: BoxDecoration(
                              color: const Color(0xFFF8FAFC),
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(color: const Color(0xFFE2E8F0)),
                            ),
                            child: Row(
                              children: [
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      const Text(
                                        'Gedung Kuliah',
                                        style: TextStyle(fontSize: 10, color: Color(0xFF64748B), fontWeight: FontWeight.w500),
                                      ),
                                      const SizedBox(height: 2),
                                      Text(
                                        _selectedGedung,
                                        style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: Color(0xFF0F172A)),
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    ],
                                  ),
                                ),
                                const Icon(Icons.keyboard_arrow_down_rounded, size: 20, color: Color(0xFF64748B)),
                              ],
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: InkWell(
                          onTap: () async {
                            final picked = await _showSearchableRuanganPicker(
                              context,
                              currentSelected: _selectedRuangan,
                              selectedGedung: _selectedGedung,
                            );
                            if (picked != null) {
                              setState(() => _selectedRuangan = picked);
                            }
                          },
                          borderRadius: BorderRadius.circular(8),
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                            decoration: BoxDecoration(
                              color: const Color(0xFFF8FAFC),
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(color: const Color(0xFFE2E8F0)),
                            ),
                            child: Row(
                              children: [
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      const Text(
                                        'Ruang Kelas',
                                        style: TextStyle(fontSize: 10, color: Color(0xFF64748B), fontWeight: FontWeight.w500),
                                      ),
                                      const SizedBox(height: 2),
                                      Text(
                                        _selectedRuangan,
                                        style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: Color(0xFF0F172A)),
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    ],
                                  ),
                                ),
                                const Icon(Icons.keyboard_arrow_down_rounded, size: 20, color: Color(0xFF64748B)),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),

                  _buildSectionHeader('CATATAN FASILITAS'),
                  const SizedBox(height: 6),
                  TextFormField(
                    controller: _catatanController,
                    maxLines: 2,
                    style: const TextStyle(fontSize: 12.5, color: Color(0xFF0F172A)),
                    decoration: _buildInputDecoration('Catatan opsional (proyektor, AC, dll)'),
                  ),
                ],
              ),
            ),
          ),

          // ── Footer Buttons ──
          Container(
            padding: const EdgeInsets.fromLTRB(20, 12, 20, 20),
            decoration: BoxDecoration(
              color: Colors.white,
              border: const Border(top: BorderSide(color: Color(0xFFE2E8F0), width: 1)),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.04),
                  blurRadius: 8,
                  offset: const Offset(0, -3),
                ),
              ],
            ),
            child: Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      side: const BorderSide(color: Color(0xFFCBD5E1)),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                    ),
                    onPressed: () => Navigator.pop(context),
                    child: const Text('Batal', style: TextStyle(color: Color(0xFF475569), fontWeight: FontWeight.w600, fontSize: 13)),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton.icon(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primary,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                      elevation: 0,
                    ),
                    onPressed: () {
                      if (!_formKey.currentState!.validate()) return;

                      final cur = widget.initialAjuan;
                      final ajuan = AjuanPengajaranModel(
                        id: cur?.id ?? 'AJU_${DateTime.now().millisecondsSinceEpoch}',
                        dosenId: cur?.dosenId ?? widget.dosenId ?? 'DSN001',
                        dosenNama: cur?.dosenNama ?? widget.dosenNama ?? 'Dosen Pengampu',
                        fakultasNama: cur?.fakultasNama ?? widget.fakultasNama ?? 'Fakultas Sains & Teknologi',
                        jurusanNama: cur?.jurusanNama ?? widget.jurusanNama ?? 'Teknik Informatika',
                        mataKuliahId: cur?.mataKuliahId ?? 'MK_${DateTime.now().millisecondsSinceEpoch}',
                        mataKuliahNama: _mkController.text.trim(),
                        sks: int.tryParse(_sksController.text.trim()) ?? 3,
                        hari: _selectedHari,
                        jamMulai: _selectedJamMulai,
                        jamSelesai: _selectedJamSelesai,
                        gedungNama: _selectedGedung,
                        ruanganNama: _selectedRuangan,
                        semester: int.tryParse(_semesterController.text.trim()) ?? 1,
                        kelasNama: _kelasController.text.trim().toUpperCase(),
                        jumlahMahasiswa: int.tryParse(_mhsController.text.trim()) ?? 30,
                        status: cur?.status ?? 'menunggu_kaprodi',
                        catatanDosen: _catatanController.text.trim().isNotEmpty ? _catatanController.text.trim() : cur?.catatanDosen,
                        catatanKaProdi: cur?.catatanKaProdi,
                        catatanDekan: cur?.catatanDekan,
                        catatanAdmin: cur?.catatanAdmin,
                        alasanPenolakan: cur?.alasanPenolakan,
                        submittedAt: cur?.submittedAt ?? DateTime.now(),
                        updatedAt: DateTime.now(),
                      );

                      Navigator.pop(context);
                      widget.onSaved(ajuan);
                    },
                    icon: Icon(isNew ? Icons.send_rounded : Icons.check_circle_rounded, size: 18),
                    label: Text(
                      isNew ? 'Kirim Pengajuan' : 'Simpan',
                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionHeader(String title) {
    return Padding(
      padding: const EdgeInsets.only(top: 4, bottom: 2),
      child: Text(
        title,
        style: const TextStyle(
          fontSize: 10.5,
          fontWeight: FontWeight.bold,
          color: Color(0xFF64748B),
          letterSpacing: 0.6,
        ),
      ),
    );
  }

  Widget _buildFieldLabel(String label) {
    final isRequired = label.contains('*');
    final cleanLabel = label.replaceAll('*', '').trim();
    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: RichText(
        text: TextSpan(
          text: cleanLabel,
          style: const TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w600,
            color: Color(0xFF1E293B),
          ),
          children: isRequired
              ? [
                  const TextSpan(
                    text: ' *',
                    style: TextStyle(color: Color(0xFFEF4444), fontWeight: FontWeight.bold),
                  ),
                ]
              : null,
        ),
      ),
    );
  }

  InputDecoration _buildInputDecoration(String hint) {
    return InputDecoration(
      hintText: hint,
      hintStyle: const TextStyle(fontSize: 12, color: Color(0xFF94A3B8)),
      filled: true,
      fillColor: const Color(0xFFF8FAFC),
      isDense: true,
      contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 11),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8),
        borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8),
        borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8),
        borderSide: const BorderSide(color: AppColors.primary, width: 1.5),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8),
        borderSide: const BorderSide(color: Color(0xFFEF4444)),
      ),
      focusedErrorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8),
        borderSide: const BorderSide(color: Color(0xFFEF4444), width: 1.5),
      ),
    );
  }
}
