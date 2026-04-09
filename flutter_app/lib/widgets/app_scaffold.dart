import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../utils/auth_manager.dart';

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

  static const _routes = ['/home', '/community', '/skills', '/fun', '/news'];
  static const _labels = ['Trang chủ', 'Cộng đồng', 'Kỹ năng', 'Vui học', 'Tin tức'];
  static const _icons = [
    Icons.home_outlined,
    Icons.people_outline_rounded,
    Icons.star_outline,
    Icons.lightbulb_outline,
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
    final currentRoute = ModalRoute.of(context)?.settings.name;
    final bool isPushedSubScreen = currentRoute == '/profile' || currentRoute == '/copilot' || currentRoute == '/news_detail' || currentRoute == '/post_detail';

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
                  colors: [Color(0xFF1E1B4B), Color(0xFF4F46E5)], // Darker sci-fi gradient
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
                        gradient: const LinearGradient(colors: [Color(0xFF8B5CF6), Color(0xFF3B82F6)]),
                        borderRadius: BorderRadius.circular(14),
                        boxShadow: [
                          BoxShadow(color: const Color(0xFF8B5CF6).withValues(alpha: 0.5), blurRadius: 10, offset: const Offset(0, 4))
                        ]),
                    child: const Icon(Icons.rocket_launch_rounded, color: Colors.white, size: 28),
                  ),
                  const SizedBox(height: 12),
                  Text('Kỹ Năng Sống 4.0',
                      style: GoogleFonts.outfit(
                          color: Colors.white,
                          fontSize: 20,
                          fontWeight: FontWeight.w800,
                          letterSpacing: 0.5)),
                  Text('Skill Up Your Life ✦',
                      style: GoogleFonts.outfit(
                          color: const Color(0xFFA78BFA), fontSize: 13, fontWeight: FontWeight.w600)),
                ],
              ),
            ),
            for (int i = 0; i < _labels.length; i++)
              Container(
                margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  gradient: i == currentIndex 
                    ? LinearGradient(colors: [const Color(0xFF4F46E5).withValues(alpha: 0.15), Colors.transparent])
                    : null,
                  borderRadius: BorderRadius.circular(12),
                  border: i == currentIndex
                    ? const Border(left: BorderSide(color: Color(0xFF4F46E5), width: 4))
                    : const Border(left: BorderSide(color: Colors.transparent, width: 4)),
                ),
                child: ListTile(
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
                  selectedTileColor: Colors.transparent, // Nền đã dùng ở Container
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12)),
                  onTap: () {
                    Navigator.pop(context);
                    _navigate(context, i);
                  },
                ),
              ),
            const Divider(),
            Container(
              margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                gradient: currentIndex == -1 && ModalRoute.of(context)?.settings.name == '/playground'
                  ? LinearGradient(colors: [const Color(0xFF059669).withValues(alpha: 0.15), Colors.transparent])
                  : null,
                borderRadius: BorderRadius.circular(12),
                border: currentIndex == -1 && ModalRoute.of(context)?.settings.name == '/playground'
                  ? const Border(left: BorderSide(color: Color(0xFF059669), width: 4))
                  : const Border(left: BorderSide(color: Colors.transparent, width: 4)),
              ),
              child: ListTile(
                leading: Icon(Icons.videogame_asset_rounded,
                    color: currentIndex == -1 && ModalRoute.of(context)?.settings.name == '/playground'
                        ? const Color(0xFF059669)
                        : Colors.orange.shade500),
                title: Row(
                  children: [
                    Text('Sân Chơi (Map)',
                        style: GoogleFonts.outfit(
                          fontWeight: FontWeight.w800,
                          color: currentIndex == -1 && ModalRoute.of(context)?.settings.name == '/playground'
                              ? const Color(0xFF059669)
                              : Colors.orange.shade700,
                        )),
                    const SizedBox(width: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(colors: [Color(0xFFEF4444), Color(0xFFF97316)]),
                        borderRadius: BorderRadius.circular(8),
                        boxShadow: [
                          BoxShadow(color: const Color(0xFFEF4444).withValues(alpha: 0.4), blurRadius: 4, offset: const Offset(0, 2))
                        ],
                      ),
                      child: Text('HOT', style: GoogleFonts.outfit(color: Colors.white, fontSize: 10, fontWeight: FontWeight.w900, letterSpacing: 0.5)),
                    ),
                  ],
                ),
                selected: currentIndex == -1 && ModalRoute.of(context)?.settings.name == '/playground',
                selectedTileColor: Colors.transparent,
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12)),
                onTap: () {
                  Navigator.pop(context);
                  final currentRoute = ModalRoute.of(context)?.settings.name;
                  if (currentRoute != '/playground') {
                    Navigator.pushNamedAndRemoveUntil(context, '/playground', (route) => false);
                  }
                },
              ),
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
                        title: Text('Quản lý người dùng',
                            style: GoogleFonts.outfit(
                                color: Colors.orange, fontWeight: FontWeight.w600)),
                        onTap: () {
                          Navigator.pop(context);
                          Navigator.pushNamed(context, '/admin');
                        },
                      ),
                      ListTile(
                        leading: const Icon(Icons.edit_note_rounded, color: Colors.deepOrange),
                        title: Text('Quản lý nội dung',
                            style: GoogleFonts.outfit(
                                color: Colors.deepOrange, fontWeight: FontWeight.w600)),
                        onTap: () {
                          Navigator.pop(context);
                          Navigator.pushNamed(context, '/admin_cms');
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
        // currentIndex phải >= 0, dùng 0 làm fallback khi là -1 (màn hình phụ)
        currentIndex: currentIndex < 0 ? 0 : currentIndex,
        onTap: (i) => _navigate(context, i),
        type: BottomNavigationBarType.fixed,
        // Khi currentIndex = -1, không highlight tab nào (dùng màu grey cho cả selected)
        selectedItemColor: currentIndex < 0 ? Colors.grey : const Color(0xFF4F46E5),
        unselectedItemColor: Colors.grey,
        selectedLabelStyle: currentIndex < 0
            ? GoogleFonts.outfit(fontWeight: FontWeight.normal, fontSize: 11)
            : GoogleFonts.outfit(fontWeight: FontWeight.w600, fontSize: 11),
        unselectedLabelStyle: GoogleFonts.outfit(fontSize: 11),
        items: List.generate(
          _labels.length,
          (i) => BottomNavigationBarItem(
              icon: Icon(_icons[i]), label: _labels[i]),
        ),
      ),
      body: body,
      floatingActionButton: floatingActionButton,
    );
  }
}
