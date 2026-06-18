import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:Temple/features/home/screens/main_shell.dart';

const _demoTemplesForPooja = [
  {
    'id': '1',
    'name': 'श्री सिद्धिविनायक मंदिर',
    'nameEn': 'Siddhivinayak Temple',
    'color': 0xFFFF6B00,
    'services': [
      {
        'name': 'गणेश पूजा',
        'name_en': 'Ganesh Pooja',
        'duration_minutes': 30,
        'price': 151,
        'image': 'assets/images/pooja/Ganesh Pooja.png'
      },
      {
        'name': 'महाआरती',
        'name_en': 'Mahaarti',
        'duration_minutes': 45,
        'price': 251,
        'image': 'assets/images/pooja/Maha aarati.png'
      }
    ]
  },
  {
    'id': '2',
    'name': 'श्री काशी विश्वनाथ मंदिर',
    'nameEn': 'Kashi Vishwanath Temple',
    'color': 0xFF8B0000,
    'services': [
      {
        'name': 'रुद्राभिषेक',
        'name_en': 'Rudrabhishek',
        'duration_minutes': 60,
        'price': 501,
        'image': 'assets/images/pooja/rudraabhishek.png'
      },
      {
        'name': 'महामृत्युंजय जाप',
        'name_en': 'Mahamrityunjay Jaap',
        'duration_minutes': 45,
        'price': 251,
        'image': 'assets/images/pooja/mahamrutu jaap.png'
      }
    ]
  },
  {
    'id': '3',
    'name': 'श्री तिरुपति बालाजी',
    'nameEn': 'Tirupati Balaji Temple',
    'color': 0xFF1A5276,
    'services': [
      {
        'name': 'सत्यनारायण कथा',
        'name_en': 'Satyanarayan Katha',
        'duration_minutes': 120,
        'price': 1001,
        'image': 'assets/images/pooja/Satyanarayan katha.png'
      }
    ]
  },
  {
    'id': '4',
    'name': 'श्री द्वारकाधीश मंदिर',
    'nameEn': 'Dwarkadhish Temple',
    'color': 0xFF1B5E20,
    'services': [
      {
        'name': 'भागवत पाठ',
        'name_en': 'Bhagwat Path',
        'duration_minutes': 90,
        'price': 751,
        'image': 'assets/images/pooja/bhagwat path.png'
      }
    ]
  },
  {
    'id': '5',
    'name': 'श्री वैष्णो देवी मंदिर',
    'nameEn': 'Vaishno Devi Temple',
    'color': 0xFF6B0080,
    'services': [
      {
        'name': 'दुर्गा पूजा',
        'name_en': 'Durga Pooja',
        'duration_minutes': 60,
        'price': 401,
        'image': 'assets/images/pooja/durga pooja.png'
      }
    ]
  },
];

class PoojaListScreen extends ConsumerStatefulWidget {
  const PoojaListScreen({super.key});
  @override
  ConsumerState<PoojaListScreen> createState() => _PoojaListScreenState();
}

class _PoojaListScreenState extends ConsumerState<PoojaListScreen> {
  @override
  Widget build(BuildContext context) {
    final lang = ref.watch(languageProvider);
    final isHindi = lang == 'hi';

    final List<Map<String, dynamic>> allPoojas = [];
    for (final temple in _demoTemplesForPooja) {
      final services =
          (temple['services'] as List).cast<Map<String, dynamic>>();
      for (final s in services) {
        allPoojas.add({
          ...s,
          'displayName': isHindi ? s['name'] : (s['name_en'] ?? s['name']),
          'templeId': temple['id'],
          'templeName': isHindi ? temple['name'] : temple['nameEn'],
          'color': temple['color'],
        });
      }
    }

    return Scaffold(
      backgroundColor: const Color(0xFFFFF8F0),
      appBar: AppBar(
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
        title: Text(isHindi ? 'पूजा सेवाएं' : 'Pooja Services'),
      ),
      body: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: allPoojas.length,
        itemBuilder: (context, i) {
          final p = allPoojas[i];
          final color = Color(p['color'] as int);
          final imagePath = p['image'] as String?;

          return Card(
            margin: const EdgeInsets.only(bottom: 12),
            elevation: 2,
            shape:
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            child: InkWell(
              onTap: () => context.go(
                '/pooja-detail/${p['templeId']}?name=${Uri.encodeQueryComponent(p['name'] as String)}&temple=${Uri.encodeQueryComponent(p['templeName'] as String)}&price=${p['price']}&duration=${p['duration_minutes']}&image=${Uri.encodeQueryComponent(p['image'] as String? ?? '')}',
              ),
              borderRadius: BorderRadius.circular(16),
              child: Padding(
                padding: const EdgeInsets.all(14),
                child: Row(children: [
                  Container(
                    width: 56,
                    height: 56,
                    decoration: BoxDecoration(
                        color: color.withOpacity(0.12),
                        borderRadius: BorderRadius.circular(12)),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(12),
                      child: imagePath != null
                          ? Image.asset(
                              imagePath,
                              width: 56,
                              height: 56,
                              fit: BoxFit.cover,
                            )
                          : Center(
                              child:
                                  Text('🙏', style: TextStyle(fontSize: 22))),
                    ),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(p['displayName'] as String,
                            style: const TextStyle(
                                fontWeight: FontWeight.w600, fontSize: 14)),
                        const SizedBox(height: 3),
                        Row(children: [
                          Icon(Icons.temple_hindu, size: 12, color: color),
                          const SizedBox(width: 4),
                          Text(p['templeName'] as String,
                              style: TextStyle(fontSize: 11, color: color)),
                        ]),
                        const SizedBox(height: 3),
                        Row(children: [
                          const Icon(Icons.access_time,
                              size: 12, color: Colors.grey),
                          const SizedBox(width: 3),
                          Text(
                              '${p['duration_minutes']} ${isHindi ? 'मिनट' : 'min'}',
                              style: const TextStyle(
                                  fontSize: 12, color: Colors.grey)),
                        ]),
                      ],
                    ),
                  ),
                  Text('₹${p['price']}',
                      style: TextStyle(
                          color: color,
                          fontWeight: FontWeight.bold,
                          fontSize: 16)),
                ]),
              ),
            ),
          );
        },
      ),
    );
  }
}
