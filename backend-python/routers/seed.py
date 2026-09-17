from fastapi import APIRouter, Depends
from sqlalchemy.orm import Session
import bcrypt
from core.database import get_db, Base, engine
from models.models import User, Gedung, Ruangan, SlotWaktu, MataKuliah, MataKuliahKelas, AjuanPengajaran, JadwalFinal

router = APIRouter(prefix="", tags=["Seed & Health"])

def hash_pw(password: str) -> str:
    return bcrypt.hashpw(password.encode("utf-8"), bcrypt.gensalt()).decode("utf-8")

@router.get("/seed")
@router.get("/seed.php")
@router.post("/seed")
@router.post("/seed.php")
def run_seed(db: Session = Depends(get_db)):
    Base.metadata.create_all(bind=engine)
    
    # Check if admin already exists
    admin = db.query(User).filter(User.id == "ADM001").first()
    if not admin:
        default_pw = hash_pw("password123")
        users = [
            User(id="ADM001", nama="Super Admin", email="hamizanqowiem90@gmail.com", password=default_pw, role="admin", is_priority=True),
            User(id="ADM002", nama="Administrator Akademik", email="admin@univ.ac.id", password=default_pw, role="admin", is_priority=False),
            User(id="DEK001", nama="Prof. Dr. Ir. Budi Santoso, M.Sc.", email="dekan.fst@univ.ac.id", password=default_pw, role="dekan", is_priority=True),
            User(id="KAJ001", nama="Dr. Eng. Ahmad Fauzi, S.T., M.T.", email="kaprodi.ti@univ.ac.id", password=default_pw, role="kajur", is_priority=True),
            User(id="DOS001", nama="Dr. Hendra Gunawan, S.Kom., M.Cs.", email="hendra.gunawan@univ.ac.id", password=default_pw, role="dosen", is_priority=False),
            User(id="DOS002", nama="Siti Rahmawati, S.T., M.Kom.", email="siti.rahmawati@univ.ac.id", password=default_pw, role="dosen", is_priority=True),
            User(id="DOS003", nama="Rian Hidayat, M.Kom.", email="rian.hidayat@univ.ac.id", password=default_pw, role="dosen", is_priority=False)
        ]
        db.add_all(users)

        gedungs = [
            Gedung(id="GD01", nama="Gedung FST Terpadu", jam_buka="07:00", jam_tutup="18:00", akses_jurusan="Teknik Informatika, Sistem Informasi, Teknik Elektro"),
            Gedung(id="GD02", nama="Gedung Laboratorium Komputer", jam_buka="07:30", jam_tutup="17:30", akses_jurusan="Teknik Informatika, Sistem Informasi")
        ]
        db.add_all(gedungs)

        ruangans = [
            Ruangan(id="R101", nama="Ruang FST 101", gedung_id="GD01", lantai="Lantai 1", kapasitas=45, tipe_ruangan="Kelas Teori", keterangan="Dilengkapi AC & Proyektor"),
            Ruangan(id="R102", nama="Ruang FST 102", gedung_id="GD01", lantai="Lantai 1", kapasitas=45, tipe_ruangan="Kelas Teori", keterangan="Dilengkapi Smart TV 75 inch"),
            Ruangan(id="RLAB1", nama="Lab Software Engineering", gedung_id="GD02", lantai="Lantai 2", kapasitas=35, tipe_ruangan="Laboratorium Komputer", keterangan="40 PC Core i7, LAN Gigabit")
        ]
        db.add_all(ruangans)

        slots = [
            SlotWaktu(id="SLOT_SEN_1", hari="Senin", jam_mulai="07:30", jam_selesai="10:00", durasi_menit=150),
            SlotWaktu(id="SLOT_SEN_2", hari="Senin", jam_mulai="10:15", jam_selesai="12:45", durasi_menit=150),
            SlotWaktu(id="SLOT_SEN_3", hari="Senin", jam_mulai="13:30", jam_selesai="16:00", durasi_menit=150),
            SlotWaktu(id="SLOT_SEL_1", hari="Selasa", jam_mulai="07:30", jam_selesai="10:00", durasi_menit=150),
            SlotWaktu(id="SLOT_SEL_2", hari="Selasa", jam_mulai="10:15", jam_selesai="12:45", durasi_menit=150),
            SlotWaktu(id="SLOT_RAB_1", hari="Rabu", jam_mulai="07:30", jam_selesai="10:00", durasi_menit=150),
            SlotWaktu(id="SLOT_RAB_2", hari="Rabu", jam_mulai="10:15", jam_selesai="12:45", durasi_menit=150),
            SlotWaktu(id="SLOT_KAM_1", hari="Kamis", jam_mulai="07:30", jam_selesai="10:00", durasi_menit=150),
            SlotWaktu(id="SLOT_JUM_1", hari="Jumat", jam_mulai="07:30", jam_selesai="10:00", durasi_menit=150)
        ]
        db.add_all(slots)

        mks = [
            MataKuliah(id="MK001", nama="Algoritma & Pemrograman", sks=3, dosen_id="DOS001", semester_angka=1, kebutuhan_tipe_ruangan="Laboratorium Komputer"),
            MataKuliah(id="MK002", nama="Struktur Data & Analisis Algoritma", sks=3, dosen_id="DOS001", semester_angka=3, kebutuhan_tipe_ruangan="Laboratorium Komputer"),
            MataKuliah(id="MK003", nama="Basis Data Terdistribusi", sks=3, dosen_id="DOS002", semester_angka=3, kebutuhan_tipe_ruangan="Kelas Teori"),
            MataKuliah(id="MK004", nama="Kecerdasan Buatan & Machine Learning", sks=3, dosen_id="DOS002", semester_angka=5, kebutuhan_tipe_ruangan="Kelas Teori"),
            MataKuliah(id="MK005", nama="Pemrograman Mobile (Flutter)", sks=3, dosen_id="DOS003", semester_angka=5, kebutuhan_tipe_ruangan="Laboratorium Komputer")
        ]
        db.add_all(mks)

        notifications = [
            Notification(id="NOTIF_001", user_id="DOS001", title="Window Pengisian Jadwal Dibuka", message="Admin telah membuka periode pengajuan ketersediaan waktu dan preferensi mengajar semester Ganjil 2026/2027.", type="info", is_read=False),
            Notification(id="NOTIF_002", user_id="DOS001", title="Jadwal Kuliah Resmi Terbit", message="Seluruh jadwal perkuliahan 1 semester telah diverifikasi KaProdi, disetujui Dekan, dan dirilis oleh Admin.", type="success", is_read=False),
            Notification(id="NOTIF_003", user_id="ADM001", title="Smart CSP Backtracking Selesai", message="Penyusunan jadwal otomatis 1 semester berhasil diselesaikan dengan 0 bentrok.", type="success", is_read=False),
            Notification(id="NOTIF_004", user_id="KAJ001", title="Ajuan Dosen Terverifikasi", message="Semua ajuan ketersediaan mengajar dosen Teknik Informatika telah lolos verifikasi.", type="info", is_read=False),
            Notification(id="NOTIF_005", user_id="DEK001", title="Approval Dekan FST Selesai", message="Pengesahan alokasi gedung dan jadwal ruang perkuliahan Fakultas Sains & Teknologi telah ditandatangani digital.", type="success", is_read=False)
        ]
        db.add_all(notifications)
        db.commit()

    return {"status": "success", "message": "Database seed completed successfully."}
