import 'dart:convert';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart' as firebase_auth;
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../domain/entities/app_user.dart';
import '../../domain/enums/role.dart';

class AuthService {
  AuthService(this._preferences, {this._firebaseAuth, this._firestore});

  static const String _sessionKey = 'ecoroute_current_user_v1';
  static const String _usersKey = 'ecoroute_registered_users_v1';

  final SharedPreferences _preferences;
  final firebase_auth.FirebaseAuth? _firebaseAuth;
  final FirebaseFirestore? _firestore;

  static const List<Map<String, dynamic>> _demoAccounts = [
    {
      'id': 'res-demo-1',
      'fullName': 'Amina Dranzoa (Resident)',
      'email': 'resident@ecoroute.demo',
      'phone': '+256 772 123 456',
      'role': 'resident',
      'password': 'demo123',
      'address': 'Arua Central Market',
    },
    {
      'id': 'rider-demo-1',
      'fullName': 'Juma Okello (Route Rider)',
      'email': 'rider@ecoroute.demo',
      'phone': '+256 701 987 654',
      'role': 'rider',
      'password': 'demo123',
      'address': 'River Oli Depot',
    },
    {
      'id': 'admin-demo-1',
      'fullName': 'Grace Candiru (Municipal Admin)',
      'email': 'admin@ecoroute.demo',
      'phone': '+256 782 555 111',
      'role': 'admin',
      'password': 'demo123',
      'address': 'Arua City Hall',
    },
  ];

  AppUser? getCurrentUser() {
    final raw = _preferences.getString(_sessionKey);
    if (raw == null) return null;
    try {
      final map = jsonDecode(raw) as Map<String, dynamic>;
      return AppUser(
        id: map['id'] as String,
        fullName: map['fullName'] as String,
        email: map['email'] as String,
        phone: map['phone'] as String,
        role: AppRole.values.byName(map['role'] as String),
        address: map['address'] as String?,
      );
    } catch (_) {
      return null;
    }
  }

  Future<void> _saveSession(AppUser user) async {
    final data = {
      'id': user.id,
      'fullName': user.fullName,
      'email': user.email,
      'phone': user.phone,
      'role': user.role.name,
      'address': user.address,
    };
    await _preferences.setString(_sessionKey, jsonEncode(data));
  }

  Future<void> logout() async {
    try {
      await _firebaseAuth?.signOut();
    } catch (_) {}
    await _preferences.remove(_sessionKey);
  }

  /// Checks if an email is already registered in the system (demo or registered accounts)
  bool isEmailRegistered(String email) {
    final cleanEmail = email.trim().toLowerCase();
    for (final demo in _demoAccounts) {
      if ((demo['email'] as String).toLowerCase() == cleanEmail) return true;
    }
    final registered = _getRegisteredUsers();
    for (final reg in registered) {
      if ((reg['email'] as String).toLowerCase() == cleanEmail) return true;
    }
    return false;
  }

  Future<AppUser?> login({
    required String email,
    required String password,
  }) async {
    final cleanEmail = email.trim().toLowerCase();

    // 1. Check demo accounts
    for (final demo in _demoAccounts) {
      if ((demo['email'] as String).toLowerCase() == cleanEmail &&
          demo['password'] == password) {
        try {
          await _firebaseAuth?.signOut();
        } catch (_) {}
        final user = AppUser(
          id: demo['id'] as String,
          fullName: demo['fullName'] as String,
          email: demo['email'] as String,
          phone: demo['phone'] as String,
          role: AppRole.values.byName(demo['role'] as String),
          address: demo['address'] as String?,
        );
        await _saveSession(user);
        return user;
      }
    }

    // 2. Attempt Firebase Authentication if configured
    final firebaseAuth = _firebaseAuth;
    final firestore = _firestore;
    if (firebaseAuth != null && firestore != null) {
      try {
        final credential = await firebaseAuth.signInWithEmailAndPassword(
          email: cleanEmail,
          password: password,
        );
        final firebaseUser = credential.user;
        if (firebaseUser != null && firebaseUser.email != null) {
          final profileRef = firestore.collection('profiles').doc(firebaseUser.uid);
          final profileSnapshot = await profileRef.get();
          final profile = profileSnapshot.data();
          if (profile == null) {
            await profileRef.set({
              'id': firebaseUser.uid,
              'fullName': firebaseUser.displayName ?? cleanEmail.split('@').first,
              'email': cleanEmail,
              'phone': firebaseUser.phoneNumber ?? '+256394880352',
              'role': 'resident',
              'address': 'Arua Municipality',
              'createdAt': FieldValue.serverTimestamp(),
              'updatedAt': FieldValue.serverTimestamp(),
            });
          }

          final user = AppUser(
            id: firebaseUser.uid,
            fullName: (profile?['fullName'] as String?) ??
                firebaseUser.displayName ??
                cleanEmail.split('@').first,
            email: cleanEmail,
            phone: (profile?['phone'] as String?) ?? firebaseUser.phoneNumber ?? '+256394880352',
            role: AppRole.values.byName(
              (profile?['role'] as String?) ?? 'resident',
            ),
            address: profile?['address'] as String?,
          );
          await _saveSession(user);
          return user;
        }
      } on firebase_auth.FirebaseAuthException catch (e) {
        debugPrint('Firebase signIn notice: ${e.code} - ${e.message}');
        if (e.code == 'wrong-password' || e.code == 'invalid-credential') {
          return null;
        }
      } catch (e) {
        debugPrint('Firebase login exception: $e');
      }
    }

    // 3. Fallback to locally registered accounts
    final registered = _getRegisteredUsers();
    for (final reg in registered) {
      if ((reg['email'] as String).toLowerCase() == cleanEmail &&
          reg['password'] == password) {
        final user = AppUser(
          id: reg['id'] as String,
          fullName: reg['fullName'] as String,
          email: reg['email'] as String,
          phone: reg['phone'] as String,
          role: AppRole.values.byName(reg['role'] as String),
          address: reg['address'] as String?,
        );
        await _saveSession(user);
        return user;
      }
    }

    return null;
  }

