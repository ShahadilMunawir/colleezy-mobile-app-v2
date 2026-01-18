import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import '../services/api_service.dart';
import 'member_details.dart';

class AgentMembersScreen extends StatefulWidget {
  final int groupId;
  final String groupName;
  final int agentUserId;
  final String agentName;
  final String agentInitial;
  final Color avatarColor;

  const AgentMembersScreen({
    super.key,
    required this.groupId,
    required this.groupName,
    required this.agentUserId,
    required this.agentName,
    required this.agentInitial,
    required this.avatarColor,
  });

  @override
  State<AgentMembersScreen> createState() => _AgentMembersScreenState();
}

class _AgentMembersScreenState extends State<AgentMembersScreen> {
  final ApiService _apiService = ApiService();
  List<Map<String, dynamic>> _members = [];
  bool _isLoading = true;
  String? _errorMessage;
  bool _currentUserIsAgent = false;

  // Color palette for avatars
  final List<Color> _avatarColors = [
    const Color(0xFF556B2F), // Dark olive green
    const Color(0xFF7B68EE), // Light purple-blue
    const Color(0xFF8B4513), // Dark reddish-brown
    const Color(0xFF90EE90), // Light green
    const Color(0xFF4682B4), // Steel blue
    const Color(0xFFCD5C5C), // Indian red
    const Color(0xFF20B2AA), // Light sea green
    const Color(0xFF9370DB), // Medium purple
  ];

  Color _getAvatarColor(int index) {
    return _avatarColors[index % _avatarColors.length];
  }

  @override
  void initState() {
    super.initState();
    _loadMembers();
  }

  Future<void> _loadMembers() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      // Get all group members
      final allMembers = await _apiService.getGroupMembers(widget.groupId);
      
      // Filter members that belong to this agent
      // Members assigned to this agent (agent_id == widget.agentUserId) and non-agent members
      final agentMembers = allMembers.where((member) {
        final isAgent = member['is_agent'] as bool? ?? false;
        final agentId = member['agent_id'] as int?;
        
        // Show members who:
        // 1. Are not agents themselves, AND
        // 2. Are assigned to this agent (agent_id matches)
        return !isAgent && agentId == widget.agentUserId;
      }).toList();

      // Check if current user is an agent
      bool isAgent = false;
      final currentUser = await _apiService.getCurrentUser();
      
      if (currentUser != null) {
        final currentUserId = currentUser['id'] as int?;
        if (currentUserId != null) {
          final currentUserMember = allMembers.firstWhere(
            (member) => member['user_id'] == currentUserId,
            orElse: () => <String, dynamic>{},
          );
          isAgent = currentUserMember['is_agent'] == true;
        }
      }

