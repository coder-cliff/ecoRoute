import 'dart:js_interop';

@JS('isAppInstalled')
external bool? _isAppInstalled();

@JS('triggerPwaInstall')
external JSPromise<JSBoolean>? _triggerPwaInstall();

/// Checks if running in standalone display mode on web
bool isPlatformStandalone() {
  try {
    return _isAppInstalled() ?? false;
  } catch (_) {
    return false;
  }
}

/// Triggers the browser PWA installation prompt
Future<bool> triggerBrowserInstall() async {
  try {
    final promise = _triggerPwaInstall();
    if (promise == null) return false;
    final res = await promise.toDart;
    return res.toDart;
  } catch (_) {
    return false;
  }
}
