import 'package:flutter/material.dart';

import '../../core/services/auth_service.dart';
import '../../domain/enums/role.dart';

class DemoAccount {
  const DemoAccount({required this.email, required this.password});

  final String email;
  final String password;
}

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
  static const Map<AppRole, DemoAccount> demoAccounts = {
    AppRole.resident: DemoAccount(
      email: 'resident@ecoroute.demo',
      password: 'demo123',
    ),
    AppRole.rider: DemoAccount(
      email: 'rider@ecoroute.demo',
      password: 'demo123',
    ),
    AppRole.admin: DemoAccount(
      email: 'admin@ecoroute.demo',
      password: 'demo123',
    ),
  };

  late bool _createAccount;
  bool _obscurePassword = true;
  bool _obscureConfirmPassword = true;
  bool _isSubmitting = false;
  AppRole _selectedRole = AppRole.resident;
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
    if (_createAccount) {
      _email.clear();
      _password.clear();
    } else {
      _applyDemoAccount();
    }
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

  void _applyDemoAccount() {
    final account = demoAccounts[_selectedRole];
    if (account == null) return;
    _email.text = account.email;
    _password.text = account.password;
  }

  void _toggleAccountMode() {
    setState(() {
      _createAccount = !_createAccount;
      _errorMessage = null;
      if (_createAccount) {
        if (_email.text.endsWith('@ecoroute.demo')) {
          _email.clear();
          _password.clear();
        }
      } else {
        _applyDemoAccount();
      }
    });
  }

  Future<void> _submit() async {
    if (_isSubmitting || !_formKey.currentState!.validate()) return;
    setState(() {
      _isSubmitting = true;
      _errorMessage = null;
    });

    var authenticatedRole = _selectedRole;
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
            role: _selectedRole,
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
              _errorMessage = 'That email and password combination was not found.';
            });
            return;
          }
          authenticatedRole = user.role;

          if (!mounted) return;
          Navigator.of(context).pop();
          widget.onAuthenticated(authenticatedRole);
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Signed in as ${user.fullName} (${user.role.label}).'),
              backgroundColor: const Color(0xFF2E7D32),
            ),
          );
          return;
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
    final colors = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;

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
                          : 'Welcome back',
                      subtitle: _createAccount
                          ? 'Sign up for instant on-demand waste collection & recycling rewards in Arua.'
                          : 'Sign in to manage waste collections, tricycle routes, and approvals.',
                      onClose: () => Navigator.of(context).maybePop(),
                    ),
                    const SizedBox(height: 16),
                    if (_errorMessage != null) ...[
                      _AuthError(message: _errorMessage!),
                      const SizedBox(height: 14),
                    ],
                    Text(
                      _createAccount ? 'Register as' : 'Sign in as',
                      style: Theme.of(context).textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.w700,
                        color: const Color(0xFF2E7D32),
                      ),
                    ),
                    const SizedBox(height: 8),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: AppRole.values
                          .where((role) => role != AppRole.guest)
                          .map(
                            (role) => ChoiceChip(
                              avatar: Icon(
                                _roleIcon(role),
                                size: 16,
                                color: _selectedRole == role
                                    ? Colors.white
                                    : const Color(0xFF2E7D32),
                              ),
                              label: Text(role.label),
                              selected: _selectedRole == role,
                              onSelected: (_) {
                                setState(() => _selectedRole = role);
                                if (!_createAccount) {
                                  _applyDemoAccount();
                                }
                              },
                            ),
                          )
                          .toList(),
                    ),
                    const SizedBox(height: 14),

                    // Signup exclusive fields
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
                        hintText: 'Use at least 6 characters',
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
                          ? 'Use at least 6 characters'
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

                    // Submit Action Button
                    SizedBox(
                      height: 50,
                      child: FilledButton(
                        onPressed: _isSubmitting ? null : _submit,
                        child: _isSubmitting
                            ? const SizedBox.square(
                                dimension: 20,
                                child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                              )
                            : _ResponsiveButtonLabel(
                                _createAccount ? 'Create account' : 'Sign in',
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
                              ? 'Already have an account? Sign in'
                              : 'New to EcoRoute? Create an account',
                        ),
                      ),
                    ),

                    if (!_createAccount) ...[
                      Divider(
                        height: 12,
                        color: isDark
                            ? colors.outlineVariant
                            : colors.surfaceContainerHighest,
                      ),
                      const SizedBox(height: 6),
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Icon(
                            Icons.info_outline_rounded,
                            size: 16,
                            color: colors.primary,
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              'Demo access: resident@ecoroute.demo • rider@ecoroute.demo • admin@ecoroute.demo',
                              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                color: colors.onSurfaceVariant,
                                fontSize: 11,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  IconData _roleIcon(AppRole role) => switch (role) {
    AppRole.resident => Icons.home_outlined,
    AppRole.rider => Icons.two_wheeler_outlined,
    AppRole.admin => Icons.admin_panel_settings_outlined,
    AppRole.guest => Icons.person_outline_rounded,
  };
}

class _ResponsiveButtonLabel extends StatelessWidget {
  const _ResponsiveButtonLabel(this.text);

  final String text;

  @override
  Widget build(BuildContext context) {
    return FittedBox(
      fit: BoxFit.scaleDown,
      child: Text(text, maxLines: 1, overflow: TextOverflow.ellipsis),
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
    final colors = Theme.of(context).colorScheme;

    return Container(
      padding: const EdgeInsets.fromLTRB(16, 14, 10, 14),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [colors.primary, const Color(0xFF174A2B)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(18),
      ),
      child: Row(
        children: [
          Container(
            width: 42,
            height: 42,
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.16),
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Icon(Icons.eco_rounded, color: Colors.white, size: 24),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    color: Colors.white,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  subtitle,
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: Colors.white.withValues(alpha: 0.88),
                    fontSize: 11,
                  ),
                ),
              ],
            ),
          ),
          IconButton(
            onPressed: onClose,
            tooltip: 'Close',
            icon: const Icon(Icons.close_rounded, color: Colors.white, size: 20),
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
    final colors = Theme.of(context).colorScheme;

    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: colors.errorContainer,
        borderRadius: BorderRadius.circular(10),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(Icons.error_outline_rounded, color: colors.onErrorContainer, size: 18),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              message,
              style: TextStyle(color: colors.onErrorContainer, fontSize: 12, fontWeight: FontWeight.w600),
            ),
          ),
        ],
      ),
    );
  }
}
