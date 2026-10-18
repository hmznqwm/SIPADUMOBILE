// File: academic_year_helper.dart
// Deskripsi: Helper utilitas untuk menentukan Tahun Akademik, Semester Aktif, dan Perhitungan Durasi SKS (Praktikum vs Teori).
// Aturan Durasi SKS:
// - Praktikum / Laboratorium / Bengkel / Studio = 90 Menit / 1 SKS
// - Kuliah Teori / Reguler                     = 50 Menit / 1 SKS

class AcademicYearHelper {
  /// Mengembalikan nama semester dan tahun akademik aktif.
  /// Siklus Kalender Akademik:
  /// - Semester Ganjil: Bulan Agustus - Januari (Bulan 8 s/d 1)
  /// - Semester Genap : Bulan Februari - Juli (Bulan 2 s/d 7)
  static String getCurrentSemester({DateTime? date}) {
    final now = date ?? DateTime.now();
    final month = now.month;
    final year = now.year;

    if (month >= 8) {
      // Agustus s/d Desember
      return 'Ganjil $year/${year + 1}';
    } else if (month == 1) {
      // Januari (akhir semester ganjil)
      return 'Ganjil ${year - 1}/$year';
    } else {
      // Februari s/d Juli
      return 'Genap ${year - 1}/$year';
    }
  }

  /// Mengembalikan tipe semester ('Ganjil' atau 'Genap')
  static String getSemesterType({DateTime? date}) {
    final now = date ?? DateTime.now();
    final month = now.month;
    return (month >= 8 || month == 1) ? 'Ganjil' : 'Genap';
  }

  /// Mengembalikan string tahun akademik (contoh: '2026/2027')
  static String getAcademicYear({DateTime? date}) {
    final now = date ?? DateTime.now();
    final month = now.month;
    final year = now.year;

    if (month >= 8) {
      return '$year/${year + 1}';
    } else {
      return '${year - 1}/$year';
    }
  }

  /// Mengecek apakah mata kuliah atau ruangan bertipe Praktikum / Laboratorium.
  /// Memprioritaskan penentuan langsung via `jenis` ('Praktikum' / 'Teori')
  /// atau deteksi cerdas berdasarkan Fakultas (Saintek, Teknik), Jurusan, Nama Matkul, dan Tipe Ruangan.
  static bool isPraktikum({
    String? matkulNama,
    String? tipeRuangan,
    String? ruanganNama,
    String? jenis,
    String? fakultasNama,
    String? jurusanNama,
  }) {
    // 1. Explicit jenis priority
    if (jenis != null && jenis.trim().isNotEmpty) {
      final j = jenis.toLowerCase().trim();
      if (j == 'praktikum' || j == 'lab' || j == 'laboratorium' || j == 'workshop' || j == 'bengkel') {
        return true;
      }
      if (j == 'teori' || j == 'kuliah' || j == 'reguler') {
        return false;
      }
    }

    final mNama = (matkulNama ?? '').toLowerCase();
    final tRuang = (tipeRuangan ?? '').toLowerCase();
    final rNama = (ruanganNama ?? '').toLowerCase();
    final fNama = (fakultasNama ?? '').toLowerCase();
    final jNama = (jurusanNama ?? '').toLowerCase();

    // 2. Direct keyword match on course name or room
    if (mNama.contains('praktikum') ||
        mNama.contains('lab ') ||
        mNama.contains('lab.') ||
        mNama.contains('laboratorium') ||
        mNama.contains('bengkel') ||
        mNama.contains('workshop') ||
        mNama.contains('studio') ||
        tRuang.contains('laboratorium') ||
        tRuang.contains('lab') ||
        tRuang.contains('bengkel') ||
        tRuang.contains('studio') ||
        rNama.contains('lab') ||
        rNama.contains('laboratorium') ||
        rNama.contains('bengkel') ||
        rNama.contains('studio')) {
      return true;
    }

    // 3. Faculty / Jurusan contextual check (Fakultas Sains dan Teknologi, Fakultas Teknik)
    final isSaintekOrTeknik = fNama.contains('sains') ||
        fNama.contains('teknik') ||
        fNama.contains('teknologi') ||
        fNama.contains('saintek') ||
        fNama.contains('fst') ||
        fNama.contains('ft') ||
        jNama.contains('informatika') ||
        jNama.contains('komputer') ||
        jNama.contains('elektro') ||
        jNama.contains('mesin') ||
        jNama.contains('sipil') ||
        jNama.contains('industri') ||
        jNama.contains('arsitektur') ||
        jNama.contains('kimia') ||
        jNama.contains('fisika') ||
        jNama.contains('biologi') ||
        jNama.contains('farmasi');

    if (isSaintekOrTeknik) {
      // Khusus Saintek / Teknik, matkul dengan kata kunci praktis default ke praktikum
      if (mNama.contains('prak') ||
          mNama.contains('pemrograman') ||
          mNama.contains('jaringan') ||
          mNama.contains('basis data') ||
          mNama.contains('database') ||
          mNama.contains('multimedia') ||
          mNama.contains('robotika') ||
          mNama.contains('mikrokontroler') ||
          mNama.contains('elektronika')) {
        return true;
      }
    }

    return false;
  }

