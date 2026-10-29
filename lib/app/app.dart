import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../core/pickup_request_repository.dart';
import '../core/services/auth_service.dart';
import '../core/services/theme_service.dart';
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
    return ListenableBuilder(
      listenable: ThemeService.instance,
      builder: (context, _) {
        final isDark = ThemeService.instance.isDarkMode;
        final statusBarColor = isDark ? const Color(0xFF192A1D) : const Color(0xFF2EAD65);
        final navBarColor = isDark ? const Color(0xFF111E14) : const Color(0xFF2EAD65);

        return AnnotatedRegion<SystemUiOverlayStyle>(
          value: SystemUiOverlayStyle(
            statusBarColor: statusBarColor,
            statusBarIconBrightness: Brightness.light,
            statusBarBrightness: Brightness.dark,
            systemNavigationBarColor: navBarColor,
            systemNavigationBarIconBrightness: Brightness.light,
            systemNavigationBarDividerColor: Colors.transparent,
          ),
          child: MaterialApp(
            title: 'EcoRoute',
            debugShowCheckedModeBanner: false,
            theme: EcoRouteTheme.build(brightness: Brightness.light),
            darkTheme: EcoRouteTheme.buildDark(),
            themeMode: ThemeService.instance.themeMode,
            home: EcoRouteSplashScreen(
              repository: repository,
              authService: authService,
              wasteApiService: wasteApiService,
            ),
          ),
        );
      },
    );
  }
}
