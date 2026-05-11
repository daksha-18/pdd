import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/user_model.dart';
import '../services/api_service.dart';
import '../utils/constants.dart';

class AuthProvider extends ChangeNotifier {
  UserModel? _user;
  String? _token;
  bool _isLoading = false;
  String? _error;

  UserModel? get user => _user;
  String? get token => _token;
  bool get isLoading => _isLoading;
  bool get isAuthenticated => _token != null && _user != null;
  String? get error => _error;
  String get userRole => _user?.role ?? 'student';

  AuthProvider() { _loadStoredAuth(); }

  Future<void> _loadStoredAuth() async {
    final prefs = await SharedPreferences.getInstance();
    _token = prefs.getString(AppConstants.tokenKey);
    final userData = prefs.getString(AppConstants.userKey);
    if (_token != null && userData != null) {
      _user = UserModel.fromJson(jsonDecode(userData));
      notifyListeners();
    }
  }

  Future<bool> register(String name, String email, String password, {String? phone, String? hostelBlock, String? roomNumber, String? role, String? specialization}) async {
    _isLoading = true;
    _error = null;
    notifyListeners();
    try {
      final res = await ApiService.post('${ApiConstants.auth}/register', {
        'name': name,
        'email': email,
        'password': password,
        'phone': phone,
        'hostelBlock': hostelBlock,
        'roomNumber': roomNumber,
        'role': role ?? 'student',
        'specialization': specialization ?? 'general',
      });
      await _handleAuthResponse(res);
      return true;
    } catch (e) {
      _error = e.toString();
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  Future<bool> login(String email, String password) async {
    _isLoading = true;
    _error = null;
    notifyListeners();
    try {
      final res = await ApiService.post('${ApiConstants.auth}/login', {'email': email, 'password': password});
      await _handleAuthResponse(res);
      return true;
    } catch (e) {
      _error = e.toString();
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  Future<void> _handleAuthResponse(Map<String, dynamic> res) async {
    final data = res['data'];
    _token = data['token'];
    _user = UserModel.fromJson(data['user']);
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(AppConstants.tokenKey, _token!);
    await prefs.setString(AppConstants.userKey, jsonEncode(_user!.toJson()));
    _isLoading = false;
    notifyListeners();
  }

  Future<void> logout() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(AppConstants.tokenKey);
    await prefs.remove(AppConstants.userKey);
    _user = null;
    _token = null;
    notifyListeners();
  }

  Future<void> updateProfile({String? name, String? phone, String? hostelBlock, String? roomNumber}) async {
    try {
      final res = await ApiService.put('${ApiConstants.auth}/update-profile', {
        if (name != null) 'name': name,
        if (phone != null) 'phone': phone,
        if (hostelBlock != null) 'hostelBlock': hostelBlock,
        if (roomNumber != null) 'roomNumber': roomNumber,
      });
      _user = UserModel.fromJson(res['data']);
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(AppConstants.userKey, jsonEncode(_user!.toJson()));
      notifyListeners();
    } catch (e) {
      _error = e.toString();
      notifyListeners();
    }
  }

  void clearError() {
    _error = null;
    notifyListeners();
  }
}
