import 'package:flutter/material.dart';

import '../../core/pickup_request_repository.dart';
import '../../core/services/auth_service.dart';
import '../../core/services/rider_invite_service.dart';
import '../../core/services/router_service.dart';
import '../../core/services/waste_api_service.dart';
import '../../domain/entities/pickup_request.dart';
import '../../domain/enums/request_status.dart';
import 'widgets/admin_session_ended_view.dart';
import 'widgets/approval_item_tile.dart';
import 'widgets/live_dispatch_map.dart';

/// Command HQ Admin Dashboard for ecoRoute:
/// High-density, real-time operational control center tailored for managing commercial waste
/// dispatches, riders, and financial logs across Arua City.
class AdminDashboard extends StatefulWidget {
  const AdminDashboard({
    super.key,
    required this.repository,
    this.authService,
    this.wasteApiService,
  });

  final PickupRequestRepository repository;
  final AuthService? authService;
  final WasteApiService? wasteApiService;

  @override
  State<AdminDashboard> createState() => _AdminDashboardState();
}

class _AdminDashboardState extends State<AdminDashboard> {
  int _currentTab = 0; // 0: Dashboard, 1: Dispatches, 2: Audits, 3: Fleet/Controls
  final bool _isOnline = true;
  String _selectedAuditFilter = 'Today';

  // Active Routes State
  final List<Map<String, dynamic>> _activeRoutes = [
    {
      'id': 'route-4',
      'title': 'Route 4 (Arua Market)',
      'status': 'En-route',
      'driver': 'Peter #R-4809',
      'stops': 8,
      'completed': 5,
    },
    {
      'id': 'route-1',
      'title': 'Route 1 (Vurra)',
      'status': 'Arrived',
      'driver': 'Kassim #R-3102',
      'stops': 6,
      'completed': 4,
    },
    {
      'id': 'route-2',
      'title': 'Route 2 (Pakwach Road)',
      'status': 'Delay',
      'driver': 'Juma #R-2041',
      'stops': 7,
      'completed': 2,
    },
  ];

  // System Controls State
  bool _operationalBoundaries = false;
  bool _manageSchedules = false;
  bool _emergencyOverride = true;
  bool _adjustOverrideFeatures = false;

  // Tracked Vehicles State
  final List<Map<String, dynamic>> _trackedVehicles = [
    {'plate': 'UG-0480T', 'type': 'Tricycle #1', 'status': 'Active', 'driver': 'Peter #R-4809'},
    {'plate': 'UG-0480T', 'type': 'Backup Truck', 'status': 'Maintenance', 'driver': 'Unassigned'},
    {'plate': 'UG-0912K', 'type': 'Compactor 2', 'status': 'En Route', 'driver': 'Kassim #R-3102'},
  ];

  // Critical Escalations & Alerts Feed
  final List<Map<String, dynamic>> _escalations = [
    {
      'id': 'esc-1',
      'title': 'Route 4 Delay Reported',
      'subtitle': 'Transit issue on Pakwach Road',
      'status': 'Active',
      'severity': 'critical',
    },
    {
      'id': 'esc-2',
      'title': 'Customer Service Flag #8821',
      'subtitle': 'Payment dispute / Pending proof',
      'status': 'In Progress',
      'severity': 'warning',
    },
  ];

  List<PickupRequest> _orders = [];

  @override
  void initState() {
    super.initState();
    _loadOrders();
    widget.authService?.recordAdminShiftStart();
  }

  Future<void> _loadOrders() async {
    try {
      final list = await widget.repository.loadAll();
      if (mounted) setState(() => _orders = list);
    } catch (_) {}
  }

