import 'dart:convert';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:crypto/crypto.dart';
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

  /// Salted SHA-256 password hash generator
  static String hashPassword(String password) {
    const salt = 'ecoroute_salt_2026:';
    return sha256.convert(utf8.encode('$salt$password')).toString();
  }

  /// Safe role parser with case-insensitive comparison and fallback
  static AppRole parseRole(String? raw) {
    if (raw == null) return AppRole.resident;
    final clean = raw.trim().toLowerCase();
    return AppRole.values.firstWhere(
      (r) => r.name.toLowerCase() == clean,
      orElse: () => AppRole.resident,
    );
  }

  /// Rate limiting & login backoff protection against brute force
  static final Map<String, int> _failedAttempts = {};
  static final Map<String, DateTime> _lockoutUntil = {};

  /// Municipal administrator accounts configured with Muni University, Arua defaults.
  /// Passwords are never stored in plaintext; salted SHA-256 hashes are used.
  static const List<Map<String, dynamic>> _adminAccounts = [
    {
      'id': 'admin-deo',
      'fullName': 'Savior Deo (Admin)',
      'email': 'saviordeogratius@gmail.com',
      'phone': '+256 782 555 111',
      'role': 'admin',
      'passwordHash': '8253199c086111be1ce87d0c3eb1a473c4ab5cb58d4a46059d4791e8477ff962',
      'address': 'Muni University, Arua',
    },
    {
      'id': 'admin-cliff',
      'fullName': 'Tech Cliff (Admin)',
      'email': 'techcliff451@gmail.com',
      'phone': '+256 701 987 654',
      'role': 'admin',
      'passwordHash': '8253199c086111be1ce87d0c3eb1a473c4ab5cb58d4a46059d4791e8477ff962',
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
      final role = parseRole(map['role'] as String?);
      return AppUser(
        id: map['id'] as String,
        fullName: map['fullName'] as String,
        email: map['email'] as String,
        phone: map['phone'] as String,
        role: role,
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
      'savedAt': DateTime.now().toIso8601String(),
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

  /// Sends a password reset email via Firebase Auth
  Future<void> sendPasswordResetEmail(String email) async {
    final cleanEmail = email.trim().toLowerCase();
    final auth = _firebaseAuth;
    if (auth != null) {
      await auth.sendPasswordResetEmail(email: cleanEmail);
    }
  }

  /// Sends email verification to the currently logged in Firebase user
  Future<void> sendEmailVerification() async {
    final user = _firebaseAuth?.currentUser;
    if (user != null && !user.emailVerified) {
      await user.sendEmailVerification();
    }
  }

  /// Checks if the current user's email is verified
  bool isEmailVerified() {
    final user = _firebaseAuth?.currentUser;
    if (user == null) return true; // Local / guest fallback
    return user.emailVerified;
  }

  Future<AppUser?> login({
    required String email,
    required String password,
  }) async {
    final cleanEmail = email.trim().toLowerCase();

    // Check rate-limiting / lockout
    final lockout = _lockoutUntil[cleanEmail];
    if (lockout != null && DateTime.now().isBefore(lockout)) {
      final secondsLeft = lockout.difference(DateTime.now()).inSeconds;
      throw StateError(
        'Too many failed login attempts. Please wait ${secondsLeft > 0 ? secondsLeft : 1}s before trying again.',
      );
    }

    final inputHash = hashPassword(password);

    // 1. Check Admin accounts with hashed password verification
    for (final admin in _adminAccounts) {
      if ((admin['email'] as String).toLowerCase() == cleanEmail &&
          admin['passwordHash'] == inputHash) {
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
        _failedAttempts.remove(cleanEmail);
        _lockoutUntil.remove(cleanEmail);
        await _saveSession(user);
        return user;
      }
    }

    // 2. Firebase Auth login
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

          final resolvedRole = parseRole(profile?['role'] as String?);
          final user = AppUser(
            id: firebaseUser.uid,
            fullName: (profile?['fullName'] as String?) ??
                firebaseUser.displayName ??
                cleanEmail.split('@').first,
            email: cleanEmail,
            phone: (profile?['phone'] as String?) ??
                firebaseUser.phoneNumber ??
                '',
            role: resolvedRole,
            address: profile?['address'] as String?,
          );
          _failedAttempts.remove(cleanEmail);
          _lockoutUntil.remove(cleanEmail);
          await _saveSession(user);
          return user;
        }
      } on firebase_auth.FirebaseAuthException catch (_) {
        _recordFailedLogin(cleanEmail);
        return null;
      }
    }

    // 3. Registered local users with hashed password verification
    final registered = _getRegisteredUsers();
    for (final reg in registered) {
      if ((reg['email'] as String).toLowerCase() == cleanEmail) {
        final storedHash = reg['passwordHash'] as String?;
        final rawStoredPassword = reg['password'] as String?; // Migration legacy

        final matches = (storedHash != null && storedHash == inputHash) ||
            (rawStoredPassword != null && rawStoredPassword == password);

        if (!matches) {
          _recordFailedLogin(cleanEmail);
          return null;
        }

        final role = parseRole((reg['role'] as String?) ?? 'resident');
        final user = AppUser(
          id: reg['id'] as String,
          fullName: reg['fullName'] as String,
          email: reg['email'] as String,
          phone: reg['phone'] as String,
          role: role,
          address: reg['address'] as String?,
        );
        _failedAttempts.remove(cleanEmail);
        _lockoutUntil.remove(cleanEmail);
        await _saveSession(user);
        return user;
      }
    }

    _recordFailedLogin(cleanEmail);
    return null;
  }

  void _recordFailedLogin(String email) {
    final attempts = (_failedAttempts[email] ?? 0) + 1;
    _failedAttempts[email] = attempts;
    if (attempts >= 3) {
      // Exponential lockout: 10s on 3rd attempt, 30s on 4th, 60s thereafter
      final lockoutDuration = attempts == 3
          ? const Duration(seconds: 10)
          : attempts == 4
              ? const Duration(seconds: 30)
              : const Duration(seconds: 60);
      _lockoutUntil[email] = DateTime.now().add(lockoutDuration);
    }
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
          throw StateError('The password is too weak. Please use at least 8 characters.');
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

  Future<String> inviteRider({
    required String email,
    required String fullName,
    required String phone,
  }) async {
    final cleanEmail = email.trim().toLowerCase();
    final inviteCode = 'RIDER-${(DateTime.now().millisecondsSinceEpoch % 1000000).toString().padLeft(6, '0')}';
    final riders = getInvitedRiders();
    riders.removeWhere((r) => (r['email'] as String).toLowerCase() == cleanEmail);
    riders.add({
      'id': 'rider-${DateTime.now().millisecondsSinceEpoch}',
      'fullName': fullName.trim(),
      'email': cleanEmail,
      'phone': phone.trim(),
      'inviteCode': inviteCode,
      'status': 'invited',
      'invitedAt': DateTime.now().toIso8601String(),
    });
    await _preferences.setString(_invitedRidersKey, jsonEncode(riders));

    // Sync to Firestore if available
    final firestore = _firestore;
    if (firestore != null) {
      try {
        await firestore.collection('invitedRiders').doc(cleanEmail).set({
          'fullName': fullName.trim(),
          'email': cleanEmail,
          'phone': phone.trim(),
          'inviteCode': inviteCode,
          'status': 'invited',
          'invitedAt': FieldValue.serverTimestamp(),
        });
      } catch (_) {}
    }

    return inviteCode;
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

  /// Queries cloud Firestore invited riders when online with offline cache fallback
  Future<List<Map<String, dynamic>>> fetchInvitedRidersAsync() async {
    final firestore = _firestore;
    if (firestore != null) {
      try {
        final snapshot = await firestore.collection('invitedRiders').get();
        if (snapshot.docs.isNotEmpty) {
          final riders = snapshot.docs.map((d) => d.data()).toList();
          await _preferences.setString(_invitedRidersKey, jsonEncode(riders));
          return riders;
        }
      } catch (_) {}
    }
    return getInvitedRiders();
  }

  Future<void> removeRider(String email) async {
    final cleanEmail = email.trim().toLowerCase();
    final riders = getInvitedRiders();
    riders.removeWhere((r) => (r['email'] as String).toLowerCase() == cleanEmail);
    await _preferences.setString(_invitedRidersKey, jsonEncode(riders));

    final firestore = _firestore;
    if (firestore != null) {
      try {
        await firestore.collection('invitedRiders').doc(cleanEmail).delete();
      } catch (_) {}
    }
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
          role: parseRole((reg['role'] as String?) ?? 'resident'),
          address: reg['address'] as String?,
        ));
      } catch (_) {}
    }
    return users;
  }

  /// Queries cloud Firestore profiles for registered residents with offline fallback
  Future<List<AppUser>> fetchResidentsAsync() async {
    final firestore = _firestore;
    if (firestore != null) {
      try {
        final snapshot = await firestore
            .collection('profiles')
            .where('role', isEqualTo: 'resident')
            .get();
        if (snapshot.docs.isNotEmpty) {
          final users = snapshot.docs.map((doc) {
            final data = doc.data();
            return AppUser(
              id: data['id'] as String? ?? doc.id,
              fullName: data['fullName'] as String? ?? 'Resident',
              email: data['email'] as String? ?? '',
              phone: data['phone'] as String? ?? '',
              role: parseRole(data['role'] as String?),
              address: data['address'] as String?,
            );
          }).toList();
          return users;
        }
      } catch (_) {}
    }
    return getRegisteredResidents();
  }

  void _saveToLocalRegisteredUsers(AppUser user, String password) {
    final users = _getRegisteredUsers();
    final newUserMap = {
      'id': user.id,
      'fullName': user.fullName,
      'email': user.email,
      'phone': user.phone,
      'role': user.role.name,
      'passwordHash': hashPassword(password),
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
