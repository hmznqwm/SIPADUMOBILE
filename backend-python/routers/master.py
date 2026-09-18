from fastapi import APIRouter, Depends, HTTPException, Query, Request
from sqlalchemy.orm import Session
from typing import Optional, List, Dict, Any
from core.database import get_db
from models.models import Gedung, Ruangan, MataKuliah, MataKuliahKelas, SlotWaktu, User, AjuanPengajaran, JadwalFinal
import bcrypt
import requests
import secrets

from core.config import SUPABASE_URL, SUPABASE_KEY, SB_HEADERS
from core.security import sanitize_supabase_param
import logging

logger = logging.getLogger("smartschedule.master")

def sync_user_to_supabase(user_data: dict):
    try:
        url = f"{SUPABASE_URL}/rest/v1/users"
        requests.post(url, headers=SB_HEADERS, json=user_data, timeout=5)
    except Exception as e:
        logger.warning(f"Failed to sync user to Supabase: {e}")

def delete_user_from_supabase(user_id: str):
    try:
        safe_id = sanitize_supabase_param(user_id)
        url = f"{SUPABASE_URL}/rest/v1/users?id=eq.{safe_id}"
        requests.delete(url, headers={"apikey": SUPABASE_KEY, "Authorization": f"Bearer {SUPABASE_KEY}"}, timeout=5)
    except Exception as e:
        logger.warning(f"Failed to delete user from Supabase: {e}")

def patch_user_priority_in_supabase(user_id: str, priority: bool):
    try:
        safe_id = sanitize_supabase_param(user_id)
        url = f"{SUPABASE_URL}/rest/v1/users?id=eq.{safe_id}"
        headers = {
            "apikey": SUPABASE_KEY,
            "Authorization": f"Bearer {SUPABASE_KEY}",
            "Content-Type": "application/json"
        }
        requests.patch(url, headers=headers, json={"is_priority": priority}, timeout=5)
    except Exception as e:
        logger.warning(f"Failed to patch user priority in Supabase: {e}")

def sync_gedung_to_supabase(gedung_data: dict):
    try:
        url = f"{SUPABASE_URL}/rest/v1/gedung"
        requests.post(url, headers=SB_HEADERS, json=gedung_data, timeout=5)
    except Exception as e:
        logger.warning(f"Failed to sync gedung to Supabase: {e}")

def delete_gedung_from_supabase(gedung_id: str):
    try:
        safe_id = sanitize_supabase_param(gedung_id)
        url = f"{SUPABASE_URL}/rest/v1/gedung?id=eq.{safe_id}"
        requests.delete(url, headers={"apikey": SUPABASE_KEY, "Authorization": f"Bearer {SUPABASE_KEY}"}, timeout=5)
    except Exception as e:
        logger.warning(f"Failed to delete gedung from Supabase: {e}")

def sync_ruangan_to_supabase(ruangan_data: dict):
    try:
        url = f"{SUPABASE_URL}/rest/v1/ruangan"
        requests.post(url, headers=SB_HEADERS, json=ruangan_data, timeout=5)
    except Exception as e:
        logger.warning(f"Failed to sync ruangan to Supabase: {e}")

def delete_ruangan_from_supabase(ruangan_id: str):
    try:
        safe_id = sanitize_supabase_param(ruangan_id)
        url = f"{SUPABASE_URL}/rest/v1/ruangan?id=eq.{safe_id}"
        requests.delete(url, headers={"apikey": SUPABASE_KEY, "Authorization": f"Bearer {SUPABASE_KEY}"}, timeout=5)
    except Exception as e:
        logger.warning(f"Failed to delete ruangan from Supabase: {e}")

def sync_matkul_to_supabase(matkul_data: dict):
    try:
        url = f"{SUPABASE_URL}/rest/v1/mata_kuliah"
        requests.post(url, headers=SB_HEADERS, json=matkul_data, timeout=5)
    except Exception as e:
        logger.warning(f"Failed to sync matkul to Supabase: {e}")

