// File: ruangan_kosong_section.dart
// Deskripsi: Widget monitoring ketersediaan ruangan kampus per hari dan jam kosong.
// Fitur: Filter bar modern berjenjang (Hari, Fakultas, dan Prodi dinamis) mirip menu Jadwal & Master Data.

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';

import '../../../../config/constants.dart';
import '../../../../data/models/gedung_model.dart';
import '../../../../data/services/api_service.dart';

class RuanganKosongSection extends StatefulWidget {
  final String? title;
  final String? subtitle;
  final List<Map<String, dynamic>> ruanganList;

  const RuanganKosongSection({
    super.key,
    this.title,
    this.subtitle,
    this.ruanganList = const [],
  });

  @override
  State<RuanganKosongSection> createState() => _RuanganKosongSectionState();
}

class _RuanganKosongSectionState extends State<RuanganKosongSection> {
  static const List<String> _dayOptions = [
    'Semua',
    'Senin',
    'Selasa',
    'Rabu',
    'Kamis',
    'Jumat',
    'Sabtu',
  ];

  // Active filter state
  String _ruanganDayFilter = 'Semua';
  String _selectedFakultas = 'Semua Fakultas';
  String _selectedProdi = 'Semua Prodi';

  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';
  int _displayedCount = 10;

  // Master data for filters
  List<Map<String, dynamic>> _fakultasData = [];
  List<GedungModel> _gedungList = [];
  final Map<String, List<String>> _fakultasToProdiMap = {};
  final List<String> _availableFakultas = ['Semua Fakultas'];

  ApiService? _apiService;

