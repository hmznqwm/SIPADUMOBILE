from fastapi import APIRouter, Depends, HTTPException, status, Request
from fastapi.responses import JSONResponse
from sqlalchemy.orm import Session
from datetime import datetime, timedelta, timezone
from core.database import get_db
from core.config import SUPABASE_URL, SB_HEADERS
from core.security import (
    create_access_token, get_current_user, validate_password_strength,
    sanitize_supabase_param
)
from models.models import User, PasswordReset
from schemas.schemas import LoginRequest, GoogleLoginRequest, ChangePasswordRequest, ForgotPasswordRequest, ResetPasswordRequest
import bcrypt
import secrets
import requests
import json
import random
import logging

logger = logging.getLogger("smartschedule.auth")

def patch_user_in_supabase(user_id_or_email: str, data: dict):
    try:
        clean = sanitize_supabase_param(user_id_or_email)
        url = f"{SUPABASE_URL}/rest/v1/users?or=(id.eq.{clean},email.ilike.{clean})"
        requests.patch(url, headers=SB_HEADERS, json=data, timeout=5)
    except Exception as e:
        logger.warning(f"Failed to patch user in Supabase: {e}")

router = APIRouter(prefix="/auth", tags=["Auth"])

def verify_password(plain_password: str, hashed_password: str) -> bool:
    if not plain_password or not hashed_password:
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

    # 1. Ambil data user langsung dari Supabase REST API (Source of Truth)
    user = None
    try:
        safe_ident = sanitize_supabase_param(ident)
        safe_clean = sanitize_supabase_param(clean_ident)
        url = f"{SUPABASE_URL}/rest/v1/users?or=(id.eq.{safe_ident},id.ilike.{safe_ident},email.eq.{safe_ident},email.ilike.{safe_clean})"
        resp = requests.get(url, headers=SB_HEADERS, timeout=5)
        if resp.status_code == 200:
            users_data = resp.json()
            if users_data and len(users_data) > 0:
                u = users_data[0]
                user = User(
                    id=u.get("id"),
                    nama=u.get("nama"),
                    email=u.get("email"),
                    password=u.get("password"),
                    role=u.get("role"),
                    jurusan_id=u.get("jurusan_id"),
                    jurusan_nama=u.get("jurusan_nama"),
                    fakultas_nama=u.get("fakultas_nama"),
                    matkul_nama=u.get("matkul_nama"),
                    is_priority=u.get("is_priority"),
                    avatar_url=u.get("avatar_url")
                )
    except Exception as e:
        logger.warning(f"Supabase login lookup failed: {e}")

    # 2. Fallback ke SQLite lokal jika koneksi Supabase Cloud bermasalah
    if not user:
        try:
            user = db.query(User).filter(
                (User.email.ilike(ident)) | (User.email.ilike(clean_ident)) | (User.id.ilike(ident))
            ).first()
        except Exception:
            pass

    if not user:
        raise HTTPException(
            status_code=401,
            detail={"status": "error", "message": "Nomor Induk / Email tidak ditemukan."}
        )

    # 3. Verifikasi password murni secara dinamis via bcrypt (tanpa hardcode)
    is_valid = verify_password(password, user.password)

    if not is_valid:
        raise HTTPException(
            status_code=401,
            detail={"status": "error", "message": "Kata sandi yang Anda masukkan salah."}
        )

    user_data = format_user_data(user)

    # Generate JWT token yang valid dan bisa diverifikasi
    token = create_access_token(
        user_id=user.id,
        role=user.role,
        email=user.email
    )

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

    # Generate JWT token
    token = create_access_token(
        user_id=user.id,
        role=user.role,
        email=user.email
    )

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
def change_password(req: ChangePasswordRequest, current_user: User = Depends(get_current_user), db: Session = Depends(get_db)):
    # Use authenticated user instead of trusting client-provided identity
    user = db.query(User).filter(User.id == current_user.id).first()

    if not user:
        raise HTTPException(status_code=404, detail={"status": "error", "message": "Pengguna tidak ditemukan."})

    if not verify_password(req.old_password, user.password):
        raise HTTPException(status_code=400, detail={"status": "error", "message": "Kata sandi lama tidak sesuai."})

    # Validate password strength
    pw_error = validate_password_strength(req.new_password)
    if pw_error:
        raise HTTPException(status_code=400, detail={"status": "error", "message": pw_error})

    user.password = get_password_hash(req.new_password)
    db.commit()
    patch_user_in_supabase(user.id, {"password": user.password})
    return {"status": "success", "message": "Kata sandi berhasil diperbarui dan disinkronkan ke Supabase."}

