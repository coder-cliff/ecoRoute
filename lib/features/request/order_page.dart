import 'package:flutter/material.dart';

import '../../core/services/location_service.dart';
import '../../core/utils/formatters.dart';
import '../../domain/entities/pickup_request.dart';
import '../../domain/enums/waste_type.dart';
import '../../domain/enums/zone.dart';
import '../../domain/rules/price_calculator.dart';

class OrderPage extends StatefulWidget {
  const OrderPage({required this.onSubmitted, super.key});

  final Future<void> Function(PickupRequest request) onSubmitted;

  @override
  State<OrderPage> createState() => _OrderPageState();
}

class _OrderPageState extends State<OrderPage> {
  final _formKey = GlobalKey<FormState>();
  final _locationService = const LocationService();

  WasteType? _wasteType;
  Zone _zone = Zone.north;
  bool _submitting = false;
  bool _locating = false;

  final _description = TextEditingController();
  final _sackCountController = TextEditingController(text: '2');
  final _addressController = TextEditingController(text: 'Arua Municipality');
  final _phoneController = TextEditingController(text: '+256 772 100 200');

  double? _latitude;
  double? _longitude;

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
    } catch (_) {
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

  Future<void> _detectLocation() async {
    setState(() => _locating = true);

    final result = await _locationService.getCurrentUserLocation();

    if (!mounted) return;
    setState(() {
      _locating = false;
      _latitude = result.latitude;
      _longitude = result.longitude;
      if (result.resolvedZone != null) {
        _zone = result.resolvedZone!;
      }
    });

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          result.message ??
              (result.isWithinServiceArea
                  ? 'Location resolved to ${_zone.label} zone.'
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
        zone: _zone,
        address: _addressController.text.trim().isEmpty
            ? 'Arua Municipality'
            : _addressController.text.trim(),
        latitude: _latitude,
        longitude: _longitude,
        residentPhone: _phoneController.text.trim(),
      );

      await widget.onSubmitted(request);
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Could not save the request. Try again.'),
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _submitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Order a collection')),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
          children: [
            const Text(
              'Tell us what to collect',
              style: TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.w800,
                color: Color(0xFF183B20),
              ),
            ),
            const SizedBox(height: 4),
            const Text(
              'Give us a few details and our collection team will take it from there.',
              style: TextStyle(fontSize: 13),
            ),
            const SizedBox(height: 12),

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
              maxLines: 3,
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

            // Zone dropdown with GPS autofill button
            Row(
              children: [
                Expanded(
                  child: DropdownButtonFormField<Zone>(
                    initialValue: _zone,
                    decoration: const InputDecoration(
                      labelText: 'Zone',
                      isDense: true,
                    ),
                    items: Zone.values
                        .map(
                          (z) => DropdownMenuItem(
                            value: z,
                            child: Text('${z.label} Zone'),
                          ),
                        )
                        .toList(),
                    onChanged: (val) {
                      if (val != null) setState(() => _zone = val);
                    },
                  ),
                ),
                const SizedBox(width: 8),
                IconButton.filledTonal(
                  onPressed: _locating ? null : _detectLocation,
                  tooltip: 'GPS Autofill',
                  icon: _locating
                      ? const SizedBox.square(
                          dimension: 16,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Icon(Icons.my_location_rounded, size: 20),
                ),
              ],
            ),
            const SizedBox(height: 14),

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
    );
  }
}
