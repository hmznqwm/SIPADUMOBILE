import requests
import json

URL = "https://wxrsstdnlpzonqcaqagv.supabase.co/rest/v1"
KEY = "sb_secret_" + "jGMLt3WS6-BcxV9bn6LHww_V8gS3wus"
HEADERS = {
    "apikey": KEY,
    "Authorization": f"Bearer {KEY}",
    "Content-Type": "application/json"
}

# 1. Check jadwal_final in Supabase
r = requests.get(f"{URL}/jadwal_final?select=*", headers=HEADERS)
schedules = r.json()
print("=" * 60)
print(f"TOTAL JADWAL_FINAL DI SUPABASE CLOUD: {len(schedules)} BARIS")
print("=" * 60)
for idx, s in enumerate(schedules, 1):
    mk = s.get("mata_kuliah_nama")
    kls = s.get("kelas_nama")
    dos = s.get("dosen_nama")
    hari = s.get("hari")
    jam = f"{s.get('jam_mulai')}-{s.get('jam_selesai')}"
    ruang = s.get("ruangan_nama")
    gedung = s.get("gedung_nama")
    print(f"{idx:2d}. [{kls}] {mk}")
    print(f"    Dosen: {dos}")
    print(f"    Waktu: {hari}, {jam}")
    print(f"    Ruang: {ruang} ({gedung})")

# 2. Check ajuan_pengajaran in Supabase
r_ajuan = requests.get(f"{URL}/ajuan_pengajaran?select=id,mata_kuliah_nama,kelas_nama,status,ruangan_nama,hari,jam_mulai", headers=HEADERS)
ajuans = r_ajuan.json()
print("\n" + "=" * 60)
print(f"TOTAL AJUAN_PENGAJARAN DI SUPABASE CLOUD: {len(ajuans)} BARIS")
print("=" * 60)
for idx, a in enumerate(ajuans, 1):
    print(f"{idx:2d}. {a.get('mata_kuliah_nama')} ({a.get('kelas_nama')}): Status={a.get('status')} | {a.get('hari')} {a.get('jam_mulai')} | Ruang={a.get('ruangan_nama')}")
