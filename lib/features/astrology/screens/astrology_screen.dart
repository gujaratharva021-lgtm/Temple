import 'package:flutter/material.dart';
import '../widgets/panchang_card.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:Temple/features/home/screens/main_shell.dart';
import 'package:Temple/shared/services/api_service.dart';

class AstrologyScreen extends ConsumerStatefulWidget {
  const AstrologyScreen({super.key});
  @override
  ConsumerState<AstrologyScreen> createState() => _AstrologyScreenState();
}

class _AstrologyScreenState extends ConsumerState<AstrologyScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  List<Map<String, dynamic>> _astrologers = [];
  bool _loading = true;

  final _demoAstrologers = [
    {
      'name': 'Pt. Ram Sharma',
      'specialty': 'Vedic Astrology, Kundli',
      'specialty_hi': 'वैदिक ज्योतिष, कुंडली',
      'exp': '15 Years',
      'exp_hi': '15 वर्ष',
      'rating': 4.8,
      'price': 500
    },
    {
      'name': 'Acharya Vishnu Das',
      'specialty': 'Numerology, Vastu',
      'specialty_hi': 'अंक ज्योतिष, वास्तु',
      'exp': '20 Years',
      'exp_hi': '20 वर्ष',
      'rating': 4.9,
      'price': 700
    },
    {
      'name': 'Pt. Shyam Tripathi',
      'specialty': 'Muhurat, Kundli Milan',
      'specialty_hi': 'मुहूर्त, कुंडली मिलान',
      'exp': '12 Years',
      'exp_hi': '12 वर्ष',
      'rating': 4.7,
      'price': 400
    },
    {
      'name': 'Jyotishacharya Devendra',
      'specialty': 'Horoscope, Vastu Shastra',
      'specialty_hi': 'राशिफल, वास्तु शास्त्र',
      'exp': '18 Years',
      'exp_hi': '18 वर्ष',
      'rating': 4.6,
      'price': 600
    },
  ];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _loadAstrologers();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _loadAstrologers() async {
    try {
      final res = await ApiService().getAstrologers();
      final list = (res['data'] as List?) ?? [];
      if (mounted)
        setState(() {
          _astrologers = list.isEmpty
              ? _demoAstrologers
              : list.cast<Map<String, dynamic>>();
          _loading = false;
        });
    } catch (_) {
      if (mounted)
        setState(() {
          _astrologers = _demoAstrologers;
          _loading = false;
        });
    }
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
        title: Text(isHindi ? 'ज्योतिष सेवाएं' : 'Astrology Services'),
        bottom: TabBar(
          controller: _tabController,
          labelColor: Colors.white,
          unselectedLabelColor: Colors.white70,
          indicatorColor: Colors.white,
          tabs: [
            Tab(text: isHindi ? 'ज्योतिषी' : 'Astrologers'),
            Tab(text: isHindi ? 'कुंडली' : 'Kundli'),
            Tab(text: isHindi ? 'राशिफल' : 'Horoscope'),
          ],
        ),
      ),
      body: TabBarView(controller: _tabController, children: [
        _buildAstrologersList(isHindi),
        _KundliTab(isHindi: isHindi),
        _buildHoroscopeTab(isHindi),
      ]),
    );
  }

  Widget _buildAstrologersList(bool isHindi) {
    if (_loading)
      return const Center(
          child: CircularProgressIndicator(color: Colors.orange));
    return RefreshIndicator(
      onRefresh: _loadAstrologers,
      color: Colors.orange,
      child: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: _astrologers.length + 1,
        itemBuilder: (ctx, i) {
          if (i == 0) return const PanchangCard();
          final item = Map<String, dynamic>.from(_astrologers[i - 1] as Map);
          return _AstrologerCard(astrologer: item, isHindi: isHindi);
        },
      ),
    );
  }

  Widget _buildHoroscopeTab(bool isHindi) {
    final rashis = [
      {'symbol': '♈', 'hi': 'मेष', 'en': 'Aries'},
      {'symbol': '♉', 'hi': 'वृषभ', 'en': 'Taurus'},
      {'symbol': '♊', 'hi': 'मिथुन', 'en': 'Gemini'},
      {'symbol': '♋', 'hi': 'कर्क', 'en': 'Cancer'},
      {'symbol': '♌', 'hi': 'सिंह', 'en': 'Leo'},
      {'symbol': '♍', 'hi': 'कन्या', 'en': 'Virgo'},
      {'symbol': '♎', 'hi': 'तुला', 'en': 'Libra'},
      {'symbol': '♏', 'hi': 'वृश्चिक', 'en': 'Scorpio'},
      {'symbol': '♐', 'hi': 'धनु', 'en': 'Sagittarius'},
      {'symbol': '♑', 'hi': 'मकर', 'en': 'Capricorn'},
      {'symbol': '♒', 'hi': 'कुंभ', 'en': 'Aquarius'},
      {'symbol': '♓', 'hi': 'मीन', 'en': 'Pisces'},
    ];
    return GridView.builder(
      padding: const EdgeInsets.all(16),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 3,
        childAspectRatio: 1.0,
        crossAxisSpacing: 12,
        mainAxisSpacing: 12,
      ),
      itemCount: rashis.length,
      itemBuilder: (ctx, i) {
        final r = rashis[i];
        return Card(
          elevation: 2,
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          child: InkWell(
            borderRadius: BorderRadius.circular(16),
            onTap: () => _showHoroscope(r['en']! as String, isHindi),
            child:
                Column(mainAxisAlignment: MainAxisAlignment.center, children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: Image.asset(
                  'assets/images/zodiac/${(r['en'] as String).toLowerCase()}.png',
                  width: 60,
                  height: 60,
                  fit: BoxFit.contain,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                isHindi ? r['hi']! as String : r['en']! as String,
                style:
                    const TextStyle(fontWeight: FontWeight.w600, fontSize: 13),
              ),
            ]),
          ),
        );
      },
    );
  }

  final Map<String, Map<String, String>> _horoscopeData = {
    'Aries': {
      'symbol': '♈',
      'hi': 'मेष',
      'lordHi': 'मंगल',
      'lord': 'Mars',
      'elementHi': 'अग्नि',
      'element': 'Fire',
      'rashifalHi':
          'आज का दिन आपके लिए बेहद शुभ है। व्यापार में लाभ के अवसर आएंगे। परिवार के साथ समय बिताएं। स्वास्थ्य का ध्यान रखें।',
      'rashifal':
          'Today is very auspicious for you. Opportunities for profit in business. Spend time with family. Take care of health.',
    },
    'Taurus': {
      'symbol': '♉',
      'hi': 'वृषभ',
      'lordHi': 'शुक्र',
      'lord': 'Venus',
      'elementHi': 'पृथ्वी',
      'element': 'Earth',
      'rashifalHi':
          'आज आपको किसी पुराने मित्र से मुलाकात हो सकती है। कार्यक्षेत्र में सफलता मिलेगी। धन लाभ के योग हैं।',
      'rashifal':
          'Today you may meet an old friend. Success in career. Chances of financial gain.',
    },
    'Gemini': {
      'symbol': '♊',
      'hi': 'मिथुन',
      'lordHi': 'बुध',
      'lord': 'Mercury',
      'elementHi': 'वायु',
      'element': 'Air',
      'rashifalHi':
          'बुद्धि और विवेक से काम लें। नई जानकारी प्राप्त होगी। यात्रा के योग हैं।',
      'rashifal':
          'Use intelligence and discretion. New information will be received. Chances of travel.',
    },
    'Cancer': {
      'symbol': '♋',
      'hi': 'कर्क',
      'lordHi': 'चंद्र',
      'lord': 'Moon',
      'elementHi': 'जल',
      'element': 'Water',
      'rashifalHi':
          'आज भावनाओं पर नियंत्रण रखें। परिवार में सुख-शांति रहेगी। माता से आशीर्वाद प्राप्त होगा।',
      'rashifal':
          'Control emotions today. Peace and happiness in family. Blessings from mother.',
    },
    'Leo': {
      'symbol': '♌',
      'hi': 'सिंह',
      'lordHi': 'सूर्य',
      'lord': 'Sun',
      'elementHi': 'अग्नि',
      'element': 'Fire',
      'rashifalHi':
          'आज आपका आत्मविश्वास चरम पर होगा। नेतृत्व क्षमता का प्रदर्शन करें। सरकारी कार्यों में सफलता मिलेगी।',
      'rashifal':
          'Your confidence will be at peak today. Show leadership skills. Success in government work.',
    },
    'Virgo': {
      'symbol': '♍',
      'hi': 'कन्या',
      'lordHi': 'बुध',
      'lord': 'Mercury',
      'elementHi': 'पृथ्वी',
      'element': 'Earth',
      'rashifalHi':
          'विश्लेषण और सटीकता से कार्य करें। स्वास्थ्य पर ध्यान दें। सेवा कार्यों में सफलता मिलेगी।',
      'rashifal':
          'Work with analysis and accuracy. Pay attention to health. Success in service work.',
    },
    'Libra': {
      'symbol': '♎',
      'hi': 'तुला',
      'lordHi': 'शुक्र',
      'lord': 'Venus',
      'elementHi': 'वायु',
      'element': 'Air',
      'rashifalHi':
          'संतुलन बनाए रखें। साझेदारी में लाभ होगा। न्यायिक मामलों में जीत मिलेगी।',
      'rashifal':
          'Maintain balance. Profit in partnership. Victory in legal matters.',
    },
    'Scorpio': {
      'symbol': '♏',
      'hi': 'वृश्चिक',
      'lordHi': 'मंगल',
      'lord': 'Mars',
      'elementHi': 'जल',
      'element': 'Water',
      'rashifalHi':
          'गुप्त ज्ञान की प्राप्ति होगी। शोध कार्यों में सफलता मिलेगी। आध्यात्मिक उन्नति का समय है।',
      'rashifal':
          'Secret knowledge will be received. Success in research work. Time for spiritual advancement.',
    },
    'Sagittarius': {
      'symbol': '♐',
      'hi': 'धनु',
      'lordHi': 'बृहस्पति',
      'lord': 'Jupiter',
      'elementHi': 'अग्नि',
      'element': 'Fire',
      'rashifalHi':
          'ज्ञान और विद्या में वृद्धि होगी। धार्मिक कार्यों में मन लगेगा। यात्रा के योग हैं।',
      'rashifal':
          'Knowledge and education will increase. Mind will be engaged in religious activities. Chances of travel.',
    },
    'Capricorn': {
      'symbol': '♑',
      'hi': 'मकर',
      'lordHi': 'शनि',
      'lord': 'Saturn',
      'elementHi': 'पृथ्वी',
      'element': 'Earth',
      'rashifalHi':
          'मेहनत और परिश्रम रंग लाएगी। करियर में उन्नति होगी। वरिष्ठों का सहयोग मिलेगा।',
      'rashifal':
          'Hard work will pay off. Career advancement. Support from seniors.',
    },
    'Aquarius': {
      'symbol': '♒',
      'hi': 'कुंभ',
      'lordHi': 'शनि',
      'lord': 'Saturn',
      'elementHi': 'वायु',
      'element': 'Air',
      'rashifalHi':
          'नवीन विचारों से सफलता मिलेगी। मित्रों का सहयोग प्राप्त होगा। तकनीकी क्षेत्र में उन्नति होगी।',
      'rashifal':
          'Success will come with new ideas. Friends will support. Advancement in technical field.',
    },
    'Pisces': {
      'symbol': '♓',
      'hi': 'मीन',
      'lordHi': 'बृहस्पति',
      'lord': 'Jupiter',
      'elementHi': 'जल',
      'element': 'Water',
      'rashifalHi':
          'आध्यात्मिक चेतना जागृत होगी। कल्पनाशीलता से कार्य करें। दान-पुण्य से मन प्रसन्न रहेगा।',
      'rashifal':
          'Spiritual consciousness will awaken. Work with imagination. Mind will be happy with charity.',
    },
  };

  String _getLuckyColor(String rashi) {
    final colors = [
      'Red',
      'Pink',
      'Yellow',
      'Silver',
      'Gold',
      'Green',
      'Blue',
      'Maroon',
      'Purple',
      'Black',
      'Sky Blue',
      'Sea Green'
    ];
    final rashiList = [
      'Aries',
      'Taurus',
      'Gemini',
      'Cancer',
      'Leo',
      'Virgo',
      'Libra',
      'Scorpio',
      'Sagittarius',
      'Capricorn',
      'Aquarius',
      'Pisces'
    ];
    final today = DateTime.now();
    final dayNum = today.day + today.month + today.year;
    final rashiIndex = rashiList.indexOf(rashi);
    return colors[(rashiIndex + dayNum) % colors.length];
  }

  String _getLuckyColorHi(String rashi) {
    final colors = [
      'लाल',
      'गुलाबी',
      'पीला',
      'चांदी',
      'सुनहरा',
      'हरा',
      'नीला',
      'मरून',
      'बैंगनी',
      'काला',
      'आसमानी',
      'समुद्री हरा'
    ];
    final rashiList = [
      'Aries',
      'Taurus',
      'Gemini',
      'Cancer',
      'Leo',
      'Virgo',
      'Libra',
      'Scorpio',
      'Sagittarius',
      'Capricorn',
      'Aquarius',
      'Pisces'
    ];
    final today = DateTime.now();
    final dayNum = today.day + today.month + today.year;
    final rashiIndex = rashiList.indexOf(rashi);
    return colors[(rashiIndex + dayNum) % colors.length];
  }

  int _getLuckyNumber(String rashi) {
    final rashiList = [
      'Aries',
      'Taurus',
      'Gemini',
      'Cancer',
      'Leo',
      'Virgo',
      'Libra',
      'Scorpio',
      'Sagittarius',
      'Capricorn',
      'Aquarius',
      'Pisces'
    ];
    final today = DateTime.now();
    final dayNum = today.day * today.month + today.year;
    final rashiIndex = rashiList.indexOf(rashi) + 1;
    return ((dayNum * rashiIndex) % 9) + 1;
  }

  final rashiList = [
    'Aries',
    'Taurus',
    'Gemini',
    'Cancer',
    'Leo',
    'Virgo',
    'Libra',
    'Scorpio',
    'Sagittarius',
    'Capricorn',
    'Aquarius',
    'Pisces'
  ];

  void _showHoroscope(String rashi, bool isHindi) {
    final data = _horoscopeData[rashi] ?? {};
    final lord = isHindi ? (data['lordHi'] ?? '') : (data['lord'] ?? '');
    final element =
        isHindi ? (data['elementHi'] ?? '') : (data['element'] ?? '');
    final rashifal =
        isHindi ? (data['rashifalHi'] ?? '') : (data['rashifal'] ?? '');
    final rashiName = isHindi ? (data['hi'] ?? rashi) : rashi;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (ctx) => DraggableScrollableSheet(
        initialChildSize: 0.6,
        minChildSize: 0.4,
        maxChildSize: 0.9,
        expand: false,
        builder: (ctx, scrollCtrl) => SingleChildScrollView(
          controller: scrollCtrl,
          padding: const EdgeInsets.all(24),
          child: Column(children: [
            Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                    color: Colors.grey[300],
                    borderRadius: BorderRadius.circular(2))),
            const SizedBox(height: 16),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                    colors: [Color(0xFF8B0000), Color(0xFFFF6B00)]),
                borderRadius: BorderRadius.circular(16),
              ),
              child: Column(children: [
                Image.asset('assets/images/zodiac/${rashi.toLowerCase()}.png',
                    width: 80, height: 80, fit: BoxFit.contain),
                const SizedBox(height: 8),
                Text(rashiName,
                    style: const TextStyle(
                        color: Colors.white,
                        fontSize: 24,
                        fontWeight: FontWeight.bold)),
                Text(isHindi ? 'आज का राशिफल' : "Today's Horoscope",
                    style:
                        const TextStyle(color: Colors.white70, fontSize: 14)),
              ]),
            ),
            const SizedBox(height: 16),
            Row(children: [
              Expanded(
                child: Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                      color: Colors.orange.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(12)),
                  child: Column(children: [
                    Text(isHindi ? 'स्वामी' : 'Lord',
                        style:
                            const TextStyle(color: Colors.grey, fontSize: 12)),
                    Text(lord,
                        style: const TextStyle(
                            fontWeight: FontWeight.bold, fontSize: 16)),
                  ]),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                      color: Colors.orange.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(12)),
                  child: Column(children: [
                    Text(isHindi ? 'तत्व' : 'Element',
                        style:
                            const TextStyle(color: Colors.grey, fontSize: 12)),
                    Text(element,
                        style: const TextStyle(
                            fontWeight: FontWeight.bold, fontSize: 16)),
                  ]),
                ),
              ),
            ]),
            const SizedBox(height: 16),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                  color: Colors.grey[50],
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.orange.withOpacity(0.2))),
              child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                        isHindi
                            ? '🔮 आज का भविष्यफल'
                            : '🔮 Today\'s Prediction',
                        style: const TextStyle(
                            fontWeight: FontWeight.bold, fontSize: 16)),
                    const SizedBox(height: 10),
                    Text(rashifal,
                        style: const TextStyle(fontSize: 15, height: 1.7)),
                  ]),
            ),
            const SizedBox(height: 20),
            Row(children: [
              Expanded(
                child: Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                      color: Colors.green.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(12)),
                  child: Column(children: [
                    Text(isHindi ? '🍀 शुभ रंग' : '🍀 Lucky Color',
                        style:
                            const TextStyle(fontSize: 12, color: Colors.grey)),
                    const SizedBox(height: 4),
                    Text(
                        isHindi
                            ? _getLuckyColorHi(rashi)
                            : _getLuckyColor(rashi),
                        style: const TextStyle(fontWeight: FontWeight.bold)),
                  ]),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                      color: Colors.blue.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(12)),
                  child: Column(children: [
                    Text(isHindi ? '🔢 शुभ अंक' : '🔢 Lucky Number',
                        style:
                            const TextStyle(fontSize: 12, color: Colors.grey)),
                    const SizedBox(height: 4),
                    Text('${_getLuckyNumber(rashi)}',
                        style: const TextStyle(fontWeight: FontWeight.bold)),
                  ]),
                ),
              ),
            ]),
            const SizedBox(height: 20),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12))),
                onPressed: () => Navigator.pop(ctx),
                child: Text(isHindi ? 'बंद करें' : 'Close'),
              ),
            ),
          ]),
        ),
      ),
    );
  }
}

