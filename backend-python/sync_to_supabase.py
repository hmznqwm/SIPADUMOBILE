import sqlite3
import requests
import json
import bcrypt

SUPABASE_URL = "https://wxrsstdnlpzonqcaqagv.supabase.co"
SUPABASE_KEY = "sb_secret_" + "jGMLt3WS6-BcxV9bn6LHww_V8gS3wus"
HEADERS = {
    "apikey": SUPABASE_KEY,
    "Authorization": f"Bearer {SUPABASE_KEY}",
    "Content-Type": "application/json",
    "Prefer": "resolution=merge-duplicates"
}

def hash_pw(pw):
    return bcrypt.hashpw(pw.encode("utf-8"), bcrypt.gensalt()).decode("utf-8")

# 1. USERS & DOSEN UIN MALANG
users_data = [
    # Admins
    {"id": "ADM001", "nama": "Hamizan Qowiem", "email": "hamizanqowiem90@gmail.com", "role": "admin", "fakultas_nama": "Fakultas Sains dan Teknologi", "jurusan_id": "JUR001", "jurusan_nama": "Teknik Informatika", "is_priority": True, "matkul_nama": "Etika Profesi & Kepemimpinan IT"},
    {"id": "ADM002", "nama": "Operator Akademik Pusat", "email": "operator.akademik@uin-malang.ac.id", "role": "admin", "fakultas_nama": "Fakultas Sains dan Teknologi", "jurusan_id": "JUR001", "jurusan_nama": "Teknik Informatika", "is_priority": False, "matkul_nama": "Tata Kelola Sistem Informasi"},
    
    # Dekan 7 Fakultas
    {"id": "DEK001", "nama": "Prof. Dr. Ir. Budi Santoso, M.Sc.", "email": "dekan.fst@uin-malang.ac.id", "role": "dekan", "fakultas_nama": "Fakultas Sains dan Teknologi", "jurusan_id": "JUR001", "jurusan_nama": "Teknik Informatika", "is_priority": True, "matkul_nama": "Sistem Informasi Enterprise & Audit TI"},
    {"id": "DEK002", "nama": "Prof. Dr. H. Nur Ali, M.Pd.", "email": "dekan.fitk@uin-malang.ac.id", "role": "dekan", "fakultas_nama": "Fakultas Ilmu Tarbiyah dan Keguruan", "jurusan_id": "JUR002", "jurusan_nama": "Pendidikan Agama Islam", "is_priority": True, "matkul_nama": "Pengembangan Kurikulum Pendidikan Islam"},
    {"id": "DEK003", "nama": "Prof. Dr. H. Saifullah, S.H., M.Hum.", "email": "dekan.syariah@uin-malang.ac.id", "role": "dekan", "fakultas_nama": "Fakultas Syariah", "jurusan_id": "JUR003", "jurusan_nama": "Hukum Ekonomi Syariah", "is_priority": True, "matkul_nama": "Hukum Tata Negara Islam (Siyasah Syari'iyyah)"},
    {"id": "DEK004", "nama": "Prof. Dr. H. Misbahul Munir, M.Si.", "email": "dekan.fe@uin-malang.ac.id", "role": "dekan", "fakultas_nama": "Fakultas Ekonomi", "jurusan_id": "JUR004", "jurusan_nama": "Manajemen", "is_priority": True, "matkul_nama": "Manajemen Strategik Bisnis Syariah"},
    {"id": "DEK005", "nama": "Prof. Dr. H. Rifa'i Husein, M.Si.", "email": "dekan.psikologi@uin-malang.ac.id", "role": "dekan", "fakultas_nama": "Fakultas Psikologi", "jurusan_id": "JUR005", "jurusan_nama": "Psikologi", "is_priority": True, "matkul_nama": "Psikologi Kepemimpinan & Organisasi"},
    {"id": "DEK006", "nama": "Dr. M. Faisol, M.Ag.", "email": "dekan.humaniora@uin-malang.ac.id", "role": "dekan", "fakultas_nama": "Fakultas Humaniora", "jurusan_id": "JUR006", "jurusan_nama": "Bahasa dan Sastra Arab", "is_priority": True, "matkul_nama": "Kritik Sastra Arab & Hermeneutika"},
    {"id": "DEK007", "nama": "Prof. Dr. dr. Yuyun Yueniwati, M.Kes., Sp.Rad(K).", "email": "dekan.fkik@uin-malang.ac.id", "role": "dekan", "fakultas_nama": "Fakultas Kedokteran dan Ilmu Kesehatan", "jurusan_id": "JUR007", "jurusan_nama": "Pendidikan Dokter", "is_priority": True, "matkul_nama": "Radiologi Kedokteran Klinis"},

    # Kaprodi / Kajur 7 Fakultas
    {"id": "KAJ001", "nama": "Dr. Eng. Ahmad Fauzi, S.T., M.T.", "email": "kaprodi.ti@uin-malang.ac.id", "role": "kajur", "fakultas_nama": "Fakultas Sains dan Teknologi", "jurusan_id": "JUR001", "jurusan_nama": "Teknik Informatika", "is_priority": True, "matkul_nama": "Jaringan Komputer & Cyber Security"},
    {"id": "KAJ002", "nama": "Dr. H. Muhammad Munir, M.Ag.", "email": "kaprodi.pai@uin-malang.ac.id", "role": "kajur", "fakultas_nama": "Fakultas Ilmu Tarbiyah dan Keguruan", "jurusan_id": "JUR002", "jurusan_nama": "Pendidikan Agama Islam", "is_priority": True, "matkul_nama": "Filsafat Pendidikan Islam Modern"},
    {"id": "KAJ003", "nama": "Dr. H. Burhanuddin, M.H.", "email": "kaprodi.hes@uin-malang.ac.id", "role": "kajur", "fakultas_nama": "Fakultas Syariah", "jurusan_id": "JUR003", "jurusan_nama": "Hukum Ekonomi Syariah", "is_priority": True, "matkul_nama": "Hukum Perdata Islam Kontemporer"},
    {"id": "KAJ004", "nama": "Dr. H. Salim Al Idrus, M.M.", "email": "kaprodi.manajemen@uin-malang.ac.id", "role": "kajur", "fakultas_nama": "Fakultas Ekonomi", "jurusan_id": "JUR004", "jurusan_nama": "Manajemen", "is_priority": True, "matkul_nama": "Kewirausahaan & Inkubasi Bisnis"},
    {"id": "KAJ005", "nama": "Dr. Fathul Lubab, M.Si.", "email": "kaprodi.psikologi@uin-malang.ac.id", "role": "kajur", "fakultas_nama": "Fakultas Psikologi", "jurusan_id": "JUR005", "jurusan_nama": "Psikologi", "is_priority": True, "matkul_nama": "Psikometri & Pengukuran Bakat"},
    {"id": "KAJ006", "nama": "Dr. Mundi Rahayu, M.Hum.", "email": "kaprodi.sastrainggris@uin-malang.ac.id", "role": "kajur", "fakultas_nama": "Fakultas Humaniora", "jurusan_id": "JUR006", "jurusan_nama": "Sastra Inggris", "is_priority": True, "matkul_nama": "Linguistik Terapan & Kajian Budaya"},
    {"id": "KAJ007", "nama": "dr. Christyana Rahayuningsih, M.Biomed.", "email": "kaprodi.kedokteran@uin-malang.ac.id", "role": "kajur", "fakultas_nama": "Fakultas Kedokteran dan Ilmu Kesehatan", "jurusan_id": "JUR007", "jurusan_nama": "Pendidikan Dokter", "is_priority": True, "matkul_nama": "Histologi Kedokteran Dasar"},

    # Dosen Pengajar UIN Malang
    {"id": "DOS001", "nama": "Dr. Hendra Gunawan, S.Kom., M.Cs.", "email": "hendra.gunawan@uin-malang.ac.id", "role": "dosen", "fakultas_nama": "Fakultas Sains dan Teknologi", "jurusan_id": "JUR001", "jurusan_nama": "Teknik Informatika", "is_priority": False, "matkul_nama": "Algoritma & Pemrograman, Struktur Data & Analisis Algoritma"},
    {"id": "DOS002", "nama": "Siti Rahmawati, S.T., M.Kom.", "email": "siti.rahmawati@uin-malang.ac.id", "role": "dosen", "fakultas_nama": "Fakultas Sains dan Teknologi", "jurusan_id": "JUR001", "jurusan_nama": "Teknik Informatika", "is_priority": True, "matkul_nama": "Basis Data Terdistribusi, Kecerdasan Buatan & Machine Learning"},
    {"id": "DOS003", "nama": "Rian Hidayat, M.Kom.", "email": "rian.hidayat@uin-malang.ac.id", "role": "dosen", "fakultas_nama": "Fakultas Sains dan Teknologi", "jurusan_id": "JUR001", "jurusan_nama": "Teknik Informatika", "is_priority": False, "matkul_nama": "Pemrograman Mobile (Flutter)"},
    {"id": "DOS004", "nama": "Dr. Muhammad Ali, M.T.", "email": "muhammad.ali@uin-malang.ac.id", "role": "dosen", "fakultas_nama": "Fakultas Sains dan Teknologi", "jurusan_id": "JUR001", "jurusan_nama": "Sistem Informasi", "is_priority": True, "matkul_nama": "Manajemen Sistem Informasi Bisnis"},
    {"id": "DOS005", "nama": "Dr. Ir. Nadhir, M.T.", "email": "nadhir@uin-malang.ac.id", "role": "dosen", "fakultas_nama": "Fakultas Sains dan Teknologi", "jurusan_id": "JUR001", "jurusan_nama": "Teknik Arsitektur", "is_priority": False, "matkul_nama": "Studio Perancangan Arsitektur 1"},
    {"id": "DOS006", "nama": "Dr. Hj. Mamluatun Ni'mah, M.Ag.", "email": "mamluatun@uin-malang.ac.id", "role": "dosen", "fakultas_nama": "Fakultas Ilmu Tarbiyah dan Keguruan", "jurusan_id": "JUR002", "jurusan_nama": "Pendidikan Agama Islam", "is_priority": True, "matkul_nama": "Metodologi Pembelajaran Agama Islam"},
    {"id": "DOS007", "nama": "Ahmad Fikri, M.Pd.", "email": "ahmad.fikri@uin-malang.ac.id", "role": "dosen", "fakultas_nama": "Fakultas Ilmu Tarbiyah dan Keguruan", "jurusan_id": "JUR002", "jurusan_nama": "Pendidikan Bahasa Arab", "is_priority": False, "matkul_nama": "Kemahiran Berbicara Bahasa Arab (Maharah Kalam)"},
    {"id": "DOS008", "nama": "Dr. Hj. Tutik Hamidah, M.Ag.", "email": "tutik.hamidah@uin-malang.ac.id", "role": "dosen", "fakultas_nama": "Fakultas Syariah", "jurusan_id": "JUR003", "jurusan_nama": "Hukum Ekonomi Syariah", "is_priority": True, "matkul_nama": "Fiqh Muamalah Maliyah"},
    {"id": "DOS009", "nama": "M. Syarif Hidayatullah, M.H.", "email": "syarif.hidayat@uin-malang.ac.id", "role": "dosen", "fakultas_nama": "Fakultas Syariah", "jurusan_id": "JUR003", "jurusan_nama": "Hukum Keluarga Islam", "is_priority": False, "matkul_nama": "Hukum Perkawinan & Waris Islam"},
    {"id": "DOS010", "nama": "Dr. Indah Yanti, S.E., M.M.", "email": "indah.yanti@uin-malang.ac.id", "role": "dosen", "fakultas_nama": "Fakultas Ekonomi", "jurusan_id": "JUR004", "jurusan_nama": "Manajemen", "is_priority": True, "matkul_nama": "Manajemen Keuangan Syariah"},
    {"id": "DOS011", "nama": "M. Nur Kholis, M.S.A., Ak.", "email": "kholis.akuntansi@uin-malang.ac.id", "role": "dosen", "fakultas_nama": "Fakultas Ekonomi", "jurusan_id": "JUR004", "jurusan_nama": "Akuntansi", "is_priority": False, "matkul_nama": "Akuntansi Forensik & Audit Lembaga Syariah"},
    {"id": "DOS012", "nama": "Nurlaila Fitriani, M.Psi., Psikolog", "email": "nurlaila.fitriani@uin-malang.ac.id", "role": "dosen", "fakultas_nama": "Fakultas Psikologi", "jurusan_id": "JUR005", "jurusan_nama": "Psikologi", "is_priority": True, "matkul_nama": "Psikologi Perkembangan Anak & Remaja"},
    {"id": "DOS013", "nama": "Dr. Abdul Basid, M.Pd.", "email": "abdul.basid@uin-malang.ac.id", "role": "dosen", "fakultas_nama": "Fakultas Humaniora", "jurusan_id": "JUR006", "jurusan_nama": "Bahasa dan Sastra Arab", "is_priority": True, "matkul_nama": "Balaghah & Al-Adab Al-Arabi"},
    {"id": "DOS014", "nama": "Apt. Eko Suhartono, M.Sc.", "email": "eko.suhartono@uin-malang.ac.id", "role": "dosen", "fakultas_nama": "Fakultas Kedokteran dan Ilmu Kesehatan", "jurusan_id": "JUR007", "jurusan_nama": "Farmasi", "is_priority": True, "matkul_nama": "Farmakologi Klinik & Resep"},
    {"id": "DSN90", "nama": "Hamizan Qowiem", "email": "hamizanqowiem90@gmail.com", "role": "dosen", "fakultas_nama": "Fakultas Sains dan Teknologi", "jurusan_id": "JUR001", "jurusan_nama": "Teknik Informatika", "is_priority": True, "matkul_nama": "Algoritma & Pemrograman, Basis Data Terdistribusi"}
]

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

