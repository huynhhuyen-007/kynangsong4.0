import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../widgets/app_scaffold.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return AppScaffold(
      title: 'Kỹ Năng Sống 4.0',
      currentIndex: 0,
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _heroSection(context),
            _statsBand(context),
            _skillPaths(context),
            _testimonial(context),
            _footer(context),
          ],
        ),
      ),
    );
  }

  Widget _heroSection(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          colors: [Color(0xFF4F46E5), Color(0xFF7C3AED)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      padding: const EdgeInsets.fromLTRB(24, 48, 24, 48),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.2),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Text(
              'Vui chơi · Rèn luyện · Học hỏi',
              style: GoogleFonts.outfit(color: Colors.white70, fontSize: 13),
            ),
          ),
          const SizedBox(height: 16),
          Text(
            'Khám phá kỹ năng sống\ncùng không gian học tập hiện đại',
            style: GoogleFonts.outfit(
              fontSize: 28,
              fontWeight: FontWeight.w800,
              color: Colors.white,
              height: 1.3,
            ),
          ),
          const SizedBox(height: 14),
          Text(
            'Một hành trình giúp các bạn nhỏ hình thành thói quen tích cực, '
            'biết quản lý cảm xúc, giao tiếp tự tin và chủ động trước những thay đổi của thời đại số.',
            style: GoogleFonts.outfit(
              color: Colors.white.withValues(alpha: 0.85),
              fontSize: 15,
              height: 1.6,
            ),
          ),
          const SizedBox(height: 24),
          Row(
            children: [
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.white,
                  foregroundColor: const Color(0xFF4F46E5),
                ),
                onPressed: () => Navigator.pushNamed(context, '/playground'),
                child: const Text('Học thử ngay'),
              ),
              const SizedBox(width: 12),
              OutlinedButton(
                style: OutlinedButton.styleFrom(
                  foregroundColor: Colors.white,
                  side: const BorderSide(color: Colors.white60),
                ),
                onPressed: () => Navigator.pushNamed(context, '/skills'),
                child: const Text('Tìm hiểu lộ trình'),
              ),
            ],
          ),
          const SizedBox(height: 20),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              _heroBubble('Xin chào! 👋'),
              _heroBubble('Cùng luyện kỹ năng nhé! 💪'),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            'Không yêu cầu kinh nghiệm · Bài học ngắn gọn · Áp dụng ngay',
            style: GoogleFonts.outfit(fontSize: 12, color: Colors.white60),
          ),
        ],
      ),
    );
  }

  Widget _heroBubble(String text) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.white30),
      ),
      child: Text(text, style: GoogleFonts.outfit(color: Colors.white, fontSize: 13)),
    );
  }

  Widget _statsBand(BuildContext context) {
    final stats = [
      ('+3.000', 'hoạt động', 'Bài học, câu hỏi, nhiệm vụ thực tế.'),
      ('+60', 'chủ đề', 'Từ giao tiếp đến quản lý cảm xúc.'),
      ('+90%', 'học sinh thích', 'Hứng thú với kỹ năng mềm mỗi ngày.'),
      ('+50', 'video', 'Tình huống gần gũi đời sống.'),
    ];
    return Container(
      color: const Color(0xFF1E1B4B),
      padding: const EdgeInsets.symmetric(vertical: 32, horizontal: 16),
      child: Column(
        children: [
          Text(
            'Tại sao nên chọn "Sân chơi Kỹ năng sống trực tuyến"?',
            textAlign: TextAlign.center,
            style: GoogleFonts.outfit(
              color: Colors.white, fontSize: 20, fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Hệ thống bài học được thiết kế dưới dạng trò chơi và thử thách.',
            textAlign: TextAlign.center,
            style: GoogleFonts.outfit(color: Colors.white60, fontSize: 14),
          ),
          const SizedBox(height: 24),
          GridView.count(
            crossAxisCount: 2,
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            crossAxisSpacing: 12,
            mainAxisSpacing: 12,
            childAspectRatio: 1.5,
            children: stats.map((s) => Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.07),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: Colors.white.withValues(alpha: 0.1)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(s.$1, style: GoogleFonts.outfit(color: const Color(0xFFA78BFA), fontSize: 22, fontWeight: FontWeight.w800)),
                  Text(s.$2, style: GoogleFonts.outfit(color: Colors.white, fontWeight: FontWeight.w600, fontSize: 13)),
                  Text(s.$3, style: GoogleFonts.outfit(color: Colors.white54, fontSize: 11)),
                ],
              ),
            )).toList(),
          ),
        ],
      ),
    );
  }

  Widget _skillPaths(BuildContext context) {
    final paths = [
      ('Chặng 1: Hiểu bản thân', 'Tìm hiểu cảm xúc, sở thích và điểm mạnh để tự tin hơn.',
        ['Nhật ký cảm xúc hàng ngày', 'Hoạt động "chiếc gương tích cực"', 'Nhận diện điều mình làm tốt'], '🧠'),
      ('Chặng 2: Giao tiếp & hợp tác', 'Biết lắng nghe, chia sẻ và làm việc nhóm hiệu quả.',
        ['Trò chơi luyện nói "cảm ơn" & "xin lỗi"', 'Đóng vai giải quyết mâu thuẫn', 'Nhiệm vụ làm việc nhóm nhỏ'], '🤝'),
      ('Chặng 3: Tự lập & kỷ luật', 'Xây dựng thói quen tốt và biết chịu trách nhiệm.',
        ['Bảng việc nhà mỗi ngày', 'Thử thách "15 phút tập trung"', 'Đánh giá lại một tuần đã qua'], '🏆'),
    ];
    return Padding(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Trau dồi kỹ năng qua các "chặng đường nhỏ"',
            style: GoogleFonts.outfit(fontSize: 20, fontWeight: FontWeight.w700, color: const Color(0xFF1E1B4B))),
          const SizedBox(height: 6),
          Text('Mỗi chặng là một nhóm kỹ năng với câu chuyện riêng.',
            style: GoogleFonts.outfit(color: Colors.grey.shade600, fontSize: 14)),
          const SizedBox(height: 20),
          ...paths.map((p) => _pathCard(context, p.$1, p.$2, p.$3, p.$4)),
        ],
      ),
    );
  }

  Widget _pathCard(BuildContext context, String title, String desc, List<String> items, String emoji) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE0E7FF)),
        boxShadow: [
          BoxShadow(color: const Color(0xFF4F46E5).withValues(alpha: 0.06), blurRadius: 12, offset: const Offset(0, 4)),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(children: [
            Text(emoji, style: const TextStyle(fontSize: 28)),
            const SizedBox(width: 12),
            Expanded(child: Text(title, style: GoogleFonts.outfit(fontWeight: FontWeight.w700, fontSize: 16, color: const Color(0xFF1E1B4B)))),
          ]),
          const SizedBox(height: 8),
          Text(desc, style: GoogleFonts.outfit(color: Colors.grey.shade600, fontSize: 13)),
          const SizedBox(height: 10),
          ...items.map((item) => Padding(
            padding: const EdgeInsets.only(bottom: 4),
            child: Row(children: [
              const Icon(Icons.check_circle_outline, size: 16, color: Color(0xFF4F46E5)),
              const SizedBox(width: 8),
              Text(item, style: GoogleFonts.outfit(fontSize: 13, color: Colors.grey.shade700)),
            ]),
          )),
          const SizedBox(height: 12),
          SizedBox(
            width: double.infinity,
            child: OutlinedButton(
              style: OutlinedButton.styleFrom(foregroundColor: const Color(0xFF4F46E5), side: const BorderSide(color: Color(0xFF4F46E5))),
              onPressed: () => Navigator.pushNamed(context, '/skills'),
              child: const Text('Xem chi tiết'),
            ),
          ),
        ],
      ),
    );
  }

  Widget _testimonial(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 20),
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: const LinearGradient(colors: [Color(0xFFEEF2FF), Color(0xFFF5F3FF)]),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFFE0E7FF)),
      ),
      child: Column(children: [
        const Text('⭐⭐⭐⭐⭐', style: TextStyle(fontSize: 22)),
        const SizedBox(height: 12),
        Text(
          '"Sau vài tuần tham gia, con biết chia sẻ cảm xúc của mình, chủ động giúp đỡ mọi người và thích thú với các thử thách nhỏ mỗi ngày."',
          textAlign: TextAlign.center,
          style: GoogleFonts.outfit(fontSize: 15, color: const Color(0xFF1E1B4B), fontStyle: FontStyle.italic, height: 1.6),
        ),
        const SizedBox(height: 12),
        Text('— Phụ huynh lớp 4, Hà Nội',
          style: GoogleFonts.outfit(color: Colors.grey.shade600, fontWeight: FontWeight.w600, fontSize: 13)),
        const SizedBox(height: 12),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          decoration: BoxDecoration(color: const Color(0xFF4F46E5), borderRadius: BorderRadius.circular(20)),
          child: Text('Hơn 5.000+ gia đình đã trải nghiệm',
            style: GoogleFonts.outfit(color: Colors.white, fontSize: 13, fontWeight: FontWeight.w600)),
        ),
      ]),
    );
  }

  Widget _footer(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(top: 32),
      padding: const EdgeInsets.all(24),
      color: const Color(0xFF1E1B4B),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Kỹ Năng Sống 4.0',
            style: GoogleFonts.outfit(color: Colors.white, fontWeight: FontWeight.w700, fontSize: 18)),
          const SizedBox(height: 6),
          Text('Đồng hành cùng gia đình trong hành trình nuôi dưỡng những công dân tự tin.',
            style: GoogleFonts.outfit(color: Colors.white60, fontSize: 13)),
          const SizedBox(height: 16),
          const Divider(color: Colors.white12),
          const SizedBox(height: 12),
          Row(children: [
            const Icon(Icons.email_outlined, color: Colors.white54, size: 16),
            const SizedBox(width: 8),
            Text('knsong@example.com', style: GoogleFonts.outfit(color: Colors.white54, fontSize: 13)),
          ]),
          const SizedBox(height: 6),
          Row(children: [
            const Icon(Icons.phone_outlined, color: Colors.white54, size: 16),
            const SizedBox(width: 8),
            Text('0123 456 789', style: GoogleFonts.outfit(color: Colors.white54, fontSize: 13)),
          ]),
          const SizedBox(height: 16),
          Text('© ${DateTime.now().year} Kỹ Năng Sống 4.0 · Học – chơi – lớn lên mỗi ngày',
            style: GoogleFonts.outfit(color: Colors.white38, fontSize: 12)),
        ],
      ),
    );
  }
}
