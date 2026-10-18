# File: core/security.py
# Deskripsi: Modul keamanan JWT untuk autentikasi dan otorisasi endpoint API.
# Fitur: JWT token creation/verification, role-based access control, password validation.

from datetime import datetime, timedelta, timezone
from typing import Optional, List
from fastapi import Depends, HTTPException, status, Request
from fastapi.security import HTTPBearer, HTTPAuthorizationCredentials
from sqlalchemy.orm import Session
from core.config import settings
from core.database import get_db
from models.models import User, TokenBlacklist
import re
import hmac
import hashlib
import base64
import json

try:
    from jose import JWTError, jwt
    HAS_JOSE = True
except ImportError:
    HAS_JOSE = False
    JWTError = Exception

# HTTP Bearer token scheme
bearer_scheme = HTTPBearer(auto_error=False)


def create_access_token(user_id: str, role: str, email: str) -> str:
    """
    [PRESENTASI] Membuat JSON Web Token (JWT) setelah pengguna berhasil login.
    Token ini memuat informasi pengguna (id, role, email) yang telah dienkripsi.
    Akan kedaluwarsa sesuai waktu yang ditentukan (exp).
    """
    expire = datetime.now(timezone.utc) + timedelta(minutes=settings.ACCESS_TOKEN_EXPIRE_MINUTES)
    payload = {
        "sub": user_id,
        "role": role,
        "email": email,
        "exp": int(expire.timestamp()), # Waktu kedaluwarsa token
        "iat": int(datetime.now(timezone.utc).timestamp()), # Waktu token dibuat
    }
    if HAS_JOSE:
        # Enkripsi dengan pustaka "jose" (Lebih aman dan standar)
        return jwt.encode(payload, settings.JWT_SECRET or "default_sec_jwt", algorithm=settings.ALGORITHM)
    else:
        # [PRESENTASI] Zero-dependency HMAC fallback:
        # Membuat dan menandatangani token manual tanpa pustaka eksternal jika "jose" tidak terinstal.
        header = base64.urlsafe_b64encode(json.dumps({"alg": "HS256", "typ": "JWT"}).encode()).decode().rstrip("=")
        body = base64.urlsafe_b64encode(json.dumps(payload).encode()).decode().rstrip("=")
        secret = (settings.JWT_SECRET or "default_sec_jwt").encode()
        sig = hmac.new(secret, f"{header}.{body}".encode(), hashlib.sha256).digest()
        sig_str = base64.urlsafe_b64encode(sig).decode().rstrip("=")
        return f"{header}.{body}.{sig_str}"


def verify_token(token: str) -> dict:
    """
    [PRESENTASI] Memverifikasi apakah JWT token valid, asli (tidak dimanipulasi), dan belum kedaluwarsa.
    Jika ada masalah, sistem akan memberikan exception Unauthorized.
    """
    try:
        if HAS_JOSE:
            # Pustaka bawaan akan otomatis mengecek masa aktif dan keaslian token
            payload = jwt.decode(token, settings.JWT_SECRET or "default_sec_jwt", algorithms=[settings.ALGORITHM])
        else:
            # Fallback jika tidak ada pustaka, harus diverifikasi manual komponen per komponen
            parts = token.split(".")
            if len(parts) != 3:
                raise ValueError("Invalid token format")
            header_str, body_str, sig_str = parts
            secret = (settings.JWT_SECRET or "default_sec_jwt").encode()
            expected_sig = hmac.new(secret, f"{header_str}.{body_str}".encode(), hashlib.sha256).digest()
            expected_sig_str = base64.urlsafe_b64encode(expected_sig).decode().rstrip("=")
            if not hmac.compare_digest(sig_str, expected_sig_str):
                raise ValueError("Signature mismatch")
            # Pad body base64
            padded = body_str + "=" * ((4 - len(body_str) % 4) % 4)
            payload = json.loads(base64.urlsafe_b64decode(padded.encode()).decode())
            if payload.get("exp") and payload["exp"] < datetime.now(timezone.utc).timestamp():
                raise ValueError("Token expired")

        user_id: str = payload.get("sub")
        if user_id is None:
            raise HTTPException(
                status_code=status.HTTP_401_UNAUTHORIZED,
                detail={"status": "error", "message": "Token tidak valid — user ID tidak ditemukan."}
            )
        return payload
    except Exception:
        raise HTTPException(
            status_code=status.HTTP_401_UNAUTHORIZED,
            detail={"status": "error", "message": "Token tidak valid atau sudah kedaluwarsa. Silakan login ulang."}
        )