# 5. MATA KULIAH
mks = [
    {"id": "MK001", "nama": "Algoritma & Pemrograman", "sks": 3, "dosen_id": "DOS001", "dosen_nama": "Dr. Hendra Gunawan, S.Kom., M.Cs.", "jurusan_id": "JUR001", "jurusan_nama": "Teknik Informatika", "fakultas_nama": "Fakultas Sains dan Teknologi"},
    {"id": "MK002", "nama": "Struktur Data & Analisis Algoritma", "sks": 3, "dosen_id": "DOS001", "dosen_nama": "Dr. Hendra Gunawan, S.Kom., M.Cs.", "jurusan_id": "JUR001", "jurusan_nama": "Teknik Informatika", "fakultas_nama": "Fakultas Sains dan Teknologi"},
    {"id": "MK003", "nama": "Basis Data Terdistribusi", "sks": 3, "dosen_id": "DOS002", "dosen_nama": "Siti Rahmawati, S.T., M.Kom.", "jurusan_id": "JUR001", "jurusan_nama": "Teknik Informatika", "fakultas_nama": "Fakultas Sains dan Teknologi"},
    {"id": "MK004", "nama": "Kecerdasan Buatan & Machine Learning", "sks": 3, "dosen_id": "DOS002", "dosen_nama": "Siti Rahmawati, S.T., M.Kom.", "jurusan_id": "JUR001", "jurusan_nama": "Teknik Informatika", "fakultas_nama": "Fakultas Sains dan Teknologi"},
    {"id": "MK005", "nama": "Pemrograman Mobile (Flutter)", "sks": 3, "dosen_id": "DOS003", "dosen_nama": "Rian Hidayat, M.Kom.", "jurusan_id": "JUR001", "jurusan_nama": "Teknik Informatika", "fakultas_nama": "Fakultas Sains dan Teknologi"},
    {"id": "MK006", "nama": "Manajemen Sistem Informasi Bisnis", "sks": 3, "dosen_id": "DOS004", "dosen_nama": "Dr. Muhammad Ali, M.T.", "jurusan_id": "JUR001", "jurusan_nama": "Sistem Informasi", "fakultas_nama": "Fakultas Sains dan Teknologi"},
    {"id": "MK007", "nama": "Metodologi Pembelajaran Agama Islam", "sks": 3, "dosen_id": "DOS006", "dosen_nama": "Dr. Hj. Mamluatun Ni'mah, M.Ag.", "jurusan_id": "JUR002", "jurusan_nama": "Pendidikan Agama Islam", "fakultas_nama": "Fakultas Ilmu Tarbiyah dan Keguruan"},
    {"id": "MK008", "nama": "Fiqh Muamalah Maliyah", "sks": 3, "dosen_id": "DOS008", "dosen_nama": "Dr. Hj. Tutik Hamidah, M.Ag.", "jurusan_id": "JUR003", "jurusan_nama": "Hukum Ekonomi Syariah", "fakultas_nama": "Fakultas Syariah"},
    {"id": "MK009", "nama": "Manajemen Keuangan Syariah", "sks": 3, "dosen_id": "DOS010", "dosen_nama": "Dr. Indah Yanti, S.E., M.M.", "jurusan_id": "JUR004", "jurusan_nama": "Manajemen", "fakultas_nama": "Fakultas Ekonomi"},
    {"id": "MK010", "nama": "Psikologi Perkembangan Anak & Remaja", "sks": 3, "dosen_id": "DOS012", "dosen_nama": "Nurlaila Fitriani, M.Psi., Psikolog", "jurusan_id": "JUR005", "jurusan_nama": "Psikologi", "fakultas_nama": "Fakultas Psikologi"},
    {"id": "MK011", "nama": "Balaghah & Al-Adab Al-Arabi", "sks": 3, "dosen_id": "DOS013", "dosen_nama": "Dr. Abdul Basid, M.Pd.", "jurusan_id": "JUR006", "jurusan_nama": "Bahasa dan Sastra Arab", "fakultas_nama": "Fakultas Humaniora"},
    {"id": "MK012", "nama": "Farmakologi Klinik & Resep", "sks": 3, "dosen_id": "DOS014", "dosen_nama": "Apt. Eko Suhartono, M.Sc.", "jurusan_id": "JUR007", "jurusan_nama": "Farmasi", "fakultas_nama": "Fakultas Kedokteran dan Ilmu Kesehatan"},
]

