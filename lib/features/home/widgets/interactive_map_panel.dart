import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../core/services/location_service.dart';
import '../../../domain/enums/zone.dart';

class AruaLandmark {
  const AruaLandmark({
    required this.name,
    required this.zone,
    required this.offsetFactor,
    required this.latitude,
    required this.longitude,
    required this.description,
  });

  final String name;
  final Zone zone;
  final Offset offsetFactor; // (0.0 to 1.0) on the map canvas
  final double latitude;
  final double longitude;
  final String description;
}

enum GoogleMapType { roadmap, satellite }

class InteractiveAruaMapPanel extends StatefulWidget {
  const InteractiveAruaMapPanel({
    required this.requestsCount,
    this.locationResult,
    this.onLocateGps,
    this.isLocating = false,
    super.key,
  });

  final int requestsCount;
  final UserLocationResult? locationResult;
  final VoidCallback? onLocateGps;
  final bool isLocating;

  @override
  State<InteractiveAruaMapPanel> createState() => _InteractiveAruaMapPanelState();
}

class _InteractiveAruaMapPanelState extends State<InteractiveAruaMapPanel> {
  double _zoomScale = 1.0;
  AruaLandmark? _selectedLandmark;
  GoogleMapType _mapType = GoogleMapType.roadmap;

  static const List<AruaLandmark> landmarks = [
    AruaLandmark(
      name: 'Arua Central Market',
      zone: Zone.north,
      offsetFactor: Offset(0.50, 0.46),
      latitude: 3.0315,
      longitude: 30.9102,
      description: 'Central commercial hub; daily waste collection schedule.',
    ),
    AruaLandmark(
      name: 'River Oli & Market',
      zone: Zone.west,
      offsetFactor: Offset(0.24, 0.62),
      latitude: 3.0180,
      longitude: 30.9020,
      description: 'Oli Division residential pickups on Saturdays.',
    ),
    AruaLandmark(
      name: 'Arua Hill & Golf Course',
      zone: Zone.east,
      offsetFactor: Offset(0.76, 0.38),
      latitude: 3.0250,
      longitude: 30.9230,
      description: 'Hill Division commercial collection on Fridays.',
    ),
    AruaLandmark(
      name: 'Arua Referral Hospital',
      zone: Zone.north,
      offsetFactor: Offset(0.48, 0.18),
      latitude: 3.0380,
      longitude: 30.9150,
      description: 'Special medical & general waste priority route.',
    ),
    AruaLandmark(
      name: 'Muni University Area',
      zone: Zone.south,
      offsetFactor: Offset(0.72, 0.82),
      latitude: 2.9980,
      longitude: 30.9180,
      description: 'Southern student residences collection on Thursdays.',
    ),
    AruaLandmark(
      name: 'Ediofe Cathedral Hub',
      zone: Zone.west,
      offsetFactor: Offset(0.18, 0.35),
      latitude: 3.0290,
      longitude: 30.8850,
      description: 'West Division institutional collection on Tuesdays.',
    ),
  ];

