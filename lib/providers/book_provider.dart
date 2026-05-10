import 'package:flutter/material.dart';
import 'package:uuid/uuid.dart';
import '../models/book_listing_model.dart';
import '../models/review_model.dart';
import '../models/user_model.dart';
import '../services/asset_service.dart';
import '../services/database_service.dart';

class BookProvider extends ChangeNotifier {
  final _db = DatabaseService();

  List<BookListingModel> _listings = [];
  List<ReviewModel> _reviews = [];
  List<TransactionModel> _transactions = [];

  bool _isLoading = false;
  bool _isInitialized = false;
  String? _loadedForUserId; // track which user's personal data is loaded

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
          .where(
              (b) => b.listingType == _selectedType || b.listingType == 'Both')
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

  // ─── FILTERS ─────────────────────────────────────────────────────

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

  // ─── RESET on logout ─────────────────────────────────────────────
  // Called by AuthProvider when user logs out so the next user
  // gets a clean slate of personal data (reviews, transactions).
  void reset() {
    _reviews = [];
    _transactions = [];
    _isInitialized = false;
    _loadedForUserId = null;
    clearFilters();
    // Keep _listings — they are shared/public across all users
    notifyListeners();
  }

  // ─── LOAD DATA ───────────────────────────────────────────────────

  Future<void> loadData(String currentUserId) async {
    // Re-load personal data if a different user logs in
    if (_isInitialized && _loadedForUserId == currentUserId) return;

    _isLoading = true;
    notifyListeners();

    // Seed shared demo listings ONCE (not tied to any real user)
    final alreadySeeded = await _db.isDemoSeeded();
    if (!alreadySeeded) {
      await _seedSharedDemoListings();
    }

    // Load ALL public listings (from every seller)
    _listings = await _db.getAllListings();

    // Load ONLY this user's personal data
    _reviews = await _db.getReviewsForUser(currentUserId);
    _transactions = await _db.getTransactionsForUser(currentUserId);

    _isInitialized = true;
    _loadedForUserId = currentUserId;
    _isLoading = false;
    notifyListeners();
  }

  Future<void> refreshListings() async {
    _listings = await _db.getAllListings();
    notifyListeners();
  }

  // ─── LISTING CRUD ────────────────────────────────────────────────

  Future<void> addListing(BookListingModel listing) async {
    _isLoading = true;
    notifyListeners();
    await _db.insertListing(listing);
    _listings.insert(0, listing);
    _isLoading = false;
    notifyListeners();
  }

  Future<void> deleteListing(String listingId) async {
    await _db.deleteListing(listingId);
    _listings.removeWhere((b) => b.id == listingId);
    notifyListeners();
  }

  Future<void> markAsSold(String listingId) async {
    await _db.updateListingAvailability(listingId, false);
    final idx = _listings.indexWhere((b) => b.id == listingId);
    if (idx != -1) {
      _listings[idx] = _listings[idx].copyWith(isAvailable: false);
      notifyListeners();
    }
  }

  Future<void> incrementViews(String listingId) async {
    await _db.incrementListingViews(listingId);
    final idx = _listings.indexWhere((b) => b.id == listingId);
    if (idx != -1) {
      _listings[idx] = _listings[idx].copyWith(views: _listings[idx].views + 1);
      notifyListeners();
    }
  }

  // ─── REVIEWS & TRANSACTIONS ──────────────────────────────────────

  Future<void> addReview(ReviewModel review) async {
    await _db.insertReview(review);
    _reviews.add(review);
    notifyListeners();
  }

  Future<void> addTransaction(TransactionModel transaction) async {
    await _db.insertTransaction(transaction);
    _transactions.add(transaction);
    notifyListeners();
  }

  // ─── SHARED DEMO LISTINGS (no real user attached) ────────────────
  // These are listings from fictional sellers so the home feed
  // is not empty on first launch. They are NEVER tied to any
  // registered user's profile — sellerId uses placeholder IDs
  // that don't match any real account.