      if (mounted) {
        setState(() {
          _members = agentMembers;
          _isLoading = false;
          _currentUserIsAgent = isAgent;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _errorMessage = 'Failed to load members: ${e.toString()}';
          _isLoading = false;
        });
      }
    }
  }

  String _extractNameFromEmail(String email) {
    if (email == 'Unknown') return 'Unknown User';
    final parts = email.split('@');
    if (parts.isEmpty) return 'Unknown User';
    final username = parts[0];
    return username
        .split('.')
        .map((part) => part.isEmpty
            ? ''
            : part[0].toUpperCase() + part.substring(1))
        .join(' ');
  }

  String _getInitial(String name) {
    if (name.isEmpty) return '?';
    final parts = name.trim().split(' ');
    if (parts.length >= 2) {
      return (parts[0][0] + parts[1][0]).toUpperCase();
    }
    return name[0].toUpperCase();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF171717),
      floatingActionButton: _currentUserIsAgent
          ? FloatingActionButton(
              onPressed: () => _showAssignMemberDialog(context),
              backgroundColor: const Color(0xFF2D7A4F),
              child: const Icon(
                Icons.person_add,
                color: Colors.white,
              ),
            )
          : null,
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
                          Text(
                            widget.agentName,
                            style: const TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.w600,
                              color: Color(0xFFEFEEEC),
                              fontFamily: 'DM Sans',
                            ),
                            overflow: TextOverflow.ellipsis,
                            maxLines: 1,
                          ),
                          const SizedBox(height: 2),
                          Text(
                            'Agent in ${widget.groupName}',
                            style: const TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w400,
                              color: Color(0xFFA5A5A5),
                              fontFamily: 'DM Sans',
                            ),
                            overflow: TextOverflow.ellipsis,
                            maxLines: 1,
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
            // Members count header
            Padding(
              padding: const EdgeInsets.all(20),
              child: Row(
                children: [
                  Text(
                    '${_members.length} ${_members.length == 1 ? 'Member' : 'Members'}',
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: Color(0xFFD2D2D2),
                      fontFamily: 'DM Sans',
                    ),
                  ),
                ],
              ),
            ),
            // Members List
            Expanded(
              child: _buildMembersList(),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMembersList() {
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
              onPressed: _loadMembers,
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF2D7A4F),
              ),
              child: const Text('Retry'),
            ),
          ],
        ),
      );
    }

    if (_members.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: const [
            Icon(
              Icons.people_outline,
              size: 64,
              color: Color(0xFFA5A5A5),
            ),
            SizedBox(height: 16),
            Text(
              'No members yet',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w600,
                color: Color(0xFFF2F2F2),
              ),
            ),
            SizedBox(height: 8),
            Text(
              'Add members under this agent',
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w400,
                color: Color(0xFFA5A5A5),
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: _loadMembers,
      color: const Color(0xFF2D7A4F),
      child: ListView.builder(
        padding: const EdgeInsets.symmetric(horizontal: 20),
        itemCount: _members.length,
        itemBuilder: (context, index) {
          final member = _members[index];
          final email = member['user_email'] as String?;
          final name = member['user_name'] as String?;
          
          String displayName = name ?? 
                              (email != null && email.isNotEmpty ? _extractNameFromEmail(email) : 'Unknown User');
          final initial = _getInitial(displayName);
          final memberNumber = member['member_number'] as int? ?? (index + 1);
          
          return _buildMemberItem(
            userId: member['user_id'] as int,
            name: displayName,
            email: email ?? '',
            initial: initial,
            avatarColor: _getAvatarColor(index),
            memberNumber: memberNumber,
          );
        },
      ),
    );
  }

  Widget _buildMemberItem({
    required int userId,
    required String name,
    required String email,
    required String initial,
    required Color avatarColor,
    required int memberNumber,
  }) {
    return InkWell(
      onTap: () {
        Navigator.of(context).push(
          MaterialPageRoute(
            builder: (context) => MemberDetailsScreen(
              groupId: widget.groupId,
              memberUserId: userId,
              memberName: name,
              memberRole: 'Member',
              memberInitial: initial,
              avatarColor: avatarColor,
              currentUserIsAgent: _currentUserIsAgent,
            ),
          ),
        );
      },
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
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
            // Name and member number
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    name,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: Colors.white,
                      fontFamily: 'DM Sans',
                    ),
                    overflow: TextOverflow.ellipsis,
                    maxLines: 1,
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '#$memberNumber • Member',
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w400,
                      color: Color(0xFFA5A5A5),
                      fontFamily: 'DM Sans',
                    ),
                  ),
                ],
              ),
            ),
            // Chevron icon
            const Icon(
              Icons.chevron_right,
              color: Color(0xFFA5A5A5),
              size: 24,
            ),
          ],
        ),
      ),
    );
  }

  void _showAssignMemberDialog(BuildContext context) async {
    // Get all group members
    final allMembers = await _apiService.getGroupMembers(widget.groupId);
    
    // Filter unassigned members (not agents and not already assigned to an agent)
    final unassignedMembers = allMembers.where((member) {
      final isAgent = member['is_agent'] as bool? ?? false;
      final agentId = member['agent_id'] as int?;
      // Show members who are not agents and not assigned to any agent
      return !isAgent && agentId == null;
    }).toList();

    if (unassignedMembers.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('No unassigned members available'),
          backgroundColor: Color(0xFF2D7A4F),
          behavior: SnackBarBehavior.floating,
          margin: EdgeInsets.all(16),
        ),
      );
      return;
    }

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (BuildContext modalContext) {
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
              // Header
              Container(
                padding: const EdgeInsets.all(20),
                decoration: const BoxDecoration(
                  border: Border(
                    bottom: BorderSide(
                      color: Color(0xFF2A2A2A),
                      width: 1,
                    ),
                  ),
                ),
                child: Row(
                  children: [
                    const Text(
                      'Assign Member',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.w600,
                        color: Colors.white,
                        fontFamily: 'DM Sans',
                      ),
                    ),
                    const Spacer(),
                    IconButton(
                      icon: const Icon(
                        Icons.close,
                        color: Color(0xFFA5A5A5),
                      ),
                      onPressed: () => Navigator.pop(modalContext),
                    ),
                  ],
                ),
              ),
              // Members List
              Expanded(
                child: ListView.builder(
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                  itemCount: unassignedMembers.length,
                  itemBuilder: (context, index) {
                    final member = unassignedMembers[index];
                    final email = member['user_email'] as String?;
                    final name = member['user_name'] as String?;
                    
                    String displayName = name ?? 
                                        (email != null && email.isNotEmpty ? _extractNameFromEmail(email) : 'Unknown User');
                    final initial = _getInitial(displayName);
                    final memberNumber = member['member_number'] as int? ?? (index + 1);
                    
                    return InkWell(
                      onTap: () async {
                        // Show loading
                        showDialog(
                          context: modalContext,
                          barrierDismissible: false,
                          builder: (dialogContext) => const Center(
                            child: CircularProgressIndicator(
                              valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF2D7A4F)),
                            ),
                          ),
                        );
                        
                        try {
                          final result = await _apiService.assignMemberToAgent(
                            groupId: widget.groupId,
                            memberUserId: member['user_id'] as int,
                            agentId: widget.agentUserId,
                          );
                          
                          // Close loading and modal
                          if (mounted) Navigator.pop(modalContext);
                          if (mounted) Navigator.pop(modalContext);
                          
                          if (result != null) {
                            // Show success message
                            if (mounted) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: Text('Member assigned to ${widget.agentName}'),
                                  backgroundColor: const Color(0xFF2D7A4F),
                                  behavior: SnackBarBehavior.floating,
                                  margin: const EdgeInsets.all(16),
                                ),
                              );
                            }
                            
                            // Refresh members list
                            _loadMembers();
                          } else {
                            if (mounted) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                  content: Text('Failed to assign member. Please try again.'),
                                  backgroundColor: Colors.red,
                                  behavior: SnackBarBehavior.floating,
                                  margin: EdgeInsets.all(16),
                                ),
                              );
                            }
                          }
                        } catch (e) {
                          // Close loading and modal
                          if (mounted) Navigator.pop(modalContext);
                          if (mounted) Navigator.pop(modalContext);
                          
                          if (mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text('Error: ${e.toString()}'),
                                backgroundColor: Colors.red,
                                behavior: SnackBarBehavior.floating,
                                margin: const EdgeInsets.all(16),
                              ),
                            );
                          }
                        }
                      },
                      child: Container(
                        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
                        child: Row(
                          children: [
                            // Avatar
                            Container(
                              width: 48,
                              height: 48,
                              decoration: BoxDecoration(
                                color: _getAvatarColor(index),
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
                            // Name and member number
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    displayName,
                                    style: const TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.w600,
                                      color: Colors.white,
                                      fontFamily: 'DM Sans',
                                    ),
                                    overflow: TextOverflow.ellipsis,
                                    maxLines: 1,
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    '#$memberNumber • Unassigned',
                                    style: const TextStyle(
                                      fontSize: 14,
                                      fontWeight: FontWeight.w400,
                                      color: Color(0xFFA5A5A5),
                                      fontFamily: 'DM Sans',
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            // Chevron icon
                            const Icon(
                              Icons.chevron_right,
                              color: Color(0xFFA5A5A5),
                              size: 24,
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}
