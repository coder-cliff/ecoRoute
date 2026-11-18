import 'dart:async';
import 'package:flutter/material.dart';

class LiveVehicleMarker {
  const LiveVehicleMarker({
    required this.id,
    required this.label,
    required this.name,
    required this.driver,
    required this.status,
    required this.destination,
    required this.speedKmH,
    required this.batteryPct,
    required this.offsetFactor,
    required this.color,
    required this.routeId,
  });

  final String id;
  final String label; // "T1", "T2", "T3", "EMG"
  final String name; // "UG-0480T"
  final String driver;
  final String status;
  final String destination;
  final int speedKmH;
  final int batteryPct;
  final Offset offsetFactor; // 0.0 to 1.0 normalized
  final Color color;
  final String routeId;

  LiveVehicleMarker copyWith({
    String? id,
    String? label,
    String? name,
    String? driver,
    String? status,
    String? destination,
    int? speedKmH,
    int? batteryPct,
    Offset? offsetFactor,
    Color? color,
    String? routeId,
  }) {
    return LiveVehicleMarker(
      id: id ?? this.id,
      label: label ?? this.label,
      name: name ?? this.name,
      driver: driver ?? this.driver,
      status: status ?? this.status,
      destination: destination ?? this.destination,
      speedKmH: speedKmH ?? this.speedKmH,
      batteryPct: batteryPct ?? this.batteryPct,
      offsetFactor: offsetFactor ?? this.offsetFactor,
      color: color ?? this.color,
      routeId: routeId ?? this.routeId,
    );
  }
}

class LiveDispatchMap extends StatefulWidget {
  const LiveDispatchMap({
    super.key,
    this.height = 300,
    this.compact = false,
    this.onViewActiveDispatches,
    this.onSelectVehicle,
    this.initialSelectedId,
    this.vehicles,
    this.isLiveSimulation = true,
  });

  final double height;
  final bool compact;
  final VoidCallback? onViewActiveDispatches;
  final ValueChanged<LiveVehicleMarker>? onSelectVehicle;
  final String? initialSelectedId;
  final List<LiveVehicleMarker>? vehicles;
  final bool isLiveSimulation;

  @override
  State<LiveDispatchMap> createState() => _LiveDispatchMapState();
}

class _LiveDispatchMapState extends State<LiveDispatchMap> with SingleTickerProviderStateMixin {
  late final AnimationController _pulseController;
  late final Animation<double> _pulseAnimation;
  double _zoomScale = 1.0;
  LiveVehicleMarker? _selectedVehicle;
  late List<LiveVehicleMarker> _currentVehicles;
  Timer? _simTimer;

  static const List<LiveVehicleMarker> vehicles = [
    LiveVehicleMarker(
      id: 'v-1',
      label: 'T1',
      name: 'UG-0480T',
      driver: 'Peter (#R-4809)',
      status: 'En Route to Shop 14',
      destination: 'Shop 14 • Pakwach Road',
      speedKmH: 26,
      batteryPct: 88,
      offsetFactor: Offset(0.32, 0.44),
      color: Color(0xFFD48B38),
      routeId: 'Route 4 (Arua Market)',
    ),
    LiveVehicleMarker(
      id: 'v-2',
      label: 'T2',
      name: 'UG-0912K',
      driver: 'Kassim (#R-3102)',
      status: 'At Arua Market',
      destination: 'Arua Central Market Stall 24',
      speedKmH: 0,
      batteryPct: 76,
      offsetFactor: Offset(0.48, 0.46),
      color: Color(0xFF2C7D6B),
      routeId: 'Route 1 (Vurra)',
    ),
    LiveVehicleMarker(
      id: 'v-3',
      label: 'T3',
      name: 'UG-0480T (Backup)',
      driver: 'Juma (#R-2041)',
      status: 'Resolving Route 4 delay',
      destination: 'Dispatch Target • Pakwach Rd',
      speedKmH: 31,
      batteryPct: 92,
      offsetFactor: Offset(0.58, 0.48),
      color: Color(0xFF386884),
      routeId: 'Route 4 (Arua Market)',
    ),
  ];

