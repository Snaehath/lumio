import 'dart:io';
import 'package:flutter/material.dart';
import '../models/ai_model.dart';
import '../theme/app_theme.dart';

class ImageDetailScreen extends StatelessWidget {
  const ImageDetailScreen({
    required this.job,
    required this.api,
    required this.onSave,
    required this.onDelete,
    required this.onReuse,
    super.key,
  });

  final Map<String, dynamic> job;
  final String api;
  final Future<void> Function() onSave;
  final Future<bool> Function() onDelete;
  final VoidCallback onReuse;

  @override
  Widget build(BuildContext context) {
    final modelId = job['model'] as String? ?? 'moss';
    final modelName = AiModel.fromId(modelId).name;
    final width = job['width'] ?? '?';
    final height = job['height'] ?? '?';
    final prompt = job['prompt'] as String? ?? 'Untitled image';
    final steps = job['steps'] ?? '?';
    final ratio = (job['aspect_ratio'] as String? ?? 'square').toUpperCase();

    return Scaffold(
      backgroundColor: AppColors.scaffoldBackground,
      appBar: AppBar(
        backgroundColor: AppColors.scaffoldBackground,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(
            Icons.arrow_back_ios_new_rounded,
            color: AppColors.textPrimary,
            size: 20,
          ),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          modelName,
          style: const TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w700,
            color: AppColors.textPrimary,
          ),
        ),
        actions: [
          IconButton(
            tooltip: 'Delete image',
            icon: const Icon(
              Icons.delete_outline_rounded,
              color: Color(0xFFFF7A7A),
            ),
            onPressed: () async {
              if (await onDelete() && context.mounted) Navigator.pop(context);
            },
          ),
        ],
      ),
      body: Column(
        children: [
          Expanded(
            child: InteractiveViewer(
              minScale: 1,
              maxScale: 4,
              child: SizedBox.expand(
                child: Center(
                  child: _preview(fit: BoxFit.contain),
                ),
              ),
            ),
          ),
          Container(
            width: double.infinity,
            decoration: const BoxDecoration(
              color: AppColors.surface,
              borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
              border: Border(
                top: BorderSide(color: AppColors.border),
              ),
            ),
            child: SafeArea(
              top: false,
              child: Padding(
                padding: const EdgeInsets.fromLTRB(20, 20, 20, 16),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      prompt,
                      maxLines: 3,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontSize: 14.5,
                        height: 1.4,
                        fontWeight: FontWeight.w600,
                        color: AppColors.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 12),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: [
                        _detailChip('$width × $height'),
                        _detailChip('$steps steps'),
                        _detailChip(ratio),
                        _detailChip(modelName),
                      ],
                    ),
                    const SizedBox(height: 18),
                    Row(
                      children: [
                        Expanded(
                          child: GestureDetector(
                            onTap: onSave,
                            child: Container(
                              height: 48,
                              decoration: BoxDecoration(
                                gradient: AppColors.accentGradient,
                                borderRadius: BorderRadius.circular(24),
                                boxShadow: [
                                  BoxShadow(
                                    color: AppColors.accent.withValues(alpha: 0.3),
                                    blurRadius: 10,
                                    offset: const Offset(0, 3),
                                  ),
                                ],
                              ),
                              child: const Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(
                                    Icons.download_rounded,
                                    color: Colors.white,
                                    size: 20,
                                  ),
                                  SizedBox(width: 8),
                                  Text(
                                    'Save Image',
                                    style: TextStyle(
                                      color: Colors.white,
                                      fontWeight: FontWeight.w700,
                                      fontSize: 14,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: OutlinedButton.icon(
                            onPressed: () {
                              onReuse();
                              Navigator.pop(context);
                            },
                            icon: const Icon(
                              Icons.replay_rounded,
                              size: 18,
                              color: AppColors.accentLight,
                            ),
                            label: const Text(
                              'Reuse Prompt',
                              style: TextStyle(
                                fontWeight: FontWeight.w700,
                                fontSize: 13.5,
                              ),
                            ),
                            style: OutlinedButton.styleFrom(
                              minimumSize: const Size.fromHeight(48),
                              foregroundColor: AppColors.accentLight,
                              side: const BorderSide(color: AppColors.borderLight),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(24),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _detailChip(String label) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
    decoration: BoxDecoration(
      color: AppColors.surfaceElevated,
      borderRadius: BorderRadius.circular(10),
      border: Border.all(color: AppColors.border),
    ),
    child: Text(
      label,
      style: const TextStyle(
        fontSize: 11.5,
        color: AppColors.textSecondary,
        fontWeight: FontWeight.w600,
      ),
    ),
  );

  Widget _preview({required BoxFit fit}) {
    final path = job['image_path'];
    if (path is String) {
      return Image.file(
        File(path),
        fit: fit,
        errorBuilder: (_, _, _) => const Center(
          child: Text(
            'Image preview unavailable',
            style: TextStyle(color: AppColors.textMuted),
          ),
        ),
      );
    }
    final imageUrl = job['image_url'];
    if (imageUrl is String) {
      return Image.network(
        '$api$imageUrl',
        fit: fit,
        errorBuilder: (_, _, _) => const Center(
          child: Text(
            'Image preview unavailable',
            style: TextStyle(color: AppColors.textMuted),
          ),
        ),
      );
    }
    return const Center(
      child: Text(
        'Image preview unavailable',
        style: TextStyle(color: AppColors.textMuted),
      ),
    );
  }
}