  Future<AppUser> register({
    required String fullName,
    required String email,
    required String phone,
    required String password,
    AppRole role = AppRole.resident,
    String? address,
  }) async {
    final cleanEmail = email.trim().toLowerCase();
    final normalizedPhone = phone.trim().isEmpty ? '+256394880352' : phone.trim();
    final normalizedAddress = address?.trim().isNotEmpty == true
        ? address!.trim()
        : 'Arua Municipality';

    // 1. Attempt Firebase Authentication if configured
    final firebaseAuth = _firebaseAuth;
    final firestore = _firestore;
    if (firebaseAuth != null && firestore != null) {
      try {
        final credential = await firebaseAuth.createUserWithEmailAndPassword(
          email: cleanEmail,
          password: password,
        );
        final firebaseUser = credential.user;
        if (firebaseUser == null) {
          throw StateError('Firebase did not return the created user.');
        }

        try {
          await firebaseUser.updateDisplayName(fullName.trim());
        } catch (_) {}

        final user = AppUser(
          id: firebaseUser.uid,
          fullName: fullName.trim(),
          email: cleanEmail,
          phone: normalizedPhone,
          role: role,
          address: normalizedAddress,
        );

        // Store user profile in Firestore
        await firestore.collection('profiles').doc(firebaseUser.uid).set({
          'id': firebaseUser.uid,
          'fullName': user.fullName,
          'email': user.email,
          'phone': user.phone,
          'role': user.role.name,
          'address': user.address,
          'createdAt': FieldValue.serverTimestamp(),
          'updatedAt': FieldValue.serverTimestamp(),
        });

        // Save locally for offline sync
        _saveToLocalRegisteredUsers(user, password);
        await _saveSession(user);
        return user;
      } on firebase_auth.FirebaseAuthException catch (e) {
        if (e.code == 'email-already-in-use') {
          throw StateError('This email is already registered with Firebase. Please sign in.');
        } else if (e.code == 'weak-password') {
          throw StateError('The password is too weak. Please use at least 6 characters.');
        } else if (e.code == 'invalid-email') {
          throw StateError('The email address format is invalid.');
        } else if (e.code == 'network-request-failed' || e.code == 'unavailable') {
          debugPrint('Firebase network unavailable. Falling back to local offline registration.');
        } else {
          throw StateError(e.message ?? 'Firebase registration failed (${e.code}).');
        }
      } catch (e) {
        if (e is StateError) rethrow;
        debugPrint('Firebase registration notice: $e. Falling back to local registration.');
      }
    }

    // 2. Local Registration (offline / test mode fallback)
    final userId = 'user-${DateTime.now().millisecondsSinceEpoch}';
    final user = AppUser(
      id: userId,
      fullName: fullName.trim(),
      email: cleanEmail,
      phone: normalizedPhone,
      role: role,
      address: normalizedAddress,
    );

    _saveToLocalRegisteredUsers(user, password);
    await _saveSession(user);
    return user;
  }

  void _saveToLocalRegisteredUsers(AppUser user, String password) {
    final users = _getRegisteredUsers();
    final newUserMap = {
      'id': user.id,
      'fullName': user.fullName,
      'email': user.email,
      'phone': user.phone,
      'role': user.role.name,
      'password': password,
      'address': user.address,
    };

    users.removeWhere((u) => (u['email'] as String).toLowerCase() == user.email.toLowerCase());
    users.add(newUserMap);
    _preferences.setString(_usersKey, jsonEncode(users));
  }

  List<Map<String, dynamic>> _getRegisteredUsers() {
    final raw = _preferences.getString(_usersKey);
    if (raw == null) return [];
    try {
      final list = jsonDecode(raw) as List<dynamic>;
      return list.cast<Map<String, dynamic>>();
    } catch (_) {
      return [];
    }
  }
}
