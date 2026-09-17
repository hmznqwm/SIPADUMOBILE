-- ============================================================
-- DATABASE SCHEMA & 1 SEMESTER FULL SIMULATION DATASET
-- SYSTEM: SMART COURSE SCHEDULER (SIDAL)
-- Target Database: PostgreSQL (Supabase)
-- ============================================================

-- Enable UUID extension if needed
CREATE EXTENSION IF NOT EXISTS "uuid-ossp";

-- 1. TABEL USERS (Dosen, KaProdi, Dekan, Admin)
DROP TABLE IF EXISTS notifications CASCADE;
DROP TABLE IF EXISTS password_resets CASCADE;
DROP TABLE IF EXISTS jadwal_final CASCADE;
DROP TABLE IF EXISTS ajuan_pengajaran CASCADE;
DROP TABLE IF EXISTS availability_slots CASCADE;
DROP TABLE IF EXISTS availability CASCADE;
DROP TABLE IF EXISTS mata_kuliah_kelas CASCADE;
DROP TABLE IF EXISTS mata_kuliah CASCADE;
DROP TABLE IF EXISTS slot_waktu CASCADE;
DROP TABLE IF EXISTS ruangan CASCADE;
DROP TABLE IF EXISTS gedung CASCADE;
DROP TABLE IF EXISTS users CASCADE;

CREATE TABLE users (
  id VARCHAR(50) PRIMARY KEY,
  nama VARCHAR(150) NOT NULL,
  email VARCHAR(150) NOT NULL UNIQUE,
  password VARCHAR(255) NOT NULL,
  role VARCHAR(50) NOT NULL CHECK (role IN ('dosen', 'kajur', 'dekan', 'admin')),
  jurusan_id VARCHAR(50) DEFAULT 'JUR001',
  jurusan_nama VARCHAR(100) DEFAULT 'Teknik Informatika',
  fakultas_nama VARCHAR(100) DEFAULT 'Fakultas Sains & Teknologi',
  google_id VARCHAR(100) DEFAULT NULL,
  avatar_url VARCHAR(255) DEFAULT NULL,
  is_priority BOOLEAN DEFAULT FALSE,
  created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP
);

-- 2. TABEL GEDUNG
CREATE TABLE gedung (
  id VARCHAR(50) PRIMARY KEY,
  nama VARCHAR(100) NOT NULL,
  jam_buka VARCHAR(10) NOT NULL DEFAULT '07:00',
  jam_tutup VARCHAR(10) NOT NULL DEFAULT '18:30',
  akses_jurusan VARCHAR(255) NOT NULL
);

-- 3. TABEL RUANGAN
CREATE TABLE ruangan (
  id VARCHAR(50) PRIMARY KEY,
  nama VARCHAR(100) NOT NULL,
  gedung_id VARCHAR(50) NOT NULL REFERENCES gedung(id) ON DELETE CASCADE,
  lantai VARCHAR(50) DEFAULT 'Lantai 1',
  kapasitas INT NOT NULL DEFAULT 40,
  tipe_ruangan VARCHAR(100) NOT NULL DEFAULT 'Kelas Teori',
  status VARCHAR(50) NOT NULL DEFAULT 'Kosong (Ready)',
  keterangan TEXT
);

-- 4. TABEL SLOT WAKTU
CREATE TABLE slot_waktu (
  id VARCHAR(50) PRIMARY KEY,
  hari VARCHAR(20) NOT NULL,
  jam_mulai VARCHAR(10) NOT NULL,
  jam_selesai VARCHAR(10) NOT NULL,
  durasi_menit INT NOT NULL DEFAULT 150
);

-- 5. TABEL MATA KULIAH
CREATE TABLE mata_kuliah (
  id VARCHAR(50) PRIMARY KEY,
  nama VARCHAR(150) NOT NULL,
  sks INT NOT NULL DEFAULT 3,
  jurusan_id VARCHAR(50) NOT NULL,
  jurusan_nama VARCHAR(100) NOT NULL,
  fakultas_nama VARCHAR(100) NOT NULL,
  dosen_id VARCHAR(50) NOT NULL REFERENCES users(id) ON DELETE CASCADE,
  semester_id VARCHAR(50) DEFAULT 'SEM001',
  semester_angka INT DEFAULT 1,
  kebutuhan_tipe_ruangan VARCHAR(100) DEFAULT NULL
);

