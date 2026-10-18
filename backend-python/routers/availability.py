import sys
import os
sys.path.insert(0, os.path.dirname(os.path.dirname(os.path.abspath(__file__))))

from fastapi import APIRouter, Depends, HTTPException, Query, Request
from sqlalchemy.orm import Session
from typing import Optional, List
from core.database import get_db
from models.models import Availability, AvailabilitySlot, SlotWaktu, User, Setting
from datetime import datetime, timezone
import secrets
import requests

from core.config import SUPABASE_URL, SUPABASE_KEY, SB_HEADERS
from core.security import sanitize_supabase_param
import logging

logger = logging.getLogger("smartschedule.availability")

def sync_availability_to_supabase(avail_id: str, dosen_id: str, semester_id: str, status: str, slot_ids: list):
    try:
        url = f"{SUPABASE_URL}/rest/v1/availability"
        payload = {
            "id": avail_id,
            "dosen_id": dosen_id,
            "semester_id": semester_id,
            "status": status,
            "submitted_at": datetime.now(timezone.utc).isoformat(),
            "updated_at": datetime.now(timezone.utc).isoformat()
        }
        requests.post(url, headers=SB_HEADERS, json=payload, timeout=5)
        # Delete old slots and insert new
        safe_id = sanitize_supabase_param(avail_id)
        del_url = f"{SUPABASE_URL}/rest/v1/availability_slots?availability_id=eq.{safe_id}"
        requests.delete(del_url, headers={"apikey": SUPABASE_KEY, "Authorization": f"Bearer {SUPABASE_KEY}"}, timeout=5)
        if slot_ids:
            slot_url = f"{SUPABASE_URL}/rest/v1/availability_slots"
            slots_payload = [{"availability_id": avail_id, "slot_id": str(sid)} for sid in slot_ids]
            requests.post(slot_url, headers=SB_HEADERS, json=slots_payload, timeout=5)
    except Exception as e:
        logger.warning(f"Failed to sync availability to Supabase: {e}")

router = APIRouter(prefix="/availability", tags=["Availability"])

@router.get("")
@router.get("/")
@router.get("/index.php")
def get_availability(
    dosenId: Optional[str] = Query(None),
    dosen_id: Optional[str] = Query(None),
    semesterId: Optional[str] = Query("SEM001"),
    semester_id: Optional[str] = Query("SEM001"),
    db: Session = Depends(get_db)
):
    target_dosen = dosenId or dosen_id
    target_sem = semesterId or semester_id or "SEM001"
    q = db.query(Availability)
    if target_dosen:
        q = q.filter(Availability.dosen_id == target_dosen)
    if target_sem:
        q = q.filter(Availability.semester_id == target_sem)
    
    items = q.all()
    data = []
    for a in items:
        slot_ids = [s.slot_id for s in a.slots]
        dosen_nama = a.dosen.nama if a.dosen else ""
        data.append({
            "id": a.id,
            "dosenId": a.dosen_id,
            "dosen_id": a.dosen_id,
            "dosenNama": dosen_nama,
            "dosen_nama": dosen_nama,
            "semesterId": a.semester_id,
            "semester_id": a.semester_id,
            "status": a.status,
            "submittedAt": str(a.submitted_at),
            "submitted_at": str(a.submitted_at),
            "slotIds": slot_ids,
            "slot_ids": slot_ids
        })
    return {"status": "success", "data": data}

@router.post("")
@router.post("/")
@router.post("/index.php")
@router.post("/submit.php")
async def submit_availability(request: Request, db: Session = Depends(get_db)):
    """
    [PRESENTASI] Pengisian Ketersediaan Waktu Dosen:
    Dosen memilih slot waktu kosong yang mereka inginkan (hari & jam tertentu) untuk mengajar.
    Data ini menjadi salah satu penentu (hard constraint) bagi CSP Engine agar tidak menempatkan dosen
    di waktu yang mereka tidak bisa mengajar.
    """
    body = await request.json()
    dosen_id = body.get("dosen_id") or body.get("dosenId")
    if isinstance(dosen_id, dict):
        dosen_id = dosen_id.get("id") or dosen_id.get("dosen_id")
    raw_slots = body.get("slot_ids") or body.get("slotIds") or body.get("selectedSlotIds") or body.get("selected_slot_ids") or []
    semester_id = body.get("semester_id") or body.get("semesterId") or "SEM001"

    if not dosen_id:
        raise HTTPException(status_code=400, detail={"status": "error", "message": "ID Dosen wajib disertakan."})

    slot_ids = []
    for item in raw_slots:
        if isinstance(item, dict):
            s_id = item.get("id") or item.get("slot_id") or item.get("slotId")
            if s_id:
                slot_ids.append(str(s_id))
        elif item:
            slot_ids.append(str(item))

    avail = db.query(Availability).filter(
        Availability.dosen_id == dosen_id,
        Availability.semester_id == semester_id
    ).first()

    now_utc = datetime.now(timezone.utc)
    if not avail:
        avail_id = f"AVL_{dosen_id}_{semester_id}"
        avail = Availability(
            id=avail_id,
            dosen_id=dosen_id,
            semester_id=semester_id,
            status="submitted",
            submitted_at=now_utc
        )
        db.add(avail)
        db.flush()
    else:
        setattr(avail, "status", "submitted")
        setattr(avail, "submitted_at", now_utc)

    # Sync slots
    db.query(AvailabilitySlot).filter(AvailabilitySlot.availability_id == avail.id).delete()
    for s_id in slot_ids:
        db.add(AvailabilitySlot(availability_id=avail.id, slot_id=s_id))

    db.commit()
    sync_availability_to_supabase(avail.id, dosen_id, semester_id, str(getattr(avail, "status", "submitted")), slot_ids)
    return {
        "status": "success",
        "message": "Ketersediaan waktu dosen berhasil disimpan.",
        "data": {
            "id": avail.id,
            "dosenId": dosen_id,
            "dosen_id": dosen_id,
            "semesterId": semester_id,
            "semester_id": semester_id,
            "status": str(getattr(avail, "status", "submitted")),
            "submittedAt": str(getattr(avail, "submitted_at", now_utc)),
            "submitted_at": str(getattr(avail, "submitted_at", now_utc)),
            "slotIds": slot_ids,
            "slot_ids": slot_ids,
        }
    }