  Future<void> _launchGoogleMaps({double? lat, double? lng}) async {
    final targetLat = lat ?? widget.locationResult?.latitude ?? 3.0315;
    final targetLng = lng ?? widget.locationResult?.longitude ?? 30.9102;
    final url = Uri.parse(
      LocationService.googleMapsSearchUrl(
        latitude: targetLat,
        longitude: targetLng,
      ),
    );

    try {
      if (await canLaunchUrl(url)) {
        await launchUrl(url, mode: LaunchMode.externalApplication);
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Opening Google Maps coordinates: $targetLat, $targetLng'),
            ),
          );
        }
      }
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Target GPS: $targetLat, $targetLng'),
          ),
        );
      }
    }
  }

  Future<void> _launchNavigation({required double lat, required double lng}) async {
    final url = Uri.parse(
      LocationService.googleMapsDirectionsUrl(latitude: lat, longitude: lng),
    );
    try {
      if (await canLaunchUrl(url)) {
        await launchUrl(url, mode: LaunchMode.externalApplication);
      }
    } catch (_) {}
  }

  @override
  Widget build(BuildContext context) {
    final hasGps = widget.locationResult != null &&
        widget.locationResult!.latitude != null &&
        widget.locationResult!.longitude != null;

    final lat = widget.locationResult?.latitude ?? 3.0315;
    final lng = widget.locationResult?.longitude ?? 30.9102;
    final accuracy = widget.locationResult?.accuracyMeters;

    return Container(
      height: 380,
      clipBehavior: Clip.antiAlias,
      decoration: BoxDecoration(
        color: _mapType == GoogleMapType.roadmap
            ? const Color(0xFFF2F4F7)
            : const Color(0xFF1E2D24),
        borderRadius: BorderRadius.circular(22),
        border: Border.all(
          color: _mapType == GoogleMapType.roadmap
              ? const Color(0xFFD2E1D1)
              : const Color(0xFF374D3E),
        ),
        boxShadow: const [
          BoxShadow(
            color: Color(0x14000000),
            blurRadius: 12,
            offset: Offset(0, 4),
          ),
        ],
      ),
      child: Stack(
        children: [
          // Interactive Map Canvas with Google Maps Styling
          GestureDetector(
            onDoubleTap: () => setState(() {
              _zoomScale = _zoomScale == 1.0 ? 1.35 : 1.0;
            }),
            child: AnimatedScale(
              scale: _zoomScale,
              duration: const Duration(milliseconds: 250),
              child: CustomPaint(
                size: Size.infinite,
                painter: _AruaGoogleMapsPainter(mapType: _mapType),
              ),
            ),
          ),

          // Google Maps Engine Header Badge
          Positioned(
            left: 14,
            top: 14,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.95),
                        borderRadius: BorderRadius.circular(10),
                        boxShadow: const [
                          BoxShadow(color: Color(0x15000000), blurRadius: 4),
                        ],
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(Icons.map_rounded, size: 14, color: Color(0xFF2E7D32)),
                          const SizedBox(width: 5),
                          Text(
                            _mapType == GoogleMapType.roadmap
                                ? 'Google Maps • Streets'
                                : 'Google Maps • Satellite',
                            style: const TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w800,
                              color: Color(0xFF202124),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 6),
                    if (hasGps)
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
                        decoration: BoxDecoration(
                          color: const Color(0xFFE8F5E9),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          accuracy != null
                              ? 'GPS ±${accuracy.toStringAsFixed(1)}m'
                              : 'GPS Locked',
                          style: const TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.w700,
                            color: Color(0xFF2E7D32),
                          ),
                        ),
                      ),
                  ],
                ),
                const SizedBox(height: 4),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.90),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    hasGps
                        ? '${lat.toStringAsFixed(5)}°N, ${lng.toStringAsFixed(5)}°E • Instant Service Active'
                        : 'Arua service radius: 12 km • Instant On-Demand Dispatch',
                    style: const TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.w600,
                      color: Color(0xFF5F6368),
                    ),
                  ),
                ),
              ],
            ),
          ),

          // Map Control Buttons (Map Type Switch, GPS Locate, Zoom, Open Google Maps)
          Positioned(
            right: 12,
            top: 12,
            child: Column(
              children: [
                // Toggle Google Maps Roadmap / Satellite
                _mapBtn(
                  icon: _mapType == GoogleMapType.roadmap
                      ? Icons.satellite_alt_rounded
                      : Icons.map_rounded,
                  tooltip: _mapType == GoogleMapType.roadmap
                      ? 'Switch to Satellite'
                      : 'Switch to Streets',
                  onTap: () => setState(() {
                    _mapType = _mapType == GoogleMapType.roadmap
                        ? GoogleMapType.satellite
                        : GoogleMapType.roadmap;
                  }),
                ),
                const SizedBox(height: 6),

                // Locate Me High-Accuracy GPS
                _mapBtn(
                  icon: widget.isLocating
                      ? Icons.hourglass_top
                      : Icons.my_location_rounded,
                  tooltip: 'Locate Accurately in Real Time',
                  accentColor: const Color(0xFF2E7D32),
                  onTap: widget.isLocating ? null : widget.onLocateGps,
                ),
                const SizedBox(height: 6),

                // Direct Open in Google Maps App
                _mapBtn(
                  icon: Icons.open_in_new_rounded,
                  tooltip: 'Open in Official Google Maps',
                  accentColor: const Color(0xFFEA4335),
                  onTap: () => _launchGoogleMaps(lat: lat, lng: lng),
                ),
                const SizedBox(height: 6),

                // Zoom In
                _mapBtn(
                  icon: Icons.zoom_in_rounded,
                  tooltip: 'Zoom In',
                  onTap: () => setState(
                    () => _zoomScale = (_zoomScale + 0.2).clamp(1.0, 1.8),
                  ),
                ),
                const SizedBox(height: 6),

                // Zoom Out
                _mapBtn(
                  icon: Icons.zoom_out_rounded,
                  tooltip: 'Zoom Out',
                  onTap: () => setState(
                    () => _zoomScale = (_zoomScale - 0.2).clamp(1.0, 1.8),
                  ),
                ),
              ],
            ),
          ),

          // User Location Marker (EcoRoute Green GPS Dot)
          if (hasGps)
            Positioned(
              left: 140,
              top: 180,
              child: Stack(
                alignment: Alignment.center,
                children: [
                  Container(
                    width: 34,
                    height: 34,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: const Color(0xFF2EAD65).withValues(alpha: 0.25),
                    ),
                  ),
                  Container(
                    width: 18,
                    height: 18,
                    decoration: BoxDecoration(
                      color: const Color(0xFF2E7D32),
                      shape: BoxShape.circle,
                      border: Border.all(color: Colors.white, width: 3),
                      boxShadow: const [
                        BoxShadow(
                          color: Color(0x33000000),
                          blurRadius: 4,
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),

          // Interactive Landmark Pins
          LayoutBuilder(
            builder: (context, constraints) {
              return Stack(
                children: landmarks.map((landmark) {
                  final left = constraints.maxWidth * landmark.offsetFactor.dx - 14;
                  final top = constraints.maxHeight * landmark.offsetFactor.dy - 14;

                  return Positioned(
                    left: left,
                    top: top,
                    child: GestureDetector(
                      onTap: () => setState(() => _selectedLandmark = landmark),
                      child: Container(
                        width: 28,
                        height: 28,
                        decoration: BoxDecoration(
                          color: _selectedLandmark == landmark
                              ? const Color(0xFFEA4335) // Google Maps Red pin
                              : const Color(0xFF1B5E20),
                          shape: BoxShape.circle,
                          border: Border.all(color: Colors.white, width: 2.5),
                          boxShadow: const [
                            BoxShadow(color: Color(0x33000000), blurRadius: 4),
                          ],
                        ),
                        child: const Icon(
                          Icons.location_on_rounded,
                          size: 15,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  );
                }).toList(),
              );
            },
          ),

          // Selected Landmark Google Maps Popover
          if (_selectedLandmark != null)
            Positioned(
              left: 14,
              right: 14,
              bottom: 64,
              child: Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: const [
                    BoxShadow(color: Color(0x28000000), blurRadius: 10),
                  ],
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 4,
                          ),
                          decoration: BoxDecoration(
                            color: const Color(0xFFE8F5E9),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: const Text(
                            'Instant Drop-Off Hub',
                            style: TextStyle(
                              fontSize: 10,
                              fontWeight: FontWeight.w800,
                              color: Color(0xFF1B5E20),
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            _selectedLandmark!.name,
                            style: const TextStyle(
                              fontWeight: FontWeight.w800,
                              fontSize: 13,
                            ),
                          ),
                        ),
                        IconButton(
                          icon: const Icon(Icons.close, size: 16),
                          padding: EdgeInsets.zero,
                          constraints: const BoxConstraints(),
                          onPressed: () => setState(() => _selectedLandmark = null),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Align(
                      alignment: Alignment.centerLeft,
                      child: Text(
                        _selectedLandmark!.description,
                        style: const TextStyle(
                          fontSize: 11,
                          color: Color(0xFF556958),
                        ),
                      ),
                    ),
                    const SizedBox(height: 8),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        OutlinedButton.icon(
                          onPressed: () => _launchNavigation(
                            lat: _selectedLandmark!.latitude,
                            lng: _selectedLandmark!.longitude,
                          ),
                          icon: const Icon(
                            Icons.directions_rounded,
                            size: 15,
                            color: Color(0xFF2E7D32),
                          ),
                          label: const Text(
                            'Directions in Google Maps',
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                          style: OutlinedButton.styleFrom(
                            visualDensity: VisualDensity.compact,
                            foregroundColor: const Color(0xFF2E7D32),
                            side: const BorderSide(color: Color(0xFF2E7D32)),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),

          // Standard bottom bar required by tests
          Positioned(
            left: 14,
            right: 14,
            bottom: 12,
            child: InkWell(
              onTap: () => _launchGoogleMaps(lat: lat, lng: lng),
              borderRadius: BorderRadius.circular(14),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(14),
                  boxShadow: const [
                    BoxShadow(color: Color(0x18000000), blurRadius: 10),
                  ],
                ),
                child: Row(
                  children: [
                    const Icon(
                      Icons.location_on_outlined,
                      color: Color(0xFF2E7D32),
                    ),
                    const SizedBox(width: 8),
                    const Expanded(
                      child: FittedBox(
                        fit: BoxFit.scaleDown,
                        alignment: Alignment.centerLeft,
                        child: Text(
                          'Arua service radius: 12 km',
                          style: TextStyle(fontWeight: FontWeight.w700),
                          maxLines: 1,
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 3,
                      ),
                      decoration: BoxDecoration(
                        color: const Color(0xFFE8F5E9),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: const Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            Icons.map_rounded,
                            size: 13,
                            color: Color(0xFF2E7D32),
                          ),
                          SizedBox(width: 4),
                          Text(
                            'Google Maps',
                            style: TextStyle(
                              fontSize: 10,
                              fontWeight: FontWeight.w700,
                              color: Color(0xFF1B5E20),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _mapBtn({
    required IconData icon,
    required String tooltip,
    Color? accentColor,
    VoidCallback? onTap,
  }) {
    return Container(
      width: 34,
      height: 34,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(10),
        boxShadow: const [BoxShadow(color: Color(0x18000000), blurRadius: 6)],
      ),
      child: IconButton(
        padding: EdgeInsets.zero,
        icon: Icon(icon, size: 18, color: accentColor ?? const Color(0xFF2E7D32)),
        tooltip: tooltip,
        onPressed: onTap,
      ),
    );
  }
}

class _AruaGoogleMapsPainter extends CustomPainter {
  const _AruaGoogleMapsPainter({required this.mapType});

  final GoogleMapType mapType;

  @override
  void paint(Canvas canvas, Size size) {
    final isSatellite = mapType == GoogleMapType.satellite;

    // Background Canvas
    final bgPaint = Paint()
      ..color = isSatellite ? const Color(0xFF1C2C20) : const Color(0xFFF2F4F7);
    canvas.drawRect(Rect.fromLTWH(0, 0, size.width, size.height), bgPaint);

    // Green Vegetation / Parks (Google Maps Style)
    final parkPaint = Paint()
      ..color = isSatellite ? const Color(0xFF16251A) : const Color(0xFFD4EBD8);

    final golfCourse = Rect.fromLTWH(
      size.width * 0.65,
      size.height * 0.28,
      size.width * 0.28,
      size.height * 0.22,
    );
    canvas.drawRRect(RRect.fromRectAndRadius(golfCourse, const Radius.circular(16)), parkPaint);

    final muniGreen = Rect.fromLTWH(
      size.width * 0.50,
      size.height * 0.70,
      size.width * 0.42,
      size.height * 0.25,
    );
    canvas.drawRRect(RRect.fromRectAndRadius(muniGreen, const Radius.circular(16)), parkPaint);

    // 12 km Municipal Perimeter Circle
    final perimeterPaint = Paint()
      ..color = isSatellite
          ? const Color(0x40FFFFFF)
          : const Color(0x402E7D32)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.0;

    final center = Offset(size.width * 0.5, size.height * 0.5);
    final radius = math.min(size.width, size.height) * 0.44;
    canvas.drawCircle(center, radius, perimeterPaint);

    // Subtle Cardinal Division Lines
    final dashPaint = Paint()
      ..color = isSatellite ? const Color(0x25FFFFFF) : const Color(0x202E7D32)
      ..strokeWidth = 1.0;
    canvas.drawLine(Offset(size.width * 0.5, 0), Offset(size.width * 0.5, size.height), dashPaint);
    canvas.drawLine(Offset(0, size.height * 0.5), Offset(size.width, size.height * 0.5), dashPaint);

    // River Oli (Waterway Green)
    final riverPaint = Paint()
      ..color = isSatellite ? const Color(0xFF143020) : const Color(0xFFC8E6C9)
      ..strokeWidth = 18
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;

    final waterPath = Path()
      ..moveTo(size.width * 0.88, -10)
      ..quadraticBezierTo(
        size.width * 0.68,
        size.height * 0.32,
        size.width * 0.94,
        size.height + 10,
      );
    canvas.drawPath(waterPath, riverPaint);

    // Road Network Layers:
    // Highway Outer Casing
    final highwayBorder = Paint()
      ..color = isSatellite ? const Color(0x60000000) : const Color(0xFFF1C775)
      ..strokeWidth = 14
      ..style = PaintingStyle.stroke;

    // Highway Fill (Google Maps Yellow)
    final highwayFill = Paint()
      ..color = isSatellite ? const Color(0xFFE0E0E0) : const Color(0xFFFFE082)
      ..strokeWidth = 10
      ..style = PaintingStyle.stroke;

    // Local Streets (Google White)
    final localStreet = Paint()
      ..color = isSatellite ? const Color(0x60FFFFFF) : const Color(0xFFFFFFFF)
      ..strokeWidth = 6
      ..style = PaintingStyle.stroke;

    final localStreetBorder = Paint()
      ..color = isSatellite ? const Color(0x30000000) : const Color(0xFFD0D7DE)
      ..strokeWidth = 8
      ..style = PaintingStyle.stroke;

    // Main Arterials
    final mainArterial = Path()
      ..moveTo(-20, size.height * 0.68)
      ..quadraticBezierTo(
        size.width * 0.35,
        size.height * 0.50,
        size.width + 20,
        size.height * 0.60,
      );

    final crossArterial = Path()
      ..moveTo(size.width * 0.25, -10)
      ..quadraticBezierTo(
        size.width * 0.50,
        size.height * 0.42,
        size.width * 0.72,
        size.height + 10,
      );

    final ediofeRoad = Path()
      ..moveTo(-10, size.height * 0.30)
      ..quadraticBezierTo(
        size.width * 0.45,
        size.height * 0.20,
        size.width + 10,
        size.height * 0.32,
      );

    // Draw borders then fills
    canvas.drawPath(mainArterial, highwayBorder);
    canvas.drawPath(crossArterial, highwayBorder);
    canvas.drawPath(mainArterial, highwayFill);
    canvas.drawPath(crossArterial, highwayFill);

    canvas.drawPath(ediofeRoad, localStreetBorder);
    canvas.drawPath(ediofeRoad, localStreet);
  }

  @override
  bool shouldRepaint(covariant _AruaGoogleMapsPainter oldDelegate) =>
      oldDelegate.mapType != mapType;
}
