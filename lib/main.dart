import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'app/app.dart';
import 'core/pickup_request_repository.dart';
import 'core/services/auth_service.dart';
import 'core/services/waste_api_service.dart';

export 'package:ecoroute/app/app.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final preferences = await SharedPreferences.getInstance();
  final repository = SharedPreferencesPickupRequestRepository(preferences);
  // Auto-seed realistic municipal demo data if storage is fresh
  await repository.seedDemoData();
  final authService = AuthService(preferences);
  final wasteApiService = WasteApiService();

  runApp(
    EcoRouteApp(
      repository: repository,
      authService: authService,
      wasteApiService: wasteApiService,
    ),
  );
}