# 6. NOTIFIKASI
notifications = [
    {"id": "NOTIF_001", "user_id": "DOS001", "title": "Window Pengisian Jadwal Dibuka", "message": "Admin UIN Malang telah membuka periode pengajuan ketersediaan mengajar semester Ganjil 2026/2027.", "type": "info", "is_read": False},
    {"id": "NOTIF_002", "user_id": "DOS001", "title": "Jadwal Kuliah Resmi Terbit", "message": "Seluruh jadwal perkuliahan 7 Fakultas UIN Malang telah diverifikasi KaProdi & disetujui Dekan.", "type": "success", "is_read": False},
    {"id": "NOTIF_003", "user_id": "ADM001", "title": "Smart CSP Backtracking Selesai", "message": "Penyusunan jadwal otomatis 7 Fakultas UIN Malang berhasil diselesaikan tanpa bentrok.", "type": "success", "is_read": False},
]

print("1. Syncing users to Supabase...")
for u in users_data:
    payload = {
        "id": u["id"],
        "nama": u["nama"],
        "email": u["email"],
        "password": hash_pw(u["id"]),
        "role": u["role"],
        "jurusan_id": u.get("jurusan_id", "JUR001"),
        "jurusan_nama": u.get("jurusan_nama"),
        "fakultas_nama": u.get("fakultas_nama"),
        "is_priority": u.get("is_priority", False),
        "matkul_nama": u.get("matkul_nama")
    }
    r = requests.post(f"{SUPABASE_URL}/rest/v1/users", headers=HEADERS, json=payload)
