import 'package:flutter_test/flutter_test.dart';
import 'package:ecoroute/models/waste_category.dart';
import 'package:ecoroute/models/waste_request.dart';
import 'package:ecoroute/services/api_service.dart';
import 'package:ecoroute/services/location_service.dart';

void main() {
  group('Waste Category & Pricing Tests', () {
    test('Plastics category calculates price and carbon reduction accurately', () {
      final plastic = WasteCategory.getByType(WasteCategoryType.plastics);
      expect(plastic.pricePerUnit, equals(2.00));
      expect(plastic.carbonSavedPerUnitKg, equals(1.8));

      // 4 bags of plastic
      final totalCash = plastic.pricePerUnit * 4;
      final totalCarbon = plastic.carbonSavedPerUnitKg * 4;
      expect(totalCash, equals(8.00));
      expect(totalCarbon, closeTo(7.2, 0.01));
    });

    test('E-Waste category has highest carbon mitigation per unit', () {
      final eWaste = WasteCategory.getByType(WasteCategoryType.eWaste);
      expect(eWaste.pricePerUnit, equals(4.00));
      expect(eWaste.carbonSavedPerUnitKg, equals(5.0));
    });
  });

  group('WasteRequest Serialization & Persistence Tests (Week 7)', () {
    test('WasteRequest correctly serializes to JSON and deserializes back', () {
      final now = DateTime.now();
      final request = WasteRequest(
        id: 'REQ-TEST-001',
        userId: 'user_123',
        userName: 'Test Citizen',
        userPhone: '+256 700 000000',
        photoPath: 'simulated_sample_plastics',
        categoryType: WasteCategoryType.plastics,
        quantityBags: 3,
        latitude: 0.3340,
        longitude: 32.5686,
        address: 'Kololo Hill Drive, Kampala',
        notes: 'Gate 4, bags on the left',
        estimatedCashAmount: 6.00,
        status: RequestStatus.pending,
        createdAt: now,
        scheduledPickupTime: now.add(const Duration(hours: 2)),
      );

      final json = request.toJson();
      expect(json['id'], equals('REQ-TEST-001'));
      expect(json['categoryType'], equals('plastics'));
      expect(json['estimatedCashAmount'], equals(6.00));
      expect(json['status'], equals('pending'));

      final restored = WasteRequest.fromJson(json);
      expect(restored.id, equals(request.id));
      expect(restored.userName, equals(request.userName));
      expect(restored.categoryType, equals(request.categoryType));
      expect(restored.quantityBags, equals(request.quantityBags));
      expect(restored.estimatedCashAmount, equals(request.estimatedCashAmount));
      expect(restored.isCashCollected, isFalse);
    });

    test('WasteRequest copyWith transitions status and confirms cash collection', () {
      final now = DateTime.now();
      final request = WasteRequest(
        id: 'REQ-TEST-002',
        userId: 'user_123',
        userName: 'Test Citizen',
        userPhone: '+256 700 000000',
        photoPath: 'simulated_sample_organic',
        categoryType: WasteCategoryType.organic,
        quantityBags: 2,
        latitude: 0.3340,
        longitude: 32.5686,
        address: 'Makerere University',
        notes: '',
        estimatedCashAmount: 3.00,
        status: RequestStatus.pending,
        createdAt: now,
        scheduledPickupTime: now.add(const Duration(hours: 1)),
      );

      // Rider Assigned
      final assigned = request.copyWith(
        status: RequestStatus.assigned,
        assignedRiderId: 'rider_01',
        assignedRiderName: 'Alex Mukasa',
      );
      expect(assigned.status, equals(RequestStatus.assigned));
      expect(assigned.assignedRiderName, equals('Alex Mukasa'));

      // Cash Collected & Picked Up
      final collected = assigned.copyWith(
        status: RequestStatus.collected,
        isCashCollected: true,
        actualCashPaid: 3.00,
        receiptNumber: 'RCP-99881',
      );
      expect(collected.status, equals(RequestStatus.collected));
      expect(collected.isCashCollected, isTrue);
      expect(collected.actualCashPaid, equals(3.00));
      expect(collected.receiptNumber, equals('RCP-99881'));
    });
  });

  group('Eco-Impact Analytics & Distance Calculations (Week 9 & 11)', () {
    test('ApiService calculates trees equivalent and landfill volume', () {
      final result = ApiService.calculateEcoImpact(
        totalCarbonSavedKg: 44.0, // 44 kg / 22 kg = 2.0 trees
        totalBags: 10,           // 10 * 0.05 = 0.50 m3
      );

      expect(result['treesEquivalent'], equals('2.0'));
      expect(result['landfillVolumeM3'], equals('0.50'));
    });

    test('LocationService calculates distance in km between two GPS points', () {
      // Distance between Makerere and Kololo (~3-4 km)
      final dist = LocationService.calculateDistanceKm(0.3340, 32.5686, 0.3382, 0.5715);
      expect(dist, isPositive);
    });
  });
}
