import sys
import os
sys.path.insert(0, os.path.dirname(os.path.dirname(os.path.abspath(__file__))))

from fastapi import APIRouter, Depends, HTTPException, Query, Request
from sqlalchemy.orm import Session
from typing import Optional
from datetime import datetime
from core.database import get_db
from models.models import AjuanPengajaran, User, JadwalFinal
import secrets
import requests

from core.config import SUPABASE_URL, SUPABASE_KEY, SB_HEADERS
from core.security import sanitize_supabase_param
import logging

logger = logging.getLogger("smartschedule.ajuan")

def sync_ajuan_to_supabase(a: AjuanPengajaran):
    try:
        url = f"{SUPABASE_URL}/rest/v1/ajuan_pengajaran"
        payload = {
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
            "catatan_dosen": a.catatan_dosen,
            "catatan_kaprodi": a.catatan_kaprodi,
            "catatan_dekan": a.catatan_dekan,
            "catatan_admin": a.catatan_admin,
            "alasan_penolakan": a.alasan_penolakan,
            "alasan_banding": a.alasan_banding,
            "preferensi_banding_hari": a.preferensi_banding_hari,
            "preferensi_banding_jam": a.preferensi_banding_jam,
            "bentrok_detail": a.bentrok_detail,
        }
        requests.post(url, headers=SB_HEADERS, json=payload, timeout=5)
    except Exception as e:
        logger.warning(f"Failed to sync ajuan to Supabase: {e}")

def delete_ajuan_from_supabase(aid: str):
    try:
        safe_id = sanitize_supabase_param(aid)
        url = f"{SUPABASE_URL}/rest/v1/ajuan_pengajaran?id=eq.{safe_id}"
        requests.delete(url, headers=SB_HEADERS, timeout=6)
    except Exception as e:
        logger.warning(f"Failed to delete ajuan from Supabase: {e}")

def sync_jadwal_to_supabase(j: JadwalFinal):
    try:
        url = f"{SUPABASE_URL}/rest/v1/jadwal_final"
        payload = {
            "id": j.id,
            "mata_kuliah_id": j.mata_kuliah_id,
            "mata_kuliah_nama": j.mata_kuliah_nama,
            "sks": j.sks,
            "ruangan_nama": j.ruangan_nama,
            "gedung_nama": j.gedung_nama,
            "kelas_nama": j.kelas_nama,
            "hari": j.hari,
            "jam_mulai": j.jam_mulai,
            "jam_selesai": j.jam_selesai,
            "dosen_id": j.dosen_id,
            "dosen_nama": j.dosen_nama,
            "fakultas_nama": j.fakultas_nama,
            "jurusan_nama": j.jurusan_nama,
            "jumlah_mahasiswa": j.jumlah_mahasiswa
        }
        requests.post(url, headers=SB_HEADERS, json=payload, timeout=5)
    except Exception:
        pass

router = APIRouter(prefix="/ajuan", tags=["Ajuan Pengajaran"])