print("Users sync finished!")

print("2. Syncing gedungs to Supabase...")
r = requests.post(f"{SUPABASE_URL}/rest/v1/gedung", headers=HEADERS, json=gedungs)
print(f"Gedungs sync finished: HTTP {r.status_code}")

print("3. Syncing ruangans to Supabase...")
r = requests.post(f"{SUPABASE_URL}/rest/v1/ruangan", headers=HEADERS, json=ruangans)
print(f"Ruangans sync finished: HTTP {r.status_code}")

print("4. Syncing slots to Supabase...")
r = requests.post(f"{SUPABASE_URL}/rest/v1/slot_waktu", headers=HEADERS, json=slots)
print(f"Slots sync finished: HTTP {r.status_code}")

print("5. Syncing mata kuliah to Supabase...")
r = requests.post(f"{SUPABASE_URL}/rest/v1/mata_kuliah", headers=HEADERS, json=mks)
print(f"Mata Kuliah sync finished: HTTP {r.status_code}")

print("6. Syncing notifications to Supabase...")
r = requests.post(f"{SUPABASE_URL}/rest/v1/notifications", headers=HEADERS, json=notifications)
print(f"Notifications sync finished: HTTP {r.status_code}")

# Also populate local SQLite
conn = sqlite3.connect("smartschedule.db")
c = conn.cursor()

