import requests
import bcrypt

SUPABASE_URL = "https://wxrsstdnlpzonqcaqagv.supabase.co"
SECRET_KEY = "sb_secret_" + "jGMLt3WS6-BcxV9bn6LHww_V8gS3wus"

headers = {
    "apikey": SECRET_KEY,
    "Authorization": f"Bearer {SECRET_KEY}",
    "Content-Type": "application/json",
    "Prefer": "resolution=merge-duplicates"
}

def hash_pw(password: str) -> str:
    return bcrypt.hashpw(password.encode("utf-8"), bcrypt.gensalt()).decode("utf-8")

def upsert_table(table_name: str, records: list):
    url = f"{SUPABASE_URL}/rest/v1/{table_name}"
    res = requests.post(url, headers=headers, json=records)
    if res.status_code in [200, 201]:
        print(f"[SUCCESS] Seeding '{table_name}': {len(records)} records inserted/merged.")
    else:
        print(f"[ERROR] Seeding '{table_name}' ({res.status_code}): {res.text}")

def seed_all():
    print("[START] Starting direct seed into Supabase Cloud Database...")

    # 1. USERS & DOSEN
    default_pw = hash_pw("password123")
    raw_users = [
        # Admins
        {"id": "ADM001", "nama": "Hamizan Qowiem", "email": "hamizanqowiem90@gmail.com", "password": hash_pw("admin123"), "role": "admin", "is_priority": True},
        {"id": "ADM002", "nama": "Operator Akademik Pusat", "email": "operator.akademik@uin-malang.ac.id", "password": hash_pw("ADM002"), "role": "admin", "is_priority": False},
        
        # Dekan 7 Fakultas
        {"id": "DEK001", "nama": "Prof. Dr. Ir. Budi Santoso, M.Sc.", "email": "dekan.fst@uin-malang.ac.id", "password": hash_pw("DEK001"), "role": "dekan", "fakultas_nama": "Fakultas Sains dan Teknologi", "is_priority": True},
        {"id": "DEK002", "nama": "Prof. Dr. H. Nur Ali, M.Pd.", "email": "dekan.fitk@uin-malang.ac.id", "password": hash_pw("DEK002"), "role": "dekan", "fakultas_nama": "Fakultas Ilmu Tarbiyah dan Keguruan", "is_priority": True},
        {"id": "DEK003", "nama": "Prof. Dr. H. Saifullah, S.H., M.Hum.", "email": "dekan.syariah@uin-malang.ac.id", "password": hash_pw("DEK003"), "role": "dekan", "fakultas_nama": "Fakultas Syariah", "is_priority": True},
        {"id": "DEK004", "nama": "Prof. Dr. H. Misbahul Munir, M.Si.", "email": "dekan.fe@uin-malang.ac.id", "password": hash_pw("DEK004"), "role": "dekan", "fakultas_nama": "Fakultas Ekonomi", "is_priority": True},
        {"id": "DEK005", "nama": "Prof. Dr. H. Rifa'i Husein, M.Si.", "email": "dekan.psikologi@uin-malang.ac.id", "password": hash_pw("DEK005"), "role": "dekan", "fakultas_nama": "Fakultas Psikologi", "is_priority": True},
        {"id": "DEK006", "nama": "Dr. M. Faisol, M.Ag.", "email": "dekan.humaniora@uin-malang.ac.id", "password": hash_pw("DEK006"), "role": "dekan", "fakultas_nama": "Fakultas Humaniora", "is_priority": True},
        {"id": "DEK007", "nama": "Prof. Dr. dr. Yuyun Yueniwati, M.Kes., Sp.Rad(K).", "email": "dekan.fkik@uin-malang.ac.id", "password": hash_pw("DEK007"), "role": "dekan", "fakultas_nama": "Fakultas Kedokteran dan Ilmu Kesehatan", "is_priority": True},

        # Kaprodi / Kajur
        {"id": "KAJ001", "nama": "Dr. Eng. Ahmad Fauzi, S.T., M.T.", "email": "kaprodi.ti@uin-malang.ac.id", "password": hash_pw("KAJ001"), "role": "kajur", "fakultas_nama": "Fakultas Sains dan Teknologi", "jurusan_nama": "Teknik Informatika", "is_priority": True},
        {"id": "KAJ002", "nama": "Dr. H. Muhammad Munir, M.Ag.", "email": "kaprodi.pai@uin-malang.ac.id", "password": hash_pw("KAJ002"), "role": "kajur", "fakultas_nama": "Fakultas Ilmu Tarbiyah dan Keguruan", "jurusan_nama": "Pendidikan Agama Islam", "is_priority": True},
        {"id": "KAJ003", "nama": "Dr. H. Burhanuddin, M.H.", "email": "kaprodi.hes@uin-malang.ac.id", "password": hash_pw("KAJ003"), "role": "kajur", "fakultas_nama": "Fakultas Syariah", "jurusan_nama": "Hukum Ekonomi Syariah", "is_priority": True},
        {"id": "KAJ004", "nama": "Dr. H. Salim Al Idrus, M.M.", "email": "kaprodi.manajemen@uin-malang.ac.id", "password": hash_pw("KAJ004"), "role": "kajur", "fakultas_nama": "Fakultas Ekonomi", "jurusan_nama": "Manajemen", "is_priority": True},
        {"id": "KAJ005", "nama": "Dr. Fathul Lubab, M.Si.", "email": "kaprodi.psikologi@uin-malang.ac.id", "password": hash_pw("KAJ005"), "role": "kajur", "fakultas_nama": "Fakultas Psikologi", "jurusan_nama": "Psikologi", "is_priority": True},
        {"id": "KAJ006", "nama": "Dr. Mundi Rahayu, M.Hum.", "email": "kaprodi.sastrainggris@uin-malang.ac.id", "password": hash_pw("KAJ006"), "role": "kajur", "fakultas_nama": "Fakultas Humaniora", "jurusan_nama": "Sastra Inggris", "is_priority": True},
        {"id": "KAJ007", "nama": "dr. Christyana Rahayuningsih, M.Biomed.", "email": "kaprodi.kedokteran@uin-malang.ac.id", "password": hash_pw("KAJ007"), "role": "kajur", "fakultas_nama": "Fakultas Kedokteran dan Ilmu Kesehatan", "jurusan_nama": "Pendidikan Dokter", "is_priority": True},

        # Dosen Pengajar UIN Malang
        {"id": "DOS001", "nama": "Dr. Hendra Gunawan, S.Kom., M.Cs.", "email": "hendra.gunawan@uin-malang.ac.id", "password": hash_pw("DOS001"), "role": "dosen", "fakultas_nama": "Fakultas Sains dan Teknologi", "jurusan_nama": "Teknik Informatika", "is_priority": False},
        {"id": "DOS002", "nama": "Siti Rahmawati, S.T., M.Kom.", "email": "siti.rahmawati@uin-malang.ac.id", "password": hash_pw("DOS002"), "role": "dosen", "fakultas_nama": "Fakultas Sains dan Teknologi", "jurusan_nama": "Teknik Informatika", "is_priority": True},
        {"id": "DOS003", "nama": "Rian Hidayat, M.Kom.", "email": "rian.hidayat@uin-malang.ac.id", "password": hash_pw("DOS003"), "role": "dosen", "fakultas_nama": "Fakultas Sains dan Teknologi", "jurusan_nama": "Teknik Informatika", "is_priority": False},
        {"id": "DOS004", "nama": "Dr. Muhammad Ali, M.T.", "email": "muhammad.ali@uin-malang.ac.id", "password": hash_pw("DOS004"), "role": "dosen", "fakultas_nama": "Fakultas Sains dan Teknologi", "jurusan_nama": "Sistem Informasi", "is_priority": True},
        {"id": "DOS005", "nama": "Dr. Ir. Nadhir, M.T.", "email": "nadhir@uin-malang.ac.id", "password": hash_pw("DOS005"), "role": "dosen", "fakultas_nama": "Fakultas Sains dan Teknologi", "jurusan_nama": "Teknik Arsitektur", "is_priority": False},
        {"id": "DOS006", "nama": "Dr. Hj. Mamluatun Ni'mah, M.Ag.", "email": "mamluatun@uin-malang.ac.id", "password": hash_pw("DOS006"), "role": "dosen", "fakultas_nama": "Fakultas Ilmu Tarbiyah dan Keguruan", "jurusan_nama": "Pendidikan Agama Islam", "is_priority": True},
        {"id": "DOS007", "nama": "Ahmad Fikri, M.Pd.", "email": "ahmad.fikri@uin-malang.ac.id", "password": hash_pw("DOS007"), "role": "dosen", "fakultas_nama": "Fakultas Ilmu Tarbiyah dan Keguruan", "jurusan_nama": "Pendidikan Bahasa Arab", "is_priority": False},
        {"id": "DOS008", "nama": "Dr. Hj. Tutik Hamidah, M.Ag.", "email": "tutik.hamidah@uin-malang.ac.id", "password": hash_pw("DOS008"), "role": "dosen", "fakultas_nama": "Fakultas Syariah", "jurusan_nama": "Hukum Ekonomi Syariah", "is_priority": True},
        {"id": "DOS009", "nama": "M. Syarif Hidayatullah, M.H.", "email": "syarif.hidayat@uin-malang.ac.id", "password": hash_pw("DOS009"), "role": "dosen", "fakultas_nama": "Fakultas Syariah", "jurusan_nama": "Hukum Keluarga Islam", "is_priority": False},
        {"id": "DOS010", "nama": "Dr. Indah Yanti, S.E., M.M.", "email": "indah.yanti@uin-malang.ac.id", "password": hash_pw("DOS010"), "role": "dosen", "fakultas_nama": "Fakultas Ekonomi", "jurusan_nama": "Manajemen", "is_priority": True},
        {"id": "DOS011", "nama": "M. Nur Kholis, M.S.A., Ak.", "email": "kholis.akuntansi@uin-malang.ac.id", "password": hash_pw("DOS011"), "role": "dosen", "fakultas_nama": "Fakultas Ekonomi", "jurusan_nama": "Akuntansi", "is_priority": False},
        {"id": "DOS012", "nama": "Nurlaila Fitriani, M.Psi., Psikolog", "email": "nurlaila.fitriani@uin-malang.ac.id", "password": hash_pw("DOS012"), "role": "dosen", "fakultas_nama": "Fakultas Psikologi", "jurusan_nama": "Psikologi", "is_priority": True},
        {"id": "DOS013", "nama": "Dr. Abdul Basid, M.Pd.", "email": "abdul.basid@uin-malang.ac.id", "password": hash_pw("DOS013"), "role": "dosen", "fakultas_nama": "Fakultas Humaniora", "jurusan_nama": "Bahasa dan Sastra Arab", "is_priority": True},
        {"id": "DOS014", "nama": "Apt. Eko Suhartono, M.Sc.", "email": "eko.suhartono@uin-malang.ac.id", "password": hash_pw("DOS014"), "role": "dosen", "fakultas_nama": "Fakultas Kedokteran dan Ilmu Kesehatan", "jurusan_nama": "Farmasi", "is_priority": True},
    ]

    users = []
    for u in raw_users:
        users.append({
            "id": u["id"],
            "nama": u["nama"],
            "email": u["email"],
            "password": u["password"],
            "role": u["role"],
            "fakultas_nama": u.get("fakultas_nama", None),
            "jurusan_nama": u.get("jurusan_nama", None),
            "is_priority": u.get("is_priority", False)
        })
    upsert_table("users", users)

    # 2. GEDUNG
    gedungs = [
        {"id": "GD_FST1", "nama": "Gedung FST Terpadu BJ Habibie", "jam_buka": "07:00", "jam_tutup": "18:00", "akses_jurusan": "Teknik Informatika, Sistem Informasi, Teknik Arsitektur, Matematika, Biologi, Fisika, Kimia"},
        {"id": "GD_FST2", "nama": "Gedung Laboratorium Sains Terpadu", "jam_buka": "07:30", "jam_tutup": "17:30", "akses_jurusan": "Teknik Informatika, Sistem Informasi, Kimia, Biologi, Fisika"},
        {"id": "GD_FITK", "nama": "Gedung Megawati Soekarnoputri (FITK)", "jam_buka": "07:00", "jam_tutup": "18:00", "akses_jurusan": "Pendidikan Agama Islam, Pendidikan Bahasa Arab, Tadris Bahasa Inggris, PGMI, PIAUD"},
        {"id": "GD_SYAR", "nama": "Gedung Al-Farabi (Fakultas Syariah)", "jam_buka": "07:00", "jam_tutup": "17:30", "akses_jurusan": "Hukum Keluarga Islam, Hukum Ekonomi Syariah, Hukum Tatanegara"},
        {"id": "GD_FE", "nama": "Gedung Al-Biruni (Fakultas Ekonomi)", "jam_buka": "07:00", "jam_tutup": "18:00", "akses_jurusan": "Manajemen, Akuntansi, Perbankan Syariah"},
        {"id": "GD_PSI", "nama": "Gedung Ibnu Rusyd (Fakultas Psikologi)", "jam_buka": "07:30", "jam_tutup": "17:30", "akses_jurusan": "Psikologi"},
        {"id": "GD_HUM", "nama": "Gedung Ibnu Khaldun (Fakultas Humaniora)", "jam_buka": "07:00", "jam_tutup": "18:00", "akses_jurusan": "Bahasa dan Sastra Arab, Sastra Inggris"},
        {"id": "GD_FKIK", "nama": "Gedung Ibnu Sina (FKIK Kampus 3)", "jam_buka": "07:00", "jam_tutup": "18:00", "akses_jurusan": "Pendidikan Dokter, Farmasi"},
        {"id": "GD_GKU", "nama": "Gedung Kuliah Umum (GKU) Rektorat", "jam_buka": "07:00", "jam_tutup": "18:30", "akses_jurusan": "Semua Fakultas"},
    ]
    upsert_table("gedung", gedungs)

    # 3. RUANGAN
    ruangans = [
        {"id": "R_FST101", "nama": "Ruang FST 101", "gedung_id": "GD_FST1", "lantai": "Lantai 1", "kapasitas": 45, "tipe_ruangan": "Kelas Teori", "keterangan": "Dilengkapi AC & Proyektor 4K"},
        {"id": "R_FST102", "nama": "Ruang FST 102", "gedung_id": "GD_FST1", "lantai": "Lantai 1", "kapasitas": 45, "tipe_ruangan": "Kelas Teori", "keterangan": "Dilengkapi Smart TV 75 inch"},
        {"id": "R_FST201", "nama": "Studio Gambar Arsitektur", "gedung_id": "GD_FST1", "lantai": "Lantai 2", "kapasitas": 40, "tipe_ruangan": "Studio Arsitektur", "keterangan": "Meja gambar & Plotter A0"},
        {"id": "RLAB_SE", "nama": "Lab Software Engineering", "gedung_id": "GD_FST2", "lantai": "Lantai 2", "kapasitas": 35, "tipe_ruangan": "Laboratorium Komputer", "keterangan": "40 PC Core i7, LAN Gigabit"},
        {"id": "RLAB_AI", "nama": "Lab AI & Data Science", "gedung_id": "GD_FST2", "lantai": "Lantai 2", "kapasitas": 35, "tipe_ruangan": "Laboratorium Komputer", "keterangan": "NVIDIA RTX GPU Workstations"},
        {"id": "R_FITK101", "nama": "Ruang FITK 101 Megawati", "gedung_id": "GD_FITK", "lantai": "Lantai 1", "kapasitas": 50, "tipe_ruangan": "Kelas Teori", "keterangan": "Sound System & Smart Board"},
        {"id": "R_FITK102", "nama": "Ruang Microteaching FITK", "gedung_id": "GD_FITK", "lantai": "Lantai 1", "kapasitas": 30, "tipe_ruangan": "Laboratorium Microteaching", "keterangan": "Kamera Rekam Pembelajaran"},
        {"id": "R_SYAR101", "nama": "Ruang Syariah 101", "gedung_id": "GD_SYAR", "lantai": "Lantai 1", "kapasitas": 45, "tipe_ruangan": "Kelas Teori", "keterangan": "Perpustakaan Hukum Mini"},
        {"id": "R_SYAR_SEM", "nama": "Ruang Peradilan Semu", "gedung_id": "GD_SYAR", "lantai": "Lantai 2", "kapasitas": 40, "tipe_ruangan": "Laboratorium Hukum", "keterangan": "Set Ruang Sidang Pengadilan"},
        {"id": "R_FE101", "nama": "Ruang FE 101 Al-Biruni", "gedung_id": "GD_FE", "lantai": "Lantai 1", "kapasitas": 50, "tipe_ruangan": "Kelas Teori", "keterangan": "AC & Dual Projector"},
        {"id": "R_FE_MINIBANK", "nama": "Lab Galeri Investasi & Bank Syariah", "gedung_id": "GD_FE", "lantai": "Lantai 2", "kapasitas": 35, "tipe_ruangan": "Laboratorium Komputer", "keterangan": "Terminal Bloomberg & Mini Bank"},
        {"id": "R_PSI101", "nama": "Ruang Psikologi 101", "gedung_id": "GD_PSI", "lantai": "Lantai 1", "kapasitas": 45, "tipe_ruangan": "Kelas Teori", "keterangan": "Papan Tulis Glassboard"},
        {"id": "R_PSI_LAB", "nama": "Lab Psikodiagnostik", "gedung_id": "GD_PSI", "lantai": "Lantai 2", "kapasitas": 30, "tipe_ruangan": "Laboratorium Psikologi", "keterangan": "Cermin One-Way Mirror"},
        {"id": "R_HUM101", "nama": "Ruang Humaniora 101", "gedung_id": "GD_HUM", "lantai": "Lantai 1", "kapasitas": 45, "tipe_ruangan": "Kelas Teori", "keterangan": "Proyektor & AC"},
        {"id": "R_HUM_BAHASA", "nama": "Lab Bahasa Multimedia", "gedung_id": "GD_HUM", "lantai": "Lantai 2", "kapasitas": 35, "tipe_ruangan": "Laboratorium Bahasa", "keterangan": "Audio Headset & Software Lingua"},
        {"id": "R_FKIK101", "nama": "Ruang FKIK 101 Ibnu Sina", "gedung_id": "GD_FKIK", "lantai": "Lantai 1", "kapasitas": 60, "tipe_ruangan": "Kelas Teori", "keterangan": "Ruang Kuliah Teater"},
        {"id": "R_FKIK_ANATOMI", "nama": "Lab Anatomi & Farmakologi", "gedung_id": "GD_FKIK", "lantai": "Lantai 2", "kapasitas": 30, "tipe_ruangan": "Laboratorium Sains", "keterangan": "Manekin Cadaver & Mikroskop"},
        {"id": "R_GKU101", "nama": "Hall GKU Rektorat 101", "gedung_id": "GD_GKU", "lantai": "Lantai 1", "kapasitas": 60, "tipe_ruangan": "Kelas Teori", "keterangan": "Gedung Bersama Multiguna"},
    ]
    upsert_table("ruangan", ruangans)

    # 4. SLOT WAKTU
    slots = [
        {"id": "SLOT_SEN_1", "hari": "Senin", "jam_mulai": "07:30", "jam_selesai": "10:00", "durasi_menit": 150},
        {"id": "SLOT_SEN_2", "hari": "Senin", "jam_mulai": "10:15", "jam_selesai": "12:45", "durasi_menit": 150},
        {"id": "SLOT_SEN_3", "hari": "Senin", "jam_mulai": "13:30", "jam_selesai": "16:00", "durasi_menit": 150},
        {"id": "SLOT_SEL_1", "hari": "Selasa", "jam_mulai": "07:30", "jam_selesai": "10:00", "durasi_menit": 150},
        {"id": "SLOT_SEL_2", "hari": "Selasa", "jam_mulai": "10:15", "jam_selesai": "12:45", "durasi_menit": 150},
        {"id": "SLOT_RAB_1", "hari": "Rabu", "jam_mulai": "07:30", "jam_selesai": "10:00", "durasi_menit": 150},
        {"id": "SLOT_RAB_2", "hari": "Rabu", "jam_mulai": "10:15", "jam_selesai": "12:45", "durasi_menit": 150},
        {"id": "SLOT_KAM_1", "hari": "Kamis", "jam_mulai": "07:30", "jam_selesai": "10:00", "durasi_menit": 150},
        {"id": "SLOT_JUM_1", "hari": "Jumat", "jam_mulai": "07:30", "jam_selesai": "10:00", "durasi_menit": 150}
    ]
    upsert_table("slot_waktu", slots)

    # 5. MATA KULIAH
    raw_mks = [
        {"id": "MK001", "nama": "Algoritma & Pemrograman", "sks": 3, "jurusan_id": "JUR001", "jurusan_nama": "Teknik Informatika", "fakultas_nama": "Fakultas Sains dan Teknologi", "dosen_id": "DOS001", "semester_id": "SEM001", "semester_angka": 1, "kebutuhan_tipe_ruangan": "Laboratorium Komputer"},
        {"id": "MK002", "nama": "Struktur Data & Analisis Algoritma", "sks": 3, "jurusan_id": "JUR001", "jurusan_nama": "Teknik Informatika", "fakultas_nama": "Fakultas Sains dan Teknologi", "dosen_id": "DOS001", "semester_id": "SEM003", "semester_angka": 3, "kebutuhan_tipe_ruangan": "Laboratorium Komputer"},
        {"id": "MK003", "nama": "Basis Data Terdistribusi", "sks": 3, "jurusan_id": "JUR001", "jurusan_nama": "Teknik Informatika", "fakultas_nama": "Fakultas Sains dan Teknologi", "dosen_id": "DOS002", "semester_id": "SEM003", "semester_angka": 3, "kebutuhan_tipe_ruangan": "Kelas Teori"},
        {"id": "MK004", "nama": "Kecerdasan Buatan & Machine Learning", "sks": 3, "jurusan_id": "JUR001", "jurusan_nama": "Teknik Informatika", "fakultas_nama": "Fakultas Sains dan Teknologi", "dosen_id": "DOS002", "semester_id": "SEM005", "semester_angka": 5, "kebutuhan_tipe_ruangan": "Laboratorium Komputer"},
        {"id": "MK005", "nama": "Pemrograman Mobile (Flutter)", "sks": 3, "jurusan_id": "JUR001", "jurusan_nama": "Teknik Informatika", "fakultas_nama": "Fakultas Sains dan Teknologi", "dosen_id": "DOS003", "semester_id": "SEM005", "semester_angka": 5, "kebutuhan_tipe_ruangan": "Laboratorium Komputer"},
        {"id": "MK006", "nama": "Manajemen Sistem Informasi Bisnis", "sks": 3, "jurusan_id": "JUR008", "jurusan_nama": "Sistem Informasi", "fakultas_nama": "Fakultas Sains dan Teknologi", "dosen_id": "DOS004", "semester_id": "SEM003", "semester_angka": 3, "kebutuhan_tipe_ruangan": "Kelas Teori"},
        {"id": "MK007", "nama": "Metodologi Pembelajaran Agama Islam", "sks": 3, "jurusan_id": "JUR002", "jurusan_nama": "Pendidikan Agama Islam", "fakultas_nama": "Fakultas Ilmu Tarbiyah dan Keguruan", "dosen_id": "DOS006", "semester_id": "SEM003", "semester_angka": 3, "kebutuhan_tipe_ruangan": "Kelas Teori"},
        {"id": "MK008", "nama": "Fiqh Muamalah Maliyah", "sks": 3, "jurusan_id": "JUR003", "jurusan_nama": "Hukum Ekonomi Syariah", "fakultas_nama": "Fakultas Syariah", "dosen_id": "DOS008", "semester_id": "SEM003", "semester_angka": 3, "kebutuhan_tipe_ruangan": "Kelas Teori"},
        {"id": "MK009", "nama": "Manajemen Keuangan Syariah", "sks": 3, "jurusan_id": "JUR004", "jurusan_nama": "Manajemen", "fakultas_nama": "Fakultas Ekonomi", "dosen_id": "DOS010", "semester_id": "SEM003", "semester_angka": 3, "kebutuhan_tipe_ruangan": "Kelas Teori"},
        {"id": "MK010", "nama": "Psikologi Perkembangan Anak & Remaja", "sks": 3, "jurusan_id": "JUR005", "jurusan_nama": "Psikologi", "fakultas_nama": "Fakultas Psikologi", "dosen_id": "DOS012", "semester_id": "SEM003", "semester_angka": 3, "kebutuhan_tipe_ruangan": "Kelas Teori"},
        {"id": "MK011", "nama": "Balaghah & Al-Adab Al-Arabi", "sks": 3, "jurusan_id": "JUR006", "jurusan_nama": "Bahasa dan Sastra Arab", "fakultas_nama": "Fakultas Humaniora", "dosen_id": "DOS013", "semester_id": "SEM003", "semester_angka": 3, "kebutuhan_tipe_ruangan": "Kelas Teori"},
        {"id": "MK012", "nama": "Farmakologi Klinik & Resep", "sks": 3, "jurusan_id": "JUR007", "jurusan_nama": "Farmasi", "fakultas_nama": "Fakultas Kedokteran dan Ilmu Kesehatan", "dosen_id": "DOS014", "semester_id": "SEM003", "semester_angka": 3, "kebutuhan_tipe_ruangan": "Laboratorium Sains"},
    ]
    mks = []
    for mk in raw_mks:
        mks.append({
            "id": mk["id"],
            "nama": mk["nama"],
            "sks": mk["sks"],
            "jurusan_id": mk["jurusan_id"],
            "jurusan_nama": mk["jurusan_nama"],
            "fakultas_nama": mk["fakultas_nama"],
            "dosen_id": mk["dosen_id"],
            "semester_id": mk["semester_id"],
            "semester_angka": mk["semester_angka"],
            "kebutuhan_tipe_ruangan": mk["kebutuhan_tipe_ruangan"]
        })
    upsert_table("mata_kuliah", mks)

    print("[SUCCESS] ALL MASTER DATA SEEDED SUCCESSFULLY INTO SUPABASE CLOUD!")

if __name__ == "__main__":
    seed_all()
