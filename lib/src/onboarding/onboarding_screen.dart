import 'package:flutter/material.dart';
import 'dart:math' as math;
import '../login/login.dart';
import '../../utils/responsive.dart';

class OnboardingScreen extends StatelessWidget {
  const OnboardingScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final responsive = Responsive(context);
    return Scaffold(
      backgroundColor: const Color(0xFF121212),
      body: Stack(
        children: [
          // Background Gradient
          Positioned(
            top: -responsive.height(100),
            right: -responsive.width(50),
            child: Container(
              width: responsive.width(400),
              height: responsive.height(400),
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: RadialGradient(
                  colors: [
                    const Color(0xFF2D7A4F).withOpacity(0.35),
                    const Color(0xFF121212).withOpacity(0.0),
                  ],
                ),
              ),
            ),
          ),
          
          SafeArea(
            child: Padding(
              padding: responsive.paddingSymmetric(horizontal: 24.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  SizedBox(height: responsive.spacing(60)),
                  // Cards Section
                  Expanded(
                    child: Center(
                      child: SizedBox(
                        height: responsive.height(350),
                        width: double.infinity,
                        child: Stack(
                          clipBehavior: Clip.none,
                          alignment: Alignment.center,
                          children: [
                            // Top Card (Partial)
                            Positioned(
                              top: responsive.spacing(20),
                              right: -responsive.width(40),
                              child: Transform.rotate(
                                angle: -0.2,
                                child: _BankCard(
                                  context: context,
                                  showSymbols: false,
                                ),
                              ),
                            ),
                            // Main Focused Card
                            Positioned(
                              top: responsive.spacing(140),
                              left: -responsive.width(10),
                              child: Transform.rotate(
                                angle: -0.2,
                                child: _BankCard(
                                  context: context,
                                  showSymbols: true,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),

                  // Content Section
                  Text(
                    'Fund Management at\nYour Fingertips!',
                    style: TextStyle(
                      fontSize: responsive.fontSize(32),
                      fontWeight: FontWeight.w700,
                      color: Colors.white,
                      height: 1.2,
                      letterSpacing: -0.5,
                      fontFamily: 'DM Sans',
                    ),
                  ),
                  SizedBox(height: responsive.spacing(16)),
                  Text(
                    'Simplify group savings, manage collections,\nand stay organized — all in one place.',
                    style: TextStyle(
                      fontSize: responsive.fontSize(16),
                      fontWeight: FontWeight.w400,
                      color: Colors.white.withOpacity(0.7),
                      height: 1.5,
                    ),
                  ),
                  SizedBox(height: responsive.spacing(48)),

                  // Button Section
                  SizedBox(
                    width: double.infinity,
                    height: responsive.height(56),
                    child: ElevatedButton(
                      onPressed: () {
                        Navigator.pushReplacement(
                          context,
                          MaterialPageRoute(builder: (context) => const LoginScreen()),
                        );
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF1B8044),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(responsive.radius(12)),
                        ),
                        elevation: 0,
                      ),
                      child: Text(
                        'Get Started',
                        style: TextStyle(
                          fontSize: responsive.fontSize(18),
                          fontWeight: FontWeight.w700,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ),
                  SizedBox(height: responsive.spacing(40)),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _BankCard extends StatelessWidget {
  final BuildContext context;
  final bool showSymbols;

  const _BankCard({
    required this.context,
    required this.showSymbols,
  });

  @override
  Widget build(BuildContext context) {
    final responsive = Responsive(context);
    return Container(
      width: responsive.width(280),
      height: responsive.height(160),
      padding: responsive.paddingAll(20),
      decoration: BoxDecoration(
        color: const Color(0xFF4C7B5B),
        borderRadius: BorderRadius.circular(responsive.radius(20)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.4),
            blurRadius: responsive.spacing(30),
            offset: Offset(0, responsive.spacing(15)),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'BANK G+',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: responsive.fontSize(14),
                  fontWeight: FontWeight.w700,
                  letterSpacing: 0.5,
                  fontFamily: 'DM Sans',
                ),
              ),
              if (showSymbols)
                Padding(
                  padding: EdgeInsets.only(top: responsive.spacing(4.0)),
                  child: Row(
                    children: [
                       Container(
                        width: responsive.width(14),
                        height: responsive.height(14),
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: Colors.white.withOpacity(0.4),
                        ),
                      ),
                      SizedBox(width: responsive.spacing(2)),
                      Container(
                        width: responsive.width(14),
                        height: responsive.height(14),
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: Colors.white.withOpacity(0.2),
                        ),
                      ),
                    ],
                  ),
                ),
            ],
          ),
          
          if (showSymbols)
             Align(
              alignment: Alignment.centerRight,
              child: Padding(
                padding: EdgeInsets.only(bottom: responsive.spacing(12.0)),
                child: Icon(
                  Icons.wifi,
                  color: Colors.white.withOpacity(0.3),
                  size: responsive.width(20),
                ),
              ),
            ),

          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'XYZ XYZ XYZ',
                style: TextStyle(
                  color: Colors.white.withOpacity(0.8),
                  fontSize: responsive.fontSize(13),
                  fontWeight: FontWeight.w500,
                  letterSpacing: 0.5,
                ),
              ),
              SizedBox(height: responsive.spacing(4)),
              Text(
                '1234 4356 8746 0008',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: responsive.fontSize(14),
                  fontWeight: FontWeight.w600,
                  letterSpacing: 1.2,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