def format_ajuan(a: AjuanPengajaran):
    return {
        "id": a.id,
        "dosenId": a.dosen_id,
        "dosen_id": a.dosen_id,
        "dosenNama": a.dosen_nama,
        "dosen_nama": a.dosen_nama,
        "fakultasNama": a.fakultas_nama,
        "fakultas_nama": a.fakultas_nama,
        "jurusanNama": a.jurusan_nama,
        "jurusan_nama": a.jurusan_nama,
        "prodi": a.jurusan_nama,
        "mataKuliahId": a.mata_kuliah_id,
        "mata_kuliah_id": a.mata_kuliah_id,
        "mataKuliahNama": a.mata_kuliah_nama,
        "mata_kuliah_nama": a.mata_kuliah_nama,
        "sks": a.sks,
        "semester": a.semester,
        "kelasNama": a.kelas_nama,
        "kelas_nama": a.kelas_nama,
        "jumlahMahasiswa": a.jumlah_mahasiswa,
        "jumlah_mahasiswa": a.jumlah_mahasiswa,
        "gedungNama": a.gedung_nama,
        "gedung_nama": a.gedung_nama,
        "ruanganNama": a.ruangan_nama,
        "ruangan_nama": a.ruangan_nama,
        "hari": a.hari,
        "jamMulai": a.jam_mulai,
        "jam_mulai": a.jam_mulai,
        "jamSelesai": a.jam_selesai,
        "jam_selesai": a.jam_selesai,
        "status": a.status,
        "catatanDosen": a.catatan_dosen,
        "catatan_dosen": a.catatan_dosen,
        "catatanKaprodi": a.catatan_kaprodi,
        "catatan_kaprodi": a.catatan_kaprodi,
        "catatanDekan": a.catatan_dekan,
        "catatan_dekan": a.catatan_dekan,
        "catatanAdmin": a.catatan_admin,
        "catatan_admin": a.catatan_admin,
        "alasanPenolakan": a.alasan_penolakan,
        "alasan_penolakan": a.alasan_penolakan,
        "alasanBanding": a.alasan_banding,
        "alasan_banding": a.alasan_banding,
        "preferensiBandingHari": a.preferensi_banding_hari,
        "preferensi_banding_hari": a.preferensi_banding_hari,
        "preferensiBandingJam": a.preferensi_banding_jam,
        "preferensi_banding_jam": a.preferensi_banding_jam,
        "bentrokDetail": a.bentrok_detail,
        "bentrok_detail": a.bentrok_detail,
        "createdAt": str(a.created_at),
        "created_at": str(a.created_at),
        "updatedAt": str(a.updated_at),
        "updated_at": str(a.updated_at)
    }

@router.get("")
@router.get("/")
@router.get("/index.php")
def get_ajuan(
    dosen_id: Optional[str] = None,
    dosenId: Optional[str] = None,
    status: Optional[str] = None,
    jurusan_nama: Optional[str] = None,
    prodi: Optional[str] = None,
    fakultas: Optional[str] = None,
    db: Session = Depends(get_db)
):
    q = db.query(AjuanPengajaran)
    did = dosen_id or dosenId
    if did:
        q = q.filter((AjuanPengajaran.dosen_id == did) | (AjuanPengajaran.dosen_nama.ilike(f"%{did}%")))
    if status and status != "Semua":
        q = q.filter(AjuanPengajaran.status == status)
    
    jur = jurusan_nama or prodi
    if jur and jur != "Semua":
        q = q.filter(AjuanPengajaran.jurusan_nama.ilike(f"%{jur}%"))
    if fakultas and fakultas != "Semua":
        q = q.filter(AjuanPengajaran.fakultas_nama.ilike(f"%{fakultas}%"))
    
    items = q.order_by(AjuanPengajaran.created_at.desc()).all()
    if not items:
        try:
            r = requests.get(f"{SUPABASE_URL}/rest/v1/ajuan_pengajaran?select=*&order=created_at.desc", headers=SB_HEADERS, timeout=5)
            if r.status_code == 200 and r.json():
                for item in r.json():
                    exist = db.query(AjuanPengajaran).filter(AjuanPengajaran.id == item["id"]).first()
                    if not exist:
                        db.add(AjuanPengajaran(
                            id=item["id"],
                            dosen_id=item.get("dosen_id"),
                            dosen_nama=item.get("dosen_nama"),
                            fakultas_nama=item.get("fakultas_nama"),
                            jurusan_nama=item.get("jurusan_nama"),
                            mata_kuliah_id=item.get("mata_kuliah_id"),
                            mata_kuliah_nama=item.get("mata_kuliah_nama"),
                            sks=item.get("sks", 3),
                            semester=item.get("semester", 1),
                            kelas_nama=item.get("kelas_nama"),
                            jumlah_mahasiswa=item.get("jumlah_mahasiswa", 40),
                            gedung_nama=item.get("gedung_nama"),
                            ruangan_nama=item.get("ruangan_nama"),
                            hari=item.get("hari"),
                            jam_mulai=item.get("jam_mulai"),
                            jam_selesai=item.get("jam_selesai"),
                            status=item.get("status", "menunggu_kaprodi"),
                            catatan_dosen=item.get("catatan_dosen"),
                            catatan_kaprodi=item.get("catatan_kaprodi"),
                            catatan_dekan=item.get("catatan_dekan"),
                            catatan_admin=item.get("catatan_admin"),
                            alasan_penolakan=item.get("alasan_penolakan"),
                            alasan_banding=item.get("alasan_banding"),
                            preferensi_banding_hari=item.get("preferensi_banding_hari"),
                            preferensi_banding_jam=item.get("preferensi_banding_jam"),
                            bentrok_detail=item.get("bentrok_detail"),
                        ))
                db.commit()
                items = q.order_by(AjuanPengajaran.created_at.desc()).all()
        except Exception as e:
            logger.warning(f"Failed to auto-sync ajuan from Supabase: {e}")

    return {"status": "success", "data": [format_ajuan(a) for a in items]}

