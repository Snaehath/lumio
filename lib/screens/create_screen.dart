import 'package:flutter/material.dart';
import '../models/ai_model.dart';
import '../theme/app_theme.dart';
import '../widgets/brand_logo.dart';
import '../widgets/model_art.dart';
import '../widgets/model_card.dart';

class CreateScreen extends StatelessWidget {
  const CreateScreen({
    required this.selectedModelId,
    required this.checkingServer,
    required this.serverOnline,
    required this.comfyOnline,
    required this.onCheckServer,
    required this.onModelChanged,
    required this.onStartCreate,
    super.key,
  });

  final String selectedModelId;
  final bool checkingServer;
  final bool? serverOnline;
  final bool? comfyOnline;
  final VoidCallback onCheckServer;
  final ValueChanged<String> onModelChanged;
  final VoidCallback onStartCreate;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        // Proportionally scale hero height so the layout fits comfortably
        // across screen heights without leaving awkward dead space or forcing scrolling
        final heroHeight = (constraints.maxHeight * 0.33).clamp(200.0, 255.0);

        return SingleChildScrollView(
          physics: const ClampingScrollPhysics(),
          child: ConstrainedBox(
            constraints: BoxConstraints(minHeight: constraints.maxHeight),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                // Top Bar
                Padding(
                  padding: const EdgeInsets.fromLTRB(20, 10, 20, 4),
                  child: Row(
                    children: [
                      const LumioLogo(size: 28),
                      const SizedBox(width: 10),
                      const Text(
                        'Lumio',
                        style: TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.w800,
                          letterSpacing: -0.8,
                          color: AppColors.textPrimary,
                        ),
                      ),
                      const Spacer(),
                      // ComfyUI status pill
                      InkWell(
                        onTap: onCheckServer,
                        borderRadius: BorderRadius.circular(20),
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 11,
                            vertical: 6,
                          ),
                          decoration: BoxDecoration(
                            color: AppColors.surfaceElevated,
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(color: AppColors.border),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Container(
                                width: 7,
                                height: 7,
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  color: checkingServer
                                      ? Colors.amber
                                      : (serverOnline == true && (comfyOnline != false))
                                      ? AppColors.statusOnline
                                      : AppColors.statusOffline,
                                  boxShadow: (serverOnline == true && (comfyOnline != false))
                                      ? [
                                          BoxShadow(
                                            color: AppColors.statusOnline.withValues(alpha: 0.5),
                                            blurRadius: 5,
                                          ),
                                        ]
                                      : null,
                                ),
                              ),
                              const SizedBox(width: 7),
                              Text(
                                checkingServer
                                    ? 'Checking…'
                                    : (serverOnline != true)
                                    ? 'Offline'
                                    : comfyOnline == true
                                    ? 'ComfyUI • Local'
                                    : 'API online',
                                style: const TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w600,
                                  color: AppColors.textSecondary,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),

                // Hero Artwork & Editorial Headline
                Stack(
                  children: [
                    HeroArtworkHeader(height: heroHeight),
                    Positioned(
                      bottom: 14,
                      left: 20,
                      right: 20,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Create\nstunning images\non your device',
                            style: TextStyle(
                              fontSize: 28,
                              height: 1.12,
                              fontWeight: FontWeight.w800,
                              letterSpacing: -0.8,
                              color: Colors.white,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            'High-quality image generation with local ComfyUI workflows.',
                            style: TextStyle(
                              fontSize: 13,
                              height: 1.35,
                              color: Colors.white.withValues(alpha: 0.74),
                              fontWeight: FontWeight.w400,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),

                // Model Selection & CTA
                Padding(
                  padding: const EdgeInsets.fromLTRB(20, 14, 20, 18),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Select a model',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
                          color: AppColors.textPrimary,
                        ),
                      ),
                      const SizedBox(height: 12),
                      for (final item in AiModel.all) ...[
                        ModelCard(
                          model: item,
                          selected: selectedModelId == item.id,
                          onTap: () => onModelChanged(item.id),
                        ),
                        if (item != AiModel.all.last) const SizedBox(height: 11),
                      ],

                      const SizedBox(height: 20),

                      // Bottom CTA button: "✦ Create Image >"
                      Material(
                        color: Colors.transparent,
                        child: InkWell(
                          onTap: onStartCreate,
                          borderRadius: BorderRadius.circular(28),
                          child: Ink(
                            height: 56,
                            decoration: BoxDecoration(
                              gradient: AppColors.accentGradient,
                              borderRadius: BorderRadius.circular(28),
                              boxShadow: [
                                BoxShadow(
                                  color: AppColors.accent.withValues(alpha: 0.35),
                                  blurRadius: 18,
                                  offset: const Offset(0, 6),
                                ),
                              ],
                            ),
                            child: const Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(
                                  Icons.auto_awesome_rounded,
                                  color: Colors.white,
                                  size: 20,
                                ),
                                SizedBox(width: 10),
                                Text(
                                  'Create Image',
                                  style: TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.w700,
                                    color: Colors.white,
                                  ),
                                ),
                                SizedBox(width: 6),
                                Icon(
                                  Icons.chevron_right_rounded,
                                  color: Colors.white,
                                  size: 22,
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
