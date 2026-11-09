class AppConfig {
  const AppConfig._();

  static const double zoneCenterLat = 3.03;
  static const double zoneCenterLng = 30.91;
  static const double serviceRadiusKm = 75; // Expanded to cover Arua City, trading centers, and neighboring West Nile districts
  static const String supportPhone = '+256 394 880 352';
  static const String defaultMomoCode = 'EcoRoute';

  static const Map<String, String> collectionSchedule = {
    'north': 'Mondays & Thursdays',
    'south': 'Tuesdays & Fridays',
    'east': 'Wednesdays & Saturdays',
    'west': 'Daily On-Demand (Commercial & Trading Centers)',
  };
}
