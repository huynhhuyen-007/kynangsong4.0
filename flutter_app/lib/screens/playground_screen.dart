import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../utils/user_progress_manager.dart';

class PlaygroundScreen extends StatefulWidget {
  const PlaygroundScreen({super.key});

  @override
  State<PlaygroundScreen> createState() => _PlaygroundScreenState();
}

class _PlaygroundScreenState extends State<PlaygroundScreen> {
  int _currentQuestion = 0;
  bool _isQuizActive = false;
  int? _selectedAnswer;
  bool _answered = false;
  int _score = 0;
  bool _quizFinished = false;

  final List<Map<String, dynamic>> _questions = [
    {
      'q': 'Khi bạn bất đồng quan điểm với đồng nghiệp, điều quan trọng nhất là?',
      'options': ['Im lặng để tránh xung đột', 'Lắng nghe và trao đổi bình tĩnh', 'Bảo vệ quan điểm của mình đến cùng', 'Nhờ sếp giải quyết ngay'],
      'correct': 1,
      'explain': 'Lắng nghe và trao đổi bình tĩnh giúp giải quyết mâu thuẫn một cách xây dựng và duy trì mối quan hệ tốt đẹp.',
    },
    {
      'q': 'Quy tắc 50/30/20 trong quản lý tài chính cá nhân có nghĩa là?',
      'options': ['50% tiết kiệm, 30% chi tiêu, 20% đầu tư', '50% nhu cầu, 30% mong muốn, 20% tiết kiệm', '50% đầu tư, 30% chi phí, 20% tiêu xài', '50% lương, 30% thưởng, 20% phụ cấp'],
      'correct': 1,
      'explain': '50% cho nhu cầu thiết yếu, 30% cho những điều mình muốn, 20% cho tiết kiệm/đầu tư – đây là công thức cân bằng tài chính phổ biến.',
    },
    {
      'q': 'Kỹ thuật Pomodoro giúp gì cho việc quản lý thời gian?',
      'options': ['Làm việc liên tục không nghỉ', 'Tập trung 25 phút rồi nghỉ 5 phút', 'Lên kế hoạch cho cả tuần', 'Họp nhóm hiệu quả hơn'],
      'correct': 1,
      'explain': 'Kỹ thuật Pomodoro giúp tập trung cao độ trong 25 phút, sau đó nghỉ ngơi 5 phút, giúp não bộ tươi tỉnh và tăng năng suất.',
    },
    {
      'q': 'Khi muốn nói "Không" với người khác mà không gây mất lòng, bạn nên?',
      'options': ['Luôn từ chối thẳng thắn không giải thích', 'Luôn đồng ý dù không muốn', 'Từ chối lịch sự và đưa ra lý do cụ thể', 'Hứa rồi sau đó bỏ quên'],
      'correct': 2,
      'explain': 'Từ chối lịch sự với lý do cụ thể là kỹ năng giao tiếp quan trọng giúp bạn giữ được sự tôn trọng của nhau.',
    },
    {
      'q': 'Để xây dựng thói quen tốt, theo nghiên cứu bạn cần duy trì bao nhiêu ngày?',
      'options': ['7 ngày', '21 ngày', '66 ngày', '100 ngày'],
      'correct': 2,
      'explain': 'Nghiên cứu của Philippa Lally (UCL) cho thấy trung bình cần ~66 ngày để một hành vi trở thành thói quen tự động.',
    },
  ];

  void _startQuiz() {
    setState(() {
      _isQuizActive = true;
      _currentQuestion = 0;
      _selectedAnswer = null;
      _answered = false;
      _score = 0;
      _quizFinished = false;
    });
  }

  void _selectAnswer(int idx) {
    if (_answered) return;
    setState(() {
      _selectedAnswer = idx;
      _answered = true;
      if (idx == _questions[_currentQuestion]['correct']) _score++;
    });
  }

  void _nextQuestion() {
    if (_currentQuestion < _questions.length - 1) {
      setState(() {
        _currentQuestion++;
        _selectedAnswer = null;
        _answered = false;
      });
    } else {
      _finishQuiz();
    }
  }

