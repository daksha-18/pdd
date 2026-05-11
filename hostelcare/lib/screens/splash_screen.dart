import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:animate_do/animate_do.dart';
import 'package:google_fonts/google_fonts.dart';
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
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final primary = theme.colorScheme.primary;
    
    return Scaffold(
      body: Container(
        width: double.infinity,
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft, end: Alignment.bottomRight,
            colors: isDark
              ? [const Color(0xFF0F172A), const Color(0xFF1E293B), const Color(0xFF334155)]
              : [const Color(0xFF6366F1), const Color(0xFF4F46E5), const Color(0xFF4338CA)],
          ),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            FadeInDown(
              duration: const Duration(milliseconds: 800),
              child: Container(
                width: 140, height: 140,
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(36),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.2),
                      blurRadius: 20,
                      offset: const Offset(0, 10),
                    )
                  ],
                ),
                padding: const EdgeInsets.all(24),
                child: Image.asset(
                  'assets/images/logo.png',
                  fit: BoxFit.contain,
                  errorBuilder: (context, error, stackTrace) => 
                      Icon(Icons.hub_rounded, size: 80, color: primary),
                ),
              ),
            ),
            const SizedBox(height: 32),
            FadeInUp(
              delay: const Duration(milliseconds: 400),
              child: Text(
                'HostelCare+', 
                style: GoogleFonts.outfit(
                  fontSize: 42, 
                  fontWeight: FontWeight.bold, 
                  color: Colors.white, 
                  letterSpacing: -1
                )
              ),
            ),
            const SizedBox(height: 8),
            FadeInUp(
              delay: const Duration(milliseconds: 600),
              child: Text(
                'Connected Community', 
                style: GoogleFonts.inter(
                  fontSize: 18, 
                  fontWeight: FontWeight.w500, 
                  color: Colors.white.withOpacity(0.8), 
                  letterSpacing: 0.5
                )
              ),
            ),
            const SizedBox(height: 64),
            FadeIn(
              delay: const Duration(milliseconds: 1000),
              child: const SizedBox(
                width: 28, 
                height: 28, 
                child: CircularProgressIndicator(
                  strokeWidth: 3, 
                  color: Colors.white,
                  backgroundColor: Colors.white24,
                )
              ),
            ),
          ],
        ),
      ),
    );
  }
}
