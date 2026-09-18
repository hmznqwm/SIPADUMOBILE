import os
import sys
import logging

# Configure logging
logging.basicConfig(level=logging.INFO, format='[%(asctime)s] %(name)s %(levelname)s: %(message)s')

# Add parent directory to sys.path to allow imports like 'routers.auth'
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

# Auto create tables on SQLite / in-memory DB
try:
    Base.metadata.create_all(bind=engine)
except Exception as e:
    print(f"Warning on metadata create: {e}")

# Rate Limiter (safely imported with fallback)
try:
    from slowapi import Limiter, _rate_limit_exceeded_handler
    from slowapi.util import get_remote_address
    from slowapi.errors import RateLimitExceeded
    limiter = Limiter(key_func=get_remote_address)
    HAS_SLOWAPI = True
except ImportError:
    limiter = None
    HAS_SLOWAPI = False

@asynccontextmanager
async def lifespan(app: FastAPI):
    """Startup & shutdown events using modern lifespan protocol."""
    # Startup: sync from Supabase
    if not (os.getenv("VERCEL") or os.getenv("VERCEL_ENV")):
        try:
            from core.database import SessionLocal
            from routers.engine import sync_supabase_to_sqlite_for_csp
            db = SessionLocal()
            sync_supabase_to_sqlite_for_csp(db)
            db.close()
            print("[SUPABASE CLOUD SYNC] Successfully loaded 100% online state from Supabase Cloud Database.")
        except Exception as err:
            print(f"[SUPABASE CLOUD SYNC WARNING] {err}")
    yield
    # Shutdown: nothing to clean up

app = FastAPI(
    title="SmartSchedule API (Python FastAPI)",
    description="Smart Academic Course Scheduling Backend for Vercel & Supabase",
    version="2.0.0",
    lifespan=lifespan,
    # Disable docs in production for security
    docs_url="/docs" if os.getenv("VERCEL_ENV") != "production" else None,
    redoc_url=None,
)

# Rate limiter state
if HAS_SLOWAPI and limiter:
    app.state.limiter = limiter
    app.add_exception_handler(RateLimitExceeded, _rate_limit_exceeded_handler)

# Enable CORS — Restricted to specific origins
app.add_middleware(
    CORSMiddleware,
    allow_origins=settings.CORS_ORIGINS,
    allow_credentials=True,
    allow_methods=["GET", "POST", "PUT", "DELETE", "PATCH"],
    allow_headers=["Authorization", "Content-Type", "Accept"],
)

# Security Headers Middleware
@app.middleware("http")
async def add_security_headers(request: Request, call_next):
    response: Response = await call_next(request)
    response.headers["X-Content-Type-Options"] = "nosniff"
    response.headers["X-Frame-Options"] = "DENY"
    response.headers["Referrer-Policy"] = "strict-origin-when-cross-origin"
    response.headers["Permissions-Policy"] = "camera=(), microphone=(), geolocation=()"
    response.headers["Cache-Control"] = "no-store, no-cache, must-revalidate"
    response.headers["Pragma"] = "no-cache"
    if request.url.scheme == "https":
        response.headers["Strict-Transport-Security"] = "max-age=31536000; includeSubDomains"
    return response

# Mount all API routers under /api prefix
app.include_router(auth.router, prefix="/api")
app.include_router(master.router, prefix="/api")
app.include_router(availability.router, prefix="/api")
app.include_router(ajuan.router, prefix="/api")
app.include_router(schedule.router, prefix="/api")
app.include_router(engine_router.router, prefix="/api")
app.include_router(notifications.router, prefix="/api")

# Seed router hanya aktif jika BUKAN production
if os.getenv("VERCEL_ENV") != "production":
    app.include_router(seed.router, prefix="/api")

@app.get("/")
@app.get("/api")
def health_check():
    return {
        "status": "success",
        "message": "SmartSchedule Python FastAPI Backend is running smoothly on Vercel!",
        "version": "2.1.0-SECURITY-HARDENED",
        "docs_url": "/docs"
    }

# Vercel Serverless entrypoint
handler = app
