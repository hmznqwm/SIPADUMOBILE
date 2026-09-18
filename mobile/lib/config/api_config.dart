// File: api_config.dart
// Deskripsi: File konfigurasi URL dasar (base URL) untuk terhubung ke Python FastAPI Backend.

class ApiConfig {
  /// Ubah ke false agar aplikasi Flutter terhubung langsung ke Python FastAPI Server & Database Supabase Cloud
  static const bool useMockBackend = false;

  /// URL Backend Python FastAPI (Production Vercel Cloud Server):
  static const String baseUrl = 'https://backend-python-lime.vercel.app/api';

  /// Fallback URL untuk emulator / local loopback:
  static const String localFallbackUrl = 'http://127.0.0.1:8000/api';

  /// Supabase Cloud Credentials (hanya publishable/anon key — AMAN untuk client-side):
  static const String supabaseUrl = 'https://wxrsstdnlpzonqcaqagv.supabase.co';
  static const String supabasePublishableKey = 'sb_publishable_4SsaAIHeYKPTeTHIxmdFIg_39jPvaKn';
  // CATATAN: Secret Key TIDAK BOLEH ada di client-side app. Semua operasi
  // yang memerlukan service_role key harus dilakukan melalui backend API.

  /// Google OAuth Web Client ID
  static const String googleClientId = '552288350914-qq3qt5b2j851vgvl4dv0kabjhd3dvjqm.apps.googleusercontent.com';
}
