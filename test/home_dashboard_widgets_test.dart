import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../core/pickup_request_repository.dart';
import '../../core/services/auth_service.dart';
import '../../core/services/language_service.dart';
import '../../core/services/location_service.dart';
import '../../core/services/waste_api_service.dart';
import '../../core/utils/formatters.dart';
import '../../domain/entities/app_user.dart';
import '../../domain/entities/pickup_request.dart';
import '../../domain/enums/request_status.dart';
import '../../domain/enums/role.dart';
import '../../domain/enums/waste_type.dart';
import '../../domain/rules/reminder_policy.dart';
import '../../domain/rules/status_machine.dart';
import '../admin/widgets/analytics_breakdown.dart';
import '../admin/widgets/approval_item_tile.dart';
import '../auth/auth_sheet.dart';
import '../database/waste_database_sheet.dart';
import '../payment/momo_payment_dialog.dart';
import '../request/order_page.dart';
import '../rider/widgets/route_stop_tile.dart';
import 'widgets/brand_lockup.dart';
import 'widgets/interactive_map_panel.dart';
import 'widgets/metric_cards.dart';
import 'widgets/status_selector.dart';

export 'widgets/brand_lockup.dart';
export 'widgets/interactive_map_panel.dart';
export 'widgets/metric_cards.dart';
export 'widgets/status_selector.dart';

