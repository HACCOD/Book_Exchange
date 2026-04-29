import 'package:flutter/material.dart';
import 'package:uuid/uuid.dart';
import '../models/user_model.dart';

class AuthProvider extends ChangeNotifier {
  UserModel? _currentUser;
  bool _isLoading = false;
  String? _error;

  UserModel? get currentUser => _currentUser;
  bool get isLoggedIn => _currentUser != null;
  bool get isLoading => _isLoading;
  String? get error => _error;

  final List<UserModel> _registeredUsers = [];

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

    await Future.delayed(const Duration(seconds: 1));

    final exists = _registeredUsers.any((u) => u.email == email);
    if (exists) {
      _error = 'An account with this email already exists.';
      _isLoading = false;
      notifyListeners();
      return false;
    }

    final user = UserModel(
      id: const Uuid().v4(),
      name: name,
      email: email,
      university: university,
      department: department,
      phone: phone,
      createdAt: DateTime.now(),
    );

    _registeredUsers.add(user);
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

    await Future.delayed(const Duration(seconds: 1));

    UserModel? found;
    try {
      found = _registeredUsers.firstWhere((u) => u.email == email);
    } catch (_) {
      found = null;
    }

    // Demo account fallback
    if (found == null && email == 'demo@uni.edu.pk' && password == '123456') {
      found = UserModel(
        id: 'demo-user-001',
        name: 'Ali Hassan',
        email: 'demo@uni.edu.pk',
        university: 'FAST NUCES',
        department: 'Computer Science',
        phone: '03001234567',
        rating: 4.5,
        totalRatings: 12,
        totalListings: 8,
        totalTransactions: 5,
        createdAt: DateTime.now().subtract(const Duration(days: 90)),
      );
    }

    if (found == null) {
      _error = 'Invalid email or password.';
      _isLoading = false;
      notifyListeners();
      return false;
    }

    _currentUser = found;
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
    notifyListeners();
  }

  void logout() {
    _currentUser = null;
    notifyListeners();
  }

  void clearError() {
    _error = null;
    notifyListeners();
  }
}
