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
  static const _reminderPolicy = ReminderPolicy();

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
          SnackBar(
            backgroundColor: const Color(0xFF2E8B57),
            content: Text('Rider invite sent successfully to ! Password: #ecorute26'),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to invite rider: ')),
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
          SnackBar(content: Text('Rider  removed.')),
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
      residentName: _currentUser?.fullName ?? 'Amina Dranzoa',
      residentPhone: request.residentPhone.isNotEmpty
          ? request.residentPhone
          : (_currentUser?.phone ?? '+256394880352'),
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
      SnackBar(content: Text('Request updated to ${status.label}.')),
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
              IconButton(
                icon: const Icon(Icons.dataset_outlined),
                tooltip: 'Waste Database & Rates',
                onPressed: _showWasteDatabase,
              ),
              // Language Selector Menu
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

          // Interactive Arua Map View
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
                      ? '${report.temperatureC.toStringAsFixed(1)}┬░C ΓÇó ${report.conditionSummary}'
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
                  'Riders are strictly invited via email by municipal admins. Default password is #ecorute26.',
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
                              '${riders[i]['email']} ΓÇó ${riders[i]['phone'] ?? ''}',
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
                              '${residents[i].email} ΓÇó ${residents[i].phone}',
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
                const SizedBox(height: 12),
                Align(
                  alignment: Alignment.centerLeft,
                  child: Text(
                    '${_orders.length} total requests \u00B7 ${_countStatus(RequestStatus.paid)} verified and paid',
                    style: const TextStyle(
                      color: Color(0xFF647568),
                      fontSize: 12,
                    ),
                  ),
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
        subtitle: 'Manage account & login',
        accent: const Color(0xFFF0A62A),
        onTap: _showAuth,
      ),
    ];

    return Row(
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

    if (_orders.isEmpty) {
      return const Center(
        child: Padding(
          padding: EdgeInsets.all(28),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                Icons.receipt_long_outlined,
                size: 56,
                color: Color(0xFF7C9580),
              ),
              SizedBox(height: 12),
              Text(
                'No collection orders yet',
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.w800),
              ),
              SizedBox(height: 6),
              Text(
                'Your submitted orders will appear here.',
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      );
    }

    final filteredOrders = _orders.where((order) {
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
                label: const Text('All'),
                selected: _statusFilter == null,
                onSelected: (_) => setState(() => _statusFilter = null),
              ),
              const SizedBox(width: 8),
              for (final status in RequestStatus.values) ...[
                FilterChip(
                  label: Text(status.label),
                  selected: _statusFilter == status,
                  onSelected: (selected) => setState(
                    () => _statusFilter = selected ? status : null,
                  ),
                ),
                const SizedBox(width: 8),
              ],
            ],
          ),
        ),
        Expanded(
          child: filteredOrders.isEmpty
              ? const Center(
                  child: Text(
                    'No requests matching the selected filter.',
                    style: TextStyle(color: Color(0xFF71877D)),
                  ),
                )
              : ListView(
                  padding: const EdgeInsets.fromLTRB(16, 4, 16, 20),
                  children: [
                    for (final order in filteredOrders)
                      Card(
                        margin: const EdgeInsets.only(bottom: 14),
                        child: Padding(
                          padding: const EdgeInsets.all(12),
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Padding(
                                padding: EdgeInsets.only(top: 8),
                                child: Icon(
                                  Icons.pending_actions,
                                  color: Color(0xFF2E7D32),
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Row(
                                      children: [
                                        Text(
                                          order.wasteType.label,
                                          style: const TextStyle(
                                            fontWeight: FontWeight.w700,
                                            fontSize: 16,
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
                                      '${order.sackCount} sack(s) ΓÇó Instant Pickup ΓÇó ${order.address}',
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
                                    ),
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
                                        if (_signedIn)
                                          _StatusSelector(
                                            currentStatus: order.status,
                                            onChanged: (status) {
                                              if (status != null) {
                                                _updateOrderStatus(order, status);
                                              }
                                            },
                                          ),
                                        // MoMo Pay Button for unpaid orders
                                        if (order.status != RequestStatus.paid &&
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
                                                _deleteOrder(order),
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
                  ],
                ),
        ),
      ],
    );
  }

  Widget _buildProfile() => Center(
    child: _signedIn
        ? SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 90,
                  height: 90,
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [Color(0xFF2E8B57), Color(0xFF135D39)],
                    ),
                    borderRadius: BorderRadius.circular(28),
                  ),
                  child: const Icon(
                    Icons.person_pin_circle_rounded,
                    size: 52,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: 16),
                Text(
                  'Signed in as ${_role.label}',
                  style: const TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                if (_currentUser != null) ...[
                  const SizedBox(height: 4),
                  Text(
                    _currentUser!.fullName,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  Text(
                    '${_currentUser!.email} ΓÇó ${_currentUser!.phone}',
                    style: const TextStyle(fontSize: 12, color: Color(0xFF71877D)),
                  ),
                ],
                const SizedBox(height: 8),
                Text(
                  _role == AppRole.rider
                      ? 'Dispatch and route checks are active.'
                      : _role == AppRole.admin
                      ? 'Admin review and approval controls are active.'
                      : 'Resident requests and service updates are active.',
                  textAlign: TextAlign.center,
                  style: const TextStyle(color: Color(0xFF5E6F60)),
                ),
                const SizedBox(height: 18),
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      children: [
                        _ProfileMetric(
                          label: 'Open requests',
                          value:
                              '${_orders.where((order) => order.status == RequestStatus.requested).length}',
                        ),
                        const Divider(),
                        _ProfileMetric(
                          label: 'Collected',
                          value:
                              '${_orders.where((order) => order.status == RequestStatus.collected).length}',
                        ),
                        const Divider(),
                        _ProfileMetric(
                          label: 'Paid',
                          value:
                              '${_orders.where((order) => order.status == RequestStatus.paid).length}',
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 16),

                // Reminder Policy toggle
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 14,
                    vertical: 10,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: const Color(0xFFE2EAE1)),
                  ),
                  child: Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'Pickup schedule reminders',
                              style: TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              _reminderPolicy.shouldSendReminder(
                                successfulRequests:
                                    _countStatus(RequestStatus.paid),
                                remindersEnabled: _remindersEnabled,
                              )
                                  ? 'Active: Free onboarding reminder policy enabled.'
                                  : 'Reminders inactive or onboarding threshold met.',
                              style: const TextStyle(fontSize: 11),
                            ),
                          ],
                        ),
                      ),
                      Switch(
                        value: _remindersEnabled,
                        onChanged: (val) =>
                            setState(() => _remindersEnabled = val),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 14),
                ListTile(
                  tileColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                    side: const BorderSide(color: Color(0xFFE2EAE1)),
                  ),
                  leading: const Icon(Icons.dataset_outlined, color: Color(0xFF2E7D32)),
                  title: const Text(
                    'Municipal Solid Waste & Recycling Data',
                    style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700),
                  ),
                  subtitle: const Text(
                    'World Bank benchmarks, Lugbara terms & scrap rates',
                    style: TextStyle(fontSize: 11),
                  ),
                  trailing: const Icon(Icons.chevron_right_rounded),
                  onTap: _showWasteDatabase,
                ),
                const SizedBox(height: 10),
                ListTile(
                  tileColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                    side: const BorderSide(color: Color(0xFFE2EAE1)),
                  ),
                  leading: const Icon(Icons.refresh_rounded, color: Color(0xFF2E7D32)),
                  title: const Text(
                    'Reset / Re-seed Demo Municipal Records',
                    style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700),
                  ),
                  subtitle: const Text(
                    'Populates demonstration instant collection requests across Arua',
                    style: TextStyle(fontSize: 11),
                  ),
                  trailing: const Icon(Icons.arrow_forward_rounded),
                  onTap: () async {
                    await widget.repository.seedDemoData(force: true);
                    await _loadOrders();
                    if (!mounted) return;
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Demonstration instant collection orders restored.'),
                        backgroundColor: Color(0xFF2E7D32),
                      ),
                    );
                  },
                ),
                const SizedBox(height: 18),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    FilledButton.icon(
                      onPressed: _showAuth,
                      icon: const Icon(Icons.swap_horiz_rounded),
                      label: const Text('Switch role'),
                    ),
                    const SizedBox(width: 12),
                    OutlinedButton.icon(
                      onPressed: _signOut,
                      icon: const Icon(Icons.logout_rounded),
                      label: const Text('Sign out'),
                    ),
                  ],
                ),
              ],
            ),
          )
        : FilledButton.icon(
            onPressed: _showAuth,
            icon: const Icon(Icons.login),
            label: const Text('Sign in or create account'),
          ),
  );
}
