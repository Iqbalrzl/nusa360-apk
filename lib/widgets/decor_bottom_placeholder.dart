import 'dart:math' as math;
import 'package:flutter/material.dart';

class DecorBottomPlaceholder extends StatelessWidget {
  final Color color;
  const DecorBottomPlaceholder({super.key, required this.color});

  @override
  Widget build(BuildContext context) {
    return CustomPaint(painter: _RingsPainter(color), willChange: false);
  }
}

class _RingsPainter extends CustomPainter {
  final Color color;
  _RingsPainter(this.color);

  @override
  void paint(Canvas canvas, Size size) {
    final paint =
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = 1.6
          ..color = color;

    final h = size.height;
    final w = size.width;

    // Wavy left lines
    final path = Path()..moveTo(0, h * 0.6);
    for (double x = 0; x <= w * 0.7; x += 6) {
      final y = h * 0.65 + 16 * math.sin(x / 22);
      path.lineTo(x, y);
    }
    canvas.drawPath(path, paint);

    // Concentric rings on the right
    final centers = [
      Offset(w * 0.60, h * 0.75),
      Offset(w * 0.78, h * 0.82),
      Offset(w * 0.92, h * 0.76),
    ];
    for (final c in centers) {
      for (double r = 14; r <= 82; r += 12) {
        canvas.drawCircle(c, r, paint);
      }
    }
  }

  @override
  bool shouldRepaint(covariant _RingsPainter oldDelegate) => false;
}
