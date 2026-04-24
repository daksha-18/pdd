import 'package:flutter/material.dart';
import '../services/api_service.dart';
import '../utils/constants.dart';

class NotificationProvider extends ChangeNotifier {
  List<Map<String, dynamic>> _notifications = [];
  int _unreadCount = 0;
  bool _isLoading = false;

  List<Map<String, dynamic>> get notifications => _notifications;
  int get unreadCount => _unreadCount;
  bool get isLoading => _isLoading;

  Future<void> fetchNotifications() async {
    _isLoading = true;
    notifyListeners();
    try {
      final res = await ApiService.get('${ApiConstants.users}/notifications');
      _notifications = (res['data'] as List).map((e) => Map<String, dynamic>.from(e)).toList();
      _unreadCount = res['unreadCount'] ?? 0;
    } catch (e) { /* silent fail */ }
    _isLoading = false;
    notifyListeners();
  }

  Future<void> markAllRead() async {
    try {
      await ApiService.put('${ApiConstants.users}/notifications/read-all', {});
      _unreadCount = 0;
      for (var n in _notifications) { n['isRead'] = true; }
      notifyListeners();
    } catch (e) { /* silent */ }
  }

  Future<void> markAsRead(String id) async {
    try {
      await ApiService.put('${ApiConstants.users}/notifications/$id/read', {});
      final idx = _notifications.indexWhere((n) => n['_id'] == id);
      if (idx != -1) { _notifications[idx]['isRead'] = true; _unreadCount--; }
      notifyListeners();
    } catch (e) { /* silent */ }
  }
}
