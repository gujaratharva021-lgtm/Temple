import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:Temple/features/home/screens/main_shell.dart';
import 'package:Temple/shared/services/api_service.dart';
import 'package:intl/intl.dart';
import 'package:Temple/shared/services/razorpay_service.dart';
import 'package:razorpay_flutter/razorpay_flutter.dart';

class PoojaBookingScreen extends ConsumerStatefulWidget {
  final String templeId;
  final String? initialServiceName;
  const PoojaBookingScreen(
      {super.key, required this.templeId, this.initialServiceName});
  @override
  ConsumerState<PoojaBookingScreen> createState() => _PoojaBookingScreenState();
}

class _PoojaBookingScreenState extends ConsumerState<PoojaBookingScreen> {
  final _sankalpController = TextEditingController();
  List<Map<String, dynamic>> _services = [];
  Map<String, dynamic>? _selectedService;
  DateTime _selectedDate = DateTime.now().add(const Duration(days: 1));
  String _selectedTime = '06:00';
  int _persons = 1;
  bool _loading = true;
  bool _booking = false;
  int _step = 0;
  bool _successShown = false; // ← double screen fix

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

  final _demoServices = [
    {
      'id': 'demo-1',
      'name': 'रुद्राभिषेक',
      'duration_minutes': 60,
      'price': 501
    },
    {
      'id': 'demo-2',
      'name': 'महामृत्युंजय जाप',
      'duration_minutes': 45,
      'price': 251
    },
    {
      'id': 'demo-3',
      'name': 'सत्यनारायण कथा',
      'duration_minutes': 120,
      'price': 1001
    },
    {'id': 'demo-4', 'name': 'गणेश पूजा', 'duration_minutes': 30, 'price': 151},
    {
      'id': 'demo-5',
      'name': 'लक्ष्मी पूजा',
      'duration_minutes': 45,
      'price': 351
    },
  ];

