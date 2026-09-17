// File: availability_common_widgets.dart
// Deskripsi: Kumpulan widget komponen bersama untuk modul ketersediaan & pengajuan pengajaran.
// Fungsi: Menyediakan badge status, chip informasi, banner pesan, dan dialog peringatan bentrok.

import 'package:flutter/material.dart';
import '../../../../config/constants.dart';
import '../../../../data/models/ajuan_pengajaran_model.dart';

class InfoChip extends StatelessWidget {
  final IconData icon;
  final String label;

  const InfoChip({
    super.key,
    required this.icon,
    required this.label,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3.5),
      decoration: BoxDecoration(
        color: const Color(0xFFF1F5F9),
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 12.5, color: const Color(0xFF64748B)),
          const SizedBox(width: 4),
          Text(
            label,
            style: const TextStyle(
              fontSize: 11.5,
              fontWeight: FontWeight.w600,
              color: Color(0xFF334155),
            ),
          ),
        ],
      ),
    );
  }
}

class AjuanStatusBadge extends StatelessWidget {
  final String status;

  const AjuanStatusBadge({
    super.key,
    required this.status,
  });

  @override
  Widget build(BuildContext context) {
    Color bg;
    Color fg;
    String text;
    IconData icon;

    switch (status) {
      case 'menunggu_kaprodi':
        bg = const Color(0xFFFEF3C7);
        fg = const Color(0xFFD97706);
        text = 'Menunggu KaProdi';
        icon = Icons.schedule_rounded;
        break;
      case 'menunggu_dekan':
        bg = const Color(0xFFE0F2FE);
        fg = const Color(0xFF0284C7);
        text = 'Verifikasi KaProdi';
        icon = Icons.verified_user_outlined;
        break;
      case 'menunggu_admin':
        bg = const Color(0xFFEEF2FF);
        fg = const Color(0xFF4F46E5);
        text = 'Disetujui Dekan';
        icon = Icons.approval_rounded;
        break;
      case 'disetujui_admin':
        bg = const Color(0xFFDCFCE7);
        fg = const Color(0xFF16A34A);
        text = 'Terjadwal Resmi';
        icon = Icons.check_circle_rounded;
        break;
      case 'menunggu_banding':
        bg = const Color(0xFFFFF7ED);
        fg = const Color(0xFFEA580C);
        text = 'Banding Diajukan';
        icon = Icons.history_toggle_off_rounded;
        break;
      case 'banding_disetujui':
        bg = const Color(0xFFECFDF5);
        fg = AppColors.primary;
        text = 'Banding Disetujui';
        icon = Icons.verified_rounded;
        break;
      case 'banding_ditolak':
        bg = const Color(0xFFFEF2F2);
        fg = AppColors.error;
        text = 'Banding Ditolak';
        icon = Icons.error_outline_rounded;
        break;
      case 'bentrok_terdeteksi':
        bg = const Color(0xFFFEF2F2);
        fg = const Color(0xFFDC2626);
        text = 'Bentrok Terdeteksi';
        icon = Icons.warning_amber_rounded;
        break;
      case 'ditolak_kaprodi':
        bg = const Color(0xFFFEE2E2);
        fg = const Color(0xFFDC2626);
        text = 'Ditolak KaProdi';
        icon = Icons.cancel_outlined;
        break;
      case 'ditolak_dekan':
        bg = const Color(0xFFFEE2E2);
        fg = const Color(0xFFDC2626);
        text = 'Ditolak Dekan';
        icon = Icons.cancel_outlined;
        break;
      case 'ditolak_admin':
        bg = const Color(0xFFFEE2E2);
        fg = const Color(0xFFDC2626);
        text = 'Ditolak Admin';
        icon = Icons.cancel_outlined;
        break;
      default:
        bg = const Color(0xFFF1F5F9);
        fg = const Color(0xFF64748B);
        text = status;
        icon = Icons.help_outline;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 13, color: fg),
          const SizedBox(width: 5),
          Text(
            text,
            style: TextStyle(
              fontSize: 11.5,
              fontWeight: FontWeight.bold,
              color: fg,
            ),
          ),
        ],
      ),
    );
  }
}

class MessageBanner extends StatelessWidget {
  final String message;
  final Color color;
  final IconData icon;

  const MessageBanner({
    super.key,
    required this.message,
    required this.color,
    required this.icon,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
      margin: const EdgeInsets.fromLTRB(16, 6, 16, 0),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Row(
        children: [
          Icon(icon, color: color, size: 18),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              message,
              style: TextStyle(
                color: color,
                fontSize: 12,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class ConfirmRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final Color valueColor;

  const ConfirmRow({
    super.key,
    required this.icon,
    required this.label,
    required this.value,
    required this.valueColor,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, size: 15, color: const Color(0xFF64748B)),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            label,
            style: const TextStyle(fontSize: 12, color: Color(0xFF64748B)),
          ),
        ),
        Text(
          value,
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.bold,
            color: valueColor,
          ),
        ),
      ],
    );
  }
}

void showConflictWarningDialog(
  BuildContext context,
  AjuanPengajaranModel aj,
  String conflictMessage,
) {
  showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.white,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
    ),
    builder: (ctx) => Padding(
      padding: EdgeInsets.only(
        left: 20,
        right: 20,
        top: 12,
        bottom: MediaQuery.of(context).viewInsets.bottom + 20,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
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
          const SizedBox(height: 16),
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: const Color(0xFFFEF2F2),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(Icons.warning_amber_rounded, color: Color(0xFFDC2626), size: 24),
              ),
              const SizedBox(width: 12),
              const Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Jadwal Bertabrakan!',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF991B1B),
                      ),
                    ),
                    SizedBox(height: 2),
                    Text(
                      'Terdeteksi bentrok ruangan / waktu',
                      style: TextStyle(fontSize: 11.5, color: Color(0xFF64748B)),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Text(
            'Pengajuan jadwal ${aj.dosenNama} (${aj.mataKuliahNama}) tidak dapat disetujui karena mengalami bentrok:',
            style: const TextStyle(fontSize: 12.5, color: Color(0xFF334155)),
          ),
          const SizedBox(height: 10),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: const Color(0xFFFEF2F2),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: const Color(0xFFFECACA)),
            ),
            child: Text(
              conflictMessage.isNotEmpty
                  ? conflictMessage
                  : (aj.bentrokDetail ?? 'Terdeteksi konflik jam, ruangan, atau dosen.'),
              style: const TextStyle(
                fontSize: 12,
                color: Color(0xFF991B1B),
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          const SizedBox(height: 12),
          const Text(
            'Silakan sesuaikan jadwal atau selesaikan konflik terlebih dahulu di menu Resolusi Konflik.',
            style: TextStyle(fontSize: 11.5, color: Color(0xFF64748B)),
          ),
          const SizedBox(height: 20),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFFDC2626),
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 12),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                elevation: 0,
              ),
              onPressed: () => Navigator.pop(ctx),
              child: const Text('Mengerti', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
            ),
          ),
        ],
      ),
    ),
  );
}
