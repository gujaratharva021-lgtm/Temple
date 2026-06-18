import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:razorpay_flutter/razorpay_flutter.dart';
import 'package:Temple/shared/services/api_service.dart';
import 'package:Temple/features/home/screens/main_shell.dart';
import 'package:go_router/go_router.dart';

class WalletScreen extends ConsumerStatefulWidget {
  const WalletScreen({super.key});

  @override
  ConsumerState<WalletScreen> createState() => _WalletScreenState();
}

class _WalletScreenState extends ConsumerState<WalletScreen>
    with SingleTickerProviderStateMixin {
  final _api = ApiService();
  late AnimationController _fadeCtrl;
  late Animation<double> _fadeAnim;
  late Razorpay _razorpay;

  bool _loading = true;
  bool _paying = false;
  int _lastAmount = 0;
  double _walletBalance = 0.0;
  double _obcBalance = 0.0;
  List<Map<String, dynamic>> _transactions = [];

  final List<int> _quickAmounts = [100, 250, 500, 1000, 2000, 5000];
  final _amountCtrl = TextEditingController();

  @override
  void initState() {
    super.initState();
    _fadeCtrl = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 700));
    _fadeAnim = CurvedAnimation(parent: _fadeCtrl, curve: Curves.easeOut);

    _razorpay = Razorpay();
    _razorpay.on(Razorpay.EVENT_PAYMENT_SUCCESS, _onPaySuccess);
    _razorpay.on(Razorpay.EVENT_PAYMENT_ERROR, _onPayError);
    _razorpay.on(Razorpay.EVENT_EXTERNAL_WALLET, _onExternalWallet);

    _loadWallet();
  }

  bool get _isHindi => ref.read(languageProvider) == 'hi';

  Future<void> _loadWallet() async {
    setState(() => _loading = true);
    try {
      final walletRes = await _api.getWallet();
      final txnRes = await _api.getTransactions();

      final walletData = walletRes['data'] ?? walletRes;
      final txnList = (txnRes['data'] ?? txnRes['transactions'] ?? []) as List;

      if (mounted) {
        setState(() {
          _walletBalance =
              (walletData['inr_balance'] as num?)?.toDouble() ?? 0.0;
          _obcBalance = (walletData['obc_balance'] as num?)?.toDouble() ?? 0.0;
          _transactions = txnList.cast<Map<String, dynamic>>();
          _loading = false;
        });
        _fadeCtrl.forward(from: 0);
      }
    } catch (_) {
      if (mounted) setState(() => _loading = false);
    }
  }

  void _openRazorpay(int amount) {
    final options = {
      'key': 'rzp_test_T12Lul1BLAYp2N',
      'amount': amount * 100,
      'name': 'One Bharat',
      'description': 'Wallet Top-up ₹$amount',
      'prefill': {
        'contact': '9999999999',
        'email': 'user@onebharat.com',
        'name': 'Devotee',
      },
      'theme': {'color': '#B8621C'},
    };
    _lastAmount = amount;
    setState(() => _paying = true);
    _razorpay.open(options);
  }

  void _onPaySuccess(PaymentSuccessResponse res) async {
    final isHindi = _isHindi;
    try {
      await _api.verifyWalletPayment(
        paymentId: res.paymentId ?? '',
        amount: _lastAmount,
        orderId: res.orderId,
        signature: res.signature,
      );
    } catch (_) {}
    setState(() {
      _paying = false;
      _walletBalance += _lastAmount;
      _transactions.insert(0, {
        'type': 'credit',
        'amount': _lastAmount,
        'description': isHindi ? 'वॉलेट टॉप-अप' : 'Wallet Top-up',
        'status': 'success',
        'created_at': DateTime.now().toIso8601String(),
      });
    });
    _showSuccessScreen();
  }

  void _onPayError(PaymentFailureResponse res) {
    final isHindi = _isHindi;
    if ((res.code ?? 0) == 0) {
      setState(() {
        _paying = false;
        _walletBalance += _lastAmount;
        _transactions.insert(0, {
          'type': 'credit',
          'amount': _lastAmount,
          'description': isHindi ? 'वॉलेट टॉप-अप' : 'Wallet Top-up',
          'status': 'success',
          'created_at': DateTime.now().toIso8601String(),
        });
      });
      _showSuccessScreen();
    } else {
      setState(() => _paying = false);
      _showSnack(
          isHindi
              ? 'पेमेंट असफल: ${res.message}'
              : 'Payment failed: ${res.message}',
          error: true);
    }
  }

  void _onExternalWallet(ExternalWalletResponse res) {
    final isHindi = _isHindi;
    setState(() {
      _paying = false;
      _walletBalance += _lastAmount;
      _transactions.insert(0, {
        'type': 'credit',
        'amount': _lastAmount,
        'description': isHindi ? 'वॉलेट टॉप-अप' : 'Wallet Top-up',
        'status': 'success',
        'created_at': DateTime.now().toIso8601String(),
      });
    });
    _showSuccessScreen();
  }

  void _showSnack(String msg, {required bool error}) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text(msg),
      backgroundColor: error ? Colors.red.shade700 : const Color(0xFFB8621C),
      behavior: SnackBarBehavior.floating,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
    ));
  }

  void _showSuccessScreen() {
    Navigator.of(context).push(PageRouteBuilder(
      opaque: true,
      pageBuilder: (_, __, ___) => _WalletSuccessScreen(amount: _lastAmount),
      transitionsBuilder: (_, anim, __, child) =>
          FadeTransition(opacity: anim, child: child),
    ));
  }

  void _showAddMoneySheet() {
    final isHindi = _isHindi;
    _amountCtrl.clear();
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => StatefulBuilder(builder: (ctx, setS) {
        int? selected;
        return Padding(
          padding:
              EdgeInsets.only(bottom: MediaQuery.of(ctx).viewInsets.bottom),
          child: Container(
            decoration: const BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
            ),
            padding: const EdgeInsets.fromLTRB(20, 16, 20, 32),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Center(
                  child: Container(
                    width: 40,
                    height: 4,
                    decoration: BoxDecoration(
                        color: Colors.grey.shade300,
                        borderRadius: BorderRadius.circular(2)),
                  ),
                ),
                const SizedBox(height: 20),
                Text(isHindi ? 'पैसे जोड़ें' : 'Add Money',
                    style: const TextStyle(
                        fontSize: 20, fontWeight: FontWeight.bold)),
                const SizedBox(height: 4),
                Text(
                    isHindi
                        ? 'आप कितनी राशि जोड़ना चाहते हैं?'
                        : 'How much do you want to add?',
                    style:
                        TextStyle(color: Colors.grey.shade600, fontSize: 13)),
                const SizedBox(height: 20),
                Wrap(
                  spacing: 10,
                  runSpacing: 10,
                  children: _quickAmounts.map((amt) {
                    final isSel = selected == amt;
                    return GestureDetector(
                      onTap: () {
                        HapticFeedback.selectionClick();
                        setS(() => selected = amt);
                        _amountCtrl.text = amt.toString();
                      },
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 18, vertical: 10),
                        decoration: BoxDecoration(
                          color: isSel
                              ? const Color(0xFFB8621C)
                              : Colors.transparent,
                          border: Border.all(
                              color: const Color(0xFFB8621C), width: 1.2),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Text('₹$amt',
                            style: TextStyle(
                                color: isSel
                                    ? Colors.white
                                    : const Color(0xFFB8621C),
                                fontWeight: FontWeight.w600)),
                      ),
                    );
                  }).toList(),
                ),
                const SizedBox(height: 20),
                TextField(
                  controller: _amountCtrl,
                  keyboardType: TextInputType.number,
                  inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                  onChanged: (_) => setS(() => selected = null),
                  decoration: InputDecoration(
                    prefixText: '₹  ',
                    hintText: isHindi
                        ? 'या कस्टम राशि डालें'
                        : 'Or enter custom amount',
                    border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide(color: Colors.grey.shade300)),
                    focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: const BorderSide(
                            color: Color(0xFFB8621C), width: 1.5)),
                    contentPadding: const EdgeInsets.symmetric(
                        horizontal: 16, vertical: 14),
                  ),
                ),
                const SizedBox(height: 20),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: () {
                      final amt = int.tryParse(_amountCtrl.text);
                      if (amt == null || amt < 10) {
                        _showSnack(
                            isHindi
                                ? 'कम से कम ₹10 आवश्यक है'
                                : 'Minimum ₹10 required',
                            error: true);
                        return;
                      }
                      Navigator.pop(ctx);
                      _openRazorpay(amt);
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFFB8621C),
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14)),
                    ),
                    child: Text(
                        isHindi
                            ? 'Razorpay से पेमेंट करें'
                            : 'Pay via Razorpay',
                        style: const TextStyle(
                            fontSize: 16, fontWeight: FontWeight.bold)),
                  ),
                ),
              ],
            ),
          ),
        );
      }),
    );
  }

  @override
  Widget build(BuildContext context) {
    final lang = ref.watch(languageProvider);
    final isHindi = lang == 'hi';

    return Scaffold(
      backgroundColor: const Color(0xFFF8F4EE),
      body: _loading
          ? const Center(
              child: CircularProgressIndicator(color: Color(0xFFB8621C)))
          : Stack(
              children: [
                RefreshIndicator(
                  color: const Color(0xFFB8621C),
                  onRefresh: _loadWallet,
                  child: CustomScrollView(
                    slivers: [
                      _buildAppBar(isHindi),
                      SliverToBoxAdapter(child: _buildQuickActions(isHindi)),
                      SliverToBoxAdapter(child: _buildTxnHeader(isHindi)),
                      if (_transactions.isEmpty)
                        SliverToBoxAdapter(child: _buildEmptyTxn(isHindi))
                      else
                        SliverList(
                          delegate: SliverChildBuilderDelegate(
                            (_, i) => _buildTxnTile(_transactions[i], isHindi),
                            childCount: _transactions.length,
                          ),
                        ),
                      const SliverToBoxAdapter(child: SizedBox(height: 40)),
                    ],
                  ),
                ),
                if (_paying)
                  Container(
                    color: Colors.black45,
                    child: const Center(
                      child: CircularProgressIndicator(color: Colors.white),
                    ),
                  ),
              ],
            ),
    );
  }

  SliverAppBar _buildAppBar(bool isHindi) {
    return SliverAppBar(
      expandedHeight: 230,
      pinned: true,
      backgroundColor: const Color(0xFFB8621C),
      leading: IconButton(
        icon: const Icon(Icons.arrow_back, color: Colors.white),
        onPressed: () {
          if (context.canPop()) {
            context.pop();
          } else {
            context.go('/home');
          }
        },
      ),
      title: Text(isHindi ? 'मेरा वॉलेट' : 'My Wallet',
          style: const TextStyle(
              color: Colors.white, fontWeight: FontWeight.bold)),
      flexibleSpace: FlexibleSpaceBar(
        background: Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [Color(0xFFB8621C), Color(0xFF7A2E00)],
            ),
          ),
          child: SafeArea(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(24, 56, 24, 24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  Text(isHindi ? 'वॉलेट बैलेंस' : 'Wallet Balance',
                      style: TextStyle(
                          color: Colors.white.withOpacity(0.7), fontSize: 13)),
                  const SizedBox(height: 4),
                  FadeTransition(
                    opacity: _fadeAnim,
                    child: Text(
                      '₹ ${_walletBalance.toStringAsFixed(2)}',
                      style: const TextStyle(
                          color: Colors.white,
                          fontSize: 36,
                          fontWeight: FontWeight.bold,
                          letterSpacing: 0.5),
                    ),
                  ),
                  const SizedBox(height: 18),
                  Row(children: [
                    _chip(
                        Icons.add_rounded,
                        isHindi ? 'पैसे जोड़ें' : 'Add Money',
                        _showAddMoneySheet),
                    const SizedBox(width: 10),
                    _chip(Icons.history_rounded, isHindi ? 'इतिहास' : 'History',
                        () {}),
                  ]),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _chip(IconData icon, String label, VoidCallback onTap) =>
      GestureDetector(
        onTap: () {
          HapticFeedback.lightImpact();
          onTap();
        },
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 9),
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.18),
            borderRadius: BorderRadius.circular(24),
            border:
                Border.all(color: Colors.white.withOpacity(0.3), width: 0.5),
          ),
          child: Row(mainAxisSize: MainAxisSize.min, children: [
            Icon(icon, color: Colors.white, size: 15),
            const SizedBox(width: 6),
            Text(label,
                style: const TextStyle(
                    color: Colors.white,
                    fontSize: 13,
                    fontWeight: FontWeight.w600)),
          ]),
        ),
      );

  Widget _buildQuickActions(bool isHindi) {
    final items = [
      {
        'icon': Icons.account_balance_wallet_rounded,
        'label': isHindi ? 'टॉप अप' : 'Top Up',
        'fn': _showAddMoneySheet
      },
      {
        'icon': Icons.volunteer_activism_rounded,
        'label': isHindi ? 'दान' : 'Donate',
        'fn': () => _showSnack(
            isHindi ? 'दान के लिए मंदिर चुनें' : 'Select a temple to donate',
            error: false)
      },
      {
        'icon': Icons.local_offer_rounded,
        'label': isHindi ? 'ऑफर्स' : 'Offers',
        'fn': () => _showSnack(isHindi ? 'जल्द आ रहा है!' : 'Coming soon!',
            error: false)
      },
      {
        'icon': Icons.help_outline_rounded,
        'label': isHindi ? 'सहायता' : 'Help',
        'fn': () => _showSnack('support@onebharat.com', error: false)
      },
    ];
    return Container(
      margin: const EdgeInsets.fromLTRB(16, 20, 16, 0),
      padding: const EdgeInsets.symmetric(vertical: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 10,
              offset: const Offset(0, 4))
        ],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: items
            .map((a) => GestureDetector(
                  onTap: () {
                    HapticFeedback.selectionClick();
                    (a['fn'] as VoidCallback)();
                  },
                  child: SizedBox(
                    width: 64,
                    child: Column(mainAxisSize: MainAxisSize.min, children: [
                      Container(
                        width: 48,
                        height: 48,
                        decoration: BoxDecoration(
                            color: const Color(0xFFFFF3E8),
                            borderRadius: BorderRadius.circular(14)),
                        child: Icon(a['icon'] as IconData,
                            color: const Color(0xFFB8621C), size: 22),
                      ),
                      const SizedBox(height: 4),
                      Text(a['label'] as String,
                          textAlign: TextAlign.center,
                          style: const TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w600,
                              color: Color(0xFF444444))),
                    ]),
                  ),
                ))
            .toList(),
      ),
    );
  }

  Widget _buildTxnHeader(bool isHindi) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 22, 20, 10),
      child: Row(children: [
        Text(isHindi ? 'ट्रांजैक्शन' : 'Transactions',
            style: const TextStyle(
                fontSize: 17,
                fontWeight: FontWeight.bold,
                color: Color(0xFF1A1A1A))),
        const Spacer(),
        Text(
            isHindi
                ? '${_transactions.length} एंट्री'
                : '${_transactions.length} entries',
            style: TextStyle(color: Colors.grey.shade500, fontSize: 12)),
      ]),
    );
  }

  Widget _buildEmptyTxn(bool isHindi) {
    return Container(
      margin: const EdgeInsets.fromLTRB(16, 0, 16, 0),
      padding: const EdgeInsets.symmetric(vertical: 40),
      decoration: BoxDecoration(
          color: Colors.white, borderRadius: BorderRadius.circular(16)),
      child: Column(children: [
        Icon(Icons.receipt_long_outlined,
            size: 50, color: Colors.grey.shade300),
        const SizedBox(height: 10),
        Text(isHindi ? 'अभी तक कोई ट्रांजैक्शन नहीं' : 'No transactions yet',
            style: TextStyle(color: Colors.grey.shade500, fontSize: 13)),
        const SizedBox(height: 4),
        Text(
            isHindi
                ? 'शुरू करने के लिए पैसे जोड़ें!'
                : 'Add money to get started!',
            style: TextStyle(color: Colors.grey.shade400, fontSize: 12)),
      ]),
    );
  }

  Widget _buildTxnTile(Map<String, dynamic> txn, bool isHindi) {
    final isCredit = (txn['type']?.toString() ?? 'credit') == 'credit';
    final status = txn['status']?.toString() ?? 'success';
    final amount = (txn['amount'] as num?)?.toDouble() ?? 0.0;
    final desc = txn['description']?.toString() ??
        (isHindi ? 'ट्रांजैक्शन' : 'Transaction');
    final dateStr = txn['created_at']?.toString() ?? '';
    final date = DateTime.tryParse(dateStr) ?? DateTime.now();

    final color = status == 'failed'
        ? Colors.red
        : isCredit
            ? Colors.green.shade600
            : const Color(0xFFB8621C);

    final icon = status == 'failed'
        ? Icons.close_rounded
        : isCredit
            ? Icons.arrow_downward_rounded
            : Icons.arrow_upward_rounded;

    final statusLabel = status == 'success'
        ? (isHindi ? 'सफल' : 'Success')
        : status == 'pending'
            ? (isHindi ? 'पेंडिंग' : 'Pending')
            : (isHindi ? 'असफल' : 'Failed');

    return Container(
      margin: const EdgeInsets.fromLTRB(16, 0, 16, 8),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        boxShadow: [
          BoxShadow(
              color: Colors.black.withOpacity(0.03),
              blurRadius: 6,
              offset: const Offset(0, 2))
        ],
      ),
      child: Row(children: [
        Container(
          width: 40,
          height: 40,
          decoration: BoxDecoration(
              color: color.withOpacity(0.1), shape: BoxShape.circle),
          child: Icon(icon, color: color, size: 18),
        ),
        const SizedBox(width: 12),
        Expanded(
          child:
              Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(desc,
                style: const TextStyle(
                    fontWeight: FontWeight.w600,
                    fontSize: 13,
                    color: Color(0xFF1A1A1A)),
                maxLines: 1,
                overflow: TextOverflow.ellipsis),
            const SizedBox(height: 2),
            Text(
              '${date.day}/${date.month}/${date.year}  •  $statusLabel',
              style: TextStyle(color: Colors.grey.shade500, fontSize: 11),
            ),
          ]),
        ),
        Text(
          '${isCredit ? '+' : '-'} ₹${amount.toStringAsFixed(0)}',
          style: TextStyle(
              color: color, fontWeight: FontWeight.bold, fontSize: 15),
        ),
      ]),
    );
  }

  @override
  void dispose() {
    _fadeCtrl.dispose();
    _razorpay.clear();
    _amountCtrl.dispose();
    super.dispose();
  }
}

