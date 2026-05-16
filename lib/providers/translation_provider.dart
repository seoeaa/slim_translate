import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/language_pair.dart';
import '../models/translation_state.dart';
import '../services/translation_engine.dart';

final translationEngineProvider = Provider<HyMTEngine>((ref) {
  return HyMTEngine();
});

final inputTextProvider = NotifierProvider<InputTextNotifier, String>(
  InputTextNotifier.new,
);

class InputTextNotifier extends Notifier<String> {
  @override
  String build() => '';
  void set(String text) => state = text;
}

final languagePairProvider =
    NotifierProvider<LanguagePairNotifier, LanguagePair>(
  LanguagePairNotifier.new,
);

class LanguagePairNotifier extends Notifier<LanguagePair> {
  @override
  LanguagePair build() => LanguagePair(Language.english, Language.chinese);

  void setSource(Language lang) =>
      state = LanguagePair(lang, state.target);
  void setTarget(Language lang) =>
      state = LanguagePair(state.source, lang);
  void swap() => state = state.swapped();
}

final translationProvider =
    NotifierProvider<TranslationNotifier, TranslationState>(
  TranslationNotifier.new,
);

class TranslationNotifier extends Notifier<TranslationState> {
  @override
  TranslationState build() => const TranslationState();

  Future<void> translate() async {
    final engine = ref.read(translationEngineProvider);
    final pair = ref.read(languagePairProvider);
    final text = ref.read(inputTextProvider);

    if (text.trim().isEmpty) return;
    if (!engine.isLoaded) {
      state = const TranslationState(
        status: TranslationStatus.error,
        errorMessage: 'Model not loaded. Download and load a model first.',
      );
      return;
    }

    state = state.copyWith(status: TranslationStatus.translating);

    try {
      final buffer = StringBuffer();
      final stream = engine.translate(text, pair);

      await for (final token in stream) {
        buffer.write(token);
        state = state.copyWith(
          outputText: buffer.toString(),
          status: TranslationStatus.translating,
        );
      }

      final result = buffer.toString();
      final cleaned = result.cleanTranslation();

      state = state.copyWith(
        status: TranslationStatus.done,
        outputText: cleaned,
      );
    } catch (e) {
      state = state.copyWith(
        status: TranslationStatus.error,
        errorMessage: e.toString(),
      );
    }
  }

  void reset() {
    state = const TranslationState();
  }
}
