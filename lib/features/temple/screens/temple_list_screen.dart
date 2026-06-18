import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:Temple/features/home/screens/main_shell.dart';
import 'package:Temple/shared/services/api_service.dart';

// Image helper - checks temple object first, then name-based matching
String _templeImage(Map<String, dynamic> temple) {
  // 1. Direct image field from API/data
  if (temple['image'] != null && (temple['image'] as String).isNotEmpty) {
    final img = temple['image'] as String;
    if (!img.startsWith('http')) return img;
  }

  // 2. Name-based matching (works regardless of ID)
  final name = (temple['name'] ?? '').toString().toLowerCase();
  if (name.contains('सिद्धिविनायक') || name.contains('siddhivinayak'))
    return 'assets/images/sidhivinayak_mandir.png';
  if (name.contains('काशी') ||
      name.contains('kashi') ||
      name.contains('vishwanath')) return 'assets/images/kashi_mandir.png';
  if (name.contains('तिरुपति') ||
      name.contains('tirupati') ||
      name.contains('balaji')) return 'assets/images/tirupati_mandir.png';
  if (name.contains('द्वारका') || name.contains('dwarka'))
    return 'assets/images/dwarka_mandir.png';
  if (name.contains('वैष्णो') ||
      name.contains('vaishno') ||
      name.contains('vaishnodevi')) return 'assets/images/vaoisdevi_mandir.png';
  if (name.contains('जगन्नाथ') || name.contains('jagannath'))
    return 'assets/images/jagnath_mandir.png';
  if (name.contains('मीनाक्षी') || name.contains('meenakshi'))
    return 'assets/images/meenakshi_mandir.png';
  if (name.contains('राम') || name.contains('ram') || name.contains('ayodhya'))
    return 'assets/images/ram_mandir.png';

  // 3. ID-based fallback
  const idMap = {
    '1': 'assets/images/sidhivinayak_mandir.png',
    '2': 'assets/images/kashi_mandir.png',
    '3': 'assets/images/tirupati_mandir.png',
    '4': 'assets/images/dwarka_mandir.png',
    '5': 'assets/images/vaoisdevi_mandir.png',
    '6': 'assets/images/jagnath_mandir.png',
    '7': 'assets/images/meenakshi_mandir.png',
    '8': 'assets/images/ram_mandir.png',
  };
  return idMap[temple['id']?.toString()] ??
      'assets/images/sidhivinayak_mandir.png';
}

// Helper: get the right text based on language
String _t(Map<String, dynamic> obj, String key, bool isHindi) {
  if (!isHindi) {
    final en = obj['${key}_en'];
    if (en != null && en.toString().isNotEmpty) return en.toString();
  }
  return obj[key]?.toString() ?? '';
}

