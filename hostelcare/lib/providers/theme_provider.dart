import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../utils/constants.dart';

class ThemeProvider extends ChangeNotifier {
  ThemeMode _themeMode = ThemeMode.system;
  ThemeMode get themeMode => _themeMode;

  ThemeProvider() { _loadTheme(); }

  void _loadTheme() async {
    final prefs = await SharedPreferences.getInstance();
    final mode = prefs.getString(AppConstants.themeKey) ?? 'system';
    _themeMode = mode == 'dark' ? ThemeMode.dark : mode == 'light' ? ThemeMode.light : ThemeMode.system;
    notifyListeners();
  }

  void toggleTheme() async {
    final prefs = await SharedPreferences.getInstance();
    if (_themeMode == ThemeMode.dark) {
      _themeMode = ThemeMode.light;
      await prefs.setString(AppConstants.themeKey, 'light');
    } else {
      _themeMode = ThemeMode.dark;
      await prefs.setString(AppConstants.themeKey, 'dark');
    }
    notifyListeners();
  }

  bool get isDark => _themeMode == ThemeMode.dark;
}
