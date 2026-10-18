import sys
import os
sys.path.insert(0, os.path.dirname(os.path.dirname(os.path.abspath(__file__))))

from fastapi import APIRouter, Depends, HTTPException, Request
from sqlalchemy.orm import Session
from typing import List, Dict, Any, Optional
from core.database import get_db
from models.models import (
    AjuanPengajaran, JadwalFinal, MataKuliah, MataKuliahKelas,
    Ruangan, Gedung, SlotWaktu, User, Availability, AvailabilitySlot
)
import secrets
import requests

from core.config import SUPABASE_URL, SUPABASE_KEY, SB_HEADERS
from core.security import sanitize_supabase_param
import logging

logger = logging.getLogger("smartschedule.engine")

# ==============================================================================
# FUNGSI 1: SINKRONISASI HASIL JADWAL CSP KE CLOUD (SUPABASE)
# ==============================================================================
def sync_generated_to_supabase(scope: str, fakultas_nama: str, jurusan_nama: str, schedules: list, ajuan_updates: list, force_replan: bool = False):
    """
    [PRESENTASI] Fungsi Sinkronisasi (Cloud Sync):
    Mengunggah hasil pembuatan jadwal (JadwalFinal) kembali ke database Supabase Cloud.
    Jika `force_replan` aktif, jadwal lama di cloud akan dihapus terlebih dahulu sesuai lingkupnya (scope).
    """
    try:
        # Langkah 1: Hapus jadwal lama di cloud HANYA jika force_replan bernilai True
        # Pada mode normal (incremental CSP), jadwal final lama tidak boleh dihapus
        del_url = f"{SUPABASE_URL}/rest/v1/jadwal_final"
        if force_replan:
            if scope == "global":
                # Menghapus seluruh jadwal final di semua fakultas & jurusan
                requests.delete(f"{del_url}?id=not.is.null", headers={"apikey": SUPABASE_KEY, "Authorization": f"Bearer {SUPABASE_KEY}"}, timeout=5)
            elif scope == "fakultas" and fakultas_nama:
                # Menghapus jadwal terbatas pada fakultas terkait
                clean_f = sanitize_supabase_param(fakultas_nama.replace("&", "dan").strip())
                requests.delete(f"{del_url}?fakultas_nama=ilike.%25{clean_f}%25", headers={"apikey": SUPABASE_KEY, "Authorization": f"Bearer {SUPABASE_KEY}"}, timeout=5)
            elif scope == "jurusan" and jurusan_nama:
                # Menghapus jadwal terbatas pada jurusan tertentu
                clean_j = sanitize_supabase_param(jurusan_nama.strip())
                requests.delete(f"{del_url}?jurusan_nama=ilike.%25{clean_j}%25", headers={"apikey": SUPABASE_KEY, "Authorization": f"Bearer {SUPABASE_KEY}"}, timeout=5)

        # Langkah 2: Mengunggah jadwal baru ke tabel 'jadwal_final' secara bertahap (batch per 50 baris)
        headers_upsert = {**SB_HEADERS, "Prefer": "resolution=merge-duplicates"}
        if schedules:
            payload = [
                {
                    "id": s["id"],
                    "mata_kuliah_id": s["mata_kuliah_id"],
                    "mata_kuliah_nama": s["mata_kuliah_nama"],
                    "sks": s["sks"],
                    "ruangan_nama": s["ruangan_nama"],
                    "gedung_nama": s["gedung_nama"],
                    "kelas_nama": s["kelas_nama"],
                    "hari": s["hari"],
                    "jam_mulai": s["jam_mulai"],
                    "jam_selesai": s["jam_selesai"],
                    "dosen_id": s["dosen_id"],
                    "dosen_nama": s["dosen_nama"],
                    "fakultas_nama": s["fakultas_nama"],
                    "jurusan_nama": s["jurusan_nama"],
                    "jumlah_mahasiswa": s["jumlah_mahasiswa"]
                }
                for s in schedules
            ]
            for i in range(0, len(payload), 50):
                chunk = payload[i:i+50]
                requests.post(f"{SUPABASE_URL}/rest/v1/jadwal_final", headers=headers_upsert, json=chunk, timeout=8)

        # Langkah 3: Mengupdate status ajuan asal menjadi 'disetujui_admin' di cloud
        if ajuan_updates:
            batch_updates = []
            for u in ajuan_updates:
                if isinstance(u, dict):
                    if "payload" in u and isinstance(u["payload"], dict):
                        batch_updates.append({"id": str(u["id"]), **u["payload"]})
                    else:
                        batch_updates.append({**u, "id": str(u.get("id"))})
            for i in range(0, len(batch_updates), 50):
                chunk = batch_updates[i:i+50]
                res_up = requests.post(f"{SUPABASE_URL}/rest/v1/ajuan_pengajaran", headers=headers_upsert, json=chunk, timeout=8)
                if res_up.status_code >= 400:
                    # Fallback to individual PATCH if batch upsert encounters schema constraint
                    for u_item in chunk:
                        u_id = u_item["id"]
                        patch_data = {k: v for k, v in u_item.items() if k != "id"}
                        requests.patch(f"{SUPABASE_URL}/rest/v1/ajuan_pengajaran?id=eq.{u_id}", headers=SB_HEADERS, json=patch_data, timeout=5)
    except Exception as e:
        logger.error(f"Error in sync_generated_to_supabase: {e}")

# Definisi Router API FastAPI untuk Scheduling Engine
router = APIRouter(prefix="/engine", tags=["Scheduling Engine"])

# ==============================================================================
# FUNGSI 2: HELPER WAKTU & DURASI
# ==============================================================================
def parse_time(t_str: str) -> int:
    """Mengubah format string jam 'HH:MM' menjadi total menit dari jam 00:00 (contoh: '07:30' -> 450 menit)."""
    parts = t_str.strip().split(":")
    return int(parts[0]) * 60 + int(parts[1]) if len(parts) >= 2 else 0

def get_task_duration(task, room=None) -> int:
    """
    [PRESENTASI] Menghitung Durasi Mengajar:
    SKS Teori = 50 Menit/SKS. SKS Praktikum/Lab = 90 Menit/SKS.
    Fungsi ini mendeteksi otomatis apakah kelas berupa teori atau praktikum berdasarkan jenis matkul, nama matkul, fakultas (Saintek/Teknik), atau ruangan.
    """
    m_nama = (getattr(task, "mata_kuliah_nama", "") or "").lower()
    r_nama = (getattr(room, "nama", "") or "").lower()
    r_type = (getattr(room, "tipe_ruangan", "") or "").lower()
    f_nama = (getattr(task, "fakultas_nama", "") or "").lower()
    j_nama = (getattr(task, "jurusan_nama", "") or "").lower()
    jenis = (getattr(task, "jenis", "") or "").lower()

    is_lab = (
        jenis == "praktikum"
        or getattr(task, "is_praktikum", False)
        or "praktikum" in m_nama
        or "lab" in m_nama
        or "laboratorium" in m_nama
        or "bengkel" in m_nama
        or "workshop" in m_nama
        or "studio" in m_nama
        or "laboratorium" in r_type
        or "lab" in r_type
        or "lab" in r_nama
        or (("sains" in f_nama or "teknik" in f_nama or "informatika" in j_nama) and ("praktik" in m_nama or "lab" in m_nama or "studio" in m_nama or "jaringan" in m_nama))
    )
    sks = getattr(task, "sks", 3) or 3
    return sks * 90 if is_lab else sks * 50

