enum ModelLoadStatus { notDownloaded, downloading, downloaded, loading, loaded, error }

enum ModelFamily { hy, minicpmv }

class ModelInfo {
  final String id;
  final String name;
  final String size;
  final String hfRepo;
  final String fileName;
  final String description;
  final ModelFamily family;

  const ModelInfo({
    required this.id,
    required this.name,
    required this.size,
    required this.hfRepo,
    required this.fileName,
    required this.description,
    this.family = ModelFamily.hy,
  });
}

class ModelState {
  final ModelInfo? activeModel;
  final ModelLoadStatus status;
  final double downloadProgress;
  final String? errorMessage;
  final List<ModelInfo> availableModels;

  const ModelState({
    this.activeModel,
    this.status = ModelLoadStatus.notDownloaded,
    this.downloadProgress = 0,
    this.errorMessage,
    this.availableModels = const [],
  });

  ModelState copyWith({
    ModelInfo? activeModel,
    ModelLoadStatus? status,
    double? downloadProgress,
    String? errorMessage,
    List<ModelInfo>? availableModels,
    bool clearError = false,
  }) {
    return ModelState(
      activeModel: activeModel ?? this.activeModel,
      status: status ?? this.status,
      downloadProgress: downloadProgress ?? this.downloadProgress,
      errorMessage: clearError ? null : (errorMessage ?? this.errorMessage),
      availableModels: availableModels ?? this.availableModels,
    );
  }
}
