import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../utils/auth_manager.dart';

class AppScaffold extends StatelessWidget {
  final String title;
  final Widget body;
  final int currentIndex;

  const AppScaffold({
    super.key,
    required this.title,
    required this.body,
    required this.currentIndex,
  });

  static const _routes = ['/home', '/playground', '/skills', '/fun', '/news'];
  static const _labels = ['Trang chủ', 'Sân chơi', 'Kỹ năng', 'Vui học', 'Tin tức'];
  static const _icons = [
    Icons.home_outlined,
    Icons.sports_esports_outlined,
    Icons.star_outline,
    Icons.lightbulb_outline,
    Icons.newspaper_outlined,
  ];

  void _navigate(BuildContext context, int index) {
    if (index == currentIndex) return;
    Navigator.pushReplacementNamed(context, _routes[index]);
  }

  Future<void> _logout(BuildContext context) async {
    await AuthManager.logout();
    if (context.mounted) Navigator.pushReplacementNamed(context, '/auth');
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
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
            Text(title),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.person_outline),
            tooltip: 'Hồ sơ',
            onPressed: () => Navigator.pushNamed(context, '/profile'),
          ),
        ],
      ),
      drawer: Drawer(
        child: ListView(
          padding: EdgeInsets.zero,
          children: [
            DrawerHeader(
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  colors: [Color(0xFF4F46E5), Color(0xFF7C3AED)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  Container(
                    width: 48,
                    height: 48,
                    decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(12)),
                    child: Center(
                      child: Text('KNS',
                          style: GoogleFonts.outfit(
                              fontWeight: FontWeight.w800,
                              color: const Color(0xFF4F46E5),
                              fontSize: 14)),
                    ),
                  ),
                  const SizedBox(height: 12),
                  Text('Kỹ Năng Sống 4.0',
                      style: GoogleFonts.outfit(
                          color: Colors.white,
                          fontSize: 18,
                          fontWeight: FontWeight.w700)),
                  Text('Vui học – Rèn luyện – Khám phá',
                      style: GoogleFonts.outfit(
                          color: Colors.white70, fontSize: 12)),
                ],
              ),
            ),
            for (int i = 0; i < _labels.length; i++)
              ListTile(
                leading: Icon(_icons[i],
                    color: i == currentIndex
                        ? const Color(0xFF4F46E5)
                        : Colors.grey.shade600),
                title: Text(_labels[i],
                    style: GoogleFonts.outfit(
                      fontWeight: i == currentIndex
                          ? FontWeight.w700
                          : FontWeight.w500,
                      color: i == currentIndex
                          ? const Color(0xFF4F46E5)
                          : Colors.grey.shade800,
                    )),
                selected: i == currentIndex,
                selectedTileColor: const Color(0xFFEEF2FF),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12)),
                onTap: () {
                  Navigator.pop(context);
                  _navigate(context, i);
                },
              ),
            FutureBuilder<Map<String, String>>(
              future: AuthManager.getUser(),
              builder: (context, snapshot) {
                if (snapshot.hasData && snapshot.data!['role'] == 'admin') {
                  return Column(
                    children: [
                      const Divider(),
                      ListTile(
                        leading: const Icon(Icons.admin_panel_settings, color: Colors.orange),
                        title: Text('Quản lý hệ thống',
                            style: GoogleFonts.outfit(
                                color: Colors.orange, fontWeight: FontWeight.w600)),
                        onTap: () {
                          Navigator.pop(context);
                          Navigator.pushNamed(context, '/admin');
                        },
                      ),
                    ],
                  );
                }
                return const SizedBox.shrink();
              },
            ),
            const Divider(),
            ListTile(
              leading: Icon(Icons.person_outline, color: const Color(0xFF4F46E5)),
              title: Text('Hồ sơ của tôi',
                  style: GoogleFonts.outfit(
                      color: const Color(0xFF4F46E5),
                      fontWeight: FontWeight.w600)),
              onTap: () {
                Navigator.pop(context);
                Navigator.pushNamed(context, '/profile');
              },
            ),
            ListTile(
              leading: Icon(Icons.logout, color: Colors.red.shade400),
              title: Text('Đăng xuất',
                  style: GoogleFonts.outfit(
                      color: Colors.red.shade400,
                      fontWeight: FontWeight.w600)),
              onTap: () => _logout(context),
            ),
          ],
        ),
      ),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: currentIndex,
        onTap: (i) => _navigate(context, i),
        type: BottomNavigationBarType.fixed,
        selectedItemColor: const Color(0xFF4F46E5),
        unselectedItemColor: Colors.grey,
        selectedLabelStyle:
            GoogleFonts.outfit(fontWeight: FontWeight.w600, fontSize: 11),
        unselectedLabelStyle: GoogleFonts.outfit(fontSize: 11),
        items: List.generate(
          _labels.length,
          (i) => BottomNavigationBarItem(
              icon: Icon(_icons[i]), label: _labels[i]),
        ),
      ),
      body: body,
    );
  }
}
