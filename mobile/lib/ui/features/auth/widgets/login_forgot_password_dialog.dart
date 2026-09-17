import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../../config/constants.dart';
import '../view_models/auth_view_model.dart';

class LoginForgotPasswordDialog {
  static void show(
    BuildContext context, {
    required TextEditingController emailController,
    required TextEditingController passwordController,
  }) {
    final emailResetCtrl = TextEditingController(text: emailController.text.trim());
    final nidnResetCtrl = TextEditingController();
    final otpCtrl = TextEditingController();
    final newPassCtrl = TextEditingController();
    final confirmPassCtrl = TextEditingController();
    int currentStep = 1;
    bool isProcessing = false;
    bool obscureNewPass = true;
    bool obscureConfirmPass = true;
    String? localError;
    String? verifiedEmail;

    showDialog(
      context: context,
      barrierDismissible: !isProcessing,
      builder: (dialogContext) {
        return StatefulBuilder(
          builder: (dialogCtx, setDialogState) {
            final authViewModel = dialogCtx.read<AuthViewModel>();

            return Dialog(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
                side: const BorderSide(color: Color(0xFFE2E8F0)),
              ),
              backgroundColor: Colors.white,
              elevation: 4,
              insetPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 440),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // ── Header (Clean, Flat, Border Bottom, No Gradient, No Emojis) ──
                    Container(
                      padding: const EdgeInsets.fromLTRB(20, 18, 16, 16),
                      decoration: const BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
                        border: Border(bottom: BorderSide(color: Color(0xFFE2E8F0))),
                      ),
                      child: Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: const Color(0xFFF0FDFA),
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(color: const Color(0xFFCCFBF1)),
                            ),
                            child: const Icon(
                              Icons.lock_reset_rounded,
                              color: Color(0xFF0F766E),
                              size: 20,
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Text(
                              currentStep == 1
                                  ? 'Lupa Password'
                                  : 'Buat Password Baru',
                              style: const TextStyle(
                                fontSize: 15,
                                fontWeight: FontWeight.bold,
                                color: Color(0xFF0F172A),
                              ),
                            ),
                          ),
                          IconButton(
                            icon: const Icon(Icons.close_rounded, size: 20, color: Color(0xFF94A3B8)),
                            onPressed: isProcessing ? null : () => Navigator.pop(dialogCtx),
                            tooltip: 'Tutup',
                            padding: EdgeInsets.zero,
                            constraints: const BoxConstraints(),
                          ),
                        ],
                      ),
                    ),

