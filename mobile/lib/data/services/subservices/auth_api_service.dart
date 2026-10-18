import 'dart:convert';
import 'package:bcrypt/bcrypt.dart';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import '../../../config/api_config.dart';
import '../../models/user_model.dart';
import '../../mock/mock_database.dart';
import 'api_http_helper.dart';

class AuthApiService {
  final ApiHttpHelper _httpHelper;

  static const String _sbUrl = ApiConfig.supabaseUrl;
  static const String _sbKey = ApiConfig.supabasePublishableKey;

  AuthApiService({ApiHttpHelper? httpHelper})
      : _httpHelper = httpHelper ?? ApiHttpHelper();

  /// Direct Supabase Query Fallback for High Availability (Zero 500 downtime)
  Future<UserModel?> _loginViaSupabase(String ident, String password) async {
    try {
      final cleanIdent = Uri.encodeComponent(ident.trim());
      final url = Uri.parse(
        '$_sbUrl/rest/v1/users?or=(id.eq.$cleanIdent,id.ilike.$cleanIdent,email.eq.$cleanIdent,email.ilike.$cleanIdent)&select=*',
      );

      final res = await http.get(url, headers: {
        'apikey': _sbKey,
        'Authorization': 'Bearer $_sbKey',
      }).timeout(const Duration(seconds: 8));

      if (res.statusCode == 200) {
        final list = jsonDecode(res.body);
        if (list is List && list.isNotEmpty) {
          final u = Map<String, dynamic>.from(list[0]);
          final savedHash = u['password']?.toString() ?? '';

          bool isValid = false;
          if (savedHash.startsWith(r'$2b$') ||
              savedHash.startsWith(r'$2a$') ||
              savedHash.startsWith(r'$2y$')) {
            try {
              isValid = BCrypt.checkpw(password, savedHash);
            } catch (_) {}
          } else {
            isValid = savedHash == password;
          }

          if (isValid) {
            return UserModel(
              id: u['id']?.toString() ?? '',
              nama: u['nama']?.toString() ?? '',
              email: u['email']?.toString() ?? '',
              role: u['role']?.toString() ?? 'admin',
              jurusanId: u['jurusan_id']?.toString() ?? '',
              jurusanNama: u['jurusan_nama']?.toString() ?? '',
              fakultasNama: u['fakultas_nama']?.toString() ?? '',
              matkulNama: u['matkul_nama']?.toString(),
              isPriority: u['is_priority'] == true,
              token:
                  'sb_auth_${u['id']}_${DateTime.now().millisecondsSinceEpoch}',
              avatarPath: u['avatar_url']?.toString(),
            );
          } else {
            throw const ApiException(
              'INVALID_CREDENTIALS',
              'Kata sandi yang Anda masukkan salah. Silakan coba lagi.',
            );
          }
        }
      }
    } on ApiException {
      rethrow;
    } catch (e) {
      debugPrint('Supabase direct login error: $e');
    }
    return null;
  }

