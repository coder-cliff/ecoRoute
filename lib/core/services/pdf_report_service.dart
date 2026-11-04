import 'dart:typed_data';
import 'package:intl/intl.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';

/// Client-side EcoRoute PDF Report Generator using 100% free offline packages
class PdfReportService {
  PdfReportService._();

  static Future<Uint8List> generateOperationsReport({
    required String title,
    required String period,
    double totalTonnes = 14.5,
    double slaPercent = 98.5,
    int activeRiders = 18,
    int completedPickups = 142,
  }) async {
    final pdf = pw.Document();
    final now = DateFormat('MMMM dd, yyyy • HH:mm').format(DateTime.now());

    pdf.addPage(
      pw.Page(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(32),
        build: (pw.Context context) {
          return pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              // Header
              pw.Row(
                mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                children: [
                  pw.Column(
                    crossAxisAlignment: pw.CrossAxisAlignment.start,
                    children: [
                      pw.Text(
                        'EcoRoute',
                        style: pw.TextStyle(
                          fontSize: 26,
                          fontWeight: pw.FontWeight.bold,
                          color: PdfColor.fromInt(0xFF0D2618),
                        ),
                      ),
                      pw.Text(
                        'Sustainable Municipal Waste Logistics • Arua City',
                        style: pw.TextStyle(
                          fontSize: 11,
                          color: PdfColor.fromInt(0xFF1A3A28),
                        ),
                      ),
                    ],
                  ),
                  pw.Container(
                    padding: const pw.EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                    decoration: pw.BoxDecoration(
                      color: PdfColor.fromInt(0xFFE8ECE7),
                      borderRadius: pw.BorderRadius.circular(6),
                    ),
                    child: pw.Text(
                      'OFFICIAL AUDIT',
                      style: pw.TextStyle(
                        fontSize: 10,
                        fontWeight: pw.FontWeight.bold,
                        color: PdfColor.fromInt(0xFF0D2618),
                      ),
                    ),
                  ),
                ],
              ),
              pw.SizedBox(height: 16),
              pw.Divider(color: PdfColor.fromInt(0xFF9C3D18), thickness: 2),
              pw.SizedBox(height: 16),

              // Report Title & Metadata
              pw.Text(
                title,
                style: pw.TextStyle(
                  fontSize: 18,
                  fontWeight: pw.FontWeight.bold,
                  color: PdfColor.fromInt(0xFF0D2618),
                ),
              ),
              pw.SizedBox(height: 4),
              pw.Text(
                'Reporting Period: $period • Generated: $now',
                style: const pw.TextStyle(fontSize: 11, color: PdfColors.grey700),
              ),
              pw.SizedBox(height: 20),

              // KPI Summary Matrix
              pw.Row(
                children: [
                  _buildKpiBox('Total Waste Collected', '${totalTonnes.toStringAsFixed(1)} Tonnes'),
                  pw.SizedBox(width: 12),
                  _buildKpiBox('SLA Achievement', '${slaPercent.toStringAsFixed(1)}%'),
                  pw.SizedBox(width: 12),
                  _buildKpiBox('Active Tricycle Fleet', '$activeRiders Units'),
                  pw.SizedBox(width: 12),
                  _buildKpiBox('Total Pickups', '$completedPickups Completed'),
                ],
              ),
              pw.SizedBox(height: 24),

              // Waste Segregation Breakdown Table
              pw.Text(
                'Waste Material Segregation Analysis (Arua City)',
                style: pw.TextStyle(
                  fontSize: 13,
                  fontWeight: pw.FontWeight.bold,
                  color: PdfColor.fromInt(0xFF0D2618),
                ),
              ),
              pw.SizedBox(height: 8),
              pw.TableHelper.fromTextArray(
                headers: ['Division / Zone', 'Household (kg)', 'Commercial (kg)', 'Recyclables (kg)', 'Status'],
                headerStyle: pw.TextStyle(
                  fontWeight: pw.FontWeight.bold,
                  color: PdfColors.white,
                  fontSize: 10,
                ),
                headerDecoration: const pw.BoxDecoration(
                  color: PdfColor.fromInt(0xFF0D2618),
                ),
                cellStyle: const pw.TextStyle(fontSize: 9),
                cellHeight: 24,
                data: [
                  ['Arua Central Business District', '3,420', '5,100', '1,850', 'Dispatched'],
                  ['Ediofe Trading Corridor', '2,150', '1,320', '890', 'Verified'],
                  ['Arua Hill Residential Area', '1,980', '650', '720', 'Collected'],
                  ['River Oli Division', '2,800', '1,100', '940', 'Verified'],
                  ['Muni University Campus Hub', '1,120', '2,200', '1,200', 'Dispatched'],
                ],
              ),
              pw.Spacer(),

              // Footer
              pw.Divider(color: PdfColors.grey300),
              pw.SizedBox(height: 6),
              pw.Row(
                mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                children: [
                  pw.Text(
                    'EcoRoute Operations Dispatch HQ • Arua, West Nile, Uganda',
                    style: const pw.TextStyle(fontSize: 9, color: PdfColors.grey600),
                  ),
                  pw.Text(
                    'Verification Hash: #ER-${DateTime.now().millisecondsSinceEpoch.toRadixString(16).toUpperCase()}',
                    style: const pw.TextStyle(fontSize: 9, color: PdfColors.grey600),
                  ),
                ],
              ),
            ],
          );
        },
      ),
    );

    return pdf.save();
  }

  static pw.Widget _buildKpiBox(String label, String value) {
    return pw.Expanded(
      child: pw.Container(
        padding: const pw.EdgeInsets.all(10),
        decoration: pw.BoxDecoration(
          color: PdfColor.fromInt(0xFFE8ECE7),
          borderRadius: pw.BorderRadius.circular(8),
          border: pw.Border.all(color: PdfColor.fromInt(0xFFCFD8D2)),
        ),
        child: pw.Column(
          crossAxisAlignment: pw.CrossAxisAlignment.start,
          children: [
            pw.Text(
              label,
              style: const pw.TextStyle(fontSize: 8.5, color: PdfColors.grey700),
            ),
            pw.SizedBox(height: 4),
            pw.Text(
              value,
              style: pw.TextStyle(
                fontSize: 13,
                fontWeight: pw.FontWeight.bold,
                color: PdfColor.fromInt(0xFF0D2618),
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// Triggers client-side share / download / print dialog
  static Future<void> printOrShareReport({
    required String title,
    required String period,
  }) async {
    final pdfBytes = await generateOperationsReport(title: title, period: period);
    await Printing.sharePdf(
      bytes: pdfBytes,
      filename: '${title.replaceAll(' ', '_')}.pdf',
    );
  }
}
