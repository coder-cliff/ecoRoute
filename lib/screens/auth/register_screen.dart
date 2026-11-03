import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';
import '../../models/user_model.dart';
import '../../providers/auth_provider.dart';
import '../../theme/app_theme.dart';
import '../../widgets/user_avatar.dart';

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final _formKey = GlobalKey<FormState>();

  final _nameController = TextEditingController();
  final _phoneController = TextEditingController();
  final _emailController = TextEditingController();
  final _addressController = TextEditingController();
  final _vehicleController = TextEditingController();

  UserRole _selectedRole = UserRole.citizen;
  String _avatarUrl = AppUser.standardAvatarPresets[0]['id']!;
  bool _isRegistering = false;
  final ImagePicker _picker = ImagePicker();

  @override
  void dispose() {
    _nameController.dispose();
    _phoneController.dispose();
    _emailController.dispose();
    _addressController.dispose();
    _vehicleController.dispose();
    super.dispose();
  }

  Color _getRoleColor(UserRole role) {
    switch (role) {
      case UserRole.citizen:
        return AppTheme.primaryGreen;
      case UserRole.rider:
        return const Color(0xFF0D6EFD);
      case UserRole.admin:
        return const Color(0xFF6F42C1);
    }
  }

  Future<void> _pickPhoto() async {
    try {
      final photo = await _picker.pickImage(
        source: ImageSource.gallery,
        maxWidth: 512,
        maxHeight: 512,
        imageQuality: 85,
      );
      if (photo != null) {
        setState(() {
          _avatarUrl = photo.path;
        });
      }
    } catch (e) {
      debugPrint('Image picker error: $e');
    }
  }

  void _showAvatarPresetPicker() {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Select Profile Display Picture',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),
            SizedBox(
              height: 100,
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                itemCount: AppUser.standardAvatarPresets.length,
                separatorBuilder: (_, __) => const SizedBox(width: 12),
                itemBuilder: (context, index) {
                  final preset = AppUser.standardAvatarPresets[index];
                  final isSelected = _avatarUrl == preset['id'];

                  return InkWell(
                    onTap: () {
                      setState(() {
                        _avatarUrl = preset['id']!;
                      });
                      Navigator.pop(ctx);
                    },
                    child: Column(
                      children: [
                        UserAvatar(
                          avatarUrl: preset['id'],
                          name: preset['label'],
                          role: _selectedRole,
                          radius: 28,
                        ),
                        const SizedBox(height: 4),
                        Text(
                          preset['label']!.split(' ')[0],
                          style: TextStyle(
                            fontSize: 10,
                            fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                          ),
                        ),
                      ],
                    ),
                  );
                },
              ),
            ),
            const SizedBox(height: 12),
            SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                onPressed: () {
                  Navigator.pop(ctx);
                  _pickPhoto();
                },
                icon: const Icon(Icons.photo_library_rounded),
                label: const Text('Choose From Phone Gallery'),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isRegistering = true;
    });

    try {
      final auth = Provider.of<AuthProvider>(context, listen: false);
      await auth.registerUser(
        name: _nameController.text.trim(),
        phone: _phoneController.text.trim(),
        email: _emailController.text.trim(),
        role: _selectedRole,
        avatarUrl: _avatarUrl,
        address: _addressController.text.trim(),
        vehicleInfo: _vehicleController.text.trim().isNotEmpty
            ? _vehicleController.text.trim()
            : null,
      );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Account created! Welcome, ${_nameController.text}.'),
            backgroundColor: AppTheme.primaryGreen,
          ),
        );
        Navigator.pop(context);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Registration failed: $e'),
            backgroundColor: Colors.redAccent,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isRegistering = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final roleColor = _getRoleColor(_selectedRole);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Create New Account'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20.0),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // DP Selection
              Center(
                child: Column(
                  children: [
                    UserAvatar(
                      avatarUrl: _avatarUrl,
                      name: _nameController.text.isNotEmpty ? _nameController.text : 'New User',
                      role: _selectedRole,
                      radius: 44,
                      showRoleBadge: true,
                      isEditable: true,
                      onTap: _showAvatarPresetPicker,
                    ),
                    const SizedBox(height: 8),
                    TextButton.icon(
                      onPressed: _showAvatarPresetPicker,
                      icon: const Icon(Icons.add_a_photo_rounded, size: 16),
                      label: const Text('Select Profile DP'),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),

              // Role Selector
              const Text(
                'Select Your Role:',
                style: TextStyle(fontWeight: FontWeight.w700, fontSize: 14),
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  _roleChoice(UserRole.citizen, 'Resident', Icons.home_rounded, AppTheme.primaryGreen),
                  const SizedBox(width: 8),
                  _roleChoice(UserRole.rider, 'Rider', Icons.two_wheeler_rounded, const Color(0xFF0D6EFD)),
                  const SizedBox(width: 8),
                  _roleChoice(UserRole.admin, 'Admin', Icons.admin_panel_settings_rounded, const Color(0xFF6F42C1)),
                ],
              ),
              const SizedBox(height: 20),

              // Input Fields
              TextFormField(
                controller: _nameController,
                decoration: const InputDecoration(
                  labelText: 'Full Name',
                  prefixIcon: Icon(Icons.person_outline_rounded),
                ),
                validator: (v) =>
                    (v == null || v.trim().isEmpty) ? 'Name is required' : null,
              ),
              const SizedBox(height: 14),

              TextFormField(
                controller: _phoneController,
                keyboardType: TextInputType.phone,
                decoration: const InputDecoration(
                  labelText: 'Phone Number',
                  prefixIcon: Icon(Icons.phone_outlined),
                ),
                validator: (v) =>
                    (v == null || v.trim().isEmpty) ? 'Phone number is required' : null,
              ),
              const SizedBox(height: 14),

              TextFormField(
                controller: _emailController,
                keyboardType: TextInputType.emailAddress,
                decoration: const InputDecoration(
                  labelText: 'Email Address',
                  prefixIcon: Icon(Icons.email_outlined),
                ),
                validator: (v) =>
                    (v == null || !v.contains('@')) ? 'Valid email required' : null,
              ),
              const SizedBox(height: 14),

              TextFormField(
                controller: _addressController,
                decoration: InputDecoration(
                  labelText: _selectedRole == UserRole.rider
                      ? 'Service Hub / Depot Area'
                      : 'Home / Pickup Address',
                  prefixIcon: const Icon(Icons.place_outlined),
                ),
              ),

              if (_selectedRole == UserRole.rider) ...[
                const SizedBox(height: 14),
                TextFormField(
                  controller: _vehicleController,
                  decoration: const InputDecoration(
                    labelText: 'Vehicle / Tricycle Number',
                    prefixIcon: Icon(Icons.two_wheeler_rounded),
                    hintText: 'e.g. Eco Tricycle #08',
                  ),
                ),
              ],

              const SizedBox(height: 28),

              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  style: ElevatedButton.styleFrom(backgroundColor: roleColor),
                  onPressed: _isRegistering ? null : _submit,
                  icon: _isRegistering
                      ? const SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                        )
                      : const Icon(Icons.check_circle_rounded),
                  label: const Text('Create Account & Sign In'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _roleChoice(UserRole role, String label, IconData icon, Color color) {
    final isSelected = _selectedRole == role;
    return Expanded(
      child: InkWell(
        onTap: () => setState(() => _selectedRole = role),
        borderRadius: BorderRadius.circular(12),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 10),
          decoration: BoxDecoration(
            color: isSelected ? color.withValues(alpha: 0.12) : Colors.white,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: isSelected ? color : const Color(0xFFDDDDDD),
              width: isSelected ? 2 : 1,
            ),
          ),
          child: Column(
            children: [
              Icon(icon, color: isSelected ? color : AppTheme.textMuted, size: 20),
              const SizedBox(height: 4),
              Text(
                label,
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                  color: isSelected ? color : AppTheme.textDark,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
