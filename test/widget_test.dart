import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:ecoroute/main.dart';

void main() {
  testWidgets('users can browse the EcoRoute dashboard', (WidgetTester tester) async {
    await tester.pumpWidget(const EcoRouteApp());

    expect(find.text('EcoRoute'), findsOneWidget);
    await tester.pump(const Duration(seconds: 5));
    await tester.pumpAndSettle();

    expect(find.text('Good morning, Alex'), findsOneWidget);
    expect(find.text('Nearby collection points'), findsOneWidget);
    expect(find.text('REPORT AN ISSUE'), findsOneWidget);
  });

  testWidgets('order form validates waste type and description', (WidgetTester tester) async {
    await tester.pumpWidget(const EcoRouteApp());
    await tester.pump(const Duration(seconds: 5));
    await tester.pumpAndSettle();
    await tester.tap(find.text('REPORT AN ISSUE'));
    await tester.pumpAndSettle();
    await tester.enterText(find.widgetWithText(TextFormField, 'Email address'), 'user@example.com');
    await tester.enterText(find.widgetWithText(TextFormField, 'Password'), 'secret1');
    await tester.tap(find.widgetWithText(FilledButton, 'Sign in'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('REPORT AN ISSUE'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Submit collection order'));
    await tester.pump();

    expect(find.text('Select a waste type'), findsOneWidget);
    expect(find.text('Please enter at least 10 characters'), findsOneWidget);
  });

  testWidgets('dashboard actions fit a compact phone viewport', (WidgetTester tester) async {
    tester.view.physicalSize = const Size(412, 700);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(const EcoRouteApp());
    await tester.pump(const Duration(seconds: 5));
    await tester.pumpAndSettle();

    expect(find.text('REPORT AN ISSUE'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}
