import 'dart:async';

import 'package:flutter/material.dart';

import '../../app/config/app_config.dart';
import '../../core/pickup_request_repository.dart';
import '../../domain/entities/pickup_request.dart';
import '../../domain/enums/request_status.dart';
import '../../domain/enums/role.dart';
import '../../domain/enums/waste_type.dart';
import '../../domain/rules/status_machine.dart';
import '../auth/auth_sheet.dart';
import '../request/order_page.dart';

class EcoRouteSplashScreen extends StatefulWidget {
  const EcoRouteSplashScreen({required this.repository, super.key});

  final PickupRequestRepository repository;

  @override
  State<EcoRouteSplashScreen> createState() => _EcoRouteSplashScreenState();
}

class _EcoRouteSplashScreenState extends State<EcoRouteSplashScreen> {
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _timer = Timer(const Duration(milliseconds: 1500), () {
      if (mounted) {
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(
            builder: (_) => EcoRouteHomeScreen(repository: widget.repository),
          ),
        );
      }
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      backgroundColor: Color(0xFF2EAD65),
      body: Center(child: BrandLockup(splash: true)),
    );
  }
}

class EcoRouteHomeScreen extends StatefulWidget {
  const EcoRouteHomeScreen({required this.repository, super.key});

  final PickupRequestRepository repository;

  @override
  State<EcoRouteHomeScreen> createState() => _EcoRouteHomeScreenState();
}

class _EcoRouteHomeScreenState extends State<EcoRouteHomeScreen> {
  int _tab = 0;
  bool _signedIn = false;
  AppRole _role = AppRole.resident;
  bool _loadingOrders = true;
  final List<PickupRequest> _orders = [];

