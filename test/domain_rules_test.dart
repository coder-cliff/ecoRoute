import 'package:ecoroute/domain/enums/request_status.dart';
import 'package:ecoroute/domain/enums/zone.dart';
import 'package:ecoroute/domain/rules/status_machine.dart';
import 'package:ecoroute/domain/rules/zone_resolver.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('zone rules', () {
    test('resolveZone picks the axis farther from the center', () {
      const centerLat = 3.0500;
      const centerLng = 30.9100;

      expect(
        resolveZone(
          3.0600,
          30.9100,
          centerLat: centerLat,
          centerLng: centerLng,
        ),
        Zone.north,
      );
      expect(
        resolveZone(
          3.0500,
          30.9200,
          centerLat: centerLat,
          centerLng: centerLng,
        ),
        Zone.east,
      );
      expect(
        resolveZone(
          3.0400,
          30.9100,
          centerLat: centerLat,
          centerLng: centerLng,
        ),
        Zone.south,
      );
      expect(
        resolveZone(
          3.0500,
          30.9000,
          centerLat: centerLat,
          centerLng: centerLng,
        ),
        Zone.west,
      );
    });

    test(
      'service area check rejects coordinates beyond the configured radius',
      () {
        const centerLat = 3.0500;
        const centerLng = 30.9100;

        expect(
          isWithinServiceArea(
            3.0500,
            30.9100,
            centerLat: centerLat,
            centerLng: centerLng,
            radiusKm: 12,
          ),
          isTrue,
        );

        expect(
          isWithinServiceArea(
            3.1600,
            30.9100,
            centerLat: centerLat,
            centerLng: centerLng,
            radiusKm: 12,
          ),
          isFalse,
        );
      },
    );
  });

  group('status transitions', () {
    test('valid transitions follow the MVP state machine', () {
      expect(
        isValidTransition(RequestStatus.requested, RequestStatus.collected),
        isTrue,
      );
      expect(
        isValidTransition(RequestStatus.requested, RequestStatus.cancelled),
        isTrue,
      );
      expect(
        isValidTransition(
          RequestStatus.collected,
          RequestStatus.awaitingVerification,
        ),
        isTrue,
      );
      expect(
        isValidTransition(
          RequestStatus.awaitingVerification,
          RequestStatus.paid,
        ),
        isTrue,
      );
      expect(
        isValidTransition(
          RequestStatus.awaitingVerification,
          RequestStatus.collected,
        ),
        isTrue,
      );
      expect(
        isValidTransition(RequestStatus.requested, RequestStatus.paid),
        isFalse,
      );
    });
  });
}
