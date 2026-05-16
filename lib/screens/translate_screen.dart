import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../models/language_pair.dart';
import '../models/translation_state.dart';
import '../models/model_state.dart';
import '../providers/translation_provider.dart';
import '../providers/model_provider.dart';

final _russianNames = {
  Language.chinese: 'Китайский',
  Language.english: 'Английский',
  Language.french: 'Французский',
  Language.portuguese: 'Португальский',
  Language.spanish: 'Испанский',
  Language.japanese: 'Японский',
  Language.turkish: 'Турецкий',
  Language.russian: 'Русский',
  Language.arabic: 'Арабский',
  Language.korean: 'Корейский',
  Language.thai: 'Тайский',
  Language.italian: 'Итальянский',
  Language.german: 'Немецкий',
  Language.vietnamese: 'Вьетнамский',
  Language.malay: 'Малайский',
  Language.indonesian: 'Индонезийский',
  Language.filipino: 'Филиппинский',
  Language.hindi: 'Хинди',
  Language.polish: 'Польский',
  Language.czech: 'Чешский',
  Language.dutch: 'Голландский',
  Language.khmer: 'Кхмерский',
  Language.burmese: 'Бирманский',
  Language.persian: 'Персидский',
  Language.gujarati: 'Гуджарати',
  Language.urdu: 'Урду',
  Language.telugu: 'Телугу',
  Language.marathi: 'Маратхи',
  Language.hebrew: 'Иврит',
  Language.bengali: 'Бенгальский',
  Language.tamil: 'Тамильский',
  Language.ukrainian: 'Украинский',
};

String ruName(Language lang) => _russianNames[lang] ?? lang.englishName;

class TranslateScreen extends ConsumerStatefulWidget {
  const TranslateScreen({super.key});

  @override
  ConsumerState<TranslateScreen> createState() => _TranslateScreenState();
}

class _TranslateScreenState extends ConsumerState<TranslateScreen> {
  final _inputController = TextEditingController();
  final _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    _inputController.addListener(() {
      ref.read(inputTextProvider.notifier).set(_inputController.text);
    });
  }

  @override
  void dispose() {
    _inputController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  void _onTranslate() {
    ref.read(inputTextProvider.notifier).set(_inputController.text);
    ref.read(translationProvider.notifier).translate();
  }

  void _onSwapLanguages() {
    ref.read(languagePairProvider.notifier).swap();
    final translation = ref.read(translationProvider);
    if (translation.status == TranslationStatus.done) {
      _inputController.text = translation.outputText;
    }
  }

  @override
  Widget build(BuildContext context) {
    final translation = ref.watch(translationProvider);
    final languagePair = ref.watch(languagePairProvider);
    final modelState = ref.watch(modelStateProvider);
    final inputText = ref.watch(inputTextProvider);
    final isTranslating = translation.status == TranslationStatus.translating;
    final isModelLoaded = modelState.status == ModelLoadStatus.loaded;

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (translation.status == TranslationStatus.translating ||
          translation.status == TranslationStatus.done) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 200),
          curve: Curves.easeOut,
        );
      }
    });

    return Scaffold(
      backgroundColor: const Color(0xFFFAFAFA),
      resizeToAvoidBottomInset: true,
      body: SafeArea(
        child: Column(
        children: [
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: Row(
                children: [
                  Expanded(
                    child: _LangTap(
                      language: languagePair.source,
                      onTap: () => _showLanguagePicker(
                        context, languagePair.source,
                        (lang) => ref.read(languagePairProvider.notifier).setSource(lang),
                      ),
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.swap_horiz, size: 28),
                    onPressed: _onSwapLanguages,
                    color: Colors.grey[700],
                  ),
                  Expanded(
                    child: _LangTap(
                      language: languagePair.target,
                      onTap: () => _showLanguagePicker(
                        context, languagePair.target,
                        (lang) => ref.read(languagePairProvider.notifier).setTarget(lang),
                      ),
                    ),
                  ),
                  const SizedBox(width: 4),
                  IconButton(
                    icon: const Icon(Icons.record_voice_over, size: 24),
                    onPressed: () => context.push('/tts'),
                    color: Colors.grey[700],
                    tooltip: 'Озвучка текста',
                  ),
                ],
              ),
            ),
            Divider(height: 1, color: Colors.grey[200]),
            if (!isModelLoaded)
              _ModelWarning(onTap: () => context.push('/models')),
            if (isModelLoaded)
              _ModelLoadedBanner(modelState: modelState),
            if (!isModelLoaded)
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                child: SizedBox(
                  width: double.infinity,
                  height: 44,
                  child: ElevatedButton.icon(
                    onPressed: () => context.push('/models'),
                    icon: const Icon(Icons.download, size: 18),
                    label: const Text('Загрузить модель', style: TextStyle(fontWeight: FontWeight.w600)),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF1A1A2E),
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                      elevation: 0,
                    ),
                  ),
                ),
              ),
            Expanded(
              child: SingleChildScrollView(
                controller: _scrollController,
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    if (translation.status == TranslationStatus.error &&
                        translation.errorMessage != null)
                      Container(
                        padding: const EdgeInsets.all(12),
                        margin: const EdgeInsets.only(bottom: 12),
                        decoration: BoxDecoration(
                          color: Colors.red[50],
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          translation.errorMessage!,
                          style: TextStyle(color: Colors.red[700], fontSize: 13),
                        ),
                      ),
                    _InputCard(
                      controller: _inputController,
                      hint: 'Введите текст для перевода...',
                      enabled: isModelLoaded && !isTranslating,
                    ),
                    const SizedBox(height: 12),
                    _OutputCard(
                      text: translation.outputText,
                      isLoading: isTranslating,
                      isDone: translation.status == TranslationStatus.done,
                      isError: translation.status == TranslationStatus.error,
                    ),
                  ],
                ),
              ),
            ),
            _BottomBar(
              onTranslate: _onTranslate,
              isTranslating: isTranslating,
              inputText: inputText,
              isModelLoaded: isModelLoaded,
            ),
          ],
        ),
      ),
    );
  }

  void _showLanguagePicker(
    BuildContext context,
    Language current,
    ValueChanged<Language> onSelected,
  ) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (ctx) => _LanguagePickerSheet(
        current: current,
        onSelected: (lang) {
          Navigator.pop(ctx);
          onSelected(lang);
        },
      ),
    );
  }
}

