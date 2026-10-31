import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../core/theme/eco_palette.dart';

/// 07_RIDER_EARNINGS: My Earnings view with balance, interactive bar chart, and payout action
class EarningsScreen extends StatefulWidget {
  const EarningsScreen({super.key});

  @override
  State<EarningsScreen> createState() => _EarningsScreenState();
}

class _EarningsScreenState extends State<EarningsScreen> {
  int _balanceUgx = 54350;
  bool _payoutRequested = false;

  void _handleRequestPayout() {
    HapticFeedback.mediumImpact();
    showModalBottomSheet<void>(
      context: context,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => Padding(
        padding: const EdgeInsets.fromLTRB(24, 20, 24, 32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Center(
              child: Container(
                width: 36,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.grey[300],
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const SizedBox(height: 18),
            const Text(
              'Request Instant Mobile Money Payout',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontFamily: 'Satoshi',
                fontSize: 19,
                fontWeight: FontWeight.w800,
                color: EcoPalette.primaryDark,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Your total balance of ${_formatUgx(_balanceUgx)} will be deposited directly to your registered MTN / Airtel Mobile Money wallet in Arua.',
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontFamily: 'Satoshi',
                fontSize: 13.5,
                color: Color(0xFF63786B),
              ),
            ),
            const SizedBox(height: 24),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: EcoPalette.surface,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: EcoPalette.cardBorder),
              ),
              child: Column(
                children: [
                  _payoutRow('Total Withdrawable', _formatUgx(_balanceUgx), isBold: true),
                  const SizedBox(height: 8),
                  _payoutRow('Disbursement Fee', '0 UGX (Subsidized)'),
                  const SizedBox(height: 8),
                  _payoutRow('Target Account', '+256 772 ••• 981 (MTN MoMo)'),
                ],
              ),
            ),
            const SizedBox(height: 24),
            SizedBox(
              height: 50,
              child: FilledButton(
                key: const ValueKey('confirm_payout_btn'),
                onPressed: () {
                  Navigator.of(ctx).pop();
                  setState(() {
                    _payoutRequested = true;
                    _balanceUgx = 0;
                  });
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      backgroundColor: EcoPalette.primaryDark,
                      content: Text(
                        'Payout request dispatched! Funds will reflect within 10 minutes.',
                        style: TextStyle(fontFamily: 'Satoshi'),
                      ),
                    ),
                  );
                },
                style: FilledButton.styleFrom(
                  backgroundColor: EcoPalette.buttonDark,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                ),
                child: const Text(
                  'Confirm Transfer',
                  style: TextStyle(fontFamily: 'Satoshi', fontSize: 16, fontWeight: FontWeight.w700),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  static Widget _payoutRow(String label, String value, {bool isBold = false}) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: const TextStyle(fontFamily: 'Satoshi', fontSize: 13, color: EcoPalette.secondaryDark),
        ),
        Text(
          value,
          style: TextStyle(
            fontFamily: 'Satoshi',
            fontSize: 13.5,
            fontWeight: isBold ? FontWeight.w800 : FontWeight.w600,
            color: EcoPalette.primaryDark,
          ),
        ),
      ],
    );
  }

  static String _formatUgx(int amount) {
    final str = amount.toString();
    final buffer = StringBuffer();
    for (int i = 0; i < str.length; i++) {
      if (i > 0 && (str.length - i) % 3 == 0) buffer.write(',');
      buffer.write(str[i]);
    }
    return '${buffer.toString()} UGX';
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Screen Title
          const Text(
            'My Earnings',
            style: TextStyle(
              fontFamily: 'Satoshi',
              fontSize: 22,
              fontWeight: FontWeight.w900,
              color: EcoPalette.primaryDark,
              letterSpacing: -0.3,
            ),
          ),
          const SizedBox(height: 16),

          // Total Balance Card
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 22),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(18),
              border: Border.all(color: EcoPalette.cardBorder),
              boxShadow: const [
                BoxShadow(
                  color: Color(0x0A000000),
                  blurRadius: 10,
                  offset: Offset(0, 4),
                ),
              ],
            ),
            child: Column(
              children: [
                const Text(
                  'Total Balance',
                  style: TextStyle(
                    fontFamily: 'Satoshi',
                    fontSize: 13.5,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF6B8073),
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  _formatUgx(_balanceUgx),
                  style: const TextStyle(
                    fontFamily: 'Satoshi',
                    fontSize: 32,
                    fontWeight: FontWeight.w900,
                    color: EcoPalette.primaryDark,
                    letterSpacing: -0.5,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  _payoutRequested
                      ? 'Payout in progress (54,350 UGX)'
                      : 'Last Payout: 48,000 UGX (3 days ago)',
                  style: const TextStyle(
                    fontFamily: 'Satoshi',
                    fontSize: 12.5,
                    color: Color(0xFF8A9B8F),
                  ),
                ),
                const SizedBox(height: 18),
                SizedBox(
                  width: double.infinity,
                  height: 48,
                  child: FilledButton(
                    key: const ValueKey('request_payout_button'),
                    onPressed: _balanceUgx > 0 ? _handleRequestPayout : null,
                    style: FilledButton.styleFrom(
                      backgroundColor: EcoPalette.buttonDark,
                      foregroundColor: Colors.white,
                      disabledBackgroundColor: Colors.grey[300],
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      elevation: 0,
                    ),
                    child: const Text(
                      'Request Payout',
                      style: TextStyle(
                        fontFamily: 'Satoshi',
                        fontSize: 15,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),

          // Today Transactions Section
          const Text(
            'Today',
            style: TextStyle(
              fontFamily: 'Satoshi',
              fontSize: 15,
              fontWeight: FontWeight.w800,
              color: EcoPalette.primaryDark,
            ),
          ),
          const SizedBox(height: 10),

          _buildTransactionItem(
            title: 'Pickup #251985',
            subtitle: 'Jane A. • 2,500 UGX',
            date: 'Date: 23, 2022, 07:35 AM',
            isBonus: false,
          ),
          const SizedBox(height: 10),

          _buildTransactionItem(
            title: 'Pickup #251986',
            subtitle: 'John B. • 5,000 UGX',
            date: 'Date: 23, 2022, 07:35 AM',
            isBonus: false,
          ),
          const SizedBox(height: 10),

          _buildTransactionItem(
            title: 'Batch Bonus: +3 Pickups',
            subtitle: '1,500 UGX',
            date: 'Date: 10, 2022, 07:35 PM',
            isBonus: true,
          ),
          const SizedBox(height: 24),

          // Yesterday Section & Weekly Earnings Bar Chart
          const Text(
            'Yesterday',
            style: TextStyle(
              fontFamily: 'Satoshi',
              fontSize: 15,
              fontWeight: FontWeight.w800,
              color: EcoPalette.primaryDark,
            ),
          ),
          const SizedBox(height: 12),

          // Weekly Bar Chart Container
          Container(
            padding: const EdgeInsets.fromLTRB(16, 20, 16, 16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: EcoPalette.cardBorder),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Weekly Performance (UGX)',
                  style: TextStyle(
                    fontFamily: 'Satoshi',
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    color: Color(0xFF6B8073),
                  ),
                ),
                const SizedBox(height: 20),
                SizedBox(
                  height: 150,
                  child: BarChart(
                    BarChartData(
                      maxY: 30000,
                      barTouchData: BarTouchData(
                        enabled: true,
                        touchTooltipData: BarTouchTooltipData(
                          getTooltipItem: (group, groupIndex, rod, rodIndex) {
                            final days = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
                            return BarTooltipItem(
                              '${days[group.x.toInt()]}\n${rod.toY.toInt()} UGX',
                              const TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                                fontSize: 11,
                                fontFamily: 'Satoshi',
                              ),
                            );
                          },
                        ),
                      ),
                      titlesData: FlTitlesData(
                        show: true,
                        topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                        rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                        leftTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                        bottomTitles: AxisTitles(
                          sideTitles: SideTitles(
                            showTitles: true,
                            getTitlesWidget: (value, meta) {
                              const days = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
                              if (value.toInt() >= 0 && value.toInt() < days.length) {
                                return Padding(
                                  padding: const EdgeInsets.only(top: 8.0),
                                  child: Text(
                                    days[value.toInt()],
                                    style: const TextStyle(
                                      fontFamily: 'Satoshi',
                                      fontSize: 11,
                                      fontWeight: FontWeight.w600,
                                      color: Color(0xFF75887C),
                                    ),
                                  ),
                                );
                              }
                              return const SizedBox.shrink();
                            },
                          ),
                        ),
                      ),
                      gridData: FlGridData(
                        show: true,
                        drawVerticalLine: false,
                        horizontalInterval: 7500,
                        getDrawingHorizontalLine: (value) => const FlLine(
                          color: Color(0xFFEEF2EF),
                          strokeWidth: 1,
                        ),
                      ),
                      borderData: FlBorderData(show: false),
                      barGroups: [
                        _makeGroupData(0, 12000),
                        _makeGroupData(1, 19500),
                        _makeGroupData(2, 14200),
                        _makeGroupData(3, 24500),
                        _makeGroupData(4, 28000),
                        _makeGroupData(5, 17800),
                        _makeGroupData(6, 8500),
                      ],
                    ),
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

  static BarChartGroupData _makeGroupData(int x, double y) {
    return BarChartGroupData(
      x: x,
      barRods: [
        BarChartRodData(
          toY: y,
          color: const Color(0xFF7E9C88),
          width: 16,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(4)),
        ),
      ],
    );
  }

  Widget _buildTransactionItem({
    required String title,
    required String subtitle,
    required String date,
    required bool isBonus,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: EcoPalette.cardBorder),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    fontFamily: 'Satoshi',
                    fontSize: 14,
                    fontWeight: FontWeight.w800,
                    color: isBonus ? EcoPalette.primaryDark : EcoPalette.accentTerracotta,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  subtitle,
                  style: const TextStyle(
                    fontFamily: 'Satoshi',
                    fontSize: 12.5,
                    fontWeight: FontWeight.w600,
                    color: EcoPalette.secondaryDark,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  date,
                  style: const TextStyle(
                    fontFamily: 'Satoshi',
                    fontSize: 11,
                    color: Color(0xFF90A195),
                  ),
                ),
              ],
            ),
          ),
          const Icon(Icons.chevron_right_rounded, size: 20, color: Color(0xFFB0BFB5)),
        ],
      ),
    );
  }
}