                    // ── Step Indicator Bar ──
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                      color: const Color(0xFFF8FAFC),
                      child: Row(
                        children: [
                          _buildStepPill(1, 'Verifikasi Akun', currentStep == 1, currentStep > 1),
                          const SizedBox(width: 8),
                          const Expanded(child: Divider(color: Color(0xFFCBD5E1), height: 1)),
                          const SizedBox(width: 8),
                          _buildStepPill(2, 'OTP & Sandi Baru', currentStep == 2, false),
                        ],
                      ),
                    ),

                    // ── Dialog Content ──
                    Flexible(
                      child: SingleChildScrollView(
                        padding: const EdgeInsets.fromLTRB(20, 16, 20, 8),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            if (currentStep == 1) ...[
                              // Input 1: Email Terdaftar
                              const Text(
                                'Alamat Email Terdaftar',
                                style: TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w600,
                                  color: Color(0xFF334155),
                                ),
                              ),
                              const SizedBox(height: 6),
                              TextField(
                                controller: emailResetCtrl,
                                keyboardType: TextInputType.emailAddress,
                                style: const TextStyle(fontSize: 13, color: Color(0xFF0F172A)),
                                decoration: InputDecoration(
                                  hintText: 'contoh: dosen@uin-malang.ac.id',
                                  hintStyle: const TextStyle(fontSize: 12, color: Color(0xFF94A3B8)),
                                  prefixIcon: const Icon(Icons.alternate_email_rounded, size: 17, color: Color(0xFF64748B)),
                                  filled: true,
                                  fillColor: const Color(0xFFF8FAFC),
                                  contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                                  border: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(10),
                                    borderSide: const BorderSide(color: Color(0xFFCBD5E1)),
                                  ),
                                  enabledBorder: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(10),
                                    borderSide: const BorderSide(color: Color(0xFFCBD5E1)),
                                  ),
                                  focusedBorder: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(10),
                                    borderSide: const BorderSide(color: AppColors.primary, width: 1.5),
                                  ),
                                ),
                              ),
                              const SizedBox(height: 14),

                              // Input 2: NIDN / NIP
                              const Text(
                                'Nomor Induk Dosen / Pegawai (NIDN / NIP)',
                                style: TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w600,
                                  color: Color(0xFF334155),
                                ),
                              ),
                              const SizedBox(height: 6),
                              TextField(
                                controller: nidnResetCtrl,
                                style: const TextStyle(fontSize: 13, color: Color(0xFF0F172A)),
                                decoration: InputDecoration(
                                  hintText: 'contoh: 198501012010121001 atau DSN001',
                                  hintStyle: const TextStyle(fontSize: 12, color: Color(0xFF94A3B8)),
                                  prefixIcon: const Icon(Icons.badge_outlined, size: 17, color: Color(0xFF64748B)),
                                  filled: true,
                                  fillColor: const Color(0xFFF8FAFC),
                                  contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                                  border: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(10),
                                    borderSide: const BorderSide(color: Color(0xFFCBD5E1)),
                                  ),
                                  enabledBorder: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(10),
                                    borderSide: const BorderSide(color: Color(0xFFCBD5E1)),
                                  ),
                                  focusedBorder: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(10),
                                    borderSide: const BorderSide(color: AppColors.primary, width: 1.5),
                                  ),
                                ),
                              ),
                            ] else ...[
                              // Step 2: Compact Info Bar
                              Container(
                                width: double.infinity,
                                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 9),
                                decoration: BoxDecoration(
                                  color: const Color(0xFFF0FDFA),
                                  borderRadius: BorderRadius.circular(8),
                                  border: Border.all(color: const Color(0xFF99F6E4)),
                                ),
                                child: Row(
                                  children: [
                                    const Icon(
                                      Icons.mark_email_read_outlined,
                                      color: Color(0xFF0F766E),
                                      size: 16,
                                    ),
                                    const SizedBox(width: 8),
                                    Expanded(
                                      child: Text(
                                        'Kode OTP dikirim ke $verifiedEmail',
                                        style: const TextStyle(
                                          fontSize: 11.5,
                                          fontWeight: FontWeight.w600,
                                          color: Color(0xFF0F766E),
                                        ),
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              const SizedBox(height: 14),

                              // Input: Kode OTP
                              const Text(
                                'Kode Verifikasi OTP',
                                style: TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w600,
                                  color: Color(0xFF334155),
                                ),
                              ),
                              const SizedBox(height: 6),
                              TextField(
                                controller: otpCtrl,
                                keyboardType: TextInputType.number,
                                maxLength: 6,
                                style: const TextStyle(
                                  fontSize: 15,
                                  fontWeight: FontWeight.bold,
                                  letterSpacing: 4.0,
                                  color: Color(0xFF0F172A),
                                ),
                                decoration: InputDecoration(
                                  counterText: '',
                                  hintText: '123456',
                                  hintStyle: const TextStyle(fontSize: 13, letterSpacing: 2.0, color: Color(0xFF94A3B8)),
                                  prefixIcon: const Icon(Icons.pin_outlined, size: 17, color: Color(0xFF64748B)),
                                  filled: true,
                                  fillColor: const Color(0xFFF8FAFC),
                                  contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                                  border: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(10),
                                    borderSide: const BorderSide(color: Color(0xFFCBD5E1)),
                                  ),
                                  enabledBorder: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(10),
                                    borderSide: const BorderSide(color: Color(0xFFCBD5E1)),
                                  ),
                                  focusedBorder: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(10),
                                    borderSide: const BorderSide(color: AppColors.primary, width: 1.5),
                                  ),
                                ),
                              ),
                              const SizedBox(height: 12),

                              // Input: Kata Sandi Baru
                              const Text(
                                'Kata Sandi Baru',
                                style: TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w600,
                                  color: Color(0xFF334155),
                                ),
                              ),
                              const SizedBox(height: 6),
                              TextField(
                                controller: newPassCtrl,
                                obscureText: obscureNewPass,
                                style: const TextStyle(fontSize: 13, color: Color(0xFF0F172A)),
                                decoration: InputDecoration(
                                  hintText: 'Minimal 6 karakter',
                                  hintStyle: const TextStyle(fontSize: 12, color: Color(0xFF94A3B8)),
                                  prefixIcon: const Icon(Icons.lock_outline_rounded, size: 17, color: Color(0xFF64748B)),
                                  suffixIcon: IconButton(
                                    icon: Icon(
                                      obscureNewPass ? Icons.visibility_off_outlined : Icons.visibility_outlined,
                                      size: 18,
                                      color: const Color(0xFF64748B),
                                    ),
                                    onPressed: () {
                                      setDialogState(() {
                                        obscureNewPass = !obscureNewPass;
                                      });
                                    },
                                  ),
                                  filled: true,
                                  fillColor: const Color(0xFFF8FAFC),
                                  contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                                  border: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(10),
                                    borderSide: const BorderSide(color: Color(0xFFCBD5E1)),
                                  ),
                                  enabledBorder: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(10),
                                    borderSide: const BorderSide(color: Color(0xFFCBD5E1)),
                                  ),
                                  focusedBorder: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(10),
                                    borderSide: const BorderSide(color: AppColors.primary, width: 1.5),
                                  ),
                                ),
                              ),
                              const SizedBox(height: 12),

                              // Input: Konfirmasi Kata Sandi Baru
                              const Text(
                                'Konfirmasi Kata Sandi Baru',
                                style: TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w600,
                                  color: Color(0xFF334155),
                                ),
                              ),
                              const SizedBox(height: 6),
                              TextField(
                                controller: confirmPassCtrl,
                                obscureText: obscureConfirmPass,
                                style: const TextStyle(fontSize: 13, color: Color(0xFF0F172A)),
                                decoration: InputDecoration(
                                  hintText: 'Ketik ulang kata sandi baru',
                                  hintStyle: const TextStyle(fontSize: 12, color: Color(0xFF94A3B8)),
                                  prefixIcon: const Icon(Icons.lock_reset_rounded, size: 17, color: Color(0xFF64748B)),
                                  suffixIcon: IconButton(
                                    icon: Icon(
                                      obscureConfirmPass ? Icons.visibility_off_outlined : Icons.visibility_outlined,
                                      size: 18,
                                      color: const Color(0xFF64748B),
                                    ),
                                    onPressed: () {
                                      setDialogState(() {
                                        obscureConfirmPass = !obscureConfirmPass;
                                      });
                                    },
                                  ),
                                  filled: true,
                                  fillColor: const Color(0xFFF8FAFC),
                                  contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                                  border: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(10),
                                    borderSide: const BorderSide(color: Color(0xFFCBD5E1)),
                                  ),
                                  enabledBorder: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(10),
                                    borderSide: const BorderSide(color: Color(0xFFCBD5E1)),
                                  ),
                                  focusedBorder: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(10),
                                    borderSide: const BorderSide(color: AppColors.primary, width: 1.5),
                                  ),
                                ),
                              ),
                            ],

                            // Error Notice Box
                            if (localError != null) ...[
                              const SizedBox(height: 14),
                              Container(
                                width: double.infinity,
                                padding: const EdgeInsets.all(10),
                                decoration: BoxDecoration(
                                  color: const Color(0xFFFEF2F2),
                                  borderRadius: BorderRadius.circular(8),
                                  border: Border.all(color: const Color(0xFFFECACA)),
                                ),
                                child: Row(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    const Icon(Icons.error_outline_rounded, color: Color(0xFFDC2626), size: 16),
                                    const SizedBox(width: 8),
                                    Expanded(
                                      child: Text(
                                        localError!,
                                        style: const TextStyle(
                                          color: Color(0xFF991B1B),
                                          fontSize: 11.5,
                                          fontWeight: FontWeight.w500,
                                          height: 1.3,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ],
                        ),
                      ),
                    ),

                    // ── Action Buttons Footer ──
                    Container(
                      padding: const EdgeInsets.fromLTRB(20, 12, 20, 16),
                      decoration: const BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.vertical(bottom: Radius.circular(16)),
                        border: Border(top: BorderSide(color: Color(0xFFE2E8F0))),
                      ),
                      child: Row(
                        children: [
                          if (currentStep == 2) ...[
                            OutlinedButton(
                              style: OutlinedButton.styleFrom(
                                foregroundColor: const Color(0xFF475569),
                                side: const BorderSide(color: Color(0xFFCBD5E1)),
                                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 11),
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                              ),
                              onPressed: isProcessing
                                  ? null
                                  : () {
                                      setDialogState(() {
                                        currentStep = 1;
                                        localError = null;
                                      });
                                    },
                              child: const Text('Kembali', style: TextStyle(fontSize: 12.5, fontWeight: FontWeight.w600)),
                            ),
                            const SizedBox(width: 8),
                          ] else ...[
                            OutlinedButton(
                              style: OutlinedButton.styleFrom(
                                foregroundColor: const Color(0xFF475569),
                                side: const BorderSide(color: Color(0xFFCBD5E1)),
                                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 11),
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                              ),
                              onPressed: isProcessing ? null : () => Navigator.pop(dialogCtx),
                              child: const Text('Batal', style: TextStyle(fontSize: 12.5, fontWeight: FontWeight.w600)),
                            ),
                            const SizedBox(width: 8),
                          ],
                          Expanded(
                            child: ElevatedButton(
                              style: ElevatedButton.styleFrom(
                                backgroundColor: AppColors.primary,
                                foregroundColor: Colors.white,
                                elevation: 0,
                                padding: const EdgeInsets.symmetric(vertical: 11),
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                              ),
                              onPressed: isProcessing
                                  ? null
                                  : () async {
                                      setDialogState(() {
                                        isProcessing = true;
                                        localError = null;
                                      });

                                      try {
                                        if (currentStep == 1) {
                                          final email = emailResetCtrl.text.trim();
                                          final nidn = nidnResetCtrl.text.trim();

                                          if (email.isEmpty || nidn.isEmpty) {
                                            setDialogState(() {
                                              localError = 'Harap isi Alamat Email dan NIDN/NIP akun Anda.';
                                              isProcessing = false;
                                            });
                                            return;
                                          }

                                          final res = await authViewModel.forgotPassword(
                                            email: email,
                                            nidn: nidn,
                                          );

                                          setDialogState(() {
                                            isProcessing = false;
                                            currentStep = 2;
                                            verifiedEmail = res['email']?.toString() ?? email;
                                            otpCtrl.clear();
                                          });
                                        } else {
                                          final otp = otpCtrl.text.trim();
                                          final newPass = newPassCtrl.text.trim();
                                          final confirmPass = confirmPassCtrl.text.trim();

                                          if (otp.length != 6) {
                                            setDialogState(() {
                                              localError = 'Kode OTP harus berupa 6 digit angka.';
                                              isProcessing = false;
                                            });
                                            return;
                                          }

                                          if (newPass.length < 6) {
                                            setDialogState(() {
                                              localError = 'Kata sandi baru minimal terdiri dari 6 karakter.';
                                              isProcessing = false;
                                            });
                                            return;
                                          }

                                          if (newPass != confirmPass) {
                                            setDialogState(() {
                                              localError = 'Konfirmasi kata sandi tidak cocok dengan kata sandi baru.';
                                              isProcessing = false;
                                            });
                                            return;
                                          }

                                          final res = await authViewModel.resetPassword(
                                            email: emailResetCtrl.text.trim(),
                                            otp: otp,
                                            newPassword: newPass,
                                          );

                                          if (context.mounted && dialogCtx.mounted) {
                                            Navigator.pop(dialogCtx);
                                            emailController.text = emailResetCtrl.text.trim();
                                            passwordController.text = newPass;
                                            ScaffoldMessenger.of(context).showSnackBar(
                                              SnackBar(
                                                content: Text(res['message']?.toString() ?? 'Kata sandi berhasil diperbarui. Silakan masuk.'),
                                                backgroundColor: const Color(0xFF0F766E),
                                                behavior: SnackBarBehavior.floating,
                                              ),
                                            );
                                          }
                                        }
                                      } catch (e) {
                                        setDialogState(() {
                                          isProcessing = false;
                                          localError = e.toString().replaceAll('ApiException: ', '');
                                        });
                                      }
                                    },
                              child: isProcessing
                                  ? const SizedBox(
                                      width: 16,
                                      height: 16,
                                      child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                                    )
                                  : Text(
                                      currentStep == 1 ? 'Verifikasi & Kirim OTP' : 'Simpan Kata Sandi Baru',
                                      style: const TextStyle(fontSize: 12.5, fontWeight: FontWeight.bold),
                                    ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  static Widget _buildStepPill(int stepNumber, String title, bool isActive, bool isDone) {
    Color bg = const Color(0xFFE2E8F0);
    Color textColor = const Color(0xFF64748B);
    Color badgeColor = const Color(0xFF94A3B8);

    if (isActive) {
      bg = const Color(0xFFF0FDFA);
      textColor = const Color(0xFF0F766E);
      badgeColor = AppColors.primary;
    } else if (isDone) {
      bg = const Color(0xFFF1F5F9);
      textColor = const Color(0xFF334155);
      badgeColor = const Color(0xFF059669);
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(6),
        border: Border.all(
          color: isActive ? const Color(0xFF99F6E4) : Colors.transparent,
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 16,
            height: 16,
            decoration: BoxDecoration(
              color: badgeColor,
              shape: BoxShape.circle,
            ),
            alignment: Alignment.center,
            child: isDone
                ? const Icon(Icons.check_rounded, size: 10, color: Colors.white)
                : Text(
                    '$stepNumber',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 9.5,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
          ),
          const SizedBox(width: 5),
          Text(
            title,
            style: TextStyle(
              fontSize: 11,
              fontWeight: isActive ? FontWeight.bold : FontWeight.w500,
              color: textColor,
            ),
          ),
        ],
      ),
    );
  }
}
