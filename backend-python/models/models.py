import sys
import os
sys.path.insert(0, os.path.dirname(os.path.dirname(os.path.abspath(__file__))))

from sqlalchemy import Column, String, Integer, Boolean, Text, DateTime, ForeignKey
from sqlalchemy.orm import relationship
from datetime import datetime, timezone
from core.database import Base

# [PRESENTASI] Model Database (SQLAlchemy ORM)
# Mengubah class Python menjadi tabel di dalam database relasional (seperti SQLite/PostgreSQL)

class User(Base):
    """
    [PRESENTASI] Tabel 'users': Menyimpan data pengguna aplikasi (Dosen, Kaprodi, Dekan, Admin).
    Digunakan untuk autentikasi dan relasi ke data master (seperti ketersediaan & jadwal mengajar).
    """
    __tablename__ = "users"

    id = Column(String(50), primary_key=True, index=True)
    nama = Column(String(150), nullable=False)
    email = Column(String(150), unique=True, nullable=False, index=True)
    password = Column(String(255), nullable=False)
    role = Column(String(50), nullable=False)  # dosen, kajur, dekan, admin
    jurusan_id = Column(String(50), default="JUR001")
    jurusan_nama = Column(Text, nullable=True)
    fakultas_nama = Column(Text, nullable=True)
    matkul_nama = Column(Text, nullable=True)
    google_id = Column(String(100), nullable=True)
    avatar_url = Column(String(255), nullable=True)
    is_priority = Column(Boolean, default=False)
    created_at = Column(DateTime, default=lambda: datetime.now(timezone.utc))

    mata_kuliah = relationship("MataKuliah", back_populates="dosen", cascade="all, delete-orphan")
    availabilities = relationship("Availability", back_populates="dosen", cascade="all, delete-orphan")
    ajuan = relationship("AjuanPengajaran", back_populates="dosen", cascade="all, delete-orphan")


class Gedung(Base):
    """
    [PRESENTASI] Tabel 'gedung': Menyimpan informasi infrastruktur fisik kampus.
    Digunakan oleh algoritma untuk menentukan apakah ruangan di suatu gedung tersedia di jam tertentu.
    """
    __tablename__ = "gedung"

    id = Column(String(50), primary_key=True, index=True)
    nama = Column(String(100), nullable=False)
    jam_buka = Column(String(10), default="07:00")
    jam_tutup = Column(String(10), default="18:30")
    akses_jurusan = Column(String(255), nullable=False)

    ruangan = relationship("Ruangan", back_populates="gedung", cascade="all, delete-orphan")


class Ruangan(Base):
    """
    [PRESENTASI] Tabel 'ruangan': Menyimpan detail spesifik setiap ruang kelas.
    Berelasi langsung dengan Gedung. Memiliki atribut kapasitas dan tipe yang krusial 
    untuk validasi bentrok saat generate jadwal (CSP).
    """
    __tablename__ = "ruangan"

    id = Column(String(50), primary_key=True, index=True)
    nama = Column(String(100), nullable=False)
    gedung_id = Column(String(50), ForeignKey("gedung.id", ondelete="CASCADE"), nullable=False)
    lantai = Column(String(50), default="Lantai 1")
    kapasitas = Column(Integer, default=40)
    tipe_ruangan = Column(String(100), default="Kelas Teori")
    status = Column(String(50), default="Kosong (Ready)")
    keterangan = Column(Text, nullable=True)

    gedung = relationship("Gedung", back_populates="ruangan")


class SlotWaktu(Base):
    """
    [PRESENTASI] Tabel 'slot_waktu': Menyimpan opsi waktu perkuliahan (Domain Waktu dalam CSP).
    Contoh: Hari Senin 07:30-10:00 (durasi 150 menit).
    Domain ini menjadi pilihan waktu saat CSP menjadwalkan kelas.
    """
    __tablename__ = "slot_waktu"

    id = Column(String(50), primary_key=True, index=True)
    hari = Column(String(20), nullable=False)               # Hari kuliah (Senin - Sabtu)
    jam_mulai = Column(String(10), nullable=False)          # Jam mulai kuliah (contoh: 07:30)
    jam_selesai = Column(String(10), nullable=False)        # Jam selesai kuliah (contoh: 10:00)
    durasi_menit = Column(Integer, default=150)             # Durasi total dalam menit


