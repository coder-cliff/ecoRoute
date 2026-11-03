import 'dart:math';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart' as fb_auth;
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/foundation.dart';
import '../models/user_model.dart';
import '../services/storage_service.dart';

class AuthProvider with ChangeNotifier {
  List<AppUser> _allUsers = [];
  AppUser? _currentUser;
  bool _isLoading = false;

  AppUser get currentUser =>
      _currentUser ??
      const AppUser(
        id: 'unauthenticated',
        name: 'Guest User',
        phone: '',
        email: '',
        role: UserRole.citizen,
      );

  bool get isAuthenticated => _currentUser != null;
  List<AppUser> get allUsers => _allUsers;
  bool get isLoading => _isLoading;
  UserRole get currentRole => currentUser.role;

  bool get isCitizen => currentUser.role == UserRole.citizen;
  bool get isRider => currentUser.role == UserRole.rider;
  bool get isAdmin => currentUser.role == UserRole.admin;

  List<AppUser> get riders => _allUsers.where((u) => u.role == UserRole.rider).toList();
  List<AppUser> get citizens => _allUsers.where((u) => u.role == UserRole.citizen).toList();
  List<AppUser> get admins => _allUsers.where((u) => u.role == UserRole.admin).toList();

  Future<void> init() async {
    _isLoading = true;
    notifyListeners();

    // 1. Load registered accounts dynamically from Firebase Cloud Firestore
    _allUsers = await StorageService.loadUsers();

    // 2. Check if a Firebase Auth user session exists
    if (Firebase.apps.isNotEmpty) {
      final fbUser = fb_auth.FirebaseAuth.instance.currentUser;
      if (fbUser != null && fbUser.email != null) {
        final match = _allUsers.where(
          (u) => u.email.toLowerCase() == fbUser.email!.toLowerCase() || u.id == fbUser.uid,
        ).toList();
        if (match.isNotEmpty) {
          _currentUser = match.first;
          _isLoading = false;
          notifyListeners();
          return;
        }

        // Try direct Firestore lookup
        try {
          var doc = await FirebaseFirestore.instance.collection('users').doc(fbUser.uid).get();
          if (!doc.exists) {
            doc = await FirebaseFirestore.instance.collection('profiles').doc(fbUser.uid).get();
          }
          if (doc.exists && doc.data() != null) {
            final user = AppUser.fromJson({...doc.data()!, 'id': fbUser.uid});
            _currentUser = user;
            _allUsers.add(user);
            await StorageService.saveUser(user);
            _isLoading = false;
            notifyListeners();
            return;
          }
        } catch (e) {
          debugPrint('Firestore init error: $e');
        }
      }
    }

    // 3. Check saved active user ID from previous session
    final savedUserId = await StorageService.getActiveUserId();
    if (savedUserId != null && savedUserId.isNotEmpty) {
      final found = _allUsers.where((u) => u.id == savedUserId).toList();
      if (found.isNotEmpty) {
        _currentUser = found.first;
      } else {
        _currentUser = null;
      }
    } else {
      _currentUser = null;
    }

    _isLoading = false;
    notifyListeners();
  }

  /// Sign in with Email and Password using Firebase Authentication
  Future<AppUser> signInWithFirebase({
    required String email,
    required String password,
  }) async {
    _isLoading = true;
    notifyListeners();

    final cleanEmail = email.trim().toLowerCase();

    if (Firebase.apps.isNotEmpty) {
      final cred = await fb_auth.FirebaseAuth.instance.signInWithEmailAndPassword(
        email: cleanEmail,
        password: password,
      );
      final fbUser = cred.user;

      if (fbUser != null) {
        try {
          var doc = await FirebaseFirestore.instance.collection('users').doc(fbUser.uid).get();
          if (!doc.exists) {
            doc = await FirebaseFirestore.instance.collection('profiles').doc(fbUser.uid).get();
          }

          if (doc.exists && doc.data() != null) {
            final user = AppUser.fromJson({...doc.data()!, 'id': fbUser.uid});
            _currentUser = user;
            await StorageService.saveUser(user);
            await StorageService.saveActiveUserId(user.id);
            _allUsers = await StorageService.loadUsers();
            _isLoading = false;
            notifyListeners();
            return user;
          }
        } catch (e) {
          debugPrint('Firestore fetch error: $e');
        }

        // Fallback user from Auth credential
        final fallbackUser = AppUser(
          id: fbUser.uid,
          name: fbUser.displayName ?? cleanEmail.split('@').first,
          phone: fbUser.phoneNumber ?? '',
          email: cleanEmail,
          role: UserRole.citizen,
        );
        _currentUser = fallbackUser;
        await StorageService.saveUser(fallbackUser);
        await StorageService.saveActiveUserId(fallbackUser.id);
        _allUsers = await StorageService.loadUsers();
        _isLoading = false;
        notifyListeners();
        return fallbackUser;
      }
    }

    // Match against local registered accounts if Firebase is offline
    final match = _allUsers.where((u) => u.email.toLowerCase() == cleanEmail).toList();
    if (match.isNotEmpty) {
      _currentUser = match.first;
      await StorageService.saveActiveUserId(_currentUser!.id);
      _isLoading = false;
      notifyListeners();
      return _currentUser!;
    }

    _isLoading = false;
    notifyListeners();
    throw Exception('No account found for $email. Please register a new account.');
  }

