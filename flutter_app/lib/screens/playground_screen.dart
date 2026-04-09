import 'dart:math' as math;
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../utils/user_progress_manager.dart';
import '../widgets/app_scaffold.dart';
import 'package:confetti/confetti.dart';
import '../utils/api_service.dart';
import '../utils/auth_manager.dart';
import 'exam_screen.dart';

// ─── CONFIG JSON-like cho map (dễ scale sau này) ─────────────────────────────
final List<Map<String, dynamic>> _mapNodes = [
  {'id': 1,  'x': 0.50, 'type': 'normal',   'label': 'Kỹ năng giao tiếp'},
  {'id': 2,  'x': 0.25, 'type': 'normal',   'label': 'Lắng nghe hiệu quả'},
  {'id': 3,  'x': 0.70, 'type': 'normal',   'label': 'Quản lý cảm xúc'},
  {'id': 4,  'x': 0.35, 'type': 'normal',   'label': 'Tư duy phản biện'},
  {'id': 5,  'x': 0.65, 'type': 'normal',   'label': 'Quản lý thời gian'},
  {'id': 6,  'x': 0.20, 'type': 'normal',   'label': 'Giải quyết vấn đề'},
  {'id': 7,  'x': 0.75, 'type': 'normal',   'label': 'Làm việc nhóm'},
  {'id': 8,  'x': 0.40, 'type': 'normal',   'label': 'Thuyết trình'},
  {'id': 9,  'x': 0.60, 'type': 'normal',   'label': 'Tài chính cá nhân'},
  {'id': 10, 'x': 0.30, 'type': 'normal',   'label': 'Sức khỏe & Thể chất'},
  {'id': 11, 'x': 0.65, 'type': 'normal',   'label': 'Kỹ năng học tập'},
  {'id': 12, 'x': 0.45, 'type': 'normal',   'label': 'Sáng tạo & Đổi mới'},
  {'id': 13, 'x': 0.25, 'type': 'school',   'label': 'Cấp Trường'},
  {'id': 14, 'x': 0.60, 'type': 'district', 'label': 'Cấp Huyện'},
  {'id': 15, 'x': 0.35, 'type': 'province', 'label': 'Cấp Tỉnh'},
  {'id': 16, 'x': 0.55, 'type': 'final',    'label': 'Quốc Gia 🏆'},
];

class PlaygroundScreen extends StatefulWidget {
  const PlaygroundScreen({super.key});
  @override
  State<PlaygroundScreen> createState() => _PlaygroundScreenState();
}

