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
        children: [
          Text(
            label,
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w700,
              color: ink.withValues(alpha: .7),
            ),
          ),
          const SizedBox(height: 8),
          ClipRRect(
            borderRadius: BorderRadius.circular(6),
            child: LinearProgressIndicator(
              value: progress,
              minHeight: 4,
              color: accent,
            ),
          ),
        ],
      );
    }
    return Column(
      children: [
        Text(
          label,
          textAlign: TextAlign.center,
          style: TextStyle(
            color: ink.withValues(alpha: .65),
            fontSize: 13,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 8),
        ClipRRect(
          borderRadius: BorderRadius.circular(8),
          child: LinearProgressIndicator(
            value: progress,
            minHeight: 6,
            color: accent,
          ),
        ),
      ],
    );
  }
}
