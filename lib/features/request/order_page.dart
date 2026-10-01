import 'package:flutter/material.dart';

import '../../domain/entities/pickup_request.dart';
import '../../domain/enums/waste_type.dart';

class OrderPage extends StatefulWidget {
  const OrderPage({required this.onSubmitted, super.key});

  final Future<void> Function(PickupRequest request) onSubmitted;

  @override
  State<OrderPage> createState() => _OrderPageState();
}

class _OrderPageState extends State<OrderPage> {
  final _formKey = GlobalKey<FormState>();
  WasteType? _wasteType;
  bool _submitting = false;
  final _description = TextEditingController();

  @override
  void dispose() {
    _description.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (_submitting || !_formKey.currentState!.validate()) {
      return;
    }

    setState(() => _submitting = true);
    try {
      await widget.onSubmitted(
        PickupRequest(
          id: DateTime.now().microsecondsSinceEpoch.toString(),
          wasteType: _wasteType!,
          description: _description.text.trim(),
          submittedAt: DateTime.now(),
        ),
      );
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
          padding: const EdgeInsets.all(20),
          children: [
            const Text(
              'Tell us what to collect',
              style: TextStyle(
                fontSize: 26,
                fontWeight: FontWeight.w800,
                color: Color(0xFF183B20),
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              'Give us a few details and our collection team will take it from there.',
            ),
            const SizedBox(height: 24),
            DropdownButtonFormField<WasteType>(
              initialValue: _wasteType,
              decoration: const InputDecoration(labelText: 'Waste type'),
              items: WasteType.values
                  .map(
                    (type) =>
                        DropdownMenuItem(value: type, child: Text(type.label)),
                  )
                  .toList(),
              onChanged: (value) => setState(() => _wasteType = value),
              validator: (value) =>
                  value == null ? 'Select a waste type' : null,
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _description,
              maxLines: 5,
              decoration: const InputDecoration(
                labelText: 'Collection details',
                hintText: 'Describe the waste and where it can be collected.',
              ),
              validator: (value) => value == null || value.trim().length < 10
                  ? 'Please enter at least 10 characters'
                  : null,
            ),
            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              height: 52,
              child: FilledButton.icon(
                onPressed: _submitting ? null : _submit,
                icon: _submitting
                    ? const SizedBox.square(
                        dimension: 18,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Icon(Icons.send_outlined),
                label: Text(
                  _submitting ? 'Saving request...' : 'Submit collection order',
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
