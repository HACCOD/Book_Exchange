import 'package:flutter/material.dart';
import 'package:uuid/uuid.dart';
import '../models/book_listing_model.dart';
import '../models/review_model.dart';

class BookProvider extends ChangeNotifier {
  final List<BookListingModel> _listings = [];
  final List<ReviewModel> _reviews = [];
  final List<TransactionModel> _transactions = [];

  bool _isLoading = false;
  String _searchQuery = '';
  String _selectedDepartment = 'All';
  String _selectedType = 'All';
  String _sortBy = 'Newest First';
  double _maxPrice = 5000;

  bool get isLoading => _isLoading;
  String get searchQuery => _searchQuery;
  String get selectedDepartment => _selectedDepartment;
  String get selectedType => _selectedType;
  String get sortBy => _sortBy;
  double get maxPrice => _maxPrice;

  List<BookListingModel> get allListings => List.unmodifiable(_listings);

  List<BookListingModel> get filteredListings {
    List<BookListingModel> result =
        _listings.where((b) => b.isAvailable).toList();

    if (_searchQuery.isNotEmpty) {
      final q = _searchQuery.toLowerCase();
      result = result
          .where((b) =>
              b.title.toLowerCase().contains(q) ||
              b.author.toLowerCase().contains(q) ||
              (b.isbn?.toLowerCase().contains(q) ?? false) ||
              b.course.toLowerCase().contains(q))
          .toList();
    }

    if (_selectedDepartment != 'All') {
      result =
          result.where((b) => b.department == _selectedDepartment).toList();
    }

    if (_selectedType != 'All') {
      result = result
          .where((b) =>
              b.listingType == _selectedType || b.listingType == 'Both')
          .toList();
    }

    result = result.where((b) {
      if (b.listingType == 'Exchange') return true;
      return (b.price ?? 0) <= _maxPrice;
    }).toList();

    switch (_sortBy) {
      case 'Price: Low to High':
        result.sort((a, b) => (a.price ?? 0).compareTo(b.price ?? 0));
        break;
      case 'Price: High to Low':
        result.sort((a, b) => (b.price ?? 0).compareTo(a.price ?? 0));
        break;
      case 'Best Condition':
        const order = ['Like New', 'Very Good', 'Good', 'Acceptable', 'Poor'];
        result.sort((a, b) =>
            order.indexOf(a.condition).compareTo(order.indexOf(b.condition)));
        break;
      default:
        result.sort((a, b) => b.createdAt.compareTo(a.createdAt));
    }

    return result;
  }

  List<BookListingModel> listingsForUser(String userId) =>
      _listings.where((b) => b.sellerId == userId).toList();

  List<ReviewModel> reviewsForUser(String userId) =>
      _reviews.where((r) => r.reviewedUserId == userId).toList();

  List<TransactionModel> transactionsForUser(String userId) => _transactions
      .where((t) => t.buyerId == userId || t.sellerId == userId)
      .toList();

  void setSearch(String query) {
    _searchQuery = query;
    notifyListeners();
  }

  void setDepartmentFilter(String dept) {
    _selectedDepartment = dept;
    notifyListeners();
  }

  void setTypeFilter(String type) {
    _selectedType = type;
    notifyListeners();
  }

  void setSortBy(String sort) {
    _sortBy = sort;
    notifyListeners();
  }

  void setMaxPrice(double price) {
    _maxPrice = price;
    notifyListeners();
  }

  void clearFilters() {
    _searchQuery = '';
    _selectedDepartment = 'All';
    _selectedType = 'All';
    _sortBy = 'Newest First';
    _maxPrice = 5000;
    notifyListeners();
  }

  Future<void> addListing(BookListingModel listing) async {
    _isLoading = true;
    notifyListeners();
    await Future.delayed(const Duration(milliseconds: 500));
    _listings.insert(0, listing);
    _isLoading = false;
    notifyListeners();
  }

  Future<void> deleteListing(String listingId) async {
    _listings.removeWhere((b) => b.id == listingId);
    notifyListeners();
  }

  Future<void> markAsSold(String listingId) async {
    final idx = _listings.indexWhere((b) => b.id == listingId);
    if (idx != -1) {
      _listings[idx] = _listings[idx].copyWith(isAvailable: false);
      notifyListeners();
    }
  }

  void incrementViews(String listingId) {
    final idx = _listings.indexWhere((b) => b.id == listingId);
    if (idx != -1) {
      _listings[idx] =
          _listings[idx].copyWith(views: _listings[idx].views + 1);
      notifyListeners();
    }
  }

  void addReview(ReviewModel review) {
    _reviews.add(review);
    notifyListeners();
  }

  void addTransaction(TransactionModel transaction) {
    _transactions.add(transaction);
    notifyListeners();
  }