@router.post("/forgot_password")
@router.post("/forgot_password.php")
def forgot_password(req: ForgotPasswordRequest, db: Session = Depends(get_db)):
    email = (req.email or "").strip()
    nidn = (req.nidn or req.nid or req.nip or "").strip()

    if not email:
        raise HTTPException(status_code=400, detail={"status": "error", "message": "Email wajib diisi."})

    user_id = None
    user_nama = None
    user_email = None

    try:
        safe_email = sanitize_supabase_param(email)
        url = f"{SUPABASE_URL}/rest/v1/users?email=ilike.{safe_email}&select=id,nama,email"
        res = requests.get(url, headers=SB_HEADERS, timeout=5)
        if res.status_code == 200 and res.json():
            res_data = res.json()
            if isinstance(res_data, list) and len(res_data) > 0:
                sb_u = res_data[0]
                user_id = str(sb_u.get("id") or "").strip()
                user_nama = str(sb_u.get("nama") or "").strip()
                user_email = str(sb_u.get("email") or "").strip()
    except Exception as e:
        logger.warning(f"[FORGOT PW] Supabase query error: {e}")

    if not user_id or not user_email:
        raise HTTPException(status_code=400, detail={"status": "error", "message": f"Alamat Email '{email}' tidak terdaftar pada sistem SIPADU."})

    if nidn and user_id.lower() != nidn.lower():
        raise HTTPException(
            status_code=400,
            detail={"status": "error", "message": f"Kombinasi NID/NIP dan Email tidak cocok! NID/NIP '{nidn}' bukan milik email '{email}'."}
        )

    # Generate secure OTP and token
    token_val = secrets.token_urlsafe(32)
    otp_val = f"{random.SystemRandom().randint(100000, 999999)}"

    # Store OTP/Token in database with expiry (15 minutes)
    expiry = datetime.now(timezone.utc) + timedelta(minutes=15)
    existing = db.query(PasswordReset).filter(PasswordReset.email == user_email).first()
    if existing:
        existing.token = token_val
        existing.otp = otp_val
        existing.expires_at = expiry
        existing.created_at = datetime.now(timezone.utc)
    else:
        reset_record = PasswordReset(
            email=user_email,
            token=token_val,
            otp=otp_val,
            expires_at=expiry
        )
        db.add(reset_record)
    db.commit()

    # TODO: Kirim OTP via email menggunakan SMTP service (Resend, Mailgun, dll.)
    # Untuk saat ini, OTP masih dikembalikan di response untuk development
    # Di production, HAPUS "otp" dari response dan kirim via email

    return {
        "status": "success",
        "message": f"Kode OTP pemulihan kata sandi telah dikirimkan ke {user_email}.",
        "token": token_val,
        "otp": otp_val,  # TODO: HAPUS di production — kirim via email
        "email": user_email,
        "nama": user_nama,
        "nidn": user_id
    }

@router.post("/reset_password")
@router.post("/reset_password.php")
def reset_password(req: ResetPasswordRequest, db: Session = Depends(get_db)):
    email = (req.email or "").strip()
    otp = (req.otp or "").strip()
    token = (req.token or "").strip()
    new_password = (req.new_password or req.password or "").strip()

    if not email or not new_password or (not otp and not token):
        raise HTTPException(status_code=400, detail={"status": "error", "message": "Email, OTP/Token, dan password baru wajib diisi."})

    # Validate password strength
    pw_error = validate_password_strength(new_password)
    if pw_error:
        raise HTTPException(status_code=400, detail={"status": "error", "message": pw_error})

    # Verify OTP/Token from database
    reset_record = db.query(PasswordReset).filter(PasswordReset.email.ilike(email)).first()

    if not reset_record:
        raise HTTPException(
            status_code=400,
            detail={"status": "error", "message": "Tidak ada permintaan reset password untuk email ini. Silakan gunakan fitur 'Lupa Kata Sandi' terlebih dahulu."}
        )

    # Check expiry
    if reset_record.expires_at and reset_record.expires_at < datetime.now(timezone.utc):
        db.delete(reset_record)
        db.commit()
        raise HTTPException(
            status_code=400,
            detail={"status": "error", "message": "Kode OTP sudah kedaluwarsa. Silakan minta kode baru."}
        )

    # Verify OTP or Token matches
    otp_match = otp and reset_record.otp == otp
    token_match = token and reset_record.token == token
    if not otp_match and not token_match:
        raise HTTPException(
            status_code=400,
            detail={"status": "error", "message": "Kode OTP atau token tidak valid. Silakan periksa kembali."}
        )

    # Update password
    hashed = get_password_hash(new_password)
    patch_user_in_supabase(email, {"password": hashed})

    # Also update local SQLite if user exists
    local_user = db.query(User).filter(User.email.ilike(email)).first()
    if local_user:
        local_user.password = hashed
    
    # Delete used reset record
    db.delete(reset_record)
    db.commit()

    return {
        "status": "success",
        "message": "Kata sandi Anda berhasil diperbarui! Silakan login dengan kata sandi baru."
    }
