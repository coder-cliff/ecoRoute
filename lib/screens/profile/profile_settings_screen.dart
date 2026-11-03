import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';
import '../../models/user_model.dart';
import '../../models/waste_category.dart';
import '../../providers/auth_provider.dart';
import '../../providers/waste_request_provider.dart';
import '../../services/storage_service.dart';
import '../../theme/app_theme.dart';
import '../../widgets/user_avatar.dart';
import '../auth/register_screen.dart';
import '../common/interactive_map_screen.dart';

class ProfileSettingsScreen extends StatefulWidget {
  const ProfileSettingsScreen({super.key});

  @override
  State<ProfileSettingsScreen> createState() => _ProfileSettingsScreenState();
}

class _ProfileSettingsScreenState extends State<ProfileSettingsScreen> {
  final _formKey = GlobalKey<FormState>();

  late TextEditingController _nameController;
  late TextEditingController _phoneController;
  late TextEditingController _emailController;
  late TextEditingController _addressController;
  late TextEditingController _vehicleController;

  late String _avatarUrl;
  bool _isSaving = false;
  final ImagePicker _picker = ImagePicker();

  @override
  void initState() {
    super.initState();
    final user = Provider.of<AuthProvider>(context, listen: false).currentUser;
    _nameController = TextEditingController(text: user.name);
    _phoneController = TextEditingController(text: user.phone);
    _emailController = TextEditingController(text: user.email);
    _addressController = TextEditingController(text: user.address);
    _vehicleController = TextEditingController(text: user.vehicleInfo ?? '');
    _avatarUrl = user.avatarUrl;
  }

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

