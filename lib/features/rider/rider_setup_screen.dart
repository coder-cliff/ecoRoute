import 'package:flutter/material.dart';

import '../../core/pickup_request_repository.dart';
import '../../core/services/auth_service.dart';
import '../../core/services/router_service.dart';
import '../../core/services/waste_api_service.dart';
import '../../core/theme/eco_palette.dart';
import '../../domain/enums/role.dart';
import '../auth/splash_screen.dart';
import '../common/widgets/smart_install_banner.dart';

/// Dedicated Onboarding and Account Setup Terminal for Authorized Collection Riders
class RiderSetupScreen extends StatefulWidget {
  const RiderSetupScreen({
    super.key,
    required this.repository,
    required this.authService,
    this.wasteApiService,
    this.initialInviteCode,
    this.initialEmail,
  });

  final PickupRequestRepository repository;
  final AuthService authService;
  final WasteApiService? wasteApiService;
  final String? initialInviteCode;
  final String? initialEmail;

  @override
  State<RiderSetupScreen> createState() => _RiderSetupScreenState();
}

class _RiderSetupScreenState extends State<RiderSetupScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _phoneController = TextEditingController();
  final _codeController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();

  bool _isVerifying = true;
  bool _isSubmitting = false;
  bool _obscurePassword = true;
  bool _obscureConfirm = true;
  String? _errorMessage;
  String _assignedTricycle = 'TRIC-04 (Ediofe Depot)';
  Map<String, dynamic>? _verifiedInvite;

  @override
  void initState() {
    super.initState();
    String? code = widget.initialInviteCode;
    String? email = widget.initialEmail;

    if (code == null || code.isEmpty) {
      final uri = Uri.base;
      code = uri.queryParameters['invite'] ?? uri.queryParameters['code'];
      email ??= uri.queryParameters['email'];

      if ((code == null || email == null) && uri.fragment.isNotEmpty) {
        try {
          final frag = uri.fragment.startsWith('/') ? uri.fragment.substring(1) : uri.fragment;
          final fragUri = Uri.tryParse('https://ecoroute.ug/$frag');
          if (fragUri != null) {
            code ??= fragUri.queryParameters['invite'] ?? fragUri.queryParameters['code'];
            email ??= fragUri.queryParameters['email'];
          }
        } catch (_) {}
      }
    }

    _codeController.text = code ?? '';
    _emailController.text = email ?? '';
    _verifyInviteToken();
  }

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    _codeController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  Future<void> _verifyInviteToken() async {
    setState(() {
      _isVerifying = true;
      _errorMessage = null;
    });

    final queryCode = _codeController.text.trim();
    final queryEmail = _emailController.text.trim().toLowerCase();

    try {
      // 1. Check local & Firestore invited riders records
      await widget.authService.fetchInvitedRidersAsync();
      final invite = widget.authService.getRiderInvite(queryCode.isNotEmpty ? queryCode : queryEmail);

      if (!mounted) return;

      if (invite != null) {
        setState(() {
          _verifiedInvite = invite;
          _nameController.text = (invite['fullName'] as String? ?? invite['name'] as String? ?? '').trim();
          _emailController.text = (invite['email'] as String? ?? queryEmail).trim();
          _phoneController.text = (invite['phone'] as String? ?? '+256 394 880 352').trim();
          _codeController.text = (invite['inviteCode'] as String? ?? queryCode).trim();
          _assignedTricycle = (invite['tricycleId'] as String? ?? 'TRIC-04 (Ediofe Depot)').trim();
          _isVerifying = false;
        });
      } else {
        setState(() {
          _isVerifying = false;
          if (queryCode.isNotEmpty || queryEmail.isNotEmpty) {
            _errorMessage = 'Invalid or expired invitation token. Please check the code or contact Municipal Dispatch.';
          }
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isVerifying = false;
          _errorMessage = 'Could not verify token online. You can enter authorized credentials manually.';
        });
      }
    }
  }

  Future<void> _handleCompleteRegistration() async {
    if (_isSubmitting || !_formKey.currentState!.validate()) return;

    final pass = _passwordController.text;
    final confirm = _confirmPasswordController.text;
    if (pass != confirm) {
      setState(() => _errorMessage = 'Passwords do not match.');
      return;
    }

    setState(() {
      _isSubmitting = true;
      _errorMessage = null;
    });

    try {
      final email = _emailController.text.trim().toLowerCase();
      final name = _nameController.text.trim();
      final phone = _phoneController.text.trim();
      final code = _codeController.text.trim();

      // Sign out any active admin or guest session first
      await widget.authService.logout();

      final user = await widget.authService.register(
        fullName: name,
        email: email,
        password: pass,
        phone: phone,
        role: AppRole.rider,
        inviteCode: code.isNotEmpty ? code : null,
      );

      if (!mounted) return;

      // Mark invitation token accepted in system
      await widget.authService.markInviteAccepted(email);

      if (!mounted) return;

      // Route directly into Rider Task Hub
      AppRouter.routeToRole(
        context,
        role: AppRole.rider,
        repository: widget.repository,
        authService: widget.authService,
        wasteApiService: widget.wasteApiService,
      );

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Rider account activated! Welcome, ${user.fullName} ($_assignedTricycle).'),
          backgroundColor: EcoPalette.buttonDark,
        ),
      );
    } catch (e) {
      if (mounted) {
        setState(() {
          _isSubmitting = false;
          _errorMessage = e.toString().replaceAll('StateError: ', '');
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: EcoPalette.surface,
      appBar: AppBar(
        backgroundColor: EcoPalette.surface,
        elevation: 0,
        title: const Row(
          children: [
            EcoRouteLeafLogo(size: 24, color: EcoPalette.primaryDark),
            SizedBox(width: 8),
            Text(
              'EcoRoute Dispatch',
              style: TextStyle(
                fontFamily: 'Satoshi',
                fontWeight: FontWeight.w800,
                color: EcoPalette.primaryDark,
              ),
            ),
          ],
        ),
      ),
      body: SafeArea(
        child: Column(
          children: [
            const SmartInstallBanner(),
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 16.0),
                child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Badge Header
                Center(
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                    decoration: BoxDecoration(
                      color: const Color(0xFF1B3828).withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: const Color(0xFF1B3828).withValues(alpha: 0.2)),
                    ),
                    child: const Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.two_wheeler_rounded, size: 18, color: EcoPalette.primaryDark),
                        SizedBox(width: 8),
                        Text(
                          'MUNICIPAL RIDER AUTHORIZATION',
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w800,
                            letterSpacing: 0.8,
                            color: EcoPalette.primaryDark,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                const Text(
                  'Set Up Rider Terminal',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.w800,
                    color: EcoPalette.primaryDark,
                    letterSpacing: -0.5,
                  ),
                ),
                const SizedBox(height: 6),
                const Text(
                  'Create your secure PIN/Password to activate your electric tricycle collection route in Arua City.',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 13,
                    color: Color(0xFF4A5D50),
                    height: 1.4,
                  ),
                ),
                const SizedBox(height: 20),
                if (_isVerifying)
                  const Padding(
                    padding: EdgeInsets.only(bottom: 12),
                    child: LinearProgressIndicator(
                      color: EcoPalette.primaryDark,
                      backgroundColor: Color(0x221B3828),
                    ),
                  ),

                // Vehicle Assignment Card
                Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: EcoPalette.cardBorder),
                    boxShadow: const [
                      BoxShadow(color: Color(0x06000000), blurRadius: 8, offset: Offset(0, 2)),
                    ],
                  ),
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: const Color(0xFF1B3828).withValues(alpha: 0.08),
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(Icons.electric_moped_rounded, color: EcoPalette.primaryDark, size: 24),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'Assigned Tricycle Unit',
                              style: TextStyle(fontSize: 11, color: Colors.grey, fontWeight: FontWeight.w600),
                            ),
                            Text(
                              _assignedTricycle,
                              style: const TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w800,
                                color: EcoPalette.primaryDark,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const Icon(Icons.verified, color: Colors.green, size: 20),
                    ],
                  ),
                ),
                const SizedBox(height: 18),

                if (_errorMessage != null) ...[
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: const Color(0xFFFFEBEE),
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: const Color(0xFFFFCDD2)),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.error_outline, color: Color(0xFFC62828), size: 20),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            _errorMessage!,
                            style: const TextStyle(color: Color(0xFFC62828), fontSize: 12, fontWeight: FontWeight.w600),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 14),
                ],

                // Full Name
                TextFormField(
                  controller: _nameController,
                  decoration: InputDecoration(
                    labelText: 'Full Name',
                    hintText: 'e.g. Juma Kassim',
                    filled: true,
                    fillColor: Colors.white,
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
                    prefixIcon: const Icon(Icons.badge_outlined, color: EcoPalette.primaryDark),
                  ),
                  validator: (v) => (v == null || v.trim().isEmpty) ? 'Please enter your full name' : null,
                ),
                const SizedBox(height: 12),

                // Email
                TextFormField(
                  controller: _emailController,
                  keyboardType: TextInputType.emailAddress,
                  decoration: InputDecoration(
                    labelText: 'Official Rider Email',
                    hintText: 'rider@ecoroute.ug',
                    filled: true,
                    fillColor: Colors.white,
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
                    prefixIcon: const Icon(Icons.alternate_email, color: EcoPalette.primaryDark),
                  ),
                  validator: (v) => (v == null || !v.contains('@')) ? 'Please enter a valid email' : null,
                ),
                const SizedBox(height: 12),

                // Phone
                TextFormField(
                  controller: _phoneController,
                  keyboardType: TextInputType.phone,
                  decoration: InputDecoration(
                    labelText: 'Phone Number',
                    hintText: '+256 700 000 000',
                    filled: true,
                    fillColor: Colors.white,
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
                    prefixIcon: const Icon(Icons.phone_outlined, color: EcoPalette.primaryDark),
                  ),
                  validator: (v) => (v == null || v.trim().isEmpty) ? 'Please enter your phone number' : null,
                ),
                const SizedBox(height: 12),

                // Authorization Token
                TextFormField(
                  controller: _codeController,
                  readOnly: _verifiedInvite != null,
                  decoration: InputDecoration(
                    labelText: 'Authorization Token',
                    hintText: 'RIDER-XXXXXX',
                    filled: true,
                    fillColor: Colors.white,
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
                    prefixIcon: const Icon(Icons.vpn_key_outlined, color: EcoPalette.primaryDark),
                    suffixIcon: _verifiedInvite != null
                        ? const Icon(Icons.check_circle, color: Colors.green)
                        : IconButton(
                            icon: const Icon(Icons.refresh),
                            onPressed: _verifyInviteToken,
                          ),
                  ),
                  validator: (v) => (v == null || v.trim().isEmpty) ? 'Token required' : null,
                ),
                const SizedBox(height: 12),

                // Password
                TextFormField(
                  controller: _passwordController,
                  obscureText: _obscurePassword,
                  decoration: InputDecoration(
                    labelText: 'Create Password / PIN',
                    hintText: 'At least 8 characters',
                    filled: true,
                    fillColor: Colors.white,
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
                    prefixIcon: const Icon(Icons.lock_outline, color: EcoPalette.primaryDark),
                    suffixIcon: IconButton(
                      icon: Icon(_obscurePassword ? Icons.visibility_off : Icons.visibility),
                      onPressed: () => setState(() => _obscurePassword = !_obscurePassword),
                    ),
                  ),
                  validator: (v) => (v == null || v.length < 8) ? 'Password must be at least 8 characters' : null,
                ),
                const SizedBox(height: 12),

                // Confirm Password
                TextFormField(
                  controller: _confirmPasswordController,
                  obscureText: _obscureConfirm,
                  decoration: InputDecoration(
                    labelText: 'Confirm Password',
                    filled: true,
                    fillColor: Colors.white,
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
                    prefixIcon: const Icon(Icons.lock_reset, color: EcoPalette.primaryDark),
                    suffixIcon: IconButton(
                      icon: Icon(_obscureConfirm ? Icons.visibility_off : Icons.visibility),
                      onPressed: () => setState(() => _obscureConfirm = !_obscureConfirm),
                    ),
                  ),
                  validator: (v) {
                    if (v == null || v.isEmpty) return 'Please confirm your password';
                    if (v != _passwordController.text) return 'Passwords do not match';
                    return null;
                  },
                ),
                const SizedBox(height: 24),

                // Submit Button
                SizedBox(
                  height: 52,
                  child: ElevatedButton(
                    onPressed: _isSubmitting ? null : _handleCompleteRegistration,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: EcoPalette.buttonDark,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                      elevation: 0,
                    ),
                    child: _isSubmitting
                        ? const SizedBox(
                            width: 22,
                            height: 22,
                            child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2.5),
                          )
                        : const Text(
                            'Activate Dispatch Terminal',
                            style: TextStyle(
                              fontFamily: 'Satoshi',
                              fontSize: 16,
                              fontWeight: FontWeight.w800,
                              color: Colors.white,
                            ),
                          ),
                  ),
                ),
                const SizedBox(height: 16),
                Center(
                  child: TextButton(
                    onPressed: () {
                      Navigator.pushNamedAndRemoveUntil(context, '/', (route) => false);
                    },
                    child: const Text(
                      'Back to EcoRoute Home',
                      style: TextStyle(color: EcoPalette.primaryDark, fontWeight: FontWeight.w700),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    ],
  ),
),
);
  }
}
