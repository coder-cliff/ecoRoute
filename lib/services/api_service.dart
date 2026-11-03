import 'dart:convert';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:http/http.dart' as http;

class ApiService {
  static const String _nominatimBaseUrl = 'https://nominatim.openstreetmap.org';
  static final Map<String, String> _geocodeCache = {};

  /// Performs reverse geocoding via OpenStreetMap Nominatim REST API
  /// with in-memory coordinate caching and web-safe headers.
  static Future<String> reverseGeocode({
    required double latitude,
    required double longitude,
  }) async {
    final cacheKey = '${latitude.toStringAsFixed(4)},${longitude.toStringAsFixed(4)}';
    if (_geocodeCache.containsKey(cacheKey)) {
      return _geocodeCache[cacheKey]!;
    }

    final uri = Uri.parse(
      '$_nominatimBaseUrl/reverse?format=json'
      '&lat=$latitude&lon=$longitude&zoom=18&addressdetails=1'
      '&email=contact@ecoroute.app',
    );

    try {
      final response = await http
          .get(
            uri,
            headers: kIsWeb
                ? const {'Accept': 'application/json'}
                : const {
                    'User-Agent': 'EcoRouteFlutterApp/1.0 (contact@ecoroute.app)',
                    'Accept': 'application/json',
                  },
          )
          .timeout(const Duration(seconds: 5));

      if (response.statusCode == 200) {
        final Map<String, dynamic> data = jsonDecode(response.body);
        final address = data['address'] as Map<String, dynamic>?;

        if (address != null) {
          final road = address['road'] ??
              address['pedestrian'] ??
              address['suburb'] ??
              address['neighbourhood'] ??
              '';
          final city = address['city'] ??
              address['town'] ??
              address['village'] ??
              address['county'] ??
              '';
          final country = address['country'] ?? '';

          final parts = [road, city, country]
              .where((element) => element.toString().isNotEmpty)
              .toList();

          if (parts.isNotEmpty) {
            final formatted = parts.join(', ');
            _geocodeCache[cacheKey] = formatted;
            return formatted;
          }
        }

        final displayName = data['display_name'] as String?;
        if (displayName != null && displayName.isNotEmpty) {
          final formatted = displayName.split(', ').take(3).join(', ');
          _geocodeCache[cacheKey] = formatted;
          return formatted;
        }
      }
    } catch (_) {
      // Fallback on network timeout or offline state
    }

    final fallback =
        'Sector ${latitude.toStringAsFixed(3)}, Long ${longitude.toStringAsFixed(3)} (Kampala Metro)';
    _geocodeCache[cacheKey] = fallback;
    return fallback;
  }

  /// Computes carbon savings and landfill metrics
  static Map<String, String> calculateEcoImpact({
    required double totalCarbonSavedKg,
    required int totalBags,
  }) {
    final trees = totalCarbonSavedKg / 22.0;
    final carKm = totalCarbonSavedKg / 0.192;
    final landfillVolumeM3 = totalBags * 0.05;

    return {
      'treesEquivalent': trees.toStringAsFixed(1),
      'carKmOffset': carKm.toStringAsFixed(0),
      'landfillVolumeM3': landfillVolumeM3.toStringAsFixed(2),
    };
  }
}
