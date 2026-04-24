import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class AppHelpers {
  /// Format date to readable string
  static String formatDate(String? dateStr) {
    if (dateStr == null) return '';
    try {
      final date = DateTime.parse(dateStr);
      return DateFormat('MMM dd, yyyy • hh:mm a').format(date);
    } catch (_) {
      return dateStr;
    }
  }

  /// Format relative time (e.g., "2 hours ago")
  static String timeAgo(String? dateStr) {
    if (dateStr == null) return '';
    try {
      final date = DateTime.parse(dateStr);
      final diff = DateTime.now().difference(date);
      if (diff.inDays > 30) return DateFormat('MMM dd').format(date);
      if (diff.inDays > 0) return '${diff.inDays}d ago';
      if (diff.inHours > 0) return '${diff.inHours}h ago';
      if (diff.inMinutes > 0) return '${diff.inMinutes}m ago';
      return 'Just now';
    } catch (_) {
      return '';
    }
  }

  /// Show a snackbar
  static void showSnackBar(BuildContext context, String message, {bool isError = false}) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text(message),
      backgroundColor: isError ? Colors.red : Colors.green,
      behavior: SnackBarBehavior.floating,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      margin: const EdgeInsets.all(16),
    ));
  }

  /// Show confirmation dialog
  static Future<bool> showConfirmDialog(BuildContext context, {required String title, required String message, String confirmText = 'Confirm'}) async {
    return await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(title),
        content: Text(message),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancel')),
          ElevatedButton(onPressed: () => Navigator.pop(ctx, true), child: Text(confirmText)),
        ],
      ),
    ) ?? false;
  }

  /// Get greeting based on time of day
  static String getGreeting() {
    final hour = DateTime.now().hour;
    if (hour < 12) return 'Good Morning';
    if (hour < 17) return 'Good Afternoon';
    return 'Good Evening';
  }

  /// Get color for category
  static Color getCategoryColor(String category) {
    switch (category) {
      case 'electrical': return Colors.amber;
      case 'water': return Colors.blue;
      case 'internet': return Colors.purple;
      case 'cleaning': return Colors.green;
      case 'furniture': return Colors.brown;
      case 'security': return Colors.red;
      default: return Colors.grey;
    }
  }

  /// Get icon for category
  static IconData getCategoryIcon(String category) {
    switch (category) {
      case 'electrical': return Icons.electrical_services;
      case 'water': return Icons.water_drop;
      case 'internet': return Icons.wifi;
      case 'cleaning': return Icons.cleaning_services;
      case 'furniture': return Icons.chair;
      case 'security': return Icons.security;
      default: return Icons.help_outline;
    }
  }
}