-- 6. TABEL MATA KULIAH KELAS
CREATE TABLE mata_kuliah_kelas (
  id SERIAL PRIMARY KEY,
  mata_kuliah_id VARCHAR(50) NOT NULL REFERENCES mata_kuliah(id) ON DELETE CASCADE,
  kelas_nama VARCHAR(50) NOT NULL
);

-- 7. TABEL KETERSEDIAAN WAKTU DOSEN (AVAILABILITY)
CREATE TABLE availability (
  id VARCHAR(50) PRIMARY KEY,
  dosen_id VARCHAR(50) NOT NULL REFERENCES users(id) ON DELETE CASCADE,
  semester_id VARCHAR(50) NOT NULL DEFAULT 'SEM001',
  status VARCHAR(50) NOT NULL DEFAULT 'submitted' CHECK (status IN ('submitted', 'verified_kajur', 'approved_dekan', 'rejected')),
  submitted_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
  updated_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP
);

-- 8. TABEL AVAILABILITY SLOTS
CREATE TABLE availability_slots (
  id SERIAL PRIMARY KEY,
  availability_id VARCHAR(50) NOT NULL REFERENCES availability(id) ON DELETE CASCADE,
  slot_id VARCHAR(50) NOT NULL REFERENCES slot_waktu(id) ON DELETE CASCADE
);

-- 9. TABEL AJUAN PENGAJARAN (MULTI-TIER WORKFLOW)
CREATE TABLE ajuan_pengajaran (
  id VARCHAR(50) PRIMARY KEY,
  dosen_id VARCHAR(50) NOT NULL REFERENCES users(id) ON DELETE CASCADE,
  dosen_nama VARCHAR(150) NOT NULL,
  fakultas_nama VARCHAR(100) NOT NULL,
  jurusan_nama VARCHAR(100) NOT NULL,
  mata_kuliah_id VARCHAR(50) NOT NULL,
  mata_kuliah_nama VARCHAR(150) NOT NULL,
  sks INT NOT NULL DEFAULT 3,
  semester INT NOT NULL DEFAULT 1,
  kelas_nama VARCHAR(50) NOT NULL DEFAULT 'TI-1A',
  jumlah_mahasiswa INT NOT NULL DEFAULT 35,
  gedung_nama VARCHAR(100) NOT NULL,
  ruangan_nama VARCHAR(100) NOT NULL,
  hari VARCHAR(20) NOT NULL,
  jam_mulai VARCHAR(10) NOT NULL,
  jam_selesai VARCHAR(10) NOT NULL,
  status VARCHAR(50) NOT NULL DEFAULT 'menunggu_kaprodi',
  catatan_dosen TEXT,
  catatan_kaprodi TEXT,
  catatan_dekan TEXT,
  catatan_admin TEXT,
  alasan_penolakan TEXT,
  alasan_banding TEXT,
  preferensi_banding_hari VARCHAR(20) DEFAULT NULL,
  preferensi_banding_jam VARCHAR(50) DEFAULT NULL,
  bentrok_detail TEXT,
  created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
  updated_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP
);

-- 10. TABEL JADWAL FINAL
CREATE TABLE jadwal_final (
  id VARCHAR(50) PRIMARY KEY,
  mata_kuliah_id VARCHAR(50) NOT NULL,
  mata_kuliah_nama VARCHAR(150) NOT NULL,
  sks INT NOT NULL,
  ruangan_nama VARCHAR(100) NOT NULL,
  gedung_nama VARCHAR(100) NOT NULL,
  kelas_nama VARCHAR(50) NOT NULL,
  hari VARCHAR(20) NOT NULL,
  jam_mulai VARCHAR(10) NOT NULL,
  jam_selesai VARCHAR(10) NOT NULL,
  dosen_id VARCHAR(50) DEFAULT NULL,
  dosen_nama VARCHAR(150) DEFAULT NULL,
  fakultas_nama VARCHAR(100) DEFAULT NULL,
  jurusan_nama VARCHAR(100) DEFAULT NULL,
  semester_nama VARCHAR(50) DEFAULT 'Ganjil 2026/2027',
  jumlah_mahasiswa INT DEFAULT 35,
  created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP
);