@router.post("")
@router.post("/")
@router.post("/index.php")
@router.post("/submit")
@router.post("/submit.php")
async def submit_or_create_ajuan(request: Request, db: Session = Depends(get_db)):
    """
    [PRESENTASI] Pengajuan Jadwal oleh Dosen / Tambah Ajuan:
    Mendukung pembuatan draf ajuan baru, pembaruan ajuan yang sudah ada, 
    atau penghapusan jika action == 'delete'.
    """
    body = await request.json()
    action = str(body.get("action", "")).lower()

    if action == "delete":
        aid = body.get("id") or body.get("ajuan_id") or body.get("ajuanId")
        if aid:
            safe_id = sanitize_supabase_param(aid)
            db.query(JadwalFinal).filter((JadwalFinal.id == aid) | (JadwalFinal.id == f"JDW_{aid}")).delete(synchronize_session=False)
            db.query(AjuanPengajaran).filter(AjuanPengajaran.id == aid).delete(synchronize_session=False)
            db.commit()
            delete_ajuan_from_supabase(safe_id)
            try:
                requests.delete(f"{SUPABASE_URL}/rest/v1/jadwal_final?or=(id.eq.{safe_id},id.eq.JDW_{safe_id})", headers=SB_HEADERS, timeout=5)
            except Exception:
                pass
            return {"status": "success", "message": "Ajuan pengajaran berhasil dihapus"}

    did = body.get("dosen_id") or body.get("dosenId")
    mk_id = body.get("mata_kuliah_id") or body.get("mataKuliahId")
    if not did or not mk_id:
        raise HTTPException(status_code=400, detail={"status": "error", "message": "Dosen dan Mata Kuliah wajib diisi."})

    aid = body.get("id") or body.get("ajuan_id") or body.get("ajuanId") or f"AJU_{secrets.token_hex(4).upper()}"
    existing = db.query(AjuanPengajaran).filter(AjuanPengajaran.id == aid).first()

    if existing:
        existing.dosen_id = did
        existing.dosen_nama = body.get("dosen_nama") or body.get("dosenNama") or existing.dosen_nama
        existing.fakultas_nama = body.get("fakultas_nama") or body.get("fakultasNama") or existing.fakultas_nama
        existing.jurusan_nama = body.get("jurusan_nama") or body.get("jurusanNama") or body.get("prodi") or existing.jurusan_nama
        existing.mata_kuliah_id = mk_id
        existing.mata_kuliah_nama = body.get("mata_kuliah_nama") or body.get("mataKuliahNama") or existing.mata_kuliah_nama
        existing.sks = int(body.get("sks", existing.sks))
        existing.semester = int(body.get("semester", existing.semester))
        existing.kelas_nama = body.get("kelas_nama") or body.get("kelasNama") or existing.kelas_nama
        existing.jumlah_mahasiswa = int(body.get("jumlah_mahasiswa") or body.get("jumlahMahasiswa") or existing.jumlah_mahasiswa)
        existing.gedung_nama = body.get("gedung_nama") or body.get("gedungNama") or existing.gedung_nama
        existing.ruangan_nama = body.get("ruangan_nama") or body.get("ruanganNama") or existing.ruangan_nama
        existing.hari = body.get("hari") or existing.hari
        existing.jam_mulai = body.get("jam_mulai") or body.get("jamMulai") or existing.jam_mulai
        existing.jam_selesai = body.get("jam_selesai") or body.get("jamSelesai") or existing.jam_selesai
        existing.status = body.get("status") or existing.status
        existing.catatan_dosen = body.get("catatan_dosen") or body.get("catatanDosen") or existing.catatan_dosen
        existing.catatan_kaprodi = body.get("catatan_kaprodi") or body.get("catatanKaprodi") or existing.catatan_kaprodi
        existing.catatan_dekan = body.get("catatan_dekan") or body.get("catatanDekan") or existing.catatan_dekan
        existing.catatan_admin = body.get("catatan_admin") or body.get("catatanAdmin") or existing.catatan_admin
        existing.alasan_penolakan = body.get("alasan_penolakan") or body.get("alasanPenolakan") or existing.alasan_penolakan
        existing.bentrok_detail = body.get("bentrok_detail") or body.get("bentrokDetail") or existing.bentrok_detail
        ajuan = existing
    else:
        ajuan = AjuanPengajaran(
            id=aid,
            dosen_id=did,
            dosen_nama=body.get("dosen_nama") or body.get("dosenNama", "Dosen Pengampu"),
            fakultas_nama=body.get("fakultas_nama") or body.get("fakultasNama", ""),
            jurusan_nama=body.get("jurusan_nama") or body.get("jurusanNama") or body.get("prodi", ""),
            mata_kuliah_id=mk_id,
            mata_kuliah_nama=body.get("mata_kuliah_nama") or body.get("mataKuliahNama", "Mata Kuliah"),
            sks=int(body.get("sks", 3)),
            semester=int(body.get("semester", 1)),
            kelas_nama=body.get("kelas_nama") or body.get("kelasNama", "TI-1A"),
            jumlah_mahasiswa=int(body.get("jumlah_mahasiswa") or body.get("jumlahMahasiswa", 35)),
            gedung_nama=body.get("gedung_nama") or body.get("gedungNama", "Gedung FST Terpadu"),
            ruangan_nama=body.get("ruangan_nama") or body.get("ruanganNama", "Ruang FST 101"),
            hari=body.get("hari", "Senin"),
            jam_mulai=body.get("jam_mulai") or body.get("jamMulai", "07:30"),
            jam_selesai=body.get("jam_selesai") or body.get("jamSelesai", "10:00"),
            status=body.get("status", "menunggu_kaprodi"),
            catatan_dosen=body.get("catatan_dosen") or body.get("catatanDosen", ""),
            catatan_kaprodi=body.get("catatan_kaprodi") or body.get("catatanKaprodi", ""),
            catatan_dekan=body.get("catatan_dekan") or body.get("catatanDekan", ""),
            catatan_admin=body.get("catatan_admin") or body.get("catatanAdmin", ""),
            alasan_penolakan=body.get("alasan_penolakan") or body.get("alasanPenolakan", ""),
            bentrok_detail=body.get("bentrok_detail") or body.get("bentrokDetail", "")
        )
        db.add(ajuan)

    db.commit()
    sync_ajuan_to_supabase(ajuan)
    return {"status": "success", "message": "Ajuan pengajaran berhasil disimpan.", "data": format_ajuan(ajuan)}

