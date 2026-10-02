import 'dart:math' as math;

import '../../app/config/app_config.dart';
import '../enums/zone.dart';

Zone resolveZone(
  double lat,
  double lng, {
  required double centerLat,
  required double centerLng,
}) {
  final dLat = lat - centerLat;
  final dLng = lng - centerLng;

  if (dLat.abs() >= dLng.abs()) {
    return dLat >= 0 ? Zone.north : Zone.south;
  }

  return dLng >= 0 ? Zone.east : Zone.west;
}

Zone resolveAruaZone(double lat, double lng) {
  return resolveZone(
    lat,
    lng,
    centerLat: AppConfig.zoneCenterLat,
    centerLng: AppConfig.zoneCenterLng,
  );
}

bool isWithinServiceArea(
  double lat,
  double lng, {
  required double centerLat,
  required double centerLng,
  required double radiusKm,
}) {
  final latDeltaKm = (lat - centerLat) * 111.32;
  final lngDeltaKm =
      (lng - centerLng) * 111.32 * math.cos(centerLat * math.pi / 180);
  final distanceKm = math.sqrt(
    (latDeltaKm * latDeltaKm) + (lngDeltaKm * lngDeltaKm),
  );

  return distanceKm <= radiusKm;
}

bool isWithinAruaServiceArea(double lat, double lng) {
  return isWithinServiceArea(
    lat,
    lng,
    centerLat: AppConfig.zoneCenterLat,
    centerLng: AppConfig.zoneCenterLng,
    radiusKm: AppConfig.serviceRadiusKm,
  );
}
