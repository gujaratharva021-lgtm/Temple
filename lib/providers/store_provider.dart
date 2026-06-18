import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../core/models/store_model.dart';

// Products Provider
class ProductNotifier extends StateNotifier<AsyncValue<List<ProductModel>>> {
  ProductNotifier() : super(const AsyncValue.loading());

  Future<void> fetchProducts({String? category}) async {
    state = const AsyncValue.loading();
    try {
      await Future.delayed(const Duration(seconds: 1));
      final products = _getDummyProducts();
      if (category != null && category != 'All') {
        state = AsyncValue.data(
          products.where((p) => p.category == category).toList(),
        );
      } else {
        state = AsyncValue.data(products);
      }
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }

  List<ProductModel> _getDummyProducts() {
    return [
      ProductModel(
        id: '1',
        name: 'Panchamrit Set',
        description:
            'Complete set for abhishek - milk, curd, honey, ghee, sugar',
        imageUrl:
            'https://images.unsplash.com/photo-1600857544200-b2f666a9a2ec',
        price: 299,
        discountPrice: 249,
        category: 'Abhishek Samagri',
        stock: 50,
        isAvailable: true,
        rating: 4.5,
        totalReviews: 230,
        images: [],
        unit: 'Set',
      ),
      ProductModel(
        id: '2',
        name: 'Gangajal 500ml',
        description: 'Pure Gangajal from Haridwar in sealed bottle',
        imageUrl: 'https://images.unsplash.com/photo-1558618666-fcd25c85cd64',
        price: 150,
        discountPrice: 120,
        category: 'Gangajal',
        stock: 100,
        isAvailable: true,
        rating: 4.8,
        totalReviews: 450,
        images: [],
        unit: 'Bottle',
      ),
      ProductModel(
        id: '3',
        name: 'Tulsi Mala',
        description: 'Original Vrindavan Tulsi beads mala - 108 beads',
        imageUrl:
            'https://images.unsplash.com/photo-1609728847937-8b98c3ba44a7',
        price: 499,
        discountPrice: 399,
        category: 'Mala',
        stock: 75,
        isAvailable: true,
        rating: 4.6,
        totalReviews: 180,
        images: [],
        unit: 'Piece',
      ),
      ProductModel(
        id: '4',
        name: 'Dhoop Sticks - Chandan',
        description: 'Premium sandalwood dhoop sticks - pack of 20',
        imageUrl:
            'https://images.unsplash.com/photo-1602928309017-e4d73697f9d0',
        price: 120,
        discountPrice: 99,
        category: 'Dhoop & Agarbatti',
        stock: 200,
        isAvailable: true,
        rating: 4.4,
        totalReviews: 320,
        images: [],
        unit: 'Pack',
      ),
      ProductModel(
        id: '5',
        name: 'Brass Diya Set',
        description: 'Set of 5 brass diyas for daily puja',
        imageUrl:
            'https://images.unsplash.com/photo-1563897539633-e56f9c1a2e55',
        price: 350,
        discountPrice: 299,
        category: 'Puja Items',
        stock: 60,
        isAvailable: true,
        rating: 4.7,
        totalReviews: 150,
        images: [],
        unit: 'Set',
      ),
      ProductModel(
        id: '6',
        name: 'Rudraksha Mala',
        description: '5 mukhi Rudraksha mala - 108 beads, original Nepal',
        imageUrl:
            'https://images.unsplash.com/photo-1609728847937-8b98c3ba44a7',
        price: 1200,
        discountPrice: 999,
        category: 'Mala',
        stock: 30,
        isAvailable: true,
        rating: 4.9,
        totalReviews: 95,
        images: [],
        unit: 'Piece',
      ),
      ProductModel(
        id: '7',
        name: 'Kumkum & Haldi Set',
        description: 'Pure kumkum and haldi for daily puja rituals',
        imageUrl:
            'https://images.unsplash.com/photo-1600857544200-b2f666a9a2ec',
        price: 80,
        discountPrice: 65,
        category: 'Abhishek Samagri',
        stock: 150,
        isAvailable: true,
        rating: 4.3,
        totalReviews: 280,
        images: [],
        unit: 'Set',
      ),
      ProductModel(
        id: '8',
        name: 'Puja Thali Set',
        description: 'Complete brass puja thali with all accessories',
        imageUrl:
            'https://images.unsplash.com/photo-1563897539633-e56f9c1a2e55',
        price: 850,
        discountPrice: 699,
        category: 'Puja Items',
        stock: 40,
        isAvailable: true,
        rating: 4.6,
        totalReviews: 120,
        images: [],
        unit: 'Set',
      ),
    ];
  }
}

final productProvider =
    StateNotifierProvider<ProductNotifier, AsyncValue<List<ProductModel>>>(
  (ref) => ProductNotifier(),
);

// Cart Provider
class CartNotifier extends StateNotifier<List<CartItemModel>> {
  CartNotifier() : super([]);

  void addToCart(ProductModel product) {
    final existingIndex =
        state.indexWhere((item) => item.product.id == product.id);
    if (existingIndex >= 0) {
      final updated = [...state];
      updated[existingIndex].quantity++;
      state = updated;
    } else {
      state = [
        ...state,
        CartItemModel(
          id: DateTime.now().millisecondsSinceEpoch.toString(),
          product: product,
          quantity: 1,
        ),
      ];
    }
  }

  void removeFromCart(String productId) {
    state = state.where((item) => item.product.id != productId).toList();
  }

  void updateQuantity(String productId, int quantity) {
    if (quantity <= 0) {
      removeFromCart(productId);
      return;
    }
    state = state.map((item) {
      if (item.product.id == productId) {
        item.quantity = quantity;
      }
      return item;
    }).toList();
  }

  void clearCart() {
    state = [];
  }

  double get totalAmount {
    return state.fold(0, (sum, item) => sum + item.totalPrice);
  }

  int get totalItems {
    return state.fold(0, (sum, item) => sum + item.quantity);
  }
}

final cartProvider = StateNotifierProvider<CartNotifier, List<CartItemModel>>(
  (ref) => CartNotifier(),
);

// Cart total provider
final cartTotalProvider = Provider<double>((ref) {
  final cart = ref.watch(cartProvider);
  return cart.fold(0, (sum, item) => sum + item.totalPrice);
});

// Cart items count provider
final cartItemsCountProvider = Provider<int>((ref) {
  final cart = ref.watch(cartProvider);
  return cart.fold(0, (sum, item) => sum + item.quantity);
});

// Category Provider
final selectedCategoryProvider = StateProvider<String>((ref) => 'All');

// Filtered Products Provider
final filteredProductsProvider =
    Provider<AsyncValue<List<ProductModel>>>((ref) {
  final products = ref.watch(productProvider);
  final category = ref.watch(selectedCategoryProvider);

  return products.whenData((list) {
    if (category == 'All') return list;
    return list.where((p) => p.category == category).toList();
  });
});
