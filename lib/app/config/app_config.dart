class AppConfig {
  const AppConfig._();

  static const double zoneCenterLat = 3.03;
  static const double zoneCenterLng = 30.91;
  static const double serviceRadiusKm = 75;
  static const String supportPhone = '+256 394 880 352';
  static const String defaultMomoCode = 'EcoRoute';

  static const Map<String, String> collectionSchedule = {
    'north': 'Mondays & Thursdays',
    'south': 'Tuesdays & Fridays',
    'east': 'Wednesdays & Saturdays',
    'west': 'Daily On-Demand (Commercial & Trading Centers)',
  };

  // Administrative
  static const String adminEmail = 'ecoroute.arua@gmail.com';
  static const String appVersion = '1.0.0';
  static const String aruaCityName = 'Arua City, Uganda';
  static const double aruaLat = 3.0243;
  static const double aruaLng = 30.9035;
  static const Duration inactivityTimeout = Duration(minutes: 10);
  static const int maxFeedbackChars = 500;
}
