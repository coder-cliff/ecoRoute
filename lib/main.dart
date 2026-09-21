import 'dart:async';

import 'package:flutter/material.dart';

void main() => runApp(const EcoRouteApp());

class EcoRouteApp extends StatelessWidget {
  const EcoRouteApp({super.key});

  @override
  Widget build(BuildContext context) {
    const green = Color(0xFF2E7D32);
    return MaterialApp(
      title: 'EcoRoute',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        useMaterial3: true,
        colorScheme: ColorScheme.fromSeed(seedColor: green),
        scaffoldBackgroundColor: const Color(0xFFF7FAF5),
        appBarTheme: const AppBarTheme(
          backgroundColor: Color(0xFFF7FAF5),
          surfaceTintColor: Colors.transparent,
          elevation: 0,
        ),
        inputDecorationTheme: InputDecorationTheme(
          filled: true,
          fillColor: Colors.white,
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: BorderSide.none),
          enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: const BorderSide(color: Color(0xFFDCE8DB))),
          focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: const BorderSide(color: green, width: 2)),
        ),
      ),
      home: const EcoRouteSplash(),
    );
  }
}

class EcoRouteSplash extends StatefulWidget {
  const EcoRouteSplash({super.key});

  @override
  State<EcoRouteSplash> createState() => _EcoRouteSplashState();
}

