import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../utils/auth_manager.dart';
import '../../main.dart';
import '../admin_theme.dart';

/// Reusable AppBar cho tất cả màn hình Admin.
/// Có settings popup: Dark/Light toggle + Logout.
class AdminAppBar extends StatelessWidget implements PreferredSizeWidget {
  final String title;
  final List<Widget>? extraActions;
  final bool showRefresh;
  final VoidCallback? onRefresh;

  const AdminAppBar({
    super.key,
    required this.title,
    this.extraActions,
    this.showRefresh = false,
    this.onRefresh,
  });

  @override
  Size get preferredSize => const Size.fromHeight(kToolbarHeight);

  Future<void> _logout(BuildContext context) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: Text('Đăng xuất',
          style: GoogleFonts.outfit(fontWeight: FontWeight.w700)),
        content: Text('Bạn có chắc muốn đăng xuất không?',
          style: GoogleFonts.outfit()),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text('Huỷ', style: GoogleFonts.outfit()),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(backgroundColor: AdminTheme.red),
            child: Text('Đăng xuất', style: GoogleFonts.outfit(color: Colors.white)),
          ),
        ],
      ),
    ) ?? false;
    if (!ok) return;
    await AuthManager.logout();
    if (context.mounted) {
      RootApp.restartApp(context, '/auth', null);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = AdminTheme.themeNotifier.value == ThemeMode.dark;

    return AppBar(
      title: Row(
        children: [
          Container(
            width: 8, height: 8,
            decoration: const BoxDecoration(
              color: AdminTheme.green,
              shape: BoxShape.circle,
            ),
          ),
          const SizedBox(width: 8),
          Text(title),
        ],
      ),
      actions: [
        // Extra actions (e.g. refresh)
        if (showRefresh && onRefresh != null)
          IconButton(
            onPressed: onRefresh,
            icon: const Icon(Icons.refresh_rounded),
            tooltip: 'Làm mới',
          ),
        if (extraActions != null) ...extraActions!,

        // Settings popup menu
        PopupMenuButton<String>(
          onSelected: (value) async {
            if (value == 'theme') {
              AdminTheme.toggleTheme();
            } else if (value == 'logout') {
              await _logout(context);
            }
          },
          tooltip: 'Tuỳ chọn',
          icon: CircleAvatar(
            radius: 16,
            backgroundColor: AdminTheme.blue.withOpacity(0.2),
            child: const Icon(Icons.person_rounded, size: 18, color: AdminTheme.blue),
          ),
          itemBuilder: (_) => [
            PopupMenuItem<String>(
              enabled: false,
              height: 32,
              child: Text('Cài đặt',
                style: GoogleFonts.outfit(
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                  color: AdminTheme.textSecondary,
                  letterSpacing: 0.8,
                )),
            ),
            const PopupMenuDivider(height: 1),
            PopupMenuItem<String>(
              value: 'theme',
              child: Row(children: [
                Icon(
                  isDark ? Icons.light_mode_rounded : Icons.dark_mode_rounded,
                  size: 18,
                  color: AdminTheme.orange,
                ),
                const SizedBox(width: 12),
                Text(isDark ? 'Chuyển Light Mode' : 'Chuyển Dark Mode',
                  style: GoogleFonts.outfit(fontSize: 14)),
              ]),
            ),
            const PopupMenuDivider(height: 1),
            PopupMenuItem<String>(
              value: 'logout',
              child: Row(children: [
                const Icon(Icons.logout_rounded, size: 18, color: AdminTheme.red),
                const SizedBox(width: 12),
                Text('Đăng xuất',
                  style: GoogleFonts.outfit(fontSize: 14, color: AdminTheme.red, fontWeight: FontWeight.w600)),
              ]),
            ),
          ],
        ),
        const SizedBox(width: 8),
      ],
    );
  }
}
