import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../screens/translate_screen.dart';
import '../screens/models_screen.dart';
import '../screens/tts_screen.dart';

final routerProvider = Provider<GoRouter>((ref) {
  return GoRouter(
    initialLocation: '/',
    routes: [
      GoRoute(path: '/', builder: (_, __) => const TranslateScreen()),
      GoRoute(path: '/models', builder: (_, __) => const ModelsScreen()),
      GoRoute(path: '/tts', builder: (_, __) => const TtsScreen()),
    ],
  );
});
