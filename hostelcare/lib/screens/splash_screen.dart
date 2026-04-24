import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:animate_do/animate_do.dart';
import '../providers/auth_provider.dart';
import 'auth/login_screen.dart';
import 'student/student_home.dart';
import 'admin/admin_home.dart';
import 'staff/staff_home.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});
  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  @override
  void initState() {
    super.initState();
    _navigate();
  }

  Future<void> _navigate() async {
    await Future.delayed(const Duration(seconds: 2));
    if (!mounted) return;
    final auth = context.read<AuthProvider>();
    Widget destination;
    if (auth.isAuthenticated) {
      switch (auth.userRole) {
        case 'admin': destination = const AdminHome(); break;
        case 'staff': destination = const StaffHome(); break;
        default: destination = const StudentHome(); break;
      }
    } else {
      destination = const LoginScreen();
    }
    Navigator.of(context).pushReplacement(MaterialPageRoute(builder: (_) => destination));
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Scaffold(
      body: Container(
        width: double.infinity,
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft, end: Alignment.bottomRight,
            colors: isDark
              ? [const Color(0xFF1a1a2e), const Color(0xFF16213e), const Color(0xFF0f3460)]
              : [const Color(0xFF6C63FF), const Color(0xFF5A52D5), const Color(0xFF3F37C9)],
          ),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            FadeInDown(
              duration: const Duration(milliseconds: 800),
              child: Container(
                width: 120, height: 120,
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.15),
                  borderRadius: BorderRadius.circular(30),
                  border: Border.all(color: Colors.white.withOpacity(0.3), width: 2),
                ),
                child: const Icon(Icons.home_repair_service_rounded, size: 60, color: Colors.white),
              ),
            ),
            const SizedBox(height: 24),
            FadeInUp(
              delay: const Duration(milliseconds: 400),
              child: const Text('HostelCare', style: TextStyle(fontSize: 36, fontWeight: FontWeight.bold, color: Colors.white, letterSpacing: 1.5)),
            ),
            const SizedBox(height: 8),
            FadeInUp(
              delay: const Duration(milliseconds: 600),
              child: Text('Digital Complaint Management', style: TextStyle(fontSize: 16, color: Colors.white.withOpacity(0.8), letterSpacing: 0.5)),
            ),
            const SizedBox(height: 48),
            FadeIn(
              delay: const Duration(milliseconds: 1000),
              child: const SizedBox(width: 32, height: 32, child: CircularProgressIndicator(strokeWidth: 3, color: Colors.white)),
            ),
          ],
        ),
      ),
    );
  }
}
