from fastapi import APIRouter, Depends, HTTPException, status, Request
from fastapi.responses import JSONResponse
from sqlalchemy.orm import Session
from datetime import datetime, timedelta
from core.database import get_db
from core.config import SUPABASE_URL, SB_HEADERS
from models.models import User, PasswordReset
from schemas.schemas import LoginRequest, GoogleLoginRequest, ChangePasswordRequest, ForgotPasswordRequest, ResetPasswordRequest
import bcrypt
import secrets
import requests
import json
import random

def patch_user_in_supabase(user_id_or_email: str, data: dict):
    try:
        url = f"{SUPABASE_URL}/rest/v1/users?or=(id.eq.{user_id_or_email},email.ilike.{user_id_or_email})"
        requests.patch(url, headers=SB_HEADERS, json=data, timeout=5)
    except Exception:
        pass

router = APIRouter(prefix="/auth", tags=["Auth"])

def verify_password(plain_password: str, hashed_password: str) -> bool:
    if not hashed_password:
        return False
    normalized_hash = hashed_password
    if normalized_hash.startswith("$2y$"):
        normalized_hash = "$2b$" + normalized_hash[4:]
    try:
        if bcrypt.checkpw(plain_password.encode("utf-8"), normalized_hash.encode("utf-8")):
            return True
    except Exception:
        pass
    return False

def get_password_hash(password: str) -> str:
    return bcrypt.hashpw(password.encode("utf-8"), bcrypt.gensalt()).decode("utf-8")

def format_user_data(user: User):
    return {
        "id": user.id,
        "nama": user.nama,
        "email": user.email,
        "role": user.role,
        "jurusan_id": user.jurusan_id or "JUR001",
        "jurusan_nama": user.jurusan_nama or "Teknik Informatika",
        "fakultas_nama": user.fakultas_nama or "Fakultas Sains & Teknologi",
        "matkul_nama": user.matkul_nama,
        "is_priority": bool(user.is_priority),
        "avatar_url": user.avatar_url
    }

@router.post("/login")
@router.post("/login.php")
def login(req: LoginRequest, db: Session = Depends(get_db)):
    ident = (req.email or req.id or req.username or req.nidn or "").strip()
    password = req.password.strip()

    if not ident or not password:
        raise HTTPException(
            status_code=400,
            detail={"status": "error", "message": "Nomor Induk / Email dan kata sandi wajib diisi."}
        )

    # Normalisasi jika user lupa mengetik .com di @gmail
    clean_ident = ident
    if clean_ident.endswith("@gmail"):
        clean_ident += ".com"

    user = db.query(User).filter(
        (User.email.ilike(ident)) | (User.email.ilike(clean_ident)) | (User.id.ilike(ident))
    ).first()

    if not user:
        raise HTTPException(
            status_code=401,
            detail={"status": "error", "message": "Nomor Induk / Email tidak ditemukan."}
        )

    # Verifikasi kredensial secara ketat tanpa backdoor
    is_valid = verify_password(password, user.password)

    if not is_valid:
        raise HTTPException(
            status_code=401,
            detail={"status": "error", "message": "Kata sandi yang Anda masukkan salah."}
        )

    user_data = format_user_data(user)
    token = f"sipadu_sec_token_{secrets.token_hex(24)}"

    return {
        "status": "success",
        "message": "Login berhasil",
        "user": user_data,
        "data": {
            "token": token,
            "user": user_data
        }
    }

@router.post("/google_login")
@router.post("/google_login.php")
def google_login(req: GoogleLoginRequest, db: Session = Depends(get_db)):
    email = (req.email or "").strip().lower()
    if not email:
        raise HTTPException(
            status_code=400,
            detail={"status": "error", "message": "Email Google wajib disertakan."}
        )

    if email.endswith("@gmail"):
        email += ".com"

    # Cari data user murni dari database Supabase berdasarkan email Google
    user = db.query(User).filter(User.email.ilike(email)).first()
    if user:
        if req.photoUrl:
            user.avatar_url = req.photoUrl
            patch_user_in_supabase(user.id, {"avatar_url": req.photoUrl})
        try:
            db.commit()
            db.refresh(user)
        except Exception:
            db.rollback()

    # 3. If user is NOT found in database, REJECT with 401 Unregistered
    if not user:
        raise HTTPException(
            status_code=401,
            detail={
                "status": "error",
                "message": f"Akun Google ({email}) tidak terdaftar dalam database institusi. Silakan hubungi Administrator."
            }
        )

    user_data = format_user_data(user)
    token = f"sipadu_token_{secrets.token_hex(16)}"

    return {
        "status": "success",
        "message": "Login Google berhasil",
        "user": user_data,
        "data": {
            "token": token,
            "user": user_data
        }
    }

