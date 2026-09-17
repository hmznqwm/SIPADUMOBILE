// File: detail_ajuan_bottom_sheet.dart
// Deskripsi: Modal bottom sheet detail lengkap ajuan pengajaran berserta riwayat aksi & approval per role.

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../../../config/constants.dart';
import '../../../../../data/models/ajuan_pengajaran_model.dart';
import '../../../../../data/services/api_service.dart';
import 'banding_and_reject_bottom_sheets.dart';
import 'conflict_check_bottom_sheet.dart';
import 'edit_ajuan_bottom_sheet.dart';

class DetailAjuanBottomSheet {
  /// Menampilkan modal Detail Lengkap Ajuan Pengajaran
  static void show({
    required BuildContext context,
    required AjuanPengajaranModel ajuan,
    required String currentRole,
    required VoidCallback onRefresh,
  }) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) {
        return DraggableScrollableSheet(
          initialChildSize: 0.85,
          minChildSize: 0.5,
          maxChildSize: 0.95,
          expand: false,
          builder: (_, scrollController) {
            return DetailAjuanContentWidget(
              ajuan: ajuan,
              currentRole: currentRole,
              scrollController: scrollController,
              onRefresh: onRefresh,
            );
          },
        );
      },
    );
  }
}

class DetailAjuanContentWidget extends StatefulWidget {
  final AjuanPengajaranModel ajuan;
  final String currentRole;
  final ScrollController scrollController;
  final VoidCallback onRefresh;

  const DetailAjuanContentWidget({
    super.key,
    required this.ajuan,
    required this.currentRole,
    required this.scrollController,
    required this.onRefresh,
  });

  @override
  State<DetailAjuanContentWidget> createState() => _DetailAjuanContentWidgetState();
}

class _DetailAjuanContentWidgetState extends State<DetailAjuanContentWidget> {
  late AjuanPengajaranModel _currentAjuan;

  @override
  void initState() {
    super.initState();
    _currentAjuan = widget.ajuan;
  }

  Color _getStatusColor(String status) {
    if (status == 'disetujui_admin' || status == 'banding_disetujui') return AppColors.primary;
    if (status == 'menunggu_admin') return const Color(0xFF7C3AED); // Purple
    if (status == 'menunggu_dekan') return const Color(0xFFD97706); // Amber
    if (status == 'menunggu_banding') return const Color(0xFFEA580C); // Orange
    if (status == 'bentrok_terdeteksi') return const Color(0xFFE11D48); // Rose
    if (status.startsWith('ditolak') || status == 'banding_ditolak') return AppColors.error;
    return const Color(0xFF2563EB); // Blue for menunggu_kaprodi
  }

  Color _getStatusBg(String status) {
    if (status == 'disetujui_admin' || status == 'banding_disetujui') return const Color(0xFFECFDF5);
    if (status == 'menunggu_admin') return const Color(0xFFF5F3FF);
    if (status == 'menunggu_dekan') return const Color(0xFFFFFBEB);
    if (status == 'menunggu_banding') return const Color(0xFFFFF7ED);
    if (status == 'bentrok_terdeteksi') return const Color(0xFFFFF1F2);
    if (status.startsWith('ditolak') || status == 'banding_ditolak') return const Color(0xFFFEF2F2);
    return const Color(0xFFEFF6FF);
  }

