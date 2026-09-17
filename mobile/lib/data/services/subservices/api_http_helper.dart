import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
import '../../../config/api_config.dart';
import '../infinity_cookie_solver.dart';

class ApiException implements Exception {
  final String code;
  final String message;

  const ApiException(this.code, this.message);

  @override
  String toString() => message;
}

class ApiHttpHelper {
  DateTime? _lastConnectivityCheck;
  bool _cachedConnectivity = true;

  Future<bool> checkConnectivity() async {
    final now = DateTime.now();
    if (_lastConnectivityCheck != null && now.difference(_lastConnectivityCheck!) < const Duration(seconds: 15)) {
      return _cachedConnectivity;
    }
    try {
      final lookup = await InternetAddress.lookup('google.com').timeout(
        const Duration(seconds: 2),
      );
      _cachedConnectivity = lookup.isNotEmpty && lookup[0].rawAddress.isNotEmpty;
      _lastConnectivityCheck = now;
      return _cachedConnectivity;
    } catch (_) {
      _cachedConnectivity = false;
      _lastConnectivityCheck = now;
      return false;
    }
  }

  Future<dynamic> makeOnlineRequest(
    String path, {
    String method = 'GET',
    Map<String, dynamic>? body,
  }) async {
    final isConnected = await checkConnectivity();
    if (!isConnected) {
      throw const ApiException(
        'OFFLINE',
        'Jaringan offline! Harap nyalakan data seluler atau Wi-Fi untuk dapat menggunakan aplikasi SIPADU.',
      );
    }

    final url = Uri.parse('${ApiConfig.baseUrl}$path');

    Map<String, String> getHeaders() {
      final headers = <String, String>{
        'User-Agent':
            'Mozilla/5.0 (Windows NT 10.0; Win64; x64) SmartScheduleApp/1.0',
        'Accept': 'application/json',
        'Connection': 'close',
      };
      if (body != null || method.toUpperCase() == 'POST' || method.toUpperCase() == 'PUT') {
        headers['Content-Type'] = 'application/json';
      }
      if (InfinityCookieSolver.cachedCookie != null) {
        headers['Cookie'] = '__test=${InfinityCookieSolver.cachedCookie}';
      }
      return headers;
    }

    Future<http.Response> executeRequest() async {
      final h = getHeaders();
      final encodedBody = body != null ? jsonEncode(body) : null;
      switch (method.toUpperCase()) {
        case 'POST':
          return await http.post(url, headers: h, body: encodedBody).timeout(const Duration(seconds: 12));
        case 'PUT':
          return await http.put(url, headers: h, body: encodedBody).timeout(const Duration(seconds: 12));
        case 'DELETE':
          return await http.delete(url, headers: h, body: encodedBody).timeout(const Duration(seconds: 12));
        case 'GET':
        default:
          return await http.get(url, headers: h).timeout(const Duration(seconds: 12));
      }
    }

    http.Response response;
    try {
      response = await executeRequest();
    } catch (_) {
      final recheck = await checkConnectivity();
      if (!recheck) {
        throw const ApiException(
          'OFFLINE',
          'Koneksi terputus! Harap nyalakan data seluler atau Wi-Fi Anda.',
        );
      }
      rethrow;
    }

    // Retest if response is InfinityFree AES challenge HTML
    if (response.body.contains('toNumbers(')) {
      final cookie = InfinityCookieSolver.solveFromHtml(response.body);
      if (cookie != null) {
        try {
          response = await executeRequest();
        } catch (_) {}
      }
    }

    if (response.statusCode >= 200 && response.statusCode < 300) {
      try {
        return jsonDecode(response.body);
      } catch (_) {
        return response.body;
      }
    } else if (response.statusCode == 400 || response.statusCode == 401 || response.statusCode == 403) {
      try {
        final data = jsonDecode(response.body);
        throw ApiException(
          response.statusCode == 403 ? 'UNREGISTERED' : 'INVALID_CREDENTIALS',
          data['message'] ?? 'Kredensial atau data tidak valid.',
        );
      } catch (e) {
        if (e is ApiException) rethrow;
        throw const ApiException('INVALID_CREDENTIALS', 'Akses ditolak atau akun tidak terdaftar.');
      }
    } else {
      throw ApiException(
        'SERVER_ERROR',
        'Terjadi kesalahan pada server online (${response.statusCode}).',
      );
    }
  }
}
