import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_markdown/flutter_markdown.dart';
import '../utils/api_service.dart';
import '../utils/auth_manager.dart';
import '../utils/user_progress_manager.dart';
import '../widgets/app_scaffold.dart';
import 'skill_detail_screen.dart';

class SkillsScreen extends StatefulWidget {
  const SkillsScreen({super.key});

  @override
  State<SkillsScreen> createState() => _SkillsScreenState();
}

class _SkillsScreenState extends State<SkillsScreen> {
  List<dynamic> _allSkills = [];
  List<dynamic> _filtered = [];
  bool _isLoading = true;
  String _selectedCategory = 'Tất cả';
  List<String> _categories = ['Tất cả'];
  Set<String> _completedIds = {};
  
  String? _aiRecommendation;
  bool _loadingAi = true;

  @override
  void initState() {
    super.initState();
    _loadSkills();
    _loadCompleted();
  }

  Future<void> _loadCompleted() async {
    final ids = await UserProgressManager.getCompletedSkillIds();
    if (mounted) setState(() => _completedIds = Set.from(ids));
  }

  Future<void> _loadAiRecommendation() async {
     final user = await AuthManager.getUser();
     final userId = user['id'];
     if (userId == null || userId.isEmpty) {
       if (mounted) setState(() => _loadingAi = false);
       return;
     }
     try {
        final res = await ApiService.getAiRecommendation(userId);
        if (mounted) setState(() { _aiRecommendation = res['recommendation_text']; _loadingAi = false; });
     } catch (e) {
        if (mounted) setState(() => _loadingAi = false);
     }
  }

