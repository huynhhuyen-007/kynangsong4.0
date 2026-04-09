import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_markdown/flutter_markdown.dart';
import '../utils/api_service.dart';
import '../utils/auth_manager.dart';
import '../widgets/app_scaffold.dart';
import 'skill_detail_screen.dart';

class CopilotScreen extends StatefulWidget {
  const CopilotScreen({super.key});

  @override
  State<CopilotScreen> createState() => _CopilotScreenState();
}

class _CopilotScreenState extends State<CopilotScreen>
    with SingleTickerProviderStateMixin {
  final _msgCtrl = TextEditingController();
  final ScrollController _scrollCtrl = ScrollController();
  bool _loading = false;
  String _userId = '';

  // Lịch sử chat
  final List<Map<String, dynamic>> _messages = [
    {
      'isBot': true,
      'text':
          'Chào bạn! Mình là **🦉 AI Mentor Owl** - Trợ lý kỹ năng sống thông minh!\n\nMình đã kết nối với hồ sơ học tập của bạn và sẽ đưa ra lời khuyên **cá nhân hóa** dựa trên tiến độ trên bản đồ kỹ năng. Hãy hỏi bất kỳ điều gì nhé!',
      'skills': [],
      'feedback': null, // null = chưa feedback, true = hữu ích, false = không
    }
  ];

  // Gợi ý thông minh
  final List<Map<String, String>> _suggestions = [
    {'emoji': '🔥', 'text': 'Nhà cháy phải làm gì?'},
    {'emoji': '💰', 'text': 'Chi tiêu 2 triệu/tháng'},
    {'emoji': '🧠', 'text': 'Cách giảm stress khi deadline'},
    {'emoji': '💬', 'text': 'Sợ thuyết trình đám đông'},
    {'emoji': '🏥', 'text': 'Sơ cứu khi bị thương'},
    {'emoji': '🎓', 'text': 'Kỹ năng học tập hiệu quả'},
  ];

  @override
  void initState() {
    super.initState();
    _loadUser();
  }

  Future<void> _loadUser() async {
    final user = await AuthManager.getUser();
    if (user != null && mounted) {
      setState(() => _userId = user['id'] ?? '');
    }
  }

  @override
  void dispose() {
    _msgCtrl.dispose();
    _scrollCtrl.dispose();
    super.dispose();
  }

  void _scrollToBottom() {
    if (_scrollCtrl.hasClients) {
      Future.delayed(const Duration(milliseconds: 150), () {
        if (_scrollCtrl.hasClients) {
          _scrollCtrl.animateTo(
            _scrollCtrl.position.maxScrollExtent,
            duration: const Duration(milliseconds: 300),
            curve: Curves.easeOut,
          );
        }
      });
    }
  }

  Future<void> _sendMessage(String text) async {
    final query = text.trim();
    if (query.isEmpty || _loading) return;

    setState(() {
      _messages.add({
        'isBot': false,
        'text': query,
        'skills': [],
        'feedback': null,
      });
      _loading = true;
      _msgCtrl.clear();
    });
    _scrollToBottom();

    try {
      // Phase 3: Dùng context-chat thay vì chat thông thường
      // → AI tự động load skill_stats để trả lời cá nhân hóa
      final response = await ApiService.contextChat(query, _userId);
      if (mounted) {
        setState(() {
          _messages.add({
            'isBot': true,
            'text': response['answer'] ?? 'Không có phản hồi.',
            'skills': response['related_skills'] ?? [],
            'feedback': null,
          });
          _loading = false;
        });
        _scrollToBottom();
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _messages.add({
            'isBot': true,
            'text': '❌ **Lỗi kết nối AI:** ${e.toString()}\n\nVui lòng kiểm tra kết nối mạng và thử lại.',
            'skills': [],
            'feedback': null,
          });
          _loading = false;
        });
        _scrollToBottom();
      }
    }
  }

  void _setFeedback(int msgIndex, bool isHelpful) {
    setState(() {
      _messages[msgIndex]['feedback'] = isHelpful;
    });
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          isHelpful ? '👍 Cảm ơn phản hồi của bạn!' : '👎 Cảm ơn! Chúng tôi sẽ cải thiện.',
          style: GoogleFonts.outfit(),
        ),
        backgroundColor: isHelpful ? Colors.green.shade600 : Colors.orange.shade700,
        duration: const Duration(seconds: 2),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
    );
  }

  // ── Widget: Message Bubble ───────────────────────────────────────────────────
  Widget _buildMessage(Map<String, dynamic> msg, int index) {
    final isBot = msg['isBot'] as bool;
    final text = msg['text'] as String;
    final skills = msg['skills'] as List<dynamic>? ?? [];
    final feedback = msg['feedback'] as bool?;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      child: Column(
        crossAxisAlignment:
            isBot ? CrossAxisAlignment.start : CrossAxisAlignment.end,
        children: [
          // ── Avatar + Bubble ──────────────────────────────────────────────────
          Row(
            mainAxisAlignment:
                isBot ? MainAxisAlignment.start : MainAxisAlignment.end,
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              if (isBot) ...[
                CircleAvatar(
                  radius: 16,
                  backgroundColor: const Color(0xFF4F46E5),
                  child: const Icon(Icons.smart_toy_rounded,
                      color: Colors.white, size: 18),
                ),
                const SizedBox(width: 8),
              ],
              Flexible(
                child: Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  decoration: BoxDecoration(
                    color: isBot ? Colors.white : const Color(0xFF4F46E5),
                    borderRadius: BorderRadius.only(
                      topLeft: const Radius.circular(18),
                      topRight: const Radius.circular(18),
                      bottomLeft: isBot
                          ? const Radius.circular(4)
                          : const Radius.circular(18),
                      bottomRight: isBot
                          ? const Radius.circular(18)
                          : const Radius.circular(4),
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.06),
                        blurRadius: 10,
                        offset: const Offset(0, 4),
                      )
                    ],
                  ),
                  child: MarkdownBody(
                    data: text,
                    styleSheet: MarkdownStyleSheet(
                      p: GoogleFonts.outfit(
                        color: isBot ? Colors.grey.shade800 : Colors.white,
                        fontSize: 14.5,
                        height: 1.55,
                      ),
                      strong: GoogleFonts.outfit(
                        color: isBot ? const Color(0xFF1E1B4B) : Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 14.5,
                      ),
                      listBullet: GoogleFonts.outfit(
                        color: isBot ? Colors.grey.shade700 : Colors.white70,
                        fontSize: 14.5,
                      ),
                    ),
                  ),
                ),
              ),
              if (!isBot) const SizedBox(width: 36),
            ],
          ),

          // ── Feedback Buttons (chỉ hiển thị cho tin nhắn của Bot) ─────────────
          if (isBot && index > 0) ...[
            const SizedBox(height: 6),
            Padding(
              padding: const EdgeInsets.only(left: 40),
              child: feedback == null
                  ? Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text('Có hữu ích không?',
                            style: GoogleFonts.outfit(
                                fontSize: 11, color: Colors.grey.shade500)),
                        const SizedBox(width: 8),
                        _feedbackBtn(
                          icon: Icons.thumb_up_alt_outlined,
                          label: 'Có',
                          color: Colors.green,
                          onTap: () => _setFeedback(index, true),
                        ),
                        const SizedBox(width: 6),
                        _feedbackBtn(
                          icon: Icons.thumb_down_alt_outlined,
                          label: 'Không',
                          color: Colors.orange,
                          onTap: () => _setFeedback(index, false),
                        ),
                      ],
                    )
                  : Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          feedback
                              ? Icons.thumb_up_alt
                              : Icons.thumb_down_alt,
                          size: 14,
                          color: feedback
                              ? Colors.green.shade600
                              : Colors.orange.shade700,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          feedback ? 'Hữu ích' : 'Không hữu ích',
                          style: GoogleFonts.outfit(
                            fontSize: 11,
                            color: feedback
                                ? Colors.green.shade600
                                : Colors.orange.shade700,
                          ),
                        ),
                      ],
                    ),
            ),
          ],

          // ── Related Skills (Tích hợp hệ sinh thái) ──────────────────────────
          if (isBot && skills.isNotEmpty) ...[
            const SizedBox(height: 10),
            Padding(
              padding: const EdgeInsets.only(left: 40),
              child: Text(
                '📚 Bài học liên quan:',
                style: GoogleFonts.outfit(
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                    color: Colors.grey.shade600),
              ),
            ),
            const SizedBox(height: 6),
            ...skills.map(
              (s) => Padding(
                padding: const EdgeInsets.only(left: 40, bottom: 6),
                child: InkWell(
                  onTap: () => Navigator.push(
                    context,
                    MaterialPageRoute(
                        builder: (_) =>
                            SkillDetailScreen(skillItem: s)),
                  ),
                  borderRadius: BorderRadius.circular(12),
                  child: Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: const Color(0xFFFFF7ED),
                      border: Border.all(color: const Color(0xFFFBBF24).withOpacity(0.5)),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Row(
                      children: [
                        ClipRRect(
                          borderRadius: BorderRadius.circular(6),
                          child: s['image_url'] != null &&
                                  s['image_url'].isNotEmpty
                              ? Image.network(
                                  s['image_url'],
                                  width: 40,
                                  height: 40,
                                  fit: BoxFit.cover,
                                  errorBuilder: (c, e, t) => Container(
                                      width: 40,
                                      height: 40,
                                      color: Colors.grey.shade200,
                                      child: const Icon(Icons.image_not_supported_outlined, size: 18, color: Colors.grey)),
                                )
                              : Container(
                                  width: 40,
                                  height: 40,
                                  color: Colors.grey.shade200,
                                  child: const Icon(Icons.book_outlined, size: 20, color: Colors.grey)),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                s['title'] ?? '',
                                style: GoogleFonts.outfit(
                                    fontWeight: FontWeight.w700,
                                    fontSize: 13),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                              Text(
                                s['category'] ?? 'Kỹ năng sống',
                                style: GoogleFonts.outfit(
                                    color: Colors.orange.shade700,
                                    fontSize: 11,
                                    fontWeight: FontWeight.bold),
                              ),
                            ],
                          ),
                        ),
                        Icon(Icons.arrow_forward_ios_rounded,
                            size: 14, color: Colors.orange.shade600),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _feedbackBtn({
    required IconData icon,
    required String label,
    required Color color,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        decoration: BoxDecoration(
          color: color.withOpacity(0.08),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: color.withOpacity(0.3)),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 13, color: color),
            const SizedBox(width: 3),
            Text(label,
                style: GoogleFonts.outfit(
                    fontSize: 11, color: color, fontWeight: FontWeight.w600)),
          ],
        ),
      ),
    );
  }

  // ── Build ────────────────────────────────────────────────────────────────────
  @override
  Widget build(BuildContext context) {
    return AppScaffold(
      title: 'AI Copilot',
      currentIndex: -1,
      body: Container(
        color: const Color(0xFFF5F6FA),
        child: Column(
          children: [
            // ── Smart Suggestions ──────────────────────────────────────────────
            Container(
              color: Colors.white,
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '💡 Gợi ý nhanh:',
                    style: GoogleFonts.outfit(
                        fontSize: 12,
                        color: Colors.grey.shade500,
                        fontWeight: FontWeight.w600),
                  ),
                  const SizedBox(height: 8),
                  SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: Row(
                      children: _suggestions.map((s) {
                        return GestureDetector(
                          onTap: _loading
                              ? null
                              : () => _sendMessage(s['text']!),
                          child: AnimatedContainer(
                            duration: const Duration(milliseconds: 200),
                            margin: const EdgeInsets.only(right: 8),
                            padding: const EdgeInsets.symmetric(
                                horizontal: 14, vertical: 8),
                            decoration: BoxDecoration(
                              color: _loading
                                  ? Colors.grey.shade100
                                  : const Color(0xFF4F46E5).withOpacity(0.08),
                              borderRadius: BorderRadius.circular(20),
                              border: Border.all(
                                color: _loading
                                    ? Colors.grey.shade300
                                    : const Color(0xFF4F46E5).withOpacity(0.25),
                              ),
                            ),
                            child: Text(
                              '${s['emoji']} ${s['text']}',
                              style: GoogleFonts.outfit(
                                color: _loading
                                    ? Colors.grey
                                    : const Color(0xFF4F46E5),
                                fontWeight: FontWeight.w600,
                                fontSize: 12.5,
                              ),
                            ),
                          ),
                        );
                      }).toList(),
                    ),
                  ),
                ],
              ),
            ),

            // ── Messages List ──────────────────────────────────────────────────
            Expanded(
              child: ListView.builder(
                controller: _scrollCtrl,
                padding: const EdgeInsets.symmetric(vertical: 12),
                itemCount: _messages.length,
                itemBuilder: (ctx, i) => _buildMessage(_messages[i], i),
              ),
            ),

            // ── Loading Indicator ──────────────────────────────────────────────
            if (_loading)
              Container(
                color: const Color(0xFFF5F6FA),
                padding:
                    const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
                child: Row(
                  children: [
                    const SizedBox(width: 40),
                    SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: const Color(0xFF4F46E5).withOpacity(0.7)),
                    ),
                    const SizedBox(width: 10),
                    Text(
                      'AI đang suy nghĩ...',
                      style: GoogleFonts.outfit(
                          color: Colors.grey.shade500,
                          fontSize: 13,
                          fontStyle: FontStyle.italic),
                    ),
                  ],
                ),
              ),

            // ── Input Bar ─────────────────────────────────────────────────────
            Container(
              padding: const EdgeInsets.fromLTRB(16, 10, 16, 10),
              decoration: BoxDecoration(
                color: Colors.white,
                boxShadow: [
                  BoxShadow(
                      color: Colors.black.withOpacity(0.06),
                      blurRadius: 12,
                      offset: const Offset(0, -4))
                ],
              ),
              child: SafeArea(
                child: Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: _msgCtrl,
                        style: GoogleFonts.outfit(fontSize: 14.5),
                        maxLines: 4,
                        minLines: 1,
                        textInputAction: TextInputAction.send,
                        onSubmitted: (_) => _sendMessage(_msgCtrl.text),
                        decoration: InputDecoration(
                          hintText: 'Hỏi AI bất kỳ tình huống nào...',
                          hintStyle: GoogleFonts.outfit(
                              color: Colors.grey.shade400, fontSize: 14),
                          contentPadding: const EdgeInsets.symmetric(
                              horizontal: 18, vertical: 12),
                          filled: true,
                          fillColor: Colors.grey.shade50,
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(24),
                            borderSide: BorderSide.none,
                          ),
                          enabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(24),
                            borderSide: BorderSide(
                                color: Colors.grey.shade200, width: 1),
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(24),
                            borderSide: const BorderSide(
                                color: Color(0xFF4F46E5), width: 1.5),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 10),
                    GestureDetector(
                      onTap: () => _sendMessage(_msgCtrl.text),
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 200),
                        width: 46,
                        height: 46,
                        decoration: BoxDecoration(
                          color: _loading
                              ? Colors.grey.shade300
                              : const Color(0xFF4F46E5),
                          shape: BoxShape.circle,
                          boxShadow: _loading
                              ? []
                              : [
                                  BoxShadow(
                                      color: const Color(0xFF4F46E5)
                                          .withOpacity(0.35),
                                      blurRadius: 10,
                                      offset: const Offset(0, 4))
                                ],
                        ),
                        child: const Icon(Icons.send_rounded,
                            color: Colors.white, size: 20),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
