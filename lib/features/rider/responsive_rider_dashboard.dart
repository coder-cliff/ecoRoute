import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:latlong2/latlong.dart';

import '../../core/layout/adaptive_layout.dart';
import '../../core/services/osrm_routing_service.dart';
import '../../core/theme/eco_palette.dart';
import '../../main.dart';
import '../common/widgets/eco_carto_map.dart';
import 'widgets/rider_evening_reconciliation_modal.dart';
import 'widgets/rider_morning_clockin_sheet.dart';
import 'widgets/rider_pickup_action_modal.dart';
import 'widgets/rider_profile_setup_wizard.dart';

/// Responsive Rider Field Operations Dashboard
/// Conforms to Architectural Wireframe B:
///   - Smartphone (<600px): One-handed high vibration constraints
///   - Tablet Dual-Pane (600px - 1024px): Task list on left + telemetry map & workflow matrix on right
class ResponsiveRiderDashboard extends StatefulWidget {
  const ResponsiveRiderDashboard({super.key});

  @override
  State<ResponsiveRiderDashboard> createState() =>
      _ResponsiveRiderDashboardState();
}

class _ResponsiveRiderDashboardState extends State<ResponsiveRiderDashboard> {
  int _selectedTaskIndex = 0;
  double _recordedWeightKg = 45.0;
  int _currentBottomNavIndex = 0;
  final TextEditingController _smsCodeController =
      TextEditingController(text: 'Q1A2B3C4D5');

  @override
  void dispose() {
    _smsCodeController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (ViewportBreakpoints.isTablet(context) ||
        ViewportBreakpoints.isDesktop(context)) {
      return _buildTabletDualPaneLayout();
    } else {
      return _buildSmartphoneLayout();
    }
  }

