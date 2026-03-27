import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../widgets/app_scaffold.dart';

class PlaygroundScreen extends StatelessWidget {
  const PlaygroundScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return AppScaffold(
      title: 'Sân Chơi',
      currentIndex: 1,
      body: SingleChildScrollView(
        child: Column(children: [_hero(), _gameList(context), _progress()]),
      ),
    );
  }

  Widget _hero() {
    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          colors: [Color(0xFF059669), Color(0xFF10B981)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      padding: const EdgeInsets.fromLTRB(24, 40, 24, 40),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('SÂN CHƠI',
              style: GoogleFonts.outfit(
                  color: Colors.white70, fontSize: 12,
                  fontWeight: FontWeight.w700, letterSpacing: 1.5)),
          const SizedBox(height: 8),
          Text('Thử thách nhỏ mỗi ngày',
              style: GoogleFonts.outfit(
                  color: Colors.white, fontSize: 26, fontWeight: FontWeight.w800)),
          const SizedBox(height: 10),
          Text('Trò chơi ngắn – tình huống thực tế – nhiệm vụ vui nhộn giúp bạn rèn kỹ năng một cách tự nhiên.',
              style: GoogleFonts.outfit(color: Colors.white70, fontSize: 14, height: 1.6)),
          const SizedBox(height: 20),
          Wrap(spacing: 8, runSpacing: 8, children: [
            _pill('⏱ 5–10 phút'),
            _pill('🎯 Có điểm & huy hiệu'),
            _pill('👨‍👩‍👧‍👦 Chơi cùng gia đình'),
          ]),
        ],
      ),
    );
  }

  Widget _pill(String t) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.2),
            borderRadius: BorderRadius.circular(20)),
        child: Text(t, style: GoogleFonts.outfit(color: Colors.white, fontSize: 13)),
      );

  Widget _gameList(BuildContext context) {
    final games = [
      ('Vòng quay cảm xúc', 'Nhận diện cảm xúc và chọn cách phản ứng tích cực.', '🎯 Cảm xúc', '⏱ 7 phút', '⭐ Dễ'),
      ('Hộp thư "cảm ơn"', 'Luyện thói quen biết ơn và giao tiếp lịch sự.', '🎯 Giao tiếp', '⏱ 5 phút', '⭐ Dễ'),
      ('Giải cứu mâu thuẫn', 'Đóng vai tình huống và chọn phương án hòa giải.', '🎯 Hợp tác', '⏱ 10 phút', '⭐⭐ Vừa'),
    ];
    return Padding(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Chọn một trò chơi',
              style: GoogleFonts.outfit(fontSize: 20, fontWeight: FontWeight.w700, color: const Color(0xFF1E1B4B))),
          const SizedBox(height: 6),
          Text('Gợi ý theo độ tuổi và mục tiêu kỹ năng.',
              style: GoogleFonts.outfit(color: Colors.grey.shade600, fontSize: 14)),
          const SizedBox(height: 16),
          ...games.map((g) => _gameCard(context, g.$1, g.$2, g.$3, g.$4, g.$5)),
        ],
      ),
    );
  }

  Widget _gameCard(BuildContext context, String title, String desc, String t1, String t2, String t3) {
    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFD1FAE5)),
        boxShadow: [BoxShadow(color: const Color(0xFF059669).withValues(alpha: 0.07), blurRadius: 10, offset: const Offset(0, 4))],
      ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text(title, style: GoogleFonts.outfit(fontWeight: FontWeight.w700, fontSize: 16, color: const Color(0xFF1E1B4B))),
        const SizedBox(height: 6),
        Text(desc, style: GoogleFonts.outfit(color: Colors.grey.shade600, fontSize: 13)),
        const SizedBox(height: 12),
        Wrap(spacing: 8, children: [t1, t2, t3].map((t) => Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
          decoration: BoxDecoration(color: const Color(0xFFD1FAE5), borderRadius: BorderRadius.circular(10)),
          child: Text(t, style: GoogleFonts.outfit(color: const Color(0xFF059669), fontSize: 12, fontWeight: FontWeight.w600)),
        )).toList()),
        const SizedBox(height: 14),
        ElevatedButton(
          style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF059669), minimumSize: const Size(double.infinity, 40)),
          onPressed: () {
            showDialog(
              context: context,
              builder: (ctx) => AlertDialog(
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                title: Text(title, style: GoogleFonts.outfit(fontWeight: FontWeight.w700)),
                content: Text('Trò chơi đang được phát triển. Sắp ra mắt! 🚀', style: GoogleFonts.outfit()),
                actions: [
                  ElevatedButton(
                    onPressed: () => Navigator.pop(ctx),
                    child: Text('OK', style: GoogleFonts.outfit()),
                  ),
                ],
              ),
            );
          },
          child: Text('Chơi ngay', style: GoogleFonts.outfit(fontWeight: FontWeight.w600)),
        ),
      ]),
    );
  }

  Widget _progress() {
    final stats = [('3', 'Trò chơi\nhoàn thành'), ('1', 'Huy hiệu\ntuần này'), ('25', 'Điểm\nkỹ năng'), ('2', 'Ngày duy trì\nliên tiếp')];
    return Container(
      color: const Color(0xFFF0FDF4),
      padding: const EdgeInsets.all(20),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text('Tiến độ của bạn', style: GoogleFonts.outfit(fontSize: 18, fontWeight: FontWeight.w700, color: const Color(0xFF1E1B4B))),
        const SizedBox(height: 16),
        GridView.count(
          crossAxisCount: 2, shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          crossAxisSpacing: 12, mainAxisSpacing: 12, childAspectRatio: 2,
          children: stats.map((s) => Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(14), border: Border.all(color: const Color(0xFFD1FAE5))),
            child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
              Text(s.$1, style: GoogleFonts.outfit(fontSize: 24, fontWeight: FontWeight.w800, color: const Color(0xFF059669))),
              Text(s.$2, textAlign: TextAlign.center, style: GoogleFonts.outfit(fontSize: 12, color: Colors.grey.shade600, height: 1.3)),
            ]),
          )).toList(),
        ),
      ]),
    );
  }
}
