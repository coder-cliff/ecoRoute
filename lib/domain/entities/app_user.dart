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
}
