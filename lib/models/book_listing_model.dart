class BookListingModel {
  final String id;
  final String sellerId;
  final String sellerName;
  final String? sellerImage;
  final double sellerRating;

  final String title;
  final String author;
  final String? isbn;
  final String department;
  final String course;
  final String condition;
  final String listingType; // 'Sell', 'Exchange', 'Both'
  final double? price;
  final String? exchangePreference;
  final List<String> images;
  final String description;

  final bool isAvailable;
  final DateTime createdAt;
  final int views;

  BookListingModel({
    required this.id,
    required this.sellerId,
    required this.sellerName,
    this.sellerImage,
    this.sellerRating = 0.0,
    required this.title,
    required this.author,
    this.isbn,
    required this.department,
    required this.course,
    required this.condition,
    required this.listingType,
    this.price,
    this.exchangePreference,
    required this.images,
    required this.description,
    this.isAvailable = true,
    required this.createdAt,
    this.views = 0,
  });

  String get conditionEmoji {
    switch (condition) {
      case 'Like New':
        return '🌟';
      case 'Very Good':
        return '✅';
      case 'Good':
        return '👍';
      case 'Acceptable':
        return '👌';
      case 'Poor':
        return '⚠️';
      default:
        return '📖';
    }
  }

  String get priceDisplay {
    if (listingType == 'Exchange') return 'Exchange Only';
    if (price == null || price == 0) return 'Free';
    return 'Rs. ${price!.toStringAsFixed(0)}';
  }

  BookListingModel copyWith({bool? isAvailable, int? views}) {
    return BookListingModel(
      id: id,
      sellerId: sellerId,
      sellerName: sellerName,
      sellerImage: sellerImage,
      sellerRating: sellerRating,
      title: title,
      author: author,
      isbn: isbn,
      department: department,
      course: course,
      condition: condition,
      listingType: listingType,
      price: price,
      exchangePreference: exchangePreference,
      images: images,
      description: description,
      isAvailable: isAvailable ?? this.isAvailable,
      createdAt: createdAt,
      views: views ?? this.views,
    );
  }

  Map<String, dynamic> toMap() => {
        'id': id,
        'sellerId': sellerId,
        'sellerName': sellerName,
        'sellerImage': sellerImage,
        'sellerRating': sellerRating,
        'title': title,
        'author': author,
        'isbn': isbn,
        'department': department,
        'course': course,
        'condition': condition,
        'listingType': listingType,
        'price': price,
        'exchangePreference': exchangePreference,
        'images': images,
        'description': description,
        'isAvailable': isAvailable,
        'createdAt': createdAt.toIso8601String(),
        'views': views,
      };

  factory BookListingModel.fromMap(Map<String, dynamic> map) =>
      BookListingModel(
        id: map['id'],
        sellerId: map['sellerId'],
        sellerName: map['sellerName'],
        sellerImage: map['sellerImage'],
        sellerRating: (map['sellerRating'] as num?)?.toDouble() ?? 0.0,
        title: map['title'],
        author: map['author'],
        isbn: map['isbn'],
        department: map['department'],
        course: map['course'],
        condition: map['condition'],
        listingType: map['listingType'],
        price: (map['price'] as num?)?.toDouble(),
        exchangePreference: map['exchangePreference'],
        images: List<String>.from(map['images'] ?? []),
        description: map['description'],
        isAvailable: map['isAvailable'] ?? true,
        createdAt: DateTime.parse(map['createdAt']),
        views: map['views'] ?? 0,
      );
}
