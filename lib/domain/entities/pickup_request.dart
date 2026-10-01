import '../enums/request_status.dart';
import '../enums/waste_type.dart';

class PickupRequest {
  const PickupRequest({
    required this.id,
    required this.wasteType,
    required this.description,
    required this.submittedAt,
    this.status = RequestStatus.requested,
  });

  final String id;
  final WasteType wasteType;
  final String description;
  final DateTime submittedAt;
  final RequestStatus status;

  PickupRequest copyWith({
    String? id,
    WasteType? wasteType,
    String? description,
    DateTime? submittedAt,
    RequestStatus? status,
  }) {
    return PickupRequest(
      id: id ?? this.id,
      wasteType: wasteType ?? this.wasteType,
      description: description ?? this.description,
      submittedAt: submittedAt ?? this.submittedAt,
      status: status ?? this.status,
    );
  }
}
