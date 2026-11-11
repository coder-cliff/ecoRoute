import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:image_picker/image_picker.dart';
import 'package:intl/intl.dart';
import 'package:latlong2/latlong.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../core/layout/adaptive_layout.dart';
import '../../core/services/auth_service.dart';
import '../../core/theme/eco_palette.dart';
import '../../main.dart';
import '../common/widgets/slide_to_confirm_widget.dart';

/// Rider Job Execution Phase
enum _RiderJobPhase {
  idle,       // Home Dashboard: Waiting for dispatch (Image 2, Screen 1)
  incoming,   // Incoming dispatch popup (Specs 4.1)
  enRoute,    // In transit & Navigation to Client (Image 1, Screen 3)
  arrived,    // Arrived at Client: Photo evidence capture + Swipe to Complete (Specs 4.3)
  completed,  // Task completed successfully with earnings breakdown (Image 1, Screen 4)
}

/// Responsive Rider Field Operations Dashboard:
/// Conforms strictly to ecoRoute Rider App Specifications and Design Blueprints
/// (Image 1: Activation, Approval, Active Task, Completed; Image 2: Home, Schedule, Account)
class ResponsiveRiderDashboard extends StatefulWidget {
  const ResponsiveRiderDashboard({super.key});

  @override
  State<ResponsiveRiderDashboard> createState() =>
      _ResponsiveRiderDashboardState();
}

