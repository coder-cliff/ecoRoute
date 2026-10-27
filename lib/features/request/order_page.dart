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
    this.autoTriggerCamera = false,
    super.key,
  });

  final Future<void> Function(PickupRequest request) onSubmitted;
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
  final _addressController = TextEditingController(text: 'Muni University, Arua');
  final _phoneController = TextEditingController(text: '+256394880352');

  double? _latitude;
  double? _longitude;
  String? _capturedPhotoLabel;
  String? _capturedPhotoPath;
  Uint8List? _capturedPhotoBytes;

  @override
  void initState() {
    super.initState();
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
                '(${result.locationResult.isWithinServiceArea ? 'Muni University service area verified' : 'Outside boundary'}).',
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

  Future<void> _submit() async {
    if (_submitting || !_formKey.currentState!.validate()) {
      return;
    }

    setState(() => _submitting = true);
    try {
      final request = PickupRequest(
        id: DateTime.now().microsecondsSinceEpoch.toString(),
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
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Could not save the request: $e'),
            backgroundColor: const Color(0xFFC62828),
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _submitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return AnnotatedRegion<SystemUiOverlayStyle>(
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
          title: const Text('Submit collection order'),
          backgroundColor: const Color(0xFF2EAD65),
          foregroundColor: Colors.white,
        ),
        body: SafeArea(
          child: Form(
            key: _formKey,
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Collection details',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 12),
                  DropdownButtonFormField<WasteType>(
                    value: _wasteType,
                    decoration: const InputDecoration(
                      labelText: 'Waste type',
                      border: OutlineInputBorder(),
                    ),
                    items: WasteType.values
                        .map(
                          (type) => DropdownMenuItem(
                            value: type,
                            child: Text(type.label),
                          ),
                        )
                        .toList(),
                    onChanged: (value) => setState(() => _wasteType = value),
                    validator: (value) => value == null ? 'Select a waste type' : null,
                  ),
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: _description,
                    minLines: 3,
                    maxLines: 5,
                    decoration: const InputDecoration(
                      labelText: 'Description',
                      border: OutlineInputBorder(),
                    ),
                    validator: (value) =>
                        (value == null || value.trim().length < 10)
                            ? 'Please enter at least 10 characters'
                            : null,
                  ),
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: _sackCountController,
                    keyboardType: TextInputType.number,
                    decoration: const InputDecoration(
                      labelText: 'Sacks',
                      border: OutlineInputBorder(),
                    ),
                  ),
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: _addressController,
                    decoration: const InputDecoration(
                      labelText: 'Pickup address',
                      border: OutlineInputBorder(),
                    ),
                  ),
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: _phoneController,
                    keyboardType: TextInputType.phone,
                    decoration: const InputDecoration(
                      labelText: 'Resident phone',
                      border: OutlineInputBorder(),
                    ),
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(
                        child: FilledButton.icon(
                          onPressed: _detectLocation,
                          icon: _locating
                              ? const SizedBox(
                                  width: 16,
                                  height: 16,
                                  child: CircularProgressIndicator(strokeWidth: 2),
                                )
                              : const Icon(Icons.location_on_outlined),
                          label: Text(_locating ? 'Locating...' : 'Use GPS'),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 18),
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: const Color(0xFFF1F8F3),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      'Estimated total: ${_formatCurrency(_totalPrice)}',
                      style: const TextStyle(
                        fontWeight: FontWeight.w700,
                        color: Color(0xFF1B5E20),
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),
                  SizedBox(
                    width: double.infinity,
                    child: FilledButton(
                      onPressed: _submitting ? null : _submit,
                      child: Text(_submitting ? 'Submitting...' : 'Submit collection order'),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  String _formatCurrency(int value) => formatCurrencyUgx(value);
}

