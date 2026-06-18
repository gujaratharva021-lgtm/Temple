class AstrologyModel {
  final String id;
  final String name;
  final String dateOfBirth;
  final String timeOfBirth;
  final String placeOfBirth;
  final String rashiName;
  final String nakshatraName;
  final String gotraName;

  AstrologyModel({
    required this.id,
    required this.name,
    required this.dateOfBirth,
    required this.timeOfBirth,
    required this.placeOfBirth,
    required this.rashiName,
    required this.nakshatraName,
    required this.gotraName,
  });

  factory AstrologyModel.fromJson(Map<String, dynamic> json) {
    return AstrologyModel(
      id: json['id'] ?? '',
      name: json['name'] ?? '',
      dateOfBirth: json['date_of_birth'] ?? '',
      timeOfBirth: json['time_of_birth'] ?? '',
      placeOfBirth: json['place_of_birth'] ?? '',
      rashiName: json['rashi_name'] ?? '',
      nakshatraName: json['nakshatra_name'] ?? '',
      gotraName: json['gotra_name'] ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'date_of_birth': dateOfBirth,
      'time_of_birth': timeOfBirth,
      'place_of_birth': placeOfBirth,
      'rashi_name': rashiName,
      'nakshatra_name': nakshatraName,
      'gotra_name': gotraName,
    };
  }
}

class ConsultationModel {
  final String id;
  final String astrologerId;
  final String astrologerName;
  final String astrologerImage;
  final String userId;
  final DateTime scheduledAt;
  final String type; // chat, call, video
  final String status; // pending, confirmed, completed, cancelled
  final double amount;
  final double rating;
  final String review;
  final int experienceYears;
  final List<String> specializations;
  final double perMinuteRate;

  ConsultationModel({
    required this.id,
    required this.astrologerId,
    required this.astrologerName,
    required this.astrologerImage,
    required this.userId,
    required this.scheduledAt,
    required this.type,
    required this.status,
    required this.amount,
    required this.rating,
    required this.review,
    required this.experienceYears,
    required this.specializations,
    required this.perMinuteRate,
  });

  factory ConsultationModel.fromJson(Map<String, dynamic> json) {
    return ConsultationModel(
      id: json['id'] ?? '',
      astrologerId: json['astrologer_id'] ?? '',
      astrologerName: json['astrologer_name'] ?? '',
      astrologerImage: json['astrologer_image'] ?? '',
      userId: json['user_id'] ?? '',
      scheduledAt: DateTime.parse(
        json['scheduled_at'] ?? DateTime.now().toIso8601String(),
      ),
      type: json['type'] ?? 'chat',
      status: json['status'] ?? 'pending',
      amount: (json['amount'] ?? 0.0).toDouble(),
      rating: (json['rating'] ?? 0.0).toDouble(),
      review: json['review'] ?? '',
      experienceYears: json['experience_years'] ?? 0,
      specializations: List<String>.from(json['specializations'] ?? []),
      perMinuteRate: (json['per_minute_rate'] ?? 0.0).toDouble(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'astrologer_id': astrologerId,
      'astrologer_name': astrologerName,
      'astrologer_image': astrologerImage,
      'user_id': userId,
      'scheduled_at': scheduledAt.toIso8601String(),
      'type': type,
      'status': status,
      'amount': amount,
      'rating': rating,
      'review': review,
      'experience_years': experienceYears,
      'specializations': specializations,
      'per_minute_rate': perMinuteRate,
    };
  }
}