class MataKuliah(Base):
    """
    [PRESENTASI] Tabel 'mata_kuliah': Menyimpan data mata kuliah beserta dosen pengampu dan beban SKS.
    Menjadi acuan dasar pembuatan tugas jadwal (Task) pada CSP Engine.
    """
    __tablename__ = "mata_kuliah"

    id = Column(String(50), primary_key=True, index=True)
    nama = Column(String(150), nullable=False)
    sks = Column(Integer, default=3)                        # Jumlah SKS (Mempengaruhi durasi waktu kuliah)
    jurusan_id = Column(String(50), default="JUR001")
    jurusan_nama = Column(String(100), nullable=True)
    fakultas_nama = Column(String(100), nullable=True)
    dosen_id = Column(String(50), ForeignKey("users.id", ondelete="CASCADE"), nullable=False)
    dosen_nama = Column(String(150), nullable=True)
    semester_id = Column(String(50), default="SEM001")
    semester_angka = Column(Integer, default=1)
    kebutuhan_tipe_ruangan = Column(String(100), nullable=True) # Contoh: Kelas Teori vs Laboratorium Komputer

    dosen = relationship("User", back_populates="mata_kuliah")
    kelas_list = relationship("MataKuliahKelas", back_populates="mata_kuliah", cascade="all, delete-orphan")


class MataKuliahKelas(Base):
    """
    [PRESENTASI] Tabel 'mata_kuliah_kelas': Pembagian rombongan belajar (paralel) dari mata kuliah.
    Contoh: TI-1A, TI-1B. Masing-masing kelas menjadi variabel independen dalam algoritma CSP.
    """
    __tablename__ = "mata_kuliah_kelas"

    id = Column(Integer, primary_key=True, autoincrement=True)
    mata_kuliah_id = Column(String(50), ForeignKey("mata_kuliah.id", ondelete="CASCADE"), nullable=False)
    kelas_nama = Column(String(50), nullable=False)

    mata_kuliah = relationship("MataKuliah", back_populates="kelas_list")


class Availability(Base):
    """
    [PRESENTASI] Tabel 'availability': Menyimpan form preferensi / ketersediaan waktu mengajar dosen.
    Berfungsi sebagai Soft Constraint / Prioritas Waktu dalam algoritma CSP Engine.
    """
    __tablename__ = "availability"

    id = Column(String(50), primary_key=True, index=True)
    dosen_id = Column(String(50), ForeignKey("users.id", ondelete="CASCADE"), nullable=False)
    semester_id = Column(String(50), default="SEM001")
    status = Column(String(50), default="submitted")  # submitted, verified_kajur, approved_dekan, rejected
    submitted_at = Column(DateTime, default=lambda: datetime.now(timezone.utc))
    updated_at = Column(DateTime, default=lambda: datetime.now(timezone.utc), onupdate=lambda: datetime.now(timezone.utc))

    dosen = relationship("User", back_populates="availabilities")
    slots = relationship("AvailabilitySlot", back_populates="availability", cascade="all, delete-orphan")


class AvailabilitySlot(Base):
    """
    [PRESENTASI] Tabel relasi many-to-many: Menghubungkan form availability dosen dengan id slot waktu yang dipilih.
    """
    __tablename__ = "availability_slots"

    id = Column(Integer, primary_key=True, autoincrement=True)
    availability_id = Column(String(50), ForeignKey("availability.id", ondelete="CASCADE"), nullable=False)
    slot_id = Column(String(50), ForeignKey("slot_waktu.id", ondelete="CASCADE"), nullable=False)

    availability = relationship("Availability", back_populates="slots")
    slot = relationship("SlotWaktu")