  /// Mengembalikan durasi menit per 1 SKS:
  /// - Praktikum / Lab / Bengkel = 90 Menit / SKS
  /// - Kuliah Teori / Reguler    = 50 Menit / SKS
  static int getDurasiMenitPerSks({
    String? matkulNama,
    String? tipeRuangan,
    String? ruanganNama,
    String? jenis,
    String? fakultasNama,
    String? jurusanNama,
  }) {
    return isPraktikum(
      matkulNama: matkulNama,
      tipeRuangan: tipeRuangan,
      ruanganNama: ruanganNama,
      jenis: jenis,
      fakultasNama: fakultasNama,
      jurusanNama: jurusanNama,
    )
        ? 90
        : 50;
  }

  /// Menghitung total durasi menit untuk SKS yang ditentukan
  static int getTotalDurasiMenit({
    required int sks,
    String? matkulNama,
    String? tipeRuangan,
    String? ruanganNama,
    String? jenis,
    String? fakultasNama,
    String? jurusanNama,
  }) {
    final menitPerSks = getDurasiMenitPerSks(
      matkulNama: matkulNama,
      tipeRuangan: tipeRuangan,
      ruanganNama: ruanganNama,
      jenis: jenis,
      fakultasNama: fakultasNama,
      jurusanNama: jurusanNama,
    );
    final effectiveSks = sks > 0 ? sks : 1;
    return effectiveSks * menitPerSks;
  }

  /// Menghitung jam selesai secara presisi berdasarkan jam mulai, SKS, dan tipe matkul/ruangan
  static String calculateJamSelesai(
    String jamMulai,
    int sks, {
    String? matkulNama,
    String? tipeRuangan,
    String? ruanganNama,
    String? jenis,
    String? fakultasNama,
    String? jurusanNama,
  }) {
    final parts = jamMulai.split(':');
    if (parts.length < 2) return jamMulai;
    final jam = int.tryParse(parts[0]) ?? 7;
    final menit = int.tryParse(parts[1]) ?? 0;

    final totalDurasi = getTotalDurasiMenit(
      sks: sks,
      matkulNama: matkulNama,
      tipeRuangan: tipeRuangan,
      ruanganNama: ruanganNama,
      jenis: jenis,
      fakultasNama: fakultasNama,
      jurusanNama: jurusanNama,
    );
    final totalMenitSelesai = jam * 60 + menit + totalDurasi;

    final jamSelesai = (totalMenitSelesai ~/ 60) % 24;
    final menitSelesai = totalMenitSelesai % 60;

    return '${jamSelesai.toString().padLeft(2, '0')}:${menitSelesai.toString().padLeft(2, '0')}';
  }
}
