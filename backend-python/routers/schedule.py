from fastapi import APIRouter, Depends, HTTPException, Query, Request
from sqlalchemy.orm import Session
from typing import Optional
from core.database import get_db
from models.models import JadwalFinal, AjuanPengajaran
import secrets

router = APIRouter(prefix="/schedule", tags=["Schedule"])

def format_jadwal(j: JadwalFinal):
    return {
        "id": j.id,
        "mataKuliahId": j.mata_kuliah_id,
        "mata_kuliah_id": j.mata_kuliah_id,
        "mataKuliahNama": j.mata_kuliah_nama,
        "mata_kuliah_nama": j.mata_kuliah_nama,
        "sks": j.sks,
        "ruanganNama": j.ruangan_nama,
        "ruangan_nama": j.ruangan_nama,
        "gedungNama": j.gedung_nama,
        "gedung_nama": j.gedung_nama,
        "kelasNama": j.kelas_nama,
        "kelas_nama": j.kelas_nama,
        "hari": j.hari,
        "jamMulai": j.jam_mulai,
        "jam_mulai": j.jam_mulai,
        "jamSelesai": j.jam_selesai,
        "jam_selesai": j.jam_selesai,
        "dosenId": j.dosen_id,
        "dosen_id": j.dosen_id,
        "dosenNama": j.dosen_nama,
        "dosen_nama": j.dosen_nama,
        "fakultasNama": j.fakultas_nama,
        "fakultas_nama": j.fakultas_nama,
        "jurusanNama": j.jurusan_nama,
        "jurusan_nama": j.jurusan_nama,
        "prodi": j.jurusan_nama,
        "semesterNama": j.semester_nama,
        "semester_nama": j.semester_nama,
        "jumlahMahasiswa": j.jumlah_mahasiswa,
        "jumlah_mahasiswa": j.jumlah_mahasiswa,
        "status": "disetujui_admin",
        "createdAt": str(j.created_at),
        "created_at": str(j.created_at)
    }

def format_ajuan_as_jadwal(a: AjuanPengajaran):
    return {
        "id": a.id,
        "mataKuliahId": a.mata_kuliah_id,
        "mata_kuliah_id": a.mata_kuliah_id,
        "mataKuliahNama": a.mata_kuliah_nama,
        "mata_kuliah_nama": a.mata_kuliah_nama,
        "sks": a.sks,
        "ruanganNama": a.ruangan_nama,
        "ruangan_nama": a.ruangan_nama,
        "gedungNama": a.gedung_nama,
        "gedung_nama": a.gedung_nama,
        "kelasNama": a.kelas_nama,
        "kelas_nama": a.kelas_nama,
        "hari": a.hari,
        "jamMulai": a.jam_mulai,
        "jam_mulai": a.jam_mulai,
        "jamSelesai": a.jam_selesai,
        "jam_selesai": a.jam_selesai,
        "dosenId": a.dosen_id,
        "dosen_id": a.dosen_id,
        "dosenNama": a.dosen_nama,
        "dosen_nama": a.dosen_nama,
        "fakultasNama": a.fakultas_nama,
        "fakultas_nama": a.fakultas_nama,
        "jurusanNama": a.jurusan_nama,
        "jurusan_nama": a.jurusan_nama,
        "prodi": a.jurusan_nama,
        "semesterNama": f"Semester {a.semester}",
        "semester_nama": f"Semester {a.semester}",
        "jumlahMahasiswa": a.jumlah_mahasiswa,
        "jumlah_mahasiswa": a.jumlah_mahasiswa,
        "status": a.status,
        "createdAt": str(a.created_at),
        "created_at": str(a.created_at)
    }

