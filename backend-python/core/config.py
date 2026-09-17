import os

class Settings:
    PROJECT_NAME: str = "SmartSchedule API"
    PROJECT_VERSION: str = "2.0.0"
    
    # Database connection URL (PostgreSQL Supabase, or SQLite for local dev)
    DATABASE_URL: str = os.getenv(
        "DATABASE_URL", 
        "postgresql://postgres:postgres@localhost:5432/smartschedule"
    )
    
    # Fix for SQLAlchemy if connection string uses postgres:// instead of postgresql://
    if DATABASE_URL.startswith("postgres://"):
        DATABASE_URL = DATABASE_URL.replace("postgres://", "postgresql://", 1)

    JWT_SECRET: str = os.getenv("JWT_SECRET", "super_secret_smart_schedule_jwt_key_2026")
    ALGORITHM: str = "HS256"
    ACCESS_TOKEN_EXPIRE_MINUTES: int = 60 * 24 * 7  # 7 days

settings = Settings()
