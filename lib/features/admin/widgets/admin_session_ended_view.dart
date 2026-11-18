import 'package:flutter/material.dart';

import '../../../core/pickup_request_repository.dart';
import '../../../core/services/auth_service.dart';
import '../../../core/services/router_service.dart';
import '../../../core/services/waste_api_service.dart';

class AdminSessionEndedView extends StatefulWidget {
  const AdminSessionEndedView({
    super.key,
    required this.repository,
    this.authService,
    this.wasteApiService,
    this.totalDispatches = 14,
    this.unresolvedAlerts = 2,
    this.auditEntriesCreated = 45,
    this.adminId = '#A-9014',
    this.onSignOutConfirmed,
  });

  final PickupRequestRepository repository;
  final AuthService? authService;
  final WasteApiService? wasteApiService;
  final int totalDispatches;
  final int unresolvedAlerts;
  final int auditEntriesCreated;
  final String adminId;
  final VoidCallback? onSignOutConfirmed;

  @override
  State<AdminSessionEndedView> createState() => _AdminSessionEndedViewState();
}

class _AdminSessionEndedViewState extends State<AdminSessionEndedView> {
  bool _isSigningOut = false;

  Future<void> _handleSignOut({required bool emergencyPause}) async {
    setState(() => _isSigningOut = true);
    try {
      final authService = widget.authService;
      if (authService != null) {
        await authService.logout();
      }
      if (widget.onSignOutConfirmed != null) {
        widget.onSignOutConfirmed!();
      } else if (mounted) {
        AppRouter.routeToLogin(
          context,
          repository: widget.repository,
          authService: widget.authService,
          wasteApiService: widget.wasteApiService,
        );
      }
    } finally {
      if (mounted) setState(() => _isSigningOut = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    const bgParchment = Color(0xFFECE7DE);
    const topBarBg = Color(0xFF1B2A32);
    const darkButtonBg = Color(0xFF1C2C34);
    final activeFor = widget.authService?.getFormattedShiftDuration() ?? '8h 12m';

    return Scaffold(
      backgroundColor: bgParchment,
      body: SafeArea(
        child: Column(
          children: [
            // Top Bar
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              color: topBarBg,
              child: Row(
                children: [
                  const Icon(Icons.eco_rounded, color: Color(0xFF7CB69D), size: 22),
                  const SizedBox(width: 8),
                  const Text(
                    'ecoRoute',
                    style: TextStyle(
                      fontFamily: 'Satoshi',
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                      color: Colors.white,
                    ),
                  ),
                  const Spacer(),
                  Flexible(
                    child: FittedBox(
                      fit: BoxFit.scaleDown,
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Text(
                            'Command HQ (Arua)',
                            style: TextStyle(
                              fontFamily: 'Satoshi',
                              fontSize: 12.5,
                              fontWeight: FontWeight.w600,
                              color: Color(0xFFBDC8C4),
                            ),
                          ),
                          const SizedBox(width: 6),
                          Container(
                            width: 7,
                            height: 7,
                            decoration: const BoxDecoration(
                              color: Color(0xFF8B9B9E),
                              shape: BoxShape.circle,
                            ),
                          ),
                          const SizedBox(width: 4),
                          const Text(
                            'Offline',
                            style: TextStyle(
                              fontFamily: 'Satoshi',
                              fontSize: 11,
                              color: Color(0xFF8B9B9E),
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),

            Expanded(
              child: Center(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 480),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        // Title
                        const Center(
                          child: Text(
                            'Session Ended',
                            style: TextStyle(
                              fontFamily: 'Satoshi',
                              fontSize: 26,
                              fontWeight: FontWeight.w800,
                              color: Color(0xFF1B2A32),
                              letterSpacing: -0.3,
                            ),
                          ),
                        ),
                        const SizedBox(height: 24),

                        // Active Session Card
                        Container(
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: const Color(0xFFE5DFC9),
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(color: const Color(0xFFD6CEB5)),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Row(
                                children: [
                                  Icon(Icons.lock_clock_outlined, size: 16, color: Color(0xFF1B2A32)),
                                  SizedBox(width: 6),
                                  Expanded(
                                    child: Text(
                                      'Active Session Found • Arua Command HQ',
                                      style: TextStyle(
                                        fontFamily: 'Satoshi',
                                        fontSize: 13,
                                        fontWeight: FontWeight.w700,
                                        color: Color(0xFF1B2A32),
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 10),
                              Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  Expanded(
                                    child: Text(
                                      'Admin ID: ${widget.adminId}',
                                      style: const TextStyle(
                                        fontFamily: 'Satoshi',
                                        fontSize: 14,
                                        fontWeight: FontWeight.w800,
                                        color: Color(0xFF1B2A32),
                                      ),
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  Text(
                                    'Active for: $activeFor',
                                    style: const TextStyle(
                                      fontFamily: 'Satoshi',
                                      fontSize: 13,
                                      fontWeight: FontWeight.w600,
                                      color: Color(0xFF3B4F55),
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 16),

                        // Session Activity Summary Card
                        Container(
                          padding: const EdgeInsets.all(18),
                          decoration: BoxDecoration(
                            color: const Color(0xFFE5DFC9),
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(color: const Color(0xFFD6CEB5)),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                'Session Activity Summary',
                                style: TextStyle(
                                  fontFamily: 'Satoshi',
                                  fontSize: 15,
                                  fontWeight: FontWeight.w800,
                                  color: Color(0xFF1B2A32),
                                ),
                              ),
                              const SizedBox(height: 14),
                              _buildSummaryRow('Total Dispatches:', '${widget.totalDispatches}'),
                              const SizedBox(height: 10),
                              _buildSummaryRow('Unresolved Alerts:', '${widget.unresolvedAlerts}'),
                              const SizedBox(height: 10),
                              _buildSummaryRow('Audit Entries Created:', '${widget.auditEntriesCreated}'),
                              const SizedBox(height: 20),

                              // Button 1: Finalize Day Ledger & Sign Out
                              SizedBox(
                                width: double.infinity,
                                height: 48,
                                child: FilledButton(
                                  key: const ValueKey('finalize_day_ledger_button'),
                                  onPressed: _isSigningOut ? null : () => _handleSignOut(emergencyPause: false),
                                  style: FilledButton.styleFrom(
                                    backgroundColor: darkButtonBg,
                                    foregroundColor: Colors.white,
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                  ),
                                  child: const Text(
                                    'Finalize Day Ledger & Sign Out',
                                    style: TextStyle(
                                      fontFamily: 'Satoshi',
                                      fontSize: 14.5,
                                      fontWeight: FontWeight.w700,
                                    ),
                                  ),
                                ),
                              ),
                              const SizedBox(height: 12),

                              // Button 2: Emergency Pause & Sign Out
                              SizedBox(
                                width: double.infinity,
                                height: 48,
                                child: OutlinedButton(
                                  key: const ValueKey('emergency_pause_button'),
                                  onPressed: _isSigningOut ? null : () => _handleSignOut(emergencyPause: true),
                                  style: OutlinedButton.styleFrom(
                                    foregroundColor: darkButtonBg,
                                    side: const BorderSide(color: Color(0xFF8B9B9E), width: 1.2),
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                  ),
                                  child: const Text(
                                    'Emergency Pause & Sign Out',
                                    style: TextStyle(
                                      fontFamily: 'Satoshi',
                                      fontSize: 14.5,
                                      fontWeight: FontWeight.w700,
                                    ),
                                  ),
                                ),
                              ),

                              // Standard Sign out text button (for backward compatibility with existing tests)
                              Center(
                                child: TextButton(
                                  onPressed: _isSigningOut ? null : () => _handleSignOut(emergencyPause: false),
                                  child: const Text(
                                    'Sign out',
                                    style: TextStyle(
                                      fontFamily: 'Satoshi',
                                      fontSize: 13,
                                      fontWeight: FontWeight.w600,
                                      color: Color(0xFF1B2A32),
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 16),

                        // Resume Active Shift option
                        Center(
                          child: TextButton.icon(
                            onPressed: () => Navigator.of(context).maybePop(),
                            icon: const Icon(Icons.arrow_back_rounded, size: 16, color: Color(0xFF2E6B4A)),
                            label: const Text(
                              'Resume Active Shift',
                              style: TextStyle(
                                fontFamily: 'Satoshi',
                                fontSize: 13.5,
                                fontWeight: FontWeight.w700,
                                color: Color(0xFF2E6B4A),
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(height: 24),

                        // Footer text
                        const Center(
                          child: Text(
                            'Log secure sign-out timestamp.\nA confirmation SMS will be sent to #4256...',
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              fontFamily: 'Satoshi',
                              fontSize: 11.5,
                              color: Color(0xFF6F7E78),
                              height: 1.35,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSummaryRow(String label, String value) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Expanded(
          child: Text(
            label,
            style: const TextStyle(
              fontFamily: 'Satoshi',
              fontSize: 13.5,
              fontWeight: FontWeight.w600,
              color: Color(0xFF2C3E45),
            ),
          ),
        ),
        const SizedBox(width: 8),
        Text(
          value,
          style: const TextStyle(
            fontFamily: 'Satoshi',
            fontSize: 14,
            fontWeight: FontWeight.w800,
            color: Color(0xFF1B2A32),
          ),
        ),
      ],
    );
  }
}
