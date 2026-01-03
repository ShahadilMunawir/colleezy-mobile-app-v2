import 'package:colleezy/src/dashboard/dashboard.dart';
import 'package:colleezy/src/login/login.dart';
import 'package:flutter/material.dart';
import 'theme/app_theme.dart';

class ColleezyApp extends StatelessWidget {
  const ColleezyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Colleezy',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.lightTheme,
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