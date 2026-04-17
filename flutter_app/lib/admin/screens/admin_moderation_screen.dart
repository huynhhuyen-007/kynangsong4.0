import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../utils/api_service.dart';
import '../../utils/auth_manager.dart';
import '../widgets/admin_scaffold.dart';
import '../widgets/admin_app_bar.dart';
import '../admin_theme.dart';

class AdminModerationScreen extends StatefulWidget {
  const AdminModerationScreen({super.key});
  @override
  State<AdminModerationScreen> createState() => _AdminModerationScreenState();
}

class _AdminModerationScreenState extends State<AdminModerationScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  // Posts tab
  List<dynamic> _allPosts = [];
  List<dynamic> _filteredPosts = [];
  Set<String> _selectedPosts = {};
  bool _loadingPosts = true;
  String _postFilter = 'all';

  // Comments tab
  List<dynamic> _allComments = [];
  List<dynamic> _filteredComments = [];
  bool _loadingComments = true;
  String _commentFilter = 'all';

  String? _adminId;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _load();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    final admin = await AuthManager.getUser();
    _adminId = admin['id'];
    _loadPosts();
    _loadComments();
  }

  Future<void> _loadPosts() async {
    setState(() { _loadingPosts = true; _selectedPosts.clear(); });
    try {
      final posts = await ApiService.adminGetPosts(_adminId!);
      if (mounted) setState(() { _allPosts = posts; _applyPostFilter(); _loadingPosts = false; });
    } catch (_) { if (mounted) setState(() => _loadingPosts = false); }
  }

  Future<void> _loadComments() async {
    setState(() => _loadingComments = true);
    try {
      final comments = await ApiService.adminGetComments(_adminId!);
      if (mounted) setState(() { _allComments = comments; _applyCommentFilter(); _loadingComments = false; });
    } catch (_) { if (mounted) setState(() => _loadingComments = false); }
  }

  void _applyPostFilter() {
    _filteredPosts = _allPosts.where((p) {
      final isHidden = p['is_hidden'] == true;
      final isReported = (p['report_count'] ?? (p['reported_by'] as List?)?.length ?? 0) > 0;
      if (_postFilter == 'hidden') return isHidden;
      if (_postFilter == 'visible') return !isHidden;
      if (_postFilter == 'reported') return isReported;
      return true;
    }).toList();
    _filteredPosts.sort((a, b) {
      final aR = (a['report_count'] ?? (a['reported_by'] as List?)?.length ?? 0) as int;
      final bR = (b['report_count'] ?? (b['reported_by'] as List?)?.length ?? 0) as int;
      if (bR != aR) return bR.compareTo(aR);
      // Nếu cùng số report, sort theo ngày mới nhất
      final aDate = a['created_at'] ?? '';
      final bDate = b['created_at'] ?? '';
      return bDate.compareTo(aDate);
    });
  }

  void _applyCommentFilter() {
    _filteredComments = _allComments.where((c) {
      final isReported = (c['report_count'] ?? 0) > 0;
      if (_commentFilter == 'reported') return isReported;
      return true;
    }).toList();
  }

  // ── Post Actions ────────────────────────────────────────────────────────────
  Future<void> _toggleHide(Map<String, dynamic> post) async {
    try {
      await ApiService.toggleHidePost(post['id'].toString(), _adminId!);
      await _loadPosts();
      if (mounted) _showSuccess('Đã cập nhật bài viết');
    } catch (e) { if (mounted) _showError(e.toString()); }
  }

  Future<void> _deletePost(Map<String, dynamic> post) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: Text('Xoá bài viết', style: GoogleFonts.outfit(fontWeight: FontWeight.w700)),
        content: Text('Hành động không thể hoàn tác.', style: GoogleFonts.outfit()),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Huỷ')),
          ElevatedButton(onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(backgroundColor: AdminTheme.red),
            child: Text('Xoá', style: GoogleFonts.outfit(color: Colors.white))),
        ],
      ),
    ) ?? false;
    if (!ok) return;
    try {
      await ApiService.deletePost(post['id'].toString(), _adminId!);
      await _loadPosts();
      if (mounted) _showSuccess('Đã xoá bài viết');
    } catch (e) { if (mounted) _showError(e.toString()); }
  }

  Future<void> _bulkHide() async {
    if (_selectedPosts.isEmpty) return;
    try {
      for (final id in _selectedPosts) {
        final post = _allPosts.firstWhere((p) => p['id'].toString() == id, orElse: () => null);
        if (post != null && post['is_hidden'] != true) await ApiService.toggleHidePost(id, _adminId!);
      }
      await _loadPosts();
      if (mounted) _showSuccess('Đã ẩn ${_selectedPosts.length} bài');
    } catch (e) { if (mounted) _showError(e.toString()); }
  }

  Future<void> _bulkDelete() async {
    if (_selectedPosts.isEmpty) return;
    final ok = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: Text('Xoá ${_selectedPosts.length} bài', style: GoogleFonts.outfit(fontWeight: FontWeight.w700)),
        content: Text('Hành động không thể hoàn tác.', style: GoogleFonts.outfit()),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Huỷ')),
          ElevatedButton(onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(backgroundColor: AdminTheme.red),
            child: Text('Xoá tất cả', style: GoogleFonts.outfit(color: Colors.white))),
        ],
      ),
    ) ?? false;
    if (!ok) return;
    try {
      for (final id in _selectedPosts) await ApiService.deletePost(id, _adminId!);
      await _loadPosts();
      if (mounted) _showSuccess('Đã xoá ${_selectedPosts.length} bài');
    } catch (e) { if (mounted) _showError(e.toString()); }
  }

  // ── Comment Actions ─────────────────────────────────────────────────────────
  Future<void> _deleteComment(Map<String, dynamic> comment) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: Text('Xoá bình luận', style: GoogleFonts.outfit(fontWeight: FontWeight.w700)),
        content: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text('Nội dung:', style: GoogleFonts.outfit(fontSize: 12, color: AdminTheme.textSecondary)),
          const SizedBox(height: 6),
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: AdminTheme.red.withOpacity(0.06),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Text(comment['content'] ?? '',
              style: GoogleFonts.outfit(fontSize: 13), maxLines: 3, overflow: TextOverflow.ellipsis),
          ),
          const SizedBox(height: 8),
          Text('Hành động không thể hoàn tác.', style: GoogleFonts.outfit(fontSize: 12, color: AdminTheme.orange)),
        ]),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Huỷ')),
          ElevatedButton(onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(backgroundColor: AdminTheme.red),
            child: Text('Xoá', style: GoogleFonts.outfit(color: Colors.white))),
        ],
      ),
    ) ?? false;
    if (!ok) return;
    try {
      await ApiService.adminDeleteComment(comment['id'].toString(), _adminId!);
      await _loadComments();
      if (mounted) _showSuccess('Đã xoá bình luận');
    } catch (e) { if (mounted) _showError(e.toString()); }
  }

  // ── Helpers ─────────────────────────────────────────────────────────────────
  String _formatDateTime(String? isoDate) {
    if (isoDate == null || isoDate.isEmpty) return 'Không rõ';
    try {
      final dt = DateTime.parse(isoDate).toLocal();
      return '${dt.day.toString().padLeft(2,'0')}/${dt.month.toString().padLeft(2,'0')}/${dt.year} · ${dt.hour.toString().padLeft(2,'0')}:${dt.minute.toString().padLeft(2,'0')}';
    } catch (_) { return 'Không rõ'; }
  }

  String _timeAgo(String? isoDate) {
    if (isoDate == null || isoDate.isEmpty) return '';
    try {
      final dt = DateTime.parse(isoDate).toLocal();
      final diff = DateTime.now().difference(dt);
      if (diff.inMinutes < 1) return 'vừa xong';
      if (diff.inMinutes < 60) return '${diff.inMinutes} phút trước';
      if (diff.inHours < 24) return '${diff.inHours} giờ trước';
      if (diff.inDays < 30) return '${diff.inDays} ngày trước';
      return '${(diff.inDays / 30).floor()} tháng trước';
    } catch (_) { return ''; }
  }

  void _showError(String msg) => ScaffoldMessenger.of(context).showSnackBar(SnackBar(
    content: Text(msg), backgroundColor: AdminTheme.red,
    behavior: SnackBarBehavior.floating, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8))));

  void _showSuccess(String msg) => ScaffoldMessenger.of(context).showSnackBar(SnackBar(
    content: Text(msg), backgroundColor: AdminTheme.green,
    behavior: SnackBarBehavior.floating, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8))));

  @override
  Widget build(BuildContext context) {
    final reportedPostCount = _allPosts.where((p) {
      final r = p['reported_by'];
      return r is List && r.isNotEmpty;
    }).length;
    final hiddenCount = _allPosts.where((p) => p['is_hidden'] == true).length;
    final reportedCommentCount = _allComments.where((c) => (c['report_count'] ?? 0) > 0).length;

    return AdminScaffold(
      currentIndex: 3,
      child: Scaffold(
        appBar: AdminAppBar(
          title: 'Moderation Center',
          showRefresh: true,
          onRefresh: _load,
        ),
        body: Column(children: [
          // TabBar
          Container(
            decoration: BoxDecoration(border: Border(bottom: BorderSide(color: AdminTheme.border))),
            child: TabBar(
              controller: _tabController,
              indicatorColor: AdminTheme.blue,
              labelColor: AdminTheme.blue,
              unselectedLabelColor: AdminTheme.textSecondary,
              labelStyle: GoogleFonts.outfit(fontWeight: FontWeight.w700, fontSize: 13),
              unselectedLabelStyle: GoogleFonts.outfit(fontSize: 13),
              tabs: [
                Tab(child: Row(mainAxisSize: MainAxisSize.min, children: [
                  const Icon(Icons.article_outlined, size: 15),
                  const SizedBox(width: 5),
                  Text('Bài viết (${_allPosts.length})'),
                  if (reportedPostCount > 0) ...[
                    const SizedBox(width: 4),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1),
                      decoration: BoxDecoration(color: AdminTheme.red, borderRadius: BorderRadius.circular(10)),
                      child: Text('$reportedPostCount', style: GoogleFonts.outfit(fontSize: 9, color: Colors.white, fontWeight: FontWeight.w800)),
                    ),
                  ],
                ])),
                Tab(child: Row(mainAxisSize: MainAxisSize.min, children: [
                  const Icon(Icons.chat_bubble_outline, size: 15),
                  const SizedBox(width: 5),
                  Text('Bình luận (${_allComments.length})'),
                  if (reportedCommentCount > 0) ...[
                    const SizedBox(width: 4),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1),
                      decoration: BoxDecoration(color: AdminTheme.red, borderRadius: BorderRadius.circular(10)),
                      child: Text('$reportedCommentCount', style: GoogleFonts.outfit(fontSize: 9, color: Colors.white, fontWeight: FontWeight.w800)),
                    ),
                  ],
                ])),
              ],
            ),
          ),
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: [_buildPostsTab(hiddenCount, reportedPostCount), _buildCommentsTab(reportedCommentCount)],
            ),
          ),
        ]),
      ),
    );
  }

  // ── Posts Tab ────────────────────────────────────────────────────────────────
  Widget _buildPostsTab(int hiddenCount, int reportedCount) {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        // Stats row
        Row(children: [
          _miniStat('Tổng bài', '${_allPosts.length}', AdminTheme.blue),
          const SizedBox(width: 8),
          _miniStat('🚩 Báo cáo', '$reportedCount', AdminTheme.red),
          const SizedBox(width: 8),
          _miniStat('🙈 Ẩn', '$hiddenCount', AdminTheme.orange),
        ]),
        const SizedBox(height: 12),
        // Filter chips
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Row(children: [
            _filterChip('Tất cả', 'all', true),
            const SizedBox(width: 8),
            _filterChip('🚩 Báo cáo', 'reported', true),
            const SizedBox(width: 8),
            _filterChip('🙈 Ẩn', 'hidden', true),
            const SizedBox(width: 8),
            _filterChip('✅ Hiển thị', 'visible', true),
          ]),
        ),
        const SizedBox(height: 10),
        // Bulk action bar
        if (_selectedPosts.isNotEmpty)
          Container(
            margin: const EdgeInsets.only(bottom: 10),
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
            decoration: BoxDecoration(
              color: AdminTheme.blue.withOpacity(0.1),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: AdminTheme.blue.withOpacity(0.3)),
            ),
            child: Row(children: [
              Text('Đã chọn ${_selectedPosts.length} bài',
                style: GoogleFonts.outfit(color: AdminTheme.blue, fontWeight: FontWeight.w600, fontSize: 13)),
              const Spacer(),
              TextButton.icon(
                onPressed: _bulkHide,
                icon: const Icon(Icons.visibility_off_outlined, size: 15, color: AdminTheme.orange),
                label: Text('Ẩn', style: GoogleFonts.outfit(color: AdminTheme.orange, fontSize: 12)),
              ),
              TextButton.icon(
                onPressed: _bulkDelete,
                icon: const Icon(Icons.delete_outline, size: 15, color: AdminTheme.red),
                label: Text('Xoá', style: GoogleFonts.outfit(color: AdminTheme.red, fontSize: 12)),
              ),
              IconButton(
                onPressed: () => setState(() => _selectedPosts.clear()),
                icon: const Icon(Icons.close, size: 16, color: AdminTheme.textSecondary),
                padding: EdgeInsets.zero,
              ),
            ]),
          ),
        if (_filteredPosts.isNotEmpty)
          Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: Text('💡 Long-press để chọn nhiều bài',
              style: GoogleFonts.outfit(fontSize: 11, color: AdminTheme.textMuted)),
          ),
        Expanded(
          child: _loadingPosts
            ? const Center(child: CircularProgressIndicator(color: AdminTheme.blue))
            : _filteredPosts.isEmpty
              ? Center(child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
                  const Icon(Icons.check_circle_outline, size: 56, color: AdminTheme.green),
                  const SizedBox(height: 10),
                  Text('Không có bài nào cần xử lý 🎉',
                    style: GoogleFonts.outfit(color: AdminTheme.textSecondary, fontSize: 14)),
                ]))
              : RefreshIndicator(
                  onRefresh: _loadPosts, color: AdminTheme.blue,
                  child: ListView.separated(
                    itemCount: _filteredPosts.length,
                    separatorBuilder: (_, __) => const SizedBox(height: 8),
                    itemBuilder: (_, i) => _buildPostCard(_filteredPosts[i]),
                  ),
                ),
        ),
      ]),
    );
  }

  Widget _buildPostCard(Map<String, dynamic> post) {
    final id = post['id'].toString();
    final isSelected = _selectedPosts.contains(id);
    final isHidden = post['is_hidden'] == true;
    final reportCount = (post['report_count'] ?? (post['reported_by'] as List?)?.length ?? 0) as int;
    final content = post['content'] ?? '';
    final author = post['user_name'] ?? 'Ẩn danh';
    final topic = post['topic'] ?? '';
    final isHot = reportCount >= 3;
    final borderColor = isSelected ? AdminTheme.blue
      : isHot ? AdminTheme.red
      : reportCount > 0 ? AdminTheme.red.withOpacity(0.4)
      : AdminTheme.border;

    return GestureDetector(
      onLongPress: () => setState(() {
        if (isSelected) _selectedPosts.remove(id); else _selectedPosts.add(id);
      }),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        decoration: BoxDecoration(
          color: isSelected ? AdminTheme.blue.withOpacity(0.06)
            : isHot ? AdminTheme.red.withOpacity(0.04)
            : Theme.of(context).cardTheme.color,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: borderColor, width: isSelected || isHot ? 1.5 : 1),
        ),
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Row(children: [
              if (isSelected)
                const Icon(Icons.check_circle, color: AdminTheme.blue, size: 16)
              else
                const Icon(Icons.person_outline, color: AdminTheme.textSecondary, size: 16),
              const SizedBox(width: 6),
              Text(author, style: GoogleFonts.outfit(fontSize: 13, fontWeight: FontWeight.w700)),
              if (topic.isNotEmpty) ...[
                const SizedBox(width: 6),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                  decoration: BoxDecoration(
                    color: AdminTheme.purple.withOpacity(0.15),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Text(topic, style: GoogleFonts.outfit(fontSize: 10, color: AdminTheme.purple)),
                ),
              ],
              const Spacer(),
              if (isHot)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(color: AdminTheme.red, borderRadius: BorderRadius.circular(10)),
                  child: Text('🔥 $reportCount reports',
                    style: GoogleFonts.outfit(fontSize: 10, fontWeight: FontWeight.w800, color: Colors.white)),
                )
              else if (reportCount > 0)
                _badge('🚩 $reportCount', AdminTheme.red),
              if (isHidden) ...[
                const SizedBox(width: 6),
                _badge('Ẩn', AdminTheme.orange),
              ],
            ]),
            // Ngày đăng
            Padding(
              padding: const EdgeInsets.only(top: 4, bottom: 4),
              child: Row(children: [
                const Icon(Icons.access_time_rounded, size: 11, color: AdminTheme.textMuted),
                const SizedBox(width: 3),
                Tooltip(
                  message: _formatDateTime(post['created_at']),
                  child: Text(_timeAgo(post['created_at']),
                    style: GoogleFonts.outfit(fontSize: 11, color: AdminTheme.textMuted)),
                ),
                const SizedBox(width: 6),
                Text(_formatDateTime(post['created_at']),
                  style: GoogleFonts.outfit(fontSize: 11, color: AdminTheme.textMuted)),
              ]),
            ),
            Text(
              content.length > 130 ? '${content.substring(0, 130)}...' : content,
              style: GoogleFonts.outfit(fontSize: 13, color: AdminTheme.textSecondary, height: 1.4),
            ),
            const SizedBox(height: 10),
            Row(children: [
              const Spacer(),
              _actionBtn(
                isHidden ? Icons.visibility_rounded : Icons.visibility_off_rounded,
                isHidden ? 'Hiện' : 'Ẩn',
                isHidden ? AdminTheme.green : AdminTheme.orange,
                () => _toggleHide(post),
              ),
              const SizedBox(width: 8),
              _actionBtn(Icons.delete_outline, 'Xoá', AdminTheme.red, () => _deletePost(post)),
            ]),
          ]),
        ),
      ),
    );
  }

  // ── Comments Tab ──────────────────────────────────────────────────────────────
  Widget _buildCommentsTab(int reportedCount) {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [
          _miniStat('Tổng comment', '${_allComments.length}', AdminTheme.blue),
          const SizedBox(width: 8),
          _miniStat('🚩 Báo cáo', '$reportedCount', AdminTheme.red),
        ]),
        const SizedBox(height: 12),
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Row(children: [
            _filterChip('Tất cả', 'all', false),
            const SizedBox(width: 8),
            _filterChip('🚩 Báo cáo', 'reported', false),
          ]),
        ),
        const SizedBox(height: 10),
        Expanded(
          child: _loadingComments
            ? const Center(child: CircularProgressIndicator(color: AdminTheme.blue))
            : _filteredComments.isEmpty
              ? Center(child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
                  const Icon(Icons.chat_bubble_outline, size: 56, color: AdminTheme.textMuted),
                  const SizedBox(height: 10),
                  Text('Không có bình luận nào cần xử lý 🎉',
                    style: GoogleFonts.outfit(color: AdminTheme.textSecondary, fontSize: 14)),
                ]))
              : RefreshIndicator(
                  onRefresh: _loadComments, color: AdminTheme.blue,
                  child: ListView.separated(
                    itemCount: _filteredComments.length,
                    separatorBuilder: (_, __) => const SizedBox(height: 8),
                    itemBuilder: (_, i) => _buildCommentCard(_filteredComments[i]),
                  ),
                ),
        ),
      ]),
    );
  }

  Widget _buildCommentCard(Map<String, dynamic> comment) {
    final reportCount = (comment['report_count'] ?? 0) as int;
    final isReported = reportCount > 0;
    final author = comment['user_name'] ?? 'Ẩn danh';
    final content = comment['content'] ?? '';

    return Container(
      decoration: BoxDecoration(
        color: isReported
          ? AdminTheme.red.withOpacity(0.04)
          : Theme.of(context).cardTheme.color,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isReported ? AdminTheme.red.withOpacity(0.4) : AdminTheme.border,
          width: isReported ? 1.5 : 1,
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          // Header: author + badges
          Row(children: [
            const Icon(Icons.person_outline, color: AdminTheme.textSecondary, size: 16),
            const SizedBox(width: 6),
            Text(author, style: GoogleFonts.outfit(fontSize: 13, fontWeight: FontWeight.w700)),
            const Spacer(),
            if (isReported)
              _badge('🚩 $reportCount báo cáo', AdminTheme.red),
          ]),
          // Ngày comment
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 4),
            child: Row(children: [
              const Icon(Icons.access_time_rounded, size: 11, color: AdminTheme.textMuted),
              const SizedBox(width: 3),
              Text(_formatDateTime(comment['created_at']),
                style: GoogleFonts.outfit(fontSize: 11, color: AdminTheme.textMuted)),
              const SizedBox(width: 6),
              Text('(${_timeAgo(comment['created_at'])})',
                style: GoogleFonts.outfit(fontSize: 11, color: AdminTheme.textMuted)),
            ]),
          ),
          // Post reference
          if ((comment['post_id'] ?? '').isNotEmpty)
            Padding(
              padding: const EdgeInsets.only(bottom: 6),
              child: Row(children: [
                const Icon(Icons.article_outlined, size: 11, color: AdminTheme.textMuted),
                const SizedBox(width: 3),
                Text('Bài: #${comment['post_id'].toString().substring(0, 8)}...',
                  style: GoogleFonts.outfit(fontSize: 11, color: AdminTheme.textMuted)),
              ]),
            ),
          // Content
          Text(
            content.length > 150 ? '${content.substring(0, 150)}...' : content,
            style: GoogleFonts.outfit(fontSize: 13, color: AdminTheme.textSecondary, height: 1.4),
          ),
          const SizedBox(height: 10),
          Row(children: [
            const Spacer(),
            _actionBtn(Icons.delete_outline, 'Xoá', AdminTheme.red, () => _deleteComment(comment)),
          ]),
        ]),
      ),
    );
  }

  // ── Common Widgets ──────────────────────────────────────────────────────────
  Widget _miniStat(String label, String value, Color color) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 10),
        decoration: BoxDecoration(
          color: color.withOpacity(0.1),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: color.withOpacity(0.3)),
        ),
        child: Column(children: [
          Text(value, style: GoogleFonts.outfit(fontSize: 18, fontWeight: FontWeight.w800, color: color)),
          Text(label, style: GoogleFonts.outfit(fontSize: 10, color: AdminTheme.textSecondary)),
        ]),
      ),
    );
  }

  Widget _filterChip(String label, String value, bool isPost) {
    final currentFilter = isPost ? _postFilter : _commentFilter;
    final selected = currentFilter == value;
    return GestureDetector(
      onTap: () => setState(() {
        if (isPost) { _postFilter = value; _applyPostFilter(); _selectedPosts.clear(); }
        else { _commentFilter = value; _applyCommentFilter(); }
      }),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
        decoration: BoxDecoration(
          color: selected ? AdminTheme.blue.withOpacity(0.2) : Colors.transparent,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: selected ? AdminTheme.blue : AdminTheme.border),
        ),
        child: Text(label, style: GoogleFonts.outfit(fontSize: 12, fontWeight: FontWeight.w600,
          color: selected ? AdminTheme.blue : AdminTheme.textSecondary)),
      ),
    );
  }

  Widget _badge(String label, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: color.withOpacity(0.15), borderRadius: BorderRadius.circular(10),
        border: Border.all(color: color.withOpacity(0.4)),
      ),
      child: Text(label, style: GoogleFonts.outfit(fontSize: 10, fontWeight: FontWeight.w700, color: color)),
    );
  }

  Widget _actionBtn(IconData icon, String label, Color color, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: color.withOpacity(0.1), borderRadius: BorderRadius.circular(8),
          border: Border.all(color: color.withOpacity(0.3)),
        ),
        child: Row(mainAxisSize: MainAxisSize.min, children: [
          Icon(icon, size: 14, color: color),
          const SizedBox(width: 4),
          Text(label, style: GoogleFonts.outfit(fontSize: 12, color: color, fontWeight: FontWeight.w600)),
        ]),
      ),
    );
  }
}
