import 'package:colleezy/src/dashboard/dashboard.dart';
import 'package:colleezy/src/login/login.dart';
import 'package:colleezy/src/splash/splash_screen.dart';
import 'package:flutter/material.dart';
import 'theme/app_theme.dart';

// Global navigator key for navigation from anywhere
final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();

class ColleezyApp extends StatelessWidget {
  const ColleezyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      navigatorKey: navigatorKey,
      title: 'Colleezy',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.lightTheme,
      home: const SplashScreen(),
      onGenerateRoute: (settings) {
        switch (settings.name) {
          case '/login':
            return MaterialPageRoute(builder: (context) => const LoginScreen());
          case '/home':
          case '/dashboard':
            return MaterialPageRoute(builder: (context) => const DashboardScreen());
          default:
            return MaterialPageRoute(builder: (context) => const LoginScreen());
        }
      },
    );
  }
}