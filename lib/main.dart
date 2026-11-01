import 'dart:async';
import 'package:flutter/material.dart';

void main() {
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
        scaffoldBackgroundColor: const Color(0xFFE8ECE7),
        primaryColor: const Color(0xFF0D2618),
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFF0D2618),
          surface: const Color(0xFFE8ECE7),
          primary: const Color(0xFF0D2618),
          secondary: const Color(0xFF9C3D18),
          onPrimary: Colors.white,
          onSecondary: Colors.white,
        ),
        fontFamily: 'Satoshi',
        textTheme: const TextTheme(
          displayLarge: TextStyle(color: Color(0xFF0D2618), fontWeight: FontWeight.bold, fontSize: 32),
          headlineMedium: TextStyle(color: Color(0xFF0D2618), fontWeight: FontWeight.bold, fontSize: 22),
          bodyLarge: TextStyle(color: Color(0xFF1A3A28), fontSize: 16),
          bodyMedium: TextStyle(color: Color(0xFF1A3A28), fontSize: 14),
        ),
        appBarTheme: const AppBarTheme(
          backgroundColor: Color(0xFFE8ECE7),
          elevation: 0,
          iconTheme: IconThemeData(color: Color(0xFF0D2618)),
          titleTextStyle: TextStyle(color: Color(0xFF0D2618), fontWeight: FontWeight.bold, fontSize: 20),
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
// 1. SPLASH SCREEN & INITIAL ENTRY
// =================================================================
class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(vsync: this, duration: const Duration(milliseconds: 800));
    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(_controller);
    _controller.forward();

    // Fade and transition to Authentication view
    Timer(const Duration(milliseconds: 2200), () {
      Navigator.pushReplacementNamed(context, '/login');
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: FadeTransition(
          opacity: _fadeAnimation,
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  color: const Color(0xFF0D2618),
                  borderRadius: BorderRadius.circular(24),
                ),
                child: const Icon(Icons.eco, color: Colors.white, size: 52),
              ),
              const SizedBox(height: 20),
              const Text(
                'EcoRoute',
                style: TextStyle(
                  fontSize: 36,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF0D2618),
                  letterSpacing: -0.5,
                ),
              ),
              const SizedBox(height: 8),
              const Text(
                'Arua City Waste Management',
                style: TextStyle(
                  fontSize: 14,
                  color: Color(0xFF1A3A28),
                  fontWeight: FontWeight.w600,
                  letterSpacing: 0.5,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// =================================================================
// 2. AUTHENTICATION (Bypasses manual role select, routes automatically)
// =================================================================
class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _isLoading = false;

  void _handleLogin() {
    if (_emailController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter an identifier (resident, rider, admin)')),
      );
      return;
    }

    setState(() => _isLoading = true);
    
    // Simulating secure network lookup and auto routing based on user input
    Future.delayed(const Duration(milliseconds: 1000), () {
      if (!mounted) return;
      setState(() => _isLoading = false);

      final email = _emailController.text.trim().toLowerCase();
      if (email.contains('admin')) {
        Navigator.pushReplacementNamed(context, '/admin');
      } else if (email.contains('rider')) {
        Navigator.pushReplacementNamed(context, '/rider');
      } else {
        Navigator.pushReplacementNamed(context, '/resident');
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 48.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const SizedBox(height: 40),
              const Center(
                child: CircleAvatar(
                  backgroundColor: Color(0xFF0D2618),
                  radius: 36,
                  child: Icon(Icons.eco, color: Colors.white, size: 36),
                ),
              ),
              const SizedBox(height: 24),
              const Text(
                'Welcome to EcoRoute',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold, color: Color(0xFF0D2618)),
              ),
              const SizedBox(height: 8),
              const Text(
                'Enter credentials to securely authenticate',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 14, color: Color(0xFF1A3A28)),
              ),
              const SizedBox(height: 48),
              TextField(
                key: const ValueKey('login_email_input'),
                controller: _emailController,
                style: const TextStyle(color: Color(0xFF0D2618)),
                decoration: InputDecoration(
                  labelText: 'Username or Email',
                  hintText: 'e.g., resident, rider, admin',
                  labelStyle: const TextStyle(color: Color(0xFF0D2618)),
                  filled: true,
                  fillColor: Colors.white,
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
                  prefixIcon: const Icon(Icons.person_outline, color: Color(0xFF0D2618)),
                ),
              ),
              const SizedBox(height: 16),
              TextField(
                key: const ValueKey('login_password_input'),
                controller: _passwordController,
                obscureText: true,
                style: const TextStyle(color: Color(0xFF0D2618)),
                decoration: InputDecoration(
                  labelText: 'Password',
                  labelStyle: const TextStyle(color: Color(0xFF0D2618)),
                  filled: true,
                  fillColor: Colors.white,
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
                  prefixIcon: const Icon(Icons.lock_outline, color: Color(0xFF0D2618)),
                ),
              ),
              const SizedBox(height: 24),
              _isLoading
                  ? const Center(child: CircularProgressIndicator(color: Color(0xFF0D2618)))
                  : ElevatedButton(
                      key: const ValueKey('login_submit_button'),
                      onPressed: _handleLogin,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF0D2618),
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                      child: const Text('Continue', style: TextStyle(fontSize: 16, color: Colors.white, fontWeight: FontWeight.bold)),
                    ),
            ],
          ),
        ),
      ),
    );
  }
}

