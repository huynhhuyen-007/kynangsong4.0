import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../utils/auth_manager.dart';
import '../utils/app_provider.dart';
import '../utils/app_localizations.dart';

class AppScaffold extends StatelessWidget {
  final String title;
  final Widget body;
  final int currentIndex;
  final Widget? floatingActionButton;

  const AppScaffold({
    super.key,
    required this.title,
    required this.body,
    required this.currentIndex,
    this.floatingActionButton,
  });

  static const _routes = ['/home', '/community', '/skills', '/news'];

  List<String> _labels(AppLocalizations loc) =>
      [loc.home, loc.community, loc.skillsNav, loc.newsNav];

  static const _icons = [
    Icons.home_outlined,
    Icons.people_outline_rounded,
    Icons.star_outline,
    Icons.newspaper_outlined,
  ];

  void _navigate(BuildContext context, int index) {
    final currentRoute = ModalRoute.of(context)?.settings.name;
    if (currentIndex >= 0 && index == currentIndex && currentRoute != '/profile') return;
    Navigator.pushNamedAndRemoveUntil(context, _routes[index], (route) => false);
  }

  Future<void> _logout(BuildContext context) async {
    await AuthManager.logout();
    if (context.mounted) Navigator.pushReplacementNamed(context, '/auth');
  }

  @override
  Widget build(BuildContext context) {
    final appProvider = context.watch<AppProvider>();
    final loc = AppLocalizations.of(context);
    final isDark = appProvider.isDark;
    final currentRoute = ModalRoute.of(context)?.settings.name;
    final bool isPushedSubScreen = currentRoute == '/profile' ||
        currentRoute == '/copilot' ||
        currentRoute == '/news_detail' ||
        currentRoute == '/post_detail';

    final labels = _labels(loc);

    return Scaffold(
      appBar: AppBar(
        leading: isPushedSubScreen
            ? IconButton(
                icon: const Icon(Icons.arrow_back),
                onPressed: () => Navigator.pop(context),
              )
            : null,
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                  color: Colors.white, borderRadius: BorderRadius.circular(8)),
              child: Text('KNS',
                  style: GoogleFonts.outfit(
                      fontWeight: FontWeight.w800,
                      color: const Color(0xFF4F46E5),
                      fontSize: 14)),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                title,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
        actions: [
          // Dark/Light toggle — hiển thị trên AppBar
          IconButton(
            icon: Icon(isDark ? Icons.light_mode_rounded : Icons.dark_mode_rounded),
            tooltip: isDark ? 'Chuyển sáng' : 'Chuyển tối',
            onPressed: () => appProvider.toggleTheme(),
          ),
          IconButton(
            icon: const Icon(Icons.person_outline),
            tooltip: loc.profile,
            onPressed: () => Navigator.pushNamed(context, '/profile'),
          ),
        ],
      ),

      // ── Drawer ─────────────────────────────────────────────────────────────
      drawer: Drawer(
        child: ListView(
          padding: EdgeInsets.zero,
          children: [
            // Header
            DrawerHeader(
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  colors: [Color(0xFF1E1B4B), Color(0xFF4F46E5)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                        gradient: const LinearGradient(
                            colors: [Color(0xFF8B5CF6), Color(0xFF3B82F6)]),
                        borderRadius: BorderRadius.circular(14),
                        boxShadow: [
                          BoxShadow(
                              color: const Color(0xFF8B5CF6).withValues(alpha: 0.5),
                              blurRadius: 10,
                              offset: const Offset(0, 4))
                        ]),
                    child: const Icon(Icons.rocket_launch_rounded,
                        color: Colors.white, size: 28),
                  ),
                  const SizedBox(height: 12),
                  Text(loc.appName,
                      style: GoogleFonts.outfit(
                          color: Colors.white,
                          fontSize: 20,
                          fontWeight: FontWeight.w800,
                          letterSpacing: 0.5)),
                  Text('Skill Up Your Life ✦',
                      style: GoogleFonts.outfit(
                          color: const Color(0xFFA78BFA),
                          fontSize: 13,
                          fontWeight: FontWeight.w600)),
                ],
              ),
            ),

            // Nav items
            for (int i = 0; i < labels.length; i++)
              _DrawerNavItem(
                icon: _icons[i],
                label: labels[i],
                isSelected: i == currentIndex,
                onTap: () {
                  Navigator.pop(context);
                  _navigate(context, i);
                },
              ),

            const Divider(height: 1),

            // Playground
            _DrawerNavItem(
              icon: Icons.videogame_asset_rounded,
              label: loc.playground,
              isSelected: currentIndex == -1 && currentRoute == '/playground',
              selectedColor: const Color(0xFF059669),
              badge: 'HOT',
              onTap: () {
                Navigator.pop(context);
                if (currentRoute != '/playground') {
                  Navigator.pushNamedAndRemoveUntil(
                      context, '/playground', (route) => false);
                }
              },
            ),

            // Admin section
            FutureBuilder<Map<String, String>>(
              future: AuthManager.getUser(),
              builder: (context, snapshot) {
                if (snapshot.hasData && snapshot.data!['role'] == 'admin') {
                  return Column(children: [
                    const Divider(height: 1),
                    Padding(
                      padding: const EdgeInsets.fromLTRB(16, 10, 16, 4),
                      child: Row(children: [
                        const Icon(Icons.admin_panel_settings_rounded,
                            size: 14, color: Colors.orange),
                        const SizedBox(width: 6),
                        Text(loc.isEn ? 'ADMIN ZONE' : 'QUẢN TRỊ',
                            style: GoogleFonts.outfit(
                                fontSize: 11,
                                fontWeight: FontWeight.w800,
                                color: Colors.orange.shade700,
                                letterSpacing: 1.2)),
                      ]),
                    ),
                    _DrawerNavItem(
                      icon: Icons.dashboard_rounded,
                      label: loc.adminDashboard,
                      isSelected: currentRoute == '/admin',
                      selectedColor: Colors.orange,
                      onTap: () {
                        Navigator.pop(context);
                        Navigator.pushNamed(context, '/admin');
                      },
                    ),
                    _DrawerNavItem(
                      icon: Icons.edit_note_rounded,
                      label: loc.adminContent,
                      isSelected: currentRoute == '/admin_cms',
                      selectedColor: Colors.deepOrange,
                      onTap: () {
                        Navigator.pop(context);
                        Navigator.pushNamed(context, '/admin_cms');
                      },
                    ),
                  ]);
                }
                return const SizedBox.shrink();
              },
            ),

            const Divider(height: 1),

            // Settings section
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 10, 16, 4),
              child: Text('CÀI ĐẶT',
                  style: GoogleFonts.outfit(
                      fontSize: 11,
                      fontWeight: FontWeight.w800,
                      color: Colors.grey.shade500,
                      letterSpacing: 1.2)),
            ),

            // Dark/Light Mode Toggle trong Drawer
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
              child: ListTile(
                leading: Icon(
                    isDark ? Icons.light_mode_rounded : Icons.dark_mode_rounded,
                    color: isDark ? Colors.amber : const Color(0xFF4F46E5)),
                title: Text(isDark ? 'Giao diện sáng' : 'Giao diện tối',
                    style: GoogleFonts.outfit(fontWeight: FontWeight.w600)),
                trailing: Switch.adaptive(
                  value: isDark,
                  activeThumbColor: const Color(0xFF4F46E5),
                  onChanged: (_) => appProvider.toggleTheme(),
                ),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                onTap: () => appProvider.toggleTheme(),
              ),
            ),

            const Divider(height: 1),

            // Profile & Logout
            _DrawerNavItem(
              icon: Icons.person_outline,
              label: loc.profile,
              isSelected: false,
              selectedColor: const Color(0xFF4F46E5),
              onTap: () {
                Navigator.pop(context);
                Navigator.pushNamed(context, '/profile');
              },
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
              child: ListTile(
                leading: Icon(Icons.logout, color: Colors.red.shade400),
                title: Text(loc.logout,
                    style: GoogleFonts.outfit(
                        color: Colors.red.shade400, fontWeight: FontWeight.w600)),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                onTap: () => _logout(context),
              ),
            ),
            const SizedBox(height: 16),
          ],
        ),
      ),

      // ── Bottom Nav ──────────────────────────────────────────────────────────
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: currentIndex < 0 ? 0 : currentIndex,
        onTap: (i) => _navigate(context, i),
        type: BottomNavigationBarType.fixed,
        selectedItemColor: currentIndex < 0 ? Colors.grey : const Color(0xFF4F46E5),
        unselectedItemColor: Colors.grey,
        selectedLabelStyle: currentIndex < 0
            ? GoogleFonts.outfit(fontWeight: FontWeight.normal, fontSize: 11)
            : GoogleFonts.outfit(fontWeight: FontWeight.w600, fontSize: 11),
        unselectedLabelStyle: GoogleFonts.outfit(fontSize: 11),
        items: List.generate(
          labels.length,
          (i) => BottomNavigationBarItem(icon: Icon(_icons[i]), label: labels[i]),
        ),
      ),

      body: body,
      floatingActionButton: floatingActionButton,
    );
  }
}

