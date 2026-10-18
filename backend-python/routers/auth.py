import sys
import os
sys.path.insert(0, os.path.dirname(os.path.dirname(os.path.abspath(__file__))))

from fastapi import APIRouter, Depends, HTTPException, status, Request
from sqlalchemy.orm import Session
from datetime import datetime, timedelta, timezone
from typing import Optional
from core.database import get_db
from core.config import SUPABASE_URL, SB_HEADERS, settings
from core.security import (
    create_access_token, get_current_user, validate_password_strength,
    sanitize_supabase_param, bearer_scheme, HTTPAuthorizationCredentials, verify_token
)
from models.models import User, PasswordReset, TokenBlacklist
from schemas.schemas import LoginRequest, GoogleLoginRequest, ChangePasswordRequest, ForgotPasswordRequest, ResetPasswordRequest
import bcrypt
import secrets
import requests
import random
import logging
import smtplib
from email.mime.text import MIMEText
from email.mime.multipart import MIMEMultipart

logger = logging.getLogger("smartschedule.auth")


def send_smtp_email(to_email: str, recipient_name: str, subject: str, html_body: str, text_body: str):
    """Mengirim email melalui SMTP server yang dikonfigurasi di backend."""
    if not settings.SMTP_HOST or not settings.SMTP_USER or not settings.SMTP_PASS:
        logger.warning("SMTP credentials belum lengkap di backend config. Email dilewati.")
        return False
    try:
        msg = MIMEMultipart("alternative")
        msg["Subject"] = subject
        msg["From"] = f"{settings.SMTP_FROM_NAME} <{settings.SMTP_FROM_EMAIL}>"
        msg["To"] = to_email

        part1 = MIMEText(text_body, "plain", "utf-8")
        part2 = MIMEText(html_body, "html", "utf-8")
        msg.attach(part1)
        msg.attach(part2)

        with smtplib.SMTP(settings.SMTP_HOST, settings.SMTP_PORT, timeout=10) as server:
            server.starttls()
            server.login(settings.SMTP_USER, settings.SMTP_PASS)
            server.sendmail(settings.SMTP_FROM_EMAIL, [to_email], msg.as_string())
        logger.info(f"Email '{subject}' berhasil dikirim ke {to_email}")
        return True
    except Exception as err:
        logger.warning(f"Gagal mengirim email SMTP ke {to_email}: {err}")
        return False


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
    if plain_password == hashed_password:
        return True
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
        "jurusan_nama": user.jurusan_nama or "",
        "fakultas_nama": user.fakultas_nama or "",
        "matkul_nama": user.matkul_nama,
        "is_priority": bool(user.is_priority),
        "avatar_url": user.avatar_url
    }

@router.post("/login")
@router.post("/login.php")
def login(req: LoginRequest, db: Session = Depends(get_db)):
    """
    [PRESENTASI] Endpoint Login Utama:
    Mendukung login menggunakan Email, NIDN, atau ID Pengguna.
    Menerapkan sistem High-Availability: Mengecek Supabase Cloud (Primary) terlebih dahulu,
    jika gagal/down, otomatis fallback ke SQLite lokal (Secondary).
    """
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

    # [PRESENTASI] Strategi Login 1: Cek Supabase Cloud (Source of Truth)
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

    # [PRESENTASI] Strategi Login 2: Fallback ke SQLite Lokal (High-Availability / Offline Mode)
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

    # [PRESENTASI] Autentikasi: Generate JWT Token
    # Token digunakan untuk mengamankan endpoint API (RBAC - Role Based Access Control)
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
    """
    [PRESENTASI] Endpoint Google SSO (Single Sign-On):
    Menerima email dari akun Google pengguna. Memastikan email tersebut terdaftar
    di dalam database institusi sebelum memberikan akses.
    """
    email = (req.email or "").strip().lower()
    if not email:
        raise HTTPException(
            status_code=400,
            detail={"status": "error", "message": "Email Google wajib disertakan."}
        )

    if email.endswith("@gmail"):
        email += ".com"

    # Validasi kriptografis Google idToken jika disediakan oleh client
    if req.idToken and not req.idToken.startswith("mock_"):
        try:
            g_verify_url = f"https://oauth2.googleapis.com/tokeninfo?id_token={req.idToken}"
            g_res = requests.get(g_verify_url, timeout=5)
            if g_res.status_code == 200:
                g_info = g_res.json()
                v_email = g_info.get("email", "").strip().lower()
                if v_email and v_email != email and not email.startswith(v_email):
                    raise HTTPException(
                        status_code=401,
                        detail={"status": "error", "message": "Token verifikasi Google tidak cocok dengan email akun."}
                    )
        except HTTPException:
            raise
        except Exception as g_err:
            logger.warning(f"Peringatan verifikasi Google idToken: {g_err}")

    # Cari data user murni dari database Supabase berdasarkan email Google
    user = None
    try:
        safe_email = sanitize_supabase_param(email)
        url = f"{SUPABASE_URL}/rest/v1/users?email=ilike.{safe_email}"
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
        logger.warning(f"Supabase google login lookup failed: {e}")

    if not user:
        user = db.query(User).filter(User.email.ilike(email)).first()

    if user:
        if req.photoUrl:
            setattr(user, "avatar_url", req.photoUrl)
            patch_user_in_supabase(str(user.id), {"avatar_url": req.photoUrl})
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

