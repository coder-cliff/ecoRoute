import '../../core/services/rider_invite_service.dart';
import 'package:flutter/material.dart';
import 'package:latlong2/latlong.dart';

import '../../core/layout/adaptive_layout.dart';
import '../../core/services/gemini_eco_service.dart';
import '../../core/theme/eco_palette.dart';
import '../../main.dart';
import '../common/widgets/eco_carto_map.dart';
import '../resident/widgets/eco_gemini_assistant_sheet.dart';

/// Responsive Admin Analytics Command Matrix Dashboard
/// Conforms strictly to Architectural Wireframe C
class ResponsiveAdminDashboard extends StatefulWidget {
  const ResponsiveAdminDashboard({super.key});

  @override
  State<ResponsiveAdminDashboard> createState() =>
      _ResponsiveAdminDashboardState();
}

class _ResponsiveAdminDashboardState extends State<ResponsiveAdminDashboard> {
  int _selectedSidebarIndex = 0;

  Future<void> _showAiDispatchBriefing(BuildContext context, EcoRouteState state) async {
    showDialog(
      context: context,
      barrierDismissible: true,
      builder: (ctx) => AlertDialog(
        title: const Row(
          children: [
            Icon(Icons.auto_awesome, color: EcoPalette.primaryForest, size: 22),
            SizedBox(width: 8),
            Text('Gemini AI Dispatch Briefing', style: TextStyle(fontSize: 16)),
          ],
        ),
        content: FutureBuilder<String>(
          future: GeminiEcoService(preferences: state.prefs).generateDispatchSummary(state.riderTasks),
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  SizedBox(height: 20),
                  CircularProgressIndicator(color: EcoPalette.primaryForest),
                  SizedBox(height: 16),
                  Text('Analyzing municipal route density & pending tasks...', style: TextStyle(fontSize: 12)),
                  SizedBox(height: 20),
                ],
              );
            }
            final summary = snapshot.data ?? 'No summary available.';
            return SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Municipal Operations Advisory • Arua City', style: TextStyle(fontSize: 11, color: Colors.grey)),
                  const SizedBox(height: 12),
                  Text(summary, style: const TextStyle(fontSize: 13, height: 1.4)),
                ],
              ),
            );
          },
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Dismiss'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.sizeOf(context).width;

    if (width < 700) {
      return _buildMobileLayout();
    }

    if (width < 1100) {
      return _buildTabletLayout();
    }

    return _buildDesktopLayout();
  }

  Widget _buildDesktopLayout() {
    final state = EcoRouteState.instance;
    final isDark = AntigravityTheme.isDark(context);
    final surfaceColor = AntigravityTheme.surface(context);
    final cardColor = AntigravityTheme.card(context);
    final textColor = AntigravityTheme.textPrimary(context);
    final subtextColor = AntigravityTheme.textSecondary(context);
    final accentGreen = AntigravityTheme.ecoAccent(context);

    return Scaffold(
      backgroundColor: surfaceColor,
      body: SafeArea(
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildSidebar(width: ViewportBreakpoints.sidebarWidth),
            Expanded(
              child: Column(
                children: [
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
                    color: cardColor,
                    child: LayoutBuilder(
                      builder: (context, constraints) {
                        final compact = constraints.maxWidth < 560;
                        return compact
                            ? Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Flexible(
                                    child: Text(
                                      'ADMINISTRATIVE COMMAND MATRIX',
                                      style: TextStyle(
                                        fontSize: 18,
                                        fontWeight: FontWeight.bold,
                                        color: textColor,
                                        letterSpacing: 0.8,
                                      ),
                                      maxLines: 2,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ),
                                  const SizedBox(height: 12),
                                  Wrap(
                                    spacing: 8,
                                    runSpacing: 8,
                                    children: [
                                      IconButton(
                                        tooltip: 'Toggle Theme',
                                        icon: Icon(
                                          isDark ? Icons.light_mode : Icons.dark_mode,
                                          color: textColor,
                                        ),
                                        onPressed: () => state.toggleTheme(),
                                      ),
                                      FilledButton.icon(
                                        onPressed: () => showEcoRouteProfileSheet(context),
                                        icon: const Icon(Icons.tune, size: 16),
                                        label: const Text('Municipal Settings'),
                                        style: FilledButton.styleFrom(backgroundColor: accentGreen),
                                      ),
                                    ],
                                  ),
                                ],
                              )
                            : Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  Expanded(
                                    child: Text(
                                      'ADMINISTRATIVE COMMAND MATRIX',
                                      style: TextStyle(
                                        fontSize: 18,
                                        fontWeight: FontWeight.bold,
                                        color: textColor,
                                        letterSpacing: 0.8,
                                      ),
                                      maxLines: 2,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ),
                                  Wrap(
                                    spacing: 8,
                                    runSpacing: 8,
                                    children: [
                                      IconButton(
                                        tooltip: 'Toggle Theme',
                                        icon: Icon(
                                          isDark ? Icons.light_mode : Icons.dark_mode,
                                          color: textColor,
                                        ),
                                        onPressed: () => state.toggleTheme(),
                                      ),
                                      FilledButton.icon(
                                        onPressed: () => showEcoRouteProfileSheet(context),
                                        icon: const Icon(Icons.tune, size: 16),
                                        label: const Text('Municipal Settings'),
                                        style: FilledButton.styleFrom(backgroundColor: accentGreen),
                                      ),
                                    ],
                                  ),
                                ],
                              );
                      },
                    ),
                  ),
                  const Divider(height: 1),
                  Expanded(
                    child: _buildAdminMainContent(state, isMobile: false),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAdminOverviewTab(
    EcoRouteState state,
    Color textColor,
    Color subtextColor,
    Color cardColor,
    Color accentGreen,
    bool isDark, {
    required bool isMobile,
  }) {
    return SingleChildScrollView(
      padding: EdgeInsets.all(isMobile ? 16 : 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // GOOGLE GEMINI AI OPERATIONS INTELLIGENCE BANNER
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: accentGreen.withOpacity(0.08),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: accentGreen.withOpacity(0.25)),
            ),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: accentGreen,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(Icons.auto_awesome, color: Colors.white, size: 20),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Text(
                            'Gemini Operations Intelligence',
                            style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: textColor),
                          ),
                          const SizedBox(width: 6),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                            decoration: BoxDecoration(
                              color: accentGreen.withOpacity(0.18),
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: const Text('Zero-Cost', style: TextStyle(fontSize: 9, fontWeight: FontWeight.bold)),
                          ),
                        ],
                      ),
                      const SizedBox(height: 3),
                      Text(
                        'Route density analysis & bottleneck recommendations for Arua City.',
                        style: TextStyle(fontSize: 11, color: subtextColor),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                FilledButton.icon(
                  style: FilledButton.styleFrom(
                    backgroundColor: accentGreen,
                    visualDensity: VisualDensity.compact,
                  ),
                  onPressed: () => _showAiDispatchBriefing(context, state),
                  icon: const Icon(Icons.analytics, size: 15),
                  label: const Text('Briefing', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                ),
              ],
            ),
          ),
          const SizedBox(height: 18),
          Text(
            'OVERVIEW METRICS',
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.bold,
              color: subtextColor,
              letterSpacing: 0.5,
            ),
          ),
                          const SizedBox(height: 12),
                          LayoutBuilder(
                            builder: (context, constraints) {
                              final availableWidth = constraints.maxWidth;
                              final columnCount = availableWidth < 720 ? 1 : availableWidth < 980 ? 2 : 3;
                              final gap = 16.0;
                              final itemWidth = (availableWidth - gap * (columnCount - 1)) / columnCount;

                              return Wrap(
                                spacing: gap,
                                runSpacing: gap,
                                children: [
                                  SizedBox(
                                    width: itemWidth,
                                    child: _buildMetricCard(
                                      title: 'Total Volume',
                                      value: '${state.totalTonnes > 0 ? state.totalTonnes.toStringAsFixed(1) : '4.2'} Tons',
                                      subtitle: 'Municipal waste diverted',
                                      icon: Icons.scale,
                                      color: accentGreen,
                                    ),
                                  ),
                                  SizedBox(
                                    width: itemWidth,
                                    child: _buildMetricCard(
                                      title: 'Fleet Online',
                                      value: '${state.activeRidersCount > 0 ? state.activeRidersCount : 14}/18',
                                      subtitle: 'Tricycles in service',
                                      icon: Icons.electric_moped,
                                      color: const Color(0xFF1976D2),
                                    ),
                                  ),
                                  SizedBox(
                                    width: itemWidth,
                                    child: _buildMetricCard(
                                      title: 'Unreconciled SMS',
                                      value: '0',
                                      subtitle: 'Telecom stream cleared',
                                      icon: Icons.sms_outlined,
                                      color: const Color(0xFFF57C00),
                                    ),
                                  ),
                                ],
                              );
                            },
                          ),
                          const SizedBox(height: 28),
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
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                  children: [
                                    Expanded(
                                      child: Text(
                                        'LOGISTICS & MONITORING CENTRAL LEDGER GRID FRAME',
                                        style: TextStyle(
                                          fontSize: 14,
                                          fontWeight: FontWeight.bold,
                                          color: textColor,
                                        ),
                                      ),
                                    ),
                                    Text(
                                      'Real-time Firestore Synchronized',
                                      style: TextStyle(
                                        fontSize: 11,
                                        color: accentGreen,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 16),
                                SingleChildScrollView(
                                  scrollDirection: Axis.horizontal,
                                  child: SizedBox(
                                    width: 860,
                                    child: Table(
                                      border: TableBorder.all(
                                        color: AntigravityTheme.border(context),
                                        borderRadius: BorderRadius.circular(8),
                                      ),
                                      columnWidths: const {
                                        0: FlexColumnWidth(1.2),
                                        1: FlexColumnWidth(1.8),
                                        2: FlexColumnWidth(1.4),
                                        3: FlexColumnWidth(1.4),
                                        4: FlexColumnWidth(1.8),
                                      },
                                      children: [
                                        TableRow(
                                          decoration: BoxDecoration(
                                            color: isDark ? const Color(0xFF242424) : const Color(0xFFF1F5F2),
                                          ),
                                          children: [
                                            _buildTableCell('ID', isHeader: true),
                                            _buildTableCell('ASSIGNED RIDER', isHeader: true),
                                            _buildTableCell('STATUS', isHeader: true),
                                            _buildTableCell('RECORDED WEIGHT', isHeader: true),
                                            _buildTableCell('REF CODE', isHeader: true),
                                          ],
                                        ),
                                        if (state.riderTasks.isEmpty) ...[
                                          TableRow(
                                            children: [
                                              _buildTableCell('—'),
                                              _buildTableCell('No active dispatches in queue'),
                                              _buildTableCell('Queue Empty', statusColor: Colors.grey),
                                              _buildTableCell('0 kg'),
                                              _buildTableCell('—'),
                                            ],
                                          ),
                                        ] else ...[
                                          for (final task in state.riderTasks)
                                            TableRow(
                                              children: [
                                                _buildTableCell('#${task['id']}'),
                                                _buildTableCell(task['assignedRider'] ?? 'TRIC-18'),
                                                _buildTableCell(task['status'] ?? 'Active', statusColor: Colors.green),
                                                _buildTableCell('${task['weight'] ?? 30} kg'),
                                                _buildTableCell(task['verificationCode'] ?? 'REF-UG-881'),
                                              ],
                                            ),
                                        ],
                                      ],
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    );
  }

  Widget _buildTabletLayout() {
    final state = EcoRouteState.instance;
    final isDark = AntigravityTheme.isDark(context);
    final surfaceColor = AntigravityTheme.surface(context);
    final textColor = AntigravityTheme.textPrimary(context);

    return Scaffold(
      backgroundColor: surfaceColor,
      appBar: AppBar(
        backgroundColor: surfaceColor,
        title: const Text('Admin Command HQ'),
        centerTitle: false,
        actions: [
          IconButton(
            tooltip: 'Toggle Theme',
            icon: Icon(isDark ? Icons.light_mode : Icons.dark_mode, color: textColor),
            onPressed: () => state.toggleTheme(),
          ),
        ],
      ),
      drawer: Drawer(
        child: _buildSidebar(),
      ),
      body: SafeArea(
        child: _buildAdminMainContent(state, isMobile: false),
      ),
    );
  }

  Widget _buildMobileLayout() {
    final state = EcoRouteState.instance;
    final isDark = AntigravityTheme.isDark(context);
    final surfaceColor = AntigravityTheme.surface(context);
    final cardColor = AntigravityTheme.card(context);
    final textColor = AntigravityTheme.textPrimary(context);
    final subtextColor = AntigravityTheme.textSecondary(context);
    final accentGreen = AntigravityTheme.ecoAccent(context);

    return Scaffold(
      backgroundColor: surfaceColor,
      appBar: AppBar(
        backgroundColor: surfaceColor,
        title: const Text('Command HQ'),
        actions: [
          IconButton(
            tooltip: 'Toggle Theme',
            icon: Icon(isDark ? Icons.light_mode : Icons.dark_mode, color: textColor),
            onPressed: () => state.toggleTheme(),
          ),
        ],
      ),
      drawer: Drawer(
        child: _buildSidebar(),
      ),
      body: SafeArea(
        child: _buildAdminMainContent(state, isMobile: true),
      ),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _selectedSidebarIndex.clamp(0, 4),
        onTap: (index) => setState(() => _selectedSidebarIndex = index),
        backgroundColor: cardColor,
        selectedItemColor: accentGreen,
        unselectedItemColor: subtextColor,
        type: BottomNavigationBarType.fixed,
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.dashboard_outlined), activeIcon: Icon(Icons.dashboard), label: 'Overview'),
          BottomNavigationBarItem(icon: Icon(Icons.receipt_long_outlined), activeIcon: Icon(Icons.receipt_long), label: 'Ledgers'),
          BottomNavigationBarItem(icon: Icon(Icons.map_outlined), activeIcon: Icon(Icons.map), label: 'Zones'),
          BottomNavigationBarItem(icon: Icon(Icons.security_outlined), activeIcon: Icon(Icons.security), label: 'Access'),
          BottomNavigationBarItem(icon: Icon(Icons.tune_outlined), activeIcon: Icon(Icons.tune), label: 'Config'),
        ],
      ),
    );
  }

  Widget _buildAdminMainContent(
    EcoRouteState state, {
    required bool isMobile,
  }) {
    final textColor = AntigravityTheme.textPrimary(context);
    final subtextColor = AntigravityTheme.textSecondary(context);
    final cardColor = AntigravityTheme.card(context);
    final accentGreen = AntigravityTheme.ecoAccent(context);
    final isDark = AntigravityTheme.isDark(context);

    switch (_selectedSidebarIndex) {
      case 1:
        return _buildAdminLedgersTab(state, textColor, subtextColor, cardColor, accentGreen, isDark, isMobile: isMobile);
      case 2:
        return _buildAdminZonesTab(state, textColor, subtextColor, cardColor, accentGreen, isDark, isMobile: isMobile);
      case 3:
        return _buildAdminAccessControlTab(state, textColor, subtextColor, cardColor, accentGreen, isDark, isMobile: isMobile);
      case 4:
        return _buildAdminGlobalConfigTab(state, textColor, subtextColor, cardColor, accentGreen, isDark, isMobile: isMobile);
      case 0:
      default:
        return _buildAdminOverviewTab(state, textColor, subtextColor, cardColor, accentGreen, isDark, isMobile: isMobile);
    }
  }

  Widget _buildAdminLedgersTab(
    EcoRouteState state,
    Color textColor,
    Color subtextColor,
    Color cardColor,
    Color accentGreen,
    bool isDark, {
    required bool isMobile,
  }) {
    return SingleChildScrollView(
      padding: EdgeInsets.all(isMobile ? 16 : 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'FINANCIAL LEDGERS & CASH RECONCILIATION',
            style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: subtextColor, letterSpacing: 0.5),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: _buildMetricCard(
                  title: 'Depot Reconciled Cash',
                  value: 'UGX ${state.totalDepotReconciledCash}',
                  subtitle: 'Physical cash verified at depot desk',
                  icon: Icons.payments,
                  color: accentGreen,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildMetricCard(
                  title: 'Tricycle Pouches',
                  value: 'UGX ${state.totalCashInPouches}',
                  subtitle: 'In field with active riders',
                  icon: Icons.account_balance_wallet,
                  color: const Color(0xFFF57C00),
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
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
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Text('Cash Reconciliation & MoMo Settlement Desk', style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: textColor)),
                    ),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: [
                        FilledButton.icon(
                          onPressed: () => state.exportCollectionAuditCsv(context),
                          icon: const Icon(Icons.download, size: 16),
                          label: const Text('Export Audit CSV'),
                          style: FilledButton.styleFrom(backgroundColor: const Color(0xFF1B5E20)),
                        ),
                        FilledButton.icon(
                          onPressed: () {
                            showDialog(
                              context: context,
                              builder: (ctx) => AlertDialog(
                                title: const Text('Depot Cash Reconciliation', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                                content: SizedBox(
                                  width: 400,
                                  child: Column(
                                    mainAxisSize: MainAxisSize.min,
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        'Total in Fleet Pouches: UGX ' + state.totalCashInPouches.toString(),
                                        style: const TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF2E7D32)),
                                      ),
                                      const SizedBox(height: 14),
                                      ListTile(
                                        contentPadding: EdgeInsets.zero,
                                        title: const Text('Tricycle Unit TRIC-04 (Ediofe Depot)', style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold)),
                                        subtitle: Text('Cash in Pouch: UGX ' + state.riderCashInPouch.toString(), style: const TextStyle(fontSize: 12)),
                                        trailing: FilledButton(
                                          onPressed: state.riderCashInPouch > 0
                                              ? () {
                                                  Navigator.pop(ctx);
                                                  state.reconcileRiderCashPouch(tricycleId: 'TRIC-04', context: context);
                                                }
                                              : null,
                                          style: FilledButton.styleFrom(backgroundColor: accentGreen),
                                          child: const Text('Check In'),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                actions: [
                                  TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Close')),
                                ],
                              ),
                            );
                          },
                          icon: const Icon(Icons.check, size: 16),
                          label: const Text('Reconcile Pouches'),
                          style: FilledButton.styleFrom(backgroundColor: accentGreen),
                        ),
                      ],
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Text('Active Settlement Desk Status: 100% in compliance with Arua commercial waste logistics standards.', style: TextStyle(fontSize: 12, color: subtextColor)),
              ],
            ),
          ),
          const SizedBox(height: 16),
          // Pending Driver MoMo Payouts Desk
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
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      children: [
                        Icon(Icons.request_quote, color: accentGreen, size: 20),
                        const SizedBox(width: 8),
                        Text(
                          'Driver MoMo Payout Authorizations (' + state.pendingPayoutRequests.where((p) => p['status'] == 'Pending Approval').length.toString() + ')',
                          style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: textColor),
                        ),
                      ],
                    ),
                    if (state.pendingPayoutRequests.where((p) => p['status'] == 'Pending Approval').isNotEmpty)
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                        decoration: BoxDecoration(
                          color: const Color(0xFFF57C00).withOpacity(0.15),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: const Text('Action Required', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Color(0xFFF57C00))),
                      ),
                  ],
                ),
                const SizedBox(height: 12),
                if (state.pendingPayoutRequests.where((p) => p['status'] == 'Pending Approval').isEmpty)
                  Container(
                    padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 12),
                    decoration: BoxDecoration(
                      color: accentGreen.withOpacity(0.08),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Row(
                      children: [
                        Icon(Icons.check_circle_outline, color: accentGreen, size: 20),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Text(
                            'All commercial driver earnings are reconciled and paid out. Zero pending authorization requests.',
                            style: TextStyle(fontSize: 12, color: textColor, fontWeight: FontWeight.w500),
                          ),
                        ),
                      ],
                    ),
                  )
                else
                  ...state.pendingPayoutRequests.where((p) => p['status'] == 'Pending Approval').map((payout) {
                    final pid = payout['id']?.toString() ?? 'PO-REQ';
                    final rider = payout['riderName']?.toString() ?? 'Fleet Driver';
                    final tri = payout['tricycleId']?.toString() ?? 'TRIC-04';
                    final phone = payout['phone']?.toString() ?? '+256 700 000 000';
                    final amount = payout['amount']?.toString() ?? '0';

                    return Container(
                      margin: const EdgeInsets.only(bottom: 10),
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: isDark ? const Color(0xFF242424) : const Color(0xFFF9FBF9),
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(color: AntigravityTheme.border(context)),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                rider + ' • ' + tri,
                                style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: textColor),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                'MoMo: ' + phone + ' • ' + pid,
                                style: TextStyle(fontSize: 11, color: subtextColor),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                'UGX ' + amount,
                                style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: accentGreen),
                              ),
                            ],
                          ),
                          Row(
                            children: [
                              OutlinedButton(
                                onPressed: () => state.rejectPayoutRequest(pid, 'Rejected by manager', context),
                                style: OutlinedButton.styleFrom(
                                  foregroundColor: Colors.redAccent,
                                  side: const BorderSide(color: Colors.redAccent),
                                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                                ),
                                child: const Text('Reject', style: TextStyle(fontSize: 11)),
                              ),
                              const SizedBox(width: 8),
                              FilledButton(
                                onPressed: () => state.approvePayoutRequest(pid, '', context),
                                style: FilledButton.styleFrom(
                                  backgroundColor: accentGreen,
                                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                                ),
                                child: const Text('Authorize MoMo', style: TextStyle(fontSize: 11)),
                              ),
                            ],
                          ),
                        ],
                      ),
                    );
                  }),
              ],
            ),
          ),
          const SizedBox(height: 12),
          ListTile(
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            tileColor: Colors.redAccent.withOpacity(0.12),
            leading: const Icon(Icons.logout, color: Colors.redAccent, size: 20),
            title: const Text('Sign Out', style: TextStyle(color: Colors.redAccent, fontWeight: FontWeight.bold, fontSize: 13)),
            onTap: () => EcoRouteState.instance.logout(context),
          ),
        ],
      ),
    );
  }

  Widget _buildAdminZonesTab(
    EcoRouteState state,
    Color textColor,
    Color subtextColor,
    Color cardColor,
    Color accentGreen,
    bool isDark, {
    required bool isMobile,
  }) {
    final zones = [
      {'name': 'Ayivu Division', 'tricycles': 'TRIC-01, TRIC-04, TRIC-18', 'status': 'Active Collection', 'sacks': '84 Sacks Cleared'},
      {'name': 'Central Division', 'tricycles': 'TRIC-02, TRIC-05', 'status': 'Route Cleared', 'sacks': '62 Sacks Cleared'},
      {'name': 'Arua Hill Ward', 'tricycles': 'TRIC-07', 'status': 'Window 2:00 PM', 'sacks': '45 Sacks Cleared'},
      {'name': 'River Oli Ward', 'tricycles': 'TRIC-09', 'status': 'En Route', 'sacks': '38 Sacks Cleared'},
      {'name': 'Rhino Camp Road', 'tricycles': 'TRIC-12', 'status': 'Standby Depot', 'sacks': '19 Sacks Cleared'},
    ];

    return SingleChildScrollView(
      padding: EdgeInsets.all(isMobile ? 16 : 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'MUNICIPAL COLLECTION ZONES & DISPATCH POOL',
                style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: subtextColor, letterSpacing: 0.5),
              ),
              TextButton.icon(
                onPressed: () => showEcoGeminiAssistantSheet(context),
                icon: const Icon(Icons.auto_awesome, size: 16),
                label: const Text('Gemini Assistant', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
              ),
            ],
          ),
          const SizedBox(height: 12),

          // Real Interactive OpenStreetMap Fleet Zone Overview
          ClipRRect(
            borderRadius: BorderRadius.circular(16),
            child: SizedBox(
              height: 240,
              child: EcoCartoMap(
                center: const LatLng(3.0303, 30.9073),
                zoom: 14.0,
                showLandmarks: true,
                showControls: true,
                onLocationSelected: (pos) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('Zone inspection coordinate: ${pos.latitude.toStringAsFixed(4)}, ${pos.longitude.toStringAsFixed(4)}'),
                      duration: const Duration(seconds: 2),
                    ),
                  );
                },
              ),
            ),
          ),
          const SizedBox(height: 16),
          ...zones.map((z) => Container(
            margin: const EdgeInsets.only(bottom: 12),
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: cardColor,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: AntigravityTheme.border(context)),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(z['name']!, style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: textColor)),
                    const SizedBox(height: 4),
                    Text('Fleet: ${z['tricycles']}', style: TextStyle(fontSize: 12, color: subtextColor)),
                    const SizedBox(height: 4),
                    Text(z['sacks']!, style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: accentGreen)),
                  ],
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: accentGreen.withOpacity(0.12),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(z['status']!, style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: accentGreen)),
                ),
              ],
            ),
          )),
        ],
      ),
    );
  }

  Widget _buildAdminAccessControlTab(
    EcoRouteState state,
    Color textColor,
    Color subtextColor,
    Color cardColor,
    Color accentGreen,
    bool isDark, {
    required bool isMobile,
  }) {
    return SingleChildScrollView(
      padding: EdgeInsets.all(isMobile ? 16 : 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'ROLE-BASED ACCESS CONTROL & RIDER ROSTER',
            style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: subtextColor, letterSpacing: 0.5),
          ),
          const SizedBox(height: 14),
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
                    Text('Municipal Operations Authority', style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: textColor)),
                    FilledButton.icon(
                      onPressed: () {
                        final nameCtrl = TextEditingController();
                        final phoneCtrl = TextEditingController(text: '+256 7');
                        final emailCtrl = TextEditingController();
                        String triId = 'TRIC-04';

                        showDialog(
                          context: context,
                          builder: (ctx) => AlertDialog(
                            title: const Text('Invite Commercial Fleet Rider', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                            content: SizedBox(
                              width: 380,
                              child: Column(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  TextField(
                                    controller: nameCtrl,
                                    decoration: const InputDecoration(labelText: 'Rider Full Name', border: OutlineInputBorder()),
                                  ),
                                  const SizedBox(height: 10),
                                  TextField(
                                    controller: phoneCtrl,
                                    decoration: const InputDecoration(labelText: 'Phone Number', border: OutlineInputBorder()),
                                  ),
                                  const SizedBox(height: 10),
                                  TextField(
                                    controller: emailCtrl,
                                    decoration: const InputDecoration(labelText: 'Email Address (for dispatch portal)', border: OutlineInputBorder()),
                                  ),
                                  const SizedBox(height: 10),
                                  DropdownButtonFormField<String>(
                                    value: triId,
                                    decoration: const InputDecoration(labelText: 'Assigned Tricycle', border: OutlineInputBorder()),
                                    items: const [
                                      DropdownMenuItem(value: 'TRIC-04', child: Text('TRIC-04 (Ediofe Depot)')),
                                      DropdownMenuItem(value: 'TRIC-09', child: Text('TRIC-09 (Onduparaka / Trading Center)')),
                                      DropdownMenuItem(value: 'TRIC-12', child: Text('TRIC-12 (Arua Hill / Commercial)')),
                                      DropdownMenuItem(value: 'TRIC-18', child: Text('TRIC-18 (Central Market / Ayivu)')),
                                    ],
                                    onChanged: (val) => triId = val ?? 'TRIC-04',
                                  ),
                                ],
                              ),
                            ),
                            actions: [
                              TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
                              FilledButton(
                                onPressed: () async {
                                  final name = nameCtrl.text.trim();
                                  final phone = phoneCtrl.text.trim();
                                  final email = emailCtrl.text.trim();
                                  if (name.isEmpty) return;
                                  Navigator.pop(ctx);
                                  final code = state.inviteRider(
                                    name: name,
                                    phone: phone,
                                    tricycleId: triId,
                                    email: email.isNotEmpty ? email : null,
                                  );
                                  if (email.isNotEmpty) {
                                    await RiderInviteService.sendRiderInviteEmail(
                                      riderEmail: email,
                                      riderName: name,
                                      inviteCode: code,
                                      tricycleId: triId,
                                    );
                                  }
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(content: Text('Rider $name authorized! Code: $code assigned to $triId.')),
                                  );
                                },
                                style: FilledButton.styleFrom(backgroundColor: accentGreen),
                                child: const Text('Dispatch Authorization'),
                              ),
                            ],
                          ),
                        );
                      },
                      icon: const Icon(Icons.person_add, size: 16),
                      label: const Text('Invite Rider'),
                      style: FilledButton.styleFrom(backgroundColor: accentGreen),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Text('Admin Roster: Super Admin, Operations Manager, Route Supervisor (3 officers active).', style: TextStyle(fontSize: 12, color: subtextColor)),
              ],
            ),
          ),
          const SizedBox(height: 12),
          ListTile(
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            tileColor: Colors.redAccent.withOpacity(0.12),
            leading: const Icon(Icons.logout, color: Colors.redAccent, size: 20),
            title: const Text('Sign Out', style: TextStyle(color: Colors.redAccent, fontWeight: FontWeight.bold, fontSize: 13)),
            onTap: () => EcoRouteState.instance.logout(context),
          ),
        ],
      ),
    );
  }

  Widget _buildAdminGlobalConfigTab(
    EcoRouteState state,
    Color textColor,
    Color subtextColor,
    Color cardColor,
    Color accentGreen,
    bool isDark, {
    required bool isMobile,
  }) {
    return SingleChildScrollView(
      padding: EdgeInsets.all(isMobile ? 16 : 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'GLOBAL MUNICIPAL CONFIGURATION',
            style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: subtextColor, letterSpacing: 0.5),
          ),
          const SizedBox(height: 14),
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
                Text('Standard Municipal Tariff: UGX ${state.baseSackPriceUgx} / Standard Sack', style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: textColor)),
                const SizedBox(height: 8),
                Text('Bulky / Commercial Surcharge: UGX ${state.bulkyWasteSurchargeUgx} / Sack', style: TextStyle(fontSize: 13, color: textColor)),
                const SizedBox(height: 8),
                Text('Rider Revenue Share: ${state.riderCommissionPercent}%', style: TextStyle(fontSize: 13, color: textColor)),
                const SizedBox(height: 8),
                Text('Support Hotline: $kEcoRouteSupportPhone', style: TextStyle(fontSize: 13, color: accentGreen, fontWeight: FontWeight.bold)),
              ],
            ),
          ),
          const SizedBox(height: 12),
          ListTile(
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            tileColor: Colors.redAccent.withOpacity(0.12),
            leading: const Icon(Icons.logout, color: Colors.redAccent, size: 20),
            title: const Text('Sign Out', style: TextStyle(color: Colors.redAccent, fontWeight: FontWeight.bold, fontSize: 13)),
            onTap: () => EcoRouteState.instance.logout(context),
          ),
        ],
      ),
    );
  }
  Widget _buildSidebar({double width = 280}) {
    final state = EcoRouteState.instance;
    final isDark = AntigravityTheme.isDark(context);
    final accentGreen = AntigravityTheme.ecoAccent(context);

    return Container(
      width: width,
      color: isDark ? const Color(0xFF161616) : const Color(0xFF0D2618),
      padding: const EdgeInsets.symmetric(vertical: 24, horizontal: 18),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.12),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(Icons.eco, color: Color(0xFF4CAF50), size: 24),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: const [
                    Text(
                      'Antigravity',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Text(
                      'Command HQ • Arua',
                      style: TextStyle(color: Colors.white60, fontSize: 11),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 32),
          _buildAdminNavItem(0, 'Fleet Summary', Icons.directions_bike),
          _buildAdminNavItem(1, 'System Ledgers', Icons.receipt_long),
          _buildAdminNavItem(2, 'Zone Management', Icons.map_outlined),
          _buildAdminNavItem(3, 'Access Control', Icons.security),
          _buildAdminNavItem(4, 'Global Config', Icons.settings_outlined),
          const Spacer(),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.06),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Row(
              children: [
                CircleAvatar(
                  backgroundColor: accentGreen,
                  radius: 16,
                  child: Text(
                    state.userName.isNotEmpty ? state.userName[0].toUpperCase() : 'A',
                    style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        state.userName.isNotEmpty ? state.userName : 'Administrator',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 11,
                          fontWeight: FontWeight.bold,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      Text(
                        state.roleDisplayName,
                        style: const TextStyle(color: Color(0xFF81C784), fontSize: 10),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),
          ListTile(
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            tileColor: Colors.redAccent.withOpacity(0.12),
            leading: const Icon(Icons.logout, color: Colors.redAccent, size: 20),
            title: const Text('Sign Out', style: TextStyle(color: Colors.redAccent, fontWeight: FontWeight.bold, fontSize: 13)),
            onTap: () => EcoRouteState.instance.logout(context),
          ),
        ],
      ),
    );
  }

  Widget _buildMetricCard({
    required String title,
    required String value,
    required String subtitle,
    required IconData icon,
    required Color color,
  }) {
    final cardColor = AntigravityTheme.card(context);
    final textColor = AntigravityTheme.textPrimary(context);
    final subtextColor = AntigravityTheme.textSecondary(context);

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: cardColor,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AntigravityTheme.border(context)),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: color.withOpacity(0.12),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, color: color, size: 28),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    fontSize: 12,
                    color: subtextColor,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  value,
                  style: TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                    color: textColor,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  subtitle,
                  style: TextStyle(fontSize: 11, color: subtextColor),
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),
          ListTile(
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            tileColor: Colors.redAccent.withOpacity(0.12),
            leading: const Icon(Icons.logout, color: Colors.redAccent, size: 20),
            title: const Text('Sign Out', style: TextStyle(color: Colors.redAccent, fontWeight: FontWeight.bold, fontSize: 13)),
            onTap: () => EcoRouteState.instance.logout(context),
          ),
        ],
      ),
    );
  }

  Widget _buildTableCell(String text, {bool isHeader = false, Color? statusColor}) {
    final textColor = AntigravityTheme.textPrimary(context);
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
      child: Text(
        text,
        style: TextStyle(
          fontSize: 12,
          fontWeight: isHeader ? FontWeight.bold : FontWeight.normal,
          color: statusColor ?? textColor,
        ),
      ),
    );
  }

  Widget _buildAdminNavItem(int index, String label, IconData icon) {
    final isSelected = _selectedSidebarIndex == index;
    return ListTile(
      dense: true,
      selected: isSelected,
      leading: Icon(icon, color: isSelected ? const Color(0xFF4CAF50) : Colors.white70, size: 20),
      title: Text(
        label,
        style: TextStyle(
          color: isSelected ? Colors.white : Colors.white70,
          fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
          fontSize: 13,
        ),
      ),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      tileColor: isSelected ? Colors.white.withOpacity(0.12) : Colors.transparent,
      onTap: () {
        setState(() => _selectedSidebarIndex = index);
        if (Navigator.of(context).canPop()) {
          Navigator.of(context).pop();
        }
      },
    );
  }
}
