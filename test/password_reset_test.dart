import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:ecoroute/core/pickup_request_repository.dart';
import 'package:ecoroute/core/services/auth_service.dart';
import 'package:ecoroute/features/auth/login_screen.dart';
import 'package:ecoroute/features/auth/responsive_sign_in_screen.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late SharedPreferences prefs;
  late AuthService authService;

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    prefs = await SharedPreferences.getInstance();
    authService = AuthService(prefs);
  });

  group('AuthService Password Reset Unit Tests', () {
    test('Empty email throws AuthException with validation message', () async {
      expect(
        () => authService.sendPasswordResetEmail(''),
        throwsA(
          isA<AuthException>().having(
            (e) => e.message,
            'message',
            'Please enter a valid email address.',
          ),
        ),
      );
    });

    test('Malformed email format throws AuthException', () async {
      expect(
        () => authService.sendPasswordResetEmail('not-an-email'),
        throwsA(
          isA<AuthException>().having(
            (e) => e.message,
            'message',
            'Please enter a valid email address.',
          ),
        ),
      );
    });

    test('Unregistered email throws AuthException in offline mode', () async {
      expect(
        () => authService.sendPasswordResetEmail('unregistered@example.com'),
        throwsA(
          isA<AuthException>().having(
            (e) => e.message,
            'message',
            contains('No account found with unregistered@example.com'),
          ),
        ),
      );
    });

    test('Registered admin email completes password reset without error', () async {
      await expectLater(
        authService.sendPasswordResetEmail('ayikog@yahoo.com'),
        completes,
      );
    });

    test('Custom passwordResetHandler is invoked when configured', () async {
      String? dispatchedEmail;
      authService.passwordResetHandler = (email) async {
        dispatchedEmail = email;
      };

      await authService.sendPasswordResetEmail('resident.test@ecoroute.ug');
      expect(dispatchedEmail, 'resident.test@ecoroute.ug');
    });
  });

  group('LoginScreen Password Reset Widget Tests', () {
    testWidgets('Empty email triggers validation SnackBar', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: LoginScreen(
            repository: const MemoryPickupRequestRepository(),
            authService: authService,
          ),
        ),
      );
      await tester.pumpAndSettle();

      await tester.tap(find.byKey(const ValueKey('login_forgot_password_button')));
      await tester.pumpAndSettle();

      expect(
        find.text('Please enter your registered email address in the field above.'),
        findsOneWidget,
      );
    });

    testWidgets('Malformed email triggers validation SnackBar', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: LoginScreen(
            repository: const MemoryPickupRequestRepository(),
            authService: authService,
          ),
        ),
      );
      await tester.pumpAndSettle();

      await tester.enterText(
        find.byKey(const ValueKey('login_email_input')),
        'invalid-email-pattern',
      );
      await tester.tap(find.byKey(const ValueKey('login_forgot_password_button')));
      await tester.pumpAndSettle();

      expect(
        find.text('Please enter your registered email address in the field above.'),
        findsOneWidget,
      );
    });

    testWidgets('Valid registered email dispatches reset and displays success feedback', (
      tester,
    ) async {
      await tester.pumpWidget(
        MaterialApp(
          home: LoginScreen(
            repository: const MemoryPickupRequestRepository(),
            authService: authService,
          ),
        ),
      );
      await tester.pumpAndSettle();

      await tester.enterText(
        find.byKey(const ValueKey('login_email_input')),
        'ayikog@yahoo.com',
      );
      await tester.tap(find.byKey(const ValueKey('login_forgot_password_button')));
      await tester.pumpAndSettle();

      expect(
        find.text('Password reset instructions sent to ayikog@yahoo.com. Please check your inbox.'),
        findsOneWidget,
      );
    });
  });

  group('ResponsiveSignInScreen Password Reset Widget Tests', () {
    testWidgets('Tapping forgot password opens dialog and validates input', (
      tester,
    ) async {
      await tester.pumpWidget(
        MaterialApp(
          home: ResponsiveSignInScreen(authService: authService),
        ),
      );
      await tester.pumpAndSettle();

      // Open dialog
      await tester.tap(find.byKey(const ValueKey('responsive_forgot_password_button')));
      await tester.pumpAndSettle();

      expect(find.text('Reset Password'), findsOneWidget);

      // Submit with empty email
      await tester.tap(find.byKey(const ValueKey('reset_password_submit_button')));
      await tester.pumpAndSettle();

      expect(find.text('Please enter a valid email address.'), findsOneWidget);
    });

    testWidgets('Valid email sends reset link and closes dialog with confirmation', (
      tester,
    ) async {
      await tester.pumpWidget(
        MaterialApp(
          home: ResponsiveSignInScreen(authService: authService),
        ),
      );
      await tester.pumpAndSettle();

      // Open dialog
      await tester.tap(find.byKey(const ValueKey('responsive_forgot_password_button')));
      await tester.pumpAndSettle();

      // Enter registered email
      await tester.enterText(
        find.byKey(const ValueKey('reset_email_input')),
        'ayikog@yahoo.com',
      );
      await tester.tap(find.byKey(const ValueKey('reset_password_submit_button')));
      await tester.pumpAndSettle();

      // Dialog dismisses and confirmation is shown
      expect(find.text('Reset Password'), findsNothing);
      expect(
        find.text('Password reset instructions sent to ayikog@yahoo.com. Please check your inbox.'),
        findsOneWidget,
      );
    });
  });
}
