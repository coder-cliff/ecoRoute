import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../core/services/pdf_report_service.dart';
import '../../core/theme/eco_palette.dart';

/// 10_ADMIN_REPORTS: Analytics & Reports with fl_chart sparklines and client-side PDF generation
class ReportsScreen extends StatefulWidget {
  const ReportsScreen({super.key});

  @override
  State<ReportsScreen> createState() => _ReportsScreenState();
}

class _ReportsScreenState extends State<ReportsScreen> {
  String _dateRange = 'This Month';
  bool _isExporting = false;

  Future<void> _handleDownloadPdf(String title, String period) async {
    HapticFeedback.mediumImpact();
    setState(() => _isExporting = true);
    try {
      await PdfReportService.printOrShareReport(title: title, period: period);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            backgroundColor: EcoPalette.primaryDark,
            content: Text(
              'Generated $title ($period). PDF ready to share or save.',
              style: const TextStyle(fontFamily: 'Satoshi'),
            ),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            backgroundColor: Colors.redAccent,
            content: Text('Failed to generate PDF: $e', style: const TextStyle(fontFamily: 'Satoshi')),
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isExporting = false);
    }
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
            'Analytics & Reports',
            style: TextStyle(
              fontFamily: 'Satoshi',
              fontSize: 22,
              fontWeight: FontWeight.w900,
              color: EcoPalette.primaryDark,
              letterSpacing: -0.3,
            ),
          ),
          const SizedBox(height: 16),

          // Date Range & Filter Row
          Row(
            children: [
              Expanded(
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: EcoPalette.cardBorder),
                  ),
                  child: DropdownButtonHideUnderline(
                    child: DropdownButton<String>(
                      value: _dateRange,
                      icon: const Icon(Icons.keyboard_arrow_down_rounded, color: EcoPalette.primaryDark),
                      items: const [
                        DropdownMenuItem(value: 'Today', child: Text('Today')),
                        DropdownMenuItem(value: 'This Week', child: Text('This Week')),
                        DropdownMenuItem(value: 'This Month', child: Text('This Month')),
                        DropdownMenuItem(value: 'Last Quarter', child: Text('Last Quarter')),
                      ],
                      onChanged: (val) {
                        if (val != null) setState(() => _dateRange = val);
                      },
                      style: const TextStyle(
                        fontFamily: 'Satoshi',
                        fontSize: 13.5,
                        fontWeight: FontWeight.w700,
                        color: EcoPalette.primaryDark,
                      ),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              OutlinedButton.icon(
                onPressed: () {
                  HapticFeedback.selectionClick();
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      backgroundColor: EcoPalette.primaryDark,
                      content: Text('Filtered reports for $_dateRange', style: const TextStyle(fontFamily: 'Satoshi')),
                      duration: const Duration(seconds: 1),
                    ),
                  );
                },
                icon: const Icon(Icons.filter_list_rounded, size: 18),
                label: const Text('Filter', style: TextStyle(fontFamily: 'Satoshi', fontSize: 13)),
                style: OutlinedButton.styleFrom(
                  foregroundColor: EcoPalette.primaryDark,
                  side: const BorderSide(color: EcoPalette.cardBorder),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),

          // Performance Overview Section
          const Text(
            'Performance Overview',
            style: TextStyle(
              fontFamily: 'Satoshi',
              fontSize: 15,
              fontWeight: FontWeight.w800,
              color: EcoPalette.primaryDark,
            ),
          ),
          const SizedBox(height: 12),

          // Total Waste Collected Card with Sparkline
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: EcoPalette.cardBorder),
              boxShadow: const [
                BoxShadow(
                  color: Color(0x0A000000),
                  blurRadius: 10,
                  offset: Offset(0, 4),
                ),
              ],
            ),
            child: Row(
              children: [
                Expanded(
                  flex: 5,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Total Waste Collected',
                        style: TextStyle(
                          fontFamily: 'Satoshi',
                          fontSize: 12.5,
                          fontWeight: FontWeight.w600,
                          color: Color(0xFF6B8073),
                        ),
                      ),
                      const SizedBox(height: 4),
                      const Text(
                        '14.5 Tonnes',
                        style: TextStyle(
                          fontFamily: 'Satoshi',
                          fontSize: 22,
                          fontWeight: FontWeight.w900,
                          color: EcoPalette.primaryDark,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        '+12% vs last month',
                        style: TextStyle(
                          fontFamily: 'Satoshi',
                          fontSize: 11.5,
                          fontWeight: FontWeight.w700,
                          color: EcoPalette.onlineGreen,
                        ),
                      ),
                    ],
                  ),
                ),
                // Smooth mini Sparkline chart
                Expanded(
                  flex: 5,
                  child: SizedBox(
                    height: 55,
                    child: LineChart(
                      LineChartData(
                        gridData: const FlGridData(show: false),
                        titlesData: const FlTitlesData(show: false),
                        borderData: FlBorderData(show: false),
                        lineTouchData: const LineTouchData(enabled: false),
                        lineBarsData: [
                          LineChartBarData(
                            spots: const [
                              FlSpot(0, 8),
                              FlSpot(1, 10.5),
                              FlSpot(2, 9.8),
                              FlSpot(3, 12.2),
                              FlSpot(4, 11.0),
                              FlSpot(5, 13.8),
                              FlSpot(6, 14.5),
                            ],
                            isCurved: true,
                            color: EcoPalette.primaryDark,
                            barWidth: 2.5,
                            isStrokeCapRound: true,
                            dotData: const FlDotData(show: false),
                            belowBarData: BarAreaData(
                              show: true,
                              color: EcoPalette.surface.withValues(alpha: 0.6),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),

          // SLA Card
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: EcoPalette.cardBorder),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Service Level Agreement',
                      style: TextStyle(
                        fontFamily: 'Satoshi',
                        fontSize: 12.5,
                        color: Color(0xFF6B8073),
                      ),
                    ),
                    const SizedBox(height: 2),
                    Row(
                      children: [
                        const Text(
                          '98.5%',
                          style: TextStyle(
                            fontFamily: 'Satoshi',
                            fontSize: 18,
                            fontWeight: FontWeight.w800,
                            color: EcoPalette.primaryDark,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                          decoration: BoxDecoration(
                            color: const Color(0xFFE4F0E7),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: const Text(
                            'Met',
                            style: TextStyle(
                              fontFamily: 'Satoshi',
                              fontSize: 11,
                              fontWeight: FontWeight.w800,
                              color: Color(0xFF1E5E35),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
                const Icon(Icons.verified_outlined, color: Color(0xFF1E5E35), size: 28),
              ],
            ),
          ),
          const SizedBox(height: 12),

          // On-Time Performance Card
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: EcoPalette.cardBorder),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'On-Time Performance',
                      style: TextStyle(
                        fontFamily: 'Satoshi',
                        fontSize: 12.5,
                        color: Color(0xFF6B8073),
                      ),
                    ),
                    SizedBox(height: 2),
                    Text(
                      '97% (Trend: Stable)',
                      style: TextStyle(
                        fontFamily: 'Satoshi',
                        fontSize: 16,
                        fontWeight: FontWeight.w800,
                        color: EcoPalette.primaryDark,
                      ),
                    ),
                  ],
                ),
                Icon(Icons.timeline_rounded, color: EcoPalette.accentTerracotta, size: 28),
              ],
            ),
          ),
          const SizedBox(height: 24),

          // Report List Section
          const Text(
            'Report List',
            style: TextStyle(
              fontFamily: 'Satoshi',
              fontSize: 15,
              fontWeight: FontWeight.w800,
              color: EcoPalette.primaryDark,
            ),
          ),
          const SizedBox(height: 12),

          _buildReportItem(
            title: 'Daily Operations Report - Oct 26, 2022',
            period: 'Daily Audit (October 26)',
          ),
          const SizedBox(height: 12),

          _buildReportItem(
            title: 'Weekly Efficiency Summary - Week 43',
            period: 'Week 43 Audit (October 17 - 23)',
          ),
          const SizedBox(height: 12),

          _buildReportItem(
            title: 'Monthly Rider Performance - September 2022',
            period: 'Monthly Audit (September 2022)',
          ),
          const SizedBox(height: 24),
        ],
      ),
    );
  }

  Widget _buildReportItem({
    required String title,
    required String period,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: EcoPalette.cardBorder),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(
              fontFamily: 'Satoshi',
              fontSize: 14,
              fontWeight: FontWeight.w800,
              color: EcoPalette.primaryDark,
            ),
          ),
          const SizedBox(height: 10),
          Align(
            alignment: Alignment.centerLeft,
            child: InkWell(
              onTap: _isExporting ? null : () => _handleDownloadPdf(title, period),
              borderRadius: BorderRadius.circular(8),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: const Color(0xFFE8F2EC),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: const Color(0xFFC3D9CC)),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.picture_as_pdf_outlined, size: 14, color: Color(0xFF1E5E35)),
                    const SizedBox(width: 6),
                    Text(
                      _isExporting ? 'Generating PDF...' : 'PDF Download',
                      style: const TextStyle(
                        fontFamily: 'Satoshi',
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                        color: Color(0xFF1E5E35),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