  @override
  void initState() {
    super.initState();
    _loadOrders();
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

  void _openOrder() {
    if (!_signedIn) {
      _showAuth();
      return;
    }
    Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => OrderPage(onSubmitted: _addOrder)),
    );
  }

  Future<void> _addOrder(PickupRequest request) async {
    await widget.repository.save(request);
    if (!mounted) return;
    setState(() => _orders.insert(0, request));
    Navigator.of(context).pop();
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Your collection order has been submitted.'),
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

  void _showAuth() {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      builder: (_) => AuthSheet(
        onAuthenticated: (role) => setState(() {
          _signedIn = true;
          _role = role;
        }),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const FittedBox(
          fit: BoxFit.scaleDown,
          child: BrandLockup(compact: true),
        ),
        actions: [
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
            _buildAnalytics(),
          ],
          const SizedBox(height: 18),
          _buildMapPanel(),
          if (_role == AppRole.resident) ...[
            const SizedBox(height: 16),
            _buildReportButton(),
            const SizedBox(height: 18),
          ],
          Row(
            children: [
              const Expanded(
                child: Text(
                  'Arua collection schedule',
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w800,
                    color: Color(0xFF183B20),
                  ),
                ),
              ),
              TextButton(
                onPressed: () => setState(() => _tab = 1),
                child: const Text('See all'),
              ),
            ],
          ),
          _reportTile(
            'North zone',
            AppConfig.collectionSchedule['north'] ?? 'Wednesdays',
            Icons.north_rounded,
            const Color(0xFFE7F3E8),
          ),
          _reportTile(
            'South zone',
            AppConfig.collectionSchedule['south'] ?? 'Thursdays',
            Icons.south_rounded,
            const Color(0xFFF2F7E8),
          ),
          _reportTile(
            'East zone',
            AppConfig.collectionSchedule['east'] ?? 'Fridays',
            Icons.east_rounded,
            const Color(0xFFEAF4FF),
          ),
          _reportTile(
            'West zone',
            AppConfig.collectionSchedule['west'] ?? 'Saturdays',
            Icons.west_rounded,
            const Color(0xFFFFF2D8),
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
              text: 'All caught up. Completed pickups will appear here for review.',
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
              text: 'Analytics will populate as collection requests are submitted.',
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
                    '${_orders.length} total requests · ${_countStatus(RequestStatus.paid)} verified and paid',
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
        icon: Icons.add_road_rounded,
        title: 'Schedule pickup',
        subtitle: 'Create a new collection request',
        accent: const Color(0xFF2E8B57),
        onTap: _openOrder,
      ),
      _QuickActionCard(
        icon: Icons.bar_chart_rounded,
        title: 'Service overview',
        subtitle: 'Review local request activity',
        accent: const Color(0xFF3A5A9F),
        onTap: () => setState(() => _tab = 2),
      ),
      _QuickActionCard(
        icon: Icons.manage_accounts_outlined,
        title: 'Account & role',
        subtitle: 'Manage your demo session',
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
                  const _WelcomeIcon(),
                  const SizedBox(width: 12),
                  Expanded(child: greeting),
                ],
              ),
      );
    },
  );

  Widget _buildMapPanel() => Container(
    height: 294,
    clipBehavior: Clip.antiAlias,
    decoration: BoxDecoration(
      color: const Color(0xFFE7F0E6),
      borderRadius: BorderRadius.circular(22),
      border: Border.all(color: const Color(0xFFD2E1D1)),
    ),
    child: Stack(
      children: [
        CustomPaint(size: Size.infinite, painter: _MapPainter()),
        const Positioned(
          left: 18,
          top: 18,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Arua service map',
                style: TextStyle(
                  fontWeight: FontWeight.w800,
                  color: Color(0xFF21452A),
                ),
              ),
              SizedBox(height: 3),
              Text(
                'Illustrative zones · demo locations',
                style: TextStyle(fontSize: 11, color: Color(0xFF647568)),
              ),
            ],
          ),
        ),
        Positioned(
          left: 16,
          top: 68,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.9),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Text(
              '${_orders.length} ${_orders.length == 1 ? 'request' : 'requests'} on the local board',
              style: const TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w700,
                color: Color(0xFF45604A),
              ),
            ),
          ),
        ),
        Positioned(
          right: 14,
          top: 14,
          child: _mapControl(Icons.layers_outlined),
        ),
        Positioned(
          right: 14,
          bottom: 62,
          child: Column(
            children: [
              _mapControl(Icons.add),
              const SizedBox(height: 8),
              _mapControl(Icons.remove),
            ],
          ),
        ),
        const Positioned(left: 80, top: 92, child: _MapPin()),
        const Positioned(left: 188, top: 150, child: _MapPin()),
        const Positioned(right: 72, top: 102, child: _MapPin()),
        const Positioned(left: 132, bottom: 54, child: _MapPin()),
        Positioned(
          left: 16,
          right: 16,
          bottom: 14,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(14),
              boxShadow: const [
                BoxShadow(color: Color(0x18000000), blurRadius: 10),
              ],
            ),
            child: Row(
              children: [
                const Icon(
                  Icons.location_on_outlined,
                  color: Color(0xFF2E7D32),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: FittedBox(
                    fit: BoxFit.scaleDown,
                    alignment: Alignment.centerLeft,
                    child: const Text(
                      'Arua service radius: 12 km',
                      style: TextStyle(fontWeight: FontWeight.w700),
                      maxLines: 1,
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                const Icon(Icons.chevron_right, color: Color(0xFF718273)),
              ],
            ),
          ),
        ),
      ],
    ),
  );

  Widget _mapControl(IconData icon) => Container(
    width: 38,
    height: 38,
    decoration: BoxDecoration(
      color: Colors.white,
      borderRadius: BorderRadius.circular(12),
      boxShadow: const [BoxShadow(color: Color(0x18000000), blurRadius: 8)],
    ),
    child: Icon(icon, size: 20, color: const Color(0xFF45604A)),
  );

  Widget _buildReportButton() => SizedBox(
    width: double.infinity,
    height: 54,
    child: FilledButton.icon(
      onPressed: _openOrder,
      icon: const Icon(Icons.add_a_photo_outlined),
      label: const _ResponsiveButtonLabel('REPORT AN ISSUE'),
      style: FilledButton.styleFrom(
        backgroundColor: const Color(0xFF2E8B57),
        foregroundColor: Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      ),
    ),
  );

  Widget _reportTile(
    String title,
    String time,
    IconData icon,
    Color background,
  ) => Container(
    margin: const EdgeInsets.only(bottom: 10),
    padding: const EdgeInsets.all(13),
    decoration: BoxDecoration(
      color: Colors.white,
      borderRadius: BorderRadius.circular(16),
      border: Border.all(color: const Color(0xFFE2EAE1)),
    ),
    child: Row(
      children: [
        Container(
          width: 42,
          height: 42,
          decoration: BoxDecoration(
            color: background,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Icon(icon, color: const Color(0xFF3D7850)),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: const TextStyle(fontWeight: FontWeight.w700),
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 3),
              Text(
                time,
                style: const TextStyle(fontSize: 12, color: Color(0xFF78877B)),
              ),
            ],
          ),
        ),
        const SizedBox(width: 8),
        const Icon(Icons.chevron_right, color: Color(0xFF9AA79C)),
      ],
    ),
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

    return ListView(
      padding: const EdgeInsets.all(20),
      children: [
        for (final order in _orders)
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
                        Text(
                          order.wasteType.label,
                          style: const TextStyle(
                            fontWeight: FontWeight.w700,
                            fontSize: 16,
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
                          children: [
                            Chip(
                              label: Text(order.status.label),
                              backgroundColor: const Color(0xFFE8F5E9),
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
    );
  }

  Widget _buildProfile() => Center(
    child: _signedIn
        ? Padding(
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
                const SizedBox(height: 18),
                FilledButton.icon(
                  onPressed: _showAuth,
                  icon: const Icon(Icons.swap_horiz_rounded),
                  label: const Text('Switch role'),
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

class _StatusSelector extends StatelessWidget {
  const _StatusSelector({required this.currentStatus, required this.onChanged});

  final RequestStatus currentStatus;
  final ValueChanged<RequestStatus?> onChanged;

  @override
  Widget build(BuildContext context) {
    final statuses = <RequestStatus>{
      currentStatus,
      ...RequestStatus.values.where(
        (status) => isValidTransition(currentStatus, status),
      ),
    }.toList();

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8),
      decoration: BoxDecoration(
        color: const Color(0xFFF1F7F2),
        borderRadius: BorderRadius.circular(999),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<RequestStatus>(
          value: currentStatus,
          isDense: true,
          items: statuses
              .map(
                (status) =>
                    DropdownMenuItem(value: status, child: Text(status.label)),
              )
              .toList(),
          onChanged: onChanged,
        ),
      ),
    );
  }
}

class _DashboardPanel extends StatelessWidget {
  const _DashboardPanel({
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.child,
  });

  final String title;
  final String subtitle;
  final IconData icon;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFFE2EAE1)),
        boxShadow: const [
          BoxShadow(
            color: Color(0x08000000),
            blurRadius: 12,
            offset: Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: const Color(0xFFEAF4EC),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(icon, color: const Color(0xFF2E8B57)),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: const TextStyle(
                        color: Color(0xFF183B20),
                        fontWeight: FontWeight.w800,
                        fontSize: 16,
                      ),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      subtitle,
                      style: const TextStyle(
                        color: Color(0xFF71877D),
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          child,
        ],
      ),
    );
  }
}

class _EmptyPanelMessage extends StatelessWidget {
  const _EmptyPanelMessage({required this.icon, required this.text});

  final IconData icon;
  final String text;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, color: const Color(0xFF78917C), size: 20),
        const SizedBox(width: 10),
        Expanded(
          child: Text(
            text,
            style: const TextStyle(color: Color(0xFF647568), fontSize: 13),
          ),
        ),
      ],
    );
  }
}

