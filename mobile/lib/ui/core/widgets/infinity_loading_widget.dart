// File: infinity_loading_widget.dart
// Deskripsi: Widget animasi loading kustom berbentuk logo infinity (∞) dengan aliran cahaya hijau neon.
// Fungsi: Menggantikan spinner putar standar dengan animasi infinity loop yang halus, elegan, dan selalu berada di tengah.

import 'dart:math' as math;
import 'package:flutter/material.dart';

import '../../../../config/constants.dart';

/// Widget animasi ikon Infinity (∞) dengan aliran sinar hijau
class InfinityLoadingWidget extends StatefulWidget {
  final double width;
  final double height;
  final double strokeWidth;
  final Color primaryColor;
  final Color trackColor;
  final Duration duration;

  const InfinityLoadingWidget({
    super.key,
    this.width = 72,
    this.height = 38,
    this.strokeWidth = 4.0,
    this.primaryColor = AppColors.primary,
    this.trackColor = const Color(0xFFE2E8F0),
    this.duration = const Duration(milliseconds: 1800),
  });

  @override
  State<InfinityLoadingWidget> createState() => _InfinityLoadingWidgetState();
}

class _InfinityLoadingWidgetState extends State<InfinityLoadingWidget>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: widget.duration,
    )..repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: widget.width,
      height: widget.height,
      child: AnimatedBuilder(
        animation: _controller,
        builder: (context, child) {
          return CustomPaint(
            size: Size(widget.width, widget.height),
            painter: _InfinityPainter(
              progress: _controller.value,
              strokeWidth: widget.strokeWidth,
              primaryColor: widget.primaryColor,
              trackColor: widget.trackColor,
            ),
          );
        },
      ),
    );
  }
}

class _InfinityPainter extends CustomPainter {
  final double progress;
  final double strokeWidth;
  final Color primaryColor;
  final Color trackColor;

  _InfinityPainter({
    required this.progress,
    required this.strokeWidth,
    required this.primaryColor,
    required this.trackColor,
  });

  Path _generateInfinityPath(Size size) {
    final path = Path();
    final double cx = size.width / 2;
    final double cy = size.height / 2;
    final double padding = strokeWidth / 2 + 2;

    final double a = cx - padding;
    final double b = (cy - padding) * 2;

    const int steps = 140;
    for (int i = 0; i <= steps; i++) {
      final double t = (i / steps) * (2 * math.pi);
      final double x = cx + a * math.cos(t);
      final double y = cy + (b / 2) * math.sin(2 * t);

      if (i == 0) {
        path.moveTo(x, y);
      } else {
        path.lineTo(x, y);
      }
    }
    path.close();
    return path;
  }

  @override
  void paint(Canvas canvas, Size size) {
    final path = _generateInfinityPath(size);

    // 1. Draw Background Track (Jalur Halus Infinity)
    final trackPaint = Paint()
      ..color = trackColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;

    canvas.drawPath(path, trackPaint);

    // Sub-track dengan aksen hijau pudar
    final softTrackPaint = Paint()
      ..color = primaryColor.withValues(alpha: 0.12)
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth
      ..strokeCap = StrokeCap.round;

    canvas.drawPath(path, softTrackPaint);

    // 2. Compute Path Metrics untuk Aliran Cahaya (Beam Comet)
    final metricsList = path.computeMetrics().toList();
    if (metricsList.isEmpty) return;

    final metric = metricsList.first;
    final totalLength = metric.length;

    // Panjang berkas sinar ~ 36% dari total keliling
    final beamLength = totalLength * 0.36;
    final startDist = progress * totalLength;
    final endDist = startDist + beamLength;

    Path beamPath = Path();

    if (endDist <= totalLength) {
      beamPath = metric.extractPath(startDist, endDist);
    } else {
      // Loop wrapping melewati ujung
      beamPath = metric.extractPath(startDist, totalLength);
      beamPath.addPath(metric.extractPath(0.0, endDist - totalLength), Offset.zero);
    }

    // 3. Draw Glowing Green Beam (Sinar Hijau Bercahaya)
    final glowPaint = Paint()
      ..color = primaryColor.withValues(alpha: 0.4)
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth + 2.5
      ..strokeCap = StrokeCap.round
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 2.5);

    canvas.drawPath(beamPath, glowPaint);

    final beamPaint = Paint()
      ..color = primaryColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth
      ..strokeCap = StrokeCap.round;

    canvas.drawPath(beamPath, beamPaint);

    // 4. Draw Bright Head Particle (Titik Kepala Hijau Terang)
    final headDist = (endDist <= totalLength) ? endDist : (endDist - totalLength);
    final tangent = metric.getTangentForOffset(headDist);

    if (tangent != null) {
      final headPos = tangent.position;

      // Glow head
      final headGlowPaint = Paint()
        ..color = const Color(0xFF10B981).withValues(alpha: 0.6)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 4.0);
      canvas.drawCircle(headPos, strokeWidth * 1.4, headGlowPaint);

      // Core head dot
      final headDotPaint = Paint()
        ..color = Colors.white
        ..style = PaintingStyle.fill;
      canvas.drawCircle(headPos, strokeWidth * 0.65, headDotPaint);
    }
  }

  @override
  bool shouldRepaint(covariant _InfinityPainter oldDelegate) {
    return oldDelegate.progress != progress ||
        oldDelegate.strokeWidth != strokeWidth ||
        oldDelegate.primaryColor != primaryColor;
  }
}

/// Tampilan Loading Penuh di Tengah Layar dengan Logo Infinity & Pesan
class InfinityLoadingView extends StatelessWidget {
  final String? message;
  final double size;

  const InfinityLoadingView({
    super.key,
    this.message,
    this.size = 72,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          InfinityLoadingWidget(
            width: size,
            height: size * 0.52,
            strokeWidth: 4.2,
          ),
          if (message != null && message!.isNotEmpty) ...[
            const SizedBox(height: 14),
            Text(
              message!,
              style: const TextStyle(
                fontSize: 12.5,
                fontWeight: FontWeight.w600,
                color: Color(0xFF64748B),
                letterSpacing: 0.2,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ],
      ),
    );
  }
}

/// Overlay Modal Transparan saat proses Login / Loading Menyeluruh
class InfinityLoadingOverlay extends StatelessWidget {
  final String? message;

  const InfinityLoadingOverlay({
    super.key,
    this.message = 'Memproses autentikasi...',
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      color: Colors.black.withValues(alpha: 0.35),
      child: Center(
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
          margin: const EdgeInsets.symmetric(horizontal: 36),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(18),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.12),
                blurRadius: 18,
                offset: const Offset(0, 6),
              ),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const InfinityLoadingWidget(
                width: 76,
                height: 40,
                strokeWidth: 4.5,
              ),
              if (message != null && message!.isNotEmpty) ...[
                const SizedBox(height: 14),
                Text(
                  message!,
                  style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF1E293B),
                  ),
                  textAlign: TextAlign.center,
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
