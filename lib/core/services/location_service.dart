import 'package:geolocator/geolocator.dart';

import '../../domain/enums/zone.dart';
import '../../domain/rules/zone_resolver.dart';

enum LocationServiceStatus {
  success,
  servicesDisabled,
  permissionDenied,
  permissionDeniedForever,
  outsideServiceArea,
  error,
}

class UserLocationResult {
  const UserLocationResult({
    required this.status,
    this.latitude,
    this.longitude,
    this.accuracyMeters,
    this.altitude,
    this.timestamp,
    this.resolvedZone,
    this.isWithinServiceArea = false,
    this.message,
  });

  final LocationServiceStatus status;
  final double? latitude;
  final double? longitude;
  final double? accuracyMeters;
  final double? altitude;
  final DateTime? timestamp;
  final Zone? resolvedZone;
  final bool isWithinServiceArea;
  final String? message;
}

class LocationService {
  const LocationService();

  Future<UserLocationResult> getCurrentUserLocation() async {
    try {
      final serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        return const UserLocationResult(
          status: LocationServiceStatus.servicesDisabled,
          message: 'Location services are disabled on your device. Please enable GPS or select your zone manually.',
        );
      }

      var permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) {
          return const UserLocationResult(
            status: LocationServiceStatus.permissionDenied,
            message: 'Location permission was denied. You can still select your zone manually.',
          );
        }
      }

      if (permission == LocationPermission.deniedForever) {
        return const UserLocationResult(
          status: LocationServiceStatus.permissionDeniedForever,
          message: 'Location permissions are permanently denied. Please choose your collection zone manually.',
        );
      }

      Position position;
      try {
        position = await Geolocator.getCurrentPosition(
          locationSettings: const LocationSettings(
            accuracy: LocationAccuracy.high,
            timeLimit: Duration(seconds: 8),
          ),
        );
      } catch (_) {
        final lastKnown = await Geolocator.getLastKnownPosition();
        if (lastKnown != null) {
          position = lastKnown;
        } else {
          try {
            position = await Geolocator.getCurrentPosition(
              locationSettings: const LocationSettings(
                accuracy: LocationAccuracy.medium,
                timeLimit: Duration(seconds: 4),
              ),
            );
          } catch (_) {
            return const UserLocationResult(
              status: LocationServiceStatus.error,
              message: 'GPS fix timed out. Please enter your address or pin location manually.',
            );
          }
        }
      }

      final isWithin = isWithinAruaServiceArea(position.latitude, position.longitude);
      final zone = resolveAruaZone(position.latitude, position.longitude);

      return UserLocationResult(
        status: isWithin ? LocationServiceStatus.success : LocationServiceStatus.outsideServiceArea,
        latitude: position.latitude,
        longitude: position.longitude,
        accuracyMeters: position.accuracy,
        altitude: position.altitude,
        timestamp: position.timestamp,
        resolvedZone: zone,
        isWithinServiceArea: isWithin,
        message: isWithin
            ? 'Located within Arua ${zone.label} zone (±${position.accuracy.toStringAsFixed(1)}m accuracy).'
            : 'Your location is outside the 12km Arua municipal collection perimeter. Please contact support.',
      );
    } catch (e) {
      return UserLocationResult(
        status: LocationServiceStatus.error,
        message: 'Could not acquire GPS fix: ${e.toString()}. Please select zone manually.',
      );
    }
  }

  /// Live continuous GPS stream with high precision
  Stream<UserLocationResult> getLiveLocationStream() {
    return Geolocator.getPositionStream(
      locationSettings: const LocationSettings(
        accuracy: LocationAccuracy.high,
        distanceFilter: 3,
      ),
    ).map((position) {
      final isWithin = isWithinAruaServiceArea(position.latitude, position.longitude);
      final zone = resolveAruaZone(position.latitude, position.longitude);

      return UserLocationResult(
        status: isWithin ? LocationServiceStatus.success : LocationServiceStatus.outsideServiceArea,
        latitude: position.latitude,
        longitude: position.longitude,
        accuracyMeters: position.accuracy,
        altitude: position.altitude,
        timestamp: position.timestamp,
        resolvedZone: zone,
        isWithinServiceArea: isWithin,
        message: 'Live GPS: ${position.latitude.toStringAsFixed(5)}, ${position.longitude.toStringAsFixed(5)} (±${position.accuracy.toStringAsFixed(1)}m)',
      );
    });
  }

  /// URL to launch directly in Google Maps application or web
  static String googleMapsSearchUrl({required double latitude, required double longitude}) {
    return 'https://www.google.com/maps/search/?api=1&query=$latitude,$longitude';
  }

  /// URL for Google Maps turn-by-turn navigation
  static String googleMapsDirectionsUrl({required double latitude, required double longitude}) {
    return 'https://www.google.com/maps/dir/?api=1&destination=$latitude,$longitude';
  }

  /// Helper to resolve zone and service area from coordinates directly
  UserLocationResult evaluateCoordinates(double lat, double lng) {
    final isWithin = isWithinAruaServiceArea(lat, lng);
    final zone = resolveAruaZone(lat, lng);

    return UserLocationResult(
      status: isWithin ? LocationServiceStatus.success : LocationServiceStatus.outsideServiceArea,
      latitude: lat,
      longitude: lng,
      resolvedZone: zone,
      isWithinServiceArea: isWithin,
      message: isWithin
          ? 'Coordinates verified within Arua ${zone.label} zone.'
          : 'Coordinates lie beyond the 12 km Arua service boundary.',
    );
  }
}
