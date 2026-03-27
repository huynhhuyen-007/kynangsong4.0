import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../widgets/app_scaffold.dart';

class FunScreen extends StatelessWidget {
  const FunScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return AppScaffold(
      title: 'Vui Học',
      currentIndex: 3,
      body: SingleChildScrollView(
        child: Column(children: [_hero(), _activities(context), _parentTip()]),
      ),
    );
  }

  Widget _hero() {
    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          colors: [Color(0xFFDB2777), Color(0xFFEC4899)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      padding: const EdgeInsets.fromLTRB(24, 40, 24, 40),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text('VUI HỌC', style: GoogleFonts.outfit(color: Colors.white70, fontSize: 12, fontWeight: FontWeight.w700, letterSpacing: 1.5)),
        const SizedBox(height: 8),
        Text('Học nhẹ nhàng như chơi', style: GoogleFonts.outfit(color: Colors.white, fontSize: 26, fontWeight: FontWeight.w800)),
        const SizedBox(height: 10),
        Text('Bộ hoạt động ngắn theo chủ đề: tranh – câu đố – mini game giúp việc học trở nên thú vị hơn.',
            style: GoogleFonts.outfit(color: Colors.white70, fontSize: 14, height: 1.6)),
        const SizedBox(height: 20),
        Wrap(spacing: 8, runSpacing: 8, children: [
          _pill('🧠 Câu đố tư duy'),
          _pill('🎨 Tranh & kể chuyện'),
          _pill('🏆 Điểm thưởng'),
        ]),
      ]),
    );
  }

  Widget _pill(String t) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(color: Colors.white.withValues(alpha: 0.2), borderRadius: BorderRadius.circular(20)),
        child: Text(t, style: GoogleFonts.outfit(color: Colors.white, fontSize: 13)),
      );

  Widget _activities(BuildContext context) {
    final acts = [
      ('Đố vui "tình huống"', 'Chọn cách xử lý phù hợp trong các tình huống đời sống.', '🎭'),
      ('Ghép đôi cảm xúc', 'Ghép gương mặt – cảm xúc – hành động tích cực.', '😊'),
      ('Kể chuyện 3 khung', 'Viết câu chuyện ngắn về việc làm tốt mỗi ngày.', '📖'),
    ];
    return Padding(
      padding: const EdgeInsets.all(20),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text('Hoạt động nổi bật', style: GoogleFonts.outfit(fontSize: 20, fontWeight: FontWeight.w700, color: const Color(0xFF1E1B4B))),
        const SizedBox(height: 6),
        Text('Chọn một hoạt động để bắt đầu.', style: GoogleFonts.outfit(color: Colors.grey.shade600, fontSize: 14)),
        const SizedBox(height: 16),
        ...acts.map((a) => _actCard(context, a.$1, a.$2, a.$3)),
      ]),
    );
  }

  Widget _actCard(BuildContext context, String title, String desc, String emoji) {
    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white, borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFFCE7F3)),
        boxShadow: [BoxShadow(color: const Color(0xFFDB2777).withValues(alpha: 0.07), blurRadius: 10, offset: const Offset(0, 4))],
      ),
      child: Row(children: [
        Text(emoji, style: const TextStyle(fontSize: 32)),
        const SizedBox(width: 14),
        Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(title, style: GoogleFonts.outfit(fontWeight: FontWeight.w700, fontSize: 15, color: const Color(0xFF1E1B4B))),
          const SizedBox(height: 4),
          Text(desc, style: GoogleFonts.outfit(fontSize: 13, color: Colors.grey.shade600)),
          const SizedBox(height: 10),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFFDB2777), padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8), minimumSize: Size.zero),
            onPressed: () {
              showDialog(
                context: context,
                builder: (ctx) => AlertDialog(
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                  title: Text(title, style: GoogleFonts.outfit(fontWeight: FontWeight.w700)),
                  content: Text('Hoạt động đang được phát triển. Sắp ra mắt! 💡', style: GoogleFonts.outfit()),
                  actions: [
                    ElevatedButton(
                      onPressed: () => Navigator.pop(ctx),
                      child: Text('OK', style: GoogleFonts.outfit()),
                    ),
                  ],
                ),
              );
            },
            child: Text('Bắt đầu', style: GoogleFonts.outfit(fontSize: 13, fontWeight: FontWeight.w600)),
          ),
        ])),
      ]),
    );
  }

  Widget _parentTip() {
    return Container(
      margin: const EdgeInsets.fromLTRB(20, 0, 20, 24),
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: const LinearGradient(colors: [Color(0xFFFFF1F9), Color(0xFFFCE7F3)]),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFFFCE7F3)),
      ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text('💡 Gợi ý cho phụ huynh', style: GoogleFonts.outfit(fontWeight: FontWeight.w700, fontSize: 16, color: const Color(0xFF1E1B4B))),
        const SizedBox(height: 10),
        Text('Dành 10 phút mỗi tối hỏi con "Hôm nay con học được điều gì?" và "Con muốn thử làm điều gì tốt hơn?" — chỉ 2 câu hỏi nhưng tạo thói quen phản tư rất tốt.',
            style: GoogleFonts.outfit(color: Colors.grey.shade700, fontSize: 14, height: 1.6)),
        const SizedBox(height: 12),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
          decoration: BoxDecoration(color: const Color(0xFFDB2777), borderRadius: BorderRadius.circular(20)),
          child: Text('⏱ 10 phút mỗi ngày', style: GoogleFonts.outfit(color: Colors.white, fontSize: 13, fontWeight: FontWeight.w600)),
        ),
      ]),
    );
  }
}
