import 'dart:math';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../utils/user_progress_manager.dart';

class NewsDetailScreen extends StatefulWidget {
  final Map<String, dynamic> newsItem;
  final List<dynamic> allNews;

  const NewsDetailScreen({
    super.key,
    required this.newsItem,
    this.allNews = const [],
  });

  @override
  State<NewsDetailScreen> createState() => _NewsDetailScreenState();
}

class _NewsDetailScreenState extends State<NewsDetailScreen> {
  final ScrollController _scrollCtrl = ScrollController();
  double _scrollProgress = 0.0;
  bool _isBookmarked = false;
  late List<dynamic> _related;

  // XP overlay
  OverlayEntry? _xpOverlay;

  @override
  void initState() {
    super.initState();
    _loadBookmarkState();
    _scrollCtrl.addListener(_onScroll);
    _related = _computeRelated();
  }

  @override
  void dispose() {
    _scrollCtrl.removeListener(_onScroll);
    _scrollCtrl.dispose();
    _xpOverlay?.remove();
    super.dispose();
  }

  void _onScroll() {
    final max = _scrollCtrl.position.maxScrollExtent;
    if (max <= 0) return;
    final progress =
        (_scrollCtrl.offset / max).clamp(0.0, 1.0);
    if ((progress - _scrollProgress).abs() > 0.005) {
      setState(() => _scrollProgress = progress);
    }
  }

  Future<void> _loadBookmarkState() async {
    final ids = await UserProgressManager.getBookmarkedNewsIds();
    if (mounted) {
      setState(() =>
          _isBookmarked = ids.contains(widget.newsItem['id'] ?? ''));
    }
  }

