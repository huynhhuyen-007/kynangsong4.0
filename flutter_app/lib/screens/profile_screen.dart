import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../utils/auth_manager.dart';
import '../widgets/app_scaffold.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  String _name = '';
  String _email = '';
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _loadUser();
  }

  Future<void> _loadUser() async {
    final user = await AuthManager.getUser();
    if (mounted) {
      setState(() {
        _name = user['name'] ?? '';
        _email = user['email'] ?? '';
        _loading = false;
      });
    }
  }

  Future<void> _logout() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text('Đăng xuất', style: GoogleFonts.outfit(fontWeight: FontWeight.w700)),
        content: Text('Bạn có chắc muốn đăng xuất không?', style: GoogleFonts.outfit()),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: Text('Hủy', style: GoogleFonts.outfit(color: Colors.grey)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red.shade600),
            onPressed: () => Navigator.pop(ctx, true),
            child: Text('Đăng xuất', style: GoogleFonts.outfit()),
          ),
        ],
      ),
    );
    if (confirm == true && mounted) {
      final nav = Navigator.of(context);
      await AuthManager.logout();
      nav.pushReplacementNamed('/auth');
    }
  }

  @override
  Widget build(BuildContext context) {
    return AppScaffold(
      title: 'Hồ Sơ',
      currentIndex: 0,
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              child: Column(
                children: [
                  // Header
                  Container(
                    width: double.infinity,
                    decoration: const BoxDecoration(
                      gradient: LinearGradient(
                        colors: [Color(0xFF4F46E5), Color(0xFF7C3AED)],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                    ),
                    padding: const EdgeInsets.fromLTRB(24, 40, 24, 40),
                    child: Column(
                      children: [
                        Container(
                          width: 88,
                          height: 88,
                          decoration: BoxDecoration(
                            color: Colors.white,
                            shape: BoxShape.circle,
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withValues(alpha: 0.2),
                                blurRadius: 16,
                                offset: const Offset(0, 6),
                              ),
                            ],
                          ),
                          child: Center(
                            child: Text(
                              _name.isNotEmpty ? _name[0].toUpperCase() : '?',
                              style: GoogleFonts.outfit(
                                fontSize: 36,
                                fontWeight: FontWeight.w800,
                                color: const Color(0xFF4F46E5),
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(height: 16),
                        Text(
                          _name.isEmpty ? 'Người dùng' : _name,
                          style: GoogleFonts.outfit(
                            fontSize: 24,
                            fontWeight: FontWeight.w800,
                            color: Colors.white,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          _email,
                          style: GoogleFonts.outfit(
                            fontSize: 14,
                            color: Colors.white.withValues(alpha: 0.85),
                          ),
                        ),
                        const SizedBox(height: 16),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                          decoration: BoxDecoration(
                            color: Colors.white.withValues(alpha: 0.2),
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Text(
                            '🌟 Học viên tích cực',
                            style: GoogleFonts.outfit(color: Colors.white, fontSize: 13, fontWeight: FontWeight.w600),
                          ),
                        ),
                      ],
                    ),
                  ),

                  // Stats
                  Padding(
                    padding: const EdgeInsets.all(20),
                    child: Row(
                      children: [
                        _statCard('3', 'Kỹ năng\nhoàn thành', const Color(0xFF4F46E5)),
                        const SizedBox(width: 12),
                        _statCard('7', 'Ngày\nhọc liên tiếp', const Color(0xFF059669)),
                        const SizedBox(width: 12),
                        _statCard('25', 'Điểm\ntích lũy', const Color(0xFFD97706)),
                      ],
                    ),
                  ),

                  // Menu items
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    child: Column(
                      children: [
                        _menuItem(Icons.person_outline, 'Thông tin tài khoản', 'Tên, email...', () {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text('Tính năng sắp ra mắt! 🚀', style: GoogleFonts.outfit()),
                              behavior: SnackBarBehavior.floating,
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                            ),
                          );
                        }),
                        _menuItem(Icons.bar_chart_outlined, 'Tiến độ học tập', 'Xem kết quả và thành tích', () {
                          Navigator.pushNamed(context, '/playground');
                        }),
                        _menuItem(Icons.star_outline, 'Kỹ năng của tôi', 'Các kỹ năng đã học', () {
                          Navigator.pushNamed(context, '/skills');
                        }),
                        _menuItem(Icons.notifications_outlined, 'Thông báo', 'Quản lý nhắc nhở học tập', () {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text('Tính năng sắp ra mắt! 🚀', style: GoogleFonts.outfit()),
                              behavior: SnackBarBehavior.floating,
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                            ),
                          );
                        }),
                        const SizedBox(height: 8),
                        _menuItem(Icons.logout, 'Đăng xuất', 'Thoát khỏi tài khoản', _logout,
                            iconColor: Colors.red.shade400, textColor: Colors.red.shade400),
                        const SizedBox(height: 24),
                      ],
                    ),
                  ),
                ],
              ),
            ),
    );
  }

  Widget _statCard(String value, String label, Color color) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: color.withValues(alpha: 0.2)),
          boxShadow: [BoxShadow(color: color.withValues(alpha: 0.08), blurRadius: 10, offset: const Offset(0, 4))],
        ),
        child: Column(children: [
          Text(value, style: GoogleFonts.outfit(fontSize: 26, fontWeight: FontWeight.w800, color: color)),
          const SizedBox(height: 4),
          Text(label, textAlign: TextAlign.center, style: GoogleFonts.outfit(fontSize: 11, color: Colors.grey.shade600, height: 1.3)),
        ]),
      ),
    );
  }

  Widget _menuItem(IconData icon, String title, String subtitle, VoidCallback onTap,
      {Color? iconColor, Color? textColor}) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFFE0E7FF)),
      ),
      child: ListTile(
        leading: Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: (iconColor ?? const Color(0xFF4F46E5)).withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Icon(icon, color: iconColor ?? const Color(0xFF4F46E5), size: 20),
        ),
        title: Text(title,
          style: GoogleFonts.outfit(fontWeight: FontWeight.w600, color: textColor ?? const Color(0xFF1E1B4B))),
        subtitle: Text(subtitle, style: GoogleFonts.outfit(fontSize: 12, color: Colors.grey.shade500)),
        trailing: Icon(Icons.chevron_right, color: Colors.grey.shade400),
        onTap: onTap,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      ),
    );
  }
}