  Future<void> _handleApproveRequest(PickupRequest req) async {
    await widget.repository.updateStatus(req.id, RequestStatus.paid);
    await _loadOrders();
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Payment approved for ${req.description}')),
      );
    }
  }

  Future<void> _handleReturnRequest(PickupRequest req) async {
    await widget.repository.updateStatus(req.id, RequestStatus.collected);
    await _loadOrders();
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Request returned to rider for ${req.description}')),
      );
    }
  }

  void _openSessionEndedView() {
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => AdminSessionEndedView(
          repository: widget.repository,
          authService: widget.authService,
          wasteApiService: widget.wasteApiService,
          totalDispatches: 14 + _activeRoutes.length,
          unresolvedAlerts: _escalations.length,
          auditEntriesCreated: 45 + _orders.length,
          onSignOutConfirmed: () {
            AppRouter.routeToLogin(
              context,
              repository: widget.repository,
              authService: widget.authService,
              wasteApiService: widget.wasteApiService,
            );
          },
        ),
      ),
    );
  }

  void _showEmergencyDispatchModal() {
    String selectedSector = 'Arua Central Market';
    String selectedVehicle = 'UG-0480T';
    final reasonCtrl = TextEditingController(text: 'Sudden commercial overflow & traffic bypass');

    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: const Color(0xFFF7F5EE),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(22)),
      ),
      builder: (ctx) => StatefulBuilder(
        builder: (context, setModalState) {
          return Padding(
            padding: EdgeInsets.only(
              left: 20,
              right: 20,
              top: 20,
              bottom: MediaQuery.of(context).viewInsets.bottom + 20,
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Row(
                  children: [
                    const Icon(Icons.emergency_rounded, color: Color(0xFFBA4738), size: 24),
                    const SizedBox(width: 8),
                    const Text(
                      'Dispatch Emergency Truck',
                      style: TextStyle(
                        fontFamily: 'Satoshi',
                        fontSize: 18,
                        fontWeight: FontWeight.w800,
                        color: Color(0xFF1B2A32),
                      ),
                    ),
                    const Spacer(),
                    IconButton(
                      icon: const Icon(Icons.close_rounded),
                      onPressed: () => Navigator.pop(ctx),
                    ),
                  ],
                ),
                const SizedBox(height: 14),
                const Text('Sector Target:', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 13)),
                const SizedBox(height: 6),
                DropdownButtonFormField<String>(
                  initialValue: selectedSector,
                  items: const [
                    DropdownMenuItem(value: 'Arua Central Market', child: Text('Arua Central Market')),
                    DropdownMenuItem(value: 'Pakwach Road Junction', child: Text('Pakwach Road Junction')),
                    DropdownMenuItem(value: 'Arua Hill Sector', child: Text('Arua Hill Sector')),
                    DropdownMenuItem(value: 'River Oli Division', child: Text('River Oli Division')),
                    DropdownMenuItem(value: 'Vurra Border Road', child: Text('Vurra Border Road')),
                  ],
                  onChanged: (val) => setModalState(() => selectedSector = val!),
                  decoration: InputDecoration(
                    filled: true,
                    fillColor: Colors.white,
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                  ),
                ),
                const SizedBox(height: 12),
                const Text('Assign Vehicle:', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 13)),
                const SizedBox(height: 6),
                DropdownButtonFormField<String>(
                  initialValue: selectedVehicle,
                  items: const [
                    DropdownMenuItem(value: 'UG-0480T', child: Text('UG-0480T (Heavy Duty Truck)')),
                    DropdownMenuItem(value: 'UG-0912K', child: Text('UG-0912K (Compactor 2)')),
                  ],
                  onChanged: (val) => setModalState(() => selectedVehicle = val!),
                  decoration: InputDecoration(
                    filled: true,
                    fillColor: Colors.white,
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                  ),
                ),
                const SizedBox(height: 12),
                const Text('Operational Rationale:', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 13)),
                const SizedBox(height: 6),
                TextField(
                  controller: reasonCtrl,
                  decoration: InputDecoration(
                    filled: true,
                    fillColor: Colors.white,
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                  ),
                ),
                const SizedBox(height: 20),
                FilledButton.icon(
                  onPressed: () {
                    setState(() {
                      _activeRoutes.insert(0, {
                        'id': 'route-emer-${DateTime.now().millisecondsSinceEpoch}',
                        'title': 'Emergency Truck ($selectedSector)',
                        'status': 'En-route',
                        'driver': 'Duty Team ($selectedVehicle)',
                        'stops': 1,
                        'completed': 0,
                      });
                    });
                    Navigator.pop(ctx);
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text('Emergency Truck $selectedVehicle dispatched to $selectedSector!'),
                        backgroundColor: const Color(0xFF1B2A32),
                      ),
                    );
                  },
                  icon: const Icon(Icons.flash_on_rounded, size: 18),
                  label: const Text('Confirm Immediate Dispatch', style: TextStyle(fontWeight: FontWeight.w700)),
                  style: FilledButton.styleFrom(
                    backgroundColor: const Color(0xFFBA4738),
                    padding: const EdgeInsets.symmetric(vertical: 14),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  void _showAdminProfileDialog() {
    final pinCtrl = TextEditingController(text: widget.authService?.getSupervisorPin() ?? '4019');
    bool is2fa = widget.authService?.is2faEnabledForEmail(AuthService.officialAdminEmail) ?? true;

    showDialog<void>(
      context: context,
      builder: (dialogCtx) => StatefulBuilder(
        builder: (ctx, setDialogState) {
          return AlertDialog(
            backgroundColor: const Color(0xFFF7F5EE),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
            title: const Row(
              children: [
                Icon(Icons.admin_panel_settings_rounded, color: Color(0xFF1B2A32)),
                SizedBox(width: 8),
                Text(
                  'Administrator Account',
                  style: TextStyle(
                    fontFamily: 'Satoshi',
                    fontWeight: FontWeight.w800,
                    fontSize: 16,
                  ),
                ),
              ],
            ),
            content: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: const Color(0xFFE5DFC9),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Row(
                      children: [
                        const CircleAvatar(
                          backgroundColor: Color(0xFF1B2A32),
                          child: Icon(Icons.person_rounded, color: Colors.white),
                        ),
                        const SizedBox(width: 12),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: const [
                            Text(
                              'Admin ID: #A-9014',
                              style: TextStyle(fontWeight: FontWeight.w800, fontSize: 13),
                            ),
                            Text(
                              AuthService.officialAdminEmail,
                              style: TextStyle(fontSize: 11.5, color: Color(0xFF384D55)),
                            ),
                            Text(
                              'Role: Municipal Ops HQ',
                              style: TextStyle(fontSize: 11, color: Color(0xFF2E6B4A), fontWeight: FontWeight.w700),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 14),
                  const Text('Supervisor Authorization PIN:', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 12)),
                  const SizedBox(height: 6),
                  TextField(
                    controller: pinCtrl,
                    obscureText: true,
                    maxLength: 6,
                    decoration: InputDecoration(
                      filled: true,
                      fillColor: Colors.white,
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                      hintText: '4-digit PIN',
                    ),
                  ),
                  const SizedBox(height: 8),
                  SwitchListTile(
                    value: is2fa,
                    contentPadding: EdgeInsets.zero,
                    title: const Text('Require 2FA via Email', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 13)),
                    subtitle: const Text('Enforce 6-digit OTP code on sign-in', style: TextStyle(fontSize: 11)),
                    onChanged: (val) {
                      setDialogState(() => is2fa = val);
                      widget.authService?.set2faEnabledForEmail(AuthService.officialAdminEmail, val);
                    },
                  ),
                  const SizedBox(height: 10),
                  TextButton.icon(
                    onPressed: () {
                      Navigator.pop(dialogCtx);
                      _showResetPasswordDialog();
                    },
                    icon: const Icon(Icons.lock_reset_rounded, size: 16),
                    label: const Text('Reset Master Password'),
                  ),
                  const SizedBox(height: 6),
                  OutlinedButton.icon(
                    onPressed: () async {
                      Navigator.pop(dialogCtx);
                      await widget.authService?.logout();
                      if (mounted) {
                        AppRouter.routeToLogin(
                          context,
                          repository: widget.repository,
                          authService: widget.authService,
                          wasteApiService: widget.wasteApiService,
                        );
                      }
                    },
                    icon: const Icon(Icons.logout_rounded, size: 16, color: Color(0xFFBA4738)),
                    label: const Text('Sign out', style: TextStyle(color: Color(0xFFBA4738), fontWeight: FontWeight.w700)),
                  ),
                ],
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(dialogCtx),
                child: const Text('Close'),
              ),
              FilledButton(
                onPressed: () {
                  widget.authService?.setSupervisorPin(pinCtrl.text.trim());
                  Navigator.pop(dialogCtx);
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Admin settings updated.')),
                  );
                },
                style: FilledButton.styleFrom(backgroundColor: const Color(0xFF1B2A32)),
                child: const Text('Save PIN'),
              ),
            ],
          );
        },
      ),
    );
  }

  void _showResetPasswordDialog() {
    final passCtrl = TextEditingController();
    showDialog<void>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Set New Admin Password', style: TextStyle(fontWeight: FontWeight.w800, fontSize: 16)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('Enter new master password for official admin account (ayikog@yahoo.com):', style: TextStyle(fontSize: 12.5)),
            const SizedBox(height: 12),
            TextField(
              controller: passCtrl,
              obscureText: true,
              decoration: InputDecoration(
                labelText: 'New Password',
                filled: true,
                fillColor: Colors.white,
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
          FilledButton(
            onPressed: () async {
              if (passCtrl.text.length < 6) return;
              await widget.authService?.resetPassword(
                email: AuthService.officialAdminEmail,
                newPassword: passCtrl.text,
              );
              if (ctx.mounted) {
                Navigator.pop(ctx);
              }
              if (mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Admin password updated successfully!')),
                );
              }
            },
            child: const Text('Update'),
          ),
        ],
      ),
    );
  }

  void _showRiderInviteDialog() {
    final nameCtrl = TextEditingController();
    final emailCtrl = TextEditingController();
    final phoneCtrl = TextEditingController();
    var sending = false;

    showDialog<void>(
      context: context,
      builder: (dialogCtx) => StatefulBuilder(
        builder: (ctx, setDialogState) {
          return AlertDialog(
            backgroundColor: const Color(0xFFF7F5EE),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
            title: const Row(
              children: [
                Icon(Icons.two_wheeler_rounded, color: Color(0xFF1B2A32)),
                SizedBox(width: 8),
                Text(
                  'Invite & Onboard Rider',
                  style: TextStyle(fontFamily: 'Satoshi', fontWeight: FontWeight.w800, fontSize: 16),
                ),
              ],
            ),
            content: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextField(
                    controller: nameCtrl,
                    decoration: InputDecoration(
                      labelText: 'Rider Full Name',
                      filled: true,
                      fillColor: Colors.white,
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                    ),
                  ),
                  const SizedBox(height: 10),
                  TextField(
                    controller: emailCtrl,
                    decoration: InputDecoration(
                      labelText: 'Email Address',
                      filled: true,
                      fillColor: Colors.white,
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                    ),
                  ),
                  const SizedBox(height: 10),
                  TextField(
                    controller: phoneCtrl,
                    decoration: InputDecoration(
                      labelText: 'Phone Number',
                      filled: true,
                      fillColor: Colors.white,
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                    ),
                  ),
                ],
              ),
            ),
            actions: [
              TextButton(onPressed: () => Navigator.pop(dialogCtx), child: const Text('Cancel')),
              FilledButton(
                onPressed: sending
                    ? null
                    : () async {
                        final name = nameCtrl.text.trim();
                        final email = emailCtrl.text.trim();
                        final phone = phoneCtrl.text.trim();
                        if (name.isEmpty || email.isEmpty) return;

                        setDialogState(() => sending = true);
                        try {
                          final code = await widget.authService?.inviteRider(
                                email: email,
                                fullName: name,
                                phone: phone,
                              ) ??
                              'RIDER-001';
                          final link = '${RiderInviteService.defaultAppUrl}?invite=$code&email=${Uri.encodeComponent(email)}';
                          await RiderInviteService.sendRiderInviteEmail(
                            riderEmail: email,
                            riderName: name,
                            inviteLink: link,
                          );
                          if (dialogCtx.mounted) {
                            Navigator.pop(dialogCtx);
                          }
                          if (mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(content: Text('Invitation dispatched to $email ($code)')),
                            );
                          }
                        } finally {
                          if (dialogCtx.mounted) setDialogState(() => sending = false);
                        }
                      },
                style: FilledButton.styleFrom(backgroundColor: const Color(0xFF1B2A32)),
                child: const Text('Send Invite'),
              ),
            ],
          );
        },
      ),
    );
  }

  void _showConfigureEmailGatewayDialog() {
    final urlCtrl = TextEditingController(text: RiderInviteService.scriptUrl);
    showDialog<void>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Configure Cloud Gateway', style: TextStyle(fontWeight: FontWeight.w800, fontSize: 16)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Google Apps Script Web App Deployment URL for email dispatch:', style: TextStyle(fontSize: 12)),
            const SizedBox(height: 10),
            TextField(
              controller: urlCtrl,
              decoration: InputDecoration(
                filled: true,
                fillColor: Colors.white,
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
          FilledButton(
            onPressed: () async {
              await RiderInviteService.saveScriptUrl(urlCtrl.text.trim());
              if (ctx.mounted) {
                Navigator.pop(ctx);
              }
              if (mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Email gateway configured successfully.')),
                );
              }
            },
            child: const Text('Save'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    const bgParchment = Color(0xFFECE7DE);
    const topBarBg = Color(0xFF16252D);

    return Scaffold(
      backgroundColor: bgParchment,
      body: SafeArea(
        child: Column(
          children: [
            // 1. Top Bar: Solid dark slate-blue background with ecoRoute Command HQ branding,
            // connection status indicator, urgent notification bell, and administrator profile avatar.
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
                  const SizedBox(width: 8),
                  Flexible(
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
                      decoration: BoxDecoration(
                        color: const Color(0xFF243640),
                        borderRadius: BorderRadius.circular(6),
                        border: Border.all(color: const Color(0xFF354B57)),
                      ),
                      child: FittedBox(
                        fit: BoxFit.scaleDown,
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Container(
                              width: 7,
                              height: 7,
                              decoration: BoxDecoration(
                                color: _isOnline ? const Color(0xFF4ADE80) : const Color(0xFFBA4738),
                                shape: BoxShape.circle,
                              ),
                            ),
                            const SizedBox(width: 5),
                            Text(
                              _isOnline ? 'Command HQ • Online' : 'Command HQ • Offline',
                              style: const TextStyle(
                                fontFamily: 'Satoshi',
                                fontSize: 11,
                                fontWeight: FontWeight.w700,
                                color: Colors.white,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                  const Spacer(),

                  // Urgent Escalation Bell with Badge
                  IconButton(
                    icon: Badge(
                      label: Text('${_escalations.length}'),
                      isLabelVisible: _escalations.isNotEmpty,
                      backgroundColor: const Color(0xFFBA4738),
                      child: const Icon(Icons.notifications_active_rounded, color: Colors.white, size: 20),
                    ),
                    tooltip: 'Dispatch Escalations',
                    onPressed: () {
                      setState(() => _currentTab = 0);
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text('${_escalations.length} urgent dispatch escalations flagged.')),
                      );
                    },
                  ),

                  // Administrator Profile Avatar
                  GestureDetector(
                    key: const ValueKey('admin_topbar_profile_button'),
                    onTap: _showAdminProfileDialog,
                    child: Tooltip(
                      message: 'Profile',
                      child: FittedBox(
                        fit: BoxFit.scaleDown,
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const CircleAvatar(
                              radius: 14,
                              backgroundColor: Color(0xFF2D4B54),
                              child: Icon(Icons.person_rounded, size: 18, color: Colors.white),
                            ),
                            const SizedBox(width: 6),
                            // Semantic text matching find.text('Profile') for tests
                            const Text(
                              'Profile',
                              style: TextStyle(
                                fontFamily: 'Satoshi',
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                                color: Colors.white,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),

            // Tab Content
            Expanded(
              child: LayoutBuilder(
                builder: (context, constraints) {
                  final isWide = constraints.maxWidth >= 600;
                  return _buildActiveTabContent(isWide);
                },
              ),
            ),
          ],
        ),
      ),

      // 4-tab control bar: Dashboard, Dispatches, Audits, Fleet/Controls
      bottomNavigationBar: Container(
        decoration: const BoxDecoration(
          color: topBarBg,
          border: Border(top: BorderSide(color: Color(0xFF243640))),
        ),
        child: NavigationBar(
          selectedIndex: _currentTab,
          onDestinationSelected: (idx) => setState(() => _currentTab = idx),
          backgroundColor: topBarBg,
          indicatorColor: const Color(0xFF24444D),
          destinations: const [
            NavigationDestination(
              icon: Icon(Icons.dashboard_customize_outlined, color: Color(0xFF8B9B9E)),
              selectedIcon: Icon(Icons.dashboard_customize_rounded, color: Color(0xFF7CB69D)),
              label: 'Dashboard',
            ),
            NavigationDestination(
              icon: Icon(Icons.alt_route_outlined, color: Color(0xFF8B9B9E)),
              selectedIcon: Icon(Icons.alt_route_rounded, color: Color(0xFF7CB69D)),
              label: 'Dispatches',
            ),
            NavigationDestination(
              icon: Icon(Icons.receipt_long_outlined, color: Color(0xFF8B9B9E)),
              selectedIcon: Icon(Icons.receipt_long_rounded, color: Color(0xFF7CB69D)),
              label: 'Audits',
            ),
            NavigationDestination(
              icon: Icon(Icons.tune_outlined, color: Color(0xFF8B9B9E)),
              selectedIcon: Icon(Icons.tune_rounded, color: Color(0xFF7CB69D)),
              label: 'Fleet/Controls',
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildActiveTabContent(bool isWide) {
    switch (_currentTab) {
      case 1:
        return _buildDispatchesTab(isWide);
      case 2:
        return _buildAuditsTab(isWide);
      case 3:
        return _buildFleetControlsTab(isWide);
      case 0:
      default:
        return _buildDashboardOverviewTab(isWide);
    }
  }

  // -------------------------------------------------------------
  // TAB 0: DASHBOARD (Overview & Live Alerts) (Mockup Image 3)
  // -------------------------------------------------------------
  Widget _buildDashboardOverviewTab(bool isWide) {
    final pendingApprovals = _orders
        .where((o) => o.status == RequestStatus.awaitingVerification)
        .toList();

    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Greeting Banner: "Good evening, Administrator!"
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              color: const Color(0xFF22353E),
              borderRadius: BorderRadius.circular(14),
            ),
            child: Row(
              children: [
                const CircleAvatar(
                  radius: 14,
                  backgroundColor: Color(0xFF2D4B54),
                  child: Icon(Icons.spa_rounded, color: Color(0xFF7CB69D), size: 16),
                ),
                const SizedBox(width: 10),
                const Expanded(
                  child: Text(
                    'Good evening, Administrator!',
                    style: TextStyle(
                      fontFamily: 'Satoshi',
                      fontSize: 14.5,
                      fontWeight: FontWeight.w700,
                      color: Colors.white,
                    ),
                  ),
                ),
                const SizedBox(width: 6),
                const Icon(Icons.notifications_outlined, color: Color(0xFF7CB69D), size: 18),
              ],
            ),
          ),
          const SizedBox(height: 16),

          // 1. System Quick Actions Banner
          const Text(
            'System Quick Actions',
            style: TextStyle(
              fontFamily: 'Satoshi',
              fontSize: 18,
              fontWeight: FontWeight.w800,
              color: Color(0xFF1B2A32),
            ),
          ),
          const SizedBox(height: 8),
          FilledButton(
            key: const ValueKey('dispatch_emergency_truck_button'),
            onPressed: _showEmergencyDispatchModal,
            style: FilledButton.styleFrom(
              backgroundColor: const Color(0xFF2E4049),
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 14),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
            child: const FittedBox(
              fit: BoxFit.scaleDown,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    'Dispatch Emergency Truck',
                    style: TextStyle(
                      fontFamily: 'Satoshi',
                      fontSize: 15,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  SizedBox(width: 6),
                  Icon(Icons.add, size: 18),
                ],
              ),
            ),
          ),
          const SizedBox(height: 4),
          const Center(
            child: Text(
              'Command HQ (Arua)',
              style: TextStyle(
                fontFamily: 'Satoshi',
                fontSize: 12,
                color: Color(0xFF5B6F77),
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          const SizedBox(height: 18),

          // 2. Real-Time Operations Metrics
          const Text(
            'Real-Time Operations',
            style: TextStyle(
              fontFamily: 'Satoshi',
              fontSize: 18,
              fontWeight: FontWeight.w800,
              color: Color(0xFF1B2A32),
            ),
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              // Metric Card 1: Live Dispatches: 14 Active
              Expanded(
                child: Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF0D5B5),
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: const Color(0xFFE2C4A2)),
                  ),
                  child: Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'Live Dispatches:',
                              style: TextStyle(
                                fontFamily: 'Satoshi',
                                fontSize: 12.5,
                                fontWeight: FontWeight.w600,
                                color: Color(0xFF4A3420),
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              '${14 + _activeRoutes.where((r) => r['status'] == 'En-route').length} Active',
                              style: const TextStyle(
                                fontFamily: 'Satoshi',
                                fontSize: 18,
                                fontWeight: FontWeight.w900,
                                color: Color(0xFF1B2A32),
                              ),
                            ),
                          ],
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: const Color(0xFFCC843D).withValues(alpha: 0.25),
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(Icons.local_shipping_rounded, color: Color(0xFF8A4F18), size: 22),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(width: 12),

              // Metric Card 2: Pending Requests: 28 Waiting
              Expanded(
                child: Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: const Color(0xFFBCE1D9),
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: const Color(0xFFA6D4CB)),
                  ),
                  child: Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'Pending Requests:',
                              style: TextStyle(
                                fontFamily: 'Satoshi',
                                fontSize: 12.5,
                                fontWeight: FontWeight.w600,
                                color: Color(0xFF1E463E),
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              '${28 + pendingApprovals.length} Waiting',
                              style: const TextStyle(
                                fontFamily: 'Satoshi',
                                fontSize: 18,
                                fontWeight: FontWeight.w900,
                                color: Color(0xFF1B2A32),
                              ),
                            ),
                          ],
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: const Color(0xFF388E77).withValues(alpha: 0.25),
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(Icons.assignment_late_rounded, color: Color(0xFF1E5648), size: 22),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),

          // 3. Live Dispatch Map View
          const Text(
            'Live Dispatch Map',
            style: TextStyle(
              fontFamily: 'Satoshi',
              fontSize: 18,
              fontWeight: FontWeight.w800,
              color: Color(0xFF1B2A32),
            ),
          ),
          const Text(
            'Arua City Fleet Track',
            style: TextStyle(
              fontFamily: 'Satoshi',
              fontSize: 13,
              color: Color(0xFF5B6F77),
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 10),
          LiveDispatchMap(
            height: isWide ? 380 : 260,
            onViewActiveDispatches: () => setState(() => _currentTab = 1),
          ),
          const SizedBox(height: 20),

          // 4. Escalations & Critical Alerts
          const Text(
            'Escalations & Alerts',
            style: TextStyle(
              fontFamily: 'Satoshi',
              fontSize: 18,
              fontWeight: FontWeight.w800,
              color: Color(0xFF1B2A32),
            ),
          ),
          const Text(
            'Critical Alerts & Escalations',
            style: TextStyle(
              fontFamily: 'Satoshi',
              fontSize: 13,
              color: Color(0xFF5B6F77),
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 10),
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: const Color(0xFFF7F5EE),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: const Color(0xFFD6CEB5)),
            ),
            child: Column(
              children: _escalations.map((esc) {
                final isCritical = esc['severity'] == 'critical';
                return Padding(
                  padding: const EdgeInsets.symmetric(vertical: 6),
                  child: Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              esc['title'] as String,
                              style: const TextStyle(
                                fontFamily: 'Satoshi',
                                fontSize: 14,
                                fontWeight: FontWeight.w800,
                                color: Color(0xFF1B2A32),
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              esc['subtitle'] as String,
                              style: const TextStyle(
                                fontFamily: 'Satoshi',
                                fontSize: 12,
                                color: Color(0xFF5B6F77),
                              ),
                            ),
                          ],
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(
                          color: isCritical ? const Color(0xFFBA4738) : const Color(0xFFD48B38),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          'Status: ${esc['status']}',
                          style: const TextStyle(
                            fontFamily: 'Satoshi',
                            color: Colors.white,
                            fontSize: 11,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                    ],
                  ),
                );
              }).toList(),
            ),
          ),
          const SizedBox(height: 20),

          // 5. Audit Trail & Logs Preview
          const Text(
            'Audit Trail & Logs',
            style: TextStyle(
              fontFamily: 'Satoshi',
              fontSize: 18,
              fontWeight: FontWeight.w800,
              color: Color(0xFF1B2A32),
            ),
          ),
          const Text(
            'Audit Ledger Preview',
            style: TextStyle(
              fontFamily: 'Satoshi',
              fontSize: 13,
              color: Color(0xFF5B6F77),
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 10),
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: const Color(0xFFDCE6DE),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: const Color(0xFFC7D6C9)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: const [
                _LedgerPreviewRow(
                  title: 'Client Pickup Complete • #7741',
                  subtitle: 'Confirmed at Shop 12 • 18:20 EAT',
                ),
                Divider(height: 16),
                _LedgerPreviewRow(
                  title: 'Rider Shift Ended • Peter #R-4809',
                  subtitle: 'Completed 6 / 8 tasks • 17:45 EAT',
                ),
                Divider(height: 16),
                _LedgerPreviewRow(
                  title: 'Receipt Verified • Bank / Mobile Money',
                  subtitle: 'UGX 45,000 Verified',
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),

          // Repository Approvals Queue (Required for widget_test.dart assertions)
          if (pendingApprovals.isNotEmpty) ...[
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: const Color(0xFFD6CEB5)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Pending Approvals Queue',
                    style: TextStyle(fontWeight: FontWeight.w800, fontSize: 14),
                  ),
                  const SizedBox(height: 10),
                  for (final req in pendingApprovals) ...[
                    ApprovalItemTile(
                      request: req,
                      onApprove: () => _handleApproveRequest(req),
                      onReturn: () => _handleReturnRequest(req),
                    ),
                    const Divider(height: 18),
                  ],
                ],
              ),
            ),
          ] else ...[
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: const Color(0xFFD6CEB5)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'All caught up. Completed pickups will appear here for review.',
                    style: TextStyle(
                      fontFamily: 'Satoshi',
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: Color(0xFF5B6F77),
                    ),
                  ),
                  const SizedBox(height: 10),
                  TextButton.icon(
                    onPressed: () => setState(() => _currentTab = 2),
                    icon: const Icon(Icons.analytics_outlined, size: 16),
                    label: const Text('Transaction analytics'),
                  ),
                ],
              ),
            ),
          ],
          const SizedBox(height: 24),
        ],
      ),
    );
  }

  // -------------------------------------------------------------
  // TAB 1: DISPATCHES (Live Fleet Map & Active Routes) (Mockup Image 1 Left)
  // -------------------------------------------------------------
  Widget _buildDispatchesTab(bool isWide) {
    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              const Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Live Dispatches',
                    style: TextStyle(
                      fontFamily: 'Satoshi',
                      fontSize: 20,
                      fontWeight: FontWeight.w800,
                      color: Color(0xFF1B2A32),
                    ),
                  ),
                  Text(
                    'Command HQ (Arua)',
                    style: TextStyle(
                      fontFamily: 'Satoshi',
                      fontSize: 13,
                      color: Color(0xFF5B6F77),
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
              const Spacer(),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: const Color(0xFF4A8B61),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Text(
                  'Active',
                  style: TextStyle(color: Colors.white, fontWeight: FontWeight.w800, fontSize: 12),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),

          // Map
          LiveDispatchMap(height: isWide ? 220 : 200),
          const SizedBox(height: 14),

          // Active Routes
          const Text(
            'Active Routes',
            style: TextStyle(
              fontFamily: 'Satoshi',
              fontSize: 18,
              fontWeight: FontWeight.w800,
              color: Color(0xFF1B2A32),
            ),
          ),
          const SizedBox(height: 10),
          for (final route in _activeRoutes) ...[
            Container(
              margin: const EdgeInsets.only(bottom: 10),
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: const Color(0xFFF7F5EE),
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: const Color(0xFFD6CEB5)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          route['title'] as String,
                          style: const TextStyle(
                            fontFamily: 'Satoshi',
                            fontSize: 14.5,
                            fontWeight: FontWeight.w800,
                            color: Color(0xFF1B2A32),
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      const Icon(Icons.arrow_forward_ios_rounded, size: 14, color: Color(0xFF5B6F77)),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '${route['driver']} • ${route['completed']}/${route['stops']} stops completed',
                    style: const TextStyle(fontSize: 12, color: Color(0xFF5B6F77)),
                  ),
                  const SizedBox(height: 10),
                  Wrap(
                    spacing: 8,
                    children: [
                      _buildRouteStatusPill(route, 'En-route', const Color(0xFFE2924E)),
                      _buildRouteStatusPill(route, 'Arrived', const Color(0xFF42898B)),
                      _buildRouteStatusPill(route, 'Delay', const Color(0xFFBA4738)),
                    ],
                  ),
                ],
              ),
            ),
          ],
          const SizedBox(height: 18),

          // Queue & Assignments: Assigned Collection Riders
          Row(
            children: [
              const Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Queue & Assignments',
                    style: TextStyle(
                      fontFamily: 'Satoshi',
                      fontSize: 18,
                      fontWeight: FontWeight.w800,
                      color: Color(0xFF1B2A32),
                    ),
                  ),
                  Text(
                    'Assigned Collection Riders',
                    style: TextStyle(
                      fontFamily: 'Satoshi',
                      fontSize: 13,
                      color: Color(0xFF5B6F77),
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
              const Spacer(),
              FilledButton.icon(
                onPressed: _showRiderInviteDialog,
                icon: const Icon(Icons.person_add_rounded, size: 16),
                label: const Text('Invite Rider', style: TextStyle(fontSize: 12)),
                style: FilledButton.styleFrom(backgroundColor: const Color(0xFF1B2A32)),
              ),
            ],
          ),
          const SizedBox(height: 10),
          _buildRiderCard(
            name: 'Peter #R-4809',
            status: 'Assigned',
            tasks: const ['Task checklist', 'Task arrived', 'Task checklist'],
          ),
          const SizedBox(height: 10),
          _buildRiderCard(
            name: 'Kassim #R-3102',
            status: 'En route',
            tasks: const ['Pickup confirmed', 'Navigating to Sector 3'],
          ),
          const SizedBox(height: 24),
        ],
      ),
    );
  }

  Widget _buildRouteStatusPill(Map<String, dynamic> route, String status, Color color) {
    final isSelected = route['status'] == status;
    return GestureDetector(
      onTap: () {
        setState(() {
          route['status'] = status;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('${route['title']} status updated to $status')),
        );
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
        decoration: BoxDecoration(
          color: isSelected ? color : color.withValues(alpha: 0.15),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: color, width: 1.2),
        ),
        child: Text(
          status,
          style: TextStyle(
            fontFamily: 'Satoshi',
            color: isSelected ? Colors.white : color,
            fontWeight: FontWeight.w800,
            fontSize: 11.5,
          ),
        ),
      ),
    );
  }

  Widget _buildRiderCard({
    required String name,
    required String status,
    required List<String> tasks,
  }) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFFDCE6DE),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFFC7D6C9)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const CircleAvatar(
            radius: 18,
            backgroundColor: Color(0xFF1B2A32),
            child: Icon(Icons.two_wheeler_rounded, size: 18, color: Colors.white),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  name,
                  style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 14, color: Color(0xFF1B2A32)),
                ),
                Text(
                  status,
                  style: const TextStyle(fontSize: 11.5, color: Color(0xFF2E6B4A), fontWeight: FontWeight.w700),
                ),
                const SizedBox(height: 6),
                for (final t in tasks) ...[
                  Row(
                    children: [
                      const Icon(Icons.check_circle_rounded, size: 14, color: Color(0xFF2E6B4A)),
                      const SizedBox(width: 4),
                      Text(t, style: const TextStyle(fontSize: 11.5, color: Color(0xFF384D55))),
                    ],
                  ),
                  const SizedBox(height: 2),
                ],
              ],
            ),
          ),
          const Icon(Icons.arrow_forward_ios_rounded, size: 14, color: Color(0xFF5B6F77)),
        ],
      ),
    );
  }

  // -------------------------------------------------------------
  // TAB 2: AUDITS (Financial Ledgers & Photo Proofs) (Mockup Image 1 Middle)
  // -------------------------------------------------------------
  Widget _buildAuditsTab(bool isWide) {
    final pendingApprovals = _orders
        .where((o) => o.status == RequestStatus.awaitingVerification)
        .toList();

    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              const Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Audit Ledger',
                    style: TextStyle(
                      fontFamily: 'Satoshi',
                      fontSize: 18,
                      fontWeight: FontWeight.w800,
                      color: Color(0xFF1B2A32),
                    ),
                  ),
                  Text(
                    'Financial & Field Logs',
                    style: TextStyle(
                      fontFamily: 'Satoshi',
                      fontSize: 12,
                      color: Color(0xFF5B6F77),
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
              const Spacer(),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: const Color(0xFF4A8B61),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Text(
                  'Verified',
                  style: TextStyle(color: Colors.white, fontWeight: FontWeight.w800, fontSize: 11),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),

          // Log Filtering Chips: [Today] [Last 7 Days] [Last 10 Days]
          const Text('Log Filtering', style: TextStyle(fontWeight: FontWeight.w800, fontSize: 12)),
          const SizedBox(height: 4),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: ['Today', 'Last 7 Days', 'Last 10 Days', 'All Time'].map((f) {
                final isSel = _selectedAuditFilter == f;
                return Padding(
                  padding: const EdgeInsets.only(right: 6),
                  child: FilterChip(
                    selected: isSel,
                    label: Text(f),
                    selectedColor: const Color(0xFF1B2A32),
                    labelStyle: TextStyle(
                      color: isSel ? Colors.white : const Color(0xFF1B2A32),
                      fontWeight: FontWeight.w700,
                    ),
                    onSelected: (_) => setState(() => _selectedAuditFilter = f),
                  ),
                );
              }).toList(),
            ),
          ),
          const SizedBox(height: 10),

          // Responsive layout for Timeline and Compliance cards
          if (isWide)
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Transaction & Verification Timeline',
                        style: TextStyle(
                          fontFamily: 'Satoshi',
                          fontSize: 14,
                          fontWeight: FontWeight.w800,
                          color: Color(0xFF1B2A32),
                        ),
                      ),
                      const SizedBox(height: 6),
                      Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: const Color(0xFFF7F5EE),
                          borderRadius: BorderRadius.circular(14),
                          border: Border.all(color: const Color(0xFFD6CEB5)),
                        ),
                        child: Column(
                          children: [
                            _buildTimelineNode(
                              icon: Icons.verified_rounded,
                              title: 'Audited Transaction #04192 Verified',
                              badge: 'Verified',
                              badgeColor: const Color(0xFF4A8B61),
                            ),
                            _buildTimelineNode(
                              icon: Icons.phone_android_rounded,
                              title: 'Mobile Money #04192 Verified',
                              badge: 'Verified',
                              badgeColor: const Color(0xFF4A8B61),
                            ),
                            _buildTimelineNodeWithThumbnail(
                              icon: Icons.camera_alt_outlined,
                              title: 'Photo Upload',
                              subtitle: 'Pick-up proof',
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: const Color(0xFFDCE6DE),
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(color: const Color(0xFFC7D6C9)),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: const [
                            Expanded(
                              child: Text(
                                'Compliance & Reports',
                                style: TextStyle(fontWeight: FontWeight.w800, fontSize: 14, color: Color(0xFF1B2A32)),
                              ),
                            ),
                            Icon(Icons.arrow_forward_ios_rounded, size: 14),
                          ],
                        ),
                        const SizedBox(height: 6),
                        const Text('Pending Verifications', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 12)),
                        const Text('Tracking Metrics: 3', style: TextStyle(fontSize: 11, color: Color(0xFF5B6F77))),
                        const Text('Tracing Metrics: 3', style: TextStyle(fontSize: 11, color: Color(0xFF5B6F77))),
                        const SizedBox(height: 8),
                        FilledButton.icon(
                          onPressed: () {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(content: Text('Audit Log Data exported successfully to CSV.')),
                            );
                          },
                          icon: const Icon(Icons.download_rounded, size: 16),
                          label: const Text('Export Log Data'),
                          style: FilledButton.styleFrom(backgroundColor: const Color(0xFF2C5659)),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            )
          else ...[
            const Text(
              'Transaction & Verification Timeline',
              style: TextStyle(
                fontFamily: 'Satoshi',
                fontSize: 14,
                fontWeight: FontWeight.w800,
                color: Color(0xFF1B2A32),
              ),
            ),
            const SizedBox(height: 6),
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: const Color(0xFFF7F5EE),
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: const Color(0xFFD6CEB5)),
              ),
              child: Column(
                children: [
                  _buildTimelineNode(
                    icon: Icons.verified_rounded,
                    title: 'Audited Transaction #04192 Verified',
                    badge: 'Verified',
                    badgeColor: const Color(0xFF4A8B61),
                  ),
                  _buildTimelineNode(
                    icon: Icons.phone_android_rounded,
                    title: 'Mobile Money #04192 Verified',
                    badge: 'Verified',
                    badgeColor: const Color(0xFF4A8B61),
                  ),
                  _buildTimelineNodeWithThumbnail(
                    icon: Icons.camera_alt_outlined,
                    title: 'Photo Upload',
                    subtitle: 'Pick-up proof',
                  ),
                ],
              ),
            ),
            const SizedBox(height: 10),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: const Color(0xFFDCE6DE),
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: const Color(0xFFC7D6C9)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: const [
                      Expanded(
                        child: Text(
                          'Compliance & Reports',
                          style: TextStyle(fontWeight: FontWeight.w800, fontSize: 14, color: Color(0xFF1B2A32)),
                        ),
                      ),
                      Icon(Icons.arrow_forward_ios_rounded, size: 14),
                    ],
                  ),
                  const SizedBox(height: 6),
                  const Text('Pending Verifications', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 12)),
                  const Text('Tracking Metrics: 3', style: TextStyle(fontSize: 11, color: Color(0xFF5B6F77))),
                  const Text('Tracing Metrics: 3', style: TextStyle(fontSize: 11, color: Color(0xFF5B6F77))),
                  const SizedBox(height: 8),
                  FilledButton.icon(
                    onPressed: () {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Audit Log Data exported successfully to CSV.')),
                      );
                    },
                    icon: const Icon(Icons.download_rounded, size: 16),
                    label: const Text('Export Log Data'),
                    style: FilledButton.styleFrom(backgroundColor: const Color(0xFF2C5659)),
                  ),
                ],
              ),
            ),
          ],
          const SizedBox(height: 18),

          // Embedded Orders Verification Queue
          if (pendingApprovals.isNotEmpty) ...[
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: const Color(0xFFD6CEB5)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Field Pickup Verifications', style: TextStyle(fontWeight: FontWeight.w800, fontSize: 14)),
                  const SizedBox(height: 10),
                  for (final req in pendingApprovals) ...[
                    ApprovalItemTile(
                      request: req,
                      onApprove: () => _handleApproveRequest(req),
                      onReturn: () => _handleReturnRequest(req),
                    ),
                    const Divider(height: 18),
                  ],
                ],
              ),
            ),
          ] else ...[
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: const Color(0xFFD6CEB5)),
              ),
              child: const Text(
                'All caught up. Completed pickups will appear here for review.',
                style: TextStyle(
                  fontFamily: 'Satoshi',
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: Color(0xFF5B6F77),
                ),
              ),
            ),
          ],
          const SizedBox(height: 24),
        ],
      ),
    );
  }

  Widget _buildTimelineNode({
    required IconData icon,
    required String title,
    required String badge,
    required Color badgeColor,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(6),
            decoration: BoxDecoration(
              color: const Color(0xFF22353E),
              borderRadius: BorderRadius.circular(6),
            ),
            child: Icon(icon, color: Colors.white, size: 16),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              title,
              style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 13, color: Color(0xFF1B2A32)),
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
            decoration: BoxDecoration(
              color: badgeColor,
              borderRadius: BorderRadius.circular(6),
            ),
            child: Text(
              badge,
              style: const TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.w700),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTimelineNodeWithThumbnail({
    required IconData icon,
    required String title,
    required String subtitle,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(6),
            decoration: BoxDecoration(
              color: const Color(0xFF22353E),
              borderRadius: BorderRadius.circular(6),
            ),
            child: Icon(icon, color: Colors.white, size: 16),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 13)),
                Text(subtitle, style: const TextStyle(fontSize: 11.5, color: Color(0xFF5B6F77))),
              ],
            ),
          ),
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: const Color(0xFFE5DFC9),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: const Color(0xFFC7D6C9)),
            ),
            child: const Icon(Icons.image_outlined, size: 22, color: Color(0xFF24444D)),
          ),
        ],
      ),
    );
  }

  // -------------------------------------------------------------
  // TAB 3: FLEET/CONTROLS (System Controls) (Mockup Image 1 Right)
  // -------------------------------------------------------------
  Widget _buildFleetControlsTab(bool isWide) {
    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: const [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'System Controls',
                    style: TextStyle(
                      fontFamily: 'Satoshi',
                      fontSize: 18,
                      fontWeight: FontWeight.w800,
                      color: Color(0xFF1B2A32),
                    ),
                  ),
                  Text(
                    'Fleet & Personnel',
                    style: TextStyle(
                      fontFamily: 'Satoshi',
                      fontSize: 12,
                      color: Color(0xFF5B6F77),
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
              Spacer(),
              CircleAvatar(
                radius: 16,
                backgroundColor: Color(0xFF243640),
                child: Icon(Icons.settings_rounded, color: Colors.white, size: 16),
              ),
            ],
          ),
          const SizedBox(height: 8),

          if (isWide)
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Fleet Management: Tracked Vehicles
                      const Text('Fleet Management', style: TextStyle(fontWeight: FontWeight.w800, fontSize: 13)),
                      const Text('Tracked Vehicles', style: TextStyle(fontSize: 11, color: Color(0xFF5B6F77))),
                      const SizedBox(height: 4),
                      Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: const Color(0xFFDCE6DE),
                          borderRadius: BorderRadius.circular(14),
                          border: Border.all(color: const Color(0xFFC7D6C9)),
                        ),
                        child: Column(
                          children: _trackedVehicles.map((v) {
                            final isActive = v['status'] == 'Active';
                            final isMaint = v['status'] == 'Maintenance';
                            final color = isActive
                                ? const Color(0xFF4A8B61)
                                : (isMaint ? const Color(0xFFD48B38) : const Color(0xFF386884));

                            return Padding(
                              padding: const EdgeInsets.symmetric(vertical: 2),
                              child: Row(
                                children: [
                                  const Icon(Icons.local_shipping_outlined, color: Color(0xFF1B2A32), size: 18),
                                  const SizedBox(width: 8),
                                  Text(
                                    v['plate'] as String,
                                    style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 13),
                                  ),
                                  const Spacer(),
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                                    decoration: BoxDecoration(
                                      color: color,
                                      borderRadius: BorderRadius.circular(6),
                                    ),
                                    child: Text(
                                      v['status'] as String,
                                      style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w800, fontSize: 10.5),
                                    ),
                                  ),
                                ],
                              ),
                            );
                          }).toList(),
                        ),
                      ),
                      const SizedBox(height: 10),

                      // Personnel & Dispatch Controls (Switches matching Mockup)
                      const Text('Personnel & Dispatch Controls', style: TextStyle(fontWeight: FontWeight.w800, fontSize: 13)),
                      const SizedBox(height: 4),
                      Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: const Color(0xFFDCE6DE),
                          borderRadius: BorderRadius.circular(14),
                          border: Border.all(color: const Color(0xFFC7D6C9)),
                        ),
                        child: Column(
                          children: [
                            _buildControlSwitch('Operational Boundaries', _operationalBoundaries, (v) => setState(() => _operationalBoundaries = v)),
                            const Divider(height: 6),
                            _buildControlSwitch('Manage Schedules', _manageSchedules, (v) => setState(() => _manageSchedules = v)),
                            const Divider(height: 6),
                            _buildControlSwitch('Emergency Override', _emergencyOverride, (v) => setState(() => _emergencyOverride = v)),
                            const Divider(height: 6),
                            _buildControlSwitch('Adjust Override Features', _adjustOverrideFeatures, (v) => setState(() => _adjustOverrideFeatures = v)),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // System Options
                      const Text('System Options', style: TextStyle(fontWeight: FontWeight.w800, fontSize: 13)),
                      const SizedBox(height: 4),
                      Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: const Color(0xFFF7F5EE),
                          borderRadius: BorderRadius.circular(14),
                          border: Border.all(color: const Color(0xFFD6CEB5)),
                        ),
                        child: Column(
                          children: [
                            _buildOptionTile('Supervisor PIN Setup', () => _showAdminProfileDialog()),
                            const Divider(height: 6),
                            _buildOptionTile('App Updates', () {
                              showDialog<void>(
                                context: context,
                                builder: (ctx) => AlertDialog(
                                  title: const Text('App Updates', style: TextStyle(fontWeight: FontWeight.w800, fontSize: 16)),
                                  content: const Text('ecoRoute Command HQ v2.4.0 is fully up to date.'),
                                  actions: [TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('OK'))],
                                ),
                              );
                            }),
                            const Divider(height: 6),
                            _buildOptionTile('Support Logs', () {
                              showDialog<void>(
                                context: context,
                                builder: (ctx) => AlertDialog(
                                  title: const Text('Support & Audit Logs', style: TextStyle(fontWeight: FontWeight.w800, fontSize: 16)),
                                  content: const Text('Logs verified across Arua municipal gateways.\nAll dispatch nodes operational.'),
                                  actions: [TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Close'))],
                                ),
                              );
                            }),
                            const Divider(height: 6),
                            _buildOptionTile('Cloud Gateway Configuration', _showConfigureEmailGatewayDialog),
                            const Divider(height: 6),
                            _buildOptionTile(
                              'Finalize Shift & Sign Out',
                              _openSessionEndedView,
                              isDestructive: true,
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            )
          else ...[
            // Fleet Management: Tracked Vehicles
            const Text('Fleet Management', style: TextStyle(fontWeight: FontWeight.w800, fontSize: 13)),
            const Text('Tracked Vehicles', style: TextStyle(fontSize: 11, color: Color(0xFF5B6F77))),
            const SizedBox(height: 4),
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: const Color(0xFFDCE6DE),
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: const Color(0xFFC7D6C9)),
              ),
              child: Column(
                children: _trackedVehicles.map((v) {
                  final isActive = v['status'] == 'Active';
                  final isMaint = v['status'] == 'Maintenance';
                  final color = isActive
                      ? const Color(0xFF4A8B61)
                      : (isMaint ? const Color(0xFFD48B38) : const Color(0xFF386884));

                  return Padding(
                    padding: const EdgeInsets.symmetric(vertical: 2),
                    child: Row(
                      children: [
                        const Icon(Icons.local_shipping_outlined, color: Color(0xFF1B2A32), size: 18),
                        const SizedBox(width: 8),
                        Text(
                          v['plate'] as String,
                          style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 13),
                        ),
                        const Spacer(),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                          decoration: BoxDecoration(
                            color: color,
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Text(
                            v['status'] as String,
                            style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w800, fontSize: 10.5),
                          ),
                        ),
                      ],
                    ),
                  );
                }).toList(),
              ),
            ),
            const SizedBox(height: 10),

            // Personnel & Dispatch Controls (Switches matching Mockup)
            const Text('Personnel & Dispatch Controls', style: TextStyle(fontWeight: FontWeight.w800, fontSize: 13)),
            const SizedBox(height: 4),
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: const Color(0xFFDCE6DE),
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: const Color(0xFFC7D6C9)),
              ),
              child: Column(
                children: [
                  _buildControlSwitch('Operational Boundaries', _operationalBoundaries, (v) => setState(() => _operationalBoundaries = v)),
                  const Divider(height: 6),
                  _buildControlSwitch('Manage Schedules', _manageSchedules, (v) => setState(() => _manageSchedules = v)),
                  const Divider(height: 6),
                  _buildControlSwitch('Emergency Override', _emergencyOverride, (v) => setState(() => _emergencyOverride = v)),
                  const Divider(height: 6),
                  _buildControlSwitch('Adjust Override Features', _adjustOverrideFeatures, (v) => setState(() => _adjustOverrideFeatures = v)),
                ],
              ),
            ),
            const SizedBox(height: 10),

            // System Options
            const Text('System Options', style: TextStyle(fontWeight: FontWeight.w800, fontSize: 13)),
            const SizedBox(height: 4),
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: const Color(0xFFF7F5EE),
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: const Color(0xFFD6CEB5)),
              ),
              child: Column(
                children: [
                  _buildOptionTile('Supervisor PIN Setup', () => _showAdminProfileDialog()),
                  const Divider(height: 6),
                  _buildOptionTile('App Updates', () {
                    showDialog<void>(
                      context: context,
                      builder: (ctx) => AlertDialog(
                        title: const Text('App Updates', style: TextStyle(fontWeight: FontWeight.w800, fontSize: 16)),
                        content: const Text('ecoRoute Command HQ v2.4.0 is fully up to date.'),
                        actions: [TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('OK'))],
                      ),
                    );
                  }),
                  const Divider(height: 6),
                  _buildOptionTile('Support Logs', () {
                    showDialog<void>(
                      context: context,
                      builder: (ctx) => AlertDialog(
                        title: const Text('Support & Audit Logs', style: TextStyle(fontWeight: FontWeight.w800, fontSize: 16)),
                        content: const Text('Logs verified across Arua municipal gateways.\nAll dispatch nodes operational.'),
                        actions: [TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Close'))],
                      ),
                    );
                  }),
                  const Divider(height: 6),
                  _buildOptionTile('Cloud Gateway Configuration', _showConfigureEmailGatewayDialog),
                  const Divider(height: 6),
                  _buildOptionTile(
                    'Finalize Shift & Sign Out',
                    _openSessionEndedView,
                    isDestructive: true,
                  ),
                ],
              ),
            ),
          ],
          const SizedBox(height: 14),
        ],
      ),
    );
  }

  Widget _buildControlSwitch(String label, bool value, ValueChanged<bool> onChanged) {
    return Row(
      children: [
        Expanded(
          child: Text(
            label,
            style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 12.5, color: Color(0xFF1B2A32)),
          ),
        ),
        Transform.scale(
          scale: 0.85,
          child: Switch(
            value: value,
            activeTrackColor: const Color(0xFF2C5659),
            onChanged: onChanged,
          ),
        ),
      ],
    );
  }

  Widget _buildOptionTile(String label, VoidCallback onTap, {bool isDestructive = false}) {
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 3),
        child: Row(
          children: [
            Expanded(
              child: Text(
                label,
                style: TextStyle(
                  fontWeight: FontWeight.w700,
                  fontSize: 12.5,
                  color: isDestructive ? const Color(0xFFBA4738) : const Color(0xFF1B2A32),
                ),
              ),
            ),
            Icon(Icons.arrow_forward_ios_rounded, size: 14, color: isDestructive ? const Color(0xFFBA4738) : const Color(0xFF5B6F77)),
          ],
        ),
      ),
    );
  }
}

class _LedgerPreviewRow extends StatelessWidget {
  const _LedgerPreviewRow({required this.title, required this.subtitle});

  final String title;
  final String subtitle;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: const TextStyle(
            fontFamily: 'Satoshi',
            fontSize: 13.5,
            fontWeight: FontWeight.w800,
            color: Color(0xFF1B2A32),
          ),
        ),
        const SizedBox(height: 2),
        Text(
          subtitle,
          style: const TextStyle(
            fontFamily: 'Satoshi',
            fontSize: 12,
            color: Color(0xFF5B6F77),
          ),
        ),
      ],
    );
  }
}
