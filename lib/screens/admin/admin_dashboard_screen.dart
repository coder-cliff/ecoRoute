import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../models/user_model.dart';
import '../../models/waste_category.dart';
import '../../models/waste_request.dart';
import '../../providers/auth_provider.dart';
import '../../providers/waste_request_provider.dart';
import '../../theme/app_theme.dart';
import '../../widgets/role_header_app_bar.dart';
import '../../widgets/status_badge.dart';
import '../../widgets/user_avatar.dart';
import '../auth/register_screen.dart';
import '../citizen/request_details_screen.dart';
import '../common/eco_stats_screen.dart';
import '../common/interactive_map_screen.dart';

class AdminDashboardScreen extends StatefulWidget {
  const AdminDashboardScreen({super.key});

  @override
  State<AdminDashboardScreen> createState() => _AdminDashboardScreenState();
}

class _AdminDashboardScreenState extends State<AdminDashboardScreen> {
  int _activeView = 0; // 0: Dispatch Queue, 1: Fleet & Riders
  String _searchQuery = '';
  final TextEditingController _searchController = TextEditingController();

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _callPhone(String phone) async {
    final cleanPhone = phone.replaceAll(RegExp(r'\s+'), '');
    final uri = Uri.parse('tel:$cleanPhone');
    try {
      if (await canLaunchUrl(uri)) {
        await launchUrl(uri);
      } else if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Calling: $phone')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Calling: $phone ($e)')),
        );
      }
    }
  }

  void _exportCsvDialog(BuildContext context, WasteRequestProvider provider) {
    final csvData = provider.exportMunicipalCsvReport();

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Row(
          children: [
            Icon(Icons.file_download_rounded, color: AppTheme.primaryGreen),
            SizedBox(width: 8),
            Text('Municipal Operations CSV Export', style: TextStyle(fontSize: 16)),
          ],
        ),
        content: SizedBox(
          width: double.maxFinite,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Complete audit trail of requests, citizen details, rider dispatches, cash settlements, and carbon savings in standard CSV format (100% Free & Open).',
                style: TextStyle(fontSize: 12, color: AppTheme.textMuted),
              ),
              const SizedBox(height: 12),
              Container(
                height: 160,
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: Colors.grey.shade100,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.grey.shade300),
                ),
                child: SingleChildScrollView(
                  child: Text(
                    csvData,
                    style: const TextStyle(fontFamily: 'monospace', fontSize: 10),
                  ),
                ),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Close'),
          ),
          ElevatedButton.icon(
            style: ElevatedButton.styleFrom(backgroundColor: AppTheme.primaryGreen),
            onPressed: () {
              Clipboard.setData(ClipboardData(text: csvData));
              Navigator.pop(ctx);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Municipal CSV Log copied to clipboard!'),
                  backgroundColor: AppTheme.primaryGreen,
                ),
              );
            },
            icon: const Icon(Icons.copy_rounded, size: 16),
            label: const Text('Copy CSV Log'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final provider = Provider.of<WasteRequestProvider>(context);
    final auth = Provider.of<AuthProvider>(context);
    final riders = auth.riders;

    List<WasteRequest> filtered = provider.adminFilteredRequests;

    if (_searchQuery.trim().isNotEmpty) {
      final q = _searchQuery.toLowerCase();
      filtered = filtered.where((r) {
        return r.id.toLowerCase().contains(q) ||
            r.userName.toLowerCase().contains(q) ||
            r.address.toLowerCase().contains(q) ||
            (r.assignedRiderName != null && r.assignedRiderName!.toLowerCase().contains(q));
      }).toList();
    }

    return Scaffold(
      appBar: RoleHeaderAppBar(
        title: 'Operations & Dispatch',
        actions: [
          IconButton(
            icon: const Icon(Icons.map_rounded, color: Color(0xFF0D6EFD)),
            tooltip: 'Live Waste Map',
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const InteractiveMapScreen()),
              );
            },
          ),
          IconButton(
            icon: const Icon(Icons.file_download_rounded, color: AppTheme.primaryGreen),
            tooltip: 'Export Municipal CSV Log',
            onPressed: () => _exportCsvDialog(context, provider),
          ),
          IconButton(
            icon: const Icon(Icons.account_balance_wallet_rounded, color: AppTheme.cashGold),
            tooltip: 'Reconcile Rider Cash Pouches',
            onPressed: () => _showReconciliationDialog(context, provider),
          ),
          IconButton(
            icon: const Icon(Icons.bar_chart_rounded, color: AppTheme.primaryGreen),
            tooltip: 'Eco Impact Stats',
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const EcoStatsScreen()),
              );
            },
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: () => provider.loadRequests(),
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // KPI METRICS OVERVIEW CARDS
              Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  children: [
                    Row(
                      children: [
                        _kpiCard(
                          title: 'Total Pickups',
                          value: '${provider.requests.length}',
                          icon: Icons.inventory_2_rounded,
                          color: const Color(0xFF6F42C1),
                        ),
                        const SizedBox(width: 12),
                        _kpiCard(
                          title: 'Pending Dispatch',
                          value: '${provider.pendingCount}',
                          icon: Icons.hourglass_top_rounded,
                          color: const Color(0xFFFB8C00),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        _kpiCard(
                          title: 'Hard Cash Collected',
                          value: '\$${provider.totalCashCollected.toStringAsFixed(2)}',
                          icon: Icons.payments_rounded,
                          color: AppTheme.cashGold,
                        ),
                        const SizedBox(width: 12),
                        _kpiCard(
                          title: 'Waste Diverted',
                          value: '${provider.totalWasteDivertedKg.toStringAsFixed(0)} kg',
                          icon: Icons.eco_rounded,
                          color: AppTheme.primaryGreen,
                        ),
                      ],
                    ),
                  ],
                ),
              ),

              // VIEW TOGGLE TABS (Dispatch Queue vs Fleet Riders)
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16.0),
                child: Row(
                  children: [
                    _viewButton(0, 'Dispatch Queue (${provider.requests.length})', Icons.assignment_rounded),
                    const SizedBox(width: 10),
                    _viewButton(1, 'Fleet Riders (${riders.length})', Icons.electric_moped_rounded),
                  ],
                ),
              ),
              const SizedBox(height: 14),

              if (_activeView == 0) ...[
                // SEARCH BAR
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16.0),
                  child: TextField(
                    controller: _searchController,
                    onChanged: (val) => setState(() => _searchQuery = val),
                    decoration: InputDecoration(
                      hintText: 'Filter requests by ID, resident, address, rider...',
                      prefixIcon: const Icon(Icons.search_rounded, size: 20),
                      suffixIcon: _searchQuery.isNotEmpty
                          ? IconButton(
                              icon: const Icon(Icons.clear, size: 18),
                              onPressed: () {
                                _searchController.clear();
                                setState(() => _searchQuery = '');
                              },
                            )
                          : null,
                      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                    ),
                  ),
                ),
                const SizedBox(height: 10),

                // FILTER CHIPS (All, Pending, Assigned, Collected)
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16.0),
                  child: SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: Row(
                      children: [
                        _chip(context, 'all', 'All (${provider.requests.length})', provider),
                        const SizedBox(width: 6),
                        _chip(context, 'pending', 'Pending (${provider.pendingCount})', provider),
                        const SizedBox(width: 6),
                        _chip(context, 'assigned', 'Assigned (${provider.assignedCount})', provider),
                        const SizedBox(width: 6),
                        _chip(context, 'collected', 'Done (${provider.collectedCount})', provider),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 12),

                // REQUESTS LIST
                if (filtered.isEmpty)
                  const Padding(
                    padding: EdgeInsets.all(40.0),
                    child: Center(
                      child: Text('No requests found under this filter.', style: TextStyle(color: AppTheme.textMuted)),
                    ),
                  )
                else
                  ...filtered.map((r) => _adminRequestTile(context, r, provider)),
              ] else ...[
                // FLEET & RIDERS DIRECTORY
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16.0),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        'Active Municipal Fleet',
                        style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                      ),
                      TextButton.icon(
                        onPressed: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(builder: (_) => const RegisterScreen()),
                          );
                        },
                        icon: const Icon(Icons.person_add_rounded, size: 16),
                        label: const Text('Add Rider'),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 8),
                if (riders.isEmpty)
                  const Padding(
                    padding: EdgeInsets.all(32.0),
                    child: Center(
                      child: Text('No collection riders registered.'),
                    ),
                  )
                else
                  ...riders.map((rider) => _buildRiderFleetCard(rider, provider)),
              ],
              const SizedBox(height: 60),
            ],
          ),
        ),
      ),
    );
  }

  Widget _viewButton(int index, String label, IconData icon) {
    final isSelected = _activeView == index;
    return Expanded(
      child: InkWell(
        onTap: () => setState(() => _activeView = index),
        borderRadius: BorderRadius.circular(12),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 10),
          decoration: BoxDecoration(
            color: isSelected ? const Color(0xFF6F42C1) : Colors.white,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: isSelected ? const Color(0xFF6F42C1) : const Color(0xFFDDDDDD),
            ),
          ),
          alignment: Alignment.center,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, size: 16, color: isSelected ? Colors.white : AppTheme.textMuted),
              const SizedBox(width: 6),
              Text(
                label,
                style: TextStyle(
                  fontWeight: FontWeight.w700,
                  fontSize: 12,
                  color: isSelected ? Colors.white : AppTheme.textMuted,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildRiderFleetCard(AppUser rider, WasteRequestProvider provider) {
    final activePickups = provider.getRiderAssignedRequests(rider.id);
    final settled = provider.getRiderCompletedRequests(rider.id);
    final cashInPouch = settled.fold(
      0.0,
      (sum, r) => sum + (r.actualCashPaid ?? r.estimatedCashAmount),
    );

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            Row(
              children: [
                UserAvatar(user: rider, radius: 24, showRoleBadge: true),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        rider.name,
                        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
                      ),
                      Text(
                        '${rider.vehicleInfo ?? 'Eco Tricycle'} • ${rider.phone}',
                        style: const TextStyle(fontSize: 12, color: AppTheme.textMuted),
                      ),
                      Text(
                        rider.address,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(fontSize: 11, color: AppTheme.textMuted),
                      ),
                    ],
                  ),
                ),
                IconButton.filledTonal(
                  onPressed: () => _callPhone(rider.phone),
                  icon: const Icon(Icons.phone_rounded, size: 18),
                  tooltip: 'Call Rider',
                ),
              ],
            ),
            const Divider(height: 20),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _fleetMetric('Assigned', '${activePickups.length}', const Color(0xFF0D6EFD)),
                _fleetMetric('Settled', '${settled.length}', AppTheme.primaryGreen),
                _fleetMetric('Cash Pouch', '\$${cashInPouch.toStringAsFixed(2)}', AppTheme.cashGold),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _fleetMetric(String label, String value, Color color) {
    return Column(
      children: [
        Text(value, style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: color)),
        Text(label, style: const TextStyle(fontSize: 11, color: AppTheme.textMuted)),
      ],
    );
  }

  Widget _kpiCard({
    required String title,
    required String value,
    required IconData icon,
    required Color color,
  }) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: const Color(0xFFEEEEEE)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(title, style: const TextStyle(fontSize: 12, color: AppTheme.textMuted)),
                Container(
                  padding: const EdgeInsets.all(6),
                  decoration: BoxDecoration(
                    color: color.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(icon, size: 18, color: color),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              value,
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.w800,
                color: color,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _chip(BuildContext context, String filter, String label, WasteRequestProvider provider) {
    final isSelected = provider.selectedFilter == filter;
    return ChoiceChip(
      label: Text(
        label,
        style: TextStyle(
          fontSize: 12,
          fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
          color: isSelected ? Colors.white : AppTheme.textDark,
        ),
      ),
      selected: isSelected,
      selectedColor: const Color(0xFF6F42C1),
      backgroundColor: Colors.white,
      side: BorderSide(
        color: isSelected ? const Color(0xFF6F42C1) : const Color(0xFFDDDDDD),
      ),
      onSelected: (_) => provider.setFilter(filter),
    );
  }

  Widget _adminRequestTile(BuildContext context, WasteRequest r, WasteRequestProvider provider) {
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      child: InkWell(
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => RequestDetailsScreen(request: r)),
          );
        },
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.all(14.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: r.category.color.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Icon(r.category.icon, size: 18, color: r.category.color),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          '${r.id} • ${r.category.title}',
                          style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 14),
                        ),
                        Text(
                          'Citizen: ${r.userName} (${r.userPhone})',
                          style: const TextStyle(fontSize: 12, color: AppTheme.textMuted),
                        ),
                      ],
                    ),
                  ),
                  StatusBadge(status: r.status),
                ],
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  const Icon(Icons.location_on_rounded, size: 14, color: Colors.redAccent),
                  const SizedBox(width: 4),
                  Expanded(
                    child: Text(
                      r.address,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(fontSize: 12, color: AppTheme.textDark),
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                    decoration: BoxDecoration(
                      color: AppTheme.accentMint,
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Text(
                      '${r.volumeSize.label} • ${r.quantityBags} units',
                      style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: AppTheme.primaryGreen),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              Row(
                children: [
                  Text(
                    r.isCashCollected
                        ? 'Cash Paid: \$${(r.actualCashPaid ?? r.estimatedCashAmount).toStringAsFixed(2)}'
                        : 'Est. Cash: \$${r.estimatedCashAmount.toStringAsFixed(2)}',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                      color: r.isCashCollected ? AppTheme.primaryGreen : AppTheme.cashGold,
                    ),
                  ),
                  const Spacer(),
                  if (r.status == RequestStatus.pending) ...[
                    ElevatedButton.icon(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF0D6EFD),
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                        minimumSize: Size.zero,
                      ),
                      onPressed: () => _showAssignRiderDialog(context, r, provider),
                      icon: const Icon(Icons.send_rounded, size: 14),
                      label: const Text('Dispatch Rider', style: TextStyle(fontSize: 12)),
                    ),
                  ] else if (r.status == RequestStatus.assigned) ...[
                    Row(
                      children: [
                        Text(
                          'Rider: ${r.assignedRiderName}',
                          style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Color(0xFF0D6EFD)),
                        ),
                        const SizedBox(width: 6),
                        OutlinedButton(
                          style: OutlinedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                            minimumSize: Size.zero,
                          ),
                          onPressed: () => _showAssignRiderDialog(context, r, provider),
                          child: const Text('Reassign', style: TextStyle(fontSize: 11)),
                        ),
                      ],
                    ),
                  ] else ...[
                    Text(
                      'Settled: ${r.receiptNumber ?? 'Receipt OK'}',
                      style: const TextStyle(fontSize: 11, color: AppTheme.primaryGreen, fontWeight: FontWeight.bold),
                    ),
                  ],
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showAssignRiderDialog(BuildContext context, WasteRequest r, WasteRequestProvider provider) {
    final auth = Provider.of<AuthProvider>(context, listen: false);
    final availableRiders = auth.riders;

    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(20.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Dispatch Rider for ${r.id}',
                style: const TextStyle(fontSize: 17, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 4),
              Text(
                'Waste: ${r.category.title} (${r.volumeSize.label} • ${r.quantityBags} bags) at ${r.address}',
                style: const TextStyle(fontSize: 12, color: AppTheme.textMuted),
              ),
              const SizedBox(height: 16),
              if (availableRiders.isEmpty)
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 20),
                  child: Column(
                    children: [
                      const Text('No riders currently registered in fleet.'),
                      const SizedBox(height: 10),
                      ElevatedButton.icon(
                        onPressed: () {
                          Navigator.pop(ctx);
                          Navigator.push(
                            context,
                            MaterialPageRoute(builder: (_) => const RegisterScreen()),
                          );
                        },
                        icon: const Icon(Icons.person_add_rounded),
                        label: const Text('Register Collection Rider'),
                      ),
                    ],
                  ),
                )
              else
                ...availableRiders.map((rider) => ListTile(
                      leading: UserAvatar(
                        user: rider,
                        radius: 20,
                        showRoleBadge: true,
                      ),
                      title: Text(rider.name, style: const TextStyle(fontWeight: FontWeight.w600)),
                      subtitle: Text('${rider.vehicleInfo ?? 'Tricycle Unit'} • ${rider.phone}'),
                      trailing: const Icon(Icons.send_rounded, color: Color(0xFF0D6EFD)),
                      onTap: () async {
                        await provider.assignRider(
                          requestId: r.id,
                          riderId: rider.id,
                          riderName: rider.name,
                        );
                        if (ctx.mounted) Navigator.pop(ctx);
                        if (context.mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text('Dispatched request ${r.id} to ${rider.name}!'),
                              backgroundColor: AppTheme.primaryGreen,
                            ),
                          );
                        }
                      },
                    )),
            ],
          ),
        ),
      ),
    );
  }

  void _showReconciliationDialog(BuildContext context, WasteRequestProvider provider) {
    final collectedRequests = provider.requests.where((r) => r.isCashCollected).toList();

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Row(
          children: [
            Icon(Icons.account_balance_wallet_rounded, color: AppTheme.cashGold),
            SizedBox(width: 8),
            Text('Daily Cash Reconciliation'),
          ],
        ),
        content: SizedBox(
          width: double.maxFinite,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Total Hard Cash Collected: \$${provider.totalCashCollected.toStringAsFixed(2)}',
                style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Color(0xFF664D03)),
              ),
              const SizedBox(height: 6),
              Text(
                'Audit records for ${collectedRequests.length} completed physical pickups:',
                style: const TextStyle(fontSize: 12, color: AppTheme.textMuted),
              ),
              const SizedBox(height: 12),
              Flexible(
                child: ListView.builder(
                  shrinkWrap: true,
                  itemCount: collectedRequests.length,
                  itemBuilder: (context, index) {
                    final r = collectedRequests[index];
                    return ListTile(
                      dense: true,
                      contentPadding: EdgeInsets.zero,
                      leading: const Icon(Icons.receipt_rounded, color: AppTheme.primaryGreen),
                      title: Text('${r.id} - ${r.receiptNumber ?? 'Receipt'}', style: const TextStyle(fontWeight: FontWeight.w600)),
                      subtitle: Text('Rider: ${r.assignedRiderName ?? 'Assigned'} • Cash: \$${(r.actualCashPaid ?? r.estimatedCashAmount).toStringAsFixed(2)}'),
                      trailing: const Icon(Icons.verified_rounded, color: AppTheme.primaryGreen, size: 18),
                    );
                  },
                ),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Close Audit View'),
          ),
        ],
      ),
    );
  }
}
