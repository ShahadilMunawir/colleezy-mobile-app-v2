import 'package:flutter/material.dart';
import '../home/home.dart';
import '../groups/groups.dart';
import '../draw_selection/draw_selection_screen.dart';
import '../widgets/bottom_nav_bar.dart';
import 'history_screen.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  int _selectedIndex = 0;
  final ValueNotifier<int> _groupsRefreshTrigger = ValueNotifier<int>(0);
  int _groupsInitialTab = 0;

  List<Widget> get _pages => [
    HomeScreen(
      onNavigateToGroups: (tabIndex) {
        setState(() {
          _selectedIndex = 1;
          _groupsInitialTab = tabIndex;
          _groupsRefreshTrigger.value++;
        });
      },
    ),
    GroupsScreen(
      key: ValueKey(_groupsRefreshTrigger.value),
      initialTab: _groupsInitialTab,
    ),
    const DrawSelectionScreen(),
    const HistoryScreen(),
  ];

  void _onItemSelected(int index) {
    setState(() {
      _selectedIndex = index;
    });
    // Refresh groups when navigating to groups tab
    if (index == 1) {
      _groupsRefreshTrigger.value++;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          IndexedStack(
            index: _selectedIndex,
            children: _pages,
          ),
          Positioned(
            left: 0,
            right: 0,
            bottom: 20,
            child: Center(
              child: SizedBox(
                width: 300,
                child: CustomBottomNavBar(
                  selectedIndex: _selectedIndex,
                  onItemSelected: _onItemSelected,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

