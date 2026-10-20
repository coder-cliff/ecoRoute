enum UserRole {
  citizen,
  rider,
  admin,
}

class AppUser {
  final String id;
  final String name;
  final String phone;
  final String email;
  final UserRole role;
  final String avatarUrl;

  const AppUser({
    required this.id,
    required this.name,
    required this.phone,
    required this.email,
    required this.role,
    this.avatarUrl = '',
  });

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'phone': phone,
        'email': email,
        'role': role.name,
        'avatarUrl': avatarUrl,
      };

  factory AppUser.fromJson(Map<String, dynamic> json) => AppUser(
        id: json['id'] as String,
        name: json['name'] as String,
        phone: json['phone'] as String,
        email: json['email'] as String,
        role: UserRole.values.byName(json['role'] as String),
        avatarUrl: json['avatarUrl'] as String? ?? '',
      );

  // Predefined demo personas for live demonstration & defence
  static const AppUser demoCitizen = AppUser(
    id: 'user_cit_01',
    name: 'Sarah Namukasa',
    phone: '+256 772 123456',
    email: 'sarah.citizen@ecoroute.org',
    role: UserRole.citizen,
  );

  static const AppUser demoRider = AppUser(
    id: 'user_rid_01',
    name: 'Alex Mukasa (Rider #12)',
    phone: '+256 701 987654',
    email: 'alex.rider@ecoroute.org',
    role: UserRole.rider,
  );

  static const AppUser demoAdmin = AppUser(
    id: 'user_adm_01',
    name: 'Grace Atuhaire (Supervisor)',
    phone: '+256 750 334455',
    email: 'grace.admin@ecoroute.org',
    role: UserRole.admin,
  );
}