class _RouteStop extends StatelessWidget {
  const _RouteStop({
    required this.index,
    required this.request,
    required this.onAdvance,
  });

  final int index;
  final PickupRequest request;
  final VoidCallback onAdvance;

  @override
  Widget build(BuildContext context) {
    final isRequested = request.status == RequestStatus.requested;
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: 32,
          height: 32,
          alignment: Alignment.center,
          decoration: const BoxDecoration(
            color: Color(0xFFEAF4EC),
            shape: BoxShape.circle,
          ),
          child: Text(
            '$index',
            style: const TextStyle(
              color: Color(0xFF2E7D4F),
              fontWeight: FontWeight.w800,
            ),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                request.wasteType.label,
                style: const TextStyle(fontWeight: FontWeight.w800),
              ),
              const SizedBox(height: 3),
              Text(
                request.description,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(color: Color(0xFF71877D), fontSize: 12),
              ),
              const SizedBox(height: 8),
              Align(
                alignment: Alignment.centerLeft,
                child: OutlinedButton.icon(
                  onPressed: onAdvance,
                  icon: Icon(
                    isRequested
                        ? Icons.check_circle_outline_rounded
                        : Icons.fact_check_outlined,
                    size: 17,
                  ),
                  label: Text(
                    isRequested ? 'Mark collected' : 'Send for verification',
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _ApprovalItem extends StatelessWidget {
  const _ApprovalItem({
    required this.request,
    required this.onApprove,
    required this.onReturn,
  });

  final PickupRequest request;
  final VoidCallback onApprove;
  final VoidCallback onReturn;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          request.wasteType.label,
          style: const TextStyle(fontWeight: FontWeight.w800),
        ),
        const SizedBox(height: 4),
        Text(
          request.description,
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
          style: const TextStyle(color: Color(0xFF71877D), fontSize: 12),
        ),
        const SizedBox(height: 10),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            FilledButton.icon(
              onPressed: onApprove,
              icon: const Icon(Icons.verified_outlined, size: 17),
              label: const Text('Approve payment'),
            ),
            OutlinedButton.icon(
              onPressed: onReturn,
              icon: const Icon(Icons.undo_rounded, size: 17),
              label: const Text('Return to rider'),
            ),
          ],
        ),
      ],
    );
  }
}