class AjuanPengajaran(Base):
    """
    [PRESENTASI] Tabel 'ajuan_pengajaran': Menyimpan usulan/plotting jadwal dari Dosen ke Kaprodi.
    Data ini menjadi input (Variabel CSP) yang akan dicocokkan ke Ruangan & Jam (Domain) oleh Engine CSP & RCK.
    """
    __tablename__ = "ajuan_pengajaran"

    id = Column(String(50), primary_key=True, index=True)
    dosen_id = Column(String(50), ForeignKey("users.id", ondelete="CASCADE"), nullable=False)
    dosen_nama = Column(String(150), nullable=False)
    fakultas_nama = Column(String(100), nullable=True)
    jurusan_nama = Column(String(100), nullable=True)
    mata_kuliah_id = Column(String(50), nullable=False)
    mata_kuliah_nama = Column(String(150), nullable=False)
    sks = Column(Integer, default=3)
    semester = Column(Integer, default=1)
    kelas_nama = Column(String(50), default="TI-1A")
    jumlah_mahasiswa = Column(Integer, default=35)
    gedung_nama = Column(String(100), nullable=False)
    ruangan_nama = Column(String(100), nullable=False)
    hari = Column(String(20), nullable=False)
    jam_mulai = Column(String(10), nullable=False)
    jam_selesai = Column(String(10), nullable=False)
    status = Column(String(50), default="menunggu_kaprodi") # menunggu_kaprodi -> disetujui_kaprodi -> disetujui_admin / bentrok_terdeteksi / menunggu_banding
    catatan_dosen = Column(Text, nullable=True)
    catatan_kaprodi = Column(Text, nullable=True)
    catatan_dekan = Column(Text, nullable=True)
    catatan_admin = Column(Text, nullable=True)
    alasan_penolakan = Column(Text, nullable=True)
    alasan_banding = Column(Text, nullable=True)
    preferensi_banding_hari = Column(String(20), nullable=True)  # Input banding dosen untuk Engine RCK
    preferensi_banding_jam = Column(String(50), nullable=True)   # Input banding dosen untuk Engine RCK
    bentrok_detail = Column(Text, nullable=True)                # Informasi detail bentrok yang dideteksi sistem
    created_at = Column(DateTime, default=lambda: datetime.now(timezone.utc))
    updated_at = Column(DateTime, default=lambda: datetime.now(timezone.utc), onupdate=lambda: datetime.now(timezone.utc))

    dosen = relationship("User", back_populates="ajuan")


class JadwalFinal(Base):
    """
    [PRESENTASI] Tabel 'jadwal_final': Menyimpan solusi akhir hasil eksekusi CSP Engine (Jadwal Terkunci & Valid).
    Jadwal yang tersimpan di sini dipastikan 100% bebas bentrok dan siap dipublikasikan ke mahasiswa & dosen.
    """
    __tablename__ = "jadwal_final"

    id = Column(String(50), primary_key=True, index=True)
    mata_kuliah_id = Column(String(50), nullable=False)
    mata_kuliah_nama = Column(String(150), nullable=False)
    sks = Column(Integer, nullable=False)
    ruangan_nama = Column(String(100), nullable=False)
    gedung_nama = Column(String(100), nullable=False)
    kelas_nama = Column(String(50), nullable=False)
    hari = Column(String(20), nullable=False)
    jam_mulai = Column(String(10), nullable=False)
    jam_selesai = Column(String(10), nullable=False)
    dosen_id = Column(String(50), nullable=True)
    dosen_nama = Column(String(150), nullable=True)
    fakultas_nama = Column(String(100), nullable=True)
    jurusan_nama = Column(String(100), nullable=True)
    semester_nama = Column(String(50), default="Ganjil 2026/2027")
    jumlah_mahasiswa = Column(Integer, default=35)
    created_at = Column(DateTime, default=lambda: datetime.now(timezone.utc))


class Notification(Base):
    __tablename__ = "notifications"

    id = Column(String(50), primary_key=True, index=True)
    user_id = Column(String(50), nullable=True)
    title = Column(String(200), nullable=False)
    message = Column(Text, nullable=False)
    type = Column(String(50), default="info")
    is_read = Column(Boolean, default=False)
    created_at = Column(DateTime, default=lambda: datetime.now(timezone.utc))


class PasswordReset(Base):
    __tablename__ = "password_resets"

    email = Column(String(150), primary_key=True, index=True)
    token = Column(String(100), nullable=False)
    otp = Column(String(10), nullable=False)
    expires_at = Column(DateTime, nullable=True)
    created_at = Column(DateTime, default=lambda: datetime.now(timezone.utc))


class Setting(Base):
    __tablename__ = "settings"

    setting_key = Column(String(100), primary_key=True, index=True)
    setting_value = Column(Text, nullable=False)


class TokenBlacklist(Base):
    """
    [KEAMANAN] Tabel 'token_blacklist': Menyimpan token JWT yang telah dicabut saat logout.
    Mencegah token lama disalahgunakan kembali setelah sesi diakhiri.
    """
    __tablename__ = "token_blacklist"

    id = Column(Integer, primary_key=True, autoincrement=True)
    token = Column(String(500), unique=True, index=True, nullable=False)
    revoked_at = Column(DateTime, default=lambda: datetime.now(timezone.utc))
    expires_at = Column(DateTime, nullable=True)

