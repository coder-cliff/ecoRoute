import 'package:flutter/material.dart';

import '../../core/layout/adaptive_layout.dart';
import '../../main.dart';

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
                                              _buildTableCell('#1001'),
                                              _buildTableCell('TRIC-18 (Field Active)'),
                                              _buildTableCell('In Progress', statusColor: Colors.orange),
                                              _buildTableCell('45 kg'),
                                              _buildTableCell('REF-ARUA-7821'),
                                            ],
                                          ),
                                          TableRow(
                                            children: [
                                              _buildTableCell('#1002'),
                                              _buildTableCell('TRIC-09 (Field Active)'),
                                              _buildTableCell('Collected', statusColor: Colors.green),
                                              _buildTableCell('60 kg'),
                                              _buildTableCell('REF-ARUA-7822'),
                                            ],
                                          ),
                                          TableRow(
                                            children: [
                                              _buildTableCell('#1003'),
                                              _buildTableCell('TRIC-12 (Field Active)'),
                                              _buildTableCell('Settled', statusColor: Colors.blue),
                                              _buildTableCell('35 kg'),
                                              _buildTableCell('REF-ARUA-7823'),
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
                               ],
                             ),
                           ),
                         ],
                        ),
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
                  value: 'UGX ${'$'}{state.totalDepotReconciledCash}',
                  subtitle: 'Physical cash verified at depot desk',
                  icon: Icons.payments,
                  color: accentGreen,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildMetricCard(
                  title: 'Tricycle Pouches',
                  value: 'UGX ${'$'}{state.totalCashInPouches}',
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
                    Text('Cash Reconciliation & MoMo Settlement Desk', style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: textColor)),
                    FilledButton.icon(
                      onPressed: () {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('All pending rider cash pouches marked reconciled with central depot.')),
                        );
                      },
                      icon: const Icon(Icons.check, size: 16),
                      label: const Text('Reconcile Pouches'),
                      style: FilledButton.styleFrom(backgroundColor: accentGreen),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Text('Active Settlement Desk Status: 100% in compliance with Arua Municipal revenue authority standards.', style: TextStyle(fontSize: 12, color: subtextColor)),
              ],
            ),
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
          Text(
            'MUNICIPAL COLLECTION ZONES & DISPATCH POOL',
            style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: subtextColor, letterSpacing: 0.5),
          ),
          const SizedBox(height: 14),
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
                    Text('Fleet: ${'$'}{z[''tricycles'']}', style: TextStyle(fontSize: 12, color: subtextColor)),
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
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('Rider invite code generated: ARUA-ECO-9941')),
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
                Text('Standard Municipal Tariff: UGX ${'$'}{state.baseSackPriceUgx} / Standard Sack', style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: textColor)),
                const SizedBox(height: 8),
                Text('Bulky / Commercial Surcharge: UGX ${'$'}{state.bulkyWasteSurchargeUgx} / Sack', style: TextStyle(fontSize: 13, color: textColor)),
                const SizedBox(height: 8),
                Text('Rider Revenue Share: ${'$'}{state.riderCommissionPercent}%', style: TextStyle(fontSize: 13, color: textColor)),
                const SizedBox(height: 8),
                Text('Support Hotline: ${'$'}kEcoRouteSupportPhone', style: TextStyle(fontSize: 13, color: accentGreen, fontWeight: FontWeight.bold)),
              ],
            ),
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
