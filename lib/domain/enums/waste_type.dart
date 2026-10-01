enum WasteType { household, tradingCenter, unknown }

extension WasteTypeLabel on WasteType {
  String get label => switch (this) {
    WasteType.household => 'Household',
    WasteType.tradingCenter => 'Trading center',
    WasteType.unknown => 'Unknown',
  };
}
