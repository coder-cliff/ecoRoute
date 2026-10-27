import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;

/// Service to dispatch official collection rider invitations using
/// the Google Apps Script MailApp API (ecoroute.waste@gmail.com).
class RiderInviteService {
  const RiderInviteService._();

  static const String defaultAppUrl = 'https://coder-cliff.github.io/ecoRoute/';

  /// Google Apps Script Web App Endpoint deployed with MailApp privileges.
  /// Update with your active Deployment ID from Google Apps Script.
  static String scriptUrl =
      'https://script.google.com/macros/s/AKfycbyEcoRouteRiderInviteGateway/exec';

  /// Sends an official invitation email to the rider via Google Apps Script MailApp.
  /// Uses text/plain to avoid CORS preflight issues on Flutter Web.
  static Future<bool> sendRiderInviteEmail({
    required String riderEmail,
    required String riderName,
    String? inviteLink,
    String? customScriptUrl,
    http.Client? httpClient,
  }) async {
    final client = httpClient ?? http.Client();
    final targetUrl = customScriptUrl ?? scriptUrl;
    final effectiveInviteLink = inviteLink ?? defaultAppUrl;

    try {
      final response = await client.post(
        Uri.parse(targetUrl),
        headers: {'Content-Type': 'text/plain;charset=utf-8'},
        body: jsonEncode({
          'email': riderEmail.trim().toLowerCase(),
          'name': riderName.trim(),
          'inviteLink': effectiveInviteLink,
        }),
      );

      // Google Apps Script redirects with HTTP 302 on success or returns HTTP 200
      if (response.statusCode == 200 || response.statusCode == 302) {
        debugPrint('Rider invitation dispatched successfully to $riderEmail');
        return true;
      }

      debugPrint('Google Apps Script responded with code: ${response.statusCode}');
      return false;
    } catch (e) {
      debugPrint('Error sending rider invite via Google MailApp: $e');
      return false;
    } finally {
      if (httpClient == null) {
        client.close();
      }
    }
  }
}
