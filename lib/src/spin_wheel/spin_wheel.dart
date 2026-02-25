import 'dart:async';
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
    with TickerProviderStateMixin {
  final ApiService _apiService = ApiService();
  AnimationController? _controller;
  AnimationController? _shuffleController;
  Animation<double>? _rotationAnimation;
  Animation<double>? _shuffleRotationAnimation;
  bool _isShuffleAnimating = false;
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
  bool _autoDraw = false;
  String? _autoDrawTime;
  Map<String, dynamic>? _selectedGroupData;
  DateTime? _selectedDrawDate; // Date for the draw, chosen before spinning
  bool _hasSpun = false; // New flag to prevent multiple spins
  Timer? _autoDrawTimer;
  final Map<int, DateTime> _lastAutoDrawRunPerGroup = {};

  // Wheel segments - will be populated with member indices
  List<int> _wheelValues = [];
  final Color _lightGreen = const Color(0xFF7FDE68); // Vibrant green
  final Color _darkGreen = const Color(0xFFFFD700); // Yellow/Gold

  @override
  void initState() {
    super.initState();
    // _controller and _shuffleController are created per-spin/per-shuffle with duration based on total rotation
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

  Future<void> _loadMembers(int groupId, {bool silent = false}) async {
    if (!silent) {
      setState(() {
        _isLoadingMembers = true;
      });
    }

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
      final memberCount = eligibleMembers.length;
      List<int> wheelValues = [];

      if (memberCount == 0) {
        // No eligible members - show placeholder numbers
        wheelValues = List.generate(12, (index) => index);
      } else {
        // Create segments equal to the number of eligible members
        // Each segment represents one member
        wheelValues = List.generate(memberCount, (index) => index);
      }
      
      if (mounted) {
        setState(() {
          _members = eligibleMembers;
          _wheelValues = wheelValues;
          _totalMemberCount = allMembers.length;
          _previousWinnerCount = winnerUserIds.length;
          _isLoadingMembers = false;
          
          // Set auto draw settings from group data
          if (_selectedGroupData != null) {
            _autoDraw = _selectedGroupData!['auto_draw'] as bool? ?? false;
            _autoDrawTime = _selectedGroupData!['auto_draw_time'] as String?;
          }
          // Setup/refresh auto-draw checker for this group
          _setupAutoDrawChecker();
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
  
  void _setupAutoDrawChecker() {
    // Cancel any existing timer
    _autoDrawTimer?.cancel();
    _autoDrawTimer = null;

    if (_selectedGroupId == null) return;
    if (!_autoDraw) return;
    if (_autoDrawTime == null) return;

    // Immediate check and periodic checks every minute
    _checkAndRunAutoDraw();
    _autoDrawTimer = Timer.periodic(const Duration(minutes: 1), (_) {
      _checkAndRunAutoDraw();
    });
  }

  void _cancelAutoDrawChecker() {
    _autoDrawTimer?.cancel();
    _autoDrawTimer = null;
  }

  void _checkAndRunAutoDraw() {
    if (_selectedGroupId == null || !_autoDraw || _autoDrawTime == null) return;

    try {
      final parts = _autoDrawTime!.split(':');
      if (parts.length != 2) return;
      final hour = int.parse(parts[0]);
      final minute = int.parse(parts[1]);
      final now = DateTime.now();
      if (now.hour == hour && now.minute == minute) {
        // Check last run date for this group (avoid multiple runs in same day)
        final lastRun = _lastAutoDrawRunPerGroup[_selectedGroupId!];
        if (lastRun != null) {
          if (lastRun.year == now.year && lastRun.month == now.month && lastRun.day == now.day) {
            return; // already ran today
          }
        }

        // Trigger auto-draw (perform spin)
        if (!_isSpinning && _members.isNotEmpty) {
          // Allow spin even if _hasSpun is true (auto draw should override)
          setState(() {
            _hasSpun = false;
          });
          _spinWheel(isAutoDraw: true);
          // record last run
          _lastAutoDrawRunPerGroup[_selectedGroupId!] = now;
        }
      }
    } catch (e) {
      print('Error in auto-draw check: $e');
    }
  }

  @override
  void dispose() {
    _controller?.dispose();
    _shuffleController?.dispose();
    _cancelAutoDrawChecker();
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

  DateTime _getFirstDate() {
    if (_selectedGroupData == null) return DateTime.now();
    final startStr = _selectedGroupData!['starting_date'] as String?;
    if (startStr == null) return DateTime.now();
    final parts = startStr.split('-');
    if (parts.length != 3) return DateTime.now();
    return DateTime(
      int.parse(parts[0]),
      int.parse(parts[1]),
      int.parse(parts[2]),
    );
  }

  DateTime _getLastDate() {
    if (_selectedGroupData == null) return DateTime.now();
    final start = _getFirstDate();
    final duration = _selectedGroupData!['duration'] as int? ?? 12;
    final collectionPeriod = (_selectedGroupData!['collection_period'] as String? ?? 'monthly').toLowerCase();
    final frequencyInDays = _selectedGroupData!['frequency_in_days'] as num?;
    if (frequencyInDays != null) {
      return start.add(Duration(days: (duration * frequencyInDays.toDouble()).toInt()));
    }
    if (collectionPeriod == 'weekly') {
      return start.add(Duration(days: duration * 7));
    }
    return DateTime(start.year, start.month + duration, start.day);
  }

  String _getFrequencyLabel() {
    if (_selectedGroupData == null) return 'Monthly';
    final collectionPeriod = (_selectedGroupData!['collection_period'] as String? ?? 'monthly').toLowerCase();
    final frequencyInDays = _selectedGroupData!['frequency_in_days'] as num?;
    if (frequencyInDays != null) {
      if (frequencyInDays <= 1) return 'Daily';
      if (frequencyInDays <= 7) return 'Weekly';
      if (frequencyInDays <= 31) return 'Every ${frequencyInDays.toInt()} days';
      return 'Monthly';
    }
    return collectionPeriod == 'weekly' ? 'Weekly' : 'Monthly';
  }

  DateTime _computeDefaultDrawDate() {
    final now = DateTime.now();
    if (_selectedGroupData == null) return now;
    final first = _getFirstDate();
    final last = _getLastDate();
    if (now.isBefore(first)) return first;
    if (now.isAfter(last)) return last;
    return now;
  }

  Future<void> _selectDrawDate() async {
    if (_selectedGroupData == null) return;
    final first = _getFirstDate();
    final last = _getLastDate();
    final picked = await showDatePicker(
      context: context,
      initialDate: _selectedDrawDate ?? _computeDefaultDrawDate(),
      firstDate: first,
      lastDate: last,
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: const ColorScheme.dark(
              primary: Color(0xFF2D7A4F),
              surface: Color(0xFF171717),
              onSurface: Colors.white,
            ),
          ),
          child: child!,
        );
      },
    );
    if (picked != null && mounted) {
      setState(() => _selectedDrawDate = picked);
    }
  }

  Future<void> _showWinnerDialog(int winningSegmentIndex, {bool isAutoDraw = false}) async {
    if (_selectedGroupId == null || _members.isEmpty) {
      return;
    }

    // Get the winner from the wheel segment
    final winnerIndex = _wheelValues[winningSegmentIndex];

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

    // Use the date chosen before spinning (or today for auto-draw)
    final DateTime drawDate = isAutoDraw
        ? _computeDefaultDrawDate()
        : (_selectedDrawDate ?? _computeDefaultDrawDate());

    if (!mounted) return;

    // Save the draw with the pre-selected date
    bool drawSaved = false;
    try {
      final drawDateStr = '${drawDate.year}-${drawDate.month.toString().padLeft(2, '0')}-${drawDate.day.toString().padLeft(2, '0')}';
      final result = await _apiService.createDraw(
        groupId: _selectedGroupId!,
        winnerUserId: winnerUserId,
        drawType: 'spin_wheel',
        drawDate: drawDateStr,
      );
      drawSaved = result != null;
      if (drawSaved) {
        print('Draw saved successfully: $result');
        
        // Immediate local state update for better responsiveness
        if (mounted) {
          setState(() {
            // Log for debugging
            print('--- ATOMIC UPDATE START ---');
            print('Winning index was: $winnerIndex');
            print('Members count before: ${_members.length}');
            
            // Create a new list for members
            final updatedMembers = List<Map<String, dynamic>>.from(_members);
            
            if (winnerIndex >= 0 && winnerIndex < updatedMembers.length) {
              final winnerData = updatedMembers[winnerIndex];
              print('Removing winner: ${winnerData['user_name']} (Member #${winnerData['member_number']})');
              updatedMembers.removeAt(winnerIndex);
            }
            
            // Atomically update both members and wheel values
            _members = updatedMembers;
            
            final newMemberCount = _members.length;
            if (newMemberCount == 0) {
              _wheelValues = List.generate(12, (index) => index);
            } else {
              _wheelValues = List.generate(newMemberCount, (index) => index);
            }
            
            _previousWinnerCount++;
            print('Members count after: ${_members.length}');
            print('Wheel segments count: ${_wheelValues.length}');
            print('--- ATOMIC UPDATE END ---');
          });
        }
        
        // Brief delay before backend sync to ensure UI settles
        Future.delayed(const Duration(milliseconds: 500), () {
          if (mounted) {
            _loadMembers(_selectedGroupId!, silent: true);
          }
        });
        // Send group notification (best-effort) so members see the winner in-app
        try {
          final title = 'Winner announced';
          final message = '$displayName is the winner for ${_selectedGroupData?['name'] ?? 'your group'}';
          await _apiService.createNotificationForGroup(groupId: _selectedGroupId!, title: title, message: message);
        } catch (e) {
          print('Failed to create group notification: $e');
        }
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

    if (drawSaved && !isAutoDraw) {
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
  }

  Future<void> _updateAutoDrawSettings(bool enabled, String? time) async {
    if (_selectedGroupId == null) return;
    
    // Optimistic update
    setState(() {
      _autoDraw = enabled;
      _autoDrawTime = time;
    });

    try {
      final success = await _apiService.updateGroup(_selectedGroupId!, {
        'auto_draw': enabled,
        'auto_draw_time': time,
        // Send other required fields from _selectedGroupData to satisfy schema validation
        'name': _selectedGroupData!['name'],
        'starting_date': _selectedGroupData!['starting_date'],
        'total_amount': _selectedGroupData!['total_amount'],
        'duration': _selectedGroupData!['duration'],
        'amount_per_period': _selectedGroupData!['amount_per_period'],
        'collection_period': _selectedGroupData!['collection_period'],
        // Ensure required fields are present to avoid 422 validation errors
        'number_of_members': _selectedGroupData!['number_of_members'],
        'currency': _selectedGroupData!['currency'],
      });

      if (success != null) {
        _selectedGroupData = success;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Auto draw settings updated'),
            backgroundColor: Color(0xFF2D7A4F),
            duration: Duration(seconds: 1),
          ),
        );
        // Restart checker based on updated settings
        _autoDraw = enabled;
        _autoDrawTime = time;
        _setupAutoDrawChecker();
      } else {
        throw Exception('Failed to update settings');
      }
    } catch (e) {
      // Revert on error
      setState(() {
        _autoDraw = _selectedGroupData?['auto_draw'] as bool? ?? false;
        _autoDrawTime = _selectedGroupData?['auto_draw_time'] as String?;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to update settings: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  Future<void> _selectTime(BuildContext context) async {
    final TimeOfDay? picked = await showTimePicker(
      context: context,
      initialTime: _autoDrawTime != null 
          ? TimeOfDay(
              hour: int.parse(_autoDrawTime!.split(':')[0]),
              minute: int.parse(_autoDrawTime!.split(':')[1]),
            )
          : TimeOfDay.now(),
      builder: (context, child) {
        return Theme(
          data: ThemeData.dark().copyWith(
            colorScheme: const ColorScheme.dark(
              primary: Color(0xFF2D7A4F),
              onPrimary: Colors.white,
              surface: Color(0xFF141414),
              onSurface: Colors.white,
            ),
            dialogBackgroundColor: const Color(0xFF171717),
          ),
          child: child!,
        );
      },
    );

    if (picked != null) {
      final timeStr = '${picked.hour.toString().padLeft(2, '0')}:${picked.minute.toString().padLeft(2, '0')}';
      _updateAutoDrawSettings(true, timeStr);
    }
  }

  /// Returns the rotation angle (in 0..2π) that places the given segment under the pointer.
  double _angleForSegment(int segmentIndex) {
    final segmentAngle = (2 * math.pi) / _wheelValues.length;
    return (2 * math.pi - (segmentIndex + 0.5) * segmentAngle) % (2 * math.pi);
  }

  void _shuffleWheel() {
    if (_isSpinning || _isShuffleAnimating || _members.isEmpty) return;
    final random = math.Random(DateTime.now().microsecondsSinceEpoch);
    final segmentCount = _wheelValues.length;
    final currentSegment = _getWinningSegment(_rotationAngle);
    // Pick a different segment for the pointer to land on
    int targetSegment;
    if (segmentCount <= 1) {
      targetSegment = 0;
    } else {
      targetSegment = random.nextInt(segmentCount - 1);
      if (targetSegment >= currentSegment) targetSegment += 1;
    }
    final targetAngle = _angleForSegment(targetSegment);
    final fullRotations = 2 + random.nextInt(2); // 2-3 full spins for animation
    final currentNormalized = _rotationAngle % (2 * math.pi);
    double delta = (targetAngle - currentNormalized + 2 * math.pi) % (2 * math.pi);
    if (delta < 0.1) delta = 2 * math.pi; // Ensure we spin at least one full rotation
    final totalRotation = (fullRotations * 2 * math.pi) + delta;
    final newEndAngle = _rotationAngle + totalRotation;
    // Duration proportional to rotation so angular speed is always consistent
    final rotations = totalRotation / (2 * math.pi);
    final durationMs = (rotations * 2000).round().clamp(4000, 8000); // ~2 sec per rotation, 4-8 sec total
    _shuffleController?.dispose();
    _shuffleController = AnimationController(
      vsync: this,
      duration: Duration(milliseconds: durationMs),
    );
    setState(() {
      _wheelValues = List<int>.from(_wheelValues)..shuffle(random);
      _isShuffleAnimating = true;
      _shuffleRotationAnimation = Tween<double>(
        begin: _rotationAngle,
        end: newEndAngle,
      ).animate(CurvedAnimation(
        parent: _shuffleController!,
        curve: Curves.decelerate,
      ));
    });
    _shuffleController!.reset();
    _shuffleController!.forward().then((_) {
      if (mounted) {
        setState(() {
          _rotationAngle = targetAngle; // Land exactly on target segment
          _isShuffleAnimating = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Wheel shuffled!'),
            backgroundColor: Color(0xFF2D7A4F),
            duration: Duration(milliseconds: 800),
          ),
        );
      }
    });
  }

  void _spinWheel({bool isAutoDraw = false}) {
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

    // Duration proportional to rotation so angular speed is always consistent
    final rotations = totalRotation / (2 * math.pi);
    final durationMs = (rotations * 1200).round().clamp(6000, 14000); // ~1.2 sec per rotation, 6-14 sec total
    _controller?.dispose();
    _controller = AnimationController(
      vsync: this,
      duration: Duration(milliseconds: durationMs),
    );

    // Update the rotation animation
    setState(() {
      _isSpinning = true;
      _rotationAnimation = Tween<double>(
        begin: _rotationAngle,
        end: newEndAngle,
      ).animate(CurvedAnimation(
        parent: _controller!,
        curve: Curves.decelerate,
      ));
    });

    // Reset and start animation
    _controller!.reset();
    _controller!.forward().then((_) {
      final finalAngle = newEndAngle % (2 * math.pi);
      if (mounted) {
        setState(() {
          _rotationAngle = finalAngle;
          _isSpinning = false;
          _hasSpun = true; // Lock the wheel after spin completes
        });
      }
      
      // Calculate and show winner
      final winningSegmentIndex = _getWinningSegment(finalAngle);
      _showWinnerDialog(winningSegmentIndex, isAutoDraw: false);
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF171717),
      body: SafeArea(
        child: LayoutBuilder(builder: (context, constraints) {
          final maxW = constraints.maxWidth;
          final maxH = constraints.maxHeight;
          // Estimate reserved vertical space for header, dropdowns, info boxes and buttons.
          // Compute wheel size from the remaining available height so it always fits.
          final bottomNavReserve = MediaQuery.of(context).padding.bottom + math.max(12.0, maxH * 0.02);
          final estimatedReserved = math.min(maxH * 0.52, 420.0); // heuristic reserve for header + controls
          final availableForWheel = (maxH - estimatedReserved - bottomNavReserve).clamp(120.0, maxH);
          // Be more conservative: limit wheel to a fraction of available vertical space to avoid overflow on tall reserved areas
          final wheelSize = math.min(maxW * 0.86, math.min(360.0, math.max(120.0, availableForWheel * 0.6)));
          final pointerWidth = math.max(24.0, wheelSize * 0.11);
          final pointerHeight = math.max(18.0, wheelSize * 0.07);
          final centerSize = math.max(44.0, wheelSize * 0.16);
          final spinButtonWidth = math.min(maxW * 0.6, 200.0);
          final spinButtonHeight = math.max(40.0, wheelSize * 0.10);

          return Column(
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
                                  _selectedGroupData = selectedGroup;
                                  _members = [];
                                  _wheelValues = [];
                                  _selectedDrawDate = _computeDefaultDrawDate();
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
                // Draw date selector (chosen before spinning)
                if (_selectedGroupId != null && !_isLoadingMembers && _selectedGroupData != null)
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    child: InkWell(
                      onTap: _selectDrawDate,
                      borderRadius: BorderRadius.circular(12),
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                        decoration: BoxDecoration(
                          color: const Color(0xFF141414),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: const Color(0xFF3A3A3A)),
                        ),
                        child: Row(
                          children: [
                            const Icon(
                              Icons.calendar_today_outlined,
                              color: Color(0xFF2D7A4F),
                              size: 22,
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'Draw date (${_getFrequencyLabel()} kuri)',
                                    style: const TextStyle(
                                      fontSize: 12,
                                      color: Color(0xFFA5A5A5),
                                      fontFamily: 'DM Sans',
                                    ),
                                  ),
                                  const SizedBox(height: 2),
                                  Text(
                                    _selectedDrawDate != null
                                        ? '${_selectedDrawDate!.year}-${_selectedDrawDate!.month.toString().padLeft(2, '0')}-${_selectedDrawDate!.day.toString().padLeft(2, '0')}'
                                        : 'Select date',
                                    style: const TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.w600,
                                      color: Colors.white,
                                      fontFamily: 'DM Sans',
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            const Icon(
                              Icons.chevron_right,
                              color: Color(0xFFA5A5A5),
                              size: 24,
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                // Auto Draw Toggle
                if (_selectedGroupId != null && !_isLoadingMembers)
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                      decoration: BoxDecoration(
                        color: const Color(0xFF141414),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Row(
                            children: [
                              const Icon(
                                Icons.auto_mode,
                                color: Color(0xFF2D7A4F),
                                size: 20,
                              ),
                              const SizedBox(width: 8),
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const Text(
                                    'Auto Draw',
                                    style: TextStyle(
                                      fontSize: 14,
                                      fontWeight: FontWeight.w600,
                                      color: Color(0xFFD0CDC6),
                                      fontFamily: 'DM Sans',
                                    ),
                                  ),
                                  if (_autoDraw && _autoDrawTime != null)
                                    Text(
                                      'Scheduled at $_autoDrawTime',
                                      style: const TextStyle(
                                        fontSize: 12,
                                        color: Color(0xFFA5A5A5),
                                        fontFamily: 'DM Sans',
                                      ),
                                    ),
                                ],
                              ),
                            ],
                          ),
                          Row(
                            children: [
                              if (_autoDraw)
                                TextButton(
                                  onPressed: () => _selectTime(context),
                                  child: Text(
                                    _autoDrawTime ?? 'Set Time',
                                    style: const TextStyle(
                                      color: Color(0xFF2D7A4F),
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ),
                              Switch(
                                value: _autoDraw,
                                onChanged: (value) {
                                  if (value && _autoDrawTime == null) {
                                    _selectTime(context);
                                  } else {
                                    _updateAutoDrawSettings(value, _autoDrawTime);
                                  }
                                },
                                activeColor: const Color(0xFF2D7A4F),
                                activeTrackColor: const Color(0xFF2D7A4F).withOpacity(0.3),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                const SizedBox(height: 10),
                // Spin the Wheel Title
                Text(
                  'Spin the Wheel',
                  style: TextStyle(
                    fontSize: math.max(18.0, wheelSize * 0.06),
                    fontWeight: FontWeight.w700,
                    color: const Color(0xFFD0CDC6),
                  ),
                ),
                SizedBox(height: math.max(12.0, wheelSize * 0.06)),
                // Wheel Container
                Expanded(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      SizedBox(
                        width: wheelSize,
                        height: wheelSize,
                        child: Stack(
                          alignment: Alignment.center,
                          children: [
                            // Wheel
                            AnimatedBuilder(
                              animation: () {
                                if (_isShuffleAnimating && _shuffleRotationAnimation != null) {
                                  return _shuffleRotationAnimation!;
                                }
                                if (_isSpinning && _rotationAnimation != null) {
                                  return _rotationAnimation!;
                                }
                                return AlwaysStoppedAnimation<double>(_rotationAngle);
                              }(),
                              builder: (context, child) {
                                final angle = _isShuffleAnimating && _shuffleRotationAnimation != null
                                    ? _shuffleRotationAnimation!.value
                                    : _isSpinning && _rotationAnimation != null
                                        ? _rotationAnimation!.value
                                        : _rotationAngle;
                                return Transform.rotate(
                                  angle: angle,
                                  child: CustomPaint(
                                    size: Size(wheelSize, wheelSize),
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
                                size: Size(pointerWidth, pointerHeight),
                                painter: PointerPainter(),
                              ),
                            ),
                            // Center star - tap to shuffle wheel
                            GestureDetector(
                              onTap: _isSpinning || _isShuffleAnimating || _members.isEmpty
                                  ? null
                                  : _shuffleWheel,
                              child: Container(
                                width: centerSize,
                                height: centerSize,
                                decoration: BoxDecoration(
                                  color: const Color(0xFF374151),
                                  shape: BoxShape.circle,
                                  boxShadow: [
                                    BoxShadow(
                                      color: Colors.black.withOpacity(0.2),
                                      blurRadius: math.max(6.0, centerSize * 0.12),
                                      offset: Offset(0, math.max(1.0, centerSize * 0.03)),
                                    ),
                                  ],
                                ),
                                child: Icon(
                                  Icons.star,
                                  color: Colors.white,
                                  size: math.max(20.0, centerSize * 0.45),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      SizedBox(height: math.max(8.0, wheelSize * 0.035)),
                      // Spin Button
                      SizedBox(
                        width: spinButtonWidth,
                        height: spinButtonHeight,
                        child: ElevatedButton(
                          onPressed: _isSpinning || _isShuffleAnimating || _selectedGroupId == null || _members.isEmpty || _hasSpun
                              ? null
                              : _spinWheel,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF2D7A4F),
                            foregroundColor: Colors.white,
                            disabledBackgroundColor: const Color(0xFF6B7280),
                            disabledForegroundColor: Colors.white54,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(math.max(10.0, spinButtonHeight * 0.22)),
                            ),
                            elevation: 4,
                          ),
                          child: _isSpinning
                              ? SizedBox(
                                  width: math.max(18.0, spinButtonHeight * 0.4),
                                  height: math.max(18.0, spinButtonHeight * 0.4),
                                  child: const CircularProgressIndicator(
                                    valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                                    strokeWidth: 2,
                                  ),
                                )
                              : Text(
                                  _hasSpun ? 'SPUN' : 'SPIN',
                                  style: TextStyle(
                                    fontSize: math.max(14.0, spinButtonHeight * 0.36),
                                    fontWeight: FontWeight.w700,
                                    letterSpacing: 1.2,
                                    color: Colors.white,
                                  ),
                                ),
                        ),
                      ),
                    ],
                  ),
                ),
                SizedBox(height: math.max(12.0, bottomNavReserve)), // Space for bottom nav bar
              ],
            );
          },
        ),
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
    if (values.length == 1) {
      // Single segment: draw a full circle
      canvas.drawCircle(
        center,
        radius,
        Paint()
          ..color = lightGreen
          ..style = PaintingStyle.fill,
      );
      
      // Draw text for the single member
      _drawSegmentText(canvas, center, radius, 0, (2 * math.pi) / 1);
    } else {
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

        _drawSegmentText(canvas, center, radius, i, segmentAngle);
      }
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

  void _drawSegmentText(Canvas canvas, Offset center, double radius, int i, double segmentAngle) {
    final startAngle = i * segmentAngle - math.pi / 2;
    final textAngle = startAngle + segmentAngle / 2;
    final textRadius = radius * 0.7;
    final textX = center.dx + textRadius * math.cos(textAngle);
    final textY = center.dy + textRadius * math.sin(textAngle);

    // Get member number (from API) or fallback to placeholder
    String displayText;
    if (members.isNotEmpty && i >= 0 && i < values.length && values[i] < members.length) {
      final memberIndex = values[i];
      final member = members[memberIndex];
      // Use member_number if available, otherwise use a placeholder to stay stable
      final memberNumber = member['member_number'];
      if (memberNumber != null) {
        displayText = '$memberNumber';
      } else {
        // Fallback that doesn't deceptively shift (e.g., use the original list position if we can't get member_number)
        displayText = '#?'; 
      }
    } else {
      displayText = '';
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

  @override
  bool shouldRepaint(covariant WheelPainter oldDelegate) {
    return oldDelegate.values != values || oldDelegate.members != members;
  }
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
