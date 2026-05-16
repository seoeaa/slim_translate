import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'app.dart';
import 'providers/translation_provider.dart';
import 'models/language_pair.dart';
import 'services/translation_engine.dart';

final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const ProviderScope(child: SlimTranslateApp()));

  _setupProcessTextHandler();
}

void _setupProcessTextHandler() {
  const channel = MethodChannel('com.angelslim.slim_translate/process_text');

  channel.setMethodCallHandler((call) async {
    if (call.method == 'onProcessText') {
      final text = call.arguments as String?;
      if (text != null && text.isNotEmpty) {
        await Future.delayed(const Duration(milliseconds: 300));
        final context = navigatorKey.currentContext;
        if (context != null) {
          final container = ProviderScope.containerOf(context, listen: false);
          final engine = container.read(translationEngineProvider);

          if (engine.isLoaded) {
            _showCompactTranslation(context, text, container, engine);
          } else {
            container.read(inputTextProvider.notifier).set(text);
          }
        }
      }
    }
  });
}

void _showCompactTranslation(
  BuildContext context,
  String text,
  ProviderContainer container,
  HyMTEngine engine,
) {
  final pair = LanguagePair(Language.english, Language.chinese);

  showDialog(
    context: context,
    barrierDismissible: true,
    builder: (ctx) => _CompactTranslationDialog(
      text: text,
      engine: engine,
      languagePair: pair,
    ),
  );
}

class _CompactTranslationDialog extends StatefulWidget {
  const _CompactTranslationDialog({
    required this.text,
    required this.engine,
    required this.languagePair,
  });

  final String text;
  final HyMTEngine engine;
  final LanguagePair languagePair;

  @override
  State<_CompactTranslationDialog> createState() => _CompactTranslationDialogState();
}

class _CompactTranslationDialogState extends State<_CompactTranslationDialog> {
  String _result = '';
  bool _loading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _translate();
  }

  Future<void> _translate() async {
    try {
      final buffer = StringBuffer();
      final stream = widget.engine.translate(widget.text, widget.languagePair);
      await for (final token in stream) {
        buffer.write(token);
        if (mounted) {
          setState(() {
            _result = buffer.toString();
            _loading = false;
          });
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _error = e.toString();
          _loading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: Colors.white,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      insetPadding: const EdgeInsets.all(16),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxHeight: 400),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                    decoration: BoxDecoration(
                      color: const Color(0xFF1A1A2E),
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: const Text(
                      'EN → ZH',
                      style: TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.w600),
                    ),
                  ),
                  const Spacer(),
                  IconButton(
                    icon: const Icon(Icons.open_in_full, size: 18),
                    onPressed: () {
                      Navigator.pop(context);
                    },
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(),
                  ),
                  const SizedBox(width: 4),
                  IconButton(
                    icon: const Icon(Icons.close, size: 18),
                    onPressed: () => Navigator.pop(context),
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Text(
                widget.text,
                maxLines: 3,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(fontSize: 13, color: Colors.grey[600]),
              ),
              const SizedBox(height: 8),
              Divider(height: 1, color: Colors.grey[200]),
              const SizedBox(height: 8),
              if (_loading)
                const Center(
                  child: Padding(
                    padding: EdgeInsets.all(16),
                    child: CircularProgressIndicator(strokeWidth: 2),
                  ),
                )
              else if (_error != null)
                Text(_error!, style: TextStyle(color: Colors.red, fontSize: 13))
              else
                Expanded(
                  child: SingleChildScrollView(
                    child: SelectableText(
                      _result,
                      style: const TextStyle(fontSize: 15, height: 1.5),
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

class SlimTranslateApp extends ConsumerWidget {
  const SlimTranslateApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final router = ref.watch(routerProvider);

    return MaterialApp.router(
      routerConfig: router,
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        brightness: Brightness.light,
        scaffoldBackgroundColor: const Color(0xFFFAFAFA),
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFF1A1A2E),
          brightness: Brightness.light,
        ),
        appBarTheme: const AppBarTheme(
          backgroundColor: Colors.white,
          foregroundColor: Colors.black,
          elevation: 0,
          centerTitle: false,
          titleTextStyle: TextStyle(
            color: Colors.black,
            fontSize: 18,
            fontWeight: FontWeight.w700,
          ),
        ),
      ),
    );
  }
}
