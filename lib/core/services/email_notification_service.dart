import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:url_launcher/url_launcher.dart';
import 'rider_invite_service.dart';

/// Centralized Transactional Email Notification Service for EcoRoute.
/// Dispatches clear, professional emails across users using Google Apps Script
/// MailApp API (scripts.google.com) with native mail client fallback.
class EmailNotificationService {
  const EmailNotificationService._();

  static const String appUrl = 'https://coder-cliff.github.io/ecoRoute/';
  static const String hotline = '+256 394 880 352';
  static const String senderEmail = 'ecoroute.waste@gmail.com';
  static const String senderName = 'EcoRoute Fleet Operations (Arua City Council)';

  /// 1. RIDER INVITATION & AUTHORIZATION EMAIL
  static Map<String, String> draftRiderInvitation({
    required String riderName,
    required String riderEmail,
    required String inviteCode,
    required String temporaryPin,
    required String tricycleId,
  }) {
    final onboardUrl = '$appUrl#/rider-activate';
    final subject = 'EcoRoute Arua: Official Rider Authorization & Tricycle Assignment';
    final body = '''
Hello $riderName,

Welcome to the EcoRoute municipal collection team for Arua City!

An official rider dispatch account has been authorized for you by Arua City Council Fleet Operations for the municipal tricycle waste collection fleet serving Ayivu, Central Division, and Muni University.

YOUR AUTHORIZATION DETAILS:
------------------------------------------
• Driver Name: $riderName
• Email Address: $riderEmail
• Assigned Unit: $tricycleId
• Invite Code: $inviteCode
• Temporary 6-Digit PIN: $temporaryPin
• Operations Hotline: $hotline

STEP-BY-STEP ACCOUNT ACTIVATION:
------------------------------------------
1. Open your activation portal: $onboardUrl
2. Enter your Email ($riderEmail) and Temporary 6-Digit PIN ($temporaryPin).
3. Create your permanent password (which you will use for future Email & Password logins).
4. Provide your Next of Kin / Emergency contact phone and your Mobile Money payout phone (MTN MoMo or Airtel Money for daily wage settlements).
5. Submit for municipal verification. Account approval is typically completed within 5 minutes to 24 hours.

📲 HOW TO INSTALL ECOROUTE ON YOUR PHONE:
------------------------------------------
No app store download is required! Install directly to your phone's home screen:
• Android (Google Chrome):
  1. Open $appUrl in Google Chrome.
  2. Tap the three dots (⋮) in the top-right corner.
  3. Tap "Install App" or "Add to Home Screen".
  4. The EcoRoute app icon will now sit on your home screen like any native app.

• iPhone (Apple Safari):
  1. Open $appUrl in Safari.
  2. Tap the Share icon (square with arrow at the bottom).
  3. Scroll down and tap "Add to Home Screen".
  4. Tap "Add" in the top-right corner.

OPERATIONAL REMINDERS:
• Ensure your tricycle cargo bay is securely fastened before transit.
• Confirm sack counts and waste categories at resident pickup locations.
• Transport loaded sacks to designated municipal sorting hubs for scale weighing.

If you have any questions, contact municipal dispatch or reply directly to this email.

EcoRoute Municipal Waste Operations
Arua City Council Logistics & Muni University Campus
Plot 4 Avenue Road, Central Division, Arua City, West Nile, Uganda
Official Dispatch: $senderEmail
''';

    final htmlBody = '''
<div style="font-family: -apple-system, BlinkMacSystemFont, 'Segoe UI', Roboto, Helvetica, Arial, sans-serif; max-width: 600px; margin: 0 auto; padding: 24px; color: #1E293B; background-color: #F8FAFC; border-radius: 12px; border: 1px solid #E2E8F0;">
  <div style="text-align: center; margin-bottom: 24px;">
    <h1 style="color: #1B5E20; margin: 0; font-size: 24px;">ecoRoute</h1>
    <p style="color: #64748B; font-size: 13px; margin: 4px 0 0 0;">Arua City Municipal Waste Logistics</p>
  </div>
  <div style="background-color: #FFFFFF; padding: 24px; border-radius: 8px; border: 1px solid #E2E8F0;">
    <h2 style="color: #0F3822; font-size: 18px; margin-top: 0;">Welcome, $riderName!</h2>
    <p style="font-size: 14px; line-height: 1.6; color: #334155;">
      An official rider dispatch account has been authorized for you by <strong>Arua City Council Fleet Operations</strong> for the municipal tricycle waste collection fleet.
    </p>
    <div style="background-color: #F1F8E9; border-left: 4px solid #2E7D32; padding: 16px; margin: 20px 0; border-radius: 4px;">
      <h3 style="margin: 0 0 10px 0; font-size: 15px; color: #1B5E20;">Authorization Details</h3>
      <table style="width: 100%; font-size: 13.5px; border-collapse: collapse;">
        <tr><td style="padding: 4px 0; color: #64748B;">Assigned Unit:</td><td style="font-weight: bold; color: #1B5E20;">$tricycleId</td></tr>
        <tr><td style="padding: 4px 0; color: #64748B;">Registered Email:</td><td style="font-weight: bold;">$riderEmail</td></tr>
        <tr><td style="padding: 4px 0; color: #64748B;">Temporary PIN:</td><td style="font-weight: bold; font-size: 16px; color: #15803D;">$temporaryPin</td></tr>
        <tr><td style="padding: 4px 0; color: #64748B;">Review Window:</td><td style="font-weight: bold; color: #B45309;">5 mins &ndash; 24 hours</td></tr>
        <tr><td style="padding: 4px 0; color: #64748B;">Dispatch Hotline:</td><td>$hotline</td></tr>
      </table>
    </div>
    <div style="text-align: center; margin: 24px 0;">
      <a href="$onboardUrl" style="background-color: #1B5E20; color: #FFFFFF; text-decoration: none; padding: 12px 28px; border-radius: 8px; font-weight: bold; font-size: 14px; display: inline-block;">Activate Rider Account &rarr;</a>
    </div>
    <div style="background-color: #F8FAFC; border: 1px dashed #CBD5E1; padding: 14px; border-radius: 6px; font-size: 12.5px; line-height: 1.5; color: #475569;">
      <strong style="color: #0F172A;">📲 How to Install the App to Your Mobile Phone:</strong><br/>
      &bull; <strong>Android (Chrome):</strong> Tap the link &gt; Tap menu (⋮) &gt; Tap <em>"Install App"</em> or <em>"Add to Home screen"</em>.<br/>
      &bull; <strong>iPhone (Safari):</strong> Tap the link &gt; Tap Share button (square with arrow) &gt; Tap <em>"Add to Home Screen"</em>.
    </div>
  </div>
  <div style="text-align: center; margin-top: 20px; font-size: 12px; color: #94A3B8;">
    <p style="margin: 4px 0;">EcoRoute Municipal Waste Operations &bull; Arua City Council &bull; Muni University</p>
    <p style="margin: 4px 0;">Official Dispatch: <a href="mailto:$senderEmail" style="color: #1B5E20;">$senderEmail</a></p>
  </div>
</div>
''';

    return {
      'subject': subject,
      'body': body,
      'htmlBody': htmlBody,
    };
  }

