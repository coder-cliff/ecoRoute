import 'dart:convert';
import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart' as firebase_auth;
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../domain/entities/pickup_request.dart';
import '../domain/enums/request_status.dart';
import '../domain/enums/waste_type.dart';
import '../domain/enums/zone.dart';

abstract interface class PickupRequestRepository {
  Future<List<PickupRequest>> loadAll();

  Stream<List<PickupRequest>> watchRequests({int limit = 50});

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
  Stream<List<PickupRequest>> watchRequests({int limit = 50}) =>
      Stream.value(List.unmodifiable(_requests.take(limit).toList()));

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
  Stream<List<PickupRequest>> watchRequests({int limit = 50}) async* {
    final all = await loadAll();
    yield all.take(limit).toList();
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
    'isInstant': request.isInstant,
    'zone': request.zone.name,
    'address': request.address,
    'latitude': request.latitude,
    'longitude': request.longitude,
    'residentName': request.residentName,
    'residentPhone': request.residentPhone,
    'residentId': request.residentId,
    'photoUrl': request.photoUrl,
    'isSynced': request.isSynced,
    'paymentMethod': request.paymentMethod,
    'cashReceivedByRider': request.cashReceivedByRider,
    'receiptNumber': request.receiptNumber,
    'paidAt': request.paidAt?.toIso8601String(),
    'isCommercial': request.isCommercial,
    'businessName': request.businessName,
    'tinNumber': request.tinNumber,
    'serviceTier': request.serviceTier,
  };

  PickupRequest _requestFromJson(Map<String, dynamic> json) => PickupRequest(
    id: json['id'] as String,
    wasteType: WasteType.values.byName(json['wasteType'] as String),
    description: json['description'] as String,
    submittedAt: DateTime.parse(json['submittedAt'] as String),
    status: RequestStatus.values.byName(json['status'] as String),
    sackCount: (json['sackCount'] as num?)?.toInt() ?? 1,
    priceUgx: (json['priceUgx'] as num?)?.toInt() ?? 1500,
    isInstant: (json['isInstant'] as bool?) ?? true,
    zone: json['zone'] != null
        ? Zone.values.byName(json['zone'] as String)
        : Zone.north,
    address: json['address'] as String? ?? 'Arua Central',
    latitude: (json['latitude'] as num?)?.toDouble(),
    longitude: (json['longitude'] as num?)?.toDouble(),
    residentName: json['residentName'] as String? ?? 'Resident',
    residentPhone: json['residentPhone'] as String? ?? '+256 772 000 001',
    residentId: json['residentId'] as String? ?? 'resident-1',
    photoUrl: json['photoUrl'] as String?,
    isSynced: (json['isSynced'] as bool?) ?? true,
    paymentMethod: json['paymentMethod'] as String? ?? 'unpaid',
    cashReceivedByRider: (json['cashReceivedByRider'] as bool?) ?? false,
    receiptNumber: json['receiptNumber'] as String?,
    paidAt: json['paidAt'] != null ? DateTime.tryParse(json['paidAt'] as String) : null,
    isCommercial: (json['isCommercial'] as bool?) ?? false,
    businessName: json['businessName'] as String?,
    tinNumber: json['tinNumber'] as String?,
    serviceTier: json['serviceTier'] as String?,
  );
}

class FirebasePickupRequestRepository implements PickupRequestRepository {
  FirebasePickupRequestRepository(
    this._localRepository, {
    required this._firestore,
    required this._firebaseAuth,
  });

  final SharedPreferencesPickupRequestRepository _localRepository;
  final FirebaseFirestore _firestore;
  final firebase_auth.FirebaseAuth _firebaseAuth;

  CollectionReference<Map<String, dynamic>> get _requests =>
      _firestore.collection('pickupRequests');

  @override
  Future<void> seedDemoData({bool force = false}) =>
      _localRepository.seedDemoData(force: force);

