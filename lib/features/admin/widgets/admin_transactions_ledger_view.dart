import 'package:flutter/material.dart';
import '../../../main.dart';

/// Screen 8: Transactions & Financial Ledger View (Image 8 & 10)
/// Financial audit ledger featuring 4 KPI metric cards, date range & payment method filtering,
/// transaction search, and CSV export.
class AdminTransactionsLedgerView extends StatefulWidget {
  const AdminTransactionsLedgerView({super.key});

  @override
  State<AdminTransactionsLedgerView> createState() => _AdminTransactionsLedgerViewState();
}

class _AdminTransactionsLedgerViewState extends State<AdminTransactionsLedgerView> {
  final TextEditingController _searchController = TextEditingController();
  String _selectedPaymentMethod = 'All';
  int _currentPage = 1;
  final int _rowsPerPage = 10;

  final List<Map<String, dynamic>> _allTransactions = [
    {
      'id': '#TRX-9482',
      'dateTime': '11 Nov 2026, 09:42 AM',
      'client': 'Ayiko Gift',
      'amount': '15,000',
      'method': 'Mobile Money',
      'status': 'Successful',
    },
    {
      'id': '#TRX-9481',
      'dateTime': '11 Nov 2026, 09:42 AM',
      'client': 'Gulu Logistics',
      'amount': '45,000',
      'method': 'Mobile Money',
      'status': 'Pending',
    },
    {
      'id': '#TRX-9480',
      'dateTime': '11 Nov 2026, 09:42 AM',
      'client': 'West Nile Traders',
      'amount': '30,000',
      'method': 'Card',
      'status': 'Successful',
    },
    {
      'id': '#TRX-9479',
      'dateTime': '11 Nov 2026, 09:42 AM',
      'client': 'Okello John',
      'amount': '20,000',
      'method': 'Mobile Money',
      'status': 'Successful',
    },
    {
      'id': '#TRX-9478',
      'dateTime': '11 Nov 2026, 09:42 AM',
      'client': 'Gulu Logistics',
      'amount': '30,000',
      'method': 'Card',
      'status': 'Refunded',
    },
    {
      'id': '#TRX-9477',
      'dateTime': '11 Nov 2026, 09:42 AM',
      'client': 'Arua Agri Hub',
      'amount': '50,000',
      'method': 'Mobile Money',
      'status': 'Pending',
    },
    {
      'id': '#TRX-9476',
      'dateTime': '11 Nov 2026, 09:42 AM',
      'client': 'Arua Agri Hub',
      'amount': '50,000',
      'method': 'Card',
      'status': 'Refunded',
    },
    {
      'id': '#TRX-9475',
      'dateTime': '11 Nov 2026, 09:15 AM',
      'client': 'White Rhino Hotel',
      'amount': '65,000',
      'method': 'Mobile Money',
      'status': 'Successful',
    },
    {
      'id': '#TRX-9474',
      'dateTime': '11 Nov 2026, 08:50 AM',
      'client': 'Heritage Park Res.',
      'amount': '35,000',
      'method': 'Card',
      'status': 'Successful',
    },
    {
      'id': '#TRX-9473',
      'dateTime': '11 Nov 2026, 08:20 AM',
      'client': 'Eco Waste Recyclers',
      'amount': '80,000',
      'method': 'Mobile Money',
      'status': 'Successful',
    },
    {
      'id': '#TRX-9472',
      'dateTime': '11 Nov 2026, 07:45 AM',
      'client': 'Arua Hill Secondary',
      'amount': '40,000',
      'method': 'Mobile Money',
      'status': 'Successful',
    },
    {
      'id': '#TRX-9471',
      'dateTime': '11 Nov 2026, 07:10 AM',
      'client': 'Onduparaka Market',
      'amount': '55,000',
      'method': 'Card',
      'status': 'Successful',
    },
  ];

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    final query = _searchController.text.trim().toLowerCase();
    final filtered = _allTransactions.where((t) {
      final matchesSearch = query.isEmpty ||
          t['id'].toString().toLowerCase().contains(query) ||
          t['client'].toString().toLowerCase().contains(query);
      final matchesMethod = _selectedPaymentMethod == 'All' ||
          t['method'] == _selectedPaymentMethod;
      return matchesSearch && matchesMethod;
    }).toList();

