import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../utils/api_service.dart';
import '../utils/user_progress_manager.dart';

class PostDetailScreen extends StatefulWidget {
  final Map<String, dynamic> post;
  final String userId;
  final String userName;

  const PostDetailScreen({
    super.key,
    required this.post,
    required this.userId,
    required this.userName,
  });

  @override
  State<PostDetailScreen> createState() => _PostDetailScreenState();
}

class _PostDetailScreenState extends State<PostDetailScreen> {
  List<dynamic> _comments = [];
  bool _loadingComments = true;
  bool _sending = false;
  late Map<String, dynamic> _post;
  final _commentCtrl = TextEditingController();
  final _scrollCtrl = ScrollController();

  @override
  void initState() {
    super.initState();
    _post = Map<String, dynamic>.from(widget.post);
    _loadComments();
  }

  @override
  void dispose() {
    _commentCtrl.dispose();
    _scrollCtrl.dispose();
    super.dispose();
  }

  Future<void> _loadComments() async {
    try {
      final comments = await ApiService.getComments(_post['id']);
      if (mounted) setState(() { _comments = comments.where((c) => !(c['reported_by'] as List? ?? []).contains(widget.userId)).toList(); _loadingComments = false; });
    } catch (_) {
      if (mounted) setState(() => _loadingComments = false);
    }
  }

  Future<void> _sendComment() async {
    final content = _commentCtrl.text.trim();
    if (content.isEmpty) return;
    setState(() => _sending = true);
    try {
      final newComment = await ApiService.addComment(
        postId: _post['id'],
        userId: widget.userId,
        userName: widget.userName,
        content: content,
      );
      _commentCtrl.clear();
      setState(() {
        _comments.add(newComment);
        _post['comments_count'] = (_post['comments_count'] ?? 0) + 1;
      });
      // Scroll to bottom
      await Future.delayed(const Duration(milliseconds: 100));
      if (_scrollCtrl.hasClients) {
        _scrollCtrl.animateTo(
          _scrollCtrl.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Lỗi: $e'), backgroundColor: Colors.red.shade600),
        );
      }
    } finally {
      if (mounted) setState(() => _sending = false);
    }
    // +2 XP khi bình luận
    await UserProgressManager.addXp(2);
  }

