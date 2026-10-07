import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:ecoroute/core/pickup_request_repository.dart';
import 'package:ecoroute/domain/entities/pickup_request.dart';
import 'package:ecoroute/domain/enums/request_status.dart';
import 'package:ecoroute/domain/enums/waste_type.dart';
import 'package:ecoroute/features/home/home_screen.dart';
import 'package:ecoroute/main.dart';

void main() {
  testWidgets('users can browse the EcoRoute dashboard', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(const EcoRouteApp());

    expect(find.text('EcoRoute'), findsOneWidget);
    await tester.pump(const Duration(seconds: 2));
    await tester.pumpAndSettle();

    expect(find.text('Arua waste pickup'), findsOneWidget);
    expect(find.text('Arua service radius: 12 km'), findsOneWidget);
    expect(find.text('REPORT AN ISSUE'), findsOneWidget);
  });

  testWidgets('demo auth accounts sign in as different roles', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(const EcoRouteApp());
    await tester.pump(const Duration(seconds: 2));
    await tester.pumpAndSettle();

    await tester.ensureVisible(find.text('REPORT AN ISSUE'));
    await tester.tap(find.text('REPORT AN ISSUE'));
    await tester.pumpAndSettle();

    await tester.ensureVisible(find.text('Rider'));
    await tester.tap(find.text('Rider'));
    await tester.pumpAndSettle();
    await tester.tap(find.widgetWithText(FilledButton, 'Sign in'));
    await tester.pumpAndSettle();
    await tester.ensureVisible(find.text('Profile'));
    await tester.tap(find.text('Profile'));
    await tester.pumpAndSettle();

    expect(find.text('Signed in as Rider'), findsOneWidget);
  });

  testWidgets('order form validates waste type and description', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(const EcoRouteApp());
    await tester.pump(const Duration(seconds: 2));
    await tester.pumpAndSettle();
    await tester.ensureVisible(find.text('REPORT AN ISSUE'));
    await tester.tap(find.text('REPORT AN ISSUE'));
    await tester.pumpAndSettle();
    await tester.enterText(
      find.widgetWithText(TextFormField, 'Email address'),
      'user@example.com',
    );
    await tester.enterText(
      find.widgetWithText(TextFormField, 'Password'),
      'secret1',
    );
    await tester.tap(find.widgetWithText(FilledButton, 'Sign in'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('REPORT AN ISSUE'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Submit collection order'));
    await tester.pump();

    expect(find.text('Select a waste type'), findsOneWidget);
    expect(find.text('Please enter at least 10 characters'), findsOneWidget);
  });

  testWidgets('dashboard actions fit a compact phone viewport', (
    WidgetTester tester,
  ) async {
    tester.view.physicalSize = const Size(412, 700);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(const EcoRouteApp());
    await tester.pump(const Duration(seconds: 2));
    await tester.pumpAndSettle();

    await tester.ensureVisible(find.text('REPORT AN ISSUE'));
    expect(find.text('REPORT AN ISSUE'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('riders can advance route stops through the pickup workflow', (
    WidgetTester tester,
  ) async {
    final repository = _TestPickupRequestRepository([
      PickupRequest(
        id: 'route-1',
        wasteType: WasteType.household,
        description: 'Blue gate, Oli division',
        submittedAt: DateTime(2026, 10, 7),
      ),
    ]);
    await tester.pumpWidget(
      MaterialApp(home: EcoRouteHomeScreen(repository: repository)),
    );
    await tester.pumpAndSettle();
    await _signInAs(tester, 'Rider');

    await tester.ensureVisible(find.text('Mark collected'));
    await tester.tap(find.text('Mark collected'));
    await tester.pumpAndSettle();
    expect(find.text('Send for verification'), findsOneWidget);

    await tester.tap(find.text('Send for verification'));
    await tester.pumpAndSettle();
    expect(
      find.text('No active stops. New collection requests will appear here.'),
      findsOneWidget,
    );
    expect(
      (await repository.loadAll()).single.status,
      RequestStatus.awaitingVerification,
    );
  });

  testWidgets('admins can approve or return pickups and see live analytics', (
    WidgetTester tester,
  ) async {
    final repository = _TestPickupRequestRepository([
      PickupRequest(
        id: 'approval-1',
        wasteType: WasteType.household,
        description: 'Market road collection point',
        submittedAt: DateTime(2026, 10, 7),
        status: RequestStatus.awaitingVerification,
      ),
      PickupRequest(
        id: 'approval-2',
        wasteType: WasteType.tradingCenter,
        description: 'Oli trading center entrance',
        submittedAt: DateTime(2026, 10, 7),
        status: RequestStatus.awaitingVerification,
      ),
    ]);
    await tester.pumpWidget(
      MaterialApp(home: EcoRouteHomeScreen(repository: repository)),
    );
    await tester.pumpAndSettle();
    await _signInAs(tester, 'Admin');

    await tester.ensureVisible(find.text('Approve payment').first);
    await tester.tap(find.text('Approve payment').first);
    await tester.pumpAndSettle();
    expect(find.text('Return to rider'), findsOneWidget);

    await tester.ensureVisible(find.text('Return to rider'));
    await tester.tap(find.text('Return to rider'));
    await tester.pumpAndSettle();
    expect(
      find.text(
        'All caught up. Completed pickups will appear here for review.',
      ),
      findsOneWidget,
    );
    expect(find.text('Transaction analytics'), findsOneWidget);
    expect(find.text('2 total requests · 1 verified and paid'), findsOneWidget);
    expect(
      (await repository.loadAll()).map((request) => request.status),
      containsAll([RequestStatus.paid, RequestStatus.collected]),
    );
  });
}

Future<void> _signInAs(WidgetTester tester, String role) async {
  await tester.tap(find.byIcon(Icons.notifications_none_rounded));
  await tester.pumpAndSettle();
  await tester.tap(find.widgetWithText(ChoiceChip, role));
  await tester.pumpAndSettle();
  await tester.tap(find.widgetWithText(FilledButton, 'Sign in'));
  await tester.pumpAndSettle();
}

class _TestPickupRequestRepository implements PickupRequestRepository {
  _TestPickupRequestRepository(this._requests);

  final List<PickupRequest> _requests;

  @override
  Future<List<PickupRequest>> loadAll() async =>
      List<PickupRequest>.of(_requests);

  @override
  Future<void> save(PickupRequest request) async {
    _requests.insert(0, request);
  }

  @override
  Future<void> updateStatus(String id, RequestStatus status) async {
    final index = _requests.indexWhere((request) => request.id == id);
    if (index >= 0) {
      _requests[index] = _requests[index].copyWith(status: status);
    }
  }

  @override
  Future<void> delete(String id) async {
    _requests.removeWhere((request) => request.id == id);
  }
}
