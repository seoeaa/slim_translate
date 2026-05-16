import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/model_state.dart';
import '../providers/model_provider.dart';

class ModelsScreen extends ConsumerWidget {
  const ModelsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final modelState = ref.watch(modelStateProvider);

    return Scaffold(
      backgroundColor: const Color(0xFFFAFAFA),
      appBar: AppBar(
        title: const Text('Модели', style: TextStyle(fontWeight: FontWeight.w600)),
        backgroundColor: Colors.white,
        elevation: 0,
        foregroundColor: Colors.black,
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (modelState.errorMessage != null)
                Container(
                  padding: const EdgeInsets.all(12),
                  margin: const EdgeInsets.only(bottom: 12),
                  decoration: BoxDecoration(
                    color: Colors.red[50],
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.red[200]!),
                  ),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Icon(Icons.error_outline, color: Colors.red[600], size: 20),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Ошибка',
                              style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: Colors.red[800]),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              modelState.errorMessage!,
                              style: TextStyle(color: Colors.red[700], fontSize: 13),
                            ),
                            const SizedBox(height: 8),
                            Row(
                              children: [
                                _RetryButton(
                                  label: 'Повторить',
                                  onPressed: () {
                                    ref.read(modelStateProvider.notifier).clearError();
                                    final model = modelState.activeModel;
                                    if (model != null) {
                                      ref.read(modelStateProvider.notifier).downloadAndLoad(model);
                                    }
                                  },
                                ),
                                const SizedBox(width: 8),
                                TextButton(
                                  onPressed: () => ref.read(modelStateProvider.notifier).clearError(),
                                  child: const Text('Закрыть'),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              Text(
                'Модели перевода',
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.w700, color: Colors.grey[800]),
              ),
              const SizedBox(height: 4),
              Text(
                'Рекомендуем Q4_K_M — гарантированно работает.',
                style: TextStyle(fontSize: 12, color: Colors.grey[500]),
              ),
              const SizedBox(height: 16),
              Expanded(
                child: ListView.separated(
                  itemCount: modelState.availableModels.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 12),
                  itemBuilder: (ctx, index) {
                    final model = modelState.availableModels[index];
                    final isActive = modelState.activeModel?.fileName == model.fileName;
                    return _ModelCard(model: model, isActive: isActive, modelState: modelState);
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _RetryButton extends StatelessWidget {
  const _RetryButton({required this.label, required this.onPressed});
  final String label;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return ElevatedButton.icon(
      onPressed: onPressed,
      icon: const Icon(Icons.refresh, size: 16),
      label: Text(label, style: const TextStyle(fontSize: 12)),
      style: ElevatedButton.styleFrom(
        backgroundColor: const Color(0xFF1A1A2E),
        foregroundColor: Colors.white,
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
        elevation: 0,
      ),
    );
  }
}

class _ModelCard extends ConsumerWidget {
  const _ModelCard({required this.model, required this.isActive, required this.modelState});
  final ModelInfo model;
  final bool isActive;
  final ModelState modelState;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isDownloading = isActive && modelState.status == ModelLoadStatus.downloading;
    final isLoading = isActive && modelState.status == ModelLoadStatus.loading;
    final isLoaded = isActive && modelState.status == ModelLoadStatus.loaded;
    final hasError = isActive && modelState.status == ModelLoadStatus.error;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isLoaded ? Colors.green : hasError ? Colors.red[300]! : Colors.grey[200]!,
          width: isLoaded ? 2 : 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              _Badge(text: model.size),
              const Spacer(),
              if (isLoaded) _Badge(text: 'ЗАГРУЖЕНА', color: Colors.green[600], bg: Colors.green[50]),
              if (hasError) _Badge(text: 'ОШИБКА', color: Colors.red[600], bg: Colors.red[50]),
            ],
          ),
          const SizedBox(height: 10),
          Text(model.name, style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w700)),
          const SizedBox(height: 4),
          Text(model.description, style: TextStyle(fontSize: 13, color: Colors.grey[600], height: 1.4)),
          if (isDownloading || isLoading) ...[
            const SizedBox(height: 12),
            ClipRRect(
              borderRadius: BorderRadius.circular(6),
              child: LinearProgressIndicator(
                value: modelState.downloadProgress > 0.01 ? modelState.downloadProgress : null,
                minHeight: 8,
                backgroundColor: Colors.grey[200],
                valueColor: const AlwaysStoppedAnimation<Color>(Color(0xFF1A1A2E)),
              ),
            ),
            const SizedBox(height: 6),
            Text(
              isDownloading
                  ? 'Скачивание: ${(modelState.downloadProgress * 100).toStringAsFixed(0)}%'
                  : 'Загрузка модели...',
              style: TextStyle(fontSize: 13, color: Colors.grey[700]),
            ),
          ],
          const SizedBox(height: 12),
          SizedBox(
            width: double.infinity,
            height: 44,
            child: _buildButton(ref),
          ),
        ],
      ),
    );
  }

  Widget _buildButton(WidgetRef ref) {
    final notifier = ref.read(modelStateProvider.notifier);
    final isDownloading = isActive && modelState.status == ModelLoadStatus.downloading;
    final isLoading = isActive && modelState.status == ModelLoadStatus.loading;
    final isLoaded = isActive && modelState.status == ModelLoadStatus.loaded;
    final hasError = isActive && modelState.status == ModelLoadStatus.error;

    if (isDownloading || isLoading) {
      return const SizedBox.shrink();
    }

    if (isLoaded) {
      return OutlinedButton(
        onPressed: () => notifier.unloadModel(),
        style: OutlinedButton.styleFrom(
          foregroundColor: Colors.red,
          side: const BorderSide(color: Colors.red),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        ),
        child: const Text('Выгрузить', style: TextStyle(fontWeight: FontWeight.w600)),
      );
    }

    if (hasError) {
      return ElevatedButton.icon(
        onPressed: () => notifier.downloadAndLoad(model),
        icon: const Icon(Icons.refresh, size: 18),
        label: const Text('Повторить', style: TextStyle(fontWeight: FontWeight.w600)),
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.orange,
          foregroundColor: Colors.white,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
          elevation: 0,
        ),
      );
    }

    return ElevatedButton.icon(
      onPressed: () => notifier.downloadAndLoad(model),
      icon: const Icon(Icons.download, size: 18),
      label: const Text('Скачать и загрузить', style: TextStyle(fontWeight: FontWeight.w600)),
      style: ElevatedButton.styleFrom(
        backgroundColor: const Color(0xFF1A1A2E),
        foregroundColor: Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        elevation: 0,
      ),
    );
  }
}

class _Badge extends StatelessWidget {
  const _Badge({required this.text, this.color, this.bg});
  final String text;
  final Color? color;
  final Color? bg;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: bg ?? const Color(0xFF1A1A2E),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Text(text, style: TextStyle(
        color: color ?? Colors.white, fontSize: 12, fontWeight: FontWeight.w600,
      )),
    );
  }
}
