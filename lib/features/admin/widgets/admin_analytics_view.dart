import 'package:flutter/material.dart';

import '../../../core/utils/formatters.dart';
import '../../../domain/entities/pickup_request.dart';
import '../../../domain/enums/request_status.dart';
import '../../../domain/enums/waste_type.dart';
import '../../../domain/enums/zone.dart';

class AdminAnalyticsView extends StatelessWidget {
  const AdminAnalyticsView({
    required this.orders,
    super.key,
  });

  final List<PickupRequest> orders;

  int _countStatus(RequestStatus status) =>
      orders.where((o) => o.status == status).length;

  int _sumRevenue(RequestStatus status) => orders
      .where((o) => o.status == status)
      .fold<int>(0, (sum, o) => sum + o.priceUgx);

  int _sumSacks(RequestStatus? status) {
    final list = status == null ? orders : orders.where((o) => o.status == status);
    return list.fold<int>(0, (sum, o) => sum + o.sackCount);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    final settledRevenue = _sumRevenue(RequestStatus.paid);
    final pendingRevenue = _sumRevenue(RequestStatus.awaitingVerification) +
        _sumRevenue(RequestStatus.collected);
    final totalPotentialRevenue = orders.fold<int>(0, (sum, o) => sum + o.priceUgx);
    final totalSacks = _sumSacks(null);
    final completedSacks = _sumSacks(RequestStatus.paid) + _sumSacks(RequestStatus.collected);
    final completionRate = orders.isEmpty
        ? 0
        : (((_countStatus(RequestStatus.paid) + _countStatus(RequestStatus.collected)) /
                    orders.length) *
                100)
            .round();

    // Commercial Private Ledger: Cash in Hand vs Direct MoMo vs 70/30 Split
    final cashCollected = orders
        .where((o) => o.cashReceivedByRider)
        .fold<int>(0, (sum, o) => sum + o.priceUgx);
    final momoCollected = (settledRevenue - cashCollected).clamp(0, 999999999);
    final riderPayout = (settledRevenue * 0.70).round();
    final companyGrossMargin = settledRevenue - riderPayout;
    final netRiderRemittance = cashCollected - riderPayout;

    final cardBg = isDark ? const Color(0xFF192A1D) : Colors.white;
    final cardBorder = isDark ? const Color(0xFF2A3F2F) : const Color(0xFFE2EAE1);
    final subtextColor = isDark ? const Color(0xFF9EABA1) : const Color(0xFF647568);

    if (orders.isEmpty) {
      return Container(
        padding: const EdgeInsets.all(28),
        decoration: BoxDecoration(
          color: cardBg,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: cardBorder),
        ),
        child: Center(
          child: Column(
            children: [
              Icon(Icons.bar_chart_rounded, size: 48, color: subtextColor),
              const SizedBox(height: 12),
              Text(
                'No collection data recorded yet.',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                  color: isDark ? Colors.white : const Color(0xFF183B20),
                ),
              ),
              const SizedBox(height: 6),
              Text(
                'Live business charts will populate automatically as residents submit pickup requests.',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 12, color: subtextColor),
              ),
            ],
          ),
        ),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // 1. High-Level Financial & Volume KPI Matrix
        Row(
          children: [
            Expanded(
              child: _MetricTile(
                title: 'Settled Revenue',
                value: formatUgx(settledRevenue),
                subtitle: '${_countStatus(RequestStatus.paid)} verified orders',
                icon: Icons.payments_rounded,
                color: const Color(0xFF2E7D32),
                isDark: isDark,
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: _MetricTile(
                title: 'Pending Pipeline',
                value: formatUgx(pendingRevenue),
                subtitle: 'Awaiting clearance',
                icon: Icons.pending_actions_rounded,
                color: const Color(0xFFE65100),
                isDark: isDark,
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        Row(
          children: [
            Expanded(
              child: _MetricTile(
                title: 'Sack Throughput',
                value: '$completedSacks / $totalSacks',
                subtitle: 'Sacks cleared vs total',
                icon: Icons.delete_sweep_rounded,
                color: const Color(0xFF1B5E20),
                isDark: isDark,
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: _MetricTile(
                title: 'Completion Rate',
                value: '$completionRate%',
                subtitle: 'Operational efficiency',
                icon: Icons.speed_rounded,
                color: const Color(0xFF00796B),
                isDark: isDark,
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),

        // 2. Revenue Breakdown & Financial Reconciliation Card
        _ChartCard(
          title: 'Revenue Reconciliation (UGX)',
          subtitle: 'Cashflow status across current collection cycles',
          icon: Icons.account_balance_wallet_rounded,
          isDark: isDark,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Total Booked Value',
                    style: TextStyle(fontSize: 12, color: subtextColor),
                  ),
                  Text(
                    formatUgx(totalPotentialRevenue),
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w800,
                      color: isDark ? Colors.white : const Color(0xFF183B20),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              // Segmented Proportional Progress Bar
              ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: SizedBox(
                  height: 12,
                  child: Row(
                    children: [
                      if (settledRevenue > 0)
                        Flexible(
                          flex: settledRevenue,
                          child: Container(color: const Color(0xFF2E7D32)),
                        ),
                      if (pendingRevenue > 0)
                        Flexible(
                          flex: pendingRevenue,
                          child: Container(color: const Color(0xFFFFA000)),
                        ),
                      if (totalPotentialRevenue - settledRevenue - pendingRevenue > 0)
                        Flexible(
                          flex: (totalPotentialRevenue - settledRevenue - pendingRevenue).clamp(1, 99999999),
                          child: Container(color: isDark ? const Color(0xFF334A38) : const Color(0xFFD6E3D8)),
                        ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 12),
              Wrap(
                spacing: 16,
                runSpacing: 6,
                children: [
                  _LegendIndicator(
                    color: const Color(0xFF2E7D32),
                    label: 'Settled: ${formatUgx(settledRevenue)}',
                    isDark: isDark,
                  ),
                  _LegendIndicator(
                    color: const Color(0xFFFFA000),
                    label: 'Pending: ${formatUgx(pendingRevenue)}',
                    isDark: isDark,
                  ),
                  _LegendIndicator(
                    color: isDark ? const Color(0xFF334A38) : const Color(0xFFD6E3D8),
                    label: 'Unassigned: ${formatUgx(totalPotentialRevenue - settledRevenue - pendingRevenue)}',
                    isDark: isDark,
                  ),
                ],
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),

        // 2b. Commercial Net Margin & Cash-in-Hand Reconciliation (Private Logistics Model)
        _ChartCard(
          title: 'Commercial Profit Margin & Cash Reconciliation',
          subtitle: 'Private micro-fleet settlement: 30% EcoRoute margin vs 70% rider commission',
          icon: Icons.pie_chart_outline_rounded,
          isDark: isDark,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: const Color(0xFF1B5E3B).withValues(alpha: isDark ? 0.25 : 0.08),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: const Color(0xFF2E8B57).withValues(alpha: 0.3)),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'EcoRoute Margin (30%)',
                            style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: Color(0xFF2E7D32)),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            formatUgx(companyGrossMargin),
                            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w900, color: Color(0xFF1B5E20)),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: const Color(0xFF0288D1).withValues(alpha: isDark ? 0.25 : 0.08),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: const Color(0xFF0288D1).withValues(alpha: 0.3)),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Rider Payout (70%)',
                            style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: Color(0xFF0277BD)),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            formatUgx(riderPayout),
                            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w900, color: Color(0xFF01579B)),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              Row(
                children: [
                  Expanded(
                    child: Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: isDark ? const Color(0xFF222B24) : const Color(0xFFF7FAF7),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: cardBorder),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('Rider Cash in Hand', style: TextStyle(fontSize: 10.5, color: subtextColor)),
                          const SizedBox(height: 2),
                          Text(
                            formatUgx(cashCollected),
                            style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w800),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: isDark ? const Color(0xFF222B24) : const Color(0xFFF7FAF7),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: cardBorder),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('Direct MoMo (+256394880352)', style: TextStyle(fontSize: 10.5, color: subtextColor)),
                          const SizedBox(height: 2),
                          Text(
                            formatUgx(momoCollected),
                            style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w800),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                decoration: BoxDecoration(
                  color: isDark ? const Color(0xFF1E281F) : const Color(0xFFEEF5EF),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  children: [
                    Icon(Icons.info_outline_rounded, size: 14, color: subtextColor),
                    const SizedBox(width: 6),
                    Expanded(
                      child: Text(
                        netRiderRemittance > 0
                            ? 'Riders hold excess cash: ${formatUgx(netRiderRemittance)} to remit to EcoRoute collection line (+256 394 880 352).'
                            : netRiderRemittance < 0
                                ? 'EcoRoute payable to riders: ${formatUgx(netRiderRemittance.abs())} to disburse via MoMo.'
                                : 'Cash and digital accounts are fully balanced.',
                        style: TextStyle(fontSize: 10.5, fontWeight: FontWeight.w600, color: subtextColor),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),

        // 2c. Commercial B2B Wholesale Accounts & Tier Invoicing
        _ChartCard(
          title: 'Commercial B2B Accounts & Multi-Sack Revenue',
          subtitle: 'Wholesale tiered invoicing for hotels, canteens, and enterprise clients in Arua',
          icon: Icons.business_center_rounded,
          isDark: isDark,
          child: _buildCommercialB2BBreakdown(orders, isDark, cardBorder, subtextColor),
        ),
        const SizedBox(height: 16),

        // 3. Daily / Period Sack Volume Bar Chart
        _ChartCard(
          title: 'Sack Collection Volume Trend',
          subtitle: 'Volume collected grouped across recent requests',
          icon: Icons.stacked_bar_chart_rounded,
          isDark: isDark,
          child: _buildSackVolumeBars(orders, isDark),
        ),
        const SizedBox(height: 16),

        // 4. Waste Category Composition & Geographic Zone Distribution
        LayoutBuilder(
          builder: (context, constraints) {
            final isSideBySide = constraints.maxWidth >= 550;
            if (isSideBySide) {
              return Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: _ChartCard(
                      title: 'Waste Categories',
                      subtitle: 'Sacks by category',
                      icon: Icons.pie_chart_rounded,
                      isDark: isDark,
                      child: _buildCategoryBreakdown(orders, isDark),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _ChartCard(
                      title: 'Arua Municipal Zones',
                      subtitle: 'Distribution by sector',
                      icon: Icons.map_rounded,
                      isDark: isDark,
                      child: _buildZoneBreakdown(orders, isDark),
                    ),
                  ),
                ],
              );
            }
            return Column(
              children: [
                _ChartCard(
                  title: 'Waste Categories',
                  subtitle: 'Sacks by category',
                  icon: Icons.pie_chart_rounded,
                  isDark: isDark,
                  child: _buildCategoryBreakdown(orders, isDark),
                ),
                const SizedBox(height: 16),
                _ChartCard(
                  title: 'Arua Municipal Zones',
                  subtitle: 'Distribution by sector',
                  icon: Icons.map_rounded,
                  isDark: isDark,
                  child: _buildZoneBreakdown(orders, isDark),
                ),
              ],
            );
          },
        ),
        const SizedBox(height: 16),

        // 5. Status Pipeline Breakdown
        _ChartCard(
          title: 'Order Status Lifecycle',
          subtitle: 'All active and historic collection requests',
          icon: Icons.alt_route_rounded,
          isDark: isDark,
          child: Column(
            children: [
              for (final status in RequestStatus.values)
                _StatusProgressRow(
                  status: status,
                  count: _countStatus(status),
                  total: orders.length,
                  isDark: isDark,
                ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildSackVolumeBars(List<PickupRequest> orders, bool isDark) {
    // Group recent orders into 6 chronological cohorts for bar visualization
    final sorted = List<PickupRequest>.from(orders)
      ..sort((a, b) => a.submittedAt.compareTo(b.submittedAt));

    final groups = <String, int>{};
    if (sorted.length <= 6) {
      for (var i = 0; i < sorted.length; i++) {
        final label = 'Batch ${i + 1}';
        groups[label] = (groups[label] ?? 0) + sorted[i].sackCount;
      }
    } else {
      final chunkSize = (sorted.length / 6).ceil();
      for (var i = 0; i < sorted.length; i++) {
        final groupIndex = (i / chunkSize).floor();
        final label = 'Batch ${groupIndex + 1}';
        groups[label] = (groups[label] ?? 0) + sorted[i].sackCount;
      }
    }

    final maxVal = groups.values.fold<int>(1, (max, v) => v > max ? v : max);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          height: 130,
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              for (final entry in groups.entries) ...[
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 4),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        Text(
                          '${entry.value}s',
                          style: TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.w800,
                            color: isDark ? Colors.white70 : const Color(0xFF2E7D32),
                          ),
                        ),
                        const SizedBox(height: 4),
                        ClipRRect(
                          borderRadius: const BorderRadius.vertical(top: Radius.circular(6)),
                          child: Container(
                            height: (entry.value / maxVal * 80).clamp(8.0, 80.0),
                            color: entry.value == maxVal
                                ? const Color(0xFF2E7D32)
                                : (isDark ? const Color(0xFF3C5E43) : const Color(0xFF81C784)),
                          ),
                        ),
                        const SizedBox(height: 6),
                        Text(
                          entry.key,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            fontSize: 9,
                            color: isDark ? const Color(0xFF9EABA1) : const Color(0xFF647568),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildCategoryBreakdown(List<PickupRequest> orders, bool isDark) {
    final householdSacks = orders
        .where((o) => o.wasteType == WasteType.household)
        .fold<int>(0, (sum, o) => sum + o.sackCount);
    final tradingSacks = orders
        .where((o) => o.wasteType == WasteType.tradingCenter)
        .fold<int>(0, (sum, o) => sum + o.sackCount);
    final otherSacks = orders
        .where((o) => o.wasteType == WasteType.unknown)
        .fold<int>(0, (sum, o) => sum + o.sackCount);

    final total = householdSacks + tradingSacks + otherSacks;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _CategoryBar(
          label: 'Household',
          count: householdSacks,
          total: total,
          color: const Color(0xFF2E7D32),
          isDark: isDark,
        ),
        const SizedBox(height: 8),
        _CategoryBar(
          label: 'Trading Center',
          count: tradingSacks,
          total: total,
          color: const Color(0xFF1565C0),
          isDark: isDark,
        ),
        const SizedBox(height: 8),
        _CategoryBar(
          label: 'Bulky / Other',
          count: otherSacks,
          total: total,
          color: const Color(0xFFEF6C00),
          isDark: isDark,
        ),
      ],
    );
  }

  Widget _buildZoneBreakdown(List<PickupRequest> orders, bool isDark) {
    final zones = Zone.values;
    final total = orders.length;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        for (final z in zones) ...[
          _CategoryBar(
            label: z.label,
            count: orders.where((o) => o.zone == z).length,
            total: total,
            color: switch (z) {
              Zone.north => const Color(0xFF2E7D32),
              Zone.south => const Color(0xFF00897B),
              Zone.east => const Color(0xFF3949AB),
              Zone.west => const Color(0xFF8E24AA),
            },
            isDark: isDark,
            unit: 'orders',
          ),
          if (z != zones.last) const SizedBox(height: 8),
        ],
      ],
    );
  }

  Widget _buildCommercialB2BBreakdown(
    List<PickupRequest> orders,
    bool isDark,
    Color cardBorder,
    Color subtextColor,
  ) {
    final commercialOrders = orders.where((o) => o.isCommercial).toList();
    final commercialRevenue = commercialOrders.fold<int>(0, (sum, o) => sum + o.priceUgx);
    final residentialRevenue = orders.where((o) => !o.isCommercial).fold<int>(0, (sum, o) => sum + o.priceUgx);
    final commercialSacks = commercialOrders.fold<int>(0, (sum, o) => sum + o.sackCount);
    final residentialSacks = orders.where((o) => !o.isCommercial).fold<int>(0, (sum, o) => sum + o.sackCount);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(
              child: Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: const Color(0xFF1B5E3B).withValues(alpha: isDark ? 0.25 : 0.08),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: const Color(0xFF2E8B57).withValues(alpha: 0.3)),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Commercial B2B Revenue',
                      style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: Color(0xFF2E7D32)),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      formatUgx(commercialRevenue),
                      style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w900, color: Color(0xFF1B5E20)),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      '${commercialOrders.length} wholesale orders • $commercialSacks sacks',
                      style: TextStyle(fontSize: 10, color: subtextColor),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: isDark ? const Color(0xFF222B24) : const Color(0xFFF7FAF7),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: cardBorder),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Household Revenue',
                      style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: subtextColor),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      formatUgx(residentialRevenue),
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w900,
                        color: isDark ? Colors.white : const Color(0xFF183B20),
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      '${orders.length - commercialOrders.length} residential orders • $residentialSacks sacks',
                      style: TextStyle(fontSize: 10, color: subtextColor),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        if (commercialOrders.isEmpty)
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: isDark ? const Color(0xFF1E281F) : const Color(0xFFEEF5EF),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Row(
              children: [
                Icon(Icons.info_outline_rounded, size: 16, color: subtextColor),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'No commercial bulk accounts active yet. Orders from hotels, supermarkets, and market vendors will populate here with formal tax invoices.',
                    style: TextStyle(fontSize: 11, color: subtextColor),
                  ),
                ),
              ],
            ),
          )
        else ...[
          const Text(
            'Active Commercial Accounts & Invoices:',
            style: TextStyle(fontSize: 11.5, fontWeight: FontWeight.w800),
          ),
          const SizedBox(height: 6),
          for (final order in commercialOrders.take(5)) ...[
            Container(
              margin: const EdgeInsets.only(bottom: 6),
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
              decoration: BoxDecoration(
                color: isDark ? const Color(0xFF222B24) : const Color(0xFFF7FAF7),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: cardBorder),
              ),
              child: Row(
                children: [
                  Container(
                    width: 32,
                    height: 32,
                    decoration: BoxDecoration(
                      color: const Color(0xFFE8F5E9),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Icon(Icons.apartment_rounded, size: 18, color: Color(0xFF2E7D32)),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          order.businessName ?? order.residentName,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w800),
                        ),
                        Text(
                          '${order.serviceTier ?? 'Wholesale'} • ${order.sackCount} sacks${order.tinNumber != null ? ' • TIN: ${order.tinNumber}' : ''}',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(fontSize: 10, color: subtextColor),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 6),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text(
                        formatUgx(order.priceUgx),
                        style: const TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w800,
                          color: Color(0xFF1B5E20),
                        ),
                      ),
                      Text(
                        order.status.label,
                        style: TextStyle(fontSize: 9.5, fontWeight: FontWeight.w700, color: subtextColor),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ],
      ],
    );
  }
}

class _MetricTile extends StatelessWidget {
  const _MetricTile({
    required this.title,
    required this.value,
    required this.subtitle,
    required this.icon,
    required this.color,
    required this.isDark,
  });

  final String title;
  final String value;
  final String subtitle;
  final IconData icon;
  final Color color;
  final bool isDark;

  @override
  Widget build(BuildContext context) {
    final bg = isDark ? const Color(0xFF192A1D) : Colors.white;
    final border = isDark ? const Color(0xFF2A3F2F) : const Color(0xFFE2EAE1);

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(icon, size: 16, color: color),
              ),
              const Spacer(),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            value,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w900,
              color: isDark ? Colors.white : color,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            title,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w700,
              color: isDark ? const Color(0xFFC7D3C9) : const Color(0xFF183B20),
            ),
          ),
          Text(
            subtitle,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              fontSize: 9,
              color: isDark ? const Color(0xFF9EABA1) : const Color(0xFF647568),
            ),
          ),
        ],
      ),
    );
  }
}

