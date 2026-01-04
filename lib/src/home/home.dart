import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import '../groups/create_group.dart';
import '../profile/profile_screen.dart';
import '../winners/winners_screen.dart';
import '../services/api_service.dart';
import '../services/auth_service.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

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
  List<Map<String, dynamic>> _groups = [];
  Map<int, int> _groupMemberCounts = {}; // groupId -> memberCount
  bool _isLoadingGroups = true;
  List<Map<String, dynamic>> _nextPayments = []; // {groupId, groupName, nextPaymentDate, memberCount}

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
    _loadGroups();
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

  Future<void> _loadGroups() async {
    setState(() {
      _isLoadingGroups = true;
    });

    try {
      final groups = await _apiService.getGroups();
      
      // Load member counts and calculate next payments for each group
      final memberCounts = <int, int>{};
      final nextPayments = <Map<String, dynamic>>[];
      
      for (var group in groups) {
        final groupId = group['id'] as int;
        try {
          final members = await _apiService.getGroupMembers(groupId);
          final memberCount = members.length;
          memberCounts[groupId] = memberCount;
          
          // Calculate next payment date (pass member count directly)
          final nextPayment = await _calculateNextPayment(group, groupId, memberCount);
          if (nextPayment != null) {
            nextPayments.add(nextPayment);
          }
        } catch (e) {
          print('Error loading members for group $groupId: $e');
          memberCounts[groupId] = 0;
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
          _groups = groups;
          _groupMemberCounts = memberCounts;
          _nextPayments = nextPayments;
          _isLoadingGroups = false;
          // Reset current page if it's beyond the new groups length
          if (_currentPage >= groups.length && groups.isNotEmpty) {
            _currentPage = 0;
          }
        });
      }
    } catch (e) {
      print('Error loading groups: $e');
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
                  child: _isLoadingGroups
                      ? const SizedBox(
                          height: 180,
                          child: Center(
                            child: CircularProgressIndicator(
                              valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF2D7A4F)),
                            ),
                          ),
                        )
                      : _groups.isEmpty
                          ? const SizedBox(
                              height: 180,
                              child: Center(
                                child: Text(
                                  'No groups yet',
                                  style: TextStyle(
                                    color: Color(0xFFA5A5A5),
                                    fontSize: 16,
                                  ),
                                ),
                              ),
                            )
                          : SizedBox(
                              height: 180,
                              child: _groups.length == 1
                                  ? Padding(
                                      padding: const EdgeInsets.symmetric(horizontal: 20),
                                      child: _buildGroupCards().first,
                                    )
                                  : PageView(
                                      padEnds: false,
                                      controller: _pageController,
                                      onPageChanged: (index) {
                                        setState(() {
                                          _currentPage = index;
                                        });
                                      },
                                      children: _buildGroupCards(),
                                    ),
                            ),
                ),
                const SliverToBoxAdapter(child: SizedBox(height: 16)),
                // Page indicator
                if (!_isLoadingGroups && _groups.isNotEmpty)
                  SliverToBoxAdapter(
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: List.generate(
                        _groups.length,
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
                                    // Refresh groups if a new group was created
                                    if (result == true) {
                                      _loadGroups();
                                    }
                                  },
                                ),
                                _buildActionButton(
                                  svgPath: 'assets/svg/invite.svg',
                                  label: 'Invite',
                                  color: const Color(0xFF2D7A4F),
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

  List<Widget> _buildGroupCards() {
    if (_groups.isEmpty) {
      return [];
    }

    return List.generate(_groups.length, (index) {
      final group = _groups[index];
      final groupId = group['id'] as int;
      final groupName = group['name'] as String? ?? 'Unnamed Group';
      final totalAmount = (group['total_amount'] as num?)?.toDouble() ?? 0.0;
      final memberCount = _groupMemberCounts[groupId] ?? 0;
      final isLast = index == _groups.length - 1;
      
      return GroupCard(
        title: groupName,
        amount: totalAmount.toStringAsFixed(0),
        totalMembers: memberCount.toString(),
        isLast: isLast,
        isSingle: _groups.length == 1,
      );
    });
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


class GroupCard extends StatelessWidget {
  final String title;
  final String amount;
  final String totalMembers;
  final bool isLast;
  final bool isSingle;

  const GroupCard({
    super.key,
    required this.title,
    required this.amount,
    required this.totalMembers,
    this.isLast = false,
    this.isSingle = false,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: isSingle
          ? EdgeInsets.zero
          : (isLast
              ? const EdgeInsets.symmetric(horizontal: 20)
              : const EdgeInsets.only(left: 20)),
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
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.w700,
                      color: Colors.black87,
                      letterSpacing: -0.5,
                    ),
                  ),
                  const Spacer(),
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      // Total Amount
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              '\$ $amount',
                              style: const TextStyle(
                                fontSize: 20,
                                fontWeight: FontWeight.w700,
                                color: Colors.black87,
                                letterSpacing: -0.3,
                              ),
                            ),
                            const SizedBox(height: 4),
                            const Text(
                              'TOTAL AMOUNT',
                              style: TextStyle(
                                fontSize: 10,
                                fontWeight: FontWeight.w600,
                                color: Colors.black87,
                                letterSpacing: 0.5,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 24),
                      // Total Members
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            totalMembers,
                            style: const TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.w700,
                              color: Colors.black87,
                              letterSpacing: -0.3,
                            ),
                          ),
                          const SizedBox(height: 4),
                          const Text(
                            'TOTAL MEMBER',
                            style: TextStyle(
                              fontSize: 10,
                              fontWeight: FontWeight.w600,
                              color: Colors.black87,
                              letterSpacing: 0.5,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}