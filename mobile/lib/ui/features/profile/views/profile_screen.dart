// File: profile_screen.dart
// Deskripsi: Tampilan Profil Pengguna yang modern, rapi, dan responsif.
// Fungsi: Menampilkan detail pengguna, role badge, status server, modal ubah kata sandi, opsi foto profil (long-press/tap ganti & hapus), serta konfirmasi logout.

import 'dart:io';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../../data/models/user_model.dart';
import '../../../../utils/academic_year_helper.dart';
import '../../auth/view_models/auth_view_model.dart';
import '../widgets/change_password_dialog.dart';
import '../widgets/logout_confirm_dialog.dart';
import '../widgets/profile_photo_action_sheets.dart';

class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final user = context.watch<AuthViewModel>().currentUser;
    final roleConfig = _getRoleConfig(user?.role);
    final initial = (user?.nama.isNotEmpty == true) ? user!.nama[0].toUpperCase() : 'U';

    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 20),
      child: Column(
        children: [
          // ── Card Profile Principal ──
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: const Color(0xFFE2E8F0)),
              boxShadow: const [
                BoxShadow(
                  color: Color(0x08000000),
                  blurRadius: 10,
                  offset: Offset(0, 4),
                ),
              ],
            ),
            child: Column(
              children: [
                Builder(
                  builder: (avatarCtx) {
                    return GestureDetector(
                      onLongPress: () => showAvatarActionModal(avatarCtx, user),
                      child: Stack(
                        alignment: Alignment.bottomRight,
                        children: [
                          Container(
                            padding: const EdgeInsets.all(3),
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              border: Border.all(color: roleConfig.borderColor, width: 2.5),
                            ),
                            child: _buildAvatarImage(user, roleConfig.textColor, initial),
                          ),
                          Container(
                            padding: const EdgeInsets.all(5),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              shape: BoxShape.circle,
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withValues(alpha: 0.12),
                                  blurRadius: 4,
                                  offset: const Offset(0, 2),
                                ),
                              ],
                            ),
                            child: Icon(Icons.camera_alt_rounded, color: roleConfig.textColor, size: 16),
                          ),
                        ],
                      ),
                    );
                  },
                ),
                const SizedBox(height: 12),
                Text(
                  user?.nama ?? 'Pengguna SIPADU',
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    fontSize: 19,
                    fontWeight: FontWeight.w700,
                    color: Color(0xFF0F172A),
                    letterSpacing: -0.2,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  user?.email ?? '-',
                  style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w500,
                    color: Color(0xFF64748B),
                  ),
                ),
                const SizedBox(height: 12),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                  decoration: BoxDecoration(
                    color: roleConfig.backgroundColor,
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: roleConfig.borderColor, width: 1.2),
                  ),
                  child: Text(
                    roleConfig.title,
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                      color: roleConfig.textColor,
                      letterSpacing: 0.2,
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),

          // ── Informational Details Card ──
          Container(
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: const Color(0xFFE2E8F0)),
            ),
            child: Column(
              children: [
                _buildDetailTile(
                  icon: Icons.badge_outlined,
                  label: 'Nomor Induk / ID',
                  value: (user?.role == 'admin' || (user?.id.toUpperCase().startsWith('GGL_') ?? false))
                      ? 'ADM001'
                      : (user?.id ?? '-'),
                ),
                const Divider(height: 1, indent: 56, endIndent: 16),
                _buildDetailTile(
                  icon: Icons.school_outlined,
                  label: 'Program Studi',
                  value: (user?.jurusanNama != null && user!.jurusanNama.isNotEmpty) ? user.jurusanNama : '-',
                ),
                const Divider(height: 1, indent: 56, endIndent: 16),
                _buildDetailTile(
                  icon: Icons.account_balance_outlined,
                  label: 'Fakultas',
                  value: (user?.fakultasNama != null && user!.fakultasNama.isNotEmpty) ? user.fakultasNama : '-',
                ),
                const Divider(height: 1, indent: 56, endIndent: 16),
                _buildDetailTile(
                  icon: Icons.calendar_today_outlined,
                  label: 'Semester Aktif',
                  value: AcademicYearHelper.getCurrentSemester(),
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),

          // ── Settings & Actions Section ──
          Material(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            clipBehavior: Clip.antiAlias,
            child: Container(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: const Color(0xFFE2E8F0)),
              ),
              child: Column(
                children: [
                  _buildActionTile(
                    icon: Icons.lock_outline_rounded,
                    label: 'Ubah Kata Sandi',
                    subtitle: 'Perbarui kata sandi akun Anda',
                    onTap: () {
                      if (user?.email != null) {
                        showChangePasswordDialog(context, user!.email);
                      }
                    },
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 24),

          // ── Logout Button ──
          SizedBox(
            width: double.infinity,
            height: 50,
            child: OutlinedButton.icon(
              style: OutlinedButton.styleFrom(
                foregroundColor: const Color(0xFF0F172A),
                side: const BorderSide(color: Color(0xFFE2E8F0), width: 1.2),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                backgroundColor: const Color(0xFFF1F5F9),
              ),
              icon: const Icon(Icons.logout_rounded, size: 20, color: Color(0xFF0F172A)),
              label: const Text(
                'Keluar Dari Akun',
                style: TextStyle(fontWeight: FontWeight.w700, fontSize: 14, color: Color(0xFF0F172A)),
              ),
              onPressed: () => showLogoutConfirmDialog(context),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDetailTile({
    required IconData icon,
    required String label,
    required String value,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 13),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: const Color(0xFFF1F5F9),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, size: 18, color: const Color(0xFF475569)),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: const TextStyle(
                    fontSize: 11.5,
                    fontWeight: FontWeight.w500,
                    color: Color(0xFF64748B),
                    letterSpacing: 0.1,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  value,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF0F172A),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActionTile({
    required IconData icon,
    required String label,
    required String subtitle,
    VoidCallback? onTap,
    Widget? trailing,
  }) {
    return Material(
      color: Colors.transparent,
      child: ListTile(
        onTap: onTap,
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
        leading: Container(
          padding: const EdgeInsets.all(9),
          decoration: BoxDecoration(
            color: const Color(0xFFF1F5F9),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Icon(icon, color: const Color(0xFF475569), size: 20),
        ),
        title: Text(
          label,
          style: const TextStyle(
            fontSize: 14.5,
            fontWeight: FontWeight.w600,
            color: Color(0xFF0F172A),
          ),
        ),
        subtitle: Text(
          subtitle,
          style: const TextStyle(
            fontSize: 11.5,
            fontWeight: FontWeight.w400,
            color: Color(0xFF64748B),
          ),
        ),
        trailing: trailing,
      ),
    );
  }

  Widget _buildAvatarImage(UserModel? user, Color roleColor, String initial) {
    if (user?.avatarPath != null && user!.avatarPath!.isNotEmpty) {
      final path = user.avatarPath!;
      if (path.startsWith('http://') || path.startsWith('https://')) {
        return CircleAvatar(
          radius: 38,
          backgroundColor: roleColor.withValues(alpha: 0.1),
          backgroundImage: NetworkImage(path),
        );
      }
      final file = File(path);
      if (file.existsSync()) {
        return CircleAvatar(
          radius: 38,
          backgroundColor: roleColor.withValues(alpha: 0.1),
          backgroundImage: FileImage(file),
        );
      }
    }

    return CircleAvatar(
      radius: 38,
      backgroundColor: const Color(0xFFF1F5F9),
      child: Text(
        initial,
        style: TextStyle(
          fontSize: 28,
          fontWeight: FontWeight.bold,
          color: roleColor,
        ),
      ),
    );
  }
}

class _RoleConfig {
  final String title;
  final Color textColor;
  final Color backgroundColor;
  final Color borderColor;

  const _RoleConfig({
    required this.title,
    required this.textColor,
    required this.backgroundColor,
    required this.borderColor,
  });
}

_RoleConfig _getRoleConfig(String? role) {
  final r = role?.toLowerCase().trim() ?? '';
  if (r == 'admin') {
    return const _RoleConfig(
      title: 'Super Admin',
      textColor: Color(0xFF0F172A), // Slate 900
      backgroundColor: Color(0xFFF1F5F9), // Slate 100
      borderColor: Color(0xFFCBD5E1), // Slate 300
    );
  } else if (r == 'dekan') {
    return const _RoleConfig(
      title: 'Dekan Fakultas',
      textColor: Color(0xFF581C87), // Deep Purple 900
      backgroundColor: Color(0xFFF3E8FF), // Purple 100
      borderColor: Color(0xFFD8B4FE), // Purple 300
    );
  } else if (r == 'kajur') {
    return const _RoleConfig(
      title: 'Ketua Program Studi',
      textColor: Color(0xFFB45309), // Warm Amber / Bronze 700
      backgroundColor: Color(0xFFFEF3C7), // Amber 100
      borderColor: Color(0xFFFDE68A), // Amber 200
    );
  } else if (r == 'dosen') {
    return const _RoleConfig(
      title: 'Dosen Pengampu',
      textColor: Color(0xFF0369A1), // Sapphire / Academic Blue 700
      backgroundColor: Color(0xFFE0F2FE), // Sky 100
      borderColor: Color(0xFFBAE6FD), // Sky 200
    );
  }

  return const _RoleConfig(
    title: 'Pengguna',
    textColor: Color(0xFF334155),
    backgroundColor: Color(0xFFF8FAFC),
    borderColor: Color(0xFFE2E8F0),
  );
}