  Widget _buildInfoRow(IconData icon, String label, String value, {Color? valueColor}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 16, color: const Color(0xFF64748B)),
          const SizedBox(width: 10),
          SizedBox(
            width: 110,
            child: Text(
              label,
              style: const TextStyle(fontSize: 12, color: Color(0xFF64748B), fontWeight: FontWeight.w500),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: TextStyle(
                fontSize: 12.5,
                fontWeight: FontWeight.w600,
                color: valueColor ?? const Color(0xFF0F172A),
              ),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final statusColor = _getStatusColor(_currentAjuan.status);
    final statusBg = _getStatusBg(_currentAjuan.status);

    return Container(
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 20),
      child: ListView(
        controller: widget.scrollController,
        children: [
          // Drag handle
          Center(
            child: Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.grey.shade300,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          const SizedBox(height: 14),

          // Header Title & Status
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: AppColors.primary.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(Icons.menu_book_rounded, color: AppColors.primary, size: 24),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      _currentAjuan.mataKuliahNama,
                      style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Color(0xFF0F172A)),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      _currentAjuan.fakultasNama,
                      style: const TextStyle(fontSize: 11.5, color: Color(0xFF64748B)),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),

          // Status Badge Box
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              color: statusBg,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: statusColor.withValues(alpha: 0.3)),
            ),
            child: Row(
              children: [
                Icon(Icons.info_rounded, size: 16, color: statusColor),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Status: ${_currentAjuan.statusDisplay}',
                    style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: statusColor),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),

          // If there is conflict details
          if (_currentAjuan.bentrokDetail != null) ...[
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: const Color(0xFFFFF1F2),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: const Color(0xFFFFE4E6)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Row(
                    children: [
                      Icon(Icons.warning_amber_rounded, color: Color(0xFFDC2626), size: 16),
                      SizedBox(width: 6),
                      Text('Detail Bentrok Jadwal', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Color(0xFF991B1B))),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(_currentAjuan.bentrokDetail!, style: const TextStyle(fontSize: 11.5, color: Color(0xFF7F1D1D))),
                ],
              ),
            ),
            const SizedBox(height: 14),
          ],

          // If there is appeal (Banding) details
          if (_currentAjuan.alasanBanding != null) ...[
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: const Color(0xFFFFF7ED),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: const Color(0xFFFFEDD5)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Row(
                    children: [
                      Icon(Icons.assignment_late_outlined, color: Color(0xFFEA580C), size: 16),
                      SizedBox(width: 6),
                      Text('Pengajuan Banding Dosen', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Color(0xFF9A3412))),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text('Alasan: ${_currentAjuan.alasanBanding}', style: const TextStyle(fontSize: 11.5, color: Color(0xFF7C2D12))),
                  if (_currentAjuan.preferensiBandingHari != null || _currentAjuan.preferensiBandingJam != null) ...[
                    const SizedBox(height: 4),
                    Text('Preferensi Waktu: ${_currentAjuan.preferensiBandingHari ?? "-"}, ${_currentAjuan.preferensiBandingJam ?? "-"}', style: const TextStyle(fontSize: 11.5, fontWeight: FontWeight.w600, color: Color(0xFF7C2D12))),
                  ],
                ],
              ),
            ),
            const SizedBox(height: 14),
          ],

          // Card: Informasi Akademik & Mahasiswa
          const Text(
            'Informasi Pengajaran & Kelas',
            style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: Color(0xFF0F172A)),
          ),
          const SizedBox(height: 6),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: const Color(0xFFF8FAFC),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: const Color(0xFFE2E8F0)),
            ),
            child: Column(
              children: [
                _buildInfoRow(Icons.person_rounded, 'Dosen Pengampu', _currentAjuan.dosenNama),
                _buildInfoRow(Icons.calendar_view_week_rounded, 'Beban SKS', '${_currentAjuan.sks} SKS'),
                _buildInfoRow(Icons.school_rounded, 'Semester & Kelas', 'Semester ${_currentAjuan.semester} (Kelas ${_currentAjuan.kelasNama})'),
                _buildInfoRow(Icons.groups_rounded, 'Jumlah Siswa/Mhs', '${_currentAjuan.jumlahMahasiswa} Mahasiswa'),
              ],
            ),
          ),
          const SizedBox(height: 14),

          // Card: Lokasi & Waktu (Gedung & Ruangan)
          const Text(
            'Alokasi Waktu & Ruangan Kampus',
            style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: Color(0xFF0F172A)),
          ),
          const SizedBox(height: 6),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: const Color(0xFFF8FAFC),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: const Color(0xFFE2E8F0)),
            ),
            child: Column(
              children: [
                _buildInfoRow(Icons.today_rounded, 'Hari Kuliah', _currentAjuan.hari),
                _buildInfoRow(Icons.access_time_rounded, 'Jam Pelaksanaan', _currentAjuan.waktuFormatted),
                _buildInfoRow(Icons.apartment_rounded, 'Gedung', _currentAjuan.gedungNama),
                _buildInfoRow(Icons.meeting_room_rounded, 'Ruangan', _currentAjuan.ruanganNama, valueColor: AppColors.primary),
              ],
            ),
          ),
          const SizedBox(height: 14),

          // Card: Riwayat Catatan & Alasan Penolakan
          if (_currentAjuan.catatanDosen != null ||
              _currentAjuan.catatanKaProdi != null ||
              _currentAjuan.catatanDekan != null ||
              _currentAjuan.catatanAdmin != null ||
              _currentAjuan.alasanPenolakan != null) ...[
            const Text(
              'Catatan & Keterangan Pengajuan',
              style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: Color(0xFF0F172A)),
            ),
            const SizedBox(height: 6),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: const Color(0xFFF8FAFC),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: const Color(0xFFE2E8F0)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (_currentAjuan.catatanDosen != null)
                    _buildNoteItem('Dosen', _currentAjuan.catatanDosen!, Icons.edit_note_rounded, Colors.blue),
                  if (_currentAjuan.catatanKaProdi != null)
                    _buildNoteItem('KaProdi', _currentAjuan.catatanKaProdi!, Icons.verified_user_outlined, Colors.orange),
                  if (_currentAjuan.catatanDekan != null)
                    _buildNoteItem('Dekan', _currentAjuan.catatanDekan!, Icons.domain_verification_rounded, Colors.purple),
                  if (_currentAjuan.catatanAdmin != null)
                    _buildNoteItem('Super Admin', _currentAjuan.catatanAdmin!, Icons.admin_panel_settings_rounded, AppColors.primary),
                  if (_currentAjuan.alasanPenolakan != null)
                    _buildNoteItem('Alasan Penolakan', _currentAjuan.alasanPenolakan!, Icons.cancel_outlined, AppColors.error),
                ],
              ),
            ),
            const SizedBox(height: 16),
          ],

          // Action Buttons: Sesuai Role
          _buildActionButtons(context),
        ],
      ),
    );
  }

  Widget _buildNoteItem(String author, String note, IconData icon, Color color) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 15, color: color),
          const SizedBox(width: 8),
          Expanded(
            child: RichText(
              text: TextSpan(
                style: const TextStyle(fontSize: 12, color: Color(0xFF334155)),
                children: [
                  TextSpan(text: '$author: ', style: TextStyle(fontWeight: FontWeight.bold, color: color)),
                  TextSpan(text: note),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActionButtons(BuildContext context) {
    final api = context.read<ApiService>();

    return Column(
      children: [
        // Tombol Cek Bentrok Gedung & Ruang (Bisa diakses semua role)
        OutlinedButton.icon(
          style: OutlinedButton.styleFrom(
            foregroundColor: const Color(0xFF0F172A),
            side: const BorderSide(color: Color(0xFFCBD5E1)),
            minimumSize: const Size(double.infinity, 44),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
          ),
          onPressed: () => ConflictCheckBottomSheet.show(
            context: context,
            ajuan: _currentAjuan,
          ),
          icon: const Icon(Icons.event_busy_outlined, size: 18, color: AppColors.primary),
          label: const Text('Cek Bentrok Jadwal', style: TextStyle(fontSize: 12.5, fontWeight: FontWeight.w600)),
        ),
        const SizedBox(height: 8),

        // Tombol Edit (Bisa diakses Dosen, KaProdi, Dekan, Admin)
        ElevatedButton.icon(
          style: ElevatedButton.styleFrom(
            backgroundColor: AppColors.primary,
            foregroundColor: Colors.white,
            minimumSize: const Size(double.infinity, 44),
            elevation: 0,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
          ),
          onPressed: () {
            EditAjuanBottomSheet.showEditDialog(
              context: context,
              ajuan: _currentAjuan,
              currentRole: widget.currentRole,
              onSaved: (updated) async {
                final result = await api.updateAjuanPengajaran(updated);
                setState(() => _currentAjuan = result);
                widget.onRefresh();
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Data ajuan berhasil disesuaikan!'), backgroundColor: AppColors.primary),
                  );
                }
              },
            );
          },
          icon: const Icon(Icons.edit_outlined, size: 16),
          label: const Text('Edit', style: TextStyle(fontSize: 12.5, fontWeight: FontWeight.bold)),
        ),
        const SizedBox(height: 8),

        // Aksi Khusus Dosen: Ajukan Banding Jadwal jika sudah disetujui resmi
        if (widget.currentRole == 'dosen' && (_currentAjuan.status == 'disetujui_admin' || _currentAjuan.status == 'banding_disetujui')) ...[
          OutlinedButton.icon(
            style: OutlinedButton.styleFrom(
              foregroundColor: const Color(0xFFEA580C),
              side: const BorderSide(color: Color(0xFFFDBA74)),
              minimumSize: const Size(double.infinity, 44),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            ),
            onPressed: () {
              BandingAndRejectBottomSheets.showBandingDialog(
                context: context,
                ajuan: _currentAjuan,
                onConfirmBanding: (alasan, prefHari, prefJam) async {
                  final res = await api.submitBandingAjuan(
                    ajuanId: _currentAjuan.id,
                    alasan: alasan,
                    preferensiHari: prefHari,
                    preferensiJam: prefJam,
                  );
                  setState(() => _currentAjuan = res);
                  widget.onRefresh();
                  if (context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Pengajuan banding berhasil dikirim ke Admin!'), backgroundColor: Color(0xFFEA580C)),
                    );
                  }
                },
              );
            },
            icon: const Icon(Icons.assignment_late_outlined, size: 18),
            label: const Text('Ajukan Banding / Berhalangan', style: TextStyle(fontSize: 12.5, fontWeight: FontWeight.bold)),
          ),
          const SizedBox(height: 8),
        ],

        // Aksi Khusus Admin: Meninjau Banding Dosen
        if (widget.currentRole == 'admin' && _currentAjuan.status == 'menunggu_banding') ...[
          Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  style: OutlinedButton.styleFrom(
                    foregroundColor: AppColors.error,
                    side: const BorderSide(color: Color(0xFFFECACA)),
                    minimumSize: const Size(0, 44),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                  ),
                  onPressed: () async {
                    final res = await api.adminProcessBanding(
                      ajuanId: _currentAjuan.id,
                      approve: false,
                      catatanAdmin: 'Permohonan banding tidak dapat dipenuhi karena keterbatasan ruang.',
                    );
                    setState(() => _currentAjuan = res);
                    widget.onRefresh();
                  },
                  icon: const Icon(Icons.close_rounded, size: 18),
                  label: const Text('Tolak Banding', style: TextStyle(fontWeight: FontWeight.bold)),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: ElevatedButton.icon(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    foregroundColor: Colors.white,
                    minimumSize: const Size(0, 44),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                  ),
                  onPressed: () {
                    EditAjuanBottomSheet.showEditDialog(
                      context: context,
                      ajuan: _currentAjuan,
                      currentRole: 'admin',
                      onSaved: (updated) async {
                        final res = await api.adminProcessBanding(
                          ajuanId: _currentAjuan.id,
                          approve: true,
                          catatanAdmin: 'Banding disetujui. Jadwal dipindahkan sesuai kesepakatan.',
                          updatedData: updated,
                        );
                        setState(() => _currentAjuan = res);
                        widget.onRefresh();
                      },
                    );
                  },
                  icon: const Icon(Icons.check_circle_outline_rounded, size: 18),
                  label: const Text('Ubah & Setujui', style: TextStyle(fontWeight: FontWeight.bold)),
                ),
              ),
            ],
          ),
        ]
        // Role-Specific Approval Actions
        else if (widget.currentRole == 'kaprodi' && _currentAjuan.status == 'menunggu_kaprodi') ...[
          Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  style: OutlinedButton.styleFrom(
                    foregroundColor: AppColors.error,
                    side: const BorderSide(color: Color(0xFFFECACA)),
                    minimumSize: const Size(0, 44),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                  ),
                  onPressed: () {
                    BandingAndRejectBottomSheets.showRejectDialog(
                      context: context,
                      ajuan: _currentAjuan,
                      role: 'kaprodi',
                      onConfirmReject: (alasan) async {
                        final res = await api.kaprodiRejectAjuan(_currentAjuan.id, alasan);
                        setState(() => _currentAjuan = res);
                        widget.onRefresh();
                      },
                    );
                  },
                  icon: const Icon(Icons.close_rounded, size: 18),
                  label: const Text('Tolak Ajuan', style: TextStyle(fontWeight: FontWeight.bold)),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: ElevatedButton.icon(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFFD97706),
                    foregroundColor: Colors.white,
                    minimumSize: const Size(0, 44),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                  ),
                  onPressed: () async {
                    final res = await api.kaprodiVerifyAjuan(_currentAjuan.id);
                    setState(() => _currentAjuan = res);
                    widget.onRefresh();
                    if (context.mounted) {
                      Navigator.pop(context);
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Ajuan diverifikasi KaProdi & diteruskan ke Dekan!'), backgroundColor: Color(0xFFD97706)),
                      );
                    }
                  },
                  icon: const Icon(Icons.check_circle_outline_rounded, size: 18),
                  label: const Text('Verifikasi ke Dekan', style: TextStyle(fontWeight: FontWeight.bold)),
                ),
              ),
            ],
          ),
        ] else if (widget.currentRole == 'dekan' && _currentAjuan.status == 'menunggu_dekan') ...[
          Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  style: OutlinedButton.styleFrom(
                    foregroundColor: AppColors.error,
                    side: const BorderSide(color: Color(0xFFFECACA)),
                    minimumSize: const Size(0, 44),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                  ),
                  onPressed: () {
                    BandingAndRejectBottomSheets.showRejectDialog(
                      context: context,
                      ajuan: _currentAjuan,
                      role: 'dekan',
                      onConfirmReject: (alasan) async {
                        final res = await api.dekanRejectAjuan(_currentAjuan.id, alasan);
                        setState(() => _currentAjuan = res);
                        widget.onRefresh();
                      },
                    );
                  },
                  icon: const Icon(Icons.close_rounded, size: 18),
                  label: const Text('Tolak ke KaProdi', style: TextStyle(fontWeight: FontWeight.bold)),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: ElevatedButton.icon(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF7C3AED),
                    foregroundColor: Colors.white,
                    minimumSize: const Size(0, 44),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                  ),
                  onPressed: () async {
                    final res = await api.dekanApproveAjuan(_currentAjuan.id);
                    setState(() => _currentAjuan = res);
                    widget.onRefresh();
                    if (context.mounted) {
                      Navigator.pop(context);
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Ajuan disetujui Dekan & diteruskan ke Super Admin!'), backgroundColor: Color(0xFF7C3AED)),
                      );
                    }
                  },
                  icon: const Icon(Icons.check_circle_outline_rounded, size: 18),
                  label: const Text('Setujui ke Admin', style: TextStyle(fontWeight: FontWeight.bold)),
                ),
              ),
            ],
          ),
        ] else if (widget.currentRole == 'admin' && _currentAjuan.status != 'disetujui_admin') ...[
          Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  style: OutlinedButton.styleFrom(
                    foregroundColor: AppColors.error,
                    side: const BorderSide(color: Color(0xFFFECACA)),
                    minimumSize: const Size(0, 44),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                  ),
                  onPressed: () {
                    BandingAndRejectBottomSheets.showRejectDialog(
                      context: context,
                      ajuan: _currentAjuan,
                      role: 'admin',
                      onConfirmReject: (alasan) async {
                        final res = await api.adminRejectAjuan(_currentAjuan.id, alasan);
                        setState(() => _currentAjuan = res);
                        widget.onRefresh();
                      },
                    );
                  },
                  icon: const Icon(Icons.close_rounded, size: 18),
                  label: const Text('Tolak Ajuan', style: TextStyle(fontWeight: FontWeight.bold)),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: ElevatedButton.icon(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    foregroundColor: Colors.white,
                    minimumSize: const Size(0, 44),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                  ),
                  onPressed: () async {
                    // Check conflict first before final approval
                    final conflict = api.checkBuildingConflict(_currentAjuan);
                    if (conflict['hasConflict'] == true) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text('${conflict['message']} Silakan sesuaikan ruangan/jam terlebih dahulu!'),
                          backgroundColor: AppColors.error,
                        ),
                      );
                      return;
                    }

                    final res = await api.adminApproveFinalAjuan(_currentAjuan.id);
                    setState(() => _currentAjuan = res);
                    widget.onRefresh();
                    if (context.mounted) {
                      Navigator.pop(context);
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Jadwal RESMI DISETUJUI & dimasukkan ke Master Jadwal Institusi!'), backgroundColor: AppColors.primary),
                      );
                    }
                  },
                  icon: const Icon(Icons.verified_rounded, size: 18),
                  label: const Text('Setujui', style: TextStyle(fontWeight: FontWeight.bold)),
                ),
              ),
            ],
          ),
        ],
      ],
    );
  }
}
