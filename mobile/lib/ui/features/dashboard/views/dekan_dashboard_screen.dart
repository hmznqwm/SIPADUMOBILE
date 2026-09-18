// File: dekan_dashboard_screen.dart
// Deskripsi: Tampilan (View) dashboard eksekutif khusus Dekan / Pimpinan Fakultas.
// Fungsi: Tinjauan ringkas statistik fakultas, otomasi jadwal CSP fakultas, aksi cepat navigasi, dan preview usulan menunggu persetujuan.

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../../config/constants.dart';
import '../../../../data/mock/mock_database.dart';
import '../../../../data/models/ajuan_pengajaran_model.dart';
import '../../../../data/models/mata_kuliah_model.dart';
import '../../../../data/services/api_service.dart';
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
  int _totalRuangan = 0;
  int _totalGedung = 0;
  bool _isLoading = true;
  bool _isEngineRunning = false;
  String _fakultasNama = 'Fakultas Sains & Teknologi';

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
      if (user != null && user.fakultasNama.isNotEmpty && user.fakultasNama != 'Universitas') {
        _fakultasNama = user.fakultasNama;
      }

      final api = context.read<ApiService>();
      await MockDatabase.initLocalCache(forceReload: true);

      final allAjuan = await api.getAjuanPengajaranList();
      final fstAjuan = allAjuan.where((a) => _matchFakultas(a.fakultasNama, _fakultasNama)).toList();

      // ── Dosen: baca dari master data user (bukan dari ajuan) ──
      final allUsers = await api.getAllUsers();
      final fstDosen = allUsers.where((u) {
        if (u.role != 'dosen' && u.role != 'kajur') return false;
        return _matchFakultas(u.fakultasNama, _fakultasNama);
      }).toList();

      // ── Ruangan & Gedung: baca dari master data ──
      final allRuangan = await api.getRuanganList();
      final effectiveRuangan = allRuangan.isNotEmpty ? allRuangan : MockDatabase.ruanganList;
      final allGedung = await api.getGedungList();
      final effectiveGedung = allGedung.isNotEmpty ? allGedung : MockDatabase.gedungList;

      // ── Matkul: baca dari live getAllMataKuliah() Supabase/Backend ──
      final allMatkul = await api.getAllMataKuliah();
      final effectiveMatkul = allMatkul.isNotEmpty
          ? allMatkul
          : MockDatabase.matkulData.map((m) => MataKuliahModel.fromJson(m)).toList();
      final fstMatkul = effectiveMatkul.where((m) => _matchFakultas(m.fakultasNama, _fakultasNama)).toList();

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
      if (jurusanSet.isEmpty) jurusanSet.add('Teknik Informatika');

      if (mounted) {
        setState(() {
          _facultyAjuanList = fstAjuan;
          _totalDosen = fstDosen.length;
          _totalMatkul = fstMatkul.length;
          _totalJurusan = jurusanSet.length;
          _totalRuangan = effectiveRuangan.length;
          _totalGedung = effectiveGedung.length;
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
    if (_facultyAjuanList.isEmpty) return true;
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

  Widget _buildMetricCard({
    required String title,
    required String value,
    required String subtitle,
    required IconData icon,
    required Color color,
    required Color bg,
  }) {
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFE2E8F0), width: 1.1),
        boxShadow: const [
          BoxShadow(
            color: Color(0x04000000),
            blurRadius: 3,
            offset: Offset(0, 1),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: bg,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(
              icon,
              color: color,
              size: 20,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF0F172A),
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 1),
                Text(
                  subtitle,
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
          const SizedBox(width: 8),
          Container(
            width: 105,
            alignment: Alignment.center,
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
            decoration: BoxDecoration(
              color: bg,
              borderRadius: BorderRadius.circular(6),
              border: Border.all(color: color.withValues(alpha: 0.25)),
            ),
            child: Text(
              value,
              textAlign: TextAlign.center,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w800,
                color: color,
              ),
            ),
          ),
        ],
      ),
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
    final finalizedCount = _facultyAjuanList.where((a) => a.status == 'disetujui_admin').length;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // ── 1. Executive Header Card ──
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(AppSpacing.md),
          decoration: BoxDecoration(
            color: AppColors.surfaceVariant,
            borderRadius: BorderRadius.circular(AppRadius.md),
            border: Border.all(color: AppColors.primary.withValues(alpha: 0.25)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                    decoration: BoxDecoration(
                      color: AppColors.primary,
                      borderRadius: BorderRadius.circular(AppRadius.full),
                    ),
                    child: const Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.account_balance_rounded, color: Colors.white, size: 11),
                        SizedBox(width: 4),
                        Text(
                          'DEKAN FAKULTAS',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 9.5,
                            fontWeight: FontWeight.bold,
                            letterSpacing: 0.5,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2.5),
                    decoration: BoxDecoration(
                      color: const Color(0xFFECFDF5),
                      borderRadius: BorderRadius.circular(AppRadius.sm),
                      border: Border.all(color: const Color(0xFFA7F3D0)),
                    ),
                    child: const Text(
                      'FST Aktif',
                      style: TextStyle(
                        color: Color(0xFF047857),
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Text(
                _fakultasNama,
                style: const TextStyle(
                  color: AppColors.textPrimary,
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  letterSpacing: -0.2,
                ),
              ),
              const SizedBox(height: 2),
              const Text(
                'Ringkasan data akademik dan koordinasi usulan jadwal fakultas.',
                style: TextStyle(
                  color: AppColors.textSecondary,
                  fontSize: 11.5,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 12),

        // ── 2. Data Akademik Fakultas FST ──
        const Text(
          'Data Akademik Fakultas',
          style: TextStyle(
            fontSize: 13.5,
            fontWeight: FontWeight.bold,
            color: AppColors.textPrimary,
          ),
        ),
        const SizedBox(height: 8),
        _buildMetricCard(
          title: 'Jumlah Jurusan',
          value: '$_totalJurusan Jurusan',
          subtitle: 'Program Studi FST',
          icon: Icons.account_tree_outlined,
          color: AppColors.primary,
          bg: const Color(0xFFF0FDFA),
        ),
        _buildMetricCard(
          title: 'Jumlah Pengajar',
          value: '$_totalDosen Pengajar',
          subtitle: 'Dosen Aktif FST',
          icon: Icons.people_alt_outlined,
          color: AppColors.primary,
          bg: const Color(0xFFF0FDFA),
        ),
        _buildMetricCard(
          title: 'Jumlah Mata Kuliah',
          value: '$_totalMatkul Matkul',
          subtitle: 'Mata Kuliah FST',
          icon: Icons.menu_book_rounded,
          color: AppColors.primary,
          bg: const Color(0xFFF0FDFA),
        ),
        _buildMetricCard(
          title: 'Ruangan & Kelas Kampus',
          value: '$_totalRuangan Ruang Kelas',
          subtitle: '$_totalGedung Gedung Terdaftar',
          icon: Icons.door_sliding_outlined,
          color: AppColors.primary,
          bg: const Color(0xFFF0FDFA),
        ),
        const SizedBox(height: 12),

        // ── 3. Statistik Usulan Jadwal FST ──
        const Text(
          'Statistik Usulan Jadwal',
          style: TextStyle(
            fontSize: 13.5,
            fontWeight: FontWeight.bold,
            color: AppColors.textPrimary,
          ),
        ),
        const SizedBox(height: 8),
        _buildMetricCard(
          title: 'Total Usulan',
          value: '$totalAjuan Ajuan',
          subtitle: 'Total Ajuan FST',
          icon: Icons.list_alt_rounded,
          color: AppColors.primary,
          bg: const Color(0xFFF0FDFA),
        ),
        _buildMetricCard(
          title: 'Menunggu Dekan',
          value: '$pendingCount Ajuan',
          subtitle: 'Perlu Persetujuan',
          icon: Icons.pending_actions_rounded,
          color: AppColors.primary,
          bg: const Color(0xFFF0FDFA),
        ),
        _buildMetricCard(
          title: 'Disetujui Dekan',
          value: '$approvedCount Ajuan',
          subtitle: 'Diteruskan ke Admin',
          icon: Icons.fact_check_outlined,
          color: AppColors.primary,
          bg: const Color(0xFFF0FDFA),
        ),
        _buildMetricCard(
          title: 'Final Admin',
          value: '$finalizedCount Ajuan',
          subtitle: 'Jadwal Telah Terbit',
          icon: Icons.check_circle_outline,
          color: AppColors.primary,
          bg: const Color(0xFFF0FDFA),
        ),
        const SizedBox(height: 10),

        // ── 4. Button Otomasi CSP ──
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(AppSpacing.md),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(AppRadius.md),
            border: Border.all(color: const Color(0xFFE2E8F0)),
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
              Container(
                padding: const EdgeInsets.all(7),
                decoration: BoxDecoration(
                  color: AppColors.primary.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(Icons.tune_rounded, color: AppColors.primary, size: 18),
              ),
              const SizedBox(width: 10),
              const Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Otomasi Jadwal (CSP)',
                      style: TextStyle(
                        fontSize: 12.5,
                        fontWeight: FontWeight.bold,
                        color: AppColors.primary,
                      ),
                    ),
                    Text(
                      'Penyelarasan jadwal lintas prodi',
                      style: TextStyle(
                        fontSize: 10.5,
                        color: AppColors.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 6),
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                  elevation: 0,
                ),
                onPressed: _isEngineRunning ? null : _runFacultyCSPEngine,
                child: _isEngineRunning
                    ? const SizedBox(
                        width: 14,
                        height: 14,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Colors.white,
                        ),
                      )
                    : const Text(
                        'Jalankan',
                        style: TextStyle(fontSize: 11.5, fontWeight: FontWeight.bold),
                      ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),
      ],
    );
  }
}
