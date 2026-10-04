import 'dart:async';

import 'package:flutter/material.dart';

import '../../app/config/app_config.dart';
import '../../core/pickup_request_repository.dart';
import '../../domain/entities/pickup_request.dart';
import '../../domain/enums/request_status.dart';
import '../../domain/enums/waste_type.dart';
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
    _timer = Timer(const Duration(seconds: 5), () {
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

  void _showAuth() {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      builder: (_) =>
          AuthSheet(onAuthenticated: () => setState(() => _signedIn = true)),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Flexible(child: BrandLockup(compact: true)),
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
    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(16, 4, 16, 28),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildWelcome(),
          const SizedBox(height: 16),
          _buildMapPanel(),
          const SizedBox(height: 16),
          _buildReportButton(),
          const SizedBox(height: 18),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Arua collection schedule',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w800,
                  color: Color(0xFF183B20),
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
          child: Text(
            'Nearby collection points',
            style: TextStyle(
              fontWeight: FontWeight.w800,
              color: Color(0xFF21452A),
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
                      'Arua centre service radius: 12 km',
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
            child: ListTile(
              leading: const Icon(
                Icons.pending_actions,
                color: Color(0xFF2E7D32),
              ),
              title: Text(
                order.wasteType.label,
                style: const TextStyle(fontWeight: FontWeight.w700),
              ),
              subtitle: Text(order.description),
              trailing: Text(order.status.label),
            ),
          ),
      ],
    );
  }

  Widget _buildProfile() => Center(
    child: _signedIn
        ? const Text('You are signed in to EcoRoute.')
        : FilledButton.icon(
            onPressed: _showAuth,
            icon: const Icon(Icons.login),
            label: const Text('Sign in or create account'),
          ),
  );
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
