class UserModel {
  final String id;
  final String name;
  final String email;
  final String university;
  final String department;
  final String? profileImage;
  final String? phone;
  final double rating;
  final int totalRatings;
  final int totalListings;
  final int totalTransactions;
  final DateTime createdAt;

  UserModel({
    required this.id,
    required this.name,
    required this.email,
    required this.university,
    required this.department,
    this.profileImage,
    this.phone,
    this.rating = 0.0,
    this.totalRatings = 0,
    this.totalListings = 0,
    this.totalTransactions = 0,
    required this.createdAt,
  });

  UserModel copyWith({
    String? name,
    String? profileImage,
    String? phone,
    String? department,
    double? rating,
    int? totalRatings,
    int? totalListings,
    int? totalTransactions,
  }) {
    return UserModel(
      id: id,
      name: name ?? this.name,
      email: email,
      university: university,
      department: department ?? this.department,
      profileImage: profileImage ?? this.profileImage,
      phone: phone ?? this.phone,
      rating: rating ?? this.rating,
      totalRatings: totalRatings ?? this.totalRatings,
      totalListings: totalListings ?? this.totalListings,
      totalTransactions: totalTransactions ?? this.totalTransactions,
      createdAt: createdAt,
    );
  }

  Map<String, dynamic> toMap() => {
        'id': id,
        'name': name,
        'email': email,
        'university': university,
        'department': department,
        'profileImage': profileImage,
        'phone': phone,
        'rating': rating,
        'totalRatings': totalRatings,
        'totalListings': totalListings,
        'totalTransactions': totalTransactions,
        'createdAt': createdAt.toIso8601String(),
      };

  factory UserModel.fromMap(Map<String, dynamic> map) => UserModel(
        id: map['id'],
        name: map['name'],
        email: map['email'],
        university: map['university'],
        department: map['department'],
        profileImage: map['profileImage'],
        phone: map['phone'],
        rating: (map['rating'] as num?)?.toDouble() ?? 0.0,
        totalRatings: map['totalRatings'] ?? 0,
        totalListings: map['totalListings'] ?? 0,
        totalTransactions: map['totalTransactions'] ?? 0,
        createdAt: DateTime.parse(map['createdAt']),
      );
}
