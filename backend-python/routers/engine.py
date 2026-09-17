from fastapi import APIRouter, Depends, HTTPException, Request
from sqlalchemy.orm import Session
from typing import List, Dict, Any, Optional
from core.database import get_db
from models.models import (
    AjuanPengajaran, JadwalFinal, MataKuliah, MataKuliahKelas,
    Ruangan, Gedung, SlotWaktu, User, Availability, AvailabilitySlot
)
import secrets

router = APIRouter(prefix="/engine", tags=["Scheduling Engine"])

def parse_time(t_str: str) -> int:
    parts = t_str.strip().split(":")
    return int(parts[0]) * 60 + int(parts[1]) if len(parts) >= 2 else 0

def is_overlap(start1: int, end1: int, start2: int, end2: int) -> bool:
    return max(start1, start2) < min(end1, end2)

def is_travel_buffer_violated(start1: int, end1: int, g1: str, start2: int, end2: int, g2: str, min_buffer: int = 15) -> bool:
    if g1 and g2 and g1.strip().lower() == g2.strip().lower():
        return False
    # If starting after end of first class
    if start2 >= end1 and (start2 - end1) < min_buffer:
        return True
    # If starting before start of second class
    if start1 >= end2 and (start1 - end2) < min_buffer:
        return True
    return False

@router.post("/csp")
@router.post("/csp.php")
async def run_csp_engine(request: Request, db: Session = Depends(get_db)):
    body = await request.json()
    scope = body.get("scope", "global")
    jurusan_nama = body.get("jurusan_nama") or body.get("jurusan")
    fakultas_nama = body.get("fakultas_nama") or body.get("fakultas")

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
    q_ajuan = db.query(AjuanPengajaran).filter(
        AjuanPengajaran.status.in_(["diverifikasi_kaprodi", "menunggu_kaprodi", "disetujui_dekan"])
    )
    if scope == "jurusan" and jurusan_nama:
        q_ajuan = q_ajuan.filter(AjuanPengajaran.jurusan_nama.ilike(f"%{jurusan_nama}%"))
    elif scope == "fakultas" and fakultas_nama:
        q_ajuan = q_ajuan.filter(AjuanPengajaran.fakultas_nama.ilike(f"%{fakultas_nama}%"))

    tasks = q_ajuan.all()

    # Backtracking CSP Solver
    placed_schedules = []
    failed_tasks = []

    # Sort tasks by MRV (Priority lecturers first, then higher SKS & number of students)
    tasks_sorted = sorted(
        tasks,
        key=lambda x: (
            0 if (x.dosen and getattr(x.dosen, "is_priority", False)) else 1,
            -x.sks,
            -x.jumlah_mahasiswa
        )
    )

    for task in tasks_sorted:
        assigned = False
        req_type = getattr(task, "kebutuhan_tipe_ruangan", None) or "Kelas Teori"

        # Filter candidate rooms by capacity and room type
        candidate_rooms = [
            r for r in ruangan_list
            if r.kapasitas >= task.jumlah_mahasiswa
            and (req_type in ["Semua", "Kosong (Ready)", None] or r.tipe_ruangan == req_type or r.tipe_ruangan == "Kelas Teori")
        ]

        # Get lecturer preferred slot IDs if available
        pref_slot_ids = dosen_avail_map.get(task.dosen_id, set())

        # Order slots: lecturer preferred slots first, then other slots
        sorted_slots = sorted(
            slot_list,
            key=lambda s: 0 if s.id in pref_slot_ids else 1
        )

        for room in candidate_rooms:
            gedung = gedung_map.get(room.gedung_id)
            g_buka = parse_time(gedung.jam_buka) if gedung else parse_time("07:00")
            g_tutup = parse_time(gedung.jam_tutup) if gedung else parse_time("18:30")
            gedung_nama = gedung.nama if gedung else task.gedung_nama or "Gedung Utama"

            for slot in sorted_slots:
                s_start = parse_time(slot.jam_mulai)
                s_end = parse_time(slot.jam_selesai)

                # 1. Building Hours Constraint
                if s_start < g_buka or s_end > g_tutup:
                    continue

                # 2. Hard Constraints Check
                conflict = False
                for sched in placed_schedules:
                    if sched["hari"] != slot.hari:
                        continue

                    # A. Time Overlap check
                    if is_overlap(s_start, s_end, sched["start_min"], sched["end_min"]):
                        # Room conflict
                        if sched["ruangan_nama"] == room.nama:
                            conflict = True
                            break
                        # Lecturer conflict
                        if sched["dosen_id"] == task.dosen_id:
                            conflict = True
                            break
                        # Class group conflict (e.g. TI-1A)
                        if sched["kelas_nama"] == task.kelas_nama:
                            conflict = True
                            break

                    # B. Travel Buffer check (15-min gap between different buildings)
                    if sched["dosen_id"] == task.dosen_id or sched["kelas_nama"] == task.kelas_nama:
                        if is_travel_buffer_violated(s_start, s_end, gedung_nama, sched["start_min"], sched["end_min"], sched["gedung_nama"]):
                            conflict = True
                            break

                if not conflict:
                    placed_schedules.append({
                        "id": f"SCH_{secrets.token_hex(4).upper()}",
                        "mata_kuliah_id": task.mata_kuliah_id,
                        "mata_kuliah_nama": task.mata_kuliah_nama,
                        "sks": task.sks,
                        "ruangan_nama": room.nama,
                        "gedung_nama": gedung_nama,
                        "kelas_nama": task.kelas_nama,
                        "hari": slot.hari,
                        "jam_mulai": slot.jam_mulai,
                        "jam_selesai": slot.jam_selesai,
                        "dosen_id": task.dosen_id,
                        "dosen_nama": task.dosen_nama,
                        "fakultas_nama": task.fakultas_nama,
                        "jurusan_nama": task.jurusan_nama,
                        "jumlah_mahasiswa": task.jumlah_mahasiswa,
                        "start_min": s_start,
                        "end_min": s_end
                    })
                    assigned = True
                    break
            if assigned:
                break

        if not assigned:
            failed_tasks.append({
                "mata_kuliah_nama": task.mata_kuliah_nama,
                "dosen_nama": task.dosen_nama,
                "alasan": "Tidak ditemukan kombinasi ruangan dan slot waktu yang bebas bentrok."
            })

    # Save to database if apply_to_db requested
    if body.get("apply_to_db", True):
        if scope == "global":
            db.query(JadwalFinal).delete()
        elif scope == "fakultas" and fakultas_nama:
            db.query(JadwalFinal).filter(JadwalFinal.fakultas_nama.ilike(f"%{fakultas_nama}%")).delete()
        elif scope == "jurusan" and jurusan_nama:
            db.query(JadwalFinal).filter(JadwalFinal.jurusan_nama.ilike(f"%{jurusan_nama}%")).delete()

        for s in placed_schedules:
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
        db.commit()

    return {
        "status": "success",
        "message": f"Berhasil men-generate {len(placed_schedules)} jadwal otomatis tanpa bentrok (CSP Solver).",
        "total_generated": len(placed_schedules),
        "total_unresolved": len(failed_tasks),
        "unresolved_details": failed_tasks,
        "data": placed_schedules
    }
