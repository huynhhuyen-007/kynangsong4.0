import 'package:flutter/material.dart';
import 'auth_manager.dart';
import 'app_logger.dart';

enum AppRole { unauthenticated, user, admin }

class AppStateNotifier extends ChangeNotifier {
  AppRole _role = AppRole.unauthenticated;
  bool _isPreviewMode = false;

  AppRole get role => _role;
  bool get isPreviewMode => _isPreviewMode;

  /// Gọi khi app khởi động — đọc session từ SharedPreferences
  Future<void> initialize() async {
    final loggedIn = await AuthManager.isLoggedIn();
    if (!loggedIn) {
      _role = AppRole.unauthenticated;
      AppLogger.info('AppStateNotifier: no session found');
      return;
    }
    final user = await AuthManager.getUser();
    _role = user['role'] == 'admin' ? AppRole.admin : AppRole.user;
    AppLogger.info('AppStateNotifier: initialized as ${_role.name}');
    notifyListeners();
  }

  /// Gọi sau khi login thành công — AppRouter tự rebuild, không cần runApp()
  void loginAs(String role) {
    _isPreviewMode = false;
    _role = role == 'admin' ? AppRole.admin : AppRole.user;
    AppLogger.info('AppStateNotifier: logged in as ${_role.name}');
    notifyListeners();
  }

  /// Admin xem tạm User App mà không cần logout
  void previewAsUser() {
    _isPreviewMode = true;
    _role = AppRole.user;
    AppLogger.info('AppStateNotifier: admin previewing as user');
    notifyListeners();
  }

  /// Quay lại Admin Control Center từ Preview mode
  void backToAdmin() {
    _isPreviewMode = false;
    _role = AppRole.admin;
    AppLogger.info('AppStateNotifier: back to admin from preview');
    notifyListeners();
  }

  /// Logout — xoá session, về auth screen
  Future<void> logout() async {
    await AuthManager.logout();
    _isPreviewMode = false;
    _role = AppRole.unauthenticated;
    AppLogger.info('AppStateNotifier: logged out');
    notifyListeners();
  }
}
