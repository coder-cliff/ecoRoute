import 'package:flutter_test/flutter_test.dart';
import 'package:ecoroute/models/waste_category.dart';
import 'package:ecoroute/models/waste_guide_item.dart';
import 'package:ecoroute/models/waste_request.dart';
import 'package:ecoroute/providers/waste_request_provider.dart';

void main() {
  group('Standardization & Municipal Guide Tests', () {
    test('Municipal Waste Sorting Catalog contains items across all categories', () {
      final catalog = WasteGuideItem.municipalCatalog;
      expect(catalog.isNotEmpty, isTrue);

      final categoriesInCatalog = catalog.map((i) => i.category).toSet();
      expect(categoriesInCatalog.contains(WasteCategoryType.plastics), isTrue);
      expect(categoriesInCatalog.contains(WasteCategoryType.organic), isTrue);
      expect(categoriesInCatalog.contains(WasteCategoryType.paper), isTrue);
      expect(categoriesInCatalog.contains(WasteCategoryType.metal), isTrue);
      expect(categoriesInCatalog.contains(WasteCategoryType.eWaste), isTrue);
      expect(categoriesInCatalog.contains(WasteCategoryType.hazardous), isTrue);
    });

    test('WasteVolumeSize multipliers scale accurately', () {
      expect(WasteVolumeSize.small.multiplier, equals(1.0));
      expect(WasteVolumeSize.medium.multiplier, equals(1.8));
      expect(WasteVolumeSize.large.multiplier, equals(3.2));

      expect(WasteVolumeSize.small.label, contains('Small'));
      expect(WasteVolumeSize.medium.label, contains('Medium'));
      expect(WasteVolumeSize.large.label, contains('Large'));
    });

    test('Scientific impact formulas calculate weight and trees accurately', () {
      final now = DateTime.now();
      final request = WasteRequest(
        id: 'REQ-SCI-01',
        userId: 'usr_01',
        userName: 'Citizen Test',
        userPhone: '+256 772 000000',
        photoPath: 'test_path',
        categoryType: WasteCategoryType.plastics,
        quantityBags: 4,
        volumeSize: WasteVolumeSize.medium, // Multiplier 1.8
        latitude: 0.33,
        longitude: 32.57,
        address: 'Acacia Ave',
        notes: '',
        estimatedCashAmount: 14.40,
        status: RequestStatus.collected,
        createdAt: now,
        scheduledPickupTime: now,
      );

      // Plastics carbon: 1.8 * 4 * 1.8 = 12.96 kg CO2e
      expect(request.totalCarbonSavedKg, closeTo(12.96, 0.01));

      // Plastics weight: 2.5 * 4 * 1.8 = 18.0 kg waste diverted
      expect(request.totalDivertedWeightKg, closeTo(18.0, 0.01));

      // Trees: 12.96 / 22 = 0.589 trees/yr
      expect(request.treesSavedEquivalent, closeTo(0.589, 0.01));
    });

    test('CSV export generates valid municipal audit headers and rows', () {
      final provider = WasteRequestProvider();
      final csv = provider.exportMunicipalCsvReport();

      expect(csv, contains('Request_ID,Citizen_Name,Phone,Category,Volume_Size,Quantity,Status'));
    });
  });
}
