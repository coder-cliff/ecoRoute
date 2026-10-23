import '../../domain/enums/zone.dart';

enum WasteCategory {
  organic('Organic & Biodegradable', '0xFF4CAF50'),
  plastic('Recyclable Plastics', '0xFF2196F3'),
  paper('Paper & Cardboard', '0xFFFFA726'),
  metal('Scrap Metals', '0xFF78909C'),
  glass('Glass & Bottles', '0xFF26A69A'),
  hazardous('Hazardous & E-Waste', '0xFFE53935');

  const WasteCategory(this.label, this.colorHex);
  final String label;
  final String colorHex;
}

class WasteMaterial {
  const WasteMaterial({
    required this.id,
    required this.name,
    required this.lugbaraName,
    required this.category,
    required this.decompositionTime,
    required this.valuePerKgUgx,
    required this.co2SavedPerKg,
    required this.sortingTip,
    required this.recyclingTip,
    this.isHazardous = false,
  });

  final String id;
  final String name;
  final String lugbaraName;
  final WasteCategory category;
  final String decompositionTime;
  final int valuePerKgUgx;
  final double co2SavedPerKg;
  final String sortingTip;
  final String recyclingTip;
  final bool isHazardous;
}

class RecyclingFacility {
  const RecyclingFacility({
    required this.id,
    required this.name,
    required this.zone,
    required this.latitude,
    required this.longitude,
    required this.address,
    required this.acceptedCategories,
    required this.operatingHours,
    required this.contactPhone,
  });

  final String id;
  final String name;
  final Zone zone;
  final double latitude;
  final double longitude;
  final String address;
  final List<WasteCategory> acceptedCategories;
  final String operatingHours;
  final String contactPhone;
}

class MunicipalWasteBenchmark {
  const MunicipalWasteBenchmark({
    required this.city,
    required this.dailyPerCapitaKg,
    required this.totalDailyTonnage,
    required this.organicPercentage,
    required this.plasticsPercentage,
    required this.paperPercentage,
    required this.recyclablePotentialPercentage,
    required this.currentCollectionCoverage,
  });

  final String city;
  final double dailyPerCapitaKg;
  final double totalDailyTonnage;
  final double organicPercentage;
  final double plasticsPercentage;
  final double paperPercentage;
  final double recyclablePotentialPercentage;
  final double currentCollectionCoverage;
}

class WasteDatabaseService {
  const WasteDatabaseService();

  static const WasteDatabaseService instance = WasteDatabaseService();

  /// Official open benchmarks from World Bank & NEMA Uganda
  MunicipalWasteBenchmark getAruaBenchmarks() {
    return const MunicipalWasteBenchmark(
      city: 'Arua City, West Nile',
      dailyPerCapitaKg: 0.44,
      totalDailyTonnage: 125.0,
      organicPercentage: 68.2,
      plasticsPercentage: 14.5,
      paperPercentage: 7.8,
      recyclablePotentialPercentage: 86.0,
      currentCollectionCoverage: 42.5,
    );
  }

