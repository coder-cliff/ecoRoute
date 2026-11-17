import 'package:ecoroute/core/pickup_request_repository.dart';
import 'package:ecoroute/core/services/auth_service.dart';
import 'package:ecoroute/core/services/waste_api_service.dart';
import 'package:ecoroute/domain/entities/app_user.dart';
import 'package:ecoroute/domain/enums/role.dart';
import 'package:ecoroute/features/auth/role_select_screen.dart';
import 'package:ecoroute/features/resident/responsive_resident_dashboard.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('Role Boundaries Tests', () {
    late SharedPreferences preferences;
    late AuthService authService;
    late PickupRequestRepository repository;
    late WasteApiService wasteApiService;

    setUp(() async {
      SharedPreferences.setMockInitialValues({});
      preferences = await SharedPreferences.getInstance();
      authService = AuthService(preferences);
      repository = PickupRequestRepository();
      wasteApiService = WasteApiService();
    });

    testWidgets('RoleSelectScreen blocks unauthenticated user from selecting Admin', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: RoleSelectScreen(
            repository: repository,
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
  });
}
