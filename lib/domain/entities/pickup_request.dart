import '../enums/request_status.dart';
import '../enums/waste_type.dart';
import '../enums/zone.dart';

class PickupRequest {
  const PickupRequest({
    required this.id,
    required this.wasteType,
    required this.description,
    required this.submittedAt,
    this.status = RequestStatus.requested,
    this.sackCount = 1,
    this.priceUgx = 1500,
    this.isInstant = true,
    this.zone = Zone.north,
    this.address = 'Arua Central',
    this.latitude,
    this.longitude,
    this.residentName = 'Resident',
    this.residentPhone = '+256 772 000 001',
    this.residentId = 'resident-1',
    this.photoUrl,
    this.isSynced = true,
    this.paymentMethod = 'unpaid',
    this.cashReceivedByRider = false,
    this.receiptNumber,
    this.paidAt,
    this.isCommercial = false,
    this.businessName,
    this.tinNumber,
    this.serviceTier,
  });

  final String id;
  final WasteType wasteType;
  final String description;
  final DateTime submittedAt;
  final RequestStatus status;
  final int sackCount;
  final int priceUgx;
  final bool isInstant;
  final Zone zone;
  final String address;
  final double? latitude;
  final double? longitude;
  final String residentName;
  final String residentPhone;
  final String residentId;
  final String? photoUrl;
  final bool isSynced;
  final String paymentMethod; // 'unpaid', 'cash', 'momo'
  final bool cashReceivedByRider;
  final String? receiptNumber;
  final DateTime? paidAt;
  final bool isCommercial;
  final String? businessName;
  final String? tinNumber;
  final String? serviceTier;

  bool get isPaidInCash => paymentMethod == 'cash' && cashReceivedByRider;
  bool get isPaidInMoMo => paymentMethod == 'momo';
  bool get isCashPending => paymentMethod == 'cash' && !cashReceivedByRider;

  PickupRequest copyWith({
    String? id,
    WasteType? wasteType,
    String? description,
    DateTime? submittedAt,
    RequestStatus? status,
    int? sackCount,
    int? priceUgx,
    bool? isInstant,
    Zone? zone,
    String? address,
    double? latitude,
    double? longitude,
    String? residentName,
    String? residentPhone,
    String? residentId,
    String? photoUrl,
    bool? isSynced,
    String? paymentMethod,
    bool? cashReceivedByRider,
    String? receiptNumber,
    DateTime? paidAt,
    bool? isCommercial,
    String? businessName,
    String? tinNumber,
    String? serviceTier,
  }) {
    return PickupRequest(
      id: id ?? this.id,
      wasteType: wasteType ?? this.wasteType,
      description: description ?? this.description,
      submittedAt: submittedAt ?? this.submittedAt,
      status: status ?? this.status,
      sackCount: sackCount ?? this.sackCount,
      priceUgx: priceUgx ?? this.priceUgx,
      isInstant: isInstant ?? this.isInstant,
      zone: zone ?? this.zone,
      address: address ?? this.address,
      latitude: latitude ?? this.latitude,
      longitude: longitude ?? this.longitude,
      residentName: residentName ?? this.residentName,
      residentPhone: residentPhone ?? this.residentPhone,
      residentId: residentId ?? this.residentId,
      photoUrl: photoUrl ?? this.photoUrl,
      isSynced: isSynced ?? this.isSynced,
      paymentMethod: paymentMethod ?? this.paymentMethod,
      cashReceivedByRider: cashReceivedByRider ?? this.cashReceivedByRider,
      receiptNumber: receiptNumber ?? this.receiptNumber,
      paidAt: paidAt ?? this.paidAt,
      isCommercial: isCommercial ?? this.isCommercial,
      businessName: businessName ?? this.businessName,
      tinNumber: tinNumber ?? this.tinNumber,
      serviceTier: serviceTier ?? this.serviceTier,
    );
  }
}
