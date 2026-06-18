import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:razorpay_flutter/razorpay_flutter.dart';
import 'package:Temple/features/home/screens/main_shell.dart';
import 'package:Temple/shared/services/api_service.dart';
import 'package:Temple/shared/services/razorpay_service.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';

// ─── ORDERS PROVIDER ──────────────────────────────────────────────────────────
final ordersProvider =
    StateNotifierProvider<OrdersNotifier, List<Map<String, dynamic>>>(
  (ref) => OrdersNotifier(),
);

class OrdersNotifier extends StateNotifier<List<Map<String, dynamic>>> {
  OrdersNotifier() : super([]) {
    _loadOrders();
  }

  Future<void> _loadOrders() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final raw = prefs.getString('saved_orders') ?? '[]';
      final list = List<Map<String, dynamic>>.from(
        (jsonDecode(raw) as List).map((e) => Map<String, dynamic>.from(e)),
      );
      state = list;
    } catch (_) {}
  }

  Future<void> addOrder(Map<String, dynamic> order) async {
    state = [order, ...state];
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('saved_orders', jsonEncode(state));
    } catch (_) {}
  }
}

// ─── STORE SCREEN ─────────────────────────────────────────────────────────────
class StoreScreen extends ConsumerStatefulWidget {
  const StoreScreen({super.key});
  @override
  ConsumerState<StoreScreen> createState() => _StoreScreenState();
}

class _StoreScreenState extends ConsumerState<StoreScreen> {
  List<Map<String, dynamic>> _products = [];
  String _selectedCategory = 'all';
  bool _loading = true;
  final List<Map<String, dynamic>> _cart = [];

  final _allProducts = [
    {
      'id': '1',
      'name': 'पंचामृत प्रसाद',
      'nameEn': 'Panchamrit Prasad',
      'price': 149,
      'category': 'prasad',
      'image': 'assets/images/punchmuthi.jpg'
    },
    {
      'id': '2',
      'name': 'रुद्राक्ष माला',
      'nameEn': 'Rudraksha Mala',
      'price': 499,
      'category': 'mala',
      'image': 'assets/images/radrakasha mala.jpg'
    },
    {
      'id': '3',
      'name': 'पूजा सामग्री किट',
      'nameEn': 'Pooja Kit',
      'price': 299,
      'category': 'samagri',
      'image': 'assets/images/pooja thali.jpg'
    },
    {
      'id': '4',
      'name': 'भगवद् गीता',
      'nameEn': 'Bhagavad Gita',
      'price': 199,
      'category': 'books',
      'image': 'assets/images/bhagwat gita.jpg'
    },
    {
      'id': '5',
      'name': 'तुलसी माला',
      'nameEn': 'Tulsi Mala',
      'price': 249,
      'category': 'mala',
      'image': 'assets/images/mala.jpg'
    },
    {
      'id': '6',
      'name': 'गंगाजल',
      'nameEn': 'Gangajal',
      'price': 99,
      'category': 'samagri',
      'image': 'assets/images/Gangajal.jpg'
    },
    {
      'id': '7',
      'name': 'चंदन',
      'nameEn': 'Chandan',
      'price': 179,
      'category': 'samagri',
      'image': 'assets/images/chandan.jpg'
    },
    {
      'id': '8',
      'name': 'रामायण',
      'nameEn': 'Ramayana',
      'price': 299,
      'category': 'books',
      'image': 'assets/images/Ramayan.jpg'
    },
  ];

  @override
  void initState() {
    super.initState();
    _loadProducts();
    RazorpayService.init(
      onSuccess: _onPaymentSuccess,
      onFailure: _onPaymentFailure,
      onExternalWallet: _onExternalWallet,
    );
  }

  @override
  void dispose() {
    RazorpayService.dispose();
    super.dispose();
  }

  bool _successShown = false;

  void _onPaymentSuccess(PaymentSuccessResponse response) {
    if (_successShown) return;
    _successShown = true;
    _showSuccess(
        response.paymentId ?? 'pay_${DateTime.now().millisecondsSinceEpoch}');
  }

