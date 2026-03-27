import 'dart:convert';
import 'package:http/http.dart' as http;

class ApiService {
  // 10.0.2.2 = máy tính host khi chạy trên Android Emulator
  // Nếu chạy trên thiết bị thật, đổi thành IP LAN của máy tính (vd: http://192.168.1.x:8000)
  static const String _baseUrl = 'http://10.0.2.2:8000';

  static Future<Map<String, dynamic>> login(
      String email, String password) async {
    final response = await http.post(
      Uri.parse('$_baseUrl/api/auth/login'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({'email': email, 'password': password}),
    );
    final body = jsonDecode(utf8.decode(response.bodyBytes));
    if (response.statusCode == 200) {
      return body as Map<String, dynamic>;
    }
    throw ApiException(body['detail'] ?? 'Đăng nhập thất bại.');
  }

  static Future<Map<String, dynamic>> register(
      String name, String email, String password) async {
    final response = await http.post(
      Uri.parse('$_baseUrl/api/auth/register'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({'name': name, 'email': email, 'password': password}),
    );
    final body = jsonDecode(utf8.decode(response.bodyBytes));
    if (response.statusCode == 200) {
      return body as Map<String, dynamic>;
    }
    throw ApiException(body['detail'] ?? 'Đăng ký thất bại.');
  }

  static Future<List<dynamic>> getAllUsers(String adminId) async {
    final response = await http.get(Uri.parse('$_baseUrl/api/admin/users?admin_id=$adminId'));
    if (response.statusCode == 200) {
      return jsonDecode(utf8.decode(response.bodyBytes)) as List<dynamic>;
    }
    final body = jsonDecode(utf8.decode(response.bodyBytes));
    throw ApiException(body['detail'] ?? 'Lỗi tải danh sách người dùng');
  }

  static Future<void> setRole(String adminId, String targetEmail, String newRole) async {
    final response = await http.post(
      Uri.parse('$_baseUrl/api/admin/set_role'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({'admin_id': adminId, 'target_email': targetEmail, 'new_role': newRole}),
    );
    if (response.statusCode != 200) {
      final body = jsonDecode(utf8.decode(response.bodyBytes));
      throw ApiException(body['detail'] ?? 'Lỗi cập nhật quyền');
    }
  }
}

class ApiException implements Exception {
  final String message;
  ApiException(this.message);

  @override
  String toString() => message;
}
