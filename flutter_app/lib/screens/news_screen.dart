import 'dart:math';
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

class _NewsScreenState extends State<NewsScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  List<dynamic> _allNews = [];
  List<dynamic> _hotNews = [];
  List<dynamic> _filtered = [];
  bool _isLoading = true;
  Set<String> _bookmarkedIds = {};
  String _searchQuery = '';
  final TextEditingController _searchCtrl = TextEditingController();

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _tabController.addListener(() {
      if (!_tabController.indexIsChanging) setState(() {});
    });
    _loadNews();
    _loadBookmarks();
  }

  @override
  void dispose() {
    _tabController.dispose();
    _searchCtrl.dispose();
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
        final hot = _computeHot(news);
        setState(() {
          _allNews = news;
          _hotNews = hot;
          _isLoading = false;
        });
        _applySearch();
      }
    } catch (e) {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  /// "Hot" = bài trong 7 ngày gần nhất ưu tiên, tie-break bằng random nhẹ
  List<dynamic> _computeHot(List<dynamic> news) {
    final sevenDaysAgo =
        DateTime.now().subtract(const Duration(days: 7));
    final rng = Random();
    final result = List<dynamic>.from(news);
    result.sort((a, b) {
      final aDate =
          DateTime.tryParse(a['created_at'] ?? '') ?? DateTime(2000);
      final bDate =
          DateTime.tryParse(b['created_at'] ?? '') ?? DateTime(2000);
      final aRecent = aDate.isAfter(sevenDaysAgo) ? 1 : 0;
      final bRecent = bDate.isAfter(sevenDaysAgo) ? 1 : 0;
      if (aRecent != bRecent) return bRecent - aRecent;
      return rng.nextInt(3) - 1;
    });
    return result;
  }

  void _applySearch() {
    final q = _searchQuery.toLowerCase();
    setState(() {
      _filtered = _allNews.where((item) {
        if (q.isEmpty) return true;
        return (item['title'] ?? '').toLowerCase().contains(q) ||
            (item['summary'] ?? '').toLowerCase().contains(q) ||
            (item['author'] ?? '').toLowerCase().contains(q);
      }).toList();
    });
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
        backgroundColor: ids.contains(id)
            ? const Color(0xFF0891B2)
            : Colors.grey.shade600,
        behavior: SnackBarBehavior.floating,
        duration: const Duration(seconds: 1),
        shape:
            RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
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
      currentIndex: 3,
      body: Column(
        children: [
          _buildSearchBar(),
          _buildTabBar(),
          Expanded(
            child: _isLoading
                ? _buildShimmer()
                : TabBarView(
                    controller: _tabController,
                    children: [
                      _buildNewsList(
                          _searchQuery.isNotEmpty ? _filtered : _allNews),
                      _buildNewsList(_hotNews),
                      _buildNewsList(
                        _bookmarkedNews,
                        emptyMsg: 'Chưa có bài viết nào được lưu',
                        emptyEmoji: '🔖',
                        showCta: true,
                      ),
                    ],
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildSearchBar() {
    return Container(
      color: Colors.white,
      padding: const EdgeInsets.fromLTRB(16, 10, 16, 6),
      child: TextField(
        controller: _searchCtrl,
        onChanged: (v) {
          _searchQuery = v;
          _applySearch();
        },
        decoration: InputDecoration(
          hintText: '🔍 Tìm kiếm tin tức...',
          hintStyle:
              GoogleFonts.outfit(color: Colors.grey.shade400, fontSize: 14),
          prefixIcon: const Icon(Icons.search, color: Colors.grey, size: 20),
          suffixIcon: _searchQuery.isNotEmpty
              ? IconButton(
                  icon: const Icon(Icons.close, size: 18),
                  onPressed: () {
                    _searchCtrl.clear();
                    _searchQuery = '';
                    _applySearch();
                  },
                )
              : null,
          border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(14),
              borderSide: BorderSide.none),
          filled: true,
          fillColor: const Color(0xFFF4F6FF),
          contentPadding: const EdgeInsets.symmetric(vertical: 10),
          isDense: true,
        ),
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
        labelStyle:
            GoogleFonts.outfit(fontWeight: FontWeight.w700, fontSize: 13),
        tabs: const [
          Tab(
              icon: Icon(Icons.access_time_rounded, size: 16),
              text: 'Mới nhất'),
          Tab(
              icon: Icon(Icons.local_fire_department_rounded, size: 16),
              text: 'Đang hot'),
          Tab(
              icon: Icon(Icons.bookmark_rounded, size: 16), text: 'Đã lưu'),
        ],
      ),
    );
  }

  Widget _buildShimmer() {
    return ListView.builder(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 80),
      itemCount: 5,
      itemBuilder: (context, index) => Padding(
        padding: const EdgeInsets.only(bottom: 12),
        child: _ShimmerCard(isFeatured: index == 0),
      ),
    );
  }

  Widget _buildNewsList(List<dynamic> list,
      {String? emptyMsg, String? emptyEmoji, bool showCta = false}) {
    if (list.isEmpty) {
      return Center(
        child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(emptyEmoji ?? '📰',
                  style: const TextStyle(fontSize: 56)),
              const SizedBox(height: 16),
              Text(
                emptyMsg ?? 'Chưa có tin tức nào',
                style: GoogleFonts.outfit(
                    color: Colors.grey,
                    fontSize: 16,
                    fontWeight: FontWeight.w500),
              ),
              if (showCta) ...[
                const SizedBox(height: 8),
                Text(
                  'Hãy nhấn 🔖 trên bài viết bạn thích để đọc lại sau!',
                  textAlign: TextAlign.center,
                  style: GoogleFonts.outfit(
                      color: Colors.grey.shade400, fontSize: 13),
                ),
                const SizedBox(height: 20),
                ElevatedButton.icon(
                  onPressed: () => _tabController.animateTo(0),
                  icon: const Icon(Icons.explore_rounded, size: 18),
                  label: Text('Khám phá tin tức →',
                      style: GoogleFonts.outfit(
                          fontWeight: FontWeight.w700)),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF0891B2),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12)),
                    padding: const EdgeInsets.symmetric(
                        horizontal: 20, vertical: 12),
                  ),
                ),
              ],
            ]),
      );
    }
    return RefreshIndicator(
      onRefresh: _loadNews,
      child: ListView.builder(
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 80),
        itemCount: list.length,
        itemBuilder: (context, index) =>
            _buildNewsCard(list[index], index == 0 && _tabController.index != 2),
      ),
    );
  }

  Widget _buildNewsCard(dynamic item, bool isFeatured) {
    final id = item['id'] ?? '';
    final isBookmarked = _bookmarkedIds.contains(id);

    if (isFeatured) {
      return GestureDetector(
        onTap: () => _openDetail(item),
        child: Container(
          margin: const EdgeInsets.only(bottom: 16),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(20),
            boxShadow: [
              BoxShadow(
                  color: const Color(0xFF0891B2).withValues(alpha: 0.18),
                  blurRadius: 18,
                  offset: const Offset(0, 6))
            ],
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(20),
            child: Stack(children: [
              if (item['image_url'] != null &&
                  (item['image_url'] as String).isNotEmpty)
                Image.network(item['image_url'],
                    height: 230,
                    width: double.infinity,
                    fit: BoxFit.cover,
                    errorBuilder: (_, __, ___) => Container(
                        height: 230,
                        color: const Color(0xFF0891B2)
                            .withValues(alpha: 0.15)))
              else
                Container(
                  height: 230,
                  color: const Color(0xFF0891B2).withValues(alpha: 0.15),
                  child: const Center(
                      child: Icon(Icons.newspaper_rounded,
                          size: 60, color: Color(0xFF0891B2))),
                ),
              // Gradient overlay
              Container(
                height: 230,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      Colors.transparent,
                      Colors.black.withValues(alpha: 0.82)
                    ],
                    stops: const [0.35, 1.0],
                  ),
                ),
              ),
              // Badge top-left
              Positioned(
                top: 14,
                left: 14,
                child: Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                      color: const Color(0xFF0891B2),
                      borderRadius: BorderRadius.circular(8)),
                  child: Text('✨ Nổi bật',
                      style: GoogleFonts.outfit(
                          color: Colors.white,
                          fontWeight: FontWeight.w700,
                          fontSize: 11)),
                ),
              ),
              // Bookmark top-right
              Positioned(
                top: 6,
                right: 6,
                child: _BookmarkButton(
                  isBookmarked: isBookmarked,
                  onTap: () =>
                      _toggleBookmark(item as Map<String, dynamic>),
                  dark: true,
                ),
              ),
              // Content bottom
              Positioned(
                left: 16,
                right: 16,
                bottom: 16,
                child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(item['title'] ?? '',
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: GoogleFonts.outfit(
                              color: Colors.white,
                              fontWeight: FontWeight.w800,
                              fontSize: 18,
                              height: 1.3)),
                      const SizedBox(height: 8),
                      Row(children: [
                        const Icon(Icons.person_outline,
                            size: 14, color: Colors.white70),
                        const SizedBox(width: 4),
                        Text(item['author'] ?? 'Admin',
                            style: GoogleFonts.outfit(
                                color: Colors.white70, fontSize: 12)),
                        const SizedBox(width: 8),
                        const Icon(Icons.access_time,
                            size: 12, color: Colors.white70),
                        const SizedBox(width: 3),
                        Text(_readingTime(item['content'] ?? ''),
                            style: GoogleFonts.outfit(
                                color: Colors.white70, fontSize: 12)),
                        const Spacer(),
                        Text('Đọc ngay →',
                            style: GoogleFonts.outfit(
                                color: Colors.white,
                                fontWeight: FontWeight.w700,
                                fontSize: 12)),
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
          boxShadow: [
            BoxShadow(
                color: Colors.black.withValues(alpha: 0.05),
                blurRadius: 10,
                offset: const Offset(0, 3))
          ],
        ),
        child: Row(children: [
          ClipRRect(
            borderRadius:
                const BorderRadius.horizontal(left: Radius.circular(16)),
            child: item['image_url'] != null &&
                    (item['image_url'] as String).isNotEmpty
                ? Image.network(item['image_url'],
                    width: 92,
                    height: 92,
                    fit: BoxFit.cover,
                    errorBuilder: (_, __, ___) => Container(
                        width: 92,
                        height: 92,
                        color: const Color(0xFFEFF6FF),
                        child: const Icon(Icons.article,
                            color: Color(0xFF0891B2), size: 36)))
                : Container(
                    width: 92,
                    height: 92,
                    color: const Color(0xFFEFF6FF),
                    child: const Icon(Icons.article_outlined,
                        color: Color(0xFF0891B2), size: 36)),
          ),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(12, 10, 4, 10),
              child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(item['title'] ?? '',
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: GoogleFonts.outfit(
                            fontWeight: FontWeight.w700,
                            fontSize: 14,
                            height: 1.3)),
                    const SizedBox(height: 4),
                    Text(item['summary'] ?? '',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: GoogleFonts.outfit(
                            color: Colors.grey.shade600, fontSize: 12)),
                    const SizedBox(height: 6),
                    Row(children: [
                      Expanded(
                        child: Row(
                          children: [
                            Flexible(
                              child: Text(item['author'] ?? 'Admin',
                                  maxLines: 1, overflow: TextOverflow.ellipsis,
                                  style: GoogleFonts.outfit(
                                      color: const Color(0xFF0891B2),
                                      fontSize: 11,
                                      fontWeight: FontWeight.w600)),
                            ),
                            const SizedBox(width: 6),
                            Flexible(
                              child: Text('· ${_readingTime(item['content'] ?? '')}',
                                  maxLines: 1, overflow: TextOverflow.ellipsis,
                                  style: GoogleFonts.outfit(
                                      color: Colors.grey.shade400, fontSize: 11)),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 8),
                      Text('Đọc tiếp',
                          style: GoogleFonts.outfit(
                              color: const Color(0xFF0891B2),
                              fontSize: 11,
                              fontWeight: FontWeight.w700)),
                    ]),
                  ]),
            ),
          ),
          _BookmarkButton(
            isBookmarked: isBookmarked,
            onTap: () => _toggleBookmark(item as Map<String, dynamic>),
            dark: false,
          ),
        ]),
      ),
    );
  }

  String _readingTime(String content) {
    final words = content.split(' ').length;
    final minutes = (words / 200).ceil().clamp(1, 60);
    return '$minutes phút đọc';
  }

  void _openDetail(dynamic item) {
    UserProgressManager.addXp(2);
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => NewsDetailScreen(
          newsItem: item as Map<String, dynamic>,
          allNews: _allNews,
        ),
      ),
    );
  }
}

