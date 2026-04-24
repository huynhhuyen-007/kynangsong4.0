import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../utils/api_service.dart';
import '../../utils/auth_manager.dart';
import '../widgets/admin_scaffold.dart';
import '../widgets/admin_app_bar.dart';
import '../admin_theme.dart';

class AdminDashboardScreen extends StatefulWidget {
  const AdminDashboardScreen({super.key});
  @override
  State<AdminDashboardScreen> createState() => _AdminDashboardScreenState();
}

class _AdminDashboardScreenState extends State<AdminDashboardScreen> {
  Map<String, dynamic>? _stats;
  Map<String, String>? _admin;
  bool _loading = true;
  DateTime? _lastUpdated;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    try {
      final admin = await AuthManager.getUser();
      final stats = await ApiService.getAdminStats(admin['id']!);
      if (mounted) {
        setState(() {
          _admin = admin;
          _stats = stats;
          _loading = false;
          _lastUpdated = DateTime.now();
        });
      }
    } catch (_) {
      if (mounted) setState(() => _loading = false);
    }
  }

  String _formatTime(DateTime? dt) {
    if (dt == null) return '—';
    final h = dt.hour.toString().padLeft(2, '0');
    final m = dt.minute.toString().padLeft(2, '0');
    final s = dt.second.toString().padLeft(2, '0');
    return '$h:$m:$s';
  }

  @override
  Widget build(BuildContext context) {
    return AdminScaffold(
      currentIndex: 0,
      child: Scaffold(
        appBar: AdminAppBar(
          title: 'Dashboard',
          showRefresh: true,
          onRefresh: _load,
        ),
        body: _loading
            ? const Center(child: CircularProgressIndicator(color: AdminTheme.blue))
            : RefreshIndicator(
                onRefresh: _load,
                color: AdminTheme.blue,
                child: SingleChildScrollView(
                  physics: const AlwaysScrollableScrollPhysics(),
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildWelcome(),
                      const SizedBox(height: 20),
                      _buildLastUpdated(),
                      const SizedBox(height: 16),
                      _buildStatsGrid(),
                      const SizedBox(height: 20),
                      _buildAlertPanel(),
                      const SizedBox(height: 20),
                      _buildSystemInfo(),
                    ],
                  ),
                ),
              ),
      ),
    );
  }

  Widget _buildWelcome() {
    final hour = DateTime.now().hour;
    final greeting = hour < 12 ? '☀️ Good morning' : hour < 18 ? '🌤 Good afternoon' : '🌙 Good evening';
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(greeting,
          style: GoogleFonts.outfit(fontSize: 13, color: AdminTheme.textSecondary)),
        const SizedBox(height: 4),
        Text('${_admin?['name'] ?? 'Admin'} 👋',
          style: GoogleFonts.outfit(fontSize: 22, fontWeight: FontWeight.w800, color: AdminTheme.textPrimary)),
      ],
    );
  }

  Widget _buildLastUpdated() {
    return Row(
      children: [
        const Icon(Icons.update_rounded, size: 14, color: AdminTheme.textMuted),
        const SizedBox(width: 6),
        Text(
          'Cập nhật lúc: ${_formatTime(_lastUpdated)}',
          style: GoogleFonts.outfit(fontSize: 12, color: AdminTheme.textMuted),
        ),
      ],
    );
  }

  Widget _buildStatsGrid() {
    final cards = [
      _StatCard(label: 'Total Users', value: '${_stats?['total_users'] ?? 0}',
        icon: Icons.people_rounded, color: AdminTheme.blue, route: '/admin_users'),
      _StatCard(label: 'Kỹ năng', value: '${_stats?['total_skills'] ?? 0}',
        icon: Icons.school_rounded, color: AdminTheme.green, route: '/admin_content'),
      _StatCard(label: 'Tin tức', value: '${_stats?['total_news'] ?? 0}',
        icon: Icons.article_rounded, color: AdminTheme.purple, route: '/admin_content'),
      _StatCard(label: 'Bài đăng', value: '${_stats?['total_posts'] ?? 0}',
        icon: Icons.forum_rounded, color: AdminTheme.orange, route: '/admin_moderation'),
    ];
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Thống kê hệ thống',
          style: GoogleFonts.outfit(fontSize: 15, fontWeight: FontWeight.w700, color: AdminTheme.textPrimary)),
        const SizedBox(height: 12),
        GridView.count(
          crossAxisCount: 2,
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          crossAxisSpacing: 12,
          mainAxisSpacing: 12,
          childAspectRatio: 1.8,
          children: cards.map((c) => _buildStatCard(c)).toList(),
        ),
      ],
    );
  }

  Widget _buildStatCard(_StatCard card) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return GestureDetector(
      onTap: () => Navigator.pushReplacementNamed(context, card.route),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Theme.of(context).cardTheme.color,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isDark ? AdminTheme.border : const Color(0xFFE2E8F0),
          ),
          boxShadow: isDark
              ? []
              : [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.07),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  ),
                ],
        ),
        child: Row(
          children: [
            Container(
              width: 40, height: 40,
              decoration: BoxDecoration(
                color: card.color.withOpacity(0.15),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(card.icon, color: card.color, size: 20),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(card.value,
                    style: GoogleFonts.outfit(
                      fontSize: 22,
                      fontWeight: FontWeight.w800,
                      color: isDark ? AdminTheme.textPrimary : const Color(0xFF111111),
                    )),
                  Text(card.label,
                    style: GoogleFonts.outfit(
                      fontSize: 11,
                      fontWeight: FontWeight.w500,
                      color: isDark ? AdminTheme.textSecondary : const Color(0xFF555555),
                    )),
                ],
              ),
            ),
            Icon(Icons.chevron_right_rounded,
                color: isDark ? AdminTheme.textMuted : const Color(0xFF888888),
                size: 18),
          ],
        ),
      ),
    );
  }

  Widget _buildAlertPanel() {
    final reported = _stats?['reported_posts'] ?? 0;
    final hidden = _stats?['hidden_posts'] ?? 0;
    if (reported == 0 && hidden == 0) {
      return Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: AdminTheme.green.withOpacity(0.08),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: AdminTheme.green.withOpacity(0.3)),
        ),
        child: Row(children: [
          const Icon(Icons.check_circle_outline, color: AdminTheme.green, size: 18),
          const SizedBox(width: 10),
          Text('Không có bài nào cần xử lý 🎉',
            style: GoogleFonts.outfit(color: AdminTheme.green, fontWeight: FontWeight.w600, fontSize: 13)),
        ]),
      );
    }
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('⚠️ Cần xử lý',
          style: GoogleFonts.outfit(fontSize: 15, fontWeight: FontWeight.w700, color: AdminTheme.textPrimary)),
        const SizedBox(height: 10),
        if (reported > 0)
          _alertBanner(Icons.flag_rounded, '$reported bài bị báo cáo', AdminTheme.red,
            route: '/admin_moderation'),
        if (reported > 0 && hidden > 0) const SizedBox(height: 8),
        if (hidden > 0)
          _alertBanner(Icons.visibility_off_rounded, '$hidden bài đang bị ẩn', AdminTheme.orange,
            route: '/admin_moderation'),
      ],
    );
  }

  Widget _alertBanner(IconData icon, String text, Color color, {required String route}) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return GestureDetector(
      onTap: () => Navigator.pushReplacementNamed(context, route),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        decoration: BoxDecoration(
          color: isDark
              ? color.withOpacity(0.15)
              : color.withOpacity(0.08),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(
            color: isDark ? color.withOpacity(0.5) : color.withOpacity(0.7),
            width: 1.5,
          ),
        ),
        child: Row(children: [
          Container(
            padding: const EdgeInsets.all(6),
            decoration: BoxDecoration(
              color: color.withOpacity(0.15),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, color: color, size: 16),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(text,
              style: GoogleFonts.outfit(
                fontSize: 13,
                color: isDark ? color : color.withRed((color.red * 0.75).round()),
                fontWeight: FontWeight.w700,
              )),
          ),
          Icon(Icons.arrow_forward_ios_rounded, size: 12, color: color),
        ]),
      ),
    );
  }

  Widget _buildSystemInfo() {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Theme.of(context).cardTheme.color,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isDark ? AdminTheme.border : const Color(0xFFE2E8F0),
        ),
        boxShadow: isDark
            ? []
            : [
                BoxShadow(
                  color: Colors.black.withOpacity(0.06),
                  blurRadius: 8,
                  offset: const Offset(0, 3),
                ),
              ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Thông tin hệ thống',
            style: GoogleFonts.outfit(
              fontSize: 14, fontWeight: FontWeight.w700,
              color: isDark ? AdminTheme.textPrimary : const Color(0xFF111111),
            )),
          const SizedBox(height: 12),
          _infoRow('Admin ID', _admin?['id'] ?? '—'),
          const Divider(color: AdminTheme.border, height: 20),
          _infoRow('Email', _admin?['email'] ?? '—'),
          const Divider(color: AdminTheme.border, height: 20),
          _infoRow('Role', _admin?['role'] ?? '—'),
          const Divider(color: AdminTheme.border, height: 20),
          _infoRow('API', 'http://192.168.8.200:8000'),
        ],
      ),
    );
  }

  Widget _infoRow(String label, String value) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Row(children: [
      SizedBox(width: 80,
        child: Text(label,
          style: GoogleFonts.outfit(
            fontSize: 12,
            fontWeight: FontWeight.w600,
            color: isDark ? AdminTheme.textSecondary : const Color(0xFF555555),
          ))),
      Expanded(
        child: Text(value,
          style: GoogleFonts.outfit(
            fontSize: 13,
            color: isDark ? AdminTheme.textPrimary : const Color(0xFF111111),
            fontWeight: FontWeight.w600,
          ),
          overflow: TextOverflow.ellipsis)),
    ]);
  }
}

class _StatCard {
  final String label, value, route;
  final IconData icon;
  final Color color;
  const _StatCard({required this.label, required this.value, required this.icon,
    required this.color, required this.route});
}
