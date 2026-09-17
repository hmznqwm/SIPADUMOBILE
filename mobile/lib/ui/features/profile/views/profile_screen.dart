// File: profile_screen.dart
// Deskripsi: Tampilan Profil Pengguna yang modern, rapi, dan responsif.
// Fungsi: Menampilkan detail pengguna, role badge, status server, modal ubah kata sandi, opsi foto profil (long-press/tap ganti & hapus), serta konfirmasi logout.

import 'dart:io';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../../config/constants.dart';
import '../../../../data/models/user_model.dart';
import '../../auth/view_models/auth_view_model.dart';
import '../widgets/change_password_dialog.dart';
import '../widgets/logout_confirm_dialog.dart';
import '../widgets/profile_photo_action_sheets.dart';

class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final user = context.watch<AuthViewModel>().currentUser;

    String roleDisplay = 'Pengguna';
    Color roleColor = AppColors.primary;
    if (user?.role == 'admin') {
      roleDisplay = 'Super Admin';
      roleColor = const Color(0xFF047857);
    } else if (user?.role == 'dekan') {
      roleDisplay = 'Dekan FST';
      roleColor = const Color(0xFF059669);
    } else if (user?.role == 'kajur') {
      roleDisplay = 'Kaprodi TI';
      roleColor = const Color(0xFF10B981);
    } else if (user?.role == 'dosen') {
      roleDisplay = 'Dosen Pengampu';
      roleColor = const Color(0xFF16A34A);
    }

    final initial = (user?.nama.isNotEmpty == true) ? user!.nama[0].toUpperCase() : 'U';

    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 90),
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
                              border: Border.all(color: roleColor.withValues(alpha: 0.4), width: 2),
                            ),
                            child: _buildAvatarImage(user, roleColor, initial),
                          ),
                          Container(
                            padding: const EdgeInsets.all(4),
                            decoration: const BoxDecoration(
                              color: Colors.white,
                              shape: BoxShape.circle,
                            ),
                            child: Icon(Icons.camera_alt_rounded, color: roleColor, size: 18),
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
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 5),
                  decoration: BoxDecoration(
                    color: roleColor.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: roleColor.withValues(alpha: 0.3)),
                  ),
                  child: Text(
                    roleDisplay.toUpperCase(),
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                      color: roleColor,
                      letterSpacing: 0.6,
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
                  value: user?.id ?? '-',
                ),
                const Divider(height: 1, indent: 56, endIndent: 16),
                _buildDetailTile(
                  icon: Icons.school_outlined,
                  label: 'Program Studi',
                  value: user?.jurusanNama ?? 'Teknik Informatika',
                ),
                const Divider(height: 1, indent: 56, endIndent: 16),
                _buildDetailTile(
                  icon: Icons.account_balance_outlined,
                  label: 'Fakultas',
                  value: user?.fakultasNama ?? 'Fakultas Sains & Teknologi',
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
                    icon: Icons.lock_reset_rounded,
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
                foregroundColor: const Color(0xFFDC2626),
                side: const BorderSide(color: Color(0xFFFECACA), width: 1.2),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                backgroundColor: const Color(0xFFFEF2F2),
              ),
              icon: const Icon(Icons.logout_rounded, size: 20),
              label: const Text(
                'Keluar Dari Akun',
                style: TextStyle(fontWeight: FontWeight.w700, fontSize: 14),
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
            color: AppColors.primary.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Icon(icon, color: AppColors.primary, size: 20),
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
      backgroundColor: roleColor.withValues(alpha: 0.1),
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
