import 'package:flutter/material.dart';
import '../theme/app_theme.dart';

class CashPaymentBanner extends StatelessWidget {
  final double amount;
  final bool isCollected;

  const CashPaymentBanner({
    super.key,
    required this.amount,
    this.isCollected = false,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: isCollected ? AppTheme.accentMint : AppTheme.cashGoldLight,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isCollected ? AppTheme.primaryGreen : AppTheme.cashGold,
          width: 1.2,
        ),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: isCollected ? AppTheme.primaryGreen : AppTheme.cashGold,
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.payments_rounded,
              color: Colors.white,
              size: 20,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  isCollected
                      ? 'Hard Cash Collected: \$${amount.toStringAsFixed(2)}'
                      : 'Pay With Hard Cash: \$${amount.toStringAsFixed(2)}',
                  style: TextStyle(
                    fontWeight: FontWeight.w700,
                    fontSize: 14,
                    color: isCollected ? AppTheme.darkForest : const Color(0xFF664D03),
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  isCollected
                      ? 'Payment verified & settled upon pickup by collector.'
                      : 'Please have exact cash ready for the rider upon waste collection.',
                  style: TextStyle(
                    fontSize: 12,
                    color: isCollected
                        ? AppTheme.darkForest.withValues(alpha: 0.8)
                        : const Color(0xFF856404),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