  /// Open dataset of waste materials, decomposition, recycling rates, and Lugbara translations
  List<WasteMaterial> getAllMaterials() {
    return const [
      // Plastics
      WasteMaterial(
        id: 'mat-pet',
        name: 'PET Beverage Bottles',
        lugbaraName: 'Kopo kopo kabi kabi',
        category: WasteCategory.plastic,
        decompositionTime: '450 years',
        valuePerKgUgx: 800,
        co2SavedPerKg: 1.5,
        sortingTip: 'Rinse out liquids, remove cap, and flatten to save tricycle sack space.',
        recyclingTip: 'Collected by Arua Hill Recovery Hub and converted into recycled polyester fibers.',
      ),
      WasteMaterial(
        id: 'mat-hdpe',
        name: 'HDPE Jerrycans & Jugs',
        lugbaraName: 'Kopoo dongo dongo',
        category: WasteCategory.plastic,
        decompositionTime: '100 years',
        valuePerKgUgx: 1200,
        co2SavedPerKg: 2.1,
        sortingTip: 'Drain completely. Separate yellow cooking oil containers from fuel containers.',
        recyclingTip: 'Shredded and remelted into agricultural drainage pipes and basins.',
      ),
      WasteMaterial(
        id: 'mat-ldpe',
        name: 'Polythene Bags (Kaveera)',
        lugbaraName: 'Kaveera / Lafa',
        category: WasteCategory.plastic,
        decompositionTime: '20-50 years',
        valuePerKgUgx: 350,
        co2SavedPerKg: 0.8,
        sortingTip: 'Bundle clean dry plastic wrappers into a single sack.',
        recyclingTip: 'Used locally for paving brick composite manufacturing.',
      ),

      // Organic
      WasteMaterial(
        id: 'mat-banana',
        name: 'Banana & Matooke Peels',
        lugbaraName: 'Agbi / Etsu kabi',
        category: WasteCategory.organic,
        decompositionTime: '2-4 weeks',
        valuePerKgUgx: 150,
        co2SavedPerKg: 0.4,
        sortingTip: 'Separate from plastics and nylon wrappers to avoid composting contamination.',
        recyclingTip: 'Diverted to Muni University Agro-Composting Yard for organic fertilizer production.',
      ),
      WasteMaterial(
        id: 'mat-cassava',
        name: 'Cassava & Food Scraps',
        lugbaraName: 'Inya kabi / Nyaka efa',
        category: WasteCategory.organic,
        decompositionTime: '1-3 weeks',
        valuePerKgUgx: 100,
        co2SavedPerKg: 0.3,
        sortingTip: 'Keep in aerated sacks; schedule collection within 48 hours to prevent odor.',
        recyclingTip: 'Feedstock for municipal bio-gas digestion and farm animal feed.',
      ),
      WasteMaterial(
        id: 'mat-market-agro',
        name: 'Market Fruit & Vegetable Waste',
        lugbaraName: 'Arua marikiti liru',
        category: WasteCategory.organic,
        decompositionTime: '1-2 weeks',
        valuePerKgUgx: 200,
        co2SavedPerKg: 0.5,
        sortingTip: 'Ideal for municipal bulk commercial sacks at trading centers.',
        recyclingTip: 'Processed into nutrient-rich black soldier fly larvae for poultry protein.',
      ),

      // Metals
      WasteMaterial(
        id: 'mat-tin',
        name: 'Tin & Canned Food Tins',
        lugbaraName: 'Kopo chuma niri',
        category: WasteCategory.metal,
        decompositionTime: '50 years',
        valuePerKgUgx: 1500,
        co2SavedPerKg: 3.2,
        sortingTip: 'Wash food residue and crush flat before bagging.',
        recyclingTip: 'Smelted in West Nile foundry facilities for rebar and agricultural hoes.',
      ),
      WasteMaterial(
        id: 'mat-scrap',
        name: 'Scrap Iron & Roofing Nails',
        lugbaraName: 'Chuma nyaza',
        category: WasteCategory.metal,
        decompositionTime: '100+ years',
        valuePerKgUgx: 1800,
        co2SavedPerKg: 4.0,
        sortingTip: 'Package in puncture-proof sacks to protect tricycle route riders from injury.',
        recyclingTip: 'Directly sold to local metal artisans in River Oli industrial corridor.',
      ),

      // Paper & Cardboard
      WasteMaterial(
        id: 'mat-cardboard',
        name: 'Corrugated Packaging Boxes',
        lugbaraName: 'Karatasi dongo',
        category: WasteCategory.paper,
        decompositionTime: '2 months',
        valuePerKgUgx: 500,
        co2SavedPerKg: 1.1,
        sortingTip: 'Keep dry. Wet cardboard loses 80% of its recycling value.',
        recyclingTip: 'Pulping and remanufacturing into egg trays and seedling planting pots.',
      ),
      WasteMaterial(
        id: 'mat-paper',
        name: 'Exercise Books & Newsprint',
        lugbaraName: 'Karatasi azo / Gazeti',
        category: WasteCategory.paper,
        decompositionTime: '6 weeks',
        valuePerKgUgx: 400,
        co2SavedPerKg: 0.9,
        sortingTip: 'Remove plastic laminated covers before bundling.',
        recyclingTip: 'Baled and transported for packaging paper production.',
      ),

      // Glass
      WasteMaterial(
        id: 'mat-glass',
        name: 'Glass Soda & Beer Bottles',
        lugbaraName: 'Chupa kabi',
        category: WasteCategory.glass,
        decompositionTime: '1,000,000 years',
        valuePerKgUgx: 300,
        co2SavedPerKg: 0.7,
        sortingTip: 'Handle with care. Return intact beverage bottles for brewery deposit returns.',
        recyclingTip: 'Crushed into cullet for terrazzo flooring and glass container remelting.',
      ),

      // Hazardous / E-Waste
      WasteMaterial(
        id: 'mat-battery',
        name: 'Dry-Cell Radio & Solar Batteries',
        lugbaraName: 'Betiri kabi',
        category: WasteCategory.hazardous,
        decompositionTime: '100+ years',
        valuePerKgUgx: 2500,
        co2SavedPerKg: 5.5,
        sortingTip: 'NEVER burn or mix with household sacks. Toxic heavy metals leach into groundwater.',
        recyclingTip: 'Delivered to Hospital Safe Biomedical & E-Waste Depot for safe neutralization.',
        isHazardous: true,
      ),
      WasteMaterial(
        id: 'mat-ewaste',
        name: 'Mobile Phone Chargers & Circuit Boards',
        lugbaraName: 'Simu chuma / Chaja kabi',
        category: WasteCategory.hazardous,
        decompositionTime: 'Indefinite',
        valuePerKgUgx: 4500,
        co2SavedPerKg: 6.2,
        sortingTip: 'Store in dry container away from rain.',
        recyclingTip: 'Precious metals (copper, tin, gold trace) extracted by licensed recyclers.',
        isHazardous: true,
      ),
    ];
  }

