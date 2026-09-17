import 'package:flutter/material.dart';

/// Ultra-Clean Modern Background Painter (Dot Grid & Ambient Canvas)
class ModernSubtleBackground extends CustomPainter {
  const ModernSubtleBackground();

  @override
  void paint(Canvas canvas, Size size) {
    final double w = size.width;
    final double h = size.height;

    // 1. Base clean background canvas
    canvas.drawRect(
      Rect.fromLTWH(0, 0, w, h),
      Paint()..color = const Color(0xFFF8FAFC),
    );

    // 2. Subtle micro dot grid matrix
    final dotPaint = Paint()
      ..color = const Color(0xFF94A3B8).withValues(alpha: 0.22)
      ..style = PaintingStyle.fill;

    const double spacing = 28.0;
    for (double x = spacing / 2; x < w; x += spacing) {
      for (double y = spacing / 2; y < h; y += spacing) {
        canvas.drawCircle(Offset(x, y), 1.2, dotPaint);
      }
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
