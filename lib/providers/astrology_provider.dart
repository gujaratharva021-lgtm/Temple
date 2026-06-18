import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../core/models/astrology_model.dart';

// Astrologers Provider
class AstrologerNotifier
    extends StateNotifier<AsyncValue<List<ConsultationModel>>> {
  AstrologerNotifier() : super(const AsyncValue.loading());

  Future<void> fetchAstrologers() async {
    state = const AsyncValue.loading();
    try {
      await Future.delayed(const Duration(seconds: 1));
      state = AsyncValue.data(_getDummyAstrologers());
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }

  List<ConsultationModel> _getDummyAstrologers() {
    return [
      ConsultationModel(
        id: '1',
        astrologerId: 'a1',
        astrologerName: 'Pandit Rajesh Sharma',
        astrologerImage:
            'https://images.unsplash.com/photo-1566492031773-4f4e44671857',
        userId: '',
        scheduledAt: DateTime.now(),
        type: 'chat',
        status: 'available',
        amount: 0,
        rating: 4.8,
        review: '',
        experienceYears: 15,
        specializations: ['Kundli', 'Vastu', 'Numerology'],
        perMinuteRate: 20,
      ),
      ConsultationModel(
        id: '2',
        astrologerId: 'a2',
        astrologerName: 'Acharya Suresh Mishra',
        astrologerImage:
            'https://images.unsplash.com/photo-1552058544-f2b08422138a',
        userId: '',
        scheduledAt: DateTime.now(),
        type: 'call',
        status: 'available',
        amount: 0,
        rating: 4.6,
        review: '',
        experienceYears: 20,
        specializations: ['Marriage', 'Career', 'Health'],
        perMinuteRate: 30,
      ),
      ConsultationModel(
        id: '3',
        astrologerId: 'a3',
        astrologerName: 'Jyotishi Priya Devi',
        astrologerImage:
            'https://images.unsplash.com/photo-1494790108377-be9c29b29330',
        userId: '',
        scheduledAt: DateTime.now(),
        type: 'video',
        status: 'available',
        amount: 0,
        rating: 4.9,
        review: '',
        experienceYears: 12,
        specializations: ['Tarot', 'Palmistry', 'Horoscope'],
        perMinuteRate: 25,
      ),
      ConsultationModel(
        id: '4',
        astrologerId: 'a4',
        astrologerName: 'Pandit Vikram Joshi',
        astrologerImage:
            'https://images.unsplash.com/photo-1500648767791-00dcc994a43e',
        userId: '',
        scheduledAt: DateTime.now(),
        type: 'chat',
        status: 'busy',
        amount: 0,
        rating: 4.5,
        review: '',
        experienceYears: 8,
        specializations: ['Muhurat', 'Gemstone', 'Vastu'],
        perMinuteRate: 15,
      ),
      ConsultationModel(
        id: '5',
        astrologerId: 'a5',
        astrologerName: 'Acharya Deepak Trivedi',
        astrologerImage:
            'https://images.unsplash.com/photo-1472099645785-5658abf4ff4e',
        userId: '',
        scheduledAt: DateTime.now(),
        type: 'call',
        status: 'available',
        amount: 0,
        rating: 4.7,
        review: '',
        experienceYears: 25,
        specializations: ['Kundli Milan', 'Prashna', 'Remedies'],
        perMinuteRate: 35,
      ),
    ];
  }
}

final astrologerProvider = StateNotifierProvider<AstrologerNotifier,
    AsyncValue<List<ConsultationModel>>>(
  (ref) => AstrologerNotifier(),
);

// Kundli Provider
class KundliNotifier extends StateNotifier<AstrologyModel?> {
  KundliNotifier() : super(null);

  void setKundliData(AstrologyModel model) {
    state = model;
  }

  void clearKundli() {
    state = null;
  }
}

final kundliProvider = StateNotifierProvider<KundliNotifier, AstrologyModel?>(
  (ref) => KundliNotifier(),
);

// Selected Consultation Type
final selectedConsultationTypeProvider = StateProvider<String>((ref) => 'All');

// Filtered Astrologers Provider
final filteredAstrologersProvider =
    Provider<AsyncValue<List<ConsultationModel>>>((ref) {
  final astrologers = ref.watch(astrologerProvider);
  final type = ref.watch(selectedConsultationTypeProvider);

  return astrologers.whenData((list) {
    if (type == 'All') return list;
    return list.where((a) => a.type == type.toLowerCase()).toList();
  });
});

// Daily Horoscope Provider
class HoroscopeNotifier extends StateNotifier<Map<String, String>> {
  HoroscopeNotifier() : super({});

  Future<void> fetchHoroscope() async {
    await Future.delayed(const Duration(seconds: 1));
    state = {
      'Mesh': 'Aaj ka din aapke liye shubh hai. Vyapar mein labh hoga.',
      'Vrishabh': 'Parivar ke saath samay bitayein. Swasthya ka dhyan rakhein.',
      'Mithun': 'Nayi opportunities aayengi. Dhairya rakhein.',
      'Kark': 'Aarthik sthiti mazboot hogi. Naye nivesh ke bare mein sochein.',
      'Simha': 'Aapka aatmavishwas aaj peak par hoga. Career mein tarakki.',
      'Kanya': 'Rishton mein madhurta aayegi. Yatra ke yog hain.',
      'Tula': 'Santulan banaye rakhein. Vivad se bachein.',
      'Vrishchik': 'Gupt gyaan prapt hoga. Adhyatmik jagriti ka samay.',
      'Dhanu': 'Safalta aapke kadam chumegi. Naye kaam mein haath daalein.',
      'Makar': 'Mehnat rang layegi. Superiors ki nazar mein aayenge.',
      'Kumbh': 'Innovative ideas aayenge. Dosto ka saath milega.',
      'Meen': 'Bhavnaon par kabu rakhein. Puja path se shanti milegi.',
    };
  }
}

final horoscopeProvider =
    StateNotifierProvider<HoroscopeNotifier, Map<String, String>>(
  (ref) => HoroscopeNotifier(),
);

// Selected Rashi Provider
final selectedRashiProvider = StateProvider<String>((ref) => 'Mesh');