// ── Shimmer Card ──────────────────────────────────────────────────────────────
class _ShimmerCard extends StatefulWidget {
  final bool isFeatured;
  const _ShimmerCard({this.isFeatured = false});

  @override
  State<_ShimmerCard> createState() => _ShimmerCardState();
}

class _ShimmerCardState extends State<_ShimmerCard>
    with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;
  late Animation<double> _anim;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 1200))
      ..repeat(reverse: true);
    _anim = Tween<double>(begin: 0.3, end: 0.7).animate(_ctrl);
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _anim,
      builder: (_, __) {
        final color = Color.lerp(
            Colors.grey.shade200, Colors.grey.shade100, _anim.value)!;
        if (widget.isFeatured) {
          return Container(
            height: 220,
            decoration: BoxDecoration(
                color: color, borderRadius: BorderRadius.circular(20)),
          );
        }
        return Container(
          height: 92,
          decoration: BoxDecoration(
              color: color, borderRadius: BorderRadius.circular(16)),
          child: Row(children: [
            Container(
                width: 92,
                height: 92,
                decoration: BoxDecoration(
                    color: Colors.grey.shade300,
                    borderRadius: const BorderRadius.horizontal(
                        left: Radius.circular(16)))),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Container(
                          height: 14,
                          width: double.infinity,
                          decoration: BoxDecoration(
                              color: Colors.grey.shade300,
                              borderRadius: BorderRadius.circular(4))),
                      const SizedBox(height: 8),
                      Container(
                          height: 12,
                          width: 140,
                          decoration: BoxDecoration(
                              color: Colors.grey.shade300,
                              borderRadius: BorderRadius.circular(4))),
                    ]),
              ),
            )
          ]),
        );
      },
    );
  }
}

// ── Bookmark Button ───────────────────────────────────────────────────────────
class _BookmarkButton extends StatelessWidget {
  final bool isBookmarked;
  final VoidCallback onTap;
  final bool dark;

  const _BookmarkButton(
      {required this.isBookmarked,
      required this.onTap,
      required this.dark});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.all(8),
        child: Icon(
          isBookmarked ? Icons.bookmark_rounded : Icons.bookmark_border_rounded,
          color: isBookmarked
              ? (dark ? Colors.white : const Color(0xFF0891B2))
              : (dark ? Colors.white70 : Colors.grey.shade400),
          size: 24,
        ),
      ),
    );
  }
}
