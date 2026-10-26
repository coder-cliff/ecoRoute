import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:ecoroute/core/pickup_request_repository.dart';
import 'package:ecoroute/core/services/waste_database_service.dart';
import 'package:ecoroute/domain/enums/zone.dart';
import 'package:ecoroute/features/database/waste_database_sheet.dart';
import 'package:ecoroute/features/home/home_screen.dart';
import 'package:ecoroute/features/request/order_page.dart';
import 'package:ecoroute/features/request/widgets/waste_camera_scanner.dart';

void main() {
  group('WasteDatabaseService (Open Solid Waste & Recycling Taxonomy)', () {
    const service = WasteDatabaseService();

    test('retrieves World Bank & NEMA Uganda municipal benchmarks', () {
      final benchmark = service.getAruaBenchmarks();
      expect(benchmark.dailyPerCapitaKg, 0.44);
      expect(benchmark.totalDailyTonnage, 125.0);
      expect(benchmark.organicPercentage, 68.2);
      expect(benchmark.recyclablePotentialPercentage, 86.0);
      expect(benchmark.currentCollectionCoverage, 42.5);
    });

    test('searches materials by English and Lugbara names', () {
      final plasticQuery = service.searchMaterials('plastic');
      expect(plasticQuery.isNotEmpty, isTrue);
      expect(plasticQuery.any((m) => m.name.contains('PET')), isTrue);

      final lugbaraQuery = service.searchMaterials('kopo');
      expect(lugbaraQuery.isNotEmpty, isTrue);

      final lugbaraOrganic = service.searchMaterials('agbi');
      expect(lugbaraOrganic.isNotEmpty, isTrue);
    });

    test('calculates estimated recycling revenue in UGX', () {
      final value = service.estimateRecycleValue(
        materialId: 'mat-pet',
        weightKg: 10.0,
      );
      // 10 kg * 800 UGX = 8,000 UGX
      expect(value, 8000);
    });

    test('retrieves certified Arua municipal facilities by zone', () {
      final northFacilities = service.getFacilitiesByZone(Zone.north);
      expect(northFacilities.isNotEmpty, isTrue);
      expect(northFacilities.any((f) => f.name.contains('Arua Central')), isTrue);

      final southFacilities = service.getFacilitiesByZone(Zone.south);
      expect(southFacilities.isNotEmpty, isTrue);
      expect(southFacilities.any((f) => f.name.contains('Muni University')), isTrue);
    });
  });

  group('WasteDatabaseSheet Widget', () {
    testWidgets('renders search field, benchmark ticker, and category chips', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: WasteDatabaseSheet(),
          ),
        ),
      );

      expect(find.text('Arua Waste & Recycling Database'), findsOneWidget);
      expect(find.text('Search materials, Lugbara names, or codes...'), findsOneWidget);
      expect(find.textContaining('World Bank / NEMA Municipal Data'), findsOneWidget);
      expect(find.text('All'), findsOneWidget);
      expect(find.text('Plastics'), findsOneWidget);
      expect(find.text('Organic'), findsOneWidget);
    });

    testWidgets('filters materials when typing in search field', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: WasteDatabaseSheet(),
          ),
        ),
      );

      await tester.enterText(
        find.byType(TextField),
        'Battery',
      );
      await tester.pumpAndSettle();

      expect(find.text('Dry-Cell Radio & Solar Batteries'), findsOneWidget);
      expect(find.text('PET Beverage Bottles'), findsNothing);
    });

    testWidgets('tapping a material shows the sorting and recycling details dialog', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: WasteDatabaseSheet(),
          ),
        ),
      );

      await tester.ensureVisible(find.text('PET Beverage Bottles'));
      await tester.tap(find.text('PET Beverage Bottles'));
      await tester.pumpAndSettle();

      expect(find.text('Decomposition & Value Breakdown'), findsOneWidget);
      expect(find.text('Lugbara: Kopo kopo kabi kabi'), findsOneWidget);
      expect(find.text('Sorting instructions:'), findsOneWidget);
      expect(find.text('Certified Arua Municipal Hubs:'), findsOneWidget);

      await tester.tap(find.text('Close'));
      await tester.pumpAndSettle();
      expect(find.text('Decomposition & Value Breakdown'), findsNothing);
    });
  });

  group('EcoRouteHomeScreen Waste Database & Auto-Scan Integration', () {
    testWidgets('displays auto-scan and database buttons on dashboard', (
      WidgetTester tester,
    ) async {
      const repository = MemoryPickupRequestRepository();

      await tester.pumpWidget(
        const MaterialApp(
          home: EcoRouteHomeScreen(repository: repository),
        ),
      );
      await tester.pumpAndSettle();

      // Quick action cards
      expect(find.text('Take rubbish photo'), findsOneWidget);
      expect(find.text('Waste database'), findsOneWidget);

      // Report section buttons
      await tester.ensureVisible(find.text('REPORT AN ISSUE'));
      expect(find.text('TAKE RUBBISH PHOTO (CAMERA)'), findsOneWidget);
      expect(find.text('REPORT AN ISSUE'), findsOneWidget);
      expect(find.text('Municipal Waste & Recycling Database'), findsOneWidget);

      // Tap database banner to open WasteDatabaseSheet
      await tester.tap(find.text('Municipal Waste & Recycling Database'));
      await tester.pumpAndSettle();

      expect(find.text('Arua Waste & Recycling Database'), findsOneWidget);
    });
  });

  group('Auto-Trigger Camera in OrderPage', () {
    testWidgets('launches WasteCameraScanner when autoTriggerCamera is true', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(
        MaterialApp(
          home: OrderPage(
            onSubmitted: (_) async {},
            autoTriggerCamera: true,
          ),
        ),
      );
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));

      expect(find.byType(WasteCameraScanner), findsOneWidget);
      expect(find.text('Rubbish Photo Capture'), findsOneWidget);
    });
  });
}