  Future<String> _getUserRole(firebase_auth.User user) async {
    final email = user.email?.toLowerCase().trim() ?? '';
    if (email == 'saviordeogratius@yahoo.com' ||
        email == 'techcliff451@hotmail.com' ||
        email == 'saviordeogratius@gmail.com' ||
        email == 'techcliff451@gmail.com' ||
        email.contains('admin')) {
      return 'admin';
    }

    try {
      final doc = await _firestore.collection('profiles').doc(user.uid).get();
      final role = doc.data()?['role'] as String?;
      if (role != null && role.isNotEmpty) {
        return role.toLowerCase().trim();
      }
    } catch (_) {}

    return 'resident';
  }

  @override
  Future<List<PickupRequest>> loadAll() async {
    final localRequests = await _localRepository.loadAll();
    final user = _firebaseAuth.currentUser;
    if (user == null) {
      // Purge legacy demo requests from unauthenticated view
      return localRequests.where((r) => !r.id.startsWith('req-arua-')).toList();
    }

    // Clean out stale demo requests from local storage if present
    for (final req in localRequests) {
      if (req.id.startsWith('req-arua-')) {
        await _localRepository.delete(req.id);
      }
    }

    try {
      final role = await _getUserRole(user);
      final query = _requests.orderBy('submittedAt', descending: true);
      final snapshot = (role == 'admin' || role == 'rider')
          ? await query.get()
          : await query.where('residentId', isEqualTo: user.uid).get();

      final cloudRequests = snapshot.docs.map(_requestFromDocument).toList();
      final cloudIds = cloudRequests.map((c) => c.id).toSet();

      // Auto-sync any genuine local requests to Firestore if missing from cloud
      for (final req in localRequests) {
        if (!req.id.startsWith('req-arua-') && !cloudIds.contains(req.id)) {
          if (role != 'resident' || req.residentId == user.uid) {
            try {
              await _requests.doc(req.id).set(
                _requestToDocument(req),
                SetOptions(merge: true),
              );
              cloudRequests.add(req.copyWith(isSynced: true));
              cloudIds.add(req.id);
            } catch (e) {
              debugPrint('Auto-sync cloud upload notice for ${req.id}: $e');
            }
          }
        }
      }

      cloudRequests.sort((a, b) => b.submittedAt.compareTo(a.submittedAt));

      // Overwrite local cache with authoritative cloud state
      for (final req in cloudRequests) {
        await _localRepository.save(req);
      }

      return cloudRequests;
    } on FirebaseException catch (error) {
      debugPrint('Firestore read notice (${error.code}): ${error.message}; falling back to local requests.');
      return localRequests.where((r) => !r.id.startsWith('req-arua-')).toList();
    } catch (error) {
      debugPrint('Repository loadAll error: $error; falling back to local requests.');
      return localRequests.where((r) => !r.id.startsWith('req-arua-')).toList();
    }
  }

  @override
  Stream<List<PickupRequest>> watchRequests({int limit = 50}) {
    final user = _firebaseAuth.currentUser;
    if (user == null) {
      return Stream.fromFuture(loadAll());
    }

    return Stream.fromFuture(_getUserRole(user)).asyncExpand((role) {
      Query<Map<String, dynamic>> query = _requests.orderBy('submittedAt', descending: true);
      if (role != 'admin' && role != 'rider') {
        query = query.where('residentId', isEqualTo: user.uid);
      }
      return query
          .limit(limit)
          .snapshots()
          .map((snapshot) => snapshot.docs.map(_requestFromDocument).toList());
    }).handleError((dynamic error) {
      debugPrint('Firestore watchRequests notice: $error');
    });
  }

  @override
  Future<void> save(PickupRequest request) async {
    final user = _firebaseAuth.currentUser;
    if (user != null && user.uid.isNotEmpty && request.residentId.isEmpty) {
      request = request.copyWith(residentId: user.uid);
    }
    await _localRepository.save(request);
    if (user == null) return;
    _queueCloudWrite(
      _requests.doc(request.id).set(
        _requestToDocument(request),
        SetOptions(merge: true),
      ),
      'save pickup request',
    );
  }

