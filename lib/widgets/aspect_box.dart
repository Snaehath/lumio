import 'package:flutter/material.dart';
import '../theme/app_theme.dart';

class AspectBox extends StatelessWidget {
  const AspectBox({
    required this.ratioKey,
    required this.label,
    required this.selected,
    required this.onTap,
    super.key,
  });

  final String ratioKey;
  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(16),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 180),
            padding: const EdgeInsets.symmetric(vertical: 14),
            decoration: BoxDecoration(
              color: AppColors.surfaceCard,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: selected ? AppColors.accent : AppColors.border,
                width: selected ? 1.6 : 1.0,
              ),
              boxShadow: selected
                  ? [
                      BoxShadow(
                        color: AppColors.accent.withValues(alpha: 0.18),
                        blurRadius: 10,
                        offset: const Offset(0, 2),
                      ),
                    ]
                  : null,
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                _buildShapeIcon(),
                const SizedBox(height: 8),
                Text(
                  label,
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    color: selected ? AppColors.accentLight : AppColors.textSecondary,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildShapeIcon() {
    double w = 22;
    double h = 22;

    switch (ratioKey) {
      case '1:1':
        w = 20;
        h = 20;
        break;
      case '3:2':
        w = 24;
        h = 16;
        break;
      case '9:16':
        w = 15;
        h = 24;
        break;
      case '16:9':
        w = 26;
        h = 15;
        break;
    }

    return Container(
      width: w,
      height: h,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(4),
        border: Border.all(
          color: selected ? AppColors.accent : AppColors.textMuted,
          width: 1.6,
        ),
      ),
    );
  }
}
