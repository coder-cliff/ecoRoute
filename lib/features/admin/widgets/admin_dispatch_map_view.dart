import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';

import '../../../core/layout/adaptive_layout.dart';
import '../../../core/theme/eco_palette.dart';
import '../../../main.dart';

/// Screen 2: Live Dispatch Map & Incoming Commercial Requests Board (Image 2)
class AdminDispatchMapView extends StatefulWidget {
  const AdminDispatchMapView({super.key});

  @override
  State<AdminDispatchMapView> createState() => _AdminDispatchMapViewState();
}

class _AdminDispatchMapViewState extends State<AdminDispatchMapView> {
  final MapController _mapController = MapController();
  final TextEditingController _mapSearchController = TextEditingController();

  static const LatLng _aruaCenter = LatLng(3.0303, 30.9073);

  // Arua commercial routing waypoints
  static const List<LatLng> _routeA = [
    LatLng(3.0210, 30.8990),
    LatLng(3.0280, 30.9040),
    LatLng(3.0380, 30.9080),
    LatLng(3.0450, 30.9150),
    LatLng(3.0390, 30.9250),
    LatLng(3.0285, 30.9165),
    LatLng(3.0220, 30.9120),
    LatLng(3.0180, 30.9060),
    LatLng(3.0210, 30.8990),
  ];

  static const List<LatLng> _routeB = [
    LatLng(3.0390, 30.9250),
    LatLng(3.0480, 30.9420),
    LatLng(3.0560, 30.9650),
  ];

  // Incoming queue state
  final List<Map<String, dynamic>> _incomingRequests = [
    {
      'id': 'REQ-881',
      'client': 'Ayiko Gift',
      'timeAgo': '3m ago',
      'address': 'Arua Hill, Block 3',
      'wasteType': 'General Commercial • Large Bin',
      'payment': 'Mobile Money',
      'status': 'Pending',
    },
    {
      'id': 'REQ-882',
      'client': 'Gulu Logistics',
      'timeAgo': '12m ago',
      'address': 'Arua-Gulu Highway',
      'wasteType': 'Commercial Waste • Multi-bins',
      'payment': 'Mobile Money',
      'status': 'Pending',
    },
    {
      'id': 'REQ-883',
      'client': 'West Nile Traders',
      'timeAgo': '25m ago',
      'address': 'Central Market',
      'wasteType': 'General Waste • Heavy Cargo',
      'payment': 'Mobile Money',
      'status': 'Pending',
    },
  ];

  @override
  void dispose() {
    _mapSearchController.dispose();
    super.dispose();
  }

