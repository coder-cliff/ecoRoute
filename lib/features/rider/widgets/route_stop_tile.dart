import 'package:flutter/material.dart';

import '../../../domain/entities/pickup_request.dart';
import '../../../domain/enums/request_status.dart';
import '../../../domain/enums/waste_type.dart';

class RouteStopTile extends StatelessWidget {
  const RouteStopTile({
    required this.index,
    required this.request,
    required this.onAdvance,
    super.key,
  });

  final int index;
  final PickupRequest request;
  final VoidCallback onAdvance;

  @override
  Widget build(BuildContext context) {
    final isRequested = request.status == RequestStatus.requested;
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: 32,
          height: 32,
          alignment: Alignment.center,
          decoration: const BoxDecoration(
            color: Color(0xFFEAF4EC),
            shape: BoxShape.circle,
          ),
          child: Text(
            '$index',
            style: const TextStyle(
              color: Color(0xFF2E7D4F),
              fontWeight: FontWeight.w800,
            ),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                request.wasteType.label,
                style: const TextStyle(fontWeight: FontWeight.w800),
              ),
              const SizedBox(height: 3),
              Text(
                request.description,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(color: Color(0xFF71877D), fontSize: 12),
              ),
              if (request.photoUrl != null) ...[
                const SizedBox(height: 4),
                Row(
                  children: [
                    const Icon(Icons.photo_camera_back_outlined, size: 14, color: Color(0xFF2E7D4F)),
                    const SizedBox(width: 4),
                    Text(
                      'Photo: ${request.photoUrl!.split(RegExp(r"[/\\]")).last}',
                      style: const TextStyle(
                        color: Color(0xFF2E7D4F),
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ],
              const SizedBox(height: 8),
              Align(
                alignment: Alignment.centerLeft,
                child: OutlinedButton.icon(
                  onPressed: onAdvance,
                  icon: Icon(
                    isRequested
                        ? Icons.check_circle_outline_rounded
                        : Icons.fact_check_outlined,
                    size: 17,
                  ),
                  label: Text(
                    isRequested ? 'Mark collected' : 'Send for verification',
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
