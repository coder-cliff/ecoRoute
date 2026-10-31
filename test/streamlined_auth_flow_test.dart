import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:ecoroute/core/pickup_request_repository.dart';
import 'package:ecoroute/core/services/auth_service.dart';
import 'package:ecoroute/domain/enums/role.dart';
import 'package:ecoroute/features/admin/admin_dashboard.dart';
import 'package:ecoroute/features/auth/login_screen.dart';
import 'package:ecoroute/features/home/home_screen.dart';
import 'package:ecoroute/features/rider/rider_task_hub.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late SharedPreferences prefs;
  late AuthService authService;
  late PickupRequestRepository repository;

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    prefs = await SharedPreferences.getInstance();
    authService = AuthService(prefs);
    repository = const MemoryPickupRequestRepository();
  });

  group('Streamlined Auth & Launch Flow', () {
    testWidgets('SplashScreen renders Rich Sage surface and twin leaf logo', (
      tester,
    ) async {
      await tester.pumpWidget(
        MaterialApp(
          home: SplashScreen(
            repository: repository,
            authService: authService,
            splashDuration: const Duration(seconds: 10), // keep on screen
          ),
        ),
      );

      expect(find.byType(EcoRouteLeafLogo), findsOneWidget);
      expect(find.text('EcoRoute'), findsOneWidget);

      final scaffold = tester.widget<Scaffold>(find.byType(Scaffold));
      expect(scaffold.backgroundColor, const Color(0xFFE8ECE7));
    });

    testWidgets('Unauthenticated launch routes from Splash to LoginScreen', (
      tester,
    ) async {
      await tester.pumpWidget(
        MaterialApp(
          home: SplashScreen(
            repository: repository,
            authService: authService,
            splashDuration: const Duration(milliseconds: 200),
          ),
        ),
      );

      await tester.pump(const Duration(milliseconds: 300));
      await tester.pumpAndSettle();

      expect(find.byType(LoginScreen), findsOneWidget);
      expect(find.text('Sign In'), findsNWidgets(2));
      expect(find.byKey(const ValueKey('login_email_input')), findsOneWidget);
      expect(find.byKey(const ValueKey('login_password_input')), findsOneWidget);
      expect(find.byKey(const ValueKey('login_submit_button')), findsOneWidget);
    });

    testWidgets('Authenticated Resident session automatically routes to HomeScreen', (
      tester,
    ) async {
      await authService.register(
        fullName: 'Jane Resident',
        email: 'resident.jane@example.ug',
        phone: '+256701111222',
        password: 'Password123!',
        role: AppRole.resident,
      );

      await tester.pumpWidget(
        MaterialApp(
          home: SplashScreen(
            repository: repository,
            authService: authService,
            splashDuration: const Duration(milliseconds: 200),
          ),
        ),
      );

      await tester.pump(const Duration(milliseconds: 300));
      await tester.pumpAndSettle();

      expect(find.byType(HomeScreen), findsOneWidget);
      expect(find.text('Arua waste pickup'), findsOneWidget);
    });

    testWidgets('Authenticated Rider session automatically routes to RiderTaskHub', (
      tester,
    ) async {
      // Invite rider and register
      final code = await authService.inviteRider(
        email: 'rider.pro@ecoroute.ug',
        fullName: 'Peter Rider',
        phone: '+256702222333',
      );
      await authService.register(
        fullName: 'Peter Rider',
        email: 'rider.pro@ecoroute.ug',
        phone: '+256702222333',
        password: 'Password123!',
        inviteCode: code,
      );

      await tester.pumpWidget(
        MaterialApp(
          home: SplashScreen(
            repository: repository,
            authService: authService,
            splashDuration: const Duration(milliseconds: 200),
          ),
        ),
      );

      await tester.pump(const Duration(milliseconds: 300));
      await tester.pumpAndSettle();

      expect(find.byType(RiderTaskHub), findsOneWidget);
    });

    testWidgets('Authenticated Admin session automatically routes to AdminDashboard', (
      tester,
    ) async {
      await authService.login(
        email: 'saviordeogratius@yahoo.com',
        password: 'OfficialAdmin@2026',
      );

      await tester.pumpWidget(
        MaterialApp(
          home: SplashScreen(
            repository: repository,
            authService: authService,
            splashDuration: const Duration(milliseconds: 200),
          ),
        ),
      );

      await tester.pump(const Duration(milliseconds: 300));
      await tester.pumpAndSettle();

      expect(find.byType(AdminDashboard), findsOneWidget);
    });

    testWidgets('LoginScreen signs in Admin and automatically routes to AdminDashboard', (
      tester,
    ) async {
      await tester.pumpWidget(
        MaterialApp(
          home: LoginScreen(
            repository: repository,
            authService: authService,
          ),
        ),
      );

      await tester.enterText(
        find.byKey(const ValueKey('login_email_input')),
        'saviordeogratius@yahoo.com',
      );
      await tester.enterText(
        find.byKey(const ValueKey('login_password_input')),
        'OfficialAdmin@2026',
      );
      await tester.tap(find.byKey(const ValueKey('login_submit_button')));
      await tester.pumpAndSettle();

      // Automatically routes without manual role selection
      expect(find.byType(AdminDashboard), findsOneWidget);
    });

    testWidgets('Sign out from role view automatically returns to LoginScreen', (
      tester,
    ) async {
      await authService.login(
        email: 'saviordeogratius@yahoo.com',
        password: 'OfficialAdmin@2026',
      );

      await tester.pumpWidget(
        MaterialApp(
          home: AdminDashboard(
            repository: repository,
            authService: authService,
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Open profile
      await tester.ensureVisible(find.text('Profile'));
      await tester.tap(find.text('Profile'));
      await tester.pumpAndSettle();

      // Tap Sign out
      await tester.ensureVisible(find.text('Sign out'));
      await tester.tap(find.text('Sign out'));
      await tester.pumpAndSettle();

      expect(find.byType(LoginScreen), findsOneWidget);
      expect(find.text('Sign In'), findsNWidgets(2));
      expect(authService.getCurrentUser(), isNull);
    });
  });
}
