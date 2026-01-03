import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'chat_screen.dart';
import 'member_details.dart';

class GroupDetailsScreen extends StatefulWidget {
  final String groupName;
  final int memberCount;

  const GroupDetailsScreen({
    super.key,
    required this.groupName,
    this.memberCount = 10,
  });

  @override
  State<GroupDetailsScreen> createState() => _GroupDetailsScreenState();
}

class _GroupDetailsScreenState extends State<GroupDetailsScreen> {
  int _selectedTab = 0; // 0 for Members, 1 for Agents

  // Sample member data
  final List<Map<String, String>> _members = [
    {'name': 'Dennis Callis', 'role': 'Admin', 'initial': 'D'},
    {'name': 'Jerry Helfer', 'role': 'Member', 'initial': 'J'},
    {'name': 'Daniel Hamilton', 'role': 'Member', 'initial': 'D'},
    {'name': 'Autumn Phillips', 'role': 'Member', 'initial': 'A'},
  ];

  // Sample contact data for the add member modal
  final List<Map<String, dynamic>> _contacts = [
    {'name': 'Dennis Callis', 'initial': 'D', 'selected': false},
    {'name': 'Jerry Helfer', 'initial': 'J', 'selected': false},
    {'name': 'Daniel Hamilton', 'initial': 'D', 'selected': false},
    {'name': 'Autumn Phillips', 'initial': 'A', 'selected': false},
  ];

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
                            '${widget.memberCount} member',
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
              child: ListView.builder(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                itemCount: _members.length,
                itemBuilder: (context, index) {
                  final member = _members[index];
                  return _buildMemberItem(
                    name: member['name']!,
                    role: member['role']!,
                    initial: member['initial']!,
                    avatarColor: _getAvatarColor(index),
                  );
                },
              ),
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

  Widget _buildMemberItem({
    required String name,
    required String role,
    required String initial,
    required Color avatarColor,
  }) {
    return InkWell(
      onTap: () {
        Navigator.of(context).push(
          MaterialPageRoute(
            builder: (context) => MemberDetailsScreen(
              memberName: name,
              memberRole: role,
              memberInitial: initial,
              avatarColor: avatarColor,
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
                _showMemberMenu(context, name);
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

  void _showMemberMenu(BuildContext context, String memberName) {
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
              _buildMenuOption(
                label: 'Edit',
                onTap: () {
                  Navigator.pop(context);
                  // Handle edit action
                },
              ),
              _buildMenuOption(
                label: 'Remove',
                onTap: () {
                  Navigator.pop(context);
                  // Handle remove action
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

  void _showAddMemberModal(BuildContext context) {
    final TextEditingController nameController = TextEditingController();
    final TextEditingController phoneController = TextEditingController();
    final List<Map<String, dynamic>> contacts = _contacts.map((contact) => {
      'name': contact['name'],
      'initial': contact['initial'],
      'selected': false,
    }).toList();

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
                          const Text(
                            'Select from Contact',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                              color: Colors.white,
                              fontFamily: 'DM Sans',
                            ),
                          ),
                          const SizedBox(height: 16),
                          // Contact List
                          ...contacts.asMap().entries.map((entry) {
                            final index = entry.key;
                            final contact = entry.value;
                            return _buildContactItem(
                              name: contact['name'],
                              initial: contact['initial'],
                              avatarColor: _getAvatarColor(index),
                              isSelected: contact['selected'],
                              onTap: () {
                                setModalState(() {
                                  contacts[index]['selected'] = !contacts[index]['selected'];
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
                        onPressed: () {
                          // Handle save action
                          final selectedContacts = contacts.where((c) => c['selected'] == true).toList();
                          final name = nameController.text.trim();
                          final phone = phoneController.text.trim();
                          
                          // TODO: Implement save member logic
                          // For now, just close the modal
                          if (name.isNotEmpty || phone.isNotEmpty || selectedContacts.isNotEmpty) {
                            // Member data collected, ready to save
                            // You can add logic here to save the member
                          }
                          Navigator.pop(context);
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