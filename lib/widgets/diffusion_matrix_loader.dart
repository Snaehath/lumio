import 'dart:math' as math;
import 'package:flutter/material.dart';

/// ChatGPT / DALL-E style dot-matrix diffusion loading animation.
/// Renders an animated grid of glowing particles with traveling latent ripples
/// and a floating progress pill.
class DiffusionMatrixLoader extends StatefulWidget {
  const DiffusionMatrixLoader({
    required this.progress,
    required this.statusMessage,
    this.ratio = '1:1',
    this.height = 280,
    super.key,
  });

  final double progress; // 0.0 to 1.0
  final String statusMessage;
  final String ratio;
  final double height;

  @override
  State<DiffusionMatrixLoader> createState() => _DiffusionMatrixLoaderState();
}

class _DiffusionMatrixLoaderState extends State<DiffusionMatrixLoader>
    with SingleTickerProviderStateMixin {
  late final AnimationController _animController;

  @override
  void initState() {
    super.initState();
    _animController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 3200),
    )..repeat();
  }

  @override
  void dispose() {
    _animController.dispose();
    super.dispose();
  }

  double _getAspectRatio() {
    return switch (widget.ratio) {
      '9:16' || 'portrait' => 9 / 16,
      '16:9' || 'landscape' => 16 / 9,
      '3:2' => 3 / 2,
      _ => 1.0,
    };
  }

  @override
  Widget build(BuildContext context) {
    final percent = (widget.progress * 100).clamp(0, 100).toInt();
    final targetAspect = _getAspectRatio();

    return Center(
      child: Container(
        constraints: BoxConstraints(
          maxHeight: widget.height,
          maxWidth: widget.height * (targetAspect > 1.0 ? targetAspect : 1.0),
        ),
        child: AspectRatio(
          aspectRatio: targetAspect,
          child: Container(
            decoration: BoxDecoration(
              color: const Color(0xFF070B11),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                color: const Color(0xFF1E2E42),
                width: 1.2,
              ),
              boxShadow: [
                BoxShadow(
                  color: const Color(0xFF1E3A5F).withValues(alpha: 0.22),
                  blurRadius: 20,
                  offset: const Offset(0, 6),
                ),
              ],
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(20),
              child: Stack(
                fit: StackFit.expand,
                children: [
                  // Animated Matrix Canvas
                  AnimatedBuilder(
                    animation: _animController,
                    builder: (context, _) {
                      return CustomPaint(
                        painter: _MatrixPainter(
                          animationValue: _animController.value,
                          progress: widget.progress,
                        ),
                      );
                    },
                  ),

                  // Floating percentage pill (bottom-right)
                  Positioned(
                    right: 14,
                    bottom: 14,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 14,
                        vertical: 6,
                      ),
                      decoration: BoxDecoration(
                        color: const Color(0xE6141E2B),
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(
                          color: const Color(0xFF3296FF).withValues(alpha: 0.35),
                          width: 1.0,
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: const Color(0xFF3296FF).withValues(alpha: 0.2),
                            blurRadius: 8,
                          ),
                        ],
                      ),
                      child: Text(
                        '$percent%',
                        style: const TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w800,
                          color: Color(0xFF339BFE),
                          letterSpacing: 0.2,
                        ),
                      ),
                    ),
                  ),

                  // Status Message Badge (bottom-left)
                  Positioned(
                    left: 14,
                    bottom: 14,
                    right: 80,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 6,
                      ),
                      decoration: BoxDecoration(
                        color: const Color(0xCC0A111A),
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(
                          color: const Color(0x331E3048),
                        ),
                      ),
                      child: Text(
                        widget.statusMessage,
                        style: const TextStyle(
                          fontSize: 11.5,
                          fontWeight: FontWeight.w600,
                          color: Color(0xFFB0C8E8),
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _MatrixPainter extends CustomPainter {
  const _MatrixPainter({
    required this.animationValue,
    required this.progress,
  });

  final double animationValue;
  final double progress;

  @override
  void paint(Canvas canvas, Size size) {
    const int cols = 24;
    const int rows = 24;

    const double padX = 20.0;
    const double padY = 20.0;

    final double stepX = (size.width - padX * 2) / (cols - 1);
    final double stepY = (size.height - padY * 2) / (rows - 1);

    final double t = animationValue;

    // Two orbiting wave centers that sweep organic energy ripples through the matrix
    final double w1x = size.width * 0.46 + math.cos(t * 2 * math.pi) * size.width * 0.22;
    final double w1y = size.height * 0.42 + math.sin(t * 2 * math.pi) * size.height * 0.22;

    final double w2x = size.width * 0.54 + math.cos(t * 2 * math.pi + 2.4) * size.width * 0.20;
    final double w2y = size.height * 0.58 + math.sin(t * 2 * math.pi + 2.4) * size.height * 0.20;

    final paint = Paint()..isAntiAlias = true;

    for (int r = 0; r < rows; r++) {
      for (int c = 0; c < cols; c++) {
        final double x = padX + c * stepX;
        final double y = padY + r * stepY;

        final double dx1 = x - w1x;
        final double dy1 = y - w1y;
        final double d1 = math.sqrt(dx1 * dx1 + dy1 * dy1);

        final double dx2 = x - w2x;
        final double dy2 = y - w2y;
        final double d2 = math.sqrt(dx2 * dx2 + dy2 * dy2);

        // Circular wave propagation with exponential spatial attenuation
        final double wave1 = math.sin(d1 * 0.052 - t * 4 * math.pi) * 0.5 + 0.5;
        final double atten1 = math.exp(-d1 / (size.width * 0.36));

        final double wave2 = math.sin(d2 * 0.060 - t * 5 * math.pi) * 0.5 + 0.5;
        final double atten2 = math.exp(-d2 / (size.width * 0.30));

        double intensity = math.max(wave1 * atten1 * 1.5, wave2 * atten2 * 1.25);
        intensity = intensity.clamp(0.0, 1.0);

        final double radius = 1.2 + intensity * 2.2;

        Color dotColor;
        if (intensity < 0.22) {
          // Inactive dim navy background dot
          dotColor = const Color(0x6616253C);
        } else if (intensity < 0.70) {
          // Mid electric blue glow
          final double k = (intensity - 0.22) / 0.48;
          dotColor = Color.lerp(
            const Color(0xFF1B406E),
            const Color(0xFF339BFE),
            k,
          )!;
        } else {
          // White-hot core electric highlight
          final double k = (intensity - 0.70) / 0.30;
          dotColor = Color.lerp(
            const Color(0xFF339BFE),
            const Color(0xFFE2F0FF),
            k,
          )!;
        }

        paint.color = dotColor;
        canvas.drawCircle(Offset(x, y), radius, paint);
      }
    }
  }

  @override
  bool shouldRepaint(covariant _MatrixPainter oldDelegate) {
    return oldDelegate.animationValue != animationValue ||
        oldDelegate.progress != progress;
  }
}
