import 'package:ecoroute/core/services/theme_service.dart';
import 'package:ecoroute/domain/entities/pickup_request.dart';
import 'package:ecoroute/domain/enums/request_status.dart';
import 'package:ecoroute/domain/enums/waste_type.dart';
import 'package:ecoroute/domain/enums/zone.dart';
import 'package:ecoroute/features/admin/widgets/admin_analytics_view.dart';
import 'package:ecoroute/features/admin/widgets/admin_settings_view.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('ThemeService (Dark Mode & Persistence)', () {
    test('initializes and switches theme modes correctly', () async {
      SharedPreferences.setMockInitialValues({'ecoroute_app_theme_mode_v1': 'dark'});
      final prefs = await SharedPreferences.getInstance();

      final service = ThemeService.instance;
      await service.init(prefs);
      expect(service.themeMode, ThemeMode.dark);
      expect(service.isDarkMode, isTrue);

      await service.setThemeMode(ThemeMode.light);
      expect(service.themeMode, ThemeMode.light);
      expect(service.isDarkMode, isFalse);

      await service.toggleTheme();
      expect(service.themeMode, ThemeMode.dark);
    });
  });

  group('AdminAnalyticsView (Business Intelligence Charts)', () {
    final sampleOrders = [
      PickupRequest(
        id: 'ord-1',
        wasteType: WasteType.household,
        description: 'House waste',
        submittedAt: DateTime(2026, 10, 20),
        status: RequestStatus.paid,
        sackCount: 3,
        priceUgx: 9000,
        zone: Zone.north,
      ),
      PickupRequest(
        id: 'ord-2',
        wasteType: WasteType.tradingCenter,
        description: 'Shop waste',
        submittedAt: DateTime(2026, 10, 21),
        status: RequestStatus.awaitingVerification,
        sackCount: 5,
        priceUgx: 15000,
        zone: Zone.south,
      ),
      PickupRequest(
        id: 'ord-3',
        wasteType: WasteType.unknown,
        description: 'Bulky wood',
        submittedAt: DateTime(2026, 10, 22),
        status: RequestStatus.requested,
        sackCount: 2,
        priceUgx: 6000,
        zone: Zone.east,
      ),
    ];

    testWidgets('renders executive KPI matrix and chart cards with valid metrics', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SingleChildScrollView(
              child: AdminAnalyticsView(orders: sampleOrders),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Settled Revenue'), findsOneWidget);
      expect(find.text('Pending Pipeline'), findsOneWidget);
      expect(find.text('Revenue Reconciliation (UGX)'), findsOneWidget);
      expect(find.text('Sack Collection Volume Trend'), findsOneWidget);
      expect(find.text('Waste Categories'), findsOneWidget);
      expect(find.text('Arua Municipal Zones'), findsOneWidget);
      expect(find.text('Order Status Lifecycle'), findsOneWidget);
      expect(find.text('Commercial B2B Accounts & Multi-Sack Revenue'), findsOneWidget);
    });

    testWidgets('renders commercial B2B breakdown with active accounts', (
      WidgetTester tester,
    ) async {
      final mixedOrders = [
        sampleOrders[0],
        sampleOrders[1].copyWith(
          isCommercial: true,
          businessName: 'Oasis 24/7 Restaurant',
          tinNumber: '100889922',
          serviceTier: 'Medium Commercial (Tier 2)',
          priceUgx: 12500,
          sackCount: 5,
        ),
      ];

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SingleChildScrollView(
              child: AdminAnalyticsView(orders: mixedOrders),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Commercial B2B Revenue'), findsOneWidget);
      expect(find.text('Oasis 24/7 Restaurant'), findsOneWidget);
      expect(find.text('Medium Commercial (Tier 2) • 5 sacks • TIN: 100889922'), findsOneWidget);
    });

    testWidgets('renders graceful empty state when no orders exist', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: AdminAnalyticsView(orders: []),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('No collection data recorded yet.'), findsOneWidget);
    });
  });

  group('AdminSettingsView (Tariffs, Zones & Theme Controls)', () {
    testWidgets('renders all operational settings sections and controls', (
      WidgetTester tester,
    ) async {
      var configuredGateway = false;
      var signedOut = false;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SingleChildScrollView(
              child: AdminSettingsView(
                onShowConfigureEmailGateway: () => configuredGateway = true,
                onSignOut: () => signedOut = true,
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Display & Appearance'), findsOneWidget);
      expect(find.text('Municipal Waste Tariffs (UGX)'), findsOneWidget);
      expect(find.text('Arua City Coverage Sectors'), findsOneWidget);
      expect(find.text('Safety & Dispatch Protocol'), findsOneWidget);
      expect(find.text('Cloud Gateway & Integrations'), findsOneWidget);

      // Verify actions
      await tester.ensureVisible(find.text('Configure'));
      await tester.tap(find.text('Configure'));
      expect(configuredGateway, isTrue);

      await tester.ensureVisible(find.text('Sign Out'));
      await tester.tap(find.text('Sign Out'));
      expect(signedOut, isTrue);
    });
  });
}
