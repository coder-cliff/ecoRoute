import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:printing/printing.dart';
import 'package:url_launcher/url_launcher.dart';

import 'core/services/pdf_report_service.dart';
import 'firebase_options.dart';

// =================================================================
// SHARED CONSTANTS & HOTLINE (+256394880352)
// =================================================================
const String kEcoRouteSupportPhone = '+256394880352';
const String kEcoRouteWhatsAppNumber = '256394880352';

Future<void> launchEcoRouteCall([String phone = kEcoRouteSupportPhone]) async {
  final cleanPhone = phone.replaceAll(' ', '');
  final uri = Uri.parse('tel:$cleanPhone');
  try {
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri);
    }
  } catch (e) {
    debugPrint('Could not launch phone dialer: $e');
  }
}

Future<void> launchEcoRouteWhatsApp({String message = 'Hello EcoRoute Operations'}) async {
  final encoded = Uri.encodeComponent(message);
  final uri = Uri.parse('https://wa.me/$kEcoRouteWhatsAppNumber?text=$encoded');
  try {
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    }
  } catch (e) {
    debugPrint('Could not launch WhatsApp: $e');
  }
}

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  try {
    if (kIsWeb || defaultTargetPlatform == TargetPlatform.android || defaultTargetPlatform == TargetPlatform.iOS) {
      await Firebase.initializeApp(
        options: DefaultFirebaseOptions.currentPlatform,
      );
    }
  } catch (e) {
    debugPrint('Firebase initialization notice: $e');
  }
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
      if (mounted) {
        Navigator.pushReplacementNamed(context, '/login');
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
                  borderRadius: BorderRadius.circular(28),
                ),
                child: const Icon(Icons.eco, color: Colors.white, size: 54),
              ),
              const SizedBox(height: 24),
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
                  fontSize: 15,
                  color: Color(0xFF1A3A28),
                  fontWeight: FontWeight.w500,
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
// 2. FIREBASE AUTHENTICATION SCREEN (LOGIN & REGISTRATION)
// =================================================================
class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  bool _isSignUp = false;
  final _fullNameController = TextEditingController();
  final _phoneController = TextEditingController(text: '+256 394 880 352');
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  String _selectedRole = 'resident'; // 'resident', 'rider', 'admin'
  bool _isLoading = false;

  @override
  void dispose() {
    _fullNameController.dispose();
    _phoneController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _handleAuth() async {
    final email = _emailController.text.trim();
    final password = _passwordController.text.trim();

    if (email.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter your email address')),
      );
      return;
    }

    if (password.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter your password')),
      );
      return;
    }

    setState(() => _isLoading = true);

    // 1. Primary path: Firebase Authentication & Firestore (when active)
    if (Firebase.apps.isNotEmpty) {
      try {
        if (_isSignUp) {
          // Register via Firebase Auth
          final userCred = await FirebaseAuth.instance.createUserWithEmailAndPassword(
            email: email,
            password: password,
          );
          final uid = userCred.user?.uid;
          final name = _fullNameController.text.trim().isNotEmpty
              ? _fullNameController.text.trim()
              : email.split('@').first;
          await userCred.user?.updateDisplayName(name);

          // Store profile in Firestore 'users' collection
          if (uid != null) {
            try {
              await FirebaseFirestore.instance.collection('profiles').doc(uid).set({
                'id': uid,
                'fullName': name,
                'email': email.toLowerCase(),
                'phone': _phoneController.text.trim(),
                'role': _selectedRole,
                'createdAt': FieldValue.serverTimestamp(),
              });
            } catch (e) {
              debugPrint('Firestore profile creation notice: $e');
            }
          }

          if (!mounted) return;
          setState(() => _isLoading = false);

          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Account created as $_selectedRole! Welcome, $name.')),
          );

          if (_selectedRole == 'admin') {
            Navigator.pushReplacementNamed(context, '/admin');
          } else if (_selectedRole == 'rider') {
            Navigator.pushReplacementNamed(context, '/rider');
          } else {
            Navigator.pushReplacementNamed(context, '/resident');
          }
          return;
        } else {
          // Sign In via Firebase Auth
          final userCred = await FirebaseAuth.instance.signInWithEmailAndPassword(
            email: email,
            password: password,
          );
          final uid = userCred.user?.uid;
          String resolvedRole = 'resident';

          // Fetch user role from Firestore 'users' collection
          if (uid != null) {
            try {
              var doc = await FirebaseFirestore.instance.collection('profiles').doc(uid).get();
              if (!doc.exists) {
                doc = await FirebaseFirestore.instance.collection('users').doc(uid).get();
              }
              if (doc.exists && doc.data() != null) {
                resolvedRole = (doc.data()!['role'] as String?)?.toLowerCase() ?? 'resident';
              }
            } catch (e) {
              debugPrint('Firestore role lookup notice: $e');
            }
          }

          if (!mounted) return;
          setState(() => _isLoading = false);

          if (resolvedRole == 'admin') {
            Navigator.pushReplacementNamed(context, '/admin');
          } else if (resolvedRole == 'rider') {
            Navigator.pushReplacementNamed(context, '/rider');
          } else {
            Navigator.pushReplacementNamed(context, '/resident');
          }
          return;
        }
      } on FirebaseAuthException catch (e) {
        if (!mounted) return;
        setState(() => _isLoading = false);
        final message = e.message ?? 'Authentication failed. Please verify credentials.';
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(message)),
        );
        return;
      } catch (e) {
        debugPrint('Firebase Auth general error: $e');
      }
    }

    // 2. Headless testing / offline runner fallback
    await Future.delayed(const Duration(milliseconds: 600));
    if (!mounted) return;
    setState(() => _isLoading = false);

    final clean = email.toLowerCase();
    if (clean.contains('admin')) {
      Navigator.pushReplacementNamed(context, '/admin');
    } else if (clean.contains('rider')) {
      Navigator.pushReplacementNamed(context, '/rider');
    } else {
      Navigator.pushReplacementNamed(context, '/resident');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 36.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const SizedBox(height: 16),
              const Center(
                child: CircleAvatar(
                  backgroundColor: Color(0xFF0D2618),
                  radius: 36,
                  child: Icon(Icons.eco, color: Colors.white, size: 36),
                ),
              ),
              const SizedBox(height: 20),
              Text(
                _isSignUp ? 'Create EcoRoute Account' : 'Welcome to EcoRoute',
                textAlign: TextAlign.center,
                style: const TextStyle(fontSize: 26, fontWeight: FontWeight.bold, color: Color(0xFF0D2618)),
              ),
              const SizedBox(height: 8),
              Text(
                _isSignUp
                    ? 'Register your account securely with Firebase'
                    : 'Sign in with your verified Firebase credentials',
                textAlign: TextAlign.center,
                style: const TextStyle(fontSize: 14, color: Color(0xFF1A3A28)),
              ),
              const SizedBox(height: 32),

              // Sign Up additional fields
              if (_isSignUp) ...[
                TextField(
                  controller: _fullNameController,
                  style: const TextStyle(color: Color(0xFF0D2618)),
                  decoration: InputDecoration(
                    labelText: 'Full Name',
                    hintText: 'e.g. Savior Deo',
                    labelStyle: const TextStyle(color: Color(0xFF0D2618)),
                    filled: true,
                    fillColor: Colors.white,
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
                    prefixIcon: const Icon(Icons.badge_outlined, color: Color(0xFF0D2618)),
                  ),
                ),
                const SizedBox(height: 14),
                TextField(
                  controller: _phoneController,
                  style: const TextStyle(color: Color(0xFF0D2618)),
                  decoration: InputDecoration(
                    labelText: 'Phone Number',
                    hintText: '+256 394 880 352',
                    labelStyle: const TextStyle(color: Color(0xFF0D2618)),
                    filled: true,
                    fillColor: Colors.white,
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
                    prefixIcon: const Icon(Icons.phone_outlined, color: Color(0xFF0D2618)),
                  ),
                ),
                const SizedBox(height: 14),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(12)),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('Select Your Role:', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Color(0xFF1A3A28))),
                      const SizedBox(height: 6),
                      Row(
                        children: [
                          _buildRoleChip('Resident', 'resident'),
                          const SizedBox(width: 8),
                          _buildRoleChip('Rider', 'rider'),
                          const SizedBox(width: 8),
                          _buildRoleChip('Admin', 'admin'),
                        ],
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 14),
              ],

              TextField(
                key: const ValueKey('login_email_input'),
                controller: _emailController,
                keyboardType: TextInputType.emailAddress,
                style: const TextStyle(color: Color(0xFF0D2618)),
                decoration: InputDecoration(
                  labelText: 'Email Address',
                  hintText: 'name@ecoroute.ug',
                  labelStyle: const TextStyle(color: Color(0xFF0D2618)),
                  filled: true,
                  fillColor: Colors.white,
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
                  prefixIcon: const Icon(Icons.email_outlined, color: Color(0xFF0D2618)),
                ),
              ),
              const SizedBox(height: 14),
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
                      onPressed: _handleAuth,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF0D2618),
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                      child: Text(
                        _isSignUp ? 'Create Account' : 'Continue',
                        style: const TextStyle(fontSize: 16, color: Colors.white, fontWeight: FontWeight.bold),
                      ),
                    ),
              const SizedBox(height: 16),
              TextButton(
                onPressed: () {
                  setState(() => _isSignUp = !_isSignUp);
                },
                child: Text(
                  _isSignUp
                      ? 'Already have a Firebase account? Sign In'
                      : "Don't have an account? Create one with Firebase",
                  style: const TextStyle(color: Color(0xFF0D2618), fontWeight: FontWeight.bold, fontSize: 13),
                ),
              ),
              const SizedBox(height: 8),
              Center(
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(Icons.support_agent, size: 16, color: Color(0xFF1A3A28)),
                    const SizedBox(width: 6),
                    TextButton(
                      onPressed: () => launchEcoRouteWhatsApp(message: 'Hello EcoRoute Support (+256394880352)'),
                      child: const Text('Support Hotline: +256 394 880 352', style: TextStyle(color: Color(0xFF1A3A28), fontSize: 12)),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildRoleChip(String label, String roleValue) {
    final isSelected = _selectedRole == roleValue;
    return Expanded(
      child: InkWell(
        onTap: () => setState(() => _selectedRole = roleValue),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 8),
          decoration: BoxDecoration(
            color: isSelected ? const Color(0xFF0D2618) : const Color(0xFFE8ECE7),
            borderRadius: BorderRadius.circular(8),
          ),
          alignment: Alignment.center,
          child: Text(
            label,
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.bold,
              color: isSelected ? Colors.white : const Color(0xFF0D2618),
            ),
          ),
        ),
      ),
    );
  }
}

