# Lumio

**Lumio** is a mobile AI image creation studio built with Flutter. It connects directly to your local ComfyUI workflow server via a lightweight FastAPI bridge, giving you high-performance on-device image generation with local hardware acceleration.

---

## ✨ Features

- **Local AI Workflows (ComfyUI & Diffusers)**:
  - **MOSS-Image**: Ultra-fast **8-step LoRA** generation (`moss_dnd_8step_lora`) or 25-step standard mode.
  - **FIBO 2.0**: High-detail 25-step image synthesis.
  - **Qwen Image**: Versatile 25-step generation.
- **ChatGPT-Style Dot-Matrix Diffusion Loader**:
  - Live animated 24×24 particle grid simulating latent diffusion waves in real-time.
  - Floating progress capsule with live percentage (`x%`) and current step tracking (`Step 3 of 8`).
  - Dynamically framed to the target aspect ratio (`1:1`, `3:2`, `9:16`, `16:9`).
- **Real-Time Step Updates**: Server-Sent Events (SSE) stream progress and intermediate states directly from ComfyUI to the mobile UI.
- **Local Gallery**: Save, inspect, and export generated artworks directly to your phone's photo library.
- **Modern Design**: Deep forest-green surfaces (`#09120F`), glowing orange accents (`#FF5C00`), and clean responsive layouts.

---

## 🚀 Getting Started

### Prerequisites

1. Ensure the Python FastAPI backend is running with local ComfyUI:
   ```bash
   cd D:\DevelopmentSide\AI-projects\sana-ai-image
   python -m uvicorn api:app --host 0.0.0.0 --port 8000
   ```
2. Verify that your phone and computer are on the same local Wi-Fi network.

### Run on Device

Replace with your computer's local IP address:

```bash
flutter run --dart-define=API_BASE_URL=http://192.168.29.196:8000
```

### Build Release APK

```bash
flutter build apk --dart-define=API_BASE_URL=http://192.168.29.196:8000
```

The compiled APK will be at:
`build/app/outputs/flutter-apk/app-release.apk`

Install directly via ADB:

```bash
adb install -r build/app/outputs/flutter-apk/app-release.apk
```

---

## 🛠️ Project Structure

```
lib/
├── data/              # Curated prompt templates and presets
├── models/            # AI model configurations and reactive GenerationController
├── screens/
│   ├── create_screen.dart        # Home dashboard with model selector and hero banner
│   ├── generate_screen.dart      # Generation workspace with aspect ratios and live loader
│   ├── library_screen.dart       # Local image gallery and filtering
│   ├── image_detail_screen.dart  # Full-screen image viewer and save actions
│   └── settings_screen.dart      # ComfyUI workflow status and storage controls
├── theme/             # Design tokens, gradients, and brand colors
└── widgets/           # Diffusion matrix loader, vector brand logo, and model thumbnails
```

---

## 📄 License

MIT
