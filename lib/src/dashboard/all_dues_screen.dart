import 'package:flutter/material.dart';
import '../services/api_service.dart';
import '../groups/group_details.dart';
import '../groups/member_details.dart';

class AllDuesScreen extends StatefulWidget {
  const AllDuesScreen({super.key});

  @override
  State<AllDuesScreen> createState() => _AllDuesScreenState();
}

class _AllDuesScreenState extends State<AllDuesScreen> {
  final ApiService _apiService = ApiService();
  List<Map<String, dynamic>> _allDues = [];
  bool _isLoading = true;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _loadAllDues();
  }

  Future<void> _loadAllDues() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final dues = await _apiService.getAllMembersDueAmounts();
      if (mounted) {
        setState(() {
          _allDues = dues;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _errorMessage = 'Failed to load dues: ${e.toString()}';
          _isLoading = false;
        });
      }
    }
  }

  Map<String, List<Map<String, dynamic>>> get _groupedDues {
    final grouped = <String, List<Map<String, dynamic>>>{};
    
    for (var due in _allDues) {
      final groupName = due['group_name'] as String? ?? 'Unknown Group';
      if (!grouped.containsKey(groupName)) {
        grouped[groupName] = [];
      }
      grouped[groupName]!.add(due);
    }
    
    // Sort groups alphabetically
    final sortedGroups = grouped.keys.toList()..sort();
    final sortedGrouped = <String, List<Map<String, dynamic>>>{};
    for (var groupName in sortedGroups) {
      sortedGrouped[groupName] = grouped[groupName]!;
    }
    
    return sortedGrouped;
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
              ),
              child: Padding(
                padding: const EdgeInsets.fromLTRB(20, 16, 20, 20),
                child: Row(
                  children: [
                    GestureDetector(
                      onTap: () => Navigator.pop(context),
                      child: Container(
                        width: 40,
                        height: 40,
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.1),
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(
                          Icons.arrow_back,
                          color: Colors.white,
                          size: 24,
                        ),
                      ),
                    ),
                    const SizedBox(width: 16),
                    const Text(
                      'All Outstanding Dues',
                      style: TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.w700,
                        color: Color(0xFFEFEEEC),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            // Content
            Expanded(
              child: _buildContent(),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildContent() {
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
              style: const TextStyle(
                color: Colors.red,
                fontSize: 14,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: _loadAllDues,
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF2D7A4F),
              ),
              child: const Text('Retry'),
            ),
          ],
        ),
      );
    }

    final groupedDues = _groupedDues;

    if (groupedDues.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(
              Icons.check_circle_outline,
              size: 64,
              color: Color(0xFF2D7A4F),
            ),
            const SizedBox(height: 16),
            const Text(
              'No Outstanding Dues',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w600,
                color: Color(0xFFF2F2F2),
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              'All payments are up to date',
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w400,
                color: Color(0xFFC1BDB3),
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: _loadAllDues,
      color: const Color(0xFF2D7A4F),
      child: ListView.builder(
        padding: const EdgeInsets.all(20),
        itemCount: groupedDues.length,
        itemBuilder: (context, index) {
          final groupName = groupedDues.keys.elementAt(index);
          final dues = groupedDues[groupName]!;
          final groupId = dues.first['group_id'] as int?;
          
          return Padding(
            padding: EdgeInsets.only(bottom: index < groupedDues.length - 1 ? 20 : 0),
            child: _buildGroupCard(groupName, dues, groupId),
          );
        },
      ),
    );
  }

  Widget _buildGroupCard(String groupName, List<Map<String, dynamic>> dues, int? groupId) {
    // Calculate total due for this group
    double totalDue = 0.0;
    for (var due in dues) {
      final dueAmount = (due['due_amount'] as num?)?.toDouble() ?? 0.0;
      totalDue += dueAmount;
    }

    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFF232220),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Group Header
          InkWell(
            onTap: groupId != null
                ? () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => GroupDetailsScreen(
                          groupId: groupId,
                          groupName: groupName,
                        ),
                      ),
                    );
                  }
                : null,
            borderRadius: const BorderRadius.only(
              topLeft: Radius.circular(16),
              topRight: Radius.circular(16),
            ),
            child: Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: const Color(0xFF2A1F1A),
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(16),
                  topRight: Radius.circular(16),
                ),
                border: Border.all(
                  color: const Color(0xFFFF6B35),
                  width: 1,
                ),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          groupName,
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.w600,
                            color: Colors.white,
                            fontFamily: 'DM Sans',
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          '${dues.length} ${dues.length == 1 ? 'member' : 'members'} with dues',
                          style: const TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w400,
                            color: Color(0xFFA5A5A5),
                            fontFamily: 'DM Sans',
                          ),
                        ),
                      ],
                    ),
                  ),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      const Text(
                        'Total Due',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w400,
                          color: Color(0xFFA5A5A5),
                          fontFamily: 'DM Sans',
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        '₹${totalDue.toStringAsFixed(2)}',
                        style: const TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.w700,
                          color: Color(0xFFFF6B35),
                          fontFamily: 'DM Sans',
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
          // Members List
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: dues.map((due) => _buildMemberDueItem(due)).toList(),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMemberDueItem(Map<String, dynamic> due) {
    final memberName = due['member_name'] as String? ?? 'Unknown Member';
    final year = due['year'] as int? ?? 0;
    final month = due['month'] as int? ?? 0;
    final dueAmount = (due['due_amount'] as num?)?.toDouble() ?? 0.0;
    final totalCollected = (due['total_collected'] as num?)?.toDouble() ?? 0.0;
    final amountPerPeriod = (due['amount_per_period'] as num?)?.toDouble() ?? 0.0;
    final memberUserId = due['member_user_id'] as int?;
    final groupId = due['group_id'] as int?;
    
    final monthNames = [
      'January', 'February', 'March', 'April', 'May', 'June',
      'July', 'August', 'September', 'October', 'November', 'December'
    ];
    final monthName = month > 0 && month <= 12 ? monthNames[month - 1] : 'Unknown';
    
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFF1A1A1A),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  memberName,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: Colors.white,
                    fontFamily: 'DM Sans',
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  '$monthName $year',
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w400,
                    color: Color(0xFFA5A5A5),
                    fontFamily: 'DM Sans',
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Paid: ₹${totalCollected.toStringAsFixed(2)} / ₹${amountPerPeriod.toStringAsFixed(2)}',
                  style: const TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w400,
                    color: Color(0xFFC1BDB3),
                    fontFamily: 'DM Sans',
                  ),
                ),
              ],
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                '₹${dueAmount.toStringAsFixed(2)}',
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                  color: Color(0xFFFF6B35),
                  fontFamily: 'DM Sans',
                ),
              ),
              if (memberUserId != null && groupId != null)
                TextButton(
                  onPressed: () async {
                    await Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => MemberDetailsScreen(
                          groupId: groupId,
                          memberUserId: memberUserId,
                          memberName: memberName,
                          memberRole: 'member',
                          memberInitial: memberName.isNotEmpty ? memberName[0].toUpperCase() : '?',
                          avatarColor: Colors.blue,
                          currentUserIsAgent: true,
                          initialYear: year,
                          initialMonth: month,
                        ),
                      ),
                    );
                    // Refresh the page when returning
                    if (mounted) {
                      _loadAllDues();
                    }
                  },
                  style: TextButton.styleFrom(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    minimumSize: Size.zero,
                    tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                  ),
                  child: const Text(
                    'View',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: Color(0xFF2D7A4F),
                      fontFamily: 'DM Sans',
                    ),
                  ),
                ),
            ],
          ),
        ],
      ),
    );
  }
}
