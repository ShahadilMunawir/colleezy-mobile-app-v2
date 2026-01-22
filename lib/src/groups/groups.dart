import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'create_group.dart';
import 'group_details.dart';
import '../services/api_service.dart';
import '../../utils/responsive.dart';

class GroupsScreen extends StatefulWidget {
  final int initialTab;
  const GroupsScreen({super.key, this.initialTab = 0});

  @override
  State<GroupsScreen> createState() => _GroupsScreenState();
}

class _GroupsScreenState extends State<GroupsScreen> {
  final ApiService _apiService = ApiService();
  List<Map<String, dynamic>> _allGroups = [];
  Map<int, bool> _userIsAgentInGroup = {}; // Cache for agent status per group
  late int _selectedTab; // 0 for Groups, 1 for As Members, 2 for As Agents
  bool _isLoading = true;
  String? _errorMessage;
  int? _currentUserId;

  @override
  void initState() {
    super.initState();
    _selectedTab = widget.initialTab;
    _loadGroups();
  }

  Future<void> _loadGroups() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      // Get current user ID
      final currentUser = await _apiService.getCurrentUser();
      if (currentUser != null) {
        _currentUserId = currentUser['id'] as int?;
      }

      // Load all groups
      final groups = await _apiService.getGroups();
      
      // Check agent status for each group
      final agentStatusMap = <int, bool>{};
      for (var group in groups) {
        final groupId = group['id'] as int;
        try {
          final members = await _apiService.getGroupMembers(groupId);
          if (_currentUserId != null) {
            final currentUserMember = members.firstWhere(
              (member) => member['user_id'] == _currentUserId,
              orElse: () => <String, dynamic>{},
            );
            agentStatusMap[groupId] = currentUserMember['is_agent'] == true;
          } else {
            agentStatusMap[groupId] = false;
          }
        } catch (e) {
          print('Error checking agent status for group $groupId: $e');
          agentStatusMap[groupId] = false;
        }
      }