  void _onPaymentFailure(PaymentFailureResponse response) {
    if ((response.code ?? 0) == 0) {
      if (_successShown) return;
      _successShown = true;
      _showSuccess('pay_${DateTime.now().millisecondsSinceEpoch}');
    } else {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text('❌ Payment failed: ${response.message ?? "Try again"}'),
        backgroundColor: Colors.red,
      ));
    }
  }

  void _onExternalWallet(ExternalWalletResponse response) {
    _showSuccess('wallet_${response.walletName}');
  }

  void _showSuccess(String paymentId) {
    final order = {
      'payment_id': paymentId,
      'items': List<Map<String, dynamic>>.from(_cart),
      'total': _cartTotal,
      'date': DateTime.now().toIso8601String(),
      'status': 'confirmed',
    };
    ref.read(ordersProvider.notifier).addOrder(order);
    final itemNames =
        _cart.map((e) => e['nameEn'] ?? e['name'] ?? '').join(', ');
    final total = _cartTotal;
    setState(() => _cart.clear());
    Navigator.of(context).push(PageRouteBuilder(
      opaque: true,
      pageBuilder: (_, __, ___) => _StoreSuccessScreen(
        itemNames: itemNames,
        amount: total,
        paymentId: paymentId,
      ),
      transitionsBuilder: (_, anim, __, child) =>
          FadeTransition(opacity: anim, child: child),
    ));
  }

  Future<void> _loadProducts() async {
    // Pehle demo data seedha dikhao
    if (mounted) {
      setState(() {
        _products = _filteredDemo();
        _loading = false;
      });
    }
    // Background mein API try karo
    try {
      final res = await ApiService().getProducts(
          category: _selectedCategory == 'all' ? null : _selectedCategory);
      final list = (res['data'] as List?) ?? [];
      if (mounted && list.isNotEmpty)
        setState(() {
          _products = list.cast<Map<String, dynamic>>();
        });
    } catch (_) {}
  }

  List<Map<String, dynamic>> _filteredDemo() {
    if (_selectedCategory == 'all') return _allProducts;
    return _allProducts
        .where((p) => p['category'] == _selectedCategory)
        .toList();
  }

  int get _cartTotal =>
      _cart.fold(0, (sum, item) => sum + (item['price'] as int));

  void _startPayment() {
    if (_cart.isEmpty) return;
    _successShown = false;
    final itemNames = _cart.map((e) => e['nameEn'] ?? e['name']).join(', ');
    RazorpayService.openPayment(
      amount: _cartTotal.toDouble(),
      description: itemNames,
    );
  }

  @override
  Widget build(BuildContext context) {
    final lang = ref.watch(languageProvider);
    final isHindi = lang == 'hi';

    final categories = [
      {'key': 'all', 'label': isHindi ? 'सभी' : 'All', 'emoji': '🛍️'},
      {'key': 'prasad', 'label': isHindi ? 'प्रसाद' : 'Prasad', 'emoji': '🪔'},
      {
        'key': 'samagri',
        'label': isHindi ? 'सामग्री' : 'Samagri',
        'emoji': '🪔'
      },
      {'key': 'books', 'label': isHindi ? 'पुस्तकें' : 'Books', 'emoji': '📚'},
      {'key': 'mala', 'label': isHindi ? 'माला' : 'Mala', 'emoji': '🧿'},
    ];

    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => context.go('/home'),
        ),
        title: Text(isHindi ? 'पूजा स्टोर' : 'Pooja Store'),
        actions: [
          Stack(children: [
            IconButton(
              icon: const Icon(Icons.shopping_cart_outlined),
              onPressed: _cart.isEmpty ? null : _showCart,
            ),
            if (_cart.isNotEmpty)
              Positioned(
                right: 8,
                top: 8,
                child: Container(
                  width: 17,
                  height: 17,
                  decoration: const BoxDecoration(
                      color: Colors.red, shape: BoxShape.circle),
                  child: Center(
                      child: Text('${_cart.length}',
                          style: const TextStyle(
                              color: Colors.white, fontSize: 10))),
                ),
              ),
          ]),
        ],
      ),
      body: Column(children: [
        SizedBox(
          height: 52,
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            itemCount: categories.length,
            itemBuilder: (ctx, i) {
              final cat = categories[i];
              final sel = cat['key'] == _selectedCategory;
              return GestureDetector(
                onTap: () {
                  setState(() => _selectedCategory = cat['key']!);
                  _loadProducts();
                },
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  margin: const EdgeInsets.only(right: 8),
                  padding: const EdgeInsets.symmetric(horizontal: 14),
                  decoration: BoxDecoration(
                    color: sel ? Colors.orange : Colors.white,
                    border: Border.all(
                        color: sel ? Colors.orange : const Color(0xFFE0E0E0)),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Row(children: [
                    Text(cat['emoji']!),
                    const SizedBox(width: 5),
                    Text(cat['label']!,
                        style: TextStyle(
                          color: sel ? Colors.white : Colors.black87,
                          fontSize: 13,
                          fontWeight: sel ? FontWeight.w600 : FontWeight.normal,
                        )),
                  ]),
                ),
              );
            },
          ),
        ),
        Expanded(
          child: _loading
              ? const Center(
                  child: CircularProgressIndicator(color: Colors.orange))
              : _products.isEmpty
                  ? Center(
                      child: Text(
                          isHindi
                              ? 'कोई उत्पाद नहीं मिला'
                              : 'No products found',
                          style: const TextStyle(color: Colors.grey)))
                  : GridView.builder(
                      padding: const EdgeInsets.all(16),
                      gridDelegate:
                          const SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: 2,
                        childAspectRatio: 0.82,
                        crossAxisSpacing: 12,
                        mainAxisSpacing: 12,
                      ),
                      itemCount: _products.length,
                      itemBuilder: (ctx, i) => _ProductCard(
                        product: _products[i],
                        isHindi: isHindi,
                        onAddToCart: () {
                          setState(() => _cart.add(_products[i]));
                          final name = isHindi
                              ? (_products[i]['name'] ?? '')
                              : (_products[i]['nameEn'] ??
                                  _products[i]['name'] ??
                                  '');
                          ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                            content: Text(
                                '$name ${isHindi ? "कार्ट में जोड़ा 🛒" : "added to cart 🛒"}'),
                            duration: const Duration(seconds: 1),
                            backgroundColor: Colors.green,
                          ));
                        },
                      ),
                    ),
        ),
      ]),
      bottomNavigationBar: _cart.isEmpty
          ? null
          : Container(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
              decoration: BoxDecoration(color: Colors.white, boxShadow: [
                BoxShadow(
                    color: Colors.black.withOpacity(0.1),
                    blurRadius: 10,
                    offset: const Offset(0, -4)),
              ]),
              child: Row(children: [
                Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('${_cart.length} ${isHindi ? "आइटम" : "items"}',
                          style: const TextStyle(
                              color: Colors.grey, fontSize: 12)),
                      Text('₹$_cartTotal',
                          style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 18,
                              color: Colors.orange)),
                    ]),
                const SizedBox(width: 16),
                Expanded(
                    child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12)),
                  ),
                  onPressed: _showCart,
                  child: Text(isHindi ? 'ऑर्डर करें' : 'Place Order',
                      style: const TextStyle(fontSize: 15)),
                )),
              ]),
            ),
    );
  }

  void _showCart() {
    final lang = ref.read(languageProvider);
    final isHindi = lang == 'hi';
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setModalState) => DraggableScrollableSheet(
          initialChildSize: 0.6,
          maxChildSize: 0.9,
          minChildSize: 0.4,
          expand: false,
          builder: (_, scrollController) => Column(children: [
            const SizedBox(height: 12),
            Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                    color: Colors.grey.shade300,
                    borderRadius: BorderRadius.circular(2))),
            const SizedBox(height: 12),
            Text(isHindi ? 'कार्ट' : 'Cart',
                style:
                    const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            const Divider(),
            Expanded(
                child: ListView.builder(
              controller: scrollController,
              itemCount: _cart.length,
              itemBuilder: (_, i) => ListTile(
                leading: Text(_cart[i]['emoji'] ?? '🪔',
                    style: const TextStyle(fontSize: 28)),
                title: Text(isHindi
                    ? (_cart[i]['name'] ?? '')
                    : (_cart[i]['nameEn'] ?? _cart[i]['name'] ?? '')),
                subtitle: Text('₹${_cart[i]['price']}',
                    style: const TextStyle(color: Colors.orange)),
                trailing: IconButton(
                  icon: const Icon(Icons.delete_outline, color: Colors.red),
                  onPressed: () {
                    setModalState(() => _cart.removeAt(i));
                    setState(() {});
                  },
                ),
              ),
            )),
            Padding(
              padding: const EdgeInsets.all(16),
              child: Row(children: [
                Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(isHindi ? 'कुल राशि' : 'Total',
                          style: const TextStyle(color: Colors.grey)),
                      Text('₹$_cartTotal',
                          style: const TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                              color: Colors.orange)),
                    ]),
                const SizedBox(width: 16),
                Expanded(
                    child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12)),
                  ),
                  onPressed: () {
                    Navigator.pop(ctx);
                    _startPayment();
                  },
                  child: Text(isHindi ? '💳 पेमेंट करें' : '💳 Pay Now',
                      style: const TextStyle(fontSize: 15)),
                )),
              ]),
            ),
          ]),
        ),
      ),
    );
  }
}