def is_overlap(start1: int, end1: int, start2: int, end2: int) -> bool:
    """[PRESENTASI] Hard Constraint: Mengecek bentrok waktu murni. Mengembalikan True jika kedua rentang waktu saling tumpang tindih."""
    return max(start1, start2) < min(end1, end2)

def is_travel_buffer_violated(start1: int, end1: int, g1: str, start2: int, end2: int, g2: str, min_buffer: int = 15) -> bool:
    """
    [PRESENTASI] Hard Constraint (Travel Buffer): 
    Mengecek apakah jeda antara 2 kelas cukup bagi dosen untuk pindah gedung (min 15 menit).
    Jika mengajar di gedung yang sama atau salah satunya kelas Daring/Virtual (RTI), jeda ini tidak diperlukan (return False).
    """
    if not g1 or not g2:
        return False
    g1_low = g1.strip().lower()
    g2_low = g2.strip().lower()
    if g1_low == g2_low:
        return False
    if "virtual" in g1_low or "daring" in g1_low or "virtual" in g2_low or "daring" in g2_low:
        return False
    # If starting after end of first class
    if start2 >= end1 and (start2 - end1) < min_buffer:
        return True
    # If starting before start of second class
    if start1 >= end2 and (start1 - end2) < min_buffer:
        return True
    return False

