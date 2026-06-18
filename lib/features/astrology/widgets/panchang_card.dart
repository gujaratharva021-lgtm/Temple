import 'package:flutter/material.dart';
import '../../../core/services/panchang_service.dart';

class PanchangCard extends StatefulWidget {
  const PanchangCard({super.key});
  @override
  State<PanchangCard> createState() => _PanchangCardState();
}

class _PanchangCardState extends State<PanchangCard> {
  Map<String, dynamic>? _data;
  bool _loading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _fetchPanchang();
  }

  Future<void> _fetchPanchang() async {
    final data = await PanchangService.getTodayPanchang();
    setState(() {
      _data = data;
      _loading = false;
      if (data == null) _error = 'Panchang load nahi hua';
    });
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFFFF6B00), Color(0xFFFFB347)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
      ),
      child: _loading
          ? const Center(child: CircularProgressIndicator(color: Colors.white))
          : _error != null
              ? Center(
                  child: Text(_error!,
                      style: const TextStyle(color: Colors.white)))
              : _buildContent(),
    );
  }

  Widget _buildContent() {
    try {
      final panchang = (_data?['data'] is Map) ? _data!['data'] as Map : {};
      final tithiList = panchang['tithi'] as List? ?? [];
      final tithi =
          tithiList.isNotEmpty ? tithiList[0]['name']?.toString() ?? '-' : '-';
      final nakshatraList = panchang['nakshatra'] as List? ?? [];
      final nakshatra = nakshatraList.isNotEmpty
          ? nakshatraList[0]['name']?.toString() ?? '-'
          : '-';
      final yogaList = panchang['yoga'] as List? ?? [];
      final yoga =
          yogaList.isNotEmpty ? yogaList[0]['name']?.toString() ?? '-' : '-';
      final sunrise = panchang['sunrise']?.toString().substring(11, 16) ?? '-';
      final sunset = panchang['sunset']?.toString().substring(11, 16) ?? '-';
      final rahukalam = '-';

      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(children: [
            const Text('🕉️', style: TextStyle(fontSize: 22)),
            const SizedBox(width: 8),
            const Text('आज का पंचांग',
                style: TextStyle(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.bold)),
            const Spacer(),
            Text(
                '${DateTime.now().day}/${DateTime.now().month}/${DateTime.now().year}',
                style: const TextStyle(color: Colors.white70, fontSize: 12)),
          ]),
          const Divider(color: Colors.white38, height: 20),
          _buildRow('⛅ तिथि', tithi),
          _buildRow('🌟 नक्षत्र', nakshatra),
          _buildRow('🔮 योग', yoga),
          _buildRow('🌅 सूर्योदय', sunrise),
          _buildRow('🌇 सूर्यास्त', sunset),
          _buildRow('⚠️ राहुकाल', rahukalam),
        ],
      );
    } catch (e) {
      return Text('Error: $e', style: const TextStyle(color: Colors.white));
    }
  }

  Widget _buildRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(children: [
        SizedBox(
            width: 130,
            child: Text(label,
                style: const TextStyle(color: Colors.white70, fontSize: 13))),
        Expanded(
            child: Text(value,
                style: const TextStyle(
                    color: Colors.white,
                    fontSize: 13,
                    fontWeight: FontWeight.w600))),
      ]),
    );
  }
}
