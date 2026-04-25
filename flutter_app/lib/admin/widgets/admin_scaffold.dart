import 'package:flutter/material.dart';
import '../../utils/auth_manager.dart';
import '../admin_theme.dart';
import '../../main.dart'; 

class AdminScaffold extends StatelessWidget {
  final Widget child;
  final int currentIndex;
  
  const AdminScaffold({super.key, required this.child, required this.currentIndex});

  void _onNavigate(BuildContext context, int index) {
    if (index == currentIndex) return;
    String route = '/admin_dashboard';
    switch (index) {
      case 0: route = '/admin_dashboard'; break;
      case 1: route = '/admin_users'; break;
      case 2: route = '/admin_content'; break;
      case 3: route = '/admin_moderation'; break;
    }
    Navigator.pushReplacementNamed(context, route);
  }

  Future<void> _logout(BuildContext context) async {
    await AuthManager.logout();
    if (context.mounted) {
      RootApp.restartApp(context, '/auth', null);
    }
  }

  @override
  Widget build(BuildContext context) {
    final bool isDesktop = MediaQuery.of(context).size.width >= 600;
    final cs = Theme.of(context).colorScheme;

    if (!isDesktop) {
      return Scaffold(
        body: child,
        bottomNavigationBar: BottomNavigationBar(
          currentIndex: currentIndex,
          onTap: (index) => _onNavigate(context, index),
          backgroundColor: cs.surface,
          selectedItemColor: AdminTheme.blue,
          unselectedItemColor: cs.onSurfaceVariant,
          type: BottomNavigationBarType.fixed,
          items: const [
            BottomNavigationBarItem(icon: Icon(Icons.dashboard_rounded), label: 'Dashboard'),
            BottomNavigationBarItem(icon: Icon(Icons.people_rounded), label: 'Users'),
            BottomNavigationBarItem(icon: Icon(Icons.inventory_2_rounded), label: 'Nội dung'),
            BottomNavigationBarItem(icon: Icon(Icons.shield_rounded), label: 'Kiểm duyệt'),
          ],
        ),
      );
    }

    return Scaffold(
      body: Row(
        children: [
          NavigationRail(
            selectedIndex: currentIndex,
            onDestinationSelected: (index) => _onNavigate(context, index),
            labelType: NavigationRailLabelType.all,
            backgroundColor: cs.surface,
            leading: Column(
              children: [
                const SizedBox(height: 16),
                Container(
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                    color: AdminTheme.blue.withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(Icons.admin_panel_settings, color: AdminTheme.blue),
                ),
                const SizedBox(height: 24),
              ],
            ),
            trailing: Expanded(
              child: Align(
                alignment: Alignment.bottomCenter,
                child: Padding(
                  padding: const EdgeInsets.only(bottom: 24.0),
                  child: IconButton(
                    icon: const Icon(Icons.logout_rounded, color: AdminTheme.red),
                    onPressed: () => _logout(context),
                  ),
                ),
              ),
            ),
            destinations: const [
              NavigationRailDestination(
                icon: Icon(Icons.dashboard_rounded),
                label: Text('Dashboard'),
              ),
              NavigationRailDestination(
                icon: Icon(Icons.people_rounded),
                label: Text('Users'),
              ),
              NavigationRailDestination(
                icon: Icon(Icons.inventory_2_rounded),
                label: Text('Nội dung'),
              ),
              NavigationRailDestination(
                icon: Icon(Icons.shield_rounded),
                label: Text('Kiểm duyệt'),
              ),
            ],
          ),
          VerticalDivider(thickness: 1, width: 1, color: cs.outlineVariant),
          Expanded(child: child),
        ],
      ),
    );
  }
}
