import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:Temple/shared/services/api_service.dart';
import 'package:Temple/features/store/screens/store_screen.dart';

class MyBookingsScreen extends ConsumerStatefulWidget {
  const MyBookingsScreen({super.key});
  @override
  ConsumerState<MyBookingsScreen> createState() => _MyBookingsScreenState();
}

class _MyBookingsScreenState extends ConsumerState<MyBookingsScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  List<dynamic> _bookings = [];
  bool _loading = true;

  // Demo bookings — API fail hone par dikhenge
  final _demoBookings = [
    {
      'id': 'demo-1',
      'sankalp': 'रुद्राभिषेक',
      'booking_date': '2025-06-20',
      'booking_time': '06:00',
      'persons': 2,
      'amount': 1002,
      'payment_id': 'pay_demo_001',
      'status': 'confirmed',
      'created_at': '2025-06-15T10:00:00',
    },
    {
      'id': 'demo-2',
      'sankalp': 'गणेश पूजा',
      'booking_date': '2025-06-18',
      'booking_time': '08:00',
      'persons': 1,
      'amount': 151,
      'payment_id': 'pay_demo_002',
      'status': 'confirmed',
      'created_at': '2025-06-14T09:00:00',
    },
  ];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _loadBookings();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _loadBookings() async {
    if (mounted) setState(() => _loading = true);
    try {
      final res = await ApiService().getMyBookings();
      final list = List<dynamic>.from(res['data'] as List<dynamic>? ?? []);
      list.sort((a, b) {
        final da = DateTime.tryParse(a['created_at'] ?? '') ?? DateTime(2000);
        final db = DateTime.tryParse(b['created_at'] ?? '') ?? DateTime(2000);
        return db.compareTo(da);
      });
      if (mounted)
        setState(() {
          // API se data aaya toh use karo, warna demo dikhao
          _bookings = list.isEmpty ? _demoBookings : list;
          _loading = false;
        });
    } catch (_) {
      // API error — demo data dikhao
      if (mounted)
        setState(() {
          _bookings = _demoBookings;
          _loading = false;
        });
    }
  }

  String _formatDate(String? raw) {
    if (raw == null || raw.isEmpty) return '—';
    final dt = DateTime.tryParse(raw);
    if (dt == null) return raw.split('T').first;
    return DateFormat('dd MMM yyyy').format(dt);
  }

  @override
  Widget build(BuildContext context) {
    final orders = ref.watch(ordersProvider);

    return Scaffold(
      backgroundColor: const Color(0xFFF5F0E8),
      appBar: AppBar(
        backgroundColor: const Color(0xFF8B2500),
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new,
              color: Colors.white, size: 20),
          onPressed: () => context.go('/home'),
        ),
        title: Text('मेरी गतिविधि',
            style: GoogleFonts.poppins(
                color: Colors.white,
                fontWeight: FontWeight.w600,
                fontSize: 18)),
        centerTitle: true,
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: Colors.white,
          labelColor: Colors.white,
          unselectedLabelColor: Colors.white60,
          labelStyle:
              GoogleFonts.poppins(fontWeight: FontWeight.w600, fontSize: 14),
          tabs: const [
            Tab(text: '🕉️ Bookings'),
            Tab(text: '🛍️ Orders'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          // ── BOOKINGS TAB ──
          _loading
              ? const Center(
                  child: CircularProgressIndicator(color: Color(0xFF8B2500)))
              : RefreshIndicator(
                  color: const Color(0xFF8B2500),
                  onRefresh: _loadBookings,
                  child: _bookings.isEmpty
                      ? ListView(
                          children: [
                            SizedBox(
                              height: MediaQuery.of(context).size.height * 0.5,
                              child: _emptyState('🕉️', 'Koi booking nahi mili',
                                  'Apna pehla pooja book karein'),
                            ),
                          ],
                        )
                      : ListView.builder(
                          padding: const EdgeInsets.fromLTRB(16, 20, 16, 32),
                          itemCount: _bookings.length,
                          itemBuilder: (context, i) => _BookingCard(
                            booking: _bookings[i],
                            isLatest: i == 0,
                            formatDate: _formatDate,
                          ),
                        ),
                ),

          // ── ORDERS TAB ──
          orders.isEmpty
              ? _emptyState(
                  '🛍️', 'Koi order nahi mila', 'Store se kuch khareedein')
              : ListView.builder(
                  padding: const EdgeInsets.fromLTRB(16, 20, 16, 32),
                  itemCount: orders.length,
                  itemBuilder: (context, i) =>
                      _OrderCard(order: orders[i], isLatest: i == 0),
                ),
        ],
      ),
    );
  }

  Widget _emptyState(String emoji, String title, String subtitle) {
    return Center(
        child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
      Text(emoji, style: const TextStyle(fontSize: 48)),
      const SizedBox(height: 16),
      Text(title,
          style: GoogleFonts.poppins(fontSize: 16, color: Colors.grey[600])),
      const SizedBox(height: 8),
      Text(subtitle,
          style: GoogleFonts.poppins(fontSize: 13, color: Colors.grey[400])),
    ]));
  }
}

