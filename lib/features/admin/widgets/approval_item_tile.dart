import 'package:flutter/material.dart';

import '../../../domain/entities/pickup_request.dart';
import '../../../domain/enums/waste_type.dart';

class ApprovalItemTile extends StatelessWidget {
  const ApprovalItemTile({
    required this.request,
    required this.onApprove,
    required this.onReturn,
    super.key,
  });

  final PickupRequest request;
  final VoidCallback onApprove;
  final VoidCallback onReturn;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          request.wasteType.label,
          style: const TextStyle(fontWeight: FontWeight.w800),
        ),
        const SizedBox(height: 4),
        Text(
          request.description,
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
          style: const TextStyle(color: Color(0xFF71877D), fontSize: 12),
        ),
        const SizedBox(height: 10),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            FilledButton.icon(
              onPressed: onApprove,
              icon: const Icon(Icons.verified_outlined, size: 17),
              label: const Text('Approve payment'),
            ),
            OutlinedButton.icon(
              onPressed: onReturn,
              icon: const Icon(Icons.undo_rounded, size: 17),
              label: const Text('Return to rider'),
            ),
          ],
        ),
      ],
    );
  }
}