  @override
  void initState() {
    super.initState();
    _currentVehicles = List.of(widget.vehicles ?? vehicles);
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    );

    final isTest = WidgetsBinding.instance.runtimeType.toString().contains('Test');
    if (!isTest) {
      _pulseController.repeat(reverse: true);
      if (widget.isLiveSimulation) {
        _simTimer = Timer.periodic(const Duration(milliseconds: 2500), (_) => tickLiveSimulation());
      }
    } else {
      _pulseController.value = 1.0;
    }

    _pulseAnimation = Tween<double>(begin: 0.85, end: 1.25).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );

    if (widget.initialSelectedId != null) {
      _selectedVehicle = _currentVehicles.firstWhere(
        (v) => v.id == widget.initialSelectedId,
        orElse: () => _currentVehicles.first,
      );
    }
  }

  @override
  void didUpdateWidget(LiveDispatchMap oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.vehicles != null && widget.vehicles != oldWidget.vehicles) {
      setState(() {
        _currentVehicles = List.of(widget.vehicles!);
      });
    }
  }

  @override
  void dispose() {
    _simTimer?.cancel();
    _pulseController.dispose();
    super.dispose();
  }

  void tickLiveSimulation() {
    if (!mounted) return;
    setState(() {
      _currentVehicles = _currentVehicles.map((v) {
        double nextDx = v.offsetFactor.dx;
        double nextDy = v.offsetFactor.dy;
        if (v.id == 'v-1') {
          nextDx = (nextDx + 0.008 > 0.42) ? 0.30 : nextDx + 0.004;
          nextDy = (nextDy + 0.005 > 0.48) ? 0.42 : nextDy + 0.002;
        } else if (v.id == 'v-3') {
          nextDx = (nextDx - 0.006 < 0.50) ? 0.62 : nextDx - 0.003;
        } else if (v.id == 'v-emg') {
          nextDx = (nextDx + 0.005 > 0.55) ? 0.40 : nextDx + 0.005;
        }
        final speedJitter = (v.speedKmH > 0) ? (v.speedKmH + (v.speedKmH % 3 == 0 ? 1 : -1)).clamp(18, 45) : 0;
        return v.copyWith(
          offsetFactor: Offset(nextDx, nextDy),
          speedKmH: speedJitter,
        );
      }).toList();
      if (_selectedVehicle != null) {
        _selectedVehicle = _currentVehicles.firstWhere(
          (v) => v.id == _selectedVehicle!.id,
          orElse: () => _currentVehicles.first,
        );
      }
    });
  }

  void _handleVehicleTap(LiveVehicleMarker v) {
    setState(() => _selectedVehicle = v);
    widget.onSelectVehicle?.call(v);
  }

  @override
  Widget build(BuildContext context) {
    const cardBg = Color(0xFFD1DBD2);
    const badgeBg = Color(0xFF22353D);

    return Container(
      decoration: BoxDecoration(
        color: cardBg,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: const Color(0xFFBCC8BD), width: 1.2),
        boxShadow: const [
          BoxShadow(
            color: Color(0x14000000),
            blurRadius: 8,
            offset: Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Map Canvas Section
          SizedBox(
            height: widget.height,
            child: ClipRRect(
              borderRadius: const BorderRadius.vertical(top: Radius.circular(18)),
              child: Stack(
                children: [
                  // Interactive Pan / Zoom Custom Map
                  GestureDetector(
                    onDoubleTap: () => setState(() {
                      _zoomScale = _zoomScale == 1.0 ? 1.35 : 1.0;
                    }),
                    child: AnimatedScale(
                      scale: _zoomScale,
                      duration: const Duration(milliseconds: 200),
                      child: CustomPaint(
                        size: Size.infinite,
                        painter: _AruaCommandMapPainter(),
                      ),
                    ),
                  ),

                  // Top Left: "Active Map View" Pill
                  Positioned(
                    left: 12,
                    top: 12,
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                      decoration: BoxDecoration(
                        color: badgeBg,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: const Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.sensors_rounded, color: Color(0xFF4ADE80), size: 14),
                          SizedBox(width: 5),
                          Text(
                            'Active Map View',
                            style: TextStyle(
                              fontFamily: 'Satoshi',
                              color: Colors.white,
                              fontSize: 11,
                              fontWeight: FontWeight.w700,
                              letterSpacing: 0.2,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),

                  // Top Right: Zoom & Center Controls
                  Positioned(
                    right: 12,
                    top: 12,
                    child: Column(
                      children: [
                        _mapControlBtn(
                          icon: Icons.add,
                          tooltip: 'Zoom in',
                          onTap: () => setState(() => _zoomScale = (_zoomScale + 0.2).clamp(0.8, 2.0)),
                        ),
                        const SizedBox(height: 6),
                        _mapControlBtn(
                          icon: Icons.remove,
                          tooltip: 'Zoom out',
                          onTap: () => setState(() => _zoomScale = (_zoomScale - 0.2).clamp(0.8, 2.0)),
                        ),
                        const SizedBox(height: 6),
                        _mapControlBtn(
                          icon: Icons.my_location_rounded,
                          tooltip: 'Center Arua City',
                          onTap: () => setState(() => _zoomScale = 1.0),
                        ),
                      ],
                    ),
                  ),

                  // Live Vehicle Markers with Animated Pulses
                  LayoutBuilder(
                    builder: (context, constraints) {
                      final w = constraints.maxWidth;
                      final h = constraints.maxHeight;

                      return Stack(
                        children: _currentVehicles.map((v) {
                          final left = w * v.offsetFactor.dx - 16;
                          final top = h * v.offsetFactor.dy - 16;
                          final isSelected = _selectedVehicle?.id == v.id;

                          return Positioned(
                            left: left,
                            top: top,
                            child: GestureDetector(
                              onTap: () => _handleVehicleTap(v),
                              child: AnimatedBuilder(
                                animation: _pulseAnimation,
                                builder: (context, child) {
                                  return Stack(
                                    alignment: Alignment.center,
                                    children: [
                                      // Pulse ring
                                      Transform.scale(
                                        scale: _pulseAnimation.value,
                                        child: Container(
                                          width: 38,
                                          height: 38,
                                          decoration: BoxDecoration(
                                            shape: BoxShape.circle,
                                            color: v.color.withValues(alpha: 0.28),
                                          ),
                                        ),
                                      ),
                                      // Vehicle Badge Pin
                                      Container(
                                        width: 32,
                                        height: 32,
                                        decoration: BoxDecoration(
                                          color: isSelected ? const Color(0xFF13222B) : v.color,
                                          shape: BoxShape.circle,
                                          border: Border.all(
                                            color: isSelected ? const Color(0xFF4ADE80) : Colors.white,
                                            width: 2.5,
                                          ),
                                          boxShadow: const [
                                            BoxShadow(
                                              color: Color(0x33000000),
                                              blurRadius: 4,
                                              offset: Offset(0, 2),
                                            ),
                                          ],
                                        ),
                                        child: Center(
                                          child: Text(
                                            v.label,
                                            style: const TextStyle(
                                              fontFamily: 'Satoshi',
                                              color: Colors.white,
                                              fontSize: 11,
                                              fontWeight: FontWeight.w800,
                                            ),
                                          ),
                                        ),
                                      ),
                                    ],
                                  );
                                },
                              ),
                            ),
                          );
                        }).toList(),
                      );
                    },
                  ),

                  // Selected Vehicle Popover Callout
                  if (_selectedVehicle != null)
                    Positioned(
                      left: 12,
                      right: 12,
                      bottom: 10,
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                        decoration: BoxDecoration(
                          color: const Color(0xFF18262E).withValues(alpha: 0.95),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: const Color(0xFF384D59)),
                          boxShadow: const [
                            BoxShadow(color: Color(0x33000000), blurRadius: 8),
                          ],
                        ),
                        child: Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                              decoration: BoxDecoration(
                                color: _selectedVehicle!.color,
                                borderRadius: BorderRadius.circular(6),
                              ),
                              child: Text(
                                _selectedVehicle!.label,
                                style: const TextStyle(
                                  fontFamily: 'Satoshi',
                                  color: Colors.white,
                                  fontWeight: FontWeight.w800,
                                  fontSize: 12,
                                ),
                              ),
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Text(
                                    '${_selectedVehicle!.name} • ${_selectedVehicle!.driver}',
                                    style: const TextStyle(
                                      fontFamily: 'Satoshi',
                                      color: Colors.white,
                                      fontWeight: FontWeight.w700,
                                      fontSize: 12.5,
                                    ),
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                  Text(
                                    '${_selectedVehicle!.status} (${_selectedVehicle!.speedKmH} km/h • ${_selectedVehicle!.batteryPct}% battery)',
                                    style: const TextStyle(
                                      fontFamily: 'Satoshi',
                                      color: Color(0xFF9FB2BC),
                                      fontSize: 11,
                                    ),
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ],
                              ),
                            ),
                            IconButton(
                              icon: const Icon(Icons.close_rounded, size: 16, color: Colors.white70),
                              padding: EdgeInsets.zero,
                              constraints: const BoxConstraints(),
                              onPressed: () => setState(() => _selectedVehicle = null),
                            ),
                          ],
                        ),
                      ),
                    ),
                ],
              ),
            ),
          ),

          // Telemetry Summary & Action Footer
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
            decoration: const BoxDecoration(
              color: Color(0xFFD9E2DA),
              borderRadius: BorderRadius.vertical(bottom: Radius.circular(18)),
            ),
            child: LayoutBuilder(
              builder: (context, mapConstraints) {
                final isNarrow = mapConstraints.maxWidth < 360;
                final telemetryInfo = Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: const [
                    Text(
                      'T1: En Route to Shop 14',
                      style: TextStyle(
                        fontFamily: 'Satoshi',
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                        color: Color(0xFF1B2A32),
                      ),
                    ),
                    SizedBox(height: 2),
                    Text(
                      'T2: At Arua Market',
                      style: TextStyle(
                        fontFamily: 'Satoshi',
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                        color: Color(0xFF1B2A32),
                      ),
                    ),
                    SizedBox(height: 2),
                    Text(
                      'T3: Resolving Route 4 delay',
                      style: TextStyle(
                        fontFamily: 'Satoshi',
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                        color: Color(0xFF1B2A32),
                      ),
                    ),
                  ],
                );

                final dispatchButton = FilledButton(
                  key: const ValueKey('view_active_dispatches_button'),
                  onPressed: widget.onViewActiveDispatches,
                  style: FilledButton.styleFrom(
                    backgroundColor: const Color(0xFF2C5659),
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                  child: const FittedBox(
                    fit: BoxFit.scaleDown,
                    child: Text(
                      'View Active Dispatches',
                      style: TextStyle(
                        fontFamily: 'Satoshi',
                        fontSize: 12.5,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                );

                if (isNarrow) {
                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      telemetryInfo,
                      const SizedBox(height: 8),
                      dispatchButton,
                    ],
                  );
                }

                return Row(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    Expanded(child: telemetryInfo),
                    const SizedBox(width: 8),
                    dispatchButton,
                  ],
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _mapControlBtn({
    required IconData icon,
    required String tooltip,
    required VoidCallback onTap,
  }) {
    return Container(
      width: 28,
      height: 28,
      decoration: BoxDecoration(
        color: const Color(0xFF1E2D34).withValues(alpha: 0.9),
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: const Color(0xFF384D59), width: 0.8),
      ),
      child: IconButton(
        icon: Icon(icon, size: 16, color: Colors.white),
        padding: EdgeInsets.zero,
        tooltip: tooltip,
        onPressed: onTap,
      ),
    );
  }
}

class _AruaCommandMapPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;

    // Background Canvas matching mockup image
    final bgPaint = Paint()..color = const Color(0xFFCED7CE);
    canvas.drawRect(Rect.fromLTWH(0, 0, w, h), bgPaint);

    // Dark Road Network Lines
    final roadPaint = Paint()
      ..color = const Color(0xFF20323B)
      ..strokeWidth = 3.2
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;

    final secondaryRoadPaint = Paint()
      ..color = const Color(0xFF2E434E)
      ..strokeWidth = 2.0
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;

    // Road paths (Pakwach Rd, Vurra route, Oligo Rd, Arua Hill bypass)
    final mainRoad = Path()
      ..moveTo(w * 0.10, h * 0.85) // Vurra
      ..lineTo(w * 0.32, h * 0.44) // T1 junction
      ..lineTo(w * 0.48, h * 0.46) // Arua Market (T2)
      ..lineTo(w * 0.70, h * 0.40) // Arua Hill
      ..lineTo(w * 0.88, h * 0.65); // Oligo Road

    canvas.drawPath(mainRoad, roadPaint);

    final crossRoad1 = Path()
      ..moveTo(w * 0.35, h * 0.10)
      ..lineTo(w * 0.48, h * 0.46)
      ..lineTo(w * 0.58, h * 0.88); // Pakwach road continuation

    canvas.drawPath(crossRoad1, secondaryRoadPaint);

    final bypass = Path()
      ..moveTo(w * 0.20, h * 0.30)
      ..lineTo(w * 0.32, h * 0.44)
      ..lineTo(w * 0.40, h * 0.65)
      ..lineTo(w * 0.58, h * 0.75);

    canvas.drawPath(bypass, secondaryRoadPaint);

    // Active Route Polyline (Gold Route Line matching image)
    final routePaint = Paint()
      ..color = const Color(0xFFE29B44)
      ..strokeWidth = 3.6
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;

    final activeRoutePath = Path()
      ..moveTo(w * 0.22, h * 0.72)
      ..lineTo(w * 0.32, h * 0.44) // T1
      ..lineTo(w * 0.48, h * 0.46) // T2
      ..lineTo(w * 0.58, h * 0.48) // T3
      ..lineTo(w * 0.74, h * 0.38); // Arua Hill

    canvas.drawPath(activeRoutePath, routePaint);

    // Dispatch Target Circle Indicator
    final targetPaint = Paint()
      ..color = const Color(0xFF386884)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.0;
    canvas.drawCircle(Offset(w * 0.56, h * 0.76), 8, targetPaint);
    final targetCenter = Paint()..color = const Color(0xFF386884);
    canvas.drawCircle(Offset(w * 0.56, h * 0.76), 3.5, targetCenter);

    // Regional Map Labels matching Mockup
    _drawText(canvas, 'Arua Market', Offset(w * 0.40, h * 0.34), isBold: true);
    _drawText(canvas, 'Arua Hill', Offset(w * 0.66, h * 0.30), isBold: true);
    _drawText(canvas, 'Vurra', Offset(w * 0.15, h * 0.88));
    _drawText(canvas, 'Dispatch Target', Offset(w * 0.48, h * 0.82), isTarget: true);
    _drawText(canvas, 'Oligo Road', Offset(w * 0.74, h * 0.66));
  }

  void _drawText(Canvas canvas, String text, Offset offset, {bool isBold = false, bool isTarget = false}) {
    final textSpan = TextSpan(
      text: text,
      style: TextStyle(
        fontFamily: 'Satoshi',
        color: isTarget ? const Color(0xFF1E3844) : const Color(0xFF1A2A33),
        fontSize: isBold ? 11.5 : 10.0,
        fontWeight: isBold || isTarget ? FontWeight.w800 : FontWeight.w600,
        letterSpacing: 0.1,
      ),
    );
    final textPainter = TextPainter(
      text: textSpan,
      textDirection: TextDirection.ltr,
    )..layout();
    textPainter.paint(canvas, offset);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
