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
        final statusBarColor = isDark ? const Color(0xFF12281B) : const Color(0xFF72B08D);
        final navBarColor = isDark ? const Color(0xFF12281B) : const Color(0xFF72B08D);

        return AnnotatedRegion<SystemUiOverlayStyle>(
          value: SystemUiOverlayStyle(
            statusBarColor: statusBarColor,
            statusBarIconBrightness: isDark ? Brightness.light : Brightness.dark,
            statusBarBrightness: isDark ? Brightness.dark : Brightness.light,
            systemNavigationBarColor: navBarColor,
            systemNavigationBarIconBrightness: isDark ? Brightness.light : Brightness.dark,
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
