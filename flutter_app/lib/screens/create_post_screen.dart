import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../utils/api_service.dart';

class CreatePostScreen extends StatefulWidget {
  final String userId;
  final String userName;

  const CreatePostScreen({
    super.key,
    required this.userId,
    required this.userName,
  });

  @override
  State<CreatePostScreen> createState() => _CreatePostScreenState();
}

class _CreatePostScreenState extends State<CreatePostScreen> {
  final _contentCtrl = TextEditingController();
  String _selectedTopic = 'Chung';
  bool _loading = false;

  static const _topics = ['Chung', 'Kỹ năng', 'Chia sẻ', 'Hỏi đáp', 'Tin tức'];

  @override
  void dispose() {
    _contentCtrl.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    final content = _contentCtrl.text.trim();
    if (content.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Vui lòng nhập nội dung bài đăng', style: GoogleFonts.outfit()),
          backgroundColor: Colors.red.shade600,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ),
      );
      return;
    }

    setState(() => _loading = true);
    try {
      await ApiService.createPost(
        userId: widget.userId,
        userName: widget.userName,
        content: content,
        topic: _selectedTopic,
      );
      if (mounted) Navigator.pop(context, true);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Đăng bài thất bại: $e', style: GoogleFonts.outfit()),
            backgroundColor: Colors.red.shade600,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8F8FF),
      appBar: AppBar(
        title: Text('Đăng bài mới', style: GoogleFonts.outfit(fontWeight: FontWeight.w700)),
        backgroundColor: const Color(0xFF4F46E5),
        foregroundColor: Colors.white,
        elevation: 0,
        actions: [
          TextButton(
            onPressed: _loading ? null : _submit,
            child: _loading
                ? const SizedBox(
                    width: 20, height: 20,
                    child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                  )
                : Text(
                    'ĐĂNG',
                    style: GoogleFonts.outfit(
                      color: Colors.white,
                      fontWeight: FontWeight.w800,
                      fontSize: 15,
                    ),
                  ),
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // User info
            Row(
              children: [
                CircleAvatar(
                  radius: 22,
                  backgroundColor: const Color(0xFF4F46E5).withValues(alpha: 0.15),
                  child: Text(
                    widget.userName.isNotEmpty ? widget.userName[0].toUpperCase() : '?',
                    style: GoogleFonts.outfit(
                      fontWeight: FontWeight.w800,
                      color: const Color(0xFF4F46E5),
                      fontSize: 18,
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      widget.userName,
                      style: GoogleFonts.outfit(fontWeight: FontWeight.w700, fontSize: 16),
                    ),
                    Text(
                      'Đang đăng bài công khai',
                      style: GoogleFonts.outfit(color: Colors.grey.shade500, fontSize: 13),
                    ),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 20),

            // Topic selector
            Text('Chủ đề', style: GoogleFonts.outfit(fontWeight: FontWeight.w700, fontSize: 15)),
            const SizedBox(height: 10),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: _topics.map((topic) {
                final selected = _selectedTopic == topic;
                return GestureDetector(
                  onTap: () => setState(() => _selectedTopic = topic),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    decoration: BoxDecoration(
                      color: selected ? const Color(0xFF4F46E5) : Colors.white,
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(
                        color: selected ? const Color(0xFF4F46E5) : Colors.grey.shade300,
                      ),
                      boxShadow: selected
                          ? [BoxShadow(color: const Color(0xFF4F46E5).withValues(alpha: 0.3), blurRadius: 8, offset: const Offset(0, 3))]
                          : [],
                    ),
                    child: Text(
                      topic,
                      style: GoogleFonts.outfit(
                        color: selected ? Colors.white : Colors.grey.shade700,
                        fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
                        fontSize: 13,
                      ),
                    ),
                  ),
                );
              }).toList(),
            ),
            const SizedBox(height: 24),

            // Content field
            Text('Nội dung', style: GoogleFonts.outfit(fontWeight: FontWeight.w700, fontSize: 15)),
            const SizedBox(height: 10),
            Container(
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: Colors.grey.shade200),
                boxShadow: [
                  BoxShadow(color: Colors.black.withValues(alpha: 0.04), blurRadius: 10, offset: const Offset(0, 4)),
                ],
              ),
              child: TextField(
                controller: _contentCtrl,
                maxLines: 10,
                maxLength: 2000,
                onChanged: (_) => setState(() {}),
                style: GoogleFonts.outfit(fontSize: 15, height: 1.6),
                decoration: InputDecoration(
                  hintText: 'Chia sẻ điều gì đó với cộng đồng...\n\n💡 Kỹ năng bạn vừa học?\n❓ Câu hỏi bạn đang thắc mắc?\n🌟 Kinh nghiệm hay muốn chia sẻ?',
                  hintStyle: GoogleFonts.outfit(color: Colors.grey.shade400, fontSize: 14, height: 1.6),
                  border: InputBorder.none,
                  contentPadding: const EdgeInsets.all(16),
                ),
              ),
            ),
            const SizedBox(height: 24),

            // Submit button
            SizedBox(
              width: double.infinity,
              height: 52,
              child: ElevatedButton.icon(
                onPressed: _loading ? null : _submit,
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF4F46E5),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                  elevation: 3,
                ),
                icon: _loading
                    ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                    : const Icon(Icons.send_rounded, color: Colors.white),
                label: Text(
                  _loading ? 'Đang đăng...' : 'Đăng bài',
                  style: GoogleFonts.outfit(fontSize: 16, fontWeight: FontWeight.w700, color: Colors.white),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
