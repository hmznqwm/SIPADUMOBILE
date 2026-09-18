// File: admin_dashboard_screen.dart
// Deskripsi: Tampilan (View) dashboard khusus Super Admin Penjadwalan.
// Fungsi: Ringkasan statistik institusi, eksekusi engine CSP, sakelar window ketersediaan, dan permohonan banding dosen.

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../../config/constants.dart';
import '../../../../data/models/ajuan_pengajaran_model.dart';
import '../../../../data/models/gedung_model.dart';
import '../../../../data/models/jadwal_model.dart';
import '../../../../data/models/ruangan_model.dart';
import '../../../../data/models/user_model.dart';
import '../../../../data/services/api_service.dart';
import '../widgets/admin_automation_section.dart';
import '../widgets/admin_banding_section.dart';
import '../widgets/admin_stat_cards.dart';
import '../widgets/csp_confirmation_dialog.dart';
import '../widgets/csp_execution_result_dialog.dart';

class AdminDashboardView extends StatefulWidget {
  const AdminDashboardView({super.key});

  @override
  State<AdminDashboardView> createState() => _AdminDashboardViewState();
}

class _AdminDashboardViewState extends State<AdminDashboardView> {
  bool _isSubmissionActive = true;
  bool _isEngineRunning = false;
  List<GedungModel> _gedungList = [];
  List<RuanganModel> _ruanganList = [];
  List<UserModel> _allUsersList = [];
  List<AjuanPengajaranModel> _allAjuanList = [];
  List<dynamic> _allMatkulList = [];
  List<JadwalModel> _jadwalList = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadAdminData();
  }

  Future<void> _loadAdminData() async {
    if (!mounted) return;
    setState(() => _isLoading = true);
    try {
      final api = context.read<ApiService>();
      final active = await api.getSubmissionWindowStatus();
      final gedung = await api.getGedungList();
      final ruangan = await api.getRuanganList();
      final users = await api.getAllUsers();
      final ajuan = await api.getAjuanPengajaranList();
      final matkul = await api.getAllMataKuliah();
      final jadwal = await api.getGlobalJadwal();

      if (mounted) {
        setState(() {
          _isSubmissionActive = active;
          _gedungList = gedung;
          _ruanganList = ruangan;
          _allUsersList = users;
          _allAjuanList = ajuan;
          _allMatkulList = matkul;
          _jadwalList = jadwal;
          _isLoading = false;
        });
      }
    } catch (_) {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _toggleSubmissionStatus(bool value) async {
    final api = context.read<ApiService>();
    try {
      await api.setSubmissionWindowStatus(value);
      setState(() => _isSubmissionActive = value);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Gagal mengubah status: ${e.toString()}'),
            backgroundColor: AppColors.error,
          ),
        );
        // Force the switch to snap back to its previous state
        setState(() {});
      }
    }
  }

  bool get _isAllApprovedAndConflictFree {
    if (_allAjuanList.isEmpty) return true;
    final unapprovedOrPending = _allAjuanList.where((a) =>
        a.status != 'disetujui_admin' &&
        a.status != 'disetujui' &&
        a.status != 'banding_disetujui');
    final bentrok = _allAjuanList.where((a) =>
        a.status == 'bentrok_terdeteksi' ||
        (a.bentrokDetail != null && a.bentrokDetail!.trim().isNotEmpty));
    return unapprovedOrPending.isEmpty && bentrok.isEmpty;
  }

  Future<void> _runCSPEngine() async {
    if (_isAllApprovedAndConflictFree) {
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
                  const Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Jadwal Sudah Rapi & Optimal',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF0F172A),
                          ),
                        ),
                        SizedBox(height: 2),
                        Text(
                          'Tidak ada jadwal yang perlu dirapikan',
                          style: TextStyle(fontSize: 12, color: AppColors.primary, fontWeight: FontWeight.w600),
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
                child: const Text(
                  'Seluruh pengajuan jam & ruang mengajar dosen telah disetujui oleh Admin dan 0 bentrok terdeteksi. Semua susunan jadwal perkuliahan institusi sudah terstruktur rapi dan optimal!',
                  style: TextStyle(fontSize: 12.5, color: Color(0xFF334155), height: 1.45),
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
      scopeTitle: 'Seluruh Fakultas & Program Studi',
      scopeDescription:
          'Engine CSP global akan memproses preferensi seluruh dosen dan menyusun jadwal mata kuliah institusi secara otomatis bebas bentrok.',
      roleLabel: 'Super Admin Penjadwalan',
    );
    if (confirm != true || !mounted) return;

    setState(() => _isEngineRunning = true);
    final api = context.read<ApiService>();

    final report = await api.runSmartCspEngineWithAutoApproval(
      scope: 'global',
      role: 'admin',
    );
    await _loadAdminData();

    if (mounted) {
      setState(() => _isEngineRunning = false);
      CspExecutionResultDialog.show(context, report);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Padding(
        padding: EdgeInsets.symmetric(vertical: 40),
        child: Center(
          child: CircularProgressIndicator(
            color: AppColors.primary,
            strokeWidth: 3.2,
          ),
        ),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // ── Header Super Admin (Perpaduan Hijau & Putih Harmonis) ──
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(AppSpacing.lg),
          decoration: BoxDecoration(
            color: AppColors.surfaceVariant,
            borderRadius: BorderRadius.circular(AppRadius.lg),
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
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: AppColors.primary,
                      borderRadius: BorderRadius.circular(AppRadius.full),
                    ),
                    child: const Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.shield_outlined, color: Colors.white, size: 12),
                        SizedBox(width: 4),
                        Text(
                          'SUPER ADMIN',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                            letterSpacing: 0.6,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                    decoration: BoxDecoration(
                      color: const Color(0xFFECFDF5),
                      borderRadius: BorderRadius.circular(AppRadius.sm),
                      border: Border.all(color: const Color(0xFFA7F3D0)),
                    ),
                    child: const Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.check_circle_rounded, color: Color(0xFF059669), size: 11),
                        SizedBox(width: 4),
                        Text(
                          'System Online',
                          style: TextStyle(
                            color: Color(0xFF047857),
                            fontSize: 10.5,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              const Text(
                'Panel Kontrol Admin',
                style: TextStyle(
                  color: AppColors.textPrimary,
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 3),
              const Text(
                'Kelola penjadwalan institusi',
                style: TextStyle(
                  color: AppColors.textSecondary,
                  fontSize: 12,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: AppSpacing.md),

        // ── Stat Summary Cards (Khusus Role Admin) ──
        AdminStatCards(
          gedungList: _gedungList,
          ruanganList: _ruanganList,
          allUsersList: _allUsersList,
          allMatkulList: _allMatkulList,
          allAjuanList: _allAjuanList,
          jadwalList: _jadwalList,
        ),
        const SizedBox(height: AppSpacing.md),

        // ── Otomasi & Kontrol Jadwal (CSP & Window Ketersediaan) ──
        AdminAutomationSection(
          isSubmissionActive: _isSubmissionActive,
          isEngineRunning: _isEngineRunning,
          isAllApprovedAndConflictFree: _isAllApprovedAndConflictFree,
          onRunCSPEngine: _runCSPEngine,
          onToggleSubmissionStatus: _toggleSubmissionStatus,
        ),
        const SizedBox(height: AppSpacing.md),

        // ── Permintaan Banding Dosen ──
        AdminBandingSection(
          allAjuanList: _allAjuanList,
          onRefreshData: _loadAdminData,
        ),
        const SizedBox(height: AppSpacing.lg),
      ],
    );
  }
}