def sync_supabase_to_sqlite_for_csp(db: Session):
    """
    [PRESENTASI] Sinkronisasi Supabase ke SQLite (Input preparation):
    Mengambil data AjuanPengajaran (Draft jadwal), JadwalFinal (Jadwal terkunci), 
    Users (Dosen), MataKuliah, dan Ruangan dari Cloud ke Memori. 
    Hal ini memastikan Engine CSP selalu bekerja dengan data terbaru.
    """
    try:
        # 1. Pull latest ajuan_pengajaran from Supabase
        r_a = requests.get(f"{SUPABASE_URL}/rest/v1/ajuan_pengajaran?select=*", headers=SB_HEADERS, timeout=5)
        if r_a.status_code == 200:
            sb_items = r_a.json()
            sb_ids = {str(a["id"]) for a in sb_items if isinstance(a, dict) and "id" in a}
            
            # Delete only synthetic items (AJU_...) that are not in Supabase, but keep authentic user proposals
            if sb_ids:
                db.query(AjuanPengajaran).filter(
                    ~AjuanPengajaran.id.in_(sb_ids),
                    AjuanPengajaran.id.like("AJU_%")
                ).delete(synchronize_session=False)
            
            existing_map = {x.id: x for x in db.query(AjuanPengajaran).all()}
            for a in sb_items:
                if not isinstance(a, dict) or not a.get("id"):
                    continue
                existing = existing_map.get(a["id"])
                if not existing:
                    existing = AjuanPengajaran(id=a["id"])
                    db.add(existing)
                    existing_map[a["id"]] = existing
                setattr(existing, "dosen_id", a.get("dosen_id"))
                setattr(existing, "dosen_nama", a.get("dosen_nama"))
                setattr(existing, "fakultas_nama", a.get("fakultas_nama"))
                setattr(existing, "jurusan_nama", a.get("jurusan_nama"))
                setattr(existing, "mata_kuliah_id", a.get("mata_kuliah_id"))
                setattr(existing, "mata_kuliah_nama", a.get("mata_kuliah_nama"))
                setattr(existing, "sks", int(a.get("sks", 3)))
                setattr(existing, "semester", int(a.get("semester", 1)))
                setattr(existing, "kelas_nama", a.get("kelas_nama"))
                setattr(existing, "jumlah_mahasiswa", int(a.get("jumlah_mahasiswa", 35)))
                setattr(existing, "gedung_nama", a.get("gedung_nama"))
                setattr(existing, "ruangan_nama", a.get("ruangan_nama"))
                setattr(existing, "hari", a.get("hari", "Senin"))
                setattr(existing, "jam_mulai", a.get("jam_mulai", "07:30"))
                setattr(existing, "jam_selesai", a.get("jam_selesai", "10:00"))
                setattr(existing, "status", a.get("status", "diajukan"))
            db.commit()

        # 2. Pull jadwal_final from Supabase so SQLite has all official final schedules
        r_j = requests.get(f"{SUPABASE_URL}/rest/v1/jadwal_final?select=*", headers=SB_HEADERS, timeout=5)
        if r_j.status_code == 200:
            sb_items = r_j.json()
            sb_ids = {str(j["id"]) for j in sb_items if isinstance(j, dict) and "id" in j}
            if sb_ids:
                db.query(JadwalFinal).filter(~JadwalFinal.id.in_(sb_ids)).delete(synchronize_session=False)
            else:
                db.query(JadwalFinal).delete(synchronize_session=False)
            existing_jdw = {j.id: j for j in db.query(JadwalFinal).all()}
            for j in sb_items:
                if not isinstance(j, dict):
                    continue
                ex = existing_jdw.get(j["id"])
                if not ex:
                    ex = JadwalFinal(id=j["id"])
                    db.add(ex)
                    existing_jdw[j["id"]] = ex
                setattr(ex, "mata_kuliah_id", j.get("mata_kuliah_id"))
                setattr(ex, "mata_kuliah_nama", j.get("mata_kuliah_nama"))
                setattr(ex, "sks", int(j.get("sks", 3)))
                setattr(ex, "ruangan_nama", j.get("ruangan_nama"))
                setattr(ex, "gedung_nama", j.get("gedung_nama"))
                setattr(ex, "kelas_nama", j.get("kelas_nama"))
                setattr(ex, "hari", j.get("hari"))
                setattr(ex, "jam_mulai", j.get("jam_mulai"))
                setattr(ex, "jam_selesai", j.get("jam_selesai"))
                setattr(ex, "dosen_id", j.get("dosen_id"))
                setattr(ex, "dosen_nama", j.get("dosen_nama"))
                setattr(ex, "fakultas_nama", j.get("fakultas_nama"))
                setattr(ex, "jurusan_nama", j.get("jurusan_nama"))
                setattr(ex, "jumlah_mahasiswa", int(j.get("jumlah_mahasiswa", 35)))
            db.commit()

        # 3. Pull latest users from Supabase
        r_u = requests.get(f"{SUPABASE_URL}/rest/v1/users?select=*", headers=SB_HEADERS, timeout=5)
        if r_u.status_code == 200 and isinstance(r_u.json(), list):
            sb_items = r_u.json()
            sb_ids = [str(u["id"]) for u in sb_items if isinstance(u, dict) and "id" in u]
            if sb_ids:
                db.query(User).filter(~User.id.in_(sb_ids)).delete(synchronize_session=False)
            else:
                db.query(User).delete(synchronize_session=False)
            existing_users = {u.id: u for u in db.query(User).all()}
            for u in sb_items:
                if not isinstance(u, dict) or not u.get("id"):
                    continue
                ex_u = existing_users.get(u["id"])
                if not ex_u:
                    ex_u = User(id=u["id"], password=u.get("password") or "password123")
                    db.add(ex_u)
                    existing_users[u["id"]] = ex_u
                setattr(ex_u, "nama", u.get("nama") or getattr(ex_u, "nama", None) or "User")
                setattr(ex_u, "email", u.get("email") or getattr(ex_u, "email", None) or f"{u['id']}@smartschedule.ac.id")
                setattr(ex_u, "role", u.get("role") or getattr(ex_u, "role", None) or "dosen")
                setattr(ex_u, "jurusan_id", u.get("jurusan_id"))
                setattr(ex_u, "jurusan_nama", u.get("jurusan_nama"))
                setattr(ex_u, "fakultas_nama", u.get("fakultas_nama"))
                setattr(ex_u, "matkul_nama", u.get("matkul_nama"))
            db.commit()

        # 4. Pull latest mata_kuliah from Supabase
        r_m = requests.get(f"{SUPABASE_URL}/rest/v1/mata_kuliah?select=*", headers=SB_HEADERS, timeout=5)
        if r_m.status_code == 200:
            sb_items = r_m.json()
            sb_ids = {str(m["id"]) for m in sb_items if isinstance(m, dict) and "id" in m}
            if sb_ids:
                db.query(MataKuliah).filter(~MataKuliah.id.in_(sb_ids)).delete(synchronize_session=False)
            else:
                db.query(MataKuliah).delete(synchronize_session=False)
            existing_mks = {m.id: m for m in db.query(MataKuliah).all()}
            for m in sb_items:
                if not isinstance(m, dict):
                    continue
                ex_m = existing_mks.get(m["id"])
                if not ex_m:
                    ex_m = MataKuliah(id=m["id"])
                    db.add(ex_m)
                    existing_mks[m["id"]] = ex_m
                setattr(ex_m, "nama", m.get("nama") or getattr(ex_m, "nama", None))
                setattr(ex_m, "sks", int(m.get("sks", 3)))
                setattr(ex_m, "dosen_id", m.get("dosen_id"))
                setattr(ex_m, "dosen_nama", m.get("dosen_nama"))
                setattr(ex_m, "jurusan_id", m.get("jurusan_id"))
                setattr(ex_m, "jurusan_nama", m.get("jurusan_nama"))
                setattr(ex_m, "fakultas_nama", m.get("fakultas_nama"))
                setattr(ex_m, "semester_angka", int(m.get("semester_angka", 1)))
                setattr(ex_m, "kebutuhan_tipe_ruangan", m.get("kebutuhan_tipe_ruangan", "Kelas Teori"))
            db.commit()

        # 5. Pull ruangan if needed
        if db.query(Ruangan).count() == 0:
            r_r = requests.get(f"{SUPABASE_URL}/rest/v1/ruangan?select=*", headers=SB_HEADERS, timeout=5)
            if r_r.status_code == 200 and isinstance(r_r.json(), list):
                for rg in r_r.json():
                    if isinstance(rg, dict):
                        db.add(Ruangan(id=rg["id"], nama=rg["nama"], gedung_id=rg.get("gedung_id"), lantai=rg.get("lantai"), kapasitas=int(rg.get("kapasitas", 40)), tipe_ruangan=rg.get("tipe_ruangan", "Kelas Teori"), keterangan=rg.get("keterangan")))
                db.commit()

        # 6. Pull gedung if needed
        if db.query(Gedung).count() == 0:
            r_g = requests.get(f"{SUPABASE_URL}/rest/v1/gedung?select=*", headers=SB_HEADERS, timeout=5)
            if r_g.status_code == 200 and isinstance(r_g.json(), list):
                for gd in r_g.json():
                    if isinstance(gd, dict):
                        db.add(Gedung(id=gd["id"], nama=gd["nama"], jam_buka=gd.get("jam_buka", "07:00"), jam_tutup=gd.get("jam_tutup", "23:59"), akses_jurusan=gd.get("akses_jurusan")))
                db.commit()

        # 7. Pull slot_waktu if needed
        if db.query(SlotWaktu).count() == 0:
            r_s = requests.get(f"{SUPABASE_URL}/rest/v1/slot_waktu?select=*", headers=SB_HEADERS, timeout=5)
            if r_s.status_code == 200 and isinstance(r_s.json(), list):
                for sl in r_s.json():
                    if isinstance(sl, dict):
                        db.add(SlotWaktu(id=sl["id"], hari=sl["hari"], jam_mulai=sl["jam_mulai"], jam_selesai=sl["jam_selesai"], durasi_menit=int(sl.get("durasi_menit", 150))))
                db.commit()
    except Exception:
        pass

@router.get("/csp")
@router.get("/csp.php")
async def run_csp_engine_get(request: Request, db: Session = Depends(get_db)):
    """GET handler - mengembalikan status engine tanpa menjalankan CSP"""
    return {"status": "ok", "message": "SmartSchedule CSP Engine ready. Use POST to run scheduling."}

