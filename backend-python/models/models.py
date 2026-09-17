from sqlalchemy import Column, String, Integer, Boolean, Text, DateTime, ForeignKey
from sqlalchemy.orm import relationship
from datetime import datetime
from core.database import Base

class User(Base):
    __tablename__ = "users"

    id = Column(String(50), primary_key=True, index=True)
    nama = Column(String(150), nullable=False)
    email = Column(String(150), unique=True, nullable=False, index=True)
    password = Column(String(255), nullable=False)
    role = Column(String(50), nullable=False)  # dosen, kajur, dekan, admin
    jurusan_id = Column(String(50), default="JUR001")
    jurusan_nama = Column(String(100), default="Teknik Informatika")
    fakultas_nama = Column(String(100), default="Fakultas Sains & Teknologi")
    google_id = Column(String(100), nullable=True)
    avatar_url = Column(String(255), nullable=True)
    is_priority = Column(Boolean, default=False)
    created_at = Column(DateTime, default=datetime.utcnow)

    mata_kuliah = relationship("MataKuliah", back_populates="dosen", cascade="all, delete-orphan")
    availabilities = relationship("Availability", back_populates="dosen", cascade="all, delete-orphan")
    ajuan = relationship("AjuanPengajaran", back_populates="dosen", cascade="all, delete-orphan")


class Gedung(Base):
    __tablename__ = "gedung"

    id = Column(String(50), primary_key=True, index=True)
    nama = Column(String(100), nullable=False)
    jam_buka = Column(String(10), default="07:00")
    jam_tutup = Column(String(10), default="18:30")
    akses_jurusan = Column(String(255), nullable=False)

    ruangan = relationship("Ruangan", back_populates="gedung", cascade="all, delete-orphan")


class Ruangan(Base):
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
    __tablename__ = "slot_waktu"

    id = Column(String(50), primary_key=True, index=True)
    hari = Column(String(20), nullable=False)
    jam_mulai = Column(String(10), nullable=False)
    jam_selesai = Column(String(10), nullable=False)
    durasi_menit = Column(Integer, default=150)


class MataKuliah(Base):
    __tablename__ = "mata_kuliah"

    id = Column(String(50), primary_key=True, index=True)
    nama = Column(String(150), nullable=False)
    sks = Column(Integer, default=3)
    jurusan_id = Column(String(50), default="JUR001")
    jurusan_nama = Column(String(100), default="Teknik Informatika")
    fakultas_nama = Column(String(100), default="Fakultas Sains & Teknologi")
    dosen_id = Column(String(50), ForeignKey("users.id", ondelete="CASCADE"), nullable=False)
    semester_id = Column(String(50), default="SEM001")
    semester_angka = Column(Integer, default=1)
    kebutuhan_tipe_ruangan = Column(String(100), nullable=True)

    dosen = relationship("User", back_populates="mata_kuliah")
    kelas_list = relationship("MataKuliahKelas", back_populates="mata_kuliah", cascade="all, delete-orphan")


class MataKuliahKelas(Base):
    __tablename__ = "mata_kuliah_kelas"

    id = Column(Integer, primary_key=True, autoincrement=True)
    mata_kuliah_id = Column(String(50), ForeignKey("mata_kuliah.id", ondelete="CASCADE"), nullable=False)
    kelas_nama = Column(String(50), nullable=False)

    mata_kuliah = relationship("MataKuliah", back_populates="kelas_list")


class Availability(Base):
    __tablename__ = "availability"

    id = Column(String(50), primary_key=True, index=True)
    dosen_id = Column(String(50), ForeignKey("users.id", ondelete="CASCADE"), nullable=False)
    semester_id = Column(String(50), default="SEM001")
    status = Column(String(50), default="submitted")  # submitted, verified_kajur, approved_dekan, rejected
    submitted_at = Column(DateTime, default=datetime.utcnow)
    updated_at = Column(DateTime, default=datetime.utcnow, onupdate=datetime.utcnow)

    dosen = relationship("User", back_populates="availabilities")
    slots = relationship("AvailabilitySlot", back_populates="availability", cascade="all, delete-orphan")


class AvailabilitySlot(Base):
    __tablename__ = "availability_slots"

    id = Column(Integer, primary_key=True, autoincrement=True)
    availability_id = Column(String(50), ForeignKey("availability.id", ondelete="CASCADE"), nullable=False)
    slot_id = Column(String(50), ForeignKey("slot_waktu.id", ondelete="CASCADE"), nullable=False)

    availability = relationship("Availability", back_populates="slots")
    slot = relationship("SlotWaktu")


class AjuanPengajaran(Base):
    __tablename__ = "ajuan_pengajaran"

    id = Column(String(50), primary_key=True, index=True)
    dosen_id = Column(String(50), ForeignKey("users.id", ondelete="CASCADE"), nullable=False)
    dosen_nama = Column(String(150), nullable=False)
    fakultas_nama = Column(String(100), default="Fakultas Sains & Teknologi")
    jurusan_nama = Column(String(100), default="Teknik Informatika")
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
    status = Column(String(50), default="menunggu_kaprodi")
    catatan_dosen = Column(Text, nullable=True)
    catatan_kaprodi = Column(Text, nullable=True)
    catatan_dekan = Column(Text, nullable=True)
    catatan_admin = Column(Text, nullable=True)
    alasan_penolakan = Column(Text, nullable=True)
    alasan_banding = Column(Text, nullable=True)
    preferensi_banding_hari = Column(String(20), nullable=True)
    preferensi_banding_jam = Column(String(50), nullable=True)
    bentrok_detail = Column(Text, nullable=True)
    created_at = Column(DateTime, default=datetime.utcnow)
    updated_at = Column(DateTime, default=datetime.utcnow, onupdate=datetime.utcnow)

    dosen = relationship("User", back_populates="ajuan")


class JadwalFinal(Base):
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
    fakultas_nama = Column(String(100), default="Fakultas Sains & Teknologi")
    jurusan_nama = Column(String(100), default="Teknik Informatika")
    semester_nama = Column(String(50), default="Ganjil 2026/2027")
    jumlah_mahasiswa = Column(Integer, default=35)
    created_at = Column(DateTime, default=datetime.utcnow)


class Notification(Base):
    __tablename__ = "notifications"

    id = Column(String(50), primary_key=True, index=True)
    user_id = Column(String(50), nullable=True)
    title = Column(String(200), nullable=False)
    message = Column(Text, nullable=False)
    type = Column(String(50), default="info")
    is_read = Column(Boolean, default=False)
    created_at = Column(DateTime, default=datetime.utcnow)


class PasswordReset(Base):
    __tablename__ = "password_resets"

    email = Column(String(150), primary_key=True, index=True)
    token = Column(String(100), nullable=False)
    otp = Column(String(10), nullable=False)
    expires_at = Column(DateTime, nullable=True)
    created_at = Column(DateTime, default=datetime.utcnow)


class Setting(Base):
    __tablename__ = "settings"

    setting_key = Column(String(100), primary_key=True, index=True)
    setting_value = Column(Text, nullable=False)
