# ==============================================================================
# File: database_tests/test_backend_api_sync.py
# Deskripsi: Skrip pengujian sinkronisasi API Backend Python FastAPI dengan Database.
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

BACKEND_BASE_URL = "http://127.0.0.1:8000/api"

def api_post(endpoint: str, payload: dict) -> tuple[int, dict, float]:
    url = f"{BACKEND_BASE_URL}/{endpoint}"
    data_bytes = json.dumps(payload).encode("utf-8")
    req = urllib.request.Request(
        url,
        data=data_bytes,
        headers={"Content-Type": "application/json"}
    )
    start = time.time()
    try:
        with urllib.request.urlopen(req, timeout=8) as resp:
            elapsed = time.time() - start
            body = json.loads(resp.read().decode("utf-8"))
            return resp.status, body, elapsed
    except urllib.error.HTTPError as e:
        elapsed = time.time() - start
        try:
            body = json.loads(e.read().decode("utf-8"))
        except Exception:
            body = {"error": str(e)}
        return e.code, body, elapsed
    except Exception as e:
        elapsed = time.time() - start
        return 0, {"error": str(e)}, elapsed

def api_get(endpoint: str) -> tuple[int, any, float]:
    url = f"{BACKEND_BASE_URL}/{endpoint}"
    req = urllib.request.Request(url)
    start = time.time()
    try:
        with urllib.request.urlopen(req, timeout=8) as resp:
            elapsed = time.time() - start
            body = json.loads(resp.read().decode("utf-8"))
            return resp.status, body, elapsed
    except urllib.error.HTTPError as e:
        elapsed = time.time() - start
        return e.code, str(e), elapsed
    except Exception as e:
        elapsed = time.time() - start
        return 0, str(e), elapsed

def run_tests():
    print("=" * 70)
    print("⚡ [TEST 2] PENGUJIAN SINKRONISASI API BACKEND PYTHON & DATABASE")
    print(f"🌐 Backend URL: {BACKEND_BASE_URL}")
    print("=" * 70)

    results = []

    # 1. Test Login Form Regular Super Admin (ADM001 / admin123)
    status, body, elapsed = api_post("auth/login.php", {
        "email": "ADM001",
        "password": "admin123"
    })
    if status == 200 and body.get("status") == "success":
        user = body.get("user", {})
        print(f"✅ [PASS] Login Form Reguler ADM001 ({elapsed:.2f}s)")
        print(f"   👤 User: {user.get('nama')} | Role: {user.get('role')}")
        results.append(True)
    else:
        print(f"❌ [FAIL] Login Reguler Gagal (Status {status}): {body}")
        results.append(False)

    # 2. Test Google Login Super Admin (hamizanqowiem90@gmail.com)
    status, body, elapsed = api_post("auth/google_login.php", {
        "email": "hamizanqowiem90@gmail.com",
        "displayName": "Hamizan Qowiem"
    })
    if status == 200 and body.get("status") == "success":
        user = body.get("user", {})
        role = user.get("role")
        if role == "admin":
            print(f"✅ [PASS] Google Login Super Admin ({elapsed:.2f}s)")
            print(f"   🔑 Email: hamizanqowiem90@gmail.com -> Sukses masuk sebagai Super Admin ({role})")
            results.append(True)
        else:
            print(f"❌ [FAIL] Google Login hamizanqowiem90@gmail.com role salah: {role}")
            results.append(False)
    else:
        print(f"❌ [FAIL] Google Login Super Admin Gagal (Status {status}): {body}")
        results.append(False)

    # 3. Test Google Login Dosen Terdaftar (hendra.gunawan@uin-malang.ac.id)
    status, body, elapsed = api_post("auth/google_login.php", {
        "email": "hendra.gunawan@uin-malang.ac.id",
        "displayName": "Dr. Hendra Gunawan"
    })
    if status == 200 and body.get("status") == "success":
        user = body.get("user", {})
        print(f"✅ [PASS] Google Login Dosen Terdaftar ({elapsed:.2f}s)")
        print(f"   👨‍🏫 Email: hendra.gunawan@uin-malang.ac.id -> Sukses masuk sebagai {user.get('role')}")
        results.append(True)
    else:
        print(f"❌ [FAIL] Google Login Dosen Gagal (Status {status}): {body}")
        results.append(False)

    # 4. Test Google Login Akun TIDAK Terdaftar (harus DITOLAK 401)
    status, body, elapsed = api_post("auth/google_login.php", {
        "email": "random.unregistered.user999@gmail.com",
        "displayName": "Orang Asing"
    })
    if status == 401:
        detail = body.get("detail", {})
        msg = detail.get("message") if isinstance(detail, dict) else str(detail)
        print(f"✅ [PASS] Proteksi Akun Tak Terdaftar Berhasil ({elapsed:.2f}s)")
        print(f"   🛡️ Ditolak dengan benar (401): \"{msg}\"")
        results.append(True)
    else:
        print(f"❌ [FAIL] Akun asing tidak ditolak! Status: {status}, Body: {body}")
        results.append(False)

    # 5. Test Master Users API Endpoint
    status, body, elapsed = api_get("master/users.php")
    if status == 200:
        data = body.get("data") if isinstance(body, dict) else body
        count = len(data) if isinstance(data, list) else 0
        print(f"✅ [PASS] API Master Users Sinkron ({elapsed:.2f}s) - {count} records")
        results.append(True)
    else:
        print(f"❌ [FAIL] API Master Users Gagal (Status {status})")
        results.append(False)

    # 6. Test Master Gedung & Ruangan API Endpoint
    status_g, body_g, _ = api_get("master/gedung.php")
    status_r, body_r, _ = api_get("master/ruangan.php")
    if status_g == 200 and status_r == 200:
        print(f"✅ [PASS] API Master Gedung & Ruangan Sinkron dengan Database")
        results.append(True)
    else:
        print(f"❌ [FAIL] API Gedung/Ruangan Gagal (Gedung: {status_g}, Ruangan: {status_r})")
        results.append(False)

    print("-" * 70)
    passed = sum(results)
    total = len(results)
    print(f"📊 Ringkasan Sinkronisasi API: {passed}/{total} Pengujian Berhasil ({passed/total*100:.0f}%)")
    print("=" * 70)
    return all(results)

if __name__ == "__main__":
    run_tests()
