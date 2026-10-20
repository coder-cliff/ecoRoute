import 'package:flutter/foundation.dart';
import '../models/user_model.dart';
import '../services/storage_service.dart';

class AuthProvider with ChangeNotifier {
  AppUser _currentUser = AppUser.demoCitizen;
  bool _isLoading = false;

  AppUser get currentUser => _currentUser;
  bool get isLoading => _isLoading;
  UserRole get currentRole => _currentUser.role;

  bool get isCitizen => _currentUser.role == UserRole.citizen;
  bool get isRider => _currentUser.role == UserRole.rider;
  bool get isAdmin => _currentUser.role == UserRole.admin;

  Future<void> init() async {
    _isLoading = true;
    notifyListeners();

    final savedUserId = await StorageService.getActiveUserId();
    if (savedUserId != null) {
      if (savedUserId == AppUser.demoRider.id) {
        _currentUser = AppUser.demoRider;
      } else if (savedUserId == AppUser.demoAdmin.id) {
        _currentUser = AppUser.demoAdmin;
      } else {
        _currentUser = AppUser.demoCitizen;
      }
    }

    _isLoading = false;
    notifyListeners();
  }

  Future<void> switchRole(UserRole role) async {
    switch (role) {
      case UserRole.citizen:
        _currentUser = AppUser.demoCitizen;
        break;
      case UserRole.rider:
        _currentUser = AppUser.demoRider;
        break;
      case UserRole.admin:
        _currentUser = AppUser.demoAdmin;
        break;
    }
    await StorageService.saveActiveUserId(_currentUser.id);
    notifyListeners();
  }

  Future<void> loginAsUser(AppUser user) async {
    _currentUser = user;
    await StorageService.saveActiveUserId(user.id);
    notifyListeners();
  }
}
