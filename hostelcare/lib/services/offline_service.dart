import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import '../utils/constants.dart';
import 'api_service.dart';

class OfflineService {
  /// Check if device has internet connectivity
  static Future<bool> isOnline() async {
    final result = await Connectivity().checkConnectivity();
    return result != ConnectivityResult.none;
  }

  /// Save complaint for offline sync
  static Future<void> saveOfflineComplaint(Map<String, dynamic> complaint) async {
    final prefs = await SharedPreferences.getInstance();
    final stored = prefs.getStringList(AppConstants.offlineComplaintsKey) ?? [];
    complaint['offlineTimestamp'] = DateTime.now().toIso8601String();
    stored.add(jsonEncode(complaint));
    await prefs.setStringList(AppConstants.offlineComplaintsKey, stored);
  }

  /// Get count of pending offline complaints
  static Future<int> getOfflineCount() async {
    final prefs = await SharedPreferences.getInstance();
    final stored = prefs.getStringList(AppConstants.offlineComplaintsKey) ?? [];
    return stored.length;
  }

  /// Get all offline complaints
  static Future<List<Map<String, dynamic>>> getOfflineComplaints() async {
    final prefs = await SharedPreferences.getInstance();
    final stored = prefs.getStringList(AppConstants.offlineComplaintsKey) ?? [];
    return stored.map((e) => jsonDecode(e) as Map<String, dynamic>).toList();
  }

  /// Sync all offline complaints to server
  static Future<bool> syncAll() async {
    if (!await isOnline()) return false;

    final prefs = await SharedPreferences.getInstance();
    final stored = prefs.getStringList(AppConstants.offlineComplaintsKey) ?? [];
    if (stored.isEmpty) return true;

    try {
      final complaints = stored.map((e) => jsonDecode(e)).toList();
      await ApiService.post('${ApiConstants.complaints}/sync', {'complaints': complaints});
      await prefs.remove(AppConstants.offlineComplaintsKey);
      return true;
    } catch (e) {
      return false;
    }
  }

  /// Clear all offline data
  static Future<void> clearOfflineData() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(AppConstants.offlineComplaintsKey);
  }

  /// Listen for connectivity changes and auto-sync
  static void startAutoSync(Function onSynced) {
    Connectivity().onConnectivityChanged.listen((result) async {
      if (result != ConnectivityResult.none) {
        final count = await getOfflineCount();
        if (count > 0) {
          final success = await syncAll();
          if (success) onSynced();
        }
      }
    });
  }
}