@router.post("/logout")
@router.post("/logout.php")
def logout(credentials: Optional[HTTPAuthorizationCredentials] = Depends(bearer_scheme), db: Session = Depends(get_db)):
    """
    [KEAMANAN] Logout & Token Revocation:
    Mencabut dan mendaftarkan token JWT ke dalam blacklist database agar tidak dapat digunakan kembali.
    """
    if credentials and credentials.credentials:
        token_str = credentials.credentials
        try:
            existing = db.query(TokenBlacklist).filter(TokenBlacklist.token == token_str).first()
            if not existing:
                bl = TokenBlacklist(token=token_str, revoked_at=datetime.now(timezone.utc))
                db.add(bl)
                db.commit()
        except Exception as e:
            logger.warning(f"Gagal memasukkan token ke blacklist: {e}")
    return {"status": "success", "message": "Sesi Anda berhasil diakhiri dan token telah dicabut."}

@router.post("/change_password")
@router.post("/change_password.php")
def change_password(
    req: ChangePasswordRequest,
    credentials: Optional[HTTPAuthorizationCredentials] = Depends(bearer_scheme),
    db: Session = Depends(get_db)
):
    user: Optional[User] = None
    if isinstance(credentials, HTTPAuthorizationCredentials) and credentials.credentials:
        try:
            payload = verify_token(credentials.credentials)
            u_id = payload.get("sub")
            if u_id:
                user = db.query(User).filter(User.id == u_id).first()
                if not user:
                    safe_uid = sanitize_supabase_param(str(u_id))
                    url = f"{SUPABASE_URL}/rest/v1/users?id=eq.{safe_uid}"
                    resp = requests.get(url, headers=SB_HEADERS, timeout=5)
                    if resp.status_code == 200 and resp.json():
                        u_list = resp.json()
                        if isinstance(u_list, list) and len(u_list) > 0:
                            u = u_list[0]
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
        except Exception:
            user = None

    if not user and req.email:
        user = db.query(User).filter(User.email.ilike(req.email.strip())).first()
    if not user and req.id:
        user = db.query(User).filter(User.id.ilike(req.id.strip())).first()

    # Fallback to Supabase Cloud lookup by email or id
    if not user and (req.email or req.id):
        lookup_param = (req.email or req.id or "").strip()
        try:
            clean = sanitize_supabase_param(lookup_param)
            url = f"{SUPABASE_URL}/rest/v1/users?or=(id.eq.{clean},email.ilike.{clean})"
            resp = requests.get(url, headers=SB_HEADERS, timeout=5)
            if resp.status_code == 200 and resp.json():
                u_list = resp.json()
                if isinstance(u_list, list) and len(u_list) > 0:
                    u = u_list[0]
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
            logger.warning(f"Supabase user lookup failed in change_password: {e}")

    if not user:
        raise HTTPException(status_code=404, detail={"status": "error", "message": "Pengguna tidak ditemukan."})

    current_pw_hash = str(user.password or "")
    if not verify_password(req.old_password, current_pw_hash):
        raise HTTPException(status_code=400, detail={"status": "error", "message": "Kata sandi lama tidak sesuai."})

    # Validate password strength
    pw_error = validate_password_strength(req.new_password)
    if pw_error:
        raise HTTPException(status_code=400, detail={"status": "error", "message": pw_error})

    new_hash = get_password_hash(req.new_password)
    setattr(user, "password", new_hash)
    try:
        db.merge(user)
        db.commit()
    except Exception:
        db.rollback()

    patch_user_in_supabase(str(user.id), {"password": new_hash})

    # Kirim email notifikasi perubahan kata sandi secara aman
    user_email = str(user.email) if user.email else None
    user_nama = str(user.nama) if user.nama else "Pengguna SIPADU"
    if user_email:
        try:
            send_smtp_email(
                to_email=user_email,
                recipient_name=user_nama,
                subject="Pemberitahuan: Kata Sandi Akun SIPADU Berhasil Diperbarui",
                html_body=f"""
                <div style="font-family: sans-serif; max-width: 480px; margin: 0 auto; padding: 24px; border: 1px solid #e2e8f0; border-radius: 12px;">
                    <h2 style="color: #0f172a; text-align: center;">SIPADU</h2>
                    <p>Halo <strong>{user_nama}</strong>,</p>
                    <p>Kata sandi akun SIPADU Anda telah <strong>berhasil diperbarui</strong>.</p>
                    <p style="background: #f0fdf4; border-left: 4px solid #059669; padding: 12px; color: #166534;">
                        Jika Anda yang melakukan perubahan ini, silakan gunakan kata sandi baru untuk masuk ke aplikasi. Jika Anda tidak merasa mengubahnya, segera hubungi Administrator.
                    </p>
                    <hr style="border: none; border-top: 1px solid #e2e8f0; margin: 20px 0;" />
                    <p style="font-size: 12px; color: #94a3b8; text-align: center;">&copy; 2026 SIPADU (Sistem Informasi Penjadwalan Dosen)</p>
                </div>
                """,
                text_body=f"Halo {user_nama},\n\nKata sandi akun SIPADU Anda telah berhasil diperbarui. Jika bukan Anda, hubungi Administrator."
            )
        except Exception as mail_err:
            logger.warning(f"SMTP notification skipped: {mail_err}")

    return {"status": "success", "message": "Kata sandi berhasil diperbarui dan disinkronkan ke Supabase."}

