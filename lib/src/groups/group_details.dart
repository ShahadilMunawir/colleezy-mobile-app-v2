import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:flutter_contacts/flutter_contacts.dart';
import 'package:permission_handler/permission_handler.dart';
import 'chat_screen.dart';
import 'member_details.dart';
import 'group_info_screen.dart';
import 'agent_members_screen.dart';
import '../services/api_service.dart';

/// Country data for the country code picker
class _Country {
  final String name;
  final String code;
  final String dialCode;
  final String flag;
  final int phoneLength;

  const _Country({
    required this.name,
    required this.code,
    required this.dialCode,
    required this.flag,
    required this.phoneLength,
  });
}

const List<_Country> _countries = [
  _Country(name: 'United States', code: 'US', dialCode: '+1', flag: '🇺🇸', phoneLength: 10),
  _Country(name: 'United Kingdom', code: 'GB', dialCode: '+44', flag: '🇬🇧', phoneLength: 10),
  _Country(name: 'India', code: 'IN', dialCode: '+91', flag: '🇮🇳', phoneLength: 10),
  _Country(name: 'Canada', code: 'CA', dialCode: '+1', flag: '🇨🇦', phoneLength: 10),
  _Country(name: 'Australia', code: 'AU', dialCode: '+61', flag: '🇦🇺', phoneLength: 9),
  _Country(name: 'Germany', code: 'DE', dialCode: '+49', flag: '🇩🇪', phoneLength: 11),
  _Country(name: 'France', code: 'FR', dialCode: '+33', flag: '🇫🇷', phoneLength: 9),
  _Country(name: 'Japan', code: 'JP', dialCode: '+81', flag: '🇯🇵', phoneLength: 10),
  _Country(name: 'China', code: 'CN', dialCode: '+86', flag: '🇨🇳', phoneLength: 11),
  _Country(name: 'Brazil', code: 'BR', dialCode: '+55', flag: '🇧🇷', phoneLength: 11),
  _Country(name: 'Mexico', code: 'MX', dialCode: '+52', flag: '🇲🇽', phoneLength: 10),
  _Country(name: 'South Korea', code: 'KR', dialCode: '+82', flag: '🇰🇷', phoneLength: 10),
  _Country(name: 'Italy', code: 'IT', dialCode: '+39', flag: '🇮🇹', phoneLength: 10),
  _Country(name: 'Spain', code: 'ES', dialCode: '+34', flag: '🇪🇸', phoneLength: 9),
  _Country(name: 'Netherlands', code: 'NL', dialCode: '+31', flag: '🇳🇱', phoneLength: 9),
  _Country(name: 'Singapore', code: 'SG', dialCode: '+65', flag: '🇸🇬', phoneLength: 8),
  _Country(name: 'UAE', code: 'AE', dialCode: '+971', flag: '🇦🇪', phoneLength: 9),
  _Country(name: 'Saudi Arabia', code: 'SA', dialCode: '+966', flag: '🇸🇦', phoneLength: 9),
  _Country(name: 'South Africa', code: 'ZA', dialCode: '+27', flag: '🇿🇦', phoneLength: 9),
  _Country(name: 'Nigeria', code: 'NG', dialCode: '+234', flag: '🇳🇬', phoneLength: 10),
  _Country(name: 'Pakistan', code: 'PK', dialCode: '+92', flag: '🇵🇰', phoneLength: 10),
  _Country(name: 'Bangladesh', code: 'BD', dialCode: '+880', flag: '🇧🇩', phoneLength: 10),
  _Country(name: 'Indonesia', code: 'ID', dialCode: '+62', flag: '🇮🇩', phoneLength: 11),
  _Country(name: 'Philippines', code: 'PH', dialCode: '+63', flag: '🇵🇭', phoneLength: 10),
  _Country(name: 'Vietnam', code: 'VN', dialCode: '+84', flag: '🇻🇳', phoneLength: 9),
  _Country(name: 'Thailand', code: 'TH', dialCode: '+66', flag: '🇹🇭', phoneLength: 9),
  _Country(name: 'Malaysia', code: 'MY', dialCode: '+60', flag: '🇲🇾', phoneLength: 10),
  _Country(name: 'Russia', code: 'RU', dialCode: '+7', flag: '🇷🇺', phoneLength: 10),
  _Country(name: 'Turkey', code: 'TR', dialCode: '+90', flag: '🇹🇷', phoneLength: 10),
  _Country(name: 'Egypt', code: 'EG', dialCode: '+20', flag: '🇪🇬', phoneLength: 10),
];

class GroupDetailsScreen extends StatefulWidget {
  final int groupId;
  final String groupName;

  const GroupDetailsScreen({
    super.key,
    required this.groupId,
    required this.groupName,
  });

  @override
  State<GroupDetailsScreen> createState() => _GroupDetailsScreenState();
}

class _GroupDetailsScreenState extends State<GroupDetailsScreen> {
  final ApiService _apiService = ApiService();
  int _selectedTab = 0; // 0 for Members, 1 for Agents
  List<Map<String, dynamic>> _allMembers = [];
  bool _isLoading = true;
  String? _errorMessage;
  bool _currentUserIsAgent = false;

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
      final members = await _apiService.getGroupMembers(widget.groupId);
      
      // Check if current user is an agent
      bool isAgent = false;
      final currentUser = await _apiService.getCurrentUser();
      
      if (currentUser != null) {
        final currentUserId = currentUser['id'] as int?;
        if (currentUserId != null) {
          // Find current user in members list
          final currentUserMember = members.firstWhere(
            (member) => member['user_id'] == currentUserId,
            orElse: () => <String, dynamic>{},
          );
          isAgent = currentUserMember['is_agent'] == true;
        }
      }
      