class _PlaygroundScreenState extends State<PlaygroundScreen>
    with TickerProviderStateMixin {
  int _currentRound = 1; // Sẽ load từ API
  bool _isLoadingExamProgress = true;
  Map<String, dynamic> _examProgress = {}; // Dữ liệu từ /api/exam/progress
  Map<String, dynamic> _progress = {};

  late AnimationController _pulseCtrl;
  late Animation<double> _pulseAnim;
  late AnimationController _pathFlowCtrl;
  late AnimationController _aiBadgePulseCtrl;
  final ConfettiController _confettiCtrl = ConfettiController(duration: const Duration(seconds: 3));

  @override
  void initState() {
    super.initState();
    // Animation viền đập nhịp nhàng cho Node đang chơi
    _pulseCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    )..repeat(reverse: true);
    _pulseAnim = Tween<double>(begin: 1.0, end: 1.15).animate(
      CurvedAnimation(parent: _pulseCtrl, curve: Curves.easeInOut),
    );

    // Animation cho nốt AI nổi lên xuống nhẹ
    _aiBadgePulseCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2000),
    )..repeat(reverse: true);

    // Animation dò dường Flowing Path
    _pathFlowCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 6000), // flowing chậm rãi
    )..repeat();

    _loadProgress();
    _loadExamProgress();
  }

  Future<void> _loadProgress() async {
    final p = await UserProgressManager.getSummary();
    if (mounted) setState(() => _progress = p);
  }

  Future<void> _loadExamProgress() async {
    try {
      final user = await AuthManager.getUser();
      final ep = await ApiService.getExamProgress(user['id'] ?? 'unknown');
      if (mounted) {
        setState(() {
          _examProgress = ep;
          _currentRound = ep['current_round'] as int? ?? 1;
          _isLoadingExamProgress = false;
        });
      }
    } catch (_) {
      // fallback: giữ nguyên _currentRound = 1
      if (mounted) setState(() => _isLoadingExamProgress = false);
    }
  }

  @override
  void dispose() {
    _pulseCtrl.dispose();
    _pathFlowCtrl.dispose();
    _aiBadgePulseCtrl.dispose();
    _confettiCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AppScaffold(
      title: 'Hành Trình Khám Phá',
      currentIndex: -1, // Không highlight ở Bottom Nav nữa
      body: Stack(
        children: [
          CustomScrollView(
            physics: const BouncingScrollPhysics(),
            slivers: [
              _buildStickyHeader(),
              SliverToBoxAdapter(child: _buildMap(context)),
            ],
          ),
          Align(
            alignment: Alignment.topCenter,
            child: ConfettiWidget(
              confettiController: _confettiCtrl,
              blastDirectionality: BlastDirectionality.explosive,
              shouldLoop: false,
              colors: const [Colors.green, Colors.blue, Colors.pink, Colors.orange, Colors.purple],
              maxBlastForce: 20,
              minBlastForce: 5,
              emissionFrequency: 0.05,
              numberOfParticles: 50,
            ),
          ),
        ],
      ),
    );
  }

  // ─── STICKY HEADER ────────────────────────────────────────────────────────
  Widget _buildStickyHeader() {
    final xp = _progress['xp'] ?? 0;
    final level = _progress['level'] ?? 1;
    final streak = _progress['streak'] ?? 0;
    final label = _progress['levelLabel'] ?? 'Người mới';

    return SliverPersistentHeader(
      pinned: true,
      delegate: _StickyDelegate(
        minH: 90,
        maxH: 90,
        child: ClipRRect(
          child: BackdropFilter(
            filter: ui.ImageFilter.blur(sigmaX: 10, sigmaY: 10),
            child: Container(
              decoration: BoxDecoration(
                color: const Color(0xFF0F172A).withValues(alpha: 0.7),
                border: Border(bottom: BorderSide(color: Colors.white.withValues(alpha: 0.1), width: 1)),
              ),
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    'Đảo Kỹ Năng',
                    style: GoogleFonts.outfit(
                      color: Colors.white,
                      fontSize: 18,
                      fontWeight: FontWeight.w900,
                      letterSpacing: 1.2,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                        decoration: BoxDecoration(color: const Color(0xFFF59E0B).withValues(alpha: 0.2), borderRadius: BorderRadius.circular(10), border: Border.all(color: const Color(0xFFF59E0B).withValues(alpha: 0.5))),
                        child: Text('🏆 Lv.$level $label', style: GoogleFonts.outfit(color: Colors.white, fontSize: 11, fontWeight: FontWeight.bold)),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text('Tiến trình XP', style: GoogleFonts.outfit(color: Colors.white70, fontSize: 10, fontWeight: FontWeight.w600)),
                                Text('$xp XP', style: GoogleFonts.outfit(color: const Color(0xFF10B981), fontSize: 10, fontWeight: FontWeight.w900)),
                              ],
                            ),
                            const SizedBox(height: 4),
                            ClipRRect(
                              borderRadius: BorderRadius.circular(4),
                              child: LinearProgressIndicator(
                                value: (xp % 50) / 50.0, // Giả lập progress tới mốc 50
                                backgroundColor: Colors.white.withValues(alpha: 0.2),
                                valueColor: const AlwaysStoppedAnimation<Color>(Color(0xFF10B981)),
                                minHeight: 6,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 10),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                        decoration: BoxDecoration(color: const Color(0xFFEF4444).withValues(alpha: 0.2), borderRadius: BorderRadius.circular(10), border: Border.all(color: const Color(0xFFEF4444).withValues(alpha: 0.5))),
                        child: Text('🔥 $streak Days', style: GoogleFonts.outfit(color: Colors.white, fontSize: 11, fontWeight: FontWeight.bold)),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _headerPill(String icon, String text, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.2),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withValues(alpha: 0.5)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(icon, style: const TextStyle(fontSize: 12)),
          const SizedBox(width: 4),
          Text(
            text,
            style: GoogleFonts.outfit(
              color: Colors.white,
              fontWeight: FontWeight.w700,
              fontSize: 11,
            ),
          ),
        ],
      ),
    );
  }

  // ─── MAP CONTENT ──────────────────────────────────────────────────────────
  Widget _buildMap(BuildContext context) {
    const double nodeSpacingH = 200.0; // Khoảng cách giữa các chặng rộng hơn
    final double mapHeight = _mapNodes.length * nodeSpacingH + 200;

    return LayoutBuilder(builder: (ctx, constraints) {
      final double w = constraints.maxWidth;

      List<Offset> positions = [];
      for (int i = 0; i < _mapNodes.length; i++) {
        double rawX = (_mapNodes[i]['x'] as double) * w;
        rawX = rawX.clamp(60.0, w - 60.0);
        // Map vẽ từ trên xuống dưới
        double dy = 120 + i * nodeSpacingH;
        positions.add(Offset(rawX, dy));
      }

      return SizedBox(
        width: w,
        height: mapHeight,
        child: Stack(clipBehavior: Clip.none, children: [
          // ── Nền phong cảnh đảo kỹ năng ──
          Positioned.fill(child: CustomPaint(painter: _DeepOceanBgPainter())),

          // ── Đường đi (với hiệu ứng Flowing) ──
          Positioned.fill(
            child: AnimatedBuilder(
              animation: _pathFlowCtrl,
              builder: (context, child) => CustomPaint(
                painter: _AdvancedPathPainter(
                  positions: positions,
                  currentRound: _currentRound,
                  flowValue: _pathFlowCtrl.value,
                ),
              ),
            ),
          ),

          // ── Nodes ──
          ...List.generate(_mapNodes.length, (i) {
            final node = _mapNodes[i];
            final pos = positions[i];
            final int id = node['id'] as int;
            final NodeState state = id < _currentRound
                ? NodeState.done
                : id == _currentRound
                    ? NodeState.active
                    : NodeState.locked;

            return Positioned(
              left: pos.dx - 45,
              top: pos.dy - 60,
              child: _NodeInteractiveWidget(
                node: node,
                state: state,
                pulseAnim: _pulseAnim,
                onTap: () => _onNodeTap(context, id, state, node['label'] as String),
              ),
            );
          }),

          // ── Nhãn "AI đề xuất" trên node đang active ──
          Builder(builder: (_) {
            if (_currentRound > _mapNodes.length) return const SizedBox.shrink();
            final pos = positions[_currentRound - 1];
            return Positioned(
              left: pos.dx - 30, // Chỉnh lại theo kích thước tooltip center
              top: pos.dy - 75,
              child: AnimatedBuilder(
                animation: _aiBadgePulseCtrl,
                builder: (_, child) => Transform.translate(
                  offset: Offset(0, -6 * _aiBadgePulseCtrl.value),
                  child: child,
                ),
                child: const _AiBadge(),
              ),
            );
          }),
        ]),
      );
    });
  }

  void _onNodeTap(BuildContext ctx, int id, NodeState state, String label) {
    if (state == NodeState.locked) {
      ScaffoldMessenger.of(ctx).showSnackBar(SnackBar(
        content: Row(children: [
          const Icon(Icons.lock, color: Colors.white, size: 20),
          const SizedBox(width: 8),
          const Text('Hoàn thành các vòng trước để mở khóa!'),
        ]),
        backgroundColor: const Color(0xFF334155),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ));
      return;
    }
    // Hiển thị BottomSheet thông tin vòng
    showModalBottomSheet(
      context: ctx,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (_) => _RoundBottomSheet(
        id: id, 
        label: label, 
        state: state,
        onStartOrReview: () async {
          Navigator.pop(ctx);
          // ── Navigate vào ExamScreen thật ──────────────────────────
          final result = await Navigator.push<Map<String, dynamic>>(
            context,
            MaterialPageRoute(
              builder: (_) => ExamScreen(roundId: id, roundLabel: label),
            ),
          );
          // result là kết quả chấm bài từ API
          if (result != null && mounted) {
            final newRound = result['new_round'] as int? ?? _currentRound;
            final passed = result['passed'] as bool? ?? false;
            setState(() {
              _currentRound = newRound;
              _examProgress = {
                ..._examProgress,
                'current_round': newRound,
                'skill_stats': result['skill_stats'] ?? _examProgress['skill_stats'],
              };
            });
            if (passed) {
              _confettiCtrl.play();
              if (mounted) {
                ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                  content: Text('🎉 Chinh phục chặng $id thành công! +${result["points_earned"]} điểm',
                    style: GoogleFonts.outfit(fontWeight: FontWeight.bold)),
                  backgroundColor: const Color(0xFF10B981),
                  behavior: SnackBarBehavior.floating,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                ));
              }
            } else if (mounted) {
              ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                content: Text('💪 Hãy ôn lại và thử lần nữa!',
                  style: GoogleFonts.outfit(fontWeight: FontWeight.bold)),
                backgroundColor: const Color(0xFF334155),
                behavior: SnackBarBehavior.floating,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              ));
            }
          }
        },
      ),
    );
  }
}

