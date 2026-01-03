import 'package:flutter/material.dart';
import '../spin_wheel/spin_wheel.dart';
import '../lottery/lottery_screen.dart';

class DrawSelectionScreen extends StatelessWidget {
  const DrawSelectionScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF141414),
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              flex: 2,
              child: SizedBox(
                width: double.infinity,
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    _buildStopwatchIllustration(),
                  ],
                ),
              ),
            ),
            // Middle Section with Buttons
            Expanded(
              flex: 1,
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    _buildActionButton(
                      label: 'Manual Draw',
                      onTap: () {
                        Navigator.of(context).push(
                          MaterialPageRoute(
                            builder: (context) => const LotteryScreen(),
                          ),  
                        );
                      },
                    ),
                    const SizedBox(height: 16),
                    _buildActionButton(
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
            // Bottom spacing for navigation bar
            const SizedBox(height: 100),
          ],
        ),
      ),
    );
  }

  Widget _buildStopwatchIllustration() {
    return Stack(
      children: [
        Image.asset(
          'assets/png/draw.png',
          width: double.infinity,
          height: double.infinity,
          fit: BoxFit.contain,
        ),
        Container(
          width: double.infinity,
          height: double.infinity,
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
    required String label,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 18),
        decoration: BoxDecoration(
          color: const Color(0xFF2D7A4F),
          borderRadius: BorderRadius.circular(16),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              label,
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w600,
                color: Colors.white,
                fontFamily: 'DM Sans',
              ),
            ),
            const Icon(
              Icons.arrow_forward,
              color: Colors.white,
              size: 24,
            ),
          ],
        ),
      ),
    );
  }
}

