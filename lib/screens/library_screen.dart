import 'dart:io';
import 'package:flutter/material.dart';
import '../models/ai_model.dart';
import '../theme/app_theme.dart';

class LibraryScreen extends StatefulWidget {
  const LibraryScreen({
    required this.images,
    required this.allHistory,
    required this.totalCount,
    required this.filter,
    required this.api,
    required this.onFilterChanged,
    required this.onClearAll,
    required this.onCreate,
    required this.onOpenImage,
    required this.onSaveImage,
    super.key,
  });

  final List<Map<String, dynamic>> images;
  final List<Map<String, dynamic>> allHistory;
  final int totalCount;
  final String filter;
  final String api;
  final ValueChanged<String> onFilterChanged;
  final VoidCallback onClearAll;
  final VoidCallback onCreate;
  final ValueChanged<Map<String, dynamic>> onOpenImage;
  final Future<void> Function(Map<String, dynamic>) onSaveImage;

  @override
  State<LibraryScreen> createState() => _LibraryScreenState();
}

class _LibraryScreenState extends State<LibraryScreen> {
  bool _searchOpen = false;
  final _searchController = TextEditingController();
  String _searchQuery = '';

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  String _formatStorage(List<Map<String, dynamic>> items) {
    var totalBytes = 0;
    for (final item in items) {
      final path = item['image_path'];
      if (path is String) {
        try {
          final file = File(path);
          if (file.existsSync()) {
            totalBytes += file.lengthSync();
          }
        } catch (_) {}
      }
    }
    if (totalBytes >= 1024 * 1024 * 1024) {
      return '${(totalBytes / (1024 * 1024 * 1024)).toStringAsFixed(1)} GB';
    }
    final mb = totalBytes / (1024 * 1024);
    return '${mb.toStringAsFixed(1)} MB';
  }

  int _countForModel(String modelId) {
    if (modelId == 'all') return widget.allHistory.length;
    return widget.allHistory.where((i) => i['model'] == modelId).length;
  }

