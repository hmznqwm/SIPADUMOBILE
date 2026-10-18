import os
import random
import uuid
from sqlalchemy.orm import Session
from core.database import SessionLocal, engine, Base
from models.models import AjuanPengajaran, Ruangan, SlotWaktu

# Use local benchmark db to ensure we don't pollute anything
os.environ["DATABASE_URL"] = "sqlite:///benchmark.db"
Base.metadata.create_all(bind=engine)
db = SessionLocal()

print("Generating 63 Ruangan...")
db.query(Ruangan).delete()
ruangans = []
for i in range(1, 64):
    ruangans.append(Ruangan(
        id=f"R{i:03d}",
        nama=f"Ruang {i}",
        gedung_id="G01",
        lantai="1",
        kapasitas=random.choice([30, 40, 50, 60]),
        tipe_ruangan="Kelas Teori",
        status="aktif"
    ))
db.add_all(ruangans)

print("Generating 34 Slot Waktu...")
db.query(SlotWaktu).delete()
slots = []
hari_list = ["Senin", "Selasa", "Rabu", "Kamis", "Jumat"]
jam_list = ["07:30", "09:10", "10:50", "13:00", "14:40", "16:20", "18:30"]
count = 1
for h in hari_list:
    for j in jam_list:
        if count > 34:
            break
        # Calculate jam_selesai (+100 mins for 2 SKS)
        h_start, m_start = map(int, j.split(':'))
        total_m = h_start * 60 + m_start + 100
        j_selesai = f"{total_m // 60:02d}:{total_m % 60:02d}"
        slots.append(SlotWaktu(
            id=f"SLOT_{count}",
            hari=h,
            jam_mulai=j,
            jam_selesai=j_selesai,
            durasi_menit=100
        ))
        count += 1
db.add_all(slots)

print("Generating 4,685 Ajuan Pengajaran...")
db.query(AjuanPengajaran).delete()
ajuans = []
for i in range(1, 4686):
    ajuans.append(AjuanPengajaran(
        id=f"AJU_{uuid.uuid4().hex[:8].upper()}",
        dosen_id=f"D{random.randint(1, 100):03d}",
        dosen_nama=f"Dosen {random.randint(1, 100)}",
        fakultas_nama="Saintek",
        jurusan_nama="Teknik Informatika",
        mata_kuliah_id=f"MK{random.randint(1, 50):03d}",
        mata_kuliah_nama=f"Mata Kuliah {random.randint(1, 50)}",
        sks=random.choice([2, 3, 4]),
        semester=random.randint(1, 8),
        kelas_nama=f"Kelas {random.choice(['A','B','C','D'])}",
        jumlah_mahasiswa=random.randint(20, 50),
        status="diajukan",
        gedung_nama=random.choice(["", "Gedung Utama"]),
        ruangan_nama="",
        hari="",
        jam_mulai="",
        jam_selesai=""
    ))
    # Commit in batches
    if i % 500 == 0:
        db.add_all(ajuans)
        db.commit()
        ajuans = []
        
if ajuans:
    db.add_all(ajuans)
    db.commit()

print("Dataset successfully generated in benchmark.db!")
db.close()