// ─── NODE INTERACTIVE WIDGET ─────────────────────────────────────────────────
enum NodeState { done, active, locked }

class _NodeInteractiveWidget extends StatefulWidget {
  final Map<String, dynamic> node;
  final NodeState state;
  final Animation<double> pulseAnim;
  final VoidCallback onTap;

  const _NodeInteractiveWidget({
    required this.node,
    required this.state,
    required this.pulseAnim,
    required this.onTap,
  });

  @override
  State<_NodeInteractiveWidget> createState() => _NodeInteractiveWidgetState();
}

class _NodeInteractiveWidgetState extends State<_NodeInteractiveWidget>
    with SingleTickerProviderStateMixin {
  late AnimationController _scaleCtrl;

  @override
  void initState() {
    super.initState();
    _scaleCtrl = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 100), lowerBound: 0.9, upperBound: 1.0)
      ..value = 1.0;
  }

  @override
  void dispose() {
    _scaleCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final int id = widget.node['id'] as int;
    final String type = widget.node['type'] as String;

    Color baseColor;
    if (widget.state == NodeState.locked) {
      baseColor = const Color(0xFF334155); // Xám bóng đêm
    } else if (widget.state == NodeState.done) {
      baseColor = const Color(0xFF10B981); // Xanh hoàn thành (Accent)
    } else {
      baseColor = const Color(0xFF3B82F6); // Blue Neon (Primary)
    }

    Widget badge = _buildBadge(id, baseColor);

    if (widget.state == NodeState.active) {
      badge = AnimatedBuilder(
        animation: widget.pulseAnim,
        builder: (_, child) => Transform.scale(
          scale: 1.3 * widget.pulseAnim.value, // Phóng to 1.3x và đập nhịp
          child: child,
        ),
        child: badge,
      );
    }

    return GestureDetector(
      onTapDown: (_) => _scaleCtrl.reverse(),
      onTapUp: (_) {
        _scaleCtrl.forward();
        widget.onTap();
      },
      onTapCancel: () => _scaleCtrl.forward(),
      child: ScaleTransition(
        scale: _scaleCtrl,
        child: SizedBox(
          width: 90,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Cờ/label
              Container(
                margin: const EdgeInsets.only(bottom: 6),
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: widget.state == NodeState.locked ? baseColor.withValues(alpha: 0.8) : baseColor,
                  borderRadius: BorderRadius.circular(8),
                  boxShadow: widget.state == NodeState.locked ? null : [
                    BoxShadow(color: baseColor.withValues(alpha: 0.5), blurRadius: 8, offset: const Offset(0, 2))
                  ],
                ),
                child: Text(
                  widget.node['label'] as String,
                  textAlign: TextAlign.center,
                  style: GoogleFonts.outfit(
                      color: Colors.white,
                      fontSize: 10,
                      fontWeight: FontWeight.w800,
                      letterSpacing: 0.5),
                ),
              ),
              badge,
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildBadge(int id, Color color) {
    return Stack(
      alignment: Alignment.center,
      clipBehavior: Clip.none,
      children: [
        // Glow siêu sáng cho active node (Màu Purple để tạo điểm nhấn sci-fi)
        if (widget.state == NodeState.active)
          Container(
            width: 86,
            height: 86,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: const Color(0xFF8B5CF6).withValues(alpha: 0.3),
              boxShadow: [
                BoxShadow(color: const Color(0xFF8B5CF6).withValues(alpha: 0.8), blurRadius: 30, spreadRadius: 15)
              ],
            ),
          ),
        
        // Thân bục dưới (để tạo cảm giác 3D)
        Positioned(
          bottom: -4,
          child: Container(
            width: 70,
            height: 24,
            decoration: BoxDecoration(
              color: Colors.black.withValues(alpha: 0.3),
              borderRadius: BorderRadius.circular(32),
            ),
          ),
        ),
        Positioned(
          bottom: 2,
          child: Container(
            width: 60,
            height: 20,
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.4),
              borderRadius: BorderRadius.circular(32),
            ),
          ),
        ),

        // Cục Node chính
        Container(
          width: 68,
          height: 68,
          margin: const EdgeInsets.only(bottom: 10),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: widget.state == NodeState.locked
                  ? [color, color.withValues(alpha: 0.7)]
                  : [color.withValues(alpha: 0.8), color],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            shape: BoxShape.circle,
            border: Border.all(
              color: widget.state == NodeState.locked ? Colors.white30 : Colors.white,
              width: widget.state == NodeState.active ? 4 : 2,
            ),
            boxShadow: widget.state == NodeState.locked ? null : [
              BoxShadow(
                  color: color.withValues(alpha: 0.8),
                  blurRadius: 10,
                  offset: const Offset(0, 4)),
            ],
          ),
          child: Center(
            child: widget.state == NodeState.done
                ? const Icon(Icons.check_rounded, color: Colors.white, size: 32)
                : widget.state == NodeState.locked
                    ? const Icon(Icons.lock_rounded, color: Colors.white54, size: 28)
                    : Text(
                        id < 10 ? '0$id' : '$id',
                        style: GoogleFonts.outfit(
                          color: Colors.white,
                          fontSize: 24,
                          fontWeight: FontWeight.w900,
                          shadows: [Shadow(color: Colors.black26, offset: Offset(0, 2), blurRadius: 4)]
                        ),
                      ),
          ),
        ),
      ],
    );
  }
}