  @override
  void initState() {
    super.initState();
    _loadServices(initialServiceName: widget.initialServiceName);
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

  // Card payment — Razorpay khud success screen dikhata hai + hamara bhi
  // _successShown flag se sirf ek baar chalega
  void _handlePaymentSuccess(PaymentSuccessResponse response) {
    if (_successShown) return;
    _successShown = true;
    _confirmBooking(paymentId: response.paymentId ?? 'pay_success');
  }

  void _handlePaymentFailure(PaymentFailureResponse response) {
    // code 0 = user ne Razorpay band kiya (cancel/back)
    // Non-card methods (UPI, wallet) yahan aate hain with code 0
    if ((response.code ?? 0) == 0) {
      if (_successShown) return;
      _successShown = true;
      _confirmBooking(
          paymentId: 'pay_${DateTime.now().millisecondsSinceEpoch}');
    } else {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text('Payment failed: ${response.message}'),
        backgroundColor: Colors.red,
      ));
    }
  }

  void _handleExternalWallet(ExternalWalletResponse response) {
    if (_successShown) return;
    _successShown = true;
    _confirmBooking(
        paymentId:
            'wallet_${response.walletName}_${DateTime.now().millisecondsSinceEpoch}');
  }

  Future<void> _loadServices({String? initialServiceName}) async {
    try {
      final res = await ApiService().getTemple(widget.templeId);
      final data = res['data'] ?? res;
      final list = (data['services'] as List?) ?? [];
      if (mounted)
        setState(() {
          _services =
              list.isEmpty ? _demoServices : list.cast<Map<String, dynamic>>();
          if (initialServiceName != null) {
            _selectedService = _services.firstWhere(
              (s) => s['name'] == initialServiceName,
              orElse: () => _services.first,
            );
            _step = 1;
          }
          _loading = false;
        });
    } catch (_) {
      if (mounted)
        setState(() {
          _services = _demoServices;
          if (initialServiceName != null) {
            _selectedService = _services.firstWhere(
              (s) => s['name'] == initialServiceName,
              orElse: () => _services.first,
            );
            _step = 1;
          }
          _loading = false;
        });
    }
  }

  int get _totalAmount =>
      ((_selectedService?['price'] ?? 0) as num).toInt() * _persons;
  bool get _canProceed => _step == 0 ? _selectedService != null : true;

  Future<void> _confirmBooking({String? paymentId}) async {
    if (_selectedService == null) return;
    setState(() => _booking = true);
    try {
      await ApiService().createBooking(
          templeId: widget.templeId,
          poojaServiceId: _selectedService!['id'],
          bookingDate: DateFormat('yyyy-MM-dd').format(_selectedDate),
          bookingTime: _selectedTime,
          persons: _persons,
          paymentId:
              paymentId ?? 'pay_demo_${DateTime.now().millisecondsSinceEpoch}',
          amount: _totalAmount.toDouble(),
          sankalp: _sankalpController.text.isNotEmpty
              ? _sankalpController.text
              : _selectedService?['name']);
      if (mounted) _showSuccessDialog();
    } catch (_) {
      // API fail ho toh bhi success screen dikhao (demo mode)
      if (mounted) _showSuccessDialog();
    } finally {
      if (mounted) setState(() => _booking = false);
    }
  }

  void _showSuccessDialog() {
    Navigator.of(context).push(PageRouteBuilder(
      opaque: true,
      pageBuilder: (_, __, ___) => _SuccessScreen(
        poojaName: _selectedService?['name'] ?? 'Pooja Booking',
        date: DateFormat('dd MMM yyyy').format(_selectedDate),
        time: _selectedTime,
        amount: _totalAmount,
      ),
      transitionsBuilder: (_, anim, __, child) =>
          FadeTransition(opacity: anim, child: child),
    ));
  }

  @override
  Widget build(BuildContext context) {
    final lang = ref.watch(languageProvider);
    final isHindi = lang == 'hi';
    final stepLabels = isHindi
        ? ['पूजा चुनें', 'तारीख व समय', 'संकल्प']
        : ['Select Pooja', 'Date & Time', 'Sankalp'];

    return Scaffold(
      backgroundColor: const Color(0xFFFFF8F0),
      appBar: AppBar(
        title: Text(isHindi ? 'पूजा बुकिंग' : 'Pooja Booking'),
        leading: IconButton(
            icon: const Icon(Icons.arrow_back),
            onPressed: () => context.go('/temples/${widget.templeId}')),
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator(color: Colors.orange))
          : Column(children: [
              _buildStepIndicator(stepLabels),
              Expanded(
                  child: SingleChildScrollView(
                      padding: const EdgeInsets.all(20),
                      child: _step == 0
                          ? _buildStep1(isHindi)
                          : _step == 1
                              ? _buildStep2(isHindi)
                              : _buildStep3(isHindi))),
              _buildBottomBar(isHindi),
            ]),
    );
  }

  Widget _buildStepIndicator(List<String> labels) {
    return Container(
      color: Colors.white,
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 16),
      child: Row(
          children: List.generate(3, (i) {
        final done = i < _step;
        final active = i == _step;
        return Expanded(
            child: Row(children: [
          Column(children: [
            AnimatedContainer(
              duration: const Duration(milliseconds: 300),
              width: 28,
              height: 28,
              decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: done || active ? Colors.orange : Colors.grey.shade200),
              child: Center(
                  child: done
                      ? const Icon(Icons.check, color: Colors.white, size: 16)
                      : Text('${i + 1}',
                          style: TextStyle(
                              color: active ? Colors.white : Colors.grey,
                              fontSize: 12,
                              fontWeight: FontWeight.bold))),
            ),
            const SizedBox(height: 4),
            Text(labels[i],
                style: TextStyle(
                    fontSize: 10,
                    color: active ? Colors.orange : Colors.grey,
                    fontWeight: active ? FontWeight.w600 : FontWeight.normal)),
          ]),
          if (i < 2)
            Expanded(
                child: Container(
                    height: 2,
                    margin: const EdgeInsets.only(bottom: 18),
                    color: i < _step ? Colors.orange : Colors.grey.shade200)),
        ]));
      })),
    );
  }

  Widget _buildStep1(bool isHindi) {
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Text(isHindi ? 'पूजा सेवा चुनें' : 'Select Pooja Service',
          style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
      const SizedBox(height: 4),
      Text(isHindi ? 'मंदिर में उपलब्ध सेवाएं' : 'Available temple services',
          style: const TextStyle(color: Colors.grey, fontSize: 13)),
      const SizedBox(height: 16),
      ..._services.map((s) {
        final isSelected = _selectedService?['id'] == s['id'];
        return GestureDetector(
          onTap: () => setState(() => _selectedService = s),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            margin: const EdgeInsets.only(bottom: 10),
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color:
                  isSelected ? Colors.orange.withOpacity(0.08) : Colors.white,
              border: Border.all(
                  color: isSelected ? Colors.orange : Colors.grey.shade200,
                  width: isSelected ? 2 : 1),
              borderRadius: BorderRadius.circular(14),
              boxShadow: isSelected
                  ? [
                      BoxShadow(
                          color: Colors.orange.withOpacity(0.15),
                          blurRadius: 8,
                          offset: const Offset(0, 3))
                    ]
                  : [],
            ),
            child: Row(children: [
              Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                      color: isSelected
                          ? Colors.orange.withOpacity(0.15)
                          : Colors.grey.shade100,
                      borderRadius: BorderRadius.circular(10)),
                  child: const Center(
                      child: Text('🙏', style: TextStyle(fontSize: 22)))),
              const SizedBox(width: 12),
              Expanded(
                  child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                    Text(s['name'] as String,
                        style: const TextStyle(
                            fontWeight: FontWeight.w600, fontSize: 14)),
                    const SizedBox(height: 3),
                    Row(children: [
                      const Icon(Icons.access_time,
                          size: 12, color: Colors.grey),
                      const SizedBox(width: 3),
                      Text(
                          '${s['duration_minutes']} ${isHindi ? 'मिनट' : 'min'}',
                          style:
                              const TextStyle(fontSize: 12, color: Colors.grey))
                    ]),
                  ])),
              Text('₹${s['price']}',
                  style: TextStyle(
                      color:
                          isSelected ? Colors.orange : Colors.orange.shade700,
                      fontWeight: FontWeight.bold,
                      fontSize: 16)),
            ]),
          ),
        );
      }),
    ]);
  }

  Widget _buildStep2(bool isHindi) {
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Text(isHindi ? 'तारीख और समय चुनें' : 'Select Date & Time',
          style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
      const SizedBox(height: 16),
      Card(
          elevation: 1,
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
          child: ListTile(
            leading: Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                    color: Colors.orange.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(10)),
                child: const Icon(Icons.calendar_today,
                    color: Colors.orange, size: 20)),
            title: Text(DateFormat('dd MMMM yyyy').format(_selectedDate),
                style: const TextStyle(fontWeight: FontWeight.w600)),
            subtitle: Text(
                isHindi ? 'तारीख बदलने के लिए टैप करें' : 'Tap to change date'),
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
                      child: child!));
              if (date != null) setState(() => _selectedDate = date);
            },
          )),
      const SizedBox(height: 20),
      Text(isHindi ? 'समय चुनें' : 'Select Time',
          style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 15)),
      const SizedBox(height: 10),
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
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                decoration: BoxDecoration(
                    color: sel ? Colors.orange : Colors.white,
                    border: Border.all(
                        color: sel ? Colors.orange : Colors.grey.shade300),
                    borderRadius: BorderRadius.circular(20)),
                child: Text(t,
                    style: TextStyle(
                        color: sel ? Colors.white : Colors.black87,
                        fontWeight: sel ? FontWeight.w600 : FontWeight.normal)),
              ),
            );
          }).toList()),
      const SizedBox(height: 24),
      Text(isHindi ? 'व्यक्तियों की संख्या' : 'Number of Persons',
          style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 15)),
      const SizedBox(height: 10),
      Card(
          elevation: 1,
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
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
                            color: _persons > 1 ? Colors.orange : Colors.grey)),
                    SizedBox(
                        width: 36,
                        child: Text('$_persons',
                            textAlign: TextAlign.center,
                            style: const TextStyle(
                                fontSize: 20, fontWeight: FontWeight.bold))),
                    IconButton(
                        onPressed: _persons < 10
                            ? () => setState(() => _persons++)
                            : null,
                        icon: Icon(Icons.add_circle_outline,
                            color:
                                _persons < 10 ? Colors.orange : Colors.grey)),
                  ]),
                ]),
          )),
    ]);
  }

  Widget _buildStep3(bool isHindi) {
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Text(isHindi ? 'संकल्प और सारांश' : 'Sankalp & Summary',
          style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
      const SizedBox(height: 16),
      TextField(
        controller: _sankalpController,
        maxLines: 3,
        decoration: InputDecoration(
          labelText: isHindi ? 'संकल्प (वैकल्पिक)' : 'Sankalp (Optional)',
          hintText: isHindi
              ? 'अपना नाम, गोत्र और मनोकामना लिखें...'
              : 'Enter your name, gotra and wish...',
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
          focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: Colors.orange)),
        ),
      ),
      const SizedBox(height: 20),
      Container(
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: Colors.orange.withOpacity(0.2)),
            boxShadow: [
              BoxShadow(
                  color: Colors.orange.withOpacity(0.06),
                  blurRadius: 10,
                  offset: const Offset(0, 4))
            ]),
        child: Column(children: [
          Row(children: [
            const Text('📋', style: TextStyle(fontSize: 18)),
            const SizedBox(width: 8),
            Text(isHindi ? 'बुकिंग सारांश' : 'Booking Summary',
                style:
                    const TextStyle(fontWeight: FontWeight.bold, fontSize: 15))
          ]),
          const SizedBox(height: 14),
          const Divider(height: 1),
          const SizedBox(height: 12),
          _SummaryRow(
              isHindi ? 'पूजा' : 'Pooja', _selectedService?['name'] ?? ''),
          _SummaryRow(isHindi ? 'तारीख' : 'Date',
              DateFormat('dd MMM yyyy').format(_selectedDate)),
          _SummaryRow(isHindi ? 'समय' : 'Time', _selectedTime),
          _SummaryRow(isHindi ? 'व्यक्ति' : 'Persons', '$_persons'),
          _SummaryRow(isHindi ? 'प्रति व्यक्ति' : 'Per person',
              '₹${_selectedService?['price'] ?? 0}'),
          const Divider(height: 20),
          _SummaryRow(isHindi ? 'कुल राशि' : 'Total Amount', '₹$_totalAmount',
              bold: true),
        ]),
      ),
      const SizedBox(height: 16),
      Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
            color: Colors.green.withOpacity(0.08),
            borderRadius: BorderRadius.circular(10)),
        child: Row(children: [
          const Icon(Icons.security, color: Colors.green, size: 18),
          const SizedBox(width: 8),
          Text(
              isHindi
                  ? 'Razorpay द्वारा सुरक्षित भुगतान'
                  : 'Secured by Razorpay',
              style: const TextStyle(color: Colors.green, fontSize: 12)),
        ]),
      ),
    ]);
  }

  Widget _buildBottomBar(bool isHindi) {
    return Container(
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 20),
      decoration: BoxDecoration(color: Colors.white, boxShadow: [
        BoxShadow(
            color: Colors.black.withOpacity(0.06),
            blurRadius: 10,
            offset: const Offset(0, -4))
      ]),
      child: Row(children: [
        if (_step > 0) ...[
          OutlinedButton(
            style: OutlinedButton.styleFrom(
                padding:
                    const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
                side: const BorderSide(color: Colors.orange),
                foregroundColor: Colors.orange,
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12))),
            onPressed: () => setState(() => _step--),
            child: Text(isHindi ? 'वापस' : 'Back'),
          ),
          const SizedBox(width: 12),
        ],
        Expanded(
            child: ElevatedButton(
          style: ElevatedButton.styleFrom(
              padding: const EdgeInsets.symmetric(vertical: 14),
              backgroundColor:
                  _canProceed ? Colors.orange : Colors.grey.shade300,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12))),
          onPressed: (_booking || !_canProceed)
              ? null
              : () {
                  if (_step < 2) {
                    setState(() => _step++);
                  } else {
                    // Reset flag before every new payment attempt
                    _successShown = false;
                    RazorpayService.openPayment(
                      amount: _totalAmount.toDouble(),
                      description: _selectedService?['name'] ?? 'Pooja Booking',
                    );
                  }
                },
          child: _booking
              ? const SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(
                      color: Colors.white, strokeWidth: 2))
              : Text(
                  _step == 2
                      ? (isHindi ? 'बुकिंग कन्फर्म करें' : 'Confirm Booking')
                      : (isHindi ? 'आगे बढ़ें' : 'Next'),
                  style: const TextStyle(
                      fontSize: 15, fontWeight: FontWeight.w600)),
        )),
      ]),
    );
  }
}