_in_memory_status = {"submission_window_active": "1"}

@router.get("/status")
@router.get("/status.php")
def get_submission_window_status(db: Session = Depends(get_db)):
    is_active = True
    try:
        setting = db.query(Setting).filter(Setting.setting_key == "submission_window_active").first()
        if setting:
            is_active = str(getattr(setting, "setting_value", "1")) in ["1", "true", "True"]
        else:
            val = _in_memory_status.get("submission_window_active", "1")
            is_active = val in ["1", "true", "True"]
    except Exception:
        val = _in_memory_status.get("submission_window_active", "1")
        is_active = val in ["1", "true", "True"]
    return {"status": "success", "isActive": is_active, "is_active": is_active}

@router.post("/status")
@router.post("/status.php")
async def set_submission_window_status(request: Request, db: Session = Depends(get_db)):
    try:
        body = await request.json()
    except Exception:
        body = {}
    active_val = body.get("active")
    if active_val is None:
        active_val = body.get("isActive", True)
    
    val_str = "1" if bool(active_val) else "0"
    _in_memory_status["submission_window_active"] = val_str
    try:
        setting = db.query(Setting).filter(Setting.setting_key == "submission_window_active").first()
        if not setting:
            setting = Setting(setting_key="submission_window_active", setting_value=val_str)
            db.add(setting)
        else:
            setattr(setting, "setting_value", val_str)
        db.commit()
    except Exception:
        pass
    return {"status": "success", "isActive": bool(active_val), "is_active": bool(active_val)}

def patch_availability_status_in_supabase(dosen_id: str, new_status: str):
    try:
        url = f"{SUPABASE_URL}/rest/v1/availability?dosen_id=eq.{dosen_id}"
        headers = {
            "apikey": SUPABASE_KEY,
            "Authorization": f"Bearer {SUPABASE_KEY}",
            "Content-Type": "application/json"
        }
        requests.patch(url, headers=headers, json={"status": new_status}, timeout=5)
    except Exception:
        pass

# ─── MULTI-TIER VERIFIKASI AVAILABILITY ────────────────────────────────
@router.post("/verify")
@router.post("/verify.php")
async def verify_availability(request: Request, db: Session = Depends(get_db)):
    """
    [PRESENTASI] Verifikasi Ketersediaan Waktu:
    Sama seperti Ajuan Mengajar, ketersediaan waktu dosen juga diverifikasi berjenjang.
    Kaprodi mengecek apakah waktu yang diminta logis, lalu disahkan oleh Dekan.
    """
    body = await request.json()
    action = body.get("action", "")

    if action == "verify_kajur" and body.get("dosenId"):
        d_id = body["dosenId"]
        db.query(Availability).filter(Availability.dosen_id == d_id).update({"status": "verified_kajur"})
        db.commit()
        patch_availability_status_in_supabase(d_id, "verified_kajur")
        return {"status": "success", "message": "Ajuan dosen berhasil diverifikasi KaProdi"}

    if action == "approve_dekan" and body.get("fakultasNama"):
        dosen_ids = [u.id for u in db.query(User).filter(User.fakultas_nama == body["fakultasNama"]).all()]
        if dosen_ids:
            db.query(Availability).filter(Availability.dosen_id.in_(dosen_ids)).update({"status": "approved_dekan"}, synchronize_session=False)
            db.commit()
            for did in dosen_ids:
                patch_availability_status_in_supabase(did, "approved_dekan")
        return {"status": "success", "message": "Seluruh ajuan fakultas disetujui Dekan"}

    return {"status": "success"}
