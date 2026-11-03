import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;

class ApiService {
  /// Reverse geocodes GPS coordinates to human-readable street address
  /// Uses OpenStreetMap Nominatim REST API (Week 9 External Data Integration)
  static Future<String> reverseGeocode({
    required double latitude,
    required double longitude,
  }) async {
    try {
      final uri = Uri.parse(
        'https://nominatim.openstreetmap.org/reverse?format=json&lat=$latitude&lon=$longitude&zoom=18&addressdetails=1',
      );

      final response = await http.get(
        uri,
        headers: {
          'User-Agent': 'EcoRouteFlutterApp/1.0 (contact@ecoroute.app)',
          'Accept': 'application/json',
        },
      ).timeout(const Duration(seconds: 5));

      if (response.statusCode == 200) {
        final Map<String, dynamic> data = jsonDecode(response.body);
        final addressObj = data['address'] as Map<String, dynamic>?;

        if (addressObj != null) {
          final road = addressObj['road'] ?? addressObj['suburb'] ?? addressObj['neighbourhood'] ?? '';
          final city = addressObj['city'] ?? addressObj['town'] ?? addressObj['county'] ?? addressObj['state'] ?? '';
          final country = addressObj['country'] ?? '';

          final parts = [road, city, country].where((s) => s.toString().isNotEmpty).toList();
          if (parts.isNotEmpty) {
            return parts.join(', ');
          }
        }

        if (data['display_name'] != null) {
          final displayName = data['display_name'] as String;
          final shortParts = displayName.split(',').take(3).map((e) => e.trim()).join(', ');
          return shortParts.isNotEmpty ? shortParts : displayName;
        }
      }
    } catch (e) {
      debugPrint('Nominatim API error or offline: $e');
    }

    // Graceful offline fallback address based on coordinates
    return 'Sector ${latitude.toStringAsFixed(3)}, Long ${longitude.toStringAsFixed(3)} (Acacia Ave Area)';
  }

  /// Calculates dynamic carbon offset and environmental impact
  static Map<String, dynamic> calculateEcoImpact({
    required double totalCarbonSavedKg,
    required int totalBags,
  }) {
    // 1 mature tree absorbs ~22kg of CO2 per year
    final treesEquivalent = (totalCarbonSavedKg / 22.0).toStringAsFixed(1);
    // Average car emits ~0.192 kg CO2 per km driven
    final carKmOffset = (totalCarbonSavedKg / 0.192).toStringAsFixed(0);
    // Landfill volume diverted: ~0.05 cubic meters per bag
    final landfillVolumeM3 = (totalBags * 0.05).toStringAsFixed(2);

    return {
      'treesEquivalent': treesEquivalent,
      'carKmOffset': carKmOffset,
      'landfillVolumeM3': landfillVolumeM3,
    };
  }
}