// =================================================================
// 3. RESIDENT INTERACTIVE SUITE (Home, Requests, Support Center)
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
      body: IndexedStack(index: _currentIndex, children: _screens),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _currentIndex,
        selectedItemColor: const Color(0xFF9C3D18),
        unselectedItemColor: const Color(0xFF1A3A28),
        backgroundColor: Colors.white,
        type: BottomNavigationBarType.fixed,
        onTap: (index) => setState(() => _currentIndex = index),
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.home_filled), label: 'Home'),
          BottomNavigationBarItem(icon: Icon(Icons.receipt_long), label: 'Requests'),
          BottomNavigationBarItem(icon: Icon(Icons.contact_support), label: 'Support'),
        ],
      ),
    );
  }
}

class ResidentHomeScreen extends StatelessWidget {
  const ResidentHomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Row(
          children: const [
            Icon(Icons.eco, color: Color(0xFF0D2618)),
            SizedBox(width: 8),
            Text('EcoRoute', style: TextStyle(fontWeight: FontWeight.bold)),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () => Navigator.pushReplacementNamed(context, '/login'),
          )
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: const [
                Text('Hello, Resident • Arua City', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Color(0xFF0D2618))),
                SizedBox(width: 8),
                Icon(Icons.circle, color: Colors.green, size: 10),
              ],
            ),
            const SizedBox(height: 16),
            ElevatedButton.icon(
              onPressed: () {},
              icon: const Icon(Icons.add, color: Colors.white),
              label: const Text('Book a New Pickup', style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold)),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF0D2618),
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              ),
            ),
            const SizedBox(height: 20),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.04), blurRadius: 10, offset: const Offset(0, 4))],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Tricycle Rider Dispatched', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Color(0xFF0D2618))),
                  const SizedBox(height: 12),
                  Container(
                    height: 140,
                    decoration: BoxDecoration(
                      color: const Color(0xFFE8ECE7),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(12),
                      child: CustomPaint(
                        painter: AruaMapPainter(),
                        child: const Center(
                          child: Text('Map View: Arua Center ➔ Ediofe', style: TextStyle(color: Color(0xFF1A3A28), fontWeight: FontWeight.bold)),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  const ProgressStepper(),
                  const Divider(height: 32),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: const [
                          Text('Order Snapshot', style: TextStyle(fontSize: 11, color: Colors.grey, fontWeight: FontWeight.bold)),
                          SizedBox(height: 2),
                          Text('1 Sack • Trading Center', style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: Color(0xFF0D2618))),
                        ],
                      ),
                      const Text('2,500 UGX\nPay on Collection', textAlign: TextAlign.right, style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Color(0xFF9C3D18))),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
              decoration: BoxDecoration(color: const Color(0xFF1A3A28), borderRadius: BorderRadius.circular(12)),
              child: Row(
                children: const [
                  Icon(Icons.wb_sunny_outlined, color: Colors.amber, size: 20),
                  SizedBox(width: 12),
                  Text('Weather: Favorable • 20.3°C', style: TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.w500)),
                  Spacer(),
                  Text('Open-Meteo API (Offline)', style: TextStyle(color: Colors.white54, fontSize: 10)),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class ResidentRequestsScreen extends StatelessWidget {
  const ResidentRequestsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('My Requests')),
      body: ListView(
        padding: const EdgeInsets.all(16.0),
        children: [
          _buildRequestCard('Active Pickup #251985', 'Today, 08:30 AM', '1 Sack', 'Dispatched', const Color(0xFF9C3D18)),
          _buildRequestCard('Sacks Pickup #249112', 'Oct 28, 2026', '2 Sacks', 'Completed', const Color(0xFF0D2618)),
          _buildRequestCard('Standard Pickup #248873', 'Oct 15, 2026', '1 Sack', 'Completed', const Color(0xFF0D2618)),
        ],
      ),
    );
  }

  Widget _buildRequestCard(String id, String date, String size, String status, Color statusColor) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      elevation: 0,
      child: ListTile(
        contentPadding: const EdgeInsets.all(16),
        title: Text(id, style: const TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF0D2618))),
        subtitle: Text('$date • $size'),
        trailing: Container(
          padding: const EdgeInsets.symmetric(vertical: 6, horizontal: 12),
          decoration: BoxDecoration(color: statusColor.withValues(alpha: 0.12), borderRadius: BorderRadius.circular(20)),
          child: Text(status, style: TextStyle(color: statusColor, fontWeight: FontWeight.bold, fontSize: 12)),
        ),
      ),
    );
  }
}

