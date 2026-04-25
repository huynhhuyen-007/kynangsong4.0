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

  // Conversation memory — gửi lên backend mỗi lần chat
  final List<Map<String, String>> _chatHistory = [];

  // Context Awareness — backend dùng để detect intent chính xác hơn
  Map<String, dynamic> _conversationState = {'topic': null, 'last_intent': 0, 'turn_count': 0};

  // Track expanded state cho từng message (index → isExpanded)
  final Map<int, bool> _expandedMessages = {};

  // Lịch sử chat hiển thị trên UI
  final List<Map<String, dynamic>> _messages = [
    {
      'isBot': true,
      'text': 'Chào bạn! 👋 Mình là **Owl** – trợ lý kỹ năng sống của bạn.\n\nBạn muốn bắt đầu với chủ đề nào?\n🗣️ **Giao tiếp & Thuyết trình**\n💰 **Quản lý tài chính**\n🧠 **Cải thiện bản thân**\n\nHoặc cứ hỏi thẳng điều bạn đang cần nhé!',
      'skills': [],
      'feedback': null,
      'intentLevel': 1,
      'canExpand': false,
      'fullAnswer': '',
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
      final response = await ApiService.contextChat(
        query, _userId,
        history: List.from(_chatHistory),
        conversationState: Map.from(_conversationState),
      );
      if (mounted) {
        final level = (response['intent_level'] as int?) ?? 3;
        final shortAnswer = response['answer'] as String? ?? 'Không có phản hồi.';
        final fullAnswer  = response['full_answer'] as String? ?? '';
        final canExpand   = response['can_expand'] as bool? ?? false;

        // Cập nhật conversation memory
        _chatHistory.add({'role': 'user', 'content': query});
        _chatHistory.add({'role': 'assistant', 'content': shortAnswer});
        if (_chatHistory.length > 6) {
          _chatHistory.removeRange(0, _chatHistory.length - 6);
        }

        // Cập nhật context state
        setState(() {
          _conversationState = {
            'last_intent': level,
            'turn_count': (_conversationState['turn_count'] as int) + 1,
            // Nếu level >= 3, lưu topic từ query để context tiếp theo chính xác hơn
            'topic': level >= 3 ? query.split(' ').take(4).join(' ') : _conversationState['topic'],
          };
          _messages.add({
            'isBot': true,
            'text': shortAnswer,
            'fullAnswer': fullAnswer,
            'canExpand': canExpand,
            'intentLevel': level,
            'skills': response['related_skills'] ?? [],
            'feedback': null,
            'suggested': response['suggested_questions'] ?? [],
            'ragUsed': response['rag_used'] ?? false,
          });
          _loading = false;
        });
        _scrollToBottom();
      }
    } catch (e) {
      if (mounted) {
        final errMsg = e.toString();
        String friendlyMsg;
        if (errMsg.contains('503') || errMsg.contains('UNAVAILABLE') || errMsg.contains('bận')) {
          friendlyMsg = '🔄 **AI đang bận do nhiều người dùng.**\n\nVui lòng thử lại sau vài giây nhé!';
        } else if (errMsg.contains('429') || errMsg.contains('quota')) {
          friendlyMsg = '⚠️ **Đã vượt giới hạn hôm nay.**\n\nVui lòng thử lại vào ngày mai.';
        } else if (errMsg.contains('SocketException') || errMsg.contains('Connection')) {
          friendlyMsg = '📵 **Mất kết nối mạng.**\n\nKiểm tra WiFi/4G rồi thử lại.';
        } else {
          friendlyMsg = '❌ **Không thể kết nối AI.**\n\nVui lòng thử lại.';
        }
        setState(() {
          _messages.add({
            'isBot': true,
            'text': friendlyMsg,
            'skills': [],
            'feedback': null,
            'isError': true,
            'retryQuery': query,
            'intentLevel': 3,
            'canExpand': false,
            'fullAnswer': '',
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


  // ── Widget: Nút Xem chi tiết (Progressive Disclosure) ─────────────────────
  Widget _buildExpandButton(int index, String fullAnswer) {
    final isExpanded = _expandedMessages[index] ?? false;
    return Padding(
      padding: const EdgeInsets.only(left: 40, top: 6),
      child: GestureDetector(
        onTap: () => setState(() => _expandedMessages[index] = !isExpanded),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
          decoration: BoxDecoration(
            color: const Color(0xFF4F46E5).withOpacity(0.08),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: const Color(0xFF4F46E5).withOpacity(0.3)),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(isExpanded ? Icons.expand_less_rounded : Icons.expand_more_rounded,
                  size: 16, color: const Color(0xFF4F46E5)),
              const SizedBox(width: 4),
              Text(
                isExpanded ? 'Thu gọn' : '📖 Xem chi tiết',
                style: GoogleFonts.outfit(
                    color: const Color(0xFF4F46E5),
                    fontSize: 12,
                    fontWeight: FontWeight.w600),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ── Widget: Menu chips cho greeting (Level 1) ───────────────────────────────
  Widget _buildMenuChips() {
    const chips = [
      {'emoji': '🗣️', 'label': 'Giao tiếp', 'query': 'Làm sao để giao tiếp tốt hơn?'},
      {'emoji': '💰', 'label': 'Tài chính', 'query': 'Cách quản lý tài chính sinh viên'},
      {'emoji': '🧠', 'label': 'Bản thân', 'query': 'Cách cải thiện bản thân mỗi ngày'},
      {'emoji': '🏥', 'label': 'Sức khỏe', 'query': 'Kỹ năng sơ cứu cơ bản'},
    ];
    return Padding(
      padding: const EdgeInsets.only(left: 40, top: 10),
      child: Wrap(
        spacing: 8, runSpacing: 8,
        children: chips.map((c) => GestureDetector(
          onTap: _loading ? null : () => _sendMessage(c['query']!),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Color(0xFF4F46E5), Color(0xFF7C3AED)],
              ),
              borderRadius: BorderRadius.circular(20),
              boxShadow: [BoxShadow(color: const Color(0xFF4F46E5).withOpacity(0.25), blurRadius: 6, offset: const Offset(0, 2))],
            ),
            child: Text('${c['emoji']} ${c['label']}',
                style: GoogleFonts.outfit(color: Colors.white, fontSize: 12, fontWeight: FontWeight.w600)),
          ),
        )).toList(),
      ),
    );
  }

  // ── Widget: Message Bubble ───────────────────────────────────────────────────
  Widget _buildMessage(Map<String, dynamic> msg, int index) {
    final isBot = msg['isBot'] as bool;
    final rawText = msg['text'] as String;
    final fullAnswer = msg['fullAnswer'] as String? ?? '';
    final canExpand  = msg['canExpand'] as bool? ?? false;
    final intentLevel = msg['intentLevel'] as int? ?? 3;
    final isExpanded = _expandedMessages[index] ?? false;
    final skills = msg['skills'] as List<dynamic>? ?? [];
    final feedback = msg['feedback'] as bool?;
    final suggested = msg['suggested'] as List<dynamic>? ?? [];
    final ragUsed = msg['ragUsed'] as bool? ?? false;

    // ── Message truncation: chỉ cắt bot messages, không cắt Level 4 (full format) ──
    const _kTruncLimit = 300;
    final isTruncatable = isBot && rawText.length > _kTruncLimit && intentLevel < 4;
    final isMsgExpanded = _expandedMessages[-index - 1] ?? false; // dùng key âm để phân biệt expand-full với truncate
    final text = (isTruncatable && !isMsgExpanded)
        ? '${rawText.substring(0, _kTruncLimit)}...'
        : rawText;

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
                        color: Colors.black.withValues(alpha: 0.06),
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

          // ── Nút Xem thêm (truncation) ─────────────────────────────────────
          if (isTruncatable) ...[
            const SizedBox(height: 4),
            Padding(
              padding: const EdgeInsets.only(left: 40),
              child: GestureDetector(
                onTap: () => setState(() => _expandedMessages[-index - 1] = !isMsgExpanded),
                child: Text(
                  isMsgExpanded ? '▲ Thu gọn' : '▼ Xem thêm',
                  style: GoogleFonts.outfit(
                    color: const Color(0xFF4F46E5),
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ),
          ],

          // ── Nút Thử lại (chỉ cho lỗi) ────────────────────────────────────────
          if (isBot && msg['isError'] == true && msg['retryQuery'] != null) ...[
            const SizedBox(height: 8),
            Padding(
              padding: const EdgeInsets.only(left: 40),
              child: GestureDetector(
                onTap: _loading ? null : () {
                  final q = msg['retryQuery'] as String;
                  setState(() => _messages.removeLast());
                  _sendMessage(q);
                },
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                  decoration: BoxDecoration(
                    color: const Color(0xFF4F46E5).withOpacity(0.1),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: const Color(0xFF4F46E5).withOpacity(0.3)),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.refresh_rounded, size: 14, color: Color(0xFF4F46E5)),
                      const SizedBox(width: 6),
                      Text('Thử lại', style: GoogleFonts.outfit(
                        color: const Color(0xFF4F46E5), fontSize: 12,
                        fontWeight: FontWeight.w600,
                      )),
                    ],
                  ),
                ),
              ),
            ),
          ],

          // ── Progressive Disclosure: nút Xem chi tiết ──────────────────────
          if (isBot && canExpand && fullAnswer.isNotEmpty) ...[
            _buildExpandButton(index, fullAnswer),
            if (isExpanded) ...[
              const SizedBox(height: 8),
              Padding(
                padding: const EdgeInsets.only(left: 40, right: 4),
                child: Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF0F0FF),
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: const Color(0xFF4F46E5).withOpacity(0.2)),
                  ),
                  child: MarkdownBody(
                    data: fullAnswer,
                    styleSheet: MarkdownStyleSheet(
                      p: GoogleFonts.outfit(color: Colors.grey.shade800, fontSize: 14, height: 1.55),
                      strong: GoogleFonts.outfit(color: const Color(0xFF1E1B4B), fontWeight: FontWeight.bold, fontSize: 14),
                      listBullet: GoogleFonts.outfit(color: Colors.grey.shade700, fontSize: 14),
                    ),
                  ),
                ),
              ),
            ],
          ],

          // ── Menu Chips cho Greeting (Level 1) ─────────────────────────────
          if (isBot && intentLevel == 1 && msg['isError'] != true)
            _buildMenuChips(),

          // ── Feedback Buttons (chỉ hiển thị cho tin nhắn bot bình thường) ────────
          if (isBot && index > 0 && msg['isError'] != true) ...[
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
          // ── RAG Badge (khi AI dùng tài liệu nội bộ) ───────────────────────
          if (isBot && ragUsed && msg['isError'] != true) ...[
            const SizedBox(height: 4),
            Padding(
              padding: const EdgeInsets.only(left: 40),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.verified_rounded, size: 11, color: Color(0xFF10B981)),
                  const SizedBox(width: 3),
                  Text('Dựa trên tài liệu nội bộ',
                      style: GoogleFonts.outfit(
                          fontSize: 10, color: const Color(0xFF10B981),
                          fontWeight: FontWeight.w600)),
                ],
              ),
            ),
          ],

          // ── Suggested Questions ────────────────────────────────────────
          if (isBot && suggested.isNotEmpty && msg['isError'] != true) ...[
            const SizedBox(height: 10),
            Padding(
              padding: const EdgeInsets.only(left: 40),
              child: Text('Bạn có muốn hỏi:',
                  style: GoogleFonts.outfit(
                      fontSize: 11, color: Colors.grey.shade500,
                      fontWeight: FontWeight.w600)),
            ),
            const SizedBox(height: 6),
            Padding(
              padding: const EdgeInsets.only(left: 40),
              child: Wrap(
                spacing: 6, runSpacing: 6,
                children: suggested.map((q) {
                  final qStr = q.toString();
                  return GestureDetector(
                    onTap: _loading ? null : () => _sendMessage(qStr),
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(
                        color: const Color(0xFFF0F0FF),
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: const Color(0xFF4F46E5).withOpacity(0.3)),
                      ),
                      child: Text(qStr,
                          style: GoogleFonts.outfit(
                              color: const Color(0xFF4F46E5), fontSize: 11.5,
                              fontWeight: FontWeight.w600)),
                    ),
                  );
                }).toList(),
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