class _AnalyticsRow extends StatelessWidget {
  const _AnalyticsRow({
    required this.status,
    required this.count,
    required this.total,
  });

  final RequestStatus status;
  final int count;
  final int total;

  @override
  Widget build(BuildContext context) {
    final proportion = count / total;
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        children: [
          SizedBox(
            width: 114,
            child: Text(
              status.label,
              style: const TextStyle(fontSize: 12, color: Color(0xFF647568)),
            ),
          ),
          Expanded(
            child: ClipRRect(
              borderRadius: BorderRadius.circular(99),
              child: SizedBox(
                height: 8,
                child: Stack(
                  children: [
                    const ColoredBox(
                      color: Color(0xFFEAF0E9),
                      child: SizedBox.expand(),
                    ),
                    FractionallySizedBox(
                      widthFactor: proportion,
                      child: const ColoredBox(color: Color(0xFF2E8B57)),
                    ),
                  ],
                ),
              ),
            ),
          ),
          const SizedBox(width: 10),
          SizedBox(
            width: 22,
            child: Text(
              '$count',
              textAlign: TextAlign.end,
              style: const TextStyle(fontWeight: FontWeight.w800),
            ),
          ),
        ],
      ),
    );
  }
}

class _ProfileMetric extends StatelessWidget {
  const _ProfileMetric({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label),
        Text(value, style: const TextStyle(fontWeight: FontWeight.w700)),
      ],
    );
  }
}

class _MetricCard extends StatelessWidget {
  const _MetricCard({
    required this.label,
    required this.value,
    required this.hint,
  });

  final String label;
  final String value;
  final String hint;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE3E7E2)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: const TextStyle(color: Color(0xFF6F8477), fontSize: 12),
          ),
          const SizedBox(height: 8),
          Text(
            value,
            style: const TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.w800,
              color: Color(0xFF183B20),
            ),
          ),
          const SizedBox(height: 2),
          Text(
            hint,
            style: const TextStyle(fontSize: 11, color: Color(0xFF839389)),
          ),
        ],
      ),
    );
  }
}

class _QuickActionCard extends StatelessWidget {
  const _QuickActionCard({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.accent,
    required this.onTap,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final Color accent;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: const Color(0xFFE3E6E1)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: accent.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(icon, color: accent),
            ),
            const SizedBox(height: 10),
            Text(
              title,
              style: const TextStyle(
                fontWeight: FontWeight.w800,
                color: Color(0xFF183B20),
              ),
            ),
            const SizedBox(height: 4),
            Text(
              subtitle,
              style: const TextStyle(fontSize: 12, color: Color(0xFF71877D)),
            ),
          ],
        ),
      ),
    );
  }
}

