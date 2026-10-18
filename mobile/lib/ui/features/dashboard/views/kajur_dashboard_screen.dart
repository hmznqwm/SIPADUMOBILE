// File: kajur_dashboard_screen.dart
// Deskripsi: Tampilan (View) dashboard khusus Ketua Program Studi (KaProdi / KaJur).
// Fungsi: Tinjauan ringkas statistik prodi, otomasi jadwal CSP internal prodi, dan monitoring usulan jadwal dosen.

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../../config/constants.dart';
import '../../../../data/mock/mock_database.dart';
import '../../../../data/models/ajuan_pengajaran_model.dart';
import '../../../../data/services/api_service.dart';
import '../../../core/widgets/wave_header_card.dart';
import '../../auth/view_models/auth_view_model.dart';
import '../widgets/csp_confirmation_dialog.dart';

/// [PRESENTASI] KaProdiDashboardView (Role Base UI):
/// Tampilan spesifik untuk Ketua Program Studi.
/// Dilengkapi dengan fitur pemanggilan otomatis Engine CSP (Constraint Satisfaction Problem)
/// yang berjalan di Backend (Python FastAPI) untuk merapikan jadwal secara internal.
class KaProdiDashboardView extends StatefulWidget {
  final Function(int)? onNavigateToTab;

  const KaProdiDashboardView({super.key, this.onNavigateToTab});

  @override
  State<KaProdiDashboardView> createState() => _KaProdiDashboardViewState();
}

class _KaProdiDashboardViewState extends State<KaProdiDashboardView> {
  List<AjuanPengajaranModel> _prodiAjuanList = [];
  int _totalDosen = 0;
  int _totalMatkul = 0;
  int _totalKelas = 0;
  bool _isLoading = true;
  bool _isEngineRunning = false;
  String _jurusanNama = '';

  @override
  void initState() {
    super.initState();
    _loadKaProdiData();
  }

