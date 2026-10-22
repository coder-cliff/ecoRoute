import 'package:ecoroute/core/pickup_request_repository.dart';
import 'package:ecoroute/domain/entities/pickup_request.dart';
import 'package:ecoroute/domain/enums/request_status.dart';
import 'package:ecoroute/domain/enums/waste_type.dart';
import 'package:ecoroute/domain/enums/zone.dart';
import 'package:ecoroute/domain/rules/price_calculator.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('Enhanced Order & Data Persistence (Weeks 5, 6, 7)', () {
    test('computes price dynamically for commercial vs household sacks', () {
      final householdTotal = calculateAmount(sackCount: 3, pricePerSackUgx: 1500);
      expect(householdTotal, 4500);

      final tradingCenterTotal = calculateAmount(sackCount: 4, pricePerSackUgx: 2500);
      expect(tradingCenterTotal, 10000);
    });

    test('persists and restores all extended pickup request fields in repository', () async {
      SharedPreferences.setMockInitialValues({});
      final preferences = await SharedPreferences.getInstance();
      final repo = SharedPreferencesPickupRequestRepository(preferences);

      final request = PickupRequest(
        id: 'ord-100',
        wasteType: WasteType.tradingCenter,
        description: 'Near Duka la Maduka, Arua Hill',
        submittedAt: DateTime(2026, 10, 22, 10, 30),
        status: RequestStatus.requested,
        sackCount: 5,
        priceUgx: 12500,
        zone: Zone.east,
        address: 'Arua Hill Market, Stand 14',
        latitude: 3.0520,
        longitude: 30.9180,
        residentName: 'Kezia Candia',
        residentPhone: '+256 772 333 444',
        residentId: 'user-77',
      );

      await repo.save(request);

      final loaded = await repo.loadAll();
      expect(loaded.length, 1);

      final item = loaded.first;
      expect(item.id, 'ord-100');
      expect(item.wasteType, WasteType.tradingCenter);
      expect(item.sackCount, 5);
      expect(item.priceUgx, 12500);
      expect(item.zone, Zone.east);
      expect(item.address, 'Arua Hill Market, Stand 14');
      expect(item.latitude, 3.0520);
      expect(item.longitude, 30.9180);
      expect(item.residentName, 'Kezia Candia');
      expect(item.residentPhone, '+256 772 333 444');
      expect(item.residentId, 'user-77');

      // Update status
      await repo.updateStatus('ord-100', RequestStatus.collected);
      final updatedList = await repo.loadAll();
      expect(updatedList.first.status, RequestStatus.collected);

      // Delete / Cancel
      await repo.delete('ord-100');
      final afterDelete = await repo.loadAll();
      expect(afterDelete, isEmpty);
    });
  });
}
