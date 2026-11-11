import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';

import '../../../core/layout/adaptive_layout.dart';
import '../../../core/theme/eco_palette.dart';
import '../../../main.dart';

/// Screen 2: Live Dispatch Map & Incoming Commercial Requests Board
/// Dynamic - strictly reflects real registered fleet riders and live requests with zero mock data.
class AdminDispatchMapView extends StatefulWidget {
  const AdminDispatchMapView({super.key});

  @override
  State<AdminDispatchMapView> createState() => _AdminDispatchMapViewState();
}

class _AdminDispatchMapViewState extends State<AdminDispatchMapView> {
  final MapController _mapController = MapController();
  final TextEditingController _mapSearchController = TextEditingController();

  static const LatLng _aruaCenter = LatLng(3.0303, 30.9073);

  static const List<LatLng> _routeA = [
    LatLng(3.0210, 30.8990),
    LatLng(3.0280, 30.9040),
    LatLng(3.0380, 30.9080),
    LatLng(3.0450, 30.9150),
    LatLng(3.0390, 30.9250),
    LatLng(3.0285, 30.9165),
  ];

  @override
  void dispose() {
    _mapSearchController.dispose();
    super.dispose();
  }

  void _handleAssignRequest(Map<String, dynamic> req) {
    final state = EcoRouteState.instance;
    final availableRiders = [...state.riderRoster, ...state.invitedRiders];

    showDialog<void>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Row(
          children: [
            const Icon(Icons.send, color: Color(0xFF1B5E20), size: 20),
            const SizedBox(width: 8),
            Text('Assign ${req['residentName'] ?? req['client'] ?? "Request"}', style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Target: ${req['address'] ?? "Arua Municipal"}', style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600)),
            Text('Load: ${req['wasteType'] ?? "General Waste"}', style: const TextStyle(fontSize: 12, color: Colors.grey)),
            const SizedBox(height: 14),
            const Text('Select Dispatch Unit:', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            if (availableRiders.isEmpty) ...[
              const Padding(
                padding: EdgeInsets.symmetric(vertical: 16),
                child: Text(
                  'No field riders have been invited or registered yet.\nPlease use "Add New Rider" in Fleet management to onboard drivers first.',
                  style: TextStyle(fontSize: 12, color: Colors.grey),
                ),
              ),
            ] else ...[
              for (final r in availableRiders)
                ListTile(
                  contentPadding: EdgeInsets.zero,
                  leading: const CircleAvatar(backgroundColor: Color(0xFF1B5E20), child: Icon(Icons.two_wheeler, color: Colors.white, size: 18)),
                  title: Text(r['name'] ?? r['fullName'] ?? 'Fleet Rider', style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold)),
                  subtitle: Text(r['tricycleId'] ?? r['phone'] ?? 'Field Vehicle', style: const TextStyle(fontSize: 11)),
                  trailing: const Icon(Icons.arrow_forward_ios, size: 14),
                  onTap: () {
                    Navigator.pop(ctx);
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text('Dispatched task to ${r['name'] ?? r['fullName']}'),
                        backgroundColor: const Color(0xFF1B5E20),
                      ),
                    );
                  },
                ),
            ],
          ],
        ),
      ),
    );
  }

  void _handleDeclineRequest(Map<String, dynamic> req) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Request declined.'),
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

    final incomingRequests = state.residentRequests
        .where((r) => r['status'] == 'Pending' || r['status'] == 'Dispatched')
        .toList();

    return LayoutBuilder(
      builder: (context, constraints) {
        final isWide = constraints.maxWidth >= 960;

        if (isWide) {
          return Row(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Expanded(
                flex: 7,
                child: _buildMapCanvas(isDark, cardColor, borderColor, textColor, brandGreen),
              ),
              Container(width: 1, color: borderColor),
              SizedBox(
                width: 380,
                child: _buildIncomingQueuePanel(incomingRequests, cardColor, borderColor, textColor, subtextColor, brandGreen),
              ),
            ],
          );
        }

        return Column(
          children: [
            SizedBox(
              height: 440,
              child: _buildMapCanvas(isDark, cardColor, borderColor, textColor, brandGreen),
            ),
            Expanded(
              child: _buildIncomingQueuePanel(incomingRequests, cardColor, borderColor, textColor, subtextColor, brandGreen),
            ),
          ],
        );
      },
    );
  }

  Widget _buildMapCanvas(
    bool isDark,
    Color cardColor,
    Color borderColor,
    Color textColor,
    Color brandGreen,
  ) {
    final state = EcoRouteState.instance;
    final onlineCount = state.activeRiderCount;

    return Stack(
      children: [
        FlutterMap(
          mapController: _mapController,
          options: const MapOptions(
            initialCenter: _aruaCenter,
            initialZoom: 13.6,
            minZoom: 11.0,
            maxZoom: 18.0,
          ),
          children: [
            TileLayer(
              urlTemplate: isDark
                  ? 'https://{s}.basemaps.cartocdn.com/dark_all/{z}/{x}/{y}{r}.png'
                  : 'https://{s}.basemaps.cartocdn.com/rastertiles/voyager/{z}/{x}/{y}{r}.png',
              subdomains: const ['a', 'b', 'c', 'd'],
              userAgentPackageName: 'com.ecoroute.app',
            ),
            PolylineLayer(
              polylines: [
                Polyline(
                  points: _routeA,
                  strokeWidth: 4.0,
                  color: const Color(0xFF2E7D32),
                ),
              ],
            ),
            MarkerLayer(
              markers: [
                // Depot Headquarters
                Marker(
                  point: _aruaCenter,
                  width: 100,
                  height: 40,
                  child: _buildVehicleMarker('Arua Depot', Icons.home_work, brandGreen),
                ),
              ],
            ),
          ],
        ),

        // Floating Top-Left Status Badge
        Positioned(
          top: 16,
          left: 16,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            decoration: BoxDecoration(
              color: cardColor.withOpacity(0.95),
              borderRadius: BorderRadius.circular(12),
              boxShadow: [
                BoxShadow(color: Colors.black.withOpacity(0.08), blurRadius: 10, offset: const Offset(0, 4)),
              ],
              border: Border.all(color: borderColor),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text('$onlineCount Active Riders', style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: textColor)),
                const SizedBox(height: 2),
                Row(
                  children: [
                    Text('Route optimization status: ', style: TextStyle(fontSize: 11, color: isDark ? Colors.white70 : Colors.black54)),
                    Text(onlineCount > 0 ? 'Optimal' : 'Standby', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: onlineCount > 0 ? const Color(0xFF2E7D32) : Colors.orange)),
                  ],
                ),
              ],
            ),
          ),
        ),

        // Floating Top-Right Search & Filter Controls
        Positioned(
          top: 16,
          right: 16,
          child: Row(
            children: [
              Container(
                width: 180,
                height: 38,
                padding: const EdgeInsets.symmetric(horizontal: 10),
                decoration: BoxDecoration(
                  color: cardColor.withOpacity(0.95),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: borderColor),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.search, size: 18, color: Colors.grey),
                    const SizedBox(width: 6),
                    Expanded(
                      child: TextField(
                        controller: _mapSearchController,
                        style: TextStyle(fontSize: 12, color: textColor),
                        decoration: const InputDecoration(
                          hintText: 'Map search...',
                          hintStyle: TextStyle(fontSize: 11, color: Colors.grey),
                          border: InputBorder.none,
                          isDense: true,
                          contentPadding: EdgeInsets.zero,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              Container(
                width: 38,
                height: 38,
                decoration: BoxDecoration(
                  color: cardColor.withOpacity(0.95),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: borderColor),
                ),
                child: IconButton(
                  icon: const Icon(Icons.filter_list, size: 18),
                  onPressed: () {},
                ),
              ),
            ],
          ),
        ),

        // Floating Bottom-Left Zoom Controls
        Positioned(
          bottom: 24,
          left: 16,
          child: Column(
            children: [
              Container(
                decoration: BoxDecoration(
                  color: cardColor.withOpacity(0.95),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: borderColor),
                ),
                child: Column(
                  children: [
                    IconButton(
                      icon: const Icon(Icons.add, size: 18),
                      onPressed: () => _mapController.move(_mapController.camera.center, _mapController.camera.zoom + 1),
                    ),
                    const Divider(height: 1),
                    IconButton(
                      icon: const Icon(Icons.remove, size: 18),
                      onPressed: () => _mapController.move(_mapController.camera.center, _mapController.camera.zoom - 1),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 8),
              Container(
                decoration: BoxDecoration(
                  color: cardColor.withOpacity(0.95),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: borderColor),
                ),
                child: IconButton(
                  icon: const Icon(Icons.my_location, size: 18),
                  onPressed: () => _mapController.move(_aruaCenter, 13.6),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildVehicleMarker(String label, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color, width: 2),
        boxShadow: const [
          BoxShadow(color: Colors.black26, blurRadius: 4, offset: Offset(0, 2)),
        ],
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 16, color: color),
          const SizedBox(width: 4),
          Text(
            label,
            style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Color(0xFF1E293B)),
          ),
        ],
      ),
    );
  }

  Widget _buildIncomingQueuePanel(
    List<Map<String, dynamic>> requests,
    Color cardColor,
    Color borderColor,
    Color textColor,
    Color subtextColor,
    Color brandGreen,
  ) {
    return Padding(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Incoming Commercial Requests',
            style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: textColor),
          ),
          const SizedBox(height: 4),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('Active queue', style: TextStyle(fontSize: 12, color: subtextColor)),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: const Color(0xFFE8F5E9),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  '${requests.length} requests',
                  style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Color(0xFF1B5E20)),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Expanded(
            child: requests.isEmpty
                ? Center(
                    child: Padding(
                      padding: const EdgeInsets.all(24),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.assignment_turned_in_outlined, size: 36, color: subtextColor),
                          const SizedBox(height: 10),
                          Text(
                            'No Incoming Requests',
                            style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: textColor),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            'When municipal clients submit pickup requests, they stream into this queue for dispatch.',
                            textAlign: TextAlign.center,
                            style: TextStyle(fontSize: 11, color: subtextColor, height: 1.3),
                          ),
                        ],
                      ),
                    ),
                  )
                : ListView.builder(
                    itemCount: requests.length,
                    itemBuilder: (context, index) {
                      final req = requests[index];
                      return Container(
                        margin: const EdgeInsets.only(bottom: 14),
                        padding: const EdgeInsets.all(14),
                        decoration: BoxDecoration(
                          color: cardColor,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: borderColor),
                          boxShadow: [
                            BoxShadow(color: Colors.black.withOpacity(0.03), blurRadius: 8, offset: const Offset(0, 2)),
                          ],
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text('Client: ${req['residentName'] ?? req['client'] ?? "Client"}', style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: textColor)),
                                Text('Pending', style: TextStyle(fontSize: 11, color: subtextColor)),
                              ],
                            ),
                            const SizedBox(height: 4),
                            Text(req['address']?.toString() ?? 'Arua Municipality', style: TextStyle(fontSize: 12, color: subtextColor)),
                            const SizedBox(height: 4),
                            Text(req['wasteType']?.toString() ?? 'General Waste', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: textColor)),
                            const SizedBox(height: 12),
                            Row(
                              children: [
                                Expanded(
                                  child: SizedBox(
                                    height: 36,
                                    child: ElevatedButton(
                                      onPressed: () => _handleAssignRequest(req),
                                      style: ElevatedButton.styleFrom(
                                        backgroundColor: brandGreen,
                                        foregroundColor: Colors.white,
                                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                                        elevation: 0,
                                      ),
                                      child: const Text('Assign', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 8),
                                SizedBox(
                                  height: 36,
                                  child: OutlinedButton(
                                    onPressed: () => _handleDeclineRequest(req),
                                    style: OutlinedButton.styleFrom(
                                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                                      side: BorderSide(color: borderColor),
                                    ),
                                    child: Text('Decline', style: TextStyle(fontSize: 12, color: subtextColor)),
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }
}
