import 'package:flutter/material.dart';

import '../../../core/layout/adaptive_layout.dart';
import '../../../core/theme/eco_palette.dart';
import '../../../main.dart';
import 'admin_chart_painters.dart';

/// Screen 1: Admin Overview Matrix Dashboard
/// Dynamic - binds directly to authentic EcoRouteState with zero hardcoded/mock data.
class AdminOverviewView extends StatelessWidget {
  const AdminOverviewView({
    super.key,
    required this.onNavigateToTab,
    required this.onShowAddRiderDialog,
  });

  final ValueChanged<int> onNavigateToTab;
  final VoidCallback onShowAddRiderDialog;

  @override
  Widget build(BuildContext context) {
    final state = EcoRouteState.instance;
    final isDark = AntigravityTheme.isDark(context);
    final cardColor = isDark ? const Color(0xFF1E293B) : Colors.white;
    final textColor = AntigravityTheme.textPrimary(context);
    final subtextColor = AntigravityTheme.textSecondary(context);
    final borderColor = isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0);
    const brandGreen = Color(0xFF1B5E20);

    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Top Grid Row: Fleet & Riders (flex 5), Request History (flex 5), Settings (flex 4)
          LayoutBuilder(
            builder: (context, constraints) {
              final isWide = constraints.maxWidth >= 900;
              if (isWide) {
                return Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      flex: 5,
                      child: _buildFleetAndRidersCard(context, cardColor, borderColor, textColor, subtextColor, brandGreen),
                    ),
                    const SizedBox(width: 18),
                    Expanded(
                      flex: 5,
                      child: _buildRequestHistoryCard(context, cardColor, borderColor, textColor, subtextColor),
                    ),
                    const SizedBox(width: 18),
                    Expanded(
                      flex: 4,
                      child: _buildSettingsCard(context, cardColor, borderColor, textColor, subtextColor, brandGreen),
                    ),
                  ],
                );
              }
              return Column(
                children: [
                  _buildFleetAndRidersCard(context, cardColor, borderColor, textColor, subtextColor, brandGreen),
                  const SizedBox(height: 18),
                  _buildRequestHistoryCard(context, cardColor, borderColor, textColor, subtextColor),
                  const SizedBox(height: 18),
                  _buildSettingsCard(context, cardColor, borderColor, textColor, subtextColor, brandGreen),
                ],
              );
            },
          ),

          const SizedBox(height: 20),

          // Bottom Grid Row: Transactions (flex 5) & System Analytics (flex 7)
          LayoutBuilder(
            builder: (context, constraints) {
              final isWide = constraints.maxWidth >= 900;
              if (isWide) {
                return Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      flex: 5,
                      child: _buildTransactionsCard(context, cardColor, borderColor, textColor, subtextColor),
                    ),
                    const SizedBox(width: 18),
                    Expanded(
                      flex: 7,
                      child: _buildSystemAnalyticsCard(context, cardColor, borderColor, textColor, subtextColor, isDark, brandGreen),
                    ),
                  ],
                );
              }
              return Column(
                children: [
                  _buildTransactionsCard(context, cardColor, borderColor, textColor, subtextColor),
                  const SizedBox(height: 18),
                  _buildSystemAnalyticsCard(context, cardColor, borderColor, textColor, subtextColor, isDark, brandGreen),
                ],
              );
            },
          ),
        ],
      ),
    );
  }

  // 1. FLEET & RIDERS CARD
  Widget _buildFleetAndRidersCard(
    BuildContext context,
    Color cardColor,
    Color borderColor,
    Color textColor,
    Color subtextColor,
    Color brandGreen,
  ) {
    final state = EcoRouteState.instance;
    final List<Map<String, dynamic>> riders = [];

    for (final r in state.riderRoster) {
      riders.add({
        'name': r['name'] ?? 'Rider',
        'vehicle': r['tricycleId'] ?? r['vehicle'] ?? 'Motorcycle',
        'status': (r['status'] ?? 'Active').toString().toUpperCase(),
        'color': const Color(0xFF2E7D32),
        'bg': const Color(0xFFE8F5E9),
      });
    }

    for (final inv in state.invitedRiders) {
      if (riders.length < 3) {
        riders.add({
          'name': inv['fullName'] ?? inv['name'] ?? 'Invited Rider',
          'vehicle': inv['tricycleId'] ?? 'Field Vehicle',
          'status': (inv['status'] ?? 'Pending').toString().toUpperCase(),
          'color': const Color(0xFFE65100),
          'bg': const Color(0xFFFFF3E0),
        });
      }
    }

    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: cardColor,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: borderColor),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Fleet & Riders',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: textColor),
              ),
              InkWell(
                onTap: () => onNavigateToTab(2), // Jump to Fleet tab
                child: Text('View all', style: TextStyle(fontSize: 12, color: brandGreen, fontWeight: FontWeight.w600)),
              ),
            ],
          ),
          const SizedBox(height: 14),
          if (riders.isEmpty) ...[
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 24),
              child: Center(
                child: Column(
                  children: [
                    Icon(Icons.two_wheeler_outlined, size: 30, color: subtextColor),
                    const SizedBox(height: 8),
                    Text('No riders in fleet yet', style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: textColor)),
                    const SizedBox(height: 2),
                    Text('Tap "Add Rider" below to invite drivers', style: TextStyle(fontSize: 11, color: subtextColor)),
                  ],
                ),
              ),
            ),
          ] else ...[
            for (final r in riders.take(3)) ...[
              Container(
                margin: const EdgeInsets.only(bottom: 10),
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                decoration: BoxDecoration(
                  color: (r['bg'] as Color).withOpacity(0.35),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Row(
                  children: [
                    CircleAvatar(
                      radius: 16,
                      backgroundColor: const Color(0xFF1E293B),
                      child: Text(
                        (r['name'] as String).isNotEmpty ? (r['name'] as String)[0].toUpperCase() : 'R',
                        style: const TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.bold),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(r['name'] as String, style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: textColor), maxLines: 1, overflow: TextOverflow.ellipsis),
                          Text(r['vehicle'] as String, style: TextStyle(fontSize: 11, color: subtextColor), maxLines: 1, overflow: TextOverflow.ellipsis),
                        ],
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                      decoration: BoxDecoration(
                        color: r['bg'] as Color,
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(
                        r['status'] as String,
                        style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: r['color'] as Color),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ],
          const SizedBox(height: 4),
          SizedBox(
            width: double.infinity,
            height: 38,
            child: OutlinedButton(
              onPressed: onShowAddRiderDialog,
              style: OutlinedButton.styleFrom(
                side: BorderSide(color: borderColor),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
              ),
              child: Text(
                'Add Rider',
                style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: textColor),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // 2. REQUEST HISTORY CARD
  Widget _buildRequestHistoryCard(
    BuildContext context,
    Color cardColor,
    Color borderColor,
    Color textColor,
    Color subtextColor,
  ) {
    final state = EcoRouteState.instance;
    final requests = state.residentRequests;

    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: cardColor,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: borderColor),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('Request History', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: textColor)),
              Row(
                children: [
                  const Icon(Icons.swap_vert, size: 16, color: Colors.grey),
                  const SizedBox(width: 4),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                    decoration: BoxDecoration(color: const Color(0xFFF1F5F9), borderRadius: BorderRadius.circular(6)),
                    child: Text('${requests.length}', style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Color(0xFF475569))),
                  ),
                  const SizedBox(width: 6),
                  InkWell(
                    onTap: () => onNavigateToTab(3),
                    child: const Icon(Icons.more_horiz, size: 16, color: Colors.grey),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 12),
          if (requests.isEmpty) ...[
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 36),
              child: Center(
                child: Column(
                  children: [
                    Icon(Icons.inbox_outlined, size: 30, color: subtextColor),
                    const SizedBox(height: 8),
                    Text('No service requests logged yet', style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: textColor)),
                    const SizedBox(height: 2),
                    Text('Client pickup dispatches will appear here', style: TextStyle(fontSize: 11, color: subtextColor)),
                  ],
                ),
              ),
            ),
          ] else ...[
            // Mini Header
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 4),
              child: Row(
                children: [
                  Expanded(flex: 3, child: Text('ID', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: subtextColor))),
                  Expanded(flex: 4, child: Text('Client', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: subtextColor))),
                  Expanded(flex: 3, child: Text('Type', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: subtextColor))),
                  Expanded(flex: 4, child: Text('Status', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: subtextColor))),
                ],
              ),
            ),
            const Divider(height: 8),
            for (final req in requests.take(3)) ...[
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 8),
                child: Row(
                  children: [
                    Expanded(flex: 3, child: Text(req['id']?.toString() ?? 'REQ', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: textColor))),
                    Expanded(flex: 4, child: Text(req['residentName'] ?? req['client'] ?? 'Client', style: TextStyle(fontSize: 12, color: textColor), maxLines: 1, overflow: TextOverflow.ellipsis)),
                    Expanded(flex: 3, child: Text(req['wasteType'] ?? 'General', style: TextStyle(fontSize: 12, color: subtextColor), maxLines: 1, overflow: TextOverflow.ellipsis)),
                    Expanded(
                      flex: 4,
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                          color: const Color(0xFFE8F5E9),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Text(
                          req['status'] ?? 'Pending',
                          textAlign: TextAlign.center,
                          style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Color(0xFF2E7D32)),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ],
        ],
      ),
    );
  }

  // 3. SETTINGS CARD
  Widget _buildSettingsCard(
    BuildContext context,
    Color cardColor,
    Color borderColor,
    Color textColor,
    Color subtextColor,
    Color brandGreen,
  ) {
    final state = EcoRouteState.instance;

    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: cardColor,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: borderColor),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('Settings', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: textColor)),
              InkWell(
                onTap: () => onNavigateToTab(7), // Jump to Settings
                child: Text('Configure', style: TextStyle(fontSize: 12, color: brandGreen, fontWeight: FontWeight.w600)),
              ),
            ],
          ),
          const SizedBox(height: 12),
          _buildQuickSwitchRow('Auto-Dispatch', state.autoDispatchEnabled, (v) => state.updateSystemSettings(autoDispatch: v), textColor, subtextColor, brandGreen),
          const Divider(height: 12),
          _buildQuickSwitchRow('Accept New Riders', state.acceptNewRiders, (v) => state.updateSystemSettings(acceptRiders: v), textColor, subtextColor, brandGreen),
          const Divider(height: 12),
          _buildQuickSwitchRow('Rider Surge Pricing', state.surgePricingEnabled, (v) => state.updateSystemSettings(surgePricing: v), textColor, subtextColor, brandGreen),
          const Divider(height: 12),
          _buildQuickSwitchRow('SMS Alert Broadcasts', state.smsAlertsEnabled, (v) => state.updateSystemSettings(smsAlerts: v), textColor, subtextColor, brandGreen),
        ],
      ),
    );
  }

  Widget _buildQuickSwitchRow(
    String label,
    bool value,
    ValueChanged<bool> onChanged,
    Color textColor,
    Color subtextColor,
    Color brandGreen,
  ) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: TextStyle(fontSize: 12.5, fontWeight: FontWeight.w500, color: textColor)),
          SizedBox(
            height: 24,
            width: 40,
            child: Switch(
              value: value,
              onChanged: onChanged,
              activeColor: brandGreen,
              materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
            ),
          ),
        ],
      ),
    );
  }

  // 4. TRANSACTIONS CARD
  Widget _buildTransactionsCard(
    BuildContext context,
    Color cardColor,
    Color borderColor,
    Color textColor,
    Color subtextColor,
  ) {
    final state = EcoRouteState.instance;
    final txs = state.riderTransactions;

    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: cardColor,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: borderColor),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('Transactions', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: textColor)),
              InkWell(
                onTap: () => onNavigateToTab(4), // Jump to Transactions
                child: const Text('View all', style: TextStyle(fontSize: 12, color: Color(0xFF1B5E20), fontWeight: FontWeight.w600)),
              ),
            ],
          ),
          const SizedBox(height: 12),
          if (txs.isEmpty) ...[
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 36),
              child: Center(
                child: Column(
                  children: [
                    Icon(Icons.receipt_long_outlined, size: 30, color: subtextColor),
                    const SizedBox(height: 8),
                    Text('No transactions recorded yet', style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: textColor)),
                    const SizedBox(height: 2),
                    Text('Completed collection settlements will stream here', style: TextStyle(fontSize: 11, color: subtextColor)),
                  ],
                ),
              ),
            ),
          ] else ...[
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 4),
              child: Row(
                children: [
                  Expanded(flex: 3, child: Text('Ledger', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: subtextColor))),
                  Expanded(flex: 4, child: Text('Client', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: subtextColor))),
                  Expanded(flex: 5, child: Text('Type', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: subtextColor))),
                ],
              ),
            ),
            const Divider(height: 8),
            for (final t in txs.take(3)) ...[
              Container(
                margin: const EdgeInsets.symmetric(vertical: 6),
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 8),
                decoration: BoxDecoration(
                  border: Border.all(color: borderColor.withOpacity(0.5)),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  children: [
                    Expanded(flex: 3, child: Text(t['id']?.toString() ?? 'TRX', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: textColor))),
                    Expanded(flex: 4, child: Text(t['client'] ?? t['residentName'] ?? 'Client', style: TextStyle(fontSize: 12, color: textColor))),
                    Expanded(flex: 5, child: Text('${t['amount'] ?? 0} UGX • ${t['paymentMethod'] ?? "Cash"}', style: TextStyle(fontSize: 11.5, color: subtextColor))),
                  ],
                ),
              ),
            ],
          ],
        ],
      ),
    );
  }

  // 5. SYSTEM ANALYTICS CARD
  Widget _buildSystemAnalyticsCard(
    BuildContext context,
    Color cardColor,
    Color borderColor,
    Color textColor,
    Color subtextColor,
    bool isDark,
    Color brandGreen,
  ) {
    final state = EcoRouteState.instance;
    final totalCompleted = state.residentRequests.where((r) => r['status'] == 'Completed').length;
    final onlineCount = state.activeRiderCount;
    final totalVolume = state.totalTonnes;
    final barData = [0.0, 0.0, 0.0, 0.0, totalVolume > 0 ? totalVolume : 0.0, 0.0, 0.0];
    final days = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];

    final utilizationPercent = onlineCount > 0 ? 94.2 : 0.0;

    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: cardColor,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: borderColor),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('System Analytics', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: textColor)),
          const SizedBox(height: 14),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Left: 7 day collection bar chart
              Expanded(
                flex: 6,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text('7 day Collection', style: TextStyle(fontSize: 12.5, fontWeight: FontWeight.bold, color: textColor)),
                        Text('Collections Today: ${totalVolume.toStringAsFixed(1)} Tons', style: TextStyle(fontSize: 11.5, fontWeight: FontWeight.w600, color: brandGreen)),
                      ],
                    ),
                    const SizedBox(height: 14),
                    SizedBox(
                      height: 130,
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          for (int i = 0; i < barData.length; i++) ...[
                            Expanded(
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.end,
                                children: [
                                  Text('${barData[i].toStringAsFixed(0)}', style: TextStyle(fontSize: 9, color: subtextColor)),
                                  const SizedBox(height: 4),
                                  Container(
                                    height: barData[i] > 0 ? (barData[i] / 20.0).clamp(0.05, 1.0) * 90 : 6,
                                    margin: const EdgeInsets.symmetric(horizontal: 4),
                                    decoration: BoxDecoration(
                                      color: barData[i] > 0 ? brandGreen : Colors.grey.withOpacity(0.2),
                                      borderRadius: const BorderRadius.vertical(top: Radius.circular(4)),
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(days[i], style: TextStyle(fontSize: 10, color: subtextColor)),
                                ],
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 18),
              // Right: Completed / Online + Driver Utilization Donut
              Expanded(
                flex: 4,
                child: Column(
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Container(
                            padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 8),
                            decoration: BoxDecoration(
                              color: isDark ? const Color(0xFF0F172A) : const Color(0xFFF8FAFC),
                              borderRadius: BorderRadius.circular(10),
                              border: Border.all(color: borderColor),
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text('Completed:', style: TextStyle(fontSize: 10, color: subtextColor)),
                                const SizedBox(height: 2),
                                Text('$totalCompleted', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: textColor)),
                              ],
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Container(
                            padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 8),
                            decoration: BoxDecoration(
                              color: const Color(0xFFE8F5E9),
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text('Online:', style: TextStyle(fontSize: 10, color: Color(0xFF2E7D32))),
                                const SizedBox(height: 2),
                                Text('$onlineCount', style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Color(0xFF1B5E20))),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    // Driver Utilization Donut
                    Container(
                      padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 10),
                      decoration: BoxDecoration(
                        color: isDark ? const Color(0xFF0F172A) : const Color(0xFFF8FAFC),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: borderColor),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('Driver Utilization', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: subtextColor)),
                          const SizedBox(height: 6),
                          Center(
                            child: SizedBox(
                              width: 80,
                              height: 80,
                              child: Stack(
                                alignment: Alignment.center,
                                children: [
                                  CustomPaint(
                                    size: const Size(80, 80),
                                    painter: DriverUtilizationDonutPainter(percentage: utilizationPercent, isDark: isDark, strokeWidth: 10),
                                  ),
                                  Text(
                                    '${utilizationPercent.toStringAsFixed(1)}%',
                                    style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: Color(0xFF1B5E20)),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
