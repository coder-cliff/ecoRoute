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

    test('logs in built-in demo accounts successfully', () async {
      final user = await authService.login(
        email: 'resident@ecoroute.demo',
        password: 'demo123',
      );

      expect(user, isNotNull);
      expect(user!.role, AppRole.resident);
      expect(user.fullName, contains('Amina Dranzoa'));

      // Verify persistent session
      final restored = authService.getCurrentUser();
      expect(restored?.email, 'resident@ecoroute.demo');
    });

    test('rejects incorrect credentials', () async {
      final user = await authService.login(
        email: 'resident@ecoroute.demo',
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

      // Initially in Sign in mode
      expect(find.text('Welcome back'), findsOneWidget);
      expect(find.text('Sign in'), findsOneWidget);
      expect(find.text('Full name'), findsNothing);

      // Tap toggle to create account
      await tester.ensureVisible(find.text('New to EcoRoute? Create an account'));
      await tester.tap(find.text('New to EcoRoute? Create an account'));
      await tester.pumpAndSettle();

      // Now in Create account mode
      expect(find.text('Create your EcoRoute account'), findsOneWidget);
      expect(find.text('Full name'), findsOneWidget);
      expect(find.text('Phone number'), findsOneWidget);
      expect(find.text('Default pickup address / landmark'), findsOneWidget);
      expect(find.text('Email address'), findsOneWidget);
      expect(find.text('Password'), findsOneWidget);
      expect(find.text('Confirm password'), findsOneWidget);
      expect(find.text('Create account'), findsOneWidget);
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
