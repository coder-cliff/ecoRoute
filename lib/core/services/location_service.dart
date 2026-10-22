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
    this.resolvedZone,
    this.isWithinServiceArea = false,
    this.message,
  });

  final LocationServiceStatus status;
  final double? latitude;
  final double? longitude;
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

      final position = await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.medium,
          timeLimit: Duration(seconds: 5),
        ),
      );

      final isWithin = isWithinAruaServiceArea(position.latitude, position.longitude);
      final zone = resolveAruaZone(position.latitude, position.longitude);

      return UserLocationResult(
        status: isWithin ? LocationServiceStatus.success : LocationServiceStatus.outsideServiceArea,
        latitude: position.latitude,
        longitude: position.longitude,
        resolvedZone: zone,
        isWithinServiceArea: isWithin,
        message: isWithin
            ? 'Located within Arua ${zone.label} zone.'
            : 'Your location is outside the 12km Arua municipal collection perimeter. Please contact support.',
      );
    } catch (e) {
      // In case of platform exceptions or desktop/emulator without GPS
      return UserLocationResult(
        status: LocationServiceStatus.error,
        message: 'Could not acquire GPS fix: ${e.toString()}. Please select zone manually.',
      );
    }
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
