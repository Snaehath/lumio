import 'package:flutter/material.dart';
import '../data/prompt_templates.dart';
import '../models/prompt_template.dart';
import '../theme/app_theme.dart';
import '../widgets/choice_pill.dart';
import '../widgets/step_progress.dart';
import '../widgets/template_card.dart';

class CreateScreen extends StatelessWidget {
  const CreateScreen({
    required this.promptController,
    required this.serverController,
    required this.model,
    required this.ratio,
    required this.steps,
    required this.completedSteps,
    required this.totalSteps,
    required this.statusMessage,
    required this.busy,
    required this.editingServer,
    required this.checkingServer,
    required this.serverOnline,
    required this.comfyOnline,
    required this.error,
    required this.onCheckServer,
    required this.onToggleSettings,
    required this.onSaveServer,
    required this.onCreate,
    required this.onTemplateSelected,
    required this.onModelChanged,
    required this.onRatioChanged,
    required this.onStepsChanged,
    super.key,
  });

  final TextEditingController promptController;
  final TextEditingController serverController;
  final String model;
  final String ratio;
  final int steps;
  final int completedSteps;
  final int totalSteps;
  final String statusMessage;
  final bool busy;
  final bool editingServer;
  final bool checkingServer;
  final bool? serverOnline;
  final bool? comfyOnline;
  final String? error;
  final VoidCallback onCheckServer;
  final VoidCallback onToggleSettings;
  final VoidCallback onSaveServer;
  final VoidCallback onCreate;
  final ValueChanged<PromptTemplate> onTemplateSelected;
  final ValueChanged<String> onModelChanged;
  final ValueChanged<String> onRatioChanged;
  final ValueChanged<int> onStepsChanged;

