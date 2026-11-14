import 'dart:convert';
import 'package:image_picker/image_picker.dart';
import '../../core/services/location_service.dart';
import 'package:flutter/material.dart';

import '../../core/layout/adaptive_layout.dart';
import '../../domain/entities/pickup_request.dart';
import '../../domain/enums/waste_type.dart';
import 'package:latlong2/latlong.dart';
import '../common/widgets/eco_carto_map.dart';
import '../payment/digital_receipt_dialog.dart';
import '../common/widgets/profile_photo_manager_sheet.dart';
import '../common/widgets/feedback_dialog.dart';
import '../../main.dart';
import 'widgets/eco_gemini_assistant_sheet.dart';

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
  static const int _pricePerSackUgx = 2500;

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
        currentIndex: _currentBottomNavIndex.clamp(0, 2),
        onTap: (index) => setState(() => _currentBottomNavIndex = index),
        backgroundColor: cardColor,
        selectedItemColor: accentGreen,
        unselectedItemColor: subtextColor,
        type: BottomNavigationBarType.fixed,
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.home_outlined),
            activeIcon: Icon(Icons.home),
            label: 'Home',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.notifications_outlined),
            activeIcon: Icon(Icons.notifications),
            label: 'Alerts',
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
        return _buildMobileAlertsView(state, textColor, subtextColor, cardColor, accentGreen, isDark);
      case 2:
        return _buildMobileAccountView(state, textColor, subtextColor, cardColor, accentGreen, isDark);
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
    final displayName = state.userName.isNotEmpty
        ? state.userName
        : (state.userEmail.isNotEmpty ? state.userEmail.split('@').first : 'EcoRoute Resident');
    final displayLocation = state.userCell.isNotEmpty ? '${state.userCell}, Arua' : 'Arua, Uganda';

    return SingleChildScrollView(
      padding: EdgeInsets.zero,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // =================================================================
          // 1. TOP GREEN PROFILE HERO (EXACTLY MATCHES IMAGE 1 & 2)
          // =================================================================
          Container(
            padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
            decoration: BoxDecoration(
              color: isDark ? const Color(0xFF132A1C) : const Color(0xFF0F3822),
              borderRadius: const BorderRadius.vertical(bottom: Radius.circular(28)),
            ),
            child: Column(
              children: [
                // Top Brand Row
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.eco, color: accentGreen, size: 26),
                    const SizedBox(width: 8),
                    const Text(
                      'ecoRoute',
                      style: TextStyle(
                        fontFamily: 'Satoshi',
                        fontSize: 22,
                        fontWeight: FontWeight.w900,
                        letterSpacing: 0.5,
                        color: Colors.white,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 18),

                // User Avatar Circle (WhatsApp Style Management)
                GestureDetector(
                  onTap: () => showProfilePhotoManagerSheet(context),
                  child: Stack(
                    children: [
                      CircleAvatar(
                        radius: 36,
                        backgroundColor: Colors.white.withOpacity(0.2),
                        child: CircleAvatar(
                          radius: 34,
                          backgroundColor: const Color(0xFFCFD8DC),
                          child: state.userPhotoBase64 != null && state.userPhotoBase64!.isNotEmpty
                              ? ClipOval(
                                  child: Image.memory(
                                    base64Decode(state.userPhotoBase64!),
                                    width: 68,
                                    height: 68,
                                    fit: BoxFit.cover,
                                  ),
                                )
                              : const Icon(Icons.person, size: 42, color: Colors.white),
                        ),
                      ),
                      Positioned(
                        bottom: 0,
                        right: 0,
                        child: Container(
                          padding: const EdgeInsets.all(4),
                          decoration: const BoxDecoration(
                            color: Color(0xFF2E7D32),
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(Icons.camera_alt, size: 14, color: Colors.white),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 12),

                // User Name
                Text(
                  displayName,
                  style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.w800,
                    color: Colors.white,
                    letterSpacing: 0.2,
                  ),
                ),
                const SizedBox(height: 4),

                // Location Subtitle
                Text(
                  displayLocation,
                  style: TextStyle(
                    fontSize: 13,
                    color: Colors.white.withOpacity(0.8),
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),

          // =================================================================
          // 2. PRIMARY ACTION CARDS (IMAGE 1 MOBILE VIEWPORT)
          // =================================================================
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // CARD 1: PICKUP HISTORY
                _buildHomeActionCard(
                  icon: Icons.local_shipping_outlined,
                  title: 'Pickup History',
                  subtitle: 'View past & scheduled collections',
                  cardColor: cardColor,
                  textColor: textColor,
                  subtextColor: subtextColor,
                  accentColor: accentGreen,
                  onTap: () => _showHistorySheet(context, state, textColor, subtextColor, cardColor, accentGreen),
                ),
                const SizedBox(height: 12),

                // CARD 2: SERVICE ADDRESSES
                _buildHomeActionCard(
                  icon: Icons.location_on_outlined,
                  title: 'Service Addresses',
                  subtitle: 'Manage pickup points & landmarks',
                  cardColor: cardColor,
                  textColor: textColor,
                  subtextColor: subtextColor,
                  accentColor: accentGreen,
                  onTap: () => _showAddressesSheet(context, state, textColor, subtextColor, cardColor, accentGreen),
                ),
                const SizedBox(height: 14),

                // CARD 3: VIBRANT GREEN REQUEST PICKUP BUTTON (HERO BUTTON)
                SizedBox(
                  height: 56,
                  child: ElevatedButton(
                    onPressed: () => _handleInstantBooking(context),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF00C853),
                      foregroundColor: Colors.white,
                      elevation: 2,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                      padding: const EdgeInsets.symmetric(horizontal: 18),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.delete_outline, size: 24, color: Colors.white),
                        const Spacer(),
                        const Text(
                          'REQUEST PICKUP',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w900,
                            letterSpacing: 1.1,
                            color: Colors.white,
                          ),
                        ),
                        const Spacer(),
                        const Icon(Icons.local_shipping, size: 24, color: Colors.white),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 14),

                // CARD 4: ecoRoute Bot (FIRST-CLASS AI ASSISTANT ON HOME SCREEN)
                InkWell(
                  onTap: () => showEcoRouteBotChatSheet(context),
                  borderRadius: BorderRadius.circular(16),
                  child: Container(
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: isDark ? const Color(0xFF162E20) : const Color(0xFFE8F5E9),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: const Color(0xFF00A884).withOpacity(0.4), width: 1.2),
                      boxShadow: [
                        BoxShadow(
                          color: const Color(0xFF00A884).withOpacity(0.08),
                          blurRadius: 10,
                          offset: const Offset(0, 3),
                        ),
                      ],
                    ),
                    child: Row(
                      children: [
                        Stack(
                          alignment: Alignment.bottomRight,
                          children: [
                            Container(
                              width: 46,
                              height: 46,
                              decoration: const BoxDecoration(
                                color: Color(0xFF00A884),
                                shape: BoxShape.circle,
                              ),
                              child: const Icon(Icons.smart_toy_outlined, color: Colors.white, size: 26),
                            ),
                            Container(
                              width: 12,
                              height: 12,
                              decoration: BoxDecoration(
                                color: const Color(0xFF25D366),
                                shape: BoxShape.circle,
                                border: Border.all(
                                  color: isDark ? const Color(0xFF162E20) : const Color(0xFFE8F5E9),
                                  width: 2,
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Text(
                                    'ecoRoute Bot',
                                    style: TextStyle(
                                      fontSize: 15,
                                      fontWeight: FontWeight.w800,
                                      color: textColor,
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                    decoration: BoxDecoration(
                                      color: const Color(0xFF25D366).withOpacity(0.2),
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                    child: const Text(
                                      'ONLINE',
                                      style: TextStyle(
                                        fontSize: 9,
                                        fontWeight: FontWeight.bold,
                                        color: Color(0xFF008069),
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 2),
                              Text(
                                'WhatsApp-style instant help • 400+ Arua chats',
                                style: TextStyle(fontSize: 11.5, color: subtextColor),
                              ),
                            ],
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                          decoration: BoxDecoration(
                            color: const Color(0xFF00A884),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: const Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(
                                'Chat',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 12,
                                ),
                              ),
                              SizedBox(width: 4),
                              Icon(Icons.arrow_forward_ios, size: 10, color: Colors.white),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 12),

                // CARD 5: ecoRoute SUPPORT
                _buildHomeActionCard(
                  icon: Icons.info_outline,
                  title: 'ecoRoute Support',
                  subtitle: 'Get help with your service • +256394880352',
                  cardColor: cardColor,
                  textColor: textColor,
                  subtextColor: subtextColor,
                  accentColor: accentGreen,
                  onTap: () => _showSupportModal(context),
                ),
                const SizedBox(height: 18),

                // =============================================================
                // 3. MAP PREVIEW & ACTIVE PICKUP TRUCK EN-ROUTE (IMAGE 2 HOME)
                // =============================================================
                Container(
                  decoration: BoxDecoration(
                    color: cardColor,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: AntigravityTheme.border(context)),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      // OpenStreetMap Preview
                      ClipRRect(
                        borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
                        child: SizedBox(
                          height: 150,
                          child: EcoCartoMap(
                            center: const LatLng(3.0303, 30.9073),
                            zoom: 14.5,
                            showLandmarks: true,
                            showControls: true,
                            onLocationSelected: (pos) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: Text('Pickup pin updated: ${pos.latitude.toStringAsFixed(4)}, ${pos.longitude.toStringAsFixed(4)}'),
                                  duration: const Duration(seconds: 2),
                                ),
                              );
                            },
                          ),
                        ),
                      ),
                      Padding(
                        padding: const EdgeInsets.all(12),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Row(
                              children: [
                                const Icon(Icons.local_shipping, size: 18, color: Color(0xFF00C853)),
                                const SizedBox(width: 8),
                                Text(
                                  'Active pickup truck en-route',
                                  style: TextStyle(
                                    fontSize: 13,
                                    fontWeight: FontWeight.bold,
                                    color: textColor,
                                  ),
                                ),
                              ],
                            ),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                              decoration: BoxDecoration(
                                color: const Color(0xFF00C853).withOpacity(0.12),
                                borderRadius: BorderRadius.circular(6),
                              ),
                              child: const Text(
                                '3 min away',
                                style: TextStyle(
                                  fontSize: 11,
                                  fontWeight: FontWeight.bold,
                                  color: Color(0xFF00C853),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),

                // =============================================================
                // 4. RECENT ACTIVITIES MATRIX (IMAGE 2 HOME)
                // =============================================================
                Text(
                  'Recent Activities',
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.bold,
                    color: textColor,
                  ),
                ),
                const SizedBox(height: 10),
                Row(
                  children: [
                    Expanded(
                      child: Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: cardColor,
                          borderRadius: BorderRadius.circular(14),
                          border: Border.all(color: AntigravityTheme.border(context)),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Icon(Icons.delete_outline, size: 16, color: accentGreen),
                                const SizedBox(width: 6),
                                Expanded(
                                  child: Text(
                                    'Next Pickup',
                                    style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: textColor),
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 6),
                            Text(
                              state.residentRequests.isNotEmpty
                                  ? (state.residentRequests.first['wasteType']?.toString() ?? 'General Waste')
                                  : 'No Pickup Scheduled',
                              style: TextStyle(fontSize: 10.5, color: subtextColor),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                            const SizedBox(height: 2),
                            Text(
                              state.residentRequests.isNotEmpty
                                  ? (state.residentRequests.first['status']?.toString() ?? 'Scheduled')
                                  : 'Tap to Request',
                              style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: accentGreen),
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: InkWell(
                        onTap: () => _handleInstantBooking(context),
                        borderRadius: BorderRadius.circular(14),
                        child: Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: cardColor,
                            borderRadius: BorderRadius.circular(14),
                            border: Border.all(color: AntigravityTheme.border(context)),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Icon(Icons.calendar_month_outlined, size: 16, color: accentGreen),
                                  const SizedBox(width: 6),
                                  Expanded(
                                    child: Text(
                                      'Quick Dispatch',
                                      style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: textColor),
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 6),
                              Text(
                                'On-demand Tricycle',
                                style: TextStyle(fontSize: 10.5, color: subtextColor),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                              const SizedBox(height: 2),
                              Text(
                                'Under 15 Mins',
                                style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: accentGreen),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),

                // =============================================================
                // 5. WASTE CONFIGURATION & PRICE CALCULATOR
                // =============================================================
                Container(
                  padding: const EdgeInsets.all(14),
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
                            'Sack Details & Tariffs',
                            style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: textColor),
                          ),
                          Text(
                            '$_sackCount Sacks • ${estimatedTotal.toString().replaceAllMapped(RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'), (Match m) => '${m[1]},')} UGX',
                            style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: accentGreen),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      SliderTheme(
                        data: SliderTheme.of(context).copyWith(
                          activeTrackColor: accentGreen,
                          inactiveTrackColor: accentGreen.withOpacity(0.2),
                          thumbColor: accentGreen,
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
                      Text(
                        'Standard Household Rate: 2,500 UGX/sack • Pay via MTN MoMo, Airtel Money or Cash.',
                        style: TextStyle(fontSize: 11, color: subtextColor),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 24),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // =========================================================================
  // TAB 1: ALERTS & MESSAGES (EXACTLY MATCHES IMAGE 2 & 3)
  // =========================================================================
  Widget _buildMobileAlertsView(
    EcoRouteState state,
    Color textColor,
    Color subtextColor,
    Color cardColor,
    Color accentGreen,
    bool isDark,
  ) {
    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            'Alerts & Messages',
            style: TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.w800,
              color: textColor,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            'Real-time collection dispatches and verified receipts',
            style: TextStyle(fontSize: 12, color: subtextColor),
          ),
          const SizedBox(height: 16),

          if (state.residentRequests.isEmpty && state.activePickup == null) ...[
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 40),
              decoration: BoxDecoration(
                color: cardColor,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: AntigravityTheme.border(context)),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: 64,
                    height: 64,
                    decoration: BoxDecoration(
                      color: accentGreen.withOpacity(0.12),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(Icons.notifications_none_outlined, size: 32, color: accentGreen),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'No New Alerts',
                    style: TextStyle(fontSize: 17, fontWeight: FontWeight.bold, color: textColor),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    'Real-time collection dispatches, rider arrival updates, and digital receipts will appear here when you schedule a pickup.',
                    textAlign: TextAlign.center,
                    style: TextStyle(fontSize: 12.5, color: subtextColor, height: 1.4),
                  ),
                  const SizedBox(height: 18),
                  FilledButton.icon(
                    onPressed: () => _handleInstantBooking(context),
                    icon: const Icon(Icons.add_shopping_cart, size: 16),
                    label: const Text('Schedule Collection'),
                    style: FilledButton.styleFrom(
                      backgroundColor: accentGreen,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                    ),
                  ),
                ],
              ),
            ),
          ] else ...[
            // DYNAMIC ALERT 1: DISPATCHER EN-ROUTE
            if (state.activePickup != null) ...[
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: cardColor,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: AntigravityTheme.border(context)),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.03),
                      blurRadius: 8,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Row(
                          children: [
                            const Icon(Icons.local_shipping, color: Color(0xFFFF9800), size: 20),
                            const SizedBox(width: 8),
                            Text(
                              'Dispatcher En-Route',
                              style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: textColor),
                            ),
                          ],
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                          decoration: BoxDecoration(
                            color: const Color(0xFFFF9800).withOpacity(0.15),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(
                            state.activePickup!['status']?.toString() ?? 'In transit',
                            style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Color(0xFFFF9800)),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Tricycle assigned for ${state.activePickup!['address'] ?? 'Arua collection point'} • ETA: ${state.activePickup!['eta'] ?? 'Under 15 Mins'}',
                      style: TextStyle(fontSize: 12.5, color: subtextColor),
                    ),
                    const SizedBox(height: 14),
                    Row(
                      children: [
                        Text('Progress tracker', style: TextStyle(fontSize: 11, color: subtextColor)),
                        const SizedBox(width: 8),
                        Expanded(
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(6),
                            child: LinearProgressIndicator(
                              value: 0.70,
                              minHeight: 6,
                              backgroundColor: Colors.grey.withOpacity(0.2),
                              valueColor: const AlwaysStoppedAnimation<Color>(Color(0xFF00C853)),
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        const Icon(Icons.local_shipping, size: 16, color: Color(0xFF00C853)),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 12),
            ],

            // DYNAMIC ALERT 2: RECENT COMPLETED WASTE COLLECTION
            if (state.residentRequests.any((r) => (r['status']?.toString().toLowerCase() ?? '') == 'completed' || (r['status']?.toString().toLowerCase() ?? '') == 'collected')) ...[
              Builder(
                builder: (ctx) {
                  final comp = state.residentRequests.firstWhere(
                    (r) => (r['status']?.toString().toLowerCase() ?? '') == 'completed' || (r['status']?.toString().toLowerCase() ?? '') == 'collected',
                  );
                  return Container(
                    padding: const EdgeInsets.all(16),
                    margin: const EdgeInsets.only(bottom: 12),
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
                            Row(
                              children: [
                                const Icon(Icons.check_circle, color: Color(0xFF00C853), size: 20),
                                const SizedBox(width: 8),
                                Text(
                                  'Waste Collected',
                                  style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: textColor),
                                ),
                              ],
                            ),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                              decoration: BoxDecoration(
                                color: const Color(0xFF00C853).withOpacity(0.15),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: const Text(
                                'Verified',
                                style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Color(0xFF00C853)),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Successful ${comp['wasteType'] ?? 'Waste'} collection at ${comp['address'] ?? comp['location'] ?? 'Arua point'} • Ref ${comp['receiptSerial'] ?? comp['id'] ?? ''}',
                          style: TextStyle(fontSize: 12.5, color: subtextColor),
                        ),
                      ],
                    ),
                  );
                },
              ),
            ],

            // DYNAMIC ALERT 3: PAYMENT RECEIPT
            if (state.residentRequests.any((r) => r['price'] != null)) ...[
              Builder(
                builder: (ctx) {
                  final paid = state.residentRequests.firstWhere((r) => r['price'] != null);
                  return Container(
                    padding: const EdgeInsets.all(16),
                    margin: const EdgeInsets.only(bottom: 12),
                    decoration: BoxDecoration(
                      color: cardColor,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: AntigravityTheme.border(context)),
                    ),
                    child: Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: const Color(0xFF00C853).withOpacity(0.12),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: const Icon(Icons.payment, color: Color(0xFF00C853), size: 22),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Payment Recorded',
                                style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: textColor),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                'UGX ${paid['price']} settled via ${paid['paymentMethod'] ?? 'Mobile Money'} (${paid['id'] ?? 'Pickup'})',
                                style: TextStyle(fontSize: 12, color: subtextColor),
                              ),
                            ],
                          ),
                        ),
                        const Icon(Icons.check_circle_outline, color: Color(0xFF00C853), size: 18),
                      ],
                    ),
                  );
                },
              ),
            ],
          ],
          const SizedBox(height: 20),

          // Dynamic Active Requests from state
          if (state.residentRequests.isNotEmpty) ...[
            Text(
              'Your Active Requests',
              style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: textColor),
            ),
            const SizedBox(height: 10),
            ...state.residentRequests.map((req) {
              final status = (req['status'] as String?) ?? 'Pending';
              final isDone = status.toLowerCase() == 'completed';
              return Container(
                margin: const EdgeInsets.only(bottom: 10),
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: cardColor,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: AntigravityTheme.border(context)),
                ),
                child: Row(
                  children: [
                    Icon(
                      isDone ? Icons.check_circle : Icons.hourglass_top,
                      color: isDone ? accentGreen : Colors.orange,
                      size: 20,
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            req['wasteType'] as String? ?? 'Household Waste',
                            style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: textColor),
                          ),
                          Text(
                            '${req['sacks'] ?? 1} sack(s) • ${req['location'] ?? 'Arua Point'}',
                            style: TextStyle(fontSize: 11, color: subtextColor),
                          ),
                        ],
                      ),
                    ),
                    Text(
                      status,
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                        color: isDone ? accentGreen : Colors.orange,
                      ),
                    ),
                  ],
                ),
              );
            }),
          ],
        ],
      ),
    );
  }

  // =========================================================================
  // TAB 2: MY ECOROUTE ACCOUNT (EXACTLY MATCHES IMAGE 2 & 3)
  // =========================================================================
  Widget _buildMobileAccountView(
    EcoRouteState state,
    Color textColor,
    Color subtextColor,
    Color cardColor,
    Color accentGreen,
    bool isDark,
  ) {
    final displayName = state.userName.isNotEmpty
        ? state.userName
        : (state.userEmail.isNotEmpty ? state.userEmail.split('@').first : 'EcoRoute Resident');
    final displayLocation = state.userCell.isNotEmpty ? '${state.userCell}, Arua' : 'Arua, Uganda';

    return SingleChildScrollView(
      padding: EdgeInsets.zero,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Top Green Hero
          Container(
            padding: const EdgeInsets.fromLTRB(20, 20, 20, 26),
            decoration: BoxDecoration(
              color: isDark ? const Color(0xFF132A1C) : const Color(0xFF0F3822),
              borderRadius: const BorderRadius.vertical(bottom: Radius.circular(28)),
            ),
            child: Column(
              children: [
                const Text(
                  'My ecoRoute Account',
                  style: TextStyle(
                    fontFamily: 'Satoshi',
                    fontSize: 20,
                    fontWeight: FontWeight.w900,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: 18),
                GestureDetector(
                  onTap: () => showProfilePhotoManagerSheet(context),
                  child: Stack(
                    children: [
                      CircleAvatar(
                        radius: 36,
                        backgroundColor: Colors.white.withOpacity(0.2),
                        child: CircleAvatar(
                          radius: 34,
                          backgroundColor: const Color(0xFFCFD8DC),
                          child: state.userPhotoBase64 != null && state.userPhotoBase64!.isNotEmpty
                              ? ClipOval(
                                  child: Image.memory(
                                    base64Decode(state.userPhotoBase64!),
                                    width: 68,
                                    height: 68,
                                    fit: BoxFit.cover,
                                  ),
                                )
                              : const Icon(Icons.person, size: 42, color: Colors.white),
                        ),
                      ),
                      Positioned(
                        bottom: 0,
                        right: 0,
                        child: Container(
                          padding: const EdgeInsets.all(4),
                          decoration: const BoxDecoration(
                            color: Color(0xFF2E7D32),
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(Icons.camera_alt, size: 14, color: Colors.white),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 12),
                Text(
                  displayName,
                  style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.w800,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  displayLocation,
                  style: TextStyle(fontSize: 13, color: Colors.white.withOpacity(0.8)),
                ),
              ],
            ),
          ),

          // Menu Options (Matching Image 2 & 3)
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Container(
                  decoration: BoxDecoration(
                    color: cardColor,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: AntigravityTheme.border(context)),
                  ),
                  child: Column(
                    children: [
                      _buildAccountTile(
                        icon: Icons.person_outline,
                        title: 'Personal Information',
                        textColor: textColor,
                        onTap: () => showEcoRouteProfileSheet(context),
                      ),
                      const Divider(height: 1, indent: 56),
                      _buildAccountTile(
                        icon: Icons.location_on_outlined,
                        title: 'Saved Service Addresses',
                        textColor: textColor,
                        onTap: () => _showAddressesSheet(context, state, textColor, subtextColor, cardColor, accentGreen),
                      ),
                      const Divider(height: 1, indent: 56),
                      _buildAccountTile(
                        icon: Icons.tune_outlined,
                        title: 'Fleet Settings',
                        textColor: textColor,
                        onTap: () {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text('Fleet Settings: Electric Tricycles assigned to Arua Central.')),
                          );
                        },
                      ),
                      const Divider(height: 1, indent: 56),
                      _buildAccountTile(
                        icon: Icons.settings_outlined,
                        title: 'App Preferences',
                        textColor: textColor,
                        onTap: () => state.toggleTheme(),
                      ),
                      const Divider(height: 1, indent: 56),
                      _buildAccountTile(
                        icon: Icons.rate_review_outlined,
                        title: 'Feedback & Report Challenges',
                        textColor: textColor,
                        onTap: () => showFeedbackSubmissionDialog(context),
                      ),
                      const Divider(height: 1, indent: 56),
                      _buildAccountTile(
                        icon: Icons.support_agent_outlined,
                        title: 'Contact ecoRoute Support',
                        textColor: textColor,
                        onTap: () => _showSupportModal(context),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 24),

                // SALMON RED SIGN OUT BUTTON (EXACTLY MATCHING IMAGE 2 & 3)
                SizedBox(
                  height: 52,
                  child: ElevatedButton(
                    onPressed: () => state.logout(context),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFFEF5350), // Salmon red
                      foregroundColor: Colors.white,
                      elevation: 0,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
                    ),
                    child: const Text(
                      'Sign Out',
                      style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
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

  Widget _buildHomeActionCard({
    required IconData icon,
    required String title,
    required String subtitle,
    required Color cardColor,
    required Color textColor,
    required Color subtextColor,
    required Color accentColor,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        decoration: BoxDecoration(
          color: cardColor,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AntigravityTheme.border(context)),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.03),
              blurRadius: 6,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: Colors.grey.withOpacity(0.12),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(icon, color: textColor, size: 22),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.bold,
                      color: textColor,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    subtitle,
                    style: TextStyle(fontSize: 12, color: subtextColor),
                  ),
                ],
              ),
            ),
            Icon(Icons.arrow_forward_ios, size: 14, color: subtextColor.withOpacity(0.5)),
          ],
        ),
      ),
    );
  }

  Widget _buildAccountTile({
    required IconData icon,
    required String title,
    required Color textColor,
    required VoidCallback onTap,
  }) {
    return ListTile(
      leading: Icon(icon, color: textColor, size: 22),
      title: Text(
        title,
        style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: textColor),
      ),
      trailing: const Icon(Icons.arrow_forward_ios, size: 14, color: Colors.grey),
      onTap: onTap,
    );
  }

  void _showHistorySheet(
    BuildContext context,
    EcoRouteState state,
    Color textColor,
    Color subtextColor,
    Color cardColor,
    Color accentGreen,
  ) {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: cardColor,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => Container(
        height: MediaQuery.of(ctx).size.height * 0.8,
        padding: const EdgeInsets.all(18),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Pickup History',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: textColor),
                ),
                IconButton(
                  icon: const Icon(Icons.close),
                  onPressed: () => Navigator.pop(ctx),
                ),
              ],
            ),
            const Divider(),
            Expanded(
              child: _buildMobileHistoryView(state, textColor, subtextColor, cardColor, accentGreen),
            ),
          ],
        ),
      ),
    );
  }

  void _showAddressesSheet(
    BuildContext context,
    EcoRouteState state,
    Color textColor,
    Color subtextColor,
    Color cardColor,
    Color accentGreen,
  ) {
    showModalBottomSheet<void>(
      context: context,
      backgroundColor: cardColor,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Saved Service Addresses',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: textColor),
                ),
                IconButton(
                  icon: const Icon(Icons.close),
                  onPressed: () => Navigator.pop(ctx),
                ),
              ],
            ),
            const SizedBox(height: 12),
            ListTile(
              leading: const Icon(Icons.home, color: Color(0xFF00C853)),
              title: const Text('Primary Collection Address'),
              subtitle: Text(state.userCell.isNotEmpty ? state.userCell : 'Registered Location (Arua)'),
              trailing: const Chip(label: Text('Default', style: TextStyle(fontSize: 10))),
            ),
            const SizedBox(height: 10),
            SizedBox(
              width: double.infinity,
              child: FilledButton.tonalIcon(
                onPressed: () {
                  Navigator.pop(ctx);
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Tap on the map canvas to lock new GPS coordinates.')),
                  );
                },
                icon: const Icon(Icons.add_location_alt_outlined, size: 18),
                label: const Text('Add New Service Address'),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showSupportModal(BuildContext context) {
    showModalBottomSheet<void>(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'ecoRoute Support',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 6),
            const Text('Need assistance with your waste collection or schedules?'),
            const SizedBox(height: 16),
            ListTile(
              leading: const Icon(Icons.rate_review_outlined, color: Color(0xFF2E7D32)),
              title: const Text('Report Field Challenge / Feedback'),
              subtitle: const Text('Direct dispatch ticket to Municipal Admins'),
              trailing: FilledButton(
                style: FilledButton.styleFrom(backgroundColor: const Color(0xFF2E7D32)),
                onPressed: () {
                  Navigator.pop(ctx);
                  showFeedbackSubmissionDialog(context);
                },
                child: const Text('Submit'),
              ),
            ),
            ListTile(
              leading: const Icon(Icons.phone, color: Color(0xFF00C853)),
              title: const Text('Toll-Free Dispatch Hotline'),
              subtitle: const Text(kEcoRouteSupportPhone),
              trailing: FilledButton(
                onPressed: () {
                  Navigator.pop(ctx);
                  launchEcoRouteCall();
                },
                child: const Text('Call'),
              ),
            ),
            ListTile(
              leading: const Icon(Icons.chat, color: Color(0xFF25D366)),
              title: const Text('WhatsApp Operations Desk'),
              subtitle: const Text('Chat with Arua Dispatcher'),
              trailing: FilledButton(
                style: FilledButton.styleFrom(backgroundColor: const Color(0xFF25D366)),
                onPressed: () {
                  Navigator.pop(ctx);
                  launchEcoRouteWhatsApp();
                },
                child: const Text('WhatsApp'),
              ),
            ),
            ListTile(
              leading: const Icon(Icons.smart_toy, color: Color(0xFF00A884)),
              title: const Text('ecoRoute Bot (AI Assistant)'),
              subtitle: const Text('24/7 instant answers & sorting guide'),
              trailing: FilledButton(
                style: FilledButton.styleFrom(backgroundColor: const Color(0xFF00A884)),
                onPressed: () {
                  Navigator.pop(ctx);
                  showEcoRouteBotChatSheet(context);
                },
                child: const Text('Chat Bot'),
              ),
            ),
          ],
        ),
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
                        Row(
                          children: [
                            TextButton.icon(
                              onPressed: () => _showDigitalReceipt(context, req),
                              icon: const Icon(Icons.receipt, size: 14),
                              label: const Text('Digital Receipt', style: TextStyle(fontSize: 12)),
                            ),
                            const SizedBox(width: 4),
                            TextButton.icon(
                              onPressed: () => _showRatingDialog(context, req),
                              icon: const Icon(Icons.star_outline, size: 14, color: Colors.amber),
                              label: const Text('Rate', style: TextStyle(fontSize: 12, color: Colors.amber)),
                            ),
                          ],
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
                GestureDetector(
                  onTap: () => showProfilePhotoManagerSheet(context),
                  child: Stack(
                    children: [
                      CircleAvatar(
                        backgroundColor: accentGreen,
                        radius: 34,
                        child: state.userPhotoBase64 != null && state.userPhotoBase64!.isNotEmpty
                            ? ClipOval(
                                child: Image.memory(
                                  base64Decode(state.userPhotoBase64!),
                                  width: 68,
                                  height: 68,
                                  fit: BoxFit.cover,
                                ),
                              )
                            : Text(
                                state.userName.isNotEmpty ? state.userName[0].toUpperCase() : 'R',
                                style: const TextStyle(color: Colors.white, fontSize: 28, fontWeight: FontWeight.bold),
                              ),
                      ),
                      Positioned(
                        bottom: 0,
                        right: 0,
                        child: Container(
                          padding: const EdgeInsets.all(4),
                          decoration: const BoxDecoration(
                            color: Color(0xFF2E7D32),
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(Icons.camera_alt, size: 14, color: Colors.white),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 12),
                Text(
                  state.userName.isNotEmpty ? state.userName : 'Resident Member',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: textColor),
                ),
                const SizedBox(height: 4),
                Text(
                  state.userEmail.isNotEmpty ? state.userEmail : 'No email linked',
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
                  leading: const Icon(Icons.rate_review_outlined, color: Color(0xFF2E7D32)),
                  title: Text('Report Field Challenge / Feedback', style: TextStyle(fontSize: 14, color: textColor)),
                  subtitle: const Text('Send direct message to Municipal Dispatch', style: TextStyle(fontSize: 12)),
                  trailing: const Icon(Icons.arrow_forward_ios, size: 14),
                  onTap: () => showFeedbackSubmissionDialog(context),
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
                      'ECO ROUTE',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 0.5,
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
                          OutlinedButton.icon(
                            onPressed: () => showEcoRouteBotChatSheet(context),
                            icon: const Icon(Icons.smart_toy_outlined, size: 16),
                            label: const Text('ecoRoute Bot'),
                            style: OutlinedButton.styleFrom(
                              foregroundColor: accentGreen,
                              side: BorderSide(color: accentGreen),
                            ),
                          ),
                          const SizedBox(width: 8),
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
                                            'DETAILED SPATIAL INTERACTIVE MAP',
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
                                        child: const EcoCartoMap(
                                          center: LatLng(3.0303, 30.9073),
                                          zoom: 14.5,
                                          height: null,
                                          showLandmarks: true,
                                          showControls: true,
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
                                      'ACCOUNT DISPOSAL HISTORY',
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
                                'MY CARBON IMPACT REDUCTION TRENDS',
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
                          Expanded(flex: 2, child: Text('RECEIPT', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: subtextColor))),
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
                              Expanded(
                                flex: 2,
                                child: TextButton.icon(
                                  onPressed: () => _showDigitalReceipt(context, req),
                                  icon: const Icon(Icons.receipt, size: 14),
                                  label: const Text('Receipt', style: TextStyle(fontSize: 11)),
                                ),
                              ),
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
                      Text('Volume: $currentSacks Sacks', style: TextStyle(fontWeight: FontWeight.bold, color: textColor)),
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
                                      locationLabel = 'GPS Coordinates: ' + lockedLat.toString() + ', ' + lockedLng.toString() + ' (West Nile)';
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

  void _showDigitalReceipt(BuildContext context, Map<String, dynamic> req) {
    final state = EcoRouteState.instance;
    final pickupReq = PickupRequest(
      id: req['id']?.toString() ?? 'ECO-REC',
      wasteType: WasteType.household,
      description: req['wasteType']?.toString() ?? 'Commercial Waste',
      submittedAt: DateTime.now(),
      sackCount: (req['sacks'] as num?)?.toInt() ?? 1,
      priceUgx: (req['fee'] as num?)?.toInt() ?? 5000,
      address: req['address']?.toString() ?? 'Arua Central, West Nile',
      residentName: req['client']?.toString() ?? (state.userName.isNotEmpty ? state.userName : 'Client'),
      residentPhone: req['phone']?.toString() ?? (state.userPhone.isNotEmpty ? state.userPhone : '+256 700 000 000'),
      paymentMethod: req['paymentMethod']?.toString() ?? 'MoMo',
      isCommercial: req['isCommercial'] == true,
      businessName: req['businessName']?.toString(),
    );
    showDialog(
      context: context,
      builder: (_) => DigitalReceiptDialog(request: pickupReq),
    );
  }

  void _showRatingDialog(BuildContext context, Map<String, dynamic> req) {
    int selectedStars = 5;
    final availableTags = ['Punctual Arrival', 'Polite Fleet Driver', 'Accurate Weight', 'Tidy Handover'];
    final selectedTags = <String>{'Punctual Arrival', 'Polite Fleet Driver'};

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDState) => AlertDialog(
          title: Row(
            children: const [
              Icon(Icons.star, color: Colors.amber),
              SizedBox(width: 8),
              Text('Rate Collection Service', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
            ],
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text('How was your pickup for Order ' + (req['id']?.toString() ?? 'REF') + '?', style: const TextStyle(fontSize: 13)),
              const SizedBox(height: 12),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: List.generate(5, (index) {
                  final starIndex = index + 1;
                  return IconButton(
                    icon: Icon(
                      starIndex <= selectedStars ? Icons.star : Icons.star_border,
                      color: Colors.amber,
                      size: 32,
                    ),
                    onPressed: () => setDState(() => selectedStars = starIndex),
                  );
                }),
              ),
              const SizedBox(height: 10),
              Wrap(
                spacing: 6,
                runSpacing: 6,
                children: availableTags.map((tag) {
                  final isSel = selectedTags.contains(tag);
                  return FilterChip(
                    label: Text(tag, style: TextStyle(fontSize: 11, color: isSel ? Colors.white : null)),
                    selected: isSel,
                    selectedColor: const Color(0xFF2E7D32),
                    onSelected: (val) {
                      setDState(() {
                        if (val) {
                          selectedTags.add(tag);
                        } else {
                          selectedTags.remove(tag);
                        }
                      });
                    },
                  );
                }).toList(),
              ),
            ],
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
            FilledButton(
              onPressed: () {
                Navigator.pop(ctx);
                EcoRouteState.instance.submitRiderRating(selectedStars, selectedTags.toList(), context);
              },
              style: FilledButton.styleFrom(backgroundColor: const Color(0xFF2E7D32)),
              child: const Text('Submit Rating'),
            ),
          ],
        ),
      ),
    );
  }
}