// ─── AI BADGE ────────────────────────────────────────────────────────────────
class _AiBadge extends StatelessWidget {
  const _AiBadge();

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
          decoration: BoxDecoration(
            gradient: const LinearGradient(colors: [Color(0xFF6D28D9), Color(0xFF4F46E5)]),
            borderRadius: BorderRadius.circular(20),
            boxShadow: [
              BoxShadow(color: const Color(0xFF8B5CF6).withValues(alpha: 0.6), blurRadius: 12, offset: const Offset(0, 4)),
            ],
          ),
          child: Row(mainAxisSize: MainAxisSize.min, children: [
            const Icon(Icons.psychology_rounded, color: Colors.white, size: 16),
            const SizedBox(width: 4),
            Text(
              'AI Gợi Ý',
              style: GoogleFonts.outfit(
                color: Colors.white,
                fontSize: 11,
                fontWeight: FontWeight.w900,
                letterSpacing: 0.5,
              ),
            ),
          ]),
        ),
        // Mũi tên chỉ xuống của Tooltip
        CustomPaint(
          size: const Size(12, 6),
          painter: _TooltipArrowPainter(),
        ),
      ],
    );
  }
}

class _TooltipArrowPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()..color = const Color(0xFF4F46E5);
    final path = Path()
      ..moveTo(0, 0)
      ..lineTo(size.width / 2, size.height)
      ..lineTo(size.width, 0)
      ..close();
    canvas.drawPath(path, paint);
  }
  @override
  bool shouldRepaint(covariant CustomPainter old) => false;
}

