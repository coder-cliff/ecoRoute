import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:url_launcher/url_launcher.dart';

import 'install_detector_stub.dart'
    if (dart.library.js_interop) 'install_detector_web.dart';
import 'rider_invite_service.dart';

/// Service to detect whether the user has installed the EcoRoute application
/// and prompt them with a 1-click PWA install or direct Android APK download.
class AppInstallService with ChangeNotifier {
  AppInstallService._();
  static final AppInstallService instance = AppInstallService._();

  static const String _kInstallDismissedUntilKey = 'ecoroute_install_banner_dismissed_until';
  bool _isDismissed = false;

  bool get isDismissed => _isDismissed;

  /// Checks whether the application is already running in installed standalone mode
  bool get isAppInstalled => !kIsWeb || isPlatformStandalone();

  /// Determines whether the smart installation prompt should be shown
  Future<bool> shouldShowInstallBanner([SharedPreferences? preferences]) async {
    // If running natively on Android, iOS, or Linux, it's already installed
    if (!kIsWeb) return false;

    // If running in browser in standalone mode (already installed PWA)
    if (isPlatformStandalone()) return false;

    if (_isDismissed) return false;

    try {
      final prefs = preferences ?? await SharedPreferences.getInstance();
      final dismissedUntil = prefs.getInt(_kInstallDismissedUntilKey) ?? 0;
      final now = DateTime.now().millisecondsSinceEpoch;
      if (now < dismissedUntil) {
        _isDismissed = true;
        return false;
      }
    } catch (_) {}

    return true;
  }

  /// Dismisses the banner for 3 days
  Future<void> dismissBanner([SharedPreferences? preferences]) async {
    _isDismissed = true;
    notifyListeners();
    try {
      final prefs = preferences ?? await SharedPreferences.getInstance();
      final expiry = DateTime.now().add(const Duration(days: 3)).millisecondsSinceEpoch;
      await prefs.setInt(_kInstallDismissedUntilKey, expiry);
    } catch (_) {}
  }

  /// Triggers PWA install prompt or falls back to APK download
  Future<void> triggerInstall() async {
    if (kIsWeb) {
      final accepted = await triggerBrowserInstall();
      if (!accepted) {
        // If PWA prompt is not available, offer direct APK download
        await downloadApk();
      }
    } else {
      await downloadApk();
    }
  }

  /// Downloads the official EcoRoute Android Release APK
  Future<bool> downloadApk() async {
    final apkUri = Uri.parse(RiderInviteService.defaultApkUrl);
    try {
      return await launchUrl(apkUri, mode: LaunchMode.externalApplication);
    } catch (e) {
      debugPrint('Error launching APK download URL: $e');
      return false;
    }
  }
}
