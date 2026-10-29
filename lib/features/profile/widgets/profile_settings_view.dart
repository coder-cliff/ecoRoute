import 'dart:convert';
import 'package:flutter/foundation.dart' show kDebugMode;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:image_picker/image_picker.dart';

import '../../../core/pickup_request_repository.dart';
import '../../../core/services/auth_service.dart';
import '../../../core/services/language_service.dart';
import '../../../core/services/theme_service.dart';
import '../../../domain/entities/app_user.dart';
import '../../../domain/entities/pickup_request.dart';
import '../../../domain/enums/request_status.dart';
import '../../../domain/enums/role.dart';
import '../../../domain/rules/reminder_policy.dart';

class ProfileSettingsView extends StatefulWidget {
  const ProfileSettingsView({
    required this.currentUser,
    required this.role,
    required this.orders,
    required this.repository,
    this.authService,
    this.remindersEnabled = true,
    this.onRemindersToggled,
    this.onOpenWasteDatabase,
    this.onRefreshOrders,
    this.onSignOut,
    this.onProfileUpdated,
    super.key,
  });

  final AppUser? currentUser;
  final AppRole role;
  final List<PickupRequest> orders;
  final PickupRequestRepository repository;
  final AuthService? authService;
  final bool remindersEnabled;
  final ValueChanged<bool>? onRemindersToggled;
  final VoidCallback? onOpenWasteDatabase;
  final VoidCallback? onRefreshOrders;
  final VoidCallback? onSignOut;
  final VoidCallback? onProfileUpdated;

  @override
  State<ProfileSettingsView> createState() => _ProfileSettingsViewState();
}

class _ProfileSettingsViewState extends State<ProfileSettingsView> {
  final _reminderPolicy = const ReminderPolicy();
  final _langService = LanguageService.instance;
  bool _uploadingPhoto = false;

  void _showPhotoOptionsSheet() {
    final hasPhoto = widget.currentUser?.photoUrl != null &&
        widget.currentUser!.photoUrl!.isNotEmpty;

    showModalBottomSheet<void>(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 36,
                height: 4,
                margin: const EdgeInsets.only(bottom: 16),
                decoration: BoxDecoration(
                  color: Colors.grey[300],
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const Padding(
                padding: EdgeInsets.symmetric(horizontal: 20, vertical: 4),
                child: Row(
                  children: [
                    Icon(Icons.account_circle_outlined, color: Color(0xFF2E7D32)),
                    SizedBox(width: 8),
                    Text(
                      'Profile Photo',
                      style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800),
                    ),
                  ],
                ),
              ),
              const Divider(),
              ListTile(
                leading: const Icon(Icons.camera_alt_outlined, color: Color(0xFF2E7D32)),
                title: const Text('Take photo with camera'),
                onTap: () {
                  Navigator.pop(ctx);
                  _pickAndUploadPhoto(ImageSource.camera);
                },
              ),
              ListTile(
                leading: const Icon(Icons.photo_library_outlined, color: Color(0xFF2E7D32)),
                title: const Text('Choose from gallery'),
                onTap: () {
                  Navigator.pop(ctx);
                  _pickAndUploadPhoto(ImageSource.gallery);
                },
              ),
              if (hasPhoto)
                ListTile(
                  leading: const Icon(Icons.delete_outline_rounded, color: Color(0xFFC62828)),
                  title: const Text(
                    'Remove profile photo',
                    style: TextStyle(color: Color(0xFFC62828)),
                  ),
                  onTap: () {
                    Navigator.pop(ctx);
                    _removePhoto();
                  },
                ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _pickAndUploadPhoto(ImageSource source) async {
    try {
      final picker = ImagePicker();
      final picked = await picker.pickImage(
        source: source,
        maxWidth: 512,
        maxHeight: 512,
        imageQuality: 70,
      );
      if (picked == null) return;

      setState(() => _uploadingPhoto = true);
      final bytes = await picked.readAsBytes();
      final base64String = 'data:image/jpeg;base64,${base64Encode(bytes)}';

      if (widget.authService != null) {
        await widget.authService!.updateProfilePhoto(base64String);
      }
      widget.onProfileUpdated?.call();

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Profile photo updated successfully.'),
            backgroundColor: Color(0xFF2E7D32),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Could not update profile photo: $e'),
            backgroundColor: const Color(0xFFC62828),
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _uploadingPhoto = false);
      }
    }
  }

  Future<void> _removePhoto() async {
    try {
      setState(() => _uploadingPhoto = true);
      if (widget.authService != null) {
        await widget.authService!.updateProfilePhoto(null);
      }
      widget.onProfileUpdated?.call();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Profile photo removed.'),
            backgroundColor: Color(0xFF2E7D32),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Could not remove photo: $e')),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _uploadingPhoto = false);
      }
    }
  }

