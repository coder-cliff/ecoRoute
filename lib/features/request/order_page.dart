import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:image_picker/image_picker.dart';
import '../../core/services/location_service.dart';
import '../../core/utils/formatters.dart';
import '../../domain/entities/pickup_request.dart';
import '../../domain/enums/waste_type.dart';
import '../../domain/rules/price_calculator.dart';
import '../database/waste_database_sheet.dart';
import 'widgets/waste_camera_scanner.dart';

class OrderPage extends StatefulWidget {
  const OrderPage({
    required this.onSubmitted,
    this.initialPhone = '',
    this.initialAddress = '',
    this.autoTriggerCamera = false,
    super.key,
  });

  final Future<void> Function(PickupRequest request) onSubmitted;
  final String initialPhone;
  final String initialAddress;
  final bool autoTriggerCamera;

  @override
  State<OrderPage> createState() => _OrderPageState();
}

class _OrderPageState extends State<OrderPage> {
  final _formKey = GlobalKey<FormState>();
  final _locationService = const LocationService();

  WasteType? _wasteType;
  bool _submitting = false;
  bool _locating = false;

  final _description = TextEditingController();
  final _sackCountController = TextEditingController(text: '2');
  late final TextEditingController _addressController;
  late final TextEditingController _phoneController;

  double? _latitude;
  double? _longitude;
  String? _capturedPhotoLabel;
  String? _capturedPhotoPath;
  Uint8List? _capturedPhotoBytes;

