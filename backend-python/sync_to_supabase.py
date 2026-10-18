import os
import sqlite3
import requests
import json
import bcrypt

SUPABASE_URL = os.getenv("SUPABASE_URL", "https://wxrsstdnlpzonqcaqagv.supabase.co")
SUPABASE_KEY = os.getenv("SUPABASE_KEY")
if not SUPABASE_KEY:
    raise ValueError("Variabel lingkungan SUPABASE_KEY belum disetel. Harap setel SUPABASE_KEY di file .env atau env runtime.")

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
    {"id": "ADM001", "nama": "Super Admin", "email": "admin@admin.com", "role": "admin", "fakultas_nama": None, "jurusan_id": None, "jurusan_nama": None, "is_priority": True, "matkul_nama": None},
]

# 2. GEDUNG
gedungs = []

# 3. RUANGAN
ruangans = []

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
mks = []

# 6. NOTIFIKASI
notifications = []

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

# Insert or replace users
for u in users_data:
    c.execute("""
        INSERT OR REPLACE INTO users (id, nama, email, password, role, jurusan_id, jurusan_nama, fakultas_nama, is_priority, matkul_nama)
        VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?)
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
