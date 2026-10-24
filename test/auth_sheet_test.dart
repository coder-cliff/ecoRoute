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
    await tester.ensureVisible(find.text('Sign in'));
    await tester.tap(find.text('Sign in'));
    await tester.pumpAndSettle();

    expect(
      find.text('That email and password combination was not found.'),
      findsOneWidget,
    );
    expect(find.text('Sign in'), findsOneWidget);
    expect(authenticated, isFalse);
  });

  testWidgets('signs in using the selected demo role', (tester) async {
    AppRole? authenticatedRole;
    await _openAuthSheet(
      tester,
      authService,
      (role) => authenticatedRole = role,
    );

    await tester.ensureVisible(find.widgetWithText(ChoiceChip, 'Rider'));
    await tester.tap(find.widgetWithText(ChoiceChip, 'Rider'));
    await tester.pumpAndSettle();
    await tester.ensureVisible(find.text('Sign in'));
    await tester.tap(find.text('Sign in'));
    await tester.pumpAndSettle();

    expect(authenticatedRole, AppRole.rider);
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
