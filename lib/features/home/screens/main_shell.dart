import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:go_router/go_router.dart';

// ─── LANGUAGE PROVIDER ───────────────────────────────────────────────────────

final languageProvider = StateNotifierProvider<LanguageNotifier, String>((ref) {
  return LanguageNotifier();
});

class LanguageNotifier extends StateNotifier<String> {
  LanguageNotifier() : super('hi') {
    _load();
  }

  Future<void> _load() async {
    const storage = FlutterSecureStorage();
    final lang = await storage.read(key: 'app_language') ?? 'hi';
    state = lang;
  }

  void set(String lang) async {
    state = lang;
    const storage = FlutterSecureStorage();
    await storage.write(key: 'app_language', value: lang);
  }
}

// ─── MAIN SHELL ──────────────────────────────────────────────────────────────

class MainShell extends ConsumerWidget {
  final Widget child;
  const MainShell({super.key, required this.child});

  int _currentIndex(BuildContext context) {
    final location = GoRouterState.of(context).uri.toString();
    if (location.startsWith('/home')) return 0;
    if (location.startsWith('/temples')) return 1;
    if (location.startsWith('/store')) return 2;
    if (location.startsWith('/astrology')) return 3;
    if (location.startsWith('/wallet')) return 4;
    return 0;
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final lang = ref.watch(languageProvider);
    final isHindi = lang == 'hi';
    final idx = _currentIndex(context);

    return Scaffold(
      body: child,
    );
  }
}