  @override
  void initState() {
    super.initState();
    _availableFakultas.clear();
    _availableFakultas.add('Semua Fakultas');
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadFilterMasterData();
    });
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final api = Provider.of<ApiService>(context);
    if (_apiService != api) {
      _apiService?.removeListener(_onApiChanged);
      _apiService = api;
      _apiService?.addListener(_onApiChanged);
    }
  }

  void _onApiChanged() {
    if (mounted) {
      _loadFilterMasterData();
    }
  }

  @override
  void dispose() {
    _apiService?.removeListener(_onApiChanged);
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadFilterMasterData() async {
    try {
      final api = context.read<ApiService>();
      final fList = await api.getFakultasList();
      final gList = await api.getGedungList();

      if (!mounted) return;

      setState(() {
        _fakultasData = List<Map<String, dynamic>>.from(fList);
        _gedungList = gList;

        _buildFakultasAndProdiMap();
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _fakultasData = [];
        _gedungList = [];
        _buildFakultasAndProdiMap();
      });
    }
  }

  void _buildFakultasAndProdiMap() {
    _fakultasToProdiMap.clear();
    _availableFakultas.clear();
    _availableFakultas.add('Semua Fakultas');

    for (final f in _fakultasData) {
      final fNama = (f['nama'] ?? '').toString().trim();
      if (fNama.isEmpty) continue;

      final jurRaw = f['jurusan'];
      final List<String> jurList = jurRaw is List
          ? jurRaw.map((e) => e.toString().trim()).where((s) => s.isNotEmpty).toList()
          : <String>[];

      if (!_fakultasToProdiMap.containsKey(fNama)) {
        _fakultasToProdiMap[fNama] = [];
        if (!_availableFakultas.contains(fNama)) {
          _availableFakultas.add(fNama);
        }
      }

      for (final j in jurList) {
        if (!_fakultasToProdiMap[fNama]!.contains(j)) {
          _fakultasToProdiMap[fNama]!.add(j);
        }
      }
    }
  }

  void _openRuanganFilterBottomSheet(BuildContext context) {
    String tempDay = _ruanganDayFilter;
    String tempFakultas = _selectedFakultas;
    String tempProdi = _selectedProdi;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) {
        return StatefulBuilder(
          builder: (context, setSheetState) {
            // Options list for Program Studi (Prodi)
            final List<String> prodiOptions = ['Semua Prodi'];
            if (tempFakultas == 'Semua Fakultas') {
              final Set<String> allProdis = {};
              _fakultasToProdiMap.forEach((_, list) {
                allProdis.addAll(list);
              });
              prodiOptions.addAll(allProdis.toList()..sort());
            } else {
              final matchedProdis = _fakultasToProdiMap[tempFakultas] ?? [];
              prodiOptions.addAll(matchedProdis);
            }

            if (!prodiOptions.contains(tempProdi)) {
              tempProdi = 'Semua Prodi';
            }

            // Decide whether to show prodi sub-filter dropdown
            final bool isSpecificFakultasSelected = tempFakultas != 'Semua Fakultas';

            return Container(
              decoration: const BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
              ),
              padding: EdgeInsets.only(
                left: 20,
                right: 20,
                top: 16,
                bottom: MediaQuery.of(context).viewInsets.bottom + 24,
              ),
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Drag Handle
                    Center(
                      child: Container(
                        width: 40,
                        height: 4,
                        decoration: BoxDecoration(
                          color: const Color(0xFFCBD5E1),
                          borderRadius: BorderRadius.circular(2),
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),

                    // Title Bar
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Row(
                          children: [
                            Icon(
                              Icons.tune_rounded,
                              color: AppColors.primary,
                              size: 22,
                            ),
                            SizedBox(width: 8),
                            Text(
                              'Filter Ruangan Kosong',
                              style: TextStyle(
                                fontSize: 17,
                                fontWeight: FontWeight.bold,
                                color: AppColors.textPrimary,
                              ),
                            ),
                          ],
                        ),
                        IconButton(
                          onPressed: () => Navigator.pop(context),
                          icon: const Icon(
                            Icons.close_rounded,
                            color: Color(0xFF64748B),
                          ),
                          padding: EdgeInsets.zero,
                          constraints: const BoxConstraints(),
                        ),
                      ],
                    ),
                    const Divider(height: 24),

                    // 1. DROPDOWN HARI OPERASIONAL
                    const Text(
                      'Hari Operasional',
                      style: TextStyle(
                        fontSize: 12.5,
                        fontWeight: FontWeight.w600,
                        color: Color(0xFF334155),
                      ),
                    ),
                    const SizedBox(height: 6),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12),
                      decoration: BoxDecoration(
                        color: const Color(0xFFF8FAFC),
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(color: const Color(0xFFCBD5E1)),
                      ),
                      child: DropdownButtonHideUnderline(
                        child: DropdownButton<String>(
                          value: _dayOptions.contains(tempDay) ? tempDay : 'Semua',
                          isExpanded: true,
                          icon: const SizedBox.shrink(),
                          style: const TextStyle(
                            fontSize: 13,
                            color: Color(0xFF0F172A),
                          ),
                          items: _dayOptions.map((day) {
                            return DropdownMenuItem<String>(
                              value: day,
                              child: Text(
                                day == 'Semua' ? 'Semua Hari (Senin - Sabtu)' : 'Hari $day',
                                style: const TextStyle(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w500,
                                  color: Color(0xFF0F172A),
                                ),
                              ),
                            );
                          }).toList(),
                          onChanged: (val) {
                            if (val != null) {
                              setSheetState(() => tempDay = val);
                            }
                          },
                        ),
                      ),
                    ),
                    const SizedBox(height: 14),

                    // 2. DROPDOWN FAKULTAS
                    const Text(
                      'Fakultas',
                      style: TextStyle(
                        fontSize: 12.5,
                        fontWeight: FontWeight.w600,
                        color: Color(0xFF334155),
                      ),
                    ),
                    const SizedBox(height: 6),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12),
                      decoration: BoxDecoration(
                        color: const Color(0xFFF8FAFC),
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(color: const Color(0xFFCBD5E1)),
                      ),
                      child: DropdownButtonHideUnderline(
                        child: DropdownButton<String>(
                          value: _availableFakultas.contains(tempFakultas)
                              ? tempFakultas
                              : 'Semua Fakultas',
                          isExpanded: true,
                          icon: const SizedBox.shrink(),
                          style: const TextStyle(
                            fontSize: 13,
                            color: Color(0xFF0F172A),
                          ),
                          items: _availableFakultas.map((fak) {
                            return DropdownMenuItem<String>(
                              value: fak,
                              child: Text(
                                fak,
                                style: const TextStyle(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w500,
                                  color: Color(0xFF0F172A),
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            );
                          }).toList(),
                          onChanged: (val) {
                            if (val != null) {
                              setSheetState(() {
                                tempFakultas = val;
                                tempProdi = 'Semua Prodi';
                              });
                            }
                          },
                        ),
                      ),
                    ),
                    const SizedBox(height: 14),

                    // 3. DROPDOWN SUB-FILTER PROGRAM STUDI (PRODI) DI BAWAH FAKULTAS
                    if (isSpecificFakultasSelected) ...[
                      Text(
                        'Program Studi ($tempFakultas)',
                        style: const TextStyle(
                          fontSize: 12.5,
                          fontWeight: FontWeight.w600,
                          color: Color(0xFF334155),
                        ),
                      ),
                      const SizedBox(height: 6),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12),
                        decoration: BoxDecoration(
                          color: const Color(0xFFF8FAFC),
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(color: const Color(0xFFCBD5E1)),
                        ),
                        child: DropdownButtonHideUnderline(
                          child: DropdownButton<String>(
                            value: prodiOptions.contains(tempProdi)
                                ? tempProdi
                                : 'Semua Prodi',
                            isExpanded: true,
                            icon: const SizedBox.shrink(),
                            style: const TextStyle(
                              fontSize: 13,
                              color: Color(0xFF0F172A),
                            ),
                            items: prodiOptions.map((prodi) {
                              return DropdownMenuItem<String>(
                                value: prodi,
                                child: Text(
                                  prodi,
                                  style: const TextStyle(
                                    fontSize: 13,
                                    fontWeight: FontWeight.w500,
                                    color: Color(0xFF0F172A),
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              );
                            }).toList(),
                            onChanged: (val) {
                              if (val != null) {
                                setSheetState(() => tempProdi = val);
                              }
                            },
                          ),
                        ),
                      ),
                      const SizedBox(height: 14),
                    ],

                    const SizedBox(height: 10),

                    // BUTTONS: RESET & TAMPILKAN!
                    Row(
                      children: [
                        Expanded(
                          flex: 1,
                          child: OutlinedButton(
                            onPressed: () {
                              setSheetState(() {
                                tempDay = 'Semua';
                                tempFakultas = 'Semua Fakultas';
                                tempProdi = 'Semua Prodi';
                              });
                            },
                            style: OutlinedButton.styleFrom(
                              padding: const EdgeInsets.symmetric(vertical: 13),
                              side: const BorderSide(color: Color(0xFFCBD5E1)),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(10),
                              ),
                            ),
                            child: const Text(
                              'Reset',
                              style: TextStyle(
                                color: Color(0xFF64748B),
                                fontWeight: FontWeight.bold,
                                fontSize: 13.5,
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          flex: 2,
                          child: ElevatedButton(
                            onPressed: () {
                              setState(() {
                                _ruanganDayFilter = tempDay;
                                _selectedFakultas = tempFakultas;
                                _selectedProdi = tempProdi;
                                _displayedCount = 10;
                              });
                              Navigator.pop(context);
                            },
                            style: ElevatedButton.styleFrom(
                              backgroundColor: AppColors.primary,
                              padding: const EdgeInsets.symmetric(vertical: 13),
                              elevation: 0,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(10),
                              ),
                            ),
                            child: const Text(
                              'Tampilkan!',
                              style: TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                                fontSize: 13.5,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  bool _matchesFakultasAndProdi(
    Map<String, dynamic> room,
    String fakultas,
    String prodi,
  ) {
    if (fakultas == 'Semua Fakultas' && prodi == 'Semua Prodi') return true;

    final roomGedung = (room['gedung'] ?? '').toString().toLowerCase();

    // 1. Filter Fakultas
    if (fakultas != 'Semua Fakultas') {
      final fakObj = _fakultasData.firstWhere(
        (f) => (f['nama'] ?? '').toString().toLowerCase() == fakultas.toLowerCase(),
        orElse: () => {},
      );
      final fakGedung = (fakObj['gedung'] ?? fakObj['gedung_nama'] ?? '').toString().toLowerCase();
      final fakNama = fakultas.toLowerCase();
      final fakJurusan = (_fakultasToProdiMap[fakultas] ?? []).map((j) => j.toLowerCase()).toList();

      bool matchFak = false;
      if (fakGedung.isNotEmpty && (roomGedung.contains(fakGedung) || fakGedung.contains(roomGedung))) {
        matchFak = true;
      } else if (fakNama.contains('sains') &&
          (roomGedung.contains('fst') || roomGedung.contains('sains') || roomGedung.contains('teknologi') || roomGedung.contains('lab ti'))) {
        matchFak = true;
      } else if (fakNama.contains('tarbiyah') &&
          (roomGedung.contains('tarbiyah') || roomGedung.contains('ftk') || roomGedung.contains('fitk'))) {
        matchFak = true;
      } else if (fakNama.contains('syariah') &&
          (roomGedung.contains('syariah') || roomGedung.contains('fsh'))) {
        matchFak = true;
      } else if (fakNama.contains('ekonomi') &&
          (roomGedung.contains('febi') || roomGedung.contains('feis') || roomGedung.contains('ekonomi'))) {
        matchFak = true;
      } else if (fakNama.contains('ushuluddin') &&
          (roomGedung.contains('ushuluddin') || roomGedung.contains('fu'))) {
        matchFak = true;
      } else if (fakNama.contains('dakwah') &&
          (roomGedung.contains('dakwah') || roomGedung.contains('fdk'))) {
        matchFak = true;
      } else if (fakNama.contains('adab') &&
          (roomGedung.contains('adab') || roomGedung.contains('fah'))) {
        matchFak = true;
      } else if (fakNama.contains('psikologi') &&
          (roomGedung.contains('psikologi') || roomGedung.contains('fpsi'))) {
        matchFak = true;
      } else if (roomGedung.contains('umum') ||
          roomGedung.contains('rektorat') ||
          roomGedung.contains('aula') ||
          roomGedung.contains('ict')) {
        matchFak = true;
      } else {
        // Fallback check in _gedungList
        final matchedGedung = _gedungList.where(
          (g) => g.nama.toLowerCase() == roomGedung || roomGedung.contains(g.nama.toLowerCase()),
        ).firstOrNull;
        if (matchedGedung != null) {
          final akses = matchedGedung.aksesJurusan.toLowerCase();
          if (akses.contains('semua') ||
              akses.contains(fakNama) ||
              fakJurusan.any((j) => akses.contains(j))) {
            matchFak = true;
          }
        }
      }

      if (!matchFak) return false;
    }

    // 2. Filter Program Studi (Prodi)
    if (prodi != 'Semua Prodi') {
      final prodiLower = prodi.toLowerCase();
      final matchedGedung = _gedungList.where(
        (g) => g.nama.toLowerCase() == roomGedung || roomGedung.contains(g.nama.toLowerCase()),
      ).firstOrNull;

      if (matchedGedung != null) {
        final akses = matchedGedung.aksesJurusan.toLowerCase();
        if (!akses.contains('semua') &&
            !akses.contains(prodiLower) &&
            !roomGedung.contains(prodiLower)) {
          return false;
        }
      }
    }

    return true;
  }

  @override
  Widget build(BuildContext context) {
    final effectiveSourceList = widget.ruanganList;

    final filteredRooms = effectiveSourceList.where((r) {
      // 1. Day Filter
      final matchDay = _ruanganDayFilter == 'Semua' ||
          (r['hariKosong'] as List<String>? ?? []).contains(_ruanganDayFilter);
      if (!matchDay) return false;

      // 2. Fakultas & Prodi Filter
      final matchFakultasProdi = _matchesFakultasAndProdi(
        r,
        _selectedFakultas,
        _selectedProdi,
      );
      if (!matchFakultasProdi) return false;

      // 3. Search Query
      if (_searchQuery.isEmpty) return true;
      final query = _searchQuery.toLowerCase();
      final nama = (r['nama'] ?? '').toString().toLowerCase();
      final gedung = (r['gedung'] ?? '').toString().toLowerCase();
      final kode = (r['kode'] ?? '').toString().toLowerCase();
      final fasilitas = (r['fasilitas'] ?? '').toString().toLowerCase();
      return nama.contains(query) ||
          gedung.contains(query) ||
          kode.contains(query) ||
          fasilitas.contains(query);
    }).toList();

    final visibleRooms = filteredRooms.take(_displayedCount).toList();

    final hasTitle = widget.title != null && widget.title!.trim().isNotEmpty;
    final hasSubtitle = widget.subtitle != null && widget.subtitle!.trim().isNotEmpty;

    // Active Filter Stats
    int activeFilterCount = 0;
    final List<String> activeFilterLabels = [];

    if (_ruanganDayFilter != 'Semua') {
      activeFilterCount++;
      activeFilterLabels.add('Hari $_ruanganDayFilter');
    }
    if (_selectedFakultas != 'Semua Fakultas') {
      activeFilterCount++;
      activeFilterLabels.add(_selectedFakultas);
    }
    if (_selectedProdi != 'Semua Prodi') {
      activeFilterCount++;
      activeFilterLabels.add(_selectedProdi);
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (hasTitle) ...[
          Text(
            widget.title!,
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: Color(0xFF0F172A),
            ),
          ),
          const SizedBox(height: 3),
        ],
        if (hasSubtitle) ...[
          Text(
            widget.subtitle!,
            style: const TextStyle(
              fontSize: 12,
              color: Color(0xFF64748B),
            ),
          ),
          const SizedBox(height: 12),
        ],

        // ── Modern Compact Filter Container (Identik dengan Menu Jadwal & Master Data) ──
        Container(
          margin: const EdgeInsets.only(bottom: 12),
          padding: const EdgeInsets.symmetric(
            horizontal: 12,
            vertical: 10,
          ),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: const Color(0xFFE2E8F0)),
            boxShadow: const [
              BoxShadow(
                color: Color(0x04000000),
                blurRadius: 4,
                offset: Offset(0, 2),
              ),
            ],
          ),
          child: Row(
            children: [
              // 1. Search Bar Ruangan & Gedung
              Expanded(
                child: Container(
                  height: 40,
                  decoration: BoxDecoration(
                    color: const Color(0xFFF8FAFC),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: const Color(0xFFCBD5E1)),
                  ),
                  child: TextField(
                    controller: _searchController,
                    onChanged: (val) => setState(() {
                      _searchQuery = val.trim();
                      _displayedCount = 10;
                    }),
                    style: const TextStyle(
                      fontSize: 12,
                      color: Color(0xFF0F172A),
                      fontWeight: FontWeight.w500,
                    ),
                    decoration: InputDecoration(
                      isDense: true,
                      hintText: 'Cari nama ruangan, gedung, fasilitas...',
                      hintStyle: const TextStyle(
                        fontSize: 11.5,
                        color: Color(0xFF94A3B8),
                      ),
                      prefixIcon: const Icon(
                        Icons.search_rounded,
                        color: AppColors.primary,
                        size: 17,
                      ),
                      prefixIconConstraints: const BoxConstraints(
                        minWidth: 32,
                        minHeight: 32,
                      ),
                      suffixIcon: _searchQuery.isNotEmpty
                          ? IconButton(
                              icon: const Icon(
                                Icons.clear_rounded,
                                size: 15,
                                color: Color(0xFF94A3B8),
                              ),
                              onPressed: () {
                                _searchController.clear();
                                setState(() {
                                  _searchQuery = '';
                                  _displayedCount = 10;
                                });
                              },
                            )
                          : null,
                      suffixIconConstraints: const BoxConstraints(
                        minWidth: 32,
                        minHeight: 32,
                      ),
                      border: InputBorder.none,
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 9,
                      ),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 8),

              // 2. Dropdown Filter Bar Trigger
              InkWell(
                onTap: () => _openRuanganFilterBottomSheet(context),
                borderRadius: BorderRadius.circular(10),
                child: Container(
                  height: 40,
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                  decoration: BoxDecoration(
                    color: activeFilterCount > 0
                        ? AppColors.primary.withValues(alpha: 0.08)
                        : const Color(0xFFF8FAFC),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(
                      color: activeFilterCount > 0
                          ? AppColors.primary
                          : const Color(0xFFCBD5E1),
                      width: activeFilterCount > 0 ? 1.4 : 1.0,
                    ),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        Icons.tune_rounded,
                        size: 18,
                        color: activeFilterCount > 0
                            ? AppColors.primary
                            : const Color(0xFF64748B),
                      ),
                      const SizedBox(width: 6),
                      Text(
                        'Filter',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: activeFilterCount > 0
                              ? FontWeight.bold
                              : FontWeight.w500,
                          color: activeFilterCount > 0
                              ? AppColors.primary
                              : const Color(0xFF475569),
                        ),
                      ),
                      if (activeFilterCount > 0) ...[
                        const SizedBox(width: 6),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 6,
                            vertical: 2,
                          ),
                          decoration: BoxDecoration(
                            color: AppColors.primary,
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Text(
                            '$activeFilterCount',
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 10,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),

        // ── Daftar Ruangan ──
        if (filteredRooms.isEmpty)
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(vertical: 36, horizontal: 16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: const Color(0xFFE2E8F0)),
            ),
            child: Column(
              children: [
                Icon(
                  Icons.meeting_room_outlined,
                  size: 40,
                  color: Colors.grey.shade400,
                ),
                const SizedBox(height: 8),
                const Text(
                  'Tidak ada ruangan kosong sesuai filter yang dipilih',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 13,
                    color: Color(0xFF0F172A),
                  ),
                ),
                const SizedBox(height: 4),
                const Text(
                  'Coba sesuaikan filter hari, fakultas, prodi, atau kata kunci pencarian.',
                  style: TextStyle(
                    fontSize: 11.5,
                    color: Color(0xFF64748B),
                  ),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          )
        else ...[
          Column(
            children: visibleRooms.map((r) {
              return RuanganKosongCard(
                room: r,
                dayFilter: _ruanganDayFilter,
              );
            }).toList(),
          ),

          if (filteredRooms.length > _displayedCount)
            Padding(
              padding: const EdgeInsets.only(top: 8, bottom: 8),
              child: InkWell(
                onTap: () {
                  setState(() {
                    _displayedCount += 10;
                  });
                },
                borderRadius: BorderRadius.circular(8),
                child: Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(vertical: 9, horizontal: 14),
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
      ],
    );
  }
}

class RuanganKosongCard extends StatefulWidget {
  final Map<String, dynamic> room;
  final String dayFilter;

  const RuanganKosongCard({
    super.key,
    required this.room,
    required this.dayFilter,
  });

  @override
  State<RuanganKosongCard> createState() => _RuanganKosongCardState();
}

class _RuanganKosongCardState extends State<RuanganKosongCard> {
  bool _isExpanded = false;

  @override
  Widget build(BuildContext context) {
    final r = widget.room;
    final days = (r['hariKosong'] as List<String>? ?? []);
    final bool isAvailToday = widget.dayFilter == 'Semua' ||
        days.contains(widget.dayFilter);
    final displayHari = isAvailToday && widget.dayFilter != 'Semua'
        ? 'Tersedia Hari ${widget.dayFilter}'
        : (r['hariFormatted'] ?? 'Senin - Sabtu');
    final displayJam = r['jamKosong'] ?? '07:30 - 16:20 WIB';
    final locationStr = '${r['gedung']}, ${r['lantai']}';
    final kapasitasStr = '${r['kapasitas']} Kursi';
    final tipeStr = r['tipe'] != null && r['tipe'].toString().isNotEmpty
        ? r['tipe'].toString()
        : 'Ruang Teori';

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: const Color(0xFFF1F5F9),
          width: 1,
        ),
        boxShadow: const [
          BoxShadow(
            color: Color(0x06000000),
            blurRadius: 10,
            offset: Offset(0, 3),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(20),
        child: InkWell(
          borderRadius: BorderRadius.circular(20),
          onTap: () {
            setState(() {
              _isExpanded = !_isExpanded;
            });
          },
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 18),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // ── Header Row ──
                Row(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    Expanded(
                      child: Text(
                        r['nama'] ?? 'Ruangan',
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 15.5,
                          fontWeight: FontWeight.w700,
                          color: const Color(0xFF2D3748),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          displayHari,
                          textAlign: TextAlign.right,
                          style: GoogleFonts.plusJakartaSans(
                            fontSize: 12.5,
                            fontWeight: FontWeight.w600,
                            color: const Color(0xFF64748B),
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          displayJam,
                          textAlign: TextAlign.right,
                          style: GoogleFonts.plusJakartaSans(
                            fontSize: 12,
                            fontWeight: FontWeight.w500,
                            color: const Color(0xFF94A3B8),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),

                // ── Expanded Content (Sesuai Gaya Desain Menu Jadwal) ──
                if (_isExpanded) ...[
                  const SizedBox(height: 10),
                  Text(
                    locationStr,
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 13.5,
                      fontWeight: FontWeight.w500,
                      color: const Color(0xFF94A3B8),
                      height: 1.35,
                    ),
                  ),
                  const SizedBox(height: 3),
                  Text(
                    displayHari,
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 13.5,
                      fontWeight: FontWeight.w500,
                      color: const Color(0xFF94A3B8),
                      height: 1.35,
                    ),
                  ),
                  const SizedBox(height: 3),
                  Text(
                    displayJam,
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 13.5,
                      fontWeight: FontWeight.w500,
                      color: const Color(0xFF94A3B8),
                      height: 1.35,
                    ),
                  ),
                  const SizedBox(height: 3),
                  Text(
                    '$kapasitasStr • $tipeStr',
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 12.5,
                      fontWeight: FontWeight.w500,
                      color: const Color(0xFF94A3B8),
                      height: 1.35,
                    ),
                  ),
                  if ((r['keterangan'] ?? r['fasilitas'] ?? '').toString().trim().isNotEmpty) ...[
                    const SizedBox(height: 3),
                    Text(
                      'Fasilitas: ${(r['keterangan'] ?? r['fasilitas'] ?? '').toString().trim()}',
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 12.5,
                        fontWeight: FontWeight.w500,
                        color: const Color(0xFF64748B),
                        height: 1.35,
                      ),
                    ),
                  ],
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}
