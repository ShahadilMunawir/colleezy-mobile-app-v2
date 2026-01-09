import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:share_plus/share_plus.dart';
import '../groups/create_group.dart';
import '../profile/profile_screen.dart';
import '../winners/winners_screen.dart';
import '../services/api_service.dart';
import '../services/auth_service.dart';

class HomeScreen extends StatefulWidget {
  final Function(int tabIndex)? onNavigateToGroups;
  const HomeScreen({super.key, this.onNavigateToGroups});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  late PageController _pageController;
  int _currentPage = 0;
  final ApiService _apiService = ApiService();
  final AuthService _authService = AuthService();
  String? _userName;
  String? _userPhotoUrl;
  bool _isLoadingUser = true;
  List<Map<String, dynamic>> _nextPayments = []; // {groupId, groupName, nextPaymentDate, memberCount}
  bool _isLoadingGroups = true;
  int _totalGroupsCount = 0;
  int _memberGroupsCount = 0;
  int _agentGroupsCount = 0;
  bool _isLoadingCounts = true;

  @override
  void initState() {
    super.initState();
    _pageController = PageController(viewportFraction: 0.85);
    _pageController.addListener(() {
      final page = _pageController.page?.round() ?? 0;
      if (page != _currentPage) {
        setState(() {
          _currentPage = page;
        });
      }
    });
    _loadUserInfo();
    _loadGroupCounts();
    _loadNextPayments();
  }

  Future<void> _loadUserInfo() async {
    // Get Firebase user info
    final firebaseUser = _authService.currentUser;
    String? photoUrl = firebaseUser?.photoURL;
    String? displayName = firebaseUser?.displayName;

    // Get backend user info
    try {
      final backendUser = await _apiService.getCurrentUser();
      if (backendUser != null) {
        final backendName = backendUser['name'] as String?;
        if (backendName != null && backendName.isNotEmpty) {
          displayName = backendName;
        }
        
        // Check for backend photo_url (prioritize backend photo over Firebase)
        final backendPhotoUrl = backendUser['photo_url'] as String?;
        if (backendPhotoUrl != null && backendPhotoUrl.isNotEmpty) {
          // Convert relative URL to full URL if needed
          if (backendPhotoUrl.startsWith('/')) {
            photoUrl = '${ApiService.baseUrl.replaceAll('/api/v1', '')}$backendPhotoUrl';
          } else {
            photoUrl = backendPhotoUrl;
          }
        }
      }
    } catch (e) {
      print('Error loading backend user info: $e');
    }

    if (mounted) {
      setState(() {
        _userName = displayName ?? 'User';
        _userPhotoUrl = photoUrl;
        _isLoadingUser = false;
      });
    }
  }

  Future<void> _loadGroupCounts() async {
    setState(() {
      _isLoadingCounts = true;
    });

    try {
      // Get current user ID
      final currentUser = await _apiService.getCurrentUser();
      int? currentUserId;
      if (currentUser != null) {
        currentUserId = currentUser['id'] as int?;
      }

      // Load all groups
      final groups = await _apiService.getGroups();
      int totalCount = groups.length;
      int memberCount = 0;
      int agentCount = 0;

      // Check agent status for each group
      for (var group in groups) {
        final groupId = group['id'] as int;
        try {
          final members = await _apiService.getGroupMembers(groupId);
          if (currentUserId != null) {
            final currentUserMember = members.firstWhere(
              (member) => member['user_id'] == currentUserId,
              orElse: () => <String, dynamic>{},
            );
            if (currentUserMember.isNotEmpty) {
              if (currentUserMember['is_agent'] == true) {
                agentCount++;
              } else {
                memberCount++;
              }
            }
          }
        } catch (e) {
          print('Error checking agent status for group $groupId: $e');
        }
      }

      if (mounted) {
        setState(() {
          _totalGroupsCount = totalCount;
          _memberGroupsCount = memberCount;
          _agentGroupsCount = agentCount;
          _isLoadingCounts = false;
        });
      }
    } catch (e) {
      print('Error loading group counts: $e');
      if (mounted) {
        setState(() {
          _isLoadingCounts = false;
        });
      }
    }
  }

