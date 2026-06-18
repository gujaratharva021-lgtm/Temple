import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../core/models/temple_model.dart';

// Temple List Provider
class TempleNotifier extends StateNotifier<AsyncValue<List<TempleModel>>> {
  TempleNotifier() : super(const AsyncValue.loading());

  Future<void> fetchTemples() async {
    state = const AsyncValue.loading();
    try {
      // TODO: Replace with real API call
      await Future.delayed(const Duration(seconds: 1));
      final temples = _getDummyTemples();
      state = AsyncValue.data(temples);
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }

  List<TempleModel> _getDummyTemples() {
    return [
      TempleModel(
        id: '1',
        name: 'Shri Siddhivinayak Temple',
        description: 'Famous Ganesh temple in Mumbai',
        imageUrl:
            'https://upload.wikimedia.org/wikipedia/commons/thumb/6/6b/Siddhivinayak_Temple%2C_Mumbai.jpg/800px-Siddhivinayak_Temple%2C_Mumbai.jpg',
        location: 'Prabhadevi, Mumbai',
        latitude: 19.0169,
        longitude: 72.8306,
        openTime: '05:30 AM',
        closeTime: '09:30 PM',
        rating: 4.8,
        totalReviews: 12500,
        isLiveDarshan: true,
        festivals: ['Ganesh Chaturthi', 'Sankashti Chaturthi'],
        deities: ['Ganesh'],
      ),
      TempleModel(
        id: '2',
        name: 'Shri Kashi Vishwanath Temple',
        description:
            'One of the most famous Hindu temples dedicated to Lord Shiva',
        imageUrl:
            'https://upload.wikimedia.org/wikipedia/commons/thumb/d/d5/Kashi_Vishwanath_Temple.jpg/800px-Kashi_Vishwanath_Temple.jpg',
        location: 'Varanasi, Uttar Pradesh',
        latitude: 25.3109,
        longitude: 83.0107,
        openTime: '04:00 AM',
        closeTime: '11:00 PM',
        rating: 4.9,
        totalReviews: 25000,
        isLiveDarshan: true,
        festivals: ['Mahashivratri', 'Sawan'],
        deities: ['Shiva'],
      ),
      TempleModel(
        id: '3',
        name: 'Shri Tirupati Balaji Temple',
        description: 'Richest and most visited temple in the world',
        imageUrl:
            'https://upload.wikimedia.org/wikipedia/commons/thumb/4/4f/Tirumala_Temple_Entrance.jpg/800px-Tirumala_Temple_Entrance.jpg',
        location: 'Tirumala, Andhra Pradesh',
        latitude: 13.6834,
        longitude: 79.3470,
        openTime: '03:00 AM',
        closeTime: '11:00 PM',
        rating: 4.9,
        totalReviews: 50000,
        isLiveDarshan: true,
        festivals: ['Brahmotsavam', 'Vaikunta Ekadashi'],
        deities: ['Vishnu', 'Balaji'],
      ),
      TempleModel(
        id: '4',
        name: 'Shri Mata Vaishno Devi',
        description: 'Sacred cave shrine dedicated to Goddess Vaishno Devi',
        imageUrl:
            'https://upload.wikimedia.org/wikipedia/commons/thumb/1/1e/Vaishno_Devi_Temple.jpg/800px-Vaishno_Devi_Temple.jpg',
        location: 'Katra, Jammu & Kashmir',
        latitude: 32.9918,
        longitude: 74.9520,
        openTime: '00:00 AM',
        closeTime: '11:59 PM',
        rating: 4.9,
        totalReviews: 35000,
        isLiveDarshan: false,
        festivals: ['Navratri', 'Diwali'],
        deities: ['Durga', 'Vaishno Devi'],
      ),
      TempleModel(
        id: '5',
        name: 'ISKCON Temple Delhi',
        description: 'Beautiful Krishna temple in New Delhi',
        imageUrl:
            'https://upload.wikimedia.org/wikipedia/commons/thumb/7/7c/ISKCON_Temple_Delhi.jpg/800px-ISKCON_Temple_Delhi.jpg',
        location: 'East of Kailash, New Delhi',
        latitude: 28.5507,
        longitude: 77.2334,
        openTime: '04:30 AM',
        closeTime: '09:00 PM',
        rating: 4.7,
        totalReviews: 18000,
        isLiveDarshan: true,
        festivals: ['Janmashtami', 'Holi', 'Radhashtami'],
        deities: ['Krishna', 'Radha'],
      ),
    ];
  }
}

final templeProvider =
    StateNotifierProvider<TempleNotifier, AsyncValue<List<TempleModel>>>(
  (ref) => TempleNotifier(),
);

// Search Provider
final searchQueryProvider = StateProvider<String>((ref) => '');

final filteredTemplesProvider = Provider<AsyncValue<List<TempleModel>>>((ref) {
  final temples = ref.watch(templeProvider);
  final query = ref.watch(searchQueryProvider).toLowerCase();

  return temples.whenData((list) {
    if (query.isEmpty) return list;
    return list
        .where((t) =>
            t.name.toLowerCase().contains(query) ||
            t.location.toLowerCase().contains(query) ||
            t.deities.any((d) => d.toLowerCase().contains(query)))
        .toList();
  });
});

// Selected Temple Provider
final selectedTempleProvider = StateProvider<TempleModel?>((ref) => null);
