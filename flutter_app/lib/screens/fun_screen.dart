import 'dart:math';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../utils/api_service.dart';
import '../utils/user_progress_manager.dart';
import '../widgets/app_scaffold.dart';

class FunScreen extends StatefulWidget {
  const FunScreen({super.key});

  @override
  State<FunScreen> createState() => _FunScreenState();
}

class _FunScreenState extends State<FunScreen> with SingleTickerProviderStateMixin {
  List<dynamic> _allFun = [];
  List<dynamic> _filtered = [];
  bool _isLoading = true;
  String _filter = 'all'; // all | tip | video
  String _searchQuery = '';
  Set<String> _likedIds = {};
  Set<String> _savedIds = {};
  final TextEditingController _searchCtrl = TextEditingController();

  final List<Map<String, dynamic>> _situations = [
    {'label': '😔 Mất động lực', 'keyword': 'động lực'},
    {'label': '💰 Quản lý tiền', 'keyword': 'tài chính'},
    {'label': '🗣️ Giao tiếp', 'keyword': 'giao tiếp'},
    {'label': '⏰ Quản lý thời gian', 'keyword': 'thời gian'},
  ];

  @override
  void initState() {
    super.initState();
    _loadFun();
    _loadUserState();
  }

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  Future<void> _loadUserState() async {
    final liked = await UserProgressManager.getLikedTipIds();
    final saved = await UserProgressManager.getSavedTipIds();
    if (mounted) {
      setState(() {
        _likedIds = Set.from(liked);
        _savedIds = Set.from(saved);
      });
    }
  }

