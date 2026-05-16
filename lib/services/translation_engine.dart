import 'dart:async';
import 'package:flutter_llama/flutter_llama.dart';
import '../models/language_pair.dart';

typedef ProgressCallback = void Function(double progress, String status);

class HyMTEngine {
  final _llama = FlutterLlama.instance;
  bool _isInitialized = false;
  bool _isTranslating = false;

  bool get isLoaded => _isInitialized;

  static const _bos = '<｜hy_begin▁of▁sentence｜>';
  static const _eos = '<｜hy_end▁of▁sentence｜>';
  static const _user = '<｜hy_User｜>';
  static const _assistant = '<｜hy_Assistant｜>';

  Future<bool> initialize(String modelPath, {int nThreads = 4, int nCtx = 4096}) async {
    if (_isInitialized) return true;

    final config = LlamaConfig(
      modelPath: modelPath,
      nThreads: nThreads,
      nGpuLayers: 0,
      contextSize: nCtx,
      batchSize: 512,
      useGpu: false,
      verbose: false,
    );

    _isInitialized = await _llama.loadModel(config);
    return _isInitialized;
  }

  Future<bool> downloadAndLoad({
    required String modelId,
    required String fileName,
    required ProgressCallback onProgress,
    int nThreads = 4,
    int nCtx = 1024,
  }) async {
    try {
      onProgress(0, 'Загрузка модели...');

      await _llama.loadModelWithAutoDownload(
        modelId: modelId,
        source: ModelSource.huggingFace,
        specificFile: fileName,
        config: LlamaConfig(
          modelPath: '',
          nThreads: nThreads,
          nGpuLayers: 0,
          contextSize: nCtx,
          batchSize: 512,
          useGpu: false,
          verbose: false,
        ),
        onProgress: (p) {
          if (p.progress < 1.0) {
            onProgress(p.progress * 0.9, 'Скачивание: ${p.progressPercent}');
          } else {
            onProgress(0.95, 'Загрузка модели в память...');
          }
        },
      );

      _isInitialized = _llama.isModelLoaded;
      if (_isInitialized) {
        onProgress(1.0, 'Готово');
      }
      return _isInitialized;
    } catch (e) {
      _isInitialized = false;
      rethrow;
    }
  }

  String _buildPrompt(String sourceText, Language sourceLang, Language targetLang) {
    final hasChinese = sourceLang == Language.chinese || targetLang == Language.chinese;
    String instruction;

    if (hasChinese) {
      instruction = '将以下文本翻译为${targetLang.displayName}，注意只需要输出翻译后的结果，不要额外解释：';
    } else {
      instruction = 'Translate the following segment into ${targetLang.englishName}, without additional explanation：';
    }

    return '$_bos$_user$instruction\n\n$sourceText$_eos$_assistant';
  }

  Stream<String> translate(String text, LanguagePair languagePair) async* {
    if (!_isInitialized) {
      throw StateError('Модель не загружена');
    }
    if (_isTranslating) {
      throw StateError('Перевод уже выполняется');
    }

    _isTranslating = true;

    try {
      final prompt = _buildPrompt(text, languagePair.source, languagePair.target);

      // Use blocking generate for now — streaming needs flutter_llama bridge fix
      // The current generateStream pre-generates ALL tokens, which blocks anyway
      final response = await _llama.generate(GenerationParams(
        prompt: prompt,
        temperature: 0.7,
        topP: 0.6,
        topK: 20,
        maxTokens: 2048,
        repeatPenalty: 1.05,
      ));

      yield response.text.cleanTranslation();
    } finally {
      _isTranslating = false;
    }
  }

  Future<void> stop() async {
    _isTranslating = false;
    await _llama.stopGeneration();
  }

  Future<void> dispose() async {
    _isTranslating = false;
    if (_isInitialized) {
      await _llama.unloadModel();
      _isInitialized = false;
    }
  }
}

extension TranslationCleanup on String {
  String cleanTranslation() {
    var s = this;

    s = s.replaceAll('<｜hy_begin▁of▁sentence｜>', '');
    s = s.replaceAll('<｜hy_end▁of▁sentence｜>', '');
    s = s.replaceAll('<｜hy_User｜>', '');
    s = s.replaceAll('<｜hy_Assistant｜>', '');
    s = s.replaceAll('<｜hy_place▁holder▁no▁2｜>', '');

    return s.trim();
  }
}
