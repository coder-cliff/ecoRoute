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
    final state = EcoRouteState.instance;
    final isDark = AntigravityTheme.isDark(context);
    final surfaceColor = AntigravityTheme.surface(context);
    final cardColor = AntigravityTheme.card(context);
    final textColor = AntigravityTheme.textPrimary(context);
    final subtextColor = AntigravityTheme.textSecondary(context);
    final accentGreen = AntigravityTheme.ecoAccent(context);

    // Responsive container
    return Scaffold(
      backgroundColor: surfaceColor,
      body: Row(
        children: [
          // 280px NAVIGATION SIDEBAR (Wireframe C Specification)
          Container(
            width: ViewportBreakpoints.sidebarWidth,
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
                    Column(
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
                  ],
                ),
                const SizedBox(height: 32),

                _buildAdminNavItem(0, 'Fleet Summary', Icons.directions_bike),
                _buildAdminNavItem(1, 'System Ledgers', Icons.receipt_long),
                _buildAdminNavItem(2, 'Zone Management', Icons.map_outlined),
                _buildAdminNavItem(3, 'Access Control', Icons.security),
                _buildAdminNavItem(4, 'Global Config', Icons.settings_outlined),

                const Spacer(),

                // Admin Status Panel
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
                              style: const TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.bold),
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
          ),

          // CENTRAL ADMINISTRATIVE COMMAND MATRIX PANEL (Wireframe C)
          Expanded(
            child: Column(
              children: [
                // Top Header
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
                  color: cardColor,
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'ADMINISTRATIVE COMMAND MATRIX',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: textColor,
                          letterSpacing: 0.8,
                        ),
                      ),
                      Row(
                        children: [
                          IconButton(
                            tooltip: 'Toggle Theme',
                            icon: Icon(isDark ? Icons.light_mode : Icons.dark_mode, color: textColor),
                            onPressed: () => state.toggleTheme(),
                          ),
                          const SizedBox(width: 12),
                          FilledButton.icon(
                            onPressed: () => showEcoRouteProfileSheet(context),
                            icon: const Icon(Icons.tune, size: 16),
                            label: const Text('Municipal Settings'),
                            style: FilledButton.styleFrom(backgroundColor: accentGreen),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                const Divider(height: 1),

                // Content
                Expanded(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.all(24),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // OVERVIEW METRICS:
                        // [Total Volume: 4.2 Tons] [Fleet Online: 14/18] [Unreconciled SMS: 0]
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
                        Row(
                          children: [
                            _buildMetricCard(
                              title: 'Total Volume',
                              value: '${state.totalTonnes > 0 ? state.totalTonnes.toStringAsFixed(1) : '4.2'} Tons',
                              subtitle: 'Municipal waste diverted',
                              icon: Icons.scale,
                              color: accentGreen,
                            ),
                            const SizedBox(width: 16),
                            _buildMetricCard(
                              title: 'Fleet Online',
                              value: '${state.activeRidersCount > 0 ? state.activeRidersCount : 14}/18',
                              subtitle: 'Tricycles in service',
                              icon: Icons.electric_moped,
                              color: const Color(0xFF1976D2),
                            ),
                            const SizedBox(width: 16),
                            _buildMetricCard(
                              title: 'Unreconciled SMS',
                              value: '0',
                              subtitle: 'Telecom stream cleared',
                              icon: Icons.sms_outlined,
                              color: const Color(0xFFF57C00),
                            ),
                          ],
                        ),
                        const SizedBox(height: 28),

                        // LOGISTICS & MONITORING CENTRAL LEDGER GRID FRAME
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
                                  Text(
                                    'LOGISTICS & MONITORING CENTRAL LEDGER GRID FRAME',
                                    style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: textColor),
                                  ),
                                  Text(
                                    'Real-time Firestore Synchronized',
                                    style: TextStyle(fontSize: 11, color: accentGreen, fontWeight: FontWeight.w600),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 16),

                              // Table
                              ClipRRect(
                                borderRadius: BorderRadius.circular(8),
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

    return Expanded(
      child: Container(
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
                  Text(title, style: TextStyle(fontSize: 12, color: subtextColor, fontWeight: FontWeight.w500)),
                  const SizedBox(height: 4),
                  Text(value, style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: textColor)),
                  const SizedBox(height: 2),
                  Text(subtitle, style: TextStyle(fontSize: 11, color: subtextColor)),
                ],
              ),
            ),
          ],
        ),
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
      onTap: () => setState(() => _selectedSidebarIndex = index),
    );
  }
}