    final totalRows = filtered.length;
    final totalPages = (totalRows / _rowsPerPage).ceil().clamp(1, 999);
    final startIndex = (_currentPage - 1) * _rowsPerPage;
    final endIndex = (startIndex + _rowsPerPage).clamp(0, totalRows);
    final currentRows = totalRows > 0 ? filtered.sublist(startIndex, endIndex) : <Map<String, dynamic>>[];

    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Text(
            'Transactions & Financial Ledger',
            style: theme.textTheme.headlineSmall?.copyWith(
              fontWeight: FontWeight.bold,
              color: isDark ? Colors.white : const Color(0xFF1E293B),
            ),
          ),
          const SizedBox(height: 4),
          Text(
            'Track, filter, and audit all delivery task transaction logs.',
            style: theme.textTheme.bodyMedium?.copyWith(
              color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B),
            ),
          ),
          const SizedBox(height: 24),

          // 4 Financial Metric Cards
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
                childAspectRatio: 2.1,
                children: [
                  _buildFinancialKpiCard(
                    title: 'Total Revenue',
                    value: 'UGX 1,540,000',
                    icon: Icons.bar_chart,
                    iconColor: const Color(0xFF2E7D32),
                    iconBg: const Color(0xFFE8F5E9),
                    isDark: isDark,
                  ),
                  _buildFinancialKpiCard(
                    title: 'Completed Transactions',
                    value: '74',
                    icon: Icons.trending_up,
                    iconColor: const Color(0xFF2E7D32),
                    iconBg: const Color(0xFFE8F5E9),
                    isDark: isDark,
                  ),
                  _buildFinancialKpiCard(
                    title: 'Mobile Money',
                    value: 'UGX 1,120,000',
                    icon: Icons.phone_android,
                    iconColor: const Color(0xFF16A34A),
                    iconBg: const Color(0xFFDCFCE7),
                    isDark: isDark,
                  ),
                  _buildFinancialKpiCard(
                    title: 'Card Payments',
                    value: 'UGX 420,000',
                    icon: Icons.credit_card,
                    iconColor: const Color(0xFF2563EB),
                    iconBg: const Color(0xFFDBEAFE),
                    isDark: isDark,
                  ),
                ],
              );
            },
          ),
          const SizedBox(height: 24),

          // Search & Filter Toolbar
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: isDark ? const Color(0xFF1E293B) : Colors.white,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0),
              ),
            ),
            child: Wrap(
              spacing: 12,
              runSpacing: 12,
              alignment: WrapAlignment.spaceBetween,
              crossAxisAlignment: WrapCrossAlignment.center,
              children: [
                // Search Input
                SizedBox(
                  width: 300,
                  height: 40,
                  child: TextField(
                    controller: _searchController,
                    onChanged: (val) => setState(() => _currentPage = 1),
                    decoration: InputDecoration(
                      hintText: 'Filter by Client or ID...',
                      hintStyle: TextStyle(
                        fontSize: 13,
                        color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B),
                      ),
                      prefixIcon: const Icon(Icons.search, size: 18),
                      filled: true,
                      fillColor: isDark ? const Color(0xFF0F172A) : const Color(0xFFF8FAFC),
                      contentPadding: EdgeInsets.zero,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                        borderSide: BorderSide(
                          color: isDark ? const Color(0xFF334155) : const Color(0xFFCBD5E1),
                        ),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                        borderSide: BorderSide(
                          color: isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0),
                        ),
                      ),
                    ),
                    style: const TextStyle(fontSize: 13),
                  ),
                ),

                // Date Range Button, Method Filter & CSV Export
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // Date Range Trigger
                    OutlinedButton.icon(
                      onPressed: () {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('Date Range selected: Last 30 Days')),
                        );
                      },
                      icon: const Icon(Icons.calendar_today, size: 14),
                      label: const Text('Date Range', style: TextStyle(fontSize: 12)),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: isDark ? Colors.white : const Color(0xFF1E293B),
                        side: BorderSide(
                          color: isDark ? const Color(0xFF334155) : const Color(0xFFCBD5E1),
                        ),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                      ),
                    ),
                    const SizedBox(width: 8),

                    // Payment Method Dropdown
                    Container(
                      height: 40,
                      padding: const EdgeInsets.symmetric(horizontal: 12),
                      decoration: BoxDecoration(
                        color: isDark ? const Color(0xFF0F172A) : const Color(0xFFF8FAFC),
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(
                          color: isDark ? const Color(0xFF334155) : const Color(0xFFCBD5E1),
                        ),
                      ),
                      child: DropdownButtonHideUnderline(
                        child: DropdownButton<String>(
                          value: _selectedPaymentMethod,
                          dropdownColor: isDark ? const Color(0xFF1E293B) : Colors.white,
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w500,
                            color: isDark ? Colors.white : const Color(0xFF1E293B),
                          ),
                          items: const [
                            DropdownMenuItem(value: 'All', child: Text('Payment Method: All')),
                            DropdownMenuItem(value: 'Mobile Money', child: Text('Mobile Money')),
                            DropdownMenuItem(value: 'Card', child: Text('Card')),
                          ],
                          onChanged: (val) {
                            if (val != null) {
                              setState(() {
                                _selectedPaymentMethod = val;
                                _currentPage = 1;
                              });
                            }
                          },
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),

                    // Export CSV Button
                    OutlinedButton.icon(
                      onPressed: () => EcoRouteState.instance.exportCollectionAuditCsv(context),
                      icon: const Icon(Icons.download, size: 15, color: Color(0xFF2E7D32)),
                      label: const Text(
                        'Export CSV',
                        style: TextStyle(
                          fontSize: 12,
                          color: Color(0xFF2E7D32),
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      style: OutlinedButton.styleFrom(
                        side: const BorderSide(color: Color(0xFF2E7D32)),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),

          // Ledger Table Container
          Container(
            decoration: BoxDecoration(
              color: isDark ? const Color(0xFF1E293B) : Colors.white,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0),
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: DataTable(
                    headingRowColor: MaterialStateProperty.all(
                      isDark ? const Color(0xFF0F172A) : const Color(0xFFF8FAFC),
                    ),
                    columns: const [
                      DataColumn(label: Text('Ledger ID', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12))),
                      DataColumn(label: Text('Date & Time', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12))),
                      DataColumn(label: Text('Client', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12))),
                      DataColumn(label: Text('Amount (UGX)', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12))),
                      DataColumn(label: Text('Payment Method', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12))),
                      DataColumn(label: Text('Status', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12))),
                    ],
                    rows: currentRows.map((t) {
                      final isMomo = t['method'] == 'Mobile Money';
                      final status = t['status'];
                      Color statusBg = const Color(0xFFE8F5E9);
                      Color statusColor = const Color(0xFF2E7D32);
                      if (status == 'Pending') {
                        statusBg = const Color(0xFFFEF3C7);
                        statusColor = const Color(0xFFB45309);
                      } else if (status == 'Refunded') {
                        statusBg = const Color(0xFFF1F5F9);
                        statusColor = const Color(0xFF64748B);
                      }

                      return DataRow(
                        cells: [
                          DataCell(
                            Text(
                              t['id'],
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                                color: Color(0xFF2E7D32),
                                fontSize: 12,
                              ),
                            ),
                          ),
                          DataCell(Text(t['dateTime'], style: const TextStyle(fontSize: 12))),
                          DataCell(Text(t['client'], style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 12))),
                          DataCell(
                            Text(
                              t['amount'],
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 12,
                              ),
                            ),
                          ),
                          DataCell(
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                              decoration: BoxDecoration(
                                color: isMomo
                                    ? const Color(0xFFDCFCE7)
                                    : const Color(0xFFDBEAFE),
                                borderRadius: BorderRadius.circular(4),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(
                                    isMomo ? Icons.phone_android : Icons.credit_card,
                                    size: 13,
                                    color: isMomo ? const Color(0xFF16A34A) : const Color(0xFF2563EB),
                                  ),
                                  const SizedBox(width: 4),
                                  Text(
                                    t['method'],
                                    style: TextStyle(
                                      fontSize: 11,
                                      fontWeight: FontWeight.w600,
                                      color: isMomo ? const Color(0xFF16A34A) : const Color(0xFF2563EB),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                          DataCell(
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                              decoration: BoxDecoration(
                                color: statusBg,
                                borderRadius: BorderRadius.circular(4),
                              ),
                              child: Text(
                                status,
                                style: TextStyle(
                                  fontSize: 11,
                                  fontWeight: FontWeight.bold,
                                  color: statusColor,
                                ),
                              ),
                            ),
                          ),
                        ],
                      );
                    }).toList(),
                  ),
                ),

                // Pagination Row
                Padding(
                  padding: const EdgeInsets.all(16),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Showing ${totalRows == 0 ? 0 : startIndex + 1}-${endIndex} of 74 transactions',
                        style: TextStyle(
                          fontSize: 12,
                          color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B),
                        ),
                      ),
                      Row(
                        children: [
                          TextButton(
                            onPressed: _currentPage > 1
                                ? () => setState(() => _currentPage--)
                                : null,
                            child: const Text('Previous'),
                          ),
                          const SizedBox(width: 8),
                          TextButton(
                            onPressed: _currentPage < totalPages
                                ? () => setState(() => _currentPage++)
                                : null,
                            child: const Text('Next >'),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),
        ],
      ),
    );
  }

  Widget _buildFinancialKpiCard({
    required String title,
    required String value,
    required IconData icon,
    required Color iconColor,
    required Color iconBg,
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
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                    color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B),
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 6),
                Text(
                  value,
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: isDark ? Colors.white : const Color(0xFF1E293B),
                  ),
                ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: iconBg,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(icon, size: 22, color: iconColor),
          ),
        ],
      ),
    );
  }
}
