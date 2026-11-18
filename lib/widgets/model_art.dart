import 'package:flutter/material.dart';
import '../theme/app_theme.dart';

class ModelThumbnail extends StatelessWidget {
  const ModelThumbnail({
    required this.modelId,
    this.width = 52,
    this.height = 52,
    this.borderRadius = 12,
    super.key,
  });

  final String modelId;
  final double width;
  final double height;
  final double borderRadius;

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(borderRadius),
      child: SizedBox(
        width: width,
        height: height,
        child: CustomPaint(
          size: Size(width, height),
          painter: _ModelThumbnailPainter(modelId),
        ),
      ),
    );
  }
}

class _ModelThumbnailPainter extends CustomPainter {
  final String modelId;
  _ModelThumbnailPainter(this.modelId);

  @override
  void paint(Canvas canvas, Size size) {
    final rect = Offset.zero & size;

    if (modelId == 'moss') {
      // Mountain sunrise with dramatic orange sky
      final skyGradient = LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [
          const Color(0xFF1E3A52),
          const Color(0xFF9E4B28),
          const Color(0xFFE87834),
          const Color(0xFFFAA44A),
        ],
      ).createShader(rect);

      canvas.drawRect(rect, Paint()..shader = skyGradient);

      // Back peak
      final backMountain = Path()
        ..moveTo(0, size.height * 0.75)
        ..lineTo(size.width * 0.35, size.height * 0.32)
        ..lineTo(size.width * 0.65, size.height * 0.65)
        ..lineTo(size.width, size.height * 0.45)
        ..lineTo(size.width, size.height)
        ..lineTo(0, size.height)
        ..close();
      canvas.drawPath(
        backMountain,
        Paint()..color = const Color(0xFF384358).withValues(alpha: 0.85),
      );

      // Snow highlight
      final snow = Path()
        ..moveTo(size.width * 0.35, size.height * 0.32)
        ..lineTo(size.width * 0.42, size.height * 0.45)
        ..lineTo(size.width * 0.35, size.height * 0.5)
        ..lineTo(size.width * 0.28, size.height * 0.46)
        ..close();
      canvas.drawPath(snow, Paint()..color = Colors.white.withValues(alpha: 0.75));

      // Foreground mountain
      final frontMountain = Path()
        ..moveTo(0, size.height * 0.6)
        ..lineTo(size.width * 0.55, size.height * 0.48)
        ..lineTo(size.width * 0.85, size.height * 0.75)
        ..lineTo(size.width, size.height * 0.65)
        ..lineTo(size.width, size.height)
        ..lineTo(0, size.height)
        ..close();
      canvas.drawPath(
        frontMountain,
        Paint()..color = const Color(0xFF1E262B),
      );
    } else if (modelId == 'fibo2') {
      // Lush green forest with sunbeams
      final forestGradient = LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [
          const Color(0xFF285E43),
          const Color(0xFF1D4733),
          const Color(0xFF0F261B),
        ],
      ).createShader(rect);
      canvas.drawRect(rect, Paint()..shader = forestGradient);

      // Sunbeams
      final sunbeam = Paint()
        ..shader = LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            const Color(0x66FFEB99),
            Colors.transparent,
          ],
        ).createShader(rect);
      final beamPath = Path()
        ..moveTo(0, 0)
        ..lineTo(size.width * 0.4, 0)
        ..lineTo(size.width, size.height * 0.8)
        ..lineTo(size.width * 0.6, size.height)
        ..close();
      canvas.drawPath(beamPath, sunbeam);

      // Silhouetted pines
      final pinePaint = Paint()..color = const Color(0xFF0A1C14);
      for (var i = 0; i < 4; i++) {
        final x = size.width * (0.15 + i * 0.25);
        final tree = Path()
          ..moveTo(x, size.height * 0.35)
          ..lineTo(x + size.width * 0.15, size.height * 0.95)
          ..lineTo(x - size.width * 0.15, size.height * 0.95)
          ..close();
        canvas.drawPath(tree, pinePaint);
      }
    } else if (modelId == 'qwen_image') {
      // Golden hour clouds
      final cloudSky = LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [
          const Color(0xFF4A3B69),
          const Color(0xFF8B4D68),
          const Color(0xFFDF7458),
          const Color(0xFFF7B163),
        ],
      ).createShader(rect);
      canvas.drawRect(rect, Paint()..shader = cloudSky);

      // Cloud puffs
      final cloudPaint = Paint()
        ..color = const Color(0xFFFFD4A3).withValues(alpha: 0.65);
      canvas.drawCircle(Offset(size.width * 0.3, size.height * 0.6), size.width * 0.25, cloudPaint);
      canvas.drawCircle(Offset(size.width * 0.6, size.height * 0.55), size.width * 0.3, cloudPaint);
      canvas.drawCircle(Offset(size.width * 0.8, size.height * 0.65), size.width * 0.22, cloudPaint);
    } else {
      // Default / SANA: Sleek amber gradient
      final defaultGrad = LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [
          const Color(0xFF2E3D35),
          AppColors.accent.withValues(alpha: 0.6),
        ],
      ).createShader(rect);
      canvas.drawRect(rect, Paint()..shader = defaultGrad);
    }
  }

  @override
  bool shouldRepaint(covariant _ModelThumbnailPainter oldDelegate) =>
      oldDelegate.modelId != modelId;
}

