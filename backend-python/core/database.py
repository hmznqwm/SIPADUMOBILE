import os
from sqlalchemy import create_engine
from sqlalchemy.ext.declarative import declarative_base
from sqlalchemy.orm import sessionmaker
from core.config import settings

# Database connection URL (Default to smartschedule.db SQLite with Supabase cloud sync)
DATABASE_URL = settings.DATABASE_URL

# On Vercel / serverless environment with SQLite, use in-memory DB to prevent read-only filesystem errors
if (os.getenv("VERCEL") or os.getenv("VERCEL_ENV")) and DATABASE_URL.startswith("sqlite"):
    DATABASE_URL = "sqlite:///:memory:"

# Database Engine Configuration
if DATABASE_URL.startswith("sqlite"):
    engine = create_engine(
        DATABASE_URL,
        connect_args={"check_same_thread": False},
        pool_pre_ping=True
    )
else:
    engine = create_engine(
        DATABASE_URL,
        pool_pre_ping=True,
        pool_size=10,
        max_overflow=20
    )

SessionLocal = sessionmaker(autocommit=False, autoflush=False, bind=engine)

Base = declarative_base()

def get_db():
    db = SessionLocal()
    try:
        yield db
    finally:
        db.close()
