import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:Temple/features/home/screens/main_shell.dart';
import 'package:Temple/shared/services/api_service.dart';

String _templeImage(Map<String, dynamic> temple) {
  final name = (temple['name'] ?? '').toString().toLowerCase();
  if (name.contains('सिद्धिविनायक') || name.contains('siddhivinayak'))
    return 'assets/images/sidhivinayak_mandir.png';
  if (name.contains('काशी') ||
      name.contains('kashi') ||
      name.contains('vishwanath')) return 'assets/images/kashi_mandir.png';
  if (name.contains('तिरुपति') || name.contains('tirupati'))
    return 'assets/images/tirupati_mandir.png';
  if (name.contains('वैष्णो') || name.contains('vaishno'))
    return 'assets/images/vaoisdevi_mandir.png';
  if (name.contains('सोमनाथ') || name.contains('somnath'))
    return 'assets/images/sidhivinayak_mandir.png';
  if (name.contains('द्वारका') || name.contains('dwarka'))
    return 'assets/images/dwarka_mandir.png';
  if (name.contains('जगन्नाथ') || name.contains('jagannath'))
    return 'assets/images/jagnath_mandir.png';
  if (name.contains('मीनाक्षी') || name.contains('meenakshi'))
    return 'assets/images/meenakshi_mandir.png';
  if (name.contains('राम') || name.contains('ram'))
    return 'assets/images/ram_mandir.png';
  return 'assets/images/mandir.jpg';
}

