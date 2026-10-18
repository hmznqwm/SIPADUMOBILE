// File: dashboard_screen.dart
// Deskripsi: Tampilan (View) utama dashboard aplikasi Smart Schedule.
// Fungsi: Mengarahkan tampilan sesuai role pengguna (Dosen, KaProdi, Dekan, Admin) dan menampilkan kartu statistik ringkasan perkuliahan.

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../../config/constants.dart';
import '../../../core/widgets/info_card.dart';
import '../../../core/widgets/wave_header_card.dart';
import '../../auth/view_models/auth_view_model.dart';
import '../view_models/dashboard_view_model.dart';
import 'admin_dashboard_screen.dart';
import 'kajur_dashboard_screen.dart';
import 'dekan_dashboard_screen.dart';

/// [PRESENTASI] DashboardScreen (View Layer Utama):
/// Berfungsi sebagai Router Tampilan yang dinamis. 
/// Memeriksa role (peran) user dan mengarahkan ke komponen dashboard 
/// yang relevan (Admin, Dekan, Kajur, Dosen) agar tampilan selalu sesuai otorisasi.
class DashboardScreen extends StatefulWidget {
  final Function(int)? onNavigateToTab;

  const DashboardScreen({super.key, this.onNavigateToTab});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<DashboardViewModel>().loadDashboardData();
    });
  }

  @override
  Widget build(BuildContext context) {
    final viewModel = context.watch<DashboardViewModel>();
    final user = context.watch<AuthViewModel>().currentUser;

    if (viewModel.isLoading) {
      return const Center(
        child: CircularProgressIndicator(
          color: AppColors.primary,
          strokeWidth: 3.2,
        ),
      );
    }

    Widget roleBody;
    if (user?.role == 'admin') {
      roleBody = const AdminDashboardView();
    } else if (user?.role == 'kajur') {
      roleBody = const KaProdiDashboardView();
    } else if (user?.role == 'dekan') {
      roleBody = DekanDashboardView(onNavigateToTab: widget.onNavigateToTab);
    } else {
      roleBody = _buildDosenBody(context, viewModel, user);
    }

    return RefreshIndicator(
      onRefresh: () => viewModel.loadDashboardData(),
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 20),
        child: roleBody,
      ),
    );
  }

  Widget _buildDosenBody(BuildContext context, DashboardViewModel viewModel, dynamic user) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
              // ── Solid Primary Green Welcome Card (Split Wave 2-Warna) ──
              WaveHeaderCard(
                showBrand: true,
                title: (user?.nama?.isNotEmpty == true) ? user.nama : 'Dosen Pengampu',
                subtitle: 'ID: ${(user?.id?.isNotEmpty == true) ? user.id : '-'} • ${(user?.jurusanNama?.isNotEmpty == true) ? user.jurusanNama : '-'} • ${(user?.fakultasNama?.isNotEmpty == true) ? user.fakultasNama : '-'}',
              ),
              const SizedBox(height: AppSpacing.xl),

              // ── Stat Metrics Row ──
              Row(
                children: [
                  Expanded(
                    child: InfoCard(
                      icon: Icons.book_outlined,
                      label: 'Mata Kuliah',
                      value: '${viewModel.mataKuliahList.length} Matkul',
                      iconColor: AppColors.primary,
                    ),
                  ),
                  const SizedBox(width: AppSpacing.md),
                  Expanded(
                    child: InfoCard(
                      icon: Icons.pie_chart_outline,
                      label: 'Beban Mengajar',
                      value: '${viewModel.totalSks} SKS',
                      iconColor: AppColors.primaryAccent,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: AppSpacing.xl),

              // ── Course List Section ──
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Mata Kuliah Yang Diampu',
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                  Text(
                    '${viewModel.mataKuliahList.length} Mata Kuliah',
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                ],
              ),
              const SizedBox(height: AppSpacing.md),

              if (viewModel.mataKuliahList.isEmpty)
                Container(
                  padding: const EdgeInsets.all(AppSpacing.xl),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(AppRadius.lg),
                    border: Border.all(color: AppColors.border),
                  ),
                  child: const Center(
                    child: Text('Belum ada mata kuliah yang ditugaskan.'),
                  ),
                )
              else
                ListView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: viewModel.mataKuliahList.length,
                  itemBuilder: (context, index) {
                    final mk = viewModel.mataKuliahList[index];
                    return Container(
                      margin: const EdgeInsets.only(bottom: AppSpacing.md),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(AppRadius.lg),
                        border: Border.all(color: AppColors.border),
                      ),
                      child: ListTile(
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: AppSpacing.lg,
                          vertical: AppSpacing.xs,
                        ),
                        leading: Container(
                          width: 42,
                          height: 42,
                          decoration: const BoxDecoration(
                            color: AppColors.surfaceVariant,
                            shape: BoxShape.circle,
                          ),
                          alignment: Alignment.center,
                          child: Text(
                            '${mk.sks}',
                            style: const TextStyle(
                              color: AppColors.primary,
                              fontWeight: FontWeight.bold,
                              fontSize: 16,
                            ),
                          ),
                        ),
                        title: Text(
                          mk.nama,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            fontWeight: FontWeight.w700,
                            fontSize: 14,
                            color: AppColors.textPrimary,
                          ),
                        ),
                        subtitle: Padding(
                          padding: const EdgeInsets.only(top: 4.0),
                          child: Text(
                            'Kelas: ${mk.kelasNama.join(", ")} • ${mk.sks} SKS${mk.kebutuhanTipeRuangan != null ? " • ${mk.kebutuhanTipeRuangan}" : ""}',
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              fontSize: 12,
                              color: AppColors.textSecondary,
                            ),
                          ),
                        ),
                        trailing: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(
                            color: AppColors.yellowSoft,
                            borderRadius: BorderRadius.circular(AppRadius.full),
                            border: Border.all(color: AppColors.primaryAccent.withValues(alpha: 0.4)),
                          ),
                          child: Text(
                            mk.tipeSesi.toUpperCase(),
                            style: const TextStyle(
                              fontSize: 10,
                              fontWeight: FontWeight.w700,
                              color: AppColors.primaryAccent,
                            ),
                          ),
                        ),
                      ),
                    );
                  },
                ),
            ],
          );
  }
}
