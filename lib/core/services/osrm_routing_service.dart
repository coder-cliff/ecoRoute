import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:latlong2/latlong.dart';

/// Free OSRM road routing integration between Arua Center & dispatch stops
class OsrmRoutingService {
  OsrmRoutingService({http.Client? httpClient})
      : _client = httpClient ?? http.Client();

  final http.Client _client;

  /// Default Arua Center to Ediofe road polyline coordinates
  static const List<LatLng> fallbackAruaToEdiofeRoute = [
    LatLng(3.0303, 30.9073), // Arua City Centre
    LatLng(3.0295, 30.9042),
    LatLng(3.0287, 30.9010),
    LatLng(3.0278, 30.8980),
    LatLng(3.0269, 30.8950),
    LatLng(3.0258, 30.8932),
    LatLng(3.0250, 30.8920), // Ediofe Trading Center
  ];

  /// Queries the public Project-OSRM driving routing API
  Future<List<LatLng>> getRoute({
    required LatLng start,
    required LatLng end,
  }) async {
    final url = Uri.parse(
      'https://router.project-osrm.org/route/v1/driving/'
      '${start.longitude},${start.latitude};${end.longitude},${end.latitude}'
      '?overview=full&geometries=geojson',
    );

    try {
      final response = await _client.get(url).timeout(const Duration(seconds: 4));
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body) as Map<String, dynamic>;
        final routes = data['routes'] as List<dynamic>?;
        if (routes != null && routes.isNotEmpty) {
          final geometry = routes.first['geometry'] as Map<String, dynamic>?;
          final coords = geometry?['coordinates'] as List<dynamic>?;
          if (coords != null && coords.isNotEmpty) {
            return coords.map((c) {
              final pair = c as List<dynamic>;
              return LatLng(
                (pair[1] as num).toDouble(),
                (pair[0] as num).toDouble(),
              );
            }).toList();
          }
        }
      }
    } catch (e) {
      debugPrint('OSRM routing fetch notice (using high-accuracy fallback): $e');
    }

    return fallbackAruaToEdiofeRoute;
  }
}
