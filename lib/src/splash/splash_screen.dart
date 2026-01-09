import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import '../services/auth_service.dart';
import '../services/api_service.dart';
import '../login/login.dart';
import '../dashboard/dashboard.dart';
import '../profile/profile_screen.dart';
import '../onboarding/onboarding_screen.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with TickerProviderStateMixin {
  late AnimationController _logoController;
  
  late Animation<double> _logoFadeAnimation;
  
  final AuthService _authService = AuthService();
  final ApiService _apiService = ApiService();

  @override
  void initState() {
    super.initState();
    
    // Logo animation controller
    _logoController = AnimationController(
      duration: const Duration(milliseconds: 1200),
      vsync: this,
    );

    // Logo animations
    _logoFadeAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _logoController,
      curve: const Interval(0.0, 0.6, curve: Curves.easeOut),
    ));

    // Start animations
    _logoController.forward();

    // Navigate after animation and initialization
    _initializeApp();
  }

  Future<void> _initializeApp() async {
    // Wait for initial animation
    await Future.delayed(const Duration(milliseconds: 1500));

    if (!mounted) return;

    // Check authentication state
    final user = _authService.currentUser;
    
    if (user != null) {
      // User is logged in, check profile completion
      final isProfileComplete = await _apiService.isProfileComplete();
      
      if (!mounted) return;
      
      // Add a small delay for smooth transition
      await Future.delayed(const Duration(milliseconds: 200));
      
      if (!mounted) return;
      
      if (isProfileComplete) {
        Navigator.pushReplacement(
          context,
          PageRouteBuilder(
            pageBuilder: (context, animation, secondaryAnimation) => const DashboardScreen(),
            transitionsBuilder: (context, animation, secondaryAnimation, child) {
              return FadeTransition(opacity: animation, child: child);
            },
            transitionDuration: const Duration(milliseconds: 400),
          ),
        );
      } else {
        Navigator.pushReplacement(
          context,
          PageRouteBuilder(
            pageBuilder: (context, animation, secondaryAnimation) => const ProfileScreen(),
            transitionsBuilder: (context, animation, secondaryAnimation, child) {
              return FadeTransition(opacity: animation, child: child);
            },
            transitionDuration: const Duration(milliseconds: 400),
          ),
        );
      }
    } else {
      // User is not logged in
      await Future.delayed(const Duration(milliseconds: 200));
      
      if (!mounted) return;
      
      Navigator.pushReplacement(
        context,
        PageRouteBuilder(
          pageBuilder: (context, animation, secondaryAnimation) => const OnboardingScreen(),
          transitionsBuilder: (context, animation, secondaryAnimation, child) {
            return FadeTransition(opacity: animation, child: child);
          },
          transitionDuration: const Duration(milliseconds: 400),
          ),
        );
      }
    }
  
  @override
  void dispose() {
    _logoController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Logo with animations
            AnimatedBuilder(
              animation: _logoController,
              builder: (context, child) {
                return FadeTransition(
                  opacity: _logoFadeAnimation,
                  child: SizedBox(
                    width: 140,
                    height: 140,
                    child: SvgPicture.asset(
                      'assets/svg/logo.svg',                    
                    ),
                  ),
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}
