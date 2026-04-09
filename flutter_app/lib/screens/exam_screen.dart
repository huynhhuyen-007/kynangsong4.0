import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:confetti/confetti.dart';
import '../utils/api_service.dart';
import '../utils/auth_manager.dart';

// ─── Mapping skill_tag → tên hiển thị và màu ─────────────────────────────────
const _skillTagInfo = {
  'communication':    {'label': 'Giao Tiếp',     'color': 0xFF3B82F6},
  'emotion':          {'label': 'Cảm Xúc',       'color': 0xFFF59E0B},
  'finance':          {'label': 'Tài Chính',     'color': 0xFF10B981},
  'critical_thinking':{'label': 'Tư Duy',        'color': 0xFF8B5CF6},
  'teamwork':         {'label': 'Làm Nhóm',      'color': 0xFFEC4899},
  'health':           {'label': 'Sức Khoẻ',      'color': 0xFF14B8A6},
};

// ─── ExamScreen ───────────────────────────────────────────────────────────────
class ExamScreen extends StatefulWidget {
  final int roundId;
  final String roundLabel;

  const ExamScreen({super.key, required this.roundId, required this.roundLabel});

  @override
  State<ExamScreen> createState() => _ExamScreenState();
}

class _ExamScreenState extends State<ExamScreen> with TickerProviderStateMixin {
  // ── State ──────────────────────────────────────────
  _ExamPhase _phase = _ExamPhase.loading;
  List<Map<String, dynamic>> _questions = [];
  int _currentIndex = 0;
  int? _selectedAnswer;
  final List<Map<String, dynamic>> _userAnswers = [];
  Map<String, dynamic>? _examResult;
  String? _errorMsg;

  // ── Phase 3: AI Recommendation State ───────────────
  bool _aiLoading = false;
  String? _aiAdvice;
  List<String> _weakSkills = [];
  List<String> _strongSkills = [];
  String? _userId;

  // ── Animations ─────────────────────────────────────
  late AnimationController _slideCtrl;
  late Animation<Offset> _slideAnim;
  late AnimationController _optionFadeCtrl;
  late AnimationController _progressCtrl;
  final ConfettiController _confettiCtrl = ConfettiController(duration: const Duration(seconds: 4));

  @override
  void initState() {
    super.initState();
    _slideCtrl = AnimationController(vsync: this, duration: const Duration(milliseconds: 400));
    _slideAnim = Tween<Offset>(begin: const Offset(0.3, 0), end: Offset.zero)
        .animate(CurvedAnimation(parent: _slideCtrl, curve: Curves.easeOutCubic));
    _optionFadeCtrl = AnimationController(vsync: this, duration: const Duration(milliseconds: 300));
    _progressCtrl = AnimationController(vsync: this, duration: const Duration(milliseconds: 600));
    _loadQuestions();
  }

  @override
  void dispose() {
    _slideCtrl.dispose();
    _optionFadeCtrl.dispose();
    _progressCtrl.dispose();
    _confettiCtrl.dispose();
    super.dispose();
  }

  // ── Data Loading ───────────────────────────────────
  Future<void> _loadQuestions() async {
    try {
      final list = await ApiService.getExamQuestions(widget.roundId);
      if (mounted) {
        setState(() {
          _questions = list.cast<Map<String, dynamic>>();
          _phase = _ExamPhase.quiz;
        });
        _slideCtrl.forward();
        _optionFadeCtrl.forward();
      }
    } catch (e) {
      if (mounted) setState(() { _phase = _ExamPhase.error; _errorMsg = e.toString(); });
    }
  }

  // ── Quiz Logic ─────────────────────────────────────
  void _selectAnswer(int index) {
    if (_selectedAnswer != null) return; // Đã chọn rồi thì khoá
    setState(() => _selectedAnswer = index);
  }