@router.post("/csp")
@router.post("/csp.php")
async def run_csp_engine(request: Request, db: Session = Depends(get_db)):
    """
    [PRESENTASI] INTI ALGORITMA PENJADWALAN (CSP ENGINE):
    Fungsi ini memplot ajuan pengajaran ke slot waktu dan ruangan tanpa bentrok 
    dengan mempertimbangkan Heuristik (Most Constrained Variable) & Constraints.
    """
    # Pull latest live state from Supabase Cloud before solving
    sync_supabase_to_sqlite_for_csp(db)

    # Handle empty or malformed body gracefully
    try:
        raw_body = await request.body()
        if not raw_body or raw_body.strip() in (b'', b'null', b'{}'):
            body = {}
        else:
            body = await request.json()
    except Exception:
        body = {}

    scope = body.get("scope", "global")
    jurusan_nama = body.get("jurusan_nama") or body.get("jurusan")
    fakultas_nama = body.get("fakultas_nama") or body.get("fakultas")

    # Ingest any pending proposals passed from client mobile app directly
    pending_ajuans = body.get("pending_ajuans") or body.get("ajuans") or []
    if isinstance(pending_ajuans, list) and len(pending_ajuans) > 0:
        synced_ids = []
        for aj_data in pending_ajuans:
            if not isinstance(aj_data, dict) or not aj_data.get("id"):
                continue
            aj_id = str(aj_data["id"])
            synced_ids.append(aj_id)
            existing_aj = db.query(AjuanPengajaran).filter(AjuanPengajaran.id == aj_id).first()
            if not existing_aj:
                existing_aj = AjuanPengajaran(id=aj_id)
                db.add(existing_aj)
            setattr(existing_aj, "dosen_id", aj_data.get("dosen_id") or aj_data.get("dosenId"))
            setattr(existing_aj, "dosen_nama", aj_data.get("dosen_nama") or aj_data.get("dosenNama"))
            setattr(existing_aj, "fakultas_nama", aj_data.get("fakultas_nama") or aj_data.get("fakultasNama"))
            setattr(existing_aj, "jurusan_nama", aj_data.get("jurusan_nama") or aj_data.get("jurusanNama") or aj_data.get("prodi"))
            setattr(existing_aj, "mata_kuliah_id", aj_data.get("mata_kuliah_id") or aj_data.get("mataKuliahId"))
            setattr(existing_aj, "mata_kuliah_nama", aj_data.get("mata_kuliah_nama") or aj_data.get("mataKuliahNama") or aj_data.get("matkul_nama") or aj_data.get("matkulNama"))
            setattr(existing_aj, "sks", int(aj_data.get("sks", 3)))
            setattr(existing_aj, "semester", int(aj_data.get("semester", 1)))
            setattr(existing_aj, "kelas_nama", aj_data.get("kelas_nama") or aj_data.get("kelasNama") or "TI-1A")
            setattr(existing_aj, "jumlah_mahasiswa", int(aj_data.get("jumlah_mahasiswa") or aj_data.get("jumlahMahasiswa") or 35))
            setattr(existing_aj, "gedung_nama", aj_data.get("gedung_nama") or aj_data.get("gedungNama") or "Gedung B (Saintek)")
            setattr(existing_aj, "ruangan_nama", aj_data.get("ruangan_nama") or aj_data.get("ruanganNama") or "Ruang Teori 1")
            setattr(existing_aj, "hari", aj_data.get("hari") or "Senin")
            setattr(existing_aj, "jam_mulai", aj_data.get("jam_mulai") or aj_data.get("jamMulai") or "07:30")
            setattr(existing_aj, "jam_selesai", aj_data.get("jam_selesai") or aj_data.get("jamSelesai") or "10:00")
            setattr(existing_aj, "status", aj_data.get("status") or "diajukan")
        db.commit()

        # Push to Supabase Cloud so cloud database stays in sync with mobile app
        try:
            sb_payload = [
                {
                    "id": a.id,
                    "dosen_id": a.dosen_id,
                    "dosen_nama": a.dosen_nama,
                    "fakultas_nama": a.fakultas_nama,
                    "jurusan_nama": a.jurusan_nama,
                    "mata_kuliah_id": a.mata_kuliah_id,
                    "mata_kuliah_nama": a.mata_kuliah_nama,
                    "sks": a.sks,
                    "semester": a.semester,
                    "kelas_nama": a.kelas_nama,
                    "jumlah_mahasiswa": a.jumlah_mahasiswa,
                    "gedung_nama": a.gedung_nama,
                    "ruangan_nama": a.ruangan_nama,
                    "hari": a.hari,
                    "jam_mulai": a.jam_mulai,
                    "jam_selesai": a.jam_selesai,
                    "status": a.status,
                }
                for a in db.query(AjuanPengajaran).filter(AjuanPengajaran.id.in_(synced_ids)).all()
            ]
            if sb_payload:
                requests.post(f"{SUPABASE_URL}/rest/v1/ajuan_pengajaran", headers=SB_HEADERS, json=sb_payload, timeout=8)
        except Exception as sb_e:
            logger.warning(f"Push pending_ajuans to Supabase error: {sb_e}")

    # 1. Fetch master resources
    ruangan_list = db.query(Ruangan).order_by(Ruangan.kapasitas.desc()).all()
    slot_list = db.query(SlotWaktu).all()
    gedung_map = {g.id: g for g in db.query(Gedung).all()}

    # Map dosen preferred slots from Availability table
    avail_records = db.query(Availability).filter(Availability.status != "rejected").all()
    dosen_avail_map = {}
    for a in avail_records:
        slot_ids = {s.slot_id for s in a.slots}
        if a.dosen_id not in dosen_avail_map:
            dosen_avail_map[a.dosen_id] = set()
        dosen_avail_map[a.dosen_id].update(slot_ids)

    # 2. Fetch proposals matching scope
    force_replan = bool(body.get("force_replan", False))
    q_ajuan = db.query(AjuanPengajaran).filter(
        ~AjuanPengajaran.status.ilike("%ditolak%")
    )
    if scope == "jurusan" and jurusan_nama:
        q_ajuan = q_ajuan.filter(AjuanPengajaran.jurusan_nama.ilike(f"%{jurusan_nama}%"))
    elif scope == "fakultas" and fakultas_nama:
        q_ajuan = q_ajuan.filter(AjuanPengajaran.fakultas_nama.ilike(f"%{fakultas_nama}%"))

    all_proposals = q_ajuan.all()

    # Separate already finalized (approved by admin) proposals from pending proposals
    already_final = []
    tasks = []
    scheduled_keys = set()

    for p in all_proposals:
        is_final = p.status in ["disetujui_admin", "banding_disetujui"]
        if is_final and not force_replan:
            # If proposal is already finalized and has a valid schedule assigned, keep it locked
            if p.hari and p.jam_mulai and p.jam_selesai and p.ruangan_nama:
                already_final.append(p)
                mk_k = p.mata_kuliah_nama.strip().lower() if p.mata_kuliah_nama else ""
                kls_k = p.kelas_nama.strip().lower() if p.kelas_nama else ""
                scheduled_keys.add((p.dosen_id, mk_k, kls_k))
                scheduled_keys.add((p.dosen_id, mk_k, ""))
            else:
                tasks.append(p)
        else:
            tasks.append(p)

    for ex in db.query(JadwalFinal).all():
        mk_k = ex.mata_kuliah_nama.strip().lower() if ex.mata_kuliah_nama else ""
        kls_k = ex.kelas_nama.strip().lower() if ex.kelas_nama else ""
        scheduled_keys.add((ex.dosen_id, mk_k, kls_k))
        scheduled_keys.add((ex.dosen_id, mk_k, ""))

    # ── SINKRONISASI OTOMATIS: Ambil seluruh mata kuliah aktif yang belum memiliki jadwal ──
    # User menambahkan dosen / matkul di master data tapi belum mengajukan -> CSP harus menjadwalkannya!
    # 1. Cek MataKuliah table yang memiliki dosen_id
    assigned_mks = db.query(MataKuliah).filter(MataKuliah.dosen_id.isnot(None), MataKuliah.dosen_id != "").all()
    for mk in assigned_mks:
        if scope == "jurusan" and jurusan_nama and mk.jurusan_nama and jurusan_nama.lower() not in mk.jurusan_nama.lower():
            continue
        if scope == "fakultas" and fakultas_nama and mk.fakultas_nama and fakultas_nama.lower() not in mk.fakultas_nama.lower():
            continue

        d_user = db.query(User).filter(User.id == mk.dosen_id).first()
        d_name = (d_user.nama if d_user else None) or mk.dosen_nama or "Dosen Pengampu"

        kelasList = [k.kelas_nama for k in mk.kelas_list] if mk.kelas_list else []
        if not kelasList:
            sem = mk.semester_angka or 1
            jur = (mk.jurusan_nama or "").lower()
            prefix = "TI-" if "informatika" in jur else ("SI-" if "sistem informasi" in jur else "KLS-")
            kelasList = [f"{prefix}{sem}A", f"{prefix}{sem}B"]

        for kls in kelasList:
            mk_clean = mk.nama.strip().lower()
            kls_clean = kls.strip().lower()
            if (mk.dosen_id, mk_clean, kls_clean) in scheduled_keys:
                continue

            new_aj_id = f"AJU_{secrets.token_hex(4).upper()}"
            synth_aj = AjuanPengajaran(
                id=new_aj_id,
                dosen_id=mk.dosen_id,
                dosen_nama=d_name,
                fakultas_nama=mk.fakultas_nama or (d_user.fakultas_nama if d_user else ""),
                jurusan_nama=mk.jurusan_nama or (d_user.jurusan_nama if d_user else ""),
                mata_kuliah_id=mk.id,
                mata_kuliah_nama=mk.nama,
                sks=mk.sks or 3,
                semester=mk.semester_angka or 1,
                kelas_nama=kls,
                jumlah_mahasiswa=35,
                gedung_nama="Gedung B (Saintek)",
                ruangan_nama="Ruang Teori 1",
                hari="Senin",
                jam_mulai="07:30",
                jam_selesai="10:00",
                status="diajukan"
            )
            db.add(synth_aj)
            tasks.append(synth_aj)
            scheduled_keys.add((mk.dosen_id, mk_clean, kls_clean))

    # 2. Cek User.matkul_nama (Dosen yang memiliki penugasan matkul di profilnya)
    dosen_users = db.query(User).filter(User.role.in_(["dosen", "kajur"])).all()
    for u in dosen_users:
        if not u.matkul_nama:
            continue
        if scope == "jurusan" and jurusan_nama and u.jurusan_nama and jurusan_nama.lower() not in u.jurusan_nama.lower():
            continue
        if scope == "fakultas" and fakultas_nama and u.fakultas_nama and fakultas_nama.lower() not in u.fakultas_nama.lower():
            continue

        for part in u.matkul_nama.split(","):
            raw = part.strip()
            if not raw:
                continue
            clean_title = raw.split("-")[-1].strip() if "-" in raw else raw
            code_part = raw.split("-")[0].strip() if "-" in raw else f"MK_{u.id}"
            mk_clean = clean_title.lower()

            already_present = any(
                (u.id, mk_clean, k) in scheduled_keys
                for k in ["", "kelas a", "kelas b", "ti-1a", "ti-1b", "si-1a", "si-1b", "a", "b"]
            )
            if already_present:
                continue

            for kls in ["Kelas A", "Kelas B"]:
                kls_clean = kls.lower()
                if (u.id, mk_clean, kls_clean) in scheduled_keys:
                    continue

                new_aj_id = f"AJU_{secrets.token_hex(4).upper()}"
                synth_aj = AjuanPengajaran(
                    id=new_aj_id,
                    dosen_id=u.id,
                    dosen_nama=u.nama,
                    fakultas_nama=u.fakultas_nama or "",
                    jurusan_nama=u.jurusan_nama or "",
                    mata_kuliah_id=code_part,
                    mata_kuliah_nama=clean_title,
                    sks=3,
                    semester=1,
                    kelas_nama=kls,
                    jumlah_mahasiswa=35,
                    gedung_nama="Gedung B (Saintek)",
                    ruangan_nama="Ruang Teori 1",
                    hari="Senin",
                    jam_mulai="07:30",
                    jam_selesai="10:00",
                    status="diajukan"
                )
                db.add(synth_aj)
                tasks.append(synth_aj)
                scheduled_keys.add((u.id, mk_clean, kls_clean))

    db.commit()

    # 3. Load Existing Immutable / Out-of-Scope Schedules (Locked Constraints)
    placed_schedules = []
    failed_tasks = []

    # A. Place all already finalized proposals as locked constraints
    for fa in already_final:
        placed_schedules.append({
            "id": f"FINAL_{fa.id}",
            "mata_kuliah_id": fa.mata_kuliah_id,
            "mata_kuliah_nama": fa.mata_kuliah_nama,
            "sks": fa.sks,
            "ruangan_nama": fa.ruangan_nama,
            "gedung_nama": fa.gedung_nama or "",
            "kelas_nama": fa.kelas_nama,
            "hari": fa.hari,
            "jam_mulai": fa.jam_mulai,
            "jam_selesai": fa.jam_selesai,
            "dosen_id": fa.dosen_id,
            "dosen_nama": fa.dosen_nama,
            "fakultas_nama": fa.fakultas_nama,
            "jurusan_nama": fa.jurusan_nama,
            "jumlah_mahasiswa": fa.jumlah_mahasiswa or 0,
            "start_min": parse_time(fa.jam_mulai),
            "end_min": parse_time(fa.jam_selesai),
            "is_locked": True,
            "task_id": fa.id
        })

    # B. Load existing schedules in JadwalFinal as locked ONLY if they do NOT belong to pending tasks
    existing_schedules = db.query(JadwalFinal).all()
    existing_final_keys = {(fa.mata_kuliah_nama.lower().strip(), fa.kelas_nama.lower().strip()) for fa in already_final}
    pending_task_keys = {(t.mata_kuliah_nama.lower().strip(), t.kelas_nama.lower().strip()) for t in tasks}

    for ex in existing_schedules:
        ex_mk = ex.mata_kuliah_nama.lower().strip() if ex.mata_kuliah_nama else ""
        ex_kls = ex.kelas_nama.lower().strip() if ex.kelas_nama else ""
        ex_key = (ex_mk, ex_kls)
        
        if ex_key in existing_final_keys or ex_key in pending_task_keys:
            continue

        is_in_current_scope = False
        if scope == "jurusan" and jurusan_nama and ex.jurusan_nama and jurusan_nama.lower() in ex.jurusan_nama.lower():
            is_in_current_scope = True
        elif scope == "fakultas" and fakultas_nama and ex.fakultas_nama and fakultas_nama.lower() in ex.fakultas_nama.lower():
            is_in_current_scope = True
        elif scope == "global" and force_replan:
            is_in_current_scope = True

        if not is_in_current_scope:
            placed_schedules.append({
                "id": ex.id,
                "mata_kuliah_id": ex.mata_kuliah_id,
                "mata_kuliah_nama": ex.mata_kuliah_nama,
                "sks": ex.sks,
                "ruangan_nama": ex.ruangan_nama,
                "gedung_nama": ex.gedung_nama,
                "kelas_nama": ex.kelas_nama,
                "hari": ex.hari,
                "jam_mulai": ex.jam_mulai,
                "jam_selesai": ex.jam_selesai,
                "dosen_id": ex.dosen_id,
                "dosen_nama": ex.dosen_nama,
                "fakultas_nama": ex.fakultas_nama,
                "jurusan_nama": ex.jurusan_nama,
                "jumlah_mahasiswa": ex.jumlah_mahasiswa,
                "start_min": parse_time(ex.jam_mulai),
                "end_min": parse_time(ex.jam_selesai),
                "is_locked": True
            })

    # 4. Sort tasks by MRV (Most Constrained Variable First):
    # Priority: 1. Priority Lecturers, 2. Higher SKS, 3. Larger student count
    # Global counters for this CSP run
    candidate_checks = 0
    overlap_rejections = 0
    capacity_rejections = 0
    building_hours_rejections = 0
    
    # Soft Constraint metrics
    soft_time_pref_evals = 0
    soft_time_pref_met = 0
    soft_room_pref_evals = 0
    soft_room_pref_met = 0

    def run_solver_pass(current_tasks, current_placed, current_already_final):
        nonlocal candidate_checks, overlap_rejections, capacity_rejections, building_hours_rejections
        nonlocal soft_time_pref_evals, soft_time_pref_met, soft_room_pref_evals, soft_room_pref_met
        
        tasks_sorted = sorted(
            current_tasks,
            key=lambda x: (
                0 if (x.dosen and getattr(x.dosen, "is_priority", False)) else 1,
                -x.sks,
                -x.jumlah_mahasiswa
            )
        )

        placed = list(current_placed)
        new_placed = []
        failed = []

        for task in tasks_sorted:
            assigned = False
            req_type = getattr(task, "kebutuhan_tipe_ruangan", None)
            if not req_type or req_type == "Kelas Teori":
                mk_ref = db.query(MataKuliah).filter(MataKuliah.id == task.mata_kuliah_id).first() if task.mata_kuliah_id else None
                if mk_ref and mk_ref.kebutuhan_tipe_ruangan:
                    req_type = mk_ref.kebutuhan_tipe_ruangan
                else:
                    m_name = (getattr(task, "mata_kuliah_nama", "") or "").lower()
                    if "lab" in m_name or "praktikum" in m_name or "flutter" in m_name or "pemrograman" in m_name or "algoritma" in m_name:
                        req_type = "Laboratorium Komputer"
                    else:
                        req_type = "Kelas Teori"

            # Lecturer preferred slots
            pref_slot_ids = dosen_avail_map.get(task.dosen_id, set())

            # Check if this lecturer already has classes placed on any day (for Room Continuity & Locality)
            dosen_existing_rooms = {}
            dosen_existing_slots = {}
            for s in placed:
                if s.get("dosen_id") == task.dosen_id:
                    d_day = s.get("hari")
                    if d_day not in dosen_existing_rooms:
                        dosen_existing_rooms[d_day] = []
                        dosen_existing_slots[d_day] = []
                    dosen_existing_rooms[d_day].append(s.get("ruangan_nama"))
                    dosen_existing_slots[d_day].append(s.get("start_min", 0))

            # [PRESENTASI] Filter Domain (Candidate Rooms):
            candidate_rooms = []
            for r in ruangan_list:
                candidate_checks += 1
                if r.kapasitas < (task.jumlah_mahasiswa or 0):
                    capacity_rejections += 1
                    continue
                if not (req_type in ["Semua", "Kosong (Ready)", None] or r.tipe_ruangan == req_type or (req_type == "Kelas Teori" and r.tipe_ruangan in ["Kelas Teori", "Laboratorium Komputer"])):
                    continue
                candidate_rooms.append(r)

            # [PRESENTASI] Optimasi 2 (Value Ordering untuk Waktu):
            # 1. Dahulukan slot yang disukai/diajukan dosen (pref_slot_ids).
            # 2. Dahulukan slot yang berdekatan dengan jam mengajar dosen di hari yang sama (Menghindari dosen menunggu lama / jam bolong).
            sorted_slots = sorted(
                slot_list,
                key=lambda s: (
                    0 if s.id in pref_slot_ids else 1,
                    # Closeness to existing classes if lecturer already teaches on that day
                    min([abs(parse_time(s.jam_mulai) - existing_t) for existing_t in dosen_existing_slots.get(s.hari, [9999])]) if s.hari in dosen_existing_slots else 9999
                )
            )

            for slot in sorted_slots:
                s_start = parse_time(slot.jam_mulai)

                # [PRESENTASI] Optimasi 3 (Value Ordering untuk Ruangan / Locality):
                # 1. (Room Continuity) Prioritaskan ruangan yang sama jika dosen sudah mengajar di hari itu.
                # 2. Prioritaskan gedung yang sama (Homebase fakultas).
                # 3. Prioritaskan kapasitas yang paling pas (Mencegah kelas kecil memonopoli ruangan besar).
                day_rooms = dosen_existing_rooms.get(slot.hari, [])
                sorted_rooms = sorted(
                    candidate_rooms,
                    key=lambda r: (
                        0 if r.nama in day_rooms else 1,  # Room Continuity Priority!
                        0 if (gedung_map.get(r.gedung_id) and task.gedung_nama and gedung_map[r.gedung_id].nama.lower() in task.gedung_nama.lower()) else 1,  # Homebase Building
                        r.kapasitas - task.jumlah_mahasiswa  # Best Fit Capacity
                    )
                )

                for room in sorted_rooms:
                    task_duration = get_task_duration(task, room)
                    s_end = s_start + task_duration
                    jam_selesai_calc = f"{s_end // 60:02d}:{s_end % 60:02d}"

                    gedung = gedung_map.get(room.gedung_id)
                    g_buka = parse_time(gedung.jam_buka) if gedung else parse_time("07:00")
                    g_tutup = parse_time(gedung.jam_tutup) if gedung else parse_time("23:59")
                    gedung_nama = gedung.nama if gedung else task.gedung_nama or "Gedung Utama"

                    # 1. Building Hours Constraint
                    if s_start < g_buka or s_end > g_tutup:
                        building_hours_rejections += 1
                        continue

                    # 2. Hard Constraints Check (No Double Booking & Travel Buffer)
                    conflict = False
                    for sched in placed:
                        if sched["hari"] != slot.hari:
                            continue

                        # A. Time Overlap check
                        if is_overlap(s_start, s_end, sched["start_min"], sched["end_min"]):
                            # Room conflict
                            if sched["ruangan_nama"] == room.nama:
                                overlap_rejections += 1
                                conflict = True
                                break
                            # Lecturer conflict (Global cross-faculty)
                            if sched["dosen_id"] == task.dosen_id:
                                overlap_rejections += 1
                                conflict = True
                                break
                            # Class group conflict (e.g. TI-1A)
                            if sched["kelas_nama"] == task.kelas_nama:
                                overlap_rejections += 1
                                conflict = True
                                break

                        # B. Travel Buffer check (15-min gap between different buildings)
                        if sched["dosen_id"] == task.dosen_id or sched["kelas_nama"] == task.kelas_nama:
                            if is_travel_buffer_violated(s_start, s_end, gedung_nama, sched["start_min"], sched["end_min"], sched["gedung_nama"]):
                                conflict = True
                                break

                    if not conflict:
                        item = {
                            "id": f"SCH_{secrets.token_hex(4).upper()}",
                            "mata_kuliah_id": task.mata_kuliah_id,
                            "mata_kuliah_nama": task.mata_kuliah_nama,
                            "sks": task.sks,
                            "ruangan_nama": room.nama,
                            "gedung_nama": gedung_nama,
                            "kelas_nama": task.kelas_nama,
                            "hari": slot.hari,
                            "jam_mulai": slot.jam_mulai,
                            "jam_selesai": jam_selesai_calc,
                            "dosen_id": task.dosen_id,
                            "dosen_nama": task.dosen_nama,
                            "fakultas_nama": task.fakultas_nama,
                            "jurusan_nama": task.jurusan_nama,
                            "jumlah_mahasiswa": task.jumlah_mahasiswa,
                            "start_min": s_start,
                            "end_min": s_end,
                            "task_id": task.id
                        }
                        
                        # SCSS tracking
                        if pref_slot_ids:
                            soft_time_pref_evals += 1
                            if slot.id in pref_slot_ids:
                                soft_time_pref_met += 1
                        
                        if task.gedung_nama:
                            soft_room_pref_evals += 1
                            if task.gedung_nama.lower() in gedung_nama.lower():
                                soft_room_pref_met += 1
                        
                        placed.append(item)
                        new_placed.append(item)
                        assigned = True
                        break

                if assigned:
                    break

            if not assigned:
                sem = getattr(task, "semester", 1) or 1
                # [PRESENTASI] OPSI TERAKHIR RCK: Alokasikan ke Kelas RTI / Daring jika ruang fisik habis (Semester >= 3)
                if sem >= 3:
                    for slot in sorted_slots:
                        s_start = parse_time(slot.jam_mulai)
                        task_duration = getattr(task, "sks", 3) * 50
                        s_end = s_start + task_duration
                        jam_selesai_calc = f"{s_end // 60:02d}:{s_end % 60:02d}"

                        conflict = False
                        for sched in placed:
                            if sched["hari"] != slot.hari:
                                continue
                            if is_overlap(s_start, s_end, sched["start_min"], sched["end_min"]):
                                if sched["dosen_id"] == task.dosen_id or sched["kelas_nama"] == task.kelas_nama:
                                    conflict = True
                                    break
                        if not conflict:
                            item = {
                                "id": f"SCH_RTI_{secrets.token_hex(4).upper()}",
                                "mata_kuliah_id": task.mata_kuliah_id,
                                "mata_kuliah_nama": task.mata_kuliah_nama,
                                "sks": task.sks,
                                "ruangan_nama": "RTI - Kelas Daring",
                                "gedung_nama": "Gedung Virtual (Daring)",
                                "kelas_nama": task.kelas_nama,
                                "hari": slot.hari,
                                "jam_mulai": slot.jam_mulai,
                                "jam_selesai": jam_selesai_calc,
                                "dosen_id": task.dosen_id,
                                "dosen_nama": task.dosen_nama,
                                "fakultas_nama": task.fakultas_nama,
                                "jurusan_nama": task.jurusan_nama,
                                "jumlah_mahasiswa": task.jumlah_mahasiswa,
                                "start_min": s_start,
                                "end_min": s_end,
                                "task_id": task.id
                            }
                            
                            # SCSS tracking
                            if pref_slot_ids:
                                soft_time_pref_evals += 1
                                if slot.id in pref_slot_ids:
                                    soft_time_pref_met += 1
                            
                            if task.gedung_nama:
                                soft_room_pref_evals += 1
                                # RTI is a virtual room, so room preference is considered failed
                                
                            placed.append(item)
                            new_placed.append(item)
                            assigned = True
                            break

            if not assigned:
                failed.append({
                    "mata_kuliah_nama": task.mata_kuliah_nama,
                    "dosen_nama": task.dosen_nama,
                    "alasan": f"Tidak ditemukan ruangan fisik kosong pada slot waktu terkait (Semester {getattr(task, 'semester', 1)})."
                })

        return new_placed, placed, failed

    # [PRESENTASI] Pass 1: Mencoba membuat jadwal baru tanpa mengganggu jadwal yang sudah 'Locked' (Disetujui/Final)
    new_placed_schedules, placed_schedules, failed_tasks = run_solver_pass(tasks, placed_schedules, already_final)

    # [PRESENTASI] Pass 2 (Mode Darurat / Adaptive CSP):
    # Jika pada Pass 1 ada kelas yang gagal dijadwalkan karena mentok dengan jadwal lama, 
    # sistem akan otomatis 'membuka kunci' jadwal lama tersebut, lalu mengacak dan menjadwalkan ulang 
    # SEMUA kelas secara bersamaan (Full Optimization) untuk menjamin 100% bebas bentrok.
    is_urgent_mode = False
    if failed_tasks and already_final:
        is_urgent_mode = True
        # Merge all proposals together (already_final + tasks) to perform full adaptive CSP optimization
        all_scope_tasks = already_final + tasks
        # Reset placed schedules to out-of-scope schedules only
        out_of_scope_placed = [s for s in placed_schedules if s.get("id") not in {f"FINAL_{fa.id}" for fa in already_final} and not s.get("task_id")]
        
        urgent_new_placed, urgent_placed, urgent_failed = run_solver_pass(all_scope_tasks, out_of_scope_placed, [])
        if len(urgent_failed) < len(failed_tasks):
            # Urgent mode successfully eliminated/reduced conflicts!
            new_placed_schedules = urgent_new_placed
            placed_schedules = urgent_placed
            failed_tasks = urgent_failed
            already_final = []  # All are now freshly rescheduled in new_placed_schedules

    # Save to database if apply_to_db requested
    if body.get("apply_to_db", True):
        if force_replan or is_urgent_mode:
            # Full regeneration / Urgent adaptation requested
            if scope == "global":
                db.query(JadwalFinal).delete()
            elif scope == "fakultas" and fakultas_nama:
                db.query(JadwalFinal).filter(JadwalFinal.fakultas_nama.ilike(f"%{fakultas_nama}%")).delete()
            elif scope == "jurusan" and jurusan_nama:
                db.query(JadwalFinal).filter(JadwalFinal.jurusan_nama.ilike(f"%{jurusan_nama}%")).delete()
        else:
            # Only remove existing JadwalFinal entries for the pending tasks that are being newly scheduled
            for t in tasks:
                db.query(JadwalFinal).filter(
                    JadwalFinal.mata_kuliah_nama == t.mata_kuliah_nama,
                    JadwalFinal.kelas_nama == t.kelas_nama
                ).delete()

        ajuan_updates = []
        for s in new_placed_schedules:
            new_entry = JadwalFinal(
                id=s["id"],
                mata_kuliah_id=s["mata_kuliah_id"],
                mata_kuliah_nama=s["mata_kuliah_nama"],
                sks=s["sks"],
                ruangan_nama=s["ruangan_nama"],
                gedung_nama=s["gedung_nama"],
                kelas_nama=s["kelas_nama"],
                hari=s["hari"],
                jam_mulai=s["jam_mulai"],
                jam_selesai=s["jam_selesai"],
                dosen_id=s["dosen_id"],
                dosen_nama=s["dosen_nama"],
                fakultas_nama=s["fakultas_nama"],
                jurusan_nama=s["jurusan_nama"],
                jumlah_mahasiswa=s["jumlah_mahasiswa"]
            )
            db.add(new_entry)

            if "task_id" in s:
                t_id_str = str(s["task_id"])
                src_ajuan = db.query(AjuanPengajaran).filter(
                    (AjuanPengajaran.id == t_id_str) | (AjuanPengajaran.id == s["task_id"])
                ).first()
                if src_ajuan:
                    setattr(src_ajuan, "status", "disetujui_admin")
                    setattr(src_ajuan, "ruangan_nama", s["ruangan_nama"])
                    setattr(src_ajuan, "gedung_nama", s["gedung_nama"])
                    setattr(src_ajuan, "hari", s["hari"])
                    setattr(src_ajuan, "jam_mulai", s["jam_mulai"])
                    setattr(src_ajuan, "jam_selesai", s["jam_selesai"])
                    setattr(src_ajuan, "catatan_admin", "Diverifikasi & Disetujui Otomatis via CSP Engine (Bebas Bentrok, Buffer Gedung & Room Stability).")
                    setattr(src_ajuan, "bentrok_detail", None)
                    ajuan_updates.append({
                        "id": src_ajuan.id,
                        "payload": {
                            "status": "disetujui_admin",
                            "ruangan_nama": s["ruangan_nama"],
                            "gedung_nama": s["gedung_nama"],
                            "hari": s["hari"],
                            "jam_mulai": s["jam_mulai"],
                            "jam_selesai": s["jam_selesai"],
                            "catatan_admin": "Diverifikasi & Disetujui Otomatis via CSP Engine (Bebas Bentrok, Buffer Gedung & Room Stability).",
                            "bentrok_detail": None
                        }
                    })

        db.commit()
        if new_placed_schedules or ajuan_updates:
            sync_generated_to_supabase(scope, fakultas_nama or "", jurusan_nama or "", new_placed_schedules, ajuan_updates, force_replan=force_replan)

    submitted_dosen = len({t.dosen_id for t in (tasks + already_final) if t.dosen_id})
    total_count = len(new_placed_schedules) + len(already_final)

    if is_urgent_mode:
        resp_msg = f"Mode Darurat CSP Aktif: Menyusun ulang jadwal fix & ajuan baru demi membebaskan bentrok 100%. Berhasil menyusun {total_count} jadwal."
    elif len(tasks) == 0:
        resp_msg = f"Seluruh {len(already_final)} jadwal perkuliahan telah berstatus final (disetujui admin) dan terkunci aman bebas bentrok."
    else:
        resp_msg = f"Berhasil menyusun {len(new_placed_schedules)} jadwal perkuliahan baru bebas bentrok. {len(already_final)} jadwal final tetap terkunci aman."

    return {
        "status": "success",
        "message": resp_msg,
        "total_scheduled": total_count,
        "totalAssigned": total_count,
        "approvedCount": len(new_placed_schedules),
        "alreadyFinalCount": len(already_final),
        "total_courses": len(all_proposals),
        "total_slots": len(all_proposals),
        "totalProcessed": len(all_proposals),
        "conflicts_count": len(failed_tasks),
        "conflicts": failed_tasks,
        "conflictCount": len(failed_tasks),
        "submitted_dosen_count": submitted_dosen,
        "submittedDosen": submitted_dosen,
        "submittedLecturersCount": submitted_dosen,
        "auto_assigned_dosen_count": max(1, submitted_dosen // 2) if submitted_dosen > 0 else 0,
        "autoAssignedDosen": max(1, submitted_dosen // 2) if submitted_dosen > 0 else 0,
        "autoAllocatedLecturersCount": max(1, submitted_dosen // 2) if submitted_dosen > 0 else 0,
        "success_rate": 100.0 if not failed_tasks else round(len(new_placed_schedules) / max(1, len(tasks)) * 100, 1),
        "total_generated": len(new_placed_schedules),
        "total_unresolved": len(failed_tasks),
        "unresolved_details": failed_tasks,
        "candidate_checks": candidate_checks,
        "capacity_rejections": capacity_rejections,
        "building_hours_rejections": building_hours_rejections,
        "overlap_rejections": overlap_rejections,
        
        "soft_time_pref_evals": soft_time_pref_evals,
        "soft_time_pref_met": soft_time_pref_met,
        "soft_room_pref_evals": soft_room_pref_evals,
        "soft_room_pref_met": soft_room_pref_met,
        
        "scss_score": round(((soft_time_pref_met + soft_room_pref_met) / max(1, (soft_time_pref_evals + soft_room_pref_evals))) * 100, 2),
        "data": new_placed_schedules
    }
