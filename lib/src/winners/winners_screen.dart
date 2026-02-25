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
  String _selectedFrequency = 'all'; // 'all', 'monthly', 'weekly', 'daily', 'every_15_days', 'twice_daily'
  String? _selectedPeriod;   // e.g. "Feb 2026", "Week 4, Feb 2026", "26 Feb 2026", "1st half Feb 2026"
  int? _selectedGroupId;
  String? _selectedGroupName;
  List<Map<String, dynamic>> _groups = [];

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
        setState(() {
          _allDraws = draws;
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

  /// Format a date for the given frequency (used for period options).
  String _formatDateForFrequency(DateTime date, String frequency) {
    switch (frequency) {
      case 'monthly':
        return DateFormat('MMM yyyy').format(date);
      case 'weekly':
        final weekOfMonth = ((date.day - 1) / 7).floor() + 1;
        return 'Week $weekOfMonth, ${DateFormat('MMM yyyy').format(date)}';
      case 'daily':
      case 'twice_daily':
        return DateFormat('d MMM yyyy').format(date);
      case 'every_15_days':
        final half = date.day <= 15 ? '1st half' : '2nd half';
        return '$half ${DateFormat('MMM yyyy').format(date)}';
      default:
        return DateFormat('MMM d, yyyy').format(date);
    }
  }

  /// Check if a draw's date falls within the selected period.
  bool _drawMatchesPeriod(Map<String, dynamic> draw, String period, String frequency) {
    final drawDateStr = draw['draw_date'] as String? ?? draw['created_at'] as String?;
    if (drawDateStr == null) return false;
    try {
      final drawDate = DateTime.parse(drawDateStr);
      switch (frequency) {
        case 'monthly':
          final parsed = DateFormat('MMM yyyy').parse(period);
          return drawDate.month == parsed.month && drawDate.year == parsed.year;
        case 'weekly':
          final match = RegExp(r'Week (\d+), (.+)$').firstMatch(period);
          if (match == null) return false;
          final weekNum = int.parse(match.group(1)!);
          final monthYear = DateFormat('MMM yyyy').parse(match.group(2)!);
          if (drawDate.month != monthYear.month || drawDate.year != monthYear.year) return false;
          final drawWeek = ((drawDate.day - 1) / 7).floor() + 1;
          return drawWeek == weekNum;
        case 'daily':
        case 'twice_daily':
          final parsed = DateFormat('d MMM yyyy').parse(period);
          return drawDate.year == parsed.year && drawDate.month == parsed.month && drawDate.day == parsed.day;
        case 'every_15_days':
          final match = RegExp(r'(1st|2nd) half (.+)$').firstMatch(period);
          if (match == null) return false;
          final half = match.group(1)!;
          final monthYear = DateFormat('MMM yyyy').parse(match.group(2)!);
          if (drawDate.month != monthYear.month || drawDate.year != monthYear.year) return false;
          final inFirstHalf = drawDate.day <= 15;
          return (half == '1st' && inFirstHalf) || (half == '2nd' && !inFirstHalf);
        default:
          return false;
      }
    } catch (e) {
      return false;
    }
  }

  /// Get period options from draws for the selected frequency (after group filter).
  List<String> get _availablePeriods {
    final baseFiltered = _selectedGroupId != null
        ? _allDraws.where((d) => d['kuri_group_id'] == _selectedGroupId).toList()
        : List<Map<String, dynamic>>.from(_allDraws);
    if (_selectedFrequency == 'all') return [];
    final periods = baseFiltered
        .map((d) {
          final dateStr = d['draw_date'] as String? ?? d['created_at'] as String?;
          if (dateStr == null) return null;
          try {
            final date = DateTime.parse(dateStr);
            return _formatDateForFrequency(date, _selectedFrequency);
          } catch (e) {
            return null;
          }
        })
        .whereType<String>()
        .toSet()
        .toList();
    periods.sort((a, b) {
      try {
        final dateA = _parsePeriodToDate(a, _selectedFrequency);
        final dateB = _parsePeriodToDate(b, _selectedFrequency);
        return dateB.compareTo(dateA);
      } catch (e) {
        return 0;
      }
    });
    return periods;
  }

  DateTime _parsePeriodToDate(String period, String frequency) {
    switch (frequency) {
      case 'monthly':
        return DateFormat('MMM yyyy').parse(period);
      case 'weekly':
        final match = RegExp(r'Week (\d+), (.+)$').firstMatch(period);
        if (match == null) throw FormatException('Invalid period');
        final weekNum = int.parse(match.group(1)!);
        final monthYear = DateFormat('MMM yyyy').parse(match.group(2)!);
        return DateTime(monthYear.year, monthYear.month, (weekNum - 1) * 7 + 1);
      case 'daily':
      case 'twice_daily':
        return DateFormat('d MMM yyyy').parse(period);
      case 'every_15_days':
        final match = RegExp(r'(1st|2nd) half (.+)$').firstMatch(period);
        if (match == null) throw FormatException('Invalid period');
        final monthYear = DateFormat('MMM yyyy').parse(match.group(2)!);
        final day = match.group(1) == '1st' ? 1 : 16;
        return DateTime(monthYear.year, monthYear.month, day);
      default:
        throw FormatException('Unknown frequency');
    }
  }

  List<Map<String, dynamic>> get _filteredDraws {
    List<Map<String, dynamic>> filtered = List.from(_allDraws);

    // Filter by group
    if (_selectedGroupId != null) {
      filtered = filtered.where((draw) => draw['kuri_group_id'] == _selectedGroupId).toList();
    }

    // Filter by frequency + period
    if (_selectedFrequency != 'all' &&
        _selectedPeriod != null &&
        _selectedPeriod != 'all') {
      filtered = filtered.where((draw) => _drawMatchesPeriod(draw, _selectedPeriod!, _selectedFrequency)).toList();
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
              child: Column(
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Frequency',
                              style: TextStyle(
                                fontSize: responsive.fontSize(12),
                                fontWeight: FontWeight.w500,
                                color: Color(0xFFA5A5A5),
                                fontFamily: 'DM Sans',
                              ),
                            ),
                            SizedBox(height: responsive.spacing(6)),
                            _buildFrequencyFilterDropdown(context),
                          ],
                        ),
                      ),
                      SizedBox(width: responsive.spacing(12)),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Period',
                              style: TextStyle(
                                fontSize: responsive.fontSize(12),
                                fontWeight: FontWeight.w500,
                                color: Color(0xFFA5A5A5),
                                fontFamily: 'DM Sans',
                              ),
                            ),
                            SizedBox(height: responsive.spacing(6)),
                            _buildPeriodFilterDropdown(context),
                          ],
                        ),
                      ),
                    ],
                  ),
                  SizedBox(height: responsive.spacing(12)),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Group',
                        style: TextStyle(
                          fontSize: responsive.fontSize(12),
                          fontWeight: FontWeight.w500,
                          color: Color(0xFFA5A5A5),
                          fontFamily: 'DM Sans',
                        ),
                      ),
                      SizedBox(height: responsive.spacing(6)),
                      _buildGroupFilterDropdown(context),
                    ],
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

  static const Map<String, String> _frequencyLabels = {
    'all': 'All',
    'monthly': 'Monthly',
    'weekly': 'Weekly',
    'daily': 'Daily',
    'every_15_days': 'Every 15 days',
    'twice_daily': 'Twice daily',
  };

  Widget _buildFrequencyFilterDropdown(BuildContext context) {
    final responsive = Responsive(context);
    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFF232220),
        borderRadius: BorderRadius.circular(responsive.radius(12)),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          value: _selectedFrequency,
          isExpanded: true,
          padding: responsive.paddingSymmetric(horizontal: 16, vertical: 14),
          hint: Text(
            'Frequency',
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
          items: _frequencyLabels.entries.map((e) {
            return DropdownMenuItem<String>(
              value: e.key,
              child: Text(e.value),
            );
          }).toList(),
          onChanged: (value) {
            setState(() {
              _selectedFrequency = value ?? 'all';
              _selectedPeriod = null;
            });
          },
        ),
      ),
    );
  }

  Widget _buildPeriodFilterDropdown(BuildContext context) {
    final responsive = Responsive(context);
    final periods = _availablePeriods;
    final isDisabled = _selectedFrequency == 'all' || periods.isEmpty;
    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFF232220),
        borderRadius: BorderRadius.circular(responsive.radius(12)),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          value: _selectedPeriod ?? 'all',
          isExpanded: true,
          padding: responsive.paddingSymmetric(horizontal: 16, vertical: 14),
          hint: Text(
            'Period',
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
          items: [
            const DropdownMenuItem<String>(value: 'all', child: Text('All')),
            ...periods.map((p) => DropdownMenuItem<String>(value: p, child: Text(p, overflow: TextOverflow.ellipsis))),
          ],
          onChanged: isDisabled
              ? null
              : (value) {
                  setState(() {
                    _selectedPeriod = value == 'all' ? null : value;
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

    // Group draws by period (format depends on selected frequency or default to date)
    final Map<String, List<Map<String, dynamic>>> grouped = {};
    final groupFreq = _selectedFrequency;
    for (var draw in _filteredDraws) {
      final drawDateStr = draw['draw_date'] as String? ?? draw['created_at'] as String?;
      if (drawDateStr != null) {
        try {
          final date = DateTime.parse(drawDateStr);
          final formattedDate = groupFreq == 'all'
              ? DateFormat('MMM d, yyyy').format(date)
              : _formatDateForFrequency(date, groupFreq);
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

    // Sort period labels (most recent first)
    final groupFreq = _selectedFrequency;
    final sortedDates = grouped.keys.toList()..sort((a, b) {
      try {
        final dateA = groupFreq == 'all'
            ? DateFormat('MMM d, yyyy').parse(a)
            : _parsePeriodToDate(a, groupFreq);
        final dateB = groupFreq == 'all'
            ? DateFormat('MMM d, yyyy').parse(b)
            : _parsePeriodToDate(b, groupFreq);
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
        final displayDateStr = draw['draw_date'] as String? ?? draw['created_at'] as String?;
        final collectionPeriod = draw['collection_period'] as String?;
        final frequencyInDays = draw['frequency_in_days'] as num?;

        sections.add(
          _buildWinnerCard(
            context: context,
            winnerName: winnerName,
            groupName: groupName,
            drawType: drawType,
            displayDateStr: displayDateStr,
            collectionPeriod: collectionPeriod,
            frequencyInDays: frequencyInDays,
          ),
        );
        sections.add(SizedBox(height: responsive.spacing(12)));
      }
    }

    return sections;
  }

  /// Format the draw date for display based on kuri frequency.
  /// - Monthly: "Feb 2026"
  /// - Daily / Twice daily: "26 Feb 2026"
  /// - Weekly: "Week 4, Feb 2026"
  /// - Every 15 days: "1st half Feb 2026" or "2nd half Feb 2026"
  String _formatDrawDateForDisplay(
    DateTime date, {
    String? collectionPeriod,
    num? frequencyInDays,
  }) {
    final cp = (collectionPeriod ?? '').toLowerCase();
    final freq = frequencyInDays?.toDouble();

    // Twice daily (0.5) or Daily (1): show day, month, year
    if (freq != null && freq <= 1) {
      return DateFormat('d MMM yyyy').format(date);
    }
    // Weekly (7): show week, month, year
    if ((freq != null && freq <= 7) || cp == 'weekly') {
      final weekOfMonth = ((date.day - 1) / 7).floor() + 1;
      return 'Week $weekOfMonth, ${DateFormat('MMM yyyy').format(date)}';
    }
    // Every 15 days: show 1st/2nd half, month, year
    if (freq != null && freq <= 15) {
      final half = date.day <= 15 ? '1st half' : '2nd half';
      return '$half ${DateFormat('MMM yyyy').format(date)}';
    }
    // Monthly or default: show month, year
    return DateFormat('MMM yyyy').format(date);
  }

  Widget _buildWinnerCard({
    required BuildContext context,
    required String winnerName,
    required String groupName,
    required String drawType,
    String? displayDateStr,
    String? collectionPeriod,
    num? frequencyInDays,
  }) {
    final responsive = Responsive(context);
    String dateTimeText = '';
    if (displayDateStr != null) {
      try {
        final date = DateTime.parse(displayDateStr);
        dateTimeText = _formatDrawDateForDisplay(
          date,
          collectionPeriod: collectionPeriod,
          frequencyInDays: frequencyInDays,
        );
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
                if (dateTimeText.isNotEmpty) ...[
                  SizedBox(height: responsive.spacing(2)),
                  Text(
                    '$drawTypeText • $dateTimeText',
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

