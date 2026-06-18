class PoojaModel {
  final String id;
  final String name;
  final String description;
  final String imageUrl;
  final double price;
  final String duration;
  final String templeId;
  final String templeName;
  final List<String> samagriList;
  final bool isAvailable;
  final String category;

  PoojaModel({
    required this.id,
    required this.name,
    required this.description,
    required this.imageUrl,
    required this.price,
    required this.duration,
    required this.templeId,
    required this.templeName,
    required this.samagriList,
    required this.isAvailable,
    required this.category,
  });

  factory PoojaModel.fromJson(Map<String, dynamic> json) {
    return PoojaModel(
      id: json['id'] ?? '',
      name: json['name'] ?? '',
      description: json['description'] ?? '',
      imageUrl: json['image_url'] ?? '',
      price: (json['price'] ?? 0.0).toDouble(),
      duration: json['duration'] ?? '',
      templeId: json['temple_id'] ?? '',
      templeName: json['temple_name'] ?? '',
      samagriList: List<String>.from(json['samagri_list'] ?? []),
      isAvailable: json['is_available'] ?? true,
      category: json['category'] ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'description': description,
      'image_url': imageUrl,
      'price': price,
      'duration': duration,
      'temple_id': templeId,
      'temple_name': templeName,
      'samagri_list': samagriList,
      'is_available': isAvailable,
      'category': category,
    };
  }
}

class BookingModel {
  final String id;
  final String poojaId;
  final String poojaName;
  final String templeId;
  final String templeName;
  final String userId;
  final DateTime bookingDate;
  final String timeSlot;
  final String status; // pending, confirmed, completed, cancelled
  final double amount;
  final String sankalp;
  final String gotraName;

  BookingModel({
    required this.id,
    required this.poojaId,
    required this.poojaName,
    required this.templeId,
    required this.templeName,
    required this.userId,
    required this.bookingDate,
    required this.timeSlot,
    required this.status,
    required this.amount,
    required this.sankalp,
    required this.gotraName,
  });

  factory BookingModel.fromJson(Map<String, dynamic> json) {
    return BookingModel(
      id: json['id'] ?? '',
      poojaId: json['pooja_id'] ?? '',
      poojaName: json['pooja_name'] ?? '',
      templeId: json['temple_id'] ?? '',
      templeName: json['temple_name'] ?? '',
      userId: json['user_id'] ?? '',
      bookingDate: DateTime.parse(json['booking_date']),
      timeSlot: json['time_slot'] ?? '',
      status: json['status'] ?? 'pending',
      amount: (json['amount'] ?? 0.0).toDouble(),
      sankalp: json['sankalp'] ?? '',
      gotraName: json['gotra_name'] ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'pooja_id': poojaId,
      'pooja_name': poojaName,
      'temple_id': templeId,
      'temple_name': templeName,
      'user_id': userId,
      'booking_date': bookingDate.toIso8601String(),
      'time_slot': timeSlot,
      'status': status,
      'amount': amount,
      'sankalp': sankalp,
      'gotra_name': gotraName,
    };
  }
}
