import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

class SpinWheelScreen extends StatefulWidget {
  const SpinWheelScreen({super.key});

  @override
  State<SpinWheelScreen> createState() => _SpinWheelScreenState();
}

class _SpinWheelScreenState extends State<SpinWheelScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _rotationAnimation;
  String? _selectedGroup;
  bool _isSpinning = false;
  double _rotationAngle = 0.0;

  // Dummy group values
  final List<String> _dummyGroups = [
    'Group 1',
    'Group 2',
    'Group 3',
    'Family Savings',
    'Vacation Fund',
    'Emergency Fund',
    'Wedding Planning',
    'Home Renovation',
  ];

  // Wheel segments with values
  final List<int> _wheelValues = [10, 20, 30, 40, 50, 60, 70, 80, 100, 200, 300, 400];
  final Color _lightGreen = const Color(0xFF8BC34A); // Lime green
  final Color _darkGreen = const Color(0xFF2E7D32); // Forest green

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 3),
    );
    _rotationAnimation = Tween<double>(
      begin: 0,
      end: 0,
    ).animate(CurvedAnimation(
      parent: _controller,
      curve: Curves.decelerate,
    ));
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  int _getWinningSegment(double rotationAngle) {
    // Pointer is fixed at the top (-π/2), pointing downward
    // Each segment has an angle of 2π/12 = π/6
    // Segment i starts at: i * segmentAngle - π/2
    // The text is placed at the center: startAngle + segmentAngle/2
    
    final segmentAngle = (2 * math.pi) / _wheelValues.length;
    final normalizedAngle = rotationAngle % (2 * math.pi);
    
    // The pointer is at -π/2 (top)
    // After rotation, we need to find which segment is at the pointer
    // Check each segment to see if it contains the pointer position
    
    // The pointer is at angle -π/2
    // After rotation, segment i's boundaries are:
    // Start: (i * segmentAngle - π/2 + normalizedAngle) mod 2π
    // End: ((i+1) * segmentAngle - π/2 + normalizedAngle) mod 2π
    
    // We need to find i such that the pointer (-π/2) is between start and end
    // But we need to handle wrap-around
    
    // Convert pointer to 0-2π range for easier comparison
    final pointerAngle = (3 * math.pi / 2) % (2 * math.pi); // -π/2 in 0-2π range
    
    // Check each segment
    for (int i = 0; i < _wheelValues.length; i++) {
      var segmentStart = (i * segmentAngle - math.pi / 2 + normalizedAngle) % (2 * math.pi);
      if (segmentStart < 0) segmentStart += 2 * math.pi;
      
      var segmentEnd = ((i + 1) * segmentAngle - math.pi / 2 + normalizedAngle) % (2 * math.pi);
      if (segmentEnd < 0) segmentEnd += 2 * math.pi;
      
      // Check if pointer is in this segment
      bool containsPointer;
      if (segmentStart < segmentEnd) {
        // Normal case: no wrap-around
        containsPointer = pointerAngle >= segmentStart && pointerAngle < segmentEnd;
      } else {
        // Wrap-around case: segment crosses 0
        containsPointer = pointerAngle >= segmentStart || pointerAngle < segmentEnd;
      }
      
      if (containsPointer) {
        return i;
      }
    }
    
    // Fallback (shouldn't happen, but return 0 if it does)
    return 0;
  }

  void _showWinnerDialog(int winningNumber) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return Dialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          child: Container(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text(
                  'Congratulations!',
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.w700,
                    color: Color(0xFF1F2937),
                  ),
                ),
                const SizedBox(height: 16),
                Container(
                  width: 80,
                  height: 80,
                  decoration: BoxDecoration(
                    color: const Color(0xFF2D7A4F),
                    shape: BoxShape.circle,
                  ),
                  child: Center(
                    child: Text(
                      winningNumber.toString(),
                      style: const TextStyle(
                        fontSize: 32,
                        fontWeight: FontWeight.w700,
                        color: Colors.white,
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                const Text(
                  'You won!',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF6B7280),
                  ),
                ),
                const SizedBox(height: 24),
                ElevatedButton(
                  onPressed: () {
                    Navigator.of(context).pop();
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF2D7A4F),
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 32,
                      vertical: 12,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: const Text(
                    'OK',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  void _spinWheel() {
    if (_isSpinning) return;
    
    // Random rotation: 5-10 full rotations + random angle
    final random = math.Random();
    final fullRotations = 5 + random.nextInt(6); // 5 to 10 rotations
    final additionalAngle = random.nextDouble() * 2 * math.pi;
    final totalRotation = (fullRotations * 2 * math.pi) + additionalAngle;
    final newEndAngle = _rotationAngle + totalRotation;

    // Update the rotation animation
    setState(() {
      _isSpinning = true;
      _rotationAnimation = Tween<double>(
        begin: _rotationAngle,
        end: newEndAngle,
      ).animate(CurvedAnimation(
        parent: _controller,
        curve: Curves.decelerate,
      ));
    });

    // Reset and start animation
    _controller.reset();
    _controller.forward().then((_) {
      final finalAngle = newEndAngle % (2 * math.pi);
      setState(() {
        _rotationAngle = finalAngle;
        _isSpinning = false;
      });
      
      // Calculate and show winning number
      final winningSegmentIndex = _getWinningSegment(finalAngle);
      final winningNumber = _wheelValues[winningSegmentIndex];
      _showWinnerDialog(winningNumber);
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF171717),
      body: Stack(
        children: [
          SafeArea(
            child: Column(
              children: [
                // Header
                Container(
                  width: double.infinity,
                  decoration: const BoxDecoration(
                    color: Color(0xFF141414),
                    borderRadius: BorderRadius.only(
                      bottomLeft: Radius.circular(24),
                      bottomRight: Radius.circular(24),
                    ),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(0, 16, 20, 20),
                    child: Row(
                      children: [
                        IconButton(
                          padding: EdgeInsets.zero,
                          icon: SvgPicture.asset(
                            'assets/svg/back.svg',
                            width: 32,
                            height: 32,
                            colorFilter: const ColorFilter.mode(
                              Colors.white,
                              BlendMode.srcIn,
                            ),
                          ),
                          onPressed: () => Navigator.of(context).pop(),
                        ),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                'Spin the Wheel',
                                style: TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.w600,
                                  color: Color(0xFFEFEEEC),
                                  fontFamily: 'DM Sans',
                                ),
                              ),
                              
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                // Select Group Dropdown
                Container(
                  margin: const EdgeInsets.symmetric(horizontal: 16),
                  decoration: BoxDecoration(
                    color: Color(0xFF141414),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: DropdownButtonHideUnderline(
                    child: DropdownButton<String>(
                      value: _selectedGroup,
                      isExpanded: true,
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 14,
                      ),
                      hint: const Text(
                        'Select Group',
                        style: TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w400,
                          color: Color(0xFFD0CDC6)
                        ),
                      ),
                      icon: const Icon(
                        Icons.keyboard_arrow_down,
                        color: Color(0xFF6B7280),
                        size: 24,
                      ),
                      style: const TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w400,
                        color: Color(0xFFD0CDC6),
                      ),
                      items: _dummyGroups.map((String group) {
                        return DropdownMenuItem<String>(
                          value: group,
                          child: Text(group),
                        );
                      }).toList(),
                      onChanged: (String? newValue) {
                        setState(() {
                          _selectedGroup = newValue;
                        });
                      },
                    ),
                  ),
                ),
                const SizedBox(height: 32),
                // Spin the Wheel Title
                const Text(
                  'Spin the Wheel',
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.w700,
                    color: Color(0xFFD0CDC6),
                  ),
                ),
                const SizedBox(height: 40),
                // Wheel Container
                Expanded(
                  child: Center(
                    child: SizedBox(
                      width: 320,
                      height: 320,
                      child: Stack(
                        alignment: Alignment.center,
                        children: [
                          // Wheel
                          AnimatedBuilder(
                            animation: _rotationAnimation,
                            builder: (context, child) {
                              return Transform.rotate(
                                angle: _rotationAnimation.value,
                                child: CustomPaint(
                                  size: const Size(320, 320),
                                  painter: WheelPainter(
                                    values: _wheelValues,
                                    lightGreen: _lightGreen,
                                    darkGreen: _darkGreen,
                                  ),
                                ),
                              );
                            },
                          ),
                          // Pointer at top
                          Positioned(
                            top: 0,
                            child: CustomPaint(
                              size: const Size(40, 30),
                              painter: PointerPainter(),
                            ),
                          ),
                          // Spin button in center
                          GestureDetector(
                            onTap: _spinWheel,
                            child: Container(
                              width: 60,
                              height: 60,
                              decoration: BoxDecoration(
                                color: const Color(0xFF374151),
                                shape: BoxShape.circle,
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.black.withOpacity(0.2),
                                    blurRadius: 8,
                                    offset: const Offset(0, 2),
                                  ),
                                ],
                              ),
                              child: const Icon(
                                Icons.star,
                                color: Colors.white,
                                size: 28,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 100), // Space for bottom nav bar
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// Custom painter for the wheel
class WheelPainter extends CustomPainter {
  final List<int> values;
  final Color lightGreen;
  final Color darkGreen;

  WheelPainter({
    required this.values,
    required this.lightGreen,
    required this.darkGreen,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width / 2;
    final segmentAngle = (2 * math.pi) / values.length;

    // Draw wheel segments
    for (int i = 0; i < values.length; i++) {
      final startAngle = i * segmentAngle - math.pi / 2;

      // Alternate colors
      final color = i % 2 == 0 ? lightGreen : darkGreen;

      // Draw segment
      final path = Path()
        ..moveTo(center.dx, center.dy)
        ..lineTo(
          center.dx + radius * math.cos(startAngle),
          center.dy + radius * math.sin(startAngle),
        )
        ..arcTo(
          Rect.fromCircle(center: center, radius: radius),
          startAngle,
          segmentAngle,
          false,
        )
        ..close();

      canvas.drawPath(
        path,
        Paint()
          ..color = color
          ..style = PaintingStyle.fill,
      );

      // Draw white border between segments
      canvas.drawLine(
        Offset(
          center.dx + radius * math.cos(startAngle),
          center.dy + radius * math.sin(startAngle),
        ),
        center,
        Paint()
          ..color = Colors.white
          ..strokeWidth = 2
          ..style = PaintingStyle.stroke,
      );

      // Draw text
      final textAngle = startAngle + segmentAngle / 2;
      final textRadius = radius * 0.7;
      final textX = center.dx + textRadius * math.cos(textAngle);
      final textY = center.dy + textRadius * math.sin(textAngle);

      final textPainter = TextPainter(
        text: TextSpan(
          text: values[i].toString(),
          style: const TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.w700,
            color: Color(0xFF1F2937),
          ),
        ),
        textDirection: TextDirection.ltr,
      );
      textPainter.layout();
      textPainter.paint(
        canvas,
        Offset(
          textX - textPainter.width / 2,
          textY - textPainter.height / 2,
        ),
      );
    }

    // Draw outer circle border
    canvas.drawCircle(
      center,
      radius,
      Paint()
        ..color = Colors.white
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2,
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

// Custom painter for the pointer
class PointerPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final path = Path()
      ..moveTo(size.width / 2, 0)
      ..lineTo(0, size.height)
      ..lineTo(size.width, size.height)
      ..close();

    canvas.drawPath(
      path,
      Paint()
        ..color = const Color(0xFF374151)
        ..style = PaintingStyle.fill,
    );

    // White top edge
    canvas.drawLine(
      Offset(0, size.height),
      Offset(size.width, size.height),
      Paint()
        ..color = Colors.white
        ..strokeWidth = 2
        ..style = PaintingStyle.stroke,
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

