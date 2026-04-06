import 'dart:convert';
import 'package:http/http.dart' as http;

class ApiService {
  static const String _baseUrl = 'http://10.0.2.2:8000';

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

  static Future<List<dynamic>> getFun() async {
    final response = await http.get(Uri.parse('$_baseUrl/api/fun'));
    if (response.statusCode == 200) return jsonDecode(utf8.decode(response.bodyBytes)) as List;
    throw ApiException('Lỗi tải danh sách vui học');
  }

  // ── Admin Users ───────────────────────────────────────────────────────────
  static Future<List<dynamic>> getAllUsers(String adminId) async {
    final response = await http.get(Uri.parse('$_baseUrl/api/admin/users?admin_id=$adminId'));
    if (response.statusCode == 200) return jsonDecode(utf8.decode(response.bodyBytes)) as List;
    final body = jsonDecode(utf8.decode(response.bodyBytes));
    throw ApiException(body['detail'] ?? 'Lỗi tải danh sách người dùng');
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

  // ── Admin CMS — Fun ───────────────────────────────────────────────────────
  static Future<void> createFun({required String adminId, required String title,
      required String type, required String mediaUrl, required String content}) async {
    final response = await http.post(Uri.parse('$_baseUrl/api/admin/fun'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'admin_id': adminId, 'title': title, 'type': type,
            'media_url': mediaUrl, 'content': content}));
    if (response.statusCode != 200) {
      final body = jsonDecode(utf8.decode(response.bodyBytes));
      throw ApiException(body['detail'] ?? 'Lỗi tạo nội dung');
    }
  }

  static Future<void> updateFun(String id, {required String adminId, required String title,
      required String type, required String mediaUrl, required String content}) async {
    final response = await http.put(Uri.parse('$_baseUrl/api/admin/fun/$id'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'admin_id': adminId, 'title': title, 'type': type,
            'media_url': mediaUrl, 'content': content}));
    if (response.statusCode != 200) {
      final body = jsonDecode(utf8.decode(response.bodyBytes));
      throw ApiException(body['detail'] ?? 'Lỗi cập nhật nội dung');
    }
  }

  static Future<void> deleteFun(String id, String adminId) async {
    final response = await http.delete(Uri.parse('$_baseUrl/api/admin/fun/$id?admin_id=$adminId'));
    if (response.statusCode != 200) throw ApiException('Lỗi xóa nội dung');
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
}

class ApiException implements Exception {
  final String message;
  ApiException(this.message);
  @override
  String toString() => message;
}