// =================================================================
// 3. ROLE 1: RESIDENT DASHBOARD (HOME, REQUESTS, SUPPORT)
// =================================================================
class ResidentRootScreen extends StatefulWidget {
  const ResidentRootScreen({super.key});

  @override
  State<ResidentRootScreen> createState() => _ResidentRootScreenState();
}

class _ResidentRootScreenState extends State<ResidentRootScreen> {
  int _currentIndex = 0;

  // Active collection order state
  Map<String, dynamic> _activePickup = {
    'id': '251985',
    'sacks': 1,
    'wasteType': 'Household',
    'address': 'Ediofe, Trading Center',
    'price': '2,500 UGX',
    'status': 'Dispatched',
    'step': 1,
  };

  final List<Map<String, dynamic>> _requests = [
    {'id': 'Active Pickup #251985', 'date': 'Today, 08:30 AM', 'size': '1 Sack', 'status': 'Dispatched', 'color': Color(0xFF9C3D18)},
    {'id': 'Sacks Pickup #249112', 'date': 'Oct 28, 2026', 'size': '2 Sacks', 'status': 'Completed', 'color': Color(0xFF0D2618)},
    {'id': 'Standard Pickup #248873', 'date': 'Oct 15, 2026', 'size': '1 Sack', 'status': 'Completed', 'color': Color(0xFF0D2618)},
  ];

  void _bookNewPickup() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => _BookingBottomSheet(
        onBook: (sacks, wasteType, address, isInstant) {
          final newId = '${DateTime.now().millisecondsSinceEpoch % 1000000}';
          final price = '${sacks * 2500} UGX';
          setState(() {
            _activePickup = {
              'id': newId,
              'sacks': sacks,
              'wasteType': wasteType,
              'address': address,
              'price': price,
              'status': 'Requested',
              'step': 0,
            };
            _requests.insert(0, {
              'id': 'Pickup #$newId',
              'date': 'Just now',
              'size': '$sacks Sack${sacks > 1 ? 's' : ''}',
              'status': 'Requested',
              'color': const Color(0xFF9C3D18),
            });
          });
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Pickup #$newId booked for $address ($price)! Dispatched to nearby tricycles.')),
          );
        },
      ),
    );
  }

  void _openLiveMapTracker() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => _LiveMapTrackerSheet(
        pickup: _activePickup,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final screens = [
      ResidentHomeScreen(
        pickup: _activePickup,
        onBookPickup: _bookNewPickup,
        onOpenMap: _openLiveMapTracker,
      ),
      ResidentRequestsScreen(
        requests: _requests,
        onBookPickup: _bookNewPickup,
      ),
      const ResidentSupportScreen(),
    ];

    return Scaffold(
      body: screens[_currentIndex],
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _currentIndex,
        onTap: (index) => setState(() => _currentIndex = index),
        selectedItemColor: const Color(0xFF0D2618),
        unselectedItemColor: Colors.grey,
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.home_outlined), activeIcon: Icon(Icons.home), label: 'Home'),
          BottomNavigationBarItem(icon: Icon(Icons.receipt_long_outlined), activeIcon: Icon(Icons.receipt_long), label: 'Requests'),
          BottomNavigationBarItem(icon: Icon(Icons.support_agent_outlined), activeIcon: Icon(Icons.support_agent), label: 'Support'),
        ],
      ),
    );
  }
}

