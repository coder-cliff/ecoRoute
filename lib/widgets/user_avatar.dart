import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import '../models/user_model.dart';
import '../theme/app_theme.dart';

class UserAvatar extends StatelessWidget {
  final AppUser? user;
  final String? name;
  final String? avatarUrl;
  final UserRole? role;
  final double radius;
  final bool showRoleBadge;
  final VoidCallback? onTap;
  final bool isEditable;

  const UserAvatar({
    super.key,
    this.user,
    this.name,
    this.avatarUrl,
    this.role,
    this.radius = 22,
    this.showRoleBadge = false,
    this.onTap,
    this.isEditable = false,
  });

  String get _displayName => user?.name ?? name ?? 'Eco User';
  String get _avatar => user?.avatarUrl ?? avatarUrl ?? '';
  UserRole get _role => user?.role ?? role ?? UserRole.citizen;

  Color get _roleColor {
    switch (_role) {
      case UserRole.citizen:
        return AppTheme.primaryGreen;
      case UserRole.rider:
        return const Color(0xFF0D6EFD);
      case UserRole.admin:
        return const Color(0xFF6F42C1);
    }
  }

  IconData get _roleIcon {
    switch (_role) {
      case UserRole.citizen:
        return Icons.eco_rounded;
      case UserRole.rider:
        return Icons.two_wheeler_rounded;
      case UserRole.admin:
        return Icons.admin_panel_settings_rounded;
    }
  }

  String get _initials {
    final parts = _displayName.trim().split(RegExp(r'\s+'));
    if (parts.isEmpty || parts[0].isEmpty) return 'U';
    if (parts.length == 1) return parts[0][0].toUpperCase();
    return '${parts[0][0]}${parts[1][0]}'.toUpperCase();
  }

  @override
  Widget build(BuildContext context) {
    final avatarWidget = InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(radius + 4),
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          Container(
            width: radius * 2,
            height: radius * 2,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(
                color: _roleColor.withValues(alpha: 0.8),
                width: 2,
              ),
              boxShadow: [
                BoxShadow(
                  color: _roleColor.withValues(alpha: 0.18),
                  blurRadius: 8,
                  offset: const Offset(0, 3),
                ),
              ],
            ),
            child: ClipOval(
              child: _buildAvatarContent(),
            ),
          ),
          if (showRoleBadge)
            Positioned(
              right: -2,
              bottom: -2,
              child: Container(
                padding: EdgeInsets.all(radius * 0.16),
                decoration: BoxDecoration(
                  color: _roleColor,
                  shape: BoxShape.circle,
                  border: Border.all(color: Colors.white, width: 1.5),
                ),
                child: Icon(
                  _roleIcon,
                  size: radius * 0.45,
                  color: Colors.white,
                ),
              ),
            ),
          if (isEditable)
            Positioned(
              right: -2,
              bottom: -2,
              child: Container(
                padding: const EdgeInsets.all(5),
                decoration: const BoxDecoration(
                  color: AppTheme.darkForest,
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.camera_alt_rounded,
                  size: 14,
                  color: Colors.white,
                ),
              ),
            ),
        ],
      ),
    );

    return avatarWidget;
  }

  Widget _buildAvatarContent() {
    final path = _avatar.trim();

    if (path.isEmpty) {
      return _buildInitials();
    }

    // Web Base64 Data URI DP
    if (path.startsWith('data:image')) {
      try {
        final bytes = base64Decode(path.split(',').last);
        return Image.memory(
          bytes,
          fit: BoxFit.cover,
          width: radius * 2,
          height: radius * 2,
          errorBuilder: (ctx, error, stackTrace) => _buildInitials(),
        );
      } catch (_) {
        return _buildInitials();
      }
    }

    // Network image DP
    if (path.startsWith('http://') || path.startsWith('https://')) {
      return Image.network(
        path,
        fit: BoxFit.cover,
        width: radius * 2,
        height: radius * 2,
        loadingBuilder: (ctx, child, progress) {
          if (progress == null) return child;
          return _buildInitials();
        },
        errorBuilder: (ctx, error, stackTrace) => _buildInitials(),
      );
    }

    // Local file from device camera or gallery
    if (!kIsWeb && File(path).existsSync()) {
      return Image.file(
        File(path),
        fit: BoxFit.cover,
        width: radius * 2,
        height: radius * 2,
        errorBuilder: (ctx, error, stackTrace) => _buildInitials(),
      );
    }

    // Vector preset avatar
    if (path.startsWith('preset:')) {
      return _buildPresetAvatar(path);
    }

    return _buildInitials();
  }

  Widget _buildInitials() {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            _roleColor.withValues(alpha: 0.8),
            _roleColor,
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      alignment: Alignment.center,
      child: Text(
        _initials,
        style: TextStyle(
          color: Colors.white,
          fontWeight: FontWeight.w800,
          fontSize: radius * 0.75,
        ),
      ),
    );
  }

  Widget _buildPresetAvatar(String presetKey) {
    IconData icon;
    Color bg;
    Color iconColor;

    switch (presetKey) {
      case 'preset:citizen_green':
        icon = Icons.person_rounded;
        bg = const Color(0xFFE8F5E9);
        iconColor = AppTheme.primaryGreen;
        break;
      case 'preset:citizen_teal':
        icon = Icons.emoji_nature_rounded;
        bg = const Color(0xFFE0F2F1);
        iconColor = const Color(0xFF00897B);
        break;
      case 'preset:rider_tricycle':
        icon = Icons.two_wheeler_rounded;
        bg = const Color(0xFFE3F2FD);
        iconColor = const Color(0xFF1E88E5);
        break;
      case 'preset:rider_courier':
        icon = Icons.local_shipping_rounded;
        bg = const Color(0xFFE1F5FE);
        iconColor = const Color(0xFF0288D1);
        break;
      case 'preset:admin_badge':
        icon = Icons.security_rounded;
        bg = const Color(0xFFEDE7F6);
        iconColor = const Color(0xFF6F42C1);
        break;
      case 'preset:admin_fleet':
        icon = Icons.hub_rounded;
        bg = const Color(0xFFF3E5F5);
        iconColor = const Color(0xFF8E24AA);
        break;
      default:
        icon = _roleIcon;
        bg = _roleColor.withValues(alpha: 0.15);
        iconColor = _roleColor;
    }

    return Container(
      color: bg,
      alignment: Alignment.center,
      child: Icon(icon, color: iconColor, size: radius * 1.05),
    );
  }
}
