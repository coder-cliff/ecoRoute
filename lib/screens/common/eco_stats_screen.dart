import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../models/waste_category.dart';
import '../../models/waste_request.dart';
import '../../providers/waste_request_provider.dart';
import '../../services/api_service.dart';
import '../../theme/app_theme.dart';

class EcoStatsScreen extends StatelessWidget {
  const EcoStatsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final provider = Provider.of<WasteRequestProvider>(context);
    final totalCarbon = provider.totalCarbonSavedKg;
    final totalBags = provider.totalBagsCollected;
    final impact = ApiService.calculateEcoImpact(
      totalCarbonSavedKg: totalCarbon,
      totalBags: totalBags,
    );

    return Scaffold(
      appBar: AppBar(
        title: const Text('Eco Impact Analytics'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // HERO IMPACT CARD
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(22),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [AppTheme.darkForest, AppTheme.primaryGreen],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Column(
                children: [
                  const Icon(Icons.public_rounded, size: 48, color: Colors.white),
                  const SizedBox(height: 12),
                  const Text(
                    'Total Carbon Emissions Avoided',
                    style: TextStyle(color: Colors.white70, fontSize: 13, fontWeight: FontWeight.w600),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    '${totalCarbon.toStringAsFixed(1)} kg CO₂e',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 32,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Calculated across ${provider.collectedCount} verified collected waste batches',
                    style: const TextStyle(color: Colors.white60, fontSize: 11),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),

            // EQUIVALENCE CARDS
            const Text(
              'Environmental Equivalencies',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: AppTheme.textDark),
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                _statTile(
                  icon: Icons.forest_rounded,
                  title: '${impact['treesEquivalent']} Trees',
                  subtitle: 'Annual CO₂ absorption equivalent',
                  color: AppTheme.primaryGreen,
                ),
                const SizedBox(width: 12),
                _statTile(
                  icon: Icons.directions_car_rounded,
                  title: '${impact['carKmOffset']} km',
                  subtitle: 'Driving emissions eliminated',
                  color: const Color(0xFF0D6EFD),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                _statTile(
                  icon: Icons.delete_sweep_rounded,
                  title: '${impact['landfillVolumeM3']} m³',
                  subtitle: 'Volume diverted from open landfill',
                  color: const Color(0xFFFB8C00),
                ),
                const SizedBox(width: 12),
                _statTile(
                  icon: Icons.payments_rounded,
                  title: '\$${provider.totalCashCollected.toStringAsFixed(2)}',
                  subtitle: 'Circulated to green riders in cash',
                  color: AppTheme.cashGold,
                ),
              ],
            ),
            const SizedBox(height: 24),

            // CATEGORY BREAKDOWN
            const Text(
              'Waste Recycled by Category',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: AppTheme.textDark),
            ),
            const SizedBox(height: 12),
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  children: WasteCategory.allCategories.map((cat) {
                    final catRequests = provider.requests.where(
                      (r) => r.categoryType == cat.type && r.status == RequestStatus.collected,
                    );
                    final catBags = catRequests.fold(0, (sum, r) => sum + r.quantityBags);
                    final catCarbon = catRequests.fold(0.0, (sum, r) => sum + r.totalCarbonSavedKg);

                    return Padding(
                      padding: const EdgeInsets.symmetric(vertical: 8.0),
                      child: Row(
                        children: [
                          CircleAvatar(
                            radius: 16,
                            backgroundColor: cat.color.withValues(alpha: 0.15),
                            child: Icon(cat.icon, size: 16, color: cat.color),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(cat.title, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13)),
                                Text('$catBags bags collected', style: const TextStyle(fontSize: 11, color: AppTheme.textMuted)),
                              ],
                            ),
                          ),
                          Text(
                            '+${catCarbon.toStringAsFixed(1)} kg CO₂',
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 13,
                              color: cat.color,
                            ),
                          ),
                        ],
                      ),
                    );
                  }).toList(),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _statTile({
    required IconData icon,
    required String title,
    required String subtitle,
    required Color color,
  }) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: const Color(0xFFEEEEEE)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            CircleAvatar(
              radius: 18,
              backgroundColor: color.withValues(alpha: 0.15),
              child: Icon(icon, color: color, size: 18),
            ),
            const SizedBox(height: 12),
            Text(title, style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800, color: color)),
            const SizedBox(height: 2),
            Text(subtitle, style: const TextStyle(fontSize: 11, color: AppTheme.textMuted)),
          ],
        ),
      ),
    );
  }
}
