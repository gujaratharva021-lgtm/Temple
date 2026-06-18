import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:Temple/core/theme/app_theme.dart';
import 'package:Temple/shared/services/api_service.dart';

class RegisterScreen extends StatefulWidget {
  final String tempToken;
  const RegisterScreen({super.key, required this.tempToken});

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _api = ApiService();
  String _selectedRole = 'devotee';
  bool _loading = false;
  String? _error;

  Future<void> _register() async {
    if (_nameController.text.trim().isEmpty) {
      setState(() => _error = 'Please enter your name');
      return;
    }
    setState(() { _loading = true; _error = null; });
    try {
      final res = await _api.register(
        tempToken: widget.tempToken,
        fullName: _nameController.text.trim(),
        role: _selectedRole,
        email: _emailController.text.isNotEmpty ? _emailController.text : null,
      );
      await _api.saveToken(res['token']);
      if (mounted) context.go('/home');
    } catch (e) {
      setState(() => _error = 'Registration failed. Try again.');
    } finally {
      setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('प्रोफाइल बनाएं')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'आपका स्वागत है! 🙏',
              style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            const Text(
              'One Bharat परिवार में जुड़ने के लिए अपनी जानकारी भरें',
              style: TextStyle(color: AppColors.textSecondary),
            ),
            const SizedBox(height: 32),

            TextFormField(
              controller: _nameController,
              decoration: const InputDecoration(
                labelText: 'पूरा नाम *',
                hintText: 'अपना नाम लिखें',
                prefixIcon: Icon(Icons.person_outline),
              ),
            ),
            const SizedBox(height: 16),

            TextFormField(
              controller: _emailController,
              keyboardType: TextInputType.emailAddress,
              decoration: const InputDecoration(
                labelText: 'ईमेल (वैकल्पिक)',
                hintText: 'your@email.com',
                prefixIcon: Icon(Icons.email_outlined),
              ),
            ),
            const SizedBox(height: 24),

            const Text(
              'आप कौन हैं?',
              style: TextStyle(fontWeight: FontWeight.w600, fontSize: 16),
            ),
            const SizedBox(height: 12),

            Row(
              children: [
                _RoleCard(
                  emoji: '🙏',
                  title: 'भक्त',
                  subtitle: 'Devotee',
                  value: 'devotee',
                  selected: _selectedRole,
                  onTap: (v) => setState(() => _selectedRole = v),
                ),
                const SizedBox(width: 12),
                _RoleCard(
                  emoji: '🕉️',
                  title: 'पुजारी',
                  subtitle: 'Priest',
                  value: 'priest',
                  selected: _selectedRole,
                  onTap: (v) => setState(() => _selectedRole = v),
                ),
                const SizedBox(width: 12),
                _RoleCard(
                  emoji: '⭐',
                  title: 'ज्योतिषी',
                  subtitle: 'Astrologer',
                  value: 'astrologer',
                  selected: _selectedRole,
                  onTap: (v) => setState(() => _selectedRole = v),
                ),
              ],
            ),

            if (_error != null) ...[
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: AppColors.error.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(_error!, style: const TextStyle(color: AppColors.error)),
              ),
            ],

            const SizedBox(height: 32),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _loading ? null : _register,
                child: _loading
                    ? const SizedBox(
                        width: 20, height: 20,
                        child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                      )
                    : const Text('शुरू करें  🚀'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _RoleCard extends StatelessWidget {
  final String emoji, title, subtitle, value, selected;
  final Function(String) onTap;

  const _RoleCard({
    required this.emoji, required this.title, required this.subtitle,
    required this.value, required this.selected, required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final isSelected = value == selected;
    return Expanded(
      child: GestureDetector(
        onTap: () => onTap(value),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: isSelected ? AppColors.primary.withOpacity(0.1) : Colors.white,
            border: Border.all(
              color: isSelected ? AppColors.primary : const Color(0xFFE0E0E0),
              width: isSelected ? 2 : 1,
            ),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Column(
            children: [
              Text(emoji, style: const TextStyle(fontSize: 28)),
              const SizedBox(height: 4),
              Text(
                title,
                style: TextStyle(
                  fontWeight: FontWeight.w600, fontSize: 13,
                  color: isSelected ? AppColors.primary : AppColors.textPrimary,
                ),
              ),
              Text(
                subtitle,
                style: const TextStyle(fontSize: 11, color: AppColors.textHint),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
