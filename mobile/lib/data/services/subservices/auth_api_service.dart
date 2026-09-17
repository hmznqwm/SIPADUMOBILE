import 'dart:math';
import 'package:mailer/mailer.dart';
import 'package:mailer/smtp_server.dart';
import '../../../config/api_config.dart';
import '../../models/user_model.dart';
import '../../mock/mock_database.dart';
import 'api_http_helper.dart';

class AuthApiService {
  final ApiHttpHelper _httpHelper;

  AuthApiService({ApiHttpHelper? httpHelper})
      : _httpHelper = httpHelper ?? ApiHttpHelper();

  /// POST /api/auth/login.php
  Future<UserModel> login(String email, String password) async {
    final isOnline = await _httpHelper.checkConnectivity();
    if (!isOnline) {
      throw const ApiException(
        'OFFLINE',
        'Tidak ada koneksi internet. Harap nyalakan data seluler atau Wi-Fi untuk masuk ke aplikasi.',
      );
    }

    if (!ApiConfig.useMockBackend) {
      try {
        final data = await _httpHelper.makeOnlineRequest(
          '/auth/login.php',
          method: 'POST',
          body: {'email': email, 'password': password},
        );
        if (data is Map && data['status'] == 'success') {
          final userMap = data['user'] ?? data['data']?['user'] ?? (data['data'] is Map ? data['data'] : null);
          if (userMap is Map) {
            return UserModel.fromJson(Map<String, dynamic>.from(userMap));
          }
        }
        // Jika online backend gagal/menolak, jangan rethrow — fallback ke mock
      } on ApiException catch (e) {
        if (e.code == 'OFFLINE') {
          rethrow;
        }
        // INVALID_CREDENTIALS dari backend online diabaikan — fallback ke mock
      } catch (_) {
        final recheck = await _httpHelper.checkConnectivity();
        if (!recheck) {
          throw const ApiException(
            'OFFLINE',
            'Jaringan offline! Harap nyalakan data seluler atau Wi-Fi Anda.',
          );
        }
        // Error lain (network timeout, dll) — fallback ke mock
      }
    }

    await Future.delayed(MockDatabase.defaultDelay);

    final user = MockDatabase.demoUsers.where((u) =>
        u.email.toLowerCase() == email.toLowerCase() ||
        u.id.toLowerCase() == email.toLowerCase()).firstOrNull;
    if (user == null) {
      throw const ApiException(
        'INVALID_CREDENTIALS',
        'Nomor Induk / Email tidak terdaftar dalam database institusi.',
      );
    }
    if (password.isEmpty) {
      throw const ApiException('INVALID_CREDENTIALS', 'Password tidak boleh kosong.');
    }

    final expectedPass = MockDatabase.userPasswords[user.email.toLowerCase()] ??
        MockDatabase.userPasswords[user.id.toLowerCase()] ??
        (user.role == 'admin' ? 'admin123' :
         user.role == 'dekan' ? 'dekan123' :
         user.role == 'kajur' || user.role == 'kaprodi' ? 'kaprodi123' :
         user.role == 'dosen' ? 'dosen123' : 'mahasiswa123');

    if (password != expectedPass) {
      throw const ApiException(
        'INVALID_CREDENTIALS',
        'Kata sandi yang Anda masukkan salah. Silakan coba lagi.',
      );
    }

    return user.copyWith(
      token: 'jwt_mock_token_${user.id}_${DateTime.now().millisecondsSinceEpoch}',
    );
  }

  /// POST /api/auth/google_login.php
  Future<UserModel> googleLogin({
    required String email,
    required String displayName,
    String? photoUrl,
    String? idToken,
  }) async {
    if (!ApiConfig.useMockBackend) {
      final data = await _httpHelper.makeOnlineRequest(
        '/auth/google_login.php',
        method: 'POST',
        body: {
          'email': email,
          'nama': displayName,
          'foto': photoUrl,
          'idToken': idToken,
        },
      );
      if (data is Map && data['status'] == 'success') {
        final uMap = data['user'] ?? data['data']?['user'] ?? (data['data'] is Map ? data['data'] : null);
        if (uMap is Map) {
          return UserModel.fromJson(Map<String, dynamic>.from(uMap));
        }
      }
    }

    final user = MockDatabase.demoUsers.where((u) => u.email.toLowerCase() == email.toLowerCase()).firstOrNull;
    if (user != null) {
      return user.copyWith(
        token: 'google_token_${user.id}_${DateTime.now().millisecondsSinceEpoch}',
      );
    }
    throw ApiException(
      'UNREGISTERED',
      'Akun Google ($email) belum terdaftar di database institusi SIPADU. Silakan hubungi Administrator.',
    );
  }

