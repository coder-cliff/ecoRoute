import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../core/layout/adaptive_layout.dart';
import '../../core/services/auth_service.dart';
import '../../core/theme/eco_palette.dart';
import '../../domain/enums/role.dart';
import '../../main.dart';

/// Screen for Rider Onboarding and Activation:
/// Matches Image 1 (Screen 1: Activation, Profile Setup, Screen 2: Pending Approval)
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
  final PageController _pageController = PageController();
  int _currentPage = 0;

  // Activation Form Controllers
  final _phoneController = TextEditingController();
  final _pinController = TextEditingController();
  bool _obscurePin = true;
  bool _isVerifying = false;
  String? _activationError;

  // Profile Setup Controllers
  final _nameController = TextEditingController();
  final _plateController = TextEditingController();
  String _selectedVehicleType = 'Tricycle / Tuk-Tuk';
  String? _selfieBase64;
  bool _isSubmittingProfile = false;
  String? _profileError;

  // Verified / Assigned Data
  String? _verifiedPhone;
  String? _assignedTricycleId;
  String? _assignedZone;

  // Pending Approval State
  bool _isCheckingApproval = false;

  @override
  void initState() {
    super.initState();
    if (widget.initialInviteCode != null && widget.initialInviteCode!.isNotEmpty) {
      _pinController.text = widget.initialInviteCode!;
    }
  }

  @override
  void dispose() {
    _pageController.dispose();
    _phoneController.dispose();
    _pinController.dispose();
    _nameController.dispose();
    _plateController.dispose();
    super.dispose();
  }

  // =========================================================================
  // STEP 1: VALIDATE ACTIVATION (PHONE + TEMPORARY PIN)
  // =========================================================================
  Future<void> _handleActivation() async {
    final phone = _phoneController.text.trim();
    final pin = _pinController.text.trim();

    if (phone.isEmpty || pin.isEmpty) {
      setState(() {
        _activationError = 'Please enter both your phone number and 6-digit PIN.';
      });
      return;
    }

    setState(() {
      _isVerifying = true;
      _activationError = null;
    });

    try {
      final prefs = EcoRouteState.instance.prefs ?? await SharedPreferences.getInstance();
      final auth = AuthService(prefs);

      // 1. Verify against invited riders in local storage / backend
      final invite = auth.validateRiderActivation(phone: phone, pin: pin);

      if (invite != null) {
        _verifiedPhone = phone;
        _nameController.text = invite['fullName'] as String? ?? '';
        _assignedTricycleId = invite['tricycleId'] as String? ?? 'TRIC-04';
        _assignedZone = invite['zone'] as String? ?? 'Arua Central';

        final status = (invite['status'] as String? ?? '').toLowerCase();

        if (status == 'active' || status == 'approved') {
          // Already fully approved -> login directly
          _finalizeRiderLogin(
            name: invite['fullName'] ?? 'Field Rider',
            phone: phone,
            vehicle: invite['vehicleType'] ?? 'Tricycle',
            plate: invite['plateNumber'] ?? 'UFD 123A',
          );
          return;
        } else if (status == 'pending_approval') {
          // Profile already submitted, waiting on approval
          _pageController.animateToPage(
            2,
            duration: const Duration(milliseconds: 350),
            curve: Curves.easeInOut,
          );
        } else {
          // Needs profile setup
          _pageController.animateToPage(
            1,
            duration: const Duration(milliseconds: 350),
            curve: Curves.easeInOut,
          );
        }
      } else {
        // If not found by phone+pin, check if PIN matches invite code directly
        final inviteByCode = auth.getRiderInvite(pin);
        if (inviteByCode != null) {
          _verifiedPhone = phone;
          _nameController.text = inviteByCode['fullName'] as String? ?? '';
          _assignedTricycleId = inviteByCode['tricycleId'] as String? ?? 'TRIC-04';
          _assignedZone = inviteByCode['zone'] as String? ?? 'Arua Central';

          final status = (inviteByCode['status'] as String? ?? '').toLowerCase();
          if (status == 'active' || status == 'approved') {
            _finalizeRiderLogin(
              name: inviteByCode['fullName'] ?? 'Field Rider',
              phone: phone,
              vehicle: inviteByCode['vehicleType'] ?? 'Tricycle',
              plate: inviteByCode['plateNumber'] ?? 'UFD 123A',
            );
            return;
          }

          _pageController.animateToPage(
            1,
            duration: const Duration(milliseconds: 350),
            curve: Curves.easeInOut,
          );
          return;
        }

        setState(() {
          _activationError =
              'Invalid authorization PIN or phone number. Please check your SMS invitation or contact dispatch.';
        });
      }
    } catch (e) {
      setState(() {
        _activationError = 'Verification notice: $e';
      });
    } finally {
      if (mounted) setState(() => _isVerifying = false);
    }
  }

  // =========================================================================
  // STEP 2: PROFILE SETUP (NAME, VEHICLE, PLATE, SELFIE)
  // =========================================================================
  Future<void> _takeSelfie() async {
    try {
      final picker = ImagePicker();
      final photo = await picker.pickImage(
        source: ImageSource.camera,
        maxWidth: 600,
        maxHeight: 600,
        imageQuality: 70,
        preferredCameraDevice: CameraDevice.front,
      );

      if (photo != null) {
        final bytes = await photo.readAsBytes();
        setState(() {
          _selfieBase64 = base64Encode(bytes);
          _profileError = null;
        });
      }
    } catch (e) {
      setState(() {
        _profileError = 'Camera notice: $e';
      });
    }
  }

  Future<void> _handleSubmitProfile() async {
    final name = _nameController.text.trim();
    final plate = _plateController.text.trim();

    if (name.isEmpty) {
      setState(() => _profileError = 'Please enter your full name.');
      return;
    }
    if (plate.isEmpty) {
      setState(() => _profileError = 'Please enter your vehicle plate number.');
      return;
    }

    setState(() {
      _isSubmittingProfile = true;
      _profileError = null;
    });

    try {
      final prefs = EcoRouteState.instance.prefs ?? await SharedPreferences.getInstance();
      final auth = AuthService(prefs);

      final phone = _verifiedPhone ?? _phoneController.text.trim();

      await auth.submitRiderProfile(
        phone: phone,
        fullName: name,
        vehicleType: _selectedVehicleType,
        plateNumber: plate,
        selfieBase64: _selfieBase64,
      );

      // Check if admin has already pre-approved this phone
      final isApproved = auth.isRiderApproved(phone);

      if (isApproved) {
        _finalizeRiderLogin(
          name: name,
          phone: phone,
          vehicle: _selectedVehicleType,
          plate: plate,
        );
      } else {
        // Move to Step 3: Pending Approval Holding Screen
        _pageController.animateToPage(
          2,
          duration: const Duration(milliseconds: 350),
          curve: Curves.easeInOut,
        );
      }
    } catch (e) {
      setState(() => _profileError = 'Profile submission notice: $e');
    } finally {
      if (mounted) setState(() => _isSubmittingProfile = false);
    }
  }

  // =========================================================================
  // STEP 3: CHECK PENDING APPROVAL
  // =========================================================================
  Future<void> _checkApprovalStatus() async {
    setState(() => _isCheckingApproval = true);

    try {
      final prefs = EcoRouteState.instance.prefs ?? await SharedPreferences.getInstance();
      final auth = AuthService(prefs);
      final phone = _verifiedPhone ?? _phoneController.text.trim();

      await Future<void>.delayed(const Duration(milliseconds: 600));

      final isApproved = auth.isRiderApproved(phone);

      if (isApproved && mounted) {
        _finalizeRiderLogin(
          name: _nameController.text.trim().isNotEmpty ? _nameController.text.trim() : 'Field Rider',
          phone: phone,
          vehicle: _selectedVehicleType,
          plate: _plateController.text.trim().isNotEmpty ? _plateController.text.trim() : 'UFD 123A',
        );
      } else {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Account still under review by Arua City Operations. Please check back shortly.'),
            duration: Duration(seconds: 3),
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isCheckingApproval = false);
    }
  }

  void _finalizeRiderLogin({
    required String name,
    required String phone,
    required String vehicle,
    required String plate,
  }) {
    final state = EcoRouteState.instance;
    state.setAuthenticatedUser(
      role: 'rider',
      name: name,
      email: '${name.toLowerCase().replaceAll(' ', '.')}@ecoroute.ug',
      phone: phone,
    );
    state.isRiderShiftActive = true;

    Navigator.pushNamedAndRemoveUntil(context, '/rider', (r) => false);
  }

  void _showResendPinDialog() {
    showDialog<void>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Row(
          children: [
            Icon(Icons.sms_outlined, color: Color(0xFF1E5E3A)),
            SizedBox(width: 8),
            Text('Dispatch PIN Support', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
          ],
        ),
        content: const Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'EcoRoute Rider accounts are authorized by the Municipal Fleet Dispatcher.',
              style: TextStyle(fontSize: 13, height: 1.4),
            ),
            SizedBox(height: 10),
            Text(
              'If you have been recruited but did not receive your SMS PIN:\n'
              '• Confirm your phone number is correct\n'
              '• Contact Arua City Dispatch at +256 700 000 000\n'
              '• Or request dispatch authorization directly from the Admin Portal.',
              style: TextStyle(fontSize: 12, color: Colors.black87, height: 1.4),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('OK', style: TextStyle(color: Color(0xFF1E5E3A), fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = AntigravityTheme.isDark(context);
    final isWide = ViewportBreakpoints.isWide(context);
    final surfaceColor = isDark
        ? const Color(0xFF101913)
        : (isWide ? const Color(0xFFF1F5F9) : Colors.white);

    final pageView = PageView(
      controller: _pageController,
      physics: const NeverScrollableScrollPhysics(),
      onPageChanged: (page) => setState(() => _currentPage = page),
      children: [
        _buildActivationPage(context, isDark),
        _buildProfileSetupPage(context, isDark),
        _buildPendingApprovalPage(context, isDark),
      ],
    );

    if (!isWide) {
      return Scaffold(
        backgroundColor: surfaceColor,
        body: SafeArea(child: pageView),
      );
    }

    // Standardized Tablet & Desktop Device Showcase Frame
    return Scaffold(
      backgroundColor: surfaceColor,
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(vertical: 24, horizontal: 16),
            child: Container(
              width: 440,
              height: 740,
              decoration: BoxDecoration(
                color: isDark ? const Color(0xFF1E293B) : Colors.white,
                borderRadius: BorderRadius.circular(28),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.08),
                    blurRadius: 24,
                    offset: const Offset(0, 8),
                  ),
                ],
                border: Border.all(
                  color: isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0),
                  width: 1,
                ),
              ),
              clipBehavior: Clip.antiAlias,
              child: pageView,
            ),
          ),
        ),
      ),
    );
  }

  // =========================================================================
  // PAGE 1: ACTIVATION (EXACTLY MATCHES IMAGE 1, SCREEN 1)
  // =========================================================================
  Widget _buildActivationPage(BuildContext context, bool isDark) {
    const brandGreen = Color(0xFF1B5E20);
    const darkButtonGreen = Color(0xFF134E2E);
    const textColor = Color(0xFF1E293B);
    const subtextColor = Color(0xFF64748B);
    const fieldBg = Color(0xFFF8FAFC);
    const borderColor = Color(0xFFE2E8F0);

    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          const SizedBox(height: 12),

          // Header Logo: ecoRoute (Green Leaf + Bold Text)
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.eco, color: brandGreen, size: 24),
              const SizedBox(width: 6),
              RichText(
                text: const TextSpan(
                  children: [
                    TextSpan(
                      text: 'eco',
                      style: TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.w400,
                        color: brandGreen,
                        letterSpacing: -0.5,
                      ),
                    ),
                    TextSpan(
                      text: 'Route',
                      style: TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                        color: brandGreen,
                        letterSpacing: -0.5,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),

          const SizedBox(height: 32),

          // Title: Rider Activation
          const Text(
            'Rider Activation',
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.w800,
              color: textColor,
              letterSpacing: -0.5,
            ),
          ),
          const SizedBox(height: 8),

          // Subtitle: Activate your account to start accepting delivery requests.
          const Text(
            'Activate your account to start accepting delivery requests.',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 13.5,
              color: subtextColor,
              height: 1.35,
            ),
          ),

          const SizedBox(height: 24),

          // Error banner
          if (_activationError != null) ...[
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
              decoration: BoxDecoration(
                color: Colors.red.withOpacity(0.08),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: Colors.red.withOpacity(0.3)),
              ),
              child: Row(
                children: [
                  const Icon(Icons.error_outline, size: 18, color: Colors.red),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      _activationError!,
                      style: const TextStyle(fontSize: 12, color: Colors.red),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
          ],

          // Field 1: Phone Number
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Phone Number',
                style: TextStyle(
                  fontSize: 12.5,
                  fontWeight: FontWeight.w600,
                  color: textColor,
                ),
              ),
              const SizedBox(height: 6),
              Container(
                decoration: BoxDecoration(
                  color: isDark ? const Color(0xFF1E293B) : fieldBg,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: isDark ? const Color(0xFF334155) : borderColor),
                ),
                child: TextField(
                  controller: _phoneController,
                  keyboardType: TextInputType.phone,
                  style: TextStyle(fontSize: 14, color: isDark ? Colors.white : textColor),
                  decoration: const InputDecoration(
                    prefixIcon: Icon(Icons.phone_outlined, size: 20, color: subtextColor),
                    hintText: '+256 700 000000',
                    hintStyle: TextStyle(color: Color(0xFF94A3B8), fontSize: 13.5),
                    border: InputBorder.none,
                    contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                  ),
                ),
              ),
            ],
          ),

          const SizedBox(height: 14),

          // Field 2: Temporary PIN
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Temporary PIN',
                style: TextStyle(
                  fontSize: 12.5,
                  fontWeight: FontWeight.w600,
                  color: textColor,
                ),
              ),
              const SizedBox(height: 6),
              Container(
                decoration: BoxDecoration(
                  color: isDark ? const Color(0xFF1E293B) : fieldBg,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: isDark ? const Color(0xFF334155) : borderColor),
                ),
                child: TextField(
                  controller: _pinController,
                  obscureText: _obscurePin,
                  keyboardType: TextInputType.text,
                  style: TextStyle(fontSize: 14, color: isDark ? Colors.white : textColor),
                  decoration: InputDecoration(
                    prefixIcon: const Icon(Icons.lock_outline, size: 20, color: subtextColor),
                    hintText: '••••••',
                    hintStyle: const TextStyle(color: Color(0xFF94A3B8), fontSize: 16, letterSpacing: 2),
                    border: InputBorder.none,
                    contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                    suffixIcon: IconButton(
                      icon: Icon(
                        _obscurePin ? Icons.visibility_off_outlined : Icons.visibility_outlined,
                        size: 20,
                        color: subtextColor,
                      ),
                      onPressed: () => setState(() => _obscurePin = !_obscurePin),
                    ),
                  ),
                ),
              ),
            ],
          ),

          const SizedBox(height: 22),

          // Primary Action: Verify & Continue >
          SizedBox(
            width: double.infinity,
            height: 50,
            child: ElevatedButton(
              onPressed: _isVerifying ? null : _handleActivation,
              style: ElevatedButton.styleFrom(
                backgroundColor: darkButtonGreen,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                elevation: 0,
              ),
              child: _isVerifying
                  ? const SizedBox(
                      width: 22,
                      height: 22,
                      child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                    )
                  : const Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          'Verify & Continue',
                          style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold),
                        ),
                        SizedBox(width: 6),
                        Icon(Icons.chevron_right, size: 20),
                      ],
                    ),
            ),
          ),

          const SizedBox(height: 12),

          // Secondary Link: Didn't receive a PIN? Resend
          InkWell(
            onTap: _showResendPinDialog,
            borderRadius: BorderRadius.circular(6),
            child: const Padding(
              padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              child: Text(
                "Didn't receive a PIN? Resend",
                style: TextStyle(
                  fontSize: 12.5,
                  fontWeight: FontWeight.w600,
                  color: darkButtonGreen,
                ),
              ),
            ),
          ),

          const SizedBox(height: 20),

          // Bottom Illustration: Rider on Scooter / Tricycle with Cargo Box
          Center(
            child: SizedBox(
              height: 110,
              width: 220,
              child: CustomPaint(
                painter: DeliveryRiderIllustrationPainter(),
              ),
            ),
          ),
          const SizedBox(height: 8),
        ],
      ),
    );
  }

  // =========================================================================
  // PAGE 2: PROFILE SETUP (SPECS SECTION 2, STEP 2)
  // =========================================================================
  Widget _buildProfileSetupPage(BuildContext context, bool isDark) {
    const brandGreen = Color(0xFF1B5E20);
    const darkButtonGreen = Color(0xFF134E2E);
    const textColor = Color(0xFF1E293B);
    const subtextColor = Color(0xFF64748B);
    const fieldBg = Color(0xFFF8FAFC);
    const borderColor = Color(0xFFE2E8F0);

    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Row(
            children: [
              IconButton(
                icon: const Icon(Icons.arrow_back),
                onPressed: () => _pageController.animateToPage(
                  0,
                  duration: const Duration(milliseconds: 300),
                  curve: Curves.easeInOut,
                ),
              ),
              const Spacer(),
              const Text(
                'Step 2 of 3',
                style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: subtextColor),
              ),
            ],
          ),
          const SizedBox(height: 8),

          const Text(
            'Rider Profile Setup',
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.w800,
              color: textColor,
              letterSpacing: -0.5,
            ),
          ),
          const SizedBox(height: 6),
          const Text(
            'Provide your vehicle details and a quick selfie.\nNo license upload or zone mapping required.',
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 13, color: subtextColor, height: 1.35),
          ),

          const SizedBox(height: 24),

          // Live Selfie Capture Avatar
          Center(
            child: Stack(
              alignment: Alignment.bottomRight,
              children: [
                GestureDetector(
                  onTap: _takeSelfie,
                  child: Container(
                    width: 96,
                    height: 96,
                    decoration: BoxDecoration(
                      color: brandGreen.withOpacity(0.08),
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: _selfieBase64 != null ? brandGreen : borderColor,
                        width: 2.5,
                      ),
                      image: _selfieBase64 != null
                          ? DecorationImage(
                              image: MemoryImage(base64Decode(_selfieBase64!)),
                              fit: BoxFit.cover,
                            )
                          : null,
                    ),
                    child: _selfieBase64 == null
                        ? const Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(Icons.camera_alt_outlined, size: 32, color: brandGreen),
                              SizedBox(height: 4),
                              Text('Selfie', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: brandGreen)),
                            ],
                          )
                        : null,
                  ),
                ),
                GestureDetector(
                  onTap: _takeSelfie,
                  child: Container(
                    padding: const EdgeInsets.all(6),
                    decoration: const BoxDecoration(
                      color: brandGreen,
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(Icons.camera_alt, color: Colors.white, size: 14),
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 20),

          // Error banner
          if (_profileError != null) ...[
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
              decoration: BoxDecoration(
                color: Colors.red.withOpacity(0.08),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: Colors.red.withOpacity(0.3)),
              ),
              child: Text(
                _profileError!,
                style: const TextStyle(fontSize: 12, color: Colors.red),
              ),
            ),
            const SizedBox(height: 16),
          ],

          // Full Name
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('Full Name', style: TextStyle(fontSize: 12.5, fontWeight: FontWeight.w600, color: textColor)),
              const SizedBox(height: 6),
              Container(
                decoration: BoxDecoration(
                  color: isDark ? const Color(0xFF1E293B) : fieldBg,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: isDark ? const Color(0xFF334155) : borderColor),
                ),
                child: TextField(
                  controller: _nameController,
                  style: TextStyle(fontSize: 14, color: isDark ? Colors.white : textColor),
                  decoration: const InputDecoration(
                    prefixIcon: Icon(Icons.person_outline, size: 20, color: subtextColor),
                    hintText: 'Enter your full name',
                    hintStyle: TextStyle(color: Color(0xFF94A3B8), fontSize: 13.5),
                    border: InputBorder.none,
                    contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                  ),
                ),
              ),
            ],
          ),

          const SizedBox(height: 14),

          // Vehicle Type Dropdown
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('Vehicle Type', style: TextStyle(fontSize: 12.5, fontWeight: FontWeight.w600, color: textColor)),
              const SizedBox(height: 6),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 14),
                decoration: BoxDecoration(
                  color: isDark ? const Color(0xFF1E293B) : fieldBg,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: isDark ? const Color(0xFF334155) : borderColor),
                ),
                child: DropdownButtonHideUnderline(
                  child: DropdownButton<String>(
                    value: _selectedVehicleType,
                    isExpanded: true,
                    icon: const Icon(Icons.keyboard_arrow_down, color: subtextColor),
                    items: const [
                      DropdownMenuItem(value: 'Tricycle / Tuk-Tuk', child: Text('Tricycle / Tuk-Tuk (Primary)')),
                      DropdownMenuItem(value: 'Motorcycle (Bodaboda)', child: Text('Motorcycle (Bodaboda)')),
                      DropdownMenuItem(value: 'Light Pickup Truck', child: Text('Light Pickup Truck')),
                      DropdownMenuItem(value: 'Cargo Bicycle', child: Text('Cargo Bicycle')),
                    ],
                    onChanged: (val) {
                      if (val != null) setState(() => _selectedVehicleType = val);
                    },
                  ),
                ),
              ),
            ],
          ),

          const SizedBox(height: 14),

          // Vehicle Plate Number
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('Vehicle Plate Number', style: TextStyle(fontSize: 12.5, fontWeight: FontWeight.w600, color: textColor)),
              const SizedBox(height: 6),
              Container(
                decoration: BoxDecoration(
                  color: isDark ? const Color(0xFF1E293B) : fieldBg,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: isDark ? const Color(0xFF334155) : borderColor),
                ),
                child: TextField(
                  controller: _plateController,
                  textCapitalization: TextCapitalization.characters,
                  style: TextStyle(fontSize: 14, color: isDark ? Colors.white : textColor),
                  decoration: const InputDecoration(
                    prefixIcon: Icon(Icons.pin_outlined, size: 20, color: subtextColor),
                    hintText: 'e.g. UFD 123A',
                    hintStyle: TextStyle(color: Color(0xFF94A3B8), fontSize: 13.5),
                    border: InputBorder.none,
                    contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                  ),
                ),
              ),
            ],
          ),

          const SizedBox(height: 28),

          // Submit Button
          SizedBox(
            width: double.infinity,
            height: 52,
            child: ElevatedButton(
              onPressed: _isSubmittingProfile ? null : _handleSubmitProfile,
              style: ElevatedButton.styleFrom(
                backgroundColor: darkButtonGreen,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                elevation: 0,
              ),
              child: _isSubmittingProfile
                  ? const SizedBox(
                      width: 22,
                      height: 22,
                      child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                    )
                  : const Text('Submit Profile for Review >', style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold)),
            ),
          ),
        ],
      ),
    );
  }

  // =========================================================================
  // PAGE 3: ACCOUNT PENDING APPROVAL (EXACTLY MATCHES IMAGE 1, SCREEN 2)
  // =========================================================================
  Widget _buildPendingApprovalPage(BuildContext context, bool isDark) {
    const brandGreen = Color(0xFF1B5E20);
    const textColor = Color(0xFF0F172A);
    const subtextColor = Color(0xFF475569);

    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          const SizedBox(height: 12),

          // Header Logo: ecoRoute (Green Leaf + Bold Text)
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.eco, color: brandGreen, size: 24),
              const SizedBox(width: 6),
              RichText(
                text: const TextSpan(
                  children: [
                    TextSpan(
                      text: 'eco',
                      style: TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.w400,
                        color: brandGreen,
                        letterSpacing: -0.5,
                      ),
                    ),
                    TextSpan(
                      text: 'Route',
                      style: TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                        color: brandGreen,
                        letterSpacing: -0.5,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),

          const SizedBox(height: 48),

          // Elevated Card with Hourglass Icon
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 36),
            decoration: BoxDecoration(
              color: isDark ? const Color(0xFF1E293B) : Colors.white,
              borderRadius: BorderRadius.circular(20),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.06),
                  blurRadius: 18,
                  offset: const Offset(0, 8),
                ),
              ],
            ),
            child: Column(
              children: [
                // Golden Amber Hourglass Icon
                Container(
                  width: 72,
                  height: 72,
                  decoration: BoxDecoration(
                    color: const Color(0xFFFFF7ED),
                    shape: BoxShape.circle,
                    border: Border.all(color: const Color(0xFFFDBA74), width: 1.5),
                  ),
                  child: const Center(
                    child: Icon(
                      Icons.hourglass_top_rounded,
                      size: 40,
                      color: Color(0xFFF97316),
                    ),
                  ),
                ),

                const SizedBox(height: 24),

                // Title: Account Pending Approval
                Text(
                  'Account Pending\nApproval',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.w800,
                    color: isDark ? Colors.white : textColor,
                    letterSpacing: -0.4,
                    height: 1.25,
                  ),
                ),

                const SizedBox(height: 16),

                // Body: We are currently reviewing your rider profile...
                Text(
                  "We are currently reviewing your rider profile. This usually takes 24–48 hours. We'll notify you as soon as your account is activated and you're ready to hit the road!",
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 13.5,
                    color: isDark ? const Color(0xFFCBD5E1) : subtextColor,
                    height: 1.45,
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 36),

          // Refresh Status Action Link
          InkWell(
            onTap: _isCheckingApproval ? null : _checkApprovalStatus,
            borderRadius: BorderRadius.circular(8),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (_isCheckingApproval)
                    const SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(strokeWidth: 2, color: brandGreen),
                    )
                  else ...[
                    const Text(
                      'Refresh Status',
                      style: TextStyle(
                        fontSize: 14.5,
                        fontWeight: FontWeight.bold,
                        color: brandGreen,
                      ),
                    ),
                    const SizedBox(width: 6),
                    const Icon(Icons.refresh, size: 18, color: brandGreen),
                  ],
                ],
              ),
            ),
          ),

          const SizedBox(height: 16),
        ],
      ),
    );
  }
}

