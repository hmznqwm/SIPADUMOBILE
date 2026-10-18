// File: kajur_ajuan_card.dart
// Deskripsi: Widget kartu pengajuan mengajar dosen untuk role KaProdi (Level 1 Approval) dengan nested slide carousel.

import 'package:flutter/material.dart';

import '../../../../../config/constants.dart';
import '../../../../../data/models/ajuan_pengajaran_model.dart';
import '../../../../../data/services/api_service.dart';
import '../ajuan_pengajaran_dialogs.dart';
import '../availability_common_widgets.dart';

class KajurAjuanCard extends StatefulWidget {
  final List<AjuanPengajaranModel>? ajuanList;
  final AjuanPengajaranModel? aj; // for backward compatibility
  final ApiService api;
  final Set<String> selectedAjuanIds;
  final Function(String id, VoidCallback defaultAction) onAjuanTap;
  final Function(String id) onAjuanLongPress;
  final Future<void> Function() onRefresh;

  const KajurAjuanCard({
    super.key,
    this.ajuanList,
    this.aj,
    required this.api,
    required this.selectedAjuanIds,
    required this.onAjuanTap,
    required this.onAjuanLongPress,
    required this.onRefresh,
  });

  @override
  State<KajurAjuanCard> createState() => _KajurAjuanCardState();
}

class _KajurAjuanCardState extends State<KajurAjuanCard> {
  int _currentIndex = 0;
  late final PageController _pageController;

  List<AjuanPengajaranModel> get _items {
    if (widget.ajuanList != null && widget.ajuanList!.isNotEmpty) {
      return widget.ajuanList!;
    }
    if (widget.aj != null) {
      return [widget.aj!];
    }
    return [];
  }