const _demoTemples = [
  {
    'id': '1',
    'name': 'श्री सिद्धिविनायक मंदिर',
    'name_en': 'Shree Siddhivinayak Temple',
    'city': 'मुंबई',
    'city_en': 'Mumbai',
    'state': 'Maharashtra',
    'deity': 'गणेश',
    'deity_en': 'Ganesh',
    'image': 'assets/images/sidhivinayak_mandir.png',
    'color': 0xFFFF6B00,
    'timings': '05:30 - 22:00',
    'services': [
      {
        'name': 'गणेश पूजा',
        'name_en': 'Ganesh Pooja',
        'duration_minutes': 30,
        'price': 151
      },
      {
        'name': 'महाआरती',
        'name_en': 'Mahaarti',
        'duration_minutes': 45,
        'price': 251
      }
    ]
  },
  {
    'id': '2',
    'name': 'श्री काशी विश्वनाथ मंदिर',
    'name_en': 'Shree Kashi Vishwanath Temple',
    'city': 'वाराणसी',
    'city_en': 'Varanasi',
    'state': 'Uttar Pradesh',
    'deity': 'शिव',
    'deity_en': 'Shiva',
    'image': 'assets/images/kashi_mandir.png',
    'color': 0xFF8B0000,
    'timings': '04:00 - 23:00',
    'services': [
      {
        'name': 'रुद्राभिषेक',
        'name_en': 'Rudrabhishek',
        'duration_minutes': 60,
        'price': 501
      },
      {
        'name': 'महामृत्युंजय जाप',
        'name_en': 'Mahamrityunjay Jaap',
        'duration_minutes': 45,
        'price': 251
      }
    ]
  },
  {
    'id': '3',
    'name': 'श्री तिरुपति बालाजी',
    'name_en': 'Shree Tirupati Balaji',
    'city': 'तिरुपति',
    'city_en': 'Tirupati',
    'state': 'Andhra Pradesh',
    'deity': 'विष्णु',
    'deity_en': 'Vishnu',
    'image': 'assets/images/tirupati_mandir.png',
    'color': 0xFF1A5276,
    'timings': '05:00 - 21:00',
    'services': [
      {
        'name': 'सत्यनारायण कथा',
        'name_en': 'Satyanarayan Katha',
        'duration_minutes': 120,
        'price': 1001
      }
    ]
  },
  {
    'id': '4',
    'name': 'श्री द्वारकाधीश मंदिर',
    'name_en': 'Shree Dwarkadhish Temple',
    'city': 'द्वारका',
    'city_en': 'Dwarka',
    'state': 'Gujarat',
    'deity': 'कृष्ण',
    'deity_en': 'Krishna',
    'image': 'assets/images/dwarka_mandir.png',
    'color': 0xFF1B5E20,
    'timings': '06:00 - 21:00',
    'services': [
      {
        'name': 'भागवत पाठ',
        'name_en': 'Bhagwat Path',
        'duration_minutes': 90,
        'price': 751
      }
    ]
  },
  {
    'id': '5',
    'name': 'श्री वैष्णो देवी मंदिर',
    'name_en': 'Shree Vaishno Devi Temple',
    'city': 'कटरा',
    'city_en': 'Katra',
    'state': 'J&K',
    'deity': 'दुर्गा',
    'deity_en': 'Durga',
    'image': 'assets/images/vaoisdevi_mandir.png',
    'color': 0xFF6B0080,
    'timings': '05:00 - 21:00',
    'services': [
      {
        'name': 'दुर्गा पूजा',
        'name_en': 'Durga Pooja',
        'duration_minutes': 60,
        'price': 401
      }
    ]
  },
  {
    'id': '6',
    'name': 'श्री जगन्नाथ मंदिर',
    'name_en': 'Shree Jagannath Temple',
    'city': 'पुरी',
    'city_en': 'Puri',
    'state': 'Odisha',
    'deity': 'विष्णु',
    'deity_en': 'Vishnu',
    'image': 'assets/images/jagnath_mandir.png',
    'color': 0xFF1A5276,
    'timings': '05:00 - 22:00',
    'services': [
      {
        'name': 'महाप्रसाद',
        'name_en': 'Mahaprasad',
        'duration_minutes': 30,
        'price': 201
      }
    ]
  },
  {
    'id': '7',
    'name': 'श्री मीनाक्षी अम्मन मंदिर',
    'name_en': 'Shree Meenakshi Amman Temple',
    'city': 'मदुरई',
    'city_en': 'Madurai',
    'state': 'Tamil Nadu',
    'deity': 'देवी',
    'deity_en': 'Devi',
    'image': 'assets/images/meenakshi_mandir.png',
    'color': 0xFFB7410E,
    'timings': '05:00 - 21:30',
    'services': [
      {
        'name': 'अभिषेकम',
        'name_en': 'Abhishekam',
        'duration_minutes': 45,
        'price': 301
      }
    ]
  },
  {
    'id': '8',
    'name': 'श्री राम जन्मभूमि मंदिर',
    'name_en': 'Shree Ram Janmabhoomi Temple',
    'city': 'अयोध्या',
    'city_en': 'Ayodhya',
    'state': 'Uttar Pradesh',
    'deity': 'राम',
    'deity_en': 'Ram',
    'image': 'assets/images/ram_mandir.png',
    'color': 0xFFFF6B00,
    'timings': '07:00 - 21:00',
    'services': [
      {
        'name': 'राम आरती',
        'name_en': 'Ram Aarti',
        'duration_minutes': 30,
        'price': 201
      }
    ]
  },
];

class TempleListScreen extends ConsumerStatefulWidget {
  const TempleListScreen({super.key});
  @override
  ConsumerState<TempleListScreen> createState() => _TempleListScreenState();
}

