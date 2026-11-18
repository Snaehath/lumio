import 'package:flutter/material.dart';
import '../theme/app_theme.dart';

class ChoicePill extends StatelessWidget {
  const ChoicePill({
    required this.selected,
    required this.label,
    required this.icon,
    required this.onTap,
    super.key,
  });

  final bool selected;
  final String label;
  final IconData icon;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => Material(
    color: selected ? AppColors.accent.withValues(alpha: 0.18) : AppColors.surfaceCard,
    borderRadius: BorderRadius.circular(15),
    child: InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(15),
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(15),
          border: Border.all(
            color: selected ? AppColors.accent : AppColors.border,
          ),
        ),
        padding: const EdgeInsets.symmetric(vertical: 12),
        child: Column(
          children: [
            Icon(
              icon,
              size: 20,
              color: selected ? AppColors.accent : AppColors.textSecondary,
            ),
            const SizedBox(height: 5),
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
  );
}
