import 'package:flutter/material.dart';
import '../models/waste_request.dart';

class StatusBadge extends StatelessWidget {
  final RequestStatus status;

  const StatusBadge({super.key, required this.status});

  @override
  Widget build(BuildContext context) {
    Color bg;
    Color fg;
    IconData icon;

    switch (status) {
      case RequestStatus.pending:
        bg = const Color(0xFFFFF3CD);
        fg = const Color(0xFF856404);
        icon = Icons.hourglass_top_rounded;
        break;
      case RequestStatus.assigned:
        bg = const Color(0xFFCCE5FF);
        fg = const Color(0xFF004085);
        icon = Icons.two_wheeler_rounded;
        break;
      case RequestStatus.collected:
        bg = const Color(0xFFD4EDDA);
        fg = const Color(0xFF155724);
        icon = Icons.check_circle_rounded;
        break;
      case RequestStatus.cancelled:
        bg = const Color(0xFFF8D7DA);
        fg = const Color(0xFF721C24);
        icon = Icons.cancel_outlined;
        break;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: fg.withValues(alpha: 0.3)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: fg),
          const SizedBox(width: 5),
          Text(
            status.displayName,
            style: TextStyle(
              color: fg,
              fontSize: 12,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}
