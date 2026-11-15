enum WasteType {
  household,
  tradingCenter,
  litter,
  overfullBin,
  illegalDumping,
  unknown,
}

extension WasteTypeLabel on WasteType {
  String get label => switch (this) {
    WasteType.household => 'Household Waste',
    WasteType.tradingCenter => 'Trading Center Waste',
    WasteType.litter => 'Litter',
    WasteType.overfullBin => 'Overfull Bin',
    WasteType.illegalDumping => 'Illegal Dumping',
    WasteType.unknown => 'Other / Unknown',
  };
}
