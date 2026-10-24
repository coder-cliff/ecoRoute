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
    },
    {
      'id': 'rider-demo-1',
      'fullName': 'Juma Okello (Route Rider)',
      'email': 'rider@ecoroute.demo',
      'phone': '+256 701 987 654',
      'role': 'rider',
      'password': 'demo123',
    },
    {
      'id': 'admin-demo-1',
      'fullName': 'Grace Candiru (Municipal Admin)',
      'email': 'admin@ecoroute.demo',
      'phone': '+256 782 555 111',
      'role': 'admin',
      'password': 'demo123',
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
    };
    await _preferences.setString(_sessionKey, jsonEncode(data));
  }

  Future<void> logout() async {
    await _firebaseAuth?.signOut();
    await _preferences.remove(_sessionKey);
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
        await _firebaseAuth?.signOut();
        final user = AppUser(
          id: demo['id'] as String,
          fullName: demo['fullName'] as String,
          email: demo['email'] as String,
          phone: demo['phone'] as String,
          role: AppRole.values.byName(demo['role'] as String),
        );
        await _saveSession(user);
        return user;
      }
    }

    final firebaseAuth = _firebaseAuth;
    final firestore = _firestore;
    if (firebaseAuth != null && firestore != null) {
      final credential = await firebaseAuth.signInWithEmailAndPassword(
        email: cleanEmail,
        password: password,
      );
      final firebaseUser = credential.user;
      if (firebaseUser == null || firebaseUser.email == null) return null;

      final profileRef = firestore.collection('profiles').doc(firebaseUser.uid);
      final profileSnapshot = await profileRef.get();
      final profile = profileSnapshot.data();
      if (profile == null) {
        await profileRef.set({
          'id': firebaseUser.uid,
          'fullName': firebaseUser.displayName ?? '',
          'email': cleanEmail,
          'phone': firebaseUser.phoneNumber ?? '',
          'role': 'resident',
          'createdAt': FieldValue.serverTimestamp(),
          'updatedAt': FieldValue.serverTimestamp(),
        });
      }

      final user = AppUser(
        id: firebaseUser.uid,
        fullName:
            (profile?['fullName'] as String?) ??
            firebaseUser.displayName ??
            cleanEmail,
        email: cleanEmail,
        phone: (profile?['phone'] as String?) ?? firebaseUser.phoneNumber ?? '',
        role: AppRole.values.byName(
          (profile?['role'] as String?) ?? 'resident',
        ),
      );
      await _saveSession(user);
      return user;
    }

    // 2. Check registered accounts
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
  }) async {
    final cleanEmail = email.trim().toLowerCase();
    final firebaseAuth = _firebaseAuth;
    final firestore = _firestore;
    if (firebaseAuth != null && firestore != null) {
      final credential = await firebaseAuth.createUserWithEmailAndPassword(
        email: cleanEmail,
        password: password,
      );
      final firebaseUser = credential.user;
      if (firebaseUser == null) {
        throw StateError('Firebase did not return the created user.');
      }

      final normalizedPhone = phone.trim().isEmpty
          ? '+256 772 000 000'
          : phone.trim();
      final user = AppUser(
        id: firebaseUser.uid,
        fullName: fullName.trim(),
        email: cleanEmail,
        phone: normalizedPhone,
        role: AppRole.resident,
      );
      await firestore.collection('profiles').doc(firebaseUser.uid).set({
        'id': firebaseUser.uid,
        'fullName': user.fullName,
        'email': user.email,
        'phone': user.phone,
        'role': user.role.name,
        'createdAt': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
      });
      await _saveSession(user);
      return user;
    }

    final users = _getRegisteredUsers();

    final userId = 'user-${DateTime.now().millisecondsSinceEpoch}';
    final newUserMap = {
      'id': userId,
      'fullName': fullName.trim(),
      'email': cleanEmail,
      'phone': phone.trim().isEmpty ? '+256 772 000 000' : phone.trim(),
      'role': role.name,
      'password': password,
    };

    users.removeWhere(
      (u) => (u['email'] as String).toLowerCase() == cleanEmail,
    );
    users.add(newUserMap);

    await _preferences.setString(_usersKey, jsonEncode(users));

    final user = AppUser(
      id: userId,
      fullName: fullName.trim(),
      email: cleanEmail,
      phone: phone.trim().isEmpty ? '+256 772 000 000' : phone.trim(),
      role: role,
    );
    await _saveSession(user);
    return user;
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