  @override
  Widget build(BuildContext context) => CustomScrollView(
    slivers: [
      SliverPadding(
        padding: const EdgeInsets.fromLTRB(22, 10, 22, 28),
        sliver: SliverList.list(
          children: [
            Row(
              children: [
                Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: ink,
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: const Icon(
                    Icons.auto_awesome_rounded,
                    color: Colors.white,
                    size: 21,
                  ),
                ),
                const SizedBox(width: 11),
                const Text(
                  'lumio',
                  style: TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.w800,
                    letterSpacing: -1,
                  ),
                ),
                const Spacer(),
                InkWell(
                  onTap: onCheckServer,
                  borderRadius: BorderRadius.circular(20),
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 7,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          Icons.circle,
                          size: 8,
                          color: checkingServer
                              ? Colors.amber
                              : serverOnline != true ||
                                    (model != 'sana' && comfyOnline == false)
                              ? accent
                              : const Color(0xFF4A8D67),
                        ),
                        const SizedBox(width: 6),
                        Text(
                          checkingServer
                              ? 'Checking'
                              : serverOnline != true
                              ? 'API offline'
                              : model != 'sana' && comfyOnline != null
                              ? comfyOnline!
                                    ? 'ComfyUI online'
                                    : 'ComfyUI offline'
                              : 'API online',
                          style: const TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                IconButton.filledTonal(
                  tooltip: 'Server settings',
                  onPressed: onToggleSettings,
                  icon: Icon(
                    editingServer ? Icons.close_rounded : Icons.tune_rounded,
                  ),
                ),
              ],
            ),
            if (editingServer) ...[
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(18),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Connect to your PC',
                      style: TextStyle(fontWeight: FontWeight.w700),
                    ),
                    const SizedBox(height: 9),
                    TextField(
                      controller: serverController,
                      keyboardType: TextInputType.url,
                      decoration: const InputDecoration(
                        labelText: 'Server address',
                        hintText: 'http://192.168.1.20:8000',
                      ),
                    ),
                    const SizedBox(height: 9),
                    Align(
                      alignment: Alignment.centerRight,
                      child: FilledButton(
                        onPressed: onSaveServer,
                        child: const Text('Save address'),
                      ),
                    ),
                  ],
                ),
              ),
            ],
            const SizedBox(height: 22),
            Container(
              padding: const EdgeInsets.fromLTRB(20, 20, 18, 18),
              decoration: BoxDecoration(
                color: ink,
                borderRadius: BorderRadius.circular(26),
                gradient: const LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [Color(0xFF292522), Color(0xFF171514)],
                ),
              ),
              child: Stack(
                children: [
                  Positioned(
                    right: 8,
                    top: 2,
                    child: Icon(
                      Icons.auto_awesome_rounded,
                      size: 74,
                      color: Colors.white.withValues(alpha: .07),
                    ),
                  ),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(
                            Icons.circle,
                            size: 7,
                            color: Color(0xFFE9A27E),
                          ),
                          const SizedBox(width: 7),
                          Text(
                            'YOUR CREATIVE STUDIO',
                            style: TextStyle(
                              fontSize: 10,
                              fontWeight: FontWeight.w800,
                              letterSpacing: 1.35,
                              color: Colors.white.withValues(alpha: .72),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 18),
                      const Text(
                        'Your next idea,\nbeautifully made.',
                        style: TextStyle(
                          fontSize: 31,
                          height: 1.08,
                          fontWeight: FontWeight.w700,
                          letterSpacing: -1.25,
                          color: Colors.white,
                        ),
                      ),
                      const SizedBox(height: 10),
                      Text(
                        'Describe a scene. Make it yours.',
                        style: TextStyle(
                          color: Colors.white.withValues(alpha: .68),
                          fontSize: 14,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 25),
            Row(
              children: [
                _sectionLabel('QUICK PROMPTS'),
                const Spacer(),
                Text(
                  'Tap to try',
                  style: TextStyle(
                    fontSize: 12,
                    color: ink.withValues(alpha: .52),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
            SizedBox(
              height: 94,
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                itemCount: promptTemplates.length,
                separatorBuilder: (_, _) => const SizedBox(width: 9),
                itemBuilder: (context, index) {
                  final template = promptTemplates[index];
                  return TemplateCard(
                    title: template.title,
                    tag: template.tag,
                    icon: template.icon,
                    onTap: () {
                      onTemplateSelected(template);
                      FocusScope.of(context).unfocus();
                    },
                  );
                },
              ),
            ),
            const SizedBox(height: 23),
            _sectionLabel('DESCRIBE YOUR IMAGE'),
            const SizedBox(height: 10),
            TextField(
              controller: promptController,
              minLines: 4,
              maxLines: 7,
              maxLength: 2000,
              textCapitalization: TextCapitalization.sentences,
              decoration: const InputDecoration(
                hintText:
                    'A tiny glass greenhouse on a rainy rooftop at blue hour, warm lights glowing inside…',
                hintMaxLines: 3,
                contentPadding: EdgeInsets.all(18),
                counterText: '',
              ),
            ),
            const SizedBox(height: 22),
            _sectionLabel('MODEL'),
            const SizedBox(height: 10),
            SegmentedButton<String>(
              segments: const [
                ButtonSegment(value: 'sana', label: Text('SANA')),
                ButtonSegment(value: 'moss', label: Text('MOSS')),
                ButtonSegment(value: 'fibo2', label: Text('FIBO 2')),
              ],
              selected: {model},
              onSelectionChanged: busy
                  ? null
                  : (selection) => onModelChanged(selection.first),
              showSelectedIcon: false,
            ),
            const SizedBox(height: 6),
            Text(
              model == 'moss'
                  ? '8 steps uses your LoRA. 25 and 50 steps use the base model.'
                  : model == 'fibo2'
                  ? 'FIBO 2.0 runs in ComfyUI at 25 steps.'
                  : 'SANA runs directly in the local API.',
              style: TextStyle(fontSize: 12, color: ink.withValues(alpha: .58)),
            ),
            const SizedBox(height: 22),
            _sectionLabel('CANVAS'),
            const SizedBox(height: 10),
            Row(
              children: [
                for (final item in [
                  ('portrait', 'Portrait', Icons.crop_portrait_rounded),
                  ('square', 'Square', Icons.crop_square_rounded),
                  ('landscape', 'Landscape', Icons.crop_landscape_rounded),
                ])
                  Expanded(
                    child: Padding(
                      padding: const EdgeInsets.only(right: 8),
                      child: ChoicePill(
                        selected: ratio == item.$1,
                        label: item.$2,
                        icon: item.$3,
                        onTap: busy ? () {} : () => onRatioChanged(item.$1),
                      ),
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 22),
            Row(
              children: [
                _sectionLabel('DETAIL'),
                const Spacer(),
                Text(
                  model == 'fibo2'
                      ? '25 steps'
                      : model == 'moss'
                      ? (steps == 8
                            ? 'Fast LoRA'
                            : steps == 50
                            ? 'Fine detail'
                            : 'Balanced')
                      : (steps == 30 ? 'Fine detail' : 'Balanced'),
                  style: const TextStyle(
                    fontWeight: FontWeight.w700,
                    color: accent,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            if (model != 'fibo2')
              SegmentedButton<int>(
                segments: model == 'moss'
                    ? const [
                        ButtonSegment(
                          value: 8,
                          label: Text('8 steps'),
                          icon: Icon(Icons.bolt_rounded),
                        ),
                        ButtonSegment(
                          value: 25,
                          label: Text('25 steps'),
                          icon: Icon(Icons.auto_awesome_rounded),
                        ),
                        ButtonSegment(value: 50, label: Text('50 steps')),
                      ]
                    : const [
                        ButtonSegment(
                          value: 20,
                          label: Text('20 steps'),
                          icon: Icon(Icons.bolt_rounded),
                        ),
                        ButtonSegment(
                          value: 30,
                          label: Text('30 steps'),
                          icon: Icon(Icons.auto_awesome_rounded),
                        ),
                      ],
                selected: {steps},
                onSelectionChanged: busy
                    ? null
                    : (selection) => onStepsChanged(selection.first),
                showSelectedIcon: false,
              ),
            const SizedBox(height: 20),
            if (error != null) ...[
              Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: const Color(0xFFFFE8E2),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Text(
                  error!,
                  style: const TextStyle(color: Color(0xFF873C2A)),
                ),
              ),
              const SizedBox(height: 12),
            ],
            FilledButton.icon(
              onPressed: busy ? null : onCreate,
              icon: busy
                  ? const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: Colors.white,
                      ),
                    )
                  : const Icon(Icons.auto_awesome_rounded),
              label: Text(busy ? statusMessage : 'Create image'),
              style: FilledButton.styleFrom(
                minimumSize: const Size.fromHeight(58),
                backgroundColor: ink,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(18),
                ),
                textStyle: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
            if (busy && model != 'sana') ...[
              const SizedBox(height: 14),
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: ink.withValues(alpha: .06)),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        const SizedBox(
                          width: 28,
                          height: 28,
                          child: CircularProgressIndicator(
                            strokeWidth: 2.5,
                            color: accent,
                          ),
                        ),
                        const SizedBox(width: 13),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                statusMessage,
                                style: const TextStyle(
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                              const SizedBox(height: 3),
                              Text(
                                model == 'moss'
                                    ? 'MOSS can take a few minutes. Keep Lumio open.'
                                    : 'FIBO 2.0 can take a few minutes. Keep Lumio open.',
                                style: TextStyle(
                                  fontSize: 12,
                                  color: ink.withValues(alpha: .58),
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: StepProgress(
                            completed: completedSteps,
                            total: totalSteps,
                            compact: true,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
            if (busy && model == 'sana') ...[
              const SizedBox(height: 14),
              StepProgress(completed: completedSteps, total: totalSteps),
            ],
          ],
        ),
      ),
    ],
  );

  Widget _sectionLabel(String value) => Text(
    value,
    style: TextStyle(
      fontSize: 11,
      fontWeight: FontWeight.w800,
      letterSpacing: 1.15,
      color: ink.withValues(alpha: .58),
    ),
  );
}
