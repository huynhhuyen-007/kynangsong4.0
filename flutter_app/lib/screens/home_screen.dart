import 'dart:math';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../utils/auth_manager.dart';
import '../utils/api_service.dart';
import '../utils/user_progress_manager.dart';
import '../widgets/app_scaffold.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> with SingleTickerProviderStateMixin {
  String _userName = '';
  Map<String, dynamic> _progress = {};
  bool _loading = true;
  late AnimationController _animCtrl;
  late Animation<double> _fadeAnim;

  @override
  void initState() {
    super.initState();
    _animCtrl = AnimationController(vsync: this, duration: const Duration(milliseconds: 700));
    _fadeAnim = CurvedAnimation(parent: _animCtrl, curve: Curves.easeOut);
    _init();
  }

  @override
  void dispose() {
    _animCtrl.dispose();
    super.dispose();
  }

  Future<void> _init() async {
    final user = await AuthManager.getUser();
    final progress = await UserProgressManager.getSummary();
    if (mounted) {
      setState(() {
        _userName = user['name'] ?? '';
        _progress = progress;
        _loading = false;
      });
      _animCtrl.forward();
    }
  }

  String _greeting() {
    final h = DateTime.now().hour;
    if (h < 12) return 'Chào buổi sáng';
    if (h < 18) return 'Chào buổi chiều';
    return 'Chào buổi tối';
  }

  @override
  Widget build(BuildContext context) {
    return AppScaffold(
      title: 'Trang chủ',
      currentIndex: 0,
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => Navigator.pushNamed(context, '/copilot'),
        backgroundColor: const Color(0xFF4F46E5),
        icon: const Icon(Icons.smart_toy_rounded, color: Colors.white),
        label: Text('Hỏi AI', style: GoogleFonts.outfit(color: Colors.white, fontWeight: FontWeight.bold)),
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : FadeTransition(
              opacity: _fadeAnim,
              child: SingleChildScrollView(
                padding: const EdgeInsets.only(bottom: 24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildHeroHeader(),
                    _buildXpStreakBar(),
                    _buildSectionTitle('🚀 Khám phá nhanh'),
                    _buildQuickGrid(),
                    _buildSectionTitle('🎯 Hành trình học tập'),
                    _buildJourneyCards(),
                    const SizedBox(height: 8),
                  ],
                ),
              ),
            ),
    );
  }

  Widget _buildHeroHeader() {
    final streak = _progress['streak'] ?? 0;
    return Container(
      width: double.infinity,
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          colors: [Color(0xFF4F46E5), Color(0xFF7C3AED)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      padding: const EdgeInsets.fromLTRB(24, 28, 24, 32),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            _greeting() + ',',
            style: GoogleFonts.outfit(color: Colors.white70, fontSize: 15),
          ),
          const SizedBox(height: 4),
          Text(
            _userName.isEmpty ? 'Bạn ơi 👋' : '$_userName 👋',
            style: GoogleFonts.outfit(
              fontSize: 28, fontWeight: FontWeight.w800, color: Colors.white,
            ),
          ),
          const SizedBox(height: 12),
          Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.18),
                borderRadius: BorderRadius.circular(20),
              ),
              child: streak > 0
                  ? Row(mainAxisSize: MainAxisSize.min, children: [
                      const Text('🔥', style: TextStyle(fontSize: 16)),
                      const SizedBox(width: 6),
                      Text(
                        'Chuỗi $streak ngày học liên tiếp!',
                        style: GoogleFonts.outfit(color: Colors.white, fontWeight: FontWeight.w600),
                      ),
                    ])
                  : Text(
                      '✨ Bắt đầu học hôm nay để tạo streak!',
                      style: GoogleFonts.outfit(color: Colors.white, fontWeight: FontWeight.w500, fontSize: 13),
                    ),
            ),
            const SizedBox(height: 16),
            _buildStartButton(streak > 0 ? 'Tiếp tục học' : '🚀 Học ngay'),
          ]),
        ],
      ),
    );
  }

  Widget _buildStartButton(String label) {
    return ElevatedButton.icon(
      onPressed: () => Navigator.pushReplacementNamed(context, '/skills'),
      icon: const Icon(Icons.rocket_launch_rounded, size: 20, color: Color(0xFF4F46E5)),
      label: Text(
        label,
        style: const TextStyle(
          inherit: false,
          color: Color(0xFF4F46E5),
          fontWeight: FontWeight.w800,
          fontSize: 15,
          fontFamily: 'Outfit',
        ),
      ),
      style: ElevatedButton.styleFrom(
        backgroundColor: Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
        elevation: 6,
        shadowColor: Colors.black38,
        textStyle: const TextStyle(
          inherit: false,
          fontFamily: 'Outfit',
          fontSize: 15,
          fontWeight: FontWeight.w800,
        ),
      ),
    );
  }

  Widget _buildXpStreakBar() {
    final xp = _progress['xp'] ?? 0;
    final level = _progress['level'] ?? 1;
    final label = _progress['levelLabel'] ?? 'Người mới';
    final completed = _progress['completedSkills'] ?? 0;
    final bookmarked = _progress['bookmarkedNews'] ?? 0;

    // XP thresholds
    final thresholds = [0, 20, 50, 100, 200, 999];
    final nextXp = thresholds[level < thresholds.length - 1 ? level : thresholds.length - 1];
    final prevXp = thresholds[level - 1 < thresholds.length ? level - 1 : 0];
    final progress = nextXp > prevXp ? ((xp - prevXp) / (nextXp - prevXp)).clamp(0.0, 1.0) : 1.0;

    return Container(
      margin: const EdgeInsets.fromLTRB(16, 16, 16, 0),
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [BoxShadow(color: const Color(0xFF4F46E5).withValues(alpha: 0.1), blurRadius: 16, offset: const Offset(0, 6))],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(color: const Color(0xFF4F46E5), borderRadius: BorderRadius.circular(20)),
              child: Text('Lv.$level $label', style: GoogleFonts.outfit(color: Colors.white, fontWeight: FontWeight.w700, fontSize: 12)),
            ),
            const Spacer(),
            Text('$xp XP', style: GoogleFonts.outfit(color: const Color(0xFF4F46E5), fontWeight: FontWeight.w800, fontSize: 16)),
          ]),
          const SizedBox(height: 10),
          ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: TweenAnimationBuilder<double>(
              tween: Tween(begin: 0, end: progress),
              duration: const Duration(milliseconds: 1500),
              curve: Curves.easeOutCubic,
              builder: (ctx, val, child) => LinearProgressIndicator(
                value: val,
                backgroundColor: const Color(0xFFEEF2FF),
                valueColor: AlwaysStoppedAnimation<Color>(val > 0.0 ? const Color(0xFF4F46E5) : const Color(0xFF9CA3AF)),
                minHeight: 12,
              ),
            ),
          ),
          const SizedBox(height: 6),
          Text(
            nextXp < 999 ? 'Cần thêm ${nextXp - xp} XP để lên Lv.${level + 1}' : '🎉 Đã đạt cấp cao nhất!',
            style: GoogleFonts.outfit(fontSize: 11, color: Colors.grey.shade500),
          ),
          const SizedBox(height: 14),
          Row(children: [
            _miniStat('🏅', '$completed', 'Kỹ năng'),
            _miniStat('📰', '$bookmarked', 'Tin đã lưu'),
            _miniStat('🔥', '${_progress['streak'] ?? 0}', 'Ngày streak'),
          ]),
        ],
      ),
    );
  }

  Widget _miniStat(String emoji, String val, String label) {
    return Expanded(
      child: Column(children: [
        Text(emoji, style: const TextStyle(fontSize: 20)),
        const SizedBox(height: 2),
        Text(val, style: GoogleFonts.outfit(fontWeight: FontWeight.w800, fontSize: 18, color: const Color(0xFF1E1B4B))),
        Text(label, style: GoogleFonts.outfit(fontSize: 10, color: Colors.grey.shade500)),
      ]),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 20, 16, 12),
      child: Text(title, style: GoogleFonts.outfit(fontSize: 18, fontWeight: FontWeight.w800, color: const Color(0xFF1E1B4B))),
    );
  }

  Widget _buildQuickGrid() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Column(children: [
        _quickCardHero('📚 Khoá Học Mới', 'Cải thiện kỹ năng mềm ngay hôm nay', Icons.rocket_launch_rounded, const Color(0xFF4F46E5), '/skills'),
        const SizedBox(height: 12),
        Row(children: [
          Expanded(child: _quickCardSmall('Sân Chơi', Icons.videogame_asset_rounded, const Color(0xFF059669), '/playground')),
          const SizedBox(width: 12),
          Expanded(child: _quickCardSmall('Cộng Đồng', Icons.people_rounded, const Color(0xFF7C3AED), '/community')),
          const SizedBox(width: 12),
          Expanded(child: _quickCardSmall('Tin Tức', Icons.newspaper_rounded, const Color(0xFF0891B2), '/news')),
        ]),
      ]),
    );
  }

  Widget _quickCardHero(String title, String sub, IconData icon, Color color, String route) {
    return InkWell(
      onTap: () => Navigator.pushReplacementNamed(context, route),
      borderRadius: BorderRadius.circular(20),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
        decoration: BoxDecoration(
          gradient: LinearGradient(colors: [color, color.withRed(100)]),
          borderRadius: BorderRadius.circular(20),
          boxShadow: [BoxShadow(color: color.withValues(alpha: 0.3), blurRadius: 16, offset: const Offset(0, 6))],
        ),
        child: Row(children: [
          Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(title, style: GoogleFonts.outfit(fontSize: 20, fontWeight: FontWeight.w800, color: Colors.white)),
            const SizedBox(height: 6),
            Text(sub, style: GoogleFonts.outfit(fontSize: 13, color: Colors.white.withValues(alpha: 0.8))),
          ])),
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(color: Colors.white.withValues(alpha: 0.2), shape: BoxShape.circle),
            child: Icon(icon, color: Colors.white, size: 40),
          ),
        ]),
      ),
    );
  }

  Widget _quickCardSmall(String title, IconData icon, Color color, String route) {
    return InkWell(
      onTap: () => Navigator.pushReplacementNamed(context, route),
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 20),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: color.withValues(alpha: 0.2)),
          boxShadow: [BoxShadow(color: color.withValues(alpha: 0.05), blurRadius: 8, offset: const Offset(0, 4))],
        ),
        child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
          Icon(icon, color: color, size: 30),
          const SizedBox(height: 10),
          Text(title, style: GoogleFonts.outfit(fontSize: 13, fontWeight: FontWeight.w700, color: const Color(0xFF1E1B4B))),
        ]),
      ),
    );
  }

  Widget _buildJourneyCards() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Column(children: [
        _journeyCard(
          '📚 Đọc bài viết',
          'Tin tức mới nhất về kỹ năng sống',
          'Vào Tin tức →',
          const Color(0xFF0891B2),
          () => Navigator.pushReplacementNamed(context, '/news'),
        ),
        const SizedBox(height: 10),
        _journeyCard(
          '🎮 Thử thách bản thân',
          'Tham gia Sân chơi để rèn luyện kỹ năng',
          'Vào Sân chơi →',
          const Color(0xFF059669),
          () => Navigator.pushReplacementNamed(context, '/playground'),
        ),
        const SizedBox(height: 10),
        _journeyCard(
          '💬 Chia sẻ cộng đồng',
          'Thảo luận và học từ trải nghiệm thật',
          'Vào Cộng đồng →',
          const Color(0xFF7C3AED),
          () => Navigator.pushReplacementNamed(context, '/community'),
        ),
      ]),
    );
  }

  Widget _journeyCard(String title, String subtitle, String cta, Color color, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: color.withValues(alpha: 0.2)),
          boxShadow: [BoxShadow(color: color.withValues(alpha: 0.07), blurRadius: 10, offset: const Offset(0, 4))],
        ),
        child: Row(children: [
          Container(
            width: 4, height: 40,
            decoration: BoxDecoration(color: color, borderRadius: BorderRadius.circular(4)),
          ),
          const SizedBox(width: 14),
          Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(title, style: GoogleFonts.outfit(fontWeight: FontWeight.w700, fontSize: 14, color: const Color(0xFF1E1B4B))),
            const SizedBox(height: 3),
            Text(subtitle, style: GoogleFonts.outfit(fontSize: 12, color: Colors.grey.shade600)),
          ])),
          Text(cta, style: GoogleFonts.outfit(color: color, fontWeight: FontWeight.w700, fontSize: 12)),
        ]),
      ),
    );
  }
}
