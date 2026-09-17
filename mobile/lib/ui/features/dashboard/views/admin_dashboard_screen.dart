// File: admin_dashboard_screen.dart
// Deskripsi: Tampilan (View) dashboard khusus Super Admin Penjadwalan.
// Fungsi: Ringkasan statistik institusi, eksekusi engine SCP, sakelar window ketersediaan, dan permohonan banding dosen.

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../../config/constants.dart';
import '../../../../data/models/ajuan_pengajaran_model.dart';
import '../../../../data/models/gedung_model.dart';
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
      debugPrint('DEBUG_COUNT_RUANGAN: ${ruangan.length}');
      for (final r in ruangan) {
        debugPrint('DEBUG_ROOM: id=${r.id}, nama=${r.nama}, gId=${r.gedungId}, gNama=${r.gedungNama}');
      }
      final users = await api.getAllUsers();
      final ajuan = await api.getAjuanPengajaranList();

      if (mounted) {
        setState(() {
          _isSubmissionActive = active;
          _gedungList = gedung;
          _ruanganList = ruangan;
          _allUsersList = users;
          _allAjuanList = ajuan;
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

  Future<void> _runCSPEngine() async {
    final confirm = await CspConfirmationDialog.show(
      context,
      scopeTitle: 'Seluruh Fakultas & Program Studi',
      scopeDescription:
          'Engine SCP global akan memproses preferensi seluruh dosen dan menyusun jadwal mata kuliah institusi secara otomatis bebas bentrok.',
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
        ),
        const SizedBox(height: AppSpacing.md),

        // ── Otomasi & Kontrol Jadwal (SCP & Window Ketersediaan) ──
        AdminAutomationSection(
          isSubmissionActive: _isSubmissionActive,
          isEngineRunning: _isEngineRunning,
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
