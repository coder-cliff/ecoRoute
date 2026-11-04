import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../core/pickup_request_repository.dart';
import '../../core/services/auth_service.dart';
import '../../core/services/router_service.dart';
import '../../core/services/waste_api_service.dart';
import '../../core/theme/eco_palette.dart';
import '../../domain/enums/role.dart';
import 'login_screen.dart';
import 'splash_screen.dart';

/// 02_ROLE_SELECT Screen: Welcome to EcoRoute with high-contrast role portals
class RoleSelectScreen extends StatefulWidget {
  const RoleSelectScreen({
    super.key,
    required this.repository,
    this.authService,
    this.wasteApiService,
  });

  final PickupRequestRepository repository;
  final AuthService? authService;
  final WasteApiService? wasteApiService;

  @override
  State<RoleSelectScreen> createState() => _RoleSelectScreenState();
}

class _RoleSelectScreenState extends State<RoleSelectScreen> {
  AppRole _selectedRole = AppRole.resident;

  void _handleContinue() {
    HapticFeedback.mediumImpact();
    AppRouter.routeToRole(
      context,
      role: _selectedRole,
      repository: widget.repository,
      authService: widget.authService,
      wasteApiService: widget.wasteApiService,
    );
  }

  void _navigateToLogin() {
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => LoginScreen(
          repository: widget.repository,
          authService: widget.authService,
          wasteApiService: widget.wasteApiService,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: const SystemUiOverlayStyle(
        statusBarColor: EcoPalette.surface,
        statusBarIconBrightness: Brightness.dark,
        statusBarBrightness: Brightness.light,
        systemNavigationBarColor: EcoPalette.surface,
        systemNavigationBarIconBrightness: Brightness.dark,
        systemNavigationBarDividerColor: Colors.transparent,
      ),
      child: Scaffold(
        backgroundColor: EcoPalette.surface,
        body: SafeArea(
          child: Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 420),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    const SizedBox(height: 10),
                    // Centered branding
                    const Center(
                      child: Column(
                        children: [
                          EcoRouteLeafLogo(size: 64, color: EcoPalette.primaryDark),
                          SizedBox(height: 10),
                          Text(
                            'EcoRoute',
                            style: TextStyle(
                              fontFamily: 'Satoshi',
                              fontSize: 26,
                              fontWeight: FontWeight.w800,
                              color: EcoPalette.primaryDark,
                              letterSpacing: -0.3,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 28),

                    // Welcome title
                    const Text(
                      'Welcome to\nEcoRoute',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontFamily: 'Satoshi',
                        fontSize: 32,
                        fontWeight: FontWeight.w900,
                        color: EcoPalette.primaryDark,
                        height: 1.15,
                        letterSpacing: -0.5,
                      ),
                    ),
                    const SizedBox(height: 8),
                    const Text(
                      'Select your operational workspace to continue',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontFamily: 'Satoshi',
                        fontSize: 14,
                        color: EcoPalette.secondaryDark,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    const SizedBox(height: 32),

                    // 1. Resident Card
                    _RoleOptionCard(
                      key: const ValueKey('role_card_resident'),
                      title: 'Resident',
                      subtitle: 'Book waste pickups, track riders & earn eco rewards',
                      icon: Icons.home_rounded,
                      isSelected: _selectedRole == AppRole.resident,
                      onTap: () => setState(() => _selectedRole = AppRole.resident),
                    ),
                    const SizedBox(height: 14),

                    // 2. Rider Card
                    _RoleOptionCard(
                      key: const ValueKey('role_card_rider'),
                      title: 'Rider',
                      subtitle: 'Navigate routes, collect sacks & track earnings',
                      icon: Icons.two_wheeler_rounded,
                      isSelected: _selectedRole == AppRole.rider,
                      onTap: () => setState(() => _selectedRole = AppRole.rider),
                    ),
                    const SizedBox(height: 14),

                    // 3. Admin Card
                    _RoleOptionCard(
                      key: const ValueKey('role_card_admin'),
                      title: 'Admin',
                      subtitle: 'Dispatch fleet, monitor KPIs & audit operations',
                      icon: Icons.shield_outlined,
                      isSelected: _selectedRole == AppRole.admin,
                      onTap: () => setState(() => _selectedRole = AppRole.admin),
                    ),
                    const SizedBox(height: 32),

                    // Continue button
                    SizedBox(
                      height: 52,
                      child: FilledButton(
                        key: const ValueKey('role_continue_button'),
                        onPressed: _handleContinue,
                        style: FilledButton.styleFrom(
                          backgroundColor: EcoPalette.buttonDark,
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(14),
                          ),
                          elevation: 0,
                        ),
                        child: const Text(
                          'Continue',
                          style: TextStyle(
                            fontFamily: 'Satoshi',
                            fontSize: 16,
                            fontWeight: FontWeight.w700,
                            letterSpacing: 0.2,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 24),

                    // Alternative Sign-In Portal link
                    Center(
                      child: TextButton.icon(
                        key: const ValueKey('role_switch_to_login'),
                        onPressed: _navigateToLogin,
                        icon: const Icon(
                          Icons.lock_outline_rounded,
                          size: 16,
                          color: EcoPalette.primaryDark,
                        ),
                        label: const Text(
                          'Sign in with email & password',
                          style: TextStyle(
                            fontFamily: 'Satoshi',
                            fontSize: 13.5,
                            fontWeight: FontWeight.w700,
                            color: EcoPalette.primaryDark,
                            decoration: TextDecoration.underline,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _RoleOptionCard extends StatelessWidget {
  const _RoleOptionCard({
    super.key,
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.isSelected,
    required this.onTap,
  });

  final String title;
  final String subtitle;
  final IconData icon;
  final bool isSelected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: isSelected ? EcoPalette.primaryDark : EcoPalette.cardBorder,
              width: isSelected ? 2.0 : 1.0,
            ),
            boxShadow: isSelected
                ? [
                    BoxShadow(
                      color: EcoPalette.primaryDark.withValues(alpha: 0.08),
                      blurRadius: 10,
                      offset: const Offset(0, 4),
                    ),
                  ]
                : null,
          ),
          child: Row(
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: isSelected
                      ? EcoPalette.surface
                      : EcoPalette.chipBackground,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  icon,
                  size: 24,
                  color: isSelected
                      ? EcoPalette.primaryDark
                      : EcoPalette.secondaryDark,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: TextStyle(
                        fontFamily: 'Satoshi',
                        fontSize: 17,
                        fontWeight: isSelected ? FontWeight.w800 : FontWeight.w700,
                        color: EcoPalette.primaryDark,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      subtitle,
                      style: const TextStyle(
                        fontFamily: 'Satoshi',
                        fontSize: 12,
                        color: Color(0xFF63786B),
                        height: 1.25,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              Container(
                width: 20,
                height: 20,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: isSelected
                        ? EcoPalette.primaryDark
                        : const Color(0xFFB0BFB5),
                    width: isSelected ? 6.0 : 1.5,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
