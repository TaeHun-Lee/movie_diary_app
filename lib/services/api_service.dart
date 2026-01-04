import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:dio/dio.dart';
import 'package:movie_diary_app/data/diary_entry.dart';
import 'package:movie_diary_app/data/home_data.dart';
import 'package:movie_diary_app/data/movie.dart';
import 'package:movie_diary_app/services/navigation_service.dart';
import 'package:movie_diary_app/services/token_storage.dart';
import 'dart:io';
import 'package:image_picker/image_picker.dart';
import 'package:flutter/foundation.dart' show kIsWeb;

class ApiService {
  static final String baseUrl = dotenv.env['BASE_URL']!;

  // Dio 인스턴스 생성
  static final Dio _dio = Dio(BaseOptions(baseUrl: baseUrl));

  // 클래스 생성 시 인터셉터 설정
  ApiService();

  static void initialize() {
    _dio.interceptors.add(
      InterceptorsWrapper(
        onRequest: (options, handler) async {
          // 토큰이 필요한 요청에 대해 헤더에 토큰 추가
          if (!options.path.contains('/auth/login') &&
              !options.path.contains('/auth/register')) {
            final token = await TokenStorage.getAccessToken();
            if (token != null) {
              options.headers['Authorization'] = 'Bearer $token';
            }
          }
          return handler.next(options); // 요청 계속 진행
        },
        onError: (DioException e, handler) {
          final path = e.requestOptions.path;
          // 401 에러 발생 시 로그인 페이지로 리디렉션
          if (e.response?.statusCode == 401 &&
              !path.contains('/auth/login') &&
              !path.contains('/auth/register') &&
              !path.contains('/auth/security-question') &&
              !path.contains('/auth/reset-password') &&
              !path.contains('/auth/change-password')) {
            NavigationService.handleUnauthorized();
            // 에러 처리를 여기서 중단하고, 호출한 쪽에서는 아무것도 받지 않게 함
            return handler.reject(
              DioException(
                requestOptions: e.requestOptions,
                message: 'Unauthorized. Redirecting to login.',
              ),
            );
          }
          return handler.next(e); // 다른 에러는 계속 전파
        },
      ),
    );
  }

  // Dio 인스턴스를 외부에서 접근할 수 있도록 getter 제공
  static Dio get dio => _dio;

  static Future<Map<String, dynamic>> login({
    required String userId,
    required String password,
  }) async {
    try {
      final response = await _dio.post(
        '/auth/login',
        data: {'user_id': userId, 'password': password},
      );
      return response.data['data'];
    } on DioException catch (e) {
      _handleDioError(e, 'Failed to login');
    }
  }

  static Future<Map<String, dynamic>> getUserInfo(String userId) async {
    try {
      final response = await _dio.get('/users/$userId');
      return response.data['data'];
    } on DioException catch (e) {
      _handleDioError(e, 'Failed to fetch user info');
    }
  }

  static Future<Map<String, dynamic>> register(
    String userId,
    String password,
    String nickname, {
    String? securityQuestion,
    String? securityAnswer,
  }) async {
    try {
      final data = {
        'user_id': userId,
        'password': password,
        'nickname': nickname,
      };
      if (securityQuestion != null) {
        data['security_question'] = securityQuestion;
      }
      if (securityAnswer != null) {
        data['security_answer'] = securityAnswer;
      }

      final response = await _dio.post('/auth/register', data: data);
      return response.data['data'];
    } on DioException catch (e) {
      _handleDioError(e, 'Failed to register');
    }
  }

  static Future<String?> uploadPhoto(XFile file) async {
    try {
      String fileName = file.name;
      FormData formData;

      if (kIsWeb) {
        final bytes = await file.readAsBytes();
        formData = FormData.fromMap({
          'file': MultipartFile.fromBytes(bytes, filename: fileName),
        });
      } else {
        formData = FormData.fromMap({
          'file': await MultipartFile.fromFile(file.path, filename: fileName),
        });
      }

      final response = await _dio.post('/uploads', data: formData);
      return response.data['data']['url'];
    } on DioException catch (e) {
      _handleDioError(e, 'Failed to upload photo');
    }
  }

  static Future<String?> getSecurityQuestion(String userId) async {
    try {
      final response = await _dio.get('/auth/security-question/$userId');
      return response.data['data']['question'];
    } on DioException catch (e) {
      // User not found or no question set
      if (e.response?.statusCode == 404 || e.response?.statusCode == 401) {
        throw Exception('사용자를 찾을 수 없거나 보안 질문이 설정되지 않았습니다.');
      }
      _handleDioError(e, 'Failed to get security question');
    }
  }

