import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:ecoroute/core/pickup_request_repository.dart';
import 'package:ecoroute/core/services/auth_service.dart';
import 'package:ecoroute/core/services/router_service.dart';
import 'package:ecoroute/core/services/waste_api_service.dart';
import 'package:ecoroute/domain/entities/app_user.dart';
import 'package:ecoroute/domain/entities/pickup_request.dart';
import 'package:ecoroute/domain/enums/request_status.dart';
import 'package:ecoroute/domain/enums/role.dart';
import 'package:ecoroute/domain/enums/waste_type.dart';
import 'package:ecoroute/features/admin/admin_dashboard.dart';
import 'package:ecoroute/features/auth/login_screen.dart';
import 'package:ecoroute/features/auth/role_select_screen.dart';
import 'package:ecoroute/features/home/home_screen.dart';
import 'package:ecoroute/features/profile/widgets/profile_settings_view.dart';
import 'package:ecoroute/features/resident/responsive_resident_dashboard.dart';
import 'package:ecoroute/features/rider/rider_task_hub.dart';

class _MockRepo implements PickupRequestRepository {
  _MockRepo([List<PickupRequest>? initial]) : _requests = initial ?? [];

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
    final index = _requests.indexWhere((r) => r.id == id);
    if (index >= 0) {
      _requests[index] = _requests[index].copyWith(status: status);
    }
  }

  @override
  Future<void> delete(String id) async {
    _requests.removeWhere((r) => r.id == id);
  }

  @override
  Future<void> seedDemoData({bool force = false}) async {}
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late SharedPreferences prefs;
  late AuthService authService;

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    prefs = await SharedPreferences.getInstance();
    authService = AuthService(prefs);
  });

  group('Role Boundaries & Isolation Tests', () {
    testWidgets('RoleSelectScreen blocks unauthenticated user from selecting Admin', (tester) async {
      final repo = const MemoryPickupRequestRepository();
      final wasteApiService = WasteApiService();

      await tester.pumpWidget(
        MaterialApp(
          home: RoleSelectScreen(
            repository: repo,
            authService: authService,
            wasteApiService: wasteApiService,
          ),
        ),
      );

      // Tap Admin card
      final adminCard = find.byKey(const ValueKey('role_card_admin'));
      expect(adminCard, findsOneWidget);
      await tester.tap(adminCard);
      await tester.pumpAndSettle();

      // Tap continue
      final continueButton = find.byKey(const ValueKey('role_continue_button'));
      expect(continueButton, findsOneWidget);
      await tester.tap(continueButton);
      await tester.pumpAndSettle();

      // Should show SnackBar requiring authentication and not enter admin dashboard
      expect(find.textContaining('Admin access requires verified authentication'), findsOneWidget);
    });

    testWidgets('ResponsiveResidentDashboard does NOT contain Fleet Settings', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: ResponsiveResidentDashboard(),
        ),
      );
      await tester.pumpAndSettle();

      // Verify that "Fleet Settings" is absent
      expect(find.text('Fleet Settings'), findsNothing);
      expect(find.textContaining('Electric Tricycles assigned to Arua Central'), findsNothing);
    });

    testWidgets('Resident view displays My Profile and excludes fleet & role switching cards', (
      tester,
    ) async {
      final repo = _MockRepo();
      await tester.pumpWidget(
        MaterialApp(
          home: EcoRouteHomeScreen(
            repository: repo,
            authService: authService,
            enforcedRole: AppRole.resident,
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Positively assert resident action cards
      expect(find.text('My Profile'), findsOneWidget);
      expect(find.text('Take rubbish photo'), findsOneWidget);

      // Negatively assert misplaced role switching and admin fleet tools
      expect(find.text('Account & role'), findsNothing);
      expect(find.text('Fleet Management'), findsNothing);
      expect(find.text('Invite Rider'), findsNothing);
    });

    testWidgets('Rider empty orders state displays dispatcher info and removes resident booking button', (
      tester,
    ) async {
      final repo = _MockRepo([]);
      await tester.pumpWidget(
        MaterialApp(
          home: EcoRouteHomeScreen(
            repository: repo,
            authService: authService,
            enforcedRole: AppRole.rider,
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Navigate to Orders tab (second bottom navigation tab)
      await tester.tap(find.byIcon(Icons.receipt_long_outlined));
      await tester.pumpAndSettle();

      // Assert rider-appropriate empty queue message
      expect(
        find.text(
          'No assigned collection stops. New pickup tasks will appear when dispatched by Municipal HQ.',
        ),
        findsOneWidget,
      );

      // Assert resident pickup booking actions are strictly absent
      expect(find.text('Request Instant Pickup'), findsNothing);
      expect(
        find.text('Book an instant waste pickup and local tricycle riders will be dispatched.'),
        findsNothing,
      );
    });

    testWidgets('Rider orders list excludes resident cancellation button', (
      tester,
    ) async {
      final request = PickupRequest(
        id: 'order-boundary-1',
        wasteType: WasteType.household,
        description: 'Bazaar division pickup',
        submittedAt: DateTime.now(),
        status: RequestStatus.requested,
        residentId: 'resident-1',
        address: 'Bazaar St 4',
      );
      final repo = _MockRepo([request]);

      await tester.pumpWidget(
        MaterialApp(
          home: EcoRouteHomeScreen(
            repository: repo,
            authService: authService,
            enforcedRole: AppRole.rider,
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Go to orders tab
      await tester.tap(find.byIcon(Icons.receipt_long_outlined));
      await tester.pumpAndSettle();

      // Rider cannot cancel resident request
      expect(find.byTooltip('Cancel Request'), findsNothing);
    });

    testWidgets('Resident orders list includes cancellation button on requested pickups', (
      tester,
    ) async {
      final request = PickupRequest(
        id: 'order-boundary-2',
        wasteType: WasteType.household,
        description: 'Rhino camp road pickup',
        submittedAt: DateTime.now(),
        status: RequestStatus.requested,
        residentId: 'resident-1',
        address: 'Rhino Camp Rd',
      );
      final repo = _MockRepo([request]);

      await tester.pumpWidget(
        MaterialApp(
          home: EcoRouteHomeScreen(
            repository: repo,
            authService: authService,
            enforcedRole: AppRole.resident,
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Go to orders tab
      await tester.tap(find.byIcon(Icons.receipt_long_outlined));
      await tester.pumpAndSettle();

      // Resident CAN cancel their pending request
      expect(find.byTooltip('Cancel Request'), findsOneWidget);
    });

    testWidgets('ProfileSettingsView excludes resident eco impact & reminders for rider role', (
      tester,
    ) async {
      const riderUser = AppUser(
        id: 'rider-user-1',
        fullName: 'Patrick Rider',
        email: 'rider.test@ecoroute.ug',
        phone: '+256772111222',
        role: AppRole.rider,
      );
      final repo = _MockRepo();

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: ProfileSettingsView(
              currentUser: riderUser,
              role: AppRole.rider,
              orders: const [],
              repository: repo,
              authService: authService,
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Resident-specific impact metrics and reminder policy must be absent
      expect(find.text('Environmental & Lifecycle Impact'), findsNothing);
      expect(find.text('Pickup schedule reminders'), findsNothing);
      expect(find.text('Arua Eco Champion'), findsNothing);
    });

    testWidgets('ProfileSettingsView includes eco impact & reminders for resident role', (
      tester,
    ) async {
      const residentUser = AppUser(
        id: 'resident-user-1',
        fullName: 'Jane Resident',
        email: 'jane.resident@example.ug',
        phone: '+256772333444',
        role: AppRole.resident,
      );
      final repo = _MockRepo();

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: ProfileSettingsView(
              currentUser: residentUser,
              role: AppRole.resident,
              orders: const [],
              repository: repo,
              authService: authService,
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Resident-specific impact metrics and reminder policy must be present
      expect(find.text('Environmental & Lifecycle Impact'), findsOneWidget);
      expect(find.text('Pickup schedule reminders'), findsOneWidget);
    });

    testWidgets('AppRouter guards unauthenticated access to admin and rider screens', (
      tester,
    ) async {
      final repo = _MockRepo();

      // Unauthenticated admin attempt
      final adminScreen = AppRouter.getScreenForRole(
        role: AppRole.admin,
        repository: repo,
        authService: authService,
      );
      expect(adminScreen, isA<LoginScreen>());

      // Unauthenticated rider attempt
      final riderScreen = AppRouter.getScreenForRole(
        role: AppRole.rider,
        repository: repo,
        authService: authService,
      );
      expect(riderScreen, isA<LoginScreen>());

      // Unauthenticated resident attempt safely defaults to EcoRouteHomeScreen
      final residentScreen = AppRouter.getScreenForRole(
        role: AppRole.resident,
        repository: repo,
        authService: authService,
      );
      expect(residentScreen, isA<EcoRouteHomeScreen>());
    });

    testWidgets('AppRouter allows authorized access when authenticated', (
      tester,
    ) async {
      final repo = _MockRepo();

      // Register official admin
      await authService.register(
        fullName: 'Admin Official',
        email: 'ayikog@yahoo.com',
        phone: '+256394880352',
        password: 'AdminPassword@2026',
        role: AppRole.admin,
      );

      final adminScreen = AppRouter.getScreenForRole(
        role: AppRole.admin,
        repository: repo,
        authService: authService,
      );
      expect(adminScreen, isA<AdminDashboard>());
    });
  });
}