class _ChartCard extends StatelessWidget {
  const _ChartCard({
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.child,
    required this.isDark,
  });

  final String title;
  final String subtitle;
  final IconData icon;
  final Widget child;
  final bool isDark;

  @override
  Widget build(BuildContext context) {
    final bg = isDark ? const Color(0xFF192A1D) : Colors.white;
    final border = isDark ? const Color(0xFF2A3F2F) : const Color(0xFFE2EAE1);

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, size: 16, color: const Color(0xFF2E7D32)),
              const SizedBox(width: 8),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w800,
                        color: isDark ? Colors.white : const Color(0xFF183B20),
                      ),
                    ),
                    Text(
                      subtitle,
                      style: TextStyle(
                        fontSize: 10,
                        color: isDark ? const Color(0xFF9EABA1) : const Color(0xFF647568),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          child,
        ],
      ),
    );
  }
}

class _LegendIndicator extends StatelessWidget {
  const _LegendIndicator({
    required this.color,
    required this.label,
    required this.isDark,
  });

  final Color color;
  final String label;
  final bool isDark;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 8,
          height: 8,
          decoration: BoxDecoration(color: color, shape: BoxShape.circle),
        ),
        const SizedBox(width: 6),
        Text(
          label,
          style: TextStyle(
            fontSize: 10,
            fontWeight: FontWeight.w600,
            color: isDark ? const Color(0xFFC7D3C9) : const Color(0xFF455A64),
          ),
        ),
      ],
    );
  }
}