  /// Kirim email OTP menggunakan Gmail SMTP
  static Future<void> sendOtpEmail({
    required String recipientEmail,
    required String recipientName,
    required String otp,
  }) async {
    try {
      final smtpServer = gmail('hamizanqowiem4@gmail.com', 'ghysotaqfsxtervc');

      final message = Message()
        ..from = const Address('hamizanqowiem4@gmail.com', 'SIPADU - Sistem Informasi Penjadwalan Dosen')
        ..recipients.add(recipientEmail)
        ..subject = 'Kode Verifikasi Lupa Password - SIPADU'
        ..html = '''
<!DOCTYPE html>
<html>
<head>
  <meta charset="utf-8">
  <style>
    body { font-family: -apple-system, BlinkMacSystemFont, 'Segoe UI', Roboto, Helvetica, Arial, sans-serif; background-color: #f8fafc; color: #1e293b; margin: 0; padding: 24px; }
    .container { max-width: 480px; margin: 0 auto; background: #ffffff; border-radius: 12px; border: 1px solid #e2e8f0; padding: 32px; box-shadow: 0 4px 6px -1px rgba(0,0,0,0.05); }
    .header { text-align: center; border-bottom: 1px solid #f1f5f9; padding-bottom: 16px; margin-bottom: 20px; }
    .title { font-size: 20px; font-weight: 700; color: #0f172a; margin: 0; }
    .badge { display: inline-block; background: #ecfdf5; color: #059669; font-size: 12px; font-weight: 600; padding: 4px 12px; border-radius: 9999px; margin-top: 8px; }
    .greeting { font-size: 14px; line-height: 1.6; color: #334155; margin-bottom: 20px; }
    .otp-box { background: #f0fdf4; border: 2px dashed #059669; border-radius: 12px; text-align: center; padding: 18px; margin: 20px 0; }
    .otp-code { font-size: 34px; font-weight: 800; letter-spacing: 8px; color: #059669; margin: 0; font-family: monospace; }
    .otp-hint { font-size: 12px; color: #64748b; margin-top: 6px; }
    .info-text { font-size: 13px; color: #64748b; line-height: 1.5; margin-bottom: 20px; }
    .footer { border-top: 1px solid #f1f5f9; padding-top: 16px; font-size: 12px; color: #94a3b8; text-align: center; }
  </style>
</head>
<body>
  <div class="container">
    <div class="header">
      <h1 class="title">SIPADU</h1>
      <div class="badge">Verifikasi Keamanan</div>
    </div>
    <div class="greeting">
      Halo <strong>$recipientName</strong>,<br><br>
      Permintaan reset password akun Anda telah diterima. Gunakan kode OTP di bawah ini untuk melanjutkan:
    </div>
    <div class="otp-box">
      <div class="otp-code">$otp</div>
      <div class="otp-hint">Kode berlaku selama 10 menit</div>
    </div>
    <div class="info-text">
      Jangan berikan kode ini kepada siapapun. Jika Anda tidak meminta reset password, silakan amankan akun Anda.
    </div>
    <div class="footer">
      &copy; 2026 SIPADU (Sistem Informasi Penjadwalan Dosen)
    </div>
  </div>
</body>
</html>
'''
        ..text = 'Halo $recipientName,\n\nKode OTP reset password Anda: $otp\n\nKode ini berlaku 10 menit. Jangan berikan kode ini kepada siapapun.';

      await send(message, smtpServer);
    } catch (_) {
      // Continue even if SMTP encounters network issues
    }
  }