def delete_matkul_from_supabase(matkul_id: str):
    try:
        safe_id = sanitize_supabase_param(matkul_id)
        url = f"{SUPABASE_URL}/rest/v1/mata_kuliah?id=eq.{safe_id}"
        requests.delete(url, headers={"apikey": SUPABASE_KEY, "Authorization": f"Bearer {SUPABASE_KEY}"}, timeout=5)
    except Exception as e:
        logger.warning(f"Failed to delete matkul from Supabase: {e}")

router = APIRouter(prefix="/master", tags=["Master Data"])

def hash_pw(password: str) -> str:
    return bcrypt.hashpw(password.encode("utf-8"), bcrypt.gensalt()).decode("utf-8")

# ─── GEDUNG ─────────────────────────────────────────────────────────────
@router.get("/gedung")
@router.get("/gedung.php")
def get_gedung(db: Session = Depends(get_db)):
    items = db.query(Gedung).all()
    data = [
        {
            "id": g.id,
            "nama": g.nama,
            "jamBuka": g.jam_buka,
            "jam_buka": g.jam_buka,
            "jamTutup": g.jam_tutup,
            "jam_tutup": g.jam_tutup,
            "aksesJurusan": g.akses_jurusan,
            "akses_jurusan": g.akses_jurusan
        }
        for g in items
    ]
    return {"status": "success", "data": data}

@router.post("/gedung")
@router.post("/gedung.php")
async def create_or_update_gedung(request: Request, db: Session = Depends(get_db)):
    body = await request.json()
    action = str(body.get("action", "")).lower()
    gid = body.get("id")

    if action == "delete" and gid:
        gedung = db.query(Gedung).filter(Gedung.id == gid).first()
        if gedung:
            g_nama = gedung.nama
            rooms = db.query(Ruangan).filter(Ruangan.gedung_id == gedung.id).all()
            room_names = [r.nama for r in rooms]
            # Cascade delete matching Jadwal and Ajuan
            db.query(JadwalFinal).filter(
                (JadwalFinal.gedung_nama == g_nama) | 
                (JadwalFinal.ruangan_nama.in_(room_names))
            ).delete(synchronize_session=False)
            db.query(AjuanPengajaran).filter(
                (AjuanPengajaran.gedung_nama == g_nama) | 
                (AjuanPengajaran.ruangan_nama.in_(room_names))
            ).delete(synchronize_session=False)
            db.delete(gedung)
            db.commit()
            delete_gedung_from_supabase(gid)
        return {"status": "success", "message": "Gedung dan jadwal/ruangan terkait berhasil dihapus"}

    if not gid or not body.get("nama"):
        raise HTTPException(status_code=400, detail={"status": "error", "message": "ID dan Nama gedung wajib diisi."})

    gedung = db.query(Gedung).filter(Gedung.id == gid).first()
    if gedung:
        gedung.nama = body.get("nama", gedung.nama)
        gedung.jam_buka = body.get("jam_buka") or body.get("jamBuka", gedung.jam_buka)
        gedung.jam_tutup = body.get("jam_tutup") or body.get("jamTutup", gedung.jam_tutup)
        gedung.akses_jurusan = body.get("akses_jurusan") or body.get("aksesJurusan", gedung.akses_jurusan)
    else:
        gedung = Gedung(
            id=gid,
            nama=body["nama"],
            jam_buka=body.get("jam_buka") or body.get("jamBuka", "07:00"),
            jam_tutup=body.get("jam_tutup") or body.get("jamTutup", "18:30"),
            akses_jurusan=body.get("akses_jurusan") or body.get("aksesJurusan", "Teknik Informatika")
        )
        db.add(gedung)
    db.commit()
    sync_gedung_to_supabase({
        "id": gedung.id,
        "nama": gedung.nama,
        "jam_buka": gedung.jam_buka,
        "jam_tutup": gedung.jam_tutup,
        "akses_jurusan": gedung.akses_jurusan
    })
    return {"status": "success", "message": "Data gedung berhasil disimpan"}

