import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../../models/waste_category.dart';
import '../../providers/auth_provider.dart';
import '../../providers/waste_request_provider.dart';
import '../../services/api_service.dart';
import '../../services/location_service.dart';
import '../../theme/app_theme.dart';
import '../../widgets/camera_picker_widget.dart';
import '../../widgets/cash_payment_banner.dart';
import 'request_details_screen.dart';

class NewRequestScreen extends StatefulWidget {
  const NewRequestScreen({super.key});

  @override
  State<NewRequestScreen> createState() => _NewRequestScreenState();
}

class _NewRequestScreenState extends State<NewRequestScreen> {
  final _formKey = GlobalKey<FormState>();

  String? _photoPath;
  WasteCategoryType _selectedCategory = WasteCategoryType.plastics;
  int _quantityBags = 2;
  final TextEditingController _notesController = TextEditingController();
  final TextEditingController _addressController = TextEditingController();

  double _latitude = LocationService.defaultLat;
  double _longitude = LocationService.defaultLon;
  double _gpsAccuracy = 10.0;
  bool _isFetchingLocation = false;
  bool _isLocationAutoCaptured = false;
  bool _isSubmitting = false;

  DateTime _scheduledTime = DateTime.now().add(const Duration(hours: 2));

  @override
  void initState() {
    super.initState();
    _autoCaptureGPS();
  }

  @override
  void dispose() {
    _notesController.dispose();
    _addressController.dispose();
    super.dispose();
  }

  // Automatic GPS Capture (Roadmap Week 11 Mobile Capability & Week 9 External API)
  Future<void> _autoCaptureGPS() async {
    setState(() {
      _isFetchingLocation = true;
    });

    final locResult = await LocationService.getCurrentLocation();
    _latitude = locResult.latitude;
    _longitude = locResult.longitude;
    _gpsAccuracy = locResult.accuracy;

    // Call OpenStreetMap Nominatim reverse geocoding REST API
    final address = await ApiService.reverseGeocode(
      latitude: _latitude,
      longitude: _longitude,
    );

    if (mounted) {
      setState(() {
        _addressController.text = address;
        _isFetchingLocation = false;
        _isLocationAutoCaptured = true;
      });
    }
  }

  double get _currentEstimatedCash {
    final cat = WasteCategory.getByType(_selectedCategory);
    return cat.pricePerUnit * _quantityBags;
  }

  Future<void> _pickPickupDateTime() async {
    final now = DateTime.now();
    final pickedDate = await showDatePicker(
      context: context,
      initialDate: _scheduledTime,
      firstDate: now,
      lastDate: now.add(const Duration(days: 7)),
    );

    if (pickedDate != null && mounted) {
      final pickedTime = await showTimePicker(
        context: context,
        initialTime: TimeOfDay.fromDateTime(_scheduledTime),
      );

      if (pickedTime != null) {
        setState(() {
          _scheduledTime = DateTime(
            pickedDate.year,
            pickedDate.month,
            pickedDate.day,
            pickedTime.hour,
            pickedTime.minute,
          );
        });
      }
    }
  }

