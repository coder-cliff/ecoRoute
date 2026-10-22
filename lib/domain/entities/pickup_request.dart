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
    this.zone = Zone.north,
    this.address = 'Arua Central',
    this.latitude,
    this.longitude,
    this.residentName = 'Resident',
    this.residentPhone = '+256 772 000 001',
    this.residentId = 'resident-1',
  });

  final String id;
  final WasteType wasteType;
  final String description;
  final DateTime submittedAt;
  final RequestStatus status;
  final int sackCount;
  final int priceUgx;
  final Zone zone;
  final String address;
  final double? latitude;
  final double? longitude;
  final String residentName;
  final String residentPhone;
  final String residentId;

  PickupRequest copyWith({
    String? id,
    WasteType? wasteType,
    String? description,
    DateTime? submittedAt,
    RequestStatus? status,
    int? sackCount,
    int? priceUgx,
    Zone? zone,
    String? address,
    double? latitude,
    double? longitude,
    String? residentName,
    String? residentPhone,
    String? residentId,
  }) {
    return PickupRequest(
      id: id ?? this.id,
      wasteType: wasteType ?? this.wasteType,
      description: description ?? this.description,
      submittedAt: submittedAt ?? this.submittedAt,
      status: status ?? this.status,
      sackCount: sackCount ?? this.sackCount,
      priceUgx: priceUgx ?? this.priceUgx,
      zone: zone ?? this.zone,
      address: address ?? this.address,
      latitude: latitude ?? this.latitude,
      longitude: longitude ?? this.longitude,
      residentName: residentName ?? this.residentName,
      residentPhone: residentPhone ?? this.residentPhone,
      residentId: residentId ?? this.residentId,
    );
  }
}