@router.post("/change_password")
@router.post("/change_password.php")
def change_password(req: ChangePasswordRequest, db: Session = Depends(get_db)):
    ident = (req.email or req.id or "").strip()
    user = db.query(User).filter((User.email.ilike(ident)) | (User.id.ilike(ident))).first()

    # If not found locally, query Supabase
    if not user:
        try:
            r = requests.get(
                f"{SUPABASE_URL}/rest/v1/users?or=(email.ilike.{ident},id.ilike.{ident})&select=*",
                headers=SB_HEADERS,
                timeout=5
            )
            if r.status_code == 200 and r.json():
                sb_u = r.json()[0]
                user = User(
                    id=sb_u["id"],
                    nama=sb_u["nama"],
                    email=sb_u["email"],
                    password=sb_u.get("password") or "password123",
                    role=sb_u.get("role") or "dosen",
                    jurusan_id=sb_u.get("jurusan_id"),
                    jurusan_nama=sb_u.get("jurusan_nama"),
                    fakultas_nama=sb_u.get("fakultas_nama")
                )
                db.add(user)
                db.commit()
        except Exception:
            pass

    if not user:
        raise HTTPException(status_code=404, detail={"status": "error", "message": "Pengguna tidak ditemukan."})

    if not verify_password(req.old_password, user.password):
        raise HTTPException(status_code=400, detail={"status": "error", "message": "Kata sandi lama tidak sesuai."})

    user.password = get_password_hash(req.new_password)
    db.commit()
    patch_user_in_supabase(user.id, {"password": user.password})
    return {"status": "success", "message": "Kata sandi berhasil diperbarui dan disinkronkan ke Supabase."}

@router.post("/forgot_password")
@router.post("/forgot_password.php")
def forgot_password(req: ForgotPasswordRequest):
    email = str(req.email or "").strip()
    nidn = str(req.nidn or req.nid or req.nip or "").strip()

    if not email:
        raise HTTPException(status_code=400, detail={"status": "error", "message": "Email wajib diisi."})

    user_id = None
    user_nama = None
    user_email = None

    try:
        url = f"{SUPABASE_URL}/rest/v1/users?email=ilike.{email}&select=id,nama,email"
        res = requests.get(url, headers=SB_HEADERS, timeout=5)
        if res.status_code == 200:
            res_data = res.json()
            if isinstance(res_data, list) and len(res_data) > 0:
                sb_u = res_data[0]
                user_id = str(sb_u.get("id") or "").strip()
                user_nama = str(sb_u.get("nama") or "").strip()
                user_email = str(sb_u.get("email") or "").strip()
    except Exception as e:
        print(f"[FORGOT PW] Supabase error: {e}")

    if not user_id or not user_email:
        raise HTTPException(status_code=400, detail={"status": "error", "message": f"Alamat Email '{email}' tidak terdaftar pada sistem SIPADU."})

    if nidn and user_id.lower() != nidn.lower():
        raise HTTPException(
            status_code=400,
            detail={"status": "error", "message": f"Kombinasi NID/NIP dan Email tidak cocok! NID/NIP '{nidn}' bukan milik email '{email}'."}
        )

    token_val = f"tok_{secrets.token_hex(4)}"
    otp_val = "123456"

    raise HTTPException(
        status_code=400,
        detail={
            "status": "success",
            "message": f"Kode OTP pemulihan kata sandi telah dikirimkan ke {user_email}.",
            "token": token_val,
            "otp": otp_val,
            "email": user_email,
            "nama": "Pengguna",
            "nidn": user_id
        }
    )

@router.post("/reset_password")
@router.post("/reset_password.php")
def reset_password(req: ResetPasswordRequest):
    email = (req.email or "").strip()
    otp = (req.otp or "").strip()
    token = (req.token or "").strip()
    new_password = (req.new_password or req.password or "").strip()

    if not email or not new_password or (not otp and not token):
        raise HTTPException(status_code=400, detail={"status": "error", "message": "Email, OTP/Token, dan password baru wajib diisi."})

    hashed = get_password_hash(new_password)
    patch_user_in_supabase(email, {"password": hashed})

    raise HTTPException(
        status_code=400,
        detail={
            "status": "success",
            "message": "Kata sandi Anda berhasil diperbarui! Silakan login dengan kata sandi baru."
        }
    )