@router.get("")
@router.get("/")
@router.get("/index.php")
def get_schedules(
    dosenId: Optional[str] = None,
    dosen_id: Optional[str] = None,
    ruangan: Optional[str] = None,
    hari: Optional[str] = None,
    jurusan: Optional[str] = None,
    prodi: Optional[str] = None,
    fakultas: Optional[str] = None,
    db: Session = Depends(get_db)
):
    did = dosenId or dosen_id
    jur = jurusan or prodi

    # 1. Fetch official final schedules
    q = db.query(JadwalFinal)
    if did and did != "GLOBAL":
        q = q.filter((JadwalFinal.dosen_id == did) | (JadwalFinal.dosen_nama.ilike(f"%{did}%")))
    if ruangan and ruangan != "Semua":
        q = q.filter(JadwalFinal.ruangan_nama == ruangan)
    if hari and hari != "Semua":
        q = q.filter(JadwalFinal.hari == hari)
    if jur and jur != "Semua":
        q = q.filter(JadwalFinal.jurusan_nama.ilike(f"%{jur}%"))
    if fakultas and fakultas != "Semua":
        q = q.filter(JadwalFinal.fakultas_nama.ilike(f"%{fakultas}%"))

    items_final = q.all()
    existing_ids = {j.id for j in items_final}
    data = [format_jadwal(j) for j in items_final]

    # 2. Merge active proposals from ajuan_pengajaran not already in JadwalFinal
    q_a = db.query(AjuanPengajaran)
    if did and did != "GLOBAL":
        q_a = q_a.filter((AjuanPengajaran.dosen_id == did) | (AjuanPengajaran.dosen_nama.ilike(f"%{did}%")))
    if ruangan and ruangan != "Semua":
        q_a = q_a.filter(AjuanPengajaran.ruangan_nama == ruangan)
    if hari and hari != "Semua":
        q_a = q_a.filter(AjuanPengajaran.hari == hari)
    if jur and jur != "Semua":
        q_a = q_a.filter(AjuanPengajaran.jurusan_nama.ilike(f"%{jur}%"))
    if fakultas and fakultas != "Semua":
        q_a = q_a.filter(AjuanPengajaran.fakultas_nama.ilike(f"%{fakultas}%"))

    items_ajuan = q_a.all()
    for a in items_ajuan:
        if a.id not in existing_ids:
            data.append(format_ajuan_as_jadwal(a))

    return {"status": "success", "data": data}

@router.post("")
@router.post("/")
@router.post("/index.php")
async def create_schedule(request: Request, db: Session = Depends(get_db)):
    body = await request.json()
    action = str(body.get("action", "")).lower()
    jid = body.get("id") or body.get("schedule_id")

    if action == "delete" and jid:
        jadwal = db.query(JadwalFinal).filter(JadwalFinal.id == jid).first()
        if jadwal:
            db.delete(jadwal)
            db.commit()
        return {"status": "success", "message": "Jadwal berhasil dihapus"}

    jid = jid or f"SCH_{secrets.token_hex(4).upper()}"
    jadwal = JadwalFinal(
        id=jid,
        mata_kuliah_id=body.get("mata_kuliah_id") or body.get("mataKuliahId", ""),
        mata_kuliah_nama=body.get("mata_kuliah_nama") or body.get("mataKuliahNama", ""),
        sks=int(body.get("sks", 3)),
        ruangan_nama=body.get("ruangan_nama") or body.get("ruanganNama", ""),
        gedung_nama=body.get("gedung_nama") or body.get("gedungNama", ""),
        kelas_nama=body.get("kelas_nama") or body.get("kelasNama", ""),
        hari=body.get("hari", "Senin"),
        jam_mulai=body.get("jam_mulai") or body.get("jamMulai", "07:30"),
        jam_selesai=body.get("jam_selesai") or body.get("jamSelesai", "10:00"),
        dosen_id=body.get("dosen_id") or body.get("dosenId"),
        dosen_nama=body.get("dosen_nama") or body.get("dosenNama"),
        fakultas_nama=body.get("fakultas_nama") or body.get("fakultasNama", "Fakultas Sains & Teknologi"),
        jurusan_nama=body.get("jurusan_nama") or body.get("jurusanNama") or body.get("prodi", "Teknik Informatika"),
        jumlah_mahasiswa=int(body.get("jumlah_mahasiswa") or body.get("jumlahMahasiswa", 35))
    )
    db.add(jadwal)
    db.commit()
    return {"status": "success", "message": "Jadwal berhasil ditambahkan", "data": format_jadwal(jadwal)}

@router.delete("")
@router.delete("/")
@router.delete("/index.php")
def delete_schedule(id: str = Query(...), db: Session = Depends(get_db)):
    jadwal = db.query(JadwalFinal).filter(JadwalFinal.id == id).first()
    if jadwal:
        db.delete(jadwal)
        db.commit()
    return {"status": "success", "message": "Jadwal berhasil dihapus"}
