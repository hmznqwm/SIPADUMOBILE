// File: kelas_paralel_picker.dart
// Deskripsi: Modal Bottom Sheet Picker multi-select untuk Kelas Paralel Mata Kuliah (Mendukung Reguler A-O dan Sub-Kelas Praktikum 1A, 1B, dll).

import 'package:flutter/material.dart';
import '../../../../../config/constants.dart';

Future<List<String>?> showKelasParalelPicker({
  required BuildContext context,
  required List<String> currentSelected,
}) async {
  const List<String> regulerLetters = [
    'A', 'B', 'C', 'D', 'E',
    'F', 'G', 'H', 'I', 'J',
    'K', 'L', 'M', 'N', 'O',
  ];

  const List<String> praktikumNumericLetters = [
    '1A', '1B', '2A', '2B',
    '3A', '3B', '4A', '4B',
    '5A', '5B', '6A', '6B',
  ];

  const List<String> praktikumAlphaLetters = [
    'A1', 'A2', 'B1', 'B2',
    'C1', 'C2', 'D1', 'D2',
    'E1', 'E2', 'F1', 'F2',
  ];

  // Detect initial mode based on current selection
  int activeModeIndex = 0; // 0 = Reguler, 1 = Praktikum (1A, 1B), 2 = Praktikum (A1, A2)
  if (currentSelected.any((s) => praktikumNumericLetters.contains(s))) {
    activeModeIndex = 1;
  } else if (currentSelected.any((s) => praktikumAlphaLetters.contains(s))) {
    activeModeIndex = 2;
  }

  final Set<String> selected = Set.from(
    currentSelected.isNotEmpty ? currentSelected : ['A'],
  );

  return showModalBottomSheet<List<String>>(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (ctx) => StatefulBuilder(
      builder: (context, setModalState) {
        List<String> currentOptions;
        int gridCount;
        if (activeModeIndex == 1) {
          currentOptions = praktikumNumericLetters;
          gridCount = 4;
        } else if (activeModeIndex == 2) {
          currentOptions = praktikumAlphaLetters;
          gridCount = 4;
        } else {
          currentOptions = regulerLetters;
          gridCount = 5;
        }

        final sortedSelected = selected.toList()..sort();

        return Container(
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
          ),
          padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // ── Drag Handle ──
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

              // ── Header (Tanpa Logo) ──
              Row(
                children: [
                  const Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Pilih Kelas Paralel',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF0F172A),
                          ),
                        ),
                        SizedBox(height: 2),
                        Text(
                          'Pilih rombel perkuliahan reguler atau praktikum',
                          style: TextStyle(
                            fontSize: 11,
                            color: Color(0xFF64748B),
                          ),
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close_rounded, color: Color(0xFF64748B)),
                    onPressed: () => Navigator.pop(ctx),
                  ),
                ],
              ),

              const SizedBox(height: 12),

              // ── Segmented Mode Switcher (Reguler vs Praktikum) ──
              Container(
                padding: const EdgeInsets.all(3),
                decoration: BoxDecoration(
                  color: const Color(0xFFF1F5F9),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Row(
                  children: [
                    _buildModeTab(
                      label: 'Reguler (A, B)',
                      isSelected: activeModeIndex == 0,
                      onTap: () {
                        setModalState(() {
                          activeModeIndex = 0;
                        });
                      },
                    ),
                    _buildModeTab(
                      label: 'Praktikum (1A, 1B)',
                      isSelected: activeModeIndex == 1,
                      onTap: () {
                        setModalState(() {
                          activeModeIndex = 1;
                        });
                      },
                    ),
                    _buildModeTab(
                      label: 'Praktikum (A1, A2)',
                      isSelected: activeModeIndex == 2,
                      onTap: () {
                        setModalState(() {
                          activeModeIndex = 2;
                        });
                      },
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 16),

              // ── Grid Pilihan Kelas ──
              GridView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: gridCount,
                  crossAxisSpacing: 8,
                  mainAxisSpacing: 8,
                  childAspectRatio: gridCount == 5 ? 1.3 : 1.5,
                ),
                itemCount: currentOptions.length,
                itemBuilder: (context, index) {
                  final item = currentOptions[index];
                  final isSelected = selected.contains(item);

                  return InkWell(
                    onTap: () {
                      setModalState(() {
                        if (isSelected) {
                          if (selected.length > 1) {
                            selected.remove(item);
                          }
                        } else {
                          selected.add(item);
                        }
                      });
                    },
                    borderRadius: BorderRadius.circular(10),
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 150),
                      decoration: BoxDecoration(
                        color: isSelected ? AppColors.primary : const Color(0xFFF8FAFC),
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(
                          color: isSelected ? AppColors.primary : const Color(0xFFE2E8F0),
                          width: isSelected ? 1.5 : 1,
                        ),
                        boxShadow: isSelected
                            ? [
                                BoxShadow(
                                  color: AppColors.primary.withValues(alpha: 0.25),
                                  blurRadius: 4,
                                  offset: const Offset(0, 2),
                                ),
                              ]
                            : null,
                      ),
                      alignment: Alignment.center,
                      child: Text(
                        item,
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                          color: isSelected ? Colors.white : const Color(0xFF334155),
                        ),
                      ),
                    ),
                  );
                },
              ),

              const SizedBox(height: 20),

              // ── Footer Summary & Action ──
              Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Pilihan:',
                          style: TextStyle(
                            fontSize: 11,
                            color: Color(0xFF64748B),
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          sortedSelected.join(', '),
                          style: const TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF0F172A),
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 12),
                  ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primary,
                      foregroundColor: Colors.white,
                      elevation: 0,
                      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                    onPressed: () {
                      Navigator.pop(ctx, sortedSelected);
                    },
                    child: const Text(
                      'Terapkan',
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                  ),
                ],
              ),
            ],
          ),
        );
      },
    ),
  );
}

Widget _buildModeTab({
  required String label,
  required bool isSelected,
  required VoidCallback onTap,
}) {
  return Expanded(
    child: InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        padding: const EdgeInsets.symmetric(vertical: 8),
        decoration: BoxDecoration(
          color: isSelected ? Colors.white : Colors.transparent,
          borderRadius: BorderRadius.circular(8),
          boxShadow: isSelected
              ? [
                  const BoxShadow(
                    color: Color(0x0F000000),
                    blurRadius: 3,
                    offset: Offset(0, 1),
                  ),
                ]
              : null,
        ),
        alignment: Alignment.center,
        child: Text(
          label,
          textAlign: TextAlign.center,
          style: TextStyle(
            fontSize: 11,
            fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
            color: isSelected ? AppColors.primary : const Color(0xFF64748B),
          ),
        ),
      ),
    ),
  );
}
