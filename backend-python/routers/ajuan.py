from fastapi import APIRouter, Depends, HTTPException, Query, Request
from sqlalchemy.orm import Session
from typing import Optional
from datetime import datetime
from core.database import get_db
from models.models import AjuanPengajaran, User, JadwalFinal
import secrets

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
    return {"status": "success", "data": [format_ajuan(a) for a in items]}

@router.post("/submit")
@router.post("/submit.php")
async def submit_ajuan(request: Request, db: Session = Depends(get_db)):
    body = await request.json()
    did = body.get("dosen_id") or body.get("dosenId")
    mk_id = body.get("mata_kuliah_id") or body.get("mataKuliahId")
    if not did or not mk_id:
        raise HTTPException(status_code=400, detail={"status": "error", "message": "Dosen dan Mata Kuliah wajib diisi."})

    aid = f"AJU_{secrets.token_hex(4).upper()}"
    ajuan = AjuanPengajaran(
        id=aid,
        dosen_id=did,
        dosen_nama=body.get("dosen_nama") or body.get("dosenNama", "Dosen Pengampu"),
        fakultas_nama=body.get("fakultas_nama") or body.get("fakultasNama", "Fakultas Sains & Teknologi"),
        jurusan_nama=body.get("jurusan_nama") or body.get("jurusanNama") or body.get("prodi", "Teknik Informatika"),
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
        status="menunggu_kaprodi",
        catatan_dosen=body.get("catatan_dosen") or body.get("catatanDosen", "")
    )
    db.add(ajuan)
    db.commit()
    return {"status": "success", "message": "Ajuan pengajaran berhasil dikirim ke KaProdi.", "data": format_ajuan(ajuan)}

# ─── VERIFIKASI MULTI-TIER (KAPRODI, DEKAN, ADMIN) ─────────────────────
@router.post("/verify")
@router.post("/verify.php")
async def verify_ajuan_endpoint(request: Request, db: Session = Depends(get_db)):
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
        ajuan.status = "diverifikasi_kaprodi"
        if catatan:
            ajuan.catatan_kaprodi = catatan
        db.commit()
        return {"status": "success", "message": "Ajuan berhasil diverifikasi oleh KaProdi.", "data": format_ajuan(ajuan)}

    elif action in ["approve_dekan", "dekan_approve"]:
        ajuan.status = "disetujui_dekan"
        if catatan:
            ajuan.catatan_dekan = catatan
        
        # Insert into Jadwal Final
        jadwal = JadwalFinal(
            id=f"SCH_{secrets.token_hex(4).upper()}",
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
        return {"status": "success", "message": "Ajuan disetujui Dekan dan dimasukkan ke Jadwal Final.", "data": format_ajuan(ajuan)}

    elif action in ["reject_kaprodi", "reject_dekan", "reject"]:
        ajuan.status = "ditolak"
        if alasan:
            ajuan.alasan_penolakan = alasan
        db.commit()
        return {"status": "success", "message": "Ajuan telah ditolak.", "data": format_ajuan(ajuan)}

    elif action in ["admin_resolve", "resolve"]:
        ajuan.status = "disetujui_dekan"
        if catatan:
            ajuan.catatan_admin = catatan
        jadwal = JadwalFinal(
            id=f"SCH_{secrets.token_hex(4).upper()}",
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
        return {"status": "success", "message": "Ajuan berhasil diselesaikan oleh Admin.", "data": format_ajuan(ajuan)}

    db.commit()
    return {"status": "success", "data": format_ajuan(ajuan)}

# ─── BANDING JADWAL ───────────────────────────────────────────────────
@router.post("/banding")
@router.post("/banding.php")
async def handle_banding(request: Request, db: Session = Depends(get_db)):
    body = await request.json()
    action = body.get("action", "submit")
    aid = body.get("ajuan_id") or body.get("ajuanId") or body.get("id")

    if not aid:
        raise HTTPException(status_code=400, detail={"status": "error", "message": "Parameter ajuan_id wajib diisi."})

    ajuan = db.query(AjuanPengajaran).filter(AjuanPengajaran.id == aid).first()
    if not ajuan:
        raise HTTPException(status_code=404, detail={"status": "error", "message": "Ajuan tidak ditemukan."})

    if action == "submit":
        ajuan.status = "mengajukan_banding"
        ajuan.alasan_banding = body.get("alasan") or body.get("alasan_banding", "")
        ajuan.preferensi_banding_hari = body.get("preferensi_hari") or body.get("preferensi_banding_hari", ajuan.hari)
        ajuan.preferensi_banding_jam = body.get("preferensi_jam") or body.get("preferensi_banding_jam", ajuan.jam_mulai)
        db.commit()
        return {"status": "success", "message": "Permohonan banding jadwal berhasil diajukan ke Admin.", "data": format_ajuan(ajuan)}

    elif action in ["process", "accept"]:
        ajuan.status = "disetujui_dekan"
        if body.get("ruangan_nama"):
            ajuan.ruangan_nama = body["ruangan_nama"]
        if body.get("hari"):
            ajuan.hari = body["hari"]
        if body.get("jam_mulai"):
            ajuan.jam_mulai = body["jam_mulai"]
        if body.get("jam_selesai"):
            ajuan.jam_selesai = body["jam_selesai"]
        db.commit()
        return {"status": "success", "message": "Banding disetujui Admin dan jadwal diperbarui.", "data": format_ajuan(ajuan)}

    elif action in ["reject", "reject_banding"]:
        ajuan.status = "ditolak"
        ajuan.alasan_penolakan = body.get("alasan_penolakan", "Banding ditolak oleh Admin")
        db.commit()
        return {"status": "success", "message": "Banding ditolak oleh Admin.", "data": format_ajuan(ajuan)}

    db.commit()
    return {"status": "success", "data": format_ajuan(ajuan)}
