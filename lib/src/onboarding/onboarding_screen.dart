import 'package:flutter/material.dart';
import 'dart:math' as math;
import 'package:auto_size_text/auto_size_text.dart';
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
            top: -responsive.height(80),
            right: -responsive.width(40),
            child: Container(
              width: responsive.width(360),
              height: responsive.height(360),
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
            child: LayoutBuilder(builder: (context, constraints) {
              final maxW = constraints.maxWidth;
              final maxH = constraints.maxHeight;
              final cardAreaHeight = maxH * 0.38;
              final cardWidth = math.min(maxW * 0.75, 340.0);

              return SingleChildScrollView(
                physics: const BouncingScrollPhysics(),
                child: ConstrainedBox(
                  constraints: BoxConstraints(minHeight: maxH),
                  child: Padding(
                    padding: responsive.paddingSymmetric(horizontal: 24.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        SizedBox(height: math.max(responsive.spacing(36), maxH * 0.03)),

                        // Cards Section (responsive height)
                        SizedBox(
                          height: cardAreaHeight,
                          width: double.infinity,
                          child: Stack(
                            clipBehavior: Clip.none,
                            children: [
                              // Top card (partial, shifted)
                              Align(
                                alignment: Alignment.topRight,
                                child: FractionalTranslation(
                                  translation: Offset(0.16, -0.08),
                                  child: Transform.rotate(
                                    angle: -0.2,
                                    child: _BankCard(
                                      width: cardWidth * 0.9,
                                      showSymbols: false,
                                    ),
                                  ),
                                ),
                              ),
                              // Main focused card
                              Align(
                                alignment: Alignment.centerLeft,
                                child: FractionalTranslation(
                                  translation: Offset(-0.12, 0.06),
                                  child: Transform.rotate(
                                    angle: -0.2,
                                    child: _BankCard(
                                      width: cardWidth,
                                      showSymbols: true,
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),

                        // Content Section
                        SizedBox(height: responsive.spacing(18)),
                        AutoSizeText(
                          'Fund Management at\nYour Fingertips!',
                          maxLines: 2,
                          minFontSize: 18,
                          style: TextStyle(
                            fontSize: responsive.fontSize(32),
                            fontWeight: FontWeight.w700,
                            color: Colors.white,
                            height: 1.1,
                            letterSpacing: -0.5,
                            fontFamily: 'DM Sans',
                          ),
                        ),
                        SizedBox(height: responsive.spacing(12)),
                        AutoSizeText(
                          'Simplify group savings, manage collections,\nand stay organized — all in one place.',
                          maxLines: 3,
                          minFontSize: 12,
                          style: TextStyle(
                            fontSize: responsive.fontSize(16),
                            fontWeight: FontWeight.w400,
                            color: Colors.white.withOpacity(0.7),
                            height: 1.45,
                          ),
                        ),
                        SizedBox(height: responsive.spacing(36)),

                        // Spacer for content above bottom button
                        SizedBox(height: responsive.spacing(28)),
                      ],
                    ),
                  ),
                ),
              );
            }),
          ),
        ],
      ),
      bottomNavigationBar: SafeArea(
        minimum: EdgeInsets.only(bottom: responsive.spacing(3)),
        child: Padding(
          padding: responsive.paddingSymmetric(horizontal: 24.0),
          child: SizedBox(
            width: double.infinity,
            height: math.max(responsive.height(52), 48),
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
        ),
      ),
    );
  }
}

class _BankCard extends StatelessWidget {
  final double width;
  final bool showSymbols;

  const _BankCard({
    required this.width,
    required this.showSymbols,
  });

  @override
  Widget build(BuildContext context) {
    final height = width * 0.57;
    final padding = math.max(12.0, width * 0.06);
    final borderRadius = width * 0.07;
    return Container(
      width: width,
      height: height,
      padding: EdgeInsets.all(padding),
      decoration: BoxDecoration(
        color: const Color(0xFF4C7B5B),
        borderRadius: BorderRadius.circular(borderRadius),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.4),
            blurRadius: width * 0.12,
            offset: Offset(0, width * 0.05),
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
                  fontSize: math.max(12.0, width * 0.05),
                  fontWeight: FontWeight.w700,
                  letterSpacing: 0.5,
                  fontFamily: 'DM Sans',
                ),
              ),
              if (showSymbols)
                Padding(
                  padding: EdgeInsets.only(top: math.max(4.0, width * 0.02)),
                  child: Row(
                    children: [
                      Container(
                        width: math.max(10.0, width * 0.05),
                        height: math.max(10.0, width * 0.05),
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: Colors.white.withOpacity(0.4),
                        ),
                      ),
                      SizedBox(width: math.max(6.0, width * 0.02)),
                      Container(
                        width: math.max(10.0, width * 0.05),
                        height: math.max(10.0, width * 0.05),
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
                padding: EdgeInsets.only(bottom: math.max(8.0, width * 0.035)),
                child: Icon(
                  Icons.wifi,
                  color: Colors.white.withOpacity(0.3),
                  size: math.max(14.0, width * 0.06),
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
                  fontSize: math.max(11.0, width * 0.045),
                  fontWeight: FontWeight.w500,
                  letterSpacing: 0.5,
                ),
              ),
              SizedBox(height: math.max(6.0, width * 0.03)),
              Text(
                '1234 4356 8746 0008',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: math.max(12.0, width * 0.05),
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