  /// 2. RIDER ACCOUNT APPROVED CONFIRMATION EMAIL
  static Map<String, String> draftRiderApproval({
    required String riderName,
    required String riderEmail,
    required String tricycleId,
  }) {
    final loginUrl = '$appUrl#/login';
    final subject = 'EcoRoute Fleet Authorization: Your Rider Account is Approved! 🚀';
    final body = '''
Hello $riderName,

Great news! Your EcoRoute field rider account has been reviewed and APPROVED by Arua City Council Municipal Fleet Operations.

Your account is now fully active and authorized for daily waste collection dispatch.

DISPATCH AUTHORIZATION SUMMARY:
------------------------------------------
• Driver Name: $riderName
• Status: APPROVED & ACTIVE
• Assigned Unit: $tricycleId
• Municipal Zone: Arua Central & Ayivu Division
• Wage Payouts: Settled daily to your registered Mobile Money number

HOW TO LOG IN & BEGIN YOUR SHIFT:
------------------------------------------
1. Open the EcoRoute portal: $loginUrl
2. Sign in using your Email Address ($riderEmail) and the Password you created during activation.
3. Clock in to your morning shift and view your assigned route.

If you have not already installed the app to your home screen:
• Android (Chrome): Tap browser menu (⋮) > "Install App" or "Add to Home screen".
• iPhone (Safari): Tap Share icon > "Add to Home Screen".

Operations Hotline: $hotline
Emergency Dispatch Desk: $senderEmail

Welcome to the team!

EcoRoute Municipal Fleet Operations
Arua City Council & Muni University Campus
''';

    final htmlBody = '''
<div style="font-family: -apple-system, BlinkMacSystemFont, 'Segoe UI', Roboto, Helvetica, Arial, sans-serif; max-width: 600px; margin: 0 auto; padding: 24px; color: #1E293B; background-color: #F8FAFC; border-radius: 12px; border: 1px solid #E2E8F0;">
  <div style="text-align: center; margin-bottom: 24px;">
    <h1 style="color: #1B5E20; margin: 0; font-size: 24px;">ecoRoute</h1>
    <p style="color: #64748B; font-size: 13px; margin: 4px 0 0 0;">Arua City Municipal Waste Logistics</p>
  </div>
  <div style="background-color: #FFFFFF; padding: 24px; border-radius: 8px; border: 1px solid #E2E8F0;">
    <div style="text-align: center; margin-bottom: 16px;">
      <div style="display: inline-block; width: 48px; height: 48px; line-height: 48px; border-radius: 50%; background-color: #E8F5E9; color: #2E7D32; font-size: 24px;">✓</div>
      <h2 style="color: #1B5E20; font-size: 20px; margin: 8px 0 0 0;">Your Rider Account is Approved!</h2>
    </div>
    <p style="font-size: 14px; line-height: 1.6; color: #334155;">
      Congratulations, <strong>$riderName</strong>! Your field collection profile has been verified and officially approved by Arua City Council Fleet Operations.
    </p>
    <div style="background-color: #F1F8E9; border-left: 4px solid #2E7D32; padding: 16px; margin: 20px 0; border-radius: 4px;">
      <table style="width: 100%; font-size: 13.5px; border-collapse: collapse;">
        <tr><td style="padding: 4px 0; color: #64748B;">Rider Status:</td><td style="font-weight: bold; color: #15803D;">APPROVED &bull; ACTIVE</td></tr>
        <tr><td style="padding: 4px 0; color: #64748B;">Assigned Unit:</td><td style="font-weight: bold; color: #1B5E20;">$tricycleId</td></tr>
        <tr><td style="padding: 4px 0; color: #64748B;">Login Email:</td><td style="font-weight: bold;">$riderEmail</td></tr>
        <tr><td style="padding: 4px 0; color: #64748B;">Wage Payouts:</td><td>Mobile Money Daily Settlement</td></tr>
      </table>
    </div>
    <div style="text-align: center; margin: 28px 0 16px 0;">
      <a href="$loginUrl" style="background-color: #1B5E20; color: #FFFFFF; text-decoration: none; padding: 12px 28px; border-radius: 8px; font-weight: bold; font-size: 14px; display: inline-block;">Log in with Email & Password &rarr;</a>
    </div>
  </div>
  <div style="text-align: center; margin-top: 20px; font-size: 12px; color: #94A3B8;">
    <p style="margin: 4px 0;">EcoRoute Municipal Waste Operations &bull; Arua City Council &bull; Muni University</p>
    <p style="margin: 4px 0;">Official Dispatch: <a href="mailto:$senderEmail" style="color: #1B5E20;">$senderEmail</a></p>
  </div>
</div>
''';

    return {
      'subject': subject,
      'body': body,
      'htmlBody': htmlBody,
    };
  }

