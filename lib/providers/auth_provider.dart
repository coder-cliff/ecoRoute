import 'dart:math';
import 'package:flutter/foundation.dart';
import '../models/user_model.dart';
import '../services/storage_service.dart';

class AuthProvider with ChangeNotifier {
  List<AppUser> _allUsers = [];
  AppUser _currentUser = const AppUser(
    id: 'temp_init',
    name: 'Sarah Namukasa',
    phone: '+256 772 123456',
    email: 'sarah.namukasa@ecoroute.app',
    role: UserRole.citizen,
    avatarUrl: 'https://images.unsplash.com/photo-1534528741775-53994a69daeb?w=200&auto=format&fit=crop&q=80',
    address: 'Plot 12, Acacia Avenue, Kololo, Kampala',
  );
  bool _isLoading = false;

  AppUser get currentUser => _currentUser;
  List<AppUser> get allUsers => _allUsers;
  bool get isLoading => _isLoading;
  UserRole get currentRole => _currentUser.role;

  bool get isCitizen => _currentUser.role == UserRole.citizen;
  bool get isRider => _currentUser.role == UserRole.rider;
  bool get isAdmin => _currentUser.role == UserRole.admin;

  List<AppUser> get riders => _allUsers.where((u) => u.role == UserRole.rider).toList();
  List<AppUser> get citizens => _allUsers.where((u) => u.role == UserRole.citizen).toList();
  List<AppUser> get admins => _allUsers.where((u) => u.role == UserRole.admin).toList();

  Future<void> init() async {
    _isLoading = true;
    notifyListeners();

    _allUsers = await StorageService.loadUsers();

    final savedUserId = await StorageService.getActiveUserId();
    if (savedUserId != null) {
      final found = _allUsers.where((u) => u.id == savedUserId).toList();
      if (found.isNotEmpty) {
        _currentUser = found.first;
      } else if (_allUsers.isNotEmpty) {
        _currentUser = _allUsers.first;
      }
    } else if (_allUsers.isNotEmpty) {
      _currentUser = _allUsers.first;
    }

    _isLoading = false;
    notifyListeners();
  }

  /// Switch to a specific existing user by ID
  Future<void> switchUser(String userId) async {
    final found = _allUsers.where((u) => u.id == userId).toList();
    if (found.isNotEmpty) {
      _currentUser = found.first;
      await StorageService.saveActiveUserId(_currentUser.id);
      notifyListeners();
    }
  }

  /// Switch to a persona by role (picks the first registered user with that role)
  Future<void> switchRole(UserRole role) async {
    final matching = _allUsers.where((u) => u.role == role).toList();
    if (matching.isNotEmpty) {
      _currentUser = matching.first;
      await StorageService.saveActiveUserId(_currentUser.id);
      notifyListeners();
    }
  }

  /// Update the current user's profile details & DP
  Future<void> updateProfile({
    required String name,
    required String phone,
    required String email,
    required String address,
    required String avatarUrl,
    String? vehicleInfo,
  }) async {
    final updated = _currentUser.copyWith(
      name: name,
      phone: phone,
      email: email,
      address: address,
      avatarUrl: avatarUrl,
      vehicleInfo: vehicleInfo,
    );

    final index = _allUsers.indexWhere((u) => u.id == updated.id);
    if (index != -1) {
      _allUsers[index] = updated;
    } else {
      _allUsers.add(updated);
    }

    _currentUser = updated;
    await StorageService.saveUsers(_allUsers);
    await StorageService.saveActiveUserId(updated.id);
    notifyListeners();
  }

  /// Register a new real account with custom DP and details
  Future<AppUser> registerUser({
    required String name,
    required String phone,
    required String email,
    required UserRole role,
    required String avatarUrl,
    required String address,
    String? vehicleInfo,
  }) async {
    final randomId = 1000 + Random().nextInt(9000);
    final prefix = role == UserRole.citizen ? 'cit' : (role == UserRole.rider ? 'rid' : 'adm');
    final newId = 'usr_${prefix}_$randomId';

    final newUser = AppUser(
      id: newId,
      name: name,
      phone: phone,
      email: email,
      role: role,
      avatarUrl: avatarUrl,
      address: address,
      vehicleInfo: vehicleInfo,
    );

    _allUsers.add(newUser);
    _currentUser = newUser;
    await StorageService.saveUsers(_allUsers);
    await StorageService.saveActiveUserId(newUser.id);
    notifyListeners();
    return newUser;
  }
}