@router.delete("/gedung")
@router.delete("/gedung.php")
def delete_gedung(id: str = Query(...), db: Session = Depends(get_db)):
    gedung = db.query(Gedung).filter(Gedung.id == id).first()
    if gedung:
        g_nama = gedung.nama
        rooms = db.query(Ruangan).filter(Ruangan.gedung_id == gedung.id).all()
        room_names = [r.nama for r in rooms]
        db.query(JadwalFinal).filter(
            (JadwalFinal.gedung_nama == g_nama) | 
            (JadwalFinal.ruangan_nama.in_(room_names))
        ).delete(synchronize_session=False)
        db.query(AjuanPengajaran).filter(
            (AjuanPengajaran.gedung_nama == g_nama) | 
            (AjuanPengajaran.ruangan_nama.in_(room_names))
        ).delete(synchronize_session=False)
        db.delete(gedung)
        db.commit()
        delete_gedung_from_supabase(id)
    return {"status": "success", "message": "Gedung dan jadwal/ruangan terkait berhasil dihapus"}

# ─── RUANGAN ────────────────────────────────────────────────────────────
@router.get("/ruangan")
@router.get("/ruangan.php")
def get_ruangan(gedung_id: Optional[str] = None, gedungId: Optional[str] = None, db: Session = Depends(get_db)):
    gid = gedung_id or gedungId
    q = db.query(Ruangan)
    if gid and gid != "Semua":
        q = q.filter(Ruangan.gedung_id == gid)
    items = q.all()
    data = [
        {
            "id": r.id,
            "nama": r.nama,
            "gedungId": r.gedung_id,
            "gedung_id": r.gedung_id,
            "gedungNama": r.gedung.nama if r.gedung else "",
            "gedung_nama": r.gedung.nama if r.gedung else "",
            "lantai": r.lantai,
            "kapasitas": r.kapasitas,
            "tipeRuangan": r.tipe_ruangan,
            "tipe_ruangan": r.tipe_ruangan,
            "status": r.status,
            "keterangan": r.keterangan
        }
        for r in items
    ]
    return {"status": "success", "data": data}

@router.post("/ruangan")
@router.post("/ruangan.php")
async def create_or_update_ruangan(request: Request, db: Session = Depends(get_db)):
    body = await request.json()
    action = str(body.get("action", "")).lower()
    rid = body.get("id")

    if action == "delete" and rid:
        ruangan = db.query(Ruangan).filter(Ruangan.id == rid).first()
        if ruangan:
            r_nama = ruangan.nama
            db.query(JadwalFinal).filter(JadwalFinal.ruangan_nama == r_nama).delete(synchronize_session=False)
            db.query(AjuanPengajaran).filter(AjuanPengajaran.ruangan_nama == r_nama).delete(synchronize_session=False)
            db.delete(ruangan)
            db.commit()
            delete_ruangan_from_supabase(rid)
        return {"status": "success", "message": "Ruangan dan jadwal terkait berhasil dihapus"}

    gid_raw = body.get("gedung_id") or body.get("gedungId") or body.get("gedung_nama") or body.get("gedungNama")
    if not rid or not body.get("nama") or not gid_raw:
        raise HTTPException(status_code=400, detail={"status": "error", "message": "ID, Nama, dan Gedung ID wajib diisi."})

    # Resolve gedung_id by ID or Name
    g_obj = db.query(Gedung).filter((Gedung.id == gid_raw) | (Gedung.nama == gid_raw)).first()
    gid = g_obj.id if g_obj else gid_raw

    ruangan = db.query(Ruangan).filter(Ruangan.id == rid).first()
    if ruangan:
        ruangan.nama = body.get("nama", ruangan.nama)
        ruangan.gedung_id = gid
        ruangan.lantai = body.get("lantai", ruangan.lantai)
        ruangan.kapasitas = int(body.get("kapasitas", ruangan.kapasitas))
        ruangan.tipe_ruangan = body.get("tipe_ruangan") or body.get("tipeRuangan", ruangan.tipe_ruangan)
        ruangan.status = body.get("status", ruangan.status)
        ruangan.keterangan = body.get("keterangan", ruangan.keterangan)
    else:
        ruangan = Ruangan(
            id=rid,
            nama=body["nama"],
            gedung_id=gid,
            lantai=body.get("lantai", "Lantai 1"),
            kapasitas=int(body.get("kapasitas", 40)),
            tipe_ruangan=body.get("tipe_ruangan") or body.get("tipeRuangan", "Kelas Teori"),
            status=body.get("status", "Kosong (Ready)"),
            keterangan=body.get("keterangan", "")
        )
        db.add(ruangan)
    db.commit()
    sync_ruangan_to_supabase({
        "id": ruangan.id,
        "nama": ruangan.nama,
        "gedung_id": ruangan.gedung_id,
        "lantai": ruangan.lantai,
        "kapasitas": ruangan.kapasitas,
        "tipe_ruangan": ruangan.tipe_ruangan,
        "status": ruangan.status,
        "keterangan": ruangan.keterangan
    })
    return {"status": "success", "message": "Data ruangan berhasil disimpan"}

