import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../utils/api_service.dart';
import '../utils/user_progress_manager.dart';
import '../widgets/app_scaffold.dart';
import 'news_detail_screen.dart';

class NewsScreen extends StatefulWidget {
  const NewsScreen({super.key});

  @override
  State<NewsScreen> createState() => _NewsScreenState();
}

class _NewsScreenState extends State<NewsScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  List<dynamic> _allNews = [];
  List<dynamic> _hotNews = [];
  bool _isLoading = true;
  Set<String> _bookmarkedIds = {};

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _loadNews();
    _loadBookmarks();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _loadBookmarks() async {
    final ids = await UserProgressManager.getBookmarkedNewsIds();
    if (mounted) setState(() => _bookmarkedIds = Set.from(ids));
  }

  Future<void> _loadNews() async {
    try {
      final news = await ApiService.getNews();
      if (mounted) {
        // Sort "hot" = simulate by reverse index as surrogate (newest = hot in seed data)
        final hot = List<dynamic>.from(news)..shuffle();
        setState(() {
          _allNews = news;
          _hotNews = hot;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _toggleBookmark(Map<String, dynamic> item) async {
    final id = item['id'] ?? '';
    await UserProgressManager.toggleBookmarkNews(id, item);
    final ids = await UserProgressManager.getBookmarkedNewsIds();
    if (mounted) {
      setState(() => _bookmarkedIds = Set.from(ids));
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text(
          ids.contains(id) ? '🔖 Đã lưu bài viết' : 'Đã bỏ lưu',
          style: GoogleFonts.outfit(fontWeight: FontWeight.w600),
        ),
        backgroundColor: ids.contains(id) ? const Color(0xFF4F46E5) : Colors.grey.shade600,
        behavior: SnackBarBehavior.floating,
        duration: const Duration(seconds: 1),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        margin: const EdgeInsets.only(bottom: 80, left: 16, right: 16),
      ));
    }
  }

  List<dynamic> get _bookmarkedNews =>
      _allNews.where((n) => _bookmarkedIds.contains(n['id'])).toList();

  @override
  Widget build(BuildContext context) {
    return AppScaffold(
      title: 'Tin tức & Cẩm nang',
      currentIndex: 4,
      body: Column(
        children: [
          _buildTabBar(),
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : TabBarView(
                    controller: _tabController,
                    children: [
                      _buildNewsList(_allNews),
                      _buildNewsList(_hotNews),
                      _buildNewsList(_bookmarkedNews, emptyMsg: 'Chưa có bài viết nào được lưu', emptyEmoji: '🔖'),
                    ],
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildTabBar() {
    return Container(
      color: Colors.white,
      child: TabBar(
        controller: _tabController,
        indicatorColor: const Color(0xFF0891B2),
        indicatorWeight: 3,
        labelColor: const Color(0xFF0891B2),
        unselectedLabelColor: Colors.grey,
        labelStyle: GoogleFonts.outfit(fontWeight: FontWeight.w700, fontSize: 13),
        tabs: const [
          Tab(icon: Icon(Icons.access_time_rounded, size: 16), text: 'Mới nhất'),
          Tab(icon: Icon(Icons.local_fire_department_rounded, size: 16), text: 'Đang hot'),
          Tab(icon: Icon(Icons.bookmark_rounded, size: 16), text: 'Đã lưu'),
        ],
      ),
    );
  }

  Widget _buildNewsList(List<dynamic> list, {String? emptyMsg, String? emptyEmoji}) {
    if (list.isEmpty) {
      return Center(
        child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
          Text(emptyEmoji ?? '📰', style: const TextStyle(fontSize: 56)),
          const SizedBox(height: 16),
          Text(emptyMsg ?? 'Chưa có tin tức nào', style: GoogleFonts.outfit(color: Colors.grey, fontSize: 16)),
        ]),
      );
    }
    return RefreshIndicator(
      onRefresh: _loadNews,
      child: ListView.builder(
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 80),
        itemCount: list.length,
        itemBuilder: (context, index) => _buildNewsCard(list[index], index == 0 && _tabController.index == 0),
      ),
    );
  }

  Widget _buildNewsCard(dynamic item, bool isFeatured) {
    final id = item['id'] ?? '';
    final isBookmarked = _bookmarkedIds.contains(id);

    if (isFeatured) {
      // Featured card (first item on "Mới nhất" tab)
      return GestureDetector(
        onTap: () => _openDetail(item),
        child: Container(
          margin: const EdgeInsets.only(bottom: 16),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(20),
            boxShadow: [BoxShadow(color: const Color(0xFF0891B2).withValues(alpha: 0.15), blurRadius: 16, offset: const Offset(0, 6))],
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(20),
            child: Stack(children: [
              if (item['image_url'] != null && (item['image_url'] as String).isNotEmpty)
                Image.network(item['image_url'], height: 220, width: double.infinity, fit: BoxFit.cover,
                  errorBuilder: (_, __, ___) => Container(height: 220, color: const Color(0xFF0891B2).withValues(alpha: 0.1))),
              Container(
                height: 220,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter, end: Alignment.bottomCenter,
                    colors: [Colors.transparent, Colors.black.withValues(alpha: 0.75)],
                  ),
                ),
              ),
              Positioned(top: 12, left: 12,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(color: const Color(0xFF0891B2), borderRadius: BorderRadius.circular(8)),
                  child: Text('✨ Nổi bật', style: GoogleFonts.outfit(color: Colors.white, fontWeight: FontWeight.w700, fontSize: 11)),
                ),
              ),
              Positioned(top: 8, right: 8,
                child: IconButton(
                  onPressed: () => _toggleBookmark(item as Map<String, dynamic>),
                  icon: Icon(isBookmarked ? Icons.bookmark_rounded : Icons.bookmark_border_rounded, color: Colors.white, size: 24),
                ),
              ),
              Positioned(left: 16, right: 16, bottom: 16,
                child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Text(item['title'] ?? '', maxLines: 2, overflow: TextOverflow.ellipsis,
                    style: GoogleFonts.outfit(color: Colors.white, fontWeight: FontWeight.w800, fontSize: 17, height: 1.3)),
                  const SizedBox(height: 6),
                  Row(children: [
                    Icon(Icons.person_outline, size: 14, color: Colors.white70),
                    const SizedBox(width: 4),
                    Text(item['author'] ?? 'Admin', style: GoogleFonts.outfit(color: Colors.white70, fontSize: 12)),
                    const Spacer(),
                    Text('Đọc ngay →', style: GoogleFonts.outfit(color: Colors.white, fontWeight: FontWeight.w700, fontSize: 12)),
                  ]),
                ]),
              ),
            ]),
          ),
        ),
      );
    }

    return GestureDetector(
      onTap: () => _openDetail(item),
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.05), blurRadius: 10, offset: const Offset(0, 3))],
        ),
        child: Row(children: [
          ClipRRect(
            borderRadius: const BorderRadius.horizontal(left: Radius.circular(16)),
            child: item['image_url'] != null && (item['image_url'] as String).isNotEmpty
                ? Image.network(item['image_url'], width: 90, height: 90, fit: BoxFit.cover,
                    errorBuilder: (_, __, ___) => Container(width: 90, height: 90,
                      color: const Color(0xFFEFF6FF), child: const Icon(Icons.article, color: Color(0xFF0891B2), size: 36)))
                : Container(width: 90, height: 90, color: const Color(0xFFEFF6FF),
                    child: const Icon(Icons.article_outlined, color: Color(0xFF0891B2), size: 36)),
          ),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(12, 12, 8, 12),
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text(item['title'] ?? '', maxLines: 2, overflow: TextOverflow.ellipsis,
                  style: GoogleFonts.outfit(fontWeight: FontWeight.w700, fontSize: 14, height: 1.3)),
                const SizedBox(height: 4),
                Text(item['summary'] ?? '', maxLines: 1, overflow: TextOverflow.ellipsis,
                  style: GoogleFonts.outfit(color: Colors.grey.shade600, fontSize: 12)),
                const SizedBox(height: 6),
                Row(children: [
                  Text(item['author'] ?? 'Admin', style: GoogleFonts.outfit(color: const Color(0xFF0891B2), fontSize: 11, fontWeight: FontWeight.w600)),
                  const Spacer(),
                  Text('Đọc tiếp', style: GoogleFonts.outfit(color: const Color(0xFF0891B2), fontSize: 11, fontWeight: FontWeight.w700)),
                ]),
              ]),
            ),
          ),
          IconButton(
            onPressed: () => _toggleBookmark(item as Map<String, dynamic>),
            icon: Icon(
              isBookmarked ? Icons.bookmark_rounded : Icons.bookmark_border_rounded,
              color: isBookmarked ? const Color(0xFF4F46E5) : Colors.grey.shade400,
              size: 22,
            ),
          ),
        ]),
      ),
    );
  }

  void _openDetail(dynamic item) {
    // add XP for reading
    UserProgressManager.addXp(2);
    Navigator.push(context, MaterialPageRoute(builder: (_) => NewsDetailScreen(newsItem: item)));
  }
}
