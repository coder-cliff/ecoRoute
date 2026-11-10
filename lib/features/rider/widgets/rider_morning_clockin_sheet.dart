import 'package:flutter/material.dart';

import '../../../core/layout/adaptive_layout.dart';
import '../../../core/theme/eco_palette.dart';
import '../../../main.dart';
import '../../common/widgets/slide_to_confirm_widget.dart';

/// Pre-flight Depot Rollout & Morning Clock-In Sheet for Riders
class RiderMorningClockInSheet extends StatefulWidget {
  const RiderMorningClockInSheet({
    super.key,
    required this.onShiftStarted,
  });

  final VoidCallback onShiftStarted;

  @override
  State<RiderMorningClockInSheet> createState() =>
      _RiderMorningClockInSheetState();
}

class _RiderMorningClockInSheetState extends State<RiderMorningClockInSheet> {
  int _greenSacksLoaded = 25;
  int _blueSacksLoaded = 25;
  int _hazardSacksLoaded = 5;
  int _startingCashFloatUgx = 10000;
  double _batteryLevel = 92.0;

  bool _checkedVest = true;
  bool _checkedGloves = true;
  bool _checkedScale = true;
  bool _isClockingIn = false;

  void _handleConfirmShift() {
    setState(() => _isClockingIn = true);

    final state = EcoRouteState.instance;
    // Update shift metrics
    state.riderCashInPouch = _startingCashFloatUgx;
    state.prefs?.setBool('ecoroute_rider_shift_active', true);
    state.prefs?.setString('ecoroute_rider_shift_start_time', DateTime.now().toIso8601String());

    Future.delayed(const Duration(milliseconds: 600), () {
      if (mounted) {
        widget.onShiftStarted();
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
      height: MediaQuery.of(context).size.height * 0.88,
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
                  child: const Icon(Icons.wb_sunny_outlined, color: EcoPalette.primaryForest, size: 22),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Depot Rollout & Shift Clock-In',
                        style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                      ),
                      Text(
                        'Arua Municipal Depot • Pre-flight safety check',
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
                  child: const Row(
                    children: [
                      Icon(Icons.cloud_queue, size: 13, color: Color(0xFF2E7D32)),
                      SizedBox(width: 4),
                      Text('21°C Dry', style: TextStyle(color: Color(0xFF2E7D32), fontSize: 11, fontWeight: FontWeight.bold)),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const Divider(height: 1),

          // Rollout Content
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Sacks Loaded Counter Card
                  Text('1. EMPTY SACKS IN CARGO BED', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: subtextColor)),
                  const SizedBox(height: 8),
                  Container(
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: isDark ? const Color(0xFF1E2D22) : const Color(0xFFF4F7F4),
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: Column(
                      children: [
                        _buildSackCounterRow(
                          'Organic Sacks (Green)',
                          _greenSacksLoaded,
                          const Color(0xFF2E7D32),
                          (val) => setState(() => _greenSacksLoaded = val),
                        ),
                        const Divider(height: 14),
                        _buildSackCounterRow(
                          'Recyclable Dry Sacks (Blue)',
                          _blueSacksLoaded,
                          const Color(0xFF1976D2),
                          (val) => setState(() => _blueSacksLoaded = val),
                        ),
                        const Divider(height: 14),
                        _buildSackCounterRow(
                          'Hazard / Sharp Sacks (Red)',
                          _hazardSacksLoaded,
                          const Color(0xFFD32F2F),
                          (val) => setState(() => _hazardSacksLoaded = val),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Starting Cash Float Card
                  Text('2. STARTING CASH FLOAT (FOR CHANGE)', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: subtextColor)),
                  const SizedBox(height: 8),
                  Container(
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: isDark ? const Color(0xFF1E2D22) : const Color(0xFFF4F7F4),
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.account_balance_wallet, color: Color(0xFF2E7D32), size: 24),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text('Physical Cash in Pouch', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: textColor)),
                              Text('Issued by Municipal Settlement Desk', style: TextStyle(fontSize: 11, color: subtextColor)),
                            ],
                          ),
                        ),
                        Text(
                          '${_startingCashFloatUgx.toString()} UGX',
                          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: Color(0xFF2E7D32)),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Vehicle Battery / Powertrain Check
                  Text('3. VEHICLE POWERTRAIN LEVEL', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: subtextColor)),
                  const SizedBox(height: 8),
                  Container(
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: isDark ? const Color(0xFF1E2D22) : const Color(0xFFF4F7F4),
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: Column(
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            const Row(
                              children: [
                                Icon(Icons.battery_charging_full, color: Color(0xFF2E7D32), size: 20),
                                SizedBox(width: 8),
                                Text('Battery Level / State of Charge', style: TextStyle(fontSize: 12.5, fontWeight: FontWeight.bold)),
                              ],
                            ),
                            Text('${_batteryLevel.toInt()}%', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: Color(0xFF2E7D32))),
                          ],
                        ),
                        Slider(
                          value: _batteryLevel,
                          min: 10,
                          max: 100,
                          divisions: 18,
                          activeColor: EcoPalette.primaryForest,
                          onChanged: (val) => setState(() => _batteryLevel = val),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Safety Equipment Checkbox List
                  Text('4. SAFETY PROTOCOLS', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: subtextColor)),
                  const SizedBox(height: 6),
                  CheckboxListTile(
                    dense: true,
                    contentPadding: EdgeInsets.zero,
                    value: _checkedVest,
                    title: const Text('High-Vis Reflective Vest Worn', style: TextStyle(fontSize: 12)),
                    activeColor: EcoPalette.primaryForest,
                    onChanged: (v) => setState(() => _checkedVest = v ?? false),
                  ),
                  CheckboxListTile(
                    dense: true,
                    contentPadding: EdgeInsets.zero,
                    value: _checkedGloves,
                    title: const Text('Heavy-duty puncture-resistant waste gloves equipped', style: TextStyle(fontSize: 12)),
                    activeColor: EcoPalette.primaryForest,
                    onChanged: (v) => setState(() => _checkedGloves = v ?? false),
                  ),
                  CheckboxListTile(
                    dense: true,
                    contentPadding: EdgeInsets.zero,
                    value: _checkedScale,
                    title: const Text('Luggage scale & bag fastener zip-ties on board', style: TextStyle(fontSize: 12)),
                    activeColor: EcoPalette.primaryForest,
                    onChanged: (v) => setState(() => _checkedScale = v ?? false),
                  ),
                ],
              ),
            ),
          ),

          // Slide to Confirm Action Bar
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: cardBg,
              border: Border(top: BorderSide(color: Colors.grey.withOpacity(0.15))),
            ),
            child: SlideToConfirmWidget(
              label: 'SLIDE TO START SHIFT',
              sliderColor: const Color(0xFF1E5E3A),
              isLoading: _isClockingIn,
              onConfirmed: _handleConfirmShift,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSackCounterRow(String title, int count, Color color, ValueChanged<int> onChanged) {
    return Row(
      children: [
        Container(
          width: 10,
          height: 10,
          decoration: BoxDecoration(color: color, shape: BoxShape.circle),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: Text(title, style: const TextStyle(fontSize: 12.5, fontWeight: FontWeight.w600)),
        ),
        IconButton(
          icon: const Icon(Icons.remove_circle_outline, size: 20),
          visualDensity: VisualDensity.compact,
          onPressed: count > 0 ? () => onChanged(count - 5) : null,
        ),
        Text('$count', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
        IconButton(
          icon: const Icon(Icons.add_circle_outline, size: 20),
          visualDensity: VisualDensity.compact,
          onPressed: count < 100 ? () => onChanged(count + 5) : null,
        ),
      ],
    );
  }
}
