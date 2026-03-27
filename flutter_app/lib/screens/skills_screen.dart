import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../widgets/app_scaffold.dart';

class SkillsScreen extends StatelessWidget {
  const SkillsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return AppScaffold(
      title: 'Kỹ Năng',
      currentIndex: 2,
      body: SingleChildScrollView(
        child: Column(children: [_hero(context), _skillCards(), _sampleExercise()]),
      ),
    );
  }

  Widget _hero(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          colors: [Color(0xFFD97706), Color(0xFFF59E0B)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      padding: const EdgeInsets.fromLTRB(24, 40, 24, 40),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text('KỸ NĂNG', style: GoogleFonts.outfit(color: Colors.white70, fontSize: 12, fontWeight: FontWeight.w700, letterSpacing: 1.5)),
        const SizedBox(height: 8),
        Text('Học theo nhóm kỹ năng', style: GoogleFonts.outfit(color: Colors.white, fontSize: 26, fontWeight: FontWeight.w800)),
        const SizedBox(height: 10),
        Text('Mỗi kỹ năng đi kèm ví dụ, bài tập nhỏ và checklist để bạn luyện tập ngay.',
            style: GoogleFonts.outfit(color: Colors.white70, fontSize: 14, height: 1.6)),
        const SizedBox(height: 20),
        Wrap(spacing: 8, runSpacing: 8, children: [
          _pill('📌 Checklist rõ ràng'),
          _pill('🧩 Bài tập ngắn'),
          _pill('🗓 Lộ trình 7 tuần'),
        ]),
        const SizedBox(height: 20),
        Row(children: [
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.white, foregroundColor: const Color(0xFFD97706)),
            onPressed: () => Navigator.pushNamed(context, '/home'),
            child: const Text('Bắt đầu từ cơ bản'),
          ),
          const SizedBox(width: 12),
          OutlinedButton(
            style: OutlinedButton.styleFrom(foregroundColor: Colors.white, side: const BorderSide(color: Colors.white60)),
            onPressed: () {
              ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                content: Text('Checklist sắp có! 📋', style: GoogleFonts.outfit()),
                behavior: SnackBarBehavior.floating,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ));
            },
            child: const Text('Tải checklist'),
          ),
        ]),
      ]),
    );
  }

  Widget _pill(String t) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(color: Colors.white.withValues(alpha: 0.2), borderRadius: BorderRadius.circular(20)),
        child: Text(t, style: GoogleFonts.outfit(color: Colors.white, fontSize: 13)),
      );

  Widget _skillCards() {
    final skills = [
      ('Giao tiếp', 'Lắng nghe – đặt câu hỏi – trình bày rõ ràng.',
          ['3 bước lắng nghe chủ động', 'Nói "không" lịch sự', 'Thuyết trình 1 phút'], '💬'),
      ('Quản lý cảm xúc', 'Nhận diện – gọi tên – điều chỉnh cảm xúc.',
          ['Bánh xe cảm xúc', 'Thở 4–4–6', 'Viết nhật ký 5 dòng'], '😌'),
      ('Kỷ luật & mục tiêu', 'Đặt mục tiêu nhỏ và duy trì đều đặn.',
          ['Mục tiêu SMART', 'To-do 3 việc quan trọng', 'Đánh giá tuần'], '🎯'),
    ];
    return Padding(
      padding: const EdgeInsets.all(20),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text('Danh mục nổi bật', style: GoogleFonts.outfit(fontSize: 20, fontWeight: FontWeight.w700, color: const Color(0xFF1E1B4B))),
        const SizedBox(height: 6),
        Text('Chọn một kỹ năng để xem nội dung gợi ý.', style: GoogleFonts.outfit(color: Colors.grey.shade600, fontSize: 14)),
        const SizedBox(height: 16),
        ...skills.map((s) => _skillCard(s.$1, s.$2, s.$3, s.$4)),
      ]),
    );
  }

  Widget _skillCard(String title, String desc, List<String> items, String emoji) {
    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white, borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFFEF3C7)),
        boxShadow: [BoxShadow(color: const Color(0xFFD97706).withValues(alpha: 0.07), blurRadius: 10, offset: const Offset(0, 4))],
      ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [
          Text(emoji, style: const TextStyle(fontSize: 26)),
          const SizedBox(width: 10),
          Text(title, style: GoogleFonts.outfit(fontWeight: FontWeight.w700, fontSize: 16, color: const Color(0xFF1E1B4B))),
        ]),
        const SizedBox(height: 6),
        Text(desc, style: GoogleFonts.outfit(color: Colors.grey.shade600, fontSize: 13)),
        const SizedBox(height: 10),
        ...items.map((i) => Padding(
          padding: const EdgeInsets.only(bottom: 4),
          child: Row(children: [
            const Icon(Icons.check_circle_outline, size: 16, color: Color(0xFFD97706)),
            const SizedBox(width: 8),
            Text(i, style: GoogleFonts.outfit(fontSize: 13, color: Colors.grey.shade700)),
          ]),
        )),
      ]),
    );
  }

  Widget _sampleExercise() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 0, 20, 24),
      child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Expanded(child: Container(
          padding: const EdgeInsets.all(18),
          decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16), border: Border.all(color: const Color(0xFFFEF3C7))),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text('Bài tập mẫu: "Một câu hỏi hay"', style: GoogleFonts.outfit(fontWeight: FontWeight.w700, fontSize: 15, color: const Color(0xFF1E1B4B))),
            const SizedBox(height: 8),
            Text('Hôm nay, hãy thử đặt 1 câu hỏi mở để hiểu người đối diện hơn.', style: GoogleFonts.outfit(fontSize: 13, color: Colors.grey.shade600)),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(color: const Color(0xFFFFF7ED), borderRadius: BorderRadius.circular(10)),
              child: Text('Gợi ý: "Điều gì làm bạn thấy vui nhất hôm nay?"',
                  style: GoogleFonts.outfit(fontSize: 13, color: const Color(0xFFD97706), fontStyle: FontStyle.italic)),
            ),
          ]),
        )),
        const SizedBox(width: 12),
        Expanded(child: Container(
          padding: const EdgeInsets.all(18),
          decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16), border: Border.all(color: const Color(0xFFFEF3C7))),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text('Checklist nhanh', style: GoogleFonts.outfit(fontWeight: FontWeight.w700, fontSize: 15, color: const Color(0xFF1E1B4B))),
            const SizedBox(height: 10),
            ...['Nhìn vào mắt khi nói chuyện', 'Không ngắt lời', 'Tóm tắt lại ý chính', 'Cảm ơn và phản hồi tích cực']
                .map((item) => Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: Row(children: [
                const Icon(Icons.check_box_outlined, size: 16, color: Color(0xFFD97706)),
                const SizedBox(width: 8),
                Expanded(child: Text(item, style: GoogleFonts.outfit(fontSize: 12, color: Colors.grey.shade700))),
              ]),
            )),
          ]),
        )),
      ]),
    );
  }
}
