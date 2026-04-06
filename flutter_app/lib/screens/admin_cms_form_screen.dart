import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../utils/api_service.dart';

class AdminCmsFormScreen extends StatefulWidget {
  final String type; // 'skill' | 'news' | 'fun'
  final String adminId;
  final Map<String, dynamic>? item; // null = create mode, non-null = edit mode

  const AdminCmsFormScreen({
    super.key,
    required this.type,
    required this.adminId,
    this.item,
  });

  @override
  State<AdminCmsFormScreen> createState() => _AdminCmsFormScreenState();
}

class _AdminCmsFormScreenState extends State<AdminCmsFormScreen> {
  final _formKey = GlobalKey<FormState>();
  bool _loading = false;

  // Common
  final _titleCtrl = TextEditingController();
  final _contentCtrl = TextEditingController();
  final _imageUrlCtrl = TextEditingController();

  // Skill specific
  final _categoryCtrl = TextEditingController();
  final _descriptionCtrl = TextEditingController();
  int _durationMinutes = 5;

  // News specific
  final _summaryCtrl = TextEditingController();
  final _authorCtrl = TextEditingController();

  // Fun specific
  String _funType = 'tip';
  final _mediaUrlCtrl = TextEditingController();

  bool get _isEdit => widget.item != null;

  @override
  void initState() {
    super.initState();
    if (_isEdit) _fillForm(widget.item!);
  }

  void _fillForm(Map<String, dynamic> item) {
    _titleCtrl.text = item['title'] ?? '';
    _contentCtrl.text = item['content'] ?? '';
    _imageUrlCtrl.text = item['image_url'] ?? '';

    if (widget.type == 'skill') {
      _categoryCtrl.text = item['category'] ?? '';
      _descriptionCtrl.text = item['description'] ?? '';
      _durationMinutes = item['duration_minutes'] ?? 5;
    } else if (widget.type == 'news') {
      _summaryCtrl.text = item['summary'] ?? '';
      _authorCtrl.text = item['author'] ?? 'Admin';
    } else if (widget.type == 'fun') {
      _funType = item['type'] ?? 'tip';
      _mediaUrlCtrl.text = item['media_url'] ?? '';
    }
  }

  @override
  void dispose() {
    for (final c in [_titleCtrl, _contentCtrl, _imageUrlCtrl, _categoryCtrl,
        _descriptionCtrl, _summaryCtrl, _authorCtrl, _mediaUrlCtrl]) {
      c.dispose();
    }
    super.dispose();
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _loading = true);

