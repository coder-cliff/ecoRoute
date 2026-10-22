import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import '../../domain/entities/app_user.dart';
import '../../domain/enums/role.dart';

class AuthService {
  AuthService(this._preferences);

  static const String _sessionKey = 'ecoroute_current_user_v1';
  static const String _usersKey = 'ecoroute_registered_users_v1';

  final SharedPreferences _preferences;

  static const List<Map<String, dynamic>> _demoAccounts = [
    {
      'id': 'res-demo-1',
      'fullName': 'Amina Dranzoa (Resident)',
      'email': 'resident@ecoroute.demo',
      'phone': '+256 772 123 456',
      'role': 'resident',
      'password': 'demo123',
    },
    {
      'id': 'rider-demo-1',
      'fullName': 'Juma Okello (Route Rider)',
      'email': 'rider@ecoroute.demo',
      'phone': '+256 701 987 654',
      'role': 'rider',
      'password': 'demo123',
    },
    {
      'id': 'admin-demo-1',
      'fullName': 'Grace Candiru (Municipal Admin)',
      'email': 'admin@ecoroute.demo',
      'phone': '+256 782 555 111',
      'role': 'admin',
      'password': 'demo123',
    },
  ];

  AppUser? getCurrentUser() {
    final raw = _preferences.getString(_sessionKey);
    if (raw == null) return null;
    try {
      final map = jsonDecode(raw) as Map<String, dynamic>;
      return AppUser(
        id: map['id'] as String,
        fullName: map['fullName'] as String,
        email: map['email'] as String,
        phone: map['phone'] as String,
        role: AppRole.values.byName(map['role'] as String),
      );
    } catch (_) {
      return null;
    }
  }

  Future<void> _saveSession(AppUser user) async {
    final data = {
      'id': user.id,
      'fullName': user.fullName,
      'email': user.email,
      'phone': user.phone,
      'role': user.role.name,
    };
    await _preferences.setString(_sessionKey, jsonEncode(data));
  }

  Future<void> logout() async {
    await _preferences.remove(_sessionKey);
  }

  Future<AppUser?> login({
    required String email,
    required String password,
  }) async {
    final cleanEmail = email.trim().toLowerCase();

    // 1. Check demo accounts
    for (final demo in _demoAccounts) {
      if ((demo['email'] as String).toLowerCase() == cleanEmail &&
          demo['password'] == password) {
        final user = AppUser(
          id: demo['id'] as String,
          fullName: demo['fullName'] as String,
          email: demo['email'] as String,
          phone: demo['phone'] as String,
          role: AppRole.values.byName(demo['role'] as String),
        );
        await _saveSession(user);
        return user;
      }
    }

    // 2. Check registered accounts
    final registered = _getRegisteredUsers();
    for (final reg in registered) {
      if ((reg['email'] as String).toLowerCase() == cleanEmail &&
          reg['password'] == password) {
        final user = AppUser(
          id: reg['id'] as String,
          fullName: reg['fullName'] as String,
          email: reg['email'] as String,
          phone: reg['phone'] as String,
          role: AppRole.values.byName(reg['role'] as String),
        );
        await _saveSession(user);
        return user;
      }
    }

    return null;
  }

  Future<AppUser> register({
    required String fullName,
    required String email,
    required String phone,
    required String password,
    AppRole role = AppRole.resident,
  }) async {
    final cleanEmail = email.trim().toLowerCase();
    final users = _getRegisteredUsers();

    final userId = 'user-${DateTime.now().millisecondsSinceEpoch}';
    final newUserMap = {
      'id': userId,
      'fullName': fullName.trim(),
      'email': cleanEmail,
      'phone': phone.trim().isEmpty ? '+256 772 000 000' : phone.trim(),
      'role': role.name,
      'password': password,
    };

    users.removeWhere((u) => (u['email'] as String).toLowerCase() == cleanEmail);
    users.add(newUserMap);

    await _preferences.setString(_usersKey, jsonEncode(users));

    final user = AppUser(
      id: userId,
      fullName: fullName.trim(),
      email: cleanEmail,
      phone: phone.trim().isEmpty ? '+256 772 000 000' : phone.trim(),
      role: role,
    );
    await _saveSession(user);
    return user;
  }

  List<Map<String, dynamic>> _getRegisteredUsers() {
    final raw = _preferences.getString(_usersKey);
    if (raw == null) return [];
    try {
      final list = jsonDecode(raw) as List<dynamic>;
      return list.cast<Map<String, dynamic>>();
    } catch (_) {
      return [];
    }
  }
}
