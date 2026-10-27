import 'dart:convert';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';

import 'package:ecoroute/core/services/rider_invite_service.dart';

void main() {
  group('RiderInviteService (Google Apps Script MailApp API)', () {
    test('sends email invite using text/plain body to avoid CORS', () async {
      String? capturedContentType;
      String? capturedBody;

      final mockClient = MockClient((request) async {
        capturedContentType = request.headers['Content-Type'];
        capturedBody = request.body;

        return http.Response(
          jsonEncode({'status': 'sent', 'recipient': 'rider@ecorute.ug'}),
          200,
        );
      });

      final success = await RiderInviteService.sendRiderInviteEmail(
        riderEmail: 'rider@ecorute.ug',
        riderName: 'John Baptist',
        inviteLink: 'https://coder-cliff.github.io/ecoRoute/?invite=TEST123',
        httpClient: mockClient,
      );

      expect(success, isTrue);
      expect(capturedContentType, 'text/plain;charset=utf-8');

      final decoded = jsonDecode(capturedBody!) as Map<String, dynamic>;
      expect(decoded['email'], 'rider@ecorute.ug');
      expect(decoded['name'], 'John Baptist');
      expect(decoded['inviteLink'], 'https://coder-cliff.github.io/ecoRoute/?invite=TEST123');
    });

    test('treats HTTP 302 redirect as success for Google Apps Script execution', () async {
      final mockClient = MockClient((request) async {
        return http.Response('', 302);
      });

      final success = await RiderInviteService.sendRiderInviteEmail(
        riderEmail: 'rider@ecorute.ug',
        riderName: 'Rider Two',
        httpClient: mockClient,
      );

      expect(success, isTrue);
    });

    test('returns false gracefully when HTTP request fails', () async {
      final mockClient = MockClient((request) async {
        return http.Response('Server Error', 500);
      });

      final success = await RiderInviteService.sendRiderInviteEmail(
        riderEmail: 'error@ecorute.ug',
        riderName: 'Error Rider',
        httpClient: mockClient,
      );

      expect(success, isFalse);
    });
  });
}
