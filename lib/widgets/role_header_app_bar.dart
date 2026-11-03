import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/user_model.dart';
import '../providers/auth_provider.dart';
import '../providers/notification_provider.dart';
import '../screens/auth/login_screen.dart';
import '../screens/auth/register_screen.dart';
import '../screens/common/interactive_map_screen.dart';
import '../screens/profile/profile_settings_screen.dart';
import '../theme/app_theme.dart';
import 'notification_center_modal.dart';
import 'user_avatar.dart';

class RoleHeaderAppBar extends StatelessWidget implements PreferredSizeWidget {
  final String title;
  final List<Widget>? actions;
  final bool showRoleSwitcher;

  const RoleHeaderAppBar({
    super.key,
    required this.title,
    this.actions,
    this.showRoleSwitcher = true,
  });

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
        if (showRoleSwitcher)
          Padding(
            padding: const EdgeInsets.only(right: 4.0),
            child: ActionChip(
              avatar: const Icon(Icons.swap_horiz_rounded, size: 14),
              label: Text(
                user.role.badgeLabel,
                style: TextStyle(
                  color: roleColor,
                  fontWeight: FontWeight.w700,
                  fontSize: 11,
                ),
              ),
              backgroundColor: roleColor.withValues(alpha: 0.12),
              side: BorderSide(color: roleColor.withValues(alpha: 0.3)),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              onPressed: () => _showAccountSwitcherDialog(context, authProvider),
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

  void _showAccountSwitcherDialog(BuildContext context, AuthProvider auth) {
    final users = auth.allUsers;

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Row(
          children: [
            Icon(Icons.switch_account_rounded, color: AppTheme.primaryGreen),
            SizedBox(width: 8),
            Text('Switch Account & Role'),
          ],
        ),
        content: SizedBox(
          width: double.maxFinite,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Select an active profile or register a new user:',
                style: TextStyle(fontSize: 12, color: AppTheme.textMuted),
              ),
              const SizedBox(height: 12),
              Flexible(
                child: ListView.builder(
                  shrinkWrap: true,
                  itemCount: users.length,
                  itemBuilder: (context, index) {
                    final u = users[index];
                    final isSelected = u.id == auth.currentUser.id;

                    return Container(
                      margin: const EdgeInsets.only(bottom: 6),
                      decoration: BoxDecoration(
                        color: isSelected ? AppTheme.accentMint.withValues(alpha: 0.3) : Colors.transparent,
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(
                          color: isSelected ? AppTheme.primaryGreen : const Color(0xFFEEEEEE),
                        ),
                      ),
                      child: ListTile(
                        dense: true,
                        leading: UserAvatar(user: u, radius: 16, showRoleBadge: true),
                        title: Text(u.name, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13)),
                        subtitle: Text(u.role.displayName, style: const TextStyle(fontSize: 10)),
                        trailing: isSelected ? const Icon(Icons.check, color: AppTheme.primaryGreen, size: 16) : null,
                        onTap: () {
                          auth.switchUser(u.id);
                          Navigator.pop(ctx);
                        },
                      ),
                    );
                  },
                ),
              ),
              const Divider(),
              ListTile(
                dense: true,
                leading: const Icon(Icons.person_add_alt_1_rounded, color: AppTheme.primaryGreen),
                title: const Text('Register New User', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                onTap: () {
                  Navigator.pop(ctx);
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => const RegisterScreen()),
                  );
                },
              ),
              ListTile(
                dense: true,
                leading: const Icon(Icons.manage_accounts_rounded, color: Color(0xFF0D6EFD)),
                title: const Text('Manage Accounts / Sign Out', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                onTap: () {
                  Navigator.pop(ctx);
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => const LoginScreen()),
                  );
                },
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }
}
