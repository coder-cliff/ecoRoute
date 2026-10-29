import 'package:ecoroute/domain/entities/pickup_request.dart';
import 'package:ecoroute/domain/enums/request_status.dart';
import 'package:ecoroute/domain/enums/waste_type.dart';
import 'package:ecoroute/domain/enums/zone.dart';
import 'package:ecoroute/features/rider/widgets/active_trip_sheet.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  final sampleStops = [
    PickupRequest(
      id: 'stop-1',
      wasteType: WasteType.household,
      description: 'Green gate, Adumi Road',
      submittedAt: DateTime(2026, 10, 20),
      status: RequestStatus.requested,
      sackCount: 2,
      priceUgx: 6000,
      zone: Zone.north,
      residentName: 'Ayiko Gift',
      residentPhone: '+256 774 224 467',
      address: 'Adumi Road near church',
    ),
    PickupRequest(
      id: 'stop-2',
      wasteType: WasteType.tradingCenter,
      description: 'Market shop, Oli division',
      submittedAt: DateTime(2026, 10, 21),
      status: RequestStatus.collected,
      sackCount: 4,
      priceUgx: 12000,
      zone: Zone.south,
      residentName: 'Draleru Sarah',
      residentPhone: '+256 782 111 222',
      address: 'Oli Trading Center',
    ),
  ];

  group('Rider Active Trip (Option B & On-Site Adjustments)', () {
    testWidgets('ActiveTripBanner renders docked trip summary and responds to tap', (
      WidgetTester tester,
    ) async {
      var tapped = false;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: ActiveTripBanner(
              activeStop: sampleStops[0],
              totalStops: 2,
              currentIndex: 1,
              onTap: () => tapped = true,
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Stop 1 of 2'), findsOneWidget);
      expect(find.text('En Route to Resident'), findsOneWidget);
      expect(find.text('Ayiko Gift • Adumi Road near church'), findsOneWidget);

      await tester.tap(find.byType(ActiveTripBanner));
      expect(tapped, isTrue);
    });

    testWidgets('ActiveTripSheet renders multi-stop sequence, contact shortcuts, and allows on-site sack count adjustment', (
      WidgetTester tester,
    ) async {
      PickupRequest? advancedRequest;
      RequestStatus? advancedStatus;
      int? updatedSackCount;
      int? updatedPrice;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: ActiveTripSheet(
              stops: sampleStops,
              initialIndex: 0,
              onAdvanceOrder: (req, status) async {
                advancedRequest = req;
                advancedStatus = status;
              },
              onUpdateSackCount: (req, count, price) async {
                updatedSackCount = count;
                updatedPrice = price;
              },
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Check header and multi-stop sequence
      expect(find.text('Active Route Dispatch Console'), findsOneWidget);
      expect(find.text('Stop 1'), findsOneWidget);
      expect(find.text('Stop 2'), findsOneWidget);
      expect(find.text('Ayiko Gift'), findsOneWidget);
      expect(find.text('Adumi Road near church'), findsOneWidget);
      expect(find.text('2 sacks'), findsOneWidget);

      // Verify incrementing sack count
      await tester.tap(find.byIcon(Icons.add_rounded));
      await tester.pumpAndSettle();
      expect(updatedSackCount, 3);
      expect(updatedPrice, 9000);

      // Verify advancing order
      final btn = find.widgetWithText(FilledButton, 'Confirm Sacks Loaded & Depart');
      await tester.scrollUntilVisible(btn, 300.0, scrollable: find.byType(Scrollable).first);
      await tester.pumpAndSettle();
      await tester.tap(btn);
      await tester.pumpAndSettle();
      expect(advancedRequest?.id, 'stop-1');
      expect(advancedStatus, RequestStatus.collected);
    });
  });
}
