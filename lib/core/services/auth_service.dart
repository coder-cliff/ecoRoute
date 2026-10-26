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
  static const String _invitedRidersKey = 'ecoroute_invited_riders_v1';

  final SharedPreferences _preferences;
  final firebase_auth.FirebaseAuth? _firebaseAuth;
  final FirebaseFirestore? _firestore;

  /// Dedicated pre-configured municipal admin accounts
  static const List<Map<String, dynamic>> _adminAccounts = [
    {
      'id': 'admin-deo',
      'fullName': 'Savior Deo (Admin)',
      'email': 'saviordeogratius@gmail.com',
      'phone': '+256 782 555 111',
      'role': 'admin',
      'password': '#ecorute26',
      'address': 'Arua City Hall',
    },
    {
      'id': 'admin-cliff',
      'fullName': 'Tech Cliff (Admin)',
      'email': 'techcliff451@gmail.com',
      'phone': '+256 701 987 654',
      'role': 'admin',
      'password': '#ecorute26',
      'address': 'Arua Municipal Offices',
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

  /// Checks if an email is already registered in the system (admin, invited rider, or resident)
  bool isEmailRegistered(String email) {
    final cleanEmail = email.trim().toLowerCase();
    for (final admin in _adminAccounts) {
      if ((admin['email'] as String).toLowerCase() == cleanEmail) return true;
    }
    final riders = getInvitedRiders();
    for (final rider in riders) {
      if ((rider['email'] as String).toLowerCase() == cleanEmail) return true;
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

    // 1. Check Admin accounts (saviordeogratius@gmail.com, techcliff451@gmail.com with #ecorute26)
    for (final admin in _adminAccounts) {
      if ((admin['email'] as String).toLowerCase() == cleanEmail &&
          admin['password'] == password) {
        try {
          await _firebaseAuth?.signOut();
        } catch (_) {}
        final user = AppUser(
          id: admin['id'] as String,
          fullName: admin['fullName'] as String,
          email: admin['email'] as String,
          phone: admin['phone'] as String,
          role: AppRole.admin,
          address: admin['address'] as String?,
        );
        await _saveSession(user);
        return user;
      }
    }

    // 2. Check Invited Riders
    final invitedRiders = getInvitedRiders();
    for (final rider in invitedRiders) {
      if ((rider['email'] as String).toLowerCase() == cleanEmail &&
          rider['password'] == password) {
        final user = AppUser(
          id: rider['id'] as String,
          fullName: rider['fullName'] as String,
          email: rider['email'] as String,
          phone: rider['phone'] as String,
          role: AppRole.rider,
          address: 'Arua Depot',
        );
        await _saveSession(user);
        return user;
      }
    }

    // 3. Attempt Firebase Authentication if configured
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

          // Check if admin email
          final isAdminEmail = cleanEmail == 'saviordeogratius@gmail.com' ||
              cleanEmail == 'techcliff451@gmail.com';
          final assignedRole = isAdminEmail
              ? 'admin'
              : (profile?['role'] as String?) ?? 'resident';

          if (profile == null) {
            await profileRef.set({
              'id': firebaseUser.uid,
              'fullName': firebaseUser.displayName ?? cleanEmail.split('@').first,
              'email': cleanEmail,
              'phone': firebaseUser.phoneNumber ?? '+256394880352',
              'role': assignedRole,
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
            role: AppRole.values.byName(assignedRole),
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

    // 4. Fallback to locally registered accounts (Residents)
    final registered = _getRegisteredUsers();
    for (final reg in registered) {
      if ((reg['email'] as String).toLowerCase() == cleanEmail &&
          reg['password'] == password) {
        final user = AppUser(
          id: reg['id'] as String,
          fullName: reg['fullName'] as String,
          email: reg['email'] as String,
          phone: reg['phone'] as String,
          role: AppRole.values.byName((reg['role'] as String?) ?? 'resident'),
          address: reg['address'] as String?,
        );
        await _saveSession(user);
        return user;
      }
    }

    return null;
  }

  /// Self-service registration for residents (or auto-assigned rider if invited)
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

    // Check if email matches an invited rider
    var assignedRole = AppRole.resident;
    final invitedRiders = getInvitedRiders();
    for (final rider in invitedRiders) {
      if ((rider['email'] as String).toLowerCase() == cleanEmail) {
        assignedRole = AppRole.rider;
        break;
      }
    }
    // Also check if matches admin
    if (cleanEmail == 'saviordeogratius@gmail.com' || cleanEmail == 'techcliff451@gmail.com') {
      assignedRole = AppRole.admin;
    }

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
          role: assignedRole,
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
          throw StateError('This email is already registered. Please login.');
        } else if (e.code == 'weak-password') {
          throw StateError('The password is too weak. Please use at least 6 characters.');
        } else if (e.code == 'invalid-email') {
          throw StateError('The email address format is invalid.');
        } else if (e.code == 'network-request-failed' || e.code == 'unavailable') {
          debugPrint('Firebase network unavailable. Falling back to local offline registration.');
        } else {
          throw StateError(e.message ?? 'Registration failed (${e.code}).');
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
      role: assignedRole,
      address: normalizedAddress,
    );

    _saveToLocalRegisteredUsers(user, password);
    await _saveSession(user);
    return user;
  }

  // --- Rider Management (Strictly Admin Invited) ---

  Future<void> inviteRider({
    required String email,
    required String fullName,
    required String phone,
    String defaultPassword = '#ecorute26',
  }) async {
    final cleanEmail = email.trim().toLowerCase();
    final riders = getInvitedRiders();
    riders.removeWhere((r) => (r['email'] as String).toLowerCase() == cleanEmail);
    riders.add({
      'id': 'rider-${DateTime.now().millisecondsSinceEpoch}',
      'fullName': fullName.trim(),
      'email': cleanEmail,
      'phone': phone.trim().isEmpty ? '+256 701 987 654' : phone.trim(),
      'status': 'invited',
      'password': defaultPassword,
      'invitedAt': DateTime.now().toIso8601String(),
    });
    await _preferences.setString(_invitedRidersKey, jsonEncode(riders));

    // Also sync to Firestore
    final firestore = _firestore;
    if (firestore != null) {
      try {
        await firestore.collection('invitedRiders').doc(cleanEmail).set({
          'fullName': fullName.trim(),
          'email': cleanEmail,
          'phone': phone.trim(),
          'status': 'invited',
          'invitedAt': FieldValue.serverTimestamp(),
        });
      } catch (e) {
        debugPrint('Firestore rider invite notice: $e');
      }
    }
  }

  List<Map<String, dynamic>> getInvitedRiders() {
    final raw = _preferences.getString(_invitedRidersKey);
    if (raw == null) {
      return [
        {
          'id': 'rider-demo-1',
          'fullName': 'Juma Okello',
          'email': 'rider.juma@ecoroute.ug',
          'phone': '+256 701 987 654',
          'status': 'active',
          'password': '#ecorute26',
          'invitedAt': DateTime.now().toIso8601String(),
        },
      ];
    }
    try {
      final list = jsonDecode(raw) as List<dynamic>;
      return list.cast<Map<String, dynamic>>();
    } catch (_) {
      return [];
    }
  }

  Future<void> removeRider(String email) async {
    final cleanEmail = email.trim().toLowerCase();
    final riders = getInvitedRiders();
    riders.removeWhere((r) => (r['email'] as String).toLowerCase() == cleanEmail);
    await _preferences.setString(_invitedRidersKey, jsonEncode(riders));
  }

  // --- Resident Directory Management ---

  List<AppUser> getRegisteredResidents() {
    final registered = _getRegisteredUsers();
    final users = <AppUser>[];
    for (final reg in registered) {
      try {
        users.add(AppUser(
          id: reg['id'] as String,
          fullName: reg['fullName'] as String,
          email: reg['email'] as String,
          phone: reg['phone'] as String,
          role: AppRole.values.byName((reg['role'] as String?) ?? 'resident'),
          address: reg['address'] as String?,
        ));
      } catch (_) {}
    }
    return users;
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
    if (raw == null) {
      return [
        {
          'id': 'user-seed-1',
          'fullName': 'Amina Dranzoa',
          'email': 'amina.resident@gmail.com',
          'phone': '+256 772 123 456',
          'role': 'resident',
          'password': '#ecorute26',
          'address': 'Arua Central Market',
        },
      ];
    }
    try {
      final list = jsonDecode(raw) as List<dynamic>;
      return list.cast<Map<String, dynamic>>();
    } catch (_) {
      return [];
    }
  }
}