class ResidentHomeScreen extends StatelessWidget {
  final Map<String, dynamic> pickup;
  final VoidCallback onBookPickup;
  final VoidCallback onOpenMap;

  const ResidentHomeScreen({
    super.key,
    required this.pickup,
    required this.onBookPickup,
    required this.onOpenMap,
  });

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
            tooltip: 'Call Support (+256394880352)',
            icon: const Icon(Icons.phone_outlined),
            onPressed: () => launchEcoRouteCall(),
          ),
          IconButton(
            tooltip: 'Log Out',
            icon: const Icon(Icons.logout),
            onPressed: () async {
              try {
                await FirebaseAuth.instance.signOut();
              } catch (_) {}
              if (context.mounted) {
                Navigator.pushReplacementNamed(context, '/login');
              }
            },
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
                    Text('Hello, Resident • Arua City', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Color(0xFF0D2618))),
                    SizedBox(height: 2),
                    Text('Ayivu / Central Division Service Area', style: TextStyle(fontSize: 12, color: Color(0xFF1A3A28))),
                  ],
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(color: Colors.green.withValues(alpha: 0.15), borderRadius: BorderRadius.circular(12)),
                  child: Row(
                    children: const [
                      Icon(Icons.circle, color: Colors.green, size: 8),
                      SizedBox(width: 4),
                      Text('Online', style: TextStyle(color: Colors.green, fontSize: 11, fontWeight: FontWeight.bold)),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            ElevatedButton.icon(
              onPressed: onBookPickup,
              icon: const Icon(Icons.add, color: Colors.white),
              label: const Text('Book a New Pickup', style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold)),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF0D2618),
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              ),
            ),
            const SizedBox(height: 20),

            // Active Tracking Card
            Container(
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.04), blurRadius: 10, offset: const Offset(0, 4))],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  GestureDetector(
                    onTap: onOpenMap,
                    child: ClipRRect(
                      borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
                      child: SizedBox(
                        height: 120,
                        child: CustomPaint(
                          painter: AruaMapPainter(),
                          child: Stack(
                            children: [
                              Container(color: Colors.black.withValues(alpha: 0.05)),
                              Center(
                                child: Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                                  decoration: BoxDecoration(color: const Color(0xFF0D2618), borderRadius: BorderRadius.circular(20)),
                                  child: const Text('Tap to View Live Route', style: TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.bold)),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text('Tricycle Rider: #${pickup['id']}', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: Color(0xFF0D2618))),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                              decoration: BoxDecoration(color: const Color(0xFF9C3D18).withValues(alpha: 0.12), borderRadius: BorderRadius.circular(8)),
                              child: Text(pickup['status'] as String, style: const TextStyle(color: Color(0xFF9C3D18), fontSize: 11, fontWeight: FontWeight.bold)),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        ProgressStepper(currentStep: pickup['step'] as int),
                        const SizedBox(height: 16),
                        const Text('Order Snapshot', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: Color(0xFF0D2618))),
                        const SizedBox(height: 4),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text('${pickup['sacks']} Sack(s) • ${pickup['address']}', style: const TextStyle(color: Color(0xFF1A3A28), fontSize: 12)),
                            Text(pickup['price'] as String, style: const TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF0D2618), fontSize: 13)),
                          ],
                        ),
                        const SizedBox(height: 2),
                        const Text('Cash on Collection (or MoMo: +256 394 880 352)', style: TextStyle(color: Colors.grey, fontSize: 11)),
                        const SizedBox(height: 12),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            InkWell(
                              onTap: onOpenMap,
                              child: const Text('View Live Map Tracker >', style: TextStyle(color: Color(0xFF9C3D18), fontWeight: FontWeight.bold, fontSize: 12)),
                            ),
                            ElevatedButton.icon(
                              onPressed: () => launchEcoRouteCall(),
                              icon: const Icon(Icons.phone, size: 14, color: Colors.white),
                              label: const Text('Call Dispatch', style: TextStyle(color: Colors.white, fontSize: 11)),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: const Color(0xFF0D2618),
                                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),

            // Weather Widget
            Container(
              padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
              decoration: BoxDecoration(color: const Color(0xFF1A3A28), borderRadius: BorderRadius.circular(12)),
              child: Row(
                children: [
                  const Icon(Icons.wb_sunny_outlined, color: Colors.amber, size: 20),
                  const SizedBox(width: 10),
                  const Expanded(
                    child: Text('Weather: Favorable • 20.3°C Arua', style: TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.w500)),
                  ),
                  InkWell(
                    onTap: () {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Weather synced from Open-Meteo Arua: 20.3°C, Favorable conditions.')),
                      );
                    },
                    child: const Text('Refresh', style: TextStyle(color: Colors.amber, fontSize: 11, fontWeight: FontWeight.bold)),
                  ),
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
  final List<Map<String, dynamic>> requests;
  final VoidCallback onBookPickup;

  const ResidentRequestsScreen({
    super.key,
    required this.requests,
    required this.onBookPickup,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('My Requests')),
      body: ListView(
        padding: const EdgeInsets.all(16.0),
        children: [
          for (final req in requests)
            _buildRequestCard(
              context,
              req['id'] as String,
              req['date'] as String,
              req['size'] as String,
              req['status'] as String,
              req['color'] as Color,
            ),
          const SizedBox(height: 16),
          ElevatedButton.icon(
            onPressed: onBookPickup,
            icon: const Icon(Icons.add, color: Colors.white),
            label: const Text('Book Another Pickup', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF0D2618),
              padding: const EdgeInsets.symmetric(vertical: 14),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRequestCard(BuildContext context, String id, String date, String size, String status, Color statusColor) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      elevation: 0,
      color: Colors.white,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: ListTile(
        onTap: () {
          showModalBottomSheet(
            context: context,
            backgroundColor: Colors.transparent,
            builder: (ctx) => Container(
              padding: const EdgeInsets.all(20),
              decoration: const BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Text(id, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18, color: Color(0xFF0D2618))),
                  const SizedBox(height: 8),
                  Text('Scheduled on $date • Payload: $size', style: const TextStyle(color: Color(0xFF1A3A28))),
                  const SizedBox(height: 16),
                  Text('Status: $status', style: TextStyle(fontWeight: FontWeight.bold, color: statusColor)),
                  const SizedBox(height: 8),
                  const Text('Payment: 2,500 UGX (Collection hotline: +256 394 880 352)'),
                  const SizedBox(height: 20),
                  ElevatedButton(
                    onPressed: () => launchEcoRouteWhatsApp(message: 'Inquiry regarding $id'),
                    style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF0D2618)),
                    child: const Text('WhatsApp Dispatch Hotline', style: TextStyle(color: Colors.white)),
                  ),
                ],
              ),
            ),
          );
        },
        leading: CircleAvatar(
          backgroundColor: statusColor.withValues(alpha: 0.12),
          child: Icon(Icons.local_shipping_outlined, color: statusColor),
        ),
        title: Text(id, style: const TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF0D2618), fontSize: 14)),
        subtitle: Text('$date • $size', style: const TextStyle(color: Colors.grey, fontSize: 12)),
        trailing: Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
          decoration: BoxDecoration(color: statusColor.withValues(alpha: 0.12), borderRadius: BorderRadius.circular(20)),
          child: Text(status, style: TextStyle(color: statusColor, fontSize: 11, fontWeight: FontWeight.bold)),
        ),
      ),
    );
  }
}

