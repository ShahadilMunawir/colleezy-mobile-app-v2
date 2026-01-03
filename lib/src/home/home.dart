import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import '../groups/create_group.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  late PageController _pageController;
  int _currentPage = 0;
  static const int _totalPages = 4;

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
                        Row(
                          children: [
                            Container(
                              width: 44,
                              height: 44,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                color: Colors.grey[300],
                                image: const DecorationImage(
                                  image: NetworkImage(
                                    'https://images.unsplash.com/photo-1494790108377-be9c29b29330?w=100',
                                  ),
                                  fit: BoxFit.cover,
                                ),
                              ),
                            ),
                            const SizedBox(width: 12),
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: const [
                                Text(
                                  'Hello,',
                                  style: TextStyle(
                                    fontSize: 13,
                                    color: Color(0xFFF2F2F2),
                                    fontWeight: FontWeight.w400,
                                  ),
                                ),
                                Text(
                                  'Ms.Joan',
                                  style: TextStyle(
                                    fontSize: 16,
                                    color: Color(0xFFF2F2F2),
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ],
                            ),
                          ],
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
                      children: [
                        GroupCard(
                          title: 'Test',
                          amount: '110',
                          totalMembers: '2',
                          isLast: false,
                        ),
                        GroupCard(
                          title: 'Test',
                          amount: '110',
                          totalMembers: '2',
                          isLast: false,
                        ),
                        GroupCard(
                          title: 'Test',
                          amount: '110',
                          totalMembers: '2',
                          isLast: false,
                        ),
                        GroupCard(
                          title: 'Test',
                          amount: '110',
                          totalMembers: '2',
                          isLast: true,
                        ),
                      ],
                    ),
                  ),
                ),
                const SliverToBoxAdapter(child: SizedBox(height: 16)),
                // Page indicator
                SliverToBoxAdapter(
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: List.generate(
                      _totalPages,
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
                SliverToBoxAdapter(
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
                                  onTap: () {
                                    showModalBottomSheet(
                                      context: context,
                                      isScrollControlled: true,
                                      backgroundColor: Colors.transparent,
                                      builder: (context) => const CreateGroupScreen(),
                                    );
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
                        Column(
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
                            Padding(
                              padding: const EdgeInsets.fromLTRB(
                                24,
                                0,
                                24,
                                100,
                              ),
                              child: Column(
                                children: [
                                  _buildPaymentItem(
                                    date: '16/12/2025',
                                    group: 'Group 2',
                                    members: '12 members',
                                  ),
                                  const SizedBox(height: 12),
                                   _buildPaymentItem(
                                    date: '16/12/2025',
                                    group: 'Group 2',
                                    members: '12 members',
                                  ),
                                  const SizedBox(height: 12),
                                    _buildPaymentItem(
                                    date: '16/12/2025',
                                    group: 'Group 2',
                                    members: '12 members',
                                  ),
                                  const SizedBox(height: 12),
                                    _buildPaymentItem(
                                    date: '16/12/2025',
                                    group: 'Group 2',
                                    members: '12 members',
                                  ),
                                  const SizedBox(height: 12),
                                    _buildPaymentItem(
                                    date: '16/12/2025',
                                    group: 'Group 2',
                                    members: '12 members',
                                  ),
                                  const SizedBox(height: 12),
                                    _buildPaymentItem(
                                    date: '16/12/2025',
                                    group: 'Group 2',
                                    members: '12 members',
                                  ),
                                ],
                              ),
                            ),
                          ],
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
              width: 24,
              height: 24,
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
              fontWeight: FontWeight.w500,
              color: Color(0xFFD0CDC6),
            ),
          ),
        ],
      ),
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
              color: Colors.grey[300],
              image: const DecorationImage(
                image: NetworkImage(
                  'https://images.unsplash.com/photo-1494790108377-be9c29b29330?w=100',
                ),
                fit: BoxFit.cover,
              ),
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

  const GroupCard({
    super.key,
    required this.title,
    required this.amount,
    required this.totalMembers,
    this.isLast = false,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
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