  void _handleAssignRequest(Map<String, dynamic> req) {
    showDialog<void>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Row(
          children: [
            const Icon(Icons.send, color: Color(0xFF1B5E20), size: 20),
            const SizedBox(width: 8),
            Text('Assign ${req['client']}', style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Target: ${req['address']}', style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600)),
            Text('Load: ${req['wasteType']}', style: const TextStyle(fontSize: 12, color: Colors.grey)),
            const SizedBox(height: 14),
            const Text('Select Dispatch Unit:', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            ListTile(
              contentPadding: EdgeInsets.zero,
              leading: const CircleAvatar(backgroundColor: Color(0xFF1B5E20), child: Icon(Icons.two_wheeler, color: Colors.white, size: 18)),
              title: const Text('Okello John (Motorcycle)', style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold)),
              subtitle: const Text('Near Block 3 • 2 mins away', style: TextStyle(fontSize: 11)),
              trailing: const Icon(Icons.arrow_forward_ios, size: 14),
              onTap: () {
                Navigator.pop(ctx);
                setState(() {
                  _incomingRequests.remove(req);
                });
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('Dispatched to Okello John for ${req['client']}'),
                    backgroundColor: const Color(0xFF1B5E20),
                  ),
                );
              },
            ),
            ListTile(
              contentPadding: EdgeInsets.zero,
              leading: const CircleAvatar(backgroundColor: Color(0xFFE65100), child: Icon(Icons.local_shipping, color: Colors.white, size: 18)),
              title: const Text('Kato David (Truck #2)', style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold)),
              subtitle: const Text('Arua Hill • 5 mins away', style: TextStyle(fontSize: 11)),
              trailing: const Icon(Icons.arrow_forward_ios, size: 14),
              onTap: () {
                Navigator.pop(ctx);
                setState(() {
                  _incomingRequests.remove(req);
                });
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('Dispatched to Kato David (Truck #2) for ${req['client']}'),
                    backgroundColor: const Color(0xFF1B5E20),
                  ),
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  void _handleDeclineRequest(Map<String, dynamic> req) {
    setState(() {
      _incomingRequests.remove(req);
    });
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Request for ${req['client']} declined.'),
        backgroundColor: Colors.red[700],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = AntigravityTheme.isDark(context);
    final cardColor = isDark ? const Color(0xFF1E293B) : Colors.white;
    final textColor = AntigravityTheme.textPrimary(context);
    final subtextColor = AntigravityTheme.textSecondary(context);
    final borderColor = isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0);
    const brandGreen = Color(0xFF1B5E20);

    return LayoutBuilder(
      builder: (context, constraints) {
        final isWide = constraints.maxWidth >= 900;
        if (isWide) {
          return Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Main Live Map View (flex 7)
              Expanded(
                flex: 7,
                child: _buildMapSection(isDark, cardColor, borderColor, textColor, brandGreen),
              ),
              // Right Incoming Commercial Requests Queue (flex 3)
              Container(
                width: 360,
                decoration: BoxDecoration(
                  color: cardColor,
                  border: Border(left: BorderSide(color: borderColor)),
                ),
                child: _buildIncomingQueuePanel(cardColor, borderColor, textColor, subtextColor, brandGreen),
              ),
            ],
          );
        }

        // Tablet / Mobile View
        return SingleChildScrollView(
          child: Column(
            children: [
              SizedBox(
                height: 400,
                child: _buildMapSection(isDark, cardColor, borderColor, textColor, brandGreen),
              ),
              _buildIncomingQueuePanel(cardColor, borderColor, textColor, subtextColor, brandGreen),
            ],
          ),
        );
      },
    );
  }

  Widget _buildMapSection(
    bool isDark,
    Color cardColor,
    Color borderColor,
    Color textColor,
    Color brandGreen,
  ) {
    return Stack(
      children: [
        // OpenStreetMap Interactive Layer
        FlutterMap(
          mapController: _mapController,
          options: const MapOptions(
            initialCenter: _aruaCenter,
            initialZoom: 13.8,
            minZoom: 10,
            maxZoom: 18,
          ),
          children: [
            TileLayer(
              urlTemplate: isDark
                  ? 'https://{s}.basemaps.cartocdn.com/dark_all/{z}/{x}/{y}{r}.png'
                  : 'https://{s}.basemaps.cartocdn.com/rastertiles/voyager/{z}/{x}/{y}{r}.png',
              subdomains: const ['a', 'b', 'c', 'd'],
              userAgentPackageName: 'org.ecoroute.app',
            ),
            // Route Polylines
            PolylineLayer(
              polylines: [
                Polyline(
                  points: _routeA,
                  color: brandGreen,
                  strokeWidth: 3.5,
                ),
                Polyline(
                  points: _routeB,
                  color: brandGreen.withOpacity(0.8),
                  strokeWidth: 3.0,
                ),
              ],
            ),
            // Vehicle Markers
            MarkerLayer(
              markers: [
                // Truck #2 at Arua Hill
                Marker(
                  point: const LatLng(3.0280, 30.9040),
                  width: 90,
                  height: 40,
                  child: _buildVehicleMarker('Truck #2', Icons.local_shipping, brandGreen),
                ),
                // Truck #5 on Highway
                Marker(
                  point: const LatLng(3.0480, 30.9420),
                  width: 90,
                  height: 40,
                  child: _buildVehicleMarker('Truck #5', Icons.local_shipping, brandGreen),
                ),
                // Motorcycle rider
                Marker(
                  point: const LatLng(3.0390, 30.9080),
                  width: 80,
                  height: 36,
                  child: _buildVehicleMarker('Unit #4', Icons.two_wheeler, const Color(0xFF2E7D32)),
                ),
                // Client Pickup Pin
                Marker(
                  point: const LatLng(3.0380, 30.9080),
                  width: 32,
                  height: 32,
                  child: Container(
                    decoration: const BoxDecoration(color: Color(0xFF1B5E20), shape: BoxShape.circle),
                    child: const Icon(Icons.delete_outline, color: Colors.white, size: 18),
                  ),
                ),
              ],
            ),
          ],
        ),

        // Floating Top-Left Status Badge (Image 2)
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
                Text('12 Active Riders', style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: textColor)),
                const SizedBox(height: 2),
                Row(
                  children: [
                    Text('Route optimization status: ', style: TextStyle(fontSize: 11, color: isDark ? Colors.white70 : Colors.black54)),
                    const Text('Optimal', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Color(0xFF2E7D32))),
                  ],
                ),
              ],
            ),
          ),
        ),

        // Floating Top-Right Search & Filter Controls (Image 2)
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
                      onPressed: () {
                        _mapController.move(_mapController.camera.center, _mapController.camera.zoom + 1);
                      },
                    ),
                    const Divider(height: 1),
                    IconButton(
                      icon: const Icon(Icons.remove, size: 18),
                      onPressed: () {
                        _mapController.move(_mapController.camera.center, _mapController.camera.zoom - 1);
                      },
                    ),
                  ],
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
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
        boxShadow: [
          BoxShadow(color: Colors.black.withOpacity(0.12), blurRadius: 6, offset: const Offset(0, 2)),
        ],
        border: Border.all(color: color, width: 1.5),
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

  // Right Panel: Incoming Commercial Requests
  Widget _buildIncomingQueuePanel(
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
                  '${_incomingRequests.length} requests',
                  style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Color(0xFF1B5E20)),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Expanded(
            child: _incomingRequests.isEmpty
                ? Center(
                    child: Text('All commercial dispatches assigned.', style: TextStyle(fontSize: 12, color: subtextColor)),
                  )
                : ListView.builder(
                    itemCount: _incomingRequests.length,
                    itemBuilder: (context, index) {
                      final req = _incomingRequests[index];
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
                                Text('Client: ${req['client']}', style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: textColor)),
                                Text(req['timeAgo'] as String, style: TextStyle(fontSize: 11, color: subtextColor)),
                              ],
                            ),
                            const SizedBox(height: 4),
                            Text(req['address'] as String, style: TextStyle(fontSize: 12, color: subtextColor)),
                            const SizedBox(height: 4),
                            Text(req['wasteType'] as String, style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: textColor)),
                            const SizedBox(height: 8),
                            // Payment method badge
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                              decoration: BoxDecoration(
                                color: const Color(0xFFF1F5F9),
                                borderRadius: BorderRadius.circular(6),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  const Icon(Icons.phone_android, size: 12, color: Color(0xFF475569)),
                                  const SizedBox(width: 4),
                                  Text('Payment: ${req['payment']}', style: const TextStyle(fontSize: 10, fontWeight: FontWeight.w500, color: Color(0xFF475569))),
                                ],
                              ),
                            ),
                            const SizedBox(height: 12),
                            // Action Buttons
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
                                if (index == 0) ...[
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
