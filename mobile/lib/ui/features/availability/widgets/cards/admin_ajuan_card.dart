// File: admin_ajuan_card.dart
// Deskripsi: Widget kartu pengajuan mengajar dosen untuk role Admin (Final Scheduling Approval) dengan nested slide carousel.

import 'package:flutter/material.dart';

import '../../../../../config/constants.dart';
import '../../../../../data/models/ajuan_pengajaran_model.dart';
import '../../../../../data/services/api_service.dart';
import '../ajuan_pengajaran_dialogs.dart';
import '../availability_common_widgets.dart';

class AdminAjuanCard extends StatefulWidget {
  final List<AjuanPengajaranModel>? ajuanList;
  final AjuanPengajaranModel? aj; // for backward compatibility
  final ApiService api;
  final Set<String> selectedAjuanIds;
  final Function(String id, VoidCallback defaultAction) onAjuanTap;
  final Function(String id) onAjuanLongPress;
  final Future<void> Function() onRefresh;

  const AdminAjuanCard({
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
  State<AdminAjuanCard> createState() => _AdminAjuanCardState();
}

class _AdminAjuanCardState extends State<AdminAjuanCard> {
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

    final isSelected = widget.selectedAjuanIds.contains(currentAj.id);
    final stageColor = getAjuanStageColor(currentAj.status);

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isSelected ? stageColor : const Color(0xFFE2E8F0),
          width: isSelected ? 2.0 : 1.0,
        ),
        boxShadow: const [
          BoxShadow(
            color: Color(0x0A0F172A), // shadow-card-elevated
            blurRadius: 10,
            offset: Offset(0, 4),
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
              currentRole: 'admin',
              onRefresh: widget.onRefresh,
            ),
          ),
          onLongPress: () => widget.onAjuanLongPress(currentAj.id),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            mainAxisSize: MainAxisSize.min,
            children: [
              // ── 1. HEADER DOSEN (White Background) ──
              Container(
                padding: const EdgeInsets.fromLTRB(20, 20, 20, 16),
                decoration: const BoxDecoration(
                  border: Border(bottom: BorderSide(color: Color(0xFFF1F5F9))),
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    Stack(
                      alignment: Alignment.center,
                      children: [
                        buildDosenAvatar(
                          dosenId: currentAj.dosenId,
                          dosenNama: currentAj.dosenNama,
                          radius: 26,
                        ),
                        if (isSelected)
                          Container(
                            width: 52,
                            height: 52,
                            decoration: BoxDecoration(
                              color: stageColor.withValues(alpha: 0.8),
                              shape: BoxShape.circle,
                              border: Border.all(color: Colors.white, width: 2),
                            ),
                            child: const Icon(
                              Icons.check_rounded,
                              color: Colors.white,
                              size: 28,
                            ),
                          ),
                      ],
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            currentAj.dosenNama,
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                              color: Color(0xFF0F172A),
                              letterSpacing: -0.3,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          const SizedBox(height: 4),
                          Wrap(
                            crossAxisAlignment: WrapCrossAlignment.center,
                            spacing: 6,
                            runSpacing: 4,
                            children: [
                              Text(
                                currentAj.dosenId.isNotEmpty ? currentAj.dosenId : '0412087601', // NIDN Fallback
                                style: const TextStyle(
                                  fontSize: 12,
                                  color: Color(0xFF64748B),
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                              const Text(
                                '•',
                                style: TextStyle(color: Color(0xFFCBD5E1), fontSize: 12),
                              ),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                                decoration: BoxDecoration(
                                  color: const Color(0xFFE0F2F1),
                                  borderRadius: BorderRadius.circular(100),
                                  border: Border.all(color: const Color(0xFFB2DFDB)),
                                ),
                                child: Text(
                                  currentAj.jurusanNama.isNotEmpty ? currentAj.jurusanNama : 'Jurusan',
                                  style: const TextStyle(
                                    fontSize: 10.5,
                                    fontWeight: FontWeight.w600,
                                    color: Color(0xFF00695C),
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

              // ── 2. BODY KARTU (Jadwal Diajukan - Light Gray) ──
              Container(
                color: const Color(0xFFF8FAFC), // bg-slate-50
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text(
                          'JADWAL DIAJUKAN',
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w700,
                            color: Color(0xFF94A3B8),
                            letterSpacing: 0.5,
                          ),
                        ),
                        if (items.length > 1)
                          Row(
                            children: List.generate(items.length, (i) {
                              final isActive = i == safeIndex;
                              return AnimatedContainer(
                                duration: const Duration(milliseconds: 200),
                                margin: const EdgeInsets.symmetric(horizontal: 2),
                                width: isActive ? 20 : 6,
                                height: 6,
                                decoration: BoxDecoration(
                                  color: isActive ? AppColors.primary : const Color(0xFFE2E8F0),
                                  borderRadius: BorderRadius.circular(3),
                                ),
                              );
                            }),
                          ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    
                    // The ExpandablePageView mimicking the horizontal scroll items
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
                                    Text('${aj.hari}, 12 Oktober 2026', style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: Color(0xFF0F172A))), // Tanggal statis sementara
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
                  ],
                ),
              ),

              // ── 3. FOOTER ACTION BAR (4 Buttons Grid) ──
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                decoration: const BoxDecoration(
                  color: Colors.white,
                  border: Border(top: BorderSide(color: Color(0xFFF1F5F9))),
                ),
                child: Column(
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: OutlinedButton(
                            style: OutlinedButton.styleFrom(
                              foregroundColor: const Color(0xFF334155),
                              backgroundColor: const Color(0xFFF8FAFC),
                              side: const BorderSide(color: Color(0xFFE2E8F0)),
                              padding: const EdgeInsets.symmetric(vertical: 12),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                            ),
                            onPressed: () => AjuanPengajaranDialogs.showConflictCheckDialog(
                              context: context,
                              ajuan: currentAj,
                            ),
                            child: const Text('Cek Jadwal Bentrok', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600)),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: OutlinedButton(
                            style: OutlinedButton.styleFrom(
                              foregroundColor: const Color(0xFF334155),
                              backgroundColor: const Color(0xFFF8FAFC),
                              side: const BorderSide(color: Color(0xFFE2E8F0)),
                              padding: const EdgeInsets.symmetric(vertical: 12),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                            ),
                            onPressed: () => AjuanPengajaranDialogs.showDetailDialog(
                              context: context,
                              ajuan: currentAj,
                              currentRole: 'admin',
                              onRefresh: widget.onRefresh,
                            ),
                            child: const Text('Detail Pengajuan', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600)),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        Expanded(
                          child: OutlinedButton(
                            style: OutlinedButton.styleFrom(
                              foregroundColor: const Color(0xFFBE123C), // rose-700
                              backgroundColor: const Color(0xFFFFF1F2), // rose-50
                              side: const BorderSide(color: Color(0xFFFDA4AF)), // rose-300
                              padding: const EdgeInsets.symmetric(vertical: 12),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                            ),
                            onPressed: () {
                              AjuanPengajaranDialogs.showRejectDialog(
                                context: context,
                                ajuan: currentAj,
                                role: 'admin',
                                onConfirmReject: (alasan) async {
                                  await widget.api.adminRejectAjuan(currentAj.id, alasan);
                                  widget.onRefresh();
                                },
                              );
                            },
                            child: const Text('Tolak Jadwal', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600)),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: ElevatedButton(
                            style: ElevatedButton.styleFrom(
                              backgroundColor: AppColors.primary,
                              foregroundColor: Colors.white,
                              padding: const EdgeInsets.symmetric(vertical: 12),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                              elevation: 2,
                            ),
                            onPressed: currentAj.status == 'disetujui_admin'
                                ? null
                                : () async {
                                    if (currentAj.status == 'bentrok_terdeteksi') {
                                      _showConflictWarning(context, currentAj, currentAj.bentrokDetail ?? 'Terdeteksi konflik jadwal.');
                                      return;
                                    }
                                    final conflict = widget.api.checkBuildingConflict(currentAj);
                                    if (conflict['hasConflict'] == true) {
                                      _showConflictWarning(context, currentAj, conflict['message'] ?? 'Terdeteksi bentrok ruangan/gedung.');
                                      return;
                                    }
                                    await widget.api.adminApproveFinalAjuan(currentAj.id);
                                    widget.onRefresh();
                                    if (context.mounted) {
                                      ScaffoldMessenger.of(context).showSnackBar(
                                        const SnackBar(
                                          content: Text('Jadwal RESMI DISETUJUI & diterbitkan!'),
                                          backgroundColor: AppColors.primary,
                                        ),
                                      );
                                    }
                                  },
                            child: Text(
                              currentAj.status == 'disetujui_admin' ? 'Jadwal Resmi' : 'Setujui Jadwal',
                              style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
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
