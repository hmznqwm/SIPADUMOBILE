from pydantic import BaseModel, EmailStr
from typing import Optional, List, Any
from datetime import datetime

# [PRESENTASI] Pydantic Schemas (Data Transfer Object / DTO)
# Digunakan oleh FastAPI untuk validasi otomatis request payload dari frontend.
# Memastikan tipe data (string, integer, email) valid sebelum diproses oleh controller.

class LoginRequest(BaseModel):
    """[PRESENTASI] Skema validasi untuk payload request saat user melakukan Login."""
    email: Optional[str] = None
    id: Optional[str] = None
    username: Optional[str] = None
    nidn: Optional[str] = None
    password: str

class GoogleLoginRequest(BaseModel):
    idToken: Optional[str] = None
    email: Optional[str] = None
    displayName: Optional[str] = None
    photoUrl: Optional[str] = None

class ChangePasswordRequest(BaseModel):
    id: Optional[str] = None
    email: Optional[str] = None
    old_password: str
    new_password: str

class ForgotPasswordRequest(BaseModel):
    email: Optional[str] = None
    nidn: Optional[str] = None
    nid: Optional[str] = None
    nip: Optional[str] = None

class ResetPasswordRequest(BaseModel):
    email: Optional[str] = None
    otp: Optional[str] = None
    token: Optional[str] = None
    new_password: Optional[str] = None
    password: Optional[str] = None

# Master Data Schemas
class GedungSchema(BaseModel):
    id: str
    nama: str
    jam_buka: str = "07:00"
    jam_tutup: str = "18:30"
    akses_jurusan: str

class RuanganSchema(BaseModel):
    id: str
    nama: str
    gedung_id: str
    lantai: str = "Lantai 1"
    kapasitas: int = 40
    tipe_ruangan: str = "Kelas Teori"
    status: str = "Kosong (Ready)"
    keterangan: Optional[str] = None

class MataKuliahSchema(BaseModel):
    id: str
    nama: str
    sks: int = 3
    jurusan_id: Optional[str] = None
    jurusan_nama: Optional[str] = None
    fakultas_nama: Optional[str] = None
    dosen_id: str
    semester_id: str = "SEM001"
    semester_angka: int = 1
    kebutuhan_tipe_ruangan: Optional[str] = None
    kelas: Optional[List[str]] = []

class UserSchema(BaseModel):
    id: str
    nama: str
    email: str
    password: Optional[str] = None
    role: str
    jurusan_id: Optional[str] = None
    jurusan_nama: Optional[str] = None
    fakultas_nama: Optional[str] = None
    avatar_url: Optional[str] = None
    is_priority: Optional[bool] = False

# [PRESENTASI] Response Wrapper
# Standar format JSON (Envelope) untuk setiap balasan dari backend ke frontend.
# Membuat konsumsi data dari frontend API (seperti Axios/Fetch) menjadi lebih seragam dan aman.
class ApiResponse(BaseModel):
    status: str = "success"
    message: str
    data: Optional[Any] = None