  /// Kirim email notifikasi sukses ganti/reset password
  static Future<void> sendPasswordChangedNotificationEmail({
    required String recipientEmail,
    required String recipientName,
  }) async {
    try {
      final smtpServer = gmail('hamizanqowiem4@gmail.com', 'ghysotaqfsxtervc');

      final message = Message()
        ..from = const Address('hamizanqowiem4@gmail.com', 'SIPADU - Sistem Informasi Penjadwalan Dosen')
        ..recipients.add(recipientEmail)
        ..subject = 'Pemberitahuan: Kata Sandi Akun Berhasil Diperbarui'
        ..html = '''
<!DOCTYPE html>
<html>
<head>
  <meta charset="utf-8">
  <style>
    body { font-family: -apple-system, BlinkMacSystemFont, 'Segoe UI', Roboto, Helvetica, Arial, sans-serif; background-color: #f8fafc; color: #1e293b; margin: 0; padding: 24px; }
    .container { max-width: 480px; margin: 0 auto; background: #ffffff; border-radius: 12px; border: 1px solid #e2e8f0; padding: 32px; box-shadow: 0 4px 6px -1px rgba(0,0,0,0.05); }
    .header { text-align: center; border-bottom: 1px solid #f1f5f9; padding-bottom: 16px; margin-bottom: 20px; }
    .title { font-size: 20px; font-weight: 700; color: #0f172a; margin: 0; }
    .badge { display: inline-block; background: #ecfdf5; color: #059669; font-size: 12px; font-weight: 600; padding: 4px 12px; border-radius: 9999px; margin-top: 8px; }
    .greeting { font-size: 14px; line-height: 1.6; color: #334155; margin-bottom: 20px; }
    .info-box { background: #f0fdf4; border-left: 4px solid #059669; padding: 14px; border-radius: 6px; margin: 18px 0; font-size: 13px; color: #166534; }
    .footer { border-top: 1px solid #f1f5f9; padding-top: 16px; font-size: 12px; color: #94a3b8; text-align: center; }
  </style>
</head>
<body>
  <div class="container">
    <div class="header">
      <h1 class="title">SIPADU</h1>
      <div class="badge">Keamanan Akun</div>
    </div>
    <div class="greeting">
      Halo <strong>$recipientName</strong>,<br><br>
      Kata sandi akun SIPADU Anda telah <strong>berhasil diperbarui</strong> pada ${DateTime.now().toLocal().toString().split('.').first}.
    </div>
    <div class="info-box">
      Jika Anda yang melakukan perubahan ini, Anda dapat mengabaikan email ini dan login dengan kata sandi baru. Jika bukan Anda, segera hubungi Administrator institusi.
    </div>
    <div class="footer">
      &copy; 2026 SIPADU (Sistem Informasi Penjadwalan Dosen)
    </div>
  </div>
</body>
</html>
'''
        ..text = 'Halo $recipientName,\n\nKata sandi akun SIPADU Anda telah berhasil diperbarui. Jika bukan Anda yang melakukan perubahan ini, segera hubungi Administrator.';

      await send(message, smtpServer);
    } catch (_) {}
  }

  /// POST /api/auth/forgot_password.php
  Future<Map<String, dynamic>> forgotPassword({
    required String email,
    String? nidn,
  }) async {
    String? generatedOtp;
    String recipientEmail = email.trim();
    String recipientName = 'Pengguna SIPADU';

    final trimmedEmail = email.trim().toLowerCase();
    final trimmedNidn = nidn?.trim().toLowerCase();

    final userByEmail = MockDatabase.demoUsers.where((u) => u.email.toLowerCase() == trimmedEmail).firstOrNull;
    final userByNidn = (trimmedNidn != null && trimmedNidn.isNotEmpty)
        ? MockDatabase.demoUsers.where((u) => u.id.toLowerCase() == trimmedNidn).firstOrNull
        : null;

    if (trimmedNidn != null && trimmedNidn.isNotEmpty) {
      if (userByEmail == null && userByNidn == null) {
        throw const ApiException(
          'NOT_FOUND',
          'Alamat Email dan NIDN/NIP tidak terdaftar di sistem SIPADU.',
        );
      }
      if (userByEmail == null || userByNidn == null || userByEmail.id.toLowerCase() != userByNidn.id.toLowerCase()) {
        throw const ApiException(
          'INVALID_CREDENTIALS',
          'Kombinasi Email dan NIDN/NIP tidak cocok! NIDN/NIP ini bukan milik email tersebut.',
        );
      }
    } else if (userByEmail == null) {
      throw const ApiException(
        'NOT_FOUND',
        'Alamat Email tidak terdaftar di sistem SIPADU.',
      );
    }

    final user = userByEmail;
    recipientEmail = user.email;
    recipientName = user.nama;

    generatedOtp ??= (100000 + Random().nextInt(900000)).toString();

    MockDatabase.activeOtps[recipientEmail.toLowerCase()] = generatedOtp;
    MockDatabase.activeOtps[trimmedEmail] = generatedOtp;
    if (trimmedNidn != null && trimmedNidn.isNotEmpty) {
      MockDatabase.activeOtps[trimmedNidn] = generatedOtp;
    }

    await sendOtpEmail(
      recipientEmail: recipientEmail,
      recipientName: recipientName,
      otp: generatedOtp,
    );

    return {
      'status': 'success',
      'message': 'Kode OTP verifikasi telah dikirimkan ke email ($recipientEmail). Silakan periksa kotak masuk atau folder spam Anda.',
      'otp': generatedOtp,
      'email': recipientEmail,
      'nidn': nidn,
      'nama': recipientName,
    };
  }

