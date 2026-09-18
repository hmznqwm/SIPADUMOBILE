from fastapi import APIRouter, Depends, HTTPException, Query, Header, status
from sqlalchemy.orm import Session
import os
import bcrypt
from typing import Optional
from core.database import get_db, Base, engine
from core.config import settings
from models.models import User, Gedung, Ruangan, SlotWaktu, MataKuliah, MataKuliahKelas, AjuanPengajaran, JadwalFinal, Notification

router = APIRouter(prefix="", tags=["Seed & Health"])

def hash_pw(password: str) -> str:
    return bcrypt.hashpw(password.encode("utf-8"), bcrypt.gensalt()).decode("utf-8")

@router.get("/seed")
@router.get("/seed.php")
@router.post("/seed")
@router.post("/seed.php")
def run_seed(
    key: Optional[str] = Query(None),
    authorization: Optional[str] = Header(None),
    db: Session = Depends(get_db)
):
    # Proteksi seed endpoint dengan JWT Secret / Master Key
    expected_key = settings.JWT_SECRET or "smartschedule_seed_dev_2026"
    provided_key = key or (authorization.replace("Bearer ", "") if authorization else "")
    if provided_key != expected_key and os.getenv("VERCEL_ENV") == "production":
        raise HTTPException(
            status_code=status.HTTP_403_FORBIDDEN,
            detail={"status": "error", "message": "Endpoint seed dinonaktifkan di production. Akses ditolak."}
        )
    Base.metadata.create_all(bind=engine)
    
    # Check if seed already executed
    admin = db.query(User).filter(User.id == "ADM001").first()
    if not admin:
        default_pw = hash_pw("password123")
        
        # 1. USERS & DOSEN UIN MALANG (7 FAKULTAS)
        users = [
            # Admins
            User(id="ADM001", nama="Super Admin UIN Malang", email="admin@uin-malang.ac.id", password=default_pw, role="admin", is_priority=True),
            User(id="ADM002", nama="Operator Akademik Pusat", email="operator.akademik@uin-malang.ac.id", password=default_pw, role="admin", is_priority=False),
            
            # Dekan 7 Fakultas UIN Malang
            User(id="DEK001", nama="Prof. Dr. Ir. Budi Santoso, M.Sc.", email="dekan.fst@uin-malang.ac.id", password=default_pw, role="dekan", fakultas_nama="Fakultas Sains dan Teknologi", is_priority=True),
            User(id="DEK002", nama="Prof. Dr. H. Nur Ali, M.Pd.", email="dekan.fitk@uin-malang.ac.id", password=default_pw, role="dekan", fakultas_nama="Fakultas Ilmu Tarbiyah dan Keguruan", is_priority=True),
            User(id="DEK003", nama="Prof. Dr. H. Saifullah, S.H., M.Hum.", email="dekan.syariah@uin-malang.ac.id", password=default_pw, role="dekan", fakultas_nama="Fakultas Syariah", is_priority=True),
            User(id="DEK004", nama="Prof. Dr. H. Misbahul Munir, M.Si.", email="dekan.fe@uin-malang.ac.id", password=default_pw, role="dekan", fakultas_nama="Fakultas Ekonomi", is_priority=True),
            User(id="DEK005", nama="Prof. Dr. H. Rifa'i Husein, M.Si.", email="dekan.psikologi@uin-malang.ac.id", password=default_pw, role="dekan", fakultas_nama="Fakultas Psikologi", is_priority=True),
            User(id="DEK006", nama="Dr. M. Faisol, M.Ag.", email="dekan.humaniora@uin-malang.ac.id", password=default_pw, role="dekan", fakultas_nama="Fakultas Humaniora", is_priority=True),
            User(id="DEK007", nama="Prof. Dr. dr. Yuyun Yueniwati, M.Kes., Sp.Rad(K).", email="dekan.fkik@uin-malang.ac.id", password=default_pw, role="dekan", fakultas_nama="Fakultas Kedokteran dan Ilmu Kesehatan", is_priority=True),

            # Kaprodi / Kajur UIN Malang
            User(id="KAJ001", nama="Dr. Eng. Ahmad Fauzi, S.T., M.T.", email="kaprodi.ti@uin-malang.ac.id", password=default_pw, role="kajur", fakultas_nama="Fakultas Sains dan Teknologi", jurusan_nama="Teknik Informatika", is_priority=True),
            User(id="KAJ002", nama="Dr. H. Muhammad Munir, M.Ag.", email="kaprodi.pai@uin-malang.ac.id", password=default_pw, role="kajur", fakultas_nama="Fakultas Ilmu Tarbiyah dan Keguruan", jurusan_nama="Pendidikan Agama Islam", is_priority=True),
            User(id="KAJ003", nama="Dr. H. Burhanuddin, M.H.", email="kaprodi.hes@uin-malang.ac.id", password=default_pw, role="kajur", fakultas_nama="Fakultas Syariah", jurusan_nama="Hukum Ekonomi Syariah", is_priority=True),
            User(id="KAJ004", nama="Dr. H. Salim Al Idrus, M.M.", email="kaprodi.manajemen@uin-malang.ac.id", password=default_pw, role="kajur", fakultas_nama="Fakultas Ekonomi", jurusan_nama="Manajemen", is_priority=True),
            User(id="KAJ005", nama="Dr. Fathul Lubab, M.Si.", email="kaprodi.psikologi@uin-malang.ac.id", password=default_pw, role="kajur", fakultas_nama="Fakultas Psikologi", jurusan_nama="Psikologi", is_priority=True),
            User(id="KAJ006", nama="Dr. Mundi Rahayu, M.Hum.", email="kaprodi.sastrainggris@uin-malang.ac.id", password=default_pw, role="kajur", fakultas_nama="Fakultas Humaniora", jurusan_nama="Sastra Inggris", is_priority=True),
            User(id="KAJ007", nama="dr. Christyana Rahayuningsih, M.Biomed.", email="kaprodi.kedokteran@uin-malang.ac.id", password=default_pw, role="kajur", fakultas_nama="Fakultas Kedokteran dan Ilmu Kesehatan", jurusan_nama="Pendidikan Dokter", is_priority=True),

            # Dosen Pengajar UIN Malang
            # FST
            User(id="DOS001", nama="Dr. Hendra Gunawan, S.Kom., M.Cs.", email="hendra.gunawan@uin-malang.ac.id", password=default_pw, role="dosen", fakultas_nama="Fakultas Sains dan Teknologi", jurusan_nama="Teknik Informatika", is_priority=False),
            User(id="DOS002", nama="Siti Rahmawati, S.T., M.Kom.", email="siti.rahmawati@uin-malang.ac.id", password=default_pw, role="dosen", fakultas_nama="Fakultas Sains dan Teknologi", jurusan_nama="Teknik Informatika", is_priority=True),
            User(id="DOS003", nama="Rian Hidayat, M.Kom.", email="rian.hidayat@uin-malang.ac.id", password=default_pw, role="dosen", fakultas_nama="Fakultas Sains dan Teknologi", jurusan_nama="Teknik Informatika", is_priority=False),
            User(id="DOS004", nama="Dr. Muhammad Ali, M.T.", email="muhammad.ali@uin-malang.ac.id", password=default_pw, role="dosen", fakultas_nama="Fakultas Sains dan Teknologi", jurusan_nama="Sistem Informasi", is_priority=True),
            User(id="DOS005", nama="Dr. Ir. Nadhir, M.T.", email="nadhir@uin-malang.ac.id", password=default_pw, role="dosen", fakultas_nama="Fakultas Sains dan Teknologi", jurusan_nama="Teknik Arsitektur", is_priority=False),

            # FITK
            User(id="DOS006", nama="Dr. Hj. Mamluatun Ni'mah, M.Ag.", email="mamluatun@uin-malang.ac.id", password=default_pw, role="dosen", fakultas_nama="Fakultas Ilmu Tarbiyah dan Keguruan", jurusan_nama="Pendidikan Agama Islam", is_priority=True),
            User(id="DOS007", nama="Ahmad Fikri, M.Pd.", email="ahmad.fikri@uin-malang.ac.id", password=default_pw, role="dosen", fakultas_nama="Fakultas Ilmu Tarbiyah dan Keguruan", jurusan_nama="Pendidikan Bahasa Arab", is_priority=False),

            # Syariah
            User(id="DOS008", nama="Dr. Hj. Tutik Hamidah, M.Ag.", email="tutik.hamidah@uin-malang.ac.id", password=default_pw, role="dosen", fakultas_nama="Fakultas Syariah", jurusan_nama="Hukum Ekonomi Syariah", is_priority=True),
            User(id="DOS009", nama="M. Syarif Hidayatullah, M.H.", email="syarif.hidayat@uin-malang.ac.id", password=default_pw, role="dosen", fakultas_nama="Fakultas Syariah", jurusan_nama="Hukum Keluarga Islam", is_priority=False),

            # FE
            User(id="DOS010", nama="Dr. Indah Yanti, S.E., M.M.", email="indah.yanti@uin-malang.ac.id", password=default_pw, role="dosen", fakultas_nama="Fakultas Ekonomi", jurusan_nama="Manajemen", is_priority=True),
            User(id="DOS011", nama="M. Nur Kholis, M.S.A., Ak.", email="kholis.akuntansi@uin-malang.ac.id", password=default_pw, role="dosen", fakultas_nama="Fakultas Ekonomi", jurusan_nama="Akuntansi", is_priority=False),

            # Psikologi
            User(id="DOS012", nama="Nurlaila Fitriani, M.Psi., Psikolog", email="nurlaila.fitriani@uin-malang.ac.id", password=default_pw, role="dosen", fakultas_nama="Fakultas Psikologi", jurusan_nama="Psikologi", is_priority=True),

            # Humaniora
            User(id="DOS013", nama="Dr. Abdul Basid, M.Pd.", email="abdul.basid@uin-malang.ac.id", password=default_pw, role="dosen", fakultas_nama="Fakultas Humaniora", jurusan_nama="Bahasa dan Sastra Arab", is_priority=True),

            # FKIK
            User(id="DOS014", nama="Apt. Eko Suhartono, M.Sc.", email="eko.suhartono@uin-malang.ac.id", password=default_pw, role="dosen", fakultas_nama="Fakultas Kedokteran dan Ilmu Kesehatan", jurusan_nama="Farmasi", is_priority=True),
        ]
        for u in users:
            u.password = hash_pw(u.id)
        db.add_all(users)

        # 2. GEDUNG PERKULIAHAN UIN MALANG
        gedungs = [
            Gedung(id="GD_FST1", nama="Gedung FST Terpadu BJ Habibie", jam_buka="07:00", jam_tutup="18:00", akses_jurusan="Teknik Informatika, Sistem Informasi, Teknik Arsitektur, Matematika, Biologi, Fisika, Kimia"),
            Gedung(id="GD_FST2", nama="Gedung Laboratorium Sains Terpadu", jam_buka="07:30", jam_tutup="17:30", akses_jurusan="Teknik Informatika, Sistem Informasi, Kimia, Biologi, Fisika"),
            Gedung(id="GD_FITK", nama="Gedung Megawati Soekarnoputri (FITK)", jam_buka="07:00", jam_tutup="18:00", akses_jurusan="Pendidikan Agama Islam, Pendidikan Bahasa Arab, Tadris Bahasa Inggris, PGMI, PIAUD"),
            Gedung(id="GD_SYAR", nama="Gedung Al-Farabi (Fakultas Syariah)", jam_buka="07:00", jam_tutup="17:30", akses_jurusan="Hukum Keluarga Islam, Hukum Ekonomi Syariah, Hukum Tatanegara"),
            Gedung(id="GD_FE", nama="Gedung Al-Biruni (Fakultas Ekonomi)", jam_buka="07:00", jam_tutup="18:00", akses_jurusan="Manajemen, Akuntansi, Perbankan Syariah"),
            Gedung(id="GD_PSI", nama="Gedung Ibnu Rusyd (Fakultas Psikologi)", jam_buka="07:30", jam_tutup="17:30", akses_jurusan="Psikologi"),
            Gedung(id="GD_HUM", nama="Gedung Ibnu Khaldun (Fakultas Humaniora)", jam_buka="07:00", jam_tutup="18:00", akses_jurusan="Bahasa dan Sastra Arab, Sastra Inggris"),
            Gedung(id="GD_FKIK", nama="Gedung Ibnu Sina (FKIK Kampus 3)", jam_buka="07:00", jam_tutup="18:00", akses_jurusan="Pendidikan Dokter, Farmasi"),
            Gedung(id="GD_GKU", nama="Gedung Kuliah Umum (GKU) Rektorat", jam_buka="07:00", jam_tutup="18:30", akses_jurusan="Semua Fakultas"),
        ]
        db.add_all(gedungs)

        # 3. RUANGAN PERKULIAHAN LENGKAP
        ruangans = [
            # FST
            Ruangan(id="R_FST101", nama="Ruang FST 101", gedung_id="GD_FST1", lantai="Lantai 1", kapasitas=45, tipe_ruangan="Kelas Teori", keterangan="Dilengkapi AC & Proyektor 4K"),
            Ruangan(id="R_FST102", nama="Ruang FST 102", gedung_id="GD_FST1", lantai="Lantai 1", kapasitas=45, tipe_ruangan="Kelas Teori", keterangan="Dilengkapi Smart TV 75 inch"),
            Ruangan(id="R_FST201", nama="Studio Gambar Arsitektur", gedung_id="GD_FST1", lantai="Lantai 2", kapasitas=40, tipe_ruangan="Studio Arsitektur", keterangan="Meja gambar & Plotter A0"),
            Ruangan(id="RLAB_SE", nama="Lab Software Engineering", gedung_id="GD_FST2", lantai="Lantai 2", kapasitas=35, tipe_ruangan="Laboratorium Komputer", keterangan="40 PC Core i7, LAN Gigabit"),
            Ruangan(id="RLAB_AI", nama="Lab AI & Data Science", gedung_id="GD_FST2", lantai="Lantai 2", kapasitas=35, tipe_ruangan="Laboratorium Komputer", keterangan="NVIDIA RTX GPU Workstations"),

            # FITK
            Ruangan(id="R_FITK101", nama="Ruang FITK 101 Megawati", gedung_id="GD_FITK", lantai="Lantai 1", kapasitas=50, tipe_ruangan="Kelas Teori", keterangan="Sound System & Smart Board"),
            Ruangan(id="R_FITK102", nama="Ruang Microteaching FITK", gedung_id="GD_FITK", lantai="Lantai 1", kapasitas=30, tipe_ruangan="Laboratorium Microteaching", keterangan="Kamera Rekam Pembelajaran"),

            # Syariah
            Ruangan(id="R_SYAR101", nama="Ruang Syariah 101", gedung_id="GD_SYAR", lantai="Lantai 1", kapasitas=45, tipe_ruangan="Kelas Teori", keterangan="Perpustakaan Hukum Mini"),
            Ruangan(id="R_SYAR_SEM", nama="Ruang Peradilan Semu", gedung_id="GD_SYAR", lantai="Lantai 2", kapasitas=40, tipe_ruangan="Laboratorium Hukum", keterangan="Set Ruang Sidang Pengadilan"),

            # FE
            Ruangan(id="R_FE101", nama="Ruang FE 101 Al-Biruni", gedung_id="GD_FE", lantai="Lantai 1", kapasitas=50, tipe_ruangan="Kelas Teori", keterangan="AC & Dual Projector"),
            Ruangan(id="R_FE_MINIBANK", nama="Lab Galeri Investasi & Bank Syariah", gedung_id="GD_FE", lantai="Lantai 2", kapasitas=35, tipe_ruangan="Laboratorium Komputer", keterangan="Terminal Bloomberg & Mini Bank"),

            # Psikologi
            Ruangan(id="R_PSI101", nama="Ruang Psikologi 101", gedung_id="GD_PSI", lantai="Lantai 1", kapasitas=45, tipe_ruangan="Kelas Teori", keterangan="Papan Tulis Glassboard"),
            Ruangan(id="R_PSI_LAB", nama="Lab Psikodiagnostik", gedung_id="GD_PSI", lantai="Lantai 2", kapasitas=30, tipe_ruangan="Laboratorium Psikologi", keterangan="Cermin One-Way Mirror"),

            # Humaniora
            Ruangan(id="R_HUM101", nama="Ruang Humaniora 101", gedung_id="GD_HUM", lantai="Lantai 1", kapasitas=45, tipe_ruangan="Kelas Teori", keterangan="Proyektor & AC"),
            Ruangan(id="R_HUM_BAHASA", nama="Lab Bahasa Multimedia", gedung_id="GD_HUM", lantai="Lantai 2", kapasitas=35, tipe_ruangan="Laboratorium Bahasa", keterangan="Audio Headset & Software Lingua"),

            # FKIK
            Ruangan(id="R_FKIK101", nama="Ruang FKIK 101 Ibnu Sina", gedung_id="GD_FKIK", lantai="Lantai 1", kapasitas=60, tipe_ruangan="Kelas Teori", keterangan="Ruang Kuliah Teater"),
            Ruangan(id="R_FKIK_ANATOMI", nama="Lab Anatomi & Farmakologi", gedung_id="GD_FKIK", lantai="Lantai 2", kapasitas=30, tipe_ruangan="Laboratorium Sains", keterangan="Manekin Cadaver & Mikroskop"),

            # GKU Bersama
            Ruangan(id="R_GKU101", nama="Hall GKU Rektorat 101", gedung_id="GD_GKU", lantai="Lantai 1", kapasitas=60, tipe_ruangan="Kelas Teori", keterangan="Gedung Bersama Multiguna"),
        ]
        db.add_all(ruangans)

        # 4. SLOT WAKTU STANDAR UIN MALANG
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

        # 5. MATA KULIAH LENGKAP 7 FAKULTAS
        mks = [
            # FST - Teknik Informatika
            MataKuliah(id="MK001", nama="Algoritma & Pemrograman", sks=3, dosen_id="DOS001", jurusan_nama="Teknik Informatika", fakultas_nama="Fakultas Sains dan Teknologi", semester_angka=1, kebutuhan_tipe_ruangan="Laboratorium Komputer"),
            MataKuliah(id="MK002", nama="Struktur Data & Analisis Algoritma", sks=3, dosen_id="DOS001", jurusan_nama="Teknik Informatika", fakultas_nama="Fakultas Sains dan Teknologi", semester_angka=3, kebutuhan_tipe_ruangan="Laboratorium Komputer"),
            MataKuliah(id="MK003", nama="Basis Data Terdistribusi", sks=3, dosen_id="DOS002", jurusan_nama="Teknik Informatika", fakultas_nama="Fakultas Sains dan Teknologi", semester_angka=3, kebutuhan_tipe_ruangan="Kelas Teori"),
            MataKuliah(id="MK004", nama="Kecerdasan Buatan & Machine Learning", sks=3, dosen_id="DOS002", jurusan_nama="Teknik Informatika", fakultas_nama="Fakultas Sains dan Teknologi", semester_angka=5, kebutuhan_tipe_ruangan="Laboratorium Komputer"),
            MataKuliah(id="MK005", nama="Pemrograman Mobile (Flutter)", sks=3, dosen_id="DOS003", jurusan_nama="Teknik Informatika", fakultas_nama="Fakultas Sains dan Teknologi", semester_angka=5, kebutuhan_tipe_ruangan="Laboratorium Komputer"),
            
            # FST - Sistem Informasi
            MataKuliah(id="MK006", nama="Manajemen Sistem Informasi Bisnis", sks=3, dosen_id="DOS004", jurusan_nama="Sistem Informasi", fakultas_nama="Fakultas Sains dan Teknologi", semester_angka=3, kebutuhan_tipe_ruangan="Kelas Teori"),
            
            # FITK - PAI
            MataKuliah(id="MK007", nama="Metodologi Pembelajaran Agama Islam", sks=3, dosen_id="DOS006", jurusan_nama="Pendidikan Agama Islam", fakultas_nama="Fakultas Ilmu Tarbiyah dan Keguruan", semester_angka=3, kebutuhan_tipe_ruangan="Kelas Teori"),
            
            # Syariah - HES
            MataKuliah(id="MK008", nama="Fiqh Muamalah Maliyah", sks=3, dosen_id="DOS008", jurusan_nama="Hukum Ekonomi Syariah", fakultas_nama="Fakultas Syariah", semester_angka=3, kebutuhan_tipe_ruangan="Kelas Teori"),

            # Ekonomi - Manajemen
            MataKuliah(id="MK009", nama="Manajemen Keuangan Syariah", sks=3, dosen_id="DOS010", jurusan_nama="Manajemen", fakultas_nama="Fakultas Ekonomi", semester_angka=3, kebutuhan_tipe_ruangan="Kelas Teori"),

            # Psikologi
            MataKuliah(id="MK010", nama="Psikologi Perkembangan Anak & Remaja", sks=3, dosen_id="DOS012", jurusan_nama="Psikologi", fakultas_nama="Fakultas Psikologi", semester_angka=3, kebutuhan_tipe_ruangan="Kelas Teori"),

            # Humaniora - BSA
            MataKuliah(id="MK011", nama="Balaghah & Al-Adab Al-Arabi", sks=3, dosen_id="DOS013", jurusan_nama="Bahasa dan Sastra Arab", fakultas_nama="Fakultas Humaniora", semester_angka=3, kebutuhan_tipe_ruangan="Kelas Teori"),

            # FKIK - Farmasi
            MataKuliah(id="MK012", nama="Farmakologi Klinik & Resep", sks=3, dosen_id="DOS014", jurusan_nama="Farmasi", fakultas_nama="Fakultas Kedokteran dan Ilmu Kesehatan", semester_angka=3, kebutuhan_tipe_ruangan="Laboratorium Sains"),
        ]
        db.add_all(mks)

        # 6. DUMMY AJUAN PENGAJARAN (DENGAN STATUS DIVERIFIKASI AGARlangsung DIPROSES CSP)
        sample_ajuans = [
            # FST - Teknik Informatika
            AjuanPengajaran(
                id="AJ001", mata_kuliah_id="MK001", mata_kuliah_nama="Algoritma & Pemrograman", sks=3, kelas_nama="TI-1A",
                dosen_id="DOS001", dosen_nama="Dr. Hendra Gunawan, S.Kom., M.Cs.", fakultas_nama="Fakultas Sains dan Teknologi", jurusan_nama="Teknik Informatika",
                jumlah_mahasiswa=40, gedung_nama="Gedung Laboratorium Sains Terpadu", ruangan_nama="Lab Software Engineering", hari="Senin", jam_mulai="07:30", jam_selesai="10:00", status="diverifikasi_kaprodi"
            ),
            AjuanPengajaran(
                id="AJ002", mata_kuliah_id="MK002", mata_kuliah_nama="Struktur Data & Analisis Algoritma", sks=3, kelas_nama="TI-3A",
                dosen_id="DOS001", dosen_nama="Dr. Hendra Gunawan, S.Kom., M.Cs.", fakultas_nama="Fakultas Sains dan Teknologi", jurusan_nama="Teknik Informatika",
                jumlah_mahasiswa=35, gedung_nama="Gedung Laboratorium Sains Terpadu", ruangan_nama="Lab Software Engineering", hari="Senin", jam_mulai="10:15", jam_selesai="12:45", status="diverifikasi_kaprodi"
            ),
            AjuanPengajaran(
                id="AJ003", mata_kuliah_id="MK003", mata_kuliah_nama="Basis Data Terdistribusi", sks=3, kelas_nama="TI-3B",
                dosen_id="DOS002", dosen_nama="Siti Rahmawati, S.T., M.Kom.", fakultas_nama="Fakultas Sains dan Teknologi", jurusan_nama="Teknik Informatika",
                jumlah_mahasiswa=42, gedung_nama="Gedung FST Terpadu BJ Habibie", ruangan_nama="Ruang FST 101", hari="Selasa", jam_mulai="07:30", jam_selesai="10:00", status="diverifikasi_kaprodi"
            ),
            AjuanPengajaran(
                id="AJ004", mata_kuliah_id="MK004", mata_kuliah_nama="Kecerdasan Buatan & Machine Learning", sks=3, kelas_nama="TI-5A",
                dosen_id="DOS002", dosen_nama="Siti Rahmawati, S.T., M.Kom.", fakultas_nama="Fakultas Sains dan Teknologi", jurusan_nama="Teknik Informatika",
                jumlah_mahasiswa=38, gedung_nama="Gedung Laboratorium Sains Terpadu", ruangan_nama="Lab AI & Data Science", hari="Rabu", jam_mulai="07:30", jam_selesai="10:00", status="diverifikasi_kaprodi"
            ),
            AjuanPengajaran(
                id="AJ005", mata_kuliah_id="MK005", mata_kuliah_nama="Pemrograman Mobile (Flutter)", sks=3, kelas_nama="TI-5B",
                dosen_id="DOS003", dosen_nama="Rian Hidayat, M.Kom.", fakultas_nama="Fakultas Sains dan Teknologi", jurusan_nama="Teknik Informatika",
                jumlah_mahasiswa=30, gedung_nama="Gedung Laboratorium Sains Terpadu", ruangan_nama="Lab Software Engineering", hari="Kamis", jam_mulai="07:30", jam_selesai="10:00", status="diverifikasi_kaprodi"
            ),

            # FITK
            AjuanPengajaran(
                id="AJ006", mata_kuliah_id="MK007", mata_kuliah_nama="Metodologi Pembelajaran Agama Islam", sks=3, kelas_nama="PAI-3A",
                dosen_id="DOS006", dosen_nama="Dr. Hj. Mamluatun Ni'mah, M.Ag.", fakultas_nama="Fakultas Ilmu Tarbiyah dan Keguruan", jurusan_nama="Pendidikan Agama Islam",
                jumlah_mahasiswa=45, gedung_nama="Gedung Megawati Soekarnoputri (FITK)", ruangan_nama="Ruang FITK 101 Megawati", hari="Senin", jam_mulai="07:30", jam_selesai="10:00", status="diverifikasi_kaprodi"
            ),

            # Syariah
            AjuanPengajaran(
                id="AJ007", mata_kuliah_id="MK008", mata_kuliah_nama="Fiqh Muamalah Maliyah", sks=3, kelas_nama="HES-3A",
                dosen_id="DOS008", dosen_nama="Dr. Hj. Tutik Hamidah, M.Ag.", fakultas_nama="Fakultas Syariah", jurusan_nama="Hukum Ekonomi Syariah",
                jumlah_mahasiswa=40, gedung_nama="Gedung Al-Farabi (Fakultas Syariah)", ruangan_nama="Ruang Syariah 101", hari="Selasa", jam_mulai="07:30", jam_selesai="10:00", status="diverifikasi_kaprodi"
            ),

            # Ekonomi
            AjuanPengajaran(
                id="AJ008", mata_kuliah_id="MK009", mata_kuliah_nama="Manajemen Keuangan Syariah", sks=3, kelas_nama="MNJ-3A",
                dosen_id="DOS010", dosen_nama="Dr. Indah Yanti, S.E., M.M.", fakultas_nama="Fakultas Ekonomi", jurusan_nama="Manajemen",
                jumlah_mahasiswa=48, gedung_nama="Gedung Al-Biruni (Fakultas Ekonomi)", ruangan_nama="Ruang FE 101 Al-Biruni", hari="Rabu", jam_mulai="07:30", jam_selesai="10:00", status="diverifikasi_kaprodi"
            ),

            # Psikologi
            AjuanPengajaran(
                id="AJ009", mata_kuliah_id="MK010", mata_kuliah_nama="Psikologi Perkembangan Anak & Remaja", sks=3, kelas_nama="PSI-3A",
                dosen_id="DOS012", dosen_nama="Nurlaila Fitriani, M.Psi., Psikolog", fakultas_nama="Fakultas Psikologi", jurusan_nama="Psikologi",
                jumlah_mahasiswa=42, gedung_nama="Gedung Ibnu Rusyd (Fakultas Psikologi)", ruangan_nama="Ruang Psikologi 101", hari="Kamis", jam_mulai="07:30", jam_selesai="10:00", status="diverifikasi_kaprodi"
            ),

            # Humaniora
            AjuanPengajaran(
                id="AJ010", mata_kuliah_id="MK011", mata_kuliah_nama="Balaghah & Al-Adab Al-Arabi", sks=3, kelas_nama="BSA-3A",
                dosen_id="DOS013", dosen_nama="Dr. Abdul Basid, M.Pd.", fakultas_nama="Fakultas Humaniora", jurusan_nama="Bahasa dan Sastra Arab",
                jumlah_mahasiswa=40, gedung_nama="Gedung Ibnu Khaldun (Fakultas Humaniora)", ruangan_nama="Ruang Humaniora 101", hari="Jumat", jam_mulai="07:30", jam_selesai="10:00", status="diverifikasi_kaprodi"
            ),

            # FKIK
            AjuanPengajaran(
                id="AJ011", mata_kuliah_id="MK012", mata_kuliah_nama="Farmakologi Klinik & Resep", sks=3, kelas_nama="FAR-3A",
                dosen_id="DOS014", dosen_nama="Apt. Eko Suhartono, M.Sc.", fakultas_nama="Fakultas Kedokteran dan Ilmu Kesehatan", jurusan_nama="Farmasi",
                jumlah_mahasiswa=30, gedung_nama="Gedung Ibnu Sina (FKIK Kampus 3)", ruangan_nama="Lab Anatomi & Farmakologi", hari="Senin", jam_mulai="13:30", jam_selesai="16:00", status="diverifikasi_kaprodi"
            ),
        ]
        db.add_all(sample_ajuans)

        # 7. NOTIFIKASI
        notifications = [
            Notification(id="NOTIF_001", user_id="DOS001", title="Window Pengisian Jadwal Dibuka", message="Admin UIN Malang telah membuka periode pengajuan ketersediaan mengajar semester Ganjil 2026/2027.", type="info", is_read=False),
            Notification(id="NOTIF_002", user_id="DOS001", title="Jadwal Kuliah Resmi Terbit", message="Seluruh jadwal perkuliahan 7 Fakultas UIN Malang telah diverifikasi KaProdi & disetujui Dekan.", type="success", is_read=False),
            Notification(id="NOTIF_003", user_id="ADM001", title="Smart CSP Backtracking Selesai", message="Penyusunan jadwal otomatis 7 Fakultas UIN Malang berhasil diselesaikan tanpa bentrok.", type="success", is_read=False),
        ]
        db.add_all(notifications)
        
        db.commit()

    return {"status": "success", "message": "Database UIN Malang (7 Fakultas & Seluruh Prodi) berhasil di-seed sempurna."}
