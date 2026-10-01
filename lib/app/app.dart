import 'package:flutter/material.dart';

import '../core/pickup_request_repository.dart';
import '../features/home/home_screen.dart';
import 'theme/app_theme.dart';

class EcoRouteApp extends StatelessWidget {
  const EcoRouteApp({
    super.key,
    this.repository = const MemoryPickupRequestRepository(),
  });

  final PickupRequestRepository repository;

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'EcoRoute',
      debugShowCheckedModeBanner: false,
      theme: EcoRouteTheme.build(),
      home: EcoRouteSplashScreen(repository: repository),
    );
  }
}
