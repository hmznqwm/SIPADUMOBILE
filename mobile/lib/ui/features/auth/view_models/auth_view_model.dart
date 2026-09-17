// File: auth_view_model.dart
// Deskripsi: ViewModel (ChangeNotifier) untuk pengelolaan state autentikasi login pengguna.
// Fungsi: Mengelola state loading, pesan error, proses autentikasi login/logout, dan pergantian peran/pengguna demo.

import 'package:flutter/material.dart';

import '../../../../data/models/user_model.dart';
import '../../../../data/repositories/auth_repository.dart';

class AuthViewModel extends ChangeNotifier {
  final AuthRepository _authRepository;

  AuthViewModel({required AuthRepository authRepository}) : _authRepository = authRepository;

  UserModel? get currentUser => _authRepository.currentUser;

  bool _isLoading = false;
  bool get isLoading => _isLoading;

  String? _errorMessage;
  String? get errorMessage => _errorMessage;

  void clearError() {
    _errorMessage = null;
    notifyListeners();
  }

  bool get isAuthenticated => _authRepository.currentUser != null;

  Future<bool> login(String email, String password) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      await _authRepository.login(email, password);
      _isLoading = false;
      notifyListeners();
      return true;
    } catch (e) {
      _errorMessage = e.toString();
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  Future<bool> googleLogin({
    required String email,
    required String displayName,
    String? photoUrl,
    String? idToken,
  }) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      await _authRepository.googleLogin(
        email: email,
        displayName: displayName,
        photoUrl: photoUrl,
        idToken: idToken,
      );
      _isLoading = false;
      notifyListeners();
      return true;
    } catch (e) {
      _errorMessage = e.toString();
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  Future<Map<String, dynamic>> forgotPassword({
    required String email,
    String? nidn,
  }) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final res = await _authRepository.forgotPassword(
        email: email,
        nidn: nidn,
      );
      _isLoading = false;
      notifyListeners();
      return res;
    } catch (e) {
      _errorMessage = e.toString();
      _isLoading = false;
      notifyListeners();
      rethrow;
    }
  }

  Future<Map<String, dynamic>> resetPassword({
    required String email,
    required String otp,
    required String newPassword,
  }) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final res = await _authRepository.resetPassword(
        email: email,
        otp: otp,
        newPassword: newPassword,
      );
      _isLoading = false;
      notifyListeners();
      return res;
    } catch (e) {
      _errorMessage = e.toString();
      _isLoading = false;
      notifyListeners();
      rethrow;
    }
  }

  Future<Map<String, dynamic>> changePassword({
    required String email,
    required String oldPassword,
    required String newPassword,
  }) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final res = await _authRepository.changePassword(
        email: email,
        oldPassword: oldPassword,
        newPassword: newPassword,
      );
      _isLoading = false;
      notifyListeners();
      return res;
    } catch (e) {
      _errorMessage = e.toString();
      _isLoading = false;
      notifyListeners();
      rethrow;
    }
  }

  Future<UserModel?> checkAndLoadSession() async {
    _isLoading = true;
    notifyListeners();
    final user = await _authRepository.loadSavedUserSession();
    _isLoading = false;
    notifyListeners();
    return user;
  }

  Future<void> logout() async {
    await _authRepository.logout();
    notifyListeners();
  }

  Future<void> updateProfilePhoto(String imagePath) async {
    await _authRepository.updateProfilePhoto(imagePath);
    notifyListeners();
  }

  Future<void> removeProfilePhoto() async {
    await _authRepository.removeProfilePhoto();
    notifyListeners();
  }

  Future<void> switchUser(UserModel user) async {
    await _authRepository.switchUser(user);
    notifyListeners();
  }
}