  Future<void> _toggleLike() async {
    final liked = (_post['likes'] as List? ?? []).contains(widget.userId);
    setState(() {
      if (liked) {
        (_post['likes'] as List).remove(widget.userId);
        _post['likes_count'] = (_post['likes_count'] ?? 1) - 1;
      } else {
        (_post['likes'] as List? ?? []).add(widget.userId);
        _post['likes_count'] = (_post['likes_count'] ?? 0) + 1;
      }
    });
    try {
      await ApiService.toggleLike(_post['id'], widget.userId);
    } catch (_) {}
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

  @override
  Widget build(BuildContext context) {
    final liked = (_post['likes'] as List? ?? []).contains(widget.userId);

    return Scaffold(
      backgroundColor: const Color(0xFFF8F8FF),
      appBar: AppBar(
        title: Text('Bài đăng', style: GoogleFonts.outfit(fontWeight: FontWeight.w700)),
        backgroundColor: const Color(0xFF4F46E5),
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      body: Column(
        children: [
          Expanded(
            child: ListView(
              controller: _scrollCtrl,
              padding: const EdgeInsets.all(16),
              children: [
                // Post card
                Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(16),
                    boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.06), blurRadius: 12, offset: const Offset(0, 4))],
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Author info
                      Row(
                        children: [
                          CircleAvatar(
                            radius: 22,
                            backgroundColor: const Color(0xFF4F46E5).withValues(alpha: 0.12),
                            child: Text(
                              (_post['user_name'] ?? '?').isNotEmpty ? (_post['user_name'] as String)[0].toUpperCase() : '?',
                              style: GoogleFonts.outfit(fontWeight: FontWeight.w800, color: const Color(0xFF4F46E5), fontSize: 18),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(_post['user_name'] ?? 'Ẩn danh', style: GoogleFonts.outfit(fontWeight: FontWeight.w700, fontSize: 15)),
                                Text(_timeAgo(_post['created_at'] ?? ''), style: GoogleFonts.outfit(color: Colors.grey.shade500, fontSize: 12)),
                              ],
                            ),
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
                            decoration: BoxDecoration(
                              color: const Color(0xFF4F46E5).withValues(alpha: 0.1),
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: Text(_post['topic'] ?? 'Chung', style: GoogleFonts.outfit(color: const Color(0xFF4F46E5), fontSize: 12, fontWeight: FontWeight.w600)),
                          ),
                          PopupMenuButton<String>(
                            icon: Icon(Icons.more_horiz, color: Colors.grey.shade500),
                            onSelected: (val) async {
                              if (val == 'report') {
                                final confirm = await showDialog<bool>(context: context, builder: (c) => AlertDialog(
                                  title: Text('Báo cáo', style: GoogleFonts.outfit(fontWeight: FontWeight.bold)),
                                  content: Text('Bạn có chắc báo cáo và ẩn bài viết này?', style: GoogleFonts.outfit()),
                                  actions: [
                                    TextButton(onPressed: () => Navigator.pop(c, false), child: const Text('Hủy')),
                                    TextButton(onPressed: () => Navigator.pop(c, true), child: const Text('Báo cáo', style: TextStyle(color: Colors.red))),
                                  ],
                                ));
                                if (confirm == true) {
                                  try {
                                    await ApiService.reportPost(_post['id'], widget.userId);
                                    if (mounted) {
                                      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Đã báo cáo bài viết')));
                                      Navigator.pop(context);
                                    }
                                  } catch (e) {
                                    if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.toString())));
                                  }
                                }
                              }
                            },
                            itemBuilder: (ctx) => [PopupMenuItem(value: 'report', child: Row(children: [const Icon(Icons.flag, size: 18, color: Colors.red), const SizedBox(width: 8), Text('Báo cáo', style: GoogleFonts.outfit(color: Colors.red))]))],
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      Text(_post['content'] ?? '', style: GoogleFonts.outfit(fontSize: 16, height: 1.6, color: Colors.grey.shade800)),
                      const SizedBox(height: 16),
                      const Divider(),
                      const SizedBox(height: 8),
                      // Like action
                      Row(
                        children: [
                          InkWell(
                            onTap: _toggleLike,
                            borderRadius: BorderRadius.circular(8),
                            child: Padding(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
                              child: Row(
                                children: [
                                  Icon(
                                    liked ? Icons.favorite_rounded : Icons.favorite_border_rounded,
                                    size: 22,
                                    color: liked ? Colors.red.shade400 : Colors.grey.shade500,
                                  ),
                                  const SizedBox(width: 6),
                                  Text(
                                    '${_post['likes_count'] ?? 0} thích',
                                    style: GoogleFonts.outfit(
                                      color: liked ? Colors.red.shade400 : Colors.grey.shade600,
                                      fontWeight: FontWeight.w600, fontSize: 14,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                          const SizedBox(width: 16),
                          Icon(Icons.chat_bubble_outline_rounded, size: 20, color: Colors.grey.shade500),
                          const SizedBox(width: 6),
                          Text('${_post['comments_count'] ?? 0} bình luận', style: GoogleFonts.outfit(color: Colors.grey.shade600, fontSize: 14)),
                        ],
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 20),
                // Comments header
                Text('Bình luận', style: GoogleFonts.outfit(fontSize: 18, fontWeight: FontWeight.w800)),
                const SizedBox(height: 12),

                // Comments list
                if (_loadingComments)
                  const Center(child: CircularProgressIndicator())
                else if (_comments.isEmpty)
                  Center(
                    child: Column(
                      children: [
                        const SizedBox(height: 20),
                        Icon(Icons.chat_bubble_outline, size: 48, color: Colors.grey.shade300),
                        const SizedBox(height: 8),
                        Text('Chưa có bình luận. Hãy là người đầu tiên!', style: GoogleFonts.outfit(color: Colors.grey.shade400)),
                      ],
                    ),
                  )
                else
                  ..._comments.map((c) => _buildComment(c)),
              ],
            ),
          ),

          // Comment input bar
          Container(
            color: Colors.white,
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
            child: SafeArea(
              child: Row(
                children: [
                  CircleAvatar(
                    radius: 18,
                    backgroundColor: const Color(0xFF4F46E5).withValues(alpha: 0.12),
                    child: Text(
                      widget.userName.isNotEmpty ? widget.userName[0].toUpperCase() : '?',
                      style: GoogleFonts.outfit(fontWeight: FontWeight.w800, color: const Color(0xFF4F46E5), fontSize: 14),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: TextField(
                      controller: _commentCtrl,
                      style: GoogleFonts.outfit(fontSize: 14),
                      decoration: InputDecoration(
                        hintText: 'Viết bình luận...',
                        hintStyle: GoogleFonts.outfit(color: Colors.grey.shade400, fontSize: 14),
                        filled: true,
                        fillColor: const Color(0xFFF3F4F6),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(24),
                          borderSide: BorderSide.none,
                        ),
                        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  GestureDetector(
                    onTap: _sending ? null : _sendComment,
                    child: Container(
                      width: 40,
                      height: 40,
                      decoration: const BoxDecoration(
                        color: Color(0xFF4F46E5),
                        shape: BoxShape.circle,
                      ),
                      child: _sending
                          ? const Padding(
                              padding: EdgeInsets.all(10),
                              child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                            )
                          : const Icon(Icons.send_rounded, color: Colors.white, size: 18),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildComment(Map<String, dynamic> c) {
    final initial = (c['user_name'] as String? ?? '?').isNotEmpty
        ? (c['user_name'] as String)[0].toUpperCase()
        : '?';
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFEEF2FF)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          CircleAvatar(
            radius: 16,
            backgroundColor: const Color(0xFF7C3AED).withValues(alpha: 0.12),
            child: Text(initial, style: GoogleFonts.outfit(fontWeight: FontWeight.w800, color: const Color(0xFF7C3AED), fontSize: 12)),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text(c['user_name'] ?? 'Ẩn danh', style: GoogleFonts.outfit(fontWeight: FontWeight.w700, fontSize: 13)),
                    const SizedBox(width: 8),
                    Text(_timeAgo(c['created_at'] ?? ''), style: GoogleFonts.outfit(color: Colors.grey.shade400, fontSize: 11)),
                  ],
                ),
                const SizedBox(height: 4),
                Text(c['content'] ?? '', style: GoogleFonts.outfit(fontSize: 14, height: 1.4, color: Colors.grey.shade800)),
              ],
            ),
          ),
          IconButton(
            icon: Icon(Icons.flag_outlined, color: Colors.grey.shade400, size: 18),
            onPressed: () async {
              final confirm = await showDialog<bool>(
                context: context,
                builder: (ctx) => AlertDialog(
                  title: Text('Báo cáo', style: GoogleFonts.outfit(fontWeight: FontWeight.bold)),
                  content: Text('Báo cáo bình luận này?', style: GoogleFonts.outfit()),
                  actions: [
                    TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Hủy')),
                    TextButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('Báo cáo', style: TextStyle(color: Colors.red))),
                  ],
                ),
              );
              if (confirm == true) {
                try {
                  await ApiService.reportComment(c['id'], widget.userId);
                  if (mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Đã báo cáo bình luận')));
                    _loadComments();
                  }
                } catch (e) {
                  if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.toString())));
                }
              }
            },
          ),
        ],
      ),
    );
  }
}
