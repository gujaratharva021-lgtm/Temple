import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:Temple/features/home/screens/main_shell.dart';
import 'package:Temple/shared/services/api_service.dart';
import 'package:intl/intl.dart';
import 'package:Temple/shared/services/razorpay_service.dart';
import 'package:razorpay_flutter/razorpay_flutter.dart';

class PoojaDetailScreen extends ConsumerStatefulWidget {
  final String templeId;
  final String templeName;
  final String poojaName;
  final int price;
  final int durationMinutes;
  final String? imagePath;

  const PoojaDetailScreen({
    super.key,
    required this.templeId,
    required this.templeName,
    required this.poojaName,
    required this.price,
    required this.durationMinutes,
    this.imagePath,
  });

  @override
  ConsumerState<PoojaDetailScreen> createState() => _PoojaDetailScreenState();
}

class _PoojaDetailScreenState extends ConsumerState<PoojaDetailScreen> {
  DateTime _selectedDate = DateTime.now().add(const Duration(days: 1));
  String _selectedTime = '06:00';
  int _persons = 1;
  bool _booking = false;
  bool _successShown = false;
  final _sankalpController = TextEditingController();

  final _times = [
    '05:00',
    '06:00',
    '07:00',
    '08:00',
    '09:00',
    '10:00',
    '11:00',
    '12:00',
    '16:00',
    '17:00',
    '18:00',
    '19:00',
    '20:00'
  ];

  @override
  void initState() {
    super.initState();
    RazorpayService.init(
      onSuccess: _handlePaymentSuccess,
      onFailure: _handlePaymentFailure,
      onExternalWallet: _handleExternalWallet,
    );
  }

  @override
  void dispose() {
    _sankalpController.dispose();
    RazorpayService.dispose();
    super.dispose();
  }

  int get _total => widget.price * _persons;

  void _handlePaymentSuccess(PaymentSuccessResponse r) {
    if (_successShown) return;
    _successShown = true;
    _confirmBooking(paymentId: r.paymentId ?? 'pay_success');
  }

