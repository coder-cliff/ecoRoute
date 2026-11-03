import 'package:flutter/foundation.dart';
import 'package:geolocator/geolocator.dart';

class LocationResult {
  final double latitude;
  final double longitude;
  final double accuracy;
  final bool isSimulated;
  final String? errorMessage;

  LocationResult({
    required this.latitude,
    required this.longitude,
    required this.accuracy,
    this.isSimulated = false,
    this.errorMessage,
  });
}

class LocationService {
  // Default coordinates (Kampala City Centre / Makerere) used for fallback/simulation
  static const double defaultLat = 0.3340;
  static const double defaultLon = 32.5686;

  /// Retrieves the current GPS position using geolocator, with graceful fallback
  static Future<LocationResult> getCurrentLocation() async {
    try {
      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        return LocationResult(
          latitude: defaultLat,
          longitude: defaultLon,
          accuracy: 15.0,
          isSimulated: true,
          errorMessage: 'Location services disabled on device. Using simulated GPS.',
        );
      }

      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) {
          return LocationResult(
            latitude: defaultLat,
            longitude: defaultLon,
            accuracy: 20.0,
            isSimulated: true,
            errorMessage: 'Location permission denied. Using simulated GPS.',
          );
        }
      }

      if (permission == LocationPermission.deniedForever) {
        return LocationResult(
          latitude: defaultLat,
          longitude: defaultLon,
          accuracy: 25.0,
          isSimulated: true,
          errorMessage: 'Location permission permanently denied. Using simulated GPS.',
        );
      }

      // Live GPS reading from device sensor
      final position = await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.high,
          timeLimit: Duration(seconds: 7),
        ),
      );

      return LocationResult(
        latitude: position.latitude,
        longitude: position.longitude,
        accuracy: position.accuracy,
        isSimulated: false,
      );
    } catch (e) {
      debugPrint('LocationService exception: $e. Falling back to simulated GPS.');
      return LocationResult(
        latitude: defaultLat + (DateTime.now().millisecond % 50) * 0.0001,
        longitude: defaultLon + (DateTime.now().second % 50) * 0.0001,
        accuracy: 10.0,
        isSimulated: true,
        errorMessage: 'Using simulated GPS: $e',
      );
    }
  }

  /// Calculates straight-line distance in km between two GPS coordinates
  static double calculateDistanceKm(
    double startLat,
    double startLon,
    double endLat,
    double endLon,
  ) {
    double distanceInMeters = Geolocator.distanceBetween(
      startLat,
      startLon,
      endLat,
      endLon,
    );
    return distanceInMeters / 1000.0;
  }
}
