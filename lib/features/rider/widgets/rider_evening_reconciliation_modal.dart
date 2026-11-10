import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:qr_flutter/qr_flutter.dart';

import '../../../core/layout/adaptive_layout.dart';
import '../../../core/theme/eco_palette.dart';
import '../../../main.dart';
import '../../common/widgets/slide_to_confirm_widget.dart';

/// Evening Depot Return & Cash Settlement Reconciliation Modal for Riders
class RiderEveningReconciliationModal extends StatefulWidget {
  const RiderEveningReconciliationModal({
    super.key,
    required this.onShiftEnded,
  });

  final VoidCallback onShiftEnded;

  @override
  State<RiderEveningReconciliationModal> createState() =>
      _RiderEveningReconciliationModalState();
}

class _RiderEveningReconciliationModalState
    extends State<RiderEveningReconciliationModal> {
  final _tonnageController = TextEditingController(text: '240');
  final _scaleTicketController = TextEditingController(text: 'AR-W-9842');

  int _baseStartingFloat = 10000;
  bool _supervisorSignedOff = false;
  bool _isConcluding = false;

  @override
  void dispose() {
    _tonnageController.dispose();
    _scaleTicketController.dispose();
    super.dispose();
  }

  void _handleConcludeShift() {
    setState(() => _isConcluding = true);

    final state = EcoRouteState.instance;
    final totalCash = state.riderCashInPouch;
    final netRemittance = (totalCash - _baseStartingFloat).clamp(0, 1000000);

    // Record depot reconciliation log
    state.cashReconciliationLog.insert(0, {
      'timestamp': DateTime.now().toIso8601String(),
      'riderName': state.userName.isNotEmpty ? state.userName : 'EcoRoute Field Rider',
      'tricycleId': state.prefs?.getString('ecoroute_rider_tricycle_v1') ?? 'TRIC-02',
      'grossCashPouch': totalCash,
      'startingFloatReturned': _baseStartingFloat,
      'remittedToDepotDesk': netRemittance,
      'weighInKg': double.tryParse(_tonnageController.text) ?? 240.0,
      'scaleTicket': _scaleTicketController.text.trim(),
    });

    // Reset rider shift
    state.riderCashInPouch = 0;
    state.totalDepotReconciledCash += netRemittance;
    state.prefs?.setBool('ecoroute_rider_shift_active', false);
    state.prefs?.remove('ecoroute_rider_shift_start_time');

    Future.delayed(const Duration(milliseconds: 600), () {
      if (mounted) {
        widget.onShiftEnded();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final state = EcoRouteState.instance;
    final isDark = AntigravityTheme.isDark(context);
    final cardBg = AntigravityTheme.card(context);
    final textColor = AntigravityTheme.textPrimary(context);
    final subtextColor = AntigravityTheme.textSecondary(context);

    final totalCashInPouch = state.riderCashInPouch > 0 ? state.riderCashInPouch : 45000;
    final grossCollected = (totalCashInPouch - _baseStartingFloat).clamp(0, 1000000);
    final riderCommission = (grossCollected * 0.70).toInt();
    final dueToDepotDesk = (grossCollected - riderCommission) + _baseStartingFloat;

    final settlementQrPayload = jsonEncode({
      'type': 'ECO_DEPOT_SETTLEMENT_V1',
      'rider': state.userName.isNotEmpty ? state.userName : 'Arua Rider',
      'tricycle': state.prefs?.getString('ecoroute_rider_tricycle_v1') ?? 'TRIC-02',
      'cashInPouch': totalCashInPouch,
      'commission': riderCommission,
      'dueToDepot': dueToDepotDesk,
      'weightKg': double.tryParse(_tonnageController.text) ?? 240.0,
      'ticket': _scaleTicketController.text,
      'timestamp': DateTime.now().toIso8601String(),
    });

    return Container(
      height: MediaQuery.of(context).size.height * 0.90,
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

          // Header
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: EcoPalette.primaryForest.withOpacity(0.12),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Icon(Icons.nightlight_round, color: EcoPalette.primaryForest, size: 22),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Depot Return & Reconciliation',
                        style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                      ),
                      Text(
                        'Arua Municipal Depot • Shift wrap-up & cash sign-off',
                        style: TextStyle(fontSize: 11.5, color: subtextColor),
                      ),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: const Color(0xFFE8F5E9),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Text('Depot Desk', style: TextStyle(color: Color(0xFF2E7D32), fontSize: 11, fontWeight: FontWeight.bold)),
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
                  // Dumpsite Weigh-In
                  Text('1. DUMPSITE / DEPOT TONNAGE WEIGH-IN', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: subtextColor)),
                  const SizedBox(height: 8),
                  Container(
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: isDark ? const Color(0xFF1E2D22) : const Color(0xFFF4F7F4),
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: Row(
                      children: [
                        Expanded(
                          child: TextFormField(
                            controller: _tonnageController,
                            keyboardType: TextInputType.number,
                            decoration: const InputDecoration(
                              labelText: 'Total Collected Waste (KG)',
                              prefixIcon: Icon(Icons.scale, size: 20),
                              suffixText: 'kg',
                              border: OutlineInputBorder(),
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: TextFormField(
                            controller: _scaleTicketController,
                            decoration: const InputDecoration(
                              labelText: 'Depot Scale Ticket',
                              prefixIcon: Icon(Icons.receipt_long, size: 20),
                              border: OutlineInputBorder(),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Financial Reconciliation Table
                  Text('2. FINANCIAL DESK RECONCILIATION', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: subtextColor)),
                  const SizedBox(height: 8),
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: isDark ? const Color(0xFF1E3224) : const Color(0xFFE8F5E9),
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(color: const Color(0xFF81C784)),
                    ),
                    child: Column(
                      children: [
                        _buildLedgerRow('Total Physical Cash in Pouch', '$totalCashInPouch UGX', true),
                        const Divider(height: 14),
                        _buildLedgerRow('Morning Starting Float Returned', '-$_baseStartingFloat UGX', false),
                        _buildLedgerRow('Gross Pickup Revenue', '$grossCollected UGX', false),
                        _buildLedgerRow('Rider Commission (70% Retained)', '+$riderCommission UGX', true, color: const Color(0xFF2E7D32)),
                        const Divider(height: 14),
                        _buildLedgerRow('NET CASH DUE TO DEPOT DESK', '$dueToDepotDesk UGX', true, color: const Color(0xFF1B5E20), isLarge: true),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Supervisor QR Handshake
                  Text('3. SUPERVISOR SETTLEMENT HANDSHAKE', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: subtextColor)),
                  const SizedBox(height: 8),
                  Container(
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: isDark ? const Color(0xFF1E2D22) : const Color(0xFFF4F7F4),
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: Column(
                      children: [
                        const Text(
                          'Present this settlement QR to the Depot Desk Supervisor for instant verification.',
                          style: TextStyle(fontSize: 11.5, textAlign: TextAlign.center),
                        ),
                        const SizedBox(height: 12),
                        Center(
                          child: Container(
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(color: Colors.grey.withOpacity(0.3)),
                            ),
                            child: QrImageView(
                              data: settlementQrPayload,
                              version: QrVersions.auto,
                              size: 150.0,
                            ),
                          ),
                        ),
                        const SizedBox(height: 10),
                        CheckboxListTile(
                          dense: true,
                          contentPadding: EdgeInsets.zero,
                          value: _supervisorSignedOff,
                          title: const Text('Depot Supervisor confirmed cash remittance & inspected tricycle bed', style: TextStyle(fontSize: 11.5, fontWeight: FontWeight.w600)),
                          activeColor: EcoPalette.primaryForest,
                          onChanged: (v) => setState(() => _supervisorSignedOff = v ?? false),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),

          // Slide to End Shift Action
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: cardBg,
              border: Border(top: BorderSide(color: Colors.grey.withOpacity(0.15))),
            ),
            child: SlideToConfirmWidget(
              label: 'SLIDE TO LOCK TRICYCLE & END SHIFT',
              sliderColor: const Color(0xFF9C3D18),
              icon: Icons.lock_outline,
              isLoading: _isConcluding,
              onConfirmed: _handleConcludeShift,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLedgerRow(String label, String value, bool isBold, {Color? color, bool isLarge = false}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: TextStyle(
              fontSize: isLarge ? 13 : 12,
              fontWeight: isBold ? FontWeight.bold : FontWeight.normal,
            ),
          ),
          Text(
            value,
            style: TextStyle(
              fontSize: isLarge ? 15 : 12.5,
              fontWeight: isBold ? FontWeight.bold : FontWeight.w600,
              color: color,
            ),
          ),
        ],
      ),
    );
  }
}
