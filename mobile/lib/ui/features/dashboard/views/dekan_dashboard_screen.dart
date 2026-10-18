// File: dekan_dashboard_screen.dart
// Deskripsi: Tampilan (View) dashboard eksekutif khusus Dekan / Pimpinan Fakultas.
// Fungsi: Tinjauan ringkas statistik fakultas, otomasi jadwal CSP fakultas, aksi cepat navigasi, dan preview usulan menunggu persetujuan.

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../../config/constants.dart';
import '../../../../data/mock/mock_database.dart';
import '../../../../data/models/ajuan_pengajaran_model.dart';
import '../../../../data/services/api_service.dart';
import '../../../core/widgets/wave_header_card.dart';
import '../../auth/view_models/auth_view_model.dart';
import '../widgets/csp_confirmation_dialog.dart';

class DekanDashboardView extends StatefulWidget {
  final Function(int)? onNavigateToTab;

  const DekanDashboardView({super.key, this.onNavigateToTab});

  @override
  State<DekanDashboardView> createState() => _DekanDashboardViewState();
}

class _DekanDashboardViewState extends State<DekanDashboardView> {
  List<AjuanPengajaranModel> _facultyAjuanList = [];
  int _totalDosen = 0;
  int _totalMatkul = 0;
  int _totalJurusan = 0;
  bool _isLoading = true;
  bool _isEngineRunning = false;
  String _fakultasNama = '';

  @override
  void initState() {
    super.initState();
    _loadDekanData();
  }

  bool _matchFakultas(String? a, String? b) {
    final na = (a ?? '').toLowerCase().replaceAll('&', 'dan').replaceAll(RegExp(r'\s+'), ' ').trim();
    final nb = (b ?? '').toLowerCase().replaceAll('&', 'dan').replaceAll(RegExp(r'\s+'), ' ').trim();
    if (na.isEmpty || nb.isEmpty) return false;
    return na.contains(nb) || nb.contains(na);
  }

