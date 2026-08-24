import 'package:flutter/foundation.dart';

class ApiConstants {
  // Set this to true when deploying to production
  static const bool isProduction = false;
  static const String prodUrl = 'https://hostelcare-backend.onrender.com/api';

  // Use 10.0.2.2 for Android emulator, localhost for iOS simulator/Windows/Web
  static String get baseUrl {
    if (isProduction) return prodUrl;
    if (kIsWeb) return 'http://localhost:5000/api';
    
    // Automatically detect Android to use 10.0.2.2 for emulator
    try {
      if (defaultTargetPlatform == TargetPlatform.android) {
        // Return 127.0.0.1 for physical device with ADB reverse, or use 10.0.2.2 for Emulator
        return 'http://127.0.0.1:5000/api';
      }
    } catch (_) {}
    
    // Machine IP from ipconfig: 192.168.137.38
    return 'http://192.168.137.38:5000/api';
  }

  static String get auth => '$baseUrl/auth';
  static String get complaints => '$baseUrl/complaints';
  static String get users => '$baseUrl/users';
  static String get admin => '$baseUrl/admin';
  static String get staff => '$baseUrl/staff';
  static String get analytics => '$baseUrl/analytics';
  static String get chatbot => '$baseUrl/chatbot';
}

class AppConstants {
  static const String appName = 'HostelCare+';
  static const String appVersion = '1.0.0';
  static const String tokenKey = 'auth_token';
  static const String userKey = 'user_data';
  static const String themeKey = 'theme_mode';
  static const String offlineComplaintsKey = 'offline_complaints';

  static const List<String> categories = [
    'electrical',
    'water',
    'internet',
    'cleaning',
    'furniture',
    'security',
    'other'
  ];

  static const List<String> priorities = ['low', 'medium', 'high', 'urgent'];

  static const List<String> statuses = [
    'pending',
    'assigned',
    'in_progress',
    'resolved',
    'closed',
    'rejected'
  ];

  static const Map<String, String> categoryIcons = {
    'electrical': '⚡',
    'water': '💧',
    'internet': '🌐',
    'cleaning': '🧹',
    'furniture': '🪑',
    'security': '🔒',
    'other': '📋',
  };

  static const Map<String, String> statusLabels = {
    'pending': 'Pending',
    'assigned': 'Assigned',
    'in_progress': 'In Progress',
    'resolved': 'Resolved',
    'closed': 'Closed',
    'rejected': 'Rejected',
  };
}
