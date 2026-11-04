import 'package:flutter/material.dart';

import '../../domain/enums/role.dart';
import '../pickup_request_repository.dart';
import 'auth_service.dart';
import 'waste_api_service.dart';
import '../../features/auth/login_screen.dart';
import '../../features/auth/role_select_screen.dart';
import '../../features/home/home_screen.dart';
import '../../features/rider/rider_task_hub.dart';
import '../../features/admin/admin_dashboard.dart';

class AppRouter {
  AppRouter._();

  static Widget getScreenForRole({
    required AppRole role,
    required PickupRequestRepository repository,
    AuthService? authService,
    WasteApiService? wasteApiService,
  }) {
    switch (role) {
      case AppRole.admin:
        return AdminDashboard(
          repository: repository,
          authService: authService,
          wasteApiService: wasteApiService,
        );
      case AppRole.rider:
        return RiderTaskHub(
          repository: repository,
          authService: authService,
          wasteApiService: wasteApiService,
        );
      case AppRole.resident:
      case AppRole.guest:
        return EcoRouteHomeScreen(
          repository: repository,
          authService: authService,
          wasteApiService: wasteApiService,
          enforcedRole: AppRole.resident,
        );
    }
  }

  static void routeToRole(
    BuildContext context, {
    required AppRole role,
    required PickupRequestRepository repository,
    AuthService? authService,
    WasteApiService? wasteApiService,
  }) {
    final destination = getScreenForRole(
      role: role,
      repository: repository,
      authService: authService,
      wasteApiService: wasteApiService,
    );
    Navigator.of(context).pushAndRemoveUntil(
      PageRouteBuilder<void>(
        pageBuilder: (context, animation, secondaryAnimation) => destination,
        transitionsBuilder: (context, animation, secondaryAnimation, child) {
          return FadeTransition(opacity: animation, child: child);
        },
        transitionDuration: const Duration(milliseconds: 300),
      ),
      (route) => false,
    );
  }

  static void routeToRoleSelect(
    BuildContext context, {
    required PickupRequestRepository repository,
    AuthService? authService,
    WasteApiService? wasteApiService,
  }) {
    Navigator.of(context).pushAndRemoveUntil(
      PageRouteBuilder<void>(
        pageBuilder: (context, animation, secondaryAnimation) => RoleSelectScreen(
          repository: repository,
          authService: authService,
          wasteApiService: wasteApiService,
        ),
        transitionsBuilder: (context, animation, secondaryAnimation, child) {
          return FadeTransition(opacity: animation, child: child);
        },
        transitionDuration: const Duration(milliseconds: 250),
      ),
      (route) => false,
    );
  }

  static void routeToLogin(
    BuildContext context, {
    required PickupRequestRepository repository,
    AuthService? authService,
    WasteApiService? wasteApiService,
  }) {
    Navigator.of(context).pushAndRemoveUntil(
      PageRouteBuilder<void>(
        pageBuilder: (context, animation, secondaryAnimation) => LoginScreen(
          repository: repository,
          authService: authService,
          wasteApiService: wasteApiService,
        ),
        transitionsBuilder: (context, animation, secondaryAnimation, child) {
          return FadeTransition(opacity: animation, child: child);
        },
        transitionDuration: const Duration(milliseconds: 250),
      ),
      (route) => false,
    );
  }
}