  /// 3. USER / RIDER FEEDBACK RESOLUTION NOTIFICATION EMAIL
  static Map<String, String> draftFeedbackResolution({
    required String recipientName,
    required String ticketId,
    required String category,
    required String userOriginalMessage,
    required String adminReply,
  }) {
    final subject = 'EcoRoute: Update on your Feedback & Challenge Report ($ticketId)';
    final body = '''
Hello $recipientName,

Municipal dispatch operations at EcoRoute has reviewed your challenge report:

Ticket ID: $ticketId
Category: $category

Your original inquiry:
"$userOriginalMessage"

Dispatch HQ Resolution & Response:
"$adminReply"

Thank you for helping us keep Arua City clean and our waste logistics running smoothly. If you require further assistance, please contact the municipal hotline at $hotline or reply to this email.

EcoRoute Support & Dispatch HQ
Arua City Council Logistics
''';

    final htmlBody = '''
<div style="font-family: -apple-system, BlinkMacSystemFont, 'Segoe UI', Roboto, sans-serif; max-width: 600px; margin: 0 auto; padding: 24px; color: #1E293B; background-color: #F8FAFC; border-radius: 12px;">
  <div style="text-align: center; margin-bottom: 20px;">
    <h1 style="color: #1B5E20; margin: 0; font-size: 22px;">ecoRoute Support</h1>
  </div>
  <div style="background-color: #FFFFFF; padding: 20px; border-radius: 8px; border: 1px solid #E2E8F0;">
    <h2 style="color: #0F3822; font-size: 16px; margin-top: 0;">Feedback Resolved: $ticketId</h2>
    <p style="font-size: 13.5px; color: #475569;">Hello $recipientName, municipal dispatch operations has addressed your reported challenge ($category):</p>
    <div style="background-color: #F8FAFC; padding: 12px; border-radius: 6px; margin: 12px 0; font-size: 13px; font-style: italic; color: #64748B;">
      "$userOriginalMessage"
    </div>
    <div style="background-color: #F0FDF4; border-left: 4px solid #16A34A; padding: 14px; margin: 16px 0; border-radius: 4px;">
      <strong style="color: #15803D; font-size: 13.5px;">Dispatch HQ Resolution:</strong>
      <p style="margin: 6px 0 0 0; font-size: 13.5px; color: #166534;">$adminReply</p>
    </div>
  </div>
</div>
''';

    return {
      'subject': subject,
      'body': body,
      'htmlBody': htmlBody,
    };
  }