  void loadDemoData(String currentUserId) {
    if (_listings.isNotEmpty) return;
    final uuid = const Uuid();
    final now = DateTime.now();

    _listings.addAll([
      BookListingModel(
        id: uuid.v4(),
        sellerId: 'other-user-1',
        sellerName: 'Sara Khan',
        sellerRating: 4.8,
        title: 'Introduction to Algorithms',
        author: 'Cormen, Leiserson, Rivest',
        isbn: '978-0262033848',
        department: 'Computer Science',
        course: 'CS301 - Data Structures',
        condition: 'Very Good',
        listingType: 'Sell',
        price: 1200,
        images: [],
        description:
            'Used for one semester only. Minor highlights on a few pages. All content intact.',
        createdAt: now.subtract(const Duration(hours: 2)),
        views: 34,
      ),
      BookListingModel(
        id: uuid.v4(),
        sellerId: 'other-user-2',
        sellerName: 'Usman Ali',
        sellerRating: 4.2,
        title: 'Calculus: Early Transcendentals',
        author: 'James Stewart',
        isbn: '978-1285741550',
        department: 'Mathematics',
        course: 'MATH101 - Calculus I',
        condition: 'Good',
        listingType: 'Both',
        price: 800,
        exchangePreference: 'Looking for Linear Algebra or Physics book',
        images: [],
        description: 'Good condition. Some pencil marks that can be erased.',
        createdAt: now.subtract(const Duration(hours: 5)),
        views: 21,
      ),
      BookListingModel(
        id: uuid.v4(),
        sellerId: 'other-user-3',
        sellerName: 'Fatima Malik',
        sellerRating: 5.0,
        title: 'Operating System Concepts',
        author: 'Silberschatz, Galvin',
        isbn: '978-1118063330',
        department: 'Computer Science',
        course: 'CS401 - Operating Systems',
        condition: 'Like New',
        listingType: 'Exchange',
        exchangePreference: 'Want Computer Networks or Database book',
        images: [],
        description:
            'Barely used. Bought but switched to online resources. Perfect condition.',
        createdAt: now.subtract(const Duration(days: 1)),
        views: 58,
      ),
      BookListingModel(
        id: uuid.v4(),
        sellerId: 'other-user-4',
        sellerName: 'Bilal Ahmed',
        sellerRating: 3.9,
        title: 'Engineering Mechanics: Statics',
        author: 'R.C. Hibbeler',
        isbn: '978-0133918922',
        department: 'Mechanical Engineering',
        course: 'ME201 - Engineering Mechanics',
        condition: 'Acceptable',
        listingType: 'Sell',
        price: 500,
        images: [],
        description:
            'Has some writing and highlights. All chapters complete.',
        createdAt: now.subtract(const Duration(days: 2)),
        views: 15,
      ),
      BookListingModel(
        id: uuid.v4(),
        sellerId: 'other-user-1',
        sellerName: 'Sara Khan',
        sellerRating: 4.8,
        title: 'Database System Concepts',
        author: 'Silberschatz, Korth',
        isbn: '978-0073523323',
        department: 'Computer Science',
        course: 'CS402 - Database Systems',
        condition: 'Good',
        listingType: 'Sell',
        price: 950,
        images: [],
        description: 'Used for one semester. Good condition overall.',
        createdAt: now.subtract(const Duration(days: 3)),
        views: 42,
      ),
      BookListingModel(
        id: uuid.v4(),
        sellerId: currentUserId,
        sellerName: 'Ali Hassan',
        sellerRating: 4.5,
        title: 'Computer Networks',
        author: 'Andrew Tanenbaum',
        isbn: '978-0132126953',
        department: 'Computer Science',
        course: 'CS403 - Computer Networks',
        condition: 'Very Good',
        listingType: 'Both',
        price: 1100,
        exchangePreference: 'Looking for Software Engineering book',
        images: [],
        description: 'My own listing. Used for one semester.',
        createdAt: now.subtract(const Duration(days: 4)),
        views: 27,
      ),
    ]);

    _reviews.addAll([
      ReviewModel(
        id: uuid.v4(),
        reviewerId: 'other-user-2',
        reviewerName: 'Usman Ali',
        reviewedUserId: currentUserId,
        rating: 5.0,
        comment: 'Great seller! Book was exactly as described. Fast meetup.',
        createdAt: now.subtract(const Duration(days: 10)),
        bookTitle: 'Discrete Mathematics',
      ),
      ReviewModel(
        id: uuid.v4(),
        reviewerId: 'other-user-3',
        reviewerName: 'Fatima Malik',
        reviewedUserId: currentUserId,
        rating: 4.0,
        comment: 'Good experience. Book condition was as stated.',
        createdAt: now.subtract(const Duration(days: 20)),
        bookTitle: 'Linear Algebra',
      ),
    ]);

    notifyListeners();
  }
}