@router.delete("/ruangan")
@router.delete("/ruangan.php")
def delete_ruangan(id: str = Query(...), db: Session = Depends(get_db)):
    ruangan = db.query(Ruangan).filter(Ruangan.id == id).first()
    if ruangan:
        r_nama = ruangan.nama
        db.query(JadwalFinal).filter(JadwalFinal.ruangan_nama == r_nama).delete(synchronize_session=False)
        db.query(AjuanPengajaran).filter(AjuanPengajaran.ruangan_nama == r_nama).delete(synchronize_session=False)
        db.delete(ruangan)
        db.commit()
        delete_ruangan_from_supabase(id)
    return {"status": "success", "message": "Ruangan dan jadwal terkait berhasil dihapus"}

# ─── MATA KULIAH ────────────────────────────────────────────────────────
@router.get("/mata_kuliah")
@router.get("/mata_kuliah.php")
def get_mata_kuliah(dosen_id: Optional[str] = None, dosenId: Optional[str] = None, jurusan_id: Optional[str] = None, db: Session = Depends(get_db)):
    q = db.query(MataKuliah)
    did = dosen_id or dosenId
    if did:
        q = q.filter(MataKuliah.dosen_id == did)
    if jurusan_id:
        q = q.filter(MataKuliah.jurusan_id == jurusan_id)
    items = q.all()
    
    if not items and did:
        # 1. Check user's assigned matkul_nama in User master record
        user = db.query(User).filter((User.id == did) | (User.email == did)).first()
        if not user or not user.matkul_nama:
            try:
                r_sb = requests.get(
                    f"{SUPABASE_URL}/rest/v1/users?or=(id.eq.{did},email.ilike.{did})&select=*",
                    headers=SB_HEADERS,
                    timeout=5
                )
                if r_sb.status_code == 200 and r_sb.json():
                    sb_u = r_sb.json()[0]
                    if not user:
                        user = User(
                            id=sb_u["id"],
                            nama=sb_u["nama"],
                            email=sb_u["email"],
                            password=sb_u.get("password") or "password123",
                            role=sb_u.get("role") or "dosen",
                            jurusan_id=sb_u.get("jurusan_id"),
                            jurusan_nama=sb_u.get("jurusan_nama"),
                            fakultas_nama=sb_u.get("fakultas_nama"),
                            matkul_nama=sb_u.get("matkul_nama")
                        )
                        db.add(user)
                    else:
                        user.matkul_nama = sb_u.get("matkul_nama")
                    db.commit()
            except Exception:
                pass

        if user and user.matkul_nama:
            for part in user.matkul_nama.split(","):
                clean = part.strip()
                if "-" in clean:
                    clean = clean.split("-")[-1].strip()
                if clean:
                    mks = db.query(MataKuliah).filter(MataKuliah.nama.ilike(f"%{clean}%")).all()
                    if mks:
                        for mk in mks:
                            mk.dosen_id = user.id
                            mk.dosen_nama = user.nama
                            items.append(mk)
                        db.commit()
                    else:
                        code_part = part.split("-")[0].strip() if "-" in part else f"MK_{user.id}"
                        new_mk = MataKuliah(
                            id=f"MK_{secrets.token_hex(4).upper()}",
                            kode=code_part,
                            nama=clean,
                            sks=3,
                            jurusan_id=user.jurusan_id or "JUR001",
                            jurusan_nama=user.jurusan_nama or "Teknik Informatika",
                            fakultas_nama=user.fakultas_nama or "Fakultas Sains & Teknologi",
                            dosen_id=user.id,
                            dosen_nama=user.nama,
                            semester_angka=1,
                            kebutuhan_tipe_ruangan="Kelas Teori"
                        )
                        db.add(new_mk)
                        db.commit()
                        items.append(new_mk)

        # 2. Check active ajuan pengajaran for this lecturer
        if not items:
            ajuan_items = db.query(AjuanPengajaran).filter(AjuanPengajaran.dosen_id == did).all()
            seen = set()
            data = []
            for a in ajuan_items:
                if a.mata_kuliah_id in seen:
                    continue
                seen.add(a.mata_kuliah_id)
                kelas_list = [a.kelas_nama] if a.kelas_nama else ["TI-1A"]
                kelas_ids = [f"{a.mata_kuliah_id}_KLS_{i+1}" for i in range(len(kelas_list))]
                data.append({
                    "id": a.mata_kuliah_id,
                    "nama": a.mata_kuliah_nama,
                    "sks": a.sks,
                    "jurusanId": "JUR001",
                    "jurusan_id": "JUR001",
                    "jurusanNama": a.jurusan_nama,
                    "jurusan_nama": a.jurusan_nama,
                    "fakultasNama": a.fakultas_nama,
                    "fakultas_nama": a.fakultas_nama,
                    "dosenId": a.dosen_id,
                    "dosen_id": a.dosen_id,
                    "dosenNama": a.dosen_nama,
                    "dosen_nama": a.dosen_nama,
                    "semesterId": "SEM001",
                    "semester_id": "SEM001",
                    "semesterAngka": a.semester,
                    "semester_angka": a.semester,
                    "kebutuhanTipeRuangan": "Kelas Teori",
                    "kebutuhan_tipe_ruangan": "Kelas Teori",
                    "kelasIds": kelas_ids,
                    "kelas_ids": kelas_ids,
                    "kelasNama": kelas_list,
                    "kelas_nama": kelas_list,
                    "kelas": kelas_list
                })
            if data:
                return {"status": "success", "data": data}

    data = []
    for mk in items:
        kelasList = [k.kelas_nama for k in mk.kelas_list] if mk.kelas_list else []
        if not kelasList:
            sem = mk.semester_angka or 1
            jur = (mk.jurusan_nama or "").lower()
            if "informatika" in jur:
                prefix = f"TI-{sem}"
            elif "sistem informasi" in jur:
                prefix = f"SI-{sem}"
            else:
                prefix = f"KLS-{sem}"
            kelasList = [f"{prefix}A", f"{prefix}B"]

        kelas_ids = [f"{mk.id}_KLS_{i+1}" for i in range(len(kelasList))]
        dosen_nama = (mk.dosen.nama if mk.dosen else None) or mk.dosen_nama or ""
        data.append({
            "id": mk.id,
            "nama": mk.nama,
            "sks": mk.sks,
            "jurusanId": mk.jurusan_id,
            "jurusan_id": mk.jurusan_id,
            "jurusanNama": mk.jurusan_nama,
            "jurusan_nama": mk.jurusan_nama,
            "fakultasNama": mk.fakultas_nama,
            "fakultas_nama": mk.fakultas_nama,
            "dosenId": mk.dosen_id,
            "dosen_id": mk.dosen_id,
            "dosenNama": dosen_nama,
            "dosen_nama": dosen_nama,
            "semesterId": mk.semester_id,
            "semester_id": mk.semester_id,
            "semesterAngka": mk.semester_angka,
            "semester_angka": mk.semester_angka,
            "kebutuhanTipeRuangan": mk.kebutuhan_tipe_ruangan or "Kelas Teori",
            "kebutuhan_tipe_ruangan": mk.kebutuhan_tipe_ruangan or "Kelas Teori",
            "kelasIds": kelas_ids,
            "kelas_ids": kelas_ids,
            "kelasNama": kelasList,
            "kelas_nama": kelasList,
            "kelas": kelasList
        })
    return {"status": "success", "data": data}