  Future<void> _loadDekanData() async {
    if (!mounted) return;
    setState(() => _isLoading = true);
    try {
      final user = context.read<AuthViewModel>().currentUser;
      _fakultasNama = (user != null && user.fakultasNama != 'Universitas') ? user.fakultasNama : '';

      final api = context.read<ApiService>();
      await MockDatabase.initLocalCache(forceReload: true);

      final allAjuan = await api.getAjuanPengajaranList();
      final fstAjuan = allAjuan.where((a) => _matchFakultas(a.fakultasNama, _fakultasNama)).toList();

      // ── Dosen: baca dari master data user (bukan dari ajuan) ──
      final allUsers = await api.getAllUsers();
      final fstDosen = allUsers.where((u) {
        if (MockDatabase.deletedUserIds.contains(u.id) ||
            MockDatabase.deletedUserIds.contains(u.nama) ||
            MockDatabase.deletedUserIds.contains(u.email)) {
          return false;
        }
        if (u.role != 'dosen' && u.role != 'kajur') return false;
        return _matchFakultas(u.fakultasNama, _fakultasNama);
      }).toList();

      // ── Matkul: baca dari live getAllMataKuliah() Supabase/Backend ──
      final allMatkul = await api.getAllMataKuliah();
      final effectiveMatkul = allMatkul;
      final fstMatkul = effectiveMatkul.where((m) {
        if (MockDatabase.deletedMatkulIds.contains(m.id) ||
            MockDatabase.deletedMatkulIds.contains(m.nama)) {
          return false;
        }
        return _matchFakultas(m.fakultasNama, _fakultasNama);
      }).toList();

      // ── Jurusan: hitung dari jurusan unik di matkul & dosen fakultas ini ──
      final Set<String> jurusanSet = {};
      for (final m in fstMatkul) {
        final jur = m.jurusanNama.trim();
        if (jur.isNotEmpty && jur != 'Semua' && jur != 'GLOBAL') jurusanSet.add(jur);
      }
      for (final d in fstDosen) {
        final jur = d.jurusanNama.trim();
        if (jur.isNotEmpty && jur != 'Semua' && jur != 'GLOBAL') {
          for (final part in jur.split(',')) {
            final clean = part.trim();
            if (clean.isNotEmpty && clean != 'Semua' && clean != 'GLOBAL') jurusanSet.add(clean);
          }
        }
      }

      if (mounted) {
        setState(() {
          _facultyAjuanList = fstAjuan;
          _totalDosen = fstDosen.length;
          _totalMatkul = fstMatkul.length;
          _totalJurusan = jurusanSet.length;
        });
      }
    } catch (e) {
      debugPrint('Error loading Dekan data: $e');
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  bool get _isFacultyAllApprovedAndConflictFree {
    if (_facultyAjuanList.isEmpty) return false;
    final unapprovedOrPending = _facultyAjuanList.where((a) =>
        a.status != 'disetujui_admin' &&
        a.status != 'disetujui' &&
        a.status != 'banding_disetujui');
    final bentrok = _facultyAjuanList.where((a) =>
        a.status == 'bentrok_terdeteksi' ||
        (a.bentrokDetail != null && a.bentrokDetail!.trim().isNotEmpty));
    return unapprovedOrPending.isEmpty && bentrok.isEmpty;
  }

  Future<void> _runFacultyCSPEngine() async {
    if (_facultyAjuanList.isEmpty) return;
    if (_isFacultyAllApprovedAndConflictFree) {
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
                          'Jadwal Fakultas Rapi & Optimal',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF0F172A),
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          '$_fakultasNama (0 Bentrok)',
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
                  'Seluruh pengajuan dosen di lingkungan $_fakultasNama telah disetujui dan 0 bentrok terdeteksi. Tidak ada jadwal yang perlu dirapikan oleh Engine CSP.',
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
      scopeTitle: _fakultasNama,
      scopeDescription:
          'Engine CSP fakultas akan menyelaraskan dan mengoptimasi jadwal perkuliahan seluruh program studi di lingkungan $_fakultasNama.',
      roleLabel: 'Dekan Fakultas',
    );
    if (confirm != true || !mounted) return;

    setState(() => _isEngineRunning = true);
    try {
      final api = context.read<ApiService>();
      final report = await api.runSmartCspEngineWithAutoApproval(
        scope: 'fakultas',
        fakultasNama: _fakultasNama,
        role: 'dekan',
      );
      await _loadDekanData();

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
                const Text(
                  'Jadwal seluruh prodi telah diselaraskan dan diteruskan ke Super Admin.',
                  style: TextStyle(fontSize: 12, color: Color(0xFF64748B), height: 1.35),
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
          SnackBar(content: Text('Gagal menjalankan optimasi: $e'), backgroundColor: const Color(0xFFDC2626)),
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

    final totalAjuan = _facultyAjuanList.length;
    final pendingAjuan = _facultyAjuanList.where((a) => a.status == 'menunggu_dekan').toList();
    final pendingCount = pendingAjuan.length;
    final approvedCount = _facultyAjuanList.where((a) => a.status == 'menunggu_admin' || a.status == 'disetujui_admin').length;
    final double ratioMenunggu = totalAjuan > 0 ? (pendingCount / totalAjuan) : 0.0;
    final double ratioDisetujui = totalAjuan > 0 ? (approvedCount / totalAjuan) : 1.0;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // ── 1. Executive Header Card (Split Wave 2-Warna) ──
        WaveHeaderCard(
          showBrand: true,
          title: _fakultasNama,
          subtitle: 'Ringkasan data akademik dan koordinasi usulan jadwal fakultas.',
        ),
        const SizedBox(height: 12),

        // ── 2. Section Title ──
        const Text(
          'Statistik Fakultas',
          style: TextStyle(
            fontSize: 15,
            fontWeight: FontWeight.bold,
            color: AppColors.textPrimary,
            letterSpacing: -0.2,
          ),
        ),
        const SizedBox(height: 10),

        // ── 3. Hero Card: Usulan Jadwal Fakultas (Clean White Card with Line Comparison Bar) ──
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
                'Usulan Jadwal Fakultas',
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
                              'Menunggu Dekan',
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
                              'Diteruskan ke Admin',
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

        // ── 4. Row 1: 2 White Cards (Program Studi & Dosen Fakultas) ──
        Row(
          children: [
            Expanded(
              child: _buildWhiteBentoCard(
                title: 'Program Studi',
                count: '$_totalJurusan',
                subtitle: 'Program Studi',
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: _buildWhiteBentoCard(
                title: 'Dosen Fakultas',
                count: '$_totalDosen',
                subtitle: 'Tenaga Pengajar',
              ),
            ),
          ],
        ),
        const SizedBox(height: 10),

        // ── 5. Row 2: 2 White Cards (Mata Kuliah & Total Usulan) ──
        Row(
          children: [
            Expanded(
              child: _buildWhiteBentoCard(
                title: 'Mata Kuliah',
                count: '$_totalMatkul',
                subtitle: 'Mata Kuliah',
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: _buildWhiteBentoCard(
                title: 'Total Usulan',
                count: '$totalAjuan',
                subtitle: 'Ajuan Fakultas',
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),

        // ── 7. Button Otomasi CSP ──
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
                      _facultyAjuanList.isEmpty
                          ? 'Belum ada ajuan di $_fakultasNama'
                          : _isFacultyAllApprovedAndConflictFree
                              ? 'Jadwal Rapi & Optimal'
                              : 'Penyelarasan seluruh prodi $_fakultasNama',
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
                    backgroundColor: _facultyAjuanList.isEmpty
                        ? const Color(0xFFF1F5F9)
                        : _isFacultyAllApprovedAndConflictFree
                            ? const Color(0xFF0F766E)
                            : AppColors.primary,
                    foregroundColor: _facultyAjuanList.isEmpty
                        ? const Color(0xFF94A3B8)
                        : Colors.white,
                    elevation: 0,
                    padding: EdgeInsets.zero,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  onPressed: (_facultyAjuanList.isEmpty || _isEngineRunning)
                      ? null
                      : _runFacultyCSPEngine,
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
                          _facultyAjuanList.isEmpty
                              ? 'Data Kosong'
                              : _isFacultyAllApprovedAndConflictFree
                                  ? 'Jadwal Rapi'
                                  : 'Jalankan',
                          style: TextStyle(
                            fontSize: _facultyAjuanList.isEmpty ? 11 : 12,
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
