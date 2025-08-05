import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:movie_diary_app/services/token_storage.dart';

class ApiService {
  static const String baseUrl = 'http://localhost:3000';

  static Future<Map<String, dynamic>> login({
    required String userId,
    required String password,
  }) async {
    final response = await http.post(
      Uri.parse('$baseUrl/auth/login'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({'user_id': userId, 'password': password}),
    );

    if (response.statusCode == 200 || response.statusCode == 201) {
      return jsonDecode(response.body);
    } else {
      throw Exception('Failed to login: ${response.reasonPhrase}');
    }
  }

  static Future<void> logout() async {
    final token = await TokenStorage.getAccessToken();
    if (token == null) return;
    await TokenStorage.clearAccessToken();
  }

  static Future<Map<String, dynamic>> register(
    String userId,
    String password,
    String nickname,
  ) async {
    final response = await http.post(
      Uri.parse('$baseUrl/auth/register'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        'user_id': userId,
        'password': password,
        'nickname': nickname,
      }),
    );

    if (response.statusCode == 200 || response.statusCode == 201) {
      return jsonDecode(response.body);
    } else {
      final errorResponse = jsonDecode(response.body);
      throw Exception(
        'Failed to register: ${errorResponse['message'] ?? response.reasonPhrase}',
      );
    }
  }
}
