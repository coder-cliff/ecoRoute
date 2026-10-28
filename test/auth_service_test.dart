import 'package:ecoroute/core/services/auth_service.dart';
import 'package:ecoroute/domain/enums/role.dart';
import 'package:ecoroute/features/auth/auth_sheet.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('AuthService (Week 10 Authentication & Cloud Data)', () {
    late SharedPreferences preferences;
    late AuthService authService;

    setUp(() async {
      SharedPreferences.setMockInitialValues({});
      preferences = await SharedPreferences.getInstance();
      authService = AuthService(preferences);
    });

    test('logs in built-in admin accounts successfully', () async {
      final admin1 = await authService.login(
        email: 'saviordeogratius@yahoo.com',
        password: 'OfficialAdmin@2026',
      );

      expect(admin1, isNotNull);
      expect(admin1!.role, AppRole.admin);
      expect(admin1.fullName, 'Savior Deo (Admin)');

      final admin2 = await authService.login(
        email: 'techcliff451@hotmail.com',
        password: 'OfficialAdmin@2026',
      );

      expect(admin2, isNotNull);
      expect(admin2!.role, AppRole.admin);
      expect(admin2.fullName, 'Tech Cliff (Admin)');

      // Verify persistent session
      final restored = authService.getCurrentUser();
      expect(restored?.email, 'techcliff451@hotmail.com');
    });

    test('rejects incorrect credentials', () async {
      final user = await authService.login(
        email: 'saviordeogratius@gmail.com',
        password: 'wrong_password',
      );

      expect(user, isNull);
      expect(authService.getCurrentUser(), isNull);
    });

    test('registers new resident account and restores session across restart', () async {
      final registered = await authService.register(
        fullName: 'Kezia Candia',
        email: 'kezia@example.ug',
        phone: '+256 772 999 888',
        password: 'securePass1',
        address: 'Arua Hill, Stand 14',
      );

      expect(registered.fullName, 'Kezia Candia');
      expect(registered.role, AppRole.resident);
      expect(registered.address, 'Arua Hill, Stand 14');

      // Verify session immediately active
      expect(authService.getCurrentUser()?.email, 'kezia@example.ug');
      expect(authService.isEmailRegistered('kezia@example.ug'), isTrue);

      // Logout
      await authService.logout();
      expect(authService.getCurrentUser(), isNull);

      // Log back in with registered credentials
      final reLoggedIn = await authService.login(
        email: 'kezia@example.ug',
        password: 'securePass1',
      );
      expect(reLoggedIn?.fullName, 'Kezia Candia');
      expect(reLoggedIn?.address, 'Arua Hill, Stand 14');
    });

    test('manages rider invitations and resident directory', () async {
      // Invite a rider
      await authService.inviteRider(
        email: 'rider.test@ecoroute.ug',
        fullName: 'Test Rider',
        phone: '+256 701 111 222',
      );

      final riders = authService.getInvitedRiders();
      expect(riders.any((r) => r['email'] == 'rider.test@ecoroute.ug'), isTrue);

      // Register a resident and verify resident directory
      await authService.register(
        fullName: 'Arua Resident',
        email: 'resident.arua@example.ug',
        phone: '+256 772 333 444',
        password: 'password123',
        address: 'Bazaar Ward',
      );

      final residents = authService.getRegisteredResidents();
      expect(residents.any((res) => res.email == 'resident.arua@example.ug'), isTrue);

      // Remove rider
      await authService.removeRider('rider.test@ecoroute.ug');
      final updatedRiders = authService.getInvitedRiders();
      expect(updatedRiders.any((r) => r['email'] == 'rider.test@ecoroute.ug'), isFalse);
    });

    test('hashes passwords using salted SHA-256', () {
      final hash1 = AuthService.hashPassword('testPassword123');
      final hash2 = AuthService.hashPassword('testPassword123');
      final hash3 = AuthService.hashPassword('differentPassword');

      expect(hash1, equals(hash2));
      expect(hash1, isNot(equals(hash3)));
      expect(hash1.length, equals(64)); // 256 bits = 64 hex characters
    });

    test('safely parses user roles with case insensitivity and fallback', () {
      expect(AuthService.parseRole('admin'), AppRole.admin);
      expect(AuthService.parseRole('ADMIN'), AppRole.admin);
      expect(AuthService.parseRole('rider'), AppRole.rider);
      expect(AuthService.parseRole('Rider'), AppRole.rider);
      expect(AuthService.parseRole('resident'), AppRole.resident);
      expect(AuthService.parseRole('unknown_role'), AppRole.resident);
      expect(AuthService.parseRole(null), AppRole.resident);
    });

    test('throttles failed login attempts with lockout', () async {
      const email = 'victim@example.com';

      // 1st failed attempt
      final res1 = await authService.login(email: email, password: 'wrong');
      expect(res1, isNull);

      // 2nd failed attempt
      final res2 = await authService.login(email: email, password: 'wrong');
      expect(res2, isNull);

      // 3rd failed attempt triggers lockout
      final res3 = await authService.login(email: email, password: 'wrong');
      expect(res3, isNull);

      // 4th attempt throws StateError with lockout message
      expect(
        () => authService.login(email: email, password: 'wrong'),
        throwsA(isA<StateError>().having(
          (e) => e.message,
          'message',
          contains('Too many failed login attempts'),
        )),
      );
    });
  });

  group('AuthSheet (Signup & Registration UI Flow)', () {
    late SharedPreferences preferences;
    late AuthService authService;

    setUp(() async {
      SharedPreferences.setMockInitialValues({});
      preferences = await SharedPreferences.getInstance();
      authService = AuthService(preferences);
    });

    testWidgets('toggles to Create Account mode and displays full registration inputs', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: AuthSheet(
              authService: authService,
              onAuthenticated: (_) {},
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Initially in Login mode
      expect(find.text('Login'), findsWidgets);
      expect(find.text('Full name'), findsNothing);

      // Tap toggle to create account
      final createAccountTab = find.byKey(const ValueKey('auth_tab_create_account'));
      await tester.ensureVisible(createAccountTab);
      await tester.tap(createAccountTab);
      await tester.pumpAndSettle();

      // Now in Create account mode
      expect(find.text('Create your EcoRoute account'), findsOneWidget);
      expect(find.text('Full name'), findsOneWidget);
      expect(find.text('Phone number'), findsOneWidget);
      expect(find.text('Default pickup address / landmark'), findsOneWidget);
      expect(find.text('Email address'), findsOneWidget);
      expect(find.text('Password'), findsOneWidget);
      expect(find.text('Confirm password'), findsOneWidget);
      expect(find.widgetWithText(FilledButton, 'Create account'), findsOneWidget);
    });

    testWidgets('validates matching passwords during signup', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: AuthSheet(
              authService: authService,
              initialCreateAccount: true,
              onAuthenticated: (_) {},
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Enter mismatched passwords
      await tester.enterText(find.widgetWithText(TextFormField, 'Full name'), 'Amina Testing');
      await tester.enterText(find.widgetWithText(TextFormField, 'Phone number'), '+256772111222');
      await tester.enterText(find.widgetWithText(TextFormField, 'Email address'), 'amina@example.com');
      await tester.enterText(find.widgetWithText(TextFormField, 'Password'), 'secret123');
      await tester.enterText(find.widgetWithText(TextFormField, 'Confirm password'), 'secret999');

      await tester.ensureVisible(find.widgetWithText(FilledButton, 'Create account'));
      await tester.tap(find.widgetWithText(FilledButton, 'Create account'));
      await tester.pumpAndSettle();

      expect(find.text('Passwords do not match'), findsOneWidget);
    });

    testWidgets('registers user, saves session, and triggers onAuthenticated', (
      WidgetTester tester,
    ) async {
      AppRole? authenticatedRole;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: AuthSheet(
              authService: authService,
              initialCreateAccount: true,
              onAuthenticated: (role) => authenticatedRole = role,
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Fill valid registration form
      await tester.enterText(find.widgetWithText(TextFormField, 'Full name'), 'Samuel Ondoma');
      await tester.enterText(find.widgetWithText(TextFormField, 'Phone number'), '+256772333444');
      await tester.enterText(find.widgetWithText(TextFormField, 'Email address'), 'samuel@ecoroute.ug');
      await tester.enterText(find.widgetWithText(TextFormField, 'Password'), 'secure123');
      await tester.enterText(find.widgetWithText(TextFormField, 'Confirm password'), 'secure123');

      await tester.ensureVisible(find.widgetWithText(FilledButton, 'Create account'));
      await tester.tap(find.widgetWithText(FilledButton, 'Create account'));
      await tester.pumpAndSettle();

      // Callback invoked with selected role (Resident)
      expect(authenticatedRole, AppRole.resident);

      // Verify persistent session in AuthService
      final current = authService.getCurrentUser();
      expect(current?.fullName, 'Samuel Ondoma');
      expect(current?.email, 'samuel@ecoroute.ug');
      expect(current?.phone, '+256772333444');
    });
  });
}
