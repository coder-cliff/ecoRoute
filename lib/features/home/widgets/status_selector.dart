import 'package:flutter/material.dart';

import '../../../domain/enums/request_status.dart';
import '../../../domain/rules/status_machine.dart';

class StatusSelector extends StatelessWidget {
  const StatusSelector({
    required this.currentStatus,
    required this.onChanged,
    super.key,
  });

  final RequestStatus currentStatus;
  final ValueChanged<RequestStatus?> onChanged;

  @override
  Widget build(BuildContext context) {
    final statuses = <RequestStatus>{
      currentStatus,
      ...RequestStatus.values.where(
        (status) => isValidTransition(currentStatus, status),
      ),
    }.toList();

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8),
      decoration: BoxDecoration(
        color: const Color(0xFFF1F7F2),
        borderRadius: BorderRadius.circular(999),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<RequestStatus>(
          value: currentStatus,
          isDense: true,
          items: statuses
              .map(
                (status) =>
                    DropdownMenuItem(value: status, child: Text(status.label)),
              )
              .toList(),
          onChanged: onChanged,
        ),
      ),
    );
  }
}
