# ==============================================================================
# File: database_tests/run_all_database_tests.py
# Deskripsi: Runner utama untuk menjalankan seluruh suite pengujian sinkronisasi.
# ==============================================================================

import sys
import os

if sys.platform == "win32":
    try:
        sys.stdout.reconfigure(encoding='utf-8')
    except Exception:
        pass

# Tambahkan direktori saat ini ke path
sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))

import test_supabase_cloud
import test_backend_api_sync

def main():
    print("\n" + "#" * 70)
    print("🚀 SMART COURSE SCHEDULER - SUITE PENGUJIAN SINKRONISASI DATABASE")
    print("#" * 70 + "\n")

    # Run Test 1
    t1_pass = test_supabase_cloud.run_tests()
    print("\n")

    # Run Test 2
    t2_pass = test_backend_api_sync.run_tests()
    print("\n")

    print("#" * 70)
    if t1_pass and t2_pass:
        print("🎉 KESIMPULAN: SELURUH SISTEM 100% SINKRON DAN BERFUNGSI SEMPURNA!")
        print("   - Database Supabase Cloud terhubung dan data terverifikasi.")
        print("   - Akun Super Admin (hamizanqowiem90@gmail.com) terdaftar & siap digunakan.")
        print("   - API Backend FastAPI meneruskan autentikasi & master data dengan benar.")
        print("   - Proteksi keamanan menolak email asing / tidak terdaftar.")
    else:
        print("⚠️ KESIMPULAN: Terdapat beberapa pengujian yang memerlukan perhatian.")
    print("#" * 70 + "\n")

if __name__ == "__main__":
    main()