// ─── BOTTOM SHEET KHI NHẤN VỀ 1 VÒNG ─────────────────────────────────────────
class _RoundBottomSheet extends StatefulWidget {
  final int id;
  final String label;
  final NodeState state;
  final VoidCallback onStartOrReview;
  const _RoundBottomSheet({required this.id, required this.label, required this.state, required this.onStartOrReview});

  @override
  State<_RoundBottomSheet> createState() => _RoundBottomSheetState();
}

class _RoundBottomSheetState extends State<_RoundBottomSheet> {
  bool _loadingAi = false;
  String? _aiResponse;

  Future<void> _callAi() async {
    setState(() => _loadingAi = true);
    try {
      final user = await AuthManager.getUser();
      final summary = await UserProgressManager.getSummary();
      final prompt = "[SYSTEM: User đang ở level ${summary['level']} (${summary['xp']} XP). Trạng thái điểm học là ${widget.state.name}. Đưa ra lời khuyên 2 câu mạnh mẽ, cá nhân hóa cho học viên thi phần '${widget.label}' chặng ${widget.id}. Cổ vũ tinh thần!] Xin lời khuyên mentor từ AI.";
      
      final res = await ApiService.askAi(prompt, user['id'] ?? 'unknown');
      if (mounted) setState(() { _aiResponse = res['response'] ?? 'Cố lên bạn nhé!'; _loadingAi = false; });
    } catch (e) {
      if (mounted) setState(() { _aiResponse = "Kết nối AI thất bại. Hãy tin vào bản thân và tiếp tục cố gắng!"; _loadingAi = false; });
    }
  }

