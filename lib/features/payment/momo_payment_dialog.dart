import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../core/utils/formatters.dart';
import '../../domain/entities/pickup_request.dart';
import '../../domain/enums/request_status.dart';
import '../../domain/enums/waste_type.dart';

enum MoMoProvider {
  mtn('MTN MoMo', Color(0xFFFFCC00), Colors.black, Icons.phone_android_rounded),
  airtel('Airtel Money', Color(0xFFE50914), Colors.white, Icons.account_balance_wallet_rounded);

  const MoMoProvider(this.label, this.color, this.textColor, this.icon);
  final String label;
  final Color color;
  final Color textColor;
  final IconData icon;
}

class MoMoPaymentDialog extends StatefulWidget {
  const MoMoPaymentDialog({
    required this.request,
    required this.onPaymentSuccess,
    this.initialPhone = '',
    super.key,
  });

  final PickupRequest request;
  final String initialPhone;
  final Future<void> Function(PickupRequest updatedRequest) onPaymentSuccess;

  static const String collectionAccount = '+256 394 880 352';

  @override
  State<MoMoPaymentDialog> createState() => _MoMoPaymentDialogState();
}

class _MoMoPaymentDialogState extends State<MoMoPaymentDialog> {
  MoMoProvider _provider = MoMoProvider.mtn;
  late final TextEditingController _phoneController;

