import 'dart:io';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:image_picker/image_picker.dart';
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
  File? _selectedImage;
  bool _uploadingImage = false;

  static const _topics = ['Chung', 'Kỹ năng', 'Chia sẻ', 'Hỏi đáp', 'Tin tức'];

  @override
  void dispose() {
    _contentCtrl.dispose();
    super.dispose();
  }

  Future<void> _pickImage() async {
    final picker = ImagePicker();
    final picked = await picker.pickImage(
      source: ImageSource.gallery,
      imageQuality: 80,
      maxWidth: 1080,
    );
    if (picked != null) {
      setState(() => _selectedImage = File(picked.path));
    }
  }

  void _removeImage() => setState(() => _selectedImage = null);

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
      // Upload ảnh trước nếu có
      String? imageUrl;
      if (_selectedImage != null) {
        setState(() => _uploadingImage = true);
        imageUrl = await ApiService.uploadCommunityImage(_selectedImage!.path);
        setState(() => _uploadingImage = false);
      }

      await ApiService.createPost(
        userId: widget.userId,
        userName: widget.userName,
        content: content,
        topic: _selectedTopic,
        imageUrl: imageUrl,
      );
      if (mounted) Navigator.pop(context, true);
    } catch (e) {
      if (mounted) {
        setState(() { _loading = false; _uploadingImage = false; });
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
    final cs = Theme.of(context).colorScheme;
    return Scaffold(
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
                      style: GoogleFonts.outfit(color: cs.onSurfaceVariant, fontSize: 13),
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
                      color: selected ? const Color(0xFF4F46E5) : cs.surface,
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(
                        color: selected ? const Color(0xFF4F46E5) : cs.outline,
                      ),
                      boxShadow: selected
                          ? [BoxShadow(color: const Color(0xFF4F46E5).withValues(alpha: 0.3), blurRadius: 8, offset: const Offset(0, 3))]
                          : [],
                    ),
                    child: Text(
                      topic,
                      style: GoogleFonts.outfit(
                        color: selected ? Colors.white : cs.onSurface,
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
                color: cs.surface,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: cs.outlineVariant),
                boxShadow: [
                  BoxShadow(color: Colors.black.withValues(alpha: 0.04), blurRadius: 10, offset: const Offset(0, 4)),
                ],
              ),
              child: TextField(
                controller: _contentCtrl,
                maxLines: 8,
                maxLength: 2000,
                onChanged: (_) => setState(() {}),
                style: GoogleFonts.outfit(fontSize: 15, height: 1.6),
                decoration: InputDecoration(
                  hintText: 'Chia sẻ điều gì đó với cộng đồng...\n\n💡 Kỹ năng bạn vừa học?\n❓ Câu hỏi bạn đang thắc mắc?\n🌟 Kinh nghiệm hay muốn chia sẻ?',
                  hintStyle: GoogleFonts.outfit(color: cs.onSurfaceVariant, fontSize: 14, height: 1.6),
                  border: InputBorder.none,
                  contentPadding: const EdgeInsets.all(16),
                ),
              ),
            ),
            const SizedBox(height: 16),

            // ── Image section ───────────────────────────────────────────────
            Text('Ảnh đính kèm', style: GoogleFonts.outfit(fontWeight: FontWeight.w700, fontSize: 15)),
            const SizedBox(height: 10),

            if (_selectedImage != null) ...[
              // Preview ảnh
              Stack(
                children: [
                  ClipRRect(
                    borderRadius: BorderRadius.circular(14),
                    child: AspectRatio(
                      aspectRatio: 16 / 9,
                      child: Image.file(_selectedImage!, fit: BoxFit.cover),
                    ),
                  ),
                  // Nút X xóa ảnh
                  Positioned(
                    top: 8,
                    right: 8,
                    child: GestureDetector(
                      onTap: _removeImage,
                      child: Container(
                        padding: const EdgeInsets.all(4),
                        decoration: BoxDecoration(
                          color: Colors.black.withValues(alpha: 0.6),
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(Icons.close_rounded, color: Colors.white, size: 18),
                      ),
                    ),
                  ),
                  if (_uploadingImage)
                    Positioned.fill(
                      child: Container(
                        decoration: BoxDecoration(
                          color: Colors.black.withValues(alpha: 0.4),
                          borderRadius: BorderRadius.circular(14),
                        ),
                        child: const Center(
                          child: CircularProgressIndicator(color: Colors.white),
                        ),
                      ),
                    ),
                ],
              ),
            ] else ...[
              // Nút chọn ảnh
              GestureDetector(
                onTap: _loading ? null : _pickImage,
                child: Container(
                  height: 100,
                  decoration: BoxDecoration(
                    color: cs.surfaceContainerHighest,
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(
                      color: const Color(0xFF4F46E5).withValues(alpha: 0.4),
                      style: BorderStyle.solid,
                    ),
                  ),
                  child: Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.add_photo_alternate_rounded,
                            size: 32, color: const Color(0xFF4F46E5).withValues(alpha: 0.7)),
                        const SizedBox(height: 6),
                        Text('Thêm ảnh từ thư viện',
                            style: GoogleFonts.outfit(
                                color: const Color(0xFF4F46E5),
                                fontWeight: FontWeight.w600,
                                fontSize: 13)),
                        Text('Tối đa 5MB',
                            style: GoogleFonts.outfit(color: cs.onSurfaceVariant, fontSize: 11)),
                      ],
                    ),
                  ),
                ),
              ),
            ],

            const SizedBox(height: 28),

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
                  _loading
                      ? (_uploadingImage ? 'Đang tải ảnh...' : 'Đang đăng...')
                      : 'Đăng bài',
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
