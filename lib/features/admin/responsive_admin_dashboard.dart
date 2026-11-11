import 'package:flutter/material.dart';

import '../../core/layout/adaptive_layout.dart';
import '../../core/theme/eco_palette.dart';
import '../../main.dart';
import 'widgets/admin_analytics_dashboard_view.dart';
import 'widgets/admin_approvals_view.dart';
import 'widgets/admin_dispatch_map_view.dart';
import 'widgets/admin_fleet_view.dart';
import 'widgets/admin_overview_view.dart';
import 'widgets/admin_requests_view.dart';
import 'widgets/admin_settings_quadrant_view.dart';
import 'widgets/admin_transactions_ledger_view.dart';

/// Responsive Admin Command HQ Portal
/// Conforms to ecoRoute Master System Specifications and UI Design Blueprints
class ResponsiveAdminDashboard extends StatefulWidget {
  const ResponsiveAdminDashboard({super.key});

  @override
  State<ResponsiveAdminDashboard> createState() => _ResponsiveAdminDashboardState();
}

class _ResponsiveAdminDashboardState extends State<ResponsiveAdminDashboard> {
  int _selectedSidebarIndex = 0;
  final TextEditingController _globalSearchController = TextEditingController();

  final List<String> _tabTitles = [
    'Admin Dashboard',
    'Live Dispatch Map',
    'Fleet & Riders Roster',
    'Request History',
    'Transactions & Financial Ledger',
    'System Analytics Dashboard',
    'Photo Evidence & Rider Approvals',
    'System Settings',
  ];

  @override
  void dispose() {
    _globalSearchController.dispose();
    super.dispose();
  }

