import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Manages app theme mode (light/dark) with persistence.
class ThemeProvider extends ChangeNotifier {
  static const _key = 'theme_mode';
  ThemeMode _mode = ThemeMode.light;

  ThemeProvider() {
    _load();
  }

  ThemeMode get mode => _mode;
  bool get isDark => _mode == ThemeMode.dark;

  void toggle() {
    _mode = isDark ? ThemeMode.light : ThemeMode.dark;
    notifyListeners();
    _save();
  }

  void setMode(ThemeMode mode) {
    _mode = mode;
    notifyListeners();
    _save();
  }

  Future<void> _load() async {
    final prefs = await SharedPreferences.getInstance();
    final value = prefs.getString(_key);
    if (value == 'dark') {
      _mode = ThemeMode.dark;
      notifyListeners();
    }
  }

  Future<void> _save() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_key, isDark ? 'dark' : 'light');
  }
}
