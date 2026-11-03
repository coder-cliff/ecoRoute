import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../models/waste_request.dart';
import '../../providers/auth_provider.dart';
import '../../providers/waste_request_provider.dart';
import '../../services/location_service.dart';
import '../../theme/app_theme.dart';
import '../../widgets/status_badge.dart';
import '../citizen/request_details_screen.dart';

class InteractiveMapScreen extends StatefulWidget {
  final WasteRequest? highlightedRequest;

  const InteractiveMapScreen({super.key, this.highlightedRequest});

  @override
  State<InteractiveMapScreen> createState() => _InteractiveMapScreenState();
}

class _InteractiveMapScreenState extends State<InteractiveMapScreen> {
  late final MapController _mapController;
  String _filter = 'all'; // 'all', 'pending', 'assigned', 'collected'

  @override
  void initState() {
    super.initState();
    _mapController = MapController();
  }

  LatLng get _initialCenter {
    if (widget.highlightedRequest != null) {
      return LatLng(
        widget.highlightedRequest!.latitude,
        widget.highlightedRequest!.longitude,
      );
    }
    return const LatLng(LocationService.defaultLat, LocationService.defaultLon);
  }

  void _showRequestModal(WasteRequest r) {
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
              Row(
                children: [
                  CircleAvatar(
                    backgroundColor: r.category.color.withValues(alpha: 0.15),
                    child: Icon(r.category.icon, color: r.category.color, size: 22),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          '${r.category.title} (${r.quantityBags} bags)',
                          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                        ),
                        Text('Request ${r.id} • ${r.userName}',
                            style: const TextStyle(fontSize: 12, color: AppTheme.textMuted)),
                      ],
                    ),
                  ),
                  StatusBadge(status: r.status),
                ],
              ),
              const SizedBox(height: 12),
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Icon(Icons.location_on_rounded, size: 16, color: Colors.redAccent),
                  const SizedBox(width: 6),
                  Expanded(
                    child: Text(
                      r.address,
                      style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w500),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: AppTheme.cashGoldLight,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.payments_rounded, size: 18, color: AppTheme.cashGold),
                    const SizedBox(width: 8),
                    Text(
                      r.isCashCollected
                          ? 'Cash Paid: \$${(r.actualCashPaid ?? r.estimatedCashAmount).toStringAsFixed(2)}'
                          : 'Due in Cash: \$${r.estimatedCashAmount.toStringAsFixed(2)}',
                      style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 13),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: () async {
                        final uri = Uri.parse(
                          'https://www.google.com/maps/search/?api=1&query=${r.latitude},${r.longitude}',
                        );
                        await launchUrl(uri, mode: LaunchMode.externalApplication);
                      },
                      icon: const Icon(Icons.directions_rounded, size: 16),
                      label: const Text('Google Maps'),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: ElevatedButton.icon(
                      style: ElevatedButton.styleFrom(backgroundColor: AppTheme.primaryGreen),
                      onPressed: () {
                        Navigator.pop(ctx);
                        Navigator.push(
                          context,
                          MaterialPageRoute(builder: (_) => RequestDetailsScreen(request: r)),
                        );
                      },
                      icon: const Icon(Icons.info_outline_rounded, size: 16),
                      label: const Text('View Details'),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final requestProvider = Provider.of<WasteRequestProvider>(context);
    final auth = Provider.of<AuthProvider>(context);

    List<WasteRequest> requests = requestProvider.requests;
    if (_filter == 'pending') {
      requests = requests.where((r) => r.status == RequestStatus.pending).toList();
    } else if (_filter == 'assigned') {
      requests = requests.where((r) => r.status == RequestStatus.assigned).toList();
    } else if (_filter == 'collected') {
      requests = requests.where((r) => r.status == RequestStatus.collected).toList();
    }

    final markers = <Marker>[];

    // Current User / Rider Station Marker
    markers.add(
      Marker(
        point: const LatLng(LocationService.defaultLat, LocationService.defaultLon),
        width: 48,
        height: 48,
        child: Container(
          decoration: BoxDecoration(
            color: const Color(0xFF0D6EFD),
            shape: BoxShape.circle,
            border: Border.all(color: Colors.white, width: 2.5),
            boxShadow: [
              BoxShadow(
                color: Colors.blue.withValues(alpha: 0.3),
                blurRadius: 10,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: const Icon(Icons.two_wheeler_rounded, color: Colors.white, size: 22),
        ),
      ),
    );

    // Waste Pickup Spot Markers
    for (final r in requests) {
      final isHighlighted = widget.highlightedRequest?.id == r.id;

      markers.add(
        Marker(
          point: LatLng(r.latitude, r.longitude),
          width: isHighlighted ? 52 : 44,
          height: isHighlighted ? 52 : 44,
          child: GestureDetector(
            onTap: () => _showRequestModal(r),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              decoration: BoxDecoration(
                color: r.category.color,
                shape: BoxShape.circle,
                border: Border.all(
                  color: isHighlighted ? Colors.yellowAccent : Colors.white,
                  width: isHighlighted ? 3 : 2,
                ),
                boxShadow: [
                  BoxShadow(
                    color: r.category.color.withValues(alpha: 0.35),
                    blurRadius: 8,
                    offset: const Offset(0, 3),
                  ),
                ],
              ),
              child: Center(
                child: Icon(
                  r.status == RequestStatus.collected
                      ? Icons.check_circle_outline
                      : r.category.icon,
                  color: Colors.white,
                  size: isHighlighted ? 26 : 20,
                ),
              ),
            ),
          ),
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Live Waste Map & Routes'),
        actions: [
          IconButton(
            icon: const Icon(Icons.my_location_rounded),
            tooltip: 'Center on Depot / GPS',
            onPressed: () {
              _mapController.move(
                const LatLng(LocationService.defaultLat, LocationService.defaultLon),
                14.5,
              );
            },
          ),
        ],
      ),
      body: Stack(
        children: [
          // OpenStreetMap Tile Engine
          FlutterMap(
            mapController: _mapController,
            options: MapOptions(
              initialCenter: _initialCenter,
              initialZoom: 14.2,
              maxZoom: 18.0,
              minZoom: 10.0,
            ),
            children: [
              TileLayer(
                urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                userAgentPackageName: 'org.ecoroute.app',
              ),
              MarkerLayer(markers: markers),
            ],
          ),

          // Top Floating Filter Chips
          Positioned(
            top: 12,
            left: 12,
            right: 12,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.95),
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.1),
                    blurRadius: 10,
                    offset: const Offset(0, 3),
                  ),
                ],
              ),
              child: SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(
                  children: [
                    _filterButton('all', 'All Spots (${requestProvider.requests.length})'),
                    const SizedBox(width: 6),
                    _filterButton('pending', 'Pending (${requestProvider.pendingCount})'),
                    const SizedBox(width: 6),
                    _filterButton('assigned', 'Assigned (${requestProvider.assignedCount})'),
                    const SizedBox(width: 6),
                    _filterButton('collected', 'Collected (${requestProvider.collectedCount})'),
                  ],
                ),
              ),
            ),
          ),

          // Bottom Info Floating Card
          Positioned(
            bottom: 16,
            left: 16,
            right: 16,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.12),
                    blurRadius: 12,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: AppTheme.accentMint,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: const Icon(Icons.explore_rounded, color: AppTheme.primaryGreen),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          'Viewing as ${auth.currentUser.name}',
                          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                        ),
                        const Text(
                          'Tap any pin on the map to inspect bags, cash & route directions.',
                          style: TextStyle(fontSize: 11, color: AppTheme.textMuted),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _filterButton(String key, String label) {
    final isSelected = _filter == key;
    return ChoiceChip(
      label: Text(
        label,
        style: TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w600,
          color: isSelected ? Colors.white : AppTheme.textDark,
        ),
      ),
      selected: isSelected,
      selectedColor: AppTheme.darkForest,
      backgroundColor: Colors.grey.shade100,
      showCheckmark: false,
      onSelected: (val) {
        if (val) {
          setState(() => _filter = key);
        }
      },
    );
  }
}