class HomeScreen extends ConsumerStatefulWidget {
  const HomeScreen({super.key});
  @override
  ConsumerState<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends ConsumerState<HomeScreen>
    with TickerProviderStateMixin {
  String _userName = '';
  List<Map<String, dynamic>> _temples = [];
  bool _loadingTemples = true;
  late PageController _bannerController;
  int _currentBanner = 0;
  Timer? _bannerTimer;
  List<AnimationController> _animControllers = [];
  List<Animation<double>> _scaleAnims = [];

  final List<Map<String, dynamic>> _fallbackTemples = [
    {
      'id': '1',
      'name': 'श्री सिद्धिविनायक',
      'city': 'मुंबई',
      'deity': 'गणेश',
      'color': 0xFFFF6B00
    },
    {
      'id': '2',
      'name': 'काशी विश्वनाथ',
      'city': 'वाराणसी',
      'deity': 'शिव',
      'color': 0xFF8B0000
    },
    {
      'id': '3',
      'name': 'तिरुपति बालाजी',
      'city': 'तिरुपति',
      'deity': 'विष्णु',
      'color': 0xFF1A5276
    },
    {
      'id': '4',
      'name': 'वैष्णो देवी',
      'city': 'कटरा',
      'deity': 'दुर्गा',
      'color': 0xFF6B0080
    },
    {
      'id': '5',
      'name': 'सोमनाथ मंदिर',
      'city': 'सोमनाथ',
      'deity': 'शिव',
      'color': 0xFF1B5E20
    },
  ];

  @override
  void initState() {
    super.initState();
    _bannerController = PageController();
    _loadData();

    // Scale animation — subtle zoom-in on each banner
    _animControllers = List.generate(
        4,
        (i) => AnimationController(
              vsync: this,
              duration: const Duration(milliseconds: 800),
            ));
    _scaleAnims = _animControllers
        .map((c) => Tween<double>(begin: 1.05, end: 1.0)
            .animate(CurvedAnimation(parent: c, curve: Curves.easeOut)))
        .toList();

    _animControllers[0].forward();

    _bannerTimer = Timer.periodic(const Duration(seconds: 3), (_) {
      if (!mounted) return;
      final next = _bannerController.page!.round() + 1;
      _bannerController.animateToPage(next,
          duration: const Duration(milliseconds: 600), curve: Curves.easeInOut);
    });
  }

  @override
  void dispose() {
    _bannerTimer?.cancel();
    _bannerController.dispose();
    for (final c in _animControllers) c.dispose();
    super.dispose();
  }

  String _getGreeting(bool isHindi) {
    final hour = DateTime.now().hour;
    if (hour >= 5 && hour < 12) return isHindi ? 'शुभ प्रभात' : 'Good Morning';
    if (hour >= 12 && hour < 17)
      return isHindi ? 'शुभ दोपहर' : 'Good Afternoon';
    if (hour >= 17 && hour < 21)
      return isHindi ? 'शुभ संध्या ' : 'Good Evening';
    return isHindi ? 'शुभ रात्रि' : 'Good Night';
  }

  Future<void> _loadData() async => Future.wait([_loadUser(), _loadTemples()]);

  Future<void> _loadUser() async {
    try {
      final res = await ApiService().getMe();
      final data = res['data'] ?? res;
      if (mounted)
        setState(() =>
            _userName = (data['full_name'] as String?)?.split(' ').first ?? '');
    } catch (_) {}
  }

  Future<void> _loadTemples() async {
    try {
      final res = await ApiService().getTemples();
      final list = (res['data'] ?? res['temples'] ?? []) as List<dynamic>;
      if (mounted)
        setState(() {
          _temples = list
              .take(5)
              .map((t) => {
                    'id': t['id']?.toString() ?? '',
                    'name': t['name'] ?? '',
                    'city': t['city'] ?? '',
                    'deity': t['deity'] ?? '',
                    'color': _colorForDeity(t['deity'] ?? ''),
                  })
              .toList();
          _loadingTemples = false;
        });
    } catch (_) {
      if (mounted)
        setState(() {
          _temples = _fallbackTemples;
          _loadingTemples = false;
        });
    }
  }

  int _colorForDeity(String d) {
    switch (d) {
      case 'गणेश':
      case 'Ganesh':
        return 0xFFFF6B00;
      case 'शिव':
      case 'Shiv':
      case 'Shiva':
        return 0xFF8B0000;
      case 'विष्णु':
      case 'Vishnu':
        return 0xFF1A5276;
      case 'दुर्गा':
      case 'Durga':
        return 0xFF6B0080;
      default:
        return 0xFF1B5E20;
    }
  }

  // ══════════════════════════════════════════════════════════
  @override
  Widget build(BuildContext context) {
    final lang = ref.watch(languageProvider);
    final isHindi = lang == 'hi';
    final userName =
        _userName.isNotEmpty ? _userName : (isHindi ? 'भक्त जी' : 'Devotee');

    final services = [
      {
        'image': 'assets/images/mandir.jpg',
        'label': isHindi ? 'मंदिर' : 'Temple',
        'route': '/temples'
      },
      {
        'image': 'assets/images/pooja.jpg',
        'label': isHindi ? 'पूजा' : 'Pooja',
        'route': '/pooja'
      },
      {
        'image': 'assets/images/prasad.jpg',
        'label': isHindi ? 'प्रसाद' : 'Prasad',
        'route': '/store'
      },
      {
        'image': 'assets/images/sadhana.jpg',
        'label': isHindi ? 'साधना' : 'Sadhana',
        'route': '/sadhana'
      },
      {
        'image': 'assets/images/jyotish.jpg',
        'label': isHindi ? 'ज्योतिष' : 'Astrology',
        'route': '/astrology'
      },
      {
        'image': 'assets/images/daan.jpg',
        'label': isHindi ? 'दान' : 'Donate',
        'route': '/wallet'
      },
    ];

    return Scaffold(
      backgroundColor: const Color(0xFFFFF8F0),
      body: RefreshIndicator(
        color: Colors.orange,
        onRefresh: _loadData,
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildHeader(isHindi, userName),
              _buildMuhurat(isHindi),
              _buildSectionTitle(isHindi ? 'सेवाएं' : 'Services',
                  isHindi ? 'और देखें' : 'View All', null),
              _buildServicesGrid(services),
              _buildCarouselBanners(isHindi),
              _buildShloka(isHindi),
              const SizedBox(height: 30),
            ],
          ),
        ),
      ),
    );
  }

  // ─── HEADER ────────────────────────────────────────────────
  Widget _buildHeader(bool isHindi, String userName) {
    return Container(
      width: double.infinity,
      decoration: const BoxDecoration(
        image: DecorationImage(
          image: AssetImage('assets/images/header_bg.jpg'),
          fit: BoxFit.cover,
          colorFilter: ColorFilter.mode(Colors.black54, BlendMode.darken),
        ),
      ),
      child: SafeArea(
        bottom: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 12, 20, 20),
          child:
              Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
              Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text(_getGreeting(isHindi),
                    style:
                        TextStyle(color: Colors.orange.shade200, fontSize: 13)),
                const SizedBox(height: 2),
                Text(userName,
                    style: const TextStyle(
                        color: Colors.white,
                        fontSize: 24,
                        fontWeight: FontWeight.bold)),
              ]),
              GestureDetector(
                onTap: () {
                  final isH = ref.read(languageProvider) == 'hi';
                  showMenu(
                    context: context,
                    position: const RelativeRect.fromLTRB(1000, 80, 16, 0),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12)),
                    items: [
                      PopupMenuItem(
                        onTap: () =>
                            Future.microtask(() => context.go('/my-bookings')),
                        child: Row(children: [
                          const Icon(Icons.book_online, color: Colors.orange),
                          const SizedBox(width: 10),
                          Text(isH ? 'मेरी बुकिंग' : 'My Bookings'),
                        ]),
                      ),
                      PopupMenuItem(
                        onTap: () async {
                          await ApiService().clearToken();
                          if (context.mounted) context.go('/home');
                        },
                        child: Row(children: [
                          const Icon(Icons.logout, color: Colors.red),
                          const SizedBox(width: 10),
                          Text(isH ? 'लॉगआउट' : 'Logout',
                              style: const TextStyle(color: Colors.red)),
                        ]),
                      ),
                    ],
                  );
                },
                child: Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(color: Colors.orange, width: 2),
                    color: Colors.orange.withOpacity(0.2),
                  ),
                  child: const Center(
                      child: Text('🕉️', style: TextStyle(fontSize: 20))),
                ),
              ),
            ]),
          ]),
        ),
      ),
    );
  }

  // ─── MUHURAT ────────────────────────────────────────────────
  Widget _buildMuhurat(bool isHindi) {
    return Container(
      margin: const EdgeInsets.fromLTRB(16, 16, 16, 0),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
            colors: [Color(0xFFFFD700), Color(0xFFFF8C00)]),
        borderRadius: BorderRadius.circular(14),
        boxShadow: [
          BoxShadow(
              color: Colors.orange.withOpacity(0.3),
              blurRadius: 10,
              offset: const Offset(0, 4))
        ],
      ),
      child: Row(children: [
        const Text('🌅', style: TextStyle(fontSize: 28)),
        const SizedBox(width: 12),
        Expanded(
            child:
                Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(isHindi ? 'आज का शुभ मुहूर्त' : "Today's Auspicious Time",
              style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: 14)),
          Text('Morning 6:00–8:30  |  Evening 5:00–7:00',
              style: TextStyle(
                  color: Colors.white.withOpacity(0.9), fontSize: 11)),
        ])),
        GestureDetector(
          onTap: () => context.go('/astrology'),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
            decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.3),
                borderRadius: BorderRadius.circular(20)),
            child: Text(isHindi ? 'देखें' : 'View',
                style: const TextStyle(
                    color: Colors.white,
                    fontSize: 12,
                    fontWeight: FontWeight.bold)),
          ),
        ),
      ]),
    );
  }

  // ─── SECTION TITLE ──────────────────────────────────────────
  Widget _buildSectionTitle(String title, String action, String? route) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 18, 16, 10),
      child: Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
        Text(title,
            style: const TextStyle(
                fontSize: 17,
                fontWeight: FontWeight.bold,
                color: Color(0xFF1A0A00))),
        GestureDetector(
          onTap: route != null ? () => context.go(route) : null,
          child: Text(action,
              style: TextStyle(fontSize: 12, color: Colors.orange.shade700)),
        ),
      ]),
    );
  }

  // ─── SERVICES GRID ──────────────────────────────────────────
  Widget _buildServicesGrid(List<Map<String, dynamic>> services) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: LayoutBuilder(builder: (context, constraints) {
        final cardSize = (constraints.maxWidth - 20) / 3 - 2;
        return Wrap(
          spacing: 10,
          runSpacing: 10,
          children: List.generate(services.length, (i) {
            final s = services[i];
            return GestureDetector(
              onTap: () => context.go(s['route'] as String),
              child: SizedBox(
                  width: cardSize,
                  child: Column(children: [
                    ClipRRect(
                      borderRadius: BorderRadius.circular(14),
                      child: Image.asset(s['image'] as String,
                          fit: BoxFit.cover, width: cardSize, height: cardSize),
                    ),
                    const SizedBox(height: 5),
                    Text(s['label'] as String,
                        style: const TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: Color(0xFF1A0A00))),
                  ])),
            );
          }),
        );
      }),
    );
  }

  // ─── ANIMATED CAROUSEL BANNERS ──────────────────────────────
  // Images (1.png–4.png) already have text & design baked in.
  // We only add a subtle Ken-Burns zoom animation + dot indicators.
  Widget _buildCarouselBanners(bool isHindi) {
    final banners = [
      {'image': 'assets/images/1.png', 'route': '/pooja'},
      {'image': 'assets/images/2.png', 'route': '/store'},
      {'image': 'assets/images/3.png', 'route': '/wallet'},
      {'image': 'assets/images/4.png', 'route': '/astrology'},
    ];

    return Column(children: [
      const SizedBox(height: 16),
      SizedBox(
        height: 200,
        child: PageView.builder(
          controller: _bannerController,
          itemCount: 99999,
          onPageChanged: (i) {
            final idx = i % banners.length;
            setState(() => _currentBanner = idx);
            _animControllers[idx % _animControllers.length].reset();
            _animControllers[idx % _animControllers.length].forward();
          },
          itemBuilder: (ctx, i) {
            final b = banners[i % banners.length];
            return GestureDetector(
              onTap: () => context.go(b['route']!),
              child: ScaleTransition(
                scale: _scaleAnims[i % _scaleAnims.length],
                child: Image.asset(
                  b['image']!,
                  width: double.infinity,
                  height: 200,
                  fit: BoxFit.cover,
                  errorBuilder: (_, __, ___) => Container(
                    color: Colors.orange.shade100,
                    child: const Center(
                        child: Icon(Icons.image_not_supported,
                            color: Colors.orange)),
                  ),
                ),
              ),
            );
          },
        ),
      ),
      const SizedBox(height: 10),
      // Animated dot indicators
      Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: List.generate(banners.length, (i) {
          final active = _currentBanner == i;
          return AnimatedContainer(
            duration: const Duration(milliseconds: 300),
            curve: Curves.easeInOut,
            margin: const EdgeInsets.symmetric(horizontal: 3),
            width: active ? 24 : 6,
            height: 6,
            decoration: BoxDecoration(
              color: active ? Colors.orange : Colors.grey.shade300,
              borderRadius: BorderRadius.circular(3),
            ),
          );
        }),
      ),
    ]);
  }

  // ─── TEMPLES LIST ───────────────────────────────────────────
  Widget _buildTemplesList() {
    if (_loadingTemples) {
      return const SizedBox(
          height: 178,
          child:
              Center(child: CircularProgressIndicator(color: Colors.orange)));
    }
    return SizedBox(
      height: 178,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        itemCount: _temples.length,
        itemBuilder: (context, i) {
          final t = _temples[i];
          return GestureDetector(
            onTap: () => context.go('/temples/${t['id']}'),
            child: Container(
              width: 135,
              height: 178,
              margin: const EdgeInsets.only(right: 12),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(18),
                gradient: LinearGradient(
                  colors: [
                    Color(t['color'] as int),
                    Color(t['color'] as int).withOpacity(0.75)
                  ],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                boxShadow: [
                  BoxShadow(
                      color: Color(t['color'] as int).withOpacity(0.4),
                      blurRadius: 10,
                      offset: const Offset(0, 4))
                ],
              ),
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    ClipRRect(
                      borderRadius: BorderRadius.circular(10),
                      child: Image.asset(_templeImage(t),
                          width: double.infinity,
                          height: 65,
                          fit: BoxFit.cover,
                          errorBuilder: (_, __, ___) =>
                              const Text('🛕', style: TextStyle(fontSize: 30))),
                    ),
                    const SizedBox(height: 6),
                    Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(t['name'] as String,
                              style: const TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 12),
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis),
                          const SizedBox(height: 4),
                          Row(children: [
                            const Icon(Icons.location_on,
                                color: Colors.white70, size: 11),
                            Text(t['city'] as String,
                                style: const TextStyle(
                                    color: Colors.white70, fontSize: 10)),
                          ]),
                          const SizedBox(height: 4),
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 6, vertical: 2),
                            decoration: BoxDecoration(
                                color: Colors.white.withOpacity(0.2),
                                borderRadius: BorderRadius.circular(8)),
                            child: Text(t['deity'] as String,
                                style: const TextStyle(
                                    color: Colors.white, fontSize: 10)),
                          ),
                        ]),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  // ─── SHLOKA ─────────────────────────────────────────────────
  Widget _buildShloka(bool isHindi) {
    final shlokas = [
      {
        'shloka':
            'कर्मण्येवाधिकारस्ते मा फलेषु कदाचन।\nमा कर्मफलहेतुर्भूर्मा ते सङ्गोऽस्त्वकर्मणि॥',
        'meaning':
            'Do your duty without attachment to results.\nThis is the essence of the Gita.',
        'source': '— Bhagavad Gita 2.47',
      },
      {
        'shloka':
            'यदा यदा हि धर्मस्य ग्लानिर्भवति भारत।\nअभ्युत्थानमधर्मस्य तदात्मानं सृजाम्यहम्॥',
        'meaning':
            'Whenever righteousness declines, I manifest myself.\nTo protect the good and destroy evil.',
        'source': '— Bhagavad Gita 4.7',
      },
      {
        'shloka':
            'सर्वधर्मान्परित्यज्य मामेकं शरणं व्रज।\nअहं त्वां सर्वपापेभ्यो मोक्षयिष्यामि मा शुचः॥',
        'meaning':
            'Abandon all duties and surrender unto me alone.\nI shall liberate you from all sins, do not grieve.',
        'source': '— Bhagavad Gita 18.66',
      },
      {
        'shloka': 'वासांसि जीर्णानि यथा विहाय\nनवानि गृह्णाति नरोऽपराणि।',
        'meaning':
            'Just as a person puts on new garments,\ngiving up old ones, the soul accepts new bodies.',
        'source': '— Bhagavad Gita 2.22',
      },
      {
        'shloka': 'नायमात्मा बलहीनेन लभ्यो\nन च प्रमादात् तपसो वाप्यलिङ्गात्।',
        'meaning':
            'The Self cannot be attained by the weak,\nnor by the careless, nor by wrong austerity.',
        'source': '— Mundaka Upanishad',
      },
      {
        'shloka': 'अहिंसा परमो धर्मः\nधर्म हिंसा तथैव च।',
        'meaning':
            'Non-violence is the highest virtue,\nso too is violence in service of righteousness.',
        'source': '— Mahabharata',
      },
      {
        'shloka': 'सत्यमेव जयते नानृतं\nसत्येन पन्था विततो देवयानः।',
        'meaning':
            'Truth alone triumphs, not falsehood.\nThrough truth the divine path is spread out.',
        'source': '— Mundaka Upanishad 3.1.6',
      },
    ];
    final today = DateTime.now();
    final index = (today.year + today.month + today.day) % shlokas.length;
    final shloka = shlokas[index];
    return Container(
      margin: const EdgeInsets.fromLTRB(16, 16, 16, 0),
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: Colors.orange.withOpacity(0.2)),
        boxShadow: [
          BoxShadow(
              color: Colors.orange.withOpacity(0.08),
              blurRadius: 12,
              offset: const Offset(0, 4))
        ],
      ),
      child: Column(children: [
        Row(children: [
          const SizedBox(width: 8),
          Text(isHindi ? 'आज का श्लोक' : "Today's Shloka",
              style: TextStyle(
                  fontWeight: FontWeight.bold,
                  color: Colors.orange.shade800,
                  fontSize: 15)),
        ]),
        const SizedBox(height: 12),
        Text(
          isHindi ? shloka['shloka']! : shloka['meaning']!,
          textAlign: TextAlign.center,
          style: const TextStyle(
              fontSize: 15, height: 1.6, color: Color(0xFF1A0A00)),
        ),
        const SizedBox(height: 8),
        Text(
          isHindi ? shloka['meaning']! : shloka['source']!,
          textAlign: TextAlign.center,
          style:
              TextStyle(fontSize: 12, color: Colors.grey.shade600, height: 1.5),
        ),
        const SizedBox(height: 6),
        if (isHindi)
          Text(shloka['source']!,
              style: TextStyle(
                  fontSize: 12,
                  color: Colors.orange.shade600,
                  fontStyle: FontStyle.italic)),
      ]),
    );
  }
}
