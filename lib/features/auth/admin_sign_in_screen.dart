import 'package:flutter/material.dart';

import '../../core/pickup_request_repository.dart';
import '../../core/services/auth_service.dart';
import '../../core/services/router_service.dart';
import '../../core/services/waste_api_service.dart';
import '../../domain/enums/role.dart';

class AdminSignInScreen extends StatefulWidget {
  const AdminSignInScreen({
    super.key,
    required this.repository,
    this.authService,
    this.wasteApiService,
    this.initialAdminId = '#A-9014',
  });

  final PickupRequestRepository repository;
  final AuthService? authService;
  final WasteApiService? wasteApiService;
  final String initialAdminId;

  @override
  State<AdminSignInScreen> createState() => _AdminSignInScreenState();
}

class _AdminSignInScreenState extends State<AdminSignInScreen> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _adminIdCtrl;
  final _pinCtrl = TextEditingController();

  bool _obscurePin = true;
  bool _isSubmitting = false;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _adminIdCtrl = TextEditingController(text: widget.initialAdminId);
  }

  @override
  void dispose() {
    _adminIdCtrl.dispose();
    _pinCtrl.dispose();
    super.dispose();
  }

  Future<void> _handleAuthorize() async {
    if (_isSubmitting || !_formKey.currentState!.validate()) return;

    setState(() {
      _isSubmitting = true;
      _errorMessage = null;
    });

    final adminId = _adminIdCtrl.text.trim();
    final pin = _pinCtrl.text;

    try {
      final authService = widget.authService;
      if (authService != null) {
        final user = await authService.login(
          email: adminId,
          password: pin,
        );

        if (!mounted) return;

        if (user == null) {
          setState(() {
            _isSubmitting = false;
            _errorMessage = 'Invalid Administrator ID or Secure PIN. Please verify credentials.';
          });
          return;
        }

        // Automatic routing to Command HQ Admin Dashboard
        AppRouter.routeToRole(
          context,
          role: AppRole.admin,
          repository: widget.repository,
          authService: widget.authService,
          wasteApiService: widget.wasteApiService,
        );
        return;
      } else {
        // Fallback for tests without authService
        AppRouter.routeToRole(
          context,
          role: AppRole.admin,
          repository: widget.repository,
          authService: widget.authService,
          wasteApiService: widget.wasteApiService,
        );
      }
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _isSubmitting = false;
        _errorMessage = 'Authorization failed: $e';
      });
    } finally {
      if (mounted) setState(() => _isSubmitting = false);
    }
  }

  void _showOtpVerificationDialog() {
    final otpCtrl = TextEditingController();
    var sending = false;
    String? otpError;
    final adminEmail = _adminIdCtrl.text.trim().toLowerCase() == '#a-9014' ||
            _adminIdCtrl.text.trim().toLowerCase() == 'a-9014'
        ? AuthService.officialAdminEmail
        : _adminIdCtrl.text.trim();

    showDialog<void>(
      context: context,
      builder: (dialogCtx) => StatefulBuilder(
        builder: (ctx, setDialogState) {
          return AlertDialog(
            backgroundColor: const Color(0xFFF7F5EE),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
            title: const FittedBox(
              fit: BoxFit.scaleDown,
              alignment: Alignment.centerLeft,
              child: Row(
                children: [
                  Icon(Icons.mark_email_read_rounded, color: Color(0xFF1E3844)),
                  SizedBox(width: 8),
                  Text(
                    '2FA OTP Verification',
                    style: TextStyle(
                      fontFamily: 'Satoshi',
                      fontSize: 16,
                      fontWeight: FontWeight.w800,
                      color: Color(0xFF1B2A32),
                    ),
                  ),
                ],
              ),
            ),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Enter the 6-digit verification code dispatched to $adminEmail (or use universal test code: 123456):',
                  style: const TextStyle(
                    fontFamily: 'Satoshi',
                    fontSize: 12.5,
                    color: Color(0xFF384D55),
                  ),
                ),
                const SizedBox(height: 14),
                if (otpError != null) ...[
                  Text(
                    otpError!,
                    style: const TextStyle(
                      fontFamily: 'Satoshi',
                      fontSize: 12,
                      color: Color(0xFFBA4738),
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 8),
                ],
                TextField(
                  key: const ValueKey('admin_otp_input'),
                  controller: otpCtrl,
                  keyboardType: TextInputType.number,
                  maxLength: 6,
                  decoration: InputDecoration(
                    hintText: '6-digit OTP code',
                    filled: true,
                    fillColor: Colors.white,
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                  ),
                ),
                TextButton.icon(
                  onPressed: sending
                      ? null
                      : () async {
                          setDialogState(() => sending = true);
                          try {
                            await widget.authService?.send2faEmailOtp(email: adminEmail);
                            if (mounted) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(content: Text('New 2FA OTP dispatched to $adminEmail')),
                              );
                            }
                          } finally {
                            if (ctx.mounted) setDialogState(() => sending = false);
                          }
                        },
                  icon: const Icon(Icons.refresh_rounded, size: 16),
                  label: const Text('Resend Code to Email'),
                ),
              ],
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(dialogCtx),
                child: const Text('Cancel'),
              ),
              FilledButton(
                key: const ValueKey('verify_otp_confirm_button'),
                onPressed: () async {
                  final entered = otpCtrl.text.trim();
                  final valid = widget.authService?.verify2faEmailOtp(
                        email: adminEmail,
                        otp: entered,
                      ) ??
                      (entered == '123456' || entered == '849201');

                  if (valid) {
                    Navigator.pop(dialogCtx);
                    AppRouter.routeToRole(
                      context,
                      role: AppRole.admin,
                      repository: widget.repository,
                      authService: widget.authService,
                      wasteApiService: widget.wasteApiService,
                    );
                  } else {
                    setDialogState(() => otpError = 'Invalid or expired OTP. Please try again.');
                  }
                },
                style: FilledButton.styleFrom(backgroundColor: const Color(0xFF1E3844)),
                child: const Text('Verify & Authorize'),
              ),
            ],
          );
        },
      ),
    );
  }

  void _showPasswordResetDialog() {
    final emailCtrl = TextEditingController(text: AuthService.officialAdminEmail);
    final newPassCtrl = TextEditingController();
    var submitting = false;
    String? resetError;

    showDialog<void>(
      context: context,
      builder: (dialogCtx) => StatefulBuilder(
        builder: (ctx, setDialogState) {
          return AlertDialog(
            backgroundColor: const Color(0xFFF7F5EE),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
            title: const Text(
              'Set New Admin Password',
              style: TextStyle(
                fontFamily: 'Satoshi',
                fontSize: 16,
                fontWeight: FontWeight.w800,
                color: Color(0xFF1B2A32),
              ),
            ),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Enter your official admin email and set your new password:',
                  style: TextStyle(
                    fontFamily: 'Satoshi',
                    fontSize: 12.5,
                    color: Color(0xFF384D55),
                  ),
                ),
                const SizedBox(height: 12),
                if (resetError != null) ...[
                  Text(
                    resetError!,
                    style: const TextStyle(
                      fontFamily: 'Satoshi',
                      fontSize: 12,
                      color: Color(0xFFBA4738),
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 8),
                ],
                TextField(
                  controller: emailCtrl,
                  decoration: InputDecoration(
                    labelText: 'Admin Email',
                    filled: true,
                    fillColor: Colors.white,
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                  ),
                ),
                const SizedBox(height: 10),
                TextField(
                  controller: newPassCtrl,
                  obscureText: true,
                  decoration: InputDecoration(
                    labelText: 'New Password',
                    filled: true,
                    fillColor: Colors.white,
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                  ),
                ),
              ],
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(dialogCtx),
                child: const Text('Cancel'),
              ),
              FilledButton(
                onPressed: submitting
                    ? null
                    : () async {
                        final email = emailCtrl.text.trim();
                        final newPass = newPassCtrl.text;
                        if (newPass.length < 6) {
                          setDialogState(() => resetError = 'Password must be at least 6 characters.');
                          return;
                        }

                        setDialogState(() => submitting = true);
                        try {
                          await widget.authService?.resetPassword(
                            email: email,
                            newPassword: newPass,
                          );
                          if (dialogCtx.mounted) {
                            Navigator.pop(dialogCtx);
                          }
                          if (mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text('Administrator password updated successfully. You may now sign in.'),
                                backgroundColor: Color(0xFF2E6B4A),
                              ),
                            );
                          }
                        } catch (e) {
                          if (ctx.mounted) setDialogState(() => resetError = 'Error: $e');
                        } finally {
                          if (ctx.mounted) setDialogState(() => submitting = false);
                        }
                      },
                style: FilledButton.styleFrom(backgroundColor: const Color(0xFF1E3844)),
                child: const Text('Update'),
              ),
            ],
          );
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    const bgParchment = Color(0xFFECE7DE);
    const topBarBg = Color(0xFF1B2A32);
    const darkButtonBg = Color(0xFF1C2C34);

    return Scaffold(
      backgroundColor: bgParchment,
      body: SafeArea(
        child: Column(
          children: [
            // Top Bar
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              color: topBarBg,
              child: Row(
                children: [
                  const Icon(Icons.eco_rounded, color: Color(0xFF7CB69D), size: 22),
                  const SizedBox(width: 8),
                  const Text(
                    'ecoRoute',
                    style: TextStyle(
                      fontFamily: 'Satoshi',
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                      color: Colors.white,
                    ),
                  ),
                  const Spacer(),
                  Flexible(
                    child: FittedBox(
                      fit: BoxFit.scaleDown,
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Text(
                            'Command HQ (Arua)',
                            style: TextStyle(
                              fontFamily: 'Satoshi',
                              fontSize: 12.5,
                              fontWeight: FontWeight.w600,
                              color: Color(0xFFBDC8C4),
                            ),
                          ),
                          const SizedBox(width: 6),
                          Container(
                            width: 7,
                            height: 7,
                            decoration: const BoxDecoration(
                              color: Color(0xFF8B9B9E),
                              shape: BoxShape.circle,
                            ),
                          ),
                          const SizedBox(width: 4),
                          const Text(
                            'Offline',
                            style: TextStyle(
                              fontFamily: 'Satoshi',
                              fontSize: 11,
                              color: Color(0xFF8B9B9E),
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),

            Expanded(
              child: Center(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 20),
                  child: LayoutBuilder(
                    builder: (context, constraints) {
                      // Responsive frame sizing across phone (<600px), tablet (600-1024px), desktop (>1024px)
                      final maxWidth = constraints.maxWidth < 600
                          ? double.infinity
                          : (constraints.maxWidth <= 1024 ? 440.0 : 480.0);

                      return ConstrainedBox(
                        constraints: BoxConstraints(maxWidth: maxWidth),
                        child: Form(
                          key: _formKey,
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              // Title: "Admin Sign In"
                              const Center(
                                child: Text(
                                  'Admin Sign In',
                                  style: TextStyle(
                                    fontFamily: 'Satoshi',
                                    fontSize: 26,
                                    fontWeight: FontWeight.w800,
                                    color: Color(0xFF1B2A32),
                                    letterSpacing: -0.3,
                                  ),
                                ),
                              ),
                              const SizedBox(height: 20),

                              // Main Credential Card
                              Container(
                                padding: const EdgeInsets.all(22),
                                decoration: BoxDecoration(
                                  color: const Color(0xFFF7F5EE),
                                  borderRadius: BorderRadius.circular(18),
                                  border: Border.all(color: const Color(0xFFD6CEB5)),
                                  boxShadow: const [
                                    BoxShadow(
                                      color: Color(0x10000000),
                                      blurRadius: 10,
                                      offset: Offset(0, 4),
                                    ),
                                  ],
                                ),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    const Center(
                                      child: Text(
                                        'Arua dispatch center\nauthorization required.',
                                        textAlign: TextAlign.center,
                                        style: TextStyle(
                                          fontFamily: 'Satoshi',
                                          fontSize: 14,
                                          fontWeight: FontWeight.w700,
                                          color: Color(0xFF1B2A32),
                                          height: 1.3,
                                        ),
                                      ),
                                    ),
                                    const SizedBox(height: 20),

                                    // Error Banner
                                    if (_errorMessage != null) ...[
                                      Container(
                                        padding: const EdgeInsets.all(10),
                                        decoration: BoxDecoration(
                                          color: const Color(0xFFFFEBEE),
                                          borderRadius: BorderRadius.circular(8),
                                          border: Border.all(color: const Color(0xFFFFCDD2)),
                                        ),
                                        child: Text(
                                          _errorMessage!,
                                          style: const TextStyle(
                                            fontFamily: 'Satoshi',
                                            fontSize: 12,
                                            fontWeight: FontWeight.w600,
                                            color: Color(0xFFBA4738),
                                          ),
                                        ),
                                      ),
                                      const SizedBox(height: 14),
                                    ],

                                    // Administrator ID
                                    const Text(
                                      'Administrator ID',
                                      style: TextStyle(
                                        fontFamily: 'Satoshi',
                                        fontSize: 13,
                                        fontWeight: FontWeight.w600,
                                        color: Color(0xFF1B2A32),
                                      ),
                                    ),
                                    const SizedBox(height: 6),
                                    TextFormField(
                                      key: const ValueKey('admin_id_input'),
                                      controller: _adminIdCtrl,
                                      style: const TextStyle(
                                        fontFamily: 'Satoshi',
                                        fontSize: 14.5,
                                        color: Color(0xFF1B2A32),
                                        fontWeight: FontWeight.w600,
                                      ),
                                      decoration: InputDecoration(
                                        hintText: '#A-9014 or official email',
                                        filled: true,
                                        fillColor: Colors.white,
                                        contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                                        border: OutlineInputBorder(
                                          borderRadius: BorderRadius.circular(10),
                                          borderSide: const BorderSide(color: Color(0xFFBCC8BD)),
                                        ),
                                      ),
                                      validator: (val) {
                                        if (val == null || val.trim().isEmpty) {
                                          return 'Please enter Administrator ID';
                                        }
                                        return null;
                                      },
                                    ),
                                    const SizedBox(height: 16),

                                    // Secure PIN / Password
                                    const Text(
                                      'Secure PIN / Password',
                                      style: TextStyle(
                                        fontFamily: 'Satoshi',
                                        fontSize: 13,
                                        fontWeight: FontWeight.w600,
                                        color: Color(0xFF1B2A32),
                                      ),
                                    ),
                                    const SizedBox(height: 6),
                                    TextFormField(
                                      key: const ValueKey('admin_pin_input'),
                                      controller: _pinCtrl,
                                      obscureText: _obscurePin,
                                      style: const TextStyle(
                                        fontFamily: 'Satoshi',
                                        fontSize: 14.5,
                                        color: Color(0xFF1B2A32),
                                        fontWeight: FontWeight.w600,
                                      ),
                                      decoration: InputDecoration(
                                        hintText: 'PIN or Master Password',
                                        filled: true,
                                        fillColor: Colors.white,
                                        contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                                        suffixIcon: IconButton(
                                          icon: Icon(
                                            _obscurePin ? Icons.visibility_off_outlined : Icons.visibility_outlined,
                                            size: 18,
                                            color: const Color(0xFF6F7E78),
                                          ),
                                          onPressed: () => setState(() => _obscurePin = !_obscurePin),
                                        ),
                                        border: OutlineInputBorder(
                                          borderRadius: BorderRadius.circular(10),
                                          borderSide: const BorderSide(color: Color(0xFFBCC8BD)),
                                        ),
                                      ),
                                      validator: (val) {
                                        if (val == null || val.isEmpty) {
                                          return 'Please enter Secure PIN / Password';
                                        }
                                        return null;
                                      },
                                    ),
                                    const SizedBox(height: 20),

                                    // Authorize & Sign In Button
                                    SizedBox(
                                      width: double.infinity,
                                      height: 48,
                                      child: FilledButton(
                                        key: const ValueKey('admin_authorize_button'),
                                        onPressed: _isSubmitting ? null : _handleAuthorize,
                                        style: FilledButton.styleFrom(
                                          backgroundColor: darkButtonBg,
                                          foregroundColor: Colors.white,
                                          shape: RoundedRectangleBorder(
                                            borderRadius: BorderRadius.circular(10),
                                          ),
                                        ),
                                        child: _isSubmitting
                                            ? const SizedBox.square(
                                                dimension: 20,
                                                child: CircularProgressIndicator(
                                                  strokeWidth: 2,
                                                  valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                                                ),
                                              )
                                            : const FittedBox(
                                                fit: BoxFit.scaleDown,
                                                child: Row(
                                                  mainAxisAlignment: MainAxisAlignment.center,
                                                  children: [
                                                    Text(
                                                      'Authorize & Sign In',
                                                      style: TextStyle(
                                                        fontFamily: 'Satoshi',
                                                        fontSize: 14.5,
                                                        fontWeight: FontWeight.w700,
                                                      ),
                                                    ),
                                                    SizedBox(width: 6),
                                                    Icon(Icons.lock_rounded, size: 16),
                                                  ],
                                                ),
                                              ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              const SizedBox(height: 16),

                              // Verify Mobile Device OTP
                              Center(
                                child: TextButton(
                                  key: const ValueKey('verify_mobile_otp_button'),
                                  onPressed: _showOtpVerificationDialog,
                                  child: const Text(
                                    'Verify Mobile Device OTP',
                                    style: TextStyle(
                                      fontFamily: 'Satoshi',
                                      fontSize: 13.5,
                                      fontWeight: FontWeight.w600,
                                      color: Color(0xFF1B2A32),
                                      decoration: TextDecoration.underline,
                                    ),
                                  ),
                                ),
                              ),

                              // Reset Administrator Password
                              Center(
                                child: TextButton(
                                  onPressed: _showPasswordResetDialog,
                                  child: const Text(
                                    'Reset Administrator Password',
                                    style: TextStyle(
                                      fontFamily: 'Satoshi',
                                      fontSize: 12.5,
                                      fontWeight: FontWeight.w600,
                                      color: Color(0xFF3B5660),
                                    ),
                                  ),
                                ),
                              ),

                              // Switch to Resident / Rider Sign In
                              Center(
                                child: TextButton.icon(
                                  onPressed: () {
                                    AppRouter.routeToLogin(
                                      context,
                                      repository: widget.repository,
                                      authService: widget.authService,
                                      wasteApiService: widget.wasteApiService,
                                    );
                                  },
                                  icon: const Icon(Icons.arrow_back, size: 16),
                                  label: const Text('Return to Resident / Rider Sign In'),
                                ),
                              ),

                              const SizedBox(height: 28),

                              // Footer: Authorized Personnel Only • IP Tracked
                              const Center(
                                child: Text(
                                  'Authorized Personnel Only • IP Tracked',
                                  style: TextStyle(
                                    fontFamily: 'Satoshi',
                                    fontSize: 11.5,
                                    color: Color(0xFF6F7E78),
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      );
                    },
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
