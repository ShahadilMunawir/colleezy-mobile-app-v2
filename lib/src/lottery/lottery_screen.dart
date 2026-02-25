import 'package:flutter/material.dart';
import '../services/api_service.dart';
import '../winners/winners_screen.dart';

class LotteryScreen extends StatefulWidget {
  const LotteryScreen({super.key});

  @override
  State<LotteryScreen> createState() => _LotteryScreenState();
}

class _LotteryScreenState extends State<LotteryScreen> {
  final ApiService _apiService = ApiService();
  List<Map<String, dynamic>> _groups = [];
  Map<int, int> _groupMemberCounts = {}; // groupId -> memberCount
  bool _isLoading = true;

  // Color palette for avatars
  final List<Color> _avatarColors = [
    const Color(0xFF556B2F), // Dark olive green
    const Color(0xFF7B68EE), // Light purple-blue
    const Color(0xFF8B4513), // Dark reddish-brown
    const Color(0xFF90EE90), // Light green
  ];

  Color _getAvatarColor(int index) {
    return _avatarColors[index % _avatarColors.length];
  }

  @override
  void initState() {
    super.initState();
    _loadGroups();
  }

  Future<void> _loadGroups() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final groups = await _apiService.getGroups();
      final Map<int, int> memberCounts = {};

      for (var group in groups) {
        final groupId = group['id'] as int;
        try {
          final members = await _apiService.getGroupMembers(groupId);
          memberCounts[groupId] = members.length;
        } catch (e) {
          print('Error loading members for group $groupId: $e');
          memberCounts[groupId] = 0;
        }
      }

