import 'package:flutter/material.dart';
import 'admin_theme.dart';
import 'screens/admin_dashboard_screen.dart';
import 'screens/admin_users_screen.dart';
import 'screens/admin_content_screen.dart';
import 'screens/admin_moderation_screen.dart';
import '../screens/auth_screen.dart';

class AdminControlCenterApp extends StatelessWidget {
  final String initialRoute;
  const AdminControlCenterApp({super.key, required this.initialRoute});

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<ThemeMode>(
      valueListenable: AdminTheme.themeNotifier,
      builder: (_, mode, __) => MaterialApp(
        title: 'Admin Control Center',
        debugShowCheckedModeBanner: false,
        theme: AdminTheme.lightTheme,
        darkTheme: AdminTheme.theme,
        themeMode: mode,
        initialRoute: initialRoute,
        routes: {
          '/auth':              (_) => const AuthScreen(),
          '/admin_dashboard':   (_) => const AdminDashboardScreen(),
          '/admin_users':       (_) => const AdminUsersScreen(),
          '/admin_content':     (_) => const AdminContentScreen(),
          '/admin_moderation':  (_) => const AdminModerationScreen(),
        },
      ),
    );
  }
}
