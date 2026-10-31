import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:ecoroute/core/pickup_request_repository.dart';
import 'package:ecoroute/domain/entities/pickup_request.dart';
import 'package:ecoroute/domain/enums/request_status.dart';
import 'package:ecoroute/domain/enums/waste_type.dart';
import 'package:ecoroute/features/auth/login_screen.dart';
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

    // After 1.5s splash animation, automatically transitions to LoginScreen
    await tester.pump(const Duration(milliseconds: 1600));
    await tester.pumpAndSettle();

    expect(find.text('Sign In'), findsNWidgets(2));
    expect(find.byType(LoginScreen), findsOneWidget);
    expect(find.text('Forgot Password?'), findsOneWidget);
    expect(find.text('Don\'t have an account? '), findsOneWidget);
  });

  testWidgets('auth accounts sign in as different roles with automatic routing', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(const EcoRouteApp());
    await tester.pump(const Duration(milliseconds: 1600));
    await tester.pumpAndSettle();

    // Fill in Rider credentials on Login Screen
    await tester.enterText(
      find.byKey(const ValueKey('login_email_input')),
      'rider.juma@ecoroute.ug',
    );
    await tester.enterText(
      find.byKey(const ValueKey('login_password_input')),
      'OfficialAdmin@2026',
    );
    await tester.tap(find.byKey(const ValueKey('login_submit_button')));
    await tester.pumpAndSettle();

    // Automatically routed to Rider Task Hub without any manual role selection
    expect(find.byType(RiderTaskHub), findsOneWidget);
    await tester.ensureVisible(find.text('Profile'));
    await tester.tap(find.text('Profile'));
    await tester.pumpAndSettle();

    expect(find.text('Signed in as Rider'), findsOneWidget);
  });

  testWidgets('resident sign in routes to resident dashboard and validates order form', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(const EcoRouteApp());
    await tester.pump(const Duration(milliseconds: 1600));
    await tester.pumpAndSettle();

    // Fill in resident credentials
    await tester.enterText(
      find.byKey(const ValueKey('login_email_input')),
      'user@example.com',
    );
    await tester.enterText(
      find.byKey(const ValueKey('login_password_input')),
      'secret123',
    );
    await tester.tap(find.byKey(const ValueKey('login_submit_button')));
    await tester.pumpAndSettle();

    // Automatically routed to Resident Dashboard
    expect(find.text('Arua waste pickup'), findsOneWidget);
    expect(find.text('REPORT AN ISSUE'), findsOneWidget);

    await tester.ensureVisible(find.text('REPORT AN ISSUE'));
    await tester.tap(find.text('REPORT AN ISSUE'));
    await tester.pumpAndSettle();
    await tester.ensureVisible(find.text('Submit collection order'));
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
