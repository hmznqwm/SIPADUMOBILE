// File: master_data_filter_bar.dart
// Deskripsi: Filter bar modern berjenjang (cascading dropdowns) untuk layar Master Data.
// Meniru gaya desain ScheduleFilterBar pada menu Jadwal.

import 'package:flutter/material.dart';
import '../../../../config/constants.dart';
import '../../../../data/models/user_model.dart';

class MasterDataFilterBar extends StatelessWidget {
  final UserModel? user;
  final String selectedCategory;
  final String selectedSemester;
  final String selectedFakultas;
  final String selectedProdi;
  final List<String> availableCategories;
  final List<String> availableFakultas;
  final Map<String, List<String>> fakultasToProdiMap;
  final Function({
    required String category,
    required String semester,
    required String fakultas,
    required String prodi,
  }) onApplyFilters;

  const MasterDataFilterBar({
    super.key,
    required this.user,
    required this.selectedCategory,
    required this.selectedSemester,
    required this.selectedFakultas,
    required this.selectedProdi,
    required this.availableCategories,
    required this.availableFakultas,
    required this.fakultasToProdiMap,
    required this.onApplyFilters,
  });

  void _openFilterBottomSheet(BuildContext context) {
    String tempCategory = selectedCategory;
    String tempSemester = selectedSemester;
    String tempFakultas = selectedFakultas;
    String tempProdi = selectedProdi;

    final role = user?.role ?? 'admin';
    final isAdmin = role == 'admin';
    final isDekan = role == 'dekan';
    final isKaProdi = role == 'kajur';

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) {
        return StatefulBuilder(
          builder: (context, setBottomSheetState) {
            // Build available prodis based on tempFakultas
            final List<String> prodiOptions = ['Semua Prodi'];
            if (tempFakultas == 'Semua Fakultas') {
              final Set<String> allProdis = {};
              fakultasToProdiMap.forEach((_, list) {
                allProdis.addAll(list);
              });
              prodiOptions.addAll(allProdis.toList()..sort());
            } else {
              final matchedProdis = fakultasToProdiMap[tempFakultas] ?? [];
              prodiOptions.addAll(matchedProdis);
            }

            if (!prodiOptions.contains(tempProdi)) {
              tempProdi = 'Semua Prodi';
            }

            // Decide which sub-filters are visible based on tempCategory
            final bool showSemesterFilter = tempCategory == 'Mata Kuliah';
            final bool showFakultasFilter = isAdmin;
            final bool showProdiFilter = isAdmin || (isDekan && !isKaProdi);

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
                              'Filter Master Data',
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

                    // 1. DROPDOWN UTAMA: JENIS DATA (Khusus Role Admin)
                    if (isAdmin) ...[
                      const Text(
                        'Jenis Data Master',
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
                            value: availableCategories.contains(tempCategory)
                                ? tempCategory
                                : (availableCategories.isNotEmpty
                                    ? availableCategories.first
                                    : 'Semua'),
                            isExpanded: true,
                            icon: const SizedBox.shrink(),
                            style: const TextStyle(
                              fontSize: 13,
                              color: Color(0xFF0F172A),
                            ),
                            items: availableCategories.map((cat) {
                              return DropdownMenuItem<String>(
                                value: cat,
                                child: Text(
                                  cat == 'Semua' ? 'Semua Kategori Data' : cat,
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
                                setBottomSheetState(() {
                                  tempCategory = val;
                                });
                              }
                            },
                          ),
                        ),
                      ),
                      const SizedBox(height: 14),
                    ],

                    // 2. SUB-FILTER: SEMESTER (Jika Mata Kuliah dipilih)
                    if (showSemesterFilter) ...[
                      const Text(
                        'Kategori Semester',
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
                            value: ['Semua', 'Ganjil', 'Genap'].contains(tempSemester)
                                ? tempSemester
                                : 'Semua',
                            isExpanded: true,
                            icon: const SizedBox.shrink(),
                            style: const TextStyle(
                              fontSize: 13,
                              color: Color(0xFF0F172A),
                            ),
                            items: const [
                              DropdownMenuItem<String>(
                                value: 'Semua',
                                child: Text(
                                  'Semua Semester (Ganjil & Genap)',
                                  style: TextStyle(
                                    fontSize: 13,
                                    fontWeight: FontWeight.w500,
                                    color: Color(0xFF0F172A),
                                  ),
                                ),
                              ),
                              DropdownMenuItem<String>(
                                value: 'Ganjil',
                                child: Text(
                                  'Semester Ganjil (1, 3, 5, 7)',
                                  style: TextStyle(
                                    fontSize: 13,
                                    fontWeight: FontWeight.w500,
                                    color: Color(0xFF0F172A),
                                  ),
                                ),
                              ),
                              DropdownMenuItem<String>(
                                value: 'Genap',
                                child: Text(
                                  'Semester Genap (2, 4, 6, 8)',
                                  style: TextStyle(
                                    fontSize: 13,
                                    fontWeight: FontWeight.w500,
                                    color: Color(0xFF0F172A),
                                  ),
                                ),
                              ),
                            ],
                            onChanged: (val) {
                              if (val != null) {
                                setBottomSheetState(() => tempSemester = val);
                              }
                            },
                          ),
                        ),
                      ),
                      const SizedBox(height: 14),
                    ],

                    // 3. SUB-FILTER: FAKULTAS (Untuk Role Admin / Khusus)
                    if (showFakultasFilter) ...[
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
                            value: availableFakultas.contains(tempFakultas)
                                ? tempFakultas
                                : 'Semua Fakultas',
                            isExpanded: true,
                            icon: const SizedBox.shrink(),
                            style: const TextStyle(
                              fontSize: 13,
                              color: Color(0xFF0F172A),
                            ),
                            items: availableFakultas.map((fak) {
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
                                setBottomSheetState(() {
                                  tempFakultas = val;
                                  tempProdi = 'Semua Prodi';
                                });
                              }
                            },
                          ),
                        ),
                      ),
                      const SizedBox(height: 14),
                    ],

                    // 4. SUB-FILTER: PROGRAM STUDI (PRODI)
                    if (showProdiFilter) ...[
                      const Text(
                        'Program Studi (Prodi)',
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
                                setBottomSheetState(() => tempProdi = val);
                              }
                            },
                          ),
                        ),
                      ),
                      const SizedBox(height: 14),
                    ] else if (isKaProdi) ...[
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 10,
                        ),
                        decoration: BoxDecoration(
                          color: const Color(0xFFF0FDFA),
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(color: const Color(0xFF99F6E4)),
                        ),
                        child: Row(
                          children: [
                            const Icon(
                              Icons.school_rounded,
                              size: 18,
                              color: AppColors.primary,
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const Text(
                                    'Lingkup Program Studi',
                                    style: TextStyle(
                                      fontSize: 10,
                                      color: Color(0xFF64748B),
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                  Text(
                                    user != null && user!.jurusanNama.isNotEmpty
                                        ? user!.jurusanNama
                                        : '-',
                                    style: const TextStyle(
                                      fontSize: 12.5,
                                      fontWeight: FontWeight.bold,
                                      color: Color(0xFF0F766E),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
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
                              setBottomSheetState(() {
                                tempCategory = isAdmin ? 'Semua' : selectedCategory;
                                tempSemester = 'Semua';
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
                              onApplyFilters(
                                category: tempCategory,
                                semester: tempSemester,
                                fakultas: tempFakultas,
                                prodi: tempProdi,
                              );
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

  @override
  Widget build(BuildContext context) {
    final role = user?.role ?? 'admin';
    final isAdmin = role == 'admin';

    int activeFilterCount = 0;
    final List<String> activeFilterLabels = [];

    // Category check (Hanya dihitung untuk role Admin karena Dekan & KaProdi menggunakan Tab)
    if (isAdmin && selectedCategory != 'Semua') {
      activeFilterCount++;
      activeFilterLabels.add(selectedCategory);
    }

    // Semester check (if category is Mata Kuliah)
    if (selectedCategory == 'Mata Kuliah' && selectedSemester != 'Semua') {
      activeFilterCount++;
      activeFilterLabels.add('Smt $selectedSemester');
    }

    // Fakultas check
    if (selectedFakultas != 'Semua Fakultas') {
      activeFilterCount++;
      activeFilterLabels.add(selectedFakultas);
    }

    // Prodi check
    if (selectedProdi != 'Semua Prodi') {
      activeFilterCount++;
      activeFilterLabels.add(selectedProdi);
    }

    return Container(
      color: Colors.transparent,
      child: InkWell(
        onTap: () => _openFilterBottomSheet(context),
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
    );
  }
}
