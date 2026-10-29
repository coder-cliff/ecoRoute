int calculateAmount({required int sackCount, required int pricePerSackUgx}) {
  if (sackCount < 1 || sackCount > 50) {
    throw ArgumentError(
      'Sack count must be between 1 and 50 for a valid pickup.',
    );
  }

  if (pricePerSackUgx < 0) {
    throw ArgumentError('Price per sack cannot be negative.');
  }

  return sackCount * pricePerSackUgx;
}

class CommercialPricing {
  static const int standardResidentialRate = 1500;
  static const int standardCommercialBaseRate = 3000;

  /// Commercial volume-tiered wholesale rates in Arua City:
  /// Tier 1 (1 - 4 sacks): 3,000 UGX / sack (Small shop / business)
  /// Tier 2 (5 - 14 sacks): 2,500 UGX / sack (Medium eatery / market vendor)
  /// Tier 3 (15 - 29 sacks): 2,000 UGX / sack (Full Tricycle / hotel / hospitality)
  /// Tier 4 (30 - 50 sacks): 1,800 UGX / sack (Bulk market / institutional / university)
  static int ratePerSack({
    required int sackCount,
    bool isCommercial = false,
  }) {
    if (!isCommercial) return standardResidentialRate;
    if (sackCount >= 30) return 1800;
    if (sackCount >= 15) return 2000;
    if (sackCount >= 5) return 2500;
    return standardCommercialBaseRate;
  }

  static int calculateTotal({
    required int sackCount,
    bool isCommercial = false,
  }) {
    final rate = ratePerSack(sackCount: sackCount, isCommercial: isCommercial);
    return sackCount * rate;
  }

  static int calculateVolumeDiscount({
    required int sackCount,
    bool isCommercial = false,
  }) {
    if (!isCommercial || sackCount < 5) return 0;
    final standardTotal = sackCount * standardCommercialBaseRate;
    final discountedTotal = calculateTotal(sackCount: sackCount, isCommercial: true);
    return standardTotal - discountedTotal;
  }

  static String getTierTitle({
    required int sackCount,
    bool isCommercial = false,
  }) {
    if (!isCommercial) return 'Residential Standard';
    if (sackCount >= 30) return 'Bulk Market / Institutional (Tier 4)';
    if (sackCount >= 15) return 'Full Tricycle / Hospitality (Tier 3)';
    if (sackCount >= 5) return 'Medium Commercial (Tier 2)';
    return 'Small Enterprise (Tier 1)';
  }
}
