import 'package:flutter/material.dart';
import '../../../main.dart';

/// Screen 6: System Settings Hub (Image 6)
/// 4 Quadrants: Automation & Dispatch, Rider Onboarding, Pricing & Financials, Notification & Communication
class AdminSettingsQuadrantView extends StatefulWidget {
  const AdminSettingsQuadrantView({super.key});

  @override
  State<AdminSettingsQuadrantView> createState() => _AdminSettingsQuadrantViewState();
}

class _AdminSettingsQuadrantViewState extends State<AdminSettingsQuadrantView> {
  late bool _autoDispatch;
  late int _timeoutMinutes;
  late bool _acceptNewRiders;
  late bool _backgroundCheck;
  late bool _surgePricing;
  late TextEditingController _baseFareController;
  late bool _smsAlerts;
  late bool _whatsApp;

  @override
  void initState() {
    super.initState();
    _loadStateSettings();
  }

  void _loadStateSettings() {
    final state = EcoRouteState.instance;
    _autoDispatch = state.autoDispatchEnabled;
    _timeoutMinutes = state.autoAssignmentTimeoutMinutes;
    _acceptNewRiders = state.acceptNewRiders;
    _backgroundCheck = state.backgroundCheckIntegration;
    _surgePricing = state.surgePricingEnabled;
    _baseFareController = TextEditingController(
      text: 'UGX ${_formatNumber(state.baseFareModifierUgx)}',
    );
    _smsAlerts = state.smsAlertsEnabled;
    _whatsApp = state.whatsAppIntegration;
  }

  String _formatNumber(int val) {
    return val.toString().replaceAllMapped(
      RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'),
      (Match m) => '${m[1]},',
    );
  }

  int _parseNumber(String text) {
    final digitsOnly = text.replaceAll(RegExp(r'[^0-9]'), '');
    return int.tryParse(digitsOnly) ?? 5000;
  }

  @override
  void dispose() {
    _baseFareController.dispose();
    super.dispose();
  }

