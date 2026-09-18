import os

# Membaca .env secara otomatis menggunakan Python Standard Library (Tanpa error di IDE)
_env_path = os.path.join(os.path.dirname(os.path.dirname(os.path.abspath(__file__))), '.env')
if os.path.exists(_env_path):
    try:
        with open(_env_path, 'r', encoding='utf-8') as _f:
            for _line in _f:
                _line = _line.strip()
                if _line and not _line.startswith('#') and '=' in _line:
                    _k, _v = _line.split('=', 1)
                    _k = _k.strip()
                    _v = _v.strip().strip("'").strip('"')
                    if _k and _k not in os.environ:
                        os.environ[_k] = _v
    except Exception:
        pass

class Settings:
    PROJECT_NAME: str = "SmartSchedule API"
    PROJECT_VERSION: str = "2.0.0"
    
    # Database connection URL (Default to smartschedule.db SQLite with Supabase cloud sync)
    DATABASE_URL: str = os.getenv(
        "DATABASE_URL", 
        f"sqlite:///{os.path.join(os.path.dirname(os.path.dirname(os.path.abspath(__file__))), 'smartschedule.db')}"
    )
    
    # Fix for SQLAlchemy if connection string uses postgres:// instead of postgresql://
    if DATABASE_URL.startswith("postgres://"):
        DATABASE_URL = DATABASE_URL.replace("postgres://", "postgresql://", 1)

    # JWT Configuration (Menggunakan env var jika ada, atau fallback aman)
    JWT_SECRET: str = os.getenv("JWT_SECRET") or "super_secret_smart_schedule_jwt_key_2026"
    ALGORITHM: str = os.getenv("JWT_ALGORITHM", "HS256")
    ACCESS_TOKEN_EXPIRE_MINUTES: int = int(os.getenv("JWT_EXPIRE_MINUTES", str(60 * 24 * 7)))  # 7 days

    # Supabase Configuration (Dimuat dari environment variable / .env)
    SUPABASE_URL: str = os.getenv("SUPABASE_URL", "https://wxrsstdnlpzonqcaqagv.supabase.co")
    SUPABASE_KEY: str = os.getenv("SUPABASE_KEY", "")

    # CORS Allowed Origins
    CORS_ORIGINS: list = [
        origin.strip()
        for origin in os.getenv("CORS_ORIGINS", "https://backend-python-lime.vercel.app,http://localhost:3000,*").split(",")
        if origin.strip()
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
    "Prefer": "return=minimal"
}
