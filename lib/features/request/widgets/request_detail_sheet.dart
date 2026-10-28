import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../core/utils/formatters.dart';
import '../../../domain/entities/pickup_request.dart';
import '../../../domain/enums/request_status.dart';
import '../../../domain/enums/role.dart';
import '../../../domain/enums/waste_type.dart';

class RequestDetailSheet extends StatelessWidget {
  const RequestDetailSheet({
    required this.request,
    required this.userRole,
    this.isOwner = false,
    this.onPayMoMo,
    this.onStatusChange,
    this.onCancel,
    super.key,
  });

  final PickupRequest request;
  final AppRole userRole;
  final bool isOwner;
  final VoidCallback? onPayMoMo;
  final ValueChanged<RequestStatus>? onStatusChange;
  final VoidCallback? onCancel;

  static Future<void> show(
    BuildContext context, {
    required PickupRequest request,
    required AppRole userRole,
    bool isOwner = false,
    VoidCallback? onPayMoMo,
    ValueChanged<RequestStatus>? onStatusChange,
    VoidCallback? onCancel,
  }) {
    return showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => RequestDetailSheet(
        request: request,
        userRole: userRole,
        isOwner: isOwner,
        onPayMoMo: onPayMoMo,
        onStatusChange: onStatusChange,
        onCancel: onCancel,
      ),
    );
  }

  Color get _statusColor => switch (request.status) {
    RequestStatus.requested => const Color(0xFFE65100),
    RequestStatus.collected => const Color(0xFF0288D1),
    RequestStatus.awaitingVerification => const Color(0xFF7B1FA2),
    RequestStatus.paid => const Color(0xFF2E7D32),
    RequestStatus.cancelled => const Color(0xFFC62828),
  };

  IconData get _statusIcon => switch (request.status) {
    RequestStatus.requested => Icons.schedule_rounded,
    RequestStatus.collected => Icons.local_shipping_rounded,
    RequestStatus.awaitingVerification => Icons.fact_check_rounded,
    RequestStatus.paid => Icons.verified_rounded,
    RequestStatus.cancelled => Icons.cancel_rounded,
  };

  int get _currentStepIndex => switch (request.status) {
    RequestStatus.requested => 0,
    RequestStatus.collected => 1,
    RequestStatus.awaitingVerification => 2,
    RequestStatus.paid => 3,
    RequestStatus.cancelled => -1,
  };

  Future<void> _makePhoneCall(String phone) async {
    final clean = phone.replaceAll(RegExp(r'\s+'), '');
    final uri = Uri(scheme: 'tel', path: clean);
    try {
      if (await canLaunchUrl(uri)) {
        await launchUrl(uri);
      }
    } catch (_) {}
  }

  @override
  Widget build(BuildContext context) {
    final isSettled = request.status == RequestStatus.paid;
    final isCancelled = request.status == RequestStatus.cancelled;
    final canAdvance = (userRole == AppRole.rider || userRole == AppRole.admin) && !isCancelled;
    final canCancel = (isOwner || userRole == AppRole.admin) &&
        request.status == RequestStatus.requested;
    final canPay = isOwner && !isSettled && !isCancelled;

    final shortId = request.id.length > 8
        ? request.id.substring(request.id.length - 8).toUpperCase()
        : request.id.toUpperCase();

    // Environmental metrics calculation
    final estimatedKg = request.sackCount * 25; // 25kg standard sack weight
    final co2Saved = (estimatedKg * 0.45).toStringAsFixed(1); // 0.45kg CO2 avoided per kg

    return Container(
      constraints: BoxConstraints(
        maxHeight: MediaQuery.sizeOf(context).height * 0.88,
      ),
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      child: Column(
        children: [
          // Drag handle
          Center(
            child: Container(
              margin: const EdgeInsets.only(top: 10, bottom: 6),
              width: 44,
              height: 4,
              decoration: BoxDecoration(
                color: const Color(0xFFD6DFD8),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),

          // Header
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Text(
                            'Request #$shortId',
                            style: const TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.w800,
                              color: Color(0xFF183B20),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                            decoration: BoxDecoration(
                              color: _statusColor.withValues(alpha: 0.12),
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(_statusIcon, size: 13, color: _statusColor),
                                const SizedBox(width: 4),
                                Text(
                                  request.status.label,
                                  style: TextStyle(
                                    fontSize: 11,
                                    fontWeight: FontWeight.w800,
                                    color: _statusColor,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 2),
                      Text(
                        'Submitted: ${formatDateTime(request.submittedAt)}',
                        style: const TextStyle(fontSize: 12, color: Color(0xFF71877D)),
                      ),
                    ],
                  ),
                ),
                IconButton(
                  onPressed: () => Navigator.pop(context),
                  icon: const Icon(Icons.close_rounded),
                  tooltip: 'Close',
                ),
              ],
            ),
          ),

          const Divider(height: 1),

          // Body Content
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Progress tracker pipeline
                  if (!isCancelled) ...[
                    _buildTrackingStepper(),
                    const SizedBox(height: 20),
                  ],

                  // Waste payload card
                  _buildWastePayloadCard(estimatedKg, co2Saved),
                  const SizedBox(height: 16),

                  // Location & Resident Card
                  _buildLocationAndResidentCard(),
                  const SizedBox(height: 16),

                  // Financial & Pricing Card
                  _buildPricingCard(context),
                  const SizedBox(height: 20),

                  // Status update controls for Rider/Admin
                  if (canAdvance) ...[
                    _buildRiderAdminActions(context),
                    const SizedBox(height: 16),
                  ],

                  // Action Buttons (MoMo Pay or Cancel)
                  if (canPay) ...[
                    SizedBox(
                      width: double.infinity,
                      height: 50,
                      child: FilledButton.icon(
                        onPressed: () {
                          Navigator.pop(context);
                          onPayMoMo?.call();
                        },
                        style: FilledButton.styleFrom(
                          backgroundColor: const Color(0xFF2E7D32),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                        ),
                        icon: const Icon(Icons.payment_rounded, size: 20),
                        label: Text(
                          'Pay ${formatUgx(request.priceUgx)} via Mobile Money',
                          style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 14),
                        ),
                      ),
                    ),
                    const SizedBox(height: 10),
                  ],

                  if (canCancel) ...[
                    SizedBox(
                      width: double.infinity,
                      child: OutlinedButton.icon(
                        onPressed: () {
                          HapticFeedback.lightImpact();
                          Navigator.pop(context);
                          onCancel?.call();
                        },
                        style: OutlinedButton.styleFrom(
                          foregroundColor: const Color(0xFFC62828),
                          side: const BorderSide(color: Color(0xFFFFCDD2)),
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                        ),
                        icon: const Icon(Icons.delete_outline_rounded, size: 18),
                        label: const Text('Cancel this pickup request'),
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTrackingStepper() {
    final steps = [
      {'title': 'Requested', 'desc': 'Order created', 'icon': Icons.send_rounded},
      {'title': 'Collected', 'desc': 'Rider picked up', 'icon': Icons.two_wheeler_rounded},
      {'title': 'Review', 'desc': 'Depot scale check', 'icon': Icons.fact_check_rounded},
      {'title': 'Completed', 'desc': 'Verified & paid', 'icon': Icons.check_circle_rounded},
    ];

    final currentIndex = _currentStepIndex;

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFFF7FBF8),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: const Color(0xFFE2EAE1)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Dispatch & Collection Lifecycle',
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w800,
              color: Color(0xFF183B20),
            ),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              for (int i = 0; i < steps.length; i++) ...[
                Expanded(
                  child: Column(
                    children: [
                      Container(
                        width: 32,
                        height: 32,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: i <= currentIndex
                              ? const Color(0xFF2E7D32)
                              : const Color(0xFFE0E0E0),
                          boxShadow: i == currentIndex
                              ? [
                                  BoxShadow(
                                    color: const Color(0xFF2E7D32).withValues(alpha: 0.35),
                                    blurRadius: 8,
                                    spreadRadius: 2,
                                  ),
                                ]
                              : null,
                        ),
                        child: Icon(
                          steps[i]['icon'] as IconData,
                          size: 16,
                          color: i <= currentIndex ? Colors.white : const Color(0xFF9E9E9E),
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        steps[i]['title'] as String,
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: i <= currentIndex ? FontWeight.w800 : FontWeight.w500,
                          color: i <= currentIndex
                              ? const Color(0xFF183B20)
                              : const Color(0xFF888888),
                        ),
                      ),
                      Text(
                        steps[i]['desc'] as String,
                        style: const TextStyle(fontSize: 9, color: Color(0xFF889988)),
                        textAlign: TextAlign.center,
                      ),
                    ],
                  ),
                ),
                if (i < steps.length - 1)
                  Expanded(
                    child: Container(
                      height: 2,
                      margin: const EdgeInsets.only(bottom: 24),
                      color: i < currentIndex
                          ? const Color(0xFF2E7D32)
                          : const Color(0xFFE0E0E0),
                    ),
                  ),
              ],
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildWastePayloadCard(int estimatedKg, String co2Saved) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE2EAE1)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: const Color(0xFFE8F5E9),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(Icons.recycling_rounded, color: Color(0xFF2E7D32), size: 20),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '${request.wasteType.label} Waste',
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w800,
                        color: Color(0xFF183B20),
                      ),
                    ),
                    Text(
                      '${request.sackCount} ${request.sackCount == 1 ? 'sack' : 'sacks'} • Instant Collection Mode',
                      style: const TextStyle(fontSize: 11, color: Color(0xFF556958)),
                    ),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: const Color(0xFFE8F5E9),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  'Zone: ${request.zone.name.toUpperCase()}',
                  style: const TextStyle(fontSize: 10, fontWeight: FontWeight.w800, color: Color(0xFF1B5E20)),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            request.description,
            style: const TextStyle(fontSize: 13, color: Color(0xFF333333), height: 1.3),
          ),
          const SizedBox(height: 12),
          const Divider(height: 1),
          const SizedBox(height: 10),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _buildMiniMetric(
                label: 'Payload',
                value: '~$estimatedKg kg',
                icon: Icons.scale_rounded,
              ),
              Container(width: 1, height: 28, color: const Color(0xFFE0ECE2)),
              _buildMiniMetric(
                label: 'Carbon Offset',
                value: '$co2Saved kg CO₂',
                icon: Icons.eco_rounded,
                accent: const Color(0xFF2E7D32),
              ),
              Container(width: 1, height: 28, color: const Color(0xFFE0ECE2)),
              _buildMiniMetric(
                label: 'Service Mode',
                value: request.isInstant ? 'Instant' : 'Scheduled',
                icon: Icons.bolt_rounded,
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildMiniMetric({
    required String label,
    required String value,
    required IconData icon,
    Color? accent,
  }) {
    return Column(
      children: [
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 13, color: accent ?? const Color(0xFF556958)),
            const SizedBox(width: 3),
            Text(
              value,
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w800,
                color: accent ?? const Color(0xFF183B20),
              ),
            ),
          ],
        ),
        const SizedBox(height: 2),
        Text(
          label,
          style: const TextStyle(fontSize: 10, color: Color(0xFF889988)),
        ),
      ],
    );
  }

  Widget _buildLocationAndResidentCard() {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE2EAE1)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.location_on_outlined, color: Color(0xFF2E7D32), size: 18),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  request.address,
                  style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    color: Color(0xFF183B20),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          const Divider(height: 1),
          const SizedBox(height: 10),
          Row(
            children: [
              CircleAvatar(
                radius: 16,
                backgroundColor: const Color(0xFFE8F5E9),
                child: Text(
                  request.residentName.isNotEmpty
                      ? request.residentName[0].toUpperCase()
                      : 'R',
                  style: const TextStyle(fontWeight: FontWeight.w800, color: Color(0xFF2E7D32), fontSize: 13),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      request.residentName,
                      style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700),
                    ),
                    Text(
                      request.residentPhone,
                      style: const TextStyle(fontSize: 11, color: Color(0xFF647568)),
                    ),
                  ],
                ),
              ),
              IconButton.filledTonal(
                onPressed: () => _makePhoneCall(request.residentPhone),
                icon: const Icon(Icons.phone_rounded, size: 18),
                tooltip: 'Call resident',
                style: IconButton.styleFrom(
                  backgroundColor: const Color(0xFFE8F5E9),
                  foregroundColor: const Color(0xFF2E7D32),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildPricingCard(BuildContext context) {
    final isPaid = request.status == RequestStatus.paid;

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFFF8FAF8),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE2EAE1)),
      ),
      child: Row(
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Collection Rate & Fee',
                style: TextStyle(fontSize: 11, color: Color(0xFF647568)),
              ),
              const SizedBox(height: 2),
              Text(
                formatUgx(request.priceUgx),
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w900,
                  color: Color(0xFF1B5E3B),
                ),
              ),
            ],
          ),
          const Spacer(),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(
              color: isPaid ? const Color(0xFFE8F5E9) : const Color(0xFFFFF3E0),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(
                color: isPaid ? const Color(0xFFA5D6A7) : const Color(0xFFFFCC80),
              ),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  isPaid ? Icons.check_circle_rounded : Icons.pending_rounded,
                  size: 14,
                  color: isPaid ? const Color(0xFF2E7D32) : const Color(0xFFE65100),
                ),
                const SizedBox(width: 4),
                Text(
                  isPaid ? 'Settled (MoMo)' : 'Unpaid',
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w800,
                    color: isPaid ? const Color(0xFF2E7D32) : const Color(0xFFE65100),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRiderAdminActions(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFFF1F8F2),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFD3E7D5)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.admin_panel_settings_outlined, size: 16, color: Color(0xFF2E7D32)),
              const SizedBox(width: 6),
              Text(
                '${userRole.label} Workflow Control',
                style: const TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w800,
                  color: Color(0xFF1B5E3B),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          const Text(
            'Advance this request along the municipal collection and verification lifecycle:',
            style: TextStyle(fontSize: 11, color: Color(0xFF556958)),
          ),
          const SizedBox(height: 10),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              if (request.status == RequestStatus.requested)
                FilledButton.icon(
                  onPressed: () {
                    Navigator.pop(context);
                    onStatusChange?.call(RequestStatus.collected);
                  },
                  style: FilledButton.styleFrom(backgroundColor: const Color(0xFF0288D1)),
                  icon: const Icon(Icons.local_shipping_rounded, size: 16),
                  label: const Text('Mark as Picked Up'),
                ),
              if (request.status == RequestStatus.collected)
                FilledButton.icon(
                  onPressed: () {
                    Navigator.pop(context);
                    onStatusChange?.call(RequestStatus.awaitingVerification);
                  },
                  style: FilledButton.styleFrom(backgroundColor: const Color(0xFF7B1FA2)),
                  icon: const Icon(Icons.scale_rounded, size: 16),
                  label: const Text('Submit to Depot Scale'),
                ),
              if (request.status == RequestStatus.awaitingVerification && userRole == AppRole.admin) ...[
                FilledButton.icon(
                  onPressed: () {
                    Navigator.pop(context);
                    onStatusChange?.call(RequestStatus.paid);
                  },
                  style: FilledButton.styleFrom(backgroundColor: const Color(0xFF2E7D32)),
                  icon: const Icon(Icons.check_circle_rounded, size: 16),
                  label: const Text('Approve & Settle Payment'),
                ),
                OutlinedButton.icon(
                  onPressed: () {
                    Navigator.pop(context);
                    onStatusChange?.call(RequestStatus.collected);
                  },
                  icon: const Icon(Icons.undo_rounded, size: 16),
                  label: const Text('Return to Rider'),
                ),
              ],
            ],
          ),
        ],
      ),
    );
  }
}
