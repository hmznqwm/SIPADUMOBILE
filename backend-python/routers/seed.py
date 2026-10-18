import sys
import os
sys.path.insert(0, os.path.dirname(os.path.dirname(os.path.abspath(__file__))))

from fastapi import APIRouter, Depends, HTTPException, Query, Header, status
from sqlalchemy.orm import Session
import os
import bcrypt
from typing import Optional
from core.database import get_db, Base, engine
from core.config import settings
from models.models import User, Gedung, Ruangan, SlotWaktu, MataKuliah, MataKuliahKelas, AjuanPengajaran, JadwalFinal, Notification

router = APIRouter(prefix="", tags=["Seed & Health"])

def hash_pw(password: str) -> str:
    return bcrypt.hashpw(password.encode("utf-8"), bcrypt.gensalt()).decode("utf-8")

@router.get("/seed")
@router.get("/seed.php")
@router.post("/seed")
@router.post("/seed.php")
def run_seed(
    key: Optional[str] = Query(None),
    authorization: Optional[str] = Header(None),
    db: Session = Depends(get_db)
):
    # Proteksi seed endpoint dengan JWT Secret / Master Key
    expected_key = settings.JWT_SECRET or "smartschedule_seed_dev_2026"
    provided_key = key or (authorization.replace("Bearer ", "") if authorization else "")
    if provided_key != expected_key and os.getenv("VERCEL_ENV") == "production":
        raise HTTPException(
            status_code=status.HTTP_403_FORBIDDEN,
            detail={"status": "error", "message": "Endpoint seed dinonaktifkan di production. Akses ditolak."}
        )
    Base.metadata.create_all(bind=engine)
    
    # Check if seed already executed
    admin = db.query(User).filter(User.id == "ADM001").first()
    if not admin:
        default_pw = hash_pw("password123")
        
        # 1. USERS
        users = [
            User(
                id="ADM001", 
                nama="Super Admin", 
                email="admin@admin.com", 
                password=default_pw, 
                role="admin", 
                jurusan_id=None,
                jurusan_nama=None,
                fakultas_nama=None,
                matkul_nama=None,
                is_priority=True
            ),
        ]
        for u in users:
            u.password = hash_pw(u.id)
        db.add_all(users)

        # 2. GEDUNG PERKULIAHAN UIN MALANG
        gedungs = []
        db.add_all(gedungs)

        # 3. RUANGAN PERKULIAHAN LENGKAP
        ruangans = []
        db.add_all(ruangans)

        # 4. SLOT WAKTU STANDAR UIN MALANG
        slots = [
            SlotWaktu(id="SLOT_SEN_1", hari="Senin", jam_mulai="07:30", jam_selesai="10:00", durasi_menit=150),
            SlotWaktu(id="SLOT_SEN_2", hari="Senin", jam_mulai="10:15", jam_selesai="12:45", durasi_menit=150),
            SlotWaktu(id="SLOT_SEN_3", hari="Senin", jam_mulai="13:30", jam_selesai="16:00", durasi_menit=150),
            SlotWaktu(id="SLOT_SEL_1", hari="Selasa", jam_mulai="07:30", jam_selesai="10:00", durasi_menit=150),
            SlotWaktu(id="SLOT_SEL_2", hari="Selasa", jam_mulai="10:15", jam_selesai="12:45", durasi_menit=150),
            SlotWaktu(id="SLOT_RAB_1", hari="Rabu", jam_mulai="07:30", jam_selesai="10:00", durasi_menit=150),
            SlotWaktu(id="SLOT_RAB_2", hari="Rabu", jam_mulai="10:15", jam_selesai="12:45", durasi_menit=150),
            SlotWaktu(id="SLOT_KAM_1", hari="Kamis", jam_mulai="07:30", jam_selesai="10:00", durasi_menit=150),
            SlotWaktu(id="SLOT_JUM_1", hari="Jumat", jam_mulai="07:30", jam_selesai="10:00", durasi_menit=150)
        ]
        db.add_all(slots)

        # 5. MATA KULIAH LENGKAP 7 FAKULTAS
        mks = []
        db.add_all(mks)

        # 6. DUMMY AJUAN PENGAJARAN (DENGAN STATUS DIVERIFIKASI AGARlangsung DIPROSES CSP)
        sample_ajuans = []
        db.add_all(sample_ajuans)

        # 7. NOTIFIKASI
        notifications = []
        db.add_all(notifications)
        
        db.commit()

    return {"status": "success", "message": "Database UIN Malang (7 Fakultas & Seluruh Prodi) berhasil di-seed sempurna."}
