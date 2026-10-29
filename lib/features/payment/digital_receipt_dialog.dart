import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../core/utils/formatters.dart';
import '../../domain/entities/pickup_request.dart';
import '../../domain/enums/waste_type.dart';

class DigitalReceiptDialog extends StatelessWidget {
  const DigitalReceiptDialog({
    required this.request,
    this.onClose,
    super.key,
  });

  final PickupRequest request;
  final VoidCallback? onClose;

  static const String collectionAccount = '+256 394 880 352';

  String get _receiptNumber {
    if (request.receiptNumber != null && request.receiptNumber!.isNotEmpty) {
      return request.receiptNumber!;
    }
    final rawSuffix = request.id.replaceAll(RegExp(r'[^a-zA-Z0-9]'), '').toUpperCase();
    final suffix = rawSuffix.length >= 6
        ? rawSuffix.substring(rawSuffix.length - 6)
        : rawSuffix.padLeft(6, '0');
    return 'REC-${DateTime.now().year}-ARU-$suffix';
  }

  String _generateReceiptText() {
    final paidTime = formatDateTime(request.paidAt ?? DateTime.now());
    final methodLabel = request.paymentMethod == 'cash'
        ? (request.cashReceivedByRider ? 'Hard Cash (Received by Rider)' : 'Hard Cash (Pay at Gate)')
        : 'Direct Mobile Money (To $collectionAccount)';

    return '''
========================================
       ECOROUTE LOGISTICS ARUA
     Digital Collection Receipt
========================================
Receipt No: $_receiptNumber
Date & Time: $paidTime
Collection Account: $collectionAccount

Resident: ${request.residentName}
Contact: ${request.residentPhone}
Pickup Address: ${request.address}

Service: On-Demand Tricycle Collection
Waste Category: ${request.wasteType.label}
Volume: ${request.sackCount} sack(s)
Total Amount: ${formatUgx(request.priceUgx)}

Payment Method: $methodLabel
Status: ${request.cashReceivedByRider || request.paymentMethod == 'momo' ? 'VERIFIED & SETTLED' : 'CASH CONFIRMED BY RESIDENT'}
========================================
EcoRoute Private Commercial Waste Hub
Muni • Ayivu • Central Division • Arua
========================================
''';
  }

