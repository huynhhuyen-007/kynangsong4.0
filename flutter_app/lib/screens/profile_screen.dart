import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:image_picker/image_picker.dart';
import '../utils/auth_manager.dart';
import '../utils/api_service.dart';
import '../utils/user_progress_manager.dart';
import '../widgets/app_scaffold.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  String _id = '';
  String _name = '';
  String _email = '';
  String _avatarUrl = '';
  Map<String, dynamic> _progress = {};
  bool _loading = true;
  String _selectedGoal = '';
  bool _uploadingAvatar = false;

  final List<Map<String, dynamic>> _goals = [
    {'label': '💪 Tự tin hơn', 'value': 'tu_tin'},
    {'label': '🗣️ Giỏi giao tiếp', 'value': 'giao_tiep'},
    {'label': '💰 Quản lý tài chính', 'value': 'tai_chinh'},
    {'label': '⏰ Quản lý thời gian', 'value': 'thoi_gian'},
    {'label': '🧠 Tư duy tích cực', 'value': 'tu_duy'},
    {'label': '🤝 Làm việc nhóm', 'value': 'nhom'},
  ];

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    final user = await AuthManager.getUser();
    final progress = await UserProgressManager.getSummary();
    final goal = await UserProgressManager.getGoal();
    if (mounted) {
      setState(() {
        _id = user['id'] ?? '';
        _name = user['name'] ?? '';
        _email = user['email'] ?? '';
        _avatarUrl = user['avatar_url'] ?? '';
        _progress = progress;
        _selectedGoal = goal;
        _loading = false;
      });
    }
  }

  String _xpToNextLevel() {
    final xp = _progress['xp'] ?? 0;
    final level = _progress['level'] ?? 1;
    final thresholds = [0, 20, 50, 100, 200, 999];
    final nextXp = thresholds[level < thresholds.length - 1 ? level : thresholds.length - 1];
    return level >= 5 ? '🏆 Đã đạt cấp cao nhất!' : 'Cần ${nextXp - xp} XP để lên cấp tiếp theo';
  }

  Future<void> _doLogout() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text('Đăng xuất', style: GoogleFonts.outfit(fontWeight: FontWeight.w700)),
        content: Text('Bạn có chắc muốn đăng xuất không?', style: GoogleFonts.outfit()),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false),
              child: Text('Hủy', style: GoogleFonts.outfit(color: Colors.grey))),
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
              child: Column(children: [
                _buildHeader(),
                _buildXpCard(),
                _buildGoalSection(),
                _buildStatsRow(),
                _buildMenuItems(),
                const SizedBox(height: 32),
              ]),
            ),
    );
  }

  Future<void> _changeAvatar() async {
    final picker = ImagePicker();
    final xfile = await picker.pickImage(source: ImageSource.gallery, maxWidth: 800, maxHeight: 800);
    if (xfile == null) return;

    setState(() => _uploadingAvatar = true);
    try {
      final newUrl = await ApiService.uploadAvatar(_id, xfile.path);
      await AuthManager.updateAvatar(newUrl);
      if (mounted) setState(() => _avatarUrl = newUrl);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.toString()), backgroundColor: Colors.red));
      }
    } finally {
      if (mounted) setState(() => _uploadingAvatar = false);
    }
  }

  Widget _buildHeader() {
    return Container(
      width: double.infinity,
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          colors: [Color(0xFF4F46E5), Color(0xFF7C3AED)],
          begin: Alignment.topLeft, end: Alignment.bottomRight,
        ),
      ),
      padding: const EdgeInsets.fromLTRB(24, 32, 24, 28),
      child: Column(children: [
        Stack(
          alignment: Alignment.bottomRight,
          children: [
            Container(
              width: 84, height: 84,
              decoration: BoxDecoration(
                color: Colors.white, shape: BoxShape.circle,
                boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.2), blurRadius: 16, offset: const Offset(0, 6))],
              ),
              child: ClipOval(
                child: _uploadingAvatar
                    ? const Center(child: Padding(padding: EdgeInsets.all(24), child: CircularProgressIndicator()))
                    : _avatarUrl.isNotEmpty
                        ? Image.network('http://10.0.2.2:8000$_avatarUrl', fit: BoxFit.cover, errorBuilder: (_,__,___) => const Icon(Icons.person, size: 40))
                        : Center(child: Text(
                            _name.isNotEmpty ? _name[0].toUpperCase() : '?',
                            style: GoogleFonts.outfit(fontSize: 34, fontWeight: FontWeight.w800, color: const Color(0xFF4F46E5)),
                          )),
              ),
            ),
            GestureDetector(
              onTap: _changeAvatar,
              child: Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(color: const Color(0xFFD97706), shape: BoxShape.circle, border: Border.all(color: Colors.white, width: 2)),
                child: const Icon(Icons.camera_alt_rounded, color: Colors.white, size: 16),
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Text(_name.isEmpty ? 'Người dùng' : _name,
          style: GoogleFonts.outfit(fontSize: 22, fontWeight: FontWeight.w800, color: Colors.white)),
        const SizedBox(height: 4),
        Text(_email, style: GoogleFonts.outfit(fontSize: 13, color: Colors.white70)),
        const SizedBox(height: 12),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 5),
          decoration: BoxDecoration(color: Colors.white.withValues(alpha: 0.2), borderRadius: BorderRadius.circular(20)),
          child: Text(
            '${_progress['levelLabel'] ?? 'Người mới'} • Lv.${_progress['level'] ?? 1}',
            style: GoogleFonts.outfit(color: Colors.white, fontWeight: FontWeight.w700, fontSize: 13),
          ),
        ),
      ]),
    );
  }

  Widget _buildXpCard() {
    final xp = _progress['xp'] ?? 0;
    final level = _progress['level'] ?? 1;
    final thresholds = [0, 20, 50, 100, 200, 999];
    final nextXp = thresholds[level < thresholds.length - 1 ? level : thresholds.length - 1];
    final prevXp = thresholds[level - 1 < thresholds.length ? level - 1 : 0];
    final pct = nextXp > prevXp ? ((xp - prevXp) / (nextXp - prevXp)).clamp(0.0, 1.0) : 1.0;

    return Container(
      margin: const EdgeInsets.fromLTRB(16, 16, 16, 0),
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: const Color(0xFFEEF2FF)),
        boxShadow: [BoxShadow(color: const Color(0xFF4F46E5).withValues(alpha: 0.07), blurRadius: 12, offset: const Offset(0, 4))],
      ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [
          const Text('⚡', style: TextStyle(fontSize: 18)),
          const SizedBox(width: 8),
          Text('Điểm kinh nghiệm (XP)', style: GoogleFonts.outfit(fontWeight: FontWeight.w700, fontSize: 14)),
          const Spacer(),
          Text('$xp XP', style: GoogleFonts.outfit(color: const Color(0xFF4F46E5), fontWeight: FontWeight.w800, fontSize: 18)),
        ]),
        const SizedBox(height: 10),
        ClipRRect(
          borderRadius: BorderRadius.circular(8),
          child: TweenAnimationBuilder<double>(
            tween: Tween(begin: 0, end: pct),
            duration: const Duration(milliseconds: 1500),
            curve: Curves.easeOutBack,
            builder: (ctx, val, child) => LinearProgressIndicator(
              value: val,
              backgroundColor: const Color(0xFFEEF2FF),
              valueColor: const AlwaysStoppedAnimation<Color>(Color(0xFF4F46E5)),
              minHeight: 12,
            ),
          ),
        ),
        const SizedBox(height: 6),
        Text(_xpToNextLevel(), style: GoogleFonts.outfit(fontSize: 11, color: Colors.grey.shade500)),
        const SizedBox(height: 14),
        Wrap(spacing: 8, runSpacing: 6, children: [
          _xpBadge('🎖️ Thông thái: +2 XP khi đọc', ''),
          _xpBadge('💾 Nhà sưu tầm: +1 XP khi lưu', ''),
        ]),
      ]),
    );
  }

  Widget _xpBadge(String label, String xp) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
    decoration: BoxDecoration(color: const Color(0xFFF0F4FF), borderRadius: BorderRadius.circular(10)),
    child: Row(mainAxisSize: MainAxisSize.min, children: [
      Text(label, style: GoogleFonts.outfit(fontSize: 11, color: const Color(0xFF4F46E5), fontWeight: FontWeight.w600)),
      const SizedBox(width: 4),
      Text(xp, style: GoogleFonts.outfit(fontSize: 11, color: Colors.grey.shade500)),
    ]),
  );

  Widget _buildGoalSection() {
    return Container(
      margin: const EdgeInsets.fromLTRB(16, 14, 16, 0),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: const Color(0xFFEEF2FF)),
      ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [
          const Text('🎯', style: TextStyle(fontSize: 18)),
          const SizedBox(width: 8),
          Text('Mục tiêu của tôi', style: GoogleFonts.outfit(fontWeight: FontWeight.w700, fontSize: 14, color: const Color(0xFF1E1B4B))),
          const SizedBox(width: 6),
          Text('(chọn 1)', style: GoogleFonts.outfit(fontSize: 11, color: Colors.grey.shade400)),
        ]),
        const SizedBox(height: 12),
        Wrap(spacing: 8, runSpacing: 8,
          children: _goals.map((g) => GestureDetector(
            onTap: () async {
              await UserProgressManager.setGoal(g['value'] as String);
              setState(() => _selectedGoal = g['value'] as String);
              if (mounted) {
                ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                  content: Text('✅ Mục tiêu: ${g['label']}', style: GoogleFonts.outfit()),
                  behavior: SnackBarBehavior.floating, duration: const Duration(seconds: 1),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  margin: const EdgeInsets.only(bottom: 80, left: 16, right: 16),
                ));
              }
            },
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
              decoration: BoxDecoration(
                color: _selectedGoal == g['value'] ? const Color(0xFF4F46E5) : const Color(0xFFF0F4FF),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Text(g['label'] as String,
                style: GoogleFonts.outfit(
                  fontSize: 13, fontWeight: FontWeight.w600,
                  color: _selectedGoal == g['value'] ? Colors.white : Colors.grey.shade700,
                )),
            ),
          )).toList(),
        ),
      ]),
    );
  }

  Widget _buildStatsRow() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 14, 16, 0),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Padding(
          padding: const EdgeInsets.only(left: 4, bottom: 8),
          child: Text('Thống kê của bạn', style: GoogleFonts.outfit(fontWeight: FontWeight.w700, fontSize: 15, color: const Color(0xFF1E1B4B))),
        ),
        Row(children: [
          _statCard('🔥', '${_progress['streak'] ?? 0}', 'Chuỗi ngày học', const Color(0xFFD97706)),
          const SizedBox(width: 8),
          _statCard('📚', '${_progress['completedSkills'] ?? 0}', 'Khóa đã học', const Color(0xFF4F46E5)),
          const SizedBox(width: 8),
          _statCard('💾', '${_progress['savedTips'] ?? 0}', 'Mẹo đã lưu', const Color(0xFF059669)),
        ]),
      ]),
    );
  }

  Widget _statCard(String emoji, String val, String label, Color color) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: color.withValues(alpha: 0.2)),
          boxShadow: [BoxShadow(color: color.withValues(alpha: 0.07), blurRadius: 8, offset: const Offset(0, 4))],
        ),
        child: Column(children: [
          Text(emoji, style: const TextStyle(fontSize: 20)),
          const SizedBox(height: 4),
          Text(val, style: GoogleFonts.outfit(fontSize: 18, fontWeight: FontWeight.w800, color: color)),
          Text(label, textAlign: TextAlign.center, style: GoogleFonts.outfit(fontSize: 11, color: Colors.grey.shade700, fontWeight: FontWeight.w600)),
        ]),
      ),
    );
  }

  Widget _buildMenuItems() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 20, 16, 0),
      child: Column(children: [
        _menuItem(Icons.history_edu_rounded, 'Lịch sử học', 'Quá trình học tập kỹ năng', () => Navigator.pushNamed(context, '/skills'), color: const Color(0xFF4F46E5)),
        _menuItem(Icons.quiz_rounded, 'Lịch sử Quiz', 'Xem lại bài kiểm tra', () => Navigator.pushNamed(context, '/playground'), color: const Color(0xFF059669)),
        _menuItem(Icons.bookmark_rounded, 'Mẹo đã lưu', 'Những mẹo vặt yêu thích', () => Navigator.pushNamed(context, '/fun'), color: const Color(0xFFD97706)),
        _menuItem(Icons.article_rounded, 'Bài viết tương tác', 'Những bài viết bạn đã xem', () => Navigator.pushNamed(context, '/news'), color: const Color(0xFF0891B2)),
        const SizedBox(height: 6),
        _menuItem(Icons.logout, 'Đăng xuất', 'Thoát khỏi tài khoản', _doLogout,
            iconColor: Colors.red.shade400, textColor: Colors.red.shade400),
      ]),
    );
  }

  Widget _menuItem(IconData icon, String title, String subtitle, VoidCallback onTap,
      {Color? color, Color? iconColor, Color? textColor}) {
    final ic = iconColor ?? color ?? const Color(0xFF4F46E5);
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
          decoration: BoxDecoration(color: ic.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(10)),
          child: Icon(icon, color: ic, size: 20),
        ),
        title: Text(title, style: GoogleFonts.outfit(fontWeight: FontWeight.w600, color: textColor ?? const Color(0xFF1E1B4B))),
        subtitle: Text(subtitle, style: GoogleFonts.outfit(fontSize: 12, color: Colors.grey.shade500)),
        trailing: Icon(Icons.chevron_right, color: Colors.grey.shade400),
        onTap: onTap,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      ),
    );
  }
}
