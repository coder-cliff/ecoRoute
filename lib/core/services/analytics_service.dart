import 'package:flutter/foundation.dart';

/// Zero-cost production analytics & operational telemetry logger for ecoRoute Arua.
/// Records operational waste events (pickups, rider shifts, emergency dispatches).
class EcoRouteAnalyticsService {
  EcoRouteAnalyticsService._();
  static final EcoRouteAnalyticsService instance = EcoRouteAnalyticsService._();

  final List<Map<String, dynamic>> _eventLog = [];
  List<Map<String, dynamic>> get eventLog => List.unmodifiable(_eventLog);

  /// Logs a business event with timestamp and contextual metadata
  Future<void> logEvent({
    required String name,
    Map<String, dynamic>? parameters,
  }) async {
    final entry = {
      'event': name,
      'timestamp': DateTime.now().toIso8601String(),
      'parameters': parameters ?? {},
    };
    _eventLog.add(entry);
    if (_eventLog.length > 200) {
      _eventLog.removeAt(0);
    }
    debugPrint('[Analytics] Event: $name | Params: $parameters');
  }

  Future<void> logPickupRequested({
    required String wasteType,
    required int sacks,
    required String zone,
    required bool isInstant,
  }) async {
    await logEvent(
      name: 'pickup_requested',
      parameters: {
        'waste_type': wasteType,
        'sacks': sacks,
        'zone': zone,
        'is_instant': isInstant,
      },
    );
  }

  Future<void> logRiderShiftStarted({
    required String riderId,
    required String tricycleId,
  }) async {
    await logEvent(
      name: 'rider_shift_started',
      parameters: {
        'rider_id': riderId,
        'tricycle_id': tricycleId,
      },
    );
  }

  Future<void> logEmergencyDispatch({
    required String vehicleId,
    required String sector,
    required String reason,
  }) async {
    await logEvent(
      name: 'emergency_dispatch_triggered',
      parameters: {
        'vehicle_id': vehicleId,
        'sector': sector,
        'reason': reason,
      },
    );
  }
}
