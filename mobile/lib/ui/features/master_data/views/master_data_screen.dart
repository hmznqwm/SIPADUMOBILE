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
import '../../auth/view_models/auth_view_model.dart';
import '../../availability/view_models/availability_view_model.dart';
import '../../dashboard/view_models/dashboard_view_model.dart';
import '../../schedule/view_models/schedule_view_model.dart';
import '../widgets/dosen_master_tab.dart';
import '../widgets/fakultas_master_tab.dart';
import '../widgets/gedung_master_tab.dart';
import '../widgets/master_data_dialogs.dart';
import '../widgets/master_data_filter_bar.dart';
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
  String _matkulSemesterFilter = 'Semua';
  String _selectedFakultas = 'Semua Fakultas';
  String _selectedProdi = 'Semua Prodi';

  bool _matchFakultas(String? a, String? b) {
    final na = (a ?? '')
        .toLowerCase()
        .replaceAll('&', 'dan')
        .replaceAll(RegExp(r'\s+'), ' ')
        .trim();
    final nb = (b ?? '')
        .toLowerCase()
        .replaceAll('&', 'dan')
        .replaceAll(RegExp(r'\s+'), ' ')
        .trim();
    if (na.isEmpty || nb.isEmpty) return false;
    return na.contains(nb) || nb.contains(na);
  }

  bool _matchProdi(String? a, String? b) {
    final na = (a ?? '').toLowerCase().trim();
    final nb = (b ?? '').toLowerCase().trim();
    if (na.isEmpty || nb.isEmpty) return false;
    return na.contains(nb) || nb.contains(na);
  }

  List<String> _getCategoriesForRole(String role) {
    if (role == 'admin') {
      return const [
        'Semua',
        'Gedung',
        'Fakultas & Prodi',
        'Mata Kuliah',
        'Data Dosen',
      ];
    }
    return const ['Mata Kuliah', 'Data Dosen'];
  }

  // Per-section pagination limits: default 10 items for all roles
  int _limitGedung = 10;
  int _limitFakultas = 10;
  int _limitMatkul = 10;
  int _limitDosen = 10;

  bool _isLoading = true;
  List<GedungModel> _gedungList = [];
  List<UserModel> _dosenList = [];
  final Set<String> _priorityDosenIds = {};

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

  void _resetLimits() {
    _limitGedung = 10;
    _limitFakultas = 10;
    _limitMatkul = 10;
    _limitDosen = 10;
  }

  void _setCategory(String cat) {
    setState(() {
      _selectedCategory = cat;
      _isMultiSelectMode = false;
      _selectedGedungIds.clear();
      _selectedFakultasIds.clear();
      _selectedMatkulIds.clear();
      _selectedDosenIds.clear();
      _resetLimits();
    });
  }

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
        _resetLimits();
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

    // Ensure local cache (including deleted IDs) is loaded before fetching any data
    await MockDatabase.initLocalCache();

    try {
      final gedung = await api.getGedungList();
      for (final g in gedung) {
        MockDatabase.gedungList.removeWhere(
          (item) =>
              item.id == g.id ||
              item.nama.toLowerCase() == g.nama.toLowerCase(),
        );
        MockDatabase.gedungList.add(g);
      }
      await MockDatabase.saveLocalGedung();

      final ruangan = await api.getRuanganList();
      for (final r in ruangan) {
        MockDatabase.ruanganList.removeWhere(
          (item) =>
              item.id == r.id ||
              (item.nama.toLowerCase() == r.nama.toLowerCase() &&
                  (item.gedungId == r.gedungId ||
                      item.gedungNama.toLowerCase() ==
                          r.gedungNama.toLowerCase())),
        );
        MockDatabase.ruanganList.add(r);
      }
      await MockDatabase.saveLocalRuangan();
      final users = await api.getAllUsers();
      final matkulList = await api.getAllMataKuliah();
      final fakultasList = await api.getFakultasList();
      
      // Strict filter: Exclude super admin & admin accounts from Master Data
      final nonAdminUsers = users.where((u) {
        final r = u.role.toLowerCase().replaceAll(' ', '_');
        return r != 'admin' && r != 'super_admin' && r != 'superadmin' && r != 'super_admin_role';
      }).toList();

      final dosen = nonAdminUsers
          .where(
            (u) => u.role == 'dosen' || u.role == 'kajur' || u.role == 'dekan',
          )
          .toList();

      List<Map<String, dynamic>> finalFakultas = [];

      if (fakultasList.isNotEmpty) {
        finalFakultas = List<Map<String, dynamic>>.from(fakultasList);

        // Supplement jurusan from non-admin users and matkul if any missing
        for (final u in nonAdminUsers) {
          final fNama = u.fakultasNama.trim();
          final jNama = u.jurusanNama.trim();
          if (fNama.isNotEmpty && jNama.isNotEmpty) {
            final idx = finalFakultas.indexWhere(
              (f) =>
                  (f['nama']?.toString() ?? '').toLowerCase() ==
                  fNama.toLowerCase(),
            );
            if (idx != -1) {
              final jurList = List<String>.from(
                finalFakultas[idx]['jurusan'] as List? ?? [],
              );
              if (!jurList.any((j) => j.toLowerCase() == jNama.toLowerCase())) {
                jurList.add(jNama);
                finalFakultas[idx]['jurusan'] = jurList;
              }
            }
          }
        }
      } else {
        // Fallback dynamic extraction if table is empty
        final Map<String, Set<String>> fakultasMap = {};
        for (final u in nonAdminUsers) {
          final f = u.fakultasNama.trim();
          final j = u.jurusanNama.trim();
          if (f.isNotEmpty) {
            fakultasMap.putIfAbsent(f, () => <String>{});
            if (j.isNotEmpty) fakultasMap[f]!.add(j);
          }
        }
        for (final m in matkulList) {
          final f = m.fakultasNama.trim();
          final j = m.jurusanNama.trim();
          if (f.isNotEmpty) {
            fakultasMap.putIfAbsent(f, () => <String>{});
            if (j.isNotEmpty) fakultasMap[f]!.add(j);
          }
        }

        int fIdx = 1;
        fakultasMap.forEach((fNama, jSet) {
          finalFakultas.add({
            'id': 'FAK_$fIdx',
            'nama': fNama,
            'dekan': '-',
            'gedung': '-',
            'jurusan': jSet.toList(),
          });
          fIdx++;
        });
      }

      final List<Map<String, dynamic>> dynamicMatkul = matkulList.map((m) {
        final dObj = dosen.where((d) => d.id == m.dosenId).firstOrNull;
        final resolvedDosenNama =
            (m.dosenNama != null && m.dosenNama!.isNotEmpty)
            ? m.dosenNama!
            : (dObj?.nama ?? (m.dosenId.isNotEmpty ? m.dosenId : '-'));
        return {
          'id': m.id,
          'kode': m.id,
          'nama': m.nama,
          'sks': m.sks,
          'semester': m.semester,
          'semester_angka': m.semester,
          'semesterId': m.semesterId,
          'fakultas': m.fakultasNama,
          'jurusan': m.jurusanNama,
          'dosenId': m.dosenId,
          'dosen': resolvedDosenNama,
          'kelas': m.kelasNama,
        };
      }).toList();

      if (mounted) {
        setState(() {
          _gedungList = List.from(gedung);
          _dosenList = List.from(dosen);
          _priorityDosenIds.clear();
          for (final d in dosen) {
            if (d.isPriority) {
              _priorityDosenIds.add(d.id);
            }
          }
          _fakultasData.clear();
          _fakultasData.addAll(finalFakultas);
          _matkulData.clear();
          _matkulData.addAll(dynamicMatkul);
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

  Future<void> _toggleDosenPriority(
    String dosenId,
    bool currentPriority,
  ) async {
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
          backgroundColor: newPriority
              ? AppColors.primary
              : const Color(0xFF334155),
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
          await api.deleteFakultas(id);
        }

        // 3. Cascade delete all selected Matkul
        for (var id in _selectedMatkulIds) {
          await MockDatabase.cascadeDeleteMatkul(id);
          await api.deleteMataKuliah(id);
        }

        // 4. Cascade delete all selected Dosen
        for (var id in _selectedDosenIds) {
          await api.deleteUser(id);
        }

        setState(() {
          _gedungList.removeWhere((g) => _selectedGedungIds.contains(g.id));
          _fakultasData.removeWhere(
            (f) => _selectedFakultasIds.contains(
              (f['id'] ?? f['nama'])?.toString(),
            ),
          );
          _matkulData.removeWhere(
            (m) => _selectedMatkulIds.contains(m['kode']?.toString()),
          );
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
            content: Text(
              'Berhasil menghapus $count data master dan seluruh jadwal/ruangan terkait!',
            ),
            backgroundColor: const Color(0xFFEF4444),
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8),
            ),
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

  void _triggerAddForCurrentCategory(UserModel? currentUser) {
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
        dosenList: _dosenList,
        onAdded: (f) async {
          final fKey = f['id']?.toString() ?? '';
          final fNama = f['nama']?.toString() ?? '';
          MockDatabase.deletedFakultasIds.remove(fKey);
          MockDatabase.deletedFakultasIds.remove(fNama);
          MockDatabase.fakultasData.removeWhere(
            (item) => ((item['id'] ?? item['nama'])?.toString() ?? '') == fKey,
          );
          MockDatabase.fakultasData.add(f);
          MockDatabase.saveLocalFakultas();
          setState(() => _fakultasData.add(f));
          await api.saveFakultas(f);
        },
      );
    } else if (_selectedCategory == 'Mata Kuliah') {
      showAddMatkulDialog(
        context: context,
        matkulData: _matkulData,
        fakultasData: _fakultasData,
        dosenList: _dosenList,
        currentUser: currentUser,
        onAdded: (m) async {
          final mKode = m['kode']?.toString() ?? '';
          final mNama = m['nama']?.toString() ?? '';
          MockDatabase.deletedMatkulIds.remove(mKode);
          MockDatabase.deletedMatkulIds.remove(mNama);
          MockDatabase.matkulData.removeWhere(
            (item) => (item['kode']?.toString() ?? '') == mKode,
          );
          MockDatabase.matkulData.add(m);
          await MockDatabase.saveLocalMatkul();
          setState(() => _matkulData.add(m));
          await api.saveMataKuliah(m);
          _syncGlobalData();
        },
      );
    } else if (_selectedCategory == 'Dosen Prioritas' ||
        _selectedCategory == 'Data Dosen') {
      showAddDosenDialog(
        context: context,
        dosenList: _dosenList,
        fakultasData: _fakultasData,
        matkulData: _matkulData,
        priorityDosenIds: _priorityDosenIds,
        currentUser: currentUser,
        onAdded: (newDosen, isPriority) {
          setState(() {
            _dosenList.removeWhere(
              (u) => u.id == newDosen.id || u.email == newDosen.email,
            );
            _dosenList.add(newDosen);
            if (isPriority) {
              _priorityDosenIds.add(newDosen.id);
            }
          });
          _syncGlobalData();
        },
      );
    }
  }

  void _showAdminAddDataBottomSheet(UserModel? currentUser) {
    final api = context.read<ApiService>();
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Drag handle
                Center(
                  child: Container(
                    width: 38,
                    height: 4,
                    decoration: BoxDecoration(
                      color: const Color(0xFFCBD5E1),
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ),
                const SizedBox(height: 16),

                // Header
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Tambah Master Data',
                          style: TextStyle(
                            fontSize: 17,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF0F172A),
                            letterSpacing: -0.2,
                          ),
                        ),
                        SizedBox(height: 2),
                        Text(
                          'Pilih kategori data yang ingin ditambahkan',
                          style: TextStyle(
                            fontSize: 12,
                            color: Color(0xFF64748B),
                          ),
                        ),
                      ],
                    ),
                    IconButton(
                      onPressed: () => Navigator.pop(ctx),
                      icon: const Icon(
                        Icons.close_rounded,
                        color: Color(0xFF94A3B8),
                        size: 20,
                      ),
                      padding: EdgeInsets.zero,
                      constraints: const BoxConstraints(),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                const Divider(height: 1, color: Color(0xFFF1F5F9)),
                const SizedBox(height: 12),

                // Options List
                _buildAddDataOptionItem(
                  title: 'Gedung & Ruangan',
                  subtitle: 'Tambah gedung baru beserta daftar ruang kuliah',
                  color: AppColors.primary,
                  onTap: () {
                    Navigator.pop(ctx);
                    showAddGedungDialog(
                      context: context,
                      gedungList: _gedungList,
                      onAdded: (g) async {
                        await api.addGedung(g);
                        await MockDatabase.saveLocalGedung();
                        if (mounted) {
                          setState(() {
                            _gedungList.removeWhere((item) => item.id == g.id);
                            _gedungList.add(g);
                          });
                        }
                      },
                    );
                  },
                ),
                const SizedBox(height: 10),
                _buildAddDataOptionItem(
                  title: 'Fakultas & Program Studi',
                  subtitle: 'Tambah fakultas dan daftar jurusan / prodi',
                  color: const Color(0xFF2563EB),
                  onTap: () {
                    Navigator.pop(ctx);
                    showAddFakultasDialog(
                      context: context,
                      fakultasData: _fakultasData,
                      gedungList: _gedungList,
                      dosenList: _dosenList,
                      onAdded: (f) async {
                        final fKey = f['id']?.toString() ?? '';
                        final fNama = f['nama']?.toString() ?? '';
                        MockDatabase.deletedFakultasIds.remove(fKey);
                        MockDatabase.deletedFakultasIds.remove(fNama);
                        MockDatabase.fakultasData.removeWhere(
                          (item) =>
                              ((item['id'] ?? item['nama'])?.toString() ??
                                  '') ==
                              fKey,
                        );
                        MockDatabase.fakultasData.add(f);
                        MockDatabase.saveLocalFakultas();
                        setState(() => _fakultasData.add(f));
                        await api.saveFakultas(f);
                      },
                    );
                  },
                ),
                const SizedBox(height: 10),
                _buildAddDataOptionItem(
                  title: 'Mata Kuliah',
                  subtitle: 'Tambah mata kuliah, SKS, semester, dan kelas',
                  color: const Color(0xFFD97706),
                  onTap: () {
                    Navigator.pop(ctx);
                    showAddMatkulDialog(
                      context: context,
                      matkulData: _matkulData,
                      fakultasData: _fakultasData,
                      dosenList: _dosenList,
                      currentUser: currentUser,
                      onAdded: (m) async {
                        final mKode = m['kode']?.toString() ?? '';
                        final mNama = m['nama']?.toString() ?? '';
                        MockDatabase.deletedMatkulIds.remove(mKode);
                        MockDatabase.deletedMatkulIds.remove(mNama);
                        MockDatabase.matkulData.removeWhere(
                          (item) => (item['kode']?.toString() ?? '') == mKode,
                        );
                        MockDatabase.matkulData.add(m);
                        await MockDatabase.saveLocalMatkul();
                        setState(() => _matkulData.add(m));
                        await api.saveMataKuliah(m);
                        _syncGlobalData();
                      },
                    );
                  },
                ),
                const SizedBox(height: 10),
                _buildAddDataOptionItem(
                  title: 'Data Dosen',
                  subtitle: 'Tambah dosen pengampu dan prioritas MRV',
                  color: const Color(0xFF7C3AED),
                  onTap: () {
                    Navigator.pop(ctx);
                    showAddDosenDialog(
                      context: context,
                      dosenList: _dosenList,
                      fakultasData: _fakultasData,
                      matkulData: _matkulData,
                      priorityDosenIds: _priorityDosenIds,
                      currentUser: currentUser,
                      onAdded: (newDosen, isPriority) {
                        setState(() {
                          _dosenList.removeWhere(
                            (u) =>
                                u.id == newDosen.id ||
                                u.email == newDosen.email,
                          );
                          _dosenList.add(newDosen);
                          if (isPriority) {
                            _priorityDosenIds.add(newDosen.id);
                          }
                        });
                        _syncGlobalData();
                      },
                    );
                  },
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildAddDataOptionItem({
    required String title,
    required String subtitle,
    required Color color,
    required VoidCallback onTap,
  }) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
          decoration: BoxDecoration(
            color: const Color(0xFFF8FAFC),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: const Color(0xFFE2E8F0)),
          ),
          child: Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: const TextStyle(
                        fontSize: 13.5,
                        fontWeight: FontWeight.w700,
                        color: Color(0xFF0F172A),
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      subtitle,
                      style: const TextStyle(
                        fontSize: 11.5,
                        color: Color(0xFF64748B),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final api = context.read<ApiService>();
    final currentUser = context.watch<AuthViewModel>().currentUser;
    final role = currentUser?.role ?? 'admin';
    final isAdmin = role == 'admin';
    final isDekan = role == 'dekan';
    final isKaProdi = role == 'kajur';
    final categories = _getCategoriesForRole(role);

    if (!categories.contains(_selectedCategory)) {
      _selectedCategory = categories.isNotEmpty ? categories.first : 'Semua';
    }

    if (_isLoading) {
      return const Scaffold(
        backgroundColor: Color(0xFFF8FAFC),
        body: Center(
          child: CircularProgressIndicator(color: AppColors.primary),
        ),
      );
    }

    // List of prodis under dekan's fakultas
    final Set<String> dekanProdis = {};
    if (isDekan && currentUser != null) {
      for (final f in _fakultasData) {
        if (_matchFakultas(f['nama']?.toString(), currentUser.fakultasNama)) {
          final jur = f['jurusan'];
          if (jur is List) {
            for (final j in jur) {
              dekanProdis.add(j.toString().toLowerCase().trim());
            }
          }
        }
      }
    }

    // Build available fakultas and prodi map dynamically
    final List<String> availableFakultas = ['Semua Fakultas'];
    final Map<String, List<String>> fakultasToProdiMap = {};

    for (final f in _fakultasData) {
      final fNama = f['nama']?.toString().trim() ?? '';
      if (fNama.isNotEmpty && !availableFakultas.contains(fNama)) {
        availableFakultas.add(fNama);
      }
      final rawJur = f['jurusan'];
      final List<String> jurList = [];
      if (rawJur is List) {
        for (final j in rawJur) {
          final jStr = j.toString().trim();
          if (jStr.isNotEmpty && !jurList.contains(jStr)) {
            jurList.add(jStr);
          }
        }
      }
      if (fNama.isNotEmpty) {
        fakultasToProdiMap[fNama] = jurList;
      }
    }

    // Filter data according to scope, category, dropdown filters, and search query
    final filteredGedung = isAdmin
        ? _gedungList.where((g) {
            // 1. Dropdown Filter: Fakultas & Prodi
            if (_selectedFakultas != 'Semua Fakultas') {
              final matchFakultasInAkses = _matchFakultas(
                g.aksesJurusan,
                _selectedFakultas,
              );
              final matchAksesSemua = g.aksesJurusan.toLowerCase().contains(
                'semua',
              );
              final isAssociatedFakultas = _fakultasData.any(
                (f) =>
                    _matchFakultas(f['nama']?.toString(), _selectedFakultas) &&
                    (f['gedung']?.toString().toLowerCase() ==
                        g.nama.toLowerCase()),
              );
              if (!matchFakultasInAkses &&
                  !matchAksesSemua &&
                  !isAssociatedFakultas) {
                return false;
              }
            }
            if (_selectedProdi != 'Semua Prodi') {
              final matchProdiInAkses = _matchProdi(
                g.aksesJurusan,
                _selectedProdi,
              );
              final matchAksesSemua = g.aksesJurusan.toLowerCase().contains(
                'semua',
              );
              if (!matchProdiInAkses && !matchAksesSemua) {
                return false;
              }
            }

            // 2. Search Query
            if (_searchQuery.isEmpty) return true;
            return g.nama.toLowerCase().contains(_searchQuery) ||
                g.aksesJurusan.toLowerCase().contains(_searchQuery);
          }).toList()
        : <GedungModel>[];

    final filteredFakultas = isAdmin
        ? _fakultasData.where((f) {
            // 1. Dropdown Filter: Fakultas & Prodi
            if (_selectedFakultas != 'Semua Fakultas') {
              if (!_matchFakultas(f['nama']?.toString(), _selectedFakultas)) {
                return false;
              }
            }
            if (_selectedProdi != 'Semua Prodi') {
              final rawJur = f['jurusan'];
              final matchProdi =
                  rawJur is List &&
                  rawJur.any((j) => _matchProdi(j.toString(), _selectedProdi));
              if (!matchProdi) return false;
            }

            // 2. Search Query
            if (_searchQuery.isEmpty) return true;
            final matchFak = (f['nama']?.toString() ?? '')
                .toLowerCase()
                .contains(_searchQuery);
            final matchDekan = (f['dekan']?.toString() ?? '')
                .toLowerCase()
                .contains(_searchQuery);
            final rawJur = f['jurusan'];
            final matchJur = rawJur is List
                ? rawJur.any(
                    (j) => j.toString().toLowerCase().contains(_searchQuery),
                  )
                : false;
            return matchFak || matchDekan || matchJur;
          }).toList()
        : <Map<String, dynamic>>[];

    final filteredMatkul = _matkulData.where((m) {
      // 1. Role Scoping
      if (isKaProdi && currentUser != null) {
        final mJur = (m['jurusan'] ?? m['prodi'] ?? '').toString();
        if (mJur.isNotEmpty && !_matchProdi(mJur, currentUser.jurusanNama)) {
          return false;
        }
      } else if (isDekan && currentUser != null) {
        final mFak = (m['fakultas'] ?? '').toString();
        final mJur = (m['jurusan'] ?? m['prodi'] ?? '')
            .toString()
            .toLowerCase()
            .trim();
        final matchFak = _matchFakultas(mFak, currentUser.fakultasNama);
        final matchProdiInFak =
            dekanProdis.contains(mJur) ||
            dekanProdis.any((p) => mJur.contains(p));
        if (!matchFak && !matchProdiInFak && mFak.isNotEmpty) {
          return false;
        }
      }

      // 2. Dropdown Filter: Fakultas & Prodi
      if (isAdmin && _selectedFakultas != 'Semua Fakultas') {
        final mFak = (m['fakultas'] ?? '').toString();
        if (!_matchFakultas(mFak, _selectedFakultas)) {
          return false;
        }
      }
      if ((isAdmin || isDekan) && _selectedProdi != 'Semua Prodi') {
        final mJur = (m['jurusan'] ?? m['prodi'] ?? '').toString();
        if (!_matchProdi(mJur, _selectedProdi)) {
          return false;
        }
      }

      // 3. Semester Filter (Semua, Ganjil, Genap)
      final smt =
          int.tryParse(
            m['semester']?.toString() ?? m['semester_angka']?.toString() ?? '',
          ) ??
          1;
      if (_matkulSemesterFilter == 'Ganjil' && smt % 2 == 0) return false;
      if (_matkulSemesterFilter == 'Genap' && smt % 2 != 0) return false;

      // 4. Search Query
      if (_searchQuery.isEmpty) return true;
      final matchNama = (m['nama']?.toString() ?? '').toLowerCase().contains(
        _searchQuery,
      );
      final matchKode = (m['kode']?.toString() ?? '').toLowerCase().contains(
        _searchQuery,
      );
      final matchDosen = (m['dosen']?.toString() ?? '').toLowerCase().contains(
        _searchQuery,
      );
      final matchSmt =
          'semester $smt'.contains(_searchQuery) ||
          'smt $smt'.contains(_searchQuery);
      return matchNama || matchKode || matchDosen || matchSmt;
    }).toList();

    final filteredDosen = _dosenList.where((d) {
      // 1. Role Scoping
      if (isKaProdi && currentUser != null) {
        if (!_matchProdi(d.jurusanNama, currentUser.jurusanNama)) {
          return false;
        }
      } else if (isDekan && currentUser != null) {
        final matchFak = _matchFakultas(
          d.fakultasNama,
          currentUser.fakultasNama,
        );
        final dJur = d.jurusanNama.toLowerCase().trim();
        final matchProdiInFak =
            dekanProdis.contains(dJur) ||
            dekanProdis.any((p) => dJur.contains(p));
        if (!matchFak && !matchProdiInFak && d.fakultasNama.isNotEmpty) {
          return false;
        }
      }

      // 2. Dropdown Filter: Fakultas & Prodi
      if (isAdmin && _selectedFakultas != 'Semua Fakultas') {
        if (!_matchFakultas(d.fakultasNama, _selectedFakultas)) {
          return false;
        }
      }
      if ((isAdmin || isDekan) && _selectedProdi != 'Semua Prodi') {
        if (!_matchProdi(d.jurusanNama, _selectedProdi)) {
          return false;
        }
      }

      // 3. Search Query
      if (_searchQuery.isEmpty) return true;
      return d.nama.toLowerCase().contains(_searchQuery) ||
          d.jurusanNama.toLowerCase().contains(_searchQuery) ||
          d.email.toLowerCase().contains(_searchQuery);
    }).toList();

    final displayedGedungCount = _limitGedung.clamp(0, filteredGedung.length);
    final displayedFakultasCount = _limitFakultas.clamp(
      0,
      filteredFakultas.length,
    );
    final displayedMatkulCount = _limitMatkul.clamp(0, filteredMatkul.length);

    final int gedungStartIndex = 1;
    final int fakultasStartIndex = _selectedCategory == 'Semua'
        ? (gedungStartIndex + displayedGedungCount)
        : 1;
    final int matkulStartIndex = _selectedCategory == 'Semua'
        ? (fakultasStartIndex + displayedFakultasCount)
        : 1;
    final int dosenStartIndex = _selectedCategory == 'Semua'
        ? (matkulStartIndex + displayedMatkulCount)
        : 1;

    final bool canPopNaturally =
        (isAdmin
            ? _selectedCategory == 'Semua'
            : _selectedCategory == 'Mata Kuliah') &&
        _selectedFakultas == 'Semua Fakultas' &&
        _selectedProdi == 'Semua Prodi' &&
        _matkulSemesterFilter == 'Semua' &&
        !_isMultiSelectMode &&
        _totalSelectedCount == 0 &&
        _searchQuery.isEmpty;

    return PopScope(
      canPop: canPopNaturally,
      onPopInvokedWithResult: (didPop, result) {
        if (didPop) return;
        if (_isMultiSelectMode || _totalSelectedCount > 0) {
          setState(() {
            _isMultiSelectMode = false;
            _selectedGedungIds.clear();
            _selectedFakultasIds.clear();
            _selectedMatkulIds.clear();
            _selectedDosenIds.clear();
          });
          return;
        }
        if (_searchQuery.isNotEmpty) {
          _searchCtrl.clear();
          return;
        }
        if (_selectedFakultas != 'Semua Fakultas' ||
            _selectedProdi != 'Semua Prodi' ||
            _matkulSemesterFilter != 'Semua') {
          setState(() {
            _selectedFakultas = 'Semua Fakultas';
            _selectedProdi = 'Semua Prodi';
            _matkulSemesterFilter = 'Semua';
            _resetLimits();
          });
          return;
        }
        if (isAdmin && _selectedCategory != 'Semua') {
          _setCategory('Semua');
        }
      },
      child: Stack(
        children: [
          RefreshIndicator(
            onRefresh: _loadData,
            color: AppColors.primary,
            child: SingleChildScrollView(
              physics: const AlwaysScrollableScrollPhysics(),
              padding: EdgeInsets.fromLTRB(
                14,
                12,
                14,
                (_isMultiSelectMode || _totalSelectedCount > 0) ? 80 : 20,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Header Master Data
                  MasterDataHeaderCard(user: currentUser),
                  const SizedBox(height: 12),

                  // Segmented Navigation Sub-Tab (Tab 1: Mata Kuliah, Tab 2: Data Dosen)
                  if (!isAdmin) ...[
                    Container(
                      margin: const EdgeInsets.only(bottom: 12),
                      padding: const EdgeInsets.all(4),
                      decoration: BoxDecoration(
                        color: const Color(0xFFF1F5F9),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: const Color(0xFFE2E8F0)),
                      ),
                      child: Row(
                        children: [
                          Expanded(
                            child: InkWell(
                              onTap: () => _setCategory('Mata Kuliah'),
                              borderRadius: BorderRadius.circular(10),
                              child: Container(
                                padding: const EdgeInsets.symmetric(
                                  vertical: 12,
                                  horizontal: 8,
                                ),
                                alignment: Alignment.center,
                                decoration: BoxDecoration(
                                  color: _selectedCategory == 'Mata Kuliah'
                                      ? AppColors.primary
                                      : Colors.transparent,
                                  borderRadius: BorderRadius.circular(10),
                                  boxShadow: _selectedCategory == 'Mata Kuliah'
                                      ? [
                                          BoxShadow(
                                            color: AppColors.primary.withValues(
                                              alpha: 0.25,
                                            ),
                                            blurRadius: 6,
                                            offset: const Offset(0, 2),
                                          ),
                                        ]
                                      : null,
                                ),
                                child: Text(
                                  'Mata Kuliah',
                                  style: TextStyle(
                                    fontSize: 13.5,
                                    fontWeight: FontWeight.bold,
                                    color: _selectedCategory == 'Mata Kuliah'
                                        ? Colors.white
                                        : const Color(0xFF64748B),
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                            ),
                          ),
                          Expanded(
                            child: InkWell(
                              onTap: () => _setCategory('Data Dosen'),
                              borderRadius: BorderRadius.circular(10),
                              child: Container(
                                padding: const EdgeInsets.symmetric(
                                  vertical: 12,
                                  horizontal: 8,
                                ),
                                alignment: Alignment.center,
                                decoration: BoxDecoration(
                                  color: _selectedCategory == 'Data Dosen'
                                      ? AppColors.primary
                                      : Colors.transparent,
                                  borderRadius: BorderRadius.circular(10),
                                  boxShadow: _selectedCategory == 'Data Dosen'
                                      ? [
                                          BoxShadow(
                                            color: AppColors.primary.withValues(
                                              alpha: 0.25,
                                            ),
                                            blurRadius: 6,
                                            offset: const Offset(0, 2),
                                          ),
                                        ]
                                      : null,
                                ),
                                child: Text(
                                  'Data Dosen',
                                  style: TextStyle(
                                    fontSize: 13.5,
                                    fontWeight: FontWeight.bold,
                                    color: _selectedCategory == 'Data Dosen'
                                        ? Colors.white
                                        : const Color(0xFF64748B),
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],

                  // Search Bar Modern & Filter Dropdown Button
                  Row(
                    children: [
                      Expanded(
                        child: Container(
                          height: 40,
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(10),
                            border: Border.all(color: const Color(0xFFE2E8F0)),
                          ),
                          child: TextField(
                            controller: _searchCtrl,
                            style: const TextStyle(fontSize: 13),
                            decoration: InputDecoration(
                              hintText: isAdmin
                                  ? 'Cari data master...'
                                  : (_selectedCategory == 'Mata Kuliah'
                                        ? 'Cari mata kuliah...'
                                        : 'Cari dosen...'),
                              hintStyle: const TextStyle(
                                fontSize: 12,
                                color: Color(0xFF94A3B8),
                              ),
                              prefixIcon: const Icon(
                                Icons.search_rounded,
                                color: AppColors.primary,
                                size: 18,
                              ),
                              suffixIcon: _searchQuery.isNotEmpty
                                  ? IconButton(
                                      icon: const Icon(
                                        Icons.close_rounded,
                                        size: 16,
                                        color: Color(0xFF94A3B8),
                                      ),
                                      onPressed: () => _searchCtrl.clear(),
                                    )
                                  : null,
                              border: InputBorder.none,
                              isDense: true,
                              contentPadding: const EdgeInsets.symmetric(
                                horizontal: 12,
                                vertical: 10,
                              ),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      MasterDataFilterBar(
                        user: currentUser,
                        selectedCategory: _selectedCategory,
                        selectedSemester: _matkulSemesterFilter,
                        selectedFakultas: _selectedFakultas,
                        selectedProdi: _selectedProdi,
                        availableCategories: categories,
                        availableFakultas: availableFakultas,
                        fakultasToProdiMap: fakultasToProdiMap,
                        onApplyFilters:
                            ({
                              required String category,
                              required String semester,
                              required String fakultas,
                              required String prodi,
                            }) {
                              setState(() {
                                _selectedCategory = category;
                                _matkulSemesterFilter = semester;
                                _selectedFakultas = fakultas;
                                _selectedProdi = prodi;
                                _isMultiSelectMode = false;
                                _selectedGedungIds.clear();
                                _selectedFakultasIds.clear();
                                _selectedMatkulIds.clear();
                                _selectedDosenIds.clear();
                                _resetLimits();
                              });
                            },
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),

                  // Button Tambah Data
                  SizedBox(
                    width: double.infinity,
                    height: 42,
                    child: ElevatedButton.icon(
                      onPressed: () {
                        if (isAdmin) {
                          _showAdminAddDataBottomSheet(currentUser);
                        } else {
                          _triggerAddForCurrentCategory(currentUser);
                        }
                      },
                      icon: const Icon(
                        Icons.add_rounded,
                        size: 18,
                        color: Colors.white,
                      ),
                      label: Text(
                        isAdmin
                            ? 'Tambah Data'
                            : (_selectedCategory == 'Mata Kuliah'
                                  ? 'Tambah Mata Kuliah'
                                  : 'Tambah Dosen'),
                        style: const TextStyle(
                          fontSize: 13.5,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                          letterSpacing: 0.3,
                        ),
                      ),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primary,
                        elevation: 0,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 14),

                  // ── SECTION 1: MASTER GEDUNG ──
                  if (isAdmin &&
                      (_selectedCategory == 'Semua' ||
                          _selectedCategory == 'Gedung')) ...[
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
                                _gedungList.removeWhere(
                                  (item) => item.id == g.id,
                                );
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
                        limit: _limitGedung,
                        startIndex: gedungStartIndex,
                        isCompact: _selectedCategory == 'Semua',
                        onRuanganUpdated: () {
                          setState(() {});
                          _syncGlobalData();
                        },
                        onToggleSelect: (id) {
                          setState(() {
                            if (_selectedGedungIds.contains(id)) {
                              _selectedGedungIds.remove(id);
                            } else {
                              _selectedGedungIds.add(id);
                            }
                            _isMultiSelectMode = _totalSelectedCount > 0;
                          });
                        },
                        onEdit: (g) => showEditGedungDialog(
                          context: context,
                          gedung: g,
                          onSaved: (updated) async {
                            final api = context.read<ApiService>();
                            setState(() {
                              final idx = _gedungList.indexWhere(
                                (item) => item.id == g.id,
                              );
                              if (idx != -1) {
                                _gedungList[idx] = updated;
                              }
                              final dbIdx = MockDatabase.gedungList.indexWhere(
                                (item) => item.id == g.id,
                              );
                              if (dbIdx != -1) {
                                MockDatabase.gedungList[dbIdx] = updated;
                              }
                            });
                            await MockDatabase.saveLocalGedung();
                            await api.addGedung(updated);
                            _syncGlobalData();
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
                                _gedungList.removeWhere(
                                  (item) => item.id == g.id,
                                );
                                MockDatabase.gedungList.removeWhere(
                                  (item) => item.id == g.id,
                                );
                                _selectedGedungIds.remove(g.id);
                              });
                              _syncGlobalData();
                              if (!context.mounted) return;
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: Text(
                                    'Gedung ${g.nama} berhasil dihapus!',
                                  ),
                                  backgroundColor: const Color(0xFFEF4444),
                                  behavior: SnackBarBehavior.floating,
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(8),
                                  ),
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
                    if (_selectedCategory != 'Semua' &&
                        filteredGedung.length > _limitGedung)
                      MasterDataPaginationBar(
                        currentCount: _limitGedung.clamp(
                          0,
                          filteredGedung.length,
                        ),
                        totalCount: filteredGedung.length,
                        onLoadMore: () => setState(() => _limitGedung += 10),
                      ),
                    SizedBox(height: _selectedCategory == 'Semua' ? 6 : 14),
                  ],

                  // ── SECTION 2: FAKULTAS & JURUSAN (Admin Only) ──
                  if (isAdmin &&
                      (_selectedCategory == 'Semua' ||
                          _selectedCategory == 'Fakultas & Prodi')) ...[
                    if (filteredFakultas.isEmpty)
                      MasterDataEmptyState(
                        message: _searchQuery.isEmpty
                            ? 'Belum ada data fakultas & prodi.'
                            : 'Tidak ada fakultas yang cocok dengan pencarian.',
                        onAdd: () => showAddFakultasDialog(
                          context: context,
                          fakultasData: _fakultasData,
                          gedungList: _gedungList,
                          dosenList: _dosenList,
                          onAdded: (f) async {
                            MockDatabase.fakultasData.add(f);
                            MockDatabase.saveLocalFakultas();
                            setState(() => _fakultasData.add(f));
                            await api.saveFakultas(f);
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
                        limit: _limitFakultas,
                        startIndex: fakultasStartIndex,
                        isCompact: _selectedCategory == 'Semua',
                        onToggleSelect: (id) {
                          setState(() {
                            if (_selectedFakultasIds.contains(id)) {
                              _selectedFakultasIds.remove(id);
                            } else {
                              _selectedFakultasIds.add(id);
                            }
                            _isMultiSelectMode = _totalSelectedCount > 0;
                          });
                        },
                        onEdit: (f) => showEditFakultasDialog(
                          context: context,
                          fakultas: f,
                          gedungList: _gedungList,
                          dosenList: _dosenList,
                          onSaved: (updated) async {
                            setState(() {
                              final fKey =
                                  (f['id'] ?? f['nama'])?.toString() ?? '';
                              final idx = _fakultasData.indexWhere(
                                (item) =>
                                    ((item['id'] ?? item['nama'])?.toString() ??
                                        '') ==
                                    fKey,
                              );
                              if (idx != -1) {
                                _fakultasData[idx] = updated;
                              }
                              final dbIdx = MockDatabase.fakultasData
                                  .indexWhere(
                                    (item) =>
                                        ((item['id'] ?? item['nama'])
                                                ?.toString() ??
                                            '') ==
                                        fKey,
                                  );
                              if (dbIdx != -1) {
                                MockDatabase.fakultasData[dbIdx] = updated;
                              }
                            });
                            MockDatabase.saveLocalFakultas();
                            await api.saveFakultas(updated);
                            _syncGlobalData();
                          },
                        ),
                        onDelete: (f) {
                          final fNama = f['nama']?.toString() ?? 'Fakultas';
                          final fKey = f['id']?.toString() ?? fNama;
                          final rawJur = f['jurusan'];
                          final List<String> fJur = rawJur is List
                              ? rawJur.map((e) => e.toString()).toList()
                              : [];
                          confirmDeleteData(
                            context: context,
                            title: fNama,
                            category: 'Fakultas',
                            onConfirm: () async {
                              await MockDatabase.cascadeDeleteFakultas(
                                fKey,
                                fNama,
                                fJur,
                              );
                              await api.deleteFakultas(fKey);
                              setState(() {
                                _fakultasData.removeWhere(
                                  (item) =>
                                      ((item['id'] ?? item['nama'])
                                              ?.toString() ??
                                          '') ==
                                      fKey,
                                );
                                _matkulData.removeWhere((m) {
                                  final mFak = (m['fakultas'] ?? '').toString();
                                  return mFak.toLowerCase() ==
                                      fNama.toLowerCase();
                                });
                                _selectedFakultasIds.remove(fKey);
                              });
                              _syncGlobalData();
                              if (!context.mounted) return;
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: Text(
                                    'Fakultas $fNama dan seluruh prodi/matkul/jadwal terkait berhasil dihapus!',
                                  ),
                                  backgroundColor: const Color(0xFFEF4444),
                                  behavior: SnackBarBehavior.floating,
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(8),
                                  ),
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
                    if (_selectedCategory != 'Semua' &&
                        filteredFakultas.length > _limitFakultas)
                      MasterDataPaginationBar(
                        currentCount: _limitFakultas.clamp(
                          0,
                          filteredFakultas.length,
                        ),
                        totalCount: filteredFakultas.length,
                        onLoadMore: () => setState(() => _limitFakultas += 10),
                      ),
                    SizedBox(height: _selectedCategory == 'Semua' ? 6 : 14),
                  ],

                  // ── SECTION 3: MATA KULIAH & KELAS ──
                  if (_selectedCategory == 'Semua' ||
                      _selectedCategory == 'Mata Kuliah') ...[
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
                          currentUser: currentUser,
                          onAdded: (m) {
                            MockDatabase.matkulData.add(m);
                            MockDatabase.saveLocalMatkul();
                            setState(() => _matkulData.add(m));
                            api.saveMataKuliah(m);
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
                        limit: _limitMatkul,
                        startIndex: matkulStartIndex,
                        isCompact: _selectedCategory == 'Semua',
                        onToggleSelect: (id) {
                          setState(() {
                            if (_selectedMatkulIds.contains(id)) {
                              _selectedMatkulIds.remove(id);
                            } else {
                              _selectedMatkulIds.add(id);
                            }
                            _isMultiSelectMode = _totalSelectedCount > 0;
                          });
                        },
                        onEdit: (m) => showEditMatkulDialog(
                          context: context,
                          matkul: m,
                          fakultasData: _fakultasData,
                          dosenList: _dosenList,
                          currentUser: currentUser,
                          onSaved: (updated) async {
                            setState(() {
                              final kode = (m['kode'] ?? '')?.toString() ?? '';
                              final idx = _matkulData.indexWhere(
                                (item) =>
                                    (item['kode']?.toString() ?? '') == kode,
                              );
                              if (idx != -1) {
                                _matkulData[idx] = updated;
                              }
                              final dbIdx = MockDatabase.matkulData.indexWhere(
                                (item) =>
                                    (item['kode']?.toString() ?? '') == kode,
                              );
                              if (dbIdx != -1) {
                                MockDatabase.matkulData[dbIdx] = updated;
                              }
                            });
                            MockDatabase.saveLocalMatkul();
                            await api.saveMataKuliah(updated);
                            _syncGlobalData();
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
                              await MockDatabase.cascadeDeleteMatkul(
                                mKode,
                                mNama,
                              );
                              await api.deleteMataKuliah(mKode);
                              setState(() {
                                _matkulData.removeWhere(
                                  (item) =>
                                      (item['kode']?.toString() ?? '') == mKode,
                                );
                                _selectedMatkulIds.remove(mKode);
                              });
                              _syncGlobalData();
                              if (!context.mounted) return;
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: Text(
                                    'Mata Kuliah $mNama dan seluruh jadwal terkait berhasil dihapus!',
                                  ),
                                  backgroundColor: const Color(0xFFEF4444),
                                  behavior: SnackBarBehavior.floating,
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(8),
                                  ),
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
                    if (_selectedCategory != 'Semua' &&
                        filteredMatkul.length > _limitMatkul)
                      MasterDataPaginationBar(
                        currentCount: _limitMatkul.clamp(
                          0,
                          filteredMatkul.length,
                        ),
                        totalCount: filteredMatkul.length,
                        initialCount: 10,
                        onLoadMore: () => setState(() => _limitMatkul += 10),
                      ),
                    SizedBox(height: _selectedCategory == 'Semua' ? 6 : 14),
                  ],

                  // ── SECTION 4: DOSEN & PRIORITAS PENJADWALAN (MRV) ──
                  if (_selectedCategory == 'Semua' ||
                      _selectedCategory == 'Dosen Prioritas' ||
                      _selectedCategory == 'Data Dosen') ...[
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
                          currentUser: currentUser,
                          onAdded: (newDosen, isPriority) {
                            setState(() {
                              _dosenList.removeWhere(
                                (u) =>
                                    u.id == newDosen.id ||
                                    u.email == newDosen.email,
                              );
                              _dosenList.add(newDosen);
                              if (isPriority) {
                                _priorityDosenIds.add(newDosen.id);
                              }
                            });
                            _syncGlobalData();
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
                        limit: _limitDosen,
                        startIndex: dosenStartIndex,
                        isCompact: _selectedCategory == 'Semua',
                        onToggleSelect: (id) {
                          setState(() {
                            if (_selectedDosenIds.contains(id)) {
                              _selectedDosenIds.remove(id);
                            } else {
                              _selectedDosenIds.add(id);
                            }
                            _isMultiSelectMode = _totalSelectedCount > 0;
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
                          currentUser: currentUser,
                          onSaved: (updated, isPriority) {
                            setState(() {
                              final idx = _dosenList.indexWhere(
                                (item) =>
                                    item.id == d.id || item.email == d.email,
                              );
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
                            _syncGlobalData();
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
                                _dosenList.removeWhere(
                                  (item) => item.id == d.id,
                                );
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
                                  content: Text(
                                    'Dosen ${d.nama} dan seluruh jadwal terkait berhasil dihapus!',
                                  ),
                                  backgroundColor: const Color(0xFFEF4444),
                                  behavior: SnackBarBehavior.floating,
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(8),
                                  ),
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
                    if (_selectedCategory != 'Semua' &&
                        filteredDosen.length > _limitDosen)
                      MasterDataPaginationBar(
                        currentCount: _limitDosen.clamp(
                          0,
                          filteredDosen.length,
                        ),
                        totalCount: filteredDosen.length,
                        initialCount: 10,
                        onLoadMore: () => setState(() => _limitDosen += 10),
                      ),
                  ],

                  // ── SINGLE LOAD MORE BUTTON UNTUK FILTER 'SEMUA' (Khusus Role Admin) ──
                  if (isAdmin &&
                      _selectedCategory == 'Semua' &&
                      (filteredGedung.length > _limitGedung ||
                          filteredFakultas.length > _limitFakultas ||
                          filteredMatkul.length > _limitMatkul ||
                          filteredDosen.length > _limitDosen)) ...[
                    Padding(
                      padding: const EdgeInsets.only(top: 8),
                      child: InkWell(
                        onTap: () {
                          setState(() {
                            _limitGedung += 10;
                            _limitFakultas += 10;
                            _limitMatkul += 10;
                            _limitDosen += 10;
                          });
                        },
                        borderRadius: BorderRadius.circular(8),
                        child: Container(
                          width: double.infinity,
                          padding: const EdgeInsets.symmetric(
                            vertical: 10,
                            horizontal: 14,
                          ),
                          decoration: BoxDecoration(
                            color: const Color(0xFFF8FAFC),
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(color: const Color(0xFFE2E8F0)),
                          ),
                          alignment: Alignment.center,
                          child: const Text(
                            'Tampilkan Lainnya',
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                              color: Color(0xFF475569),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                  const SizedBox(height: 20),
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
      ),
    );
  }
}
