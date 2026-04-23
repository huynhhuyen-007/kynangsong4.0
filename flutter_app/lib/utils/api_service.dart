import 'dart:convert';
import 'dart:io' show Platform;
import 'package:http/http.dart' as http;

class ApiService {
  /// IP máy tính chạy backend — cập nhật khi đổi mạng WiFi
  static const String _pcIp = '192.168.8.200';

  /// Tự chọn URL đúng theo môi trường:
  ///   - Android Emulator : 10.0.2.2  (alias của localhost trên máy host)
  ///   - Thiết bị thật    : IP WiFi của máy tính (_pcIp)
  static String get _baseUrl {
    try {
      if (Platform.isAndroid) {
        // Kiểm tra xem có phải emulator không qua ANDROID_EMULATOR env
        // Mặc định dùng IP WiFi; nếu muốn force emulator, đổi thành 10.0.2.2
        return 'http://$_pcIp:8000';
      }
      return 'http://$_pcIp:8000';
    } catch (_) {
      return 'http://$_pcIp:8000';
    }
  }

  static String get baseUrl => _baseUrl;

  // ── Auth ──────────────────────────────────────────────────────────────────
  static Future<Map<String, dynamic>> login(String email, String password) async {
    final response = await http.post(Uri.parse('$_baseUrl/api/auth/login'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'email': email, 'password': password}));
    final body = jsonDecode(utf8.decode(response.bodyBytes));
    if (response.statusCode == 200) return body as Map<String, dynamic>;
    throw ApiException(body['detail'] ?? 'Đăng nhập thất bại.');
  }

  static Future<Map<String, dynamic>> register(String name, String email, String password) async {
    final response = await http.post(Uri.parse('$_baseUrl/api/auth/register'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'name': name, 'email': email, 'password': password}));
    final body = jsonDecode(utf8.decode(response.bodyBytes));
    if (response.statusCode == 200) return body as Map<String, dynamic>;
    throw ApiException(body['detail'] ?? 'Đăng ký thất bại.');
  }

  static Future<String> uploadAvatar(String userId, String filePath) async {
    final request = http.MultipartRequest('POST', Uri.parse('$_baseUrl/api/users/$userId/avatar'));
    request.files.add(await http.MultipartFile.fromPath('file', filePath));
    final response = await request.send();
    final respStr = await response.stream.bytesToString();
    if (response.statusCode == 200) {
      final body = jsonDecode(respStr);
      return body['avatar_url'] as String;
    }
    throw ApiException('Lỗi tải ảnh lên');
  }

  // ── Content ───────────────────────────────────────────────────────────────
  static Future<List<dynamic>> getSkills() async {
    final response = await http.get(Uri.parse('$_baseUrl/api/skills'));
    if (response.statusCode == 200) return jsonDecode(utf8.decode(response.bodyBytes)) as List;
    throw ApiException('Lỗi tải danh sách kỹ năng');
  }

  static Future<List<dynamic>> getNews() async {
    final response = await http.get(Uri.parse('$_baseUrl/api/news'));
    if (response.statusCode == 200) return jsonDecode(utf8.decode(response.bodyBytes)) as List;
    throw ApiException('Lỗi tải danh sách tin tức');
  }


  // ── Admin Users ───────────────────────────────────────────────────────────
  static Future<List<dynamic>> getAllUsers(String adminId) async {
    final response = await http.get(Uri.parse('$_baseUrl/api/admin/users?admin_id=$adminId'));
    if (response.statusCode == 200) return jsonDecode(utf8.decode(response.bodyBytes)) as List;
    final body = jsonDecode(utf8.decode(response.bodyBytes));
    throw ApiException(body['detail'] ?? 'Lỗi tải danh sách người dùng');
  }

  static Future<Map<String, dynamic>> getAdminStats(String adminId) async {
    final response = await http.get(Uri.parse('$_baseUrl/api/admin/stats?admin_id=$adminId'));
    if (response.statusCode == 200) return jsonDecode(utf8.decode(response.bodyBytes)) as Map<String, dynamic>;
    throw ApiException('Lỗi tải thống kê hệ thống');
  }

  static Future<void> setRole(String adminId, String targetEmail, String newRole) async {
    final response = await http.post(Uri.parse('$_baseUrl/api/admin/set_role'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'admin_id': adminId, 'target_email': targetEmail, 'new_role': newRole}));
    if (response.statusCode != 200) {
      final body = jsonDecode(utf8.decode(response.bodyBytes));
      throw ApiException(body['detail'] ?? 'Lỗi cập nhật quyền');
    }
  }

  static Future<void> deleteUser(String adminId, String userId) async {
    final response = await http.delete(
        Uri.parse('$_baseUrl/api/admin/users/$userId?admin_id=$adminId'));
    if (response.statusCode != 200) {
      final body = jsonDecode(utf8.decode(response.bodyBytes));
      throw ApiException(body['detail'] ?? 'Lỗi xóa tài khoản');
    }
  }

  // ── Community ─────────────────────────────────────────────────────────────
  static Future<List<dynamic>> getPosts({String sort = 'new'}) async {
    final response = await http.get(Uri.parse('$_baseUrl/api/community/posts?sort=$sort'));
    if (response.statusCode == 200) return jsonDecode(utf8.decode(response.bodyBytes)) as List;
    throw ApiException('Lỗi tải bài đăng');
  }

  static Future<Map<String, dynamic>> createPost({
    required String userId, required String userName,
    required String content, required String topic,
  }) async {
    final response = await http.post(Uri.parse('$_baseUrl/api/community/posts'),
        headers: {'Content-Type': 'application/json; charset=UTF-8'},
        body: jsonEncode({'user_id': userId, 'user_name': userName, 'content': content, 'topic': topic}));
    final body = jsonDecode(utf8.decode(response.bodyBytes));
    if (response.statusCode == 200) return body as Map<String, dynamic>;
    throw ApiException(body['detail'] ?? 'Đăng bài thất bại');
  }

  static Future<Map<String, dynamic>> toggleLike(String postId, String userId) async {
    final response = await http.post(Uri.parse('$_baseUrl/api/community/posts/$postId/like'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'user_id': userId}));
    final body = jsonDecode(utf8.decode(response.bodyBytes));
    if (response.statusCode == 200) return body as Map<String, dynamic>;
    throw ApiException(body['detail'] ?? 'Lỗi thích bài');
  }

  static Future<List<dynamic>> getComments(String postId) async {
    final response = await http.get(Uri.parse('$_baseUrl/api/community/posts/$postId/comments'));
    if (response.statusCode == 200) return jsonDecode(utf8.decode(response.bodyBytes)) as List;
    throw ApiException('Lỗi tải bình luận');
  }

  static Future<Map<String, dynamic>> addComment({
    required String postId, required String userId,
    required String userName, required String content,
  }) async {
    final response = await http.post(Uri.parse('$_baseUrl/api/community/posts/$postId/comments'),
        headers: {'Content-Type': 'application/json; charset=UTF-8'},
        body: jsonEncode({'user_id': userId, 'user_name': userName, 'content': content}));
    
    if (response.statusCode != 200) {
      try {
        final body = jsonDecode(utf8.decode(response.bodyBytes));
        throw ApiException(body['detail'] ?? 'Gửi bình luận thất bại');
      } catch (e) {
        if (e is ApiException) rethrow;
        throw ApiException('Lỗi máy chủ (HTTP ${response.statusCode})');
      }
    }
    return jsonDecode(utf8.decode(response.bodyBytes)) as Map<String, dynamic>;
  }

  static Future<void> reportPost(String postId, String userId) async {
    final response = await http.post(
      Uri.parse('$_baseUrl/api/community/posts/$postId/report'),
      headers: {'Content-Type': 'application/json; charset=UTF-8'},
      body: jsonEncode({'user_id': userId}),
    );
    if (response.statusCode != 200) throw ApiException('Báo cáo thất bại');
  }

  static Future<void> reportComment(String commentId, String userId) async {
    final response = await http.post(
      Uri.parse('$_baseUrl/api/community/comments/$commentId/report'),
      headers: {'Content-Type': 'application/json; charset=UTF-8'},
      body: jsonEncode({'user_id': userId}),
    );
    if (response.statusCode != 200) throw ApiException('Báo cáo bình luận thất bại');
  }

  static Future<void> deletePost(String postId, String adminId) async {
    final response = await http.delete(Uri.parse('$_baseUrl/api/community/posts/$postId?admin_id=$adminId'));
    if (response.statusCode != 200) {
      final body = jsonDecode(utf8.decode(response.bodyBytes));
      throw ApiException(body['detail'] ?? 'Lỗi xóa bài');
    }
  }

  // ── Admin Community ───────────────────────────────────────────────────────
  static Future<List<dynamic>> adminGetPosts(String adminId) async {
    final response = await http.get(Uri.parse('$_baseUrl/api/admin/community/posts?admin_id=$adminId'));
    if (response.statusCode == 200) return jsonDecode(utf8.decode(response.bodyBytes)) as List;
    throw ApiException('Lỗi tải bài đăng');
  }

  static Future<void> toggleHidePost(String postId, String adminId) async {
    final response = await http.post(
        Uri.parse('$_baseUrl/api/admin/community/posts/$postId/toggle_hide?admin_id=$adminId'));
    if (response.statusCode != 200) {
      final body = jsonDecode(utf8.decode(response.bodyBytes));
      throw ApiException(body['detail'] ?? 'Lỗi ẩn/hiện bài');
    }
  }

  static Future<List<dynamic>> adminGetComments(String adminId) async {
    final response = await http.get(
        Uri.parse('$_baseUrl/api/admin/community/comments?admin_id=$adminId'));
    if (response.statusCode == 200) return jsonDecode(utf8.decode(response.bodyBytes)) as List;
    throw ApiException('Lỗi tải danh sách bình luận');
  }

  static Future<void> adminDeleteComment(String commentId, String adminId) async {
    final response = await http.delete(
        Uri.parse('$_baseUrl/api/admin/community/comments/$commentId?admin_id=$adminId'));
    if (response.statusCode != 200) {
      final body = jsonDecode(utf8.decode(response.bodyBytes));
      throw ApiException(body['detail'] ?? 'Lỗi xóa bình luận');
    }
  }

  static Future<String> uploadSkillImage(String adminId, String filePath) async {
    final request = http.MultipartRequest(
        'POST', Uri.parse('$_baseUrl/api/admin/upload/image?admin_id=$adminId'));
    request.files.add(await http.MultipartFile.fromPath('file', filePath));
    final response = await request.send();
    final respStr = await response.stream.bytesToString();
    if (response.statusCode == 200) {
      final body = jsonDecode(respStr);
      return body['image_url'] as String;
    }
    final err = jsonDecode(respStr);
    throw ApiException(err['detail'] ?? 'Lỗi upload ảnh');
  }

  static Future<List<dynamic>> getSkillCategories(String adminId) async {
    final response = await http.get(
        Uri.parse('$_baseUrl/api/admin/skills/categories?admin_id=$adminId'));
    if (response.statusCode == 200) return jsonDecode(utf8.decode(response.bodyBytes)) as List;
    throw ApiException('Lỗi tải danh mục');
  }

  // ── Admin CMS — Skills ────────────────────────────────────────────────────
  static Future<void> createSkill({required String adminId, required String title,
      required String category, required String description, required String imageUrl,
      required String content, required int durationMinutes}) async {
    final response = await http.post(Uri.parse('$_baseUrl/api/admin/skills'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'admin_id': adminId, 'title': title, 'category': category,
            'description': description, 'image_url': imageUrl, 'content': content, 'duration_minutes': durationMinutes}));
    if (response.statusCode != 200) {
      final body = jsonDecode(utf8.decode(response.bodyBytes));
      throw ApiException(body['detail'] ?? 'Lỗi tạo kỹ năng');
    }
  }

  static Future<void> updateSkill(String id, {required String adminId, required String title,
      required String category, required String description, required String imageUrl,
      required String content, required int durationMinutes}) async {
    final response = await http.put(Uri.parse('$_baseUrl/api/admin/skills/$id'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'admin_id': adminId, 'title': title, 'category': category,
            'description': description, 'image_url': imageUrl, 'content': content, 'duration_minutes': durationMinutes}));
    if (response.statusCode != 200) {
      final body = jsonDecode(utf8.decode(response.bodyBytes));
      throw ApiException(body['detail'] ?? 'Lỗi cập nhật kỹ năng');
    }
  }

  static Future<void> deleteSkill(String id, String adminId) async {
    final response = await http.delete(Uri.parse('$_baseUrl/api/admin/skills/$id?admin_id=$adminId'));
    if (response.statusCode != 200) throw ApiException('Lỗi xóa kỹ năng');
  }

  // ── Admin CMS — News ──────────────────────────────────────────────────────
  static Future<void> createNews({required String adminId, required String title,
      required String summary, required String content, required String imageUrl, required String author}) async {
    final response = await http.post(Uri.parse('$_baseUrl/api/admin/news'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'admin_id': adminId, 'title': title, 'summary': summary,
            'content': content, 'image_url': imageUrl, 'author': author}));
    if (response.statusCode != 200) {
      final body = jsonDecode(utf8.decode(response.bodyBytes));
      throw ApiException(body['detail'] ?? 'Lỗi tạo tin tức');
    }
  }

  static Future<void> updateNews(String id, {required String adminId, required String title,
      required String summary, required String content, required String imageUrl, required String author}) async {
    final response = await http.put(Uri.parse('$_baseUrl/api/admin/news/$id'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'admin_id': adminId, 'title': title, 'summary': summary,
            'content': content, 'image_url': imageUrl, 'author': author}));
    if (response.statusCode != 200) {
      final body = jsonDecode(utf8.decode(response.bodyBytes));
      throw ApiException(body['detail'] ?? 'Lỗi cập nhật tin tức');
    }
  }

  static Future<void> deleteNews(String id, String adminId) async {
    final response = await http.delete(Uri.parse('$_baseUrl/api/admin/news/$id?admin_id=$adminId'));
    if (response.statusCode != 200) throw ApiException('Lỗi xóa tin tức');
  }


  // ── AI Copilot ────────────────────────────────────────────────────────────
  static Future<Map<String, dynamic>> askAi(String query, String userId) async {
    final response = await http.post(Uri.parse('$_baseUrl/api/ai/chat'),
        headers: {'Content-Type': 'application/json; charset=UTF-8'},
        body: jsonEncode({'query': query, 'user_id': userId}));
    final body = jsonDecode(utf8.decode(response.bodyBytes));
    if (response.statusCode == 200) return body as Map<String, dynamic>;
    throw ApiException(body['detail'] ?? 'Lỗi kết nối AI');
  }

  // ── Phase 2: Exam System ──────────────────────────────────────────────────

  /// Lấy danh sách câu hỏi cho 1 vòng thi
  static Future<List<dynamic>> getExamQuestions(int roundId) async {
    final response = await http.get(Uri.parse('$_baseUrl/api/exam/questions/$roundId'));
    if (response.statusCode == 200) {
      return jsonDecode(utf8.decode(response.bodyBytes)) as List;
    }
    final body = jsonDecode(utf8.decode(response.bodyBytes));
    throw ApiException(body['detail'] ?? 'Lỗi tải câu hỏi');
  }

  /// Nộp bài thi và nhận kết quả chấm điểm
  static Future<Map<String, dynamic>> submitExam({
    required String userId,
    required int roundId,
    required List<Map<String, dynamic>> answers,
  }) async {
    final response = await http.post(
      Uri.parse('$_baseUrl/api/exam/submit'),
      headers: {'Content-Type': 'application/json; charset=UTF-8'},
      body: jsonEncode({'user_id': userId, 'round_id': roundId, 'answers': answers}),
    );
    final body = jsonDecode(utf8.decode(response.bodyBytes));
    if (response.statusCode == 200) return body as Map<String, dynamic>;
    throw ApiException(body['detail'] ?? 'Lỗi nộp bài');
  }

  /// Lấy tiến độ Map của user (current_round, skill_stats...)
  static Future<Map<String, dynamic>> getExamProgress(String userId) async {
    final response = await http.get(Uri.parse('$_baseUrl/api/exam/progress/$userId'));
    if (response.statusCode == 200) {
      return jsonDecode(utf8.decode(response.bodyBytes)) as Map<String, dynamic>;
    }
    throw ApiException('Lỗi tải tiến độ');
  }

  // ── Phase 3: AI Personalized Recommendation ───────────────────────────────

  /// AI phân tích kết quả và đưa ra lộ trình cá nhân hóa
  static Future<Map<String, dynamic>> recommendPath({
    required String userId,
    required int roundId,
    required int correctCount,
    required int totalQuestions,
    required Map<String, dynamic> skillStats,
    required bool passed,
  }) async {
    final response = await http.post(
      Uri.parse('$_baseUrl/api/ai/recommend-path'),
      headers: {'Content-Type': 'application/json; charset=UTF-8'},
      body: jsonEncode({
        'user_id': userId,
        'round_id': roundId,
        'correct_count': correctCount,
        'total_questions': totalQuestions,
        'skill_stats': skillStats,
        'passed': passed,
      }),
    );
    final body = jsonDecode(utf8.decode(response.bodyBytes));
    if (response.statusCode == 200) return body as Map<String, dynamic>;
    throw ApiException(body['detail'] ?? 'Lỗi AI phân tích');
  }

  /// AI Chat context-aware (biết tiến độ học của user)
  static Future<Map<String, dynamic>> contextChat(String query, String userId) async {
    final response = await http.post(
      Uri.parse('$_baseUrl/api/ai/context-chat'),
      headers: {'Content-Type': 'application/json; charset=UTF-8'},
      body: jsonEncode({'query': query, 'user_id': userId, 'include_progress': true}),
    );
    final body = jsonDecode(utf8.decode(response.bodyBytes));
    if (response.statusCode == 200) return body as Map<String, dynamic>;
    throw ApiException(body['detail'] ?? 'Lỗi AI chat');
  }

  // ── Phase 4: Skill Page Learning Flow (SCORM & RAG) ─────────────────────

  static Future<List<dynamic>> getLessons(String skillId) async {
    final response = await http.get(Uri.parse('$_baseUrl/api/skills/$skillId/lessons'));
    if (response.statusCode == 200) return jsonDecode(utf8.decode(response.bodyBytes)) as List;
    throw ApiException('Lỗi tải bài học');
  }

  static Future<void> updateLessonProgress({
    required String userId,
    required String lessonId,
    required double progress,
    required String status,
    int score = 0,
    int timeSpent = 0,
  }) async {
    final response = await http.post(
      Uri.parse('$_baseUrl/api/learning/progress'),
      headers: {'Content-Type': 'application/json; charset=UTF-8'},
      body: jsonEncode({
        'user_id': userId,
        'lesson_id': lessonId,
        'progress': progress,
        'status': status,
        'score': score,
        'time_spent': timeSpent,
      }),
    );
    if (response.statusCode != 200) throw ApiException('Lỗi cập nhật tiến trình SCORM');
  }

  static Future<List<dynamic>> getLessonQuiz(String lessonId) async {
    final response = await http.get(Uri.parse('$_baseUrl/api/learning/quiz/$lessonId'));
    if (response.statusCode == 200) return jsonDecode(utf8.decode(response.bodyBytes)) as List;
    throw ApiException('Lỗi tải câu hỏi quizzes');
  }

  static Future<Map<String, dynamic>> submitLessonQuiz({
    required String userId,
    required String lessonId,
    required List<Map<String, dynamic>> answers,
  }) async {
    final response = await http.post(
      Uri.parse('$_baseUrl/api/learning/quiz_submit'),
      headers: {'Content-Type': 'application/json; charset=UTF-8'},
      body: jsonEncode({
        'user_id': userId,
        'lesson_id': lessonId,
        'answers': answers,
      }),
    );
    if (response.statusCode == 200) return jsonDecode(utf8.decode(response.bodyBytes)) as Map<String, dynamic>;
    throw ApiException('Lỗi lưu kết quả quiz');
  }

  static Future<Map<String, dynamic>> getAiRecommendation(String userId) async {
    final response = await http.get(Uri.parse('$_baseUrl/api/ai/recommendation/$userId'));
    if (response.statusCode == 200) return jsonDecode(utf8.decode(response.bodyBytes)) as Map<String, dynamic>;
    throw ApiException('Lỗi AI phân tích recommendation');
  }
}

class ApiException implements Exception {
  final String message;
  ApiException(this.message);
  @override
  String toString() => message;
}
