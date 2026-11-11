import 'package:flutter/material.dart';

import '../../../core/layout/adaptive_layout.dart';
import '../../../core/theme/eco_palette.dart';
import '../../../main.dart';
import 'admin_chart_painters.dart';

/// Screen 5: Request History with Filters, Data Table & CSV Export (Image 5)
class AdminRequestsView extends StatefulWidget {
  const AdminRequestsView({super.key});

  @override
  State<AdminRequestsView> createState() => _AdminRequestsViewState();
}

class _AdminRequestsViewState extends State<AdminRequestsView> {
  final TextEditingController _searchController = TextEditingController();
  String _selectedStatus = 'All';
  String _selectedWasteType = 'All';
  int _currentPage = 1;

  final List<Map<String, dynamic>> _allRequests = [
    {
      'id': '#ER8432',
      'client': 'Ayiko Gift',
      'wasteType': 'General Commercial',
      'status': 'Completed',
      'dateTime': 'Nov 11, 2026, 09:45 AM',
      'payment': 'UGX 15,000',
      'method': 'Mobile Money',
      'isMoMo': true,
      'statusColor': Color(0xFF2E7D32),
      'statusBg': Color(0xFFE8F5E9),
    },
    {
      'id': '#ER8431',
      'client': 'Gulu Logistics',
      'wasteType': 'Multi-bins',
      'status': 'Pending',
      'dateTime': 'Nov 11, 2026, 09:12 AM',
      'payment': 'UGX 45,000',
      'method': 'Card',
      'isMoMo': false,
      'statusColor': Color(0xFFE65100),
      'statusBg': Color(0xFFFFF3E0),
    },
    {
      'id': '#ER8430',
      'client': 'West Nile Traders',
      'wasteType': 'Heavy Cargo',
      'status': 'Pending',
      'dateTime': 'Nov 11, 2026, 08:30 AM',
      'payment': 'UGX 30,000',
      'method': 'Card',
      'isMoMo': false,
      'statusColor': Color(0xFFE65100),
      'statusBg': Color(0xFFFFF3E0),
    },
    {
      'id': '#ER8429',
      'client': 'Gulu Logistics',
      'wasteType': 'General Waste',
      'status': 'In-Transit',
      'dateTime': 'Nov 11, 2026, 07:38 AM',
      'payment': 'UGX 60,000',
      'method': 'Card',
      'isMoMo': false,
      'statusColor': Color(0xFF0284C7),
      'statusBg': Color(0xFFE0F2FE),
    },
    {
      'id': '#ER8428',
      'client': 'Arua Central Hotel',
      'wasteType': 'Organic Waste',
      'status': 'In-Transit',
      'dateTime': 'Nov 11, 2026, 09:45 AM',
      'payment': 'UGX 18,000',
      'method': 'Card',
      'isMoMo': false,
      'statusColor': Color(0xFF0284C7),
      'statusBg': Color(0xFFE0F2FE),
    },
    {
      'id': '#ER8427',
      'client': 'Ayiko Gift',
      'wasteType': 'General Commercial',
      'status': 'Completed',
      'dateTime': 'Nov 11, 2026, 09:30 AM',
      'payment': 'UGX 12,000',
      'method': 'Card',
      'isMoMo': false,
      'statusColor': Color(0xFF2E7D32),
      'statusBg': Color(0xFFE8F5E9),
    },
    {
      'id': '#ER8426',
      'client': 'West Nile Traders',
      'wasteType': 'Heavy Cargo',
      'status': 'Cancelled',
      'dateTime': 'Nov 11, 2026, 08:35 AM',
      'payment': 'UGX 75,000',
      'method': 'Mobile Money',
      'isMoMo': true,
      'statusColor': Color(0xFFE53935),
      'statusBg': Color(0xFFFFEBEE),
    },
  ];

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _showDetailsDialog(Map<String, dynamic> req) {
    showDialog<void>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Row(
          children: [
            const Icon(Icons.receipt_long, color: Color(0xFF1B5E20), size: 22),
            const SizedBox(width: 8),
            Text('Request Details ${req['id']}', style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Client: ${req['client']}', style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold)),
            const SizedBox(height: 4),
            Text('Waste Type: ${req['wasteType']}', style: const TextStyle(fontSize: 13)),
            const SizedBox(height: 4),
            Text('Date: ${req['dateTime']}', style: const TextStyle(fontSize: 12, color: Colors.grey)),
            const SizedBox(height: 4),
            Text('Payment: ${req['payment']} (${req['method']})', style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600)),
            const SizedBox(height: 8),
            Row(
              children: [
                const Text('Status: ', style: TextStyle(fontSize: 12)),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(color: req['statusBg'] as Color, borderRadius: BorderRadius.circular(6)),
                  child: Text(req['status'] as String, style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: req['statusColor'] as Color)),
                ),
              ],
            ),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Close')),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final state = EcoRouteState.instance;
    final isDark = AntigravityTheme.isDark(context);
    final cardColor = isDark ? const Color(0xFF1E293B) : Colors.white;
    final textColor = AntigravityTheme.textPrimary(context);
    final subtextColor = AntigravityTheme.textSecondary(context);
    final borderColor = isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0);
    const brandGreen = Color(0xFF1B5E20);

