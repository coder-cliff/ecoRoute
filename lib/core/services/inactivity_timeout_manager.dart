import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../main.dart';

/// Manages automatic inactivity timeouts for high-security roles.
///
/// Per specification:
/// - Admin, Operations Manager, Route Supervisor, and Rider sessions automatically
///   expire after 10 minutes of user inactivity and return to the login screen.
/// - Residents and Guests stay logged in permanently ("for good").
class InactivityTimeoutManager extends StatefulWidget {
  const InactivityTimeoutManager({
    super.key,
    required this.child,
    this.timeoutDuration = const Duration(minutes: 10),
  });

  final Widget child;
  final Duration timeoutDuration;

  /// Global static accessor to reset inactivity timer from anywhere
  static void recordActivity() {
    _InactivityTimeoutManagerState._instance?._resetTimer();
  }

  @override
  State<InactivityTimeoutManager> createState() => _InactivityTimeoutManagerState();
}

class _InactivityTimeoutManagerState extends State<InactivityTimeoutManager> {
  static _InactivityTimeoutManagerState? _instance;
  Timer? _periodicCheckTimer;
  DateTime _lastActivityTime = DateTime.now();
  final FocusNode _focusNode = FocusNode();

  @override
  void initState() {
    super.initState();
    _instance = this;
    _startMonitoring();
  }

  void _startMonitoring() {
    _periodicCheckTimer?.cancel();
    _periodicCheckTimer = Timer.periodic(const Duration(seconds: 15), (timer) {
      _checkInactivity();
    });
  }

  void _resetTimer() {
    _lastActivityTime = DateTime.now();
  }

  void _checkInactivity() {
    final state = EcoRouteState.instance;

    // Only apply strict timeout to Admin tier and Riders
    final role = state.currentRole.toLowerCase();
    final isSecuredRole = state.isAdminTier ||
        role == 'rider' ||
        role == 'admin' ||
        role == 'manager' ||
        role == 'supervisor' ||
        role == 'routesupervisor' ||
        role == 'operationsmanager';

    if (!isSecuredRole) {
      // Residents and Guests stay logged in permanently
      return;
    }

    final idleDuration = DateTime.now().difference(_lastActivityTime);
    if (idleDuration >= widget.timeoutDuration) {
      _handleSessionTimeout();
    }
  }

  void _handleSessionTimeout() {
    _resetTimer();
    final navContext = EcoRouteState.navigatorKey.currentContext ?? context;

    // Reset session in state
    EcoRouteState.instance.signOut();

    // Navigate to Login screen
    EcoRouteState.navigatorKey.currentState?.pushNamedAndRemoveUntil(
      '/login',
      (route) => false,
    );

    // Show warning notification
    if (navContext.mounted) {
      ScaffoldMessenger.of(navContext).showSnackBar(
        const SnackBar(
          content: Row(
            children: [
              Icon(Icons.security, color: Colors.white, size: 20),
              SizedBox(width: 10),
              Expanded(
                child: Text(
                  'Session timed out after 10 minutes of inactivity for security.',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
              ),
            ],
          ),
          backgroundColor: Color(0xFF991B1B),
          duration: Duration(seconds: 5),
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  @override
  void dispose() {
    if (_instance == this) _instance = null;
    _periodicCheckTimer?.cancel();
    _focusNode.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Listener(
      behavior: HitTestBehavior.translucent,
      onPointerDown: (_) => _resetTimer(),
      onPointerMove: (_) => _resetTimer(),
      onPointerHover: (_) => _resetTimer(),
      onPointerSignal: (_) => _resetTimer(),
      child: KeyboardListener(
        focusNode: _focusNode,
        onKeyEvent: (event) {
          if (event is KeyDownEvent) {
            _resetTimer();
          }
        },
        child: widget.child,
      ),
    );
  }
}
