// File: pdf_export.dart
// Deskripsi: Utilitas ekspor dokumen PDF Kartu Program Studi / Jadwal Mengajar Dosen.
// Fungsi: Meng-generate file PDF berformat SIAKAD UIN Malang lengkap dengan Kop Surat, tabel jadwal, barcode QR, dan fitur cetak/unduh.

import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import '../data/models/jadwal_model.dart';
import '../data/models/user_model.dart';

class PdfExportUtility {
  static Future<void> exportJadwalToPdf({
    required UserModel user,
    required List<JadwalModel> jadwalList,
  }) async {
    final pdf = pw.Document();

    final now = DateTime.now();
    final months = [
      'Januari',
      'Februari',
      'Maret',
      'April',
      'Mei',
      'Juni',
      'Juli',
      'Agustus',
      'September',
      'Oktober',
      'November',
      'Desember'
    ];
    final dateStr = '${now.day} ${months[now.month - 1]} ${now.year}';
    final timeStr =
        '${now.hour.toString().padLeft(2, '0')}:${now.minute.toString().padLeft(2, '0')}';

    pdf.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.symmetric(horizontal: 24, vertical: 20),
        header: (pw.Context context) {
          return pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.center,
            children: [
              // Top small header
              pw.Row(
                mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                children: [
                  pw.Text(
                    '${now.day}/${now.month}/${now.year.toString().substring(2)}, $timeStr PM',
                    style: const pw.TextStyle(fontSize: 7),
                  ),
                  pw.Text(
                    ':: Sistem Informasi Akademik Universitas Islam Negeri Maulana Malik Ibrahim Malang 2.0',
                    style: pw.TextStyle(fontSize: 7, fontWeight: pw.FontWeight.bold),
                  ),
                  pw.SizedBox(width: 30),
                ],
              ),
              pw.SizedBox(height: 4),

              // Kop Surat Header Row
              pw.Row(
                crossAxisAlignment: pw.CrossAxisAlignment.center,
                children: [
                  // Logo container (blank box)
                  pw.Container(
                    width: 55,
                    height: 55,
                    decoration: pw.BoxDecoration(
                      border: pw.Border.all(color: PdfColors.black, width: 0.8),
                    ),
                  ),
                  pw.SizedBox(width: 12),
                  // Center Text Kop
                  pw.Expanded(
                    child: pw.Column(
                      crossAxisAlignment: pw.CrossAxisAlignment.center,
                      children: [
                        pw.Text(
                          'KEMENTERIAN AGAMA',
                          style: pw.TextStyle(fontSize: 10, fontWeight: pw.FontWeight.bold),
                        ),
                        pw.Text(
                          'UNIVERSITAS ISLAM NEGERI MAULANA MALIK IBRAHIM MALANG',
                          style: pw.TextStyle(fontSize: 10.5, fontWeight: pw.FontWeight.bold),
                          textAlign: pw.TextAlign.center,
                        ),
                        pw.Text(
                          'Jalan Gajayana Nomor 50, Telepon (0341)551354, Fax. (0341) 572533',
                          style: const pw.TextStyle(fontSize: 7.5),
                          textAlign: pw.TextAlign.center,
                        ),
                        pw.Text(
                          'Website: http://www.uin-malang.ac.id Email: info@uin-malang.ac.id',
                          style: const pw.TextStyle(fontSize: 7.5),
                          textAlign: pw.TextAlign.center,
                        ),
                      ],
                    ),
                  ),
                  pw.SizedBox(width: 55), // balance spacing with logo box
                ],
              ),
              pw.SizedBox(height: 6),

              // Double Horizontal Line under Kop
              pw.Column(
                children: [
                  pw.Container(height: 1.5, color: PdfColors.black),
                  pw.SizedBox(height: 1.5),
                  pw.Container(height: 0.5, color: PdfColors.black),
                ],
              ),
              pw.SizedBox(height: 10),
            ],
          );
        },
        footer: (pw.Context context) {
          return pw.Row(
            mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
            children: [
              pw.Text(
                'https://siakad.uin-malang.ac.id/clk-printKPS-${user.id.hashCode.abs()}',
                style: const pw.TextStyle(fontSize: 7, color: PdfColors.grey700),
              ),
              pw.Text(
                '${context.pageNumber}/${context.pagesCount}',
                style: const pw.TextStyle(fontSize: 7, color: PdfColors.grey700),
              ),
            ],
          );
        },
        build: (pw.Context context) {
          return [
            // Title
            pw.Center(
              child: pw.Text(
                'KARTU PROGRAM STUDI',
                style: pw.TextStyle(
                  fontSize: 11,
                  fontWeight: pw.FontWeight.bold,
                ),
              ),
            ),
            pw.SizedBox(height: 12),

            // Identity Table (2 Columns)
            pw.Row(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                // Left Column
                pw.Expanded(
                  child: pw.Table(
                    columnWidths: const {
                      0: pw.FixedColumnWidth(80),
                      1: pw.FixedColumnWidth(10),
                      2: pw.FlexColumnWidth(),
                    },
                    children: [
                      _buildInfoRow('NIM Mahasiswa', user.id),
                      _buildInfoRow('Fakultas', user.fakultasNama.toUpperCase()),
                      _buildInfoRow('Semester, Tahun', 'GANJIL, 2026/2027'),
                    ],
                  ),
                ),
                pw.SizedBox(width: 20),
                // Right Column
                pw.Expanded(
                  child: pw.Table(
                    columnWidths: const {
                      0: pw.FixedColumnWidth(85),
                      1: pw.FixedColumnWidth(10),
                      2: pw.FlexColumnWidth(),
                    },
                    children: [
                      _buildInfoRow('Nama Mahasiswa', user.nama.toUpperCase()),
                      _buildInfoRow('Jurusan', user.jurusanNama.toUpperCase()),
                      _buildInfoRow('Dosen Wali', 'SUPRIYONO, M.Kom'),
                    ],
                  ),
                ),
              ],
            ),
            pw.SizedBox(height: 12),

            // Table Jadwal
            pw.Table(
              border: pw.TableBorder.all(color: PdfColors.black, width: 0.8),
              columnWidths: const {
                0: pw.FixedColumnWidth(22), // No
                1: pw.FixedColumnWidth(65), // Kode
                2: pw.FlexColumnWidth(2.2), // Nama Matakuliah
                3: pw.FixedColumnWidth(24), // SKS
                4: pw.FlexColumnWidth(2.5), // Dosen
                5: pw.FixedColumnWidth(38), // Hari
                6: pw.FixedColumnWidth(55), // Pukul
                7: pw.FixedColumnWidth(28), // Kelas
                8: pw.FixedColumnWidth(65), // Ruang
              },
              children: [
                // Header Row
                pw.TableRow(
                  decoration: const pw.BoxDecoration(color: PdfColors.white),
                  children: [
                    _buildCell('No', isHeader: true, align: pw.TextAlign.center),
                    _buildCell('Kode', isHeader: true, align: pw.TextAlign.center),
                    _buildCell('Nama Matakuliah', isHeader: true, align: pw.TextAlign.center),
                    _buildCell('SKS', isHeader: true, align: pw.TextAlign.center),
                    _buildCell('Dosen', isHeader: true, align: pw.TextAlign.center),
                    _buildCell('Hari', isHeader: true, align: pw.TextAlign.center),
                    _buildCell('Pukul', isHeader: true, align: pw.TextAlign.center),
                    _buildCell('Kelas', isHeader: true, align: pw.TextAlign.center),
                    _buildCell('Ruang', isHeader: true, align: pw.TextAlign.center),
                  ],
                ),
                // Data Rows
                ...jadwalList.asMap().entries.map((entry) {
                  final idx = entry.key + 1;
                  final j = entry.value;
                  return pw.TableRow(
                    children: [
                      _buildCell('$idx', align: pw.TextAlign.center),
                      _buildCell(j.mataKuliahId, align: pw.TextAlign.left),
                      _buildCell(j.mataKuliahNama.toUpperCase()),
                      _buildCell('${j.sks}', align: pw.TextAlign.center),
                      _buildCell(user.nama.toUpperCase()),
                      _buildCell(j.hari, align: pw.TextAlign.center),
                      _buildCell('${j.jamMulai} -\n${j.jamSelesai}', align: pw.TextAlign.center),
                      _buildCell(j.kelasNama, align: pw.TextAlign.center),
                      _buildCell('${j.ruanganNama}\n${j.gedungNama}', align: pw.TextAlign.left),
                    ],
                  );
                }),
              ],
            ),
            pw.SizedBox(height: 18),

            // Bottom QR Code and Disclaimer
            pw.Row(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                // QR Code
                pw.Container(
                  width: 55,
                  height: 55,
                  child: pw.BarcodeWidget(
                    barcode: pw.Barcode.qrCode(),
                    data: 'KRS Semester GANJIL 2026/2027 - ${user.nama} (${user.id})',
                    drawText: false,
                  ),
                ),
                pw.SizedBox(width: 10),
                pw.Expanded(
                  child: pw.Column(
                    crossAxisAlignment: pw.CrossAxisAlignment.start,
                    children: [
                      pw.Text(
                        'KRS Semester GANJIL Tahun 2026/2027 ini telah disetujui Dosen Wali',
                        style: pw.TextStyle(fontSize: 6.5, fontWeight: pw.FontWeight.bold),
                      ),
                      pw.SizedBox(height: 2),
                      pw.Text(
                        'Dicetak melalui https://siakad.uin-malang.ac.id pada tanggal $dateStr',
                        style: const pw.TextStyle(fontSize: 6.5),
                      ),
                      pw.SizedBox(height: 4),
                      pw.Text(
                        'Printout KRS ini sebagai bukti telah melakukan perwalian,\ntanpa perlu ditandatangani Dosen Wali dan Fakultas',
                        style: const pw.TextStyle(fontSize: 6.5),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ];
        },
      ),
    );

    await Printing.layoutPdf(
      onLayout: (PdfPageFormat format) async => pdf.save(),
      name: 'Jadwal_Mengajar_${user.nama.replaceAll(' ', '_')}.pdf',
    );
  }

  static pw.TableRow _buildInfoRow(String label, String value) {
    return pw.TableRow(
      children: [
        pw.Padding(
          padding: const pw.EdgeInsets.symmetric(vertical: 1.5),
          child: pw.Text(
            label,
            style: const pw.TextStyle(fontSize: 8),
          ),
        ),
        pw.Padding(
          padding: const pw.EdgeInsets.symmetric(vertical: 1.5),
          child: pw.Text(
            ':',
            style: const pw.TextStyle(fontSize: 8),
          ),
        ),
        pw.Padding(
          padding: const pw.EdgeInsets.symmetric(vertical: 1.5),
          child: pw.Text(
            value,
            style: pw.TextStyle(fontSize: 8, fontWeight: pw.FontWeight.bold),
          ),
        ),
      ],
    );
  }

  static pw.Widget _buildCell(
    String text, {
    bool isHeader = false,
    pw.TextAlign align = pw.TextAlign.left,
  }) {
    return pw.Padding(
      padding: const pw.EdgeInsets.all(3.5),
      child: pw.Text(
        text,
        textAlign: align,
        style: pw.TextStyle(
          fontSize: isHeader ? 7.5 : 7,
          fontWeight: isHeader ? pw.FontWeight.bold : pw.FontWeight.normal,
        ),
      ),
    );
  }
}

