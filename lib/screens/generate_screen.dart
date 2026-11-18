import 'package:flutter/material.dart';
import '../data/prompt_templates.dart';
import '../models/ai_model.dart';
import '../models/generation_controller.dart';
import '../models/prompt_template.dart';
import '../theme/app_theme.dart';
import '../widgets/aspect_box.dart';
import '../widgets/diffusion_matrix_loader.dart';
import '../widgets/model_art.dart';
import '../widgets/model_card.dart';
import '../widgets/step_progress.dart';

class GenerateScreen extends StatefulWidget {
  const GenerateScreen({
    required this.promptController,
    required this.modelId,
    required this.ratio,
    required this.steps,
    required this.generationController,
    required this.onModelChanged,
    required this.onRatioChanged,
    required this.onStepsChanged,
    required this.onGenerate,
    required this.onTemplateSelected,
    super.key,
  });

  final TextEditingController promptController;
  final String modelId;
  final String ratio;
  final int steps;
  final GenerationController generationController;
  final ValueChanged<String> onModelChanged;
  final ValueChanged<String> onRatioChanged;
  final ValueChanged<int> onStepsChanged;
  final VoidCallback onGenerate;
  final ValueChanged<PromptTemplate> onTemplateSelected;

  @override
  State<GenerateScreen> createState() => _GenerateScreenState();
}

class _GenerateScreenState extends State<GenerateScreen> {
  late String _selectedRatio;
  late int _selectedSteps;
  late String _selectedModelId;

  @override
  void initState() {
    super.initState();
    _selectedRatio = widget.ratio;
    _selectedSteps = widget.steps;
    _selectedModelId = widget.modelId;
    widget.promptController.addListener(_onPromptChanged);
    widget.generationController.addListener(_onGenerationStateChanged);
  }