  Future<void> _toggleBookmark() async {
    final id = widget.newsItem['id'] ?? '';
    await UserProgressManager.toggleBookmarkNews(id, widget.newsItem);
    final ids = await UserProgressManager.getBookmarkedNewsIds();
    if (mounted) {
      setState(() => _isBookmarked = ids.contains(id));
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text(
          _isBookmarked ? '🔖 Đã lưu bài viết' : 'Đã bỏ lưu',
          style: GoogleFonts.outfit(fontWeight: FontWeight.w600),
        ),
        backgroundColor:
            _isBookmarked ? const Color(0xFF0891B2) : Colors.grey.shade600,
        behavior: SnackBarBehavior.floating,
        duration: const Duration(seconds: 1),
        shape:
            RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        margin: const EdgeInsets.only(bottom: 20, left: 16, right: 16),
      ));
    }
  }

  List<dynamic> _computeRelated() {
    final currentId = widget.newsItem['id'];
    final pool = widget.allNews
        .where((n) => n['id'] != currentId)
        .toList();
    pool.shuffle(Random());
    return pool.take(3).toList();
  }

  String _readingTime(String content) {
    final words = content.split(' ').length;
    final minutes = (words / 200).ceil().clamp(1, 60);
    return '$minutes phút đọc';
  }

  List<String> _extractKeyPoints(String summary) {
    // Split by common Vietnamese sentence delimiters
    final raw = summary
        .split(RegExp(r'[.;]'))
        .map((s) => s.trim())
        .where((s) => s.length > 10)
        .take(3)
        .toList();
    if (raw.isEmpty) {
      return [summary.isNotEmpty ? summary : 'Bài viết hữu ích cho bạn'];
    }
    return raw;
  }

  void _showXpToast() {
    _xpOverlay?.remove();
    _xpOverlay = OverlayEntry(
      builder: (_) => _XpToast(
        onDone: () {
          _xpOverlay?.remove();
          _xpOverlay = null;
        },
      ),
    );
    Overlay.of(context).insert(_xpOverlay!);
  }

  @override
  Widget build(BuildContext context) {
    final item = widget.newsItem;
    final content = item['content'] ?? '';
    final summary = item['summary'] ?? '';
    final keyPoints = _extractKeyPoints(summary);

    return Scaffold(
      backgroundColor: const Color(0xFFFAFAFC),
      body: Stack(
        children: [
          CustomScrollView(
            controller: _scrollCtrl,
            slivers: [
              // ── Hero AppBar ─────────────────────────────────────────────
              SliverAppBar(
                expandedHeight: 260,
                pinned: true,
                backgroundColor: const Color(0xFF0891B2),
                foregroundColor: Colors.white,
                actions: [
                  AnimatedSwitcher(
                    duration: const Duration(milliseconds: 250),
                    child: IconButton(
                      key: ValueKey(_isBookmarked),
                      icon: Icon(
                        _isBookmarked
                            ? Icons.bookmark_rounded
                            : Icons.bookmark_border_rounded,
                        color: Colors.white,
                      ),
                      tooltip: _isBookmarked ? 'Bỏ lưu' : 'Lưu bài',
                      onPressed: _toggleBookmark,
                    ),
                  ),
                  const SizedBox(width: 4),
                ],
                flexibleSpace: FlexibleSpaceBar(
                  background: item['image_url'] != null &&
                          (item['image_url'] as String).isNotEmpty
                      ? Hero(
                          tag: 'news_image_${item['id']}',
                          child: Stack(children: [
                            Image.network(
                              item['image_url'],
                              fit: BoxFit.cover,
                              width: double.infinity,
                              height: 260,
                              errorBuilder: (_, __, ___) => Container(
                                  height: 260,
                                  color: const Color(0xFF0891B2)
                                      .withValues(alpha: 0.3)),
                            ),
                            Container(
                              height: 260,
                              decoration: BoxDecoration(
                                gradient: LinearGradient(
                                  begin: Alignment.topCenter,
                                  end: Alignment.bottomCenter,
                                  colors: [
                                    Colors.transparent,
                                    Colors.black.withValues(alpha: 0.5)
                                  ],
                                  stops: const [0.5, 1.0],
                                ),
                              ),
                            ),
                          ]),
                        )
                      : Container(
                          height: 260,
                          decoration: const BoxDecoration(
                            gradient: LinearGradient(
                              colors: [Color(0xFF0891B2), Color(0xFF06B6D4)],
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                            ),
                          ),
                          child: const Center(
                              child: Icon(Icons.newspaper_rounded,
                                  size: 80,
                                  color: Colors.white30)),
                        ),
                ),
              ),

              // ── Content ─────────────────────────────────────────────────
              SliverToBoxAdapter(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Header block
                    Container(
                      color: Colors.white,
                      padding: const EdgeInsets.fromLTRB(20, 24, 20, 20),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Category badge + reading time
                          Row(children: [
                            Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 10, vertical: 4),
                              decoration: BoxDecoration(
                                color: const Color(0xFFE0F2FE),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Text('📰 Cẩm nang',
                                  style: GoogleFonts.outfit(
                                      color: const Color(0xFF0891B2),
                                      fontWeight: FontWeight.w700,
                                      fontSize: 11)),
                            ),
                            const SizedBox(width: 8),
                            Icon(Icons.access_time,
                                size: 13,
                                color: Colors.grey.shade500),
                            const SizedBox(width: 4),
                            Text(_readingTime(content),
                                style: GoogleFonts.outfit(
                                    color: Colors.grey.shade500,
                                    fontSize: 12)),
                          ]),
                          const SizedBox(height: 14),
                          // Title
                          Text(item['title'] ?? '',
                              style: GoogleFonts.outfit(
                                  fontSize: 22,
                                  fontWeight: FontWeight.w800,
                                  height: 1.35,
                                  color: const Color(0xFF0F172A))),
                          const SizedBox(height: 16),
                          // Author row
                          Row(children: [
                            CircleAvatar(
                              radius: 18,
                              backgroundColor:
                                  const Color(0xFFE0F2FE),
                              child: Text(
                                (item['author'] ?? 'A')
                                    .substring(0, 1)
                                    .toUpperCase(),
                                style: GoogleFonts.outfit(
                                    fontWeight: FontWeight.w800,
                                    color: const Color(0xFF0891B2),
                                    fontSize: 14),
                              ),
                            ),
                            const SizedBox(width: 10),
                            Column(
                                crossAxisAlignment:
                                    CrossAxisAlignment.start,
                                children: [
                                  Text(item['author'] ?? 'Admin',
                                      style: GoogleFonts.outfit(
                                          fontWeight: FontWeight.w700,
                                          fontSize: 14)),
                                  Text('Biên tập · KNS 4.0',
                                      style: GoogleFonts.outfit(
                                          color: Colors.grey.shade500,
                                          fontSize: 12)),
                                ]),
                          ]),
                        ],
                      ),
                    ),

                    const SizedBox(height: 8),

                    // ── Key Points Box ───────────────────────────────────
                    if (keyPoints.isNotEmpty)
                      Container(
                        margin: const EdgeInsets.symmetric(horizontal: 16),
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          gradient: const LinearGradient(
                            colors: [
                              Color(0xFFE0F2FE),
                              Color(0xFFF0F9FF)
                            ],
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                          ),
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(
                              color: const Color(0xFF0891B2)
                                  .withValues(alpha: 0.25)),
                        ),
                        child: Column(
                          crossAxisAlignment:
                              CrossAxisAlignment.start,
                          children: [
                            Row(children: [
                              const Icon(Icons.lightbulb_rounded,
                                  color: Color(0xFF0891B2), size: 18),
                              const SizedBox(width: 6),
                              Text('Điểm chính của bài',
                                  style: GoogleFonts.outfit(
                                      fontWeight: FontWeight.w800,
                                      fontSize: 14,
                                      color: const Color(0xFF0891B2))),
                            ]),
                            const SizedBox(height: 10),
                            ...keyPoints.asMap().entries.map((e) =>
                                Padding(
                                  padding:
                                      const EdgeInsets.only(bottom: 6),
                                  child: Row(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Container(
                                        width: 20,
                                        height: 20,
                                        margin: const EdgeInsets.only(
                                            right: 8, top: 1),
                                        decoration: BoxDecoration(
                                          color:
                                              const Color(0xFF0891B2),
                                          borderRadius:
                                              BorderRadius.circular(6),
                                        ),
                                        child: Center(
                                          child: Text(
                                            '${e.key + 1}',
                                            style: GoogleFonts.outfit(
                                                color: Colors.white,
                                                fontWeight:
                                                    FontWeight.w800,
                                                fontSize: 11),
                                          ),
                                        ),
                                      ),
                                      Expanded(
                                        child: Text(e.value,
                                            style: GoogleFonts.outfit(
                                                fontSize: 13,
                                                color: const Color(
                                                    0xFF0F172A),
                                                height: 1.5)),
                                      ),
                                    ],
                                  ),
                                )),
                          ],
                        ),
                      ),

                    const SizedBox(height: 16),

                    // ── Body Content ─────────────────────────────────────
                    Container(
                      color: Colors.white,
                      padding:
                          const EdgeInsets.fromLTRB(20, 24, 20, 28),
                      child: Text(
                        content,
                        style: GoogleFonts.outfit(
                          fontSize: 16,
                          height: 1.75,
                          color: const Color(0xFF1E293B),
                          letterSpacing: 0.1,
                        ),
                      ),
                    ),

                    const SizedBox(height: 8),

                    // ── XP Earned Banner ─────────────────────────────────
                    Container(
                      margin: const EdgeInsets.symmetric(horizontal: 16),
                      padding: const EdgeInsets.symmetric(
                          horizontal: 16, vertical: 12),
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(
                          colors: [
                            Color(0xFF4F46E5),
                            Color(0xFF7C3AED)
                          ],
                        ),
                        borderRadius: BorderRadius.circular(14),
                      ),
                      child: Row(children: [
                        const Text('⚡',
                            style: TextStyle(fontSize: 22)),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Text(
                            '+2 XP cho việc đọc bài này!',
                            style: GoogleFonts.outfit(
                                color: Colors.white,
                                fontWeight: FontWeight.w700,
                                fontSize: 14),
                          ),
                        ),
                        GestureDetector(
                          onTap: _showXpToast,
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 12, vertical: 6),
                            decoration: BoxDecoration(
                              color: Colors.white
                                  .withValues(alpha: 0.2),
                              borderRadius:
                                  BorderRadius.circular(10),
                            ),
                            child: Text('Nhận XP',
                                style: GoogleFonts.outfit(
                                    color: Colors.white,
                                    fontWeight: FontWeight.w700,
                                    fontSize: 12)),
                          ),
                        ),
                      ]),
                    ),

                    const SizedBox(height: 24),

                    // ── Related Articles ─────────────────────────────────
                    if (_related.isNotEmpty) ...[
                      Padding(
                        padding:
                            const EdgeInsets.symmetric(horizontal: 16),
                        child: Text('📰 Bài viết liên quan',
                            style: GoogleFonts.outfit(
                                fontSize: 16,
                                fontWeight: FontWeight.w800,
                                color: const Color(0xFF0F172A))),
                      ),
                      const SizedBox(height: 12),
                      SizedBox(
                        height: 150,
                        child: ListView.builder(
                          scrollDirection: Axis.horizontal,
                          padding: const EdgeInsets.symmetric(
                              horizontal: 16),
                          itemCount: _related.length,
                          itemBuilder: (ctx, i) =>
                              _buildRelatedCard(_related[i]),
                        ),
                      ),
                    ],

                    const SizedBox(height: 40),
                  ],
                ),
              ),
            ],
          ),

          // ── Scroll Progress Bar ────────────────────────────────────────
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            child: SafeArea(
              bottom: false,
              child: LinearProgressIndicator(
                value: _scrollProgress,
                backgroundColor: Colors.transparent,
                color: const Color(0xFF06B6D4).withValues(alpha: 0.85),
                minHeight: 3,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRelatedCard(dynamic item) {
    return GestureDetector(
      onTap: () {
        UserProgressManager.addXp(2);
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (_) => NewsDetailScreen(
              newsItem: item as Map<String, dynamic>,
              allNews: widget.allNews,
            ),
          ),
        );
      },
      child: Container(
        width: 200,
        margin: const EdgeInsets.only(right: 12),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(14),
          boxShadow: [
            BoxShadow(
                color: Colors.black.withValues(alpha: 0.06),
                blurRadius: 10,
                offset: const Offset(0, 3))
          ],
        ),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          ClipRRect(
            borderRadius:
                const BorderRadius.vertical(top: Radius.circular(14)),
            child: item['image_url'] != null &&
                    (item['image_url'] as String).isNotEmpty
                ? Image.network(item['image_url'],
                    height: 90,
                    width: double.infinity,
                    fit: BoxFit.cover,
                    errorBuilder: (_, __, ___) => Container(
                        height: 90,
                        color: const Color(0xFFE0F2FE),
                        child: const Icon(Icons.article,
                            color: Color(0xFF0891B2), size: 30)))
                : Container(
                    height: 90,
                    color: const Color(0xFFE0F2FE),
                    child: const Icon(Icons.article_outlined,
                        color: Color(0xFF0891B2), size: 30)),
          ),
          Padding(
            padding: const EdgeInsets.all(8),
            child: Text(
              item['title'] ?? '',
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: GoogleFonts.outfit(
                  fontWeight: FontWeight.w700, fontSize: 12, height: 1.3),
            ),
          ),
        ]),
      ),
    );
  }
}

