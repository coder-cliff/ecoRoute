import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:url_launcher/url_launcher.dart';

import 'core/services/pdf_report_service.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  SystemChrome.setSystemUIOverlayStyle(
    const SystemUiOverlayStyle(
      statusBarColor: Color(0xFFE8ECE7),
      statusBarIconBrightness: Brightness.dark,
      statusBarBrightness: Brightness.light,
      systemNavigationBarColor: Color(0xFFE8ECE7),
      systemNavigationBarIconBrightness: Brightness.dark,
      systemNavigationBarDividerColor: Colors.transparent,
    ),
  );
  runApp(const EcoRouteApp());
}

class EcoRouteApp extends StatelessWidget {
  const EcoRouteApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'EcoRoute Arua',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        useMaterial3: true,
        scaffoldBackgroundColor: const Color(0xFFE8ECE7),
        primaryColor: const Color(0xFF0D2618),
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFF0D2618),
          surface: const Color(0xFFE8ECE7),
          primary: const Color(0xFF0D2618),
          secondary: const Color(0xFF9C3D18),
        ),
        fontFamily: 'Satoshi',
        appBarTheme: const AppBarTheme(
          backgroundColor: Color(0xFFE8ECE7),
          elevation: 0,
          scrolledUnderElevation: 0,
          surfaceTintColor: Colors.transparent,
          iconTheme: IconThemeData(color: Color(0xFF0D2618)),
          titleTextStyle: TextStyle(
            fontFamily: 'Satoshi',
            color: Color(0xFF0D2618),
            fontSize: 20,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
      initialRoute: '/',
      routes: {
        '/': (context) => const SplashScreen(),
        '/login': (context) => const LoginScreen(),
        '/resident': (context) => const ResidentRootScreen(),
        '/rider': (context) => const RiderRootScreen(),
        '/admin': (context) => const AdminRootScreen(),
      },
    );
  }
}