  /// Open database of Arua municipal drop-off hubs and transfer bays
  List<RecyclingFacility> getAruaFacilities() {
    return const [
      RecyclingFacility(
        id: 'fac-central',
        name: 'Arua Central Market Eco-Station',
        zone: Zone.north,
        latitude: 3.0305,
        longitude: 30.9110,
        address: 'Market Lane, Central Division, Arua',
        acceptedCategories: [WasteCategory.organic, WasteCategory.plastic, WasteCategory.paper],
        operatingHours: 'Mon-Sat: 6:00 AM - 6:00 PM',
        contactPhone: '+256394880352',
      ),
      RecyclingFacility(
        id: 'fac-oli',
        name: 'River Oli Community Recycling Bay',
        zone: Zone.west,
        latitude: 3.0180,
        longitude: 30.9020,
        address: 'Oli Division Office Road, Arua',
        acceptedCategories: [WasteCategory.plastic, WasteCategory.metal, WasteCategory.glass],
        operatingHours: 'Mon-Fri: 7:30 AM - 5:00 PM',
        contactPhone: '+256394880352',
      ),
      RecyclingFacility(
        id: 'fac-hill',
        name: 'Arua Hill Plastics Recovery Hub',
        zone: Zone.east,
        latitude: 3.0250,
        longitude: 30.9230,
        address: 'Near Arua Hill Stadium, East Division',
        acceptedCategories: [WasteCategory.plastic, WasteCategory.paper, WasteCategory.metal],
        operatingHours: 'Daily: 7:00 AM - 7:00 PM',
        contactPhone: '+256394880352',
      ),
      RecyclingFacility(
        id: 'fac-hospital',
        name: 'Hospital Safe Biomedical & E-Waste Depot',
        zone: Zone.south,
        latitude: 3.0120,
        longitude: 30.9125,
        address: 'Arua Regional Referral Hospital Perimeter, South Division',
        acceptedCategories: [WasteCategory.hazardous, WasteCategory.metal],
        operatingHours: '24/7 Monitored Drop-off',
        contactPhone: '+256394880352',
      ),
      RecyclingFacility(
        id: 'fac-muni',
        name: 'Muni University Agro-Composting Yard',
        zone: Zone.south,
        latitude: 2.9980,
        longitude: 30.9180,
        address: 'Muni Campus Agronomy Field, South Division',
        acceptedCategories: [WasteCategory.organic],
        operatingHours: 'Mon-Fri: 8:00 AM - 4:30 PM',
        contactPhone: '+256394880352',
      ),
    ];
  }

  /// Full-text search across English and Lugbara terms with stem matching
  List<WasteMaterial> searchMaterials(String query) {
    final clean = query.trim().toLowerCase();
    if (clean.isEmpty) return getAllMaterials();

    final queryVariations = <String>{clean};
    if (clean.endsWith('y') && clean.length > 2) {
      queryVariations.add('${clean.substring(0, clean.length - 1)}ie');
      queryVariations.add('${clean.substring(0, clean.length - 1)}ies');
    }
    if (clean.endsWith('ies') && clean.length > 3) {
      queryVariations.add('${clean.substring(0, clean.length - 3)}y');
    }
    if (clean.endsWith('s') && clean.length > 3) {
      queryVariations.add(clean.substring(0, clean.length - 1));
    } else {
      queryVariations.add('${clean}s');
    }

    return getAllMaterials().where((item) {
      final targets = [
        item.name.toLowerCase(),
        item.lugbaraName.toLowerCase(),
        item.category.label.toLowerCase(),
        item.sortingTip.toLowerCase(),
        item.recyclingTip.toLowerCase(),
        item.id.toLowerCase(),
      ];

      return queryVariations.any(
        (variant) => targets.any((t) => t.contains(variant)),
      );
    }).toList();
  }

  /// Find facilities serving instant municipal drop-offs across Arua
  List<RecyclingFacility> getInstantFacilities() => getAruaFacilities();

  /// Find facilities serving a specific municipal zone
  List<RecyclingFacility> getFacilitiesByZone(Zone zone) {
    return getAruaFacilities().where((f) => f.zone == zone).toList();
  }

  /// Compute estimated market recycling earnings in UGX
  int estimateRecycleValue({required String materialId, required double weightKg}) {
    final match = getAllMaterials().firstWhere(
      (m) => m.id == materialId,
      orElse: () => getAllMaterials().first,
    );
    return (match.valuePerKgUgx * weightKg).round();
  }
}
