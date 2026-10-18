import 'dart:io';
import 'package:flutter/material.dart';
import '../../../../config/constants.dart';
import '../../../../data/mock/mock_database.dart';
import '../../../../data/models/ajuan_pengajaran_model.dart';

/// Helper widget to build circular Dosen avatar supporting custom profile photos
Widget buildDosenAvatar({
  required String dosenId,
  required String dosenNama,
  double radius = 18,
}) {
  String? avatarPath;
  try {
    final user = MockDatabase.demoUsers.where((u) =>
      (u.id.isNotEmpty && u.id.toLowerCase() == dosenId.trim().toLowerCase()) ||
      (u.nama.isNotEmpty && u.nama.trim().toLowerCase() == dosenNama.trim().toLowerCase())
    ).firstOrNull;
    avatarPath = user?.avatarPath;
  } catch (_) {}

  ImageProvider? imageProvider;
  if (avatarPath != null && avatarPath.isNotEmpty) {
    if (avatarPath.startsWith('http://') || avatarPath.startsWith('https://')) {
      imageProvider = NetworkImage(avatarPath);
    } else {
      final file = File(avatarPath);
      if (file.existsSync()) {
        imageProvider = FileImage(file);
      }
    }
  }

  if (imageProvider != null) {
    return CircleAvatar(
      radius: radius,
      backgroundColor: const Color(0xFFE2E8F0),
      backgroundImage: imageProvider,
    );
  }

  // Fallback to demo photos using hash of the name for consistency
  final int hash = dosenNama.trim().toLowerCase().hashCode;
  final int index = (hash.abs() % 12) + 1;
  final String fallbackAvatar = 'assets/images/profiles/profile$index.png';

  return CircleAvatar(
    radius: radius,
    backgroundColor: const Color(0xFFE2E8F0),
    backgroundImage: AssetImage(fallbackAvatar),
  );
}

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

/// Helper function to get the dynamic stage color for approval cards (Option A)
Color getAjuanStageColor(String status) {
  final s = status.toLowerCase();
  switch (s) {
    case 'menunggu_kaprodi':
    case 'draft':
      return const Color(0xFFD97706); // Amber / Kuning Oker (Tahap KaProdi)
    case 'menunggu_dekan':
    case 'diverifikasi_kaprodi':
      return const Color(0xFF2563EB); // Royal Blue (Tahap Dekan)
    case 'menunggu_admin':
    case 'disetujui_dekan':
      return const Color(0xFF1D4ED8); // Deep Blue (Menuju Admin)
    case 'disetujui_admin':
    case 'disetujui':
    case 'terjadwal_resmi':
    case 'final':
    case 'banding_disetujui':
      return AppColors.primary; // Hijau Tosca Solid (Disetujui Admin / Final)
    case 'menunggu_banding':
      return const Color(0xFF7C3AED); // Purple (Banding Dosen)
    case 'ditolak_kaprodi':
    case 'ditolak_dekan':
    case 'ditolak_admin':
    case 'banding_ditolak':
    case 'bentrok_terdeteksi':
      return AppColors.error; // Merah Solid (Ditolak / Bentrok)
    default:
      return AppColors.primary;
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
        bg = const Color(0xFFF3E8FF);
        fg = const Color(0xFF7C3AED);
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

/// Custom Vector Icon for Course Book
class PhotoCourseBookIcon extends StatelessWidget {
  final Color color;
  final double size;

  const PhotoCourseBookIcon({
    super.key,
    this.color = const Color(0xFF475569),
    this.size = 16,
  });

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      size: Size(size, size * 0.95),
      painter: _PhotoCourseBookPainter(color: color),
    );
  }
}

class _PhotoCourseBookPainter extends CustomPainter {
  final Color color;
  _PhotoCourseBookPainter({required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.4
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;

    final rrect = RRect.fromRectAndRadius(
      Rect.fromLTWH(0.8, 0.8, size.width - 1.6, size.height - 1.6),
      const Radius.circular(2.5),
    );
    canvas.drawRRect(rrect, paint);
    // Vertical center line
    canvas.drawLine(
      Offset(size.width / 2, 0.8),
      Offset(size.width / 2, size.height - 0.8),
      paint,
    );
  }

  @override
  bool shouldRepaint(covariant _PhotoCourseBookPainter oldDelegate) =>
      oldDelegate.color != color;
}

/// Custom Vector Icon for Campus Building
class PhotoBuildingIcon extends StatelessWidget {
  final Color color;
  final double size;

