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
  static const String defaultApkUrl = 'https://github.com/coder-cliff/ecoRoute/releases/latest/download/app-release.apk';
  static const String _prefScriptUrlKey = 'ecoroute_google_apps_script_url_v1';

  /// Default Google Apps Script Web App endpoint.
  /// Can be overridden dynamically by the admin or persisted via SharedPreferences.
  static String scriptUrl =
      'https://script.google.com/macros/s/AKfycbzC-HGLSimx4BSNLAJeMlG6b51cy5emlVEUayxuTY21u7i8qyx5YV8zEfTMwKDG2NWYgg/exec';

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

  /// Builds the authoritative rider 1-click activation link (Option 1)
  static String buildRiderInviteUrl({
    required String inviteCode,
    required String email,
    String? tricycleId,
  }) {
    final cleanEmail = Uri.encodeComponent(email.trim().toLowerCase());
    final cleanCode = Uri.encodeComponent(inviteCode.trim());
    final tricParam = tricycleId != null ? '&tric=${Uri.encodeComponent(tricycleId.trim())}' : '';
    // Format hash routing with dual query params for 100% router compatibility
    return '$defaultAppUrl#/rider-setup?code=$cleanCode&invite=$cleanCode&email=$cleanEmail$tricParam';
  }

  /// Direct Android APK download URL
  static String buildApkDownloadUrl() => defaultApkUrl;

  /// Sends an official invitation email to the rider via Google Apps Script MailApp.
  /// Uses text/plain to avoid CORS preflight issues on Flutter Web.
  static Future<bool> sendRiderInviteEmail({
    required String riderEmail,
    required String riderName,
    String? inviteLink,
    String? inviteCode,
    String? tricycleId,
    String? apkLink,
    String? customScriptUrl,
    http.Client? httpClient,
  }) async {
    final client = httpClient ?? http.Client();
    final targetUrl = customScriptUrl ?? await getEffectiveScriptUrl();
    final effectiveInviteLink = inviteLink ??
        (inviteCode != null
            ? buildRiderInviteUrl(inviteCode: inviteCode, email: riderEmail, tricycleId: tricycleId)
            : defaultAppUrl);
    final effectiveApkLink = apkLink ?? defaultApkUrl;

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
          'apkLink': effectiveApkLink,
          'inviteCode': inviteCode,
          'tricycleId': tricycleId,
          'subject': 'EcoRoute Arua: Official Rider Authorization & Tricycle Assignment',
          'senderName': 'EcoRoute Fleet Operations (Arua City Council)',
        }),
      );

      // Google Apps Script redirects with HTTP 302 on success or returns HTTP 200
      if (response.statusCode == 200 || response.statusCode == 302) {
        if (response.body.isNotEmpty) {
          try {
            final decoded = jsonDecode(response.body);
            if (decoded is Map<String, dynamic> && decoded['status'] == 'error') {
              debugPrint('Google Apps Script execution error: ${decoded['message']}');
              return false;
            }
          } catch (_) {}
        }
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
    String? inviteCode,
    String? tricycleId,
  }) async {
    final subject = 'EcoRoute Arua: Official Rider Authorization & Tricycle Assignment';
    final body = '''
Hello $riderName,

Welcome to the EcoRoute collection team for Arua City.

An official rider dispatch account has been authorized for you by Arua City Council Fleet Operations for the municipal tricycle waste collection fleet serving Ayivu, Central Division, and Muni University.

Your Authorization Details:
- Driver Name: $riderName
- Assigned Tricycle: ${tricycleId ?? 'TRIC-04 (Ediofe Depot)'}
- Authorization Token: ${inviteCode ?? 'Authorized'}
- Operations Hotline: +256 784 638 852

1-Click Portal Activation (Option 1):
$inviteLink

Install Official Android App (APK):
$defaultApkUrl

Collection operations reminder:
1. Ensure your tricycle cargo bay is securely fastened before transit.
2. Confirm sack counts and waste categories at resident pickup locations.
3. Transport loaded sacks to designated municipal sorting hubs for scale weighing.

If you have questions, contact municipal dispatch or reply directly to this email.

EcoRoute Municipal Waste Operations
Arua City Council Logistics & Muni University Campus
Plot 4 Avenue Road, Central Division, Arua City, West Nile, Uganda
Official Dispatch: ecoroute.waste@gmail.com
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
