import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'create_group.dart';
import 'group_details.dart';
import '../services/api_service.dart';

class GroupsScreen extends StatefulWidget {
  const GroupsScreen({super.key});

  @override
  State<GroupsScreen> createState() => _GroupsScreenState();
}

class _GroupsScreenState extends State<GroupsScreen> {
  final ApiService _apiService = ApiService();
  List<Map<String, dynamic>> _groups = [];
  bool _isLoading = true;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _loadGroups();
  }

  Future<void> _loadGroups() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final groups = await _apiService.getGroups();
      if (mounted) {
        setState(() {
          _groups = groups;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _errorMessage = 'Failed to load groups: ${e.toString()}';
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
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text(
                          'Groups',
                          style: TextStyle(
                            fontSize: 24,
                            fontWeight: FontWeight.w700,
                            color: Color(0xFFEFEEEC),
                          ),
                        ),
                        IconButton(
                          padding: EdgeInsets.zero,
                          icon: SvgPicture.asset(
                            'assets/svg/add.svg',
                            width: 24,
                            height: 24,
                            colorFilter: const ColorFilter.mode(
                              Colors.white,
                              BlendMode.srcIn,
                            ),
                          ),
                          onPressed: () async {
                            final result = await showModalBottomSheet<bool>(
                              context: context,
                              isScrollControlled: true,
                              backgroundColor: Colors.transparent,
                              builder: (context) => const CreateGroupScreen(),
                            );
                            
                            // Refresh groups list if a new group was created
                            if (result == true && mounted) {
                              _loadGroups();
                            }
                          },
                        ),
                      ],
                    ),
                  ),
                ),
                // Groups List
                Expanded(
                  child: _buildGroupsList(),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildGroupsList() {
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
              onPressed: _loadGroups,
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF2D7A4F),
              ),
              child: const Text('Retry'),
            ),
          ],
        ),
      );
    }

    if (_groups.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(
              Icons.group_outlined,
              size: 64,
              color: Color(0xFFC1BDB3),
            ),
            const SizedBox(height: 16),
            const Text(
              'No groups yet',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w600,
                color: Color(0xFFF2F2F2),
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              'Create your first group to get started',
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
      onRefresh: _loadGroups,
      color: const Color(0xFF2D7A4F),
      child: ListView.builder(
        padding: const EdgeInsets.all(20),
        itemCount: _groups.length,
        itemBuilder: (context, index) {
          final group = _groups[index];
          return Padding(
            padding: EdgeInsets.only(bottom: index < _groups.length - 1 ? 16 : 0),
            child: _buildGroupCard(
              groupId: group['id'] as int,
              title: group['name'] as String? ?? 'Unnamed Group',
              startingDate: group['starting_date'] as String?,
              totalAmount: (group['total_amount'] as num?)?.toDouble() ?? 0.0,
              amountPerPeriod: (group['amount_per_period'] as num?)?.toDouble() ?? 0.0,
              collectionPeriod: group['collection_period'] as String? ?? 'monthly',
            ),
          );
        },
      ),
    );
  }

  Widget _buildGroupCard({
    required int groupId,
    required String title,
    String? startingDate,
    required double totalAmount,
    required double amountPerPeriod,
    required String collectionPeriod,
  }) {
    // Format date if available
    String? formattedDate;
    if (startingDate != null) {
      try {
        final date = DateTime.parse(startingDate);
        formattedDate = '${date.month}/${date.day}/${date.year}';
      } catch (e) {
        formattedDate = startingDate;
      }
    }

    // Format collection period
    final periodText = collectionPeriod == 'weekly' ? 'Weekly' : 'Monthly';

    return InkWell(
      onTap: () {
        Navigator.of(context).push(
          MaterialPageRoute(
            builder: (context) => GroupDetailsScreen(
              groupId: groupId,
              groupName: title,
            ),
          ),
        );
      },
      borderRadius: BorderRadius.circular(16),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: const Color(0xFF232220),
          borderRadius: BorderRadius.circular(16),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Text(
                    title,
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w600,
                      color: Color(0xFFF2F2F2),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            if (formattedDate != null) ...[
              Text(
                'Starts: $formattedDate',
                style: const TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w400,
                  color: Color(0xFFC1BDB3),
                ),
              ),
              const SizedBox(height: 4),
            ],
            Row(
              children: [
                Text(
                  '\$${totalAmount.toStringAsFixed(2)}',
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                    color: Color(0xFF2D7A4F),
                  ),
                ),
                const SizedBox(width: 8),
                Text(
                  '• $periodText',
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w400,
                    color: Color(0xFFC1BDB3),
                  ),
                ),
                const SizedBox(width: 8),
                Text(
                  '• \$${amountPerPeriod.toStringAsFixed(2)}/period',
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w400,
                    color: Color(0xFFC1BDB3),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

