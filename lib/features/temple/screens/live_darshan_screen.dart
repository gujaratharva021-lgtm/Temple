import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:webview_flutter/webview_flutter.dart';

const _templeYoutubeMap = {
  '1': {
    'youtubeId': '5q4w4CZDbcg',
    'name': 'श्री सिद्धिविनायक मंदिर',
    'nameEn': 'Siddhivinayak Temple',
    'city': 'Mumbai'
  },
  '2': {
    'youtubeId': 'KtJJy7kPHts',
    'name': 'श्री काशी विश्वनाथ',
    'nameEn': 'Kashi Vishwanath',
    'city': 'Varanasi'
  },
  '3': {
    'youtubeId': 'JoJo_YFxRsY',
    'name': 'श्री तिरुपति बालाजी',
    'nameEn': 'Tirupati Balaji',
    'city': 'Tirupati'
  },
  '4': {
    'youtubeId': 'placeholder_dwarka',
    'name': 'श्री द्वारकाधीश',
    'nameEn': 'Dwarkadhish Temple',
    'city': 'Dwarka'
  },
  '5': {
    'youtubeId': 'placeholder_vaishno',
    'name': 'श्री वैष्णो देवी',
    'nameEn': 'Vaishno Devi',
    'city': 'Katra'
  },
  '6': {
    'youtubeId': 'T9BIp0noEfc',
    'name': 'श्री जगन्नाथ मंदिर',
    'nameEn': 'Jagannath Temple',
    'city': 'Puri'
  },
  '7': {
    'youtubeId': 'placeholder_meenakshi',
    'name': 'श्री मीनाक्षी मंदिर',
    'nameEn': 'Meenakshi Temple',
    'city': 'Madurai'
  },
  '8': {
    'youtubeId': '7ZY20Z0bFh4',
    'name': 'श्री राम जन्मभूमि',
    'nameEn': 'Ram Janmabhoomi',
    'city': 'Ayodhya'
  },
};

class LiveDarshanScreen extends StatefulWidget {
  final String templeId;
  const LiveDarshanScreen({super.key, required this.templeId});

  @override
  State<LiveDarshanScreen> createState() => _LiveDarshanScreenState();
}

class _LiveDarshanScreenState extends State<LiveDarshanScreen> {
  WebViewController? _webController;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _initPlayer();
  }

  void _initPlayer() {
    final temple = _templeYoutubeMap[widget.templeId];
    if (temple == null) return;
    final youtubeId = temple['youtubeId']!;
    if (youtubeId.startsWith('placeholder')) return;

    final controller = WebViewController()
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..setNavigationDelegate(NavigationDelegate(
        onPageFinished: (_) => setState(() => _isLoading = false),
      ))
      ..loadRequest(Uri.parse('https://m.youtube.com/watch?v=$youtubeId'));

    setState(() => _webController = controller);
  }

  @override
  Widget build(BuildContext context) {
    final temple = _templeYoutubeMap[widget.templeId] ??
        {
          'nameEn': 'Live Darshan',
          'name': 'लाइव दर्शन',
          'city': '',
          'youtubeId': ''
        };
    final youtubeId = temple['youtubeId']!;
    final isPlaceholder = youtubeId.startsWith('placeholder');

    return Scaffold(
      backgroundColor: const Color(0xFF0A0A0A),
      appBar: AppBar(
        backgroundColor: const Color(0xFF1A0A00),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () {
            if (context.canPop())
              context.pop();
            else
              context.go('/temples/${widget.templeId}');
          },
        ),
        title: Text(
          temple['nameEn']!,
          style:
              const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.fullscreen, color: Colors.white),
            onPressed: () {
              SystemChrome.setPreferredOrientations([
                DeviceOrientation.landscapeLeft,
                DeviceOrientation.landscapeRight,
              ]);
            },
          ),
        ],
      ),
      body: Column(
        children: [
          Container(
            color: Colors.black,
            height: 240,
            child: isPlaceholder
                ? Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(Icons.live_tv,
                            color: Colors.white54, size: 60),
                        const SizedBox(height: 16),
                        Text(
                          '${temple['nameEn']} Live Darshan',
                          style: const TextStyle(
                              color: Colors.white, fontSize: 16),
                        ),
                        const SizedBox(height: 8),
                        const Text(
                          'Coming Soon! 🙏',
                          style: TextStyle(color: Colors.orange, fontSize: 14),
                        ),
                      ],
                    ),
                  )
                : Stack(
                    children: [
                      if (_webController != null)
                        WebViewWidget(controller: _webController!),
                      if (_isLoading)
                        const Center(
                          child:
                              CircularProgressIndicator(color: Colors.orange),
                        ),
                    ],
                  ),
          ),
          Expanded(
            child: Container(
              color: const Color(0xFF1A0A00),
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    temple['name']!,
                    style: const TextStyle(
                        color: Colors.white,
                        fontSize: 22,
                        fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 8),
                  Row(children: [
                    const Icon(Icons.location_on,
                        color: Colors.orange, size: 16),
                    const SizedBox(width: 4),
                    Text(temple['city']!,
                        style: const TextStyle(
                            color: Colors.orange, fontSize: 14)),
                    const SizedBox(width: 12),
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 8, vertical: 3),
                      decoration: BoxDecoration(
                        color: isPlaceholder ? Colors.grey : Colors.red,
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Row(mainAxisSize: MainAxisSize.min, children: [
                        Icon(
                          isPlaceholder ? Icons.schedule : Icons.circle,
                          color: Colors.white,
                          size: 8,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          isPlaceholder ? 'Coming Soon' : 'LIVE',
                          style: const TextStyle(
                              color: Colors.white,
                              fontSize: 11,
                              fontWeight: FontWeight.bold),
                        ),
                      ]),
                    ),
                  ]),
                  const SizedBox(height: 24),
                  const Text('🙏 Jay Ho!',
                      style: TextStyle(color: Colors.white54, fontSize: 13)),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
