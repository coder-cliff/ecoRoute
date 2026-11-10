import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

import '../../../core/layout/adaptive_layout.dart';
import '../../../core/theme/eco_palette.dart';
import '../../../main.dart';

/// High-contrast, sunlight-readable modal for single-tap street pickup execution
class RiderPickupActionModal extends StatefulWidget {
  const RiderPickupActionModal({
    super.key,
    required this.task,
    required this.onCompleted,
  });

  final Map<String, dynamic> task;
  final VoidCallback onCompleted;

  @override
  State<RiderPickupActionModal> createState() => _RiderPickupActionModalState();
}

class _RiderPickupActionModalState extends State<RiderPickupActionModal> {
  int _organicSacks = 2;
  int _recyclableSacks = 1;
  int _hazardousSacks = 0;
  bool _isCashPayment = true;
  String? _photoProofPath;
  bool _isSubmitting = false;

  int get _totalSacks => _organicSacks + _recyclableSacks + _hazardousSacks;
  int get _calculatedFeeUgx {
    // Arua municipal tariff: 1,500 UGX per organic/recyclable, 3,000 UGX per hazardous
    return (_organicSacks * 1500) + (_recyclableSacks * 1500) + (_hazardousSacks * 3000);
  }

  Future<void> _handleCaptureProof() async {
    try {
      final picker = ImagePicker();
      final photo = await picker.pickImage(
        source: ImageSource.camera,
        maxWidth: 800,
        maxHeight: 800,
        imageQuality: 65,
      );
      if (photo != null) {
        setState(() => _photoProofPath = photo.path);
      }
    } catch (e) {
      debugPrint('Camera notice: $e');
    }
  }