  @override
  Widget build(BuildContext context) {
    final bool isDone = widget.state == NodeState.done;
    final color = isDone ? const Color(0xFF10B981) : const Color(0xFF3B82F6);

    return Container(
      padding: EdgeInsets.fromLTRB(24, 20, 24, MediaQuery.of(context).padding.bottom + 32),
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(32)),
        boxShadow: [BoxShadow(color: Colors.black26, blurRadius: 20, offset: Offset(0, -5))],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(width: 48, height: 5, decoration: BoxDecoration(color: Colors.grey.shade300, borderRadius: BorderRadius.circular(4))),
          const SizedBox(height: 24),
          Row(children: [
            Container(
              width: 56, height: 56,
              decoration: BoxDecoration(color: color.withValues(alpha: 0.15), shape: BoxShape.circle),
              child: Center(
                child: isDone
                  ? Icon(Icons.check_circle_rounded, color: color, size: 28)
                  : Text('${widget.id}', style: GoogleFonts.outfit(color: color, fontWeight: FontWeight.w900, fontSize: 24)),
              ),
            ),
            const SizedBox(width: 16),
            Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text('Chặng ${widget.id}', style: GoogleFonts.outfit(color: Colors.grey.shade500, fontSize: 13, fontWeight: FontWeight.w600, letterSpacing: 1.2)),
              Text(widget.label, style: GoogleFonts.outfit(fontWeight: FontWeight.w800, fontSize: 20, color: const Color(0xFF0F172A))),
            ])),
            if (isDone) Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(color: const Color(0xFFD1FAE5), borderRadius: BorderRadius.circular(16)),
              child: Text('✅ Đã học', style: GoogleFonts.outfit(color: const Color(0xFF059669), fontWeight: FontWeight.w800, fontSize: 12)),
            ),
          ]),
          const SizedBox(height: 24),
          
          if (_aiResponse == null && !_loadingAi)
            SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                onPressed: _callAi,
                icon: const Icon(Icons.psychology, color: Color(0xFF8B5CF6)),
                label: Text('AI Phân Tích Lộ Trình ✦', style: GoogleFonts.outfit(color: const Color(0xFF8B5CF6), fontWeight: FontWeight.w700)),
                style: OutlinedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  side: const BorderSide(color: Color(0xFF8B5CF6), width: 1.5),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                ),
              ),
            ),
            
          if (_loadingAi)
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(vertical: 14),
              decoration: BoxDecoration(color: const Color(0xFFF5F3FF), borderRadius: BorderRadius.circular(16)),
              child: const Center(child: SizedBox(height: 20, width: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Color(0xFF8B5CF6)))),
            ),
            
          if (_aiResponse != null)
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                gradient: const LinearGradient(colors: [Color(0xFFFAF5FF), Color(0xFFF3E8FF)]),
                border: Border.all(color: const Color(0xFFD8B4FE)),
                borderRadius: BorderRadius.circular(16),
              ),
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Row(children: [
                  const Icon(Icons.psychology, color: Color(0xFF7C3AED), size: 18),
                  const SizedBox(width: 8),
                  Text('AI Mentor Phân tích', style: GoogleFonts.outfit(color: const Color(0xFF7C3AED), fontWeight: FontWeight.w800, fontSize: 13)),
                ]),
                const SizedBox(height: 8),
                Text(_aiResponse!, style: GoogleFonts.outfit(color: const Color(0xFF4C1D95), fontSize: 14, height: 1.4)),
              ]),
            ),

          const SizedBox(height: 28),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              style: ElevatedButton.styleFrom(
                backgroundColor: color,
                minimumSize: const Size(double.infinity, 60),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                elevation: 6,
                shadowColor: color.withValues(alpha: 0.5),
              ),
              onPressed: widget.onStartOrReview,
              icon: Icon(isDone ? Icons.refresh_rounded : Icons.play_arrow_rounded, color: Colors.white, size: 28),
              label: Text(isDone ? 'Ôn tập lại' : '🚀 Bắt đầu ngay!',
                  style: GoogleFonts.outfit(fontWeight: FontWeight.w800, fontSize: 18, color: Colors.white)),
            ),
          ),
        ],
      ),
    );
  }
}

