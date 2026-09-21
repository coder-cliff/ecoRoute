import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:ecoroute/main.dart';

void main() {
  testWidgets('public users can browse EcoRoute and see the order gate', (WidgetTester tester) async {
    await tester.pumpWidget(const EcoRouteApp());

    expect(find.text('EcoRoute'), findsOneWidget);
    expect(find.text('A cleaner route\nstarts with you.'), findsOneWidget);
    expect(find.text('Sign in to order'), findsOneWidget);
  });

  testWidgets('order form validates waste type and description', (WidgetTester tester) async {
    await tester.pumpWidget(const EcoRouteApp());
    await tester.tap(find.text('Sign in to order'));
    await tester.pumpAndSettle();
    await tester.enterText(find.widgetWithText(TextFormField, 'Email address'), 'user@example.com');
    await tester.enterText(find.widgetWithText(TextFormField, 'Password'), 'secret1');
    await tester.tap(find.widgetWithText(FilledButton, 'Sign in'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Order a collection'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Submit collection order'));
    await tester.pump();

    expect(find.text('Select a waste type'), findsOneWidget);
    expect(find.text('Please enter at least 10 characters'), findsOneWidget);
  });
}
