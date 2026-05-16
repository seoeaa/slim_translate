import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/model_state.dart';
import 'translation_provider.dart';

final modelStateProvider =
    NotifierProvider<ModelNotifier, ModelState>(ModelNotifier.new);

class ModelNotifier extends Notifier<ModelState> {
  static final _models = [
    // AngelSlim compact models (fast, own STQ support)
    ModelInfo(
      id: 'AngelSlim/Hy-MT1.5-1.8B-1.25bit-GGUF',
      name: 'STQ 1.25-bit — 440 MB (быстрый)',
      size: '440 MB',
      hfRepo: 'AngelSlim/Hy-MT1.5-1.8B-1.25bit-GGUF',
      fileName: 'Hy-MT1.5-1.8B-1.25bit.gguf',
      description: 'Sherry 1.25-бит. Максимальная скорость, компактный размер.',
    ),
    ModelInfo(
      id: 'AngelSlim/Hy-MT1.5-1.8B-2bit-GGUF',
      name: 'SEQ 2-bit — 574 MB',
      size: '574 MB',
      hfRepo: 'AngelSlim/Hy-MT1.5-1.8B-2bit-GGUF',
      fileName: 'Hy-MT1.5-1.8B-2bit.gguf',
      description: 'SEQ 2-бит. Хороший баланс скорости и качества.',
    ),
    // Tencent official models
    ModelInfo(
      id: 'tencent/HY-MT1.5-1.8B-GGUF',
      name: 'Q4_K_M — 1.1 ГБ (работает)',
      size: '1.1 GB',
      hfRepo: 'tencent/HY-MT1.5-1.8B-GGUF',
      fileName: 'HY-MT1.5-1.8B-Q4_K_M.gguf',
      description: '4-бит. Гарантированно работает. Рекомендуемый вариант.',
    ),
    ModelInfo(
      id: 'tencent/HY-MT1.5-1.8B-GGUF',
      name: 'Q6_K — 1.4 ГБ',
      size: '1.4 GB',
      hfRepo: 'tencent/HY-MT1.5-1.8B-GGUF',
      fileName: 'HY-MT1.5-1.8B-Q6_K.gguf',
      description: '6-бит. Выше качество перевода.',
    ),
    ModelInfo(
      id: 'tencent/HY-MT1.5-1.8B-GGUF',
      name: 'Q8_0 — 1.9 ГБ',
      size: '1.9 GB',
      hfRepo: 'tencent/HY-MT1.5-1.8B-GGUF',
      fileName: 'HY-MT1.5-1.8B-Q8_0.gguf',
      description: '8-бит. Максимальное качество.',
    ),
  ];

  @override
  ModelState build() => ModelState(availableModels: _models);

  Future<void> downloadAndLoad(ModelInfo model) async {
    state = state.copyWith(
      activeModel: model,
      status: ModelLoadStatus.downloading,
      downloadProgress: 0,
      clearError: true,
    );

    try {
      final engine = ref.read(translationEngineProvider);

      final ok = await engine.downloadAndLoad(
        modelId: model.id,
        fileName: model.fileName,
        nThreads: 4,
        nCtx: 2048,
        onProgress: (progress, status) {
          state = state.copyWith(
            status: progress >= 1.0
                ? ModelLoadStatus.loaded
                : progress > 0.95
                    ? ModelLoadStatus.loading
                    : ModelLoadStatus.downloading,
            downloadProgress: progress,
          );
        },
      );

      if (!ok) {
        state = state.copyWith(
          status: ModelLoadStatus.error,
          errorMessage: 'Не удалось загрузить модель. Попробуйте другую версию (Q4_K_M).',
        );
      }
    } catch (e) {
      state = state.copyWith(
        status: ModelLoadStatus.error,
        errorMessage: 'Ошибка: ${e.toString().replaceAll("Exception:", "").trim()}',
      );
    }
  }

  Future<void> unloadModel() async {
    await ref.read(translationEngineProvider).dispose();
    state = state.copyWith(status: ModelLoadStatus.notDownloaded);
  }

  void clearError() {
    state = state.copyWith(clearError: true);
  }
}