  Future<void> _loadKaProdiData() async {
    if (!mounted) return;
    setState(() => _isLoading = true);
    try {
      final user = context.read<AuthViewModel>().currentUser;
      _jurusanNama = user?.jurusanNama ?? '';

      final api = context.read<ApiService>();
      await MockDatabase.initLocalCache(forceReload: true);

      final allAjuan = await api.getAjuanPengajaranList();
      final prodiAjuan = allAjuan.where((a) {
        final ajJur = a.jurusanNama.toLowerCase();
        final targetJur = _jurusanNama.toLowerCase();
        return ajJur.contains(targetJur) || targetJur.contains(ajJur);
      }).toList();

      // ── Dosen: baca dari master data user (bukan dari ajuan) ──
      final allUsers = await api.getAllUsers();
      final prodiDosen = allUsers.where((u) {
        if (MockDatabase.deletedUserIds.contains(u.id) ||
            MockDatabase.deletedUserIds.contains(u.nama) ||
            MockDatabase.deletedUserIds.contains(u.email)) {
          return false;
        }
        if (u.role != 'dosen' && u.role != 'kajur') return false;
        final uJur = u.jurusanNama.toLowerCase();
        final targetJur = _jurusanNama.toLowerCase();
        return uJur.contains(targetJur) || targetJur.contains(uJur);
      }).toList();

      // ── Matkul: baca dari live getAllMataKuliah() Supabase/Backend ──
      final allMatkul = await api.getAllMataKuliah();
      final effectiveMatkul = allMatkul;
      final prodiMatkul = effectiveMatkul.where((m) {
        if (MockDatabase.deletedMatkulIds.contains(m.id) ||
            MockDatabase.deletedMatkulIds.contains(m.nama)) {
          return false;
        }
        final jur = m.jurusanNama.toLowerCase();
        final targetJur = _jurusanNama.toLowerCase();
        if (jur.isEmpty) return true;
        return jur.contains(targetJur) || targetJur.contains(jur);
      }).toList();

      // ── Kelas/Rombel: ambil semua kelas unik dari field kelasNama tiap matkul prodi ──
      final Set<String> kelasSet = {};
      for (final m in prodiMatkul) {
        for (final k in m.kelasNama) {
          final kStr = k.trim();
          if (kStr.isNotEmpty) kelasSet.add(kStr);
        }
      }

      debugPrint('KAPRODI_DEBUG: _jurusanNama=$_jurusanNama, allUsers=${allUsers.length}, prodiDosen=${prodiDosen.length}, effectiveMatkul=${effectiveMatkul.length}, prodiMatkul=${prodiMatkul.length}, kelasSet=${kelasSet.length}');

      if (mounted) {
        setState(() {
          _prodiAjuanList = prodiAjuan;
          _totalDosen = prodiDosen.length;
          _totalMatkul = prodiMatkul.length;
          _totalKelas = kelasSet.length;
        });
      }
    } catch (e) {
      debugPrint('Error loading KaProdi data: $e');
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  bool get _isProdiAllApprovedAndConflictFree {
    if (_prodiAjuanList.isEmpty) return false;
    final unapprovedOrPending = _prodiAjuanList.where((a) =>
        a.status != 'disetujui_admin' &&
        a.status != 'disetujui' &&
        a.status != 'banding_disetujui');
    final bentrok = _prodiAjuanList.where((a) =>
        a.status == 'bentrok_terdeteksi' ||
        (a.bentrokDetail != null && a.bentrokDetail!.trim().isNotEmpty));
    return unapprovedOrPending.isEmpty && bentrok.isEmpty;
  }

  Future<void> _runProdiCSPEngine() async {
    if (_prodiAjuanList.isEmpty) return;
    if (_isProdiAllApprovedAndConflictFree) {
      final forceRun = await showModalBottomSheet<bool>(
        context: context,
        backgroundColor: Colors.white,
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        ),
        builder: (ctx) => Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
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
              const SizedBox(height: 16),
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: AppColors.surfaceVariant,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Icon(
                      Icons.check_circle_rounded,
                      color: AppColors.primary,
                      size: 26,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Jadwal Prodi Rapi & Optimal',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF0F172A),
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          'Prodi $_jurusanNama (0 Bentrok)',
                          style: const TextStyle(fontSize: 12, color: AppColors.primary, fontWeight: FontWeight.w600),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: const Color(0xFFF8FAFC),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: const Color(0xFFE2E8F0)),
                ),
                child: Text(
                  'Seluruh pengajuan dosen internal Program Studi $_jurusanNama telah disetujui dan 0 bentrok terdeteksi. Tidak ada jadwal yang perlu dirapikan oleh Engine CSP.',
                  style: const TextStyle(fontSize: 12.5, color: Color(0xFF334155), height: 1.45),
                ),
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
                      onPressed: () => Navigator.pop(ctx, false),
                      child: const Text(
                        'Tutup',
                        style: TextStyle(color: Color(0xFF475569), fontWeight: FontWeight.bold, fontSize: 13),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primary,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                        elevation: 0,
                      ),
                      onPressed: () => Navigator.pop(ctx, true),
                      child: const Text(
                        'Tetap Re-Generate',
                        style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12.5),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      );

      if (forceRun != true || !mounted) return;
    }

    final confirm = await CspConfirmationDialog.show(
      context,
      scopeTitle: 'Program Studi $_jurusanNama',
      scopeDescription:
          'Engine CSP prodi akan menyelaraskan ajuan jadwal dosen internal $_jurusanNama sebelum diajukan ke Dekan.',
      roleLabel: 'Ketua Program Studi (KaProdi)',
    );
    if (confirm != true || !mounted) return;

    setState(() => _isEngineRunning = true);
    try {
      final api = context.read<ApiService>();
      final report = await api.runSmartCspEngineWithAutoApproval(
        scope: 'jurusan',
        jurusanNama: _jurusanNama,
        role: 'kajur',
      );
      await _loadKaProdiData();

      if (mounted) {
        setState(() => _isEngineRunning = false);
        final approved = report['approvedCount'] ?? 0;
        final conflicts = report['conflictCount'] ?? 0;
        final submittedDosen = report['submittedLecturersCount'] ?? 0;
        final autoDosen = report['autoAllocatedLecturersCount'] ?? 0;

        showDialog(
          context: context,
          builder: (ctx) => AlertDialog(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(14),
              side: const BorderSide(color: Color(0xFFE2E8F0)),
            ),
            backgroundColor: Colors.white,
            titlePadding: const EdgeInsets.fromLTRB(18, 16, 18, 8),
            contentPadding: const EdgeInsets.symmetric(horizontal: 18),
            actionsPadding: const EdgeInsets.fromLTRB(16, 10, 16, 14),
            title: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(7),
                  decoration: BoxDecoration(
                    color: AppColors.primary.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Icon(Icons.check_circle_outline_rounded, color: AppColors.primary, size: 20),
                ),
                const SizedBox(width: 10),
                const Expanded(
                  child: Text(
                    'Penyelarasan Selesai',
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.bold,
                      color: AppColors.textPrimary,
                    ),
                  ),
                ),
              ],
            ),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Jadwal Program Studi $_jurusanNama telah diselaraskan dan diteruskan ke Dekan.',
                  style: const TextStyle(fontSize: 12, color: Color(0xFF64748B), height: 1.35),
                ),
                const SizedBox(height: 12),
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF8FAFC),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: const Color(0xFFE2E8F0)),
                  ),
                  child: Column(
                    children: [
                      _buildDialogRow('Kelas Terjadwal', '$approved Kelas', AppColors.primary),
                      const Divider(height: 10, color: Color(0xFFE2E8F0)),
                      _buildDialogRow('Sesuai Ajuan', '$submittedDosen Dosen', const Color(0xFF0F766E)),
                      const Divider(height: 10, color: Color(0xFFE2E8F0)),
                      _buildDialogRow('Alokasi Ruang', '$autoDosen Dosen', const Color(0xFF334155)),
                      const Divider(height: 10, color: Color(0xFFE2E8F0)),
                      _buildDialogRow('Bentrok', '$conflicts', conflicts > 0 ? const Color(0xFFDC2626) : const Color(0xFF16A34A)),
                    ],
                  ),
                ),
              ],
            ),
            actions: [
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () => Navigator.pop(ctx),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    foregroundColor: Colors.white,
                    elevation: 0,
                    padding: const EdgeInsets.symmetric(vertical: 10),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                  ),
                  child: const Text('Tutup', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12.5)),
                ),
              ),
            ],
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isEngineRunning = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Gagal menjalankan optimasi prodi: $e'), backgroundColor: const Color(0xFFDC2626)),
        );
      }
    }
  }

  Widget _buildDialogRow(String label, String value, Color valColor) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label, style: const TextStyle(fontSize: 11.5, color: Color(0xFF64748B))),
        Text(value, style: TextStyle(fontSize: 11.5, fontWeight: FontWeight.bold, color: valColor)),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Padding(
        padding: EdgeInsets.symmetric(vertical: 48),
        child: Center(
          child: CircularProgressIndicator(
            color: AppColors.primary,
            strokeWidth: 3,
          ),
        ),
      );
    }

    final totalAjuan = _prodiAjuanList.length;
    final pendingAjuan = _prodiAjuanList.where((a) => a.status == 'menunggu_kaprodi' || a.status == 'menunggu_verifikasi').toList();
    final pendingCount = pendingAjuan.length;
    final approvedCount = _prodiAjuanList.where((a) => a.status == 'menunggu_dekan' || a.status == 'menunggu_admin' || a.status == 'disetujui_admin').length;

    final double ratioMenunggu = totalAjuan > 0 ? (pendingCount / totalAjuan) : 0.0;
    final double ratioDisetujui = totalAjuan > 0 ? (approvedCount / totalAjuan) : 1.0;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // ── 1. Executive Header Card (Split Wave 2-Warna) ──
        WaveHeaderCard(
          showBrand: true,
          title: 'Program Studi $_jurusanNama',
          subtitle: 'Ringkasan data akademik dan koordinasi usulan jadwal program studi.',
        ),
        const SizedBox(height: 12),

        // ── 2. Section Title ──
        const Text(
          'Statistik Program Studi',
          style: TextStyle(
            fontSize: 15,
            fontWeight: FontWeight.bold,
            color: AppColors.textPrimary,
            letterSpacing: -0.2,
          ),
        ),
        const SizedBox(height: 10),

        // ── 3. Hero Card: Usulan Jadwal Prodi (Clean White Card with Line Comparison Bar) ──
        Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: const Color(0xFFE2E8F0)),
            boxShadow: const [
              BoxShadow(
                color: Color(0x05000000),
                blurRadius: 4,
                offset: Offset(0, 2),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Usulan Jadwal Prodi',
                style: TextStyle(
                  color: Color(0xFF0F172A),
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                  letterSpacing: -0.1,
                ),
              ),
              const SizedBox(height: 10),

              // Baris Perbandingan Garis (Visual Comparison Bar)
              ClipRRect(
                borderRadius: BorderRadius.circular(6),
                child: SizedBox(
                  height: 6,
                  child: Row(
                    children: [
                      Expanded(
                        flex: totalAjuan == 0 ? 50 : (ratioMenunggu * 100).toInt().clamp(1, 99),
                        child: Container(color: AppColors.primary),
                      ),
                      const SizedBox(width: 2),
                      Expanded(
                        flex: totalAjuan == 0 ? 50 : (ratioDisetujui * 100).toInt().clamp(1, 99),
                        child: Container(color: const Color(0xFFE2E8F0)),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 12),

              // Keterangan Jumlah Menunggu vs Disetujui
              Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Container(
                              width: 7,
                              height: 7,
                              decoration: const BoxDecoration(
                                color: AppColors.primary,
                                shape: BoxShape.circle,
                              ),
                            ),
                            const SizedBox(width: 6),
                            const Text(
                              'Menunggu KaProdi',
                              style: TextStyle(
                                color: Color(0xFF64748B),
                                fontSize: 11.5,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 3),
                        Text(
                          '$pendingCount Ajuan',
                          style: const TextStyle(
                            color: Color(0xFF0F172A),
                            fontSize: 17,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Container(
                    width: 1,
                    height: 28,
                    color: const Color(0xFFE2E8F0),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Container(
                              width: 7,
                              height: 7,
                              decoration: const BoxDecoration(
                                color: Color(0xFF94A3B8),
                                shape: BoxShape.circle,
                              ),
                            ),
                            const SizedBox(width: 6),
                            const Text(
                              'Disetujui / Final',
                              style: TextStyle(
                                color: Color(0xFF64748B),
                                fontSize: 11.5,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 3),
                        Text(
                          '$approvedCount Ajuan',
                          style: const TextStyle(
                            color: Color(0xFF0F172A),
                            fontSize: 17,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
        const SizedBox(height: 10),

        // ── 4. Row 1: 2 White Cards (Dosen & Mata Kuliah) ──
        Row(
          children: [
            Expanded(
              child: _buildWhiteBentoCard(
                title: 'Dosen',
                count: '$_totalDosen',
                subtitle: 'Dosen Aktif',
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: _buildWhiteBentoCard(
                title: 'Mata Kuliah',
                count: '$_totalMatkul',
                subtitle: 'Mata Kuliah',
              ),
            ),
          ],
        ),
        const SizedBox(height: 10),

        // ── 5. Row 2: 2 White Cards (Kelas / Rombel & Total Usulan) ──
        Row(
          children: [
            Expanded(
              child: _buildWhiteBentoCard(
                title: 'Kelas/Rombel',
                count: '$_totalKelas',
                subtitle: 'Rombel Aktif',
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: _buildWhiteBentoCard(
                title: 'Total Usulan',
                count: '$totalAjuan',
                subtitle: 'Total Ajuan',
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),

        // ── 4. Button Otomasi CSP ──
        Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
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
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Container(
                width: 38,
                height: 38,
                decoration: BoxDecoration(
                  color: const Color(0xFFF1F5F9),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(
                  Icons.settings_outlined,
                  color: Color(0xFF64748B),
                  size: 20,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Engine CSP',
                      style: TextStyle(
                        fontSize: 13.5,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF0F172A),
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      _prodiAjuanList.isEmpty
                          ? 'Belum ada ajuan di $_jurusanNama'
                          : _isProdiAllApprovedAndConflictFree
                              ? 'Jadwal Rapi & Optimal'
                              : 'Penyelarasan internal $_jurusanNama',
                      style: const TextStyle(
                        fontSize: 11,
                        color: Color(0xFF64748B),
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 10),
              SizedBox(
                width: 90,
                height: 34,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: _prodiAjuanList.isEmpty
                        ? const Color(0xFFF1F5F9)
                        : _isProdiAllApprovedAndConflictFree
                            ? const Color(0xFF0F766E)
                            : AppColors.primary,
                    foregroundColor: _prodiAjuanList.isEmpty
                        ? const Color(0xFF94A3B8)
                        : Colors.white,
                    elevation: 0,
                    padding: EdgeInsets.zero,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  onPressed: (_prodiAjuanList.isEmpty || _isEngineRunning)
                      ? null
                      : _runProdiCSPEngine,
                  child: _isEngineRunning
                      ? const SizedBox(
                          width: 14,
                          height: 14,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Colors.white,
                          ),
                        )
                      : Text(
                          _prodiAjuanList.isEmpty
                              ? 'Data Kosong'
                              : _isProdiAllApprovedAndConflictFree
                                  ? 'Jadwal Rapi'
                                  : 'Jalankan',
                          style: TextStyle(
                            fontSize: _prodiAjuanList.isEmpty ? 11 : 12,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),
      ],
    );
  }

  Widget _buildWhiteBentoCard({
    required String title,
    required String count,
    required String subtitle,
  }) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE2E8F0)),
        boxShadow: const [
          BoxShadow(
            color: Color(0x05000000),
            blurRadius: 4,
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              color: Color(0xFF1E293B),
              fontSize: 12.5,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            count,
            style: const TextStyle(
              color: Color(0xFF0F172A),
              fontSize: 24,
              fontWeight: FontWeight.w800,
              letterSpacing: -0.5,
              height: 1.1,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            subtitle,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              color: Color(0xFF64748B),
              fontSize: 11,
            ),
          ),
        ],
      ),
    );
  }
}