class _ResponsiveRiderDashboardState extends State<ResponsiveRiderDashboard>
    with SingleTickerProviderStateMixin {
  // Navigation Tabs: 0: Home, 1: Schedule, 2: Account (Image 2)
  int _currentTabIndex = 0;

  // Job Execution Phase (Image 1 & Specs Section 4)
  _RiderJobPhase _jobPhase = _RiderJobPhase.idle;

  // Active Task Data
  Map<String, dynamic>? _activeJob;
  String? _wastePhotoBase64;
  DateTime? _jobStartTime;
  int _jobDurationMinutes = 18;

  // Today's Performance Metrics
  int _completedTasksToday = 0;
  int _todaysEarnings = 0;

  // Schedule View: Weekly vs Monthly
  bool _isWeeklySchedule = true;
  DateTime _selectedDate = DateTime.now();

  // Radar Pulse Animation for Idle Map
  late AnimationController _pulseController;
  late Animation<double> _pulseAnimation;

  // Coordinates in Arua City
  static const LatLng _aruaRiderPosition = LatLng(3.0285, 30.9090); // Rider Start (Point A)
  static const LatLng _aruaClientPosition = LatLng(3.0360, 30.9165); // Client (Point B: Block 3, Arua Hill)

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    )..repeat(reverse: true);

    _pulseAnimation = Tween<double>(begin: 0.85, end: 1.25).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );

    _checkInitialTasks();
  }

  @override
  void dispose() {
    _pulseController.dispose();
    super.dispose();
  }

  void _checkInitialTasks() {
    final state = EcoRouteState.instance;
    if (state.riderTasks.isNotEmpty) {
      final task = state.riderTasks.first;
      final status = (task['status'] as String? ?? '').toLowerCase();
      if (status == 'en-route' || status == 'in transit' || status == 'dispatched') {
        _activeJob = task;
        _jobPhase = _RiderJobPhase.enRoute;
        _jobStartTime = DateTime.now().subtract(const Duration(minutes: 5));
      } else if (status == 'arrived') {
        _activeJob = task;
        _jobPhase = _RiderJobPhase.arrived;
      }
    }
  }

  // =========================================================================
  // ACTIONS: JOB WORKFLOW
  // =========================================================================

  void _acceptIncomingJob(Map<String, dynamic> job) {
    setState(() {
      _activeJob = job;
      _jobPhase = _RiderJobPhase.enRoute;
      _jobStartTime = DateTime.now();
      _wastePhotoBase64 = null;
    });

    final state = EcoRouteState.instance;
    final idx = state.riderTasks.indexWhere((t) => t['id'] == job['id']);
    if (idx != -1) {
      state.riderTasks[idx]['status'] = 'In Transit';
    }
  }

  void _declineIncomingJob() {
    setState(() {
      _jobPhase = _RiderJobPhase.idle;
      _activeJob = null;
    });
  }

  void _handleRiderArrived() {
    setState(() {
      _jobPhase = _RiderJobPhase.arrived;
    });

    final state = EcoRouteState.instance;
    if (_activeJob != null) {
      final idx = state.riderTasks.indexWhere((t) => t['id'] == _activeJob!['id']);
      if (idx != -1) {
        state.riderTasks[idx]['status'] = 'Arrived';
      }
    }
  }

  Future<void> _captureWasteEvidence() async {
    try {
      final picker = ImagePicker();
      final photo = await picker.pickImage(
        source: ImageSource.camera,
        maxWidth: 800,
        maxHeight: 800,
        imageQuality: 65,
      );

      if (photo != null) {
        final bytes = await photo.readAsBytes();
        setState(() {
          _wastePhotoBase64 = base64Encode(bytes);
        });

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('✓ Waste photo evidence locked to pickup order.'),
              backgroundColor: Color(0xFF1B5E20),
              duration: Duration(seconds: 2),
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Camera notice: $e')),
        );
      }
    }
  }

  void _completeActiveJob() {
    if (_jobStartTime != null) {
      _jobDurationMinutes = DateTime.now().difference(_jobStartTime!).inMinutes;
      if (_jobDurationMinutes < 1) _jobDurationMinutes = 18;
    } else {
      _jobDurationMinutes = 18;
    }

    final rawPrice = _activeJob?['price'] ?? _activeJob?['expectedEarnings'] ?? 15000;
    final int earnings = (rawPrice is num) ? rawPrice.toInt() : 15000;

    setState(() {
      _completedTasksToday += 1;
      _todaysEarnings += earnings;
      _jobPhase = _RiderJobPhase.completed;
    });

    final state = EcoRouteState.instance;
    state.riderLedgerBalance += earnings;

    if (_activeJob != null) {
      final idx = state.riderTasks.indexWhere((t) => t['id'] == _activeJob!['id']);
      if (idx != -1) {
        state.riderTasks[idx]['status'] = 'Completed';
        state.riderTasks[idx]['photoEvidence'] = _wastePhotoBase64;
      }
    }
  }

  void _resetToNextJob() {
    setState(() {
      _jobPhase = _RiderJobPhase.idle;
      _activeJob = null;
      _wastePhotoBase64 = null;
    });
  }

  void _requestOpenDispatch() {
    final state = EcoRouteState.instance;

    // Look for pending unassigned resident request
    final pendingReq = state.residentRequests.firstWhere(
      (r) => (r['status'] as String? ?? '').toLowerCase() == 'requested',
      orElse: () => <String, dynamic>{},
    );

    if (pendingReq.isNotEmpty) {
      final newJob = <String, dynamic>{
        'id': pendingReq['id']?.toString().replaceAll('Pickup #', '') ?? 'ER${DateTime.now().millisecondsSinceEpoch % 100000}',
        'client': state.userName.isNotEmpty ? state.userName : 'Ayiko Gift',
        'address': pendingReq['address'] ?? 'Block 3, Arua Hill',
        'wasteType': pendingReq['wasteType'] ?? 'General Commercial Waste',
        'distance': '1.8 km',
        'expectedEarnings': pendingReq['price'] ?? 15000,
        'status': 'Dispatched',
        'sacks': pendingReq['sacks'] ?? 3,
        'phone': '+256700000000',
      };

      setState(() {
        _activeJob = newJob;
        _jobPhase = _RiderJobPhase.incoming;
        _currentTabIndex = 0; // Switch to Home
      });
    } else {
      // Create active on-demand commercial job
      final newId = (DateTime.now().millisecondsSinceEpoch % 90000 + 10000).toString();
      final onDemandJob = <String, dynamic>{
        'id': newId,
        'client': 'Ayiko Gift',
        'address': 'Block 3, Arua Hill',
        'wasteType': 'General Waste Pickup Block 3',
        'distance': '1.8 km',
        'expectedEarnings': 15000,
        'status': 'Dispatched',
        'sacks': 2,
        'phone': '+256700000000',
      };

      setState(() {
        _activeJob = onDemandJob;
        _jobPhase = _RiderJobPhase.incoming;
        _currentTabIndex = 0; // Switch to Home
      });
    }
  }

  Future<void> _callCustomer(String phone) async {
    final clean = phone.replaceAll(RegExp(r'\s+'), '');
    final uri = Uri.parse('tel:$clean');
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri);
    } else {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Dialer intent initiated for $clean')),
        );
      }
    }
  }

  // =========================================================================
  // MAIN BUILD DISPATCHER
  // =========================================================================
  @override
  Widget build(BuildContext context) {
    final isDark = AntigravityTheme.isDark(context);
    final surfaceColor = isDark ? const Color(0xFF101913) : const Color(0xFFF8FAFC);

    // If an active task is running, show the dedicated Active Task or Completed Screen
    if (_currentTabIndex == 0) {
      if (_jobPhase == _RiderJobPhase.enRoute || _jobPhase == _RiderJobPhase.arrived) {
        return Scaffold(
          backgroundColor: surfaceColor,
          body: SafeArea(child: _buildActiveTaskScreen(context, isDark)),
          bottomNavigationBar: _buildBottomNav(context, isDark),
        );
      } else if (_jobPhase == _RiderJobPhase.completed) {
        return Scaffold(
          backgroundColor: surfaceColor,
          body: SafeArea(child: _buildCompletedTaskScreen(context, isDark)),
          bottomNavigationBar: _buildBottomNav(context, isDark),
        );
      }
    }

    return Scaffold(
      backgroundColor: surfaceColor,
      body: SafeArea(
        child: IndexedStack(
          index: _currentTabIndex,
          children: [
            _buildHomeDashboard(context, isDark),
            _buildShiftScheduleScreen(context, isDark),
            _buildRiderAccountScreen(context, isDark),
          ],
        ),
      ),
      bottomNavigationBar: _buildBottomNav(context, isDark),
    );
  }

  // =========================================================================
  // BOTTOM NAVIGATION BAR (STRICT 3-TAB LAYOUT: HOME, SCHEDULE, ACCOUNT)
  // =========================================================================
  Widget _buildBottomNav(BuildContext context, bool isDark) {
    const brandGreen = Color(0xFF1B5E20);
    const unselectedColor = Color(0xFF94A3B8);

    return Container(
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E293B) : Colors.white,
        border: Border(
          top: BorderSide(
            color: isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0),
            width: 1,
          ),
        ),
      ),
      child: BottomNavigationBar(
        currentIndex: _currentTabIndex,
        onTap: (index) {
          setState(() {
            _currentTabIndex = index;
          });
        },
        backgroundColor: Colors.transparent,
        elevation: 0,
        selectedItemColor: brandGreen,
        unselectedItemColor: unselectedColor,
        selectedLabelStyle: const TextStyle(fontWeight: FontWeight.bold, fontSize: 11),
        unselectedLabelStyle: const TextStyle(fontWeight: FontWeight.w500, fontSize: 11),
        type: BottomNavigationBarType.fixed,
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.home_outlined),
            activeIcon: Icon(Icons.home),
            label: 'Home',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.calendar_month_outlined),
            activeIcon: Icon(Icons.calendar_month),
            label: 'Schedule',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.person_outline),
            activeIcon: Icon(Icons.person),
            label: 'Account',
          ),
        ],
      ),
    );
  }

  // =========================================================================
  // TAB 1: HOME DASHBOARD (IMAGE 2, SCREEN 1)
  // =========================================================================
  Widget _buildHomeDashboard(BuildContext context, bool isDark) {
    final state = EcoRouteState.instance;
    const brandGreen = Color(0xFF1B5E20);
    const darkGreen = Color(0xFF0F3822);
    const textColor = Color(0xFF1E293B);
    const subtextColor = Color(0xFF64748B);

    final riderName = state.userName.isNotEmpty
        ? state.userName.split(' ').first
        : (state.userEmail.isNotEmpty ? state.userEmail.split('@').first : 'Ayiko');

    return Stack(
      children: [
        Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Top Bar: ecoRoute Rider + Online Status Toggle (Image 2, Screen 1)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
              color: isDark ? const Color(0xFF1E293B) : Colors.white,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'ecoRoute Rider',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w800,
                      color: textColor,
                      letterSpacing: -0.3,
                    ),
                  ),

                  // Online Toggle Pill
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: state.isRiderShiftActive
                          ? const Color(0xFFE8F5E9)
                          : const Color(0xFFF1F5F9),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(
                        color: state.isRiderShiftActive
                            ? const Color(0xFFA5D6A7)
                            : const Color(0xFFCBD5E1),
                      ),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Container(
                          width: 8,
                          height: 8,
                          decoration: BoxDecoration(
                            color: state.isRiderShiftActive
                                ? const Color(0xFF2E7D32)
                                : const Color(0xFF94A3B8),
                            shape: BoxShape.circle,
                          ),
                        ),
                        const SizedBox(width: 6),
                        Text(
                          state.isRiderShiftActive ? 'ONLINE' : 'OFFLINE',
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.bold,
                            color: state.isRiderShiftActive
                                ? const Color(0xFF2E7D32)
                                : const Color(0xFF64748B),
                            letterSpacing: 0.5,
                          ),
                        ),
                        const SizedBox(width: 4),
                        SizedBox(
                          height: 24,
                          width: 36,
                          child: Switch(
                            value: state.isRiderShiftActive,
                            activeColor: const Color(0xFF2E7D32),
                            activeTrackColor: const Color(0xFFA5D6A7),
                            materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                            onChanged: (val) {
                              setState(() {
                                state.isRiderShiftActive = val;
                              });
                            },
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            // Welcome Card + Daily Performance Summary
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
              child: Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: isDark ? const Color(0xFF1E293B) : Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.04),
                      blurRadius: 10,
                      offset: const Offset(0, 3),
                    ),
                  ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Welcome back, $riderName!',
                      style: TextStyle(
                        fontSize: 17,
                        fontWeight: FontWeight.bold,
                        color: isDark ? Colors.white : textColor,
                      ),
                    ),
                    const SizedBox(height: 2),
                    const Text(
                      "Ready for today's dispatches",
                      style: TextStyle(fontSize: 12.5, color: subtextColor),
                    ),
                    const SizedBox(height: 16),

                    // Metrics Row
                    Row(
                      children: [
                        // Metric 1: Daily Summary
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                'Daily Summary:',
                                style: TextStyle(fontSize: 11, color: subtextColor),
                              ),
                              const SizedBox(height: 4),
                              RichText(
                                text: TextSpan(
                                  children: [
                                    TextSpan(
                                      text: '$_completedTasksToday / 8 ',
                                      style: TextStyle(
                                        fontSize: 18,
                                        fontWeight: FontWeight.w800,
                                        color: isDark ? Colors.white : textColor,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              const Text(
                                'Tasks Completed',
                                style: TextStyle(fontSize: 10.5, color: subtextColor),
                              ),
                            ],
                          ),
                        ),

                        Container(width: 1, height: 40, color: const Color(0xFFE2E8F0)),
                        const SizedBox(width: 16),

                        // Metric 2: Today's Earnings
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                "Today's Earnings:",
                                style: TextStyle(fontSize: 11, color: subtextColor),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                'UGX ${NumberFormat('#,###').format(_todaysEarnings)}',
                                style: const TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.w800,
                                  color: textColor,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),

            // Live Map View (OpenStreetMap vector canvas with Pulse Radar)
            Expanded(
              child: Stack(
                children: [
                  FlutterMap(
                    options: const MapOptions(
                      initialCenter: _aruaRiderPosition,
                      initialZoom: 14.8,
                    ),
                    children: [
                      TileLayer(
                        urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                        userAgentPackageName: 'org.ecoroute.app',
                      ),
                      MarkerLayer(
                        markers: [
                          Marker(
                            point: _aruaRiderPosition,
                            width: 60,
                            height: 60,
                            child: AnimatedBuilder(
                              animation: _pulseAnimation,
                              builder: (context, child) {
                                return Stack(
                                  alignment: Alignment.center,
                                  children: [
                                    Container(
                                      width: 44 * _pulseAnimation.value,
                                      height: 44 * _pulseAnimation.value,
                                      decoration: BoxDecoration(
                                        color: const Color(0xFF2E7D32).withOpacity(0.25),
                                        shape: BoxShape.circle,
                                      ),
                                    ),
                                    Container(
                                      width: 24,
                                      height: 24,
                                      decoration: const BoxDecoration(
                                        color: Color(0xFF1B5E20),
                                        shape: BoxShape.circle,
                                      ),
                                      child: const Icon(Icons.location_on, color: Colors.white, size: 16),
                                    ),
                                  ],
                                );
                              },
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),

                  // Floating Idle Banner: "Waiting for dispatch..."
                  if (_jobPhase == _RiderJobPhase.idle)
                    Positioned(
                      left: 20,
                      right: 20,
                      bottom: 24,
                      child: Center(
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                          decoration: BoxDecoration(
                            color: state.isRiderShiftActive
                                ? const Color(0xFFC8E6C9).withOpacity(0.92)
                                : const Color(0xFFE2E8F0).withOpacity(0.92),
                            borderRadius: BorderRadius.circular(24),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withOpacity(0.08),
                                blurRadius: 10,
                                offset: const Offset(0, 4),
                              ),
                            ],
                          ),
                          child: Text(
                            state.isRiderShiftActive
                                ? 'Waiting for dispatch...'
                                : 'You are currently Offline',
                            style: TextStyle(
                              fontSize: 13.5,
                              fontWeight: FontWeight.bold,
                              color: state.isRiderShiftActive
                                  ? const Color(0xFF1B5E20)
                                  : const Color(0xFF475569),
                            ),
                          ),
                        ),
                      ),
                    ),
                ],
              ),
            ),
          ],
        ),

        // Incoming Job Dispatch Popup Card (Specs Section 4.1)
        if (_jobPhase == _RiderJobPhase.incoming && _activeJob != null)
          _buildIncomingJobModal(context, isDark),
      ],
    );
  }

  // =========================================================================
  // INCOMING JOB DISPATCH CARD (SPECS SECTION 4.1)
  // =========================================================================
  Widget _buildIncomingJobModal(BuildContext context, bool isDark) {
    const brandGreen = Color(0xFF1B5E20);
    const textColor = Color(0xFF1E293B);
    const subtextColor = Color(0xFF64748B);

    final client = _activeJob?['client'] ?? 'Ayiko Gift';
    final location = _activeJob?['address'] ?? 'Block 3, Arua Hill';
    final distance = _activeJob?['distance'] ?? '1.8 km';
    final rawPrice = _activeJob?['expectedEarnings'] ?? _activeJob?['price'] ?? 15000;
    final int earnings = (rawPrice is num) ? rawPrice.toInt() : 15000;

    return Container(
      color: Colors.black45,
      alignment: Alignment.bottomCenter,
      child: Container(
        margin: const EdgeInsets.all(16),
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: isDark ? const Color(0xFF1E293B) : Colors.white,
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.15),
              blurRadius: 20,
              offset: const Offset(0, -4),
            ),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Row(
                  children: [
                    Icon(Icons.notifications_active, color: Color(0xFFF57C00), size: 20),
                    SizedBox(width: 8),
                    Text(
                      'Incoming Job Dispatch',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: textColor,
                      ),
                    ),
                  ],
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: const Color(0xFFFFF3E0),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: const Text(
                    'Commercial Run',
                    style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Color(0xFFE65100)),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 14),

            // Client and Address
            Text(
              'Client: $client',
              style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: textColor),
            ),
            const SizedBox(height: 4),
            Text(
              location,
              style: const TextStyle(fontSize: 13, color: subtextColor),
            ),
            const SizedBox(height: 12),

            // Distance & Expected Earnings
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: const Color(0xFFE8F5E9),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      const Icon(Icons.route, size: 18, color: brandGreen),
                      const SizedBox(width: 6),
                      Text('Distance: $distance', style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: brandGreen)),
                    ],
                  ),
                  Text(
                    'UGX ${NumberFormat('#,###').format(earnings)}',
                    style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: brandGreen),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 18),

            // Action Buttons: ACCEPT JOB or DECLINE
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: _declineIncomingJob,
                    style: OutlinedButton.styleFrom(
                      foregroundColor: Colors.red,
                      side: const BorderSide(color: Colors.red),
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                    child: const Text('DECLINE', style: TextStyle(fontWeight: FontWeight.bold)),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  flex: 2,
                  child: ElevatedButton(
                    onPressed: () => _acceptIncomingJob(_activeJob!),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: brandGreen,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      elevation: 0,
                    ),
                    child: const Text('ACCEPT JOB', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  // =========================================================================
  // ACTIVE TASK SCREEN (TRANSIT & NAVIGATION - EXACTLY MATCHES IMAGE 1, SCREEN 3)
  // =========================================================================
  Widget _buildActiveTaskScreen(BuildContext context, bool isDark) {
    const brandGreen = Color(0xFF1B5E20);
    const brightGreen = Color(0xFF00C853);
    const textColor = Color(0xFF1E293B);
    const subtextColor = Color(0xFF64748B);

    final client = _activeJob?['client'] ?? 'Ayiko Gift';
    final location = _activeJob?['address'] ?? 'Block 3, Arua Hill';
    final phone = _activeJob?['phone'] ?? '+256700000000';

    return Stack(
      children: [
        Column(
          children: [
            // Header: Hamburger Menu + ecoRoute Map (Image 1, Screen 3)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              color: isDark ? const Color(0xFF1E293B) : Colors.white,
              child: Row(
                children: [
                  IconButton(
                    icon: const Icon(Icons.menu, color: textColor),
                    onPressed: () {
                      Scaffold.of(context).openDrawer();
                    },
                  ),
                  const SizedBox(width: 4),
                  const Text(
                    'ecoRoute Map',
                    style: TextStyle(
                      fontSize: 17,
                      fontWeight: FontWeight.bold,
                      color: textColor,
                    ),
                  ),
                ],
              ),
            ),

            // Map View with Polyline Route (Point A to Point B)
            Expanded(
              child: Stack(
                children: [
                  FlutterMap(
                    options: const MapOptions(
                      initialCenter: LatLng(3.0322, 30.9127),
                      initialZoom: 14.5,
                    ),
                    children: [
                      TileLayer(
                        urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                        userAgentPackageName: 'org.ecoroute.app',
                      ),
                      // Polyline connecting Point A to Point B
                      PolylineLayer(
                        polylines: [
                          Polyline(
                            points: const [
                              _aruaRiderPosition,
                              LatLng(3.0310, 30.9120),
                              LatLng(3.0340, 30.9140),
                              _aruaClientPosition,
                            ],
                            strokeWidth: 5.0,
                            color: brightGreen,
                          ),
                        ],
                      ),
                      // Markers A and B
                      MarkerLayer(
                        markers: [
                          // Point A: Rider
                          Marker(
                            point: _aruaRiderPosition,
                            width: 32,
                            height: 32,
                            child: Container(
                              decoration: const BoxDecoration(
                                color: brightGreen,
                                shape: BoxShape.circle,
                              ),
                              child: const Center(
                                child: Text('A', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 13)),
                              ),
                            ),
                          ),
                          // Point B: Client
                          Marker(
                            point: _aruaClientPosition,
                            width: 32,
                            height: 32,
                            child: Container(
                              decoration: const BoxDecoration(
                                color: Color(0xFF1E293B),
                                shape: BoxShape.circle,
                              ),
                              child: const Center(
                                child: Text('B', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 13)),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),

                  // Floating Top Card: Client Info (Image 1, Screen 3)
                  Positioned(
                    top: 14,
                    left: 16,
                    right: 16,
                    child: Container(
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        color: isDark ? const Color(0xFF1E293B) : Colors.white,
                        borderRadius: BorderRadius.circular(16),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.08),
                            blurRadius: 12,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      child: Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(10),
                            decoration: BoxDecoration(
                              color: const Color(0xFFE2E8F0),
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: const Icon(Icons.location_on, size: 20, color: Color(0xFF1E293B)),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Client: $client',
                                  style: const TextStyle(
                                    fontSize: 14,
                                    fontWeight: FontWeight.bold,
                                    color: textColor,
                                  ),
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  location,
                                  style: const TextStyle(fontSize: 12, color: subtextColor),
                                ),
                                const SizedBox(height: 2),
                                const Text(
                                  'Task status: En-Route to Pickup',
                                  style: TextStyle(
                                    fontSize: 11,
                                    fontWeight: FontWeight.w600,
                                    color: Color(0xFF2E7D32),
                                  ),
                                ),
                              ],
                            ),
                          ),
                          IconButton(
                            icon: const Icon(Icons.phone, color: Color(0xFF2E7D32)),
                            onPressed: () => _callCustomer(phone),
                          ),
                        ],
                      ),
                    ),
                  ),

                  // GPS Crosshair Button
                  Positioned(
                    right: 16,
                    bottom: 16,
                    child: Container(
                      decoration: BoxDecoration(
                        color: Colors.white,
                        shape: BoxShape.circle,
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.12),
                            blurRadius: 6,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      child: IconButton(
                        icon: const Icon(Icons.my_location, color: Color(0xFF1E293B), size: 20),
                        onPressed: () {},
                      ),
                    ),
                  ),
                ],
              ),
            ),

            // Bottom Turn-by-Turn Instruction Card & Action (Image 1, Screen 3)
            Container(
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 20),
              decoration: BoxDecoration(
                color: isDark ? const Color(0xFF1E293B) : Colors.white,
                borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.06),
                    blurRadius: 10,
                    offset: const Offset(0, -3),
                  ),
                ],
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Turn-by-Turn Row
                  const Row(
                    children: [
                      Icon(Icons.arrow_upward, size: 28, color: Color(0xFF1E293B)),
                      SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Head North on Gulu Rd',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                                color: textColor,
                              ),
                            ),
                            SizedBox(height: 2),
                            Text(
                              'En-Route to Pickup',
                              style: TextStyle(fontSize: 12, color: subtextColor),
                            ),
                          ],
                        ),
                      ),
                      Text(
                        '500m',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: textColor,
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 18),

                  // Action: I HAVE ARRIVED or Evidence Capture + SWIPE TO COMPLETE
                  if (_jobPhase == _RiderJobPhase.enRoute) ...[
                    SizedBox(
                      width: double.infinity,
                      height: 52,
                      child: ElevatedButton.icon(
                        onPressed: _handleRiderArrived,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF00C853),
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(26)),
                          elevation: 0,
                        ),
                        icon: const Icon(Icons.check, size: 22),
                        label: const Text(
                          'I HAVE ARRIVED',
                          style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold, letterSpacing: 0.5),
                        ),
                      ),
                    ),
                  ] else if (_jobPhase == _RiderJobPhase.arrived) ...[
                    // Photo Evidence Mandatory Step (Specs Section 4.3)
                    if (_wastePhotoBase64 == null) ...[
                      SizedBox(
                        width: double.infinity,
                        height: 50,
                        child: OutlinedButton.icon(
                          onPressed: _captureWasteEvidence,
                          style: OutlinedButton.styleFrom(
                            foregroundColor: brandGreen,
                            side: const BorderSide(color: brandGreen, width: 1.5),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                          ),
                          icon: const Icon(Icons.camera_alt, size: 20),
                          label: const Text('Capture Waste Photo (Mandatory Evidence)', style: TextStyle(fontWeight: FontWeight.bold)),
                        ),
                      ),
                    ] else ...[
                      Row(
                        children: [
                          ClipRRect(
                            borderRadius: BorderRadius.circular(8),
                            child: Image.memory(
                              base64Decode(_wastePhotoBase64!),
                              width: 48,
                              height: 48,
                              fit: BoxFit.cover,
                            ),
                          ),
                          const SizedBox(width: 10),
                          const Expanded(
                            child: Text(
                              '✓ Photo Evidence Locked',
                              style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: Color(0xFF2E7D32)),
                            ),
                          ),
                          TextButton(
                            onPressed: _captureWasteEvidence,
                            child: const Text('Retake', style: TextStyle(fontSize: 12, color: subtextColor)),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      // Swipe To Complete Slider
                      SlideToConfirmWidget(
                        label: 'SWIPE TO COMPLETE',
                        onConfirmed: _completeActiveJob,
                        sliderColor: const Color(0xFF00C853),
                        backgroundColor: const Color(0xFFE8F5E9),
                      ),
                    ],
                  ],
                ],
              ),
            ),
          ],
        ),
      ],
    );
  }

  // =========================================================================
  // COMPLETED TASK SCREEN (EARNINGS & RESET - EXACTLY MATCHES IMAGE 1, SCREEN 4)
  // =========================================================================
  Widget _buildCompletedTaskScreen(BuildContext context, bool isDark) {
    const textColor = Color(0xFF0F172A);
    const subtextColor = Color(0xFF64748B);
    const darkButtonBg = Color(0xFF1E293B);

    final jobId = _activeJob?['id'] ?? 'ER89423';
    final rawPrice = _activeJob?['expectedEarnings'] ?? _activeJob?['price'] ?? 15000;
    final int earnings = (rawPrice is num) ? rawPrice.toInt() : 15000;

    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          // Header: Hamburger + ecoRoute Map (Image 1, Screen 4)
          Row(
            children: [
              IconButton(
                icon: const Icon(Icons.menu, color: textColor),
                onPressed: () => Scaffold.of(context).openDrawer(),
              ),
              const SizedBox(width: 4),
              const Text(
                'ecoRoute Map',
                style: TextStyle(
                  fontSize: 17,
                  fontWeight: FontWeight.bold,
                  color: textColor,
                ),
              ),
            ],
          ),

          const SizedBox(height: 36),

          // Big Green Circle Checkmark
          Container(
            width: 80,
            height: 80,
            decoration: const BoxDecoration(
              color: Color(0xFF00C853),
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.check,
              size: 48,
              color: Colors.white,
            ),
          ),

          const SizedBox(height: 24),

          // Title: Task Completed successfully!
          const Text(
            'Task Completed\nsuccessfully!',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.w800,
              color: textColor,
              letterSpacing: -0.5,
              height: 1.25,
            ),
          ),

          const SizedBox(height: 24),

          // Job Details Card: Job ID & Duration
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
            decoration: BoxDecoration(
              color: isDark ? const Color(0xFF1E293B) : const Color(0xFFF8FAFC),
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: const Color(0xFFE2E8F0)),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('Job ID:', style: TextStyle(fontSize: 12, color: subtextColor)),
                    const SizedBox(height: 4),
                    const Text('Duration:', style: TextStyle(fontSize: 12, color: subtextColor)),
                  ],
                ),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      '#$jobId',
                      style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: textColor),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '$_jobDurationMinutes mins',
                      style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: textColor),
                    ),
                  ],
                ),
              ],
            ),
          ),

          const SizedBox(height: 16),

          // Earnings Secured Highlight Card (Soft green background)
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 16),
            decoration: BoxDecoration(
              color: const Color(0xFFE8F5E9),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Column(
              children: [
                const Text(
                  'Earnings Secured:',
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF2E7D32),
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  'UGX ${NumberFormat('#,###').format(earnings)}',
                  style: const TextStyle(
                    fontSize: 26,
                    fontWeight: FontWeight.w900,
                    color: Color(0xFF1B5E20),
                    letterSpacing: -0.5,
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 36),

          // Action Button: Ready for Next Job (Large dark button)
          SizedBox(
            width: double.infinity,
            height: 52,
            child: ElevatedButton(
              onPressed: _resetToNextJob,
              style: ElevatedButton.styleFrom(
                backgroundColor: darkButtonBg,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(26)),
                elevation: 0,
              ),
              child: const Text(
                'Ready for Next Job',
                style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold),
              ),
            ),
          ),

          const SizedBox(height: 16),
        ],
      ),
    );
  }

  // =========================================================================
  // TAB 2: SHIFT SCHEDULE (UPCOMING OPERATIONS - EXACTLY MATCHES IMAGE 2, SCREEN 2)
  // =========================================================================
  Widget _buildShiftScheduleScreen(BuildContext context, bool isDark) {
    const brandGreen = Color(0xFF1B5E20);
    const textColor = Color(0xFF1E293B);
    const subtextColor = Color(0xFF64748B);
    const darkButtonBg = Color(0xFF1E293B);

    final now = DateTime.now();
    final weekStart = now.subtract(Duration(days: now.weekday % 7)); // Sunday start

    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          // Header: My Schedule (Image 2, Screen 2)
          const Text(
            'My Schedule',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w800,
              color: textColor,
            ),
          ),

          const SizedBox(height: 16),

          // Segmented Toggle: Weekly vs Monthly
          Container(
            padding: const EdgeInsets.all(4),
            decoration: BoxDecoration(
              color: isDark ? const Color(0xFF1E293B) : const Color(0xFFF1F5F9),
              borderRadius: BorderRadius.circular(24),
            ),
            child: Row(
              children: [
                Expanded(
                  child: InkWell(
                    onTap: () => setState(() => _isWeeklySchedule = true),
                    borderRadius: BorderRadius.circular(20),
                    child: Container(
                      padding: const EdgeInsets.symmetric(vertical: 8),
                      decoration: BoxDecoration(
                        color: _isWeeklySchedule ? Colors.white : Colors.transparent,
                        borderRadius: BorderRadius.circular(20),
                        boxShadow: _isWeeklySchedule
                            ? [
                                BoxShadow(
                                  color: Colors.black.withOpacity(0.06),
                                  blurRadius: 4,
                                  offset: const Offset(0, 2),
                                ),
                              ]
                            : null,
                      ),
                      child: Text(
                        'Weekly',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.bold,
                          color: _isWeeklySchedule ? textColor : subtextColor,
                        ),
                      ),
                    ),
                  ),
                ),
                Expanded(
                  child: InkWell(
                    onTap: () => setState(() => _isWeeklySchedule = false),
                    borderRadius: BorderRadius.circular(20),
                    child: Container(
                      padding: const EdgeInsets.symmetric(vertical: 8),
                      decoration: BoxDecoration(
                        color: !_isWeeklySchedule ? brandGreen : Colors.transparent,
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text(
                        'Monthly',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.bold,
                          color: !_isWeeklySchedule ? Colors.white : subtextColor,
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 20),

          // Calendar Strip (7 Days: Sun to Sat)
          Container(
            padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 8),
            decoration: BoxDecoration(
              color: isDark ? const Color(0xFF1E293B) : Colors.white,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: const Color(0xFFE2E8F0)),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: List.generate(7, (i) {
                final dayDate = weekStart.add(Duration(days: i));
                final dayLabel = DateFormat('E').format(dayDate);
                final dayNum = dayDate.day;
                final isSelected = dayDate.day == _selectedDate.day &&
                    dayDate.month == _selectedDate.month;
                final isToday = dayDate.day == now.day && dayDate.month == now.month;

                return GestureDetector(
                  onTap: () => setState(() => _selectedDate = dayDate),
                  child: Column(
                    children: [
                      Text(
                        dayLabel,
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                          color: isSelected ? brandGreen : subtextColor,
                        ),
                      ),
                      const SizedBox(height: 6),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
                        decoration: BoxDecoration(
                          color: isSelected
                              ? const Color(0xFFC8E6C9)
                              : (isToday ? const Color(0xFFE8F5E9) : Colors.transparent),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(
                          '$dayNum',
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.bold,
                            color: isSelected ? const Color(0xFF1B5E20) : textColor,
                          ),
                        ),
                      ),
                      const SizedBox(height: 6),
                      // Scheduled run indicator dots
                      Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          if (i == 1 || i == 3 || i == 5) ...[
                            Container(width: 4, height: 4, decoration: const BoxDecoration(color: Color(0xFF2E7D32), shape: BoxShape.circle)),
                            const SizedBox(width: 2),
                            Container(width: 4, height: 4, decoration: const BoxDecoration(color: Color(0xFF2E7D32), shape: BoxShape.circle)),
                          ] else if (i == 2 || i == 4) ...[
                            Container(width: 4, height: 4, decoration: const BoxDecoration(color: Color(0xFF2E7D32), shape: BoxShape.circle)),
                          ],
                        ],
                      ),
                    ],
                  ),
                );
              }),
            ),
          ),

          const SizedBox(height: 20),

          // Shift Details Card (Image 2, Screen 2)
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(18),
            decoration: BoxDecoration(
              color: isDark ? const Color(0xFF1E293B) : Colors.white,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: const Color(0xFFE2E8F0)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      'Upcoming Booked Runs:',
                      style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: subtextColor),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                      decoration: BoxDecoration(
                        color: const Color(0xFFE8F5E9),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: const Text(
                        'Assigned',
                        style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Color(0xFF2E7D32)),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                const Text(
                  'Today - 11:30 AM',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w800,
                    color: textColor,
                  ),
                ),
                const SizedBox(height: 8),
                const Divider(height: 1, color: Color(0xFFE2E8F0)),
                const SizedBox(height: 10),
                const Text(
                  'Shift Details:',
                  style: TextStyle(fontSize: 11.5, fontWeight: FontWeight.bold, color: subtextColor),
                ),
                const SizedBox(height: 2),
                const Text(
                  'General Waste Pickup Block 3 (Assigned)',
                  style: TextStyle(fontSize: 13.5, color: textColor),
                ),
              ],
            ),
          ),

          const SizedBox(height: 24),

          // Secondary Action: Request Open Dispatch Button (Image 2, Screen 2)
          SizedBox(
            width: double.infinity,
            height: 50,
            child: ElevatedButton(
              onPressed: _requestOpenDispatch,
              style: ElevatedButton.styleFrom(
                backgroundColor: darkButtonBg,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                elevation: 0,
              ),
              child: const Text(
                'Request Open Dispatch',
                style: TextStyle(fontSize: 14.5, fontWeight: FontWeight.bold),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // =========================================================================
  // TAB 3: RIDER ACCOUNT (SETTINGS & WALLET - EXACTLY MATCHES IMAGE 2, SCREEN 3)
  // =========================================================================
  Widget _buildRiderAccountScreen(BuildContext context, bool isDark) {
    final state = EcoRouteState.instance;
    const textColor = Color(0xFF1E293B);
    const subtextColor = Color(0xFF64748B);

    final fullName = state.userName.isNotEmpty ? state.userName : 'Ayiko Gift Clifford';

    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          // Header: My Account (Image 2, Screen 3)
          const Text(
            'My Account',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w800,
              color: textColor,
            ),
          ),

          const SizedBox(height: 20),

          // Rider Profile Avatar with Verified Badge
          Center(
            child: Stack(
              alignment: Alignment.bottomRight,
              children: [
                Container(
                  width: 80,
                  height: 80,
                  decoration: BoxDecoration(
                    color: const Color(0xFFC8E6C9),
                    shape: BoxShape.circle,
                    border: Border.all(color: Colors.white, width: 3),
                  ),
                  child: Center(
                    child: Text(
                      fullName.isNotEmpty ? fullName[0].toUpperCase() : 'R',
                      style: const TextStyle(
                        fontSize: 32,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF1B5E20),
                      ),
                    ),
                  ),
                ),
                Container(
                  padding: const EdgeInsets.all(3),
                  decoration: const BoxDecoration(
                    color: Color(0xFF00C853),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.check, color: Colors.white, size: 14),
                ),
              ],
            ),
          ),

          const SizedBox(height: 12),

          // Rider Full Name & Location
          Text(
            fullName,
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w800,
              color: textColor,
            ),
          ),
          const SizedBox(height: 4),
          const Text(
            'Verified Rider • Arua, Uganda',
            style: TextStyle(fontSize: 12.5, color: subtextColor),
          ),

          const SizedBox(height: 24),

          // Account Menu List (Image 2, Screen 3)
          Container(
            decoration: BoxDecoration(
              color: isDark ? const Color(0xFF1E293B) : Colors.white,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: const Color(0xFFE2E8F0)),
            ),
            child: Column(
              children: [
                _buildAccountTile(
                  icon: Icons.person_outline,
                  label: 'Personal Information',
                  onTap: () => _showPersonalInformationModal(context),
                ),
                const Divider(height: 1, color: Color(0xFFE2E8F0)),
                _buildAccountTile(
                  icon: Icons.local_shipping_outlined,
                  label: 'Vehicle & Equipment',
                  onTap: () => _showVehicleEquipmentModal(context),
                ),
                const Divider(height: 1, color: Color(0xFFE2E8F0)),
                _buildAccountTile(
                  icon: Icons.account_balance_wallet_outlined,
                  label: 'Payout & Wallet',
                  onTap: () => _showPayoutWalletModal(context),
                ),
                const Divider(height: 1, color: Color(0xFFE2E8F0)),
                _buildAccountTile(
                  icon: Icons.settings_outlined,
                  label: 'App Preferences',
                  onTap: () => _showAppPreferencesModal(context),
                ),
                const Divider(height: 1, color: Color(0xFFE2E8F0)),
                _buildAccountTile(
                  icon: Icons.help_outline,
                  label: 'Support & Help',
                  onTap: () => _showSupportModal(context),
                ),
              ],
            ),
          ),

          const SizedBox(height: 24),

          // Outlined Red Button: Sign Out (Image 2, Screen 3)
          SizedBox(
            width: double.infinity,
            height: 48,
            child: OutlinedButton(
              onPressed: () => _handleSignOut(context),
              style: OutlinedButton.styleFrom(
                foregroundColor: Colors.red,
                side: const BorderSide(color: Color(0xFFFCA5A5), width: 1.2),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
              child: const Text('Sign Out', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
            ),
          ),
          const SizedBox(height: 16),
        ],
      ),
    );
  }

  Widget _buildAccountTile({
    required IconData icon,
    required String label,
    required VoidCallback onTap,
  }) {
    return ListTile(
      leading: Icon(icon, color: const Color(0xFF1E293B), size: 20),
      title: Text(label, style: const TextStyle(fontSize: 13.5, fontWeight: FontWeight.w600)),
      trailing: const Icon(Icons.chevron_right, size: 20, color: Color(0xFF94A3B8)),
      onTap: onTap,
    );
  }

  // =========================================================================
  // ACCOUNT SUB-MODALS
  // =========================================================================

  void _showPersonalInformationModal(BuildContext context) {
    final state = EcoRouteState.instance;
    showModalBottomSheet<void>(
      context: context,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (ctx) => Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Personal Information', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 14),
            ListTile(
              leading: const Icon(Icons.person, color: Color(0xFF1B5E20)),
              title: const Text('Full Name'),
              subtitle: Text(state.userName.isNotEmpty ? state.userName : 'Ayiko Gift Clifford'),
            ),
            ListTile(
              leading: const Icon(Icons.phone, color: Color(0xFF1B5E20)),
              title: const Text('Phone Number'),
              subtitle: Text(state.userPhone.isNotEmpty ? state.userPhone : '+256 700 000 000'),
            ),
            ListTile(
              leading: const Icon(Icons.verified, color: Color(0xFF00C853)),
              title: const Text('Authorization Status'),
              subtitle: const Text('Municipal Verified Fleet Operator (Arua City Council)'),
            ),
          ],
        ),
      ),
    );
  }

  void _showVehicleEquipmentModal(BuildContext context) {
    showModalBottomSheet<void>(
      context: context,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (ctx) => Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Vehicle & Equipment', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 14),
            const ListTile(
              leading: Icon(Icons.electric_rickshaw, color: Color(0xFF1B5E20)),
              title: Text('Assigned Unit'),
              subtitle: Text('Tricycle / Tuk-Tuk • Plate UFD 123A'),
            ),
            const ListTile(
              leading: Icon(Icons.health_and_safety, color: Color(0xFF00C853)),
              title: Text('Safety Equipment'),
              subtitle: Text('Helmet (Passed) • Reflective Vest (Active) • Heavy Gloves (Issued)'),
            ),
          ],
        ),
      ),
    );
  }

  void _showPayoutWalletModal(BuildContext context) {
    final state = EcoRouteState.instance;
    showModalBottomSheet<void>(
      context: context,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (ctx) => Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('Payout & Wallet', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 14),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: const Color(0xFFE8F5E9),
                borderRadius: BorderRadius.circular(14),
              ),
              child: Column(
                children: [
                  const Text('Available Earnings Balance:', style: TextStyle(fontSize: 12, color: Color(0xFF2E7D32))),
                  const SizedBox(height: 6),
                  Text(
                    'UGX ${NumberFormat('#,###').format(state.riderLedgerBalance)}',
                    style: const TextStyle(fontSize: 26, fontWeight: FontWeight.w900, color: Color(0xFF1B5E20)),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: () {
                  Navigator.pop(ctx);
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Mobile Money payout scheduled via MTN MoMo / Airtel Money.')),
                  );
                },
                icon: const Icon(Icons.payments_outlined),
                label: const Text('Withdraw via Mobile Money'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF1B5E20),
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showAppPreferencesModal(BuildContext context) {
    final state = EcoRouteState.instance;
    showModalBottomSheet<void>(
      context: context,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (ctx) => Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('App Preferences', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 12),
            SwitchListTile(
              title: const Text('Dark Mode'),
              subtitle: const Text('Optimize contrast for night collection runs'),
              value: state.isDarkMode,
              onChanged: (val) {
                state.toggleTheme();
                Navigator.pop(ctx);
              },
            ),
          ],
        ),
      ),
    );
  }

  void _showSupportModal(BuildContext context) {
    showModalBottomSheet<void>(
      context: context,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (ctx) => Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Support & Fleet Help', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 6),
            const Text('Arua City Waste Management Dispatch Desk', style: TextStyle(fontSize: 13, color: Colors.grey)),
            const SizedBox(height: 14),
            ListTile(
              leading: const Icon(Icons.call, color: Color(0xFF1B5E20)),
              title: const Text('Call Dispatch Officer'),
              subtitle: const Text('+256 700 000 000 (Toll-Free Dispatch)'),
              onTap: () {
                Navigator.pop(ctx);
                _callCustomer('+256700000000');
              },
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _handleSignOut(BuildContext context) async {
    final prefs = EcoRouteState.instance.prefs ?? await SharedPreferences.getInstance();
    final auth = AuthService(prefs);
    await auth.logout();
    EcoRouteState.instance.logout(context);
  }
}
