import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../services/api_service.dart';

class WinnersScreen extends StatefulWidget {
  const WinnersScreen({super.key});

  @override
  State<WinnersScreen> createState() => _WinnersScreenState();
}

class _WinnersScreenState extends State<WinnersScreen> {
  final ApiService _apiService = ApiService();
  List<Map<String, dynamic>> _allDraws = [];
  bool _isLoading = true;
  String? _errorMessage;
  String? _selectedDate;
  int? _selectedGroupId;
  String? _selectedGroupName;
  List<Map<String, dynamic>> _groups = [];
  List<String> _availableDates = [];

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });
    await Future.wait([
      _loadGroups(),
      _loadDraws(),
    ]);
  }

  Future<void> _loadGroups() async {
    try {
      final groups = await _apiService.getGroups();
      if (mounted) {
        setState(() {
          _groups = groups;
        });
      }
    } catch (e) {
      print('Error loading groups: $e');
    }
  }

  Future<void> _loadDraws() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      print('Loading draws from API...');
      final draws = await _apiService.getAllDraws();
      print('Received ${draws.length} draws from API');

      if (mounted) {
        // Extract unique dates and sort them
        final dates = draws
            .map((d) {
              final createdAt = d['created_at'] as String?;
              if (createdAt != null) {
                try {
                  final date = DateTime.parse(createdAt);
                  return DateFormat('MMM d, yyyy').format(date);
                } catch (e) {
                  return null;
                }
              }
              return null;
            })
            .whereType<String>()
            .toSet()
            .toList();
        
        dates.sort((a, b) {
          try {
            final dateA = DateFormat('MMM d, yyyy').parse(a);
            final dateB = DateFormat('MMM d, yyyy').parse(b);
            return dateB.compareTo(dateA); // Most recent first
          } catch (e) {
            return 0;
          }
        });

        setState(() {
          _allDraws = draws;
          _availableDates = ['All Dates', ...dates];
          _isLoading = false;
        });
        print('Updated state with ${_allDraws.length} draws');
      }
    } catch (e) {
      print('Error loading draws: $e');
      if (mounted) {
        setState(() {
          _errorMessage = 'Failed to load winners: ${e.toString()}';
          _isLoading = false;
        });
      }
    }
  }

  List<Map<String, dynamic>> get _filteredDraws {
    List<Map<String, dynamic>> filtered = List.from(_allDraws);

    // Filter by date
    if (_selectedDate != null && _selectedDate != 'All Dates') {
      try {
        final selectedDate = DateFormat('MMM d, yyyy').parse(_selectedDate!);
        filtered = filtered.where((draw) {
          final createdAt = draw['created_at'] as String?;
          if (createdAt != null) {
            try {
              final drawDate = DateTime.parse(createdAt);
              return DateFormat('yyyy-MM-dd').format(drawDate) ==
                  DateFormat('yyyy-MM-dd').format(selectedDate);
            } catch (e) {
              return false;
            }
          }
          return false;
        }).toList();
      } catch (e) {
        print('Error filtering by date: $e');
      }
    }

    // Filter by group
    if (_selectedGroupId != null) {
      filtered = filtered.where((draw) {
        return draw['kuri_group_id'] == _selectedGroupId;
      }).toList();
    }

    return filtered;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF171717),
      body: SafeArea(
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
                      icon: const Icon(
                        Icons.arrow_back,
                        color: Colors.white,
                        size: 24,
                      ),
                      onPressed: () => Navigator.of(context).pop(),
                    ),
                    const Expanded(
                      child: Text(
                        'Winners',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w600,
                          color: Color(0xFFEFEEEC),
                          fontFamily: 'DM Sans',
                        ),
                      ),
                    ),
                    IconButton(
                      padding: EdgeInsets.zero,
                      icon: const Icon(
                        Icons.more_vert,
                        color: Colors.white,
                        size: 24,
                      ),
                      onPressed: () {
                        // Handle menu action
                      },
                    ),
                  ],
                ),
              ),
            ),
            // Filters
            Padding(
              padding: const EdgeInsets.all(20),
              child: Row(
                children: [
                  Expanded(
                    child: _buildDateFilterDropdown(),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _buildGroupFilterDropdown(),
                  ),
                ],
              ),
            ),
            // Winners List
            Expanded(
              child: _buildWinnersList(),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDateFilterDropdown() {
    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFF232220),
        borderRadius: BorderRadius.circular(12),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          value: _selectedDate,
          isExpanded: true,
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          hint: const Text(
            'Date',
            style: TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w400,
              color: Color(0xFFA5A5A5),
              fontFamily: 'DM Sans',
            ),
          ),
          icon: const Icon(
            Icons.keyboard_arrow_down,
            color: Color(0xFFA5A5A5),
            size: 24,
          ),
          style: const TextStyle(
            fontSize: 15,
            fontWeight: FontWeight.w400,
            color: Color(0xFFD0CDC6),
            fontFamily: 'DM Sans',
          ),
          dropdownColor: const Color(0xFF232220),
          items: _availableDates.map((String date) {
            return DropdownMenuItem<String>(
              value: date,
              child: Text(date),
            );
          }).toList(),
          onChanged: (value) {
            setState(() {
              _selectedDate = value;
            });
          },
        ),
      ),
    );
  }

  Widget _buildGroupFilterDropdown() {
    final List<String> groupNames = ['All Groups', ..._groups.map((g) => g['name'] as String).whereType<String>().toList()];
    final List<int?> groupIds = [null, ..._groups.map((g) => g['id'] as int?).toList()];

    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFF232220),
        borderRadius: BorderRadius.circular(12),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<int?>(
          value: _selectedGroupId,
          isExpanded: true,
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          hint: Text(
            _selectedGroupName ?? 'All Groups',
            style: const TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w400,
              color: Color(0xFFA5A5A5),
              fontFamily: 'DM Sans',
            ),
          ),
          icon: const Icon(
            Icons.keyboard_arrow_down,
            color: Color(0xFFA5A5A5),
            size: 24,
          ),
          style: const TextStyle(
            fontSize: 15,
            fontWeight: FontWeight.w400,
            color: Color(0xFFD0CDC6),
            fontFamily: 'DM Sans',
          ),
          dropdownColor: const Color(0xFF232220),
          items: List.generate(groupNames.length, (index) {
            return DropdownMenuItem<int?>(
              value: groupIds[index],
              child: Text(groupNames[index]),
            );
          }),
          onChanged: (value) {
            setState(() {
              _selectedGroupId = value;
              _selectedGroupName = value == null
                  ? 'All Groups'
                  : _groups.firstWhere((g) => g['id'] == value)['name'] as String?;
            });
          },
        ),
      ),
    );
  }

  Widget _buildWinnersList() {
    if (_isLoading) {
      return const Center(
        child: CircularProgressIndicator(
          valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF2D7A4F)),
        ),
      );
    }

    if (_errorMessage != null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              _errorMessage!,
              style: const TextStyle(color: Colors.red),
            ),
            const SizedBox(height: 10),
            ElevatedButton(
              onPressed: _loadData,
              child: const Text('Retry'),
            ),
          ],
        ),
      );
    }

    if (_filteredDraws.isEmpty) {
      return const Center(
        child: Text(
          'No winners yet.',
          style: TextStyle(
            fontSize: 16,
            color: Color(0xFFA5A5A5),
          ),
        ),
      );
    }

    // Group draws by date
    final Map<String, List<Map<String, dynamic>>> grouped = {};
    for (var draw in _filteredDraws) {
      final createdAt = draw['created_at'] as String?;
      if (createdAt != null) {
        try {
          final date = DateTime.parse(createdAt);
          final formattedDate = DateFormat('MMM d, yyyy').format(date);
          grouped.putIfAbsent(formattedDate, () => []).add(draw);
        } catch (e) {
          print('Error parsing draw date for grouping: $e');
        }
      }
    }

    return RefreshIndicator(
      onRefresh: _loadDraws,
      color: const Color(0xFF2D7A4F),
      child: ListView(
        padding: const EdgeInsets.symmetric(horizontal: 20),
        children: _buildWinnerSections(grouped),
      ),
    );
  }

  List<Widget> _buildWinnerSections(Map<String, List<Map<String, dynamic>>> grouped) {
    List<Widget> sections = [];

    // Sort dates (most recent first)
    final sortedDates = grouped.keys.toList()..sort((a, b) {
      try {
        final dateA = DateFormat('MMM d, yyyy').parse(a);
        final dateB = DateFormat('MMM d, yyyy').parse(b);
        return dateB.compareTo(dateA);
      } catch (e) {
        return 0;
      }
    });

    for (var date in sortedDates) {
      final draws = grouped[date]!;
      sections.add(
        Padding(
          padding: const EdgeInsets.only(bottom: 16, top: 8),
          child: Text(
            date,
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: Color(0xFFA5A5A5),
              fontFamily: 'DM Sans',
            ),
          ),
        ),
      );

      for (var draw in draws) {
        final winnerName = draw['winner_name'] as String? ?? 'Unknown';
        final groupName = draw['group_name'] as String? ?? 'Unknown Group';
        final drawType = draw['draw_type'] as String? ?? 'spin_wheel';
        final createdAt = draw['created_at'] as String?;

        sections.add(
          _buildWinnerCard(
            winnerName: winnerName,
            groupName: groupName,
            drawType: drawType,
            createdAt: createdAt,
          ),
        );
        sections.add(const SizedBox(height: 12));
      }
    }

    return sections;
  }

  Widget _buildWinnerCard({
    required String winnerName,
    required String groupName,
    required String drawType,
    String? createdAt,
  }) {
    // Format time if available
    String timeText = '';
    if (createdAt != null) {
      try {
        final date = DateTime.parse(createdAt);
        timeText = DateFormat('h:mm a').format(date);
      } catch (e) {
        // Ignore parsing errors
      }
    }

    final drawTypeText = drawType == 'spin_wheel' ? 'Spin Wheel' : 'Manual Draw';
    
    // Format display name - extract from email if needed
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
    
    final initial = displayName.isNotEmpty ? displayName[0].toUpperCase() : '?';

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: const Color(0xFF232220),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        children: [
          // Winner Avatar
          Container(
            width: 56,
            height: 56,
            decoration: BoxDecoration(
              color: const Color(0xFF2D7A4F),
              shape: BoxShape.circle,
            ),
            child: Center(
              child: Text(
                initial,
                style: const TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.w700,
                  color: Colors.white,
                  fontFamily: 'DM Sans',
                ),
              ),
            ),
          ),
          const SizedBox(width: 16),
          // Winner Info
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  displayName,
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                    color: Colors.white,
                    fontFamily: 'DM Sans',
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  groupName,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w400,
                    color: Color(0xFFA5A5A5),
                    fontFamily: 'DM Sans',
                  ),
                ),
                if (timeText.isNotEmpty) ...[
                  const SizedBox(height: 2),
                  Text(
                    '$drawTypeText • $timeText',
                    style: const TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w400,
                      color: Color(0xFF6B7280),
                      fontFamily: 'DM Sans',
                    ),
                  ),
                ] else ...[
                  const SizedBox(height: 2),
                  Text(
                    drawTypeText,
                    style: const TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w400,
                      color: Color(0xFF6B7280),
                      fontFamily: 'DM Sans',
                    ),
                  ),
                ],
              ],
            ),
          ),
          // Trophy Icon
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: const Color(0xFF2D7A4F).withOpacity(0.2),
              borderRadius: BorderRadius.circular(8),
            ),
            child: const Icon(
              Icons.emoji_events,
              color: Color(0xFF2D7A4F),
              size: 24,
            ),
          ),
        ],
      ),
    );
  }
}

