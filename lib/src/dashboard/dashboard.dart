import 'package:flutter/material.dart';
import '../home/home.dart';
import '../groups/groups.dart';
import '../spin_wheel/spin_wheel.dart';
import '../widgets/bottom_nav_bar.dart';
import 'history_screen.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  int _selectedIndex = 0;

  final List<Widget> _pages = [
    const HomeScreen(),
    const GroupsScreen(),
    const SpinWheelScreen(),
    const HistoryScreen(),
  ];

  void _onItemSelected(int index) {
    setState(() {
      _selectedIndex = index;
    });
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