      if (mounted) {
        setState(() {
          _allMembers = members;
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

  List<Map<String, dynamic>> get _displayedMembers {
    if (_selectedTab == 0) {
      // Show all members
      return _allMembers;
    } else {
      // Show only agents
      return _allMembers.where((member) => member['is_agent'] == true).toList();
    }
  }

  // Device contacts will be loaded dynamically
  List<Contact> _deviceContacts = [];
  bool _contactsLoading = false;

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
                          GestureDetector(
                            onTap: () {
                              Navigator.of(context).push(
                                MaterialPageRoute(
                                  builder: (context) => GroupInfoScreen(
                                    groupId: widget.groupId,
                                    groupName: widget.groupName,
                                  ),
                                ),
                              );
                            },
                            child: Text(
                              widget.groupName,
                              style: const TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.w600,
                                color: Color(0xFFEFEEEC),
                                fontFamily: 'DM Sans',
                              ),
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            '${_allMembers.length} ${_allMembers.length == 1 ? 'member' : 'members'}',
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
                  ],
                ),
              ),
            ),
            // Tabs
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
              child: Container(
                decoration: BoxDecoration(
                  color: const Color(0xFF121212),
                  borderRadius: BorderRadius.circular(30),
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: _buildTab('Members', 0),
                    ),
                    Expanded(
                      child: _buildTab('Agents', 1),
                    ),
                  ],
                ),
              ),
            ),
            // Members List
            Expanded(
              child: _buildMembersList(),
            ),
            // Add Member/Agent Button
            Container(
              padding: const EdgeInsets.all(20),
              child: Center(
                child: IntrinsicWidth(
                    child: ElevatedButton(
                    onPressed: () {
                      if (_selectedTab == 0) {
                        _showAddMemberModal(context);
                      } else {
                        _showAddAgentModal(context);
                      }
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF2D7A4F),
                      foregroundColor: Colors.white,
                      elevation: 0,
                      padding: const EdgeInsets.symmetric(
                        horizontal: 20,
                        vertical: 20,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(40),
                      ),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Container(
                          width: 24,
                          height: 24,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            border: Border.all(
                              color: Colors.white,
                              width: 2,
                            ),
                          ),
                          child: const Icon(
                            Icons.add,
                            size: 16,
                            color: Colors.white,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Text(
                          _selectedTab == 0 ? 'Add Member' : 'Add Agent',
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.w600,
                            fontFamily: 'DM Sans',
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
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

    if (_displayedMembers.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(
              Icons.people_outline,
              size: 64,
              color: Color(0xFFA5A5A5),
            ),
            const SizedBox(height: 16),
            Text(
              _selectedTab == 0 ? 'No members yet' : 'No agents yet',
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w600,
                color: Color(0xFFF2F2F2),
              ),
            ),
            const SizedBox(height: 8),
            Text(
              _selectedTab == 0
                  ? 'Add members to get started'
                  : 'No agents in this group',
              style: const TextStyle(
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
        itemCount: _displayedMembers.length,
        itemBuilder: (context, index) {
          final member = _displayedMembers[index];
          final email = member['user_email'] as String?;
          final name = member['user_name'] as String?;
          final isAgent = member['is_agent'] as bool? ?? false;
          final isOwner = member['is_owner'] as bool? ?? false;
          
          // Use provided name, or extract from email, or use "Unknown User"
          String displayName = name ?? 
                              (email != null && email.isNotEmpty ? _extractNameFromEmail(email) : 'Unknown User');
          final initial = _getInitial(displayName);
          
          final memberNumber = member['member_number'] as int? ?? (index + 1);
          
          // Determine the role to display
          String role;
          if (isOwner) {
            role = 'Owner';
          } else if (isAgent) {
            role = 'Agent';
          } else {
            role = 'Member';
          }
          
          return _buildMemberItem(
            memberId: member['id'] as int,
            userId: member['user_id'] as int,
            name: displayName,
            email: email ?? '',
            role: role,
            initial: initial,
            avatarColor: _getAvatarColor(index),
            isAgent: isAgent,
            memberNumber: memberNumber,
          );
        },
      ),
    );
  }

  String _extractNameFromEmail(String email) {
    if (email == 'Unknown') return 'Unknown User';
    final parts = email.split('@');
    if (parts.isEmpty) return 'Unknown User';
    final username = parts[0];
    // Convert email username to display name (e.g., "john.doe" -> "John Doe")
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

  Widget _buildMemberItem({
    required int memberId,
    required int userId,
    required String name,
    required String email,
    required String role,
    required String initial,
    required Color avatarColor,
    required bool isAgent,
    required int memberNumber,
  }) {
    return InkWell(
      onTap: () {
        // If in Agents tab and tapping an agent, navigate to AgentMembersScreen
        if (_selectedTab == 1 && isAgent) {
          Navigator.of(context).push(
            MaterialPageRoute(
              builder: (context) => AgentMembersScreen(
                groupId: widget.groupId,
                groupName: widget.groupName,
                agentUserId: userId,
                agentName: name,
                agentInitial: initial,
                avatarColor: avatarColor,
              ),
            ),
          );
        } else {
          // Otherwise, navigate to member details
          Navigator.of(context).push(
            MaterialPageRoute(
              builder: (context) => MemberDetailsScreen(
                groupId: widget.groupId,
                memberUserId: userId,
                memberName: name,
                memberRole: role,
                memberInitial: initial,
                avatarColor: avatarColor,
                currentUserIsAgent: _currentUserIsAgent,
              ),
            ),
          );
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
            // Name and role with member number
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
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '#$memberNumber • $role',
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
            // Three dots menu
            GestureDetector(
              onTap: () {
                _showMemberMenu(context, name, memberId, userId, isAgent);
              },
              behavior: HitTestBehavior.opaque,
              child: Container(
                padding: const EdgeInsets.all(8),
                child: const Icon(
                  Icons.more_vert,
                  color: Color(0xFFA5A5A5),
                  size: 24,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTab(String label, int index) {
    final isSelected = _selectedTab == index;
    return GestureDetector(
      onTap: () {
        setState(() {
          _selectedTab = index;
        });
      },
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12),
        decoration: BoxDecoration(
          color: isSelected ? const Color(0xCC232220) : Colors.transparent,
          borderRadius: BorderRadius.circular(30),
        ),
        child: Center(
          child: Text(
            label,
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: isSelected ? Colors.white : const Color(0xFFA5A5A5),
              fontFamily: 'DM Sans',
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _makeMemberAgent(int userId) async {
    // Show loading
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => const Center(
        child: CircularProgressIndicator(
          valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF2D7A4F)),
        ),
      ),
    );
    
    try {
      final result = await _apiService.makeMemberAgent(
        groupId: widget.groupId,
        userId: userId,
      );
      
      // Close loading dialog
      if (mounted) Navigator.pop(context);
      
      if (result != null) {
        // Show success message
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Member made agent successfully!'),
              backgroundColor: Color(0xFF2D7A4F),
            ),
          );
        }
        
        // Refresh members list
        _loadMembers();
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Failed to make member agent. Please try again.'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    } catch (e) {
      // Close loading dialog
      if (mounted) Navigator.pop(context);
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  void _confirmRemoveMember(String memberName, int userId) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          backgroundColor: const Color(0xFF171717),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          title: const Text(
            'Remove Member',
            style: TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.w600,
              fontFamily: 'DM Sans',
            ),
          ),
          content: Text(
            'Are you sure you want to remove $memberName from this group?',
            style: const TextStyle(
              color: Color(0xFFD0CDC6),
              fontFamily: 'DM Sans',
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text(
                'Cancel',
                style: TextStyle(
                  color: Color(0xFFA5A5A5),
                  fontFamily: 'DM Sans',
                ),
              ),
            ),
            TextButton(
              onPressed: () {
                Navigator.pop(context);
                _removeMember(userId);
              },
              child: const Text(
                'Remove',
                style: TextStyle(
                  color: Colors.red,
                  fontWeight: FontWeight.w600,
                  fontFamily: 'DM Sans',
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  Future<void> _removeMember(int userId) async {
    // Show loading
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => const Center(
        child: CircularProgressIndicator(
          valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF2D7A4F)),
        ),
      ),
    );
    
    try {
      final success = await _apiService.removeMemberFromGroup(
        groupId: widget.groupId,
        userId: userId,
      );
      
      // Close loading dialog
      if (mounted) Navigator.pop(context);
      
      if (success) {
        // Show success message
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Member removed successfully'),
              backgroundColor: Color(0xFF2D7A4F),
            ),
          );
        }
        
        // Refresh members list
        _loadMembers();
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Failed to remove member. Please try again.'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    } catch (e) {
      // Close loading dialog
      if (mounted) Navigator.pop(context);
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  void _showMemberMenu(BuildContext context, String memberName, int memberId, int userId, bool isAgent) {
    // Don't show menu if current user is not an agent
    if (!_currentUserIsAgent) {
      return;
    }
    
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (BuildContext context) {
        return Container(
          decoration: const BoxDecoration(
            color: Color(0xFF171717),
            borderRadius: BorderRadius.only(
              topLeft: Radius.circular(20),
              topRight: Radius.circular(20),
            ),
          ),
          padding: const EdgeInsets.symmetric(vertical: 16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Drag handle
              Container(
                margin: const EdgeInsets.only(top: 8, bottom: 16),
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: const Color(0xFF6B7280).withOpacity(0.3),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              if (!isAgent)
                _buildMenuOption(
                  label: 'Make Agent',
                  icon: Icons.admin_panel_settings,
                  onTap: () {
                    Navigator.pop(context);
                    _makeMemberAgent(userId);
                  },
                ),
              _buildMenuOption(
                label: 'Remove Member',
                icon: Icons.person_remove,
                isDestructive: true,
                onTap: () {
                  Navigator.pop(context);
                  _confirmRemoveMember(memberName, userId);
                },
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildMenuOption({
    required String label,
    required IconData icon,
    required VoidCallback onTap,
    bool isDestructive = false,
  }) {
    return InkWell(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
        child: Row(
          children: [
            Icon(
              icon,
              color: isDestructive ? Colors.red : Colors.white,
              size: 24,
            ),
            const SizedBox(width: 16),
            Text(
              label,
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: isDestructive ? Colors.red : Colors.white,
                fontFamily: 'DM Sans',
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _loadContacts() async {
    setState(() {
      _contactsLoading = true;
    });

    try {
      // Request permission
      final permission = await Permission.contacts.request();
      if (!permission.isGranted) {
        setState(() {
          _contactsLoading = false;
        });
        return;
      }

      // Load contacts with phone numbers
      final contacts = await FlutterContacts.getContacts(
        withProperties: true,
        withThumbnail: false,
      );

      // Filter contacts that have phone numbers
      final contactsWithPhones = contacts.where((contact) {
        return contact.phones.isNotEmpty;
      }).toList();

      setState(() {
        _deviceContacts = contactsWithPhones;
        _contactsLoading = false;
      });
    } catch (e) {
      print('Error loading contacts: $e');
      setState(() {
        _contactsLoading = false;
      });
    }
  }

  String _getContactInitial(Contact contact) {
    if (contact.displayName.isNotEmpty) {
      return contact.displayName[0].toUpperCase();
    }
    return '?';
  }

  String _getContactName(Contact contact) {
    return contact.displayName.isNotEmpty ? contact.displayName : 'Unknown';
  }

  String? _getContactPhone(Contact contact) {
    if (contact.phones.isNotEmpty) {
      return contact.phones.first.number;
    }
    return null;
  }

  void _showAddMemberModal(BuildContext context) {
    final TextEditingController nameController = TextEditingController();
    final TextEditingController phoneController = TextEditingController();
    final TextEditingController contactSearchController = TextEditingController();
    final Map<Contact, bool> selectedContacts = {};
    _Country selectedCountry = _countries[2]; // Default to India
    String contactSearchQuery = '';
    int? selectedAgentId; // Track selected agent
    
    // Get list of agents from current members
    final agents = _allMembers.where((member) => member['is_agent'] == true).toList();
    
    // Capture the parent scaffold messenger for showing SnackBars above the modal
    final scaffoldMessenger = ScaffoldMessenger.of(context);
    
    // Load contacts if not already loaded
    if (_deviceContacts.isEmpty && !_contactsLoading) {
      _loadContacts();
    }

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (BuildContext modalContext) {
        return StatefulBuilder(
          builder: (modalContext, setModalState) {
            
            // Filter contacts based on search query
            List<Contact> filteredContacts = contactSearchQuery.isEmpty
                ? _deviceContacts
                : _deviceContacts.where((contact) {
                    final name = _getContactName(contact).toLowerCase();
                    final phone = _getContactPhone(contact)?.toLowerCase() ?? '';
                    final query = contactSearchQuery.toLowerCase();
                    return name.contains(query) || phone.contains(query);
                  }).toList();
            
            void showCountryPicker() {
              showModalBottomSheet(
                context: context,
                backgroundColor: Colors.transparent,
                isScrollControlled: true,
                builder: (ctx) => _CountryPickerSheet(
                  countries: _countries,
                  selectedCountry: selectedCountry,
                  onSelect: (country) {
                    setModalState(() {
                      selectedCountry = country;
                    });
                    Navigator.pop(ctx);
                  },
                ),
              );
            }
            
            return Container(
              height: MediaQuery.of(context).size.height * 0.85,
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
                    child: Row(
                      children: [
                        const Text(
                          'Add Member',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.w600,
                            color: Colors.white,
                            fontFamily: 'DM Sans',
                          ),
                        ),
                        const Spacer(),
                        IconButton(
                          icon: const Icon(Icons.close, color: Colors.white),
                          onPressed: () => Navigator.pop(modalContext),
                        ),
                      ],
                    ),
                  ),
                  Expanded(
                    child: SingleChildScrollView(
                      padding: const EdgeInsets.symmetric(horizontal: 20),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Name Input
                          const Text(
                            'Name',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                              color: Colors.white,
                              fontFamily: 'DM Sans',
                            ),
                          ),
                          const SizedBox(height: 8),
                          Container(
                            decoration: BoxDecoration(
                              color: const Color(0xFF141414),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: TextField(
                              controller: nameController,
                              style: const TextStyle(
                                color: Colors.white,
                                fontFamily: 'DM Sans',
                              ),
                              decoration: const InputDecoration(
                                hintText: 'Enter Name',
                                hintStyle: TextStyle(
                                  color: Color(0xFFA5A5A5),
                                  fontFamily: 'DM Sans',
                                ),
                                border: InputBorder.none,
                                contentPadding: EdgeInsets.symmetric(
                                  horizontal: 16,
                                  vertical: 16,
                                ),
                                filled: true,
                                fillColor: Color(0xFF474540)
                              ),
                            ),
                          ),
                          const SizedBox(height: 20),
                          // Phone Input with Country Picker
                          const Text(
                            'Phone',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                              color: Colors.white,
                              fontFamily: 'DM Sans',
                            ),
                          ),
                          const SizedBox(height: 8),
                          Container(
                            decoration: BoxDecoration(
                              color: const Color(0xFF474540),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Row(
                              children: [
                                // Country Code Picker
                                GestureDetector(
                                  onTap: showCountryPicker,
                                  child: Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 16),
                                    decoration: const BoxDecoration(
                                      border: Border(
                                        right: BorderSide(
                                          color: Color(0xFF5A5A5A),
                                          width: 1,
                                        ),
                                      ),
                                    ),
                                    child: Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        Text(
                                          selectedCountry.flag,
                                          style: const TextStyle(fontSize: 16),
                                        ),
                                        const SizedBox(width: 3),
                                        Text(
                                          selectedCountry.dialCode,
                                          style: const TextStyle(
                                            color: Colors.white,
                                            fontSize: 13,
                                            fontWeight: FontWeight.w500,
                                            fontFamily: 'DM Sans',
                                          ),
                                        ),
                                        const Icon(
                                          Icons.keyboard_arrow_down_rounded,
                                          color: Color(0xFFA5A5A5),
                                          size: 16,
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                                // Phone Number Input
                                Expanded(
                                  child: TextField(
                                    controller: phoneController,
                                    keyboardType: TextInputType.phone,
                                    maxLength: selectedCountry.phoneLength,
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontFamily: 'DM Sans',
                                    ),
                                    decoration: InputDecoration(
                                      hintText: 'Phone (${selectedCountry.phoneLength} digits)',
                                      hintStyle: const TextStyle(
                                        color: Color(0xFFA5A5A5),
                                        fontFamily: 'DM Sans',
                                      ),
                                      border: InputBorder.none,
                                      counterText: '',
                                      filled: true,
                                      fillColor: Colors.transparent,
                                      contentPadding: const EdgeInsets.symmetric(
                                        horizontal: 12,
                                        vertical: 16,
                                      ),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 24),
                          // Agent Selection Dropdown
                          if (agents.isNotEmpty) ...[
                            const Text(
                              'Assign to Agent',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w600,
                                color: Colors.white,
                                fontFamily: 'DM Sans',
                              ),
                            ),
                            const SizedBox(height: 8),
                            Container(
                              decoration: BoxDecoration(
                                color: const Color(0xFF474540),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: DropdownButtonHideUnderline(
                                child: DropdownButton<int?>(
                                  value: selectedAgentId,
                                  isExpanded: true,
                                  dropdownColor: const Color(0xFF474540),
                                  icon: const Icon(
                                    Icons.keyboard_arrow_down_rounded,
                                    color: Color(0xFFA5A5A5),
                                  ),
                                  hint: const Padding(
                                    padding: EdgeInsets.symmetric(horizontal: 16),
                                    child: Text(
                                      'Select an agent',
                                      style: TextStyle(
                                        color: Color(0xFFA5A5A5),
                                        fontFamily: 'DM Sans',
                                      ),
                                    ),
                                  ),
                                  items: agents.map((agent) {
                                    final agentUserId = agent['user_id'] as int;
                                    final agentName = agent['user_name'] as String? ?? 
                                                      _extractNameFromEmail(agent['user_email'] as String? ?? 'Unknown');
                                    return DropdownMenuItem<int?>(
                                      value: agentUserId,
                                      child: Padding(
                                        padding: const EdgeInsets.symmetric(horizontal: 16),
                                        child: Text(
                                          agentName,
                                          style: const TextStyle(
                                            color: Colors.white,
                                            fontFamily: 'DM Sans',
                                          ),
                                        ),
                                      ),
                                    );
                                  }).toList(),
                                  onChanged: (value) {
                                    setModalState(() {
                                      selectedAgentId = value;
                                    });
                                  },
                                ),
                              ),
                            ),
                            const SizedBox(height: 24),
                          ] else ...[
                            Container(
                              padding: const EdgeInsets.all(16),
                              margin: const EdgeInsets.only(bottom: 24),
                              decoration: BoxDecoration(
                                color: const Color(0xFF2D7A4F).withOpacity(0.1),
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(
                                  color: const Color(0xFF2D7A4F).withOpacity(0.3),
                                ),
                              ),
                              child: Row(
                                children: [
                                  const Icon(
                                    Icons.info_outline_rounded,
                                    color: Color(0xFF2D7A4F),
                                    size: 20,
                                  ),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: const Text(
                                      'This will be the first member. They will be automatically promoted to an agent.',
                                      style: TextStyle(
                                        color: Colors.white,
                                        fontSize: 13,
                                        fontFamily: 'DM Sans',
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                          // Separator with "Or"
                          Row(
                            children: [
                              Expanded(
                                child: Container(
                                  height: 1,
                                  color: const Color(0xFF2E2E2E),
                                ),
                              ),
                              Padding(
                                padding: const EdgeInsets.symmetric(horizontal: 16),
                                child: const Text(
                                  'Or',
                                  style: TextStyle(
                                    fontSize: 14,
                                    fontWeight: FontWeight.w400,
                                    color: Color(0xFFA5A5A5),
                                    fontFamily: 'DM Sans',
                                  ),
                                ),
                              ),
                              Expanded(
                                child: Container(
                                  height: 1,
                                  color: const Color(0xFF2E2E2E),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 24),
                          // Select from Contact Section
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              const Text(
                                'Select from Contact',
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w600,
                                  color: Colors.white,
                                  fontFamily: 'DM Sans',
                                ),
                              ),
                              if (_contactsLoading)
                                const SizedBox(
                                  width: 20,
                                  height: 20,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                    valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF2D7A4F)),
                                  ),
                                )
                              else
                                TextButton(
                                  onPressed: () {
                                    _loadContacts();
                                    setModalState(() {});
                                  },
                                  child: const Text(
                                    'Refresh',
                                    style: TextStyle(
                                      color: Color(0xFF2D7A4F),
                                      fontFamily: 'DM Sans',
                                    ),
                                  ),
                                ),
                            ],
                          ),
                          const SizedBox(height: 12),
                          // Contact Search Field
                          Container(
                            decoration: BoxDecoration(
                              color: const Color(0xFF141414),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: TextField(
                              controller: contactSearchController,
                              onChanged: (value) {
                                setModalState(() {
                                  contactSearchQuery = value;
                                });
                              },
                              style: const TextStyle(
                                color: Colors.white,
                                fontFamily: 'DM Sans',
                              ),
                              decoration: const InputDecoration(
                                hintText: 'Search contacts...',
                                hintStyle: TextStyle(
                                  color: Color(0xFFA5A5A5),
                                  fontFamily: 'DM Sans',
                                ),
                                prefixIcon: Icon(
                                  Icons.search_rounded,
                                  color: Color(0xFFA5A5A5),
                                  size: 22,
                                ),
                                border: InputBorder.none,
                                filled: true,
                                fillColor: Color(0xFF474540),
                                contentPadding: EdgeInsets.symmetric(
                                  horizontal: 16,
                                  vertical: 14,
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(height: 16),
                          // Contact List
                          if (_contactsLoading)
                            const Center(
                              child: Padding(
                                padding: EdgeInsets.all(20.0),
                                child: CircularProgressIndicator(
                                  valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF2D7A4F)),
                                ),
                              ),
                            )
                          else if (_deviceContacts.isEmpty)
                            const Padding(
                              padding: EdgeInsets.all(20.0),
                              child: Text(
                                'No contacts found. Please grant contacts permission.',
                                style: TextStyle(
                                  color: Color(0xFFA5A5A5),
                                  fontFamily: 'DM Sans',
                                ),
                                textAlign: TextAlign.center,
                              ),
                            )
                          else if (filteredContacts.isEmpty)
                            const Padding(
                              padding: EdgeInsets.all(20.0),
                              child: Text(
                                'No contacts match your search.',
                                style: TextStyle(
                                  color: Color(0xFFA5A5A5),
                                  fontFamily: 'DM Sans',
                                ),
                                textAlign: TextAlign.center,
                              ),
                            )
                          else
                            ...filteredContacts.asMap().entries.map((entry) {
                              final index = entry.key;
                              final contact = entry.value;
                              final isSelected = selectedContacts[contact] ?? false;
                              return _buildContactItem(
                                name: _getContactName(contact),
                                initial: _getContactInitial(contact),
                                phone: _getContactPhone(contact),
                                avatarColor: _getAvatarColor(index),
                                isSelected: isSelected,
                                onTap: () {
                                  setModalState(() {
                                    selectedContacts[contact] = !isSelected;
                                  });
                                },
                              );
                            }),
                          const SizedBox(height: 20),
                        ],
                      ),
                    ),
                  ),
                  // Save Button
                  Container(
                    padding: const EdgeInsets.all(20),
                    child: SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: () async {
                          final selectedContactsList = selectedContacts.entries
                              .where((entry) => entry.value == true)
                              .map((entry) => entry.key)
                              .toList();
                          final name = nameController.text.trim();
                          final phone = phoneController.text.trim();
                          
                          // Check if manual entry is being used (either name or phone has value)
                          final isManualEntry = name.isNotEmpty || phone.isNotEmpty;
                          
                          // Helper function to show error toast above modal
                          void showErrorToast(String message) {
                            scaffoldMessenger.showSnackBar(
                              SnackBar(
                                content: Text(message),
                                backgroundColor: Colors.red,
                                behavior: SnackBarBehavior.floating,
                                margin: EdgeInsets.only(
                                  bottom: MediaQuery.of(modalContext).size.height * 0.88,
                                  left: 16,
                                  right: 16,
                                ),
                              ),
                            );
                          }
                          
                          // Validate input - need either manual entry OR selected contacts
                          if (!isManualEntry && selectedContactsList.isEmpty) {
                            showErrorToast('Please enter name and phone, or select from contacts');
                            return;
                          }
                          
                          // Validate agent selection if agents exist
                          if (agents.isNotEmpty && selectedAgentId == null) {
                            showErrorToast('Please select an agent to assign this member to');
                            return;
                          }
                          
                          // If manual entry, validate both name and phone are present
                          if (isManualEntry) {
                            if (name.isEmpty) {
                              showErrorToast('Please enter the member\'s name');
                              return;
                            }
                            
                            if (phone.isEmpty) {
                              showErrorToast('Please enter the member\'s phone number');
                              return;
                            }
                            
                            // Validate phone number format (should have at least 7 digits)
                            final cleanPhone = phone.replaceAll(RegExp(r'[^\d]'), '');
                            if (cleanPhone.length < 7) {
                              showErrorToast('Please enter a valid phone number (at least 7 digits)');
                              return;
                            }
                            
                            if (cleanPhone.length > 15) {
                              showErrorToast('Phone number is too long (maximum 15 digits)');
                              return;
                            }
                          }
                          
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
                            int successCount = 0;
                            int failCount = 0;
                            
                            // Handle selected contacts
                            for (var contact in selectedContactsList) {
                              final contactPhone = _getContactPhone(contact);
                              final contactName = _getContactName(contact);
                              
                              if (contactPhone != null && contactPhone.isNotEmpty) {
                                // Format phone number
                                String formattedPhone = contactPhone.replaceAll(RegExp(r'[^\d+]'), '');
                                if (!formattedPhone.startsWith('+')) {
                                  formattedPhone = '+$formattedPhone';
                                }
                                
                                try {
                                  final result = await _apiService.addMemberToGroup(
                                    groupId: widget.groupId,
                                    phone: formattedPhone,
                                    name: contactName,
                                    agentId: selectedAgentId,
                                  );
                                  
                                  if (result != null) {
                                    successCount++;
                                  } else {
                                    failCount++;
                                  }
                                } catch (e) {
                                  failCount++;
                                  print('Error inviting ${contactName}: $e');
                                }
                              }
                            }
                            
                            // Handle manual entry (both name and phone are required and validated above)
                            if (name.isNotEmpty && phone.isNotEmpty) {
                              // Format phone number with selected country code
                              String cleanPhone = phone.replaceAll(RegExp(r'[^\d]'), '');
                              String formattedPhone = '${selectedCountry.dialCode}$cleanPhone';
                              
                              final result = await _apiService.addMemberToGroup(
                                groupId: widget.groupId,
                                phone: formattedPhone,
                                name: name,
                                agentId: selectedAgentId,
                              );
                              
                              if (result != null) {
                                successCount++;
                              } else {
                                failCount++;
                              }
                            }
                            
                            // Close loading dialog
                            if (mounted) Navigator.pop(modalContext);
                            
                            if (successCount > 0) {
                              // Close add member modal
                              if (mounted) Navigator.pop(modalContext);
                              
                              // Show success message (modal is closed, so normal SnackBar is fine)
                              if (mounted) {
                                String message = 'Successfully invited $successCount member(s)';
                                if (failCount > 0) {
                                  message += '. $failCount invitation(s) failed.';
                                }
                                scaffoldMessenger.showSnackBar(
                                  SnackBar(
                                    content: Text(message),
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
                                showErrorToast('Failed to invite member(s). Please try again.');
                              }
                            }
                          } catch (e) {
                            // Close loading dialog
                            if (mounted) Navigator.pop(modalContext);
                            
                            if (mounted) {
                              showErrorToast('Error: ${e.toString()}');
                            }
                          }
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF2D7A4F),
                          foregroundColor: Colors.white,
                          elevation: 0,
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        child: const Text(
                          'Save',
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
          },
        );
      },
    );
  }

  void _showAddAgentModal(BuildContext context) {
    final TextEditingController nameController = TextEditingController();
    final TextEditingController phoneController = TextEditingController();
    final TextEditingController contactSearchController = TextEditingController();
    final Map<Contact, bool> selectedContacts = {};
    _Country selectedCountry = _countries[2]; // Default to India
    String contactSearchQuery = '';
    
    // Capture the parent scaffold messenger for showing SnackBars above the modal
    final scaffoldMessenger = ScaffoldMessenger.of(context);
    
    // Load contacts if not already loaded
    if (_deviceContacts.isEmpty && !_contactsLoading) {
      _loadContacts();
    }
    
    void showErrorToast(String message) {
      if (mounted) {
        scaffoldMessenger.showSnackBar(
          SnackBar(
            content: Text(message),
            backgroundColor: Colors.red,
            behavior: SnackBarBehavior.floating,
            margin: const EdgeInsets.all(16),
          ),
        );
      }
    }
    
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (BuildContext modalContext) {
        return StatefulBuilder(
          builder: (modalContext, setModalState) {
            
            // Filter contacts based on search query
            List<Contact> filteredContacts = contactSearchQuery.isEmpty
                ? _deviceContacts
                : _deviceContacts.where((contact) {
                    final name = _getContactName(contact).toLowerCase();
                    final phone = _getContactPhone(contact)?.toLowerCase() ?? '';
                    final query = contactSearchQuery.toLowerCase();
                    return name.contains(query) || phone.contains(query);
                  }).toList();
            
            void showCountryPicker() {
              showModalBottomSheet(
                context: context,
                backgroundColor: Colors.transparent,
                isScrollControlled: true,
                builder: (ctx) => _CountryPickerSheet(
                  countries: _countries,
                  selectedCountry: selectedCountry,
                  onSelect: (country) {
                    setModalState(() {
                      selectedCountry = country;
                    });
                    Navigator.pop(ctx);
                  },
                ),
              );
            }
            
            return Container(
              height: MediaQuery.of(context).size.height * 0.85,
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
                    child: Row(
                      children: [
                        const Text(
                          'Add Agent',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.w600,
                            color: Colors.white,
                            fontFamily: 'DM Sans',
                          ),
                        ),
                        const Spacer(),
                        IconButton(
                          icon: const Icon(Icons.close, color: Colors.white),
                          onPressed: () => Navigator.pop(modalContext),
                        ),
                      ],
                    ),
                  ),
                  // Content
                  Expanded(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 20),
                      child: SingleChildScrollView(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // Name Field
                            const Text(
                              'Name',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w600,
                                color: Colors.white,
                                fontFamily: 'DM Sans',
                              ),
                            ),
                            const SizedBox(height: 8),
                            Container(
                              decoration: BoxDecoration(
                                color: const Color(0xFF141414),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: TextField(
                                controller: nameController,
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontFamily: 'DM Sans',
                                ),
                                decoration: const InputDecoration(
                                  hintText: 'Enter Name',
                                  hintStyle: TextStyle(
                                    color: Color(0xFFA5A5A5),
                                    fontFamily: 'DM Sans',
                                  ),
                                  border: InputBorder.none,
                                  contentPadding: EdgeInsets.symmetric(
                                    horizontal: 16,
                                    vertical: 16,
                                  ),
                                  filled: true,
                                  fillColor: Color(0xFF474540)
                                ),
                              ),
                            ),
                            const SizedBox(height: 20),
                            // Phone Field with Country Picker
                            const Text(
                              'Phone',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w600,
                                color: Colors.white,
                                fontFamily: 'DM Sans',
                              ),
                            ),
                            const SizedBox(height: 8),
                            Container(
                              decoration: BoxDecoration(
                                color: const Color(0xFF474540),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Row(
                                children: [
                                  // Country Code Picker
                                  GestureDetector(
                                    onTap: showCountryPicker,
                                    child: Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 16),
                                      decoration: const BoxDecoration(
                                        border: Border(
                                          right: BorderSide(
                                            color: Color(0xFF5A5A5A),
                                            width: 1,
                                          ),
                                        ),
                                      ),
                                      child: Row(
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          Text(
                                            selectedCountry.flag,
                                            style: const TextStyle(fontSize: 16),
                                          ),
                                          const SizedBox(width: 3),
                                          Text(
                                            selectedCountry.dialCode,
                                            style: const TextStyle(
                                              color: Colors.white,
                                              fontSize: 13,
                                              fontWeight: FontWeight.w500,
                                              fontFamily: 'DM Sans',
                                            ),
                                          ),
                                          const Icon(
                                            Icons.keyboard_arrow_down_rounded,
                                            color: Color(0xFFA5A5A5),
                                            size: 16,
                                          ),
                                        ],
                                      ),
                                    ),
                                  ),
                                  // Phone Number Input
                                  Expanded(
                                    child: TextField(
                                      controller: phoneController,
                                      keyboardType: TextInputType.phone,
                                      maxLength: selectedCountry.phoneLength,
                                      style: const TextStyle(
                                        color: Colors.white,
                                        fontFamily: 'DM Sans',
                                      ),
                                      decoration: InputDecoration(
                                        hintText: 'Phone (${selectedCountry.phoneLength} digits)',
                                        hintStyle: const TextStyle(
                                          color: Color(0xFFA5A5A5),
                                          fontFamily: 'DM Sans',
                                        ),
                                        border: InputBorder.none,
                                        counterText: '',
                                        filled: true,
                                        fillColor: Colors.transparent,
                                        contentPadding: const EdgeInsets.symmetric(
                                          horizontal: 12,
                                          vertical: 16,
                                        ),
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(height: 24),
                            // Separator with "Or"
                            Row(
                              children: [
                                Expanded(
                                  child: Container(
                                    height: 1,
                                    color: const Color(0xFF2E2E2E),
                                  ),
                                ),
                                Padding(
                                  padding: const EdgeInsets.symmetric(horizontal: 16),
                                  child: const Text(
                                    'Or',
                                    style: TextStyle(
                                      fontSize: 14,
                                      fontWeight: FontWeight.w400,
                                      color: Color(0xFFA5A5A5),
                                      fontFamily: 'DM Sans',
                                    ),
                                  ),
                                ),
                                Expanded(
                                  child: Container(
                                    height: 1,
                                    color: const Color(0xFF2E2E2E),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 24),
                            // Select from Contact Section
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                const Text(
                                  'Select from Contact',
                                  style: TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.w600,
                                    color: Colors.white,
                                    fontFamily: 'DM Sans',
                                  ),
                                ),
                                if (_contactsLoading)
                                  const SizedBox(
                                    width: 20,
                                    height: 20,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                      valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF2D7A4F)),
                                    ),
                                  )
                                else
                                  TextButton(
                                    onPressed: () {
                                      _loadContacts();
                                      setModalState(() {});
                                    },
                                    child: const Text(
                                      'Refresh',
                                      style: TextStyle(
                                        color: Color(0xFF2D7A4F),
                                        fontFamily: 'DM Sans',
                                      ),
                                    ),
                                  ),
                              ],
                            ),
                            const SizedBox(height: 12),
                            // Contact Search Field
                            Container(
                              decoration: BoxDecoration(
                                color: const Color(0xFF141414),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: TextField(
                                controller: contactSearchController,
                                onChanged: (value) {
                                  setModalState(() {
                                    contactSearchQuery = value;
                                  });
                                },
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontFamily: 'DM Sans',
                                ),
                                decoration: const InputDecoration(
                                  hintText: 'Search contacts...',
                                  hintStyle: TextStyle(
                                    color: Color(0xFFA5A5A5),
                                    fontFamily: 'DM Sans',
                                  ),
                                  prefixIcon: Icon(
                                    Icons.search_rounded,
                                    color: Color(0xFFA5A5A5),
                                    size: 22,
                                  ),
                                  border: InputBorder.none,
                                  filled: true,
                                  fillColor: Color(0xFF474540),
                                  contentPadding: EdgeInsets.symmetric(
                                    horizontal: 16,
                                    vertical: 14,
                                  ),
                                ),
                              ),
                            ),
                            const SizedBox(height: 16),
                            // Contact List
                            if (_contactsLoading)
                              const Center(
                                child: Padding(
                                  padding: EdgeInsets.all(20.0),
                                  child: CircularProgressIndicator(
                                    valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF2D7A4F)),
                                  ),
                                ),
                              )
                            else if (_deviceContacts.isEmpty)
                              const Center(
                                child: Padding(
                                  padding: EdgeInsets.all(20.0),
                                  child: Text(
                                    'No contacts found. Please allow contact permission.',
                                    style: TextStyle(
                                      color: Color(0xFFA5A5A5),
                                      fontSize: 14,
                                      fontFamily: 'DM Sans',
                                    ),
                                  ),
                                ),
                              )
                            else if (filteredContacts.isEmpty)
                              const Center(
                                child: Padding(
                                  padding: EdgeInsets.all(20.0),
                                  child: Text(
                                    'No contacts found',
                                    style: TextStyle(
                                      color: Color(0xFFA5A5A5),
                                      fontSize: 14,
                                      fontFamily: 'DM Sans',
                                    ),
                                  ),
                                ),
                              )
                            else
                              Column(
                                children: [
                                  ...filteredContacts.map((contact) {
                                    final name = _getContactName(contact);
                                    final initial = _getContactInitial(contact);
                                    final phone = _getContactPhone(contact);
                                    final isSelected = selectedContacts[contact] ?? false;
                                    
                                    return _buildContactItem(
                                      name: name,
                                      initial: initial,
                                      avatarColor: _getAvatarColor(contact.hashCode % _avatarColors.length),
                                      isSelected: isSelected,
                                      onTap: () {
                                        setModalState(() {
                                          selectedContacts[contact] = !isSelected;
                                        });
                                      },
                                      phone: phone,
                                    );
                                  }).toList(),
                                ],
                              ),
                            const SizedBox(height: 24),
                          ],
                        ),
                      ),
                    ),
                  ),
                  // Save Button
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 20),
                    child: ElevatedButton(
                      onPressed: () async {
                        // Get selected contacts list
                        final selectedContactsList = selectedContacts.entries
                            .where((entry) => entry.value)
                            .map((entry) => entry.key)
                            .toList();
                        
                        // Validate inputs
                        if (nameController.text.trim().isEmpty && phoneController.text.trim().isEmpty && selectedContactsList.isEmpty) {
                          showErrorToast('Please enter a name and phone number, or select a contact');
                          return;
                        }
                        
                        if (nameController.text.trim().isEmpty && phoneController.text.trim().isNotEmpty) {
                          showErrorToast('Name is required when adding by phone');
                          return;
                        }
                        
                        // Validate manual entry if provided
                        String phone = phoneController.text.trim();
                        if (phone.isNotEmpty) {
                          // Remove all non-digit characters except +
                          String cleanPhone = phone.replaceAll(RegExp(r'[\D]+'), '');
                          
                          if (cleanPhone.isEmpty) {
                            showErrorToast('Please enter a valid phone number');
                            return;
                          }
                          
                          if (cleanPhone.length < 7) {
                            showErrorToast('Please enter a valid phone number (at least 7 digits)');
                            return;
                          }
                          
                          if (cleanPhone.length > 15) {
                            showErrorToast('Phone number is too long (maximum 15 digits)');
                            return;
                          }
                        }
                        
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
                          int successCount = 0;
                          int failCount = 0;
                          
                          // Handle selected contacts
                          for (var contact in selectedContactsList) {
                            final contactPhone = _getContactPhone(contact);
                            final contactName = _getContactName(contact);
                            
                            if (contactPhone != null && contactPhone.isNotEmpty) {
                              // Format phone number - keep only digits and +
                              String formattedPhone = contactPhone.replaceAll(RegExp(r'[^\d+]'), '');
                              if (!formattedPhone.startsWith('+')) {
                                formattedPhone = '+$formattedPhone';
                              }
                              
                              try {
                                final result = await _apiService.addMemberToGroup(
                                  groupId: widget.groupId,
                                  phone: formattedPhone,
                                  name: contactName,
                                );
                                
                                if (result != null) {
                                  // Make the member an agent
                                  final agentResult = await _apiService.makeMemberAgent(
                                    groupId: widget.groupId,
                                    userId: result['user_id'] as int,
                                  );
                                  
                                  if (agentResult != null) {
                                    successCount++;
                                  } else {
                                    failCount++;
                                  }
                                } else {
                                  failCount++;
                                }
                              } catch (e) {
                                failCount++;
                                print('Error adding ${contactName} as agent: $e');
                              }
                            }
                          }
                          
                          // Handle manual entry (both name and phone are required and validated above)
                          if (nameController.text.trim().isNotEmpty && phone.isNotEmpty) {
                            // Format phone number with selected country code
                            String cleanPhone = phone.replaceAll(RegExp(r'[^\d]'), '');
                            String formattedPhone = '${selectedCountry.dialCode}$cleanPhone';
                            
                            final result = await _apiService.addMemberToGroup(
                              groupId: widget.groupId,
                              phone: formattedPhone,
                              name: nameController.text.trim(),
                            );
                            
                            if (result != null) {
                              // Make the member an agent
                              final agentResult = await _apiService.makeMemberAgent(
                                groupId: widget.groupId,
                                userId: result['user_id'] as int,
                              );
                              
                              if (agentResult != null) {
                                successCount++;
                              } else {
                                failCount++;
                              }
                            } else {
                              failCount++;
                            }
                          }
                          
                          // Close loading dialog
                          if (mounted) Navigator.pop(modalContext);
                          
                          if (successCount > 0) {
                            // Close add agent modal
                            if (mounted) Navigator.pop(modalContext);
                            
                            // Show success message (modal is closed, so normal SnackBar is fine)
                            if (mounted) {
                              String message = 'Successfully added $successCount agent(s)';
                              if (failCount > 0) {
                                message += '. $failCount agent(s) failed.';
                              }
                              scaffoldMessenger.showSnackBar(
                                SnackBar(
                                  content: Text(message),
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
                              showErrorToast('Failed to add agent(s). Please try again.');
                            }
                          }
                        } catch (e) {
                          // Close loading dialog
                          if (mounted) Navigator.pop(modalContext);
                          
                          if (mounted) {
                            showErrorToast('Error: ${e.toString()}');
                          }
                        }
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF2D7A4F),
                        foregroundColor: Colors.white,
                        elevation: 0,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: const Text(
                        'Add Agent',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          fontFamily: 'DM Sans',
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }
  }

  Widget _buildContactItem({
    required String name,
    required String initial,
    required Color avatarColor,
    required bool isSelected,
    required VoidCallback onTap,
    String? phone,
  }) {
    return InkWell(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12),
        child: Row(
          children: [
            // Avatar
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: avatarColor,
                shape: BoxShape.circle,
              ),
              child: Center(
                child: Text(
                  initial,
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                    color: Colors.white,
                    fontFamily: 'DM Sans',
                  ),
                ),
              ),
            ),
            const SizedBox(width: 16),
            // Name and Phone
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
                  ),
                  if (phone != null && phone.isNotEmpty)
                    Text(
                      phone,
                      style: const TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w400,
                        color: Color(0xFFA5A5A5),
                        fontFamily: 'DM Sans',
                      ),
                    ),
                ],
              ),
            ),
            // Checkbox
            Container(
              width: 24,
              height: 24,
              decoration: BoxDecoration(
                border: Border.all(
                  color: isSelected ? const Color(0xFF2D7A4F) : const Color(0xFFA5A5A5),
                  width: 2,
                ),
                borderRadius: BorderRadius.circular(4),
                color: isSelected ? const Color(0xFF2D7A4F) : Colors.transparent,
              ),
              child: isSelected
                  ? const Icon(
                      Icons.check,
                      size: 16,
                      color: Colors.white,
                    )
                  : null,
            ),
          ],
        ),
      ),
    );
  }

/// Bottom sheet for selecting a country code
class _CountryPickerSheet extends StatefulWidget {
  final List<_Country> countries;
  final _Country selectedCountry;
  final ValueChanged<_Country> onSelect;

  const _CountryPickerSheet({
    required this.countries,
    required this.selectedCountry,
    required this.onSelect,
  });

  @override
  State<_CountryPickerSheet> createState() => _CountryPickerSheetState();
}

class _CountryPickerSheetState extends State<_CountryPickerSheet> {
  late TextEditingController _searchController;
  late List<_Country> _filteredCountries;

  @override
  void initState() {
    super.initState();
    _searchController = TextEditingController();
    _filteredCountries = widget.countries;
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _filterCountries(String query) {
    setState(() {
      if (query.isEmpty) {
        _filteredCountries = widget.countries;
      } else {
        _filteredCountries = widget.countries
            .where((c) =>
                c.name.toLowerCase().contains(query.toLowerCase()) ||
                c.dialCode.contains(query) ||
                c.code.toLowerCase().contains(query.toLowerCase()))
            .toList();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      height: MediaQuery.of(context).size.height * 0.65,
      decoration: const BoxDecoration(
        color: Color(0xFF2A2A2A),
        borderRadius: BorderRadius.only(
          topLeft: Radius.circular(24),
          topRight: Radius.circular(24),
        ),
      ),
      child: Column(
        children: [
          // Handle bar
          Container(
            margin: const EdgeInsets.only(top: 12),
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: const Color(0xFF6B7280),
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          // Title
          const Padding(
            padding: EdgeInsets.all(20),
            child: Text(
              'Select Country',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w600,
                color: Color(0xFFEFEEEC),
                fontFamily: 'DM Sans',
              ),
            ),
          ),
          // Search field
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Container(
              decoration: BoxDecoration(
                color: const Color(0xFF141414),
                borderRadius: BorderRadius.circular(12),
              ),
              child: TextField(
                controller: _searchController,
                onChanged: _filterCountries,
                style: const TextStyle(
                  color: Color(0xFFEFEEEC),
                  fontSize: 15,
                  fontFamily: 'DM Sans',
                ),
                decoration: InputDecoration(
                  hintText: 'Search country...',
                  hintStyle: const TextStyle(
                    color: Color(0xFFD0CDC6),
                    fontSize: 15,
                    fontWeight: FontWeight.w400,
                  ),
                  prefixIcon: const Icon(
                    Icons.search_rounded,
                    color: Color(0xFF6B7280),
                    size: 22,
                  ),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide.none,
                  ),
                  filled: true,
                  fillColor: Colors.transparent,
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 14,
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(height: 12),
          // Country list
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.symmetric(horizontal: 12),
              itemCount: _filteredCountries.length,
              itemBuilder: (context, index) {
                final country = _filteredCountries[index];
                final isSelected = country.code == widget.selectedCountry.code;
                
                return GestureDetector(
                  onTap: () => widget.onSelect(country),
                  child: Container(
                    margin: const EdgeInsets.symmetric(vertical: 2),
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                    decoration: BoxDecoration(
                      color: isSelected 
                          ? const Color(0xFF2D7A4F).withOpacity(0.15)
                          : Colors.transparent,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Row(
                      children: [
                        Text(
                          country.flag,
                          style: const TextStyle(fontSize: 24),
                        ),
                        const SizedBox(width: 14),
                        Expanded(
                          child: Text(
                            country.name,
                            style: TextStyle(
                              color: isSelected 
                                  ? const Color(0xFF2D7A4F) 
                                  : const Color(0xFFEFEEEC),
                              fontSize: 15,
                              fontWeight: isSelected ? FontWeight.w600 : FontWeight.w400,
                              fontFamily: 'DM Sans',
                            ),
                          ),
                        ),
                        Text(
                          country.dialCode,
                          style: TextStyle(
                            color: isSelected 
                                ? const Color(0xFF2D7A4F) 
                                : const Color(0xFFD0CDC6),
                            fontSize: 14,
                            fontWeight: FontWeight.w500,
                            fontFamily: 'DM Sans',
                          ),
                        ),
                        if (isSelected) ...[
                          const SizedBox(width: 10),
                          const Icon(
                            Icons.check_rounded,
                            color: Color(0xFF2D7A4F),
                            size: 20,
                          ),
                        ],
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
  }
}