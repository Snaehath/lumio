import 'package:flutter/material.dart';
import '../theme/app_theme.dart';

class TemplateCard extends StatelessWidget {
  const TemplateCard({
    required this.title,
    required this.tag,
    required this.icon,
    required this.onTap,
    super.key,
  });

  final String title;
  final String tag;
  final IconData icon;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => Material(
    color: Colors.white,
    borderRadius: BorderRadius.circular(17),
    child: InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(17),
      child: Container(
        width: 164,
        padding: const EdgeInsets.symmetric(horizontal: 13, vertical: 11),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(17),
          border: Border.all(color: ink.withValues(alpha: .06)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Row(
              children: [
                Icon(icon, size: 18, color: accent),
                const Spacer(),
                Icon(
                  Icons.add_rounded,
                  size: 16,
                  color: ink.withValues(alpha: .48),
                ),
              ],
            ),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  tag,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: 9,
                    letterSpacing: .55,
                    fontWeight: FontWeight.w700,
                    color: ink.withValues(alpha: .48),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    ),
  );
}
