import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:url_launcher/url_launcher.dart';

/// Service to dispatch official collection rider invitations using
/// the Google Apps Script MailApp API (ecoroute.waste@gmail.com)
/// or via direct mail client fallback (mailto:).
class RiderInviteService {
  const RiderInviteService._();

  static const String defaultAppUrl = 'https://coder-cliff.github.io/ecoRoute/';
  static const String _prefScriptUrlKey = 'ecoroute_google_apps_script_url_v1';

  /// Default Google Apps Script Web App endpoint.
  /// Can be overridden dynamically by the admin or persisted via SharedPreferences.
  static String scriptUrl =
      'https://script.google.com/macros/s/AKfycbyEcoRouteRiderInviteGateway/exec';

  /// Loads the persisted Google Apps Script URL if saved by the admin
  static Future<String> getEffectiveScriptUrl([SharedPreferences? prefs]) async {
    try {
      final p = prefs ?? await SharedPreferences.getInstance();
      final saved = p.getString(_prefScriptUrlKey);
      if (saved != null && saved.trim().isNotEmpty) {
        scriptUrl = saved.trim();
      }
    } catch (_) {}
    return scriptUrl;
  }

  /// Persists a custom Google Apps Script Web App URL
  static Future<void> saveScriptUrl(String url, [SharedPreferences? prefs]) async {
    scriptUrl = url.trim();
    try {
      final p = prefs ?? await SharedPreferences.getInstance();
      await p.setString(_prefScriptUrlKey, scriptUrl);
    } catch (_) {}
  }

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
    final targetUrl = customScriptUrl ?? await getEffectiveScriptUrl();
    final effectiveInviteLink = inviteLink ?? defaultAppUrl;

    // Detect if targetUrl is still the placeholder
    if (targetUrl.contains('AKfycbyEcoRouteRiderInviteGateway') ||
        targetUrl.contains('YOUR_DEPLOYMENT_ID')) {
      debugPrint('Google Apps Script URL is a placeholder. Web App deployment required.');
      return false;
    }

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

  /// Opens the device default email application (Gmail, Outlook, Apple Mail)
  /// with pre-filled recipient, official subject, and invitation body.
  static Future<bool> openEmailClient({
    required String riderEmail,
    required String riderName,
    required String inviteLink,
  }) async {
    final subject = 'EcoRoute Arua — Official Rider Invitation';
    final body = '''
Hello $riderName,

You have been officially invited to join the EcoRoute Municipal Waste Logistics team as an authorized collection rider serving Arua City.

Click the link below to accept your invitation, verify your credentials, and access your live rider dispatch board:
$inviteLink

Sent officially by EcoRoute Waste Management (ecoroute.waste@gmail.com)
Arua City, West Nile, Uganda
''';

    final emailLaunchUri = Uri(
      scheme: 'mailto',
      path: riderEmail.trim(),
      queryParameters: {
        'subject': subject,
        'body': body,
      },
    );

    try {
      return await launchUrl(
        emailLaunchUri,
        mode: LaunchMode.externalApplication,
      );
    } catch (e) {
      debugPrint('Could not launch mail client: $e');
      return false;
    }
  }
}
