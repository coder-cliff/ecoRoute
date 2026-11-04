enum RequestStatus {
  requested,
  collected,
  awaitingVerification,
  paid,
  cancelled,
}

extension RequestStatusLabel on RequestStatus {
  String get label => switch (this) {
    RequestStatus.requested => 'Requested',
    RequestStatus.collected => 'Collected',
    RequestStatus.awaitingVerification => 'Awaiting verification',
    RequestStatus.paid => 'Paid',
    RequestStatus.cancelled => 'Cancelled',
  };
}
