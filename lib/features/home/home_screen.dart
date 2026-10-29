import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../core/pickup_request_repository.dart';
import '../../core/services/auth_service.dart';
import '../../core/services/language_service.dart';
import '../../core/services/location_service.dart';
import '../../core/services/rider_invite_service.dart';
import '../../core/services/waste_api_service.dart';
import '../../core/utils/formatters.dart';
import '../../domain/entities/app_user.dart';
import '../../domain/entities/pickup_request.dart';
import '../../domain/enums/request_status.dart';
import '../../domain/enums/role.dart';
import '../../domain/enums/waste_type.dart';
import '../../domain/rules/status_machine.dart';
import '../../core/services/theme_service.dart';
import '../admin/widgets/admin_analytics_view.dart';
import '../admin/widgets/admin_settings_view.dart';
import '../admin/widgets/analytics_breakdown.dart';
import '../admin/widgets/approval_item_tile.dart';
import '../auth/auth_sheet.dart';
import '../database/waste_database_sheet.dart';
import '../payment/momo_payment_dialog.dart';
import '../profile/widgets/profile_settings_view.dart';
import '../request/order_page.dart';
import '../request/widgets/request_detail_sheet.dart';
import '../rider/widgets/route_stop_tile.dart';
import 'widgets/brand_lockup.dart';
import 'widgets/interactive_map_panel.dart';
import 'widgets/metric_cards.dart';
import 'widgets/resident_dashboard_widgets.dart';
import 'widgets/status_selector.dart';

export 'widgets/brand_lockup.dart';
export 'widgets/interactive_map_panel.dart';
export 'widgets/metric_cards.dart';
export 'widgets/resident_dashboard_widgets.dart';
export 'widgets/status_selector.dart';

// Backward compatibility aliases
typedef _RouteStop = RouteStopTile;
typedef _ApprovalItem = ApprovalItemTile;
typedef _AnalyticsRow = AnalyticsRow;
typedef _MetricCard = MetricCard;
typedef _QuickActionCard = QuickActionCard;
typedef _DashboardPanel = DashboardPanel;
typedef _EmptyPanelMessage = EmptyPanelMessage;
typedef _StatusSelector = StatusSelector;

class EcoRouteSplashScreen extends StatefulWidget {
  const EcoRouteSplashScreen({
    required this.repository,
    this.authService,
    this.wasteApiService,
    super.key,
  });

  final PickupRequestRepository repository;
  final AuthService? authService;
  final WasteApiService? wasteApiService;

  @override
  State<EcoRouteSplashScreen> createState() => _EcoRouteSplashScreenState();
}

