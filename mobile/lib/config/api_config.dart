// File: api_config.dart
// Deskripsi: File konfigurasi URL dasar (base URL) dan saklar mock backend untuk REST API server.
// Fungsi: Menyediakan alamat endpoint server backend PHP/MySQL online dan pengaturan mode pengujian.

class ApiConfig {
  /// Ubah ke false untuk menghubungkan aplikasi Flutter langsung ke server backend online
  static const bool useMockBackend = false;

  /// URL Backend REST API Server Active (InfinityFree / Custom Host):
  static const String baseUrl = 'http://sistemjadwalpintar.freedev.app/api';

  /// Google OAuth Web Client ID
  static const String googleClientId = '552288350914-qq3qt5b2j851vgvl4dv0kabjhd3dvjqm.apps.googleusercontent.com';
}
