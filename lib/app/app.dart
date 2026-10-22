import 'package:flutter/material.dart';

import '../core/pickup_request_repository.dart';
import '../core/services/auth_service.dart';
import '../core/services/waste_api_service.dart';
import '../features/home/home_screen.dart';
import 'theme/app_theme.dart';

class EcoRouteApp extends StatelessWidget {
  const EcoRouteApp({
    super.key,
    this.repository = const MemoryPickupRequestRepository(),
    this.authService,
    this.wasteApiService,
  });

  final PickupRequestRepository repository;
  final AuthService? authService;
  final WasteApiService? wasteApiService;

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'EcoRoute',
      debugShowCheckedModeBanner: false,
      theme: EcoRouteTheme.build(),
      home: EcoRouteSplashScreen(
        repository: repository,
        authService: authService,
        wasteApiService: wasteApiService,
      ),
    );
  }
}