// ── Drawer Nav Item ─────────────────────────────────────────────────────────
class _DrawerNavItem extends StatelessWidget {
  final IconData icon;
  final String label;
  final bool isSelected;
  final Color selectedColor;
  final String? badge;
  final VoidCallback onTap;

  const _DrawerNavItem({
    required this.icon,
    required this.label,
    required this.isSelected,
    this.selectedColor = const Color(0xFF4F46E5),
    this.badge,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(
        gradient: isSelected
            ? LinearGradient(colors: [selectedColor.withValues(alpha: 0.12), Colors.transparent])
            : null,
        borderRadius: BorderRadius.circular(12),
        border: Border(
          left: BorderSide(
            color: isSelected ? selectedColor : Colors.transparent,
            width: 3,
          ),
        ),
      ),
      child: ListTile(
        leading: Icon(icon,
            color: isSelected ? selectedColor : Theme.of(context).colorScheme.onSurfaceVariant),
        title: Row(children: [
          Text(label,
              style: GoogleFonts.outfit(
                fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                color: isSelected ? selectedColor : Theme.of(context).colorScheme.onSurface,
              )),
          if (badge != null) ...[
            const SizedBox(width: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
              decoration: BoxDecoration(
                gradient: const LinearGradient(colors: [Color(0xFFEF4444), Color(0xFFF97316)]),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(badge!,
                  style: GoogleFonts.outfit(
                      color: Colors.white, fontSize: 10, fontWeight: FontWeight.w900)),
            ),
          ],
        ]),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        onTap: onTap,
      ),
    );
  }
}
