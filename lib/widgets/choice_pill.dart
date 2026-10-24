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
    color: selected ? const Color(0xFFF0DFD8) : Colors.white,
    borderRadius: BorderRadius.circular(15),
    child: InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(15),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 12),
        child: Column(
          children: [
            Icon(
              icon,
              size: 20,
              color: selected ? accent : ink.withValues(alpha: .65),
            ),
            const SizedBox(height: 5),
            Text(
              label,
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w700,
                color: selected ? accent : ink,
              ),
            ),
          ],
        ),
      ),
    ),
  );
}
