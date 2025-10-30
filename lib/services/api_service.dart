import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:dio/dio.dart';
import 'package:movie_diary_app/data/diary_entry.dart';
import 'package:movie_diary_app/data/home_data.dart';
import 'package:movie_diary_app/data/movie.dart';
import 'package:movie_diary_app/services/navigation_service.dart';
import 'package:movie_diary_app/services/token_storage.dart';

class ApiService {
  static final String baseUrl = dotenv.env['BASE_URL']!;

  // Dio 인스턴스 생성
  static final Dio _dio = Dio(BaseOptions(baseUrl: baseUrl));

  // 클래스 생성 시 인터셉터 설정
  ApiService() {
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
          // 401 에러 발생 시 로그인 페이지로 리디렉션
          if (e.response?.statusCode == 401) {
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
      return response.data;
    } on DioException catch (e) {
      _handleDioError(e, 'Failed to login');
    }
  }

  static Future<Map<String, dynamic>> getUserInfo(String userId) async {
    try {
      final response = await _dio.get('/users/$userId');
      return response.data;
    } on DioException catch (e) {
      _handleDioError(e, 'Failed to fetch user info');
    }
  }

  static Future<Map<String, dynamic>> register(
    String userId,
    String password,
    String nickname,
  ) async {
    try {
      final response = await _dio.post(
        '/auth/register',
        data: {'user_id': userId, 'password': password, 'nickname': nickname},
      );
      return response.data;
    } on DioException catch (e) {
      _handleDioError(e, 'Failed to register');
    }
  }

  static Future<HomeData> fetchHomeData() async {
    try {
      // 두 API 요청을 동시에 보냄
      final responses = await Future.wait([
        _dio.get('/auth/me'),
        _dio.get('/posts'),
      ]);

      final user = responses[0].data;
      final recent = responses[1].data as List;

      return HomeData(
        nickname: user['nickname'] ?? '사용자',
        todayCount: 0, // API에 해당 필드가 없으므로 기본값 처리
        totalCount: 0, // API에 해당 필드가 없으므로 기본값 처리
        recentEntries: recent.map((e) => DiaryEntry.fromJson(e)).toList(),
      );
    } on DioException catch (e) {
      _handleDioError(e, '홈 데이터를 불러오는데 실패했습니다.');
    }
  }

  static Future<List<Movie>> searchMovies(String title) async {
    try {
      final response = await _dio.get(
        '/movies/search',
        queryParameters: {'title': title},
      );
      final List<dynamic> data = response.data;
      return data.map((json) => Movie.fromJson(json)).toList();
    } on DioException catch (e) {
      _handleDioError(e, 'Failed to search movies');
    }
  }

  static Future<List<DiaryEntry>> getPostsForMovie(String docId) async {
    try {
      final response = await _dio.get('/posts'); // 이 부분은 API 수정이 필요해 보임
      final List<dynamic> data = response.data;
      return data
          .map((json) => DiaryEntry.fromJson(json))
          .where((entry) => entry.docId == docId)
          .toList();
    } on DioException catch (e) {
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
  }) async {
    try {
      await _dio.post(
        '/posts',
        data: {
          'movie_docId': docId,
          'title': title,
          'content': content,
          'rating': rating,
          'watched_at': watchedAt.toIso8601String(),
          'movieData': movie.toJson(),
          if (location != null && location.isNotEmpty) 'place': location,
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
        },
      );
    } on DioException catch (e) {
      _handleDioError(e, 'Failed to update post');
    }
  }

  // 에러 처리 헬퍼 함수
  static Never _handleDioError(DioException e, String defaultMessage) {
    if (e.response != null && e.response!.data is Map) {
      // 서버에서 보낸 구체적인 에러 메시지가 있으면 사용
      final errorMessage = e.response!.data['message'] ?? defaultMessage;
      throw Exception(errorMessage);
    } else {
      // 그 외의 경우 (네트워크 오류 등) 기본 메시지 사용
      throw Exception(defaultMessage);
    }
  }
}
