class ReviewModel {
  final String id;
  final String reviewerId;
  final String reviewerName;
  final String? reviewerImage;
  final String reviewedUserId;
  final double rating;
  final String comment;
  final DateTime createdAt;
  final String bookTitle;

  ReviewModel({
    required this.id,
    required this.reviewerId,
    required this.reviewerName,
    this.reviewerImage,
    required this.reviewedUserId,
    required this.rating,
    required this.comment,
    required this.createdAt,
    required this.bookTitle,
  });

  Map<String, dynamic> toMap() => {
        'id': id,
        'reviewerId': reviewerId,
        'reviewerName': reviewerName,
        'reviewerImage': reviewerImage,
        'reviewedUserId': reviewedUserId,
        'rating': rating,
        'comment': comment,
        'createdAt': createdAt.toIso8601String(),
        'bookTitle': bookTitle,
      };

  factory ReviewModel.fromMap(Map<String, dynamic> map) => ReviewModel(
        id: map['id'],
        reviewerId: map['reviewerId'],
        reviewerName: map['reviewerName'],
        reviewerImage: map['reviewerImage'],
        reviewedUserId: map['reviewedUserId'],
        rating: (map['rating'] as num).toDouble(),
        comment: map['comment'],
        createdAt: DateTime.parse(map['createdAt']),
        bookTitle: map['bookTitle'],
      );
}

class TransactionModel {
  final String id;
  final String bookId;
  final String bookTitle;
  final String? bookImage;
  final String buyerId;
  final String buyerName;
  final String sellerId;
  final String sellerName;
  final double? price;
  final String type; // 'Sold', 'Exchanged'
  final DateTime completedAt;

  TransactionModel({
    required this.id,
    required this.bookId,
    required this.bookTitle,
    this.bookImage,
    required this.buyerId,
    required this.buyerName,
    required this.sellerId,
    required this.sellerName,
    this.price,
    required this.type,
    required this.completedAt,
  });
}