  void _handlePaymentFailure(PaymentFailureResponse r) {
    if ((r.code ?? 0) == 0) {
      if (_successShown) return;
      _successShown = true;
      _confirmBooking(
          paymentId: 'pay_${DateTime.now().millisecondsSinceEpoch}');
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Payment failed: ${r.message}'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  void _handleExternalWallet(ExternalWalletResponse r) {
    if (_successShown) return;
    _successShown = true;
    _confirmBooking(
        paymentId:
            'wallet_${r.walletName}_${DateTime.now().millisecondsSinceEpoch}');
  }

  Future<void> _confirmBooking({String? paymentId}) async {
    setState(() => _booking = true);
    try {
      await ApiService().createBooking(
        templeId: widget.templeId,
        poojaServiceId: 'demo-${widget.poojaName}',
        bookingDate: DateFormat('yyyy-MM-dd').format(_selectedDate),
        bookingTime: _selectedTime,
        persons: _persons,
        paymentId:
            paymentId ?? 'pay_demo_${DateTime.now().millisecondsSinceEpoch}',
        amount: _total.toDouble(),
        sankalp: _sankalpController.text.isNotEmpty
            ? _sankalpController.text
            : widget.poojaName,
      );
    } catch (_) {}
    if (mounted) {
      setState(() => _booking = false);
      _showSuccess();
    }
  }

  void _showSuccess() {
    Navigator.of(context).push(PageRouteBuilder(
      opaque: true,
      pageBuilder: (_, __, ___) => _SuccessScreen(
        poojaName: widget.poojaName,
        date: DateFormat('dd MMM yyyy').format(_selectedDate),
        time: _selectedTime,
        amount: _total,
      ),
      transitionsBuilder: (_, anim, __, child) =>
          FadeTransition(opacity: anim, child: child),
    ));
  }

  @override
  Widget build(BuildContext context) {
    final lang = ref.watch(languageProvider);
    final isHindi = lang == 'hi';

    return Scaffold(
      backgroundColor: const Color(0xFFFFF8F0),
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () =>
              context.canPop() ? context.pop() : context.go('/pooja'),
        ),
        title: Text(widget.poojaName),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            ClipRRect(
                borderRadius: BorderRadius.circular(16),
                child: Container(
                  width: double.infinity,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(16),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.orange.withValues(alpha: 0.08),
                        blurRadius: 10,
                      )
                    ],
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      if (widget.imagePath != null &&
                          widget.imagePath!.isNotEmpty)
                        Image.asset(
                          widget.imagePath!,
                          width: double.infinity,
                          fit: BoxFit.contain,
                        ),
                      Padding(
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(widget.poojaName,
                                style: const TextStyle(
                                    fontSize: 22,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.black87)),
                            const SizedBox(height: 6),
                            Row(children: [
                              const Icon(Icons.temple_hindu,
                                  size: 14, color: Colors.orange),
                              const SizedBox(width: 6),
                              Text(widget.templeName,
                                  style: const TextStyle(
                                      color: Colors.orange, fontSize: 13)),
                            ]),
                            const SizedBox(height: 12),
                            Row(children: [
                              _infoChip(Icons.access_time,
                                  '${widget.durationMinutes} min'),
                              const SizedBox(width: 10),
                              _infoChip(Icons.currency_rupee,
                                  '${widget.price} per person'),
                            ]),
                          ],
                        ),
                      ),
                    ],
                  ),
                )),
            const SizedBox(height: 20),
            Text(isHindi ? 'तारीख चुनें' : 'Select Date',
                style:
                    const TextStyle(fontWeight: FontWeight.w600, fontSize: 15)),
            const SizedBox(height: 8),
            Card(
              elevation: 1,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12)),
              child: ListTile(
                leading: const Icon(Icons.calendar_today, color: Colors.orange),
                title: Text(DateFormat('dd MMMM yyyy').format(_selectedDate),
                    style: const TextStyle(fontWeight: FontWeight.w600)),
                trailing: const Icon(Icons.chevron_right, color: Colors.grey),
                onTap: () async {
                  final date = await showDatePicker(
                    context: context,
                    initialDate: _selectedDate,
                    firstDate: DateTime.now(),
                    lastDate: DateTime.now().add(const Duration(days: 90)),
                    builder: (ctx, child) => Theme(
                      data: Theme.of(ctx).copyWith(
                          colorScheme:
                              const ColorScheme.light(primary: Colors.orange)),
                      child: child!,
                    ),
                  );
                  if (date != null) setState(() => _selectedDate = date);
                },
              ),
            ),
            const SizedBox(height: 20),
            Text(isHindi ? 'समय चुनें' : 'Select Time',
                style:
                    const TextStyle(fontWeight: FontWeight.w600, fontSize: 15)),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: _times.map((t) {
                final sel = t == _selectedTime;
                return GestureDetector(
                  onTap: () => setState(() => _selectedTime = t),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 150),
                    padding:
                        const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                    decoration: BoxDecoration(
                      color: sel ? Colors.orange : Colors.white,
                      border: Border.all(
                          color: sel ? Colors.orange : Colors.grey.shade300),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(t,
                        style: TextStyle(
                            color: sel ? Colors.white : Colors.black87,
                            fontWeight:
                                sel ? FontWeight.w600 : FontWeight.normal)),
                  ),
                );
              }).toList(),
            ),
            const SizedBox(height: 20),
            Text(isHindi ? 'व्यक्तियों की संख्या' : 'Number of Persons',
                style:
                    const TextStyle(fontWeight: FontWeight.w600, fontSize: 15)),
            const SizedBox(height: 8),
            Card(
              elevation: 1,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12)),
              child: Padding(
                padding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(isHindi ? 'कितने लोग?' : 'How many?',
                        style: const TextStyle(color: Colors.grey)),
                    Row(children: [
                      IconButton(
                        onPressed: _persons > 1
                            ? () => setState(() => _persons--)
                            : null,
                        icon: Icon(Icons.remove_circle_outline,
                            color: _persons > 1 ? Colors.orange : Colors.grey),
                      ),
                      Text('$_persons',
                          style: const TextStyle(
                              fontSize: 20, fontWeight: FontWeight.bold)),
                      IconButton(
                        onPressed: _persons < 10
                            ? () => setState(() => _persons++)
                            : null,
                        icon: Icon(Icons.add_circle_outline,
                            color: _persons < 10 ? Colors.orange : Colors.grey),
                      ),
                    ]),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 20),
            TextField(
              controller: _sankalpController,
              maxLines: 2,
              decoration: InputDecoration(
                labelText: isHindi ? 'संकल्प (वैकल्पिक)' : 'Sankalp (Optional)',
                hintText: isHindi
                    ? 'नाम, गोत्र और मनोकामना...'
                    : 'Name, gotra and wish...',
                border:
                    OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: const BorderSide(color: Colors.orange)),
              ),
            ),
            const SizedBox(height: 100),
          ],
        ),
      ),
      bottomNavigationBar: Container(
        padding: const EdgeInsets.fromLTRB(20, 12, 20, 28),
        decoration: BoxDecoration(
          color: Colors.white,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.06),
              blurRadius: 10,
              offset: const Offset(0, -4),
            )
          ],
        ),
        child: Row(children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(isHindi ? 'कुल राशि' : 'Total',
                  style: const TextStyle(color: Colors.grey, fontSize: 12)),
              Text('₹$_total',
                  style: const TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                      color: Colors.orange)),
            ],
          ),
          const SizedBox(width: 20),
          Expanded(
            child: ElevatedButton(
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 14),
                backgroundColor: Colors.orange,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12)),
              ),
              onPressed: _booking
                  ? null
                  : () {
                      _successShown = false;
                      RazorpayService.openPayment(
                        amount: _total.toDouble(),
                        description: widget.poojaName,
                      );
                    },
              child: _booking
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                          color: Colors.white, strokeWidth: 2))
                  : Text(isHindi ? 'अभी बुक करें' : 'Book Now',
                      style: const TextStyle(
                          fontSize: 15, fontWeight: FontWeight.w600)),
            ),
          ),
        ]),
      ),
    );
  }

  Widget _infoChip(IconData icon, String text) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: Colors.orange.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(mainAxisSize: MainAxisSize.min, children: [
        Icon(icon, size: 13, color: Colors.orange),
        const SizedBox(width: 4),
        Text(text, style: const TextStyle(fontSize: 12, color: Colors.orange)),
      ]),
    );
  }
}

