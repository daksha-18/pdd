import 'package:flutter/material.dart';
import 'staff_assignments_screen.dart';
import 'staff_stats_screen.dart';
import '../common/profile_screen.dart';

class StaffHome extends StatefulWidget {
  const StaffHome({super.key});
  @override
  State<StaffHome> createState() => _StaffHomeState();
}

class _StaffHomeState extends State<StaffHome> {
  int _currentIndex = 0;
  final _pages = const [
    StaffAssignmentsScreen(),
    StaffStatsScreen(),
    ProfileScreen()
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: _pages[_currentIndex],
      bottomNavigationBar: NavigationBar(
        selectedIndex: _currentIndex,
        onDestinationSelected: (i) => setState(() => _currentIndex = i),
        destinations: const [
          NavigationDestination(
              icon: Icon(Icons.task_alt_rounded),
              selectedIcon: Icon(Icons.task_alt_rounded),
              label: 'Tasks'),
          NavigationDestination(
              icon: Icon(Icons.analytics_rounded),
              selectedIcon: Icon(Icons.analytics_rounded),
              label: 'Stats'),
          NavigationDestination(
              icon: Icon(Icons.person_rounded),
              selectedIcon: Icon(Icons.person_rounded),
              label: 'Profile'),
        ],
      ),
    );
  }
}
