import 'dart:async';
import 'dart:io';
import 'package:flutter_llama/flutter_llama.dart';
import 'package:http/http.dart' as http;
import 'package:path_provider/path_provider.dart';
import '../models/language_pair.dart';
import '../models/model_state.dart';

typedef ProgressCallback = void Function(double progress, String status);

class HyMTEngine {
  final _llama = FlutterLlama.instance;
  bool _isInitialized = false;
  bool _isTranslating = false;
  ModelFamily _family = ModelFamily.hy;

  bool get isLoaded => _isInitialized;

  static const _bos = '<｜hy_begin▁of▁sentence｜>';
  static const _eos = '<｜hy_end▁of▁sentence｜>';
  static const _user = '<｜hy_User｜>';
  static const _assistant = '<｜hy_Assistant｜>';

  Future<void> _forceUnload() async {
    _isTranslating = false;
    _family = ModelFamily.hy;
    if (_isInitialized) {
      try {
        await _llama.unloadModel();
      } catch (_) {}
      _isInitialized = false;
    }
  }

  Future<String> get _modelDir async {
    final dir = await getApplicationDocumentsDirectory();
    final modelDir = Directory('${dir.path}/models');
    if (!modelDir.existsSync()) {
      await modelDir.create(recursive: true);
    }
    return modelDir.path;
  }

  Future<bool> initialize(String modelPath, {int nThreads = 4, int nCtx = 4096}) async {
    await _forceUnload();

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
    ModelFamily family = ModelFamily.hy,
    int nThreads = 4,
    int nCtx = 1024,
  }) async {
    await _forceUnload();
    _family = family;

    final localPath = await _downloadModelHttp(
      hfRepo: modelId,
      fileName: fileName,
      onProgress: onProgress,
    );

    if (localPath == null) {
      onProgress(0, 'HTTP не удалось, пробуем через плагин...');
      return _downloadAndLoadPlugin(modelId, fileName, onProgress, nThreads, nCtx);
    }

    onProgress(0.95, 'Загрузка модели в память...');
    final config = LlamaConfig(
      modelPath: localPath,
      nThreads: nThreads,
      nGpuLayers: 0,
      contextSize: nCtx,
      batchSize: 512,
      useGpu: false,
      verbose: false,
    );

    _isInitialized = await _llama.loadModel(config);
    if (_isInitialized) {
      onProgress(1.0, 'Готово');
    }
    return _isInitialized;
  }

  Future<String?> _downloadModelHttp({
    required String hfRepo,
    required String fileName,
    required ProgressCallback onProgress,
  }) async {
    final dir = await _modelDir;
    final localFile = File('$dir/$fileName');

    if (localFile.existsSync() && localFile.lengthSync() > 1024 * 1024) {
      onProgress(0.9, 'Модель уже скачана');
      return localFile.path;
    }

    final url = 'https://huggingface.co/$hfRepo/resolve/main/$fileName';

    try {
      final client = http.Client();
      final request = http.Request('GET', Uri.parse(url));
      final response = await client.send(request);

      if (response.statusCode != 200) {
        client.close();
        return null;
      }

      final total = response.contentLength ?? 0;
      int received = 0;

      final raf = await localFile.open(mode: FileMode.write);
      await for (final chunk in response.stream) {
        received += chunk.length;
        await raf.writeFrom(chunk);
        if (total > 0) {
          onProgress(received / total * 0.9, 'Скачивание: ${(received / total * 100).toStringAsFixed(0)}%');
        }
      }
      await raf.close();
      client.close();

      if (!localFile.existsSync() || localFile.lengthSync() < 1024 * 1024) {
        await localFile.delete().catchError((_) => localFile);
        return null;
      }

      return localFile.path;
    } catch (e) {
      if (localFile.existsSync()) {
        await localFile.delete().catchError((_) => localFile);
      }
      return null;
    }
  }

  Future<bool> _downloadAndLoadPlugin(
    String modelId,
    String fileName,
    ProgressCallback onProgress,
    int nThreads,
    int nCtx,
  ) async {
    try {
      onProgress(0, 'Загрузка через плагин...');

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
    if (_family == ModelFamily.minicpmv) {
      return _buildChatMLPrompt(sourceText, sourceLang, targetLang);
    }
    return _buildHyPrompt(sourceText, sourceLang, targetLang);
  }

  String _buildHyPrompt(String sourceText, Language sourceLang, Language targetLang) {
    final hasChinese = sourceLang == Language.chinese || targetLang == Language.chinese;
    String instruction;

    if (hasChinese) {
      instruction = '将以下文本翻译为${targetLang.displayName}，注意只需要输出翻译后的结果，不要额外解释：';
    } else {
      instruction = 'Translate the following segment into ${targetLang.englishName}, without additional explanation：';
    }

    return '$_bos$_user$instruction\n\n$sourceText$_eos$_assistant';
  }

  String _buildChatMLPrompt(String sourceText, Language sourceLang, Language targetLang) {
    final instruction = 'Translate the following text into ${targetLang.englishName}. Output ONLY the translation, nothing else:\n\n$sourceText';

    return '<|im_start|>user\n$instruction<|im_end|>\n<|im_start|>assistant\n';
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
    await _forceUnload();
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
    s = s.replaceAll('<|im_start|>', '');
    s = s.replaceAll('<|im_end|>', '');
    s = s.replaceAll('<|im_sep|>', '');

    if (s.contains('<|image_pad|>')) {
      s = s.replaceAll(RegExp(r'<\|image_pad\|>'), '');
    }

    final thinkingMatch = RegExp(r'<think\b[^>]*>([\s\S]*?)</think\s*>').firstMatch(s);
    if (thinkingMatch != null) {
      s = s.replaceRange(thinkingMatch.start, thinkingMatch.end, '');
    }
    s = s.replaceAll(RegExp(r'<think\b[^>]*>[\s\S]*$'), '');

    s = s.replaceAll(RegExp(r'^[\s\S]*?\n\n'), '');
    if (s.startsWith('Translation:')) {
      s = s.substring('Translation:'.length).trim();
    }

    return s.trim();
  }
}
