import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../models/waste_category.dart';
import '../../models/waste_request.dart';
import '../../providers/waste_request_provider.dart';
import '../../theme/app_theme.dart';
import '../../widgets/cash_payment_banner.dart';
import '../../widgets/milestone_stepper_widget.dart';
import '../../widgets/status_badge.dart';

class RequestDetailsScreen extends StatelessWidget {
  final WasteRequest request;

  const RequestDetailsScreen({super.key, required this.request});

  Future<void> _openMaps(BuildContext context, double lat, double lon) async {
    final uri = Uri.parse('https://www.google.com/maps/search/?api=1&query=$lat,$lon');
    try {
      final launched = await launchUrl(uri, mode: LaunchMode.externalApplication);
      if (!launched && context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Coordinates: $lat, $lon')),
        );
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Coordinates: $lat, $lon ($e)')),
        );
      }
    }
  }

  Future<void> _callPhone(BuildContext context, String phone) async {
    final cleanPhone = phone.replaceAll(RegExp(r'\s+'), '');
    final uri = Uri.parse('tel:$cleanPhone');
    try {
      if (await canLaunchUrl(uri)) {
        await launchUrl(uri);
      } else if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Dialing: $phone')),
        );
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Dialing: $phone ($e)')),
        );
      }
    }
  }

  void _copyReceipt(BuildContext context, WasteRequest r) {
    final text = '''
==============================
   ECOROUTE OFFICIAL RECEIPT
==============================
Receipt Number: ${r.receiptNumber}
Request ID: ${r.id}
Citizen Name: ${r.userName}
Category: ${r.category.title}
Container Size: ${r.volumeSize.label}
Quantity: ${r.quantityBags} unit(s)
Amount Paid: \$${(r.actualCashPaid ?? r.estimatedCashAmount).toStringAsFixed(2)} (Hard Cash)
Collection Date: ${r.collectedAt != null ? DateFormat('yyyy-MM-dd HH:mm').format(r.collectedAt!) : 'Completed'}
Collector / Rider: ${r.assignedRiderName ?? 'Assigned Collector'}
Pickup Address: ${r.address}
Carbon Mitigated: ~${r.totalCarbonSavedKg.toStringAsFixed(1)} kg CO2e
Trees Equivalent: ~${r.treesSavedEquivalent.toStringAsFixed(2)} trees/yr
==============================
Thank you for keeping our communities clean & green!
''';
    Clipboard.setData(ClipboardData(text: text));
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Official Receipt copied to clipboard for sharing!'),
        backgroundColor: AppTheme.primaryGreen,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final provider = Provider.of<WasteRequestProvider>(context);
    final currentReq = provider.requests.firstWhere(
      (r) => r.id == request.id,
      orElse: () => request,
    );

    final category = currentReq.category;
    final scheduledStr = DateFormat('EEE, MMM d • h:mm a').format(currentReq.scheduledPickupTime);

    return Scaffold(
      appBar: AppBar(
        title: Text('Pickup ${currentReq.id}'),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 16.0),
            child: StatusBadge(status: currentReq.status),
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 4-STAGE MILESTONE STEPPER PIPELINE
            MilestoneStepperWidget(
              status: currentReq.status,
              requestedAt: currentReq.createdAt,
              collectedAt: currentReq.collectedAt,
              assignedRiderName: currentReq.assignedRiderName,
            ),
            const SizedBox(height: 16),

            // PHOTO PREVIEW CARD
            Container(
              height: 200,
              width: double.infinity,
              decoration: BoxDecoration(
                color: Colors.grey.shade200,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: const Color(0xFFDDDDDD)),
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(16),
                child: _buildPhotoWidget(currentReq.photoPath, category.title),
              ),
            ),
            const SizedBox(height: 16),

            // SUMMARY CARD
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        CircleAvatar(
                          backgroundColor: category.color.withValues(alpha: 0.15),
                          child: Icon(category.icon, color: category.color, size: 22),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                category.title,
                                style: const TextStyle(
                                  fontWeight: FontWeight.w700,
                                  fontSize: 16,
                                ),
                              ),
                              Text(
                                '${currentReq.volumeSize.label} • ${currentReq.quantityBags} units',
                                style: const TextStyle(
                                  fontSize: 13,
                                  color: AppTheme.textMuted,
                                ),
                              ),
                            ],
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                          decoration: BoxDecoration(
                            color: AppTheme.accentMint,
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.end,
                            children: [
                              Text(
                                '~${currentReq.totalCarbonSavedKg.toStringAsFixed(1)} kg CO₂e',
                                style: const TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w700,
                                  color: AppTheme.primaryGreen,
                                ),
                              ),
                              Text(
                                '~${currentReq.totalDivertedWeightKg.toStringAsFixed(1)} kg waste',
                                style: const TextStyle(fontSize: 10, color: AppTheme.textMuted),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const Divider(height: 24),
                    _infoRow(
                      Icons.schedule_rounded,
                      'Scheduled Window',
                      scheduledStr,
                    ),
                    const SizedBox(height: 10),
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Icon(Icons.location_on_rounded, size: 18, color: AppTheme.primaryGreen),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text('Location & GPS', style: TextStyle(fontSize: 11, color: AppTheme.textMuted)),
                              const SizedBox(height: 2),
                              Text(
                                '${currentReq.address}\n(${currentReq.latitude.toStringAsFixed(4)}, ${currentReq.longitude.toStringAsFixed(4)})',
                                style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
                              ),
                            ],
                          ),
                        ),
                        IconButton.filledTonal(
                          onPressed: () => _openMaps(context, currentReq.latitude, currentReq.longitude),
                          icon: const Icon(Icons.directions_rounded, size: 18),
                          tooltip: 'Open in Maps',
                        ),
                      ],
                    ),
                    if (currentReq.notes.isNotEmpty) ...[
                      const SizedBox(height: 10),
                      _infoRow(
                        Icons.notes_rounded,
                        'Rider Instructions',
                        currentReq.notes,
                      ),
                    ],

                    // Assigned Rider Contact Bar
                    if (currentReq.assignedRiderName != null) ...[
                      const Divider(height: 20),
                      Row(
                        children: [
                          const CircleAvatar(
                            radius: 16,
                            backgroundColor: AppTheme.accentMint,
                            child: Icon(Icons.electric_moped_rounded, size: 18, color: AppTheme.primaryGreen),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Collector: ${currentReq.assignedRiderName}',
                                  style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold),
                                ),
                                const Text(
                                  'Municipal Field Collector',
                                  style: TextStyle(fontSize: 11, color: AppTheme.textMuted),
                                ),
                              ],
                            ),
                          ),
                          ElevatedButton.icon(
                            style: ElevatedButton.styleFrom(
                              backgroundColor: AppTheme.primaryGreen,
                              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                              minimumSize: Size.zero,
                            ),
                            icon: const Icon(Icons.call_rounded, size: 14),
                            label: const Text('Call', style: TextStyle(fontSize: 12)),
                            onPressed: () => _callPhone(context, '+256701987654'),
                          ),
                        ],
                      ),
                    ],
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),

            // HARD CASH NOTICE & RECEIPT
            CashPaymentBanner(
              amount: currentReq.actualCashPaid ?? currentReq.estimatedCashAmount,
              isCollected: currentReq.isCashCollected,
            ),
            if (currentReq.receiptNumber != null) ...[
              const SizedBox(height: 8),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: AppTheme.primaryGreen),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.receipt_long_rounded, color: AppTheme.primaryGreen),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Official Cash Collection Receipt',
                            style: TextStyle(fontWeight: FontWeight.w700, fontSize: 13),
                          ),
                          Text(
                            'Receipt ID: ${currentReq.receiptNumber} • Paid in Hard Cash',
                            style: const TextStyle(fontSize: 12, color: AppTheme.textMuted),
                          ),
                        ],
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.share_rounded, color: AppTheme.primaryGreen),
                      tooltip: 'Copy / Share Receipt',
                      onPressed: () => _copyReceipt(context, currentReq),
                    ),
                  ],
                ),
              ),
            ],
            const SizedBox(height: 20),

            // ACTION BUTTONS
            if (currentReq.status == RequestStatus.pending) ...[
              SizedBox(
                width: double.infinity,
                child: OutlinedButton.icon(
                  onPressed: () {
                    provider.cancelRequest(currentReq.id);
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Request cancelled successfully.')),
                    );
                    Navigator.pop(context);
                  },
                  icon: const Icon(Icons.cancel_outlined, color: Colors.redAccent),
                  label: const Text('Cancel Pickup Request',
                      style: TextStyle(color: Colors.redAccent)),
                ),
              ),
            ],
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }

  Widget _buildPhotoWidget(String path, String categoryName) {
    if (path.isEmpty || path.startsWith('simulated_') || path.startsWith('assets/')) {
      return Container(
        color: AppTheme.accentMint,
        child: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.photo_camera_back_rounded, size: 48, color: AppTheme.primaryGreen),
              const SizedBox(height: 8),
              Text(
                'Waste Photo: $categoryName',
                style: const TextStyle(fontWeight: FontWeight.w700, color: AppTheme.darkForest),
              ),
              const Text(
                'Auto-tagged with GPS coordinate metadata',
                style: TextStyle(fontSize: 11, color: AppTheme.textMuted),
              ),
            ],
          ),
        ),
      );
    } else if (path.startsWith('http://') || path.startsWith('https://')) {
      return Image.network(
        path,
        fit: BoxFit.cover,
        errorBuilder: (context, error, stackTrace) => Center(
          child: Text('Waste Photo: $categoryName'),
        ),
      );
    } else if (!kIsWeb && File(path).existsSync()) {
      return Image.file(
        File(path),
        fit: BoxFit.cover,
        errorBuilder: (context, error, stackTrace) => Center(
          child: Text('Waste Photo: $categoryName'),
        ),
      );
    } else {
      return Container(
        color: AppTheme.accentMint,
        child: Center(
          child: Text(
            'Waste Photo: $categoryName',
            style: const TextStyle(fontWeight: FontWeight.bold, color: AppTheme.darkForest),
          ),
        ),
      );
    }
  }

  Widget _infoRow(IconData icon, String label, String value) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 18, color: AppTheme.primaryGreen),
        const SizedBox(width: 10),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(label, style: const TextStyle(fontSize: 11, color: AppTheme.textMuted)),
              const SizedBox(height: 2),
              Text(value, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600)),
            ],
          ),
        ),
      ],
    );
  }
}
