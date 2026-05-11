import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/notification_provider.dart';
import 'student_dashboard.dart';
import 'submit_complaint_screen.dart';
import 'my_complaints_screen.dart';
import '../common/profile_screen.dart';
import '../common/chatbot_screen.dart';

class StudentHome extends StatefulWidget {
  const StudentHome({super.key});
  @override
  State<StudentHome> createState() => _StudentHomeState();
}

class _StudentHomeState extends State<StudentHome> {
  int _currentIndex = 0;
  final _pages = const [
    StudentDashboard(),
    MyComplaintsScreen(),
    ChatbotScreen(),
    ProfileScreen()
  ];

  @override
  void initState() {
    super.initState();
    Future.microtask(
        () => context.read<NotificationProvider>().fetchNotifications());
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final primary = theme.colorScheme.primary;
    final isDark = theme.brightness == Brightness.dark;

    return Scaffold(
      body: _pages[_currentIndex],
      floatingActionButton: Container(
        height: 64,
        width: 64,
        margin: const EdgeInsets.only(top: 32),
        child: FloatingActionButton(
          onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const SubmitComplaintScreen())),
          backgroundColor: primary,
          foregroundColor: Colors.white,
          elevation: 8,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          child: const Icon(Icons.add_rounded, size: 32),
        ),
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerDocked,
      bottomNavigationBar: NavigationBar(
        selectedIndex: _currentIndex,
        onDestinationSelected: (i) => setState(() => _currentIndex = i),
        destinations: const [
          NavigationDestination(
              icon: Icon(Icons.home_rounded),
              selectedIcon: Icon(Icons.home_rounded),
              label: 'Home'),
          NavigationDestination(
              icon: Icon(Icons.assignment_rounded),
              selectedIcon: Icon(Icons.assignment_rounded),
              label: 'My Issues'),
          NavigationDestination(
              icon: Icon(Icons.auto_awesome_rounded),
              selectedIcon: Icon(Icons.auto_awesome_rounded),
              label: 'AI Chat'),
          NavigationDestination(
              icon: Icon(Icons.person_rounded),
              selectedIcon: Icon(Icons.person_rounded),
              label: 'Profile'),
        ],
      ),
    );
  }
}