@router.put("")
@router.put("/")
@router.put("/index.php")
async def update_ajuan_endpoint(request: Request, db: Session = Depends(get_db)):
    """
    [PRESENTASI] Update Ajuan Pengajaran
    """
    return await submit_or_create_ajuan(request, db)

# ─── VERIFIKASI MULTI-TIER (KAPRODI, DEKAN, ADMIN) ─────────────────────
@router.post("/verify")
@router.post("/verify.php")
async def verify_ajuan_endpoint(request: Request, db: Session = Depends(get_db)):
    """
    [PRESENTASI] Sistem Verifikasi Berjenjang (Workflow Approval):
    Mengatur alur persetujuan jadwal:
    1. Kaprodi: Menyetujui/Menolak dari segi substansi akademik.
    2. Dekan: Persetujuan akhir dari fakultas.
    3. Admin/RCK: Verifikasi final, eksekusi masuk ke 'Jadwal Final', atau resolve manual saat ada bentrok.
    """
    body = await request.json()
    action = (body.get("action") or "").strip().lower()
    aid = body.get("id") or body.get("ajuan_id") or body.get("ajuanId")

    if not action or not aid:
        raise HTTPException(status_code=400, detail={"status": "error", "message": "Parameter action dan ajuan_id wajib diisi."})

    ajuan = db.query(AjuanPengajaran).filter(AjuanPengajaran.id == aid).first()
    if not ajuan:
        raise HTTPException(status_code=404, detail={"status": "error", "message": f"Ajuan tidak ditemukan dengan ID: {aid}"})

    catatan = body.get("catatan") or body.get("catatan_kaprodi") or body.get("catatan_dekan") or body.get("catatan_admin") or ""
    alasan = body.get("alasan") or body.get("alasanPenolakan") or body.get("alasan_penolakan") or ""
    updated_data = body.get("updatedData") or body.get("updated_data")

    if updated_data:
        ajuan.ruangan_nama = updated_data.get("ruanganNama") or updated_data.get("ruangan_nama") or ajuan.ruangan_nama
        ajuan.gedung_nama = updated_data.get("gedungNama") or updated_data.get("gedung_nama") or ajuan.gedung_nama
        ajuan.hari = updated_data.get("hari") or ajuan.hari
        ajuan.jam_mulai = updated_data.get("jamMulai") or updated_data.get("jam_mulai") or ajuan.jam_mulai
        ajuan.jam_selesai = updated_data.get("jamSelesai") or updated_data.get("jam_selesai") or ajuan.jam_selesai

    if action in ["verify_kaprodi", "kaprodi_verify"]:
        # [PRESENTASI] Tahap 1: Disetujui Kaprodi, lanjut ke Dekan
        ajuan.status = "menunggu_dekan"
        ajuan.bentrok_detail = None
        if catatan:
            ajuan.catatan_kaprodi = catatan
        db.commit()
        sync_ajuan_to_supabase(ajuan)
        return {"status": "success", "message": "Ajuan berhasil diverifikasi oleh KaProdi.", "data": format_ajuan(ajuan)}

    elif action in ["approve_dekan", "dekan_approve"]:
        # [PRESENTASI] Tahap 2: Disetujui Dekan, siap direview Admin / Masuk CSP Engine
        ajuan.status = "menunggu_admin"
        ajuan.bentrok_detail = None
        if catatan:
            ajuan.catatan_dekan = catatan
        db.commit()
        sync_ajuan_to_supabase(ajuan)
        return {"status": "success", "message": "Ajuan disetujui Dekan dan diteruskan ke Admin.", "data": format_ajuan(ajuan)}

    elif action in ["reject_kaprodi", "kaprodi_reject", "reject_dekan", "dekan_reject", "admin_reject", "reject_admin", "reject"]:
        if "kaprodi" in action:
            ajuan.status = "ditolak_kaprodi"
        elif "dekan" in action:
            ajuan.status = "ditolak_dekan"
        elif "admin" in action:
            ajuan.status = "ditolak_admin"
        else:
            ajuan.status = "ditolak"
        if alasan:
            ajuan.alasan_penolakan = alasan
        db.commit()
        sync_ajuan_to_supabase(ajuan)
        return {"status": "success", "message": "Ajuan telah ditolak.", "data": format_ajuan(ajuan)}

    elif action in ["admin_approve", "admin_final_approve", "admin_resolve", "resolve", "batch_resolve"]:
        # [PRESENTASI] Tahap Akhir: Disetujui Admin
        # Memindahkan status ajuan menjadi "disetujui_admin" dan menyalin datanya ke tabel 'JadwalFinal'
        ajuan.status = "disetujui_admin"
        ajuan.bentrok_detail = None
        if catatan:
            ajuan.catatan_admin = catatan
        
        j_id = f"JDW_{ajuan.id}"
        exist_j = db.query(JadwalFinal).filter((JadwalFinal.id == j_id) | ((JadwalFinal.mata_kuliah_nama == ajuan.mata_kuliah_nama) & (JadwalFinal.kelas_nama == ajuan.kelas_nama))).first()
        if exist_j:
            exist_j.mata_kuliah_id = ajuan.mata_kuliah_id
            exist_j.mata_kuliah_nama = ajuan.mata_kuliah_nama
            exist_j.sks = ajuan.sks
            exist_j.ruangan_nama = ajuan.ruangan_nama
            exist_j.gedung_nama = ajuan.gedung_nama
            exist_j.kelas_nama = ajuan.kelas_nama
            exist_j.hari = ajuan.hari
            exist_j.jam_mulai = ajuan.jam_mulai
            exist_j.jam_selesai = ajuan.jam_selesai
            exist_j.dosen_id = ajuan.dosen_id
            exist_j.dosen_nama = ajuan.dosen_nama
            exist_j.fakultas_nama = ajuan.fakultas_nama
            exist_j.jurusan_nama = ajuan.jurusan_nama
            exist_j.jumlah_mahasiswa = ajuan.jumlah_mahasiswa
            jadwal = exist_j
        else:
            jadwal = JadwalFinal(
                id=j_id,
                mata_kuliah_id=ajuan.mata_kuliah_id,
                mata_kuliah_nama=ajuan.mata_kuliah_nama,
                sks=ajuan.sks,
                ruangan_nama=ajuan.ruangan_nama,
                gedung_nama=ajuan.gedung_nama,
                kelas_nama=ajuan.kelas_nama,
                hari=ajuan.hari,
                jam_mulai=ajuan.jam_mulai,
                jam_selesai=ajuan.jam_selesai,
                dosen_id=ajuan.dosen_id,
                dosen_nama=ajuan.dosen_nama,
                fakultas_nama=ajuan.fakultas_nama,
                jurusan_nama=ajuan.jurusan_nama,
                jumlah_mahasiswa=ajuan.jumlah_mahasiswa
            )
            db.add(jadwal)
        db.commit()
        sync_ajuan_to_supabase(ajuan)
        sync_jadwal_to_supabase(jadwal)
        return {"status": "success", "message": "Ajuan berhasil disetujui Admin dan dicatat ke Jadwal Final.", "data": format_ajuan(ajuan)}

    db.commit()
    sync_ajuan_to_supabase(ajuan)
    return {"status": "success", "data": format_ajuan(ajuan)}

