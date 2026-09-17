import os
import sys

# Add parent directory to sys.path to allow imports like 'routers.auth'
current_dir = os.path.dirname(os.path.abspath(__file__))
parent_dir = os.path.dirname(current_dir)
if parent_dir not in sys.path:
    sys.path.insert(0, parent_dir)

from fastapi import FastAPI
from fastapi.middleware.cors import CORSMiddleware
from core.database import Base, engine
from routers import auth, master, availability, ajuan, schedule, engine as engine_router, notifications, seed

# Auto create tables on SQLite / in-memory DB
try:
    Base.metadata.create_all(bind=engine)
except Exception as e:
    print(f"Warning on metadata create: {e}")

app = FastAPI(
    title="SmartSchedule API (Python FastAPI)",
    description="Smart Academic Course Scheduling Backend for Vercel & Supabase",
    version="2.0.0"
)

# Enable CORS for Mobile & Web clients
app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)

# Security Headers Middleware
@app.middleware("http")
async def add_security_headers(request, call_next):
    response = await call_next(request)
    response.headers["X-Content-Type-Options"] = "nosniff"
    response.headers["X-Frame-Options"] = "SAMEORIGIN"
    response.headers["X-XSS-Protection"] = "1; mode=block"
    return response

# Mount all API routers under /api prefix
app.include_router(auth.router, prefix="/api")
app.include_router(master.router, prefix="/api")
app.include_router(availability.router, prefix="/api")
app.include_router(ajuan.router, prefix="/api")
app.include_router(schedule.router, prefix="/api")
app.include_router(engine_router.router, prefix="/api")
app.include_router(notifications.router, prefix="/api")
app.include_router(seed.router, prefix="/api")

@app.on_event("startup")
def startup_sync_from_supabase_cloud():
    if os.getenv("VERCEL") or os.getenv("VERCEL_ENV"):
        return
    try:
        from core.database import SessionLocal
        from routers.engine import sync_supabase_to_sqlite_for_csp
        db = SessionLocal()
        sync_supabase_to_sqlite_for_csp(db)
        db.close()
        print("[SUPABASE CLOUD SYNC] Successfully loaded 100% online state from Supabase Cloud Database.")
    except Exception as err:
        print(f"[SUPABASE CLOUD SYNC WARNING] {err}")

@app.get("/")
@app.get("/api")
def health_check():
    return {
        "status": "success",
        "message": "SmartSchedule Python FastAPI Backend is running smoothly on Vercel!",
        "version": "2.0.0",
        "author": "Hamizan Qowiem",
        "docs_url": "/docs"
    }

# Vercel Serverless entrypoint
handler = app
