import 'dart:convert';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/waste_request.dart';
import '../models/user_model.dart';

class StorageService {
  static const String _keyRequests = 'ecoroute_waste_requests_v2';
  static const String _keyActiveUserId = 'ecoroute_active_user_id_v2';
  static const String _keyUsers = 'ecoroute_registered_users_v2';
  static const int maxPersistedRequests = 100;

  /// Saves list of requests to Firebase Firestore and local persistent storage
  static Future<bool> saveRequests(List<WasteRequest> requests) async {
    final cappedRequests = requests.length > maxPersistedRequests
        ? requests.sublist(0, maxPersistedRequests)
        : requests;

    // Sync to Cloud Firestore if Firebase is active
    if (Firebase.apps.isNotEmpty) {
      try {
        final batch = FirebaseFirestore.instance.batch();
        for (final req in cappedRequests) {
          final docRef = FirebaseFirestore.instance.collection('requests').doc(req.id);
          batch.set(docRef, req.toJson(), SetOptions(merge: true));
        }
        await batch.commit();
      } catch (e) {
        debugPrint('Firestore saveRequests notice: $e');
      }
    }

    try {
      final prefs = await SharedPreferences.getInstance();
      final listJson = cappedRequests.map((r) => r.toJson()).toList();
      final encoded = jsonEncode(listJson);
      return await prefs.setString(_keyRequests, encoded);
    } catch (e) {
      debugPrint('StorageService saveRequests error: $e');
      return false;
    }
  }

  /// Loads list of requests from Firebase Firestore, falling back to local persistent storage
  static Future<List<WasteRequest>> loadRequests([List<AppUser>? users]) async {
    // 1. Try Firebase Cloud Firestore first
    if (Firebase.apps.isNotEmpty) {
      try {
        final query = await FirebaseFirestore.instance
            .collection('requests')
            .limit(maxPersistedRequests)
            .get();
        if (query.docs.isNotEmpty) {
          final cloudList = query.docs
              .map((doc) => WasteRequest.fromJson(doc.data()))
              .toList();
          if (cloudList.isNotEmpty) {
            final prefs = await SharedPreferences.getInstance();
            final listJson = cloudList.map((r) => r.toJson()).toList();
            await prefs.setString(_keyRequests, jsonEncode(listJson));
            return cloudList;
          }
        }
      } catch (e) {
        debugPrint('Firestore loadRequests notice: $e');
      }
    }

    // 2. Fall back to local SharedPreferences cache
    try {
      final prefs = await SharedPreferences.getInstance();
      final raw = prefs.getString(_keyRequests);
      if (raw != null && raw.isNotEmpty) {
        final List<dynamic> decoded = jsonDecode(raw);
        return decoded
            .map((item) => WasteRequest.fromJson(item as Map<String, dynamic>))
            .toList();
      }
    } catch (e) {
      debugPrint('StorageService loadRequests error: $e');
    }

    return [];
  }

  /// Saves a single user to Cloud Firestore and local storage
  static Future<void> saveUser(AppUser user) async {
    if (Firebase.apps.isNotEmpty) {
      try {
        await FirebaseFirestore.instance
            .collection('users')
            .doc(user.id)
            .set(user.toJson(), SetOptions(merge: true));
        await FirebaseFirestore.instance
            .collection('profiles')
            .doc(user.id)
            .set(user.toJson(), SetOptions(merge: true));
      } catch (e) {
        debugPrint('Firestore saveUser notice: $e');
      }
    }

    final existing = await loadUsers();
    final idx = existing.indexWhere((u) => u.id == user.id);
    if (idx != -1) {
      existing[idx] = user;
    } else {
      existing.add(user);
    }
    await saveUsers(existing, syncToCloud: false);
  }

  /// Saves list of registered users to Firebase Firestore and local storage
  static Future<bool> saveUsers(List<AppUser> users, {bool syncToCloud = true}) async {
    if (syncToCloud && Firebase.apps.isNotEmpty) {
      try {
        final batch = FirebaseFirestore.instance.batch();
        for (final u in users) {
          final userDoc = FirebaseFirestore.instance.collection('users').doc(u.id);
          final profileDoc = FirebaseFirestore.instance.collection('profiles').doc(u.id);
          batch.set(userDoc, u.toJson(), SetOptions(merge: true));
          batch.set(profileDoc, u.toJson(), SetOptions(merge: true));
        }
        await batch.commit();
      } catch (e) {
        debugPrint('Firestore saveUsers notice: $e');
      }
    }

    try {
      final prefs = await SharedPreferences.getInstance();
      final listJson = users.map((u) => u.toJson()).toList();
      return await prefs.setString(_keyUsers, jsonEncode(listJson));
    } catch (e) {
      debugPrint('StorageService saveUsers error: $e');
      return false;
    }
  }

  /// Loads list of registered users directly from Firebase Firestore
  static Future<List<AppUser>> loadUsers() async {
    // 1. Fetch from Firebase Cloud Firestore
    if (Firebase.apps.isNotEmpty) {
      try {
        final query = await FirebaseFirestore.instance.collection('users').get();
        if (query.docs.isNotEmpty) {
          final list = query.docs
              .map((doc) => AppUser.fromJson({...doc.data(), 'id': doc.id}))
              .toList();
          if (list.isNotEmpty) {
            await saveUsers(list, syncToCloud: false);
            return list;
          }
        }
      } catch (e) {
        debugPrint('Firestore loadUsers notice: $e');
      }
    }

    // 2. Fetch from SharedPreferences cache
    try {
      final prefs = await SharedPreferences.getInstance();
      final raw = prefs.getString(_keyUsers);
      if (raw != null && raw.isNotEmpty) {
        final List<dynamic> decoded = jsonDecode(raw);
        final list = decoded
            .map((item) => AppUser.fromJson(item as Map<String, dynamic>))
            .toList();
        if (list.isNotEmpty) {
          return list;
        }
      }
    } catch (e) {
      debugPrint('StorageService loadUsers error: $e');
    }

    // 3. No preconfigured accounts - purely dynamic from Firebase
    return [];
  }

  /// Saves currently selected active user id
  static Future<void> saveActiveUserId(String userId) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_keyActiveUserId, userId);
  }

  /// Retrieves saved active user id
  static Future<String?> getActiveUserId() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_keyActiveUserId);
  }
}
