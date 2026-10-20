import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/waste_request.dart';
import '../models/waste_category.dart';
import '../models/user_model.dart';

class StorageService {
  static const String _keyRequests = 'ecoroute_waste_requests_v1';
  static const String _keyActiveUserId = 'ecoroute_active_user_id_v1';

  /// Saves list of requests to persistent storage
  static Future<bool> saveRequests(List<WasteRequest> requests) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final listJson = requests.map((r) => r.toJson()).toList();
      final encoded = jsonEncode(listJson);
      return await prefs.setString(_keyRequests, encoded);
    } catch (e) {
      debugPrint('StorageService save error: $e');
      return false;
    }
  }

  /// Loads list of requests from persistent storage, or generates seed data if empty
  static Future<List<WasteRequest>> loadRequests() async {
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
      debugPrint('StorageService load error: $e');
    }

    // Default seed requests if first time launching
    final seedRequests = _getSeedRequests();
    await saveRequests(seedRequests);
    return seedRequests;
  }

  /// Saves currently selected active user role/id
  static Future<void> saveActiveUserId(String userId) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_keyActiveUserId, userId);
  }

  /// Retrieves saved active user id
  static Future<String?> getActiveUserId() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_keyActiveUserId);
  }

  static List<WasteRequest> _getSeedRequests() {
    final now = DateTime.now();
    return [
      WasteRequest(
        id: 'REQ-2026-101',
        userId: AppUser.demoCitizen.id,
        userName: AppUser.demoCitizen.name,
        userPhone: AppUser.demoCitizen.phone,
        photoPath: 'assets/sample_plastics.jpg',
        categoryType: WasteCategoryType.plastics,
        quantityBags: 3,
        latitude: 0.3345,
        longitude: 32.5690,
        address: 'Plot 12, Acacia Avenue, Kololo, Kampala',
        notes: 'Three large bags of sorted plastic water bottles and milk jugs behind the gate.',
        estimatedCashAmount: 6.00,
        status: RequestStatus.pending,
        createdAt: now.subtract(const Duration(hours: 2)),
        scheduledPickupTime: now.add(const Duration(hours: 3)),
      ),
      WasteRequest(
        id: 'REQ-2026-102',
        userId: 'user_cit_02',
        userName: 'David Ochieng',
        userPhone: '+256 782 556677',
        photoPath: 'assets/sample_organic.jpg',
        categoryType: WasteCategoryType.organic,
        quantityBags: 2,
        latitude: 0.3382,
        longitude: 32.5715,
        address: 'Kisementi Shopping Center Lane, Kamwokya',
        notes: 'Vegetable waste from restaurant prep. Sealed bags.',
        estimatedCashAmount: 3.00,
        status: RequestStatus.assigned,
        assignedRiderId: AppUser.demoRider.id,
        assignedRiderName: AppUser.demoRider.name,
        createdAt: now.subtract(const Duration(hours: 4)),
        scheduledPickupTime: now.add(const Duration(hours: 1)),
      ),
      WasteRequest(
        id: 'REQ-2026-103',
        userId: AppUser.demoCitizen.id,
        userName: AppUser.demoCitizen.name,
        userPhone: AppUser.demoCitizen.phone,
        photoPath: 'assets/sample_ewaste.jpg',
        categoryType: WasteCategoryType.eWaste,
        quantityBags: 1,
        latitude: 0.3312,
        longitude: 32.5648,
        address: 'Makerere Hill Road, Near Main Gate',
        notes: 'Old printer and dead laptop batteries for recycling.',
        estimatedCashAmount: 4.00,
        status: RequestStatus.collected,
        assignedRiderId: AppUser.demoRider.id,
        assignedRiderName: AppUser.demoRider.name,
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
