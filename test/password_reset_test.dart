import 'package:ecoroute/core/services/auth_service.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('Password Reset Flow Tests', () {
    late SharedPreferences preferences;
    late AuthService authService;

    setUp(() async {
      SharedPreferences.setMockInitialValues({});
      preferences = await SharedPreferences.getInstance();
      authService = AuthService(preferences);
    });

    test('rejects empty or invalid email format', () async {
      expect(
        () => authService.sendPasswordResetEmail(''),
        throwsA(isA<AuthException>()),
      );
      expect(
        () => authService.sendPasswordResetEmail('invalid-email'),
        throwsA(isA<AuthException>()),
      );
    });

    test('rejects unregistered email when offline', () async {
      expect(
        () => authService.sendPasswordResetEmail('unknown.user@example.com'),
        throwsA(isA<AuthException>()),
      );
    });

    test('triggers password reset handler for registered email', () async {
      String? sentTo;
      authService.passwordResetHandler = (email) async {
        sentTo = email;
      };

      await authService.sendPasswordResetEmail('resident.arua@ecoroute.ug');
      expect(sentTo, 'resident.arua@ecoroute.ug');
    });

    test('allows designated admin email to trigger password reset', () async {
      String? sentTo;
      authService.passwordResetHandler = (email) async {
        sentTo = email;
      };

      await authService.sendPasswordResetEmail('ayikog@yahoo.com');
      expect(sentTo, 'ayikog@yahoo.com');
    });
  });
}
