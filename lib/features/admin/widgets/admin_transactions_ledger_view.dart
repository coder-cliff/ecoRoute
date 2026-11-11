import 'package:flutter/material.dart';
import '../../../main.dart';

/// Screen 8: Transactions & Financial Ledger View
/// Dynamic - strictly reflects real completed delivery and collection transactions with zero mock data.
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

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final state = EcoRouteState.instance;
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    final allTransactions = state.riderTransactions;

    // Calculate dynamic financials
    int totalRevenue = 0;
    int momoRevenue = 0;
    int cardRevenue = 0;

    for (final t in allTransactions) {
      final amt = (t['amount'] as num?)?.toInt() ?? 0;
      totalRevenue += amt;
      final method = (t['paymentMethod'] ?? t['method'] ?? '').toString().toLowerCase();
      if (method.contains('mobile') || method.contains('momo')) {
        momoRevenue += amt;
      } else {
        cardRevenue += amt;
      }
    }

    final query = _searchController.text.trim().toLowerCase();
    final filtered = allTransactions.where((t) {
      final id = (t['id'] ?? '').toString().toLowerCase();
      final client = (t['residentName'] ?? t['client'] ?? '').toString().toLowerCase();
      final method = (t['paymentMethod'] ?? t['method'] ?? 'Mobile Money').toString();

      final matchesSearch = query.isEmpty || id.contains(query) || client.contains(query);
      final matchesMethod = _selectedPaymentMethod == 'All' || method == _selectedPaymentMethod;
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
                    value: 'UGX $totalRevenue',
                    icon: Icons.bar_chart,
                    iconColor: const Color(0xFF2E7D32),
                    iconBg: const Color(0xFFE8F5E9),
                    isDark: isDark,
                  ),
                  _buildFinancialKpiCard(
                    title: 'Completed Transactions',
                    value: '${allTransactions.length}',
                    icon: Icons.trending_up,
                    iconColor: const Color(0xFF2E7D32),
                    iconBg: const Color(0xFFE8F5E9),
                    isDark: isDark,
                  ),
                  _buildFinancialKpiCard(
                    title: 'Mobile Money',
                    value: 'UGX $momoRevenue',
                    icon: Icons.phone_android,
                    iconColor: const Color(0xFF16A34A),
                    iconBg: const Color(0xFFDCFCE7),
                    isDark: isDark,
                  ),
                  _buildFinancialKpiCard(
                    title: 'Card Payments',
                    value: 'UGX $cardRevenue',
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

                // Payment Method Filter & CSV Export
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
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

          // Ledger Table Container or Empty State
          Container(
            decoration: BoxDecoration(
              color: isDark ? const Color(0xFF1E293B) : Colors.white,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0),
              ),
            ),
            child: currentRows.isEmpty
                ? Padding(
                    padding: const EdgeInsets.all(48),
                    child: Center(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.receipt_long_outlined, size: 40, color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B)),
                          const SizedBox(height: 12),
                          Text(
                            'No Transaction Records Found',
                            style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: isDark ? Colors.white : const Color(0xFF1E293B)),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            'No collection settlements or payments have been recorded yet.',
                            style: TextStyle(fontSize: 12, color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B)),
                          ),
                        ],
                      ),
                    ),
                  )
                : Column(
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
                            DataColumn(label: Text('Client', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12))),
                            DataColumn(label: Text('Amount (UGX)', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12))),
                            DataColumn(label: Text('Payment Method', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12))),
                            DataColumn(label: Text('Status', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12))),
                          ],
                          rows: currentRows.map((t) {
                            final method = t['paymentMethod'] ?? t['method'] ?? 'Mobile Money';
                            final isMomo = method.toString().toLowerCase().contains('mobile') || method.toString().toLowerCase().contains('momo');
                            return DataRow(
                              cells: [
                                DataCell(
                                  Text(
                                    t['id']?.toString() ?? 'TRX',
                                    style: const TextStyle(
                                      fontWeight: FontWeight.bold,
                                      color: Color(0xFF2E7D32),
                                      fontSize: 12,
                                    ),
                                  ),
                                ),
                                DataCell(Text(t['client'] ?? t['residentName'] ?? 'Client', style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 12))),
                                DataCell(
                                  Text(
                                    '${t['amount'] ?? 0}',
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
                                      color: isMomo ? const Color(0xFFDCFCE7) : const Color(0xFFDBEAFE),
                                      borderRadius: BorderRadius.circular(4),
                                    ),
                                    child: Text(
                                      method.toString(),
                                      style: TextStyle(
                                        fontSize: 11,
                                        fontWeight: FontWeight.w600,
                                        color: isMomo ? const Color(0xFF16A34A) : const Color(0xFF2563EB),
                                      ),
                                    ),
                                  ),
                                ),
                                DataCell(
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                    decoration: BoxDecoration(
                                      color: const Color(0xFFE8F5E9),
                                      borderRadius: BorderRadius.circular(4),
                                    ),
                                    child: const Text(
                                      'Successful',
                                      style: TextStyle(
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

                      // Pagination Row
                      Padding(
                        padding: const EdgeInsets.all(16),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              'Showing ${totalRows == 0 ? 0 : startIndex + 1}-$endIndex of $totalRows transactions',
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
                    fontSize: 18,
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
