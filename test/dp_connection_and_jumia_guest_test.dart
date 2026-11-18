import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:ecoroute/core/services/auth_service.dart';
import 'package:ecoroute/domain/enums/role.dart';
import 'package:ecoroute/main.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late SharedPreferences prefs;
  late AuthService authService;

  const samplePhotoA = 'data:image/jpeg;base64,iVBORw0KGgoAAAANSUhEUgAAAAEAAAABCAYAAAAfFcSJAAAADUlEQVR42mP8z8BQDwAEhQGAhKmMIQAAAABJRU5ErkJggg==';
  const samplePhotoB = 'data:image/jpeg;base64,iVBORw0KGgoAAAANSUhEUgAAAAEAAAABCAYAAAAfFcSJAAAADUlEQVR42mNk+M9QDwADhgGAWjR9awAAAABJRU5ErkJggg==';

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    prefs = await SharedPreferences.getInstance();
    authService = AuthService(prefs);
    EcoRouteState.instance.authService = authService;
    EcoRouteState.instance.isGuest = true;
    EcoRouteState.instance.currentRole = 'resident';
    EcoRouteState.instance.userName = 'Guest User';
    EcoRouteState.instance.userEmail = 'guest@ecoroute.ug';
    EcoRouteState.instance.userPhotoBase64 = null;
  });

  group('Per-Account DP Isolation (Each account has its own DP)', () {
    test('AuthService stores and retrieves dedicated DP per account without leakage', () async {
      // 1. Register User A with a custom DP
      final userA = await authService.register(
        fullName: 'Kezia Candia',
        email: 'kezia@ecoroute.ug',
        phone: '+256772111222',
        password: 'passwordA123',
        photoUrl: samplePhotoA,
      );
      expect(userA.photoUrl, samplePhotoA);
      expect(authService.getPhotoForUser('kezia@ecoroute.ug'), samplePhotoA);

      // 2. Register User B without any DP
      final userB = await authService.register(
        fullName: 'Baker Anguzu',
        email: 'baker@ecoroute.ug',
        phone: '+256772333444',
        password: 'passwordB123',
      );
      expect(userB.photoUrl, isNull);
      expect(authService.getPhotoForUser('baker@ecoroute.ug'), isNull);

      // 3. Log in User B - verify User B does NOT inherit User A's DP
      final loggedInB = await authService.login(email: 'baker@ecoroute.ug', password: 'passwordB123');
      expect(loggedInB, isNotNull);
      expect(loggedInB!.photoUrl, isNull);

      // 4. User B sets their own DP B
      final updatedB = await authService.updateProfilePhoto(samplePhotoB);
      expect(updatedB.photoUrl, samplePhotoB);
      expect(authService.getPhotoForUser('baker@ecoroute.ug'), samplePhotoB);

      // 5. Verify User A's DP remains strictly DP A
      expect(authService.getPhotoForUser('kezia@ecoroute.ug'), samplePhotoA);

      // 6. User B logs out -> session is wiped, guest has no DP
      await authService.logout();
      expect(authService.getCurrentUser(), isNull);
      expect(authService.getPhotoForUser('guest@ecoroute.ug'), isNull);
    });

    test('EcoRouteState preserves account-specific DP across switching and wipes on logout', () async {
      final state = EcoRouteState.instance;

      // Authenticate User A with DP A
      state.setAuthenticatedUser(
        role: 'resident',
        name: 'Kezia Candia',
        email: 'kezia@ecoroute.ug',
        phone: '+256772111222',
        photoBase64: samplePhotoA,
      );
      expect(state.isGuest, isFalse);
      expect(state.userPhotoBase64, samplePhotoA);
      expect(state.getDpForAccount('kezia@ecoroute.ug'), samplePhotoA);

      // Switch to User B (no photo provided) -> must NOT inherit User A's photo
      state.setAuthenticatedUser(
        role: 'resident',
        name: 'Baker Anguzu',
        email: 'baker@ecoroute.ug',
        phone: '+256772333444',
      );
      expect(state.userPhotoBase64, isNull);

      // User B updates DP to samplePhotoB
      state.updateProfile(
        name: 'Baker Anguzu',
        username: 'baker_arua',
        phone: '+256772333444',
        cell: 'Arua Hill',
        photoBase64: samplePhotoB,
      );
      expect(state.userPhotoBase64, samplePhotoB);
      expect(state.getDpForAccount('baker@ecoroute.ug'), samplePhotoB);

      // Switch back to User A -> restores DP A
      state.setAuthenticatedUser(
        role: 'resident',
        name: 'Kezia Candia',
        email: 'kezia@ecoroute.ug',
        phone: '+256772111222',
      );
      expect(state.userPhotoBase64, samplePhotoA);

      // Logout -> strictly wipes active DP for Guest mode
      await state.logout();
      expect(state.isGuest, isTrue);
      expect(state.userPhotoBase64, isNull);
      expect(state.userName, 'Guest User');
    });

    testWidgets('buildSafeUserAvatar renders Jumia guest icon for guest and image for authenticated user', (
      tester,
    ) async {
      // 1. Guest Avatar test
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Builder(
              builder: (context) => buildSafeUserAvatar(
                context: context,
                photoBase64: null,
                name: 'Guest User',
                isGuest: true,
                radius: 30,
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Guest avatar renders person_outline icon
      expect(find.byIcon(Icons.person_outline), findsOneWidget);

      // 2. Authenticated user with DP test
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Builder(
              builder: (context) => buildSafeUserAvatar(
                context: context,
                photoBase64: samplePhotoA,
                name: 'Kezia Candia',
                isGuest: false,
                radius: 30,
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Image memory widget rendered inside ClipOval
      expect(find.byType(ClipOval), findsOneWidget);
      expect(find.byType(Image), findsOneWidget);
    });
  });

  group('Jumia UG Style Guest User Interactions', () {
    testWidgets('ResidentProfileTabScreen renders Jumia UG welcome banner, benefits, and sign-in CTAs for guest', (
      tester,
    ) async {
      final state = EcoRouteState.instance;
      state.isGuest = true;
      state.userName = 'Guest User';
      state.userPhotoBase64 = null;

      await tester.pumpWidget(
        const MaterialApp(
          home: ResidentProfileTabScreen(),
        ),
      );
      await tester.pumpAndSettle();

      // Jumia UG style greeting
      expect(find.text('Welcome to EcoRoute'), findsOneWidget);
      expect(find.text('Guest'), findsOneWidget);
      expect(find.text('Enter your account to access pickups, receipts, and Eco-Credits'), findsOneWidget);

      // Jumia UG style privileges card
      expect(find.text('Unlock Full Resident Privileges'), findsOneWidget);
      expect(find.text('• 150 Municipal Eco-Credits welcome bonus'), findsOneWidget);
      expect(find.text('• Save default pickup addresses & digital receipts'), findsOneWidget);
      expect(find.text('• Real-time SMS & WhatsApp dispatch tracking'), findsOneWidget);

      // Actions
      expect(find.text('Sign In'), findsWidgets);
      expect(find.text('Register'), findsOneWidget);
      expect(find.text('Sign In to Existing Account'), findsOneWidget);

      // Hotline & WhatsApp
      expect(find.text('Operations Hotline (+256 394 880 352)'), findsOneWidget);
      expect(find.text('WhatsApp Operations Desk'), findsOneWidget);
    });

    testWidgets('ResidentHomeScreen renders Jumia UG guest banner with quick Sign In pill', (
      tester,
    ) async {
      final state = EcoRouteState.instance;
      state.isGuest = true;
      state.userPhotoBase64 = null;

      await tester.pumpWidget(
        MaterialApp(
          home: ResidentHomeScreen(
            pickup: null,
            onBookPickup: () {},
            onOpenMap: () {},
            onReportIssue: () {},
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Hello, Guest Explorer'), findsOneWidget);
      expect(find.text('Arua Municipality • Tap to Sign In'), findsOneWidget);
      expect(find.text('Browsing as Guest (Jumia Style)'), findsOneWidget);
      expect(find.text('Browse waste rates & schedules freely. Sign in to earn 150 Eco-Credits!'), findsOneWidget);
    });

    testWidgets('ResidentRequestsScreen renders Jumia UG empty state with Book and Sign In options for guest', (
      tester,
    ) async {
      final state = EcoRouteState.instance;
      state.isGuest = true;

      await tester.pumpWidget(
        MaterialApp(
          home: ResidentRequestsScreen(
            requests: const [],
            onBookPickup: () {},
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text("You're Exploring as Guest"), findsOneWidget);
      expect(
        find.text('Book a pickup to track your tricycle in real-time, or sign in to sync your collection history across devices.'),
        findsOneWidget,
      );
      expect(find.text('Book a Pickup'), findsOneWidget);
      expect(find.text('Sign In'), findsOneWidget);
    });
  });
}
