import 'package:flutter/material.dart';
import '../theme/app_theme.dart';

class StepProgress extends StatelessWidget {
  const StepProgress({
    required this.completed,
    required this.total,
    this.compact = false,
    super.key,
  });

  final int completed;
  final int total;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    final progress = total > 0
        ? (completed / total).clamp(0.0, 1.0).toDouble()
        : null;
    final label = '$completed of $total steps';

    if (compact) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            label,
            style: const TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w700,
              color: AppColors.textSecondary,
            ),
          ),
          const SizedBox(height: 6),
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(
              value: progress,
              minHeight: 4,
              backgroundColor: AppColors.surfaceElevated,
              color: AppColors.accent,
            ),
          ),
        ],
      );
    }

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text(
              'Rendering progress',
              style: TextStyle(
                color: AppColors.textSecondary,
                fontSize: 12.5,
                fontWeight: FontWeight.w600,
              ),
            ),
            Text(
              label,
              style: const TextStyle(
                color: AppColors.accentLight,
                fontSize: 12.5,
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        ClipRRect(
          borderRadius: BorderRadius.circular(6),
          child: LinearProgressIndicator(
            value: progress,
            minHeight: 6,
            backgroundColor: AppColors.surfaceElevated,
            color: AppColors.accent,
          ),
        ),
      ],
    );
  }
}
