import 'package:ecoroute/core/services/location_service.dart';
import 'package:ecoroute/domain/enums/zone.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('LocationService (Week 11 Device Capability & Zone Integration)', () {
    const service = LocationService();

    test('evaluates coordinates within Arua municipal service area', () {
      // Within 2km of center (3.05, 30.91)
      final result = service.evaluateCoordinates(3.0550, 30.9100);

      expect(result.status, LocationServiceStatus.success);
      expect(result.isWithinServiceArea, isTrue);
      expect(result.resolvedZone, Zone.north);
      expect(result.message, contains('within Arua North zone'));
    });

    test('flags coordinates outside the 12 km Arua service boundary', () {
      // ~25km away from Arua
      final result = service.evaluateCoordinates(3.2800, 30.9100);

      expect(result.status, LocationServiceStatus.outsideServiceArea);
      expect(result.isWithinServiceArea, isFalse);
      expect(result.message, contains('beyond the 12 km Arua service boundary'));
    });

    test('resolves south and east zones from coordinates', () {
      final southResult = service.evaluateCoordinates(3.0300, 30.9100);
      expect(southResult.resolvedZone, Zone.south);

      final eastResult = service.evaluateCoordinates(3.0500, 30.9300);
      expect(eastResult.resolvedZone, Zone.east);
    });
  });
}
