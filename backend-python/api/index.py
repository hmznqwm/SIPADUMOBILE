import os
import sys
import logging

# [PRESENTASI] Konfigurasi logging: Mengatur format output log untuk keperluan monitoring dan debugging aplikasi.
logging.basicConfig(level=logging.INFO, format='[%(asctime)s] %(name)s %(levelname)s: %(message)s')

# [PRESENTASI] Menambahkan folder parent (backend-python) ke dalam sys.path
# Tujuannya agar Python bisa mengenali dan mengimpor modul-modul lain seperti 'routers' dan 'core'.
current_dir = os.path.dirname(os.path.abspath(__file__))
parent_dir = os.path.dirname(current_dir)
if parent_dir not in sys.path:
    sys.path.insert(0, parent_dir)

from contextlib import asynccontextmanager
from fastapi import FastAPI, Request, Response
from fastapi.middleware.cors import CORSMiddleware
from core.database import Base, engine
from core.config import settings
from routers import auth, master, availability, ajuan, schedule, engine as engine_router, notifications, seed

# [PRESENTASI] Inisialisasi Database: Membuat semua tabel di database (SQLite) berdasarkan model yang telah didefinisikan jika belum ada.
try:
    Base.metadata.create_all(bind=engine)
except Exception as e:
    print(f"Warning on metadata create: {e}")

# [PRESENTASI] Konfigurasi Rate Limiter: Membatasi jumlah permintaan (request) dari satu IP untuk mencegah serangan DDoS atau spam.
try:
    from slowapi import Limiter, _rate_limit_exceeded_handler
    from slowapi.util import get_remote_address
    from slowapi.errors import RateLimitExceeded
    limiter = Limiter(key_func=get_remote_address)
    HAS_SLOWAPI = True
except ImportError:
    limiter = None
    HAS_SLOWAPI = False

# [PRESENTASI] Lifespan (Startup & Shutdown Event): Fungsi yang dijalankan saat server FastAPI pertama kali hidup (startup) dan mati (shutdown).
@asynccontextmanager
async def lifespan(app: FastAPI):
    """Startup & shutdown events using modern lifespan protocol."""
    # [PRESENTASI] Startup: Sinkronisasi data dari Supabase Cloud ke database lokal/in-memory
    try:
        from core.database import SessionLocal, Base, engine
        from routers.engine import sync_supabase_to_sqlite_for_csp
        Base.metadata.create_all(bind=engine)
        db = SessionLocal()
        if db:
            try:
                sync_supabase_to_sqlite_for_csp(db) # Melakukan sinkronisasi state untuk algoritma CSP & API
            except Exception as sync_err:
                print(f"[SUPABASE SYNC ERROR] {sync_err}")
            finally:
                try:
                    db.close()
                except Exception:
                    pass
        print("[SUPABASE CLOUD SYNC] Successfully completed startup sync cycle.")
    except Exception as err:
        print(f"[SUPABASE CLOUD SYNC WARNING] {err}")
    yield
    # [PRESENTASI] Shutdown: Proses pembersihan sumber daya saat server dimatikan

# [PRESENTASI] Pembuatan Instance FastAPI: Inisialisasi aplikasi backend utama dengan judul, deskripsi, versi, dan fungsi lifespan.
app = FastAPI(
    title="SmartSchedule API (Python FastAPI)",
    description="Smart Academic Course Scheduling Backend for Vercel & Supabase",
    version="2.0.0",
    lifespan=lifespan,
    # [PRESENTASI] Keamanan Tambahan: Mematikan akses ke dokumentasi otomatis (/docs) saat dijalankan di server production
    docs_url="/docs" if os.getenv("VERCEL_ENV") != "production" else None,
    redoc_url=None,
)

from fastapi.responses import JSONResponse
from fastapi.exceptions import HTTPException, RequestValidationError

@app.exception_handler(HTTPException)
async def http_exception_handler(request: Request, exc: HTTPException):
    if isinstance(exc.detail, dict):
        return JSONResponse(status_code=exc.status_code, content=exc.detail)
    return JSONResponse(status_code=exc.status_code, content={"status": "error", "message": str(exc.detail)})

