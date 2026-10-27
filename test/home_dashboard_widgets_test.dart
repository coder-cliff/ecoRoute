import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:ecoroute/features/home/widgets/metric_cards.dart';

void main() {
  group('Dashboard Summary & Metric Cards Widgets', () {
    testWidgets('MetricCard displays label, value, and hint text', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: MetricCard(
              label: 'Total Collections',
              value: '142',
              hint: 'sacks collected',
            ),
          ),
        ),
      );

      expect(find.text('Total Collections'), findsOneWidget);
      expect(find.text('142'), findsOneWidget);
      expect(find.text('sacks collected'), findsOneWidget);
    });

    testWidgets('QuickActionCard responds to user tap', (
      WidgetTester tester,
    ) async {
      var tapped = false;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: QuickActionCard(
              icon: Icons.camera_alt,
              title: 'Scan Waste',
              subtitle: 'Capture photo of sack',
              accent: const Color(0xFF2EAD65),
              onTap: () => tapped = true,
            ),
          ),
        ),
      );

      expect(find.text('Scan Waste'), findsOneWidget);
      expect(find.text('Capture photo of sack'), findsOneWidget);

      await tester.tap(find.byType(QuickActionCard));
      expect(tapped, isTrue);
    });

    testWidgets('HomeSummaryCard renders title, subtitle, and primary value', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: HomeSummaryCard(
              title: 'Active Zone Routes',
              subtitle: 'Muni University & Arua Hill',
              value: '12 Trips',
              trailing: Icon(Icons.navigation, color: Colors.white),
            ),
          ),
        ),
      );

      expect(find.text('Active Zone Routes'), findsOneWidget);
      expect(find.text('Muni University & Arua Hill'), findsOneWidget);
      expect(find.text('12 Trips'), findsOneWidget);
      expect(find.byIcon(Icons.navigation), findsOneWidget);
    });

    testWidgets('WasteStatusListTile renders item status and fires onTap', (
      WidgetTester tester,
    ) async {
      var tapped = false;

      const item = WasteStatusItem(
        label: 'Collected Sacks',
        value: '4 Sacks',
        color: Color(0xFF2EAD65),
        icon: Icons.check_circle_outline,
        subtitle: 'Ready for recycling depot',
      );

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: WasteStatusListTile(
              item: item,
              onTap: () => tapped = true,
            ),
          ),
        ),
      );

      expect(find.text('Collected Sacks'), findsOneWidget);
      expect(find.text('4 Sacks'), findsOneWidget);
      expect(find.text('Ready for recycling depot'), findsOneWidget);

      await tester.tap(find.byType(WasteStatusListTile));
      expect(tapped, isTrue);
    });

    testWidgets('EcoRouteActionButton invokes callback on press', (
      WidgetTester tester,
    ) async {
      var pressed = false;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Row(
              children: [
                EcoRouteActionButton(
                  label: 'Instant Pickup Request',
                  icon: Icons.add_location_alt_outlined,
                  onPressed: () => pressed = true,
                ),
              ],
            ),
          ),
        ),
      );

      expect(find.text('Instant Pickup Request'), findsOneWidget);
      expect(find.byIcon(Icons.add_location_alt_outlined), findsOneWidget);

      await tester.tap(find.byType(EcoRouteActionButton));
      expect(pressed, isTrue);
    });

    testWidgets('RouteDetailCard renders pickup window and rider name', (
      WidgetTester tester,
    ) async {
      var tapped = false;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: RouteDetailCard(
              status: 'In Transit',
              riderName: 'Savior Deo',
              pickupWindow: '09:00 - 11:00 AM',
              onTap: () => tapped = true,
            ),
          ),
        ),
      );

      expect(find.text('In Transit'), findsOneWidget);
      expect(find.text('Rider: Savior Deo'), findsOneWidget);
      expect(find.text('Pickup window: 09:00 - 11:00 AM'), findsOneWidget);

      await tester.tap(find.byType(RouteDetailCard));
      expect(tapped, isTrue);
    });
  });
}
