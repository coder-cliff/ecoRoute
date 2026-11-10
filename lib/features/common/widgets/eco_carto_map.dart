import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';

import '../../../core/services/location_service.dart';
import '../../../core/theme/eco_palette.dart';

/// Preset Landmarks in Arua City for municipal routing & landmark discovery
class AruaMapLandmark {
  const AruaMapLandmark({
    required this.name,
    required this.category,
    required this.position,
    required this.description,
  });

  final String name;
  final String category;
  final LatLng position;
  final String description;
}

/// Zero-Cost Interactive OpenStreetMap Engine for EcoRoute
/// Uses OpenStreetMap & CARTO free public tiles without API fees
class EcoCartoMap extends StatefulWidget {
  const EcoCartoMap({
    super.key,
    required this.center,
    this.zoom = 14.2,
    this.height = 220,
    this.routePoints,
    this.markers = const [],
    this.interactive = true,
    this.showControls = true,
    this.showLandmarks = false,
    this.onTap,
    this.onLocationSelected,
  });

  final LatLng center;
  final double zoom;
  final double? height;
  final List<LatLng>? routePoints;
  final List<Marker> markers;
  final bool interactive;
  final bool showControls;
  final bool showLandmarks;
  final VoidCallback? onTap;
  final ValueChanged<LatLng>? onLocationSelected;

  static const LatLng aruaCityCenter = LatLng(3.0303, 30.9073);

  static const List<AruaMapLandmark> aruaLandmarks = [
    AruaMapLandmark(
      name: 'Arua Central Market',
      category: 'Commercial Hub',
      position: LatLng(3.0315, 30.9102),
      description: 'Daily municipal organic collection center.',
    ),
    AruaMapLandmark(
      name: 'River Oli Division',
      category: 'Residential',
      position: LatLng(3.0180, 30.9020),
      description: 'Saturday residential tricycle routes.',
    ),
    AruaMapLandmark(
      name: 'Arua Hill & Golf Course',
      category: 'Commercial/Gov',
      position: LatLng(3.0250, 30.9230),
      description: 'Friday commercial collection corridor.',
    ),
    AruaMapLandmark(
      name: 'Arua Regional Referral Hospital',
      category: 'Priority Health',
      position: LatLng(3.0380, 30.9150),
      description: 'Special medical & hazardous priority corridor.',
    ),
    AruaMapLandmark(
      name: 'Muni University Hub',
      category: 'Education/Institutional',
      position: LatLng(2.9980, 30.9180),
      description: 'Thursday institutional bulk collection.',
    ),
    AruaMapLandmark(
      name: 'Ediofe Cathedral Trading Center',
      category: 'Institutional',
      position: LatLng(3.0290, 30.8850),
      description: 'Tuesday West Division routes.',
    ),
  ];

  @override
  State<EcoCartoMap> createState() => _EcoCartoMapState();
}

class _EcoCartoMapState extends State<EcoCartoMap> {
  late final MapController _mapController;
  late double _currentZoom;
  LatLng? _selectedLocation;
  bool _isLocatingGps = false;

  @override
  void initState() {
    super.initState();
    _mapController = MapController();
    _currentZoom = widget.zoom;
  }

  void _zoomIn() {
    setState(() {
      _currentZoom = (_currentZoom + 1).clamp(10.0, 18.0);
      _mapController.move(_mapController.camera.center, _currentZoom);
    });
  }

  void _zoomOut() {
    setState(() {
      _currentZoom = (_currentZoom - 1).clamp(10.0, 18.0);
      _mapController.move(_mapController.camera.center, _currentZoom);
    });
  }

  void _recenterArua() {
    _mapController.move(widget.center, widget.zoom);
  }