// ─── KUNDLI TAB ───────────────────────────────────────────────────────────────

class _KundliTab extends StatefulWidget {
  final bool isHindi;
  const _KundliTab({required this.isHindi});
  @override
  State<_KundliTab> createState() => _KundliTabState();
}

class _KundliTabState extends State<_KundliTab> {
  final nameCtrl = TextEditingController();
  final dateCtrl = TextEditingController();
  final timeCtrl = TextEditingController();
  final placeCtrl = TextEditingController();
  DateTime? selectedDate;
  TimeOfDay? selectedTime;
  Map<String, dynamic>? kundliData;
  bool isLoading = false;

  @override
  void dispose() {
    nameCtrl.dispose();
    dateCtrl.dispose();
    timeCtrl.dispose();
    placeCtrl.dispose();
    super.dispose();
  }

  Future<void> createKundli() async {
    if (nameCtrl.text.isEmpty ||
        selectedDate == null ||
        selectedTime == null ||
        placeCtrl.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text(widget.isHindi
              ? 'कृपया सभी जानकारी भरें'
              : 'Please fill all details')));
      return;
    }
    setState(() => isLoading = true);
    try {
      final day = selectedDate!.day.toString().padLeft(2, '0');
      final month = selectedDate!.month.toString().padLeft(2, '0');
      final year = selectedDate!.year;
      final hour = selectedTime!.hour.toString().padLeft(2, '0');
      final minute = selectedTime!.minute.toString().padLeft(2, '0');
      final planets = [
        'Sun',
        'Moon',
        'Mars',
        'Mercury',
        'Jupiter',
        'Venus',
        'Saturn',
        'Rahu',
        'Ketu'
      ];
      final List<Map<String, dynamic>> planetResults = [];
      for (final planet in planets) {
        try {
          final url =
              'https://api.vedastro.org/api/Calculate/AllPlanetData/PlanetName/$planet/Location/19.0760,72.8777/Time/$hour:$minute/$day-$month-$year/+05:30/Ayanamsa/RAMAN';
          final res = await ApiService().getFromUrl(url);
          final allData = res['Payload']?['AllPlanetData'];
          planetResults.add({
            'Name': planet,
            'Rasi': allData?['PlanetRasiD1Sign']?['Name'] ?? '',
            'Constellation': allData?['PlanetConstellation'] ?? '',
            'HouseName': allData?['HousePlanetOccupiesBasedOnLongitudes'] ?? '',
            'IsRetrograde': allData?['IsPlanetRetrograde'] ?? 'False',
          });
        } catch (_) {}
      }
      setState(() {
        kundliData = {'Payload': planetResults};
        isLoading = false;
      });
    } catch (e) {
      setState(() => isLoading = false);
      if (mounted)
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text('Error: $e')));
    }
  }

  Widget _buildInput(TextEditingController ctrl, String label, IconData icon,
      {bool readOnly = false, VoidCallback? onTap}) {
    return TextField(
      controller: ctrl,
      readOnly: readOnly,
      onTap: onTap,
      decoration: InputDecoration(
        labelText: label,
        prefixIcon: Icon(icon, color: Colors.orange),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
        focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(color: Colors.orange)),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isHindi = widget.isHindi;
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Container(
          width: double.infinity,
          height: 200,
          decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(20),
              boxShadow: [
                BoxShadow(
                    color: Colors.deepPurple.withValues(alpha: 0.3),
                    blurRadius: 15,
                    offset: const Offset(0, 6))
              ]),
          child: Stack(children: [
            ClipRRect(
                borderRadius: BorderRadius.circular(20),
                child: Image.asset('assets/images/kundli.jpg',
                    width: double.infinity, height: 200, fit: BoxFit.cover)),
            Container(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(20),
                gradient: LinearGradient(colors: [
                  Colors.black.withValues(alpha: 0.3),
                  Colors.black.withValues(alpha: 0.7)
                ], begin: Alignment.topCenter, end: Alignment.bottomCenter),
              ),
            ),
            Center(
              child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(isHindi ? 'जन्म कुंडली' : 'Birth Kundli',
                        style: const TextStyle(
                            color: Colors.white,
                            fontSize: 26,
                            fontWeight: FontWeight.bold,
                            letterSpacing: 1.2)),
                    const SizedBox(height: 6),
                    Text(
                        isHindi
                            ? 'अपनी जन्म जानकारी भरें'
                            : 'Enter your birth details',
                        style: TextStyle(
                            color: Colors.white.withValues(alpha: 0.85),
                            fontSize: 13)),
                    const SizedBox(height: 12),
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 16, vertical: 6),
                      decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.2),
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(
                              color: Colors.white.withValues(alpha: 0.4))),
                      child: Text(
                          isHindi
                              ? '🔮 वैदिक ज्योतिष पर आधारित'
                              : '🔮 Based on Vedic Astrology',
                          style: const TextStyle(
                              color: Colors.white, fontSize: 12)),
                    ),
                  ]),
            ),
          ]),
        ),
        const SizedBox(height: 24),
        _buildInput(nameCtrl, isHindi ? 'नाम' : 'Full Name', Icons.person),
        const SizedBox(height: 12),
        _buildInput(dateCtrl, isHindi ? 'जन्म तारीख' : 'Birth Date',
            Icons.calendar_today,
            readOnly: true, onTap: () async {
          final d = await showDatePicker(
              context: context,
              initialDate: DateTime(1990),
              firstDate: DateTime(1900),
              lastDate: DateTime.now());
          if (d != null)
            setState(() {
              selectedDate = d;
              dateCtrl.text = '${d.day}/${d.month}/${d.year}';
            });
        }),
        const SizedBox(height: 12),
        _buildInput(
            timeCtrl, isHindi ? 'जन्म समय' : 'Birth Time', Icons.access_time,
            readOnly: true, onTap: () async {
          final t = await showTimePicker(
              context: context, initialTime: TimeOfDay.now());
          if (t != null && mounted)
            setState(() {
              selectedTime = t;
              timeCtrl.text = t.format(context);
            });
        }),
        const SizedBox(height: 12),
        _buildInput(placeCtrl, isHindi ? 'जन्म स्थान' : 'Birth Place',
            Icons.location_on),
        const SizedBox(height: 24),
        SizedBox(
          width: double.infinity,
          child: ElevatedButton(
            style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12))),
            onPressed: isLoading ? null : createKundli,
            child: isLoading
                ? const SizedBox(
                    height: 20,
                    width: 20,
                    child: CircularProgressIndicator(
                        color: Colors.white, strokeWidth: 2))
                : Text(isHindi ? 'कुंडली बनाएं' : 'Create Kundli',
                    style: const TextStyle(fontSize: 16)),
          ),
        ),
        if (kundliData != null) ...[
          const SizedBox(height: 24),
          _buildKundliResult(kundliData!, isHindi)
        ],
      ]),
    );
  }

  Widget _buildKundliResult(Map<String, dynamic> data, bool isHindi) {
    final payload = data['Payload'];
    List planets = payload is List
        ? payload
        : (payload is Map ? payload.values.toList() : []);
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Text(isHindi ? '🪐 ग्रह स्थिति' : '🪐 Planet Positions',
          style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
      const SizedBox(height: 12),
      if (planets.isEmpty)
        Center(child: Text(isHindi ? 'कोई डेटा नहीं मिला' : 'No data found'))
      else
        ...planets.map((planet) {
          final p = planet is Map ? planet : {};
          final name = p['Name']?.toString() ?? '';
          final rashi = p['Rasi']?.toString() ?? '';
          final house = p['HouseName']?.toString() ?? '';
          final nakshatra = p['Constellation']?.toString() ?? '';
          return Card(
            margin: const EdgeInsets.only(bottom: 8),
            shape:
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            child: ListTile(
              leading: CircleAvatar(
                  backgroundColor: Colors.orange.withOpacity(0.15),
                  child: Text(_getPlanetEmoji(name),
                      style: const TextStyle(fontSize: 18))),
              title: Text(name,
                  style: const TextStyle(fontWeight: FontWeight.bold)),
              subtitle: Text('$nakshatra • $house'),
              trailing: Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                    color: Colors.orange.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8)),
                child: Text(rashi,
                    style: const TextStyle(
                        color: Colors.orange, fontWeight: FontWeight.bold)),
              ),
            ),
          );
        }),
    ]);
  }

  String _getPlanetEmoji(String name) {
    const map = {
      'Sun': '☀️',
      'Moon': '🌙',
      'Mars': '♂️',
      'Mercury': '☿️',
      'Jupiter': '♃',
      'Venus': '♀️',
      'Saturn': '♄',
      'Rahu': '🐉',
      'Ketu': '☄️'
    };
    return map[name] ?? '⭐';
  }
}