  Future<void> _nextQuestion() async {
    if (_selectedAnswer == null) return;
    final q = _questions[_currentIndex];
    _userAnswers.add({'question_id': q['id'], 'selected': _selectedAnswer});

    if (_currentIndex < _questions.length - 1) {
      // Chuyển câu tiếp
      _slideCtrl.reset();
      _optionFadeCtrl.reset();
      setState(() {
        _currentIndex++;
        _selectedAnswer = null;
      });
      _slideCtrl.forward();
      _optionFadeCtrl.forward();
    } else {
      // Nộp bài
      await _submitExam();
    }
  }

  Future<void> _submitExam() async {
    setState(() => _phase = _ExamPhase.submitting);
    try {
      final user = await AuthManager.getUser();
      _userId = user['id'] ?? 'unknown';
      final result = await ApiService.submitExam(
        userId: _userId!,
        roundId: widget.roundId,
        answers: _userAnswers,
      );
      if (mounted) {
        setState(() { _examResult = result; _phase = _ExamPhase.result; });
        if (result['passed'] == true) _confettiCtrl.play();
        // Phase 3: Tự động gọi AI recommend sau khi có kết quả
        _callAiRecommend(result);
      }
    } catch (e) {
      if (mounted) setState(() { _phase = _ExamPhase.error; _errorMsg = e.toString(); });
    }
  }

  // ── Phase 3: Gọi AI recommend-path ───────────────────
  Future<void> _callAiRecommend(Map<String, dynamic> result) async {
    if (!mounted) return;
    setState(() => _aiLoading = true);
    try {
      final rec = await ApiService.recommendPath(
        userId: _userId ?? 'unknown',
        roundId: widget.roundId,
        correctCount: result['correct_count'] as int? ?? 0,
        totalQuestions: result['total_questions'] as int? ?? 1,
        skillStats: (result['skill_stats'] as Map<String, dynamic>?) ?? {},
        passed: result['passed'] as bool? ?? false,
      );
      if (mounted) {
        setState(() {
          _aiAdvice = rec['advice'] as String?;
          _weakSkills = (rec['weak_skills'] as List? ?? []).cast<String>();
          _strongSkills = (rec['strong_skills'] as List? ?? []).cast<String>();
          _aiLoading = false;
        });
      }
    } catch (_) {
      if (mounted) setState(() => _aiLoading = false);
    }
  }