@router.post("/mata_kuliah")
@router.post("/mata_kuliah.php")
async def create_or_update_mata_kuliah(request: Request, db: Session = Depends(get_db)):
    body = await request.json()
    action = str(body.get("action", "")).lower()
    mk_id = body.get("id")

    if action == "delete" and mk_id:
        mk = db.query(MataKuliah).filter(MataKuliah.id == mk_id).first()
        if mk:
            mk_id_val = mk.id
            mk_nama_val = mk.nama
            db.query(JadwalFinal).filter(
                (JadwalFinal.mata_kuliah_id == mk_id_val) | 
                (JadwalFinal.mata_kuliah_nama == mk_nama_val)
            ).delete(synchronize_session=False)
            db.query(AjuanPengajaran).filter(
                (AjuanPengajaran.mata_kuliah_id == mk_id_val) | 
                (AjuanPengajaran.mata_kuliah_nama == mk_nama_val)
            ).delete(synchronize_session=False)
            db.delete(mk)
            db.commit()
            delete_matkul_from_supabase(mk_id)
        return {"status": "success", "message": "Mata kuliah dan jadwal terkait berhasil dihapus"}

    did_raw = body.get("dosen_id") or body.get("dosenId") or body.get("dosen_nama") or body.get("dosenNama")
    if not mk_id or not body.get("nama") or not did_raw:
        raise HTTPException(status_code=400, detail={"status": "error", "message": "ID, Nama, dan Dosen Pengampu wajib diisi."})

    # Resolve dosen_id by ID or Name
    u_obj = db.query(User).filter((User.id == did_raw) | (User.nama == did_raw)).first()
    did = u_obj.id if u_obj else did_raw

    mk = db.query(MataKuliah).filter(MataKuliah.id == mk_id).first()
    if not mk:
        mk = MataKuliah(id=mk_id)
        db.add(mk)
    
    mk.nama = body.get("nama", mk.nama)
    mk.sks = int(body.get("sks", mk.sks or 3))
    mk.jurusan_id = body.get("jurusan_id") or body.get("jurusanId", mk.jurusan_id or "JUR001")
    mk.jurusan_nama = body.get("jurusan_nama") or body.get("jurusanNama", mk.jurusan_nama or "Teknik Informatika")
    mk.fakultas_nama = body.get("fakultas_nama") or body.get("fakultasNama", mk.fakultas_nama or "Fakultas Sains & Teknologi")
    mk.dosen_id = did
    mk.dosen_nama = u_obj.nama if u_obj else (body.get("dosen_nama") or body.get("dosenNama") or body.get("dosen") or getattr(mk, 'dosen_nama', None) or "")
    mk.semester_angka = int(body.get("semester_angka") or body.get("semesterAngka", mk.semester_angka or 1))
    mk.kebutuhan_tipe_ruangan = body.get("kebutuhan_tipe_ruangan") or body.get("kebutuhanTipeRuangan", mk.kebutuhan_tipe_ruangan)

    # Sync kelas
    kelas_input = body.get("kelas") or body.get("kelasNama") or body.get("kelas_nama") or []
    if isinstance(kelas_input, list) and kelas_input:
        db.query(MataKuliahKelas).filter(MataKuliahKelas.mata_kuliah_id == mk_id).delete()
        for k in kelas_input:
            db.add(MataKuliahKelas(mata_kuliah_id=mk_id, kelas_nama=str(k)))

    db.commit()
    sync_matkul_to_supabase({
        "id": mk.id,
        "nama": mk.nama,
        "sks": mk.sks,
        "jurusan_id": mk.jurusan_id,
        "jurusan_nama": mk.jurusan_nama,
        "fakultas_nama": mk.fakultas_nama,
        "dosen_id": mk.dosen_id,
        "dosen_nama": mk.dosen_nama,
    })
    return {"status": "success", "message": "Mata kuliah berhasil disimpan"}