// =================================================================
// 1. SPLASH & LOGIN SCREENS
// =================================================================

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  @override
  void initState() {
    super.initState();
    Future.delayed(const Duration(milliseconds: 1800), () {
      if (mounted) {
        Navigator.pushReplacementNamed(context, '/login');
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFE8ECE7),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 80,
              height: 80,
              decoration: BoxDecoration(
                color: const Color(0xFF0D2618),
                borderRadius: BorderRadius.circular(24),
                boxShadow: const [
                  BoxShadow(
                    color: Color(0x1A0D2618),
                    blurRadius: 16,
                    offset: Offset(0, 6),
                  ),
                ],
              ),
              child: const Icon(Icons.eco, color: Colors.white, size: 44),
            ),
            const SizedBox(height: 20),
            const Text(
              'EcoRoute',
              style: TextStyle(
                fontFamily: 'Satoshi',
                fontSize: 34,
                fontWeight: FontWeight.w900,
                color: Color(0xFF0D2618),
                letterSpacing: -0.5,
              ),
            ),
            const SizedBox(height: 6),
            const Text(
              'Arua City Waste Management',
              style: TextStyle(
                fontFamily: 'Satoshi',
                fontSize: 14,
                color: Color(0xFF1A3A28),
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController(text: '••••••••');
  bool _obscure = true;

  void _handleLogin([String? overrideEmail]) {
    final email = (overrideEmail ?? _emailController.text).trim().toLowerCase();
    HapticFeedback.mediumImpact();
    if (email.contains('admin')) {
      Navigator.pushReplacementNamed(context, '/admin');
    } else if (email.contains('rider')) {
      Navigator.pushReplacementNamed(context, '/rider');
    } else {
      Navigator.pushReplacementNamed(context, '/resident');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFE8ECE7),
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 400),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Center(
                    child: Container(
                      width: 60,
                      height: 60,
                      decoration: BoxDecoration(
                        color: const Color(0xFF0D2618),
                        borderRadius: BorderRadius.circular(18),
                      ),
                      child: const Icon(Icons.eco, color: Colors.white, size: 34),
                    ),
                  ),
                  const SizedBox(height: 16),
                  const Text(
                    'EcoRoute',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontFamily: 'Satoshi',
                      fontSize: 24,
                      fontWeight: FontWeight.w900,
                      color: Color(0xFF0D2618),
                    ),
                  ),
                  const SizedBox(height: 24),
                  const Text(
                    'Sign In',
                    style: TextStyle(
                      fontFamily: 'Satoshi',
                      fontSize: 28,
                      fontWeight: FontWeight.w900,
                      color: Color(0xFF0D2618),
                    ),
                  ),
                  const SizedBox(height: 6),
                  const Text(
                    'Sign in to access your role-based operations hub',
                    style: TextStyle(
                      fontFamily: 'Satoshi',
                      fontSize: 13.5,
                      color: Color(0xFF1A3A28),
                    ),
                  ),
                  const SizedBox(height: 24),
                  TextField(
                    controller: _emailController,
                    decoration: InputDecoration(
                      labelText: 'Email Address',
                      hintText: 'resident@, rider@, or admin@',
                      filled: true,
                      fillColor: Colors.white,
                      prefixIcon: const Icon(Icons.email_outlined, size: 20),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(14),
                        borderSide: const BorderSide(color: Color(0xFFD4DDD6)),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(14),
                        borderSide: const BorderSide(color: Color(0xFFD4DDD6)),
                      ),
                    ),
                  ),
                  const SizedBox(height: 14),
                  TextField(
                    controller: _passwordController,
                    obscureText: _obscure,
                    decoration: InputDecoration(
                      labelText: 'Password',
                      filled: true,
                      fillColor: Colors.white,
                      prefixIcon: const Icon(Icons.lock_outline, size: 20),
                      suffixIcon: IconButton(
                        icon: Icon(_obscure ? Icons.visibility_off_outlined : Icons.visibility_outlined, size: 20),
                        onPressed: () => setState(() => _obscure = !_obscure),
                      ),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(14),
                        borderSide: const BorderSide(color: Color(0xFFD4DDD6)),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(14),
                        borderSide: const BorderSide(color: Color(0xFFD4DDD6)),
                      ),
                    ),
                  ),
                  const SizedBox(height: 22),
                  ElevatedButton(
                    onPressed: () => _handleLogin(),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF0D2618),
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                      elevation: 0,
                    ),
                    child: const Text(
                      'Sign In',
                      style: TextStyle(fontFamily: 'Satoshi', fontSize: 16, fontWeight: FontWeight.bold),
                    ),
                  ),
                  const SizedBox(height: 24),
                  const Text(
                    'Quick Demo Portals:',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontFamily: 'Satoshi',
                      fontSize: 12.5,
                      fontWeight: FontWeight.w700,
                      color: Color(0xFF6B8073),
                    ),
                  ),
                  const SizedBox(height: 10),
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton(
                          onPressed: () => _handleLogin('resident@ecoroute.ug'),
                          style: OutlinedButton.styleFrom(
                            side: const BorderSide(color: Color(0xFF0D2618)),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                            padding: const EdgeInsets.symmetric(vertical: 10),
                          ),
                          child: const Text('Resident', style: TextStyle(fontFamily: 'Satoshi', color: Color(0xFF0D2618), fontWeight: FontWeight.bold, fontSize: 12.5)),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: OutlinedButton(
                          onPressed: () => _handleLogin('rider@ecoroute.ug'),
                          style: OutlinedButton.styleFrom(
                            side: const BorderSide(color: Color(0xFF0D2618)),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                            padding: const EdgeInsets.symmetric(vertical: 10),
                          ),
                          child: const Text('Rider', style: TextStyle(fontFamily: 'Satoshi', color: Color(0xFF0D2618), fontWeight: FontWeight.bold, fontSize: 12.5)),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: OutlinedButton(
                          onPressed: () => _handleLogin('admin@ecoroute.ug'),
                          style: OutlinedButton.styleFrom(
                            side: const BorderSide(color: Color(0xFF9C3D18)),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                            padding: const EdgeInsets.symmetric(vertical: 10),
                          ),
                          child: const Text('Admin', style: TextStyle(fontFamily: 'Satoshi', color: Color(0xFF9C3D18), fontWeight: FontWeight.bold, fontSize: 12.5)),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

// =================================================================
// 2. RESIDENT ACCOUNT (Home, Requests, Support)
// =================================================================

class ResidentRootScreen extends StatefulWidget {
  const ResidentRootScreen({super.key});

  @override
  State<ResidentRootScreen> createState() => _ResidentRootScreenState();
}

class _ResidentRootScreenState extends State<ResidentRootScreen> {
  int _currentIndex = 0;

  final List<Widget> _screens = const [
    ResidentHomeScreen(),
    ResidentRequestsScreen(),
    ResidentSupportScreen(),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFE8ECE7),
      body: _screens[_currentIndex],
      bottomNavigationBar: Container(
        decoration: const BoxDecoration(
          color: Colors.white,
          border: Border(top: BorderSide(color: Color(0xFFE0E5E1), width: 1)),
        ),
        child: BottomNavigationBar(
          currentIndex: _currentIndex,
          selectedItemColor: const Color(0xFF9C3D18),
          unselectedItemColor: const Color(0xFF1A3A28),
          backgroundColor: Colors.white,
          elevation: 0,
          type: BottomNavigationBarType.fixed,
          selectedLabelStyle: const TextStyle(fontFamily: 'Satoshi', fontWeight: FontWeight.bold, fontSize: 12),
          unselectedLabelStyle: const TextStyle(fontFamily: 'Satoshi', fontWeight: FontWeight.w600, fontSize: 12),
          onTap: (index) {
            HapticFeedback.selectionClick();
            setState(() => _currentIndex = index);
          },
          items: const [
            BottomNavigationBarItem(icon: Icon(Icons.home_rounded), label: 'Home'),
            BottomNavigationBarItem(icon: Icon(Icons.list_alt_rounded), label: 'Requests'),
            BottomNavigationBarItem(icon: Icon(Icons.support_agent_rounded), label: 'Support'),
          ],
        ),
      ),
    );
  }
}

class ResidentHomeScreen extends StatelessWidget {
  const ResidentHomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFE8ECE7),
      appBar: AppBar(
        title: const Row(
          children: [
            Icon(Icons.eco, color: Color(0xFF0D2618), size: 24),
            SizedBox(width: 8),
            Text('EcoRoute', style: TextStyle(fontWeight: FontWeight.w900)),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout_rounded),
            tooltip: 'Sign Out',
            onPressed: () => Navigator.pushReplacementNamed(context, '/login'),
          ),
          const SizedBox(width: 4),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Row(
              children: [
                Text(
                  'Hello, Resident • Arua City',
                  style: TextStyle(
                    fontFamily: 'Satoshi',
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                    color: Color(0xFF0D2618),
                  ),
                ),
                SizedBox(width: 8),
                Icon(Icons.circle, color: Color(0xFF22C55E), size: 10),
              ],
            ),
            const SizedBox(height: 16),

            // + Book a New Pickup
            ElevatedButton.icon(
              onPressed: () {
                HapticFeedback.mediumImpact();
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Opening collection request booking...'),
                    backgroundColor: Color(0xFF0D2618),
                  ),
                );
              },
              icon: const Icon(Icons.add, color: Colors.white),
              label: const Text(
                'Book a New Pickup',
                style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF0D2618),
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                elevation: 0,
              ),
            ),
            const SizedBox(height: 20),

            // Active Tracking Card
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: const Color(0xFFE0E5E1)),
                boxShadow: const [
                  BoxShadow(color: Color(0x0A000000), blurRadius: 10, offset: Offset(0, 4)),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Tricycle Rider Dispatched',
                    style: TextStyle(
                      fontFamily: 'Satoshi',
                      fontSize: 16,
                      fontWeight: FontWeight.w800,
                      color: Color(0xFF0D2618),
                    ),
                  ),
                  const SizedBox(height: 12),

                  // Mini Map Graphic Container
                  Container(
                    height: 130,
                    width: double.infinity,
                    decoration: BoxDecoration(
                      color: const Color(0xFFE8ECE7),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: const Color(0xFFD4DDD6)),
                    ),
                    child: Stack(
                      children: [
                        CustomPaint(
                          size: const Size(double.infinity, 130),
                          painter: _MapRoadsPainter(),
                        ),
                        Center(
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                decoration: BoxDecoration(
                                  color: const Color(0xFF0D2618),
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: const Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Icon(Icons.location_on, color: Color(0xFF9C3D18), size: 14),
                                    SizedBox(width: 4),
                                    Text(
                                      'Ediofe (Arua)',
                                      style: TextStyle(
                                        fontFamily: 'Satoshi',
                                        fontSize: 12,
                                        fontWeight: FontWeight.bold,
                                        color: Colors.white,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),

                  // 4-Step Tracker
                  Row(
                    children: [
                      _trackerStep('Requested', true, true),
                      _trackerStep('Collected', false, false),
                      _trackerStep('Verifying', false, false),
                      _trackerStep('Settled', false, false, isLast: true),
                    ],
                  ),
                  const Divider(height: 28, color: Color(0xFFF0F4F1)),

                  const Text(
                    'Order Snapshot',
                    style: TextStyle(fontFamily: 'Satoshi', fontSize: 12, fontWeight: FontWeight.bold, color: Color(0xFF6B8073)),
                  ),
                  const SizedBox(height: 4),
                  const Text(
                    '1 Sack • Trading Center',
                    style: TextStyle(fontFamily: 'Satoshi', fontSize: 14.5, fontWeight: FontWeight.w800, color: Color(0xFF0D2618)),
                  ),
                  const SizedBox(height: 2),
                  const Text(
                    '2,500 UGX • Pay on Collection',
                    style: TextStyle(fontFamily: 'Satoshi', fontSize: 13, color: Color(0xFF1A3A28)),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),

            // Quick Utility (Weather)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: const Color(0xFFE0E5E1)),
              ),
              child: const Row(
                children: [
                  Icon(Icons.wb_sunny_outlined, color: Color(0xFFE67E22), size: 22),
                  SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      'Live Weather: Favorable • 20.3°C • Open-Meteo Arua',
                      style: TextStyle(
                        fontFamily: 'Satoshi',
                        fontSize: 13.5,
                        fontWeight: FontWeight.w600,
                        color: Color(0xFF0D2618),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  static Widget _trackerStep(String label, bool isDone, bool isCurrent, {bool isLast = false}) {
    return Expanded(
      child: Column(
        children: [
          Row(
            children: [
              Container(
                width: 18,
                height: 18,
                decoration: BoxDecoration(
                  color: isDone || isCurrent ? const Color(0xFF9C3D18) : const Color(0xFFD4DDD6),
                  shape: BoxShape.circle,
                ),
                child: isDone
                    ? const Icon(Icons.check, size: 12, color: Colors.white)
                    : null,
              ),
              if (!isLast)
                Expanded(
                  child: Container(
                    height: 2,
                    color: isDone ? const Color(0xFF9C3D18) : const Color(0xFFD4DDD6),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 6),
          Align(
            alignment: Alignment.centerLeft,
            child: Text(
              label,
              style: TextStyle(
                fontFamily: 'Satoshi',
                fontSize: 10.5,
                fontWeight: isCurrent ? FontWeight.bold : FontWeight.w500,
                color: isCurrent ? const Color(0xFF9C3D18) : const Color(0xFF6B8073),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class ResidentRequestsScreen extends StatelessWidget {
  const ResidentRequestsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFE8ECE7),
      appBar: AppBar(
        title: const Text('My Requests', style: TextStyle(fontWeight: FontWeight.w900)),
      ),
      body: ListView(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
        children: [
          _requestCard('Pickup #251985', '1 Sack • Ediofe, Trading Center', 'Dispatched', '2,500 UGX', true),
          const SizedBox(height: 12),
          _requestCard('Pickup #251986', '2 Sacks • Arua Hill Residential', 'Scheduled', '5,000 UGX', false),
          const SizedBox(height: 12),
          _requestCard('Pickup #251984', '1 Sack • River Oli Sector', 'Completed', '2,500 UGX', false, isDone: true),
        ],
      ),
    );
  }

  static Widget _requestCard(String title, String subtitle, String status, String price, bool isDispatched, {bool isDone = false}) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE0E5E1)),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text(
                      title,
                      style: const TextStyle(fontFamily: 'Satoshi', fontSize: 14.5, fontWeight: FontWeight.w800, color: Color(0xFF0D2618)),
                    ),
                    const SizedBox(width: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                      decoration: BoxDecoration(
                        color: isDone ? const Color(0xFFE4F0E7) : (isDispatched ? const Color(0xFFFEF3D6) : const Color(0xFFE8ECE7)),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(
                        status,
                        style: TextStyle(
                          fontFamily: 'Satoshi',
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                          color: isDone ? const Color(0xFF1E5E35) : (isDispatched ? const Color(0xFF915900) : const Color(0xFF1A3A28)),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Text(subtitle, style: const TextStyle(fontFamily: 'Satoshi', fontSize: 12.5, color: Color(0xFF6B8073))),
              ],
            ),
          ),
          Text(
            price,
            style: const TextStyle(fontFamily: 'Satoshi', fontSize: 14, fontWeight: FontWeight.w900, color: Color(0xFF9C3D18)),
          ),
        ],
      ),
    );
  }
}

class ResidentSupportScreen extends StatelessWidget {
  const ResidentSupportScreen({super.key});

  Future<void> _makeCall(String phone) async {
    final uri = Uri.parse('tel:$phone');
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFE8ECE7),
      appBar: AppBar(
        title: const Text('Support Center', style: TextStyle(fontWeight: FontWeight.w900)),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            TextField(
              decoration: InputDecoration(
                hintText: 'Search FAQs or topics...',
                prefixIcon: const Icon(Icons.search, color: Color(0xFF1A3A28)),
                filled: true,
                fillColor: Colors.white,
                contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: BorderSide.none),
              ),
            ),
            const SizedBox(height: 20),

            const Text(
              'Quick Help Cards',
              style: TextStyle(fontFamily: 'Satoshi', fontSize: 14, fontWeight: FontWeight.w800, color: Color(0xFF0D2618)),
            ),
            const SizedBox(height: 10),
            Row(
              children: [
                _quickCard('Missed\nPickup', Icons.local_shipping_outlined),
                const SizedBox(width: 10),
                _quickCard('Change\nBooking', Icons.calendar_today_outlined),
                const SizedBox(width: 10),
                _quickCard('Payment\nIssue', Icons.credit_card_outlined),
              ],
            ),
            const SizedBox(height: 24),

            const Text(
              'Direct Contact',
              style: TextStyle(fontFamily: 'Satoshi', fontSize: 14, fontWeight: FontWeight.w800, color: Color(0xFF0D2618)),
            ),
            const SizedBox(height: 10),
            ElevatedButton.icon(
              onPressed: () {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Connected to Arua Dispatch Live Chat.'), backgroundColor: Color(0xFF0D2618)),
                );
              },
              icon: const Icon(Icons.chat_bubble_outline_rounded, color: Colors.white, size: 18),
              label: const Text('Chat with Dispatch', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF0D2618),
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
              ),
            ),
            const SizedBox(height: 10),
            OutlinedButton.icon(
              onPressed: () => _makeCall('+256701234567'),
              icon: const Icon(Icons.phone_outlined, color: Color(0xFF9C3D18), size: 18),
              label: const Text('Call Arua Fleet Ops', style: TextStyle(color: Color(0xFF9C3D18), fontWeight: FontWeight.bold)),
              style: OutlinedButton.styleFrom(
                side: const BorderSide(color: Color(0xFF9C3D18)),
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
              ),
            ),
            const SizedBox(height: 24),

            const Text(
              'General FAQs',
              style: TextStyle(fontFamily: 'Satoshi', fontSize: 14, fontWeight: FontWeight.w800, color: Color(0xFF0D2618)),
            ),
            const SizedBox(height: 10),
            Container(
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: const Color(0xFFE0E5E1)),
              ),
              child: const Column(
                children: [
                  ExpansionTile(
                    title: Text('How to prepare waste?', style: TextStyle(fontFamily: 'Satoshi', fontSize: 13.5, fontWeight: FontWeight.w700)),
                    children: [Padding(padding: EdgeInsets.fromLTRB(16, 0, 16, 12), child: Text('Tie sacks securely and separate recyclables from organic kitchen waste.', style: TextStyle(fontSize: 12.5, color: Color(0xFF6B8073))))],
                  ),
                  Divider(height: 1, color: Color(0xFFF0F4F1)),
                  ExpansionTile(
                    title: Text('Accepted materials?', style: TextStyle(fontFamily: 'Satoshi', fontSize: 13.5, fontWeight: FontWeight.w700)),
                    children: [Padding(padding: EdgeInsets.fromLTRB(16, 0, 16, 12), child: Text('Household plastics, paper, bio-waste, packaging, and commercial bulk sacks.', style: TextStyle(fontSize: 12.5, color: Color(0xFF6B8073))))],
                  ),
                  Divider(height: 1, color: Color(0xFFF0F4F1)),
                  ExpansionTile(
                    title: Text('Operating service hours?', style: TextStyle(fontFamily: 'Satoshi', fontSize: 13.5, fontWeight: FontWeight.w700)),
                    children: [Padding(padding: EdgeInsets.fromLTRB(16, 0, 16, 12), child: Text('Monday to Saturday from 07:00 AM to 06:00 PM throughout Arua municipality.', style: TextStyle(fontSize: 12.5, color: Color(0xFF6B8073))))],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  static Widget _quickCard(String label, IconData icon) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 8),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: const Color(0xFFE0E5E1)),
        ),
        child: Column(
          children: [
            Icon(icon, color: const Color(0xFF9C3D18), size: 24),
            const SizedBox(height: 8),
            Text(
              label,
              textAlign: TextAlign.center,
              style: const TextStyle(fontFamily: 'Satoshi', fontSize: 12, fontWeight: FontWeight.w700, color: Color(0xFF0D2618)),
            ),
          ],
        ),
      ),
    );
  }
}

// =================================================================
// 3. RIDER ACCOUNT (Tasks, Route, Earnings)
// =================================================================

class RiderRootScreen extends StatefulWidget {
  const RiderRootScreen({super.key});

  @override
  State<RiderRootScreen> createState() => _RiderRootScreenState();
}

class _RiderRootScreenState extends State<RiderRootScreen> {
  int _currentIndex = 0;

  final List<Widget> _screens = const [
    RiderTasksScreen(),
    RiderRouteScreen(),
    RiderEarningsScreen(),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFE8ECE7),
      body: _screens[_currentIndex],
      bottomNavigationBar: Container(
        decoration: const BoxDecoration(
          color: Colors.white,
          border: Border(top: BorderSide(color: Color(0xFFE0E5E1), width: 1)),
        ),
        child: BottomNavigationBar(
          currentIndex: _currentIndex,
          selectedItemColor: const Color(0xFF9C3D18),
          unselectedItemColor: const Color(0xFF1A3A28),
          backgroundColor: Colors.white,
          elevation: 0,
          type: BottomNavigationBarType.fixed,
          selectedLabelStyle: const TextStyle(fontFamily: 'Satoshi', fontWeight: FontWeight.bold, fontSize: 12),
          unselectedLabelStyle: const TextStyle(fontFamily: 'Satoshi', fontWeight: FontWeight.w600, fontSize: 12),
          onTap: (index) {
            HapticFeedback.selectionClick();
            setState(() => _currentIndex = index);
          },
          items: const [
            BottomNavigationBarItem(icon: Icon(Icons.check_box_outlined), label: 'Tasks'),
            BottomNavigationBarItem(icon: Icon(Icons.alt_route_rounded), label: 'Route'),
            BottomNavigationBarItem(icon: Icon(Icons.attach_money_rounded), label: 'Earnings'),
          ],
        ),
      ),
    );
  }
}

class RiderTasksScreen extends StatefulWidget {
  const RiderTasksScreen({super.key});

  @override
  State<RiderTasksScreen> createState() => _RiderTasksScreenState();
}

class _RiderTasksScreenState extends State<RiderTasksScreen> {
  bool _collected = false;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFE8ECE7),
      appBar: AppBar(
        title: const Row(
          children: [
            Icon(Icons.eco, color: Color(0xFF0D2618), size: 24),
            SizedBox(width: 8),
            Text('EcoRoute Rider', style: TextStyle(fontWeight: FontWeight.w900)),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout_rounded),
            tooltip: 'Sign Out',
            onPressed: () => Navigator.pushReplacementNamed(context, '/login'),
          ),
          const SizedBox(width: 4),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    Text('Hello, Rider • Arua City', style: TextStyle(fontFamily: 'Satoshi', fontSize: 16, fontWeight: FontWeight.w700, color: Color(0xFF0D2618))),
                    SizedBox(width: 8),
                    Icon(Icons.circle, color: Color(0xFF22C55E), size: 10),
                  ],
                ),
                Text('Tricycle #04', style: TextStyle(fontFamily: 'Satoshi', fontSize: 12, fontWeight: FontWeight.bold, color: Color(0xFF1A3A28))),
              ],
            ),
            const SizedBox(height: 16),

            // Start Shift button
            ElevatedButton(
              onPressed: () {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Shift logged. GPS beacon active.'), backgroundColor: Color(0xFF0D2618)),
                );
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF0D2618),
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
              ),
              child: const Text('+ Start Next Shift', style: TextStyle(color: Colors.white, fontSize: 15, fontWeight: FontWeight.bold)),
            ),
            const SizedBox(height: 20),

            // Active Task Card
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: const Color(0xFFE0E5E1)),
                boxShadow: const [
                  BoxShadow(color: Color(0x0A000000), blurRadius: 10, offset: Offset(0, 4)),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        'Active Pickup #251985',
                        style: TextStyle(fontFamily: 'Satoshi', fontSize: 16, fontWeight: FontWeight.w900, color: Color(0xFF9C3D18)),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                        decoration: BoxDecoration(
                          color: _collected ? const Color(0xFFE4F0E7) : const Color(0xFFF9EAE1),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Text(
                          _collected ? 'Collected' : 'Pending',
                          style: TextStyle(
                            fontFamily: 'Satoshi',
                            fontSize: 11,
                            fontWeight: FontWeight.bold,
                            color: _collected ? const Color(0xFF1E5E35) : const Color(0xFF9C3D18),
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  const Text('Client: Jane A.', style: TextStyle(fontFamily: 'Satoshi', fontSize: 14, fontWeight: FontWeight.bold, color: Color(0xFF0D2618))),
                  const Text('Address: Ediofe, Trading Center (6FG8287F+W2)', style: TextStyle(fontFamily: 'Satoshi', fontSize: 12.5, color: Color(0xFF6B8073))),
                  const SizedBox(height: 12),

                  Row(
                    children: [
                      Expanded(
                        child: Container(
                          padding: const EdgeInsets.all(10),
                          decoration: BoxDecoration(color: const Color(0xFFE8ECE7), borderRadius: BorderRadius.circular(10)),
                          child: const Text('📦 1 sack', style: TextStyle(fontFamily: 'Satoshi', fontWeight: FontWeight.bold, fontSize: 13)),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Container(
                          padding: const EdgeInsets.all(10),
                          decoration: BoxDecoration(color: const Color(0xFFE8ECE7), borderRadius: BorderRadius.circular(10)),
                          child: const Text('💰 2,500 UGX Cash', style: TextStyle(fontFamily: 'Satoshi', fontWeight: FontWeight.bold, fontSize: 13)),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  const Text('📍 Distance: 4.1 km  •  ⏱️ Est. Time: 15 min', style: TextStyle(fontFamily: 'Satoshi', fontSize: 12, color: Color(0xFF6B8073))),
                  const SizedBox(height: 16),

                  Row(
                    children: [
                      Expanded(
                        flex: 4,
                        child: OutlinedButton(
                          onPressed: () {},
                          style: OutlinedButton.styleFrom(
                            side: const BorderSide(color: Color(0xFF0D2618)),
                            padding: const EdgeInsets.symmetric(vertical: 12),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                          ),
                          child: const Text('Call Client', style: TextStyle(color: Color(0xFF0D2618), fontWeight: FontWeight.bold)),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        flex: 6,
                        child: ElevatedButton(
                          onPressed: () {
                            HapticFeedback.heavyImpact();
                            setState(() => _collected = !_collected);
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: _collected ? const Color(0xFF1E5E35) : const Color(0xFF0D2618),
                            padding: const EdgeInsets.symmetric(vertical: 12),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                          ),
                          child: Text(
                            _collected ? 'Collected ✓' : 'Mark as Collected',
                            style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),

            const Text('Upcoming Tasks (5)', style: TextStyle(fontFamily: 'Satoshi', fontSize: 14.5, fontWeight: FontWeight.w800, color: Color(0xFF0D2618))),
            const SizedBox(height: 10),
            _taskItem('Pickup #251986', 'John B. • Arua Hill, Avenue 4', '2 sacks', '5,000 UGX'),
            const SizedBox(height: 8),
            _taskItem('Drop-off #251985', 'West Nile Segregation Depot', '1 sack', 'Internal Depot'),
          ],
        ),
      ),
    );
  }

  static Widget _taskItem(String title, String subtitle, String sacks, String pay) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFFE0E5E1)),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(title, style: const TextStyle(fontFamily: 'Satoshi', fontSize: 13.5, fontWeight: FontWeight.w800, color: Color(0xFF0D2618))),
              const SizedBox(height: 2),
              Text(subtitle, style: const TextStyle(fontFamily: 'Satoshi', fontSize: 12, color: Color(0xFF6B8073))),
            ],
          ),
          Text('$sacks • $pay', style: const TextStyle(fontFamily: 'Satoshi', fontSize: 12, fontWeight: FontWeight.bold, color: Color(0xFF1A3A28))),
        ],
      ),
    );
  }
}