  Future<void> _loadSkills() async {
    try {
      final skills = await ApiService.getSkills();
      if (mounted) {
        final cats = <String>{'Tất cả'};
        for (final s in skills) {
          if (s['category'] != null) cats.add(s['category'] as String);
        }
        setState(() {
          _allSkills = skills;
          _categories = cats.toList();
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
      _filtered = _selectedCategory == 'Tất cả'
          ? List.from(_allSkills)
          : _allSkills.where((s) => s['category'] == _selectedCategory).toList();
    });
  }

  double _getCompletion() {
    if (_allSkills.isEmpty) return 0;
    return _completedIds.length / _allSkills.length;
  }

  @override
  Widget build(BuildContext context) {
    return AppScaffold(
      title: 'Khoá Học Kỹ Năng',
      currentIndex: 2,
      body: _isLoading
          ? ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: 4,
              itemBuilder: (_, __) => Container(
                height: 160, margin: const EdgeInsets.only(bottom: 16),
                decoration: BoxDecoration(color: Colors.grey.shade200, borderRadius: BorderRadius.circular(18)),
              ),
            )
          : Column(
              children: [
                _buildProgressHeader(),
                _buildCategoryFilter(),
                Expanded(child: _buildList()),
              ],
            ),
    );
  }

  Widget _buildProgressHeader() {
    final done = _completedIds.length;
    final total = _allSkills.length;
    final pct = _getCompletion();
    return Container(
      margin: const EdgeInsets.fromLTRB(16, 14, 16, 0),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF4F46E5), Color(0xFF7C3AED)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(18),
      ),
      child: Row(children: [
        Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text('Tiến độ học tập', style: GoogleFonts.outfit(color: Colors.white70, fontSize: 13)),
          const SizedBox(height: 4),
          Text('$done / $total kỹ năng', style: GoogleFonts.outfit(color: Colors.white, fontWeight: FontWeight.w800, fontSize: 20)),
          const SizedBox(height: 10),
          ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: LinearProgressIndicator(
              value: pct,
              backgroundColor: Colors.white.withValues(alpha: 0.25),
              valueColor: const AlwaysStoppedAnimation<Color>(Colors.white),
              minHeight: 8,
            ),
          ),
          const SizedBox(height: 4),
          Text('${(pct * 100).toStringAsFixed(0)}% hoàn thành', style: GoogleFonts.outfit(color: Colors.white70, fontSize: 11)),
        ])),
        const SizedBox(width: 16),
        Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(color: Colors.white.withValues(alpha: 0.15), shape: BoxShape.circle),
          child: const Text('🎓', style: TextStyle(fontSize: 28)),
        ),
      ]),
    );
  }

  Widget _buildAiRecommendation() {
     if (_loadingAi) {
         return const Padding(
           padding: EdgeInsets.symmetric(vertical: 20),
           child: Center(child: CircularProgressIndicator(color: Color(0xFFF59E0B))),
         );
     }
     if (_aiRecommendation == null) return const SizedBox();

     return Container(
        margin: const EdgeInsets.only(left: 16, right: 16, top: 12),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
           color: const Color(0xFFFFF7ED),
           borderRadius: BorderRadius.circular(16),
           border: Border.all(color: const Color(0xFFFBBF24).withOpacity(0.5)),
           boxShadow: [BoxShadow(color: const Color(0xFFF59E0B).withOpacity(0.05), blurRadius: 10, offset: const Offset(0, 4))],
        ),
        child: Column(
           crossAxisAlignment: CrossAxisAlignment.start,
           children: [
              Row(
                 children: [
                    const Text('🦉', style: TextStyle(fontSize: 20)),
                    const SizedBox(width: 8),
                    Text('AI Mentor Owl gợi ý lộ trình', style: GoogleFonts.outfit(fontSize: 14, fontWeight: FontWeight.bold, color: const Color(0xFFD97706))),
                 ],
              ),
              const SizedBox(height: 8),
              MarkdownBody(
                 data: _aiRecommendation!,
                 styleSheet: MarkdownStyleSheet(
                    p: GoogleFonts.outfit(fontSize: 13, color: Colors.grey.shade800, height: 1.5),
                    strong: GoogleFonts.outfit(fontWeight: FontWeight.bold, color: const Color(0xFF1E1B4B)),
                 ),
              )
           ]
        ),
     );
  }

  Widget _buildCategoryFilter() {
    return Container(
      color: Colors.white,
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text('Danh mục', style: GoogleFonts.outfit(fontWeight: FontWeight.w700, fontSize: 13, color: Colors.grey.shade600)),
        const SizedBox(height: 8),
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Row(
            children: _categories.map((cat) => GestureDetector(
              onTap: () {
                setState(() => _selectedCategory = cat);
                _applyFilter();
              },
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                margin: const EdgeInsets.only(right: 8),
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
                decoration: BoxDecoration(
                  color: _selectedCategory == cat ? const Color(0xFF4F46E5) : const Color(0xFFF0F0FF),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(cat,
                  style: GoogleFonts.outfit(
                    color: _selectedCategory == cat ? Colors.white : Colors.grey.shade700,
                    fontWeight: FontWeight.w600,
                    fontSize: 13,
                  )),
              ),
            )).toList(),
          ),
        ),
      ]),
    );
  }

  Widget _buildList() {
    if (_filtered.isEmpty) {
      return Center(
        child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
          const Text('📚', style: TextStyle(fontSize: 64)),
          const SizedBox(height: 16),
          Text('Chưa có kỹ năng nào', style: GoogleFonts.outfit(color: Colors.grey.shade700, fontSize: 18, fontWeight: FontWeight.w600)),
          const SizedBox(height: 24),
          ElevatedButton.icon(
            onPressed: () {
              setState(() => _selectedCategory = 'Tất cả');
              _applyFilter();
            },
            icon: const Icon(Icons.explore_rounded, color: Colors.white, size: 20),
            label: Text('Khám phá ngay', style: GoogleFonts.outfit(fontWeight: FontWeight.w700, color: Colors.white, fontSize: 15)),
            style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF4F46E5), padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20))),
          ),
        ]),
      );
    }
    return RefreshIndicator(
      onRefresh: _loadSkills,
      child: ListView.builder(
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 80),
        itemCount: _filtered.length,
        itemBuilder: (context, index) => _buildSkillCard(_filtered[index]),
      ),
    );
  }

  Widget _buildSkillCard(dynamic item) {
    final id = item['id'] ?? '';
    final isCompleted = _completedIds.contains(id);

    return GestureDetector(
      onTap: () async {
        await Navigator.push(context, MaterialPageRoute(builder: (_) => SkillDetailScreen(skillItem: item)));
        // Reload completed status after returning
        _loadCompleted();
      },
      child: Container(
        margin: const EdgeInsets.only(bottom: 14),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: isCompleted ? const Color(0xFF059669).withValues(alpha: 0.4) : const Color(0xFFEEF2FF)),
          boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.05), blurRadius: 10, offset: const Offset(0, 4))],
        ),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          if (item['image_url'] != null && (item['image_url'] as String).isNotEmpty)
            Stack(children: [
              ClipRRect(
                borderRadius: const BorderRadius.vertical(top: Radius.circular(18)),
                child: Hero(
                  tag: 'skill_img_${item['id']}',
                  child: Image.network(
                    item['image_url'],
                    height: 160, width: double.infinity, fit: BoxFit.cover,
                    errorBuilder: (_, __, ___) => Container(height: 160, color: const Color(0xFFEEF2FF)),
                  ),
                ),
              ),
              if (isCompleted)
                Positioned(top: 10, right: 10,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(color: const Color(0xFF059669), borderRadius: BorderRadius.circular(20)),
                    child: Row(mainAxisSize: MainAxisSize.min, children: [
                      const Icon(Icons.check_circle, color: Colors.white, size: 14),
                      const SizedBox(width: 4),
                      Text('Hoàn thành', style: GoogleFonts.outfit(color: Colors.white, fontSize: 11, fontWeight: FontWeight.w700)),
                    ]),
                  ),
                ),
            ]),

          Padding(
            padding: const EdgeInsets.all(14),
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Row(children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(color: const Color(0xFFEEF2FF), borderRadius: BorderRadius.circular(20)),
                  child: Text(item['category'] ?? 'Khác', style: GoogleFonts.outfit(color: const Color(0xFF4F46E5), fontWeight: FontWeight.w700, fontSize: 12)),
                ),
                const Spacer(),
                if (isCompleted)
                  const Text('⭐', style: TextStyle(fontSize: 16)),
              ]),
              const SizedBox(height: 8),
              Text(item['title'] ?? '', style: GoogleFonts.outfit(fontSize: 17, fontWeight: FontWeight.w800, color: const Color(0xFF1E1B4B), height: 1.3)),
              const SizedBox(height: 6),
              Text(item['description'] ?? '', maxLines: 2, overflow: TextOverflow.ellipsis,
                style: GoogleFonts.outfit(color: Colors.grey.shade600, fontSize: 13, height: 1.4)),
              const SizedBox(height: 12),
              Row(children: [
                Icon(Icons.school_outlined, size: 16, color: Colors.indigo.shade400),
                const SizedBox(width: 4),
                Text('Cơ bản', style: GoogleFonts.outfit(color: Colors.indigo.shade400, fontWeight: FontWeight.w600, fontSize: 12)),
                const SizedBox(width: 12),
                Icon(Icons.timer_outlined, size: 16, color: Colors.indigo.shade400),
                const SizedBox(width: 4),
                Text('${item['duration_minutes'] ?? 5}p',
                  style: GoogleFonts.outfit(color: Colors.indigo.shade400, fontWeight: FontWeight.w600, fontSize: 12)),
                const Spacer(),
                if (isCompleted) Text('Hoàn thành 100%', style: GoogleFonts.outfit(color: const Color(0xFF059669), fontWeight: FontWeight.w800, fontSize: 12))
                else Text('0%', style: GoogleFonts.outfit(color: Colors.grey.shade500, fontWeight: FontWeight.w800, fontSize: 12)),
              ]),
              const SizedBox(height: 12),
              Row(children: [
                const Spacer(),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
                  decoration: BoxDecoration(
                    color: isCompleted ? const Color(0xFF059669).withValues(alpha: 0.1) : const Color(0xFF4F46E5),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Text(
                    isCompleted ? '✓ Xem lại' : 'Học ngay →',
                    style: GoogleFonts.outfit(
                      color: isCompleted ? const Color(0xFF059669) : Colors.white,
                      fontWeight: FontWeight.w700, fontSize: 12,
                    ),
                  ),
                ),
              ]),
            ]),
          ),
        ]),
      ),
    );
  }
}
