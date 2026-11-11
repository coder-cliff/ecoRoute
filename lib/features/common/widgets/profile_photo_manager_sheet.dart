import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import '../../../main.dart';

/// WhatsApp-style Profile Photo Management Bottom Sheet.
/// Allows users, riders, and admins to:
/// 1. View full photo preview
/// 2. Take a new photo with camera
/// 3. Upload from gallery
/// 4. Delete/remove photo (reverting to clean initials avatar)
Future<void> showProfilePhotoManagerSheet(BuildContext context) async {
  final state = EcoRouteState.instance;
  final isDark = state.isDarkMode;
  final hasPhoto = state.userPhotoBase64 != null && state.userPhotoBase64!.isNotEmpty;

  await showModalBottomSheet<void>(
    context: context,
    backgroundColor: isDark ? const Color(0xFF1E293B) : Colors.white,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
    ),
    builder: (ctx) {
      return StatefulBuilder(
        builder: (context, setSheetState) {
          final currentPhoto = state.userPhotoBase64;
          final currentHasPhoto = currentPhoto != null && currentPhoto.isNotEmpty;

          return SafeArea(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Handle bar
                  Container(
                    width: 40,
                    height: 4,
                    decoration: BoxDecoration(
                      color: isDark ? Colors.white24 : Colors.black12,
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Header with Close
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Profile Photo',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: isDark ? Colors.white : const Color(0xFF1E293B),
                        ),
                      ),
                      IconButton(
                        icon: const Icon(Icons.close),
                        onPressed: () => Navigator.pop(ctx),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),

                  // Large Avatar Preview
                  Center(
                    child: Container(
                      width: 120,
                      height: 120,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: const Color(0xFF2E7D32).withOpacity(0.12),
                        border: Border.all(
                          color: const Color(0xFF2E7D32),
                          width: 2.5,
                        ),
                      ),
                      child: ClipOval(
                        child: currentHasPhoto
                            ? _buildImageFromBase64(currentPhoto!)
                            : Center(
                                child: Text(
                                  state.userName.isNotEmpty
                                      ? state.userName[0].toUpperCase()
                                      : 'U',
                                  style: const TextStyle(
                                    fontSize: 48,
                                    fontWeight: FontWeight.bold,
                                    color: Color(0xFF2E7D32),
                                  ),
                                ),
                              ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 28),

                  // Action Row: Camera, Gallery, Delete (WhatsApp Style)
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      // Camera
                      _buildActionButton(
                        context: context,
                        icon: Icons.camera_alt,
                        label: 'Camera',
                        color: const Color(0xFF2E7D32),
                        onTap: () async {
                          Navigator.pop(ctx);
                          await _pickAndSavePhoto(ImageSource.camera, context);
                        },
                      ),

                      // Gallery
                      _buildActionButton(
                        context: context,
                        icon: Icons.photo_library,
                        label: 'Gallery',
                        color: const Color(0xFF2E7D32),
                        onTap: () async {
                          Navigator.pop(ctx);
                          await _pickAndSavePhoto(ImageSource.gallery, context);
                        },
                      ),

                      // Remove / Delete (WhatsApp Style Trash)
                      _buildActionButton(
                        context: context,
                        icon: Icons.delete_outline,
                        label: 'Remove',
                        color: currentHasPhoto ? Colors.redAccent : Colors.grey,
                        onTap: currentHasPhoto
                            ? () async {
                                Navigator.pop(ctx);
                                _confirmPhotoDeletion(context);
                              }
                            : null,
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                ],
              ),
            ),
          );
        },
      );
    },
  );
}

Widget _buildActionButton({
  required BuildContext context,
  required IconData icon,
  required String label,
  required Color color,
  required VoidCallback? onTap,
}) {
  return InkWell(
    onTap: onTap,
    borderRadius: BorderRadius.circular(16),
    child: Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 52,
            height: 52,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: color.withOpacity(0.12),
              border: Border.all(color: color.withOpacity(0.3), width: 1.2),
            ),
            child: Icon(icon, color: color, size: 24),
          ),
          const SizedBox(height: 8),
          Text(
            label,
            style: TextStyle(
              fontSize: 12.5,
              fontWeight: FontWeight.w600,
              color: onTap == null ? Colors.grey : color,
            ),
          ),
        ],
      ),
    ),
  );
}

Widget _buildImageFromBase64(String base64Str) {
  try {
    String clean = base64Str;
    if (clean.contains(',')) {
      clean = clean.split(',').last;
    }
    final bytes = base64Decode(clean);
    return Image.memory(
      bytes,
      fit: BoxFit.cover,
      width: 120,
      height: 120,
      errorBuilder: (_, __, ___) => const Icon(Icons.person, size: 48, color: Color(0xFF2E7D32)),
    );
  } catch (_) {
    return const Icon(Icons.person, size: 48, color: Color(0xFF2E7D32));
  }
}

Future<void> _pickAndSavePhoto(ImageSource source, BuildContext context) async {
  try {
    final picker = ImagePicker();
    final xfile = await picker.pickImage(
      source: source,
      maxWidth: 512,
      maxHeight: 512,
      imageQuality: 70,
    );
    if (xfile == null) return;

    final bytes = await xfile.readAsBytes();
    final base64String = base64Encode(bytes);
    EcoRouteState.instance.setProfilePhoto(base64String);

    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Profile photo updated successfully.'),
          backgroundColor: Color(0xFF2E7D32),
          duration: Duration(seconds: 2),
        ),
      );
    }
  } catch (e) {
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to update photo: $e'),
          backgroundColor: const Color(0xFF991B1B),
        ),
      );
    }
  }
}

void _confirmPhotoDeletion(BuildContext context) {
  showDialog<void>(
    context: context,
    builder: (ctx) {
      return AlertDialog(
        title: const Text('Remove profile photo?'),
        content: const Text('Your profile photo will be deleted and reset to your initials avatar.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel'),
          ),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: Colors.redAccent),
            onPressed: () {
              Navigator.pop(ctx);
              EcoRouteState.instance.deleteProfilePhoto();
              if (context.mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Profile photo removed.'),
                    backgroundColor: Color(0xFF1E293B),
                    duration: Duration(seconds: 2),
                  ),
                );
              }
            },
            child: const Text('Remove'),
          ),
        ],
      );
    },
  );
}
