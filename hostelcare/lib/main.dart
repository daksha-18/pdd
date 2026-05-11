import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:provider/provider.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'providers/auth_provider.dart';
import 'providers/complaint_provider.dart';
import 'providers/theme_provider.dart';
import 'providers/notification_provider.dart';
import 'screens/splash_screen.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize sqflite for Windows/Linux
  if (!kIsWeb && (Platform.isWindows || Platform.isLinux)) {
    sqfliteFfiInit();
    databaseFactory = databaseFactoryFfi;
  }

  runApp(const HostelCareApp());
}

class HostelCareApp extends StatelessWidget {
  const HostelCareApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => ThemeProvider()),
        ChangeNotifierProvider(create: (_) => AuthProvider()),
        ChangeNotifierProvider(create: (_) => ComplaintProvider()),
        ChangeNotifierProvider(create: (_) => NotificationProvider()),
      ],
      child: Consumer<ThemeProvider>(
        builder: (context, themeProvider, _) {
          return MaterialApp(
            title: 'HostelCare+',
            debugShowCheckedModeBanner: false,
            themeMode: themeProvider.themeMode,
            theme: _buildLightTheme(),
            darkTheme: _buildDarkTheme(),
            home: const SplashScreen(),
          );
        },
      ),
    );
  }

  ThemeData _buildLightTheme() {
    final baseTheme = ThemeData(
      useMaterial3: true,
      brightness: Brightness.light,
      colorSchemeSeed: const Color(0xFF6366F1),
    );

    return baseTheme.copyWith(
      textTheme: GoogleFonts.interTextTheme(baseTheme.textTheme).copyWith(
        headlineLarge: GoogleFonts.outfit(fontWeight: FontWeight.bold, color: const Color(0xFF0F172A)),
        headlineMedium: GoogleFonts.outfit(fontWeight: FontWeight.bold, color: const Color(0xFF0F172A)),
        headlineSmall: GoogleFonts.outfit(fontWeight: FontWeight.bold, color: const Color(0xFF0F172A)),
        titleLarge: GoogleFonts.outfit(fontWeight: FontWeight.w600, color: const Color(0xFF0F172A)),
        titleMedium: GoogleFonts.outfit(fontWeight: FontWeight.w600, color: const Color(0xFF0F172A)),
      ),
      scaffoldBackgroundColor: const Color(0xFFF8FAFC),
      cardTheme: CardThemeData(
        elevation: 0,
        color: Colors.white,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(24),
          side: BorderSide(color: Colors.grey.withOpacity(0.1), width: 1),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: Colors.white,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide(color: Colors.grey.withOpacity(0.2)),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide(color: Colors.grey.withOpacity(0.2)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: const BorderSide(color: Color(0xFF6366F1), width: 2),
        ),
        contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 18),
        prefixIconColor: const Color(0xFF64748B),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 18),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          elevation: 0,
          backgroundColor: const Color(0xFF6366F1),
          foregroundColor: Colors.white,
          textStyle: GoogleFonts.outfit(fontWeight: FontWeight.bold, fontSize: 16),
        ),
      ),
      navigationBarTheme: NavigationBarThemeData(
        backgroundColor: Colors.white,
        elevation: 0,
        indicatorColor: const Color(0xFF6366F1).withOpacity(0.1),
        labelTextStyle: MaterialStateProperty.resolveWith((states) {
          if (states.contains(MaterialState.selected)) {
            return GoogleFonts.outfit(fontSize: 12, fontWeight: FontWeight.bold, color: const Color(0xFF6366F1));
          }
          return GoogleFonts.outfit(fontSize: 12, fontWeight: FontWeight.w500, color: const Color(0xFF64748B));
        }),
        iconTheme: MaterialStateProperty.resolveWith((states) {
          if (states.contains(MaterialState.selected)) {
            return const IconThemeData(color: Color(0xFF6366F1), size: 24);
          }
          return const IconThemeData(color: Color(0xFF64748B), size: 24);
        }),
      ),
      appBarTheme: AppBarTheme(
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: true,
        titleTextStyle: GoogleFonts.outfit(
          color: const Color(0xFF0F172A),
          fontSize: 20,
          fontWeight: FontWeight.bold,
        ),
        iconTheme: const IconThemeData(color: Color(0xFF0F172A)),
      ),
    );
  }

  ThemeData _buildDarkTheme() {
    final baseTheme = ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
      colorSchemeSeed: const Color(0xFF6366F1),
    );

    return baseTheme.copyWith(
      textTheme: GoogleFonts.interTextTheme(baseTheme.textTheme).copyWith(
        headlineLarge: GoogleFonts.outfit(fontWeight: FontWeight.bold, color: Colors.white),
        headlineMedium: GoogleFonts.outfit(fontWeight: FontWeight.bold, color: Colors.white),
        headlineSmall: GoogleFonts.outfit(fontWeight: FontWeight.bold, color: Colors.white),
        titleLarge: GoogleFonts.outfit(fontWeight: FontWeight.w600, color: Colors.white),
        titleMedium: GoogleFonts.outfit(fontWeight: FontWeight.w600, color: Colors.white),
      ),
      scaffoldBackgroundColor: const Color(0xFF0F172A),
      cardTheme: CardThemeData(
        elevation: 0,
        color: const Color(0xFF1E293B),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(24),
          side: BorderSide(color: Colors.white.withOpacity(0.05), width: 1),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: const Color(0xFF1E293B),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide(color: Colors.white.withOpacity(0.1)),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide(color: Colors.white.withOpacity(0.1)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: const BorderSide(color: Color(0xFF6366F1), width: 2),
        ),
        contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 18),
        prefixIconColor: const Color(0xFF94A3B8),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 18),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          elevation: 0,
          backgroundColor: const Color(0xFF6366F1),
          foregroundColor: Colors.white,
          textStyle: GoogleFonts.outfit(fontWeight: FontWeight.bold, fontSize: 16),
        ),
      ),
      navigationBarTheme: NavigationBarThemeData(
        backgroundColor: const Color(0xFF0F172A),
        elevation: 0,
        indicatorColor: const Color(0xFF6366F1).withOpacity(0.2),
        labelTextStyle: MaterialStateProperty.resolveWith((states) {
          if (states.contains(MaterialState.selected)) {
            return GoogleFonts.outfit(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.white);
          }
          return GoogleFonts.outfit(fontSize: 12, fontWeight: FontWeight.w500, color: const Color(0xFF94A3B8));
        }),
        iconTheme: MaterialStateProperty.resolveWith((states) {
          if (states.contains(MaterialState.selected)) {
            return const IconThemeData(color: Colors.white, size: 24);
          }
          return const IconThemeData(color: Color(0xFF94A3B8), size: 24);
        }),
      ),
      appBarTheme: AppBarTheme(
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: true,
        titleTextStyle: GoogleFonts.outfit(
          color: Colors.white,
          fontSize: 20,
          fontWeight: FontWeight.bold,
        ),
        iconTheme: const IconThemeData(color: Colors.white),
      ),
    );
  }
}