  @override
  void didUpdateWidget(covariant GenerateScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.ratio != oldWidget.ratio && widget.ratio != _selectedRatio) {
      _selectedRatio = widget.ratio;
    }
    if (widget.steps != oldWidget.steps && widget.steps != _selectedSteps) {
      _selectedSteps = widget.steps;
    }
    if (widget.modelId != oldWidget.modelId && widget.modelId != _selectedModelId) {
      _selectedModelId = widget.modelId;
    }
  }

  @override
  void dispose() {
    widget.promptController.removeListener(_onPromptChanged);
    widget.generationController.removeListener(_onGenerationStateChanged);
    super.dispose();
  }

  void _onPromptChanged() {
    if (mounted) setState(() {});
  }

  void _onGenerationStateChanged() {
    if (mounted) setState(() {});
  }

  void _selectRatio(String newRatio) {
    if (widget.generationController.busy) return;
    setState(() => _selectedRatio = newRatio);
    widget.onRatioChanged(newRatio);
  }

  void _selectSteps(int newSteps) {
    if (widget.generationController.busy) return;
    setState(() => _selectedSteps = newSteps);
    widget.onStepsChanged(newSteps);
  }

  void _selectModel(String newModelId) {
    final ai = AiModel.fromId(newModelId);
    setState(() {
      _selectedModelId = newModelId;
      if (!ai.hasLora) {
        _selectedSteps = ai.defaultSteps;
        widget.onStepsChanged(ai.defaultSteps);
      }
    });
    widget.onModelChanged(newModelId);
  }

  void _showModelPicker(BuildContext context) {
    showModalBottomSheet<void>(
      context: context,
      backgroundColor: AppColors.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Center(
                  child: Container(
                    width: 36,
                    height: 4,
                    decoration: BoxDecoration(
                      color: AppColors.borderLight,
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ),
                const SizedBox(height: 18),
                const Text(
                  'Select Model',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                    color: AppColors.textPrimary,
                  ),
                ),
                const SizedBox(height: 16),
                for (final item in AiModel.all) ...[
                  ModelCard(
                    model: item,
                    selected: _selectedModelId == item.id,
                    onTap: () {
                      _selectModel(item.id);
                      Navigator.pop(ctx);
                    },
                  ),
                  const SizedBox(height: 10),
                ],
              ],
            ),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final currentModel = AiModel.fromId(_selectedModelId);
    final promptLength = widget.promptController.text.length;
    final isBusy = widget.generationController.busy;
    final statusMsg = widget.generationController.statusMessage;
    final completedSteps = widget.generationController.completedSteps;
    final totalSteps = widget.generationController.totalSteps > 0
        ? widget.generationController.totalSteps
        : _selectedSteps;
    final error = widget.generationController.error;

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
          onPressed: () => Navigator.maybePop(context),
        ),
        title: const Text(
          'Generate',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w700,
            color: AppColors.textPrimary,
          ),
        ),
        centerTitle: true,
      ),
      body: Stack(
        children: [
          // Bottom subtle warm glow
          Positioned(
            left: 0,
            right: 0,
            bottom: 0,
            height: 140,
            child: IgnorePointer(
              child: Container(
                decoration: BoxDecoration(
                  gradient: RadialGradient(
                    center: const Alignment(0.0, 1.3),
                    radius: 1.1,
                    colors: [
                      AppColors.accent.withValues(alpha: 0.18),
                      Colors.transparent,
                    ],
                  ),
                ),
              ),
            ),
          ),
          SafeArea(
            child: SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(20, 8, 20, 24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Model Selector Dropdown Card
                  Material(
                    color: Colors.transparent,
                    child: InkWell(
                      onTap: isBusy ? null : () => _showModelPicker(context),
                      borderRadius: BorderRadius.circular(16),
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 14,
                          vertical: 11,
                        ),
                        decoration: BoxDecoration(
                          color: AppColors.surfaceCard,
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(color: AppColors.border),
                        ),
                        child: Row(
                          children: [
                            ModelThumbnail(
                              modelId: currentModel.id,
                              width: 40,
                              height: 40,
                              borderRadius: 10,
                            ),
                            const SizedBox(width: 12),
                            Text(
                              currentModel.name,
                              style: const TextStyle(
                                fontSize: 15,
                                fontWeight: FontWeight.w700,
                                color: AppColors.textPrimary,
                              ),
                            ),
                            if (currentModel.hasLora) ...[
                              const SizedBox(width: 8),
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 7,
                                  vertical: 2,
                                ),
                                decoration: BoxDecoration(
                                  color: AppColors.amberBadgeBg,
                                  borderRadius: BorderRadius.circular(16),
                                  border: Border.all(
                                    color: AppColors.amberBadgeBorder,
                                    width: 0.8,
                                  ),
                                ),
                                child: const Text(
                                  'LoRA',
                                  style: TextStyle(
                                    fontSize: 10,
                                    fontWeight: FontWeight.w800,
                                    color: AppColors.amberBadgeText,
                                  ),
                                ),
                              ),
                            ],
                            const Spacer(),
                            const Icon(
                              Icons.keyboard_arrow_down_rounded,
                              color: AppColors.textSecondary,
                              size: 22,
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),

                  const SizedBox(height: 22),

                  // Prompt Section
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        'Prompt',
                        style: TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w700,
                          color: AppColors.textPrimary,
                        ),
                      ),
                      Text(
                        '$promptLength / 1000',
                        style: const TextStyle(
                          fontSize: 12,
                          color: AppColors.textMuted,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 9),
                  Container(
                    decoration: BoxDecoration(
                      color: AppColors.surfaceInput,
                      borderRadius: BorderRadius.circular(18),
                      border: Border.all(color: AppColors.border),
                    ),
                    child: TextField(
                      controller: widget.promptController,
                      enabled: !isBusy,
                      minLines: 4,
                      maxLines: 7,
                      maxLength: 1000,
                      style: const TextStyle(
                        fontSize: 14,
                        height: 1.45,
                        color: AppColors.textPrimary,
                      ),
                      decoration: const InputDecoration(
                        hintText:
                            'A serene coastal house carved into a cliff, soft morning light, cinematic, high detail…',
                        counterText: '',
                        border: InputBorder.none,
                        enabledBorder: InputBorder.none,
                        focusedBorder: InputBorder.none,
                        contentPadding: EdgeInsets.all(16),
                      ),
                    ),
                  ),

                  // Prompt templates quick row
                  const SizedBox(height: 12),
                  SizedBox(
                    height: 34,
                    child: ListView.separated(
                      scrollDirection: Axis.horizontal,
                      itemCount: promptTemplates.length,
                      separatorBuilder: (_, _) => const SizedBox(width: 8),
                      itemBuilder: (ctx, idx) {
                        final t = promptTemplates[idx];
                        return Material(
                          color: Colors.transparent,
                          child: InkWell(
                            onTap: isBusy
                                ? null
                                : () {
                                    widget.onTemplateSelected(t);
                                    final newRatio = t.ratio == 'portrait'
                                        ? '9:16'
                                        : t.ratio == 'landscape'
                                            ? '16:9'
                                            : '1:1';
                                    setState(() => _selectedRatio = newRatio);
                                  },
                            borderRadius: BorderRadius.circular(20),
                            child: Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 12,
                                vertical: 6,
                              ),
                              decoration: BoxDecoration(
                                color: AppColors.surfaceCard,
                                borderRadius: BorderRadius.circular(20),
                                border: Border.all(color: AppColors.border),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(t.icon, size: 14, color: AppColors.accentLight),
                                  const SizedBox(width: 6),
                                  Text(
                                    t.title,
                                    style: const TextStyle(
                                      fontSize: 12,
                                      fontWeight: FontWeight.w600,
                                      color: AppColors.textSecondary,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        );
                      },
                    ),
                  ),

                  const SizedBox(height: 24),

                  // Steps Section
                  const Text(
                    'Steps',
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w700,
                      color: AppColors.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 10),
                  Row(
                    children: [
                      if (currentModel.hasLora) ...[
                        Expanded(
                          child: _StepPill(
                            label: '8 (Optimized)',
                            selected: _selectedSteps == 8,
                            onTap: isBusy ? () {} : () => _selectSteps(8),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: _StepPill(
                            label: '25 (Quality)',
                            selected: _selectedSteps == 25,
                            onTap: isBusy ? () {} : () => _selectSteps(25),
                          ),
                        ),
                      ] else ...[
                        Expanded(
                          child: _StepPill(
                            label: '${currentModel.defaultSteps} (Quality)',
                            selected: true,
                            onTap: () {},
                          ),
                        ),
                      ],
                    ],
                  ),
                  const SizedBox(height: 8),
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Icon(
                        Icons.info_outline_rounded,
                        size: 14,
                        color: AppColors.textMuted,
                      ),
                      const SizedBox(width: 6),
                      Expanded(
                        child: Text(
                          currentModel.hasLora
                              ? 'Steps are set automatically based on the selected model (LoRA optimized models use 8 steps).'
                              : 'Standard ${currentModel.defaultSteps} steps for high-quality generation on ComfyUI.',
                          style: const TextStyle(
                            fontSize: 11.5,
                            color: AppColors.textMuted,
                            height: 1.35,
                          ),
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 24),

                  // Aspect Ratio Section
                  const Text(
                    'Aspect Ratio',
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w700,
                      color: AppColors.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 10),
                  Row(
                    children: [
                      AspectBox(
                        ratioKey: '1:1',
                        label: '1:1',
                        selected: _selectedRatio == '1:1' || _selectedRatio == 'square',
                        onTap: () => _selectRatio('1:1'),
                      ),
                      const SizedBox(width: 10),
                      AspectBox(
                        ratioKey: '3:2',
                        label: '3:2',
                        selected: _selectedRatio == '3:2',
                        onTap: () => _selectRatio('3:2'),
                      ),
                      const SizedBox(width: 10),
                      AspectBox(
                        ratioKey: '9:16',
                        label: '9:16',
                        selected: _selectedRatio == '9:16' || _selectedRatio == 'portrait',
                        onTap: () => _selectRatio('9:16'),
                      ),
                      const SizedBox(width: 10),
                      AspectBox(
                        ratioKey: '16:9',
                        label: '16:9',
                        selected: _selectedRatio == '16:9' || _selectedRatio == 'landscape',
                        onTap: () => _selectRatio('16:9'),
                      ),
                    ],
                  ),

                  const SizedBox(height: 28),

                  if (error != null) ...[
                    Container(
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        color: const Color(0xFF2E1512),
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(color: const Color(0xFF6E281F)),
                      ),
                      child: Row(
                        children: [
                          const Icon(
                            Icons.error_outline_rounded,
                            color: Color(0xFFFF6B6B),
                            size: 20,
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Text(
                              error,
                              style: const TextStyle(
                                color: Color(0xFFFFCCCC),
                                fontSize: 13,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),
                  ],

                  // Action Button
                  Material(
                    color: Colors.transparent,
                    child: InkWell(
                      onTap: isBusy ? null : widget.onGenerate,
                      borderRadius: BorderRadius.circular(28),
                      child: Ink(
                        height: 56,
                        decoration: BoxDecoration(
                          gradient: isBusy
                              ? const LinearGradient(
                                  colors: [Color(0xFF8A3D00), Color(0xFF7A2900)],
                                )
                              : AppColors.accentGradient,
                          borderRadius: BorderRadius.circular(28),
                          boxShadow: [
                            BoxShadow(
                              color: AppColors.accent.withValues(alpha: isBusy ? 0.15 : 0.35),
                              blurRadius: 18,
                              offset: const Offset(0, 6),
                            ),
                          ],
                        ),
                        child: Center(
                          child: isBusy
                              ? Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    const SizedBox(
                                      width: 20,
                                      height: 20,
                                      child: CircularProgressIndicator(
                                        strokeWidth: 2.5,
                                        color: Colors.white,
                                      ),
                                    ),
                                    const SizedBox(width: 12),
                                    Flexible(
                                      child: Text(
                                        statusMsg,
                                        style: const TextStyle(
                                          color: Colors.white,
                                          fontSize: 14.5,
                                          fontWeight: FontWeight.w700,
                                        ),
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    ),
                                  ],
                                )
                              : const Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Icon(
                                      Icons.auto_awesome_rounded,
                                      color: Colors.white,
                                      size: 20,
                                    ),
                                    SizedBox(width: 8),
                                    Text(
                                      'Generate Image',
                                      style: TextStyle(
                                        color: Colors.white,
                                        fontSize: 16,
                                        fontWeight: FontWeight.w700,
                                      ),
                                    ),
                                  ],
                                ),
                        ),
                      ),
                    ),
                  ),

                  // ChatGPT / DALL-E style dot-matrix diffusion canvas loader
                  if (isBusy) ...[
                    const SizedBox(height: 24),
                    DiffusionMatrixLoader(
                      progress: totalSteps > 0
                          ? (completedSteps / totalSteps).clamp(0.0, 1.0)
                          : 0.05,
                      statusMessage: statusMsg,
                      ratio: _selectedRatio,
                      height: 270,
                    ),
                    const SizedBox(height: 16),
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: AppColors.surfaceCard,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: AppColors.border),
                      ),
                      child: StepProgress(
                        completed: completedSteps,
                        total: totalSteps,
                      ),
                    ),
                  ],

                  const SizedBox(height: 24),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _StepPill extends StatelessWidget {
  const _StepPill({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(24),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 180),
          padding: const EdgeInsets.symmetric(vertical: 13),
          decoration: BoxDecoration(
            color: selected ? AppColors.accent : AppColors.surfaceCard,
            borderRadius: BorderRadius.circular(24),
            border: Border.all(
              color: selected ? AppColors.accent : AppColors.border,
            ),
            boxShadow: selected
                ? [
                    BoxShadow(
                      color: AppColors.accent.withValues(alpha: 0.25),
                      blurRadius: 10,
                      offset: const Offset(0, 3),
                    ),
                  ]
                : null,
          ),
          child: Center(
            child: Text(
              label,
              style: TextStyle(
                fontSize: 13.5,
                fontWeight: FontWeight.w700,
                color: selected ? Colors.white : AppColors.textSecondary,
              ),
            ),
          ),
        ),
      ),
    );
  }
}
