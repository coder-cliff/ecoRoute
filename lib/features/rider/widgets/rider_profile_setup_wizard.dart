import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

import '../../../core/layout/adaptive_layout.dart';
import '../../../core/theme/eco_palette.dart';
import '../../../main.dart';

/// 60-Second Fast Field Profile Setup Wizard for newly authorized collection riders
class RiderProfileSetupWizard extends StatefulWidget {
  const RiderProfileSetupWizard({
    super.key,
    required this.riderName,
    required this.assignedTricycleId,
    required this.onFinished,
  });

  final String riderName;
  final String assignedTricycleId;
  final VoidCallback onFinished;

  @override
  State<RiderProfileSetupWizard> createState() =>
      _RiderProfileSetupWizardState();
}

class _RiderProfileSetupWizardState extends State<RiderProfileSetupWizard> {
  int _currentStep = 0;
  final _kinPhoneController = TextEditingController(text: '+256 772 100 200');
  final _payoutPhoneController = TextEditingController(text: '+256 780 456 789');
  String _selectedPayoutMethod = 'MTN Mobile Money';
  String _energyType = 'Electric Battery (Swappable)';
  bool _agreedToCashPolicy = true;
  bool _wearingReflector = true;
  bool _tiresInspected = true;
  String? _photoEvidencePath;

  @override
  void dispose() {
    _kinPhoneController.dispose();
    _payoutPhoneController.dispose();
    super.dispose();
  }

  Future<void> _handleCaptureSelfie() async {
    try {
      final picker = ImagePicker();
      final photo = await picker.pickImage(
        source: ImageSource.camera,
        maxWidth: 600,
        maxHeight: 600,
        imageQuality: 70,
      );
      if (photo != null) {
        setState(() {
          _photoEvidencePath = photo.path;
        });
      }
    } catch (e) {
      debugPrint('Selfie picker notice: $e');
    }
  }