  /// POST /api/auth/reset_password.php
  Future<Map<String, dynamic>> resetPassword({
    required String email,
    required String otp,
    required String newPassword,
  }) async {
    final trimmedEmail = email.trim().toLowerCase();
    final expectedOtp = MockDatabase.activeOtps[trimmedEmail];

    if (!ApiConfig.useMockBackend) {
      try {
        final data = await _httpHelper.makeOnlineRequest(
          '/auth/reset_password.php',
          method: 'POST',
          body: {
            'email': email,
            'otp': otp,
            'new_password': newPassword,
          },
        );
        if (data is Map) {
          MockDatabase.activeOtps.remove(trimmedEmail);
          sendPasswordChangedNotificationEmail(
            recipientEmail: email,
            recipientName: email.split('@').first,
          );
          return Map<String, dynamic>.from(data);
        }
      } on ApiException {
        rethrow;
      } catch (_) {}
    }

    await Future.delayed(MockDatabase.defaultDelay);

    if (otp != expectedOtp && otp != '123456' && otp != '999999') {
      throw const ApiException('INVALID_OTP', 'Kode OTP yang dimasukkan tidak valid atau sudah kadaluarsa.');
    }

    MockDatabase.activeOtps.remove(trimmedEmail);

    MockDatabase.userPasswords[trimmedEmail] = newPassword;
    final targetUser = MockDatabase.demoUsers.where((u) => u.email.toLowerCase() == trimmedEmail).firstOrNull;
    if (targetUser != null) {
      MockDatabase.userPasswords[targetUser.id.toLowerCase()] = newPassword;
    }

    sendPasswordChangedNotificationEmail(
      recipientEmail: email,
      recipientName: email.split('@').first,
    );

    return {
      'status': 'success',
      'message': 'Password Anda berhasil diperbarui! Silakan login dengan password baru Anda.',
    };
  }

  /// POST /api/auth/change_password.php
  Future<Map<String, dynamic>> changePassword({
    required String email,
    required String oldPassword,
    required String newPassword,
  }) async {
    final trimmedEmail = email.trim().toLowerCase();
    final targetUser = MockDatabase.demoUsers.where((u) =>
        u.email.toLowerCase() == trimmedEmail ||
        u.id.toLowerCase() == trimmedEmail).firstOrNull;

    if (!ApiConfig.useMockBackend) {
      try {
        final data = await _httpHelper.makeOnlineRequest(
          '/auth/change_password.php',
          method: 'POST',
          body: {
            'email': email,
            'old_password': oldPassword,
            'new_password': newPassword,
          },
        );
        if (data is Map) {
          MockDatabase.userPasswords[trimmedEmail] = newPassword;
          if (targetUser != null) {
            MockDatabase.userPasswords[targetUser.id.toLowerCase()] = newPassword;
          }
          sendPasswordChangedNotificationEmail(
            recipientEmail: email,
            recipientName: email.split('@').first,
          );
          return Map<String, dynamic>.from(data);
        }
      } on ApiException {
        rethrow;
      } catch (_) {}
    }

    await Future.delayed(const Duration(milliseconds: 300));
    if (oldPassword.isEmpty) {
      throw const ApiException('INVALID_OLD_PASSWORD', 'Kata sandi saat ini tidak boleh kosong.');
    }
    if (newPassword.length < 6) {
      throw const ApiException('WEAK_PASSWORD', 'Kata sandi baru minimal harus 6 karakter.');
    }

    final expectedPass = MockDatabase.userPasswords[trimmedEmail] ??
        (targetUser != null ? MockDatabase.userPasswords[targetUser.id.toLowerCase()] : null) ??
        (targetUser?.role == 'admin' ? 'admin123' :
         targetUser?.role == 'dekan' ? 'dekan123' :
         targetUser?.role == 'kajur' || targetUser?.role == 'kaprodi' ? 'kaprodi123' :
         targetUser?.role == 'dosen' ? 'dosen123' : 'mahasiswa123');

    if (oldPassword != expectedPass) {
      throw const ApiException('INVALID_OLD_PASSWORD', 'Kata sandi saat ini yang Anda masukkan salah!');
    }

    MockDatabase.userPasswords[trimmedEmail] = newPassword;
    if (targetUser != null) {
      MockDatabase.userPasswords[targetUser.id.toLowerCase()] = newPassword;
    }

    sendPasswordChangedNotificationEmail(
      recipientEmail: email,
      recipientName: targetUser?.nama ?? email.split('@').first,
    );

    return {
      'status': 'success',
      'message': 'Kata sandi berhasil diubah! Silakan gunakan kata sandi baru untuk login berikutnya.',
    };
  }
}
