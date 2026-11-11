import 'package:flutter/material.dart';
import '../../../main.dart';
import 'admin_chart_painters.dart';

/// Screen 7: System Analytics Dashboard (Image 7)
/// Features dual-area Weekly Collection & Volume chart, 92.5% Driver Utilization donut gauge,
/// 4 KPI cards with sparklines, and Completed Collections Log table with CSV export.
class AdminAnalyticsDashboardView extends StatefulWidget {
  const AdminAnalyticsDashboardView({super.key});

  @override
  State<AdminAnalyticsDashboardView> createState() => _AdminAnalyticsDashboardViewState();
}

class _AdminAnalyticsDashboardViewState extends State<AdminAnalyticsDashboardView> {
  String _selectedTimeframe = 'This Week';

  final List<Map<String, dynamic>> _completedLogs = [
    {
      'id': '#ER8432',
      'client': 'Ayiko Gift',
      'area': 'Block 3, Arua Hill',
      'volume': '1.2 Tons',
      'rider': 'Okello John',
      'time': '09:45 AM',
      'status': 'Verified',
    },
    {
      'id': '#ER8431',
      'client': 'Gulu Logistics Ltd',
      'area': 'Industrial Area, Arua',
      'volume': '2.8 Tons',
      'rider': 'Kato David',
      'time': '09:15 AM',
      'status': 'Verified',
    },
    {
      'id': '#ER8430',
      'client': 'West Nile Traders',
      'area': 'Arua Main Market',
      'volume': '0.8 Tons',
      'rider': 'Mukasa Paul',
      'time': '08:40 AM',
      'status': 'Verified',
    },
    {
      'id': '#ER8429',
      'client': 'Arua Agri Hub',
      'area': 'Hospital Road',
      'volume': '1.5 Tons',
      'rider': 'Opio Francis',
      'time': '08:10 AM',
      'status': 'Verified',
    },
    {
      'id': '#ER8428',
      'client': 'White Rhino Hotel',
      'area': 'Rhino Camp Rd',
      'volume': '3.1 Tons',
      'rider': 'Drileba Emmanuel',
      'time': '07:35 AM',
      'status': 'Verified',
    },
  ];

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final screenWidth = MediaQuery.of(context).size.width;
    final isDesktop = screenWidth >= 1024;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header & Top Controls
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'System Analytics Dashboard',
                      style: theme.textTheme.headlineSmall?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: isDark ? Colors.white : const Color(0xFF1E293B),
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Monitor operational performance, rider utilization, and completion metrics.',
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 12),
              // Timeframe Dropdown
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                decoration: BoxDecoration(
                  color: isDark ? const Color(0xFF1E293B) : Colors.white,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                    color: isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0),
                  ),
                ),
                child: DropdownButtonHideUnderline(
                  child: DropdownButton<String>(
                    value: _selectedTimeframe,
                    dropdownColor: isDark ? const Color(0xFF1E293B) : Colors.white,
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w500,
                      color: isDark ? Colors.white : const Color(0xFF1E293B),
                    ),
                    items: const [
                      DropdownMenuItem(value: 'Today', child: Text('Today')),
                      DropdownMenuItem(value: 'This Week', child: Text('This Week')),
                      DropdownMenuItem(value: 'This Month', child: Text('This Month')),
                      DropdownMenuItem(value: 'Quarter to Date', child: Text('Quarter to Date')),
                    ],
                    onChanged: (val) {
                      if (val != null) setState(() => _selectedTimeframe = val);
                    },
                  ),
                ),
              ),
              const SizedBox(width: 10),
              // Export Report Button
              PopupMenuButton<String>(
                onSelected: (val) {
                  if (val == 'csv') {
                    EcoRouteState.instance.exportCollectionAuditCsv(context);
                  } else {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Generating summary audit report...')),
                    );
                  }
                },
                itemBuilder: (ctx) => [
                  const PopupMenuItem(
                    value: 'csv',
                    child: Row(
                      children: [
                        Icon(Icons.table_chart, size: 16, color: Color(0xFF2E7D32)),
                        SizedBox(width: 8),
                        Text('Export CSV Audit Log'),
                      ],
                    ),
                  ),
                  const PopupMenuItem(
                    value: 'summary',
                    child: Row(
                      children: [
                        Icon(Icons.picture_as_pdf, size: 16, color: Color(0xFFD32F2F)),
                        SizedBox(width: 8),
                        Text('Executive Summary (Print)'),
                      ],
                    ),
                  ),
                ],
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                  decoration: BoxDecoration(
                    color: isDark ? const Color(0xFF1E293B) : Colors.white,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(
                      color: isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0),
                    ),
                  ),
                  child: Row(
                    children: [
                      Text(
                        'Export Report',
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w500,
                          color: isDark ? Colors.white : const Color(0xFF1E293B),
                        ),
                      ),
                      const SizedBox(width: 4),
                      Icon(
                        Icons.keyboard_arrow_down,
                        size: 16,
                        color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),

          // 4 KPI Cards
          LayoutBuilder(
            builder: (context, constraints) {
              final crossAxisCount = constraints.maxWidth >= 1000
                  ? 4
                  : (constraints.maxWidth >= 540 ? 2 : 1);
              return GridView.count(
                crossAxisCount: crossAxisCount,
                crossAxisSpacing: 16,
                mainAxisSpacing: 16,
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                childAspectRatio: 1.85,
                children: [
                  _buildKpiCard(
                    context,
                    title: 'Completed Collections',
                    value: '2,482',
                    badge: '+12.4%',
                    badgeColor: const Color(0xFF2E7D32),
                    sparklinePoints: [10, 14, 12, 18, 16, 22, 28],
                    sparklineColor: const Color(0xFF2E7D32),
                    isDark: isDark,
                  ),
                  _buildKpiCard(
                    context,
                    title: 'Total Volume (Tons)',
                    value: '48.2',
                    badge: '+8%',
                    badgeColor: const Color(0xFF2E7D32),
                    sparklinePoints: [8, 11, 15, 12, 18, 20, 24],
                    sparklineColor: const Color(0xFF2E7D32),
                    isDark: isDark,
                  ),
                  _buildUtilizationKpiCard(
                    context,
                    title: 'Active Rider Utilization',
                    value: '92.5%',
                    subtext: '12 / 15 Riders active',
                    isDark: isDark,
                  ),
                  _buildKpiCard(
                    context,
                    title: 'Environmental Impact',
                    value: '3,480 kg',
                    unit: 'CO2 Offset',
                    badge: '+15%',
                    badgeColor: const Color(0xFF2E7D32),
                    badgeIcon: Icons.eco,
                    sparklinePoints: [12, 14, 18, 22, 25, 30, 35],
                    sparklineColor: const Color(0xFF2E7D32),
                    isDark: isDark,
                  ),
                ],
              );
            },
          ),
          const SizedBox(height: 24),

          // Middle Charts Section: Weekly Collection & Volume + Driver Utilization Donut
          if (isDesktop)
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  flex: 3,
                  child: _buildWeeklyCollectionChartCard(isDark),
                ),
                const SizedBox(width: 24),
                Expanded(
                  flex: 2,
                  child: _buildDriverUtilizationCard(isDark),
                ),
              ],
            )
          else ...[
            _buildWeeklyCollectionChartCard(isDark),
            const SizedBox(height: 20),
            _buildDriverUtilizationCard(isDark),
          ],

          const SizedBox(height: 24),

          // Completed Collections Log Table
          _buildCompletedCollectionsTable(context, isDark),
          const SizedBox(height: 24),
        ],
      ),
    );
  }

  Widget _buildKpiCard(
    BuildContext context, {
    required String title,
    required String value,
    String? unit,
    required String badge,
    required Color badgeColor,
    IconData? badgeIcon,
    required List<double> sparklinePoints,
    required Color sparklineColor,
    required bool isDark,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E293B) : Colors.white,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(
          color: isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Text(
                  title,
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                    color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B),
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: badgeColor.withOpacity(0.12),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    if (badgeIcon != null) ...[
                      Icon(badgeIcon, size: 11, color: badgeColor),
                      const SizedBox(width: 2),
                    ],
                    Text(
                      badge,
                      style: TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                        color: badgeColor,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.baseline,
                textBaseline: TextBaseline.alphabetic,
                children: [
                  Text(
                    value,
                    style: TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                      color: isDark ? Colors.white : const Color(0xFF1E293B),
                    ),
                  ),
                  if (unit != null) ...[
                    const SizedBox(width: 4),
                    Text(
                      unit,
                      style: TextStyle(
                        fontSize: 11,
                        color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B),
                      ),
                    ),
                  ],
                ],
              ),
              SizedBox(
                width: 60,
                height: 24,
                child: CustomPaint(
                  painter: MiniSparklinePainter(
                    points: sparklinePoints,
                    lineColor: sparklineColor,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildUtilizationKpiCard(
    BuildContext context, {
    required String title,
    required String value,
    required String subtext,
    required bool isDark,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E293B) : Colors.white,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(
          color: isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Text(
                  title,
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                    color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B),
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: const Color(0xFFE8F5E9),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Text(
                  'Optimal',
                  style: TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF2E7D32),
                  ),
                ),
              ),
            ],
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                value,
                style: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                  color: isDark ? Colors.white : const Color(0xFF1E293B),
                ),
              ),
              Text(
                subtext,
                style: TextStyle(
                  fontSize: 11,
                  color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildWeeklyCollectionChartCard(bool isDark) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E293B) : Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Weekly Collection & Volume',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: isDark ? Colors.white : const Color(0xFF1E293B),
                ),
              ),
              Row(
                children: [
                  Row(
                    children: [
                      Container(width: 8, height: 8, decoration: const BoxDecoration(color: Color(0xFF1B5E20), shape: BoxShape.circle)),
                      const SizedBox(width: 6),
                      Text('Tons', style: TextStyle(fontSize: 12, color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B))),
                    ],
                  ),
                  const SizedBox(width: 16),
                  Row(
                    children: [
                      Container(width: 8, height: 8, decoration: const BoxDecoration(color: Color(0xFF81C784), shape: BoxShape.circle)),
                      const SizedBox(width: 6),
                      Text('Active Trips', style: TextStyle(fontSize: 12, color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B))),
                    ],
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 20),

          // Area Chart View
          SizedBox(
            height: 180,
            child: Row(
              children: [
                // Y-Axis Left (Tons)
                Column(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: const ['100', '80', '60', '40', '20', '0']
                      .map((l) => Text(l, style: const TextStyle(fontSize: 10, color: Color(0xFF94A3B8))))
                      .toList(),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: CustomPaint(
                    painter: WeeklyCollectionAreaChartPainter(
                      isDark: isDark,
                      tonData: const [15, 45, 85, 42, 60, 48, 95],
                      tripData: const [25, 60, 40, 75, 50, 80, 20],
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                // Y-Axis Right (Active Trips)
                Column(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: const ['100', '75', '50', '25', '0']
                      .map((l) => Text(l, style: const TextStyle(fontSize: 10, color: Color(0xFF94A3B8))))
                      .toList(),
                ),
              ],
            ),
          ),
          const SizedBox(height: 8),
          // X-Axis Labels
          Padding(
            padding: const EdgeInsets.only(left: 32, right: 32),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: const ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun']
                  .map((d) => Text(d, style: const TextStyle(fontSize: 11, color: Color(0xFF94A3B8))))
                  .toList(),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDriverUtilizationCard(bool isDark) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E293B) : Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Driver Utilization',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: isDark ? Colors.white : const Color(0xFF1E293B),
            ),
          ),
          const SizedBox(height: 16),
          // Radial Gauge
          Center(
            child: SizedBox(
              width: 140,
              height: 140,
              child: Stack(
                alignment: Alignment.center,
                children: [
                  CustomPaint(
                    size: const Size(140, 140),
                    painter: DriverUtilizationDonutPainter(
                      percentage: 92.5,
                      isDark: isDark,
                    ),
                  ),
                  Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        '92.5%',
                        style: TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.bold,
                          color: isDark ? Colors.white : const Color(0xFF1E293B),
                        ),
                      ),
                      const Text(
                        'Optimal',
                        style: TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.w600,
                          color: Color(0xFF2E7D32),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 20),
          // Breakdown Items
          _buildUtilizationLegendRow('Active (En-route)', '12', const Color(0xFF1B5E20), isDark),
          const SizedBox(height: 6),
          _buildUtilizationLegendRow('Idle (Online)', '3', const Color(0xFF66BB6A), isDark),
          const SizedBox(height: 6),
          _buildUtilizationLegendRow('Offline', '5', const Color(0xFF94A3B8), isDark),
        ],
      ),
    );
  }

  Widget _buildUtilizationLegendRow(String label, String count, Color dotColor, bool isDark) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Row(
          children: [
            Container(width: 8, height: 8, decoration: BoxDecoration(color: dotColor, shape: BoxShape.circle)),
            const SizedBox(width: 8),
            Text(
              label,
              style: TextStyle(
                fontSize: 12,
                color: isDark ? const Color(0xFFCBD5E1) : const Color(0xFF475569),
              ),
            ),
          ],
        ),
        Text(
          count,
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.bold,
            color: isDark ? Colors.white : const Color(0xFF1E293B),
          ),
        ),
      ],
    );
  }

  Widget _buildCompletedCollectionsTable(BuildContext context, bool isDark) {
    return Container(
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E293B) : Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0),
        ),
      ),
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Completed Collections Log',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: isDark ? Colors.white : const Color(0xFF1E293B),
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: const Color(0xFFE8F5E9),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: const Text(
                  '● System Online • 12 Active',
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF2E7D32),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),

          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: DataTable(
              headingRowColor: MaterialStateProperty.all(
                isDark ? const Color(0xFF0F172A) : const Color(0xFFF8FAFC),
              ),
              columns: const [
                DataColumn(label: Text('ID', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12))),
                DataColumn(label: Text('Client', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12))),
                DataColumn(label: Text('Area', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12))),
                DataColumn(label: Text('Volume', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12))),
                DataColumn(label: Text('Rider', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12))),
                DataColumn(label: Text('Time', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12))),
                DataColumn(label: Text('Status', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12))),
              ],
              rows: _completedLogs.map((log) {
                return DataRow(
                  cells: [
                    DataCell(Text(log['id'], style: const TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF2E7D32), fontSize: 12))),
                    DataCell(Text(log['client'], style: const TextStyle(fontSize: 12))),
                    DataCell(Text(log['area'], style: const TextStyle(fontSize: 12))),
                    DataCell(Text(log['volume'], style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600))),
                    DataCell(Text(log['rider'], style: const TextStyle(fontSize: 12))),
                    DataCell(Text(log['time'], style: const TextStyle(fontSize: 12))),
                    DataCell(
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                        decoration: BoxDecoration(
                          color: const Color(0xFFE8F5E9),
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Text(
                          log['status'],
                          style: const TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF2E7D32),
                          ),
                        ),
                      ),
                    ),
                  ],
                );
              }).toList(),
            ),
          ),
        ],
      ),
    );
  }
}
