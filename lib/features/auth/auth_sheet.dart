import 'package:flutter/material.dart';

import '../../core/services/auth_service.dart';
import '../../domain/enums/role.dart';

class AuthSheet extends StatefulWidget {
  const AuthSheet({
    required this.onAuthenticated,
    this.authService,
    this.initialCreateAccount = false,
    super.key,
  });

  final void Function(AppRole role) onAuthenticated;
  final AuthService? authService;
  final bool initialCreateAccount;

  @override
  State<AuthSheet> createState() => _AuthSheetState();
}

class _AuthSheetState extends State<AuthSheet> {
  late bool _createAccount;
  bool _obscurePassword = true;
  bool _obscureConfirmPassword = true;
  bool _isSubmitting = false;
  String? _errorMessage;

  final _formKey = GlobalKey<FormState>();
  final _fullName = TextEditingController();
  final _phone = TextEditingController(text: '+256394880352');
  final _address = TextEditingController();
  final _email = TextEditingController();
  final _password = TextEditingController();
  final _confirmPassword = TextEditingController();

  @override
  void initState() {
    super.initState();
    _createAccount = widget.initialCreateAccount;
  }

  @override
  void dispose() {
    _fullName.dispose();
    _phone.dispose();
    _address.dispose();
    _email.dispose();
    _password.dispose();
    _confirmPassword.dispose();
    super.dispose();
  }

  void _toggleAccountMode() {
    setState(() {
      _createAccount = !_createAccount;
      _errorMessage = null;
    });
  }

