import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../models/waste_category.dart';
import '../models/waste_request.dart';
import '../theme/app_theme.dart';
import 'status_badge.dart';

class WasteCard extends StatelessWidget {
  final WasteRequest request;
  final VoidCallback onTap;

  const WasteCard({
    super.key,
    required this.request,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final category = request.category;
    final timeStr = DateFormat('EEE, MMM d • h:mm a').format(request.scheduledPickupTime);

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Card(
        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header: Category Icon + ID + Status Badge
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: category.color.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Icon(category.icon, color: category.color, size: 22),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          category.title,
                          style: const TextStyle(
                            fontWeight: FontWeight.w700,
                            fontSize: 16,
                            color: AppTheme.textDark,
                          ),
                        ),
                        Text(
                          'ID: ${request.id}',
                          style: const TextStyle(
                            fontSize: 12,
                            color: AppTheme.textMuted,
                          ),
                        ),
                      ],
                    ),
                  ),
                  StatusBadge(status: request.status),
                ],
              ),
              const SizedBox(height: 12),
              const Divider(height: 1, color: Color(0xFFEEEEEE)),
              const SizedBox(height: 12),

              // Address & Location
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Icon(Icons.location_on_rounded, size: 16, color: Colors.redAccent),
                  const SizedBox(width: 6),
                  Expanded(
                    child: Text(
                      request.address,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontSize: 13,
                        color: AppTheme.textDark,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),

              // Time, Volume & Bags
              Row(
                children: [
                  const Icon(Icons.access_time_rounded, size: 16, color: AppTheme.textMuted),
                  const SizedBox(width: 6),
                  Text(
                    timeStr,
                    style: const TextStyle(
                      fontSize: 12,
                      color: AppTheme.textMuted,
                    ),
                  ),
                  const Spacer(),
                  Container(
                    margin: const EdgeInsets.only(right: 6),
                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                    decoration: BoxDecoration(
                      color: AppTheme.accentMint,
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Text(
                      request.volumeSize.label.split(' ').first,
                      style: const TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                        color: AppTheme.primaryGreen,
                      ),
                    ),
                  ),
                  Text(
                    '${request.quantityBags} ${request.quantityBags == 1 ? 'bag' : 'bags'}',
                    style: const TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: AppTheme.primaryGreen,
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 12),
              // Cash Price Tag & Rider status
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                decoration: BoxDecoration(
                  color: request.isCashCollected ? AppTheme.accentMint : AppTheme.cashGoldLight,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Row(
                  children: [
                    Icon(
                      request.isCashCollected ? Icons.check_circle : Icons.payments_outlined,
                      size: 16,
                      color: request.isCashCollected ? AppTheme.primaryGreen : AppTheme.cashGold,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      request.isCashCollected
                          ? 'Cash Paid: \$${(request.actualCashPaid ?? request.estimatedCashAmount).toStringAsFixed(2)}'
                          : 'Due in Cash: \$${request.estimatedCashAmount.toStringAsFixed(2)}',
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                        color: request.isCashCollected ? AppTheme.darkForest : const Color(0xFF664D03),
                      ),
                    ),
                    const Spacer(),
                    if (request.assignedRiderName != null) ...[
                      const Icon(Icons.two_wheeler, size: 14, color: AppTheme.textMuted),
                      const SizedBox(width: 4),
                      Text(
                        request.assignedRiderName!,
                        style: const TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w500,
                          color: AppTheme.textMuted,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
