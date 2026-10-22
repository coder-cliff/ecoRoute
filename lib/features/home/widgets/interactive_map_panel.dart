import 'package:flutter/material.dart';

import '../../../core/services/location_service.dart';
import '../../../domain/enums/zone.dart';

class AruaLandmark {
  const AruaLandmark({
    required this.name,
    required this.zone,
    required this.offsetFactor,
    required this.description,
  });

  final String name;
  final Zone zone;
  final Offset offsetFactor; // (0.0 to 1.0) on the map canvas
  final String description;
}

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

  static const List<AruaLandmark> landmarks = [
    AruaLandmark(
      name: 'Arua Central Market',
      zone: Zone.north,
      offsetFactor: Offset(0.50, 0.46),
      description: 'Central commercial hub; daily waste collection schedule.',
    ),
    AruaLandmark(
      name: 'River Oli & Market',
      zone: Zone.west,
      offsetFactor: Offset(0.24, 0.62),
      description: 'Oli Division residential pickups on Saturdays.',
    ),
    AruaLandmark(
      name: 'Arua Hill & Golf Course',
      zone: Zone.east,
      offsetFactor: Offset(0.76, 0.38),
      description: 'Hill Division commercial collection on Fridays.',
    ),
    AruaLandmark(
      name: 'Arua Referral Hospital',
      zone: Zone.north,
      offsetFactor: Offset(0.48, 0.18),
      description: 'Special medical & general waste priority route.',
    ),
    AruaLandmark(
      name: 'Muni University Area',
      zone: Zone.south,
      offsetFactor: Offset(0.72, 0.82),
      description: 'Southern student residences collection on Thursdays.',
    ),
  ];

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 330,
      clipBehavior: Clip.antiAlias,
      decoration: BoxDecoration(
        color: const Color(0xFFE7F0E6),
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: const Color(0xFFD2E1D1)),
      ),
      child: Stack(
        children: [
          // Interactive zoomable painter
          GestureDetector(
            onDoubleTap: () => setState(() {
              _zoomScale = _zoomScale == 1.0 ? 1.35 : 1.0;
            }),
            child: AnimatedScale(
              scale: _zoomScale,
              duration: const Duration(milliseconds: 250),
              child: CustomPaint(
                size: Size.infinite,
                painter: _AruaDetailedMapPainter(),
              ),
            ),
          ),

          // Map Header
          Positioned(
            left: 18,
            top: 16,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text(
                      widget.locationResult != null && widget.locationResult!.resolvedZone != null
                          ? 'Arua Map (${widget.locationResult!.resolvedZone!.label} Zone)'
                          : 'Arua service map',
                      style: const TextStyle(
                        fontWeight: FontWeight.w800,
                        color: Color(0xFF21452A),
                        fontSize: 15,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 2),
                const Text(
                  'Tap landmarks to view zone details',
                  style: TextStyle(fontSize: 11, color: Color(0xFF647568)),
                ),
              ],
            ),
          ),

          // Request count badge
          Positioned(
            left: 16,
            top: 66,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.92),
                borderRadius: BorderRadius.circular(12),
                boxShadow: const [BoxShadow(color: Color(0x10000000), blurRadius: 4)],
              ),
              child: Text(
                '${widget.requestsCount} ${widget.requestsCount == 1 ? 'request' : 'requests'} on local board',
                style: const TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                  color: Color(0xFF45604A),
                ),
              ),
            ),
          ),

          // Zoom & Reset controls
          Positioned(
            right: 14,
            top: 14,
            child: Column(
              children: [
                _mapBtn(
                  icon: widget.isLocating ? Icons.hourglass_top : Icons.my_location_rounded,
                  tooltip: 'Detect Zone via GPS',
                  onTap: widget.isLocating ? null : widget.onLocateGps,
                ),
                const SizedBox(height: 8),
                _mapBtn(
                  icon: Icons.zoom_in_rounded,
                  tooltip: 'Zoom In',
                  onTap: () => setState(() => _zoomScale = (_zoomScale + 0.2).clamp(1.0, 1.8)),
                ),
                const SizedBox(height: 8),
                _mapBtn(
                  icon: Icons.zoom_out_rounded,
                  tooltip: 'Zoom Out',
                  onTap: () => setState(() => _zoomScale = (_zoomScale - 0.2).clamp(1.0, 1.8)),
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
                              ? const Color(0xFF1B5E20)
                              : const Color(0xFF2E8B57),
                          shape: BoxShape.circle,
                          border: Border.all(color: Colors.white, width: 2.5),
                          boxShadow: const [BoxShadow(color: Color(0x33000000), blurRadius: 4)],
                        ),
                        child: const Icon(Icons.location_on, size: 15, color: Colors.white),
                      ),
                    ),
                  );
                }).toList(),
              );
            },
          ),

          // Landmark Info Popover
          if (_selectedLandmark != null)
            Positioned(
              left: 16,
              right: 16,
              bottom: 60,
              child: Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(14),
                  boxShadow: const [BoxShadow(color: Color(0x22000000), blurRadius: 10)],
                ),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: const Color(0xFFE8F5E9),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        _selectedLandmark!.zone.label,
                        style: const TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.w800,
                          color: Color(0xFF2E7D32),
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            _selectedLandmark!.name,
                            style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 12),
                          ),
                          Text(
                            _selectedLandmark!.description,
                            style: const TextStyle(fontSize: 10, color: Color(0xFF556958)),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
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
              ),
            ),

          // Standard bottom bar required by tests
          Positioned(
            left: 16,
            right: 16,
            bottom: 12,
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
                  Expanded(
                    child: FittedBox(
                      fit: BoxFit.scaleDown,
                      alignment: Alignment.centerLeft,
                      child: const Text(
                        'Arua service radius: 12 km',
                        style: TextStyle(fontWeight: FontWeight.w700),
                        maxLines: 1,
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  const Icon(Icons.chevron_right, color: Color(0xFF718273)),
                ],
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
        icon: Icon(icon, size: 18, color: const Color(0xFF2E7D32)),
        tooltip: tooltip,
        onPressed: onTap,
      ),
    );
  }
}

