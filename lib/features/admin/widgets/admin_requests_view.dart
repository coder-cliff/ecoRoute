import 'package:flutter/material.dart';

import '../../../core/layout/adaptive_layout.dart';
import '../../../core/theme/eco_palette.dart';
import '../../../main.dart';
import 'admin_chart_painters.dart';

/// Screen 5: Request History with Filters, Data Table & CSV Export
/// Dynamic - strictly reflects real resident pickup requests with zero mock data.
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

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
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

    final allRequests = state.residentRequests;

    // Filter requests
    final filtered = allRequests.where((req) {
      final status = (req['status'] ?? 'Pending').toString();
      final wasteType = (req['wasteType'] ?? 'General').toString();
      final client = (req['residentName'] ?? req['client'] ?? '').toString().toLowerCase();
      final id = (req['id'] ?? '').toString().toLowerCase();
      final query = _searchController.text.toLowerCase().trim();

      if (_selectedStatus != 'All' && status != _selectedStatus) return false;
      if (_selectedWasteType != 'All' && wasteType != _selectedWasteType) return false;
      if (query.isNotEmpty && !client.contains(query) && !id.contains(query)) return false;

      return true;
    }).toList();

    final totalCount = allRequests.length;
    final completedCount = allRequests.where((r) => (r['status'] ?? '').toString().toLowerCase() == 'completed').length;
    final pendingCount = allRequests.where((r) {
      final s = (r['status'] ?? '').toString().toLowerCase();
      return s == 'pending' || s == 'dispatched' || s == 'in-transit';
    }).length;
    final cancelledCount = allRequests.where((r) => (r['status'] ?? '').toString().toLowerCase() == 'cancelled').length;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Text(
            'Request History',
            style: TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.bold,
              color: textColor,
              letterSpacing: -0.5,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            'Manage, audit, and track municipal waste collection requests.',
            style: TextStyle(fontSize: 13, color: subtextColor),
          ),

          const SizedBox(height: 20),

          // 4 KPI Summary Cards
          LayoutBuilder(
            builder: (context, constraints) {
              final crossAxisCount = constraints.maxWidth >= 1000 ? 4 : (constraints.maxWidth >= 600 ? 2 : 1);
              return GridView.count(
                crossAxisCount: crossAxisCount,
                crossAxisSpacing: 16,
                mainAxisSpacing: 16,
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                childAspectRatio: 2.1,
                children: [
                  _buildKpiCard(
                    'Total Requests',
                    '$totalCount',
                    '+0%',
                    [0, 0, 0, 0, totalCount.toDouble()],
                    brandGreen,
                    cardColor,
                    borderColor,
                    textColor,
                    subtextColor,
                  ),
                  _buildKpiCard(
                    'Completed',
                    '$completedCount',
                    '+0%',
                    [0, 0, 0, 0, completedCount.toDouble()],
                    const Color(0xFF2E7D32),
                    cardColor,
                    borderColor,
                    textColor,
                    subtextColor,
                  ),
                  _buildKpiCard(
                    'Active / Pending',
                    '$pendingCount',
                    'Queue',
                    [0, 0, 0, 0, pendingCount.toDouble()],
                    const Color(0xFFE65100),
                    cardColor,
                    borderColor,
                    textColor,
                    subtextColor,
                  ),
                  _buildKpiCard(
                    'Cancelled',
                    '$cancelledCount',
                    'Total',
                    [0, 0, 0, 0, cancelledCount.toDouble()],
                    const Color(0xFF94A3B8),
                    cardColor,
                    borderColor,
                    textColor,
                    subtextColor,
                  ),
                ],
              );
            },
          ),

          const SizedBox(height: 20),

          // Search, Filters & Export Toolbar
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: cardColor,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: borderColor),
            ),
            child: Wrap(
              spacing: 12,
              runSpacing: 12,
              alignment: WrapAlignment.spaceBetween,
              crossAxisAlignment: WrapCrossAlignment.center,
              children: [
                // Search Input
                SizedBox(
                  width: 240,
                  height: 38,
                  child: TextField(
                    controller: _searchController,
                    onChanged: (v) => setState(() {}),
                    style: TextStyle(fontSize: 12, color: textColor),
                    decoration: InputDecoration(
                      hintText: 'Search by Client or ID...',
                      hintStyle: TextStyle(fontSize: 12, color: subtextColor),
                      prefixIcon: const Icon(Icons.search, size: 18),
                      contentPadding: EdgeInsets.zero,
                      filled: true,
                      fillColor: isDark ? const Color(0xFF0F172A) : const Color(0xFFF8FAFC),
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: BorderSide(color: borderColor)),
                      enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: BorderSide(color: borderColor)),
                    ),
                  ),
                ),

                // Status & Waste Type Filters + Export
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    _buildFilterDropdown(
                      'Status',
                      _selectedStatus,
                      ['All', 'Completed', 'Pending', 'In-Transit', 'Cancelled'],
                      (val) => setState(() => _selectedStatus = val!),
                      cardColor,
                      borderColor,
                      textColor,
                      subtextColor,
                    ),
                    const SizedBox(width: 8),
                    _buildFilterDropdown(
                      'Waste Type',
                      _selectedWasteType,
                      ['All', 'General', 'Commercial', 'Organic', 'Plastic', 'Heavy'],
                      (val) => setState(() => _selectedWasteType = val!),
                      cardColor,
                      borderColor,
                      textColor,
                      subtextColor,
                    ),
                    const SizedBox(width: 8),
                    OutlinedButton.icon(
                      onPressed: () => EcoRouteState.instance.exportCollectionAuditCsv(context),
                      icon: const Icon(Icons.download, size: 16),
                      label: const Text('Export CSV', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: brandGreen,
                        side: const BorderSide(color: brandGreen),
                        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),

          const SizedBox(height: 16),

          // Requests Data Table or Empty State
          Container(
            width: double.infinity,
            decoration: BoxDecoration(
              color: cardColor,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: borderColor),
            ),
            child: filtered.isEmpty
                ? Padding(
                    padding: const EdgeInsets.all(48),
                    child: Center(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.inbox_outlined, size: 40, color: subtextColor),
                          const SizedBox(height: 12),
                          Text('No Collection Requests Found', style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: textColor)),
                          const SizedBox(height: 4),
                          Text('No service requests match your search or have been logged yet.', style: TextStyle(fontSize: 12, color: subtextColor)),
                        ],
                      ),
                    ),
                  )
                : SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: DataTable(
                      columns: const [
                        DataColumn(label: Text('ID', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12))),
                        DataColumn(label: Text('Client', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12))),
                        DataColumn(label: Text('Waste Type', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12))),
                        DataColumn(label: Text('Status', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12))),
                        DataColumn(label: Text('Address', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12))),
                        DataColumn(label: Text('Payment', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12))),
                      ],
                      rows: filtered.map((req) {
                        final status = req['status'] ?? 'Pending';
                        return DataRow(
                          cells: [
                            DataCell(Text(req['id']?.toString() ?? 'REQ', style: const TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF2E7D32), fontSize: 12))),
                            DataCell(Text(req['residentName'] ?? req['client'] ?? 'Client', style: const TextStyle(fontSize: 12))),
                            DataCell(Text(req['wasteType'] ?? 'General', style: const TextStyle(fontSize: 12))),
                            DataCell(
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                decoration: BoxDecoration(
                                  color: const Color(0xFFE8F5E9),
                                  borderRadius: BorderRadius.circular(4),
                                ),
                                child: Text(status, style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Color(0xFF2E7D32))),
                              ),
                            ),
                            DataCell(Text(req['address']?.toString() ?? 'Arua Municipality', style: const TextStyle(fontSize: 12))),
                            DataCell(Text('${req['totalPrice'] ?? req['payment'] ?? 0} UGX', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12))),
                          ],
                        );
                      }).toList(),
                    ),
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildKpiCard(
    String title,
    String value,
    String badge,
    List<double> sparkPoints,
    Color color,
    Color cardColor,
    Color borderColor,
    Color textColor,
    Color subtextColor,
  ) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: cardColor,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: borderColor),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(title, style: TextStyle(fontSize: 12, color: subtextColor)),
              const SizedBox(height: 4),
              Text(value, style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: textColor)),
            ],
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
            decoration: BoxDecoration(
              color: color.withOpacity(0.12),
              borderRadius: BorderRadius.circular(6),
            ),
            child: Text(badge, style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: color)),
          ),
        ],
      ),
    );
  }

  Widget _buildFilterDropdown(
    String label,
    String value,
    List<String> items,
    ValueChanged<String?> onChanged,
    Color cardColor,
    Color borderColor,
    Color textColor,
    Color subtextColor,
  ) {
    return Container(
      height: 38,
      padding: const EdgeInsets.symmetric(horizontal: 10),
      decoration: BoxDecoration(
        color: cardColor,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: borderColor),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          value: value,
          onChanged: onChanged,
          items: items.map((e) => DropdownMenuItem(value: e, child: Text(e, style: TextStyle(fontSize: 12, color: textColor)))).toList(),
        ),
      ),
    );
  }
}
