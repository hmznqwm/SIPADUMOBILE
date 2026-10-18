import os
from sqlalchemy import create_engine
from sqlalchemy.ext.declarative import declarative_base
from sqlalchemy.orm import sessionmaker
from core.config import settings

# [PRESENTASI] Konfigurasi Database URL
# Secara default, aplikasi menggunakan SQLite lokal ('smartschedule.db').
DATABASE_URL = settings.DATABASE_URL

# [PRESENTASI] Deteksi Environment Serverless (Vercel)
# Jika aplikasi berjalan di Vercel (read-only filesystem) dan menggunakan SQLite, ubah ke in-memory database agar tidak terjadi error penulisan file.
if (os.getenv("VERCEL") or os.getenv("VERCEL_ENV")) and DATABASE_URL.startswith("sqlite"):
    DATABASE_URL = "sqlite:////tmp/smartschedule.db"

# [PRESENTASI] Konfigurasi Engine Database (SQLAlchemy)
if DATABASE_URL.startswith("sqlite"):
    connect_args = {"check_same_thread": False}
    extra_kwargs = {"connect_args": connect_args, "pool_pre_ping": True}
    engine = create_engine(DATABASE_URL, **extra_kwargs)
else:
    # [PRESENTASI] Konfigurasi untuk Database relasional lain (seperti PostgreSQL)
    engine = create_engine(
        DATABASE_URL,
        pool_pre_ping=True, # Menguji koneksi sebelum mengeksekusi query (mencegah error 'MySQL server has gone away')
        pool_size=10,       # Maksimal 10 koneksi tetap yang dibuka
        max_overflow=20     # Maksimal 20 koneksi tambahan jika sistem sedang sibuk
    )

# [PRESENTASI] Membuat factory (pabrik) session untuk interaksi dengan database
SessionLocal = sessionmaker(autocommit=False, autoflush=False, bind=engine)

# [PRESENTASI] Base class yang akan di-inherit (diwariskan) oleh semua model database kita (Tabel)
Base = declarative_base()

# [PRESENTASI] Dependency Injection: Menyediakan Session Database ke setiap endpoint FastAPI
# Fungsi ini membuka koneksi DB saat API diakses, lalu memutus/menutup koneksi setelah respon dikirim.
def get_db():
    db = SessionLocal()
    try:
        yield db
    finally:
        try:
            db.close()
        except Exception:
            pass
