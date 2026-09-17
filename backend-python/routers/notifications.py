from fastapi import APIRouter, Depends, HTTPException, Query, Request
from sqlalchemy.orm import Session
from typing import Optional, List
from core.database import get_db
from models.models import Notification
import secrets

router = APIRouter(prefix="/notifications", tags=["Notifications"])

def format_notif(n: Notification):
    return {
        "id": n.id,
        "userId": n.user_id,
        "user_id": n.user_id,
        "title": n.title,
        "message": n.message,
        "type": n.type,
        "isRead": bool(n.is_read),
        "is_read": bool(n.is_read),
        "createdAt": str(n.created_at),
        "created_at": str(n.created_at)
    }

@router.get("")
@router.get("/")
@router.get("/index.php")
def get_notifications(
    userId: Optional[str] = None,
    user_id: Optional[str] = None,
    db: Session = Depends(get_db)
):
    uid = userId or user_id
    q = db.query(Notification)
    if uid:
        q = q.filter(
            (Notification.user_id == uid) | 
            (Notification.user_id.is_(None)) | 
            (Notification.user_id == 'GLOBAL') | 
            (Notification.user_id == '')
        )
    
    items = q.order_by(Notification.created_at.desc()).all()
    return {"status": "success", "data": [format_notif(n) for n in items]}

@router.put("")
@router.put("/")
@router.put("/index.php")
@router.post("")
@router.post("/")
@router.post("/index.php")
async def handle_notif_action(request: Request, db: Session = Depends(get_db)):
    try:
        body = await request.json()
    except Exception:
        body = {}
        
    action = body.get("action")
    nid = body.get("id") or body.get("notificationId")
    ids = body.get("ids", [])
    is_read_val = False if body.get("isRead") in [0, "0", False] else True

    # 1. Action Delete
    if action == "delete":
        del_ids = ids or ([nid] if nid else [])
        if del_ids:
            db.query(Notification).filter(Notification.id.in_(del_ids)).delete(synchronize_session=False)
            db.commit()
        return {"status": "success", "message": "Notifikasi berhasil dihapus."}

    # 2. Mark All Read
    if action == "mark_all_read" or body.get("markAll"):
        uid = body.get("user_id") or body.get("userId")
        q = db.query(Notification)
        if uid:
            q = q.filter(
                (Notification.user_id == uid) | 
                (Notification.user_id.is_(None)) | 
                (Notification.user_id == 'GLOBAL') | 
                (Notification.user_id == '')
            )
        q.update({"is_read": True}, synchronize_session=False)
        db.commit()
        return {"status": "success", "message": "Semua notifikasi ditandai telah dibaca."}

    # 3. Mark Multiple Read/Unread
    if ids and isinstance(ids, list):
        db.query(Notification).filter(Notification.id.in_(ids)).update({"is_read": is_read_val}, synchronize_session=False)
        db.commit()
        return {"status": "success", "message": "Daftar notifikasi diperbarui."}

    # 4. Mark Single Read/Unread
    if nid and (action == "mark_read" or "isRead" in body or request.method == "PUT"):
        n = db.query(Notification).filter(Notification.id == nid).first()
        if n:
            n.is_read = is_read_val
            db.commit()
        return {"status": "success", "message": "Status notifikasi diperbarui."}

    # 5. Create new notification
    title = body.get("title") or body.get("judul")
    message = body.get("message") or body.get("pesan")
    if title and message:
        new_n = Notification(
            id=body.get("id") or f"NOT_{secrets.token_hex(4).upper()}",
            user_id=body.get("user_id") or body.get("userId"),
            title=title,
            message=message,
            type=body.get("type") or body.get("tipe") or "info",
            is_read=False
        )
        db.add(new_n)
        db.commit()
        return {"status": "success", "message": "Notifikasi berhasil dibuat.", "data": format_notif(new_n)}

    return {"status": "success"}

@router.delete("")
@router.delete("/")
@router.delete("/index.php")
async def delete_notification(request: Request, id: Optional[str] = Query(None), db: Session = Depends(get_db)):
    try:
        body = await request.json()
    except Exception:
        body = {}
    
    del_ids = body.get("ids") or ([id] if id else [])
    if del_ids:
        db.query(Notification).filter(Notification.id.in_(del_ids)).delete(synchronize_session=False)
        db.commit()
    return {"status": "success", "message": "Notifikasi berhasil dihapus."}
