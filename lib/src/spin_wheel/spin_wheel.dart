import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import '../services/api_service.dart';

class SpinWheelScreen extends StatefulWidget {
  const SpinWheelScreen({super.key});

  @override
  State<SpinWheelScreen> createState() => _SpinWheelScreenState();
}

class _SpinWheelScreenState extends State<SpinWheelScreen>
    with SingleTickerProviderStateMixin {
  final ApiService _apiService = ApiService();
  late AnimationController _controller;
  late Animation<double> _rotationAnimation;
  int? _selectedGroupId;
  String? _selectedGroupName;
  bool _isSpinning = false;
  double _rotationAngle = 0.0;
  List<Map<String, dynamic>> _groups = [];
  List<Map<String, dynamic>> _members = [];
  int _totalMemberCount = 0;  // Total members including winners
  int _previousWinnerCount = 0;  // Number of previous winners
  bool _isLoadingGroups = true;
  bool _isLoadingMembers = false;

  // Wheel segments - will be populated with member indices
  List<int> _wheelValues = [];
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
    _loadGroups();
  }

  Future<void> _loadGroups() async {
    setState(() {
      _isLoadingGroups = true;
    });

    try {
      final groups = await _apiService.getGroups();
      if (mounted) {
        setState(() {
          _groups = groups;
          _isLoadingGroups = false;
        });
      }
    } catch (e) {
      print('Error loading groups: $e');
      if (mounted) {
        setState(() {
          _isLoadingGroups = false;
        });
      }
    }
  }

  Future<void> _loadMembers(int groupId) async {
    setState(() {
      _isLoadingMembers = true;
    });

    try {
      // Get all members and previous draws for this group
      final allMembers = await _apiService.getGroupMembers(groupId);
      final draws = await _apiService.getGroupDraws(groupId);
      
      // Get set of winner user IDs to exclude
      final winnerUserIds = draws
          .map((draw) => draw['winner_user_id'] as int?)
          .where((id) => id != null)
          .toSet();
      
      // Filter out members who have already won
      final eligibleMembers = allMembers
          .where((member) => !winnerUserIds.contains(member['user_id'] as int?))
          .toList();
      
      // Create wheel values based on eligible member count
      // Always create 12 segments for the wheel
      final memberCount = eligibleMembers.length;
      List<int> wheelValues = [];
      
      if (memberCount == 0) {
        // No eligible members - show placeholder numbers
        wheelValues = List.generate(12, (index) => index);
      } else if (memberCount <= 12) {
        // Use member indices directly, repeat if needed to fill 12 segments
        wheelValues = List.generate(12, (index) => index % memberCount);
      } else {
        // More than 12 members - distribute evenly across 12 segments
        // Each segment represents a range of members
        wheelValues = List.generate(12, (index) {
          // Map segment index to member index
          // This ensures all members have a chance to be selected
          return ((index * memberCount) / 12).floor();
        });
      }
      
      if (mounted) {
        setState(() {
          _members = eligibleMembers;
          _wheelValues = wheelValues;
          _totalMemberCount = allMembers.length;
          _previousWinnerCount = winnerUserIds.length;
          _isLoadingMembers = false;
        });
      }
    } catch (e) {
      print('Error loading members: $e');
      if (mounted) {
        setState(() {
          _isLoadingMembers = false;
        });
      }
    }
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

  Future<void> _showWinnerDialog(int winningSegmentIndex) async {
    if (_selectedGroupId == null || _members.isEmpty) {
      return;
    }

    // Get the winner from the wheel segment
    final winnerIndex = _wheelValues[winningSegmentIndex];
    if (winnerIndex >= _members.length) {
      // Handle case where index is out of bounds
      return;
    }

    final winner = _members[winnerIndex];
    final winnerUserId = winner['user_id'] as int;
    final winnerMemberNumber = winner['member_number'] as int? ?? (winnerIndex + 1);
    final winnerName = winner['user_name'] as String? ?? 
                      (winner['user_email'] as String? ?? 'Unknown');
    
    // Extract name from email if needed
    String displayName = winnerName;
    if (winnerName.contains('@')) {
      final emailParts = winnerName.split('@');
      if (emailParts.isNotEmpty) {
        displayName = emailParts[0].split('.').map((part) {
          if (part.isEmpty) return part;
          return part[0].toUpperCase() + part.substring(1).toLowerCase();
        }).join(' ');
      }
    }

    // Save the draw result
    bool drawSaved = false;
    try {
      final result = await _apiService.createDraw(
        groupId: _selectedGroupId!,
        winnerUserId: winnerUserId,
        drawType: 'spin_wheel',
      );
      drawSaved = result != null;
      if (drawSaved) {
        print('Draw saved successfully: $result');
      } else {
        print('Failed to save draw - result was null');
      }
    } catch (e) {
      print('Error saving draw result: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to save winner: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }

    if (!mounted) return;

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return Dialog(
          backgroundColor: const Color(0xFF171717),
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
                    color: Colors.white,
                    fontFamily: 'DM Sans',
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
                      '$winnerMemberNumber',
                      style: const TextStyle(
                        fontSize: 32,
                        fontWeight: FontWeight.w700,
                        color: Colors.white,
                        fontFamily: 'DM Sans',
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                Text(
                  '#$winnerMemberNumber - $displayName',
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFFD0CDC6),
                    fontFamily: 'DM Sans',
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 8),
                const Text(
                  'is the winner!',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w400,
                    color: Color(0xFFA5A5A5),
                    fontFamily: 'DM Sans',
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
                      fontFamily: 'DM Sans',
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
    if (_isSpinning || _selectedGroupId == null || _members.isEmpty) {
      if (_selectedGroupId == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Please select a group first'),
            backgroundColor: Colors.red,
          ),
        );
      } else if (_members.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('All members have already won! No eligible members left.'),
            backgroundColor: Colors.orange,
          ),
        );
      }
      return;
    }
    
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
      
      // Calculate and show winner
      final winningSegmentIndex = _getWinningSegment(finalAngle);
      _showWinnerDialog(winningSegmentIndex);
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
                    color: const Color(0xFF141414),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: _isLoadingGroups
                      ? const Padding(
                          padding: EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                          child: Center(
                            child: CircularProgressIndicator(
                              valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF2D7A4F)),
                            ),
                          ),
                        )
                      : DropdownButtonHideUnderline(
                    child: DropdownButton<String>(
                            value: _selectedGroupName,
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
                                color: Color(0xFFD0CDC6),
                                fontFamily: 'DM Sans',
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
                              fontFamily: 'DM Sans',
                      ),
                            dropdownColor: const Color(0xFF141414),
                            items: _groups.map((group) {
                              final groupName = group['name'] as String? ?? 'Unnamed Group';
                        return DropdownMenuItem<String>(
                                value: groupName,
                                child: Text(groupName),
                        );
                      }).toList(),
                      onChanged: (String? newValue) {
                              if (newValue != null) {
                                final selectedGroup = _groups.firstWhere(
                                  (g) => g['name'] == newValue,
                                );
                                final groupId = selectedGroup['id'] as int;
                        setState(() {
                                  _selectedGroupName = newValue;
                                  _selectedGroupId = groupId;
                                  _members = [];
                                  _wheelValues = [];
                                });
                                _loadMembers(groupId);
                              }
                            },
                          ),
                        ),
                ),
                if (_isLoadingMembers)
                  const Padding(
                    padding: EdgeInsets.all(16.0),
                    child: Center(
                      child: CircularProgressIndicator(
                        valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF2D7A4F)),
                    ),
                  ),
                ),
                // Show eligible members info
                if (_selectedGroupId != null && !_isLoadingMembers)
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                      decoration: BoxDecoration(
                        color: const Color(0xFF141414),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            _members.isEmpty ? Icons.warning_amber_rounded : Icons.people,
                            color: _members.isEmpty ? Colors.orange : const Color(0xFF2D7A4F),
                            size: 20,
                          ),
                          const SizedBox(width: 8),
                          Text(
                            _members.isEmpty
                                ? 'All $_totalMemberCount members have already won!'
                                : '${_members.length} eligible • $_previousWinnerCount won',
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w500,
                              color: _members.isEmpty ? Colors.orange : const Color(0xFFD0CDC6),
                              fontFamily: 'DM Sans',
                            ),
                          ),
                        ],
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
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      SizedBox(
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
                                      members: _members,
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
                            // Center decoration (no longer a button)
                            Container(
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
                          ],
                        ),
                      ),
                      const SizedBox(height: 32),
                      // Spin Button
                      SizedBox(
                        width: 200,
                        height: 56,
                        child: ElevatedButton(
                          onPressed: _isSpinning || _selectedGroupId == null || _members.isEmpty
                              ? null
                              : _spinWheel,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF2D7A4F),
                            foregroundColor: Colors.white,
                            disabledBackgroundColor: const Color(0xFF6B7280),
                            disabledForegroundColor: Colors.white54,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(16),
                            ),
                            elevation: 4,
                          ),
                          child: _isSpinning
                              ? const SizedBox(
                                  width: 24,
                                  height: 24,
                                  child: CircularProgressIndicator(
                                    valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                                    strokeWidth: 2,
                                  ),
                                )
                              : const Text(
                                  'SPIN',
                                  style: TextStyle(
                                    fontSize: 20,
                                    fontWeight: FontWeight.w700,
                                    fontFamily: 'DM Sans',
                                    letterSpacing: 2,
                                  ),
                                ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 40), // Space for bottom nav bar
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
  final List<Map<String, dynamic>> members;
  final Color lightGreen;
  final Color darkGreen;

  WheelPainter({
    required this.values,
    required this.members,
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

      // Draw text - show member number
      final textAngle = startAngle + segmentAngle / 2;
      final textRadius = radius * 0.7;
      final textX = center.dx + textRadius * math.cos(textAngle);
      final textY = center.dy + textRadius * math.sin(textAngle);

      // Get member number (from API) or fallback to index + 1
      String displayText;
      if (members.isNotEmpty && values[i] < members.length) {
        final member = members[values[i]];
        final memberNumber = member['member_number'] as int? ?? (values[i] + 1);
        displayText = '$memberNumber';
      } else {
        // No members or invalid index - show number
        displayText = '${values[i] + 1}';
      }

      final textPainter = TextPainter(
        text: TextSpan(
          text: displayText,
          style: const TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.w700,
            color: Color(0xFF1F2937),
            fontFamily: 'DM Sans',
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

