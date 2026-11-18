class AiModel {
  final String id;
  final String name;
  final String subtitle;
  final bool hasLora;
  final int defaultSteps;
  final List<int> supportedSteps;
  final String description;
  final String workflowBackend;

  const AiModel({
    required this.id,
    required this.name,
    required this.subtitle,
    required this.hasLora,
    required this.defaultSteps,
    required this.supportedSteps,
    required this.description,
    required this.workflowBackend,
  });

  // Exactly matching D:\DevelopmentSide\AI-projects\sana-ai-image\api.py:
  // - moss: UNET moss_image_sft_int8_convrot.safetensors, CLIP qwen3.5_9b_w4a8_gptq, VAE flux2-vae_small
  //         8 steps -> moss_dnd_8step_lora.safetensors, cfg 1.0, euler sampler
  //         25 steps -> base model, cfg 2.5, er_sde sampler
  static const moss = AiModel(
    id: 'moss',
    name: 'MOSS-Image',
    subtitle: 'Fast • 8 Steps',
    hasLora: true,
    defaultSteps: 8,
    supportedSteps: [8, 25],
    description: 'Steps are set automatically based on the selected model (LoRA optimized models use 8 steps).',
    workflowBackend: 'ComfyUI (moss_dnd_8step_lora)',
  );

  // - fibo2: UNET fibo2_dev_int8_convrot.safetensors, CLIP qwen3vl_4b_int8_convrot, TextEncodeFibo2, VAE flux2-vae
  //          steps: 25, cfg 8.0, euler sampler (no LoRA)
  static const fibo2 = AiModel(
    id: 'fibo2',
    name: 'FIBO 2.0',
    subtitle: 'High Quality • 25 Steps',
    hasLora: false,
    defaultSteps: 25,
    supportedSteps: [25],
    description: 'Standard 25 steps for high quality generation on ComfyUI.',
    workflowBackend: 'ComfyUI (fibo2_dev_int8)',
  );

  // - qwen_image: UNET qwen_image_2.1_int8_convrot.safetensors, CLIP qwen3vl_8b_int8_convrot, TextEncodeQwenImage21, VAE qwen_image_2.1_vae_bf16
  //               steps: 25, cfg 1.0, euler sampler (no LoRA)
  static const qwenImage = AiModel(
    id: 'qwen_image',
    name: 'Qwen Image',
    subtitle: 'Versatile • 25 Steps',
    hasLora: false,
    defaultSteps: 25,
    supportedSteps: [25],
    description: 'Versatile 25-step generation on ComfyUI.',
    workflowBackend: 'ComfyUI (qwen_image_2.1)',
  );

  // - sana: SANA 1.5 1.6B local pipeline (20, 30 steps)
  static const sana = AiModel(
    id: 'sana',
    name: 'SANA',
    subtitle: 'Local Diffusers • 30 Steps',
    hasLora: false,
    defaultSteps: 30,
    supportedSteps: [20, 30],
    description: 'Direct SANA 1.5 local pipeline.',
    workflowBackend: 'Local PyTorch Pipeline',
  );

  static const List<AiModel> all = [moss, fibo2, qwenImage];

  static AiModel fromId(String id) {
    return all.firstWhere(
      (m) => m.id == id,
      orElse: () => id == 'sana' ? sana : moss,
    );
  }
}
