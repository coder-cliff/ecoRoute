enum UserRole {
  citizen,
  rider,
  admin,
}

extension UserRoleExtension on UserRole {
  String get displayName {
    switch (this) {
      case UserRole.citizen:
        return 'Resident / Citizen';
      case UserRole.rider:
        return 'Collection Rider';
      case UserRole.admin:
        return 'Operations Admin';
    }
  }

  String get badgeLabel {
    switch (this) {
      case UserRole.citizen:
        return 'Citizen';
      case UserRole.rider:
        return 'Rider';
      case UserRole.admin:
        return 'Admin';
    }
  }
}

class AppUser {
  final String id;
  final String name;
  final String phone;
  final String email;
  final UserRole role;
  final String avatarUrl;
  final String address;
  final String? vehicleInfo;

  const AppUser({
    required this.id,
    required this.name,
    required this.phone,
    required this.email,
    required this.role,
    this.avatarUrl = '',
    this.address = '',
    this.vehicleInfo,
  });

  AppUser copyWith({
    String? id,
    String? name,
    String? phone,
    String? email,
    UserRole? role,
    String? avatarUrl,
    String? address,
    String? vehicleInfo,
  }) {
    return AppUser(
      id: id ?? this.id,
      name: name ?? this.name,
      phone: phone ?? this.phone,
      email: email ?? this.email,
      role: role ?? this.role,
      avatarUrl: avatarUrl ?? this.avatarUrl,
      address: address ?? this.address,
      vehicleInfo: vehicleInfo ?? this.vehicleInfo,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'fullName': name,
        'phone': phone,
        'email': email,
        'role': role.name,
        'avatarUrl': avatarUrl,
        'address': address,
        'vehicleInfo': vehicleInfo,
      };

  factory AppUser.fromJson(Map<String, dynamic> json) {
    UserRole parsedRole = UserRole.citizen;
    final rawRole = json['role'] as String?;
    if (rawRole != null) {
      final lower = rawRole.toLowerCase();
      if (lower.contains('rider')) {
        parsedRole = UserRole.rider;
      } else if (lower.contains('admin')) {
        parsedRole = UserRole.admin;
      } else {
        parsedRole = UserRole.citizen;
      }
    }

    return AppUser(
      id: json['id'] as String? ?? json['uid'] as String? ?? 'usr_${DateTime.now().millisecondsSinceEpoch}',
      name: json['name'] as String? ?? json['fullName'] as String? ?? json['displayName'] as String? ?? 'EcoRoute User',
      phone: json['phone'] as String? ?? json['phoneNumber'] as String? ?? '',
      email: json['email'] as String? ?? '',
      role: parsedRole,
      avatarUrl: json['avatarUrl'] as String? ?? json['photoURL'] as String? ?? '',
      address: json['address'] as String? ?? json['cell'] as String? ?? '',
      vehicleInfo: json['vehicleInfo'] as String?,
    );
  }

  // Standard curated avatar presets available in profile settings
  static const List<Map<String, String>> standardAvatarPresets = [
    {
      'id': 'https://images.unsplash.com/photo-1534528741775-53994a69daeb?w=200&auto=format&fit=crop&q=80',
      'label': 'Sarah (Resident)',
      'category': 'Citizen',
    },
    {
      'id': 'https://images.unsplash.com/photo-1544005313-94ddf0286df2?w=200&auto=format&fit=crop&q=80',
      'label': 'Amina (Resident)',
      'category': 'Citizen',
    },
    {
      'id': 'https://images.unsplash.com/photo-1507003211169-0a1dd7228f2d?w=200&auto=format&fit=crop&q=80',
      'label': 'Alex (Rider #12)',
      'category': 'Rider',
    },
    {
      'id': 'https://images.unsplash.com/photo-1500648767791-00dcc994a43e?w=200&auto=format&fit=crop&q=80',
      'label': 'Brian (Rider #05)',
      'category': 'Rider',
    },
    {
      'id': 'https://images.unsplash.com/photo-1573496359142-b8d87734a5a2?w=200&auto=format&fit=crop&q=80',
      'label': 'Grace (Operations Admin)',
      'category': 'Admin',
    },
    {
      'id': 'https://images.unsplash.com/photo-1580489944761-15a19d654956?w=200&auto=format&fit=crop&q=80',
      'label': 'Jane (Citizen)',
      'category': 'Citizen',
    },
  ];
}

/// Backward compatibility alias for profile settings and legacy references
typedef UserModel = AppUser;