/// Custom painter that renders a delivery rider on a scooter with delivery box
/// matching the illustration at the bottom of Image 1, Screen 1.
class DeliveryRiderIllustrationPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final groundPaint = Paint()
      ..color = const Color(0xFFE2E8F0)
      ..strokeWidth = 2.0;
    canvas.drawLine(Offset(0, size.height - 10), Offset(size.width, size.height - 10), groundPaint);

    final greenPaint = Paint()..color = const Color(0xFF2E7D32);
    final darkPaint = Paint()..color = const Color(0xFF1E293B);
    final helmetPaint = Paint()..color = const Color(0xFF388E3C);
    final skinPaint = Paint()..color = const Color(0xFFD7CCC8);
    final boxPaint = Paint()..color = const Color(0xFF2E7D32);

    const cx = 110.0;
    final cy = size.height - 35;

    // Wheels
    canvas.drawCircle(Offset(cx - 45, cy + 10), 12, darkPaint);
    canvas.drawCircle(Offset(cx - 45, cy + 10), 6, Paint()..color = Colors.white);
    canvas.drawCircle(Offset(cx + 40, cy + 10), 12, darkPaint);
    canvas.drawCircle(Offset(cx + 40, cy + 10), 6, Paint()..color = Colors.white);

    // Chassis
    final bodyPath = Path()
      ..moveTo(cx - 45, cy + 10)
      ..lineTo(cx - 20, cy + 10)
      ..lineTo(cx - 5, cy - 2)
      ..lineTo(cx + 25, cy - 2)
      ..lineTo(cx + 35, cy - 18)
      ..lineTo(cx + 38, cy - 25)
      ..lineTo(cx + 33, cy - 25)
      ..lineTo(cx + 20, cy)
      ..lineTo(cx - 20, cy)
      ..close();
    canvas.drawPath(bodyPath, darkPaint);

    // Delivery Box on Back
    final boxRect = RRect.fromRectAndRadius(
      Rect.fromLTWH(cx - 52, cy - 32, 28, 28),
      const Radius.circular(4),
    );
    canvas.drawRRect(boxRect, boxPaint);

    // Rider Torso (leaning forward)
    final riderPath = Path()
      ..moveTo(cx - 15, cy - 8)
      ..lineTo(cx + 2, cy - 36)
      ..lineTo(cx + 14, cy - 36)
      ..lineTo(cx + 5, cy - 8)
      ..close();
    canvas.drawPath(riderPath, greenPaint);

    // Arm reaching handlebar
    final armPaint = Paint()
      ..color = greenPaint.color
      ..strokeWidth = 5
      ..strokeCap = StrokeCap.round;
    canvas.drawLine(Offset(cx + 6, cy - 30), Offset(cx + 32, cy - 22), armPaint);

    // Head & Helmet
    canvas.drawCircle(Offset(cx + 10, cy - 46), 8, skinPaint);
    canvas.drawCircle(Offset(cx + 10, cy - 48), 9, helmetPaint);
    // Visor
    canvas.drawArc(
      Rect.fromCircle(center: Offset(cx + 12, cy - 48), radius: 8),
      -0.4,
      1.2,
      false,
      Paint()
        ..color = Colors.black87
        ..strokeWidth = 3
        ..style = PaintingStyle.stroke,
    );

    // Leg
    final legPaint = Paint()
      ..color = darkPaint.color
      ..strokeWidth = 6
      ..strokeCap = StrokeCap.round;
    canvas.drawLine(Offset(cx - 8, cy - 6), Offset(cx + 10, cy + 4), legPaint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
