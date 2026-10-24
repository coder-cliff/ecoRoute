import 'package:flutter/material.dart';

import '../../core/services/auth_service.dart';
import '../../domain/enums/role.dart';

class DemoAccount {
  const DemoAccount({required this.email, required this.password});

  final String email;
  final String password;
}

class AuthSheet extends StatefulWidget {
  const AuthSheet({required this.onAuthenticated, this.authService, super.key});

  final void Function(AppRole role) onAuthenticated;
  final AuthService? authService;

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

  bool _createAccount = false;
  bool _obscurePassword = true;
  bool _isSubmitting = false;
  AppRole _selectedRole = AppRole.resident;
  String? _errorMessage;
  final _formKey = GlobalKey<FormState>();
  final _fullName = TextEditingController();
  final _email = TextEditingController();
  final _password = TextEditingController();

  @override
  void initState() {
    super.initState();
    _applyDemoAccount();
  }

  @override
  void dispose() {
    _fullName.dispose();
    _email.dispose();
    _password.dispose();
    super.dispose();
  }

  void _applyDemoAccount() {
    final account = demoAccounts[_selectedRole];
    if (account == null) return;
    _email.text = account.email;
    _password.text = account.password;
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
            fullName: _fullName.text.trim(),
            email: _email.text.trim(),
            phone: '+256 772 000 000',
            password: _password.text,
            role: _selectedRole,
          );
          authenticatedRole = user.role;
        } else {
          final user = await authService.login(
            email: _email.text.trim(),
            password: _password.text,
          );
          if (!mounted) return;
          if (user == null) {
            setState(() {
              _isSubmitting = false;
              _errorMessage =
                  'That email and password combination was not found.';
            });
            return;
          }
          authenticatedRole = user.role;
        }
      }
    } on Exception catch (error) {
      if (!mounted) return;
      setState(() {
        _isSubmitting = false;
        _errorMessage = 'We could not complete sign-in: $error';
      });
      return;
    }

    if (!mounted) return;
    Navigator.of(context).pop();
    widget.onAuthenticated(authenticatedRole);
  }

  void _toggleAccountMode() {
    setState(() {
      _createAccount = !_createAccount;
      _errorMessage = null;
      _fullName.clear();
      if (_createAccount) {
        _selectedRole = AppRole.resident;
      } else {
        _applyDemoAccount();
      }
    });
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
                          ? 'Join the cleaner route'
                          : 'Welcome back',
                      subtitle: _createAccount
                          ? 'Create your EcoRoute account to get started.'
                          : 'Sign in to manage your collections and routes.',
                      onClose: () => Navigator.of(context).maybePop(),
                    ),
                    const SizedBox(height: 20),
                    Text(
                      _createAccount ? 'I am joining as' : 'I am signing in as',
                      style: Theme.of(context).textTheme.labelLarge
                          ?.copyWith(fontWeight: FontWeight.w700),
                    ),
                    const SizedBox(height: 10),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: AppRole.values
                          .where(
                            (role) =>
                                role != AppRole.guest &&
                                (!_createAccount || role == AppRole.resident),
                          )
                          .map(
                            (role) => ChoiceChip(
                              avatar: Icon(
                                _roleIcon(role),
                                size: 17,
                                color: _selectedRole == role
                                    ? colors.onPrimaryContainer
                                    : colors.onSurfaceVariant,
                              ),
                              label: Text(role.label),
                              selected: _selectedRole == role,
                              onSelected: _isSubmitting
                                  ? null
                                  : (_) {
                                      setState(() {
                                        _selectedRole = role;
                                        _errorMessage = null;
                                      });
                                      if (!_createAccount) _applyDemoAccount();
                                    },
                            ),
                          )
                          .toList(),
                    ),
                    const SizedBox(height: 16),
                    if (_createAccount) ...[
                      TextFormField(
                        controller: _fullName,
                        textCapitalization: TextCapitalization.words,
                        textInputAction: TextInputAction.next,
                        autofillHints: const [AutofillHints.name],
                        decoration: const InputDecoration(
                          labelText: 'Full name',
                          prefixIcon: Icon(Icons.person_outline_rounded),
                        ),
                        validator: (value) =>
                            value == null || value.trim().isEmpty
                            ? 'Enter your name'
                            : null,
                      ),
                      const SizedBox(height: 12),
                    ],
                    TextFormField(
                      controller: _email,
                      keyboardType: TextInputType.emailAddress,
                      textInputAction: TextInputAction.next,
                      autofillHints: const [AutofillHints.username],
                      autocorrect: false,
                      decoration: const InputDecoration(
                        labelText: 'Email address',
                        prefixIcon: Icon(Icons.alternate_email_rounded),
                      ),
                      validator: (value) {
                        final email = value?.trim() ?? '';
                        return RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$')
                                .hasMatch(email)
                            ? null
                            : 'Enter a valid email address';
                      },
                    ),
                    const SizedBox(height: 12),
                    TextFormField(
                      controller: _password,
                      obscureText: _obscurePassword,
                      textInputAction: TextInputAction.done,
                      autofillHints: [
                        _createAccount
                            ? AutofillHints.newPassword
                            : AutofillHints.password,
                      ],
                      onFieldSubmitted: (_) => _submit(),
                      decoration: InputDecoration(
                        labelText: 'Password',
                        prefixIcon: const Icon(Icons.lock_outline_rounded),
                        suffixIcon: IconButton(
                          tooltip: _obscurePassword
                              ? 'Show password'
                              : 'Hide password',
                          onPressed: () => setState(
                            () => _obscurePassword = !_obscurePassword,
                          ),
                          icon: Icon(
                            _obscurePassword
                                ? Icons.visibility_outlined
                                : Icons.visibility_off_outlined,
                          ),
                        ),
                      ),
                      validator: (value) => value == null || value.length < 6
                          ? 'Use at least 6 characters'
                          : null,
                    ),
                    if (_errorMessage != null) ...[
                      const SizedBox(height: 12),
                      _AuthError(message: _errorMessage!),
                    ],
                    const SizedBox(height: 18),
                    SizedBox(
                      height: 52,
                      child: FilledButton(
                        onPressed: _isSubmitting ? null : _submit,
                        child: _isSubmitting
                            ? const SizedBox.square(
                                dimension: 22,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2.4,
                                ),
                              )
                            : Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(
                                    _createAccount
                                        ? Icons.person_add_alt_1_rounded
                                        : Icons.login_rounded,
                                  ),
                                  const SizedBox(width: 9),
                                  Text(
                                    _createAccount
                                        ? 'Create account'
                                        : 'Sign in',
                                  ),
                                ],
                              ),
                      ),
                    ),
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
                      const SizedBox(height: 10),
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Icon(
                            Icons.info_outline_rounded,
                            size: 18,
                            color: colors.primary,
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              'Demo access is available for residents, riders, and admins. Use the prefilled demo credentials.',
                              style: Theme.of(context).textTheme.bodySmall
                                  ?.copyWith(color: colors.onSurfaceVariant),
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
    AppRole.resident => Icons.home_work_outlined,
    AppRole.rider => Icons.delivery_dining_rounded,
    AppRole.admin => Icons.admin_panel_settings_outlined,
    AppRole.guest => Icons.person_outline_rounded,
  };
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
      padding: const EdgeInsets.fromLTRB(18, 16, 12, 18),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [colors.primary, const Color(0xFF174A2B)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(22),
      ),
      child: Row(
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.16),
              borderRadius: BorderRadius.circular(15),
            ),
            child: const Icon(Icons.eco_rounded, color: Colors.white, size: 27),
          ),
          const SizedBox(width: 13),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    color: Colors.white,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  subtitle,
                  style: Theme.of(context).textTheme.bodySmall
                      ?.copyWith(color: Colors.white.withValues(alpha: 0.86)),
                ),
              ],
            ),
          ),
          IconButton(
            onPressed: onClose,
            tooltip: 'Close',
            icon: const Icon(Icons.close_rounded, color: Colors.white),
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
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: colors.errorContainer,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(Icons.error_outline_rounded, color: colors.onErrorContainer),
          const SizedBox(width: 9),
          Expanded(
            child: Text(
              message,
              style: TextStyle(color: colors.onErrorContainer),
            ),
          ),
        ],
      ),
    );
  }
}
