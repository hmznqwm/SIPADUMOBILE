import requests
import json
import random
import time

URL = "https://wxrsstdnlpzonqcaqagv.supabase.co/rest/v1"
KEY = "sb_secret_" + "jGMLt3WS6-BcxV9bn6LHww_V8gS3wus"
HEADERS = {
    "apikey": KEY,
    "Authorization": f"Bearer {KEY}",
    "Content-Type": "application/json",
    "Prefer": "resolution=merge-duplicates"
}

print("Memulai injeksi data pengujian skala besar ke Supabase Cloud...")

# 1. CLEAR JADWAL FINAL
print("\n[1/7] Menghapus data jadwal_final (karena status belum final)...")
del_jf = requests.delete(f"{URL}/jadwal_final?id=not.is.null", headers={"apikey": KEY, "Authorization": f"Bearer {KEY}"})
print(f"Jadwal final direset: {del_jf.status_code}")

# 2. SEED GEDUNG (15 Gedung)
print("\n[2/7] Menyiapkan data Gedung (15 Gedung Kampus)...")
gedung_data = [
    {"id": "GDG001", "nama": "Gedung BJ Habibie (FST Terpadu)", "jam_buka": "07:00", "jam_tutup": "18:30", "akses_jurusan": "Teknik Informatika"},
    {"id": "GDG002", "nama": "Gedung Megawati Soekarnoputri (FITK)", "jam_buka": "07:00", "jam_tutup": "18:30", "akses_jurusan": "Pendidikan Agama Islam"},
    {"id": "GDG003", "nama": "Gedung Al-Farabi (Fakultas Syariah)", "jam_buka": "07:00", "jam_tutup": "18:30", "akses_jurusan": "Hukum Ekonomi Syariah"},
    {"id": "GDG004", "nama": "Gedung Al-Biruni (Fakultas Ekonomi)", "jam_buka": "07:00", "jam_tutup": "18:30", "akses_jurusan": "Manajemen"},
    {"id": "GDG005", "nama": "Gedung Ibnu Khaldun (Fakultas Humaniora)", "jam_buka": "07:00", "jam_tutup": "18:30", "akses_jurusan": "Bahasa dan Sastra Arab"},
    {"id": "GDG006", "nama": "Gedung Ibnu Rusyd (Fakultas Psikologi)", "jam_buka": "07:00", "jam_tutup": "18:30", "akses_jurusan": "Psikologi"},
    {"id": "GDG007", "nama": "Gedung Ibnu Sina (FKIK Kampus 3)", "jam_buka": "07:00", "jam_tutup": "18:30", "akses_jurusan": "Pendidikan Dokter"},
    {"id": "GDG008", "nama": "Gedung Kuliah Umum (GKU) Rektorat", "jam_buka": "07:00", "jam_tutup": "21:00", "akses_jurusan": "Semua Jurusan"},
    {"id": "GDG009", "nama": "Gedung Laboratorium Komputer Terpadu", "jam_buka": "07:00", "jam_tutup": "20:00", "akses_jurusan": "Teknik Informatika"},
    {"id": "GDG010", "nama": "Gedung Laboratorium Sains & Farmasi", "jam_buka": "07:00", "jam_tutup": "18:00", "akses_jurusan": "Farmasi"},
    {"id": "GDG011", "nama": "Gedung Perpustakaan Pusat KH. Abdurrahman Wahid", "jam_buka": "08:00", "jam_tutup": "20:00", "akses_jurusan": "Semua Jurusan"},
    {"id": "GDG012", "nama": "Gedung Pascasarjana KH. Oesman Mansoer", "jam_buka": "07:30", "jam_tutup": "21:00", "akses_jurusan": "Semua Jurusan"},
    {"id": "GDG013", "nama": "Gedung SAC (Self Access Center) Humaniora", "jam_buka": "07:30", "jam_tutup": "17:00", "akses_jurusan": "Sastra Inggris"},
    {"id": "GDG014", "nama": "Gedung Microteaching & Lab FITK", "jam_buka": "07:00", "jam_tutup": "17:30", "akses_jurusan": "Pendidikan Guru MI"},
    {"id": "GDG015", "nama": "Gedung Mini Hospital FKIK", "jam_buka": "07:00", "jam_tutup": "19:00", "akses_jurusan": "Pendidikan Dokter"}
]
r_g = requests.post(f"{URL}/gedung", headers=HEADERS, json=gedung_data)
print(f"Gedung inserted: {len(gedung_data)} baris (Status {r_g.status_code})")