  // ── BUILD ──────────────────────────────────────────
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0F172A),
      body: Stack(
        children: [
          // Background gradient
          Positioned.fill(
            child: CustomPaint(painter: _ExamBgPainter()),
          ),
          SafeArea(
            child: _buildContent(),
          ),
          // Confetti
          Align(
            alignment: Alignment.topCenter,
            child: ConfettiWidget(
              confettiController: _confettiCtrl,
              blastDirectionality: BlastDirectionality.explosive,
              shouldLoop: false,
              colors: const [Color(0xFF10B981), Color(0xFF3B82F6), Color(0xFFF59E0B), Color(0xFF8B5CF6)],
              numberOfParticles: 60,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildContent() {
    switch (_phase) {
      case _ExamPhase.loading:
        return _buildLoading();
      case _ExamPhase.quiz:
        return _buildQuiz();
      case _ExamPhase.submitting:
        return _buildSubmitting();
      case _ExamPhase.result:
        return _buildResult();
      case _ExamPhase.error:
        return _buildError();
    }
  }

  // ── Loading ────────────────────────────────────────
  Widget _buildLoading() {
    return Center(
      child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
        const SizedBox(height: 32, width: 32,
          child: CircularProgressIndicator(color: Color(0xFF3B82F6), strokeWidth: 3)),
        const SizedBox(height: 20),
        Text('Đang tải câu hỏi...', style: GoogleFonts.outfit(color: Colors.white70, fontSize: 16)),
      ]),
    );
  }

  // ── Quiz ────────────────────────────────────────────
  Widget _buildQuiz() {
    final q = _questions[_currentIndex];
    final options = (q['options'] as List).cast<String>();
    final skillTag = q['skill_tag'] as String? ?? 'communication';
    final skillInfo = _skillTagInfo[skillTag] ?? {'label': skillTag, 'color': 0xFF3B82F6};
    final skillColor = Color(skillInfo['color'] as int);
    final progress = (_currentIndex + 1) / _questions.length;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _buildQuizHeader(progress, skillColor, skillInfo['label'] as String),
        Expanded(
          child: SlideTransition(
            position: _slideAnim,
            child: SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // Question card
                  Container(
                    padding: const EdgeInsets.all(24),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.05),
                      borderRadius: BorderRadius.circular(24),
                      border: Border.all(color: Colors.white.withValues(alpha: 0.1)),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(children: [
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                            decoration: BoxDecoration(
                              color: skillColor.withValues(alpha: 0.2),
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(color: skillColor.withValues(alpha: 0.5)),
                            ),
                            child: Text(skillInfo['label'] as String,
                              style: GoogleFonts.outfit(color: skillColor, fontSize: 11, fontWeight: FontWeight.w700)),
                          ),
                          const Spacer(),
                          Text('Câu ${_currentIndex + 1}/${_questions.length}',
                            style: GoogleFonts.outfit(color: Colors.white54, fontSize: 12)),
                        ]),
                        const SizedBox(height: 16),
                        Text(
                          q['content'] as String? ?? '',
                          style: GoogleFonts.outfit(
                            color: Colors.white,
                            fontSize: 17,
                            fontWeight: FontWeight.w600,
                            height: 1.5,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 20),

                  // Answer options
                  FadeTransition(
                    opacity: _optionFadeCtrl,
                    child: Column(
                      children: List.generate(options.length, (i) =>
                        _buildOptionTile(i, options[i], skillColor)),
                    ),
                  ),
                  const SizedBox(height: 24),

                  // Next button
                  AnimatedOpacity(
                    opacity: _selectedAnswer != null ? 1.0 : 0.3,
                    duration: const Duration(milliseconds: 300),
                    child: GestureDetector(
                      onTap: _selectedAnswer != null ? _nextQuestion : null,
                      child: Container(
                        padding: const EdgeInsets.symmetric(vertical: 18),
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: _selectedAnswer != null
                              ? [const Color(0xFF3B82F6), const Color(0xFF6D28D9)]
                              : [Colors.grey.shade700, Colors.grey.shade800],
                          ),
                          borderRadius: BorderRadius.circular(20),
                          boxShadow: _selectedAnswer != null ? [
                            BoxShadow(color: const Color(0xFF3B82F6).withValues(alpha: 0.4),
                              blurRadius: 20, offset: const Offset(0, 8))
                          ] : null,
                        ),
                        child: Center(
                          child: Text(
                            _currentIndex < _questions.length - 1 ? 'Câu tiếp theo →' : '🚀 Nộp bài',
                            style: GoogleFonts.outfit(
                              color: Colors.white,
                              fontWeight: FontWeight.w800,
                              fontSize: 17,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildQuizHeader(double progress, Color skillColor, String skillLabel) {
    return Container(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 12),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.03),
        border: Border(bottom: BorderSide(color: Colors.white.withValues(alpha: 0.08))),
      ),
      child: Column(children: [
        Row(children: [
          GestureDetector(
            onTap: () => _showExitConfirm(),
            child: Container(
              width: 40, height: 40,
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Icon(Icons.close_rounded, color: Colors.white70, size: 20),
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Text(
              'Vòng ${widget.roundId}: ${widget.roundLabel}',
              style: GoogleFonts.outfit(color: Colors.white, fontWeight: FontWeight.w700, fontSize: 15),
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ]),
        const SizedBox(height: 12),
        ClipRRect(
          borderRadius: BorderRadius.circular(6),
          child: LinearProgressIndicator(
            value: progress,
            backgroundColor: Colors.white.withValues(alpha: 0.1),
            valueColor: AlwaysStoppedAnimation<Color>(skillColor),
            minHeight: 6,
          ),
        ),
      ]),
    );
  }

  Widget _buildOptionTile(int index, String text, Color accentColor) {
    final isSelected = _selectedAnswer == index;
    final letters = ['A', 'B', 'C', 'D'];

    return GestureDetector(
      onTap: () => _selectAnswer(index),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
        decoration: BoxDecoration(
          color: isSelected
              ? accentColor.withValues(alpha: 0.15)
              : Colors.white.withValues(alpha: 0.04),
          borderRadius: BorderRadius.circular(18),
          border: Border.all(
            color: isSelected ? accentColor : Colors.white.withValues(alpha: 0.1),
            width: isSelected ? 2 : 1,
          ),
          boxShadow: isSelected ? [
            BoxShadow(color: accentColor.withValues(alpha: 0.3), blurRadius: 12, offset: const Offset(0, 4))
          ] : null,
        ),
        child: Row(children: [
          Container(
            width: 36, height: 36,
            decoration: BoxDecoration(
              color: isSelected ? accentColor : Colors.white.withValues(alpha: 0.08),
              shape: BoxShape.circle,
            ),
            child: Center(
              child: Text(
                letters[index],
                style: GoogleFonts.outfit(
                  color: isSelected ? Colors.white : Colors.white70,
                  fontWeight: FontWeight.w800, fontSize: 14,
                ),
              ),
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Text(
              text,
              style: GoogleFonts.outfit(
                color: isSelected ? Colors.white : Colors.white70,
                fontSize: 14.5,
                fontWeight: isSelected ? FontWeight.w600 : FontWeight.w400,
                height: 1.4,
              ),
            ),
          ),
          if (isSelected)
            const Icon(Icons.check_circle_rounded, color: Colors.white, size: 22),
        ]),
      ),
    );
  }

  // ── Submitting ─────────────────────────────────────
  Widget _buildSubmitting() {
    return Center(
      child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
        const SizedBox(height: 48, width: 48,
          child: CircularProgressIndicator(color: Color(0xFF8B5CF6), strokeWidth: 3)),
        const SizedBox(height: 24),
        Text('AI đang chấm bài...', style: GoogleFonts.outfit(color: Colors.white, fontSize: 18, fontWeight: FontWeight.w700)),
        const SizedBox(height: 8),
        Text('Phân tích kỹ năng của bạn', style: GoogleFonts.outfit(color: Colors.white54, fontSize: 14)),
      ]),
    );
  }

  // ── Result ─────────────────────────────────────────
  Widget _buildResult() {
    final result = _examResult!;
    final passed = result['passed'] as bool;
    final correct = result['correct_count'] as int;
    final total = result['total_questions'] as int;
    final points = result['points_earned'] as int;
    final skillStats = (result['skill_stats'] as Map<String, dynamic>?) ?? {};
    final results = (result['results'] as List? ?? []).cast<Map<String, dynamic>>();

    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(20, 20, 20, 40),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Header result card
          Container(
            padding: const EdgeInsets.all(28),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: passed
                  ? [const Color(0xFF065F46), const Color(0xFF10B981)]
                  : [const Color(0xFF7F1D1D), const Color(0xFFDC2626)],
                begin: Alignment.topLeft, end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(28),
              boxShadow: [
                BoxShadow(
                  color: (passed ? const Color(0xFF10B981) : const Color(0xFFDC2626)).withValues(alpha: 0.4),
                  blurRadius: 24, offset: const Offset(0, 8),
                )
              ],
            ),
            child: Column(children: [
              Text(passed ? '🏆' : '💪', style: const TextStyle(fontSize: 52)),
              const SizedBox(height: 12),
              Text(
                passed ? 'Xuất Sắc! Chinh phục thành công!' : 'Hãy thử lại lần nữa!',
                textAlign: TextAlign.center,
                style: GoogleFonts.outfit(color: Colors.white, fontSize: 20, fontWeight: FontWeight.w900),
              ),
              const SizedBox(height: 20),
              Row(mainAxisAlignment: MainAxisAlignment.spaceEvenly, children: [
                _resultStat('Đúng', '$correct/$total', Colors.white),
                _resultStat('Điểm', '+$points', const Color(0xFFFDE68A)),
                _resultStat('Kết quả', passed ? 'PASS ✅' : 'FAIL ❌', Colors.white),
              ]),
            ]),
          ),
          const SizedBox(height: 24),

          // Skill stats radar
          if (skillStats.isNotEmpty) ...[
            _sectionTitle('📊 Phân Tích Kỹ Năng'),
            const SizedBox(height: 12),
            ...skillStats.entries.where((e) => e.value > 0).map((e) {
              final info = _skillTagInfo[e.key];
              if (info == null) return const SizedBox.shrink();
              final color = Color(info['color'] as int);
              final val = (e.value as num).toDouble().clamp(0, 100);
              return Padding(
                padding: const EdgeInsets.only(bottom: 10),
                child: Row(children: [
                  SizedBox(width: 90,
                    child: Text(info['label'] as String,
                      style: GoogleFonts.outfit(color: Colors.white70, fontSize: 12, fontWeight: FontWeight.w600))),
                  Expanded(
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(6),
                      child: LinearProgressIndicator(
                        value: val / 100,
                        backgroundColor: Colors.white.withValues(alpha: 0.1),
                        valueColor: AlwaysStoppedAnimation<Color>(color),
                        minHeight: 8,
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Text('${val.toInt()}', style: GoogleFonts.outfit(color: color, fontSize: 12, fontWeight: FontWeight.w700)),
                ]),
              );
            }),
            const SizedBox(height: 24),
          ],

          // AI Owl Mentor Card (Phase 3)
          _buildAiMentorCard(),
          const SizedBox(height: 24),

          // Review answers
          _sectionTitle('📝 Xem Lại Câu Trả Lời'),
          const SizedBox(height: 12),
          ...results.asMap().entries.map((entry) => _buildReviewCard(entry.key + 1, entry.value)),

          const SizedBox(height: 32),

          // Action buttons
          ElevatedButton.icon(
            onPressed: () => Navigator.pop(context, result),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF3B82F6),
              minimumSize: const Size(double.infinity, 56),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
              elevation: 8, shadowColor: const Color(0xFF3B82F6).withValues(alpha: 0.4),
            ),
            icon: const Icon(Icons.map_rounded, color: Colors.white),
            label: Text('Về Bản Đồ', style: GoogleFonts.outfit(color: Colors.white, fontWeight: FontWeight.w800, fontSize: 16)),
          ),
          if (!passed) ...[
            const SizedBox(height: 12),
            OutlinedButton.icon(
              onPressed: () {
                setState(() {
                  _phase = _ExamPhase.loading;
                  _currentIndex = 0;
                  _selectedAnswer = null;
                  _userAnswers.clear();
                  _examResult = null;
                  _aiAdvice = null;
                  _aiLoading = false;
                });
                _loadQuestions();
              },
              style: OutlinedButton.styleFrom(
                minimumSize: const Size(double.infinity, 56),
                side: const BorderSide(color: Color(0xFF8B5CF6), width: 2),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
              ),
              icon: const Icon(Icons.refresh_rounded, color: Color(0xFF8B5CF6)),
              label: Text('Thử Lại', style: GoogleFonts.outfit(color: const Color(0xFF8B5CF6), fontWeight: FontWeight.w800, fontSize: 16)),
            ),
          ],
        ],
      ),
    );
  }

  Widget _resultStat(String label, String value, Color color) {
    return Column(children: [
      Text(value, style: GoogleFonts.outfit(color: color, fontWeight: FontWeight.w900, fontSize: 22)),
      const SizedBox(height: 4),
      Text(label, style: GoogleFonts.outfit(color: Colors.white70, fontSize: 12)),
    ]);
  }

  Widget _sectionTitle(String text) {
    return Text(text, style: GoogleFonts.outfit(color: Colors.white, fontWeight: FontWeight.w800, fontSize: 16));
  }

  // ── Phase 3: AI Mentor Card ──────────────────────────
  Widget _buildAiMentorCard() {
    return AnimatedSwitcher(
      duration: const Duration(milliseconds: 500),
      child: _aiLoading
        ? _buildAiLoadingCard()
        : _aiAdvice != null
          ? _buildAiAdviceCard()
          : const SizedBox.shrink(),
    );
  }

  Widget _buildAiLoadingCard() {
    return Container(
      key: const ValueKey('loading'),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [const Color(0xFF1E1B4B), const Color(0xFF312E81)],
          begin: Alignment.topLeft, end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: const Color(0xFF6D28D9).withValues(alpha: 0.5)),
        boxShadow: [
          BoxShadow(color: const Color(0xFF8B5CF6).withValues(alpha: 0.3), blurRadius: 20, offset: const Offset(0, 6))
        ],
      ),
      child: Row(children: [
        // Animated Owl
        Container(
          width: 52, height: 52,
          decoration: BoxDecoration(
            color: const Color(0xFF8B5CF6).withValues(alpha: 0.2),
            shape: BoxShape.circle,
          ),
          child: const Center(child: Text('🦉', style: TextStyle(fontSize: 28))),
        ),
        const SizedBox(width: 16),
        Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text('AI Mentor Owl đang phân tích...',
            style: GoogleFonts.outfit(color: Colors.white, fontWeight: FontWeight.w800, fontSize: 14)),
          const SizedBox(height: 8),
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(
              backgroundColor: Colors.white.withValues(alpha: 0.1),
              valueColor: const AlwaysStoppedAnimation<Color>(Color(0xFF8B5CF6)),
              minHeight: 4,
            ),
          ),
          const SizedBox(height: 6),
          Text('Đọc kết quả và chuẩn bị lời khuyên...', 
            style: GoogleFonts.outfit(color: Colors.white54, fontSize: 11)),
        ])),
      ]),
    );
  }

  Widget _buildAiAdviceCard() {
    return Container(
      key: const ValueKey('advice'),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [const Color(0xFF1E1B4B), const Color(0xFF312E81)],
          begin: Alignment.topLeft, end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: const Color(0xFF6D28D9).withValues(alpha: 0.6), width: 1.5),
        boxShadow: [
          BoxShadow(color: const Color(0xFF8B5CF6).withValues(alpha: 0.35), blurRadius: 24, offset: const Offset(0, 8))
        ],
      ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        // Header
        Row(children: [
          Container(
            width: 48, height: 48,
            decoration: BoxDecoration(
              gradient: const LinearGradient(colors: [Color(0xFF7C3AED), Color(0xFF4F46E5)]),
              shape: BoxShape.circle,
              boxShadow: [BoxShadow(color: const Color(0xFF8B5CF6).withValues(alpha: 0.5), blurRadius: 12)],
            ),
            child: const Center(child: Text('🦉', style: TextStyle(fontSize: 24))),
          ),
          const SizedBox(width: 14),
          Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text('AI Mentor Owl', style: GoogleFonts.outfit(
              color: Colors.white, fontWeight: FontWeight.w900, fontSize: 15)),
            Text('Phân tích cá nhân hóa', style: GoogleFonts.outfit(
              color: const Color(0xFFD8B4FE), fontSize: 11, fontWeight: FontWeight.w500)),
          ])),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(
              color: const Color(0xFF8B5CF6).withValues(alpha: 0.2),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: const Color(0xFF8B5CF6).withValues(alpha: 0.4)),
            ),
            child: Row(mainAxisSize: MainAxisSize.min, children: [
              const Icon(Icons.auto_awesome, color: Color(0xFFC4B5FD), size: 12),
              const SizedBox(width: 4),
              Text('AI', style: GoogleFonts.outfit(color: const Color(0xFFC4B5FD), fontSize: 10, fontWeight: FontWeight.w800)),
            ]),
          ),
        ]),
        const SizedBox(height: 16),
        // Divider
        Divider(color: Colors.white.withValues(alpha: 0.1), height: 1),
        const SizedBox(height: 16),
        // AI Advice text
        Text(
          _aiAdvice ?? '',
          style: GoogleFonts.outfit(
            color: Colors.white.withValues(alpha: 0.9),
            fontSize: 13.5,
            height: 1.7,
          ),
        ),
        // Skill tags
        if (_weakSkills.isNotEmpty || _strongSkills.isNotEmpty) ...[
          const SizedBox(height: 16),
          Wrap(spacing: 8, runSpacing: 6, children: [
            ..._strongSkills.map((s) => _skillChip(s, const Color(0xFF10B981), '💪')),
            ..._weakSkills.map((s) => _skillChip(s, const Color(0xFFEF4444), '🎯')),
          ]),
        ],
      ]),
    );
  }

  Widget _skillChip(String label, Color color, String icon) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withValues(alpha: 0.4)),
      ),
      child: Row(mainAxisSize: MainAxisSize.min, children: [
        Text(icon, style: const TextStyle(fontSize: 11)),
        const SizedBox(width: 4),
        Text(label, style: GoogleFonts.outfit(color: color, fontSize: 11, fontWeight: FontWeight.w700)),
      ]),
    );
  }

  Widget _buildReviewCard(int no, Map<String, dynamic> r) {
    final isCorrect = r['is_correct'] as bool;
    final selectedIndex = r['selected'] as int?;
    final correctIndex = r['correct_answer'] as int?;
    final options = ['A', 'B', 'C', 'D'];

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isCorrect
          ? const Color(0xFF10B981).withValues(alpha: 0.08)
          : const Color(0xFFEF4444).withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: isCorrect
            ? const Color(0xFF10B981).withValues(alpha: 0.4)
            : const Color(0xFFEF4444).withValues(alpha: 0.4),
        ),
      ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [
          Icon(isCorrect ? Icons.check_circle_rounded : Icons.cancel_rounded,
            color: isCorrect ? const Color(0xFF10B981) : const Color(0xFFEF4444), size: 20),
          const SizedBox(width: 8),
          Text('Câu $no', style: GoogleFonts.outfit(
            color: isCorrect ? const Color(0xFF10B981) : const Color(0xFFEF4444),
            fontWeight: FontWeight.w800, fontSize: 13)),
        ]),
        const SizedBox(height: 8),
        Text(r['content'] as String? ?? '', style: GoogleFonts.outfit(color: Colors.white70, fontSize: 13, height: 1.4)),
        const SizedBox(height: 8),
        if (!isCorrect && selectedIndex != null)
          Text('Bạn chọn: ${options[selectedIndex]}. ${_getOptionText(r, selectedIndex)}',
            style: GoogleFonts.outfit(color: const Color(0xFFEF4444), fontSize: 12)),
        if (correctIndex != null)
          Text('Đáp án đúng: ${options[correctIndex]}. ${_getOptionText(r, correctIndex)}',
            style: GoogleFonts.outfit(color: const Color(0xFF10B981), fontSize: 12, fontWeight: FontWeight.w700)),
        if ((r['explanation'] as String? ?? '').isNotEmpty) ...[
          const SizedBox(height: 6),
          Text('💡 ${r['explanation']}', style: GoogleFonts.outfit(color: Colors.white54, fontSize: 11.5, fontStyle: FontStyle.italic)),
        ],
      ]),
    );
  }

  String _getOptionText(Map<String, dynamic> r, int index) {
    // The backend returns the full option text as part of the review
    // We just show the content; if options aren't in result, show index
    return '(Đáp án ${'ABCD'[index]})';
  }

  // ── Error ──────────────────────────────────────────
  Widget _buildError() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
          const Text('😕', style: TextStyle(fontSize: 64)),
          const SizedBox(height: 20),
          Text('Lỗi tải dữ liệu', style: GoogleFonts.outfit(color: Colors.white, fontSize: 20, fontWeight: FontWeight.w800)),
          const SizedBox(height: 12),
          Text(_errorMsg ?? 'Không rõ lỗi', textAlign: TextAlign.center,
            style: GoogleFonts.outfit(color: Colors.white54, fontSize: 14, height: 1.5)),
          const SizedBox(height: 32),
          ElevatedButton.icon(
            onPressed: () { setState(() { _phase = _ExamPhase.loading; _errorMsg = null; }); _loadQuestions(); },
            style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF3B82F6), padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 14)),
            icon: const Icon(Icons.refresh_rounded, color: Colors.white),
            label: Text('Thử lại', style: GoogleFonts.outfit(color: Colors.white, fontWeight: FontWeight.w700)),
          ),
          const SizedBox(height: 12),
          TextButton(onPressed: () => Navigator.pop(context), child: Text('Quay lại', style: GoogleFonts.outfit(color: Colors.white54))),
        ]),
      ),
    );
  }

  // ── Helpers ────────────────────────────────────────
  Future<void> _showExitConfirm() async {
    final exit = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: const Color(0xFF1E293B),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text('Thoát bài thi?', style: GoogleFonts.outfit(color: Colors.white, fontWeight: FontWeight.w800)),
        content: Text('Tiến trình bài thi sẽ không được lưu.', style: GoogleFonts.outfit(color: Colors.white70)),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false),
            child: Text('Tiếp tục thi', style: GoogleFonts.outfit(color: const Color(0xFF3B82F6), fontWeight: FontWeight.w700))),
          TextButton(onPressed: () => Navigator.pop(ctx, true),
            child: Text('Thoát', style: GoogleFonts.outfit(color: const Color(0xFFEF4444), fontWeight: FontWeight.w700))),
        ],
      ),
    );
    if (exit == true && mounted) Navigator.pop(context);
  }
}

