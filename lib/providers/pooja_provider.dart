import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../core/models/pooja_model.dart';

// Pooja List Provider
class PoojaNotifier extends StateNotifier<AsyncValue<List<PoojaModel>>> {
  PoojaNotifier() : super(const AsyncValue.loading());

  Future<void> fetchPoojas({String? templeId}) async {
    state = const AsyncValue.loading();
    try {
      await Future.delayed(const Duration(seconds: 1));
      final poojas = _getDummyPoojas()
          .where((p) => templeId == null || p.templeId == templeId)
          .toList();
      state = AsyncValue.data(poojas);
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }

  List<PoojaModel> _getDummyPoojas() {
    return [
      PoojaModel(
        id: '1',
        name: 'Rudrabhishek',
        description: 'Sacred abhishek of Lord Shiva with milk, honey and water',
        imageUrl:
            'https://images.unsplash.com/photo-1567591370464-b5e4cf37f894',
        price: 1100,
        duration: '1 Hour',
        templeId: '2',
        templeName: 'Shri Kashi Vishwanath Temple',
        samagriList: ['Milk', 'Honey', 'Gangajal', 'Bilva Patra', 'Flowers'],
        isAvailable: true,
        category: 'Abhishek',
      ),
      PoojaModel(
        id: '2',
        name: 'Satyanarayan Katha',
        description: 'Complete Satyanarayan Puja with katha and prasad',
        imageUrl:
            'https://images.unsplash.com/photo-1610282985576-d843c977a5c8',
        price: 2100,
        duration: '2 Hours',
        templeId: '1',
        templeName: 'Shri Siddhivinayak Temple',
        samagriList: ['Panchamrit', 'Tulsi', 'Flowers', 'Prasad', 'Incense'],
        isAvailable: true,
        category: 'Katha',
      ),
      PoojaModel(
        id: '3',
        name: 'Ganesh Abhishek',
        description: 'Special abhishek of Lord Ganesh with modak prasad',
        imageUrl:
            'https://images.unsplash.com/photo-1599490659213-e2b9527bd087',
        price: 551,
        duration: '45 Minutes',
        templeId: '1',
        templeName: 'Shri Siddhivinayak Temple',
        samagriList: ['Modak', 'Durva', 'Red Flowers', 'Coconut'],
        isAvailable: true,
        category: 'Abhishek',
      ),
      PoojaModel(
        id: '4',
        name: 'Navgraha Shanti Puja',
        description: 'Puja to appease all 9 planets and remove doshas',
        imageUrl:
            'https://images.unsplash.com/photo-1584786369571-f99fc47f8a64',
        price: 3100,
        duration: '3 Hours',
        templeId: '5',
        templeName: 'ISKCON Temple Delhi',
        samagriList: ['9 Grains', 'Colored Cloth', 'Ghee', 'Flowers', 'Fruits'],
        isAvailable: true,
        category: 'Shanti',
      ),
      PoojaModel(
        id: '5',
        name: 'Lakshmi Puja',
        description: 'Special puja for wealth and prosperity',
        imageUrl:
            'https://images.unsplash.com/photo-1567591370464-b5e4cf37f894',
        price: 1501,
        duration: '1.5 Hours',
        templeId: '3',
        templeName: 'Shri Tirupati Balaji Temple',
        samagriList: [
          'Lotus Flowers',
          'Coconut',
          'Sweets',
          'Gold Coin',
          'Red Cloth'
        ],
        isAvailable: true,
        category: 'Prosperity',
      ),
    ];
  }
}

final poojaProvider =
    StateNotifierProvider<PoojaNotifier, AsyncValue<List<PoojaModel>>>(
  (ref) => PoojaNotifier(),
);

// Booking Notifier
class BookingNotifier extends StateNotifier<AsyncValue<List<BookingModel>>> {
  BookingNotifier() : super(const AsyncValue.data([]));

  Future<bool> createBooking(BookingModel booking) async {
    try {
      await Future.delayed(const Duration(seconds: 1));
      final current = state.value ?? [];
      state = AsyncValue.data([...current, booking]);
      return true;
    } catch (e, st) {
      state = AsyncValue.error(e, st);
      return false;
    }
  }

  Future<void> fetchMyBookings() async {
    state = const AsyncValue.loading();
    try {
      await Future.delayed(const Duration(seconds: 1));
      state = const AsyncValue.data([]);
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }

  Future<bool> cancelBooking(String bookingId) async {
    try {
      await Future.delayed(const Duration(seconds: 1));
      final current = state.value ?? [];
      state = AsyncValue.data(
        current
            .map((b) => b.id == bookingId
                ? BookingModel(
                    id: b.id,
                    poojaId: b.poojaId,
                    poojaName: b.poojaName,
                    templeId: b.templeId,
                    templeName: b.templeName,
                    userId: b.userId,
                    bookingDate: b.bookingDate,
                    timeSlot: b.timeSlot,
                    status: 'cancelled',
                    amount: b.amount,
                    sankalp: b.sankalp,
                    gotraName: b.gotraName,
                  )
                : b)
            .toList(),
      );
      return true;
    } catch (e, st) {
      state = AsyncValue.error(e, st);
      return false;
    }
  }
}

final bookingProvider =
    StateNotifierProvider<BookingNotifier, AsyncValue<List<BookingModel>>>(
  (ref) => BookingNotifier(),
);

// Selected Pooja Provider
final selectedPoojaProvider = StateProvider<PoojaModel?>((ref) => null);

// Selected Date Provider
final selectedDateProvider = StateProvider<DateTime?>((ref) => null);

// Selected Time Slot Provider
final selectedTimeSlotProvider = StateProvider<String?>((ref) => null);
