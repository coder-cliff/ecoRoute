import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../models/user_model.dart';
import '../../providers/auth_provider.dart';
import '../../theme/app_theme.dart';
import '../../widgets/user_avatar.dart';
import 'register_screen.dart';

class LoginScreen extends StatelessWidget {
  const LoginScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final auth = Provider.of<AuthProvider>(context);
    final users = auth.allUsers;

    return Scaffold(
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // App Logo & Branding
                Container(
                  padding: const EdgeInsets.all(18),
                  decoration: BoxDecoration(
                    color: AppTheme.accentMint,
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: AppTheme.primaryGreen.withValues(alpha: 0.15),
                        blurRadius: 20,
                        offset: const Offset(0, 10),
                      ),
                    ],
                  ),
                  child: const Icon(
                    Icons.delete_sweep_rounded,
                    size: 56,
                    color: AppTheme.primaryGreen,
                  ),
                ),
                const SizedBox(height: 18),
                const Text(
                  'EcoRoute',
                  style: TextStyle(
                    fontSize: 30,
                    fontWeight: FontWeight.w900,
                    color: AppTheme.darkForest,
                    letterSpacing: -0.5,
                  ),
                ),
                const SizedBox(height: 4),
                const Text(
                  'On-Demand Community Waste Collection',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 13,
                    color: AppTheme.textMuted,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 28),

                // Existing Accounts Section
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(20.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Row(
                          children: [
                            const Text(
                              'Select Profile Account',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w700,
                                color: AppTheme.textDark,
                              ),
                            ),
                            const Spacer(),
                            Text(
                              '${users.length} Registered',
                              style: const TextStyle(fontSize: 11, color: AppTheme.textMuted),
                            ),
                          ],
                        ),
                        const SizedBox(height: 6),
                        const Text(
                          'Each account has an individual display picture (DP) and specific role:',
                          style: TextStyle(fontSize: 12, color: AppTheme.textMuted),
                        ),
                        const SizedBox(height: 16),

                        if (users.isEmpty)
                          const Padding(
                            padding: EdgeInsets.symmetric(vertical: 20),
                            child: Center(
                              child: Text('No accounts registered yet.'),
                            ),
                          )
                        else
                          ...users.map(
                            (u) => Container(
                              margin: const EdgeInsets.only(bottom: 10),
                              decoration: BoxDecoration(
                                color: auth.currentUser.id == u.id
                                    ? AppTheme.accentMint.withValues(alpha: 0.4)
                                    : Colors.white,
                                borderRadius: BorderRadius.circular(14),
                                border: Border.all(
                                  color: auth.currentUser.id == u.id
                                      ? AppTheme.primaryGreen
                                      : const Color(0xFFEEEEEE),
                                  width: auth.currentUser.id == u.id ? 1.5 : 1,
                                ),
                              ),
                              child: ListTile(
                                leading: UserAvatar(
                                  user: u,
                                  radius: 22,
                                  showRoleBadge: true,
                                ),
                                title: Text(
                                  u.name,
                                  style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 14),
                                ),
                                subtitle: Text(
                                  '${u.role.displayName} • ${u.phone}',
                                  style: const TextStyle(fontSize: 11, color: AppTheme.textMuted),
                                ),
                                trailing: auth.currentUser.id == u.id
                                    ? const Icon(Icons.check_circle_rounded, color: AppTheme.primaryGreen)
                                    : const Icon(Icons.arrow_forward_ios_rounded, size: 14, color: AppTheme.textMuted),
                                onTap: () async {
                                  await auth.switchUser(u.id);
                                  if (context.mounted) {
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      SnackBar(
                                        content: Text('Switched to ${u.name} (${u.role.displayName})'),
                                        duration: const Duration(seconds: 1),
                                      ),
                                    );
                                  }
                                },
                              ),
                            ),
                          ),

                        const SizedBox(height: 12),
                        OutlinedButton.icon(
                          onPressed: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(builder: (_) => const RegisterScreen()),
                            );
                          },
                          icon: const Icon(Icons.person_add_alt_1_rounded),
                          label: const Text('Create New User Account'),
                        ),
                      ],
                    ),
                  ),
                ),

                const SizedBox(height: 20),
                // Footer
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  decoration: BoxDecoration(
                    color: AppTheme.cashGoldLight,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.payments_rounded, size: 16, color: AppTheme.cashGold),
                      SizedBox(width: 8),
                      Text(
                        'Direct hard cash payment settled upon physical waste collection',
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                          color: Color(0xFF664D03),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
