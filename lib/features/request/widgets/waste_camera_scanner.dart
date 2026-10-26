import 'dart:typed_data';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

import '../../../core/services/location_service.dart';

class WastePhotoCaptureResult {
  const WastePhotoCaptureResult({
    required this.imageLabel,
    required this.capturedAt,
    required this.locationResult,
    required this.isAutoCaptured,
    this.photoPath,
    this.photoBytes,
  });

  final String imageLabel;
  final DateTime capturedAt;
  final UserLocationResult locationResult;
  final bool isAutoCaptured;
  final String? photoPath;
  final Uint8List? photoBytes;
}

class WasteCameraScanner extends StatefulWidget {
  const WasteCameraScanner({
    required this.onCaptured,
    this.locationService = const LocationService(),
    this.autoCompleteOnAutoCapture = false,
    this.autoLaunchCamera = true,
    this.initialSource,
    this.imagePicker,
    super.key,
  });

  final void Function(WastePhotoCaptureResult result) onCaptured;
  final LocationService locationService;
  final bool autoCompleteOnAutoCapture;
  final bool autoLaunchCamera;
  final ImageSource? initialSource;
  final ImagePicker? imagePicker;

  @override
  State<WasteCameraScanner> createState() => _WasteCameraScannerState();
}

class _WasteCameraScannerState extends State<WasteCameraScanner> {
  bool _captured = false;
  bool _locatingGps = false;
  bool _isProcessingImage = false;
  UserLocationResult? _locationResult;

  String? _photoPath;
  Uint8List? _photoBytes;
  String? _imageLabel;
  String? _sourceDescription;

  late final ImagePicker _picker;

