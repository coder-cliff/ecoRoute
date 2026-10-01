import 'package:ecoroute/core/pickup_request_repository.dart';
import 'package:ecoroute/domain/entities/pickup_request.dart';
import 'package:ecoroute/domain/enums/request_status.dart';
import 'package:ecoroute/domain/enums/waste_type.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('SharedPreferencesPickupRequestRepository', () {
    late SharedPreferences preferences;
    late SharedPreferencesPickupRequestRepository repository;

    setUp(() async {
      SharedPreferences.setMockInitialValues({});
      preferences = await SharedPreferences.getInstance();
      repository = SharedPreferencesPickupRequestRepository(preferences);
    });

    test('persists requests and restores all request fields', () async {
      final submittedAt = DateTime.utc(2026, 10, 1, 12);
      final request = PickupRequest(
        id: 'request-1',
        wasteType: WasteType.tradingCenter,
        description: 'Three sacks beside the market entrance',
        submittedAt: submittedAt,
        status: RequestStatus.collected,
      );

      await repository.save(request);
      final restored = await repository.loadAll();

      expect(restored, hasLength(1));
      expect(restored.single.id, request.id);
      expect(restored.single.wasteType, request.wasteType);
      expect(restored.single.description, request.description);
      expect(restored.single.submittedAt, request.submittedAt);
      expect(restored.single.status, request.status);
    });

    test('new requests are listed before earlier requests', () async {
      final first = PickupRequest(
        id: 'first',
        wasteType: WasteType.household,
        description: 'Household waste by the gate',
        submittedAt: DateTime.utc(2026, 10, 1),
      );
      final second = first.copyWith(id: 'second');

      await repository.save(first);
      await repository.save(second);

      expect((await repository.loadAll()).map((request) => request.id), [
        'second',
        'first',
      ]);
    });
  });
}