# 3. SEED RUANGAN (45 Ruangan)
print("\n[3/7] Menyiapkan data Ruangan (45 Ruangan)...")
ruangan_data = []
r_idx = 1
for g in gedung_data:
    g_id = g["id"]
    g_name = g["nama"].split("(")[0].strip()
    prefix = g_name.replace("Gedung ", "").split()[0]
    for floor in [1, 2, 3]:
        r_id = f"RNG{r_idx:03d}"
        r_type = "Laboratorium" if "Laboratorium" in g["nama"] or floor == 3 and "FST" in g["nama"] else "Kelas Teori"
        kapasitas = 35 if floor == 1 else (45 if floor == 2 else 60)
        ruangan_data.append({
            "id": r_id,
            "nama": f"Ruang {prefix} {floor}01",
            "gedung_id": g_id,
            "lantai": f"Lantai {floor}",
            "kapasitas": kapasitas,
            "tipe_ruangan": r_type,
            "status": "Kosong (Ready)",
            "keterangan": f"Ruang kelas ber-AC dan LCD proyektor di {g['nama']}"
        })
        r_idx += 1
r_r = requests.post(f"{URL}/ruangan", headers=HEADERS, json=ruangan_data)
print(f"Ruangan inserted: {len(ruangan_data)} baris (Status {r_r.status_code})")

# 4. SEED SLOT WAKTU (20 Slot Waktu: Senin - Jumat)
print("\n[4/7] Menyiapkan data Slot Waktu (20 Slot)...")
slot_data = []
slot_times = [
    ("07:30", "10:00"),
    ("10:15", "12:45"),
    ("13:00", "15:30"),
    ("15:45", "18:15")
]
days = ["Senin", "Selasa", "Rabu", "Kamis", "Jumat"]
s_idx = 1
for day in days:
    for start, end in slot_times:
        slot_data.append({
            "id": f"SLOT{s_idx:03d}",
            "hari": day,
            "jam_mulai": start,
            "jam_selesai": end,
            "durasi_menit": 150
        })
        s_idx += 1
r_s = requests.post(f"{URL}/slot_waktu", headers=HEADERS, json=slot_data)
print(f"Slot waktu inserted: {len(slot_data)} baris (Status {r_s.status_code})")

# 5. SEED 300 DOSEN (Users)
print("\n[5/7] Menyiapkan 300 Dosen di Supabase...")
first_names = [
    "Ahmad", "Muhammad", "Siti", "Nur", "Budi", "Hendra", "Dewi", "Eko", "Indah", "Rian",
    "Agus", "Tri", "Sri", "Wahyu", "Bambang", "Fajar", "Dian", "Anisa", "Rina", "Ari",
    "Rizky", "Bayu", "Fitri", "Teguh", "Hadi", "Ratna", "Yusuf", "Maya", "Doni", "Lestari",
    "Hasan", "Ali", "Farhan", "Nadia", "Irfan", "Zahra", "Lukman", "Aulia", "Dimas", "Putri",
    "Arif", "Mega", "Galih", "Wulan", "Aditya", "Safira", "Bagas", "Novita", "Danang", "Tika"
]
last_names = [
    "Prasetyo", "Kusuma", "Hidayat", "Saputra", "Utami", "Wijaya", "Santoso", "Lestari", "Nugroho", "Wahyudi",
    "Setiawan", "Rahayu", "Firmansyah", "Pertiwi", "Handayani", "Wibowo", "Suryani", "Gunawan", "Susanto", "Kurniawan",
    "Ramadhan", "Puspitasari", "Wicaksono", "Anggraini", "Mahardika", "Safitri", "Pradana", "Nuraini", "Subagyo", "Hartono",
    "Fauzi", "Maulana", "Hamid", "Basid", "Hamidah", "Ni'mah", "Lubab", "Suhartono", "Fitriani", "Yanti"
]
titles_front = ["Dr.", "Prof. Dr.", "Dr. Ir.", "Dr. Eng.", "", "Drs.", "Dra."]
titles_back = ["M.Kom.", "M.T.", "M.Sc.", "Ph.D.", "M.Pd.", "M.Ag.", "M.M.", "M.Si.", "M.H.", "M.Psi., Psikolog", "M.Biomed.", "Sp.Rad."]