  void _copyReceiptToClipboard(BuildContext context) {
    Clipboard.setData(ClipboardData(text: _generateReceiptText()));
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Receipt details copied to clipboard. Ready to paste or share.'),
        backgroundColor: Color(0xFF2E7D32),
        duration: Duration(seconds: 3),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    final receiptBg = isDark ? const Color(0xFF142417) : const Color(0xFFF9FCF9);
    final cardBorder = isDark ? const Color(0xFF2A3F2F) : const Color(0xFFD6E3D8);
    final subtextColor = isDark ? const Color(0xFF9EABA1) : const Color(0xFF556958);

    final isPaid = request.cashReceivedByRider || request.paymentMethod == 'momo';
    final isCashPending = request.paymentMethod == 'cash' && !request.cashReceivedByRider;

    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
      clipBehavior: Clip.antiAlias,
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 460),
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(22),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Top EcoRoute Header
              Row(
                children: [
                  Container(
                    width: 44,
                    height: 44,
                    decoration: BoxDecoration(
                      color: const Color(0xFFE8F5E9),
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: const Icon(Icons.receipt_long_rounded, color: Color(0xFF2E7D32), size: 24),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'EcoRoute Logistics',
                          style: TextStyle(fontSize: 17, fontWeight: FontWeight.w900),
                        ),
                        Text(
                          'Commercial Waste Receipt • Arua Hub',
                          style: TextStyle(fontSize: 11, color: subtextColor),
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    onPressed: () {
                      Navigator.of(context).pop();
                      onClose?.call();
                    },
                    icon: const Icon(Icons.close_rounded, size: 20),
                    tooltip: 'Close receipt',
                  ),
                ],
              ),
              const SizedBox(height: 16),

              // Printable Receipt Paper Box
              Container(
                padding: const EdgeInsets.all(18),
                decoration: BoxDecoration(
                  color: receiptBg,
                  borderRadius: BorderRadius.circular(18),
                  border: Border.all(color: cardBorder, width: 1.5),
                ),
                child: Column(
                  children: [
                    // Receipt Number & Time
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'RECEIPT NUMBER',
                                style: TextStyle(
                                  fontSize: 9.5,
                                  fontWeight: FontWeight.w800,
                                  letterSpacing: 0.8,
                                  color: subtextColor,
                                ),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                _receiptNumber,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: const TextStyle(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w900,
                                  color: Color(0xFF1B5E20),
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.end,
                            children: [
                              Text(
                                'DATE & TIME',
                                style: TextStyle(
                                  fontSize: 9.5,
                                  fontWeight: FontWeight.w800,
                                  letterSpacing: 0.8,
                                  color: subtextColor,
                                ),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                formatDateTime(request.paidAt ?? DateTime.now()),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: TextStyle(
                                  fontSize: 11,
                                  fontWeight: FontWeight.w700,
                                  color: subtextColor,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Divider(height: 1, color: cardBorder),
                    const SizedBox(height: 12),

                    // Resident & Location
                    _receiptRow('Resident Name', request.residentName),
                    const SizedBox(height: 6),
                    _receiptRow('Phone Number', request.residentPhone),
                    const SizedBox(height: 6),
                    _receiptRow('Pickup Landmark', request.address),
                    const SizedBox(height: 6),
                    _receiptRow('EcoRoute Account', collectionAccount),
                    const SizedBox(height: 12),
                    Divider(height: 1, color: cardBorder),
                    const SizedBox(height: 12),

                    // Service & Waste Breakdown
                    _receiptRow('Service Class', 'On-Demand Tricycle Collection'),
                    const SizedBox(height: 6),
                    _receiptRow('Waste Category', request.wasteType.label),
                    const SizedBox(height: 6),
                    _receiptRow('Volume Cleared', '${request.sackCount} sack(s)'),
                    const SizedBox(height: 6),
                    _receiptRow(
                      'Payment Channel',
                      request.paymentMethod == 'cash'
                          ? (request.cashReceivedByRider
                              ? 'Hard Cash (Collected by Rider)'
                              : 'Hard Cash (To Pay at Gate)')
                          : 'Direct Mobile Money',
                    ),
                    const SizedBox(height: 12),
                    Divider(height: 1, color: cardBorder),
                    const SizedBox(height: 12),

                    // Total Paid
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Expanded(
                          child: Text(
                            'TOTAL AMOUNT PAID',
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w900,
                              letterSpacing: 0.5,
                            ),
                          ),
                        ),
                        Text(
                          formatUgx(request.priceUgx),
                          style: const TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.w900,
                            color: Color(0xFF1B5E20),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 14),

                    // Verification Stamp
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                      decoration: BoxDecoration(
                        color: isPaid
                            ? const Color(0xFFE8F5E9)
                            : (isCashPending ? const Color(0xFFFFF3E0) : const Color(0xFFE8F5E9)),
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(
                          color: isPaid
                              ? const Color(0xFF81C784)
                              : (isCashPending ? const Color(0xFFFFB74D) : const Color(0xFF81C784)),
                        ),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            isPaid ? Icons.verified_rounded : Icons.pending_rounded,
                            size: 16,
                            color: isPaid
                                ? const Color(0xFF2E7D32)
                                : (isCashPending ? const Color(0xFFE65100) : const Color(0xFF2E7D32)),
                          ),
                          const SizedBox(width: 8),
                          Flexible(
                            child: Text(
                              isPaid
                                  ? 'VERIFIED PAYMENT • ECOROUTE PRIVATE LTD'
                                  : 'CASH COMMITMENT ACCEPTED • PAY RIDER AT GATE',
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                fontSize: 10,
                                fontWeight: FontWeight.w900,
                                letterSpacing: 0.6,
                                color: isPaid
                                    ? const Color(0xFF1B5E20)
                                    : (isCashPending ? const Color(0xFFBF360C) : const Color(0xFF1B5E20)),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 18),

              // Action Buttons
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: () => _copyReceiptToClipboard(context),
                      icon: const Icon(Icons.copy_rounded, size: 16),
                      label: const Text('Copy Receipt'),
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: FilledButton(
                      style: FilledButton.styleFrom(
                        backgroundColor: const Color(0xFF2E7D32),
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                      onPressed: () {
                        Navigator.of(context).pop();
                        onClose?.call();
                      },
                      child: const Text('Done'),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _receiptRow(String label, String value) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: const TextStyle(fontSize: 11, color: Color(0xFF647568)),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Text(
            value,
            textAlign: TextAlign.end,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(fontSize: 11.5, fontWeight: FontWeight.w700),
          ),
        ),
      ],
    );
  }
}
