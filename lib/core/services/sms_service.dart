import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:url_launcher/url_launcher.dart';

/// Zero-cost SMS dispatch gateway for low-bandwidth client notifications across Arua City.
/// Uses Africa's Talking sandbox (10 free SMS/day) with instant device dialer fallback (sms:).
class AfricaTalkingSmsService {
  const AfricaTalkingSmsService._();

  static const String defaultSenderId = 'ecoRoute';
  static const String _africasTalkingSandboxUrl =
      'https://api.sandbox.africastalking.com/version1/messaging';

  /// Dispatches an automated collection SMS alert to resident or rider.
  /// Falls back to direct device SMS app if offline or out of free credits.
  static Future<bool> sendCollectionSms({
    required String recipientPhone,
    required String message,
    String? apiKey,
    String? username,
    http.Client? httpClient,
  }) async {
    final cleanPhone = recipientPhone.replaceAll(' ', '').trim();
    if (cleanPhone.isEmpty) return false;

    // Direct device SMS launcher fallback if no API credentials configured
    if (apiKey == null || username == null) {
      return openDeviceSmsApp(phone: cleanPhone, message: message);
    }

    final client = httpClient ?? http.Client();
    try {
      final response = await client.post(
        Uri.parse(_africasTalkingSandboxUrl),
        headers: {
          'apiKey': apiKey,
          'Content-Type': 'application/x-www-form-urlencoded',
          'Accept': 'application/json',
        },
        body: {
          'username': username,
          'to': cleanPhone,
          'message': message,
          'from': defaultSenderId,
        },
      ).timeout(const Duration(seconds: 4));

      if (response.statusCode == 201 || response.statusCode == 200) {
        final data = jsonDecode(response.body) as Map<String, dynamic>;
        final recipients = data['SMSMessageData']?['Recipients'] as List<dynamic>?;
        if (recipients != null && recipients.isNotEmpty) {
          final status = recipients.first['status'] as String?;
          debugPrint('Africa Talking SMS status: $status');
          return status == 'Success';
        }
        return true;
      }
      debugPrint('Africa Talking responded with code ${response.statusCode}');
      return await openDeviceSmsApp(phone: cleanPhone, message: message);
    } catch (e) {
      debugPrint('Africa Talking SMS error, launching device SMS: $e');
      return await openDeviceSmsApp(phone: cleanPhone, message: message);
    } finally {
      if (httpClient == null) client.close();
    }
  }

  /// Opens the device default SMS messenger app with pre-filled recipient and text
  static Future<bool> openDeviceSmsApp({
    required String phone,
    required String message,
  }) async {
    final cleanPhone = phone.replaceAll(RegExp(r'[^0-9+]'), '');
    final uri = Uri(
      scheme: 'sms',
      path: cleanPhone,
      queryParameters: {'body': message},
    );

    try {
      if (await canLaunchUrl(uri)) {
        return await launchUrl(uri);
      }
    } catch (e) {
      debugPrint('Could not launch SMS app: $e');
    }
    return false;
  }
}