faculty_catalog = [
    ("Fakultas Sains & Teknologi", "Teknik Informatika", [
        "Algoritma & Pemrograman", "Struktur Data & Analisis Algoritma", "Basis Data Terdistribusi",
        "Kecerdasan Buatan & Machine Learning", "Pemrograman Mobile (Flutter)", "Jaringan Komputer Lanjut",
        "Keamanan Siber & Kriptografi", "Cloud Computing & DevOps", "Pengolahan Citra Digital", "Rekayasa Perangkat Lunak"
    ]),
    ("Fakultas Ilmu Tarbiyah dan Keguruan", "Pendidikan Agama Islam", [
        "Metodologi Pembelajaran Agama Islam", "Filsafat Pendidikan Islam", "Pengembangan Kurikulum PAI",
        "Evaluasi Pembelajaran PAI", "Psikologi Pendidikan Islam", "Media & Teknologi Pembelajaran PAI",
        "Manajemen Pendidikan Islam", "Ushul Fiqh Pendidikan"
    ]),
    ("Fakultas Syariah", "Hukum Ekonomi Syariah", [
        "Fiqh Muamalah Maliyah", "Hukum Perbankan Syariah", "Ushul Fiqh Kontemporer",
        "Hukum Pasar Modal Syariah", "Arbitrase & Penyelesaian Sengketa", "Hukum Asuransi Syariah",
        "Tafsir Ayat-Ayat Ekonomi"
    ]),
    ("Fakultas Ekonomi", "Manajemen", [
        "Manajemen Keuangan Syariah", "Manajemen Pemasaran Strategik", "Manajemen Sumber Daya Manusia",
        "Kewirausahaan & Inovasi Bisnis", "Akuntansi Manajemen", "Manajemen Operasional",
        "Ekonomi Manajerial", "Perilaku Konsumen"
    ]),
    ("Fakultas Humaniora", "Bahasa dan Sastra Arab", [
        "Balaghah & Al-Adab Al-Arabi", "Nahwu Lanjut & Sharf", "Terjemah Arab-Indonesia Kontemporer",
        "Linguistik Arab Terapan", "Sejarah Sastra Arab", "Kritik Sastra Arab Klasik"
    ]),
    ("Fakultas Psikologi", "Psikologi", [
        "Psikologi Perkembangan Anak & Remaja", "Psikologi Klinis Dasar", "Psikodiagnostika & Asesmen",
        "Psikologi Sosial Terapan", "Psikometri & Konstruksi Alat Ukur", "Metode Penelitian Psikologi"
    ]),
    ("Fakultas Kedokteran dan Ilmu Kesehatan", "Pendidikan Dokter", [
        "Farmakologi Klinik & Resep", "Anatomi Sistem Manusia", "Fisiologi Seluler & Organ",
        "Patologi Anatomi & Klinik", "Kardiologi & Respirasi", "Mikrobiologi Kedokteran"
    ])
]

# Ambil email yang sudah ada agar tidak bentrok
existing_users_res = requests.get(f"{URL}/users?select=id,email", headers={"apikey": KEY, "Authorization": f"Bearer {KEY}"})
existing_emails = {u["email"] for u in existing_users_res.json()} if existing_users_res.status_code == 200 else set()
existing_ids = {u["id"] for u in existing_users_res.json()} if existing_users_res.status_code == 200 else set()

dosen_users = []
target_dosen_count = 300
d_num = 1

while len(dosen_users) < target_dosen_count:
    user_id = f"DOS{d_num:03d}"
    d_num += 1
    if user_id in existing_ids:
        continue

    fn = random.choice(first_names)
    ln = random.choice(last_names)
    tf = random.choice(titles_front)
    tb = random.choice(titles_back)
    nama_full = f"{tf} {fn} {ln}, {tb}".strip() if tf else f"{fn} {ln}, {tb}"

    email = f"{fn.lower()}.{ln.lower()}{random.randint(10, 999)}@uin-malang.ac.id"
    while email in existing_emails:
        email = f"{fn.lower()}.{ln.lower()}{random.randint(1000, 99999)}@uin-malang.ac.id"
    existing_emails.add(email)

    fak, jur, matkul_choices = random.choice(faculty_catalog)
    matkul_assigned = ", ".join(random.sample(matkul_choices, k=random.randint(1, 2)))
    is_prio = random.random() < 0.15

    dosen_users.append({
        "id": user_id,
        "nama": nama_full,
        "email": email,
        "password": "password123",
        "role": "dosen",
        "jurusan_id": f"JUR{random.randint(1, 7):03d}",
        "jurusan_nama": jur,
        "fakultas_nama": fak,
        "matkul_nama": matkul_assigned,
        "is_priority": is_prio
    })

# Batch insert 300 dosen (batches of 100)
for i in range(0, len(dosen_users), 100):
    batch = dosen_users[i:i+100]
    r_u = requests.post(f"{URL}/users", headers=HEADERS, json=batch)
    print(f"Dosen batch {i+1}-{i+len(batch)} inserted (Status {r_u.status_code})")

