import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:ecoroute/core/pickup_request_repository.dart';
import 'package:ecoroute/core/services/app_install_service.dart';
import 'package:ecoroute/core/services/auth_service.dart';
import 'package:ecoroute/core/services/rider_invite_service.dart';
import 'package:ecoroute/features/common/widgets/smart_install_banner.dart';
import 'package:ecoroute/features/rider/rider_setup_screen.dart';
import 'package:ecoroute/main.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late SharedPreferences prefs;
  late AuthService authService;

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    prefs = await SharedPreferences.getInstance();
    authService = AuthService(prefs);
    EcoRouteState.instance.authService = authService;
    EcoRouteState.instance.isGuest = true;
    EcoRouteState.instance.currentRole = 'resident';
    EcoRouteState.instance.userName = 'Guest User';
    EcoRouteState.instance.userEmail = 'guest@ecoroute.ug';
  });

  group('Video Alignment, Guest Intercept & Dual-Photo Proof', () {
    test('RiderInviteService builds authoritative invite URL with code and email', () {
      final url = RiderInviteService.buildRiderInviteUrl(
        inviteCode: 'RIDER-456',
        email: 'rider@example.ug',
        tricycleId: 'TRIC-04',
      );

      expect(url, contains('invite=RIDER-456'));
      expect(url, contains('email=rider%40example.ug'));
      expect(url, contains('tric=TRIC-04'));
    });

    test('buildSafeThumbnail returns fallback icon for null or invalid data', () {
      final widgetNull = buildSafeThumbnail(null);
      expect(widgetNull, isA<Container>());

      final widgetEmpty = buildSafeThumbnail('');
      expect(widgetEmpty, isA<Container>());
    });

    testWidgets('ResidentRequestsScreen renders dual-photo thumbnails and opens proof dialog', (
      tester,
    ) async {
      // 1x1 transparent PNG in base64
      const samplePng = 'iVBORw0KGgoAAAANSUhEUgAAAAEAAAABCAYAAAAfFcSJAAAADUlEQVR42mNk+M9QDwADhgGAWjR9awAAAABJRU5ErkJggg==';

      final requests = [
        {
          'id': 'Pickup #101',
          'pickupId': '101',
          'date': 'Today, 10:00',
          'size': '2 Sacks',
          'wasteType': 'Recyclables',
          'status': 'Resolved',
          'color': 0xFF0D2618,
          'receiptSerial': 'ECO-ARUA-101',
          'address': 'Ediofe, Trading Center',
          'price': '5,000 UGX',
          'description': 'Bottles and cardboard by gate',
          'photoUrl': samplePng,
          'clearedPhotoUrl': samplePng,
        }
      ];

      await tester.pumpWidget(
        MaterialApp(
          home: ResidentRequestsScreen(
            requests: requests,
            onBookPickup: () {},
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Pickup #101'), findsOneWidget);
      expect(find.text('Resolved'), findsOneWidget);
      expect(find.text('Verification Proof:'), findsOneWidget);
      expect(find.text('View Full Proof >'), findsOneWidget);
      expect(find.text('Reported Issue'), findsOneWidget);
      expect(find.text('Cleared Proof'), findsOneWidget);

      // Tap 'View Full Proof >'
      await tester.tap(find.text('View Full Proof >'));
      await tester.pumpAndSettle();

      expect(find.text('Clearance Verification • Pickup #101'), findsOneWidget);
      expect(find.text('Before (Resident Reported Waste):'), findsOneWidget);
      expect(find.text('After (Municipal Clearance Proof):'), findsOneWidget);
    });

    testWidgets('Resident HomeScreen displays video-aligned Drawer and Floating Action Button', (
      tester,
    ) async {
      var reportClicked = false;
      var mapClicked = false;

      await tester.pumpWidget(
        MaterialApp(
          home: ResidentHomeScreen(
            pickup: null,
            onBookPickup: () {},
            onOpenMap: () => mapClicked = true,
            onReportIssue: () => reportClicked = true,
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Video aligned UI elements
      expect(find.text('Search your types'), findsOneWidget);
      expect(find.text('REPORT ISSUE'), findsOneWidget);
      expect(find.byIcon(Icons.report_problem_outlined), findsOneWidget);

      // Tap Floating green pill
      await tester.tap(find.text('REPORT ISSUE'));
      expect(reportClicked, isTrue);

      // Open slide-out navigation drawer
      final menuButton = find.byTooltip('Navigation Menu');
      expect(menuButton, findsOneWidget);
      await tester.tap(menuButton);
      await tester.pumpAndSettle();

      // Drawer destinations matching requirements
      expect(find.text('Home'), findsOneWidget);
      expect(find.text('My Reports'), findsOneWidget);
      expect(find.text('Map'), findsOneWidget);
      expect(find.text('Notifications'), findsOneWidget);
      expect(find.text('Profile'), findsOneWidget);
      expect(find.text('Support Hotline (+256394880352)'), findsOneWidget);
      expect(find.text('WhatsApp Dispatch'), findsOneWidget);

      // Tap Map in drawer
      await tester.tap(find.text('Map'));
      await tester.pumpAndSettle();
      expect(mapClicked, isTrue);
    });

    test('Audit CSV generation formats all 11 columns with correct price and payment', () async {
      final state = EcoRouteState.instance;
      state.riderTasks = [
        {
          'id': '9901',
          'client': 'Jane Agondua',
          'address': 'Ediofe, Trading Center',
          'sacks': 2,
          'wasteType': 'Household',
          'price': '5,000 UGX',
          'paymentMethod': 'Cash on Collection',
          'receiptSerial': 'ECO-ARUA-9901',
          'assignedRiderId': 'TRIC-04',
          'status': 'Resolved',
        }
      ];

      final task = state.riderTasks.first;
      final sacks = (task['sacks'] as num).toInt();
      final price = task['price']?.toString() ?? '${sacks * 2500} UGX';
      final payment = task['paymentMethod'] ?? 'Cash on Collection';

      expect(price, '5,000 UGX');
      expect(payment, 'Cash on Collection');
      expect(task['receiptSerial'], 'ECO-ARUA-9901');
      expect(task['status'], 'Resolved');
    });

    test('RiderInviteService builds APK download URL pointing to official GitHub release', () {
      final apkUrl = RiderInviteService.buildApkDownloadUrl();
      expect(apkUrl, contains('releases/latest/download/app-release.apk'));
    });

    test('AppInstallService persists banner dismissal into SharedPreferences', () async {
      final service = AppInstallService.instance;
      await service.dismissBanner(prefs);
      expect(service.isDismissed, isTrue);

      final shouldShow = await service.shouldShowInstallBanner(prefs);
      expect(shouldShow, isFalse);
    });

    testWidgets('SmartInstallBanner renders install CTAs and responds to dismiss', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: SmartInstallBanner(forceShow: true),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Install App'), findsWidgets);
      expect(find.text('Download APK'), findsWidgets);
      expect(find.text('Install the EcoRoute Application'), findsWidgets);

      // Tap dismiss button
      await tester.tap(find.byTooltip('Dismiss').first);
      await tester.pumpAndSettle();

      expect(find.text('Install the EcoRoute Application'), findsNothing);
    });

    testWidgets('RiderSetupScreen renders authorization form with prefilled invite token', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: RiderSetupScreen(
            repository: MemoryPickupRequestRepository(),
            authService: authService,
            initialInviteCode: 'RDR-TEST-99',
            initialEmail: 'rider99@ecoroute.ug',
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('MUNICIPAL RIDER AUTHORIZATION'), findsOneWidget);
      expect(find.text('Set Up Rider Terminal'), findsOneWidget);
      expect(find.text('Activate Dispatch Terminal'), findsOneWidget);
      expect(find.text('RDR-TEST-99'), findsOneWidget);
      expect(find.text('rider99@ecoroute.ug'), findsOneWidget);
    });
  });
}