// Backward compatibility aliases
typedef _RouteStop = RouteStopTile;
typedef _ApprovalItem = ApprovalItemTile;
typedef _AnalyticsRow = AnalyticsRow;
typedef _MetricCard = MetricCard;
typedef _QuickActionCard = QuickActionCard;
typedef _ProfileMetric = ProfileMetric;
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

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    );

    _scaleAnimation = TweenSequence<double>([
      TweenSequenceItem(
        tween: Tween<double>(begin: 0.9, end: 1.05)
            .chain(CurveTween(curve: Curves.easeOut)),
        weight: 60,
      ),
      TweenSequenceItem(
        tween: Tween<double>(begin: 1.05, end: 1.6)
            .chain(CurveTween(curve: Curves.easeInCubic)),
        weight: 40,
      ),
    ]).animate(_controller);

    _opacityAnimation = TweenSequence<double>([
      TweenSequenceItem(tween: ConstantTween<double>(1.0), weight: 75),
      TweenSequenceItem(
        tween: Tween<double>(begin: 1.0, end: 0.0)
            .chain(CurveTween(curve: Curves.easeOut)),
        weight: 25,
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
            transitionDuration: const Duration(milliseconds: 300),
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
        statusBarColor: Color(0xFF2EAD65),
        statusBarIconBrightness: Brightness.light,
        statusBarBrightness: Brightness.dark,
        systemNavigationBarColor: Color(0xFF2EAD65),
        systemNavigationBarIconBrightness: Brightness.light,
        systemNavigationBarDividerColor: Colors.transparent,
      ),
      child: Scaffold(
        backgroundColor: const Color(0xFF2EAD65),
        body: Center(
          child: AnimatedBuilder(
            animation: _controller,
            builder: (context, child) {
              return FadeTransition(
                opacity: _opacityAnimation,
                child: Transform.scale(
                  scale: _scaleAnimation.value,
                  child: child,
                ),
              );
            },
            child: const BrandLockup(splash: true),
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
  AppUser? _currentUser;
  bool _loadingOrders = true;
  final List<PickupRequest> _orders = [];

  late final WasteApiService _apiService;
  AruaWeatherReport? _weatherReport;
  bool _loadingWeather = false;

  UserLocationResult? _lastGpsResult;
  bool _locatingGps = false;

  RequestStatus? _statusFilter;
  String _searchQuery = '';

  bool _remindersEnabled = true;
  static const _reminderPolicy = ReminderPolicy();

  final LanguageService _langService = LanguageService.instance;

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
  }

  void _loadUserSession() {
    if (widget.authService != null) {
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
      if (widget.authService != null) {
        await widget.authService!.inviteRider(
          email: email,
          fullName: name,
          phone: phone,
        );
      }
      _riderEmailController.clear();
      _riderNameController.clear();
      _riderPhoneController.clear();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            backgroundColor: Color(0xFF2E8B57),
            content: Text('Rider invite sent successfully.'),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Failed to invite rider.')),
        );
      }
    } finally {
      if (mounted) setState(() => _invitingRider = false);
    }
  }

  Future<void> _removeRider(String email) async {
    if (widget.authService != null) {
      await widget.authService!.removeRider(email);
      if (mounted) {
        setState(() {});
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Rider removed.')),
        );
      }
    }
  }

  void _openOrder() {
    if (!_signedIn) {
      _showAuth();
      return;
    }
    Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => OrderPage(onSubmitted: _addOrder)),
    );
  }

  void _openAutoScanOrder() {
    if (!_signedIn) {
      _showAuth();
      return;
    }
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => OrderPage(
          onSubmitted: _addOrder,
          autoTriggerCamera: true,
        ),
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
    final requestWithUser = request.copyWith(
      residentId: _currentUser?.id ?? 'resident-1',
      residentName: _currentUser?.fullName ?? 'EcoRoute Resident',
      residentPhone: request.residentPhone.isNotEmpty
          ? request.residentPhone
          : (_currentUser?.phone ?? ''),
      address: (request.address.isNotEmpty && request.address != 'Arua Municipality')
          ? request.address
          : (_currentUser?.address ?? request.address),
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

  Future<void> _deleteOrder(PickupRequest request) async {
    await widget.repository.delete(request.id);
    if (!mounted) return;
    setState(() => _orders.removeWhere((o) => o.id == request.id));
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Collection request cancelled.')),
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
      SnackBar(content: Text('Request updated to ${status.label}.'),
      ),
    );
  }

  void _openMoMoPayment(PickupRequest request) {
    final phone = request.residentPhone.isNotEmpty ? request.residentPhone : '';
    showDialog<void>(
      context: context,
      builder: (_) => MoMoPaymentDialog(
        request: request,
        initialPhone: phone,
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
                IconButton(
                  icon: const Icon(Icons.dataset_outlined),
                  tooltip: 'Waste Database & Rates',
                  onPressed: _showWasteDatabase,
                ),
                PopupMenuButton<AppLanguage>(
                  icon: const Icon(Icons.language_rounded),
                  tooltip: 'Select Language',
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
                  onPressed: _showAuth,
                  icon: const Icon(Icons.notifications_none_rounded),
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
              onDestinationSelected: (value) => setState(() => _tab = value),
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

    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(16, 4, 16, 28),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildWelcome(),
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
            _buildApprovalQueue(),
            const SizedBox(height: 18),
            _buildRiderManagement(),
            const SizedBox(height: 18),
            _buildResidentDirectory(),
            const SizedBox(height: 18),
            _buildAnalytics(),
          ],
          const SizedBox(height: 18),
          InteractiveAruaMapPanel(
            requestsCount: _orders.length,
            locationResult: _lastGpsResult,
            isLocating: _locatingGps,
            onLocateGps: _checkGpsLocation,
          ),
          if (_role == AppRole.resident) ...[
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
                        isOnline ? 'REST API Live' : 'Cached',
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
                      : 'Connecting to Arua meteorological service...',
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
                const Text(
                  'Invite New Collection Rider',
                  style: TextStyle(
                    fontWeight: FontWeight.w700,
                    fontSize: 13,
                    color: Color(0xFF1B5E3B),
                  ),
                ),
                const SizedBox(height: 4),
                const Text(
                  'Invite riders via Firebase Auth. Passwords are managed by the municipality and never stored in app code.',
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
                    labelText: 'Rider phone',
                    hintText: 'e.g. +256 700 000 001',
                    prefixIcon: const Icon(Icons.phone_outlined, size: 20),
                    isDense: true,
                    contentPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                  ),
                ),
                const SizedBox(height: 10),
                SizedBox(
                  width: double.infinity,
                  child: FilledButton.icon(
                    onPressed: _invitingRider ? null : _inviteRider,
                    icon: _invitingRider
                        ? const SizedBox(
                            width: 16,
                            height: 16,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : const Icon(Icons.person_add_alt_1_rounded),
                    label: Text(_invitingRider ? 'Inviting...' : 'Invite rider'),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildWelcome() => const SizedBox.shrink();

  Widget _buildQuickActions() => const SizedBox.shrink();

  Widget _buildOrders() => const SizedBox.shrink();

  Widget _buildProfile() => const SizedBox.shrink();

  Widget _buildReportButton() => const SizedBox.shrink();

  Widget _buildAnalytics() => const SizedBox.shrink();

  Widget _buildResidentDirectory() => const SizedBox.shrink();
}
