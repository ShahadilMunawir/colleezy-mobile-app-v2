import 'package:colleezy/src/dashboard/dashboard.dart';
import 'package:colleezy/src/login/login.dart';
import 'package:colleezy/src/services/auth_service.dart';
import 'package:colleezy/src/services/api_service.dart';
import 'package:colleezy/src/profile/profile_screen.dart';
import 'package:flutter/material.dart';
import 'theme/app_theme.dart';

class ColleezyApp extends StatelessWidget {
  const ColleezyApp({super.key});

  @override
  Widget build(BuildContext context) {
    final authService = AuthService();
    
    return MaterialApp(
      title: 'Colleezy',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.lightTheme,
      home: StreamBuilder(
        stream: authService.authStateChanges,
        builder: (context, snapshot) {
          // Show loading while checking auth state
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Scaffold(
              body: Center(
                child: CircularProgressIndicator(),
              ),
            );
          }
          
          // If user is signed in, check profile completion, otherwise login
          final user = snapshot.data;
          if (user != null) {
            return _AuthCheckWidget();
          } else {
            return const LoginScreen();
          }
        },
      ),
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

class _AuthCheckWidget extends StatefulWidget {
  @override
  State<_AuthCheckWidget> createState() => _AuthCheckWidgetState();
}

class _AuthCheckWidgetState extends State<_AuthCheckWidget> {
  final ApiService _apiService = ApiService();
  bool _isChecking = true;
  bool _isProfileComplete = false;

  @override
  void initState() {
    super.initState();
    _checkProfileCompletion();
  }

  Future<void> _checkProfileCompletion() async {
    // Wait a bit for backend to sync
    await Future.delayed(const Duration(milliseconds: 500));
    
    final isComplete = await _apiService.isProfileComplete();
    if (mounted) {
      setState(() {
        _isChecking = false;
        _isProfileComplete = isComplete;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isChecking) {
      return const Scaffold(
        body: Center(
          child: CircularProgressIndicator(),
        ),
      );
    }

    if (!_isProfileComplete) {
      return const ProfileScreen();
    }

    return const DashboardScreen();
  }
}