class _LangTap extends StatelessWidget {
  const _LangTap({required this.language, required this.onTap});
  final Language language;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
        decoration: BoxDecoration(
          border: Border.all(color: Colors.grey[300]!),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Column(
          children: [
            Text(
              ruName(language),
              style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 2),
            Text(
              language.englishName,
              style: TextStyle(fontSize: 12, color: Colors.grey[500]),
            ),
          ],
        ),
      ),
    );
  }
}

class _LanguagePickerSheet extends StatefulWidget {
  const _LanguagePickerSheet({required this.current, required this.onSelected});
  final Language current;
  final ValueChanged<Language> onSelected;

  @override
  State<_LanguagePickerSheet> createState() => _LanguagePickerSheetState();
}

class _LanguagePickerSheetState extends State<_LanguagePickerSheet> {
  String _search = '';

  @override
  Widget build(BuildContext context) {
    final filtered = Language.values.where((l) {
      if (_search.isEmpty) return true;
      final q = _search.toLowerCase();
      return ruName(l).toLowerCase().contains(q) ||
          l.englishName.toLowerCase().contains(q) ||
          l.code.contains(q);
    }).toList();

    return Container(
      height: MediaQuery.of(context).size.height * 0.75,
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          Container(
            width: 40, height: 4,
            decoration: BoxDecoration(
              color: Colors.grey[300],
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(height: 16),
          TextField(
            autofocus: true,
            decoration: InputDecoration(
              hintText: 'Поиск языка...',
              prefixIcon: const Icon(Icons.search),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            ),
            onChanged: (v) => setState(() => _search = v),
          ),
          const SizedBox(height: 12),
          Expanded(
            child: ListView.builder(
              itemCount: filtered.length,
              itemBuilder: (ctx, index) {
                final lang = filtered[index];
                final isSelected = lang == widget.current;
                return ListTile(
                  leading: Container(
                    width: 40,
                    alignment: Alignment.center,
                    child: Text(
                      lang.code.toUpperCase(),
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                        color: isSelected ? Colors.blue : Colors.grey[700],
                      ),
                    ),
                  ),
                  title: Text(
                    ruName(lang),
                    style: TextStyle(
                      fontWeight: isSelected ? FontWeight.w700 : FontWeight.w400,
                    ),
                  ),
                  subtitle: Text(lang.englishName),
                  trailing: isSelected
                      ? const Icon(Icons.check_circle, color: Colors.blue)
                      : null,
                  onTap: () => widget.onSelected(lang),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

class _ModelWarning extends StatelessWidget {
  const _ModelWarning({required this.onTap});
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          color: Colors.amber[50],
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: Colors.amber[200]!),
        ),
        child: Row(
          children: [
            Icon(Icons.warning_amber_rounded, color: Colors.amber[700], size: 20),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                'Модель не загружена. Нажмите, чтобы скачать.',
                style: TextStyle(color: Colors.amber[900], fontSize: 13),
              ),
            ),
            Icon(Icons.arrow_forward_ios, size: 14, color: Colors.amber[700]),
          ],
        ),
      ),
    );
  }
}

class _ModelLoadedBanner extends StatelessWidget {
  const _ModelLoadedBanner({required this.modelState});
  final ModelState modelState;

