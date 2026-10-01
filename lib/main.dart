import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'app/app.dart';
import 'core/pickup_request_repository.dart';

export 'package:ecoroute/app/app.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final preferences = await SharedPreferences.getInstance();
  runApp(
    EcoRouteApp(
      repository: SharedPreferencesPickupRequestRepository(preferences),
    ),
  );
}
