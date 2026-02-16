import 'package:flutter/material.dart';
import 'dart:math' as math;
import 'package:auto_size_text/auto_size_text.dart';
import '../spin_wheel/spin_wheel.dart';
import '../lottery/lottery_screen.dart';
import '../../utils/responsive.dart';

class DrawSelectionScreen extends StatelessWidget {
  const DrawSelectionScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final responsive = Responsive(context);
    return Scaffold(
      backgroundColor: const Color(0xFF141414),
      body: SafeArea(
        child: LayoutBuilder(builder: (context, constraints) {
          final maxW = constraints.maxWidth;
          final maxH = constraints.maxHeight;
          final headerH = (maxH * 0.10).clamp(56.0, 100.0);
          final canvasH = (maxH * 0.50).clamp(180.0, maxH * 0.65);
          final buttonAreaH = (maxH * 0.25).clamp(120.0, maxH * 0.35);
          final horizontalPad = math.max(16.0, maxW * 0.05);
          final bottomNavReserve = MediaQuery.of(context).padding.bottom + responsive.height(16);

          return Column(
            children: [
              // Header
              SizedBox(
                height: headerH,
                width: double.infinity,
                child: Padding(
                  padding: EdgeInsets.fromLTRB(horizontalPad, headerH * 0.12, horizontalPad, headerH * 0.12),
                  child: AutoSizeText(
                    'Draw Selection',
                    maxLines: 1,
                    minFontSize: 18,
                    style: TextStyle(
                      fontSize: responsive.fontSize(24),
                      fontWeight: FontWeight.w700,
                      color: const Color(0xFFEFEEEC),
                    ),
                  ),
                ),
              ),

              // Illustration / Canvas
              SizedBox(
                height: canvasH,
                width: double.infinity,
                child: Center(
                  child: _buildStopwatchIllustration(canvasH),
                ),
              ),

              // Middle Section with Buttons
              SizedBox(
                height: buttonAreaH,
                child: Padding(
                  padding: EdgeInsets.symmetric(horizontal: horizontalPad, vertical: buttonAreaH * 0.12),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      _buildActionButton(
                        context: context,
                        label: 'Manual Draw',
                        onTap: () {
                          Navigator.of(context).push(
                            MaterialPageRoute(
                              builder: (context) => const LotteryScreen(),
                            ),
                          );
                        },
                      ),
                      SizedBox(height: responsive.spacing(12)),
                      _buildActionButton(
                        context: context,
                        label: 'Spin the Wheel',
                        onTap: () {
                          Navigator.of(context).push(
                            MaterialPageRoute(
                              builder: (context) => const SpinWheelScreen(),
                            ),
                          );
                        },
                      ),
                    ],
                  ),
                ),
              ),

              // Reserve space for bottom nav so content isn't blocked
              SizedBox(height: bottomNavReserve),
            ],
          );
        }),
      ),
    );
  }

  Widget _buildStopwatchIllustration(double height) {
    return Stack(
      children: [
        Center(
          child: Image.asset(
            'assets/png/draw.png',
            width: double.infinity,
            height: height,
            fit: BoxFit.contain,
          ),
        ),
        Container(
          width: double.infinity,
          height: height,
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [
                const Color(0xFF141414).withOpacity(0.0),
                const Color(0xFF141414).withOpacity(0.3),
                const Color(0xFF141414).withOpacity(0.6),
                const Color(0xFF141414),
              ],
              stops: const [0.0, 0.3, 0.7, 1.0],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildActionButton({
    required BuildContext context,
    required String label,
    required VoidCallback onTap,
  }) {
    final responsive = Responsive(context);
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: double.infinity,
        padding: responsive.paddingSymmetric(horizontal: 24, vertical: 12),
        decoration: BoxDecoration(
          color: const Color(0xFF2D7A4F),
          borderRadius: BorderRadius.circular(responsive.radius(16)),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              label,
              style: TextStyle(
                fontSize: responsive.fontSize(18),
                fontWeight: FontWeight.w600,
                color: Colors.white,
                fontFamily: 'DM Sans',
              ),
            ),
            Icon(
              Icons.arrow_forward,
              color: Colors.white,
              size: responsive.width(24),
            ),
          ],
        ),
      ),
    );
  }
}