# ─── BANDING JADWAL ───────────────────────────────────────────────────
@router.post("/banding")
@router.post("/banding.php")
async def handle_banding(request: Request, db: Session = Depends(get_db)):
    """
    [PRESENTASI] Fitur Banding / Rescheduling:
    Jika jadwal dari CSP Engine atau Admin dirasa kurang cocok, dosen dapat
    mengajukan banding jadwal baru (preferensi_banding_hari/jam) yang akan diproses oleh Admin.
    """
    body = await request.json()
    action = body.get("action", "submit")
    aid = body.get("ajuan_id") or body.get("ajuanId") or body.get("id")

    if not aid:
        raise HTTPException(status_code=400, detail={"status": "error", "message": "Parameter ajuan_id wajib diisi."})

    ajuan = db.query(AjuanPengajaran).filter(AjuanPengajaran.id == aid).first()
    if not ajuan:
        raise HTTPException(status_code=404, detail={"status": "error", "message": "Ajuan tidak ditemukan."})

    if action in ["submit", "submit_banding"]:
        ajuan.status = "menunggu_banding"
        ajuan.alasan_banding = body.get("alasan") or body.get("alasan_banding") or body.get("alasanBanding", "")
        ajuan.preferensi_banding_hari = body.get("preferensi_hari") or body.get("preferensi_banding_hari") or body.get("preferensiHari", ajuan.hari)
        ajuan.preferensi_banding_jam = body.get("preferensi_jam") or body.get("preferensi_banding_jam") or body.get("preferensiJam", ajuan.jam_mulai)
        db.commit()
        sync_ajuan_to_supabase(ajuan)
        return {"status": "success", "message": "Permohonan banding jadwal berhasil diajukan ke Admin.", "data": format_ajuan(ajuan)}

    elif action in ["process", "accept", "admin_process_banding"]:
        approve = body.get("approve", True)
        if approve:
            ajuan.status = "banding_disetujui"
            catatan = body.get("catatan_admin") or body.get("catatanAdmin") or "Disetujui & Disesuaikan otomatis oleh RCK sesuai permohonan banding dosen."
            ajuan.catatan_admin = catatan
            ajuan.bentrok_detail = None
            updated_data = body.get("updated_data") or body.get("updatedData")
            if updated_data:
                ajuan.ruangan_nama = updated_data.get("ruangan_nama") or updated_data.get("ruanganNama") or ajuan.ruangan_nama
                ajuan.gedung_nama = updated_data.get("gedung_nama") or updated_data.get("gedungNama") or ajuan.gedung_nama
                ajuan.hari = updated_data.get("hari") or ajuan.hari
                ajuan.jam_mulai = updated_data.get("jam_mulai") or updated_data.get("jamMulai") or ajuan.jam_mulai
                ajuan.jam_selesai = updated_data.get("jam_selesai") or updated_data.get("jamSelesai") or ajuan.jam_selesai
            elif body.get("ruangan_nama"):
                ajuan.ruangan_nama = body["ruangan_nama"]
                if body.get("gedung_nama"): ajuan.gedung_nama = body["gedung_nama"]
                if body.get("hari"): ajuan.hari = body["hari"]
                if body.get("jam_mulai"): ajuan.jam_mulai = body["jam_mulai"]
                if body.get("jam_selesai"): ajuan.jam_selesai = body["jam_selesai"]

            j_id = f"JDW_{ajuan.id}"
            exist_j = db.query(JadwalFinal).filter((JadwalFinal.id == j_id) | ((JadwalFinal.mata_kuliah_nama == ajuan.mata_kuliah_nama) & (JadwalFinal.kelas_nama == ajuan.kelas_nama))).first()
            if exist_j:
                exist_j.mata_kuliah_id = ajuan.mata_kuliah_id
                exist_j.mata_kuliah_nama = ajuan.mata_kuliah_nama
                exist_j.sks = ajuan.sks
                exist_j.ruangan_nama = ajuan.ruangan_nama
                exist_j.gedung_nama = ajuan.gedung_nama
                exist_j.kelas_nama = ajuan.kelas_nama
                exist_j.hari = ajuan.hari
                exist_j.jam_mulai = ajuan.jam_mulai
                exist_j.jam_selesai = ajuan.jam_selesai
                exist_j.dosen_id = ajuan.dosen_id
                exist_j.dosen_nama = ajuan.dosen_nama
                exist_j.fakultas_nama = ajuan.fakultas_nama
                exist_j.jurusan_nama = ajuan.jurusan_nama
                exist_j.jumlah_mahasiswa = ajuan.jumlah_mahasiswa
                jadwal = exist_j
            else:
                jadwal = JadwalFinal(
                    id=j_id,
                    mata_kuliah_id=ajuan.mata_kuliah_id,
                    mata_kuliah_nama=ajuan.mata_kuliah_nama,
                    sks=ajuan.sks,
                    ruangan_nama=ajuan.ruangan_nama,
                    gedung_nama=ajuan.gedung_nama,
                    kelas_nama=ajuan.kelas_nama,
                    hari=ajuan.hari,
                    jam_mulai=ajuan.jam_mulai,
                    jam_selesai=ajuan.jam_selesai,
                    dosen_id=ajuan.dosen_id,
                    dosen_nama=ajuan.dosen_nama,
                    fakultas_nama=ajuan.fakultas_nama,
                    jurusan_nama=ajuan.jurusan_nama,
                    jumlah_mahasiswa=ajuan.jumlah_mahasiswa
                )
                db.add(jadwal)
            db.commit()
            sync_ajuan_to_supabase(ajuan)
            sync_jadwal_to_supabase(jadwal)
            return {"status": "success", "message": "Banding disetujui Admin dan jadwal diperbarui.", "data": format_ajuan(ajuan)}
        else:
            ajuan.status = "banding_ditolak"
            ajuan.alasan_penolakan = body.get("alasan_penolakan") or body.get("alasanPenolakan") or body.get("catatanAdmin") or "Banding ditolak oleh Admin"
            db.commit()
            sync_ajuan_to_supabase(ajuan)
            return {"status": "success", "message": "Banding ditolak oleh Admin.", "data": format_ajuan(ajuan)}

    elif action in ["reject", "reject_banding"]:
        ajuan.status = "banding_ditolak"
        ajuan.alasan_penolakan = body.get("alasan_penolakan") or body.get("alasanPenolakan") or "Banding ditolak oleh Admin"
        db.commit()
        sync_ajuan_to_supabase(ajuan)
        return {"status": "success", "message": "Banding ditolak oleh Admin.", "data": format_ajuan(ajuan)}

    db.commit()
    sync_ajuan_to_supabase(ajuan)
    return {"status": "success", "data": format_ajuan(ajuan)}