  Future<void> _finishQuiz() async {
    final xp = _score * 3;
    await UserProgressManager.addXp(xp);
    setState(() => _quizFinished = true);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Row(children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(8)),
            child: Text('KNS', style: GoogleFonts.outfit(fontWeight: FontWeight.w800, color: const Color(0xFF059669), fontSize: 14)),
          ),
          const SizedBox(width: 10),
          Text('Sân Chơi', style: GoogleFonts.outfit(fontWeight: FontWeight.w700, color: Colors.white)),
        ]),
        backgroundColor: const Color(0xFF059669),
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      body: _isQuizActive ? _buildQuiz() : _buildHome(),
    );
  }

  Widget _buildHome() {
    return SingleChildScrollView(
      child: Column(children: [
        _buildHero(),
        _buildDailyChallenge(),
        _buildGameCards(),
        _buildProgress(),
      ]),
    );
  }

  Widget _buildHero() {
    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(colors: [Color(0xFF059669), Color(0xFF10B981)], begin: Alignment.topLeft, end: Alignment.bottomRight),
      ),
      padding: const EdgeInsets.fromLTRB(24, 32, 24, 32),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text('SÂN CHƠI', style: GoogleFonts.outfit(color: Colors.white70, fontSize: 12, fontWeight: FontWeight.w700, letterSpacing: 1.5)),
        const SizedBox(height: 8),
        Text('Học qua trò chơi', style: GoogleFonts.outfit(color: Colors.white, fontSize: 26, fontWeight: FontWeight.w800)),
        const SizedBox(height: 10),
        Text('Quiz kỹ năng sống · Mini game · Daily challenge', style: GoogleFonts.outfit(color: Colors.white70, fontSize: 14, height: 1.6)),
        const SizedBox(height: 20),
        Wrap(spacing: 8, runSpacing: 8, children: [
          _pill('⏱ 5–10 phút'),
          _pill('🎯 +XP mỗi câu đúng'),
          _pill('🏆 Bảng xếp hạng'),
        ]),
      ]),
    );
  }

  Widget _pill(String t) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
    decoration: BoxDecoration(color: Colors.white.withValues(alpha: 0.2), borderRadius: BorderRadius.circular(20)),
    child: Text(t, style: GoogleFonts.outfit(color: Colors.white, fontSize: 13)),
  );

  Widget _buildDailyChallenge() {
    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        gradient: const LinearGradient(colors: [Color(0xFFFFF7ED), Color(0xFFFFFBEB)]),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: const Color(0xFFFBBF24).withValues(alpha: 0.4)),
      ),
      child: Row(children: [
        const Text('🌟', style: TextStyle(fontSize: 36)),
        const SizedBox(width: 14),
        Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text('Thử thách hôm nay', style: GoogleFonts.outfit(fontWeight: FontWeight.w800, color: const Color(0xFFD97706), fontSize: 14)),
          const SizedBox(height: 4),
          Text('Quiz 5 câu kỹ năng sống\n+3 XP mỗi câu đúng', style: GoogleFonts.outfit(color: Colors.grey.shade700, fontSize: 13, height: 1.4)),
        ])),
        ElevatedButton(
          style: ElevatedButton.styleFrom(
            backgroundColor: const Color(0xFFD97706),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
          ),
          onPressed: _startQuiz,
          child: Text('Bắt đầu', style: GoogleFonts.outfit(fontWeight: FontWeight.w700, fontSize: 13)),
        ),
      ]),
    );
  }

  Widget _buildGameCards() {
    final games = [
      {'title': '🎯 Vòng quay cảm xúc', 'desc': 'Nhận diện cảm xúc và chọn cách phản ứng tích cực', 'time': '7 phút', 'xp': '+10 XP'},
      {'title': '💬 Hộp thư cảm ơn', 'desc': 'Luyện thói quen biết ơn và giao tiếp lịch sự', 'time': '5 phút', 'xp': '+8 XP'},
      {'title': '🤝 Giải cứu mâu thuẫn', 'desc': 'Đóng vai tình huống xử lý xung đột thực tế', 'time': '10 phút', 'xp': '+12 XP'},
    ];
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text('🎮 Mini Games', style: GoogleFonts.outfit(fontSize: 18, fontWeight: FontWeight.w800, color: const Color(0xFF1E1B4B))),
        const SizedBox(height: 4),
        Text('Sắp ra mắt – đang phát triển', style: GoogleFonts.outfit(color: Colors.grey.shade500, fontSize: 12)),
        const SizedBox(height: 12),
        ...games.map((g) => _gameCard(g)),
      ]),
    );
  }

  Widget _gameCard(Map<String, dynamic> g) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFD1FAE5)),
        boxShadow: [BoxShadow(color: const Color(0xFF059669).withValues(alpha: 0.07), blurRadius: 10, offset: const Offset(0, 4))],
      ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text(g['title'] as String, style: GoogleFonts.outfit(fontWeight: FontWeight.w800, fontSize: 15)),
        const SizedBox(height: 4),
        Text(g['desc'] as String, style: GoogleFonts.outfit(color: Colors.grey.shade600, fontSize: 13)),
        const SizedBox(height: 10),
        Row(children: [
          _chip('⏱ ${g['time']}'), const SizedBox(width: 8), _chip('⚡ ${g['xp']}'),
          const Spacer(),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(color: const Color(0xFF059669).withValues(alpha: 0.1), borderRadius: BorderRadius.circular(10)),
            child: Text('🚀 Sắp ra mắt', style: GoogleFonts.outfit(color: const Color(0xFF059669), fontWeight: FontWeight.w700, fontSize: 12)),
          ),
        ]),
      ]),
    );
  }

  Widget _chip(String t) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
    decoration: BoxDecoration(color: const Color(0xFFD1FAE5), borderRadius: BorderRadius.circular(10)),
    child: Text(t, style: GoogleFonts.outfit(color: const Color(0xFF059669), fontSize: 12, fontWeight: FontWeight.w600)),
  );

  Widget _buildProgress() {
    return FutureBuilder<Map<String, dynamic>>(
      future: UserProgressManager.getSummary(),
      builder: (context, snapshot) {
        final data = snapshot.data ?? {};
        final xp = data['xp'] ?? 0;
        final streak = data['streak'] ?? 0;
        final completed = data['completedSkills'] ?? 0;
        return Container(
          margin: const EdgeInsets.fromLTRB(16, 16, 16, 24),
          padding: const EdgeInsets.all(18),
          decoration: BoxDecoration(
            color: const Color(0xFFF0FDF4),
            borderRadius: BorderRadius.circular(18),
            border: Border.all(color: const Color(0xFFD1FAE5)),
          ),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text('📊 Tiến độ của bạn', style: GoogleFonts.outfit(fontSize: 16, fontWeight: FontWeight.w800, color: const Color(0xFF1E1B4B))),
            const SizedBox(height: 14),
            Row(children: [
              _progressStat('⚡', '$xp', 'XP'),
              _progressStat('🔥', '$streak', 'Ngày streak'),
              _progressStat('📚', '$completed', 'KN hoàn thành'),
            ]),
          ]),
        );
      },
    );
  }

  Widget _progressStat(String emoji, String val, String label) {
    return Expanded(child: Column(children: [
      Text(emoji, style: const TextStyle(fontSize: 24)),
      Text(val, style: GoogleFonts.outfit(fontSize: 22, fontWeight: FontWeight.w800, color: const Color(0xFF059669))),
      Text(label, textAlign: TextAlign.center, style: GoogleFonts.outfit(fontSize: 11, color: Colors.grey.shade600, height: 1.3)),
    ]));
  }

  // ─────── QUIZ ────────────────────────────────────────────────────────────────

  Widget _buildQuiz() {
    if (_quizFinished) return _buildResult();
    final q = _questions[_currentQuestion];
    final correct = q['correct'] as int;
    final options = q['options'] as List<String>;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        // Progress bar
        Row(children: [
          Expanded(
            child: ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: LinearProgressIndicator(
                value: (_currentQuestion + 1) / _questions.length,
                backgroundColor: const Color(0xFFD1FAE5),
                valueColor: const AlwaysStoppedAnimation<Color>(Color(0xFF059669)),
                minHeight: 10,
              ),
            ),
          ),
          const SizedBox(width: 12),
          Text('${_currentQuestion + 1}/${_questions.length}',
            style: GoogleFonts.outfit(fontWeight: FontWeight.w700, color: const Color(0xFF059669))),
        ]),
        const SizedBox(height: 8),
        Text('Điểm: $_score', style: GoogleFonts.outfit(color: Colors.grey.shade500, fontSize: 12)),
        const SizedBox(height: 20),

        // Question
        Container(
          padding: const EdgeInsets.all(18),
          decoration: BoxDecoration(
            gradient: const LinearGradient(colors: [Color(0xFF059669), Color(0xFF34D399)], begin: Alignment.topLeft, end: Alignment.bottomRight),
            borderRadius: BorderRadius.circular(18),
          ),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text('Câu ${_currentQuestion + 1}', style: GoogleFonts.outfit(color: Colors.white70, fontSize: 12, fontWeight: FontWeight.w600)),
            const SizedBox(height: 8),
            Text(q['q'] as String, style: GoogleFonts.outfit(color: Colors.white, fontSize: 17, fontWeight: FontWeight.w700, height: 1.4)),
          ]),
        ),
        const SizedBox(height: 20),

        // Options
        ...List.generate(options.length, (i) {
          Color? bg, border;
          if (_answered) {
            if (i == correct) { bg = const Color(0xFFDCFCE7); border = const Color(0xFF059669); }
            else if (i == _selectedAnswer) { bg = const Color(0xFFFEE2E2); border = Colors.red.shade400; }
          }
          return GestureDetector(
            onTap: () => _selectAnswer(i),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              margin: const EdgeInsets.only(bottom: 10),
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: bg ?? Colors.white,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(
                  color: border ?? (_selectedAnswer == i ? const Color(0xFF059669) : const Color(0xFFE2E8F0)),
                  width: border != null ? 2 : 1,
                ),
                boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.04), blurRadius: 6, offset: const Offset(0, 2))],
              ),
              child: Row(children: [
                Container(
                  width: 28, height: 28,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: _answered && i == correct
                        ? const Color(0xFF059669)
                        : (_answered && i == _selectedAnswer ? Colors.red.shade400 : const Color(0xFFF0F4FF)),
                  ),
                  child: Center(child: _answered && i == correct
                      ? const Icon(Icons.check, color: Colors.white, size: 16)
                      : _answered && i == _selectedAnswer
                          ? const Icon(Icons.close, color: Colors.white, size: 16)
                          : Text(['A','B','C','D'][i], style: GoogleFonts.outfit(color: const Color(0xFF4F46E5), fontWeight: FontWeight.w800, fontSize: 13)),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(child: Text(options[i], style: GoogleFonts.outfit(fontSize: 14, fontWeight: FontWeight.w600, height: 1.4))),
              ]),
            ),
          );
        }),

        // Explanation
        if (_answered) ...[
          const SizedBox(height: 8),
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: const Color(0xFFF0FDF4),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: const Color(0xFFD1FAE5)),
            ),
            child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
              const Text('💡', style: TextStyle(fontSize: 18)),
              const SizedBox(width: 8),
              Expanded(child: Text(q['explain'] as String,
                style: GoogleFonts.outfit(fontSize: 13, color: Colors.grey.shade700, height: 1.5))),
            ]),
          ),
          const SizedBox(height: 16),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF059669),
                minimumSize: const Size(double.infinity, 48),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
              ),
              onPressed: _nextQuestion,
              child: Text(
                _currentQuestion < _questions.length - 1 ? 'Câu tiếp theo →' : '🏁 Xem kết quả',
                style: GoogleFonts.outfit(fontWeight: FontWeight.w700, fontSize: 15),
              ),
            ),
          ),
        ],
      ]),
    );
  }

  Widget _buildResult() {
    final xp = _score * 3;
    final pct = (_score / _questions.length * 100).round();
    String emoji, msg;
    if (pct >= 80) { emoji = '🏆'; msg = 'Xuất sắc! Bạn rất giỏi!'; }
    else if (pct >= 60) { emoji = '🎉'; msg = 'Tốt lắm! Tiếp tục phát huy!'; }
    else { emoji = '💪'; msg = 'Cố gắng lên! Học thêm nhé!'; }

    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
          Text(emoji, style: const TextStyle(fontSize: 80)),
          const SizedBox(height: 16),
          Text(msg, style: GoogleFonts.outfit(fontSize: 22, fontWeight: FontWeight.w800, color: const Color(0xFF059669))),
          const SizedBox(height: 20),
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(20),
              boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.07), blurRadius: 14)],
            ),
            child: Row(mainAxisAlignment: MainAxisAlignment.spaceAround, children: [
              _resultStat('$_score/${_questions.length}', 'Câu đúng', const Color(0xFF059669)),
              _resultStat('$pct%', 'Tỷ lệ', const Color(0xFF4F46E5)),
              _resultStat('+$xp', 'XP', const Color(0xFFD97706)),
            ]),
          ),
          const SizedBox(height: 24),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF059669),
                minimumSize: const Size(double.infinity, 50),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
              ),
              onPressed: _startQuiz,
              child: Text('🔄 Chơi lại', style: GoogleFonts.outfit(fontWeight: FontWeight.w700, fontSize: 15)),
            ),
          ),
          const SizedBox(height: 12),
          TextButton(
            onPressed: () => setState(() => _isQuizActive = false),
            child: Text('Về trang chủ sân chơi', style: GoogleFonts.outfit(color: Colors.grey, fontWeight: FontWeight.w600)),
          ),
        ]),
      ),
    );
  }

  Widget _resultStat(String val, String label, Color color) {
    return Column(children: [
      Text(val, style: GoogleFonts.outfit(fontSize: 26, fontWeight: FontWeight.w800, color: color)),
      Text(label, style: GoogleFonts.outfit(fontSize: 12, color: Colors.grey.shade600)),
    ]);
  }
}
