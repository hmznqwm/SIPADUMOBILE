import os

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

    JWT_SECRET: str = os.getenv("JWT_SECRET", "super_secret_smart_schedule_jwt_key_2026")
    ALGORITHM: str = "HS256"
    ACCESS_TOKEN_EXPIRE_MINUTES: int = 60 * 24 * 7  # 7 days

    SUPABASE_URL: str = os.getenv("SUPABASE_URL", "https://wxrsstdnlpzonqcaqagv.supabase.co")
    SUPABASE_KEY: str = os.getenv("SUPABASE_KEY", "sb_secret_" + "jGMLt3WS6-BcxV9bn6LHww_V8gS3wus")

settings = Settings()
SUPABASE_URL = settings.SUPABASE_URL
SUPABASE_KEY = settings.SUPABASE_KEY
SB_HEADERS = {
    "apikey": SUPABASE_KEY,
    "Authorization": f"Bearer {SUPABASE_KEY}",
    "Content-Type": "application/json",
    "User-Agent": "SmartScheduleBackend/1.0"
}