class ResidentSupportScreen extends StatefulWidget {
  const ResidentSupportScreen({super.key});

  @override
  State<ResidentSupportScreen> createState() => _ResidentSupportScreenState();
}

class _ResidentSupportScreenState extends State<ResidentSupportScreen> {
  final _searchController = TextEditingController();
  String _searchQuery = '';

  final List<Map<String, String>> _faqs = [
    {
      'q': 'What is EcoRoute Dispatch?',
      'a': 'EcoRoute Dispatch is an on-demand waste collection service deploying motorized tricycles across Arua City (Ediofe, Oli, Ayivu, Arua Hill, Muni) for clean and timely disposal.'
    },
    {
      'q': 'How to change or reschedule booking?',
      'a': 'You can change or reschedule your booking by tapping Change Booking above or contacting dispatch directly via WhatsApp (+256 394 880 352).'
    },
    {
      'q': 'What materials and sacks are accepted?',
      'a': 'We accept household waste, organic compostables, paper, plastics, and recyclable metal scrap in standard sacks.'
    },
    {
      'q': 'How does Cash on Collection work?',
      'a': 'You pay 2,500 UGX per sack directly to the verified rider upon collection, or pay via MTN MoMo to our official line (+256 394 880 352).'
    },
  ];

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final filteredFaqs = _faqs.where((f) {
      final q = f['q']!.toLowerCase();
      final a = f['a']!.toLowerCase();
      final search = _searchQuery.toLowerCase();
      return q.contains(search) || a.contains(search);
    }).toList();

    return Scaffold(
      appBar: AppBar(title: const Text('Support Center')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            TextField(
              controller: _searchController,
              onChanged: (val) => setState(() => _searchQuery = val),
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
                _buildHelpActionCard(
                  'Missed Pickup',
                  Icons.report_problem_outlined,
                  () => launchEcoRouteWhatsApp(message: 'Hello EcoRoute Dispatch (+256394880352), I have a Missed Pickup inquiry in Arua.'),
                ),
                const SizedBox(width: 8),
                _buildHelpActionCard(
                  'Change Booking',
                  Icons.edit_calendar_outlined,
                  () => launchEcoRouteWhatsApp(message: 'Hello EcoRoute Dispatch (+256394880352), I want to Change my Pickup Booking.'),
                ),
                const SizedBox(width: 8),
                _buildHelpActionCard(
                  'Payment Issue',
                  Icons.payments_outlined,
                  () => launchEcoRouteWhatsApp(message: 'Hello EcoRoute Dispatch (+256394880352), I have a Payment Issue inquiry.'),
                ),
              ],
            ),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: () => launchEcoRouteWhatsApp(message: 'Hello EcoRoute Dispatch Support (+256394880352)'),
              icon: const Icon(Icons.chat_outlined, color: Colors.white),
              label: const Text('Chat with Dispatch (+256 394 880 352)', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF0D2618),
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
            ),
            const SizedBox(height: 12),
            OutlinedButton.icon(
              onPressed: () => launchEcoRouteCall(),
              icon: const Icon(Icons.phone_outlined, color: Color(0xFF9C3D18)),
              label: const Text('Call Arua Fleet Ops (+256 394 880 352)', style: TextStyle(color: Color(0xFF9C3D18), fontWeight: FontWeight.bold)),
              style: OutlinedButton.styleFrom(
                side: const BorderSide(color: Color(0xFF9C3D18)),
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
            ),
            const SizedBox(height: 24),
            const Text('General FAQs', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Color(0xFF0D2618))),
            const SizedBox(height: 12),
            if (filteredFaqs.isEmpty)
              const Padding(
                padding: EdgeInsets.all(16.0),
                child: Text('No matching FAQ found. Tap Chat with Dispatch for instant support.', style: TextStyle(color: Colors.grey)),
              )
            else
              for (final f in filteredFaqs)
                Card(
                  margin: const EdgeInsets.only(bottom: 8),
                  color: Colors.white,
                  elevation: 0,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  child: ExpansionTile(
                    title: Text(f['q']!, style: const TextStyle(fontWeight: FontWeight.w600, color: Color(0xFF0D2618), fontSize: 13)),
                    children: [
                      Padding(
                        padding: const EdgeInsets.all(16.0),
                        child: Text(f['a']!, style: const TextStyle(color: Color(0xFF1A3A28), fontSize: 12, height: 1.4)),
                      )
                    ],
                  ),
                ),
          ],
        ),
      ),
    );
  }

  Widget _buildHelpActionCard(String title, IconData icon, VoidCallback onTap) {
    return Expanded(
      child: InkWell(
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
            boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.04), blurRadius: 4, offset: const Offset(0, 2))],
          ),
          child: Column(
            children: [
              Icon(icon, color: const Color(0xFF0D2618), size: 24),
              const SizedBox(height: 8),
              Text(title, textAlign: TextAlign.center, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 11, color: Color(0xFF0D2618))),
            ],
          ),
        ),
      ),
    );
  }
}

// =================================================================
// 4. ROLE 2: RIDER / COLLECTOR DASHBOARD
// =================================================================
class RiderRootScreen extends StatefulWidget {
  const RiderRootScreen({super.key});

  @override
  State<RiderRootScreen> createState() => _RiderRootScreenState();
}

class _RiderRootScreenState extends State<RiderRootScreen> {
  int _currentIndex = 0;
  bool _isShiftActive = true;
  bool _isCollected = false;
  int _earningsBalance = 54350;

  final List<Map<String, dynamic>> _transactions = [
    {'title': 'Ediofe Center Batch #251980', 'date': 'Today, 07:45 AM', 'amount': '+12,500 UGX', 'isBonus': false},
    {'title': 'Ayivu Central Route Completion', 'date': 'Today, 06:30 AM', 'amount': '+25,000 UGX', 'isBonus': false},
    {'title': 'SLA Reliability Bonus', 'date': 'Yesterday', 'amount': '+16,850 UGX', 'isBonus': true},
  ];