  Future<void> _loadNextPayments() async {
    setState(() {
      _isLoadingGroups = true;
    });

    try {
      final groups = await _apiService.getGroups();
      final nextPayments = <Map<String, dynamic>>[];
      
      for (var group in groups) {
        final groupId = group['id'] as int;
        try {
          final members = await _apiService.getGroupMembers(groupId);
          final memberCount = members.length;
          
          // Calculate next payment date (pass member count directly)
          final nextPayment = await _calculateNextPayment(group, groupId, memberCount);
          if (nextPayment != null) {
            nextPayments.add(nextPayment);
          }
        } catch (e) {
          print('Error loading members for group $groupId: $e');
        }
      }

      // Sort next payments by date (earliest first)
      nextPayments.sort((a, b) {
        final dateA = a['nextPaymentDate'] as DateTime;
        final dateB = b['nextPaymentDate'] as DateTime;
        return dateA.compareTo(dateB);
      });

      if (mounted) {
        setState(() {
          _nextPayments = nextPayments;
          _isLoadingGroups = false;
        });
      }
    } catch (e) {
      print('Error loading groups for next payments: $e');
      if (mounted) {
        setState(() {
          _isLoadingGroups = false;
        });
      }
    }
  }

  Future<Map<String, dynamic>?> _calculateNextPayment(Map<String, dynamic> group, int groupId, int memberCount) async {
    try {
      final startingDateStr = group['starting_date'] as String?;
      final collectionPeriod = group['collection_period'] as String?;
      
      if (startingDateStr == null || collectionPeriod == null) {
        return null;
      }

      // Parse starting date
      final startingDate = DateTime.parse(startingDateStr);
      final today = DateTime.now();
      
      // Get transactions for this group to find the last payment date
      DateTime lastPaymentDate = startingDate;
      try {
        // Get all transactions for this group (we'll get transactions for current user)
        final allTransactions = await _apiService.getAllTransactions(groupId: groupId);
        if (allTransactions.isNotEmpty) {
          // Find the most recent transaction date
          DateTime? mostRecentDate;
          for (var transaction in allTransactions) {
            final createdAt = transaction['created_at'] as String?;
            if (createdAt != null) {
              try {
                final transactionDate = DateTime.parse(createdAt);
                if (mostRecentDate == null || transactionDate.isAfter(mostRecentDate)) {
                  mostRecentDate = transactionDate;
                }
              } catch (e) {
                // Skip invalid dates
              }
            }
          }
          if (mostRecentDate != null) {
            lastPaymentDate = mostRecentDate;
          }
        }
      } catch (e) {
        print('Error fetching transactions for next payment calculation: $e');
        // Continue with starting date as fallback
      }
      
      // Calculate next payment date based on collection period
      DateTime nextPaymentDate;
      if (collectionPeriod == 'weekly') {
        // Find the next payment date (weekly from last payment)
        int weeksSinceLastPayment = today.difference(lastPaymentDate).inDays ~/ 7;
        nextPaymentDate = lastPaymentDate.add(Duration(days: (weeksSinceLastPayment + 1) * 7));
      } else if (collectionPeriod == 'monthly') {
        // Find the next payment date (monthly from last payment)
        int monthsSinceLastPayment = (today.year - lastPaymentDate.year) * 12 + (today.month - lastPaymentDate.month);
        nextPaymentDate = DateTime(lastPaymentDate.year, lastPaymentDate.month + monthsSinceLastPayment + 1, lastPaymentDate.day);
      } else {
        return null;
      }

      // Only show if next payment is in the future
      if (nextPaymentDate.isAfter(today) || nextPaymentDate.isAtSameMomentAs(today)) {
        final groupName = group['name'] as String? ?? 'Unnamed Group';
        
        return {
          'groupId': groupId,
          'groupName': groupName,
          'nextPaymentDate': nextPaymentDate,
          'memberCount': memberCount,
        };
      }
      
      return null;
    } catch (e) {
      print('Error calculating next payment for group $groupId: $e');
      return null;
    }
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  void _showInviteModal() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        decoration: const BoxDecoration(
          color: Color(0xFF2A2A2A),
          borderRadius: BorderRadius.only(
            topLeft: Radius.circular(30),
            topRight: Radius.circular(30),
          ),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Drag handle
            Container(
              margin: const EdgeInsets.only(top: 12, bottom: 8),
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: const Color(0xFF6B7280).withOpacity(0.3),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            // Header
            const Padding(
              padding: EdgeInsets.symmetric(horizontal: 20, vertical: 16),
              child: Text(
                'Invite Friends',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                  color: Color(0xFFE0DED9),
                  fontFamily: 'DM Sans',
                ),
              ),
            ),
            // Share button
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 20),
              child: SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () {
                    // Share the Play Store link
                    const playStoreLink = 'https://play.google.com/store/apps/details?id=com.colleezy.app';
                    const message = 'Check out Colleezy - Manage your group savings and kuri easily! Download now: $playStoreLink';
                    
                    Share.share(
                      message,
                      subject: 'Join me on Colleezy',
                    );
                    
                    Navigator.pop(context);
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF2D7A4F),
                    foregroundColor: Colors.white,
                    elevation: 0,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 20,
                      vertical: 16,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: const [
                      Icon(
                        Icons.share,
                        size: 20,
                      ),
                      SizedBox(width: 12),
                      Text(
                        'Share App Link',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          fontFamily: 'DM Sans',
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
            // Description
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Text(
                'Share the app with your friends and start managing groups together!',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w400,
                  color: const Color(0xFFA5A5A5),
                  fontFamily: 'DM Sans',
                ),
              ),
            ),
            const SizedBox(height: 30),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Color(0xFF7FDE68),
              Color(0xFF1B1F1A),
            ],
            stops: [0.0, 0.5],
          ),
        ),
        child: Stack(
          children: [
            SafeArea(
            child: CustomScrollView(
              physics: const BouncingScrollPhysics(
                parent: AlwaysScrollableScrollPhysics(),
              ),
              slivers: [
                // Header
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.all(20.0),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        GestureDetector(
                          onTap: () async {
                            await Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => const ProfileScreen(),
                              ),
                            );
                            // Refresh user info when returning from profile screen
                            _loadUserInfo();
                          },
                          child: Row(
                            children: [
                              _buildUserAvatar(),
                              const SizedBox(width: 12),
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const Text(
                                    'Hello,',
                                    style: TextStyle(
                                      fontSize: 13,
                                      color: Color(0xFFF2F2F2),
                                      fontWeight: FontWeight.w400,
                                    ),
                                  ),
                                  Text(
                                    _isLoadingUser ? 'Loading...' : _getDisplayName(),
                                    style: const TextStyle(
                                      fontSize: 16,
                                      color: Color(0xFFF2F2F2),
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                        SvgPicture.asset(
                          'assets/svg/bell.svg',
                          width: 22,
                          height: 22,
                          colorFilter: const ColorFilter.mode(
                            Colors.white,
                            BlendMode.srcIn,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                // Carousel
                SliverToBoxAdapter(
                  child: SizedBox(
                    height: 180,
                    child: PageView(
                      padEnds: false,
                      controller: _pageController,
                      onPageChanged: (index) {
                        setState(() {
                          _currentPage = index;
                        });
                      },
                      children: _buildCategoryCards(),
                    ),
                  ),
                ),
                const SliverToBoxAdapter(child: SizedBox(height: 16)),
                // Page indicator
                SliverToBoxAdapter(
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: List.generate(
                      3,
                      (index) => GestureDetector(
                        onTap: () {
                          _pageController.animateToPage(
                            index,
                            duration: const Duration(milliseconds: 300),
                            curve: Curves.easeInOut,
                          );
                        },
                        child: Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 3),
                          child: _buildDot(_currentPage == index),
                        ),
                      ),
                    ),
                  ),
                ),
                const SliverToBoxAdapter(child: SizedBox(height: 24)),
                // Wrapped section with top border radius
                SliverFillRemaining(
                  hasScrollBody: false,
                  child: Container(
                    width: double.infinity,
                    decoration: const BoxDecoration(
                      color: Color(0xFF2A2A2A),
                      borderRadius: BorderRadius.only(
                        topLeft: Radius.circular(30),
                        topRight: Radius.circular(30),
                      ),
                    ),
                    child: Column(
                      mainAxisSize: MainAxisSize.max,
                      children: [
                        // Action buttons
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 0),
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                              vertical: 20,
                              horizontal: 16,
                            ),

                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.spaceAround,
                              children: [
                                _buildActionButton(
                                  svgPath: 'assets/svg/create.svg',
                                  label: 'Create',
                                  color: const Color(0xFF2D7A4F),
                                  onTap: () async {
                                    final result = await showModalBottomSheet(
                                      context: context,
                                      isScrollControlled: true,
                                      backgroundColor: Colors.transparent,
                                      builder: (context) => const CreateGroupScreen(),
                                    );
                                    // Refresh counts and next payments if a new group was created
                                    if (result == true) {
                                      _loadGroupCounts();
                                      _loadNextPayments();
                                    }
                                  },
                                ),
                                _buildActionButton(
                                  svgPath: 'assets/svg/invite.svg',
                                  label: 'Invite',
                                  color: const Color(0xFF2D7A4F),
                                  onTap: _showInviteModal,
                                ),
                                _buildActionButton(
                                  svgPath: 'assets/svg/winnder.svg',
                                  label: 'Winner',
                                  color: const Color(0xFF2D7A4F),
                                  onTap: () {
                                    Navigator.push(
                                      context,
                                      MaterialPageRoute(
                                        builder: (context) => const WinnersScreen(),
                                      ),
                                    );
                                  },
                                ),
                                _buildActionButton(
                                  svgPath: 'assets/svg/support.svg',
                                  label: 'Support',
                                  color: const Color(0xFF2D7A4F),
                                ),
                              ],
                            ),
                          ),
                        ),
                        const SizedBox(height: 10),
                        // Quote card
                        Container(
                          padding: const EdgeInsets.symmetric(
                            vertical: 20,
                            horizontal: 40,
                          ),
                          decoration: BoxDecoration(
                            color: Color(0xFF141414),
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Column(
                            children: const [
                              Text(
                                'Dream Bid . Start small. Act now.',
                                textAlign: TextAlign.center,
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w600,
                                  color: Color(0xFFF2F2F2),
                                  height: 1.4,
                                ),
                              ),
                              SizedBox(height: 8),
                              Text(
                                '-Robin Sharma',
                                style: TextStyle(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w400,
                                  color: Color(0xFF136232),
                                ),
                              ),
                            ],
                          ),
                        ),
                        // const SizedBox(height: 24),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Padding(
                                padding: EdgeInsets.fromLTRB(24, 24, 24, 16),
                                child: Text(
                                  'Next Payment',
                                  style: TextStyle(
                                    fontSize: 18,
                                    fontWeight: FontWeight.w700,
                                    color: Color(0xFFD2D2D2),
                                  ),
                                ),
                              ),
                              Expanded(
                                child: Padding(
                                  padding: const EdgeInsets.fromLTRB(
                                    24,
                                    0,
                                    24,
                                    0,
                                  ),
                                  child: _buildNextPaymentsList(),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
        ),
      ),
    );
  }

  Widget _buildDot(bool isActive) {
    return Container(
      width: 8,
      height: 8,
      decoration: BoxDecoration(
        color: isActive ? const Color(0xFF6B7280) : const Color(0xFFD1D5DB),
        borderRadius: BorderRadius.circular(4),
      ),
    );
  }

  Widget _buildActionButton({
    required String svgPath,
    required String label,
    required Color color,
    VoidCallback? onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: Color(0xFF141414),
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.08),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: SvgPicture.asset(
              svgPath,
              width: 28,
              height: 28,
              colorFilter: ColorFilter.mode(
                color,
                BlendMode.srcIn,
              ),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            label,
            style: const TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: Color(0xFFD0CDC6),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildUserAvatar() {
    if (_userPhotoUrl != null && _userPhotoUrl!.isNotEmpty) {
      return Container(
        width: 44,
        height: 44,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: Colors.grey[300],
          image: DecorationImage(
            image: NetworkImage(_userPhotoUrl!),
            fit: BoxFit.cover,
            onError: (exception, stackTrace) {
              // If image fails to load, show placeholder
              setState(() {
                _userPhotoUrl = null;
              });
            },
          ),
        ),
      );
    } else {
      // Show placeholder with initial
      final initial = _getInitial(_userName ?? 'U');
      return Container(
        width: 44,
        height: 44,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: const Color(0xFF2D7A4F),
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
      );
    }
  }

  String _getDisplayName() {
    if (_userName == null || _userName!.isEmpty) {
      return 'User';
    }
    // Format name: capitalize first letter of each word
    final words = _userName!.split(' ');
    final formatted = words.map((word) {
      if (word.isEmpty) return word;
      return word[0].toUpperCase() + word.substring(1).toLowerCase();
    }).join(' ');
    return formatted;
  }

  String _getInitial(String name) {
    if (name.isEmpty) return 'U';
    final parts = name.trim().split(' ');
    if (parts.length >= 2) {
      return (parts[0][0] + parts[1][0]).toUpperCase();
    }
    return name[0].toUpperCase();
  }

  List<Widget> _buildCategoryCards() {
    return [
      CategoryCard(
        title: 'My Groups',
        description: 'All your groups',
        icon: Icons.group,
        isLast: false,
        count: _totalGroupsCount,
        isLoading: _isLoadingCounts,
        onTap: () {
          widget.onNavigateToGroups?.call(0);
        },
      ),
      CategoryCard(
        title: 'As Member',
        description: 'Groups you joined',
        icon: Icons.person,
        isLast: false,
        count: _memberGroupsCount,
        isLoading: _isLoadingCounts,
        onTap: () {
          widget.onNavigateToGroups?.call(1);
        },
      ),
      CategoryCard(
        title: 'As Agent',
        description: 'Groups you manage',
        icon: Icons.admin_panel_settings,
        isLast: true,
        count: _agentGroupsCount,
        isLoading: _isLoadingCounts,
        onTap: () {
          widget.onNavigateToGroups?.call(2);
        },
      ),
    ];
  }

  Widget _buildNextPaymentsList() {
    if (_isLoadingGroups) {
      return const Center(
        child: Padding(
          padding: EdgeInsets.all(20.0),
          child: CircularProgressIndicator(
            valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF2D7A4F)),
          ),
        ),
      );
    }

    if (_nextPayments.isEmpty) {
      return const Center(
        child: Padding(
          padding: EdgeInsets.all(20.0),
          child: Text(
            'No upcoming payments',
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w400,
              color: Color(0xFFA5A5A5),
            ),
          ),
        ),
      );
    }

    return Column(
      children: [
        ...List.generate(
          _nextPayments.length,
          (index) {
            final payment = _nextPayments[index];
            final nextPaymentDate = payment['nextPaymentDate'] as DateTime;
            final groupName = payment['groupName'] as String;
            final memberCount = payment['memberCount'] as int;
            
            // Format date as DD/MM/YYYY
            final formattedDate = '${nextPaymentDate.day.toString().padLeft(2, '0')}/${nextPaymentDate.month.toString().padLeft(2, '0')}/${nextPaymentDate.year}';
            final membersText = memberCount == 1 ? '1 member' : '$memberCount members';
            
            return Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: _buildPaymentItem(
                date: formattedDate,
                group: groupName,
                members: membersText,
              ),
            );
          },
        ),
      ],
    );
  }

  Widget _buildPaymentItem({
    required String date,
    required String group,
    required String members,
  }) {
    return Container(
      padding: const EdgeInsets.all(4),
      child: Row(
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: const Color(0xFF2D7A4F),
            ),
            child: const Icon(
              Icons.calendar_today,
              color: Colors.white,
              size: 20,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  date,
                  style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFFD2D2D2),
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  group,
                  style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w400,
                    color: Color(0xFFA5A5A5),
                  ),
                ),
              ],
            ),
          ),
          Text(
            members,
            style: const TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w500,
              color: Color(0xFFD2D2D2),
            ),
          ),
        ],
      ),
    );
  }

}

