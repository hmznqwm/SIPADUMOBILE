from fastapi import APIRouter, Depends, HTTPException, Query, Request
from sqlalchemy.orm import Session
from typing import Optional, List
from core.database import get_db
from models.models import Availability, AvailabilitySlot, SlotWaktu, User, Setting
from datetime import datetime
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
            "submitted_at": datetime.utcnow().isoformat()
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
def get_availability(dosenId: Optional[str] = None, semesterId: Optional[str] = "SEM001", db: Session = Depends(get_db)):
    q = db.query(Availability)
    if dosenId:
        q = q.filter(Availability.dosen_id == dosenId)
    if semesterId:
        q = q.filter(Availability.semester_id == semesterId)
    
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
    body = await request.json()
    dosen_id = body.get("dosen_id") or body.get("dosenId")
    if isinstance(dosen_id, dict):
        dosen_id = dosen_id.get("id") or dosen_id.get("dosen_id")
    raw_slots = body.get("slot_ids") or body.get("slotIds") or []
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

    if not avail:
        avail_id = f"AVL_{secrets.token_hex(4).upper()}"
        avail = Availability(
            id=avail_id,
            dosen_id=dosen_id,
            semester_id=semester_id,
            status="submitted"
        )
        db.add(avail)
        db.flush()
    else:
        avail.status = "submitted"

    # Sync slots
    db.query(AvailabilitySlot).filter(AvailabilitySlot.availability_id == avail.id).delete()
    for s_id in slot_ids:
        db.add(AvailabilitySlot(availability_id=avail.id, slot_id=s_id))

    db.commit()
    sync_availability_to_supabase(avail.id, dosen_id, semester_id, avail.status, slot_ids)
    return {"status": "success", "message": "Ketersediaan waktu dosen berhasil disimpan."}

_in_memory_status = {"submission_window_active": "1"}

@router.get("/status")
@router.get("/status.php")
def get_submission_window_status(db: Session = Depends(get_db)):
    is_active = True
    try:
        setting = db.query(Setting).filter(Setting.setting_key == "submission_window_active").first()
        if setting:
            is_active = setting.setting_value in ["1", "true", "True"]
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
            setting.setting_value = val_str
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
