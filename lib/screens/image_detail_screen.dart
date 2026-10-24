import 'dart:io';
import 'package:flutter/material.dart';
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
    final model = switch (job['model']) {
      'moss' => 'MOSS',
      'fibo2' => 'FIBO 2.0',
      _ => 'SANA',
    };
    final width = job['width'] ?? '?';
    final height = job['height'] ?? '?';
    final prompt = job['prompt'] as String? ?? 'Untitled image';

    return Scaffold(
      backgroundColor: const Color(0xFF191715),
      appBar: AppBar(
        backgroundColor: const Color(0xFF191715),
        foregroundColor: Colors.white,
        title: Text(model),
        actions: [
          IconButton(
            tooltip: 'Delete image',
            icon: const Icon(Icons.delete_outline_rounded),
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
              child: SizedBox.expand(child: _preview(fit: BoxFit.contain)),
            ),
          ),
          Container(
            width: double.infinity,
            color: paper,
            child: SafeArea(
              top: false,
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxHeight: 280),
                child: SingleChildScrollView(
                  padding: const EdgeInsets.fromLTRB(20, 18, 20, 14),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        prompt,
                        maxLines: 4,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          fontSize: 15,
                          height: 1.4,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: 12),
                      Wrap(
                        spacing: 7,
                        runSpacing: 7,
                        children: [
                          _detailChip('$width × $height'),
                          _detailChip('${job['steps'] ?? '?'} steps'),
                          _detailChip(
                            (job['aspect_ratio'] as String? ?? 'square')
                                .toUpperCase(),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      Row(
                        children: [
                          Expanded(
                            child: FilledButton.icon(
                              onPressed: onSave,
                              icon: const Icon(Icons.download_rounded),
                              label: const Text('Save image'),
                              style: FilledButton.styleFrom(
                                minimumSize: const Size.fromHeight(48),
                                backgroundColor: ink,
                                foregroundColor: Colors.white,
                              ),
                            ),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: OutlinedButton.icon(
                              onPressed: () {
                                onReuse();
                                Navigator.pop(context);
                              },
                              icon: const Icon(Icons.replay_rounded),
                              label: const Text('Reuse prompt'),
                              style: OutlinedButton.styleFrom(
                                minimumSize: const Size.fromHeight(48),
                                foregroundColor: ink,
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
          ),
        ],
      ),
    );
  }

  Widget _preview({required BoxFit fit}) {
    final path = job['image_path'];
    if (path is String) {
      return Image.file(
        File(path),
        fit: fit,
        errorBuilder: (_, _, _) => const Center(
          child: Text(
            'Image preview unavailable',
            style: TextStyle(color: Colors.white70),
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
            style: TextStyle(color: Colors.white70),
          ),
        ),
      );
    }
    return const Center(
      child: Text(
        'Image preview unavailable',
        style: TextStyle(color: Colors.white70),
      ),
    );
  }

  Widget _detailChip(String label) => Chip(
    visualDensity: VisualDensity.compact,
    backgroundColor: Colors.white,
    side: BorderSide.none,
    label: Text(
      label,
      style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600),
    ),
  );
}
