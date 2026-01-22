import 'package:flutter/material.dart';
import '../home/home.dart';
import '../groups/groups.dart';
import '../draw_selection/draw_selection_screen.dart';
import '../widgets/bottom_nav_bar.dart';
import 'history_screen.dart';
import '../../utils/responsive.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  int _selectedIndex = 0;
  final ValueNotifier<int> _groupsRefreshTrigger = ValueNotifier<int>(0);
  int _groupsInitialTab = 0;
  VoidCallback? _historyRefreshCallback;

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
    HistoryScreen(
      onVisible: (callback) {
        _historyRefreshCallback = callback;
      },
    ),
  ];

  void _onItemSelected(int index) {
    setState(() {
      _selectedIndex = index;
    });
    // Refresh groups when navigating to groups tab
    if (index == 1) {
      _groupsRefreshTrigger.value++;
    }
    // Trigger history refresh when navigating to history tab
    if (index == 3) {
      _historyRefreshCallback?.call();
    }
  }

  Future<bool> _onWillPop() async {
    final shouldExit = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Exit App'),
        content: const Text('Are you sure you want to exit the app?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('Exit'),
          ),
        ],
      ),
    );
    return shouldExit ?? false;
  }

  @override
  Widget build(BuildContext context) {
    final responsive = Responsive(context);
    return WillPopScope(
      onWillPop: _onWillPop,
      child: Scaffold(
        body: Stack(
          children: [
            IndexedStack(
              index: _selectedIndex,
              children: _pages,
            ),
            Positioned(
              left: 0,
              right: 0,
              bottom: responsive.padding(20),
              child: Center(
                child: SizedBox(
                  width: responsive.width(300),
                  child: CustomBottomNavBar(
                    selectedIndex: _selectedIndex,
                    onItemSelected: _onItemSelected,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