class ResidentSupportScreen extends StatelessWidget {
  const ResidentSupportScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Support Center')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            TextField(
              decoration: InputDecoration(
                hintText: 'Search FAQs or topics...',
                prefixIcon: const Icon(Icons.search, color: Color(0xFF1A3A28)),
                filled: true,
                fillColor: Colors.white,
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
              ),
            ),
            const SizedBox(height: 20),
            Row(
              children: [
                Expanded(child: _buildQuickHelpCard(Icons.local_shipping_outlined, 'Missed Pickup', 'Report a missed collection')),
                const SizedBox(width: 12),
                Expanded(child: _buildQuickHelpCard(Icons.edit_calendar_outlined, 'Change Booking', 'Reschedule your pickup')),
              ],
            ),
            const SizedBox(height: 16),
            _buildQuickHelpRow(Icons.payment_outlined, 'Payment Issue', 'Verify transaction or change billing'),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: () {},
              icon: const Icon(Icons.chat_bubble_outline, color: Colors.white),
              label: const Text('Chat with Dispatch', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF0D2618),
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
            ),
            const SizedBox(height: 12),
            OutlinedButton.icon(
              onPressed: () {},
              icon: const Icon(Icons.phone_outlined, color: Color(0xFF9C3D18)),
              label: const Text('Call Arua Fleet Ops', style: TextStyle(color: Color(0xFF9C3D18), fontWeight: FontWeight.bold)),
              style: OutlinedButton.styleFrom(
                side: const BorderSide(color: Color(0xFF9C3D18)),
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
            ),
            const SizedBox(height: 24),
            const Text('General FAQs', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Color(0xFF0D2618))),
            const SizedBox(height: 12),
            _buildFAQTile('What is is Dispatch?'),
            _buildFAQTile('How to change booking?'),
            _buildFAQTile('What materials are accepted?'),
          ],
        ),
      ),
    );
  }

  Widget _buildQuickHelpCard(IconData icon, String title, String desc) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(12)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: const Color(0xFF9C3D18), size: 28),
          const SizedBox(height: 12),
          Text(title, style: const TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF0D2618), fontSize: 14)),
          const SizedBox(height: 4),
          Text(desc, style: const TextStyle(fontSize: 11, color: Colors.grey)),
        ],
      ),
    );
  }

  Widget _buildQuickHelpRow(IconData icon, String title, String desc) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(12)),
      child: Row(
        children: [
          Icon(icon, color: const Color(0xFF9C3D18), size: 28),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: const TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF0D2618), fontSize: 14)),
                const SizedBox(height: 2),
                Text(desc, style: const TextStyle(fontSize: 11, color: Colors.grey)),
              ],
            ),
          ),
          const Icon(Icons.chevron_right, color: Colors.grey),
        ],
      ),
    );
  }

  Widget _buildFAQTile(String question) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(12)),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(question, style: const TextStyle(fontWeight: FontWeight.w600, color: Color(0xFF1A3A28))),
          const Icon(Icons.keyboard_arrow_down, color: Color(0xFF0D2618)),
        ],
      ),
    );
  }
}