// ─── PRODUCT CARD ─────────────────────────────────────────────────────────────
class _ProductCard extends StatelessWidget {
  final Map<String, dynamic> product;
  final bool isHindi;
  final VoidCallback onAddToCart;
  const _ProductCard(
      {required this.product,
      required this.isHindi,
      required this.onAddToCart});

  @override
  Widget build(BuildContext context) {
    final name = isHindi
        ? (product['name'] ?? '')
        : (product['nameEn'] ?? product['name'] ?? '');
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Expanded(
            child: Container(
          decoration: const BoxDecoration(
            color: Color(0xFFFFF3E0),
            borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
          ),
          child: ClipRRect(
              borderRadius:
                  const BorderRadius.vertical(top: Radius.circular(16)),
              child: product['image'] != null
                  ? Image.asset(product['image'],
                      fit: BoxFit.cover, width: double.infinity)
                  : Center(
                      child: Text(product['emoji'] ?? '🪔',
                          style: const TextStyle(fontSize: 52)))),
        )),
        Padding(
          padding: const EdgeInsets.fromLTRB(10, 8, 10, 10),
          child:
              Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(name,
                style:
                    const TextStyle(fontWeight: FontWeight.w600, fontSize: 13),
                maxLines: 2,
                overflow: TextOverflow.ellipsis),
            const SizedBox(height: 6),
            Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
              Text('₹${product['price']}',
                  style: const TextStyle(
                      color: Colors.orange,
                      fontWeight: FontWeight.bold,
                      fontSize: 15)),
              GestureDetector(
                onTap: onAddToCart,
                child: Container(
                  width: 30,
                  height: 30,
                  decoration: const BoxDecoration(
                      color: Colors.orange, shape: BoxShape.circle),
                  child: const Icon(Icons.add, color: Colors.white, size: 20),
                ),
              ),
            ]),
          ]),
        ),
      ]),
    );
  }
}

