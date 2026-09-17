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

# Auto create tables if running on SQLite or fresh DB
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

# Mount all API routers under both /api and root / for maximum compatibility
app.include_router(auth.router, prefix="/api")
app.include_router(master.router, prefix="/api")
app.include_router(availability.router, prefix="/api")
app.include_router(ajuan.router, prefix="/api")
app.include_router(schedule.router, prefix="/api")
app.include_router(engine_router.router, prefix="/api")
app.include_router(notifications.router, prefix="/api")
app.include_router(seed.router, prefix="/api")

# Also include directly for root routes
app.include_router(auth.router)
app.include_router(master.router)
app.include_router(availability.router)
app.include_router(ajuan.router)
app.include_router(schedule.router)
app.include_router(engine_router.router)
app.include_router(notifications.router)
app.include_router(seed.router)

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
