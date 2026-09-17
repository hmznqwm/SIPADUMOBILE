import 'package:flutter/material.dart';
import '../../../../config/constants.dart';
import '../../../../data/models/user_model.dart';
import '../view_models/schedule_view_model.dart';

class ScheduleFilterBar extends StatelessWidget {
  final ScheduleViewModel viewModel;
  final UserModel? user;
  final int selectedAdminTab;
  final int conflictCount;
  final ValueChanged<int> onTabChanged;

  const ScheduleFilterBar({
    super.key,
    required this.viewModel,
    required this.user,
    required this.selectedAdminTab,
    required this.conflictCount,
    required this.onTabChanged,
  });

  void _openFilterBottomSheet(BuildContext context) {
    String tempDay = viewModel.selectedDay;
    String tempFakultas = viewModel.selectedFakultas;
    String tempProdi = viewModel.selectedProdi;

    final isAdmin = user?.role == 'admin';
    final isDekan = user?.role == 'dekan';
    final isKaProdi = user?.role == 'kajur';

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) {
        return StatefulBuilder(
          builder: (context, setBottomSheetState) {
            // Available prodis based on tempFakultas
            final prodisForFakultas = <String>{'Semua Prodi'};
            for (final item in viewModel.jadwalList) {
              final isFakMatch = tempFakultas == 'Semua Fakultas' ||
                  item.fakultasNama == tempFakultas ||
                  (tempFakultas.contains('Ekonomi') && (item.fakultasNama?.contains('Ekonomi') ?? false));
              if (isFakMatch && item.jurusanNama != null && item.jurusanNama!.isNotEmpty) {
                prodisForFakultas.add(item.jurusanNama!);
              }
            }
            if (tempFakultas == 'Fakultas Sains & Teknologi') {
              prodisForFakultas.add('Teknik Informatika');
              prodisForFakultas.add('Sistem Informasi');
            } else if (tempFakultas.contains('Ekonomi')) {
              prodisForFakultas.add('Manajemen');
              prodisForFakultas.add('Akuntansi');
            }

            final prodiList = prodisForFakultas.toList();
            if (!prodiList.contains(tempProdi)) {
              tempProdi = 'Semua Prodi';
            }

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
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
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
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Row(
                        children: [
                          Icon(Icons.tune_rounded, color: AppColors.primary, size: 22),
                          SizedBox(width: 8),
                          Text(
                            'Filter Jadwal Perkuliahan',
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
                        icon: const Icon(Icons.close_rounded, color: Color(0xFF64748B)),
                        padding: EdgeInsets.zero,
                        constraints: const BoxConstraints(),
                      ),
                    ],
                  ),
                  const Divider(height: 24),
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
                        value: viewModel.availableDays.contains(tempDay) ? tempDay : 'Semua',
                        isExpanded: true,
                        icon: const Icon(Icons.keyboard_arrow_down_rounded, color: AppColors.primary),
                        style: const TextStyle(fontSize: 13, color: Color(0xFF0F172A)),
                        items: viewModel.availableDays.map((day) {
                          return DropdownMenuItem<String>(
                            value: day,
                            child: Row(
                              children: [
                                const Icon(Icons.today_rounded, size: 16, color: AppColors.primary),
                                const SizedBox(width: 8),
                                Text(
                                  day == 'Semua' ? 'Semua Hari (Senin - Jumat)' : 'Hari $day',
                                  style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w500, color: Color(0xFF0F172A)),
                                ),
                              ],
                            ),
                          );
                        }).toList(),
                        onChanged: (val) {
                          if (val != null) {
                            setBottomSheetState(() => tempDay = val);
                          }
                        },
                      ),
                    ),
                  ),
                  const SizedBox(height: 14),
                  if (isAdmin || isDekan) ...[
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
                          value: viewModel.availableFakultas.contains(tempFakultas) ? tempFakultas : 'Semua Fakultas',
                          isExpanded: true,
                          icon: const Icon(Icons.keyboard_arrow_down_rounded, color: AppColors.primary),
                          style: const TextStyle(fontSize: 13, color: Color(0xFF0F172A)),
                          items: viewModel.availableFakultas.map((fak) {
                            return DropdownMenuItem<String>(
                              value: fak,
                              child: Text(fak),
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
                          value: prodiList.contains(tempProdi) ? tempProdi : 'Semua Prodi',
                          isExpanded: true,
                          icon: const Icon(Icons.keyboard_arrow_down_rounded, color: AppColors.primary),
                          style: const TextStyle(fontSize: 13, color: Color(0xFF0F172A)),
                          items: prodiList.map((prodi) {
                            return DropdownMenuItem<String>(
                              value: prodi,
                              child: Text(prodi),
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
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                      decoration: BoxDecoration(
                        color: const Color(0xFFF0FDFA),
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(color: const Color(0xFF99F6E4)),
                      ),
                      child: Row(
                        children: [
                          const Icon(Icons.school_rounded, size: 18, color: AppColors.primary),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text(
                                  'Lingkup Program Studi',
                                  style: TextStyle(fontSize: 10, color: Color(0xFF64748B), fontWeight: FontWeight.w500),
                                ),
                                Text(
                                  user != null && user!.jurusanNama.isNotEmpty
                                      ? user!.jurusanNama
                                      : 'Teknik Informatika',
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
                  Row(
                    children: [
                      Expanded(
                        flex: 1,
                        child: OutlinedButton(
                          onPressed: () {
                            setBottomSheetState(() {
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
                            viewModel.setFilters(
                              day: tempDay,
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
            );
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final isAdmin = user?.role == 'admin';
    final isDekan = user?.role == 'dekan';
    final isKaProdi = user?.role == 'kajur';
    final isPrivileged = isAdmin || isDekan || isKaProdi;

    int activeFilterCount = 0;
    final List<String> activeFilterLabels = [];

    if (viewModel.selectedDay != 'Semua') {
      activeFilterCount++;
      activeFilterLabels.add('Hari ${viewModel.selectedDay}');
    }
    if (viewModel.selectedFakultas != 'Semua Fakultas') {
      activeFilterCount++;
      activeFilterLabels.add(viewModel.selectedFakultas);
    }
    if (viewModel.selectedProdi != 'Semua Prodi') {
      activeFilterCount++;
      activeFilterLabels.add(viewModel.selectedProdi);
    }

    String defaultHint = 'Filter Hari, Fakultas & Prodi';
    if (isKaProdi) {
      defaultHint = 'Filter Hari (Internal Prodi)';
    } else if (!isAdmin && !isDekan) {
      defaultHint = 'Filter Hari';
    }

    final String buttonLabel = activeFilterCount > 0
        ? 'Filter (${activeFilterLabels.join(', ')})'
        : defaultHint;

    return Container(
      color: Colors.white,
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      child: Column(
        children: [
          // 0. Segmented Tab Switcher (Khusus Role Admin, Dekan, & KaProdi: Jadwal vs Resolusi Konflik)
          if (isPrivileged) ...[
            Container(
              margin: const EdgeInsets.only(bottom: 10),
              padding: const EdgeInsets.all(4),
              decoration: BoxDecoration(
                color: const Color(0xFFF1F5F9),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: const Color(0xFFE2E8F0)),
              ),
              child: Row(
                children: [
                  // Tab 1: Jadwal
                  Expanded(
                    child: InkWell(
                      onTap: () => onTabChanged(0),
                      borderRadius: BorderRadius.circular(8),
                      child: Container(
                        padding: const EdgeInsets.symmetric(vertical: 9),
                        alignment: Alignment.center,
                        decoration: BoxDecoration(
                          color: selectedAdminTab == 0 ? AppColors.primary : Colors.transparent,
                          borderRadius: BorderRadius.circular(8),
                          boxShadow: selectedAdminTab == 0
                              ? [
                                  BoxShadow(
                                    color: AppColors.primary.withValues(alpha: 0.2),
                                    blurRadius: 4,
                                    offset: const Offset(0, 1),
                                  ),
                                ]
                              : null,
                        ),
                        child: Text(
                          'Jadwal',
                          style: TextStyle(
                            fontSize: 12.5,
                            fontWeight: FontWeight.bold,
                            color: selectedAdminTab == 0 ? Colors.white : const Color(0xFF64748B),
                          ),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 4),
                  // Tab 2: Bentrok Jadwal
                  Expanded(
                    child: InkWell(
                      onTap: () => onTabChanged(1),
                      borderRadius: BorderRadius.circular(8),
                      child: Container(
                        padding: const EdgeInsets.symmetric(vertical: 9),
                        alignment: Alignment.center,
                        decoration: BoxDecoration(
                          color: selectedAdminTab == 1 ? AppColors.primary : Colors.transparent,
                          borderRadius: BorderRadius.circular(8),
                          boxShadow: selectedAdminTab == 1
                              ? [
                                  BoxShadow(
                                    color: AppColors.primary.withValues(alpha: 0.2),
                                    blurRadius: 4,
                                    offset: const Offset(0, 1),
                                  ),
                                ]
                              : null,
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              'Resolusi Konflik',
                              style: TextStyle(
                                fontSize: 12.5,
                                fontWeight: FontWeight.bold,
                                color: selectedAdminTab == 1 ? Colors.white : const Color(0xFF64748B),
                              ),
                            ),
                            if (conflictCount > 0) ...[
                              const SizedBox(width: 6),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1.5),
                                decoration: BoxDecoration(
                                  color: selectedAdminTab == 1 ? Colors.white : const Color(0xFFDC2626),
                                  borderRadius: BorderRadius.circular(10),
                                ),
                                child: Text(
                                  '$conflictCount',
                                  style: TextStyle(
                                    fontSize: 10,
                                    fontWeight: FontWeight.bold,
                                    color: selectedAdminTab == 1 ? AppColors.primary : Colors.white,
                                  ),
                                ),
                              ),
                            ],
                          ],
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],

          // Filter Button jika sedang di Tab Jadwal (atau non-privileged)
          if (!isPrivileged || selectedAdminTab == 0) ...[
            InkWell(
              onTap: () => _openFilterBottomSheet(context),
              borderRadius: BorderRadius.circular(10),
              child: Container(
                height: 40,
                width: double.infinity,
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
                  children: [
                    Icon(
                      Icons.tune_rounded,
                      size: 18,
                      color: activeFilterCount > 0
                          ? AppColors.primary
                          : const Color(0xFF64748B),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        buttonLabel,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
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
                    ),
                    if (activeFilterCount > 0) ...[
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
                      const SizedBox(width: 6),
                    ],
                    Icon(
                      Icons.keyboard_arrow_down_rounded,
                      size: 20,
                      color: activeFilterCount > 0
                          ? AppColors.primary
                          : const Color(0xFF64748B),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}
