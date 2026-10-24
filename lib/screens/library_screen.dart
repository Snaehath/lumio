import 'dart:io';
import 'package:flutter/material.dart';
import '../theme/app_theme.dart';

class LibraryScreen extends StatelessWidget {
  const LibraryScreen({
    required this.images,
    required this.totalCount,
    required this.filter,
    required this.api,
    required this.onFilterChanged,
    required this.onClearAll,
    required this.onCreate,
    required this.onOpenImage,
    super.key,
  });

  final List<Map<String, dynamic>> images;
  final int totalCount;
  final String filter;
  final String api;
  final ValueChanged<String> onFilterChanged;
  final VoidCallback onClearAll;
  final VoidCallback onCreate;
  final ValueChanged<Map<String, dynamic>> onOpenImage;

  @override
  Widget build(BuildContext context) => CustomScrollView(
    slivers: [
      SliverPadding(
        padding: const EdgeInsets.fromLTRB(22, 18, 22, 14),
        sliver: SliverList.list(
          children: [
            Row(
              children: [
                const Text(
                  'Your library',
                  style: TextStyle(
                    fontSize: 27,
                    fontWeight: FontWeight.w800,
                    letterSpacing: -.8,
                  ),
                ),
                const Spacer(),
                if (totalCount > 0)
                  TextButton(
                    onPressed: onClearAll,
                    child: const Text('Clear all'),
                  ),
              ],
            ),
            const SizedBox(height: 4),
            Text(
              '$totalCount ${totalCount == 1 ? 'image' : 'images'} saved on this phone',
              style: TextStyle(fontSize: 13, color: ink.withValues(alpha: .56)),
            ),
            if (totalCount > 0) ...[
              const SizedBox(height: 16),
              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(
                  children: [
                    for (final item in [
                      ('all', 'All'),
                      ('sana', 'SANA'),
                      ('moss', 'MOSS'),
                      ('fibo2', 'FIBO 2'),
                    ])
                      Padding(
                        padding: const EdgeInsets.only(right: 8),
                        child: ChoiceChip(
                          label: Text(item.$2),
                          selected: filter == item.$1,
                          onSelected: (_) => onFilterChanged(item.$1),
                          selectedColor: const Color(0xFFF0DFD8),
                        ),
                      ),
                  ],
                ),
              ),
            ],
          ],
        ),
      ),
      if (totalCount == 0)
        SliverFillRemaining(
          hasScrollBody: false,
          child: Center(
            child: Padding(
              padding: const EdgeInsets.all(32),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    Icons.collections_outlined,
                    size: 42,
                    color: ink.withValues(alpha: .38),
                  ),
                  const SizedBox(height: 12),
                  const Text(
                    'Your images will live here',
                    style: TextStyle(fontSize: 17, fontWeight: FontWeight.w700),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    'Create an image and it will be saved to this library.',
                    textAlign: TextAlign.center,
                    style: TextStyle(color: ink.withValues(alpha: .58)),
                  ),
                  const SizedBox(height: 16),
                  FilledButton.icon(
                    onPressed: onCreate,
                    icon: const Icon(Icons.auto_awesome_rounded),
                    label: const Text('Create an image'),
                  ),
                ],
              ),
            ),
          ),
        )
      else if (images.isEmpty)
        SliverFillRemaining(
          hasScrollBody: false,
          child: Center(
            child: Text(
              'No ${filter == 'fibo2' ? 'FIBO 2' : filter.toUpperCase()} images yet.',
              style: TextStyle(color: ink.withValues(alpha: .58)),
            ),
          ),
        )
      else
        SliverPadding(
          padding: const EdgeInsets.fromLTRB(18, 6, 18, 28),
          sliver: SliverGrid.builder(
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2,
              mainAxisSpacing: 12,
              crossAxisSpacing: 12,
              childAspectRatio: .72,
            ),
            itemCount: images.length,
            itemBuilder: (context, index) {
              final image = images[index];
              return Material(
                color: Colors.white,
                borderRadius: BorderRadius.circular(18),
                clipBehavior: Clip.antiAlias,
                child: InkWell(
                  onTap: () => onOpenImage(image),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        child: Stack(
                          fit: StackFit.expand,
                          children: [
                            _imageFor(image),
                            Positioned(
                              top: 8,
                              left: 8,
                              child: DecoratedBox(
                                decoration: BoxDecoration(
                                  color: Colors.black.withValues(alpha: .58),
                                  borderRadius: BorderRadius.circular(20),
                                ),
                                child: Padding(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 9,
                                    vertical: 5,
                                  ),
                                  child: Text(
                                    _modelName(
                                      image['model'] as String? ?? 'sana',
                                    ),
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontSize: 10,
                                      fontWeight: FontWeight.w700,
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      Padding(
                        padding: const EdgeInsets.fromLTRB(10, 9, 10, 10),
                        child: Text(
                          image['prompt'] as String? ?? 'Untitled image',
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
        ),
    ],
  );

  Widget _imageFor(Map<String, dynamic> image) {
    final path = image['image_path'];
    if (path is String) {
      return Image.file(
        File(path),
        fit: BoxFit.cover,
        errorBuilder: (_, _, _) => _imageFallback(),
      );
    }
    final url = image['image_url'];
    if (url is String) {
      return Image.network(
        '$api$url',
        fit: BoxFit.cover,
        errorBuilder: (_, _, _) => _imageFallback(),
      );
    }
    return _imageFallback();
  }

  Widget _imageFallback() => Container(
    color: const Color(0xFFE9E3DA),
    child: const Center(
      child: Icon(Icons.image_not_supported_outlined, color: accent),
    ),
  );

  String _modelName(String model) => switch (model) {
    'moss' => 'MOSS',
    'fibo2' => 'FIBO 2',
    _ => 'SANA',
  };
}