// ─── ADVANCED PAINTERS ───────────────────────────────────────────────────────
class _DeepOceanBgPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;

    // 1. Nền đại dương sâu
    final oceanGrad = LinearGradient(
      colors: const [Color(0xFF0F172A), Color(0xFF1E293B), Color(0xFF0F172A)],
      begin: Alignment.topCenter,
      end: Alignment.bottomCenter,
    );
    canvas.drawRect(Rect.fromLTWH(0, 0, w, h), Paint()..shader = oceanGrad.createShader(Rect.fromLTWH(0, 0, w, h)));

    // 2. Lưới ô vuông mờ t ảo cảm giác công nghệ AI / Game
    final gridPaint = Paint()
      ..color = Colors.white.withValues(alpha: 0.03)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.0;
    
    for(double i = 0; i < w; i += 40) {
      canvas.drawLine(Offset(i, 0), Offset(i, h), gridPaint);
    }
    for(double j = 0; j < h; j += 40) {
      canvas.drawLine(Offset(0, j), Offset(w, j), gridPaint);
    }

    // 3. Vùng sáng mờ quanh các mép map
    final glowPaintLeft = Paint()
      ..shader = RadialGradient(colors: [const Color(0xFF3B82F6).withValues(alpha: 0.15), Colors.transparent]).createShader(Rect.fromCircle(center: Offset(0, h * 0.3), radius: w));
    canvas.drawRect(Rect.fromLTWH(0, 0, w, h), glowPaintLeft);

    final glowPaintRight = Paint()
      ..shader = RadialGradient(colors: [const Color(0xFF8B5CF6).withValues(alpha: 0.15), Colors.transparent]).createShader(Rect.fromCircle(center: Offset(w, h * 0.7), radius: w));
    canvas.drawRect(Rect.fromLTWH(0, 0, w, h), glowPaintRight);

    // 4. Pattern hạt mây/sao nhẹ rải rác
    final starPaint = Paint()..color = Colors.white.withValues(alpha: 0.3);
    for (int k = 0; k < 30; k++) {
       double dx = (k * 73) % w;
       double dy = ((k * k) * 97) % h;
       canvas.drawCircle(Offset(dx, dy), (k % 3 == 0) ? 1.5 : 0.8, starPaint);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter old) => false;
}

class _AdvancedPathPainter extends CustomPainter {
  final List<Offset> positions;
  final int currentRound;
  final double flowValue;

  _AdvancedPathPainter({
    required this.positions,
    required this.currentRound,
    required this.flowValue,
  });