  void _showAddRiderDialog(BuildContext context) {
    final nameController = TextEditingController();
    final phoneController = TextEditingController();
    String selectedVehicle = 'Motorcycle (Bajaj Boxer)';
    final formKey = GlobalKey<FormState>();

    showDialog(
      context: context,
      builder: (ctx) {
        final isDark = Theme.of(ctx).brightness == Brightness.dark;
        return StatefulBuilder(
          builder: (context, setDialogState) => AlertDialog(
            backgroundColor: isDark ? const Color(0xFF1E293B) : Colors.white,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            title: Row(
              children: const [
                Icon(Icons.person_add, color: Color(0xFF2E7D32)),
                SizedBox(width: 10),
                Text('Add New Fleet Rider', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
              ],
            ),
            content: SizedBox(
              width: 420,
              child: Form(
                key: formKey,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Dispatch an onboarding invitation and temporary activation PIN to a field rider.',
                      style: TextStyle(
                        fontSize: 12,
                        color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B),
                      ),
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: nameController,
                      decoration: const InputDecoration(
                        labelText: 'Rider Full Name',
                        prefixIcon: Icon(Icons.person_outline, size: 20),
                        border: OutlineInputBorder(),
                        isDense: true,
                      ),
                      validator: (val) => (val == null || val.trim().isEmpty) ? 'Enter rider name' : null,
                    ),
                    const SizedBox(height: 14),
                    TextFormField(
                      controller: phoneController,
                      keyboardType: TextInputType.phone,
                      decoration: const InputDecoration(
                        labelText: 'Phone Number (e.g. +256 700 000000)',
                        prefixIcon: Icon(Icons.phone_outlined, size: 20),
                        border: OutlineInputBorder(),
                        isDense: true,
                      ),
                      validator: (val) => (val == null || val.trim().isEmpty) ? 'Enter phone number' : null,
                    ),
                    const SizedBox(height: 14),
                    DropdownButtonFormField<String>(
                      value: selectedVehicle,
                      decoration: const InputDecoration(
                        labelText: 'Assigned Vehicle Category',
                        prefixIcon: Icon(Icons.two_wheeler_outlined, size: 20),
                        border: OutlineInputBorder(),
                        isDense: true,
                      ),
                      dropdownColor: isDark ? const Color(0xFF1E293B) : Colors.white,
                      items: const [
                        DropdownMenuItem(value: 'Motorcycle (Bajaj Boxer)', child: Text('Motorcycle (Bajaj Boxer)')),
                        DropdownMenuItem(value: 'Tricycle (Tuk-Tuk Hauler)', child: Text('Tricycle (Tuk-Tuk Hauler)')),
                        DropdownMenuItem(value: 'Truck (Isuzu 3-Ton)', child: Text('Truck (Isuzu 3-Ton)')),
                        DropdownMenuItem(value: 'Bicycle Cart', child: Text('Bicycle Cart')),
                      ],
                      onChanged: (val) {
                        if (val != null) setDialogState(() => selectedVehicle = val);
                      },
                    ),
                  ],
                ),
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(ctx),
                child: const Text('Cancel'),
              ),
              ElevatedButton.icon(
                onPressed: () {
                  if (formKey.currentState?.validate() ?? false) {
                    final name = nameController.text.trim();
                    final phone = phoneController.text.trim();
                    final inviteCode = EcoRouteState.instance.inviteRider(
                      name: name,
                      phone: phone,
                      tricycleId: selectedVehicle,
                    );
                    Navigator.pop(ctx);
                    setState(() {});
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        backgroundColor: const Color(0xFF2E7D32),
                        content: Text('Rider invite sent to $name ($phone). Code: $inviteCode'),
                      ),
                    );
                  }
                },
                icon: const Icon(Icons.send, size: 16),
                label: const Text('Send Invitation'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF2E7D32),
                  foregroundColor: Colors.white,
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.sizeOf(context).width;
    final isDesktop = width >= 1024;

    if (!isDesktop) {
      return _buildMobileOrTabletLayout(context, width);
    }

    return _buildDesktopLayout(context);
  }

  Widget _buildDesktopLayout(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final surfaceBg = isDark ? const Color(0xFF0F172A) : const Color(0xFFF1F5F9);

    return Scaffold(
      backgroundColor: surfaceBg,
      body: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Sidebar
          _buildSidebar(context, width: 260),

          // Main Screen Area with Top Bar
          Expanded(
            child: Column(
              children: [
                _buildTopBar(context, isDark: isDark),
                const Divider(height: 1, thickness: 1, color: Color(0xFFE2E8F0)),
                Expanded(
                  child: _buildCurrentView(),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMobileOrTabletLayout(BuildContext context, double width) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final surfaceBg = isDark ? const Color(0xFF0F172A) : const Color(0xFFF1F5F9);

    return Scaffold(
      backgroundColor: surfaceBg,
      appBar: AppBar(
        title: Text(
          _tabTitles[_selectedSidebarIndex],
          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
        ),
        actions: [
          IconButton(
            icon: Icon(isDark ? Icons.light_mode : Icons.dark_mode),
            onPressed: () => EcoRouteState.instance.toggleTheme(),
          ),
          IconButton(
            icon: const Icon(Icons.person_add_outlined),
            onPressed: () => _showAddRiderDialog(context),
          ),
        ],
      ),
      drawer: Drawer(
        child: _buildSidebar(context, width: 280),
      ),
      body: _buildCurrentView(),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _selectedSidebarIndex.clamp(0, 4),
        onTap: (idx) => setState(() => _selectedSidebarIndex = idx),
        type: BottomNavigationBarType.fixed,
        selectedItemColor: const Color(0xFF2E7D32),
        unselectedItemColor: isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B),
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.home_outlined), label: 'Overview'),
          BottomNavigationBarItem(icon: Icon(Icons.location_on_outlined), label: 'Dispatch'),
          BottomNavigationBarItem(icon: Icon(Icons.local_shipping_outlined), label: 'Fleet'),
          BottomNavigationBarItem(icon: Icon(Icons.calendar_today_outlined), label: 'Requests'),
          BottomNavigationBarItem(icon: Icon(Icons.receipt_long_outlined), label: 'Ledger'),
        ],
      ),
    );
  }

  Widget _buildTopBar(BuildContext context, {required bool isDark}) {
    final state = EcoRouteState.instance;

    return Container(
      height: 64,
      padding: const EdgeInsets.symmetric(horizontal: 24),
      color: isDark ? const Color(0xFF1E293B) : Colors.white,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          // Left: Screen Title
          Text(
            _tabTitles[_selectedSidebarIndex],
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: isDark ? Colors.white : const Color(0xFF1E293B),
            ),
          ),

          // Center: Global Search Bar
          Container(
            width: 320,
            height: 38,
            decoration: BoxDecoration(
              color: isDark ? const Color(0xFF0F172A) : const Color(0xFFF8FAFC),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                color: isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0),
              ),
            ),
            child: TextField(
              controller: _globalSearchController,
              decoration: InputDecoration(
                hintText: 'Search across all data...',
                hintStyle: TextStyle(
                  fontSize: 13,
                  color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF94A3B8),
                ),
                prefixIcon: const Icon(Icons.search, size: 18, color: Color(0xFF94A3B8)),
                border: InputBorder.none,
                contentPadding: const EdgeInsets.symmetric(vertical: 8),
              ),
              style: const TextStyle(fontSize: 13),
            ),
          ),

          // Right: Action Icons & Profile Dropdown
          Row(
            children: [
              // Messages Icon
              IconButton(
                icon: const Icon(Icons.mail_outline, size: 20),
                tooltip: 'Inquiries & Broadcasts',
                onPressed: () {
                  setState(() => _selectedSidebarIndex = 6);
                },
              ),
              const SizedBox(width: 4),

              // Bell Icon with unread indicator
              Stack(
                children: [
                  IconButton(
                    icon: const Icon(Icons.notifications_none, size: 22),
                    tooltip: 'System Alerts',
                    onPressed: () {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Notifications: All systems normal. 12 riders online.')),
                      );
                    },
                  ),
                  Positioned(
                    top: 10,
                    right: 12,
                    child: Container(
                      width: 8,
                      height: 8,
                      decoration: const BoxDecoration(
                        color: Color(0xFFEF4444),
                        shape: BoxShape.circle,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(width: 8),

              // Profile Dropdown
              PopupMenuButton<String>(
                onSelected: (val) {
                  if (val == 'theme') {
                    state.toggleTheme();
                  } else if (val == 'csv') {
                    state.exportCollectionAuditCsv(context);
                  } else if (val == 'signout') {
                    state.logout(context);
                  }
                },
                itemBuilder: (ctx) => [
                  PopupMenuItem(
                    value: 'profile',
                    enabled: false,
                    child: Text(
                      'Signed in as ${state.userName.isNotEmpty ? state.userName : "Admin HQ"}',
                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12),
                    ),
                  ),
                  const PopupMenuDivider(),
                  PopupMenuItem(
                    value: 'theme',
                    child: Row(
                      children: [
                        Icon(isDark ? Icons.light_mode : Icons.dark_mode, size: 18),
                        const SizedBox(width: 8),
                        Text(isDark ? 'Switch to Light Mode' : 'Switch to Dark Mode'),
                      ],
                    ),
                  ),
                  const PopupMenuItem(
                    value: 'csv',
                    child: Row(
                      children: [
                        Icon(Icons.download, size: 18, color: Color(0xFF2E7D32)),
                        SizedBox(width: 8),
                        Text('Export Master Audit CSV'),
                      ],
                    ),
                  ),
                  const PopupMenuDivider(),
                  const PopupMenuItem(
                    value: 'signout',
                    child: Row(
                      children: [
                        Icon(Icons.logout, size: 18, color: Colors.redAccent),
                        SizedBox(width: 8),
                        Text('Sign Out', style: TextStyle(color: Colors.redAccent)),
                      ],
                    ),
                  ),
                ],
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                  decoration: BoxDecoration(
                    color: isDark ? const Color(0xFF0F172A) : const Color(0xFFF1F5F9),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Row(
                    children: [
                      const CircleAvatar(
                        radius: 14,
                        backgroundColor: Color(0xFF2E7D32),
                        child: Icon(Icons.person, size: 16, color: Colors.white),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        state.userName.isNotEmpty ? state.userName : 'Admin HQ',
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          color: isDark ? Colors.white : const Color(0xFF1E293B),
                        ),
                      ),
                      const SizedBox(width: 4),
                      Icon(
                        Icons.keyboard_arrow_down,
                        size: 16,
                        color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B),
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

  Widget _buildSidebar(BuildContext context, {required double width}) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final sidebarBg = isDark ? const Color(0xFF0B130E) : const Color(0xFF0D2818);

    return Container(
      width: width,
      color: sidebarBg,
      padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Logo & Brand Header
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.12),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Icon(Icons.eco, color: Color(0xFF81C784), size: 22),
                ),
                const SizedBox(width: 12),
                const Text(
                  'ecoRoute',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    letterSpacing: -0.5,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),

          // 8 Navigation Tabs
          Expanded(
            child: ListView(
              padding: EdgeInsets.zero,
              children: [
                _buildNavItem(0, 'Overview', Icons.home_outlined, Icons.home),
                _buildNavItem(1, 'Live Dispatch Map', Icons.location_on_outlined, Icons.location_on),
                _buildNavItem(2, 'Fleet & Riders', Icons.local_shipping_outlined, Icons.local_shipping),
                _buildNavItem(3, 'Request History', Icons.calendar_today_outlined, Icons.calendar_today),
                _buildNavItem(4, 'Transactions', Icons.receipt_long_outlined, Icons.receipt_long),
                _buildNavItem(5, 'System Analytics', Icons.bar_chart_outlined, Icons.bar_chart),
                _buildNavItem(6, 'Approvals & Evidence', Icons.check_circle_outlined, Icons.check_circle),
                _buildNavItem(7, 'Settings', Icons.settings_outlined, Icons.settings),
              ],
            ),
          ),

          // Bottom System Live Status Indicator
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.08),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: const [
                Icon(Icons.circle, size: 8, color: Color(0xFF4CAF50)),
                SizedBox(width: 8),
                Text(
                  'System Live • Active',
                  style: TextStyle(
                    color: Color(0xFF81C784),
                    fontSize: 11,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 8),
        ],
      ),
    );
  }

  Widget _buildNavItem(int index, String label, IconData icon, IconData activeIcon) {
    final isSelected = _selectedSidebarIndex == index;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: ListTile(
        dense: true,
        selected: isSelected,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        tileColor: isSelected ? const Color(0xFF1B5E20) : Colors.transparent,
        leading: Icon(
          isSelected ? activeIcon : icon,
          color: isSelected ? Colors.white : Colors.white70,
          size: 19,
        ),
        title: Text(
          label,
          style: TextStyle(
            color: isSelected ? Colors.white : Colors.white70,
            fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
            fontSize: 13,
          ),
        ),
        onTap: () {
          setState(() => _selectedSidebarIndex = index);
          if (Navigator.of(context).canPop()) {
            Navigator.of(context).pop();
          }
        },
      ),
    );
  }

  Widget _buildCurrentView() {
    switch (_selectedSidebarIndex) {
      case 1:
        return const AdminDispatchMapView();
      case 2:
        return AdminFleetView(
          onShowAddRiderDialog: () => _showAddRiderDialog(context),
        );
      case 3:
        return const AdminRequestsView();
      case 4:
        return const AdminTransactionsLedgerView();
      case 5:
        return const AdminAnalyticsDashboardView();
      case 6:
        return const AdminApprovalsView();
      case 7:
        return const AdminSettingsQuadrantView();
      case 0:
      default:
        return AdminOverviewView(
          onNavigateToTab: (idx) => setState(() => _selectedSidebarIndex = idx),
          onShowAddRiderDialog: () => _showAddRiderDialog(context),
        );
    }
  }
}