// ─── BOOKING CARD ──────────────────────────────────────────────────────────────
class _BookingCard extends StatelessWidget {
  final dynamic booking;
  final bool isLatest;
  final String Function(String?) formatDate;
  const _BookingCard(
      {required this.booking,
      required this.isLatest,
      required this.formatDate});

  @override
  Widget build(BuildContext context) {
    final b = booking;
    final paymentId = b['payment_id']?.toString() ?? '';

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: isLatest
            ? Border.all(color: const Color(0xFF8B2500), width: 1.5)
            : Border.all(color: const Color(0xFFE8DDD0)),
        boxShadow: [
          BoxShadow(
              color: Colors.black.withOpacity(0.06),
              blurRadius: 10,
              offset: const Offset(0, 4))
        ],
      ),
      child: Column(children: [
        // Header
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          decoration: BoxDecoration(
            color: isLatest ? const Color(0xFF8B2500) : const Color(0xFFF5F0E8),
            borderRadius: const BorderRadius.vertical(top: Radius.circular(15)),
          ),
          child:
              Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
            Text(isLatest ? '🕉️ Latest Booking' : 'Pooja Booking',
                style: GoogleFonts.poppins(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: isLatest ? Colors.white70 : Colors.grey[500])),
            _StatusChip(status: b['status'] ?? 'pending', isLatest: isLatest),
          ]),
        ),
        // Body
        Padding(
          padding: const EdgeInsets.all(16),
          child:
              Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(
                b['sankalp']?.toString().isNotEmpty == true
                    ? b['sankalp'].toString()
                    : 'Pooja Booking',
                style: GoogleFonts.poppins(
                    fontWeight: FontWeight.w700,
                    fontSize: 17,
                    color: const Color(0xFF1A0A00))),
            const SizedBox(height: 12),
            _Row(Icons.calendar_today_outlined, 'Date',
                formatDate(b['booking_date'])),
            const _HDivider(),
            _Row(Icons.access_time_outlined, 'Time', b['booking_time'] ?? '—'),
            const _HDivider(),
            _Row(Icons.people_outline, 'Persons', '${b['persons'] ?? 1}'),
            const _HDivider(),
            const SizedBox(height: 4),
            Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
              Text('Amount Paid',
                  style: GoogleFonts.poppins(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: Colors.grey[700])),
              Text('₹${b['amount'] ?? '—'}',
                  style: GoogleFonts.poppins(
                      fontSize: 22,
                      fontWeight: FontWeight.w800,
                      color: const Color(0xFF8B2500))),
            ]),
          ]),
        ),
        if (paymentId.isNotEmpty)
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            decoration: const BoxDecoration(
                color: Color(0xFFF5F0E8),
                borderRadius:
                    BorderRadius.vertical(bottom: Radius.circular(15))),
            child: Text('Txn: $paymentId',
                style: GoogleFonts.robotoMono(
                    fontSize: 11, color: Colors.grey[500]),
                overflow: TextOverflow.ellipsis),
          )
        else
          const SizedBox(height: 4),
      ]),
    );
  }
}

// ─── ORDER CARD ────────────────────────────────────────────────────────────────
class _OrderCard extends StatelessWidget {
  final Map<String, dynamic> order;
  final bool isLatest;
  const _OrderCard({required this.order, required this.isLatest});