  void _handleConfirmPickup() {
    setState(() => _isSubmitting = true);

    final state = EcoRouteState.instance;
    final earnedCommission = (_calculatedFeeUgx * 0.70).toInt();

    // If cash paid in hand, add to rider's cash in pouch
    if (_isCashPayment) {
      state.riderCashInPouch += _calculatedFeeUgx;
    }

    state.riderLedgerBalance += earnedCommission;

    // Log transaction
    state.riderTransactions.insert(0, {
      'title': 'Pickup: ${widget.task['client'] ?? widget.task['address'] ?? "Stop"}',
      'amount': '+$earnedCommission UGX',
      'date': 'Just Now',
      'type': 'pickup_commission',
      'sacks': _totalSacks,
      'isCash': _isCashPayment,
    });

    // Mark task settled
    widget.task['status'] = 'Settled';
    widget.task['sacks'] = _totalSacks;
    widget.task['feeUgx'] = _calculatedFeeUgx;

    Future.delayed(const Duration(milliseconds: 400), () {
      if (mounted) {
        widget.onCompleted();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final isDark = AntigravityTheme.isDark(context);
    final cardBg = AntigravityTheme.card(context);
    final textColor = AntigravityTheme.textPrimary(context);
    final subtextColor = AntigravityTheme.textSecondary(context);

    return Container(
      height: MediaQuery.of(context).size.height * 0.85,
      decoration: BoxDecoration(
        color: cardBg,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
        boxShadow: const [
          BoxShadow(color: Color(0x33000000), blurRadius: 24, offset: Offset(0, -6)),
        ],
      ),
      child: Column(
        children: [
          // Drag handle
          Center(
            child: Container(
              margin: const EdgeInsets.only(top: 10, bottom: 8),
              width: 44,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.grey.withOpacity(0.3),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),

          // Header Stop Info
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: const Color(0xFFE8F5E9),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Icon(Icons.location_on, color: Color(0xFF2E7D32), size: 24),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        widget.task['client'] ?? widget.task['address'] ?? 'Household Collection',
                        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                      ),
                      Text(
                        widget.task['address'] ?? 'Ayivu Zone, Plot 42',
                        style: TextStyle(fontSize: 12, color: subtextColor),
                      ),
                    ],
                  ),
                ),
                IconButton.filled(
                  icon: const Icon(Icons.call, size: 18),
                  style: IconButton.styleFrom(backgroundColor: const Color(0xFF1E5E3A)),
                  onPressed: () => launchEcoRouteCall(),
                ),
              ],
            ),
          ),
          const Divider(height: 1),

          // Body
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Sacks Tally Section
                  Text('1. COUNT SACKS COLLECTED', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: subtextColor)),
                  const SizedBox(height: 8),
                  Container(
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: isDark ? const Color(0xFF1E2D22) : const Color(0xFFF4F7F4),
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: Column(
                      children: [
                        _buildSackCounter('Organic Waste (Green)', _organicSacks, const Color(0xFF2E7D32), (v) => setState(() => _organicSacks = v)),
                        const Divider(height: 12),
                        _buildSackCounter('Recyclable Plastics (Blue)', _recyclableSacks, const Color(0xFF1976D2), (v) => setState(() => _recyclableSacks = v)),
                        const Divider(height: 12),
                        _buildSackCounter('Hazardous / Sharps (Red)', _hazardousSacks, const Color(0xFFD32F2F), (v) => setState(() => _hazardousSacks = v)),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Calculated Fee & Payment Mode
                  Text('2. COLLECTION FEE & PAYMENT', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: subtextColor)),
                  const SizedBox(height: 8),
                  Container(
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: isDark ? const Color(0xFF1E3224) : const Color(0xFFE8F5E9),
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(color: const Color(0xFF81C784)),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text('Total Calculated Fee', style: TextStyle(fontSize: 11.5, color: Color(0xFF2E7D32), fontWeight: FontWeight.w600)),
                            const SizedBox(height: 2),
                            Text(
                              '$_calculatedFeeUgx UGX',
                              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18, color: Color(0xFF1B5E20)),
                            ),
                          ],
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                          decoration: BoxDecoration(
                            color: const Color(0xFF2E7D32),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(
                            '$_totalSacks Sacks',
                            style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 12),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 12),

                  // Payment method selector
                  Row(
                    children: [
                      Expanded(
                        child: ChoiceChip(
                          selected: _isCashPayment,
                          selectedColor: const Color(0xFF1E5E3A),
                          backgroundColor: cardBg,
                          label: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(Icons.money, size: 16, color: _isCashPayment ? Colors.white : textColor),
                              const SizedBox(width: 6),
                              Text('Cash in Pouch', style: TextStyle(color: _isCashPayment ? Colors.white : textColor, fontWeight: FontWeight.bold, fontSize: 12)),
                            ],
                          ),
                          onSelected: (val) => setState(() => _isCashPayment = true),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: ChoiceChip(
                          selected: !_isCashPayment,
                          selectedColor: const Color(0xFF1E5E3A),
                          backgroundColor: cardBg,
                          label: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(Icons.phone_android, size: 16, color: !_isCashPayment ? Colors.white : textColor),
                              const SizedBox(width: 6),
                              Text('Paid via MoMo', style: TextStyle(color: !_isCashPayment ? Colors.white : textColor, fontWeight: FontWeight.bold, fontSize: 12)),
                            ],
                          ),
                          onSelected: (val) => setState(() => _isCashPayment = false),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),

                  // Photo Proof Snapshot
                  Text('3. PHOTO PROOF EVIDENCE', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: subtextColor)),
                  const SizedBox(height: 8),
                  OutlinedButton.icon(
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                    onPressed: _handleCaptureProof,
                    icon: Icon(_photoProofPath != null ? Icons.check_circle : Icons.camera_alt, color: _photoProofPath != null ? Colors.green : null),
                    label: Text(_photoProofPath != null ? 'Bag Photo Captured (Locked to Order)' : 'Snap Photo of Placed Sacks'),
                  ),
                ],
              ),
            ),
          ),

          // Confirm Button
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: cardBg,
              border: Border(top: BorderSide(color: Colors.grey.withOpacity(0.15))),
            ),
            child: ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF1E5E3A),
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
              ),
              onPressed: _isSubmitting || _totalSacks == 0 ? null : _handleConfirmPickup,
              child: _isSubmitting
                  ? const SizedBox(
                      height: 20,
                      width: 20,
                      child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                    )
                  : Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(Icons.check_circle, size: 20),
                        const SizedBox(width: 8),
                        Text(
                          'Confirm & Complete Pickup ($_calculatedFeeUgx UGX)',
                          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                        ),
                      ],
                    ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSackCounter(String title, int count, Color color, ValueChanged<int> onChanged) {
    return Row(
      children: [
        Container(width: 10, height: 10, decoration: BoxDecoration(color: color, shape: BoxShape.circle)),
        const SizedBox(width: 8),
        Expanded(child: Text(title, style: const TextStyle(fontSize: 12.5, fontWeight: FontWeight.w600))),
        IconButton(
          icon: const Icon(Icons.remove_circle_outline, size: 22),
          visualDensity: VisualDensity.compact,
          onPressed: count > 0 ? () => onChanged(count - 1) : null,
        ),
        Text('$count', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
        IconButton(
          icon: const Icon(Icons.add_circle_outline, size: 22),
          visualDensity: VisualDensity.compact,
          onPressed: count < 20 ? () => onChanged(count + 1) : null,
        ),
      ],
    );
  }
}
