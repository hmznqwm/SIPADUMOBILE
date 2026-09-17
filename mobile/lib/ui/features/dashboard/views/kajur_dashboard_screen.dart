// File: kajur_dashboard_screen.dart
// Deskripsi: Tampilan (View) dashboard khusus Ketua Program Studi (KaProdi / KaJur).
// Fungsi: Tinjauan ringkas statistik prodi, otomasi jadwal CSP internal prodi, dan monitoring usulan jadwal dosen.

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../../config/constants.dart';
import '../../../../data/mock/mock_database.dart';
import '../../../../data/models/ajuan_pengajaran_model.dart';
import '../../../../data/services/api_service.dart';
import '../../auth/view_models/auth_view_model.dart';
import '../widgets/csp_confirmation_dialog.dart';

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
  int _totalRuangan = 0;
  int _totalGedung = 0;
  bool _isLoading = true;
  bool _isEngineRunning = false;
  String _jurusanNama = 'Teknik Informatika';

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
      if (user != null && user.jurusanNama.isNotEmpty) {
        _jurusanNama = user.jurusanNama;
      }

      await MockDatabase.initLocalCache(forceReload: true);

      final api = context.read<ApiService>();
      final allAjuan = await api.getAjuanPengajaranList();
      final prodiAjuan = allAjuan.where((a) => a.jurusanNama == _jurusanNama).toList();

      // ── Dosen: baca dari master data user (bukan dari ajuan) ──
      final allUsers = await api.getAllUsers();
      final prodiDosen = allUsers.where((u) {
        if (u.role != 'dosen' && u.role != 'kajur') return false;
        final uJur = u.jurusanNama.toLowerCase();
        final targetJur = _jurusanNama.toLowerCase();
        return uJur.contains(targetJur) || targetJur.contains(uJur);
      }).toList();

      // ── Ruangan & Gedung: baca dari master data ruangan ──
      final allRuangan = await api.getRuanganList();
      final effectiveRuangan = allRuangan.isNotEmpty ? allRuangan : MockDatabase.ruanganList;
      final allGedung = await api.getGedungList();
      final effectiveGedung = allGedung.isNotEmpty ? allGedung : MockDatabase.gedungList;

      // ── Matkul: baca dari matkulData master (bukan dari ajuan) ──
      final prodiMatkul = MockDatabase.matkulData.where((m) {
        final jur = (m['jurusan'] ?? m['jurusanNama'] ?? '').toString().toLowerCase();
        final targetJur = _jurusanNama.toLowerCase();
        if (jur.isEmpty) return true; // jika belum diset jurusannya, tampilkan juga
        return jur.contains(targetJur) || targetJur.contains(jur);
      }).toList();

      // ── Kelas/Rombel: ambil semua kelas unik dari field 'kelas' tiap matkul prodi ──
      final Set<String> kelasSet = {};
      for (final m in prodiMatkul) {
        final kelasList = m['kelas'];
        if (kelasList is List) {
          for (final k in kelasList) {
            final kStr = k.toString().trim();
            if (kStr.isNotEmpty) kelasSet.add(kStr);
          }
        }
      }

      debugPrint('KAPRODI_DEBUG: _jurusanNama=$_jurusanNama, allUsers=${allUsers.length}, prodiDosen=${prodiDosen.length}, matkulData=${MockDatabase.matkulData.length}, prodiMatkul=${prodiMatkul.length}, kelasSet=${kelasSet.length}');

      if (mounted) {
        setState(() {
          _prodiAjuanList = prodiAjuan;
          _totalDosen = prodiDosen.length;
          _totalMatkul = prodiMatkul.length;
          _totalKelas = kelasSet.length;
          _totalRuangan = effectiveRuangan.length;
          _totalGedung = effectiveGedung.length;
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

  Future<void> _runProdiCSPEngine() async {
    final confirm = await CspConfirmationDialog.show(
      context,
      scopeTitle: 'Program Studi $_jurusanNama',
      scopeDescription:
          'Engine SCP prodi akan menyelaraskan ajuan jadwal dosen internal $_jurusanNama sebelum diajukan ke Dekan.',
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

    final totalAjuan = _prodiAjuanList.length;
    final pendingAjuan = _prodiAjuanList.where((a) => a.status == 'menunggu_kaprodi' || a.status == 'menunggu_verifikasi').toList();
    final pendingCount = pendingAjuan.length;
    final approvedCount = _prodiAjuanList.where((a) => a.status == 'menunggu_dekan' || a.status == 'menunggu_admin' || a.status == 'disetujui_admin').length;
    final finalizedCount = _prodiAjuanList.where((a) => a.status == 'disetujui_admin').length;

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
              Wrap(
                alignment: WrapAlignment.spaceBetween,
                crossAxisAlignment: WrapCrossAlignment.center,
                spacing: 8,
                runSpacing: 6,
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
                        Icon(Icons.school_rounded, color: Colors.white, size: 11),
                        SizedBox(width: 4),
                        Text(
                          'KETUA PRODI / KAPRODI',
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
                    child: Text(
                      '$_jurusanNama Aktif',
                      style: const TextStyle(
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
                'Program Studi $_jurusanNama',
                style: const TextStyle(
                  color: AppColors.textPrimary,
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  letterSpacing: -0.2,
                ),
              ),
              const SizedBox(height: 2),
              const Text(
                'Ringkasan data akademik dan koordinasi usulan jadwal program studi.',
                style: TextStyle(
                  color: AppColors.textSecondary,
                  fontSize: 11.5,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 12),

        // ── 2. Data Akademik Program Studi ──
        const Text(
          'Data Akademik Jurusan',
          style: TextStyle(
            fontSize: 13.5,
            fontWeight: FontWeight.bold,
            color: AppColors.textPrimary,
          ),
        ),
        const SizedBox(height: 8),
        _buildMetricCard(
          title: 'Jumlah Pengajar',
          value: '$_totalDosen Pengajar',
          subtitle: 'Dosen Aktif $_jurusanNama',
          icon: Icons.people_alt_outlined,
          color: AppColors.primary,
          bg: const Color(0xFFF0FDFA),
        ),
        _buildMetricCard(
          title: 'Jumlah Mata Kuliah',
          value: '$_totalMatkul Matkul',
          subtitle: 'Mata Kuliah $_jurusanNama',
          icon: Icons.menu_book_rounded,
          color: AppColors.primary,
          bg: const Color(0xFFF0FDFA),
        ),
        _buildMetricCard(
          title: 'Jumlah Kelas / Rombel',
          value: '$_totalKelas Kelas',
          subtitle: 'Kelas Aktif Semester Ini',
          icon: Icons.class_outlined,
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

        // ── 3. Statistik Usulan Jadwal Prodi ──
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
          subtitle: 'Total Ajuan $_jurusanNama',
          icon: Icons.list_alt_rounded,
          color: AppColors.primary,
          bg: const Color(0xFFF0FDFA),
        ),
        _buildMetricCard(
          title: 'Menunggu KaProdi',
          value: '$pendingCount Ajuan',
          subtitle: 'Perlu Persetujuan',
          icon: Icons.pending_actions_rounded,
          color: AppColors.primary,
          bg: const Color(0xFFF0FDFA),
        ),
        _buildMetricCard(
          title: 'Disetujui KaProdi',
          value: '$approvedCount Ajuan',
          subtitle: 'Diteruskan ke Dekan',
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
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Otomasi Jadwal (CSP)',
                      style: TextStyle(
                        fontSize: 12.5,
                        fontWeight: FontWeight.bold,
                        color: AppColors.primary,
                      ),
                    ),
                    Text(
                      'Penyelarasan jadwal internal $_jurusanNama',
                      style: const TextStyle(
                        fontSize: 10.5,
                        color: AppColors.textSecondary,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
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
                onPressed: _isEngineRunning ? null : _runProdiCSPEngine,
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
