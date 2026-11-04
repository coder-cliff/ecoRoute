enum AppRole {
  guest,
  resident,
  rider,
  routeSupervisor,
  operationsManager,
  admin,
}

extension AppRoleLabel on AppRole {
  String get label => switch (this) {
    AppRole.guest => 'Guest',
    AppRole.resident => 'Resident',
    AppRole.rider => 'Rider',
    AppRole.routeSupervisor => 'Route Supervisor',
    AppRole.operationsManager => 'Operations Manager',
    AppRole.admin => 'Super Admin',
  };

  bool get isAdminTier => switch (this) {
    AppRole.admin || AppRole.operationsManager || AppRole.routeSupervisor => true,
    _ => false,
  };

  bool get canDispatch => switch (this) {
    AppRole.admin || AppRole.operationsManager || AppRole.routeSupervisor => true,
    _ => false,
  };

  bool get canReconcileCash => switch (this) {
    AppRole.admin || AppRole.operationsManager || AppRole.routeSupervisor => true,
    _ => false,
  };

  bool get canApprovePayouts => switch (this) {
    AppRole.admin || AppRole.operationsManager => true,
    _ => false,
  };

  bool get canManageStaff => switch (this) {
    AppRole.admin => true,
    _ => false,
  };

  bool get canConfigureTariffs => switch (this) {
    AppRole.admin => true,
    _ => false,
  };
}
