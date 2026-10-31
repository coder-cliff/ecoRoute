import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../core/pickup_request_repository.dart';
import '../../core/services/auth_service.dart';
import '../../core/services/router_service.dart';
import '../../core/services/waste_api_service.dart';

/// Minimalist EcoRoute twin leaf logo matching design specifications
class EcoRouteLeafLogo extends StatelessWidget {
  const EcoRouteLeafLogo({
    super.key,
    this.size = 84,
    this.color = const Color(0xFF0D2618),
  });

  final double size;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: size,
      height: size,
      child: CustomPaint(
        painter: _LeafLogoPainter(color: color),
      ),
    );
  }
}

class _LeafLogoPainter extends CustomPainter {
  const _LeafLogoPainter({required this.color});

  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.fill
      ..isAntiAlias = true;

    final w = size.width;
    final h = size.height;

    // Right leaf (larger primary leaf)
    final rightLeaf = Path();
    rightLeaf.moveTo(w * 0.46, h * 0.80);
    rightLeaf.cubicTo(
      w * 0.88, h * 0.76,
      w * 0.98, h * 0.36,
      w * 0.78, h * 0.12,
    );
    rightLeaf.cubicTo(
      w * 0.60, h * 0.22,
      w * 0.44, h * 0.48,
      w * 0.46, h * 0.80,
    );
    rightLeaf.close();
    canvas.drawPath(rightLeaf, paint);

    // Left leaf (smaller secondary leaf)
    final leftLeaf = Path();
    leftLeaf.moveTo(w * 0.42, h * 0.82);
    leftLeaf.cubicTo(
      w * 0.14, h * 0.76,
      w * 0.08, h * 0.52,
      w * 0.28, h * 0.35,
    );
    leftLeaf.cubicTo(
      w * 0.38, h * 0.42,
      w * 0.45, h * 0.58,
      w * 0.42, h * 0.82,
    );
    leftLeaf.close();
    canvas.drawPath(leftLeaf, paint);
  }

  @override
  bool shouldRepaint(covariant _LeafLogoPainter oldDelegate) =>
      oldDelegate.color != color;
}

/// 01_Splash Screen: Unified Rich Sage/Khaki surface preventing white flash
class SplashScreen extends StatefulWidget {
  const SplashScreen({
    super.key,
    required this.repository,
    this.authService,
    this.wasteApiService,
    this.splashDuration = const Duration(milliseconds: 1500),
  });

  final PickupRequestRepository repository;
  final AuthService? authService;
  final WasteApiService? wasteApiService;
  final Duration splashDuration;

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<double> _scaleAnimation;
  late final Animation<double> _fadeAnimation;
  Timer? _authVerifyTimer;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    );

    _scaleAnimation = Tween<double>(begin: 0.92, end: 1.0).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeOutCubic),
    );
    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeIn),
    );

    _controller.forward();

    // Verify session and navigate after splash animation duration
    _authVerifyTimer = Timer(widget.splashDuration, _checkAuthAndNavigate);
  }

  void _checkAuthAndNavigate() {
    if (!mounted) return;

    final user = widget.authService?.getCurrentUser();
    if (user != null) {
      // Authenticated user: automatic role-based routing
      AppRouter.routeToRole(
        context,
        role: user.role,
        repository: widget.repository,
        authService: widget.authService,
        wasteApiService: widget.wasteApiService,
      );
    } else {
      // Unauthenticated: present clean Sign-In Portal
      AppRouter.routeToLogin(
        context,
        repository: widget.repository,
        authService: widget.authService,
        wasteApiService: widget.wasteApiService,
      );
    }
  }

  @override
  void dispose() {
    _authVerifyTimer?.cancel();
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    const surfaceColor = Color(0xFFE8ECE7);
    const contentColor = Color(0xFF0D2618);

    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: const SystemUiOverlayStyle(
        statusBarColor: surfaceColor,
        statusBarIconBrightness: Brightness.dark,
        statusBarBrightness: Brightness.light,
        systemNavigationBarColor: surfaceColor,
        systemNavigationBarIconBrightness: Brightness.dark,
        systemNavigationBarDividerColor: Colors.transparent,
      ),
      child: Scaffold(
        backgroundColor: surfaceColor,
        body: Center(
          child: FadeTransition(
            opacity: _fadeAnimation,
            child: ScaleTransition(
              scale: _scaleAnimation,
              child: const Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  EcoRouteLeafLogo(size: 88, color: contentColor),
                  SizedBox(height: 16),
                  Text(
                    'EcoRoute',
                    style: TextStyle(
                      fontFamily: 'Satoshi',
                      fontSize: 34,
                      fontWeight: FontWeight.w800,
                      color: contentColor,
                      letterSpacing: -0.5,
                    ),
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

// Backward compatibility alias
typedef EcoRouteSplashScreen = SplashScreen;
