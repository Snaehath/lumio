import 'package:flutter/material.dart';
import '../models/ai_model.dart';
import '../theme/app_theme.dart';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({
    required this.comfyOnline,
    required this.checkingServer,
    required this.onCheckServer,
    required this.onClearHistory,
    required this.historyCount,
    super.key,
  });

  final bool? comfyOnline;
  final bool checkingServer;
  final VoidCallback onCheckServer;
  final VoidCallback onClearHistory;
  final int historyCount;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.scaffoldBackground,
      appBar: AppBar(
        backgroundColor: AppColors.scaffoldBackground,
        elevation: 0,
        title: const Text(
          'Settings',
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.w800,
            color: AppColors.textPrimary,
          ),
        ),
        centerTitle: false,
      ),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(20, 10, 20, 32),
          children: [
            // Models Status Card (from D:\DevelopmentSide\AI-projects\sana-ai-image\api.py)
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'COMFYUI WORKFLOWS',
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 1.2,
                    color: AppColors.textMuted,
                  ),
                ),
                InkWell(
                  onTap: onCheckServer,
                  borderRadius: BorderRadius.circular(12),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          Icons.refresh_rounded,
                          size: 16,
                          color: checkingServer ? Colors.amber : AppColors.textSecondary,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          checkingServer ? 'Checking…' : 'Check status',
                          style: TextStyle(
                            fontSize: 12,
                            color: checkingServer ? Colors.amber : AppColors.textSecondary,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
            Container(
              padding: const EdgeInsets.all(18),
              decoration: BoxDecoration(
                color: AppColors.surfaceCard,
                borderRadius: BorderRadius.circular(18),
                border: Border.all(color: AppColors.border),
              ),
              child: Column(
                children: [
                  for (final m in AiModel.all) ...[
                    Row(
                      children: [
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Text(
                                  m.name,
                                  style: const TextStyle(
                                    fontSize: 14,
                                    fontWeight: FontWeight.w600,
                                    color: AppColors.textPrimary,
                                  ),
                                ),
                                if (m.hasLora) ...[
                                  const SizedBox(width: 6),
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 6,
                                      vertical: 2,
                                    ),
                                    decoration: BoxDecoration(
                                      color: AppColors.amberBadgeBg,
                                      borderRadius: BorderRadius.circular(10),
                                      border: Border.all(
                                        color: AppColors.amberBadgeBorder,
                                        width: 0.6,
                                      ),
                                    ),
                                    child: const Text(
                                      'LoRA 8 steps',
                                      style: TextStyle(
                                        fontSize: 9,
                                        fontWeight: FontWeight.w700,
                                        color: AppColors.amberBadgeText,
                                      ),
                                    ),
                                  ),
                                ],
                              ],
                            ),
                            const SizedBox(height: 2),
                            Text(
                              m.workflowBackend,
                              style: const TextStyle(
                                fontSize: 11,
                                color: AppColors.textMuted,
                              ),
                            ),
                          ],
                        ),
                        const Spacer(),
                        Text(
                          comfyOnline == true ? 'Ready' : 'Standby',
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: comfyOnline == true
                                ? AppColors.statusOnline
                                : AppColors.textMuted,
                          ),
                        ),
                      ],
                    ),
                    if (m != AiModel.all.last) const Divider(color: AppColors.border, height: 20),
                  ],
                ],
              ),
            ),

            const SizedBox(height: 28),

            // Storage & History
            const Text(
              'STORAGE & CACHE',
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w800,
                letterSpacing: 1.2,
                color: AppColors.textMuted,
              ),
            ),
            const SizedBox(height: 10),
            Container(
              padding: const EdgeInsets.all(18),
              decoration: BoxDecoration(
                color: AppColors.surfaceCard,
                borderRadius: BorderRadius.circular(18),
                border: Border.all(color: AppColors.border),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '$historyCount images stored locally',
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: AppColors.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 6),
                  const Text(
                    'Saved generations are stored in your device storage. Clearing does not delete them on the server.',
                    style: TextStyle(
                      fontSize: 12,
                      color: AppColors.textSecondary,
                    ),
                  ),
                  const SizedBox(height: 14),
                  OutlinedButton.icon(
                    onPressed: historyCount > 0 ? onClearHistory : null,
                    icon: const Icon(Icons.delete_outline_rounded, size: 18),
                    label: const Text('Clear Saved History'),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: const Color(0xFFFF7A7A),
                      side: const BorderSide(color: Color(0xFF6E281F)),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 32),
            Center(
              child: Text(
                'Lumio v1.0.0 • Local ComfyUI Client',
                style: TextStyle(
                  fontSize: 12,
                  color: AppColors.textMuted.withValues(alpha: 0.8),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
