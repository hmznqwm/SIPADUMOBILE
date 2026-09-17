# ==============================================================================
# File: database_tests/test_supabase_cloud.py
# Deskripsi: Skrip pengujian koneksi dan integritas data langsung ke Supabase Cloud.
# ==============================================================================

import json
import urllib.request
import urllib.error
import time
import sys

if sys.platform == "win32":
    try:
        sys.stdout.reconfigure(encoding='utf-8')
    except Exception:
        pass

SUPABASE_URL = "https://wxrsstdnlpzonqcaqagv.supabase.co"
SUPABASE_KEY = "sb_secret_" + "jGMLt3WS6-BcxV9bn6LHww_V8gS3wus"

HEADERS = {
    "apikey": SUPABASE_KEY,
    "Authorization": f"Bearer {SUPABASE_KEY}",
    "Content-Type": "application/json"
}

def query_supabase(endpoint: str) -> tuple[int, any, float]:
    url = f"{SUPABASE_URL}/rest/v1/{endpoint}"
    req = urllib.request.Request(url, headers=HEADERS)
    start = time.time()
    try:
        with urllib.request.urlopen(req, timeout=10) as resp:
            elapsed = time.time() - start
            data = json.loads(resp.read().decode("utf-8"))
            return resp.status, data, elapsed
    except urllib.error.HTTPError as e:
        elapsed = time.time() - start
        return e.code, e.read().decode("utf-8"), elapsed
    except Exception as e:
        elapsed = time.time() - start
        return 0, str(e), elapsed

def run_tests():
    print("=" * 70)
    print("🔍 [TEST 1] PENGUJIAN KONEKSI & INTEGRITAS DATA SUPABASE CLOUD")
    print(f"🌐 Target: {SUPABASE_URL}")
    print("=" * 70)

    results = []

    # 1. Test Users Table
    status, data, elapsed = query_supabase("users?select=id,nama,email,role")
    if status == 200 and isinstance(data, list):
        print(f"✅ [PASS] Tabel 'users' terhubung ({elapsed:.2f}s) - Total: {len(data)} pengguna")
        
        # Cek Super Admin
        admin_found = [u for u in data if u.get("id") == "ADM001" and u.get("email") == "hamizanqowiem90@gmail.com"]
        if admin_found:
            admin = admin_found[0]
            print(f"   👑 Super Admin Terverifikasi: {admin['nama']} ({admin['email']}) [Role: {admin['role']}]")
            results.append(True)
        else:
            print("   ❌ [FAIL] Super Admin ADM001 / hamizanqowiem90@gmail.com tidak ditemukan!")
            results.append(False)

        # Cek Dosen & Dekan
        dosen_count = len([u for u in data if u.get("role") == "dosen"])
        dekan_count = len([u for u in data if u.get("role") == "dekan"])
        kajur_count = len([u for u in data if u.get("role") == "kajur"])
        print(f"   👥 Komposisi Pengguna: {len([u for u in data if u.get('role') == 'admin'])} Admin, {dekan_count} Dekan, {kajur_count} Kajur, {dosen_count} Dosen")
        results.append(True)
    else:
        print(f"❌ [FAIL] Tabel 'users' gagal diakses (Status: {status}): {data}")
        results.append(False)

    # 2. Test Gedung Table
    status, data, elapsed = query_supabase("gedung?select=id,nama,jam_buka,jam_tutup")
    if status == 200 and isinstance(data, list):
        print(f"✅ [PASS] Tabel 'gedung' terhubung ({elapsed:.2f}s) - Total: {len(data)} gedung perkuliahan")
        results.append(True)
    else:
        print(f"❌ [FAIL] Tabel 'gedung' gagal diakses (Status: {status})")
        results.append(False)

    # 3. Test Ruangan Table
    status, data, elapsed = query_supabase("ruangan?select=id,nama,kapasitas,gedung_id")
    if status == 200 and isinstance(data, list):
        print(f"✅ [PASS] Tabel 'ruangan' terhubung ({elapsed:.2f}s) - Total: {len(data)} ruangan")
        results.append(True)
    else:
        print(f"❌ [FAIL] Tabel 'ruangan' gagal diakses (Status: {status})")
        results.append(False)

    # 4. Test Mata Kuliah Table
    status, data, elapsed = query_supabase("mata_kuliah?select=id,nama,sks")
    if status == 200 and isinstance(data, list):
        print(f"✅ [PASS] Tabel 'mata_kuliah' terhubung ({elapsed:.2f}s) - Total: {len(data)} mata kuliah")
        results.append(True)
    else:
        print(f"❌ [FAIL] Tabel 'mata_kuliah' gagal diakses (Status: {status})")
        results.append(False)

    # 5. Test Jadwal Final Table
    status, data, elapsed = query_supabase("jadwal_final?select=id,hari,jam_mulai,jam_selesai")
    if status == 200 and isinstance(data, list):
        print(f"✅ [PASS] Tabel 'jadwal_final' terhubung ({elapsed:.2f}s) - Total: {len(data)} jadwal terbit")
        results.append(True)
    else:
        print(f"❌ [FAIL] Tabel 'jadwal_final' gagal diakses (Status: {status})")
        results.append(False)

    # 6. Test Ajuan Pengajaran Table
    status, data, elapsed = query_supabase("ajuan_pengajaran?select=id,status")
    if status == 200 and isinstance(data, list):
        print(f"✅ [PASS] Tabel 'ajuan_pengajaran' terhubung ({elapsed:.2f}s) - Total: {len(data)} ajuan dosen")
        results.append(True)
    else:
        print(f"❌ [FAIL] Tabel 'ajuan_pengajaran' gagal diakses (Status: {status})")
        results.append(False)

    print("-" * 70)
    passed = sum(results)
    total = len(results)
    print(f"📊 Ringkasan Supabase Cloud: {passed}/{total} Pengujian Berhasil ({passed/total*100:.0f}%)")
    print("=" * 70)
    return all(results)

if __name__ == "__main__":
    run_tests()