      if (mounted) {
        setState(() {
          _allGroups = groups;
          _userIsAgentInGroup = agentStatusMap;
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

  List<Map<String, dynamic>> get _displayedGroups {
    if (_currentUserId == null) return [];
    
    if (_selectedTab == 0) {
      // Show groups where current user is owner (created_by_id matches current user)
      return _allGroups.where((group) {
        final createdById = group['created_by_id'] as int?;
        return createdById == _currentUserId;
      }).toList();
    } else if (_selectedTab == 1) {
      // Show groups where user is a member (not an agent) AND user is not the owner
      return _allGroups.where((group) {
        final groupId = group['id'] as int;
        final createdById = group['created_by_id'] as int?;
        // Exclude groups where user is the owner
        if (createdById == _currentUserId) return false;
        // Show only groups where user is a member but not an agent
        return _userIsAgentInGroup[groupId] == false;
      }).toList();
    } else {
      // Show groups where user is an agent (including groups where user is owner and agent)
      return _allGroups.where((group) {
        final groupId = group['id'] as int;
        // Show groups where user is an agent (can be owner or not)
        return _userIsAgentInGroup[groupId] == true;
      }).toList();
    }
  }

  @override
  Widget build(BuildContext context) {
    final responsive = Responsive(context);
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
                  decoration: BoxDecoration(
                    color: Color(0xFF141414),
                    borderRadius: BorderRadius.only(
                      bottomLeft: Radius.circular(responsive.radius(24)),
                      bottomRight: Radius.circular(responsive.radius(24)),
                    ),
                  ),
                  child: Padding(
                    padding: responsive.paddingFromLTRB(20, 16, 20, 20),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'Groups',
                          style: TextStyle(
                            fontSize: responsive.fontSize(24),
                            fontWeight: FontWeight.w700,
                            color: Color(0xFFEFEEEC),
                          ),
                        ),
                        IconButton(
                          padding: EdgeInsets.zero,
                          icon: SvgPicture.asset(
                            'assets/svg/add.svg',
                            width: responsive.width(24),
                            height: responsive.height(24),
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
                // Tabs
                Container(
                  padding: responsive.paddingSymmetric(horizontal: 20, vertical: 16),
                  child: Container(
                    decoration: BoxDecoration(
                      color: Color(0xFF121212),
                      borderRadius: BorderRadius.circular(responsive.radius(30)),
                    ),
                    child: Row(
                      children: [
                        Expanded(
                          child: _buildTab(context, 'My Groups', 0),
                        ),
                        Expanded(
                          child: _buildTab(context, 'As Members', 1),
                        ),
                        Expanded(
                          child: _buildTab(context, 'As Agents', 2),
                        ),
                      ],
                    ),
                  ),
                ),
                // Groups List
                Expanded(
                  child: _buildGroupsList(context),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildGroupsList(BuildContext context) {
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
              style: TextStyle(
                color: Colors.red,
                fontSize: responsive.fontSize(14),
              ),
              textAlign: TextAlign.center,
            ),
            SizedBox(height: responsive.spacing(16)),
            ElevatedButton(
              onPressed: _loadGroups,
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF2D7A4F),
              ),
              child: Text('Retry'),
            ),
          ],
        ),
      );
    }

    final displayedGroups = _displayedGroups;

    if (displayedGroups.isEmpty) {
      String emptyMessage;
      if (_selectedTab == 0) {
        emptyMessage = 'No groups created yet';
      } else if (_selectedTab == 1) {
        emptyMessage = 'No groups as member';
      } else {
        emptyMessage = 'No groups as agent';
      }

      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.group_outlined,
              size: responsive.width(64),
              color: Color(0xFFC1BDB3),
            ),
            SizedBox(height: responsive.spacing(16)),
            Text(
              emptyMessage,
              style: TextStyle(
                fontSize: responsive.fontSize(18),
                fontWeight: FontWeight.w600,
                color: Color(0xFFF2F2F2),
              ),
            ),
            SizedBox(height: responsive.spacing(8)),
            Text(
              'Create your first group to get started',
              style: TextStyle(
                fontSize: responsive.fontSize(14),
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
        padding: responsive.paddingAll(20),
        itemCount: displayedGroups.length,
        itemBuilder: (context, index) {
          final group = displayedGroups[index];
          return Padding(
            padding: EdgeInsets.only(bottom: index < displayedGroups.length - 1 ? responsive.spacing(16) : 0),
            child: _buildGroupCard(
              context: context,
              groupId: group['id'] as int,
              title: group['name'] as String? ?? 'Unnamed Group',
            ),
          );
        },
      ),
    );
  }

  Widget _buildGroupCard({
    required BuildContext context,
    required int groupId,
    required String title,
  }) {
    final responsive = Responsive(context);
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
      borderRadius: BorderRadius.circular(responsive.radius(16)),
      child: Container(
        width: double.infinity,
        padding: responsive.paddingAll(20),
        decoration: BoxDecoration(
          color: Color(0xFF232220),
          borderRadius: BorderRadius.circular(responsive.radius(16)),
        ),
        child: Text(
          title,
          style: TextStyle(
            fontSize: responsive.fontSize(18),
            fontWeight: FontWeight.w600,
            color: Color(0xFFF2F2F2),
          ),
        ),
      ),
    );
  }

  Widget _buildTab(BuildContext context, String label, int index) {
    final responsive = Responsive(context);
    final isSelected = _selectedTab == index;
    return GestureDetector(
      onTap: () {
        setState(() {
          _selectedTab = index;
        });
      },
      child: Container(
        padding: responsive.paddingSymmetric(vertical: 12),
        decoration: BoxDecoration(
          color: isSelected ? Color(0xCC232220) : Colors.transparent,
          borderRadius: BorderRadius.circular(responsive.radius(30)),
        ),
        child: Center(
          child: Text(
            label,
            style: TextStyle(
              fontSize: responsive.fontSize(16),
              fontWeight: FontWeight.w600,
              color: isSelected ? Colors.white : Color(0xFFA5A5A5),
              fontFamily: 'DM Sans',
            ),
          ),
        ),
      ),
    );
  }
}

