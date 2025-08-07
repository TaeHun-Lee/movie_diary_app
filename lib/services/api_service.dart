import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:movie_diary_app/data/diary_entry.dart';
import 'package:movie_diary_app/data/home_data.dart';
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

  static Future<Map<String, dynamic>> getUserInfo(String userId) async {
    final token = await TokenStorage.getAccessToken();
    if (token == null) {
      throw Exception('No access token found');
    }

    final response = await http.get(
      Uri.parse('$baseUrl/users/$userId'),
      headers: {'Authorization': 'Bearer $token'},
    );

    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    } else {
      throw Exception('Failed to fetch user info: ${response.reasonPhrase}');
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

  static Future<HomeData> fetchHomeData(String accessToken) async {
    final headers = {
      'Authorization': 'Bearer $accessToken',
      'Content-Type': 'application/json',
    };

    final userRes = await http.get(
      Uri.parse('$baseUrl/auth/me'),
      headers: headers,
    );
    final summaryRes = await http.get(
      Uri.parse('$baseUrl/post'),
      headers: headers,
    );
    final recentRes = await http.get(
      Uri.parse('$baseUrl/post'),
      headers: headers,
    );

    if (userRes.statusCode == 200 &&
        summaryRes.statusCode == 200 &&
        recentRes.statusCode == 200) {
      final user = json.decode(userRes.body);
      final summary = json.decode(summaryRes.body);
      final recent = json.decode(recentRes.body) as List;

      return HomeData(
        nickname: user['nickname'],
        todayCount: 0,
        totalCount: 0,
        recentEntries: recent.map((e) => DiaryEntry.fromJson(e)).toList(),
      );
    } else {
      throw Exception('홈 데이터를 불러오는데 실패했습니다.');
    }
  }
}