  Widget _buildAvatarImage(AppUser? user) {
    final photoUrl = user?.photoUrl;
    if (photoUrl != null && photoUrl.isNotEmpty) {
      try {
        if (photoUrl.startsWith('data:image')) {
          final base64Part = photoUrl.contains(',')
              ? photoUrl.split(',').last.trim()
              : photoUrl;
          final bytes = base64Decode(base64Part);
          return Image.memory(
            bytes,
            width: 86,
            height: 86,
            fit: BoxFit.cover,
            errorBuilder: (context, error, stackTrace) => _buildFallbackInitial(user),
          );
        } else if (photoUrl.startsWith('http')) {
          return Image.network(
            photoUrl,
            width: 86,
            height: 86,
            fit: BoxFit.cover,
            errorBuilder: (context, error, stackTrace) => _buildFallbackInitial(user),
          );
        } else {
          final bytes = base64Decode(photoUrl);
          return Image.memory(
            bytes,
            width: 86,
            height: 86,
            fit: BoxFit.cover,
            errorBuilder: (context, error, stackTrace) => _buildFallbackInitial(user),
          );
        }
      } catch (_) {
        return _buildFallbackInitial(user);
      }
    }
    return _buildFallbackInitial(user);
  }

  Widget _buildFallbackInitial(AppUser? user) {
    return Container(
      width: 86,
      height: 86,
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          colors: [Color(0xFF2E8B57), Color(0xFF135D39)],
        ),
        shape: BoxShape.circle,
      ),
      child: Center(
        child: Text(
          user?.fullName.isNotEmpty == true
              ? user!.fullName.trim()[0].toUpperCase()
              : 'U',
          style: const TextStyle(
            fontSize: 36,
            fontWeight: FontWeight.w900,
            color: Colors.white,
          ),
        ),
      ),
    );
  }

  String _formatName(String raw) {
    if (raw.isEmpty) return 'EcoRoute User';
    return raw
        .trim()
        .split(RegExp(r'\s+'))
        .map((w) => w.isNotEmpty ? '${w[0].toUpperCase()}${w.substring(1).toLowerCase()}' : '')
        .join(' ');
  }

  void _showEditProfileDialog() {
    final user = widget.currentUser;
    final nameCtrl = TextEditingController(text: user?.fullName ?? '');
    final phoneCtrl = TextEditingController(text: user?.phone ?? '');
    final addressCtrl = TextEditingController(text: user?.address ?? '');
    final formKey = GlobalKey<FormState>();

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Row(
          children: [
            Icon(Icons.edit_note_rounded, color: Color(0xFF2E7D32)),
            SizedBox(width: 8),
            Text('Edit Contact Profile', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800)),
          ],
        ),
        content: Form(
          key: formKey,
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text(
                  'Update your profile information for collection riders and dispatch dispatchers.',
                  style: TextStyle(fontSize: 12, color: Color(0xFF647568)),
                ),
                const SizedBox(height: 12),
                Center(
                  child: InkWell(
                    onTap: () {
                      Navigator.pop(ctx);
                      _showPhotoOptionsSheet();
                    },
                    borderRadius: BorderRadius.circular(30),
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(
                        color: const Color(0xFFE8F5E9),
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(color: const Color(0xFFA5D6A7)),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          ClipOval(
                            child: SizedBox(
                              width: 28,
                              height: 28,
                              child: _buildAvatarImage(user),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Text(
                            user?.photoUrl != null && user!.photoUrl!.isNotEmpty
                                ? 'Change Photo'
                                : 'Upload Photo',
                            style: const TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w700,
                              color: Color(0xFF2E7D32),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 14),
                TextFormField(
                  controller: nameCtrl,
                  decoration: InputDecoration(
                    labelText: 'Full name',
                    prefixIcon: const Icon(Icons.person_outline, size: 20),
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                    isDense: true,
                  ),
                  validator: (v) => (v == null || v.trim().isEmpty) ? 'Please enter your name' : null,
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: phoneCtrl,
                  keyboardType: TextInputType.phone,
                  decoration: InputDecoration(
                    labelText: 'Phone number',
                    prefixIcon: const Icon(Icons.phone_outlined, size: 20),
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                    isDense: true,
                  ),
                  validator: (v) => (v == null || v.trim().isEmpty) ? 'Please enter your phone number' : null,
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: addressCtrl,
                  decoration: InputDecoration(
                    labelText: 'Default pickup address / zone',
                    hintText: 'e.g. Muni University, Arua Central',
                    prefixIcon: const Icon(Icons.location_on_outlined, size: 20),
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                    isDense: true,
                  ),
                ),
              ],
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () async {
              if (formKey.currentState?.validate() != true) return;
              if (widget.authService != null) {
                try {
                  await widget.authService!.updateUserProfile(
                    fullName: nameCtrl.text.trim(),
                    phone: phoneCtrl.text.trim(),
                    address: addressCtrl.text.trim(),
                  );
                  if (ctx.mounted) Navigator.pop(ctx);
                  widget.onProfileUpdated?.call();
                  if (mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Profile updated successfully!'),
                        backgroundColor: Color(0xFF2E7D32),
                      ),
                    );
                  }
                } catch (e) {
                  if (mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text('Error updating profile: $e')),
                    );
                  }
                }
              }
            },
            style: FilledButton.styleFrom(backgroundColor: const Color(0xFF2E7D32)),
            child: const Text('Save Profile'),
          ),
        ],
      ),
    );
  }

  void _showPasswordResetDialog() {
    final email = widget.currentUser?.email ?? '';
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Row(
          children: [
            Icon(Icons.lock_reset_rounded, color: Color(0xFF2E7D32)),
            SizedBox(width: 8),
            Text('Reset Password', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800)),
          ],
        ),
        content: Text(
          'Send a secure password reset link to $email?',
          style: const TextStyle(fontSize: 13),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () async {
              Navigator.pop(ctx);
              try {
                await widget.authService?.sendPasswordResetEmail(email);
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('Password reset link sent to $email.'),
                      backgroundColor: const Color(0xFF2E7D32),
                    ),
                  );
                }
              } catch (e) {
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Could not send reset link: $e')),
                  );
                }
              }
            },
            style: FilledButton.styleFrom(backgroundColor: const Color(0xFF2E7D32)),
            child: const Text('Send Reset Email'),
          ),
        ],
      ),
    );
  }

  void _showLanguageSelector() {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) => Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.language_rounded, color: Color(0xFF2E7D32)),
                const SizedBox(width: 8),
                const Text(
                  'Select App Language',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800),
                ),
                const Spacer(),
                IconButton(
                  onPressed: () => Navigator.pop(ctx),
                  icon: const Icon(Icons.close_rounded),
                ),
              ],
            ),
            const SizedBox(height: 12),
            for (final lang in AppLanguage.values) ...[
              Material(
                color: Colors.transparent,
                child: ListTile(
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  leading: Container(
                    width: 36,
                    height: 36,
                    decoration: BoxDecoration(
                      color: _langService.currentLanguage == lang
                          ? const Color(0xFF2E7D32)
                          : const Color(0xFFE8F5E9),
                      shape: BoxShape.circle,
                    ),
                    child: Center(
                      child: Text(
                        lang.code.toUpperCase(),
                        style: TextStyle(
                          fontWeight: FontWeight.w800,
                          fontSize: 12,
                          color: _langService.currentLanguage == lang
                              ? Colors.white
                              : const Color(0xFF2E7D32),
                        ),
                      ),
                    ),
                  ),
                  title: Text(lang.label, style: const TextStyle(fontWeight: FontWeight.w700)),
                  trailing: _langService.currentLanguage == lang
                      ? const Icon(Icons.check_circle_rounded, color: Color(0xFF2E7D32))
                      : null,
                  onTap: () {
                    _langService.setLanguage(lang);
                    Navigator.pop(ctx);
                    setState(() {});
                  },
                ),
              ),
              const SizedBox(height: 6),
            ],
          ],
        ),
      ),
    );
  }

  void _showThemeSelector() {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) => Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Row(
              children: [
                Icon(Icons.palette_outlined, color: Color(0xFF2E7D32)),
                SizedBox(width: 8),
                Text(
                  'Select Theme Mode',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800),
                ),
              ],
            ),
            const SizedBox(height: 16),
            for (final mode in [ThemeMode.system, ThemeMode.light, ThemeMode.dark])
              ListTile(
                contentPadding: EdgeInsets.zero,
                leading: Icon(
                  switch (mode) {
                    ThemeMode.light => Icons.light_mode_outlined,
                    ThemeMode.dark => Icons.dark_mode_outlined,
                    ThemeMode.system => Icons.settings_brightness_outlined,
                  },
                  color: const Color(0xFF2E7D32),
                ),
                title: Text(
                  switch (mode) {
                    ThemeMode.light => 'Light Mode',
                    ThemeMode.dark => 'Dark Mode',
                    ThemeMode.system => 'System Default',
                  },
                  style: const TextStyle(fontWeight: FontWeight.w700),
                ),
                trailing: ThemeService.instance.themeMode == mode
                    ? const Icon(Icons.check_rounded, color: Color(0xFF2E7D32))
                    : null,
                onTap: () {
                  ThemeService.instance.setThemeMode(mode);
                  Navigator.pop(ctx);
                  setState(() {});
                },
              ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final user = widget.currentUser;
    final role = widget.role;

    // Environmental metrics calculation
    final totalRequests = widget.orders.length;
    final totalSacks = widget.orders.fold<int>(0, (sum, o) => sum + o.sackCount);
    final totalKg = totalSacks * 25;
    final totalCo2 = (totalKg * 0.45).toStringAsFixed(1);

    final openCount = widget.orders.where((o) => o.status == RequestStatus.requested).length;
    final collectedCount = widget.orders.where((o) => o.status == RequestStatus.collected).length;
    final paidCount = widget.orders.where((o) => o.status == RequestStatus.paid).length;

    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(18, 12, 18, 32),
      child: Column(
        children: [
          // Header Card
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Color(0xFFFFFFFF), Color(0xFFF7FBF8)],
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
              ),
              borderRadius: BorderRadius.circular(24),
              border: Border.all(color: const Color(0xFFE2EAE1)),
              boxShadow: const [
                BoxShadow(
                  color: Color(0x0C000000),
                  blurRadius: 10,
                  offset: Offset(0, 4),
                ),
              ],
            ),
            child: Column(
              children: [
                Stack(
                  alignment: Alignment.bottomRight,
                  children: [
                    GestureDetector(
                      onTap: _showPhotoOptionsSheet,
                      child: Container(
                        width: 86,
                        height: 86,
                        decoration: const BoxDecoration(
                          shape: BoxShape.circle,
                          boxShadow: [
                            BoxShadow(
                              color: Color(0x22135D39),
                              blurRadius: 12,
                              offset: Offset(0, 4),
                            ),
                          ],
                        ),
                        child: ClipOval(
                          child: _buildAvatarImage(user),
                        ),
                      ),
                    ),
                    if (_uploadingPhoto)
                      Positioned.fill(
                        child: Container(
                          decoration: const BoxDecoration(
                            color: Colors.black38,
                            shape: BoxShape.circle,
                          ),
                          child: const Center(
                            child: SizedBox(
                              width: 24,
                              height: 24,
                              child: CircularProgressIndicator(
                                strokeWidth: 2.5,
                                color: Colors.white,
                              ),
                            ),
                          ),
                        ),
                      ),
                    InkWell(
                      onTap: _showPhotoOptionsSheet,
                      borderRadius: BorderRadius.circular(16),
                      child: Container(
                        padding: const EdgeInsets.all(6),
                        decoration: BoxDecoration(
                          color: const Color(0xFF1B5E20),
                          shape: BoxShape.circle,
                          border: Border.all(color: Colors.white, width: 2),
                        ),
                        child: const Icon(Icons.camera_alt_rounded, size: 14, color: Colors.white),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                TextButton.icon(
                  onPressed: _showPhotoOptionsSheet,
                  icon: const Icon(Icons.photo_camera_outlined, size: 14, color: Color(0xFF2E7D32)),
                  label: Text(
                    user?.photoUrl != null && user!.photoUrl!.isNotEmpty
                        ? 'Change Photo'
                        : 'Upload Photo',
                    style: const TextStyle(
                      fontSize: 11.5,
                      fontWeight: FontWeight.w700,
                      color: Color(0xFF2E7D32),
                    ),
                  ),
                ),
                const SizedBox(height: 4),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Flexible(
                      child: Text(
                        _formatName(user?.fullName ?? ''),
                        textAlign: TextAlign.center,
                        style: const TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.w900,
                          color: Color(0xFF183B20),
                        ),
                      ),
                    ),
                    const SizedBox(width: 4),
                    IconButton(
                      icon: const Icon(Icons.edit_outlined, size: 17, color: Color(0xFF2E7D32)),
                      tooltip: 'Edit Profile Information',
                      onPressed: _showEditProfileDialog,
                      visualDensity: VisualDensity.compact,
                    ),
                  ],
                ),
                const SizedBox(height: 6),

                // Crucial requirement: 'Signed in as ${_role.label}' exact matching
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
                  decoration: BoxDecoration(
                    color: const Color(0xFFE8F5E9),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: const Color(0xFFA5D6A7)),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        role == AppRole.admin
                            ? Icons.admin_panel_settings_rounded
                            : role == AppRole.rider
                                ? Icons.two_wheeler_rounded
                                : Icons.person_rounded,
                        size: 14,
                        color: const Color(0xFF2E7D32),
                      ),
                      const SizedBox(width: 5),
                      Text(
                        'Signed in as ${role.label}',
                        style: const TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w800,
                          color: Color(0xFF2E7D32),
                        ),
                      ),
                    ],
                  ),
                ),

                if (user != null) ...[
                  const SizedBox(height: 8),
                  Text(
                    '${user.email} • ${user.phone}',
                    textAlign: TextAlign.center,
                    style: const TextStyle(fontSize: 12, color: Color(0xFF71877D)),
                  ),
                  if (user.address?.isNotEmpty == true) ...[
                    const SizedBox(height: 4),
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.location_on_outlined, size: 13, color: Color(0xFF2E7D32)),
                        const SizedBox(width: 3),
                        Text(
                          user.address!,
                          style: const TextStyle(fontSize: 11, color: Color(0xFF556958)),
                        ),
                      ],
                    ),
                  ],
                ],
              ],
            ),
          ),
          const SizedBox(height: 16),

          if (role == AppRole.resident) ...[
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Color(0xFFE8F5E9), Color(0xFFD4EED8)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: const Color(0xFFA5D6A7)),
              ),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: const BoxDecoration(
                      color: Color(0xFF2E7D32),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(Icons.workspace_premium_rounded, color: Colors.white, size: 20),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          paidCount >= 5 ? 'Arua Eco Champion' : paidCount >= 2 ? 'Green Guardian' : 'Arua Clean Citizen',
                          style: const TextStyle(
                            fontSize: 13.5,
                            fontWeight: FontWeight.w800,
                            color: Color(0xFF1B5E20),
                          ),
                        ),
                        Text(
                          '$totalSacks sack(s) collected & recycled • Thank you for keeping Arua green!',
                          style: const TextStyle(
                            fontSize: 11,
                            color: Color(0xFF2E7D32),
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
          ],

          // Environmental & Operation Impact
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: const Color(0xFFE2EAE1)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Row(
                  children: [
                    Icon(Icons.eco_rounded, color: Color(0xFF2E7D32), size: 18),
                    SizedBox(width: 6),
                    Text(
                      'Environmental & Lifecycle Impact',
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w800,
                        color: Color(0xFF183B20),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 14),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: [
                    _buildMetricCol('Pickups', '$totalRequests', Icons.local_shipping_outlined),
                    Container(width: 1, height: 32, color: const Color(0xFFE2EAE1)),
                    _buildMetricCol('Sacks', '$totalSacks', Icons.shopping_bag_outlined),
                    Container(width: 1, height: 32, color: const Color(0xFFE2EAE1)),
                    _buildMetricCol('CO₂ Avoided', '$totalCo2 kg', Icons.cloud_done_outlined, const Color(0xFF2E7D32)),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),

          // Request Stats
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: const Color(0xFFE2EAE1)),
            ),
            child: Column(
              children: [
                _buildMetricRow('Open requests', '$openCount', const Color(0xFFE65100)),
                const Divider(height: 20),
                _buildMetricRow('Collected', '$collectedCount', const Color(0xFF0288D1)),
                const Divider(height: 20),
                _buildMetricRow('Paid & Settled', '$paidCount', const Color(0xFF2E7D32)),
              ],
            ),
          ),
          const SizedBox(height: 16),

          // Group 1: Preferences & Service
          _buildSettingsSection(
            title: 'Service & Notifications',
            icon: Icons.tune_rounded,
            items: [
              _buildSettingTile(
                icon: Icons.notifications_active_outlined,
                title: 'Pickup schedule reminders',
                subtitle: _reminderPolicy.shouldSendReminder(
                  successfulRequests: paidCount,
                  remindersEnabled: widget.remindersEnabled,
                )
                    ? 'Active: Free onboarding reminder policy enabled.'
                    : 'Reminders inactive or onboarding threshold met.',
                trailing: Switch(
                  value: widget.remindersEnabled,
                  onChanged: (val) {
                    widget.onRemindersToggled?.call(val);
                    widget.authService?.setRemindersEnabled(val);
                  },
                ),
              ),
              const Divider(height: 1),
              _buildSettingTile(
                icon: Icons.language_rounded,
                title: 'App Language',
                subtitle: _langService.currentLanguage.label,
                trailing: const Icon(Icons.chevron_right_rounded),
                onTap: _showLanguageSelector,
              ),
              const Divider(height: 1),
              ListenableBuilder(
                listenable: ThemeService.instance,
                builder: (context, _) => _buildSettingTile(
                  icon: ThemeService.instance.isDarkMode
                      ? Icons.dark_mode_outlined
                      : Icons.light_mode_outlined,
                  title: 'Appearance',
                  subtitle: switch (ThemeService.instance.themeMode) {
                    ThemeMode.light => 'Light mode',
                    ThemeMode.dark => 'Dark mode',
                    ThemeMode.system => 'System default',
                  },
                  trailing: const Icon(Icons.chevron_right_rounded),
                  onTap: _showThemeSelector,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),

          // Group 2: Intelligence & Knowledge Base
          _buildSettingsSection(
            title: 'Waste Intelligence & Resources',
            icon: Icons.dataset_outlined,
            items: [
              _buildSettingTile(
                icon: Icons.auto_awesome_outlined,
                title: 'Municipal Solid Waste & Recycling Data',
                subtitle: 'World Bank benchmarks, Lugbara terms & scrap rates',
                trailing: const Icon(Icons.chevron_right_rounded),
                onTap: widget.onOpenWasteDatabase,
              ),
            ],
          ),
          const SizedBox(height: 16),

          // Group 3: Security & Synchronization
          _buildSettingsSection(
            title: 'Security & Synchronization',
            icon: Icons.security_rounded,
            items: [
              _buildSettingTile(
                icon: Icons.lock_reset_rounded,
                title: 'Send password reset email',
                subtitle: 'Receive a secure link to change your password',
                trailing: const Icon(Icons.arrow_forward_ios_rounded, size: 14),
                onTap: _showPasswordResetDialog,
              ),
              const Divider(height: 1),
              _buildSettingTile(
                icon: Icons.sync_rounded,
                title: 'Refresh & Sync Local Database',
                subtitle: 'Ensure offline orders match municipal dispatch records',
                trailing: const Icon(Icons.refresh_rounded),
                onTap: () {
                  HapticFeedback.lightImpact();
                  widget.onRefreshOrders?.call();
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Database refreshed successfully.'),
                      backgroundColor: Color(0xFF2E7D32),
                    ),
                  );
                },
              ),
              if (kDebugMode && role == AppRole.admin) ...[
                const Divider(height: 1),
                _buildSettingTile(
                  icon: Icons.replay_rounded,
                  title: 'Reset / Re-seed Demo Municipal Records',
                  subtitle: 'Debug Admin only: Restores demo pickups across Arua',
                  trailing: const Icon(Icons.delete_sweep_rounded, color: Color(0xFFC62828)),
                  onTap: () async {
                    final confirmed = await showDialog<bool>(
                      context: context,
                      builder: (ctx) => AlertDialog(
                        title: const Text('Reset Demo Records?'),
                        content: const Text(
                          'This will overwrite current local pickup requests with default municipal demo data. Continue?',
                        ),
                        actions: [
                          TextButton(
                            onPressed: () => Navigator.of(ctx).pop(false),
                            child: const Text('Cancel'),
                          ),
                          FilledButton(
                            onPressed: () => Navigator.of(ctx).pop(true),
                            style: FilledButton.styleFrom(backgroundColor: const Color(0xFFC62828)),
                            child: const Text('Reset'),
                          ),
                        ],
                      ),
                    );
                    if (confirmed == true) {
                      await widget.repository.seedDemoData(force: true);
                      widget.onRefreshOrders?.call();
                      if (context.mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('Demonstration instant collection orders restored.'),
                            backgroundColor: Color(0xFF2E7D32),
                          ),
                        );
                      }
                    }
                  },
                ),
              ],
            ],
          ),
          const SizedBox(height: 24),

          // Account Sign Out
          SizedBox(
            width: double.infinity,
            child: OutlinedButton.icon(
              onPressed: widget.onSignOut,
              style: OutlinedButton.styleFrom(
                foregroundColor: const Color(0xFFC62828),
                side: const BorderSide(color: Color(0xFFFFCDD2)),
                padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 13),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
              ),
              icon: const Icon(Icons.logout_rounded, size: 18),
              label: const Text('Sign out', style: TextStyle(fontWeight: FontWeight.w700)),
            ),
          ),
          const SizedBox(height: 18),
          const Text(
            'EcoRoute Arua v2.4.0 • Municipal Waste Logistics Platform',
            style: TextStyle(fontSize: 11, color: Color(0xFF8B9D90)),
          ),
        ],
      ),
    );
  }

  Widget _buildMetricCol(String label, String value, IconData icon, [Color? color]) {
    return Column(
      children: [
        Icon(icon, size: 18, color: color ?? const Color(0xFF556958)),
        const SizedBox(height: 4),
        Text(
          value,
          style: TextStyle(
            fontSize: 15,
            fontWeight: FontWeight.w800,
            color: color ?? const Color(0xFF183B20),
          ),
        ),
        const SizedBox(height: 2),
        Text(
          label,
          style: const TextStyle(fontSize: 11, color: Color(0xFF71877D)),
        ),
      ],
    );
  }

  Widget _buildMetricRow(String label, String value, Color color) {
    return Row(
      children: [
        Container(
          width: 8,
          height: 8,
          decoration: BoxDecoration(color: color, shape: BoxShape.circle),
        ),
        const SizedBox(width: 10),
        Text(
          label,
          style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: Color(0xFF333333)),
        ),
        const Spacer(),
        Text(
          value,
          style: TextStyle(fontSize: 15, fontWeight: FontWeight.w800, color: color),
        ),
      ],
    );
  }

  Widget _buildSettingsSection({
    required String title,
    required IconData icon,
    required List<Widget> items,
  }) {
    return Material(
      color: Colors.white,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
        side: const BorderSide(color: Color(0xFFE2EAE1)),
      ),
      clipBehavior: Clip.antiAlias,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 14, 16, 8),
            child: Row(
              children: [
                Icon(icon, size: 16, color: const Color(0xFF2E7D32)),
                const SizedBox(width: 8),
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w800,
                    color: Color(0xFF183B20),
                    letterSpacing: 0.3,
                  ),
                ),
              ],
            ),
          ),
          const Divider(height: 1),
          ...items,
        ],
      ),
    );
  }

  Widget _buildSettingTile({
    required IconData icon,
    required String title,
    required String subtitle,
    Widget? trailing,
    VoidCallback? onTap,
  }) {
    return Material(
      color: Colors.transparent,
      child: ListTile(
        leading: Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: const Color(0xFFF1F8F2),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Icon(icon, color: const Color(0xFF2E7D32), size: 18),
        ),
        title: Text(
          title,
          style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: Color(0xFF183B20)),
        ),
        subtitle: Text(
          subtitle,
          style: const TextStyle(fontSize: 11, color: Color(0xFF647568)),
        ),
        trailing: trailing,
        onTap: onTap,
      ),
    );
  }
}
