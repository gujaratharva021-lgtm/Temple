import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:Temple/features/home/screens/main_shell.dart';
import 'package:Temple/shared/services/api_service.dart';
import 'package:intl/intl.dart';

class SadhanaScreen extends ConsumerStatefulWidget {
  const SadhanaScreen({super.key});
  @override
  ConsumerState<SadhanaScreen> createState() => _SadhanaScreenState();
}

class _SadhanaScreenState extends ConsumerState<SadhanaScreen>
    with TickerProviderStateMixin {
  late TabController _tabController;

  List<Map<String, dynamic>> _mantras = [];
  List<Map<String, dynamic>> _practices = [];
  List<Map<String, dynamic>> _festivals = [];
  Map<String, dynamic>? _todayShloka;
  Map<String, bool> _todayLog = {};

  bool _loadingMantras = true;
  bool _loadingPractices = true;
  bool _loadingFestivals = true;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _loadAll();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _loadAll() async {
    _loadMantras();
    _loadPractices();
    _loadFestivals();
    _loadShloka();
    _loadTodayLog();
  }

  Future<void> _loadMantras() async {
    try {
      final res = await ApiService().getMantras();
      final list = (res['data'] as List?) ?? [];
      if (mounted)
        setState(() {
          _mantras = list.cast<Map<String, dynamic>>();
          _loadingMantras = false;
        });
    } catch (_) {
      if (mounted) setState(() => _loadingMantras = false);
    }
  }

  Future<void> _loadPractices() async {
    try {
      final res = await ApiService().getPractices();
      final list = (res['data'] as List?) ?? [];
      if (mounted)
        setState(() {
          _practices = list.cast<Map<String, dynamic>>();
          _loadingPractices = false;
        });
    } catch (_) {
      if (mounted) setState(() => _loadingPractices = false);
    }
  }

  Future<void> _loadFestivals() async {
    try {
      final res = await ApiService().getFestivals();
      final list = (res['data'] as List?) ?? [];
      if (mounted)
        setState(() {
          _festivals = list.cast<Map<String, dynamic>>();
          _loadingFestivals = false;
        });
    } catch (_) {
      if (mounted) setState(() => _loadingFestivals = false);
    }
  }

  Future<void> _loadShloka() async {
    try {
      final res = await ApiService().getTodayShloka();
      if (mounted) setState(() => _todayShloka = res['data']);
    } catch (_) {}
  }

  Future<void> _loadTodayLog() async {
    try {
      final res = await ApiService().getTodayLog();
      final data = res['data'] as Map<String, dynamic>? ?? {};
      if (mounted)
        setState(() => _todayLog = data.map((k, v) => MapEntry(k, v as bool)));
    } catch (_) {}
  }

  Future<void> _togglePractice(String key) async {
    final current = _todayLog[key] ?? false;
    setState(() => _todayLog[key] = !current);
    try {
      await ApiService().logPractice(key, !current);
    } catch (_) {
      // Revert on failure
      if (mounted) setState(() => _todayLog[key] = current);
    }
  }

  int get _completedCount => _todayLog.values.where((v) => v).length;

  void _showMantraJapa(
      BuildContext context, Map<String, dynamic> mantra, bool isHindi) {
    int count = 0;
    final color = _hexToColor(mantra['color'] ?? '#FF8C00');
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => StatefulBuilder(
        builder: (ctx, setModal) => Container(
          height: MediaQuery.of(context).size.height * 0.75,
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [color.withOpacity(0.95), color.withOpacity(0.75)],
            ),
            borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
          ),
          child: Column(children: [
            const SizedBox(height: 12),
            Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                    color: Colors.white38,
                    borderRadius: BorderRadius.circular(2))),
            const SizedBox(height: 24),
            Text(
              isHindi
                  ? (mantra['name_hi'] ?? mantra['name'] ?? '')
                  : (mantra['name'] ?? ''),
              style: const TextStyle(
                  color: Colors.white,
                  fontSize: 22,
                  fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 24),
            Container(
              margin: const EdgeInsets.symmetric(horizontal: 24),
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.15),
                borderRadius: BorderRadius.circular(16),
              ),
              child: Text(
                mantra['text'] ?? '',
                textAlign: TextAlign.center,
                style: const TextStyle(
                    color: Colors.white,
                    fontSize: 18,
                    height: 1.8,
                    fontWeight: FontWeight.w500),
              ),
            ),
            const Spacer(),
            Text('$count / ${mantra['japa_count'] ?? 108}',
                style: const TextStyle(
                    color: Colors.white,
                    fontSize: 48,
                    fontWeight: FontWeight.bold)),
            Text(isHindi ? 'जप' : 'Japa count',
                style: TextStyle(
                    color: Colors.white.withOpacity(0.8), fontSize: 14)),
            const SizedBox(height: 24),
            GestureDetector(
              onTap: () => setModal(() => count++),
              child: Container(
                width: 80,
                height: 80,
                decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: Colors.white,
                    boxShadow: const [
                      BoxShadow(
                          color: Colors.black26,
                          blurRadius: 12,
                          spreadRadius: 2)
                    ]),
                child: Icon(Icons.touch_app, size: 36, color: color),
              ),
            ),
            const SizedBox(height: 8),
            Text(isHindi ? 'स्पर्श करें' : 'Tap to count',
                style: TextStyle(
                    color: Colors.white.withOpacity(0.7), fontSize: 12)),
            const SizedBox(height: 32),
          ]),
        ),
      ),
    );
  }

  Color _hexToColor(String hex) {
    try {
      return Color(int.parse(hex.replaceFirst('#', '0xFF')));
    } catch (_) {
      return Colors.orange;
    }
  }

  @override
  Widget build(BuildContext context) {
    final lang = ref.watch(languageProvider);
    final isHindi = lang == 'hi';

    return Scaffold(
      backgroundColor: const Color(0xFFFFF8F0),
      body: NestedScrollView(
        headerSliverBuilder: (_, __) => [
          SliverAppBar(
            expandedHeight: 200,
            pinned: true,
            backgroundColor: const Color(0xFFB8621C),
            title: Text(isHindi ? 'साधना' : 'Sadhana',
                style: const TextStyle(
                    color: Colors.white, fontWeight: FontWeight.bold)),
            centerTitle: true,
            leading: IconButton(
              icon: const Icon(Icons.arrow_back, color: Colors.white),
              onPressed: () => context.go('/home'),
            ),
            flexibleSpace: FlexibleSpaceBar(
              background: Container(
                decoration: const BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [Color(0xFFD4501A), Color(0xFF8B3A0F)],
                  ),
                ),
                child: Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const SizedBox(height: 20),
                      const Text('🕉️', style: TextStyle(fontSize: 40)),
                      const SizedBox(height: 4),
                      Text(
                        isHindi ? 'आज की साधना' : "Today's Practice",
                        style: TextStyle(
                            color: Colors.white.withOpacity(0.85),
                            fontSize: 13),
                      ),
                      Text(
                        '$_completedCount / ${_practices.length}',
                        style: const TextStyle(
                            color: Colors.white,
                            fontSize: 20,
                            fontWeight: FontWeight.bold),
                      ),
                    ],
                  ),
                ),
              ),
            ),
            bottom: PreferredSize(
              preferredSize: const Size.fromHeight(44),
              child: TabBar(
                controller: _tabController,
                indicatorColor: Colors.white,
                labelColor: Colors.white,
                unselectedLabelColor: Colors.white60,
                labelStyle:
                    const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                tabs: [
                  Tab(text: isHindi ? 'मंत्र' : 'Mantras'),
                  Tab(text: isHindi ? 'अभ्यास' : 'Practice'),
                  Tab(text: isHindi ? 'पंचांग' : 'Calendar'),
                ],
              ),
            ),
          ),
        ],
        body: TabBarView(
          controller: _tabController,
          children: [
            // ── MANTRAS TAB ──
            _loadingMantras
                ? const Center(
                    child: CircularProgressIndicator(color: Color(0xFFB8621C)))
                : _mantras.isEmpty
                    ? _emptyState('📿',
                        isHindi ? 'कोई मंत्र नहीं मिला' : 'No mantras found')
                    : ListView.builder(
                        padding: const EdgeInsets.all(16),
                        itemCount: _mantras.length,
                        itemBuilder: (_, i) => _MantraCard(
                          mantra: _mantras[i],
                          isHindi: isHindi,
                          onTap: () =>
                              _showMantraJapa(context, _mantras[i], isHindi),
                          hexToColor: _hexToColor,
                        ),
                      ),

            // ── PRACTICE TAB ──
            _loadingPractices
                ? const Center(
                    child: CircularProgressIndicator(color: Color(0xFFB8621C)))
                : ListView(
                    padding: const EdgeInsets.all(16),
                    children: [
                      // Progress card
                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          gradient: const LinearGradient(
                            colors: [Color(0xFFD4501A), Color(0xFF8B3A0F)],
                          ),
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                isHindi ? 'आज की प्रगति' : "Today's Progress",
                                style: const TextStyle(
                                    color: Colors.white,
                                    fontWeight: FontWeight.bold,
                                    fontSize: 16),
                              ),
                              const SizedBox(height: 12),
                              ClipRRect(
                                borderRadius: BorderRadius.circular(4),
                                child: LinearProgressIndicator(
                                  value: _practices.isEmpty
                                      ? 0
                                      : _completedCount / _practices.length,
                                  backgroundColor: Colors.white30,
                                  valueColor: const AlwaysStoppedAnimation(
                                      Colors.white),
                                  minHeight: 8,
                                ),
                              ),
                              const SizedBox(height: 8),
                              Text(
                                '$_completedCount ${isHindi ? "पूर्ण" : "completed"} / ${_practices.length} ${isHindi ? "कुल" : "total"}',
                                style: TextStyle(
                                    color: Colors.white.withOpacity(0.85),
                                    fontSize: 13),
                              ),
                            ]),
                      ),
                      const SizedBox(height: 16),
                      ..._practices.map((p) {
                        final key = p['key'] ?? '';
                        final done = _todayLog[key] ?? false;
                        return GestureDetector(
                          onTap: () => _togglePractice(key),
                          child: AnimatedContainer(
                            duration: const Duration(milliseconds: 200),
                            margin: const EdgeInsets.only(bottom: 10),
                            padding: const EdgeInsets.symmetric(
                                horizontal: 16, vertical: 14),
                            decoration: BoxDecoration(
                              color:
                                  done ? const Color(0xFFE8F5E9) : Colors.white,
                              borderRadius: BorderRadius.circular(14),
                              border: Border.all(
                                  color: done
                                      ? const Color(0xFF2E7D32)
                                      : Colors.grey.shade200),
                            ),
                            child: Row(children: [
                              Text(p['icon'] ?? '🙏',
                                  style: const TextStyle(fontSize: 28)),
                              const SizedBox(width: 14),
                              Expanded(
                                  child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                    Text(
                                      isHindi
                                          ? (p['name_hi'] ?? p['name'] ?? '')
                                          : (p['name'] ?? ''),
                                      style: TextStyle(
                                          fontSize: 15,
                                          fontWeight: FontWeight.w600,
                                          color: done
                                              ? const Color(0xFF2E7D32)
                                              : const Color(0xFF2D1A0A),
                                          decoration: done
                                              ? TextDecoration.lineThrough
                                              : null),
                                    ),
                                    const SizedBox(height: 2),
                                    Text(
                                      isHindi
                                          ? (p['duration_hi'] ??
                                              p['duration'] ??
                                              '')
                                          : (p['duration'] ?? ''),
                                      style: TextStyle(
                                          fontSize: 12,
                                          color: Colors.grey[600]),
                                    ),
                                  ])),
                              Container(
                                width: 28,
                                height: 28,
                                decoration: BoxDecoration(
                                    shape: BoxShape.circle,
                                    color: done
                                        ? const Color(0xFF2E7D32)
                                        : Colors.grey.shade200),
                                child: Icon(
                                    done ? Icons.check : Icons.circle_outlined,
                                    color: done ? Colors.white : Colors.grey,
                                    size: 18),
                              ),
                            ]),
                          ),
                        );
                      }),
                    ],
                  ),

            // ── CALENDAR TAB ──
            _loadingFestivals
                ? const Center(
                    child: CircularProgressIndicator(color: Color(0xFFB8621C)))
                : ListView(
                    padding: const EdgeInsets.all(16),
                    children: [
                      Text(
                        isHindi
                            ? 'आने वाले व्रत और त्योहार'
                            : 'Upcoming Vrats & Festivals',
                        style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF2D1A0A)),
                      ),
                      const SizedBox(height: 14),
                      if (_festivals.isEmpty)
                        _emptyState(
                            '📅',
                            isHindi
                                ? 'कोई आगामी त्योहार नहीं'
                                : 'No upcoming festivals')
                      else
                        ..._festivals.map((f) {
                          final dateRaw = f['festival_date'] ?? '';
                          final date = DateTime.tryParse(dateRaw);
                          final dateStr = date != null
                              ? DateFormat('dd MMM').format(date)
                              : dateRaw;
                          final dateStrHi = date != null
                              ? DateFormat('dd MMM').format(date)
                              : dateRaw;
                          return Container(
                            margin: const EdgeInsets.only(bottom: 12),
                            padding: const EdgeInsets.all(16),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(14),
                              boxShadow: [
                                BoxShadow(
                                    color: Colors.black.withOpacity(0.05),
                                    blurRadius: 8,
                                    offset: const Offset(0, 2))
                              ],
                            ),
                            child: Row(children: [
                              Container(
                                width: 52,
                                height: 52,
                                decoration: BoxDecoration(
                                    color: const Color(0xFFFFF3E0),
                                    borderRadius: BorderRadius.circular(12)),
                                child: Center(
                                    child: Text(f['icon'] ?? '🪔',
                                        style: const TextStyle(fontSize: 26))),
                              ),
                              const SizedBox(width: 14),
                              Expanded(
                                  child: Text(
                                isHindi
                                    ? (f['name_hi'] ?? f['name'] ?? '')
                                    : (f['name'] ?? ''),
                                style: const TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.w600,
                                    color: Color(0xFF2D1A0A)),
                              )),
                              Container(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 12, vertical: 6),
                                decoration: BoxDecoration(
                                    color: const Color(0xFFD4501A)
                                        .withOpacity(0.1),
                                    borderRadius: BorderRadius.circular(20)),
                                child: Text(
                                  isHindi ? dateStrHi : dateStr,
                                  style: const TextStyle(
                                      color: Color(0xFFD4501A),
                                      fontWeight: FontWeight.bold,
                                      fontSize: 13),
                                ),
                              ),
                            ]),
                          );
                        }),
                      const SizedBox(height: 16),
                      // Today's Shloka
                      if (_todayShloka != null)
                        Container(
                          padding: const EdgeInsets.all(20),
                          decoration: BoxDecoration(
                            gradient: const LinearGradient(
                              colors: [Color(0xFF5C6BC0), Color(0xFF3949AB)],
                            ),
                            borderRadius: BorderRadius.circular(16),
                          ),
                          child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(children: [
                                  const Text('📖',
                                      style: TextStyle(fontSize: 20)),
                                  const SizedBox(width: 8),
                                  Text(
                                    isHindi ? 'आज का श्लोक' : "Today's Shloka",
                                    style: const TextStyle(
                                        color: Colors.white,
                                        fontWeight: FontWeight.bold,
                                        fontSize: 15),
                                  ),
                                ]),
                                const SizedBox(height: 12),
                                Text(
                                  _todayShloka!['text'] ?? '',
                                  style: const TextStyle(
                                      color: Colors.white,
                                      fontSize: 14,
                                      height: 1.8),
                                ),
                                if ((_todayShloka!['translation_hi'] ?? '') !=
                                    '') ...[
                                  const SizedBox(height: 8),
                                  Text(
                                    isHindi
                                        ? (_todayShloka!['translation_hi'] ??
                                            '')
                                        : (_todayShloka!['translation'] ?? ''),
                                    style: TextStyle(
                                        color: Colors.white.withOpacity(0.8),
                                        fontSize: 13,
                                        fontStyle: FontStyle.italic),
                                  ),
                                ],
                                const SizedBox(height: 10),
                                Text(
                                  isHindi
                                      ? ('— ' +
                                          (_todayShloka!['source_hi'] ?? ''))
                                      : ('— ' +
                                          (_todayShloka!['source'] ?? '')),
                                  style: TextStyle(
                                      color: Colors.white.withOpacity(0.7),
                                      fontSize: 12),
                                ),
                              ]),
                        ),
                    ],
                  ),
          ],
        ),
      ),
    );
  }

  Widget _emptyState(String emoji, String msg) {
    return Center(
        child: Padding(
      padding: const EdgeInsets.all(32),
      child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
        Text(emoji, style: const TextStyle(fontSize: 48)),
        const SizedBox(height: 12),
        Text(msg, style: const TextStyle(color: Colors.grey, fontSize: 15)),
      ]),
    ));
  }
}

