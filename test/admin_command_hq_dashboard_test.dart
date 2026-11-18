import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:ecoroute/core/pickup_request_repository.dart';
import 'package:ecoroute/core/services/auth_service.dart';
import 'package:ecoroute/domain/entities/pickup_request.dart';
import 'package:ecoroute/domain/enums/request_status.dart';
import 'package:ecoroute/domain/enums/waste_type.dart';
import 'package:ecoroute/features/admin/admin_dashboard.dart';
import 'package:ecoroute/features/admin/widgets/admin_session_ended_view.dart';
import 'package:ecoroute/features/admin/widgets/live_dispatch_map.dart';
import 'package:ecoroute/features/auth/admin_sign_in_screen.dart';
import 'package:ecoroute/features/auth/login_screen.dart';
import 'package:ecoroute/features/request/order_page.dart';
import 'package:ecoroute/features/rider/rider_task_hub.dart';

class _MockRepo implements PickupRequestRepository {
  _MockRepo([List<PickupRequest>? initial]) : _list = initial ?? [];
  final List<PickupRequest> _list;

  @override
  Stream<List<PickupRequest>> watchRequests({int limit = 50}) => Stream.value(List.of(_list));

  @override
  Future<List<PickupRequest>> loadAll() async => List.of(_list);

  @override
  Future<void> save(PickupRequest request) async {
    final idx = _list.indexWhere((r) => r.id == request.id);
    if (idx >= 0) {
      _list[idx] = request;
    } else {
      _list.insert(0, request);
    }
  }

  @override
  Future<void> updateStatus(String id, RequestStatus status) async {
    final idx = _list.indexWhere((r) => r.id == id);
    if (idx >= 0) {
      _list[idx] = _list[idx].copyWith(status: status);
    }
  }

  @override
  Future<void> delete(String id) async {
    _list.removeWhere((r) => r.id == id);
  }