  void _saveSettings() {
    final baseFare = _parseNumber(_baseFareController.text);
    EcoRouteState.instance.updateSystemSettings(
      autoDispatch: _autoDispatch,
      timeoutMinutes: _timeoutMinutes,
      acceptRiders: _acceptNewRiders,
      backgroundCheck: _backgroundCheck,
      surgePricing: _surgePricing,
      baseFareModifier: baseFare,
      smsAlerts: _smsAlerts,
      whatsApp: _whatsApp,
    );

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        backgroundColor: Color(0xFF2E7D32),
        content: Row(
          children: [
            Icon(Icons.check_circle, color: Colors.white, size: 18),
            SizedBox(width: 8),
            Text('System settings successfully updated & applied to dispatch engine!'),
          ],
        ),
      ),
    );
  }

  void _discardSettings() {
    setState(() {
      _loadStateSettings();
    });
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Unsaved configuration changes discarded.'),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final screenWidth = MediaQuery.of(context).size.width;
    final isDesktop = screenWidth >= 1024;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Text(
            'System Settings',
            style: theme.textTheme.headlineSmall?.copyWith(
              fontWeight: FontWeight.bold,
              color: isDark ? Colors.white : const Color(0xFF1E293B),
            ),
          ),
          const SizedBox(height: 4),
          Text(
            'Configure automated dispatching, rider onboarding, pricing adjustments, and communication protocols.',
            style: theme.textTheme.bodyMedium?.copyWith(
              color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B),
            ),
          ),
          const SizedBox(height: 24),

          // 4 Quadrants Grid
          if (isDesktop)
            Column(
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(child: _buildAutomationQuadrant(isDark)),
                    const SizedBox(width: 24),
                    Expanded(child: _buildRiderOnboardingQuadrant(isDark)),
                  ],
                ),
                const SizedBox(height: 24),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(child: _buildPricingQuadrant(isDark)),
                    const SizedBox(width: 24),
                    Expanded(child: _buildNotificationQuadrant(isDark)),
                  ],
                ),
              ],
            )
          else
            Column(
              children: [
                _buildAutomationQuadrant(isDark),
                const SizedBox(height: 20),
                _buildRiderOnboardingQuadrant(isDark),
                const SizedBox(height: 20),
                _buildPricingQuadrant(isDark),
                const SizedBox(height: 20),
                _buildNotificationQuadrant(isDark),
              ],
            ),

          const SizedBox(height: 28),

          // Bottom Action Controls: Save Changes & Discard
          Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              ElevatedButton(
                onPressed: _saveSettings,
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF1B5E20),
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 14),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                  elevation: 0,
                ),
                child: const Text(
                  'Save Changes',
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                ),
              ),
              const SizedBox(width: 12),
              OutlinedButton(
                onPressed: _discardSettings,
                style: OutlinedButton.styleFrom(
                  foregroundColor: isDark ? const Color(0xFFCBD5E1) : const Color(0xFF475569),
                  side: BorderSide(
                    color: isDark ? const Color(0xFF475569) : const Color(0xFFCBD5E1),
                  ),
                  padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                ),
                child: const Text('Discard', style: TextStyle(fontSize: 14)),
              ),
            ],
          ),
          const SizedBox(height: 24),
        ],
      ),
    );
  }

  // Quadrant 1: Automation & Dispatch
  Widget _buildAutomationQuadrant(bool isDark) {
    return _buildQuadrantContainer(
      isDark: isDark,
      title: 'Automation & Dispatch',
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Switch(
                        value: _autoDispatch,
                        activeColor: const Color(0xFF2E7D32),
                        activeTrackColor: const Color(0xFFA5D6A7),
                        onChanged: (val) => setState(() => _autoDispatch = val),
                      ),
                      const SizedBox(width: 6),
                      Text(
                        'Auto-Dispatch',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 14,
                          color: isDark ? Colors.white : const Color(0xFF1E293B),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Automatically match available riders to pending client requests based on proximity.',
                    style: TextStyle(
                      fontSize: 12,
                      color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        const SizedBox(height: 18),
        Text(
          'Auto-Assignment Timeout',
          style: TextStyle(
            fontWeight: FontWeight.w600,
            fontSize: 13,
            color: isDark ? Colors.white : const Color(0xFF1E293B),
          ),
        ),
        const SizedBox(height: 6),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 14),
          decoration: BoxDecoration(
            color: isDark ? const Color(0xFF0F172A) : const Color(0xFFF8FAFC),
            borderRadius: BorderRadius.circular(8),
            border: Border.all(
              color: isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0),
            ),
          ),
          child: DropdownButtonHideUnderline(
            child: DropdownButton<int>(
              value: _timeoutMinutes,
              isExpanded: true,
              dropdownColor: isDark ? const Color(0xFF1E293B) : Colors.white,
              items: const [
                DropdownMenuItem(value: 1, child: Text('1 minute')),
                DropdownMenuItem(value: 2, child: Text('2 minutes')),
                DropdownMenuItem(value: 3, child: Text('3 minutes')),
                DropdownMenuItem(value: 5, child: Text('5 minutes')),
                DropdownMenuItem(value: 10, child: Text('10 minutes')),
              ],
              onChanged: (val) {
                if (val != null) setState(() => _timeoutMinutes = val);
              },
            ),
          ),
        ),
        const SizedBox(height: 4),
        Text(
          'set the time a rider has to accept a task before it\'s reassigned.',
          style: TextStyle(
            fontSize: 11,
            color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B),
          ),
        ),
      ],
    );
  }

  // Quadrant 2: Rider Onboarding
  Widget _buildRiderOnboardingQuadrant(bool isDark) {
    return _buildQuadrantContainer(
      isDark: isDark,
      title: 'Rider Onboarding',
      children: [
        Row(
          children: [
            Switch(
              value: _acceptNewRiders,
              activeColor: const Color(0xFF2E7D32),
              activeTrackColor: const Color(0xFFA5D6A7),
              onChanged: (val) => setState(() => _acceptNewRiders = val),
            ),
            const SizedBox(width: 6),
            Text(
              'Accept New Riders',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 14,
                color: isDark ? Colors.white : const Color(0xFF1E293B),
              ),
            ),
          ],
        ),
        const SizedBox(height: 4),
        Text(
          'Allow new rider registration submissions and enable the activation queue.',
          style: TextStyle(
            fontSize: 12,
            color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B),
          ),
        ),
        const SizedBox(height: 18),
        Row(
          children: [
            Switch(
              value: _backgroundCheck,
              activeColor: const Color(0xFF2E7D32),
              activeTrackColor: const Color(0xFFA5D6A7),
              onChanged: (val) => setState(() => _backgroundCheck = val),
            ),
            const SizedBox(width: 6),
            Text(
              'Background Check Integration',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 14,
                color: isDark ? Colors.white : const Color(0xFF1E293B),
              ),
            ),
          ],
        ),
        const SizedBox(height: 4),
        Text(
          'Require document verification before activation.',
          style: TextStyle(
            fontSize: 12,
            color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B),
          ),
        ),
      ],
    );
  }

  // Quadrant 3: Pricing & Financials
  Widget _buildPricingQuadrant(bool isDark) {
    return _buildQuadrantContainer(
      isDark: isDark,
      title: 'Pricing & Financials',
      children: [
        Row(
          children: [
            Switch(
              value: _surgePricing,
              activeColor: const Color(0xFF2E7D32),
              activeTrackColor: const Color(0xFFA5D6A7),
              onChanged: (val) => setState(() => _surgePricing = val),
            ),
            const SizedBox(width: 6),
            Text(
              'Surge Pricing',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 14,
                color: isDark ? Colors.white : const Color(0xFF1E293B),
              ),
            ),
          ],
        ),
        const SizedBox(height: 4),
        Text(
          'Enable dynamic, distance-based price adjustments during peak dispatch demand hours.',
          style: TextStyle(
            fontSize: 12,
            color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B),
          ),
        ),
        const SizedBox(height: 18),
        Text(
          'Base Fare Modifier',
          style: TextStyle(
            fontWeight: FontWeight.w600,
            fontSize: 13,
            color: isDark ? Colors.white : const Color(0xFF1E293B),
          ),
        ),
        const SizedBox(height: 6),
        TextField(
          controller: _baseFareController,
          decoration: InputDecoration(
            isDense: true,
            filled: true,
            fillColor: isDark ? const Color(0xFF0F172A) : const Color(0xFFF8FAFC),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: BorderSide(
                color: isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0),
              ),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: BorderSide(
                color: isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0),
              ),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: const BorderSide(color: Color(0xFF2E7D32), width: 1.5),
            ),
            contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
          ),
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w500,
            color: isDark ? Colors.white : const Color(0xFF1E293B),
          ),
        ),
        const SizedBox(height: 4),
        Text(
          'set the base rate for standard collections.',
          style: TextStyle(
            fontSize: 11,
            color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B),
          ),
        ),
      ],
    );
  }

  // Quadrant 4: Notification & Communication
  Widget _buildNotificationQuadrant(bool isDark) {
    return _buildQuadrantContainer(
      isDark: isDark,
      title: 'Notification & Communication',
      children: [
        Row(
          children: [
            Switch(
              value: _smsAlerts,
              activeColor: const Color(0xFF2E7D32),
              activeTrackColor: const Color(0xFFA5D6A7),
              onChanged: (val) => setState(() => _smsAlerts = val),
            ),
            const SizedBox(width: 6),
            Text(
              'SMS Alert Broadcasts',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 14,
                color: isDark ? Colors.white : const Color(0xFF1E293B),
              ),
            ),
          ],
        ),
        const SizedBox(height: 4),
        Text(
          'Send automated text alerts to riders and clients regarding route updates.',
          style: TextStyle(
            fontSize: 12,
            color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B),
          ),
        ),
        const SizedBox(height: 18),
        Row(
          children: [
            Switch(
              value: _whatsApp,
              activeColor: const Color(0xFF2E7D32),
              activeTrackColor: const Color(0xFFA5D6A7),
              onChanged: (val) => setState(() => _whatsApp = val),
            ),
            const SizedBox(width: 6),
            Text(
              'WhatsApp Integration',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 14,
                color: isDark ? Colors.white : const Color(0xFF1E293B),
              ),
            ),
          ],
        ),
        const SizedBox(height: 4),
        Text(
          'WhatsApp enterprise integration for beta updates.',
          style: TextStyle(
            fontSize: 12,
            color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B),
          ),
        ),
      ],
    );
  }

  Widget _buildQuadrantContainer({
    required bool isDark,
    required String title,
    required List<Widget> children,
  }) {
    return Container(
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E293B) : Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: isDark ? Colors.white : const Color(0xFF1E293B),
            ),
          ),
          const SizedBox(height: 18),
          ...children,
        ],
      ),
    );
  }
}
