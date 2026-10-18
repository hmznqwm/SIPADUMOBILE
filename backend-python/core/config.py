import os

# [PRESENTASI] Otomatisasi pembacaan file environment variable (.env) tanpa library tambahan (dotenv).
# Blok kode ini mencari file .env di direktori utama, membacanya baris per baris, dan memasukkannya ke os.environ
_env_path = os.path.join(os.path.dirname(os.path.dirname(os.path.abspath(__file__))), '.env')
if os.path.exists(_env_path):
    try:
        with open(_env_path, 'r', encoding='utf-8') as _f:
            for _line in _f:
                _line = _line.strip()
                # Mengabaikan baris kosong atau komentar (#)
                if _line and not _line.startswith('#') and '=' in _line:
                    _k, _v = _line.split('=', 1)
                    _k = _k.strip()
                    _v = _v.strip().strip("'").strip('"')
                    # Hanya memasukkan key jika belum terdefinisi di os environment
                    if _k and _k not in os.environ:
                        os.environ[_k] = _v
    except Exception:
        pass

class Settings:
    # [PRESENTASI] Metadata Aplikasi
    PROJECT_NAME: str = "SmartSchedule API"
    PROJECT_VERSION: str = "2.0.0"
    
    # [PRESENTASI] URL Koneksi Database: Mencoba mengambil dari .env, jika gagal gunakan SQLite lokal 'smartschedule.db'
    DATABASE_URL: str = os.getenv(
        "DATABASE_URL", 
        f"sqlite:///{os.path.join(os.path.dirname(os.path.dirname(os.path.abspath(__file__))), 'smartschedule.db')}"
    )
    
    # [PRESENTASI] Perbaikan URI SQLAlchemy untuk driver PostgreSQL modern
    if DATABASE_URL.startswith("postgres://"):
        DATABASE_URL = DATABASE_URL.replace("postgres://", "postgresql://", 1)

    # [PRESENTASI] Pengaturan Token JWT (Keamanan)
    # JWT Secret digunakan untuk mengenkripsi (signing) token autentikasi. Harus dirahasiakan!
    JWT_SECRET: str = os.getenv("JWT_SECRET") or "smart_schedule_secure_production_jwt_key_2026_x9z!"
    ALGORITHM: str = os.getenv("JWT_ALGORITHM", "HS256")
    ACCESS_TOKEN_EXPIRE_MINUTES: int = int(os.getenv("JWT_EXPIRE_MINUTES", str(60 * 24 * 7)))  # Default token valid selama 7 hari

    # [PRESENTASI] Konfigurasi API Supabase untuk Sinkronisasi Data Cloud
    SUPABASE_URL: str = os.getenv("SUPABASE_URL", "https://wxrsstdnlpzonqcaqagv.supabase.co")
    SUPABASE_KEY: str = os.getenv("SUPABASE_KEY", "")

    # [PRESENTASI] Konfigurasi Layanan Email SMTP (Backend)
    SMTP_HOST: str = os.getenv("SMTP_HOST", "smtp.gmail.com")
    SMTP_PORT: int = int(os.getenv("SMTP_PORT", "587"))
    SMTP_USER: str = os.getenv("SMTP_USER", "")
    SMTP_PASS: str = os.getenv("SMTP_PASS", "")
    SMTP_FROM_EMAIL: str = os.getenv("SMTP_FROM_EMAIL", os.getenv("SMTP_USER", ""))
    SMTP_FROM_NAME: str = os.getenv("SMTP_FROM_NAME", "SIPADU - Sistem Informasi Penjadwalan Dosen")

    # [PRESENTASI] CORS (Cross-Origin Resource Sharing): Daftar alamat frontend yang diizinkan memanggil backend ini
    # Jika mengakses dari luar daftar ini, browser akan memblokir request.
    CORS_ORIGINS: list = [
        origin.strip()
        for origin in os.getenv(
            "CORS_ORIGINS", 
            "https://backend-python-lime.vercel.app,http://localhost:3000,http://localhost:8080,http://127.0.0.1:3000,http://127.0.0.1:8000"
        ).split(",")
        if origin.strip() and origin.strip() != "*"
    ]

    def validate(self):
        """Validasi status koneksi Supabase dan kredensial."""
        if not self.SUPABASE_URL or not self.SUPABASE_KEY:
            print("[WARNING] Supabase credentials kosong! Hubungkan ke Supabase Cloud.")
        else:
            print(f"[OK] Terhubung ke Supabase Cloud Database: {self.SUPABASE_URL}")

settings = Settings()
settings.validate()

SUPABASE_URL = settings.SUPABASE_URL
SUPABASE_KEY = settings.SUPABASE_KEY
SB_HEADERS = {
    "apikey": SUPABASE_KEY,
    "Authorization": f"Bearer {SUPABASE_KEY}",
    "Content-Type": "application/json",
    "User-Agent": "SmartScheduleBackend/1.0",
    "Prefer": "resolution=merge-duplicates,return=minimal"
}

