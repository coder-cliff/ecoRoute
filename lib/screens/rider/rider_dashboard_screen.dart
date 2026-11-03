import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';
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
                            '${completed.length} pickups successfully settled & cleared',
                            style: const TextStyle(fontSize: 11, color: Color(0xFF856404)),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),

              // NAVIGATION TABS
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16.0),
                child: Row(
                  children: [
                    _filterChip(0, 'Assigned (${assigned.length})'),
                    const SizedBox(width: 8),
                    _filterChip(1, 'Open Jobs (${available.length})'),
                    const SizedBox(width: 8),
                    _filterChip(2, 'Settled (${completed.length})'),
                  ],
                ),
              ),
              const SizedBox(height: 12),

              // LIST CONTENT
              if (_selectedTab == 0) ...[
                if (assigned.isEmpty)
                  _emptyMsg(
                    icon: Icons.done_all_rounded,
                    title: 'No pending pickups assigned',
                    subtitle: 'Check "Open Jobs" tab to claim new waste requests.',
                  )
                else
                  ...assigned.map((r) => _riderJobCard(r, isAssignedToMe: true)),
              ] else if (_selectedTab == 1) ...[
                if (available.isEmpty)
                  _emptyMsg(
                    icon: Icons.hourglass_empty_rounded,
                    title: 'No unassigned requests',
                    subtitle: 'All waste collection requests in the city are currently dispatched.',
                  )
                else
                  ...available.map((r) => _riderJobCard(r, isAssignedToMe: false)),
              ] else ...[
                if (completed.isEmpty)
                  _emptyMsg(
                    icon: Icons.receipt_long_rounded,
                    title: 'No collections completed today',
                    subtitle: 'Cash collections made on completed jobs will be listed here.',
                  )
                else
                  ...completed.map((r) => _completedJobCard(r)),
              ],
              const SizedBox(height: 30),
            ],
          ),
        ),
      ),
    );
  }

  Widget _filterChip(int index, String label) {
    final isSelected = _selectedTab == index;
    return Expanded(
      child: InkWell(
        onTap: () => setState(() => _selectedTab = index),
        borderRadius: BorderRadius.circular(12),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 10),
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: isSelected ? const Color(0xFF0D6EFD) : Colors.white,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: isSelected ? const Color(0xFF0D6EFD) : const Color(0xFFDDDDDD),
            ),
          ),
          child: Text(
            label,
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w700,
              color: isSelected ? Colors.white : AppTheme.textDark,
            ),
          ),
        ),
      ),
    );
  }

  Widget _riderJobCard(WasteRequest r, {required bool isAssignedToMe}) {
    final distKm = LocationService.calculateDistanceKm(
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
                        '${r.category.title} (${r.quantityBags} bags)',
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
                    '${r.quantityBags} Bags',
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
                    onPressed: () => _launchMapsNavigation(r.latitude, r.longitude),
                    icon: const Icon(Icons.navigation_rounded, size: 16, color: Color(0xFF0D6EFD)),
                    label: const Text('Navigate'),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: () {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(content: Text('Calling customer ${r.userName} at ${r.userPhone}')),
                        );
                      },
                      icon: const Icon(Icons.phone, size: 16),
                      label: const Text('Call'),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    flex: 2,
                    child: ElevatedButton.icon(
                      style: ElevatedButton.styleFrom(backgroundColor: AppTheme.primaryGreen),
                      onPressed: () => _showCashCollectionDialog(context, r),
                      icon: const Icon(Icons.check_circle_outline, size: 18),
                      label: const Text('Collect Cash'),
                    ),
                  ),
                ],
              ),
            ] else ...[
              Row(
                children: [
                  OutlinedButton.icon(
                    onPressed: () => _launchMapsNavigation(r.latitude, r.longitude),
                    icon: const Icon(Icons.directions_rounded, size: 16, color: Color(0xFF0D6EFD)),
                    label: const Text('Map'),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: ElevatedButton.icon(
                      style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF0D6EFD)),
                      onPressed: () async {
                        final auth = Provider.of<AuthProvider>(context, listen: false);
                        final provider = Provider.of<WasteRequestProvider>(context, listen: false);
                        await provider.assignRider(
                          requestId: r.id,
                          riderId: auth.currentUser.id,
                          riderName: auth.currentUser.name,
                        );
                        if (mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(content: Text('Accepted pickup ${r.id}! Added to Assigned tab.')),
                          );
                        }
                      },
                      icon: const Icon(Icons.thumb_up_rounded, size: 18),
                      label: const Text('Accept Pickup Job'),
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

  Widget _completedJobCard(WasteRequest r) {
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.check_circle, color: AppTheme.primaryGreen, size: 20),
                const SizedBox(width: 10),
                Text(
                  '${r.category.title} (${r.id})',
                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                ),
                const Spacer(),
                Text(
                  'Receipt: ${r.receiptNumber ?? 'N/A'}',
                  style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: AppTheme.primaryGreen),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(r.address, style: const TextStyle(fontSize: 12, color: AppTheme.textMuted)),
            const SizedBox(height: 8),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Collected: ${r.collectedAt != null ? DateFormat('h:mm a • MMM d').format(r.collectedAt!) : 'Completed'}',
                  style: const TextStyle(fontSize: 11, color: AppTheme.textMuted),
                ),
                Text(
                  'Cash Collected: \$${(r.actualCashPaid ?? r.estimatedCashAmount).toStringAsFixed(2)}',
                  style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w800, color: AppTheme.darkForest),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPhotoThumbnail(String path, String categoryName) {
    if (path.isEmpty || path.startsWith('simulated_') || path.startsWith('assets/')) {
      return Container(
        color: AppTheme.accentMint.withValues(alpha: 0.5),
        child: Center(
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.image, size: 20, color: AppTheme.primaryGreen),
              const SizedBox(width: 8),
              Text('Waste Photo: $categoryName',
                  style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: AppTheme.darkForest)),
            ],
          ),
        ),
      );
    } else if (path.startsWith('http://') || path.startsWith('https://')) {
      return Image.network(
        path,
        fit: BoxFit.cover,
        errorBuilder: (_, __, ___) => const Center(child: Icon(Icons.broken_image, size: 20)),
      );
    } else if (!kIsWeb && File(path).existsSync()) {
      return Image.file(
        File(path),
        fit: BoxFit.cover,
        errorBuilder: (_, __, ___) => const Center(child: Icon(Icons.broken_image, size: 20)),
      );
    } else {
      return Container(
        color: AppTheme.accentMint.withValues(alpha: 0.5),
        child: Center(
          child: Text('Waste Photo: $categoryName',
              style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: AppTheme.darkForest)),
        ),
      );
    }
  }

  void _showCashCollectionDialog(BuildContext context, WasteRequest r) {
    final cashController = TextEditingController(
      text: r.estimatedCashAmount.toStringAsFixed(2),
    );

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Row(
          children: [
            Icon(Icons.payments_rounded, color: AppTheme.cashGold),
            SizedBox(width: 10),
            Text('Confirm Cash Payment'),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Collecting from: ${r.userName}'),
            const SizedBox(height: 4),
            Text('Address: ${r.address}', style: const TextStyle(fontSize: 12, color: AppTheme.textMuted)),
            const SizedBox(height: 16),
            const Text(
              'Enter Hard Cash Amount Received:',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
            ),
            const SizedBox(height: 8),
            TextField(
              controller: cashController,
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
              decoration: const InputDecoration(
                prefixText: '\$ ',
                labelText: 'Cash Collected',
              ),
            ),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: AppTheme.cashGoldLight,
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Text(
                'By confirming, you certify that the waste was collected and exact hard cash was handed over.',
                style: TextStyle(fontSize: 11, color: Color(0xFF664D03)),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: AppTheme.primaryGreen),
            onPressed: () async {
              final val = double.tryParse(cashController.text) ?? r.estimatedCashAmount;
              final provider = Provider.of<WasteRequestProvider>(context, listen: false);
              await provider.confirmCashCollection(
                requestId: r.id,
                amountCollected: val,
              );
              if (ctx.mounted) Navigator.pop(ctx);
              if (context.mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('Payment of \$${val.toStringAsFixed(2)} confirmed! Receipt generated.'),
                    backgroundColor: AppTheme.primaryGreen,
                  ),
                );
              }
            },
            child: const Text('Confirm Cash & Complete'),
          ),
        ],
      ),
    );
  }

  Widget _emptyMsg({required IconData icon, required String title, required String subtitle}) {
    return Padding(
      padding: const EdgeInsets.all(36.0),
      child: Center(
        child: Column(
          children: [
            Icon(icon, size: 48, color: AppTheme.textMuted.withValues(alpha: 0.5)),
            const SizedBox(height: 12),
            Text(title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
            const SizedBox(height: 4),
            Text(subtitle, textAlign: TextAlign.center, style: const TextStyle(fontSize: 12, color: AppTheme.textMuted)),
          ],
        ),
      ),
    );
  }
}
