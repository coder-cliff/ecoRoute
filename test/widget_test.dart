import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:ecoroute/core/pickup_request_repository.dart';
import 'package:ecoroute/domain/entities/pickup_request.dart';
import 'package:ecoroute/domain/enums/request_status.dart';
import 'package:ecoroute/domain/enums/waste_type.dart';
import 'package:ecoroute/features/home/home_screen.dart';
import 'package:ecoroute/features/rider/rider_task_hub.dart';
import 'package:ecoroute/features/admin/admin_dashboard.dart';
import 'package:ecoroute/main.dart';

void main() {
  testWidgets('launch sequence starts with splash and transitions to Sign-In portal', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(const EcoRouteApp());
    // Initial splash state
    expect(find.text('EcoRoute'), findsOneWidget);

    // After 2.2s splash timer, automatically transitions to LoginScreen
    await tester.pump(const Duration(milliseconds: 2400));
    await tester.pumpAndSettle();

    expect(find.text('Welcome to EcoRoute'), findsOneWidget);
    expect(find.text('Continue'), findsOneWidget);
  });

  testWidgets('auth accounts sign in as rider with automatic routing', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(const EcoRouteApp());
    await tester.pump(const Duration(milliseconds: 2400));
    await tester.pumpAndSettle();

    // Fill in Rider credentials on Login Screen
    await tester.enterText(
      find.byKey(const ValueKey('login_email_input')),
      'rider@ecoroute.ug',
    );
    await tester.enterText(
      find.byKey(const ValueKey('login_password_input')),
      'password123',
    );
    await tester.tap(find.byKey(const ValueKey('login_submit_button')));
    await tester.pump(const Duration(milliseconds: 1200));
    await tester.pumpAndSettle();

    // Automatically routed to Rider Dashboard
    expect(find.text('Rider Dashboard'), findsOneWidget);
    expect(find.text('Tasks'), findsOneWidget);
    expect(find.text('Route'), findsOneWidget);
    expect(find.text('Earnings'), findsOneWidget);
  });

  testWidgets('auth accounts sign in as resident with automatic routing', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(const EcoRouteApp());
    await tester.pump(const Duration(milliseconds: 2400));
    await tester.pumpAndSettle();

    // Fill in Resident credentials
    await tester.enterText(
      find.byKey(const ValueKey('login_email_input')),
      'resident@ecoroute.ug',
    );
    await tester.enterText(
      find.byKey(const ValueKey('login_password_input')),
      'password123',
    );
    await tester.tap(find.byKey(const ValueKey('login_submit_button')));
    await tester.pump(const Duration(milliseconds: 1200));
    await tester.pumpAndSettle();

    // Automatically routed to Resident Dashboard
    expect(find.text('Hello, Resident • Arua City'), findsOneWidget);
    expect(find.text('Book a New Pickup'), findsOneWidget);
    expect(find.text('Home'), findsOneWidget);
    expect(find.text('Requests'), findsOneWidget);
    expect(find.text('Support'), findsOneWidget);
  });

  testWidgets('auth accounts sign in as admin with automatic routing', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(const EcoRouteApp());
    await tester.pump(const Duration(milliseconds: 2400));
    await tester.pumpAndSettle();

    // Fill in Admin credentials
    await tester.enterText(
      find.byKey(const ValueKey('login_email_input')),
      'admin@ecoroute.ug',
    );
    await tester.enterText(
      find.byKey(const ValueKey('login_password_input')),
      'password123',
    );
    await tester.tap(find.byKey(const ValueKey('login_submit_button')));
    await tester.pump(const Duration(milliseconds: 1200));
    await tester.pumpAndSettle();

    // Automatically routed to Admin Dashboard
    expect(find.text('Admin Dashboard'), findsOneWidget);
    expect(find.text('All Systems Nominal'), findsOneWidget);
    expect(find.text('Active Riders'), findsOneWidget);
    expect(find.text('Dashboard'), findsOneWidget);
    expect(find.text('Fleet'), findsOneWidget);
    expect(find.text('Reports'), findsOneWidget);
  });

  testWidgets('dashboard actions fit a compact phone viewport', (
    WidgetTester tester,
  ) async {
    tester.view.physicalSize = const Size(412, 700);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(
      const MaterialApp(
        home: HomeScreen(repository: MemoryPickupRequestRepository()),
      ),
    );
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
      MaterialApp(home: RiderTaskHub(repository: repository)),
    );
    await tester.pumpAndSettle();

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
      MaterialApp(home: AdminDashboard(repository: repository)),
    );
    await tester.pumpAndSettle();

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
    expect(
      (await repository.loadAll()).map((request) => request.status),
      containsAll([RequestStatus.paid, RequestStatus.collected]),
    );
  });
}

class _TestPickupRequestRepository implements PickupRequestRepository {
  _TestPickupRequestRepository(this._requests);

  final List<PickupRequest> _requests;

  @override
  Stream<List<PickupRequest>> watchRequests({int limit = 50}) =>
      Stream.value(List<PickupRequest>.of(_requests));

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

  @override
  Future<void> seedDemoData({bool force = false}) async {}
}
