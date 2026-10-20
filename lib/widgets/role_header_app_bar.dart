import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/user_model.dart';
import '../providers/auth_provider.dart';
import '../theme/app_theme.dart';

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
    String roleLabel;
    IconData roleIcon;

    switch (user.role) {
      case UserRole.citizen:
        roleColor = AppTheme.primaryGreen;
        roleLabel = 'Citizen';
        roleIcon = Icons.person_rounded;
        break;
      case UserRole.rider:
        roleColor = const Color(0xFF0D6EFD);
        roleLabel = 'Rider';
        roleIcon = Icons.two_wheeler_rounded;
        break;
      case UserRole.admin:
        roleColor = const Color(0xFF6F42C1);
        roleLabel = 'Admin';
        roleIcon = Icons.admin_panel_settings_rounded;
        break;
    }

    return AppBar(
      title: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 18),
          ),
          Text(
            user.name,
            style: const TextStyle(fontSize: 11, color: AppTheme.textMuted),
          ),
        ],
      ),
      actions: [
        if (showRoleSwitcher)
          Padding(
            padding: const EdgeInsets.only(right: 8.0),
            child: ActionChip(
              avatar: Icon(roleIcon, size: 14, color: roleColor),
              label: Text(
                roleLabel,
                style: TextStyle(
                  color: roleColor,
                  fontWeight: FontWeight.w700,
                  fontSize: 12,
                ),
              ),
              backgroundColor: roleColor.withValues(alpha: 0.12),
              side: BorderSide(color: roleColor.withValues(alpha: 0.3)),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              onPressed: () => _showRoleDialog(context, authProvider),
            ),
          ),
        ...?actions,
      ],
    );
  }

  void _showRoleDialog(BuildContext context, AuthProvider auth) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Row(
          children: [
            Icon(Icons.swap_horiz_rounded, color: AppTheme.primaryGreen),
            SizedBox(width: 8),
            Text('Switch Persona'),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Switch between system roles to demonstrate the full end-to-end workflow:',
              style: TextStyle(fontSize: 13, color: AppTheme.textMuted),
            ),
            const SizedBox(height: 16),
            _roleTile(
              context: ctx,
              title: 'Citizen (Sarah Namukasa)',
              subtitle: 'Takes waste photo, auto GPS, schedules & pays cash',
              role: UserRole.citizen,
              color: AppTheme.primaryGreen,
              icon: Icons.person_rounded,
              currentRole: auth.currentRole,
              onTap: () {
                auth.switchRole(UserRole.citizen);
                Navigator.pop(ctx);
              },
            ),
            _roleTile(
              context: ctx,
              title: 'Rider / Collector (Alex Mukasa)',
              subtitle: 'Receives alerts, views GPS map, collects hard cash',
              role: UserRole.rider,
              color: const Color(0xFF0D6EFD),
              icon: Icons.two_wheeler_rounded,
              currentRole: auth.currentRole,
              onTap: () {
                auth.switchRole(UserRole.rider);
                Navigator.pop(ctx);
              },
            ),
            _roleTile(
              context: ctx,
              title: 'Admin / Dispatcher (Grace Atuhaire)',
              subtitle: 'Monitors incoming pickups, assigns riders & tracks cash',
              role: UserRole.admin,
              color: const Color(0xFF6F42C1),
              icon: Icons.admin_panel_settings_rounded,
              currentRole: auth.currentRole,
              onTap: () {
                auth.switchRole(UserRole.admin);
                Navigator.pop(ctx);
              },
            ),
          ],
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

  Widget _roleTile({
    required BuildContext context,
    required String title,
    required String subtitle,
    required UserRole role,
    required Color color,
    required IconData icon,
    required UserRole currentRole,
    required VoidCallback onTap,
  }) {
    final isSelected = currentRole == role;
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      decoration: BoxDecoration(
        color: isSelected ? color.withValues(alpha: 0.1) : Colors.transparent,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isSelected ? color : const Color(0xFFEEEEEE),
          width: isSelected ? 1.5 : 1,
        ),
      ),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: color.withValues(alpha: 0.15),
          child: Icon(icon, color: color, size: 20),
        ),
        title: Text(title, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14)),
        subtitle: Text(subtitle, style: const TextStyle(fontSize: 11)),
        trailing: isSelected ? Icon(Icons.check_circle, color: color, size: 18) : null,
        onTap: onTap,
      ),
    );
  }
}
