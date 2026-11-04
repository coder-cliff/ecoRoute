import 'package:flutter/material.dart';

import '../../../domain/enums/request_status.dart';

class AnalyticsRow extends StatelessWidget {
  const AnalyticsRow({
    required this.status,
    required this.count,
    required this.total,
    super.key,
  });

  final RequestStatus status;
  final int count;
  final int total;

  @override
  Widget build(BuildContext context) {
    final proportion = total == 0 ? 0.0 : (count / total);
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        children: [
          SizedBox(
            width: 114,
            child: Text(
              status.label,
              style: const TextStyle(fontSize: 12, color: Color(0xFF647568)),
            ),
          ),
          Expanded(
            child: ClipRRect(
              borderRadius: BorderRadius.circular(99),
              child: SizedBox(
                height: 8,
                child: Stack(
                  children: [
                    const ColoredBox(
                      color: Color(0xFFEAF0E9),
                      child: SizedBox.expand(),
                    ),
                    FractionallySizedBox(
                      alignment: Alignment.centerLeft,
                      widthFactor: proportion,
                      heightFactor: 1.0,
                      child: const ColoredBox(color: Color(0xFF2E8B57)),
                    ),
                  ],
                ),
              ),
            ),
          ),
          const SizedBox(width: 10),
          SizedBox(
            width: 22,
            child: Text(
              '$count',
              textAlign: TextAlign.end,
              style: const TextStyle(fontWeight: FontWeight.w800),
            ),
          ),
        ],
      ),
    );
  }
}
