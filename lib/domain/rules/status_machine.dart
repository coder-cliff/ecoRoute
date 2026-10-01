import '../enums/request_status.dart';

bool isValidTransition(RequestStatus from, RequestStatus to) {
  final validTransitions = <RequestStatus, Set<RequestStatus>>{
    RequestStatus.requested: {RequestStatus.collected, RequestStatus.cancelled},
    RequestStatus.collected: {RequestStatus.awaitingVerification},
    RequestStatus.awaitingVerification: {
      RequestStatus.paid,
      RequestStatus.collected,
    },
    RequestStatus.paid: const <RequestStatus>{},
    RequestStatus.cancelled: const <RequestStatus>{},
  };

  return validTransitions[from]?.contains(to) ?? false;
}