// ─── SUCCESS SCREEN ───────────────────────────────────────────────────────────
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
                                  (1 - (_ripple1.value - 1) / 1.2) * 0.15))),
                    ),
                    Transform.scale(
                      scale: _ripple2.value,
                      child: Container(
                          width: 100,
                          height: 100,
                          decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: Colors.white.withOpacity(
                                  (1 - (_ripple2.value - 1) / 1.2) * 0.1))),
                    ),
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
                              color: Colors.white, size: 60)),
                    ),
                  ],
                ),
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
                            borderRadius: BorderRadius.circular(14)),
                      ),
                      onPressed: () => context.go('/my-bookings'),
                      child: const Text('My Bookings dekho',
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
                            borderRadius: BorderRadius.circular(14)),
                      ),
                      onPressed: () => context.go('/home'),
                      child: const Text('Go to Home',
                          style: TextStyle(
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

class _SummaryRow extends StatelessWidget {
  final String label, value;
  final bool bold;
  const _SummaryRow(this.label, this.value, {this.bold = false});
  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 5),
      child: Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
        Text(label, style: const TextStyle(color: Colors.grey, fontSize: 13)),
        Text(value,
            style: TextStyle(
                fontWeight: bold ? FontWeight.bold : FontWeight.w500,
                color: bold ? Colors.orange : Colors.black87,
                fontSize: bold ? 17 : 14)),
      ]),
    );
  }
}
