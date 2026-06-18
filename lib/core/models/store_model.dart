class ProductModel {
  final String id;
  final String name;
  final String description;
  final String imageUrl;
  final double price;
  final double discountPrice;
  final String category;
  final int stock;
  final bool isAvailable;
  final double rating;
  final int totalReviews;
  final List<String> images;
  final String unit;

  ProductModel({
    required this.id,
    required this.name,
    required this.description,
    required this.imageUrl,
    required this.price,
    required this.discountPrice,
    required this.category,
    required this.stock,
    required this.isAvailable,
    required this.rating,
    required this.totalReviews,
    required this.images,
    required this.unit,
  });

  factory ProductModel.fromJson(Map<String, dynamic> json) {
    return ProductModel(
      id: json['id'] ?? '',
      name: json['name'] ?? '',
      description: json['description'] ?? '',
      imageUrl: json['image_url'] ?? '',
      price: (json['price'] ?? 0.0).toDouble(),
      discountPrice: (json['discount_price'] ?? 0.0).toDouble(),
      category: json['category'] ?? '',
      stock: json['stock'] ?? 0,
      isAvailable: json['is_available'] ?? true,
      rating: (json['rating'] ?? 0.0).toDouble(),
      totalReviews: json['total_reviews'] ?? 0,
      images: List<String>.from(json['images'] ?? []),
      unit: json['unit'] ?? 'piece',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'description': description,
      'image_url': imageUrl,
      'price': price,
      'discount_price': discountPrice,
      'category': category,
      'stock': stock,
      'is_available': isAvailable,
      'rating': rating,
      'total_reviews': totalReviews,
      'images': images,
      'unit': unit,
    };
  }
}

class CartItemModel {
  final String id;
  final ProductModel product;
  int quantity;

  CartItemModel({
    required this.id,
    required this.product,
    required this.quantity,
  });

  double get totalPrice => product.discountPrice > 0
      ? product.discountPrice * quantity
      : product.price * quantity;
}

class OrderModel {
  final String id;
  final String userId;
  final List<CartItemModel> items;
  final double totalAmount;
  final String status; // pending, confirmed, shipped, delivered, cancelled
  final String address;
  final DateTime orderDate;
  final String paymentMethod;
  final String paymentStatus;

  OrderModel({
    required this.id,
    required this.userId,
    required this.items,
    required this.totalAmount,
    required this.status,
    required this.address,
    required this.orderDate,
    required this.paymentMethod,
    required this.paymentStatus,
  });

  factory OrderModel.fromJson(Map<String, dynamic> json) {
    return OrderModel(
      id: json['id'] ?? '',
      userId: json['user_id'] ?? '',
      items: (json['items'] as List<dynamic>? ?? [])
          .map((e) => CartItemModel(
                id: e['id'] ?? '',
                product: ProductModel.fromJson(e['product']),
                quantity: e['quantity'] ?? 1,
              ))
          .toList(),
      totalAmount: (json['total_amount'] ?? 0.0).toDouble(),
      status: json['status'] ?? 'pending',
      address: json['address'] ?? '',
      orderDate: DateTime.parse(
        json['order_date'] ?? DateTime.now().toIso8601String(),
      ),
      paymentMethod: json['payment_method'] ?? '',
      paymentStatus: json['payment_status'] ?? 'pending',
    );
  }
}