    try {
      final id = widget.item?['id'];
      if (widget.type == 'skill') {
        if (_isEdit) {
          await ApiService.updateSkill(id!, adminId: widget.adminId, title: _titleCtrl.text.trim(),
              category: _categoryCtrl.text.trim(), description: _descriptionCtrl.text.trim(),
              imageUrl: _imageUrlCtrl.text.trim(), content: _contentCtrl.text.trim(),
              durationMinutes: _durationMinutes);
        } else {
          await ApiService.createSkill(adminId: widget.adminId, title: _titleCtrl.text.trim(),
              category: _categoryCtrl.text.trim(), description: _descriptionCtrl.text.trim(),
              imageUrl: _imageUrlCtrl.text.trim(), content: _contentCtrl.text.trim(),
              durationMinutes: _durationMinutes);
        }
      } else if (widget.type == 'news') {
        if (_isEdit) {
          await ApiService.updateNews(id!, adminId: widget.adminId, title: _titleCtrl.text.trim(),
              summary: _summaryCtrl.text.trim(), content: _contentCtrl.text.trim(),
              imageUrl: _imageUrlCtrl.text.trim(), author: _authorCtrl.text.trim());
        } else {
          await ApiService.createNews(adminId: widget.adminId, title: _titleCtrl.text.trim(),
              summary: _summaryCtrl.text.trim(), content: _contentCtrl.text.trim(),
              imageUrl: _imageUrlCtrl.text.trim(), author: _authorCtrl.text.trim());
        }
      } else if (widget.type == 'fun') {
        if (_isEdit) {
          await ApiService.updateFun(id!, adminId: widget.adminId, title: _titleCtrl.text.trim(),
              type: _funType, mediaUrl: _mediaUrlCtrl.text.trim(), content: _contentCtrl.text.trim());
        } else {
          await ApiService.createFun(adminId: widget.adminId, title: _titleCtrl.text.trim(),
              type: _funType, mediaUrl: _mediaUrlCtrl.text.trim(), content: _contentCtrl.text.trim());
        }
      }
      if (mounted) Navigator.pop(context, true);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Lỗi: $e', style: GoogleFonts.outfit()),
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

  String get _typeName {
    switch (widget.type) {
      case 'skill': return 'Kỹ năng';
      case 'news': return 'Tin tức';
      case 'fun': return 'Vui học';
      default: return 'Nội dung';
    }
  }

  Color get _typeColor {
    switch (widget.type) {
      case 'skill': return const Color(0xFF4F46E5);
      case 'news': return const Color(0xFF0891B2);
      case 'fun': return const Color(0xFFD97706);
      default: return const Color(0xFF4F46E5);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8F8FF),
      appBar: AppBar(
        title: Text('${_isEdit ? "Sửa" : "Thêm"} $_typeName',
            style: GoogleFonts.outfit(fontWeight: FontWeight.w700)),
        backgroundColor: _typeColor,
        foregroundColor: Colors.white,
        elevation: 0,
        actions: [
          TextButton(
            onPressed: _loading ? null : _save,
            child: _loading
                ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                : Text('LƯU', style: GoogleFonts.outfit(color: Colors.white, fontWeight: FontWeight.w800, fontSize: 15)),
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildField('Tiêu đề *', _titleCtrl, maxLines: 2, validator: (v) => (v?.trim().isEmpty ?? true) ? 'Không được để trống' : null),
              const SizedBox(height: 16),
              _buildField('URL Ảnh', _imageUrlCtrl, hint: 'https://...', keyboard: TextInputType.url),
              const SizedBox(height: 16),

              // Type-specific fields
              if (widget.type == 'skill') ...[
                _buildField('Danh mục *', _categoryCtrl, hint: 'Giao tiếp, Tư duy, Cảm xúc...', validator: (v) => (v?.trim().isEmpty ?? true) ? 'Không được để trống' : null),
                const SizedBox(height: 16),
                _buildField('Mô tả ngắn *', _descriptionCtrl, maxLines: 3, validator: (v) => (v?.trim().isEmpty ?? true) ? 'Không được để trống' : null),
                const SizedBox(height: 16),
                _buildDurationPicker(),
                const SizedBox(height: 16),
              ],
              if (widget.type == 'news') ...[
                _buildField('Tóm tắt *', _summaryCtrl, maxLines: 3, validator: (v) => (v?.trim().isEmpty ?? true) ? 'Không được để trống' : null),
                const SizedBox(height: 16),
                _buildField('Tác giả', _authorCtrl, hint: 'Admin'),
                const SizedBox(height: 16),
              ],
              if (widget.type == 'fun') ...[
                _buildFunTypePicker(),
                const SizedBox(height: 16),
                _buildField('URL Media', _mediaUrlCtrl, hint: 'URL ảnh hoặc video...', keyboard: TextInputType.url),
                const SizedBox(height: 16),
              ],

              _buildField('Nội dung *', _contentCtrl, maxLines: 10,
                  validator: (v) => (v?.trim().isEmpty ?? true) ? 'Không được để trống' : null),
              const SizedBox(height: 28),

              SizedBox(
                width: double.infinity, height: 52,
                child: ElevatedButton.icon(
                  onPressed: _loading ? null : _save,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: _typeColor,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                    elevation: 3,
                  ),
                  icon: _loading
                      ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                      : Icon(_isEdit ? Icons.save_rounded : Icons.add_rounded, color: Colors.white),
                  label: Text(
                    _loading ? 'Đang lưu...' : (_isEdit ? 'Lưu thay đổi' : 'Thêm $_typeName'),
                    style: GoogleFonts.outfit(fontSize: 16, fontWeight: FontWeight.w700, color: Colors.white),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildField(String label, TextEditingController ctrl, {
    int maxLines = 1,
    String? hint,
    TextInputType? keyboard,
    String? Function(String?)? validator,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: GoogleFonts.outfit(fontWeight: FontWeight.w700, fontSize: 14)),
        const SizedBox(height: 6),
        TextFormField(
          controller: ctrl,
          maxLines: maxLines,
          keyboardType: keyboard,
          validator: validator,
          style: GoogleFonts.outfit(fontSize: 14),
          decoration: InputDecoration(
            hintText: hint,
            hintStyle: GoogleFonts.outfit(color: Colors.grey.shade400, fontSize: 14),
            filled: true,
            fillColor: Colors.white,
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: Colors.grey.shade200)),
            enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: Colors.grey.shade200)),
            focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: _typeColor, width: 2)),
            contentPadding: const EdgeInsets.all(14),
          ),
        ),
      ],
    );
  }

  Widget _buildDurationPicker() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Thời lượng học: $_durationMinutes phút', style: GoogleFonts.outfit(fontWeight: FontWeight.w700, fontSize: 14)),
        const SizedBox(height: 6),
        Slider(
          value: _durationMinutes.toDouble(),
          min: 1, max: 60,
          divisions: 59,
          activeColor: _typeColor,
          label: '$_durationMinutes phút',
          onChanged: (v) => setState(() => _durationMinutes = v.round()),
        ),
      ],
    );
  }

  Widget _buildFunTypePicker() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Loại nội dung', style: GoogleFonts.outfit(fontWeight: FontWeight.w700, fontSize: 14)),
        const SizedBox(height: 8),
        Row(
          children: [
            _typePill('tip', '💡 Mẹo vặt'),
            const SizedBox(width: 10),
            _typePill('video', '🎬 Video'),
          ],
        ),
      ],
    );
  }

  Widget _typePill(String value, String label) {
    final selected = _funType == value;
    return GestureDetector(
      onTap: () => setState(() => _funType = value),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
        decoration: BoxDecoration(
          color: selected ? _typeColor : Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: selected ? _typeColor : Colors.grey.shade300),
        ),
        child: Text(label, style: GoogleFonts.outfit(color: selected ? Colors.white : Colors.grey.shade700, fontWeight: FontWeight.w600, fontSize: 13)),
      ),
    );
  }
}
