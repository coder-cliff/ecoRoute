import 'package:flutter/material.dart';

import '../../core/layout/adaptive_layout.dart';
import '../../main.dart';

/// Responsive Rider Field Operations Dashboard
/// Conforms to Architectural Wireframe B:
///   - Smartphone (<600px): One-handed high vibration constraints
///   - Tablet Dual-Pane (600px - 1024px): Task list on left + telemetry map & workflow matrix on right
class ResponsiveRiderDashboard extends StatefulWidget {
  const ResponsiveRiderDashboard({super.key});

  @override
  State<ResponsiveRiderDashboard> createState() =>
      _ResponsiveRiderDashboardState();
}

class _ResponsiveRiderDashboardState extends State<ResponsiveRiderDashboard> {
  int _selectedTaskIndex = 0;
  double _recordedWeightKg = 45.0;
  final TextEditingController _smsCodeController =
      TextEditingController(text: 'Q1A2B3C4D5');

  @override
  void dispose() {
    _smsCodeController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (ViewportBreakpoints.isTablet(context) ||
        ViewportBreakpoints.isDesktop(context)) {
      return _buildTabletDualPaneLayout();
    } else {
      return _buildSmartphoneLayout();
    }
  }

  // =========================================================================
  // SMARTPHONE VIEWPORT (<600px) - WIREFRAME B SPECIFICATION
  // =========================================================================
  Widget _buildSmartphoneLayout() {
    final state = EcoRouteState.instance;
    final isDark = AntigravityTheme.isDark(context);
    final surfaceColor = AntigravityTheme.surface(context);
    final cardColor = AntigravityTheme.card(context);
    final textColor = AntigravityTheme.textPrimary(context);
    final subtextColor = AntigravityTheme.textSecondary(context);
    final accentGreen = AntigravityTheme.ecoAccent(context);

    final currentTask = state.riderTasks.isNotEmpty &&
            _selectedTaskIndex < state.riderTasks.length
        ? state.riderTasks[_selectedTaskIndex]
        : null;

    return Scaffold(
      backgroundColor: surfaceColor,
      appBar: AppBar(
        backgroundColor: surfaceColor,
        elevation: 0,
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                color: accentGreen.withOpacity(0.15),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                'Rider Unit: TRIC-18',
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.bold,
                  color: accentGreen,
                ),
              ),
            ),
            const Spacer(),
            Row(
              children: [
                const Icon(Icons.battery_5_bar, color: Color(0xFF2E7D32), size: 20),
                const SizedBox(width: 4),
                Text(
                  'Battery: 92%',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                    color: textColor,
                  ),
                ),
              ],
            ),
          ],
        ),
        actions: [
          IconButton(
            tooltip: 'Toggle Theme',
            icon: Icon(
              isDark ? Icons.light_mode_outlined : Icons.dark_mode_outlined,
              color: textColor,
            ),
            onPressed: () => state.toggleTheme(),
          ),
          IconButton(
            tooltip: 'My Profile',
            icon: Icon(Icons.account_circle_outlined, color: textColor),
            onPressed: () => showEcoRouteProfileSheet(context),
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Active Route Focus
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
              decoration: BoxDecoration(
                color: cardColor,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: AntigravityTheme.border(context)),
              ),
              child: Row(
                children: [
                  const Icon(Icons.near_me, color: Color(0xFF2E7D32), size: 18),
                  const SizedBox(width: 8),
                  Text(
                    'Active Route Focus: Ayivu Zone',
                    style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: textColor),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 14),

            // ROUTE NAVIGATION MAP WINDOW
            Container(
              decoration: BoxDecoration(
                color: cardColor,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: AntigravityTheme.border(context)),
              ),
              child: Column(
                children: [
                  ClipRRect(
                    borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
                    child: Container(
                      height: 140,
                      color: const Color(0xFFDCEAD7),
                      child: Stack(
                        alignment: Alignment.center,
                        children: [
                          CustomPaint(
                            size: const Size(double.infinity, 140),
                            painter: _RiderPathPainter(),
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                            decoration: BoxDecoration(
                              color: const Color(0xFF0D2618),
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: const Text(
                              '🗺️ ROUTE NAVIGATION MAP WINDOW',
                              style: TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.bold),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.all(12),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'Next Destination Point: 1.4 km Remaining',
                          style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: textColor),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                          decoration: BoxDecoration(
                            color: Colors.green.withOpacity(0.12),
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: const Text('Speed: 18 km/h', style: TextStyle(fontSize: 10, color: Colors.green, fontWeight: FontWeight.bold)),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 14),

            // CURRENT RECIPIENT TASK CARD
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: cardColor,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: AntigravityTheme.border(context)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        '👤 CURRENT RECIPIENT TASK CARD',
                        style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: textColor),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                        decoration: BoxDecoration(
                          color: accentGreen.withOpacity(0.15),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Text('Assigned', style: TextStyle(color: accentGreen, fontSize: 10, fontWeight: FontWeight.bold)),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  Text(
                    'Name: ${currentTask != null ? currentTask['client'] : 'John Doe'}',
                    style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: textColor),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Address: ${currentTask != null ? currentTask['address'] : 'Muni Road, Plot 42'}',
                    style: TextStyle(fontSize: 12, color: subtextColor),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Load Metrics: ${currentTask != null ? currentTask['sacks'] : 3} Sacks Indicated',
                    style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: textColor),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 14),

            // AUTOMATED SMS INCOME PARSER PANEL
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: cardColor,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: AntigravityTheme.border(context)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Text(
                    '📥 AUTOMATED SMS INCOME PARSER PANEL',
                    style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: textColor),
                  ),
                  const SizedBox(height: 8),
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: isDark ? const Color(0xFF282828) : const Color(0xFFF1F5F2),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text('Last Incoming Code Detected:', style: TextStyle(fontSize: 11, color: subtextColor)),
                        Text(
                          _smsCodeController.text,
                          style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: accentGreen, letterSpacing: 1.2),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 14),
                  FilledButton.icon(
                    onPressed: () => _handleCompleteJob(context),
                    icon: const Icon(Icons.check_circle_outline, size: 18),
                    label: const Text('ONE-TAP VERIFY & COMPLETE JOB', style: TextStyle(fontWeight: FontWeight.bold)),
                    style: FilledButton.styleFrom(
                      backgroundColor: accentGreen,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
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

  // =========================================================================
  // TABLET DUAL-PANE VIEWPORT (600px - 1024px) - WIREFRAME B SPECIFICATION
  // =========================================================================
  Widget _buildTabletDualPaneLayout() {
    final state = EcoRouteState.instance;
    final isDark = AntigravityTheme.isDark(context);
    final surfaceColor = AntigravityTheme.surface(context);
    final cardColor = AntigravityTheme.card(context);
    final textColor = AntigravityTheme.textPrimary(context);
    final accentGreen = AntigravityTheme.ecoAccent(context);

    return Scaffold(
      backgroundColor: surfaceColor,
      appBar: AppBar(
        backgroundColor: surfaceColor,
        elevation: 0,
        title: Row(
          children: [
            const Icon(Icons.electric_moped, color: Color(0xFF2E7D32)),
            const SizedBox(width: 8),
            Text(
              'RIDER OPERATIONS MATRIX • TRIC-18',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15, color: textColor),
            ),
          ],
        ),
        actions: [
          IconButton(
            tooltip: 'Toggle Theme',
            icon: Icon(isDark ? Icons.light_mode : Icons.dark_mode, color: textColor),
            onPressed: () => state.toggleTheme(),
          ),
          IconButton(
            tooltip: 'My Profile',
            icon: Icon(Icons.account_circle_outlined, color: textColor),
            onPressed: () => showEcoRouteProfileSheet(context),
          ),
        ],
      ),
      body: Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // LEFT PANEL: TASK LIST (Wireframe B)
          Container(
            width: 320,
            decoration: BoxDecoration(
              color: cardColor,
              border: Border(right: BorderSide(color: AntigravityTheme.border(context))),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Padding(
                  padding: const EdgeInsets.all(16),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Active Collection Logs',
                        style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: textColor),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: accentGreen.withOpacity(0.12),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Text(
                          '🔄 3 RECORDS CACHED',
                          style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: accentGreen),
                        ),
                      ),
                    ],
                  ),
                ),
                const Divider(height: 1),

                Expanded(
                  child: ListView(
                    padding: const EdgeInsets.all(12),
                    children: [
                      _buildTaskItemCard(0, 'Amani K.', '1.2km away', 'Confirmed', true),
                      _buildTaskItemCard(1, 'John D.', '2.4km away', 'Pending', false),
                      _buildTaskItemCard(2, 'Alice M.', '3.1km away', 'Confirmed', true),
                    ],
                  ),
                ),
              ],
            ),
          ),

          // RIGHT PANEL: NAVIGATION & VERIFICATION VIEW (Wireframe B)
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // Live Telemetry Path Routing Map Overlay
                  Container(
                    height: 220,
                    decoration: BoxDecoration(
                      color: cardColor,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: AntigravityTheme.border(context)),
                    ),
                    child: Stack(
                      alignment: Alignment.center,
                      children: [
                        ClipRRect(
                          borderRadius: BorderRadius.circular(16),
                          child: CustomPaint(
                            size: const Size(double.infinity, 220),
                            painter: _RiderPathPainter(),
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                          decoration: BoxDecoration(
                            color: const Color(0xFF0D2618),
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: const Text(
                            '🗺️ LIVE TELEMETRY PATH ROUTING MAP OVERLAY',
                            style: TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.bold),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),

                  // ON-SITE WORKFLOW MATRIX
                  Container(
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: cardColor,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: AntigravityTheme.border(context)),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          '⚙️ ON-SITE WORKFLOW MATRIX',
                          style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: textColor),
                        ),
                        const SizedBox(height: 16),

                        // Weight Slider
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text('Extracted Weight Parameters:', style: TextStyle(fontSize: 13, color: textColor)),
                            Text('${_recordedWeightKg.toInt()} kg', style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: accentGreen)),
                          ],
                        ),
                        Slider(
                          value: _recordedWeightKg,
                          min: 5,
                          max: 120,
                          activeColor: accentGreen,
                          onChanged: (val) => setState(() => _recordedWeightKg = val),
                        ),
                        const SizedBox(height: 14),

                        // Mobile Money Code Entry
                        Text('Mobile Money Code Entry Stream:', style: TextStyle(fontSize: 13, color: textColor)),
                        const SizedBox(height: 6),
                        TextField(
                          controller: _smsCodeController,
                          decoration: InputDecoration(
                            hintText: 'e.g. Q1A2B3C4D5',
                            filled: true,
                            fillColor: isDark ? const Color(0xFF282828) : const Color(0xFFF8F9FA),
                            border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                          ),
                        ),
                        const SizedBox(height: 16),

                        // Reconcile Button
                        FilledButton.icon(
                          onPressed: () => _handleCompleteJob(context),
                          icon: const Icon(Icons.verified),
                          label: const Text('CONFIRM MATCHING TELECOM RECONCILIATION BUTTON'),
                          style: FilledButton.styleFrom(
                            backgroundColor: accentGreen,
                            padding: const EdgeInsets.symmetric(vertical: 14),
                            minimumSize: const Size(double.infinity, 48),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 12),

                  // Offline Drift Warning Tracker Active
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.amber.withOpacity(0.12),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: Colors.amber.withOpacity(0.4)),
                    ),
                    child: Row(
                      children: const [
                        Icon(Icons.warning_amber_rounded, color: Colors.amber, size: 20),
                        SizedBox(width: 10),
                        Expanded(
                          child: Text(
                            '⚠️ Local Drift Warning Tracker Active: 3 Unsynchronized Offline Logs!',
                            style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Color(0xFF8D6E63)),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTaskItemCard(int index, String name, String distance, String status, bool confirmed) {
    final isSelected = _selectedTaskIndex == index;
    final cardColor = AntigravityTheme.card(context);
    final accentGreen = AntigravityTheme.ecoAccent(context);

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      decoration: BoxDecoration(
        color: cardColor,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(
          color: isSelected ? accentGreen : AntigravityTheme.border(context),
          width: isSelected ? 1.5 : 1,
        ),
      ),
      child: ListTile(
        selected: isSelected,
        title: Text(name, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
        subtitle: Text(distance, style: const TextStyle(fontSize: 11)),
        trailing: Container(
          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
          decoration: BoxDecoration(
            color: confirmed ? Colors.green.withOpacity(0.12) : Colors.orange.withOpacity(0.12),
            borderRadius: BorderRadius.circular(4),
          ),
          child: Text(
            status,
            style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: confirmed ? Colors.green : Colors.orange),
          ),
        ),
        onTap: () => setState(() => _selectedTaskIndex = index),
      ),
    );
  }

  void _handleCompleteJob(BuildContext context) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Job reconciled & marked complete. Digital receipt synchronized to HQ.'),
        backgroundColor: Color(0xFF2E7D32),
      ),
    );
  }
}

/// Painter for Rider Route Map
class _RiderPathPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final roadPaint = Paint()
      ..color = Colors.white
      ..strokeWidth = 8
      ..style = PaintingStyle.stroke;
    final routePaint = Paint()
      ..color = const Color(0xFF2E7D32)
      ..strokeWidth = 4
      ..style = PaintingStyle.stroke;

    // Roads
    canvas.drawLine(Offset(0, size.height * 0.3), Offset(size.width, size.height * 0.7), roadPaint);
    canvas.drawLine(Offset(size.width * 0.2, 0), Offset(size.width * 0.8, size.height), roadPaint);

    // Active route overlay
    final path = Path();
    path.moveTo(size.width * 0.15, size.height * 0.35);
    path.lineTo(size.width * 0.45, size.height * 0.5);
    path.lineTo(size.width * 0.7, size.height * 0.6);
    canvas.drawPath(path, routePaint);

    // Destination Pin
    final pinPaint = Paint()..color = const Color(0xFFD32F2F);
    canvas.drawCircle(Offset(size.width * 0.7, size.height * 0.6), 6, pinPaint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
