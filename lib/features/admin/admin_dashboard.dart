import 'package:flutter/material.dart';

import '../../core/pickup_request_repository.dart';
import '../../core/services/auth_service.dart';
import '../../core/services/waste_api_service.dart';
import '../../domain/enums/role.dart';
import '../home/home_screen.dart';

/// Dedicated Municipal Operations Command Center & Admin Hub for EcoRoute
class AdminDashboard extends StatelessWidget {
  const AdminDashboard({
    super.key,
    required this.repository,
    this.authService,
    this.wasteApiService,
  });

  final PickupRequestRepository repository;
  final AuthService? authService;
  final WasteApiService? wasteApiService;

  @override
  Widget build(BuildContext context) {
    return EcoRouteHomeScreen(
      repository: repository,
      authService: authService,
      wasteApiService: wasteApiService,
      enforcedRole: AppRole.admin,
    );
  }
}