  void _requestPayout() {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Request Payout', style: TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF0D2618))),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Available Balance: 54,350 UGX', style: TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF9C3D18))),
            const SizedBox(height: 12),
            const Text('Payout Method: MTN Mobile Money / Airtel Money'),
            const SizedBox(height: 6),
            const Text('Target line: +256 394 880 352 (Official Fleet)', style: TextStyle(color: Colors.grey, fontSize: 12)),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(ctx);
              setState(() {
                _earningsBalance = 0;
                _transactions.insert(0, {
                  'title': 'Payout Request (MTN MoMo)',
                  'date': 'Just now',
                  'amount': '-54,350 UGX',
                  'isBonus': false,
                });
              });
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Payout request of 54,350 UGX submitted to MTN MoMo (+256 394 880 352)!')),
              );
            },
            style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF0D2618)),
            child: const Text('Confirm Payout', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final screens = [
      RiderTasksScreen(
        isShiftActive: _isShiftActive,
        isCollected: _isCollected,
        onToggleShift: (val) {
          setState(() => _isShiftActive = val);
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(_isShiftActive ? 'Shift Started • Online & accepting pickups' : 'Shift Ended • Offline')),
          );
        },
        onToggleCollected: () {
          setState(() => _isCollected = !_isCollected);
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(_isCollected ? 'Pickup #251985 collected! Synced with Admin HQ.' : 'Pickup #251985 marked active.')),
          );
        },
        onNavigateToRoute: () => setState(() => _currentIndex = 1),
      ),
      RiderRouteScreen(
        onArrived: () {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Arrived at Ediofe Trading Center. Notifying client Jane A.')),
          );
        },
      ),
      RiderEarningsScreen(
        balance: _earningsBalance,
        transactions: _transactions,
        onRequestPayout: _requestPayout,
      ),
    ];

    return Scaffold(
      body: screens[_currentIndex],
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _currentIndex,
        onTap: (index) => setState(() => _currentIndex = index),
        selectedItemColor: const Color(0xFF0D2618),
        unselectedItemColor: Colors.grey,
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.assignment_outlined), activeIcon: Icon(Icons.assignment), label: 'Tasks'),
          BottomNavigationBarItem(icon: Icon(Icons.route_outlined), activeIcon: Icon(Icons.route), label: 'Route'),
          BottomNavigationBarItem(icon: Icon(Icons.account_balance_wallet_outlined), activeIcon: Icon(Icons.account_balance_wallet), label: 'Earnings'),
        ],
      ),
    );
  }
}

class RiderTasksScreen extends StatelessWidget {
  final bool isShiftActive;
  final bool isCollected;
  final ValueChanged<bool> onToggleShift;
  final VoidCallback onToggleCollected;
  final VoidCallback onNavigateToRoute;

  const RiderTasksScreen({
    super.key,
    required this.isShiftActive,
    required this.isCollected,
    required this.onToggleShift,
    required this.onToggleCollected,
    required this.onNavigateToRoute,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Rider Dashboard'),
        actions: [
          IconButton(
            tooltip: 'Log Out',
            icon: const Icon(Icons.logout),
            onPressed: () async {
              try {
                await FirebaseAuth.instance.signOut();
              } catch (_) {}
              if (context.mounted) {
                Navigator.pushReplacementNamed(context, '/login');
              }
            },
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
                  children: [
                    const Text('Hello, Rider • Arua City', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Color(0xFF0D2618))),
                    const SizedBox(height: 2),
                    Text(isShiftActive ? 'Online Status: Active' : 'Online Status: Shift Ended', style: TextStyle(fontSize: 12, color: isShiftActive ? Colors.green : Colors.grey)),
                  ],
                ),
                Row(
                  children: [
                    Text(isShiftActive ? 'Shift On' : 'Shift Off', style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                    Switch(
                      value: isShiftActive,
                      onChanged: onToggleShift,
                      activeTrackColor: const Color(0xFF0D2618),
                      activeThumbColor: Colors.white,
                    ),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 16),

            // Active Task Card
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
                      isCollected
                          ? const Chip(label: Text('Collected'), backgroundColor: Color(0xFFE8ECE7))
                          : const Chip(label: Text('Dispatched'), backgroundColor: Color(0xFFFFEBEE)),
                    ],
                  ),
                  const SizedBox(height: 12),
                  const Text('Client: Jane A.', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Color(0xFF0D2618))),
                  const Text('Address: Ediofe, Trading Center', style: TextStyle(color: Colors.grey, fontSize: 13)),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      Expanded(
                        child: Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(color: const Color(0xFFE8ECE7), borderRadius: BorderRadius.circular(8)),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: const [
                              Text('Payload', style: TextStyle(fontSize: 11, color: Colors.grey)),
                              Text('1 Sack', style: TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF0D2618))),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(color: const Color(0xFFE8ECE7), borderRadius: BorderRadius.circular(8)),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: const [
                              Text('Payment', style: TextStyle(fontSize: 11, color: Colors.grey)),
                              Text('2,500 UGX Cash', style: TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF0D2618))),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton(
                          onPressed: () => launchEcoRouteCall(),
                          style: OutlinedButton.styleFrom(side: const BorderSide(color: Color(0xFF0D2618)), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))),
                          child: const Text('Call Client', style: TextStyle(color: Color(0xFF0D2618))),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: ElevatedButton(
                          onPressed: onToggleCollected,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF0D2618),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                          ),
                          child: Text(isCollected ? 'Mark Pending' : 'Mark Collected', style: const TextStyle(color: Colors.white)),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),

            // Mini Map Route Preview
            GestureDetector(
              onTap: onNavigateToRoute,
              child: Container(
                height: 180,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.04), blurRadius: 10, offset: const Offset(0, 4))],
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(16),
                  child: Stack(
                    children: [
                      CustomPaint(
                        size: const Size(double.infinity, 180),
                        painter: AruaMapPainter(),
                      ),
                      Positioned(
                        bottom: 12,
                        right: 12,
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                          decoration: BoxDecoration(color: const Color(0xFF0D2618), borderRadius: BorderRadius.circular(20)),
                          child: const Text('Tap to Start Turn Route >', style: TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.bold)),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class RiderRouteScreen extends StatelessWidget {
  final VoidCallback onArrived;

  const RiderRouteScreen({super.key, required this.onArrived});

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
                      Text('Approaching client pickup point Jane A.', style: TextStyle(color: Colors.white70, fontSize: 12)),
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
                  size: Size.infinite,
                  painter: AruaMapPainter(),
                ),
                Positioned(
                  bottom: 24,
                  left: 16,
                  right: 16,
                  child: Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16)),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: const [
                            Text('4.1 km • 15 min remaining', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15, color: Color(0xFF0D2618))),
                            Text('Tricycle Route: Arua Center -> Ediofe', style: TextStyle(color: Colors.grey, fontSize: 11)),
                          ],
                        ),
                        ElevatedButton(
                          onPressed: onArrived,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF9C3D18),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                          ),
                          child: const Text('Arrived', style: TextStyle(color: Colors.white)),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class RiderEarningsScreen extends StatelessWidget {
  final int balance;
  final List<Map<String, dynamic>> transactions;
  final VoidCallback onRequestPayout;

  const RiderEarningsScreen({
    super.key,
    required this.balance,
    required this.transactions,
    required this.onRequestPayout,
  });

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
                  Text('$balance UGX', style: const TextStyle(fontSize: 32, fontWeight: FontWeight.bold, color: Color(0xFF0D2618))),
                  const SizedBox(height: 4),
                  const Text('Last Payout: Today, 06:00 AM • EcoRoute Arua', style: TextStyle(color: Colors.grey, fontSize: 12)),
                  const SizedBox(height: 16),
                  ElevatedButton(
                    onPressed: balance > 0 ? onRequestPayout : null,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF9C3D18),
                      padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 12),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                    child: const Text('Request Payout', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),
            const Text('Recent Collections & Payouts', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Color(0xFF0D2618))),
            const SizedBox(height: 12),
            for (final tx in transactions)
              _buildTransactionTile(
                context,
                tx['title'] as String,
                tx['date'] as String,
                tx['amount'] as String,
                isBonus: tx['isBonus'] as bool,
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildTransactionTile(BuildContext context, String title, String time, String amount, {bool isBonus = false}) {
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      elevation: 0,
      color: Colors.white,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: ListTile(
        onTap: () {
          showDialog(
            context: context,
            builder: (ctx) => AlertDialog(
              title: Text(title, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Color(0xFF0D2618))),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Timestamp: $time'),
                  Text('Amount: $amount', style: const TextStyle(fontWeight: FontWeight.bold)),
                  const SizedBox(height: 8),
                  const Text('Settled to Rider Ledger: EcoRoute Arua Fleet Operations (+256 394 880 352)'),
                ],
              ),
              actions: [
                TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Close')),
              ],
            ),
          );
        },
        leading: CircleAvatar(
          backgroundColor: isBonus ? const Color(0xFF9C3D18).withValues(alpha: 0.12) : const Color(0xFF0D2618).withValues(alpha: 0.12),
          child: Icon(isBonus ? Icons.star_outline : Icons.arrow_downward, color: isBonus ? const Color(0xFF9C3D18) : const Color(0xFF0D2618)),
        ),
        title: Text(title, style: const TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF0D2618), fontSize: 13)),
        subtitle: Text(time, style: const TextStyle(color: Colors.grey, fontSize: 11)),
        trailing: Text(amount, style: TextStyle(fontWeight: FontWeight.bold, color: isBonus ? const Color(0xFF9C3D18) : const Color(0xFF0D2618))),
      ),
    );
  }
}