class _EcoRouteSplashState extends State<EcoRouteSplash> {
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _timer = Timer(const Duration(seconds: 5), () {
      if (mounted) {
        Navigator.of(context).pushReplacement(MaterialPageRoute(builder: (_) => const EcoRouteHome()));
      }
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => const Scaffold(
    backgroundColor: Color(0xFF2EAD65),
    body: Center(child: BrandLockup(splash: true)),
  );
}

class WasteOrder {
  const WasteOrder({required this.wasteType, required this.description, required this.submittedAt});
  final String wasteType;
  final String description;
  final DateTime submittedAt;
}

class EcoRouteHome extends StatefulWidget {
  const EcoRouteHome({super.key});

  @override
  State<EcoRouteHome> createState() => _EcoRouteHomeState();
}

class _EcoRouteHomeState extends State<EcoRouteHome> {
  int _tab = 0;
  bool _signedIn = false;
  final List<WasteOrder> _orders = [];

  void _openOrder() {
    if (!_signedIn) {
      _showAuth();
      return;
    }
    Navigator.of(context).push(MaterialPageRoute(builder: (_) => OrderPage(onSubmitted: _addOrder)));
  }

  void _addOrder(WasteOrder order) {
    setState(() => _orders.insert(0, order));
    Navigator.of(context).pop();
    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Your collection order has been submitted.')));
  }

  void _showAuth() {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      builder: (_) => AuthSheet(onAuthenticated: () => setState(() => _signedIn = true)),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const BrandLockup(compact: true), actions: [IconButton(onPressed: _showAuth, icon: const Icon(Icons.notifications_none_rounded)), const SizedBox(width: 8)]),
      body: IndexedStack(index: _tab, children: [_buildBrowse(), _buildOrders(), _buildProfile()]),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _tab,
        labelBehavior: MediaQuery.sizeOf(context).width < 360 ? NavigationDestinationLabelBehavior.onlyShowSelected : NavigationDestinationLabelBehavior.alwaysShow,
        onDestinationSelected: (value) => setState(() => _tab = value),
        destinations: const [
          NavigationDestination(icon: Icon(Icons.home_outlined), selectedIcon: Icon(Icons.home), label: 'Home'),
          NavigationDestination(icon: Icon(Icons.stars_outlined), selectedIcon: Icon(Icons.stars), label: 'My Points'),
          NavigationDestination(icon: Icon(Icons.person_outline), selectedIcon: Icon(Icons.person), label: 'Profile'),
        ],
      ),
    );
  }

  Widget _buildBrowse() {
    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(16, 4, 16, 28),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        _buildWelcome(),
        const SizedBox(height: 16),
        _buildMapPanel(),
        const SizedBox(height: 16),
        _buildReportButton(),
        const SizedBox(height: 18),
        Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
          const Text('Nearby reports', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800, color: Color(0xFF183B20))),
          TextButton(onPressed: () => setState(() => _tab = 1), child: const Text('See all')),
        ]),
        _reportTile('Overflowing bin', '2 min ago', Icons.delete_outline, const Color(0xFFE7F3E8)),
        _reportTile('Litter on sidewalk', '18 min ago', Icons.warning_amber_rounded, const Color(0xFFFFF2D8)),
      ]),
    );
  }

  Widget _buildWelcome() => LayoutBuilder(builder: (context, constraints) {
    final greeting = const Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Text('Good morning, Alex', style: TextStyle(fontSize: 19, fontWeight: FontWeight.w800, color: Color(0xFF183B20))),
      SizedBox(height: 3),
      Text('Let’s keep your neighborhood clean.', style: TextStyle(color: Color(0xFF647568))),
    ]);
    return Padding(padding: const EdgeInsets.fromLTRB(4, 8, 4, 0), child: constraints.maxWidth < 340 ? greeting : Row(children: [_WelcomeIcon(), const SizedBox(width: 12), Flexible(child: greeting)]));
  });

  Widget _buildMapPanel() => Container(
    height: 294,
    clipBehavior: Clip.antiAlias,
    decoration: BoxDecoration(color: const Color(0xFFE7F0E6), borderRadius: BorderRadius.circular(22), border: Border.all(color: const Color(0xFFD2E1D1))),
    child: Stack(children: [
      CustomPaint(size: Size.infinite, painter: _MapPainter()),
      const Positioned(left: 18, top: 18, child: Text('Nearby collection points', style: TextStyle(fontWeight: FontWeight.w800, color: Color(0xFF21452A)))),
      Positioned(right: 14, top: 14, child: _mapControl(Icons.layers_outlined)),
      Positioned(right: 14, bottom: 62, child: Column(children: [_mapControl(Icons.add), const SizedBox(height: 8), _mapControl(Icons.remove)])),
      const Positioned(left: 80, top: 92, child: _MapPin()),
      const Positioned(left: 188, top: 150, child: _MapPin()),
      const Positioned(right: 72, top: 102, child: _MapPin()),
      const Positioned(left: 132, bottom: 54, child: _MapPin()),
      Positioned(left: 16, right: 16, bottom: 14, child: Container(padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10), decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(14), boxShadow: const [BoxShadow(color: Color(0x18000000), blurRadius: 10)]), child: const Row(children: [Icon(Icons.location_on_outlined, color: Color(0xFF2E7D32)), SizedBox(width: 8), Expanded(child: Text('4 collection points within 1 km', style: TextStyle(fontWeight: FontWeight.w700), maxLines: 1, overflow: TextOverflow.ellipsis)), SizedBox(width: 8), Icon(Icons.chevron_right, color: Color(0xFF718273))]))),
    ]),
  );

  Widget _mapControl(IconData icon) => Container(width: 38, height: 38, decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(12), boxShadow: const [BoxShadow(color: Color(0x18000000), blurRadius: 8)]), child: Icon(icon, size: 20, color: const Color(0xFF45604A)));

  Widget _buildReportButton() => SizedBox(width: double.infinity, height: 54, child: FilledButton.icon(onPressed: _openOrder, icon: const Icon(Icons.add_a_photo_outlined), label: const _ResponsiveButtonLabel('REPORT AN ISSUE'), style: FilledButton.styleFrom(backgroundColor: const Color(0xFF2E8B57), foregroundColor: Colors.white, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)))));

  Widget _reportTile(String title, String time, IconData icon, Color background) => Container(margin: const EdgeInsets.only(bottom: 10), padding: const EdgeInsets.all(13), decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16), border: Border.all(color: const Color(0xFFE2EAE1))), child: Row(children: [Container(width: 42, height: 42, decoration: BoxDecoration(color: background, borderRadius: BorderRadius.circular(12)), child: Icon(icon, color: const Color(0xFF3D7850))), const SizedBox(width: 12), Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text(title, style: const TextStyle(fontWeight: FontWeight.w700), overflow: TextOverflow.ellipsis), const SizedBox(height: 3), Text(time, style: const TextStyle(fontSize: 12, color: Color(0xFF78877B)))])), const SizedBox(width: 8), const Icon(Icons.chevron_right, color: Color(0xFF9AA79C))]));

  Widget _buildOrders() {
    return _orders.isEmpty
        ? const Center(child: Padding(padding: EdgeInsets.all(28), child: Column(mainAxisSize: MainAxisSize.min, children: [Icon(Icons.receipt_long_outlined, size: 56, color: Color(0xFF7C9580)), SizedBox(height: 12), Text('No collection orders yet', style: TextStyle(fontSize: 20, fontWeight: FontWeight.w800)), SizedBox(height: 6), Text('Your submitted orders will appear here.', textAlign: TextAlign.center)])))
        : ListView(padding: const EdgeInsets.all(20), children: [for (final order in _orders) Card(child: ListTile(leading: const Icon(Icons.pending_actions, color: Color(0xFF2E7D32)), title: Text(order.wasteType, style: const TextStyle(fontWeight: FontWeight.w700)), subtitle: Text(order.description), trailing: const Text('Pending')))]);
  }

  Widget _buildProfile() => Center(child: _signedIn ? const Text('You are signed in to EcoRoute.') : FilledButton.icon(onPressed: _showAuth, icon: const Icon(Icons.login), label: const Text('Sign in or create account')));
}

