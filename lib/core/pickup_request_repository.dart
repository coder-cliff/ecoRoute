import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import '../domain/entities/pickup_request.dart';
import '../domain/enums/request_status.dart';
import '../domain/enums/waste_type.dart';
import '../domain/enums/zone.dart';

abstract interface class PickupRequestRepository {
  Future<List<PickupRequest>> loadAll();

  Future<void> save(PickupRequest request);

  Future<void> updateStatus(String id, RequestStatus status);

  Future<void> delete(String id);

  Future<void> seedDemoData({bool force = false});
}

class MemoryPickupRequestRepository implements PickupRequestRepository {
  const MemoryPickupRequestRepository();

  static final List<PickupRequest> _requests = [];

  @override
  Future<List<PickupRequest>> loadAll() async => List.unmodifiable(_requests);

  @override
  Future<void> save(PickupRequest request) async {
    _requests.removeWhere((existing) => existing.id == request.id);
    _requests.insert(0, request);
  }

  @override
  Future<void> updateStatus(String id, RequestStatus status) async {
    final index = _requests.indexWhere((request) => request.id == id);
    if (index == -1) return;

    _requests[index] = _requests[index].copyWith(status: status);
  }

  @override
  Future<void> delete(String id) async {
    _requests.removeWhere((request) => request.id == id);
  }

  @override
  Future<void> seedDemoData({bool force = false}) async {
    if (_requests.isNotEmpty && !force) return;
    _requests.clear();
    _requests.addAll(getInitialDemoRequests());
  }
}

class SharedPreferencesPickupRequestRepository
    implements PickupRequestRepository {
  SharedPreferencesPickupRequestRepository(this._preferences);

  static const _storageKey = 'pickup_requests_v1';
  final SharedPreferences _preferences;

  @override
  Future<void> seedDemoData({bool force = false}) async {
    final stored = _preferences.getString(_storageKey);
    if (stored != null && !force) return;

    final initial = getInitialDemoRequests();
    await _preferences.setString(
      _storageKey,
      jsonEncode(initial.map(_requestToJson).toList()),
    );
  }

  @override
  Future<List<PickupRequest>> loadAll() async {
    final stored = _preferences.getString(_storageKey);
    if (stored == null) return [];

    try {
      final decoded = jsonDecode(stored) as List<dynamic>;
      return decoded
          .map((value) => _requestFromJson(value as Map<String, dynamic>))
          .toList();
    } on FormatException {
      return [];
    } on TypeError {
      return [];
    }
  }

  @override
  Future<void> save(PickupRequest request) async {
    final requests = await loadAll();
    requests.removeWhere((existing) => existing.id == request.id);
    requests.insert(0, request);
    await _preferences.setString(
      _storageKey,
      jsonEncode(requests.map(_requestToJson).toList()),
    );
  }

  @override
  Future<void> updateStatus(String id, RequestStatus status) async {
    final requests = await loadAll();
    final index = requests.indexWhere((request) => request.id == id);
    if (index == -1) return;

    requests[index] = requests[index].copyWith(status: status);
    await _preferences.setString(
      _storageKey,
      jsonEncode(requests.map(_requestToJson).toList()),
    );
  }

  @override
  Future<void> delete(String id) async {
    final requests = await loadAll();
    requests.removeWhere((request) => request.id == id);
    await _preferences.setString(
      _storageKey,
      jsonEncode(requests.map(_requestToJson).toList()),
    );
  }

  Map<String, Object?> _requestToJson(PickupRequest request) => {
    'id': request.id,
    'wasteType': request.wasteType.name,
    'description': request.description,
    'submittedAt': request.submittedAt.toIso8601String(),
    'status': request.status.name,
    'sackCount': request.sackCount,
    'priceUgx': request.priceUgx,
    'zone': request.zone.name,
    'address': request.address,
    'latitude': request.latitude,
    'longitude': request.longitude,
    'residentName': request.residentName,
    'residentPhone': request.residentPhone,
    'residentId': request.residentId,
  };

  PickupRequest _requestFromJson(Map<String, dynamic> json) => PickupRequest(
    id: json['id'] as String,
    wasteType: WasteType.values.byName(json['wasteType'] as String),
    description: json['description'] as String,
    submittedAt: DateTime.parse(json['submittedAt'] as String),
    status: RequestStatus.values.byName(json['status'] as String),
    sackCount: (json['sackCount'] as num?)?.toInt() ?? 1,
    priceUgx: (json['priceUgx'] as num?)?.toInt() ?? 1500,
    zone: json['zone'] != null
        ? Zone.values.byName(json['zone'] as String)
        : Zone.north,
    address: json['address'] as String? ?? 'Arua Central',
    latitude: (json['latitude'] as num?)?.toDouble(),
    longitude: (json['longitude'] as num?)?.toDouble(),
    residentName: json['residentName'] as String? ?? 'Resident',
    residentPhone: json['residentPhone'] as String? ?? '+256 772 000 001',
    residentId: json['residentId'] as String? ?? 'resident-1',
  );
}

