import 'package:ecoroute/core/services/auth_service.dart';
import 'package:ecoroute/domain/enums/role.dart';
import 'package:ecoroute/features/auth/auth_sheet.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late AuthService authService;

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    authService = AuthService(await SharedPreferences.getInstance());
  });

  testWidgets('shows a clear error and stays open for invalid credentials', (
    tester,
  ) async {
    var authenticated = false;
    await _openAuthSheet(tester, authService, (_) => authenticated = true);

    await tester.enterText(
      find.widgetWithText(TextFormField, 'Email address'),
      'unknown@example.ug',
    );
    await tester.enterText(
      find.widgetWithText(TextFormField, 'Password'),
      'unknown123',
    );
    final loginButton = find.widgetWithText(FilledButton, 'Login');
    await tester.ensureVisible(loginButton);
    await tester.tap(loginButton);
    await tester.pumpAndSettle();

    expect(
      find.text('Invalid email or password. Please try again.'),
      findsOneWidget,
    );
    expect(find.widgetWithText(FilledButton, 'Login'), findsOneWidget);
    expect(authenticated, isFalse);
  });

  testWidgets('signs in using admin credentials', (tester) async {
    AppRole? authenticatedRole;
    await _openAuthSheet(
      tester,
      authService,
      (role) => authenticatedRole = role,
    );

    await tester.enterText(
      find.widgetWithText(TextFormField, 'Email address'),
      'saviordeogratius@gmail.com',
    );
    await tester.enterText(
      find.widgetWithText(TextFormField, 'Password'),
      '#ecorute26',
    );
    final loginButton = find.widgetWithText(FilledButton, 'Login');
    await tester.ensureVisible(loginButton);
    await tester.tap(loginButton);
    await tester.pumpAndSettle();

    expect(authenticatedRole, AppRole.admin);
  });
}

Future<void> _openAuthSheet(
  WidgetTester tester,
  AuthService authService,
  void Function(AppRole role) onAuthenticated,
) async {
  await tester.pumpWidget(
    MaterialApp(
      home: Builder(
        builder: (context) => Scaffold(
          body: Center(
            child: FilledButton(
              onPressed: () => showModalBottomSheet<void>(
                context: context,
                isScrollControlled: true,
                builder: (_) => AuthSheet(
                  authService: authService,
                  onAuthenticated: onAuthenticated,
                ),
              ),
              child: const Text('Open login'),
            ),
          ),
        ),
      ),
    ),
  );

  await tester.tap(find.text('Open login'));
  await tester.pumpAndSettle();
}