@router.delete("/mata_kuliah")
@router.delete("/mata_kuliah.php")
def delete_mata_kuliah(id: str = Query(...), db: Session = Depends(get_db)):
    mk = db.query(MataKuliah).filter(MataKuliah.id == id).first()
    if mk:
        mk_id_val = mk.id
        mk_nama_val = mk.nama
        db.query(JadwalFinal).filter(
            (JadwalFinal.mata_kuliah_id == mk_id_val) | 
            (JadwalFinal.mata_kuliah_nama == mk_nama_val)
        ).delete(synchronize_session=False)
        db.query(AjuanPengajaran).filter(
            (AjuanPengajaran.mata_kuliah_id == mk_id_val) | 
            (AjuanPengajaran.mata_kuliah_nama == mk_nama_val)
        ).delete(synchronize_session=False)
        db.delete(mk)
        db.commit()
        delete_matkul_from_supabase(id)
    return {"status": "success", "message": "Mata kuliah dan jadwal terkait berhasil dihapus"}

# ─── USERS / DOSEN ──────────────────────────────────────────────────────
@router.get("/users")
@router.get("/users.php")
def get_users(role: Optional[str] = None, db: Session = Depends(get_db)):
    q = db.query(User)
    if role and role != "Semua":
        q = q.filter(User.role == role)
    items = q.all()
    data = [
        {
            "id": u.id,
            "nama": u.nama,
            "email": u.email,
            "role": u.role,
            "jurusanId": u.jurusan_id,
            "jurusan_id": u.jurusan_id,
            "jurusanNama": u.jurusan_nama,
            "jurusan_nama": u.jurusan_nama,
            "fakultasNama": u.fakultas_nama,
            "fakultas_nama": u.fakultas_nama,
            "isPriority": bool(u.is_priority),
            "is_priority": bool(u.is_priority),
            "avatarUrl": u.avatar_url,
            "avatar_url": u.avatar_url,
            "matkulNama": u.matkul_nama,
            "matkul_nama": u.matkul_nama
        }
        for u in items
    ]
    return {"status": "success", "data": data}

