import 'package:flutter/material.dart';

import '../../../core/layout/adaptive_layout.dart';
import '../../../core/theme/eco_palette.dart';
import '../../../main.dart';

/// Screen 4: Fleet & Riders Roster
/// Fully dynamic - reads directly from authentic state with zero hardcoded/mock riders.
class AdminFleetView extends StatefulWidget {
  const AdminFleetView({
    super.key,
    required this.onShowAddRiderDialog,
  });

  final VoidCallback onShowAddRiderDialog;

  @override
  State<AdminFleetView> createState() => _AdminFleetViewState();
}

class _AdminFleetViewState extends State<AdminFleetView> {
  void _handleRiderAction(Map<String, dynamic> rider) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Dispatched management action for ${rider['name']} (${rider['vehicle']})'),
        backgroundColor: const Color(0xFF1B5E20),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final state = EcoRouteState.instance;
    final isDark = AntigravityTheme.isDark(context);
    final cardColor = isDark ? const Color(0xFF1E293B) : Colors.white;
    final textColor = AntigravityTheme.textPrimary(context);
    final subtextColor = AntigravityTheme.textSecondary(context);
    final borderColor = isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0);
    const brandGreen = Color(0xFF1B5E20);

    // Merge authentic registered riders and invited riders from state
    final List<Map<String, dynamic>> allRiders = [];
    final seenPhones = <String>{};

    for (final r in state.riderRoster) {
      final phone = (r['phone'] ?? '').toString();
      if (!seenPhones.contains(phone)) {
        seenPhones.add(phone);
        allRiders.add({
          'name': r['name'] ?? 'Rider',
          'vehicle': r['tricycleId'] ?? r['vehicle'] ?? 'Motorcycle',
          'vehicleIcon': Icons.two_wheeler,
          'status': r['status'] ?? 'Active',
          'statusType': (r['status'] ?? '').toString().toLowerCase().contains('active') ? 'active' : 'idle',
          'phone': phone,
          'action': 'Manage / Dispatch',
        });
      }
    }

    for (final inv in state.invitedRiders) {
      final phone = (inv['phone'] ?? '').toString();
      if (!seenPhones.contains(phone)) {
        seenPhones.add(phone);
        final status = (inv['status'] ?? 'Invited').toString();
        allRiders.add({
          'name': inv['fullName'] ?? inv['name'] ?? 'Invited Rider',
          'vehicle': inv['tricycleId'] ?? 'Field Vehicle',
          'vehicleIcon': Icons.two_wheeler,
          'status': status.toLowerCase() == 'active' ? 'Active' : 'Pending Activation',
          'statusType': status.toLowerCase() == 'active' ? 'active' : 'idle',
          'phone': phone,
          'action': 'View Invite',
        });
      }
    }

    final activeCount = allRiders.where((r) => r['statusType'] == 'active').length;
    final onRouteCount = allRiders.where((r) => r['statusType'] == 'onRoute').length;
    final idleCount = allRiders.where((r) => r['statusType'] == 'idle').length;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header Row: Title & Subtitle on left, Add New Rider button on right
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Fleet & Riders',
                    style: TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                      color: textColor,
                      letterSpacing: -0.5,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Monitor active, idle, and on-route delivery riders.',
                    style: TextStyle(fontSize: 13, color: subtextColor),
                  ),
                ],
              ),
              ElevatedButton.icon(
                onPressed: widget.onShowAddRiderDialog,
                style: ElevatedButton.styleFrom(
                  backgroundColor: brandGreen,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                  elevation: 0,
                ),
                icon: const Icon(Icons.add, size: 18),
                label: const Text('Add New Rider', style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold)),
              ),
            ],
          ),

          const SizedBox(height: 20),

          // Summary Stats Pills
          Row(
            children: [
              _buildStatsPill('Active: $activeCount', const Color(0xFFE8F5E9), const Color(0xFF2E7D32), Icons.eco),
              const SizedBox(width: 12),
              _buildStatsPill('On-Route: $onRouteCount', const Color(0xFFFFF3E0), const Color(0xFFE65100), Icons.local_shipping_outlined),
              const SizedBox(width: 12),
              _buildStatsPill('Idle: $idleCount', isDark ? const Color(0xFF334155) : const Color(0xFFF1F5F9), subtextColor, Icons.access_time),
            ],
          ),

          const SizedBox(height: 24),

          // Grid of Rider Cards or Empty State
          if (allRiders.isEmpty)
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(vertical: 48, horizontal: 24),
              decoration: BoxDecoration(
                color: cardColor,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: borderColor),
              ),
              child: Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: brandGreen.withOpacity(0.08),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(Icons.two_wheeler, size: 42, color: brandGreen),
                    ),
                    const SizedBox(height: 16),
                    Text(
                      'No Riders Registered or Invited Yet',
                      style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: textColor),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      'No field drivers have been invited or registered yet.\nClick "Add New Rider" above to dispatch an onboarding invitation PIN.',
                      textAlign: TextAlign.center,
                      style: TextStyle(fontSize: 13, color: subtextColor, height: 1.4),
                    ),
                    const SizedBox(height: 20),
                    ElevatedButton.icon(
                      onPressed: widget.onShowAddRiderDialog,
                      icon: const Icon(Icons.person_add, size: 16),
                      label: const Text('Add New Rider'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: brandGreen,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                      ),
                    ),
                  ],
                ),
              ),
            )
          else
            LayoutBuilder(
              builder: (context, constraints) {
                final crossAxisCount = constraints.maxWidth >= 1000 ? 3 : (constraints.maxWidth >= 640 ? 2 : 1);
                return GridView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: crossAxisCount,
                    crossAxisSpacing: 16,
                    mainAxisSpacing: 16,
                    childAspectRatio: 2.1,
                  ),
                  itemCount: allRiders.length,
                  itemBuilder: (context, index) {
                    final r = allRiders[index];
                    Color pillBg;
                    Color pillColor;

                    switch (r['statusType']) {
                      case 'active':
                        pillBg = const Color(0xFFE8F5E9);
                        pillColor = const Color(0xFF2E7D32);
                        break;
                      case 'onRoute':
                        pillBg = const Color(0xFFFFF3E0);
                        pillColor = const Color(0xFFE65100);
                        break;
                      default:
                        pillBg = isDark ? const Color(0xFF334155) : const Color(0xFFF1F5F9);
                        pillColor = subtextColor;
                    }

                    return Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: cardColor,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: borderColor),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.02),
                            blurRadius: 8,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          // Avatar, Name, Vehicle
                          Row(
                            children: [
                              CircleAvatar(
                                radius: 20,
                                backgroundColor: brandGreen.withOpacity(0.12),
                                child: Text(
                                  (r['name'] as String).isNotEmpty ? (r['name'] as String)[0].toUpperCase() : 'R',
                                  style: const TextStyle(fontWeight: FontWeight.bold, color: brandGreen, fontSize: 16),
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      r['name'] as String,
                                      style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: textColor),
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                    Row(
                                      children: [
                                        Icon(r['vehicleIcon'] as IconData, size: 14, color: subtextColor),
                                        const SizedBox(width: 4),
                                        Expanded(
                                          child: Text(
                                            r['vehicle'] as String,
                                            style: TextStyle(fontSize: 12, color: subtextColor),
                                            maxLines: 1,
                                            overflow: TextOverflow.ellipsis,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),

                          // Status badge
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                            decoration: BoxDecoration(
                              color: pillBg,
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: Text(
                              r['status'] as String,
                              style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: pillColor),
                            ),
                          ),

                          // Action footer
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text('Action', style: TextStyle(fontSize: 11, color: subtextColor)),
                              InkWell(
                                onTap: () => _handleRiderAction(r),
                                child: Text(
                                  r['action'] as String,
                                  style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: brandGreen),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    );
                  },
                );
              },
            ),
        ],
      ),
    );
  }

  Widget _buildStatsPill(String text, Color bg, Color color, IconData icon) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: color),
          const SizedBox(width: 6),
          Text(text, style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: color)),
        ],
      ),
    );
  }
}
