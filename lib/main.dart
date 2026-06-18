import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:go_router/go_router.dart';
import 'package:Temple/core/theme/app_theme.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:Temple/features/auth/screens/splash_screen.dart';
import 'package:Temple/features/auth/screens/login_screen.dart';
import 'package:Temple/features/auth/screens/register_screen.dart';
import 'package:Temple/features/auth/screens/language_screen.dart';
import 'package:Temple/features/home/screens/main_shell.dart';
import 'package:Temple/features/home/screens/home_screen.dart';
import 'package:Temple/features/temple/screens/temple_list_screen.dart';
import 'package:Temple/features/temple/screens/live_darshan_screen.dart';
import 'package:Temple/features/pooja/screens/pooja_booking_screen.dart';
import 'package:Temple/features/pooja/screens/pooja_list_screen.dart';
import 'package:Temple/features/pooja/screens/pooja_detail_screen.dart';

import 'package:Temple/features/store/screens/store_screen.dart';
import 'package:Temple/features/wallet/screens/wallet_screen.dart';
import 'package:Temple/features/sadhana/screens/sadhana_screen.dart';
import 'package:Temple/features/profile/screens/profile_screen.dart';
import 'package:Temple/features/pooja/screens/my_bookings_screen.dart';
import 'package:Temple/features/temple/screens/temple_detail_screen.dart';
import 'package:Temple/features/astrology/screens/astrology_screen.dart';

// ─── LANGUAGE PROVIDER ───────────────────────────────────────────────────────

final localeProvider = StateNotifierProvider<LocaleNotifier, Locale>((ref) {
  return LocaleNotifier();
});

class LocaleNotifier extends StateNotifier<Locale> {
  LocaleNotifier() : super(const Locale('hi', 'IN')) {
    _loadSavedLocale();
  }
  Future<void> _loadSavedLocale() async {
    const storage = FlutterSecureStorage();
    final lang = await storage.read(key: 'app_language');
    if (lang != null) {
      state =
          lang == 'en' ? const Locale('en', 'US') : const Locale('hi', 'IN');
    }
  }

  void setLocale(String lang) {
    state = lang == 'en' ? const Locale('en', 'US') : const Locale('hi', 'IN');
  }
}

// ─── MAIN ─────────────────────────────────────────────────────────────────────

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const ProviderScope(child: OneBharatApp()));
}

// ─── ROUTER ───────────────────────────────────────────────────────────────────

final _router = GoRouter(
  initialLocation: '/',
  routes: [
    GoRoute(path: '/', builder: (_, __) => const SplashScreen()),
    GoRoute(path: '/language', builder: (_, __) => const LanguageScreen()),
    GoRoute(path: '/login', builder: (_, __) => const LoginScreen()),
    GoRoute(
      path: '/register',
      builder: (_, s) =>
          RegisterScreen(tempToken: s.uri.queryParameters['temp_token'] ?? ''),
    ),
    ShellRoute(
      builder: (context, state, child) => MainShell(child: child),
      routes: [
        GoRoute(path: '/home', builder: (_, __) => const HomeScreen()),
        GoRoute(path: '/temples', builder: (_, __) => const TempleListScreen()),
        GoRoute(
          path: '/live-darshan/:templeId',
          builder: (_, s) =>
              LiveDarshanScreen(templeId: s.pathParameters['templeId'] ?? '1'),
        ),
        GoRoute(path: '/pooja', builder: (_, __) => const PoojaListScreen()),
        GoRoute(
          path: '/pooja-detail/:templeId',
          builder: (_, s) => PoojaDetailScreen(
            imagePath:
                Uri.decodeQueryComponent(s.uri.queryParameters['image'] ?? ''),
            templeId: s.pathParameters['templeId']!,
            templeName: s.uri.queryParameters['temple'] ?? '',
            poojaName: s.uri.queryParameters['name'] ?? '',
            price: int.tryParse(s.uri.queryParameters['price'] ?? '0') ?? 0,
            durationMinutes:
                int.tryParse(s.uri.queryParameters['duration'] ?? '0') ?? 0,
          ),
        ),
        GoRoute(
          path: '/temples/:id',
          builder: (_, s) =>
              TempleDetailScreen(templeId: s.pathParameters['id']!),
        ),
        GoRoute(
          path: '/temples/:id/booking',
          builder: (_, s) => PoojaBookingScreen(
            templeId: s.pathParameters['id']!,
            initialServiceName: s.uri.queryParameters['service'],
          ),
        ),
        GoRoute(
            path: '/astrology', builder: (_, __) => const AstrologyScreen()),
        GoRoute(path: '/store', builder: (_, __) => const StoreScreen()),
        GoRoute(path: '/wallet', builder: (_, __) => const WalletScreen()),
        GoRoute(path: '/sadhana', builder: (_, __) => const SadhanaScreen()),
        GoRoute(
            path: '/my-bookings', builder: (_, __) => const MyBookingsScreen()),
        GoRoute(path: '/profile', builder: (_, __) => const ProfileScreen()),
      ],
    ),
  ],
);

// ─── APP ──────────────────────────────────────────────────────────────────────

class OneBharatApp extends ConsumerWidget {
  const OneBharatApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final locale = ref.watch(localeProvider);

    return MaterialApp.router(
      title: 'Temple',
      debugShowCheckedModeBanner: false,
      locale: locale,
      localizationsDelegates: const [
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      supportedLocales: const [
        Locale('hi', 'IN'),
        Locale('en', 'US'),
      ],
      theme: AppTheme.lightTheme,
      routerConfig: _router,
    );
  }
}