class RiderRouteScreen extends StatelessWidget {
  const RiderRouteScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFE8ECE7),
      appBar: AppBar(
        title: const Text('My Route', style: TextStyle(fontWeight: FontWeight.w900)),
      ),
      body: Column(
        children: [
          Expanded(
            flex: 5,
            child: Container(
              margin: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: const Color(0xFFD4DDD6)),
              ),
              child: Stack(
                children: [
                  CustomPaint(
                    size: const Size(double.infinity, double.infinity),
                    painter: _MapRoadsPainter(),
                  ),
                  const Center(
                    child: Text(
                      'Turn-by-Turn Route Preview\nArua Center → Ediofe → Arua Hill',
                      textAlign: TextAlign.center,
                      style: TextStyle(fontFamily: 'Satoshi', fontWeight: FontWeight.w800, color: Color(0xFF0D2618)),
                    ),
                  ),
                ],
              ),
            ),
          ),
          Expanded(
            flex: 5,
            child: Container(
              color: Colors.white,
              padding: const EdgeInsets.all(16),
              child: ListView(
                children: const [
                  Text('Route Stops Sequence', style: TextStyle(fontFamily: 'Satoshi', fontSize: 14, fontWeight: FontWeight.w900, color: Color(0xFF0D2618))),
                  SizedBox(height: 12),
                  ListTile(leading: CircleAvatar(radius: 12, backgroundColor: Color(0xFF0D2618), child: Text('1', style: TextStyle(color: Colors.white, fontSize: 12))), title: Text('Arua Center Market Depot'), subtitle: Text('Start point • 08:00 AM')),
                  ListTile(leading: CircleAvatar(radius: 12, backgroundColor: Color(0xFF9C3D18), child: Text('2', style: TextStyle(color: Colors.white, fontSize: 12))), title: Text('Ediofe Trading Center (Jane A.)'), subtitle: Text('1 sack • Active Stop')),
                  ListTile(leading: CircleAvatar(radius: 12, backgroundColor: Color(0xFF1A3A28), child: Text('3', style: TextStyle(color: Colors.white, fontSize: 12))), title: Text('Arua Hill Avenue 4 (John B.)'), subtitle: Text('2 sacks • Next Stop')),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class RiderEarningsScreen extends StatelessWidget {
  const RiderEarningsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFE8ECE7),
      appBar: AppBar(
        title: const Text('My Earnings', style: TextStyle(fontWeight: FontWeight.w900)),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Balance Card
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 22),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: const Color(0xFFE0E5E1)),
                boxShadow: const [
                  BoxShadow(color: Color(0x0A000000), blurRadius: 10, offset: Offset(0, 4)),
                ],
              ),
              child: Column(
                children: [
                  const Text('Total Balance', style: TextStyle(fontFamily: 'Satoshi', fontSize: 13, color: Color(0xFF6B8073))),
                  const SizedBox(height: 6),
                  const Text('54,350 UGX', style: TextStyle(fontFamily: 'Satoshi', fontSize: 32, fontWeight: FontWeight.w900, color: Color(0xFF0D2618))),
                  const SizedBox(height: 4),
                  const Text('Last Payout: 48,000 UGX (3 days ago)', style: TextStyle(fontFamily: 'Satoshi', fontSize: 12, color: Color(0xFF8A9B8F))),
                  const SizedBox(height: 18),
                  ElevatedButton(
                    onPressed: () {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Payout requested. Transfer queued for MTN MoMo.'), backgroundColor: Color(0xFF0D2618)),
                      );
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF0D2618),
                      minimumSize: const Size(double.infinity, 46),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                    child: const Text('Request Payout', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),

            const Text('Today', style: TextStyle(fontFamily: 'Satoshi', fontSize: 14, fontWeight: FontWeight.w800, color: Color(0xFF0D2618))),
            const SizedBox(height: 8),
            _earningRow('Pickup #251985', 'Jane A. • 07:35 AM', '2,500 UGX'),
            const SizedBox(height: 8),
            _earningRow('Pickup #251986', 'John B. • 07:35 AM', '5,000 UGX'),
            const SizedBox(height: 8),
            _earningRow('Batch Bonus: +3 Pickups', 'Bonus incentive', '1,500 UGX', isBonus: true),
            const SizedBox(height: 20),

            const Text('Yesterday', style: TextStyle(fontFamily: 'Satoshi', fontSize: 14, fontWeight: FontWeight.w800, color: Color(0xFF0D2618))),
            const SizedBox(height: 10),
            Container(
              height: 120,
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: const Color(0xFFE0E5E1)),
              ),
              child: CustomPaint(
                size: const Size(double.infinity, 120),
                painter: _WeeklyCollectionsPainter(),
              ),
            ),
          ],
        ),
      ),
    );
  }

  static Widget _earningRow(String title, String subtitle, String amount, {bool isBonus = false}) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFFE0E5E1)),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(title, style: TextStyle(fontFamily: 'Satoshi', fontSize: 13.5, fontWeight: FontWeight.w800, color: isBonus ? const Color(0xFF0D2618) : const Color(0xFF9C3D18))),
              const SizedBox(height: 2),
              Text(subtitle, style: const TextStyle(fontFamily: 'Satoshi', fontSize: 11.5, color: Color(0xFF6B8073))),
            ],
          ),
          Text(amount, style: const TextStyle(fontFamily: 'Satoshi', fontSize: 13.5, fontWeight: FontWeight.bold, color: Color(0xFF0D2618))),
        ],
      ),
    );
  }
}

