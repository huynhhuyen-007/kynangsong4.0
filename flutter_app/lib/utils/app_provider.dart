import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class AppProvider extends ChangeNotifier {
  static const _keyTheme = 'theme_mode';
  static const _keyLocale = 'locale';

  ThemeMode _themeMode = ThemeMode.light;
  String _locale = 'vi'; // 'vi' hoặc 'en'

  ThemeMode get themeMode => _themeMode;
  String get locale => _locale;
  bool get isDark => _themeMode == ThemeMode.dark;

  AppProvider() {
    _loadPrefs();
  }

  Future<void> _loadPrefs() async {
    final prefs = await SharedPreferences.getInstance();
    final themeStr = prefs.getString(_keyTheme) ?? 'light';
    _themeMode = themeStr == 'dark' ? ThemeMode.dark : ThemeMode.light;
    _locale = prefs.getString(_keyLocale) ?? 'vi';
    notifyListeners();
  }

  Future<void> toggleTheme() async {
    _themeMode = _themeMode == ThemeMode.dark ? ThemeMode.light : ThemeMode.dark;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_keyTheme, _themeMode == ThemeMode.dark ? 'dark' : 'light');
    notifyListeners();
  }

  Future<void> setLocale(String locale) async {
    _locale = locale;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_keyLocale, locale);
    notifyListeners();
  }

  Future<void> toggleLocale() async {
    await setLocale(_locale == 'vi' ? 'en' : 'vi');
  }
}
