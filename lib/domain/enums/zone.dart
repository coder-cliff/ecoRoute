enum Zone { north, south, east, west }

extension ZoneLabel on Zone {
  String get label => switch (this) {
    Zone.north => 'North',
    Zone.south => 'South',
    Zone.east => 'East',
    Zone.west => 'West',
  };
}
