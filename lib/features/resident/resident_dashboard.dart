import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:latlong2/latlong.dart';
import 'package:qr_flutter/qr_flutter.dart';

import '../../core/pickup_request_repository.dart';
import '../../core/services/auth_service.dart';
import '../../core/services/osrm_routing_service.dart';
import '../../core/services/router_service.dart';
import '../../core/services/waste_api_service.dart';
import '../../core/theme/eco_palette.dart';
import '../../domain/entities/pickup_request.dart';
import '../../domain/enums/request_status.dart';
import '../auth/splash_screen.dart';
import '../common/widgets/eco_carto_map.dart';
import '../request/order_page.dart';
import 'support_screen.dart';

/// 03_RESIDENT_HOME & 04_RESIDENT_TRACKING: Resident Dashboard with live CartoDB map
class ResidentDashboard extends StatefulWidget {
  const ResidentDashboard({
    super.key,
    required this.repository,
    this.authService,
    this.wasteApiService,
  });

  final PickupRequestRepository repository;
  final AuthService? authService;
  final WasteApiService? wasteApiService;

  @override
  State<ResidentDashboard> createState() => _ResidentDashboardState();
}

class _ResidentDashboardState extends State<ResidentDashboard> {
  int _currentTab = 0;
  List<PickupRequest> _orders = [];
  AruaWeatherReport? _weather;
  late final WasteApiService _wasteApiService;

  // Arua coordinates for live CartoDB tracking preview
  static const LatLng _aruaCenter = LatLng(3.0303, 30.9073);

  @override
  void initState() {
    super.initState();
    _wasteApiService = widget.wasteApiService ?? WasteApiService();
    _loadOrders();
    _loadWeather();
  }

  Future<void> _loadWeather() async {
    try {
      final report = await _wasteApiService.fetchAruaCollectionWeather();
      if (mounted) setState(() => _weather = report);
    } catch (_) {}
  }

  Future<void> _loadOrders() async {
    final list = await widget.repository.loadAll();
    if (!mounted) return;
    setState(() {
      _orders = list;
    });
  }