  @override
  Future<void> updateStatus(String id, RequestStatus status) async {
    await _localRepository.updateStatus(id, status);
    if (_firebaseAuth.currentUser == null) return;
    _queueCloudWrite(
      _requests.doc(id).set({
        'status': status.name,
        'updatedAt': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true)),
      'update pickup status',
    );
  }

  @override
  Future<void> delete(String id) async {
    await _localRepository.delete(id);
    if (_firebaseAuth.currentUser == null) return;
    _queueCloudWrite(_requests.doc(id).delete(), 'delete pickup request');
  }

  bool _isConnectivityError(FirebaseException error) =>
      error.code == 'unavailable' ||
      error.code == 'deadline-exceeded' ||
      error.code == 'network-request-failed';

  void _queueCloudWrite(Future<void> write, String operation) {
    unawaited(
      write.catchError((Object error, StackTrace stackTrace) {
        if (error is FirebaseException && _isConnectivityError(error)) {
          debugPrint(
            'Firestore $operation is waiting for a network connection.',
          );
          return;
        }
        debugPrint('Firestore $operation failed: $error');
      }),
    );
  }

  Map<String, Object?> _requestToDocument(PickupRequest request) => {
    'id': request.id,
    'wasteType': request.wasteType.name,
    'description': request.description,
    'submittedAt': Timestamp.fromDate(request.submittedAt),
    'serverSubmittedAt': FieldValue.serverTimestamp(),
    'status': request.status.name,
    'sackCount': request.sackCount,
    'priceUgx': request.priceUgx,
    'isInstant': request.isInstant,
    'zone': request.zone.name,
    'address': request.address,
    'latitude': request.latitude,
    'longitude': request.longitude,
    'residentName': request.residentName,
    'residentPhone': request.residentPhone,
    'residentId': request.residentId,
    'photoUrl': request.photoUrl,
    'paymentMethod': request.paymentMethod,
    'cashReceivedByRider': request.cashReceivedByRider,
    'receiptNumber': request.receiptNumber,
    'paidAt': request.paidAt != null ? Timestamp.fromDate(request.paidAt!) : null,
    'isCommercial': request.isCommercial,
    'businessName': request.businessName,
    'tinNumber': request.tinNumber,
    'serviceTier': request.serviceTier,
    'updatedAt': FieldValue.serverTimestamp(),
  };

  PickupRequest _requestFromDocument(
    QueryDocumentSnapshot<Map<String, dynamic>> document,
  ) {
    final data = document.data();
    final submittedAt = data['serverSubmittedAt'] ?? data['submittedAt'];
    final paidAtRaw = data['paidAt'];
    final paidAt = paidAtRaw is Timestamp
        ? paidAtRaw.toDate()
        : paidAtRaw is int
            ? DateTime.fromMillisecondsSinceEpoch(paidAtRaw)
            : paidAtRaw != null
                ? DateTime.tryParse(paidAtRaw.toString())
                : null;

    return PickupRequest(
      id: data['id'] as String? ?? document.id,
      wasteType: WasteType.values.byName(data['wasteType'] as String),
      description: data['description'] as String,
      submittedAt: submittedAt is Timestamp
          ? submittedAt.toDate()
          : submittedAt is int
              ? DateTime.fromMillisecondsSinceEpoch(submittedAt)
              : DateTime.tryParse(submittedAt?.toString() ?? '') ?? DateTime.now(),
      status: RequestStatus.values.byName(data['status'] as String),
      sackCount: (data['sackCount'] as num?)?.toInt() ?? 1,
      priceUgx: (data['priceUgx'] as num?)?.toInt() ?? 1500,
      isInstant: (data['isInstant'] as bool?) ?? true,
      zone: Zone.values.byName(data['zone'] as String? ?? 'north'),
      address: data['address'] as String? ?? 'Arua Central',
      latitude: (data['latitude'] as num?)?.toDouble(),
      longitude: (data['longitude'] as num?)?.toDouble(),
      residentName: data['residentName'] as String? ?? 'Resident',
      residentPhone: data['residentPhone'] as String? ?? '',
      residentId: data['residentId'] as String,
      photoUrl: data['photoUrl'] as String?,
      isSynced: true,
      paymentMethod: data['paymentMethod'] as String? ?? 'unpaid',
      cashReceivedByRider: (data['cashReceivedByRider'] as bool?) ?? false,
      receiptNumber: data['receiptNumber'] as String?,
      paidAt: paidAt,
      isCommercial: (data['isCommercial'] as bool?) ?? false,
      businessName: data['businessName'] as String?,
      tinNumber: data['tinNumber'] as String?,
      serviceTier: data['serviceTier'] as String?,
    );
  }
}

