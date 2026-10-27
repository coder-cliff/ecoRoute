import 'dart:convert';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart' as firebase_auth;
import 'package:shared_preferences/shared_preferences.dart';

import '../../domain/entities/app_user.dart';
import '../../domain/enums/role.dart';

class AuthService {
  AuthService(this._preferences, {this._firebaseAuth, this._firestore});

  static const String _sessionKey = 'ecoroute_current_user_v1';
  static const String _usersKey = 'ecoroute_registered_users_v1';
  static const String _invitedRidersKey = 'ecoroute_invited_riders_v1';
  static const String supportEmail = 'ecoroute.waste@gmail.com';

  /// Municipal administrator accounts configured with Muni University, Arua defaults
  static const List<Map<String, dynamic>> _adminAccounts = [
    {
      'id': 'admin-deo',
      'fullName': 'Savior Deo (Admin)',
      'email': 'saviordeogratius@gmail.com',
      'phone': '+256 782 555 111',
      'role': 'admin',
      'password': '#ecorute26',
      'address': 'Muni University, Arua',
    },
    {
      'id': 'admin-cliff',
      'fullName': 'Tech Cliff (Admin)',
      'email': 'techcliff451@gmail.com',
      'phone': '+256 701 987 654',
      'role': 'admin',
      'password': '#ecorute26',
      'address': 'Muni University, Arua',
    },
  ];

  final SharedPreferences _preferences;
  final firebase_auth.FirebaseAuth? _firebaseAuth;
  final FirebaseFirestore? _firestore;

  AppUser? getCurrentUser() {
    final raw = _preferences.getString(_sessionKey);
    if (raw == null) return null;
    try {
      final map = jsonDecode(raw) as Map<String, dynamic>;
      final roleName = (map['role'] as String?) ?? AppRole.resident.name;
      return AppUser(
        id: map['id'] as String,
        fullName: map['fullName'] as String,
        email: map['email'] as String,
        phone: map['phone'] as String,
        role: AppRole.values.byName(roleName),
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

          final resolvedRole = profile?['role'] as String? ?? 'resident';
          final user = AppUser(
            id: firebaseUser.uid,
            fullName: (profile?['fullName'] as String?) ??
                firebaseUser.displayName ??
                cleanEmail.split('@').first,
            email: cleanEmail,
            phone: (profile?['phone'] as String?) ??
                firebaseUser.phoneNumber ??
                '',
            role: AppRole.values.byName(resolvedRole),
            address: profile?['address'] as String?,
          );
          await _saveSession(user);
          return user;
        }
      } on firebase_auth.FirebaseAuthException catch (_) {
        return null;
      }
    }

    final registered = _getRegisteredUsers();
    for (final reg in registered) {
      if ((reg['email'] as String).toLowerCase() == cleanEmail) {
        final storedPassword = reg['password'] as String?;
        if (storedPassword == null || storedPassword != password) {
          return null;
        }
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

  Future<AppUser> register({
    required String fullName,
    required String email,
    required String phone,
    required String password,
    AppRole role = AppRole.resident,
    String? address,
  }) async {
    final cleanEmail = email.trim().toLowerCase();
    if (cleanEmail == supportEmail) {
      throw StateError('This email is reserved for the EcoRoute support account.');
    }

    final normalizedPhone = phone.trim();
    if (normalizedPhone.isEmpty) {
      throw StateError('Please enter a valid phone number.');
    }

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

        final user = AppUser(
          id: firebaseUser.uid,
          fullName: fullName.trim(),
          email: cleanEmail,
          phone: normalizedPhone,
          role: role,
          address: address?.trim().isNotEmpty == true ? address!.trim() : null,
        );

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

        await _saveSession(user);
        return user;
      } on firebase_auth.FirebaseAuthException catch (e) {
        if (e.code == 'email-already-in-use') {
          throw StateError('This email is already registered. Please login.');
        }
        if (e.code == 'weak-password') {
          throw StateError('The password is too weak. Please use at least 6 characters.');
        }
        if (e.code == 'invalid-email') {
          throw StateError('The email address format is invalid.');
        }
        throw StateError(e.message ?? 'Registration failed (${e.code}).');
      }
    }

    final user = AppUser(
      id: 'user-${DateTime.now().millisecondsSinceEpoch}',
      fullName: fullName.trim(),
      email: cleanEmail,
      phone: normalizedPhone,
      role: role,
      address: address?.trim().isNotEmpty == true ? address!.trim() : null,
    );

    _saveToLocalRegisteredUsers(user, password);
    await _saveSession(user);
    return user;
  }

  Future<void> inviteRider({
    required String email,
    required String fullName,
    required String phone,
  }) async {
    final cleanEmail = email.trim().toLowerCase();
    final riders = getInvitedRiders();
    riders.removeWhere((r) => (r['email'] as String).toLowerCase() == cleanEmail);
    riders.add({
      'id': 'rider-${DateTime.now().millisecondsSinceEpoch}',
      'fullName': fullName.trim(),
      'email': cleanEmail,
      'phone': phone.trim(),
      'status': 'invited',
      'invitedAt': DateTime.now().toIso8601String(),
    });
    await _preferences.setString(_invitedRidersKey, jsonEncode(riders));
  }

  List<Map<String, dynamic>> getInvitedRiders() {
    final raw = _preferences.getString(_invitedRidersKey);
    if (raw == null) {
      return <Map<String, dynamic>>[];
    }
    try {
      final list = jsonDecode(raw) as List<dynamic>;
      return list.map((e) => Map<String, dynamic>.from(e as Map)).toList();
    } catch (_) {
      return <Map<String, dynamic>>[];
    }
  }

  Future<void> removeRider(String email) async {
    final cleanEmail = email.trim().toLowerCase();
    final riders = getInvitedRiders();
    riders.removeWhere((r) => (r['email'] as String).toLowerCase() == cleanEmail);
    await _preferences.setString(_invitedRidersKey, jsonEncode(riders));
  }

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
      return <Map<String, dynamic>>[];
    }
    try {
      final list = jsonDecode(raw) as List<dynamic>;
      return list.map((e) => Map<String, dynamic>.from(e as Map)).toList();
    } catch (_) {
      return <Map<String, dynamic>>[];
    }
  }
}
