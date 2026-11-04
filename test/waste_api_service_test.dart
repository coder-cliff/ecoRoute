import 'dart:convert';

import 'package:ecoroute/core/services/waste_api_service.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';

void main() {
  group('WasteApiService (Week 9 REST API integration)', () {
    test('parses live Open-Meteo weather JSON response successfully', () async {
      final mockClient = MockClient((request) async {
        return http.Response(
          jsonEncode({
            'current_weather': {
              'temperature': 28.2,
              'windspeed': 11.5,
              'weathercode': 0,
            },
          }),
          200,
          headers: {'content-type': 'application/json'},
        );
      });

      final service = WasteApiService(client: mockClient);
      final report = await service.fetchAruaCollectionWeather();

      expect(report.isOnline, isTrue);
      expect(report.temperatureC, 28.2);
      expect(report.windSpeedKmH, 11.5);
      expect(report.weatherCode, 0);
      expect(report.isSafeForCollection, isTrue);
      expect(report.conditionSummary, contains('Favorable'));
    });

    test('detects rain weather code and flags route delay advisory', () async {
      final mockClient = MockClient((request) async {
        return http.Response(
          jsonEncode({
            'current_weather': {
              'temperature': 21.0,
              'windspeed': 14.0,
              'weathercode': 63, // Rain
            },
          }),
          200,
          headers: {'content-type': 'application/json'},
        );
      });

      final service = WasteApiService(client: mockClient);
      final report = await service.fetchAruaCollectionWeather();

      expect(report.isOnline, isTrue);
      expect(report.isSafeForCollection, isFalse);
      expect(report.conditionSummary, contains('Rain reported'));
    });

    test('gracefully falls back to offline cache on network error / non-200', () async {
      final mockClient = MockClient((request) async {
        return http.Response('Internal Server Error', 500);
      });

      final service = WasteApiService(client: mockClient);
      final report = await service.fetchAruaCollectionWeather();

      expect(report.isOnline, isFalse);
      expect(report.temperatureC, 26.5);
      expect(report.isSafeForCollection, isTrue);
      expect(report.conditionSummary, contains('Offline cache'));
    });

    test('fetches standardized municipal waste tariff guidelines', () async {
      final service = WasteApiService();
      final guidelines = await service.fetchTariffGuidelines();

      expect(guidelines.length, 3);
      expect(guidelines.first.ratePerSackUgx, 1500);
      expect(guidelines.first.scheduleDay, contains('Wednesdays'));
    });
  });
}
