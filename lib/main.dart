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
        inputDecorationTheme: InputDecorationTheme(
          filled: true,
          fillColor: Colors.white,
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: BorderSide.none),
          enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: const BorderSide(color: Color(0xFFDCE8DB))),
          focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: const BorderSide(color: green, width: 2)),
        ),
      ),
      home: const EcoRouteHome(),
    );
  }
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
      appBar: AppBar(
        title: const BrandLockup(compact: true),
        actions: [
          TextButton.icon(
            onPressed: _showAuth,
            icon: Icon(_signedIn ? Icons.verified_user_outlined : Icons.login_outlined),
            label: Text(_signedIn ? 'Account' : 'Sign in'),
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: IndexedStack(index: _tab, children: [_buildBrowse(), _buildOrders(), _buildProfile()]),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _tab,
        onDestinationSelected: (value) => setState(() => _tab = value),
        destinations: const [
          NavigationDestination(icon: Icon(Icons.explore_outlined), selectedIcon: Icon(Icons.explore), label: 'Discover'),
          NavigationDestination(icon: Icon(Icons.receipt_long_outlined), selectedIcon: Icon(Icons.receipt_long), label: 'Orders'),
          NavigationDestination(icon: Icon(Icons.person_outline), selectedIcon: Icon(Icons.person), label: 'Profile'),
        ],
      ),
    );
  }

  Widget _buildBrowse() {
    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(20, 18, 20, 32),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text('A cleaner route\nstarts with you.', style: Theme.of(context).textTheme.headlineMedium?.copyWith(fontWeight: FontWeight.w800, color: const Color(0xFF123B1A), height: 1.08)),
        const SizedBox(height: 10),
        const Text('Simple, reliable waste collection for homes, businesses, and the communities around them.', style: TextStyle(color: Color(0xFF5D7160), fontSize: 16, height: 1.45)),
        const SizedBox(height: 24),
        _buildOrderBanner(),
        const SizedBox(height: 28),
        Text('Explore EcoRoute', style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w800, color: const Color(0xFF183B20))),
        const SizedBox(height: 12),
        _infoTile(Icons.calendar_month_outlined, 'Collection schedules', 'Know when our team will be in your area.'),
        _infoTile(Icons.recycling_outlined, 'Sort with confidence', 'Separate organic, recyclable, and general waste.'),
        _infoTile(Icons.route_outlined, 'Routes that matter', 'Every order helps us plan more efficient collections.'),
        const SizedBox(height: 18),
        const Text('How it works', style: TextStyle(fontSize: 20, fontWeight: FontWeight.w800, color: Color(0xFF183B20))),
        const SizedBox(height: 14),
        Row(crossAxisAlignment: CrossAxisAlignment.start, children: const [
          _Step(number: '01', title: 'Browse', text: 'Learn about collection.'),
          _Step(number: '02', title: 'Sign in', text: 'Create an account to order.'),
          _Step(number: '03', title: 'Collect', text: 'We handle the rest.'),
        ]),
      ]),
    );
  }

  Widget _buildOrderBanner() {
    return Container(
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(color: const Color(0xFF246B2B), borderRadius: BorderRadius.circular(24)),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        const Icon(Icons.local_shipping_outlined, color: Color(0xFFD8F0D6), size: 34),
        const SizedBox(height: 14),
        const Text('Ready for a collection?', style: TextStyle(color: Colors.white, fontSize: 22, fontWeight: FontWeight.w800)),
        const SizedBox(height: 6),
        Text(_signedIn ? 'Place a new order in under a minute.' : 'Sign in or create an account when you are ready to place an order.', style: const TextStyle(color: Color(0xFFD8F0D6), height: 1.35)),
        const SizedBox(height: 18),
        SizedBox(width: double.infinity, child: FilledButton.icon(onPressed: _openOrder, icon: const Icon(Icons.arrow_forward), label: Text(_signedIn ? 'Order a collection' : 'Sign in to order'), style: FilledButton.styleFrom(backgroundColor: Colors.white, foregroundColor: const Color(0xFF246B2B), padding: const EdgeInsets.symmetric(vertical: 14)))),
      ]),
    );
  }

  Widget _infoTile(IconData icon, String title, String text) => Card(color: Colors.white, elevation: 0, margin: const EdgeInsets.only(bottom: 10), child: ListTile(leading: CircleAvatar(backgroundColor: const Color(0xFFE3F1E1), foregroundColor: const Color(0xFF2E7D32), child: Icon(icon)), title: Text(title, style: const TextStyle(fontWeight: FontWeight.w700)), subtitle: Text(text)));

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
    const SizedBox(height: 24), SizedBox(height: 52, child: FilledButton.icon(onPressed: _submit, icon: const Icon(Icons.send_outlined), label: const Text('Submit collection order'))),
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
    SizedBox(width: double.infinity, height: 50, child: FilledButton(onPressed: _submit, child: Text(_createAccount ? 'Create account' : 'Sign in'))), TextButton(onPressed: () => setState(() => _createAccount = !_createAccount), child: Text(_createAccount ? 'Already have an account? Sign in' : 'New to EcoRoute? Create an account')),
  ])));
}

class BrandLockup extends StatelessWidget {
  const BrandLockup({this.compact = false, super.key});
  final bool compact;
  @override
  Widget build(BuildContext context) => Row(mainAxisSize: MainAxisSize.min, children: [Image.asset('assets/EcoRoute_logo.png', width: compact ? 44 : 120, height: compact ? 44 : 120, fit: BoxFit.contain), const SizedBox(width: 10), Text('EcoRoute', style: TextStyle(fontSize: compact ? 20 : 40, fontWeight: FontWeight.w800, color: const Color(0xFF123B1A)))]);
}

class _Step extends StatelessWidget {
  const _Step({required this.number, required this.title, required this.text});
  final String number;
  final String title;
  final String text;
  @override
  Widget build(BuildContext context) => Expanded(child: Padding(padding: const EdgeInsets.only(right: 10), child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text(number, style: const TextStyle(color: Color(0xFF2E7D32), fontWeight: FontWeight.w800)), const SizedBox(height: 6), Text(title, style: const TextStyle(fontWeight: FontWeight.w800)), const SizedBox(height: 3), Text(text, style: const TextStyle(fontSize: 12, color: Color(0xFF617264)))])));
}