class OrderPage extends StatefulWidget {
  const OrderPage({required this.onSubmitted, super.key});
  final ValueChanged<WasteOrder> onSubmitted;
  @override
  State<OrderPage> createState() => _OrderPageState();
}

class _OrderPageState extends State<OrderPage> {
  final _formKey = GlobalKey<FormState>();
  String? _wasteType;
  final _description = TextEditingController();

  @override
  void dispose() { _description.dispose(); super.dispose(); }

  void _submit() {
    if (!_formKey.currentState!.validate()) return;
    widget.onSubmitted(WasteOrder(wasteType: _wasteType!, description: _description.text.trim(), submittedAt: DateTime.now()));
  }

  @override
  Widget build(BuildContext context) => Scaffold(appBar: AppBar(title: const Text('Order a collection')), body: Form(key: _formKey, child: ListView(padding: const EdgeInsets.all(20), children: [
    const Text('Tell us what to collect', style: TextStyle(fontSize: 26, fontWeight: FontWeight.w800, color: Color(0xFF183B20))),
    const SizedBox(height: 8), const Text('Give us a few details and our collection team will take it from there.'), const SizedBox(height: 24),
    DropdownButtonFormField<String>(initialValue: _wasteType, decoration: const InputDecoration(labelText: 'Waste type'), items: const [DropdownMenuItem(value: 'Organic waste', child: Text('Organic waste')), DropdownMenuItem(value: 'Recyclables', child: Text('Recyclables')), DropdownMenuItem(value: 'General waste', child: Text('General waste')), DropdownMenuItem(value: 'Mixed waste', child: Text('Mixed waste'))], onChanged: (value) => setState(() => _wasteType = value), validator: (value) => value == null ? 'Select a waste type' : null),
    const SizedBox(height: 16), TextFormField(controller: _description, maxLines: 5, decoration: const InputDecoration(labelText: 'Collection details', hintText: 'Describe the waste and where it can be collected.'), validator: (value) => value == null || value.trim().length < 10 ? 'Please enter at least 10 characters' : null),
    const SizedBox(height: 24), SizedBox(width: double.infinity, height: 52, child: FilledButton.icon(onPressed: _submit, icon: const Icon(Icons.send_outlined), label: const _ResponsiveButtonLabel('Submit collection order'))),
  ])));
}

class AuthSheet extends StatefulWidget {
  const AuthSheet({required this.onAuthenticated, super.key});
  final VoidCallback onAuthenticated;
  @override
  State<AuthSheet> createState() => _AuthSheetState();
}

class _AuthSheetState extends State<AuthSheet> {
  bool _createAccount = false;
  final _formKey = GlobalKey<FormState>();
  final _email = TextEditingController();
  final _password = TextEditingController();
  @override
  void dispose() { _email.dispose(); _password.dispose(); super.dispose(); }
  void _submit() { if (_formKey.currentState!.validate()) { Navigator.pop(context); widget.onAuthenticated(); } }
  @override
  Widget build(BuildContext context) => Padding(padding: EdgeInsets.only(left: 20, right: 20, bottom: MediaQuery.viewInsetsOf(context).bottom + 20), child: Form(key: _formKey, child: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.start, children: [
    Text(_createAccount ? 'Create your EcoRoute account' : 'Welcome back', style: const TextStyle(fontSize: 23, fontWeight: FontWeight.w800, color: Color(0xFF183B20))), const SizedBox(height: 6), Text(_createAccount ? 'Create an account to request waste collection.' : 'Sign in to request a collection for your waste.'), const SizedBox(height: 20),
    if (_createAccount) ...[TextFormField(decoration: const InputDecoration(labelText: 'Full name'), validator: (value) => value == null || value.trim().isEmpty ? 'Enter your name' : null), const SizedBox(height: 12)],
    TextFormField(controller: _email, keyboardType: TextInputType.emailAddress, decoration: const InputDecoration(labelText: 'Email address'), validator: (value) => value == null || !value.contains('@') ? 'Enter a valid email' : null), const SizedBox(height: 12), TextFormField(controller: _password, obscureText: true, decoration: const InputDecoration(labelText: 'Password'), validator: (value) => value == null || value.length < 6 ? 'Use at least 6 characters' : null), const SizedBox(height: 18),
    SizedBox(width: double.infinity, height: 50, child: FilledButton(onPressed: _submit, child: _ResponsiveButtonLabel(_createAccount ? 'Create account' : 'Sign in'))), TextButton(onPressed: () => setState(() => _createAccount = !_createAccount), child: _ResponsiveButtonLabel(_createAccount ? 'Already have an account? Sign in' : 'New to EcoRoute? Create an account')),
  ])));
}

