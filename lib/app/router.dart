import 'package:flutter/material.dart';

import '../core/pickup_request_repository.dart';
import '../features/home/home_screen.dart';
import '../features/request/order_page.dart';

class AppRouter {
  const AppRouter._();

  static const splash = '/splash';
  static const home = '/';
  static const signIn = '/auth';
  static const request = '/request';

  static Route<dynamic> onGenerateRoute(
    RouteSettings settings, {
    required PickupRequestRepository repository,
  }) {
    switch (settings.name) {
      case splash:
        return MaterialPageRoute(
          builder: (_) => EcoRouteSplashScreen(repository: repository),
        );
      case home:
        return MaterialPageRoute(
          builder: (_) => EcoRouteHomeScreen(repository: repository),
        );
      case request:
        return MaterialPageRoute(
          builder: (_) => OrderPage(
            onSubmitted: (req) async => repository.save(req),
          ),
        );
      default:
        return MaterialPageRoute(
          builder: (_) => EcoRouteHomeScreen(repository: repository),
        );
    }
  }
}