  @override
  Future<void> seedDemoData({bool force = false}) async {}
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late SharedPreferences prefs;
  late AuthService authService;
  late _MockRepo repo;

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    prefs = await SharedPreferences.getInstance();
    authService = AuthService(prefs);
    repo = _MockRepo([
      PickupRequest(
        id: 'req-verif-1',
        wasteType: WasteType.tradingCenter,
        description: 'Arua Hill Supermarket commercial sacks',
        submittedAt: DateTime(2026, 11, 1),
        status: RequestStatus.awaitingVerification,
      ),
    ]);
  });

  group('Admin Sign-In & 2FA Email OTP Verification', () {
    testWidgets('renders Admin Sign-In screen with #A-9014 and responsive frame', (
      WidgetTester tester,
    ) async {
      await tester.binding.setSurfaceSize(const Size(390, 844)); // iPhone
      addTearDown(() => tester.binding.setSurfaceSize(null));
      await tester.pumpWidget(
        MaterialApp(
          home: AdminSignInScreen(
            repository: repo,
            authService: authService,
            initialAdminId: '#A-9014',
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Admin Sign In'), findsOneWidget);
      expect(find.text('Arua dispatch center\nauthorization required.'), findsOneWidget);
      expect(find.byKey(const ValueKey('admin_id_input')), findsOneWidget);
      expect(find.byKey(const ValueKey('admin_pin_input')), findsOneWidget);
      expect(find.byKey(const ValueKey('admin_authorize_button')), findsOneWidget);
      expect(find.byKey(const ValueKey('verify_mobile_otp_button')), findsOneWidget);
      expect(find.text('Authorized Personnel Only • IP Tracked'), findsOneWidget);
    });

    testWidgets('authorizes admin with #A-9014 and navigates to AdminDashboard', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(
        MaterialApp(
          home: AdminSignInScreen(
            repository: repo,
            authService: authService,
            initialAdminId: '#A-9014',
          ),
        ),
      );
      await tester.pumpAndSettle();

      await tester.enterText(
        find.byKey(const ValueKey('admin_pin_input')),
        'OfficialAdmin@2026',
      );
      await tester.tap(find.byKey(const ValueKey('admin_authorize_button')));
      await tester.pumpAndSettle();

      expect(find.byType(AdminDashboard), findsOneWidget);
    });

    testWidgets('opens 2FA OTP modal and verifies 6-digit code', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(
        MaterialApp(
          home: AdminSignInScreen(
            repository: repo,
            authService: authService,
            initialAdminId: '#A-9014',
          ),
        ),
      );
      await tester.pumpAndSettle();

      await tester.tap(find.byKey(const ValueKey('verify_mobile_otp_button')));
      await tester.pumpAndSettle();

      expect(find.text('2FA OTP Verification'), findsOneWidget);
      expect(find.byKey(const ValueKey('admin_otp_input')), findsOneWidget);

      await tester.enterText(find.byKey(const ValueKey('admin_otp_input')), '123456');
      await tester.tap(find.byKey(const ValueKey('verify_otp_confirm_button')));
      await tester.pumpAndSettle();

      expect(find.byType(AdminDashboard), findsOneWidget);
    });

    testWidgets('allows self-service password reset for administrator', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(
        MaterialApp(
          home: AdminSignInScreen(
            repository: repo,
            authService: authService,
            initialAdminId: '#A-9014',
          ),
        ),
      );
      await tester.pumpAndSettle();

      await tester.tap(find.text('Reset Administrator Password'));
      await tester.pumpAndSettle();

      expect(find.text('Set New Admin Password'), findsOneWidget);
      await tester.enterText(find.widgetWithText(TextField, 'New Password'), 'NewAdminSecret@2026');
      await tester.tap(find.text('Update'));
      await tester.pumpAndSettle();

      // Sign in with new password
      await tester.enterText(find.byKey(const ValueKey('admin_pin_input')), 'NewAdminSecret@2026');
      await tester.tap(find.byKey(const ValueKey('admin_authorize_button')));
      await tester.pumpAndSettle();

      expect(find.byType(AdminDashboard), findsOneWidget);
    });

    testWidgets('allows rider to enable 2FA via email and reset password using OTP', (
      WidgetTester tester,
    ) async {
      const riderEmail = 'rider@ecoroute.ug';
      // Enable 2FA for rider
      await authService.set2faEnabledForEmail(riderEmail, true);
      expect(authService.is2faEnabledForEmail(riderEmail), isTrue);

      // Send 2FA email OTP
      final otp = await authService.send2faEmailOtp(email: riderEmail);
      expect(otp.length, 6);

      // Verify invalid code fails
      expect(authService.verify2faEmailOtp(email: riderEmail, otp: '000000'), isFalse);

      // Verify generated OTP succeeds
      expect(authService.verify2faEmailOtp(email: riderEmail, otp: otp), isTrue);

      // Rider resets their password using OTP
      final resetSuccess = await authService.resetPassword(
        email: riderEmail,
        newPassword: 'NewRiderPassword2026!',
        otpCode: otp,
      );
      expect(resetSuccess, isTrue);

      // Verify rider can log in with new password
      final loggedIn = await authService.login(
        email: riderEmail,
        password: 'NewRiderPassword2026!',
      );
      expect(loggedIn, isNotNull);
      expect(loggedIn!.email, riderEmail);
    });
  });

  group('Session Ended View', () {
    testWidgets('renders session summary metrics and finalize button', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(
        MaterialApp(
          home: AdminSessionEndedView(
            repository: repo,
            authService: authService,
            adminId: '#A-9014',
            totalDispatches: 14,
            unresolvedAlerts: 2,
            auditEntriesCreated: 45,
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Session Ended'), findsOneWidget);
      expect(find.text('Active Session Found • Arua Command HQ'), findsOneWidget);
      expect(find.text('Admin ID: #A-9014'), findsOneWidget);
      expect(find.text('Total Dispatches:'), findsOneWidget);
      expect(find.text('14'), findsOneWidget);
      expect(find.text('Unresolved Alerts:'), findsOneWidget);
      expect(find.text('2'), findsOneWidget);
      expect(find.text('Audit Entries Created:'), findsOneWidget);
      expect(find.text('45'), findsOneWidget);
      expect(find.byKey(const ValueKey('finalize_day_ledger_button')), findsOneWidget);
      expect(find.byKey(const ValueKey('emergency_pause_button')), findsOneWidget);

      await tester.tap(find.byKey(const ValueKey('finalize_day_ledger_button')));
      await tester.pumpAndSettle();

      expect(find.byType(LoginScreen), findsOneWidget);
    });
  });

  group('Command HQ Admin Dashboard Tabs & Live Control Operations', () {
    testWidgets('renders Top Bar, Quick Actions, Metrics, Live Map, and Escalations', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(
        MaterialApp(
          home: AdminDashboard(
            repository: repo,
            authService: authService,
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Top Bar Branding & Connection
      expect(find.text('ecoRoute'), findsOneWidget);
      expect(find.text('Command HQ • Online'), findsOneWidget);
      expect(find.text('Profile'), findsOneWidget);

      // Section 1: Quick Actions
      expect(find.text('System Quick Actions'), findsOneWidget);
      expect(find.text('Dispatch Emergency Truck'), findsOneWidget);
      expect(find.text('Command HQ (Arua)'), findsWidgets);

      // Section 2: Real-time Metrics
      expect(find.text('Real-Time Operations'), findsOneWidget);
      expect(find.text('Live Dispatches:'), findsOneWidget);
      expect(find.text('Pending Requests:'), findsOneWidget);

      // Section 3: Live Map
      expect(find.text('Live Dispatch Map'), findsOneWidget);
      expect(find.text('Arua City Fleet Track'), findsOneWidget);
      expect(find.text('Active Map View'), findsOneWidget);
      expect(find.text('T1: En Route to Shop 14'), findsOneWidget);
      expect(find.text('T2: At Arua Market'), findsOneWidget);
      expect(find.text('T3: Resolving Route 4 delay'), findsOneWidget);
      expect(find.byKey(const ValueKey('view_active_dispatches_button')), findsOneWidget);

      // Section 4: Escalations & Alerts
      expect(find.text('Escalations & Alerts'), findsOneWidget);
      expect(find.text('Route 4 Delay Reported'), findsOneWidget);
      expect(find.text('Customer Service Flag #8821'), findsOneWidget);

      // Section 5: Audit Trail & Logs Preview
      expect(find.text('Audit Trail & Logs'), findsOneWidget);
      expect(find.text('Client Pickup Complete • #7741'), findsOneWidget);
    });

    testWidgets('triggers Emergency Dispatch Truck workflow and adds active route', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(
        MaterialApp(
          home: AdminDashboard(
            repository: repo,
            authService: authService,
          ),
        ),
      );
      await tester.pumpAndSettle();

      await tester.tap(find.byKey(const ValueKey('dispatch_emergency_truck_button')));
      await tester.pumpAndSettle();

      expect(find.text('Sector Target:'), findsOneWidget);
      expect(find.text('Assign Vehicle:'), findsOneWidget);
      expect(find.text('Confirm Immediate Dispatch'), findsOneWidget);

      await tester.tap(find.text('Confirm Immediate Dispatch'));
      await tester.pumpAndSettle();

      // Switch to Dispatches tab and verify newly dispatched emergency route
      await tester.tap(find.text('Dispatches'));
      await tester.pumpAndSettle();

      expect(find.text('Emergency Truck (Arua Central Market)'), findsOneWidget);
    });

    testWidgets('Dispatches Tab allows interactive route status toggles and rider checklists', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(
        MaterialApp(
          home: AdminDashboard(
            repository: repo,
            authService: authService,
          ),
        ),
      );
      await tester.pumpAndSettle();

      await tester.tap(find.text('Dispatches'));
      await tester.pumpAndSettle();

      expect(find.text('Live Dispatches'), findsOneWidget);
      expect(find.text('Active Routes'), findsOneWidget);
      expect(find.text('Route 4 (Arua Market)'), findsOneWidget);
      expect(find.text('Route 1 (Vurra)'), findsOneWidget);

      // Toggle status pill
      await tester.ensureVisible(find.text('Delay').first);
      await tester.tap(find.text('Delay').first);
      await tester.pumpAndSettle();

      expect(find.text('Peter #R-4809'), findsOneWidget);
      expect(find.text('Kassim #R-3102'), findsOneWidget);
    });

    testWidgets('Audits Tab renders timeline nodes, filter chips, and export button', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(
        MaterialApp(
          home: AdminDashboard(
            repository: repo,
            authService: authService,
          ),
        ),
      );
      await tester.pumpAndSettle();

      await tester.tap(find.text('Audits'));
      await tester.pumpAndSettle();

      expect(find.text('Audit Ledger'), findsOneWidget);
      expect(find.text('Log Filtering'), findsOneWidget);
      expect(find.text('Transaction & Verification Timeline'), findsOneWidget);
      expect(find.text('Audited Transaction #04192 Verified'), findsOneWidget);
      expect(find.text('Mobile Money #04192 Verified'), findsOneWidget);
      expect(find.text('Compliance & Reports'), findsOneWidget);
      expect(find.text('Export Log Data'), findsOneWidget);

      // Tap filter chip
      await tester.tap(find.text('Last 7 Days'));
      await tester.pumpAndSettle();

      // Tap Export Log Data
      await tester.ensureVisible(find.text('Export Log Data'));
      await tester.tap(find.text('Export Log Data'));
      await tester.pumpAndSettle();
      expect(find.text('Audit Log Data exported successfully to CSV.'), findsOneWidget);
    });

    testWidgets('Fleet/Controls Tab toggles operational switches and opens PIN setup', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(
        MaterialApp(
          home: AdminDashboard(
            repository: repo,
            authService: authService,
          ),
        ),
      );
      await tester.pumpAndSettle();

      await tester.tap(find.text('Fleet/Controls'));
      await tester.pumpAndSettle();

      expect(find.text('System Controls'), findsOneWidget);
      expect(find.text('Fleet Management'), findsOneWidget);
      expect(find.text('Personnel & Dispatch Controls'), findsOneWidget);
      expect(find.text('Operational Boundaries'), findsOneWidget);
      expect(find.text('Emergency Override'), findsOneWidget);
      expect(find.text('Supervisor PIN Setup'), findsOneWidget);
      expect(find.text('Cloud Gateway Configuration'), findsOneWidget);
      expect(find.text('Finalize Shift & Sign Out'), findsOneWidget);

      // Open Supervisor PIN setup
      await tester.ensureVisible(find.text('Supervisor PIN Setup'));
      await tester.tap(find.text('Supervisor PIN Setup'));
      await tester.pumpAndSettle();

      expect(find.text('Administrator Account'), findsOneWidget);
      expect(find.text('Supervisor Authorization PIN:'), findsOneWidget);
      expect(find.text('Save PIN'), findsOneWidget);
      await tester.tap(find.text('Close'));
      await tester.pumpAndSettle();

      // Open Finalize Shift & Sign Out
      await tester.ensureVisible(find.text('Finalize Shift & Sign Out'));
      await tester.tap(find.text('Finalize Shift & Sign Out'));
      await tester.pumpAndSettle();
      expect(find.byType(AdminSessionEndedView), findsOneWidget);
    });

    testWidgets('Live Dispatch Map handles interactive vehicle taps and zoom controls', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: LiveDispatchMap(height: 300),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Active Map View'), findsOneWidget);
      expect(find.text('T1: En Route to Shop 14'), findsOneWidget);

      // Tap zoom controls
      await tester.tap(find.byTooltip('Zoom in'));
      await tester.pumpAndSettle();
      await tester.tap(find.byTooltip('Center Arua City'));
      await tester.pumpAndSettle();
    });

    testWidgets('Responsive Frame Sizes: renders without overflow on phone, tablet, and desktop', (
      WidgetTester tester,
    ) async {
      // 1. Phone Viewport (< 600px)
      await tester.binding.setSurfaceSize(const Size(380, 800));
      await tester.pumpWidget(
        MaterialApp(
          home: AdminDashboard(
            repository: repo,
            authService: authService,
          ),
        ),
      );
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);

      // 2. Tablet Viewport (600 - 1024px)
      await tester.binding.setSurfaceSize(const Size(768, 1024));
      await tester.pumpWidget(
        MaterialApp(
          home: AdminDashboard(
            repository: repo,
            authService: authService,
          ),
        ),
      );
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);

      // 3. Desktop Viewport (> 1024px)
      await tester.binding.setSurfaceSize(const Size(1280, 800));
      await tester.pumpWidget(
        MaterialApp(
          home: AdminDashboard(
            repository: repo,
            authService: authService,
          ),
        ),
      );
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);

      // Reset surface size
      await tester.binding.setSurfaceSize(null);
    });

    testWidgets('Rider 2FA Email Sign-In flow authorizes rider using email OTP', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(
        MaterialApp(
          home: LoginScreen(
            repository: repo,
            authService: authService,
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.byKey(const ValueKey('login_rider_2fa_button')), findsOneWidget);
      await tester.ensureVisible(find.byKey(const ValueKey('login_rider_2fa_button')));
      await tester.tap(find.byKey(const ValueKey('login_rider_2fa_button')));
      await tester.pumpAndSettle();

      expect(find.text('2FA Email Verification'), findsOneWidget);
      await tester.enterText(
        find.byKey(const ValueKey('rider_2fa_email_input')),
        'peter.rider@ecoroute.ug',
      );
      await tester.enterText(
        find.byKey(const ValueKey('rider_2fa_otp_input')),
        '123456',
      );
      await tester.tap(find.byKey(const ValueKey('rider_2fa_verify_button')));
      await tester.pumpAndSettle();

      expect(find.byType(RiderTaskHub), findsOneWidget);
    });

    testWidgets('Offline working capabilities: User fills all details in OrderPage and receives clear offline notice', (
      WidgetTester tester,
    ) async {
      tester.view.physicalSize = const Size(1080, 2400);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() => tester.view.resetPhysicalSize());

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: OrderPage(
              isOnline: false,
              onSubmitted: (req) async => repo.save(req),
              initialPhone: '+256772001122',
              initialAddress: 'Pakwach Road, Arua',
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Verify offline banner is shown
      expect(find.text('Offline Mode Active'), findsOneWidget);

      // Select household waste chip
      await tester.ensureVisible(find.text('Household (1.5k)'));
      await tester.tap(find.text('Household (1.5k)'));
      await tester.pumpAndSettle();

      // Enter collection details
      await tester.ensureVisible(find.widgetWithText(TextFormField, 'Collection details'));
      await tester.enterText(
        find.widgetWithText(TextFormField, 'Collection details'),
        'Plastic sacks outside residence in Arua',
      );
      await tester.pumpAndSettle();

      // Submit while offline
      await tester.ensureVisible(find.text('Submit collection order'));
      await tester.tap(find.text('Submit collection order'));
      await tester.pumpAndSettle();

      // Verify polite offline notification is shown
      expect(
        find.text(
          'Offline Mode Active: Your pickup request has been saved securely to your device. It will automatically synchronize with Arua Dispatch as soon as your connection is restored.',
        ),
        findsOneWidget,
      );

      // Verify request is saved in repo
      final all = await repo.loadAll();
      expect(all.any((r) => r.description == 'Plastic sacks outside residence in Arua'), isTrue);
    });

    testWidgets('Redesigned Admin Accounts switcher toggles between municipal administrators', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(
        MaterialApp(
          home: AdminDashboard(
            repository: repo,
            authService: authService,
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Open admin account dialog
      await tester.tap(find.byKey(const ValueKey('admin_topbar_profile_button')));
      await tester.pumpAndSettle();

      expect(find.text('Administrator Account'), findsOneWidget);
      expect(find.text('Switch Municipal Administrator:'), findsOneWidget);
      expect(find.textContaining('Geoffrey Ayiko (#A-9014)'), findsOneWidget);
      expect(find.textContaining('Savior Deo Gratius (#A-4019)'), findsOneWidget);

      // Switch to Savior Deo Gratius
      await tester.tap(find.textContaining('Savior Deo Gratius (#A-4019)'));
      await tester.pumpAndSettle();

      expect(find.text('Admin ID: #A-4019'), findsOneWidget);
      expect(find.text('saviordeogratius@gmail.com'), findsOneWidget);

      await tester.tap(find.text('Close'));
      await tester.pumpAndSettle();
    });

    testWidgets('Top Bar Connection Status indicator toggles Online/Offline on tap', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(
        MaterialApp(
          home: AdminDashboard(
            repository: repo,
            authService: authService,
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Command HQ • Online'), findsOneWidget);

      // Tap status badge
      await tester.tap(find.byKey(const ValueKey('admin_connection_status_badge')));
      await tester.pumpAndSettle();

      expect(find.text('Command HQ • Offline'), findsOneWidget);

      // Tap again to restore
      await tester.tap(find.byKey(const ValueKey('admin_connection_status_badge')));
      await tester.pumpAndSettle();

      expect(find.text('Command HQ • Online'), findsOneWidget);
    });
  });
}
