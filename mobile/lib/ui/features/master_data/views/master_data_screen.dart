// File: master_data_screen.dart
// Deskripsi: Layar Master Data & Prioritas Kampus khusus Role Super Admin.
// Fitur: Desain modern profesional (no AI slop, no tacky gradients, zero overflow),
//        manajemen terstruktur Gedung, Fakultas & Prodi, Mata Kuliah, Dosen (dengan Searchable Pickers).

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../../config/constants.dart';
import '../../../../data/models/gedung_model.dart';
import '../../../../data/models/user_model.dart';
import '../../../../data/mock/mock_database.dart';
import '../../../../data/services/api_service.dart';
import '../../availability/view_models/availability_view_model.dart';
import '../../dashboard/view_models/dashboard_view_model.dart';
import '../../schedule/view_models/schedule_view_model.dart';
import '../widgets/dosen_master_tab.dart';
import '../widgets/fakultas_master_tab.dart';
import '../widgets/gedung_master_tab.dart';
import '../widgets/master_data_dialogs.dart';
import '../widgets/master_data_screen_components.dart';
import '../widgets/matkul_master_tab.dart';

class AdminMasterDataScreen extends StatefulWidget {
  const AdminMasterDataScreen({super.key});

  @override
  State<AdminMasterDataScreen> createState() => _AdminMasterDataScreenState();
}

class _AdminMasterDataScreenState extends State<AdminMasterDataScreen> {
  final TextEditingController _searchCtrl = TextEditingController();
  String _selectedCategory = 'Semua';
  String _searchQuery = '';

  bool _isLoading = true;
  List<GedungModel> _gedungList = [];
  List<UserModel> _dosenList = [];
  final Set<String> _priorityDosenIds = {'DSN001', 'DSN003'};

  // State seleksi untuk kartu Master Data (berwarna saat dipilih)
  bool _isMultiSelectMode = false;
  final Set<String> _selectedGedungIds = {};
  final Set<String> _selectedFakultasIds = {};
  final Set<String> _selectedMatkulIds = {};
  final Set<String> _selectedDosenIds = {};

  int get _totalSelectedCount =>
      _selectedGedungIds.length +
      _selectedFakultasIds.length +
      _selectedMatkulIds.length +
      _selectedDosenIds.length;

  // State ekspansi untuk kategori pada tab "Semua" agar halaman tetap rapi
  bool _expandGedung = false;
  bool _expandFakultas = false;
  bool _expandMatkul = false;
  bool _expandDosen = false;

  // Master list Fakultas & Jurusan
  final List<Map<String, dynamic>> _fakultasData = [];

  // Master list Mata Kuliah & Kelas
  final List<Map<String, dynamic>> _matkulData = [];

