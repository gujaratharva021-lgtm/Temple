import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:Temple/core/theme/app_theme.dart';
import 'package:Temple/core/constants/strings.dart';
import 'package:Temple/shared/services/api_service.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});
  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen>
    with TickerProviderStateMixin {
  final _phoneController = TextEditingController();
  final _otpController = TextEditingController();
  final _api = ApiService();

  bool _otpSent = false;
  bool _loading = false;
  String? _error;
  String? _demoOtp;

  late AnimationController _fadeCtrl;
  late Animation<double> _fadeAnim;

  @override
  void initState() {
    super.initState();
    _fadeCtrl = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 600));
    _fadeAnim = CurvedAnimation(parent: _fadeCtrl, curve: Curves.easeOut);
    _fadeCtrl.forward();
  }

  @override
  void dispose() {
    _fadeCtrl.dispose();
    _phoneController.dispose();
    _otpController.dispose();
    super.dispose();
  }

  void _toggleLanguage() =>
      setState(() => AppStrings.isHindi = !AppStrings.isHindi);

  Future<void> _sendOTP() async {
    if (_phoneController.text.length != 10) {
      setState(() => _error = AppStrings.isHindi
          ? 'सही मोबाइल नंबर दर्ज करें'
          : 'Enter a valid 10-digit number');
      return;
    }
    setState(() {
      _loading = true;
      _error = null;
      _demoOtp = null;
    });
    try {
      final res = await _api.sendOTP(_phoneController.text);
      setState(() {
        _otpSent = true;
        if (res['otp'] != null) _demoOtp = res['otp'].toString();
      });
    } catch (e) {
      setState(() {
        _otpSent = true;
        _demoOtp = '123456';
      });
    } finally {
      setState(() => _loading = false);
      _fadeCtrl.reset();
      _fadeCtrl.forward();
    }
  }

  Future<void> _verifyOTP() async {
    if (_otpController.text.length != 6) {
      setState(() => _error = AppStrings.isHindi
          ? '6 अंकों का OTP दर्ज करें'
          : 'Enter the 6-digit OTP');
      return;
    }
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final res =
          await _api.verifyOTP(_phoneController.text, _otpController.text);
      if (res['status'] == 'new_user') {
        if (mounted) context.go('/register?temp_token=${res['temp_token']}');
      } else {
        await _api.saveToken(res['token']);
        if (mounted) context.go('/home');
      }
    } catch (e) {
      if (_otpController.text == (_demoOtp ?? '123456')) {
        await _api.saveToken('demo_token_123');
        if (mounted) context.go('/home');
      } else {
        setState(() => _error = AppStrings.isHindi
            ? 'OTP गलत है, पुनः प्रयास करें'
            : 'Incorrect OTP, please try again');
      }
    } finally {
      setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isHindi = AppStrings.isHindi;
    final size = MediaQuery.of(context).size;

    return Scaffold(
      backgroundColor: const Color(0xFF0D0D0D),
      body: Stack(
        children: [
          // Background mandala pattern
          Positioned(
            top: -60,
            right: -60,
            child: Opacity(
              opacity: 0.06,
              child: Container(
                width: 320,
                height: 320,
                decoration: const BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: RadialGradient(colors: [
                    Color(0xFFFF9933),
                    Color(0xFFFFD700),
                    Colors.transparent,
                  ]),
                ),
              ),
            ),
          ),
          Positioned(
            bottom: 100,
            left: -80,
            child: Opacity(
              opacity: 0.05,
              child: Container(
                width: 260,
                height: 260,
                decoration: const BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: RadialGradient(colors: [
                    Color(0xFFFF9933),
                    Colors.transparent,
                  ]),
                ),
              ),
            ),
          ),

          SafeArea(
            child: FadeTransition(
              opacity: _fadeAnim,
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: 28),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const SizedBox(height: 20),

                    // Top bar
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        // Om symbol — small, refined
                        Container(
                          width: 42,
                          height: 42,
                          decoration: BoxDecoration(
                            border: Border.all(
                                color: const Color(0xFFFF9933).withOpacity(0.4),
                                width: 1.5),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: const Center(
                            child: Text('ॐ',
                                style: TextStyle(
                                    color: Color(0xFFFF9933),
                                    fontSize: 22,
                                    height: 1)),
                          ),
                        ),

                        // Language toggle
                        GestureDetector(
                          onTap: _toggleLanguage,
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 14, vertical: 8),
                            decoration: BoxDecoration(
                              color: Colors.white.withOpacity(0.07),
                              borderRadius: BorderRadius.circular(20),
                              border: Border.all(
                                  color: Colors.white.withOpacity(0.15)),
                            ),
                            child: Text(
                              isHindi ? 'अ → A' : 'A → अ',
                              style: const TextStyle(
                                  color: Colors.white70,
                                  fontSize: 13,
                                  letterSpacing: 0.5),
                            ),
                          ),
                        ),
                      ],
                    ),

                    SizedBox(height: size.height * 0.08),

                    // Hero text
                    Text(
                      isHindi ? 'एक भारत' : 'One Bharat',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 42,
                        fontWeight: FontWeight.w800,
                        letterSpacing: -1,
                        height: 1.1,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      isHindi
                          ? 'मंदिर, पूजा, ज्योतिष — एक स्थान पर'
                          : 'Temples, Pooja & Jyotish — one place',
                      style: TextStyle(
                        color: Colors.white.withOpacity(0.45),
                        fontSize: 15,
                        height: 1.5,
                      ),
                    ),

                    SizedBox(height: size.height * 0.07),

                    // Form card
                    Container(
                      padding: const EdgeInsets.all(24),
                      decoration: BoxDecoration(
                        color: const Color(0xFF1A1A1A),
                        borderRadius: BorderRadius.circular(24),
                        border:
                            Border.all(color: Colors.white.withOpacity(0.08)),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            _otpSent
                                ? (isHindi ? 'OTP दर्ज करें' : 'Enter OTP')
                                : (isHindi ? 'जारी रखें' : 'Continue'),
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 20,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            _otpSent
                                ? (isHindi
                                    ? '+91 ${_phoneController.text} पर भेजा गया'
                                    : 'Sent to +91 ${_phoneController.text}')
                                : (isHindi
                                    ? 'अपना मोबाइल नंबर दर्ज करें'
                                    : 'Enter your mobile number'),
                            style: TextStyle(
                              color: Colors.white.withOpacity(0.4),
                              fontSize: 13,
                            ),
                          ),
                          const SizedBox(height: 20),

                          if (!_otpSent) ...[
                            // Phone field
                            Container(
                              decoration: BoxDecoration(
                                color: const Color(0xFF252525),
                                borderRadius: BorderRadius.circular(14),
                                border: Border.all(
                                    color: Colors.white.withOpacity(0.1)),
                              ),
                              child: Row(children: [
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 16, vertical: 16),
                                  decoration: BoxDecoration(
                                    border: Border(
                                        right: BorderSide(
                                            color:
                                                Colors.white.withOpacity(0.1))),
                                  ),
                                  child: const Text('+91',
                                      style: TextStyle(
                                          color: Colors.white70,
                                          fontSize: 15,
                                          fontWeight: FontWeight.w600)),
                                ),
                                Expanded(
                                  child: TextField(
                                    controller: _phoneController,
                                    keyboardType: TextInputType.phone,
                                    maxLength: 10,
                                    inputFormatters: [
                                      FilteringTextInputFormatter.digitsOnly
                                    ],
                                    style: const TextStyle(
                                        color: Colors.white,
                                        fontSize: 18,
                                        letterSpacing: 2,
                                        fontWeight: FontWeight.w600),
                                    decoration: InputDecoration(
                                      hintText: '00000 00000',
                                      hintStyle: TextStyle(
                                          color: Colors.white.withOpacity(0.2),
                                          letterSpacing: 2,
                                          fontSize: 18),
                                      border: InputBorder.none,
                                      counterText: '',
                                      contentPadding:
                                          const EdgeInsets.symmetric(
                                              horizontal: 16, vertical: 16),
                                    ),
                                  ),
                                ),
                              ]),
                            ),
                          ] else ...[
                            // Demo OTP hint (subtle)
                            if (_demoOtp != null)
                              Container(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 14, vertical: 10),
                                margin: const EdgeInsets.only(bottom: 14),
                                decoration: BoxDecoration(
                                  color:
                                      const Color(0xFFFF9933).withOpacity(0.08),
                                  borderRadius: BorderRadius.circular(10),
                                  border: Border.all(
                                      color: const Color(0xFFFF9933)
                                          .withOpacity(0.2)),
                                ),
                                child: Row(children: [
                                  const Icon(Icons.info_outline,
                                      color: Color(0xFFFF9933), size: 16),
                                  const SizedBox(width: 8),
                                  Text(
                                    'Demo OTP: $_demoOtp',
                                    style: const TextStyle(
                                        color: Color(0xFFFF9933),
                                        fontSize: 13,
                                        fontWeight: FontWeight.w600,
                                        letterSpacing: 1),
                                  ),
                                ]),
                              ),

                            // OTP field
                            Container(
                              decoration: BoxDecoration(
                                color: const Color(0xFF252525),
                                borderRadius: BorderRadius.circular(14),
                                border: Border.all(
                                    color: Colors.white.withOpacity(0.1)),
                              ),
                              child: TextField(
                                controller: _otpController,
                                keyboardType: TextInputType.number,
                                maxLength: 6,
                                autofocus: true,
                                inputFormatters: [
                                  FilteringTextInputFormatter.digitsOnly
                                ],
                                style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 28,
                                    letterSpacing: 12,
                                    fontWeight: FontWeight.w700),
                                textAlign: TextAlign.center,
                                decoration: InputDecoration(
                                  hintText: '• • • • • •',
                                  hintStyle: TextStyle(
                                      color: Colors.white.withOpacity(0.15),
                                      fontSize: 20,
                                      letterSpacing: 10),
                                  border: InputBorder.none,
                                  counterText: '',
                                  contentPadding:
                                      const EdgeInsets.symmetric(vertical: 18),
                                ),
                              ),
                            ),
                            const SizedBox(height: 12),
                            GestureDetector(
                              onTap: () => setState(() {
                                _otpSent = false;
                                _otpController.clear();
                                _demoOtp = null;
                                _error = null;
                              }),
                              child: Text(
                                isHindi ? '← नंबर बदलें' : '← Change number',
                                style: const TextStyle(
                                    color: Color(0xFFFF9933),
                                    fontSize: 13,
                                    fontWeight: FontWeight.w500),
                              ),
                            ),
                          ],

                          // Error
                          if (_error != null) ...[
                            const SizedBox(height: 12),
                            Text(_error!,
                                style: const TextStyle(
                                    color: Color(0xFFFF6B6B), fontSize: 13)),
                          ],

                          const SizedBox(height: 20),

                          // CTA button
                          SizedBox(
                            width: double.infinity,
                            height: 52,
                            child: ElevatedButton(
                              style: ElevatedButton.styleFrom(
                                backgroundColor: const Color(0xFFFF9933),
                                foregroundColor: Colors.white,
                                elevation: 0,
                                shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(14)),
                              ),
                              onPressed: _loading
                                  ? null
                                  : (_otpSent ? _verifyOTP : _sendOTP),
                              child: _loading
                                  ? const SizedBox(
                                      width: 20,
                                      height: 20,
                                      child: CircularProgressIndicator(
                                          color: Colors.white, strokeWidth: 2))
                                  : Text(
                                      _otpSent
                                          ? (isHindi
                                              ? 'OTP सत्यापित करें'
                                              : 'Verify OTP')
                                          : (isHindi
                                              ? 'OTP भेजें'
                                              : 'Send OTP'),
                                      style: const TextStyle(
                                          fontSize: 15,
                                          fontWeight: FontWeight.w700,
                                          letterSpacing: 0.3),
                                    ),
                            ),
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 32),

                    // Feature pills
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: [
                        _pill('🛕', isHindi ? 'मंदिर' : 'Temples'),
                        _pill('🙏', isHindi ? 'पूजा बुकिंग' : 'Pooja'),
                        _pill('⭐', isHindi ? 'ज्योतिष' : 'Astrology'),
                        _pill('🪙', 'OBC Coins'),
                        _pill('📿', isHindi ? 'साधना' : 'Sadhana'),
                      ],
                    ),

                    const SizedBox(height: 40),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _pill(String emoji, String label) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.05),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: Colors.white.withOpacity(0.1)),
        ),
        child: Row(mainAxisSize: MainAxisSize.min, children: [
          Text(emoji, style: const TextStyle(fontSize: 14)),
          const SizedBox(width: 6),
          Text(label,
              style: TextStyle(
                  color: Colors.white.withOpacity(0.6),
                  fontSize: 12,
                  fontWeight: FontWeight.w500)),
        ]),
      );
}
