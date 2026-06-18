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
    with TickerProviderStateMixin {
  String? _selected;
  late AnimationController _controller;
  late AnimationController _rippleController;
  late Animation<double> _fadeIn;
  late Animation<double> _slideUp;
  late Animation<double> _ripple;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 800))
      ..forward();
    _rippleController = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 1500))
      ..repeat(reverse: true);
    _fadeIn = Tween<double>(begin: 0, end: 1).animate(
        CurvedAnimation(parent: _controller, curve: Curves.easeIn));
    _slideUp = Tween<double>(begin: 40, end: 0).animate(
        CurvedAnimation(parent: _controller, curve: Curves.easeOut));
    _ripple = Tween<double>(begin: 0.85, end: 1.15).animate(
        CurvedAnimation(parent: _rippleController, curve: Curves.easeInOut));
  }

  @override
  void dispose() {
    _controller.dispose();
    _rippleController.dispose();
    super.dispose();
  }

  Future<void> _selectLanguage(String lang) async {
    setState(() => _selected = lang);
    await Future.delayed(const Duration(milliseconds: 300));
    const storage = FlutterSecureStorage();
    await storage.write(key: 'app_language', value: lang);
    ref.read(localeProvider.notifier).setLocale(lang);
    ref.read(languageProvider.notifier).set(lang);
    if (mounted) context.go('/home');
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          Positioned.fill(
            child: Image.asset('assets/images/language_bg.png', fit: BoxFit.cover),
          ),
          Positioned.fill(
            child: Container(color: Colors.white.withOpacity(0.82)),
          ),
          SafeArea(
            child: AnimatedBuilder(
              animation: _controller,
              builder: (_, __) => Opacity(
                opacity: _fadeIn.value,
                child: Transform.translate(
                  offset: Offset(0, _slideUp.value),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 32),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Spacer(flex: 2),
                        AnimatedBuilder(
                          animation: _rippleController,
                          builder: (_, __) => Stack(
                            alignment: Alignment.center,
                            children: [
                              Container(
                                width: 90 * _ripple.value,
                                height: 90 * _ripple.value,
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  color: Colors.orange.withOpacity(0.12),
                                ),
                              ),
                              Container(
                                width: 70,
                                height: 70,
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  gradient: const LinearGradient(
                                    colors: [Color(0xFFFF8C00), Color(0xFFFFD700)],
                                    begin: Alignment.topLeft,
                                    end: Alignment.bottomRight,
                                  ),
                                  boxShadow: [
                                    BoxShadow(
                                      color: Colors.orange.withOpacity(0.4),
                                      blurRadius: 20,
                                      spreadRadius: 2,
                                    )
                                  ],
                                ),
                                child: ClipOval(
                                  child: Image.asset(
                                    'assets/images/temple_logo.png',
                                    width: 70,
                                    height: 70,
                                    fit: BoxFit.cover,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 32),
                        Text(
                          'Select your language',
                          style: TextStyle(
                            fontSize: 13,
                            color: Colors.grey.shade600,
                          ),
                        ),
                        const SizedBox(height: 40),
                        _LangCard(
                          label: 'हिंदी',
                          sublabel: 'Hindi',
                          isSelected: _selected == 'hi',
                          onTap: () => _selectLanguage('hi'),
                        ),
                        const SizedBox(height: 12),
                        _LangCard(
                          label: 'English',
                          sublabel: 'अंग्रेज़ी',
                          isSelected: _selected == 'en',
                          onTap: () => _selectLanguage('en'),
                        ),
                        const Spacer(flex: 2),
                        Text(
                          'एक भारत, श्रेष्ठ भारत',
                          style: TextStyle(
                            fontSize: 11,
                            color: Colors.orange.shade400,
                            letterSpacing: 1.2,
                          ),
                        ),
                        const SizedBox(height: 20),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _LangCard extends StatelessWidget {
  final String label, sublabel;
  final bool isSelected;
  final VoidCallback onTap;

  const _LangCard({
    required this.label,
    required this.sublabel,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 250),
        width: double.infinity,
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 18),
        decoration: BoxDecoration(
          color: isSelected
              ? Colors.orange.withOpacity(0.15)
              : Colors.white.withOpacity(0.9),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: isSelected ? Colors.orange : Colors.grey.shade300,
            width: isSelected ? 2 : 1.2,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.06),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(label,
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: isSelected
                            ? Colors.orange.shade800
                            : const Color(0xFF1A1A1A),
                      )),
                  Text(sublabel,
                      style: TextStyle(
                        fontSize: 12,
                        color: isSelected
                            ? Colors.orange.shade400
                            : Colors.grey.shade500,
                      )),
                ],
              ),
            ),
            AnimatedContainer(
              duration: const Duration(milliseconds: 250),
              width: 24,
              height: 24,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: isSelected ? Colors.orange : Colors.transparent,
                border: Border.all(
                  color: isSelected ? Colors.orange : Colors.grey.shade300,
                  width: 2,
                ),
              ),
              child: isSelected
                  ? const Icon(Icons.check, color: Colors.white, size: 14)
                  : null,
            ),
          ],
        ),
      ),
    );
  }
}
