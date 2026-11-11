import 'package:flutter/material.dart';
import '../../../main.dart';
import 'admin_chart_painters.dart';

/// Screen 3: Photo Evidence & Rider Approvals View (Image 3)
/// Shows verified commercial waste collection photos and a live queue of pending rider approvals.
class AdminApprovalsView extends StatefulWidget {
  const AdminApprovalsView({super.key});

  @override
  State<AdminApprovalsView> createState() => _AdminApprovalsViewState();
}

class _AdminApprovalsViewState extends State<AdminApprovalsView> {
  String _selectedCategory = 'All';

  final List<Map<String, dynamic>> _mockEvidenceList = [
    {
      'id': 'EV-9482',
      'taskId': '#ER8432',
      'client': 'Ayiko Gift',
      'location': 'Block 3, Arua Hill',
      'wasteType': 'Commercial Organic',
      'rider': 'Okello John',
      'time': '10:14 AM',
      'date': 'Today',
      'gps': '3.0303° N, 30.9073° E',
      'status': 'Verified',
      'volume': '1.2 Tons',
      'typeIndex': 0,
    },
    {
      'id': 'EV-9481',
      'taskId': '#ER8431',
      'client': 'Gulu Logistics Ltd',
      'location': 'Industrial Area, Arua',
      'wasteType': 'Industrial Mixed',
      'rider': 'Kato David',
      'time': '09:45 AM',
      'date': 'Today',
      'gps': '3.0245° N, 30.9120° E',
      'status': 'Verified',
      'volume': '2.8 Tons',
      'typeIndex': 1,
    },
    {
      'id': 'EV-9480',
      'taskId': '#ER8430',
      'client': 'West Nile Traders',
      'location': 'Arua Main Market',
      'wasteType': 'Recyclable Plastics',
      'rider': 'Mukasa Paul',
      'time': '09:12 AM',
      'date': 'Today',
      'gps': '3.0315° N, 30.9060° E',
      'status': 'Verified',
      'volume': '850 Kg',
      'typeIndex': 0,
    },
    {
      'id': 'EV-9479',
      'taskId': '#ER8429',
      'client': 'Arua Agri Hub',
      'location': 'Hospital Road',
      'wasteType': 'Bio-Waste Composting',
      'rider': 'Opio Francis',
      'time': '08:30 AM',
      'date': 'Today',
      'gps': '3.0280° N, 30.9095° E',
      'status': 'Verified',
      'volume': '1.5 Tons',
      'typeIndex': 1,
    },
  ];