      if (mounted) {
        setState(() {
          _groups = groups;
          _groupMemberCounts = memberCounts;
          _isLoading = false;
        });
      }
    } catch (e) {
      print('Error loading groups: $e');
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
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
                    padding: const EdgeInsets.fromLTRB(20, 16, 20, 20),
                    child: const Text(
                      'Lottery',
                      style: TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.w700,
                        color: Color(0xFFEFEEEC),
                      ),
                    ),
                  ),
                ),
                // Groups List
                Expanded(
                  child: _isLoading
                      ? const Center(
                          child: CircularProgressIndicator(
                            valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF2D7A4F)),
                          ),
                        )
                      : _groups.isEmpty
                          ? const Center(
                              child: Text(
                                'No groups yet. Create one!',
                                style: TextStyle(
                                  fontSize: 16,
                                  color: Color(0xFFA5A5A5),
                                ),
                              ),
                            )
                          : ListView.builder(
                    padding: const EdgeInsets.all(20),
                              itemCount: _groups.length,
                              itemBuilder: (context, index) {
                                final group = _groups[index];
                                final groupId = group['id'] as int;
                                final groupName = group['name'] as String? ?? 'Unnamed Group';
                                final memberCount = _groupMemberCounts[groupId] ?? 0;
                                return Padding(
                                  padding: EdgeInsets.only(
                                    bottom: index < _groups.length - 1 ? 16 : 0,
                                  ),
                                  child: _buildGroupCard(
                                    groupId: groupId,
                                    title: groupName,
                                    memberCount: memberCount,
                                  ),
                                );
                              },
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildGroupCard({
    required int groupId,
    required String title,
    required int memberCount,
  }) {
    return InkWell(
      onTap: () {
        _showSelectWinnerModal(context, groupId);
      },
      borderRadius: BorderRadius.circular(16),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: const Color(0xFF232220),
          borderRadius: BorderRadius.circular(16),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w600,
                      color: Color(0xFFF2F2F2),
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '$memberCount members',
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w400,
                      color: Color(0xFFC1BDB3),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _showSelectWinnerModal(BuildContext context, int groupId) async {
    // Load group details and members
    try {
      final group = await _apiService.getGroup(groupId);
      if (group == null) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Failed to load group details'),
              backgroundColor: Colors.red,
            ),
          );
        }
        return;
      }
      final members = await _apiService.getGroupMembers(groupId);
      
      // Convert members to participants format
      final participants = members.map((member) {
        final userName = member['user_name'] as String? ?? 
                        (member['user_email'] as String? ?? 'Unknown');
        
        // Extract initial
        String initial = '?';
        if (userName.isNotEmpty) {
          if (userName.contains('@')) {
            final emailParts = userName.split('@');
            if (emailParts.isNotEmpty) {
              initial = emailParts[0][0].toUpperCase();
            }
          } else {
            initial = userName[0].toUpperCase();
          }
        }
        
        return {
          'user_id': member['user_id'] as int,
          'name': userName,
          'initial': initial,
        };
      }).toList();
      if (!mounted) return;

      // Fetch previous draws and exclude previous winners so they do not appear
      // in the manual draw participant list.
      Set<int> previousWinners = {};
      try {
        final draws = await _apiService.getGroupDraws(groupId);
        for (var d in draws) {
          final winnerId = d['winner_user_id'] as int?;
          if (winnerId != null) previousWinners.add(winnerId);
        }
      } catch (e) {
        // ignore - we'll still show participants
      }

      final eligibleParticipants = participants.where((p) {
        final uid = p['user_id'] as int;
        return !previousWinners.contains(uid);
      }).toList();

      if (eligibleParticipants.isEmpty) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('All members have already been selected as winners.'),
              backgroundColor: Colors.red,
            ),
          );
        }
        return;
      }

      showModalBottomSheet(
        context: context,
        backgroundColor: Colors.transparent,
        isScrollControlled: true,
        builder: (BuildContext context) {
          return _SelectWinnerModal(
            groupId: groupId,
            groupData: group,
            participants: eligibleParticipants,
            getAvatarColor: _getAvatarColor,
          );
        },
      );
    } catch (e) {
      print('Error loading members: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to load members: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }
}

class _SelectWinnerModal extends StatefulWidget {
  final int groupId;
  final Map<String, dynamic> groupData;
  final List<Map<String, dynamic>> participants;
  final Color Function(int) getAvatarColor;
 
  const _SelectWinnerModal({
    required this.groupId,
    required this.groupData,
    required this.participants,
    required this.getAvatarColor,
  });

  @override
  State<_SelectWinnerModal> createState() => _SelectWinnerModalState();
}

class _SelectWinnerModalState extends State<_SelectWinnerModal> {
  int? selectedWinnerUserId;
  DateTime? _selectedDate;
  final ApiService _apiService = ApiService();
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    final now = DateTime.now();
    final first = _getFirstDate();
    final last = _getLastDate();
    if (now.isBefore(first)) {
      _selectedDate = first;
    } else if (now.isAfter(last)) {
      _selectedDate = last;
    } else {
      _selectedDate = now;
    }
  }

  DateTime _getFirstDate() {
    final startStr = widget.groupData['starting_date'] as String?;
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
    final start = _getFirstDate();
    final duration = widget.groupData['duration'] as int? ?? 12;
    final collectionPeriod = (widget.groupData['collection_period'] as String? ?? 'monthly').toLowerCase();
    final frequencyInDays = widget.groupData['frequency_in_days'] as num?;
    if (frequencyInDays != null) {
      return start.add(Duration(days: (duration * frequencyInDays.toDouble()).toInt()));
    }
    if (collectionPeriod == 'weekly') {
      return start.add(Duration(days: duration * 7));
    }
    // Monthly
    return DateTime(start.year, start.month + duration, start.day);
  }

  String _getFrequencyLabel() {
    final collectionPeriod = (widget.groupData['collection_period'] as String? ?? 'monthly').toLowerCase();
    final frequencyInDays = widget.groupData['frequency_in_days'] as num?;
    if (frequencyInDays != null) {
      if (frequencyInDays <= 1) return 'Daily';
      if (frequencyInDays <= 7) return 'Weekly';
      if (frequencyInDays <= 31) return 'Every ${frequencyInDays.toInt()} days';
      return 'Monthly';
    }
    return collectionPeriod == 'weekly' ? 'Weekly' : 'Monthly';
  }

  Future<void> _selectDate() async {
    final first = _getFirstDate();
    final last = _getLastDate();
    final picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate ?? DateTime.now(),
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
      setState(() => _selectedDate = picked);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      height: MediaQuery.of(context).size.height * 0.7,
      decoration: const BoxDecoration(
        color: Color(0xFF171717),
        borderRadius: BorderRadius.only(
          topLeft: Radius.circular(20),
          topRight: Radius.circular(20),
        ),
      ),
      child: Column(
        children: [
          // Handle bar
          Container(
            margin: const EdgeInsets.only(top: 12, bottom: 8),
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: const Color(0xFFA5A5A5),
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          // Title
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
            child: const Text(
              'Select Winner',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w600,
                color: Colors.white,
                fontFamily: 'DM Sans',
              ),
            ),
          ),
          // Date selector (based on kuri frequency)
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
            child: InkWell(
              onTap: _selectDate,
              borderRadius: BorderRadius.circular(12),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                decoration: BoxDecoration(
                  color: const Color(0xFF232220),
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
                            _selectedDate != null
                                ? '${_selectedDate!.year}-${_selectedDate!.month.toString().padLeft(2, '0')}-${_selectedDate!.day.toString().padLeft(2, '0')}'
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
          // Participants List
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              itemCount: widget.participants.length,
              itemBuilder: (context, index) {
                final participant = widget.participants[index];
                final userId = participant['user_id'] as int;
                final isSelected = selectedWinnerUserId == userId;
                return _buildParticipantItem(
                  name: participant['name'] as String,
                  initial: participant['initial'] as String,
                  avatarColor: widget.getAvatarColor(index),
                  isSelected: isSelected,
                  onTap: () {
                    setState(() {
                      selectedWinnerUserId = userId;
                    });
                  },
                );
              },
            ),
          ),
          // Winner Button
          Container(
            padding: const EdgeInsets.all(20),
            child: SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _isSaving || selectedWinnerUserId == null
                    ? null
                    : () async {
                        await _saveWinner();
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF2D7A4F),
                  foregroundColor: Colors.white,
                  elevation: 0,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  disabledBackgroundColor: const Color(0xFF6B7280),
                ),
                child: _isSaving
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                          valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                          strokeWidth: 2,
                        ),
                      )
                    : const Text(
                  'Winner',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    fontFamily: 'DM Sans',
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildParticipantItem({
    required String name,
    required String initial,
    required Color avatarColor,
    required bool isSelected,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12),
        child: Row(
          children: [
            // Avatar
            Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                color: avatarColor,
                shape: BoxShape.circle,
              ),
              child: Center(
                child: Text(
                  initial,
                  style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.w700,
                    color: Colors.white,
                    fontFamily: 'DM Sans',
                  ),
                ),
              ),
            ),
            const SizedBox(width: 16),
            // Name
            Expanded(
              child: Text(
                name,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: Colors.white,
                  fontFamily: 'DM Sans',
                ),
              ),
            ),
            // Radio Button
            Container(
              width: 24,
              height: 24,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(
                  color: Colors.white,
                  width: 2,
                ),
                color: isSelected ? const Color(0xFF2D7A4F) : Colors.transparent,
              ),
              child: isSelected
                  ? const Center(
                      child: Icon(
                        Icons.check,
                        size: 16,
                        color: Colors.white,
                      ),
                    )
                  : null,
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _saveWinner() async {
    if (selectedWinnerUserId == null) return;

    setState(() {
      _isSaving = true;
    });

    try {
      final drawDateStr = _selectedDate != null
          ? '${_selectedDate!.year}-${_selectedDate!.month.toString().padLeft(2, '0')}-${_selectedDate!.day.toString().padLeft(2, '0')}'
          : null;
      final result = await _apiService.createDraw(
        groupId: widget.groupId,
        winnerUserId: selectedWinnerUserId!,
        drawType: 'manual_draw',
        drawDate: drawDateStr,
      );

      if (result != null && mounted) {
        // Close the modal
        Navigator.pop(context);
        // Navigate to Winners screen to show the saved winner
        Navigator.of(context).push(
          MaterialPageRoute(builder: (c) => const WinnersScreen()),
        );
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Winner saved successfully!'),
            backgroundColor: Color(0xFF2D7A4F),
          ),
        );
      } else {
        if (mounted) {
          setState(() {
            _isSaving = false;
          });
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Failed to save winner'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    } catch (e) {
      print('Error saving winner: $e');
      if (mounted) {
        setState(() {
          _isSaving = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error saving winner: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }
}

