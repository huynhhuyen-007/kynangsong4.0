import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../utils/api_service.dart';
import '../utils/auth_manager.dart';
import '../utils/user_progress_manager.dart';
import '../widgets/app_scaffold.dart';
import 'create_post_screen.dart';
import 'post_detail_screen.dart';

class CommunityScreen extends StatefulWidget {
  const CommunityScreen({super.key});

  @override
  State<CommunityScreen> createState() => _CommunityScreenState();
}

class _CommunityScreenState extends State<CommunityScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  List<dynamic> _newPosts = [];
  List<dynamic> _hotPosts = [];
  bool _isLoading = true;
  String _userId = '';
  String _userName = '';
  String _selectedTopic = 'Tất cả';
  final List<String> _topics = ['Tất cả', 'Kỹ năng', 'Chia sẻ', 'Hỏi đáp', 'Tin tức', 'Chung'];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _tabController.addListener(() {
      if (!_tabController.indexIsChanging) setState(() {});
    });
    _init();
  }

  Future<void> _init() async {
    final user = await AuthManager.getUser();
    _userId = user['id'] ?? '';
    _userName = user['name'] ?? '';
    await _loadPosts();
  }

  Future<void> _loadPosts() async {
    setState(() => _isLoading = true);
    try {
      final newP = await ApiService.getPosts(sort: 'new');
      final hotP = await ApiService.getPosts(sort: 'hot');
      if (mounted) {
        setState(() {
          _newPosts = newP.where((p) => !(p['reported_by'] as List? ?? []).contains(_userId)).toList();
          _hotPosts = hotP.where((p) => !(p['reported_by'] as List? ?? []).contains(_userId)).toList();
          _isLoading = false;
        });
      }
    } catch (_) {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  String _timeAgo(String iso) {
    final dt = DateTime.tryParse(iso)?.toLocal();
    if (dt == null) return '';
    final diff = DateTime.now().difference(dt);
    if (diff.inMinutes < 1) return 'Vừa xong';
    if (diff.inMinutes < 60) return '${diff.inMinutes} phút trước';
    if (diff.inHours < 24) return '${diff.inHours} giờ trước';
    if (diff.inDays < 7) return '${diff.inDays} ngày trước';
    return '${(diff.inDays / 7).floor()} tuần trước';
  }

  Color _topicColor(String topic) {
    const map = {
      'Kỹ năng': Color(0xFF4F46E5),
      'Chia sẻ': Color(0xFF059669),
      'Hỏi đáp': Color(0xFFD97706),
      'Tin tức': Color(0xFF0891B2),
      'Chung': Color(0xFF7C3AED),
    };
    return map[topic] ?? const Color(0xFF7C3AED);
  }

  Future<void> _toggleLike(List<dynamic> posts, int index) async {
    final post = posts[index];
    final liked = (post['likes'] as List).contains(_userId);
    setState(() {
      if (liked) {
        (post['likes'] as List).remove(_userId);
        post['likes_count'] = (post['likes_count'] ?? 1) - 1;
      } else {
        (post['likes'] as List).add(_userId);
        post['likes_count'] = (post['likes_count'] ?? 0) + 1;
      }
    });
    try {
      await ApiService.toggleLike(post['id'], _userId);
    } catch (_) {
      // Revert
      setState(() {
        if (liked) {
          (post['likes'] as List).add(_userId);
          post['likes_count'] = (post['likes_count'] ?? 0) + 1;
        } else {
          (post['likes'] as List).remove(_userId);
          post['likes_count'] = (post['likes_count'] ?? 1) - 1;
        }
      });
    }
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  List<dynamic> _filterByTopic(List<dynamic> posts) {
    if (_selectedTopic == 'Tất cả') return posts;
    return posts.where((p) => p['topic'] == _selectedTopic).toList();
  }

  @override
  Widget build(BuildContext context) {
    return AppScaffold(
      title: 'Cộng đồng',
      currentIndex: 1,
      body: Column(
        children: [
          _buildTabBar(),
          _buildTopicChips(),
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : TabBarView(
                    controller: _tabController,
                    children: [
                      _buildFeed(_filterByTopic(_newPosts)),
                      _buildFeed(_filterByTopic(_hotPosts)),
                    ],
                  ),
          ),
        ],
      ),
      floatingActionButton: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(30),
          boxShadow: [BoxShadow(color: const Color(0xFF4F46E5).withValues(alpha: 0.5), blurRadius: 16, offset: const Offset(0, 6))],
        ),
        child: FloatingActionButton.extended(
          onPressed: () async {
            final created = await Navigator.push<bool>(
              context,
              MaterialPageRoute(
                builder: (_) => CreatePostScreen(userId: _userId, userName: _userName),
              ),
            );
            if (created == true) {
              _loadPosts();
              await UserProgressManager.addXp(2); // +2 XP khi đăng bài
            }
          },
          backgroundColor: const Color(0xFF4F46E5),
          icon: const Icon(Icons.edit_rounded, color: Colors.white, size: 24),
          label: Text('Đăng bài ngay', style: GoogleFonts.outfit(color: Colors.white, fontWeight: FontWeight.w700, fontSize: 16)),
        ),
      ),
    );
  }

  Widget _buildTabBar() {
    return Container(
      color: Colors.white,
      child: TabBar(
        controller: _tabController,
        indicatorColor: const Color(0xFF4F46E5),
        indicatorWeight: 3,
        labelColor: const Color(0xFF4F46E5),
        unselectedLabelColor: Colors.grey,
        labelStyle: GoogleFonts.outfit(fontWeight: FontWeight.w700, fontSize: 14),
        tabs: const [
          Tab(icon: Icon(Icons.access_time_rounded, size: 18), text: 'Mới nhất'),
          Tab(icon: Icon(Icons.local_fire_department_rounded, size: 18), text: 'Đang hot'),
        ],
      ),
    );
  }

  Widget _buildTopicChips() {
    return Container(
      color: Colors.white,
      padding: const EdgeInsets.fromLTRB(12, 0, 12, 10),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Row(
          children: _topics.map((topic) {
            final isSelected = _selectedTopic == topic;
            return GestureDetector(
              onTap: () => setState(() => _selectedTopic = topic),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                margin: const EdgeInsets.only(right: 8),
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
                decoration: BoxDecoration(
                  color: isSelected ? const Color(0xFF4F46E5) : const Color(0xFFF0F4FF),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  topic == 'Tất cả' ? '🌐 Tất cả' :
                  topic == 'Kỹ năng' ? '📚 #kỹ_năng' :
                  topic == 'Chia sẻ' ? '💬 #chia_sẻ' :
                  topic == 'Hỏi đáp' ? '❓ #hỏi_đáp' :
                  topic == 'Tin tức' ? '📰 #tin_tức' : '🌀 #chung',
                  style: GoogleFonts.outfit(
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    color: isSelected ? Colors.white : Colors.grey.shade700,
                  ),
                ),
              ),
            );
          }).toList(),
        ),
      ),
    );
  }

  Widget _buildFeed(List<dynamic> posts) {
    if (posts.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.forum_outlined, size: 64, color: Colors.grey),
            const SizedBox(height: 16),
            Text('Chưa có bài đăng nào', style: GoogleFonts.outfit(color: Colors.grey, fontSize: 16)),
            const SizedBox(height: 8),
            Text('Hãy là người đầu tiên chia sẻ!', style: GoogleFonts.outfit(color: Colors.grey.shade400)),
          ],
        ),
      );
    }
    return RefreshIndicator(
      onRefresh: _loadPosts,
      child: ListView.builder(
        padding: const EdgeInsets.only(top: 8, bottom: 80),
        itemCount: posts.length,
        itemBuilder: (ctx, i) => _buildPostCard(posts, i),
      ),
    );
  }

  Widget _buildPostCard(List<dynamic> posts, int index) {
    final post = posts[index];
    final liked = (post['likes'] as List? ?? []).contains(_userId);
    final initials = (post['user_name'] as String? ?? '?').isNotEmpty
        ? (post['user_name'] as String)[0].toUpperCase()
        : '?';
    final topicColor = _topicColor(post['topic'] ?? 'Chung');

    return GestureDetector(
      onTap: () async {
        await Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => PostDetailScreen(
              post: post,
              userId: _userId,
              userName: _userName,
            ),
          ),
        );
        _loadPosts();
      },
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.06),
              blurRadius: 12,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header row
              Row(
                children: [
                  CircleAvatar(
                    radius: 22,
                    backgroundColor: Colors.primaries[(post['user_id'] ?? '').toString().hashCode.abs() % Colors.primaries.length],
                    child: Text(
                      initials,
                      style: GoogleFonts.outfit(
                        fontWeight: FontWeight.w800,
                        color: Colors.white,
                        fontSize: 18,
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          post['user_name'] ?? 'Ẩn danh',
                          style: GoogleFonts.outfit(fontWeight: FontWeight.w700, fontSize: 14),
                        ),
                        Text(
                          _timeAgo(post['created_at'] ?? ''),
                          style: GoogleFonts.outfit(color: Colors.grey.shade500, fontSize: 12),
                        ),
                      ],
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: topicColor.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      post['topic'] ?? 'Chung',
                      style: GoogleFonts.outfit(
                        color: topicColor,
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                  PopupMenuButton<String>(
                    icon: Icon(Icons.more_horiz, color: Colors.grey.shade500),
                    onSelected: (value) async {
                      if (value == 'report') {
                        final confirm = await showDialog<bool>(
                          context: context,
                          builder: (c) => AlertDialog(
                            title: Text('Báo cáo', style: GoogleFonts.outfit(fontWeight: FontWeight.bold)),
                            content: Text('Bạn có chắc chắn muốn báo cáo và ẩn bài viết này không?', style: GoogleFonts.outfit()),
                            actions: [
                              TextButton(onPressed: () => Navigator.pop(c, false), child: const Text('Hủy')),
                              TextButton(onPressed: () => Navigator.pop(c, true), child: const Text('Báo cáo', style: TextStyle(color: Colors.red))),
                            ],
                          ),
                        );
                        if (confirm == true) {
                          try {
                            await ApiService.reportPost(post['id'], _userId);
                            if (mounted) {
                              ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Đã báo cáo bài viết')));
                              _loadPosts(); // reload data
                            }
                          } catch (e) {
                            if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.toString())));
                          }
                        }
                      }
                    },
                    itemBuilder: (ctx) => [
                      PopupMenuItem(
                        value: 'report',
                        child: Row(children: [const Icon(Icons.flag, size: 18, color: Colors.red), const SizedBox(width: 8), Text('Báo cáo', style: GoogleFonts.outfit(color: Colors.red))]),
                      ),
                    ],
                  ),
                ],
              ),
              const SizedBox(height: 12),
              // Content
              Container(
                width: double.infinity,
                padding: const EdgeInsets.only(left: 14, top: 4, bottom: 4),
                decoration: BoxDecoration(border: Border(left: BorderSide(color: Colors.grey.shade300, width: 3))),
                child: Text(
                  post['content'] ?? '',
                  maxLines: 4,
                  overflow: TextOverflow.ellipsis,
                  style: GoogleFonts.outfit(fontSize: 15, height: 1.5, color: Colors.grey.shade800, fontWeight: FontWeight.w500),
                ),
              ),
              const SizedBox(height: 14),
              // Actions
              Row(
                children: [
                  InkWell(
                    onTap: () => _toggleLike(posts, index),
                    borderRadius: BorderRadius.circular(8),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
                      child: Row(
                        children: [
                          Icon(
                            liked ? Icons.favorite_rounded : Icons.favorite_border_rounded,
                            size: 20,
                            color: liked ? Colors.red.shade400 : Colors.grey.shade500,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            '${post['likes_count'] ?? 0}',
                            style: GoogleFonts.outfit(
                              color: liked ? Colors.red.shade400 : Colors.grey.shade600,
                              fontWeight: FontWeight.w600,
                              fontSize: 13,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Row(
                    children: [
                      Icon(Icons.chat_bubble_outline_rounded, size: 18, color: Colors.grey.shade500),
                      const SizedBox(width: 4),
                      Text(
                        '${post['comments_count'] ?? 0} bình luận',
                        style: GoogleFonts.outfit(color: Colors.grey.shade600, fontSize: 13),
                      ),
                    ],
                  ),
                  const Spacer(),
                  Icon(Icons.arrow_forward_ios_rounded, size: 14, color: Colors.grey.shade400),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
