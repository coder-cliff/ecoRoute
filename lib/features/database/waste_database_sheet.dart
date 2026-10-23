import 'package:flutter/material.dart';

import '../../core/services/waste_database_service.dart';
import '../../core/utils/formatters.dart';

class WasteDatabaseSheet extends StatefulWidget {
  const WasteDatabaseSheet({super.key});

  @override
  State<WasteDatabaseSheet> createState() => _WasteDatabaseSheetState();
}

class _WasteDatabaseSheetState extends State<WasteDatabaseSheet> {
  final _searchController = TextEditingController();
  final _dbService = WasteDatabaseService.instance;

  WasteCategory? _selectedCategory;
  String _query = '';

  // Calculator State
  bool _showCalculator = false;
  double _calcWeightKg = 10.0;
  String _calcMaterialId = 'mat-pet';

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  String _categoryShortName(WasteCategory cat) => switch (cat) {
        WasteCategory.organic => 'Organic',
        WasteCategory.plastic => 'Plastics',
        WasteCategory.paper => 'Paper',
        WasteCategory.metal => 'Metals',
        WasteCategory.glass => 'Glass',
        WasteCategory.hazardous => 'Hazardous',
      };

  void _showMaterialDetails(WasteMaterial item) {
    final facilities = _dbService
        .getAruaFacilities()
        .where((f) => f.acceptedCategories.contains(item.category))
        .toList();

    showDialog<void>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Row(
          children: [
            Icon(
              item.isHazardous ? Icons.warning_amber_rounded : Icons.eco_rounded,
              color: item.isHazardous
                  ? const Color(0xFFE53935)
                  : const Color(0xFF2E7D32),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                item.name,
                style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w800),
              ),
            ),
          ],
        ),
        content: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text(
                'Decomposition & Value Breakdown',
                style: TextStyle(
                  fontWeight: FontWeight.w700,
                  fontSize: 13,
                  color: Color(0xFF1B5E20),
                ),
              ),
              const SizedBox(height: 4),
              Text(
                'Lugbara: ${item.lugbaraName}',
                style: const TextStyle(fontStyle: FontStyle.italic),
              ),
              Text('Category: ${item.category.label}'),
              Text('Decomposition time: ${item.decompositionTime}'),
              Text('Estimated resale value: ${formatUgx(item.valuePerKgUgx)} / kg'),
              Text('Carbon avoided: ${item.co2SavedPerKg} kg CO₂ / kg recycled'),
              const Divider(height: 20),
              const Text(
                'Sorting instructions:',
                style: TextStyle(fontWeight: FontWeight.w700, fontSize: 13),
              ),
              const SizedBox(height: 2),
              Text(item.sortingTip),
              const SizedBox(height: 8),
              const Text(
                'Recycling process:',
                style: TextStyle(fontWeight: FontWeight.w700, fontSize: 13),
              ),
              const SizedBox(height: 2),
              Text(item.recyclingTip),
              const Divider(height: 20),
              const Text(
                'Certified Arua Municipal Hubs:',
                style: TextStyle(fontWeight: FontWeight.w700, fontSize: 13),
              ),
              const SizedBox(height: 4),
              if (facilities.isEmpty)
                const Text('Collection via standard municipal tricycle pickup.')
              else
                for (final fac in facilities)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 4),
                    child: Text(
                      '• ${fac.name} (${fac.address})',
                      style: const TextStyle(fontSize: 12),
                    ),
                  ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final all = _dbService.searchMaterials(_query);
    final filtered = _selectedCategory == null
        ? all
        : all.where((m) => m.category == _selectedCategory).toList();

    final benchmark = _dbService.getAruaBenchmarks();

    return Container(
      constraints: BoxConstraints(
        maxHeight: MediaQuery.sizeOf(context).height * 0.88,
      ),
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      padding: const EdgeInsets.fromLTRB(18, 14, 18, 18),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Row(
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: const Color(0xFFE8F5E9),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: const Icon(Icons.dataset_outlined, color: Color(0xFF2E7D32)),
              ),
              const SizedBox(width: 12),
              const Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Arua Waste & Recycling Database',
                      style: TextStyle(fontSize: 17, fontWeight: FontWeight.w800),
                    ),
                    Text(
                      'Free Arua Municipal Taxonomy & Sorting Directory',
                      style: TextStyle(fontSize: 11, color: Color(0xFF556958)),
                    ),
                  ],
                ),
              ),
              IconButton(
                onPressed: () => Navigator.pop(context),
                icon: const Icon(Icons.close_rounded),
              ),
            ],
          ),
          const SizedBox(height: 12),

          // Search bar
          TextField(
            controller: _searchController,
            onChanged: (val) => setState(() => _query = val),
            decoration: InputDecoration(
              hintText: 'Search materials, Lugbara names, or codes...',
              prefixIcon: const Icon(Icons.search_rounded),
              suffixIcon: _query.isNotEmpty
                  ? IconButton(
                      icon: const Icon(Icons.clear_rounded),
                      onPressed: () {
                        _searchController.clear();
                        setState(() => _query = '');
                      },
                    )
                  : null,
              contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            ),
          ),
          const SizedBox(height: 10),

          // Category filter chips
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: [
                FilterChip(
                  label: const Text('All'),
                  selected: _selectedCategory == null,
                  onSelected: (_) => setState(() => _selectedCategory = null),
                ),
                const SizedBox(width: 6),
                for (final cat in WasteCategory.values) ...[
                  FilterChip(
                    label: Text(_categoryShortName(cat)),
                    selected: _selectedCategory == cat,
                    onSelected: (sel) => setState(() {
                      _selectedCategory = sel ? cat : null;
                    }),
                  ),
                  const SizedBox(width: 6),
                ],
              ],
            ),
          ),
          const SizedBox(height: 10),

          // Municipal benchmark ticker
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              color: const Color(0xFFF1F8F2),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: const Color(0xFFD2E6D5)),
            ),
            child: Row(
              children: [
                const Icon(Icons.public_rounded, size: 16, color: Color(0xFF2E7D32)),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'World Bank / NEMA Municipal Data: ${benchmark.dailyPerCapitaKg} kg/day • ${benchmark.organicPercentage.toInt()}% Organic • ${benchmark.recyclablePotentialPercentage.toInt()}% Recyclable',
                    style: const TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                      color: Color(0xFF245228),
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 8),

          // Interactive Scrap Cash & Carbon Calculator
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Color(0xFFE8F5E9), Color(0xFFF1F8F2)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: const Color(0xFFC8E6C9)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                InkWell(
                  onTap: () => setState(() => _showCalculator = !_showCalculator),
                  child: Row(
                    children: [
                      const Icon(Icons.calculate_rounded, color: Color(0xFF1B5E20), size: 20),
                      const SizedBox(width: 8),
                      const Expanded(
                        child: Text(
                          'Scrap Value & Carbon Calculator',
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w800,
                            color: Color(0xFF1B5E20),
                          ),
                        ),
                      ),
                      Text(
                        _showCalculator ? 'Hide' : 'Calculate Earnings',
                        style: const TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                          color: Color(0xFF2E7D32),
                        ),
                      ),
                      Icon(
                        _showCalculator
                            ? Icons.keyboard_arrow_up_rounded
                            : Icons.keyboard_arrow_down_rounded,
                        color: const Color(0xFF2E7D32),
                        size: 18,
                      ),
                    ],
                  ),
                ),
                if (_showCalculator) ...[
                  const SizedBox(height: 10),
                  DropdownButtonFormField<String>(
                    initialValue: _calcMaterialId,
                    isDense: true,
                    decoration: const InputDecoration(
                      labelText: 'Select Recyclable Material',
                      contentPadding: EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                    ),
                    items: all.map((m) {
                      return DropdownMenuItem(
                        value: m.id,
                        child: Text(
                          '${m.name} (${formatUgx(m.valuePerKgUgx)}/kg)',
                          style: const TextStyle(fontSize: 12),
                        ),
                      );
                    }).toList(),
                    onChanged: (val) {
                      if (val != null) setState(() => _calcMaterialId = val);
                    },
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Expanded(
                        flex: 3,
                        child: Slider(
                          value: _calcWeightKg,
                          min: 1.0,
                          max: 50.0,
                          divisions: 49,
                          label: '${_calcWeightKg.round()} kg',
                          onChanged: (val) => setState(() => _calcWeightKg = val),
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(color: const Color(0xFFC8E6C9)),
                        ),
                        child: Text(
                          '${_calcWeightKg.toStringAsFixed(0)} kg',
                          style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 13),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  Builder(
                    builder: (context) {
                      final item = all.firstWhere(
                        (m) => m.id == _calcMaterialId,
                        orElse: () => all.first,
                      );
                      final totalValue = (item.valuePerKgUgx * _calcWeightKg).round();
                      final totalCo2 = (item.co2SavedPerKg * _calcWeightKg).toStringAsFixed(1);

                      return Row(
                        children: [
                          Expanded(
                            child: Container(
                              padding: const EdgeInsets.all(8),
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(10),
                              ),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const Text(
                                    'Estimated Cash Payout',
                                    style: TextStyle(fontSize: 10, color: Color(0xFF556958)),
                                  ),
                                  Text(
                                    '${formatUgx(totalValue)} UGX',
                                    style: const TextStyle(
                                      fontSize: 15,
                                      fontWeight: FontWeight.w800,
                                      color: Color(0xFF1B5E20),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Container(
                              padding: const EdgeInsets.all(8),
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(10),
                              ),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const Text(
                                    'Carbon Avoided',
                                    style: TextStyle(fontSize: 10, color: Color(0xFF556958)),
                                  ),
                                  Text(
                                    '$totalCo2 kg CO₂',
                                    style: const TextStyle(
                                      fontSize: 15,
                                      fontWeight: FontWeight.w800,
                                      color: Color(0xFF2E7D32),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ],
                      );
                    },
                  ),
                ],
              ],
            ),
          ),
          const SizedBox(height: 10),

          // List of waste materials
          Expanded(
            child: filtered.isEmpty
                ? const Center(
                    child: Text('No matching waste items in open database.'),
                  )
                : ListView.separated(
                    itemCount: filtered.length,
                    separatorBuilder: (context, index) => const SizedBox(height: 8),
                    itemBuilder: (ctx, idx) {
                      final item = filtered[idx];
                      return Material(
                        color: Colors.transparent,
                        child: InkWell(
                          onTap: () => _showMaterialDetails(item),
                          borderRadius: BorderRadius.circular(14),
                          child: Container(
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(14),
                              border: Border.all(
                                color: item.isHazardous
                                    ? const Color(0xFFFFCDD2)
                                    : const Color(0xFFE2EAE1),
                              ),
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    Icon(
                                      item.isHazardous
                                          ? Icons.warning_amber_rounded
                                          : Icons.recycling_rounded,
                                      color: item.isHazardous
                                          ? const Color(0xFFE53935)
                                          : const Color(0xFF2E7D32),
                                      size: 20,
                                    ),
                                    const SizedBox(width: 8),
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            item.name,
                                            style: const TextStyle(
                                              fontWeight: FontWeight.w800,
                                              fontSize: 13,
                                            ),
                                          ),
                                          Text(
                                            'Lugbara: ${item.lugbaraName} • ${item.category.label}',
                                            style: const TextStyle(
                                              fontSize: 11,
                                              color: Color(0xFF647568),
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                    Container(
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 8,
                                        vertical: 4,
                                      ),
                                      decoration: BoxDecoration(
                                        color: const Color(0xFFE8F5E9),
                                        borderRadius: BorderRadius.circular(8),
                                      ),
                                      child: Text(
                                        '${formatUgx(item.valuePerKgUgx)}/kg',
                                        style: const TextStyle(
                                          fontSize: 11,
                                          fontWeight: FontWeight.w800,
                                          color: Color(0xFF1B5E20),
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 6),
                                Text(
                                  'Degrades: ${item.decompositionTime} • ${item.sortingTip}',
                                  style: const TextStyle(
                                    fontSize: 11,
                                    color: Color(0xFF384A3B),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }
}
