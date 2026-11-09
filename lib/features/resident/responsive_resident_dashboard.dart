import 'dart:convert';
import 'package:image_picker/image_picker.dart';
import '../../core/services/location_service.dart';
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
      body: _buildMobileBody(state, textColor, subtextColor, cardColor, accentGreen, isDark, estimatedTotal),
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

  Widget _buildMobileBody(
    EcoRouteState state,
    Color textColor,
    Color subtextColor,
    Color cardColor,
    Color accentGreen,
    bool isDark,
    int estimatedTotal,
  ) {
    switch (_currentBottomNavIndex) {
      case 1:
        return _buildMobileHistoryView(state, textColor, subtextColor, cardColor, accentGreen);
      case 2:
        return _buildMobileRequestsView(state, textColor, subtextColor, cardColor, accentGreen);
      case 3:
        return _buildMobileProfileView(state, textColor, subtextColor, cardColor, accentGreen, isDark);
      case 0:
      default:
        return _buildMobileHomeView(state, textColor, subtextColor, cardColor, accentGreen, isDark, estimatedTotal);
    }
  }

  Widget _buildMobileHomeView(
    EcoRouteState state,
    Color textColor,
    Color subtextColor,
    Color cardColor,
    Color accentGreen,
    bool isDark,
    int estimatedTotal,
  ) {
    return SingleChildScrollView(
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
      );
  }

  Widget _buildMobileHistoryView(
    EcoRouteState state,
    Color textColor,
    Color subtextColor,
    Color cardColor,
    Color accentGreen,
  ) {
    final requests = state.residentRequests;
    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            'Pickup History & Receipts',
            style: TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.w800,
              color: textColor,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            'Archived collection logs and verified municipal weight slips',
            style: TextStyle(fontSize: 12, color: subtextColor),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: cardColor,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: AntigravityTheme.border(context)),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Total Requests', style: TextStyle(fontSize: 11, color: subtextColor)),
                      const SizedBox(height: 4),
                      Text('${requests.length}', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: textColor)),
                    ],
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: cardColor,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: AntigravityTheme.border(context)),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('EcoCredits', style: TextStyle(fontSize: 11, color: subtextColor)),
                      const SizedBox(height: 4),
                      Text('${state.ecoCredits} pts', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: accentGreen)),
                    ],
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          if (requests.isEmpty)
            Container(
              padding: const EdgeInsets.symmetric(vertical: 40, horizontal: 20),
              decoration: BoxDecoration(
                color: cardColor,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: AntigravityTheme.border(context)),
              ),
              child: Column(
                children: [
                  Icon(Icons.history_toggle_off, size: 52, color: subtextColor.withOpacity(0.5)),
                  const SizedBox(height: 12),
                  Text(
                    'No Past Pickups Yet',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: textColor),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    'Once a tricycle completes your waste pickup, digital receipts and weight logs appear here.',
                    textAlign: TextAlign.center,
                    style: TextStyle(fontSize: 12, color: subtextColor),
                  ),
                  const SizedBox(height: 16),
                  ElevatedButton.icon(
                    onPressed: () => _handleInstantBooking(context),
                    icon: const Icon(Icons.flash_on, size: 16),
                    label: const Text('Schedule First Pickup'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: accentGreen,
                      foregroundColor: Colors.white,
                    ),
                  ),
                ],
              ),
            )
          else
            ...requests.map((req) {
              final status = req['status'] ?? 'Completed';
              final isCompleted = status == 'Completed' || status == 'Collected';
              return Container(
                margin: const EdgeInsets.only(bottom: 12),
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: cardColor,
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: AntigravityTheme.border(context)),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          req['id'] ?? 'ORD-REF',
                          style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: textColor),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                          decoration: BoxDecoration(
                            color: isCompleted
                                ? accentGreen.withOpacity(0.15)
                                : const Color(0xFFF57C00).withOpacity(0.15),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Text(
                            status,
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.bold,
                              color: isCompleted ? accentGreen : const Color(0xFFF57C00),
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Text(
                      '${req['sacks'] ?? 1} Sacks • ${req['wasteType'] ?? 'Household Waste'}',
                      style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: textColor),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '${req['address'] ?? 'Arua Municipality'} • ${req['date'] ?? 'Recent'}',
                      style: TextStyle(fontSize: 12, color: subtextColor),
                    ),
                    const SizedBox(height: 10),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'UGX ${req['fee'] ?? 5000}',
                          style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: accentGreen),
                        ),
                        TextButton.icon(
                          onPressed: () {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(content: Text('Receipt #${req['id'] ?? 'ORD'} verified on municipal ledger.')),
                            );
                          },
                          icon: const Icon(Icons.receipt, size: 14),
                          label: const Text('Digital Receipt', style: TextStyle(fontSize: 12)),
                        ),
                      ],
                    ),
                  ],
                ),
              );
            }),
        ],
      ),
    );
  }

  Widget _buildMobileRequestsView(
    EcoRouteState state,
    Color textColor,
    Color subtextColor,
    Color cardColor,
    Color accentGreen,
  ) {
    final active = state.activePickup;
    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Collection Requests',
                style: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.w800,
                  color: textColor,
                ),
              ),
              IconButton(
                tooltip: 'Book New Pickup',
                icon: Icon(Icons.add_circle, color: accentGreen, size: 28),
                onPressed: () => _handleInstantBooking(context),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            'Track your live collection dispatch and pending orders',
            style: TextStyle(fontSize: 12, color: subtextColor),
          ),
          const SizedBox(height: 16),
          if (active != null) ...[
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: cardColor,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: accentGreen, width: 1.5),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(6),
                            decoration: BoxDecoration(
                              color: accentGreen.withOpacity(0.15),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Icon(Icons.electric_moped, color: accentGreen, size: 18),
                          ),
                          const SizedBox(width: 8),
                          Text(
                            'ACTIVE PICKUP DISPATCH',
                            style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: accentGreen),
                          ),
                        ],
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: accentGreen.withOpacity(0.15),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Text(
                          active['status'] ?? 'Rider Dispatched',
                          style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: accentGreen),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 14),
                  Text(
                    'Order ${active['id'] ?? 'TRIC-REQ'}',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: textColor),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '${active['sacks'] ?? 3} Sacks • ${active['wasteType'] ?? 'Household Waste'}',
                    style: TextStyle(fontSize: 13, color: textColor),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Address: ${active['address'] ?? 'Ayivu Division, Arua'}',
                    style: TextStyle(fontSize: 12, color: subtextColor),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'ETA: ${active['eta'] ?? '12 mins'} • Fare: UGX ${active['fee'] ?? 7500}',
                    style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: textColor),
                  ),
                  const SizedBox(height: 14),
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton.icon(
                          onPressed: () {
                            state.cancelActivePickup();
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(content: Text('Pickup request cancelled.')),
                            );
                          },
                          icon: const Icon(Icons.close, size: 16, color: Colors.redAccent),
                          label: const Text('Cancel', style: TextStyle(color: Colors.redAccent, fontSize: 12)),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: FilledButton.icon(
                          onPressed: () => launchEcoRouteCall(),
                          icon: const Icon(Icons.call, size: 16),
                          label: const Text('Call Dispatch', style: TextStyle(fontSize: 12)),
                          style: FilledButton.styleFrom(backgroundColor: accentGreen),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
          ] else ...[
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: cardColor,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: AntigravityTheme.border(context)),
              ),
              child: Column(
                children: [
                  Icon(Icons.check_circle_outline, size: 44, color: accentGreen),
                  const SizedBox(height: 10),
                  Text(
                    'No Active Collection in Progress',
                    style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: textColor),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    'All scheduled pickups are cleared. Tap below whenever your waste sacks are ready.',
                    textAlign: TextAlign.center,
                    style: TextStyle(fontSize: 12, color: subtextColor),
                  ),
                  const SizedBox(height: 14),
                  FilledButton.icon(
                    onPressed: () => _handleInstantBooking(context),
                    icon: const Icon(Icons.local_shipping, size: 16),
                    label: const Text('Book Collection Pickup'),
                    style: FilledButton.styleFrom(backgroundColor: accentGreen),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
          ],
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: cardColor,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: AntigravityTheme.border(context)),
            ),
            child: Row(
              children: [
                const Icon(Icons.lightbulb_outline, color: Color(0xFFF57C00), size: 24),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Collection Tip', style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: textColor)),
                      const SizedBox(height: 2),
                      Text(
                        'Separate organic kitchen waste from dry plastics for faster weighing & bonus EcoCredits.',
                        style: TextStyle(fontSize: 11, color: subtextColor),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMobileProfileView(
    EcoRouteState state,
    Color textColor,
    Color subtextColor,
    Color cardColor,
    Color accentGreen,
    bool isDark,
  ) {
    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Container(
            padding: const EdgeInsets.all(18),
            decoration: BoxDecoration(
              color: cardColor,
              borderRadius: BorderRadius.circular(18),
              border: Border.all(color: AntigravityTheme.border(context)),
            ),
            child: Column(
              children: [
                CircleAvatar(
                  backgroundColor: accentGreen,
                  radius: 34,
                  child: Text(
                    state.userName.isNotEmpty ? state.userName[0].toUpperCase() : 'R',
                    style: const TextStyle(color: Colors.white, fontSize: 28, fontWeight: FontWeight.bold),
                  ),
                ),
                const SizedBox(height: 12),
                Text(
                  state.userName.isNotEmpty ? state.userName : 'Resident Member',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: textColor),
                ),
                const SizedBox(height: 4),
                Text(
                  state.userEmail.isNotEmpty ? state.userEmail : 'resident@ecoroute.ug',
                  style: TextStyle(fontSize: 12, color: subtextColor),
                ),
                const SizedBox(height: 8),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: accentGreen.withOpacity(0.15),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    'Active Resident • ${state.userCell.isNotEmpty ? state.userCell : 'Ayivu Ward'}',
                    style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: accentGreen),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 14),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: cardColor,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: AntigravityTheme.border(context)),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: accentGreen.withOpacity(0.12),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Icon(Icons.eco, color: accentGreen, size: 24),
                    ),
                    const SizedBox(width: 12),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('EcoCredits Balance', style: TextStyle(fontSize: 11, color: subtextColor)),
                        const SizedBox(height: 2),
                        Text('${state.ecoCredits} Points', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: accentGreen)),
                      ],
                    ),
                  ],
                ),
                OutlinedButton(
                  onPressed: () {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('EcoCredits can be redeemed for biodegradable trash sacks at municipal depots.')),
                    );
                  },
                  child: const Text('Redeem', style: TextStyle(fontSize: 12)),
                ),
              ],
            ),
          ),
          const SizedBox(height: 14),
          Container(
            decoration: BoxDecoration(
              color: cardColor,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: AntigravityTheme.border(context)),
            ),
            child: Column(
              children: [
                ListTile(
                  leading: Icon(Icons.tune, color: textColor),
                  title: Text('Edit Profile & Password', style: TextStyle(fontSize: 14, color: textColor)),
                  trailing: const Icon(Icons.chevron_right, size: 20),
                  onTap: () => showEcoRouteProfileSheet(context),
                ),
                Divider(height: 1, color: AntigravityTheme.border(context)),
                SwitchListTile(
                  secondary: Icon(isDark ? Icons.dark_mode : Icons.light_mode, color: textColor),
                  title: Text('Dark Theme', style: TextStyle(fontSize: 14, color: textColor)),
                  value: state.isDarkMode,
                  onChanged: (_) => state.toggleTheme(),
                ),
                Divider(height: 1, color: AntigravityTheme.border(context)),
                ListTile(
                  leading: const Icon(Icons.phone_in_talk, color: Color(0xFF2E7D32)),
                  title: Text('Municipal Operations Hotline', style: TextStyle(fontSize: 14, color: textColor)),
                  subtitle: const Text(kEcoRouteSupportPhone, style: TextStyle(fontSize: 12)),
                  trailing: const Icon(Icons.call, size: 18, color: Color(0xFF2E7D32)),
                  onTap: () => launchEcoRouteCall(),
                ),
                Divider(height: 1, color: AntigravityTheme.border(context)),
                ListTile(
                  leading: const Icon(Icons.chat, color: Color(0xFF25D366)),
                  title: Text('WhatsApp Operations', style: TextStyle(fontSize: 14, color: textColor)),
                  subtitle: const Text('Chat with Arua Dispatch', style: TextStyle(fontSize: 12)),
                  trailing: const Icon(Icons.arrow_forward_ios, size: 14),
                  onTap: () => launchEcoRouteWhatsApp(),
                ),
                Divider(height: 1, color: AntigravityTheme.border(context)),
                ListTile(
                  leading: const Icon(Icons.logout, color: Colors.redAccent),
                  title: const Text('Log Out', style: TextStyle(fontSize: 14, color: Colors.redAccent, fontWeight: FontWeight.bold)),
                  onTap: () {
                    state.logout(context);
                  },
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),
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
                          const SizedBox(width: 8),
                          IconButton(
                            tooltip: 'Sign Out',
                            icon: const Icon(Icons.logout, color: Colors.redAccent),
                            onPressed: () => state.logout(context),
                          ),
                          const SizedBox(width: 12),
                          FilledButton.icon(
                            onPressed: () => _handleInstantBooking(context),
                            icon: const Icon(Icons.flash_on, size: 16),
                            label: const Text('Book Commercial Pickup'),
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
                  child: _buildDesktopBody(state, textColor, subtextColor, cardColor, accentGreen, isDark),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDesktopBody(
    EcoRouteState state,
    Color textColor,
    Color subtextColor,
    Color cardColor,
    Color accentGreen,
    bool isDark,
  ) {
    switch (_selectedSidebarNav) {
      case 1:
        return _buildDesktopHistoryView(state, textColor, subtextColor, cardColor, accentGreen);
      case 2:
        return _buildDesktopAnalyticsView(state, textColor, subtextColor, cardColor, accentGreen);
      case 3:
        return _buildDesktopWalletView(state, textColor, subtextColor, cardColor, accentGreen);
      case 4:
        return _buildDesktopSupportView(state, textColor, subtextColor, cardColor, accentGreen);
      case 0:
      default:
        return _buildDesktopDashboardHub(state, textColor, subtextColor, cardColor, accentGreen, isDark);
    }
  }

  Widget _buildDesktopDashboardHub(
    EcoRouteState state,
    Color textColor,
    Color subtextColor,
    Color cardColor,
    Color accentGreen,
    bool isDark,
  ) {
    return SingleChildScrollView(
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
                );
  }

  Widget _buildDesktopHistoryView(
    EcoRouteState state,
    Color textColor,
    Color subtextColor,
    Color cardColor,
    Color accentGreen,
  ) {
    final requests = state.residentRequests;
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'HISTORICAL COLLECTION LEDGER',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: textColor),
                  ),
                  const SizedBox(height: 4),
                  Text('Complete archive of household waste collections and verified municipal receipts',
                      style: TextStyle(fontSize: 12, color: subtextColor)),
                ],
              ),
              FilledButton.icon(
                onPressed: () => _handleInstantBooking(context),
                icon: const Icon(Icons.add, size: 16),
                label: const Text('Schedule Collection'),
                style: FilledButton.styleFrom(backgroundColor: accentGreen),
              ),
            ],
          ),
          const SizedBox(height: 20),
          Container(
            width: double.infinity,
            decoration: BoxDecoration(
              color: cardColor,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: AntigravityTheme.border(context)),
            ),
            padding: const EdgeInsets.all(20),
            child: requests.isEmpty
                ? Center(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(vertical: 40),
                      child: Column(
                        children: [
                          Icon(Icons.history, size: 48, color: subtextColor.withOpacity(0.5)),
                          const SizedBox(height: 12),
                          Text('No collection history recorded yet',
                              style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: textColor)),
                          const SizedBox(height: 6),
                          Text('Completed waste pickups will generate digital receipts here.',
                              style: TextStyle(fontSize: 12, color: subtextColor)),
                        ],
                      ),
                    ),
                  )
                : Column(
                    children: [
                      Row(
                        children: [
                          Expanded(flex: 2, child: Text('ORDER ID', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: subtextColor))),
                          Expanded(flex: 3, child: Text('WASTE TYPE & SACKS', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: subtextColor))),
                          Expanded(flex: 3, child: Text('ADDRESS', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: subtextColor))),
                          Expanded(flex: 2, child: Text('DATE', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: subtextColor))),
                          Expanded(flex: 2, child: Text('STATUS', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: subtextColor))),
                          Expanded(flex: 2, child: Text('FEE (UGX)', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: subtextColor))),
                        ],
                      ),
                      const Divider(height: 24),
                      ...requests.map((req) {
                        return Padding(
                          padding: const EdgeInsets.symmetric(vertical: 10),
                          child: Row(
                            children: [
                              Expanded(flex: 2, child: Text(req['id'] ?? 'REF', style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: textColor))),
                              Expanded(flex: 3, child: Text('${req['sacks'] ?? 1} Sacks (${req['wasteType'] ?? 'General'})', style: TextStyle(fontSize: 12, color: textColor))),
                              Expanded(flex: 3, child: Text(req['address'] ?? 'Ayivu Zone', style: TextStyle(fontSize: 12, color: subtextColor))),
                              Expanded(flex: 2, child: Text(req['date'] ?? 'Recent', style: TextStyle(fontSize: 12, color: subtextColor))),
                              Expanded(
                                flex: 2,
                                child: Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                  decoration: BoxDecoration(
                                    color: accentGreen.withOpacity(0.12),
                                    borderRadius: BorderRadius.circular(6),
                                  ),
                                  child: Text(req['status'] ?? 'Completed', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: accentGreen)),
                                ),
                              ),
                              Expanded(flex: 2, child: Text('${req['fee'] ?? 5000}', style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: textColor))),
                            ],
                          ),
                        );
                      }),
                    ],
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildDesktopAnalyticsView(
    EcoRouteState state,
    Color textColor,
    Color subtextColor,
    Color cardColor,
    Color accentGreen,
  ) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('RESIDENTIAL DIVERSION & ENVIRONMENTAL IMPACT',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: textColor)),
          const SizedBox(height: 4),
          Text('Key sustainability performance indicators tracked across Arua municipality',
              style: TextStyle(fontSize: 12, color: subtextColor)),
          const SizedBox(height: 20),
          Row(
            children: [
              Expanded(
                child: Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: cardColor,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: AntigravityTheme.border(context)),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Estimated Plastic Diverted', style: TextStyle(fontSize: 12, color: subtextColor)),
                      const SizedBox(height: 8),
                      Text('184.5 kg', style: TextStyle(fontSize: 26, fontWeight: FontWeight.bold, color: accentGreen)),
                      const SizedBox(height: 4),
                      Text('+18% from last month', style: TextStyle(fontSize: 11, color: accentGreen)),
                    ],
                  ),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: cardColor,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: AntigravityTheme.border(context)),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Organic Compost Yield', style: TextStyle(fontSize: 12, color: subtextColor)),
                      const SizedBox(height: 8),
                      Text('320.0 kg', style: TextStyle(fontSize: 26, fontWeight: FontWeight.bold, color: const Color(0xFFF57C00))),
                      const SizedBox(height: 4),
                      Text('Transferred to local farms', style: TextStyle(fontSize: 11, color: subtextColor)),
                    ],
                  ),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: cardColor,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: AntigravityTheme.border(context)),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Earned EcoCredits', style: TextStyle(fontSize: 12, color: subtextColor)),
                      const SizedBox(height: 8),
                      Text('${state.ecoCredits} pts', style: TextStyle(fontSize: 26, fontWeight: FontWeight.bold, color: const Color(0xFF1976D2))),
                      const SizedBox(height: 4),
                      Text('Available for subsidy redemption', style: TextStyle(fontSize: 11, color: subtextColor)),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildDesktopWalletView(
    EcoRouteState state,
    Color textColor,
    Color subtextColor,
    Color cardColor,
    Color accentGreen,
  ) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('WALLET MATRIX & MUNICIPAL CREDITS',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: textColor)),
          const SizedBox(height: 4),
          Text('Manage stored EcoCredits, payment methods, and automated collection fees',
              style: TextStyle(fontSize: 12, color: subtextColor)),
          const SizedBox(height: 20),
          Container(
            padding: const EdgeInsets.all(24),
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
                    Text('EcoCredits Balance', style: TextStyle(fontSize: 13, color: subtextColor)),
                    const SizedBox(height: 6),
                    Text('${state.ecoCredits} Points', style: TextStyle(fontSize: 32, fontWeight: FontWeight.bold, color: accentGreen)),
                    const SizedBox(height: 6),
                    Text('Equivalent to ${(state.ecoCredits * 100)} UGX in waste collection fee vouchers', style: TextStyle(fontSize: 12, color: textColor)),
                  ],
                ),
                FilledButton.icon(
                  onPressed: () {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Voucher redemption active for your next collection order.')),
                    );
                  },
                  icon: const Icon(Icons.redeem, size: 16),
                  label: const Text('Redeem Vouchers'),
                  style: FilledButton.styleFrom(backgroundColor: accentGreen),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDesktopSupportView(
    EcoRouteState state,
    Color textColor,
    Color subtextColor,
    Color cardColor,
    Color accentGreen,
  ) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('MUNICIPAL OPERATIONS & RESIDENT HELP DESK',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: textColor)),
          const SizedBox(height: 4),
          Text('Direct hotline, WhatsApp dispatch link, and operational guidance for Arua City',
              style: TextStyle(fontSize: 12, color: subtextColor)),
          const SizedBox(height: 20),
          Row(
            children: [
              Expanded(
                child: Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: cardColor,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: AntigravityTheme.border(context)),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Icon(Icons.phone_in_talk, color: accentGreen, size: 24),
                          const SizedBox(width: 8),
                          Text('Direct Dispatch Line', style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: textColor)),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Text(kEcoRouteSupportPhone, style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: accentGreen)),
                      const SizedBox(height: 12),
                      FilledButton.icon(
                        onPressed: () => launchEcoRouteCall(),
                        icon: const Icon(Icons.call, size: 16),
                        label: const Text('Call Operations'),
                        style: FilledButton.styleFrom(backgroundColor: accentGreen),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: cardColor,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: AntigravityTheme.border(context)),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          const Icon(Icons.chat, color: Color(0xFF25D366), size: 24),
                          const SizedBox(width: 8),
                          Text('WhatsApp Field Dispatch', style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: textColor)),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Text('Instant chat with Arua Central Dispatch', style: TextStyle(fontSize: 13, color: subtextColor)),
                      const SizedBox(height: 12),
                      FilledButton.icon(
                        onPressed: () => launchEcoRouteWhatsApp(),
                        icon: const Icon(Icons.send, size: 16),
                        label: const Text('Open WhatsApp'),
                        style: FilledButton.styleFrom(backgroundColor: const Color(0xFF25D366)),
                      ),
                    ],
                  ),
                ),
              ),
            ],
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
    String currentWasteType = _selectedWasteType;
    int currentSacks = _sackCount;
    bool isCommercial = false;
    String businessName = '';
    String? photoBase64;
    double? lockedLat;
    double? lockedLng;
    String locationLabel = 'Arua Central & Nearby Districts';
    String paymentMethod = 'MoMo';
    bool isCapturing = false;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: AntigravityTheme.card(context),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setModalState) {
          final isDark = AntigravityTheme.isDark(ctx);
          final textColor = AntigravityTheme.textPrimary(ctx);
          final subtextColor = AntigravityTheme.textSecondary(ctx);
          final accentGreen = AntigravityTheme.ecoAccent(ctx);

          int rate = isCommercial ? 3500 : (currentWasteType == 'Bulky / Construction' ? 5000 : 2500);
          int total = currentSacks * rate;

          return Padding(
            padding: EdgeInsets.only(
              top: 24,
              left: 24,
              right: 24,
              bottom: MediaQuery.of(ctx).viewInsets.bottom + 24,
            ),
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Row(
                        children: [
                          Icon(Icons.local_shipping, color: accentGreen),
                          const SizedBox(width: 8),
                          Text(
                            'Commercial Waste Collection',
                            style: TextStyle(fontSize: 17, fontWeight: FontWeight.bold, color: textColor),
                          ),
                        ],
                      ),
                      IconButton(
                        icon: const Icon(Icons.close),
                        onPressed: () => Navigator.pop(ctx),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Rapid pickup across Arua City, Trading Centers & West Nile districts',
                    style: TextStyle(fontSize: 12, color: subtextColor),
                  ),
                  const SizedBox(height: 16),

                  // Waste Type Selection
                  Text('SELECT WASTE TYPE', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: subtextColor)),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      'Household Waste',
                      'Trading Center Waste',
                      'Commercial Packaging',
                      'Recyclable Plastics',
                      'Organic Compost',
                      'Bulky / Construction',
                    ].map((type) {
                      final selected = currentWasteType == type;
                      return ChoiceChip(
                        label: Text(type, style: TextStyle(fontSize: 12, color: selected ? Colors.white : textColor)),
                        selected: selected,
                        selectedColor: accentGreen,
                        onSelected: (val) {
                          if (val) setModalState(() => currentWasteType = type);
                        },
                      );
                    }).toList(),
                  ),
                  const SizedBox(height: 16),

                  // Sack Count
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text('Volume: $currentSacks Sack\', style: TextStyle(fontWeight: FontWeight.bold, color: textColor)),
                      Text('$total UGX', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: accentGreen)),
                    ],
                  ),
                  Slider(
                    value: currentSacks.toDouble(),
                    min: 1,
                    max: 20,
                    divisions: 19,
                    activeColor: accentGreen,
                    label: '$currentSacks Sacks',
                    onChanged: (val) => setModalState(() => currentSacks = val.round()),
                  ),
                  const SizedBox(height: 12),

                  // Commercial Enterprise Toggle
                  SwitchListTile(
                    contentPadding: EdgeInsets.zero,
                    title: Text('Commercial Business / Enterprise', style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: textColor)),
                    subtitle: Text('Enable B2B wholesale invoice with TIN details', style: TextStyle(fontSize: 11, color: subtextColor)),
                    value: isCommercial,
                    activeColor: accentGreen,
                    onChanged: (val) => setModalState(() => isCommercial = val),
                  ),
                  if (isCommercial) ...[
                    const SizedBox(height: 8),
                    TextField(
                      decoration: const InputDecoration(
                        labelText: 'Business / Shop / Hotel Name',
                        border: OutlineInputBorder(),
                        contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                      ),
                      onChanged: (val) => businessName = val,
                    ),
                  ],
                  const SizedBox(height: 14),

                  // Low-Memory Camera & GPS Capture
                  Container(
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: isDark ? const Color(0xFF222222) : const Color(0xFFF3F7F4),
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(color: AntigravityTheme.border(ctx)),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Row(
                          children: [
                            Icon(Icons.camera_alt, color: accentGreen, size: 20),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                photoBase64 != null ? 'Waste Photo & GPS Coordinates Locked' : 'Waste Photo & GPS Verification',
                                style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: textColor),
                              ),
                            ),
                            if (photoBase64 != null)
                              const Icon(Icons.check_circle, color: Colors.green, size: 18),
                          ],
                        ),
                        const SizedBox(height: 8),
                        Text(
                          locationLabel,
                          style: TextStyle(fontSize: 11, color: subtextColor),
                        ),
                        const SizedBox(height: 10),
                        OutlinedButton.icon(
                          onPressed: isCapturing
                              ? null
                              : () async {
                                  setModalState(() => isCapturing = true);
                                  try {
                                    final picker = ImagePicker();
                                    // Memory-optimized: 800x800 downscaling, 65% quality to keep RAM < 5MB
                                    final xfile = await picker.pickImage(
                                      source: ImageSource.camera,
                                      maxWidth: 800,
                                      maxHeight: 800,
                                      imageQuality: 65,
                                    );
                                    if (xfile != null) {
                                      final bytes = await xfile.readAsBytes();
                                      photoBase64 = base64Encode(bytes);
                                    }
                                  } catch (e) {
                                    debugPrint('Camera capture fallback notice: $e');
                                  }

                                  try {
                                    const locService = LocationService();
                                    final loc = await locService.getCurrentUserLocation();
                                    if (loc.latitude != null && loc.longitude != null) {
                                      lockedLat = loc.latitude;
                                      lockedLng = loc.longitude;
                                      locationLabel = 'GPS Coordinates: \, \ (West Nile)';
                                    }
                                  } catch (e) {
                                    debugPrint('Location service fallback notice: $e');
                                  }

                                  setModalState(() => isCapturing = false);
                                },
                          icon: isCapturing
                              ? const SizedBox(width: 14, height: 14, child: CircularProgressIndicator(strokeWidth: 2))
                              : const Icon(Icons.add_a_photo, size: 16),
                          label: Text(
                            photoBase64 != null ? 'Retake Photo & Relock GPS' : 'Snap Photo & Lock GPS',
                            style: const TextStyle(fontSize: 12),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 18),

                  // Payment Method
                  Row(
                    children: [
                      Expanded(
                        child: RadioListTile<String>(
                          title: const Text('MTN/Airtel MoMo', style: TextStyle(fontSize: 12)),
                          value: 'MoMo',
                          groupValue: paymentMethod,
                          activeColor: accentGreen,
                          contentPadding: EdgeInsets.zero,
                          onChanged: (val) => setModalState(() => paymentMethod = val!),
                        ),
                      ),
                      Expanded(
                        child: RadioListTile<String>(
                          title: const Text('Cash on Pickup', style: TextStyle(fontSize: 12)),
                          value: 'Cash',
                          groupValue: paymentMethod,
                          activeColor: accentGreen,
                          contentPadding: EdgeInsets.zero,
                          onChanged: (val) => setModalState(() => paymentMethod = val!),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),

                  FilledButton.icon(
                    onPressed: () {
                      Navigator.pop(ctx);
                      final address = locationLabel.contains('GPS')
                          ? 'Commercial Pickup, $locationLabel'
                          : 'Arua Central & Nearby Trading Center';

                      EcoRouteState.instance.bookPickup(
                        sacks: currentSacks,
                        wasteType: currentWasteType,
                        address: address,
                        isInstant: true,
                        paymentMethod: paymentMethod,
                        photoBase64: photoBase64,
                        latitude: lockedLat,
                        longitude: lockedLng,
                        isCommercial: isCommercial,
                        businessName: businessName.isNotEmpty ? businessName : null,
                      );

                      final active = EcoRouteState.instance.activePickup;
                      final pin = active?['verificationCode'] ?? '----';

                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text('Collection dispatched! Handover PIN: $pin. Show this PIN to your driver.'),
                          backgroundColor: const Color(0xFF2E7D32),
                          duration: const Duration(seconds: 6),
                        ),
                      );
                    },
                    icon: const Icon(Icons.electric_moped, size: 18),
                    label: Text('Confirm & Dispatch Tricycle ($total UGX)'),
                    style: FilledButton.styleFrom(
                      backgroundColor: accentGreen,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                  ),
                ],
              ),
            ),
          );
        },
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