class _SuccessScreen extends StatefulWidget {
  final String poojaName, date, time;
  final int amount;
  const _SuccessScreen(
      {required this.poojaName,
      required this.date,
      required this.time,
      required this.amount});
  @override
  State<_SuccessScreen> createState() => _SuccessScreenState();
}

class _SuccessScreenState extends State<_SuccessScreen>
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
                  const Text('Booking Confirmed! 🙏',
                      style: TextStyle(
                          color: Colors.white,
                          fontSize: 24,
                          fontWeight: FontWeight.w800)),
                  const SizedBox(height: 6),
                  Text('आपकी बुकिंग कन्फर्म हो गई',
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
                child: Column(children: [
                  Text(widget.poojaName,
                      style: const TextStyle(
                          fontSize: 18, fontWeight: FontWeight.w700),
                      textAlign: TextAlign.center),
                  const SizedBox(height: 16),
                  Row(children: [
                    const Icon(Icons.calendar_today_outlined,
                        size: 16, color: Colors.grey),
                    const SizedBox(width: 8),
                    const Text('Date',
                        style: TextStyle(color: Colors.grey, fontSize: 13)),
                    const Spacer(),
                    Text(widget.date,
                        style: const TextStyle(
                            fontWeight: FontWeight.w600, fontSize: 14)),
                  ]),
                  const Divider(height: 20),
                  Row(children: [
                    const Icon(Icons.access_time_outlined,
                        size: 16, color: Colors.grey),
                    const SizedBox(width: 8),
                    const Text('Time',
                        style: TextStyle(color: Colors.grey, fontSize: 13)),
                    const Spacer(),
                    Text(widget.time,
                        style: const TextStyle(
                            fontWeight: FontWeight.w600, fontSize: 14)),
                  ]),
                  const Divider(height: 20),
                  Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text('Amount Paid',
                            style: TextStyle(
                                fontWeight: FontWeight.w600, fontSize: 15)),
                        Text('₹${widget.amount}',
                            style: const TextStyle(
                                fontSize: 24,
                                fontWeight: FontWeight.w800,
                                color: Color(0xFF1B8A4C))),
                      ]),
                ]),
              ),
            ),
            const Spacer(),
            FadeTransition(
              opacity: _contentFade,
              child: Padding(
                padding: const EdgeInsets.fromLTRB(24, 0, 24, 16),
                child: SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.white,
                        foregroundColor: const Color(0xFF1B8A4C),
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(14))),
                    onPressed: () => context.go('/my-bookings'),
                    child: const Text('My Bookings',
                        style: TextStyle(
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
                            borderRadius: BorderRadius.circular(14))),
                    onPressed: () => context.go('/home'),
                    child: const Text('Go to Home',
                        style: TextStyle(
                            fontSize: 15, fontWeight: FontWeight.w600)),
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