// ─── MANTRA CARD ──────────────────────────────────────────────────────────────
class _MantraCard extends StatelessWidget {
  final Map<String, dynamic> mantra;
  final bool isHindi;
  final VoidCallback onTap;
  final Color Function(String) hexToColor;
  const _MantraCard(
      {required this.mantra,
      required this.isHindi,
      required this.onTap,
      required this.hexToColor});

  @override
  Widget build(BuildContext context) {
    final color = hexToColor(mantra['color'] ?? '#FF8C00');
    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.only(bottom: 14),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border(left: BorderSide(color: color, width: 4)),
          boxShadow: [
            BoxShadow(
                color: Colors.black.withOpacity(0.06),
                blurRadius: 8,
                offset: const Offset(0, 2))
          ],
        ),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child:
              Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Row(children: [
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                    color: color.withOpacity(0.12),
                    borderRadius: BorderRadius.circular(20)),
                child: Text(
                  isHindi
                      ? (mantra['deity_hi'] ?? mantra['deity'] ?? '')
                      : (mantra['deity'] ?? ''),
                  style: TextStyle(
                      color: color, fontSize: 12, fontWeight: FontWeight.bold),
                ),
              ),
              const Spacer(),
              Icon(Icons.touch_app, color: color, size: 20),
              const SizedBox(width: 4),
              Text(isHindi ? 'जप करें' : 'Start Japa',
                  style: TextStyle(
                      color: color, fontSize: 12, fontWeight: FontWeight.bold)),
            ]),
            const SizedBox(height: 10),
            Text(
              isHindi
                  ? (mantra['name_hi'] ?? mantra['name'] ?? '')
                  : (mantra['name'] ?? ''),
              style: const TextStyle(
                  fontSize: 17,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF2D1A0A)),
            ),
            const SizedBox(height: 6),
            Text(mantra['text'] ?? '',
                style: TextStyle(
                    fontSize: 13, color: Colors.grey[600], height: 1.5),
                maxLines: 2,
                overflow: TextOverflow.ellipsis),
            const SizedBox(height: 8),
            Row(children: [
              Icon(Icons.auto_awesome, size: 14, color: Colors.amber[700]),
              const SizedBox(width: 4),
              Text(
                isHindi
                    ? (mantra['benefit_hi'] ?? mantra['benefit'] ?? '')
                    : (mantra['benefit'] ?? ''),
                style: TextStyle(fontSize: 12, color: Colors.grey[600]),
              ),
              const Spacer(),
              Text(
                '${mantra['japa_count'] ?? 108} ${isHindi ? "जप" : "counts"}',
                style: TextStyle(fontSize: 12, color: Colors.grey[500]),
              ),
            ]),
          ]),
        ),
      ),
    );
  }
}
