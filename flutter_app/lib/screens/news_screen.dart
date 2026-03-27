import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../widgets/app_scaffold.dart';

class NewsScreen extends StatefulWidget {
  const NewsScreen({super.key});

  @override
  State<NewsScreen> createState() => _NewsScreenState();
}

class _NewsScreenState extends State<NewsScreen> {
  final _emailCtrl = TextEditingController();

  @override
  void dispose() {
    _emailCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AppScaffold(
      title: 'Tin Tức',
      currentIndex: 4,
      body: SingleChildScrollView(
        child: Column(children: [_hero(), _articles(context), _eventsAndNewsletter(context)]),
      ),
    );
  }

  Widget _hero() {
    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          colors: [Color(0xFF0284C7), Color(0xFF38BDF8)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      padding: const EdgeInsets.fromLTRB(24, 40, 24, 40),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text('TIN TỨC', style: GoogleFonts.outfit(color: Colors.white70, fontSize: 12, fontWeight: FontWeight.w700, letterSpacing: 1.5)),
        const SizedBox(height: 8),
        Text('Bài viết & hoạt động mới', style: GoogleFonts.outfit(color: Colors.white, fontSize: 26, fontWeight: FontWeight.w800)),
        const SizedBox(height: 10),
        Text('Tổng hợp bài viết ngắn, mẹo thực hành và câu chuyện truyền cảm hứng về kỹ năng sống.',
            style: GoogleFonts.outfit(color: Colors.white70, fontSize: 14, height: 1.6)),
        const SizedBox(height: 20),
        Wrap(spacing: 8, runSpacing: 8, children: [
          _pill('📰 Cập nhật hằng tuần'),
          _pill('📚 Dễ áp dụng'),
          _pill('💬 Thảo luận'),
        ]),
      ]),
    );
  }

  Widget _pill(String t) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(color: Colors.white.withValues(alpha: 0.2), borderRadius: BorderRadius.circular(20)),
        child: Text(t, style: GoogleFonts.outfit(color: Colors.white, fontSize: 13)),
      );

  Widget _articles(BuildContext context) {
    final posts = [
      ('5 cách giúp con tự tin hơn', 'Những bước nhỏ để con dám nói, dám thử và dám sai.', '4 phút đọc', '🏷 Tự tin'),
      ('Khi con tức giận, làm gì?', 'Kỹ thuật "dừng – thở – nói" giúp hạ nhiệt nhanh.', '3 phút đọc', '🏷 Cảm xúc'),
      ('Thói quen 15 phút mỗi ngày', 'Biến mục tiêu lớn thành việc nhỏ và làm đều đặn.', '5 phút đọc', '🏷 Kỷ luật'),
    ];
    return Padding(
      padding: const EdgeInsets.all(20),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text('Bài viết nổi bật', style: GoogleFonts.outfit(fontSize: 20, fontWeight: FontWeight.w700, color: const Color(0xFF1E1B4B))),
        const SizedBox(height: 6),
        Text('Chọn bài viết để đọc nhanh.', style: GoogleFonts.outfit(color: Colors.grey.shade600, fontSize: 14)),
        const SizedBox(height: 16),
        ...posts.map((p) => _postCard(context, p.$1, p.$2, p.$3, p.$4)),
      ]),
    );
  }

  Widget _postCard(BuildContext context, String title, String desc, String time, String tag) {
    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white, borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE0F2FE)),
        boxShadow: [BoxShadow(color: const Color(0xFF0284C7).withValues(alpha: 0.07), blurRadius: 10, offset: const Offset(0, 4))],
      ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text(title, style: GoogleFonts.outfit(fontWeight: FontWeight.w700, fontSize: 15, color: const Color(0xFF1E1B4B))),
        const SizedBox(height: 6),
        Text(desc, style: GoogleFonts.outfit(fontSize: 13, color: Colors.grey.shade600)),
        const SizedBox(height: 10),
        Row(children: [
          _tag('⏱ $time'),
          const SizedBox(width: 8),
          _tag(tag),
          const Spacer(),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF0284C7), padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6), minimumSize: Size.zero),
            onPressed: () {
              showDialog(
                context: context,
                builder: (ctx) => AlertDialog(
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                  title: Text(title, style: GoogleFonts.outfit(fontWeight: FontWeight.w700)),
                  content: Text('Nội dung bài viết đang được cập nhật. Sắp có! 📰', style: GoogleFonts.outfit()),
                  actions: [
                    ElevatedButton(
                      onPressed: () => Navigator.pop(ctx),
                      child: Text('OK', style: GoogleFonts.outfit()),
                    ),
                  ],
                ),
              );
            },
            child: Text('Đọc bài', style: GoogleFonts.outfit(fontSize: 13, fontWeight: FontWeight.w600)),
          ),
        ]),
      ]),
    );
  }

  Widget _tag(String text) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
        decoration: BoxDecoration(color: const Color(0xFFE0F2FE), borderRadius: BorderRadius.circular(10)),
        child: Text(text, style: GoogleFonts.outfit(fontSize: 12, color: const Color(0xFF0284C7), fontWeight: FontWeight.w600)),
      );

  Widget _eventsAndNewsletter(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 0, 20, 24),
      child: Column(children: [
        Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16), border: Border.all(color: const Color(0xFFE0F2FE))),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text('📅 Sự kiện sắp tới', style: GoogleFonts.outfit(fontWeight: FontWeight.w700, fontSize: 16, color: const Color(0xFF1E1B4B))),
            const SizedBox(height: 12),
            ...[
              ('Chủ nhật', 'Workshop: Giao tiếp tích cực trong gia đình'),
              ('Thứ 4', 'Mini talk: Quản lý cảm xúc cho học sinh'),
              ('Thứ 7', 'Thử thách 7 ngày: Thói quen tốt'),
            ].map((e) => Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: Row(children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(color: const Color(0xFF0284C7), borderRadius: BorderRadius.circular(8)),
                  child: Text(e.$1, style: GoogleFonts.outfit(color: Colors.white, fontSize: 12, fontWeight: FontWeight.w700)),
                ),
                const SizedBox(width: 10),
                Expanded(child: Text(e.$2, style: GoogleFonts.outfit(fontSize: 13, color: Colors.grey.shade700))),
              ]),
            )),
          ]),
        ),
        const SizedBox(height: 16),
        Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            gradient: const LinearGradient(colors: [Color(0xFFF0F9FF), Color(0xFFE0F2FE)]),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: const Color(0xFFBAE6FD)),
          ),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text('📬 Đăng ký nhận bản tin', style: GoogleFonts.outfit(fontWeight: FontWeight.w700, fontSize: 16, color: const Color(0xFF1E1B4B))),
            const SizedBox(height: 6),
            Text('Nhận 1 mẹo nhỏ mỗi tuần qua email.', style: GoogleFonts.outfit(color: Colors.grey.shade600, fontSize: 14)),
            const SizedBox(height: 14),
            Row(children: [
              Expanded(
                child: TextField(
                  controller: _emailCtrl,
                  keyboardType: TextInputType.emailAddress,
                  decoration: InputDecoration(
                    hintText: 'Email của bạn',
                    hintStyle: GoogleFonts.outfit(fontSize: 14),
                    contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                    filled: true, fillColor: Colors.white,
                  ),
                ),
              ),
              const SizedBox(width: 10),
              ElevatedButton(
                style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF0284C7), padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14)),
                onPressed: () {
                  ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                    content: Text('Đăng ký thành công! 🎉', style: GoogleFonts.outfit()),
                    backgroundColor: const Color(0xFF0284C7),
                    behavior: SnackBarBehavior.floating,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ));
                },
                child: Text('Đăng ký', style: GoogleFonts.outfit(fontWeight: FontWeight.w600)),
              ),
            ]),
          ]),
        ),
      ]),
    );
  }
}