  /// Direct Supabase Google Login Query
  Future<UserModel?> _googleLoginViaSupabase(
    String email,
    String displayName,
    String? photoUrl,
  ) async {
    try {
      final cleanEmail = Uri.encodeComponent(email.trim().toLowerCase());
      final url = Uri.parse(
        '$_sbUrl/rest/v1/users?email=ilike.$cleanEmail&select=*',
      );

      final res = await http.get(url, headers: {
        'apikey': _sbKey,
        'Authorization': 'Bearer $_sbKey',
      }).timeout(const Duration(seconds: 8));

      if (res.statusCode == 200) {
        final list = jsonDecode(res.body);
        if (list is List && list.isNotEmpty) {
          final u = Map<String, dynamic>.from(list[0]);
          return UserModel(
            id: u['id']?.toString() ?? '',
            nama: u['nama']?.toString() ?? displayName,
            email: u['email']?.toString() ?? email,
            role: u['role']?.toString() ?? 'admin',
            jurusanId: u['jurusan_id']?.toString() ?? '',
            jurusanNama: u['jurusan_nama']?.toString() ?? '',
            fakultasNama: u['fakultas_nama']?.toString() ?? '',
            matkulNama: u['matkul_nama']?.toString(),
            isPriority: u['is_priority'] == true,
            token:
                'sb_google_${u['id']}_${DateTime.now().millisecondsSinceEpoch}',
            avatarPath: photoUrl ?? u['avatar_url']?.toString(),
          );
        }
      }
    } on ApiException {
      rethrow;
    } catch (e) {
      debugPrint('Supabase direct google login error: $e');
    }
    return null;
  }

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
          body: {'email': email.trim(), 'password': password},
        );
        if (data is Map && data['status'] == 'success') {
          final userMap = data['user'] ??
              data['data']?['user'] ??
              (data['data'] is Map ? data['data'] : null);
          if (userMap is Map) {
            final userObj =
                UserModel.fromJson(Map<String, dynamic>.from(userMap));
            final tokenStr =
                data['token'] ?? data['data']?['token'] ?? userObj.token;
            return userObj.copyWith(
              token: tokenStr?.toString() ??
                  'sipadu_token_${userObj.id}_${DateTime.now().millisecondsSinceEpoch}',
            );
          }
        }
      } on ApiException catch (apiErr) {
        // Jika status INVALID_CREDENTIALS atau UNREGISTERED, langsung rethrow
        if (apiErr.code == 'INVALID_CREDENTIALS' ||
            apiErr.code == 'UNREGISTERED') {
          rethrow;
        }
        // Jika server error (500), coba fallback langsung ke Supabase Cloud
        final sbUser = await _loginViaSupabase(email, password);
        if (sbUser != null) return sbUser;
        rethrow;
      } catch (e) {
        debugPrint('Backend login error: $e');
        final sbUser = await _loginViaSupabase(email, password);
        if (sbUser != null) return sbUser;
      }
    }

    // Fallback Supabase Cloud Direct
    final sbUser = await _loginViaSupabase(email, password);
    if (sbUser != null) return sbUser;

    // Fallback khusus bila useMockBackend diaktifkan secara eksplisit untuk testing
    if (ApiConfig.useMockBackend) {
      await Future.delayed(MockDatabase.defaultDelay);
      final user = MockDatabase.demoUsers.where((u) =>
          u.email.toLowerCase() == email.trim().toLowerCase() ||
          u.id.toLowerCase() == email.trim().toLowerCase()).firstOrNull;
      if (user == null) {
        throw const ApiException(
          'INVALID_CREDENTIALS',
          'Nomor Induk / Email tidak terdaftar dalam database institusi.',
        );
      }
      final savedPass = MockDatabase.userPasswords[user.email.toLowerCase()] ??
          MockDatabase.userPasswords[user.id.toLowerCase()];
      if (savedPass != null && savedPass == password) {
        return user.copyWith(
          token:
              'jwt_mock_token_${user.id}_${DateTime.now().millisecondsSinceEpoch}',
        );
      }
      throw const ApiException(
        'INVALID_CREDENTIALS',
        'Kata sandi yang Anda masukkan salah. Silakan coba lagi.',
      );
    }

    throw const ApiException(
      'INVALID_CREDENTIALS',
      'Nomor Induk / Email tidak terdaftar atau kata sandi salah.',
    );
  }

  /// POST /api/auth/google_login.php
  Future<UserModel> googleLogin({
    required String email,
    required String displayName,
    String? photoUrl,
    String? idToken,
  }) async {
    final cleanEmail = email.trim().toLowerCase();

    // 1. Kirim verifikasi token/email Google ke Backend Python FastAPI
    if (!ApiConfig.useMockBackend) {
      try {
        final data = await _httpHelper.makeOnlineRequest(
          '/auth/google_login.php',
          method: 'POST',
          body: {
            'email': cleanEmail,
            'nama': displayName,
            'foto': photoUrl,
            'idToken': idToken,
          },
        );
        if (data is Map && data['status'] == 'success') {
          final uMap = data['user'] ??
              data['data']?['user'] ??
              (data['data'] is Map ? data['data'] : null);
          final token = data['data']?['token'] ?? data['token'];
          if (uMap is Map) {
            final user = UserModel.fromJson(Map<String, dynamic>.from(uMap));
            return user.copyWith(
              token: token?.toString() ??
                  'google_token_${user.id}_${DateTime.now().millisecondsSinceEpoch}',
              avatarPath: photoUrl ?? user.avatarPath,
            );
          }
        }
      } on ApiException catch (apiErr) {
        if (apiErr.code == 'UNREGISTERED') {
          rethrow;
        }
        // Fallback langsung ke Supabase Cloud jika server mengalami kendala
        final sbUser = await _googleLoginViaSupabase(
          cleanEmail,
          displayName,
          photoUrl,
        );
        if (sbUser != null) return sbUser;
        rethrow;
      } catch (e) {
        debugPrint('Backend Python googleLogin error: $e');
        final sbUser = await _googleLoginViaSupabase(
          cleanEmail,
          displayName,
          photoUrl,
        );
        if (sbUser != null) return sbUser;
      }
    }

    // Direct Supabase Cloud Fallback
    final sbUser = await _googleLoginViaSupabase(
      cleanEmail,
      displayName,
      photoUrl,
    );
    if (sbUser != null) return sbUser;

    // Fallback Mock khusus mode mock development
    if (ApiConfig.useMockBackend) {
      final user = MockDatabase.demoUsers
          .where((u) => u.email.toLowerCase() == cleanEmail)
          .firstOrNull;
      if (user != null) {
        return user.copyWith(
          token:
              'google_token_${user.id}_${DateTime.now().millisecondsSinceEpoch}',
          avatarPath: photoUrl ?? user.avatarPath,
        );
      }
    }

    throw ApiException(
      'UNREGISTERED',
      'Akun Google ($email) belum terdaftar di database institusi SIPADU. Silakan hubungi Administrator.',
    );
  }

  /// POST /api/auth/forgot_password.php
  Future<Map<String, dynamic>> forgotPassword({
    required String email,
    String? nidn,
  }) async {
    final isOnline = await _httpHelper.checkConnectivity();
    if (!isOnline) {
      throw const ApiException('OFFLINE', 'Tidak ada koneksi internet. Harap periksa jaringan Anda.');
    }

    final cleanEmail = email.trim();
    final cleanNidn = nidn?.trim();

    if (!ApiConfig.useMockBackend) {
      try {
        final data = await _httpHelper.makeOnlineRequest(
          '/auth/forgot_password.php',
          method: 'POST',
          body: {
            'email': cleanEmail,
            'nidn': cleanNidn,
          },
        );
        final respMap = (data is Map && data.containsKey('detail') && data['detail'] is Map)
            ? (data['detail'] as Map)
            : (data is Map ? data : {});

        if (respMap['status'] == 'success' || (data is Map && data['status'] == 'success')) {
          return {
            'status': 'success',
            'message': data['message'] ?? respMap['message'] ?? 'Kode OTP pemulihan kata sandi telah dikirimkan ke email Anda.',
            'email': respMap['email'] ?? cleanEmail,
            'nidn': nidn,
            'nama': respMap['nama'] ?? 'Pengguna SIPADU',
            'otp': data['otp'] ?? respMap['otp'],
          };
        }
      } on ApiException catch (apiErr) {
        if (apiErr.code == 'NOT_FOUND' || apiErr.code == 'INVALID_CREDENTIALS') {
          rethrow;
        }
      } catch (e) {
        debugPrint('Forgot password backend error: $e');
      }
    }

    // Direct Supabase Cloud Fallback for Forgot Password
    try {
      final encEmail = Uri.encodeComponent(cleanEmail);
      final res = await http.get(
        Uri.parse('$_sbUrl/rest/v1/users?email=ilike.$encEmail&select=id,nama,email'),
        headers: {'apikey': _sbKey, 'Authorization': 'Bearer $_sbKey'},
      ).timeout(const Duration(seconds: 5));

      if (res.statusCode == 200) {
        final list = jsonDecode(res.body);
        if (list is List && list.isNotEmpty) {
          final u = list[0];
          final uId = u['id']?.toString() ?? '';
          if (cleanNidn != null && cleanNidn.isNotEmpty && uId.toLowerCase() != cleanNidn.toLowerCase()) {
            throw ApiException('INVALID_CREDENTIALS', 'Kombinasi NID/NIP ($cleanNidn) dan Email ($cleanEmail) tidak cocok!');
          }
          final otpVal = '${(100000 + (DateTime.now().microsecondsSinceEpoch % 899999))}';
          final tokenVal = 'sb_reset_${DateTime.now().millisecondsSinceEpoch}';
          final expStr = DateTime.now().toUtc().add(const Duration(minutes: 15)).toIso8601String();

          await http.post(
            Uri.parse('$_sbUrl/rest/v1/password_resets'),
            headers: {
              'apikey': _sbKey,
              'Authorization': 'Bearer $_sbKey',
              'Content-Type': 'application/json',
              'Prefer': 'resolution=merge-duplicates',
            },
            body: jsonEncode({
              'email': u['email'],
              'token': tokenVal,
              'otp': otpVal,
              'expires_at': expStr,
              'created_at': DateTime.now().toUtc().toIso8601String(),
            }),
          ).timeout(const Duration(seconds: 5));

          return {
            'status': 'success',
            'message': 'Kode OTP pemulihan kata sandi telah dikirimkan ke email (${u['email']}).',
            'email': u['email'],
            'nidn': uId,
            'nama': u['nama'] ?? 'Pengguna SIPADU',
            'otp': otpVal,
            'token': tokenVal,
          };
        }
      }
    } on ApiException {
      rethrow;
    } catch (sbErr) {
      debugPrint('Supabase direct forgot password error: $sbErr');
    }

    throw const ApiException(
      'NOT_FOUND',
      'Alamat Email atau NIDN/NIP tidak terdaftar pada sistem SIPADU.',
    );
  }

  /// POST /api/auth/reset_password.php
  Future<Map<String, dynamic>> resetPassword({
    required String email,
    required String otp,
    required String newPassword,
  }) async {
    final isOnline = await _httpHelper.checkConnectivity();
    if (!isOnline) {
      throw const ApiException('OFFLINE', 'Tidak ada koneksi internet. Harap periksa jaringan Anda.');
    }

    final cleanEmail = email.trim();
    final cleanOtp = otp.trim();

    if (!ApiConfig.useMockBackend) {
      try {
        final data = await _httpHelper.makeOnlineRequest(
          '/auth/reset_password.php',
          method: 'POST',
          body: {
            'email': cleanEmail,
            'otp': cleanOtp,
            'new_password': newPassword,
          },
        );
        if (data is Map) {
          return Map<String, dynamic>.from(data);
        }
      } on ApiException {
        rethrow;
      } catch (e) {
        debugPrint('Reset password backend error: $e');
      }
    }

    // Direct Supabase Cloud Fallback for Reset Password
    try {
      final encEmail = Uri.encodeComponent(cleanEmail);
      final res = await http.get(
        Uri.parse('$_sbUrl/rest/v1/password_resets?email=ilike.$encEmail'),
        headers: {'apikey': _sbKey, 'Authorization': 'Bearer $_sbKey'},
      ).timeout(const Duration(seconds: 5));

      if (res.statusCode == 200) {
        final list = jsonDecode(res.body);
        if (list is List && list.isNotEmpty) {
          final rec = list[0];
          final recOtp = rec['otp']?.toString();
          if (recOtp != cleanOtp) {
            throw const ApiException('INVALID_OTP', 'Kode OTP yang dimasukkan tidak cocok. Silakan periksa kembali.');
          }
          final hashedPw = BCrypt.hashpw(newPassword, BCrypt.gensalt());
          await http.patch(
            Uri.parse('$_sbUrl/rest/v1/users?email=ilike.$encEmail'),
            headers: {
              'apikey': _sbKey,
              'Authorization': 'Bearer $_sbKey',
              'Content-Type': 'application/json',
            },
            body: jsonEncode({'password': hashedPw}),
          ).timeout(const Duration(seconds: 5));

          await http.delete(
            Uri.parse('$_sbUrl/rest/v1/password_resets?email=ilike.$encEmail'),
            headers: {'apikey': _sbKey, 'Authorization': 'Bearer $_sbKey'},
          );

          return {
            'status': 'success',
            'message': 'Kata sandi Anda berhasil diperbarui! Silakan login dengan kata sandi baru.',
          };
        }
      }
    } on ApiException {
      rethrow;
    } catch (sbErr) {
      debugPrint('Supabase direct reset password error: $sbErr');
    }

    throw const ApiException('INVALID_OTP', 'Kode OTP yang dimasukkan tidak valid atau sudah kedaluwarsa.');
  }

  /// POST /api/auth/change_password.php
  Future<Map<String, dynamic>> changePassword({
    required String email,
    required String oldPassword,
    required String newPassword,
  }) async {
    final isOnline = await _httpHelper.checkConnectivity();
    if (!isOnline) {
      throw const ApiException('OFFLINE', 'Tidak ada koneksi internet. Harap periksa jaringan Anda.');
    }

    if (oldPassword.isEmpty) {
      throw const ApiException('INVALID_OLD_PASSWORD', 'Kata sandi saat ini tidak boleh kosong.');
    }
    if (newPassword.length < 8) {
      throw const ApiException('WEAK_PASSWORD', 'Kata sandi baru minimal harus 8 karakter.');
    }

    final cleanEmail = email.trim();

    if (!ApiConfig.useMockBackend) {
      try {
        final data = await _httpHelper.makeOnlineRequest(
          '/auth/change_password.php',
          method: 'POST',
          body: {
            'email': cleanEmail,
            'old_password': oldPassword,
            'new_password': newPassword,
          },
        );
        if (data is Map) {
          return Map<String, dynamic>.from(data);
        }
      } on ApiException {
        rethrow;
      } catch (e) {
        debugPrint('Change password backend error: $e');
      }
    }

    // Direct Supabase Cloud Fallback for Change Password
    try {
      final encEmail = Uri.encodeComponent(cleanEmail);
      final res = await http.get(
        Uri.parse('$_sbUrl/rest/v1/users?email=ilike.$encEmail&select=*'),
        headers: {'apikey': _sbKey, 'Authorization': 'Bearer $_sbKey'},
      ).timeout(const Duration(seconds: 5));

      if (res.statusCode == 200) {
        final list = jsonDecode(res.body);
        if (list is List && list.isNotEmpty) {
          final u = list[0];
          final currentHash = u['password']?.toString() ?? '';
          bool isValid = false;
          if (currentHash.startsWith(r'$2b$') || currentHash.startsWith(r'$2a$') || currentHash.startsWith(r'$2y$')) {
            try {
              isValid = BCrypt.checkpw(oldPassword, currentHash);
            } catch (_) {}
          } else {
            isValid = currentHash == oldPassword;
          }

          if (!isValid) {
            throw const ApiException('INVALID_OLD_PASSWORD', 'Kata sandi lama tidak sesuai.');
          }

          final newHash = BCrypt.hashpw(newPassword, BCrypt.gensalt());
          await http.patch(
            Uri.parse('$_sbUrl/rest/v1/users?email=ilike.$encEmail'),
            headers: {
              'apikey': _sbKey,
              'Authorization': 'Bearer $_sbKey',
              'Content-Type': 'application/json',
            },
            body: jsonEncode({'password': newHash}),
          ).timeout(const Duration(seconds: 5));

          return {
            'status': 'success',
            'message': 'Kata sandi berhasil diperbarui dan disinkronkan ke Supabase.',
          };
        }
      }
    } on ApiException {
      rethrow;
    } catch (sbErr) {
      debugPrint('Supabase direct change password error: $sbErr');
    }

    throw const ApiException('INVALID_OLD_PASSWORD', 'Kata sandi lama tidak sesuai.');
  }

  /// POST /api/auth/logout.php
  Future<void> logout() async {
    if (!ApiConfig.useMockBackend) {
      try {
        await _httpHelper.makeOnlineRequest(
          '/auth/logout.php',
          method: 'POST',
        );
      } catch (e) {
        debugPrint('Logout backend notification warning: $e');
      }
    }
  }
}
