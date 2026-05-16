enum TranslationStatus { idle, loading, translating, done, error }

class TranslationState {
  final TranslationStatus status;
  final String inputText;
  final String outputText;
  final String? errorMessage;

  const TranslationState({
    this.status = TranslationStatus.idle,
    this.inputText = '',
    this.outputText = '',
    this.errorMessage,
  });

  TranslationState copyWith({
    TranslationStatus? status,
    String? inputText,
    String? outputText,
    String? errorMessage,
  }) {
    return TranslationState(
      status: status ?? this.status,
      inputText: inputText ?? this.inputText,
      outputText: outputText ?? this.outputText,
      errorMessage: errorMessage,
    );
  }
}