// ── XP Toast Overlay ──────────────────────────────────────────────────────────
class _XpToast extends StatefulWidget {
  final VoidCallback onDone;
  const _XpToast({required this.onDone});

  @override
  State<_XpToast> createState() => _XpToastState();
}

class _XpToastState extends State<_XpToast>
    with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;
  late Animation<double> _opacity;
  late Animation<Offset> _offset;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 1500));
    _opacity = Tween<double>(begin: 1.0, end: 0.0).animate(
        CurvedAnimation(parent: _ctrl, curve: const Interval(0.6, 1.0)));
    _offset = Tween<Offset>(
            begin: const Offset(0, 0), end: const Offset(0, -0.5))
        .animate(
            CurvedAnimation(parent: _ctrl, curve: Curves.easeOut));
    _ctrl.forward().then((_) => widget.onDone());
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Positioned(
      bottom: 120,
      left: 0,
      right: 0,
      child: SlideTransition(
        position: _offset,
        child: FadeTransition(
          opacity: _opacity,
          child: Center(
            child: Container(
              padding:
                  const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                    colors: [Color(0xFF4F46E5), Color(0xFF7C3AED)]),
                borderRadius: BorderRadius.circular(30),
                boxShadow: [
                  BoxShadow(
                      color: const Color(0xFF4F46E5).withValues(alpha: 0.4),
                      blurRadius: 16,
                      offset: const Offset(0, 4))
                ],
              ),
              child: Text('⚡ +2 XP',
                  style: GoogleFonts.outfit(
                      color: Colors.white,
                      fontWeight: FontWeight.w800,
                      fontSize: 16)),
            ),
          ),
        ),
      ),
    );
  }
}