// ─── WALLET SUCCESS SCREEN ────────────────────────────────────────────────────

class _WalletSuccessScreen extends ConsumerStatefulWidget {
  final int amount;
  const _WalletSuccessScreen({required this.amount});
  @override
  ConsumerState<_WalletSuccessScreen> createState() =>
      _WalletSuccessScreenState();
}

class _WalletSuccessScreenState extends ConsumerState<_WalletSuccessScreen>
    with TickerProviderStateMixin {
  late AnimationController _checkCtrl, _contentCtrl, _rippleCtrl;
  late Animation<double> _checkScale, _contentFade, _ripple1, _ripple2;
  late Animation<Offset> _contentSlide;

  @override
  void initState() {
    super.initState();
    _checkCtrl = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 700));
    _contentCtrl = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 600));
    _rippleCtrl = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 1200))
      ..repeat();

    _checkScale = Tween<double>(begin: 0, end: 1)
        .animate(CurvedAnimation(parent: _checkCtrl, curve: Curves.elasticOut));
    _contentFade = Tween<double>(begin: 0, end: 1)
        .animate(CurvedAnimation(parent: _contentCtrl, curve: Curves.easeIn));
    _contentSlide = Tween<Offset>(begin: const Offset(0, 0.3), end: Offset.zero)
        .animate(CurvedAnimation(parent: _contentCtrl, curve: Curves.easeOut));
    _ripple1 = Tween<double>(begin: 1.0, end: 2.2)
        .animate(CurvedAnimation(parent: _rippleCtrl, curve: Curves.easeOut));
    _ripple2 = Tween<double>(begin: 1.0, end: 2.2).animate(CurvedAnimation(
        parent: _rippleCtrl,
        curve: const Interval(0.4, 1.0, curve: Curves.easeOut)));

    _checkCtrl.forward();
    Future.delayed(
        const Duration(milliseconds: 400), () => _contentCtrl.forward());
  }

  @override
  void dispose() {
    _checkCtrl.dispose();
    _contentCtrl.dispose();
    _rippleCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final lang = ref.watch(languageProvider);
    final isHindi = lang == 'hi';

    return Scaffold(
      body: Container(
        width: double.infinity,
        height: double.infinity,
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [Color(0xFF22A85A), Color(0xFF0D5C32)],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
        ),
        child: SafeArea(
          child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
            const Spacer(),
            AnimatedBuilder(
              animation: _rippleCtrl,
              builder: (_, __) => Stack(alignment: Alignment.center, children: [
                Transform.scale(
                    scale: _ripple1.value,
                    child: Container(
                        width: 100,
                        height: 100,
                        decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: Colors.white.withValues(
                                alpha:
                                    (1 - (_ripple1.value - 1) / 1.2) * 0.15)))),
                Transform.scale(
                    scale: _ripple2.value,
                    child: Container(
                        width: 100,
                        height: 100,
                        decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: Colors.white.withValues(
                                alpha:
                                    (1 - (_ripple2.value - 1) / 1.2) * 0.1)))),
                ScaleTransition(
                    scale: _checkScale,
                    child: Container(
                        width: 100,
                        height: 100,
                        decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: Colors.white.withValues(alpha: 0.25),
                            border: Border.all(color: Colors.white, width: 3)),
                        child: const Icon(Icons.check_rounded,
                            color: Colors.white, size: 60))),
              ]),
            ),
            const SizedBox(height: 24),
            FadeTransition(
              opacity: _contentFade,
              child: SlideTransition(
                position: _contentSlide,
                child: Column(children: [
                  Text(isHindi ? 'पेमेंट सफल! 🙏' : 'Payment Successful! 🙏',
                      style: const TextStyle(
                          color: Colors.white,
                          fontSize: 24,
                          fontWeight: FontWeight.w800)),
                  const SizedBox(height: 6),
                  Text(
                      isHindi
                          ? 'वॉलेट में पैसे जुड़ गए'
                          : 'Money added to your wallet',
                      style: TextStyle(
                          color: Colors.white.withValues(alpha: 0.8),
                          fontSize: 14)),
                ]),
              ),
            ),
            const SizedBox(height: 32),
            FadeTransition(
              opacity: _contentFade,
              child: Container(
                margin: const EdgeInsets.symmetric(horizontal: 24),
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(20)),
                child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(isHindi ? 'जोड़ी गई राशि' : 'Amount Added',
                          style: const TextStyle(
                              fontWeight: FontWeight.w600, fontSize: 15)),
                      Text('₹${widget.amount}',
                          style: const TextStyle(
                              fontSize: 24,
                              fontWeight: FontWeight.w800,
                              color: Color(0xFF1B8A4C))),
                    ]),
              ),
            ),
            const Spacer(),
            FadeTransition(
              opacity: _contentFade,
              child: Padding(
                padding: const EdgeInsets.fromLTRB(24, 0, 24, 32),
                child: SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.white,
                        foregroundColor: const Color(0xFF1B8A4C),
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(14))),
                    onPressed: () => Navigator.of(context).pop(),
                    child: Text(isHindi ? 'वॉलेट पर जाएं' : 'Go to Wallet',
                        style: const TextStyle(
                            fontSize: 16, fontWeight: FontWeight.w700)),
                  ),
                ),
              ),
            ),
          ]),
        ),
      ),
    );
  }
}
