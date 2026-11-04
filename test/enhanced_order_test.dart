import 'package:ecoroute/core/pickup_request_repository.dart';
import 'package:ecoroute/domain/entities/pickup_request.dart';
import 'package:ecoroute/domain/enums/request_status.dart';
import 'package:ecoroute/domain/enums/waste_type.dart';
import 'package:ecoroute/domain/enums/zone.dart';
import 'package:ecoroute/domain/rules/price_calculator.dart';
import 'package:ecoroute/features/request/order_page.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('Enhanced Order & Data Persistence (Weeks 5, 6, 7)', () {
    test('computes price dynamically for commercial vs household sacks', () {
      final householdTotal = calculateAmount(sackCount: 3, pricePerSackUgx: 1500);
      expect(householdTotal, 4500);

      final tradingCenterTotal = calculateAmount(sackCount: 4, pricePerSackUgx: 2500);
      expect(tradingCenterTotal, 10000);
    });

    test('persists and restores all extended pickup request fields in repository', () async {
      SharedPreferences.setMockInitialValues({});
      final preferences = await SharedPreferences.getInstance();
      final repo = SharedPreferencesPickupRequestRepository(preferences);

      final request = PickupRequest(
        id: 'ord-100',
        wasteType: WasteType.tradingCenter,
        description: 'Near Duka la Maduka, Arua Hill',
        submittedAt: DateTime(2026, 10, 22, 10, 30),
        status: RequestStatus.requested,
        sackCount: 5,
        priceUgx: 12500,
        isInstant: true,
        zone: Zone.east,
        address: 'Arua Hill Market, Stand 14',
        latitude: 3.0520,
        longitude: 30.9180,
        residentName: 'Kezia Candia',
        residentPhone: '+256 772 333 444',
        residentId: 'user-77',
      );

      await repo.save(request);

      final loaded = await repo.loadAll();
      expect(loaded.length, 1);

      final item = loaded.first;
      expect(item.id, 'ord-100');
      expect(item.wasteType, WasteType.tradingCenter);
      expect(item.sackCount, 5);
      expect(item.priceUgx, 12500);
      expect(item.isInstant, isTrue);
      expect(item.zone, Zone.east);
      expect(item.address, 'Arua Hill Market, Stand 14');
      expect(item.latitude, 3.0520);
      expect(item.longitude, 30.9180);
      expect(item.residentName, 'Kezia Candia');
      expect(item.residentPhone, '+256 772 333 444');
      expect(item.residentId, 'user-77');

      // Update status
      await repo.updateStatus('ord-100', RequestStatus.collected);
      final updatedList = await repo.loadAll();
      expect(updatedList.first.status, RequestStatus.collected);

      // Delete / Cancel
      await repo.delete('ord-100');
      final afterDelete = await repo.loadAll();
      expect(afterDelete, isEmpty);
    });

    test('persists isInstant flag for on-demand collection requests', () async {
      SharedPreferences.setMockInitialValues({});
      final preferences = await SharedPreferences.getInstance();
      final repo = SharedPreferencesPickupRequestRepository(preferences);

      final instantRequest = PickupRequest(
        id: 'ord-instant-01',
        wasteType: WasteType.household,
        description: 'Instant pickup: Plastic sacks ready',
        submittedAt: DateTime(2026, 10, 23, 12, 0),
        isInstant: true,
        address: 'Arua Central Lane 4',
      );

      await repo.save(instantRequest);
      final loaded = await repo.loadAll();
      expect(loaded.single.isInstant, isTrue);
      expect(loaded.single.address, 'Arua Central Lane 4');
    });

    testWidgets('OrderPage displays instant collection mode and has no zone dropdown', (
      WidgetTester tester,
    ) async {
      tester.view.physicalSize = const Size(1080, 2400);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() => tester.view.resetPhysicalSize());

      await tester.pumpWidget(
        MaterialApp(
          home: OrderPage(onSubmitted: (_) async {}),
        ),
      );
      await tester.pumpAndSettle();

      // Instant On-Demand Dispatch header
      expect(find.text('Instant On-Demand Collection'), findsOneWidget);
      expect(
        find.text(
          'Collections operate upon instant request across Arua municipality without zone delays.',
        ),
        findsOneWidget,
      );

      // Account Type Toggle
      expect(find.text('Residential / Household'), findsOneWidget);
      expect(find.text('Commercial B2B Bulk'), findsOneWidget);

      // Dedicated Instant pickup address input with GPS autofill
      expect(find.text('Instant pickup address / landmark'), findsOneWidget);

      // Verify NO zone dropdown is present
      expect(find.text('North Zone'), findsNothing);
      expect(find.text('South Zone'), findsNothing);
      expect(find.text('East Zone'), findsNothing);
      expect(find.text('West Zone'), findsNothing);
    });

    test('CommercialPricing computes accurate wholesale volume tiers and discounts', () {
      // Residential Standard: 1500 UGX
      expect(CommercialPricing.ratePerSack(sackCount: 2, isCommercial: false), 1500);
      expect(CommercialPricing.calculateTotal(sackCount: 2, isCommercial: false), 3000);
      expect(CommercialPricing.calculateVolumeDiscount(sackCount: 2, isCommercial: false), 0);

      // Commercial Tier 1 (1 - 4 sacks): 3000 UGX / sack
      expect(CommercialPricing.ratePerSack(sackCount: 3, isCommercial: true), 3000);
      expect(CommercialPricing.calculateTotal(sackCount: 3, isCommercial: true), 9000);
      expect(CommercialPricing.calculateVolumeDiscount(sackCount: 3, isCommercial: true), 0);
      expect(CommercialPricing.getTierTitle(sackCount: 3, isCommercial: true), 'Small Enterprise (Tier 1)');

      // Commercial Tier 2 (5 - 14 sacks): 2500 UGX / sack
      expect(CommercialPricing.ratePerSack(sackCount: 10, isCommercial: true), 2500);
      expect(CommercialPricing.calculateTotal(sackCount: 10, isCommercial: true), 25000);
      // Saved 500 UGX * 10 = 5000 UGX
      expect(CommercialPricing.calculateVolumeDiscount(sackCount: 10, isCommercial: true), 5000);
      expect(CommercialPricing.getTierTitle(sackCount: 10, isCommercial: true), 'Medium Commercial (Tier 2)');

      // Commercial Tier 3 (15 - 29 sacks): 2000 UGX / sack (Full Tricycle)
      expect(CommercialPricing.ratePerSack(sackCount: 15, isCommercial: true), 2000);
      expect(CommercialPricing.calculateTotal(sackCount: 15, isCommercial: true), 30000);
      // Saved 1000 UGX * 15 = 15000 UGX
      expect(CommercialPricing.calculateVolumeDiscount(sackCount: 15, isCommercial: true), 15000);
      expect(CommercialPricing.getTierTitle(sackCount: 15, isCommercial: true), 'Full Tricycle / Hospitality (Tier 3)');

      // Commercial Tier 4 (30 - 50 sacks): 1800 UGX / sack (Bulk Market / Institutional)
      expect(CommercialPricing.ratePerSack(sackCount: 30, isCommercial: true), 1800);
      expect(CommercialPricing.calculateTotal(sackCount: 30, isCommercial: true), 54000);
      // Saved 1200 UGX * 30 = 36000 UGX
      expect(CommercialPricing.calculateVolumeDiscount(sackCount: 30, isCommercial: true), 36000);
      expect(CommercialPricing.getTierTitle(sackCount: 30, isCommercial: true), 'Bulk Market / Institutional (Tier 4)');
    });

    testWidgets('OrderPage switches to Commercial B2B Bulk mode and shows entity inputs', (
      WidgetTester tester,
    ) async {
      tester.view.physicalSize = const Size(1080, 2400);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() => tester.view.resetPhysicalSize());

      await tester.pumpWidget(
        MaterialApp(
          home: OrderPage(onSubmitted: (_) async {}),
        ),
      );
      await tester.pumpAndSettle();

      // Tap Commercial B2B Bulk toggle
      await tester.tap(find.text('Commercial B2B Bulk'));
      await tester.pumpAndSettle();

      // Commercial details should be rendered
      expect(find.text('Commercial Entity Details'), findsOneWidget);
      expect(find.text('Business / Enterprise Name *'), findsOneWidget);
      expect(find.text('Tax Identification Number (TIN - Optional)'), findsOneWidget);
      expect(find.text('15 (Full Tricycle)'), findsOneWidget);
    });
  });
}