  void _openOrderBooking() {
    HapticFeedback.mediumImpact();
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => OrderPage(
          onSubmitted: (request) async {
            await widget.repository.save(request);
            if (mounted) {
              Navigator.of(context).pop();
              _loadOrders();
            }
          },
        ),
      ),
    );
  }

  void _showQrHandshakeModal(PickupRequest activeOrder) {
    HapticFeedback.lightImpact();
    final pinCode = (activeOrder.id.hashCode.abs() % 9000 + 1000).toString();

    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => Padding(
        padding: const EdgeInsets.fromLTRB(24, 20, 24, 32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.grey[300],
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: 18),
            const Text(
              'Pickup Handshake Code',
              style: TextStyle(
                fontFamily: 'Satoshi',
                fontSize: 20,
                fontWeight: FontWeight.w800,
                color: EcoPalette.primaryDark,
              ),
            ),
            const SizedBox(height: 6),
            const Text(
              'Show this QR code or 4-digit PIN to the tricycle rider upon arrival',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontFamily: 'Satoshi',
                fontSize: 13,
                color: Color(0xFF6B8073),
              ),
            ),
            const SizedBox(height: 20),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: EcoPalette.surface,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: EcoPalette.cardBorder),
              ),
              child: QrImageView(
                data: 'ECOROUTE-PICKUP-${activeOrder.id}-$pinCode',
                version: QrVersions.auto,
                size: 180.0,
                eyeStyle: const QrEyeStyle(
                  eyeShape: QrEyeShape.square,
                  color: EcoPalette.primaryDark,
                ),
                dataModuleStyle: const QrDataModuleStyle(
                  dataModuleShape: QrDataModuleShape.square,
                  color: EcoPalette.primaryDark,
                ),
              ),
            ),
            const SizedBox(height: 18),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
              decoration: BoxDecoration(
                color: EcoPalette.chipBackground,
                borderRadius: BorderRadius.circular(10),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Text(
                    'Handshake PIN: ',
                    style: TextStyle(
                      fontFamily: 'Satoshi',
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: EcoPalette.secondaryDark,
                    ),
                  ),
                  Text(
                    pinCode,
                    style: const TextStyle(
                      fontFamily: 'Satoshi',
                      fontSize: 18,
                      fontWeight: FontWeight.w900,
                      color: EcoPalette.accentTerracotta,
                      letterSpacing: 2.0,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),
            SizedBox(
              width: double.infinity,
              height: 48,
              child: FilledButton(
                onPressed: () => Navigator.of(ctx).pop(),
                style: FilledButton.styleFrom(backgroundColor: EcoPalette.buttonDark),
                child: const Text('Close'),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showAccountMenu() {
    showModalBottomSheet<void>(
      context: context,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => Padding(
        padding: const EdgeInsets.fromLTRB(20, 16, 20, 28),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Center(
              child: Container(
                width: 36,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.grey[300],
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const SizedBox(height: 16),
            const Text(
              'Resident Account',
              style: TextStyle(
                fontFamily: 'Satoshi',
                fontSize: 18,
                fontWeight: FontWeight.w800,
                color: EcoPalette.primaryDark,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              widget.authService?.getCurrentUser()?.email ?? 'Arua City Resident',
              style: const TextStyle(fontFamily: 'Satoshi', fontSize: 13, color: Colors.grey),
            ),
            const SizedBox(height: 20),
            ListTile(
              leading: const Icon(Icons.logout_rounded, color: Colors.redAccent),
              title: const Text('Sign Out', style: TextStyle(color: Colors.redAccent, fontWeight: FontWeight.w700)),
              onTap: () async {
                Navigator.of(ctx).pop();
                await widget.authService?.logout();
                if (!mounted) return;
                AppRouter.routeToLogin(
                  context,
                  repository: widget.repository,
                  authService: widget.authService,
                  wasteApiService: widget.wasteApiService,
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final activeOrder = _orders.isNotEmpty
        ? _orders.firstWhere(
            (o) => o.status != RequestStatus.cancelled,
            orElse: () => _orders.first,
          )
        : null;

    Widget bodyContent;
    if (_currentTab == 1) {
      bodyContent = _buildRequestsView();
    } else if (_currentTab == 2) {
      bodyContent = const SupportScreen(embedded: true);
    } else {
      bodyContent = _buildHomeView(activeOrder);
    }

    return Scaffold(
      backgroundColor: EcoPalette.surface,
      appBar: AppBar(
        backgroundColor: EcoPalette.surface,
        elevation: 0,
        scrolledUnderElevation: 0,
        title: const Row(
          children: [
            EcoRouteLeafLogo(size: 26, color: EcoPalette.primaryDark),
            SizedBox(width: 8),
            Text(
              'EcoRoute',
              style: TextStyle(
                fontFamily: 'Satoshi',
                fontSize: 20,
                fontWeight: FontWeight.w800,
                color: EcoPalette.primaryDark,
              ),
            ),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.account_circle_outlined, color: EcoPalette.primaryDark),
            onPressed: _showAccountMenu,
          ),
          const SizedBox(width: 4),
        ],
      ),
      body: bodyContent,
      bottomNavigationBar: Container(
        decoration: const BoxDecoration(
          color: EcoPalette.surface,
          border: Border(top: BorderSide(color: EcoPalette.cardBorder, width: 0.8)),
        ),
        child: NavigationBar(
          selectedIndex: _currentTab,
          backgroundColor: EcoPalette.surface,
          indicatorColor: Colors.transparent,
          elevation: 0,
          onDestinationSelected: (idx) {
            HapticFeedback.selectionClick();
            setState(() => _currentTab = idx);
          },
          destinations: const [
            NavigationDestination(
              icon: Icon(Icons.home_outlined, color: EcoPalette.secondaryDark),
              selectedIcon: Icon(Icons.home_rounded, color: EcoPalette.primaryDark),
              label: 'Home',
            ),
            NavigationDestination(
              icon: Icon(Icons.receipt_long_outlined, color: EcoPalette.secondaryDark),
              selectedIcon: Icon(Icons.receipt_long_rounded, color: EcoPalette.primaryDark),
              label: 'Requests',
            ),
            NavigationDestination(
              icon: Icon(Icons.chat_bubble_outline_rounded, color: EcoPalette.secondaryDark),
              selectedIcon: Icon(Icons.chat_bubble_rounded, color: EcoPalette.primaryDark),
              label: 'Support',
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHomeView(PickupRequest? activeOrder) {
    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Sub-Header
          Row(
            children: [
              const Text(
                'Hello, Resident • Arua City',
                style: TextStyle(
                  fontFamily: 'Satoshi',
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                  color: EcoPalette.primaryDark,
                ),
              ),
              const SizedBox(width: 8),
              Container(
                width: 8,
                height: 8,
                decoration: const BoxDecoration(
                  color: EcoPalette.onlineGreen,
                  shape: BoxShape.circle,
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),

          // Primary CTA: + Book a New Pickup
          SizedBox(
            width: double.infinity,
            height: 52,
            child: FilledButton.icon(
              key: const ValueKey('resident_book_pickup_btn'),
              onPressed: _openOrderBooking,
              icon: const Icon(Icons.add, size: 20),
              label: const Text(
                'Book a New Pickup',
                style: TextStyle(
                  fontFamily: 'Satoshi',
                  fontSize: 16,
                  fontWeight: FontWeight.w800,
                  letterSpacing: 0.2,
                ),
              ),
              style: FilledButton.styleFrom(
                backgroundColor: EcoPalette.buttonDark,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
                elevation: 0,
              ),
            ),
          ),
          const SizedBox(height: 20),

          if (activeOrder != null) ...[
            // Active Tracking Card
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: EcoPalette.cardBorder),
                boxShadow: const [
                  BoxShadow(
                    color: Color(0x0A000000),
                    blurRadius: 10,
                    offset: Offset(0, 4),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        'Tricycle Rider Dispatched',
                        style: TextStyle(
                          fontFamily: 'Satoshi',
                          fontSize: 16,
                          fontWeight: FontWeight.w800,
                          color: EcoPalette.primaryDark,
                        ),
                      ),
                      IconButton(
                        icon: const Icon(Icons.qr_code_rounded, color: EcoPalette.accentTerracotta),
                        tooltip: 'Show Handshake QR Code',
                        onPressed: () => _showQrHandshakeModal(activeOrder),
                        visualDensity: VisualDensity.compact,
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),

                  // Embedded CartoDB Positron Map Preview
                  EcoCartoMap(
                    center: _aruaCenter,
                    zoom: 14.0,
                    height: 150,
                    routePoints: OsrmRoutingService.fallbackAruaToEdiofeRoute,
                    onTap: () => _showQrHandshakeModal(activeOrder),
                  ),
                  const SizedBox(height: 14),

                  // Destination Landmark
                  Row(
                    children: [
                      const Icon(Icons.location_on, size: 16, color: EcoPalette.accentTerracotta),
                      const SizedBox(width: 6),
                      Text(
                        activeOrder.address.isNotEmpty
                            ? activeOrder.address
                            : 'Ediofe (Arua)',
                        style: const TextStyle(
                          fontFamily: 'Satoshi',
                          fontSize: 14,
                          fontWeight: FontWeight.w800,
                          color: EcoPalette.primaryDark,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),

                  // 4-Step Horizontal Progress Tracker
                  _buildFourStepTracker(activeOrder.status),
                  const SizedBox(height: 18),

                  const Divider(height: 1, color: Color(0xFFF0F4F1)),
                  const SizedBox(height: 14),

                  // Order Snapshot details
                  const Text(
                    'Order Snapshot',
                    style: TextStyle(
                      fontFamily: 'Satoshi',
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                      color: Color(0xFF6B8073),
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    activeOrder.description.isNotEmpty
                        ? activeOrder.description
                        : '1 Sack • Household',
                    style: const TextStyle(
                      fontFamily: 'Satoshi',
                      fontSize: 14.5,
                      fontWeight: FontWeight.w700,
                      color: EcoPalette.primaryDark,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    '${activeOrder.priceUgx} UGX • Pay on Collection',
                    style: const TextStyle(
                      fontFamily: 'Satoshi',
                      fontSize: 13.5,
                      color: EcoPalette.secondaryDark,
                    ),
                  ),
                  const SizedBox(height: 12),

                  // View Live Map Tracker action
                  InkWell(
                    onTap: () => _showQrHandshakeModal(activeOrder),
                    child: const Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          'View Live Map Tracker',
                          style: TextStyle(
                            fontFamily: 'Satoshi',
                            fontSize: 13.5,
                            fontWeight: FontWeight.w800,
                            color: EcoPalette.accentTerracotta,
                          ),
                        ),
                        SizedBox(width: 4),
                        Icon(Icons.chevron_right_rounded, size: 18, color: EcoPalette.accentTerracotta),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ] else ...[
            Container(
              padding: const EdgeInsets.symmetric(vertical: 36, horizontal: 20),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: EcoPalette.cardBorder),
              ),
              child: Column(
                children: const [
                  Icon(Icons.recycling_outlined, size: 48, color: EcoPalette.primaryDark),
                  SizedBox(height: 12),
                  Text(
                    'No Active Pickup Scheduled',
                    style: TextStyle(
                      fontFamily: 'Satoshi',
                      fontSize: 16,
                      fontWeight: FontWeight.w800,
                      color: EcoPalette.primaryDark,
                    ),
                  ),
                  SizedBox(height: 6),
                  Text(
                    'You have no pending waste collection requests in Arua City. Tap "Book a New Pickup" above to request an electric tricycle to your gate.',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontFamily: 'Satoshi',
                      fontSize: 12.5,
                      color: Color(0xFF6B8073),
                      height: 1.4,
                    ),
                  ),
                ],
              ),
            ),
          ],
          const SizedBox(height: 20),

          // Quick Utility (Open-Meteo Weather)
          const Text(
            'Quick Utility',
            style: TextStyle(
              fontFamily: 'Satoshi',
              fontSize: 14.5,
              fontWeight: FontWeight.w700,
              color: EcoPalette.secondaryDark,
            ),
          ),
          const SizedBox(height: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: EcoPalette.cardBorder),
            ),
            child: Row(
              children: [
                const Icon(Icons.wb_sunny_outlined, color: Color(0xFFE67E22), size: 22),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    _weather != null
                        ? 'Weather: ${_weather!.conditionSummary} • ${_weather!.temperatureC.toStringAsFixed(1)}°C • Open-Meteo'
                        : 'Weather: Favorable • 20.3°C • Open-Meteo',
                    style: const TextStyle(
                      fontFamily: 'Satoshi',
                      fontSize: 13.5,
                      fontWeight: FontWeight.w600,
                      color: EcoPalette.primaryDark,
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),
        ],
      ),
    );
  }

  Widget _buildFourStepTracker(RequestStatus status) {
    final stepIndex = switch (status) {
      RequestStatus.requested => 0,
      RequestStatus.collected => 1,
      RequestStatus.awaitingVerification => 2,
      RequestStatus.paid => 3,
      RequestStatus.cancelled => -1,
    };

    final steps = ['Requested', 'Collected', 'Verifying', 'Settled'];

    return Column(
      children: [
        Row(
          children: [
            for (var i = 0; i < steps.length; i++) ...[
              // Step node
              Container(
                width: 22,
                height: 22,
                decoration: BoxDecoration(
                  color: i <= stepIndex ? EcoPalette.accentTerracotta : const Color(0xFFD4DDD6),
                  shape: BoxShape.circle,
                ),
                child: Center(
                  child: i < stepIndex
                      ? const Icon(Icons.check, size: 13, color: Colors.white)
                      : i == stepIndex
                          ? Container(
                              width: 8,
                              height: 8,
                              decoration: const BoxDecoration(
                                color: Colors.white,
                                shape: BoxShape.circle,
                              ),
                            )
                          : null,
                ),
              ),
              // Connecting line
              if (i < steps.length - 1)
                Expanded(
                  child: Container(
                    height: 3,
                    color: i < stepIndex ? EcoPalette.accentTerracotta : const Color(0xFFD4DDD6),
                  ),
                ),
            ],
          ],
        ),
        const SizedBox(height: 8),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            for (var i = 0; i < steps.length; i++)
              Text(
                steps[i],
                style: TextStyle(
                  fontFamily: 'Satoshi',
                  fontSize: 11,
                  fontWeight: i == stepIndex ? FontWeight.w800 : FontWeight.w500,
                  color: i <= stepIndex ? EcoPalette.accentTerracotta : const Color(0xFF8A9B8F),
                ),
              ),
          ],
        ),
      ],
    );
  }

  Widget _buildRequestsView() {
    return ListView.builder(
      padding: const EdgeInsets.all(20),
      itemCount: _orders.length,
      itemBuilder: (context, i) {
        final order = _orders[i];
        return Card(
          margin: const EdgeInsets.only(bottom: 12),
          color: Colors.white,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
          elevation: 0,
          child: ListTile(
            title: Text(
              order.description,
              style: const TextStyle(fontWeight: FontWeight.w700, fontFamily: 'Satoshi'),
            ),
            subtitle: Text(
              '${order.status.label} • ${order.priceUgx} UGX',
              style: const TextStyle(fontFamily: 'Satoshi', fontSize: 13),
            ),
            trailing: const Icon(Icons.chevron_right),
            onTap: () => _showQrHandshakeModal(order),
          ),
        );
      },
    );
  }
}
