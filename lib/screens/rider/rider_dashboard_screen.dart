import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../models/waste_category.dart';
import '../../models/waste_request.dart';
import '../../providers/auth_provider.dart';
import '../../providers/waste_request_provider.dart';
import '../../services/location_service.dart';
import '../../theme/app_theme.dart';
import '../../widgets/role_header_app_bar.dart';
import '../../widgets/status_badge.dart';
import '../../widgets/user_avatar.dart';

class RiderDashboardScreen extends StatefulWidget {
  const RiderDashboardScreen({super.key});

  @override
  State<RiderDashboardScreen> createState() => _RiderDashboardScreenState();
}

class _RiderDashboardScreenState extends State<RiderDashboardScreen> {
  int _selectedTab = 0; // 0: Assigned, 1: Available, 2: Cash Settled

  Future<void> _launchMapsNavigation(double lat, double lon) async {
    final uri = Uri.parse('https://www.google.com/maps/search/?api=1&query=$lat,$lon');
    try {
      final launched = await launchUrl(uri, mode: LaunchMode.externalApplication);
      if (!launched && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('GPS Coordinates: $lat, $lon')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Coordinates: $lat, $lon (Maps error: $e)')),
        );
      }
    }
  }

  Future<void> _callResident(String phone) async {
    final cleanPhone = phone.replaceAll(RegExp(r'\s+'), '');
    final uri = Uri.parse('tel:$cleanPhone');
    try {
      if (await canLaunchUrl(uri)) {
        await launchUrl(uri);
      } else if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Calling customer: $phone')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Calling customer: $phone ($e)')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final auth = Provider.of<AuthProvider>(context);
    final provider = Provider.of<WasteRequestProvider>(context);

    final assigned = provider.getRiderAssignedRequests(auth.currentUser.id);
    final available = provider.availableUnassignedRequests;
    final completed = provider.getRiderCompletedRequests(auth.currentUser.id);

    final totalCashCollected = completed.fold(
      0.0,
      (sum, r) => sum + (r.actualCashPaid ?? r.estimatedCashAmount),
    );

    return Scaffold(
      appBar: const RoleHeaderAppBar(title: 'Rider Portal'),
      body: RefreshIndicator(
        onRefresh: () => provider.loadRequests(),
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // RIDER CASH COUNTER BANNER
              Container(
                margin: const EdgeInsets.all(16),
                padding: const EdgeInsets.all(18),
                decoration: BoxDecoration(
                  color: AppTheme.cashGoldLight,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: AppTheme.cashGold, width: 1.5),
                ),
                child: Row(
                  children: [
                    UserAvatar(
                      user: auth.currentUser,
                      radius: 26,
                      showRoleBadge: true,
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Hard Cash in Pouch Today',
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                              color: Color(0xFF664D03),
                            ),
                          ),
                          Text(
                            '\$${totalCashCollected.toStringAsFixed(2)}',
                            style: const TextStyle(
                              fontSize: 24,
                              fontWeight: FontWeight.w900,
                              color: Color(0xFF664D03),
                            ),
                          ),
                          Text(
                            '${completed.length} cash collections settled with residents',
                            style: const TextStyle(fontSize: 11, color: Color(0xFF856404)),
                          ),
                        ],
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: const BoxDecoration(
                        color: Colors.white,
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(Icons.account_balance_wallet_rounded,
                          color: AppTheme.cashGold, size: 28),
                    ),
                  ],
                ),
              ),

              // SEGMENTED TABS (Assigned, Available, Completed)
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16.0),
                child: Row(
                  children: [
                    _tabChip(0, 'My Active (${assigned.length})'),
                    const SizedBox(width: 8),
                    _tabChip(1, 'Open Queue (${available.length})'),
                    const SizedBox(width: 8),
                    _tabChip(2, 'Settled (${completed.length})'),
                  ],
                ),
              ),
              const SizedBox(height: 12),

              // LIST SECTION
              if (_selectedTab == 0) ...[
                if (assigned.isEmpty)
                  _emptyState(
                    'No active pickups assigned',
                    'Check the "Open Queue" tab to accept available waste pickups nearby.',
                    Icons.two_wheeler_outlined,
                  )
                else
                  ...assigned.map((r) => _buildRiderRequestCard(r, provider, isAssignedToMe: true)),
              ] else if (_selectedTab == 1) ...[
                if (available.isEmpty)
                  _emptyState(
                    'No pending pickups in area',
                    'All scheduled pickups have been claimed. Check back shortly for new requests.',
                    Icons.check_circle_outline,
                  )
                else
                  ...available.map((r) => _buildRiderRequestCard(r, provider, isAssignedToMe: false)),
              ] else ...[
                if (completed.isEmpty)
                  _emptyState(
                    'No completed pickups today',
                    'Cash settlements and completed pickups will appear here for audit.',
                    Icons.receipt_long_outlined,
                  )
                else
                  ...completed.map((r) => _buildSettledCard(r)),
              ],
              const SizedBox(height: 80),
            ],
          ),
        ),
      ),
    );
  }

  Widget _tabChip(int index, String label) {
    final isSelected = _selectedTab == index;
    return Expanded(
      child: InkWell(
        onTap: () => setState(() => _selectedTab = index),
        borderRadius: BorderRadius.circular(12),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 10),
          decoration: BoxDecoration(
            color: isSelected ? const Color(0xFF0D6EFD) : Colors.white,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: isSelected ? const Color(0xFF0D6EFD) : const Color(0xFFDDDDDD),
            ),
          ),
          alignment: Alignment.center,
          child: Text(
            label,
            style: TextStyle(
              fontWeight: FontWeight.w700,
              fontSize: 12,
              color: isSelected ? Colors.white : AppTheme.textMuted,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildRiderRequestCard(WasteRequest r, WasteRequestProvider provider, {required bool isAssignedToMe}) {
    final distKm = LocationService.distanceInKm(
      LocationService.defaultLat,
      LocationService.defaultLon,
      r.latitude,
      r.longitude,
    );
    final scheduledStr = DateFormat('EEE, MMM d • h:mm a').format(r.scheduledPickupTime);

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
            Row(
              children: [
                CircleAvatar(
                  backgroundColor: r.category.color.withValues(alpha: 0.15),
                  child: Icon(r.category.icon, color: r.category.color, size: 20),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '${r.category.title} (${r.volumeSize.label} • ${r.quantityBags} bags)',
                        style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 15),
                      ),
                      Text(
                        'Customer: ${r.userName} • ID: ${r.id}',
                        style: const TextStyle(fontSize: 12, color: AppTheme.textMuted),
                      ),
                    ],
                  ),
                ),
                StatusBadge(status: r.status),
              ],
            ),
            const SizedBox(height: 12),

            // Photo Preview
            Container(
              height: 120,
              width: double.infinity,
              decoration: BoxDecoration(
                color: Colors.grey.shade100,
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: const Color(0xFFEEEEEE)),
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(10),
                child: _buildPhotoThumbnail(r.photoPath, r.category.title),
              ),
            ),
            const SizedBox(height: 12),

            // Time & Location
            Row(
              children: [
                const Icon(Icons.access_time_rounded, size: 16, color: AppTheme.textMuted),
                const SizedBox(width: 6),
                Text(
                  'Pickup window: $scheduledStr',
                  style: const TextStyle(fontSize: 12, color: AppTheme.textMuted),
                ),
              ],
            ),
            const SizedBox(height: 6),
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Icon(Icons.location_on, size: 16, color: Colors.redAccent),
                const SizedBox(width: 6),
                Expanded(
                  child: Text(
                    r.address,
                    style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: Colors.blue.shade50,
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Text(
                    '~${distKm.toStringAsFixed(1)} km away',
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.bold,
                      color: Colors.blue.shade800,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 6),
            Text(
              'GPS Coordinates: ${r.latitude.toStringAsFixed(5)}, ${r.longitude.toStringAsFixed(5)}',
              style: const TextStyle(fontSize: 11, color: AppTheme.textMuted),
            ),
            const SizedBox(height: 12),

            // Cash info
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: AppTheme.cashGoldLight,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                children: [
                  const Icon(Icons.payments_rounded, size: 18, color: AppTheme.cashGold),
                  const SizedBox(width: 8),
                  Text(
                    'Collect Hard Cash: \$${r.estimatedCashAmount.toStringAsFixed(2)}',
                    style: const TextStyle(
                      fontWeight: FontWeight.w800,
                      fontSize: 13,
                      color: Color(0xFF664D03),
                    ),
                  ),
                  const Spacer(),
                  Text(
                    '${r.quantityBags} Units',
                    style: const TextStyle(
                      fontWeight: FontWeight.w600,
                      fontSize: 12,
                      color: Color(0xFF664D03),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 14),

            // Actions
            if (isAssignedToMe) ...[
              Row(
                children: [
                  OutlinedButton.icon(
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                      minimumSize: Size.zero,
                    ),
                    onPressed: () => _launchMapsNavigation(r.latitude, r.longitude),
                    icon: const Icon(Icons.navigation_rounded, size: 16, color: Color(0xFF0D6EFD)),
                    label: const Text('Navigate'),
                  ),
                  const SizedBox(width: 8),
                  OutlinedButton.icon(
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                      minimumSize: Size.zero,
                    ),
                    onPressed: () => _callResident(r.userPhone),
                    icon: const Icon(Icons.phone, size: 16),
                    label: const Text('Call'),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: ElevatedButton.icon(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppTheme.primaryGreen,
                        padding: const EdgeInsets.symmetric(vertical: 10),
                        minimumSize: Size.zero,
                      ),
                      onPressed: () => _showCollectionDialog(context, r, provider),
                      icon: const Icon(Icons.check_circle_rounded, size: 16),
                      label: const Text('Collect Cash', style: TextStyle(fontWeight: FontWeight.bold)),
                    ),
                  ),
                ],
              ),
            ] else ...[
              Row(
                children: [
                  OutlinedButton.icon(
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                      minimumSize: Size.zero,
                    ),
                    onPressed: () => _launchMapsNavigation(r.latitude, r.longitude),
                    icon: const Icon(Icons.map_rounded, size: 16),
                    label: const Text('Preview'),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: ElevatedButton.icon(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF0D6EFD),
                        padding: const EdgeInsets.symmetric(vertical: 10),
                        minimumSize: Size.zero,
                      ),
                      onPressed: () {
                        final auth = Provider.of<AuthProvider>(context, listen: false);
                        provider.assignRider(
                          requestId: r.id,
                          riderId: auth.currentUser.id,
                          riderName: auth.currentUser.name,
                        );
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(content: Text('Accepted pickup ${r.id}! Added to active queue.')),
                        );
                      },
                      icon: const Icon(Icons.assignment_turned_in_rounded, size: 16),
                      label: const Text('Accept Pickup'),
                    ),
                  ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildPhotoThumbnail(String path, String categoryName) {
    if (path.isEmpty || path.startsWith('simulated_') || path.startsWith('assets/')) {
      return Container(
        color: AppTheme.accentMint,
        child: Center(
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.photo_camera_rounded, size: 24, color: AppTheme.primaryGreen),
              const SizedBox(width: 8),
              Text(
                'Verified Waste: $categoryName',
                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: AppTheme.darkForest),
              ),
            ],
          ),
        ),
      );
    } else if (path.startsWith('http://') || path.startsWith('https://')) {
      return Image.network(
        path,
        fit: BoxFit.cover,
        errorBuilder: (_, __, ___) => Container(
          color: AppTheme.accentMint,
          alignment: Alignment.center,
          child: Text('Waste: $categoryName'),
        ),
      );
    } else if (!kIsWeb && File(path).existsSync()) {
      return Image.file(
        File(path),
        fit: BoxFit.cover,
        errorBuilder: (_, __, ___) => Container(
          color: AppTheme.accentMint,
          alignment: Alignment.center,
          child: Text('Waste: $categoryName'),
        ),
      );
    } else {
      return Container(
        color: AppTheme.accentMint,
        alignment: Alignment.center,
        child: Text('Waste: $categoryName', style: const TextStyle(fontWeight: FontWeight.bold)),
      );
    }
  }

  Widget _buildSettledCard(WasteRequest r) {
    final collectedTime = r.collectedAt != null
        ? DateFormat('EEE, MMM d • h:mm a').format(r.collectedAt!)
        : 'Completed';

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.verified_rounded, color: AppTheme.primaryGreen, size: 22),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '${r.category.title} (${r.volumeSize.label} • ${r.quantityBags} bags)',
                        style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 14),
                      ),
                      Text(
                        'Receipt: ${r.receiptNumber} • Settled $collectedTime',
                        style: const TextStyle(fontSize: 12, color: AppTheme.textMuted),
                      ),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: AppTheme.accentMint,
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Text(
                    '+\$${(r.actualCashPaid ?? r.estimatedCashAmount).toStringAsFixed(2)}',
                    style: const TextStyle(
                      fontWeight: FontWeight.w900,
                      color: AppTheme.darkForest,
                      fontSize: 14,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              'Resident: ${r.userName} • Address: ${r.address}',
              style: const TextStyle(fontSize: 12, color: AppTheme.textMuted),
            ),
          ],
        ),
      ),
    );
  }

  void _showCollectionDialog(BuildContext context, WasteRequest r, WasteRequestProvider provider) {
    final cashController = TextEditingController(
      text: r.estimatedCashAmount.toStringAsFixed(2),
    );

    showDialog(
      context: context,
      builder: (dialogCtx) {
        return AlertDialog(
          title: Text('Collect Hard Cash (${r.id})'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Customer: ${r.userName}',
                style: const TextStyle(fontWeight: FontWeight.w700),
              ),
              Text(
                'Category: ${r.category.title} (${r.volumeSize.label} • ${r.quantityBags} units)',
                style: const TextStyle(fontSize: 13, color: AppTheme.textMuted),
              ),
              const SizedBox(height: 14),
              const Text(
                'Physical Cash Received (USD / Local):',
                style: TextStyle(fontWeight: FontWeight.w600, fontSize: 13),
              ),
              const SizedBox(height: 6),
              TextField(
                controller: cashController,
                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                decoration: const InputDecoration(
                  prefixIcon: Icon(Icons.payments_rounded, color: AppTheme.cashGold),
                  prefixText: '\$ ',
                ),
              ),
              const SizedBox(height: 10),
              const Text(
                'Notice: Please ensure you count physical cash on site before tapping confirm.',
                style: TextStyle(fontSize: 11, color: Colors.orange, fontStyle: FontStyle.italic),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogCtx),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(backgroundColor: AppTheme.primaryGreen),
              onPressed: () {
                final amount = double.tryParse(cashController.text.trim()) ?? r.estimatedCashAmount;
                provider.confirmCashCollection(
                  requestId: r.id,
                  amountCollected: amount,
                );
                Navigator.pop(dialogCtx);
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('Collection confirmed! \$${amount.toStringAsFixed(2)} added to pouch.'),
                    backgroundColor: AppTheme.primaryGreen,
                  ),
                );
              },
              child: const Text('Confirm Cash Receipt'),
            ),
          ],
        );
      },
    );
  }

  Widget _emptyState(String title, String subtitle, IconData icon) {
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.all(24),
      padding: const EdgeInsets.all(32),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFEEEEEE)),
      ),
      child: Column(
        children: [
          CircleAvatar(
            radius: 30,
            backgroundColor: Colors.blue.shade50,
            child: Icon(icon, size: 30, color: const Color(0xFF0D6EFD)),
          ),
          const SizedBox(height: 16),
          Text(
            title,
            style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 16),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 6),
          Text(
            subtitle,
            textAlign: TextAlign.center,
            style: const TextStyle(fontSize: 12, color: AppTheme.textMuted),
          ),
        ],
      ),
    );
  }
}