  Future<void> _loadFun() async {
    try {
      final funs = await ApiService.getFun();
      if (mounted) {
        setState(() {
          _allFun = funs;
          _isLoading = false;
        });
        _applyFilter();
      }
    } catch (e) {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _applyFilter() {
    setState(() {
      _filtered = _allFun.where((item) {
        final matchType = _filter == 'all' || item['type'] == _filter;
        final q = _searchQuery.toLowerCase();
        final matchSearch = q.isEmpty ||
            (item['title'] ?? '').toLowerCase().contains(q) ||
            (item['content'] ?? '').toLowerCase().contains(q);
        return matchType && matchSearch;
      }).toList();
    });
  }

  void _randomTip() {
    final tips = _allFun.where((i) => i['type'] != 'video').toList();
    if (tips.isEmpty) return;
    final tip = tips[Random().nextInt(tips.length)];
    _showTipDialog(tip);
  }

  void _showTipDialog(Map<String, dynamic> tip) {
    showDialog(
      context: context,
      builder: (ctx) => Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(mainAxisSize: MainAxisSize.min, children: [
            const Text('💡', style: TextStyle(fontSize: 48)),
            const SizedBox(height: 12),
            Text(
              tip['title'] ?? '',
              textAlign: TextAlign.center,
              style: GoogleFonts.outfit(fontWeight: FontWeight.w800, fontSize: 18, color: const Color(0xFF1E1B4B)),
            ),
            const SizedBox(height: 12),
            Text(
              tip['content'] ?? '',
              textAlign: TextAlign.center,
              style: GoogleFonts.outfit(color: Colors.grey.shade700, height: 1.6, fontSize: 14),
            ),
            const SizedBox(height: 20),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFFD97706),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
              onPressed: () => Navigator.pop(ctx),
              child: Text('Tuyệt vời! 👍', style: GoogleFonts.outfit(fontWeight: FontWeight.w700)),
            ),
          ]),
        ),
      ),
    );
  }

  Future<void> _toggleLike(String id) async {
    await UserProgressManager.toggleLikeTip(id);
    final liked = await UserProgressManager.getLikedTipIds();
    if (mounted) setState(() => _likedIds = Set.from(liked));
    if (mounted && !_likedIds.contains(id)) {
      // was liked, show XP
    } else {
      _showXpToast('+1 XP ❤️');
    }
  }

  Future<void> _toggleSave(String id) async {
    final wasSaved = _savedIds.contains(id);
    await UserProgressManager.toggleSaveTip(id);
    final saved = await UserProgressManager.getSavedTipIds();
    if (mounted) setState(() => _savedIds = Set.from(saved));
    if (!wasSaved) _showXpToast('+1 XP 💾');
  }

  void _showXpToast(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(msg, style: GoogleFonts.outfit(fontWeight: FontWeight.w700)),
        backgroundColor: const Color(0xFF4F46E5),
        behavior: SnackBarBehavior.floating,
        duration: const Duration(seconds: 1),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        margin: const EdgeInsets.only(bottom: 80, left: 16, right: 16),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return AppScaffold(
      title: 'Mẹo vặt',
      currentIndex: 3,
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : Column(
              children: [
                _buildTopBar(),
                _buildSituationChips(),
                _buildFilterChips(),
                Expanded(
                  child: _filtered.isEmpty
                      ? _buildEmpty()
                      : RefreshIndicator(
                          onRefresh: _loadFun,
                          child: ListView.builder(
                            padding: const EdgeInsets.fromLTRB(16, 8, 16, 80),
                            itemCount: _filtered.length,
                            itemBuilder: (context, index) => _buildCard(_filtered[index]),
                          ),
                        ),
                ),
              ],
            ),
    );
  }

  Widget _buildTopBar() {
    return Container(
      color: Colors.white,
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
      child: Row(children: [
        Expanded(
          child: TextField(
            controller: _searchCtrl,
            onChanged: (v) {
              _searchQuery = v;
              _applyFilter();
            },
            decoration: InputDecoration(
              hintText: '🔍 Tìm kiếm mẹo vặt...',
              hintStyle: GoogleFonts.outfit(color: Colors.grey.shade400, fontSize: 14),
              prefixIcon: const Icon(Icons.search, color: Colors.grey),
              suffixIcon: _searchQuery.isNotEmpty
                  ? IconButton(
                      icon: const Icon(Icons.close, size: 18),
                      onPressed: () {
                        _searchCtrl.clear();
                        _searchQuery = '';
                        _applyFilter();
                      },
                    )
                  : null,
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: BorderSide.none),
              filled: true,
              fillColor: const Color(0xFFF8F8FF),
              contentPadding: const EdgeInsets.symmetric(vertical: 10),
              isDense: true,
            ),
          ),
        ),
        const SizedBox(width: 8),
        GestureDetector(
          onTap: _randomTip,
          child: Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: const Color(0xFFFFF7ED),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: const Color(0xFFFBBF24).withValues(alpha: 0.5)),
            ),
            child: const Text('🎲', style: TextStyle(fontSize: 20)),
          ),
        ),
      ]),
    );
  }

  Widget _buildSituationChips() {
    return Container(
      color: Colors.white,
      padding: const EdgeInsets.only(bottom: 10, left: 12, right: 12),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Padding(
          padding: const EdgeInsets.only(bottom: 6, left: 4),
          child: Text('Theo tình huống:', style: GoogleFonts.outfit(fontSize: 12, color: Colors.grey.shade500, fontWeight: FontWeight.w600)),
        ),
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Row(
            children: _situations.map((s) => GestureDetector(
              onTap: () {
                setState(() => _searchQuery = s['keyword'] as String);
                _searchCtrl.text = s['keyword'] as String;
                _applyFilter();
              },
              child: Container(
                margin: const EdgeInsets.only(right: 8),
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: const Color(0xFFFFF7ED),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: const Color(0xFFFBBF24).withValues(alpha: 0.5)),
                ),
                child: Text(s['label'] as String, style: GoogleFonts.outfit(fontSize: 12, fontWeight: FontWeight.w600, color: const Color(0xFFD97706))),
              ),
            )).toList(),
          ),
        ),
      ]),
    );
  }

  Widget _buildFilterChips() {
    final filters = [
      ('all', 'Tất cả'),
      ('tip', '💡 Mẹo'),
      ('video', '🎬 Video'),
    ];
    return Container(
      color: const Color(0xFFF8F8FF),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Row(children: [
        ...filters.map((f) => GestureDetector(
          onTap: () {
            setState(() => _filter = f.$1);
            _applyFilter();
          },
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            margin: const EdgeInsets.only(right: 8),
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
            decoration: BoxDecoration(
              color: _filter == f.$1 ? const Color(0xFFD97706) : Colors.white,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: _filter == f.$1 ? const Color(0xFFD97706) : Colors.grey.shade300),
            ),
            child: Text(f.$2,
              style: GoogleFonts.outfit(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: _filter == f.$1 ? Colors.white : Colors.grey.shade700,
              )),
          ),
        )),
        const Spacer(),
        Text('${_filtered.length} kết quả', style: GoogleFonts.outfit(fontSize: 12, color: Colors.grey.shade500)),
      ]),
    );
  }

  Widget _buildEmpty() {
    return Center(
      child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
        const Text('🔍', style: TextStyle(fontSize: 56)),
        const SizedBox(height: 16),
        Text('Không tìm thấy mẹo nào', style: GoogleFonts.outfit(fontSize: 16, color: Colors.grey)),
        const SizedBox(height: 8),
        TextButton(
          onPressed: () {
            _searchCtrl.clear();
            setState(() { _searchQuery = ''; _filter = 'all'; });
            _applyFilter();
          },
          child: Text('Xóa bộ lọc', style: GoogleFonts.outfit(color: const Color(0xFFD97706), fontWeight: FontWeight.w600)),
        ),
      ]),
    );
  }

  Widget _buildCard(dynamic item) {
    final isVideo = item['type'] == 'video';
    final id = item['id'] ?? '';
    final liked = _likedIds.contains(id);
    final saved = _savedIds.contains(id);

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.06), blurRadius: 12, offset: const Offset(0, 4))],
      ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        // Media
        if (item['media_url'] != null && (item['media_url'] as String).isNotEmpty)
          ClipRRect(
            borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
            child: Stack(alignment: Alignment.center, children: [
              Image.network(
                item['media_url'],
                height: 190, width: double.infinity, fit: BoxFit.cover,
                errorBuilder: (_, __, ___) => Container(
                  height: 190,
                  color: isVideo ? const Color(0xFF1E1B4B) : const Color(0xFFFFF7ED),
                  child: Center(child: Icon(isVideo ? Icons.play_circle_fill : Icons.lightbulb, size: 60, color: isVideo ? Colors.white : const Color(0xFFD97706))),
                ),
              ),
              if (isVideo)
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(color: Colors.black.withValues(alpha: 0.5), shape: BoxShape.circle, border: Border.all(color: Colors.white, width: 2)),
                  child: const Icon(Icons.play_arrow_rounded, color: Colors.white, size: 48),
                ),
            ]),
          )
        else
          Container(
            height: 80,
            decoration: BoxDecoration(
              color: isVideo ? const Color(0xFF1E1B4B).withValues(alpha: 0.05) : const Color(0xFFFFF7ED),
              borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
            ),
            child: Center(child: Text(isVideo ? '🎬' : '💡', style: const TextStyle(fontSize: 40))),
          ),

        // Content
        Padding(
          padding: const EdgeInsets.all(16),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Row(children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: isVideo ? const Color(0xFF1E1B4B).withValues(alpha: 0.08) : const Color(0xFFFFF7ED),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  isVideo ? '🎬 Video' : '💡 Mẹo vặt',
                  style: GoogleFonts.outfit(fontSize: 11, fontWeight: FontWeight.w700, color: isVideo ? const Color(0xFF1E1B4B) : const Color(0xFFD97706)),
                ),
              ),
            ]),
            const SizedBox(height: 8),
            Text(item['title'] ?? '', style: GoogleFonts.outfit(fontSize: 17, fontWeight: FontWeight.w800, color: const Color(0xFF1E1B4B))),
            const SizedBox(height: 8),
            Text(
              item['content'] ?? '',
              maxLines: 4,
              overflow: TextOverflow.ellipsis,
              style: GoogleFonts.outfit(fontSize: 14, color: Colors.grey.shade700, height: 1.6),
            ),
            const SizedBox(height: 14),
            // Actions
            Row(children: [
              _actionBtn(
                liked ? Icons.favorite_rounded : Icons.favorite_border_rounded,
                liked ? Colors.red.shade400 : Colors.grey.shade500,
                liked ? 'Đã thích' : 'Thích',
                () => _toggleLike(id),
              ),
              const SizedBox(width: 8),
              _actionBtn(
                saved ? Icons.bookmark_rounded : Icons.bookmark_add_outlined,
                saved ? const Color(0xFF4F46E5) : Colors.grey.shade600,
                saved ? 'Đã lưu' : 'Lưu mẹo',
                () => _toggleSave(id),
              ),
              const Spacer(),
              if (!isVideo)
                ElevatedButton.icon(
                  onPressed: () => _showTipDialog(item as Map<String, dynamic>),
                  icon: const Icon(Icons.fullscreen_rounded, color: Colors.white, size: 16),
                  label: Text('Đọc ngay', style: GoogleFonts.outfit(color: Colors.white, fontWeight: FontWeight.w800, fontSize: 13)),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFFD97706),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    elevation: 2,
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  ),
                ),
            ]),
          ]),
        ),
      ]),
    );
  }

  Widget _actionBtn(IconData icon, Color color, String label, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.08),
          borderRadius: BorderRadius.circular(10),
        ),
        child: Row(mainAxisSize: MainAxisSize.min, children: [
          Icon(icon, color: color, size: 18),
          const SizedBox(width: 4),
          Text(label, style: GoogleFonts.outfit(color: color, fontWeight: FontWeight.w600, fontSize: 12)),
        ]),
      ),
    );
  }
}