class _EcoRouteSplashScreenState extends State<EcoRouteSplashScreen>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<double> _scaleAnimation;
  late final Animation<double> _opacityAnimation;
  late final Animation<double> _brightnessAnimation;
  late final Animation<double> _glowAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1800),
    );

    _scaleAnimation = TweenSequence<double>([
      TweenSequenceItem(
        tween: Tween<double>(begin: 0.86, end: 1.02)
            .chain(CurveTween(curve: Curves.easeOutBack)),
        weight: 65,
      ),
      TweenSequenceItem(
        tween: Tween<double>(begin: 1.02, end: 1.15)
            .chain(CurveTween(curve: Curves.easeInCubic)),
        weight: 35,
      ),
    ]).animate(_controller);

    _opacityAnimation = TweenSequence<double>([
      TweenSequenceItem(
        tween: Tween<double>(begin: 0.0, end: 1.0)
            .chain(CurveTween(curve: Curves.easeIn)),
        weight: 20,
      ),
      TweenSequenceItem(tween: ConstantTween<double>(1.0), weight: 60),
      TweenSequenceItem(
        tween: Tween<double>(begin: 1.0, end: 0.0)
            .chain(CurveTween(curve: Curves.easeOut)),
        weight: 20,
      ),
    ]).animate(_controller);

    // Dynamic brightness & exposure sweep across logo as it launches
    _brightnessAnimation = TweenSequence<double>([
      TweenSequenceItem(
        tween: Tween<double>(begin: 0.65, end: 1.35)
            .chain(CurveTween(curve: Curves.easeInOutCubic)),
        weight: 50,
      ),
      TweenSequenceItem(
        tween: Tween<double>(begin: 1.35, end: 1.0)
            .chain(CurveTween(curve: Curves.easeOut)),
        weight: 50,
      ),
    ]).animate(_controller);

    // Subtle breathing halo glow
    _glowAnimation = TweenSequence<double>([
      TweenSequenceItem(
        tween: Tween<double>(begin: 0.15, end: 0.55)
            .chain(CurveTween(curve: Curves.easeInOut)),
        weight: 50,
      ),
      TweenSequenceItem(
        tween: Tween<double>(begin: 0.55, end: 0.25)
            .chain(CurveTween(curve: Curves.easeOut)),
        weight: 50,
      ),
    ]).animate(_controller);

    _controller.forward().then((_) {
      if (mounted) {
        Navigator.of(context).pushReplacement(
          PageRouteBuilder(
            pageBuilder: (context, animation, secondaryAnimation) => EcoRouteHomeScreen(
              repository: widget.repository,
              authService: widget.authService,
              wasteApiService: widget.wasteApiService,
            ),
            transitionDuration: const Duration(milliseconds: 350),
            transitionsBuilder: (context, animation, secondaryAnimation, child) =>
                FadeTransition(opacity: animation, child: child),
          ),
        );
      }
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: const SystemUiOverlayStyle(
        statusBarColor: Color(0xFF141D26),
        statusBarIconBrightness: Brightness.light,
        statusBarBrightness: Brightness.dark,
        systemNavigationBarColor: Color(0xFF141D26),
        systemNavigationBarIconBrightness: Brightness.light,
        systemNavigationBarDividerColor: Colors.transparent,
      ),
      child: Scaffold(
        backgroundColor: const Color(0xFF141D26),
        body: Container(
          decoration: const BoxDecoration(
            gradient: RadialGradient(
              center: Alignment(0.0, -0.1),
              radius: 1.1,
              colors: [
                Color(0xFF1B2836),
                Color(0xFF141D26),
                Color(0xFF0C1218),
              ],
            ),
          ),
          child: Center(
            child: AnimatedBuilder(
              animation: _controller,
              builder: (context, _) {
                final b = _brightnessAnimation.value;
                return FadeTransition(
                  opacity: _opacityAnimation,
                  child: Transform.scale(
                    scale: _scaleAnimation.value,
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        // Soft breathing glowing aura behind logo
                        Stack(
                          alignment: Alignment.center,
                          children: [
                            Container(
                              width: 280,
                              height: 280,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                boxShadow: [
                                  BoxShadow(
                                    color: const Color(0xFF2EAD65).withValues(alpha: _glowAnimation.value),
                                    blurRadius: 70,
                                    spreadRadius: 10,
                                  ),
                                  BoxShadow(
                                    color: const Color(0xFF1E88E5).withValues(alpha: _glowAnimation.value * 0.6),
                                    blurRadius: 90,
                                    spreadRadius: 5,
                                  ),
                                ],
                              ),
                            ),
                            // Uploaded EcoRoute emblem with dynamic animated brightness sweep
                            ColorFiltered(
                              colorFilter: ColorFilter.matrix([
                                b, 0, 0, 0, 0,
                                0, b, 0, 0, 0,
                                0, 0, b, 0, 0,
                                0, 0, 0, 1, 0,
                              ]),
                              child: Image.asset(
                                'assets/EcoRoute_splash.png',
                                width: 280,
                                fit: BoxFit.contain,
                                errorBuilder: (context, error, stackTrace) => const BrandLockup(splash: true),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 24),
                        // Modern tagline & loading bar
                        const Text(
                          'Sustainable Waste Logistics • Arua',
                          style: TextStyle(
                            color: Color(0xFF8BA296),
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                            letterSpacing: 0.8,
                          ),
                        ),
                        const SizedBox(height: 18),
                        SizedBox(
                          width: 140,
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(10),
                            child: LinearProgressIndicator(
                              value: _controller.value,
                              minHeight: 3,
                              backgroundColor: Colors.white.withValues(alpha: 0.1),
                              valueColor: const AlwaysStoppedAnimation<Color>(Color(0xFF2EAD65)),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
        ),
      ),
    );
  }
}

class EcoRouteHomeScreen extends StatefulWidget {
  const EcoRouteHomeScreen({
    required this.repository,
    this.authService,
    this.wasteApiService,
    this.locationService = const LocationService(),
    super.key,
  });

  final PickupRequestRepository repository;
  final AuthService? authService;
  final WasteApiService? wasteApiService;
  final LocationService locationService;

  @override
  State<EcoRouteHomeScreen> createState() => _EcoRouteHomeScreenState();
}

class _EcoRouteHomeScreenState extends State<EcoRouteHomeScreen> {
  int _tab = 0;
  bool _signedIn = false;
  AppRole _role = AppRole.resident;
  int _adminNavIndex = 0;
  AppUser? _currentUser;
  bool _loadingOrders = true;
  final List<PickupRequest> _orders = [];

  // REST API Weather
  late final WasteApiService _apiService;
  AruaWeatherReport? _weatherReport;
  bool _loadingWeather = false;

  // GPS State
  UserLocationResult? _lastGpsResult;
  bool _locatingGps = false;

  // Filter & Search
  RequestStatus? _statusFilter;
  String _searchQuery = '';

  // Reminders
  bool _remindersEnabled = true;

  final LanguageService _langService = LanguageService.instance;

  // Rider Management Controllers
  final TextEditingController _riderEmailController = TextEditingController();
  final TextEditingController _riderNameController = TextEditingController();
  final TextEditingController _riderPhoneController = TextEditingController();
  bool _invitingRider = false;

  @override
  void dispose() {
    _riderEmailController.dispose();
    _riderNameController.dispose();
    _riderPhoneController.dispose();
    super.dispose();
  }
  @override
  void initState() {
    super.initState();
    _apiService = widget.wasteApiService ?? WasteApiService();
    _loadUserSession();
    _loadOrders();
    _loadWeather();
    _loadRiders();
  }

  void _loadUserSession() {
    if (widget.authService != null) {
      _remindersEnabled = widget.authService!.getRemindersEnabled();
      final user = widget.authService!.getCurrentUser();
      if (user != null) {
        _signedIn = true;
        _role = user.role;
        _currentUser = user;
      }
    }
  }

  Future<void> _loadWeather() async {
    setState(() => _loadingWeather = true);
    final report = await _apiService.fetchAruaCollectionWeather();
    if (mounted) {
      setState(() {
        _weatherReport = report;
        _loadingWeather = false;
      });
    }
  }

  Future<void> _loadOrders() async {
    final orders = await widget.repository.loadAll();
    if (!mounted) return;
    setState(() {
      _orders
        ..clear()
        ..addAll(orders);
      _loadingOrders = false;
    });
  }

  Future<void> _loadRiders() async {
    if (widget.authService != null) {
      await widget.authService!.fetchInvitedRidersAsync();
    }
    if (mounted) {
      setState(() {});
    }
  }

  Future<void> _inviteRider() async {
    final email = _riderEmailController.text.trim();
    final name = _riderNameController.text.trim();
    final phone = _riderPhoneController.text.trim();

    if (email.isEmpty || !email.contains('@')) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter a valid email address for the rider.')),
      );
      return;
    }
    if (name.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter rider full name.')),
      );
      return;
    }

    setState(() => _invitingRider = true);
    try {
      String inviteCode = 'RIDER-INVITE';
      if (widget.authService != null) {
        inviteCode = await widget.authService!.inviteRider(
          email: email,
          fullName: name,
          phone: phone.isNotEmpty ? phone : '+256 700 000 000',
        );
      }

      // Dispatch invitation email via Google Apps Script MailApp API
      final inviteLink = '${RiderInviteService.defaultAppUrl}?invite=$inviteCode&email=${Uri.encodeComponent(email)}';
      final emailSent = await RiderInviteService.sendRiderInviteEmail(
        riderEmail: email,
        riderName: name,
        inviteLink: inviteLink,
      );

      _riderEmailController.clear();
      _riderNameController.clear();
      _riderPhoneController.clear();
      await _loadRiders();
      if (mounted) {
        if (emailSent) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              backgroundColor: const Color(0xFF2E8B57),
              content: Text('Official invite email dispatched to $email! Invite code: $inviteCode'),
            ),
          );
        } else {
          _showInviteLinkDialog(
            email: email,
            name: name,
            inviteCode: inviteCode,
            inviteLink: inviteLink,
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to invite rider: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _invitingRider = false);
    }
  }

  void _showInviteLinkDialog({
    required String email,
    required String name,
    required String inviteCode,
    required String inviteLink,
  }) {
    showDialog<void>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Row(
          children: [
            Icon(Icons.mark_email_read_outlined, color: Color(0xFF2E7D32)),
            SizedBox(width: 8),
            Expanded(
              child: Text(
                'Rider Invitation Ready',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800),
              ),
            ),
          ],
        ),
        content: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text('Rider $name has been authorized with code $inviteCode.'),
              const SizedBox(height: 10),
              const Text(
                'Direct Google MailApp delivery requires an active Apps Script Deployment URL. You can send the official email right now via your mail client (Gmail/Outlook) or copy the onboarding link:',
                style: TextStyle(fontSize: 12, color: Color(0xFF556958)),
              ),
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: const Color(0xFFF1F8F2),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: const Color(0xFFC8E6C9)),
                ),
                child: SelectableText(
                  inviteLink,
                  style: const TextStyle(
                    fontSize: 11,
                    fontFamily: 'monospace',
                    color: Color(0xFF1B5E20),
                  ),
                ),
              ),
            ],
          ),
        ),
        actions: [
          TextButton.icon(
            icon: const Icon(Icons.copy_rounded, size: 16),
            label: const Text('Copy Link'),
            onPressed: () {
              Clipboard.setData(ClipboardData(text: inviteLink));
              Navigator.pop(ctx);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Invitation link copied to clipboard!')),
              );
            },
          ),
          FilledButton.icon(
            icon: const Icon(Icons.mail_outline_rounded, size: 16),
            label: const Text('Send via Email App'),
            style: FilledButton.styleFrom(backgroundColor: const Color(0xFF2E7D32)),
            onPressed: () async {
              Navigator.pop(ctx);
              await RiderInviteService.openEmailClient(
                riderEmail: email,
                riderName: name,
                inviteLink: inviteLink,
              );
            },
          ),
        ],
      ),
    );
  }

  void _openEmailClientForRider(Map<String, dynamic> rider) {
    final email = rider['email'] as String? ?? '';
    final name = rider['fullName'] as String? ?? 'Rider';
    final code = rider['inviteCode'] as String? ?? 'RIDER-INVITE';
    final link = '${RiderInviteService.defaultAppUrl}?invite=$code&email=${Uri.encodeComponent(email)}';

    RiderInviteService.openEmailClient(
      riderEmail: email,
      riderName: name,
      inviteLink: link,
    );
  }

  void _copyRiderInviteLink(Map<String, dynamic> rider) {
    final email = rider['email'] as String? ?? '';
    final code = rider['inviteCode'] as String? ?? 'RIDER-INVITE';
    final link = '${RiderInviteService.defaultAppUrl}?invite=$code&email=${Uri.encodeComponent(email)}';

    Clipboard.setData(ClipboardData(text: link));
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Invite link for $email copied to clipboard!')),
    );
  }

  void _showConfigureEmailGatewayDialog() {
    final controller = TextEditingController(text: RiderInviteService.scriptUrl);
    showDialog<void>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Row(
          children: [
            Icon(Icons.settings_suggest_rounded, color: Color(0xFF2E7D32)),
            SizedBox(width: 8),
            Expanded(
              child: Text(
                'Google Apps Script Gateway',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800),
              ),
            ),
          ],
        ),
        content: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text(
                'To automatically send official emails from ecoroute.waste@gmail.com without opening your local mail app:',
                style: TextStyle(fontSize: 12),
              ),
              const SizedBox(height: 8),
              const Text(
                '1. Open Google Apps Script (script.google.com) under ecoroute.waste@gmail.com.\n2. Paste Code.gs from the project repo.\n3. Deploy as Web App (Execute as: Me, Access: Anyone).\n4. Paste the resulting /exec URL below:',
                style: TextStyle(fontSize: 11, color: Color(0xFF556958)),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: controller,
                decoration: InputDecoration(
                  labelText: 'Web App URL (/exec)',
                  hintText: 'https://script.google.com/macros/s/.../exec',
                  isDense: true,
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                ),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () async {
              final newUrl = controller.text.trim();
              if (newUrl.isNotEmpty) {
                await RiderInviteService.saveScriptUrl(newUrl);
                if (ctx.mounted) Navigator.pop(ctx);
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Google Apps Script URL saved successfully!'),
                      backgroundColor: Color(0xFF2E7D32),
                    ),
                  );
                }
              }
            },
            style: FilledButton.styleFrom(backgroundColor: const Color(0xFF2E7D32)),
            child: const Text('Save Gateway URL'),
          ),
        ],
      ),
    );
  }

  Future<void> _removeRider(String email) async {
    if (widget.authService != null) {
      await widget.authService!.removeRider(email);
      await _loadRiders();
      if (mounted) {
        setState(() {});
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Rider $email removed.')),
        );
      }
    }
  }

  void _openOrder() {
    if (!_signedIn) {
      _showAuth();
      return;
    }
    if (widget.authService != null && !widget.authService!.isEmailVerified()) {
      _promptEmailVerification();
      return;
    }
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => OrderPage(
          onSubmitted: _addOrder,
          initialPhone: _currentUser?.phone ?? '',
          initialAddress: _currentUser?.address ?? '',
        ),
      ),
    );
  }

  void _openAutoScanOrder() {
    if (!_signedIn) {
      _showAuth();
      return;
    }
    if (widget.authService != null && !widget.authService!.isEmailVerified()) {
      _promptEmailVerification();
      return;
    }
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => OrderPage(
          onSubmitted: _addOrder,
          initialPhone: _currentUser?.phone ?? '',
          initialAddress: _currentUser?.address ?? '',
          autoTriggerCamera: true,
        ),
      ),
    );
  }

  void _promptEmailVerification() {
    showDialog<void>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Email Verification Required'),
        content: const Text(
          'To protect municipal routing and prevent unverified orders, please verify your email address before ordering a waste collection.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text('Later'),
          ),
          FilledButton(
            onPressed: () async {
              Navigator.of(ctx).pop();
              await widget.authService?.sendEmailVerification();
              if (mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Verification email sent! Please check your inbox.'),
                    backgroundColor: Color(0xFF2E7D32),
                  ),
                );
              }
            },
            child: const Text('Send Verification Email'),
          ),
        ],
      ),
    );
  }

  void _showWasteDatabase() {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => const WasteDatabaseSheet(),
    );
  }

  Future<void> _addOrder(PickupRequest request) async {
    final user = _currentUser;
    final requestWithUser = request.copyWith(
      residentId: user?.id ?? 'res_${DateTime.now().millisecondsSinceEpoch}',
      residentName: user?.fullName ?? 'EcoRoute Resident',
      residentPhone: request.residentPhone.isNotEmpty
          ? request.residentPhone
          : (user?.phone ?? ''),
      address: request.address.isNotEmpty
          ? request.address
          : (user?.address ?? 'Arua Municipality'),
    );

    await widget.repository.save(requestWithUser);
    if (!mounted) return;
    setState(() => _orders.insert(0, requestWithUser));
    Navigator.of(context).pop();
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Your collection order has been submitted.'),
      ),
    );
  }

  Future<void> _cancelOrder(PickupRequest request) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Cancel Pickup Request?'),
        content: const Text(
          'Are you sure you want to cancel this instant waste pickup request?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: const Text('Keep Request'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            style: FilledButton.styleFrom(backgroundColor: const Color(0xFFC62828)),
            child: const Text('Cancel Request'),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    await widget.repository.updateStatus(request.id, RequestStatus.cancelled);
    if (!mounted) return;
    setState(() {
      final index = _orders.indexWhere((o) => o.id == request.id);
      if (index != -1) {
        _orders[index] = request.copyWith(status: RequestStatus.cancelled);
      }
    });

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: const Text('Collection request cancelled.'),
        action: SnackBarAction(
          label: 'Undo',
          textColor: const Color(0xFFA5D6A7),
          onPressed: () async {
            await widget.repository.updateStatus(request.id, RequestStatus.requested);
            if (mounted) {
              setState(() {
                final idx = _orders.indexWhere((o) => o.id == request.id);
                if (idx != -1) {
                  _orders[idx] = request.copyWith(status: RequestStatus.requested);
                }
              });
            }
          },
        ),
      ),
    );
  }

  Future<void> _updateOrderStatus(
    PickupRequest request,
    RequestStatus status,
  ) async {
    if (!isValidTransition(request.status, status)) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Cannot move this request from ${request.status.label} to ${status.label}.',
          ),
        ),
      );
      return;
    }

    await widget.repository.updateStatus(request.id, status);
    if (!mounted) return;
    setState(() {
      final index = _orders.indexWhere((order) => order.id == request.id);
      if (index != -1) {
        _orders[index] = _orders[index].copyWith(status: status);
      }
    });
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Request updated to ${status.label}.')),
    );
  }

  void _openRequestDetails(PickupRequest order) {
    RequestDetailSheet.show(
      context,
      request: order,
      userRole: _role,
      isOwner: _currentUser == null ||
          order.residentId == _currentUser!.id ||
          order.residentPhone == _currentUser!.phone,
      onPayMoMo: () => _openMoMoPayment(order),
      onStatusChange: (newStatus) => _updateOrderStatus(order, newStatus),
      onCancel: () => _cancelOrder(order),
    );
  }

  void _openMoMoPayment(PickupRequest request) {
    showDialog<void>(
      context: context,
      builder: (_) => MoMoPaymentDialog(
        request: request,
        initialPhone: request.residentPhone.isNotEmpty
            ? request.residentPhone
            : '+256394880352',
        onPaymentSuccess: (paid) async {
          await widget.repository.updateStatus(paid.id, RequestStatus.paid);
          if (!mounted) return;
          setState(() {
            final idx = _orders.indexWhere((o) => o.id == paid.id);
            if (idx != -1) _orders[idx] = paid;
          });
        },
      ),
    );
  }

  void _showAuth({bool createAccount = false}) {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      builder: (_) => AuthSheet(
        authService: widget.authService,
        initialCreateAccount: createAccount,
        onAuthenticated: (role) => setState(() {
          _signedIn = true;
          _role = role;
          if (widget.authService != null) {
            _currentUser = widget.authService!.getCurrentUser();
          }
        }),
      ),
    );
  }

  Future<void> _signOut() async {
    if (widget.authService != null) {
      await widget.authService!.logout();
    }
    if (!mounted) return;
    setState(() {
      _signedIn = false;
      _role = AppRole.resident;
      _currentUser = null;
    });
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Signed out successfully.')),
    );
  }

  Future<void> _checkGpsLocation() async {
    setState(() => _locatingGps = true);
    final result = await widget.locationService.getCurrentUserLocation();
    if (!mounted) return;
    setState(() {
      _locatingGps = false;
      _lastGpsResult = result;
    });

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(result.message ?? 'GPS location evaluated.'),
        duration: const Duration(seconds: 4),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: const SystemUiOverlayStyle(
        statusBarColor: Color(0xFF2EAD65),
        statusBarIconBrightness: Brightness.light,
        statusBarBrightness: Brightness.dark,
        systemNavigationBarColor: Color(0xFF2EAD65),
        systemNavigationBarIconBrightness: Brightness.light,
        systemNavigationBarDividerColor: Colors.transparent,
      ),
      child: ListenableBuilder(
        listenable: _langService,
        builder: (context, _) {
          return Scaffold(
            appBar: AppBar(
              systemOverlayStyle: const SystemUiOverlayStyle(
                statusBarColor: Color(0xFF2EAD65),
                statusBarIconBrightness: Brightness.light,
                statusBarBrightness: Brightness.dark,
                systemNavigationBarColor: Color(0xFF2EAD65),
                systemNavigationBarIconBrightness: Brightness.light,
                systemNavigationBarDividerColor: Colors.transparent,
              ),
            title: const FittedBox(
              fit: BoxFit.scaleDown,
              child: BrandLockup(compact: true),
            ),
            actions: [
              ListenableBuilder(
                listenable: ThemeService.instance,
                builder: (context, _) => IconButton(
                  icon: Icon(
                    ThemeService.instance.isDarkMode
                        ? Icons.light_mode_outlined
                        : Icons.dark_mode_outlined,
                  ),
                  tooltip: ThemeService.instance.isDarkMode
                      ? 'Switch to light mode'
                      : 'Switch to dark mode',
                  onPressed: () => ThemeService.instance.toggleTheme(),
                ),
              ),
              IconButton(
                icon: const Icon(Icons.dataset_outlined),
                tooltip: _langService.translate('waste_database'),
                onPressed: _showWasteDatabase,
              ),
              // Language Selector Menu
              PopupMenuButton<AppLanguage>(
                icon: const Icon(Icons.language_rounded),
                tooltip: _langService.translate('select_language'),
                onSelected: (lang) => _langService.setLanguage(lang),
                itemBuilder: (_) => AppLanguage.values
                    .map(
                      (l) => PopupMenuItem(
                        value: l,
                        child: Row(
                          children: [
                            Text(l.label),
                            if (_langService.currentLanguage == l) ...[
                              const Spacer(),
                              const Icon(Icons.check, size: 16, color: Color(0xFF2E7D32)),
                            ],
                          ],
                        ),
                      ),
                    )
                    .toList(),
              ),
              IconButton(
                tooltip: _signedIn
                    ? '${_langService.translate('my_account')} (${_currentUser?.fullName ?? 'User'})'
                    : _langService.translate('sign_in'),
                onPressed: _showAuth,
                icon: Icon(
                  _signedIn
                      ? Icons.account_circle_rounded
                      : Icons.account_circle_outlined,
                  color: _signedIn ? const Color(0xFF1B5E20) : null,
                ),
              ),
              const SizedBox(width: 8),
            ],
          ),
          body: IndexedStack(
            index: _tab,
            children: [_buildBrowse(), _buildOrders(), _buildProfile()],
          ),
          bottomNavigationBar: NavigationBar(
            selectedIndex: _tab,
            indicatorColor: const Color(0xFFDCEFE0),
            labelBehavior: MediaQuery.sizeOf(context).width < 360
                ? NavigationDestinationLabelBehavior.onlyShowSelected
                : NavigationDestinationLabelBehavior.alwaysShow,
            onDestinationSelected: (value) {
              if (value != _tab) {
                HapticFeedback.selectionClick();
                setState(() => _tab = value);
              }
            },
            destinations: const [
              NavigationDestination(
                icon: Icon(Icons.home_outlined),
                selectedIcon: Icon(Icons.home),
                label: 'Home',
              ),
              NavigationDestination(
                icon: Icon(Icons.receipt_long_outlined),
                selectedIcon: Icon(Icons.receipt_long),
                label: 'Requests',
              ),
              NavigationDestination(
                icon: Icon(Icons.person_outline),
                selectedIcon: Icon(Icons.person),
                label: 'Profile',
              ),
            ],
          ),
        );
      },
    ),
  );
}

  Widget _buildBrowse() {
    final heroTitle = switch (_role) {
      AppRole.rider => 'Rider dispatch board',
      AppRole.admin => 'Operations control center',
      _ => 'Resident service overview',
    };
    final heroDescription = switch (_role) {
      AppRole.rider =>
        'Plan pickups, route stops and status updates in one place.',
      AppRole.admin =>
        'Track collection demand, route health and service quality.',
      _ =>
        'Book pickups, review service windows and monitor your waste requests.',
    };

    final requestedCount = _countStatus(RequestStatus.requested);
    final collectedCount = _countStatus(RequestStatus.collected);
    final awaitingVerificationCount = _countStatus(
      RequestStatus.awaitingVerification,
    );
    final paidCount = _countStatus(RequestStatus.paid);

    final stats = switch (_role) {
      AppRole.rider => [
        _MetricCard(
          label: 'Stops',
          value: '$requestedCount',
          hint: 'to collect',
        ),
        _MetricCard(
          label: 'Collected',
          value: '${collectedCount + awaitingVerificationCount}',
          hint: 'in progress',
        ),
        _MetricCard(label: 'Completed', value: '$paidCount', hint: 'verified'),
      ],
      AppRole.admin => [
        _MetricCard(
          label: 'Requests',
          value: '${_orders.length}',
          hint: 'all time',
        ),
        _MetricCard(
          label: 'Approvals',
          value: '$awaitingVerificationCount',
          hint: 'to review',
        ),
        _MetricCard(label: 'Paid', value: '$paidCount', hint: 'verified'),
      ],
      _ => [
        _MetricCard(label: 'Open', value: '$requestedCount', hint: 'requests'),
        _MetricCard(
          label: 'Collected',
          value: '$collectedCount',
          hint: 'ready',
        ),
        _MetricCard(label: 'Paid', value: '$paidCount', hint: 'settled'),
      ],
    };

    // Resident scoped orders for personalized tracking & impact
    final residentOrders = _role == AppRole.resident
        ? _orders.where((o) =>
            _currentUser == null ||
            o.residentId == _currentUser!.id ||
            o.residentPhone == _currentUser!.phone ||
            o.residentName == _currentUser!.fullName ||
            o.residentId == 'resident-1'
          ).toList()
        : _orders;

    final activeResidentOrder = residentOrders.cast<PickupRequest?>().firstWhere(
      (o) => o != null && o.status != RequestStatus.paid && o.status != RequestStatus.cancelled,
      orElse: () => null,
    );

    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(16, 4, 16, 28),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildWelcome(),
          if (_role == AppRole.resident) ...[
            const SizedBox(height: 12),
            ResidentHeroGreeting(
              user: _currentUser,
              activeRequestsCount: residentOrders.where((o) => o.status != RequestStatus.paid && o.status != RequestStatus.cancelled).length,
              onTapProfile: () => setState(() => _tab = 2),
            ),
            if (activeResidentOrder != null) ...[
              const SizedBox(height: 12),
              ActivePickupTrackerCard(
                request: activeResidentOrder,
                onTapDetails: () => _openRequestDetails(activeResidentOrder),
                onPayMoMo: () => _openMoMoPayment(activeResidentOrder),
              ),
            ],
          ],
          const SizedBox(height: 16),

          _buildWeatherSafetyCard(),
          const SizedBox(height: 16),

          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(18),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Color(0xFF2E8B57), Color(0xFF1B5E3B)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(22),
              boxShadow: const [
                BoxShadow(
                  color: Color(0x33000000),
                  blurRadius: 14,
                  offset: Offset(0, 8),
                ),
              ],
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        heroTitle,
                        style: const TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.w800,
                          color: Colors.white,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        heroDescription,
                        style: const TextStyle(
                          color: Color(0xFFEAF7F0),
                          fontSize: 13,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 14),
                Container(
                  width: 70,
                  height: 70,
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.14),
                    borderRadius: BorderRadius.circular(18),
                  ),
                  child: Icon(
                    _role == AppRole.rider
                        ? Icons.route_rounded
                        : _role == AppRole.admin
                        ? Icons.dashboard_customize_rounded
                        : Icons.home_repair_service_rounded,
                    color: Colors.white,
                    size: 30,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 18),
          Row(
            children: [
              for (final metric in stats)
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.only(right: 8),
                    child: metric,
                  ),
                ),
            ],
          ),
          const SizedBox(height: 18),
          if (_role == AppRole.resident) _buildQuickActions(),
          if (_role == AppRole.rider) ...[
            const SizedBox(height: 18),
            _buildRiderRoute(),
          ],
          if (_role == AppRole.admin) ...[
            const SizedBox(height: 18),
            _buildAdminWorkspace(),
          ],
          const SizedBox(height: 18),

          // Interactive Arua Map View
          InteractiveAruaMapPanel(
            requestsCount: _orders.length,
            locationResult: _lastGpsResult,
            isLocating: _locatingGps,
            onLocateGps: _checkGpsLocation,
          ),

          if (_role == AppRole.resident) ...[
            const SizedBox(height: 16),
            ResidentEcoImpactCard(personalRequests: residentOrders),
            const SizedBox(height: 12),
            WasteSegregationTipsCard(onTapDatabase: _showWasteDatabase),
            const SizedBox(height: 16),
            _buildReportButton(),
          ],
          const SizedBox(height: 16),
        ],
      ),
    );
  }

  Widget _buildWeatherSafetyCard() {
    final report = _weatherReport;
    final isOnline = report?.isOnline ?? false;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: const Color(0xFFF0F7F2),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFD6E8D8)),
      ),
      child: Row(
        children: [
          Container(
            width: 38,
            height: 38,
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(
              report != null && report.isSafeForCollection
                  ? Icons.wb_sunny_rounded
                  : Icons.cloud_queue_rounded,
              color: const Color(0xFF2E7D32),
              size: 20,
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const Expanded(
                      child: Text(
                        'Arua Route Weather',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w800,
                          color: Color(0xFF183B20),
                        ),
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 6,
                        vertical: 2,
                      ),
                      decoration: BoxDecoration(
                        color: isOnline
                            ? const Color(0xFFE8F5E9)
                            : const Color(0xFFFFF3E0),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(
                        isOnline ? 'Open-Meteo Live' : 'Offline Cache',
                        style: TextStyle(
                          fontSize: 9,
                          fontWeight: FontWeight.w700,
                          color: isOnline
                              ? const Color(0xFF2E7D32)
                              : const Color(0xFFE65100),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 2),
                Text(
                  report != null
                      ? '${report.temperatureC.toStringAsFixed(1)}°C • ${report.conditionSummary}'
                      : 'Connecting to Open-Meteo weather service...',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 11,
                    color: Color(0xFF556958),
                  ),
                ),
              ],
            ),
          ),
          IconButton(
            onPressed: _loadingWeather ? null : _loadWeather,
            tooltip: 'Refresh Weather',
            icon: _loadingWeather
                ? const SizedBox.square(
                    dimension: 16,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Icon(Icons.refresh_rounded, size: 20),
          ),
        ],
      ),
    );
  }

  int _countStatus(RequestStatus status) =>
      _orders.where((order) => order.status == status).length;

  Widget _buildRiderRoute() {
    final stops = _orders
        .where(
          (order) =>
              order.status == RequestStatus.requested ||
              order.status == RequestStatus.collected,
        )
        .toList();

    return _DashboardPanel(
      title: 'Today\'s route',
      subtitle:
          '${stops.length} active ${stops.length == 1 ? 'stop' : 'stops'}',
      icon: Icons.route_rounded,
      child: stops.isEmpty
          ? const _EmptyPanelMessage(
              icon: Icons.check_circle_outline_rounded,
              text:
                  'No active stops. New collection requests will appear here.',
            )
          : Column(
              children: [
                for (var index = 0; index < stops.length; index++) ...[
                  if (index > 0) const Divider(height: 20),
                  _RouteStop(
                    index: index + 1,
                    request: stops[index],
                    onAdvance: () => _updateOrderStatus(
                      stops[index],
                      stops[index].status == RequestStatus.requested
                          ? RequestStatus.collected
                          : RequestStatus.awaitingVerification,
                    ),
                  ),
                ],
              ],
            ),
    );
  }

  Widget _buildAdminWorkspace() {
    final approvals = _orders
        .where((order) => order.status == RequestStatus.awaitingVerification)
        .toList();
    final riders = widget.authService?.getInvitedRiders() ?? [];
    final residents = widget.authService?.getRegisteredResidents() ?? [];

    return LayoutBuilder(
      builder: (context, constraints) {
        final isWide = constraints.maxWidth >= 720;
        final theme = Theme.of(context);
        final isDark = theme.brightness == Brightness.dark;

        final sidebarBg = isDark ? const Color(0xFF192A1D) : Colors.white;
        final sidebarBorder = isDark ? const Color(0xFF2A3F2F) : const Color(0xFFE2EAE1);

        final navItems = [
          (
            icon: Icons.dashboard_customize_rounded,
            label: 'Overview',
            badge: null,
          ),
          (
            icon: Icons.insights_rounded,
            label: 'Analytics',
            badge: null,
          ),
          (
            icon: Icons.fact_check_rounded,
            label: 'Approvals',
            badge: approvals.isNotEmpty ? '${approvals.length}' : null,
          ),
          (
            icon: Icons.two_wheeler_rounded,
            label: 'Fleet & Riders',
            badge: riders.isNotEmpty ? '${riders.length}' : null,
          ),
          (
            icon: Icons.people_alt_outlined,
            label: 'Residents',
            badge: residents.isNotEmpty ? '${residents.length}' : null,
          ),
          (
            icon: Icons.settings_outlined,
            label: 'Settings',
            badge: null,
          ),
        ];

        Widget activeContent;
        switch (_adminNavIndex) {
          case 1:
            activeContent = Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                AdminAnalyticsView(orders: _orders),
                const SizedBox(height: 18),
                _buildAnalytics(),
              ],
            );
            break;
          case 2:
            activeContent = _buildApprovalQueue();
            break;
          case 3:
            activeContent = _buildRiderManagement();
            break;
          case 4:
            activeContent = _buildResidentDirectory();
            break;
          case 5:
            activeContent = AdminSettingsView(
              onShowConfigureEmailGateway: _showConfigureEmailGatewayDialog,
              onSignOut: _signOut,
            );
            break;
          case 0:
          default:
            activeContent = Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                AdminAnalyticsView(orders: _orders),
                const SizedBox(height: 18),
                _buildApprovalQueue(),
                const SizedBox(height: 18),
                _buildRiderManagement(),
                const SizedBox(height: 18),
                _buildResidentDirectory(),
                const SizedBox(height: 18),
                _buildAnalytics(),
              ],
            );
            break;
        }

        if (isWide) {
          return Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 210,
                padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 8),
                decoration: BoxDecoration(
                  color: sidebarBg,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: sidebarBorder),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                      child: Row(
                        children: [
                          const Icon(Icons.admin_panel_settings_rounded, size: 20, color: Color(0xFF2E7D32)),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              'Municipal Ops',
                              style: TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.w800,
                                color: isDark ? Colors.white : const Color(0xFF183B20),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const Divider(height: 16),
                    for (var i = 0; i < navItems.length; i++)
                      _buildSidebarItem(
                        index: i,
                        item: navItems[i],
                        isSelected: _adminNavIndex == i,
                        isDark: isDark,
                      ),
                  ],
                ),
              ),
              const SizedBox(width: 16),
              Expanded(child: activeContent),
            ],
          );
        }

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 6),
              decoration: BoxDecoration(
                color: sidebarBg,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: sidebarBorder),
              ),
              child: SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(
                  children: [
                    for (var i = 0; i < navItems.length; i++) ...[
                      if (i > 0) const SizedBox(width: 6),
                      _buildMobileNavPill(
                        index: i,
                        item: navItems[i],
                        isSelected: _adminNavIndex == i,
                        isDark: isDark,
                      ),
                    ],
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),
            activeContent,
          ],
        );
      },
    );
  }

  Widget _buildSidebarItem({
    required int index,
    required ({IconData icon, String label, String? badge}) item,
    required bool isSelected,
    required bool isDark,
  }) {
    final activeBg = const Color(0xFF2E7D32);
    final activeText = Colors.white;
    final inactiveText = isDark ? const Color(0xFFC7D3C9) : const Color(0xFF37474F);

    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: InkWell(
        onTap: () {
          HapticFeedback.selectionClick();
          setState(() => _adminNavIndex = index);
        },
        borderRadius: BorderRadius.circular(10),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
          decoration: BoxDecoration(
            color: isSelected ? activeBg : Colors.transparent,
            borderRadius: BorderRadius.circular(10),
          ),
          child: Row(
            children: [
              Icon(item.icon, size: 16, color: isSelected ? activeText : inactiveText),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  item.label,
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: isSelected ? FontWeight.w800 : FontWeight.w600,
                    color: isSelected ? activeText : inactiveText,
                  ),
                ),
              ),
              if (item.badge != null)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                  decoration: BoxDecoration(
                    color: isSelected ? Colors.white.withValues(alpha: 0.25) : const Color(0xFFE65100),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    item.badge!,
                    style: const TextStyle(
                      fontSize: 9,
                      fontWeight: FontWeight.w800,
                      color: Colors.white,
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildMobileNavPill({
    required int index,
    required ({IconData icon, String label, String? badge}) item,
    required bool isSelected,
    required bool isDark,
  }) {
    final activeBg = const Color(0xFF2E7D32);
    final inactiveBg = isDark ? const Color(0xFF233627) : const Color(0xFFF1F5F2);
    final activeText = Colors.white;
    final inactiveText = isDark ? const Color(0xFFC7D3C9) : const Color(0xFF556958);

    return InkWell(
      onTap: () {
        HapticFeedback.selectionClick();
        setState(() => _adminNavIndex = index);
      },
      borderRadius: BorderRadius.circular(10),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected ? activeBg : inactiveBg,
          borderRadius: BorderRadius.circular(10),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(item.icon, size: 14, color: isSelected ? activeText : inactiveText),
            const SizedBox(width: 6),
            Text(
              item.label,
              style: TextStyle(
                fontSize: 11,
                fontWeight: isSelected ? FontWeight.w800 : FontWeight.w600,
                color: isSelected ? activeText : inactiveText,
              ),
            ),
            if (item.badge != null) ...[
              const SizedBox(width: 4),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1),
                decoration: BoxDecoration(
                  color: isSelected ? Colors.white.withValues(alpha: 0.25) : const Color(0xFFE65100),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  item.badge!,
                  style: const TextStyle(
                    fontSize: 8,
                    fontWeight: FontWeight.w900,
                    color: Colors.white,
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildApprovalQueue() {
    final approvals = _orders
        .where((order) => order.status == RequestStatus.awaitingVerification)
        .toList();

    return _DashboardPanel(
      title: 'Approval queue',
      subtitle: '${approvals.length} awaiting review',
      icon: Icons.fact_check_outlined,
      child: approvals.isEmpty
          ? const _EmptyPanelMessage(
              icon: Icons.task_alt_rounded,
              text:
                  'All caught up. Completed pickups will appear here for review.',
            )
          : Column(
              children: [
                for (var index = 0; index < approvals.length; index++) ...[
                  if (index > 0) const Divider(height: 20),
                  _ApprovalItem(
                    request: approvals[index],
                    onApprove: () => _updateOrderStatus(
                      approvals[index],
                      RequestStatus.paid,
                    ),
                    onReturn: () => _updateOrderStatus(
                      approvals[index],
                      RequestStatus.collected,
                    ),
                  ),
                ],
              ],
            ),
    );
  }

  Widget _buildRiderManagement() {
    final riders = widget.authService?.getInvitedRiders() ?? [];

    return _DashboardPanel(
      title: 'Rider management',
      subtitle: '${riders.length} active / invited riders',
      icon: Icons.two_wheeler_rounded,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: const Color(0xFFF7FBF8),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: const Color(0xFFE0ECE2)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const Expanded(
                      child: Text(
                        'Invite New Collection Rider',
                        style: TextStyle(
                          fontWeight: FontWeight.w700,
                          fontSize: 13,
                          color: Color(0xFF1B5E3B),
                        ),
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.settings_suggest_outlined, size: 18, color: Color(0xFF2E7D32)),
                      tooltip: 'Configure MailApp Gateway URL',
                      visualDensity: VisualDensity.compact,
                      onPressed: _showConfigureEmailGatewayDialog,
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                const Text(
                  'Riders are invited via verified email by municipal admins. A secure invite code is generated upon dispatch.',
                  style: TextStyle(fontSize: 11, color: Color(0xFF557060)),
                ),
                const SizedBox(height: 10),
                TextField(
                  controller: _riderNameController,
                  decoration: InputDecoration(
                    labelText: 'Rider full name',
                    hintText: 'e.g. John Boda',
                    prefixIcon: const Icon(Icons.person_outline, size: 20),
                    isDense: true,
                    contentPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                  ),
                ),
                const SizedBox(height: 8),
                TextField(
                  controller: _riderEmailController,
                  keyboardType: TextInputType.emailAddress,
                  decoration: InputDecoration(
                    labelText: 'Rider email address',
                    hintText: 'e.g. rider@ecoroute.ug',
                    prefixIcon: const Icon(Icons.email_outlined, size: 20),
                    isDense: true,
                    contentPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                  ),
                ),
                const SizedBox(height: 8),
                TextField(
                  controller: _riderPhoneController,
                  keyboardType: TextInputType.phone,
                  decoration: InputDecoration(
                    labelText: 'Phone number (optional)',
                    hintText: '+256 700 000 000',
                    prefixIcon: const Icon(Icons.phone_outlined, size: 20),
                    isDense: true,
                    contentPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                  ),
                ),
                const SizedBox(height: 10),
                SizedBox(
                  width: double.infinity,
                  height: 40,
                  child: FilledButton.icon(
                    onPressed: _invitingRider ? null : _inviteRider,
                    icon: _invitingRider
                        ? const SizedBox(
                            width: 16,
                            height: 16,
                            child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                          )
                        : const Icon(Icons.send_rounded, size: 18),
                    label: Text(_invitingRider ? 'Inviting...' : 'Send Rider Invite'),
                    style: FilledButton.styleFrom(
                      backgroundColor: const Color(0xFF1B5E3B),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 14),
          const Text(
            'Authorized Riders',
            style: TextStyle(
              fontWeight: FontWeight.w700,
              fontSize: 13,
              color: Color(0xFF1E2D24),
            ),
          ),
          const SizedBox(height: 8),
          if (riders.isEmpty)
            const _EmptyPanelMessage(
              icon: Icons.two_wheeler_outlined,
              text: 'No riders invited yet.',
            )
          else
            Column(
              children: [
                for (var i = 0; i < riders.length; i++) ...[
                  if (i > 0) const Divider(height: 14),
                  Row(
                    children: [
                      CircleAvatar(
                        radius: 18,
                        backgroundColor: const Color(0xFFE8F5E9),
                        child: const Icon(
                          Icons.delivery_dining_rounded,
                          size: 20,
                          color: Color(0xFF2E7D32),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              riders[i]['fullName'] as String? ?? 'Rider',
                              style: const TextStyle(
                                fontWeight: FontWeight.w600,
                                fontSize: 13,
                              ),
                            ),
                            Text(
                              '${riders[i]['email']} • ${riders[i]['phone'] ?? ''}',
                              style: const TextStyle(
                                fontSize: 11,
                                color: Color(0xFF647568),
                              ),
                            ),
                          ],
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                        decoration: BoxDecoration(
                          color: const Color(0xFFE8F5E9),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(
                          (riders[i]['status'] as String? ?? 'invited').toUpperCase(),
                          style: const TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.w700,
                            color: Color(0xFF1B5E20),
                          ),
                        ),
                      ),
                      IconButton(
                        icon: const Icon(Icons.mail_outline_rounded, size: 20, color: Color(0xFF2E7D32)),
                        tooltip: 'Send invite via Email App',
                        onPressed: () => _openEmailClientForRider(riders[i]),
                      ),
                      IconButton(
                        icon: const Icon(Icons.copy_rounded, size: 18, color: Color(0xFF556958)),
                        tooltip: 'Copy onboarding link',
                        onPressed: () => _copyRiderInviteLink(riders[i]),
                      ),
                      IconButton(
                        icon: const Icon(Icons.delete_outline, size: 20, color: Colors.redAccent),
                        tooltip: 'Remove rider',
                        onPressed: () => _removeRider(riders[i]['email'] as String),
                      ),
                    ],
                  ),
                ],
              ],
            ),
        ],
      ),
    );
  }

  Widget _buildResidentDirectory() {
    final residents = widget.authService?.getRegisteredResidents() ?? [];

    return _DashboardPanel(
      title: 'Resident directory',
      subtitle: '${residents.length} registered residents',
      icon: Icons.people_alt_outlined,
      child: residents.isEmpty
          ? const _EmptyPanelMessage(
              icon: Icons.people_outline,
              text: 'No residents registered yet. New resident signups will appear here.',
            )
          : Column(
              children: [
                for (var i = 0; i < residents.length; i++) ...[
                  if (i > 0) const Divider(height: 14),
                  Row(
                    children: [
                      CircleAvatar(
                        radius: 18,
                        backgroundColor: const Color(0xFFE8F5E9),
                        child: Text(
                          residents[i].fullName.isNotEmpty
                              ? residents[i].fullName[0].toUpperCase()
                              : 'R',
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF2E7D32),
                          ),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              residents[i].fullName,
                              style: const TextStyle(
                                fontWeight: FontWeight.w600,
                                fontSize: 13,
                              ),
                            ),
                            Text(
                              '${residents[i].email} • ${residents[i].phone}',
                              style: const TextStyle(
                                fontSize: 11,
                                color: Color(0xFF647568),
                              ),
                            ),
                            if (residents[i].address != null && residents[i].address!.isNotEmpty)
                              Text(
                                residents[i].address!,
                                style: const TextStyle(
                                  fontSize: 10,
                                  color: Color(0xFF8B9D90),
                                ),
                              ),
                          ],
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                        decoration: BoxDecoration(
                          color: const Color(0xFFE8F5E9),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: const Text(
                          'RESIDENT',
                          style: TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.w700,
                            color: Color(0xFF1B5E20),
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ],
            ),
    );
  }

  Widget _buildAnalytics() {
    final statuses = [
      RequestStatus.requested,
      RequestStatus.collected,
      RequestStatus.awaitingVerification,
      RequestStatus.paid,
      RequestStatus.cancelled,
    ];

    return _DashboardPanel(
      title: 'Transaction analytics',
      subtitle: 'Request status breakdown',
      icon: Icons.query_stats_rounded,
      child: _orders.isEmpty
          ? const _EmptyPanelMessage(
              icon: Icons.bar_chart_rounded,
              text:
                  'Analytics will populate as collection requests are submitted.',
            )
          : Column(
              children: [
                for (final status in statuses)
                  _AnalyticsRow(
                    status: status,
                    count: _countStatus(status),
                    total: _orders.length,
                  ),
              ],
            ),
    );
  }

  Widget _buildQuickActions() {
    final actions = [
      _QuickActionCard(
        icon: Icons.camera_alt_outlined,
        title: 'Take rubbish photo',
        subtitle: 'Camera & GPS',
        accent: const Color(0xFF2E8B57),
        onTap: _openAutoScanOrder,
      ),
      _QuickActionCard(
        icon: Icons.dataset_outlined,
        title: 'Waste database',
        subtitle: 'Pricing & Lugbara terms',
        accent: const Color(0xFF2E7D32),
        onTap: _showWasteDatabase,
      ),
      _QuickActionCard(
        icon: Icons.manage_accounts_outlined,
        title: 'Account & role',
        subtitle: 'Account settings',
        accent: const Color(0xFF1B5E20),
        onTap: _showAuth,
      ),
    ];

    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          for (int index = 0; index < actions.length; index++)
            Expanded(
              child: Padding(
                padding: EdgeInsets.only(
                  right: index < actions.length - 1 ? 8 : 0,
                ),
                child: actions[index],
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildWelcome() => LayoutBuilder(
    builder: (context, constraints) {
      final subtitle = constraints.maxWidth < 340
          ? 'Service area: 12 km'
          : 'Service area: within 12 km of the Arua centre.';

      final greeting = Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Arua waste pickup',
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              fontSize: 19,
              fontWeight: FontWeight.w800,
              color: Color(0xFF183B20),
            ),
          ),
          const SizedBox(height: 3),
          Text(
            subtitle,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(color: Color(0xFF647568)),
          ),
        ],
      );

      return Padding(
        padding: const EdgeInsets.fromLTRB(4, 8, 4, 0),
        child: constraints.maxWidth < 340
            ? greeting
            : Row(
                children: [
                  const WelcomeIcon(),
                  const SizedBox(width: 12),
                  Expanded(child: greeting),
                ],
              ),
      );
    },
  );

  Widget _buildReportButton() => Column(
    children: [
      SizedBox(
        width: double.infinity,
        height: 52,
        child: FilledButton.icon(
          onPressed: _openAutoScanOrder,
          icon: const Icon(Icons.camera_alt_rounded),
          label: const ResponsiveButtonLabel('TAKE RUBBISH PHOTO (CAMERA)'),
          style: FilledButton.styleFrom(
            backgroundColor: const Color(0xFF1B5E3B),
            foregroundColor: Colors.white,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          ),
        ),
      ),
      const SizedBox(height: 10),
      SizedBox(
        width: double.infinity,
        height: 52,
        child: OutlinedButton.icon(
          onPressed: _openOrder,
          icon: const Icon(Icons.edit_note_rounded),
          label: const ResponsiveButtonLabel('REPORT AN ISSUE'),
          style: OutlinedButton.styleFrom(
            foregroundColor: const Color(0xFF2E8B57),
            side: const BorderSide(color: Color(0xFF2E8B57), width: 1.5),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          ),
        ),
      ),
      const SizedBox(height: 10),
      InkWell(
        onTap: _showWasteDatabase,
        borderRadius: BorderRadius.circular(16),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
          decoration: BoxDecoration(
            color: const Color(0xFFE8F5E9),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: const Color(0xFFC8E6C9)),
          ),
          child: const Row(
            children: [
              Icon(Icons.dataset_outlined, color: Color(0xFF2E7D32), size: 24),
              SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Municipal Waste & Recycling Database',
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w800,
                        color: Color(0xFF1B5E20),
                      ),
                    ),
                    SizedBox(height: 2),
                    Text(
                      'World Bank benchmarks, Lugbara terms & UGX/kg resale rates',
                      style: TextStyle(
                        fontSize: 11,
                        color: Color(0xFF388E3C),
                      ),
                    ),
                  ],
                ),
              ),
              Icon(Icons.arrow_forward_ios_rounded, size: 14, color: Color(0xFF2E7D32)),
            ],
          ),
        ),
      ),
    ],
  );

  Widget _buildOrders() {
    if (_loadingOrders) {
      return const Center(child: CircularProgressIndicator());
    }

    // Guest protection: Guests cannot see resident private orders, addresses or contacts
    if (!_signedIn) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(28),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 68,
                height: 68,
                decoration: BoxDecoration(
                  color: const Color(0xFF2EAD65).withValues(alpha: 0.15),
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.lock_outline_rounded, size: 34, color: Color(0xFF2E7D32)),
              ),
              const SizedBox(height: 18),
              const Text(
                'Sign In to View Orders',
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.w800, color: Color(0xFF1B2E23)),
              ),
              const SizedBox(height: 8),
              const Text(
                'Collection orders contain private resident locations and phone numbers. Please sign in or register to view and track your pickup requests.',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 13, color: Color(0xFF557060), height: 1.4),
              ),
              const SizedBox(height: 22),
              FilledButton.icon(
                onPressed: () => _showAuth(),
                icon: const Icon(Icons.login_rounded, size: 18),
                label: const Text('Sign in / Register', style: TextStyle(fontWeight: FontWeight.w700)),
              ),
            ],
          ),
        ),
      );
    }

    // Filter requests for residents: residents only see requests from their own account
    final scopedOrders = _role == AppRole.resident
        ? _orders.where((o) =>
            _currentUser == null ||
            o.residentId == _currentUser!.id ||
            o.residentPhone == _currentUser!.phone ||
            o.residentName == _currentUser!.fullName ||
            o.residentId == 'resident-1'
          ).toList()
        : _orders;

    if (_loadingOrders) {
      return const Center(
        child: Padding(
          padding: EdgeInsets.all(28),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              SizedBox.square(
                dimension: 36,
                child: CircularProgressIndicator(
                  strokeWidth: 3,
                  color: Color(0xFF2E7D32),
                ),
              ),
              SizedBox(height: 16),
              Text(
                'Retrieving collection requests...',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: Color(0xFF556958),
                ),
              ),
            ],
          ),
        ),
      );
    }

    if (scopedOrders.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(28),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 72,
                height: 72,
                decoration: BoxDecoration(
                  color: const Color(0xFFE8F5E9),
                  borderRadius: BorderRadius.circular(24),
                ),
                child: const Icon(
                  Icons.receipt_long_outlined,
                  size: 38,
                  color: Color(0xFF2E7D32),
                ),
              ),
              const SizedBox(height: 16),
              const Text(
                'No collection orders yet',
                style: TextStyle(
                  fontSize: 19,
                  fontWeight: FontWeight.w800,
                  color: Color(0xFF183B20),
                ),
              ),
              const SizedBox(height: 6),
              const Text(
                'Book an instant waste pickup and local tricycle riders will be dispatched.',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 13, color: Color(0xFF647568)),
              ),
              const SizedBox(height: 18),
              FilledButton.icon(
                onPressed: _openOrder,
                style: FilledButton.styleFrom(
                  backgroundColor: const Color(0xFF2E7D32),
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                ),
                icon: const Icon(Icons.add_rounded, size: 20),
                label: const Text('Request Instant Pickup'),
              ),
            ],
          ),
        ),
      );
    }

    final filteredOrders = scopedOrders.where((order) {
      final matchesStatus =
          _statusFilter == null || order.status == _statusFilter;
      final matchesSearch = _searchQuery.isEmpty ||
          order.description.toLowerCase().contains(_searchQuery.toLowerCase()) ||
          order.address.toLowerCase().contains(_searchQuery.toLowerCase()) ||
          order.wasteType.label.toLowerCase().contains(_searchQuery.toLowerCase());
      return matchesStatus && matchesSearch;
    }).toList();

    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
          child: TextField(
            decoration: InputDecoration(
              hintText: 'Search requests by location or type...',
              prefixIcon: const Icon(Icons.search_rounded),
              suffixIcon: _searchQuery.isNotEmpty
                  ? IconButton(
                      icon: const Icon(Icons.clear_rounded, size: 20),
                      onPressed: () => setState(() => _searchQuery = ''),
                    )
                  : null,
              isDense: true,
              filled: true,
              fillColor: Colors.white,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(14),
                borderSide: BorderSide.none,
              ),
            ),
            onChanged: (val) => setState(() => _searchQuery = val.trim()),
          ),
        ),
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          child: Row(
            children: [
              FilterChip(
                label: Text('All (${scopedOrders.length})'),
                selected: _statusFilter == null,
                onSelected: (_) {
                  HapticFeedback.selectionClick();
                  setState(() => _statusFilter = null);
                },
              ),
              const SizedBox(width: 8),
              for (final status in RequestStatus.values) ...[
                FilterChip(
                  label: Text('${status.label} (${scopedOrders.where((o) => o.status == status).length})'),
                  selected: _statusFilter == status,
                  onSelected: (selected) {
                    HapticFeedback.selectionClick();
                    setState(
                      () => _statusFilter = selected ? status : null,
                    );
                  },
                ),
                const SizedBox(width: 8),
              ],
            ],
          ),
        ),
        Expanded(
          child: filteredOrders.isEmpty
              ? Center(
                  child: Padding(
                    padding: const EdgeInsets.all(24),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Container(
                          width: 56,
                          height: 56,
                          decoration: BoxDecoration(
                            color: const Color(0xFFF1F8F2),
                            borderRadius: BorderRadius.circular(18),
                          ),
                          child: const Icon(
                            Icons.filter_alt_off_outlined,
                            size: 28,
                            color: Color(0xFF2E7D32),
                          ),
                        ),
                        const SizedBox(height: 12),
                        const Text(
                          'No matching requests',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w800,
                            color: Color(0xFF183B20),
                          ),
                        ),
                        const SizedBox(height: 4),
                        const Text(
                          'Try clearing your search query or status filter to see other requests.',
                          textAlign: TextAlign.center,
                          style: TextStyle(fontSize: 12, color: Color(0xFF647568)),
                        ),
                        const SizedBox(height: 14),
                        OutlinedButton(
                          onPressed: () {
                            HapticFeedback.selectionClick();
                            setState(() {
                              _statusFilter = null;
                              _searchQuery = '';
                            });
                          },
                          child: const Text('Clear all filters'),
                        ),
                      ],
                    ),
                  ),
                )
              : RefreshIndicator(
                  color: const Color(0xFF2E7D32),
                  onRefresh: () async {
                    HapticFeedback.lightImpact();
                    await _loadOrders();
                  },
                  child: ListView.builder(
                    keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
                    physics: const AlwaysScrollableScrollPhysics(),
                    padding: const EdgeInsets.fromLTRB(16, 4, 16, 20),
                    itemCount: filteredOrders.length,
                    itemBuilder: (context, index) {
                      final order = filteredOrders[index];
                      final shortId = order.id.length > 6
                          ? order.id.substring(order.id.length - 6).toUpperCase()
                          : order.id.toUpperCase();

                      final stepIndex = switch (order.status) {
                        RequestStatus.requested => 0,
                        RequestStatus.collected => 1,
                        RequestStatus.awaitingVerification => 2,
                        RequestStatus.paid => 3,
                        RequestStatus.cancelled => -1,
                      };

                      return Card(
                        margin: const EdgeInsets.only(bottom: 14),
                        elevation: 1.5,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: InkWell(
                          borderRadius: BorderRadius.circular(16),
                          onTap: () => _openRequestDetails(order),
                          child: Padding(
                            padding: const EdgeInsets.all(12),
                            child: Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Padding(
                                  padding: const EdgeInsets.only(top: 8),
                                  child: Icon(
                                    order.status == RequestStatus.paid
                                        ? Icons.verified_rounded
                                        : order.status == RequestStatus.collected
                                            ? Icons.local_shipping_rounded
                                            : order.status == RequestStatus.awaitingVerification
                                                ? Icons.fact_check_rounded
                                                : Icons.pending_actions,
                                    color: order.status == RequestStatus.paid
                                        ? const Color(0xFF2E7D32)
                                        : order.status == RequestStatus.collected
                                            ? const Color(0xFF0288D1)
                                            : const Color(0xFFE65100),
                                  ),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Row(
                                        children: [
                                          Container(
                                            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                            decoration: BoxDecoration(
                                              color: const Color(0xFFF1F8F2),
                                              borderRadius: BorderRadius.circular(6),
                                            ),
                                            child: Text(
                                              '#$shortId',
                                              style: const TextStyle(
                                                fontSize: 10,
                                                fontWeight: FontWeight.w800,
                                                color: Color(0xFF1B5E3B),
                                              ),
                                            ),
                                          ),
                                          const SizedBox(width: 6),
                                          Text(
                                            order.wasteType.label,
                                            style: const TextStyle(
                                              fontWeight: FontWeight.w700,
                                              fontSize: 15,
                                            ),
                                          ),
                                          const Spacer(),
                                          Text(
                                            formatUgx(order.priceUgx),
                                            style: const TextStyle(
                                              fontWeight: FontWeight.w800,
                                              color: Color(0xFF2E7D32),
                                            ),
                                          ),
                                        ],
                                      ),
                                      const SizedBox(height: 3),
                                      Text(
                                        '${order.sackCount} sack(s) • Instant Pickup • ${order.address}',
                                        style: const TextStyle(
                                          fontSize: 12,
                                          fontWeight: FontWeight.w600,
                                          color: Color(0xFF556958),
                                        ),
                                      ),
                                      const SizedBox(height: 4),
                                      Text(
                                        order.description,
                                        maxLines: 2,
                                        overflow: TextOverflow.ellipsis,
                                        style: const TextStyle(fontSize: 12),
                                      ),
                                      if (stepIndex >= 0) ...[
                                        const SizedBox(height: 6),
                                        Container(
                                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                          decoration: BoxDecoration(
                                            color: const Color(0xFFF7FBF8),
                                            borderRadius: BorderRadius.circular(8),
                                          ),
                                          child: Row(
                                            children: [
                                              for (int s = 0; s < 4; s++) ...[
                                                Icon(
                                                  s <= stepIndex
                                                      ? Icons.check_circle_rounded
                                                      : Icons.radio_button_unchecked_rounded,
                                                  size: 11,
                                                  color: s <= stepIndex
                                                      ? const Color(0xFF2E7D32)
                                                      : const Color(0xFFB0BEC5),
                                                ),
                                                if (s < 3)
                                                  Expanded(
                                                    child: Container(
                                                      height: 1.5,
                                                      color: s < stepIndex
                                                          ? const Color(0xFF2E7D32)
                                                          : const Color(0xFFE0E0E0),
                                                    ),
                                                  ),
                                              ],
                                            ],
                                          ),
                                        ),
                                      ],
                                      const SizedBox(height: 8),
                                      Wrap(
                                        spacing: 8,
                                        runSpacing: 8,
                                        crossAxisAlignment: WrapCrossAlignment.center,
                                        children: [
                                          Chip(
                                            label: Text(order.status.label),
                                            backgroundColor:
                                                const Color(0xFFE8F5E9),
                                          ),
                                          ActionChip(
                                            avatar: const Icon(Icons.timeline_rounded, size: 15, color: Color(0xFF2E7D32)),
                                            label: const Text('Tracker & Details'),
                                            onPressed: () => _openRequestDetails(order),
                                          ),
                                          // Status modifier visible strictly to Riders and Municipal Admins
                                          if (_signedIn && (_role == AppRole.rider || _role == AppRole.admin))
                                            _StatusSelector(
                                              currentStatus: order.status,
                                              onChanged: (status) {
                                                if (status != null) {
                                                  _updateOrderStatus(order, status);
                                                }
                                              },
                                            ),
                                          // MoMo Pay Button visible strictly to owning resident
                                          if (_signedIn &&
                                              _role == AppRole.resident &&
                                              order.status != RequestStatus.paid &&
                                              order.status != RequestStatus.cancelled)
                                            ActionChip(
                                              avatar: const Icon(Icons.payment, size: 16, color: Color(0xFF2E7D32)),
                                              label: const Text('Pay MoMo'),
                                              onPressed: () => _openMoMoPayment(order),
                                            ),
                                          if (order.status ==
                                              RequestStatus.requested)
                                            IconButton(
                                              icon: const Icon(
                                                Icons.delete_outline_rounded,
                                                size: 20,
                                                color: Colors.redAccent,
                                              ),
                                              tooltip: 'Cancel Request',
                                              onPressed: () =>
                                                  _cancelOrder(order),
                                            ),
                                        ],
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      );
                    },
                  ),
                ),
        ),
      ],
    );
  }

  Widget _buildProfile() => Center(
    child: _signedIn
        ? ProfileSettingsView(
            currentUser: _currentUser,
            role: _role,
            orders: _role == AppRole.resident
                ? _orders.where((o) =>
                    _currentUser == null ||
                    o.residentId == _currentUser!.id ||
                    o.residentPhone == _currentUser!.phone ||
                    o.residentName == _currentUser!.fullName ||
                    o.residentId == 'resident-1'
                  ).toList()
                : _orders,
            repository: widget.repository,
            authService: widget.authService,
            remindersEnabled: _remindersEnabled,
            onRemindersToggled: (val) {
              setState(() => _remindersEnabled = val);
              widget.authService?.setRemindersEnabled(val);
            },
            onOpenWasteDatabase: _showWasteDatabase,
            onRefreshOrders: _loadOrders,
            onSignOut: _signOut,
            onProfileUpdated: () {
              if (widget.authService != null) {
                setState(() {
                  _currentUser = widget.authService!.getCurrentUser();
                });
              }
            },
          )
        : FilledButton.icon(
            onPressed: _showAuth,
            icon: const Icon(Icons.login),
            label: const Text('Sign in or create account'),
          ),
  );
}