  const PhotoBuildingIcon({
    super.key,
    this.color = const Color(0xFF475569),
    this.size = 16,
  });

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      size: Size(size, size * 1.05),
      painter: _PhotoBuildingPainter(color: color),
    );
  }
}

class _PhotoBuildingPainter extends CustomPainter {
  final Color color;
  _PhotoBuildingPainter({required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.4
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;

    final w = size.width;
    final h = size.height;

    // 1. Outer building outline with roof
    final path = Path()
      ..moveTo(1.0, h - 0.8)
      ..lineTo(1.0, h * 0.40)
      ..lineTo(w / 2, 1.0)
      ..lineTo(w - 1.0, h * 0.40)
      ..lineTo(w - 1.0, h - 0.8)
      ..close();
    canvas.drawPath(path, paint);

    // 2. Doorway / Arch in the bottom center
    final doorPath = Path()
      ..moveTo(w * 0.36, h - 0.8)
      ..lineTo(w * 0.36, h * 0.62)
      ..arcToPoint(
        Offset(w * 0.64, h * 0.62),
        radius: Radius.circular(w * 0.14),
      )
      ..lineTo(w * 0.64, h - 0.8);
    canvas.drawPath(doorPath, paint);

    // 3. Two dots / windows above the door
    final dotPaint = Paint()
      ..color = color
      ..style = PaintingStyle.fill;
    canvas.drawCircle(Offset(w * 0.36, h * 0.44), 1.0, dotPaint);
    canvas.drawCircle(Offset(w * 0.64, h * 0.44), 1.0, dotPaint);
  }

  @override
  bool shouldRepaint(covariant _PhotoBuildingPainter oldDelegate) =>
      oldDelegate.color != color;
}

/// Bottom Sheet modern & elegan saat menekan tombol 3-titik (•••) pada Card Ajuan
void showAjuanActionBottomSheet({
  required BuildContext context,
  required AjuanPengajaranModel ajuan,
  required String role,
  required VoidCallback onEdit,
  required VoidCallback onConflictCheck,
  required VoidCallback onRejectOrDelete,
}) {
  final isDosen = role.toLowerCase() == 'dosen';
  final isConflict = ajuan.status == 'bentrok_terdeteksi';

  showModalBottomSheet(
    context: context,
    backgroundColor: Colors.transparent,
    isScrollControlled: true,
    builder: (ctx) => Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 28),
      child: SafeArea(
        top: false,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Drag Handle
            Center(
              child: Container(
                width: 44,
                height: 4,
                decoration: BoxDecoration(
                  color: const Color(0xFFCBD5E1),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const SizedBox(height: 16),

            // Header info ajuan
            Row(
              children: [
                const SizedBox(width: 4),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Opsi Pengajuan Jadwal',
                        style: TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF0F172A),
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        '${ajuan.mataKuliahNama} • ${ajuan.kelasNama}',
                        style: const TextStyle(
                          fontSize: 12,
                          color: Color(0xFF64748B),
                          fontWeight: FontWeight.w500,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
                IconButton(
                  onPressed: () => Navigator.pop(ctx),
                  icon: const Icon(Icons.close_rounded, size: 20, color: Color(0xFF94A3B8)),
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
                ),
              ],
            ),
            const SizedBox(height: 14),
            const Divider(height: 1, color: Color(0xFFF1F5F9)),
            const SizedBox(height: 14),

            // Item 1: Edit / Sesuaikan
            _buildActionSheetTile(
              icon: Icons.edit_note_rounded,
              iconColor: AppColors.primary,
              title: isDosen ? 'Edit Data Ajuan' : 'Sesuaikan / Edit Jadwal',
              subtitle: 'Ubah hari, jam pertemuan, ruangan, atau kapasitas',
              onTap: () {
                Navigator.pop(ctx);
                onEdit();
              },
            ),
            const SizedBox(height: 10),

            // Item 2: Cek Bentrok
            _buildActionSheetTile(
              icon: Icons.published_with_changes_rounded,
              iconColor: isConflict ? const Color(0xFFDC2626) : const Color(0xFF0284C7),
              title: 'Cek Bentrok Jadwal & Ruang',
              subtitle: isConflict ? 'Terdapat bentrok jadwal pada ruangan ini' : 'Analisis ketersediaan gedung dan ruangan kampus',
              onTap: () {
                Navigator.pop(ctx);
                onConflictCheck();
              },
            ),
            const SizedBox(height: 10),

            // Item 3: Tolak / Hapus
            _buildActionSheetTile(
              icon: isDosen ? Icons.delete_outline_rounded : Icons.cancel_outlined,
              iconColor: const Color(0xFFDC2626),
              title: isDosen ? 'Hapus Pengajuan Ini' : 'Tolak / Minta Revisi Dosen',
              subtitle: isDosen ? 'Batalkan usulan jam dan ruangan mengajar ini' : 'Kembalikan ajuan kepada dosen dengan catatan revisi',
              isDestructive: true,
              onTap: () {
                Navigator.pop(ctx);
                onRejectOrDelete();
              },
            ),
          ],
        ),
      ),
    ),
  );
}