  Future<void> _pickFromCamera() async {
    try {
      final photo = await _picker.pickImage(
        source: ImageSource.camera,
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
      debugPrint('Camera error: $e');
    }
  }

  Future<void> _pickFromGallery() async {
    try {
      final image = await _picker.pickImage(
        source: ImageSource.gallery,
        maxWidth: 512,
        maxHeight: 512,
        imageQuality: 85,
      );
      if (image != null) {
        setState(() {
          _avatarUrl = image.path;
        });
      }
    } catch (e) {
      debugPrint('Gallery error: $e');
    }
  }

  void _showAvatarPickerModal(UserRole currentRole) {
    final presets = UserModel.standardAvatarPresets;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(20.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'Choose Profile Picture',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close_rounded),
                    onPressed: () => Navigator.pop(ctx),
                  ),
                ],
              ),
              const SizedBox(height: 6),
              const Text(
                'Upload a personalized photo from your device or select an official municipal avatar.',
                style: TextStyle(fontSize: 12, color: AppTheme.textMuted),
              ),
              const SizedBox(height: 16),

              // Upload options
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 12),
                      ),
                      onPressed: () {
                        Navigator.pop(ctx);
                        _pickFromCamera();
                      },
                      icon: const Icon(Icons.camera_alt_rounded),
                      label: const Text('Camera'),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: OutlinedButton.icon(
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 12),
                      ),
                      onPressed: () {
                        Navigator.pop(ctx);
                        _pickFromGallery();
                      },
                      icon: const Icon(Icons.photo_library_rounded),
                      label: const Text('Gallery'),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20),

              const Text(
                'Standard Vector Presets',
                style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 12),

              GridView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 3,
                  crossAxisSpacing: 10,
                  mainAxisSpacing: 10,
                  childAspectRatio: 0.95,
                ),
                itemCount: presets.length,
                itemBuilder: (context, index) {
                  final preset = presets[index];
                  final presetId = preset['id']!;
                  final isSelected = _avatarUrl == presetId;

                  return InkWell(
                    onTap: () {
                      setState(() {
                        _avatarUrl = presetId;
                      });
                      Navigator.pop(ctx);
                    },
                    borderRadius: BorderRadius.circular(12),
                    child: Container(
                      decoration: BoxDecoration(
                        color: isSelected
                            ? _getRoleColor(currentRole).withValues(alpha: 0.1)
                            : Colors.grey.shade50,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: isSelected
                              ? _getRoleColor(currentRole)
                              : Colors.grey.shade200,
                          width: isSelected ? 2 : 1,
                        ),
                      ),
                      padding: const EdgeInsets.all(8),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          UserAvatar(
                            avatarUrl: presetId,
                            name: preset['label'],
                            role: currentRole,
                            radius: 26,
                          ),
                          const SizedBox(height: 6),
                          Text(
                            preset['label']!,
                            textAlign: TextAlign.center,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                              color: isSelected ? _getRoleColor(currentRole) : AppTheme.textDark,
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _saveProfile() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isSaving = true;
    });

    try {
      final auth = Provider.of<AuthProvider>(context, listen: false);
      await auth.updateProfile(
        name: _nameController.text.trim(),
        phone: _phoneController.text.trim(),
        email: _emailController.text.trim(),
        address: _addressController.text.trim(),
        avatarUrl: _avatarUrl.trim(),
        vehicleInfo: _vehicleController.text.trim().isNotEmpty
            ? _vehicleController.text.trim()
            : null,
      );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Profile & Display Picture updated successfully!'),
            backgroundColor: AppTheme.primaryGreen,
          ),
        );
        Navigator.pop(context);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error updating profile: $e'),
            backgroundColor: Colors.redAccent,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isSaving = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final auth = Provider.of<AuthProvider>(context);
    final provider = Provider.of<WasteRequestProvider>(context);
    final user = auth.currentUser;
    final roleColor = _getRoleColor(user.role);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Profile & Account'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20.0),
        child: Form(
          key: _formKey,
          child: Column(
            children: [
              // HEADER CARD WITH DP
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: const Color(0xFFEEEEEE)),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.03),
                      blurRadius: 10,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Column(
                  children: [
                    Stack(
                      alignment: Alignment.bottomRight,
                      children: [
                        UserAvatar(
                          avatarUrl: _avatarUrl,
                          name: _nameController.text,
                          role: user.role,
                          radius: 48,
                          showRoleBadge: true,
                          isEditable: true,
                          onTap: () => _showAvatarPickerModal(user.role),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    TextButton.icon(
                      onPressed: () => _showAvatarPickerModal(user.role),
                      icon: const Icon(Icons.photo_camera_rounded, size: 16),
                      label: const Text('Change Display Picture'),
                    ),
                    const SizedBox(height: 6),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                      decoration: BoxDecoration(
                        color: roleColor.withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: Text(
                        user.role.displayName,
                        style: TextStyle(
                          color: roleColor,
                          fontWeight: FontWeight.bold,
                          fontSize: 12,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),

              // FORM FIELDS
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(20.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Personal Information',
                        style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
                      ),
                      const SizedBox(height: 16),

                      TextFormField(
                        controller: _nameController,
                        decoration: const InputDecoration(
                          labelText: 'Full Name',
                          prefixIcon: Icon(Icons.person_outline_rounded),
                        ),
                        validator: (v) =>
                            (v == null || v.trim().isEmpty) ? 'Please enter your full name' : null,
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
                            (v == null || !v.contains('@')) ? 'Enter a valid email' : null,
                      ),
                      const SizedBox(height: 14),

                      TextFormField(
                        controller: _addressController,
                        maxLines: 2,
                        decoration: InputDecoration(
                          labelText: user.role == UserRole.rider
                              ? 'Operating Depot / Base Location'
                              : 'Default Home / Business Address',
                          prefixIcon: const Icon(Icons.place_outlined),
                        ),
                      ),

                      if (user.role == UserRole.rider) ...[
                        const SizedBox(height: 14),
                        TextFormField(
                          controller: _vehicleController,
                          decoration: const InputDecoration(
                            labelText: 'Vehicle Type / Fleet ID',
                            prefixIcon: Icon(Icons.two_wheeler_rounded),
                            hintText: 'e.g. Eco Cargo Tricycle #12',
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 20),

              // SAVE BUTTON
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: _isSaving ? null : _saveProfile,
                  icon: _isSaving
                      ? const SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                        )
                      : const Icon(Icons.save_rounded),
                  label: const Text('Save Profile & DP Changes'),
                ),
              ),

              // ADMIN EXCLUSIVE SYSTEM SETTINGS
              if (user.role == UserRole.admin) ...[
                const SizedBox(height: 28),
                _buildAdminSystemSettings(context, auth, provider),
              ],

              const SizedBox(height: 30),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildAdminSystemSettings(
    BuildContext context,
    AuthProvider auth,
    WasteRequestProvider provider,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Container(
              padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(
                color: const Color(0xFF6F42C1).withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Icon(Icons.admin_panel_settings_rounded, color: Color(0xFF6F42C1), size: 20),
            ),
            const SizedBox(width: 10),
            const Text(
              'Municipal System & Admin Controls',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: Color(0xFF6F42C1),
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),

        // 1. Operating Hours Policy
        Card(
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Row(
                  children: [
                    Icon(Icons.schedule_rounded, color: AppTheme.primaryGreen, size: 20),
                    SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        'Municipal Operating Window',
                        style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                      ),
                    ),
                    Text(
                      'ACTIVE',
                      style: TextStyle(color: AppTheme.primaryGreen, fontWeight: FontWeight.bold, fontSize: 11),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                const Text(
                  'Service Window: 07:00 AM – 07:00 PM Daily',
                  style: TextStyle(fontWeight: FontWeight.w600, fontSize: 13),
                ),
                const SizedBox(height: 4),
                const Text(
                  'Daylight safety guardrail actively blocks citizen scheduling during nighttime hours to safeguard collection riders.',
                  style: TextStyle(fontSize: 12, color: AppTheme.textMuted),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 10),

        // 2. Collection Pricing Standard
        Card(
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Row(
                  children: [
                    Icon(Icons.tune_rounded, color: AppTheme.cashGold, size: 20),
                    SizedBox(width: 10),
                    Text(
                      'Container Volume Multipliers',
                      style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: WasteVolumeSize.values.map((v) {
                    return Column(
                      children: [
                        Text(
                          '${v.multiplier}x',
                          style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 16, color: AppTheme.cashGold),
                        ),
                        Text(
                          v.label.split(' ').first,
                          style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
                        ),
                        Text(
                          v.label.split(' ').last,
                          style: const TextStyle(fontSize: 10, color: AppTheme.textMuted),
                        ),
                      ],
                    );
                  }).toList(),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 10),

        // 3. Central Sorting Depot Hub
        Card(
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Row(
              children: [
                const Icon(Icons.hub_rounded, color: Color(0xFF0D6EFD), size: 20),
                const SizedBox(width: 10),
                const Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Central Recycling Depot',
                        style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                      ),
                      Text(
                        'Kampala Municipal Hub (0.3476, 32.5825)',
                        style: TextStyle(fontSize: 12, color: AppTheme.textMuted),
                      ),
                    ],
                  ),
                ),
                IconButton.filledTonal(
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (_) => const InteractiveMapScreen()),
                    );
                  },
                  icon: const Icon(Icons.map_rounded, size: 18),
                  tooltip: 'View on Map',
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 10),

        // 4. Municipal User Directory
        Card(
          child: ListTile(
            leading: const Icon(Icons.badge_rounded, color: Color(0xFF6F42C1)),
            title: const Text('Municipal User Directory', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
            subtitle: Text('${auth.allUsers.length} registered citizens, riders & admins'),
            trailing: const Icon(Icons.arrow_forward_ios_rounded, size: 14),
            onTap: () => _showUserDirectoryModal(context, auth),
          ),
        ),
        const SizedBox(height: 10),

        // 5. CSV Export Shortcut
        Card(
          child: ListTile(
            leading: const Icon(Icons.file_download_rounded, color: AppTheme.primaryGreen),
            title: const Text('Export Operations CSV', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
            subtitle: const Text('Download full audit trail (100% Free & Open)'),
            trailing: const Icon(Icons.copy_rounded, size: 16),
            onTap: () {
              final csv = provider.exportMunicipalCsvReport();
              Clipboard.setData(ClipboardData(text: csv));
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Municipal Operations CSV copied to clipboard!'),
                  backgroundColor: AppTheme.primaryGreen,
                ),
              );
            },
          ),
        ),
        const SizedBox(height: 10),

        // 6. Reset / Re-seed Data
        Card(
          child: ListTile(
            leading: const Icon(Icons.restart_alt_rounded, color: Colors.orange),
            title: const Text('Reset Demo Database', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
            subtitle: const Text('Restore baseline sample requests & accounts'),
            trailing: const Icon(Icons.refresh_rounded, size: 18),
            onTap: () => _confirmResetDatabase(context, provider),
          ),
        ),
      ],
    );
  }

  void _showUserDirectoryModal(BuildContext context, AuthProvider auth) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => Container(
        height: MediaQuery.of(context).size.height * 0.75,
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
        child: Column(
          children: [
            Center(
              child: Container(
                margin: const EdgeInsets.only(top: 12, bottom: 8),
                width: 44,
                height: 5,
                decoration: BoxDecoration(
                  color: Colors.grey.shade300,
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 8.0),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'Municipal User Directory',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close_rounded),
                    onPressed: () => Navigator.pop(context),
                  ),
                ],
              ),
            ),
            const Divider(height: 1),
            Expanded(
              child: ListView.separated(
                padding: const EdgeInsets.all(16),
                itemCount: auth.allUsers.length,
                separatorBuilder: (_, __) => const Divider(height: 1),
                itemBuilder: (context, index) {
                  final u = auth.allUsers[index];
                  return ListTile(
                    leading: UserAvatar(user: u, radius: 22, showRoleBadge: true),
                    title: Text(u.name, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                    subtitle: Text('${u.role.displayName} • ${u.phone}\n${u.address}'),
                    isThreeLine: true,
                  );
                },
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: () {
                    Navigator.pop(context);
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (_) => const RegisterScreen()),
                    );
                  },
                  icon: const Icon(Icons.person_add_rounded),
                  label: const Text('Register New Personnel'),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _confirmResetDatabase(BuildContext context, WasteRequestProvider provider) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Reset Demo Data?'),
        content: const Text(
          'This will re-initialize sample requests and baseline accounts for viva/demonstration purposes.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.orange),
            onPressed: () async {
              Navigator.pop(ctx);
              await StorageService.saveRequests([]);
              await provider.loadRequests();
              if (context.mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Demo database re-initialized successfully!'),
                    backgroundColor: AppTheme.primaryGreen,
                  ),
                );
              }
            },
            child: const Text('Reset'),
          ),
        ],
      ),
    );
  }
}