class CategoryCard extends StatelessWidget {
  final String title;
  final String description;
  final IconData icon;
  final bool isLast;
  final VoidCallback? onTap;
  final int? count;
  final bool isLoading;

  const CategoryCard({
    super.key,
    required this.title,
    required this.description,
    required this.icon,
    this.isLast = false,
    this.onTap,
    this.count,
    this.isLoading = false,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: isLast
            ? const EdgeInsets.symmetric(horizontal: 20)
            : const EdgeInsets.only(left: 20),
        width: double.infinity,
        height: 180,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(20),
          gradient: const LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [Color(0xFF5BBF7E), Color(0xFF3DA861)],
          ),
          boxShadow: [
            BoxShadow(
              color: const Color(0xFF3DA861).withOpacity(0.3),
              blurRadius: 16,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(20),
          child: Stack(
            children: [
              // Large decorative curved shape
              Positioned(
                right: -100,
                top: -50,
                child: Container(
                  width: 300,
                  height: 300,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: RadialGradient(
                      colors: [
                        Colors.white.withOpacity(0.15),
                        Colors.white.withOpacity(0.05),
                        Colors.transparent,
                      ],
                      stops: const [0.0, 0.5, 1.0],
                    ),
                  ),
                ),
              ),
              // Additional subtle circles for depth
              Positioned(
                left: -60,
                bottom: -80,
                child: Container(
                  width: 200,
                  height: 200,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: Colors.white.withOpacity(0.08),
                  ),
                ),
              ),
              // Content
              Padding(
                padding: const EdgeInsets.all(24.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          title,
                          style: const TextStyle(
                            fontSize: 24,
                            fontWeight: FontWeight.w700,
                            color: Colors.black87,
                            letterSpacing: -0.5,
                          ),
                          overflow: TextOverflow.ellipsis,
                          maxLines: 1,
                        ),
                        isLoading
                            ? const SizedBox(
                                width: 215,
                                height: 20,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  valueColor: AlwaysStoppedAnimation<Color>(Colors.black54),
                                ),
                              )
                            : Text(
                                count != null ? '$count Groups' : '0 Groups',
                                style: const TextStyle(
                                  fontSize: 32,
                                  fontWeight: FontWeight.w800,
                                  color: Colors.black87,
                                  letterSpacing: -0.8,
                                ),
                                overflow: TextOverflow.ellipsis,
                                maxLines: 1,
                              ),
                      ],
                    ),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Text(
                          description,
                          style: const TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w500,
                            color: Colors.black87,
                            letterSpacing: 0.2,
                          ),
                          overflow: TextOverflow.ellipsis,
                          maxLines: 1,
                        ),
                        Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.3),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Icon(
                            icon,
                            color: Colors.black87,
                            size: 28,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}