// =================================================================
// 4. ADMIN ACCOUNT (Dashboard, Fleet, Reports)
// =================================================================

class AdminRootScreen extends StatefulWidget {
  const AdminRootScreen({super.key});

  @override
  State<AdminRootScreen> createState() => _AdminRootScreenState();
}

class _AdminRootScreenState extends State<AdminRootScreen> {
  int _currentIndex = 0;

  final List<Widget> _screens = const [
    AdminDashboardScreen(),
    AdminFleetScreen(),
    AdminReportsScreen(),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFE8ECE7),
      body: _screens[_currentIndex],
      bottomNavigationBar: Container(
        decoration: const BoxDecoration(
          color: Colors.white,
          border: Border(top: BorderSide(color: Color(0xFFE0E5E1), width: 1)),
        ),
        child: BottomNavigationBar(
          currentIndex: _currentIndex,
          selectedItemColor: const Color(0xFF9C3D18),
          unselectedItemColor: const Color(0xFF1A3A28),
          backgroundColor: Colors.white,
          elevation: 0,
          type: BottomNavigationBarType.fixed,
          selectedLabelStyle: const TextStyle(fontFamily: 'Satoshi', fontWeight: FontWeight.bold, fontSize: 12),
          unselectedLabelStyle: const TextStyle(fontFamily: 'Satoshi', fontWeight: FontWeight.w600, fontSize: 12),
          onTap: (index) {
            HapticFeedback.selectionClick();
            setState(() => _currentIndex = index);
          },
          items: const [
            BottomNavigationBarItem(icon: Icon(Icons.dashboard_rounded), label: 'Dashboard'),
            BottomNavigationBarItem(icon: Icon(Icons.directions_car_rounded), label: 'Fleet'),
            BottomNavigationBarItem(icon: Icon(Icons.bar_chart_rounded), label: 'Reports'),
          ],
        ),
      ),
    );
  }
}

