import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../../config/constants.dart';

/// Card Header dengan desain motif Split Wave 2-Warna yang bersih dan elegan.
/// Mendukung logo mark SIPADU + teks asli Flutter di atas judul.
class WaveHeaderCard extends StatelessWidget {
  final String title;
  final String subtitle;
  final bool showBrand;
  final String brandText;
  final Widget? trailing;
  final EdgeInsetsGeometry padding;

  const WaveHeaderCard({
    super.key,
    required this.title,
    required this.subtitle,
    this.showBrand = false,
    this.brandText = 'SIPADU',
    this.trailing,
    this.padding = const EdgeInsets.symmetric(horizontal: 20, vertical: 18),
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(AppRadius.lg),
        boxShadow: [
          BoxShadow(
            color: AppColors.primary.withValues(alpha: 0.25),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(AppRadius.lg),
        child: Stack(
          children: [
            // ── Background Gradient & Split Wave Motif ──
            Positioned.fill(
              child: Container(
                decoration: const BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      Color(0xFF00897B), // AppColors.primary
                      Color(0xFF00695C), // Darker teal accent
                    ],
                  ),
                ),
                child: CustomPaint(
                  painter: _SplitWavePainter(),
                ),
              ),
            ),

            // ── Content Typography & Brand Header ──
            Padding(
              padding: padding,
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        // ── Brand Logo Ribbon + Native Text ──
                        if (showBrand) ...[
                          Row(
                            mainAxisSize: MainAxisSize.min,
                            crossAxisAlignment: CrossAxisAlignment.center,
                            children: [
                              Image.asset(
                                'assets/images/dashboard/logo_mark.png',
                                height: 22,
                                fit: BoxFit.contain,
                              ),
                              const SizedBox(width: 8),
                              Text(
                                brandText,
                                style: GoogleFonts.plusJakartaSans(
                                  color: Colors.white,
                                  fontSize: 16,
                                  fontWeight: FontWeight.w700,
                                  letterSpacing: 0.6,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 8),
                        ],

                        Text(
                          title,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            letterSpacing: -0.2,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          subtitle,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            color: Color(0xFFE6F4F1),
                            fontSize: 12.5,
                            height: 1.35,
                          ),
                        ),
                      ],
                    ),
                  ),
                  if (trailing != null) ...[
                    const SizedBox(width: AppSpacing.md),
                    trailing!,
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// CustomPainter untuk menggambar lekukan gelombang halus (Split Wave)
class _SplitWavePainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    // ── Layer 1: Gelombang Luar (Transparan Lembut) ──
    final paint1 = Paint()
      ..color = Colors.white.withValues(alpha: 0.12)
      ..style = PaintingStyle.fill;

    final path1 = Path();
    path1.moveTo(size.width * 0.60, 0);
    path1.cubicTo(
      size.width * 0.72,
      size.height * 0.40,
      size.width * 0.52,
      size.height * 0.70,
      size.width * 0.68,
      size.height,
    );
    path1.lineTo(size.width, size.height);
    path1.lineTo(size.width, 0);
    path1.close();
    canvas.drawPath(path1, paint1);

    // ── Layer 2: Gelombang Dalam (Aksen Lengkung Split) ──
    final paint2 = Paint()
      ..color = Colors.white.withValues(alpha: 0.20)
      ..style = PaintingStyle.fill;

    final path2 = Path();
    path2.moveTo(size.width * 0.76, 0);
    path2.cubicTo(
      size.width * 0.86,
      size.height * 0.35,
      size.width * 0.68,
      size.height * 0.75,
      size.width * 0.84,
      size.height,
    );
    path2.lineTo(size.width, size.height);
    path2.lineTo(size.width, 0);
    path2.close();
    canvas.drawPath(path2, paint2);

    // ── Layer 3: Aksen Sudut Kanan Atas ──
    final paint3 = Paint()
      ..color = Colors.white.withValues(alpha: 0.08)
      ..style = PaintingStyle.fill;

    final path3 = Path();
    path3.moveTo(size.width * 0.88, 0);
    path3.quadraticBezierTo(
      size.width * 0.85,
      size.height * 0.50,
      size.width,
      size.height * 0.60,
    );
    path3.lineTo(size.width, 0);
    path3.close();
    canvas.drawPath(path3, paint3);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