    final filtered = _allRequests.where((r) {
      final matchesSearch = _searchController.text.isEmpty ||
          (r['client'] as String).toLowerCase().contains(_searchController.text.toLowerCase()) ||
          (r['id'] as String).toLowerCase().contains(_searchController.text.toLowerCase());
      final matchesStatus = _selectedStatus == 'All' || r['status'] == _selectedStatus;
      final matchesType = _selectedWasteType == 'All' || r['wasteType'] == _selectedWasteType;
      return matchesSearch && matchesStatus && matchesType;
    }).toList();

    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Text(
            'Request History',
            style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: textColor, letterSpacing: -0.5),
          ),
          const SizedBox(height: 4),
          Text(
            'Manage, view, and audit past commercial waste collection requests.',
            style: TextStyle(fontSize: 13, color: subtextColor),
          ),
          const SizedBox(height: 20),

          // 4 Top Stat KPI Cards (Image 5)
          LayoutBuilder(
            builder: (context, constraints) {
              final isWide = constraints.maxWidth >= 900;
              final cards = [
                _buildKpiCard('Total Requests', '1,248', [20, 35, 45, 60, 50, 75, 90], const Color(0xFF1B5E20), cardColor, borderColor, textColor, subtextColor),
                _buildKpiCard('Completed', '1,182', [20, 30, 42, 55, 65, 80, 95], const Color(0xFF2E7D32), cardColor, borderColor, textColor, subtextColor),
                _buildKpiCard('Active/Pending', '34', [15, 25, 20, 35, 30, 40, 34], const Color(0xFFE65100), cardColor, borderColor, textColor, subtextColor),
                _buildKpiCard('Cancelled', '32', [10, 15, 12, 18, 14, 25, 32], const Color(0xFFE53935), cardColor, borderColor, textColor, subtextColor),
              ];
              if (isWide) {
                return Row(
                  children: [
                    for (int i = 0; i < cards.length; i++) ...[
                      if (i > 0) const SizedBox(width: 14),
                      Expanded(child: cards[i]),
                    ],
                  ],
                );
              }
              return Wrap(
                spacing: 12,
                runSpacing: 12,
                children: cards.map((c) => SizedBox(width: (constraints.maxWidth - 12) / 2, child: c)).toList(),
              );
            },
          ),

          const SizedBox(height: 24),

          // Filters Bar
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            decoration: BoxDecoration(
              color: cardColor,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: borderColor),
            ),
            child: Wrap(
              spacing: 12,
              runSpacing: 10,
              crossAxisAlignment: WrapCrossAlignment.center,
              children: [
                // Search
                SizedBox(
                  width: 220,
                  height: 38,
                  child: TextField(
                    controller: _searchController,
                    onChanged: (v) => setState(() {}),
                    style: TextStyle(fontSize: 12, color: textColor),
                    decoration: InputDecoration(
                      prefixIcon: const Icon(Icons.search, size: 18, color: Colors.grey),
                      hintText: 'Search by Client or ID',
                      hintStyle: const TextStyle(fontSize: 12, color: Colors.grey),
                      contentPadding: const EdgeInsets.symmetric(vertical: 8),
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: BorderSide(color: borderColor)),
                      enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: BorderSide(color: borderColor)),
                    ),
                  ),
                ),

                // Status Dropdown
                Container(
                  height: 38,
                  padding: const EdgeInsets.symmetric(horizontal: 10),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: borderColor),
                  ),
                  child: DropdownButtonHideUnderline(
                    child: DropdownButton<String>(
                      value: _selectedStatus,
                      style: TextStyle(fontSize: 12, color: textColor),
                      items: const [
                        DropdownMenuItem(value: 'All', child: Text('Filter by Status')),
                        DropdownMenuItem(value: 'Completed', child: Text('Completed')),
                        DropdownMenuItem(value: 'Pending', child: Text('Pending')),
                        DropdownMenuItem(value: 'In-Transit', child: Text('In-Transit')),
                        DropdownMenuItem(value: 'Cancelled', child: Text('Cancelled')),
                      ],
                      onChanged: (val) {
                        if (val != null) setState(() => _selectedStatus = val);
                      },
                    ),
                  ),
                ),

                // Waste Type Dropdown
                Container(
                  height: 38,
                  padding: const EdgeInsets.symmetric(horizontal: 10),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: borderColor),
                  ),
                  child: DropdownButtonHideUnderline(
                    child: DropdownButton<String>(
                      value: _selectedWasteType,
                      style: TextStyle(fontSize: 12, color: textColor),
                      items: const [
                        DropdownMenuItem(value: 'All', child: Text('Filter by Waste Type')),
                        DropdownMenuItem(value: 'General Commercial', child: Text('General Commercial')),
                        DropdownMenuItem(value: 'Multi-bins', child: Text('Multi-bins')),
                        DropdownMenuItem(value: 'Heavy Cargo', child: Text('Heavy Cargo')),
                        DropdownMenuItem(value: 'General Waste', child: Text('General Waste')),
                        DropdownMenuItem(value: 'Organic Waste', child: Text('Organic Waste')),
                      ],
                      onChanged: (val) {
                        if (val != null) setState(() => _selectedWasteType = val);
                      },
                    ),
                  ),
                ),

                // Date Range Button
                OutlinedButton.icon(
                  onPressed: () {},
                  style: OutlinedButton.styleFrom(
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                    side: BorderSide(color: borderColor),
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                  ),
                  icon: const Icon(Icons.calendar_today_outlined, size: 14),
                  label: Text('Date Range', style: TextStyle(fontSize: 12, color: textColor)),
                ),

                // Export CSV Button
                ElevatedButton.icon(
                  onPressed: () => state.exportCollectionAuditCsv(context),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.white,
                    foregroundColor: const Color(0xFF1E293B),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8), side: BorderSide(color: borderColor)),
                    elevation: 0,
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                  ),
                  icon: const Icon(Icons.download, size: 16),
                  label: const Text('Export CSV', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                ),
              ],
            ),
          ),

          const SizedBox(height: 18),

          // Data Table Container
          Container(
            decoration: BoxDecoration(
              color: cardColor,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: borderColor),
              boxShadow: [
                BoxShadow(color: Colors.black.withOpacity(0.02), blurRadius: 8, offset: const Offset(0, 2)),
              ],
            ),
            child: Column(
              children: [
                // Table Header
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  child: Row(
                    children: [
                      Expanded(flex: 2, child: Text('ID', style: TextStyle(fontSize: 11.5, fontWeight: FontWeight.bold, color: subtextColor))),
                      Expanded(flex: 3, child: Text('Client', style: TextStyle(fontSize: 11.5, fontWeight: FontWeight.bold, color: subtextColor))),
                      Expanded(flex: 3, child: Text('Waste Type', style: TextStyle(fontSize: 11.5, fontWeight: FontWeight.bold, color: subtextColor))),
                      Expanded(flex: 2, child: Text('Status', style: TextStyle(fontSize: 11.5, fontWeight: FontWeight.bold, color: subtextColor))),
                      Expanded(flex: 3, child: Text('Date & Time', style: TextStyle(fontSize: 11.5, fontWeight: FontWeight.bold, color: subtextColor))),
                      Expanded(flex: 3, child: Text('Payment', style: TextStyle(fontSize: 11.5, fontWeight: FontWeight.bold, color: subtextColor))),
                      Expanded(flex: 2, child: Text('Actions', textAlign: TextAlign.right, style: TextStyle(fontSize: 11.5, fontWeight: FontWeight.bold, color: subtextColor))),
                    ],
                  ),
                ),
                const Divider(height: 1),
                // Table Rows
                for (final req in filtered) ...[
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                    child: Row(
                      children: [
                        Expanded(flex: 2, child: Text(req['id'] as String, style: TextStyle(fontSize: 12.5, fontWeight: FontWeight.bold, color: textColor))),
                        Expanded(flex: 3, child: Text(req['client'] as String, style: TextStyle(fontSize: 12.5, color: textColor))),
                        Expanded(flex: 3, child: Text(req['wasteType'] as String, style: TextStyle(fontSize: 12, color: subtextColor))),
                        Expanded(
                          flex: 2,
                          child: Align(
                            alignment: Alignment.centerLeft,
                            child: Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                              decoration: BoxDecoration(color: req['statusBg'] as Color, borderRadius: BorderRadius.circular(6)),
                              child: Text(req['status'] as String, style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: req['statusColor'] as Color)),
                            ),
                          ),
                        ),
                        Expanded(flex: 3, child: Text(req['dateTime'] as String, style: TextStyle(fontSize: 11.5, color: subtextColor))),
                        Expanded(
                          flex: 3,
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(req['payment'] as String, style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: textColor)),
                              const SizedBox(width: 4),
                              Icon(
                                (req['isMoMo'] as bool) ? Icons.phone_android : Icons.credit_card,
                                size: 14,
                                color: (req['isMoMo'] as bool) ? const Color(0xFF2E7D32) : const Color(0xFF1E293B),
                              ),
                            ],
                          ),
                        ),
                        Expanded(
                          flex: 2,
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.end,
                            children: [
                              IconButton(
                                icon: const Icon(Icons.visibility_outlined, size: 16),
                                onPressed: () => _showDetailsDialog(req),
                                tooltip: 'View Details',
                              ),
                              IconButton(
                                icon: const Icon(Icons.edit_outlined, size: 16),
                                onPressed: () => _showDetailsDialog(req),
                                tooltip: 'Edit',
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                  const Divider(height: 1),
                ],

                // Table Footer / Pagination (Image 5)
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text('Showing 1-10 of 1,248 entries', style: TextStyle(fontSize: 12, color: subtextColor)),
                      Row(
                        children: [
                          OutlinedButton(
                            onPressed: _currentPage > 1 ? () => setState(() => _currentPage--) : null,
                            style: OutlinedButton.styleFrom(
                              side: BorderSide(color: borderColor),
                              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                            ),
                            child: const Text('Previous', style: TextStyle(fontSize: 11)),
                          ),
                          const SizedBox(width: 6),
                          for (int p = 1; p <= 4; p++) ...[
                            InkWell(
                              onTap: () => setState(() => _currentPage = p),
                              child: Container(
                                width: 28,
                                height: 28,
                                margin: const EdgeInsets.symmetric(horizontal: 2),
                                decoration: BoxDecoration(
                                  color: _currentPage == p ? brandGreen : Colors.transparent,
                                  borderRadius: BorderRadius.circular(6),
                                  border: Border.all(color: _currentPage == p ? brandGreen : borderColor),
                                ),
                                child: Center(
                                  child: Text(
                                    '$p',
                                    style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: _currentPage == p ? Colors.white : textColor),
                                  ),
                                ),
                              ),
                            ),
                          ],
                          const Text(' ... 125 ', style: TextStyle(fontSize: 11, color: Colors.grey)),
                          const SizedBox(width: 6),
                          OutlinedButton(
                            onPressed: () => setState(() => _currentPage++),
                            style: OutlinedButton.styleFrom(
                              side: BorderSide(color: borderColor),
                              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                            ),
                            child: const Text('Next', style: TextStyle(fontSize: 11)),
                          ),
                        ],
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

  Widget _buildKpiCard(
    String label,
    String value,
    List<double> sparkPoints,
    Color sparkColor,
    Color cardColor,
    Color borderColor,
    Color textColor,
    Color subtextColor,
  ) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: cardColor,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: borderColor),
        boxShadow: [
          BoxShadow(color: Colors.black.withOpacity(0.02), blurRadius: 6, offset: const Offset(0, 2)),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: TextStyle(fontSize: 11.5, color: subtextColor)),
          const SizedBox(height: 6),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(value, style: TextStyle(fontSize: 22, fontWeight: FontWeight.w800, color: textColor)),
              SizedBox(
                width: 50,
                height: 22,
                child: CustomPaint(painter: MiniSparklinePainter(points: sparkPoints, lineColor: sparkColor)),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
