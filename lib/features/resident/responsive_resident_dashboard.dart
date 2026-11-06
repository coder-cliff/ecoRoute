import 'package:flutter/material.dart';

import '../../core/layout/adaptive_layout.dart';
import '../../main.dart';

/// Responsive Resident / User Dashboard
/// Strictly adheres to Architectural Wireframe A & Image 1 Mobile layout + Desktop matrix
class ResponsiveResidentDashboard extends StatefulWidget {
  const ResponsiveResidentDashboard({super.key});

  @override
  State<ResponsiveResidentDashboard> createState() =>
      _ResponsiveResidentDashboardState();
}

class _ResponsiveResidentDashboardState
    extends State<ResponsiveResidentDashboard> {
  int _currentBottomNavIndex = 0;
  int _selectedSidebarNav = 0;

  // Real-time Waste Details Configuration
  String _selectedWasteType = 'Household Waste';
  int _sackCount = 3;
  static const int _pricePerSackUgx = 5000;

  final List<String> _wasteTypes = const [
    'Household Waste',
    'Commercial Packaging',
    'Recyclable Plastics',
    'Organic Compost',
  ];

  @override
  Widget build(BuildContext context) {
    if (ViewportBreakpoints.isDesktop(context)) {
      return _buildDesktopLayout();
    } else {
      return _buildMobileLayout();
    }
  }

  // =========================================================================
  // SMARTPHONE VIEWPORT (<600px) - EXACTLY MATCHES IMAGE 1 & WIREFRAME A
  // =========================================================================
  Widget _buildMobileLayout() {
    final state = EcoRouteState.instance;
    final isDark = AntigravityTheme.isDark(context);
    final surfaceColor = AntigravityTheme.surface(context);
    final cardColor = AntigravityTheme.card(context);
    final textColor = AntigravityTheme.textPrimary(context);
    final subtextColor = AntigravityTheme.textSecondary(context);
    final accentGreen = AntigravityTheme.ecoAccent(context);
    final estimatedTotal = _sackCount * _pricePerSackUgx;

    return Scaffold(
      backgroundColor: surfaceColor,
      appBar: AppBar(
        backgroundColor: surfaceColor,
        elevation: 0,
        title: Row(
          children: [
            Icon(Icons.eco, color: accentGreen, size: 24),
            const SizedBox(width: 8),
            Text(
              'ECOROUTE',
              style: TextStyle(
                fontFamily: 'Satoshi',
                fontSize: 18,
                fontWeight: FontWeight.w900,
                letterSpacing: 1.2,
                color: accentGreen,
              ),
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
          Stack(
            alignment: Alignment.topRight,
            children: [
              IconButton(
                tooltip: 'Notifications',
                icon: Icon(Icons.notifications_outlined, color: textColor),
                onPressed: () {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('No unread municipal alerts.')),
                  );
                },
              ),
              Positioned(
                right: 12,
                top: 12,
                child: Container(
                  width: 8,
                  height: 8,
                  decoration: const BoxDecoration(
                    color: Color(0xFFE53935),
                    shape: BoxShape.circle,
                  ),
                ),
              ),
            ],
          ),
          IconButton(
            tooltip: 'My Profile',
            icon: Icon(Icons.account_circle_outlined, color: textColor),
            onPressed: () => showEcoRouteProfileSheet(context),
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // User Greeting
            Text(
              state.userName.isNotEmpty
                  ? 'Hello, ${state.userName}!'
                  : 'Hello, Muni Residence!',
              style: TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.w800,
                color: textColor,
              ),
            ),
            const SizedBox(height: 14),

            // Schedule Fast Pickup Button
            ElevatedButton(
              onPressed: () => _handleInstantBooking(context),
              style: ElevatedButton.styleFrom(
                backgroundColor: accentGreen,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 16),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                elevation: 1,
              ),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.2),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Icon(Icons.calendar_month, color: Colors.white, size: 22),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: const [
                        Text(
                          'Schedule Fast Pickup',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                        SizedBox(height: 2),
                        Text(
                          'Sub-5-Meter Precision. On-Site Verified.',
                          style: TextStyle(fontSize: 11, color: Colors.white70),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),

            // WASTE DETAILS CARD
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: cardColor,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: AntigravityTheme.border(context)),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.04),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Waste Details',
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.bold,
                      color: textColor,
                    ),
                  ),
                  const SizedBox(height: 12),

                  // Waste Type Dropdown
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
                    decoration: BoxDecoration(
                      color: isDark ? const Color(0xFF282828) : const Color(0xFFF8F9FA),
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: AntigravityTheme.border(context)),
                    ),
                    child: DropdownButtonHideUnderline(
                      child: DropdownButton<String>(
                        value: _selectedWasteType,
                        isExpanded: true,
                        dropdownColor: cardColor,
                        icon: const Icon(Icons.keyboard_arrow_down),
                        items: _wasteTypes.map((type) {
                          return DropdownMenuItem<String>(
                            value: type,
                            child: Row(
                              children: [
                                const Icon(Icons.shopping_bag_outlined, size: 18, color: Colors.grey),
                                const SizedBox(width: 10),
                                Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Text('Select Waste Type', style: TextStyle(fontSize: 10, color: subtextColor)),
                                    Text(
                                      type,
                                      style: TextStyle(
                                        fontSize: 13,
                                        fontWeight: FontWeight.w600,
                                        color: textColor,
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          );
                        }).toList(),
                        onChanged: (val) {
                          if (val != null) setState(() => _selectedWasteType = val);
                        },
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Number of Sacks Slider
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Number of Sacks',
                        style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: textColor),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(
                          color: accentGreen.withOpacity(0.12),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Text(
                          '$_sackCount Sacks',
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                            color: accentGreen,
                          ),
                        ),
                      ),
                    ],
                  ),
                  SliderTheme(
                    data: SliderTheme.of(context).copyWith(
                      activeTrackColor: accentGreen,
                      inactiveTrackColor: accentGreen.withOpacity(0.2),
                      thumbColor: accentGreen,
                      overlayColor: accentGreen.withOpacity(0.15),
                      trackHeight: 4,
                    ),
                    child: Slider(
                      value: _sackCount.toDouble(),
                      min: 1,
                      max: 10,
                      divisions: 9,
                      onChanged: (val) => setState(() => _sackCount = val.toInt()),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 14),

            // MINI OPENSTREETMAP PORT CARD
            Container(
              decoration: BoxDecoration(
                color: cardColor,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: AntigravityTheme.border(context)),
              ),
              child: Column(
                children: [
                  // Map Preview Canvas
                  ClipRRect(
                    borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
                    child: Container(
                      height: 130,
                      color: const Color(0xFFE2EBE2),
                      child: Stack(
                        alignment: Alignment.center,
                        children: [
                          CustomPaint(
                            size: const Size(double.infinity, 130),
                            painter: _MiniMapPainter(),
                          ),
                          // Precision Radius Circle
                          Container(
                            width: 68,
                            height: 68,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: accentGreen.withOpacity(0.2),
                              border: Border.all(color: accentGreen, width: 1.5),
                            ),
                            child: const Center(
                              child: Icon(Icons.location_on, color: Color(0xFF1B5E20), size: 28),
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
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Muni University Area',
                              style: TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.bold,
                                color: textColor,
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              'Live Location Accuracy: <5m',
                              style: TextStyle(fontSize: 11, color: accentGreen, fontWeight: FontWeight.w600),
                            ),
                            const SizedBox(height: 2),
                            Row(
                              children: [
                                const Icon(Icons.place, size: 12, color: Colors.grey),
                                const SizedBox(width: 2),
                                Text(
                                  'Arua, Uganda',
                                  style: TextStyle(fontSize: 11, color: subtextColor),
                                ),
                              ],
                            ),
                          ],
                        ),
                        Text(
                          '© OpenStreetMap',
                          style: TextStyle(fontSize: 9, color: subtextColor.withOpacity(0.6)),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 14),

            // ESTIMATED PRICE CARD
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: cardColor,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: AntigravityTheme.border(context)),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'ESTIMATED PRICE',
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.bold,
                          color: subtextColor,
                          letterSpacing: 0.5,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'UGX ${estimatedTotal.toString().replaceAllMapped(RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'), (Match m) => '${m[1]},')}',
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.w900,
                          color: accentGreen,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        'Cost: $_sackCount Sacks @ UGX 5,000',
                        style: TextStyle(fontSize: 11, color: subtextColor),
                      ),
                      Text(
                        'Pay via MoMo Intent (*165*3#)',
                        style: TextStyle(fontSize: 11, color: subtextColor),
                      ),
                    ],
                  ),
                  FilledButton.tonal(
                    onPressed: () => _handleInstantBooking(context),
                    style: FilledButton.styleFrom(
                      backgroundColor: accentGreen.withValues(alpha: 0.12),
                      foregroundColor: accentGreen,
                    ),
                    child: const Text('Book Order', style: TextStyle(fontWeight: FontWeight.bold)),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),

            // Status notification pills
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                color: cardColor,
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: AntigravityTheme.border(context)),
              ),
              child: Row(
                children: [
                  const Icon(Icons.event_available, size: 16, color: Color(0xFF2E7D32)),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Pickup Scheduled for Today (North Zone)',
                      style: TextStyle(fontSize: 12, color: textColor, fontWeight: FontWeight.w500),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                color: cardColor,
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: AntigravityTheme.border(context)),
              ),
              child: Row(
                children: [
                  const Icon(Icons.electric_moped, size: 16, color: Color(0xFF2E7D32)),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Rider TRIC-18 is active nearby',
                      style: TextStyle(fontSize: 12, color: textColor, fontWeight: FontWeight.w500),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),
          ],
        ),
      ),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _currentBottomNavIndex,
        onTap: (index) => setState(() => _currentBottomNavIndex = index),
        backgroundColor: cardColor,
        selectedItemColor: accentGreen,
        unselectedItemColor: subtextColor,
        type: BottomNavigationBarType.fixed,
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.home), label: 'Home'),
          BottomNavigationBarItem(icon: Icon(Icons.history), label: 'History'),
          BottomNavigationBarItem(icon: Icon(Icons.receipt_long), label: 'Requests'),
          BottomNavigationBarItem(icon: Icon(Icons.person_outline), label: 'Profile'),
        ],
      ),
    );
  }

  // =========================================================================
  // DESKTOP FULL MATRIX VIEWPORT (>1024px) - WIREFRAME A SPECIFICATION
  // =========================================================================
  Widget _buildDesktopLayout() {
    final state = EcoRouteState.instance;
    final isDark = AntigravityTheme.isDark(context);
    final surfaceColor = AntigravityTheme.surface(context);
    final cardColor = AntigravityTheme.card(context);
    final textColor = AntigravityTheme.textPrimary(context);
    final subtextColor = AntigravityTheme.textSecondary(context);
    final accentGreen = AntigravityTheme.ecoAccent(context);

    return Scaffold(
      backgroundColor: surfaceColor,
      body: Row(
        children: [
          // 280px SIDEBAR NAV (Wireframe A Specification)
          Container(
            width: ViewportBreakpoints.sidebarWidth,
            color: isDark ? const Color(0xFF161616) : const Color(0xFF1B3828),
            padding: const EdgeInsets.symmetric(vertical: 24, horizontal: 18),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: const [
                    Icon(Icons.eco, color: Color(0xFF4CAF50), size: 28),
                    SizedBox(width: 10),
                    Text(
                      'Antigravity',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 28),

                _buildSidebarItem(0, 'Dashboard Hub', Icons.dashboard_outlined),
                _buildSidebarItem(1, 'History Log', Icons.history),
                _buildSidebarItem(2, 'Analytics Stats', Icons.bar_chart_outlined),
                _buildSidebarItem(3, 'Wallet Matrix', Icons.account_balance_wallet_outlined),
                _buildSidebarItem(4, 'Help Support', Icons.help_outline),

                const Spacer(),

                // Profile Panel (Wireframe A)
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.08),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    children: [
                      CircleAvatar(
                        backgroundColor: accentGreen,
                        radius: 18,
                        child: Text(
                          state.userName.isNotEmpty ? state.userName[0].toUpperCase() : 'R',
                          style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              state.userName.isNotEmpty ? state.userName : 'Resident User',
                              style: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.bold),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                            const Text(
                              'User Status: Active',
                              style: TextStyle(color: Color(0xFF81C784), fontSize: 10),
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

          // MAIN WORKSPACE CONTAINER (Fluid Grid Array)
          Expanded(
            child: Column(
              children: [
                // Topbar
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
                  color: cardColor,
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Welcome back, ${state.userName.isNotEmpty ? state.userName : 'Resident'}',
                            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: textColor),
                          ),
                          Text(
                            'Active Account: ${state.userEmail.isNotEmpty ? state.userEmail : 'Arua Municipality'}',
                            style: TextStyle(fontSize: 12, color: subtextColor),
                          ),
                        ],
                      ),
                      Row(
                        children: [
                          IconButton(
                            tooltip: 'Toggle Theme',
                            icon: Icon(isDark ? Icons.light_mode : Icons.dark_mode, color: textColor),
                            onPressed: () => state.toggleTheme(),
                          ),
                          const SizedBox(width: 12),
                          FilledButton.icon(
                            onPressed: () => _handleInstantBooking(context),
                            icon: const Icon(Icons.flash_on, size: 16),
                            label: const Text('TRIPPED PICKUP DRAWER BUTTON'),
                            style: FilledButton.styleFrom(backgroundColor: accentGreen),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                const Divider(height: 1),

                // Workspace Fluid Grid
                Expanded(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.all(24),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Row: Interactive Map + Account Disposal History
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // Spatial Interactive Map (spans canvas)
                            Expanded(
                              flex: 6,
                              child: Container(
                                height: 320,
                                decoration: BoxDecoration(
                                  color: cardColor,
                                  borderRadius: BorderRadius.circular(16),
                                  border: Border.all(color: AntigravityTheme.border(context)),
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
                                            '🗺️ DETAILED SPATIAL INTERACTIVE MAP',
                                            style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: textColor),
                                          ),
                                          Container(
                                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                            decoration: BoxDecoration(
                                              color: accentGreen.withOpacity(0.12),
                                              borderRadius: BorderRadius.circular(6),
                                            ),
                                            child: Text('Live Sub-5m GNSS Lock', style: TextStyle(color: accentGreen, fontSize: 11, fontWeight: FontWeight.bold)),
                                          ),
                                        ],
                                      ),
                                    ),
                                    Expanded(
                                      child: ClipRRect(
                                        borderRadius: const BorderRadius.vertical(bottom: Radius.circular(16)),
                                        child: CustomPaint(
                                          size: const Size(double.infinity, double.infinity),
                                          painter: _DesktopMapPainter(),
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                            const SizedBox(width: 20),

                            // Account Disposal History Ledger
                            Expanded(
                              flex: 4,
                              child: Container(
                                height: 320,
                                padding: const EdgeInsets.all(16),
                                decoration: BoxDecoration(
                                  color: cardColor,
                                  borderRadius: BorderRadius.circular(16),
                                  border: Border.all(color: AntigravityTheme.border(context)),
                                ),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      '📑 ACCOUNT DISPOSAL HISTORY',
                                      style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: textColor),
                                    ),
                                    const SizedBox(height: 12),
                                    Expanded(
                                      child: state.residentRequests.isEmpty
                                          ? Center(
                                              child: Column(
                                                mainAxisSize: MainAxisSize.min,
                                                children: [
                                                  Icon(Icons.receipt_long_outlined, size: 36, color: subtextColor),
                                                  const SizedBox(height: 8),
                                                  Text('No past disposal requests recorded.', style: TextStyle(fontSize: 12, color: subtextColor)),
                                                  const SizedBox(height: 6),
                                                  Text('Book a pickup to generate municipal receipts.', style: TextStyle(fontSize: 11, color: subtextColor)),
                                                ],
                                              ),
                                            )
                                          : ListView.separated(
                                              itemCount: state.residentRequests.length,
                                              separatorBuilder: (_, __) => const Divider(height: 1),
                                              itemBuilder: (ctx, idx) {
                                                final req = state.residentRequests[idx];
                                                return ListTile(
                                                  dense: true,
                                                  contentPadding: EdgeInsets.zero,
                                                  title: Text(req['address'] as String? ?? 'Arua Area', style: TextStyle(fontWeight: FontWeight.bold, color: textColor)),
                                                  subtitle: Text('${req['sacks']} Sack(s) • ${req['wasteType']}', style: TextStyle(fontSize: 11, color: subtextColor)),
                                                  trailing: Text(req['price'] as String? ?? 'UGX 5,000', style: TextStyle(fontWeight: FontWeight.bold, color: accentGreen)),
                                                );
                                              },
                                            ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 24),

                        // Carbon Impact Trends (Wireframe A)
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
                                '📊 MY CARBON IMPACT REDUCTION TRENDS',
                                style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: textColor),
                              ),
                              const SizedBox(height: 4),
                              Text('Measured in municipal solid waste diversion & methane mitigation (kg CO2e)', style: TextStyle(fontSize: 11, color: subtextColor)),
                              const SizedBox(height: 16),
                              Row(
                                children: [
                                  _buildTrendBar('Jun Diversion', 0.65, '42 kg', accentGreen),
                                  const SizedBox(width: 24),
                                  _buildTrendBar('Jul Diversion', 0.85, '58 kg', accentGreen),
                                  const SizedBox(width: 24),
                                  _buildTrendBar('Aug Diversion', 0.95, '72 kg', accentGreen),
                                ],
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
          ),
        ],
      ),
    );
  }

  Widget _buildTrendBar(String label, double ratio, String value, Color color) {
    return Expanded(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(label, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w500)),
              Text(value, style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: color)),
            ],
          ),
          const SizedBox(height: 6),
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(
              value: ratio,
              minHeight: 12,
              backgroundColor: color.withOpacity(0.15),
              valueColor: AlwaysStoppedAnimation<Color>(color),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSidebarItem(int index, String label, IconData icon) {
    final isSelected = _selectedSidebarNav == index;
    return ListTile(
      dense: true,
      selected: isSelected,
      leading: Icon(icon, color: isSelected ? const Color(0xFF4CAF50) : Colors.white70, size: 20),
      title: Text(
        label,
        style: TextStyle(
          color: isSelected ? Colors.white : Colors.white70,
          fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
          fontSize: 13,
        ),
      ),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      tileColor: isSelected ? Colors.white.withOpacity(0.12) : Colors.transparent,
      onTap: () => setState(() => _selectedSidebarNav = index),
    );
  }

  void _handleInstantBooking(BuildContext context) {
    final total = _sackCount * _pricePerSackUgx;
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: AntigravityTheme.card(context),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Text(
              'Confirm Instant Pickup Order',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),
            Text('Waste Type: $_selectedWasteType'),
            Text('Sacks: $_sackCount'),
            Text('Estimated Price: UGX $total'),
            Text('Location: Muni University Area (Verified Accuracy <5m)'),
            const SizedBox(height: 20),
            FilledButton(
              onPressed: () {
                Navigator.pop(ctx);
                EcoRouteState.instance.bookPickup(
                  sacks: _sackCount,
                  wasteType: _selectedWasteType,
                  address: 'Muni University Area, Arua',
                  isInstant: true,
                  paymentMethod: 'MoMo',
                );
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Instant collection scheduled & dispatched!'),
                    backgroundColor: Color(0xFF2E7D32),
                  ),
                );
              },
              style: FilledButton.styleFrom(backgroundColor: const Color(0xFF2E7D32)),
              child: const Text('Confirm & Dispatch Tricycle'),
            ),
          ],
        ),
      ),
    );
  }
}

