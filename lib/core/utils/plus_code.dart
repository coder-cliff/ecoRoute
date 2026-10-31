/// Clean, zero-dependency Open Location Code (Plus Code) generator for Arua, Uganda
class PlusCode {
  PlusCode._();

  static const String _alphabet = '23456789CFGHJMPQRVWX';
  static const int _encodingBase = 20;
  static const int _latitudeMax = 90;
  static const int _longitudeMax = 180;

  /// Encodes latitude and longitude into an 8-character + 2-character Plus Code
  static String encode(double latitude, double longitude, {int codeLength = 10}) {
    // Normalization
    var lat = latitude.clamp(-90.0, 90.0);
    var lng = longitude;
    while (lng < -180.0) {
      lng += 360.0;
    }
    while (lng >= 180.0) {
      lng -= 360.0;
    }

    lat += _latitudeMax;
    lng += _longitudeMax;

    final buffer = StringBuffer();
    var latVal = lat;
    var lngVal = lng;

    var latResolution = 20.0;
    var lngResolution = 20.0;

    for (var i = 0; i < codeLength; i += 2) {
      final latDigit = (latVal / latResolution).floor();
      final lngDigit = (lngVal / lngResolution).floor();

      buffer.write(_alphabet[latDigit.clamp(0, _encodingBase - 1)]);
      buffer.write(_alphabet[lngDigit.clamp(0, _encodingBase - 1)]);

      latVal -= latDigit * latResolution;
      lngVal -= lngDigit * lngResolution;

      latResolution /= _encodingBase;
      lngResolution /= _encodingBase;

      if (i == 6) {
        buffer.write('+');
      }
    }

    return '${buffer.toString()} Arua';
  }
}
