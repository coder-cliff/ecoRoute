import 'package:flutter/material.dart';

import '../../core/services/auth_service.dart';
import '../../domain/entities/app_user.dart';
import '../../domain/enums/role.dart';

/* Placeholder kept as the real auth sheet is in other files. */
class AuthSheet extends StatefulWidget {
  const AuthSheet({
    required this.authService,
    required this.onAuthenticated,
    this.initialCreateAccount = false,
    super.key,
  });

  final AuthService? authService;
  final void Function(AppRole role) onAuthenticated;
  final bool initialCreateAccount;

  @override
  State<AuthSheet> createState() => _AuthSheetState();
}

class _AuthSheetState extends State<AuthSheet> {
  late bool _createAccount;
  bool _obscurePassword = true;
  bool _isSubmitting = false;
  String? _errorMessage;

  final _formKey = GlobalKey<FormState>();
  final _fullName = TextEditingController();
  final _phone = TextEditingController();
  final _address = TextEditingController();
  final _email = TextEditingController();
  final _password = TextEditingController();

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

    try {
      if (widget.authService == null) {
        throw StateError('Authentication is not configured.');
      }

      if (_createAccount) {
        final user = await widget.authService!.register(
          fullName: _fullName.text.trim().isEmpty
              ? 'EcoRoute Resident'
              : _fullName.text.trim(),
          email: _email.text.trim(),
          phone: _phone.text.trim(),
          password: _password.text,
          role: AppRole.resident,
          address: _address.text.trim(),
        );
        if (!mounted) return;
        Navigator.of(context).pop();
        widget.onAuthenticated(user.role);
        return;
      }

      final user = await widget.authService!.login(
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

      Navigator.of(context).pop();
      widget.onAuthenticated(user.role);
    } on StateError catch (error) {
      if (!mounted) return;
      setState(() {
        _isSubmitting = false;
        _errorMessage = error.message;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _isSubmitting = false;
        _errorMessage = 'Could not sign in. Please try again.';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Form(
        key: _formKey,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            if (_errorMessage != null)
              Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: Text(
                  _errorMessage!,
                  style: const TextStyle(color: Colors.red),
                ),
              ),
            if (_createAccount)
              TextFormField(
                controller: _fullName,
                decoration: const InputDecoration(labelText: 'Full name'),
                validator: (value) =>
                    (value == null || value.trim().isEmpty) ? 'Please enter your full name.' : null,
              ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _email,
              keyboardType: TextInputType.emailAddress,
              decoration: const InputDecoration(labelText: 'Email address'),
              validator: (value) =>
                  (value == null || value.trim().isEmpty) ? 'Please enter an email address.' : null,
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _password,
              obscureText: _obscurePassword,
              decoration: InputDecoration(
                labelText: 'Password',
                suffixIcon: IconButton(
                  onPressed: () => setState(() => _obscurePassword = !_obscurePassword),
                  icon: Icon(_obscurePassword ? Icons.visibility : Icons.visibility_off),
                ),
              ),
              validator: (value) =>
                  (value == null || value.isEmpty) ? 'Please enter a password.' : null,
            ),
            if (_createAccount) ...[
              const SizedBox(height: 12),
              TextFormField(
                controller: _phone,
                keyboardType: TextInputType.phone,
                decoration: const InputDecoration(labelText: 'Phone number'),
                validator: (value) =>
                    (value == null || value.trim().isEmpty) ? 'Please enter a phone number.' : null,
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _address,
                decoration: const InputDecoration(labelText: 'Address (optional)'),
              ),
            ],
            const SizedBox(height: 16),
            FilledButton(
              onPressed: _isSubmitting ? null : _submit,
              child: Text(_isSubmitting ? 'Please wait...' : (_createAccount ? 'Create account' : 'Login')),
            ),
            TextButton(
              onPressed: _toggleAccountMode,
              child: Text(
                _createAccount ? 'Already have an account? Login' : 'Need an account? Create one',
              ),
            ),
          ],
        ),
      ),
    );
  }
}
