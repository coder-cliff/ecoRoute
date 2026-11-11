import 'dart:convert';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:crypto/crypto.dart';
import 'package:firebase_auth/firebase_auth.dart' as firebase_auth;
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../domain/entities/app_user.dart';
import '../../domain/enums/role.dart';
export '../../domain/enums/role.dart';

class AuthService {
  AuthService(this._preferences, {this._firebaseAuth, this._firestore});

  static const String _sessionKey = 'ecoroute_current_user_v1';
  static const String _usersKey = 'ecoroute_registered_users_v1';
  static const String _invitedRidersKey = 'ecoroute_invited_riders_v1';
  static const String _remindersKey = 'ecoroute_reminders_enabled_v1';
  static const String supportEmail = 'ecoroute.waste@gmail.com';

  SharedPreferences get preferences => _preferences;

  bool getRemindersEnabled() => _preferences.getBool(_remindersKey) ?? true;
  Future<void> setRemindersEnabled(bool enabled) =>
      _preferences.setBool(_remindersKey, enabled);

  /// Salted SHA-256 password hash generator
  static String hashPassword(String password) {
    const salt = 'ecoroute_salt_2026:';
    return sha256.convert(utf8.encode('$salt$password')).toString();
  }

  /// Safe role parser with case-insensitive comparison and fallback
  static AppRole parseRole(String? raw) {
    if (raw == null) return AppRole.resident;
    final clean = raw.trim().toLowerCase();
    if (clean == 'routesupervisor' || clean == 'route_supervisor' || clean == 'supervisor') {
      return AppRole.routeSupervisor;
    }
    if (clean == 'operationsmanager' || clean == 'operations_manager' || clean == 'manager') {
      return AppRole.operationsManager;
    }
    return AppRole.values.firstWhere(
      (r) => r.name.toLowerCase() == clean,
      orElse: () => AppRole.resident,
    );
  }

  /// Rate limiting & login backoff protection against brute force
  static final Map<String, int> _failedAttempts = {};
  static final Map<String, DateTime> _lockoutUntil = {};


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
        photoUrl: map['photoUrl'] as String?,
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
      'photoUrl': user.photoUrl,
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

    // 1. Primary: Firebase Authentication (when cloud services are active)
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
          Map<String, dynamic>? profile;
          try {
            final profileSnapshot = await profileRef.get();
            profile = profileSnapshot.data();
          } catch (e) {
            debugPrint('Firestore profile fetch notice: $e');
          }

          // Role is stored and managed on Firestore, not hardcoded
          var resolvedRole = parseRole(profile?['role'] as String?);

          // If this is a newly authenticated user without a profile doc yet,
          // check if they match municipal admin emails or invited rider records
          if (profile == null) {
            final riderInvite = getRiderInvite(cleanEmail);
            resolvedRole = riderInvite != null ? AppRole.rider : AppRole.resident;

            try {
              await profileRef.set({
                'id': firebaseUser.uid,
                'fullName': firebaseUser.displayName ?? cleanEmail.split('@').first,
                'email': cleanEmail,
                'phone': firebaseUser.phoneNumber ?? '',
                'role': resolvedRole.name,
                'createdAt': FieldValue.serverTimestamp(),
                'updatedAt': FieldValue.serverTimestamp(),
              });
            } catch (e) {
              debugPrint('Firestore profile initial sync notice: $e');
            }
          }

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
            photoUrl: (profile?['photoUrl'] as String?) ?? firebaseUser.photoURL,
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