  @override
  Widget build(BuildContext context) {
    String modelName = modelState.activeModel?.name ?? '';
    if (modelName.length > 40) modelName = '${modelName.substring(0, 40)}…';
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      decoration: BoxDecoration(
        color: Colors.green[50],
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.green[200]!),
      ),
      child: Row(
        children: [
          Icon(Icons.check_circle_outline, color: Colors.green[700], size: 20),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              'Загружена: $modelName',
              style: TextStyle(color: Colors.green[800], fontSize: 13),
            ),
          ),
        ],
      ),
    );
  }
}

class _InputCard extends StatelessWidget {
  const _InputCard({
    required this.controller,
    required this.hint,
    required this.enabled,
  });
  final TextEditingController controller;
  final String hint;
  final bool enabled;

  Future<void> _pasteFromClipboard(BuildContext context) async {
    final data = await Clipboard.getData(Clipboard.kTextPlain);
    if (data?.text != null && data!.text!.isNotEmpty) {
      controller.text = data.text!;
      controller.selection = TextSelection.fromPosition(
        TextPosition(offset: controller.text.length),
      );
    }
  }

  void _clearText() {
    controller.clear();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey[200]!),
      ),
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          TextField(
            controller: controller,
            enabled: enabled,
            maxLines: 8,
            minLines: 4,
            style: const TextStyle(fontSize: 16, height: 1.5),
            decoration: InputDecoration.collapsed(
              hintText: hint,
              hintStyle: TextStyle(color: Colors.grey[400]),
            ),
            textInputAction: TextInputAction.newline,
          ),
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              TextButton.icon(
                onPressed: () => _pasteFromClipboard(context),
                icon: const Icon(Icons.content_paste, size: 16),
                label: const Text('Вставить', style: TextStyle(fontSize: 12)),
                style: TextButton.styleFrom(
                  foregroundColor: Colors.grey[600],
                  padding: const EdgeInsets.symmetric(horizontal: 8),
                ),
              ),
              const SizedBox(width: 4),
              TextButton.icon(
                onPressed: controller.text.isNotEmpty ? _clearText : null,
                icon: const Icon(Icons.clear, size: 16),
                label: const Text('Очистить', style: TextStyle(fontSize: 12)),
                style: TextButton.styleFrom(
                  foregroundColor: Colors.grey[600],
                  padding: const EdgeInsets.symmetric(horizontal: 8),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _OutputCard extends StatelessWidget {
  const _OutputCard({
    required this.text,
    required this.isLoading,
    required this.isDone,
    required this.isError,
  });
  final String text;
  final bool isLoading;
  final bool isDone;
  final bool isError;

  @override
  Widget build(BuildContext context) {
    if (text.isEmpty && !isLoading && !isError) {
      return const SizedBox.shrink();
    }

    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey[200]!),
      ),
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.translate,
                size: 16,
                color: isDone ? Colors.green[600] : Colors.grey[400],
              ),
              const SizedBox(width: 6),
              Text(
                'Перевод',
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: Colors.grey[600],
                ),
              ),
              const Spacer(),
              if (isLoading)
                SizedBox(
                  width: 14, height: 14,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: Colors.grey[400],
                  ),
                ),
            ],
          ),
          const SizedBox(height: 12),
          SelectableText(
            text.isEmpty && isLoading ? '...' : text,
            style: TextStyle(
              fontSize: 16,
              height: 1.5,
              color: text.isEmpty ? Colors.grey[400] : Colors.black87,
            ),
          ),
        ],
      ),
    );
  }
}

class _BottomBar extends StatelessWidget {
  const _BottomBar({
    required this.onTranslate,
    required this.isTranslating,
    required this.inputText,
    required this.isModelLoaded,
  });
  final VoidCallback onTranslate;
  final bool isTranslating;
  final String inputText;
  final bool isModelLoaded;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.fromLTRB(16, 16, 16, 16 + MediaQuery.of(context).padding.bottom),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 8,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: SizedBox(
        width: double.infinity,
        height: 52,
        child: ElevatedButton(
          onPressed: (isModelLoaded && inputText.isNotEmpty && !isTranslating)
              ? onTranslate
              : null,
          style: ElevatedButton.styleFrom(
            backgroundColor: const Color(0xFF1A1A2E),
            foregroundColor: Colors.white,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            disabledBackgroundColor: Colors.grey[300],
            elevation: 0,
          ),
          child: isTranslating
              ? const SizedBox(
                  width: 22, height: 22,
                  child: CircularProgressIndicator(
                    strokeWidth: 2.5, color: Colors.white,
                  ),
                )
              : const Text('Перевести', style: TextStyle(
                  fontSize: 17, fontWeight: FontWeight.w600,
                )),
        ),
      ),
    );
  }
}