  static Future<void> changePassword(
    String oldPassword,
    String newPassword,
  ) async {
    try {
      await _dio.post(
        '/auth/change-password',
        data: {'old_password': oldPassword, 'new_password': newPassword},
      );
    } on DioException catch (e) {
      if (e.response?.statusCode == 401) {
        throw Exception('기존 비밀번호가 일치하지 않습니다.');
      }
      _handleDioError(e, '비밀번호 변경에 실패했습니다.');
    }
  }

  static Future<void> resetPassword(
    String userId,
    String securityAnswer,
    String newPassword,
  ) async {
    try {
      await _dio.post(
        '/auth/reset-password',
        data: {
          'user_id': userId,
          'security_answer': securityAnswer,
          'new_password': newPassword,
        },
      );
    } on DioException catch (e) {
      if (e.response?.statusCode == 401 || e.response?.statusCode == 400) {
        throw Exception('비밀번호 재설정에 실패했습니다. 답변이 틀렸을 수 있습니다.');
      }
      _handleDioError(e, '비밀번호 재설정에 실패했습니다.');
    }
  }

  static Future<HomeData> fetchHomeData() async {
    try {
      // 두 API 요청을 동시에 보냄
      final responses = await Future.wait([
        _dio.get('/auth/me'),
        _dio.get('/posts/my'), // 내 포스트만 가져오도록 수정
      ]);

      final userJson = responses[0].data['data'];
      final postsJson = responses[1].data['data'] as List;

      return HomeData.fromJson(userJson, postsJson);
    } on DioException catch (e) {
      _handleDioError(e, '홈 데이터를 불러오는데 실패했습니다.');
    }
  }

  static Future<List<DiaryEntry>> getMyPosts() async {
    try {
      final response = await _dio.get('/posts/my');
      final List<dynamic> data = response.data['data'];
      return data.map((json) => DiaryEntry.fromJson(json)).toList();
    } on DioException catch (e) {
      _handleDioError(e, '내가 쓴 다이어리를 불러오는데 실패했습니다.');
    }
  }

  static Future<List<DiaryEntry>> getPopularPosts() async {
    try {
      final response = await _dio.get('/posts/popular');
      final List<dynamic> data = response.data['data'];
      return data.map((json) => DiaryEntry.fromJson(json)).toList();
    } on DioException catch (e) {
      _handleDioError(e, '인기 다이어리를 불러오는데 실패했습니다.');
    }
  }

  static Future<List<Movie>> searchMovies(
    String title, {
    int startCount = 0,
  }) async {
    try {
      final response = await _dio.get(
        '/movies/search',
        queryParameters: {'title': title, 'startCount': startCount},
      );
      final List<dynamic> data = response.data['data'];
      return data.map((json) => Movie.fromJson(json)).toList();
    } on DioException catch (e) {
      _handleDioError(e, 'Failed to search movies');
    }
  }

  static Future<List<DiaryEntry>> getMyReviewsForMovie(String docId) async {
    try {
      final response = await _dio.get('/posts/movie/doc/$docId/my-reviews');
      final List<dynamic> data = response.data['data'];
      return data.map((json) => DiaryEntry.fromJson(json)).toList();
    } on DioException catch (e) {
      if (e.response?.statusCode == 404) {
        return [];
      }
      _handleDioError(e, 'Failed to fetch posts');
    }
  }

  static Future<void> createPost({
    required String docId,
    required String title,
    required String content,
    required double rating,
    required DateTime watchedAt,
    required Movie movie,
    String? location,
    bool isSpoiler = false,
    List<String>? photoUrls,
  }) async {
    try {
      await _dio.post(
        '/posts',
        data: {
          'title': title,
          'content': content,
          'rating': rating,
          'watched_at': watchedAt.toIso8601String(),
          'movie': movie.toJson(),
          'is_spoiler': isSpoiler,
          if (location != null && location.isNotEmpty) 'place': location,
          if (photoUrls != null) 'photo_urls': photoUrls,
        },
      );
    } on DioException catch (e) {
      _handleDioError(e, 'Failed to create post');
    }
  }

