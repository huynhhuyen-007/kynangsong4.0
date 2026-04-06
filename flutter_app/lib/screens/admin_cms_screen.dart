import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../utils/api_service.dart';
import '../utils/auth_manager.dart';
import 'admin_cms_form_screen.dart';

class AdminCmsScreen extends StatefulWidget {
  const AdminCmsScreen({super.key});

  @override
  State<AdminCmsScreen> createState() => _AdminCmsScreenState();
}

class _AdminCmsScreenState extends State<AdminCmsScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  String _adminId = '';
  List<dynamic> _skills = [], _news = [], _fun = [], _posts = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
    _tabController.addListener(() { if (!_tabController.indexIsChanging) setState(() {}); });
    _init();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _init() async {
    final user = await AuthManager.getUser();
    _adminId = user['id'] ?? '';
    await _loadAll();
  }

  Future<void> _loadAll() async {
    setState(() => _loading = true);
    try {
      final results = await Future.wait([
        ApiService.getSkills(),
        ApiService.getNews(),
        ApiService.getFun(),
        ApiService.adminGetPosts(_adminId),
      ]);
      if (mounted) {
        setState(() {
          _skills = results[0];
          _news = results[1];
          _fun = results[2];
          _posts = results[3];
          _loading = false;
        });
      }
    } catch (_) {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _confirmDelete(String type, String id) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text('Xác nhận xóa', style: GoogleFonts.outfit(fontWeight: FontWeight.w700)),
        content: Text('Bạn có chắc muốn xóa mục này không?', style: GoogleFonts.outfit()),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: Text('Hủy', style: GoogleFonts.outfit())),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red.shade600),
            onPressed: () => Navigator.pop(ctx, true),
            child: Text('Xóa', style: GoogleFonts.outfit()),
          ),
        ],
      ),
    );
    if (confirm != true) return;

    try {
      switch (type) {
        case 'skill': await ApiService.deleteSkill(id, _adminId); break;
        case 'news': await ApiService.deleteNews(id, _adminId); break;
        case 'fun': await ApiService.deleteFun(id, _adminId); break;
        case 'post': await ApiService.deletePost(id, _adminId); break;
      }
      _loadAll();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Đã xóa thành công', style: GoogleFonts.outfit()),
            backgroundColor: Colors.green.shade600,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Lỗi: $e'), backgroundColor: Colors.red.shade600),
        );
      }
    }
  }

  Future<void> _toggleHidePost(Map<String, dynamic> post) async {
    try {
      await ApiService.toggleHidePost(post['id'], _adminId);
      _loadAll();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Lỗi: $e'), backgroundColor: Colors.red.shade600),
        );
      }
    }
  }

  void _openForm(String type, {Map<String, dynamic>? item}) async {
    final saved = await Navigator.push<bool>(
      context,
      MaterialPageRoute(
        builder: (_) => AdminCmsFormScreen(type: type, adminId: _adminId, item: item),
      ),
    );
    if (saved == true) _loadAll();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8F8FF),
      appBar: AppBar(
        title: Text('Quản lý nội dung', style: GoogleFonts.outfit(fontWeight: FontWeight.w700)),
        backgroundColor: const Color(0xFF4F46E5),
        foregroundColor: Colors.white,
        elevation: 0,
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: Colors.white,
          labelColor: Colors.white,
          unselectedLabelColor: Colors.white60,
          labelStyle: GoogleFonts.outfit(fontWeight: FontWeight.w700, fontSize: 13),
          isScrollable: true,
          tabs: const [
            Tab(icon: Icon(Icons.star_outline, size: 16), text: 'Kỹ năng'),
            Tab(icon: Icon(Icons.newspaper_outlined, size: 16), text: 'Tin tức'),
            Tab(icon: Icon(Icons.lightbulb_outline, size: 16), text: 'Vui học'),
            Tab(icon: Icon(Icons.forum_outlined, size: 16), text: 'Bài đăng'),
          ],
        ),
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : TabBarView(
              controller: _tabController,
              children: [
                _buildContentTab(_skills, 'skill', icon: Icons.star_rounded, color: const Color(0xFF4F46E5)),
                _buildContentTab(_news, 'news', icon: Icons.newspaper_rounded, color: const Color(0xFF0891B2)),
                _buildContentTab(_fun, 'fun', icon: Icons.lightbulb_rounded, color: const Color(0xFFD97706)),
                _buildPostsTab(),
              ],
            ),
      floatingActionButton: _tabController.index < 3
          ? FloatingActionButton.extended(
              onPressed: () => _openForm(['skill', 'news', 'fun'][_tabController.index]),
              backgroundColor: const Color(0xFF4F46E5),
              icon: const Icon(Icons.add_rounded, color: Colors.white),
              label: Text('Thêm mới', style: GoogleFonts.outfit(color: Colors.white, fontWeight: FontWeight.w600)),
            )
          : null,
    );
  }

  Widget _buildContentTab(List<dynamic> items, String type, {required IconData icon, required Color color}) {
    if (items.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 64, color: Colors.grey.shade300),
            const SizedBox(height: 16),
            Text('Chưa có nội dung', style: GoogleFonts.outfit(color: Colors.grey)),
            const SizedBox(height: 8),
            Text('Nhấn "+ Thêm mới" để bắt đầu', style: GoogleFonts.outfit(color: Colors.grey.shade400, fontSize: 13)),
          ],
        ),
      );
    }
    return RefreshIndicator(
      onRefresh: _loadAll,
      child: ListView.builder(
        padding: const EdgeInsets.only(top: 12, bottom: 90, left: 12, right: 12),
        itemCount: items.length,
        itemBuilder: (ctx, i) {
          final item = items[i];
          return Container(
            margin: const EdgeInsets.only(bottom: 10),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: color.withValues(alpha: 0.15)),
              boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.04), blurRadius: 8, offset: const Offset(0, 3))],
            ),
            child: ListTile(
              contentPadding: const EdgeInsets.fromLTRB(14, 8, 8, 8),
              leading: Container(
                width: 42, height: 42,
                decoration: BoxDecoration(color: color.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(10)),
                child: Icon(icon, color: color, size: 22),
              ),
              title: Text(
                item['title'] ?? '',
                style: GoogleFonts.outfit(fontWeight: FontWeight.w700, fontSize: 14),
                maxLines: 2, overflow: TextOverflow.ellipsis,
              ),
              subtitle: Text(
                type == 'skill' ? (item['category'] ?? '') :
                type == 'news' ? (item['author'] ?? 'Admin') :
                (item['type'] == 'video' ? '🎬 Video' : '💡 Mẹo vặt'),
                style: GoogleFonts.outfit(color: color, fontSize: 12, fontWeight: FontWeight.w600),
              ),
              trailing: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  IconButton(
                    icon: Icon(Icons.edit_outlined, color: Colors.blue.shade600, size: 20),
                    onPressed: () => _openForm(type, item: item),
                    tooltip: 'Sửa',
                  ),
                  IconButton(
                    icon: Icon(Icons.delete_outline, color: Colors.red.shade400, size: 20),
                    onPressed: () => _confirmDelete(type, item['id']),
                    tooltip: 'Xóa',
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildPostsTab() {
    if (_posts.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.forum_outlined, size: 64, color: Colors.grey),
            const SizedBox(height: 16),
            Text('Chưa có bài đăng nào', style: GoogleFonts.outfit(color: Colors.grey)),
          ],
        ),
      );
    }
    return RefreshIndicator(
      onRefresh: _loadAll,
      child: ListView.builder(
        padding: const EdgeInsets.all(12),
        itemCount: _posts.length,
        itemBuilder: (ctx, i) {
          final post = _posts[i];
          final isHidden = post['is_hidden'] == true;
          return Container(
            margin: const EdgeInsets.only(bottom: 10),
            decoration: BoxDecoration(
              color: isHidden ? Colors.grey.shade50 : Colors.white,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: isHidden ? Colors.grey.shade200 : const Color(0xFFEEF2FF)),
              boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.04), blurRadius: 8, offset: const Offset(0, 3))],
            ),
            child: Padding(
              padding: const EdgeInsets.all(14),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Row(
                          children: [
                            CircleAvatar(
                              radius: 16,
                              backgroundColor: const Color(0xFF4F46E5).withValues(alpha: 0.1),
                              child: Text(
                                (post['user_name'] ?? '?').isNotEmpty ? (post['user_name'] as String)[0].toUpperCase() : '?',
                                style: GoogleFonts.outfit(fontWeight: FontWeight.w700, color: const Color(0xFF4F46E5), fontSize: 12),
                              ),
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                post['user_name'] ?? 'Ẩn danh',
                                style: GoogleFonts.outfit(fontWeight: FontWeight.w700, fontSize: 13),
                              ),
                            ),
                          ],
                        ),
                      ),
                      if (isHidden)
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                          decoration: BoxDecoration(color: Colors.red.shade50, borderRadius: BorderRadius.circular(8)),
                          child: Text('Ẩn', style: GoogleFonts.outfit(color: Colors.red.shade400, fontSize: 11, fontWeight: FontWeight.w600)),
                        ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text(
                    post['content'] ?? '',
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: GoogleFonts.outfit(fontSize: 13, color: Colors.grey.shade700, height: 1.4),
                  ),
                  const SizedBox(height: 10),
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                        decoration: BoxDecoration(color: const Color(0xFFEEF2FF), borderRadius: BorderRadius.circular(8)),
                        child: Text(post['topic'] ?? 'Chung', style: GoogleFonts.outfit(color: const Color(0xFF4F46E5), fontSize: 11, fontWeight: FontWeight.w600)),
                      ),
                      const SizedBox(width: 8),
                      Icon(Icons.favorite, size: 14, color: Colors.red.shade300),
                      const SizedBox(width: 2),
                      Text('${post['likes_count'] ?? 0}', style: GoogleFonts.outfit(fontSize: 12, color: Colors.grey.shade600)),
                      const SizedBox(width: 8),
                      Icon(Icons.chat_bubble_outline, size: 14, color: Colors.grey.shade400),
                      const SizedBox(width: 2),
                      Text('${post['comments_count'] ?? 0}', style: GoogleFonts.outfit(fontSize: 12, color: Colors.grey.shade600)),
                      const Spacer(),
                      // Toggle hide
                      IconButton(
                        icon: Icon(
                          isHidden ? Icons.visibility_off_outlined : Icons.visibility_outlined,
                          color: isHidden ? Colors.green.shade600 : Colors.orange.shade600,
                          size: 20,
                        ),
                        onPressed: () => _toggleHidePost(post),
                        tooltip: isHidden ? 'Bỏ ẩn' : 'Ẩn bài',
                      ),
                      IconButton(
                        icon: Icon(Icons.delete_outline, color: Colors.red.shade400, size: 20),
                        onPressed: () => _confirmDelete('post', post['id']),
                        tooltip: 'Xóa bài',
                      ),
                    ],
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}