class AdminDashboardScreen extends StatelessWidget {
  const AdminDashboardScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFE8ECE7),
      appBar: AppBar(
        title: const Text('Admin Hub • Arua City HQ', style: TextStyle(fontWeight: FontWeight.w900)),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout_rounded),
            tooltip: 'Sign Out',
            onPressed: () => Navigator.pushReplacementNamed(context, '/login'),
          ),
          const SizedBox(width: 4),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Row(
              children: [
                Text('All Systems Nominal', style: TextStyle(fontFamily: 'Satoshi', fontSize: 15, fontWeight: FontWeight.w800, color: Color(0xFF0D2618))),
                SizedBox(width: 8),
                Icon(Icons.circle, color: Color(0xFF22C55E), size: 10),
              ],
            ),
            const SizedBox(height: 12),

            // Operational Overview (3 Metrics)
            Container(
              padding: const EdgeInsets.all(18),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: const Color(0xFFE0E5E1)),
                boxShadow: const [
                  BoxShadow(color: Color(0x0A000000), blurRadius: 10, offset: Offset(0, 4)),
                ],
              ),
              child: const Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  Column(
                    children: [
                      Text('18', style: TextStyle(fontFamily: 'Satoshi', fontSize: 24, fontWeight: FontWeight.w900, color: Color(0xFF0D2618))),
                      SizedBox(height: 2),
                      Text('Active Riders', style: TextStyle(fontFamily: 'Satoshi', fontSize: 12, color: Color(0xFF6B8073))),
                    ],
                  ),
                  Column(
                    children: [
                      Text('5', style: TextStyle(fontFamily: 'Satoshi', fontSize: 24, fontWeight: FontWeight.w900, color: Color(0xFF0D2618))),
                      SizedBox(height: 2),
                      Text('Pending', style: TextStyle(fontFamily: 'Satoshi', fontSize: 12, color: Color(0xFF6B8073))),
                    ],
                  ),
                  Column(
                    children: [
                      Text('98%', style: TextStyle(fontFamily: 'Satoshi', fontSize: 24, fontWeight: FontWeight.w900, color: Color(0xFF22C55E))),
                      SizedBox(height: 2),
                      Text('Efficiency', style: TextStyle(fontFamily: 'Satoshi', fontSize: 12, color: Color(0xFF6B8073))),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),

            // Live Fleet Map
            const Text('Live Fleet Map Preview (Arua)', style: TextStyle(fontFamily: 'Satoshi', fontSize: 14.5, fontWeight: FontWeight.w800, color: Color(0xFF0D2618))),
            const SizedBox(height: 10),
            Container(
              height: 180,
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: const Color(0xFFE0E5E1)),
              ),
              child: Stack(
                children: [
                  CustomPaint(
                    size: const Size(double.infinity, 180),
                    painter: _MapRoadsPainter(),
                  ),
                  const Center(
                    child: Text(
                      'Live Dispatch Map\n18 Active Tricycle Beacons',
                      textAlign: TextAlign.center,
                      style: TextStyle(fontFamily: 'Satoshi', fontWeight: FontWeight.w800, color: Color(0xFF0D2618)),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),

            // Quick Actions
            const Text('Quick Actions', style: TextStyle(fontFamily: 'Satoshi', fontSize: 14.5, fontWeight: FontWeight.w800, color: Color(0xFF0D2618))),
            const SizedBox(height: 10),
            Row(
              children: [
                _actionCard('Assign New\nTask', Icons.calendar_today_rounded),
                const SizedBox(width: 10),
                _actionCard('Broadcast\nAlert', Icons.campaign_rounded),
                const SizedBox(width: 10),
                _actionCard('Generate\nReport', Icons.bar_chart_rounded),
              ],
            ),
          ],
        ),
      ),
    );
  }

  static Widget _actionCard(String title, IconData icon) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 8),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: const Color(0xFFE0E5E1)),
        ),
        child: Column(
          children: [
            Icon(icon, color: const Color(0xFF0D2618), size: 24),
            const SizedBox(height: 8),
            Text(
              title,
              textAlign: TextAlign.center,
              style: const TextStyle(fontFamily: 'Satoshi', fontSize: 12, fontWeight: FontWeight.w700, color: Color(0xFF0D2618)),
            ),
          ],
        ),
      ),
    );
  }
}