/// Initial realistic demonstration requests for Arua City
List<PickupRequest> getInitialDemoRequests() {
  final now = DateTime.now();
  return [
    PickupRequest(
      id: 'req-arua-01',
      wasteType: WasteType.household,
      description: 'Household sorted recyclables and domestic sacks behind market stalls.',
      submittedAt: now.subtract(const Duration(hours: 3)),
      status: RequestStatus.requested,
      sackCount: 3,
      priceUgx: 4500,
      zone: Zone.north,
      address: 'Arua Central Market, North Division',
      latitude: 3.0315,
      longitude: 30.9102,
      residentName: 'Amina Dranzoa',
      residentPhone: '+256394880352',
      residentId: 'resident-1',
    ),
    PickupRequest(
      id: 'req-arua-02',
      wasteType: WasteType.tradingCenter,
      description: 'Commercial trading center cardboard and packaging waste ready for collection.',
      submittedAt: now.subtract(const Duration(hours: 6)),
      status: RequestStatus.collected,
      sackCount: 5,
      priceUgx: 12500,
      zone: Zone.west,
      address: 'River Oli Trading Corridor, West Division',
      latitude: 3.0180,
      longitude: 30.9020,
      residentName: 'Kassim Anguyo',
      residentPhone: '+256394880352',
      residentId: 'resident-2',
    ),
    PickupRequest(
      id: 'req-arua-03',
      wasteType: WasteType.household,
      description: 'Residential sacks collected from mission quarter, awaiting verification.',
      submittedAt: now.subtract(const Duration(hours: 9)),
      status: RequestStatus.awaitingVerification,
      sackCount: 2,
      priceUgx: 3000,
      zone: Zone.west,
      address: 'Ediofe Road, West Division',
      latitude: 3.0290,
      longitude: 30.8850,
      residentName: 'Sister Beatrice',
      residentPhone: '+256394880352',
      residentId: 'resident-3',
    ),
    PickupRequest(
      id: 'req-arua-04',
      wasteType: WasteType.household,
      description: 'Agro-compostable organic waste verified and settled via MTN MoMo.',
      submittedAt: now.subtract(const Duration(hours: 24)),
      status: RequestStatus.paid,
      sackCount: 4,
      priceUgx: 6000,
      zone: Zone.south,
      address: 'Muni University Staff Quarters, South Division',
      latitude: 2.9980,
      longitude: 30.9180,
      residentName: 'Dr. Taban Charles',
      residentPhone: '+256394880352',
      residentId: 'resident-4',
    ),
    PickupRequest(
      id: 'req-arua-05',
      wasteType: WasteType.household,
      description: 'Plastic beverage bottles and clean paper bundled in sacks.',
      submittedAt: now.subtract(const Duration(hours: 2)),
      status: RequestStatus.requested,
      sackCount: 2,
      priceUgx: 3000,
      zone: Zone.east,
      address: 'Arua Hill Residential, East Division',
      latitude: 3.0250,
      longitude: 30.9230,
      residentName: 'Grace Candiru',
      residentPhone: '+256394880352',
      residentId: 'resident-1',
    ),
  ];
}
