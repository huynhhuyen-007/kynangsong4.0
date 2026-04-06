import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../utils/user_progress_manager.dart';

class SkillDetailScreen extends StatefulWidget {
  final Map<String, dynamic> skillItem;

  const SkillDetailScreen({super.key, required this.skillItem});

  @override
  State<SkillDetailScreen> createState() => _SkillDetailScreenState();
}

class _SkillDetailScreenState extends State<SkillDetailScreen> {
  bool _isCompleted = false;
  bool _checkingComplete = true;

  @override
  void initState() {
    super.initState();
    _checkCompleted();
    // Give +2 XP for opening a skill
    UserProgressManager.addXp(2);
  }

  Future<void> _checkCompleted() async {
    final done = await UserProgressManager.isSkillCompleted(widget.skillItem['id'] ?? '');
    if (mounted) setState(() { _isCompleted = done; _checkingComplete = false; });
  }

  Future<void> _markComplete() async {
    final id = widget.skillItem['id'] ?? '';
    await UserProgressManager.markSkillCompleted(id);
    setState(() => _isCompleted = true);
    if (mounted) {
      showDialog(
        context: context,
        builder: (ctx) => Dialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
          child: Padding(
            padding: const EdgeInsets.all(28),
            child: Column(mainAxisSize: MainAxisSize.min, children: [
              const Text('🎉', style: TextStyle(fontSize: 56)),
              const SizedBox(height: 12),
              Text('Xuất sắc!', style: GoogleFonts.outfit(fontWeight: FontWeight.w800, fontSize: 22, color: const Color(0xFF4F46E5))),
              const SizedBox(height: 8),
              Text('Bạn đã hoàn thành kỹ năng này!\n+5 XP được tích lũy.',
                textAlign: TextAlign.center,
                style: GoogleFonts.outfit(color: Colors.grey.shade700, height: 1.5)),
              const SizedBox(height: 20),
              ElevatedButton(
                style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF4F46E5), minimumSize: const Size(double.infinity, 44)),
                onPressed: () { Navigator.pop(ctx); Navigator.pop(context); },
                child: Text('Tiếp tục học 🚀', style: GoogleFonts.outfit(fontWeight: FontWeight.w700)),
              ),
            ]),
          ),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final skill = widget.skillItem;
    return Scaffold(
      body: CustomScrollView(
        slivers: [
          SliverAppBar(
            expandedHeight: 240,
            pinned: true,
            backgroundColor: const Color(0xFF4F46E5),
            foregroundColor: Colors.white,
            flexibleSpace: FlexibleSpaceBar(
              background: skill['image_url'] != null && (skill['image_url'] as String).isNotEmpty
                  ? Hero(
                      tag: 'skill_img_${skill['id']}',
                      child: Stack(fit: StackFit.expand, children: [
                        Image.network(skill['image_url'], fit: BoxFit.cover,
                          errorBuilder: (_, __, ___) => Container(color: const Color(0xFF4F46E5))),
                        Container(color: Colors.black.withValues(alpha: 0.3)),
                      ]),
                    )
                  : Container(
                      decoration: const BoxDecoration(
                        gradient: LinearGradient(
                          colors: [Color(0xFF4F46E5), Color(0xFF7C3AED)],
                          begin: Alignment.topLeft, end: Alignment.bottomRight,
                        ),
                      ),
                    ),
            ),
          ),
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Category + completed badge
                  Row(children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
                      decoration: BoxDecoration(color: const Color(0xFFEEF2FF), borderRadius: BorderRadius.circular(20)),
                      child: Text(skill['category'] ?? 'Khác',
                        style: GoogleFonts.outfit(color: const Color(0xFF4F46E5), fontWeight: FontWeight.w700, fontSize: 13)),
                    ),
                    if (_isCompleted) ...[
                      const SizedBox(width: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
                        decoration: BoxDecoration(color: const Color(0xFF059669), borderRadius: BorderRadius.circular(20)),
                        child: Row(mainAxisSize: MainAxisSize.min, children: [
                          const Icon(Icons.check_circle, color: Colors.white, size: 14),
                          const SizedBox(width: 4),
                          Text('Hoàn thành', style: GoogleFonts.outfit(color: Colors.white, fontWeight: FontWeight.w700, fontSize: 12)),
                        ]),
                      ),
                    ],
                  ]),
                  const SizedBox(height: 14),
                  Text(skill['title'] ?? '',
                    style: GoogleFonts.outfit(fontSize: 24, fontWeight: FontWeight.w800, height: 1.3, color: const Color(0xFF1E1B4B))),
                  const SizedBox(height: 12),
                  Row(children: [
                    Icon(Icons.timer_outlined, color: Colors.grey.shade500, size: 18),
                    const SizedBox(width: 6),
                    Text('${skill['duration_minutes'] ?? 5} phút học',
                      style: GoogleFonts.outfit(color: Colors.grey.shade600, fontWeight: FontWeight.w500)),
                    const SizedBox(width: 16),
                    const Icon(Icons.star_rounded, color: Color(0xFFFBBF24), size: 18),
                    const SizedBox(width: 4),
                    Text('+5 XP khi hoàn thành', style: GoogleFonts.outfit(color: const Color(0xFFD97706), fontWeight: FontWeight.w600, fontSize: 13)),
                  ]),
                  const SizedBox(height: 20),
                  // Description box
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: const Color(0xFFF0F4FF),
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(color: const Color(0xFF4F46E5).withValues(alpha: 0.2)),
                    ),
                    child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
                      const Text('💡', style: TextStyle(fontSize: 20)),
                      const SizedBox(width: 10),
                      Expanded(child: Text(skill['description'] ?? '',
                        style: GoogleFonts.outfit(fontSize: 14, color: const Color(0xFF4F46E5), height: 1.5))),
                    ]),
                  ),
                  const SizedBox(height: 24),
                  Text('📖 Nội dung bài học',
                    style: GoogleFonts.outfit(fontSize: 19, fontWeight: FontWeight.w800, color: const Color(0xFF1E1B4B))),
                  const SizedBox(height: 12),
                  // Content paragraphs
                  ...(skill['content'] ?? '').toString().split('\n').where((l) => l.trim().isNotEmpty).map((line) =>
                    Padding(
                      padding: const EdgeInsets.only(bottom: 12),
                      child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
                        Container(
                          margin: const EdgeInsets.only(top: 6),
                          width: 6, height: 6,
                          decoration: const BoxDecoration(color: Color(0xFF4F46E5), shape: BoxShape.circle),
                        ),
                        const SizedBox(width: 10),
                        Expanded(child: Text(line.trim(),
                          style: GoogleFonts.outfit(fontSize: 15, height: 1.6, color: Colors.grey.shade800))),
                      ]),
                    ),
                  ),

                  // Related
                  const SizedBox(height: 24),
                  Container(
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: const Color(0xFFFFF7ED),
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(color: const Color(0xFFFBBF24).withValues(alpha: 0.4)),
                    ),
                    child: Row(children: [
                      const Text('🔗', style: TextStyle(fontSize: 20)),
                      const SizedBox(width: 10),
                      Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                        Text('Tiếp theo: Chia sẻ cộng đồng', style: GoogleFonts.outfit(fontWeight: FontWeight.w700, color: const Color(0xFFD97706))),
                        Text('Thảo luận về kỹ năng này với cộng đồng', style: GoogleFonts.outfit(fontSize: 12, color: Colors.grey.shade600)),
                      ])),
                      Icon(Icons.arrow_forward_ios, size: 14, color: const Color(0xFFD97706)),
                    ]),
                  ),

                  const SizedBox(height: 28),
                  _checkingComplete
                      ? const Center(child: CircularProgressIndicator())
                      : _isCompleted
                          ? Container(
                              width: double.infinity,
                              padding: const EdgeInsets.symmetric(vertical: 14),
                              decoration: BoxDecoration(color: const Color(0xFF059669).withValues(alpha: 0.1), borderRadius: BorderRadius.circular(14), border: Border.all(color: const Color(0xFF059669).withValues(alpha: 0.4))),
                              child: Row(mainAxisAlignment: MainAxisAlignment.center, children: [
                                const Icon(Icons.check_circle, color: Color(0xFF059669)),
                                const SizedBox(width: 8),
                                Text('Đã hoàn thành kỹ năng này!', style: GoogleFonts.outfit(color: const Color(0xFF059669), fontWeight: FontWeight.w700, fontSize: 15)),
                              ]),
                            )
                          : SizedBox(
                              width: double.infinity,
                              child: ElevatedButton(
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: const Color(0xFF4F46E5),
                                  minimumSize: const Size(double.infinity, 52),
                                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                                ),
                                onPressed: _markComplete,
                                child: Text('✅ ĐÁNH DẤU HOÀN THÀNH  (+5 XP)',
                                  style: GoogleFonts.outfit(fontSize: 14, fontWeight: FontWeight.w800)),
                              ),
                            ),
                  const SizedBox(height: 40),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