  @override
  void initState() {
    super.initState();
    _loadData();
    _searchCtrl.addListener(() {
      setState(() {
        _searchQuery = _searchCtrl.text.trim().toLowerCase();
      });
    });
  }

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  Future<void> _loadData() async {
    if (!mounted) return;
    final api = context.read<ApiService>();
    setState(() => _isLoading = true);
    try {
      await MockDatabase.initLocalCache(forceReload: true);
      final gedung = await api.getGedungList();
      final users = await api.getAllUsers();
      final dosen = users.where((u) => u.role == 'dosen' || u.role == 'kajur' || u.role == 'dekan').toList();

      if (mounted) {
        setState(() {
          _gedungList = List.from(gedung);
          _dosenList = List.from(dosen);
          _fakultasData.clear();
          _fakultasData.addAll(MockDatabase.fakultasData);
          _matkulData.clear();
          _matkulData.addAll(MockDatabase.matkulData);
        });
      }
    } catch (e) {
      debugPrint('Error loading master data: $e');
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  Future<void> _toggleDosenPriority(String dosenId, bool currentPriority) async {
    final api = context.read<ApiService>();
    final newPriority = !currentPriority;
    await api.setDosenPriority(dosenId, newPriority);
    setState(() {
      if (newPriority) {
        _priorityDosenIds.add(dosenId);
      } else {
        _priorityDosenIds.remove(dosenId);
      }
    });
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            newPriority
                ? 'Dosen diatur sebagai Prioritas Utama Penjadwalan (MRV)'
                : 'Prioritas Dosen dinonaktifkan',
          ),
          backgroundColor: newPriority ? AppColors.primary : const Color(0xFF334155),
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        ),
      );
    }
  }

  void _confirmBatchDelete() {
    final count = _totalSelectedCount;
    if (count == 0) return;

    confirmBatchDeleteDialog(
      context: context,
      count: count,
      onConfirm: () async {
        final api = context.read<ApiService>();

        // 1. Cascade delete all selected Gedung
        for (var id in _selectedGedungIds) {
          await api.deleteGedung(id);
        }

        // 2. Cascade delete all selected Fakultas
        for (var id in _selectedFakultasIds) {
          await MockDatabase.cascadeDeleteFakultas(id);
        }

        // 3. Cascade delete all selected Matkul
        for (var id in _selectedMatkulIds) {
          await MockDatabase.cascadeDeleteMatkul(id);
        }

        // 4. Cascade delete all selected Dosen
        for (var id in _selectedDosenIds) {
          await api.deleteUser(id);
        }

        setState(() {
          _gedungList.removeWhere((g) => _selectedGedungIds.contains(g.id));
          _fakultasData.removeWhere((f) => _selectedFakultasIds.contains((f['id'] ?? f['nama'])?.toString()));
          _matkulData.removeWhere((m) => _selectedMatkulIds.contains(m['kode']?.toString()));
          _dosenList.removeWhere((d) => _selectedDosenIds.contains(d.id));
          _priorityDosenIds.removeWhere((id) => _selectedDosenIds.contains(id));

          _selectedGedungIds.clear();
          _selectedFakultasIds.clear();
          _selectedMatkulIds.clear();
          _selectedDosenIds.clear();
          _isMultiSelectMode = false;
        });

        _syncGlobalData();

        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Berhasil menghapus $count data master dan seluruh jadwal/ruangan terkait!'),
            backgroundColor: const Color(0xFFEF4444),
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
          ),
        );
      },
    );
  }

  void _syncGlobalData() {
    if (!mounted) return;
    try {
      context.read<ScheduleViewModel>().loadScheduleData();
      context.read<DashboardViewModel>().loadDashboardData();
      context.read<AvailabilityViewModel>().loadAvailabilityData();
    } catch (_) {}
  }

  void _triggerAddForCurrentCategory() {
    final api = context.read<ApiService>();
    if (_selectedCategory == 'Gedung') {
      showAddGedungDialog(
        context: context,
        gedungList: _gedungList,
        onAdded: (g) async {
          await api.addGedung(g);
          setState(() => _gedungList.add(g));
        },
      );
    } else if (_selectedCategory == 'Fakultas & Prodi') {
      showAddFakultasDialog(
        context: context,
        fakultasData: _fakultasData,
        gedungList: _gedungList,
        onAdded: (f) {
          final fKey = f['id']?.toString() ?? '';
          final fNama = f['nama']?.toString() ?? '';
          MockDatabase.deletedFakultasIds.remove(fKey);
          MockDatabase.deletedFakultasIds.remove(fNama);
          MockDatabase.fakultasData.removeWhere((item) => ((item['id'] ?? item['nama'])?.toString() ?? '') == fKey);
          MockDatabase.fakultasData.add(f);
          MockDatabase.saveLocalFakultas();
          setState(() => _fakultasData.add(f));
        },
      );
    } else if (_selectedCategory == 'Mata Kuliah') {
      showAddMatkulDialog(
        context: context,
        matkulData: _matkulData,
        fakultasData: _fakultasData,
        dosenList: _dosenList,
        onAdded: (m) {
          final mKode = m['kode']?.toString() ?? '';
          final mNama = m['nama']?.toString() ?? '';
          MockDatabase.deletedMatkulIds.remove(mKode);
          MockDatabase.deletedMatkulIds.remove(mNama);
          MockDatabase.matkulData.removeWhere((item) => (item['kode']?.toString() ?? '') == mKode);
          MockDatabase.matkulData.add(m);
          MockDatabase.saveLocalMatkul();
          setState(() => _matkulData.add(m));
        },
      );
    } else if (_selectedCategory == 'Dosen Prioritas') {
      showAddDosenDialog(
        context: context,
        dosenList: _dosenList,
        fakultasData: _fakultasData,
        matkulData: _matkulData,
        priorityDosenIds: _priorityDosenIds,
        onAdded: (newDosen, isPriority) {
          setState(() {
            _dosenList.removeWhere((u) => u.id == newDosen.id || u.email == newDosen.email);
            _dosenList.add(newDosen);
            if (isPriority) {
              _priorityDosenIds.add(newDosen.id);
            }
          });
        },
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(
        backgroundColor: Color(0xFFF8FAFC),
        body: Center(
          child: CircularProgressIndicator(color: AppColors.primary),
        ),
      );
    }

    // Filter data according to search query
    final filteredGedung = _gedungList.where((g) {
      if (_searchQuery.isEmpty) return true;
      return g.nama.toLowerCase().contains(_searchQuery) ||
          g.aksesJurusan.toLowerCase().contains(_searchQuery);
    }).toList();

    final filteredFakultas = _fakultasData.where((f) {
      if (_searchQuery.isEmpty) return true;
      final matchFak = (f['nama']?.toString() ?? '').toLowerCase().contains(_searchQuery);
      final matchDekan = (f['dekan']?.toString() ?? '').toLowerCase().contains(_searchQuery);
      final rawJur = f['jurusan'];
      final matchJur = rawJur is List
          ? rawJur.any((j) => j.toString().toLowerCase().contains(_searchQuery))
          : false;
      return matchFak || matchDekan || matchJur;
    }).toList();

    final filteredMatkul = _matkulData.where((m) {
      if (_searchQuery.isEmpty) return true;
      final matchNama = (m['nama']?.toString() ?? '').toLowerCase().contains(_searchQuery);
      final matchKode = (m['kode']?.toString() ?? '').toLowerCase().contains(_searchQuery);
      final matchDosen = (m['dosen']?.toString() ?? '').toLowerCase().contains(_searchQuery);
      return matchNama || matchKode || matchDosen;
    }).toList();

    final filteredDosen = _dosenList.where((d) {
      if (_searchQuery.isEmpty) return true;
      return d.nama.toLowerCase().contains(_searchQuery) ||
          d.jurusanNama.toLowerCase().contains(_searchQuery) ||
          d.email.toLowerCase().contains(_searchQuery);
    }).toList();

    return Stack(
      children: [
        RefreshIndicator(
          onRefresh: _loadData,
          color: AppColors.primary,
          child: SingleChildScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: EdgeInsets.fromLTRB(14, 12, 14, (_isMultiSelectMode || _totalSelectedCount > 0) ? 80 : 20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
              // Header Master Data
              const MasterDataHeaderCard(),
              const SizedBox(height: 12),

              // Search Bar Modern
              Container(
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: const Color(0xFFE2E8F0)),
                ),
                child: TextField(
                  controller: _searchCtrl,
                  style: const TextStyle(fontSize: 13),
                  decoration: InputDecoration(
                    hintText: 'Cari gedung, fakultas, prodi, matkul, dosen...',
                    hintStyle: const TextStyle(fontSize: 12, color: Color(0xFF94A3B8)),
                    prefixIcon: const Icon(Icons.search_rounded, color: AppColors.primary, size: 18),
                    suffixIcon: _searchQuery.isNotEmpty
                        ? IconButton(
                            icon: const Icon(Icons.close_rounded, size: 16, color: Color(0xFF94A3B8)),
                            onPressed: () => _searchCtrl.clear(),
                          )
                        : null,
                    border: InputBorder.none,
                    isDense: true,
                    contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                  ),
                ),
              ),
              const SizedBox(height: 10),

              // Filter Kategori Dropdown
              Container(
                height: 44,
                padding: const EdgeInsets.symmetric(horizontal: 12),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: const Color(0xFFCBD5E1)),
                  boxShadow: const [
                    BoxShadow(
                      color: Color(0x04000000),
                      blurRadius: 4,
                      offset: Offset(0, 1),
                    ),
                  ],
                ),
                child: Row(
                  children: [
                    const Icon(Icons.filter_alt_outlined, size: 18, color: AppColors.primary),
                    const SizedBox(width: 8),
                    const Text(
                      'Kategori:',
                      style: TextStyle(fontSize: 12.5, fontWeight: FontWeight.bold, color: Color(0xFF64748B)),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: DropdownButtonHideUnderline(
                        child: DropdownButton<String>(
                          value: _selectedCategory,
                          isExpanded: true,
                          icon: const Icon(Icons.keyboard_arrow_down_rounded, color: Color(0xFF64748B), size: 20),
                          style: const TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF0F172A),
                          ),
                          items: const [
                            DropdownMenuItem(value: 'Semua', child: Text('Semua Data Master')),
                            DropdownMenuItem(value: 'Gedung', child: Text('Gedung Kampus')),
                            DropdownMenuItem(value: 'Fakultas & Prodi', child: Text('Fakultas & Prodi')),
                            DropdownMenuItem(value: 'Mata Kuliah', child: Text('Mata Kuliah')),
                            DropdownMenuItem(value: 'Dosen Prioritas', child: Text('Dosen Prioritas')),
                          ],
                          onChanged: (val) {
                            if (val != null) {
                              setState(() => _selectedCategory = val);
                            }
                          },
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              // Button Tambah Khusus di Bawah Filter Dropdown
              if (_selectedCategory != 'Semua') ...[
                const SizedBox(height: 8),
                SizedBox(
                  width: double.infinity,
                  height: 42,
                  child: ElevatedButton(
                    onPressed: _triggerAddForCurrentCategory,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primary,
                      elevation: 0,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                    child: const Text(
                      '+ Tambah',
                      style: TextStyle(
                        fontSize: 13.5,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                        letterSpacing: 0.3,
                      ),
                    ),
                  ),
                ),
              ],
              const SizedBox(height: 14),

                // ── SECTION 1: MASTER GEDUNG ──
                if (_selectedCategory == 'Semua' || _selectedCategory == 'Gedung') ...[
                  MasterDataSectionHeader(
                    title: 'Gedung Kampus',
                    icon: Icons.apartment_rounded,
                    iconColor: AppColors.primary,
                    onAdd: () => showAddGedungDialog(
                      context: context,
                      gedungList: _gedungList,
                      onAdded: (g) async {
                        final api = context.read<ApiService>();
                        await api.addGedung(g);
                        await MockDatabase.saveLocalGedung();
                        if (mounted) {
                          setState(() {
                            if (!_gedungList.any((item) => item.id == g.id)) {
                              _gedungList.add(g);
                            }
                          });
                        }
                      },
                    ),
                    addButtonText: 'Tambah Gedung',
                    showAddButton: _selectedCategory == 'Semua',
                  ),
                  const SizedBox(height: 6),
                  if (filteredGedung.isEmpty)
                    MasterDataEmptyState(
                      message: _searchQuery.isEmpty
                          ? 'Belum ada data gedung kampus.'
                          : 'Tidak ada gedung yang cocok dengan pencarian.',
                      onAdd: () => showAddGedungDialog(
                        context: context,
                        gedungList: _gedungList,
                        onAdded: (g) async {
                          final api = context.read<ApiService>();
                          await api.addGedung(g);
                          await MockDatabase.saveLocalGedung();
                          if (mounted) {
                            setState(() {
                              _gedungList.removeWhere((item) => item.id == g.id);
                              _gedungList.add(g);
                            });
                          }
                        },
                      ),
                      addLabel: 'Tambah Gedung',
                    )
                  else
                    GedungMasterList(
                      list: filteredGedung,
                      selectedGedungIds: _selectedGedungIds,
                      isMultiSelectMode: _isMultiSelectMode,
                      totalSelectedCount: _totalSelectedCount,
                      limit: (_selectedCategory == 'Semua' && !_expandGedung) ? 3 : null,
                      isCompact: _selectedCategory == 'Semua',
                      onRuanganUpdated: () {
                        setState(() {});
                        _syncGlobalData();
                      },
                      onToggleSelect: (id) {
                        setState(() {
                          if (_selectedGedungIds.contains(id)) {
                            _selectedGedungIds.remove(id);
                            if (_totalSelectedCount == 0) _isMultiSelectMode = false;
                          } else {
                            _selectedGedungIds.add(id);
                          }
                        });
                      },
                      onEdit: (g) => showEditGedungDialog(
                        context: context,
                        gedung: g,
                        onSaved: (updated) {
                          setState(() {
                            final idx = _gedungList.indexWhere((item) => item.id == g.id);
                            if (idx != -1) _gedungList[idx] = updated;
                            final dbIdx = MockDatabase.gedungList.indexWhere((item) => item.id == g.id);
                            if (dbIdx != -1) MockDatabase.gedungList[dbIdx] = updated;
                          });
                          MockDatabase.saveLocalGedung();
                        },
                      ),
                      onDelete: (g) {
                        confirmDeleteData(
                          context: context,
                          title: g.nama,
                          category: 'Gedung',
                          onConfirm: () async {
                            final api = context.read<ApiService>();
                            await api.deleteGedung(g.id);
                            setState(() {
                              _gedungList.removeWhere((item) => item.id == g.id);
                              MockDatabase.gedungList.removeWhere((item) => item.id == g.id);
                              _selectedGedungIds.remove(g.id);
                            });
                            _syncGlobalData();
                            if (!context.mounted) return;
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text('Gedung ${g.nama} berhasil dihapus!'),
                                backgroundColor: const Color(0xFFEF4444),
                                behavior: SnackBarBehavior.floating,
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                              ),
                            );
                          },
                        );
                      },
                      onBatchDelete: (id) {
                        setState(() {
                          _isMultiSelectMode = true;
                          _selectedGedungIds.add(id);
                        });
                      },
                    ),
                  if (_selectedCategory == 'Semua' && filteredGedung.length > 3)
                    MasterDataExpandToggle(
                      isExpanded: _expandGedung,
                      onToggle: () => setState(() => _expandGedung = !_expandGedung),
                    ),
                  const SizedBox(height: 14),
                ],

                // ── SECTION 2: FAKULTAS & JURUSAN ──
                if (_selectedCategory == 'Semua' || _selectedCategory == 'Fakultas & Prodi') ...[
                  MasterDataSectionHeader(
                    title: 'Fakultas & Prodi',
                    icon: Icons.account_balance_outlined,
                    iconColor: AppColors.primary,
                    onAdd: () => showAddFakultasDialog(
                      context: context,
                      fakultasData: _fakultasData,
                      gedungList: _gedungList,
                      onAdded: (f) {
                        MockDatabase.fakultasData.add(f);
                        MockDatabase.saveLocalFakultas();
                        setState(() => _fakultasData.add(f));
                      },
                    ),
                    addButtonText: 'Tambah Fakultas',
                    showAddButton: _selectedCategory == 'Semua',
                  ),
                  const SizedBox(height: 6),
                  if (filteredFakultas.isEmpty)
                    MasterDataEmptyState(
                      message: _searchQuery.isEmpty
                          ? 'Belum ada data fakultas & prodi.'
                          : 'Tidak ada fakultas yang cocok dengan pencarian.',
                      onAdd: () => showAddFakultasDialog(
                        context: context,
                        fakultasData: _fakultasData,
                        gedungList: _gedungList,
                        onAdded: (f) {
                          MockDatabase.fakultasData.add(f);
                          MockDatabase.saveLocalFakultas();
                          setState(() => _fakultasData.add(f));
                        },
                      ),
                      addLabel: 'Tambah Fakultas',
                    )
                  else
                    FakultasMasterList(
                      list: filteredFakultas,
                      selectedFakultasIds: _selectedFakultasIds,
                      isMultiSelectMode: _isMultiSelectMode,
                      totalSelectedCount: _totalSelectedCount,
                      limit: (_selectedCategory == 'Semua' && !_expandFakultas) ? 2 : null,
                      isCompact: _selectedCategory == 'Semua',
                      onToggleSelect: (id) {
                        setState(() {
                          if (_selectedFakultasIds.contains(id)) {
                            _selectedFakultasIds.remove(id);
                            if (_totalSelectedCount == 0) _isMultiSelectMode = false;
                          } else {
                            _selectedFakultasIds.add(id);
                          }
                        });
                      },
                      onEdit: (f) => showEditFakultasDialog(
                        context: context,
                        fakultas: f,
                        gedungList: _gedungList,
                        onSaved: (updated) {
                          setState(() {
                            final key = (f['id'] ?? f['nama'])?.toString() ?? '';
                            final idx = _fakultasData.indexWhere((item) => ((item['id'] ?? item['nama'])?.toString() ?? '') == key);
                            if (idx != -1) _fakultasData[idx] = updated;
                            final dbIdx = MockDatabase.fakultasData.indexWhere((item) => ((item['id'] ?? item['nama'])?.toString() ?? '') == key);
                            if (dbIdx != -1) MockDatabase.fakultasData[dbIdx] = updated;
                          });
                          MockDatabase.saveLocalFakultas();
                        },
                      ),
                      onDelete: (f) {
                        final fNama = f['nama']?.toString() ?? 'Fakultas';
                        final fKey = (f['id'] ?? f['nama'])?.toString() ?? '';
                        final rawJur = f['jurusan'];
                        final List<String> fJur = rawJur is List
                            ? rawJur.map((e) => e.toString()).toList()
                            : <String>[];
                        confirmDeleteData(
                          context: context,
                          title: fNama,
                          category: 'Fakultas',
                          onConfirm: () async {
                            await MockDatabase.cascadeDeleteFakultas(fKey, fNama, fJur);
                            setState(() {
                              _fakultasData.removeWhere((item) => ((item['id'] ?? item['nama'])?.toString() ?? '') == fKey);
                              _matkulData.removeWhere((m) {
                                final mFak = (m['fakultas'] ?? '').toString();
                                return mFak.toLowerCase() == fNama.toLowerCase();
                              });
                              _selectedFakultasIds.remove(fKey);
                            });
                            _syncGlobalData();
                            if (!context.mounted) return;
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text('Fakultas $fNama dan seluruh prodi/matkul/jadwal terkait berhasil dihapus!'),
                                backgroundColor: const Color(0xFFEF4444),
                                behavior: SnackBarBehavior.floating,
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                              ),
                            );
                          },
                        );
                      },
                      onBatchDelete: (id) {
                        setState(() {
                          _isMultiSelectMode = true;
                          _selectedFakultasIds.add(id);
                        });
                      },
                    ),
                  if (_selectedCategory == 'Semua' && filteredFakultas.length > 2)
                    MasterDataExpandToggle(
                      isExpanded: _expandFakultas,
                      onToggle: () => setState(() => _expandFakultas = !_expandFakultas),
                    ),
                  const SizedBox(height: 14),
                ],

                // ── SECTION 3: MATA KULIAH & KELAS ──
                if (_selectedCategory == 'Semua' || _selectedCategory == 'Mata Kuliah') ...[
                  MasterDataSectionHeader(
                    title: 'Mata Kuliah',
                    icon: Icons.menu_book_rounded,
                    iconColor: AppColors.primary,
                    onAdd: () => showAddMatkulDialog(
                      context: context,
                      matkulData: _matkulData,
                      fakultasData: _fakultasData,
                      dosenList: _dosenList,
                      onAdded: (m) {
                        MockDatabase.matkulData.add(m);
                        MockDatabase.saveLocalMatkul();
                        setState(() => _matkulData.add(m));
                      },
                    ),
                    addButtonText: 'Tambah Matkul',
                    showAddButton: _selectedCategory == 'Semua',
                  ),
                  const SizedBox(height: 6),
                  if (filteredMatkul.isEmpty)
                    MasterDataEmptyState(
                      message: _searchQuery.isEmpty
                          ? 'Belum ada data mata kuliah.'
                          : 'Tidak ada mata kuliah yang cocok dengan pencarian.',
                      onAdd: () => showAddMatkulDialog(
                        context: context,
                        matkulData: _matkulData,
                        fakultasData: _fakultasData,
                        dosenList: _dosenList,
                        onAdded: (m) {
                          MockDatabase.matkulData.add(m);
                          MockDatabase.saveLocalMatkul();
                          setState(() => _matkulData.add(m));
                        },
                      ),
                      addLabel: 'Tambah Matkul',
                    )
                  else
                    MatkulMasterList(
                      list: filteredMatkul,
                      selectedMatkulIds: _selectedMatkulIds,
                      isMultiSelectMode: _isMultiSelectMode,
                      totalSelectedCount: _totalSelectedCount,
                      limit: (_selectedCategory == 'Semua' && !_expandMatkul) ? 3 : null,
                      isCompact: _selectedCategory == 'Semua',
                      onToggleSelect: (id) {
                        setState(() {
                          if (_selectedMatkulIds.contains(id)) {
                            _selectedMatkulIds.remove(id);
                            if (_totalSelectedCount == 0) _isMultiSelectMode = false;
                          } else {
                            _selectedMatkulIds.add(id);
                          }
                        });
                      },
                      onEdit: (m) => showEditMatkulDialog(
                        context: context,
                        matkul: m,
                        fakultasData: _fakultasData,
                        dosenList: _dosenList,
                        onSaved: (updated) {
                          setState(() {
                            final kode = (m['kode'] ?? '')?.toString() ?? '';
                            final idx = _matkulData.indexWhere((item) => (item['kode']?.toString() ?? '') == kode);
                            if (idx != -1) _matkulData[idx] = updated;
                            final dbIdx = MockDatabase.matkulData.indexWhere((item) => (item['kode']?.toString() ?? '') == kode);
                            if (dbIdx != -1) MockDatabase.matkulData[dbIdx] = updated;
                          });
                          MockDatabase.saveLocalMatkul();
                        },
                      ),
                      onDelete: (m) {
                        final mNama = m['nama']?.toString() ?? 'Mata Kuliah';
                        final mKode = m['kode']?.toString() ?? '';
                        confirmDeleteData(
                          context: context,
                          title: '$mNama ($mKode)',
                          category: 'Mata Kuliah',
                          onConfirm: () async {
                            await MockDatabase.cascadeDeleteMatkul(mKode, mNama);
                            setState(() {
                              _matkulData.removeWhere((item) => (item['kode']?.toString() ?? '') == mKode);
                              _selectedMatkulIds.remove(mKode);
                            });
                            _syncGlobalData();
                            if (!context.mounted) return;
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text('Mata Kuliah $mNama dan seluruh jadwal terkait berhasil dihapus!'),
                                backgroundColor: const Color(0xFFEF4444),
                                behavior: SnackBarBehavior.floating,
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                              ),
                            );
                          },
                        );
                      },
                      onBatchDelete: (id) {
                        setState(() {
                          _isMultiSelectMode = true;
                          _selectedMatkulIds.add(id);
                        });
                      },
                    ),
                  if (_selectedCategory == 'Semua' && filteredMatkul.length > 3)
                    MasterDataExpandToggle(
                      isExpanded: _expandMatkul,
                      onToggle: () => setState(() => _expandMatkul = !_expandMatkul),
                    ),
                  const SizedBox(height: 14),
                ],

                // ── SECTION 4: DOSEN & PRIORITAS PENJADWALAN (MRV) ──
                if (_selectedCategory == 'Semua' || _selectedCategory == 'Dosen Prioritas') ...[
                  MasterDataSectionHeader(
                    title: 'Dosen & Prioritas MRV',
                    icon: Icons.people_outline_rounded,
                    iconColor: const Color(0xFF0284C7),
                    onAdd: () => showAddDosenDialog(
                      context: context,
                      dosenList: _dosenList,
                      fakultasData: _fakultasData,
                      matkulData: _matkulData,
                      priorityDosenIds: _priorityDosenIds,
                      onAdded: (newDosen, isPriority) {
                        setState(() {
                          _dosenList.removeWhere((u) => u.id == newDosen.id || u.email == newDosen.email);
                          _dosenList.add(newDosen);
                          if (isPriority) {
                            _priorityDosenIds.add(newDosen.id);
                          }
                        });
                      },
                    ),
                    addButtonText: 'Tambah Dosen',
                    showAddButton: _selectedCategory == 'Semua',
                  ),
                  const SizedBox(height: 6),
                  if (filteredDosen.isEmpty)
                    MasterDataEmptyState(
                      message: _searchQuery.isEmpty
                          ? 'Belum ada data dosen.'
                          : 'Tidak ada dosen yang cocok dengan pencarian.',
                      onAdd: () => showAddDosenDialog(
                        context: context,
                        dosenList: _dosenList,
                        fakultasData: _fakultasData,
                        matkulData: _matkulData,
                        priorityDosenIds: _priorityDosenIds,
                        onAdded: (newDosen, isPriority) {
                          setState(() {
                            _dosenList.removeWhere((u) => u.id == newDosen.id || u.email == newDosen.email);
                            _dosenList.add(newDosen);
                            if (isPriority) {
                              _priorityDosenIds.add(newDosen.id);
                            }
                          });
                        },
                      ),
                      addLabel: 'Tambah Dosen',
                    )
                  else
                    DosenMasterList(
                      list: filteredDosen,
                      priorityDosenIds: _priorityDosenIds,
                      selectedDosenIds: _selectedDosenIds,
                      isMultiSelectMode: _isMultiSelectMode,
                      totalSelectedCount: _totalSelectedCount,
                      limit: (_selectedCategory == 'Semua' && !_expandDosen) ? 4 : null,
                      isCompact: _selectedCategory == 'Semua',
                      onToggleSelect: (id) {
                        setState(() {
                          if (_selectedDosenIds.contains(id)) {
                            _selectedDosenIds.remove(id);
                            if (_totalSelectedCount == 0) _isMultiSelectMode = false;
                          } else {
                            _selectedDosenIds.add(id);
                          }
                        });
                      },
                      onTogglePriority: _toggleDosenPriority,
                      onEdit: (d) => showEditDosenDialog(
                        context: context,
                        dosen: d,
                        dosenList: _dosenList,
                        fakultasData: _fakultasData,
                        matkulData: _matkulData,
                        priorityDosenIds: _priorityDosenIds,
                        onSaved: (updated, isPriority) {
                          setState(() {
                            final idx = _dosenList.indexWhere((item) => item.id == d.id || item.email == d.email);
                            if (idx != -1) {
                              _dosenList[idx] = updated;
                            } else {
                              _dosenList.add(updated);
                            }
                            if (isPriority) {
                              _priorityDosenIds.add(updated.id);
                            } else {
                              _priorityDosenIds.remove(updated.id);
                            }
                          });
                        },
                      ),
                      onDelete: (d) {
                        confirmDeleteData(
                          context: context,
                          title: d.nama,
                          category: 'Dosen',
                          onConfirm: () async {
                            final api = context.read<ApiService>();
                            await api.deleteUser(d.id);
                            setState(() {
                              _dosenList.removeWhere((item) => item.id == d.id);
                              _priorityDosenIds.remove(d.id);
                              _selectedDosenIds.remove(d.id);
                              _matkulData.removeWhere((m) {
                                final mDid = (m['dosenId'] ?? '').toString();
                                return mDid == d.id;
                              });
                            });
                            _syncGlobalData();
                            if (!context.mounted) return;
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text('Dosen ${d.nama} dan seluruh jadwal terkait berhasil dihapus!'),
                                backgroundColor: const Color(0xFFEF4444),
                                behavior: SnackBarBehavior.floating,
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                              ),
                            );
                          },
                        );
                      },
                      onBatchDelete: (id) {
                        setState(() {
                          _isMultiSelectMode = true;
                          _selectedDosenIds.add(id);
                        });
                      },
                    ),
                  if (_selectedCategory == 'Semua' && filteredDosen.length > 4)
                    MasterDataExpandToggle(
                      isExpanded: _expandDosen,
                      onToggle: () => setState(() => _expandDosen = !_expandDosen),
                    ),
                  const SizedBox(height: 20),
                ],
              ],
            ),
          ),
        ),
        if (_isMultiSelectMode || _totalSelectedCount > 0)
          MasterDataMultiSelectBar(
            totalSelectedCount: _totalSelectedCount,
            onCancel: () {
              setState(() {
                _isMultiSelectMode = false;
                _selectedGedungIds.clear();
                _selectedFakultasIds.clear();
                _selectedMatkulIds.clear();
                _selectedDosenIds.clear();
              });
            },
            onDelete: _confirmBatchDelete,
          ),
      ],
    );
  }
}