// ─── ASTROLOGER CARD ──────────────────────────────────────────────────────────

class _AstrologerCard extends StatelessWidget {
  final Map<String, dynamic> astrologer;
  final bool isHindi;
  const _AstrologerCard({required this.astrologer, required this.isHindi});

  @override
  Widget build(BuildContext context) {
    final name = astrologer['name']?.toString() ?? '';
    final initial = name.isNotEmpty ? name[0] : '⭐';
    final price = astrologer['price']?.toString() ?? '';
    final rating = astrologer['rating']?.toString() ?? '';
    final exp = isHindi
        ? (astrologer['exp_hi'] ?? astrologer['exp'] ?? '')
        : (astrologer['exp'] ?? '');
    final specialty = isHindi
        ? (astrologer['specialty_hi'] ?? astrologer['specialty'] ?? '')
        : (astrologer['specialty'] ?? '');

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Row(children: [
          CircleAvatar(
            radius: 28,
            backgroundColor: Colors.orange.withOpacity(0.15),
            child: Text(initial,
                style: const TextStyle(fontSize: 22, color: Colors.orange)),
          ),
          const SizedBox(width: 10),
          Expanded(
            child:
                Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(name,
                  style: const TextStyle(
                      fontWeight: FontWeight.bold, fontSize: 14),
                  overflow: TextOverflow.ellipsis),
              const SizedBox(height: 2),
              Text(specialty.toString(),
                  style: const TextStyle(color: Colors.grey, fontSize: 11),
                  overflow: TextOverflow.ellipsis),
              const SizedBox(height: 4),
              Row(children: [
                const Icon(Icons.star, color: Colors.amber, size: 13),
                Text(' $rating', style: const TextStyle(fontSize: 11)),
                const SizedBox(width: 8),
                const Icon(Icons.workspace_premium,
                    size: 13, color: Colors.grey),
                Flexible(
                    child: Text(' ${exp.toString()}',
                        style:
                            const TextStyle(fontSize: 11, color: Colors.grey),
                        overflow: TextOverflow.ellipsis)),
              ]),
            ]),
          ),
          const SizedBox(width: 8),
          Column(crossAxisAlignment: CrossAxisAlignment.end, children: [
            Text('₹$price/hr',
                style: const TextStyle(
                    color: Colors.orange,
                    fontWeight: FontWeight.bold,
                    fontSize: 12)),
            const SizedBox(height: 6),
            SizedBox(
              height: 30,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(horizontal: 10),
                  textStyle: const TextStyle(fontSize: 11),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8)),
                ),
                onPressed: () => ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                        content: Text(
                            '$name ${isHindi ? 'से परामर्श बुक हो रहा है...' : '- Booking...'} '))),
                child: Text(isHindi ? 'बुक करें' : 'Book'),
              ),
            ),
          ]),
        ]),
      ),
    );
  }
}