Widget _buildActionSheetTile({
  required IconData icon,
  required Color iconColor,
  required String title,
  required String subtitle,
  required VoidCallback onTap,
  bool isDestructive = false,
}) {
  return InkWell(
    onTap: onTap,
    borderRadius: BorderRadius.circular(12),
    child: Padding(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      child: Row(
        children: [
          Icon(icon, color: iconColor, size: 24),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: isDestructive ? const Color(0xFFDC2626) : const Color(0xFF1E293B),
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  subtitle,
                  style: TextStyle(
                    fontSize: 12,
                    color: isDestructive ? const Color(0xFFEF4444) : const Color(0xFF64748B),
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
        ],
      ),
    ),
  );
}

/// Helper model for dynamic inner card styling based on approval workflow stage
class AjuanCardInnerStyle {
  final Color backgroundColor;
  final Color borderColor;
  final Color dividerColor;

  const AjuanCardInnerStyle({
    required this.backgroundColor,
    required this.borderColor,
    required this.dividerColor,
  });
}

/// Maps status to inner card background & border:
/// - Awal / belum disetujui kaprodi -> Kuning
/// - Masuk ke dekan / diverifikasi kaprodi -> Orange
/// - Masuk admin / disetujui -> Biasa (Neutral Slate)
AjuanCardInnerStyle getAjuanCardInnerStyle(String status) {
  final s = status.toLowerCase().trim();

  // Ditolak
  if (s.contains('ditolak') || s == 'banding_ditolak') {
    return const AjuanCardInnerStyle(
      backgroundColor: Color(0xFFFEF2F2),
      borderColor: Color(0xFFFECACA),
      dividerColor: Color(0xFFFEE2E2),
    );
  }

  // 1. Awal / Belum disetujui Kaprodi (Menunggu KaProdi / Draft / Diajukan) -> Kuning
  if (s == 'menunggu_kaprodi' ||
      s == 'draft' ||
      s == 'diajukan' ||
      s == 'pending' ||
      s == 'menunggu' ||
      s == 'menunggu_banding') {
    return const AjuanCardInnerStyle(
      backgroundColor: Color(0xFFFEFCE8), // Yellow 50
      borderColor: Color(0xFFFDE047),     // Yellow 300
      dividerColor: Color(0xFFFEF08A),    // Yellow 200
    );
  }

  // 2. Data sudah masuk ke Dekan (Diverifikasi KaProdi / Menunggu Dekan) -> Orange
  if (s == 'menunggu_dekan' ||
      s == 'diverifikasi_kaprodi' ||
      s == 'disetujui_kaprodi' ||
      s == 'pending_dekan') {
    return const AjuanCardInnerStyle(
      backgroundColor: Color(0xFFFFF7ED), // Orange 50
      borderColor: Color(0xFFFED7AA),     // Orange 200
      dividerColor: Color(0xFFFFEDD5),    // Orange 100
    );
  }

  // 3. Sudah masuk Admin / Disetujui Dekan / Disetujui Admin / Terjadwal Resmi -> Biasa saja (Neutral)
  return const AjuanCardInnerStyle(
    backgroundColor: Color(0xFFF8FAFC), // Slate 50
    borderColor: Color(0xFFE2E8F0),     // Slate 200
    dividerColor: Color(0xFFE2E8F0),
  );
}

/// Widget ExpandablePageView murni (Pure Flutter) tanpa dependensi eksternal.
/// Secara otomatis menyesuaikan tinggi kartu dalam dengan konten aktualnya secara dinamis & responsif.
class ExpandablePageView extends StatefulWidget {
  final int itemCount;
  final Widget Function(BuildContext context, int index) itemBuilder;
  final PageController? controller;
  final ValueChanged<int>? onPageChanged;

  const ExpandablePageView({
    super.key,
    required this.itemCount,
    required this.itemBuilder,
    this.controller,
    this.onPageChanged,
  });

  const ExpandablePageView.builder({
    super.key,
    required this.itemCount,
    required this.itemBuilder,
    this.controller,
    this.onPageChanged,
  });

  @override
  State<ExpandablePageView> createState() => _ExpandablePageViewState();
}

class _ExpandablePageViewState extends State<ExpandablePageView> {
  int _currentIndex = 0;
  bool _isSlidingForward = true;

  @override
  void initState() {
    super.initState();
    if (widget.controller != null && widget.controller!.hasClients) {
      _currentIndex = widget.controller!.initialPage;
    }
  }

  void _onHorizontalDragEnd(DragEndDetails details) {
    if (widget.itemCount <= 1) return;
    final velocity = details.primaryVelocity ?? 0;
    if (velocity < -60) {
      // Geser ke kiri -> Halaman berikutnya (Next)
      if (_currentIndex < widget.itemCount - 1) {
        setState(() {
          _isSlidingForward = true;
          _currentIndex++;
        });
        widget.onPageChanged?.call(_currentIndex);
      }
    } else if (velocity > 60) {
      // Geser ke kanan -> Halaman sebelumnya (Prev)
      if (_currentIndex > 0) {
        setState(() {
          _isSlidingForward = false;
          _currentIndex--;
        });
        widget.onPageChanged?.call(_currentIndex);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (widget.itemCount == 0) return const SizedBox.shrink();
    if (widget.itemCount == 1) {
      return widget.itemBuilder(context, 0);
    }

    if (_currentIndex >= widget.itemCount) {
      _currentIndex = widget.itemCount - 1;
    }

    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onHorizontalDragEnd: _onHorizontalDragEnd,
      child: AnimatedSize(
        duration: const Duration(milliseconds: 250),
        curve: Curves.easeInOutCubic,
        alignment: Alignment.topCenter,
        child: AnimatedSwitcher(
          duration: const Duration(milliseconds: 220),
          layoutBuilder: (currentChild, previousChildren) {
            return Stack(
              alignment: Alignment.topCenter,
              children: <Widget>[
                ...previousChildren,
                ?currentChild,
              ],
            );
          },
          transitionBuilder: (child, animation) {
            final offsetAnim = Tween<Offset>(
              begin: _isSlidingForward
                  ? const Offset(0.12, 0.0)
                  : const Offset(-0.12, 0.0),
              end: Offset.zero,
            ).animate(CurvedAnimation(parent: animation, curve: Curves.easeOutCubic));

            return FadeTransition(
              opacity: animation,
              child: SlideTransition(
                position: offsetAnim,
                child: child,
              ),
            );
          },
          child: KeyedSubtree(
            key: ValueKey<int>(_currentIndex),
            child: widget.itemBuilder(context, _currentIndex),
          ),
        ),
      ),
    );
  }
}

