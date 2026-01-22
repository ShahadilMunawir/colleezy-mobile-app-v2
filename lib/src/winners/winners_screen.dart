import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../services/api_service.dart';
import '../../utils/responsive.dart';

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
    final responsive = Responsive(context);
    return Scaffold(
      backgroundColor: const Color(0xFF171717),
      body: SafeArea(
        child: Column(
          children: [
            // Header
            Container(
              width: double.infinity,
              decoration: BoxDecoration(
                color: Color(0xFF141414),
                borderRadius: BorderRadius.only(
                  bottomLeft: Radius.circular(responsive.radius(24)),
                  bottomRight: Radius.circular(responsive.radius(24)),
                ),
              ),
              child: Padding(
                padding: responsive.paddingFromLTRB(0, 16, 20, 20),
                child: Row(
                  children: [
                    IconButton(
                      padding: EdgeInsets.zero,
                      icon: Icon(
                        Icons.arrow_back,
                        color: Colors.white,
                        size: responsive.width(24),
                      ),
                      onPressed: () => Navigator.of(context).pop(),
                    ),
                    Text(
                      'Winners',
                      style: TextStyle(
                        fontSize: responsive.fontSize(18),
                        fontWeight: FontWeight.w600,
                        color: Color(0xFFEFEEEC),
                        fontFamily: 'DM Sans',
                      ),
                    ),
                  ],
                ),
              ),
            ),
            // Filters
            Padding(
              padding: responsive.paddingAll(20),
              child: Row(
                children: [
                  Expanded(
                    child: _buildDateFilterDropdown(context),
                  ),
                  SizedBox(width: responsive.spacing(12)),
                  Expanded(
                    child: _buildGroupFilterDropdown(context),
                  ),
                ],
              ),
            ),
            // Winners List
            Expanded(
              child: _buildWinnersList(context),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDateFilterDropdown(BuildContext context) {
    final responsive = Responsive(context);
    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFF232220),
        borderRadius: BorderRadius.circular(responsive.radius(12)),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          value: _selectedDate,
          isExpanded: true,
          padding: responsive.paddingSymmetric(horizontal: 16, vertical: 14),
          hint: Text(
            'Date',
            style: TextStyle(
              fontSize: responsive.fontSize(15),
              fontWeight: FontWeight.w400,
              color: Color(0xFFA5A5A5),
              fontFamily: 'DM Sans',
            ),
          ),
          icon: Icon(
            Icons.keyboard_arrow_down,
            color: Color(0xFFA5A5A5),
            size: responsive.width(24),
          ),
          style: TextStyle(
            fontSize: responsive.fontSize(15),
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

  Widget _buildGroupFilterDropdown(BuildContext context) {
    final responsive = Responsive(context);
    final List<String> groupNames = ['All Groups', ..._groups.map((g) => g['name'] as String).whereType<String>().toList()];
    final List<int?> groupIds = [null, ..._groups.map((g) => g['id'] as int?).toList()];

    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFF232220),
        borderRadius: BorderRadius.circular(responsive.radius(12)),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<int?>(
          value: _selectedGroupId,
          isExpanded: true,
          padding: responsive.paddingSymmetric(horizontal: 16, vertical: 14),
          hint: Text(
            _selectedGroupName ?? 'All Groups',
            style: TextStyle(
              fontSize: responsive.fontSize(15),
              fontWeight: FontWeight.w400,
              color: Color(0xFFA5A5A5),
              fontFamily: 'DM Sans',
            ),
          ),
          icon: Icon(
            Icons.keyboard_arrow_down,
            color: Color(0xFFA5A5A5),
            size: responsive.width(24),
          ),
          style: TextStyle(
            fontSize: responsive.fontSize(15),
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

  Widget _buildWinnersList(BuildContext context) {
    final responsive = Responsive(context);
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
              style: TextStyle(color: Colors.red, fontSize: responsive.fontSize(14)),
            ),
            SizedBox(height: responsive.spacing(10)),
            ElevatedButton(
              onPressed: _loadData,
              child: Text('Retry'),
            ),
          ],
        ),
      );
    }

    if (_filteredDraws.isEmpty) {
      return Center(
        child: Text(
          'No winners yet.',
          style: TextStyle(
            fontSize: responsive.fontSize(16),
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
        padding: responsive.paddingSymmetric(horizontal: 20),
        children: _buildWinnerSections(context, grouped),
      ),
    );
  }

  List<Widget> _buildWinnerSections(BuildContext context, Map<String, List<Map<String, dynamic>>> grouped) {
    final responsive = Responsive(context);
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
          padding: EdgeInsets.only(bottom: responsive.spacing(16), top: responsive.spacing(8)),
          child: Text(
            date,
            style: TextStyle(
              fontSize: responsive.fontSize(16),
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
            context: context,
            winnerName: winnerName,
            groupName: groupName,
            drawType: drawType,
            createdAt: createdAt,
          ),
        );
        sections.add(SizedBox(height: responsive.spacing(12)));
      }
    }

    return sections;
  }

  Widget _buildWinnerCard({
    required BuildContext context,
    required String winnerName,
    required String groupName,
    required String drawType,
    String? createdAt,
  }) {
    final responsive = Responsive(context);
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
      padding: responsive.paddingAll(20),
      decoration: BoxDecoration(
        color: Color(0xFF232220),
        borderRadius: BorderRadius.circular(responsive.radius(16)),
      ),
      child: Row(
        children: [
          // Winner Avatar
          Container(
            width: responsive.width(56),
            height: responsive.height(56),
            decoration: BoxDecoration(
              color: const Color(0xFF2D7A4F),
              shape: BoxShape.circle,
            ),
            child: Center(
              child: Text(
                initial,
                style: TextStyle(
                  fontSize: responsive.fontSize(24),
                  fontWeight: FontWeight.w700,
                  color: Colors.white,
                  fontFamily: 'DM Sans',
                ),
              ),
            ),
          ),
          SizedBox(width: responsive.spacing(16)),
          // Winner Info
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  displayName,
                  style: TextStyle(
                    fontSize: responsive.fontSize(18),
                    fontWeight: FontWeight.w600,
                    color: Colors.white,
                    fontFamily: 'DM Sans',
                  ),
                ),
                SizedBox(height: responsive.spacing(4)),
                Text(
                  groupName,
                  style: TextStyle(
                    fontSize: responsive.fontSize(14),
                    fontWeight: FontWeight.w400,
                    color: Color(0xFFA5A5A5),
                    fontFamily: 'DM Sans',
                  ),
                ),
                if (timeText.isNotEmpty) ...[
                  SizedBox(height: responsive.spacing(2)),
                  Text(
                    '$drawTypeText • $timeText',
                    style: TextStyle(
                      fontSize: responsive.fontSize(12),
                      fontWeight: FontWeight.w400,
                      color: Color(0xFF6B7280),
                      fontFamily: 'DM Sans',
                    ),
                  ),
                ] else ...[
                  SizedBox(height: responsive.spacing(2)),
                  Text(
                    drawTypeText,
                    style: TextStyle(
                      fontSize: responsive.fontSize(12),
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
            padding: responsive.paddingAll(8),
            decoration: BoxDecoration(
              color: Color(0xFF2D7A4F).withOpacity(0.2),
              borderRadius: BorderRadius.circular(responsive.radius(8)),
            ),
            child: Icon(
              Icons.emoji_events,
              color: Color(0xFF2D7A4F),
              size: responsive.width(24),
            ),
          ),
        ],
      ),
    );
  }
}

