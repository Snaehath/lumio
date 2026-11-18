import 'dart:math' as math;
import 'package:flutter/material.dart';
import '../theme/app_theme.dart';

/// Pure vector-generated brand mark for Lumio.
/// Renders the 3-petal organic seedling/sprout mark procedurally with
/// cubic Bézier curves and vibrant brand gradient.
class LumioLogo extends StatelessWidget {
  const LumioLogo({this.size = 28, super.key});

  final double size;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: size,
      height: size,
      child: const CustomPaint(
        painter: LumioLogoPainter(),
      ),
    );
  }
}

class LumioLogoPainter extends CustomPainter {
  const LumioLogoPainter();

  @override
  void paint(Canvas canvas, Size size) {
    final s = size.shortestSide;
    final paint = Paint()
      ..shader = AppColors.accentGradient.createShader(
        Rect.fromLTWH(0, 0, s, s),
      )
      ..isAntiAlias = true
      ..style = PaintingStyle.fill;

    // Mathematical definition of the 3 Lumio seedling petals:
    // 1. Top-Left Petal: upright, slightly tilted left
    // 2. Top-Right Petal: angled at ~30° above horizontal
    // 3. Bottom-Left Petal: angled at ~44° below negative x-axis
    final specs = [
      // (base_x, base_y, angle_deg, length, half_width, tip_radius)
      (s * 0.45, s * 0.52, -88.0, s * 0.40, s * 0.175, s * 0.050),
      (s * 0.48, s * 0.50, -30.0, s * 0.47, s * 0.185, s * 0.055),
      (s * 0.43, s * 0.53, 136.0, s * 0.46, s * 0.180, s * 0.052),
    ];

    for (final (bx, by, angleDeg, len, halfW, tipR) in specs) {
      final rad = angleDeg * (math.pi / 180.0);
      final ux = math.cos(rad);
      final uy = math.sin(rad);
      final px = -uy;
      final py = ux;

      final tx = bx + ux * len;
      final ty = by + uy * len;

      // Base point
      final p0x = bx;
      final p0y = by;

      // Left flank belly control point
      final p1x = bx + ux * (len * 0.40) + px * halfW;
      final p1y = by + uy * (len * 0.40) + py * halfW;

      // Left tip transition control point
      final p2x = tx - ux * (len * 0.14) + px * (tipR * 1.4);
      final p2y = ty - uy * (len * 0.14) + py * (tipR * 1.4);

      // Tip point
      final p3x = tx;
      final p3y = ty;

      // Right tip transition control point
      final p4x = tx - ux * (len * 0.14) - px * (tipR * 1.4);
      final p4y = ty - uy * (len * 0.14) - py * (tipR * 1.4);

      // Right flank belly control point
      final p5x = bx + ux * (len * 0.40) - px * halfW;
      final p5y = by + uy * (len * 0.40) - py * halfW;

      final path = Path()
        ..moveTo(p0x, p0y)
        ..cubicTo(p1x, p1y, p2x, p2y, p3x, p3y)
        ..cubicTo(p4x, p4y, p5x, p5y, p0x, p0y)
        ..close();

      canvas.drawPath(path, paint);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