// =================================================================
// 4. RIDER/COLLECTOR SUITE (Tasks, Route Navigation, Earnings)
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
      body: IndexedStack(index: _currentIndex, children: _screens),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _currentIndex,
        selectedItemColor: const Color(0xFF9C3D18),
        unselectedItemColor: const Color(0xFF1A3A28),
        backgroundColor: Colors.white,
        type: BottomNavigationBarType.fixed,
        onTap: (index) => setState(() => _currentIndex = index),
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.assignment), label: 'Tasks'),
          BottomNavigationBarItem(icon: Icon(Icons.navigation), label: 'Route'),
          BottomNavigationBarItem(icon: Icon(Icons.payments), label: 'Earnings'),
        ],
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
  bool _isOnShift = false;
  bool _isCollected = false;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Rider Dashboard'),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () => Navigator.pushReplacementNamed(context, '/login'),
          )
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: const [
                    Text('Hello, Rider • Arua City', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Color(0xFF0D2618))),
                    SizedBox(height: 2),
                    Text('Online Status', style: TextStyle(fontSize: 12, color: Colors.grey)),
                  ],
                ),
                Switch(
                  value: _isOnShift,
                  onChanged: (val) {
                    setState(() => _isOnShift = val);
                  },
                  activeTrackColor: const Color(0xFF0D2618), activeThumbColor: Colors.white,
                ),
              ],
            ),
            const SizedBox(height: 16),
            _isOnShift
                ? Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(color: const Color(0xFF0D2618), borderRadius: BorderRadius.circular(16)),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: const [
                        Text('Rider Active and Online', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                        Icon(Icons.online_prediction, color: Colors.green),
                      ],
                    ),
                  )
                : ElevatedButton(
                    onPressed: () => setState(() => _isOnShift = true),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF0D2618),
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                    child: const Text('+ Start Next Shift', style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold)),
                  ),
            const SizedBox(height: 24),
            const Text("Today's Active Task", style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Color(0xFF0D2618))),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.04), blurRadius: 10, offset: const Offset(0, 4))],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text('Active Pickup #251985', style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: Color(0xFF9C3D18))),
                      _isCollected
                          ? const Chip(label: Text('Collected'), backgroundColor: Color(0xFFE8ECE7))
                          : const Chip(label: Text('Dispatched'), backgroundColor: Color(0xFFFFEBEE)),
                    ],
                  ),
                  const SizedBox(height: 12),
                  const Text('Client: Jane A.', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Color(0xFF0D2618))),
                  const Text('Address: Ediofe, Trading Center', style: TextStyle(color: Color(0xFF1A3A28))),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      _buildMetricChip(Icons.shopping_bag_outlined, '1 Sack'),
                      const SizedBox(width: 8),
                      _buildMetricChip(Icons.currency_exchange, '2,500 UGX'),
                    ],
                  ),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton(
                          onPressed: () {},
                          style: OutlinedButton.styleFrom(side: const BorderSide(color: Color(0xFF0D2618)), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))),
                          child: const Text('Call Client', style: TextStyle(color: Color(0xFF0D2618))),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: ElevatedButton(
                          onPressed: () {
                            setState(() => _isCollected = !_isCollected);
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(content: Text(_isCollected ? 'Task completed & synced offline' : 'Task marked active')),
                            );
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF0D2618),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                          ),
                          child: Text(_isCollected ? 'Mark Active' : 'Mark Collected', style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                        ),
                      ),
                    ],
                  )
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMetricChip(IconData icon, String text) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 6, horizontal: 12),
      decoration: BoxDecoration(color: const Color(0xFFE8ECE7), borderRadius: BorderRadius.circular(20)),
      child: Row(
        children: [
          Icon(icon, size: 16, color: const Color(0xFF0D2618)),
          const SizedBox(width: 6),
          Text(text, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Color(0xFF0D2618))),
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
      appBar: AppBar(title: const Text('Active Navigation')),
      body: Column(
        children: [
          Container(
            color: const Color(0xFF0D2618),
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                const Icon(Icons.navigation_outlined, color: Colors.white, size: 36),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: const [
                      Text('In 150m, turn right onto Ediofe Rd', style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold)),
                      SizedBox(height: 2),
                      Text('Heading to Jane A. (Pickup #251985)', style: TextStyle(color: Colors.white70, fontSize: 13)),
                    ],
                  ),
                ),
              ],
            ),
          ),
          Expanded(
            child: Stack(
              children: [
                CustomPaint(
                  painter: AruaMapPainter(),
                  child: const Center(
                    child: Text('Navigation Path View: 4.3 km away • 12 mins left', style: TextStyle(color: Color(0xFF1A3A28), fontWeight: FontWeight.bold)),
                  ),
                ),
                Positioned(
                  bottom: 16,
                  left: 16,
                  right: 16,
                  child: Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16)),
                    child: Row(
                      children: [
                        const CircleAvatar(backgroundColor: Color(0xFFE8ECE7), child: Icon(Icons.person, color: Color(0xFF0D2618))),
                        const SizedBox(width: 16),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: const [
                              Text('Jane A. • 1 Sack', style: TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF0D2618))),
                              Text('Trading Center', style: TextStyle(color: Colors.grey, fontSize: 12)),
                            ],
                          ),
                        ),
                        ElevatedButton(
                          onPressed: () {},
                          style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF9C3D18), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))),
                          child: const Text('Arrived', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                        )
                      ],
                    ),
                  ),
                )
              ],
            ),
          )
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
      appBar: AppBar(title: const Text('My Earnings')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
              ),
              child: Column(
                children: [
                  const Text('Total Balance', style: TextStyle(color: Color(0xFF1A3A28), fontWeight: FontWeight.bold)),
                  const SizedBox(height: 8),
                  const Text('54,350 UGX', style: TextStyle(fontSize: 32, fontWeight: FontWeight.bold, color: Color(0xFF0D2618))),
                  const SizedBox(height: 20),
                  ElevatedButton(
                    onPressed: () {},
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF0D2618),
                      minimumSize: const Size(double.infinity, 48),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                    child: const Text('Request Payout', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                  )
                ],
              ),
            ),
            const SizedBox(height: 24),
            const Text('Daily Transactions', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Color(0xFF0D2618))),
            const SizedBox(height: 12),
            _buildEarningsItem('Pickup #251985', 'Jane A.', '2,500 UGX', 'Oct 31, 07:35 AM'),
            _buildEarningsItem('Pickup #251932', 'John B.', '2,500 UGX', 'Oct 30, 04:12 PM'),
            _buildEarningsItem('Batch Bonus', '+3 Pickups', '1,500 UGX', 'Oct 30, 08:00 PM'),
          ],
        ),
      ),
    );
  }

  Widget _buildEarningsItem(String title, String desc, String amt, String date) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(12)),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(title, style: const TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF0D2618))),
              Text('$desc • $date', style: const TextStyle(color: Colors.grey, fontSize: 11)),
            ],
          ),
          Text(amt, style: const TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF9C3D18))),
        ],
      ),
    );
  }
}