# 6. SEED MATA KULIAH & KELAS (60 Mata Kuliah)
print("\n[6/7] Menyiapkan data Mata Kuliah & Kelas...")
mata_kuliah_data = []
kelas_data = []
mk_counter = 1
for fak, jur, matkul_list in faculty_catalog:
    for mk_nama in matkul_list:
        mk_id = f"MK{mk_counter:03d}"
        sks = random.choice([2, 3, 3, 3, 4])
        sem = random.choice([1, 3, 5, 7])
        eligible_dosen = [d for d in dosen_users if d["jurusan_nama"] == jur]
        dosen_pick = random.choice(eligible_dosen) if eligible_dosen else random.choice(dosen_users)

        mata_kuliah_data.append({
            "id": mk_id,
            "nama": mk_nama,
            "sks": sks,
            "jurusan_id": dosen_pick["jurusan_id"],
            "jurusan_nama": jur,
            "fakultas_nama": fak,
            "dosen_id": dosen_pick["id"],
            "dosen_nama": dosen_pick["nama"],
            "semester_id": "SEM001",
            "semester_angka": sem,
            "kebutuhan_tipe_ruangan": "Laboratorium" if "Komputer" in mk_nama or "Praktikum" in mk_nama else "Kelas Teori"
        })

        # Kelas A, B
        abbr = jur.split()[-1][:3].upper()
        kelas_data.append({"mata_kuliah_id": mk_id, "kelas_nama": f"{abbr}-{sem}A"})
        kelas_data.append({"mata_kuliah_id": mk_id, "kelas_nama": f"{abbr}-{sem}B"})
        mk_counter += 1

r_mk = requests.post(f"{URL}/mata_kuliah", headers=HEADERS, json=mata_kuliah_data)
print(f"Mata Kuliah inserted: {len(mata_kuliah_data)} baris (Status {r_mk.status_code})")

r_kls = requests.post(f"{URL}/mata_kuliah_kelas", headers=HEADERS, json=kelas_data)
print(f"Kelas inserted: {len(kelas_data)} baris (Status {r_kls.status_code})")

# 7. SEED AJUAN PENGAJARAN (80 Ajuan dengan status Kaprodi / Dekan, NON-FINAL)
print("\n[7/7] Menyiapkan 80 Ajuan Pengajaran (Status: Menunggu Kaprodi, Diverifikasi Kaprodi, Menunggu Dekan, Disetujui Dekan)...")
# Delete existing ajuan so we have a fresh testing dataset
requests.delete(f"{URL}/ajuan_pengajaran?id=not.is.null", headers={"apikey": KEY, "Authorization": f"Bearer {KEY}"})

status_pool = [
    "menunggu_kaprodi",
    "menunggu_kaprodi",
    "diverifikasi_kaprodi",
    "diverifikasi_kaprodi",
    "menunggu_dekan",
    "disetujui_dekan"
]

ajuan_data = []
for idx in range(1, 81):
    mk = random.choice(mata_kuliah_data)
    room = random.choice(ruangan_data)
    ged = next((g for g in gedung_data if g["id"] == room["gedung_id"]), gedung_data[0])
    slot = random.choice(slot_data)
    st = random.choice(status_pool)

    catatan_kap = "Dokumen kelayakan dan ketersediaan ruangan telah diverifikasi Kaprodi." if st in ["diverifikasi_kaprodi", "menunggu_dekan", "disetujui_dekan"] else None
    catatan_dek = "Disetujui Dekan untuk dijadwalkan oleh sistem." if st == "disetujui_dekan" else None

    abbr = mk["jurusan_nama"].split()[-1][:3].upper()
    kls_name = f"{abbr}-{mk['semester_angka']}{random.choice(['A', 'B'])}"

    ajuan_data.append({
        "id": f"AJUAN_{idx:04d}",
        "dosen_id": mk["dosen_id"],
        "dosen_nama": mk["dosen_nama"],
        "fakultas_nama": mk["fakultas_nama"],
        "jurusan_nama": mk["jurusan_nama"],
        "mata_kuliah_id": mk["id"],
        "mata_kuliah_nama": mk["nama"],
        "sks": mk["sks"],
        "semester": mk["semester_angka"],
        "kelas_nama": kls_name,
        "jumlah_mahasiswa": random.randint(30, 48),
        "gedung_nama": ged["nama"],
        "ruangan_nama": room["nama"],
        "hari": slot["hari"],
        "jam_mulai": slot["jam_mulai"],
        "jam_selesai": slot["jam_selesai"],
        "status": st,
        "catatan_dosen": f"Pengajuan jadwal mengajar semester ganjil untuk mata kuliah {mk['nama']}.",
        "catatan_kaprodi": catatan_kap,
        "catatan_dekan": catatan_dek,
        "catatan_admin": None
    })

# Batch insert ajuan
for i in range(0, len(ajuan_data), 40):
    batch = ajuan_data[i:i+40]
    r_aj = requests.post(f"{URL}/ajuan_pengajaran", headers=HEADERS, json=batch)
    print(f"Ajuan batch {i+1}-{i+len(batch)} inserted (Status {r_aj.status_code})")

print("\n" + "=" * 60)
print("INJEKSI DATA SKALA BESAR KE SUPABASE SELESAI!")
print("=" * 60)