-- 11. TABEL NOTIFIKASI
CREATE TABLE notifications (
  id VARCHAR(50) PRIMARY KEY,
  user_id VARCHAR(50) DEFAULT NULL,
  title VARCHAR(200) NOT NULL,
  message TEXT NOT NULL,
  type VARCHAR(50) DEFAULT 'info',
  is_read BOOLEAN DEFAULT FALSE,
  created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP
);

-- 12. TABEL PASSWORD RESETS
CREATE TABLE password_resets (
  email VARCHAR(150) NOT NULL,
  token VARCHAR(100) NOT NULL,
  otp VARCHAR(10) NOT NULL,
  created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP
);

-- ============================================================
-- SEED INITIAL USERS & DEFAULT DATA
-- Password default: password123 ($2y$10$wT8vFpL9oQ1Q.g6JjT1ZPe6iEaL2d8t.W9mYf.h7N3L6aO5k1Q2u6 / bcrypt)
-- ============================================================

INSERT INTO users (id, nama, email, password, role, jurusan_id, jurusan_nama, fakultas_nama, is_priority) VALUES
('ADM001', 'Hamizan Qowiem (Super Admin)', 'hamizanqowiem90@gmail.com', '$2y$10$wT8vFpL9oQ1Q.g6JjT1ZPe6iEaL2d8t.W9mYf.h7N3L6aO5k1Q2u6', 'admin', 'JUR001', 'Teknik Informatika', 'Fakultas Sains & Teknologi', TRUE),
('ADM002', 'Administrator Akademik', 'admin@univ.ac.id', '$2y$10$wT8vFpL9oQ1Q.g6JjT1ZPe6iEaL2d8t.W9mYf.h7N3L6aO5k1Q2u6', 'admin', 'JUR001', 'Teknik Informatika', 'Fakultas Sains & Teknologi', FALSE),
('DEK001', 'Prof. Dr. Ir. Budi Santoso, M.Sc.', 'dekan.fst@univ.ac.id', '$2y$10$wT8vFpL9oQ1Q.g6JjT1ZPe6iEaL2d8t.W9mYf.h7N3L6aO5k1Q2u6', 'dekan', 'JUR001', 'Teknik Informatika', 'Fakultas Sains & Teknologi', TRUE),
('KAJ001', 'Dr. Eng. Ahmad Fauzi, S.T., M.T.', 'kaprodi.ti@univ.ac.id', '$2y$10$wT8vFpL9oQ1Q.g6JjT1ZPe6iEaL2d8t.W9mYf.h7N3L6aO5k1Q2u6', 'kajur', 'JUR001', 'Teknik Informatika', 'Fakultas Sains & Teknologi', TRUE),
('DOS001', 'Dr. Hendra Gunawan, S.Kom., M.Cs.', 'hendra.gunawan@univ.ac.id', '$2y$10$wT8vFpL9oQ1Q.g6JjT1ZPe6iEaL2d8t.W9mYf.h7N3L6aO5k1Q2u6', 'dosen', 'JUR001', 'Teknik Informatika', 'Fakultas Sains & Teknologi', FALSE),
('DOS002', 'Siti Rahmawati, S.T., M.Kom.', 'siti.rahmawati@univ.ac.id', '$2y$10$wT8vFpL9oQ1Q.g6JjT1ZPe6iEaL2d8t.W9mYf.h7N3L6aO5k1Q2u6', 'dosen', 'JUR001', 'Teknik Informatika', 'Fakultas Sains & Teknologi', TRUE),
('DOS003', 'Rian Hidayat, M.Kom.', 'rian.hidayat@univ.ac.id', '$2y$10$wT8vFpL9oQ1Q.g6JjT1ZPe6iEaL2d8t.W9mYf.h7N3L6aO5k1Q2u6', 'dosen', 'JUR001', 'Teknik Informatika', 'Fakultas Sains & Teknologi', FALSE)
ON CONFLICT (id) DO NOTHING;

