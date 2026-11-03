import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../models/waste_category.dart';
import '../../models/waste_request.dart';
import '../../providers/auth_provider.dart';
import '../../providers/waste_request_provider.dart';
import '../../theme/app_theme.dart';
import '../../widgets/role_header_app_bar.dart';
import '../../widgets/waste_card.dart';
import '../common/eco_stats_screen.dart';
import '../common/interactive_map_screen.dart';
import 'new_request_screen.dart';
import 'request_details_screen.dart';

class CitizenHomeScreen extends StatefulWidget {
  const CitizenHomeScreen({super.key});

  @override
  State<CitizenHomeScreen> createState() => _CitizenHomeScreenState();
}

class _CitizenHomeScreenState extends State<CitizenHomeScreen> {
  int _tabIndex = 0; // 0: Active, 1: History
  String _searchQuery = '';
  String _categoryFilter = 'all';
  final TextEditingController _searchController = TextEditingController();

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final auth = Provider.of<AuthProvider>(context);
    final provider = Provider.of<WasteRequestProvider>(context);
    final userRequests = provider.getCitizenRequests(auth.currentUser.id);

    final allActiveRequests = userRequests
        .where((r) => r.status == RequestStatus.pending || r.status == RequestStatus.assigned)
        .toList();

    final allCompletedRequests = userRequests
        .where((r) => r.status == RequestStatus.collected || r.status == RequestStatus.cancelled)
        .toList();

    final totalCarbon = allCompletedRequests.fold(0.0, (sum, r) => sum + r.totalCarbonSavedKg);

    // Apply search and category filter
    List<WasteRequest> currentTabRequests = _tabIndex == 0 ? allActiveRequests : allCompletedRequests;

    if (_categoryFilter != 'all') {
      currentTabRequests = currentTabRequests
          .where((r) => r.categoryType.name == _categoryFilter)
          .toList();
    }

    if (_searchQuery.isNotEmpty) {
      final q = _searchQuery.toLowerCase();
      currentTabRequests = currentTabRequests.where((r) {
        return r.address.toLowerCase().contains(q) ||
            r.id.toLowerCase().contains(q) ||
            r.category.title.toLowerCase().contains(q) ||
            r.notes.toLowerCase().contains(q);
      }).toList();
    }