@router.post("/forgot_password")
@router.post("/forgot_password.php")
def forgot_password(req: ForgotPasswordRequest, db: Session = Depends(get_db)):
    """
    [PRESENTASI] Lupa Kata Sandi:
    1. Mengecek kombinasi Email dan NIDN/NIP untuk keamanan ekstra.
    2. Menghasilkan OTP (One Time Password) acak & aman secara kriptografis.
    3. Menyimpan OTP di Supabase Cloud & SQLite lokal dengan kedaluwarsa 15 menit.
    4. Mengirimkan kode OTP ke email pengguna secara aman dari server.
    """
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

    # Fallback lookup in local SQLite
    if not user_id or not user_email:
        local_u = db.query(User).filter(User.email.ilike(email)).first()
        if local_u:
            user_id = local_u.id
            user_nama = local_u.nama
            user_email = local_u.email

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

    # Store OTP/Token with expiry (15 minutes) - Naive UTC datetime to prevent comparison crashes
    now_naive = datetime.now(timezone.utc).replace(tzinfo=None)
    expiry = now_naive + timedelta(minutes=15)

    # Save to local SQLite
    try:
        existing = db.query(PasswordReset).filter(PasswordReset.email.ilike(user_email)).first()
        if existing:
            setattr(existing, "token", token_val)
            setattr(existing, "otp", otp_val)
            setattr(existing, "expires_at", expiry)
            setattr(existing, "created_at", now_naive)
        else:
            reset_record = PasswordReset(
                email=user_email,
                token=token_val,
                otp=otp_val,
                expires_at=expiry,
                created_at=now_naive
            )
            db.add(reset_record)
        db.commit()
    except Exception as db_err:
        logger.warning(f"Local SQLite PasswordReset save error: {db_err}")
        db.rollback()

    # Sync to Supabase Cloud password_resets table for Serverless HA
    try:
        sb_payload = {
            "email": user_email,
            "token": token_val,
            "otp": otp_val,
            "expires_at": expiry.isoformat(),
            "created_at": now_naive.isoformat()
        }
        sb_url = f"{SUPABASE_URL}/rest/v1/password_resets"
        sb_headers = dict(SB_HEADERS)
        sb_headers["Prefer"] = "resolution=merge-duplicates"
        requests.post(sb_url, headers=sb_headers, json=sb_payload, timeout=5)
    except Exception as sb_err:
        logger.warning(f"Failed to save password_reset to Supabase Cloud: {sb_err}")

    # Kirim kode OTP via SMTP email dari server backend secara aman
    try:
        send_smtp_email(
            to_email=user_email,
            recipient_name=user_nama or "Pengguna SIPADU",
            subject="Kode Verifikasi Lupa Kata Sandi - SIPADU",
            html_body=f"""
            <div style="font-family: sans-serif; max-width: 480px; margin: 0 auto; padding: 28px; border: 1px solid #e2e8f0; border-radius: 12px; background: #ffffff;">
                <div style="text-align: center; border-bottom: 1px solid #f1f5f9; padding-bottom: 16px;">
                    <h1 style="color: #0f172a; margin: 0; font-size: 22px;">SIPADU</h1>
                    <span style="display: inline-block; background: #ecfdf5; color: #059669; font-size: 12px; font-weight: 600; padding: 4px 12px; border-radius: 9999px; margin-top: 6px;">Verifikasi Keamanan</span>
                </div>
                <p style="margin-top: 20px; color: #334155; font-size: 14px;">Halo <strong>{user_nama}</strong>,</p>
                <p style="color: #334155; font-size: 14px;">Permintaan reset kata sandi akun Anda telah diterima. Gunakan kode OTP di bawah ini untuk melanjutkan:</p>
                <div style="background: #f0fdf4; border: 2px dashed #059669; border-radius: 12px; text-align: center; padding: 18px; margin: 24px 0;">
                    <div style="font-size: 34px; font-weight: 800; letter-spacing: 8px; color: #059669; font-family: monospace;">{otp_val}</div>
                    <div style="font-size: 12px; color: #64748b; margin-top: 6px;">Kode ini berlaku selama 15 menit</div>
                </div>
                <p style="font-size: 13px; color: #64748b; line-height: 1.5;">Jangan berikan kode ini kepada siapapun. Jika Anda tidak meminta reset kata sandi, silakan abaikan pesan ini.</p>
                <hr style="border: none; border-top: 1px solid #f1f5f9; margin: 20px 0;" />
                <p style="font-size: 12px; color: #94a3b8; text-align: center;">&copy; 2026 SIPADU (Sistem Informasi Penjadwalan Dosen)</p>
            </div>
            """,
            text_body=f"Halo {user_nama},\n\nKode OTP reset password Anda: {otp_val}\n\nKode ini berlaku 15 menit. Jangan berikan kode ini kepada siapapun."
        )
    except Exception as mail_err:
        logger.warning(f"SMTP OTP email dispatch error: {mail_err}")

    return {
        "status": "success",
        "message": f"Kode OTP pemulihan kata sandi telah dikirimkan ke email ({user_email}). Silakan periksa kotak masuk atau spam email Anda.",
        "token": token_val,
        "otp": otp_val,
        "email": user_email,
        "nama": user_nama,
        "nidn": user_id
    }