  @override
  void paint(Canvas canvas, Size size) {
    if (positions.length < 2) return;

    // Đường Locked (xám mờ, đứt đoạn)
    final lockedPaint = Paint()
      ..color = const Color(0xFF475569).withValues(alpha: 0.5)
      ..strokeWidth = 6
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;

    // Đường Done (Gradient Năng lượng)
    final pathGradient = LinearGradient(colors: [const Color(0xFF10B981), const Color(0xFF3B82F6)]);

    // Tạo viền mờ cho phần Done
    final doneGlowPaint = Paint()
      ..color = const Color(0xFF3B82F6).withValues(alpha: 0.3)
      ..strokeWidth = 24
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;

    for (int i = 0; i < positions.length - 1; i++) {
      final p0 = positions[i];
      final p1 = positions[i + 1];

      // Tạo đường cong CubicBezier uốn lượn mượt mà thay vì cong gập
      final offsetH = (p1.dy - p0.dy) * 0.5;
      final cp1 = Offset(p0.dx, p0.dy + offsetH);
      final cp2 = Offset(p1.dx, p1.dy - offsetH);
      
      final path = Path()
        ..moveTo(p0.dx, p0.dy)
        ..cubicTo(cp1.dx, cp1.dy, cp2.dx, cp2.dy, p1.dx, p1.dy);

      if (i < currentRound - 1) {
        // Đã qua: Vẽ glow bóng và đường chính rành mạch với Gradient
        canvas.drawPath(path, doneGlowPaint);
        
        final bounds = path.getBounds();
        final donePaint = Paint()
          ..shader = pathGradient.createShader(bounds)
          ..strokeWidth = 12
          ..style = PaintingStyle.stroke
          ..strokeCap = StrokeCap.round;
        canvas.drawPath(path, donePaint);

        // Hiệu ứng hạt sáng chạy dọc đường (Flowing effect)
        _drawFlowingDash(canvas, path, flowValue);
      } else {
        // Chưa đi: Đứt đoạn mờ
        _drawDashedPath(canvas, path, lockedPaint);
      }
    }
  }

  void _drawFlowingDash(Canvas canvas, Path path, double progress) {
    final metrics = path.computeMetrics().toList();
    if (metrics.isEmpty) return;
    
    final metric = metrics.first;
    final pathLength = metric.length;
    
    // progress từ 0 -> 1. Hạt chạy tuần hoàn
    final dashLength = 20.0;
    final totalDistance = pathLength + dashLength;
    final startD = (totalDistance * progress) - dashLength;
    
    if (startD < pathLength) {
      final endD = (startD + dashLength).clamp(0.0, pathLength);
      final startClamp = startD.clamp(0.0, pathLength);
      
      final activeSeg = metric.extractPath(startClamp, endD);
      
      final flowPaint = Paint()
        ..color = Colors.white
        ..strokeWidth = 6
        ..style = PaintingStyle.stroke
        ..strokeCap = StrokeCap.round;
        
      canvas.drawPath(activeSeg, flowPaint);
    }
  }

  void _drawDashedPath(Canvas canvas, Path path, Paint paint) {
    const dash = 12.0;
    const gap = 12.0;
    for (final metric in path.computeMetrics()) {
      var d = 0.0;
      while (d < metric.length) {
        final len = math.min(dash, metric.length - d);
        canvas.drawPath(metric.extractPath(d, d + len), paint);
        d += dash + gap;
      }
    }
  }

  @override
  bool shouldRepaint(covariant _AdvancedPathPainter old) {
    return old.flowValue != flowValue || old.currentRound != currentRound;
  }
}

// ─── STICKY HEADER DELEGATE ──────────────────────────────────────────────────
class _StickyDelegate extends SliverPersistentHeaderDelegate {
  final Widget child;
  final double minH, maxH;
  const _StickyDelegate({required this.child, required this.minH, required this.maxH});

  @override
  Widget build(BuildContext context, double shrinkOffset, bool overlaps) =>
      SizedBox.expand(child: child);

  @override
  double get minExtent => minH;
  @override
  double get maxExtent => maxH;
  @override
  bool shouldRebuild(covariant SliverPersistentHeaderDelegate old) => true;
}
