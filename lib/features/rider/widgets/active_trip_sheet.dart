import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:image_picker/image_picker.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../core/utils/formatters.dart';
import '../../../domain/entities/pickup_request.dart';
import '../../../domain/enums/request_status.dart';
import '../../../domain/enums/waste_type.dart';
import '../../payment/digital_receipt_dialog.dart';

/// Floating Trip Banner docked on the rider dashboard (Option B)
class ActiveTripBanner extends StatelessWidget {
  const ActiveTripBanner({
    required this.activeStop,
    required this.totalStops,
    required this.currentIndex,
    required this.onTap,
    super.key,
  });

  final PickupRequest activeStop;
  final int totalStops;
  final int currentIndex;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    final isCollected = activeStop.status == RequestStatus.collected;
    final stageLabel = isCollected ? 'Heading to Municipal Depot' : 'En Route to Resident';
    final stageColor = isCollected ? const Color(0xFFFB8C00) : const Color(0xFF2E7D32);

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF192A1D) : Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isDark ? const Color(0xFF2A3F2F) : const Color(0xFFD0E2D3),
        ),
        boxShadow: const [
          BoxShadow(
            color: Color(0x14000000),
            blurRadius: 12,
            offset: Offset(0, 4),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () {
            HapticFeedback.selectionClick();
            onTap();
          },
          borderRadius: BorderRadius.circular(16),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
            child: Row(
              children: [
                Container(
                  width: 38,
                  height: 38,
                  decoration: BoxDecoration(
                    color: stageColor.withValues(alpha: 0.15),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    isCollected ? Icons.local_shipping_outlined : Icons.navigation_rounded,
                    color: stageColor,
                    size: 20,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                            decoration: BoxDecoration(
                              color: stageColor,
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: Text(
                              'Stop $currentIndex of $totalStops',
                              style: const TextStyle(
                                fontSize: 9,
                                fontWeight: FontWeight.w800,
                                color: Colors.white,
                              ),
                            ),
                          ),
                          const SizedBox(width: 6),
                          Expanded(
                            child: Text(
                              stageLabel,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(
                                fontSize: 10,
                                fontWeight: FontWeight.w700,
                                color: stageColor,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 3),
                      Text(
                        '${activeStop.residentName} • ${activeStop.address}',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w800,
                          color: isDark ? Colors.white : const Color(0xFF183B20),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                  decoration: BoxDecoration(
                    color: const Color(0xFF2E7D32),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Text(
                    'Active Trip',
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                      color: Colors.white,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// Comprehensive Expanded Active Trip Console Sheet (Option B)
class ActiveTripSheet extends StatefulWidget {
  const ActiveTripSheet({
    required this.stops,
    required this.initialIndex,
    required this.onAdvanceOrder,
    required this.onUpdateSackCount,
    this.onUpdateCashReceived,
    super.key,
  });

  final List<PickupRequest> stops;
  final int initialIndex;
  final Future<void> Function(PickupRequest request, RequestStatus nextStatus) onAdvanceOrder;
  final Future<void> Function(PickupRequest request, int newCount, int newPrice) onUpdateSackCount;
  final Future<void> Function(PickupRequest request)? onUpdateCashReceived;

  @override
  State<ActiveTripSheet> createState() => _ActiveTripSheetState();
}

class _ActiveTripSheetState extends State<ActiveTripSheet> {
  late int _selectedStopIndex;
  bool _advancing = false;
  final _picker = ImagePicker();

  Future<void> _captureProofPhoto(ImageSource source) async {
    try {
      final file = await _picker.pickImage(
        source: source,
        maxWidth: 1024,
        maxHeight: 1024,
        imageQuality: 85,
      );
      if (file == null) return;
      final updated = _currentStop.copyWith(photoUrl: file.path);
      if (widget.onUpdateCashReceived != null) {
        await widget.onUpdateCashReceived!(updated);
      } else {
        await widget.onAdvanceOrder(updated, updated.status);
      }
      if (mounted) setState(() {});
    } catch (_) {}
  }

  @override
  void initState() {
    super.initState();
    _selectedStopIndex = widget.initialIndex.clamp(0, widget.stops.isEmpty ? 0 : widget.stops.length - 1);
  }

  PickupRequest get _currentStop => widget.stops[_selectedStopIndex];

  Future<void> _makeCall(String phone) async {
    final clean = phone.replaceAll(RegExp(r'\s+'), '');
    final uri = Uri(scheme: 'tel', path: clean);
    try {
      if (await canLaunchUrl(uri)) {
        await launchUrl(uri);
      }
    } catch (_) {}
  }

  Future<void> _openDirections(String address, double? lat, double? lng) async {
    final Uri uri;
    if (lat != null && lng != null) {
      uri = Uri.parse('https://www.google.com/maps/search/?api=1&query=$lat,$lng');
    } else {
      uri = Uri.parse('https://www.google.com/maps/search/?api=1&query=${Uri.encodeComponent('$address, Arua, Uganda')}');
    }
    try {
      if (await canLaunchUrl(uri)) {
        await launchUrl(uri, mode: LaunchMode.externalApplication);
      }
    } catch (_) {}
  }

  void _adjustSackCount(int delta) {
    final current = _currentStop;
    final newCount = (current.sackCount + delta).clamp(1, 30);
    if (newCount == current.sackCount) return;

    // Recalculate price: base 3,000 UGX per sack standard
    final unitPrice = current.sackCount > 0
        ? (current.priceUgx / current.sackCount).round()
        : 3000;
    final newPrice = newCount * unitPrice;

    widget.onUpdateSackCount(current, newCount, newPrice);
    setState(() {});
  }

  Future<void> _handleConfirmCash() async {
    final current = _currentStop;
    final txId = 'REC-${DateTime.now().year}-ARU-${DateTime.now().millisecondsSinceEpoch.toString().substring(7)}';
    final now = DateTime.now();
    final updated = current.copyWith(
      paymentMethod: 'cash',
      cashReceivedByRider: true,
      receiptNumber: txId,
      paidAt: now,
    );

    if (widget.onUpdateCashReceived != null) {
      await widget.onUpdateCashReceived!(updated);
    } else {
      await widget.onAdvanceOrder(updated, updated.status);
    }

    if (!mounted) return;
    setState(() {});

    showDialog<void>(
      context: context,
      builder: (_) => DigitalReceiptDialog(request: updated),
    );
  }

  void _showReceipt() {
    showDialog<void>(
      context: context,
      builder: (_) => DigitalReceiptDialog(request: _currentStop),
    );
  }

  Future<void> _handleAdvance() async {
    final current = _currentStop;
    setState(() => _advancing = true);

    try {
      final nextStatus = current.status == RequestStatus.requested
          ? RequestStatus.collected
          : RequestStatus.awaitingVerification;

      await widget.onAdvanceOrder(current, nextStatus);

      if (mounted) {
        Navigator.pop(context);
      }
    } finally {
      if (mounted) setState(() => _advancing = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    final cardBg = isDark ? const Color(0xFF192A1D) : Colors.white;
    final cardBorder = isDark ? const Color(0xFF2A3F2F) : const Color(0xFFE2EAE1);
    final subtextColor = isDark ? const Color(0xFF9EABA1) : const Color(0xFF647568);

    if (widget.stops.isEmpty) {
      return Container(
        padding: const EdgeInsets.all(24),
        child: const Text('No active collection stops remaining.'),
      );
    }

    final current = _currentStop;
    final isCollected = current.status == RequestStatus.collected;

    return Container(
      constraints: BoxConstraints(
        maxHeight: MediaQuery.sizeOf(context).height * 0.88,
      ),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF111E14) : const Color(0xFFF7FAF5),
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Drag handle
          Center(
            child: Container(
              margin: const EdgeInsets.only(top: 10, bottom: 8),
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: isDark ? const Color(0xFF334A38) : const Color(0xFFD0DCD2),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),

          // Header
          Padding(
            padding: const EdgeInsets.fromLTRB(18, 4, 18, 12),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: const Color(0xFFE8F5E9),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Icon(Icons.two_wheeler_rounded, color: Color(0xFF2E7D32), size: 22),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Active Route Dispatch Console',
                        style: TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      Text(
                        'Arua Tricycle Collection Hub',
                        style: TextStyle(fontSize: 11, color: subtextColor),
                      ),
                    ],
                  ),
                ),
                IconButton(
                  onPressed: () => Navigator.pop(context),
                  icon: const Icon(Icons.close_rounded, size: 20),
                ),
              ],
            ),
          ),

          const Divider(height: 1),

          Expanded(
            child: ListView(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 20),
              children: [
                // 1. Multi-Stop Sequence Stepper (Requirement 3)
                if (widget.stops.length > 1) ...[
                  Text(
                    'Multi-Stop Route Sequence',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w800,
                      color: isDark ? Colors.white70 : const Color(0xFF183B20),
                    ),
                  ),
                  const SizedBox(height: 8),
                  SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: Row(
                      children: [
                        for (var i = 0; i < widget.stops.length; i++) ...[
                          if (i > 0)
                            Container(
                              width: 16,
                              height: 2,
                              color: isDark ? const Color(0xFF2A3F2F) : const Color(0xFFD0DCD2),
                            ),
                          InkWell(
                            onTap: () => setState(() => _selectedStopIndex = i),
                            borderRadius: BorderRadius.circular(8),
                            child: Container(
                              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                              decoration: BoxDecoration(
                                color: _selectedStopIndex == i
                                    ? const Color(0xFF2E7D32)
                                    : (isDark ? const Color(0xFF192A1D) : Colors.white),
                                borderRadius: BorderRadius.circular(8),
                                border: Border.all(
                                  color: _selectedStopIndex == i
                                      ? const Color(0xFF1B5E20)
                                      : (isDark ? const Color(0xFF2A3F2F) : const Color(0xFFE2EAE1)),
                                ),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Text(
                                    'Stop ${i + 1}',
                                    style: TextStyle(
                                      fontSize: 11,
                                      fontWeight: FontWeight.w800,
                                      color: _selectedStopIndex == i
                                          ? Colors.white
                                          : (isDark ? const Color(0xFFC7D3C9) : const Color(0xFF183B20)),
                                    ),
                                  ),
                                  if (widget.stops[i].status == RequestStatus.collected) ...[
                                    const SizedBox(width: 4),
                                    const Icon(Icons.check_circle_rounded, size: 12, color: Color(0xFF81C784)),
                                  ],
                                ],
                              ),
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                  const SizedBox(height: 14),
                ],

                // 2. Resident Contact & Navigation Card
                Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: cardBg,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: cardBorder),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          CircleAvatar(
                            radius: 18,
                            backgroundColor: const Color(0xFFE8F5E9),
                            child: Text(
                              current.residentName.isNotEmpty ? current.residentName[0].toUpperCase() : 'R',
                              style: const TextStyle(fontWeight: FontWeight.w800, color: Color(0xFF2E7D32)),
                            ),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  current.residentName,
                                  style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w800),
                                ),
                                Text(
                                  current.residentPhone,
                                  style: TextStyle(fontSize: 11, color: subtextColor),
                                ),
                              ],
                            ),
                          ),
                          IconButton.filledTonal(
                            onPressed: () => _makeCall(current.residentPhone),
                            icon: const Icon(Icons.phone_rounded, size: 18),
                            style: IconButton.styleFrom(
                              backgroundColor: const Color(0xFFE8F5E9),
                              foregroundColor: const Color(0xFF2E7D32),
                            ),
                          ),
                        ],
                      ),
                      const Divider(height: 16),
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Icon(Icons.location_on_outlined, size: 18, color: Color(0xFF2E7D32)),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  current.address,
                                  style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700),
                                ),
                                if (current.description.isNotEmpty)
                                  Text(
                                    current.description,
                                    style: TextStyle(fontSize: 11, color: subtextColor),
                                  ),
                              ],
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 10),
                      SizedBox(
                        width: double.infinity,
                        child: OutlinedButton.icon(
                          onPressed: () => _openDirections(current.address, current.latitude, current.longitude),
                          icon: const Icon(Icons.directions_rounded, size: 16),
                          label: const Text('Open in Google Maps / Directions'),
                          style: OutlinedButton.styleFrom(
                            side: const BorderSide(color: Color(0xFF2E7D32)),
                            foregroundColor: const Color(0xFF2E7D32),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 14),

                // 3. On-Site Sack Verification & Stepper (Requirement 2)
                Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: cardBg,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: cardBorder),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          const Icon(Icons.inventory_2_outlined, size: 18, color: Color(0xFF2E7D32)),
                          const SizedBox(width: 8),
                          const Text(
                            'On-Site Waste & Sack Verification',
                            style: TextStyle(fontSize: 13, fontWeight: FontWeight.w800),
                          ),
                        ],
                      ),
                      const SizedBox(height: 10),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                current.wasteType.label,
                                style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700),
                              ),
                              Text(
                                'Category booked by resident',
                                style: TextStyle(fontSize: 10, color: subtextColor),
                              ),
                            ],
                          ),
                          // Sack Stepper [-] count [+]
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
                            decoration: BoxDecoration(
                              color: isDark ? const Color(0xFF233627) : const Color(0xFFEAF4EC),
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: Row(
                              children: [
                                IconButton(
                                  icon: const Icon(Icons.remove_rounded, size: 16),
                                  visualDensity: VisualDensity.compact,
                                  onPressed: () => _adjustSackCount(-1),
                                ),
                                Padding(
                                  padding: const EdgeInsets.symmetric(horizontal: 8),
                                  child: Text(
                                    '${current.sackCount} sacks',
                                    style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w900),
                                  ),
                                ),
                                IconButton(
                                  icon: const Icon(Icons.add_rounded, size: 16),
                                  visualDensity: VisualDensity.compact,
                                  onPressed: () => _adjustSackCount(1),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text('Recalculated Fee:', style: TextStyle(fontSize: 11, color: subtextColor)),
                          Text(
                            formatUgx(current.priceUgx),
                            style: const TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w900,
                              color: Color(0xFF2E7D32),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 14),

                // 3a. On-Site Proof of Collection Photo (Audit & Verification)
                Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: cardBg,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: cardBorder),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          const Icon(Icons.camera_alt_outlined, size: 18, color: Color(0xFF2E7D32)),
                          const SizedBox(width: 8),
                          const Text(
                            'Proof of Collection Photo',
                            style: TextStyle(fontSize: 13, fontWeight: FontWeight.w800),
                          ),
                          const Spacer(),
                          if (current.photoUrl != null)
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                              decoration: BoxDecoration(
                                color: const Color(0xFFE8F5E9),
                                borderRadius: BorderRadius.circular(6),
                              ),
                              child: const Text(
                                'Photo Attached',
                                style: TextStyle(fontSize: 10, fontWeight: FontWeight.w800, color: Color(0xFF2E7D32)),
                              ),
                            ),
                        ],
                      ),
                      const SizedBox(height: 6),
                      Text(
                        current.photoUrl != null
                            ? 'Visual proof captured on-site. Ready for depot weigh-in audit.'
                            : 'Snap a photo of the loaded tricycle sacks at the gate for verified drop-off.',
                        style: TextStyle(fontSize: 11, color: subtextColor),
                      ),
                      const SizedBox(height: 10),
                      Row(
                        children: [
                          Expanded(
                            child: OutlinedButton.icon(
                              onPressed: () => _captureProofPhoto(ImageSource.camera),
                              icon: const Icon(Icons.photo_camera_rounded, size: 16),
                              label: Text(current.photoUrl != null ? 'Retake Photo' : 'Take Gate Photo'),
                              style: OutlinedButton.styleFrom(
                                side: const BorderSide(color: Color(0xFF2E7D32)),
                                foregroundColor: const Color(0xFF2E7D32),
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),
                          IconButton.outlined(
                            onPressed: () => _captureProofPhoto(ImageSource.gallery),
                            icon: const Icon(Icons.photo_library_outlined, size: 18),
                            tooltip: 'Select from gallery',
                            style: IconButton.styleFrom(
                              side: const BorderSide(color: Color(0xFF2E7D32)),
                              foregroundColor: const Color(0xFF2E7D32),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 14),

                // 3b. Physical Hard Cash Collection & Digital Receipt (Commercial Micro-Fleet)
                Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: current.cashReceivedByRider
                        ? (isDark ? const Color(0xFF132A18) : const Color(0xFFE8F5E9))
                        : (isDark ? const Color(0xFF262111) : const Color(0xFFFFF9E6)),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: current.cashReceivedByRider
                          ? (isDark ? const Color(0xFF254B2C) : const Color(0xFFA5D6A7))
                          : (isDark ? const Color(0xFF4A3E1E) : const Color(0xFFFFE082)),
                    ),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Icon(
                            current.cashReceivedByRider
                                ? Icons.verified_rounded
                                : Icons.payments_outlined,
                            size: 18,
                            color: current.cashReceivedByRider
                                ? const Color(0xFF2E7D32)
                                : const Color(0xFFE65100),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              current.cashReceivedByRider
                                  ? 'Cash Handover Confirmed'
                                  : 'Cash Collection at Gate',
                              style: TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.w800,
                                color: current.cashReceivedByRider
                                    ? const Color(0xFF1B5E20)
                                    : const Color(0xFFB78103),
                              ),
                            ),
                          ),
                          Text(
                            formatUgx(current.priceUgx),
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w900,
                              color: current.cashReceivedByRider
                                  ? const Color(0xFF1B5E20)
                                  : const Color(0xFFE65100),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 6),
                      Text(
                        current.cashReceivedByRider
                            ? 'Physical cash received into rider custody. Receipt generated and credited to trip ledger.'
                            : 'Collect physical cash from resident upon loading sacks. Tap below to confirm and issue digital receipt.',
                        style: TextStyle(fontSize: 11, color: subtextColor),
                      ),
                      const SizedBox(height: 10),
                      if (!current.cashReceivedByRider)
                        SizedBox(
                          width: double.infinity,
                          child: FilledButton.icon(
                            style: FilledButton.styleFrom(
                              backgroundColor: const Color(0xFF1B5E3B),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                            ),
                            onPressed: _handleConfirmCash,
                            icon: const Icon(Icons.check_circle_outline_rounded, size: 16),
                            label: Text('Confirm Cash Received (${formatUgx(current.priceUgx)})'),
                          ),
                        )
                      else
                        SizedBox(
                          width: double.infinity,
                          child: OutlinedButton.icon(
                            style: OutlinedButton.styleFrom(
                              side: const BorderSide(color: Color(0xFF2E7D32)),
                              foregroundColor: const Color(0xFF2E7D32),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                            ),
                            onPressed: _showReceipt,
                            icon: const Icon(Icons.receipt_long_rounded, size: 16),
                            label: const Text('View / Print Digital Receipt'),
                          ),
                        ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),

                // 4. Action Button to Advance Order Status
                FilledButton.icon(
                  onPressed: _advancing ? null : _handleAdvance,
                  icon: _advancing
                      ? const SizedBox(
                          width: 16,
                          height: 16,
                          child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                        )
                      : Icon(
                          isCollected ? Icons.scale_rounded : Icons.check_circle_rounded,
                          size: 18,
                        ),
                  label: Text(
                    isCollected
                        ? 'Deliver to Municipal Depot / Scale'
                        : 'Confirm Sacks Loaded & Depart',
                  ),
                  style: FilledButton.styleFrom(
                    backgroundColor: isCollected ? const Color(0xFFE65100) : const Color(0xFF2E7D32),
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