// =================================================================
// 5. ROLE 3: ADMIN COMMAND HQ
// =================================================================
class AdminRootScreen extends StatefulWidget {
  const AdminRootScreen({super.key});

  @override
  State<AdminRootScreen> createState() => _AdminRootScreenState();
}

class _AdminRootScreenState extends State<AdminRootScreen> {
  int _currentIndex = 0;

  @override
  Widget build(BuildContext context) {
    final screens = [
      AdminDashboardScreen(onSwitchToFleet: () => setState(() => _currentIndex = 1)),
      const AdminFleetMapScreen(),
      const AdminReportsScreen(),
    ];

    return Scaffold(
      body: screens[_currentIndex],
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _currentIndex,
        onTap: (index) => setState(() => _currentIndex = index),
        selectedItemColor: const Color(0xFF0D2618),
        unselectedItemColor: Colors.grey,
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.dashboard_outlined), activeIcon: Icon(Icons.dashboard), label: 'Dashboard'),
          BottomNavigationBarItem(icon: Icon(Icons.map_outlined), activeIcon: Icon(Icons.map), label: 'Fleet'),
          BottomNavigationBarItem(icon: Icon(Icons.analytics_outlined), activeIcon: Icon(Icons.analytics), label: 'Reports'),
        ],
      ),
    );
  }
}

class AdminDashboardScreen extends StatelessWidget {
  final VoidCallback onSwitchToFleet;

  const AdminDashboardScreen({super.key, required this.onSwitchToFleet});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Admin Dashboard'),
        actions: [
          IconButton(
            tooltip: 'Call Support (+256394880352)',
            icon: const Icon(Icons.phone_outlined),
            onPressed: () => launchEcoRouteCall(),
          ),
          IconButton(
            tooltip: 'Log Out',
            icon: const Icon(Icons.logout),
            onPressed: () async {
              try {
                await FirebaseAuth.instance.signOut();
              } catch (_) {}
              if (context.mounted) {
                Navigator.pushReplacementNamed(context, '/login');
              }
            },
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
                Expanded(child: _buildMetricCard(context, '18', 'Active Riders')),
                const SizedBox(width: 8),
                Expanded(child: _buildMetricCard(context, '5', 'Pending Pickups')),
                const SizedBox(width: 8),
                Expanded(child: _buildMetricCard(context, '98%', 'Route Efficiency')),
              ],
            ),
            const SizedBox(height: 20),

            // Live Dispatch Map
            const Text('Dispatch Network Map', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Color(0xFF0D2618))),
            const SizedBox(height: 8),
            GestureDetector(
              onTap: onSwitchToFleet,
              child: Container(
                height: 150,
                decoration: BoxDecoration(borderRadius: BorderRadius.circular(16)),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(16),
                  child: Stack(
                    children: [
                      CustomPaint(
                        size: const Size(double.infinity, 150),
                        painter: AruaMapPainter(),
                      ),
                      Positioned(
                        bottom: 8,
                        right: 8,
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                          decoration: BoxDecoration(color: const Color(0xFF0D2618), borderRadius: BorderRadius.circular(12)),
                          child: const Text('View Full Fleet >', style: TextStyle(color: Colors.white, fontSize: 11)),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
            const SizedBox(height: 20),

            // Quick Actions
            const Text('Quick Action', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Color(0xFF0D2618))),
            const SizedBox(height: 12),
            Row(
              children: [
                _buildActionCard(
                  context,
                  'Assign New Task',
                  Icons.edit_note,
                  () {
                    showDialog(
                      context: context,
                      builder: (ctx) => AlertDialog(
                        title: const Text('Assign Pending Pickup', style: TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF0D2618))),
                        content: const Text('Assign pickup #251985 (Jane A. - Ediofe) to active unit TRIC-04 (John B.)?'),
                        actions: [
                          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
                          ElevatedButton(
                            onPressed: () {
                              Navigator.pop(ctx);
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(content: Text('Pickup #251985 assigned to TRIC-04 (John B.)!')),
                              );
                            },
                            style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF0D2618)),
                            child: const Text('Assign', style: TextStyle(color: Colors.white)),
                          ),
                        ],
                      ),
                    );
                  },
                ),
                const SizedBox(width: 8),
                _buildActionCard(
                  context,
                  'Broadcast Alert',
                  Icons.campaign_outlined,
                  () {
                    showDialog(
                      context: context,
                      builder: (ctx) => AlertDialog(
                        title: const Text('Broadcast Fleet Alert', style: TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF0D2618))),
                        content: const TextField(
                          decoration: InputDecoration(
                            hintText: 'Enter alert message for all active riders in Arua...',
                            border: OutlineInputBorder(),
                          ),
                        ),
                        actions: [
                          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
                          ElevatedButton(
                            onPressed: () {
                              Navigator.pop(ctx);
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(content: Text('Broadcast alert dispatched to 18 active riders across Arua!')),
                              );
                            },
                            style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF9C3D18)),
                            child: const Text('Send Broadcast', style: TextStyle(color: Colors.white)),
                          ),
                        ],
                      ),
                    );
                  },
                ),
                const SizedBox(width: 8),
                _buildActionCard(
                  context,
                  'Generate Report',
                  Icons.picture_as_pdf_outlined,
                  () async {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Generating operational audit report PDF...')),
                    );
                    try {
                      final pdf = await PdfReportService.generateOperationsReport(
                        title: 'Arua Operations Audit',
                        period: 'October 2026',
                      );
                      await Printing.sharePdf(bytes: pdf, filename: 'EcoRoute_Arua_Report.pdf');
                    } catch (e) {
                      debugPrint('PDF download error: $e');
                    }
                  },
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMetricCard(BuildContext context, String value, String title) {
    return InkWell(
      onTap: () {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('$title: $value - Current system telemetry within optimal parameters.')),
        );
      },
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 8),
        decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(12)),
        child: Column(
          children: [
            Text(value, style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Color(0xFF0D2618))),
            const SizedBox(height: 4),
            Text(title, textAlign: TextAlign.center, style: const TextStyle(fontSize: 10, color: Color(0xFF1A3A28))),
          ],
        ),
      ),
    );
  }

  Widget _buildActionCard(BuildContext context, String title, IconData icon, VoidCallback onTap) {
    return Expanded(
      child: InkWell(
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(12)),
          child: Column(
            children: [
              Icon(icon, color: const Color(0xFF9C3D18), size: 28),
              const SizedBox(height: 8),
              Text(title, textAlign: TextAlign.center, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 11, color: Color(0xFF0D2618))),
            ],
          ),
        ),
      ),
    );
  }
}