@app.exception_handler(RequestValidationError)
async def validation_exception_handler(request: Request, exc: RequestValidationError):
    return JSONResponse(status_code=422, content={"status": "error", "message": "Validasi request gagal.", "errors": exc.errors()})

# [PRESENTASI] Mengaktifkan Rate Limiter pada object FastAPI utama jika pustakanya tersedia.
if HAS_SLOWAPI and limiter:
    app.state.limiter = limiter
    app.add_exception_handler(RateLimitExceeded, _rate_limit_exceeded_handler)

# [PRESENTASI] Konfigurasi CORS (Cross-Origin Resource Sharing): Mengizinkan frontend dari domain/origin tertentu untuk mengakses API backend ini.
app.add_middleware(
    CORSMiddleware,
    allow_origins=settings.CORS_ORIGINS,
    allow_credentials=True,
    allow_methods=["GET", "POST", "PUT", "DELETE", "PATCH"],
    allow_headers=["Authorization", "Content-Type", "Accept"],
)

# [PRESENTASI] Middleware Security Headers: Menambahkan header HTTP keamanan untuk melindungi dari serangan umum (XSS, Clickjacking, MIME-sniffing).
@app.middleware("http")
async def add_security_headers(request: Request, call_next):
    response: Response = await call_next(request)
    response.headers["X-Content-Type-Options"] = "nosniff" # Mencegah browser menebak MIME type
    response.headers["X-Frame-Options"] = "DENY" # Mencegah aplikasi dimuat dalam iframe (Clickjacking)
    response.headers["Referrer-Policy"] = "strict-origin-when-cross-origin"
    response.headers["Permissions-Policy"] = "camera=(), microphone=(), geolocation=()" # Menonaktifkan akses sensor browser
    response.headers["Cache-Control"] = "no-store, no-cache, must-revalidate" # Tidak menyimpan data caching
    response.headers["Pragma"] = "no-cache"
    if request.url.scheme == "https":
        response.headers["Strict-Transport-Security"] = "max-age=31536000; includeSubDomains" # Memaksa penggunaan koneksi aman (HSTS)
    return response

# [PRESENTASI] Routing API: Mendaftarkan seluruh endpoint yang dipisah tiap modul ke dalam satu jalur (prefix '/api').
app.include_router(auth.router, prefix="/api")          # Endpoint Auth: Login, Register, Manajemen Token
app.include_router(master.router, prefix="/api")        # Endpoint Data Master: Ruangan, Mata Kuliah, Dosen
app.include_router(availability.router, prefix="/api")  # Endpoint Ketersediaan: Waktu kosong dosen
app.include_router(ajuan.router, prefix="/api")         # Endpoint Ajuan: Data plot/pengajuan jadwal
app.include_router(schedule.router, prefix="/api")      # Endpoint Schedule: Pengelolaan hasil jadwal
app.include_router(engine_router.router, prefix="/api") # Endpoint Engine: Pemicu algoritma penjadwalan
app.include_router(notifications.router, prefix="/api") # Endpoint Notifications: Pemberitahuan sistem

# [PRESENTASI] Mendaftarkan Endpoint Seeding (pembuatan data dummy) hanya di environment lokal (development).
if os.getenv("VERCEL_ENV") != "production":
    app.include_router(seed.router, prefix="/api")

# [PRESENTASI] Endpoint Health Check: Root endpoint untuk mengecek apakah server merespon dan beroperasi dengan baik.
@app.get("/")
@app.get("/api")
def health_check():
    return {
        "status": "success",
        "message": "SmartSchedule Python FastAPI Backend is running smoothly on Vercel!",
        "version": "2.1.0-SECURITY-HARDENED",
        "docs_url": "/docs"
    }

# [PRESENTASI] Handler spesifik untuk Serverless Deployment (contohnya di Vercel).
try:
    from mangum import Mangum
    handler = Mangum(app, api_gateway_base_path=None)
except Exception:
    handler = app
