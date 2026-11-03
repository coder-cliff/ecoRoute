import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'models/user_model.dart';
import 'providers/auth_provider.dart';
import 'providers/waste_request_provider.dart';
import 'providers/notification_provider.dart';
import 'screens/admin/admin_dashboard_screen.dart';
import 'screens/citizen/citizen_home_screen.dart';
import 'screens/rider/rider_dashboard_screen.dart';
import 'theme/app_theme.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  final authProvider = AuthProvider();
  final requestProvider = WasteRequestProvider();
  final notificationProvider = NotificationProvider();
  requestProvider.setNotificationProvider(notificationProvider);

  // Load persistent data from SharedPreferences (Roadmap Week 7)
  await authProvider.init();
  await requestProvider.loadRequests();

  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider.value(value: authProvider),
        ChangeNotifierProvider.value(value: requestProvider),
        ChangeNotifierProvider.value(value: notificationProvider),
      ],
      child: const EcoRouteApp(),
    ),
  );
}

class EcoRouteApp extends StatelessWidget {
  const EcoRouteApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'EcoRoute - On-Demand Waste Pickup',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.lightTheme,
      home: const RoleBasedMainRouter(),
    );
  }
}

/// Routes user to appropriate screen based on current logged in role
class RoleBasedMainRouter extends StatelessWidget {
  const RoleBasedMainRouter({super.key});

  @override
  Widget build(BuildContext context) {
    final auth = Provider.of<AuthProvider>(context);

    if (auth.isLoading) {
      return const Scaffold(
        body: Center(
          child: CircularProgressIndicator(color: AppTheme.primaryGreen),
        ),
      );
    }

    switch (auth.currentRole) {
      case UserRole.citizen:
        return const CitizenHomeScreen();
      case UserRole.rider:
        return const RiderDashboardScreen();
      case UserRole.admin:
        return const AdminDashboardScreen();
    }
  }
}
