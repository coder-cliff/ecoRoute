import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/user_model.dart';
import '../providers/auth_provider.dart';
import '../providers/notification_provider.dart';
import '../screens/common/interactive_map_screen.dart';
import '../screens/profile/profile_settings_screen.dart';
import '../theme/app_theme.dart';
import 'notification_center_modal.dart';
import 'user_avatar.dart';

class RoleHeaderAppBar extends StatelessWidget implements PreferredSizeWidget {
  final String title;
  final List<Widget>? actions;
  final bool showRoleBadge;

  const RoleHeaderAppBar({
    super.key,
    required this.title,
    this.actions,
    bool? showRoleBadge,
    bool? showRoleSwitcher,
  }) : showRoleBadge = showRoleBadge ?? showRoleSwitcher ?? true;

  @override
  Size get preferredSize => const Size.fromHeight(kToolbarHeight);

  @override
  Widget build(BuildContext context) {
    final authProvider = Provider.of<AuthProvider>(context);
    final user = authProvider.currentUser;

    Color roleColor;
    switch (user.role) {
      case UserRole.citizen:
        roleColor = AppTheme.primaryGreen;
        break;
      case UserRole.rider:
        roleColor = const Color(0xFF0D6EFD);
        break;
      case UserRole.admin:
        roleColor = const Color(0xFF6F42C1);
        break;
    }

    return AppBar(
      title: Row(
        children: [
          // Profile DP with tap to open profile settings
          UserAvatar(
            user: user,
            radius: 18,
            showRoleBadge: true,
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const ProfileSettingsScreen()),
              );
            },
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  title,
                  style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 16),
                  overflow: TextOverflow.ellipsis,
                ),
                Text(
                  user.name,
                  style: const TextStyle(fontSize: 11, color: AppTheme.textMuted),
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
        ],
      ),
      actions: [
        if (showRoleBadge)
          Padding(
            padding: const EdgeInsets.only(right: 6.0),
            child: Center(
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                decoration: BoxDecoration(
                  color: roleColor.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: roleColor.withValues(alpha: 0.3)),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      user.role == UserRole.admin
                          ? Icons.shield_rounded
                          : user.role == UserRole.rider
                              ? Icons.two_wheeler_rounded
                              : Icons.person_rounded,
                      size: 13,
                      color: roleColor,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      user.role.badgeLabel,
                      style: TextStyle(
                        color: roleColor,
                        fontWeight: FontWeight.w700,
                        fontSize: 11,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        // Live Waste Map Button
        IconButton(
          icon: const Icon(Icons.map_outlined, size: 20),
          tooltip: 'Live Waste Map',
          onPressed: () {
            Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const InteractiveMapScreen()),
            );
          },
        ),
        // Notification Bell with Badge
        Consumer<NotificationProvider>(
          builder: (ctx, notif, _) => Stack(
            alignment: Alignment.center,
            children: [
              IconButton(
                icon: const Icon(Icons.notifications_outlined, size: 20),
                tooltip: 'Notification Center',
                onPressed: () => NotificationCenterModal.show(context),
              ),
              if (notif.unreadCount > 0)
                Positioned(
                  right: 8,
                  top: 8,
                  child: Container(
                    padding: const EdgeInsets.all(3),
                    decoration: const BoxDecoration(
                      color: Colors.redAccent,
                      shape: BoxShape.circle,
                    ),
                    constraints: const BoxConstraints(minWidth: 14, minHeight: 14),
                    child: Text(
                      '${notif.unreadCount}',
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 8,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
            ],
          ),
        ),
        ...?actions,
      ],
    );
  }
}
