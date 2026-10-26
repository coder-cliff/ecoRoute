import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

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
    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: const SystemUiOverlayStyle(
        statusBarColor: Color(0xFF2EAD65),
        statusBarIconBrightness: Brightness.light,
        statusBarBrightness: Brightness.dark,
        systemNavigationBarColor: Color(0xFF2EAD65),
        systemNavigationBarIconBrightness: Brightness.light,
        systemNavigationBarDividerColor: Colors.transparent,
      ),
      child: MaterialApp(
        title: 'EcoRoute',
        debugShowCheckedModeBanner: false,
        theme: EcoRouteTheme.build(),
        home: EcoRouteSplashScreen(
          repository: repository,
          authService: authService,
          wasteApiService: wasteApiService,
        ),
      ),
    );
  }
}
