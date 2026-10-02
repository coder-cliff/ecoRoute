import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import '../domain/entities/pickup_request.dart';
import '../domain/enums/request_status.dart';
import '../domain/enums/waste_type.dart';

abstract interface class PickupRequestRepository {
  Future<List<PickupRequest>> loadAll();

  Future<void> save(PickupRequest request);

  Future<void> updateStatus(String id, RequestStatus status);

  Future<void> delete(String id);
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
}

class SharedPreferencesPickupRequestRepository
    implements PickupRequestRepository {
  SharedPreferencesPickupRequestRepository(this._preferences);

  static const _storageKey = 'pickup_requests_v1';
  final SharedPreferences _preferences;

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

  Map<String, Object> _requestToJson(PickupRequest request) => {
    'id': request.id,
    'wasteType': request.wasteType.name,
    'description': request.description,
    'submittedAt': request.submittedAt.toIso8601String(),
    'status': request.status.name,
  };

  PickupRequest _requestFromJson(Map<String, dynamic> json) => PickupRequest(
    id: json['id'] as String,
    wasteType: WasteType.values.byName(json['wasteType'] as String),
    description: json['description'] as String,
    submittedAt: DateTime.parse(json['submittedAt'] as String),
    status: RequestStatus.values.byName(json['status'] as String),
  );
}