    // Local registered users verification (used for offline or mock tests)
    final registered = _getRegisteredUsers();
    for (final reg in registered) {
      if ((reg['email'] as String).toLowerCase() == cleanEmail) {
        final storedHash = reg['passwordHash'] as String?;
        final rawStoredPassword = reg['password'] as String?;
        final matches = (storedHash != null && storedHash == inputHash) ||
            (rawStoredPassword != null && rawStoredPassword == password);
        if (matches) {
          final user = AppUser(
            id: reg['id'] as String,
            fullName: reg['fullName'] as String,
            email: reg['email'] as String,
            phone: (reg['phone'] as String?) ?? '',
            role: parseRole(reg['role'] as String?),
            address: reg['address'] as String?,
            photoUrl: reg['photoUrl'] as String?,
          );
          _failedAttempts.remove(cleanEmail);
          _lockoutUntil.remove(cleanEmail);
          await _saveSession(user);
          return user;
        }
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
    String? inviteCode,
    String? photoUrl,
  }) async {
    final cleanEmail = email.trim().toLowerCase();
    if (cleanEmail == supportEmail) {
      throw StateError('This email is reserved for the EcoRoute support account.');
    }

    final normalizedPhone = phone.trim();
    if (normalizedPhone.isEmpty) {
      throw StateError('Please enter a valid phone number.');
    }

    // Auto-detect if user was invited by management as a Rider
    var resolvedRole = role;
    final invite = getRiderInvite(inviteCode?.trim().isNotEmpty == true ? inviteCode!.trim() : cleanEmail);
    if (invite != null) {
      resolvedRole = AppRole.rider;
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
          fullName: fullName.trim().isNotEmpty
              ? fullName.trim()
              : (invite?['fullName'] as String? ?? 'EcoRoute Rider'),
          email: cleanEmail,
          phone: normalizedPhone,
          role: resolvedRole,
          address: address?.trim().isNotEmpty == true ? address!.trim() : null,
          photoUrl: photoUrl,
        );

        try {
          final profileDoc = <String, dynamic>{
            'id': firebaseUser.uid,
            'fullName': user.fullName,
            'email': user.email,
            'phone': user.phone,
            'role': user.role.name,
            'address': user.address,
            'createdAt': FieldValue.serverTimestamp(),
            'updatedAt': FieldValue.serverTimestamp(),
          };
          if (user.photoUrl != null) {
            profileDoc['photoUrl'] = user.photoUrl;
          }
          await firestore.collection('profiles').doc(firebaseUser.uid).set(
            profileDoc,
            SetOptions(merge: true),
          );
        } catch (e) {
          debugPrint('Firestore profile document write notice: $e');
        }

        if (resolvedRole == AppRole.rider) {
          await markInviteAccepted(cleanEmail);
        }

        _saveToLocalRegisteredUsers(user, password);
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
      } on FirebaseException catch (e) {
        debugPrint('Firebase operation notice (${e.code}): ${e.message}');
      }
    }

    final user = AppUser(
      id: 'user-${DateTime.now().millisecondsSinceEpoch}',
      fullName: fullName.trim().isNotEmpty
          ? fullName.trim()
          : (invite?['fullName'] as String? ?? 'EcoRoute Rider'),
      email: cleanEmail,
      phone: normalizedPhone,
      role: resolvedRole,
      address: address?.trim().isNotEmpty == true ? address!.trim() : null,
      photoUrl: photoUrl,
    );

    _saveToLocalRegisteredUsers(user, password);
    if (resolvedRole == AppRole.rider) {
      await markInviteAccepted(cleanEmail);
    }
    await _saveSession(user);
    return user;
  }

  /// Checks if an email or invite code corresponds to an authorized rider invitation
  Map<String, dynamic>? getRiderInvite(String emailOrCode) {
    final query = emailOrCode.trim().toLowerCase();
    final riders = getInvitedRiders();
    for (final rider in riders) {
      final email = (rider['email'] as String? ?? '').toLowerCase();
      final code = (rider['inviteCode'] as String? ?? '').toLowerCase();
      if (email == query || code == query) {
        return rider;
      }
    }
    return null;
  }

  /// Marks an invited rider record as accepted upon custom password registration
  Future<void> markInviteAccepted(String email) async {
    final cleanEmail = email.trim().toLowerCase();
    final riders = getInvitedRiders();
    final index = riders.indexWhere((r) => (r['email'] as String).toLowerCase() == cleanEmail);
    if (index != -1) {
      riders[index]['status'] = 'accepted';
      riders[index]['acceptedAt'] = DateTime.now().toIso8601String();
      await _preferences.setString(_invitedRidersKey, jsonEncode(riders));
    }

    final firestore = _firestore;
    if (firestore != null) {
      try {
        await firestore.collection('invitedRiders').doc(cleanEmail).update({
          'status': 'accepted',
          'acceptedAt': FieldValue.serverTimestamp(),
        });
      } catch (_) {}
    }
  }

  /// Accepts a rider invitation by email or code
  Future<void> acceptRiderInvite(String email, [String? code]) async {
    await markInviteAccepted(email);
  }

  Future<String> inviteRider({
    required String email,
    required String fullName,
    required String phone,
    String? temporaryPin,
  }) async {
    final cleanEmail = email.trim().toLowerCase();
    final cleanPhone = phone.replaceAll(RegExp(r'\s+'), '').trim();
    final inviteCode = 'RIDER-${(DateTime.now().millisecondsSinceEpoch % 1000000).toString().padLeft(6, '0')}';
    final pin = temporaryPin ?? ((DateTime.now().millisecondsSinceEpoch ~/ 10) % 900000 + 100000).toString();
    final riders = getInvitedRiders();
    riders.removeWhere((r) => (r['email'] as String).toLowerCase() == cleanEmail);
    riders.add({
      'id': 'rider-${DateTime.now().millisecondsSinceEpoch}',
      'fullName': fullName.trim(),
      'email': cleanEmail,
      'phone': cleanPhone,
      'inviteCode': inviteCode,
      'temporaryPin': pin,
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
          'phone': cleanPhone,
          'inviteCode': inviteCode,
          'temporaryPin': pin,
          'status': 'invited',
          'invitedAt': FieldValue.serverTimestamp(),
        });
      } catch (_) {}
    }

    return inviteCode;
  }

  /// Validates a rider's phone and temporary PIN for activation.
  Map<String, dynamic>? validateRiderActivation({
    required String phone,
    required String pin,
  }) {
    final cleanPhone = phone.replaceAll(RegExp(r'[\s\-\(\)]'), '').trim();
    final cleanPin = pin.trim();
    if (cleanPhone.isEmpty || cleanPin.isEmpty) return null;

    final riders = getInvitedRiders();
    for (final r in riders) {
      final rPhone = (r['phone'] as String? ?? '').replaceAll(RegExp(r'[\s\-\(\)]'), '').trim();
      final rPin = (r['temporaryPin'] ?? r['inviteCode'] ?? '').toString().trim();
      final rCode = (r['inviteCode'] as String? ?? '').trim();

      final phoneMatch = rPhone == cleanPhone ||
          cleanPhone.endsWith(rPhone.replaceFirst('+256', '0')) ||
          rPhone.endsWith(cleanPhone.replaceFirst('+256', '0')) ||
          cleanPhone.endsWith(rPhone) ||
          rPhone.endsWith(cleanPhone);

      final pinMatch = rPin == cleanPin ||
          rPin.endsWith(cleanPin) ||
          rCode.toLowerCase() == cleanPin.toLowerCase() ||
          rCode.toLowerCase().endsWith(cleanPin.toLowerCase());

      if (phoneMatch && pinMatch) {
        return r;
      }
    }
    return null;
  }

  /// Updates or records a rider's profile setup (name, vehicle, plate, selfie)
  /// and sets status to 'pending_approval'.
  Future<void> submitRiderProfile({
    required String phone,
    required String fullName,
    required String vehicleType,
    required String plateNumber,
    String? selfieBase64,
  }) async {
    final cleanPhone = phone.replaceAll(RegExp(r'[\s\-\(\)]'), '').trim();
    final riders = getInvitedRiders();
    final idx = riders.indexWhere((r) {
      final rPhone = (r['phone'] as String? ?? '').replaceAll(RegExp(r'[\s\-\(\)]'), '').trim();
      return rPhone == cleanPhone || cleanPhone.endsWith(rPhone) || rPhone.endsWith(cleanPhone);
    });

    final updated = <String, dynamic>{
      'phone': cleanPhone,
      'fullName': fullName.trim(),
      'vehicleType': vehicleType,
      'plateNumber': plateNumber.trim().toUpperCase(),
      if (selfieBase64 != null) 'selfieBase64': selfieBase64,
      'status': 'pending_approval',
      'submittedAt': DateTime.now().toIso8601String(),
    };

    if (idx != -1) {
      riders[idx].addAll(updated);
    } else {
      riders.add({
        'id': 'rider-${DateTime.now().millisecondsSinceEpoch}',
        ...updated,
      });
    }

    await _preferences.setString(_invitedRidersKey, jsonEncode(riders));
  }

  /// Checks if a rider's account is approved.
  bool isRiderApproved(String phone) {
    final cleanPhone = phone.replaceAll(RegExp(r'[\s\-\(\)]'), '').trim();
    final riders = getInvitedRiders();
    for (final r in riders) {
      final rPhone = (r['phone'] as String? ?? '').replaceAll(RegExp(r'[\s\-\(\)]'), '').trim();
      if (rPhone == cleanPhone || cleanPhone.endsWith(rPhone) || rPhone.endsWith(cleanPhone)) {
        final status = (r['status'] as String? ?? '').toLowerCase();
        return status == 'active' || status == 'approved';
      }
    }
    return false;
  }

  /// Approves a rider's application.
  Future<void> approveRider(String phone) async {
    final cleanPhone = phone.replaceAll(RegExp(r'[\s\-\(\)]'), '').trim();
    final riders = getInvitedRiders();
    for (final r in riders) {
      final rPhone = (r['phone'] as String? ?? '').replaceAll(RegExp(r'[\s\-\(\)]'), '').trim();
      if (rPhone == cleanPhone || cleanPhone.endsWith(rPhone) || rPhone.endsWith(cleanPhone)) {
        r['status'] = 'active';
        r['approvedAt'] = DateTime.now().toIso8601String();
      }
    }
    await _preferences.setString(_invitedRidersKey, jsonEncode(riders));
  }

  List<Map<String, dynamic>> getInvitedRiders() {
    final raw = _preferences.getString(_invitedRidersKey);
    if (raw == null) {
      return <Map<String, dynamic>>[];
    }
    try {
      final list = jsonDecode(raw) as List<dynamic>;
      return list
          .map((e) => Map<String, dynamic>.from(e as Map))
          .where((r) {
            final name = (r['fullName'] as String? ?? '').toLowerCase();
            final email = (r['email'] as String? ?? '').toLowerCase();
            return !name.contains('acan') &&
                !name.contains('kato') &&
                !name.contains('okello') &&
                !name.contains('mukasa') &&
                !name.contains('drileba') &&
                !name.contains('atiku') &&
                !name.contains('buga') &&
                !name.contains('ayiko') &&
                !email.contains('demo');
          })
          .toList();
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

  /// Updates the profile attributes of the currently logged-in user
  Future<AppUser> updateUserProfile({
    required String fullName,
    required String phone,
    String? address,
    String? photoUrl,
  }) async {
    final current = getCurrentUser();
    if (current == null) {
      throw StateError('No user is currently signed in.');
    }

    final updated = AppUser(
      id: current.id,
      fullName: fullName.trim(),
      email: current.email,
      phone: phone.trim(),
      role: current.role,
      address: address?.trim().isNotEmpty == true ? address!.trim() : null,
      photoUrl: photoUrl ?? current.photoUrl,
    );

    await _saveSession(updated);

    // Update in registered users list if present
    final registered = _getRegisteredUsers();
    final index = registered.indexWhere(
      (u) => (u['email'] as String).toLowerCase() == current.email.toLowerCase(),
    );
    if (index != -1) {
      registered[index]['fullName'] = updated.fullName;
      registered[index]['phone'] = updated.phone;
      registered[index]['address'] = updated.address;
      registered[index]['photoUrl'] = updated.photoUrl;
      await _preferences.setString(_usersKey, jsonEncode(registered));
    }

    // Sync to Firestore if active
    final firestore = _firestore;
    if (firestore != null) {
      try {
        final profileData = <String, dynamic>{
          'fullName': updated.fullName,
          'phone': updated.phone,
          'address': updated.address,
          'updatedAt': FieldValue.serverTimestamp(),
        };
        if (updated.photoUrl != null) {
          profileData['photoUrl'] = updated.photoUrl;
        }
        await firestore.collection('profiles').doc(current.id).set(
          profileData,
          SetOptions(merge: true),
        );
      } catch (_) {}
    }

    return updated;
  }

  /// Dedicated fast update for profile picture
  Future<AppUser> updateProfilePhoto(String? photoUrl) async {
    final current = getCurrentUser();
    if (current == null) {
      throw StateError('No user is currently signed in.');
    }
    final updated = AppUser(
      id: current.id,
      fullName: current.fullName,
      email: current.email,
      phone: current.phone,
      role: current.role,
      address: current.address,
      photoUrl: photoUrl,
    );
    await _saveSession(updated);

    final registered = _getRegisteredUsers();
    final index = registered.indexWhere(
      (u) => (u['email'] as String).toLowerCase() == current.email.toLowerCase(),
    );
    if (index != -1) {
      registered[index]['photoUrl'] = photoUrl;
      await _preferences.setString(_usersKey, jsonEncode(registered));
    }

    final firestore = _firestore;
    if (firestore != null) {
      try {
        await firestore.collection('profiles').doc(current.id).set({
          'photoUrl': photoUrl,
          'updatedAt': FieldValue.serverTimestamp(),
        }, SetOptions(merge: true));
      } catch (_) {}
    }

    return updated;
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
          photoUrl: reg['photoUrl'] as String?,
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
        final snapshot = await firestore.collection('profiles').get();
        if (snapshot.docs.isNotEmpty) {
          final users = <AppUser>[];
          for (final doc in snapshot.docs) {
            final data = doc.data();
            final role = parseRole(data['role'] as String?);
            if (role == AppRole.resident) {
              users.add(AppUser(
                id: data['id'] as String? ?? doc.id,
                fullName: data['fullName'] as String? ?? 'Resident',
                email: data['email'] as String? ?? '',
                phone: data['phone'] as String? ?? '',
                role: AppRole.resident,
                address: data['address'] as String?,
                photoUrl: data['photoUrl'] as String?,
              ));
            }
          }
          final userMaps = users.map((u) => {
            'id': u.id,
            'fullName': u.fullName,
            'email': u.email,
            'phone': u.phone,
            'role': u.role.name,
            'address': u.address,
            'photoUrl': u.photoUrl,
          }).toList();
          await _preferences.setString(_usersKey, jsonEncode(userMaps));
          return users;
        }
      } catch (e) {
        debugPrint('Firestore fetchResidents notice: $e');
      }
    }
    return getRegisteredResidents();
  }

  /// Updates a user's role on Firestore profiles collection and local store
  Future<void> updateUserRole({
    required String userId,
    required AppRole newRole,
    String? userEmail,
  }) async {
    // 1. Update Firestore if active
    final firestore = _firestore;
    if (firestore != null) {
      try {
        await firestore.collection('profiles').doc(userId).set({
          'role': newRole.name,
          'updatedAt': FieldValue.serverTimestamp(),
        }, SetOptions(merge: true));
      } catch (_) {}
    }

    // 2. Update local registered users
    final registered = _getRegisteredUsers();
    final index = registered.indexWhere(
      (u) => u['id'] == userId ||
          (userEmail != null && (u['email'] as String).toLowerCase() == userEmail.toLowerCase()),
    );
    if (index != -1) {
      registered[index]['role'] = newRole.name;
      await _preferences.setString(_usersKey, jsonEncode(registered));
    }

    // 3. Update current session if matching
    final current = getCurrentUser();
    if (current != null &&
        (current.id == userId ||
            (userEmail != null && current.email.toLowerCase() == userEmail.toLowerCase()))) {
      final updated = current.copyWith(role: newRole);
      await _saveSession(updated);
    }
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
      'photoUrl': user.photoUrl,
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
      return list
          .map((e) => Map<String, dynamic>.from(e as Map))
          .where((u) {
            final email = (u['email'] as String? ?? '').toLowerCase();
            final name = (u['fullName'] as String? ?? '').toLowerCase();
            return !email.contains('demo') &&
                !email.contains('saviordeogratius') &&
                !email.contains('techcliff') &&
                !name.contains('jane') &&
                !name.contains('ayiko') &&
                !name.contains('acan') &&
                !name.contains('kato') &&
                !name.contains('okello');
          })
          .toList();
    } catch (_) {
      return <Map<String, dynamic>>[];
    }
  }
}