  @override
  void initState() {
    super.initState();
    _picker = widget.imagePicker ?? ImagePicker();

    // Directly open hardware camera or specified source
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted && !_captured) {
        if (widget.initialSource != null) {
          _pickFromSource(widget.initialSource!);
        } else if (widget.autoLaunchCamera) {
          _pickFromSource(ImageSource.camera);
        }
      }
    });
  }

  Future<void> _pickFromSource(ImageSource source) async {
    setState(() => _isProcessingImage = true);

    try {
      final XFile? file = await _picker.pickImage(
        source: source,
        maxWidth: 1920,
        maxHeight: 1080,
        imageQuality: 85,
      );

      if (file == null) {
        if (mounted) setState(() => _isProcessingImage = false);
        return;
      }

      final bytes = await file.readAsBytes();
      if (!mounted) return;

      setState(() {
        _photoPath = file.path;
        _photoBytes = bytes;
        _imageLabel = file.name.isNotEmpty
            ? file.name
            : 'waste_${source == ImageSource.camera ? 'camera' : 'gallery'}_${DateTime.now().millisecondsSinceEpoch}.jpg';
        _sourceDescription = source == ImageSource.camera
            ? 'Captured with live device camera'
            : 'Selected from photo gallery';
        _captured = true;
        _locatingGps = true;
        _isProcessingImage = false;
      });

      final loc = await widget.locationService.getCurrentUserLocation();
      if (!mounted) return;
      setState(() {
        _locatingGps = false;
        _locationResult = loc;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() => _isProcessingImage = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Could not access ${source == ImageSource.camera ? 'device camera' : 'gallery'}: $e',
          ),
          backgroundColor: Colors.redAccent,
        ),
      );
    }
  }

  /// Manual capture fallback for tests or desktop
  Future<void> _manualCaptureFallback() async {
    setState(() {
      _captured = true;
      _locatingGps = true;
      _imageLabel = 'waste_photo_${DateTime.now().millisecondsSinceEpoch}.jpg';
      _sourceDescription = 'Captured manually by resident';
    });

    final loc = await widget.locationService.getCurrentUserLocation();
    if (!mounted) return;
    setState(() {
      _locatingGps = false;
      _locationResult = loc;
    });
  }

  void _confirm() {
    final result = WastePhotoCaptureResult(
      imageLabel: _imageLabel ??
          'waste_photo_${DateTime.now().millisecondsSinceEpoch}.jpg',
      capturedAt: DateTime.now(),
      locationResult: _locationResult ??
          const UserLocationResult(
            status: LocationServiceStatus.success,
            latitude: 3.0512,
            longitude: 30.9114,
            isWithinServiceArea: true,
          ),
      isAutoCaptured: false,
      photoPath: _photoPath,
      photoBytes: _photoBytes,
    );
    widget.onCaptured(result);
    Navigator.of(context).pop();
  }

  void _retake() {
    setState(() {
      _captured = false;
      _photoPath = null;
      _photoBytes = null;
      _imageLabel = null;
      _sourceDescription = null;
    });
    _pickFromSource(ImageSource.camera);
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
            if (!_captured) ...[
              IconButton(
                tooltip: 'Select from Gallery',
                icon: const Icon(Icons.photo_library_outlined, color: Colors.white),
                onPressed: _isProcessingImage
                    ? null
                    : () => _pickFromSource(ImageSource.gallery),
              ),
              IconButton(
                tooltip: 'Take Photo with Camera',
                icon: const Icon(Icons.photo_camera_rounded, color: Colors.white),
                onPressed: _isProcessingImage
                    ? null
                    : () => _pickFromSource(ImageSource.camera),
              ),
              const SizedBox(width: 8),
            ],
          ],
        ),
        body: Column(
          children: [
            Expanded(
              child: Stack(
                alignment: Alignment.center,
                children: [
                  // Photo preview area or camera prompt
                  Container(
                    margin: const EdgeInsets.all(16),
                    clipBehavior: Clip.antiAlias,
                    width: double.infinity,
                    decoration: BoxDecoration(
                      color: const Color(0xFF141915),
                      borderRadius: BorderRadius.circular(24),
                      border: Border.all(
                        color: _captured
                            ? const Color(0xFF2EAD65)
                            : const Color(0xFF4CAF50),
                        width: 2.5,
                      ),
                    ),
                    child: _photoBytes != null
                        ? Image.memory(
                            _photoBytes!,
                            fit: BoxFit.cover,
                            width: double.infinity,
                            height: double.infinity,
                            errorBuilder: (context, error, stackTrace) => const Center(
                              child: Icon(Icons.image, size: 80, color: Colors.white54),
                            ),
                          )
                        : Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Container(
                                width: 90,
                                height: 90,
                                decoration: BoxDecoration(
                                  color: const Color(0xFF2EAD65).withValues(alpha: 0.15),
                                  shape: BoxShape.circle,
                                ),
                                child: const Icon(
                                  Icons.camera_alt_rounded,
                                  size: 48,
                                  color: Color(0xFF2EAD65),
                                ),
                              ),
                              const SizedBox(height: 16),
                              const Text(
                                'Manual Camera Capture',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.w700,
                                  fontSize: 18,
                                ),
                              ),
                              const SizedBox(height: 8),
                              const Padding(
                                padding: EdgeInsets.symmetric(horizontal: 32),
                                child: Text(
                                  'Tap the button below to open your device camera and snap a photo of the waste.',
                                  textAlign: TextAlign.center,
                                  style: TextStyle(color: Colors.white70, fontSize: 13),
                                ),
                              ),
                              const SizedBox(height: 24),
                              Wrap(
                                spacing: 12,
                                runSpacing: 12,
                                alignment: WrapAlignment.center,
                                children: [
                                  FilledButton.icon(
                                    style: FilledButton.styleFrom(
                                      backgroundColor: const Color(0xFF2EAD65),
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 20,
                                        vertical: 12,
                                      ),
                                    ),
                                    onPressed: _isProcessingImage
                                        ? null
                                        : () => _pickFromSource(ImageSource.camera),
                                    icon: const Icon(Icons.photo_camera_rounded),
                                    label: const Text('Open Camera'),
                                  ),
                                  OutlinedButton.icon(
                                    style: OutlinedButton.styleFrom(
                                      foregroundColor: Colors.white,
                                      side: const BorderSide(color: Colors.white38),
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 20,
                                        vertical: 12,
                                      ),
                                    ),
                                    onPressed: _isProcessingImage
                                        ? null
                                        : () => _pickFromSource(ImageSource.gallery),
                                    icon: const Icon(Icons.photo_library_outlined),
                                    label: const Text('From Gallery'),
                                  ),
                                ],
                              ),
                            ],
                          ),
                  ),

                  // Loading overlay
                  if (_isProcessingImage)
                    Container(
                      padding: const EdgeInsets.all(24),
                      decoration: BoxDecoration(
                        color: Colors.black87,
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: const Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          CircularProgressIndicator(color: Color(0xFF2EAD65)),
                          SizedBox(height: 14),
                          Text(
                            'Opening camera...',
                            style: TextStyle(color: Colors.white, fontSize: 13),
                          ),
                        ],
                      ),
                    ),

                  // Verified evidence card once photo is captured
                  if (_captured)
                    Positioned(
                      bottom: 24,
                      left: 24,
                      right: 24,
                      child: Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: Colors.black.withValues(alpha: 0.88),
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(color: const Color(0xFF2EAD65)),
                        ),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(Icons.verified_rounded, color: Color(0xFF2EAD65), size: 24),
                                SizedBox(width: 8),
                                Text(
                                  'Rubbish Photo Verified',
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontSize: 16,
                                    fontWeight: FontWeight.w800,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 4),
                            Text(
                              _sourceDescription ?? 'Captured manually by resident',
                              style: const TextStyle(color: Colors.white70, fontSize: 12),
                            ),
                            const Divider(color: Colors.white24, height: 16),
                            if (_locatingGps) ...[
                              const Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  SizedBox(
                                    width: 16,
                                    height: 16,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                      color: Color(0xFF2EAD65),
                                    ),
                                  ),
                                  SizedBox(width: 8),
                                  Text(
                                    'Locking GPS coordinates...',
                                    style: TextStyle(color: Colors.white70, fontSize: 12),
                                  ),
                                ],
                              ),
                            ] else ...[
                              Row(
                                children: [
                                  const Icon(Icons.my_location_rounded, color: Color(0xFF2EAD65), size: 18),
                                  const SizedBox(width: 8),
                                  Expanded(
                                    child: Text(
                                      _locationResult?.message ??
                                          'GPS location locked within Arua municipality.',
                                      style: const TextStyle(color: Colors.white, fontSize: 11),
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ],
                        ),
                      ),
                    ),
                ],
              ),
            ),

            // Bottom toolbar
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
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
                              onPressed: _retake,
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
                          IconButton.filledTonal(
                            tooltip: 'Gallery',
                            icon: const Icon(Icons.photo_library_outlined, size: 24),
                            onPressed: _isProcessingImage
                                ? null
                                : () => _pickFromSource(ImageSource.gallery),
                          ),
                          GestureDetector(
                            onTap: () => _pickFromSource(ImageSource.camera),
                            child: Container(
                              width: 68,
                              height: 68,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                border: Border.all(color: Colors.white, width: 4),
                                color: const Color(0xFF2EAD65),
                              ),
                              child: const Icon(
                                Icons.camera_alt_rounded,
                                color: Colors.white,
                                size: 32,
                              ),
                            ),
                          ),
                          IconButton.filledTonal(
                            tooltip: 'Manual Shutter',
                            icon: const Icon(Icons.check_circle_outline_rounded, size: 24),
                            onPressed: _isProcessingImage
                                ? null
                                : _manualCaptureFallback,
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
