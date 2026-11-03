import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../models/waste_request.dart';
import '../../providers/auth_provider.dart';
import '../../providers/waste_request_provider.dart';
import '../../theme/app_theme.dart';
import '../../widgets/role_header_app_bar.dart';
import '../../widgets/waste_card.dart';
import '../common/eco_stats_screen.dart';
import 'new_request_screen.dart';
import 'request_details_screen.dart';

class CitizenHomeScreen extends StatefulWidget {
  const CitizenHomeScreen({super.key});

  @override
  State<CitizenHomeScreen> createState() => _CitizenHomeScreenState();
}

class _CitizenHomeScreenState extends State<CitizenHomeScreen> {
  int _tabIndex = 0; // 0: Active, 1: History

  @override
  Widget build(BuildContext context) {
    final auth = Provider.of<AuthProvider>(context);
    final provider = Provider.of<WasteRequestProvider>(context);
    final userRequests = provider.getCitizenRequests(auth.currentUser.id);

    final activeRequests = userRequests
        .where((r) => r.status == RequestStatus.pending || r.status == RequestStatus.assigned)
        .toList();

    final completedRequests = userRequests
        .where((r) => r.status == RequestStatus.collected || r.status == RequestStatus.cancelled)
        .toList();

    final totalCarbon = completedRequests.fold(0.0, (sum, r) => sum + r.totalCarbonSavedKg);

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
                          value: '${completedRequests.fold(0, (sum, r) => sum + r.quantityBags)}',
                          label: 'Bags Cleaned',
                        ),
                        const SizedBox(width: 16),
                        _metricBadge(
                          icon: Icons.payments_rounded,
                          value: '\$${completedRequests.fold(0.0, (sum, r) => sum + (r.actualCashPaid ?? 0)).toStringAsFixed(0)}',
                          label: 'Cash Settled',
                        ),
                      ],
                    ),
                  ],
                ),
              ),

              // CALL TO ACTION BUTTON
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16.0),
                child: InkWell(
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (_) => const NewRequestScreen()),
                    );
                  },
                  borderRadius: BorderRadius.circular(16),
                  child: Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: AppTheme.accentMint,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: AppTheme.primaryGreen.withValues(alpha: 0.3)),
                    ),
                    child: Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(12),
                          decoration: const BoxDecoration(
                            color: AppTheme.primaryGreen,
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(Icons.camera_alt_rounded, color: Colors.white, size: 24),
                        ),
                        const SizedBox(width: 16),
                        const Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Schedule Waste Collection',
                                style: TextStyle(
                                  fontWeight: FontWeight.w700,
                                  fontSize: 16,
                                  color: AppTheme.darkForest,
                                ),
                              ),
                              SizedBox(height: 2),
                              Text(
                                'Move close, snap a photo & auto-log GPS',
                                style: TextStyle(fontSize: 12, color: AppTheme.textMuted),
                              ),
                            ],
                          ),
                        ),
                        const Icon(Icons.chevron_right_rounded, color: AppTheme.primaryGreen),
                      ],
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 20),

              // TABS: ACTIVE VS HISTORY
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16.0),
                child: Row(
                  children: [
                    _tabButton(0, 'Active Requests (${activeRequests.length})'),
                    const SizedBox(width: 10),
                    _tabButton(1, 'Completed (${completedRequests.length})'),
                  ],
                ),
              ),
              const SizedBox(height: 12),

              // REQUEST LIST
              if (_tabIndex == 0) ...[
                if (activeRequests.isEmpty)
                  _emptyState(
                    title: 'No active waste pickups',
                    subtitle: 'Snap a picture of waste outside to summon a collection rider.',
                    icon: Icons.checklist_rounded,
                  )
                else
                  ...activeRequests.map((req) => WasteCard(
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
              ] else ...[
                if (completedRequests.isEmpty)
                  _emptyState(
                    title: 'No past collections yet',
                    subtitle: 'Completed waste collections will appear here with cash receipts.',
                    icon: Icons.history_rounded,
                  )
                else
                  ...completedRequests.map((req) => WasteCard(
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
              ],
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

  Widget _tabButton(int index, String label) {
    final isSelected = _tabIndex == index;
    return InkWell(
      onTap: () => setState(() => _tabIndex = index),
      borderRadius: BorderRadius.circular(20),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected ? AppTheme.primaryGreen : Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isSelected ? AppTheme.primaryGreen : const Color(0xFFDDDDDD),
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w600,
            color: isSelected ? Colors.white : AppTheme.textDark,
          ),
        ),
      ),
    );
  }

  Widget _metricBadge({required IconData icon, required String value, required String label}) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(10),
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
                fontSize: 16,
              ),
            ),
            Text(
              label,
              style: const TextStyle(color: Colors.white70, fontSize: 10),
            ),
          ],
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
              style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 16, color: AppTheme.textDark),
            ),
            const SizedBox(height: 6),
            Text(
              subtitle,
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 13, color: AppTheme.textMuted),
            ),
          ],
        ),
      ),
    );
  }
}
