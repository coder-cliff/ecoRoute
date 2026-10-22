import 'dart:async';
import 'package:flutter/material.dart';

import '../../core/utils/formatters.dart';
import '../../domain/entities/pickup_request.dart';
import '../../domain/enums/request_status.dart';
import '../../domain/enums/waste_type.dart';
import '../../domain/enums/zone.dart';

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
    this.initialPhone = '+256394880352',
    super.key,
  });

  final PickupRequest request;
  final String initialPhone;
  final Future<void> Function(PickupRequest updatedRequest) onPaymentSuccess;

  @override
  State<MoMoPaymentDialog> createState() => _MoMoPaymentDialogState();
}

class _MoMoPaymentDialogState extends State<MoMoPaymentDialog> {
  MoMoProvider _provider = MoMoProvider.mtn;
  late final TextEditingController _phoneController;
  final TextEditingController _pinController = TextEditingController();

  int _step = 0; // 0: Enter Details, 1: USSD Push Waiting, 2: Receipt
  String? _transactionId;
  DateTime? _paidAt;

  @override
  void initState() {
    super.initState();
    _phoneController = TextEditingController(text: widget.initialPhone);
  }

  @override
  void dispose() {
    _phoneController.dispose();
    _pinController.dispose();
    super.dispose();
  }

  Future<void> _simulatePayment() async {
    setState(() => _step = 1);

    // Simulate network USSD push delay
    await Future<void>.delayed(const Duration(milliseconds: 1600));

    final txId = 'TX-${_provider == MoMoProvider.mtn ? 'MTN' : 'AIR'}-${DateTime.now().millisecondsSinceEpoch.toString().substring(5)}';
    final now = DateTime.now();

    final updated = widget.request.copyWith(
      status: RequestStatus.paid,
      residentPhone: _phoneController.text.trim(),
    );

    await widget.onPaymentSuccess(updated);

    if (!mounted) return;
    setState(() {
      _transactionId = txId;
      _paidAt = now;
      _step = 2; // Show receipt
    });
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
            _ => _buildReceiptStep(),
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
                      'Official Arua Municipal Gateway',
                      style: TextStyle(fontSize: 11, color: Color(0xFF647568)),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 18),

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
          const SizedBox(height: 18),

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
          Text(
            'Sending USSD Prompt...',
            style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w800),
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
                _receiptRow('Method', _provider.label),
                const Divider(height: 16),
                _receiptRow('Sacks & Waste', '${widget.request.sackCount} sacks (${widget.request.wasteType.label})'),
                const Divider(height: 16),
                _receiptRow('Location', '${widget.request.zone.label} zone • ${widget.request.address}'),
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
            child: const Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.verified_outlined, size: 16, color: Color(0xFF2E7D32)),
                SizedBox(width: 6),
                Text(
                  'AUDITED & CLEARED • ARUA CITY',
                  style: TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.w800,
                    color: Color(0xFF2E7D32),
                    letterSpacing: 0.5,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 18),

          SizedBox(
            width: double.infinity,
            height: 48,
            child: FilledButton(
              style: FilledButton.styleFrom(backgroundColor: const Color(0xFF2E7D32)),
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Done & Close Receipt'),
            ),
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