class _TempleListScreenState extends ConsumerState<TempleListScreen> {
  final _searchController = TextEditingController();
  List<Map<String, dynamic>> _temples = [];
  List<Map<String, dynamic>> _filtered = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _fetchTemples();
  }

  Future<void> _fetchTemples() async {
    // Pehle demo data seedha dikhao
    if (mounted) {
      setState(() {
        _temples = List<Map<String, dynamic>>.from(_demoTemples);
        _filtered = _temples;
        _loading = false;
      });
    }
    // Background mein API try karo
    try {
      final res = await ApiService().getTemples();
      final list = (res['data'] ?? res['temples'] ?? []) as List<dynamic>;
      if (mounted && list.isNotEmpty)
        setState(() {
          _temples = list.map((t) => Map<String, dynamic>.from(t)).toList();
          _filtered = _temples;
        });
    } catch (_) {}
  }

  void _onSearch(String query) {
    if (query.isEmpty) {
      setState(() => _filtered = _temples);
      return;
    }
    final q = query.toLowerCase();
    setState(() {
      _filtered = _temples
          .where((t) =>
              (t['name'] ?? '').toLowerCase().contains(q) ||
              (t['name_en'] ?? '').toLowerCase().contains(q) ||
              (t['city'] ?? '').toLowerCase().contains(q) ||
              (t['city_en'] ?? '').toLowerCase().contains(q) ||
              (t['deity'] ?? '').toLowerCase().contains(q) ||
              (t['state'] ?? '').toLowerCase().contains(q))
          .toList();
    });
  }

  @override
  Widget build(BuildContext context) {
    final lang = ref.watch(languageProvider);
    final isHindi = lang == 'hi';

    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => context.go('/home'),
        ),
        title: Text(isHindi ? 'मंदिर' : 'Temples'),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(60),
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 10),
            child: TextField(
              controller: _searchController,
              style: const TextStyle(color: Colors.white),
              decoration: InputDecoration(
                hintText: isHindi
                    ? 'शहर या मंदिर खोजें...'
                    : 'Search city or temple...',
                hintStyle: TextStyle(color: Colors.white.withOpacity(0.7)),
                prefixIcon:
                    Icon(Icons.search, color: Colors.white.withOpacity(0.8)),
                filled: true,
                fillColor: Colors.white.withOpacity(0.2),
                border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide.none),
                contentPadding: const EdgeInsets.symmetric(vertical: 10),
              ),
              onChanged: _onSearch,
            ),
          ),
        ),
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator(color: Colors.orange))
          : _filtered.isEmpty
              ? Center(
                  child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                      const Text('🛕', style: TextStyle(fontSize: 48)),
                      const SizedBox(height: 12),
                      Text(
                          '"${_searchController.text}" ${isHindi ? 'नहीं मिला' : 'not found'}',
                          style: const TextStyle(color: Colors.grey)),
                    ]))
              : RefreshIndicator(
                  onRefresh: _fetchTemples,
                  color: Colors.orange,
                  child: ListView.builder(
                    padding: const EdgeInsets.all(16),
                    itemCount: _filtered.length,
                    itemBuilder: (context, i) => _TempleCard(
                        temple: _filtered[i],
                        isHindi: isHindi,
                        onTap: () =>
                            context.go('/temples/${_filtered[i]['id']}')),
                  ),
                ),
    );
  }
}

class _TempleCard extends StatelessWidget {
  final Map<String, dynamic> temple;
  final bool isHindi;
  final VoidCallback onTap;
  const _TempleCard(
      {required this.temple, required this.isHindi, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final color = temple['color'] != null
        ? Color(temple['color'] as int)
        : const Color(0xFFFF6B00);
    final imagePath = _templeImage(temple);
    final name = _t(temple, 'name', isHindi);
    final city = _t(temple, 'city', isHindi);
    final deity = _t(temple, 'deity', isHindi);

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Row(children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(14),
              child: Image.asset(
                imagePath,
                width: 70,
                height: 70,
                fit: BoxFit.cover,
                key: ValueKey(imagePath),
                errorBuilder: (_, __, ___) => Container(
                  width: 70,
                  height: 70,
                  color: color,
                  child: const Icon(Icons.temple_hindu,
                      color: Colors.white, size: 36),
                ),
              ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(name,
                        style: const TextStyle(
                            fontWeight: FontWeight.w600, fontSize: 14),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis),
                    const SizedBox(height: 5),
                    Row(children: [
                      const Icon(Icons.location_on_outlined,
                          size: 13, color: Colors.grey),
                      const SizedBox(width: 2),
                      Text('$city, ${temple['state']}',
                          style: const TextStyle(
                              color: Colors.grey, fontSize: 12)),
                    ]),
                    const SizedBox(height: 6),
                    Row(children: [
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 8, vertical: 3),
                        decoration: BoxDecoration(
                            color: color.withOpacity(0.12),
                            borderRadius: BorderRadius.circular(20)),
                        child: Text(deity,
                            style: TextStyle(
                                fontSize: 11,
                                color: color,
                                fontWeight: FontWeight.w600)),
                      ),
                      if (temple['timings'] != null) ...[
                        const SizedBox(width: 8),
                        Icon(Icons.access_time,
                            size: 12, color: Colors.grey.shade500),
                        const SizedBox(width: 2),
                        Text(temple['timings'],
                            style: TextStyle(
                                fontSize: 11, color: Colors.grey.shade500)),
                      ],
                    ]),
                  ]),
            ),
            Icon(Icons.chevron_right, color: Colors.grey.shade400),
          ]),
        ),
      ),
    );
  }
}

