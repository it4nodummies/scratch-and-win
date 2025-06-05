import 'package:flutter/material.dart';
import '../features/splash/splash_screen.dart';
import '../features/auth/auth_screen.dart';
import '../features/operator/operator_screen.dart';
import '../features/scratch_card/scratch_card_screen.dart';
import '../features/settings/settings_screen.dart';

class AppRoutes {
  // Route names
  static const String splash = '/';
  static const String auth = '/auth';
  static const String operator = '/operator';
  static const String scratchCard = '/scratch-card';
  static const String settings = '/settings';

  // Route generator
  static Route<dynamic> onGenerateRoute(RouteSettings routeSettings) {
    switch (routeSettings.name) {
      case AppRoutes.splash:
        return MaterialPageRoute(
          builder: (_) => const SplashScreen(),
        );
      case AppRoutes.auth:
        return MaterialPageRoute(
          builder: (_) => const AuthScreen(),
        );
      case AppRoutes.operator:
        return MaterialPageRoute(
          builder: (_) => const OperatorScreen(),
        );
      case AppRoutes.scratchCard:
        final int attemptsRemaining = routeSettings.arguments as int? ?? 1;
        return MaterialPageRoute(
          builder: (_) => ScratchCardScreen(attemptsRemaining: attemptsRemaining),
        );
      case AppRoutes.settings:
        return MaterialPageRoute(
          builder: (_) => const SettingsScreen(),
        );
      default:
        return MaterialPageRoute(
          builder: (_) => Scaffold(
            body: Center(
              child: Text('No route defined for ${routeSettings.name}'),
            ),
          ),
        );
    }
  }
}
