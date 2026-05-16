# Slim Translate

On-device machine translation app for Android, powered by [Tencent Hy-MT1.5-1.8B](https://huggingface.co/tencent/HY-MT1.5-1.8B-GGUF) running locally via [llama.cpp](https://github.com/ggml-org/llama.cpp).

All inference happens on-device — no internet connection required after model download.

## Features

- **33 languages** — Chinese, English, Russian, Japanese, Korean, Arabic, Hindi, and 26 more
- **On-device LLM inference** — translation runs entirely on the CPU via GGUF quantized models
- **Multiple model sizes** — from 440 MB (1.25-bit) to 1.9 GB (Q8_0)
- **Android Process Text integration** — select text in any app and translate it inline via a compact dialog
- **Language swap** — one tap to reverse source/target languages
- **Streaming output** — translation results appear as they are generated

## Supported Models

| Model | Size | Quantization | Notes |
|-------|------|-------------|-------|
| STQ 1.25-bit | 440 MB | Sherry STQ | Fastest, smallest |
| SEQ 2-bit | 574 MB | SEQ | Good speed/quality balance |
| Q4_K_M | 1.1 GB | 4-bit | Recommended |
| Q6_K | 1.4 GB | 6-bit | Higher quality |
| Q8_0 | 1.9 GB | 8-bit | Maximum quality |

Models are downloaded from HuggingFace on first use.

## Tech Stack

- **Flutter** (Dart)
- **Riverpod** — state management
- **go_router** — navigation
- **flutter_llama** — llama.cpp bindings for on-device inference
- **Hive** — local storage

## Getting Started

```bash
flutter pub get
flutter run
```

## License

MIT
