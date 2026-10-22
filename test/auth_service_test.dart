import 'package:ecoroute/core/services/auth_service.dart';
import 'package:ecoroute/domain/enums/role.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('AuthService (Week 10 Authentication & Cloud Data)', () {
    late SharedPreferences preferences;
    late AuthService authService;

    setUp(() async {
      SharedPreferences.setMockInitialValues({});
      preferences = await SharedPreferences.getInstance();
      authService = AuthService(preferences);
    });

    test('logs in built-in demo accounts successfully', () async {
      final user = await authService.login(
        email: 'resident@ecoroute.demo',
        password: 'demo123',
      );

      expect(user, isNotNull);
      expect(user!.role, AppRole.resident);
      expect(user.fullName, contains('Amina Dranzoa'));

      // Verify persistent session
      final restored = authService.getCurrentUser();
      expect(restored?.email, 'resident@ecoroute.demo');
    });

    test('rejects incorrect credentials', () async {
      final user = await authService.login(
        email: 'resident@ecoroute.demo',
        password: 'wrong_password',
      );

      expect(user, isNull);
      expect(authService.getCurrentUser(), isNull);
    });

    test('registers new resident account and restores session across restart', () async {
      final registered = await authService.register(
        fullName: 'Kezia Candia',
        email: 'kezia@example.ug',
        phone: '+256 772 999 888',
        password: 'securePass1',
      );

      expect(registered.fullName, 'Kezia Candia');
      expect(registered.role, AppRole.resident);

      // Verify session immediately active
      expect(authService.getCurrentUser()?.email, 'kezia@example.ug');

      // Logout
      await authService.logout();
      expect(authService.getCurrentUser(), isNull);

      // Log back in with registered credentials
      final reLoggedIn = await authService.login(
        email: 'kezia@example.ug',
        password: 'securePass1',
      );
      expect(reLoggedIn?.fullName, 'Kezia Candia');
    });
  });
}