class BrandLockup extends StatelessWidget {
  const BrandLockup({this.compact = false, this.splash = false, super.key});
  final bool compact;
  final bool splash;
  @override
  Widget build(BuildContext context) => splash
      ? Column(mainAxisSize: MainAxisSize.min, children: [Image.asset('assets/EcoRoute_logo.png', width: 126, height: 126, fit: BoxFit.contain, color: Colors.white), const SizedBox(height: 14), const Text('EcoRoute', style: TextStyle(color: Colors.white, fontSize: 34, fontWeight: FontWeight.w800))])
      : Row(mainAxisSize: MainAxisSize.min, children: [Image.asset('assets/EcoRoute_logo.png', width: compact ? 44 : 120, height: compact ? 44 : 120, fit: BoxFit.contain), const SizedBox(width: 10), Text('EcoRoute', style: TextStyle(fontSize: compact ? 20 : 40, fontWeight: FontWeight.w800, color: const Color(0xFF123B1A)))]);
}

class _ResponsiveButtonLabel extends StatelessWidget {
  const _ResponsiveButtonLabel(this.text);
  final String text;

  @override
  Widget build(BuildContext context) => FittedBox(fit: BoxFit.scaleDown, child: Text(text, maxLines: 1, overflow: TextOverflow.ellipsis));
}

class _WelcomeIcon extends StatelessWidget {
  const _WelcomeIcon();

  @override
  Widget build(BuildContext context) => Container(width: 48, height: 48, decoration: BoxDecoration(color: const Color(0xFFDCEFE0), borderRadius: BorderRadius.circular(16)), child: const Icon(Icons.waving_hand_rounded, color: Color(0xFF2E7D32)));
}

class _MapPin extends StatelessWidget {
  const _MapPin();

  @override
  Widget build(BuildContext context) => Container(width: 34, height: 34, decoration: BoxDecoration(color: const Color(0xFF3D8B5A), shape: BoxShape.circle, border: Border.all(color: Colors.white, width: 3), boxShadow: const [BoxShadow(color: Color(0x30000000), blurRadius: 6)]), child: const Icon(Icons.recycling_rounded, size: 18, color: Colors.white));
}

class _MapPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final road = Paint()..color = const Color(0xFFD2E1D0)..strokeWidth = 18..style = PaintingStyle.stroke;
    final smallRoad = Paint()..color = const Color(0xFFDCE8DA)..strokeWidth = 9..style = PaintingStyle.stroke;
    final river = Paint()..color = const Color(0xFFB9DDE2)..strokeWidth = 24..style = PaintingStyle.stroke;
    final mainRoad = Path()..moveTo(-20, size.height * .72)..quadraticBezierTo(size.width * .35, size.height * .52, size.width + 20, size.height * .62);
    final crossRoad = Path()..moveTo(size.width * .22, -10)..quadraticBezierTo(size.width * .5, size.height * .42, size.width * .72, size.height + 10);
    final sideRoad = Path()..moveTo(-10, size.height * .22)..quadraticBezierTo(size.width * .45, size.height * .1, size.width + 10, size.height * .28);
    canvas.drawPath(mainRoad, road);
    canvas.drawPath(crossRoad, road);
    canvas.drawPath(sideRoad, smallRoad);
    final waterPath = Path()..moveTo(size.width * .84, -10)..quadraticBezierTo(size.width * .65, size.height * .32, size.width * .92, size.height + 10);
    canvas.drawPath(waterPath, river);
    for (var index = 0; index < 7; index++) {
      final x = 28.0 + (index * 61) % size.width;
      final y = 70.0 + (index * 47) % (size.height - 95);
      canvas.drawCircle(Offset(x, y), 2.5, Paint()..color = const Color(0xFFB8CFB4));
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