/// Mini Map Painter for OpenStreetMap port
class _MiniMapPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final roadPaint = Paint()
      ..color = Colors.white
      ..strokeWidth = 6
      ..style = PaintingStyle.stroke;
    final greenZonePaint = Paint()..color = const Color(0xFFC8E6C9);

    // Green zone patches
    canvas.drawRRect(
      RRect.fromRectAndRadius(Rect.fromLTWH(size.width * 0.1, 10, size.width * 0.35, 60), const Radius.circular(8)),
      greenZonePaint,
    );
    canvas.drawRRect(
      RRect.fromRectAndRadius(Rect.fromLTWH(size.width * 0.55, 40, size.width * 0.4, 70), const Radius.circular(8)),
      greenZonePaint,
    );

    // Roads
    canvas.drawLine(Offset(0, size.height * 0.5), Offset(size.width, size.height * 0.45), roadPaint);
    canvas.drawLine(Offset(size.width * 0.4, 0), Offset(size.width * 0.6, size.height), roadPaint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

/// Desktop Detailed Spatial Interactive Map Painter
class _DesktopMapPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final bgPaint = Paint()..color = const Color(0xFFE8F0E8);
    canvas.drawRect(Rect.fromLTWH(0, 0, size.width, size.height), bgPaint);

    final roadPaint = Paint()
      ..color = Colors.white
      ..strokeWidth = 10
      ..style = PaintingStyle.stroke;

    // Major Arua Corridors
    canvas.drawLine(Offset(0, size.height * 0.4), Offset(size.width, size.height * 0.55), roadPaint);
    canvas.drawLine(Offset(size.width * 0.3, 0), Offset(size.width * 0.35, size.height), roadPaint);
    canvas.drawLine(Offset(size.width * 0.7, 0), Offset(size.width * 0.65, size.height), roadPaint);

    // Fleet & Depot Pins
    final pinPaint = Paint()..color = const Color(0xFF2E7D32);
    canvas.drawCircle(Offset(size.width * 0.32, size.height * 0.42), 8, pinPaint);
    canvas.drawCircle(Offset(size.width * 0.68, size.height * 0.52), 8, pinPaint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
