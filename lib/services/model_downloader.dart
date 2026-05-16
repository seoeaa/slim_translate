import 'dart:async';
import 'dart:io';
import 'package:http/http.dart' as http;
import 'package:path_provider/path_provider.dart';
import '../models/model_state.dart';

class ModelDownloader {
  static const _baseUrl = 'https://huggingface.co';
  StreamController<DownloadEvent>? _eventController;
  http.Client? _httpClient;
  bool _cancelled = false;

  Stream<DownloadEvent>? get eventStream => _eventController?.stream;

  static final availableModels = [
    const ModelInfo(
      id: 'hy-mt-2bit',
      name: 'Hy-MT1.5-1.8B (2-bit)',
      size: '574 MB',
      hfRepo: 'AngelSlim/Hy-MT1.5-1.8B-2bit-GGUF',
      fileName: 'Hy-MT1.5-1.8B-2bit.gguf',
      description: '2-bit SEQ. Быстрый на ARM CPU с Neon SIMD.',
    ),
    const ModelInfo(
      id: 'hy-mt-1.25bit',
      name: 'Hy-MT1.5-1.8B (1.25-bit)',
      size: '440 MB',
      hfRepo: 'AngelSlim/Hy-MT1.5-1.8B-1.25bit-GGUF',
      fileName: 'Hy-MT1.5-1.8B-1.25bit.gguf',
      description: '1.25-bit Sherry STQ. Самый маленький, для любых устройств.',
    ),
  ];

  static const _expectedSizes = {
    'hy-mt-2bit': 574 * 1024 * 1024,
    'hy-mt-1.25bit': 440 * 1024 * 1024,
  };

  Future<String> get _modelDir async {
    final dir = await getApplicationDocumentsDirectory();
    final modelDir = Directory('${dir.path}/models');
    if (!await modelDir.exists()) {
      await modelDir.create(recursive: true);
    }
    return modelDir.path;
  }

  Future<String> getModelPath(ModelInfo model) async {
    final dir = await _modelDir;
    return '$dir/${model.fileName}';
  }

  Future<bool> isModelDownloaded(ModelInfo model) async {
    final path = await getModelPath(model);
    final file = File(path);
    if (!file.existsSync()) return false;

    final expectedSize = _expectedSizes[model.id];
    if (expectedSize != null) {
      final actualSize = file.lengthSync();
      return actualSize >= expectedSize * 0.95;
    }
    return file.lengthSync() > 1024 * 1024;
  }

  Future<void> downloadModel(ModelInfo model) async {
    final outputPath = await getModelPath(model);
    final url = '$_baseUrl/${model.hfRepo}/resolve/main/${model.fileName}';
    final expectedSize = _expectedSizes[model.id] ?? 0;

    _cancelled = false;
    _eventController = StreamController<DownloadEvent>.broadcast();
    _httpClient = http.Client();

    try {
      final request = http.Request('GET', Uri.parse(url));
      final response = await _httpClient!.send(request);

      if (response.statusCode != 200) {
        throw DownloadException('HTTP ${response.statusCode}');
      }

      final total = response.contentLength ?? expectedSize;
      if (total <= 0) {
        throw DownloadException('Неизвестный размер файла');
      }

      _eventController!.add(DownloadEvent(progress: 0, totalBytes: total, receivedBytes: 0));

      int received = 0;
      final file = File(outputPath);
      final raf = await file.open(mode: FileMode.write);

      final stream = response.stream;
      await for (final chunk in stream) {
        if (_cancelled) {
          await raf.close();
          if (file.existsSync()) await file.delete();
          _eventController!.add(const DownloadEvent.cancelled());
          return;
        }

        received += chunk.length;
        await raf.writeFrom(chunk);

        _eventController!.add(DownloadEvent(
          progress: received / total,
          totalBytes: total,
          receivedBytes: received,
        ));
      }

      await raf.close();

      final actualSize = file.lengthSync();
      if (actualSize < total * 0.95) {
        if (file.existsSync()) await file.delete();
        throw DownloadException('Файл неполный: $actualSize из $total байт');
      }

      _eventController!.add(DownloadEvent(
        progress: 1.0,
        totalBytes: total,
        receivedBytes: actualSize,
        completed: true,
      ));
    } catch (e) {
      if (!_cancelled) {
        _eventController!.add(DownloadEvent.error(e.toString()));
        final file = File(outputPath);
        if (file.existsSync()) await file.delete();
      }
      rethrow;
    } finally {
      _httpClient?.close();
      _httpClient = null;
      _eventController?.close();
      _eventController = null;
    }
  }

  Future<void> cancelDownload() async {
    _cancelled = true;
    _httpClient?.close();
  }

  Future<void> deleteModel(ModelInfo model) async {
    final path = await getModelPath(model);
    final file = File(path);
    if (file.existsSync()) await file.delete();
  }
}

class DownloadEvent {
  final double progress;
  final int totalBytes;
  final int receivedBytes;
  final bool completed;
  final bool cancelled;
  final String? error;

  const DownloadEvent({
    required this.progress,
    this.totalBytes = 0,
    this.receivedBytes = 0,
    this.completed = false,
    this.cancelled = false,
    this.error,
  });

  const DownloadEvent.cancelled()
      : progress = 0,
        totalBytes = 0,
        receivedBytes = 0,
        completed = false,
        cancelled = true,
        error = null;

  factory DownloadEvent.error(String message) => DownloadEvent(
        progress: 0,
        error: message,
      );

  bool get isError => error != null;
}

class DownloadException implements Exception {
  final String message;
  const DownloadException(this.message);
  @override
  String toString() => 'Ошибка загрузки: $message';
}
