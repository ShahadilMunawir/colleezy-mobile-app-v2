import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:flutter_contacts/flutter_contacts.dart';
import 'package:permission_handler/permission_handler.dart';
import 'chat_screen.dart';
import 'member_details.dart';
import '../services/api_service.dart';

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
                          Text(
                            widget.groupName,
                            style: const TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.w600,
                              color: Color(0xFFEFEEEC),
                              fontFamily: 'DM Sans',
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
                    // Edit icon
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
                      onPressed: () {
                        Navigator.of(context).push(
                          MaterialPageRoute(
                            builder: (context) => ChatScreen(
                              groupName: widget.groupName,
                            ),
                          ),
                        );
                      },
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
            // Add Member Button
            Container(
              padding: const EdgeInsets.all(20),
              child: Center(
                child: IntrinsicWidth(
                    child: ElevatedButton(
                    onPressed: () {
                      _showAddMemberModal(context);
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
                        const Text(
                          'Add Member',
                          style: TextStyle(
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
          
          // Use provided name, or extract from email, or use "Unknown User"
          String displayName = name ?? 
                              (email != null && email.isNotEmpty ? _extractNameFromEmail(email) : 'Unknown User');
          final initial = _getInitial(displayName);
          
          return _buildMemberItem(
            memberId: member['id'] as int,
            userId: member['user_id'] as int,
            name: displayName,
            email: email ?? '',
            role: isAgent ? 'Agent' : 'Member',
            initial: initial,
            avatarColor: _getAvatarColor(index),
            isAgent: isAgent,
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
  }) {
    return InkWell(
      onTap: () {
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
            // Name and role
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
                    role,
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

  void _showMemberMenu(BuildContext context, String memberName, int memberId, int userId, bool isAgent) {
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
              if (!isAgent && _currentUserIsAgent)
                _buildMenuOption(
                  label: 'Make Agent',
                  onTap: () {
                    Navigator.pop(context);
                    _makeMemberAgent(userId);
                  },
                ),
              _buildMenuOption(
                label: 'Remove',
                onTap: () {
                  Navigator.pop(context);
                  // TODO: Implement remove member functionality
                  // _removeMember(memberId, userId);
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
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
        child: Row(
          children: [
            Container(
              width: 40,
              height: 20,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(
                  color: Colors.white,
                  width: 2,
                ),
              ),
              child: Center(
                child: Container(
                  width: 16,
                  height: 4,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
            ),
            const SizedBox(width: 16),
            Text(
              label,
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
    final Map<Contact, bool> selectedContacts = {};
    
    // Load contacts if not already loaded
    if (_deviceContacts.isEmpty && !_contactsLoading) {
      _loadContacts();
    }

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (BuildContext context) {
        return StatefulBuilder(
          builder: (context, setModalState) {
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
                          onPressed: () => Navigator.pop(context),
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
                          // Phone Input
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
                              color: const Color(0xFF141414),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: TextField(
                              controller: phoneController,
                              keyboardType: TextInputType.phone,
                              style: const TextStyle(
                                color: Colors.white,
                                fontFamily: 'DM Sans',
                              ),
                              decoration: const InputDecoration(
                                hintText: 'Enter Phone Number',
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
                          else
                            ..._deviceContacts.asMap().entries.map((entry) {
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
                          
                          // Validate input
                          if (name.isEmpty && phone.isEmpty && selectedContactsList.isEmpty) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text('Please enter name and phone, or select from contacts'),
                                backgroundColor: Colors.red,
                              ),
                            );
                            return;
                          }
                          
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
                            
                            // Handle manual entry
                            if (name.isNotEmpty && phone.isNotEmpty) {
                              // Format phone number
                              String formattedPhone = phone.replaceAll(RegExp(r'[^\d+]'), '');
                              if (!formattedPhone.startsWith('+')) {
                                formattedPhone = '+$formattedPhone';
                              }
                              
                              final result = await _apiService.addMemberToGroup(
                                groupId: widget.groupId,
                                phone: formattedPhone,
                                name: name,
                              );
                              
                              if (result != null) {
                                successCount++;
                              } else {
                                failCount++;
                              }
                            } else if (phone.isNotEmpty) {
                              // Phone only
                              String formattedPhone = phone.replaceAll(RegExp(r'[^\d+]'), '');
                              if (!formattedPhone.startsWith('+')) {
                                formattedPhone = '+$formattedPhone';
                              }
                              
                              final result = await _apiService.addMemberToGroup(
                                groupId: widget.groupId,
                                phone: formattedPhone,
                                name: name.isNotEmpty ? name : 'Unknown',
                              );
                              
                              if (result != null) {
                                successCount++;
                              } else {
                                failCount++;
                              }
                            }
                            
                            // Close loading dialog
                            if (mounted) Navigator.pop(context);
                            
                            if (successCount > 0) {
                              // Close add member modal
                              if (mounted) Navigator.pop(context);
                              
                              // Show success message
                              if (mounted) {
                                String message = 'Successfully invited $successCount member(s)';
                                if (failCount > 0) {
                                  message += '. $failCount invitation(s) failed.';
                                }
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(
                                    content: Text(message),
                                    backgroundColor: const Color(0xFF2D7A4F),
                                  ),
                                );
                              }
                              
                              // Refresh members list
                              _loadMembers();
                            } else {
                              if (mounted) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(
                                    content: Text('Failed to invite member(s). Please try again.'),
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
}