class HeroArtworkHeader extends StatelessWidget {
  const HeroArtworkHeader({this.height = 210, super.key});

  final double height;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: height,
      width: double.infinity,
      child: Stack(
        fit: StackFit.expand,
        children: [
          Image.asset(
            'assets/images/hero_mountain.jpg',
            fit: BoxFit.cover,
            alignment: Alignment.centerRight,
            errorBuilder: (_, _, _) => CustomPaint(
              painter: _HeroLandscapePainter(),
            ),
          ),
          // Gradient dissolves to deep forest background at the bottom
          Container(
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  Colors.transparent,
                  Color(0x2209120F),
                  Color(0x9909120F),
                  AppColors.scaffoldBackground,
                ],
                stops: [0.0, 0.35, 0.72, 1.0],
              ),
            ),
          ),
          // Subtle horizontal dissolve from left to protect headline text contrast
          Container(
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.centerLeft,
                end: Alignment.centerRight,
                colors: [
                  Color(0xDD09120F),
                  Color(0x8809120F),
                  Colors.transparent,
                ],
                stops: [0.0, 0.35, 0.8],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _HeroLandscapePainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final rect = Offset.zero & size;

    final sky = LinearGradient(
      begin: Alignment.topCenter,
      end: Alignment.bottomCenter,
      colors: [
        const Color(0xFF0D1D22),
        const Color(0xFF1E373B),
        const Color(0xFF7A3B1B),
        const Color(0xFFD36224),
        const Color(0xFFFFA24A),
      ],
      stops: const [0.0, 0.28, 0.6, 0.82, 1.0],
    ).createShader(rect);
    canvas.drawRect(rect, Paint()..shader = sky);

    // Glowing sun behind ridge on right
    final sunCenter = Offset(size.width * 0.82, size.height * 0.45);
    final sunGlow = Paint()
      ..shader = RadialGradient(
        colors: [
          const Color(0xFFFFF2D0),
          const Color(0xFFFF9438).withValues(alpha: 0.85),
          Colors.transparent,
        ],
        stops: const [0.0, 0.35, 1.0],
      ).createShader(Rect.fromCircle(center: sunCenter, radius: 95));
    canvas.drawCircle(sunCenter, 95, sunGlow);

    // Distant mountain ridge
    final distantPeak = Path()
      ..moveTo(size.width * 0.2, size.height)
      ..lineTo(size.width * 0.45, size.height * 0.55)
      ..lineTo(size.width * 0.65, size.height * 0.68)
      ..lineTo(size.width * 0.85, size.height * 0.38)
      ..lineTo(size.width, size.height * 0.52)
      ..lineTo(size.width, size.height)
      ..close();
    canvas.drawPath(
      distantPeak,
      Paint()..color = const Color(0xFF382A2B).withValues(alpha: 0.7),
    );

    // Midground sharp cliff
    final midCliff = Path()
      ..moveTo(size.width * 0.35, size.height)
      ..lineTo(size.width * 0.75, size.height * 0.42)
      ..lineTo(size.width * 0.88, size.height * 0.5)
      ..lineTo(size.width, size.height * 0.32)
      ..lineTo(size.width, size.height)
      ..close();
    canvas.drawPath(
      midCliff,
      Paint()
        ..shader = LinearGradient(
          begin: Alignment.topRight,
          end: Alignment.bottomLeft,
          colors: [
            const Color(0xFF854B2A),
            const Color(0xFF281C18),
          ],
        ).createShader(rect),
    );

    // Flowing warm ribbon across bottom-center
    final ribbon = Path()
      ..moveTo(size.width * 0.1, size.height * 0.88)
      ..cubicTo(
        size.width * 0.4,
        size.height * 0.72,
        size.width * 0.7,
        size.height * 0.96,
        size.width,
        size.height * 0.76,
      )
      ..lineTo(size.width, size.height)
      ..lineTo(size.width * 0.1, size.height)
      ..close();
    canvas.drawPath(
      ribbon,
      Paint()
        ..shader = LinearGradient(
          begin: Alignment.centerLeft,
          end: Alignment.centerRight,
          colors: [
            Colors.transparent,
            const Color(0xFFE86F20).withValues(alpha: 0.5),
            const Color(0xFFFFAE52).withValues(alpha: 0.3),
            Colors.transparent,
          ],
        ).createShader(rect),
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
