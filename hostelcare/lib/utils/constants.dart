class ApiConstants {
  // Change this to your deployed backend URL
  static const String baseUrl = 'http://10.0.2.2:5000/api'; // Android emulator
  // static const String baseUrl = 'http://localhost:5000/api'; // iOS simulator
  // static const String baseUrl = 'https://your-api.render.com/api'; // Production

  static const String auth = '$baseUrl/auth';
  static const String complaints = '$baseUrl/complaints';
  static const String users = '$baseUrl/users';
  static const String admin = '$baseUrl/admin';
  static const String staff = '$baseUrl/staff';
  static const String analytics = '$baseUrl/analytics';
  static const String chatbot = '$baseUrl/chatbot';
}

class AppConstants {
  static const String appName = 'HostelCare+';
  static const String appVersion = '1.0.0';
  static const String tokenKey = 'auth_token';
  static const String userKey = 'user_data';
  static const String themeKey = 'theme_mode';
  static const String offlineComplaintsKey = 'offline_complaints';

  static const List<String> categories = [
    'electrical', 'water', 'internet', 'cleaning', 'furniture', 'security', 'other'
  ];

  static const List<String> priorities = ['low', 'medium', 'high', 'urgent'];

  static const List<String> statuses = [
    'pending', 'assigned', 'in_progress', 'resolved', 'closed', 'rejected'
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