  @override
  Widget build(BuildContext context) {
    final filteredImages = widget.images.where((item) {
      if (_searchQuery.isEmpty) return true;
      final prompt = (item['prompt'] as String? ?? '').toLowerCase();
      return prompt.contains(_searchQuery.toLowerCase());
    }).toList();

    final storageText = _formatStorage(widget.allHistory);

    return Scaffold(
      backgroundColor: AppColors.scaffoldBackground,
      body: SafeArea(
        child: CustomScrollView(
          slivers: [
            // Top Bar
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(20, 16, 20, 10),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        const Text(
                          'Library',
                          style: TextStyle(
                            fontSize: 28,
                            fontWeight: FontWeight.w800,
                            letterSpacing: -0.8,
                            color: AppColors.textPrimary,
                          ),
                        ),
                        const Spacer(),
                        IconButton(
                          icon: Icon(
                            _searchOpen ? Icons.close_rounded : Icons.search_rounded,
                            color: AppColors.textPrimary,
                            size: 24,
                          ),
                          onPressed: () {
                            setState(() {
                              _searchOpen = !_searchOpen;
                              if (!_searchOpen) {
                                _searchQuery = '';
                                _searchController.clear();
                              }
                            });
                          },
                        ),
                        IconButton(
                          icon: const Icon(
                            Icons.grid_view_rounded,
                            color: AppColors.textPrimary,
                            size: 22,
                          ),
                          onPressed: () {},
                        ),
                      ],
                    ),
                    const SizedBox(height: 2),
                    Text(
                      '${widget.totalCount} ${widget.totalCount == 1 ? 'image' : 'images'} • $storageText',
                      style: const TextStyle(
                        fontSize: 13,
                        color: AppColors.textSecondary,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    if (_searchOpen) ...[
                      const SizedBox(height: 12),
                      Container(
                        height: 44,
                        decoration: BoxDecoration(
                          color: AppColors.surfaceInput,
                          borderRadius: BorderRadius.circular(14),
                          border: Border.all(color: AppColors.border),
                        ),
                        child: TextField(
                          controller: _searchController,
                          autofocus: true,
                          style: const TextStyle(
                            color: AppColors.textPrimary,
                            fontSize: 14,
                          ),
                          onChanged: (val) => setState(() => _searchQuery = val),
                          decoration: const InputDecoration(
                            hintText: 'Search prompts…',
                            prefixIcon: Icon(
                              Icons.search_rounded,
                              size: 18,
                              color: AppColors.textMuted,
                            ),
                            contentPadding: EdgeInsets.symmetric(
                              horizontal: 12,
                              vertical: 10,
                            ),
                            border: InputBorder.none,
                            enabledBorder: InputBorder.none,
                            focusedBorder: InputBorder.none,
                          ),
                        ),
                      ),
                    ],
                    const SizedBox(height: 14),
                    // Filter Pills Row
                    SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      child: Row(
                        children: [
                          _buildFilterChip('all', 'All (${_countForModel('all')})'),
                          const SizedBox(width: 8),
                          _buildFilterChip('moss', 'MOSS (${_countForModel('moss')})'),
                          const SizedBox(width: 8),
                          _buildFilterChip('fibo2', 'Fibo2 (${_countForModel('fibo2')})'),
                          const SizedBox(width: 8),
                          _buildFilterChip('qwen_image', 'Qwen (${_countForModel('qwen_image')})'),
                          if (_countForModel('sana') > 0) ...[
                            const SizedBox(width: 8),
                            _buildFilterChip('sana', 'SANA (${_countForModel('sana')})'),
                          ],
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),

            // Content
            if (widget.totalCount == 0)
              SliverFillRemaining(
                hasScrollBody: false,
                child: Center(
                  child: Padding(
                    padding: const EdgeInsets.all(32),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Container(
                          width: 64,
                          height: 64,
                          decoration: BoxDecoration(
                            color: AppColors.surfaceElevated,
                            shape: BoxShape.circle,
                            border: Border.all(color: AppColors.border),
                          ),
                          child: const Icon(
                            Icons.photo_library_outlined,
                            size: 28,
                            color: AppColors.textMuted,
                          ),
                        ),
                        const SizedBox(height: 16),
                        const Text(
                          'Your images will live here',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.w700,
                            color: AppColors.textPrimary,
                          ),
                        ),
                        const SizedBox(height: 6),
                        const Text(
                          'Generate stunning images with ComfyUI and they will be saved here.',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            color: AppColors.textSecondary,
                            fontSize: 13.5,
                          ),
                        ),
                        const SizedBox(height: 20),
                        FilledButton.icon(
                          onPressed: widget.onCreate,
                          icon: const Icon(Icons.auto_awesome_rounded, size: 18),
                          label: const Text('Create an image'),
                          style: FilledButton.styleFrom(
                            backgroundColor: AppColors.accent,
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(
                              horizontal: 20,
                              vertical: 12,
                            ),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(16),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              )
            else if (filteredImages.isEmpty)
              SliverFillRemaining(
                hasScrollBody: false,
                child: Center(
                  child: Text(
                    _searchQuery.isNotEmpty
                        ? 'No images match "$_searchQuery"'
                        : 'No ${_filterName(widget.filter)} images yet.',
                    style: const TextStyle(
                      color: AppColors.textSecondary,
                      fontSize: 14,
                    ),
                  ),
                ),
              )
            else
              SliverPadding(
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 28),
                sliver: SliverGrid.builder(
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 2,
                    mainAxisSpacing: 12,
                    crossAxisSpacing: 12,
                    childAspectRatio: 0.72,
                  ),
                  itemCount: filteredImages.length,
                  itemBuilder: (context, index) {
                    final image = filteredImages[index];
                    return _buildImageCard(context, image);
                  },
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildFilterChip(String key, String label) {
    final selected = widget.filter == key;
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () => widget.onFilterChanged(key),
        borderRadius: BorderRadius.circular(20),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 150),
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
          decoration: BoxDecoration(
            color: selected ? AppColors.accent : AppColors.surfaceCard,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: selected ? AppColors.accent : AppColors.border,
            ),
            boxShadow: selected
                ? [
                    BoxShadow(
                      color: AppColors.accent.withValues(alpha: 0.25),
                      blurRadius: 8,
                      offset: const Offset(0, 2),
                    ),
                  ]
                : null,
          ),
          child: Text(
            label,
            style: TextStyle(
              fontSize: 13,
              fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
              color: selected ? Colors.white : AppColors.textSecondary,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildImageCard(BuildContext context, Map<String, dynamic> image) {
    return Material(
      color: AppColors.surfaceCard,
      borderRadius: BorderRadius.circular(18),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: () => widget.onOpenImage(image),
        child: Stack(
          fit: StackFit.expand,
          children: [
            // Hero image
            _imageFor(image),

            // Top gradient overlay for subtle depth
            Positioned(
              top: 0,
              left: 0,
              right: 0,
              height: 48,
              child: Container(
                decoration: const BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      Color(0x77000000),
                      Colors.transparent,
                    ],
                  ),
                ),
              ),
            ),

            // Model badge top-left
            Positioned(
              top: 8,
              left: 8,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: Colors.black.withValues(alpha: 0.6),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: Colors.white.withValues(alpha: 0.12),
                    width: 0.8,
                  ),
                ),
                child: Text(
                  AiModel.fromId(image['model'] as String? ?? 'moss').name,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 9.5,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ),

            // Bottom gradient overlay for prompt readability
            Positioned(
              bottom: 0,
              left: 0,
              right: 0,
              child: Container(
                padding: const EdgeInsets.fromLTRB(10, 24, 10, 10),
                decoration: const BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      Colors.transparent,
                      Color(0x99000000),
                      Color(0xDD000000),
                    ],
                  ),
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Expanded(
                      child: Text(
                        image['prompt'] as String? ?? 'Untitled',
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 11.5,
                          fontWeight: FontWeight.w600,
                          height: 1.3,
                        ),
                      ),
                    ),
                    const SizedBox(width: 6),
                    // Quick Download button overlay on bottom right
                    Material(
                      color: Colors.transparent,
                      child: InkWell(
                        onTap: () => widget.onSaveImage(image),
                        borderRadius: BorderRadius.circular(16),
                        child: Container(
                          width: 32,
                          height: 32,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: Colors.black.withValues(alpha: 0.65),
                            border: Border.all(
                              color: Colors.white.withValues(alpha: 0.2),
                              width: 0.8,
                            ),
                          ),
                          child: const Icon(
                            Icons.download_rounded,
                            size: 16,
                            color: Colors.white,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _imageFor(Map<String, dynamic> image) {
    final path = image['image_path'];
    if (path is String) {
      return Image.file(
        File(path),
        fit: BoxFit.cover,
        errorBuilder: (_, _, _) => _fallbackImage(),
      );
    }
    final url = image['image_url'];
    if (url is String) {
      return Image.network(
        '${widget.api}$url',
        fit: BoxFit.cover,
        errorBuilder: (_, _, _) => _fallbackImage(),
      );
    }
    return _fallbackImage();
  }

  Widget _fallbackImage() {
    return Container(
      color: AppColors.surfaceElevated,
      child: const Center(
        child: Icon(
          Icons.image_not_supported_outlined,
          color: AppColors.textMuted,
          size: 28,
        ),
      ),
    );
  }

  String _filterName(String filter) => switch (filter) {
    'moss' => 'MOSS',
    'fibo2' => 'Fibo2',
    'qwen_image' => 'Qwen',
    'sana' => 'SANA',
    _ => 'All',
  };
}