  // =========================================================================
  // SMARTPHONE VIEWPORT (<600px) - WIREFRAME B SPECIFICATION
  // =========================================================================
  Widget _buildSmartphoneLayout() {
    final state = EcoRouteState.instance;
    final isDark = AntigravityTheme.isDark(context);
    final surfaceColor = AntigravityTheme.surface(context);
    final cardColor = AntigravityTheme.card(context);
    final textColor = AntigravityTheme.textPrimary(context);
    final subtextColor = AntigravityTheme.textSecondary(context);
    final accentGreen = AntigravityTheme.ecoAccent(context);

    final currentTask = state.riderTasks.isNotEmpty &&
            _selectedTaskIndex < state.riderTasks.length
        ? state.riderTasks[_selectedTaskIndex]
        : null;

    return Scaffold(
      backgroundColor: surfaceColor,
      appBar: AppBar(
        backgroundColor: surfaceColor,
        elevation: 0,
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                color: accentGreen.withOpacity(0.15),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                'Rider Unit: TRIC-18',
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.bold,
                  color: accentGreen,
                ),
              ),
            ),
            const Spacer(),
            Row(
              children: [
                const Icon(Icons.battery_5_bar, color: Color(0xFF2E7D32), size: 20),
                const SizedBox(width: 4),
                Text(
                  'Battery: 92%',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                    color: textColor,
                  ),
                ),
              ],
            ),
          ],
        ),
        actions: [
          IconButton(
            tooltip: 'Toggle Theme',
            icon: Icon(
              isDark ? Icons.light_mode_outlined : Icons.dark_mode_outlined,
              color: textColor,
            ),
            onPressed: () => state.toggleTheme(),
          ),
          IconButton(
            tooltip: 'Rider Profile Wizard',
            icon: Icon(Icons.badge_outlined, color: textColor),
            onPressed: () => _openProfileSetupWizard(context),
          ),
          IconButton(
            tooltip: 'My Profile',
            icon: Icon(Icons.account_circle_outlined, color: textColor),
            onPressed: () => showEcoRouteProfileSheet(context),
          ),
          IconButton(
            tooltip: 'Sign Out',
            icon: const Icon(Icons.logout, color: Colors.redAccent),
            onPressed: () => state.logout(context),
          ),
        ],
      ),
      body: _buildSmartphoneBody(state, textColor, subtextColor, cardColor, accentGreen, isDark, currentTask),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _currentBottomNavIndex,
        onTap: (index) => setState(() => _currentBottomNavIndex = index),
        backgroundColor: cardColor,
        selectedItemColor: accentGreen,
        unselectedItemColor: subtextColor,
        type: BottomNavigationBarType.fixed,
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.assignment_outlined), activeIcon: Icon(Icons.assignment), label: 'Tasks'),
          BottomNavigationBarItem(icon: Icon(Icons.navigation_outlined), activeIcon: Icon(Icons.navigation), label: 'Route'),
          BottomNavigationBarItem(icon: Icon(Icons.account_balance_wallet_outlined), activeIcon: Icon(Icons.account_balance_wallet), label: 'Earnings'),
        ],
      ),
    );
  }

  Widget _buildSmartphoneBody(
    EcoRouteState state,
    Color textColor,
    Color subtextColor,
    Color cardColor,
    Color accentGreen,
    bool isDark,
    Map<String, dynamic>? currentTask,
  ) {
    switch (_currentBottomNavIndex) {
      case 1:
        return _buildSmartphoneRouteView(state, textColor, subtextColor, cardColor, accentGreen, isDark);
      case 2:
        return _buildSmartphoneEarningsView(state, textColor, subtextColor, cardColor, accentGreen, isDark);
      case 0:
      default:
        return _buildSmartphoneTasksView(state, textColor, subtextColor, cardColor, accentGreen, isDark, currentTask);
    }
  }

  Widget _buildSmartphoneTasksView(
    EcoRouteState state,
    Color textColor,
    Color subtextColor,
    Color cardColor,
    Color accentGreen,
    bool isDark,
    Map<String, dynamic>? currentTask,
  ) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // SHIFT STATUS & DEPOT OPERATIONS BANNER
          Builder(
            builder: (ctx) {
              final isShiftActive = state.prefs?.getBool('ecoroute_rider_shift_active') ?? false;
              return Container(
                margin: const EdgeInsets.only(bottom: 14),
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: isShiftActive
                      ? (isDark ? const Color(0xFF1E3224) : const Color(0xFFE8F5E9))
                      : (isDark ? const Color(0xFF332015) : const Color(0xFFFFF3E0)),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: isShiftActive ? const Color(0xFF81C784) : const Color(0xFFFFB74D),
                  ),
                ),
                child: Row(
                  children: [
                    Icon(
                      isShiftActive ? Icons.radio_button_checked : Icons.lock_clock,
                      color: isShiftActive ? const Color(0xFF2E7D32) : const Color(0xFFE65100),
                      size: 22,
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            isShiftActive ? '● SHIFT ACTIVE: ON ARUA ROUTE' : 'SHIFT NOT STARTED',
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                              color: isShiftActive ? const Color(0xFF1B5E20) : const Color(0xFFBF360C),
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            isShiftActive
                                ? 'Cash in Pouch: ${state.riderCashInPouch} UGX'
                                : 'Clock in at Depot to unlock route navigation.',
                            style: TextStyle(fontSize: 11, color: subtextColor),
                          ),
                        ],
                      ),
                    ),
                    FilledButton(
                      style: FilledButton.styleFrom(
                        backgroundColor: isShiftActive ? const Color(0xFF9C3D18) : const Color(0xFF1E5E3A),
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                        visualDensity: VisualDensity.compact,
                      ),
                      onPressed: () {
                        if (isShiftActive) {
                          _openEveningReconciliationSheet(context);
                        } else {
                          _openMorningClockInSheet(context);
                        }
                      },
                      child: Text(
                        isShiftActive ? 'Reconcile' : 'Clock In',
                        style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold),
                      ),
                    ),
                  ],
                ),
              );
            },
          ),

          // CURRENT RECIPIENT TASK CARD
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: cardColor,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: AntigravityTheme.border(context)),
            ),
            child: currentTask == null
                ? Padding(
                    padding: const EdgeInsets.symmetric(vertical: 8),
                    child: Column(
                      children: [
                        Icon(Icons.inbox_outlined, size: 32, color: subtextColor),
                        const SizedBox(height: 8),
                        Text(
                          'No Active Tasks Assigned',
                          style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: textColor),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'Your collection queue is currently empty. New requests from residents in your zone will appear here in real time.',
                          textAlign: TextAlign.center,
                          style: TextStyle(fontSize: 11.5, color: subtextColor),
                        ),
                      ],
                    ),
                  )
                : Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            'CURRENT TASK ASSIGNMENT',
                            style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: textColor),
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                            decoration: BoxDecoration(
                              color: accentGreen.withOpacity(0.15),
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: Text('Active Stop', style: TextStyle(color: accentGreen, fontSize: 10, fontWeight: FontWeight.bold)),
                          ),
                        ],
                      ),
                      const SizedBox(height: 10),
                      Text(
                        'Client: ${currentTask['client'] ?? currentTask['address'] ?? 'Resident'}',
                        style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: textColor),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Address: ${currentTask['address'] ?? 'Collection Point'}',
                        style: TextStyle(fontSize: 12, color: subtextColor),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Waste Type: ${currentTask['wasteType'] ?? 'Household Waste'} • ${currentTask['sacks'] ?? 1} Sacks',
                        style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: textColor),
                      ),
                      const SizedBox(height: 12),
                      Row(
                        children: [
                          Expanded(
                            child: OutlinedButton.icon(
                              onPressed: () => launchEcoRouteCall(),
                              icon: const Icon(Icons.call, size: 16),
                              label: const Text('Call Client', style: TextStyle(fontSize: 12)),
                            ),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: OutlinedButton.icon(
                              onPressed: () async {
                                try {
                                  final picker = ImagePicker();
                                  final xfile = await picker.pickImage(
                                    source: ImageSource.camera,
                                    maxWidth: 800,
                                    maxHeight: 800,
                                    imageQuality: 65,
                                  );
                                  if (xfile != null && context.mounted) {
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      const SnackBar(content: Text('Waste photo evidence captured & locked to pickup order.')),
                                    );
                                  }
                                } catch (e) {
                                  debugPrint('Rider photo evidence notice: $e');
                                }
                              },
                              icon: const Icon(Icons.camera_alt, size: 16),
                              label: const Text('Snap Photo', style: TextStyle(fontSize: 12)),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
          ),
          const SizedBox(height: 14),

          // RECORDED WEIGHT SLIDER
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: cardColor,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: AntigravityTheme.border(context)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text('Verified Collection Weight', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: textColor)),
                    Text(
                      '${_recordedWeightKg.toStringAsFixed(1)} kg',
                      style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: accentGreen),
                    ),
                  ],
                ),
                Slider(
                  value: _recordedWeightKg,
                  min: 5.0,
                  max: 150.0,
                  divisions: 29,
                  activeColor: accentGreen,
                  label: '${_recordedWeightKg.toStringAsFixed(1)} kg',
                  onChanged: (val) => setState(() => _recordedWeightKg = val),
                ),
              ],
            ),
          ),
          const SizedBox(height: 14),

          // AUTOMATED SMS INCOME PARSER PANEL
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: cardColor,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: AntigravityTheme.border(context)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(
                  'AUTOMATED SMS VERIFICATION & COMPLETE',
                  style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: textColor),
                ),
                const SizedBox(height: 8),
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: isDark ? const Color(0xFF282828) : const Color(0xFFF1F5F2),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text('Verification Code Detected:', style: TextStyle(fontSize: 11, color: subtextColor)),
                      Text(
                        _smsCodeController.text,
                        style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: accentGreen, letterSpacing: 1.2),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 14),
                FilledButton.icon(
                  onPressed: () => _handleCompleteJob(context),
                  icon: const Icon(Icons.check_circle_outline, size: 18),
                  label: const Text('ONE-TAP VERIFY & COMPLETE JOB', style: TextStyle(fontWeight: FontWeight.bold)),
                  style: FilledButton.styleFrom(
                    backgroundColor: accentGreen,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSmartphoneRouteView(
    EcoRouteState state,
    Color textColor,
    Color subtextColor,
    Color cardColor,
    Color accentGreen,
    bool isDark,
  ) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            decoration: BoxDecoration(
              color: cardColor,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: AntigravityTheme.border(context)),
            ),
            child: Row(
              children: [
                const Icon(Icons.near_me, color: Color(0xFF2E7D32), size: 18),
                const SizedBox(width: 8),
                Text(
                  'Active Route Focus: Ayivu Zone',
                  style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: textColor),
                ),
              ],
            ),
          ),
          const SizedBox(height: 14),
          Container(
            decoration: BoxDecoration(
              color: cardColor,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: AntigravityTheme.border(context)),
            ),
            child: Column(
              children: [
                ClipRRect(
                  borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
                  child: Container(
                    height: 200,
                    width: double.infinity,
                    color: isDark ? const Color(0xFF1E2822) : const Color(0xFFE2EBE5),
                    child: Stack(
                      children: [
                        Positioned.fill(
                          child: EcoCartoMap(
                            center: const LatLng(3.0275, 30.8995),
                            zoom: 14.5,
                            routePoints: OsrmRoutingService.fallbackAruaToEdiofeRoute,
                            showControls: true,
                            showLandmarks: true,
                          ),
                        ),
                        Positioned(
                          top: 12,
                          left: 12,
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                            decoration: BoxDecoration(
                              color: Colors.black87,
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: const Row(
                              children: [
                                Icon(Icons.navigation, color: Colors.greenAccent, size: 12),
                                SizedBox(width: 4),
                                Text('OSRM Live Route', style: TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.bold)),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.all(14),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('Next Stop: Muni Ward Landmark', style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: textColor)),
                          const SizedBox(height: 2),
                          Text('Distance: 1.4 km • ETA: 6 mins', style: TextStyle(fontSize: 12, color: subtextColor)),
                        ],
                      ),
                      IconButton.filled(
                        onPressed: () => launchEcoRouteCall(),
                        icon: const Icon(Icons.call, size: 18),
                        style: IconButton.styleFrom(backgroundColor: accentGreen),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 14),
          Text('SEQUENTIAL STOPS (${state.userCell.isNotEmpty ? state.userCell.toUpperCase() : "ASSIGNED ZONE"})', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: subtextColor)),
          const SizedBox(height: 8),
          Container(
            decoration: BoxDecoration(
              color: cardColor,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: AntigravityTheme.border(context)),
            ),
            child: state.riderTasks.isEmpty
                ? Padding(
                    padding: const EdgeInsets.all(16),
                    child: Center(
                      child: Text(
                        'No sequential stops in queue. New assignments will appear here.',
                        style: TextStyle(fontSize: 12, color: subtextColor),
                      ),
                    ),
                  )
                : Column(
                    children: [
                      for (int i = 0; i < state.riderTasks.length; i++) ...[
                        if (i > 0) Divider(height: 1, color: AntigravityTheme.border(context)),
                        ListTile(
                          leading: CircleAvatar(
                            backgroundColor: i == 0 ? accentGreen : (i == 1 ? const Color(0xFFF57C00) : Colors.grey),
                            radius: 14,
                            child: Text('${i + 1}', style: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.bold)),
                          ),
                          title: Text(state.riderTasks[i]['address'] ?? 'Collection Stop', style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: textColor)),
                          subtitle: Text('${state.riderTasks[i]['sacks'] ?? 1} Sacks • ${state.riderTasks[i]['wasteType'] ?? 'Waste'}', style: TextStyle(fontSize: 11, color: subtextColor)),
                          trailing: Text(
                            state.riderTasks[i]['status'] ?? (i == 0 ? 'Active' : 'Pending'),
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.bold,
                              color: i == 0 ? accentGreen : (i == 1 ? const Color(0xFFF57C00) : subtextColor),
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildSmartphoneEarningsView(
    EcoRouteState state,
    Color textColor,
    Color subtextColor,
    Color cardColor,
    Color accentGreen,
    bool isDark,
  ) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Container(
            padding: const EdgeInsets.all(18),
            decoration: BoxDecoration(
              color: cardColor,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: AntigravityTheme.border(context)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Today\'s Shift Earnings', style: TextStyle(fontSize: 12, color: subtextColor)),
                const SizedBox(height: 6),
                Text(
                  'UGX ${state.riderLedgerBalance > 0 ? state.riderLedgerBalance : 35000}',
                  style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold, color: accentGreen),
                ),
                const SizedBox(height: 14),
                Row(
                  children: [
                    Expanded(
                      child: Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: isDark ? Colors.white.withOpacity(0.05) : Colors.black.withOpacity(0.03),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('Cash in Pouch', style: TextStyle(fontSize: 11, color: subtextColor)),
                            const SizedBox(height: 4),
                            Text('UGX ${state.riderCashInPouch}', style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: textColor)),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: isDark ? Colors.white.withOpacity(0.05) : Colors.black.withOpacity(0.03),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('Shift Status', style: TextStyle(fontSize: 11, color: subtextColor)),
                            const SizedBox(height: 4),
                            Text('Active Shift', style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: accentGreen)),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                FilledButton.icon(
                  onPressed: () {
                    final balance = state.riderLedgerBalance > 0 ? state.riderLedgerBalance : 35000;
                    final amountCtrl = TextEditingController(text: '$balance');
                    final phoneCtrl = TextEditingController(text: state.userPhone.isNotEmpty ? state.userPhone : '+256772111222');
                    showDialog(
                      context: context,
                      builder: (ctx) => AlertDialog(
                        title: const Text('Request MoMo Cashout', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                        content: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text('Available Commission Balance: UGX $balance', style: const TextStyle(fontWeight: FontWeight.w600, color: Color(0xFF2E7D32))),
                            const SizedBox(height: 14),
                            TextField(
                              controller: amountCtrl,
                              keyboardType: TextInputType.number,
                              decoration: const InputDecoration(
                                labelText: 'Payout Amount (UGX)',
                                border: OutlineInputBorder(),
                              ),
                            ),
                            const SizedBox(height: 10),
                            TextField(
                              controller: phoneCtrl,
                              keyboardType: TextInputType.phone,
                              decoration: const InputDecoration(
                                labelText: 'Mobile Money Number (MTN / Airtel)',
                                border: OutlineInputBorder(),
                              ),
                            ),
                          ],
                        ),
                        actions: [
                          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
                          FilledButton(
                            onPressed: () {
                              final amt = int.tryParse(amountCtrl.text.trim()) ?? 0;
                              final phone = phoneCtrl.text.trim();
                              Navigator.pop(ctx);
                              state.riderRequestPayout(amt, phone, context);
                            },
                            style: FilledButton.styleFrom(backgroundColor: accentGreen),
                            child: const Text('Submit Cashout'),
                          ),
                        ],
                      ),
                    );
                  },
                  icon: const Icon(Icons.account_balance_wallet, size: 16),
                  label: const Text('Request MoMo Cashout'),
                  style: FilledButton.styleFrom(backgroundColor: accentGreen),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
  // =========================================================================
  // TABLET DUAL-PANE VIEWPORT (600px - 1024px) - WIREFRAME B SPECIFICATION
  // =========================================================================
  Widget _buildTabletDualPaneLayout() {
    final state = EcoRouteState.instance;
    final isDark = AntigravityTheme.isDark(context);
    final surfaceColor = AntigravityTheme.surface(context);
    final cardColor = AntigravityTheme.card(context);
    final textColor = AntigravityTheme.textPrimary(context);
    final accentGreen = AntigravityTheme.ecoAccent(context);

    return Scaffold(
      backgroundColor: surfaceColor,
      appBar: AppBar(
        backgroundColor: surfaceColor,
        elevation: 0,
        title: Row(
          children: [
            const Icon(Icons.electric_moped, color: Color(0xFF2E7D32)),
            const SizedBox(width: 8),
            Text(
              'RIDER OPERATIONS MATRIX • TRIC-18',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15, color: textColor),
            ),
          ],
        ),
        actions: [
          IconButton(
            tooltip: 'Toggle Theme',
            icon: Icon(isDark ? Icons.light_mode : Icons.dark_mode, color: textColor),
            onPressed: () => state.toggleTheme(),
          ),
          IconButton(
            tooltip: 'My Profile',
            icon: Icon(Icons.account_circle_outlined, color: textColor),
            onPressed: () => showEcoRouteProfileSheet(context),
          ),
          IconButton(
            tooltip: 'Sign Out',
            icon: const Icon(Icons.logout, color: Colors.redAccent),
            onPressed: () => state.logout(context),
          ),
        ],
      ),
      body: Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // LEFT PANEL: TASK LIST (Wireframe B)
          Container(
            width: 320,
            decoration: BoxDecoration(
              color: cardColor,
              border: Border(right: BorderSide(color: AntigravityTheme.border(context))),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Padding(
                  padding: const EdgeInsets.all(16),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Active Collection Logs',
                        style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: textColor),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: accentGreen.withOpacity(0.12),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Text(
                          '🔄 3 RECORDS CACHED',
                          style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: accentGreen),
                        ),
                      ),
                    ],
                  ),
                ),
                const Divider(height: 1),

                Expanded(
                  child: ListView(
                    padding: const EdgeInsets.all(12),
                    children: [
                      _buildTaskItemCard(0, 'Amani K.', '1.2km away', 'Confirmed', true),
                      _buildTaskItemCard(1, 'John D.', '2.4km away', 'Pending', false),
                      _buildTaskItemCard(2, 'Alice M.', '3.1km away', 'Confirmed', true),
                    ],
                  ),
                ),
              ],
            ),
          ),

          // RIGHT PANEL: NAVIGATION & VERIFICATION VIEW (Wireframe B)
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // Live Telemetry Path Routing Map Overlay
                  Container(
                    height: 220,
                    decoration: BoxDecoration(
                      color: cardColor,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: AntigravityTheme.border(context)),
                    ),
                    child: Stack(
                      alignment: Alignment.center,
                      children: [
                        ClipRRect(
                          borderRadius: BorderRadius.circular(16),
                          child: const EcoCartoMap(
                            center: LatLng(3.0275, 30.8995),
                            zoom: 14.5,
                            routePoints: OsrmRoutingService.fallbackAruaToEdiofeRoute,
                            showControls: true,
                            showLandmarks: true,
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                          decoration: BoxDecoration(
                            color: const Color(0xFF0D2618),
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: const Text(
                            '🗺️ LIVE TELEMETRY PATH ROUTING MAP OVERLAY',
                            style: TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.bold),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),

                  // ON-SITE WORKFLOW MATRIX
                  Container(
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: cardColor,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: AntigravityTheme.border(context)),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          '⚙️ ON-SITE WORKFLOW MATRIX',
                          style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: textColor),
                        ),
                        const SizedBox(height: 16),

                        // Weight Slider
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text('Extracted Weight Parameters:', style: TextStyle(fontSize: 13, color: textColor)),
                            Text('${_recordedWeightKg.toInt()} kg', style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: accentGreen)),
                          ],
                        ),
                        Slider(
                          value: _recordedWeightKg,
                          min: 5,
                          max: 120,
                          activeColor: accentGreen,
                          onChanged: (val) => setState(() => _recordedWeightKg = val),
                        ),
                        const SizedBox(height: 14),

                        // Mobile Money Code Entry
                        Text('Mobile Money Code Entry Stream:', style: TextStyle(fontSize: 13, color: textColor)),
                        const SizedBox(height: 6),
                        TextField(
                          controller: _smsCodeController,
                          decoration: InputDecoration(
                            hintText: 'e.g. Q1A2B3C4D5',
                            filled: true,
                            fillColor: isDark ? const Color(0xFF282828) : const Color(0xFFF8F9FA),
                            border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                          ),
                        ),
                        const SizedBox(height: 16),

                        // Reconcile Button
                        FilledButton.icon(
                          onPressed: () => _handleCompleteJob(context),
                          icon: const Icon(Icons.verified),
                          label: const Text('CONFIRM MATCHING TELECOM RECONCILIATION BUTTON'),
                          style: FilledButton.styleFrom(
                            backgroundColor: accentGreen,
                            padding: const EdgeInsets.symmetric(vertical: 14),
                            minimumSize: const Size(double.infinity, 48),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 12),

                  // Offline Drift Warning Tracker Active
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.amber.withOpacity(0.12),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: Colors.amber.withOpacity(0.4)),
                    ),
                    child: Row(
                      children: const [
                        Icon(Icons.warning_amber_rounded, color: Colors.amber, size: 20),
                        SizedBox(width: 10),
                        Expanded(
                          child: Text(
                            '⚠️ Local Drift Warning Tracker Active: 3 Unsynchronized Offline Logs!',
                            style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Color(0xFF8D6E63)),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTaskItemCard(int index, String name, String distance, String status, bool confirmed) {
    final isSelected = _selectedTaskIndex == index;
    final cardColor = AntigravityTheme.card(context);
    final accentGreen = AntigravityTheme.ecoAccent(context);

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      decoration: BoxDecoration(
        color: cardColor,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(
          color: isSelected ? accentGreen : AntigravityTheme.border(context),
          width: isSelected ? 1.5 : 1,
        ),
      ),
      child: ListTile(
        selected: isSelected,
        title: Text(name, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
        subtitle: Text(distance, style: const TextStyle(fontSize: 11)),
        trailing: Container(
          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
          decoration: BoxDecoration(
            color: confirmed ? Colors.green.withOpacity(0.12) : Colors.orange.withOpacity(0.12),
            borderRadius: BorderRadius.circular(4),
          ),
          child: Text(
            status,
            style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: confirmed ? Colors.green : Colors.orange),
          ),
        ),
        onTap: () => setState(() => _selectedTaskIndex = index),
      ),
    );
  }

  void _openMorningClockInSheet(BuildContext context) {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => RiderMorningClockInSheet(
        onShiftStarted: () {
          Navigator.pop(ctx);
          setState(() {});
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Shift Started! Live route broadcast to municipal dispatch.'),
              backgroundColor: Color(0xFF1E5E3A),
            ),
          );
        },
      ),
    );
  }

  void _openEveningReconciliationSheet(BuildContext context) {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => RiderEveningReconciliationModal(
        onShiftEnded: () {
          Navigator.pop(ctx);
          setState(() {});
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Shift Reconciled & Closed. Cash handover logged at Depot Desk.'),
              backgroundColor: Color(0xFF1E5E3A),
            ),
          );
        },
      ),
    );
  }

  void _openProfileSetupWizard(BuildContext context) {
    final state = EcoRouteState.instance;
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => RiderProfileSetupWizard(
        riderName: state.userName.isNotEmpty ? state.userName : 'EcoRoute Field Rider',
        assignedTricycleId: state.prefs?.getString('ecoroute_rider_tricycle_v1') ?? 'TRIC-02',
        onFinished: () {
          Navigator.pop(ctx);
          setState(() {});
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Rider Profile Updated!'),
              backgroundColor: Color(0xFF1E5E3A),
            ),
          );
        },
      ),
    );
  }

  void _handleCompleteJob(BuildContext context) {
    final state = EcoRouteState.instance;
    if (state.riderTasks.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('No active collection jobs assigned to this unit.')),
      );
      return;
    }
    final activeTask = state.riderTasks[_selectedTaskIndex.clamp(0, state.riderTasks.length - 1)];

    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => RiderPickupActionModal(
        task: activeTask,
        onCompleted: () {
          Navigator.pop(ctx);
          setState(() {
            if (_selectedTaskIndex < state.riderTasks.length - 1) {
              _selectedTaskIndex++;
            }
          });
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Stop Completed! Cash in pouch & route progress updated.'),
              backgroundColor: Color(0xFF1E5E3A),
            ),
          );
        },
      ),
    );
  }
}