class _CategoryBar extends StatelessWidget {
  const _CategoryBar({
    required this.label,
    required this.count,
    required this.total,
    required this.color,
    required this.isDark,
    this.unit = 'sacks',
  });

  final String label;
  final int count;
  final int total;
  final Color color;
  final bool isDark;
  final String unit;

  @override
  Widget build(BuildContext context) {
    final percent = total == 0 ? 0 : ((count / total) * 100).round();
    final fraction = total == 0 ? 0.0 : (count / total).clamp(0.0, 1.0);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Expanded(
              child: Text(
                label,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                  color: isDark ? Colors.white70 : const Color(0xFF263238),
                ),
              ),
            ),
            const SizedBox(width: 8),
            Text(
              '$count $unit ($percent%)',
              style: TextStyle(
                fontSize: 10,
                fontWeight: FontWeight.w700,
                color: isDark ? const Color(0xFF9EABA1) : const Color(0xFF546E7A),
              ),
            ),
          ],
        ),
        const SizedBox(height: 4),
        ClipRRect(
          borderRadius: BorderRadius.circular(4),
          child: SizedBox(
            height: 6,
            child: Stack(
              children: [
                Container(
                  color: isDark ? const Color(0xFF2E4633) : const Color(0xFFE8F0E9),
                  width: double.infinity,
                ),
                FractionallySizedBox(
                  widthFactor: fraction,
                  child: Container(color: color),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

class _StatusProgressRow extends StatelessWidget {
  const _StatusProgressRow({
    required this.status,
    required this.count,
    required this.total,
    required this.isDark,
  });

  final RequestStatus status;
  final int count;
  final int total;
  final bool isDark;

  @override
  Widget build(BuildContext context) {
    final proportion = total == 0 ? 0.0 : (count / total);
    final statusColor = switch (status) {
      RequestStatus.requested => const Color(0xFF1E88E5),
      RequestStatus.collected => const Color(0xFFFB8C00),
      RequestStatus.awaitingVerification => const Color(0xFF8E24AA),
      RequestStatus.paid => const Color(0xFF2E7D32),
      RequestStatus.cancelled => const Color(0xFFE53935),
    };

    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        children: [
          SizedBox(
            width: 120,
            child: Text(
              status.label,
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w600,
                color: isDark ? const Color(0xFFC7D3C9) : const Color(0xFF455A64),
              ),
            ),
          ),
          Expanded(
            child: ClipRRect(
              borderRadius: BorderRadius.circular(99),
              child: SizedBox(
                height: 8,
                child: Stack(
                  children: [
                    Container(
                      color: isDark ? const Color(0xFF2E4633) : const Color(0xFFEAF0E9),
                    ),
                    FractionallySizedBox(
                      alignment: Alignment.centerLeft,
                      widthFactor: proportion,
                      child: Container(color: statusColor),
                    ),
                  ],
                ),
              ),
            ),
          ),
          const SizedBox(width: 12),
          SizedBox(
            width: 28,
            child: Text(
              '$count',
              textAlign: TextAlign.end,
              style: TextStyle(
                fontWeight: FontWeight.w800,
                fontSize: 11,
                color: isDark ? Colors.white : const Color(0xFF183B20),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