  Future<void> _submitRequest() async {
    // Week 5: User Input & Validation
    if (_photoPath == null || _photoPath!.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please take or select a photo of the waste first!'),
          backgroundColor: Colors.redAccent,
        ),
      );
      return;
    }

    if (_addressController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Waste location address cannot be empty.'),
          backgroundColor: Colors.redAccent,
        ),
      );
      return;
    }

    setState(() {
      _isSubmitting = true;
    });

    try {
      final auth = Provider.of<AuthProvider>(context, listen: false);
      final requestProvider = Provider.of<WasteRequestProvider>(context, listen: false);

      final newReq = await requestProvider.createRequest(
        userId: auth.currentUser.id,
        userName: auth.currentUser.name,
        userPhone: auth.currentUser.phone,
        photoPath: _photoPath!,
        categoryType: _selectedCategory,
        quantityBags: _quantityBags,
        latitude: _latitude,
        longitude: _longitude,
        address: _addressController.text.trim(),
        notes: _notesController.text.trim(),
        scheduledPickupTime: _scheduledTime,
      );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Waste pickup scheduled! Request ${newReq.id} created.'),
            backgroundColor: AppTheme.primaryGreen,
          ),
        );

        // Replace route with details screen
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (_) => RequestDetailsScreen(request: newReq),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to submit request: $e'),
            backgroundColor: Colors.redAccent,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isSubmitting = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Schedule Waste Pickup'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // SECTION 1: PHOTO CAPTURE
              const Text(
                '1. Waste Photo (Visual Verification)',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                  color: AppTheme.textDark,
                ),
              ),
              const SizedBox(height: 6),
              const Text(
                'Move close to the pile/bin and snap a picture for the collection team.',
                style: TextStyle(fontSize: 12, color: AppTheme.textMuted),
              ),
              const SizedBox(height: 10),
              CameraPickerWidget(
                initialImagePath: _photoPath,
                onImageSelected: (path) {
                  setState(() {
                    _photoPath = path;
                  });
                },
              ),
              const SizedBox(height: 24),

              // SECTION 2: AUTOMATIC GPS LOCATION
              Row(
                children: [
                  const Text(
                    '2. Automatic GPS Location',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                      color: AppTheme.textDark,
                    ),
                  ),
                  const Spacer(),
                  if (_isFetchingLocation)
                    const SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  else
                    TextButton.icon(
                      onPressed: _autoCaptureGPS,
                      icon: const Icon(Icons.my_location, size: 16),
                      label: const Text('Re-detect'),
                    ),
                ],
              ),
              const SizedBox(height: 6),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: _isLocationAutoCaptured
                        ? AppTheme.primaryGreen.withValues(alpha: 0.5)
                        : const Color(0xFFDDDDDD),
                  ),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(6),
                          decoration: BoxDecoration(
                            color: AppTheme.accentMint,
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: const Icon(Icons.satellite_alt_rounded,
                              size: 18, color: AppTheme.primaryGreen),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'GPS: ${_latitude.toStringAsFixed(5)}, ${_longitude.toStringAsFixed(5)}',
                                style: const TextStyle(
                                  fontWeight: FontWeight.w700,
                                  fontSize: 13,
                                ),
                              ),
                              Text(
                                'Accuracy: ±${_gpsAccuracy.toStringAsFixed(1)}m • Auto-recorded via device GPS',
                                style: const TextStyle(
                                  fontSize: 11,
                                  color: AppTheme.textMuted,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),
                    TextFormField(
                      controller: _addressController,
                      decoration: const InputDecoration(
                        labelText: 'Street Address (Reverse Geocoded)',
                        prefixIcon: Icon(Icons.place_rounded, color: Colors.redAccent),
                      ),
                      validator: (val) =>
                          (val == null || val.trim().isEmpty) ? 'Address is required' : null,
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),

              // SECTION 3: WASTE CATEGORY
              const Text(
                '3. Waste Category',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                  color: AppTheme.textDark,
                ),
              ),
              const SizedBox(height: 6),
              const Text(
                'Select waste type for correct sorting and collection rate.',
                style: TextStyle(fontSize: 12, color: AppTheme.textMuted),
              ),
              const SizedBox(height: 10),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: WasteCategory.allCategories.map((cat) {
                  final isSelected = _selectedCategory == cat.type;
                  return ChoiceChip(
                    avatar: Icon(cat.icon, size: 16, color: isSelected ? Colors.white : cat.color),
                    label: Text(
                      '${cat.title} (\$${cat.pricePerUnit.toStringAsFixed(2)}/bag)',
                      style: TextStyle(
                        fontWeight: FontWeight.w600,
                        fontSize: 13,
                        color: isSelected ? Colors.white : AppTheme.textDark,
                      ),
                    ),
                    selected: isSelected,
                    selectedColor: cat.color,
                    backgroundColor: Colors.white,
                    side: BorderSide(
                      color: isSelected ? cat.color : const Color(0xFFDDDDDD),
                    ),
                    onSelected: (val) {
                      if (val) {
                        setState(() {
                          _selectedCategory = cat.type;
                        });
                      }
                    },
                  );
                }).toList(),
              ),
              const SizedBox(height: 24),

              // SECTION 4: QUANTITY & PICKUP SCHEDULE
              const Text(
                '4. Volume & Preferred Pickup Time',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                  color: AppTheme.textDark,
                ),
              ),
              const SizedBox(height: 10),
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: const Color(0xFFEEEEEE)),
                ),
                child: Column(
                  children: [
                    // Quantity Stepper
                    Row(
                      children: [
                        const Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Number of Bags / Bins',
                              style: TextStyle(fontWeight: FontWeight.w600, fontSize: 14),
                            ),
                            Text(
                              'Standard 30L-50L garbage bags',
                              style: TextStyle(fontSize: 11, color: AppTheme.textMuted),
                            ),
                          ],
                        ),
                        const Spacer(),
                        IconButton.filledTonal(
                          onPressed: _quantityBags > 1
                              ? () => setState(() => _quantityBags--)
                              : null,
                          icon: const Icon(Icons.remove, size: 18),
                        ),
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 14),
                          child: Text(
                            '$_quantityBags',
                            style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w800),
                          ),
                        ),
                        IconButton.filledTonal(
                          onPressed: () => setState(() => _quantityBags++),
                          icon: const Icon(Icons.add, size: 18),
                        ),
                      ],
                    ),
                    const Divider(height: 24),
                    // Pickup Time Picker
                    InkWell(
                      onTap: _pickPickupDateTime,
                      child: Row(
                        children: [
                          const Icon(Icons.event_available_rounded, color: AppTheme.primaryGreen),
                          const SizedBox(width: 12),
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                'Scheduled Collection Window',
                                style: TextStyle(fontWeight: FontWeight.w600, fontSize: 13),
                              ),
                              Text(
                                DateFormat('EEE, MMM d, yyyy • h:mm a').format(_scheduledTime),
                                style: const TextStyle(
                                  fontSize: 12,
                                  color: AppTheme.primaryGreen,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ],
                          ),
                          const Spacer(),
                          const Icon(Icons.edit_calendar_rounded, size: 18, color: AppTheme.textMuted),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),

              // SECTION 5: NOTES & INSTRUCTIONS
              TextFormField(
                controller: _notesController,
                maxLines: 2,
                decoration: const InputDecoration(
                  labelText: 'Instructions for Rider (Optional)',
                  hintText: 'e.g. Call when outside the black gate, bags are by the curb',
                  prefixIcon: Icon(Icons.notes_rounded),
                ),
              ),
              const SizedBox(height: 24),

              // SECTION 6: HARD CASH ESTIMATION BANNER
              CashPaymentBanner(
                amount: _currentEstimatedCash,
                isCollected: false,
              ),
              const SizedBox(height: 24),

              // SUBMIT BUTTON
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: _isSubmitting ? null : _submitRequest,
                  icon: _isSubmitting
                      ? const SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                        )
                      : const Icon(Icons.send_rounded),
                  label: Text(
                    _isSubmitting
                        ? 'Dispatching Request...'
                        : 'Submit Pickup Request (\$${_currentEstimatedCash.toStringAsFixed(2)} Cash)',
                  ),
                ),
              ),
              const SizedBox(height: 30),
            ],
          ),
        ),
      ),
    );
  }
}
