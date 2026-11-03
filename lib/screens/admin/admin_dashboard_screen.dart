import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../models/user_model.dart';
import '../../models/waste_request.dart';
import '../../providers/waste_request_provider.dart';
import '../../theme/app_theme.dart';
import '../../widgets/role_header_app_bar.dart';
import '../../widgets/status_badge.dart';
import '../citizen/request_details_screen.dart';
import '../common/eco_stats_screen.dart';

class AdminDashboardScreen extends StatelessWidget {
  const AdminDashboardScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final provider = Provider.of<WasteRequestProvider>(context);
    final filtered = provider.adminFilteredRequests;

    return Scaffold(
      appBar: RoleHeaderAppBar(
        title: 'Dispatch & Operations Admin',
        actions: [
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
                          title: 'Cash Collected',
                          value: '\$${provider.totalCashCollected.toStringAsFixed(2)}',
                          icon: Icons.payments_rounded,
                          color: AppTheme.cashGold,
                        ),
                        const SizedBox(width: 12),
                        _kpiCard(
                          title: 'Waste Diverted',
                          value: '${provider.totalCarbonSavedKg.toStringAsFixed(0)} kg',
                          icon: Icons.eco_rounded,
                          color: AppTheme.primaryGreen,
                        ),
                      ],
                    ),
                  ],
                ),
              ),

              // FILTER CHIPS (All, Pending, Assigned, Collected)
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16.0),
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
              const SizedBox(height: 40),
            ],
          ),
        ),
      ),
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
                Icon(icon, size: 20, color: color),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              value,
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.w900,
                color: color,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _chip(BuildContext context, String filterKey, String label, WasteRequestProvider provider) {
    final isSelected = provider.selectedFilter == filterKey;
    return Expanded(
      child: InkWell(
        onTap: () => provider.setFilter(filterKey),
        borderRadius: BorderRadius.circular(10),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 8),
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: isSelected ? AppTheme.darkForest : Colors.white,
            borderRadius: BorderRadius.circular(10),
            border: Border.all(
              color: isSelected ? AppTheme.darkForest : const Color(0xFFDDDDDD),
            ),
          ),
          child: Text(
            label,
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w700,
              color: isSelected ? Colors.white : AppTheme.textDark,
            ),
          ),
        ),
      ),
    );
  }

  Widget _adminRequestTile(BuildContext context, WasteRequest r, WasteRequestProvider provider) {
    final category = r.category;
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      child: Padding(
        padding: const EdgeInsets.all(14.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                CircleAvatar(
                  radius: 16,
                  backgroundColor: category.color.withValues(alpha: 0.15),
                  child: Icon(category.icon, size: 16, color: category.color),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('${category.title} • ${r.id}',
                          style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 14)),
                      Text('Citizen: ${r.userName} (${r.userPhone})',
                          style: const TextStyle(fontSize: 11, color: AppTheme.textMuted)),
                    ],
                  ),
                ),
                StatusBadge(status: r.status),
              ],
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                const Icon(Icons.location_on, size: 14, color: Colors.redAccent),
                const SizedBox(width: 4),
                Expanded(
                  child: Text(
                    r.address,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(fontSize: 12),
                  ),
                ),
                const SizedBox(width: 8),
                Text(
                  'GPS: (${r.latitude.toStringAsFixed(3)}, ${r.longitude.toStringAsFixed(3)})',
                  style: const TextStyle(fontSize: 10, color: AppTheme.textMuted),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                Text(
                  'Hard Cash: \$${r.estimatedCashAmount.toStringAsFixed(2)}',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                    color: r.isCashCollected ? AppTheme.primaryGreen : AppTheme.cashGold,
                  ),
                ),
                const Spacer(),
                if (r.assignedRiderName != null)
                  Text(
                    'Rider: ${r.assignedRiderName}',
                    style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: Color(0xFF0D6EFD)),
                  ),
              ],
            ),
            const SizedBox(height: 8),
            const Divider(height: 1),
            const SizedBox(height: 6),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                TextButton(
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (_) => RequestDetailsScreen(request: r)),
                    );
                  },
                  child: const Text('View Full Info', style: TextStyle(fontSize: 12)),
                ),
                if (r.status == RequestStatus.pending) ...[
                  const SizedBox(width: 6),
                  ElevatedButton.icon(
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                      backgroundColor: const Color(0xFF0D6EFD),
                    ),
                    icon: const Icon(Icons.person_add_alt_1_rounded, size: 14),
                    label: const Text('Assign Rider', style: TextStyle(fontSize: 12)),
                    onPressed: () => _showAssignRiderDialog(context, r, provider),
                  ),
                ],
              ],
            ),
          ],
        ),
      ),
    );
  }

  void _showAssignRiderDialog(BuildContext context, WasteRequest r, WasteRequestProvider provider) {
    final availableRiders = [
      AppUser.demoRider,
      const AppUser(
        id: 'rider_02',
        name: 'Brian Kato (Rider #05)',
        phone: '+256 702 334455',
        email: 'brian@ecoroute.app',
        role: UserRole.rider,
      ),
      const AppUser(
        id: 'rider_03',
        name: 'Emmanuel Ssebo (Rider #09)',
        phone: '+256 771 889900',
        email: 'emmanuel@ecoroute.app',
        role: UserRole.rider,
      ),
    ];

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
                'Waste: ${r.category.title} (${r.quantityBags} bags) at ${r.address}',
                style: const TextStyle(fontSize: 12, color: AppTheme.textMuted),
              ),
              const SizedBox(height: 16),
              ...availableRiders.map((rider) => ListTile(
                    leading: const CircleAvatar(
                      backgroundColor: Color(0xFFE7F1FF),
                      child: Icon(Icons.two_wheeler, color: Color(0xFF0D6EFD)),
                    ),
                    title: Text(rider.name, style: const TextStyle(fontWeight: FontWeight.w600)),
                    subtitle: Text('Contact: ${rider.phone}'),
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
}