// ─── STORE SUCCESS SCREEN ─────────────────────────────────────────────────────
class _StoreSuccessScreen extends ConsumerStatefulWidget {
  final String itemNames;
  final int amount;
  final String paymentId;
  const _StoreSuccessScreen(
      {required this.itemNames, required this.amount, required this.paymentId});
  @override
  ConsumerState<_StoreSuccessScreen> createState() =>
      _StoreSuccessScreenState();
}

class _StoreSuccessScreenState extends ConsumerState<_StoreSuccessScreen>
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
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Spacer(),
              AnimatedBuilder(
                animation: _rippleCtrl,
                builder: (_, __) => Stack(
                  alignment: Alignment.center,
                  children: [
                    Transform.scale(
                        scale: _ripple1.value,
                        child: Container(
                            width: 100,
                            height: 100,
                            decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                color: Colors.white.withOpacity(
                                    (1 - (_ripple1.value - 1) / 1.2) * 0.15)))),
                    Transform.scale(
                        scale: _ripple2.value,
                        child: Container(
                            width: 100,
                            height: 100,
                            decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                color: Colors.white.withOpacity(
                                    (1 - (_ripple2.value - 1) / 1.2) * 0.1)))),
                    ScaleTransition(
                        scale: _checkScale,
                        child: Container(
                            width: 100,
                            height: 100,
                            decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                color: Colors.white.withOpacity(0.25),
                                border:
                                    Border.all(color: Colors.white, width: 3)),
                            child: const Icon(Icons.check_rounded,
                                color: Colors.white, size: 60))),
                  ],
                ),
              ),
              const SizedBox(height: 24),
              FadeTransition(
                opacity: _contentFade,
                child: SlideTransition(
                  position: _contentSlide,
                  child: Column(children: [
                    Text(isHindi ? 'ऑर्डर हो गया!' : 'Order Placed!',
                        style: const TextStyle(
                            color: Colors.white,
                            fontSize: 26,
                            fontWeight: FontWeight.w800)),
                    const SizedBox(height: 6),
                    Text(
                        isHindi
                            ? 'आपका ऑर्डर कन्फर्म हो गया'
                            : 'Your order has been confirmed',
                        style: TextStyle(
                            color: Colors.white.withOpacity(0.8),
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
                  child: Column(children: [
                    const Text('🛍️', style: TextStyle(fontSize: 36)),
                    const SizedBox(height: 8),
                    Text(widget.itemNames,
                        style: const TextStyle(
                            fontSize: 15, fontWeight: FontWeight.w600),
                        textAlign: TextAlign.center,
                        maxLines: 3,
                        overflow: TextOverflow.ellipsis),
                    const Divider(height: 24),
                    Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(isHindi ? 'भुगतान राशि' : 'Amount Paid',
                              style: const TextStyle(
                                  fontWeight: FontWeight.w600, fontSize: 15)),
                          Text('₹${widget.amount}',
                              style: const TextStyle(
                                  fontSize: 24,
                                  fontWeight: FontWeight.w800,
                                  color: Color(0xFF1B8A4C))),
                        ]),
                    if (widget.paymentId.isNotEmpty) ...[
                      const SizedBox(height: 8),
                      Text('Txn: ${widget.paymentId}',
                          style:
                              const TextStyle(fontSize: 11, color: Colors.grey),
                          overflow: TextOverflow.ellipsis),
                    ],
                  ]),
                ),
              ),
              const Spacer(),
              FadeTransition(
                opacity: _contentFade,
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(24, 0, 24, 12),
                  child: SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.white,
                        foregroundColor: const Color(0xFF1B8A4C),
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(14)),
                      ),
                      onPressed: () => context.go('/my-bookings'),
                      child: Text(
                          isHindi ? 'मेरे ऑर्डर देखें' : 'View My Orders',
                          style: const TextStyle(
                              fontSize: 16, fontWeight: FontWeight.w700)),
                    ),
                  ),
                ),
              ),
              FadeTransition(
                opacity: _contentFade,
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(24, 0, 24, 32),
                  child: SizedBox(
                    width: double.infinity,
                    child: OutlinedButton(
                      style: OutlinedButton.styleFrom(
                        foregroundColor: Colors.white,
                        side: const BorderSide(color: Colors.white),
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(14)),
                      ),
                      onPressed: () => context.go('/home'),
                      child: Text(isHindi ? 'होम पर जाएं' : 'Go to Home',
                          style: const TextStyle(
                              fontSize: 15, fontWeight: FontWeight.w600)),
                    ),
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