  @override
  void initState() {
    super.initState();
    _pageController = PageController();
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final items = _items;
    if (items.isEmpty) return const SizedBox.shrink();

    final safeIndex = _currentIndex < items.length ? _currentIndex : 0;
    final currentAj = items[safeIndex];

    final isPendingKaProdi =
        currentAj.status == 'menunggu_kaprodi' || currentAj.status == 'menunggu_verifikasi';
    final isSelected = widget.selectedAjuanIds.contains(currentAj.id);

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isSelected ? AppColors.primary : const Color(0xFFE2E8F0),
          width: isSelected ? 2.0 : 1.0,
        ),
        boxShadow: [
          BoxShadow(
            color: isSelected
                ? AppColors.primary.withValues(alpha: 0.15)
                : const Color(0x0A000000),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(15.0),
        child: InkWell(
          onTap: () => widget.onAjuanTap(
            currentAj.id,
            () => AjuanPengajaranDialogs.showDetailDialog(
              context: context,
              ajuan: currentAj,
              currentRole: 'kaprodi',
              onRefresh: widget.onRefresh,
            ),
          ),
          onLongPress: () => widget.onAjuanLongPress(currentAj.id),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            mainAxisSize: MainAxisSize.min,
            children: [
              // ── HEADER DOSEN ──
              Padding(
                padding: const EdgeInsets.all(16),
                child: Row(
                  children: [
                    Stack(
                      alignment: Alignment.center,
                      children: [
                        buildDosenAvatar(
                          dosenId: currentAj.dosenId,
                          dosenNama: currentAj.dosenNama,
                          radius: 22,
                        ),
                        if (isSelected)
                          Container(
                            width: 44,
                            height: 44,
                            decoration: BoxDecoration(
                              color: AppColors.primary,
                              shape: BoxShape.circle,
                              border: Border.all(color: Colors.white, width: 2),
                            ),
                            child: const Icon(
                              Icons.check_rounded,
                              color: Colors.white,
                              size: 24,
                            ),
                          ),
                      ],
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            currentAj.dosenNama,
                            style: const TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.bold,
                              color: Color(0xFF0F172A),
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          const SizedBox(height: 2),
                          Text(
                            currentAj.jurusanNama.isNotEmpty
                                ? currentAj.jurusanNama
                                : (currentAj.fakultasNama.isNotEmpty ? currentAj.fakultasNama : '-'),
                            style: const TextStyle(
                              fontSize: 12,
                              color: Color(0xFF64748B),
                              fontWeight: FontWeight.w500,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: AppColors.primary.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text(
                        'KaProdi',
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.bold,
                          color: AppColors.primary,
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              // ── BODY: CAROUSEL ──
              Container(
                color: const Color(0xFFF8FAFC),
                child: Column(
                  children: [
                    ExpandablePageView.builder(
                      controller: _pageController,
                      itemCount: items.length,
                      onPageChanged: (idx) {
                        setState(() {
                          _currentIndex = idx;
                        });
                      },
                      itemBuilder: (ctx, idx) {
                        final aj = items[idx];
                        final cleanKelas = aj.kelasNama.trim().toLowerCase().startsWith('kelas')
                            ? aj.kelasNama.trim()
                            : (aj.kelasNama.trim().isNotEmpty ? 'Kelas ${aj.kelasNama.trim()}' : '-');

                        return Container(
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: const Color(0xFFE2E8F0)),
                            boxShadow: const [
                              BoxShadow(
                                color: Color(0x050F172A),
                                blurRadius: 4,
                                offset: Offset(0, 1),
                              ),
                            ],
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              // Top Sub-header
                              Container(
                                padding: const EdgeInsets.only(bottom: 12),
                                decoration: const BoxDecoration(
                                  border: Border(bottom: BorderSide(color: Color(0xFFF1F5F9))),
                                ),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    const Text(
                                      'MATA KULIAH POKOK',
                                      style: TextStyle(
                                        fontSize: 10,
                                        fontWeight: FontWeight.w700,
                                        color: Color(0xFF94A3B8),
                                        letterSpacing: 0.5,
                                      ),
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      aj.mataKuliahNama,
                                      style: const TextStyle(
                                        fontSize: 15,
                                        fontWeight: FontWeight.w600,
                                        color: Color(0xFF0F172A),
                                      ),
                                    ),
                                    const SizedBox(height: 2),
                                    Text(
                                      'TIF-${aj.mataKuliahId} | ${aj.sks} SKS | Teori & Praktik',
                                      style: const TextStyle(
                                        fontSize: 12,
                                        color: Color(0xFF64748B),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              const SizedBox(height: 12),
                              
                              // Grid Semester & Kelas
                              Row(
                                children: [
                                  Expanded(
                                    child: Container(
                                      padding: const EdgeInsets.all(10),
                                      decoration: BoxDecoration(
                                        color: const Color(0xFFF8FAFC),
                                        borderRadius: BorderRadius.circular(8),
                                        border: Border.all(color: const Color(0xFFF1F5F9)),
                                      ),
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          const Text('TINGKAT SEMESTER', style: TextStyle(fontSize: 10, fontWeight: FontWeight.w700, color: Color(0xFF94A3B8))),
                                          const SizedBox(height: 2),
                                          Text('Semester ${aj.semester}', style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: Color(0xFF0F172A))),
                                        ],
                                      ),
                                    ),
                                  ),
                                  const SizedBox(width: 10),
                                  Expanded(
                                    child: Container(
                                      padding: const EdgeInsets.all(10),
                                      decoration: BoxDecoration(
                                        color: const Color(0xFFF8FAFC),
                                        borderRadius: BorderRadius.circular(8),
                                        border: Border.all(color: const Color(0xFFF1F5F9)),
                                      ),
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          const Text('ALOKASI KELAS', style: TextStyle(fontSize: 10, fontWeight: FontWeight.w700, color: Color(0xFF94A3B8))),
                                          const SizedBox(height: 2),
                                          Text(cleanKelas, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: Color(0xFF0F172A))),
                                        ],
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 10),

                              // Hari & Tanggal
                              Container(
                                padding: const EdgeInsets.all(10),
                                width: double.infinity,
                                decoration: BoxDecoration(
                                  color: const Color(0xFFF8FAFC),
                                  borderRadius: BorderRadius.circular(8),
                                  border: Border.all(color: const Color(0xFFF1F5F9)),
                                ),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    const Text('HARI & TANGGAL', style: TextStyle(fontSize: 10, fontWeight: FontWeight.w700, color: Color(0xFF94A3B8))),
                                    const SizedBox(height: 2),
                                    Text('${aj.hari}, 12 Oktober 2026', style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: Color(0xFF0F172A))),
                                  ],
                                ),
                              ),
                              const SizedBox(height: 10),

                              // Waktu
                              Container(
                                padding: const EdgeInsets.all(10),
                                width: double.infinity,
                                decoration: BoxDecoration(
                                  color: const Color(0xFFF8FAFC),
                                  borderRadius: BorderRadius.circular(8),
                                  border: Border.all(color: const Color(0xFFF1F5F9)),
                                ),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    const Text('WAKTU PERKULIAHAN', style: TextStyle(fontSize: 10, fontWeight: FontWeight.w700, color: Color(0xFF94A3B8))),
                                    const SizedBox(height: 2),
                                    Text(aj.waktuFormatted, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: AppColors.primary)),
                                  ],
                                ),
                              ),
                              const SizedBox(height: 10),

                              // Ruangan
                              Container(
                                padding: const EdgeInsets.all(12),
                                width: double.infinity,
                                decoration: BoxDecoration(
                                  color: const Color(0xFFF8FAFC),
                                  borderRadius: BorderRadius.circular(8),
                                  border: Border.all(color: const Color(0xFFF1F5F9)),
                                ),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Row(
                                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                      children: [
                                        const Text('RUANGAN & TEMPAT', style: TextStyle(fontSize: 10, fontWeight: FontWeight.w700, color: Color(0xFF94A3B8))),
                                        const Text('Tersedia', style: TextStyle(fontSize: 10, fontWeight: FontWeight.w700, color: AppColors.primary)),
                                      ],
                                    ),
                                    const SizedBox(height: 4),
                                    Text('${aj.gedungNama} — ${aj.ruanganNama}', style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: Color(0xFF0F172A))),
                                    const SizedBox(height: 6),
                                    const Divider(color: Color(0xFFE2E8F0), height: 1),
                                    const SizedBox(height: 6),
                                    const Text('Kapasitas 40 Kursi | Fasilitas Smart TV & AC', style: TextStyle(fontSize: 11, color: Color(0xFF64748B))),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        );
                      },
                    ),
                    if (items.length > 1) ...[
                      Padding(
                        padding: const EdgeInsets.only(bottom: 12),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: List.generate(items.length, (i) {
                            final isActive = i == safeIndex;
                            return AnimatedContainer(
                              duration: const Duration(milliseconds: 200),
                              margin: const EdgeInsets.symmetric(horizontal: 4),
                              width: isActive ? 20 : 8,
                              height: 6,
                              decoration: BoxDecoration(
                                color: isActive ? AppColors.primary : const Color(0xFFCBD5E1),
                                borderRadius: BorderRadius.circular(4),
                              ),
                            );
                          }),
                        ),
                      ),
                    ],
                  ],
                ),
              ),

              // ── FOOTER: BUTTONS ──
              Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: OutlinedButton(
                            style: OutlinedButton.styleFrom(
                              foregroundColor: const Color(0xFF0F172A),
                              side: const BorderSide(color: Color(0xFFCBD5E1)),
                              padding: const EdgeInsets.symmetric(vertical: 12),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(8),
                              ),
                            ),
                            onPressed: () {
                              AjuanPengajaranDialogs.showConflictCheckDialog(
                                context: context,
                                ajuan: currentAj,
                              );
                            },
                            child: const Text(
                              'Cek Bentrok',
                              style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold),
                              maxLines: 1,
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: OutlinedButton(
                            style: OutlinedButton.styleFrom(
                              foregroundColor: const Color(0xFF0F172A),
                              side: const BorderSide(color: Color(0xFFCBD5E1)),
                              padding: const EdgeInsets.symmetric(vertical: 12),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(8),
                              ),
                            ),
                            onPressed: () {
                              AjuanPengajaranDialogs.showDetailDialog(
                                context: context,
                                ajuan: currentAj,
                                currentRole: 'kaprodi',
                                onRefresh: widget.onRefresh,
                              );
                            },
                            child: const Text(
                              'Detail',
                              style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold),
                              maxLines: 1,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        Expanded(
                          child: ElevatedButton(
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFFFEF2F2),
                              foregroundColor: const Color(0xFFDC2626),
                              padding: const EdgeInsets.symmetric(vertical: 12),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(8),
                              ),
                              elevation: 0,
                            ),
                            onPressed: isPendingKaProdi
                                ? () {
                                    AjuanPengajaranDialogs.showRejectDialog(
                                      context: context,
                                      ajuan: currentAj,
                                      role: 'kaprodi',
                                      onConfirmReject: (alasan) async {
                                        await widget.api.kaprodiRejectAjuan(currentAj.id, alasan);
                                        widget.onRefresh();
                                      },
                                    );
                                  }
                                : null,
                            child: const Text(
                              'Tolak Jadwal',
                              style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold),
                              maxLines: 1,
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: ElevatedButton(
                            style: ElevatedButton.styleFrom(
                              backgroundColor: isPendingKaProdi
                                  ? AppColors.primary
                                  : const Color(0xFFE2E8F0),
                              foregroundColor: isPendingKaProdi
                                  ? Colors.white
                                  : const Color(0xFF64748B),
                              padding: const EdgeInsets.symmetric(vertical: 12),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(8),
                              ),
                              elevation: 0,
                            ),
                            onPressed: isPendingKaProdi
                                ? () async {
                                    if (currentAj.status == 'bentrok_terdeteksi') {
                                      _showConflictWarning(context, currentAj, currentAj.bentrokDetail ?? 'Terdeteksi konflik jadwal.');
                                      return;
                                    }
                                    final conflict = widget.api.checkBuildingConflict(currentAj);
                                    if (conflict['hasConflict'] == true) {
                                      _showConflictWarning(context, currentAj, conflict['message'] ?? 'Terdeteksi bentrok ruangan/gedung.');
                                      return;
                                    }
                                    await widget.api.kaprodiVerifyAjuan(currentAj.id);
                                    widget.onRefresh();
                                    if (context.mounted) {
                                      ScaffoldMessenger.of(context).showSnackBar(
                                        SnackBar(
                                          content: const Text('Ajuan Terverifikasi KaProdi -> Diteruskan ke Dekan!'),
                                          backgroundColor: AppColors.primary,
                                        ),
                                      );
                                    }
                                  }
                                : null,
                            child: const Text(
                              'Verifikasi',
                              style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold),
                              maxLines: 1,
                            ),
                          ),
                        ),
                      ],
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



  void _showConflictWarning(BuildContext context, AjuanPengajaranModel aj, String detail) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Row(
          children: [
            Icon(Icons.warning_amber_rounded, color: AppColors.error, size: 24),
            SizedBox(width: 8),
            Text('Konflik Terdeteksi', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
          ],
        ),
        content: Text(detail, style: const TextStyle(fontSize: 13, color: Color(0xFF334155))),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Tutup'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.primary, foregroundColor: Colors.white),
            onPressed: () {
              Navigator.pop(ctx);
              AjuanPengajaranDialogs.showConflictCheckDialog(context: context, ajuan: aj);
            },
            child: const Text('Buka Solusi RCK'),
          ),
        ],
      ),
    );
  }
}