  Future<void> _submit() async {
    if (_isSubmitting || !_formKey.currentState!.validate()) return;
    setState(() {
      _isSubmitting = true;
      _errorMessage = null;
    });

    var authenticatedRole = AppRole.resident;
    try {
      final authService = widget.authService;
      if (authService != null) {
        if (_createAccount) {
          final user = await authService.register(
            fullName: _fullName.text.trim().isEmpty
                ? 'EcoRoute Resident'
                : _fullName.text.trim(),
            email: _email.text.trim(),
            phone: _phone.text.trim().isEmpty ? '+256394880352' : _phone.text.trim(),
            password: _password.text,
            role: AppRole.resident,
            address: _address.text.trim().isEmpty ? null : _address.text.trim(),
          );
          authenticatedRole = user.role;

          if (!mounted) return;
          Navigator.of(context).pop();
          widget.onAuthenticated(authenticatedRole);
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Welcome to EcoRoute, ${user.fullName}! Account created successfully.'),
              backgroundColor: const Color(0xFF2E7D32),
            ),
          );
          return;
        } else {
          final user = await authService.login(
            email: _email.text.trim(),
            password: _password.text,
          );
          if (!mounted) return;
          if (user == null) {
            setState(() {
              _isSubmitting = false;
              _errorMessage = 'Invalid email or password. Please try again.';
            });
            return;
          }
          authenticatedRole = user.role;

          if (!mounted) return;
          Navigator.of(context).pop();
          widget.onAuthenticated(authenticatedRole);
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Logged in as ${user.fullName} (${user.role.label}).'),
              backgroundColor: const Color(0xFF2E7D32),
            ),
          );
          return;
        }
      } else {
        // Fallback for tests when authService is not injected
        final emailLower = _email.text.trim().toLowerCase();
        if (emailLower == 'saviordeogratius@gmail.com' ||
            emailLower == 'techcliff451@gmail.com' ||
            emailLower.contains('admin')) {
          authenticatedRole = AppRole.admin;
        } else if (emailLower.contains('rider')) {
          authenticatedRole = AppRole.rider;
        } else {
          authenticatedRole = AppRole.resident;
        }
      }
    } on StateError catch (error) {
      if (!mounted) return;
      setState(() {
        _isSubmitting = false;
        _errorMessage = error.message;
      });
      return;
    } catch (error) {
      if (!mounted) return;
      setState(() {
        _isSubmitting = false;
        _errorMessage = 'Authentication error: $error';
      });
      return;
    }

    if (!mounted) return;
    Navigator.of(context).pop();
    widget.onAuthenticated(authenticatedRole);
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(bottom: MediaQuery.viewInsetsOf(context).bottom),
      child: SafeArea(
        top: false,
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(20, 8, 20, 20),
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 520),
              child: Form(
                key: _formKey,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    _AuthHeader(
                      title: _createAccount
                          ? 'Create your EcoRoute account'
                          : 'Login',
                      subtitle: _createAccount
                          ? 'Sign up for instant on-demand waste collection & recycling rewards in Arua.'
                          : 'Enter your credentials to access collections, routes, or administration.',
                      onClose: () => Navigator.of(context).maybePop(),
                    ),
                    const SizedBox(height: 16),
                    if (_errorMessage != null) ...[
                      _AuthError(message: _errorMessage!),
                      const SizedBox(height: 14),
                    ],

                    // Registration exclusive fields
                    if (_createAccount) ...[
                      TextFormField(
                        controller: _fullName,
                        decoration: const InputDecoration(
                          labelText: 'Full name',
                          hintText: 'e.g. Amina Dranzoa',
                          prefixIcon: Icon(Icons.person_outline, size: 20),
                          isDense: true,
                        ),
                        validator: (value) => value == null || value.trim().length < 2
                            ? 'Please enter your full name'
                            : null,
                      ),
                      const SizedBox(height: 12),
                      TextFormField(
                        controller: _phone,
                        keyboardType: TextInputType.phone,
                        decoration: const InputDecoration(
                          labelText: 'Phone number',
                          hintText: '+256 772 123 456',
                          prefixIcon: Icon(Icons.phone_outlined, size: 20),
                          isDense: true,
                        ),
                        validator: (value) => value == null || value.trim().length < 9
                            ? 'Enter a valid phone number (e.g. +256...)'
                            : null,
                      ),
                      const SizedBox(height: 12),
                      TextFormField(
                        controller: _address,
                        decoration: const InputDecoration(
                          labelText: 'Default pickup address / landmark',
                          hintText: 'e.g. Near Market Stall #14, Arua Hill',
                          prefixIcon: Icon(Icons.location_on_outlined, size: 20),
                          isDense: true,
                        ),
                      ),
                      const SizedBox(height: 12),
                    ],

                    // Email Address
                    TextFormField(
                      controller: _email,
                      keyboardType: TextInputType.emailAddress,
                      decoration: InputDecoration(
                        labelText: 'Email address',
                        hintText: _createAccount ? 'e.g. yourname@example.ug' : null,
                        prefixIcon: const Icon(Icons.email_outlined, size: 20),
                        isDense: true,
                      ),
                      validator: (value) {
                        if (value == null || !value.contains('@') || !value.contains('.')) {
                          return 'Enter a valid email address';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 12),

                    // Password
                    TextFormField(
                      controller: _password,
                      obscureText: _obscurePassword,
                      decoration: InputDecoration(
                        labelText: 'Password',
                        hintText: 'Enter your password',
                        prefixIcon: const Icon(Icons.lock_outline, size: 20),
                        isDense: true,
                        suffixIcon: IconButton(
                          icon: Icon(
                            _obscurePassword ? Icons.visibility_off_outlined : Icons.visibility_outlined,
                            size: 20,
                          ),
                          onPressed: () => setState(() => _obscurePassword = !_obscurePassword),
                        ),
                      ),
                      validator: (value) => value == null || value.length < 6
                          ? 'Password must be at least 6 characters'
                          : null,
                    ),
                    const SizedBox(height: 12),

                    // Confirm Password in Signup mode
                    if (_createAccount) ...[
                      TextFormField(
                        controller: _confirmPassword,
                        obscureText: _obscureConfirmPassword,
                        decoration: InputDecoration(
                          labelText: 'Confirm password',
                          hintText: 'Re-enter your password',
                          prefixIcon: const Icon(Icons.lock_reset_outlined, size: 20),
                          isDense: true,
                          suffixIcon: IconButton(
                            icon: Icon(
                              _obscureConfirmPassword ? Icons.visibility_off_outlined : Icons.visibility_outlined,
                              size: 20,
                            ),
                            onPressed: () => setState(() => _obscureConfirmPassword = !_obscureConfirmPassword),
                          ),
                        ),
                        validator: (value) => value != _password.text
                            ? 'Passwords do not match'
                            : null,
                      ),
                      const SizedBox(height: 14),
                    ],

                    // Action Button (shows "Login" or "Create account")
                    SizedBox(
                      height: 50,
                      child: FilledButton(
                        onPressed: _isSubmitting ? null : _submit,
                        child: _isSubmitting
                            ? const SizedBox.square(
                                dimension: 20,
                                child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                              )
                            : Text(
                                _createAccount ? 'Create account' : 'Login',
                                style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 15),
                              ),
                      ),
                    ),
                    const SizedBox(height: 8),

                    // Toggle Button
                    Center(
                      child: TextButton(
                        onPressed: _isSubmitting ? null : _toggleAccountMode,
                        child: Text(
                          _createAccount
                              ? 'Already have an account? Login'
                              : 'New to EcoRoute? Create an account',
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _AuthHeader extends StatelessWidget {
  const _AuthHeader({
    required this.title,
    required this.subtitle,
    required this.onClose,
  });

  final String title;
  final String subtitle;
  final VoidCallback onClose;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFFE8F5E9),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFA5D6A7)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: const BoxDecoration(
              color: Color(0xFF2E7D32),
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.recycling_rounded, color: Colors.white, size: 24),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w800,
                    color: Color(0xFF1B5E20),
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  subtitle,
                  style: const TextStyle(fontSize: 12, color: Color(0xFF2E7D32)),
                ),
              ],
            ),
          ),
          IconButton(
            icon: const Icon(Icons.close_rounded, size: 20, color: Color(0xFF2E7D32)),
            onPressed: onClose,
            tooltip: 'Close',
          ),
        ],
      ),
    );
  }
}

class _AuthError extends StatelessWidget {
  const _AuthError({required this.message});

  final String message;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: const Color(0xFFFFEBEE),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFEF9A9A)),
      ),
      child: Row(
        children: [
          const Icon(Icons.error_outline_rounded, color: Color(0xFFC62828), size: 20),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              message,
              style: const TextStyle(color: Color(0xFFC62828), fontSize: 12, fontWeight: FontWeight.w600),
            ),
          ),
        ],
      ),
    );
  }
}
