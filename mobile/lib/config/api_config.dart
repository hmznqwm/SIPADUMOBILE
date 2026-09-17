// File: api_config.dart
// Deskripsi: File konfigurasi URL dasar (base URL) untuk terhubung ke Python FastAPI Backend.

class ApiConfig {
  /// Ubah ke false agar aplikasi Flutter terhubung langsung ke Python FastAPI Server (Database SQLite smartschedule.db)
  static const bool useMockBackend = false;

  /// URL Backend Python FastAPI (Host Laptop Wi-Fi IP / Localhost):
  static const String baseUrl = 'http://192.168.100.248:8000/api';

  /// Fallback URL untuk emulator / local loopback:
  static const String localFallbackUrl = 'http://127.0.0.1:8000/api';

  /// Google OAuth Web Client ID
  static const String googleClientId = '552288350914-qq3qt5b2j851vgvl4dv0kabjhd3dvjqm.apps.googleusercontent.com';
}