  Future<void> _seedSharedDemoListings() async {
    const uuid = Uuid();
    final now = DateTime.now();
    final assets = AssetService();

    // Sentinel user — fictional, never shown in any real profile
    final sentinel = UserModel(
      id: '_demo_sentinel_',
      name: 'Demo Sentinel',
      email: 'demo@uni.edu.pk',
      university: 'FAST NUCES',
      department: 'Computer Science',
      createdAt: now,
    );
    await _db.registerUser(sentinel, '__sentinel__');

    final demoListings = [
      BookListingModel(
        id: uuid.v4(),
        sellerId: '_demo_seller_1_',
        sellerName: 'Sara Khan',
        sellerRating: 4.8,
        title: 'Introduction to Algorithms',
        author: 'Cormen, Leiserson, Rivest & Stein',
        isbn: '978-0-262-03384-8',
        department: 'Computer Science',
        course: 'CS301 - Data Structures & Algorithms',
        condition: 'Very Good',
        listingType: 'Sell',
        price: 1200,
        images: [assets.path('intro_algorithms')],
        description:
            'Used for one semester only. Minor pencil highlights on a few pages — '
            'all content fully intact. Covers divide-and-conquer, dynamic programming, '
            'greedy algorithms, graph algorithms and more. Perfect for CS301 and '
            'competitive programming prep.',
        createdAt: now.subtract(const Duration(hours: 2)),
        views: 34,
      ),
      BookListingModel(
        id: uuid.v4(),
        sellerId: '_demo_seller_2_',
        sellerName: 'Usman Ali',
        sellerRating: 4.2,
        title: 'Calculus: Early Transcendentals',
        author: 'James Stewart',
        isbn: '978-1-285-74155-0',
        department: 'Mathematics',
        course: 'MATH101 - Calculus I',
        condition: 'Good',
        listingType: 'Both',
        price: 800,
        exchangePreference: 'Looking for Linear Algebra or Physics book',
        images: [assets.path('calculus_stewart')],
        description:
            'Good condition overall. Some pencil marks in chapters 3–5 that can be erased. '
            'Covers limits, derivatives, integrals, and series. '
            'Includes all practice problems and solutions appendix.',
        createdAt: now.subtract(const Duration(hours: 5)),
        views: 21,
      ),
      BookListingModel(
        id: uuid.v4(),
        sellerId: '_demo_seller_3_',
        sellerName: 'Fatima Malik',
        sellerRating: 5.0,
        title: 'Operating System Concepts',
        author: 'Silberschatz, Galvin & Gagne',
        isbn: '978-1-118-06333-0',
        department: 'Computer Science',
        course: 'CS401 - Operating Systems',
        condition: 'Like New',
        listingType: 'Exchange',
        exchangePreference: 'Want Computer Networks or Database Systems book',
        images: [assets.path('os_concepts')],
        description:
            'Barely used — bought but switched to online resources after week 2. '
            'Absolutely perfect condition, no marks or highlights anywhere. '
            'Covers processes, threads, CPU scheduling, memory management, '
            'file systems and security.',
        createdAt: now.subtract(const Duration(days: 1)),
        views: 58,
      ),
      BookListingModel(
        id: uuid.v4(),
        sellerId: '_demo_seller_4_',
        sellerName: 'Bilal Ahmed',
        sellerRating: 3.9,
        title: 'Engineering Mechanics: Statics',
        author: 'R.C. Hibbeler',
        isbn: '978-0-13-391892-2',
        department: 'Mechanical Engineering',
        course: 'ME201 - Engineering Mechanics',
        condition: 'Acceptable',
        listingType: 'Sell',
        price: 500,
        images: [assets.path('engineering_mechanics')],
        description:
            'Has some pen writing and yellow highlights in chapters 4–7. '
            'All chapters complete, no torn or missing pages. '
            'Good for reference and solving practice problems. '
            'Covers force vectors, equilibrium, structural analysis and friction.',
        createdAt: now.subtract(const Duration(days: 2)),
        views: 15,
      ),
      BookListingModel(
        id: uuid.v4(),
        sellerId: '_demo_seller_1_',
        sellerName: 'Sara Khan',
        sellerRating: 4.8,
        title: 'Database System Concepts',
        author: 'Silberschatz, Korth & Sudarshan',
        isbn: '978-0-07-352332-3',
        department: 'Computer Science',
        course: 'CS402 - Database Systems',
        condition: 'Good',
        listingType: 'Sell',
        price: 950,
        images: [assets.path('database_systems')],
        description:
            'Used for one semester. Good condition with light highlighting in the '
            'ER diagram chapter. Covers relational model, SQL, normalization, '
            'transactions, concurrency control and NoSQL. '
            'Includes all end-of-chapter exercises.',
        createdAt: now.subtract(const Duration(days: 3)),
        views: 42,
      ),
      BookListingModel(
        id: uuid.v4(),
        sellerId: '_demo_seller_2_',
        sellerName: 'Usman Ali',
        sellerRating: 4.2,
        title: 'Linear Algebra and Its Applications',
        author: 'Gilbert Strang',
        isbn: '978-0-03-010567-8',
        department: 'Mathematics',
        course: 'MATH201 - Linear Algebra',
        condition: 'Very Good',
        listingType: 'Sell',
        price: 700,
        images: [assets.path('linear_algebra')],
        description:
            'Clean copy used for one semester only. Minor dog-ear on page 1, '
            'otherwise perfect. Covers vectors, matrices, determinants, eigenvalues, '
            'linear transformations and applications. '
            'Great for CS and Engineering students.',
        createdAt: now.subtract(const Duration(days: 5)),
        views: 19,
      ),
    ];

    for (final listing in demoListings) {
      await _db.insertListing(listing);
    }
  }
}
