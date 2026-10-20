import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../../models/waste_request.dart';
import '../../providers/waste_request_provider.dart';
import '../../theme/app_theme.dart';
import '../../widgets/cash_payment_banner.dart';
import '../../widgets/status_badge.dart';

class RequestDetailsScreen extends StatelessWidget {
  final WasteRequest request;

  const RequestDetailsScreen({super.key, required this.request});

  @override
  Widget build(BuildContext context) {
    // Listen to provider to receive live updates when rider updates status!
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
                                '${currentReq.quantityBags} Bags • \$${currentReq.estimatedCashAmount.toStringAsFixed(2)} Estimated',
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
                          child: Text(
                            '~${currentReq.totalCarbonSavedKg.toStringAsFixed(1)} kg CO₂e Saved',
                            style: const TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w700,
                              color: AppTheme.primaryGreen,
                            ),
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
                    _infoRow(
                      Icons.location_on_rounded,
                      'Location & GPS',
                      '${currentReq.address}\n(${currentReq.latitude.toStringAsFixed(4)}, ${currentReq.longitude.toStringAsFixed(4)})',
                    ),
                    if (currentReq.notes.isNotEmpty) ...[
                      const SizedBox(height: 10),
                      _infoRow(
                        Icons.notes_rounded,
                        'Rider Instructions',
                        currentReq.notes,
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
                    Column(
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
                  ],
                ),
              ),
            ],
            const SizedBox(height: 20),

            // STATUS TIMELINE STEPPER
            const Text(
              'Collection Workflow Timeline',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: 12),
            _buildTimeline(currentReq),

            const SizedBox(height: 24),

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
    if (path.startsWith('simulated_') || path.isEmpty) {
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
    } else if (kIsWeb) {
      return Image.network(path, fit: BoxFit.cover);
    } else {
      return Image.file(File(path), fit: BoxFit.cover);
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
              Text(value, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600)),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildTimeline(WasteRequest req) {
    return Column(
      children: [
        _stepTile(
          title: 'Request Logged with GPS & Photo',
          subtitle: DateFormat('h:mm a • MMM d').format(req.createdAt),
          isDone: true,
          isCurrent: req.status == RequestStatus.pending,
        ),
        _stepTile(
          title: req.assignedRiderName != null
              ? 'Rider Dispatched: ${req.assignedRiderName}'
              : 'Admin Dispatching Rider',
          subtitle: req.assignedRiderName != null
              ? 'Collector assigned and navigating to waste location'
              : 'Waiting for available tricycle/truck collector',
          isDone: req.status == RequestStatus.assigned || req.status == RequestStatus.collected,
          isCurrent: req.status == RequestStatus.assigned,
        ),
        _stepTile(
          title: 'Waste Collected & Hard Cash Paid',
          subtitle: req.collectedAt != null
              ? 'Completed on ${DateFormat('h:mm a').format(req.collectedAt!)} • Cash settled'
              : 'Collector confirms waste weighing and receives cash payment',
          isDone: req.status == RequestStatus.collected,
          isCurrent: false,
          isLast: true,
        ),
      ],
    );
  }

  Widget _stepTile({
    required String title,
    required String subtitle,
    required bool isDone,
    required bool isCurrent,
    bool isLast = false,
  }) {
    Color color = isDone
        ? AppTheme.primaryGreen
        : isCurrent
            ? const Color(0xFF0D6EFD)
            : const Color(0xFFDDDDDD);

    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Column(
            children: [
              Container(
                width: 24,
                height: 24,
                decoration: BoxDecoration(
                  color: isDone ? color : Colors.white,
                  shape: BoxShape.circle,
                  border: Border.all(color: color, width: 2),
                ),
                child: isDone
                    ? const Icon(Icons.check, size: 14, color: Colors.white)
                    : isCurrent
                        ? Container(
                            margin: const EdgeInsets.all(4),
                            decoration: BoxDecoration(
                              color: color,
                              shape: BoxShape.circle,
                            ),
                          )
                        : null,
              ),
              if (!isLast)
                Expanded(
                  child: Container(
                    width: 2,
                    color: isDone ? AppTheme.primaryGreen : const Color(0xFFE0E0E0),
                  ),
                ),
            ],
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.only(bottom: 20.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      fontWeight: FontWeight.w700,
                      fontSize: 14,
                      color: isDone || isCurrent ? AppTheme.textDark : AppTheme.textMuted,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    subtitle,
                    style: const TextStyle(fontSize: 12, color: AppTheme.textMuted),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
