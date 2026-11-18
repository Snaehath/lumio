import 'package:flutter/material.dart';
import '../theme/app_theme.dart';

/// Lumio brand mark: high-resolution glowing 3-petal seedling logo
class LumioLogo extends StatelessWidget {
  const LumioLogo({this.size = 28, super.key});

  final double size;

  @override
  Widget build(BuildContext context) {
    return Image.asset(
      'assets/images/lumio_logo.png',
      width: size,
      height: size,
      fit: BoxFit.contain,
      errorBuilder: (_, _, _) => CustomPaint(
        size: Size(size, size),
        painter: const _LumioLogoPainterFallback(),
      ),
    );
  }
}

class _LumioLogoPainterFallback extends CustomPainter {
  const _LumioLogoPainterFallback();

  @override
  void paint(Canvas canvas, Size size) {
    final s = size.shortestSide;
    final paint = Paint()
      ..shader = AppColors.accentGradient.createShader(
        Rect.fromLTWH(0, 0, s, s),
      )
      ..isAntiAlias = true
      ..style = PaintingStyle.fill;

    canvas.drawCircle(Offset(s / 2, s / 2), s * 0.4, paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
