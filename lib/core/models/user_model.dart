class UserModel {
  final String id;
  final String name;
  final String email;
  final String phone;
  final String profileImage;
  final String gotraName;
  final String dateOfBirth;
  final String gender;
  final String city;
  final String state;
  final bool isVerified;
  final DateTime createdAt;

  UserModel({
    required this.id,
    required this.name,
    required this.email,
    required this.phone,
    required this.profileImage,
    required this.gotraName,
    required this.dateOfBirth,
    required this.gender,
    required this.city,
    required this.state,
    required this.isVerified,
    required this.createdAt,
  });

  factory UserModel.fromJson(Map<String, dynamic> json) {
    return UserModel(
      id: json['id'] ?? '',
      name: json['name'] ?? '',
      email: json['email'] ?? '',
      phone: json['phone'] ?? '',
      profileImage: json['profile_image'] ?? '',
      gotraName: json['gotra_name'] ?? '',
      dateOfBirth: json['date_of_birth'] ?? '',
      gender: json['gender'] ?? '',
      city: json['city'] ?? '',
      state: json['state'] ?? '',
      isVerified: json['is_verified'] ?? false,
      createdAt: DateTime.parse(
        json['created_at'] ?? DateTime.now().toIso8601String(),
      ),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'email': email,
      'phone': phone,
      'profile_image': profileImage,
      'gotra_name': gotraName,
      'date_of_birth': dateOfBirth,
      'gender': gender,
      'city': city,
      'state': state,
      'is_verified': isVerified,
      'created_at': createdAt.toIso8601String(),
    };
  }

  UserModel copyWith({
    String? name,
    String? email,
    String? phone,
    String? profileImage,
    String? gotraName,
    String? dateOfBirth,
    String? gender,
    String? city,
    String? state,
  }) {
    return UserModel(
      id: id,
      name: name ?? this.name,
      email: email ?? this.email,
      phone: phone ?? this.phone,
      profileImage: profileImage ?? this.profileImage,
      gotraName: gotraName ?? this.gotraName,
      dateOfBirth: dateOfBirth ?? this.dateOfBirth,
      gender: gender ?? this.gender,
      city: city ?? this.city,
      state: state ?? this.state,
      isVerified: isVerified,
      createdAt: createdAt,
    );
  }
}
