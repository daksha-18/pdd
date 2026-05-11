import 'package:flutter/material.dart';
import 'admin_dashboard.dart';
import 'admin_complaints_screen.dart';
import 'admin_users_screen.dart';
import '../common/profile_screen.dart';

class AdminHome extends StatefulWidget {
  const AdminHome({super.key});
  @override
  State<AdminHome> createState() => _AdminHomeState();
}

class _AdminHomeState extends State<AdminHome> {
  int _currentIndex = 0;
  final _pages = const [
    AdminDashboard(),
    AdminComplaintsScreen(),
    AdminUsersScreen(),
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
              icon: Icon(Icons.grid_view_rounded),
              selectedIcon: Icon(Icons.grid_view_rounded),
              label: 'Dashboard'),
          NavigationDestination(
              icon: Icon(Icons.assignment_rounded),
              selectedIcon: Icon(Icons.assignment_rounded),
              label: 'Complaints'),
          NavigationDestination(
              icon: Icon(Icons.group_rounded),
              selectedIcon: Icon(Icons.group_rounded),
              label: 'Users'),
          NavigationDestination(
              icon: Icon(Icons.person_rounded),
              selectedIcon: Icon(Icons.person_rounded),
              label: 'Profile'),
        ],
      ),
    );
  }
}
