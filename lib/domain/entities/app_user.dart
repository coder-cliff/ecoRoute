import '../enums/role.dart';

class AppUser {
  const AppUser({
    required this.id,
    required this.fullName,
    required this.email,
    required this.phone,
    this.role = AppRole.resident,
    this.address,
  });

  final String id;
  final String fullName;
  final String email;
  final String phone;
  final AppRole role;
  final String? address;

  AppUser copyWith({
    String? id,
    String? fullName,
    String? email,
    String? phone,
    AppRole? role,
    String? address,
  }) {
    return AppUser(
      id: id ?? this.id,
      fullName: fullName ?? this.fullName,
      email: email ?? this.email,
      phone: phone ?? this.phone,
      role: role ?? this.role,
      address: address ?? this.address,
    );
  }
}