# Insert or ignore users
for u in users_data:
    c.execute("""
        INSERT INTO users (id, nama, email, password, role, jurusan_id, jurusan_nama, fakultas_nama, is_priority, matkul_nama)
        VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?)
        ON CONFLICT(id) DO UPDATE SET
            nama=excluded.nama, email=excluded.email, role=excluded.role,
            jurusan_id=excluded.jurusan_id, jurusan_nama=excluded.jurusan_nama,
            fakultas_nama=excluded.fakultas_nama, is_priority=excluded.is_priority,
            matkul_nama=excluded.matkul_nama
    """, (u["id"], u["nama"], u["email"], hash_pw(u["id"]), u["role"], u.get("jurusan_id", "JUR001"), u.get("jurusan_nama"), u.get("fakultas_nama"), u.get("is_priority", False), u.get("matkul_nama")))

# Gedung
for g in gedungs:
    c.execute("""
        INSERT INTO gedung (id, nama, jam_buka, jam_tutup, akses_jurusan)
        VALUES (?, ?, ?, ?, ?)
        ON CONFLICT(id) DO UPDATE SET nama=excluded.nama, jam_buka=excluded.jam_buka, jam_tutup=excluded.jam_tutup, akses_jurusan=excluded.akses_jurusan
    """, (g["id"], g["nama"], g["jam_buka"], g["jam_tutup"], g["akses_jurusan"]))

