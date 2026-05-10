import 'package:flutter/material.dart';
import 'package:uuid/uuid.dart';
import '../models/user_model.dart';
import '../services/database_service.dart';

class AuthProvider extends ChangeNotifier {
  UserModel? _currentUser;
  bool _isLoading = false;
  String? _error;

  final _db = DatabaseService();

  // Callbacks so AuthProvider can tell other providers to reset
  // without creating circular dependencies.
  VoidCallback? onLogout;

  UserModel? get currentUser => _currentUser;
  bool get isLoggedIn => _currentUser != null;
  bool get isLoading => _isLoading;
  String? get error => _error;

  Future<bool> register({
    required String name,
    required String email,
    required String password,
    required String university,
    required String department,
    String? phone,
  }) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    await Future.delayed(const Duration(milliseconds: 300));

    final user = UserModel(
      id: const Uuid().v4(),
      name: name,
      email: email,
      university: university,
      department: department,
      phone: phone,
      // New users start with zero stats — no defaults
      rating: 0.0,
      totalRatings: 0,
      totalListings: 0,
      totalTransactions: 0,
      createdAt: DateTime.now(),
    );

    final success = await _db.registerUser(user, password);
    if (!success) {
      _error = 'An account with this email already exists.';
      _isLoading = false;
      notifyListeners();
      return false;
    }

    _currentUser = user;
    _isLoading = false;
    notifyListeners();
    return true;
  }

  Future<bool> login({
    required String email,
    required String password,
  }) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    await Future.delayed(const Duration(milliseconds: 300));

    final user = await _db.loginUser(email, password);

    if (user == null) {
      _error = 'Invalid email or password.';
      _isLoading = false;
      notifyListeners();
      return false;
    }

    _currentUser = user;
    _isLoading = false;
    notifyListeners();
    return true;
  }

  Future<void> updateProfile({
    String? name,
    String? phone,
    String? department,
    String? profileImage,
  }) async {
    if (_currentUser == null) return;
    _currentUser = _currentUser!.copyWith(
      name: name,
      phone: phone,
      department: department,
      profileImage: profileImage,
    );
    await _db.updateUser(_currentUser!);
    notifyListeners();
  }

  void logout() {
    _currentUser = null;
    // Notify other providers to clear user-specific data
    onLogout?.call();
    notifyListeners();
  }

  void clearError() {
    _error = null;
    notifyListeners();
  }
}
