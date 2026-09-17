# 🧪 Database & Backend Synchronization Test Suite

Folder ini berisi perangkat pengujian otomatis untuk memverifikasi bahwa database **Supabase Cloud**, **Backend Python FastAPI**, dan **Aplikasi Flutter** terhubung dan tersinkronisasi secara akurat.

---

## 📁 Daftar File Pengujian:

1. **`test_supabase_cloud.py`**
   * Menguji koneksi langsung ke **Supabase Cloud REST API**.
   * Memverifikasi tabel: `users`, `gedung`, `ruangan`, `mata_kuliah`, `jadwal_kuliah`.
   * Memastikan akun Super Admin (`hamizanqowiem90@gmail.com` / `ADM001`) aktif dengan role `admin`.

2. **`test_backend_api_sync.py`**
   * Menguji API backend Python FastAPI (`http://127.0.0.1:8000/api`).
   * Menguji login form reguler (`ADM001` + password).
   * Menguji Google Login Super Admin (`hamizanqowiem90@gmail.com`) -> berhasil masuk sebagai `admin`.
   * Menguji Google Login Dosen terdaftar (`hendra.gunawan@uin-malang.ac.id`) -> berhasil masuk sebagai `dosen`.
   * Menguji proteksi akun asing/tidak terdaftar -> ditolak dengan status `401 Unauthorized`.
   * Menguji pembacaan data master (`users`, `gedung`, `ruangan`).

3. **`run_all_database_tests.py`**
   * Skrip utama yang menjalankan seluruh rangkaian pengujian di atas dan memberikan laporan status evaluasi menyeluruh.

4. **`run_tests.bat`**
   * File batch praktis. Cukup klik ganda (double-click) file ini di Windows Explorer untuk menjalankan seluruh tes.

---

## 🚀 Cara Menjalankan Pengujian:

### Cara 1 (Praktis - Double Click):
* Buka folder `database_tests` di Windows Explorer.
* Klik ganda pada file **`run_tests.bat`**.

### Cara 2 (Terminal / Command Prompt):
```powershell
cd database_tests
..\backend-python\.venv\Scripts\python.exe run_all_database_tests.py
```
