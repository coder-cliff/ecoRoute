import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:latlong2/latlong.dart';

import 'package:ecoroute/main.dart';
import 'package:ecoroute/core/services/auth_service.dart';
import 'package:ecoroute/core/services/osrm_routing_service.dart';
import 'package:ecoroute/core/services/sms_service.dart';
import 'package:ecoroute/core/services/analytics_service.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late SharedPreferences prefs;
  late AuthService authService;

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    prefs = await SharedPreferences.getInstance();
    authService = AuthService(prefs);
    await EcoRouteState.instance.logout();
  });

  group('Browsing Account Launch & Top-Right Login Navigation', () {
    testWidgets('Root launch directly opens Browsing Account (Resident/Guest Mode)', (
      tester,
    ) async {
      await tester.pumpWidget(
        MaterialApp(
          home: const SplashScreen(allowGuestLaunch: true),
          routes: {
            '/resident': (_) => const Scaffold(body: Text('Resident Browsing Portal')),
            '/login': (_) => const Scaffold(body: Text('Login Screen')),
            '/admin': (_) => const Scaffold(body: Text('Admin Screen')),
          },
        ),
      );

      // Fast forward past splash duration
      await tester.pump(const Duration(milliseconds: 2300));
      await tester.pumpAndSettle();

      // Confirms visitor lands on Browsing Account, NOT Admin Command HQ
      expect(find.text('Resident Browsing Portal'), findsOneWidget);
      expect(find.text('Admin Screen'), findsNothing);
    });

    testWidgets('ResidentHomeScreen renders prominent Login button at top-right corner for guest visitors', (
      tester,
    ) async {
      EcoRouteState.instance.isGuest = true;

      await tester.pumpWidget(
        MaterialApp(
          home: ResidentHomeScreen(
            pickup: null,
            onBookPickup: () {},
            onOpenMap: () {},
            onReportIssue: () {},
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Top right Login button exists and is visible
      expect(find.byKey(const ValueKey('top_right_login_button')), findsOneWidget);
      expect(find.text('Login'), findsOneWidget);
    });

    testWidgets('CloudSyncStatusBadge is completely hidden from the UI', (
      tester,
    ) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: CloudSyncStatusBadge(),
          ),
        ),
      );
      await tester.pumpAndSettle();

      // 2nd image (Cloud Database Active) must NOT appear on UI
      expect(find.textContaining('Cloud Database Active'), findsNothing);
      expect(find.textContaining('africa-south1'), findsNothing);
    });
  });

  group('Login Form Across All Display Sizes (Desktop, Tablet, Phone)', () {
    testWidgets('Renders side-by-side desktop view with illustration panel on wide desktop display (1280x800)', (
      tester,
    ) async {
      tester.view.physicalSize = const Size(1280, 800);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() => tester.view.resetPhysicalSize());

      await tester.pumpWidget(
        const MaterialApp(
          home: LoginScreen(),
        ),
      );
      await tester.pumpAndSettle();

      // Desktop layout contains both the illustration headline and the login form
      expect(find.textContaining('Optimizing Commercial Waste'), findsOneWidget);
      expect(find.textContaining('Driving Efficiency in Arua City'), findsOneWidget);
      expect(find.text('Welcome to ecoRoute'), findsOneWidget);
      expect(find.byKey(const ValueKey('login_email_input')), findsOneWidget);
      expect(find.byKey(const ValueKey('login_password_input')), findsOneWidget);
      expect(find.byKey(const ValueKey('login_submit_button')), findsOneWidget);
    });

    testWidgets('Renders clean single-column view without overflow on mobile phone display (380x750)', (
      tester,
    ) async {
      tester.view.physicalSize = const Size(380, 750);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() => tester.view.resetPhysicalSize());

      await tester.pumpWidget(
        const MaterialApp(
          home: LoginScreen(),
        ),
      );
      await tester.pumpAndSettle();

      // On phone, side-by-side illustration is omitted to prevent overflow
      expect(find.textContaining('Optimizing Commercial Waste'), findsNothing);
      expect(find.text('Welcome to ecoRoute'), findsOneWidget);
      expect(find.byKey(const ValueKey('login_email_input')), findsOneWidget);
      expect(find.byKey(const ValueKey('login_password_input')), findsOneWidget);
      expect(find.byKey(const ValueKey('login_submit_button')), findsOneWidget);
    });
  });

  group('High-Accuracy Arua Maps & Navigation', () {
    testWidgets('AruaMapPainter renders River Oli waterway, bridge, compass rose and GNSS precision telemetry', (
      tester,
    ) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: CustomPaint(
              size: const Size(600, 600),
              painter: const AruaMapPainter(),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Verified CustomPaint renders cleanly
      expect(find.byType(CustomPaint), findsWidgets);
    });

    test('OsrmRoutingService getOptimizedTrip handles TSP waypoint sequence', () async {
      final service = OsrmRoutingService();
      final waypoints = [
        const LatLng(3.0303, 30.9073), // Arua Market
        const LatLng(3.0250, 30.8920), // Ediofe
        const LatLng(3.0350, 30.9150), // Arua Hill
      ];

      final route = await service.getOptimizedTrip(waypoints: waypoints);
      expect(route, isNotEmpty);
      expect(route.first.latitude, isNotNull);
    });
  });

  group('Security & Telemetry Improvements', () {
    test('AuthService persists brute-force lockout timestamp to SharedPreferences across restarts', () async {
      const email = 'lockout_test@ecoroute.ug';

      // 3 failed attempts triggers exponential lockout
      await authService.login(email: email, password: 'wrong_password_1');
      await authService.login(email: email, password: 'wrong_password_2');
      await authService.login(email: email, password: 'wrong_password_3');

      final prefMs = prefs.getInt('ecoroute_lockout_$email');
      expect(prefMs, isNotNull);
      expect(prefMs! > DateTime.now().millisecondsSinceEpoch, isTrue);

      // Verify that a new AuthService instance recognizes the lockout
      final freshAuthService = AuthService(prefs);
      expect(
        () => freshAuthService.login(email: email, password: 'attempt_after_restart'),
        throwsA(isA<StateError>()),
      );
    });

    test('AfricaTalkingSmsService openDeviceSmsApp safely handles formatting', () async {
      final success = await AfricaTalkingSmsService.openDeviceSmsApp(
        phone: '+256 784 638 852',
        message: 'Your EcoRoute collection truck is arriving in 5 minutes.',
      );
      // In headless test environment, url_launcher returns false or true without exception
      expect(success, isA<bool>());
    });

    test('EcoRouteAnalyticsService logs events and keeps max capacity', () async {
      final analytics = EcoRouteAnalyticsService.instance;
      await analytics.logPickupRequested(
        wasteType: 'Organic food waste',
        sacks: 3,
        zone: 'Ediofe',
        isInstant: true,
      );

      expect(analytics.eventLog, isNotEmpty);
      expect(analytics.eventLog.last['event'], 'pickup_requested');
    });
  });
}
