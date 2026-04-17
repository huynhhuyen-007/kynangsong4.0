import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:confetti/confetti.dart';
import '../utils/api_service.dart';
import '../utils/user_progress_manager.dart';

class LessonQuizScreen extends StatefulWidget {
  final Map<String, dynamic> lessonItem;
  final String userId;

  const LessonQuizScreen({super.key, required this.lessonItem, required this.userId});

  @override
  State<LessonQuizScreen> createState() => _LessonQuizScreenState();
}

class _LessonQuizScreenState extends State<LessonQuizScreen> {
  bool _isLoading = true;
  List<dynamic> _questions = [];
  Map<int, int> _selectedAnswers = {}; // questionIndex -> optionIndex
  bool _isSubmitted = false;
  Map<int, bool> _results = {}; // questionIndex -> isCorrect
  Map<int, String> _explanations = {};
  
  late ConfettiController _confettiController;
  int _pointsEarned = 0;

  @override
  void initState() {
    super.initState();
    _confettiController = ConfettiController(duration: const Duration(seconds: 3));
    _loadQuestions();
  }

  Future<void> _loadQuestions() async {
    try {
      final qs = await ApiService.getLessonQuiz(widget.lessonItem['id'].toString());
      if (mounted) {
        setState(() {
          _questions = qs;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _submitQuiz() async {
    if (_selectedAnswers.length < _questions.length) {
       ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Vui lòng chọn đủ đáp án')));
       return;
    }
    setState(() => _isLoading = true);
    
    List<Map<String, dynamic>> submitData = [];
    for (int i=0; i<_questions.length; i++) {
       submitData.add({
          "question_id": _questions[i]['id'],
          "selected": _selectedAnswers[i]
       });
    }

    try {
      final res = await ApiService.submitLessonQuiz(
        userId: widget.userId,
        lessonId: widget.lessonItem['id'].toString(),
        answers: submitData
      );
      
      final resultsData = res['results'] as List;
      for (int i=0; i<resultsData.length; i++) {
         _results[i] = resultsData[i]['is_correct'];
         _explanations[i] = resultsData[i]['explanation'] ?? '';
      }
      
      _pointsEarned = res['points_earned'] ?? 0;
      await UserProgressManager.addXp(_pointsEarned);

      setState(() {
         _isSubmitted = true;
         _isLoading = false;
      });
      
      if (_pointsEarned > 0) {
         _confettiController.play();
         _showXpPopup();
      }
      
    } catch (e) {
      if (mounted) {
         setState(() => _isLoading = false);
         ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.toString())));
      }
    }
  }
  
  void _showXpPopup() {
     showDialog(
       context: context,
       barrierDismissible: false,
       builder: (_) => Dialog(
         backgroundColor: Colors.transparent,
         elevation: 0,
         child: TweenAnimationBuilder<double>(
            tween: Tween(begin: 0.0, end: 1.0),
            duration: const Duration(milliseconds: 600),
            curve: Curves.elasticOut,
            builder: (ctx, val, child) {
               return Transform.scale(
                 scale: val,
                 child: child
               );
            },
            child: Container(
               padding: const EdgeInsets.all(24),
               decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(24),
                  boxShadow: [
                     BoxShadow(color: const Color(0xFFF59E0B).withOpacity(0.3), blurRadius: 30, spreadRadius: 10)
                  ]
               ),
               child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                     const Text('🏆', style: TextStyle(fontSize: 64)),
                     const SizedBox(height: 16),
                     Text('Xuất sắc!', style: GoogleFonts.outfit(fontSize: 24, fontWeight: FontWeight.w800, color: const Color(0xFFD97706))),
                     const SizedBox(height: 8),
                     Text('Bạn đã hoàn thành bài test', style: GoogleFonts.outfit(color: Colors.grey.shade600)),
                     const SizedBox(height: 16),
                     Container(
                        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                        decoration: BoxDecoration(
                           color: const Color(0xFFFEF3C7),
                           borderRadius: BorderRadius.circular(20),
                        ),
                        child: Text('+ $_pointsEarned XP', style: GoogleFonts.outfit(fontSize: 28, fontWeight: FontWeight.w900, color: const Color(0xFFD97706))),
                     ),
                     const SizedBox(height: 24),
                     ElevatedButton(
                        style: ElevatedButton.styleFrom(
                           backgroundColor: const Color(0xFF4F46E5),
                           minimumSize: const Size(double.infinity, 50),
                           shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                        ),
                        onPressed: () {
                           Navigator.pop(context);
                        },
                        child: Text('TIẾP TỤC', style: GoogleFonts.outfit(fontWeight: FontWeight.w800, color: Colors.white)),
                     )
                  ],
               )
            )
         )
       )
     );
  }

  @override
  void dispose() {
    _confettiController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading && _questions.isEmpty) {
       return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }
    
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: Text('Quiz: ${widget.lessonItem['title']}', style: GoogleFonts.outfit(fontWeight: FontWeight.w700)),
        backgroundColor: const Color(0xFF4F46E5),
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      body: Stack(
        children: [
          CustomScrollView(
            slivers: [
              SliverPadding(
                padding: const EdgeInsets.all(20),
                sliver: SliverList(
                  delegate: SliverChildBuilderDelegate(
                    (ctx, i) {
                      final q = _questions[i];
                      final opts = q['options'] as List;
                      final isCorrect = _results[i];
                      
                      return Container(
                        margin: const EdgeInsets.only(bottom: 24),
                        padding: const EdgeInsets.all(20),
                        decoration: BoxDecoration(
                           color: Colors.white,
                           borderRadius: BorderRadius.circular(16),
                           border: Border.all(color: Colors.grey.shade200),
                           boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.03), blurRadius: 10, offset: const Offset(0, 4))],
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                  decoration: BoxDecoration(color: const Color(0xFFEEF2FF), borderRadius: BorderRadius.circular(12)),
                                  child: Text('Câu ${i+1}', style: GoogleFonts.outfit(color: const Color(0xFF4F46E5), fontWeight: FontWeight.w800)),
                                ),
                                const Spacer(),
                                if (_isSubmitted)
                                   Icon(
                                      isCorrect == true ? Icons.check_circle : Icons.cancel,
                                      color: isCorrect == true ? const Color(0xFF059669) : const Color(0xFFDC2626),
                                   )
                              ],
                            ),
                            const SizedBox(height: 12),
                            Text(q['content'] ?? '', style: GoogleFonts.outfit(fontSize: 16, fontWeight: FontWeight.w600, color: const Color(0xFF1E1B4B))),
                            const SizedBox(height: 16),
                            for (int oi=0; oi<opts.length; oi++)
                               GestureDetector(
                                  onTap: () {
                                     if (!_isSubmitted) {
                                        setState(() => _selectedAnswers[i] = oi);
                                     }
                                  },
                                  child: Container(
                                     margin: const EdgeInsets.only(bottom: 10),
                                     padding: const EdgeInsets.all(14),
                                     decoration: BoxDecoration(
                                        color: _selectedAnswers[i] == oi ? const Color(0xFFEEF2FF) : Colors.white,
                                        borderRadius: BorderRadius.circular(12),
                                        border: Border.all(
                                           color: _selectedAnswers[i] == oi ? const Color(0xFF4F46E5) : Colors.grey.shade300,
                                           width: _selectedAnswers[i] == oi ? 2 : 1
                                        )
                                     ),
                                     child: Row(
                                        children: [
                                           Icon(
                                              _selectedAnswers[i] == oi ? Icons.radio_button_checked : Icons.radio_button_off,
                                              color: _selectedAnswers[i] == oi ? const Color(0xFF4F46E5) : Colors.grey.shade400,
                                              size: 20,
                                           ),
                                           const SizedBox(width: 12),
                                           Expanded(child: Text(opts[oi].toString(), style: GoogleFonts.outfit(fontSize: 15, color: Colors.grey.shade800))),
                                        ],
                                     ),
                                  ),
                               ),
                            if (_isSubmitted && _explanations[i] != null && _explanations[i]!.isNotEmpty)
                               Container(
                                  margin: EdgeInsets.only(top: 12),
                                  padding: const EdgeInsets.all(12),
                                  decoration: BoxDecoration(
                                     color: isCorrect == true ? const Color(0xFF059669).withOpacity(0.05) : const Color(0xFFDC2626).withOpacity(0.05),
                                     borderRadius: BorderRadius.circular(12),
                                     border: Border.all(color: isCorrect == true ? const Color(0xFF059669).withOpacity(0.2) : const Color(0xFFDC2626).withOpacity(0.2)),
                                  ),
                                  child: Row(
                                     crossAxisAlignment: CrossAxisAlignment.start,
                                     children: [
                                        Icon(Icons.lightbulb_outline, size: 18, color: isCorrect == true ? const Color(0xFF059669) : const Color(0xFFDC2626)),
                                        const SizedBox(width: 8),
                                        Expanded(child: Text(_explanations[i]!, style: GoogleFonts.outfit(fontSize: 14, color: Colors.grey.shade800))),
                                     ],
                                  ),
                               )
                          ],
                        )
                      );
                    },
                    childCount: _questions.length,
                  ),
                ),
              ),
              SliverToBoxAdapter(
                 child: Padding(
                    padding: const EdgeInsets.fromLTRB(20, 0, 20, 40),
                    child: _isSubmitted 
                       ? ElevatedButton(
                            style: ElevatedButton.styleFrom(
                               backgroundColor: Colors.white,
                               minimumSize: const Size(double.infinity, 56),
                               shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16), side: const BorderSide(color: Color(0xFF4F46E5), width: 2)),
                            ),
                            onPressed: () => Navigator.pop(context),
                            child: Text('Trở Về Kỹ Năng', style: GoogleFonts.outfit(fontSize: 15, fontWeight: FontWeight.w800, color: const Color(0xFF4F46E5))),
                         )
                       : ElevatedButton(
                            style: ElevatedButton.styleFrom(
                               backgroundColor: const Color(0xFF4F46E5),
                               minimumSize: const Size(double.infinity, 56),
                               shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                            ),
                            onPressed: _submitQuiz,
                            child: _isLoading 
                               ? const SizedBox(width: 24, height: 24, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                               : Text('NỘP BÀI KIỂM TRA', style: GoogleFonts.outfit(fontSize: 15, fontWeight: FontWeight.w800, color: Colors.white)),
                         ),
                 )
              )
            ],
          ),
          Align(
            alignment: Alignment.topCenter,
            child: ConfettiWidget(
              confettiController: _confettiController,
              blastDirectionality: BlastDirectionality.explosive,
              shouldLoop: false,
              colors: const [Colors.green, Colors.blue, Colors.pink, Colors.orange, Colors.purple],
            ),
          ),
        ],
      ),
    );
  }
}