class AdminFleetScreen extends StatelessWidget {
  const AdminFleetScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFE8ECE7),
      appBar: AppBar(
        title: const Text('Fleet Tracking', style: TextStyle(fontWeight: FontWeight.w900)),
      ),
      body: Column(
        children: [
          Expanded(
            flex: 6,
            child: Container(
              margin: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: const Color(0xFFD4DDD6)),
              ),
              child: Stack(
                children: [
                  CustomPaint(
                    size: const Size(double.infinity, double.infinity),
                    painter: _MapRoadsPainter(),
                  ),
                  const Center(
                    child: Text(
                      'Live Central Map View for Fleet Management\n(18 Units Connected)',
                      textAlign: TextAlign.center,
                      style: TextStyle(fontFamily: 'Satoshi', fontWeight: FontWeight.w800, color: Color(0xFF0D2618)),
                    ),
                  ),
                ],
              ),
            ),
          ),
          Expanded(
            flex: 4,
            child: Container(
              color: Colors.white,
              padding: const EdgeInsets.all(16),
              child: ListView(
                children: const [
                  Text('Field Units (Arua Municipality)', style: TextStyle(fontFamily: 'Satoshi', fontSize: 14, fontWeight: FontWeight.w900, color: Color(0xFF0D2618))),
                  SizedBox(height: 10),
                  ListTile(leading: Icon(Icons.two_wheeler, color: Color(0xFF0D2618)), title: Text('Tricycle #04 • Jane A.'), subtitle: Text('Ediofe Corridor • Active Collection'), trailing: Text('85% Bat', style: TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF1E5E35)))),
                  ListTile(leading: Icon(Icons.two_wheeler, color: Color(0xFF0D2618)), title: Text('Tricycle #07 • Rashid K.'), subtitle: Text('Arua Hill Sector • En Route Hub'), trailing: Text('92% Bat', style: TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF1E5E35)))),
                  ListTile(leading: Icon(Icons.two_wheeler, color: Color(0xFF6B8073)), title: Text('Tricycle #11 • Sam O.'), subtitle: Text('River Oli Central • Standby'), trailing: Text('78% Bat', style: TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF6B8073)))),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// 09_ADMIN_REPORTS: Analytics & Reports Matching the Exact Approved Mockup in Image 2
