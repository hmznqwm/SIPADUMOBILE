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
    connect_args = {"check_same_thread": False}
    extra_kwargs = {}
    if ":memory:" in DATABASE_URL:
        from sqlalchemy.pool import StaticPool
        extra_kwargs["poolclass"] = StaticPool
        extra_kwargs["connect_args"] = connect_args
    else:
        extra_kwargs["connect_args"] = connect_args
        extra_kwargs["pool_pre_ping"] = True

    engine = create_engine(DATABASE_URL, **extra_kwargs)
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
    db = None
    try:
        db = SessionLocal()
        yield db
    except Exception:
        yield None
    finally:
        if db is not None:
            try:
                db.close()
            except Exception:
                pass