  // Local pending approvals list
  final List<Map<String, dynamic>> _pendingRiders = [
    {
      'name': 'Drileba Emmanuel',
      'phone': '+256 772 112233',
      'vehicle': 'Motorcycle (Bajaj Boxer)',
      'nationalId': 'CM940284729102',
      'license': 'Permit #DL-88219 (Class A)',
      'appliedDate': 'Today, 08:15 AM',
      'status': 'Pending Approval',
    },
    {
      'name': 'Atiku Samuel',
      'phone': '+256 701 445566',
      'vehicle': 'Truck (Isuzu 3-Ton)',
      'nationalId': 'CM910183748291',
      'license': 'Permit #DL-74910 (Class B)',
      'appliedDate': 'Yesterday, 04:30 PM',
      'status': 'Pending Approval',
    },
    {
      'name': 'Buga Denis',
      'phone': '+256 782 998877',
      'vehicle': 'Tricycle (Tuk-Tuk Hauler)',
      'nationalId': 'CM960274619283',
      'license': 'Permit #DL-63102 (Class A1)',
      'appliedDate': '2 Days ago',
      'status': 'Pending Approval',
    },
  ];

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final screenWidth = MediaQuery.of(context).size.width;
    final isDesktop = screenWidth >= 1024;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Photo Evidence & Rider Approvals',
                      style: theme.textTheme.headlineSmall?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: isDark ? Colors.white : const Color(0xFF1E293B),
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Audit verified field waste collection evidence and review pending driver applications.',
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B),
                      ),
                    ),
                  ],
                ),
              ),
              OutlinedButton.icon(
                onPressed: () {
                  setState(() {});
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Evidence and approval queues refreshed.')),
                  );
                },
                icon: const Icon(Icons.refresh, size: 18),
                label: const Text('Refresh'),
                style: OutlinedButton.styleFrom(
                  foregroundColor: const Color(0xFF2E7D32),
                  side: const BorderSide(color: Color(0xFF2E7D32)),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),

          // Main Layout: Photo Evidence Feed + Pending Rider Approvals
          if (isDesktop)
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  flex: 3,
                  child: _buildEvidenceFeed(context, isDark),
                ),
                const SizedBox(width: 24),
                Expanded(
                  flex: 2,
                  child: _buildRiderApprovalsCard(context, isDark),
                ),
              ],
            )
          else ...[
            _buildEvidenceFeed(context, isDark),
            const SizedBox(height: 24),
            _buildRiderApprovalsCard(context, isDark),
          ],
        ],
      ),
    );
  }

  Widget _buildEvidenceFeed(BuildContext context, bool isDark) {
    final theme = Theme.of(context);
    final filtered = _mockEvidenceList.where((item) {
      if (_selectedCategory == 'All') return true;
      return item['wasteType'].toString().toLowerCase().contains(_selectedCategory.toLowerCase());
    }).toList();

    return Container(
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E293B) : Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0),
        ),
      ),
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  const Icon(Icons.camera_alt_outlined, color: Color(0xFF2E7D32), size: 22),
                  const SizedBox(width: 8),
                  Text(
                    'Recent Photo Evidence Feed',
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: isDark ? Colors.white : const Color(0xFF1E293B),
                    ),
                  ),
                ],
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: const Color(0xFFE8F5E9),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.verified, size: 14, color: Color(0xFF2E7D32)),
                    const SizedBox(width: 4),
                    Text(
                      '${_mockEvidenceList.length} Verified Today',
                      style: const TextStyle(
                        color: Color(0xFF2E7D32),
                        fontWeight: FontWeight.w600,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),

          // Categories Filter Row
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: ['All', 'Organic', 'Industrial', 'Plastics', 'Bio-Waste'].map((cat) {
                final isSelected = _selectedCategory == cat;
                return Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: FilterChip(
                    label: Text(cat),
                    selected: isSelected,
                    onSelected: (val) {
                      setState(() => _selectedCategory = cat);
                    },
                    selectedColor: const Color(0xFF2E7D32).withOpacity(0.15),
                    checkmarkColor: const Color(0xFF2E7D32),
                    labelStyle: TextStyle(
                      color: isSelected
                          ? const Color(0xFF2E7D32)
                          : (isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B)),
                      fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                      fontSize: 12,
                    ),
                    backgroundColor: isDark ? const Color(0xFF0F172A) : const Color(0xFFF8FAFC),
                    side: BorderSide(
                      color: isSelected
                          ? const Color(0xFF2E7D32)
                          : (isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0)),
                    ),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                  ),
                );
              }).toList(),
            ),
          ),
          const SizedBox(height: 16),

          // Grid of Evidence Cards
          LayoutBuilder(
            builder: (context, constraints) {
              final crossAxisCount = constraints.maxWidth > 580 ? 2 : 1;
              return GridView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: filtered.length,
                gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: crossAxisCount,
                  crossAxisSpacing: 16,
                  mainAxisSpacing: 16,
                  mainAxisExtent: 310,
                ),
                itemBuilder: (context, index) {
                  final ev = filtered[index];
                  return _buildEvidenceItemCard(context, ev, isDark);
                },
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildEvidenceItemCard(BuildContext context, Map<String, dynamic> ev, bool isDark) {
    return Container(
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF0F172A) : const Color(0xFFF8FAFC),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(
          color: isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0),
        ),
      ),
      clipBehavior: Clip.antiAlias,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Visual Evidence Canvas
          Stack(
            children: [
              SizedBox(
                height: 140,
                width: double.infinity,
                child: CustomPaint(
                  painter: PhotoEvidenceThumbnailPainter(type: ev['typeIndex'] as int),
                ),
              ),
              Positioned(
                top: 8,
                left: 8,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: Colors.black.withOpacity(0.65),
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.verified, size: 12, color: Color(0xFF4CAF50)),
                      const SizedBox(width: 4),
                      Text(
                        ev['status'],
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 11,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              Positioned(
                top: 8,
                right: 8,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: const Color(0xFF2E7D32),
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Text(
                    ev['volume'],
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 11,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
              Positioned(
                bottom: 6,
                left: 8,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                  decoration: BoxDecoration(
                    color: Colors.black.withOpacity(0.6),
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.location_on, size: 10, color: Colors.white70),
                      const SizedBox(width: 2),
                      Text(
                        ev['gps'],
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 10,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),

          // Metadata & Actions
          Padding(
            padding: const EdgeInsets.all(12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      ev['taskId'],
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 14,
                        color: Color(0xFF2E7D32),
                      ),
                    ),
                    Text(
                      ev['time'],
                      style: TextStyle(
                        fontSize: 11,
                        color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  ev['client'],
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 13,
                    color: isDark ? Colors.white : const Color(0xFF1E293B),
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                Text(
                  '${ev['location']} • ${ev['wasteType']}',
                  style: TextStyle(
                    fontSize: 11,
                    color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B),
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    CircleAvatar(
                      radius: 9,
                      backgroundColor: isDark ? const Color(0xFF334155) : const Color(0xFFCBD5E1),
                      child: const Icon(Icons.person, size: 12, color: Colors.white),
                    ),
                    const SizedBox(width: 6),
                    Expanded(
                      child: Text(
                        'Collector: ${ev['rider']}',
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w500,
                          color: isDark ? const Color(0xFFCBD5E1) : const Color(0xFF475569),
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    InkWell(
                      onTap: () => _showEvidenceDetailsDialog(context, ev),
                      child: const Padding(
                        padding: EdgeInsets.symmetric(horizontal: 4, vertical: 2),
                        child: Text(
                          'View Audit Log',
                          style: TextStyle(
                            fontSize: 11,
                            color: Color(0xFF2E7D32),
                            fontWeight: FontWeight.bold,
                            decoration: TextDecoration.underline,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRiderApprovalsCard(BuildContext context, bool isDark) {
    final theme = Theme.of(context);
    final state = EcoRouteState.instance;

    // Combine local pending with any pending in EcoRouteState.instance.invitedRiders
    final pendingInvites = state.invitedRiders.where((r) {
      final status = (r['status'] ?? '').toString().toLowerCase();
      return status != 'active';
    }).toList();

    return Container(
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E293B) : Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0),
        ),
      ),
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  const Icon(Icons.assignment_ind_outlined, color: Color(0xFF2E7D32), size: 22),
                  const SizedBox(width: 8),
                  Text(
                    'Pending Rider Approvals',
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: isDark ? Colors.white : const Color(0xFF1E293B),
                    ),
                  ),
                ],
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: const Color(0xFFFEF3C7),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  '${_pendingRiders.length + pendingInvites.length} Pending',
                  style: const TextStyle(
                    color: Color(0xFFB45309),
                    fontWeight: FontWeight.bold,
                    fontSize: 12,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Text(
            'Review submitted driver permits, national IDs, and vehicle registrations before enabling field dispatch access.',
            style: TextStyle(
              fontSize: 12,
              color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B),
            ),
          ),
          const SizedBox(height: 16),

          // Pending List
          if (_pendingRiders.isEmpty && pendingInvites.isEmpty)
            Center(
              child: Padding(
                padding: const EdgeInsets.all(32),
                child: Column(
                  children: [
                    const Icon(Icons.check_circle_outline, size: 48, color: Color(0xFF2E7D32)),
                    const SizedBox(height: 12),
                    Text(
                      'No pending rider approvals',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: isDark ? Colors.white : const Color(0xFF1E293B),
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'All submitted driver profiles are actively reviewed and verified.',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 12,
                        color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B),
                      ),
                    ),
                  ],
                ),
              ),
            )
          else ...[
            ..._pendingRiders.map((rider) => _buildPendingRiderTile(context, rider, isDark, isMock: true)),
            ...pendingInvites.map((invite) => _buildPendingRiderTile(
              context,
              {
                'name': invite['name'] ?? 'Field Rider',
                'phone': invite['phone'] ?? '',
                'vehicle': invite['tricycleId'] ?? 'Field Vehicle',
                'nationalId': 'Pending Doc Verification',
                'license': 'PIN: ${invite['temporaryPin'] ?? invite['inviteCode'] ?? ''}',
                'appliedDate': 'Recent Invitation',
                'status': invite['status'] ?? 'Pending',
              },
              isDark,
              isMock: false,
              rawInvitePhone: invite['phone']?.toString(),
            )),
          ],
        ],
      ),
    );
  }

  Widget _buildPendingRiderTile(
    BuildContext context,
    Map<String, dynamic> rider,
    bool isDark, {
    required bool isMock,
    String? rawInvitePhone,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF0F172A) : const Color(0xFFF8FAFC),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              CircleAvatar(
                radius: 20,
                backgroundColor: const Color(0xFF2E7D32).withOpacity(0.15),
                child: Text(
                  rider['name'].toString().isNotEmpty ? rider['name'][0] : 'R',
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF2E7D32),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      rider['name'],
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 14,
                        color: isDark ? Colors.white : const Color(0xFF1E293B),
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      '${rider['phone']} • ${rider['vehicle']}',
                      style: TextStyle(
                        fontSize: 12,
                        color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B),
                      ),
                    ),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: const Color(0xFFFEF3C7),
                  borderRadius: BorderRadius.circular(4),
                ),
                child: const Text(
                  'Pending',
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFFB45309),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: isDark ? const Color(0xFF1E293B) : const Color(0xFFF1F5F9),
              borderRadius: BorderRadius.circular(6),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Text(
                    'ID: ${rider['nationalId']}',
                    style: TextStyle(
                      fontSize: 11,
                      color: isDark ? const Color(0xFFCBD5E1) : const Color(0xFF475569),
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                Text(
                  rider['license'],
                  style: const TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF2E7D32),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: () {
                    setState(() {
                      if (isMock) {
                        _pendingRiders.remove(rider);
                      } else if (rawInvitePhone != null) {
                        EcoRouteState.instance.approveRider(rawInvitePhone);
                      }
                    });
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        backgroundColor: const Color(0xFF2E7D32),
                        content: Text('Rider ${rider['name']} activated & dispatched to fleet!'),
                      ),
                    );
                  },
                  icon: const Icon(Icons.check, size: 16),
                  label: const Text('Approve Rider'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF2E7D32),
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
                    padding: const EdgeInsets.symmetric(vertical: 10),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              OutlinedButton(
                onPressed: () {
                  setState(() {
                    if (isMock) {
                      _pendingRiders.remove(rider);
                    }
                  });
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('Application for ${rider['name']} declined.'),
                    ),
                  );
                },
                style: OutlinedButton.styleFrom(
                  foregroundColor: const Color(0xFFEF4444),
                  side: const BorderSide(color: Color(0xFFEF4444)),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                ),
                child: const Text('Decline'),
              ),
            ],
          ),
        ],
      ),
    );
  }

  void _showEvidenceDetailsDialog(BuildContext context, Map<String, dynamic> ev) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: isDark ? const Color(0xFF1E293B) : Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        title: Row(
          children: [
            const Icon(Icons.verified, color: Color(0xFF2E7D32)),
            const SizedBox(width: 8),
            Text('Collection Evidence: ${ev['taskId']}'),
          ],
        ),
        content: SizedBox(
          width: 500,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              SizedBox(
                height: 180,
                width: double.infinity,
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: CustomPaint(
                    painter: PhotoEvidenceThumbnailPainter(type: ev['typeIndex'] as int),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              _buildAuditRow('Client Name', ev['client'], isDark),
              _buildAuditRow('Location', ev['location'], isDark),
              _buildAuditRow('GPS Coordinates', ev['gps'], isDark),
              _buildAuditRow('Waste Classification', ev['wasteType'], isDark),
              _buildAuditRow('Logged Volume', ev['volume'], isDark),
              _buildAuditRow('Field Collector', ev['rider'], isDark),
              _buildAuditRow('Timestamp', '${ev['date']} at ${ev['time']}', isDark),
              _buildAuditRow('Audit Status', 'Cryptographically Signed • Immutable', isDark, isGreen: true),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }

  Widget _buildAuditRow(String label, String value, bool isDark, {bool isGreen = false}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: TextStyle(
              fontSize: 12,
              color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B),
            ),
          ),
          Text(
            value,
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.bold,
              color: isGreen
                  ? const Color(0xFF2E7D32)
                  : (isDark ? Colors.white : const Color(0xFF1E293B)),
            ),
          ),
        ],
      ),
    );
  }
}