  @override
  void initState() {
    super.initState();
    _addressController = TextEditingController(text: widget.initialAddress);
    _phoneController = TextEditingController(text: widget.initialPhone);
    if (widget.autoTriggerCamera) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted && _capturedPhotoLabel == null) {
          _openCameraScanner();
        }
      });
    }
  }

  int get _sackCount {
    final parsed = int.tryParse(_sackCountController.text.trim());
    return (parsed != null && parsed >= 1 && parsed <= 50) ? parsed : 1;
  }

  int get _ratePerSack => switch (_wasteType) {
        WasteType.tradingCenter => 2500,
        WasteType.unknown => 2000,
        _ => 1500,
      };

  int get _totalPrice {
    try {
      return calculateAmount(
        sackCount: _sackCount,
        pricePerSackUgx: _ratePerSack,
      );
    } catch (e) {
      return 1500;
    }
  }

  @override
  void dispose() {
    _description.dispose();
    _sackCountController.dispose();
    _addressController.dispose();
    _phoneController.dispose();
    super.dispose();
  }

  Future<void> _openCameraScanner({
    bool autoLaunchCamera = true,
    ImageSource? initialSource,
  }) async {
    await showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (_) => WasteCameraScanner(
        locationService: _locationService,
        autoCompleteOnAutoCapture: widget.autoTriggerCamera,
        autoLaunchCamera: autoLaunchCamera,
        initialSource: initialSource,
        onCaptured: (result) {
          setState(() {
            _capturedPhotoLabel = result.imageLabel;
            _capturedPhotoPath = result.photoPath;
            _capturedPhotoBytes = result.photoBytes;
            _latitude = result.locationResult.latitude;
            _longitude = result.locationResult.longitude;
          });

          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                'Photo captured! GPS coordinates locked for instant collection '
                '(${result.locationResult.isWithinServiceArea ? 'Arua municipality verified' : 'Outside boundary'}).',
              ),
              backgroundColor: const Color(0xFF2E7D32),
            ),
          );
        },
      ),
    );
  }

  Future<void> _detectLocation() async {
    setState(() => _locating = true);

    final result = await _locationService.getCurrentUserLocation();

    if (!mounted) return;
    setState(() {
      _locating = false;
      _latitude = result.latitude;
      _longitude = result.longitude;
    });

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          result.message ??
              (result.isWithinServiceArea
                  ? 'Location locked: Ready for instant on-demand collection.'
                  : 'Unable to resolve GPS location.'),
        ),
        duration: const Duration(seconds: 3),
      ),
    );
  }

  bool get _isFormDirty =>
      _description.text.trim().isNotEmpty ||
      _capturedPhotoLabel != null ||
      _wasteType != null;

  Future<bool> _confirmDiscard() async {
    if (!_isFormDirty) return true;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Discard Request?'),
        content: const Text(
          'You have unsaved waste pickup details or photos. Are you sure you want to exit?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: const Text('Keep Editing'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            style: FilledButton.styleFrom(backgroundColor: const Color(0xFFC62828)),
            child: const Text('Discard'),
          ),
        ],
      ),
    );
    return confirmed ?? false;
  }

  Future<void> _submit() async {
    if (_submitting || !_formKey.currentState!.validate()) {
      return;
    }

    setState(() => _submitting = true);
    try {
      final randomSuffix = (math.Random().nextInt(900000) + 100000).toString();
      final collisionFreeId = 'req_${DateTime.now().millisecondsSinceEpoch}_$randomSuffix';

      final request = PickupRequest(
        id: collisionFreeId,
        wasteType: _wasteType!,
        description: _description.text.trim(),
        submittedAt: DateTime.now(),
        sackCount: _sackCount,
        priceUgx: _totalPrice,
        isInstant: true,
        address: _addressController.text.trim().isEmpty
            ? 'Muni University, Arua'
            : _addressController.text.trim(),
        latitude: _latitude,
        longitude: _longitude,
        residentPhone: _phoneController.text.trim(),
        photoUrl: _capturedPhotoPath ?? _capturedPhotoLabel,
      );

      await widget.onSubmitted(request);
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Could not save the request. Please check your network connection and try again.'),
            backgroundColor: Color(0xFFC62828),
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _submitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: !_isFormDirty,
      onPopInvokedWithResult: (didPop, _) async {
        if (didPop) return;
        final shouldPop = await _confirmDiscard();
        if (shouldPop && context.mounted) {
          Navigator.of(context).pop();
        }
      },
      child: AnnotatedRegion<SystemUiOverlayStyle>(
      value: const SystemUiOverlayStyle(
        statusBarColor: Color(0xFF2EAD65),
        statusBarIconBrightness: Brightness.light,
        statusBarBrightness: Brightness.dark,
        systemNavigationBarColor: Color(0xFF2EAD65),
        systemNavigationBarIconBrightness: Brightness.light,
        systemNavigationBarDividerColor: Colors.transparent,
      ),
      child: Scaffold(
        appBar: AppBar(
          systemOverlayStyle: const SystemUiOverlayStyle(
            statusBarColor: Color(0xFF2EAD65),
            statusBarIconBrightness: Brightness.light,
            statusBarBrightness: Brightness.dark,
            systemNavigationBarColor: Color(0xFF2EAD65),
            systemNavigationBarIconBrightness: Brightness.light,
            systemNavigationBarDividerColor: Colors.transparent,
          ),
          title: const Text('Order a collection'),
        actions: [
          IconButton(
            tooltip: 'Waste Database & Rates',
            icon: const Icon(Icons.dataset_outlined),
            onPressed: () {
              showModalBottomSheet<void>(
                context: context,
                isScrollControlled: true,
                backgroundColor: Colors.transparent,
                builder: (_) => const WasteDatabaseSheet(),
              );
            },
          ),
          IconButton(
            tooltip: 'Waste Photo Scanner',
            icon: Icon(
              _capturedPhotoLabel != null
                  ? Icons.check_circle_rounded
                  : Icons.camera_alt_outlined,
              color: _capturedPhotoLabel != null ? const Color(0xFF2E7D32) : null,
            ),
            onPressed: _openCameraScanner,
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 10),
          children: [
            // Instant On-Demand Dispatch Notice
            Container(
              margin: const EdgeInsets.only(bottom: 12),
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
              decoration: BoxDecoration(
                color: const Color(0xFFE8F5E9),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: const Color(0xFFA5D6A7)),
              ),
              child: const Row(
                children: [
                  Icon(Icons.bolt_rounded, color: Color(0xFF2E7D32), size: 24),
                  SizedBox(width: 8),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Instant On-Demand Collection',
                          style: TextStyle(
                            fontWeight: FontWeight.w800,
                            fontSize: 13,
                            color: Color(0xFF1B5E20),
                          ),
                        ),
                        Text(
                          'Collections operate upon instant request across Arua municipality without zone delays.',
                          style: TextStyle(fontSize: 11, color: Color(0xFF2E7D32)),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Tell us what to collect',
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.w800,
                          color: Color(0xFF183B20),
                        ),
                      ),
                      Text(
                        _capturedPhotoLabel != null
                            ? 'Photo attached • GPS locked'
                            : 'Give details or use camera scanner',
                        style: const TextStyle(fontSize: 12, color: Color(0xFF556958)),
                      ),
                    ],
                  ),
                ),
                ActionChip(
                  avatar: Icon(
                    _capturedPhotoLabel != null
                        ? Icons.check_circle_rounded
                        : Icons.camera_alt_rounded,
                    size: 16,
                    color: const Color(0xFF2E7D32),
                  ),
                  label: Text(_capturedPhotoLabel != null ? 'Retake' : 'Scan Rubbish'),
                  onPressed: () => _openCameraScanner(autoLaunchCamera: true),
                ),
              ],
            ),
            if (_capturedPhotoLabel != null || _capturedPhotoBytes != null) ...[
              const SizedBox(height: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                decoration: BoxDecoration(
                  color: const Color(0xFFE8F5E9),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: const Color(0xFF81C784)),
                ),
                child: Row(
                  children: [
                    if (_capturedPhotoBytes != null)
                      ClipRRect(
                        borderRadius: BorderRadius.circular(8),
                        child: Image.memory(
                          _capturedPhotoBytes!,
                          width: 44,
                          height: 44,
                          fit: BoxFit.cover,
                        ),
                      )
                    else
                      Container(
                        width: 44,
                        height: 44,
                        decoration: BoxDecoration(
                          color: const Color(0xFF2E7D32),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: const Icon(
                          Icons.verified_rounded,
                          color: Colors.white,
                          size: 24,
                        ),
                      ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            _capturedPhotoLabel ?? 'waste_evidence.jpg',
                            style: const TextStyle(
                              fontWeight: FontWeight.w700,
                              fontSize: 12,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          Text(
                            _latitude != null && _longitude != null
                                ? 'GPS: ${_latitude!.toStringAsFixed(4)}, ${_longitude!.toStringAsFixed(4)} (Locked)'
                                : 'Location verified for instant dispatch',
                            style: const TextStyle(
                              fontSize: 11,
                              color: Color(0xFF2E7D32),
                            ),
                          ),
                        ],
                      ),
                    ),
                    IconButton(
                      icon: const Icon(
                        Icons.close_rounded,
                        size: 18,
                        color: Colors.redAccent,
                      ),
                      tooltip: 'Remove photo',
                      onPressed: () {
                        setState(() {
                          _capturedPhotoLabel = null;
                          _capturedPhotoPath = null;
                          _capturedPhotoBytes = null;
                        });
                      },
                    ),
                  ],
                ),
              ),
            ],
            const SizedBox(height: 10),

            // Waste type dropdown
            DropdownButtonFormField<WasteType>(
              initialValue: _wasteType,
              decoration: const InputDecoration(labelText: 'Waste type'),
              items: WasteType.values
                  .map(
                    (type) => DropdownMenuItem(
                      value: type,
                      child: Text(type.label),
                    ),
                  )
                  .toList(),
              onChanged: (value) => setState(() => _wasteType = value),
              validator: (value) =>
                  value == null ? 'Select a waste type' : null,
            ),
            const SizedBox(height: 10),

            // Collection details
            TextFormField(
              controller: _description,
              maxLines: 2,
              decoration: const InputDecoration(
                labelText: 'Collection details',
                hintText: 'Describe the waste and where it can be collected.',
              ),
              validator: (value) => value == null || value.trim().length < 10
                  ? 'Please enter at least 10 characters'
                  : null,
            ),
            const SizedBox(height: 10),

            // Compact sacks & live price calculation row
            Row(
              children: [
                Expanded(
                  flex: 2,
                  child: TextFormField(
                    controller: _sackCountController,
                    keyboardType: TextInputType.number,
                    decoration: const InputDecoration(
                      labelText: 'Sacks (1-50)',
                      isDense: true,
                    ),
                    onChanged: (_) => setState(() {}),
                    validator: (val) {
                      final n = int.tryParse(val ?? '');
                      if (n == null || n < 1 || n > 50) return '1-50';
                      return null;
                    },
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  flex: 3,
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 10,
                    ),
                    decoration: BoxDecoration(
                      color: const Color(0xFFE8F5E9),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Estimated Price',
                          style: TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.w700,
                            color: Color(0xFF2E7D32),
                          ),
                        ),
                        Text(
                          formatUgx(_totalPrice),
                          style: const TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w800,
                            color: Color(0xFF1B5E20),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),

            // Instant Pickup Address & Landmark with GPS Autofill
            TextFormField(
              controller: _addressController,
              decoration: InputDecoration(
                labelText: 'Instant pickup address / landmark',
                hintText: 'e.g. Near Market Stall #14, Arua Hill or Exact Gate',
                isDense: true,
                prefixIcon: const Icon(Icons.location_on_outlined, size: 20),
                suffixIcon: IconButton(
                  onPressed: _locating ? null : _detectLocation,
                  tooltip: 'GPS Autofill',
                  icon: _locating
                      ? const SizedBox.square(
                          dimension: 16,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Icon(Icons.my_location_rounded, size: 20),
                ),
              ),
              validator: (val) =>
                  val == null || val.trim().isEmpty ? 'Enter pickup location' : null,
            ),
            if (_latitude != null && _longitude != null) ...[
              const SizedBox(height: 6),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                decoration: BoxDecoration(
                  color: const Color(0xFFE8F5E9),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: const Color(0xFFA5D6A7)),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.check_circle_rounded, size: 14, color: Color(0xFF2E7D32)),
                    const SizedBox(width: 6),
                    Expanded(
                      child: Text(
                        'GPS Locked: ${_latitude!.toStringAsFixed(5)}°N, ${_longitude!.toStringAsFixed(5)}°E (Instant Pin)',
                        style: const TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                          color: Color(0xFF1B5E20),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
            const SizedBox(height: 12),

            // Submit Button
            SizedBox(
              width: double.infinity,
              height: 50,
              child: FilledButton.icon(
                onPressed: _submitting ? null : _submit,
                icon: _submitting
                    ? const SizedBox.square(
                        dimension: 18,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Icon(Icons.send_outlined),
                label: Text(
                  _submitting
                      ? 'Saving request...'
                      : 'Submit collection order',
                ),
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