  Future<void> _handleSaveAndComplete() async {
    final state = EcoRouteState.instance;
    await state.prefs?.setString('ecoroute_rider_kin_phone', _kinPhoneController.text.trim());
    await state.prefs?.setString('ecoroute_rider_payout_phone', _payoutPhoneController.text.trim());
    await state.prefs?.setString('ecoroute_rider_payout_method', _selectedPayoutMethod);
    await state.prefs?.setString('ecoroute_rider_energy_type', _energyType);
    await state.prefs?.setBool('ecoroute_rider_profile_completed', true);

    widget.onFinished();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = AntigravityTheme.isDark(context);
    final cardBg = AntigravityTheme.card(context);
    final textColor = AntigravityTheme.textPrimary(context);
    final subtextColor = AntigravityTheme.textSecondary(context);

    return Container(
      height: MediaQuery.of(context).size.height * 0.88,
      decoration: BoxDecoration(
        color: cardBg,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
        boxShadow: const [
          BoxShadow(color: Color(0x33000000), blurRadius: 20, offset: Offset(0, -6)),
        ],
      ),
      child: Column(
        children: [
          // Drag handle
          Center(
            child: Container(
              margin: const EdgeInsets.only(top: 10, bottom: 8),
              width: 44,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.grey.withOpacity(0.3),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),

          // Header
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: EcoPalette.primaryForest.withOpacity(0.12),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Icon(Icons.badge_outlined, color: EcoPalette.primaryForest, size: 22),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Rider Profile Setup',
                        style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                      ),
                      Text(
                        'Step ${_currentStep + 1} of 3 • Fast field registration',
                        style: TextStyle(fontSize: 11.5, color: subtextColor),
                      ),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: EcoPalette.primaryForest.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    widget.assignedTricycleId,
                    style: const TextStyle(
                      color: EcoPalette.primaryForest,
                      fontWeight: FontWeight.bold,
                      fontSize: 11,
                    ),
                  ),
                ),
              ],
            ),
          ),
          const Divider(height: 1),

          // Horizontal Progress Indicator
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
            child: Row(
              children: [
                _buildProgressPill(0, '1. Identity & Safety'),
                const SizedBox(width: 8),
                _buildProgressPill(1, '2. Tricycle'),
                const SizedBox(width: 8),
                _buildProgressPill(2, '3. Payouts'),
              ],
            ),
          ),

          // Step Body
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
              child: _buildCurrentStepBody(isDark, textColor, subtextColor),
            ),
          ),

          // Bottom Navigation Buttons
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: cardBg,
              border: Border(top: BorderSide(color: Colors.grey.withOpacity(0.15))),
            ),
            child: Row(
              children: [
                if (_currentStep > 0) ...[
                  OutlinedButton(
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                    onPressed: () => setState(() => _currentStep--),
                    child: const Text('Back'),
                  ),
                  const SizedBox(width: 12),
                ],
                Expanded(
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: EcoPalette.primaryForest,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                    onPressed: () {
                      if (_currentStep < 2) {
                        setState(() => _currentStep++);
                      } else {
                        _handleSaveAndComplete();
                      }
                    },
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          _currentStep == 2 ? 'Complete & Start Shift' : 'Continue',
                          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                        ),
                        const SizedBox(width: 8),
                        Icon(_currentStep == 2 ? Icons.check_circle : Icons.arrow_forward, size: 18),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildProgressPill(int stepIndex, String title) {
    final isActive = _currentStep == stepIndex;
    final isDone = _currentStep > stepIndex;

    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 6),
        decoration: BoxDecoration(
          color: isDone
              ? EcoPalette.primaryForest
              : (isActive ? EcoPalette.primaryForest.withOpacity(0.15) : Colors.grey.withOpacity(0.1)),
          borderRadius: BorderRadius.circular(6),
        ),
        child: Center(
          child: Text(
            title,
            style: TextStyle(
              fontSize: 10,
              fontWeight: FontWeight.bold,
              color: isDone
                  ? Colors.white
                  : (isActive ? EcoPalette.primaryForest : Colors.grey[600]),
            ),
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ),
    );
  }

  Widget _buildCurrentStepBody(bool isDark, Color textColor, Color subtextColor) {
    switch (_currentStep) {
      case 0:
        return _buildStep1Identity(isDark, textColor, subtextColor);
      case 1:
        return _buildStep2Tricycle(isDark, textColor, subtextColor);
      case 2:
      default:
        return _buildStep3Payouts(isDark, textColor, subtextColor);
    }
  }

  Widget _buildStep1Identity(bool isDark, Color textColor, Color subtextColor) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Field Rider Identity & Safety',
          style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: textColor),
        ),
        const SizedBox(height: 6),
        Text(
          'Confirm your field identity and emergency contacts before deploying to Arua routes.',
          style: TextStyle(fontSize: 12, color: subtextColor),
        ),
        const SizedBox(height: 16),

        // Photo Selfie Button
        Center(
          child: GestureDetector(
            onTap: _handleCaptureSelfie,
            child: Container(
              width: 100,
              height: 100,
              decoration: BoxDecoration(
                color: isDark ? const Color(0xFF1E2D22) : const Color(0xFFEFF5F0),
                shape: BoxShape.circle,
                border: Border.all(color: EcoPalette.primaryForest, width: 2),
              ),
              child: _photoEvidencePath != null
                  ? const Icon(Icons.check, color: EcoPalette.primaryForest, size: 40)
                  : const Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.camera_alt_outlined, color: EcoPalette.primaryForest, size: 28),
                        SizedBox(height: 4),
                        Text('Selfie + Vest', style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: EcoPalette.primaryForest)),
                      ],
                    ),
            ),
          ),
        ),
        const SizedBox(height: 16),

        // Emergency Contact
        TextFormField(
          controller: _kinPhoneController,
          keyboardType: TextInputType.phone,
          decoration: InputDecoration(
            labelText: 'Next of Kin / Emergency Contact',
            hintText: '+256 7XX XXX XXX',
            prefixIcon: const Icon(Icons.emergency_outlined, color: Colors.redAccent, size: 20),
            filled: true,
            fillColor: isDark ? const Color(0xFF1E2D22) : const Color(0xFFF4F7F4),
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
          ),
        ),
        const SizedBox(height: 14),

        // Safety Gear Checkbox
        CheckboxListTile(
          contentPadding: EdgeInsets.zero,
          value: _wearingReflector,
          title: Text(
            'Equipped with Arua Municipal High-Vis Reflector Vest',
            style: TextStyle(fontSize: 12.5, fontWeight: FontWeight.w600, color: textColor),
          ),
          activeColor: EcoPalette.primaryForest,
          onChanged: (val) => setState(() => _wearingReflector = val ?? false),
        ),
      ],
    );
  }

  Widget _buildStep2Tricycle(bool isDark, Color textColor, Color subtextColor) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Vehicle Assignment & Specs',
          style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: textColor),
        ),
        const SizedBox(height: 6),
        Text(
          'Verify your assigned waste collection tricycle specs.',
          style: TextStyle(fontSize: 12, color: subtextColor),
        ),
        const SizedBox(height: 14),

        Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: isDark ? const Color(0xFF1E3224) : const Color(0xFFE8F5E9),
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: const Color(0xFF81C784)),
          ),
          child: Row(
            children: [
              const Icon(Icons.electric_rickshaw, color: Color(0xFF2E7D32), size: 36),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Fleet Unit: ${widget.assignedTricycleId}', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: Color(0xFF1B5E20))),
                    const SizedBox(height: 2),
                    const Text('Payload Capacity: 350 kg (Up to 40 Standard Sacks)', style: TextStyle(fontSize: 11.5, color: Color(0xFF2E7D32))),
                  ],
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),

        Text('Energy & Powertrain System:', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: textColor)),
        const SizedBox(height: 8),
        Column(
          children: [
            RadioListTile<String>(
              dense: true,
              contentPadding: EdgeInsets.zero,
              title: const Text('Electric Battery (Swappable at Depot)', style: TextStyle(fontSize: 12.5)),
              value: 'Electric Battery (Swappable)',
              groupValue: _energyType,
              activeColor: EcoPalette.primaryForest,
              onChanged: (val) => setState(() => _energyType = val!),
            ),
            RadioListTile<String>(
              dense: true,
              contentPadding: EdgeInsets.zero,
              title: const Text('Fuel Engine (Petrol / Hybrid)', style: TextStyle(fontSize: 12.5)),
              value: 'Fuel Engine (Petrol)',
              groupValue: _energyType,
              activeColor: EcoPalette.primaryForest,
              onChanged: (val) => setState(() => _energyType = val!),
            ),
          ],
        ),
        const SizedBox(height: 10),

        CheckboxListTile(
          contentPadding: EdgeInsets.zero,
          value: _tiresInspected,
          title: Text(
            'Tire pressure and cargo bed locking pins verified secure',
            style: TextStyle(fontSize: 12.5, fontWeight: FontWeight.w600, color: textColor),
          ),
          activeColor: EcoPalette.primaryForest,
          onChanged: (val) => setState(() => _tiresInspected = val ?? false),
        ),
      ],
    );
  }

  Widget _buildStep3Payouts(bool isDark, Color textColor, Color subtextColor) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Commission Payout & Remittance',
          style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: textColor),
        ),
        const SizedBox(height: 6),
        Text(
          'Set up your mobile wallet for weekly commissions (70% per completed sack).',
          style: TextStyle(fontSize: 12, color: subtextColor),
        ),
        const SizedBox(height: 14),

        // Payment Method Dropdown
        Text('Preferred Mobile Wallet:', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: textColor)),
        const SizedBox(height: 8),
        DropdownButtonFormField<String>(
          value: _selectedPayoutMethod,
          decoration: InputDecoration(
            filled: true,
            fillColor: isDark ? const Color(0xFF1E2D22) : const Color(0xFFF4F7F4),
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
          ),
          items: const [
            DropdownMenuItem(value: 'MTN Mobile Money', child: Text('MTN Mobile Money (MoMo)')),
            DropdownMenuItem(value: 'Airtel Money', child: Text('Airtel Money')),
          ],
          onChanged: (val) {
            if (val != null) setState(() => _selectedPayoutMethod = val);
          },
        ),
        const SizedBox(height: 12),

        TextFormField(
          controller: _payoutPhoneController,
          keyboardType: TextInputType.phone,
          decoration: InputDecoration(
            labelText: 'Wallet Registered Phone Number',
            hintText: '+256 7XX XXX XXX',
            prefixIcon: const Icon(Icons.account_balance_wallet_outlined, size: 20),
            filled: true,
            fillColor: isDark ? const Color(0xFF1E2D22) : const Color(0xFFF4F7F4),
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
          ),
        ),
        const SizedBox(height: 16),

        // Cash Remittance Policy Agreement
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: isDark ? const Color(0xFF262016) : const Color(0xFFFFF8E1),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: const Color(0xFFFFB300)),
          ),
          child: Column(
            children: [
              SwitchListTile(
                contentPadding: EdgeInsets.zero,
                value: _agreedToCashPolicy,
                title: const Text(
                  'Physical Cash Pouch Agreement',
                  style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: Color(0xFFB78103)),
                ),
                subtitle: const Text(
                  'I agree to keep physical cash safe in the pouch and reconcile with the Depot Desk at the end of each shift.',
                  style: TextStyle(fontSize: 11, color: Color(0xFF8D6E63)),
                ),
                activeColor: const Color(0xFFB78103),
                onChanged: (val) => setState(() => _agreedToCashPolicy = val),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