// ── Enums ────────────────────────────────────────────
enum _ExamPhase { loading, quiz, submitting, result, error }

// ── Background Painter ────────────────────────────────
class _ExamBgPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    // Deep dark background
    canvas.drawRect(Rect.fromLTWH(0, 0, size.width, size.height),
      Paint()..color = const Color(0xFF0F172A));

    // Subtle top-left glow
    final glow1 = Paint()
      ..shader = RadialGradient(
        colors: [const Color(0xFF3B82F6).withValues(alpha: 0.12), Colors.transparent],
      ).createShader(Rect.fromCircle(center: Offset(0, 0), radius: size.width * 0.7));
    canvas.drawRect(Rect.fromLTWH(0, 0, size.width, size.height), glow1);

    // Bottom-right purple glow
    final glow2 = Paint()
      ..shader = RadialGradient(
        colors: [const Color(0xFF8B5CF6).withValues(alpha: 0.10), Colors.transparent],
      ).createShader(Rect.fromCircle(center: Offset(size.width, size.height), radius: size.width * 0.8));
    canvas.drawRect(Rect.fromLTWH(0, 0, size.width, size.height), glow2);

    // Subtle grid
    final gridPaint = Paint()
      ..color = Colors.white.withValues(alpha: 0.02)
      ..style = PaintingStyle.stroke;
    for (double x = 0; x < size.width; x += 48) {
      canvas.drawLine(Offset(x, 0), Offset(x, size.height), gridPaint);
    }
    for (double y = 0; y < size.height; y += 48) {
      canvas.drawLine(Offset(0, y), Offset(size.width, y), gridPaint);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter _) => false;
}