// =================================================================
// 5. ADMIN/DISPATCH HQ SUITE (Overview, Live Map, PDF Analytics)
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
    AdminFleetMapScreen(),
    AdminReportsScreen(),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: IndexedStack(index: _currentIndex, children: _screens),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _currentIndex,
        selectedItemColor: const Color(0xFF9C3D18),
        unselectedItemColor: const Color(0xFF1A3A28),
        backgroundColor: Colors.white,
        type: BottomNavigationBarType.fixed,
        onTap: (index) => setState(() => _currentIndex = index),
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.dashboard), label: 'Dashboard'),
          BottomNavigationBarItem(icon: Icon(Icons.directions_car), label: 'Fleet'),
          BottomNavigationBarItem(icon: Icon(Icons.assessment), label: 'Reports'),
        ],
      ),
    );
  }
}

class AdminDashboardScreen extends StatelessWidget {
  const AdminDashboardScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Admin Dashboard'),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () => Navigator.pushReplacementNamed(context, '/login'),
          )
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Container(
              padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
              decoration: BoxDecoration(color: const Color(0xFF1A3A28), borderRadius: BorderRadius.circular(12)),
              child: Row(
                children: const [
                  Icon(Icons.check_circle_outline, color: Colors.green, size: 20),
                  SizedBox(width: 12),
                  Text('All Systems Nominal', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 13)),
                  Spacer(),
                  Text('LIVE', style: TextStyle(color: Colors.green, fontSize: 11, fontWeight: FontWeight.bold)),
                ],
              ),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(child: _buildMetricCard('18', 'Active Riders')),
                const SizedBox(width: 8),
                Expanded(child: _buildMetricCard('5', 'Pending Pickups')),
                const SizedBox(width: 8),
                Expanded(child: _buildMetricCard('98%', 'Route Efficiency')),
              ],
            ),
            const SizedBox(height: 20),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16)),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Dispatch Network Status', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Color(0xFF0D2618))),
                  const SizedBox(height: 12),
                  Container(
                    height: 160,
                    decoration: BoxDecoration(color: const Color(0xFFE8ECE7), borderRadius: BorderRadius.circular(12)),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(12),
                      child: CustomPaint(
                        painter: AruaMapPainter(),
                        child: const Center(
                          child: Text('Cluster Activity Overview', style: TextStyle(color: Color(0xFF1A3A28), fontWeight: FontWeight.bold)),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),
            const Text('Quick Actions', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Color(0xFF0D2618))),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(child: _buildQuickActionCard(Icons.add_task, 'Assign New Task')),
                const SizedBox(width: 12),
                Expanded(child: _buildQuickActionCard(Icons.campaign_outlined, 'Broadcast Alert')),
                const SizedBox(width: 12),
                Expanded(child: _buildQuickActionCard(Icons.analytics_outlined, 'Generate Report')),
              ],
            )
          ],
        ),
      ),
    );
  }

  Widget _buildMetricCard(String val, String desc) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(12)),
      child: Column(
        children: [
          Text(val, style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Color(0xFF0D2618))),
          const SizedBox(height: 4),
          Text(desc, textAlign: TextAlign.center, style: const TextStyle(fontSize: 10, color: Colors.grey, fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }

  Widget _buildQuickActionCard(IconData icon, String title) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(12)),
      child: Column(
        children: [
          Icon(icon, color: const Color(0xFF9C3D18), size: 28),
          const SizedBox(height: 8),
          Text(title, textAlign: TextAlign.center, style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Color(0xFF0D2618))),
        ],
      ),
    );
  }
}

