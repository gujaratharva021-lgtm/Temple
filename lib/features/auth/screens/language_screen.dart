import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:go_router/go_router.dart';
import 'package:Temple/main.dart';
import 'package:Temple/features/home/screens/main_shell.dart';

class LanguageScreen extends ConsumerStatefulWidget {
  const LanguageScreen({super.key});
  @override
  ConsumerState<LanguageScreen> createState() => _LanguageScreenState();
}

class _LanguageScreenState extends ConsumerState<LanguageScreen>
    with SingleTickerProviderStateMixin {
  String? _selected;
  late AnimationController _controller;
  late Animation<double> _fadeIn;
  late Animation<double> _slideUp;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 600))
      ..forward();
    _fadeIn = Tween<double>(begin: 0, end: 1)
        .animate(CurvedAnimation(parent: _controller, curve: Curves.easeIn));
    _slideUp = Tween<double>(begin: 30, end: 0)
        .animate(CurvedAnimation(parent: _controller, curve: Curves.easeOut));
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _selectLanguage(String lang) async {
    setState(() => _selected = lang);
    await Future.delayed(const Duration(milliseconds: 250));
    const storage = FlutterSecureStorage();
    await storage.write(key: 'app_language', value: lang);
    ref.read(localeProvider.notifier).setLocale(lang);
    ref.read(languageProvider.notifier).set(lang);
    print('LANGUAGE SET TO: $lang');
    print('LANGUAGE SET TO: $lang');
    print('CURRENT PROVIDER VALUE: ${ref.read(languageProvider)}');
    if (mounted) context.go('/home');
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: AnimatedBuilder(
          animation: _controller,
          builder: (_, __) => Opacity(
            opacity: _fadeIn.value,
            child: Transform.translate(
              offset: Offset(0, _slideUp.value),
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 28),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Container(
                      width: 84,
                      height: 84,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(22),
                        gradient: const LinearGradient(
                            colors: [Color(0xFFFFD700), Color(0xFFFF8C00)]),
                        boxShadow: [
                          BoxShadow(
                              color: Colors.orange.withOpacity(0.25),
                              blurRadius: 20,
                              spreadRadius: 2)
                        ],
                      ),
                      child: const Center(
                          child: Text('🕉️', style: TextStyle(fontSize: 42))),
                    ),
                    const SizedBox(height: 28),
                    const Text('भाषा चुनें',
                        style: TextStyle(
                            color: Color(0xFF2D2D2D),
                            fontSize: 26,
                            fontWeight: FontWeight.bold)),
                    const SizedBox(height: 4),
                    Text('Choose Language',
                        style: TextStyle(
                            color: Colors.grey.shade500, fontSize: 15)),
                    const SizedBox(height: 44),
                    _LanguageCard(
                        emoji: '🇮🇳',
                        language: 'हिंदी',
                        subtitle: 'Hindi',
                        isSelected: _selected == 'hi',
                        onTap: () => _selectLanguage('hi')),
                    const SizedBox(height: 14),
                    _LanguageCard(
                        emoji: '🇬🇧',
                        language: 'English',
                        subtitle: 'अंग्रेज़ी',
                        isSelected: _selected == 'en',
                        onTap: () => _selectLanguage('en')),
                    const SizedBox(height: 44),
                    Text('एक भारत, श्रेष्ठ भारत',
                        style: TextStyle(
                            color: Colors.orange.shade400,
                            fontSize: 12,
                            letterSpacing: 1.5)),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _LanguageCard extends StatelessWidget {
  final String emoji, language, subtitle;
  final bool isSelected;
  final VoidCallback onTap;
  const _LanguageCard(
      {required this.emoji,
      required this.language,
      required this.subtitle,
      required this.isSelected,
      required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 18),
        decoration: BoxDecoration(
          color: isSelected ? Colors.orange.shade50 : Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
              color: isSelected ? Colors.orange : Colors.grey.shade300,
              width: isSelected ? 2 : 1.2),
          boxShadow: [
            BoxShadow(
                color: Colors.black.withOpacity(0.04),
                blurRadius: 8,
                offset: const Offset(0, 2))
          ],
        ),
        child: Row(
          children: [
            Text(emoji, style: const TextStyle(fontSize: 32)),
            const SizedBox(width: 18),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(language,
                      style: TextStyle(
                          color: isSelected
                              ? Colors.orange.shade800
                              : const Color(0xFF2D2D2D),
                          fontSize: 20,
                          fontWeight: FontWeight.bold)),
                  Text(subtitle,
                      style: TextStyle(
                          color: isSelected
                              ? Colors.orange.shade400
                              : Colors.grey.shade500,
                          fontSize: 13)),
                ],
              ),
            ),
            AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              width: 26,
              height: 26,
              decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: isSelected ? Colors.orange : Colors.transparent,
                  border: Border.all(
                      color: isSelected ? Colors.orange : Colors.grey.shade400,
                      width: 2)),
              child: isSelected
                  ? const Icon(Icons.check, color: Colors.white, size: 15)
                  : null,
            ),
          ],
        ),
      ),
    );
  }
}