@router.post("/users")
@router.post("/users.php")
async def create_or_update_user(request: Request, db: Session = Depends(get_db)):
    body = await request.json()
    action = str(body.get("action", "")).lower()

    # 1. Action set priority
    dId = body.get("dosenId") or body.get("dosen_id")
    if "isPriority" in body or "is_priority" in body:
        if dId:
            p = bool(body.get("isPriority") if "isPriority" in body else body.get("is_priority"))
            db.query(User).filter(User.id == dId).update({"is_priority": p})
            db.commit()
            patch_user_priority_in_supabase(dId, p)
            return {"status": "success", "message": "Prioritas dosen berhasil diperbarui"}

    # 2. Action delete
    uid = body.get("id") or body.get("nidn")
    if action == "delete" and uid:
        user = db.query(User).filter(User.id == uid).first()
        if user:
            u_id_val = user.id
            u_nama_val = user.nama
            db.query(JadwalFinal).filter(
                (JadwalFinal.dosen_id == u_id_val) | 
                (JadwalFinal.dosen_nama == u_nama_val)
            ).delete(synchronize_session=False)
            db.query(AjuanPengajaran).filter(
                (AjuanPengajaran.dosen_id == u_id_val) | 
                (AjuanPengajaran.dosen_nama == u_nama_val)
            ).delete(synchronize_session=False)
            db.query(MataKuliah).filter(MataKuliah.dosen_id == u_id_val).delete(synchronize_session=False)
            db.delete(user)
            db.commit()
            delete_user_from_supabase(u_id_val)
        return {"status": "success", "message": "Pengguna dan jadwal/matkul terkait berhasil dihapus"}

    nama = body.get("nama")
    email = body.get("email")

    # Auto generate ID for dosen if omitted
    if not uid:
        count = db.query(User).filter(User.role == "dosen").count()
        uid = f"DSN{count + 1:03d}"

    if not nama or not email:
        raise HTTPException(status_code=400, detail={"status": "error", "message": "Nama dan Email wajib diisi."})

    user = db.query(User).filter((User.id == uid) | (User.email == email)).first()
    if not user:
        raw_pass = body.get("password") or uid
        user = User(
            id=uid,
            password=hash_pw(raw_pass)
        )
        db.add(user)

    user.nama = nama
    user.email = email
    user.role = body.get("role", user.role or "dosen")
    user.jurusan_id = body.get("jurusan_id") or body.get("jurusanId", user.jurusan_id or "JUR001")
    user.jurusan_nama = body.get("jurusan_nama") or body.get("jurusanNama", user.jurusan_nama or "Teknik Informatika")
    user.fakultas_nama = body.get("fakultas_nama") or body.get("fakultasNama", user.fakultas_nama or "Fakultas Sains & Teknologi")
    user.matkul_nama = body.get("matkul_nama") or body.get("matkulNama", user.matkul_nama)
    user.is_priority = bool(body.get("is_priority") if "is_priority" in body else body.get("isPriority", user.is_priority))
    if body.get("password"):
        user.password = hash_pw(body["password"])

    db.commit()

    # Automatically bind assigned matkul_nama to MataKuliah table and Supabase
    if user.matkul_nama:
        for part in user.matkul_nama.split(","):
            clean = part.strip()
            if "-" in clean:
                clean = clean.split("-")[-1].strip()
            if clean:
                db.query(MataKuliah).filter(
                    (MataKuliah.nama.ilike(f"%{clean}%")) |
                    (MataKuliah.kode.ilike(f"%{clean}%"))
                ).update({"dosen_id": user.id, "dosen_nama": user.nama}, synchronize_session=False)
                db.commit()
                try:
                    url_mk = f"{SUPABASE_URL}/rest/v1/mata_kuliah?nama=ilike.%25{clean}%25"
                    requests.patch(url_mk, headers=SB_HEADERS, json={"dosen_id": user.id, "dosen_nama": user.nama}, timeout=5)
                except Exception:
                    pass

    # Sync to Supabase Cloud
    sync_user_to_supabase({
        "id": user.id,
        "nama": user.nama,
        "email": user.email,
        "password": user.password,
        "role": user.role,
        "jurusan_id": user.jurusan_id,
        "jurusan_nama": user.jurusan_nama,
        "fakultas_nama": user.fakultas_nama,
        "matkul_nama": user.matkul_nama,
        "is_priority": bool(user.is_priority),
    })
    return {
        "status": "success",
        "message": "Pengguna berhasil disimpan",
        "data": {
            "id": user.id,
            "nama": user.nama,
            "email": user.email,
            "role": user.role,
            "jurusan_id": user.jurusan_id,
            "jurusan_nama": user.jurusan_nama,
            "fakultas_nama": user.fakultas_nama,
            "matkul_nama": user.matkul_nama,
            "is_priority": bool(user.is_priority),
            "avatar_url": user.avatar_url
        }
    }