class TempleDetailScreen extends ConsumerStatefulWidget {
  final String templeId;
  const TempleDetailScreen({super.key, required this.templeId});
  @override
  ConsumerState<TempleDetailScreen> createState() => _TempleDetailScreenState();
}

class _TempleDetailScreenState extends ConsumerState<TempleDetailScreen> {
  Map<String, dynamic>? _temple;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _fetchTemple();
  }

  Future<void> _fetchTemple() async {
    // Pehle demo data seedha dikhao
    final demo = _demoTemples.firstWhere(
        (t) => t['id'].toString() == widget.templeId.toString(),
        orElse: () => _demoTemples.first);
    if (mounted) {
      setState(() {
        _temple = Map<String, dynamic>.from(demo);
        _loading = false;
      });
    }
    // Background mein API try karo
    try {
      final res = await ApiService().getTemple(widget.templeId);
      if (mounted)
        setState(() {
          _temple = Map<String, dynamic>.from(res['data'] ?? res);
        });
    } catch (_) {}
  }

  @override
  Widget build(BuildContext context) {
    final lang = ref.watch(languageProvider);
    final isHindi = lang == 'hi';

    if (_loading)
      return const Scaffold(
          body: Center(child: CircularProgressIndicator(color: Colors.orange)));

    final temple = _temple!;
    final services =
        (temple['services'] as List?)?.cast<Map<String, dynamic>>() ?? [];
    final color = temple['color'] != null
        ? Color(temple['color'] as int)
        : const Color(0xFFFF6B00);
    final imagePath = _templeImage(temple);
    final city = _t(temple, 'city', isHindi);
    final deity = _t(temple, 'deity', isHindi);
    final name = _t(temple, 'name', isHindi);

    return Scaffold(
      body: CustomScrollView(
        slivers: [
          SliverAppBar(
            expandedHeight: 260,
            pinned: true,
            leading: IconButton(
                icon: const Icon(Icons.arrow_back, color: Colors.white),
                onPressed: () => context.go('/temples')),
            flexibleSpace: FlexibleSpaceBar(
              title: null,
              background: Stack(
                fit: StackFit.expand,
                children: [
                  Image.asset(
                    imagePath,
                    fit: BoxFit.cover,
                    errorBuilder: (_, __, ___) => Container(color: color),
                  ),
                  DecoratedBox(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [
                          Colors.transparent,
                          Colors.black.withOpacity(0.55)
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(children: [
                      Icon(Icons.location_on, color: color, size: 18),
                      const SizedBox(width: 6),
                      Text('$city, ${temple['state']}',
                          style:
                              const TextStyle(color: Colors.grey, fontSize: 14))
                    ]),
                    const SizedBox(height: 8),
                    Row(children: [
                      Icon(Icons.access_time, color: color, size: 18),
                      const SizedBox(width: 6),
                      Text(temple['timings'] ?? '05:00 - 21:00',
                          style:
                              const TextStyle(color: Colors.grey, fontSize: 14))
                    ]),
                    const SizedBox(height: 8),
                    Row(children: [
                      Icon(Icons.self_improvement, color: color, size: 18),
                      const SizedBox(width: 6),
                      Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 10, vertical: 3),
                          decoration: BoxDecoration(
                              color: color.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(20)),
                          child: Text(deity,
                              style: TextStyle(
                                  color: color, fontWeight: FontWeight.w600))),
                    ]),
                    const SizedBox(height: 24),
                    Row(children: [
                      Expanded(
                          child: ElevatedButton.icon(
                        icon: const Icon(Icons.book_online),
                        label: Text(isHindi ? 'पूजा बुक करें' : 'Book Pooja'),
                        style: ElevatedButton.styleFrom(
                            backgroundColor: color,
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(vertical: 12),
                            shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12))),
                        onPressed: () =>
                            context.go('/temples/${widget.templeId}/booking'),
                      )),
                      const SizedBox(width: 12),
                      Expanded(
                          child: OutlinedButton.icon(
                        icon: Icon(Icons.volunteer_activism, color: color),
                        label: Text(isHindi ? 'दान करें' : 'Donate',
                            style: TextStyle(color: color)),
                        style: OutlinedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(vertical: 12),
                            side: BorderSide(color: color),
                            shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12))),
                        onPressed: () =>
                            _showDonateDialog(context, color, isHindi),
                      )),
                    ]),
                    const SizedBox(height: 12),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton.icon(
                        icon: const Icon(Icons.live_tv, color: Colors.white),
                        label: Text(
                            isHindi ? '🔴 लाइव दर्शन' : '🔴 Live Darshan',
                            style: const TextStyle(
                                color: Colors.white,
                                fontSize: 15,
                                fontWeight: FontWeight.bold)),
                        style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.red,
                            padding: const EdgeInsets.symmetric(vertical: 14),
                            shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12))),
                        onPressed: () =>
                            context.go('/live-darshan/${widget.templeId}'),
                      ),
                    ),
                    const SizedBox(height: 28),
                    Text(isHindi ? 'पूजा सेवाएं' : 'Pooja Services',
                        style: const TextStyle(
                            fontSize: 16, fontWeight: FontWeight.bold)),
                    const SizedBox(height: 12),
                    if (services.isEmpty)
                      Text(
                          isHindi
                              ? 'कोई सेवा उपलब्ध नहीं'
                              : 'No services available',
                          style: const TextStyle(color: Colors.grey))
                    else
                      ...services.map((s) => Card(
                            margin: const EdgeInsets.only(bottom: 10),
                            elevation: 1,
                            shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12)),
                            child: ListTile(
                              leading: Container(
                                  width: 44,
                                  height: 44,
                                  decoration: BoxDecoration(
                                      color: color.withOpacity(0.1),
                                      borderRadius: BorderRadius.circular(10)),
                                  child: Icon(Icons.self_improvement,
                                      color: color)),
                              title: Text(_t(s, 'name', isHindi),
                                  style: const TextStyle(
                                      fontWeight: FontWeight.w500,
                                      fontSize: 14)),
                              subtitle: Text(
                                  '${s['duration_minutes']} ${isHindi ? 'मिनट' : 'min'}',
                                  style: const TextStyle(fontSize: 12)),
                              trailing: Text('₹${s['price']}',
                                  style: TextStyle(
                                      color: color,
                                      fontWeight: FontWeight.bold,
                                      fontSize: 16)),
                            ),
                          )),
                  ]),
            ),
          ),
        ],
      ),
    );
  }

  void _showDonateDialog(BuildContext context, Color color, bool isHindi) {
    final controller = TextEditingController();
    final templeName = _temple != null ? _t(_temple!, 'name', isHindi) : '';
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (ctx) => Padding(
        padding: EdgeInsets.fromLTRB(
            20, 20, 20, MediaQuery.of(ctx).viewInsets.bottom + 20),
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          Text('$templeName ${isHindi ? 'को दान करें' : '- Donate'}',
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              textAlign: TextAlign.center),
          const SizedBox(height: 16),
          Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [51, 101, 251, 501, 1001]
                  .map((amt) => ActionChip(
                      label: Text('₹$amt'),
                      backgroundColor: color.withOpacity(0.1),
                      labelStyle: TextStyle(color: color),
                      onPressed: () => controller.text = amt.toString()))
                  .toList()),
          const SizedBox(height: 12),
          TextField(
              controller: controller,
              keyboardType: TextInputType.number,
              decoration: InputDecoration(
                  labelText: isHindi ? 'राशि (₹)' : 'Amount (₹)',
                  prefixIcon: Icon(Icons.currency_rupee, color: color),
                  border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12)))),
          const SizedBox(height: 16),
          SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                    backgroundColor: color,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12))),
                onPressed: () {
                  Navigator.pop(ctx);
                  ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                      content: Text(isHindi
                          ? '🙏 दान के लिए धन्यवाद!'
                          : '🙏 Thank you for your donation!'),
                      backgroundColor: Colors.green));
                },
                child: Text(isHindi ? 'दान करें' : 'Donate',
                    style: const TextStyle(fontSize: 16)),
              )),
        ]),
      ),
    );
  }
}