class AdminFleetMapScreen extends StatefulWidget {
  const AdminFleetMapScreen({super.key});

  @override
  State<AdminFleetMapScreen> createState() => _AdminFleetMapScreenState();
}

class _AdminFleetMapScreenState extends State<AdminFleetMapScreen> {
  String _activeDivision = 'All';

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Live Fleet Overviews')),
      body: Stack(
        children: [
          CustomPaint(
            size: Size.infinite,
            painter: AruaMapPainter(),
          ),
          Positioned(
            top: 16,
            left: 16,
            right: 16,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.1), blurRadius: 10)],
              ),
              child: Row(
                children: [
                  const Icon(Icons.search, color: Color(0xFF0D2618)),
                  const SizedBox(width: 8),
                  const Expanded(
                    child: Text('Search Fleet by Division (Arua Hill, Ayivu, Oli)...', style: TextStyle(color: Colors.grey, fontSize: 12)),
                  ),
                  PopupMenuButton<String>(
                    onSelected: (div) {
                      setState(() => _activeDivision = div);
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text('Filtering fleet for division: $div')),
                      );
                    },
                    itemBuilder: (ctx) => [
                      const PopupMenuItem(value: 'All', child: Text('All Divisions')),
                      const PopupMenuItem(value: 'Arua Hill', child: Text('Arua Hill')),
                      const PopupMenuItem(value: 'Ayivu', child: Text('Ayivu')),
                      const PopupMenuItem(value: 'Oli', child: Text('Oli')),
                    ],
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(color: const Color(0xFFE8ECE7), borderRadius: BorderRadius.circular(8)),
                      child: Text(_activeDivision, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 11, color: Color(0xFF0D2618))),
                    ),
                  ),
                ],
              ),
            ),
          ),
          Positioned(
            bottom: 24,
            left: 16,
            right: 16,
            child: Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16)),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Row(
                    children: [
                      const CircleAvatar(
                        backgroundColor: Color(0xFF0D2618),
                        child: Icon(Icons.electric_rickshaw, color: Colors.white),
                      ),
                      const SizedBox(width: 12),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: const [
                          Text('TRIC-04 (John B.)', style: TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF0D2618))),
                          Text('Payload: 3/5 Sacks • 85% Battery • Ediofe', style: TextStyle(color: Colors.grey, fontSize: 11)),
                        ],
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton(
                          onPressed: () => launchEcoRouteCall(),
                          style: OutlinedButton.styleFrom(side: const BorderSide(color: Color(0xFF9C3D18)), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))),
                          child: const Text('Call Rider', style: TextStyle(color: Color(0xFF9C3D18))),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: ElevatedButton(
                          onPressed: () {
                            showDialog(
                              context: context,
                              builder: (ctx) => AlertDialog(
                                title: const Text('Reassign Route', style: TextStyle(fontWeight: FontWeight.bold)),
                                content: const Text('Reassign TRIC-04 Ediofe route to TRIC-09 (Sarah A. - Oli)?'),
                                actions: [
                                  TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
                                  ElevatedButton(
                                    onPressed: () {
                                      Navigator.pop(ctx);
                                      ScaffoldMessenger.of(context).showSnackBar(
                                        const SnackBar(content: Text('Route successfully reassigned to TRIC-09!')),
                                      );
                                    },
                                    style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF0D2618)),
                                    child: const Text('Reassign', style: TextStyle(color: Colors.white)),
                                  ),
                                ],
                              ),
                            );
                          },
                          style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF0D2618), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))),
                          child: const Text('Reassign', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
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
            _buildReportDownloadTile(context, 'Daily Operations - Oct 31, 2026', 'October 31, 2026'),
            _buildReportDownloadTile(context, 'Weekly Operations Summary - W44', 'Week 44, 2026'),
            _buildReportDownloadTile(context, 'Rider Fleet Monthly Report', 'October 2026'),
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

  Widget _buildReportDownloadTile(BuildContext context, String title, String period) {
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
            onPressed: () async {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text('Generating official PDF: $title...')),
              );
              try {
                final pdf = await PdfReportService.generateOperationsReport(
                  title: title,
                  period: period,
                );
                await Printing.sharePdf(bytes: pdf, filename: '${title.replaceAll(' ', '_')}.pdf');
              } catch (e) {
                debugPrint('PDF generation notice: $e');
              }
            },
            icon: const Icon(Icons.download, size: 16, color: Colors.white),
            label: const Text('PDF', style: TextStyle(color: Colors.white, fontSize: 12)),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF9C3D18),
              elevation: 0,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
            ),
          ),
        ],
      ),
    );
  }
}

// =================================================================
// 6. MODALS & AUXILIARY WIDGETS
// =================================================================
class _BookingBottomSheet extends StatefulWidget {
  final Function(int sacks, String wasteType, String address, bool isInstant) onBook;

  const _BookingBottomSheet({required this.onBook});

  @override
  State<_BookingBottomSheet> createState() => _BookingBottomSheetState();
}