  Future<void> _locateGps() async {
    setState(() => _isLocatingGps = true);
    try {
      const locService = LocationService();
      final res = await locService.getCurrentUserLocation();
      if (res.latitude != null && res.longitude != null) {
        final pos = LatLng(res.latitude!, res.longitude!);
        _mapController.move(pos, 15.5);
        if (widget.onLocationSelected != null) {
          setState(() => _selectedLocation = pos);
          widget.onLocationSelected!(pos);
        }
      } else if (mounted && res.message != null) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(res.message!)),
        );
      }
    } catch (_) {
    } finally {
      if (mounted) setState(() => _isLocatingGps = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    // Assemble combined markers
    final allMarkers = <Marker>[...widget.markers];

    // Selected Pin Drop Marker
    if (_selectedLocation != null) {
      allMarkers.add(
        Marker(
          point: _selectedLocation!,
          width: 48,
          height: 48,
          child: const Column(
            children: [
              Icon(Icons.location_on, color: Colors.redAccent, size: 36),
            ],
          ),
        ),
      );
    }

    // Optional Arua Landmark Badges
    if (widget.showLandmarks) {
      for (final lm in EcoCartoMap.aruaLandmarks) {
        allMarkers.add(
          Marker(
            point: lm.position,
            width: 90,
            height: 38,
            child: GestureDetector(
              onTap: () {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('${lm.name} • ${lm.description}'),
                    duration: const Duration(seconds: 3),
                  ),
                );
              },
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: isDark ? const Color(0xFF1E3224) : Colors.white,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: EcoPalette.primaryForest, width: 1.2),
                  boxShadow: const [
                    BoxShadow(color: Color(0x22000000), blurRadius: 4, offset: Offset(0, 2))
                  ],
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.place, color: EcoPalette.primaryForest, size: 12),
                    const SizedBox(width: 3),
                    Flexible(
                      child: Text(
                        lm.name,
                        style: TextStyle(
                          fontSize: 9,
                          fontWeight: FontWeight.bold,
                          color: isDark ? Colors.white : Colors.black87,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
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

    final mapWidget = Container(
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF19251E) : EcoPalette.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: EcoPalette.cardBorder, width: 1),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(16),
        child: Stack(
          children: [
            FlutterMap(
              mapController: _mapController,
              options: MapOptions(
                initialCenter: widget.center,
                initialZoom: widget.zoom,
                interactionOptions: InteractionOptions(
                  flags: widget.interactive ? InteractiveFlag.all : InteractiveFlag.none,
                ),
                onTap: (tapPosition, point) {
                  if (widget.onLocationSelected != null) {
                    setState(() => _selectedLocation = point);
                    widget.onLocationSelected!(point);
                  }
                  if (widget.onTap != null) widget.onTap!();
                },
              ),
              children: [
                TileLayer(
                  urlTemplate: isDark
                      ? 'https://{s}.basemaps.cartocdn.com/dark_all/{z}/{x}/{y}.png'
                      : 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                  subdomains: isDark ? const ['a', 'b', 'c', 'd'] : const ['a', 'b', 'c'],
                  userAgentPackageName: 'ug.ecoroute.app',
                  tileBuilder: (context, tileWidget, tile) {
                    if (!isDark) {
                      // Harmonize with Rich Sage aesthetic
                      return ColorFiltered(
                        colorFilter: ColorFilter.mode(
                          EcoPalette.surface.withOpacity(0.08),
                          BlendMode.darken,
                        ),
                        child: tileWidget,
                      );
                    }
                    return tileWidget;
                  },
                ),
                if (widget.routePoints != null && widget.routePoints!.isNotEmpty)
                  PolylineLayer(
                    polylines: [
                      Polyline(
                        points: widget.routePoints!,
                        strokeWidth: 4.5,
                        color: EcoPalette.accentTerracotta,
                        strokeCap: StrokeCap.round,
                        strokeJoin: StrokeJoin.round,
                      ),
                    ],
                  ),
                if (allMarkers.isNotEmpty) MarkerLayer(markers: allMarkers),
              ],
            ),

            // Map Attribution Badge (OSM / Zero-Cost)
            Positioned(
              left: 10,
              bottom: 8,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: (isDark ? Colors.black87 : Colors.white70),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: const Text(
                  '© OpenStreetMap contributors',
                  style: TextStyle(fontSize: 8.5, color: Colors.grey),
                ),
              ),
            ),

            // Floating Controls Bar
            if (widget.showControls && widget.interactive)
              Positioned(
                right: 10,
                bottom: 12,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    _mapButton(
                      icon: Icons.add,
                      tooltip: 'Zoom In',
                      onPressed: _zoomIn,
                      isDark: isDark,
                    ),
                    const SizedBox(height: 6),
                    _mapButton(
                      icon: Icons.remove,
                      tooltip: 'Zoom Out',
                      onPressed: _zoomOut,
                      isDark: isDark,
                    ),
                    const SizedBox(height: 6),
                    _mapButton(
                      icon: Icons.my_location,
                      tooltip: 'Locate My GPS',
                      isLoading: _isLocatingGps,
                      onPressed: _locateGps,
                      isDark: isDark,
                    ),
                    const SizedBox(height: 6),
                    _mapButton(
                      icon: Icons.center_focus_strong,
                      tooltip: 'Recenter Arua',
                      onPressed: _recenterArua,
                      isDark: isDark,
                    ),
                  ],
                ),
              ),
          ],
        ),
      ),
    );

    if (widget.height == null) {
      return mapWidget;
    }

    return SizedBox(
      height: widget.height,
      child: mapWidget,
    );
  }

  Widget _mapButton({
    required IconData icon,
    required String tooltip,
    required VoidCallback onPressed,
    required bool isDark,
    bool isLoading = false,
  }) {
    return Material(
      color: isDark ? const Color(0xFF24362A) : Colors.white,
      elevation: 2,
      shape: const CircleBorder(),
      child: InkWell(
        onTap: isLoading ? null : onPressed,
        customBorder: const CircleBorder(),
        child: Padding(
          padding: const EdgeInsets.all(7.0),
          child: isLoading
              ? const SizedBox(
                  width: 16,
                  height: 16,
                  child: CircularProgressIndicator(strokeWidth: 2, color: EcoPalette.primaryForest),
                )
              : Icon(icon, size: 18, color: EcoPalette.primaryForest),
        ),
      ),
    );
  }
}