/// Initial realistic demonstration requests for Arua City
List<PickupRequest> getInitialDemoRequests() {
  final now = DateTime.now();
  return [
    PickupRequest(
      id: 'req-arua-01',
      wasteType: WasteType.household,
      description:
          'Instant pickup: Domestic sorted recyclables behind market stalls.',
      submittedAt: now.subtract(const Duration(hours: 3)),
      status: RequestStatus.requested,
      sackCount: 3,
      priceUgx: 4500,
      isInstant: true,
      zone: Zone.north,
      address: 'Arua Central Market, Main Gate',
      latitude: 3.0315,
      longitude: 30.9102,
      residentName: 'Amina Dranzoa',
      residentPhone: '+256 772 000 001',
      residentId: 'resident-1',
    ),
    PickupRequest(
      id: 'req-arua-02',
      wasteType: WasteType.tradingCenter,
      description: 'Instant pickup: Commercial packaging cardboard dispatched to tricycle.',
      submittedAt: now.subtract(const Duration(hours: 6)),
      status: RequestStatus.collected,
      sackCount: 5,
      priceUgx: 12500,
      isInstant: true,
      zone: Zone.west,
      address: 'River Oli Trading Corridor',
      latitude: 3.0180,
      longitude: 30.9020,
      residentName: 'Kassim Anguyo',
      residentPhone: '+256 772 000 002',
      residentId: 'resident-2',
    ),
    PickupRequest(
      id: 'req-arua-03',
      wasteType: WasteType.household,
      description: 'Instant pickup: Residential sacks collected, awaiting digital verification.',
      submittedAt: now.subtract(const Duration(hours: 9)),
      status: RequestStatus.awaitingVerification,
      sackCount: 2,
      priceUgx: 3000,
      isInstant: true,
      zone: Zone.west,
      address: 'Ediofe Road Junction',
      latitude: 3.0290,
      longitude: 30.8850,
      residentName: 'Sister Beatrice',
      residentPhone: '+256 772 000 003',
      residentId: 'resident-3',
    ),
    PickupRequest(
      id: 'req-arua-04',
      wasteType: WasteType.household,
      description: 'Instant pickup: Agro-compostable organic waste verified and settled via MTN MoMo.',
      submittedAt: now.subtract(const Duration(hours: 24)),
      status: RequestStatus.paid,
      sackCount: 4,
      priceUgx: 6000,
      isInstant: true,
      zone: Zone.south,
      address: 'Muni University Staff Quarters',
      latitude: 2.9980,
      longitude: 30.9180,
      residentName: 'Dr. Taban Charles',
      residentPhone: '+256 772 000 004',
      residentId: 'resident-4',
    ),
    PickupRequest(
      id: 'req-arua-05',
      wasteType: WasteType.household,
      description: 'Instant pickup: Plastic beverage bottles and clean paper bundled in sacks.',
      submittedAt: now.subtract(const Duration(hours: 2)),
      status: RequestStatus.requested,
      sackCount: 2,
      priceUgx: 3000,
      isInstant: true,
      zone: Zone.east,
      address: 'Arua Hill Residential Lane',
      latitude: 3.0250,
      longitude: 30.9230,
      residentName: 'Grace Candiru',
      residentPhone: '+256 772 000 005',
      residentId: 'resident-1',
    ),
  ];
}