  static Future<void> updatePost({
    required int postId,
    required String title,
    required String content,
    required double rating,
    required DateTime watchedAt,
    String? location,
    bool? isSpoiler,
    List<String>? photoUrls,
  }) async {
    try {
      await _dio.patch(
        '/posts/$postId',
        data: {
          'title': title,
          'content': content,
          'rating': rating,
          'watched_at': watchedAt.toIso8601String(),
          if (location != null && location.isNotEmpty) 'place': location,
          if (isSpoiler != null) 'is_spoiler': isSpoiler,
          if (photoUrls != null) 'photo_urls': photoUrls,
        },
      );
    } on DioException catch (e) {
      _handleDioError(e, 'Failed to update post');
    }
  }

  static Future<void> deletePost(int postId) async {
    try {
      await _dio.delete('/posts/$postId');
    } on DioException catch (e) {
      _handleDioError(e, 'Failed to delete post');
    }
  }

  static String? buildImageUrl(String? imagePath) {
    if (imagePath == null || imagePath.isEmpty) return null;
    imagePath = imagePath.trim();

    // 1. 이미 프록시 URL인 경우 중복 처리 방지
    if (imagePath.contains('/movies/image?url=')) {
      if (imagePath.contains('localhost') && baseUrl.contains('10.0.2.2')) {
        return imagePath.replaceFirst('localhost', '10.0.2.2');
      }
      return imagePath;
    }

    // 2. 내부 서버(업로드 이미지)인 경우 프록시 타지 않고 호스트만 보정
    if (imagePath.contains('localhost') || imagePath.contains('10.0.2.2')) {
      if (imagePath.contains('localhost') && baseUrl.contains('10.0.2.2')) {
        return imagePath.replaceFirst('localhost', '10.0.2.2');
      }
      return imagePath;
    }

    // 3. 외부 URL인 경우 프록시 URL 생성
    if (imagePath.startsWith('http')) {
      final String proxyUrl = '$baseUrl/movies/image?url=';
      return '$proxyUrl${Uri.encodeQueryComponent(imagePath)}';
    }

    // 4. 상대 경로인 경우 Base URL 붙이기
    return '$baseUrl$imagePath';
  }

  static String? extractOriginalUrl(String? imageUrl) {
    if (imageUrl == null || imageUrl.isEmpty) {
      return null;
    }
    if (imageUrl.contains('url=')) {
      final uri = Uri.parse(imageUrl);
      final originalUrl = uri.queryParameters['url'];
      if (originalUrl != null) {
        return originalUrl;
      }
    }
    return imageUrl;
  }

  // 프로필 업데이트
  static Future<void> updateProfile(int id, Map<String, dynamic> data) async {
    try {
      await _dio.patch('/users/$id', data: data);
    } on DioException catch (e) {
      _handleDioError(e, '프로필 수정에 실패했습니다.');
    }
  }

  // 회원 탈퇴
  static Future<void> deleteUser(int id) async {
    try {
      await _dio.delete('/users/$id');
    } on DioException catch (e) {
      _handleDioError(e, '회원 탈퇴에 실패했습니다.');
    }
  }

  // Personal Diary
  static Future<void> savePersonalDiary(String date, String content) async {
    try {
      // Backend create handles upsert logic
      await _dio.post(
        '/personal-diary',
        data: {'date': date, 'content': content},
      );
    } on DioException catch (e) {
      _handleDioError(e, '일기 저장에 실패했습니다.');
    }
  }

  static Future<List<dynamic>> getPersonalDiaries() async {
    try {
      final response = await _dio.get('/personal-diary');
      return response.data['data']; // Correctly access the data field
    } on DioException catch (e) {
      if (e.response?.statusCode == 404) {
        return [];
      }
      _handleDioError(e, '일기 목록을 불러오는데 실패했습니다.');
    }
  }

  static Future<Map<String, dynamic>?> getPersonalDiaryByDate(
    String date,
  ) async {
    try {
      final response = await _dio.get('/personal-diary/date/$date');
      return response.data['data'];
    } on DioException {
      return null;
    }
  }

  static Future<void> deletePersonalDiary(int id) async {
    try {
      await _dio.delete('/personal-diary/$id');
    } on DioException catch (e) {
      _handleDioError(e, '일기 삭제에 실패했습니다.');
    }
  }

  // DioException 처리를 위한 헬퍼 함수
  static Never _handleDioError(DioException e, String message) {
    throw Exception('$message: ${e.message}');
  }
}