class AdminFleetMapScreen extends StatelessWidget {
  const AdminFleetMapScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Live Fleet Overviews')),
      body: Stack(
        children: [
          CustomPaint(
            painter: AruaMapPainter(),
            child: const Center(
              child: Text('Live City map showing ongoing collection dispatch trails', style: TextStyle(color: Color(0xFF1A3A28), fontWeight: FontWeight.bold)),
            ),
          ),
          Positioned(
            top: 16,
            left: 16,
            right: 16,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(12)),
              child: Row(
                children: const [
                  Icon(Icons.search, color: Colors.grey),
                  SizedBox(width: 12),
                  Text('Search live rider ID or collection post...', style: TextStyle(color: Colors.grey, fontSize: 13)),
                ],
              ),
            ),
          ),
          Positioned(
            bottom: 16,
            left: 16,
            right: 16,
            child: Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16)),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: const [
                      Text('Selected: TRIC-04 (John B.)', style: TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF0D2618))),
                      Text('95% Active 🟢', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.green)),
                    ],
                  ),
                  const SizedBox(height: 6),
                  const Text('On Route: Arua Center ➔ Ediofe, Trading Center (Jane A.)', style: TextStyle(color: Colors.grey, fontSize: 12)),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton(
                          onPressed: () {},
                          style: OutlinedButton.styleFrom(side: const BorderSide(color: Color(0xFF9C3D18)), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))),
                          child: const Text('Call Rider', style: TextStyle(color: Color(0xFF9C3D18))),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: ElevatedButton(
                          onPressed: () {},
                          style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF0D2618), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))),
                          child: const Text('Reassign', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                        ),
                      ),
                    ],
                  )
                ],
              ),
            ),
          )
        ],
      ),
    );
  }
}