    return Scaffold(
      appBar: const RoleHeaderAppBar(title: 'EcoRoute Citizen'),
      body: RefreshIndicator(
        onRefresh: () => provider.loadRequests(),
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // ECO IMPACT HERO BANNER
              Container(
                margin: const EdgeInsets.all(16),
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [AppTheme.darkForest, AppTheme.primaryGreen],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(20),
                  boxShadow: [
                    BoxShadow(
                      color: AppTheme.primaryGreen.withValues(alpha: 0.25),
                      blurRadius: 15,
                      offset: const Offset(0, 8),
                    ),
                  ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text(
                          'Your Environmental Impact',
                          style: TextStyle(
                            color: Colors.white70,
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        InkWell(
                          onTap: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(builder: (_) => const EcoStatsScreen()),
                            );
                          },
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                            decoration: BoxDecoration(
                              color: Colors.white.withValues(alpha: 0.2),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: const Row(
                              children: [
                                Text('Analytics', style: TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.bold)),
                                SizedBox(width: 4),
                                Icon(Icons.arrow_forward_ios, color: Colors.white, size: 10),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        _metricBadge(
                          icon: Icons.eco_rounded,
                          value: '${totalCarbon.toStringAsFixed(1)} kg',
                          label: 'CO₂e Diverted',
                        ),
                        const SizedBox(width: 16),
                        _metricBadge(
                          icon: Icons.delete_sweep_rounded,
                          value: '${allCompletedRequests.fold(0, (sum, r) => sum + r.quantityBags)}',
                          label: 'Bags Cleaned',
                        ),
                        const SizedBox(width: 16),
                        _metricBadge(
                          icon: Icons.payments_rounded,
                          value: '\$${allCompletedRequests.fold(0.0, (sum, r) => sum + (r.actualCashPaid ?? 0)).toStringAsFixed(0)}',
                          label: 'Cash Settled',
                        ),
                      ],
                    ),
                  ],
                ),
              ),

              // CALL TO ACTION BUTTON & MAP SHORTCUT
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16.0),
                child: Row(
                  children: [
                    Expanded(
                      flex: 3,
                      child: InkWell(
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(builder: (_) => const NewRequestScreen()),
                          );
                        },
                        borderRadius: BorderRadius.circular(16),
                        child: Container(
                          padding: const EdgeInsets.all(14),
                          decoration: BoxDecoration(
                            color: AppTheme.accentMint,
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(color: AppTheme.primaryGreen.withValues(alpha: 0.3)),
                          ),
                          child: const Row(
                            children: [
                              CircleAvatar(
                                backgroundColor: AppTheme.primaryGreen,
                                radius: 18,
                                child: Icon(Icons.camera_alt_rounded, color: Colors.white, size: 18),
                              ),
                              SizedBox(width: 12),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      'Schedule Pickup',
                                      style: TextStyle(
                                        fontWeight: FontWeight.w700,
                                        fontSize: 14,
                                        color: AppTheme.darkForest,
                                      ),
                                    ),
                                    Text(
                                      'Snap waste photo & auto GPS',
                                      style: TextStyle(fontSize: 11, color: AppTheme.textMuted),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      flex: 2,
                      child: InkWell(
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(builder: (_) => const InteractiveMapScreen()),
                          );
                        },
                        borderRadius: BorderRadius.circular(16),
                        child: Container(
                          padding: const EdgeInsets.all(14),
                          decoration: BoxDecoration(
                            color: Colors.blue.shade50,
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(color: Colors.blue.shade200),
                          ),
                          child: const Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(Icons.map_rounded, color: Color(0xFF0D6EFD), size: 20),
                              SizedBox(width: 8),
                              Text(
                                'City Map',
                                style: TextStyle(
                                  fontWeight: FontWeight.w700,
                                  fontSize: 13,
                                  color: Color(0xFF0D6EFD),
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
              const SizedBox(height: 16),

              // SEARCH BAR
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16.0),
                child: TextField(
                  controller: _searchController,
                  decoration: InputDecoration(
                    hintText: 'Search by address, notes, category...',
                    prefixIcon: const Icon(Icons.search_rounded, size: 20),
                    suffixIcon: _searchQuery.isNotEmpty
                        ? IconButton(
                            icon: const Icon(Icons.clear, size: 18),
                            onPressed: () {
                              _searchController.clear();
                              setState(() => _searchQuery = '');
                            },
                          )
                        : null,
                    contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  ),
                  onChanged: (val) {
                    setState(() => _searchQuery = val.trim());
                  },
                ),
              ),
              const SizedBox(height: 10),

              // CATEGORY FILTER CHIPS
              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(horizontal: 16.0),
                child: Row(
                  children: [
                    _categoryChip('all', 'All Types'),
                    const SizedBox(width: 6),
                    ...WasteCategory.allCategories.map(
                      (c) => Padding(
                        padding: const EdgeInsets.only(right: 6.0),
                        child: _categoryChip(c.type.name, c.title),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 14),

              // TABS: ACTIVE VS HISTORY
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16.0),
                child: Row(
                  children: [
                    _tabButton(0, 'Active (${allActiveRequests.length})'),
                    const SizedBox(width: 10),
                    _tabButton(1, 'History (${allCompletedRequests.length})'),
                  ],
                ),
              ),
              const SizedBox(height: 12),

              // REQUEST LIST
              if (currentTabRequests.isEmpty)
                _emptyState(
                  title: _searchQuery.isNotEmpty
                      ? 'No requests match "$_searchQuery"'
                      : (_tabIndex == 0 ? 'No active pickups' : 'No past collections yet'),
                  subtitle: _searchQuery.isNotEmpty
                      ? 'Try clearing your search query or category filter.'
                      : (_tabIndex == 0
                          ? 'Snap a picture of waste outside to summon a collection rider.'
                          : 'Completed waste collections will appear here with cash receipts.'),
                  icon: _searchQuery.isNotEmpty ? Icons.search_off_rounded : Icons.checklist_rounded,
                )
              else
                ...currentTabRequests.map((req) => WasteCard(
                      request: req,
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => RequestDetailsScreen(request: req),
                          ),
                        );
                      },
                    )),
              const SizedBox(height: 80),
            ],
          ),
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        backgroundColor: AppTheme.primaryGreen,
        foregroundColor: Colors.white,
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => const NewRequestScreen()),
          );
        },
        icon: const Icon(Icons.add_a_photo_rounded),
        label: const Text('New Pickup'),
      ),
    );
  }

  Widget _categoryChip(String key, String label) {
    final isSelected = _categoryFilter == key;
    return ChoiceChip(
      label: Text(label, style: const TextStyle(fontSize: 11)),
      selected: isSelected,
      selectedColor: AppTheme.darkForest,
      labelStyle: TextStyle(
        color: isSelected ? Colors.white : AppTheme.textDark,
        fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
      ),
      backgroundColor: Colors.white,
      showCheckmark: false,
      onSelected: (val) {
        if (val) {
          setState(() => _categoryFilter = key);
        }
      },
    );
  }

  Widget _metricBadge({required IconData icon, required String value, required String label}) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.15),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(icon, color: Colors.white, size: 18),
            const SizedBox(height: 6),
            Text(
              value,
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.w800,
                fontSize: 15,
              ),
            ),
            Text(
              label,
              style: const TextStyle(
                color: Colors.white70,
                fontSize: 10,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _tabButton(int index, String label) {
    final isSelected = _tabIndex == index;
    return Expanded(
      child: InkWell(
        onTap: () => setState(() => _tabIndex = index),
        borderRadius: BorderRadius.circular(12),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 10),
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: isSelected ? AppTheme.primaryGreen : Colors.white,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: isSelected ? AppTheme.primaryGreen : const Color(0xFFDDDDDD),
            ),
          ),
          child: Text(
            label,
            style: TextStyle(
              color: isSelected ? Colors.white : AppTheme.textDark,
              fontWeight: FontWeight.w700,
              fontSize: 13,
            ),
          ),
        ),
      ),
    );
  }

  Widget _emptyState({required String title, required String subtitle, required IconData icon}) {
    return Padding(
      padding: const EdgeInsets.all(40.0),
      child: Center(
        child: Column(
          children: [
            Icon(icon, size: 54, color: AppTheme.textMuted.withValues(alpha: 0.5)),
            const SizedBox(height: 12),
            Text(
              title,
              style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: AppTheme.textDark),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 6),
            Text(
              subtitle,
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 12, color: AppTheme.textMuted),
            ),
          ],
        ),
      ),
    );
  }
}