@router.delete("/users")
@router.delete("/users.php")
def delete_user(id: str = Query(...), db: Session = Depends(get_db)):
    user = db.query(User).filter(User.id == id).first()
    if user:
        u_id_val = user.id
        u_nama_val = user.nama
        db.query(JadwalFinal).filter(
            (JadwalFinal.dosen_id == u_id_val) | 
            (JadwalFinal.dosen_nama == u_nama_val)
        ).delete(synchronize_session=False)
        db.query(AjuanPengajaran).filter(
            (AjuanPengajaran.dosen_id == u_id_val) | 
            (AjuanPengajaran.dosen_nama == u_nama_val)
        ).delete(synchronize_session=False)
        db.query(MataKuliah).filter(MataKuliah.dosen_id == u_id_val).delete(synchronize_session=False)
        db.delete(user)
        db.commit()
        delete_user_from_supabase(u_id_val)
    return {"status": "success", "message": "Pengguna dan jadwal/matkul terkait berhasil dihapus"}

# ─── SLOT WAKTU ────────────────────────────────────────────────────────
@router.get("/slot_waktu")
@router.get("/slot_waktu.php")
def get_slot_waktu(db: Session = Depends(get_db)):
    items = db.query(SlotWaktu).all()
    data = [
        {
            "id": s.id,
            "hari": s.hari,
            "jamMulai": s.jam_mulai,
            "jam_mulai": s.jam_mulai,
            "jamSelesai": s.jam_selesai,
            "jam_selesai": s.jam_selesai,
            "durasiMenit": s.durasi_menit,
            "durasi_menit": s.durasi_menit
        }
        for s in items
    ]
    return {"status": "success", "data": data}