-- GEDUNG
INSERT INTO gedung (id, nama, jam_buka, jam_tutup, akses_jurusan) VALUES
('GD01', 'Gedung FST Terpadu', '07:00', '18:00', 'Teknik Informatika, Sistem Informasi, Teknik Elektro'),
('GD02', 'Gedung Laboratorium Komputer', '07:30', '17:30', 'Teknik Informatika, Sistem Informasi')
ON CONFLICT (id) DO NOTHING;

-- RUANGAN
INSERT INTO ruangan (id, nama, gedung_id, lantai, kapasitas, tipe_ruangan, status, keterangan) VALUES
('R101', 'Ruang FST 101', 'GD01', 'Lantai 1', 45, 'Kelas Teori', 'Kosong (Ready)', 'Dilengkapi AC, Proyektor, Sound System'),
('R102', 'Ruang FST 102', 'GD01', 'Lantai 1', 45, 'Kelas Teori', 'Kosong (Ready)', 'Dilengkapi AC, Smart TV 75 inch'),
('RLAB1', 'Lab Software Engineering', 'GD02', 'Lantai 2', 35, 'Laboratorium Komputer', 'Kosong (Ready)', '40 PC Core i7, LAN Gigabit, Proyektor')
ON CONFLICT (id) DO NOTHING;

-- SLOT WAKTU
INSERT INTO slot_waktu (id, hari, jam_mulai, jam_selesai, durasi_menit) VALUES
('SLOT_SEN_1', 'Senin', '07:30', '10:00', 150),
('SLOT_SEN_2', 'Senin', '10:15', '12:45', 150),
('SLOT_SEN_3', 'Senin', '13:30', '16:00', 150),
('SLOT_SEL_1', 'Selasa', '07:30', '10:00', 150),
('SLOT_SEL_2', 'Selasa', '10:15', '12:45', 150),
('SLOT_SEL_3', 'Selasa', '13:30', '16:00', 150),
('SLOT_RAB_1', 'Rabu', '07:30', '10:00', 150),
('SLOT_RAB_2', 'Rabu', '10:15', '12:45', 150),
('SLOT_RAB_3', 'Rabu', '13:30', '16:00', 150),
('SLOT_KAM_1', 'Kamis', '07:30', '10:00', 150),
('SLOT_KAM_2', 'Kamis', '10:15', '12:45', 150),
('SLOT_KAM_3', 'Kamis', '13:30', '16:00', 150),
('SLOT_JUM_1', 'Jumat', '07:30', '10:00', 150),
('SLOT_JUM_2', 'Jumat', '13:30', '16:00', 150)
ON CONFLICT (id) DO NOTHING;

-- MATA KULIAH
INSERT INTO mata_kuliah (id, nama, sks, jurusan_id, jurusan_nama, fakultas_nama, dosen_id, semester_angka, kebutuhan_tipe_ruangan) VALUES
('MK001', 'Algoritma & Pemrograman', 3, 'JUR001', 'Teknik Informatika', 'Fakultas Sains & Teknologi', 'DOS001', 1, 'Laboratorium Komputer'),
('MK002', 'Struktur Data & Analisis Algoritma', 3, 'JUR001', 'Teknik Informatika', 'Fakultas Sains & Teknologi', 'DOS001', 3, 'Laboratorium Komputer'),
('MK003', 'Basis Data Terdistribusi', 3, 'JUR001', 'Teknik Informatika', 'Fakultas Sains & Teknologi', 'DOS002', 3, 'Kelas Teori'),
('MK004', 'Kecerdasan Buatan & Machine Learning', 3, 'JUR001', 'Teknik Informatika', 'Fakultas Sains & Teknologi', 'DOS002', 5, 'Kelas Teori'),
('MK005', 'Pemrograman Mobile (Flutter)', 3, 'JUR001', 'Teknik Informatika', 'Fakultas Sains & Teknologi', 'DOS003', 5, 'Laboratorium Komputer')
ON CONFLICT (id) DO NOTHING;