  /// Switch to a specific existing user by ID (for multi-account management)
  Future<void> switchUser(String userId) async {
    final found = _allUsers.where((u) => u.id == userId).toList();
    if (found.isNotEmpty) {
      _currentUser = found.first;
      await StorageService.saveActiveUserId(_currentUser!.id);
      notifyListeners();
    }
  }

  /// Switch to a persona by role (picks the first registered user with that role)
  Future<void> switchRole(UserRole role) async {
    final matching = _allUsers.where((u) => u.role == role).toList();
    if (matching.isNotEmpty) {
      _currentUser = matching.first;
      await StorageService.saveActiveUserId(_currentUser!.id);
      notifyListeners();
    }
  }

  /// Update the current user's profile details & DP in Firebase Firestore and local storage
  Future<void> updateProfile({
    required String name,
    required String phone,
    required String email,
    required String address,
    required String avatarUrl,
    String? vehicleInfo,
  }) async {
    if (_currentUser == null) return;

    final updated = _currentUser!.copyWith(
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
    await StorageService.saveUser(updated);
    await StorageService.saveActiveUserId(updated.id);
    notifyListeners();
  }

  /// Register a new real account with Firebase Authentication and Firestore
  Future<AppUser> registerUser({
    required String name,
    required String phone,
    required String email,
    required UserRole role,
    required String avatarUrl,
    required String address,
    String? vehicleInfo,
    String? password,
  }) async {
    final cleanEmail = email.trim().toLowerCase();
    String newId = 'usr_${role == UserRole.citizen ? 'cit' : (role == UserRole.rider ? 'rid' : 'adm')}_${1000 + Random().nextInt(9000)}';

    // 1. Create user in Firebase Authentication
    if (Firebase.apps.isNotEmpty) {
      try {
        final cred = await fb_auth.FirebaseAuth.instance.createUserWithEmailAndPassword(
          email: cleanEmail,
          password: password ?? 'password123',
        );
        if (cred.user?.uid != null) {
          newId = cred.user!.uid;
        }
      } catch (e) {
        debugPrint('Firebase Auth register notice: $e');
      }
    }

    final newUser = AppUser(
      id: newId,
      name: name,
      phone: phone,
      email: cleanEmail,
      role: role,
      avatarUrl: avatarUrl,
      address: address,
      vehicleInfo: vehicleInfo,
    );

    // 2. Persist to Firebase Firestore and local storage
    await StorageService.saveUser(newUser);

    final idx = _allUsers.indexWhere((u) => u.id == newUser.id);
    if (idx != -1) {
      _allUsers[idx] = newUser;
    } else {
      _allUsers.add(newUser);
    }

    _currentUser = newUser;
    await StorageService.saveActiveUserId(newUser.id);
    notifyListeners();
    return newUser;
  }

  /// Sign out completely from Firebase Authentication and active session
  Future<void> signOut() async {
    if (Firebase.apps.isNotEmpty) {
      try {
        await fb_auth.FirebaseAuth.instance.signOut();
      } catch (e) {
        debugPrint('Firebase Auth sign out notice: $e');
      }
    }
    await StorageService.saveActiveUserId('');
    _currentUser = null;
    notifyListeners();
  }
}
