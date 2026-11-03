import 'dart:math';
import 'package:flutter/foundation.dart';
import '../models/waste_request.dart';
import '../models/waste_category.dart';
import '../services/storage_service.dart';

class WasteRequestProvider with ChangeNotifier {
  List<WasteRequest> _requests = [];
  bool _isLoading = false;
  String _selectedFilter = 'all'; // 'all', 'pending', 'assigned', 'collected'

  List<WasteRequest> get requests => _requests;
  bool get isLoading => _isLoading;
  String get selectedFilter => _selectedFilter;

  void setFilter(String filter) {
    _selectedFilter = filter;
    notifyListeners();
  }

  Future<void> loadRequests() async {
    _isLoading = true;
    notifyListeners();

    _requests = await StorageService.loadRequests();

    _isLoading = false;
    notifyListeners();
  }

  // Requests created by a specific citizen
  List<WasteRequest> getCitizenRequests(String userId) {
    return _requests.where((r) => r.userId == userId).toList()
      ..sort((a, b) => b.createdAt.compareTo(a.createdAt));
  }

  // Requests assigned to a specific rider
  List<WasteRequest> getRiderAssignedRequests(String riderId) {
    return _requests
        .where((r) => r.assignedRiderId == riderId && r.status == RequestStatus.assigned)
        .toList()
      ..sort((a, b) => a.scheduledPickupTime.compareTo(b.scheduledPickupTime));
  }

  // Available pending requests open for riders to accept
  List<WasteRequest> get availableUnassignedRequests {
    return _requests
        .where((r) => r.status == RequestStatus.pending)
        .toList()
      ..sort((a, b) => b.createdAt.compareTo(a.createdAt));
  }

  // Completed collections for a rider
  List<WasteRequest> getRiderCompletedRequests(String riderId) {
    return _requests
        .where((r) => r.assignedRiderId == riderId && r.status == RequestStatus.collected)
        .toList()
      ..sort((a, b) => (b.collectedAt ?? b.createdAt).compareTo(a.collectedAt ?? a.createdAt));
  }

  // Filtered requests for Admin dashboard
  List<WasteRequest> get adminFilteredRequests {
    if (_selectedFilter == 'pending') {
      return _requests.where((r) => r.status == RequestStatus.pending).toList();
    } else if (_selectedFilter == 'assigned') {
      return _requests.where((r) => r.status == RequestStatus.assigned).toList();
    } else if (_selectedFilter == 'collected') {
      return _requests.where((r) => r.status == RequestStatus.collected).toList();
    }
    return List.from(_requests)..sort((a, b) => b.createdAt.compareTo(a.createdAt));
  }

  // Statistics
  double get totalCashCollected {
    return _requests
        .where((r) => r.isCashCollected)
        .fold(0.0, (sum, r) => sum + (r.actualCashPaid ?? r.estimatedCashAmount));
  }

  int get totalBagsCollected {
    return _requests
        .where((r) => r.status == RequestStatus.collected)
        .fold(0, (sum, r) => sum + r.quantityBags);
  }

  double get totalCarbonSavedKg {
    return _requests
        .where((r) => r.status == RequestStatus.collected)
        .fold(0.0, (sum, r) => sum + r.totalCarbonSavedKg);
  }

  int get pendingCount => _requests.where((r) => r.status == RequestStatus.pending).length;
  int get assignedCount => _requests.where((r) => r.status == RequestStatus.assigned).length;
  int get collectedCount => _requests.where((r) => r.status == RequestStatus.collected).length;

  /// Citizen creates a new waste collection request
  Future<WasteRequest> createRequest({
    required String userId,
    required String userName,
    required String userPhone,
    required String photoPath,
    required WasteCategoryType categoryType,
    required int quantityBags,
    required double latitude,
    required double longitude,
    required String address,
    required String notes,
    required DateTime scheduledPickupTime,
  }) async {
    final category = WasteCategory.getByType(categoryType);
    final estimatedCashAmount = category.pricePerUnit * quantityBags;
    final randomIdNum = 100 + Random().nextInt(900);
    final id = 'REQ-2026-$randomIdNum';

    final newRequest = WasteRequest(
      id: id,
      userId: userId,
      userName: userName,
      userPhone: userPhone,
      photoPath: photoPath,
      categoryType: categoryType,
      quantityBags: quantityBags,
      latitude: latitude,
      longitude: longitude,
      address: address,
      notes: notes,
      estimatedCashAmount: estimatedCashAmount,
      status: RequestStatus.pending,
      createdAt: DateTime.now(),
      scheduledPickupTime: scheduledPickupTime,
    );

    _requests.insert(0, newRequest);
    await StorageService.saveRequests(_requests);
    notifyListeners();
    return newRequest;
  }

  /// Admin or Rider assigns request to a rider
  Future<void> assignRider({
    required String requestId,
    required String riderId,
    required String riderName,
  }) async {
    final index = _requests.indexWhere((r) => r.id == requestId);
    if (index != -1) {
      _requests[index] = _requests[index].copyWith(
        status: RequestStatus.assigned,
        assignedRiderId: riderId,
        assignedRiderName: riderName,
      );
      await StorageService.saveRequests(_requests);
      notifyListeners();
    }
  }

  /// Rider confirms collection and records cash payment
  Future<void> confirmCashCollection({
    required String requestId,
    required double amountCollected,
  }) async {
    final index = _requests.indexWhere((r) => r.id == requestId);
    if (index != -1) {
      final receiptNum = 'RCP-${10000 + Random().nextInt(90000)}';
      _requests[index] = _requests[index].copyWith(
        status: RequestStatus.collected,
        isCashCollected: true,
        actualCashPaid: amountCollected,
        collectedAt: DateTime.now(),
        receiptNumber: receiptNum,
      );
      await StorageService.saveRequests(_requests);
      notifyListeners();
    }
  }

  /// Citizen or Admin cancels request
  Future<void> cancelRequest(String requestId) async {
    final index = _requests.indexWhere((r) => r.id == requestId);
    if (index != -1) {
      _requests[index] = _requests[index].copyWith(
        status: RequestStatus.cancelled,
      );
      await StorageService.saveRequests(_requests);
      notifyListeners();
    }
  }

  /// Delete request (CRUD delete operation)
  Future<void> deleteRequest(String requestId) async {
    _requests.removeWhere((r) => r.id == requestId);
    await StorageService.saveRequests(_requests);
    notifyListeners();
  }
}