@router.delete("")
@router.delete("/")
@router.delete("/index.php")
async def delete_ajuan_endpoint(
    request: Request,
    id: Optional[str] = Query(None),
    db: Session = Depends(get_db)
):
    ids_to_delete = []
    if id:
        ids_to_delete.append(id)
    
    try:
        body = await request.json()
        if isinstance(body, dict):
            if "id" in body and body["id"]:
                ids_to_delete.append(str(body["id"]))
            if "ids" in body and isinstance(body["ids"], list):
                ids_to_delete.extend([str(x) for x in body["ids"] if x])
    except Exception:
        pass

    ids_to_delete = list(set(ids_to_delete))
    if not ids_to_delete:
        return {"status": "success", "message": "Tidak ada ID ajuan yang dihapus"}

    for aid in ids_to_delete:
        safe_id = sanitize_supabase_param(aid)
        # Delete from local SQLite
        db.query(JadwalFinal).filter((JadwalFinal.id == aid) | (JadwalFinal.id == f"JDW_{aid}")).delete(synchronize_session=False)
        db.query(AjuanPengajaran).filter(AjuanPengajaran.id == aid).delete(synchronize_session=False)
        
        # Delete from Supabase
        delete_ajuan_from_supabase(safe_id)
        try:
            requests.delete(
                f"{SUPABASE_URL}/rest/v1/jadwal_final?or=(id.eq.{safe_id},id.eq.JDW_{safe_id})",
                headers=SB_HEADERS,
                timeout=5
            )
        except Exception:
            pass

    db.commit()
    return {
        "status": "success",
        "message": f"Berhasil menghapus {len(ids_to_delete)} ajuan pengajaran permanen",
        "deleted_ids": ids_to_delete
    }


