class TempleModel {
  final String id;
  final String name;
  final String description;
  final String imageUrl;
  final String location;
  final double latitude;
  final double longitude;
  final String openTime;
  final String closeTime;
  final double rating;
  final int totalReviews;
  final bool isLiveDarshan;
  final List<String> festivals;
  final List<String> deities;

  TempleModel({
    required this.id,
    required this.name,
    required this.description,
    required this.imageUrl,
    required this.location,
    required this.latitude,
    required this.longitude,
    required this.openTime,
    required this.closeTime,
    required this.rating,
    required this.totalReviews,
    required this.isLiveDarshan,
    required this.festivals,
    required this.deities,
  });

  factory TempleModel.fromJson(Map<String, dynamic> json) {
    return TempleModel(
      id: json['id'] ?? '',
      name: json['name'] ?? '',
      description: json['description'] ?? '',
      imageUrl: json['image_url'] ?? '',
      location: json['location'] ?? '',
      latitude: (json['latitude'] ?? 0.0).toDouble(),
      longitude: (json['longitude'] ?? 0.0).toDouble(),
      openTime: json['open_time'] ?? '',
      closeTime: json['close_time'] ?? '',
      rating: (json['rating'] ?? 0.0).toDouble(),
      totalReviews: json['total_reviews'] ?? 0,
      isLiveDarshan: json['is_live_darshan'] ?? false,
      festivals: List<String>.from(json['festivals'] ?? []),
      deities: List<String>.from(json['deities'] ?? []),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'description': description,
      'image_url': imageUrl,
      'location': location,
      'latitude': latitude,
      'longitude': longitude,
      'open_time': openTime,
      'close_time': closeTime,
      'rating': rating,
      'total_reviews': totalReviews,
      'is_live_darshan': isLiveDarshan,
      'festivals': festivals,
      'deities': deities,
    };
  }
}
