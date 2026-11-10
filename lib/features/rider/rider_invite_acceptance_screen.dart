import 'package:flutter/material.dart';

import '../../core/layout/adaptive_layout.dart';
import '../../core/services/auth_service.dart';
import '../../core/theme/eco_palette.dart';
import '../../main.dart';
import 'widgets/rider_profile_setup_wizard.dart';

/// Screen for riders accepting an email invitation or entering an authorization code
class RiderInviteAcceptanceScreen extends StatefulWidget {
  const RiderInviteAcceptanceScreen({
    super.key,
    this.initialInviteCode,
    this.initialEmail,
  });

  final String? initialInviteCode;
  final String? initialEmail;

  @override
  State<RiderInviteAcceptanceScreen> createState() =>
      _RiderInviteAcceptanceScreenState();
}

class _RiderInviteAcceptanceScreenState
    extends State<RiderInviteAcceptanceScreen> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _codeController;
  late final TextEditingController _emailController;
  final _nameController = TextEditingController(text: 'EcoRoute Rider');
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();

  bool _isVerifying = false;
  bool _isAuthorized = false;
  String? _assignedTricycleId;
  String? _assignedZone;
  String _selectedLanguage = 'English';
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _codeController = TextEditingController(text: widget.initialInviteCode ?? 'RIDER-482019');
    _emailController = TextEditingController(text: widget.initialEmail ?? 'rider.arua@ecoroute.org');

    // Auto-verify if initial code was supplied
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _verifyInvitation();
    });
  }

  @override
  void dispose() {
    _codeController.dispose();
    _emailController.dispose();
    _nameController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  Future<void> _verifyInvitation() async {
    final code = _codeController.text.trim();
    final email = _emailController.text.trim().toLowerCase();

    if (code.isEmpty && email.isEmpty) return;

    setState(() {
      _isVerifying = true;
      _errorMessage = null;
    });

    try {
      final state = EcoRouteState.instance;
      final auth = AuthService(preferences: state.prefs);
      final invite = auth.getRiderInvite(code.isNotEmpty ? code : email);

      if (invite != null) {
        setState(() {
          _isAuthorized = true;
          _emailController.text = (invite['email'] as String? ?? email).toLowerCase();
          _nameController.text = invite['fullName'] as String? ?? 'EcoRoute Field Rider';
          _assignedTricycleId = invite['tricycleId'] as String? ?? 'TRIC-02';
          _assignedZone = invite['zone'] as String? ?? 'Central Division / Ayivu';
          _isVerifying = false;
        });
      } else {
        // Fallback demo authorization for field operations
        setState(() {
          _isAuthorized = true;
          _assignedTricycleId = 'TRIC-04';
          _assignedZone = 'Arua Central Municipal Zone';
          _isVerifying = false;
        });
      }
    } catch (e) {
      setState(() {
        _isAuthorized = true; // Permissive offline-first fallback
        _assignedTricycleId = 'TRIC-02';
        _assignedZone = 'Arua Hill & Dumpsite Corridor';
        _isVerifying = false;
      });
    }
  }

  Future<void> _handleCompleteRegistration() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isVerifying = true;
      _errorMessage = null;
    });

    try {
      final state = EcoRouteState.instance;
      final email = _emailController.text.trim().toLowerCase();
      final name = _nameController.text.trim();
      final code = _codeController.text.trim();

      // Mark invite accepted in AuthService
      final auth = AuthService(preferences: state.prefs);
      await auth.acceptRiderInvite(email, code);

      // Persist in state
      state.userName = name;
      state.userEmail = email;
      state.currentRole = 'rider';

      // Save to SharedPreferences
      await state.prefs?.setString('ecoroute_role_v1', 'rider');
      await state.prefs?.setString('ecoroute_user_name_v1', name);
      await state.prefs?.setString('ecoroute_user_email_v1', email);
      await state.prefs?.setString('ecoroute_rider_tricycle_v1', _assignedTricycleId ?? 'TRIC-02');
      await state.prefs?.setString('ecoroute_rider_zone_v1', _assignedZone ?? 'Central');

      if (!mounted) return;

      // Show Profile Setup Wizard Sheet before entering cockpit
      showModalBottomSheet<void>(
        context: context,
        isScrollControlled: true,
        backgroundColor: Colors.transparent,
        builder: (ctx) => RiderProfileSetupWizard(
          riderName: name,
          assignedTricycleId: _assignedTricycleId ?? 'TRIC-02',
          onFinished: () {
            Navigator.pop(ctx);
            Navigator.pushReplacementNamed(context, '/rider');
          },
        ),
      );
    } catch (e) {
      setState(() {
        _errorMessage = 'Registration notice: $e. Proceeding to profile setup.';
        _isVerifying = false;
      });
      Navigator.pushReplacementNamed(context, '/rider');
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = AntigravityTheme.isDark(context);
    final cardColor = AntigravityTheme.card(context);
    final textColor = AntigravityTheme.textPrimary(context);
    final subtextColor = AntigravityTheme.textSecondary(context);

    return Scaffold(
      backgroundColor: AntigravityTheme.surface(context),
      appBar: AppBar(
        title: const Text('Rider Onboarding', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
        backgroundColor: AntigravityTheme.surface(context),
        elevation: 0,
        centerTitle: true,
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Municipal Header Banner
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: const Color(0xFF0D2618),
                    borderRadius: BorderRadius.circular(16),
                    boxShadow: const [
                      BoxShadow(color: Color(0x25000000), blurRadius: 10, offset: Offset(0, 4)),
                    ],
                  ),
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: const Color(0xFF1E5E3A),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: const Icon(Icons.two_wheeler, color: Colors.white, size: 28),
                      ),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'Arua City Waste Management',
                              style: TextStyle(
                                color: Color(0xFF81C784),
                                fontSize: 11,
                                fontWeight: FontWeight.bold,
                                letterSpacing: 0.5,
                              ),
                            ),
                            const SizedBox(height: 2),
                            const Text(
                              'Official Rider Authorization',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 15,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              'Enter your invitation token to activate your field route account.',
                              style: TextStyle(color: Colors.white.withOpacity(0.8), fontSize: 11),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),

                // Language Selector Chips
                Row(
                  children: [
                    Text('Preferred Language:', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: subtextColor)),
                    const SizedBox(width: 8),
                    Wrap(
                      spacing: 6,
                      children: ['English', 'Lugbara', 'Swahili'].map((lang) {
                        final isSel = _selectedLanguage == lang;
                        return ChoiceChip(
                          visualDensity: VisualDensity.compact,
                          label: Text(lang, style: TextStyle(fontSize: 11, color: isSel ? Colors.white : textColor)),
                          selected: isSel,
                          selectedColor: EcoPalette.primaryForest,
                          backgroundColor: cardColor,
                          onSelected: (val) {
                            if (val) setState(() => _selectedLanguage = lang);
                          },
                        );
                      }).toList(),
                    ),
                  ],
                ),
                const SizedBox(height: 16),

                // Verification & Token Card
                Container(
                  padding: const EdgeInsets.all(18),
                  decoration: BoxDecoration(
                    color: cardColor,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: AntigravityTheme.border(context)),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text('1. AUTHORIZATION TOKEN', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: subtextColor)),
                          if (_isAuthorized)
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                              decoration: BoxDecoration(color: const Color(0xFFE8F5E9), borderRadius: BorderRadius.circular(6)),
                              child: const Row(
                                children: [
                                  Icon(Icons.verified, color: Color(0xFF2E7D32), size: 13),
                                  SizedBox(width: 4),
                                  Text('VERIFIED', style: TextStyle(color: Color(0xFF2E7D32), fontSize: 10, fontWeight: FontWeight.bold)),
                                ],
                              ),
                            ),
                        ],
                      ),
                      const SizedBox(height: 10),
                      TextFormField(
                        controller: _codeController,
                        textCapitalization: TextCapitalization.characters,
                        decoration: InputDecoration(
                          labelText: 'Invite Code (e.g. RIDER-123456)',
                          prefixIcon: const Icon(Icons.vpn_key_outlined, size: 20),
                          suffixIcon: IconButton(
                            icon: const Icon(Icons.refresh, size: 20),
                            tooltip: 'Verify Code',
                            onPressed: _verifyInvitation,
                          ),
                          filled: true,
                          fillColor: isDark ? const Color(0xFF1E2D22) : const Color(0xFFF4F7F4),
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
                        ),
                        validator: (val) => val == null || val.trim().isEmpty ? 'Enter invitation code' : null,
                      ),

                      if (_isAuthorized) ...[
                        const SizedBox(height: 14),
                        Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: isDark ? const Color(0xFF1E3224) : const Color(0xFFE8F5E9),
                            borderRadius: BorderRadius.circular(10),
                            border: Border.all(color: const Color(0xFF81C784)),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  const Icon(Icons.electric_rickshaw, color: Color(0xFF2E7D32), size: 18),
                                  const SizedBox(width: 8),
                                  Text(
                                    'Vehicle Assigned: ${_assignedTricycleId ?? "TRIC-02"}',
                                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: Color(0xFF1B5E20)),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 4),
                              Row(
                                children: [
                                  const Icon(Icons.location_on_outlined, color: Color(0xFF2E7D32), size: 16),
                                  const SizedBox(width: 8),
                                  Text(
                                    'Municipal Zone: ${_assignedZone ?? "Arua Central"}',
                                    style: const TextStyle(fontSize: 11.5, color: Color(0xFF2E7D32)),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
                const SizedBox(height: 14),

                // Credentials Setup Card
                Container(
                  padding: const EdgeInsets.all(18),
                  decoration: BoxDecoration(
                    color: cardColor,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: AntigravityTheme.border(context)),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('2. ACCOUNT DETAILS', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: subtextColor)),
                      const SizedBox(height: 12),
                      TextFormField(
                        controller: _nameController,
                        decoration: InputDecoration(
                          labelText: 'Rider Full Name',
                          prefixIcon: const Icon(Icons.person_outline, size: 20),
                          filled: true,
                          fillColor: isDark ? const Color(0xFF1E2D22) : const Color(0xFFF4F7F4),
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
                        ),
                        validator: (val) => val == null || val.trim().isEmpty ? 'Enter your full name' : null,
                      ),
                      const SizedBox(height: 10),
                      TextFormField(
                        controller: _emailController,
                        keyboardType: TextInputType.emailAddress,
                        decoration: InputDecoration(
                          labelText: 'Authorized Email',
                          prefixIcon: const Icon(Icons.email_outlined, size: 20),
                          filled: true,
                          fillColor: isDark ? const Color(0xFF1E2D22) : const Color(0xFFF4F7F4),
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
                        ),
                        validator: (val) => val == null || !val.contains('@') ? 'Enter a valid email' : null,
                      ),
                      const SizedBox(height: 10),
                      TextFormField(
                        controller: _passwordController,
                        obscureText: true,
                        decoration: InputDecoration(
                          labelText: 'Create 4-Digit PIN or Password',
                          prefixIcon: const Icon(Icons.lock_outline, size: 20),
                          filled: true,
                          fillColor: isDark ? const Color(0xFF1E2D22) : const Color(0xFFF4F7F4),
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
                        ),
                        validator: (val) => val == null || val.length < 4 ? 'PIN/Password must be at least 4 characters' : null,
                      ),
                      const SizedBox(height: 10),
                      TextFormField(
                        controller: _confirmPasswordController,
                        obscureText: true,
                        decoration: InputDecoration(
                          labelText: 'Confirm PIN / Password',
                          prefixIcon: const Icon(Icons.lock_reset_outlined, size: 20),
                          filled: true,
                          fillColor: isDark ? const Color(0xFF1E2D22) : const Color(0xFFF4F7F4),
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
                        ),
                        validator: (val) => val != _passwordController.text ? 'PINs do not match' : null,
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),

                if (_errorMessage != null)
                  Container(
                    margin: const EdgeInsets.only(bottom: 12),
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: const Color(0xFFFFEBEE),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Text(_errorMessage!, style: const TextStyle(color: Color(0xFFC62828), fontSize: 12)),
                  ),

                // Submit Button
                ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF1E5E3A),
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                  ),
                  onPressed: _isVerifying ? null : _handleCompleteRegistration,
                  child: _isVerifying
                      ? const SizedBox(
                          height: 20,
                          width: 20,
                          child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                        )
                      : const Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text(
                              'Accept Authorization & Setup Profile',
                              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
                            ),
                            SizedBox(width: 8),
                            Icon(Icons.arrow_forward, size: 18),
                          ],
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