  bool _isCashMode = false;
  int _step = 0; // 0: Enter Details, 1: USSD Push Waiting, 2: Receipt, 3: Failed
  String? _transactionId;
  DateTime? _paidAt;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    final defaultPhone = widget.initialPhone.isNotEmpty
        ? widget.initialPhone
        : widget.request.residentPhone;
    _phoneController = TextEditingController(text: defaultPhone);
  }

  @override
  void dispose() {
    _phoneController.dispose();
    super.dispose();
  }

  Future<void> _simulatePayment() async {
    final phone = _phoneController.text.trim();
    if (phone.isEmpty || phone.length < 9) {
      setState(() {
        _errorMessage = 'Please enter a valid mobile number (min 9 digits) to receive the USSD prompt.';
        _step = 3;
      });
      return;
    }

    setState(() => _step = 1);

    // Simulate network USSD push delay
    await Future<void>.delayed(const Duration(milliseconds: 1600));

    final txId = 'DEMO-TX-${_provider == MoMoProvider.mtn ? 'MTN' : 'AIR'}-${DateTime.now().millisecondsSinceEpoch.toString().substring(5)}';
    final now = DateTime.now();

    final updated = widget.request.copyWith(
      status: RequestStatus.paid,
      residentPhone: phone,
      paymentMethod: 'momo',
      receiptNumber: txId,
      paidAt: now,
    );

    try {
      await widget.onPaymentSuccess(updated);
      if (!mounted) return;
      setState(() {
        _transactionId = txId;
        _paidAt = now;
        _step = 2; // Show receipt
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _errorMessage = 'Payment confirmation could not be verified: $e';
        _step = 3;
      });
    }
  }

  Future<void> _confirmCashPayment() async {
    final phone = _phoneController.text.trim();
    final txId = 'REC-${DateTime.now().year}-ARU-${DateTime.now().millisecondsSinceEpoch.toString().substring(7)}';
    final now = DateTime.now();

    final updated = widget.request.copyWith(
      paymentMethod: 'cash',
      cashReceivedByRider: false,
      receiptNumber: txId,
      paidAt: now,
      residentPhone: phone.isNotEmpty ? phone : widget.request.residentPhone,
    );

    try {
      await widget.onPaymentSuccess(updated);
      if (!mounted) return;
      setState(() {
        _transactionId = txId;
        _paidAt = now;
        _step = 2; // Show receipt
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _errorMessage = 'Cash payment commitment could not be recorded: $e';
        _step = 3;
      });
    }
  }

  void _copyReceiptToClipboard() {
    final text = '''
========================================
       ECOROUTE LOGISTICS ARUA
     Digital Collection Receipt
========================================
Receipt No: ${_transactionId ?? 'REC-ARU'}
Date & Time: ${formatDateTime(_paidAt ?? DateTime.now())}
Collection Account: ${MoMoPaymentDialog.collectionAccount}

Resident Phone: ${_phoneController.text}
Pickup Address: ${widget.request.address}
Service Class: On-Demand Tricycle Collection
Waste Category: ${widget.request.wasteType.label}
Volume: ${widget.request.sackCount} sack(s)
Amount: ${formatUgx(widget.request.priceUgx)}

Method: ${_isCashMode ? 'Hard Cash to Rider' : _provider.label}
Status: ${_isCashMode ? 'CASH COMMITMENT ACCEPTED' : 'VERIFIED PAID'}
========================================
''';
    Clipboard.setData(ClipboardData(text: text));
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Receipt summary copied to clipboard.'),
        backgroundColor: Color(0xFF2E7D32),
        duration: Duration(seconds: 2),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
      clipBehavior: Clip.antiAlias,
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 440),
        child: SingleChildScrollView(
          child: switch (_step) {
            0 => _buildInputStep(),
            1 => _buildProcessingStep(),
            2 => _buildReceiptStep(),
            _ => _buildFailedStep(),
          },
        ),
      ),
    );
  }

  Widget _buildInputStep() {
    return Padding(
      padding: const EdgeInsets.all(22),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: const Color(0xFFE8F5E9),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: const Icon(Icons.payments_rounded, color: Color(0xFF2E7D32)),
              ),
              const SizedBox(width: 12),
              const Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Mobile Money Payment',
                      style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800),
                    ),
                    Text(
                      'EcoRoute Commercial Settlement Hub • Arua',
                      style: TextStyle(fontSize: 11, color: Color(0xFF647568)),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),

          // Payment Channel Selector: Mobile Money vs Hard Cash to Rider
          Container(
            padding: const EdgeInsets.all(4),
            decoration: BoxDecoration(
              color: const Color(0xFFF1F5F2),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: const Color(0xFFD6E2D8)),
            ),
            child: Row(
              children: [
                Expanded(
                  child: InkWell(
                    onTap: () => setState(() => _isCashMode = false),
                    borderRadius: BorderRadius.circular(9),
                    child: Container(
                      padding: const EdgeInsets.symmetric(vertical: 8),
                      decoration: BoxDecoration(
                        color: !_isCashMode ? Colors.white : Colors.transparent,
                        borderRadius: BorderRadius.circular(9),
                        boxShadow: !_isCashMode
                            ? const [
                                BoxShadow(
                                  color: Color(0x12000000),
                                  blurRadius: 4,
                                  offset: Offset(0, 2),
                                )
                              ]
                            : null,
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.phone_android_rounded,
                            size: 16,
                            color: !_isCashMode ? const Color(0xFF2E7D32) : const Color(0xFF647568),
                          ),
                          const SizedBox(width: 6),
                          Flexible(
                            child: Text(
                              'Mobile Money',
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w800,
                                color: !_isCashMode ? const Color(0xFF1B5E20) : const Color(0xFF647568),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
                Expanded(
                  child: InkWell(
                    onTap: () => setState(() => _isCashMode = true),
                    borderRadius: BorderRadius.circular(9),
                    child: Container(
                      padding: const EdgeInsets.symmetric(vertical: 8),
                      decoration: BoxDecoration(
                        color: _isCashMode ? Colors.white : Colors.transparent,
                        borderRadius: BorderRadius.circular(9),
                        boxShadow: _isCashMode
                            ? const [
                                BoxShadow(
                                  color: Color(0x12000000),
                                  blurRadius: 4,
                                  offset: Offset(0, 2),
                                )
                              ]
                            : null,
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.payments_outlined,
                            size: 16,
                            color: _isCashMode ? const Color(0xFF2E7D32) : const Color(0xFF647568),
                          ),
                          const SizedBox(width: 6),
                          Flexible(
                            child: Text(
                              'Hard Cash to Rider',
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w800,
                                color: _isCashMode ? const Color(0xFF1B5E20) : const Color(0xFF647568),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),

          // Total Amount Banner
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: const Color(0xFFE8F5E9),
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: const Color(0xFFC8E6C9)),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('Amount Due', style: TextStyle(fontSize: 11, color: Color(0xFF2E7D32))),
                      Text(
                        '${widget.request.sackCount} sack(s) • ${widget.request.wasteType.label}',
                        style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                Text(
                  formatUgx(widget.request.priceUgx),
                  style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.w900,
                    color: Color(0xFF1B5E20),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),

          if (!_isCashMode) ...[
            // Free Collection Account Banner
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              margin: const EdgeInsets.only(bottom: 14),
              decoration: BoxDecoration(
                color: const Color(0xFFF1F8F3),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: const Color(0xFFD4E8D7)),
              ),
              child: Row(
                children: [
                  const Icon(Icons.verified_outlined, size: 16, color: Color(0xFF2E7D32)),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Free Collection Account: ${MoMoPaymentDialog.collectionAccount}',
                      style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: Color(0xFF1B5E20)),
                    ),
                  ),
                ],
              ),
            ),

            // Provider selector
            Row(
              children: MoMoProvider.values.map((p) {
                final isSelected = _provider == p;
                return Expanded(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 4),
                    child: InkWell(
                      onTap: () => setState(() => _provider = p),
                      borderRadius: BorderRadius.circular(14),
                      child: Container(
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        decoration: BoxDecoration(
                          color: isSelected ? p.color : const Color(0xFFF2F4F2),
                          borderRadius: BorderRadius.circular(14),
                          border: Border.all(
                            color: isSelected ? Colors.black26 : const Color(0xFFDCE2DC),
                            width: isSelected ? 2 : 1,
                          ),
                        ),
                        child: Column(
                          children: [
                            Icon(p.icon, color: isSelected ? p.textColor : Colors.black87),
                            const SizedBox(height: 4),
                            Text(
                              p.label,
                              style: TextStyle(
                                fontWeight: FontWeight.w800,
                                color: isSelected ? p.textColor : Colors.black87,
                                fontSize: 12,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                );
              }).toList(),
            ),
            const SizedBox(height: 16),

            // Payer Mobile Phone
            TextField(
              controller: _phoneController,
              keyboardType: TextInputType.phone,
              decoration: const InputDecoration(
                labelText: 'Mobile Money Number',
                prefixIcon: Icon(Icons.phone_iphone_rounded),
              ),
            ),
            const SizedBox(height: 20),

            SizedBox(
              width: double.infinity,
              height: 48,
              child: FilledButton.icon(
                style: FilledButton.styleFrom(
                  backgroundColor: const Color(0xFF2E7D32),
                ),
                onPressed: _simulatePayment,
                icon: const Icon(Icons.lock_outline_rounded, size: 18),
                label: Text('Pay ${formatUgx(widget.request.priceUgx)}'),
              ),
            ),
          ] else ...[
            // Hard Cash to Rider Section
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: const Color(0xFFFFF9E6),
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: const Color(0xFFFFE082)),
              ),
              child: const Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(Icons.handshake_outlined, color: Color(0xFFB78103), size: 18),
                      SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          'Cash Payment at Gate Handover',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(fontWeight: FontWeight.w800, fontSize: 12.5, color: Color(0xFF6D4C00)),
                        ),
                      ),
                    ],
                  ),
                  SizedBox(height: 6),
                  Text(
                    'Hand physical cash directly to the tricycle rider when they arrive at your gate. You will receive an official digital receipt, and the rider will confirm the cash collection in their app console.',
                    style: TextStyle(fontSize: 11, color: Color(0xFF5D4037)),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),

            // Payer phone for receipt SMS confirmation
            TextField(
              controller: _phoneController,
              keyboardType: TextInputType.phone,
              decoration: const InputDecoration(
                labelText: 'Resident Phone for Digital Receipt',
                prefixIcon: Icon(Icons.phone_android_rounded),
              ),
            ),
            const SizedBox(height: 20),

            SizedBox(
              width: double.infinity,
              height: 48,
              child: FilledButton.icon(
                style: FilledButton.styleFrom(
                  backgroundColor: const Color(0xFF1B5E3B),
                ),
                onPressed: _confirmCashPayment,
                icon: const Icon(Icons.check_circle_outline_rounded, size: 18),
                label: Text('Accept & Pay ${formatUgx(widget.request.priceUgx)} Cash at Gate'),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildProcessingStep() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 36),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const SizedBox(
            width: 52,
            height: 52,
            child: CircularProgressIndicator(strokeWidth: 3.5, color: Color(0xFF2E7D32)),
          ),
          const SizedBox(height: 20),
          const Text(
            'Sending USSD Prompt...',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800),
          ),
          const SizedBox(height: 8),
          Text(
            'A prompt has been sent to ${_phoneController.text}.\nPlease confirm the prompt on your phone.',
            textAlign: TextAlign.center,
            style: const TextStyle(fontSize: 13, color: Color(0xFF556958)),
          ),
        ],
      ),
    );
  }

  Widget _buildReceiptStep() {
    return Padding(
      padding: const EdgeInsets.all(22),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.check_circle_rounded, color: Color(0xFF2EAD65), size: 54),
          const SizedBox(height: 8),
          const Text(
            'Payment Completed!',
            style: TextStyle(fontSize: 20, fontWeight: FontWeight.w900, color: Color(0xFF183B20)),
          ),
          const SizedBox(height: 2),
          const Text('Digital Collection Receipt', style: TextStyle(fontSize: 12, color: Color(0xFF647568))),
          const SizedBox(height: 18),

          // Digital Receipt Box
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: const Color(0xFFF7FAF5),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: const Color(0xFFD6E2D5)),
            ),
            child: Column(
              children: [
                _receiptRow('Transaction ID', _transactionId ?? 'TX-998811'),
                const Divider(height: 16),
                _receiptRow('Paid At', formatDateTime(_paidAt ?? DateTime.now())),
                const Divider(height: 16),
                _receiptRow('Paid To', 'Arua EcoRoute Municipal Service'),
                const Divider(height: 16),
                _receiptRow('Payer Phone', _phoneController.text),
                const Divider(height: 16),
                _receiptRow('Method', _isCashMode ? 'Hard Cash to Rider (Gate Handover)' : _provider.label),
                const Divider(height: 16),
                _receiptRow('Sacks & Waste', '${widget.request.sackCount} sacks (${widget.request.wasteType.label})'),
                const Divider(height: 16),
                _receiptRow('Location', 'Instant Pickup • ${widget.request.address}'),
                const Divider(height: 16),
                _receiptRow('Collection Account', MoMoPaymentDialog.collectionAccount),
                const Divider(height: 16),
                _receiptRow('Amount Settled', formatUgx(widget.request.priceUgx), isBold: true),
              ],
            ),
          ),
          const SizedBox(height: 14),

          // Official verification stamp
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: const Color(0xFFE8F5E9),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: const Color(0xFF81C784)),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.receipt_long_rounded, size: 16, color: Color(0xFF2E7D32)),
                const SizedBox(width: 6),
                Flexible(
                  child: Text(
                    _isCashMode
                        ? 'CASH PAYMENT ACCEPTED • ECOROUTE'
                        : 'DEMO TRANSACTION • ECOROUTE',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.w800,
                      color: Color(0xFF2E7D32),
                      letterSpacing: 0.5,
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 18),

          Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: _copyReceiptToClipboard,
                  icon: const Icon(Icons.copy_rounded, size: 16),
                  label: const Text('Copy Receipt'),
                  style: OutlinedButton.styleFrom(
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: FilledButton(
                  style: FilledButton.styleFrom(
                    backgroundColor: const Color(0xFF2E7D32),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  onPressed: () => Navigator.of(context).pop(),
                  child: const Text('Done & Close Receipt'),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildFailedStep() {
    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.error_outline_rounded, color: Colors.redAccent, size: 54),
          const SizedBox(height: 12),
          const Text(
            'Payment Unsuccessful',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800, color: Color(0xFF1B2E23)),
          ),
          const SizedBox(height: 8),
          Text(
            _errorMessage ?? 'The transaction could not be processed. Please verify your phone number and try again.',
            textAlign: TextAlign.center,
            style: const TextStyle(fontSize: 13, color: Color(0xFF647568)),
          ),
          const SizedBox(height: 20),
          Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  onPressed: () => Navigator.of(context).pop(),
                  child: const Text('Cancel'),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: FilledButton(
                  style: FilledButton.styleFrom(backgroundColor: const Color(0xFF2E7D32)),
                  onPressed: () => setState(() {
                    _errorMessage = null;
                    _step = 0;
                  }),
                  child: const Text('Retry'),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _receiptRow(String label, String value, {bool isBold = false}) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label, style: const TextStyle(fontSize: 12, color: Color(0xFF647568))),
        const SizedBox(width: 12),
        Expanded(
          child: Text(
            value,
            textAlign: TextAlign.end,
            style: TextStyle(
              fontSize: isBold ? 14 : 12,
              fontWeight: isBold ? FontWeight.w900 : FontWeight.w700,
              color: isBold ? const Color(0xFF1B5E20) : const Color(0xFF183B20),
            ),
          ),
        ),
      ],
    );
  }
}
