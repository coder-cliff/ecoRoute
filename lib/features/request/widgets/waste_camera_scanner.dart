import 'dart:async';
import 'package:flutter/material.dart';

import '../../../core/services/location_service.dart';

class WastePhotoCaptureResult {
  const WastePhotoCaptureResult({
    required this.imageLabel,
    required this.capturedAt,
    required this.locationResult,
    required this.isAutoCaptured,
  });

  final String imageLabel;
  final DateTime capturedAt;
  final UserLocationResult locationResult;
  final bool isAutoCaptured;
}

class WasteCameraScanner extends StatefulWidget {
  const WasteCameraScanner({
    required this.onCaptured,
    this.locationService = const LocationService(),
    super.key,
  });

  final void Function(WastePhotoCaptureResult result) onCaptured;
  final LocationService locationService;

  @override
  State<WasteCameraScanner> createState() => _WasteCameraScannerState();
}

class _WasteCameraScannerState extends State<WasteCameraScanner>
    with SingleTickerProviderStateMixin {
  bool _isAutoMode = true;
  double _proximityScore = 0.35; // 0.0 to 1.0 (1.0 = close enough)
  bool _captured = false;
  bool _locatingGps = false;
  UserLocationResult? _locationResult;

  Timer? _proximityTimer;
  late final AnimationController _pulseController;

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1400),
    )..repeat(reverse: true);

    _startProximitySimulation();
  }

  @override
  void dispose() {
    _proximityTimer?.cancel();
    _pulseController.dispose();
    super.dispose();
  }

  void _startProximitySimulation() {
    if (!_isAutoMode || _captured) return;
    _proximityTimer?.cancel();
    _proximityTimer = Timer.periodic(const Duration(milliseconds: 700), (timer) {
      if (!mounted || _captured) {
        timer.cancel();
        return;
      }

      setState(() {
        _proximityScore = (_proximityScore + 0.22).clamp(0.0, 1.0);
      });

      if (_proximityScore >= 0.95) {
        timer.cancel();
        _triggerCapture(auto: true);
      }
    });
  }

  Future<void> _triggerCapture({required bool auto}) async {
    if (_captured) return;
    _proximityTimer?.cancel();

    setState(() {
      _captured = true;
      _locatingGps = true;
    });

    // Capture GPS automatically as requested
    final loc = await widget.locationService.getCurrentUserLocation();

    if (!mounted) return;
    setState(() {
      _locatingGps = false;
      _locationResult = loc;
    });
  }

  void _confirm() {
    final result = WastePhotoCaptureResult(
      imageLabel: 'waste_evidence_${DateTime.now().millisecondsSinceEpoch}.jpg',
      capturedAt: DateTime.now(),
      locationResult: _locationResult ??
          const UserLocationResult(
            status: LocationServiceStatus.success,
            latitude: 3.0512,
            longitude: 30.9114,
            isWithinServiceArea: true,
          ),
      isAutoCaptured: _isAutoMode,
    );
    widget.onCaptured(result);
    Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    return Dialog.fullscreen(
      child: Scaffold(
        backgroundColor: Colors.black,
        appBar: AppBar(
          backgroundColor: Colors.black,
          iconTheme: const IconThemeData(color: Colors.white),
          title: const Text(
            'Rubbish Photo Capture',
            style: TextStyle(color: Colors.white, fontSize: 18),
          ),
          actions: [
            // Auto vs Manual toggle
            if (!_captured)
              SegmentedButton<bool>(
                segments: const [
                  ButtonSegment(value: true, label: Text('Auto', style: TextStyle(fontSize: 12))),
                  ButtonSegment(value: false, label: Text('Manual', style: TextStyle(fontSize: 12))),
                ],
                selected: {_isAutoMode},
                onSelectionChanged: (set) {
                  setState(() {
                    _isAutoMode = set.first;
                    _proximityScore = 0.35;
                  });
                  if (_isAutoMode) {
                    _startProximitySimulation();
                  } else {
                    _proximityTimer?.cancel();
                  }
                },
                style: const ButtonStyle(
                  visualDensity: VisualDensity.compact,
                ),
              ),
            const SizedBox(width: 10),
          ],
        ),
        body: Column(
          children: [
            // Viewfinder frame
            Expanded(
              child: Stack(
                alignment: Alignment.center,
                children: [
                  // Camera simulated feed
                  Container(
                    margin: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: const Color(0xFF1E2820),
                      borderRadius: BorderRadius.circular(24),
                      border: Border.all(
                        color: _captured
                            ? const Color(0xFF2EAD65)
                            : _proximityScore > 0.8
                                ? const Color(0xFF66BB6A)
                                : const Color(0xFFFFA726),
                        width: 3,
                      ),
                    ),
                    child: Stack(
                      children: [
                        Center(
                          child: Icon(
                            Icons.delete_sweep_rounded,
                            size: 130,
                            color: Colors.white.withValues(alpha: 0.16),
                          ),
                        ),
                        // Corner view finder brackets
                        Positioned.fill(
                          child: CustomPaint(
                            painter: _ViewfinderCornersPainter(
                              color: _proximityScore > 0.8
                                  ? const Color(0xFF4CAF50)
                                  : Colors.white70,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),

                  // Prompt Banner: "Move closer to the rubbish..."
                  if (!_captured)
                    Positioned(
                      top: 36,
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                        decoration: BoxDecoration(
                          color: Colors.black.withValues(alpha: 0.75),
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(color: const Color(0xFF4CAF50)),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              _proximityScore < 0.8
                                  ? Icons.zoom_in_rounded
                                  : Icons.check_circle_rounded,
                              color: _proximityScore < 0.8 ? Colors.amber : Colors.greenAccent,
                              size: 20,
                            ),
                            const SizedBox(width: 8),
                            Text(
                              _proximityScore < 0.8
                                  ? 'Move closer to the rubbish...'
                                  : 'Optimal distance! Hold steady...',
                              style: const TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.w700,
                                fontSize: 13,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),

                  // Proximity Bar
                  if (!_captured)
                    Positioned(
                      bottom: 36,
                      left: 40,
                      right: 40,
                      child: Column(
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              const Text('Far', style: TextStyle(color: Colors.white60, fontSize: 11)),
                              Text(
                                '${(_proximityScore * 100).toInt()}% Proximity',
                                style: const TextStyle(
                                  color: Colors.greenAccent,
                                  fontWeight: FontWeight.w700,
                                  fontSize: 12,
                                ),
                              ),
                              const Text('Close', style: TextStyle(color: Colors.white60, fontSize: 11)),
                            ],
                          ),
                          const SizedBox(height: 6),
                          ClipRRect(
                            borderRadius: BorderRadius.circular(10),
                            child: LinearProgressIndicator(
                              value: _proximityScore,
                              backgroundColor: Colors.white24,
                              valueColor: AlwaysStoppedAnimation<Color>(
                                _proximityScore > 0.8 ? Colors.greenAccent : Colors.orangeAccent,
                              ),
                              minHeight: 8,
                            ),
                          ),
                        ],
                      ),
                    ),

                  // Post-capture evidence overlay
                  if (_captured)
                    Container(
                      margin: const EdgeInsets.all(24),
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Colors.black.withValues(alpha: 0.82),
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(color: Colors.greenAccent),
                      ),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(Icons.verified_rounded, color: Colors.greenAccent, size: 48),
                          const SizedBox(height: 10),
                          const Text(
                            'Rubbish Photo Verified',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 18,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            _isAutoMode
                                ? 'Captured automatically via proximity sensor'
                                : 'Captured manually by resident',
                            style: const TextStyle(color: Colors.white70, fontSize: 12),
                          ),
                          const Divider(color: Colors.white24, height: 24),
                          // Automatic GPS Capture display
                          if (_locatingGps) ...[
                            const CircularProgressIndicator(strokeWidth: 2),
                            const SizedBox(height: 8),
                            const Text(
                              'Acquiring GPS location automatically...',
                              style: TextStyle(color: Colors.white70, fontSize: 12),
                            ),
                          ] else ...[
                            Row(
                              children: [
                                const Icon(Icons.my_location_rounded, color: Colors.greenAccent, size: 20),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: Text(
                                    _locationResult?.message ??
                                        'GPS coordinates captured within Arua service perimeter.',
                                    style: const TextStyle(color: Colors.white, fontSize: 12),
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ],
                      ),
                    ),
                ],
              ),
            ),

            // Bottom control bar
            Container(
              padding: const EdgeInsets.all(20),
              color: const Color(0xFF141915),
              child: SafeArea(
                top: false,
                child: _captured
                    ? Row(
                        children: [
                          Expanded(
                            child: OutlinedButton(
                              style: OutlinedButton.styleFrom(
                                foregroundColor: Colors.white,
                                side: const BorderSide(color: Colors.white38),
                                padding: const EdgeInsets.symmetric(vertical: 14),
                              ),
                              onPressed: () {
                                setState(() {
                                  _captured = false;
                                  _proximityScore = 0.35;
                                });
                                if (_isAutoMode) _startProximitySimulation();
                              },
                              child: const Text('Retake Photo'),
                            ),
                          ),
                          const SizedBox(width: 14),
                          Expanded(
                            child: FilledButton.icon(
                              style: FilledButton.styleFrom(
                                backgroundColor: const Color(0xFF2EAD65),
                                padding: const EdgeInsets.symmetric(vertical: 14),
                              ),
                              onPressed: _locatingGps ? null : _confirm,
                              icon: const Icon(Icons.check_rounded),
                              label: const Text('Confirm & Save'),
                            ),
                          ),
                        ],
                      )
                    : Row(
                        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                        children: [
                          Text(
                            _isAutoMode
                                ? 'Auto Mode: Framing waste...'
                                : 'Manual Mode: Ready to capture',
                            style: const TextStyle(color: Colors.white70, fontSize: 13),
                          ),
                          GestureDetector(
                            onTap: () => _triggerCapture(auto: false),
                            child: Container(
                              width: 68,
                              height: 68,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                border: Border.all(color: Colors.white, width: 4),
                                color: const Color(0xFF2EAD65),
                              ),
                              child: const Icon(Icons.camera_alt_rounded, color: Colors.white, size: 30),
                            ),
                          ),
                        ],
                      ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ViewfinderCornersPainter extends CustomPainter {
  const _ViewfinderCornersPainter({required this.color});
  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..strokeWidth = 3.5
      ..style = PaintingStyle.stroke;

    const cornerLength = 28.0;
    const padding = 20.0;

    // Top Left
    canvas.drawLine(const Offset(padding, padding), const Offset(padding + cornerLength, padding), paint);
    canvas.drawLine(const Offset(padding, padding), const Offset(padding, padding + cornerLength), paint);

    // Top Right
    canvas.drawLine(Offset(size.width - padding, padding), Offset(size.width - padding - cornerLength, padding), paint);
    canvas.drawLine(Offset(size.width - padding, padding), Offset(size.width - padding, padding + cornerLength), paint);

    // Bottom Left
    canvas.drawLine(Offset(padding, size.height - padding), Offset(padding + cornerLength, size.height - padding), paint);
    canvas.drawLine(Offset(padding, size.height - padding), Offset(padding, size.height - padding - cornerLength), paint);

    // Bottom Right
    canvas.drawLine(Offset(size.width - padding, size.height - padding), Offset(size.width - padding - cornerLength, size.height - padding), paint);
    canvas.drawLine(Offset(size.width - padding, size.height - padding), Offset(size.width - padding, size.height - padding - cornerLength), paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
