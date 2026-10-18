import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:encrypt/encrypt.dart' as enc;

import '../models/user_model.dart';
import '../services/api_service.dart';
import '../services/subservices/api_http_helper.dart';

class AuthRepository {
  static const String _userSessionKey = 'saved_user_session';
  final ApiService _apiService;
  UserModel? _currentUser;

  // Enkripsi Kriptografis AES-256 untuk perlindungan data sesi lokal (At-Rest Encryption)
  static final enc.Key _encKey = enc.Key.fromUtf8('sipadu_secure_session_key_2026_!');
  static final enc.IV _encIv = enc.IV.fromUtf8('sipadu_iv_2026_!');

  AuthRepository({required ApiService apiService}) : _apiService = apiService;

  UserModel? get currentUser => _currentUser;

  /// Enkripsi string data sesi menggunakan AES-CBC
  String _encryptData(String plainText) {
    try {
      final encrypter = enc.Encrypter(enc.AES(_encKey, mode: enc.AESMode.cbc));
      final encrypted = encrypter.encrypt(plainText, iv: _encIv);
      return 'enc:${encrypted.base64}';
    } catch (e) {
      debugPrint('Enkripsi data sesi gagal, fallback ke plain: $e');
      return plainText;
    }
  }

  /// Dekripsi string data sesi terenkripsi (Mendukung backward compatibility)
  String _decryptData(String rawText) {
    try {
      if (rawText.startsWith('enc:')) {
        final rawBase64 = rawText.substring(4);
        final encrypter = enc.Encrypter(enc.AES(_encKey, mode: enc.AESMode.cbc));
        return encrypter.decrypt64(rawBase64, iv: _encIv);
      }
      return rawText;
    } catch (e) {
      debugPrint('Dekripsi data sesi gagal: $e');
      return rawText;
    }
  }

  /// [PRESENTASI] Fitur 'Tetap Masuk' (Remember Me):
  /// Memuat dan mendekripsi sesi login tersimpan dari SharedPreferences.
  Future<UserModel?> loadSavedUserSession() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final rawStr = prefs.getString(_userSessionKey);
      if (rawStr != null && rawStr.isNotEmpty) {
        final jsonStr = _decryptData(rawStr);
        final Map<String, dynamic> map = jsonDecode(jsonStr);
        var user = UserModel.fromJson(map);
        final savedAvatar = prefs.getString('user_avatar_${user.id}');
        if (savedAvatar != null && savedAvatar.isNotEmpty) {
          user = user.copyWith(avatarPath: savedAvatar);
        }
        _currentUser = user;
        ApiHttpHelper.currentAuthToken = user.token;
        return _currentUser;
      }
    } catch (e) {
      debugPrint('Error loading saved user session: $e');
    }
    return null;
  }

  /// Memperbarui foto profil pengguna secara permanen
  Future<void> updateProfilePhoto(String imagePath) async {
    if (_currentUser == null) return;
    final updatedUser = _currentUser!.copyWith(avatarPath: imagePath);
    _currentUser = updatedUser;
    await _saveSession(updatedUser);

    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('user_avatar_${updatedUser.id}', imagePath);
    } catch (e) {
      debugPrint('Error saving avatar in SharedPreferences: $e');
    }
  }

  /// Menghapus foto profil pengguna secara permanen
  Future<void> removeProfilePhoto() async {
    if (_currentUser == null) return;
    final userId = _currentUser!.id;
    final updatedUser = UserModel(
      id: _currentUser!.id,
      nama: _currentUser!.nama,
      email: _currentUser!.email,
      role: _currentUser!.role,
      jurusanId: _currentUser!.jurusanId,
      jurusanNama: _currentUser!.jurusanNama,
      fakultasNama: _currentUser!.fakultasNama,
      matkulNama: _currentUser!.matkulNama,
      isPriority: _currentUser!.isPriority,
      token: _currentUser!.token,
      avatarPath: null,
    );
    _currentUser = updatedUser;
    await _saveSession(updatedUser);

    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove('user_avatar_$userId');
    } catch (e) {
      debugPrint('Error removing avatar in SharedPreferences: $e');
    }
  }

  /// Menyimpan data user login ke SharedPreferences secara terenkripsi AES-256
  Future<void> _saveSession(UserModel user) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final jsonStr = jsonEncode(user.toJson());
      final encryptedStr = _encryptData(jsonStr);
      await prefs.setString(_userSessionKey, encryptedStr);
    } catch (e) {
      debugPrint('Error saving encrypted user session: $e');
    }
  }

  /// Menghapus data user login dari SharedPreferences saat logout
  Future<void> _clearSession() async {
    try {
      ApiHttpHelper.currentAuthToken = null;
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(_userSessionKey);
    } catch (e) {
      debugPrint('Error clearing user session: $e');
    }
  }

  Future<UserModel> login(String email, String password) async {
    var user = await _apiService.login(email, password);
    try {
      final prefs = await SharedPreferences.getInstance();
      final savedAvatar = prefs.getString('user_avatar_${user.id}');
      if (savedAvatar != null && savedAvatar.isNotEmpty) {
        user = user.copyWith(avatarPath: savedAvatar);
      }
    } catch (_) {}
    _currentUser = user;
    ApiHttpHelper.currentAuthToken = user.token;
    await _saveSession(user);
    return user;
  }

  Future<UserModel> googleLogin({
    required String email,
    required String displayName,
    String? photoUrl,
    String? idToken,
  }) async {
    var user = await _apiService.googleLogin(
      email: email,
      displayName: displayName,
      photoUrl: photoUrl,
      idToken: idToken,
    );
    try {
      final prefs = await SharedPreferences.getInstance();
      final savedAvatar = prefs.getString('user_avatar_${user.id}');
      if (savedAvatar != null && savedAvatar.isNotEmpty) {
        user = user.copyWith(avatarPath: savedAvatar);
      }
    } catch (_) {}
    _currentUser = user;
    ApiHttpHelper.currentAuthToken = user.token;
    await _saveSession(user);
    return user;
  }

  Future<Map<String, dynamic>> forgotPassword({
    required String email,
    String? nidn,
  }) async {
    return await _apiService.forgotPassword(
      email: email,
      nidn: nidn,
    );
  }

  Future<Map<String, dynamic>> resetPassword({
    required String email,
    required String otp,
    required String newPassword,
  }) async {
    return await _apiService.resetPassword(
      email: email,
      otp: otp,
      newPassword: newPassword,
    );
  }

  Future<Map<String, dynamic>> changePassword({
    required String email,
    required String oldPassword,
    required String newPassword,
  }) async {
    return await _apiService.changePassword(
      email: email,
      oldPassword: oldPassword,
      newPassword: newPassword,
    );
  }

  /// Logout dengan mencabut token di server dan membersihkan sesi lokal
  Future<void> logout() async {
    try {
      await _apiService.logout();
    } catch (e) {
      debugPrint('Logout remote revocation notification error: $e');
    }
    _currentUser = null;
    await _clearSession();
  }

  Future<void> switchUser(UserModel newUser) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final savedAvatar = prefs.getString('user_avatar_${newUser.id}');
      if (savedAvatar != null && savedAvatar.isNotEmpty) {
        newUser = newUser.copyWith(avatarPath: savedAvatar);
      }
    } catch (_) {}
    _currentUser = newUser;
    ApiHttpHelper.currentAuthToken = newUser.token;
    await _saveSession(newUser);
  }
}
