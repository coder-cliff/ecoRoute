enum AppRole { guest, resident, rider, admin }

extension AppRoleLabel on AppRole {
  String get label => switch (this) {
    AppRole.guest => 'Guest',
    AppRole.resident => 'Resident',
    AppRole.rider => 'Rider',
    AppRole.admin => 'Admin',
  };
}