  @override
  Widget build(BuildContext context) {
    final items = (order['items'] as List?) ?? [];
    final date = DateTime.tryParse(order['date'] ?? '');
    final dateStr =
        date != null ? DateFormat('dd MMM yyyy, hh:mm a').format(date) : '—';

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: isLatest
            ? Border.all(color: Colors.orange, width: 1.5)
            : Border.all(color: const Color(0xFFE8DDD0)),
        boxShadow: [
          BoxShadow(
              color: Colors.black.withOpacity(0.06),
              blurRadius: 10,
              offset: const Offset(0, 4))
        ],
      ),
      child: Column(children: [
        // Header
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          decoration: BoxDecoration(
            color: isLatest ? Colors.orange : const Color(0xFFFFF3E0),
            borderRadius: const BorderRadius.vertical(top: Radius.circular(15)),
          ),
          child:
              Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
            Text(isLatest ? '🛍️ Latest Order' : '🛍️ Order',
                style: GoogleFonts.poppins(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: isLatest ? Colors.white : Colors.orange[700])),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                  color: isLatest ? Colors.white : Colors.green[50],
                  borderRadius: BorderRadius.circular(20)),
              child: Text('✅ Confirmed',
                  style: GoogleFonts.poppins(
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                      color: Colors.green[700])),
            ),
          ]),
        ),
        // Items
        Padding(
          padding: const EdgeInsets.all(16),
          child:
              Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            ...items.map((item) => Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: Row(children: [
                    Text(item['emoji'] ?? '🪔',
                        style: const TextStyle(fontSize: 22)),
                    const SizedBox(width: 10),
                    Expanded(
                        child: Text(item['nameEn'] ?? item['name'] ?? '',
                            style: GoogleFonts.poppins(
                                fontWeight: FontWeight.w500, fontSize: 13))),
                    Text('₹${item['price']}',
                        style: GoogleFonts.poppins(
                            color: Colors.orange, fontWeight: FontWeight.w600)),
                  ]),
                )),
            const Divider(),
            Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
              Text('Total',
                  style: GoogleFonts.poppins(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: Colors.grey[700])),
              Text('₹${order['total']}',
                  style: GoogleFonts.poppins(
                      fontSize: 22,
                      fontWeight: FontWeight.w800,
                      color: Colors.orange)),
            ]),
          ]),
        ),
        // Footer
        Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
          decoration: const BoxDecoration(
              color: Color(0xFFFFF8F0),
              borderRadius: BorderRadius.vertical(bottom: Radius.circular(15))),
          child:
              Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text('📅 $dateStr',
                style:
                    GoogleFonts.poppins(fontSize: 11, color: Colors.grey[500])),
            if ((order['payment_id'] ?? '').isNotEmpty)
              Text('Txn: ${order['payment_id']}',
                  style: GoogleFonts.robotoMono(
                      fontSize: 11, color: Colors.grey[500]),
                  overflow: TextOverflow.ellipsis),
          ]),
        ),
      ]),
    );
  }
}

// ─── HELPERS ──────────────────────────────────────────────────────────────────
class _StatusChip extends StatelessWidget {
  final String status;
  final bool isLatest;
  const _StatusChip({required this.status, required this.isLatest});

  @override
  Widget build(BuildContext context) {
    final isConfirmed = status == 'confirmed';
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: isConfirmed
            ? (isLatest ? Colors.white : Colors.green[50])
            : Colors.orange[50],
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(isConfirmed ? '✅ Confirmed' : '⏳ Pending',
          style: GoogleFonts.poppins(
              fontSize: 11,
              fontWeight: FontWeight.w600,
              color: isConfirmed ? Colors.green[700] : Colors.orange[800])),
    );
  }
}

class _Row extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  const _Row(this.icon, this.label, this.value);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(children: [
        Icon(icon, size: 16, color: const Color(0xFF8B2500)),
        const SizedBox(width: 10),
        Text(label,
            style: GoogleFonts.poppins(fontSize: 13, color: Colors.grey[500])),
        const Spacer(),
        Text(value,
            style: GoogleFonts.poppins(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: const Color(0xFF1A0A00))),
      ]),
    );
  }
}

class _HDivider extends StatelessWidget {
  const _HDivider();
  @override
  Widget build(BuildContext context) =>
      Container(height: 1, color: const Color(0xFFF0E8DC));
}