class _AruaDetailedMapPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    // Background Zone Quadrants (subtle tinting)
    final northZone = Paint()..color = const Color(0x152E7D32);
    final southZone = Paint()..color = const Color(0x15F57C00);
    final eastZone = Paint()..color = const Color(0x151976D2);
    final westZone = Paint()..color = const Color(0x157B1FA2);

    final midX = size.width * 0.5;
    final midY = size.height * 0.5;

    canvas.drawRect(Rect.fromLTWH(0, 0, midX, midY), westZone);
    canvas.drawRect(Rect.fromLTWH(midX, 0, size.width - midX, midY), northZone);
    canvas.drawRect(Rect.fromLTWH(0, midY, midX, size.height - midY), southZone);
    canvas.drawRect(Rect.fromLTWH(midX, midY, size.width - midX, size.height - midY), eastZone);

    // Roads & River
    final road = Paint()
      ..color = const Color(0xFFD2E1D0)
      ..strokeWidth = 16
      ..style = PaintingStyle.stroke;
    final smallRoad = Paint()
      ..color = const Color(0xFFDCE8DA)
      ..strokeWidth = 8
      ..style = PaintingStyle.stroke;
    final river = Paint()
      ..color = const Color(0xFFB9DDE2)
      ..strokeWidth = 22
      ..style = PaintingStyle.stroke;

    final mainRoad = Path()
      ..moveTo(-20, size.height * .72)
      ..quadraticBezierTo(size.width * .35, size.height * .52, size.width + 20, size.height * .62);
    final crossRoad = Path()
      ..moveTo(size.width * .22, -10)
      ..quadraticBezierTo(size.width * .5, size.height * .42, size.width * .72, size.height + 10);
    final sideRoad = Path()
      ..moveTo(-10, size.height * .22)
      ..quadraticBezierTo(size.width * .45, size.height * .1, size.width + 10, size.height * .28);

    canvas.drawPath(mainRoad, road);
    canvas.drawPath(crossRoad, road);
    canvas.drawPath(sideRoad, smallRoad);

    final waterPath = Path()
      ..moveTo(size.width * .84, -10)
      ..quadraticBezierTo(size.width * .65, size.height * .32, size.width * .92, size.height + 10);
    canvas.drawPath(waterPath, river);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
