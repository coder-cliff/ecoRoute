import 'package:flutter/material.dart';
import 'waste_category.dart';

class WasteGuideItem {
  final String name;
  final WasteCategoryType category;
  final String binColorName;
  final Color binColor;
  final String disposalTip;
  final String iconEmoji;

  const WasteGuideItem({
    required this.name,
    required this.category,
    required this.binColorName,
    required this.binColor,
    required this.disposalTip,
    required this.iconEmoji,
  });

  /// Complete offline municipal waste sorting database (100% Free & Open)
  static const List<WasteGuideItem> municipalCatalog = [
    // Plastics
    WasteGuideItem(
      name: 'Plastic Water / Soda Bottle (PET)',
      category: WasteCategoryType.plastics,
      binColorName: 'Yellow Bin (Plastics & Synthetics)',
      binColor: Color(0xFFFBC02D),
      disposalTip: 'Empty all liquids, rinse lightly, and crush to save bag space.',
      iconEmoji: '🍾',
    ),
    WasteGuideItem(
      name: 'Plastic Shopping / Grocery Bag',
      category: WasteCategoryType.plastics,
      binColorName: 'Yellow Bin (Plastics & Synthetics)',
      binColor: Color(0xFFFBC02D),
      disposalTip: 'Bundle clean bags together into a single bag for sorting.',
      iconEmoji: '🛍️',
    ),
    WasteGuideItem(
      name: 'Shampoo / Detergent Bottle (HDPE)',
      category: WasteCategoryType.plastics,
      binColorName: 'Yellow Bin (Plastics & Synthetics)',
      binColor: Color(0xFFFBC02D),
      disposalTip: 'Rinse out soap residue. Caps can stay screwed on.',
      iconEmoji: '🧴',
    ),
    WasteGuideItem(
      name: 'Takeaway Food Container (PP / Styrofoam)',
      category: WasteCategoryType.plastics,
      binColorName: 'Yellow Bin (Plastics & Synthetics)',
      binColor: Color(0xFFFBC02D),
      disposalTip: 'Scrape off all food waste first. Contaminated plastics cannot be recycled.',
      iconEmoji: '🥡',
    ),

    // Organic
    WasteGuideItem(
      name: 'Fruit Peels & Vegetable Scraps',
      category: WasteCategoryType.organic,
      binColorName: 'Green Bin (Compost / Organics)',
      binColor: Color(0xFF2E7D32),
      disposalTip: 'Perfect for composting. Diverts methane production from local landfills.',
      iconEmoji: '🍌',
    ),
    WasteGuideItem(
      name: 'Coffee Grounds & Tea Bags',
      category: WasteCategoryType.organic,
      binColorName: 'Green Bin (Compost / Organics)',
      binColor: Color(0xFF2E7D32),
      disposalTip: 'Remove any synthetic staple or plastic tags before adding to organics.',
      iconEmoji: '☕',
    ),
    WasteGuideItem(
      name: 'Garden Weeds, Leaves & Grass Clippings',
      category: WasteCategoryType.organic,
      binColorName: 'Green Bin (Compost / Organics)',
      binColor: Color(0xFF2E7D32),
      disposalTip: 'Keep dry and free from stones, plastics, and animal waste.',
      iconEmoji: '🍂',
    ),
    WasteGuideItem(
      name: 'Leftover Food & Cooked Rice/Grains',
      category: WasteCategoryType.organic,
      binColorName: 'Green Bin (Compost / Organics)',
      binColor: Color(0xFF2E7D32),
      disposalTip: 'Seal tightly in bio-degradable bags to prevent odors and pests.',
      iconEmoji: '🍲',
    ),

    // Paper & Cardboard
    WasteGuideItem(
      name: 'Cardboard Delivery Box (Amazon / Jumia)',
      category: WasteCategoryType.paper,
      binColorName: 'Blue Bin (Paper & Fiber)',
      binColor: Color(0xFF1976D2),
      disposalTip: 'Flatten completely. Remove packing tape and plastic bubble wraps.',
      iconEmoji: '📦',
    ),
    WasteGuideItem(
      name: 'Newspaper, Magazines & Office Paper',
      category: WasteCategoryType.paper,
      binColorName: 'Blue Bin (Paper & Fiber)',
      binColor: Color(0xFF1976D2),
      disposalTip: 'Keep dry. Wet paper fibers decompose and degrade recycling grade.',
      iconEmoji: '📰',
    ),
    WasteGuideItem(
      name: 'Pizza Box (Greasy base)',
      category: WasteCategoryType.organic,
      binColorName: 'Green Bin (Compost) or General',
      binColor: Color(0xFF2E7D32),
      disposalTip: 'Tear off clean top for paper recycling; compost the greasy bottom.',
      iconEmoji: '🍕',
    ),
    WasteGuideItem(
      name: 'Egg Carton (Pressed paper pulp)',
      category: WasteCategoryType.paper,
      binColorName: 'Blue Bin (Paper & Fiber)',
      binColor: Color(0xFF1976D2),
      disposalTip: 'Highly compostable or recyclable with general paper.',
      iconEmoji: '🥚',
    ),

    // Metals
    WasteGuideItem(
      name: 'Aluminum Soda Can',
      category: WasteCategoryType.metal,
      binColorName: 'Silver / Grey Bin (Scrap Metal)',
      binColor: Color(0xFF616161),
      disposalTip: '100% recyclable infinitely! Rinse and crush for compact storage.',
      iconEmoji: '🥤',
    ),
    WasteGuideItem(
      name: 'Tin Can (Baked Beans, Canned Fish)',
      category: WasteCategoryType.metal,
      binColorName: 'Silver / Grey Bin (Scrap Metal)',
      binColor: Color(0xFF616161),
      disposalTip: 'Rinse thoroughly to remove oil/sauce. Push lid safely inside.',
      iconEmoji: '🥫',
    ),
    WasteGuideItem(
      name: 'Bottle Caps & Metal Jar Lids',
      category: WasteCategoryType.metal,
      binColorName: 'Silver / Grey Bin (Scrap Metal)',
      binColor: Color(0xFF616161),
      disposalTip: 'Collect inside an aluminum can and crimp closed so they do not fall out.',
      iconEmoji: '🪙',
    ),

    // E-Waste
    WasteGuideItem(
      name: 'Old Smartphone / Tablet',
      category: WasteCategoryType.eWaste,
      binColorName: 'Orange Bin (E-Waste Special Pickup)',
      binColor: Color(0xFFE65100),
      disposalTip: 'Factory reset and remove SIM/SD cards. Contains valuable precious metals.',
      iconEmoji: '📱',
    ),
    WasteGuideItem(
      name: 'Charging Cables & Power Adapters',
      category: WasteCategoryType.eWaste,
      binColorName: 'Orange Bin (E-Waste Special Pickup)',
      binColor: Color(0xFFE65100),
      disposalTip: 'Bundle cables neatly with a rubber band. Never cut copper wire.',
      iconEmoji: '🔌',
    ),
    WasteGuideItem(
      name: 'Computer Monitor / Laptop',
      category: WasteCategoryType.eWaste,
      binColorName: 'Orange Bin (E-Waste Special Pickup)',
      binColor: Color(0xFFE65100),
      disposalTip: 'Wrap screen with cardboard to prevent glass fracture during rider transport.',
      iconEmoji: '💻',
    ),

    // Hazardous
    WasteGuideItem(
      name: 'AA / AAA Alkaline or Lithium Batteries',
      category: WasteCategoryType.hazardous,
      binColorName: 'Red Bin (Hazardous Material)',
      binColor: Color(0xFFC62828),
      disposalTip: 'DANGER: Tape terminals with clear tape to prevent short circuits & fires.',
      iconEmoji: '🔋',
    ),
    WasteGuideItem(
      name: 'Fluorescent Bulbs / CFL Tubes',
      category: WasteCategoryType.hazardous,
      binColorName: 'Red Bin (Hazardous Material)',
      binColor: Color(0xFFC62828),
      disposalTip: 'Contains mercury vapor! Do not break. Keep in original sleeve or box.',
      iconEmoji: '💡',
    ),
    WasteGuideItem(
      name: 'Paint Cans & Solvents',
      category: WasteCategoryType.hazardous,
      binColorName: 'Red Bin (Hazardous Material)',
      binColor: Color(0xFFC62828),
      disposalTip: 'Allow wet paint to dry before collection. Keep sealed and upright.',
      iconEmoji: '🎨',
    ),
    WasteGuideItem(
      name: 'Expired Medicines / Tablets',
      category: WasteCategoryType.hazardous,
      binColorName: 'Red Bin (Hazardous Material)',
      binColor: Color(0xFFC62828),
      disposalTip: 'Never flush down the toilet. Keep in blister pack for hazardous drop-off.',
      iconEmoji: '💊',
    ),
  ];
}