# Ruangan
for r_item in ruangans:
    c.execute("""
        INSERT INTO ruangan (id, nama, gedung_id, lantai, kapasitas, tipe_ruangan, keterangan)
        VALUES (?, ?, ?, ?, ?, ?, ?)
        ON CONFLICT(id) DO UPDATE SET nama=excluded.nama, gedung_id=excluded.gedung_id, lantai=excluded.lantai, kapasitas=excluded.kapasitas, tipe_ruangan=excluded.tipe_ruangan, keterangan=excluded.keterangan
    """, (r_item["id"], r_item["nama"], r_item["gedung_id"], r_item["lantai"], r_item["kapasitas"], r_item["tipe_ruangan"], r_item["keterangan"]))

# Slot
for s in slots:
    c.execute("""
        INSERT INTO slot_waktu (id, hari, jam_mulai, jam_selesai, durasi_menit)
        VALUES (?, ?, ?, ?, ?)
        ON CONFLICT(id) DO UPDATE SET hari=excluded.hari, jam_mulai=excluded.jam_mulai, jam_selesai=excluded.jam_selesai, durasi_menit=excluded.durasi_menit
    """, (s["id"], s["hari"], s["jam_mulai"], s["jam_selesai"], s["durasi_menit"]))

# Mata Kuliah
for m in mks:
    c.execute("""
        INSERT INTO mata_kuliah (id, nama, sks, dosen_id, dosen_nama, jurusan_id, jurusan_nama, fakultas_nama)
        VALUES (?, ?, ?, ?, ?, ?, ?, ?)
        ON CONFLICT(id) DO UPDATE SET nama=excluded.nama, sks=excluded.sks, dosen_id=excluded.dosen_id, dosen_nama=excluded.dosen_nama, jurusan_id=excluded.jurusan_id, jurusan_nama=excluded.jurusan_nama, fakultas_nama=excluded.fakultas_nama
    """, (m["id"], m["nama"], m["sks"], m["dosen_id"], m["dosen_nama"], m["jurusan_id"], m["jurusan_nama"], m["fakultas_nama"]))

conn.commit()
print("Local SQLite synchronized successfully!")