class AdminReportsScreen extends StatelessWidget {
  const AdminReportsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Analytics & Reports')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16)),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Performance Overview', style: TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF0D2618))),
                  const SizedBox(height: 16),
                  _buildStatRow('Total Waste Collected', '14.5 Tonnes', '+12% Since Last Week', Colors.green),
                  const Divider(height: 24),
                  _buildStatRow('SLA Performance', '98.5%', 'Optimal Operational Capacity', const Color(0xFF9C3D18)),
                  const Divider(height: 24),
                  _buildStatRow('On-Time Operations', '97.0%', 'Rider efficiency active', Colors.green),
                ],
              ),
            ),
            const SizedBox(height: 24),
            const Text('Downloadable Activity Logs', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Color(0xFF0D2618))),
            const SizedBox(height: 12),
            _buildReportDownloadTile('Daily Operations - Oct 31, 2026'),
            _buildReportDownloadTile('Weekly Operations Summary - W44'),
            _buildReportDownloadTile('Rider Fleet Monthly Report'),
          ],
        ),
      ),
    );
  }

  Widget _buildStatRow(String label, String value, String helper, Color helperColor) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(label, style: const TextStyle(color: Colors.grey, fontSize: 13)),
            const SizedBox(height: 4),
            Text(value, style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Color(0xFF0D2618))),
          ],
        ),
        Text(helper, style: TextStyle(fontSize: 11, color: helperColor, fontWeight: FontWeight.bold)),
      ],
    );
  }

  Widget _buildReportDownloadTile(String title) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(12)),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: const TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF0D2618), fontSize: 13)),
                const Text('Includes dispatch payload history & rider audits', style: TextStyle(color: Colors.grey, fontSize: 10)),
              ],
            ),
          ),
          ElevatedButton.icon(
            onPressed: () {},
            icon: const Icon(Icons.download, size: 16, color: Colors.white),
            label: const Text('PDF', style: TextStyle(color: Colors.white, fontSize: 12)),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF9C3D18),
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
            ),
          ),
        ],
      ),
    );
  }
}

// =================================================================
// 6. SHARED PROGRESS STEPPER
// =================================================================
class ProgressStepper extends StatelessWidget {
  const ProgressStepper({super.key});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        _buildStep('Requested', true),
        _buildConnector(true),
        _buildStep('Collected', false),
        _buildConnector(false),
        _buildStep('Verifying', false),
        _buildConnector(false),
        _buildStep('Settled', false),
      ],
    );
  }

  Widget _buildStep(String title, bool isCompleted) {
    return Column(
      children: [
        CircleAvatar(
          radius: 12,
          backgroundColor: isCompleted ? const Color(0xFF9C3D18) : const Color(0xFFE8ECE7),
          child: isCompleted ? const Icon(Icons.check, size: 14, color: Colors.white) : const Text('•', style: TextStyle(color: Color(0xFF1A3A28))),
        ),
        const SizedBox(height: 6),
        Text(title, style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: isCompleted ? const Color(0xFF9C3D18) : Colors.grey)),
      ],
    );
  }

  Widget _buildConnector(bool isCompleted) {
    return Expanded(
      child: Padding(
        padding: const EdgeInsets.only(bottom: 16.0),
        child: Container(
          height: 2,
          color: isCompleted ? const Color(0xFF9C3D18) : const Color(0xFFE8ECE7),
        ),
      ),
    );
  }
}

// =================================================================
// 7. COMPACT CUSTOM PAINTER FOR ARUA CITY MAPS & ROUTING TRAILS
// =================================================================
class AruaMapPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paintLine = Paint()
      ..color = const Color(0xFF9C3D18) // Route outline trail (terracotta)
      ..strokeWidth = 3
      ..style = PaintingStyle.stroke;

    final paintRider = Paint()..color = const Color(0xFF0D2618); // Rider Location
    final paintTarget = Paint()..color = const Color(0xFF9C3D18); // Delivery Destination

    // Draw grid paths simulating roads in Arua, Uganda
    final paintRoad = Paint()
      ..color = Colors.white
      ..strokeWidth = 2;

    // Drawing some sample grids
    canvas.drawLine(Offset(0, size.height * 0.4), Offset(size.width, size.height * 0.5), paintRoad);
    canvas.drawLine(Offset(size.width * 0.3, 0), Offset(size.width * 0.25, size.height), paintRoad);
    canvas.drawLine(Offset(size.width * 0.7, 0), Offset(size.width * 0.75, size.height), paintRoad);

    // Route Trace Path
    final path = Path()
      ..moveTo(size.width * 0.2, size.height * 0.8)
      ..lineTo(size.width * 0.4, size.height * 0.6)
      ..lineTo(size.width * 0.5, size.height * 0.7)
      ..lineTo(size.width * 0.8, size.height * 0.2);
    canvas.drawPath(path, paintLine);

    // Drawing Origin, Dispatch nodes
    canvas.drawCircle(Offset(size.width * 0.2, size.height * 0.8), 6, paintRider);
    canvas.drawCircle(Offset(size.width * 0.8, size.height * 0.2), 6, paintTarget);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}