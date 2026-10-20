import 'waste_category.dart';

enum RequestStatus {
  pending,
  assigned,
  collected,
  cancelled,
}

extension RequestStatusExtension on RequestStatus {
  String get displayName {
    switch (this) {
      case RequestStatus.pending:
        return 'Pending Dispatch';
      case RequestStatus.assigned:
        return 'Rider Assigned';
      case RequestStatus.collected:
        return 'Collected & Paid';
      case RequestStatus.cancelled:
        return 'Cancelled';
    }
  }
}

class WasteRequest {
  final String id;
  final String userId;
  final String userName;
  final String userPhone;
  final String photoPath;
  final WasteCategoryType categoryType;
  final int quantityBags;
  final double latitude;
  final double longitude;
  final String address;
  final String notes;
  final double estimatedCashAmount;
  final RequestStatus status;
  final String? assignedRiderId;
  final String? assignedRiderName;
  final DateTime createdAt;
  final DateTime scheduledPickupTime;
  final DateTime? collectedAt;
  final bool isCashCollected;
  final double? actualCashPaid;
  final String? receiptNumber;

  const WasteRequest({
    required this.id,
    required this.userId,
    required this.userName,
    required this.userPhone,
    required this.photoPath,
    required this.categoryType,
    required this.quantityBags,
    required this.latitude,
    required this.longitude,
    required this.address,
    required this.notes,
    required this.estimatedCashAmount,
    required this.status,
    this.assignedRiderId,
    this.assignedRiderName,
    required this.createdAt,
    required this.scheduledPickupTime,
    this.collectedAt,
    this.isCashCollected = false,
    this.actualCashPaid,
    this.receiptNumber,
  });

  WasteCategory get category => WasteCategory.getByType(categoryType);

  double get totalCarbonSavedKg => category.carbonSavedPerUnitKg * quantityBags;

  WasteRequest copyWith({
    String? id,
    String? userId,
    String? userName,
    String? userPhone,
    String? photoPath,
    WasteCategoryType? categoryType,
    int? quantityBags,
    double? latitude,
    double? longitude,
    String? address,
    String? notes,
    double? estimatedCashAmount,
    RequestStatus? status,
    String? assignedRiderId,
    String? assignedRiderName,
    DateTime? createdAt,
    DateTime? scheduledPickupTime,
    DateTime? collectedAt,
    bool? isCashCollected,
    double? actualCashPaid,
    String? receiptNumber,
  }) {
    return WasteRequest(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      userName: userName ?? this.userName,
      userPhone: userPhone ?? this.userPhone,
      photoPath: photoPath ?? this.photoPath,
      categoryType: categoryType ?? this.categoryType,
      quantityBags: quantityBags ?? this.quantityBags,
      latitude: latitude ?? this.latitude,
      longitude: longitude ?? this.longitude,
      address: address ?? this.address,
      notes: notes ?? this.notes,
      estimatedCashAmount: estimatedCashAmount ?? this.estimatedCashAmount,
      status: status ?? this.status,
      assignedRiderId: assignedRiderId ?? this.assignedRiderId,
      assignedRiderName: assignedRiderName ?? this.assignedRiderName,
      createdAt: createdAt ?? this.createdAt,
      scheduledPickupTime: scheduledPickupTime ?? this.scheduledPickupTime,
      collectedAt: collectedAt ?? this.collectedAt,
      isCashCollected: isCashCollected ?? this.isCashCollected,
      actualCashPaid: actualCashPaid ?? this.actualCashPaid,
      receiptNumber: receiptNumber ?? this.receiptNumber,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'userId': userId,
        'userName': userName,
        'userPhone': userPhone,
        'photoPath': photoPath,
        'categoryType': categoryType.name,
        'quantityBags': quantityBags,
        'latitude': latitude,
        'longitude': longitude,
        'address': address,
        'notes': notes,
        'estimatedCashAmount': estimatedCashAmount,
        'status': status.name,
        'assignedRiderId': assignedRiderId,
        'assignedRiderName': assignedRiderName,
        'createdAt': createdAt.toIso8601String(),
        'scheduledPickupTime': scheduledPickupTime.toIso8601String(),
        'collectedAt': collectedAt?.toIso8601String(),
        'isCashCollected': isCashCollected,
        'actualCashPaid': actualCashPaid,
        'receiptNumber': receiptNumber,
      };

  factory WasteRequest.fromJson(Map<String, dynamic> json) => WasteRequest(
        id: json['id'] as String,
        userId: json['userId'] as String,
        userName: json['userName'] as String,
        userPhone: json['userPhone'] as String,
        photoPath: json['photoPath'] as String? ?? '',
        categoryType: WasteCategoryType.values.byName(json['categoryType'] as String),
        quantityBags: json['quantityBags'] as int,
        latitude: (json['latitude'] as num).toDouble(),
        longitude: (json['longitude'] as num).toDouble(),
        address: json['address'] as String,
        notes: json['notes'] as String? ?? '',
        estimatedCashAmount: (json['estimatedCashAmount'] as num).toDouble(),
        status: RequestStatus.values.byName(json['status'] as String),
        assignedRiderId: json['assignedRiderId'] as String?,
        assignedRiderName: json['assignedRiderName'] as String?,
        createdAt: DateTime.parse(json['createdAt'] as String),
        scheduledPickupTime: DateTime.parse(json['scheduledPickupTime'] as String),
        collectedAt: json['collectedAt'] != null
            ? DateTime.parse(json['collectedAt'] as String)
            : null,
        isCashCollected: json['isCashCollected'] as bool? ?? false,
        actualCashPaid: (json['actualCashPaid'] as num?)?.toDouble(),
        receiptNumber: json['receiptNumber'] as String?,
      );
}
