import 'dart:convert';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/waste_request.dart';
import '../models/waste_category.dart';
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

    final initialRequests = _getInitialRequests(users ?? _getInitialUsers());
    await saveRequests(initialRequests);
    return initialRequests;
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
        } else {
          // Cloud Firestore has not been seeded yet. Auto-seed preconfigured demo personas into Firebase:
          final initialUsers = _getInitialUsers();
          final batch = FirebaseFirestore.instance.batch();
          for (final u in initialUsers) {
            final userDoc = FirebaseFirestore.instance.collection('users').doc(u.id);
            final profileDoc = FirebaseFirestore.instance.collection('profiles').doc(u.id);
            batch.set(userDoc, u.toJson());
            batch.set(profileDoc, u.toJson());
          }
          await batch.commit();
          await saveUsers(initialUsers, syncToCloud: false);
          return initialUsers;
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

    // 3. Baseline preconfigured demo personas
    final initialUsers = _getInitialUsers();
    await saveUsers(initialUsers);
    return initialUsers;
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

  /// Baseline standard accounts with distinct, professional DPs and details
  static List<AppUser> _getInitialUsers() {
    return [
      const AppUser(
        id: 'usr_resident_01',
        name: 'Sarah Namukasa',
        phone: '+256 772 123456',
        email: 'sarah.namukasa@ecoroute.app',
        role: UserRole.citizen,
        avatarUrl: 'https://images.unsplash.com/photo-1534528741775-53994a69daeb?w=200&auto=format&fit=crop&q=80',
        address: 'Plot 12, Acacia Avenue, Kololo, Kampala',
      ),
      const AppUser(
        id: 'usr_rider_01',
        name: 'Alex Mukasa',
        phone: '+256 701 987654',
        email: 'alex.mukasa@ecoroute.app',
        role: UserRole.rider,
        avatarUrl: 'https://images.unsplash.com/photo-1507003211169-0a1dd7228f2d?w=200&auto=format&fit=crop&q=80',
        address: 'Kisementi Collection Depot, Kamwokya',
        vehicleInfo: 'Eco Cargo Tricycle #12',
      ),
      const AppUser(
        id: 'usr_rider_02',
        name: 'Brian Kato',
        phone: '+256 702 334455',
        email: 'brian.kato@ecoroute.app',
        role: UserRole.rider,
        avatarUrl: 'https://images.unsplash.com/photo-1500648767791-00dcc994a43e?w=200&auto=format&fit=crop&q=80',
        address: 'Makerere Hill Service Hub',
        vehicleInfo: 'Tricycle #05',
      ),
      const AppUser(
        id: 'usr_admin_01',
        name: 'Grace Atuhaire',
        phone: '+256 750 334455',
        email: 'grace.atuhaire@ecoroute.app',
        role: UserRole.admin,
        avatarUrl: 'https://images.unsplash.com/photo-1573496359142-b8d87734a5a2?w=200&auto=format&fit=crop&q=80',
        address: 'Central Waste Operations Command, Kampala',
      ),
    ];
  }

  static List<WasteRequest> _getInitialRequests(List<AppUser> users) {
    final now = DateTime.now();
    final resident = users.firstWhere(
      (u) => u.role == UserRole.citizen,
      orElse: () => _getInitialUsers().first,
    );
    final rider = users.firstWhere(
      (u) => u.role == UserRole.rider,
      orElse: () => _getInitialUsers()[1],
    );

    return [
      WasteRequest(
        id: 'REQ-2026-101',
        userId: resident.id,
        userName: resident.name,
        userPhone: resident.phone,
        photoPath: 'simulated_sample_plastics',
        categoryType: WasteCategoryType.plastics,
        quantityBags: 3,
        latitude: 0.3345,
        longitude: 32.5690,
        address: resident.address.isNotEmpty
            ? resident.address
            : 'Plot 12, Acacia Avenue, Kololo, Kampala',
        notes: 'Three sorted bags of plastic water bottles and milk jugs behind the front gate.',
        estimatedCashAmount: 6.00,
        status: RequestStatus.pending,
        createdAt: now.subtract(const Duration(hours: 2)),
        scheduledPickupTime: now.add(const Duration(hours: 3)),
      ),
      WasteRequest(
        id: 'REQ-2026-102',
        userId: 'usr_resident_guest',
        userName: 'David Ochieng',
        userPhone: '+256 782 556677',
        photoPath: 'simulated_sample_organic',
        categoryType: WasteCategoryType.organic,
        quantityBags: 2,
        latitude: 0.3382,
        longitude: 32.5715,
        address: 'Kisementi Shopping Center Lane, Kamwokya',
        notes: 'Vegetable kitchen waste from restaurant prep. Sealed bags.',
        estimatedCashAmount: 3.00,
        status: RequestStatus.assigned,
        assignedRiderId: rider.id,
        assignedRiderName: rider.name,
        createdAt: now.subtract(const Duration(hours: 4)),
        scheduledPickupTime: now.add(const Duration(hours: 1)),
      ),
      WasteRequest(
        id: 'REQ-2026-103',
        userId: resident.id,
        userName: resident.name,
        userPhone: resident.phone,
        photoPath: 'simulated_sample_ewaste',
        categoryType: WasteCategoryType.eWaste,
        quantityBags: 1,
        latitude: 0.3312,
        longitude: 32.5648,
        address: 'Makerere Hill Road, Near Main Gate',
        notes: 'Old laser printer and dead laptop batteries for recycling.',
        estimatedCashAmount: 4.00,
        status: RequestStatus.collected,
        assignedRiderId: rider.id,
        assignedRiderName: rider.name,
        createdAt: now.subtract(const Duration(days: 1, hours: 3)),
        scheduledPickupTime: now.subtract(const Duration(days: 1)),
        collectedAt: now.subtract(const Duration(days: 1, minutes: 45)),
        isCashCollected: true,
        actualCashPaid: 4.00,
        receiptNumber: 'RCP-88392',
      ),
    ];
  }
}