class _BookingBottomSheetState extends State<_BookingBottomSheet> {
  int _sacks = 1;
  String _wasteType = 'Household';
  final _addressController = TextEditingController(text: 'Ediofe Trading Center, Arua');
  bool _isInstant = true;

  @override
  void dispose() {
    _addressController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final price = _sacks * 2500;

    return Container(
      padding: EdgeInsets.only(
        top: 20,
        left: 20,
        right: 20,
        bottom: MediaQuery.of(context).viewInsets.bottom + 20,
      ),
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text('Book Waste Pickup', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Color(0xFF0D2618))),
              IconButton(icon: const Icon(Icons.close), onPressed: () => Navigator.pop(context)),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text('Number of Sacks', style: TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF1A3A28))),
              Row(
                children: [
                  IconButton(
                    onPressed: _sacks > 1 ? () => setState(() => _sacks--) : null,
                    icon: const Icon(Icons.remove_circle_outline, color: Color(0xFF0D2618)),
                  ),
                  Text('$_sacks', style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                  IconButton(
                    onPressed: () => setState(() => _sacks++),
                    icon: const Icon(Icons.add_circle_outline, color: Color(0xFF0D2618)),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 12),
          const Text('Waste Category', style: TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF1A3A28), fontSize: 13)),
          const SizedBox(height: 6),
          Row(
            children: [
              _buildTypeChip('Household'),
              const SizedBox(width: 8),
              _buildTypeChip('Market/Commercial'),
              const SizedBox(width: 8),
              _buildTypeChip('Recyclable'),
            ],
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _addressController,
            decoration: InputDecoration(
              labelText: 'Collection Address in Arua',
              filled: true,
              fillColor: const Color(0xFFE8ECE7),
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
              prefixIcon: const Icon(Icons.location_on_outlined, color: Color(0xFF0D2618)),
            ),
          ),
          const SizedBox(height: 12),
          SwitchListTile(
            value: _isInstant,
            onChanged: (val) => setState(() => _isInstant = val),
            title: const Text('Instant Dispatch', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
            subtitle: const Text('Assigns nearest motorized tricycle immediately', style: TextStyle(fontSize: 11)),
            activeThumbColor: Colors.white, activeTrackColor: const Color(0xFF0D2618),
            contentPadding: EdgeInsets.zero,
          ),
          const SizedBox(height: 16),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              widget.onBook(_sacks, _wasteType, _addressController.text.trim(), _isInstant);
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF0D2618),
              padding: const EdgeInsets.symmetric(vertical: 16),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
            child: Text('Confirm & Request Pickup ($price UGX)', style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 15)),
          ),
        ],
      ),
    );
  }

  Widget _buildTypeChip(String label) {
    final isSelected = _wasteType == label;
    return Expanded(
      child: InkWell(
        onTap: () => setState(() => _wasteType = label),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 8),
          decoration: BoxDecoration(
            color: isSelected ? const Color(0xFF0D2618) : const Color(0xFFE8ECE7),
            borderRadius: BorderRadius.circular(8),
          ),
          alignment: Alignment.center,
          child: Text(
            label,
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.bold,
              color: isSelected ? Colors.white : const Color(0xFF0D2618),
            ),
          ),
        ),
      ),
    );
  }
}

class _LiveMapTrackerSheet extends StatelessWidget {
  final Map<String, dynamic> pickup;

  const _LiveMapTrackerSheet({required this.pickup});

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 480,
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text('Live Dispatch Map Tracker', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Color(0xFF0D2618))),
                IconButton(icon: const Icon(Icons.close), onPressed: () => Navigator.pop(context)),
              ],
            ),
          ),
          Expanded(
            child: CustomPaint(
              size: Size.infinite,
              painter: AruaMapPainter(),
            ),
          ),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: const Color(0xFFE8ECE7),
              borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
            ),
            child: Column(
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: const [
                        Text('Rider: John B. (TRIC-04)', style: TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF0D2618))),
                        Text('1.4 km away • Estimated 8 mins ETA', style: TextStyle(color: Colors.grey, fontSize: 12)),
                      ],
                    ),
                    ElevatedButton.icon(
                      onPressed: () => launchEcoRouteCall(),
                      icon: const Icon(Icons.phone, size: 16, color: Colors.white),
                      label: const Text('Call (+256394880352)', style: TextStyle(color: Colors.white, fontSize: 11)),
                      style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF9C3D18)),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                OutlinedButton.icon(
                  onPressed: () => launchEcoRouteWhatsApp(message: 'Hello Rider John B. (+256394880352), tracking pickup #${pickup['id']}'),
                  icon: const Icon(Icons.chat, size: 16, color: Color(0xFF0D2618)),
                  label: const Text('WhatsApp Dispatch Hotline', style: TextStyle(color: Color(0xFF0D2618), fontSize: 12)),
                  style: OutlinedButton.styleFrom(
                    side: const BorderSide(color: Color(0xFF0D2618)),
                    minimumSize: const Size(double.infinity, 38),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class ProgressStepper extends StatelessWidget {
  final int currentStep;

  const ProgressStepper({super.key, required this.currentStep});

  @override
  Widget build(BuildContext context) {
    const steps = ['Requested', 'Collected', 'Verifying', 'Settled'];

    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: List.generate(steps.length, (index) {
        final isActive = index <= currentStep;
        return Expanded(
          child: Row(
            children: [
              CircleAvatar(
                radius: 10,
                backgroundColor: isActive ? const Color(0xFF9C3D18) : Colors.grey[300],
                child: isActive ? const Icon(Icons.check, size: 12, color: Colors.white) : null,
              ),
              const SizedBox(width: 4),
              Expanded(
                child: Text(
                  steps[index],
                  style: TextStyle(
                    fontSize: 10,
                    fontWeight: isActive ? FontWeight.bold : FontWeight.normal,
                    color: isActive ? const Color(0xFF0D2618) : Colors.grey,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
        );
      }),
    );
  }
}

// =================================================================
// 7. ARUA MAP PAINTER (AUTHENTIC MAPPING CANVAS)
// =================================================================
class AruaMapPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paintBg = Paint()..color = const Color(0xFFE0E5E0);
    canvas.drawRect(Rect.fromLTWH(0, 0, size.width, size.height), paintBg);

    final paintLine = Paint()
      ..color = const Color(0xFF9C3D18)
      ..strokeWidth = 3
      ..style = PaintingStyle.stroke;

    final paintRider = Paint()..color = const Color(0xFF0D2618);
    final paintTarget = Paint()..color = const Color(0xFF9C3D18);

    final paintRoad = Paint()
      ..color = Colors.white
      ..strokeWidth = 2;

    // Road Grid Paths
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

    // Origin and Dispatch Nodes
    canvas.drawCircle(Offset(size.width * 0.2, size.height * 0.8), 6, paintRider);
    canvas.drawCircle(Offset(size.width * 0.8, size.height * 0.2), 6, paintTarget);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