class AdminReportsScreen extends StatelessWidget {
  const AdminReportsScreen({super.key});

  Future<void> _downloadPdf(BuildContext context, String title, String period) async {
    HapticFeedback.mediumImpact();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Generating $title ($period)...'),
        backgroundColor: const Color(0xFF0D2618),
      ),
    );
    try {
      await PdfReportService.printOrShareReport(title: title, period: period);
    } catch (_) {}
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFE8ECE7),
      appBar: AppBar(
        title: const Row(
          children: [
            Icon(Icons.eco, color: Color(0xFF0D2618), size: 24),
            SizedBox(width: 8),
            Text('EcoRoute', style: TextStyle(fontWeight: FontWeight.w900)),
          ],
        ),
        actions: const [
          Row(
            children: [
              Icon(Icons.circle, color: Color(0xFF22C55E), size: 8),
              SizedBox(width: 4),
              Text(
                'Arua City HQ',
                style: TextStyle(
                  fontFamily: 'Satoshi',
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF1A3A28),
                ),
              ),
              SizedBox(width: 8),
              CircleAvatar(
                radius: 14,
                backgroundColor: Color(0xFF0D2618),
                child: Icon(Icons.person, color: Colors.white, size: 16),
              ),
              SizedBox(width: 16),
            ],
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Text(
              'Admin Analytics',
              style: TextStyle(
                fontFamily: 'Satoshi',
                fontSize: 24,
                fontWeight: FontWeight.w900,
                color: Color(0xFF0D2618),
                letterSpacing: -0.5,
              ),
            ),
            const SizedBox(height: 14),

            // Search & Filter Bar
            Row(
              children: [
                Expanded(
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 14),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: const Color(0xFFD4DDD6)),
                    ),
                    child: const Row(
                      children: [
                        Icon(Icons.search, size: 18, color: Color(0xFF6B8073)),
                        SizedBox(width: 8),
                        Expanded(
                          child: TextField(
                            decoration: InputDecoration(
                              hintText: 'Search reports and metrics...',
                              hintStyle: TextStyle(fontFamily: 'Satoshi', fontSize: 13, color: Color(0xFF8A9B8F)),
                              border: InputBorder.none,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                OutlinedButton(
                  onPressed: () {},
                  style: OutlinedButton.styleFrom(
                    foregroundColor: const Color(0xFF0D2618),
                    side: const BorderSide(color: Color(0xFF0D2618)),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                  ),
                  child: const Text('Filter', style: TextStyle(fontFamily: 'Satoshi', fontWeight: FontWeight.bold)),
                ),
              ],
            ),
            const SizedBox(height: 20),

            // Card 1: Operations Overview (Exact Image 2)
            Container(
              padding: const EdgeInsets.all(18),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(18),
                boxShadow: const [
                  BoxShadow(color: Color(0x0A000000), blurRadius: 10, offset: Offset(0, 4)),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Operations Overview',
                        style: TextStyle(
                          fontFamily: 'Satoshi',
                          fontSize: 15,
                          fontWeight: FontWeight.w800,
                          color: Color(0xFF0D2618),
                        ),
                      ),
                      Icon(Icons.more_horiz, color: Color(0xFF6B8073)),
                    ],
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    'Total Waste Collected:',
                    style: TextStyle(fontFamily: 'Satoshi', fontSize: 12, color: Color(0xFF6B8073)),
                  ),
                  const SizedBox(height: 2),
                  Row(
                    children: [
                      const Text(
                        '14.5 Tonnes',
                        style: TextStyle(
                          fontFamily: 'Satoshi',
                          fontSize: 24,
                          fontWeight: FontWeight.w900,
                          color: Color(0xFF0D2618),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                        decoration: BoxDecoration(
                          color: const Color(0xFFB85D19),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: const Text(
                          '+12%',
                          style: TextStyle(
                            fontFamily: 'Satoshi',
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 18),

                  // Smooth Trendline Graphic with Marked Points
                  SizedBox(
                    height: 100,
                    width: double.infinity,
                    child: CustomPaint(
                      painter: _LineChartPainter(),
                    ),
                  ),
                  const SizedBox(height: 8),
                  const Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text('Day', style: TextStyle(fontSize: 10, color: Color(0xFF8A9B8F))),
                      Text('#17', style: TextStyle(fontSize: 10, color: Color(0xFF8A9B8F))),
                      Text('#10', style: TextStyle(fontSize: 10, color: Color(0xFF8A9B8F))),
                      Text('Mon', style: TextStyle(fontSize: 10, color: Color(0xFF8A9B8F))),
                      Text('220', style: TextStyle(fontSize: 10, color: Color(0xFF8A9B8F))),
                      Text('310', style: TextStyle(fontSize: 10, color: Color(0xFF8A9B8F))),
                      Text('Mon', style: TextStyle(fontSize: 10, color: Color(0xFF8A9B8F))),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),

            // Card 2: Key Metrics (2x2 Grid)
            const Text(
              'Key Metrics',
              style: TextStyle(fontFamily: 'Satoshi', fontSize: 15, fontWeight: FontWeight.w800, color: Color(0xFF0D2618)),
            ),
            const SizedBox(height: 10),
            Row(
              children: [
                Expanded(child: _metricCard('Active Riders:', '18', Icons.person_outline)),
                const SizedBox(width: 10),
                Expanded(child: _metricCard('Pending Pickups:', '5', Icons.schedule)),
              ],
            ),
            const SizedBox(height: 10),
            Row(
              children: [
                Expanded(child: _metricCard('Completed Today:', '42', Icons.check_circle_outline)),
                const SizedBox(width: 10),
                Expanded(
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
                    decoration: BoxDecoration(
                      color: const Color(0xFFB85D19),
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: const Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          'SLA Met: 98.5%',
                          style: TextStyle(
                            fontFamily: 'Satoshi',
                            fontSize: 13.5,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),

            // Card 3: Weekly Collections (Tonnes)
            Container(
              padding: const EdgeInsets.all(18),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(18),
                boxShadow: const [
                  BoxShadow(color: Color(0x0A000000), blurRadius: 10, offset: Offset(0, 4)),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        'Weekly Collections (Tonnes)',
                        style: TextStyle(fontFamily: 'Satoshi', fontSize: 14.5, fontWeight: FontWeight.w800, color: Color(0xFF0D2618)),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                        decoration: BoxDecoration(
                          color: const Color(0xFFE8ECE7),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: const Text('Avg: 2.1T/day', style: TextStyle(fontFamily: 'Satoshi', fontSize: 11, fontWeight: FontWeight.bold, color: Color(0xFF1A3A28))),
                      ),
                    ],
                  ),
                  const SizedBox(height: 18),
                  SizedBox(
                    height: 110,
                    width: double.infinity,
                    child: CustomPaint(
                      painter: _WeeklyCollectionsPainter(),
                    ),
                  ),
                  const SizedBox(height: 8),
                  const Row(
                    mainAxisAlignment: MainAxisAlignment.spaceAround,
                    children: [
                      Text('Mon', style: TextStyle(fontSize: 10.5, fontWeight: FontWeight.w600, color: Color(0xFF6B8073))),
                      Text('Tue', style: TextStyle(fontSize: 10.5, fontWeight: FontWeight.w600, color: Color(0xFF6B8073))),
                      Text('Wed', style: TextStyle(fontSize: 10.5, fontWeight: FontWeight.w600, color: Color(0xFF6B8073))),
                      Text('Thu', style: TextStyle(fontSize: 10.5, fontWeight: FontWeight.w600, color: Color(0xFF6B8073))),
                      Text('Fri', style: TextStyle(fontSize: 10.5, fontWeight: FontWeight.w800, color: Color(0xFF0D2618))),
                      Text('Sat', style: TextStyle(fontSize: 10.5, fontWeight: FontWeight.w600, color: Color(0xFF6B8073))),
                      Text('Sun', style: TextStyle(fontSize: 10.5, fontWeight: FontWeight.w600, color: Color(0xFF6B8073))),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),

            // Card 4: Recent Reports
            Container(
              padding: const EdgeInsets.all(18),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(18),
                boxShadow: const [
                  BoxShadow(color: Color(0x0A000000), blurRadius: 10, offset: Offset(0, 4)),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Recent Reports',
                    style: TextStyle(fontFamily: 'Satoshi', fontSize: 14.5, fontWeight: FontWeight.w800, color: Color(0xFF0D2618)),
                  ),
                  const SizedBox(height: 14),
                  _reportDownloadRow(context, 'Daily Operations - Oct 31, 2026', () => _downloadPdf(context, 'Daily Operations Report', 'October 31, 2026')),
                  const SizedBox(height: 12),
                  _reportDownloadRow(context, 'Rider Efficiency - Oct 2026', () => _downloadPdf(context, 'Rider Efficiency Report', 'October 2026')),
                ],
              ),
            ),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }

  static Widget _metricCard(String label, String value, IconData icon) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFFE0E5E1)),
      ),
      child: Row(
        children: [
          Icon(icon, size: 20, color: const Color(0xFF0D2618)),
          const SizedBox(width: 8),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(label, style: const TextStyle(fontFamily: 'Satoshi', fontSize: 11, color: Color(0xFF6B8073))),
              Text(value, style: const TextStyle(fontFamily: 'Satoshi', fontSize: 15, fontWeight: FontWeight.w900, color: Color(0xFF0D2618))),
            ],
          ),
        ],
      ),
    );
  }

  static Widget _reportDownloadRow(BuildContext context, String title, VoidCallback onDownload) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Row(
          children: [
            Container(
              padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(
                color: const Color(0xFFE4F0E7),
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Icon(Icons.description_outlined, color: Color(0xFF1E5E35), size: 18),
            ),
            const SizedBox(width: 10),
            Text(
              title,
              style: const TextStyle(fontFamily: 'Satoshi', fontSize: 13, fontWeight: FontWeight.w700, color: Color(0xFF0D2618)),
            ),
          ],
        ),
        ElevatedButton(
          onPressed: onDownload,
          style: ElevatedButton.styleFrom(
            backgroundColor: const Color(0xFFB85D19),
            foregroundColor: Colors.white,
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
            minimumSize: Size.zero,
            tapTargetSize: MaterialTapTargetSize.shrinkWrap,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
            elevation: 0,
          ),
          child: const Text('Download PDF', style: TextStyle(fontFamily: 'Satoshi', fontSize: 11, fontWeight: FontWeight.bold)),
        ),
      ],
    );
  }
}

// =================================================================
// 5. CUSTOM PAINTERS (ZERO DEPENDENCY MAPS & CHARTS)
// =================================================================

class _MapRoadsPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final roadPaint = Paint()
      ..color = const Color(0xFFD4DDD6)
      ..strokeWidth = 3
      ..style = PaintingStyle.stroke;

    final routePaint = Paint()
      ..color = const Color(0xFF9C3D18)
      ..strokeWidth = 3.5
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;

    // Draw grid roads
    canvas.drawLine(Offset(0, size.height * 0.3), Offset(size.width, size.height * 0.4), roadPaint);
    canvas.drawLine(Offset(0, size.height * 0.7), Offset(size.width, size.height * 0.6), roadPaint);
    canvas.drawLine(Offset(size.width * 0.3, 0), Offset(size.width * 0.4, size.height), roadPaint);
    canvas.drawLine(Offset(size.width * 0.7, 0), Offset(size.width * 0.6, size.height), roadPaint);

    // Draw active route polyline
    final path = Path()
      ..moveTo(size.width * 0.2, size.height * 0.8)
      ..lineTo(size.width * 0.35, size.height * 0.45)
      ..lineTo(size.width * 0.5, size.height * 0.5)
      ..lineTo(size.width * 0.75, size.height * 0.25);
    canvas.drawPath(path, routePaint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class _LineChartPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;

    final linePaint = Paint()
      ..color = const Color(0xFF0D2618)
      ..strokeWidth = 2.8
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;

    final dotPaint = Paint()
      ..color = const Color(0xFFB85D19)
      ..style = PaintingStyle.fill;

    final whiteDotPaint = Paint()
      ..color = Colors.white
      ..style = PaintingStyle.fill;

    final path = Path()
      ..moveTo(0, h * 0.7)
      ..cubicTo(w * 0.15, h * 0.4, w * 0.25, h * 0.2, w * 0.35, h * 0.35)
      ..cubicTo(w * 0.45, h * 0.5, w * 0.55, h * 0.2, w * 0.65, h * 0.15)
      ..cubicTo(w * 0.75, h * 0.1, w * 0.85, h * 0.6, w, h * 0.2);

    // Gradient fill below curve
    final fillPath = Path.from(path)
      ..lineTo(w, h)
      ..lineTo(0, h)
      ..close();

    final fillPaint = Paint()
      ..shader = LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [
          const Color(0xFF0D2618).withValues(alpha: 0.18),
          const Color(0xFF0D2618).withValues(alpha: 0.0),
        ],
      ).createShader(Rect.fromLTWH(0, 0, w, h));

    canvas.drawPath(fillPath, fillPaint);
    canvas.drawPath(path, linePaint);

    // Draw highlighted points (matches Image 2)
    final points = [
      Offset(w * 0.35, h * 0.35),
      Offset(w * 0.65, h * 0.15),
      Offset(w * 0.75, h * 0.42),
    ];

    for (final p in points) {
      canvas.drawCircle(p, 5.5, whiteDotPaint);
      canvas.drawCircle(p, 4.0, dotPaint);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class _WeeklyCollectionsPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final barPaint = Paint()
      ..color = const Color(0xFF5A7C66)
      ..style = PaintingStyle.fill;

    final fridayPaint = Paint()
      ..color = const Color(0xFF0D2618)
      ..style = PaintingStyle.fill;

    final heights = [0.4, 0.6, 0.75, 0.65, 0.95, 0.7, 0.45];
    final barWidth = size.width / 11;
    final spacing = size.width / 7;

    for (var i = 0; i < heights.length; i++) {
      final x = (i * spacing) + (spacing - barWidth) / 2;
      final barH = size.height * heights[i];
      final y = size.height - barH;

      final rect = RRect.fromRectAndRadius(
        Rect.fromLTWH(x, y, barWidth, barH),
        const Radius.circular(4),
      );
      canvas.drawRRect(rect, i == 4 ? fridayPaint : barPaint);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