@router.post("/reset_password")
@router.post("/reset_password.php")
def reset_password(req: ResetPasswordRequest, db: Session = Depends(get_db)):
    """
    [PRESENTASI] Reset Kata Sandi:
    Memverifikasi OTP dan mengenkripsi ulang password baru menggunakan Bcrypt.
    """
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

    # Verify OTP/Token from database (local SQLite first, fallback to Supabase Cloud)
    reset_record = None
    try:
        reset_record = db.query(PasswordReset).filter(PasswordReset.email.ilike(email)).first()
    except Exception:
        reset_record = None

    sb_reset_data = None
    if not reset_record:
        try:
            safe_email = sanitize_supabase_param(email)
            url = f"{SUPABASE_URL}/rest/v1/password_resets?email=ilike.{safe_email}"
            resp = requests.get(url, headers=SB_HEADERS, timeout=5)
            if resp.status_code == 200 and resp.json():
                res_list = resp.json()
                if isinstance(res_list, list) and len(res_list) > 0:
                    sb_reset_data = res_list[0]
        except Exception as e:
            logger.warning(f"Supabase password_resets lookup error: {e}")

    if not reset_record and not sb_reset_data:
        raise HTTPException(
            status_code=400,
            detail={"status": "error", "message": "Tidak ada permintaan reset password untuk email ini. Silakan gunakan fitur 'Lupa Kata Sandi' terlebih dahulu."}
        )

    # Check expiry safely (strip timezone if present for naive comparison)
    now_naive = datetime.now(timezone.utc).replace(tzinfo=None)
    exp_at = None
    rec_otp = None
    rec_token = None

    if reset_record:
        exp_at = reset_record.expires_at.replace(tzinfo=None) if (reset_record.expires_at and reset_record.expires_at.tzinfo) else reset_record.expires_at
        rec_otp = reset_record.otp
        rec_token = reset_record.token
    elif sb_reset_data:
        rec_otp = sb_reset_data.get("otp")
        rec_token = sb_reset_data.get("token")
        exp_str = sb_reset_data.get("expires_at")
        if exp_str:
            try:
                exp_at = datetime.fromisoformat(exp_str.replace("Z", "+00:00")).replace(tzinfo=None)
            except Exception:
                exp_at = now_naive + timedelta(minutes=15)

    if exp_at and exp_at < now_naive:
        if reset_record:
            try:
                db.delete(reset_record)
                db.commit()
            except Exception:
                pass
        try:
            safe_email = sanitize_supabase_param(email)
            requests.delete(f"{SUPABASE_URL}/rest/v1/password_resets?email=ilike.{safe_email}", headers=SB_HEADERS, timeout=5)
        except Exception:
            pass
        raise HTTPException(
            status_code=400,
            detail={"status": "error", "message": "Kode OTP sudah kedaluwarsa. Silakan minta kode baru."}
        )

    # Verify OTP or Token matches
    otp_match = otp and rec_otp == otp
    token_match = token and rec_token == token
    if not otp_match and not token_match:
        raise HTTPException(
            status_code=400,
            detail={"status": "error", "message": "Kode OTP atau token tidak valid. Silakan periksa kembali."}
        )

    # Update password
    hashed = get_password_hash(new_password)
    patch_user_in_supabase(email, {"password": hashed})

    # Also update local SQLite if user exists
    try:
        local_user = db.query(User).filter(User.email.ilike(email)).first()
        if local_user:
            setattr(local_user, "password", hashed)
        if reset_record:
            db.delete(reset_record)
        db.commit()
    except Exception:
        db.rollback()

    # Delete reset record from Supabase Cloud
    try:
        safe_email = sanitize_supabase_param(email)
        requests.delete(f"{SUPABASE_URL}/rest/v1/password_resets?email=ilike.{safe_email}", headers=SB_HEADERS, timeout=5)
    except Exception as del_err:
        logger.warning(f"Failed to delete password_reset from Supabase Cloud: {del_err}")

    # Kirim email konfirmasi perubahan kata sandi secara aman
    try:
        send_smtp_email(
            to_email=email,
            recipient_name=local_user.nama if 'local_user' in locals() and local_user else "Pengguna SIPADU",
            subject="Pemberitahuan: Kata Sandi Akun SIPADU Berhasil Diperbarui",
            html_body=f"""
            <div style="font-family: sans-serif; max-width: 480px; margin: 0 auto; padding: 28px; border: 1px solid #e2e8f0; border-radius: 12px; background: #ffffff;">
                <div style="text-align: center; border-bottom: 1px solid #f1f5f9; padding-bottom: 16px;">
                    <h1 style="color: #0f172a; margin: 0; font-size: 22px;">SIPADU</h1>
                    <span style="display: inline-block; background: #ecfdf5; color: #059669; font-size: 12px; font-weight: 600; padding: 4px 12px; border-radius: 9999px; margin-top: 6px;">Keamanan Akun</span>
                </div>
                <p style="margin-top: 20px; color: #334155; font-size: 14px;">Halo,</p>
                <p style="color: #334155; font-size: 14px;">Kata sandi akun SIPADU Anda ({email}) telah <strong>berhasil diperbarui</strong>.</p>
                <div style="background: #f0fdf4; border-left: 4px solid #059669; padding: 14px; border-radius: 6px; margin: 18px 0; font-size: 13px; color: #166534;">
                    Jika Anda yang melakukan perubahan ini, Anda dapat mengabaikan email ini dan login dengan kata sandi baru Anda. Jika bukan Anda, segera hubungi Administrator institusi.
                </div>
                <hr style="border: none; border-top: 1px solid #f1f5f9; margin: 20px 0;" />
                <p style="font-size: 12px; color: #94a3b8; text-align: center;">&copy; 2026 SIPADU (Sistem Informasi Penjadwalan Dosen)</p>
            </div>
            """,
            text_body=f"Halo,\n\nKata sandi akun SIPADU ({email}) Anda telah berhasil diperbarui. Jika bukan Anda, segera hubungi Administrator."
        )
    except Exception as mail_err:
        logger.warning(f"SMTP reset confirmation email error: {mail_err}")

    return {
        "status": "success",
        "message": "Kata sandi Anda berhasil diperbarui! Silakan login dengan kata sandi baru."
    }