  /// 3. RESIDENT PICKUP RECEIPT & CONFIRMATION EMAIL
  static Map<String, String> draftPickupReceipt({
    required String residentName,
    required String pickupId,
    required String wasteType,
    required int sacks,
    required int amountUgx,
    required String address,
    required String riderName,
  }) {
    final subject = 'EcoRoute Receipt: Waste Collection Completed ($pickupId)';
    final body = '''
Hello $residentName,

Your municipal waste collection in Arua City has been completed successfully.

COLLECTION RECEIPT:
------------------------------------------
• Receipt ID: $pickupId
• Collection Location: $address
• Waste Category: $wasteType
• Sacks Collected: $sacks
• Total Paid: UGX ${amountUgx.toString()}
• Servicing Field Rider: $riderName
• Status: Completed & Verified

Thank you for contributing to a cleaner and greener Arua City!

EcoRoute Logistics Team
Plot 4 Avenue Road, Central Division, Arua City
''';

    return {
      'subject': subject,
      'body': body,
      'htmlBody': body.replaceAll('\n', '<br/>'),
    };
  }

  /// Dispatches email via Google Apps Script MailApp API
  static Future<bool> sendEmail({
    required String toEmail,
    required String subject,
    required String body,
    String? htmlBody,
    String? customScriptUrl,
    http.Client? httpClient,
  }) async {
    final client = httpClient ?? http.Client();
    final targetUrl = customScriptUrl ?? await RiderInviteService.getEffectiveScriptUrl();

    if (targetUrl.contains('AKfycbyEcoRouteRiderInviteGateway') ||
        targetUrl.contains('YOUR_DEPLOYMENT_ID')) {
      debugPrint('Google Apps Script URL not configured.');
      return false;
    }

    try {
      final response = await client.post(
        Uri.parse(targetUrl),
        headers: {'Content-Type': 'text/plain;charset=utf-8'},
        body: jsonEncode({
          'email': toEmail.trim().toLowerCase(),
          'subject': subject,
          'body': body,
          'htmlBody': htmlBody ?? body,
          'senderName': senderName,
        }),
      );

      if (response.statusCode == 200 || response.statusCode == 302) {
        return true;
      }
      return false;
    } catch (e) {
      debugPrint('Email send error via Google Apps Script: $e');
      return false;
    } finally {
      if (httpClient == null) client.close();
    }
  }

  /// Dispatches the official Rider Approval & Welcome confirmation email
  static Future<bool> sendRiderApprovalEmail({
    required String riderName,
    required String riderEmail,
    required String tricycleId,
    String? customScriptUrl,
    http.Client? httpClient,
  }) async {
    final draft = draftRiderApproval(
      riderName: riderName,
      riderEmail: riderEmail,
      tricycleId: tricycleId,
    );
    return sendEmail(
      toEmail: riderEmail,
      subject: draft['subject']!,
      body: draft['body']!,
      htmlBody: draft['htmlBody'],
      customScriptUrl: customScriptUrl,
      httpClient: httpClient,
    );
  }

  /// Opens default email application with prefilled fields
  static Future<bool> openMailClient({
    required String toEmail,
    required String subject,
    required String body,
  }) async {
    final uri = Uri(
      scheme: 'mailto',
      path: toEmail.trim(),
      queryParameters: {
        'subject': subject,
        'body': body,
      },
    );
    try {
      return await launchUrl(uri, mode: LaunchMode.externalApplication);
    } catch (e) {
      debugPrint('Mailto launch error: $e');
      return false;
    }
  }
}
