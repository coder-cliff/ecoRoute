import 'package:flutter/material.dart';

enum WasteCategoryType {
  organic,
  plastics,
  paper,
  eWaste,
  metal,
  hazardous,
  general,
}

enum WasteVolumeSize {
  small,  // Standard 25L Bag
  medium, // 60L Sack / Bin
  large,  // 120L+ Bulk Cartload
}

extension WasteVolumeSizeExtension on WasteVolumeSize {
  String get label {
    switch (this) {
      case WasteVolumeSize.small:
        return 'Small (25L Bag)';
      case WasteVolumeSize.medium:
        return 'Medium (60L Bin)';
      case WasteVolumeSize.large:
        return 'Large (120L Bulk)';
    }
  }

  String get description {
    switch (this) {
      case WasteVolumeSize.small:
        return 'Fits standard grocery/rubbish sack';
      case WasteVolumeSize.medium:
        return 'Standard curbside household bin';
      case WasteVolumeSize.large:
        return 'Commercial cartload or bulk sacks';
    }
  }

  double get multiplier {
    switch (this) {
      case WasteVolumeSize.small:
        return 1.0;
      case WasteVolumeSize.medium:
        return 1.8;
      case WasteVolumeSize.large:
        return 3.2;
    }
  }
}

class WasteCategory {
  final WasteCategoryType type;
  final String title;
  final String description;
  final IconData icon;
  final Color color;
  final double pricePerUnit; // Cash in USD / UGX equivalent
  final double carbonSavedPerUnitKg;

  const WasteCategory({
    required this.type,
    required this.title,
    required this.description,
    required this.icon,
    required this.color,
    required this.pricePerUnit,
    required this.carbonSavedPerUnitKg,
  });

  static const List<WasteCategory> allCategories = [
    WasteCategory(
      type: WasteCategoryType.plastics,
      title: 'Plastics & Bottles',
      description: 'PET bottles, plastic bags, jerrycans & packaging',
      icon: Icons.recycling_rounded,
      color: Color(0xFF1E88E5),
      pricePerUnit: 2.00,
      carbonSavedPerUnitKg: 1.8,
    ),
    WasteCategory(
      type: WasteCategoryType.organic,
      title: 'Organic & Food Waste',
      description: 'Kitchen scraps, vegetable peelings & garden refuse',
      icon: Icons.eco_rounded,
      color: Color(0xFF43A047),
      pricePerUnit: 1.50,
      carbonSavedPerUnitKg: 2.5,
    ),
    WasteCategory(
      type: WasteCategoryType.paper,
      title: 'Paper & Cardboard',
      description: 'Boxes, cartons, newspapers & office paper',
      icon: Icons.inventory_2_outlined,
      color: Color(0xFFFB8C00),
      pricePerUnit: 1.20,
      carbonSavedPerUnitKg: 1.2,
    ),
    WasteCategory(
      type: WasteCategoryType.eWaste,
      title: 'E-Waste & Electronics',
      description: 'Broken electronics, wires, old phones, circuit boards',
      icon: Icons.electrical_services_rounded,
      color: Color(0xFFE65100),
      pricePerUnit: 4.00,
      carbonSavedPerUnitKg: 5.0,
    ),
    WasteCategory(
      type: WasteCategoryType.metal,
      title: 'Scrap Metal & Cans',
      description: 'Aluminum cans, iron sheets, kitchen metal scraps',
      icon: Icons.construction_rounded,
      color: Color(0xFF757575),
      pricePerUnit: 2.50,
      carbonSavedPerUnitKg: 3.2,
    ),
    WasteCategory(
      type: WasteCategoryType.hazardous,
      title: 'Hazardous Refuse',
      description: 'Batteries, CFL fluorescent tubes, solvents, chemicals',
      icon: Icons.warning_rounded,
      color: Color(0xFFC62828),
      pricePerUnit: 4.50,
      carbonSavedPerUnitKg: 6.0,
    ),
    WasteCategory(
      type: WasteCategoryType.general,
      title: 'General Mixed Waste',
      description: 'Non-recyclable domestic household refuse',
      icon: Icons.delete_sweep_rounded,
      color: Color(0xFF546E7A),
      pricePerUnit: 3.00,
      carbonSavedPerUnitKg: 0.5,
    ),
  ];

  static WasteCategory getByType(WasteCategoryType type) {
    return allCategories.firstWhere(
      (c) => c.type == type,
      orElse: () => allCategories.last,
    );
  }
}
