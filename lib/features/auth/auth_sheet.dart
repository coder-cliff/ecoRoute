import 'package:flutter/material.dart';

import '../../domain/enums/role.dart';

class DemoAccount {
  const DemoAccount({required this.email, required this.password});

  final String email;
  final String password;
}

class AuthSheet extends StatefulWidget {
  const AuthSheet({required this.onAuthenticated, super.key});

  final void Function(AppRole role) onAuthenticated;

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
  AppRole _selectedRole = AppRole.resident;
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

  void _submit() {
    if (_formKey.currentState!.validate()) {
      Navigator.pop(context);
      widget.onAuthenticated(_selectedRole);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(
        left: 20,
        right: 20,
        bottom: MediaQuery.viewInsetsOf(context).bottom + 20,
      ),
      child: Form(
        key: _formKey,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              _createAccount ? 'Create your EcoRoute account' : 'Welcome back',
              style: const TextStyle(
                fontSize: 23,
                fontWeight: FontWeight.w800,
                color: Color(0xFF183B20),
              ),
            ),
            const SizedBox(height: 6),
            Text(
              _createAccount
                  ? 'Create an account to request waste collection.'
                  : 'Sign in to request a collection for your waste.',
            ),
            const SizedBox(height: 18),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: AppRole.values
                  .where((role) => role != AppRole.guest)
                  .map(
                    (role) => ChoiceChip(
                      label: Text(role.label),
                      selected: _selectedRole == role,
                      onSelected: (_) {
                        setState(() => _selectedRole = role);
                        _applyDemoAccount();
                      },
                    ),
                  )
                  .toList(),
            ),
            const SizedBox(height: 12),
            Text(
              'Demo access: resident@ecoroute.demo • rider@ecoroute.demo • admin@ecoroute.demo',
              style: const TextStyle(fontSize: 12, color: Color(0xFF647568)),
            ),
            const SizedBox(height: 12),
            if (_createAccount) ...[
              TextFormField(
                controller: _fullName,
                decoration: const InputDecoration(labelText: 'Full name'),
                validator: (value) => value == null || value.trim().isEmpty
                    ? 'Enter your name'
                    : null,
              ),
              const SizedBox(height: 12),
            ],
            TextFormField(
              controller: _email,
              keyboardType: TextInputType.emailAddress,
              decoration: const InputDecoration(labelText: 'Email address'),
              validator: (value) => value == null || !value.contains('@')
                  ? 'Enter a valid email'
                  : null,
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _password,
              obscureText: true,
              decoration: const InputDecoration(labelText: 'Password'),
              validator: (value) => value == null || value.length < 6
                  ? 'Use at least 6 characters'
                  : null,
            ),
            const SizedBox(height: 18),
            SizedBox(
              width: double.infinity,
              height: 50,
              child: FilledButton(
                onPressed: _submit,
                child: _ResponsiveButtonLabel(
                  _createAccount ? 'Create account' : 'Sign in',
                ),
              ),
            ),
            TextButton(
              onPressed: () => setState(() => _createAccount = !_createAccount),
              child: _ResponsiveButtonLabel(
                _createAccount
                    ? 'Already have an account? Sign in'
                    : 'New to EcoRoute? Create an account',
              ),
            ),
          ],
        ),
      ),
    );
  }
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
