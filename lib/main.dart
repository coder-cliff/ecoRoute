import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter/foundation.dart' show defaultTargetPlatform, kIsWeb, kDebugMode;
import 'package:shared_preferences/shared_preferences.dart';

import 'app/app.dart';
import 'core/pickup_request_repository.dart';
import 'core/services/auth_service.dart';
import 'core/services/language_service.dart';
import 'core/services/theme_service.dart';
import 'core/services/waste_api_service.dart';
import 'firebase_options.dart';

export 'package:ecoroute/app/app.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  SystemChrome.setSystemUIOverlayStyle(
    const SystemUiOverlayStyle(
      statusBarColor: Color(0xFF2EAD65),
      statusBarIconBrightness: Brightness.light,
      statusBarBrightness: Brightness.dark,
      systemNavigationBarColor: Color(0xFF2EAD65),
      systemNavigationBarIconBrightness: Brightness.light,
      systemNavigationBarDividerColor: Colors.transparent,
    ),
  );
  final preferences = await SharedPreferences.getInstance();
  FirebaseAuth? firebaseAuth;
  FirebaseFirestore? firestore;
  if (kIsWeb || defaultTargetPlatform == TargetPlatform.android) {
    try {
      await Firebase.initializeApp(
        options: DefaultFirebaseOptions.currentPlatform,
      );
      firebaseAuth = FirebaseAuth.instance;
      firestore = FirebaseFirestore.instance;
    } catch (e) {
      debugPrint('Firebase initialization notice: $e');
    }
  }

  final localRepository = SharedPreferencesPickupRequestRepository(preferences);
  final repository = firestore == null || firebaseAuth == null
      ? localRepository
      : FirebasePickupRequestRepository(
          localRepository,
          firestore: firestore,
          firebaseAuth: firebaseAuth,
        );
  // Restore user saved language preference on startup
  await LanguageService.instance.init(preferences);
  // Restore user saved theme mode on startup
  await ThemeService.instance.init(preferences);

  // Auto-seed realistic municipal demo data only in debug mode
  if (kDebugMode) {
    await repository.seedDemoData();
  }
  final authService = AuthService(
    preferences,
    firebaseAuth: firebaseAuth,
    firestore: firestore,
  );
  final wasteApiService = WasteApiService();

  runApp(
    EcoRouteApp(
      repository: repository,
      authService: authService,
      wasteApiService: wasteApiService,
    ),
  );
}