class BrandLockup extends StatelessWidget {
  const BrandLockup({this.compact = false, this.splash = false, super.key});

  final bool compact;
  final bool splash;

  @override
  Widget build(BuildContext context) {
    if (splash) {
      return const Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.recycling_rounded, size: 126, color: Colors.white),
          SizedBox(height: 14),
          Text(
            'EcoRoute',
            style: TextStyle(
              color: Colors.white,
              fontSize: 34,
              fontWeight: FontWeight.w800,
            ),
          ),
        ],
      );
    }

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(
          Icons.recycling_rounded,
          size: compact ? 44 : 120,
          color: const Color(0xFF123B1A),
        ),
        const SizedBox(width: 10),
        Text(
          'EcoRoute',
          style: TextStyle(
            fontSize: compact ? 20 : 40,
            fontWeight: FontWeight.w800,
            color: const Color(0xFF123B1A),
          ),
        ),
      ],
    );
  }
}

class _ResponsiveButtonLabel extends StatelessWidget {
  const _ResponsiveButtonLabel(this.text);

  final String text;

  @override
  Widget build(BuildContext context) {
    return FittedBox(
      fit: BoxFit.scaleDown,
      child: Text(text, maxLines: 1, overflow: TextOverflow.ellipsis),
    );
  }
}

class _WelcomeIcon extends StatelessWidget {
  const _WelcomeIcon();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 48,
      height: 48,
      decoration: BoxDecoration(
        color: const Color(0xFFDCEFE0),
        borderRadius: BorderRadius.circular(16),
      ),
      child: const Icon(Icons.waving_hand_rounded, color: Color(0xFF2E7D32)),
    );
  }
}

class _MapPin extends StatelessWidget {
  const _MapPin();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 34,
      height: 34,
      decoration: BoxDecoration(
        color: const Color(0xFF3D8B5A),
        shape: BoxShape.circle,
        border: Border.all(color: Colors.white, width: 3),
        boxShadow: const [BoxShadow(color: Color(0x30000000), blurRadius: 6)],
      ),
      child: const Icon(Icons.recycling_rounded, size: 18, color: Colors.white),
    );
  }
}

class _MapPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final road = Paint()
      ..color = const Color(0xFFD2E1D0)
      ..strokeWidth = 18
      ..style = PaintingStyle.stroke;
    final smallRoad = Paint()
      ..color = const Color(0xFFDCE8DA)
      ..strokeWidth = 9
      ..style = PaintingStyle.stroke;
    final river = Paint()
      ..color = const Color(0xFFB9DDE2)
      ..strokeWidth = 24
      ..style = PaintingStyle.stroke;
    final mainRoad = Path()
      ..moveTo(-20, size.height * .72)
      ..quadraticBezierTo(
        size.width * .35,
        size.height * .52,
        size.width + 20,
        size.height * .62,
      );
    final crossRoad = Path()
      ..moveTo(size.width * .22, -10)
      ..quadraticBezierTo(
        size.width * .5,
        size.height * .42,
        size.width * .72,
        size.height + 10,
      );
    final sideRoad = Path()
      ..moveTo(-10, size.height * .22)
      ..quadraticBezierTo(
        size.width * .45,
        size.height * .1,
        size.width + 10,
        size.height * .28,
      );
    canvas.drawPath(mainRoad, road);
    canvas.drawPath(crossRoad, road);
    canvas.drawPath(sideRoad, smallRoad);
    final waterPath = Path()
      ..moveTo(size.width * .84, -10)
      ..quadraticBezierTo(
        size.width * .65,
        size.height * .32,
        size.width * .92,
        size.height + 10,
      );
    canvas.drawPath(waterPath, river);
    for (var index = 0; index < 7; index++) {
      final x = 28.0 + (index * 61) % size.width;
      final y = 70.0 + (index * 47) % (size.height - 95);
      canvas.drawCircle(
        Offset(x, y),
        2.5,
        Paint()..color = const Color(0xFFB8CFB4),
      );
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
