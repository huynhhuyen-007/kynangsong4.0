import 'package:shared_preferences/shared_preferences.dart';

class AuthManager {
  static const _keyLoggedIn = 'kns_logged_in';
  static const _keyUserId = 'kns_user_id';
  static const _keyUserName = 'kns_user_name';
  static const _keyUserEmail = 'kns_user_email';
  static const _keyUserRole = 'kns_user_role';

  static Future<bool> isLoggedIn() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_keyLoggedIn) ?? false;
  }

  static Future<void> saveUser(Map<String, dynamic> user) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_keyLoggedIn, true);
    await prefs.setString(_keyUserId, user['id'] ?? '');
    await prefs.setString(_keyUserName, user['name'] ?? '');
    await prefs.setString(_keyUserEmail, user['email'] ?? '');
    await prefs.setString(_keyUserRole, user['role'] ?? 'user');
  }

  static Future<Map<String, String>> getUser() async {
    final prefs = await SharedPreferences.getInstance();
    return {
      'id': prefs.getString(_keyUserId) ?? '',
      'name': prefs.getString(_keyUserName) ?? '',
      'email': prefs.getString(_keyUserEmail) ?? '',
      'role': prefs.getString(_keyUserRole) ?? 'user',
    };
  }

  static Future<void> logout() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.clear();
  }
}