async def get_current_user(
    credentials: Optional[HTTPAuthorizationCredentials] = Depends(bearer_scheme),
    db: Session = Depends(get_db),
) -> User:
    """
    [PRESENTASI] FastAPI Dependency: Mengambil Data Pengguna yang Sedang Login.
    Setiap request yang butuh login akan melewati fungsi ini. Mengekstrak token dari header, 
    memvalidasinya, mengecek blacklist logout, dan menarik objek User dari database.
    """
    if credentials is None:
        raise HTTPException(
            status_code=status.HTTP_401_UNAUTHORIZED,
            detail={"status": "error", "message": "Autentikasi diperlukan. Silakan login terlebih dahulu."},
            headers={"WWW-Authenticate": "Bearer"},
        )

    # 1. Cek apakah token berada di dalam daftar Token Blacklist (Logout)
    token_str = credentials.credentials
    try:
        blacklisted = db.query(TokenBlacklist).filter(TokenBlacklist.token == token_str).first()
        if blacklisted:
            raise HTTPException(
                status_code=status.HTTP_401_UNAUTHORIZED,
                detail={"status": "error", "message": "Sesi telah kedaluwarsa atau Anda telah logout. Silakan login kembali."}
            )
    except HTTPException:
        raise
    except Exception:
        pass

    # 2. Dekode dan pastikan token valid
    payload = verify_token(token_str)
    user_id = payload.get("sub")

    # 3. Cari data user di database (mengecek apakah user masih terdaftar/aktif)
    user = db.query(User).filter(User.id == user_id).first()
    if user is None:
        raise HTTPException(
            status_code=status.HTTP_401_UNAUTHORIZED,
            detail={"status": "error", "message": "User tidak ditemukan. Silakan login ulang."}
        )
    return user


def require_role(*allowed_roles: str):
    """
    [PRESENTASI] RBAC (Role-Based Access Control)
    Fungsi pelindung endpoint (Dependency factory) yang memblokir akses 
    jika role pengguna yang sedang login tidak sesuai dengan yang diizinkan (misal: 'admin').
    """
    async def role_checker(current_user: User = Depends(get_current_user)) -> User:
        if current_user.role not in allowed_roles:
            raise HTTPException(
                status_code=status.HTTP_403_FORBIDDEN, # 403 Forbidden: Dilarang akses
                detail={
                    "status": "error",
                    "message": f"Akses ditolak. Fitur ini hanya untuk role: {', '.join(allowed_roles)}."
                }
            )
        return current_user
    return role_checker


def validate_password_strength(password: str) -> Optional[str]:
    """
    Validasi kekuatan password. Return pesan error jika lemah, None jika kuat.
    Minimal: 8 karakter, 1 huruf besar, 1 huruf kecil, 1 angka.
    """
    if len(password) < 8:
        return "Kata sandi harus minimal 8 karakter."
    if not re.search(r'[A-Z]', password):
        return "Kata sandi harus mengandung minimal 1 huruf besar."
    if not re.search(r'[a-z]', password):
        return "Kata sandi harus mengandung minimal 1 huruf kecil."
    if not re.search(r'[0-9]', password):
        return "Kata sandi harus mengandung minimal 1 angka."
    return None


def sanitize_supabase_param(value: str) -> str:
    """Sanitasi input sebelum dimasukkan ke Supabase REST URL query."""
    # Remove characters yang bisa memanipulasi PostgREST query
    return re.sub(r'[;\'\"\\()&|!,]', '', value.strip())
